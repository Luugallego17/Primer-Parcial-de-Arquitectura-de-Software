/**
 * Simulador de CPU — Arquitectura von Neumann / x86 de 8 bits
 * Materia: Arquitectura de Computadoras (SIS-131)
 * Plataforma: Google Sheets + Google Apps Script (Opción B)
 *
 * Módulos del sistema (pensados para escalar en el Parcial 2 con
 * bus multiplexado, controladores de I/O e interrupciones):
 *   - Memoria.gs          Memoria principal (RAM 256 x 8 bits)
 *   - Registros.gs        Registros del CPU y banderas de estado
 *   - ALU.gs              Unidad Aritmético-Lógica
 *   - ISA.gs              Set de instrucciones y tabla de opcodes
 *   - Ensamblador.gs      Traductor mnemónico -> código máquina
 *   - CicloInstruccion.gs Unidad de Control (Fetch-Decode-Execute-Store)
 *   - Controles.gs        STEP / RUN / PAUSE / RESET / LOAD PROGRAM
 *   - Interfaz.gs         Construcción de la hoja y resaltado visual
 *   - LogMicroOps.gs      Registro cronológico de micro-operaciones
 *   - ProgramaDemo.gs     Programa demostrativo con bucles y saltos
 */

// Nombres de las hojas del libro
const HOJA_CPU  = 'Simulador';
const HOJA_RAM  = 'RAM';       // almacenamiento interno (oculta)
const HOJA_LOG  = 'Log';
const HOJA_PROG = 'Programa';

// Celdas fijas del panel de registros en la hoja Simulador
const CELDA = {
  PC:  'C4',  IR:  'C5',  MAR: 'C6',  MDR: 'C7',  AX: 'C8',  BX: 'C9',
  ZF:  'C11', CF:  'C12', SF:  'C13',
  FASE: 'C15', ESTADO: 'C16', DELAY: 'C17', VISTA: 'C18'
};

// Ubicación de la matriz de memoria 16x16 (celda F4 = dirección 00h)
const MEM = { FILA: 4, COL: 6, DIM: 16 };

// Segmentación lógica: 00h-7Fh Segmento de Código, 80h-FFh Segmento de Datos
const SEG_CODIGO_FIN = 0x7F;

function onOpen() {
  SpreadsheetApp.getUi().createMenu('▶ Simulador CPU')
    .addItem('Construir interfaz', 'construirInterfaz')
    .addSeparator()
    .addItem('LOAD PROGRAM', 'btnLoadProgram')
    .addItem('STEP (una fase)', 'btnStep')
    .addItem('RUN (continuo)', 'btnRun')
    .addItem('PAUSE', 'btnPause')
    .addItem('RESET', 'btnReset')
    .addSeparator()
    .addItem('Cargar programa demostrativo', 'cargarProgramaDemo')
    .addItem('Refrescar vista de memoria', 'refrescarMatrizMemoria')
    .addToUi();
}

/** Devuelve la hoja pedida, creándola si no existe. */
function hoja(nombre) {
  const ss = SpreadsheetApp.getActive();
  return ss.getSheetByName(nombre) || ss.insertSheet(nombre);
}

/** Formatea un byte como texto hexadecimal de dos dígitos (ej. 0x0A). */
function hex2(v) {
  return '0x' + (v & 0xFF).toString(16).toUpperCase().padStart(2, '0');
}
