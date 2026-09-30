Attribute VB_Name = "modEstado"
'==================================================================================
' modEstado
' ---------------------------------------------------------------------------------
' Estado global y constantes de arquitectura del simulador de CPU
' (arquitectura von Neumann / x86 de 8 bits).
'
' Aqui viven unicamente las constantes de la maquina y las banderas que controlan
' el motor de ejecucion (paso a paso / continuo). Los registros, la memoria y la
' ALU se definen en sus propios modulos para mantener el diseno desacoplado y
' escalable de cara al Segundo Parcial (Buses e I/O).
'
' Tablero Kanban -> Tarjeta #1 (estructura modular del proyecto).
'==================================================================================
Option Explicit

' ---- Parametros de la arquitectura -------------------------------------------------
Public Const MEM_TAM As Integer = 256          ' 256 posiciones: 00h (0d) .. FFh (255d)
Public Const ANCHO_PALABRA As Integer = 8      ' 8 bits (1 byte) por celda
Public Const NOMBRE_HOJA As String = "Simulador"      ' nombre de la hoja de trabajo

' Identificadores internos de los registros de proposito general
Public Const REG_AX As Byte = 0
Public Const REG_BX As Byte = 1

' ---- Fases del ciclo de instruccion ------------------------------------------------
Public Const FASE_FETCH As Integer = 0
Public Const FASE_DECODE As Integer = 1
Public Const FASE_EXECUTE As Integer = 2
Public Const FASE_STORE As Integer = 3

' ---- Control del motor de ejecucion ------------------------------------------------
Public Halted As Boolean        ' True cuando se ejecuto HLT (reloj detenido)
Public Corriendo As Boolean      ' True durante el modo continuo (RUN)
Public Pausado As Boolean        ' solicitud de PAUSA del usuario
Public RetardoMs As Long         ' retardo entre pasos en modo continuo (ms)
Public NumPaso As Long           ' contador cronologico de micro-operaciones
Public Fase As Integer           ' fase actual del ciclo (FASE_FETCH .. FASE_STORE)
Public LongitudPrograma As Integer  ' bytes ocupados por el ultimo programa cargado

' Escritura diferida: la fase Execute deja aqui el resultado y la fase Store lo aplica
Public PendienteTipo As String   ' "REG" | "MEM" | "" (sin escritura)
Public PendienteDestino As Byte  ' id de registro o direccion de memoria
Public PendienteValor As Byte    ' valor a escribir en la fase Store

'------------------------------------------------------------------------------------
' Reinicia unicamente el estado del motor de ejecucion (no toca memoria ni registros).
'------------------------------------------------------------------------------------
Public Sub ReiniciarMotor()
    Halted = False
    Corriendo = False
    Pausado = False
    NumPaso = 0
    Fase = FASE_FETCH
    LongitudPrograma = LongitudPrograma   ' se conserva el programa cargado
    PendienteTipo = ""
    PendienteDestino = 0
    PendienteValor = 0
    If RetardoMs <= 0 Then RetardoMs = 400
End Sub
