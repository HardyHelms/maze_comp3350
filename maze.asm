# maze

# array size 15 * 15
# index 0 ~ 14
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

# Each data size
.eqv	DATA_SIZE     4

.eqv	ARRSIZE		15

# screen size
.eqv 	SCREEN_WIDTH	64
.eqv 	SCREEN_HEIGHT 	64

# each dot is using 4 so 64/4 = 16
.eqv	PIXEL_WIDTH	16
.eqv	PIXEL_HEIGHT	16

# Maze start
.eqv	MAZE_START_X	1
.eqv	MAZE_START_Y	0

# Maze Goal
.eqv	MAZE_GOAL_X	13
.eqv	MAZE_GOAL_Y	14

# start
.eqv	START_X	0
.eqv	START_Y 0

# colors
.eqv	RED 	0x00FF0000
.eqv	GREEN 	0x0000FF00
.eqv	BLUE 	0x000000FF
.eqv	WHITE 	0x00FFFFFF
.eqv	YELLOW 	0x00FFFF00
.eqv	CYAN 	0x0000FFFF
.eqv	MAGENTA 0x00FF00FF
.eqv	L_GRAY	0x00D3D3D3

# traps
.eqv TRAP_VAL   	2
.eqv HIT_TRAP_VAL	3
.eqv NUM_TRAPS  	3


.text
main:
	# set up starting position
	addi 	$a0, $0, START_X    	# a0 = X = zero index
	sra 	$a0, $a0, 1
	addi 	$a1, $0, START_Y   	# a1 = Y = zero index
	sra 	$a1, $a1, 1
	addi 	$a2, $0, WHITE  	# a2 = color
	
loop1:
	beq	$a0, PIXEL_WIDTH, check_Y	# if x's location == 16, check if y is also 16
	beq	$a1, PIXEL_HEIGHT, next		# if only y at 16, reset x location and draw next
	jal	draw_pixel			#
	addi	$a0, $a0, 1			# x++
	j	loop1				# keep looping until x = 16


check_Y:
	beq	$a1, PIXEL_HEIGHT, next
	move	$a0, $zero
	addi	$a1, $a1, 1
	j	loop1
	
next:
	li	$s0, 0		# i = 0
	li	$s1, 250	# i < 250
	
loop2:
	addi	$s0, $s0, 1
	beq	$s0, $s1, maze_process
	j	loop2
	
maze_process:
	# TEST 1 #
	la	$a0, mdArray
	lw	$a1, arrSize
	jal	generate_maze_outer_moat

	# TEST 2 #
	la	$a0, mdArray
	lw	$a1, arrSize
	jal	generate_maze_street

	# NEW: place hidden traps on path cells
	la	$a0, mdArray
	lw	$a1, arrSize
	jal	place_traps

	# TEST 3 #
	la	$a0, mdArray
	lw	$a1, arrSize
	jal	draw_maze

	# TEST 4 #
	j	user_location

	

exit:
	#
	# move	$a0, $v0
	# li	$v0, 1
	# syscall
	li	$v0, 10
	syscall







#################################################
# subroutine to draw a pixel
# $a0 = X
# $a1 = Y
# $a2 = color
draw_pixel:
	# pixel address = $gp + 4*(x + y*width)
	mul	$t9, $a1, PIXEL_WIDTH   # y * WIDTH
	add	$t9, $t9, $a0	  # add X
	mul	$t9, $t9, 4	  # multiply by 4 to get word offset
	add	$t9, $t9, $gp	  # add to base address
	sw	$a2, ($t9)	  # store color at memory location
	jr 	$ra
	


#################################################
# draw_maze 
# $a0 = array address
# $a1 = array size
draw_maze:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li	$s0, 0			# return value
	li	$t0, 0			# t0 as index i
	li	$t1, 0			# t1 as index j
