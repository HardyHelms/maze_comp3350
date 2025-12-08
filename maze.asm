.data
mdArray:	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

arrSize:	.word 15

NEW_LINE: 	.asciiz "\n"

# GAME STATE VARIABLES
coinsCollected: .word 0     # Track how many coins user has
wallColor:      .word 0x000000FF  # Default wall color (BLUE)

# CONSTANTS
.eqv	DATA_SIZE     4
.eqv	ARRSIZE		15
.eqv 	SCREEN_WIDTH	64
.eqv 	SCREEN_HEIGHT 	64
.eqv	PIXEL_WIDTH	16
.eqv	PIXEL_HEIGHT	16

# Locations
.eqv	MAZE_START_X	1
.eqv	MAZE_START_Y	0
.eqv	MAZE_GOAL_X	13
.eqv	MAZE_GOAL_Y	14
.eqv	START_X	0
.eqv	START_Y 0

# Colors
.eqv	RED 	    0x00FF0000
.eqv	GREEN 	    0x0000FF00
.eqv	BLUE 	    0x000000FF
.eqv	WHITE 	    0x00FFFFFF
.eqv	YELLOW 	    0x00FFFF00
.eqv	CYAN 	    0x0000FFFF
.eqv	MAGENTA     0x00FF00FF
.eqv	L_GRAY	    0x00D3D3D3
.eqv    NEON_ORANGE 0x00FF5F1F  

# Map Values
# 0 = Path, 1 = Wall
.eqv TRAP_VAL   	2
.eqv HIT_TRAP_VAL	3
.eqv NUM_TRAPS  	3

.eqv COIN_VAL       4
.eqv NUM_COINS      3

.eqv GATE_VAL       5   

.text
main:
	# set up starting position
	addi 	$a0, $0, START_X    	# a0 = X = zero index
	sra 	$a0, $a0, 1
	addi 	$a1, $0, START_Y   	# a1 = Y = zero index
	sra 	$a1, $a1, 1
	addi 	$a2, $0, WHITE  	# a2 = color
	
loop1:
	beq	$a0, PIXEL_WIDTH, check_Y
	beq	$a1, PIXEL_HEIGHT, next
	jal	draw_pixel
	addi	$a0, $a0, 1
	j	loop1


check_Y:
	beq	$a1, PIXEL_HEIGHT, next
	move	$a0, $zero
	addi	$a1, $a1, 1
	j	loop1
	
next:
	li	$s0, 0
	li	$s1, 250
	
loop2:
	addi	$s0, $s0, 1
	beq	$s0, $s1, maze_process
	j	loop2
	
maze_process:
	# 1. Generate Outer Walls
	la	$a0, mdArray
	lw	$a1, arrSize
	jal	generate_maze_outer_moat

	# 2. Generate Maze Streets & Locked Gate
	la	$a0, mdArray
	lw	$a1, arrSize
	jal	generate_maze_street

	# 3. Place Hidden Traps
	la	$a0, mdArray
	lw	$a1, arrSize
	jal	place_traps

    # 4. Place Neon Coins
	la	$a0, mdArray
	lw	$a1, arrSize
	jal	place_coins

	# 5. Draw Everything
	la	$a0, mdArray
	lw	$a1, arrSize
	jal	draw_maze

	# 6. Start Game Loop
	j	user_location

exit:
	li	$v0, 10
	syscall



# subroutine to draw a pixel
# $a0 = X, $a1 = Y, $a2 = color
draw_pixel:
	mul	$t9, $a1, PIXEL_WIDTH   # y * WIDTH
	add	$t9, $t9, $a0	  # add X
	mul	$t9, $t9, 4	  # word offset
	add	$t9, $t9, $gp	  # base address
	sw	$a2, ($t9)	  # store color
	jr 	$ra
	


# draw_maze 
# Draws the map based on mdArray values
draw_maze:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li	$s0, 0			# return value
	li	$t0, 0			# i
	li	$t1, 0			# j

    # Load dynamic wall color
    lw      $t8, wallColor

