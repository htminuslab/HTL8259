-------------------------------------------------------------------------------
--  HTL8259 - PIC core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8259                                                   --
-- Purpose       : Top Level                                                 --
-- Library       : I8259                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  05/09/2005                                           --
--               : 1.2  04/07/2010   Removed dbus output mux FF              --
--               : 1.3  21/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

entity HTL8259A is
   port( 
      a0       : in     std_logic;
      cas_in   : in     std_logic_vector (2 downto 0);
      clk      : in     std_logic;
      csn      : in     std_logic;
      dbus_in  : in     std_logic_vector (7 downto 0);
      inta     : in     std_logic;
      ir       : in     std_logic_vector (7 downto 0);
      rdn      : in     std_logic;
      resetn   : in     std_logic;
      spen_in  : in     std_logic;
      wrn      : in     std_logic;
      cas_out  : out    std_logic_vector (2 downto 0);
      dbus_out : out    std_logic_vector (7 downto 0);
      dbus_tri : out    std_logic;
      int      : out    std_logic;
      spen_out : out    std_logic;
      spen_tri : out    std_logic);
end HTL8259A ;

architecture struct of HTL8259A is

   -- Architecture declarations
   signal vec1_8085_s : std_logic_vector(7 downto 0):="11001101";   -- First vector, CALL Code
   signal vec2_8085_s : std_logic_vector(7 downto 0);
   signal vec3_8085_s : std_logic_vector(7 downto 0);
   signal inta_sel_s       : std_logic_vector(2 downto 0);
   signal sel_inta2_8085_s : std_logic_vector(3 downto 0);
   signal intvector_s     : std_logic_vector(2 downto 0);
   signal dbus_sel_s : std_logic_vector(1 downto 0);

   -- Internal signal declarations
   signal aeoi           : std_logic;
   signal clr_irr        : std_logic;
   signal cmd            : std_logic_vector(1 downto 0);
   signal freeze         : std_logic;
   signal icw1_reg_s     : std_logic_vector(7 downto 0);
   signal icw2_reg_s     : std_logic_vector(7 downto 0);
   signal icw3_reg_s     : std_logic_vector(7 downto 0);
   signal icw4_reg_s     : std_logic_vector(7 downto 0);
   signal idle_s         : std_logic;
   signal init_s         : std_logic;
   signal inta1          : std_logic;
   signal inta2          : std_logic;
   signal inta3          : std_logic;
   signal irlevel        : std_logic_vector(2 downto 0);
   signal irr            : std_logic_vector(7 downto 0);
   signal isr            : std_logic_vector(7 downto 0);
   signal ld_irlevel     : std_logic;
   signal ld_isr         : std_logic;
   signal ld_rot         : std_logic;
   signal ltim           : std_logic;
   signal m8086_s        : std_logic;
   signal ms_s           : std_logic;
   signal ocw1_reg_s     : std_logic_vector(7 downto 0);
   signal ocw2_reg_s     : std_logic_vector(7 downto 0);
   signal ocw2cmd        : std_logic_vector(2 downto 0);
   signal ocw3_reg_s     : std_logic_vector(7 downto 0);
   signal pollcmd        : std_logic;
   signal prisbit        : std_logic_vector(3 downto 0);
   signal rd_s           : std_logic;
   signal reqisr         : std_logic_vector(2 downto 0);
   signal rot_aeoi_s     : std_logic;
   signal sfn_mode       : std_logic;
   signal slave_cas_s    : std_logic;
   signal slave_int_s    : std_logic;
   signal special_mask_s : std_logic;
   signal vector         : std_logic_vector(3 downto 0);
   signal wra0_s         : std_logic;
   signal wra1_s         : std_logic;

   -- Implicit buffer signal declarations
   signal dbus_tri_internal : std_logic;
   signal int_internal      : std_logic;

   -- Component Declarations
   component backend
   port (
      clk     : in     std_logic;
      clr_irr : in     std_logic;
      cmd     : in     std_logic_vector (1 downto 0);
      init_s  : in     std_logic;
      irlevel : in     std_logic_vector (2 downto 0);
      ld_isr  : in     std_logic;
      prisbit : in     std_logic_vector (3 downto 0);
      resetn  : in     std_logic;
      isr     : out    std_logic_vector (7 downto 0);
      reqisr  : out    std_logic_vector (2 downto 0);
      vector  : out    std_logic_vector (3 downto 0)
   );
   end component;
   component ctrl
   port (
      aeoi        : in     std_logic ;
      clk         : in     std_logic ;
      inta        : in     std_logic ;
      m8086_s     : in     std_logic ;
      ms_s        : in     std_logic ;
      ocw2cmd     : in     std_logic_vector (2 downto 0);
      pollcmd     : in     std_logic ;
      rd_s        : in     std_logic ;
      resetn      : in     std_logic ;
      rot_aeoi_s  : in     std_logic ;
      slave_cas_s : in     std_logic ;
      clr_irr     : out    std_logic ;
      cmd         : out    std_logic_vector (1 downto 0);
      freeze      : out    std_logic ;
      inta1       : out    std_logic ;
      inta2       : out    std_logic ;
      inta3       : out    std_logic ;
      ld_isr      : out    std_logic ;
      ld_rot      : out    std_logic 
   );
   end component;
   component frontend
   port (
      clk        : in     std_logic;
      clr_irr    : in     std_logic;
      freeze     : in     std_logic;
      icw3_reg_s : in     std_logic_vector (7 downto 0);
      init_s     : in     std_logic;
      ir         : in     std_logic_vector (7 downto 0);
      ltim       : in     std_logic;
      ms_s       : in     std_logic;
      ocw1_reg_s : in     std_logic_vector (7 downto 0);
      pollcmd    : in     std_logic;
      reqisr     : in     std_logic_vector (2 downto 0);
      resetn     : in     std_logic;
      irr        : out    std_logic_vector (7 downto 0)
   );
   end component;
   component priority
   port (
      clk            : in     std_logic;
      icw3_reg_s     : in     std_logic_vector (7 downto 0);
      init_s         : in     std_logic;
      irlevel        : in     std_logic_vector (2 downto 0);
      irr            : in     std_logic_vector (7 downto 0);
      ld_irlevel     : in     std_logic;
      ld_rot         : in     std_logic;
      resetn         : in     std_logic;
      sfn_mode       : in     std_logic;
      special_mask_s : in     std_logic;
      vector         : in     std_logic_vector (3 downto 0);
      int            : out    std_logic;
      prisbit        : out    std_logic_vector (3 downto 0)
   );
   end component;
   component wrctrl
   port (
      clk        : in     std_logic ;
      dbus_in    : in     std_logic_vector (7 downto 0);
      idle_s     : in     std_logic ;
      init_s     : in     std_logic ;
      rd_s       : in     std_logic ;
      resetn     : in     std_logic ;
      wra0_s     : in     std_logic ;
      wra1_s     : in     std_logic ;
      wrn        : in     std_logic ;
      icw2_reg_s : out    std_logic_vector (7 downto 0);
      icw3_reg_s : out    std_logic_vector (7 downto 0);
      icw4_reg_s : out    std_logic_vector (7 downto 0);
      ocw1_reg_s : out    std_logic_vector (7 downto 0);
      ocw2_reg_s : out    std_logic_vector (7 downto 0);
      ocw3_reg_s : out    std_logic_vector (7 downto 0);
      icw1_reg_s : buffer std_logic_vector (7 downto 0)
   );
   end component;


