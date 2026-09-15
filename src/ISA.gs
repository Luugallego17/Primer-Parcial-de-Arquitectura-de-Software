/**
 * ISA — Set de instrucciones del simulador (x86 simplificado, 8 bits).
 *
 * Codificación: 1 byte de opcode + 0 o 1 byte de operando.
 *   - imm : valor inmediato de 8 bits.
 *   - dir : dirección de memoria de 8 bits (00h-FFh).
 *
 * Familias por nibble alto y variante por nibble bajo:
 *   x0: destino AX, operando inmediato    x1: destino AX, fuente BX
 *   x2: destino BX, operando inmediato    x3: destino BX, fuente AX
 */

const ISA = {
  // Transferencia de datos
  0x10: { clave: 'MOV AX,IMM',    texto: 'MOV AX, imm',    tam: 2 },
  0x11: { clave: 'MOV BX,IMM',    texto: 'MOV BX, imm',    tam: 2 },
  0x12: { clave: 'MOV AX,BX',     texto: 'MOV AX, BX',     tam: 1 },
  0x13: { clave: 'MOV BX,AX',     texto: 'MOV BX, AX',     tam: 1 },
  0x20: { clave: 'LOAD AX,[DIR]', texto: 'LOAD AX, [dir]', tam: 2 },
  0x21: { clave: 'LOAD BX,[DIR]', texto: 'LOAD BX, [dir]', tam: 2 },
  0x30: { clave: 'STORE [DIR],AX', texto: 'STORE [dir], AX', tam: 2 },
  0x31: { clave: 'STORE [DIR],BX', texto: 'STORE [dir], BX', tam: 2 },

  // Aritmética
  0x40: { clave: 'ADD AX,IMM', texto: 'ADD AX, imm', tam: 2 },
  0x41: { clave: 'ADD AX,BX',  texto: 'ADD AX, BX',  tam: 1 },
  0x42: { clave: 'ADD BX,IMM', texto: 'ADD BX, imm', tam: 2 },
  0x43: { clave: 'ADD BX,AX',  texto: 'ADD BX, AX',  tam: 1 },
  0x50: { clave: 'SUB AX,IMM', texto: 'SUB AX, imm', tam: 2 },
  0x51: { clave: 'SUB AX,BX',  texto: 'SUB AX, BX',  tam: 1 },
  0x52: { clave: 'SUB BX,IMM', texto: 'SUB BX, imm', tam: 2 },
  0x53: { clave: 'SUB BX,AX',  texto: 'SUB BX, AX',  tam: 1 },
  0x60: { clave: 'INC AX', texto: 'INC AX', tam: 1 },
  0x61: { clave: 'INC BX', texto: 'INC BX', tam: 1 },
  0x62: { clave: 'DEC AX', texto: 'DEC AX', tam: 1 },
  0x63: { clave: 'DEC BX', texto: 'DEC BX', tam: 1 },
  0x70: { clave: 'CMP AX,IMM', texto: 'CMP AX, imm', tam: 2 },
  0x71: { clave: 'CMP AX,BX',  texto: 'CMP AX, BX',  tam: 1 },
  0x72: { clave: 'CMP BX,IMM', texto: 'CMP BX, imm', tam: 2 },
  0x73: { clave: 'CMP BX,AX',  texto: 'CMP BX, AX',  tam: 1 },

  // Lógica
  0x80: { clave: 'AND AX,IMM', texto: 'AND AX, imm', tam: 2 },
  0x81: { clave: 'AND AX,BX',  texto: 'AND AX, BX',  tam: 1 },
  0x82: { clave: 'AND BX,IMM', texto: 'AND BX, imm', tam: 2 },
  0x83: { clave: 'AND BX,AX',  texto: 'AND BX, AX',  tam: 1 },
  0x90: { clave: 'OR AX,IMM',  texto: 'OR AX, imm',  tam: 2 },
  0x91: { clave: 'OR AX,BX',   texto: 'OR AX, BX',   tam: 1 },
  0x92: { clave: 'OR BX,IMM',  texto: 'OR BX, imm',  tam: 2 },
  0x93: { clave: 'OR BX,AX',   texto: 'OR BX, AX',   tam: 1 },
  0xA0: { clave: 'XOR AX,IMM', texto: 'XOR AX, imm', tam: 2 },
  0xA1: { clave: 'XOR AX,BX',  texto: 'XOR AX, BX',  tam: 1 },
  0xA2: { clave: 'XOR BX,IMM', texto: 'XOR BX, imm', tam: 2 },
  0xA3: { clave: 'XOR BX,AX',  texto: 'XOR BX, AX',  tam: 1 },
  0xB0: { clave: 'NOT AX', texto: 'NOT AX', tam: 1 },
  0xB1: { clave: 'NOT BX', texto: 'NOT BX', tam: 1 },

  // Control de flujo
  0xC0: { clave: 'JMP DIR', texto: 'JMP dir', tam: 2 },
  0xC1: { clave: 'JZ DIR',  texto: 'JZ dir',  tam: 2 },
  0xC2: { clave: 'JNZ DIR', texto: 'JNZ dir', tam: 2 },
  0xFF: { clave: 'HLT', texto: 'HLT', tam: 1 }
};

/** Tabla inversa: clave normalizada del ensamblador -> opcode. */
const ASM = (function () {
  const t = {};
  Object.keys(ISA).forEach(function (op) {
    t[ISA[op].clave] = Number(op);
  });
  return t;
})();

/** Devuelve la entrada de la ISA para un opcode, o error controlado. */
function isaDecodificar(opcode) {
  const info = ISA[opcode];
  if (!info) {
    throw new Error('Opcode inválido: ' + hex2(opcode) +
      ' (no pertenece a la ISA del simulador)');
  }
  return info;
}
