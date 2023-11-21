-------------------------------------------------------------------------------
--  HTL8259 - PIC core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8259                                                   --
-- Purpose       : TestBench Tester Module                                   --
-- Library       : I8259                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  05/09/2005                                           --
--               : 1.2  30/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

LIBRARY std;
USE std.TEXTIO.all;

USE work.utils.all;

ENTITY htl8259_tester IS
   PORT( 
      int           : IN     std_logic;
      abus          : OUT    std_logic_vector (15 DOWNTO 0);
      buffer_mode_s : OUT    std_logic;
      cas_in        : OUT    std_logic_vector (2 DOWNTO 0);
      clk           : OUT    std_logic;
      inta          : OUT    std_logic;
      rdn           : OUT    std_logic;
      resetn        : OUT    std_logic;
      wrn           : OUT    std_logic;
      dbus          : INOUT  std_logic_vector (7 DOWNTO 0);
      IR            : BUFFER std_logic_vector (15 DOWNTO 0));
END htl8259_tester ;


ARCHITECTURE behaviour OF htl8259_tester IS

    signal clk_s  : std_logic:='0';
    signal ms_s   : std_logic;                          -- master(1)/Slave(0) select
    signal data_s : std_logic_vector(7 downto 0);
    signal abus_s : std_logic_vector(15 downto 0);
    signal m8086_s: std_logic;                          -- Mode 8086(1) 8085(0) select

    signal icw1_s : std_logic_vector(7 downto 0);
    signal icw2_s : std_logic_vector(7 downto 0);
    signal icw3_s : std_logic_vector(7 downto 0);
    signal icw4_s : std_logic_vector(7 downto 0);
    signal ocw1_s : std_logic_vector(7 downto 0);

    signal check_s: std_logic_vector(15 downto 0);

