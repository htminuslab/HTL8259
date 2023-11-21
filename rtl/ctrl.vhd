-------------------------------------------------------------------------------
--  HTL8259 - PIC core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8259                                                   --
-- Purpose       : FSM Controller                                            --
-- Library       : I8259                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  05/09/2005                                           --
--               : 1.2  21/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.STD_LOGIC_UNSIGNED.all;

entity ctrl is
   port( 
      aeoi        : in     std_logic;
      clk         : in     std_logic;
      inta        : in     std_logic;
      m8086_s     : in     std_logic;
      ms_s        : in     std_logic;
      ocw2cmd     : in     std_logic_vector (2 downto 0);
      pollcmd     : in     std_logic;
      rd_s        : in     std_logic;
      resetn      : in     std_logic;
      rot_aeoi_s  : in     std_logic;
      slave_cas_s : in     std_logic;
      clr_irr     : out    std_logic;
      cmd         : out    std_logic_vector (1 downto 0);
      freeze      : out    std_logic;
      inta1       : out    std_logic;
      inta2       : out    std_logic;
      inta3       : out    std_logic;
      ld_isr      : out    std_logic;
      ld_rot      : out    std_logic);
end ctrl ;
 
architecture fsm of ctrl is

   type state_type is (
      swait,
      sINTA1,
      sw1,
      sINTA2,
      sw0,
      sw2,
      sPOLL1,
      sPOLL2,
      snseoi,
      sseoi,
      sseoir,
      snseoir,
      sw3,
      sINTA3,
      sw4
   );
 
   signal current_state : state_type;
   signal next_state : state_type;

begin

   clocked_proc : process (clk,resetn)
   begin
      if (resetn = '0') then
         current_state <= swait;
      elsif (clk'event and clk = '1') then
         current_state <= next_state;
      end if;
   end process clocked_proc;
 
   nextstate_proc : process ( 
      aeoi,
      current_state,
      inta,
      m8086_s,
      ms_s,
      ocw2cmd,
      pollcmd,
      rd_s,
      rot_aeoi_s,
      slave_cas_s
   )
   begin

      clr_irr <= '0';
      cmd <= (others => '0');
      freeze <= '0';
      inta1 <= '1';
      inta2 <= '1';
      inta3 <= '1';
      ld_isr <= '0';
      ld_rot <= '0';

      case current_state is
         when swait => 
            if (rd_s='1' AND
                pollcmd='1') then 
               next_state <= sPOLL1;
            elsif (ocw2cmd="001") then 
               next_state <= snseoi;
            elsif (ocw2cmd="011") then 
               next_state <= sseoi;
            elsif (ocw2cmd="111") then 
               next_state <= sseoir;
            elsif (ocw2cmd="101") then 
               next_state <= snseoir;
            elsif (inta='0' and (ms_s='1' OR (ms_s='0' AND slave_cas_s='1'))) then 
               inta1<=inta;
               freeze<='1';
               next_state <= sINTA1;
            else
               next_state <= swait;
            end if;
         when sINTA1 => 
            --clr_irr <= '1';
            ld_isr <= '1';
            cmd <= "00";
            inta1<=inta;
            freeze<='1';
            clr_irr <= '1';                             -- ver 1.1
            next_state <= sw0;
         when sw1 => 
            freeze<='1';
            if (inta='0') then 
               inta2<=inta;
               next_state <= sINTA2;
            else
               next_state <= sw1;
            end if;
         when sINTA2 => 
            if aeoi='1' then
                cmd<="01";                              -- clear ISR  if AEOI
                ld_isr<= '1';                           -- Non-Specific EOI
                ld_rot<=rot_aeoi_s;
            end if;
            inta2<=inta;
            if  m8086_s='0' then                        -- version 1.2 Adam Z80
               freeze<='1'; 
            end if;
            next_state <= sw2;
         when sw0 => 
            inta1<=inta;
            freeze<='1';
            if (inta='1') then 
               next_state <= sw1;
            else
               next_state <= sw0;
            end if;
         when sw2 => 
            inta2<=inta;
            if  m8086_s='0' then -- version 1.2 Adam Z80
               freeze<='1'; 
            end if;
            if (m8086_s='1' 
                AND inta='1') then 
               next_state <= swait;
            elsif (m8086_s='0' 
                   AND inta='1' ) then 
               next_state <= sw3;
            else
               next_state <= sw2;
            end if;
         when sPOLL1 => 
            ld_isr <= '1';
            cmd <= "00";
            if (rd_s='0') then 
               clr_irr <= '1'; -- ver 1.1
               next_state <= sPOLL2;
            else
               next_state <= sPOLL1;
            end if;
         when sPOLL2 => 
            if aeoi='1' then
                cmd<="01";                              -- clear ISR  if AEOI
                ld_isr<= '1';                           -- Non-Specific EOI
                ld_rot<=rot_aeoi_s;
            end if;
            next_state <= swait;
         when snseoi => 
            cmd<="01";
            ld_isr<='1';
            next_state <= swait;
         when sseoi => 
            cmd<="11";
            ld_isr<='1';
            next_state <= swait;
         when sseoir => 
            cmd<="11";
            ld_isr<='1';
            ld_rot<='1';
            next_state <= swait;
         when snseoir => 
            cmd<="01";
            ld_isr<='1';
            ld_rot<='1';
            next_state <= swait;
         when sw3 => 
            freeze<='1';
            if (inta='0') then 
               inta3<=inta;
               next_state <= sINTA3;
            else
               next_state <= sw3;
            end if;
         when sINTA3 => 
            inta3<=inta;
            --freeze<='1';
            next_state <= sw4;
         when sw4 => 
            inta3<=inta;
            --freeze<='1';
            if (inta='1') then 
               next_state <= swait;
            else
               next_state <= sw4;
            end if;
         when others =>
            next_state <= swait;
      end case;
   end process nextstate_proc;
 
end fsm;
