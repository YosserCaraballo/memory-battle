
;  MEMORY BATTLE — Juego de memoria en ensamblador x86
;  Plataforma  : EMU8086 (Modo Real 16 bits)
;  Integrantes : Yosser Caraballo




.MODEL SMALL
.STACK 200h

.DATA
    SEQ_LEN     DB  4
    SEQUENCE    DB  15 DUP(0)
    INPUT       DB  15 DUP(0)
    LIVES       DB  3
    SCORE       DW  0
    PRN         DW  0

    MSG_TITLE   DB  '+==================================+', 0Dh, 0Ah
                DB  '|       *** MEMORY BATTLE ***      |', 0Dh, 0Ah
                DB  '|  Entrena tu memoria secuencial   |', 0Dh, 0Ah
                DB  '|   UTB - Arq. del Computador      |', 0Dh, 0Ah
                DB  '+==================================+', 0Dh, 0Ah, '$'

    MSG_START   DB  0Dh, 0Ah
                DB  '  Presiona cualquier tecla para iniciar...', 0Dh, 0Ah, '$'

    MSG_SEP     DB  '----------------------------------', 0Dh, 0Ah, '$'

    MSG_LEVEL   DB  'Nivel   : $'
    MSG_LIVES   DB  'Vidas   : $'
    MSG_SCORE   DB  'Puntaje : $'

    MSG_WATCH   DB  0Dh, 0Ah, '>> Memoriza la secuencia: $'
    MSG_HIDE    DB  0Dh, 0Ah, '>> Secuencia oculta!', 0Dh, 0Ah, '$'
    ; CORRECCIÓN: mensaje claro indicando que debe digitar lo que vio
    MSG_INPUT   DB  0Dh, 0Ah, '>> Digite la secuencia que se vio: $'

    MSG_CORRECT DB  0Dh, 0Ah, '[OK] Correcto! Subiste de nivel.', 0Dh, 0Ah, '$'
    MSG_WRONG   DB  0Dh, 0Ah, '[X]  Incorrecto. Perdiste una vida.', 0Dh, 0Ah, '$'

    MSG_CONT    DB  0Dh, 0Ah
                DB  '  Presiona cualquier tecla para continuar...'
                DB  0Dh, 0Ah, '$'

    MSG_OVER    DB  0Dh, 0Ah
                DB  '+==================================+', 0Dh, 0Ah
                DB  '|         *** GAME OVER ***        |', 0Dh, 0Ah
                DB  '+==================================+', 0Dh, 0Ah
                DB  'Puntaje final: $'

    MSG_WIN     DB  0Dh, 0Ah
                DB  '+==================================+', 0Dh, 0Ah
                DB  '| *** FELICITACIONES - GANASTE *** |', 0Dh, 0Ah
                DB  '+==================================+', 0Dh, 0Ah
                DB  'Puntaje final: $'

    MSG_NEWLINE DB  0Dh, 0Ah, '$'

.CODE

MAIN PROC
    MOV  AX, @DATA
    MOV  DS, AX

    ; Semilla inicial para el generador aleatorio
    MOV  AH, 00h
    INT  1Ah
    MOV  PRN, DX

    CALL CLEAR_SCREEN
    CALL SHOW_TITLE

    LEA  DX, MSG_START
    MOV  AH, 09h
    INT  21h
    MOV  AH, 08h
    INT  21h

GAME_LOOP:
    CMP  LIVES, 0
    JE   GAME_OVER_SCREEN

    CMP  SEQ_LEN, 10
    JG   WIN_SCREEN

    CALL CLEAR_SCREEN

    LEA  DX, MSG_SEP
    MOV  AH, 09h
    INT  21h

    CALL SHOW_STATUS

    LEA  DX, MSG_SEP
    MOV  AH, 09h
    INT  21h

    CALL GEN_SEQ
    CALL SHOW_SEQ       ; muestra secuencia, espera ~3s, oculta
    CALL READ_INPUT     ; muestra "Digite la secuencia que se vio:"
    CALL VALIDATE

    ; si se queda sin vidas, ir directo al Game Over
    CMP  LIVES, 0
    JE   GAME_OVER_SCREEN

    CALL SHOW_STATUS

    LEA  DX, MSG_CONT
    MOV  AH, 09h
    INT  21h
    MOV  AH, 08h
    INT  21h

    JMP  GAME_LOOP

GAME_OVER_SCREEN:
    CALL CLEAR_SCREEN
    LEA  DX, MSG_OVER
    MOV  AH, 09h
    INT  21h
    MOV  AX, SCORE
    CALL PRINT_NUM
    LEA  DX, MSG_NEWLINE
    MOV  AH, 09h
    INT  21h
    JMP  EXIT_PROG

