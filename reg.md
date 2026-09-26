In x86 assembly (32-bit x86 and 64-bit x86-64), registers are divided into general-purpose roles and strict calling convention responsibilities.

### 1. Register Sizes & Naming Structure

Registers overlap in memory. Modifying a lower portion alters the containing register:

| 64-bit (x86-64) | 32-bit (x86) | 16-bit | 8-bit (Low / High) | Primary Purpose / Historical Role |
| --- | --- | --- | --- | --- |
| **RAX** | EAX | AX | AL / AH | Accumulator, function return values |
| **RBX** | EBX | BX | BL / BH | Base index, general storage (preserved) |
| **RCX** | ECX | CX | CL / CH | Counter for loops and bit shifts |
| **RDX** | EDX | DX | DL / DH | Data, I/O, secondary return value |
| **RSI** | ESI | SI | SIL / — | Source index for string operations |
| **RDI** | EDI | DI | DIL / — | Destination index for string operations |
| **RBP** | EBP | BP | BPL / — | Base pointer (stack frame anchor) |
| **RSP** | ESP | SP | SPL / — | Stack pointer (points to current stack top) |
| **R8 – R15** | R8D – R15D | R8W – R15W | R8B – R15B | Additional general registers (x86-64 only) |


In 16-bit x86 assembly (Real Mode)—which is what custom OS boots start in before entering Protected or Long Mode—registers are 16 bits wide and rely heavily on **Segmented Memory Architecture**.

---

### 1. The 16-Bit Registers & Their Names

The 16-bit register names are the original forms before `E` (32-bit Extended) and `R` (64-bit Register) were added:

* **`AX` (Accumulator):** Primary register for arithmetic, math operations, and I/O port interactions.
* **`BX` (Base):** Used as a base pointer for holding memory addresses.
* **`CX` (Count):** Used as a loop counter (e.g., `loop` instruction, `rep` string instructions).
* **`DX` (Data):** Used in multiplication/division and holding I/O port addresses.
* **`SI` (Source Index):** Points to the source offset memory address for string/memory copying instructions.
* **`DI` (Destination Index):** Points to the destination offset memory address for string/memory operations.
* **`BP` (Base Pointer):** Points to data on the stack (stack frame anchor).
* **`SP` (Stack Pointer):** Points to the top of the stack.

---

### 2. Segment Registers (`DS`, `CS`, `SS`, `ES`)

In 16-bit Real Mode, a single 16-bit register can only address up to $2^{16} = 64\text{ KB}$ of memory. To reach up to 1 MB ($2^{20}$ bytes) of RAM, x86 uses **Segment Registers**:

* **`CS` (Code Segment):** Points to the code segment (paired with `IP` - Instruction Pointer).
* **`DS` (Data Segment):** Points to the default segment for general data/variables.
* **`SS` (Stack Segment):** Points to the stack segment (paired with `SP`).
* **`ES` (Extra Segment):** An extra data segment, often used with `DI` for string operations.

---

### 3. What does `DS:SI` mean?

`DS:SI` represents a **Segment:Offset** address pair.

In Real Mode, memory addresses are written in the format `Segment:Offset`. The CPU calculates the **actual physical memory address** using this formula:

$$\text{Physical Address} = (\text{Segment} \times 16) + \text{Offset}$$

* **`DS`** holds the segment base address (shifted left by 4 bits / multiplied by 16).
* **`SI`** holds the offset inside that segment.

#### Practical Example in OS Development

When writing a BIOS bootloader (loaded at physical address `0x7C00`), printing a string byte-by-byte using `lodsb` automatically reads from memory address **`DS:SI`**:

```nasm
mov ax, 0x0000
mov ds, ax          ; DS = 0x0000
mov si, 0x7C00      ; SI = 0x7C00 (Offset to string)

; Effective Physical Address = (0x0000 * 16) + 0x7C00 = 0x07C00

lodsb               ; Reads byte at [DS:SI], loads into AL, increments SI

```

Common standard pairs in 16-bit x86 include:

* **`CS:IP`** $\rightarrow$ Next instruction to execute
* **`SS:SP`** $\rightarrow$ Top of the stack
* **`DS:SI`** $\rightarrow$ Source string/data
* **`ES:DI`** $\rightarrow$ Destination string/data (e.g., writing directly to video memory at `0xB800:0x0000`)