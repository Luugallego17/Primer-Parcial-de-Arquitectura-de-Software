Attribute VB_Name = "modRegistros"
'==================================================================================
' modRegistros
' ---------------------------------------------------------------------------------
' Banco de registros visibles del CPU. Modela los registros que la interfaz debe
' reflejar en todo momento y expone acceso uniforme por identificador para que la
' ALU y la Unidad de Control no dependan de nombres concretos.
'
' Tablero Kanban -> Tarjetas #4 (registros PC, IR, MAR, MDR, AX, BX) y #5 (banderas).
'==================================================================================
Option Explicit

' ---- Registros de control del flujo de instruccion ----
Public PC As Byte      ' Program Counter: direccion de la siguiente instruccion
Public IR As Byte      ' Instruction Register: opcode de la instruccion en curso
Public IR_Op1 As Byte  ' primer operando capturado durante la fase Decode
Public IR_Op2 As Byte  ' segundo operando capturado durante la fase Decode

' ---- Registros de interfaz con la memoria ----
Public MAR As Byte     ' Memory Address Register: direccion a leer/escribir
Public MDR As Byte     ' Memory Data/Buffer Register: dato transferido con la RAM

' ---- Registros de proposito general (8 bits) ----
Public AX As Byte      ' Acumulador (AC)
Public BX As Byte      ' Registro de proposito general

' ---- Registro de estado (banderas de 1 bit actualizadas por la ALU) ----
Public ZF As Boolean   ' Zero Flag  : 1 si el ultimo resultado fue cero
Public CF As Boolean   ' Carry Flag : 1 si hubo acarreo/prestamo sin signo
Public SF As Boolean   ' Sign Flag  : 1 si el MSB del resultado es 1 (negativo en Ca2)

'------------------------------------------------------------------------------------
' FijarBanderasZS: actualiza ZF y SF a partir de un resultado de 8 bits. La ALU la
' invoca tras cada operacion aritmetico-logica. CF se fija por separado segun el
' tipo de operacion (acarreo en suma, prestamo en resta).
'------------------------------------------------------------------------------------
Public Sub FijarBanderasZS(ByVal resultado As Byte)
    ZF = (resultado = 0)
    SF = ((resultado And &H80) <> 0)
End Sub

'------------------------------------------------------------------------------------
' TextoBanderas: representacion compacta del registro de estado para el log.
'------------------------------------------------------------------------------------
Public Function TextoBanderas() As String
    TextoBanderas = "ZF=" & IIf(ZF, 1, 0) & " CF=" & IIf(CF, 1, 0) & " SF=" & IIf(SF, 1, 0)
End Function

'------------------------------------------------------------------------------------
' LeerReg / EscribirReg: acceso uniforme al banco de registros por identificador.
'------------------------------------------------------------------------------------
Public Function LeerReg(ByVal id As Byte) As Byte
    Select Case id
        Case REG_AX: LeerReg = AX
        Case REG_BX: LeerReg = BX
        Case Else:   LeerReg = 0
    End Select
End Function

Public Sub EscribirReg(ByVal id As Byte, ByVal valor As Byte)
    Select Case id
        Case REG_AX: AX = valor
        Case REG_BX: BX = valor
    End Select
End Sub

'------------------------------------------------------------------------------------
' ReiniciarRegistros: restaura todos los registros visibles a cero (usado por RESET).
'------------------------------------------------------------------------------------
Public Sub ReiniciarRegistros()
    PC = 0
    IR = 0
    IR_Op1 = 0
    IR_Op2 = 0
    MAR = 0
    MDR = 0
    AX = 0
    BX = 0
    ZF = False
    CF = False
    SF = False
End Sub