draw_Loop1:
	blt	$t1, $a1, draw_Loop2
	move	$v0, $s0
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
draw_Loop2:
	mul	$t2, $t1, $a1		# t1 = rowIndex * colSize
	add	$t2, $t2, $t0		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	lw	$t3, 0($t2)

	move	$t5, $a0
	move	$t6, $a1
	
	# Logic Checks
	beq	$t3, $zero, skip        # 0 = path

	li	$t7, 1
	beq	$t3, $t7, draw_wall     # 1 = wall

	li	$t7, HIT_TRAP_VAL
	beq	$t3, $t7, draw_hit_trap # 3 = hit trap

    li  $t7, COIN_VAL
    beq $t3, $t7, draw_coin     # 4 = coin

    li  $t7, GATE_VAL
    beq $t3, $t7, draw_gate     # 5 = locked gate

	# 2 (hidden trap) => invisible
	j	skip

	draw_wall:
		add 	$a0, $0, $t0
		add 	$a1, $0, $t1
		move  	$a2, $t8        # Dynamic Color
		jal	draw_pixel
		j	skip

    draw_coin:
		add 	$a0, $0, $t0
		add 	$a1, $0, $t1
		li  	$a2, NEON_ORANGE 
		jal	draw_pixel
		j	skip

    draw_gate:
		add 	$a0, $0, $t0
		add 	$a1, $0, $t1
		li  	$a2, MAGENTA    # Locked Gate is Magenta
		jal	draw_pixel
		j	skip

	draw_hit_trap:
		add 	$a0, $0, $t0
		add 	$a1, $0, $t1
		li  	$a2, L_GRAY
		jal	draw_pixel
		j	skip
							
skip:											
	move	$a0, $t5
	move	$a1, $t6
	addi	$t0, $t0, 1
	blt	$t0, $a1, draw_Loop2
	addi	$t1, $t1, 1
	move	$t0, $zero
	move	$t5, $a0
	li	$v0, 4
	la	$a0, NEW_LINE
	syscall
	move	$a0, $t5
	j	draw_Loop1
		


# Generate maze outer moat
generate_maze_outer_moat:
# top/buttom outer moat
top_btm:
	li	$t0, 0		# index x = 0
	li	$s0, 0		# top y 
	li	$s1, 14		# btm y
	li	$t4, 1
t_b_loop: 				# for(x=0; x<max_x; x++)
	# top
	mul	$t2, $s0, $a1
	add	$t2, $t2, $t0
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	sw	$t4, 0($t2)
	# bottom
	mul	$t2, $s1, $a1
	add	$t2, $t2, $t0
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	sw	$t4, 0($t2)
	addi	$t0, $t0, 1
	bne	$t0, $a1, t_b_loop
# left/right outer moat
left_right:
	move	$t0, $zero
l_r_loop:
	# left
	mul	$t2, $t0, $a1
	add	$t2, $t2, $s0
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	sw	$t4, 0($t2)
	# right
	mul	$t2, $t0, $a1
	add	$t2, $t2, $s1
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	sw	$t4, 0($t2)
	addi	$t0, $t0, 1
	bne	$t0, $a1, l_r_loop
	jr	$ra



# Generate maze street
generate_maze_street:
	li	$t0, 2
	li	$t1, 2
	li	$s0, 14
	li	$s1, 1
	li	$s3, 3
	li	$s4, 6
	li	$s5, 9
	
maze_st_loop1:
	beq	$t0, $s0, check_x_location
	j	maze_st_loop2
	
check_x_location:
	beq	$t1, $s0, end_maze_st_loop

maze_st_loop2:
	# Drop a prop for the wall
	mul	$t2, $t0, $a1
	add	$t2, $t2, $t1
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	sw	$s1, 0($t2)
	
	# Generate random integer
	li	$t9, 0
	move	$t5, $a0
	move	$t6, $a1
	li	$v0, 42
	li 	$a1, 11
	syscall
	addi 	$t9, $a0, 1
	move	$a0, $t5
	move	$a1, $t6
	
	# Cases
	sle   	$t7, $t9, $s3
	bne	$t7, $zero, case1
	sle	$t7, $t9, $s4
	bne	$t7, $zero, case2
	sle	$t7, $t9, $s5
	bne	$t7, $zero, case3
	j	case4
	
case1:
	addi	$t0, $t0, -1
	mul	$t2, $t0, $a1
	add	$t2, $t2, $t1
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	lw	$t3, 0($t2)
	addi	$t0, $t0, 1
	bne	$t3, $zero, reverse_x_index_by_two
	sw	$s1, 0($t2)
	j	next_x_index

case2:
	addi	$t0, $t0, 1
	mul	$t2, $t0, $a1
	add	$t2, $t2, $t1
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	lw	$t3, 0($t2)
	addi	$t0, $t0, -1
	bne	$t3, $zero, reverse_x_index_by_two
	sw	$s1, 0($t2)
	j	next_x_index

