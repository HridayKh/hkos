# Real Mode (1 MB) Memory Map

| Address Range | Size | Description & Usage |
| --- | --- | --- |
| `0x00000` – `0x003FF` | 1 KB | IVT (Interrupt Vector Table) |
| `0x00400` – `0x004FF` | 256 B | BDA (BIOS Data Area) |
| | | |
| `0x00500` – `0x07BFF` | ~30 KB | Free RAM |
| `0x07C00` – `0x07DFF` | 512 B | Bootloader |
| `0x07E00` – `0x7FFFF` | ~480 KB | Free RAM |
| | | |
| `0x80000` – `0x9FFFF` | ~128 KB | EBDA (Extended BIOS Data Area) |
| `0xA0000` – `0xBFFFF` | 128 KB | Video RAM (VRAM) |
| `0xC0000` – `0xFFFFF` | 256 KB | BIOS ROMs |
