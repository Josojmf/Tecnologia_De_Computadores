library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--M�quina de estados que se encargar� de comprobar las flags de entrada(Escritura,Comprobar contrase�a)
--y en funci�n de las veces que se haya intentado introducir la contrase�a bloquear� la entrada hasta un nuevo reset
entity FSM is
    port( CLK, RST, Comp : in  std_logic;--Reloj,Reset,Comprobar contrase�a,Escritura de nueva contrase�a
         OK: in std_logic;--Comprobaci�n de que la contrase�a coincide con la entrada, viene del comparator
         BLOQUEO : out std_logic;--Se�al que bloquea la entrada de datos si se han cometido 3 errores
         DATA: in std_logic_vector(7 downto 0);--Data introducida por el usuario
         DataROM: out std_logic_vector(7 downto 0);--Data que ir� al comparador para comprobar la contrase�a
         LectROM : out std_logic--Flags que indicar�n el comportamiento del banco de memoria
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


    process(currentState,Comp, OK)--Proceso que depende del estado actual y comprobaci�n y de la salida del comparator
    begin
        case currentState is
            --Estado inicial
            when S0 =>

                LectROM <= '1';
                BLOQUEO <= '0';--La se�al de bloqueo se resetea solo en el estado inicial
                DataROM <= "ZZZZZZZZ";
                nextState <= S1;

            when S1 =>
                if(OK = '1') then--Si el comparador nos devuelve un 1 es que la contrase�a introducida coincide con la almacenada
                    nextState <= S5;--Pasamos al ultimo estado
                else
                    if(Comp = '1') then --Si habilitamos la comparaci�n de datos 
                        LectROM <= '1';--Activamos la flag de salida de datos de la ROM 
                        DataROM <= DATA;--Pasamos la data introducida al banco de memoria para comparar con la data almacenada
                        if(OK = '1') then--Si coinciden
                            nextState <= S5;--Pasamos al �ltimo estado
                        else--Si no coinciden 
                            nextState <= S2;--Pasamos al primer estado de error
                        end if;
                    else
                        nextState <= S1;
                    end if;
                end if;

            when S2 =>
                if(OK = '1') then
                    nextState <= S5;
                else
                    if(Comp = '1' )then
                        LectROM <= '1';
                        DataROM <= DATA;
                        if(OK = '1') then
                            nextState <= S5;
                        else
                            nextState <= S3;
                        end if;
                    end if;
                end if;

            when S3 =>
                if(OK = '1') then
                    nextState <= S5;
                else
                    if(Comp = '1' )then
                        LectROM <= '1';
                        DataROM <= DATA;
                        if(OK = '1') then
                            nextState <= S5;
                        else
                            nextState <= S4;
                        end if;
                    end if;
                end if;

            when S4 =>
                if(OK = '1') then
                    nextState <= S5;
                else
                    if(Comp = '1' )then
                        LectROM <= '1';
                        DataROM <= DATA;
                        nextState <= S5;
                    end if;
                end if;

            when S5 =>
                BLOQUEO <= '1';--bloqueamos la maquina ya que hemos fallado 3 veces o hemos acertado una vez
                LectROM <= '0';--flag de la ROM a 0 para evitar que se lea contenido de la memoria
                DataROM <= "ZZZZZZZZ";--fijamos a zzzz la a para comprobar para no volver a comparar con nada hasta un reset 
                nextState <= S5;
            when others =>
                nextState <= S0;
        end case;
    end process;
end Structural;