case3:
	addi	$t1, $t1, -1
	mul	$t2, $t0, $a1
	add	$t2, $t2, $t1
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	lw	$t3, 0($t2)
	addi	$t1, $t1, 1
	bne	$t3, $zero, reverse_x_index_by_two
	sw	$s1, 0($t2)
	j	next_x_index

case4:
	addi	$t1, $t1, 1
	mul	$t2, $t0, $a1
	add	$t2, $t2, $t1
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	lw	$t3, 0($t2)
	addi	$t1, $t1, -1
	bne	$t3, $zero, reverse_x_index_by_two
	sw	$s1, 0($t2)
	j	next_x_index

reverse_x_index_by_two:
	addi	$t1, $t1, -2

next_x_index:
	addi	$t1, $t1, 2
	beq	$t1, $s0, check_y_location
	j	maze_st_loop2
	
check_y_location:
	addi	$t0, $t0, 2
	li	$t1, 2
	beq	$t0, $s0, end_maze_st_loop
	j	maze_st_loop1
	
end_maze_st_loop:
	# Set Start (Clear)
	li	$t1, MAZE_START_X
	li	$t0, MAZE_START_Y
	mul	$t2, $t0, $a1
	add	$t2, $t2, $t1
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	sw	$zero, 0($t2)
	
	# Set Goal to GATE_VAL (Locked Gate)
	li	$t1, MAZE_GOAL_X
	li	$t0, MAZE_GOAL_Y
	mul	$t2, $t0, $a1
	add	$t2, $t2, $t1
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $a0
	
	li  $t4, GATE_VAL   # Load Gate Value (5)
	sw	$t4, 0($t2)     # Store Gate
	
	jr	$ra
	

 
# Show Current location of the user
user_location:
	addi	$a0, $zero, 1		# start X
	addi	$a1, $zero, 0		# start Y
	addi 	$a2, $0, RED  		# color
	lw	$s6, arrSize
	la	$s7, mdArray

loop_user_location:
	jal 	draw_pixel
	
	# check input
	lw $t0, 0xffff0000
    beq $t0, 0, loop_user_location
	
	# process input
	lw 	$s1, 0xffff0004
	
	beq	$s1, 32, exit	

    # Color Change Keys
    beq $s1, 49, set_color_blue  # '1'
    beq $s1, 50, set_color_green # '2'
    beq $s1, 51, set_color_cyan  # '3'

    # Movement
	beq	$s1, 119, up 	# w
	beq	$s1, 115, down 	# s
	beq	$s1, 97, left  	# a
	beq	$s1, 100, right	# d
    
	j	loop_user_location

# Color Change Handlers
set_color_blue:
    li      $t0, BLUE
    sw      $t0, wallColor
    j       refresh_map
set_color_green:
    li      $t0, GREEN
    sw      $t0, wallColor
    j       refresh_map
set_color_cyan:
    li      $t0, CYAN
    sw      $t0, wallColor
    j       refresh_map

refresh_map:
    move    $s4, $a0        # Save Player X/Y
    move    $s5, $a1
    la      $a0, mdArray
    lw      $a1, arrSize
    jal     draw_maze
    move    $a0, $s4        # Restore Player
    move    $a1, $s5
    li      $a2, RED
    jal     draw_pixel
    j       loop_user_location

# MOVEMENT LOGIC
up:
	beq	$a1, $zero, skip_move_up
	addi	$t4, $a1, -1

	# get mdArray[x][y-1]
	mul	$t2, $t4, $s6
	add	$t2, $t2, $a0
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $s7
	lw	$t3, 0($t2)

	li	$t7, 1
	beq	$t3, $t7, skip_move_up    # Wall collision

    li  $t7, GATE_VAL
    beq $t3, $t7, skip_move_up    # Locked Gate collision

    li  $t7, COIN_VAL
    beq $t3, $t7, collect_coin_up

	li	$t7, TRAP_VAL
	bne	$t3, $t7, not_trap_up

	# trap hit
	move	$s2, $a0
	move	$s3, $t4
	j	trap_trigger

collect_coin_up:
    lw      $t8, coinsCollected
    addi    $t8, $t8, 1
    sw      $t8, coinsCollected
    sw      $zero, 0($t2)   # clear coin
    jal     check_unlock_gate
    j       not_trap_up

