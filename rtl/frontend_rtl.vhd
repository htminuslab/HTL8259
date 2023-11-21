-------------------------------------------------------------------------------
--  HTL8259 - PIC core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8259                                                   --
-- Purpose       : Frontend Module                                           --
-- Library       : I8259                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  05/09/2005                                           --
--               : 1.2  30/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.STD_LOGIC_UNSIGNED.all;

ENTITY frontend IS
   PORT( 
      ir         : IN     std_logic_vector (7 DOWNTO 0);
      clk        : IN     std_logic;
      ltim       : IN     std_logic;
      resetn     : IN     std_logic;
      irr        : OUT    std_logic_vector (7 DOWNTO 0);
      ocw1_reg_s : IN     std_logic_vector (7 DOWNTO 0);
      clr_irr    : IN     std_logic;
      reqisr     : IN     std_logic_vector (2 DOWNTO 0);
      init_s     : IN     std_logic;
      freeze     : IN     std_logic;
      pollcmd    : IN     std_logic;
      icw3_reg_s : IN     std_logic_vector (7 DOWNTO 0);
      ms_s       : IN     std_logic);
END frontend ;


architecture rtl of frontend is

COMPONENT pulselevel
   PORT (
      clk     : IN     std_logic;
      init    : IN     std_logic;
      ir      : IN     std_logic;
      pollcmd : IN     std_logic;
      resetn  : IN     std_logic;
      level   : OUT    std_logic;
      pulse   : OUT    std_logic
   );
END COMPONENT;


signal ir_mask_s   : std_logic_vector(7 downto 0);
signal ir_mux_s    : std_logic_vector(7 downto 0);
signal irr_s       : std_logic_vector(7 downto 0);

signal ir_redge_s  : std_logic_vector(7 downto 0);
signal ir_level_s  : std_logic_vector(7 downto 0);
signal edge_reg_s  : std_logic_vector(7 downto 0);

begin
    
    ir_mask_s <= IR AND (NOT ocw1_reg_s);               -- Mask IR signal, ocw1=MASK


    ---------------------------------------------------------------------------
    -- Connect all IR bits to a pulselevel block
    ---------------------------------------------------------------------------   
    pa: for n in 0 to 7 generate    
    
        instanceName : pulselevel
           PORT MAP (
              clk     => clk,
              init    => init_s,
              ir      => ir_mask_s(n),
              pollcmd => pollcmd,
              resetn  => resetn,
              level   => ir_level_s(n),
              pulse   => ir_redge_s(n)
           );
    end generate pa;
      
    process (clk,resetn)                                -- Edge Register, cleared by INTA cycle                             
        begin
            if (resetn='0') then                     
               edge_reg_s <= (others => '0');              
            elsif (rising_edge(clk)) then 
                if init_s='1' then
                    edge_reg_s <= (others => '0');
                elsif clr_irr='1' then
                    case reqisr is 
                       when "000"  => edge_reg_s(0)<='0';            
                       when "001"  => edge_reg_s(1)<='0';
                       when "010"  => edge_reg_s(2)<='0';
                       when "011"  => edge_reg_s(3)<='0';   
                       when "100"  => edge_reg_s(4)<='0';   
                       when "101"  => edge_reg_s(5)<='0';   
                       when "110"  => edge_reg_s(6)<='0';
                       when others => edge_reg_s(7)<='0';
                    end case;
                else                                    -- Check after synthesis!!!!!
                    if ir_redge_s(0)='1' then edge_reg_s(0)<='1'; end if;
                    if ir_redge_s(1)='1' then edge_reg_s(1)<='1'; end if;
                    if ir_redge_s(2)='1' then edge_reg_s(2)<='1'; end if;
                    if ir_redge_s(3)='1' then edge_reg_s(3)<='1'; end if;
                    if ir_redge_s(4)='1' then edge_reg_s(4)<='1'; end if;
                    if ir_redge_s(5)='1' then edge_reg_s(5)<='1'; end if;
                    if ir_redge_s(6)='1' then edge_reg_s(6)<='1'; end if;
                    if ir_redge_s(7)='1' then edge_reg_s(7)<='1'; end if;
                end if;                               
            end if;   
        end process;    

    ---------------------------------------------------------------------------
    -- Select Level or edge triggered mode for all IR inputs accept when the input is used
    -- for a slave 8259, in that case you need level triggered input. If this was not used
    -- then multiple slave interrupts would result in a single IRQ2 edge.
    -- LTIM 0=Edge, 1=level
    ---------------------------------------------------------------------------
    process(ms_s,icw3_reg_s,ltim,ir_level_s,edge_reg_s)
        begin
            if ms_s='1' then                            -- Check we are master
                if (icw3_reg_s(0)='1' OR ltim='1') then ir_mux_s(0) <= ir_level_s(0); else ir_mux_s(0) <= edge_reg_s(0); end if; 
                if (icw3_reg_s(1)='1' OR ltim='1') then ir_mux_s(1) <= ir_level_s(1); else ir_mux_s(1) <= edge_reg_s(1); end if; 
                if (icw3_reg_s(2)='1' OR ltim='1') then ir_mux_s(2) <= ir_level_s(2); else ir_mux_s(2) <= edge_reg_s(2); end if; 
                if (icw3_reg_s(3)='1' OR ltim='1') then ir_mux_s(3) <= ir_level_s(3); else ir_mux_s(3) <= edge_reg_s(3); end if; 
                if (icw3_reg_s(4)='1' OR ltim='1') then ir_mux_s(4) <= ir_level_s(4); else ir_mux_s(4) <= edge_reg_s(4); end if; 
                if (icw3_reg_s(5)='1' OR ltim='1') then ir_mux_s(5) <= ir_level_s(5); else ir_mux_s(5) <= edge_reg_s(5); end if; 
                if (icw3_reg_s(6)='1' OR ltim='1') then ir_mux_s(6) <= ir_level_s(6); else ir_mux_s(6) <= edge_reg_s(6); end if; 
                if (icw3_reg_s(7)='1' OR ltim='1') then ir_mux_s(7) <= ir_level_s(7); else ir_mux_s(7) <= edge_reg_s(7); end if; 
            else
                if ltim='1' then    
                    ir_mux_s <= ir_level_s;             -- Level triggered for all IR inputs
                else
                    ir_mux_s <= edge_reg_s;             -- Edge triggered for all IR inputs
                end if;
            end if;         
    end process;


    process (clk,resetn)                                -- IR Register                                      
        begin
            if (resetn='0') then                     
               irr_s <= (others => '0');              
            elsif (rising_edge(clk)) then 
                if init_s='1' then
                    irr_s <= (others => '0');
                elsif freeze='0' then                   -- allow update only when not inside inta cycle
                    irr_s <= ir_mux_s;
                end if;                               
            end if;   
        end process;    

    irr <= irr_s;

end architecture rtl;