BEGIN
    
    clk_s <= not clk_s after 40 ns;     
    clk <= clk_s;

    process
        variable L   : line;

        procedure outport(                              -- write byte to I/Oport   
            signal addr_p : in std_logic_vector(15 downto 0);-- Port Address
            signal dbus_p : in std_logic_vector(7 downto 0)) is 
            begin 
                wait until rising_edge(clk_s);
                abus <= addr_p;
                wait for 5 ns;
                wait until rising_edge(clk_s);
                wait for 3 ns;
                wrn <= '0';
                wait for 2 ns;
                dbus <= dbus_p;
                wait until rising_edge(clk_s);
                wait until rising_edge(clk_s);
                wait for 2 ns;
                abus  <= (others => 'H');
                wrn <= '1';
                dbus <= (others=>'Z');
                wait for 1 ns;
        end outport;

        procedure inport(                               -- Read from I/O port   
            signal addr_p : in std_logic_vector(15 downto 0);-- Port Address
            signal dbus_p : out std_logic_vector(7 downto 0)) is 
            begin 
                wait until rising_edge(clk_s);
                abus <= addr_p;
                wait for 5 ns;
                wait until rising_edge(clk_s);
                wait for 3 ns;
                rdn <= '0';
                wait for 2 ns;
                dbus_p <= dbus;
                wait until rising_edge(clk_s);
                wait until rising_edge(clk_s);
                wait for 2 ns;
                abus  <= (others => 'H');
                rdn <= '1';
              --  dbus_p <= (others=>'1');
                wait for 1 ns;
        end inport;

        procedure init_8259(                        -- Initialise 8259   
            signal ms_p : in std_logic) is          -- ms_p=1 for master, 0 for slave
            begin 
                if ms_p='1' then abus_s <= X"0020";
                            else abus_s <= X"00A0";
                end if;
                outport(abus_s,icw1_s);
                if ms_p='1' then abus_s <= X"0021";
                            else abus_s <= X"00A1";
                end if;
                outport(abus_s,icw2_s);
                outport(abus_s,icw3_s);
                outport(abus_s,icw4_s);
                outport(abus_s,ocw1_s);
        end init_8259;

        procedure inta_sequence is                  -- Generate Interrupt Ack Cycle
            begin                                   -- and read IR/IS/MSK registers
                
                wait for 0 ns;                      -- Display IRQ Input Status
                write(L,string'("*** Request "));
                for I in 0 to 15 loop
                    if IR(I)='1' then
                        write(L,string'(" IRQ"));
                        write(L,I);
                    end if;
                end loop;

                abus_s <= X"0020";                  -- Select IRR register on next read
                data_s <="00001010";                -- OCW3
                outport(abus_s,data_s);
                
                write(L,string'("  IRm="));
                inport(abus_s,data_s);              -- Read IR Register
                write(L,std_to_hex(data_s));

                abus_s <= X"0020";                  -- Select IS register on next read
                data_s <="00001011";                -- OCW3
                outport(abus_s,data_s);
                
                write(L,string'(" ISm="));
                inport(abus_s,data_s);              -- Read IS Register
                write(L,std_to_hex(data_s));

                write(L,string'(" MKm="));
                abus_s <= X"0021";
                inport(abus_s,data_s);              -- Read OCW1 Register
                write(L,std_to_hex(data_s));

                -----------------------------------------------------------------------
                abus_s <= X"00A0";                  -- Select Slave IRR register on next read
                data_s <="00001010";                -- OCW3
                outport(abus_s,data_s);
                
                write(L,string'("  IRs="));
                inport(abus_s,data_s);              -- Read IR Register
                write(L,std_to_hex(data_s));

                abus_s <= X"00A0";                  -- Select Slave IS register on next read
                data_s <="00001011";                -- OCW3
                outport(abus_s,data_s);
                
                write(L,string'(" ISs="));
                inport(abus_s,data_s);              -- Read IS Register
                write(L,std_to_hex(data_s));

                write(L,string'(" MKs="));
                abus_s <= X"00A1";
                inport(abus_s,data_s);              -- Read OCW1 Register
                write(L,std_to_hex(data_s));


                write(L,string'("  ->"));

                ---------------------------------------------------------------------------------
                -- INTA sequence
                ---------------------------------------------------------------------------------
                if m8086_s='0' then                 -- MC8080 Mode
                    write(L,string'(" 8080 INTA :"));               
                    wait until rising_edge(clk_s);
                    inta  <= '0';                   -- First INTA Pulse
                    wait until rising_edge(clk_s);
                    write(L,std_to_hex(dbus));
                    write(L,string'(" "));
                    wait until rising_edge(clk_s);
                    inta <= '1';
                    wait until rising_edge(clk_s);
                    wait until rising_edge(clk_s);
                    inta  <= '0';                   -- Second INTA Pulse
                    wait until rising_edge(clk_s);
                    write(L,std_to_hex(dbus));
                    write(L,string'(" "));
                    check_s(7 downto 0) <= dbus;
                    wait until rising_edge(clk_s);
                    inta  <= '1';                   
                    wait until rising_edge(clk_s);
                    wait until rising_edge(clk_s);
                    inta  <= '0';                   -- Third INTA Pulse
                    wait until rising_edge(clk_s);
                    write(L,std_to_hex(dbus));
                    write(L,string'(" "));          
                    check_s(15 downto 8) <= dbus;
                else                                -- 8086 mode
                    write(L,string'(" 8086 INTA :"));               
                    wait until rising_edge(clk_s);
                    inta  <= '0';                   -- First INTA Pulse
--                  assert int='1'  
--                      report "Error: INTA asserted whilst INT=0" severity error;
                    wait until rising_edge(clk_s);
                    wait until rising_edge(clk_s);
                    inta <= '1';
                    wait until rising_edge(clk_s);
                    wait until rising_edge(clk_s);
                    inta  <= '0';                   -- Second INTA Pulse
                    wait until rising_edge(clk_s);
                    wait for 10 ns;                 -- NOTE INTA vector requires 2 clock cycles due to latching
                                                    -- of the DBUS_OUT, remove the latch is this is causing problems.
                                                    -- See "eb1 1"
                    write(L,string'("IRQ"));   
                    write(L,std_to_hex(dbus(2 downto 0)));
                    write(L,string'(" Vector "));   
                    write(L,std_to_hex(dbus));
                    check_s(7 downto 0) <= dbus;
                end if;
                wait until rising_edge(clk_s);
                inta  <= '1';
                writeline(output,L);
                wait for 0 ns;
            end inta_sequence;

        begin

            IR       <= (others => '0');
            buffer_mode_s <= '1';               -- Normal SPEN input mode
            check_s  <= (others => 'H');        -- contains last serviced IRQ
            cas_in   <= (others => '0');
            dbus     <= (others => 'Z');
            abus     <= (others => 'H');
            data_s   <= (others => '0');
            rdn      <= '1';
            resetn   <= '0';
            wrn      <= '1';
            inta     <= '1';
            m8086_s  <= '1';                    -- Default to 8086 mode
            ms_s     <= '1';                    -- Default to Master

            wait for 100 ns;
            resetn   <= '1';
            wait for 100 ns;

            ---------------------------------------------------------------------------
            -- Initialise Master 8259
            -- 8086 mode
            -- INT vector is   1001-1000-110.....
            ---------------------------------------------------------------------------
            m8086_s<= '1';                      -- Test 8086 Mode
            ms_s   <= '1';                      -- Select Master
            icw1_s <= "00011001";               -- ICW1 Level triggered 
            icw2_s <= "01000000";               -- ICW2 base=0x40
            icw3_s <= "00000100";               -- ICW3 X04
            icw4_s <= "0000110"&m8086_s;        -- ICW4 normal EOI, master
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            ms_s   <= '0';                      -- Select Slave
            icw1_s <= "00011001";               -- ICW1 Level triggered 
            icw2_s <= "10000000";               -- ICW2 base=0x80
            icw3_s <= "00000010";               -- ICW3 ID=2
            icw4_s <= "0000100"&m8086_s;        -- ICW4 normal EOI, slave
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259


            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("------- Test Spurious Interrupt --------"));   
            writeline(output,L);

            
            IR <= "0000000000000010";           -- IRQ1 Interrupt Asserted
            wait for 300 ns;
            
            IR <= "0000000000000000";           -- IRQ1 removed to quickly
            wait for 100 ns;
            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ7 is serviced
            assert check_s(7 downto 0)=("01000" & "111")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Non-Specific EOI 
            data_s<="00100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;


            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("------- Test Non-Specific Interrupt --------"));   
            writeline(output,L);

            
            IR <= "0000000001001000";           -- IRQ3 & 6 Interrupt Asserted
            wait for 500 ns;
            
            inta_sequence;                      -- First INTA sequence
                                                -- Check IRQ3 is serviced
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                      -- First ISR called

            abus_s <= X"0020";                  -- Issue Non-Specific EOI 
            data_s<="00100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;
            
            inta_sequence;                      -- Second INTA sequence
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;

            abus_s <= X"0020";                  -- Issue Non-Specific EOI
            data_s<="00100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Non-Specific Interrupt + Rotate ----"));   
            writeline(output,L);

            
            IR <= "0000000001001000";           -- IRQ3 & 6 Interrupt Asserted
            wait for 500 ns;
            
            inta_sequence;                      -- First INTA sequence
                                                -- Check IRQ3 is serviced
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                      -- First ISR called

            abus_s <= X"0020";                  -- Issue Non-Specific EOI + Rotate
            data_s<="10100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            inta_sequence;                      -- Second INTA sequence
            assert check_s(7 downto 0)=("01000" & "110")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;

            abus_s <= X"0020";                  -- Issue Non-Specific EOI + Rotate
            data_s<="10100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            inta_sequence;                      -- Third INTA sequence
                                                -- Check IRQ3 is serviced
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                      -- First ISR called

            abus_s <= X"0020";                  -- Issue Non-Specific EOI + Rotate
            data_s<="10100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("------- Test Spurious Interrupt after rotate --------"));   
            writeline(output,L);

            
            IR <= "0000000000000010";           -- IRQ1 Interrupt Asserted
            wait for 300 ns;
            
            IR <= "0000000000000000";           -- IRQ1 removed
            wait for 100 ns;
            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ7 is serviced
            assert check_s(7 downto 0)=("01000" & "111")
                report "failure: wrong IRQ serviced, expected IRQ7!!" severity error;
            wait for 1 us;      
            
            -- check ISR!              

            abus_s <= X"0020";                  -- Issue Non-Specific EOI 
            data_s<="00100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Specific Interrupt ----"));   
            writeline(output,L);

            abus_s <= X"0020";                  -- Restore priority
            data_s<="11000111";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            
            IR <= "0000000001001000";           -- IRQ3 & 6 Interrupt Asserted
            wait for 500 ns;
            
            inta_sequence;                      -- First INTA sequence
                                                -- Check IRQ3 is serviced
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                      -- First ISR called

            abus_s <= X"0020";                  -- Issue Specific EOI 
            data_s<="01100011";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            inta_sequence;                      -- Second INTA sequence
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;

            abus_s <= X"0020";                  -- Issue Specific EOI 
            data_s<="01100011";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Specific Interrupt + Rotate----"));   
            writeline(output,L);

            
            IR <= "0000000001001000";           -- IRQ3 & 6 Interrupt Asserted
            wait for 500 ns;
            
            inta_sequence;                      -- First INTA sequence
                                                -- Check IRQ3 is serviced
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                      -- First ISR called

            abus_s <= X"0020";                  -- Issue Specific EOI 
            data_s<="11100011";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            inta_sequence;                      -- Second INTA sequence
            assert check_s(7 downto 0)=("01000" & "110")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;

            abus_s <= X"0020";                  -- Issue Specific EOI 
            data_s<="11100110";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;

            inta_sequence;                      -- Third INTA sequence
                                                -- Check IRQ3 is serviced
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                      -- First ISR called

            abus_s <= X"0020";                  -- Issue Specific EOI 
            data_s<="11100011";                 -- OCW2
            outport(abus_s,data_s);
            wait for 200 ns;


            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Automatic EOI Edge triggered ----"));   
            writeline(output,L);
            
            IR     <= "0000000000000000";       -- Clear All interrupts
            
            ms_s   <= '1';                      -- Select Master
            icw1_s <= "00010001";               -- ICW1 Edge triggered  
            icw2_s <= "01000000";               -- ICW2 base=0x40
            icw3_s <= "00000100";               -- ICW3 X04
            icw4_s <= "0000111"&m8086_s;        -- ICW4, Auto EOI, master
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            IR <= "0000000011001001";           -- IRQ0,3,6,7 Interrupt Asserted
            wait for 500 ns;
            
            inta_sequence;                      -- First INTA sequence
                                                -- Check IRQ0 is serviced
            assert check_s(7 downto 0)=("01000" & "000")
                report "failure: wrong IRQ serviced!!" severity error;
            
            wait for 200 ns;                    -- First ISR called

            inta_sequence;                      -- Second INTA sequence
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;

            wait for 200 ns;

            inta_sequence;                      -- Third INTA sequence
                                                -- Check IRQ6 is serviced
            assert check_s(7 downto 0)=("01000" & "110")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                      

            wait for 200 ns;

            inta_sequence;                      -- Third INTA sequence
                                                -- Check IRQ7 is serviced
            assert check_s(7 downto 0)=("01000" & "111")
                report "failure: wrong IRQ serviced!!" severity error;
                
            IR <= "0000000000000000";           
            wait for 200 ns;

            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Automatic EOI + Rotate ----"));   
            writeline(output,L);

            IR     <= "0000000000000000";       -- Clear All interrupts
            
            ms_s   <= '1';                      -- Select Master
            icw1_s <= "00011001";               -- ICW1 Level triggered 
            icw2_s <= "01000000";               -- ICW2 base=0x40
            icw3_s <= "00000100";               -- ICW3 X04
            icw4_s <= "0000111"&m8086_s;        -- ICW4, Auto EOI, master
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            abus_s <= X"0020";                  
            data_s <="10000000";                -- OCW2, Rotate on AEOI set!
            outport(abus_s,data_s);
            
            IR <= "0000000011001001";           -- IRQ0,3,6,7   Interrupt Asserted
            wait for 500 ns;
            
            inta_sequence;                      -- First INTA sequence
                                                -- Check IRQ0 is serviced
            assert check_s(7 downto 0)=("01000" & "000")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 200 ns;

            inta_sequence;                      -- Second INTA sequence
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 200 ns;

            inta_sequence;                      -- Third INTA sequence
                                                -- Check IRQ6 is serviced
            assert check_s(7 downto 0)=("01000" & "110")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 200 ns;

            inta_sequence;                      -- Third INTA sequence
                                                -- Check IRQ7 is serviced
            assert check_s(7 downto 0)=("01000" & "111")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 200 ns;

            abus_s <= X"0020";                  
            data_s <="00000000";                -- OCW2, Rotate on AEOI clear
            outport(abus_s,data_s);

            IR     <= "0000000000000000";       -- Clear All interrupts
            wait for 300 ns;

            ---------------------------------------------------------------------------
            -- Assert IRQ0 continuously in level mode without rotate, only IRQ0 is
            -- serviced.
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Automatic EOI level Stuck IRQ0 ----"));   
            writeline(output,L);
            
            IR <= "0000000011001001";           -- IRQ0,3,6,7   Interrupt Asserted
            wait for 500 ns;
            
            inta_sequence;                      -- First INTA sequence
                                                -- Check IRQ0 is serviced
            assert check_s(7 downto 0)=("01000" & "000")
                report "failure: wrong IRQ serviced, expected IRQ0!!" severity error;
            wait for 200 ns;

            inta_sequence;                      -- Second INTA sequence
            assert check_s(7 downto 0)=("01000" & "000")
                report "failure: wrong IRQ serviced, expected IRQ0!!" severity error;
            wait for 200 ns;

            inta_sequence;                      -- Third INTA sequence
                                                -- Check IRQ6 is serviced
            assert check_s(7 downto 0)=("01000" & "000")
                report "failure: wrong IRQ serviced, expected IRQ0!!" severity error;
            wait for 200 ns;

            inta_sequence;                      -- Third INTA sequence
                                                -- Check IRQ7 is serviced
            assert check_s(7 downto 0)=("01000" & "000")
                report "failure: wrong IRQ serviced, expected IRQ0!!" severity error;
            wait for 200 ns;
            
            IR     <= "0000000000000000";       -- Clear All interrupts
            wait for 300 ns;

            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("------- Test Level Interrupt --------"));   
            writeline(output,L);
        
            m8086_s<= '1';                      -- Test 8086 Mode
            ms_s   <= '1';                      -- Select Master
            icw1_s <= "00011001";               -- ICW1 Level triggered 
            icw2_s <= "01000000";               -- ICW2 base=0x40
            icw3_s <= "00000100";               -- ICW3 X04
            icw4_s <= "0000110"&m8086_s;        -- ICW4 normal EOI, master
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            IR <= "0000000000010000";           -- IRQ4 Interrupt Asserted
            wait for 300 ns;
            
            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ4 is serviced
            assert check_s(7 downto 0)=("01000" & "100")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Non-Specific EOI 
            data_s<="00100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 300 ns;

            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ4 is again serviced
            assert check_s(7 downto 0)=("01000" & "100")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Non-Specific EOI 
            data_s<="00100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 300 ns;

            ---------------------------------------------------------------------------
            -- Start
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Edge triggered Interrupt ----"));   
            writeline(output,L);
            
            IR <= "0000000000000000";           

            m8086_s<= '1';                      -- Test 8086 Mode
            ms_s   <= '1';                      -- Select Master
            icw1_s <= "00010001";               -- ICW1 Edge triggered  
            icw2_s <= "01000000";               -- ICW2 base=0x40
            icw3_s <= "00000100";               -- ICW3 X04
            icw4_s <= "0000110"&m8086_s;        -- ICW4 normal EOI, master
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            IR <= "0000000000010000";           -- IRQ4 Interrupt Asserted
            wait for 300 ns;                    -- leave asserted

            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ4 is serviced
            assert check_s(7 downto 0)=("01000" & "100")
                report "failure: wrong IRQ serviced!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Non-Specific EOI 
            data_s<="00100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 300 ns;

            assert int='0'
                report "failure: INT still asserted" severity error;
            wait for 1 us;                     
            
            IR <= "0000000000000000";           
            wait for 300 ns;                    


            ---------------------------------------------------------------------------
            -- Test Priority 
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Priority Interrupt ----"));   
            writeline(output,L);
            
            IR <= "0000000000111000";           -- IRQ5,4,3 Interrupt Asserted
            wait for 300 ns;                    -- leave asserted

            inta_sequence;                      -- INTA sequence
            IR <= "0000000000110000";           -- IRQ5,4 Interrupt Asserted
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced, expected IRQ3!!" severity error;
            wait for 1 us;                     

            inta_sequence;                      -- INTA sequence
            IR <= "0000000000100000";           -- IRQ4 Interrupt Asserted
            assert check_s(7 downto 0)=("01000" & "100")
                report "failure: wrong IRQ serviced, expected IRQ4!!" severity error;
            wait for 1 us;                     

            inta_sequence;                      -- INTA sequence
            IR <= "0000000000000000";   
            assert check_s(7 downto 0)=("01000" & "101")
                report "failure: wrong IRQ serviced, expected IRQ5!!" severity error;
            wait for 1 us;                     
                   
            wait for 300 ns;                   

            -- 3 ISR bits should be set

            abus_s <= X"0020";                  -- Issue Non-Specific EOI 
            data_s<="00100000";                 -- OCW2
            outport(abus_s,data_s);
            outport(abus_s,data_s);
            outport(abus_s,data_s);


            ---------------------------------------------------------------------------
            -- Test Priority 4
            -- Issue IRQ1,3,13,14,15
            -- Issue Rotate EOI to Slave only
            ---------------------------------------------------------------------------

            ms_s   <= '1';                      -- Select Master
            icw1_s <= "00010001";               -- ICW1 Edge triggered  
            icw2_s <= "01000000";               -- ICW2 base=0x40
            icw3_s <= "00000100";               -- ICW3 X04
            icw4_s <= "0000110"&m8086_s;        -- ICW4 normal EOI, master
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            ms_s   <= '0';                      -- Select Slave
            icw1_s <= "00010001";               -- ICW1 Edge triggered  
            icw2_s <= "10000000";               -- ICW2 base=0x80
            icw3_s <= "00000010";               -- ICW3 ID=2
            icw4_s <= "0000100"&m8086_s;        -- ICW4 normal EOI, slave
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259


            write(L,string'("--- Test EOI Master Rotate EOI Slave ----"));   
            writeline(output,L);
            
            IR <= "0111000000001010";           -- IRQ1,3,13,14,15 Interrupt Asserted
            wait for 300 ns;                    -- leave asserted

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ1 is serviced
            assert check_s(7 downto 0)=("01000" & "001")
                report "failure: wrong IRQ serviced, expected IRQ1!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Master           
            data_s<="00100000";                 -- OCW2, normal EOI to master
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("10000" & "100")  -- Check IRQ12 is serviced
                report "failure: wrong IRQ serviced, expected IRQ12!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Rotate EOI to Master 
            data_s<="00100000";                 -- Normal EOI to Master                 
            outport(abus_s,data_s);
            data_s<="10100000";                 -- Rotate EOI to Slave
            abus_s <= X"00A0";                   
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("10000" & "101")  -- Check IRQ13 is serviced
                report "failure: wrong IRQ serviced, expected IRQ13!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Rotate EOI to Master 
            data_s<="00100000";                 -- Normal EOI to Master                 
            outport(abus_s,data_s);
            data_s<="10100000";                 -- Rotate EOI to Slave
            abus_s <= X"00A0";                   
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("10000" & "110")  -- Check IRQ14 is serviced
                report "failure: wrong IRQ serviced, expected IRQ13!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Rotate EOI to Master 
            data_s<="00100000";                 -- Normal EOI to Master                 
            outport(abus_s,data_s);
            data_s<="10100000";                 -- Rotate EOI to Slave Highest is now IRQ15
            abus_s <= X"00A0";                   
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            -- After servicing all slave ints, service the remaining master int3
            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced, expected IRQ3!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Rotate EOI to Master 
            data_s<="10100000";                 -- OCW2, rotate EOI
            outport(abus_s,data_s);
            wait for 300 ns;

            IR <= "0000000000000000";           -- Clear All ints
            wait for 300 ns;                    

            IR <= "1000000100000000";           -- Assert IRQ8 and IRQ15
            wait for 300 ns;                    -- leave asserted


            ------------------------------------------------------------------------
            -- The highest priority of the slave is now set to IRQ15
            -- Assert IRQ15 and IRQ8, IRQ15 should be serviced first!
            ------------------------------------------------------------------------

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("10000" & "111")  -- Check IRQ15 is serviced
                report "failure: wrong IRQ serviced, expected IRQ15!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue normal EOI to Master 
            data_s<="00100000";                 
            outport(abus_s,data_s);
            abus_s <= X"00A0";                  -- and to Slave! 
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("10000" & "000")  -- Check IRQ8 is serviced
                report "failure: wrong IRQ serviced, expected IRQ8!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Normal EOI to Master 
            data_s<="00100000";                 
            outport(abus_s,data_s);
            abus_s <= X"00A0";                  -- and to Slave 
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            -- And do it again, the highest priority should still be set to IRQ15!
            -- Assert IRQ15 and IRQ8, IRQ15 should still be serviced first!
            -- On the servicing IRQ8 issue a Rotate EOI, highest priority should
            -- now be IRQ9
            ------------------------------------------------------------------------
            IR <= "0000000000000000";           -- Clear All ints
            wait for 300 ns;                    

            IR <= "1000000100000000";           -- Assert IRQ8 and IRQ15
            wait for 300 ns;                    -- leave asserted

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("10000" & "111")  -- Check IRQ15 is serviced
                report "failure: wrong IRQ serviced, expected IRQ15!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue normal EOI to Master 
            data_s<="00100000";                 
            outport(abus_s,data_s);
            abus_s <= X"00A0";                  -- and to Slave! 
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("10000" & "000")  -- Check IRQ8 is serviced
                report "failure: wrong IRQ serviced, expected IRQ8!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Normal EOI to Master 
            data_s<="00100000";                 
            outport(abus_s,data_s);
            abus_s <= X"00A0";                  -- Issue Rotate EOI to Slave, highest IRQ is now 9 
            data_s<="10100000"; 
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            -- Assert IRQ9 and IRQ15, IRQ9 should be serviced first
            ------------------------------------------------------------------------
            IR <= "0000000000000000";           -- Clear All ints
            wait for 300 ns;                    

            IR <= "1000001000000000";           -- Assert IRQ9 and IRQ15
            wait for 300 ns;                    -- leave asserted

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("10000" & "001")  -- Check IRQ9 is serviced
                report "failure: wrong IRQ serviced, expected IRQ9!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue normal EOI to Master 
            data_s<="00100000";                 
            outport(abus_s,data_s);
            abus_s <= X"00A0";                  -- and to Slave! 
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("10000" & "111")  -- Check IRQ15 is serviced
                report "failure: wrong IRQ serviced, expected IRQ15!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue Normal EOI to Master 
            data_s<="00100000";                 
            outport(abus_s,data_s);
            abus_s <= X"00A0";                  -- and to slave 
            outport(abus_s,data_s);
            wait for 300 ns;


            ---------------------------------------------------------------------------
            -- Test Priority 6
            -- Set specific priority to 5 (5=lowest, 6 is highest)
            -- Issue IRQ0 and IRQ6 
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Specific Priority1, set lowest priority to IRQ5 ----"));   
            writeline(output,L);
            
            abus_s <= X"0020";                  -- Issue Set Priority command to IRQ5 
            data_s<="11000101";                 -- Note IRQ is now the lowest priority!                 
            outport(abus_s,data_s);
            wait for 300 ns;

            IR <= "0000000001000001";           -- IRQ0 and 6 Asserted
            wait for 300 ns;                    -- leave asserted

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ6 is serviced
            assert check_s(7 downto 0)=("01000" & "110")
                report "failure: wrong IRQ serviced, expected IRQ6!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Master           
            data_s<="00100000";                 -- OCW2, normal EOI to master
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("01000" & "000")  -- Check IRQ0 is serviced
                report "failure: wrong IRQ serviced, expected IRQ0!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue normal EOI to Master 
            data_s<="00100000";                 -- Normal EOI to Master                 
            outport(abus_s,data_s);
            wait for 300 ns;

            ---------------------------------------------------------------------------
            -- Test Priority 7
            -- Set specific priority to 5 (5=lowest, 6 is highest)
            -- Issue IRQ0 and IRQ5 
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Specific Priority2, set lowest priority to IRQ5 ----"));   
            writeline(output,L);

            IR <= "0000000000000000";           -- IRQ0 and 6 Asserted
            wait for 300 ns;                    -- leave asserted
            IR <= "0000000000100001";           -- IRQ0 and 5 Asserted
            wait for 300 ns;                    -- leave asserted

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ0 is serviced
            assert check_s(7 downto 0)=("01000" & "000")
                report "failure: wrong IRQ serviced, expected IRQ0!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Master           
            data_s<="00100000";                 -- OCW2, normal EOI to master
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("01000" & "101")  -- Check IRQ5 is serviced
                report "failure: wrong IRQ serviced, expected IRQ5!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue normal EOI to Master 
            data_s<="00100000";                 -- Normal EOI to Master                 
            outport(abus_s,data_s);
            wait for 300 ns;


            ---------------------------------------------------------------------------
            -- Test Priority 8
            -- Corner case, set specific priority to 7 (0 is highest)
            -- Issue IRQ7 and IRQ6 
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Specific Priority3, set lowest priority to IRQ7 ----"));   
            writeline(output,L);

            IR <= "0000000000000000";           -- IRQ0 and 6 Asserted
            wait for 300 ns;                    -- leave asserted

            abus_s <= X"0020";                  -- Issue Set Priority command to IRQ5 
            data_s<="11000111";                 -- Note IRQ is now the lowest priority!                 
            outport(abus_s,data_s);
            wait for 300 ns;

            IR <= "0000000011000000";           -- IRQ7 and 6 Asserted
            wait for 300 ns;                    -- leave asserted

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ6 is serviced
            assert check_s(7 downto 0)=("01000" & "110")
                report "failure: wrong IRQ serviced, expected IRQ6!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Master           
            data_s<="00100000";                 -- OCW2, normal EOI to master
            outport(abus_s,data_s);
            wait for 300 ns;

            ------------------------------------------------------------------------
            inta_sequence;                      -- INTA sequence
            assert check_s(7 downto 0)=("01000" & "111")  -- Check IRQ7 is serviced
                report "failure: wrong IRQ serviced, expected IRQ7!!" severity error;
            wait for 1 us;                     

            abus_s <= X"0020";                  -- Issue normal EOI to Master 
            data_s<="00100000";                 -- Normal EOI to Master                 
            outport(abus_s,data_s);
            wait for 300 ns;


            ---------------------------------------------------------------------------
            -- Special mask Mode
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Special Mask Mode ----"));   
            writeline(output,L);
            
            IR     <= "0000000000000000";       -- Clear All interrupts
            wait for 300 ns;

            ms_s   <= '1';                      -- Select Master
            icw1_s <= "00011001";               -- ICW1 Level triggered 
            icw2_s <= "01000000";               -- ICW2 base=0x40
            icw3_s <= "00000100";               -- ICW3 X04
            icw4_s <= "0000110"&m8086_s;        -- ICW4, Normal EOI, master
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            
            IR <= "0000000001001000";           -- IRQ3,6 Interrupt Asserted
            wait for 300 ns;                    -- leave asserted

            inta_sequence;                      -- INTA sequence
                                                -- Check IRQ3 is serviced
            assert check_s(7 downto 0)=("01000" & "011")
                report "failure: wrong IRQ serviced, expected IRQ3!!" severity error;
            wait for 1 us;                     

            
            ---------------------------------------------------------------------------
            -- First set the bit to mask of IRQ3 (currently being serviced)
            ---------------------------------------------------------------------------
            abus_s <= X"0021";                  -- Issue Non-Specific EOI 
            data_s <= "00001000";               -- OCW1, Mask of IRQ3
            outport(abus_s,data_s);
            wait for 300 ns;

            ---------------------------------------------------------------------------
            -- Next enable special mask mode
            ---------------------------------------------------------------------------
            abus_s <= X"0020";                  -- OCW3 
            data_s <= "01101000";               -- Set Special mask mode
            outport(abus_s,data_s);
            wait for 300 ns;

            ---------------------------------------------------------------------------
            -- This should result in INT being re-asserted for IRQ6
            ---------------------------------------------------------------------------

            inta_sequence;                      -- INTA sequence for IRQ6
            assert check_s(7 downto 0)=("01000" & "110")
                report "failure: wrong IRQ serviced, expected IRQ6!!" severity error;
            wait for 1 us;                     

            ---------------------------------------------------------------------------
            -- Issue specific EOI for IRQ6 while special mask is enabled
            ---------------------------------------------------------------------------
            abus_s <= X"0020";                  -- Issue Specific EOI 
            data_s<="01100110";                 -- OCW2
            outport(abus_s,data_s);
            wait for 300 ns;

            IR <= "0000000000001000";           -- Clear IRQ6


            ---------------------------------------------------------------------------
            -- Then disable special mask mode
            ---------------------------------------------------------------------------
            abus_s <= X"0020";                  -- OCW3 
            data_s <= "01001000";               -- Clear Special mask mode
            outport(abus_s,data_s);
            wait for 300 ns;

            ---------------------------------------------------------------------------
            -- Issue Normal EOI for IRQ3
            ---------------------------------------------------------------------------
            abus_s <= X"0020";                  -- Issue non-Specific EOI 
            data_s<="00100000";                 -- OCW2
            outport(abus_s,data_s);
            wait for 300 ns;
            
            IR <= "0000000000000000";           -- clear final IRQ3
            wait for 300 ns;                    


            ---------------------------------------------------------------------------
            -- Special Fully Nested Mode
            ---------------------------------------------------------------------------
            write(L,string'("--- Test Special Fully Nested Mode ----"));   
            writeline(output,L);
            
            IR     <= "0000000000000000";       -- Clear All interrupts
            
            ms_s   <= '1';                      -- Select Master
            icw1_s <= "00010001";               -- ICW1 Edge triggered  
            icw2_s <= "01000000";               -- ICW2 base=0x40
            icw3_s <= "00000100";               -- ICW3 X04
            icw4_s <= "0001110"&m8086_s;        -- ICW4, Normal EOI, master, SFNM
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            ms_s   <= '0';                      -- Select Slave
            icw1_s <= "00010001";               -- ICW1 Edge triggered  
            icw2_s <= "10000000";               -- ICW2 base=0x80
            icw3_s <= "00000010";               -- ICW3 ID=2
            icw4_s <= "0000100"&m8086_s;        -- ICW4 normal EOI, slave
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            IR <= "0001000000000000";           -- IRQ12 Interrupt Asserted
            wait for 300 ns;
            
            inta_sequence;                      -- First INTA sequence
                                                -- Check IRQ12 is serviced
            assert check_s(7 downto 0)=("10000" & "100")
                report "failure: wrong IRQ serviced, expected IRQ12!!" severity error;
            wait for 200 ns;                    -- First ISR called

            ---------------------------------------------------------------------------
            -- Before Issuing an EOI a higher Slave interrupt comes in
            ---------------------------------------------------------------------------
            
           --   IR <= "0000000100000000";       -- IRQ8 Interrupt Asserted
            IR <= "0001000100000000";           -- IRQ8 Interrupt Asserted added
            wait for 300 ns;

            inta_sequence;                      -- Service another slave IRQ
            
            ---------------------------------------------------------------------------
            -- Check that there are no more slave IRQ's pending before issuing a EOI
            -- to the master (otherwise the interrupt is lost)
            -- First issue a EOI to the slave and then check IS register to see if 0
            ---------------------------------------------------------------------------     
            abus_s <= X"00A0";                  -- issue Normal EOI to Slave only
            data_s<="00100000";                 
            outport(abus_s,data_s);
            
            abus_s <= X"00A0";                  -- Select Slave IS register on next read
            data_s <="00001011";                -- OCW3
            outport(abus_s,data_s);
            
            write(L,string'("...   Checking Slave IS="));
            inport(abus_s,data_s);              -- Read IS Register
            write(L,std_to_hex(data_s));
            if (data_s="00000000") then         -- ISR slave register empty?
                write(L,string'(" empty, issue EOI to master"));
                abus_s <= X"0020";              -- yes, issue Normal EOI to Slave only
                data_s<="00100000";                 
                outport(abus_s,data_s);
            else 
                write(L,string'(" not empty, issue EOI to slave only"));
                abus_s <= X"00A0";                  -- issue Normal EOI to Slave only
                data_s<="00100000";                 
                outport(abus_s,data_s);
            end if;
            writeline(output,L);
            
            -- Read ISR again to see if empty
            abus_s <= X"00A0";                  -- Select Slave IS register on next read
            data_s <="00001011";                -- OCW3
            outport(abus_s,data_s);
            

            write(L,string'("...   Checking Slave IS="));
            inport(abus_s,data_s);              -- Read IS Register
            write(L,std_to_hex(data_s));
            if (data_s="00000000") then         -- ISR slave register empty?
                write(L,string'(" empty, issue EOI to master"));
                abus_s <= X"0020";              -- yes, issue Normal EOI to Slave only
                data_s<="00100000";                 
                outport(abus_s,data_s);
            else 
                write(L,string'(" not empty, issue EOI to slave only"));
                abus_s <= X"00A0";                  -- issue Normal EOI to Slave only
                data_s<="00100000";                 
                outport(abus_s,data_s);
            end if;
            writeline(output,L);



            ---------------------------------------------------------------------------
            -- 
            ---------------------------------------------------------------------------
            write(L,string'("------- Test Poll Command --------"));   
            writeline(output,L);
            
            IR <= "0000000000000000";           
            wait for 500 ns;

            ms_s   <= '1';                      -- Select Master
            icw1_s <= "00011001";               -- ICW1 Level triggered 
            icw2_s <= "01000000";               -- ICW2 base=0x40
            icw3_s <= "00000100";               -- ICW3 X04
            icw4_s <= "0000110"&m8086_s;        -- ICW4 normal EOI, master
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259
            
            ms_s   <= '0';                      -- Select Slave
            icw1_s <= "00011001";               -- ICW1 Level triggered 
            icw2_s <= "10000000";               -- ICW2 base=0x80
            icw3_s <= "00000010";               -- ICW3 ID=2
            icw4_s <= "0000100"&m8086_s;        -- ICW4 normal EOI, slave
            ocw1_s <= "00000000";               -- Mask, enable all
            wait for 0 ns;
            init_8259(ms_s);                    -- Init Master 8259

            IR <= "0100000000000010";           
            wait for 300 ns;

            ---------------------------------------------------------------------------
            -- Issue the Poll Command
            ---------------------------------------------------------------------------         
            abus_s <= X"0020";                  -- Issue Poll Command 
            data_s<="00001100";                 -- OCW3
            outport(abus_s,data_s);
            wait for 200 ns;
            inport(abus_s,data_s);              -- Read Poll status
            wait for 200 ns;

            if data_s(7)='1' then               -- Interrupt Pending
                write(L,string'("  Interrupt Pending : "));
                write(L,std_to_hex(data_s));

                abus_s <= X"0020";                  -- Select IS register on next read
                data_s <="00001011";                -- OCW3
                outport(abus_s,data_s);
                write(L,string'(" ISmaster="));
                inport(abus_s,data_s);              -- Read IS Register
                write(L,std_to_hex(data_s));

                writeline(output,L);

                abus_s <= X"0020";                  -- Issue non-Specific EOI 
                data_s<="00100000";                 -- OCW2
                outport(abus_s,data_s);
            end if;
               

            ---------------------------------------------------------------------------
            -- Issue the Poll Command
            ---------------------------------------------------------------------------         
            abus_s <= X"0020";                      -- Issue Poll Command 
            data_s<="00001100";                     -- OCW3
            outport(abus_s,data_s);
            wait for 200 ns;
            inport(abus_s,data_s);                  -- Read Poll status
            wait for 200 ns;

            if data_s(7)='1' then                   -- Interrupt Pending
                write(L,string'("  Interrupt Pending : "));
                write(L,std_to_hex(data_s));

                abus_s <= X"0020";                  -- Select IS register on next read
                data_s <="00001011";                -- OCW3
                outport(abus_s,data_s);
                write(L,string'(" ISmaster="));
                inport(abus_s,data_s);              -- Read IS Register
                write(L,std_to_hex(data_s));

                writeline(output,L);

                abus_s <= X"0020";                  -- Issue non-Specific EOI 
                data_s<="00100000";                 -- OCW2
                outport(abus_s,data_s);
            end if;

            IR <= "0000000000000000";           
            wait for 200 ns;


---------------------------------------------------------------------------
            -- 8080 Mode
            -- Interval=4 A7-A6-A5-<Vector_identifier>
            -- Interrupt base at 0x3B20
            ---------------------------------------------------------------------------        
            write(L,string'("------- Test 8080/8085 mode, interval 4 -------"));   
            writeline(output,L);
            
            m8086_s <='0';
            
            IR     <= "0000000000000000";           -- Clear All interrupts
                                                    
            ms_s   <= '1';                          -- Select Master
            icw1_s <= "00110101";                   -- ICW1 Edge, A7:5=001xxxx, ADI(bit2)=1 (4)   
            icw2_s <= "00111011";                   -- ICW2 A15:8=0x3B
            icw3_s <= "00000100";                   -- ICW3 X04
            icw4_s <= "00001110";                   -- ICW4, Auto EOI, BM master, uPM=0
            ocw1_s <= "00000000";                   -- Mask, enable all
            wait for 0 ns;                          
            init_8259(ms_s);                        -- Init Master 8259
                                                    
            IR <= "0000000011111011";               -- IRQ0,1,3,4,5,6,7 Interrupt Asserted
            wait for 500 ns;
            
            inta_sequence;                          -- 3 INTA sequence, Check IRQ0 Vector
            assert check_s=X"3B20" report "failure: wrong IRQ0 vector serviced, expected 0x3B20!" severity error;       
            wait for 200 ns;                    

            inta_sequence;                          -- 3 INTA sequence, Check IRQ1 Vector
            assert check_s=X"3B24" report "failure: wrong IRQ0 vector serviced, expected 0x3B24!" severity error;
            wait for 200 ns;  
            
            inta_sequence;                          -- 3 INTA sequence, Check IRQ3 Vector
            assert check_s=X"3B2C" report "failure: wrong IRQ0 vector serviced, expected 0x3B2C!" severity error;
            wait for 200 ns;  
            
            inta_sequence;                          -- 3 INTA sequence, Check IRQ4 Vector
            assert check_s=X"3B30" report "failure: wrong IRQ0 vector serviced, expected 0x3B30!" severity error;
            wait for 200 ns;  

            inta_sequence;                          -- 3 INTA sequence, Check IRQ5 Vector
            assert check_s=X"3B34" report "failure: wrong IRQ0 vector serviced, expected 0x3B34!" severity error;
            wait for 200 ns;            
            
            inta_sequence;                          -- 3 INTA sequence, Check IRQ6 Vector
            assert check_s=X"3B38" report "failure: wrong IRQ0 vector serviced, expected 0x3B38!" severity error;
            wait for 200 ns;            
            
            inta_sequence;                          -- 3 INTA sequence, Check IRQ7 Vector
            assert check_s=X"3B3C" report "failure: wrong IRQ0 vector serviced, expected 0x3B3C!" severity error;
            wait for 200 ns;  
            
            IR <= "0000000000000000";           
            wait for 200 ns;
            
            ---------------------------------------------------------------------------
            -- 8080 Mode
            -- Interval=8 A7-A6-<Vector_identifier>
            -- Interrupt base at 0x2A40
            ---------------------------------------------------------------------------        
            write(L,string'("------- Test 8080/8085 mode, interval 8 -------"));   
            writeline(output,L);
            
            m8086_s <='0';
            
            IR     <= "0000000000000000";           -- Clear All interrupts
                
            ms_s   <= '1';                          -- Select Master
            icw1_s <= "01010001";                   -- ICW1 Edge, A7:5=01xxxxx, ADI(bit2)=0 (8)   
            icw2_s <= "00101010";                   -- ICW2 A15:8=0x2A
            icw3_s <= "00000100";                   -- ICW3 X04
            icw4_s <= "00001110";                   -- ICW4, Auto EOI, BM master, uPM=0
            ocw1_s <= "00000000";                   -- Mask, enable all
            wait for 0 ns;  
            init_8259(ms_s);                        -- Init Master 8259
    
            IR <= "0000000011111011";               -- IRQ0,1,3,4,5,6,7 Interrupt Asserted
            wait for 500 ns;    
                
            inta_sequence;                          -- 3 INTA sequence, Check IRQ0 Vector
            assert check_s=X"2A40" report "failure: wrong IRQ0 vector serviced, expected 0x2A40!" severity error;
            wait for 200 ns;                    

            inta_sequence;                          -- 3 INTA sequence, Check IRQ1 Vector
            assert check_s=X"2A48" report "failure: wrong IRQ0 vector serviced, expected 0x2A48!" severity error;
            wait for 200 ns;  
            
            inta_sequence;                          -- 3 INTA sequence, Check IRQ3 Vector
            assert check_s=X"2A58" report "failure: wrong IRQ0 vector serviced, expected 0x2A58!" severity error;
            wait for 200 ns;  
            
            inta_sequence;                          -- 3 INTA sequence, Check IRQ4 Vector
            assert check_s=X"2A60" report "failure: wrong IRQ0 vector serviced, expected 0x2A60!" severity error;
            wait for 200 ns;  

            inta_sequence;                          -- 3 INTA sequence, Check IRQ5 Vector
            assert check_s=X"2A68" report "failure: wrong IRQ0 vector serviced, expected 0x2A68!" severity error;
            wait for 200 ns;            
            
            inta_sequence;                          -- 3 INTA sequence, Check IRQ6 Vector
            assert check_s=X"2A70" report "failure: wrong IRQ0 vector serviced, expected 0x2A70!" severity error;
            wait for 200 ns;            
            
            inta_sequence;                          -- 3 INTA sequence, Check IRQ7 Vector
            assert check_s=X"2A78" report "failure: wrong IRQ0 vector serviced, expected 0x2A78!" severity error;
            wait for 200 ns;  
            
            IR <= "0000000000000000";           
            wait for 200 ns;
            assert FALSE
                report "end of simulation" severity failure;

    end process; 

END ARCHITECTURE behaviour;