not_trap_up:
	li	$t7, HIT_TRAP_VAL
	beq	$t3, $t7, do_move_up
	bne	$t3, $zero, skip_move_up

do_move_up:
	li	$a2, 0
	jal	draw_pixel
	addi	$a1, $a1, -1
	addi 	$a2, $0, RED
	jal	draw_pixel

skip_move_up:
	j	loop_user_location

	
down:
	addi	$t4, $a1, 1
	li	$t5, MAZE_GOAL_X
	li	$t6, MAZE_GOAL_Y

	mul	$t2, $t4, $s6
	add	$t2, $t2, $a0
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $s7
	lw	$t3, 0($t2)

	li	$t7, 1
	beq	$t3, $t7, skip_move_down

    li  $t7, GATE_VAL
    beq $t3, $t7, skip_move_down

    li  $t7, COIN_VAL
    beq $t3, $t7, collect_coin_down
    
	li	$t7, TRAP_VAL
	bne	$t3, $t7, not_trap_down

	move	$s2, $a0
	move	$s3, $t4
	j	trap_trigger

collect_coin_down:
    lw      $t8, coinsCollected
    addi    $t8, $t8, 1
    sw      $t8, coinsCollected
    sw      $zero, 0($t2)
    jal     check_unlock_gate
    j       not_trap_down

not_trap_down:
	li	$t7, HIT_TRAP_VAL
	beq	$t3, $t7, do_move_down
	bne	$t3, $zero, skip_move_down

do_move_down:
	li	$a2, 0
	jal	draw_pixel
	addi	$a1, $a1, 1
	addi 	$a2, $0, RED
	jal	draw_pixel

	# Check If User Reached Goal
	bne	$a0, $t5, skip_move_down
	bne	$a1, $t6, skip_move_down
	j	goal_reached

skip_move_down:
	j	loop_user_location

	
left:
	addi	$t4, $a0, -1

	mul	$t2, $a1, $s6
	add	$t2, $t2, $t4
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $s7
	lw	$t3, 0($t2)

	li	$t7, 1
	beq	$t3, $t7, skip_move_left

    li  $t7, GATE_VAL
    beq $t3, $t7, skip_move_left

    li  $t7, COIN_VAL
    beq $t3, $t7, collect_coin_left

	li	$t7, TRAP_VAL
	bne	$t3, $t7, not_trap_left

	move	$s2, $t4
	move	$s3, $a1
	j	trap_trigger

collect_coin_left:
    lw      $t8, coinsCollected
    addi    $t8, $t8, 1
    sw      $t8, coinsCollected
    sw      $zero, 0($t2)
    jal     check_unlock_gate
    j       not_trap_left

not_trap_left:
	li	$t7, HIT_TRAP_VAL
	beq	$t3, $t7, do_move_left
	bne	$t3, $zero, skip_move_left

do_move_left:
	li	$a2, 0
	jal	draw_pixel
	addi	$a0, $a0, -1
	addi 	$a2, $0, RED
	jal	draw_pixel

skip_move_left:
	j	loop_user_location

	
right:
	addi	$t4, $a0, 1

	mul	$t2, $a1, $s6
	add	$t2, $t2, $t4
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $s7
	lw	$t3, 0($t2)

	li	$t7, 1
	beq	$t3, $t7, skip_move_right

    li  $t7, GATE_VAL
    beq $t3, $t7, skip_move_right

    li  $t7, COIN_VAL
    beq $t3, $t7, collect_coin_right

	li	$t7, TRAP_VAL
	bne	$t3, $t7, not_trap_right

	move	$s2, $t4
	move	$s3, $a1
	j	trap_trigger

collect_coin_right:
    lw      $t8, coinsCollected
    addi    $t8, $t8, 1
    sw      $t8, coinsCollected
    sw      $zero, 0($t2)
    jal     check_unlock_gate
    j       not_trap_right

not_trap_right:
	li	$t7, HIT_TRAP_VAL
	beq	$t3, $t7, do_move_right
	bne	$t3, $zero, skip_move_right

do_move_right:
	li	$a2, 0
	jal	draw_pixel
	addi	$a0, $a0, 1
	addi 	$a2, $0, RED
	jal	draw_pixel

skip_move_right:
	j	loop_user_location



