-------------------------------------------------------------------------------
--  HTL8259 - PIC core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8259                                                   --
-- Purpose       :                                                           --
-- Library       : I8259                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  05/09/2005                                           --
--               : 1.2  30/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.STD_LOGIC_UNSIGNED.all;

entity pulselevel is
   port( 
      clk     : in     std_logic;
      init    : in     std_logic;
      ir      : in     std_logic;
      pollcmd : in     std_logic;
      resetn  : in     std_logic;
      level   : out    std_logic;
      pulse   : out    std_logic);
end pulselevel ;
 
architecture fsm of pulselevel is

   type state_type is (
      sWIR1,
      sIRrec,
      sWIR0,
      sWpoll
   );
 
   -- Declare current and next state signals
   signal current_state : state_type;
   signal next_state : state_type;

begin

   clocked_proc : process (clk,resetn)
   begin
      if (resetn = '0') then
         current_state <= sWIR1;
      elsif (clk'event and clk = '1') then
         if (init = '1') then
            current_state <= sWIR1;
         else
            current_state <= next_state;
         end if;
      end if;
   end process clocked_proc;
 
   nextstate_proc : process (current_state,ir,pollcmd)
   begin
      -- Default Assignment
      level <= '0';
      pulse <= '0';

      -- Combined Actions
      case current_state is
         when sWIR1 => 
            if (ir='1') then 
               next_state <= sIRrec;
            else
               next_state <= sWIR1;
            end if;
         when sIRrec => 
            if (pollcmd='0') then 
               pulse <='1';
               next_state <= sWIR0;
            elsif (pollcmd='1') then 
               next_state <= sWpoll;
            else
               next_state <= sIRrec;
            end if;
         when sWIR0 => 
            level<='1';
            if (ir='0') then 
               next_state <= sWIR1;
            else
               next_state <= sWIR0;
            end if;
         when sWpoll => 
            if (pollcmd='0') then 
               pulse <='1';
               next_state <= sWIR0;
            else
               next_state <= sWpoll;
            end if;
         when others =>
            next_state <= sWIR1;
      end case;
   end process nextstate_proc;
 
end fsm;