draw_Loop1:
	blt	$t1, $a1, draw_Loop2	# if (int j=0; j < 15; j++)
	move	$v0, $s0		# reutrn value
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
draw_Loop2:
	# Define the 2D index address #
	mul	$t2, $t1, $a1		# t1 = rowIndex * colSize
	add	$t2, $t2, $t0		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	# get element of arr index and save to $t3 #
	lw	$t3, 0($t2)

	move	$t5, $a0
	move	$t6, $a1
	
	# 0 = path => skip
	beq	$t3, $zero, skip

	# 1 = wall => BLUE
	li	$t7, 1
	beq	$t3, $t7, draw_wall

	# 3 = hit-trap mark => LIGHT_GRAY
	li	$t7, HIT_TRAP_VAL
	beq	$t3, $t7, draw_hit_trap

	# 2 (hidden trap) or anything else => invisible
	j	skip

	draw_wall:
		add 	$a0, $0, $t0
		add 	$a1, $0, $t1
		li  	$a2, BLUE
		jal	draw_pixel
		j	skip

	draw_hit_trap:
		add 	$a0, $0, $t0
		add 	$a1, $0, $t1
		li  	$a2, L_GRAY
		jal	draw_pixel
		j	skip

			
							
skip:											
	move	$a0, $t5		# reset
	move	$a1, $t6		# reset
	add	$s0, $s0, $t3		# sum = sum + mdArray[i][j]
	
	addi	$t0, $t0, 1		# i++
	blt	$t0, $a1, draw_Loop2	# if (i < 15) --> loop again
	addi	$t1, $t1, 1		# j++
	move	$t0, $zero		# reset i = 0
	move	$t5, $a0
	li	$v0, 4
	la	$a0, NEW_LINE
	syscall
	move	$a0, $t5		# reset
	j	draw_Loop1
		
	
	


#################################################
# Generate maze outer moat
# $a0 = array address
# $a1 = array size
# 
generate_maze_outer_moat:
# top/buttom outer moat
top_btm:
	li	$t0, 0		# index x = 0
	li	$s0, 0		# top y 
	li	$s1, 14		# btm y
	li	$t4, 1
t_b_loop: 				# for(x=0; x<max_x; x++)
	# Define the 2D index address #
	# top
	mul	$t2, $s0, $a1		# t1 = rowIndex * colSize
	add	$t2, $t2, $t0		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	sw	$t4, 0($t2)		# store 1 into the wall
	# bottom
	mul	$t2, $s1, $a1		# t1 = rowIndex * colSize
	add	$t2, $t2, $t0		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	sw	$t4, 0($t2)		# store 1 into the wall
	addi	$t0, $t0, 1		# i++
	bne	$t0, $a1, t_b_loop	# keep looping until x = 15
# left/right outer moat
left_right:
	# $s0 is used as left x and $s1 is used as right x
	move	$t0, $zero		# j = 0
l_r_loop:
	# Define the 2D index address #
	# left
	mul	$t2, $t0, $a1		# t1 = rowIndex * colSize
	add	$t2, $t2, $s0		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	sw	$t4, 0($t2)		# store 1 into the wall
	# right
	mul	$t2, $t0, $a1		# t1 = rowIndex * colSize
	add	$t2, $t2, $s1		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	sw	$t4, 0($t2)		# store 1 into the wall
	
	addi	$t0, $t0, 1		# j++
	bne	$t0, $a1, l_r_loop	# keep looping until x = 15
	
	jr	$ra


#################################################
# Generate maze street
# $a0 = array address
# $a1 = array size
generate_maze_street:
	li	$t0, 2			# j = 2
	li	$t1, 2			# i = 2
	li	$s0, 14			# arrSize - 1 = max_y = max_x
	li	$s1, 1			# wall or prop
	li	$s3, 3
	li	$s4, 6
	li	$s5, 9
	
maze_st_loop1:				# for(y=4; y<max_y-1; y+2)
	beq	$t0, $s0, check_x_location
	j	maze_st_loop2
	
check_x_location:
	beq	$t1, $s0, end_maze_st_loop

