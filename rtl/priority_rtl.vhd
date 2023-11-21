-------------------------------------------------------------------------------
--  HTL8259 - PIC core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8259                                                   --
-- Purpose       : Priority Encoder                                          --
-- Library       : I8259                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  05/09/2005                                           --
--               : 1.2  21/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.STD_LOGIC_UNSIGNED.all;

ENTITY priority IS
   PORT( 
      irr            : IN     std_logic_vector (7 DOWNTO 0);
      prisbit        : OUT    std_logic_vector (3 DOWNTO 0);
      int            : OUT    std_logic;
      resetn         : IN     std_logic;
      clk            : IN     std_logic;
      init_s         : IN     std_logic;
      irlevel        : IN     std_logic_vector (2 DOWNTO 0);
      ld_irlevel     : IN     std_logic;
      ld_rot         : IN     std_logic;
      vector         : IN     std_logic_vector (3 DOWNTO 0);
      icw3_reg_s     : IN     std_logic_vector (7 DOWNTO 0);
      sfn_mode       : IN     std_logic;
      special_mask_s : IN     std_logic);
END priority ;


ARCHITECTURE rtl OF priority IS

signal irr_reorder_s : std_logic_vector(7 downto 0);
signal lsb_s         : std_logic_vector(3 downto 0);
signal is_s          : std_logic_vector(2 downto 0);
signal issel_s       : std_logic_vector(5 downto 0);

signal rot_s         : std_logic_vector(2 downto 0);

signal slave_int_req : std_logic;

