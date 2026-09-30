Attribute VB_Name = "modInterfaz"
'==================================================================================
' modInterfaz
' ---------------------------------------------------------------------------------
' Construccion y refresco de la hoja del simulador: cuadricula de memoria 16x16
' con segmentacion codigo/datos, panel de registros y banderas, controles y
' resaltado visual en tiempo real de la celda y los registros activos.
'
' Tablero Kanban -> Tarjetas #13 (resaltado visual) y parte de #1 (interfaz).
'==================================================================================
Option Explicit

' ---- Coordenadas de la cuadricula de memoria ----
Private Const MEM_FILA0 As Integer = 5      ' primera fila de datos (fila Excel)
Private Const MEM_COL0 As Integer = 6       ' primera columna de datos (F = 6)

' ---- Celdas del panel de registros (columna C = valores) ----
Private Const CEL_PC As String = "C5"
Private Const CEL_IR As String = "C6"
Private Const CEL_IRMNE As String = "D6"
Private Const CEL_MAR As String = "C7"
Private Const CEL_MDR As String = "C8"
Private Const CEL_AX As String = "C9"
Private Const CEL_BX As String = "C10"
Private Const CEL_ZF As String = "C13"
Private Const CEL_CF As String = "C14"
Private Const CEL_SF As String = "C15"
Private Const CEL_FASE As String = "C17"
Private Const CEL_PASO As String = "C18"
Private Const CEL_VEL As String = "C19"

'------------------------------------------------------------------------------------
' Hoja: obtiene (o crea) la hoja del simulador.
'------------------------------------------------------------------------------------
Public Function Hoja() As Worksheet
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(NOMBRE_HOJA)
    On Error GoTo 0
    If ws Is Nothing Then
        Set ws = ThisWorkbook.Worksheets.Add
        ws.Name = NOMBRE_HOJA
    End If
    Set Hoja = ws
End Function

'------------------------------------------------------------------------------------
' ConstruirSimulador: genera desde cero toda la interfaz (macro de un solo clic).
'------------------------------------------------------------------------------------
Public Sub ConstruirSimulador()
    Dim ws As Worksheet
    Set ws = Hoja()

    Application.ScreenUpdating = False
    ws.Cells.Clear
    On Error Resume Next
    ws.Buttons.Delete
    On Error GoTo 0

    ' ---- Titulo ----
    With ws.Range("B2")
        .Value = "SIMULADOR DE CPU - Arquitectura von Neumann (8 bits)"
        .Font.Bold = True
        .Font.Size = 14
    End With

    ' ---- Panel de registros ----
    ws.Range("B4").Value = "REGISTROS DE LA CPU"
    ws.Range("B4").Font.Bold = True
    EtiquetaReg ws, "B5", "PC"
    EtiquetaReg ws, "B6", "IR"
    EtiquetaReg ws, "B7", "MAR"
    EtiquetaReg ws, "B8", "MDR"
    EtiquetaReg ws, "B9", "AX"
    EtiquetaReg ws, "B10", "BX"

    ws.Range("B12").Value = "BANDERAS"
    ws.Range("B12").Font.Bold = True
    EtiquetaReg ws, "B13", "ZF"
    EtiquetaReg ws, "B14", "CF"
    EtiquetaReg ws, "B15", "SF"

    EtiquetaReg ws, "B17", "Fase"
    EtiquetaReg ws, "B18", "Paso #"
    EtiquetaReg ws, "B19", "Retardo (ms)"
    ws.Range(CEL_VEL).Value = 400

    ws.Columns("B").ColumnWidth = 12
    ws.Columns("C").ColumnWidth = 10
    ws.Columns("D").ColumnWidth = 16

    ' ---- Cuadricula de memoria 16x16 ----
    ws.Range("F3").Value = "MEMORIA PRINCIPAL (RAM 256 bytes)  -  azul: segmento de codigo / gris: datos"
    ws.Range("F3").Font.Bold = True

    Dim i As Integer
    For i = 0 To 15
        With ws.Cells(4, MEM_COL0 + i)              ' cabecera de columnas: nibble bajo
            .Value = Hex$(i)
            .Font.Bold = True
            .HorizontalAlignment = xlCenter
        End With
        With ws.Cells(MEM_FILA0 + i, 5)             ' cabecera de filas: nibble alto
            .Value = Hex$(i) & "0"
            .Font.Bold = True
            .HorizontalAlignment = xlCenter
        End With
    Next i

    Dim a As Integer
    For a = 0 To MEM_TAM - 1
        With CeldaMem(a)
            .NumberFormat = "@"
            .HorizontalAlignment = xlCenter
            .Font.Name = "Consolas"
        End With
    Next a
    ws.Range(ws.Cells(MEM_FILA0, MEM_COL0), ws.Cells(MEM_FILA0 + 15, MEM_COL0 + 15)).ColumnWidth = 4

    ' ---- Cabecera del panel de log ----
    ws.Cells(3, 24).Value = "LOG DE MICRO-OPERACIONES"
    ws.Cells(3, 24).Font.Bold = True
    ws.Columns(24).ColumnWidth = 52

    ' ---- Botones de control ----
    CrearBoton ws, "LOAD PROGRAM", "btnCargar", 8, 10
    CrearBoton ws, "STEP", "btnPaso", 8, 40
    CrearBoton ws, "RUN", "btnEjecutar", 8, 70
    CrearBoton ws, "PAUSE", "btnPausar", 8, 100
    CrearBoton ws, "RESET", "btnReset", 8, 130

    ReiniciarRegistros
    ReiniciarMotor
    RefrescarTodo

    Application.ScreenUpdating = True
    MsgBox "Simulador construido. Pulse LOAD PROGRAM para cargar el programa demostrativo.", vbInformation