maze_st_loop2:				# for(x=2; x<max_x-1; x+2)
	# Drop a prop for the wall
	mul	$t2, $t0, $a1		# t2 = rowIndex * colSize
	add	$t2, $t2, $t1		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	sw	$s1, 0($t2)		# store 1 into the wall
	
	# Generate random integer between range 1 ~ 12
	li	$t9, 0			# RANDOM INT value
	move	$t5, $a0		# save $a0 temporary
	move	$t6, $a1		# save $a1 temporary
	li	$v0, 42 		# syscall 42 = generate random int
	li 	$a1, 11 		# $a1 = upper bound
	syscall     			# $a0 = reutrn value
	addi 	$t9, $a0, 1		# random int + 1 
	move	$a0, $t5		# reset
	move	$a1, $t6		# reset
	
	
	# Case 1: 1  <= random int  <= 3
	sle   	$t7, $t9, $s3
	bne	$t7, $zero, case1
	# Case 2: 4  <= random int  <= 6
	sle	$t7, $t9, $s4
	bne	$t7, $zero, case2
	# Case 3: 7  <= random int  <= 9
	sle	$t7, $t9, $s5
	bne	$t7, $zero, case3
	# Case 4: 10 <= random int  <= 12
	j	case4
	

case1:
	# get element at array[x][y-1]
	addi	$t0, $t0, -1
	mul	$t2, $t0, $a1		# t2 = rowIndex * colSize
	add	$t2, $t2, $t1		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	lw	$t3, 0($t2)		# get the element
	addi	$t0, $t0, 1		# reset
	bne	$t3, $zero, reverse_x_index_by_two
	sw	$s1, 0($t2)
	j	next_x_index

case2:
	# get element at array[x][y+1]
	addi	$t0, $t0, 1
	mul	$t2, $t0, $a1		# t2 = rowIndex * colSize
	add	$t2, $t2, $t1		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	lw	$t3, 0($t2)		# store 1 into the wall
	addi	$t0, $t0, -1		# reset
	bne	$t3, $zero, reverse_x_index_by_two
	sw	$s1, 0($t2)
	j	next_x_index

case3:
	# get element at array[x-1][y]
	addi	$t1, $t1, -1
	mul	$t2, $t0, $a1		# t2 = rowIndex * colSize
	add	$t2, $t2, $t1		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	lw	$t3, 0($t2)		# store 1 into the wall
	addi	$t1, $t1, 1		# reset
	bne	$t3, $zero, reverse_x_index_by_two
	sw	$s1, 0($t2)
	j	next_x_index

case4:
	# get element at array[x+1][y]
	addi	$t1, $t1, 1
	mul	$t2, $t0, $a1		# t2 = rowIndex * colSize
	add	$t2, $t2, $t1		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	lw	$t3, 0($t2)		# store 1 into the wall
	addi	$t1, $t1, -1		# reset
	bne	$t3, $zero, reverse_x_index_by_two
	sw	$s1, 0($t2)
	j	next_x_index

reverse_x_index_by_two:
	addi	$t1, $t1, -2
	#j	maze_st_loop2

next_x_index:
	# if
	addi	$t1, $t1, 2		# i + 2
	beq	$t1, $s0, check_y_location	# if (i == 14) -> check y and move or exit function
	j	maze_st_loop2
	


check_y_location:
	addi	$t0, $t0, 2		# j + 2
	li	$t1, 2			# reset i = 2
	beq	$t0, $s0, end_maze_st_loop
	j	maze_st_loop1
	
end_maze_st_loop:
	# call to set start and goal point
	# start
	li	$t1, MAZE_START_X	# x
	li	$t0, MAZE_START_Y	# y
	mul	$t2, $t0, $a1		# t2 = rowIndex * colSize
	add	$t2, $t2, $t1		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	sw	$zero, 0($t2)		# make a hole
	# goal
	li	$t1, MAZE_GOAL_X	# x
	li	$t0, MAZE_GOAL_Y	# y
	mul	$t2, $t0, $a1		# t2 = rowIndex * colSize
	add	$t2, $t2, $t1		# 			 + colIndex
	mul	$t2, $t2, DATA_SIZE	# multiply by the data size
	add	$t2, $t2, $a0		# add base address
	sw	$zero, 0($t2)		# make a hole
	
	jr	$ra
	


#########################################
# Show Current location of the user
#
user_location:
	# set up starting position
	addi	$a0, $zero, 1		# column = 1
	addi	$a1, $zero, 0		# row = 0
	addi 	$a2, $0, RED  		# a2 = red (ox00RRGGBB)
	lw	$s6, arrSize		# colSize	
	la	$s7, mdArray		# array base address
