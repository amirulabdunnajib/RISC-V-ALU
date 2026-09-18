# Multicyl Design Instruction Set

## Scope

This note lists the **ALU work required by the six instruction examples** in the planned multicycle RISC-V processor. **The ALU is not used for PC operations** in this design: PC increment and branch-target calculation belong to separate hardware. The ALU is combinational; the controller selects its inputs and operation for the relevant cycle.

## ALU operations by instruction

| Instruction | Example | ALU input A | ALU input B | ALU operation | ALU output |
|---|---|---|---|---|---|
| `ADD` | `add a3, a1, a2` | `rs1` | `rs2` | ADD | `rs1 + rs2` |
| `SUB` | `sub a3, a1, a2` | `rs1` | `rs2` | SUB | `rs1 - rs2` |
| `ADDI` | `addi a3, a1, 0x15` | `rs1` | Immediate | ADD | `rs1 + imm` |
| `LW` | `lw a1, 4(a4)` | `rs1` (base address) | Immediate | ADD | Effective memory address: `rs1 + imm` |
| `SW` | `sw a1, 4(a4)` | `rs1` (base address) | Immediate | ADD | Effective memory address: `rs1 + imm` |
| `BEQ` | `beq a1, a2, target` | — | — | **None for this ALU** | Equality check uses a separate branch comparator; branch target uses separate PC/branch hardware. |

> **Syntax:** RISC-V uses `addi rd, rs1, imm`, not `add rd, rs1, imm`. For stores, `sw rs2, imm(rs1)` uses `rs1` as the address base and `rs2` as the data to store.

## ALU control for the arithmetic and address-calculation cycle

| Instruction | `i_A_Sel` | `i_B_sel` | `i_ALU_OP` |
|---|---:|---:|---|
| `ADD` | `0` (`rs1`) | `0` (`rs2`) | `3'b000` ADD |
| `SUB` | `0` (`rs1`) | `0` (`rs2`) | `3'b001` SUB |
| `ADDI` | `0` (`rs1`) | `1` (immediate) | `3'b000` ADD |
| `LW` | `0` (`rs1`) | `1` (immediate) | `3'b000` ADD |
| `SW` | `0` (`rs1`) | `1` (immediate) | `3'b000` ADD |
| `BEQ` | — | — | — |

## Multicycle rule

- **One ALU operation is selected at a time.** For `ADD`, `SUB`, and `ADDI`, the ALU computes the arithmetic result during the designated execute cycle.
- For `LW` and `SW`, the ALU computes the effective address during the address-calculation cycle. The memory access takes place separately; the ALU does not read or write memory.
- `BEQ` equality comparison and target calculation use separate hardware in this planned design; they do not require an ALU operation.
- PC update (`PC + 4`) also uses separate hardware, **not this ALU**.

## RTL alignment note

The supplied ALU RTL currently includes a mux that can select `I_pc_output` when `i_A_Sel = 1`. **That is an existing RTL capability, not a requirement of the intended processor architecture described here.** To keep the ALU independent of PC operations, drive `i_A_Sel = 0` for the listed ALU instructions, and implement PC increment/branch-target generation separately. Removing the unused PC input/mux is an optional RTL cleanup after checking the top-level connections.

The RTL ALU also implements AND, OR, and XOR, but those instructions are outside the six examples documented here. This table specifies the ALU's role, not proof that the complete CPU already implements all six instructions.
