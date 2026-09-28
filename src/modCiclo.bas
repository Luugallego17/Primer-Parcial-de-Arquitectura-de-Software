Attribute VB_Name = "modCiclo"
'==================================================================================
' modCiclo
' ---------------------------------------------------------------------------------
' Ciclo de instruccion completo: Fetch -> Decode -> Execute -> Store/Write-back.
' Actua como Unidad de Control: secuencia las cuatro fases del ciclo de reloj y
' coordina memoria, registros y ALU. Cada llamada a PasoMicro avanza UNA fase
' (micro-operacion); PasoInstruccion completa una instruccion entera.
'
' Tablero Kanban -> Tarjetas #8 (Fetch), #9 (Decode), #10 (Execute), #11 (Store).
'==================================================================================
Option Explicit

'------------------------------------------------------------------------------------
' PasoMicro: ejecuta la fase actual del ciclo (una micro-operacion) y deja el
' sistema listo para la siguiente. Es el corazon del modo Paso a Paso.
'------------------------------------------------------------------------------------
Public Sub PasoMicro()
    If Halted Then
        AnexarLog "CPU detenida (HLT). Pulse RESET para reiniciar."
        Exit Sub
    End If

    Select Case Fase
        Case FASE_FETCH:   FaseFetch
        Case FASE_DECODE:  FaseDecode
        Case FASE_EXECUTE: FaseExecute
        Case FASE_STORE:   FaseStore
    End Select
End Sub

'------------------------------------------------------------------------------------
' PasoInstruccion: completa la instruccion en curso (recorre las fases pendientes
' hasta volver a FETCH). Usado por el modo Continuo y como "paso de instruccion".
'------------------------------------------------------------------------------------
Public Sub PasoInstruccion()
    If Halted Then
        AnexarLog "CPU detenida (HLT). Pulse RESET para reiniciar."
        Exit Sub
    End If
    Do
        PasoMicro
        If Halted Then Exit Do
    Loop Until Fase = FASE_FETCH
End Sub

'==================================================================================
' FASE 1 - FETCH (Busqueda)
' La direccion en PC se carga en MAR; se lee la RAM hacia MDR; el dato pasa al IR
' y se incrementa el PC.
'==================================================================================
Public Sub FaseFetch()
    MAR = PC
    MDR = LeerMemoria(MAR)
    IR = MDR
    AnexarLog "FETCH  : MAR=" & Hex2(MAR) & "  MDR=" & Hex2(MDR) & "  -> IR=" & Hex2(IR)
    PC = (CInt(PC) + 1) And &HFF
    Fase = FASE_DECODE
End Sub

'==================================================================================
' FASE 2 - DECODE (Decodificacion)
' La Unidad de Control interpreta el Opcode del IR, determina cuantos operandos
' necesita y los captura desde memoria (usando MAR/MDR), avanzando el PC.
'==================================================================================
Public Sub FaseDecode()
    Dim nOperandos As Integer
    nOperandos = TamanoInstruccion(IR) - 1
    IR_Op1 = 0
    IR_Op2 = 0

    If nOperandos >= 1 Then
        MAR = PC
        MDR = LeerMemoria(MAR)
        IR_Op1 = MDR
        PC = (CInt(PC) + 1) And &HFF
    End If
    If nOperandos >= 2 Then
        MAR = PC
        MDR = LeerMemoria(MAR)
        IR_Op2 = MDR
        PC = (CInt(PC) + 1) And &HFF
    End If

    AnexarLog "DECODE : " & DescribirInstruccion(IR, IR_Op1, IR_Op2)
    Fase = FASE_EXECUTE
End Sub