loop_user_location:
	jal 	draw_pixel
	
	# check for input
	lw $t0, 0xffff0000  #t1 holds if input available
    	beq $t0, 0, loop_user_location   #If no input, keep displaying
	
	# process input
	lw 	$s1, 0xffff0004
	beq	$s1, 32, exit	# input space
	beq	$s1, 119, up 	# input w
	beq	$s1, 115, down 	# input s
	beq	$s1, 97, left  	# input a
	beq	$s1, 100, right	# input d
	# invalid input, ignore
	j	loop_user_location

# process valid input	
up:
	# Check if you are allowed to go to that location
	beq	$a1, $zero, skip_move_up
	addi	$t4, $a1, -1			# y-1 as "up"

	# get element at array[x][y-1]
	mul	$t2, $t4, $s6
	add	$t2, $t2, $a0
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $s7
	lw	$t3, 0($t2)		# next cell value

	li	$t7, 1
	beq	$t3, $t7, skip_move_up     # wall => ignore

	li	$t7, TRAP_VAL
	bne	$t3, $t7, not_trap_up

	# trap hit: save trap (x,y) then trigger
	move	$s2, $a0        # trapX = next x (same column)
	move	$s3, $t4        # trapY = next y
	j	trap_trigger

not_trap_up:
	# allow move if cell is 0 (path) OR 3 (used-trap mark)
	li	$t7, HIT_TRAP_VAL
	beq	$t3, $t7, do_move_up
	bne	$t3, $zero, skip_move_up   # any other nonzero => block

do_move_up:
	li	$a2, 0		# black out the old pixel
	jal	draw_pixel
	addi	$a1, $a1, -1
	addi 	$a2, $0, RED
	jal	draw_pixel

skip_move_up:
	j	loop_user_location

	

down:
	addi	$t4, $a1, 1			# y+1 as "down"
	li	$t5, MAZE_GOAL_X
	li	$t6, MAZE_GOAL_Y

	# get element at array[x][y+1]
	mul	$t2, $t4, $s6
	add	$t2, $t2, $a0
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $s7
	lw	$t3, 0($t2)

	li	$t7, 1
	beq	$t3, $t7, skip_move_down   # wall => ignore

	li	$t7, TRAP_VAL
	bne	$t3, $t7, not_trap_down

	# trap hit
	move	$s2, $a0
	move	$s3, $t4
	j	trap_trigger

not_trap_down:
	# allow move if 0 or HIT_TRAP_VAL
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
	beq	$a1, $t6, goal_reached

skip_move_down:
	j	loop_user_location

	
	
left:
	addi	$t4, $a0, -1			# x-1 as "left"

	# get element at array[x-1][y]
	mul	$t2, $a1, $s6
	add	$t2, $t2, $t4
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $s7
	lw	$t3, 0($t2)

	li	$t7, 1
	beq	$t3, $t7, skip_move_left

	li	$t7, TRAP_VAL
	bne	$t3, $t7, not_trap_left

	# trap hit (next x is t4)
	move	$s2, $t4
	move	$s3, $a1
	j	trap_trigger

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
	addi	$t4, $a0, 1			# x+1 as "right"

	# get element at array[x+1][y]
	mul	$t2, $a1, $s6
	add	$t2, $t2, $t4
	mul	$t2, $t2, DATA_SIZE
	add	$t2, $t2, $s7
	lw	$t3, 0($t2)

	li	$t7, 1
	beq	$t3, $t7, skip_move_right

	li	$t7, TRAP_VAL
	bne	$t3, $t7, not_trap_right

	# trap hit
	move	$s2, $t4
	move	$s3, $a1
	j	trap_trigger

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




##############################################
goal_reached:
	# Show message
	# Board
	li	$a0, 0	# x
	li	$a1, 0	# y
	addi 	$a2, $0, YELLOW
	li	$s0, 256	# stop
	j	loop_board2
	
#################################################
# place_traps
# $a0 = mdArray base
# $a1 = arrSize (15)
# Places NUM_TRAPS traps (TRAP_VAL) on path cells only.
place_traps:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t8, 0              # traps placed

