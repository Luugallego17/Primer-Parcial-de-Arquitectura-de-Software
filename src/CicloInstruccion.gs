/**
 * Unidad de Control: ciclo de instrucción completo en 4 fases.
 *
 *   1. FETCH   PC → MAR; RAM[MAR] → MDR; MDR → IR; PC ← PC + 1
 *   2. DECODE  interpreta el opcode del IR, identifica el modo de
 *              direccionamiento y busca el byte de operando si existe.
 *   3. EXECUTE la ALU opera o se resuelve la bifurcación; banderas.
 *   4. STORE   write-back al registro destino o MDR → RAM[MAR].
 *
 * El estado decodificado entre fases se conserva en DocumentProperties
 * (OPCODE, ARG, DESTINO, RESULTADO), simulando los latches internos
 * de la Unidad de Control.
 */

function latches() { return PropertiesService.getDocumentProperties(); }

/** Ejecuta UNA fase del ciclo (lo invoca STEP y el bucle de RUN). */
function pasoFase() {
  if (panelGet('ESTADO') === 'HLT') {
    logMicroOp('—', 'CPU detenido (HLT). Use RESET para reiniciar.');
    return;
  }
  limpiarResaltados();
  const fase = panelGet('FASE') || 'FETCH';
  switch (fase) {
    case 'FETCH':   faseFetch();   break;
    case 'DECODE':  faseDecode();  break;
    case 'EXECUTE': faseExecute(); break;
    case 'STORE':   faseStore();   break;
    default: panelSet('FASE', 'FETCH');
  }
}

// ---------------------------------------------------------- 1. FETCH
function faseFetch() {
  const pc = regGet('PC');
  regSet('MAR', pc);                      // PC → MAR
  const opcode = memRead(pc);             // RAM[MAR] → MDR
  regSet('MDR', opcode);
  panelSet('IR', hex2(opcode));           // MDR → IR
  regSet('PC', (pc + 1) & 0xFF);          // PC ← PC + 1
  logMicroOp('FETCH', 'MAR=' + hex2(pc) + ', MDR=' + hex2(opcode) +
    ' → IR=' + hex2(opcode) + ', PC=' + hex2(regGet('PC')));
  panelSet('FASE', 'DECODE');
}

// --------------------------------------------------------- 2. DECODE
function faseDecode() {
  const opcode = regGet('MDR');
  const info = isaDecodificar(opcode);
  let arg = null;
  let irTexto = info.texto;

  if (info.tam === 2) {                   // buscar byte de operando
    const pc = regGet('PC');
    regSet('MAR', pc);
    arg = memRead(pc);
    regSet('MDR', arg);
    regSet('PC', (pc + 1) & 0xFF);
    irTexto = info.texto.replace('imm', hex2(arg)).replace('dir', hex2(arg));
  }

  panelSet('IR', irTexto);
  latches().setProperties({ OPCODE: String(opcode), ARG: String(arg) });
  logMicroOp('DECODE', 'Opcode ' + hex2(opcode) + ' = "' + irTexto +
    '" (' + info.tam + ' byte' + (info.tam > 1 ? 's' : '') + ')' +
    (arg === null ? '' : ', operando=' + hex2(arg)));
  panelSet('FASE', 'EXECUTE');
}

