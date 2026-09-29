/**
 * Registros visibles del CPU (todos de 8 bits) y banderas de estado.
 *
 *   PC  - Program Counter: dirección de la siguiente instrucción.
 *   IR  - Instruction Register: opcode y operandos en curso (texto).
 *   MAR - Memory Address Register: dirección a leer/escribir.
 *   MDR - Memory Data/Buffer Register: dato transferido con la RAM.
 *   AX  - Acumulador de propósito general.
 *   BX  - Registro de propósito general.
 *   ZF / CF / SF - banderas actualizadas por la ALU.
 *
 * Los valores viven en las celdas del panel (hoja Simulador), de modo
 * que el estado del procesador es siempre visible e inspeccionable.
 */

const REGISTROS_8BITS = ['PC', 'MAR', 'MDR', 'AX', 'BX'];
const BANDERAS = ['ZF', 'CF', 'SF'];

/** Lee un registro de 8 bits desde su celda (formato 0xNN). */
function regGet(nombre) {
  const texto = hoja(HOJA_CPU).getRange(CELDA[nombre]).getDisplayValue();
  const v = parseInt(String(texto).replace('0x', ''), 16);
  return Number.isNaN(v) ? 0 : (v & 0xFF);
}

/** Escribe un registro de 8 bits en su celda y lo resalta. */
function regSet(nombre, valor) {
  hoja(HOJA_CPU).getRange(CELDA[nombre]).setValue(hex2(valor));
  resaltarRegistro(nombre);
}

/** Lee una bandera (0 o 1). */
function flagGet(nombre) {
  return Number(hoja(HOJA_CPU).getRange(CELDA[nombre]).getValue()) === 1 ? 1 : 0;
}

/** Escribe una bandera (0 o 1) y la resalta. */
function flagSet(nombre, valor) {
  hoja(HOJA_CPU).getRange(CELDA[nombre]).setValue(valor ? 1 : 0);
  resaltarRegistro(nombre);
}

/** Celdas de texto del panel: IR, FASE y ESTADO. */
function panelSet(nombre, texto) {
  hoja(HOJA_CPU).getRange(CELDA[nombre]).setValue(texto);
  if (nombre === 'IR') resaltarRegistro('IR');
}

function panelGet(nombre) {
  return hoja(HOJA_CPU).getRange(CELDA[nombre]).getDisplayValue();
}

/** Restaura registros, banderas, fase y estado a su valor inicial. */
function registrosReset() {
  REGISTROS_8BITS.forEach(function (r) { regSet(r, 0); });
  BANDERAS.forEach(function (f) { flagSet(f, 0); });
  panelSet('IR', '—');
  panelSet('FASE', 'FETCH');
  panelSet('ESTADO', 'LISTO');
}
