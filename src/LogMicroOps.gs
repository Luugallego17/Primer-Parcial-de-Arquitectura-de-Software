/**
 * Log cronológico de micro-operaciones.
 *
 * Cada acción del simulador agrega una fila numerada a la hoja Log:
 *   [Paso 08] FETCH: MAR=0x12, MDR=0x05 → IR=ADD AX, 0x05
 */

function logMicroOp(fase, detalle) {
  const h = hoja(HOJA_LOG);
  const paso = siguientePaso();
  h.appendRow(['[Paso ' + String(paso).padStart(2, '0') + ']', fase, detalle]);
}

function siguientePaso() {
  const p = PropertiesService.getDocumentProperties();
  const n = Number(p.getProperty('LOG_PASO') || 0) + 1;
  p.setProperty('LOG_PASO', String(n));
  return n;
}

/** Limpia el log (lo invoca RESET). */
function logReset() {
  const h = hoja(HOJA_LOG);
  h.clearContents();
  h.getRange(1, 1, 1, 3).setValues([['Paso', 'Fase', 'Micro-operación']])
    .setFontWeight('bold');
  PropertiesService.getDocumentProperties().setProperty('LOG_PASO', '0');
}
