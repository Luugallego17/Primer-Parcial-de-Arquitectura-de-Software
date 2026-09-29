/**
 * Ensamblador de dos pasadas: traduce el programa fuente (hoja Programa)
 * a código máquina de la ISA.
 *
 * Sintaxis admitida por línea:
 *   [etiqueta:] MNEMONICO [operando1[, operando2]]  [; comentario]
 *
 * Operandos:
 *   AX / BX          registro
 *   n, 0xNN, NNh     inmediato (decimal o hexadecimal)
 *   [n] / [0xNN]     dirección de memoria (directo)
 *   etiqueta         destino de salto (JMP/JZ/JNZ)
 */

function ensamblar(lineasFuente) {
  const instrucciones = [];
  const etiquetas = {};
  let direccion = 0;

  // ---- Primera pasada: direcciones de etiquetas y análisis sintáctico ----
  lineasFuente.forEach(function (lineaCruda, idx) {
    let linea = String(lineaCruda).split(';')[0].trim();
    if (!linea) return;

    const conEtiqueta = linea.match(/^([A-Za-z_][\w]*)\s*:\s*(.*)$/);
    if (conEtiqueta) {
      etiquetas[conEtiqueta[1].toUpperCase()] = direccion;
      linea = conEtiqueta[2].trim();
      if (!linea) return;
    }

    const partes = linea.match(/^(\w+)\s*(.*)$/);
    const mnem = partes[1].toUpperCase();
    const operandos = partes[2]
      ? partes[2].split(',').map(function (o) { return o.trim().toUpperCase(); })
      : [];

    const inst = analizarInstruccion(mnem, operandos, idx + 1);
    inst.direccion = direccion;
    instrucciones.push(inst);
    direccion += ISA[inst.opcode].tam;

    if (direccion > SEG_CODIGO_FIN + 1) {
      throw new Error('El programa excede el Segmento de Código (00h-' +
        hex2(SEG_CODIGO_FIN) + ')');
    }
  });

  // ---- Segunda pasada: resolución de etiquetas y emisión de bytes ----
  const bytes = [];
  instrucciones.forEach(function (inst) {
    bytes.push(inst.opcode);
    if (ISA[inst.opcode].tam === 2) {
      let arg = inst.arg;
      if (typeof arg === 'string') { // etiqueta pendiente
        if (!(arg in etiquetas)) {
          throw new Error('Etiqueta no definida: ' + arg +
            ' (línea ' + inst.lineaNro + ')');
        }
        arg = etiquetas[arg];
      }
      bytes.push(arg & 0xFF);
    }
  });
  return bytes;
}

/** Normaliza una instrucción a su clave de la tabla ASM. */
function analizarInstruccion(mnem, operandos, lineaNro) {
  let arg = null;
  const claves = operandos.map(function (op) {
    if (op === 'AX' || op === 'BX') return op;

    const dirMem = op.match(/^\[(.+)\]$/);
    if (dirMem) { arg = parsearNumero(dirMem[1], lineaNro); return '[DIR]'; }

    const num = intentarNumero(op);
    if (num !== null) { arg = num; return esSalto(mnem) ? 'DIR' : 'IMM'; }

    // Identificador: etiqueta de salto (se resuelve en la 2ª pasada)
    if (esSalto(mnem) && /^[A-Z_]\w*$/.test(op)) { arg = op; return 'DIR'; }

    throw new Error('Operando inválido "' + op + '" (línea ' + lineaNro + ')');
  });

  const clave = (mnem + ' ' + claves.join(',')).trim();
  if (!(clave in ASM)) {
    throw new Error('Instrucción no reconocida por la ISA: "' + clave +
      '" (línea ' + lineaNro + ')');
  }
  if (arg !== null && typeof arg === 'number') validarByte(arg);
  return { opcode: ASM[clave], arg: arg, lineaNro: lineaNro };
}

function esSalto(mnem) {
  return mnem === 'JMP' || mnem === 'JZ' || mnem === 'JNZ';
}

function intentarNumero(texto) {
  if (/^0X[0-9A-F]+$/.test(texto)) return parseInt(texto.slice(2), 16);
  if (/^[0-9A-F]+H$/.test(texto))  return parseInt(texto.slice(0, -1), 16);
  if (/^\d+$/.test(texto))         return parseInt(texto, 10);
  return null;
}

function parsearNumero(texto, lineaNro) {
  const n = intentarNumero(texto.trim());
  if (n === null) {
    throw new Error('Número inválido "' + texto + '" (línea ' + lineaNro + ')');
  }
  return n;
}
