library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--M�quina de estados que se encargar� de comprobar las flags de entrada(Escritura,Comprobar contrase�a)
--y en funci�n de las veces que se haya intentado introducir la contrase�a bloquear� la entrada hasta un nuevo reset
entity FSM is
    port( CLK, RST, Comp, Esc : in  std_logic;--Reloj,Reset,Comprobar contrase�a,Escritura de nueva contrase�a
          OK: in std_logic;--Comprobaci�n de que la contrase�a coincide con la entrada, viene del comparator
          BLOQUEO : out std_logic;--Se�al que bloquea la entrada de datos si se han cometido 3 errores
          DATA: in std_logic_vector(7 downto 0);--Data introducida por el usuario
          DataRAM: out std_logic_vector(7 downto 0);--Data que ir� a la RAM para sobreescribir o al comparador para comprobar la contrase�a
          LectROM, LectRAM, EscRAM : out std_logic--Flags que indicar�n el comportamiento del banco de memoria
    );
end FSM;

architecture Structural of FSM is
    type state_type is (S0, S1, S2, S3, S4, S5);--Estados que va a tener la FSM
    signal currentState, nextState : state_type;--Se�ales de estado actual y estado siguiente   
    signal repeat : integer := 0;
    
begin
    --Proceso dependiente del reloj  de la FSM
    process(CLK, RST)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then--Si hay un reset se vuelve al estado incial
                currentState <= S0;
            else
                currentState <= nextState;--Cada pulso de reloj se pasa al siguiente estado
            end if;
        end if;
    end process;

    
    process(currentState,Comp, Esc, OK)--Proceso que depende del estado actual, de las flag de escritura y comprobaci�n y de la salida del comparator
    begin
        case currentState is
            --Estado inicial
            when S0 =>
            repeat<=repeat+1;
                LectROM <= '1'; EscRAM <= '1'; LectRAM <= '0';--Activamos las flags de salida de datos de la ROM y escritura de la RAM                                         --para pasar incialmente la contrase�a a la RAM
                BLOQUEO <= '0';--La se�al de bloqueo se resetea solo en el estado inicial
                DataRAM <= "ZZZZZZZZ";--En el primer estado no se puede sobreescribir la RAM
                if(repeat<4) then
                nextState<=S0;
                else
                 nextState <= S1;--El siguiente estado ser� el S1 
                 end if;

                 
            when S1 =>
            if(OK = '1') then--Si el comparador nos devuelve un 1 es que la contrase�a introducida coincide con la almacenada
                nextState <= S5;--Pasamos al ultimo estado
            else
                if(Comp = '1' and Esc = '0') then --Si habilitamos la comparaci�n de datos y no escribimos en la RAM
                    LectRAM <= '1'; EscRAM <= '0'; LectROM <= '0';--Activamos la flag de salida de datos de la RAM y el resto de flags se desactivan
                    DataRAM <= DATA;--Pasamos la data introducida al banco de memoria para comparar con la data almacenada
                    if(OK = '1') then--Si coinciden
                        nextState <= S5;--Pasamos al �ltimo estado
                    else--Si no coinciden 
                        nextState <= S2;--Pasamos al primer estado de error
                    end if;
                elsif(Esc = '1' and Comp = '0') then
                    LectRAM <= '0'; EscRAM <= '1'; LectROM <= '0';
                    nextState <= S1;
                else
                    nextState <= S1;
                end if;
            end if;    
            when S2 =>
                if(OK = '1') then
                        nextState <= S5;
                else
                    if(Esc = '0') then  
                        if(Comp = '1' )then
                            LectRAM <= '1'; EscRAM <= '0'; LectROM <= '0';
                            DataRAM <= DATA;
                            if(OK = '1') then
                                nextState <= S5;
                            else
                                nextState <= S3;
                            end if;
                        end if;
                    end if;
                end if;
            when S3 =>
            if(OK = '1') then
                        nextState <= S5;
            else
                if(Esc = '0') then  
                    if(Comp = '1' )then
                        LectRAM <= '1'; EscRAM <= '0'; LectROM <= '0';
                        DataRAM <= DATA;
                        if(OK = '1') then
                            nextState <= S5;
                        else
                            nextState <= S4;
                        end if;
                    end if;
                end if;
            end if;
            when S4 =>
            if(OK = '1') then
                        nextState <= S5;
            else
                if(Esc = '0') then  
                    if(Comp = '1' )then
                        LectRAM <= '1'; EscRAM <= '0'; LectROM <= '0';
                        DataRAM <= DATA;
                        nextState <= S5;
                    end if;
                end if;
            end if;
            when S5 =>
            -- Check
                BLOQUEO <= '1';
                report "Sanity check : OK = " & std_logic'image(OK);
                LectRAM <= '0'; EscRAM <= '0'; LectROM <= '0';
                DataRAM <= "ZZZZZZZZ";
                nextState <= S5;
            when others =>
                nextState <= S0;
        end case;
     end process;
end Structural;
