/**
 * ALU — Unidad Aritmético-Lógica de 8 bits.
 *
 * Procesa las operaciones aritméticas (ADD, SUB, INC, DEC) y lógicas
 * (AND, OR, XOR, NOT, CMP) y actualiza las banderas de estado:
 *
 *   ZF (Zero Flag):  1 si el resultado fue cero.
 *   CF (Carry Flag): 1 si hubo acarreo/desbordamiento sin signo
 *                    (o préstamo en la resta).
 *   SF (Sign Flag):  copia del bit más significativo del resultado
 *                    (1 = negativo en complemento a 2).
 *
 * CMP ejecuta la resta y actualiza banderas SIN devolver resultado
 * al registro destino (la Unidad de Control lo descarta).
 */

function aluEjecutar(operacion, a, b) {
  let bruto;
  let carry = 0;

  switch (operacion) {
    case 'ADD': bruto = a + b; carry = bruto > 0xFF ? 1 : 0; break;
    case 'SUB':
    case 'CMP': bruto = a - b; carry = bruto < 0 ? 1 : 0; break;
    case 'INC': bruto = a + 1; carry = bruto > 0xFF ? 1 : 0; break;
    case 'DEC': bruto = a - 1; carry = bruto < 0 ? 1 : 0; break;
    case 'AND': bruto = a & b; break;
    case 'OR':  bruto = a | b; break;
    case 'XOR': bruto = a ^ b; break;
    case 'NOT': bruto = ~a; break;
    default: throw new Error('Operación desconocida en la ALU: ' + operacion);
  }

  const resultado = bruto & 0xFF; // aritmética de 8 bits (wrap-around)

  flagSet('ZF', resultado === 0 ? 1 : 0);
  flagSet('CF', carry);
  flagSet('SF', (resultado & 0x80) ? 1 : 0);

  logMicroOp('EXECUTE', 'ALU ' + operacion + ': A=' + hex2(a) +
    (operacion === 'INC' || operacion === 'DEC' || operacion === 'NOT'
      ? '' : ', B=' + hex2(b)) +
    ' → ' + hex2(resultado) +
    ' [ZF=' + flagGet('ZF') + ' CF=' + flagGet('CF') + ' SF=' + flagGet('SF') + ']');

  return resultado;
}
