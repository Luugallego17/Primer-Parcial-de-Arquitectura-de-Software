Attribute VB_Name = "modALU"
'==================================================================================
' modALU
' ---------------------------------------------------------------------------------
' Unidad Aritmetico-Logica (ALU). Procesa las operaciones aritmeticas y logicas
' sobre operandos de 8 bits y actualiza el registro de estado (banderas ZF/CF/SF).
'
' Todas las operaciones se calculan en aritmetica de 16 bits (Integer) para poder
' detectar el acarreo/prestamo y luego se truncan a 8 bits (mascara &HFF), tal
' como lo haria una ALU fisica de 8 bits.
'
' Tablero Kanban -> Tarjeta #6 (modulo ALU: ADD, SUB, INC, DEC, AND, OR, XOR,
' NOT, CMP).
'==================================================================================
Option Explicit

' Operaciones reconocidas por la ALU
Public Enum AluOp
    aluADD
    aluSUB
    aluAND
    aluOR
    aluXOR
    aluNOT
    aluCMP      ' resta que solo fija banderas (no produce resultado almacenable)
End Enum

'------------------------------------------------------------------------------------
' EjecutarALU: aplica la operacion 'op' a los operandos a y b, actualiza las
' banderas y devuelve el resultado de 8 bits. Para aluCMP el valor devuelto no se
' almacena (solo interesan las banderas).
'------------------------------------------------------------------------------------
Public Function EjecutarALU(ByVal op As AluOp, ByVal a As Byte, ByVal b As Byte) As Byte
    Dim t As Integer
    Dim r As Byte

    Select Case op
        Case aluADD
            t = CInt(a) + CInt(b)
            CF = (t > 255)
            r = t And &HFF
            FijarBanderasZS r

        Case aluSUB, aluCMP
            t = CInt(a) - CInt(b)
            CF = (a < b)                 ' prestamo sin signo
            r = ((t Mod 256) + 256) Mod 256
            FijarBanderasZS r

        Case aluAND
            r = a And b
            CF = False
            FijarBanderasZS r

        Case aluOR
            r = a Or b
            CF = False
            FijarBanderasZS r

        Case aluXOR
            r = a Xor b
            CF = False
            FijarBanderasZS r

        Case aluNOT
            r = (Not a) And &HFF         ' complemento a 1 sobre 8 bits
            CF = False
            FijarBanderasZS r
    End Select

    EjecutarALU = r
End Function
