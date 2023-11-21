-------------------------------------------------------------------------------
--  HTL8259 - PIC core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8259                                                   --
-- Purpose       : Backend Decoder                                           --
-- Library       : I8259                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  05/09/2005                                           --
--               : 1.2  30/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.STD_LOGIC_UNSIGNED.all;

ENTITY backend IS
   PORT( 
      clk     : IN     std_logic;
      cmd     : IN     std_logic_vector (1 DOWNTO 0);
      irlevel : IN     std_logic_vector (2 DOWNTO 0);
      ld_isr  : IN     std_logic;
      prisbit : IN     std_logic_vector (3 DOWNTO 0);
      resetn  : IN     std_logic;
      isr     : OUT    std_logic_vector (7 DOWNTO 0);
      reqisr  : OUT    std_logic_vector (2 DOWNTO 0);
      init_s  : IN     std_logic;
      vector  : OUT    std_logic_vector (3 DOWNTO 0);
      clr_irr : IN     std_logic);
END backend ;


ARCHITECTURE rtl OF backend IS

signal newis_s    : std_logic;
signal isr_s      : std_logic_vector(7 downto 0);
signal msb_s      : std_logic_vector(3 downto 0);       -- Higest IS priority (on output of IS reg)

signal vector_s   : std_logic_vector(2 downto 0);       

signal isbit_s    : std_logic_vector(3 downto 0);       -- IS bit select

signal irlevel_s  : std_logic_vector (2 downto 0);      


BEGIN
    
    process (clk,resetn)                                -- 1 clk cycled delayed irlevel_s (coincide with ld_isr)                    
        begin
            if (resetn='0') then                     
               irlevel_s <= (others => '0'); 
            elsif (rising_edge(clk)) then 
               irlevel_s <= irlevel;
            end if;   
    end process;    

    ---------------------------------------------------------------------------
    -- Automatic End Of Interrupt
    --      Issue a NonSpecific EOI as soon as INTA2 is received
    -- Specific End Of Interrupt
    --      Specify Level using OCW2        
    -- Non Specific End Of Interrupt
    --      Clear highest Level of current IRQ when writing to OCW2  
    ---------------------------------------------------------------------------
    process (cmd,prisbit,msb_s,irlevel_s) 
        begin
            case cmd is 
                when "01"  => isbit_s <= '1' & msb_s(2 downto 0);   -- Non-Specific select MSB from IS register
                              newis_s <= '0';
                when "11"  => isbit_s <= '1' & irlevel_s;-- Specific, IR Level specified in OCW2
                              newis_s <= '0';
                when others=> isbit_s <= prisbit;       -- select bit from Priority encoder
                              newis_s <= '1';           -- Set ISR Bit

            end case;
    end process;


    process (clk,resetn)                                -- IS Register                  
        begin
            if (resetn='0') then                     
               isr_s <= (others => '0');              
            elsif (rising_edge(clk)) then 
                if init_s='1' then
                   isr_s <= (others => '0');
                elsif ld_isr='1' then                   -- write strobe, first inta2
                        case isbit_s is 
                           when "1000"  => isr_s <= isr_s(7 downto 1) & newis_s;             
                           when "1001"  => isr_s <= isr_s(7 downto 2) & newis_s & isr_s(0);   
                           when "1010"  => isr_s <= isr_s(7 downto 3) & newis_s & isr_s(1 downto 0);
                           when "1011"  => isr_s <= isr_s(7 downto 4) & newis_s & isr_s(2 downto 0);    
                           when "1100"  => isr_s <= isr_s(7 downto 5) & newis_s & isr_s(3 downto 0);    
                           when "1101"  => isr_s <= isr_s(7 downto 6) & newis_s & isr_s(4 downto 0);    
                           when "1110"  => isr_s <= isr_s(7) & newis_s & isr_s(5 downto 0);
                           when "1111"  => isr_s <= newis_s & isr_s(6 downto 0);    
                           when others  => isr_s <= isr_s;
                        end case;
                end if;
            end if;   
        end process;    

    isr <= isr_s;                                       -- Connect to outside world

    process (isr_s)                                     -- Find LSB (highest Priority) 
        begin                                           -- use bit to clear highest ISR register bit
            if    (isr_s(0)='1') then msb_s <="0000";   -- use msb_s(3) for enable (1 means ISR is empty)
            elsif (isr_s(1)='1') then msb_s <="0001";   
            elsif (isr_s(2)='1') then msb_s <="0010";   
            elsif (isr_s(3)='1') then msb_s <="0011";   
            elsif (isr_s(4)='1') then msb_s <="0100";   
            elsif (isr_s(5)='1') then msb_s <="0101";   
            elsif (isr_s(6)='1') then msb_s <="0110";   
            elsif (isr_s(7)='1') then msb_s <="0111";   
                                 else msb_s <="1111";   -- Signal ISR is empty (msb_s(3)='1')
            end if;
    end process;
                      
    reqisr  <= isbit_s(2 downto 0);                     -- Most significant IS request, inta2 not yet received.

    process (clk,resetn)                                -- IS Register                  
        begin
            if (resetn='0') then                     
               vector_s <= (others => '1');             -- Default to spurious interrupt             
            elsif (rising_edge(clk)) then 
                --if init_s='1' then  -- check if required for spurious interrupts
                if clr_irr='1' then                     -- Clear the bit in IRR and set the vector
                    vector_s <= isbit_s(2 downto 0);    -- Interrupt vector 0..7   
                end if;  
            end if;
    end process;

    vector <= msb_s(3) & vector_s;                      -- msb_s(3)='1' if isr is empty 

END ARCHITECTURE rtl;
