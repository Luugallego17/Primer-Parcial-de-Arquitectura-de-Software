# Tablero Kanban — Parcial 1: Simulador de CPU (von Neumann 8 bits)

Gestión de tareas del proyecto según la sección 3 del enunciado del Primer Parcial
de Arquitectura de Computadoras (SIS-131).

## Columnas del tablero (exigidas por el enunciado)

| Columna | Uso |
|---|---|
| **Backlog** | Tareas identificadas pero aún no priorizadas |
| **To Do** | Tareas priorizadas, listas para comenzar |
| **In Progress** | Tareas en desarrollo activo |
| **In Review / Testing** | Tareas terminadas, en verificación o prueba |
| **Done** | Tareas completadas y verificadas |

> ⚠️ El enunciado exige estas **cinco** columnas (no solo To Do / Doing / Done).
> La rúbrica (criterio 4, 15 pts) evalúa tarjetas desglosadas con criterios de
> aceptación y flujo continuo de commits atómicos.

## Cómo activar el tablero en GitHub Projects

1. Ir a **github.com → pestaña Projects del perfil → New project → Board**.
2. Nombrarlo, por ejemplo: `Parcial 1 — Simulador CPU von Neumann`.
3. Renombrar/crear las columnas: `Backlog`, `To Do`, `In Progress`, `In Review / Testing`, `Done`.
4. En el tablero: **⋯ → Settings → Manage access** (verificar visibilidad) y luego
   **Add item → Add from repository** → seleccionar este repositorio → agregar los
   issues #1 a #19.
5. Opcional: en **Workflows** del Project activar *Item added to project → To Do*
   y *Item closed → Done* para que las tarjetas se muevan automáticamente al
   cerrar cada issue.
6. Vincular el Project al repositorio: pestaña **Projects** del repo → **Link a project**.

## Tarjetas del proyecto (issues #1–#19)

| # | Tarjeta | Área |
|---|---|---|
| 1 | Elegir plataforma y definir estructura modular del proyecto | setup |
| 2 | Implementar matriz de memoria RAM de 256 bytes (16×16) | memoria |
| 3 | Crear subrutinas primitivas Read(address) y Write(address, value) | memoria |
| 4 | Implementar registros visibles del CPU: PC, IR, MAR, MDR, AX, BX | cpu-registros |
| 5 | Implementar registro de estado: banderas ZF, CF y SF | cpu-registros |
| 6 | Desarrollar módulo ALU (ADD, SUB, INC, DEC, AND, OR, XOR, NOT, CMP) | alu |
| 7 | Definir la ISA: tabla de opcodes y codificación en bytes | isa |
| 8 | Implementar fase Fetch del ciclo de instrucción | ciclo-instruccion |
| 9 | Implementar fase Decode (Unidad de Control) | ciclo-instruccion |
| 10 | Implementar fase Execute (ALU, saltos y banderas) | ciclo-instruccion |
| 11 | Implementar fase Store / Write-back | ciclo-instruccion |
| 12 | Implementar cargador de programa (LOAD PROGRAM) | isa / interfaz |
| 13 | Modo Paso a Paso (STEP) con resaltado visual | interfaz |
| 14 | Modo Continuo (RUN) con velocidad ajustable y PAUSE | interfaz |
| 15 | Botón RESET y panel de controles esenciales | interfaz |
| 16 | Log cronológico de micro-operaciones | interfaz |
| 17 | Programa demostrativo con bucles y bifurcaciones + traza | isa |
| 18 | README.md técnico (Mermaid, tabla ISA, manual, análisis) | documentation |
| 19 | Preparar defensa oral (15 minutos) y ensayo de demo en vivo | defensa |

Orden sugerido de desarrollo: 1 → 2 → 3 → 7 → 4 → 5 → 6 → 8 → 9 → 10 → 11 → 12 →
13 → 14 → 15 → 16 → 17 → 18 → 19 (la documentación #18 conviene avanzarla en
paralelo desde el inicio).

## Reglas de trabajo (del enunciado)

- **Milestone:** entrega improrrogable el **domingo 29 de septiembre, 23:59 hrs**.
  Ningún commit ni movimiento de tarjetas después de esa hora (auditoría del log).
- **Commits semánticos y atómicos:** `feat:`, `fix:`, `docs:`, `refactor:` —
  penalizado el commit masivo único de último momento.
- **Entrega:** solo los dos enlaces (repositorio + GitHub Project) en la
  plataforma académica; sin `.zip` ni libros de cálculo directos.
- Cada tarjeta se mueve a **Done** únicamente cuando todos sus criterios de
  aceptación están marcados.
