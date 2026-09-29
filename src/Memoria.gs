/**
 * Memoria Principal: 256 posiciones continuas de 8 bits (00h - FFh).
 *
 * El almacenamiento canónico vive en la hoja oculta RAM (una columna de
 * 256 valores decimales 0-255). La matriz 16x16 de la hoja Simulador es
 * la vista visible, formateada en Hex / Bin / Dec según la celda VISTA.
 *
 * Read() y Write() son la ÚNICA vía de acceso a la RAM: ningún otro
 * módulo toca el almacenamiento directamente.
 */

/** Inicializa las 256 celdas de la RAM en cero. */
function memInit() {
  const h = hoja(HOJA_RAM);
  const ceros = Array.from({ length: 256 }, () => [0]);
  h.getRange(1, 1, 256, 1).setValues(ceros);
  h.hideSheet();
  refrescarMatrizMemoria();
}

function validarDireccion(direccion) {
  if (!Number.isInteger(direccion) || direccion < 0x00 || direccion > 0xFF) {
    throw new Error('Dirección fuera de rango (00h-FFh): ' + direccion);
  }
}

function validarByte(valor) {
  if (!Number.isInteger(valor) || valor < 0 || valor > 0xFF) {
    throw new Error('Valor fuera de rango de 8 bits (0-255): ' + valor);
  }
}

/** Read(address): devuelve el byte almacenado en la dirección. */
function memRead(direccion) {
  validarDireccion(direccion);
  const v = Number(hoja(HOJA_RAM).getRange(direccion + 1, 1).getValue()) & 0xFF;
  resaltarCeldaMemoria(direccion);
  return v;
}

/** Write(address, value): escribe el byte y actualiza la vista. */
function memWrite(direccion, valor) {
  validarDireccion(direccion);
  validarByte(valor);
  hoja(HOJA_RAM).getRange(direccion + 1, 1).setValue(valor & 0xFF);
  pintarCeldaMemoria(direccion, valor & 0xFF);
  resaltarCeldaMemoria(direccion);
}

/** Vuelca las 256 celdas de la RAM a la matriz visible según VISTA. */
function refrescarMatrizMemoria() {
  const valores = hoja(HOJA_RAM).getRange(1, 1, 256, 1).getValues();
  const vista = vistaActual();
  const grid = [];
  for (let f = 0; f < MEM.DIM; f++) {
    const fila = [];
    for (let c = 0; c < MEM.DIM; c++) {
      fila.push(formatearByte(Number(valores[f * MEM.DIM + c][0]) & 0xFF, vista));
    }
    grid.push(fila);
  }
  hoja(HOJA_CPU).getRange(MEM.FILA, MEM.COL, MEM.DIM, MEM.DIM).setValues(grid);
}

/** Formatea un byte en la vista pedida: HEX, BIN o DEC. */
function formatearByte(valor, vista) {
  switch (vista) {
    case 'BIN': return valor.toString(2).padStart(8, '0');
    case 'DEC': return String(valor);
    default:    return valor.toString(16).toUpperCase().padStart(2, '0');
  }
}

function vistaActual() {
  const v = hoja(HOJA_CPU).getRange(CELDA.VISTA).getDisplayValue().toUpperCase();
  return (v === 'BIN' || v === 'DEC') ? v : 'HEX';
}

/** Fila/columna de la celda visible que corresponde a una dirección. */
function direccionACelda(direccion) {
  return {
    fila: MEM.FILA + (direccion >> 4),
    col:  MEM.COL + (direccion & 0x0F)
  };
}
