Attribute VB_Name = "modEnsamblador"
'==================================================================================
' modEnsamblador
' ---------------------------------------------------------------------------------
' Ensamblador de dos pasadas y cargador de programas (LOAD PROGRAM).
' Traduce el texto ensamblador (con etiquetas, comentarios ';' e inmediatos en
' decimal / hexadecimal) a los bytes de la ISA y los deposita en el segmento de
' codigo de la RAM a partir de la direccion 00h.
'
' Tablero Kanban -> Tarjeta #12 (cargador de programa LOAD PROGRAM).
'==================================================================================
Option Explicit

'------------------------------------------------------------------------------------
' CargarPrograma: ensambla el texto fuente y lo escribe en memoria desde 00h,
' dejando la CPU lista para ejecutar (registros y motor reiniciados).
'------------------------------------------------------------------------------------
Public Sub CargarPrograma(ByVal fuente As String)
    Dim programa() As Byte
    Dim n As Integer
    n = Ensamblar(fuente, programa)

    LimpiarMemoria
    Dim i As Integer
    For i = 0 To n - 1
        EscribirMemoria i, programa(i)
    Next i

    LongitudPrograma = n
    ReiniciarRegistros
    ReiniciarMotor
End Sub

'------------------------------------------------------------------------------------
' Ensamblar: convierte el fuente en un arreglo de bytes. Devuelve la cantidad de
' bytes generados. Pasada 1: resuelve etiquetas y calcula direcciones. Pasada 2:
' emite el codigo maquina.
'------------------------------------------------------------------------------------
Public Function Ensamblar(ByVal fuente As String, ByRef salida() As Byte) As Integer
    Dim lineas() As String
    lineas = Split(Replace(fuente, vbCr, ""), vbLf)

    Dim etiquetas As New Collection
    Dim mnem() As String, op1() As String, op2() As String
    Dim total As Integer, cuenta As Integer, i As Integer
    ReDim mnem(0 To UBound(lineas))
    ReDim op1(0 To UBound(lineas))
    ReDim op2(0 To UBound(lineas))
    cuenta = 0
    total = 0

    ' ---- Pasada 1: etiquetas y tamanos ----
    Dim linea As String, nombre As String, p As Integer
    Dim mm As String, a As String, b As String
    For i = 0 To UBound(lineas)
        linea = LimpiarLinea(lineas(i))
        If Len(linea) > 0 Then
            p = InStr(linea, ":")
            If p > 0 Then
                nombre = Trim$(Left$(linea, p - 1))
                On Error Resume Next
                etiquetas.Add total, UCase$(nombre)
                On Error GoTo 0
                linea = Trim$(Mid$(linea, p + 1))
            End If
            If Len(linea) > 0 Then
                SepararInstruccion linea, mm, a, b
                mnem(cuenta) = mm
                op1(cuenta) = a
                op2(cuenta) = b
                cuenta = cuenta + 1
                total = total + TamanoDeMnemonico(mm)
            End If
        End If
    Next i

    ' ---- Pasada 2: emision de codigo maquina ----
    If total = 0 Then
        ReDim salida(0 To 0)
        Ensamblar = 0
        Exit Function
    End If
    ReDim salida(0 To total - 1)
    Dim pos As Integer
    pos = 0
    For i = 0 To cuenta - 1
        pos = EmitirInstruccion(mnem(i), op1(i), op2(i), salida, pos, etiquetas)
    Next i

    Ensamblar = total
End Function

'==================================================================================
' Utilidades de analisis lexico
'==================================================================================

' Elimina comentarios (';'), tabulaciones y espacios sobrantes de una linea.
Private Function LimpiarLinea(ByVal linea As String) As String
    Dim p As Integer
    p = InStr(linea, ";")
    If p > 0 Then linea = Left$(linea, p - 1)
    LimpiarLinea = Trim$(Replace(linea, vbTab, " "))
End Function