'==================================================================================
' FASE 3 - EXECUTE (Ejecucion)
' La ALU efectua la operacion aritmetica/logica, o se resuelve el salto
' condicional/incondicional; se actualizan las banderas. El resultado a escribir
' se deja "pendiente" para la fase Store (write-back).
'==================================================================================
Public Sub FaseExecute()
    Dim res As Byte
    PendienteTipo = ""
    PendienteDestino = 0
    PendienteValor = 0

    Select Case IR
        Case OP_NOP
            ' sin operacion

        Case OP_MOV_RI
            EscribirPendienteReg IR_Op1, IR_Op2
        Case OP_MOV_RR
            EscribirPendienteReg IR_Op1, LeerReg(IR_Op2)

        Case OP_LOAD
            MAR = IR_Op2
            MDR = LeerMemoria(MAR)
            EscribirPendienteReg IR_Op1, MDR
        Case OP_STORE
            PendienteTipo = "MEM"
            PendienteDestino = IR_Op1
            PendienteValor = LeerReg(IR_Op2)

        Case OP_ADD_RI
            EscribirPendienteReg IR_Op1, EjecutarALU(aluADD, LeerReg(IR_Op1), IR_Op2)
        Case OP_ADD_RR
            EscribirPendienteReg IR_Op1, EjecutarALU(aluADD, LeerReg(IR_Op1), LeerReg(IR_Op2))
        Case OP_SUB_RI
            EscribirPendienteReg IR_Op1, EjecutarALU(aluSUB, LeerReg(IR_Op1), IR_Op2)
        Case OP_SUB_RR
            EscribirPendienteReg IR_Op1, EjecutarALU(aluSUB, LeerReg(IR_Op1), LeerReg(IR_Op2))
        Case OP_INC
            EscribirPendienteReg IR_Op1, EjecutarALU(aluADD, LeerReg(IR_Op1), 1)
        Case OP_DEC
            EscribirPendienteReg IR_Op1, EjecutarALU(aluSUB, LeerReg(IR_Op1), 1)

        Case OP_CMP_RI
            EjecutarALU aluCMP, LeerReg(IR_Op1), IR_Op2          ' solo actualiza banderas
        Case OP_CMP_RR
            EjecutarALU aluCMP, LeerReg(IR_Op1), LeerReg(IR_Op2)

        Case OP_AND
            EscribirPendienteReg IR_Op1, EjecutarALU(aluAND, LeerReg(IR_Op1), LeerReg(IR_Op2))
        Case OP_OR
            EscribirPendienteReg IR_Op1, EjecutarALU(aluOR, LeerReg(IR_Op1), LeerReg(IR_Op2))
        Case OP_XOR
            EscribirPendienteReg IR_Op1, EjecutarALU(aluXOR, LeerReg(IR_Op1), LeerReg(IR_Op2))
        Case OP_NOT
            EscribirPendienteReg IR_Op1, EjecutarALU(aluNOT, LeerReg(IR_Op1), 0)

        Case OP_JMP
            PC = IR_Op1
        Case OP_JZ
            If ZF Then PC = IR_Op1
        Case OP_JNZ
            If Not ZF Then PC = IR_Op1

        Case OP_HLT
            Halted = True
    End Select

    AnexarLog "EXECUTE: " & DescribirInstruccion(IR, IR_Op1, IR_Op2) & "   [" & TextoBanderas() & "]"

    If Halted Then
        AnexarLog "------- CPU DETENIDA (HLT) -------"
    Else
        Fase = FASE_STORE
    End If
End Sub

'==================================================================================
' FASE 4 - STORE / WRITE-BACK (Almacenamiento)
' El resultado final se guarda en el registro destino (AX/BX) o en la celda de
' memoria apuntada (MDR -> RAM[MAR]).
'==================================================================================
Public Sub FaseStore()
    Select Case PendienteTipo
        Case "REG"
            EscribirReg PendienteDestino, PendienteValor
            AnexarLog "STORE  : " & NombreReg(PendienteDestino) & " <- " & Hex2(PendienteValor)
        Case "MEM"
            MAR = PendienteDestino
            MDR = PendienteValor
            EscribirMemoria MAR, MDR
            AnexarLog "STORE  : RAM[" & Hex2(MAR) & "] <- " & Hex2(MDR)
        Case Else
            AnexarLog "STORE  : (sin escritura en este ciclo)"
    End Select

    PendienteTipo = ""
    Fase = FASE_FETCH
End Sub

'------------------------------------------------------------------------------------
' EscribirPendienteReg: helper para dejar preparada una escritura de registro que
' la fase Store aplicara (write-back diferido).
'------------------------------------------------------------------------------------
Private Sub EscribirPendienteReg(ByVal idReg As Byte, ByVal valor As Byte)
    PendienteTipo = "REG"
    PendienteDestino = idReg
    PendienteValor = valor
End Sub