begin

       wra0_s <= '1' when (a0='0' AND csn='0' AND wrn='0') else '0';  
       wra1_s <= '1' when (a0='1' AND csn='0' AND wrn='0') else '0';  
       init_s <= '1' when (a0='0' AND csn='0' AND wrn='0' and dbus_in(4)='1') else '0';
       idle_s <= '1' when (csn='1' OR wrn='1') else '0';
   
       rd_s <= '1' when (rdn='0' and csn='0') else '0';
   
       ---------------------------------------------------------------------------
       -- If ISR register is empty (vector(3)='1') then feed a spurious vector 7
       ---------------------------------------------------------------------------
       intvector_s <= vector(2 downto 0) when vector(3)='0' else "111";
   
   
       ---------------------------------------------------------------------------
       -- dbus_out <= Master interrupt vector during inta2 when master interrupt
       -- dbus_out <= Slave interrupt vector during inta2 when slave and CAS=slave_ID
       -- dbus_out <= IRR  register when a0=0 and RR=1 and RIS=0
       -- dbus_out <= IS   register when a0=1 and RR=1 and RIS=1
       -- dbus_out <= OCW1 register when a0=1 
       ---------------------------------------------------------------------------
       dbus_sel_s <= a0 & ocw3_reg_s(2);  
       inta_sel_s <= inta3 & inta2 & inta1;
   
       -- process (clk)  -- dbus output mux      version 1.2, extra time for dbus           
       process (inta_sel_s,icw2_reg_s,intvector_s,irr,isr,ocw3_reg_s,ocw1_reg_s,reqisr,int_internal)  -- dbus output mux
           begin
               --if rising_edge(clk) then
                   case inta_sel_s is 
                       when "110"  => dbus_out <= vec1_8085_s; 
                       when "101"  => if m8086_s='1' then      -- 8086 mode
                               dbus_out <= icw2_reg_s(7 downto 3) & intvector_s;  -- 8086 mode int_internal number 
                            else
                               dbus_out <= vec2_8085_s;        -- 8085 mode, write second inta vector 
                            end if;
                       when "011"  => dbus_out <= vec3_8085_s; -- 8085 mode, write third inta vector
                       when others =>                          -- Status, polling 
                           case dbus_sel_s is 
                               when "00"   => if ocw3_reg_s(0)='0' then 
                                                  dbus_out <= irr; 
                                              else 
                                                  dbus_out <= isr; 
                                              end if;
                               when "10"   => dbus_out <= ocw1_reg_s; 
                               when others => dbus_out <= int_internal & "0000" & reqisr;  -- a0=don't care, ocw3_reg_s(1..0)=don't care
                           end case;
                   end case;
         --  end if;
       end process;   
   
   
       ---------------------------------------------------------------------------
       -- DataBus tri state signal, if asserted (1) read mode into the 8259 (default) if 
       -- negated(0) then the 8259 is writing data to the databus (status, int_internal vector)
       -- Master ms_s='1'
       -- dbus_tri_internal is also negated when the 8259 is in 8085 mode and the first and third INTA
       -- cycle is active. The second INTA cycle the driver is always negated.
       ---------------------------------------------------------------------------
       dbus_tri_internal<='0' when (csn='0' AND rdn='0')  
                  or  ((inta2='0' OR ((inta1='0' OR inta3='0') AND m8086_s='0')) AND ms_s='1' AND slave_int_s='0')   
                  or  ((inta2='0' OR ((inta1='0' OR inta3='0') AND m8086_s='0')) AND ms_s='0' AND slave_cas_s='1' AND prisbit(3)='1') else '1';
   
   
       ---------------------------------------------------------------------------
       -- 8085/8080 Mode
       ---------------------------------------------------------------------------
       vec3_8085_s <= icw2_reg_s;     -- Third vector
   
       sel_inta2_8085_s <= icw1_reg_s(2) & prisbit(2 downto 0);
   
       ---------------------------------------------------------------------------
       -- Second vector
       ---------------------------------------------------------------------------
       process (sel_inta2_8085_s,icw1_reg_s)                                                  
           begin
               case sel_inta2_8085_s is 
                  when "1000"  => vec2_8085_s <= icw1_reg_s(7 downto 5) & "00000";      -- Interval=4 (ICW1(2))
                  when "1001"  => vec2_8085_s <= icw1_reg_s(7 downto 5) & "00100";  
                  when "1010"  => vec2_8085_s <= icw1_reg_s(7 downto 5) & "01000";
                  when "1011"  => vec2_8085_s <= icw1_reg_s(7 downto 5) & "01100";  
                  when "1100"  => vec2_8085_s <= icw1_reg_s(7 downto 5) & "10000";  
                  when "1101"  => vec2_8085_s <= icw1_reg_s(7 downto 5) & "10100";  
                  when "1110"  => vec2_8085_s <= icw1_reg_s(7 downto 5) & "11000";
                  when "1111"  => vec2_8085_s <= icw1_reg_s(7 downto 5) & "11100";
                  
                  when "0000"  => vec2_8085_s <= icw1_reg_s(7 downto 6) & "000000";      -- Interval=8
                  when "0001"  => vec2_8085_s <= icw1_reg_s(7 downto 6) & "001000";  
                  when "0010"  => vec2_8085_s <= icw1_reg_s(7 downto 6) & "010000";
                  when "0011"  => vec2_8085_s <= icw1_reg_s(7 downto 6) & "011000";  
                  when "0100"  => vec2_8085_s <= icw1_reg_s(7 downto 6) & "100000";  
                  when "0101"  => vec2_8085_s <= icw1_reg_s(7 downto 6) & "101000";  
                  when "0110"  => vec2_8085_s <= icw1_reg_s(7 downto 6) & "110000";
                  when others  => vec2_8085_s <= icw1_reg_s(7 downto 6) & "111000";
               end case;
       end process;

       ltim    <= icw1_reg_s(3);
   
       aeoi    <= icw4_reg_s(1);                           -- Automatic End Of Interrupt
       m8086_s <= icw4_reg_s(0);                           -- 0=8085 mode, 1=8086 mode (default?)
       sfn_mode <= icw4_reg_s(4);                          -- Special Fully Nested Mode
   
       ---------------------------------------------------------------------------
       -- End Of Interrupt Commands
       ---------------------------------------------------------------------------
       ocw2cmd    <= ocw2_reg_s(7 downto 5);
       irlevel    <= ocw2_reg_s(2 downto 0);
       ld_irlevel <= '1' when ocw2_reg_s(7 downto 5)="110" else '0';
   
       ---------------------------------------------------------------------------
       -- Poll Mode, bit set until next read command (any read!)
       -- signal is clocked to extend 1 clk cycle after rd strobe
       -- is negated. This means that the clr_irr command which
       -- occurs 1 clk cycle after the read strobe can not kill
       -- an IR pulse which occurs during this time.
       ---------------------------------------------------------------------------
       process (clk,resetn)                                    
          begin
              if (resetn='0') then                     
                 pollcmd <= '0';              
              elsif (rising_edge(clk)) then 
                   pollcmd <= ocw3_reg_s(2);
              end if;   
       end process;
   
       ---------------------------------------------------------------------------
       -- Clear/Set Rotate on AEOI
       -- Note AEOI cleared on writing to ICW1, this is not in the datasheets but it
       -- makes perfect sense.
       ---------------------------------------------------------------------------
       process (clk,resetn)                                    
          begin
              if (resetn='0') then                     
                 rot_aeoi_s <= '0';              
              elsif (rising_edge(clk)) then 
                 if (ocw2_reg_s(7 downto 5)="000" OR init_s='1') then
                    rot_aeoi_s <= '0';              
                 elsif ocw2_reg_s(7 downto 5)="100" then
                     rot_aeoi_s <= '1';
                 end if;       
              end if;   
       end process;
                               
       ---------------------------------------------------------------------------
       -- Clear/Set Special Mask Mode signal
       -- Cleared on ICW1 write (init_s=1)
       ---------------------------------------------------------------------------
       process (clk,resetn)                                    
          begin
              if (resetn='0') then                     
                 special_mask_s <= '0';              
              elsif (rising_edge(clk)) then 
                 if (ocw3_reg_s(6 downto 5)="10" OR init_s='1') then   
                    special_mask_s <= '0';              
                 elsif ocw3_reg_s(6 downto 5)="11" then
                     special_mask_s <= '1';
                 end if;       
              end if;   
       end process;

       ---------------------------------------------------------------------------
       -- cas_out only valid when Master (spen='1') and prisbit is slave input
       ---------------------------------------------------------------------------
       process (prisbit, icw3_reg_s)                                                  
           begin
               case prisbit(2 downto 0) is 
                  when "000"  => cas_out<="000";   -- default value
                  when "001"  => if icw3_reg_s(1)='1' then cas_out <= "001"; else cas_out<="000"; end if;   
                  when "010"  => if icw3_reg_s(2)='1' then cas_out <= "010"; else cas_out<="000"; end if;
                  when "011"  => if icw3_reg_s(3)='1' then cas_out <= "011"; else cas_out<="000"; end if;   
                  when "100"  => if icw3_reg_s(4)='1' then cas_out <= "100"; else cas_out<="000"; end if;   
                  when "101"  => if icw3_reg_s(5)='1' then cas_out <= "101"; else cas_out<="000"; end if;   
                  when "110"  => if icw3_reg_s(6)='1' then cas_out <= "110"; else cas_out<="000"; end if;
                  when others => if icw3_reg_s(7)='1' then cas_out <= "111"; else cas_out<="000"; end if;
               end case;
       end process;    
   
   
       ---------------------------------------------------------------------------
       -- Buffered mode.
       -- program icw4(3)='1' to enable buffered mode
       -- Signal used to drive bus transceivers, active low!!
       ---------------------------------------------------------------------------
       spen_out <= '0' when ((rd_s='1' OR (m8086_s='1' AND inta2='0') OR (m8086_s='0' AND (inta1='0' OR inta2='0' OR inta3='0'))) 
                           AND icw4_reg_s(3)='1' AND dbus_tri_internal='0') else '1';
       spen_tri <= icw4_reg_s(3) AND (NOT dbus_tri_internal);      -- enable tri-state driver, active high
   
       ---------------------------------------------------------------------------
       -- If buffered mode then icw4_reg_s(2) determines master(1) or slave(0), else use spen_in signal
       -- spen_in=1-> master mode
       -- spen_in=0-> slave mode
       ---------------------------------------------------------------------------
       ms_s <= icw4_reg_s(2) when icw4_reg_s(3)='1' else spen_in;
   
       ---------------------------------------------------------------------------
       -- When in Slave Mode
       -- Compare slave_id against stored value in icw3 register 
       -- Assert slave_cas_s when equal.
       ---------------------------------------------------------------------------
       slave_cas_s <= '1' when cas_in=icw3_reg_s(2 downto 0)  else '0';
   
       ---------------------------------------------------------------------------
       -- When in Master Mode
       -- Compare IR request to see if it is coming from a slave (icw3(IR_input)='1')
       ---------------------------------------------------------------------------
       process (prisbit,icw3_reg_s, ms_s)
           begin
              if ms_s='1' then                     -- Are we the master?
                  case prisbit(2 downto 0) is          -- yes, check if slave is requesting int_internal
                     when "000"  => if icw3_reg_s(0)='1' then slave_int_s <= '1'; 
                                                         else slave_int_s <= '0'; 
                                    end if;            
                     when "001"  => if icw3_reg_s(1)='1' then slave_int_s <= '1'; 
                                                         else slave_int_s <= '0'; 
                                    end if;
                     when "010"  => if icw3_reg_s(2)='1' then slave_int_s <= '1'; 
                                                         else slave_int_s <= '0'; 
                                    end if;
                     when "011"  => if icw3_reg_s(3)='1' then slave_int_s <= '1'; 
                                                         else slave_int_s <= '0'; 
                                    end if;   
                     when "100"  => if icw3_reg_s(4)='1' then slave_int_s <= '1'; 
                                                         else slave_int_s <= '0'; 
                                    end if;   
                     when "101"  => if icw3_reg_s(5)='1' then slave_int_s <= '1'; 
                                                         else slave_int_s <= '0'; 
                                    end if;   
                     when "110"  => if icw3_reg_s(6)='1' then slave_int_s <= '1'; 
                                                         else slave_int_s <= '0'; 
                                    end if;
                     when others => if icw3_reg_s(7)='1' then slave_int_s <= '1'; 
                                                         else slave_int_s <= '0'; 
                                    end if;
                  end case;
             else
                slave_int_s <= '0';
             end if;
       end process;


   -- Instance port mappings.
   U_2 : backend
      port map (
         clk     => clk,
         cmd     => cmd,
         irlevel => irlevel,
         ld_isr  => ld_isr,
         prisbit => prisbit,
         resetn  => resetn,
         isr     => isr,
         reqisr  => reqisr,
         init_s  => init_s,
         vector  => vector,
         clr_irr => clr_irr
      );
   U_4 : ctrl
      port map (
         aeoi        => aeoi,
         clk         => clk,
         inta        => inta,
         m8086_s     => m8086_s,
         ms_s        => ms_s,
         ocw2cmd     => ocw2cmd,
         pollcmd     => pollcmd,
         rd_s        => rd_s,
         resetn      => resetn,
         rot_aeoi_s  => rot_aeoi_s,
         slave_cas_s => slave_cas_s,
         clr_irr     => clr_irr,
         cmd         => cmd,
         freeze      => freeze,
         inta1       => inta1,
         inta2       => inta2,
         inta3       => inta3,
         ld_isr      => ld_isr,
         ld_rot      => ld_rot
      );
   U_0 : frontend
      port map (
         ir         => ir,
         clk        => clk,
         ltim       => ltim,
         resetn     => resetn,
         irr        => irr,
         ocw1_reg_s => ocw1_reg_s,
         clr_irr    => clr_irr,
         reqisr     => reqisr,
         init_s     => init_s,
         freeze     => freeze,
         pollcmd    => pollcmd,
         icw3_reg_s => icw3_reg_s,
         ms_s       => ms_s
      );
   U_1 : priority
      port map (
         irr            => irr,
         prisbit        => prisbit,
         int            => int_internal,
         resetn         => resetn,
         clk            => clk,
         init_s         => init_s,
         irlevel        => irlevel,
         ld_irlevel     => ld_irlevel,
         ld_rot         => ld_rot,
         vector         => vector,
         icw3_reg_s     => icw3_reg_s,
         sfn_mode       => sfn_mode,
         special_mask_s => special_mask_s
      );
   U_3 : wrctrl
      port map (
         clk        => clk,
         dbus_in    => dbus_in,
         idle_s     => idle_s,
         init_s     => init_s,
         rd_s       => rd_s,
         resetn     => resetn,
         wra0_s     => wra0_s,
         wra1_s     => wra1_s,
         wrn        => wrn,
         icw2_reg_s => icw2_reg_s,
         icw3_reg_s => icw3_reg_s,
         icw4_reg_s => icw4_reg_s,
         ocw1_reg_s => ocw1_reg_s,
         ocw2_reg_s => ocw2_reg_s,
         ocw3_reg_s => ocw3_reg_s,
         icw1_reg_s => icw1_reg_s
      );

    dbus_tri <= dbus_tri_internal;
    int      <= int_internal;

end struct;