' Separa "MOV AX, 0x04" en mnemonico="MOV", op1="AX", op2="0x04".
Private Sub SepararInstruccion(ByVal linea As String, ByRef mm As String, _
                               ByRef a As String, ByRef b As String)
    Dim sp As Integer, c As Integer, resto As String
    a = "": b = ""
    sp = InStr(linea, " ")
    If sp = 0 Then
        mm = UCase$(Trim$(linea))
        Exit Sub
    End If
    mm = UCase$(Trim$(Left$(linea, sp - 1)))
    resto = Trim$(Mid$(linea, sp + 1))
    c = InStr(resto, ",")
    If c = 0 Then
        a = Trim$(resto)
    Else
        a = Trim$(Left$(resto, c - 1))
        b = Trim$(Mid$(resto, c + 1))
    End If
End Sub

' Tamano en bytes de una instruccion segun su mnemonico.
Private Function TamanoDeMnemonico(ByVal mm As String) As Integer
    Select Case UCase$(mm)
        Case "NOP", "HLT"
            TamanoDeMnemonico = 1
        Case "INC", "DEC", "NOT", "JMP", "JZ", "JNZ"
            TamanoDeMnemonico = 2
        Case Else
            TamanoDeMnemonico = 3
    End Select
End Function

'==================================================================================
' Emision de codigo maquina
'==================================================================================
Private Function EmitirInstruccion(ByVal mm As String, ByVal a As String, ByVal b As String, _
                                   ByRef salida() As Byte, ByVal pos As Integer, _
                                   ByRef etiquetas As Collection) As Integer
    Select Case UCase$(mm)
        Case "NOP":  Emite salida, pos, OP_NOP
        Case "HLT":  Emite salida, pos, OP_HLT

        Case "MOV"
            If EsRegistro(b) Then
                Emite salida, pos, OP_MOV_RR: Emite salida, pos, IdRegistro(a): Emite salida, pos, IdRegistro(b)
            Else
                Emite salida, pos, OP_MOV_RI: Emite salida, pos, IdRegistro(a): Emite salida, pos, ValorInmediato(b)
            End If

        Case "LOAD"
            Emite salida, pos, OP_LOAD: Emite salida, pos, IdRegistro(a): Emite salida, pos, ResolverDireccion(b, etiquetas)
        Case "STORE"
            Emite salida, pos, OP_STORE: Emite salida, pos, ResolverDireccion(a, etiquetas): Emite salida, pos, IdRegistro(b)

        Case "ADD"
            If EsRegistro(b) Then
                Emite salida, pos, OP_ADD_RR: Emite salida, pos, IdRegistro(a): Emite salida, pos, IdRegistro(b)
            Else
                Emite salida, pos, OP_ADD_RI: Emite salida, pos, IdRegistro(a): Emite salida, pos, ValorInmediato(b)
            End If
        Case "SUB"
            If EsRegistro(b) Then
                Emite salida, pos, OP_SUB_RR: Emite salida, pos, IdRegistro(a): Emite salida, pos, IdRegistro(b)
            Else
                Emite salida, pos, OP_SUB_RI: Emite salida, pos, IdRegistro(a): Emite salida, pos, ValorInmediato(b)
            End If
        Case "CMP"
            If EsRegistro(b) Then
                Emite salida, pos, OP_CMP_RR: Emite salida, pos, IdRegistro(a): Emite salida, pos, IdRegistro(b)
            Else
                Emite salida, pos, OP_CMP_RI: Emite salida, pos, IdRegistro(a): Emite salida, pos, ValorInmediato(b)
            End If

        Case "INC": Emite salida, pos, OP_INC: Emite salida, pos, IdRegistro(a)
        Case "DEC": Emite salida, pos, OP_DEC: Emite salida, pos, IdRegistro(a)
        Case "NOT": Emite salida, pos, OP_NOT: Emite salida, pos, IdRegistro(a)

        Case "AND": Emite salida, pos, OP_AND: Emite salida, pos, IdRegistro(a): Emite salida, pos, IdRegistro(b)
        Case "OR":  Emite salida, pos, OP_OR:  Emite salida, pos, IdRegistro(a): Emite salida, pos, IdRegistro(b)
        Case "XOR": Emite salida, pos, OP_XOR: Emite salida, pos, IdRegistro(a): Emite salida, pos, IdRegistro(b)

        Case "JMP": Emite salida, pos, OP_JMP: Emite salida, pos, ResolverDireccion(a, etiquetas)
        Case "JZ":  Emite salida, pos, OP_JZ:  Emite salida, pos, ResolverDireccion(a, etiquetas)
        Case "JNZ": Emite salida, pos, OP_JNZ: Emite salida, pos, ResolverDireccion(a, etiquetas)

        Case Else
            Err.Raise vbObjectError + 520, "modEnsamblador", "Instruccion desconocida: " & mm
    End Select
    EmitirInstruccion = pos