# Helper: Check if all coins collected to open gate
check_unlock_gate:
    lw      $t8, coinsCollected
    li      $t9, NUM_COINS
    bne     $t8, $t9, skip_unlock

    # Unlock the Gate!
    # Goal location address
    li      $t0, MAZE_GOAL_X
    li      $t1, MAZE_GOAL_Y
    lw      $t6, arrSize
    
    mul     $t2, $t1, $t6       # y * width
    add     $t2, $t2, $t0       # + x
    mul     $t2, $t2, 4
    la      $t5, mdArray
    add     $t2, $t2, $t5
    
    sw      $zero, 0($t2)       # Store 0 (Path) to clear gate

    # Visually clear the gate (draw black)
    
    addi    $sp, $sp, -12       # Make room for $ra, $a0, $a1
    sw      $ra, 0($sp)
    sw      $a0, 4($sp)         # Save Player X
    sw      $a1, 8($sp)         # Save Player Y
    
    move    $a0, $t0            # Set Gate X
    move    $a1, $t1            # Set Gate Y
    li      $a2, 0              # Black
    jal     draw_pixel
    
    lw      $ra, 0($sp)
    lw      $a0, 4($sp)         # Restore Player X
    lw      $a1, 8($sp)         # Restore Player Y
    addi    $sp, $sp, 12

skip_unlock:
    jr      $ra


goal_reached:
	# Show message
	li	$a0, 0	# x
	li	$a1, 0	# y
	addi 	$a2, $0, YELLOW
	li	$s0, 256
	j	loop_board2
	

# place_traps
place_traps:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t8, 0

trap_loop:
    move $t5, $a0
    move $t6, $a1

    li   $v0, 42
    addi $a1, $t6, -2
    syscall
    addi $t0, $a0, 1

    li   $v0, 42
    addi $a1, $t6, -2
    syscall
    addi $t1, $a0, 1

    move $a0, $t5
    move $a1, $t6

    # avoid start
    li   $t2, MAZE_START_X
    bne  $t0, $t2, check_goal_trap
    li   $t2, MAZE_START_Y
    beq  $t1, $t2, trap_loop

check_goal_trap:
    # avoid goal (Note: Goal is now Gate=5, so it's not 0 anyway)
    li   $t2, MAZE_GOAL_X
    bne  $t0, $t2, check_cell_trap
    li   $t2, MAZE_GOAL_Y
    beq  $t1, $t2, trap_loop

check_cell_trap:
    mul  $t2, $t1, $a1
    add  $t2, $t2, $t0
    mul  $t2, $t2, DATA_SIZE
    add  $t2, $t2, $a0

    lw   $t3, 0($t2)
    bne  $t3, $zero, trap_loop   # only place on empty path

    li   $t4, TRAP_VAL
    sw   $t4, 0($t2)

    addi $t8, $t8, 1
    li   $t7, NUM_TRAPS
    blt  $t8, $t7, trap_loop

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra



# place_coins
place_coins:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t8, 0

coin_loop_p:
    move $t5, $a0
    move $t6, $a1

    li   $v0, 42
    addi $a1, $t6, -2
    syscall
    addi $t0, $a0, 1

    li   $v0, 42
    addi $a1, $t6, -2
    syscall
    addi $t1, $a0, 1

    move $a0, $t5
    move $a1, $t6

    # avoid start
    li   $t2, MAZE_START_X
    bne  $t0, $t2, check_goal_coin_p
    li   $t2, MAZE_START_Y
    beq  $t1, $t2, coin_loop_p

check_goal_coin_p:
    # avoid goal
    li   $t2, MAZE_GOAL_X
    bne  $t0, $t2, check_cell_coin_p
    li   $t2, MAZE_GOAL_Y
    beq  $t1, $t2, coin_loop_p

check_cell_coin_p:
    mul  $t2, $t1, $a1
    add  $t2, $t2, $t0
    mul  $t2, $t2, DATA_SIZE
    add  $t2, $t2, $a0

    lw   $t3, 0($t2)
    bne  $t3, $zero, coin_loop_p   # only place on path

    li   $t4, COIN_VAL
    sw   $t4, 0($t2)

    addi $t8, $t8, 1
    li   $t7, NUM_COINS
    blt  $t8, $t7, coin_loop_p

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra



# clear_screen
clear_screen:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $a1, 0
cs_y:
    li   $a0, 0
cs_x:
    jal  draw_pixel
    addi $a0, $a0, 1
    blt  $a0, PIXEL_WIDTH, cs_x

    addi $a1, $a1, 1
    blt  $a1, PIXEL_HEIGHT, cs_y

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra



