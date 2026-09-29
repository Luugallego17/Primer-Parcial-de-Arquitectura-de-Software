Attribute VB_Name = "modMemoria"
'==================================================================================
' modMemoria
' ---------------------------------------------------------------------------------
' Memoria principal (RAM) de 256 bytes direccionable de 00h a FFh.
' Expone las operaciones primitivas Read(address) y Write(address, value) exigidas
' por el enunciado, aisladas del resto del sistema para respetar el desacople de
' componentes (la CPU nunca toca el arreglo directamente).
'
' Tablero Kanban -> Tarjetas #2 (matriz RAM 16x16) y #3 (primitivas Read/Write).
'==================================================================================
Option Explicit

' Arreglo fisico de la RAM: 256 celdas de 1 byte.
Public Memoria(0 To MEM_TAM - 1) As Byte

'------------------------------------------------------------------------------------
' DireccionValida: valida que una direccion caiga en el rango 00h..FFh.
'------------------------------------------------------------------------------------
Public Function DireccionValida(ByVal direccion As Integer) As Boolean
    DireccionValida = (direccion >= 0 And direccion <= MEM_TAM - 1)
End Function

'------------------------------------------------------------------------------------
' LeerMemoria (Read): devuelve el byte almacenado en la direccion indicada.
' Operacion primitiva de lectura del bus de datos.
'------------------------------------------------------------------------------------
Public Function LeerMemoria(ByVal direccion As Integer) As Byte
    If Not DireccionValida(direccion) Then
        Err.Raise vbObjectError + 513, "modMemoria.LeerMemoria", _
                  "Direccion fuera de rango (00h-FFh): " & direccion
    End If
    LeerMemoria = Memoria(direccion)
End Function

'------------------------------------------------------------------------------------
' EscribirMemoria (Write): almacena un byte en la direccion indicada.
' Operacion primitiva de escritura del bus de datos.
'------------------------------------------------------------------------------------
Public Sub EscribirMemoria(ByVal direccion As Integer, ByVal valor As Byte)
    If Not DireccionValida(direccion) Then
        Err.Raise vbObjectError + 514, "modMemoria.EscribirMemoria", _
                  "Direccion fuera de rango (00h-FFh): " & direccion
    End If
    Memoria(direccion) = valor
End Sub

'------------------------------------------------------------------------------------
' LimpiarMemoria: pone toda la RAM a 00h (usado por RESET y por el cargador).
'------------------------------------------------------------------------------------
Public Sub LimpiarMemoria()
    Dim i As Integer
    For i = 0 To MEM_TAM - 1
        Memoria(i) = 0
    Next i
End Sub

'------------------------------------------------------------------------------------
' FilaDe / ColumnaDe: traducen una direccion lineal a su posicion en la matriz 16x16
' (fila = nibble alto, columna = nibble bajo). Usados por la interfaz grafica.
'------------------------------------------------------------------------------------
Public Function FilaDe(ByVal direccion As Integer) As Integer
    FilaDe = direccion \ 16
End Function

Public Function ColumnaDe(ByVal direccion As Integer) As Integer
    ColumnaDe = direccion Mod 16
End Function