BEGIN
    
  process (clk,resetn)                                  -- Rotate Register                  
        begin
            if (resetn='0') then                     
               rot_s <= (others => '0');              
            elsif (rising_edge(clk)) then 
                if init_s='1' then
                    rot_s <= (others => '0');
                elsif ld_irlevel='1' then               -- force priority, note you set the lowest priority!        
                    rot_s <= irlevel+'1';               -- thus if L2:0=5, then 6 is the highest priority
                elsif ld_rot='1' then                  
                    rot_s <= vector(2 downto 0) +'1';   -- New Rotate=Priority last IS serviced

                end if;
            end if;   
        end process;    


  process(rot_s,irr)                  
  begin 
    case rot_s is 
       when "000"  => irr_reorder_s <= irr;             -- 0 highest priority
       when "001"  => irr_reorder_s <= irr(0) & irr(7 downto 1);    -- 1 highest priority   
       when "010"  => irr_reorder_s <= irr(1 downto 0) & irr(7 downto 2);   
       when "011"  => irr_reorder_s <= irr(2 downto 0) & irr(7 downto 3);   
       when "100"  => irr_reorder_s <= irr(3 downto 0) & irr(7 downto 4);   
       when "101"  => irr_reorder_s <= irr(4 downto 0) & irr(7 downto 5);   
       when "110"  => irr_reorder_s <= irr(5 downto 0) & irr(7 downto 6);   
       when others => irr_reorder_s <= irr(6 downto 0) & irr(7);  -- 7 highest priority
    end case;
  end process;

  process (irr_reorder_s)                               -- Find LSB
  begin
    case irr_reorder_s is
       when "00000000" => lsb_s <= "0000";              -- All zero case, enable (bit) = 0
       when "00000001" => lsb_s <= "1000";
       when "00000010" => lsb_s <= "1001";
       when "00000011" => lsb_s <= "1000";
       when "00000100" => lsb_s <= "1010";
       when "00000101" => lsb_s <= "1000";
       when "00000110" => lsb_s <= "1001";
       when "00000111" => lsb_s <= "1000";
       when "00001000" => lsb_s <= "1011";
       when "00001001" => lsb_s <= "1000";
       when "00001010" => lsb_s <= "1001";
       when "00001011" => lsb_s <= "1000";
       when "00001100" => lsb_s <= "1010";
       when "00001101" => lsb_s <= "1000";
       when "00001110" => lsb_s <= "1001";
       when "00001111" => lsb_s <= "1000";
       when "00010000" => lsb_s <= "1100";
       when "00010001" => lsb_s <= "1000";
       when "00010010" => lsb_s <= "1001";
       when "00010011" => lsb_s <= "1000";
       when "00010100" => lsb_s <= "1010";
       when "00010101" => lsb_s <= "1000";
       when "00010110" => lsb_s <= "1001";
       when "00010111" => lsb_s <= "1000";
       when "00011000" => lsb_s <= "1011";
       when "00011001" => lsb_s <= "1000";
       when "00011010" => lsb_s <= "1001";
       when "00011011" => lsb_s <= "1000";
       when "00011100" => lsb_s <= "1010";
       when "00011101" => lsb_s <= "1000";
       when "00011110" => lsb_s <= "1001";
       when "00011111" => lsb_s <= "1000";
       when "00100000" => lsb_s <= "1101";
       when "00100001" => lsb_s <= "1000";
       when "00100010" => lsb_s <= "1001";
       when "00100011" => lsb_s <= "1000";
       when "00100100" => lsb_s <= "1010";
       when "00100101" => lsb_s <= "1000";
       when "00100110" => lsb_s <= "1001";
       when "00100111" => lsb_s <= "1000";
       when "00101000" => lsb_s <= "1011";
       when "00101001" => lsb_s <= "1000";
       when "00101010" => lsb_s <= "1001";
       when "00101011" => lsb_s <= "1000";
       when "00101100" => lsb_s <= "1010";
       when "00101101" => lsb_s <= "1000";
       when "00101110" => lsb_s <= "1001";
       when "00101111" => lsb_s <= "1000";
       when "00110000" => lsb_s <= "1100";
       when "00110001" => lsb_s <= "1000";
       when "00110010" => lsb_s <= "1001";
       when "00110011" => lsb_s <= "1000";
       when "00110100" => lsb_s <= "1010";
       when "00110101" => lsb_s <= "1000";
       when "00110110" => lsb_s <= "1001";
       when "00110111" => lsb_s <= "1000";
       when "00111000" => lsb_s <= "1011";
       when "00111001" => lsb_s <= "1000";
       when "00111010" => lsb_s <= "1001";
       when "00111011" => lsb_s <= "1000";
       when "00111100" => lsb_s <= "1010";
       when "00111101" => lsb_s <= "1000";
       when "00111110" => lsb_s <= "1001";
       when "00111111" => lsb_s <= "1000";
       when "01000000" => lsb_s <= "1110";
       when "01000001" => lsb_s <= "1000";
       when "01000010" => lsb_s <= "1001";
       when "01000011" => lsb_s <= "1000";
       when "01000100" => lsb_s <= "1010";
       when "01000101" => lsb_s <= "1000";
       when "01000110" => lsb_s <= "1001";
       when "01000111" => lsb_s <= "1000";
       when "01001000" => lsb_s <= "1011";
       when "01001001" => lsb_s <= "1000";
       when "01001010" => lsb_s <= "1001";
       when "01001011" => lsb_s <= "1000";
       when "01001100" => lsb_s <= "1010";
       when "01001101" => lsb_s <= "1000";
       when "01001110" => lsb_s <= "1001";
       when "01001111" => lsb_s <= "1000";
       when "01010000" => lsb_s <= "1100";
       when "01010001" => lsb_s <= "1000";
       when "01010010" => lsb_s <= "1001";
       when "01010011" => lsb_s <= "1000";
       when "01010100" => lsb_s <= "1010";
       when "01010101" => lsb_s <= "1000";
       when "01010110" => lsb_s <= "1001";
       when "01010111" => lsb_s <= "1000";
       when "01011000" => lsb_s <= "1011";
       when "01011001" => lsb_s <= "1000";
       when "01011010" => lsb_s <= "1001";
       when "01011011" => lsb_s <= "1000";
       when "01011100" => lsb_s <= "1010";
       when "01011101" => lsb_s <= "1000";
       when "01011110" => lsb_s <= "1001";
       when "01011111" => lsb_s <= "1000";
       when "01100000" => lsb_s <= "1101";
       when "01100001" => lsb_s <= "1000";
       when "01100010" => lsb_s <= "1001";
       when "01100011" => lsb_s <= "1000";
       when "01100100" => lsb_s <= "1010";
       when "01100101" => lsb_s <= "1000";
       when "01100110" => lsb_s <= "1001";
       when "01100111" => lsb_s <= "1000";
       when "01101000" => lsb_s <= "1011";
       when "01101001" => lsb_s <= "1000";
       when "01101010" => lsb_s <= "1001";
       when "01101011" => lsb_s <= "1000";
       when "01101100" => lsb_s <= "1010";
       when "01101101" => lsb_s <= "1000";
       when "01101110" => lsb_s <= "1001";
       when "01101111" => lsb_s <= "1000";
       when "01110000" => lsb_s <= "1100";
       when "01110001" => lsb_s <= "1000";
       when "01110010" => lsb_s <= "1001";
       when "01110011" => lsb_s <= "1000";
       when "01110100" => lsb_s <= "1010";
       when "01110101" => lsb_s <= "1000";
       when "01110110" => lsb_s <= "1001";
       when "01110111" => lsb_s <= "1000";
       when "01111000" => lsb_s <= "1011";
       when "01111001" => lsb_s <= "1000";
       when "01111010" => lsb_s <= "1001";
       when "01111011" => lsb_s <= "1000";
       when "01111100" => lsb_s <= "1010";
       when "01111101" => lsb_s <= "1000";
       when "01111110" => lsb_s <= "1001";
       when "01111111" => lsb_s <= "1000";
       when "10000000" => lsb_s <= "1111";
       when "10000001" => lsb_s <= "1000";
       when "10000010" => lsb_s <= "1001";
       when "10000011" => lsb_s <= "1000";
       when "10000100" => lsb_s <= "1010";
       when "10000101" => lsb_s <= "1000";
       when "10000110" => lsb_s <= "1001";
       when "10000111" => lsb_s <= "1000";
       when "10001000" => lsb_s <= "1011";
       when "10001001" => lsb_s <= "1000";
       when "10001010" => lsb_s <= "1001";
       when "10001011" => lsb_s <= "1000";
       when "10001100" => lsb_s <= "1010";
       when "10001101" => lsb_s <= "1000";
       when "10001110" => lsb_s <= "1001";
       when "10001111" => lsb_s <= "1000";
       when "10010000" => lsb_s <= "1100";
       when "10010001" => lsb_s <= "1000";
       when "10010010" => lsb_s <= "1001";
       when "10010011" => lsb_s <= "1000";
       when "10010100" => lsb_s <= "1010";
       when "10010101" => lsb_s <= "1000";
       when "10010110" => lsb_s <= "1001";
       when "10010111" => lsb_s <= "1000";
       when "10011000" => lsb_s <= "1011";
       when "10011001" => lsb_s <= "1000";
       when "10011010" => lsb_s <= "1001";
       when "10011011" => lsb_s <= "1000";
       when "10011100" => lsb_s <= "1010";
       when "10011101" => lsb_s <= "1000";
       when "10011110" => lsb_s <= "1001";
       when "10011111" => lsb_s <= "1000";
       when "10100000" => lsb_s <= "1101";
       when "10100001" => lsb_s <= "1000";
       when "10100010" => lsb_s <= "1001";
       when "10100011" => lsb_s <= "1000";
       when "10100100" => lsb_s <= "1010";
       when "10100101" => lsb_s <= "1000";
       when "10100110" => lsb_s <= "1001";
       when "10100111" => lsb_s <= "1000";
       when "10101000" => lsb_s <= "1011";
       when "10101001" => lsb_s <= "1000";
       when "10101010" => lsb_s <= "1001";
       when "10101011" => lsb_s <= "1000";
       when "10101100" => lsb_s <= "1010";
       when "10101101" => lsb_s <= "1000";
       when "10101110" => lsb_s <= "1001";
       when "10101111" => lsb_s <= "1000";
       when "10110000" => lsb_s <= "1100";
       when "10110001" => lsb_s <= "1000";
       when "10110010" => lsb_s <= "1001";
       when "10110011" => lsb_s <= "1000";
       when "10110100" => lsb_s <= "1010";
       when "10110101" => lsb_s <= "1000";
       when "10110110" => lsb_s <= "1001";
       when "10110111" => lsb_s <= "1000";
       when "10111000" => lsb_s <= "1011";
       when "10111001" => lsb_s <= "1000";
       when "10111010" => lsb_s <= "1001";
       when "10111011" => lsb_s <= "1000";
       when "10111100" => lsb_s <= "1010";
       when "10111101" => lsb_s <= "1000";
       when "10111110" => lsb_s <= "1001";
       when "10111111" => lsb_s <= "1000";
       when "11000000" => lsb_s <= "1110";
       when "11000001" => lsb_s <= "1000";
       when "11000010" => lsb_s <= "1001";
       when "11000011" => lsb_s <= "1000";
       when "11000100" => lsb_s <= "1010";
       when "11000101" => lsb_s <= "1000";
       when "11000110" => lsb_s <= "1001";
       when "11000111" => lsb_s <= "1000";
       when "11001000" => lsb_s <= "1011";
       when "11001001" => lsb_s <= "1000";
       when "11001010" => lsb_s <= "1001";
       when "11001011" => lsb_s <= "1000";
       when "11001100" => lsb_s <= "1010";
       when "11001101" => lsb_s <= "1000";
       when "11001110" => lsb_s <= "1001";
       when "11001111" => lsb_s <= "1000";
       when "11010000" => lsb_s <= "1100";
       when "11010001" => lsb_s <= "1000";
       when "11010010" => lsb_s <= "1001";
       when "11010011" => lsb_s <= "1000";
       when "11010100" => lsb_s <= "1010";
       when "11010101" => lsb_s <= "1000";
       when "11010110" => lsb_s <= "1001";
       when "11010111" => lsb_s <= "1000";
       when "11011000" => lsb_s <= "1011";
       when "11011001" => lsb_s <= "1000";
       when "11011010" => lsb_s <= "1001";
       when "11011011" => lsb_s <= "1000";
       when "11011100" => lsb_s <= "1010";
       when "11011101" => lsb_s <= "1000";
       when "11011110" => lsb_s <= "1001";
       when "11011111" => lsb_s <= "1000";
       when "11100000" => lsb_s <= "1101";
       when "11100001" => lsb_s <= "1000";
       when "11100010" => lsb_s <= "1001";
       when "11100011" => lsb_s <= "1000";
       when "11100100" => lsb_s <= "1010";
       when "11100101" => lsb_s <= "1000";
       when "11100110" => lsb_s <= "1001";
       when "11100111" => lsb_s <= "1000";
       when "11101000" => lsb_s <= "1011";
       when "11101001" => lsb_s <= "1000";
       when "11101010" => lsb_s <= "1001";
       when "11101011" => lsb_s <= "1000";
       when "11101100" => lsb_s <= "1010";
       when "11101101" => lsb_s <= "1000";
       when "11101110" => lsb_s <= "1001";
       when "11101111" => lsb_s <= "1000";
       when "11110000" => lsb_s <= "1100";
       when "11110001" => lsb_s <= "1000";
       when "11110010" => lsb_s <= "1001";
       when "11110011" => lsb_s <= "1000";
       when "11110100" => lsb_s <= "1010";
       when "11110101" => lsb_s <= "1000";
       when "11110110" => lsb_s <= "1001";
       when "11110111" => lsb_s <= "1000";
       when "11111000" => lsb_s <= "1011";
       when "11111001" => lsb_s <= "1000";
       when "11111010" => lsb_s <= "1001";
       when "11111011" => lsb_s <= "1000";
       when "11111100" => lsb_s <= "1010";
       when "11111101" => lsb_s <= "1000";
       when "11111110" => lsb_s <= "1001";
       when others     => lsb_s <= "1000";
    end case;
  end process;

  issel_s <= rot_s & lsb_s(2 downto 0);

  process (issel_s)                                     -- Find LSB
  begin
    case issel_s is
       when "000000" => is_s <= "000";                  -- No rotation
       when "000001" => is_s <= "001";
       when "000010" => is_s <= "010";
       when "000011" => is_s <= "011";
       when "000100" => is_s <= "100";
       when "000101" => is_s <= "101";
       when "000110" => is_s <= "110";
       when "000111" => is_s <= "111";
        
       when "001000" => is_s <= "001";                  -- 1 rotation, IR1=Highest Priority
       when "001001" => is_s <= "010";
       when "001010" => is_s <= "011";
       when "001011" => is_s <= "100";
       when "001100" => is_s <= "101";
       when "001101" => is_s <= "110";
       when "001110" => is_s <= "111";
       when "001111" => is_s <= "000";
        
       when "010000" => is_s <= "010";
       when "010001" => is_s <= "011";
       when "010010" => is_s <= "100";
       when "010011" => is_s <= "101";
       when "010100" => is_s <= "110";
       when "010101" => is_s <= "111";
       when "010110" => is_s <= "000";
       when "010111" => is_s <= "001";
        
       when "011000" => is_s <= "011";
       when "011001" => is_s <= "100";
       when "011010" => is_s <= "101";
       when "011011" => is_s <= "110";
       when "011100" => is_s <= "111";
       when "011101" => is_s <= "000";
       when "011110" => is_s <= "001";
       when "011111" => is_s <= "010";
        
       when "100000" => is_s <= "100";
       when "100001" => is_s <= "101";
       when "100010" => is_s <= "110";
       when "100011" => is_s <= "111";
       when "100100" => is_s <= "000";
       when "100101" => is_s <= "001";
       when "100110" => is_s <= "010";
       when "100111" => is_s <= "011";
        
       when "101000" => is_s <= "101";
       when "101001" => is_s <= "110";
       when "101010" => is_s <= "111";
       when "101011" => is_s <= "000";
       when "101100" => is_s <= "001";
       when "101101" => is_s <= "010";
       when "101110" => is_s <= "011";
       when "101111" => is_s <= "100";
        
       when "110000" => is_s <= "110";
       when "110001" => is_s <= "111";
       when "110010" => is_s <= "000";
       when "110011" => is_s <= "001";
       when "110100" => is_s <= "010";
       when "110101" => is_s <= "011";
       when "110110" => is_s <= "100";
       when "110111" => is_s <= "101";
        
       when "111000" => is_s <= "111";
       when "111001" => is_s <= "000";
       when "111010" => is_s <= "001";
       when "111011" => is_s <= "010";
       when "111100" => is_s <= "011";
       when "111101" => is_s <= "100";
       when "111110" => is_s <= "101";
       when others   => is_s <= "110";
    end case;
  end process;

  prisbit <= lsb_s(3) & is_s;                           -- Enable(1) & InService Bit Number(3)

    ---------------------------------------------------------------------------
    -- assert signal if any of the slave request service. This is used in the special
    -- fully nested mode.
    ---------------------------------------------------------------------------
    slave_int_req <= (irr(0) AND icw3_reg_s(0)) OR (irr(1) AND icw3_reg_s(1)) OR
                     (irr(2) AND icw3_reg_s(2)) OR (irr(3) AND icw3_reg_s(3)) OR
                     (irr(4) AND icw3_reg_s(4)) OR (irr(5) AND icw3_reg_s(5)) OR
                     (irr(6) AND icw3_reg_s(6)) OR (irr(7) AND icw3_reg_s(7));
                    
    ---------------------------------------------------------------------------
    -- Only generate an interrupt if the new IR priority is greater than the 
    -- current IS priority in service
    -- In special Fully nested mode if is_s=vector and vector=slave_input then
    -- also assert int!
    -- Special Fully nested mode can not be used with any other scheme???
    -- Assert INT without checking the priority (vector&is_s) if special_mask_s='1'
    ---------------------------------------------------------------------------
    process (clk,resetn)                                -- INTR line to processor        
    begin
        if (resetn='0') then                     
           int <= '0';              
        elsif (rising_edge(clk)) then     
            if lsb_s(3)='1' then

                if (sfn_mode='1' AND slave_int_req='1' AND (('0'&is_s)<=vector)) 
                                            OR (('0'&is_s)<vector) OR (special_mask_s='1') then
                    int <= '1';                         -- Higher Priority requested
                                                        -- are serviced. vector(3)='1' when ISR is empty
                else 
                    int <= '0';
                end if;                             
            else 
                int <= '0';
            end if;                                 
        end if;   
    end process;

end architecture rtl;