# crude busy-wait delay
delay_3s:
    li $t0, 0
    li $t1, 1000000     
d3_loop:
    addi $t0, $t0, 1
    blt  $t0, $t1, d3_loop
    jr   $ra



# Helpers for letters
draw_hline:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    move $t0, $a0
hloop:
    move $a0, $t0
    jal  draw_pixel
    addi $t0, $t0, 1
    ble  $t0, $a3, hloop
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

draw_vline:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    move $t1, $a1
vloop:
    move $a1, $t1
    jal  draw_pixel
    addi $t1, $t1, 1
    ble  $t1, $a3, vloop
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra



# trap_trigger
trap_trigger:
    # Mark trap as used
    mul  $t2, $s3, $s6
    add  $t2, $t2, $s2
    mul  $t2, $t2, DATA_SIZE
    add  $t2, $t2, $s7
    li   $t4, HIT_TRAP_VAL
    sw   $t4, 0($t2)

    # TRAP ANIMATION
    li  $a2, RED
    jal clear_screen
    li  $a2, RED
    jal clear_screen
    li  $a2, WHITE

    # T
    li $a0, 1
    li $a1, 4
    li $a3, 3
    jal draw_hline
    li $a0, 2
    li $a1, 4
    li $a3, 8
    jal draw_vline
    # R
    li $a0, 5
    li $a1, 4
    li $a3, 8
    jal draw_vline
    li $a0, 5
    li $a1, 4
    li $a3, 7
    jal draw_hline
    li $a0, 5
    li $a1, 6
    li $a3, 7
    jal draw_hline
    li $a0, 7
    li $a1, 4
    li $a3, 6
    jal draw_vline
    li $a0, 6
    li $a1, 7
    jal draw_pixel
    li $a0, 7
    li $a1, 8
    jal draw_pixel
    # A
    li $a0, 9
    li $a1, 5
    li $a3, 8
    jal draw_vline
    li $a0, 11
    li $a1, 5
    li $a3, 8
    jal draw_vline
    li $a0, 9
    li $a1, 4
    li $a3, 11
    jal draw_hline
    li $a0, 9
    li $a1, 6
    li $a3, 11
    jal draw_hline
    # P
    li $a0, 13
    li $a1, 4
    li $a3, 8
    jal draw_vline
    li $a0, 13
    li $a1, 4
    li $a3, 15
    jal draw_hline
    li $a0, 13
    li $a1, 6
    li $a3, 15
    jal draw_hline
    li $a0, 15
    li $a1, 4
    li $a3, 6
    jal draw_vline

    jal delay_3s

    # Restore Map
    li  $a2, WHITE
    jal clear_screen
    la  $a0, mdArray
    lw  $a1, arrSize
    jal draw_maze

    # Reset Player
    li  $a0, MAZE_START_X
    li  $a1, MAZE_START_Y
    li  $a2, RED
    jal draw_pixel

    j loop_user_location


loop_board2:
	jal	draw_pixel
	addi	$a0, $a0, 1
	beq	$a0, $s0, completed_board
	j	loop_board2

completed_board:
	# G
	li	$a0, 1
	li	$a1, 2
	addi 	$a2, $0, RED
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	li	$a0, 1
	
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel

	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	
	addi	$a1, $a1, -1
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	
	addi	$a0, $a0, -1
	jal	draw_pixel
	
	# O
	li	$a0, 8
	li	$a1, 2
	
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	
	addi	$a1, $a1, -1
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	
	addi	$a0, $a0, -1
	jal	draw_pixel
	addi	$a0, $a0, -1
	jal	draw_pixel
	addi	$a0, $a0, -1
	jal	draw_pixel
	
	# A
	li	$a0, 1
	li	$a1, 10
	
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	
	addi	$a0, $a0, 3
	
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	addi	$a1, $a1, -1
	jal	draw_pixel
	
	addi	$a0, $a0, -1
	jal	draw_pixel
	addi	$a0, $a0, -1
	jal	draw_pixel
	addi	$a0, $a0, -1
	jal	draw_pixel
	
	addi	$a1, $a1, 2
	
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	
	# L
	li	$a0, 8
	li	$a1, 10
	
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	
	# !
	li	$a0, 14
	li	$a1, 10
	
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 2
	jal	draw_pixel
	
	j	exit