Attribute VB_Name = "modPrograma"
'==================================================================================
' modPrograma
' ---------------------------------------------------------------------------------
' Programa demostrativo obligatorio: multiplicacion por sumas sucesivas.
' Contiene un bucle y una bifurcacion condicional (JZ) que ejercitan el ciclo
' completo, las banderas y la escritura en el segmento de datos.
'
' Calcula 3 x 4 = 12 (0Ch) sumando 3 cuatro veces y guarda el resultado en la
' celda de datos RAM[20h].
'   AX = acumulador (resultado)   BX = contador (multiplicador)
'
' Tablero Kanban -> Tarjeta #17 (programa demostrativo con bucles y bifurcaciones).
'==================================================================================
Option Explicit

'------------------------------------------------------------------------------------
' FuentePrograma: texto ensamblador del programa demostrativo.
'------------------------------------------------------------------------------------
Public Function FuentePrograma() As String
    Dim s As String
    s = ""
    s = s & "; ============================================================" & vbLf
    s = s & "; Multiplicacion por sumas sucesivas: 3 x 4 = 12 (0Ch)" & vbLf
    s = s & "; Resultado almacenado en el segmento de datos RAM[20h]" & vbLf
    s = s & ";   AX = acumulador (resultado)" & vbLf
    s = s & ";   BX = contador (multiplicador)" & vbLf
    s = s & "; ============================================================" & vbLf
    s = s & "        MOV AX, 0        ; AX = 0  (resultado)" & vbLf
    s = s & "        MOV BX, 4        ; BX = 4  (multiplicador / contador)" & vbLf
    s = s & "LOOP:   CMP BX, 0        ; contador == 0 ?" & vbLf
    s = s & "        JZ  FIN          ; si es cero, terminar" & vbLf
    s = s & "        ADD AX, 3        ; resultado += 3  (multiplicando)" & vbLf
    s = s & "        DEC BX           ; contador--" & vbLf
    s = s & "        JMP LOOP         ; repetir el bucle" & vbLf
    s = s & "FIN:    STORE [0x20], AX ; guardar resultado en RAM[20h]" & vbLf
    s = s & "        HLT              ; detener el reloj" & vbLf
    FuentePrograma = s
End Function

'------------------------------------------------------------------------------------
' CargarProgramaDemo: ensambla y carga el programa demostrativo en memoria.
'------------------------------------------------------------------------------------
Public Sub CargarProgramaDemo()
    CargarPrograma FuentePrograma()
End Sub
