# Author: Ben Brittain

#constants
FRAMESIZE = 40
GRASS   = 0
TREE    = 1
TENT    = 2

        .data
        .align 2

error_board_size:   
        .asciiz "Invalid board size, Tents terminating\n"

error_sum_str:
        .asciiz "Illegal sum value, Tents terminating\n"

error_tree_str:
        .asciiz "Illegal number of trees, Tents terminating\n"

error_loc_str:
        .asciiz "Illegal tree location, Tents terminating\n"

        .align 2

board:  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

size:   .byte 0
tree:   .byte 0
rows:   .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
cols:   .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

str_space:  .asciiz " "
str_grass:  .asciiz "."
str_tree:   .asciiz "T"
str_tent:   .asciiz "A"
str_floor:  .asciiz "-"
str_border: .asciiz "|"
str_corner: .asciiz "+"
str_banner: .asciiz "******************\n**     TENTS    **\n******************"
str_newline:.asciiz "\n"

        .text				# this is program code
        .align	4			# code must be on word boundaries
        .globl	main			# main is a global label


main:
        jal     read_board              # function call to read in board from file
        jal     print_board             # function call to pretty-print board
        j       exit                    # end the program

print_board:
        addi    $sp, $sp, -FRAMESIZE
        sw      $ra, -4+FRAMESIZE($sp)
        sw      $s7, 28($sp)
        sw      $s6, 24($sp)
        sw      $s5, 20($sp)
        sw      $s4, 16($sp)
        sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

        ### load in all the vals ###
        la      $s0, size           # load address of boardsize
        lb      $s0, 0($s0)         # load boardsize form address
        la      $s1, rows           # load first row sum in s1
        la      $s2, cols           # load first col sum in s2
        la      $s3, board          # load board in s3
        li      $v0, 4              # only print strings values

        ### print out top border ###
        li      $t0, 0              # incrementor 
        la  $a0, str_corner         # print +
        syscall
        la  $a0, str_floor          # print -
        syscall
    for_top:
        beq     $t0, $s0, done_top  # if t0 is the size of board, finish off top
        addi    $t0, $t0, 1         # increment 
        la      $a0, str_floor      # print -
        syscall
        la      $a0, str_floor      # print -
        syscall
        j for_top
    done_top:
        la  $a0, str_corner         # print +
        syscall
        la  $a0, str_newline        # print \n
        syscall

        ### for each row, for each col: print vals###
        li      $t0, 0              # count rows
    for_row:
        li      $t1, 0              # count cols
        beq     $s0, $t0, done_rows # if t0 counter reaches board size, go print sums         

        la  $a0, str_border         # print |
        syscall
        la  $a0, str_space          # print " "
        syscall

    for_col:
        beq     $t1, $s0, finish_row# if t1 is the same size as board, finish the row
        mul     $t3, $t0, $s0       # start array offset        
        add     $t3, $t3, $t1       # add in col num
        add     $t3, $t3, $s3       # add in memory address now points at value

        lb      $t4, 0($t3)         # load object at t3 into t4
        li      $t5, GRASS
        beq     $t4, $t5, print_grass # if 0, print grass
        li      $t5, TREE
        beq     $t4, $t5, print_tree # if 0, print tree
        li      $t5, TENT
        beq     $t4, $t5, print_tent # if 0, print tent

    print_grass:
        la      $a0, str_grass      # print .
        j       actual_print
    print_tree:
        la      $a0, str_tree       # print T 
        j       actual_print
    print_tent:
        la      $a0, str_tent       # print A
        j       actual_print
    actual_print:
        syscall
        la      $a0, str_space      # print " "
        syscall

        addi    $t1, $t1, 1         # increment col counter
        j       for_col

    finish_row:
        la      $a0, str_border     # print |
        syscall
        la      $a0, str_space      # print " "
        syscall
        add     $t6, $t0, $s1       # add row num to address
        lb      $t6, 0($t6)         # get value
        li      $v0, 1              # change v0 to 1 for this integer printout
        add     $a0, $t6, $zero     # put t6 in a0 a lazy way
        syscall
        li      $v0, 4              # change v0 back to 4

        la      $a0, str_newline    # print \n
        syscall
        addi    $t0, $t0, 1
        j for_row

    done_rows:

        ### print out bottom border ###
        li      $t0, 0              # incrementor 
        la  $a0, str_corner         # print +
        syscall
        la  $a0, str_floor          # print -
        syscall
    for_bot:
        beq     $t0, $s0, done_bot  # if t0 is the size of board, finish off top
        addi    $t0, $t0, 1         # increment 
        la      $a0, str_floor      # print -
        syscall
        la      $a0, str_floor      # print -
        syscall
        j for_bot
    done_bot:
        la  $a0, str_corner         # print +
        syscall
        la  $a0, str_newline        # print \n
        syscall

    ### Print out column sums ###
        la      $a0, str_space      # print " "
        syscall
        la      $a0, str_space      # print " "
        syscall
        li      $t1, 0              # counter for cols
    val_loop:
        beq     $s0, $t1, done_vals # if t1 counter reaches board size, be done
        add     $t3, $s2, $t1       # get new mem address pointing at col
        lb      $t2, 0($t3)         # load byte from said address
        li      $v0, 1              # change v0 to 1 for this integer printout
        add     $a0, $t2, $zero     # put t2 in a0 a lazy way
        syscall
        li      $v0, 4              # change v0 back to 4
        la      $a0, str_space      # print " "
        syscall
        addi    $t1, $t1, 1         # increment counter and mempointer
        j val_loop
    done_vals:
        la      $a0, str_newline    # print \n
        syscall


        lw      $ra, -4+FRAMESIZE($sp)
        lw      $s7, 28($sp)
        lw      $s6, 24($sp)
        lw      $s5, 20($sp)
        lw      $s4, 16($sp)
        lw      $s3, 12($sp)
        lw      $s2, 8($sp)
        lw      $s1, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, FRAMESIZE

        jr      $ra