End Function

' Escribe un byte en la posicion 'pos' y la avanza (ByRef).
Private Sub Emite(ByRef salida() As Byte, ByRef pos As Integer, ByVal valor As Byte)
    salida(pos) = valor
    pos = pos + 1
End Sub

'==================================================================================
' Analisis de operandos
'==================================================================================
Private Function EsRegistro(ByVal s As String) As Boolean
    Select Case UCase$(Trim$(s))
        Case "AX", "BX": EsRegistro = True
        Case Else:       EsRegistro = False
    End Select
End Function

Private Function IdRegistro(ByVal s As String) As Byte
    Select Case UCase$(Trim$(s))
        Case "AX": IdRegistro = REG_AX
        Case "BX": IdRegistro = REG_BX
        Case Else
            Err.Raise vbObjectError + 521, "modEnsamblador", "Registro no valido: " & s
    End Select
End Function

' Convierte un inmediato (decimal, 0x.. o ..h) a un byte 0..255.
Private Function ValorInmediato(ByVal s As String) As Byte
    ValorInmediato = CByte(NumeroDe(s) And &HFF)
End Function

' Resuelve un operando de direccion: numero, [numero] o etiqueta.
Private Function ResolverDireccion(ByVal s As String, ByRef etiquetas As Collection) As Byte
    s = QuitarCorchetes(s)
    If EsNumerico(s) Then
        ResolverDireccion = CByte(NumeroDe(s) And &HFF)
    Else
        Dim v As Variant
        On Error GoTo sinEtiqueta
        v = etiquetas(UCase$(Trim$(s)))
        ResolverDireccion = CByte(CInt(v) And &HFF)
        Exit Function
sinEtiqueta:
        Err.Raise vbObjectError + 522, "modEnsamblador", "Etiqueta no definida: " & s
    End If
End Function

Private Function QuitarCorchetes(ByVal s As String) As String
    s = Trim$(s)
    If Left$(s, 1) = "[" Then s = Mid$(s, 2)
    If Right$(s, 1) = "]" Then s = Left$(s, Len(s) - 1)
    QuitarCorchetes = Trim$(s)
End Function

Private Function EsNumerico(ByVal s As String) As Boolean
    s = UCase$(Trim$(s))
    If Len(s) = 0 Then EsNumerico = False: Exit Function
    If Left$(s, 2) = "0X" Then EsNumerico = True: Exit Function
    If Right$(s, 1) = "H" And IsNumeric("&H" & Left$(s, Len(s) - 1)) Then EsNumerico = True: Exit Function
    EsNumerico = IsNumeric(s)
End Function

' Parsea un literal numerico en decimal (31), hexadecimal 0x (0x1F) o sufijo h (1Fh).
Private Function NumeroDe(ByVal s As String) As Integer
    s = UCase$(Trim$(s))
    If Left$(s, 2) = "0X" Then
        NumeroDe = CInt(Val("&H" & Mid$(s, 3)))
    ElseIf Right$(s, 1) = "H" Then
        NumeroDe = CInt(Val("&H" & Left$(s, Len(s) - 1)))
    Else
        NumeroDe = CInt(Val(s))
    End If
End Function
