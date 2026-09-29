Attribute VB_Name = "modISA"
'==================================================================================
' modISA
' ---------------------------------------------------------------------------------
' Definicion del Conjunto de Instrucciones (ISA) del procesador simulado.
' Contiene la tabla formal de opcodes, el tamano en bytes de cada instruccion y
' las rutinas para describir de forma legible (mnemonico) una instruccion, tanto
' para el registro IR como para el log de micro-operaciones.
'
' Codificacion de operandos de registro: AX = 00h, BX = 01h.
'
' Tablero Kanban -> Tarjeta #7 (definir la ISA: tabla de opcodes y codificacion).
'==================================================================================
Option Explicit

' ---- Tabla de opcodes -------------------------------------------------------------
' Transferencia de datos
Public Const OP_NOP As Byte = &H0          ' NOP                (1 byte)
Public Const OP_MOV_RI As Byte = &H10      ' MOV reg, imm       (3 bytes)
Public Const OP_MOV_RR As Byte = &H11      ' MOV reg, reg       (3 bytes)
Public Const OP_LOAD As Byte = &H20        ' LOAD reg, [dir]    (3 bytes)
Public Const OP_STORE As Byte = &H21       ' STORE [dir], reg   (3 bytes)
' Aritmetica
Public Const OP_ADD_RI As Byte = &H30      ' ADD reg, imm       (3 bytes)
Public Const OP_ADD_RR As Byte = &H31      ' ADD reg, reg       (3 bytes)
Public Const OP_SUB_RI As Byte = &H32      ' SUB reg, imm       (3 bytes)
Public Const OP_SUB_RR As Byte = &H33      ' SUB reg, reg       (3 bytes)
Public Const OP_INC As Byte = &H34         ' INC reg            (2 bytes)
Public Const OP_DEC As Byte = &H35         ' DEC reg            (2 bytes)
Public Const OP_CMP_RI As Byte = &H36      ' CMP reg, imm       (3 bytes)
Public Const OP_CMP_RR As Byte = &H37      ' CMP reg, reg       (3 bytes)
' Logica
Public Const OP_AND As Byte = &H40         ' AND reg, reg       (3 bytes)
Public Const OP_OR As Byte = &H41          ' OR  reg, reg       (3 bytes)
Public Const OP_XOR As Byte = &H42         ' XOR reg, reg       (3 bytes)
Public Const OP_NOT As Byte = &H43         ' NOT reg            (2 bytes)
' Control de flujo
Public Const OP_JMP As Byte = &H50         ' JMP dir            (2 bytes)
Public Const OP_JZ As Byte = &H51          ' JZ  dir            (2 bytes)
Public Const OP_JNZ As Byte = &H52         ' JNZ dir            (2 bytes)
Public Const OP_HLT As Byte = &HFF         ' HLT               (1 byte)

'------------------------------------------------------------------------------------
' TamanoInstruccion: numero total de bytes que ocupa una instruccion (opcode +
' operandos), a partir de su opcode. Es la fuente unica de verdad usada por el
' cargador y por la fase Decode.
'------------------------------------------------------------------------------------
Public Function TamanoInstruccion(ByVal opcode As Byte) As Integer
    Select Case opcode
        Case OP_NOP, OP_HLT
            TamanoInstruccion = 1
        Case OP_INC, OP_DEC, OP_NOT, OP_JMP, OP_JZ, OP_JNZ
            TamanoInstruccion = 2
        Case OP_MOV_RI, OP_MOV_RR, OP_LOAD, OP_STORE, _
             OP_ADD_RI, OP_ADD_RR, OP_SUB_RI, OP_SUB_RR, _
             OP_CMP_RI, OP_CMP_RR, OP_AND, OP_OR, OP_XOR
            TamanoInstruccion = 3
        Case Else
            TamanoInstruccion = 1     ' opcode desconocido -> se trata como NOP
    End Select
End Function

'------------------------------------------------------------------------------------
' NombreReg: nombre legible de un registro a partir de su id.
'------------------------------------------------------------------------------------
Public Function NombreReg(ByVal id As Byte) As String
    Select Case id
        Case REG_AX: NombreReg = "AX"
        Case REG_BX: NombreReg = "BX"
        Case Else:   NombreReg = "R?"
    End Select
End Function

'------------------------------------------------------------------------------------
' Hex2: formatea un byte como dos digitos hexadecimales con sufijo 'h' (ej. 0Ch).
'------------------------------------------------------------------------------------
Public Function Hex2(ByVal valor As Byte) As String
    Hex2 = Right$("0" & Hex$(valor), 2) & "h"
End Function

'------------------------------------------------------------------------------------
' DescribirInstruccion: reconstruye el mnemonico ensamblador de una instruccion a
' partir de su opcode y operandos ya capturados. Se usa para pintar el IR y el log.
'------------------------------------------------------------------------------------
Public Function DescribirInstruccion(ByVal opcode As Byte, ByVal op1 As Byte, ByVal op2 As Byte) As String
    Select Case opcode
        Case OP_NOP:    DescribirInstruccion = "NOP"
        Case OP_HLT:    DescribirInstruccion = "HLT"
        Case OP_MOV_RI: DescribirInstruccion = "MOV " & NombreReg(op1) & ", " & Hex2(op2)
        Case OP_MOV_RR: DescribirInstruccion = "MOV " & NombreReg(op1) & ", " & NombreReg(op2)
        Case OP_LOAD:   DescribirInstruccion = "LOAD " & NombreReg(op1) & ", [" & Hex2(op2) & "]"
        Case OP_STORE:  DescribirInstruccion = "STORE [" & Hex2(op1) & "], " & NombreReg(op2)
        Case OP_ADD_RI: DescribirInstruccion = "ADD " & NombreReg(op1) & ", " & Hex2(op2)
        Case OP_ADD_RR: DescribirInstruccion = "ADD " & NombreReg(op1) & ", " & NombreReg(op2)
        Case OP_SUB_RI: DescribirInstruccion = "SUB " & NombreReg(op1) & ", " & Hex2(op2)
        Case OP_SUB_RR: DescribirInstruccion = "SUB " & NombreReg(op1) & ", " & NombreReg(op2)
        Case OP_INC:    DescribirInstruccion = "INC " & NombreReg(op1)
        Case OP_DEC:    DescribirInstruccion = "DEC " & NombreReg(op1)
        Case OP_CMP_RI: DescribirInstruccion = "CMP " & NombreReg(op1) & ", " & Hex2(op2)
        Case OP_CMP_RR: DescribirInstruccion = "CMP " & NombreReg(op1) & ", " & NombreReg(op2)
        Case OP_AND:    DescribirInstruccion = "AND " & NombreReg(op1) & ", " & NombreReg(op2)
        Case OP_OR:     DescribirInstruccion = "OR " & NombreReg(op1) & ", " & NombreReg(op2)
        Case OP_XOR:    DescribirInstruccion = "XOR " & NombreReg(op1) & ", " & NombreReg(op2)
        Case OP_NOT:    DescribirInstruccion = "NOT " & NombreReg(op1)
        Case OP_JMP:    DescribirInstruccion = "JMP " & Hex2(op1)
        Case OP_JZ:     DescribirInstruccion = "JZ " & Hex2(op1)
        Case OP_JNZ:    DescribirInstruccion = "JNZ " & Hex2(op1)
        Case Else:      DescribirInstruccion = "??? (" & Hex2(opcode) & ")"
    End Select
End Function