WIN_SCREEN:
    CALL CLEAR_SCREEN
    LEA  DX, MSG_WIN
    MOV  AH, 09h
    INT  21h
    MOV  AX, SCORE
    CALL PRINT_NUM
    LEA  DX, MSG_NEWLINE
    MOV  AH, 09h
    INT  21h

EXIT_PROG:
    MOV  AH, 4Ch
    MOV  AL, 0
    INT  21h
MAIN ENDP


;  GEN_SEQ Genera SEQ_LEN digitos aleatorios en SEQUENCE

GEN_SEQ PROC
    PUSH CX
    PUSH SI

    MOV  CL, SEQ_LEN
    XOR  CH, CH
    LEA  SI, SEQUENCE

GEN_LOOP:
    CALL CALC_RANDOM_DIGIT
    MOV  [SI], AL
    INC  SI
    LOOP GEN_LOOP

    POP  SI
    POP  CX
    RET
GEN_SEQ ENDP


;  CALC_RANDOM_DIGIT — LCG: Xn+1 = (25173*Xn + 13849) mod 2^16
;  Retorna en AL el caracter ASCII del digito (0-9)

CALC_RANDOM_DIGIT PROC
    PUSH BX
    PUSH CX
    PUSH DX

    MOV  AX, 25173
    MUL  WORD PTR PRN       ; DX:AX = 25173 * PRN
    ADD  AX, 13849
    MOV  PRN, AX            ; guarda solo los 16 bits bajos

    MOV  BX, 10
    XOR  DX, DX
    DIV  BX                 ; AX = PRN / 10, DX = PRN mod 10

    ADD  DL, '0'            ; convierte 0-9 a ASCII
    MOV  AL, DL             ; resultado en AL

    POP  DX
    POP  CX
    POP  BX
    RET
CALC_RANDOM_DIGIT ENDP


;  SHOW_SEQ — Muestra la secuencia ~2 segundos y la oculta
;  Flujo: mostrar digitos ? delay real ? limpiar ? MSG_HIDE

SHOW_SEQ PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DX

    LEA  DX, MSG_WATCH
    MOV  AH, 09h
    INT  21h

    MOV  CL, SEQ_LEN
    XOR  CH, CH
    LEA  SI, SEQUENCE

SHOW_LOOP:
    MOV  DL, [SI]
    MOV  AH, 02h
    INT  21h                ; imprime el digito
    MOV  DL, ' '
    INT  21h                ; espacio separador
    INC  SI
    LOOP SHOW_LOOP

    LEA  DX, MSG_NEWLINE
    MOV  AH, 09h
    INT  21h

    ; CORRECCIÓN: delay real de ~2 segundos usando timer BIOS
    CALL GENERATE_DELAY_2S

    CALL CLEAR_SCREEN

    ; Muestra "Secuencia oculta!" antes del prompt de entrada
    LEA  DX, MSG_HIDE
    MOV  AH, 09h
    INT  21h

    POP  DX
    POP  SI
    POP  CX
    POP  AX
    RET
SHOW_SEQ ENDP


;  GENERATE_DELAY_2S — Delay de ~2 segundos usando INT 1Ah
;  INT 1Ah AH=00h devuelve CX:DX = ticks del timer BIOS
;  El timer avanza a ~18.2 ticks/segundo
;  36 ticks ˜ 2 segundos

GENERATE_DELAY_2S PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV  AH, 00h
    INT  1Ah                ; lee el tick actual en CX:DX
    ADD  DX, 54             ; objetivo = ahora + 54 ticks (~3s)
    MOV  BX, DX             ; guarda el tick objetivo en BX

DELAY_LOOP:
    MOV  AH, 00h
    INT  1Ah                ; lee tick actual
    CMP  DX, BX
    JB   DELAY_LOOP         ; espera hasta que DX >= objetivo

    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
GENERATE_DELAY_2S ENDP


;  CLEAR_SCREEN  Limpia pantalla con INT 10h

CLEAR_SCREEN PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV  AH, 06h
    MOV  AL, 00h
    MOV  BH, 07h
    MOV  CX, 0000h
    MOV  DX, 184Fh
    INT  10h

    ; reposiciona cursor en (0,0)
    MOV  AH, 02h
    MOV  BH, 00h
    MOV  DH, 00h
    MOV  DL, 00h
    INT  10h

    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
CLEAR_SCREEN ENDP


;  READ_INPUT — Lee SEQ_LEN digitos del jugador
;  CORRECCIÓN: muestra "Digite la secuencia que se vio"
;              preserva todos los registros usados

