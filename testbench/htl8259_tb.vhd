-------------------------------------------------------------------------------
--  HTL8259 - PIC core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8259                                                   --
-- Purpose       : Testbench                                                 --
-- Library       : I8259                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  05/09/2005                                           --
--               : 1.2  21/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
entity HTL8259_tb is
end HTL8259_tb;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

architecture struct of HTL8259_tb is

   -- Architecture declarations

   -- Internal signal declarations
   signal IR            : std_logic_vector(15 downto 0);
   signal abus          : std_logic_vector(15 downto 0);
   signal buffer_mode_s : std_logic;
   signal cas_in        : std_logic_vector(2 downto 0);
   signal cas_m2s       : std_logic_vector(2 downto 0);
   signal clk           : std_logic;
   signal csmn_s        : std_logic;
   signal cssn_s        : std_logic;
   signal dbus          : std_logic_vector(7 downto 0);
   signal dbus_inm      : std_logic_vector(7 downto 0);
   signal dbus_ins      : std_logic_vector(7 downto 0);
   signal dbus_outm     : std_logic_vector(7 downto 0);
   signal dbus_outs     : std_logic_vector(7 downto 0);
   signal dbus_trim     : std_logic;
   signal dbus_tris     : std_logic;
   signal int           : std_logic;
   signal inta          : std_logic;
   signal irq2_s        : std_logic;
   signal irqm_s        : std_logic_vector(7 downto 0);
   signal rdmn_s        : std_logic;
   signal rdn           : std_logic;
   signal rdsn_s        : std_logic;
   signal resetn        : std_logic;
   signal spen_inm      : std_logic;
   signal spen_ins      : std_logic;
   signal spen_outm     : std_logic;
   signal spen_outs     : std_logic;
   signal spen_trim     : std_logic;
   signal spen_tris     : std_logic;
   signal spenm         : std_logic;
   signal spens         : std_logic;
   signal wrn           : std_logic;


   -- Component Declarations
   component HTL8259A
   port (
      a0       : in     std_logic ;
      cas_in   : in     std_logic_vector (2 downto 0);
      clk      : in     std_logic ;
      csn      : in     std_logic ;
      dbus_in  : in     std_logic_vector (7 downto 0);
      inta     : in     std_logic ;
      ir       : in     std_logic_vector (7 downto 0);
      rdn      : in     std_logic ;
      resetn   : in     std_logic ;
      spen_in  : in     std_logic ;
      wrn      : in     std_logic ;
      cas_out  : out    std_logic_vector (2 downto 0);
      dbus_out : out    std_logic_vector (7 downto 0);
      dbus_tri : out    std_logic ;
      int      : out    std_logic ;
      spen_out : out    std_logic ;
      spen_tri : out    std_logic 
   );
   end component;
   component htl8259_tester
   port (
      int           : in     std_logic;
      abus          : out    std_logic_vector (15 downto 0);
      buffer_mode_s : out    std_logic;
      cas_in        : out    std_logic_vector (2 downto 0);
      clk           : out    std_logic;
      inta          : out    std_logic;
      rdn           : out    std_logic;
      resetn        : out    std_logic;
      wrn           : out    std_logic;
      dbus          : inout  std_logic_vector (7 downto 0);
      IR            : buffer std_logic_vector (15 downto 0)
   );
   end component;

begin

   ---------------------------------------------------------------------------
   -- Master 20/21
   -- Slave A0/A1
   ---------------------------------------------------------------------------
   csmn_s <= '0' when (abus=X"0020" OR abus=X"0021") else '1' after 4 ns;
   cssn_s <= '0' when (abus=X"00A0" OR abus=X"00A1") else '1' after 4 ns;

   process (rdmn_s,dbus_outm)
         begin       
         case rdmn_s is
             when '0'    => dbus<= dbus_outm;          -- drive port
             when others => dbus<= (others => 'Z');         
         end case;         
   end process;   

   dbus_inm <= dbus;                                   -- cpu write to 8259

   process (rdsn_s,dbus_outs)
         begin       
         case rdsn_s is
             when '0'    => dbus<= dbus_outs;          -- drive port, read status, int vector
             when others => dbus<= (others => 'Z');         
         end case;         
   end process;   

   dbus_ins <= dbus;                                   -- CPU writes to 8259

   process (spen_trim,spen_outm)
         begin       
         case spen_trim is
             when '1'    => spenm<= spen_outm; -- drive port
             when others => spenm<= 'Z';         
         end case;         
   end process;   
   spen_inm <= spenm;
                                  
   process (spen_tris,spen_outs)
       begin       
           case spen_tris is
               when '1'    => spens<= spen_outs; -- drive port
               when others => spens<= 'Z';         
           end case;         
   end process;   
   spen_ins <= spens;

   ---------------------------------------------------------------------------
   -- If Buffered mode then use spen to control the tri-state line drivers
   -- else use spen as an input signal to select master(1) or slave(0)
   ---------------------------------------------------------------------------
   process (buffer_mode_s,spenm,spens,abus,rdn, inta,dbus_trim,dbus_tris,csmn_s,cssn_s,spen_outm,spen_outs)
      begin
           if buffer_mode_s='1' then
               rdmn_s <= spen_outm AND (csmn_s OR rdn); --spenm;
               rdsn_s <= spen_outs AND (cssn_s OR rdn); --spens;
               spenm<='1';
               spens<='1';
           else
               rdmn_s <= dbus_trim;   
               rdsn_s <= dbus_tris;               
               spenm<='1';
               spens<='0';
           end if;   
   end process;
   
    ---------------------------------------------------------------------------
    -- Slave is connected to IRQ2 of Master
    ---------------------------------------------------------------------------
    irqm_s <= IR(7 downto 3) & irq2_s & IR(1 downto 0);
   
   -- Instance port mappings.
   U_0 : HTL8259A
      port map (
         IR       => irqm_s,
         a0       => abus(0),
         cas_in   => cas_in,
         clk      => clk,
         csn      => csmn_s,
         dbus_in  => dbus_inm,
         inta     => inta,
         rdn      => rdn,
         resetn   => resetn,
         spen_in  => spen_inm,
         wrn      => wrn,
         cas_out  => cas_m2s,
         dbus_out => dbus_outm,
         dbus_tri => dbus_trim,
         int      => int,
         spen_out => spen_outm,
         spen_tri => spen_trim
      );
   U_2 : HTL8259A
      port map (
         IR       => IR(15 DOWNTO 8),
         a0       => abus(0),
         cas_in   => cas_m2s,
         clk      => clk,
         csn      => cssn_s,
         dbus_in  => dbus_ins,
         inta     => inta,
         rdn      => rdn,
         resetn   => resetn,
         spen_in  => spen_ins,
         wrn      => wrn,
         cas_out  => open,
         dbus_out => dbus_outs,
         dbus_tri => dbus_tris,
         int      => irq2_s,
         spen_out => spen_outs,
         spen_tri => spen_tris
      );
   U_1 : htl8259_tester
      port map (
         int           => int,
         abus          => abus,
         buffer_mode_s => buffer_mode_s,
         cas_in        => cas_in,
         clk           => clk,
         inta          => inta,
         rdn           => rdn,
         resetn        => resetn,
         wrn           => wrn,
         dbus          => dbus,
         IR            => IR
      );

end struct;