trap_loop:
    move $t5, $a0            # save base
    move $t6, $a1            # save size

    # random x in [1, a1-2]  => 1..13
    li   $v0, 42
    addi $a1, $t6, -2        # upper bound
    syscall
    addi $t0, $a0, 1         # x = rand + 1

    # random y in [1, a1-2]  => 1..13
    li   $v0, 42
    addi $a1, $t6, -2
    syscall
    addi $t1, $a0, 1         # y = rand + 1

    move $a0, $t5            # restore base
    move $a1, $t6            # restore size

    # avoid start tile
    li   $t2, MAZE_START_X
    bne  $t0, $t2, check_goal_trap
    li   $t2, MAZE_START_Y
    beq  $t1, $t2, trap_loop

check_goal_trap:
    # avoid goal tile
    li   $t2, MAZE_GOAL_X
    bne  $t0, $t2, check_cell_trap
    li   $t2, MAZE_GOAL_Y
    beq  $t1, $t2, trap_loop

check_cell_trap:
    # addr = base + 4*(y*size + x)
    mul  $t2, $t1, $a1
    add  $t2, $t2, $t0
    mul  $t2, $t2, DATA_SIZE
    add  $t2, $t2, $a0

    lw   $t3, 0($t2)
    bne  $t3, $zero, trap_loop   # only place on path (0)

    li   $t4, TRAP_VAL
    sw   $t4, 0($t2)

    addi $t8, $t8, 1
    li   $t7, NUM_TRAPS
    blt  $t8, $t7, trap_loop

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


#################################################
# clear_screen
# expects $a2=color, fills whole 16x16 logical grid
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


#################################################
# crude busy-wait delay
delay_3s:
    li $t0, 0
    li $t1, 1000000     
d3_loop:
    addi $t0, $t0, 1
    blt  $t0, $t1, d3_loop
    jr   $ra


#################################################
# Helpers for letters
# $a0=start x, $a1=start y, $a3=end (x for hline, y for vline), $a2=color

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


#################################################
# trap_trigger
trap_trigger:
    # ---- MARK TRAP AS HIT (visible gray later) ----
    # mdArray[trapY][trapX] = HIT_TRAP_VAL
    mul  $t2, $s3, $s6        # t2 = trapY * arrSize
    add  $t2, $t2, $s2        # t2 = trapY*size + trapX
    mul  $t2, $t2, DATA_SIZE  # word offset
    add  $t2, $t2, $s7        # base + offset
    li   $t4, HIT_TRAP_VAL
    sw   $t4, 0($t2)

    # ---- rest of your trap screen code follows ----
    li  $a2, RED
    jal clear_screen

    # RED background
    li  $a2, RED
    jal clear_screen

    # WHITE letters spelling "TRAP"
    li  $a2, WHITE

    # --- T ---
    li $a0, 1
    li $a1, 4
    li $a3, 3
    jal draw_hline
    li $a0, 2
    li $a1, 4
    li $a3, 8
    jal draw_vline

    # --- R ---
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

    # --- A ---
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

    # --- P ---
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

    # delay ~3 seconds
    jal delay_3s

    # clear back to WHITE
    li  $a2, WHITE
    jal clear_screen

    # redraw maze (walls only)
    la  $a0, mdArray
    lw  $a1, arrSize
    jal draw_maze

    # reset player to start
    li  $a0, MAZE_START_X
    li  $a1, MAZE_START_Y
    li  $a2, RED
    jal draw_pixel

    j loop_user_location


#loop_board1:
#	beq	$a0, $s0, exit
loop_board2:
	jal	draw_pixel
	addi	$a0, $a0, 1	#i++
	beq	$a0, $s0, completed_board
	j	loop_board2

#check_board_y:
#	addi	$a1, $a1, 1	#j++
#	j	loop_board1


completed_board:
	## GOAL! ##
	
	# G
	li	$a0, 1	#x
	li	$a1, 2	#y
	addi 	$a2, $0, RED
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	addi	$a0, $a0, 1
	jal	draw_pixel
	li	$a0, 1	# reset
	
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
	li	$a0, 8	#x
	li	$a1, 2	#y
	
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
	li	$a0, 1	#x
	li	$a1, 10	#y
	
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
	li	$a0, 8	#x
	li	$a1, 10	#y
	
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
	li	$a0, 14	#x
	li	$a1, 10	#y
	
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 1
	jal	draw_pixel
	addi	$a1, $a1, 2
	jal	draw_pixel
	
	j	exit