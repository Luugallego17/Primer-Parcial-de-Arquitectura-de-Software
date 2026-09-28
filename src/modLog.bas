Attribute VB_Name = "modLog"
'==================================================================================
' modLog
' ---------------------------------------------------------------------------------
' Log cronologico de micro-operaciones. Cada accion del ciclo de reloj (fetch,
' lecturas/escrituras de memoria, operaciones de la ALU, saltos y write-back) queda
' registrada en un panel de la hoja con su numero de paso, tal como exige el
' enunciado (ej. [Paso 008] FETCH: MAR=12h  MDR=05h -> IR=ADD).
'
' Tablero Kanban -> Tarjeta #16 (log cronologico de micro-operaciones).
'==================================================================================
Option Explicit

Private Const LOG_COL As Integer = 24        ' columna X
Private Const LOG_FILA0 As Long = 4          ' primera fila del listado
Public LogFila As Long                        ' proxima fila libre del log

'------------------------------------------------------------------------------------
' AnexarLog: agrega una linea numerada al panel de micro-operaciones.
'------------------------------------------------------------------------------------
Public Sub AnexarLog(ByVal texto As String)
    NumPaso = NumPaso + 1
    If LogFila < LOG_FILA0 Then LogFila = LOG_FILA0

    Dim ws As Worksheet
    Set ws = Hoja()
    With ws.Cells(LogFila, LOG_COL)
        .Value = "[Paso " & Format$(NumPaso, "000") & "] " & texto
        .Font.Name = "Consolas"
        .Font.Size = 9
    End With

    LogFila = LogFila + 1
End Sub

'------------------------------------------------------------------------------------
' LimpiarLog: vacia el panel y reinicia el contador de pasos.
'------------------------------------------------------------------------------------
Public Sub LimpiarLog()
    Dim ws As Worksheet
    Set ws = Hoja()
    ws.Range(ws.Cells(LOG_FILA0, LOG_COL), ws.Cells(4000, LOG_COL)).ClearContents
    LogFila = LOG_FILA0
    NumPaso = 0
End Sub