// -------------------------------------------------------- 3. EXECUTE
function faseExecute() {
  const opcode = Number(latches().getProperty('OPCODE'));
  const argTxt = latches().getProperty('ARG');
  const arg = argTxt === 'null' ? null : Number(argTxt);
  const familia = opcode & 0xF0;
  const variante = opcode & 0x0F;
  let destino = 'NINGUNO';
  let resultado = 0;

  const OPS_ALU = { 0x40: 'ADD', 0x50: 'SUB', 0x70: 'CMP',
                    0x80: 'AND', 0x90: 'OR', 0xA0: 'XOR' };

  if (opcode === 0xFF) {                                   // HLT
    panelSet('ESTADO', 'HLT');
    logMicroOp('EXECUTE', 'HLT: se detiene el reloj del CPU');
  } else if (opcode === 0x10 || opcode === 0x11) {         // MOV reg, imm
    destino = opcode === 0x10 ? 'AX' : 'BX';
    resultado = arg;
  } else if (opcode === 0x12 || opcode === 0x13) {         // MOV reg, reg
    destino = opcode === 0x12 ? 'AX' : 'BX';
    resultado = regGet(opcode === 0x12 ? 'BX' : 'AX');
  } else if (opcode === 0x20 || opcode === 0x21) {         // LOAD reg, [dir]
    destino = opcode === 0x20 ? 'AX' : 'BX';
    regSet('MAR', arg);
    resultado = memRead(arg);
    regSet('MDR', resultado);
    logMicroOp('EXECUTE', 'LOAD: RAM[' + hex2(arg) + ']=' + hex2(resultado));
  } else if (opcode === 0x30 || opcode === 0x31) {         // STORE [dir], reg
    destino = 'MEM';
    regSet('MAR', arg);
    resultado = regGet(opcode === 0x30 ? 'AX' : 'BX');
    regSet('MDR', resultado);
    logMicroOp('EXECUTE', 'STORE preparado: MDR=' + hex2(resultado) +
      ', MAR=' + hex2(arg));
  } else if (familia in OPS_ALU) {                          // ALU binaria
    const op = OPS_ALU[familia];
    const reg = (variante === 0 || variante === 1) ? 'AX' : 'BX';
    const b = (variante === 0 || variante === 2)
      ? arg
      : regGet(reg === 'AX' ? 'BX' : 'AX');
    resultado = aluEjecutar(op, regGet(reg), b);
    destino = op === 'CMP' ? 'NINGUNO' : reg;               // CMP descarta
  } else if (familia === 0x60) {                            // INC / DEC
    const reg = (variante % 2 === 0) ? 'AX' : 'BX';
    resultado = aluEjecutar(variante < 2 ? 'INC' : 'DEC', regGet(reg), 0);
    destino = reg;
  } else if (opcode === 0xB0 || opcode === 0xB1) {          // NOT
    const reg = opcode === 0xB0 ? 'AX' : 'BX';
    resultado = aluEjecutar('NOT', regGet(reg), 0);
    destino = reg;
  } else if (familia === 0xC0) {                            // saltos
    const salta = opcode === 0xC0 ||
      (opcode === 0xC1 && flagGet('ZF') === 1) ||
      (opcode === 0xC2 && flagGet('ZF') === 0);
    if (salta) {
      regSet('PC', arg);
      logMicroOp('EXECUTE', 'Salto tomado → PC=' + hex2(arg));
    } else {
      logMicroOp('EXECUTE', 'Salto NO tomado (ZF=' + flagGet('ZF') + ')');
    }
  } else {
    throw new Error('Opcode sin ruta de ejecución: ' + hex2(opcode));
  }

  latches().setProperties({ DESTINO: destino, RESULTADO: String(resultado) });
  panelSet('FASE', 'STORE');
}

// ---------------------------------------------------------- 4. STORE
function faseStore() {
  const destino = latches().getProperty('DESTINO');
  const resultado = Number(latches().getProperty('RESULTADO'));

  if (destino === 'AX' || destino === 'BX') {
    regSet(destino, resultado);
    logMicroOp('STORE', 'Write-back: ' + destino + ' ← ' + hex2(resultado));
  } else if (destino === 'MEM') {
    const mar = regGet('MAR');
    memWrite(mar, regGet('MDR'));                 // MDR → RAM[MAR]
    logMicroOp('STORE', 'MDR → RAM[MAR]: RAM[' + hex2(mar) + '] ← ' +
      hex2(regGet('MDR')));
  } else {
    logMicroOp('STORE', 'Sin write-back para esta instrucción');
  }
  panelSet('FASE', 'FETCH');
}
