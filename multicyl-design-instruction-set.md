# Multicyl Design Instruction Set

## Scope

This note lists **what the shared ALU computes for six instruction examples** in the planned multicycle RISC-V processor. The ALU is combinational: the control unit selects its two inputs and operation during the appropriate cycle. **A separate incrementer computes `PC + 4`; the ALU does not do that job.** The ALU **does** compute the branch target for `BEQ` using `PC + branch immediate`.

## ALU operations by instruction

| Instruction | Example | ALU input A | ALU input B | ALU operation | ALU output |
|---|---|---|---|---|---|
| `ADD` | `add a3, a1, a2` | `rs1` | `rs2` | ADD | `rs1 + rs2` |
| `SUB` | `sub a3, a1, a2` | `rs1` | `rs2` | SUB | `rs1 - rs2` |
| `ADDI` | `addi a3, a1, 0x15` | `rs1` | Immediate | ADD | `rs1 + imm` |
| `LW` | `lw a1, 4(a4)` | `rs1` (base address) | Immediate | ADD | Effective address: `rs1 + imm` |
| `SW` | `sw a1, 4(a4)` | `rs1` (base address) | Immediate | ADD | Effective address: `rs1 + imm` |
| `BEQ` | `beq a1, a2, target` | PC | Branch immediate | ADD | Branch target: `PC + branch_imm` |

> **Syntax:** RISC-V uses `addi rd, rs1, imm`, not `add rd, rs1, imm`. For `sw rs2, imm(rs1)`, `rs1` supplies the base address and `rs2` supplies the data to store.

## ALU control during the relevant cycle

The selector meanings in these notes are:

- `i_A_Sel = 0`: `rs1`; `i_A_Sel = 1`: PC.
- `i_B_Sel = 0`: `rs2`; `i_B_Sel = 1`: immediate.
- ALU operation `3'b000`: ADD; `3'b001`: SUB (as encoded in the earlier design notes).

| Instruction | `i_A_Sel` | `i_B_Sel` | ALU operation selection |
|---|---:|---:|---|
| `ADD` | `0` (rs1) | `0` (rs2) | `3'b000` ADD |
| `SUB` | `0` (rs1) | `0` (rs2) | `3'b001` SUB |
| `ADDI` | `0` (rs1) | `1` (immediate) | `3'b000` ADD |
| `LW` | `0` (rs1) | `1` (immediate) | `3'b000` ADD |
| `SW` | `0` (rs1) | `1` (immediate) | `3'b000` ADD |
| `BEQ` | `1` (PC) | `1` (branch immediate) | `3'b000` ADD |

*Match the exact signal capitalization and operation constant names to your RTL when wiring the control unit.*

## Multicycle rule: what happens in one cycle?

- **Only one selected ALU computation is used at a time.** The ALU's inputs and operation are controlled by the FSM for the current cycle.
- `ADD`, `SUB`, `ADDI`: compute the arithmetic result in the designated execute cycle. Register write-back is a separate processor action.
- `LW`, `SW`: compute `rs1 + immediate` to produce an effective memory address in the address-calculation cycle. The LSU/memory handles the subsequent load or store; the ALU does not access memory itself.
- `BEQ`: compute `PC + branch immediate` to produce the branch target. A **separate branch comparator** checks `rs1 == rs2`; PC-selection logic uses the target only if the branch is taken. The precise FSM cycle in which comparison and target calculation occur depends on the implementation.
- **Sequential PC increment (`PC + 4`) uses a separate incrementer, not the ALU.**

## BEQ example

If the branch instruction's PC is `0x00400000` and its decoded branch immediate is `0x24`:

```text
ALU input A = PC                 = 0x00400000
ALU input B = branch immediate   = 0x00000024
ALU operation = ADD
ALU output = branch target       = 0x00400024
```

The comparator independently checks whether the two source registers are equal. If equal, the PC-update logic selects `0x00400024`; otherwise, execution follows the sequential PC path.

## RTL alignment note

The ALU's PC input/multiplexer is **required for `BEQ` target calculation** in this architecture. Do not remove it. The separate `PC + 4` incrementer remains outside the ALU. The ALU may implement other operations (such as AND, OR and XOR), but they are outside the six instruction examples covered here. This note documents ALU requirements, not proof that the entire CPU already executes every instruction.