READ_INPUT PROC
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH DI

    ; CORRECCIÓN: mensaje que pide digitar lo que se vio
    LEA  DX, MSG_INPUT
    MOV  AH, 09h
    INT  21h

    ; limpia el buffer INPUT antes de leer
    LEA  DI, INPUT
    MOV  CX, 15
    MOV  AL, 0
CLEAR_INPUT:
    MOV  [DI], AL
    INC  DI
    LOOP CLEAR_INPUT

    LEA  DI, INPUT
    MOV  CL, SEQ_LEN
    XOR  CH, CH

READ_LOOP:
    MOV  AH, 08h
    INT  21h                ; lee tecla sin eco

    CMP  AL, 0Dh
    JE   READ_DONE          ; ENTER termina antes de tiempo

    CMP  AL, '0'
    JB   READ_LOOP          ; ignora teclas que no sean digitos
    CMP  AL, '9'
    JA   READ_LOOP

    MOV  [DI], AL           ; guarda el digito en INPUT

    MOV  DL, AL             ; CORRECCIÓN: muestra el digito real
    MOV  AH, 02h            ; (no '*') para que el jugador confirme
    INT  21h

    INC  DI
    LOOP READ_LOOP

READ_DONE:
    LEA  DX, MSG_NEWLINE
    MOV  AH, 09h
    INT  21h

    POP  DI
    POP  DX
    POP  CX
    POP  AX
    RET
READ_INPUT ENDP


;  VALIDATE — Compara SEQUENCE e INPUT, actualiza puntaje/vidas

VALIDATE PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH DX

    MOV  CL, SEQ_LEN
    XOR  CH, CH
    LEA  SI, SEQUENCE
    LEA  DI, INPUT

VAL_LOOP:
    MOV  AL, [SI]
    CMP  AL, [DI]
    JNE  WRONG_INPUT
    INC  SI
    INC  DI
    LOOP VAL_LOOP

    ; todos los digitos coincidieron
    LEA  DX, MSG_CORRECT
    MOV  AH, 09h
    INT  21h

    MOV  AX, SCORE
    ADD  AX, 10
    MOV  SCORE, AX

    INC  SEQ_LEN
    JMP  VAL_DONE

WRONG_INPUT:
    LEA  DX, MSG_WRONG
    MOV  AH, 09h
    INT  21h
    DEC  LIVES

VAL_DONE:
    POP  DX
    POP  DI
    POP  SI
    POP  CX
    POP  AX
    RET
VALIDATE ENDP


;  SHOW_STATUS — Muestra nivel, vidas y puntaje

SHOW_STATUS PROC
    PUSH AX
    PUSH DX

    LEA  DX, MSG_LEVEL
    MOV  AH, 09h
    INT  21h
    MOV  AL, SEQ_LEN
    SUB  AL, 3              ; nivel 1 cuando SEQ_LEN=4
    ADD  AL, '0'
    MOV  DL, AL
    MOV  AH, 02h
    INT  21h
    LEA  DX, MSG_NEWLINE
    MOV  AH, 09h
    INT  21h

    LEA  DX, MSG_LIVES
    MOV  AH, 09h
    INT  21h
    MOV  DL, LIVES
    ADD  DL, '0'
    MOV  AH, 02h
    INT  21h
    LEA  DX, MSG_NEWLINE
    MOV  AH, 09h
    INT  21h

    LEA  DX, MSG_SCORE
    MOV  AH, 09h
    INT  21h
    MOV  AX, SCORE
    CALL PRINT_NUM
    LEA  DX, MSG_NEWLINE
    MOV  AH, 09h
    INT  21h

    POP  DX
    POP  AX
    RET
SHOW_STATUS ENDP


;  SHOW_TITLE — Imprime banner de bienvenida

SHOW_TITLE PROC
    PUSH AX
    PUSH DX
    LEA  DX, MSG_TITLE
    MOV  AH, 09h
    INT  21h
    POP  DX
    POP  AX
    RET
SHOW_TITLE ENDP


;  PRINT_NUM Imprime AX como numero decimal sin signo

PRINT_NUM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV  BX, 10
    XOR  CX, CX

DIVIDE_LOOP:
    XOR  DX, DX
    DIV  BX                 ; AX = AX/10, DX = AX mod 10
    PUSH DX
    INC  CX
    CMP  AX, 0
    JNE  DIVIDE_LOOP

PRINT_DIGITS:
    POP  DX
    ADD  DL, '0'
    MOV  AH, 02h
    INT  21h
    LOOP PRINT_DIGITS

    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
PRINT_NUM ENDP

END MAIN
