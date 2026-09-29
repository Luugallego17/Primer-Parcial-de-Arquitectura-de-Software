/**
 * Construcción de la interfaz y animación visual del simulador.
 *
 * Distribución de la hoja Simulador:
 *   B3:C18  panel de registros, banderas y controles de estado
 *   E3:U19  matriz de memoria 16x16 con encabezados hexadecimales
 */

const COLOR_CODIGO   = '#dbe8ff'; // Segmento de Código (00h-7Fh)
const COLOR_DATOS    = '#e2f3e4'; // Segmento de Datos  (80h-FFh)
const COLOR_ACTIVO   = '#ffe082'; // celda/registro activo en la fase actual
const COLOR_PANEL    = '#f4f6f8';

/** Crea (o reconstruye) toda la interfaz del simulador. */
function construirInterfaz() {
  const h = hoja(HOJA_CPU);
  h.clear();
  h.setHiddenGridlines(true);

  // Título
  h.getRange('B1:U1').merge().setValue(
    'SIMULADOR DE CPU — von Neumann / x86 de 8 bits (SIS-131)')
    .setFontWeight('bold').setFontSize(14);

  // ---- Panel de registros ----
  h.getRange('B3').setValue('REGISTROS').setFontWeight('bold');
  const etiquetas = [
    ['PC'], ['IR'], ['MAR'], ['MDR'], ['AX'], ['BX']
  ];
  h.getRange('B4:B9').setValues(etiquetas).setFontWeight('bold');
  h.getRange('B10').setValue('BANDERAS').setFontWeight('bold');
  h.getRange('B11:B13').setValues([['ZF'], ['CF'], ['SF']]).setFontWeight('bold');
  h.getRange('B14').setValue('CONTROL').setFontWeight('bold');
  h.getRange('B15:B18').setValues([['FASE'], ['ESTADO'], ['DELAY (ms)'], ['VISTA']])
    .setFontWeight('bold');
  h.getRange('B3:C18').setBackground(COLOR_PANEL);
  h.getRange('C4:C18').setHorizontalAlignment('center');

  // Valores por defecto de control
  h.getRange(CELDA.DELAY).setValue(300);
  const vista = h.getRange(CELDA.VISTA);
  vista.setValue('HEX');
  vista.setDataValidation(SpreadsheetApp.newDataValidation()
    .requireValueInList(['HEX', 'BIN', 'DEC'], true).build());

  // ---- Matriz de memoria 16x16 ----
  h.getRange('E3').setValue('RAM').setFontWeight('bold');
  const encabezadoCols = [];
  for (let c = 0; c < MEM.DIM; c++) {
    encabezadoCols.push(c.toString(16).toUpperCase());
  }
  h.getRange(MEM.FILA - 1, MEM.COL, 1, MEM.DIM).setValues([encabezadoCols])
    .setFontWeight('bold').setHorizontalAlignment('center');
  for (let f = 0; f < MEM.DIM; f++) {
    h.getRange(MEM.FILA + f, MEM.COL - 1).setValue(
      (f * 16).toString(16).toUpperCase().padStart(2, '0'))
      .setFontWeight('bold').setHorizontalAlignment('center');
  }
  const grid = h.getRange(MEM.FILA, MEM.COL, MEM.DIM, MEM.DIM);
  grid.setHorizontalAlignment('center').setFontFamily('Courier New');

  // Segmentación visual: Código (filas 0-7) / Datos (filas 8-15)
  h.getRange(MEM.FILA, MEM.COL, MEM.DIM / 2, MEM.DIM).setBackground(COLOR_CODIGO);
  h.getRange(MEM.FILA + MEM.DIM / 2, MEM.COL, MEM.DIM / 2, MEM.DIM)
    .setBackground(COLOR_DATOS);
  h.getRange(MEM.FILA + MEM.DIM, MEM.COL, 1, MEM.DIM / 2).merge()
    .setValue('■ Segmento de Código (00h-7Fh)').setFontColor('#3c5a99');
  h.getRange(MEM.FILA + MEM.DIM, MEM.COL + MEM.DIM / 2, 1, MEM.DIM / 2).merge()
    .setValue('■ Segmento de Datos (80h-FFh)').setFontColor('#3f7a44');

  for (let c = MEM.COL - 1; c < MEM.COL + MEM.DIM; c++) h.setColumnWidth(c, 42);

  // ---- Hojas auxiliares ----
  logReset();
  const prog = hoja(HOJA_PROG);
  if (prog.getLastRow() === 0) {
    prog.getRange('A1').setValue('; Escriba aquí su programa (una instrucción por línea)');
  }

  memInit();
  registrosReset();
  SpreadsheetApp.flush();
}

/** Pinta el valor de una celda de memoria en la vista actual. */
function pintarCeldaMemoria(direccion, valor) {
  const p = direccionACelda(direccion);
  hoja(HOJA_CPU).getRange(p.fila, p.col)
    .setValue(formatearByte(valor, vistaActual()));
}

/** Resalta la celda de memoria activa (lectura o escritura). */
function resaltarCeldaMemoria(direccion) {
  const p = direccionACelda(direccion);
  hoja(HOJA_CPU).getRange(p.fila, p.col).setBackground(COLOR_ACTIVO);
}

/** Resalta el registro o bandera que acaba de cambiar. */
function resaltarRegistro(nombre) {
  hoja(HOJA_CPU).getRange(CELDA[nombre]).setBackground(COLOR_ACTIVO);
}

/** Restaura los colores de fondo del panel y de la matriz. */
function limpiarResaltados() {
  const h = hoja(HOJA_CPU);
  h.getRange('C4:C13').setBackground(COLOR_PANEL);
  h.getRange(MEM.FILA, MEM.COL, MEM.DIM / 2, MEM.DIM).setBackground(COLOR_CODIGO);
  h.getRange(MEM.FILA + MEM.DIM / 2, MEM.COL, MEM.DIM / 2, MEM.DIM)
    .setBackground(COLOR_DATOS);
}
