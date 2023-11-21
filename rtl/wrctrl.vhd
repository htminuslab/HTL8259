-------------------------------------------------------------------------------
--  HTL8259 - PIC core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8259                                                   --
-- Purpose       : write register controller                                 --
-- Library       : I8259                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  05/09/2005                                           --
--               : 1.2  21/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.STD_LOGIC_UNSIGNED.all;

entity wrctrl is
   port( 
      clk        : in     std_logic;
      dbus_in    : in     std_logic_vector (7 downto 0);
      idle_s     : in     std_logic;
      init_s     : in     std_logic;
      rd_s       : in     std_logic;
      resetn     : in     std_logic;
      wra0_s     : in     std_logic;
      wra1_s     : in     std_logic;
      wrn        : in     std_logic;
      icw2_reg_s : out    std_logic_vector (7 downto 0);
      icw3_reg_s : out    std_logic_vector (7 downto 0);
      icw4_reg_s : out    std_logic_vector (7 downto 0);
      ocw1_reg_s : out    std_logic_vector (7 downto 0);
      ocw2_reg_s : out    std_logic_vector (7 downto 0);
      ocw3_reg_s : out    std_logic_vector (7 downto 0);
      icw1_reg_s : buffer std_logic_vector (7 downto 0));
end wrctrl ;
 
architecture fsm of wrctrl is

   type state_type is (
      sICW1,
      sICW2,
      sw1,
      sICW3,
      sw2,
      sICW4,
      sOCW1,
      sRESET,
      sw0,
      sw4,
      sOCW2b,
      sOCW3,
      sOCW2a
   );
 
   -- Declare current and next state signals
   signal current_state : state_type;
   signal next_state : state_type;

   -- Declare any pre-registered internal signals
   signal icw2_reg_s_cld : std_logic_vector (7 downto 0);
   signal icw3_reg_s_cld : std_logic_vector (7 downto 0);
   signal icw4_reg_s_cld : std_logic_vector (7 downto 0);
   signal ocw1_reg_s_cld : std_logic_vector (7 downto 0);
   signal ocw3_reg_s_cld : std_logic_vector (7 downto 0);
   signal icw1_reg_s_cld : std_logic_vector (7 downto 0);

