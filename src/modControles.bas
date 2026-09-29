Attribute VB_Name = "modControles"
'==================================================================================
' modControles
' ---------------------------------------------------------------------------------
' Macros asociadas a los botones de la interfaz. Implementan el modo Paso a Paso
' (STEP), el modo Continuo (RUN) con retardo ajustable y PAUSE, el RESET y la carga
' del programa (LOAD PROGRAM).
'
' Tablero Kanban -> Tarjetas #14 (modo Continuo RUN/PAUSE) y #15 (RESET/controles).
'==================================================================================
Option Explicit

'------------------------------------------------------------------------------------
' btnCargar (LOAD PROGRAM): carga el programa demostrativo en memoria.
'------------------------------------------------------------------------------------
Public Sub btnCargar()
    LimpiarLog
    CargarProgramaDemo
    AnexarLog "Programa cargado (" & LongitudPrograma & " bytes). Listo para ejecutar."
    RefrescarTodo
End Sub

'------------------------------------------------------------------------------------
' btnPaso (STEP): avanza exactamente una micro-operacion (una fase del ciclo).
'------------------------------------------------------------------------------------
Public Sub btnPaso()
    PasoMicro
    RefrescarTodo
End Sub

'------------------------------------------------------------------------------------
' btnEjecutar (RUN): ejecuta de forma continua hasta HLT, PAUSE o RESET, con el
' retardo indicado en la hoja para animar el flujo en tiempo real.
'------------------------------------------------------------------------------------
Public Sub btnEjecutar()
    If Halted Then
        AnexarLog "CPU detenida (HLT). Pulse RESET para reiniciar."
        RefrescarTodo
        Exit Sub
    End If

    Corriendo = True
    Pausado = False
    RefrescarRegistros                     ' lee el retardo configurado

    Do While Not Halted And Corriendo And Not Pausado
        PasoInstruccion
        RefrescarTodo
        Espera RetardoMs
        DoEvents
    Loop

    Corriendo = False
    If Pausado Then AnexarLog "== Ejecucion en PAUSA =="
    RefrescarTodo
End Sub

'------------------------------------------------------------------------------------
' btnPausar (PAUSE): solicita la pausa del modo continuo.
'------------------------------------------------------------------------------------
Public Sub btnPausar()
    Pausado = True
    Corriendo = False
End Sub

'------------------------------------------------------------------------------------
' btnReset (RESET): restaura registros, banderas y PC a cero y reinicia el ciclo,
' conservando el programa cargado en memoria.
'------------------------------------------------------------------------------------
Public Sub btnReset()
    Corriendo = False
    Pausado = False
    ReiniciarRegistros
    ReiniciarMotor
    LimpiarLog
    AnexarLog "RESET: registros y PC a 00h. Programa conservado en memoria."
    RefrescarTodo
End Sub

'------------------------------------------------------------------------------------
' Espera: retardo activo de 'ms' milisegundos cediendo el control a Excel (DoEvents)
' para poder atender el boton PAUSE durante el modo continuo.
'------------------------------------------------------------------------------------
Private Sub Espera(ByVal ms As Long)
    Dim t As Double
    If ms <= 0 Then Exit Sub
    t = Timer
    Do While (Timer - t) * 1000# < ms
        DoEvents
        If Timer < t Then Exit Do          ' proteccion ante medianoche
    Loop
End Sub
