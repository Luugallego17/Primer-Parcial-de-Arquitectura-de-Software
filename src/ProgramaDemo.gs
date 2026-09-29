/**
 * Programa demostrativo obligatorio: multiplicación por sumas sucesivas.
 *
 * Calcula 6 x 4 sumando 6 cuatro veces con un bucle controlado por
 * CMP + JZ/JMP, y guarda el resultado (24 = 0x18) en el Segmento de
 * Datos, en la dirección 80h.
 *
 * Dir   Bytes   Instrucción
 * 00h   10 00   MOV AX, 0      ; acumulador del resultado
 * 02h   11 04   MOV BX, 4      ; contador de repeticiones
 * 04h   72 00   CMP BX, 0      ; ¿contador llegó a cero?   <- bucle
 * 06h   C1 0D   JZ 0x0D        ; sí: ir a guardar
 * 08h   40 06   ADD AX, 6      ; no: acumular otro 6
 * 0Ah   63      DEC BX         ; contador--
 * 0Bh   C0 04   JMP 0x04       ; repetir el bucle
 * 0Dh   30 80   STORE [0x80], AX ; resultado -> Segmento de Datos
 * 0Fh   FF      HLT            ; detener el reloj
 */

const PROGRAMA_DEMO = [
  '; === Multiplicación 6 x 4 por sumas sucesivas ===',
  '        MOV AX, 0        ; acumulador del resultado',
  '        MOV BX, 4        ; contador de repeticiones',
  'bucle:  CMP BX, 0        ; ¿contador == 0?',
  '        JZ fin           ; si ZF=1, terminar el bucle',
  '        ADD AX, 6        ; AX = AX + 6',
  '        DEC BX           ; BX = BX - 1',
  '        JMP bucle        ; repetir',
  'fin:    STORE [0x80], AX ; guardar 0x18 en el Segmento de Datos',
  '        HLT              ; detener el reloj'
];

/** Escribe el programa demo en la hoja Programa y lo carga en RAM. */
function cargarProgramaDemo() {
  const h = hoja(HOJA_PROG);
  h.clearContents();
  h.getRange(1, 1, PROGRAMA_DEMO.length, 1)
    .setValues(PROGRAMA_DEMO.map(function (l) { return [l]; }));
  btnLoadProgram();
}