End Sub

'------------------------------------------------------------------------------------
' RefrescarTodo: sincroniza toda la interfaz con el estado interno de la CPU.
'------------------------------------------------------------------------------------
Public Sub RefrescarTodo()
    RefrescarRegistros
    RefrescarMemoria
    Resaltar
End Sub

'------------------------------------------------------------------------------------
' RefrescarRegistros: vuelca los registros y banderas al panel.
'------------------------------------------------------------------------------------
Public Sub RefrescarRegistros()
    Dim ws As Worksheet
    Set ws = Hoja()
    ws.Range(CEL_PC).Value = Hex2(PC)
    ws.Range(CEL_IR).Value = Hex2(IR)
    ws.Range(CEL_IRMNE).Value = DescribirInstruccion(IR, IR_Op1, IR_Op2)
    ws.Range(CEL_MAR).Value = Hex2(MAR)
    ws.Range(CEL_MDR).Value = Hex2(MDR)
    ws.Range(CEL_AX).Value = Hex2(AX) & "  (" & AX & ")"
    ws.Range(CEL_BX).Value = Hex2(BX) & "  (" & BX & ")"
    ws.Range(CEL_ZF).Value = IIf(ZF, 1, 0)
    ws.Range(CEL_CF).Value = IIf(CF, 1, 0)
    ws.Range(CEL_SF).Value = IIf(SF, 1, 0)
    ws.Range(CEL_FASE).Value = NombreFase(Fase)
    ws.Range(CEL_PASO).Value = NumPaso
    RetardoMs = CLng(Val(ws.Range(CEL_VEL).Value))
End Sub

'------------------------------------------------------------------------------------
' RefrescarMemoria: repinta las 256 celdas con su valor y color de segmento base.
'------------------------------------------------------------------------------------
Public Sub RefrescarMemoria()
    Dim a As Integer
    For a = 0 To MEM_TAM - 1
        With CeldaMem(a)
            .Value = Right$("0" & Hex$(Memoria(a)), 2)
            If a < LongitudPrograma Then
                .Interior.Color = RGB(214, 231, 245)     ' segmento de codigo (azul claro)
            Else
                .Interior.Color = RGB(240, 240, 240)     ' segmento de datos (gris claro)
            End If
        End With
    Next a
End Sub

'------------------------------------------------------------------------------------
' Resaltar: marca la celda activa (MAR) y la instruccion apuntada por el PC.
'------------------------------------------------------------------------------------
Public Sub Resaltar()
    If DireccionValida(PC) Then CeldaMem(PC).Interior.Color = RGB(198, 239, 206)   ' PC -> verde
    If DireccionValida(MAR) Then CeldaMem(MAR).Interior.Color = RGB(255, 235, 156) ' MAR -> amarillo
End Sub

'==================================================================================
' Utilidades internas de la interfaz
'==================================================================================
Private Function CeldaMem(ByVal direccion As Integer) As Range
    Set CeldaMem = Hoja().Cells(MEM_FILA0 + FilaDe(direccion), MEM_COL0 + ColumnaDe(direccion))
End Function

Private Sub EtiquetaReg(ByVal ws As Worksheet, ByVal celdaEtiq As String, ByVal texto As String)
    ws.Range(celdaEtiq).Value = texto
    ws.Range(celdaEtiq).Font.Bold = True
End Sub

Private Function NombreFase(ByVal f As Integer) As String
    Select Case f
        Case FASE_FETCH:   NombreFase = "FETCH"
        Case FASE_DECODE:  NombreFase = "DECODE"
        Case FASE_EXECUTE: NombreFase = "EXECUTE"
        Case FASE_STORE:   NombreFase = "STORE"
        Case Else:         NombreFase = "-"
    End Select
End Function

Private Sub CrearBoton(ByVal ws As Worksheet, ByVal texto As String, ByVal macro As String, _
                       ByVal topPt As Single, ByVal leftPt As Single)
    Dim b As Button
    Set b = ws.Buttons.Add(leftPt, topPt, 78, 22)
    b.Caption = texto
    b.OnAction = macro
End Sub
