/**
 * Controles esenciales del simulador:
 * STEP, RUN (con delay ajustable), PAUSE, RESET y LOAD PROGRAM.
 * Cada función puede asignarse a un botón (dibujo) de la hoja.
 */

const MAX_FASES_RUN = 4000; // tope de seguridad contra bucles infinitos

/** STEP: avanza exactamente una fase del ciclo de instrucción. */
function btnStep() {
  if (panelGet('ESTADO') === 'LISTO') panelSet('ESTADO', 'EJECUTANDO');
  pasoFase();
  SpreadsheetApp.flush();
}

/** RUN: ejecución continua con retardo ajustable (celda DELAY, ms). */
function btnRun() {
  latches().deleteProperty('PAUSA');
  panelSet('ESTADO', 'EJECUTANDO');
  const delay = Math.max(0, Number(panelGet('DELAY')) || 300);

  for (let i = 0; i < MAX_FASES_RUN; i++) {
    if (panelGet('ESTADO') === 'HLT') break;
    if (latches().getProperty('PAUSA')) {
      panelSet('ESTADO', 'PAUSA');
      logMicroOp('—', 'Ejecución pausada por el usuario');
      break;
    }
    pasoFase();
    SpreadsheetApp.flush();
    if (delay > 0) Utilities.sleep(delay);
  }
}

/** PAUSE: solicita detener el bucle de RUN sin corromper el estado. */
function btnPause() {
  latches().setProperty('PAUSA', '1');
}

/** RESET: registros y PC a cero, banderas limpias, log vacío.
 *  El contenido de la RAM se conserva (el programa sigue cargado). */
function btnReset() {
  latches().deleteProperty('PAUSA');
  latches().setProperties({ OPCODE: '', ARG: '', DESTINO: '', RESULTADO: '' });
  registrosReset();
  logReset();
  limpiarResaltados();
  logMicroOp('—', 'RESET: registros y banderas a cero');
  SpreadsheetApp.flush();
}

/** LOAD PROGRAM: ensambla la hoja Programa y la carga en el
 *  Segmento de Código (a partir de 00h). */
function btnLoadProgram() {
  const h = hoja(HOJA_PROG);
  const ultima = h.getLastRow();
  if (ultima === 0) {
    SpreadsheetApp.getUi().alert('La hoja "' + HOJA_PROG + '" está vacía.');
    return;
  }
  const lineas = h.getRange(1, 1, ultima, 1).getDisplayValues()
    .map(function (f) { return f[0]; });

  let bytes;
  try {
    bytes = ensamblar(lineas);
  } catch (e) {
    SpreadsheetApp.getUi().alert('Error de ensamblado:\n' + e.message);
    return;
  }

  btnReset();
  for (let dir = 0; dir < bytes.length; dir++) {
    memWrite(dir, bytes[dir]);
  }
  refrescarMatrizMemoria();
  logMicroOp('—', 'LOAD PROGRAM: ' + bytes.length +
    ' bytes cargados en el Segmento de Código (00h-' +
    hex2(bytes.length - 1) + '). PC=0x00');
  SpreadsheetApp.flush();
}