read_board:
        addi    $sp, $sp, -FRAMESIZE
        sw      $ra, -4+FRAMESIZE($sp)
        sw      $s7, 28($sp)
        sw      $s6, 24($sp)
        sw      $s5, 20($sp)
        sw      $s4, 16($sp)
        sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

	li 	$v0, 5                  # read in board size
	syscall
        move    $s0, $v0                # store board size in s0
        la      $s6, size               # load address for board size
        sb      $s0, 0($s6)             # store s0 in size

        ### check that board is of appropriate dimensions ###
        li      $t0, 1                  # store 1 in t0
        slti    $t3, $s0, 2             # is s0 less than 2? 1 if so
        beq     $t3, $t0, error_board   # if t3 is less than 2 (== 1) error!
        slti    $t3, $s0, 13            # is s0 less then 13? 1 if so
        beq     $t3, $zero, error_board # is t3 greater than 12? (==0) error!

        ### read in number of trees for each row ###
        li      $t0, 0                  # store 0 in t0
        li      $t4, 1                  # store 1 in t4
        la      $s1, rows               # load address of rows data
    row_read:
        beq     $t0, $s0, done_row      # if t0 (counter) is same size as s0 (board) be done
        li      $v0, 5                  # read in value
        syscall
        move    $t1, $v0                # store val in $t1
        slti    $t3, $t1, 0             # is t1 less than 0? 1 if so
        beq     $t3, $t4, error_sum     # if t1 is less than 0 (== 1) error!
        slt     $t3, $t1, $s0           # is t1 less then n (s0)? 1 if so
        beq     $t3, $zero, error_sum   # is t1 greater than s0? (==0) error!
        sb      $t1, 0($s1)             # store t1 in s1
        addi    $s1, $s1, 1             # increment s1 memory address by 1 byte
        addi    $t0, $t0, 1             # increment loop counter by 1
        j row_read                      # jump to top of loop
    done_row:                           
        la      $s1, rows               # here so I can check that it is right [DEBUG] [CORRECT]

        ### read in number of trees for each col ###
        li      $t0, 0                  # store 0 in t0
        la      $s1, cols               # load address of cols data
    col_read:
        beq     $t0, $s0, done_col      # if t0 (counter) is same size as s0 (board) be done
        li      $v0, 5                  # read in value
        syscall
        move    $t1, $v0                # store val in $t1
        slti    $t3, $t1, 0             # is t1 less than 0? 1 if so
        beq     $t3, $t4, error_sum     # if t1 is less than 0 (== 1) error!
        slt     $t3, $t1, $s0           # is t1 less then n (s0)? 1 if so
        beq     $t3, $zero, error_sum   # is t1 greater than s0? (==0) error!
        sb      $t1, 0($s1)             # store t1 in s1
        addi    $s1, $s1, 1             # increment s1 memory address by 1 byte
        addi    $t0, $t0, 1             # increment loop counter by 1
        j col_read                      # jump to top of loop
    done_col:                           
        la      $s1, cols               # here so I can check that it is right [DEBUG] [CORRECT]

        ### read in overall number of trees ###
        la      $s2, tree               # load address of trees data
        li      $v0, 5                  # read in value
        syscall
        move    $t1, $v0                # store val in $t1
        slti    $t3, $t1, 0             # is t1 less than 0? 1 if so
        beq     $t3, $t4, error_tree    # if t1 is less than 0 (== 1) error!
        sb      $t1, 0($s2)             # store t1 in s2 henceforth known a "c"
        move    $s2, $t1                # store tree num for ease of access later on

        ### read in location of each tree ###
        li      $t0, 0                  # counter for trees
    tree_read:
        beq     $t0, $s2, tree_done     # done if all trees are read in
        li      $v0, 5                  # read in value
        syscall
        move    $t1, $v0                # store row in $t1
        slti    $t5, $t1, 0             # is t1 less than 0? 1 if so
        beq     $t5, $t4, error_loc     # if t1 is less than 0 (== 1) error!
        slt     $t5, $t1, $s0           # is t1 less then n (s0)? 1 if so
        beq     $t5, $zero, error_loc   # is t1 greater than s0? (==0) error!
        li      $v0, 5                  # read in value
        syscall
        move    $t2, $v0                # store col in $t2
        slti    $t5, $t2, 0             # is t2 less than 0? 1 if so
        beq     $t5, $t4, error_loc     # if t2 is less than 0 (== 1) error!
        slt     $t5, $t2, $s0           # is t2 less then n (s0)? 1 if so
        beq     $t5, $zero, error_loc   # is t2 greater than s0? (==0) error!
        mul     $t3, $t1, $s0           # multiply row by boardsize
        add     $t3, $t3, $t2           # add col to row*12 for array offset
        la      $s4, board              # load address of board into s4
        add     $t3, $t3, $s4           # add offset to memory address
        li      $t4, TREE
        sb      $t4, 0($t3)             # put a tree down
        addi    $t0, $t0, 1             # increment loop counter
        j tree_read
    tree_done:
        lw      $ra, -4+FRAMESIZE($sp)
        lw      $s7, 28($sp)
        lw      $s6, 24($sp)
        lw      $s5, 20($sp)
        lw      $s4, 16($sp)
        lw      $s3, 12($sp)
        lw      $s2, 8($sp)
        lw      $s1, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, FRAMESIZE

        jr      $ra


exit:
    move    $a0, $s0              # Store return code in $a0
    li      $v0, 10               # load exit2 syscall number in $v0
    syscall                       # Execute the syscall




error_board:
	li 	$v0, 4          # print 1st number label	
	la 	$a0, error_board_size
	syscall
        j       exit
error_sum:
	li 	$v0, 4          # print 1st number label	
	la 	$a0, error_sum_str
	syscall
        j       exit
error_tree:
	li 	$v0, 4          # print 1st number label	
	la 	$a0, error_tree_str
	syscall
        j       exit
error_loc:
	li 	$v0, 4          # print 1st number label	
	la 	$a0, error_loc_str
	syscall
        j       exit
noerror:
