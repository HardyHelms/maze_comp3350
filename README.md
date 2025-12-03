# MIPS Maze Game (using MARS Bitmap Display + MMIO)

A maze game written in **MIPS assembly** for the **MARS emulator**, using the **Bitmap Display** for graphics and **MMIO** for keyboard input.

## Features
- Renders a maze to the Bitmap Display
- Player movement via keyboard input (MMIO)
- Win condition when reaching the goal tile
- Extra mechanics: traps, coins, color swap

## Extra Mechanics in Detail
1. Traps:
   - Invisible squares will be randomly generated in the maze that, once hit, will display a "TRAP" screen and send the user back to the beginning of the maze
   - After the user is sent back, the traps will become visible, and the user will be able to pass over them freely
2. Coins:
   - Yellow squares will be randomly generated in the maze that, once hit, will disappear
   - Once all coins are collected (disappear), the exit gate will open
3. Color Swap:
   - Use number keys on the keyboard to change the color of the maze

## Requirements
- **MARS MIPS Simulator** (recommended: a recent MARS jar)
- Java (to run MARS)
- MARS tools:
  - **Bitmap Display**
  - **Keyboard and Display MMIO**

## Setup in MARS
1. Open MARS.
2. Load the program: `File → Open → maze.asm`
3. Enable tools:
   - `Tools → Bitmap Display`
   - `Tools → Keyboard and Display MMIO`
4. Configure Bitmap Display:
   - Unit width: `4`
   - Unit height: `4`
   - Display width (pixels): `64`
   - Display height (pixels): `64`
   - Base address: typically `0x10008000 ($gp)`
5. Click **Connect to MIPS** in both tools (Bitmap Display + MMIO).

## How to Run
1. Click **Assemble**.
2. Click **Run**.

## Controls
- `W/A/S/D`: user movement
- `1-3`: change maze color
- maze color code --> (1:blue, 2:green, 3:cyan)

## Game Rules
- Start at: start tile (automatically placed there when code runs)
- Goal: reach the exit opening at the other end of the maze
- Walls: impassable
- Collect `3` coins to unlock the exit
- Hidden traps reset you to start of maze and then mark the trap location

## Code Overview
- **Rendering**: writes 32-bit color values to the Bitmap Display memory-mapped buffer
- **Input**: reads keycodes from MMIO
- **Maze storage**: typically a 2D grid stored as a 1D array in `.data`
- **Main loop**: poll input → validate move → update player position → redraw tiles → check win

## File Layout
- `maze.asm` — main program

## Customization
These customizations are in the actual CODE, not while the game is running
- Colors (wall/player/goal)
- Number of coins / trap count

## Troubleshooting
- **Nothing appears in Bitmap Display**
  - Ensure Bitmap Display is connected to MIPS
  - Verify base address matches your code (often `0x10008000 ($gp)`)
  - Confirm display dimensions match `maze_width * tile_size` and `maze_height * tile_size`

- **Keyboard input not working**
  - Ensure MMIO tool is connected to MIPS
  - Click inside the MMIO window before pressing keys

- **Runtime exception: address out of range**
  - Usually means a bad pointer/index when writing pixels or accessing the maze array
  - Check bounds on row/col and computed addresses