begin

   clocked_proc : process (clk,resetn)
   begin
      if (resetn = '0') then
         current_state <= sRESET;
         -- Default Reset Values
         icw2_reg_s_cld <= (others => '0');
         icw3_reg_s_cld <= (others => '0');
         icw4_reg_s_cld <= (others => '0');
         ocw1_reg_s_cld <= (others => '1');
         ocw3_reg_s_cld <= (others => '0');
         icw1_reg_s_cld <= (others => '0');
      elsif (clk'event and clk = '1') then
         current_state <= next_state;

         -- Combined Actions
         case current_state is
            when sICW1 => 
               if (wrn='0') then 
                    icw1_reg_s_cld <= dbus_in;
               end if;
               ocw1_reg_s_cld <= (others => '1'); -- Clear Mask Register
            when sICW2 => 
               if (wrn='0') then 
                    icw2_reg_s_cld <= dbus_in;
               end if;
            when sw1 => 
               if (init_s='1') then 
               elsif (wra1_s='1') then 
                  if (wrn='0') then 
                       icw3_reg_s_cld <= dbus_in;
                  end if;
               end if;
            when sICW3 => 
               if (wrn='0') then 
                    icw3_reg_s_cld <= dbus_in;
               end if;
            when sw2 => 
               if (init_s='1') then 
               elsif (wra1_s='1' AND 
                      icw1_reg_s_cld(0)='1') then 
                  if (wrn='0') then 
                       icw4_reg_s_cld <= dbus_in;
                  end if;
               elsif (wra1_s='1') then 
                  if (wrn='0') then 
                       ocw1_reg_s_cld <= dbus_in;
                  end if;
               elsif (wra0_s='1' AND dbus_in(3)='0'
                      AND dbus_in(4)='0') then 
               elsif ((wra0_s='1' AND dbus_in(3)='1'
                      AND dbus_in(4)='0') OR  rd_s='1') then 
                  if (wrn='0') then 
                       ocw3_reg_s_cld<= dbus_in;
                  elsif rd_s='1' then
                       ocw3_reg_s_cld <= ocw3_reg_s_cld(7 downto 3) 
                      & '0' &  ocw3_reg_s_cld(1 downto 0);
                  end if;
               end if;
            when sICW4 => 
               if (wrn='0') then 
                    icw4_reg_s_cld <= dbus_in;
               end if;
            when sOCW1 => 
               if (wrn='0') then 
                    ocw1_reg_s_cld <= dbus_in;
               end if;
            when sRESET => 
               if (init_s='1') then 
                  if (wrn='0') then 
                       icw1_reg_s_cld <= dbus_in;
                  end if;
               end if;
            when sw0 => 
               if (init_s='1') then 
               elsif (wra1_s='1') then 
                  if (wrn='0') then 
                       icw2_reg_s_cld <= dbus_in;
                  end if;
               end if;
            when sw4 => 
               if (init_s='1') then 
               elsif (wra0_s='1' AND dbus_in(3)='0'
                      AND dbus_in(4)='0') then 
               elsif (wra1_s='1') then 
                  if (wrn='0') then 
                       ocw1_reg_s_cld <= dbus_in;
                  end if;
               elsif ((wra0_s='1' AND dbus_in(3)='1'
                      AND dbus_in(4)='0') OR  rd_s='1') then 
                  if (wrn='0') then 
                       ocw3_reg_s_cld<= dbus_in;
                  --elsif rd_s='1' then
                  --    ocw3_reg_s_cld <= ocw3_reg_s_cld(7 downto 3) 
                  --    & '0' &  ocw3_reg_s_cld(1 downto 0);
                  end if;
               end if;
            when sOCW3 => 
               if (wrn='0') then 
                    ocw3_reg_s_cld<= dbus_in;
               end if;
               if (idle_s='1') then 
                  if rd_s='1' then -- Ver 1.1
                       ocw3_reg_s_cld <= ocw3_reg_s_cld(7 downto 3) 
                      & '0' &  ocw3_reg_s_cld(1 downto 0);
                  end if;
               end if;
            when others =>
               null;
         end case;
      end if;
   end process clocked_proc;
 
   nextstate_proc : process ( 
      current_state,
      dbus_in,
      icw1_reg_s_cld,
      idle_s,
      init_s,
      rd_s,
      wra0_s,
      wra1_s,
      wrn
   )
   begin
      -- Default Assignment
      ocw2_reg_s <= "01000000";

      -- Combined Actions
      case current_state is
         when sICW1 => 
            if (idle_s='1') then 
               next_state <= sw0;
            else
               next_state <= sICW1;
            end if;
         when sICW2 => 
            if (idle_s='1') then 
               next_state <= sw1;
            else
               next_state <= sICW2;
            end if;
         when sw1 => 
            if (init_s='1') then 
               next_state <= sICW1;
            elsif (wra1_s='1') then 
               next_state <= sICW3;
            else
               next_state <= sw1;
            end if;
         when sICW3 => 
            if (idle_s='1') then 
               next_state <= sw2;
            else
               next_state <= sICW3;
            end if;
         when sw2 => 
            if (init_s='1') then 
               next_state <= sICW1;
            elsif (wra1_s='1' AND 
                   icw1_reg_s_cld(0)='1') then 
               next_state <= sICW4;
            elsif (wra1_s='1') then 
               next_state <= sOCW1;
            elsif (wra0_s='1' AND dbus_in(3)='0'
                   AND dbus_in(4)='0') then 
               if (wrn='0') then 
                    ocw2_reg_s <= dbus_in;
               end if;
               next_state <= sOCW2a;
            elsif ((wra0_s='1' AND dbus_in(3)='1'
                   AND dbus_in(4)='0') OR  rd_s='1') then 
               next_state <= sOCW3;
            else
               next_state <= sw2;
            end if;
         when sICW4 => 
            next_state <= sw4;
         when sOCW1 => 
            if (idle_s='1') then 
               next_state <= sw4;
            else
               next_state <= sOCW1;
            end if;
         when sRESET => 
            if (init_s='1') then 
               next_state <= sICW1;
            else
               next_state <= sRESET;
            end if;
         when sw0 => 
            if (init_s='1') then 
               next_state <= sICW1;
            elsif (wra1_s='1') then 
               next_state <= sICW2;
            else
               next_state <= sw0;
            end if;
         when sw4 => 
            if (init_s='1') then 
               next_state <= sICW1;
            elsif (wra0_s='1' AND dbus_in(3)='0'
                   AND dbus_in(4)='0') then 
               if (wrn='0') then 
                    ocw2_reg_s <= dbus_in;
               end if;
               next_state <= sOCW2a;
            elsif (wra1_s='1') then 
               next_state <= sOCW1;
            elsif ((wra0_s='1' AND dbus_in(3)='1'
                   AND dbus_in(4)='0') OR  rd_s='1') then 
               next_state <= sOCW3;
            else
               next_state <= sw4;
            end if;
         when sOCW2b => 
            if (idle_s='1') then 
               next_state <= sw4;
            else
               next_state <= sOCW2b;
            end if;
         when sOCW3 => 
            if (idle_s='1') then 
               next_state <= sw4;
            else
               next_state <= sOCW3;
            end if;
         when sOCW2a => 
            next_state <= sOCW2b;
         when others =>
            next_state <= sICW1;
      end case;
   end process nextstate_proc;
 
   -- Concurrent Statements
   -- Clocked output assignments
   icw2_reg_s <= icw2_reg_s_cld;
   icw3_reg_s <= icw3_reg_s_cld;
   icw4_reg_s <= icw4_reg_s_cld;
   ocw1_reg_s <= ocw1_reg_s_cld;
   ocw3_reg_s <= ocw3_reg_s_cld;
   icw1_reg_s <= icw1_reg_s_cld;
end fsm;
