# File:         tents.asm
# Author:       Ben Brittain
#
# Description:  Written for Comp Org Project
#               Takes in a file that represents an unsolved tents game
#               solves the game from a tree perspective blazingly fast
#                prints output

# Constants for various uses. Mostly for readability of code
#
FRAMESIZE       = 40            # How much to push the stack pointer

GRASS           = 0             # The board representation of grass
TREE            = 1             # The board representation of Trees
TENT            = 2             # The board representation of Tents

NORTH           = 1             # Represents North in the Tree Data Structure
EAST            = 2             # Represents East in the Tree Data Structure
SOUTH           = 3             # Represents South in the Tree Data Structure
WEST            = 4             # Represents West in the Tree Data Structure

        .data
        .align 2

# Error Messages that are displayed by the program during errors
#

error_board_size:   
        .asciiz "\nInvalid board size, Tents terminating\n"

error_sum_str:
        .asciiz "\nIllegal sum value, Tents terminating\n"

error_tree_str:
        .asciiz "\nIllegal number of trees, Tents terminating\n"

error_loc_str:
        .asciiz "\nIllegal tree location, Tents terminating\n"

        .align 2

# Various global Data Structures manipulated by the program
#

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

size:   .byte 0             # stores the size of the rows/col
rows:   .byte 0:12          # stores 12 possible values for row sums
cols:   .byte 0:12          # stores 12 possible values for col sums
tree:   .byte 0             # stores how many trees there are
trees:  .byte 0:40          # stores 40 possible tree orientations

# Strings that are used for printing the board
#

str_space:  .asciiz " "     
str_grass:  .asciiz "."
str_tree:   .asciiz "T"
str_tent:   .asciiz "A"
str_floor:  .asciiz "-"
str_border: .asciiz "|"
str_corner: .asciiz "+"
str_banner: .asciiz "\n******************\n**     TENTS    **\n******************\n"
str_newline:.asciiz "\n"
str_imposibru: .asciiz "\nImpossible Puzzle\n\n"
str_init: .asciiz "\nInitial Puzzle\n\n"
str_final: .asciiz "\nFinal Puzzle\n"

        .text				    # this is program code
        .align	4			    # code must be on word boundaries
        .globl	main			    # main is a global label

main:
        li      $v0, 4                      # only print strings values
        la      $a0, str_banner             # print *TENT*
        syscall
        jal     read_board                  # function call to read in board from file
        li      $v0, 4                      # only print strings values
        la      $a0, str_init               # print Initial Puzzle
        syscall
        jal     print_board                 # function call to pretty-print board
        move    $a0, $zero                  # what cell are we on?
        jal     guess                       # function call to brute-force algorithm
        move    $s0, $v0                    # what does guess return?
        beq     $s0, $zero, fail            # if 0, then no solution
        li      $v0, 4                      # only print strings values
        la      $a0, str_final              # print Initial Puzzle
        syscall
        li      $v0, 4                      # only print strings values
        la      $a0, str_newline            # print Initial Puzzle
        syscall
        jal     print_board                 # function call to pretty-print board
        li      $v0, 4                      # only print strings values
        la      $a0, str_newline            # print Initial Puzzle
        syscall
        j valid_board
fail:
        li      $v0, 4                      # only print strings values
        la      $a0, str_imposibru          # print "Impossible Puzzle"
        syscall
valid_board:
        j       exit                        # end the program


# Name: Guess
# Main code for recursivly guessing various tree orientations
# takes $a0 as the current tree that is being guessed
# returns a 0 or 1 in $v0 to represent success or failure respectivly
#
# Ascii representation of what the various orientations mean. 
# Also declared as Cardinal Direction constants at beginning of program
#        ################
#        #              #
#        #      1       #
#        #    4 T 2     #
#        #      3       #
#        #              #
#        #   0 = notyet #
#        ################
#

guess:
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

        # load all necessary values
        la      $s0, size               # load address of boardsize
        lb      $s0, 0($s0)             # load boardsize form address
        la      $s3, board              # load board in s3
        la      $s4, tree               # load address of tree
        lb      $s4, 0($s4)             # load tree in s4
        la      $s5, trees              # load address of trees

        # a0 is the current tree we are testing 0 - $s4
        move    $s6, $a0                # tree is now in $s5
        beq     $s6, $s4, guess_good    # if we are on the last tree (maybe +1?), your done
        li      $s1, 4                  # store possible tree position
        add     $t0, $s5, $s6           # get tree byte
        lb      $t0, 0($t0)             # get current tree alue
        beq     $zero, $t0, guess_loop  # guess loop
        addi    $a0, $s6, 1             # try next tree
        jal     guess                   # recurse to next tree cell
        j       guess_fin               # return value returned by guess

guess_loop:
        move    $a0, $s1                # pass tree-position as argument
        move    $a1, $s6                # pass tree number as argument (top left to bottom right)
        jal     check                   # check that position is valid and the board still works
        beq     $v0, $zero, guess_bad   # if v0 is 0, bad guess, try different position
        add     $t0, $s5, $s6           # get tree byte
        sb      $s1, 0($t0)             # otherwise, put tree into array!
        addi    $a0, $s6, 1             # move onto next cell
        jal     guess                   # recurse forward!
        li      $t1, 1                  # put 1 into t1
        beq     $v0, $t1, guess_fin     # if guess returns one, finish up!

guess_bad:
        addi    $s1, $s1, -1            # decrement position guess [maybe need to take in board consideration]
        beq     $s1, $zero, nothing_work# if s1 reaches 0, then nothing works and FAIL
        j       guess_loop              # otherwise, try guessing again in new position
nothing_work:
        add     $t0, $s5, $s6           # get tree byte
        sb      $zero, 0($t0)           # clear out num
        li      $v0, 0                  # return failure
        j guess_fin                     # finish up, skip over good
guess_good:
        li      $v0, 1
guess_fin:
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

# Name: TreePlacement
# Function responsible for placing trees in actual board.
# takes tree number 
# returns a 1 in $v0 if tent fits, otherwise a 0
# as arguments takes tree location in $s1 and the direction in $s4
#

treeplacement:
    #return 1 in v0 if tent in a0
    #return 0 if tent does not work
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

        ### load all necessary values ###
        la      $s0, size               # load address of boardsize
        lb      $s0, 0($s0)             # load boardsize form address
        la      $s1, board              # load board in s3
        la      $s2, trees              # load address of trees

        move    $s3, $a0                # board offset location of tree
        move    $s4, $a1                # direction TENT is being placed

        li      $t1, NORTH
        beq     $t1, $s4, north         # if t1 and s4 are the same, NORTH
        li      $t1, SOUTH 
        beq     $t1, $s4, south         # if t1 and s4 are the same, SOUTH
        li      $t1, EAST 
        beq     $t1, $s4, east          # if t1 and s4 are the same, EAST
        li      $t1, WEST 
        beq     $t1, $s4, west          # if t1 and s4 are the same, WEST
north:
        li      $t1, -1                 # negate
        mul     $t1, $s0, $t1           # multiply -1 times board size
        add     $t1, $s3, $t1           # location TENT would be placed ( - offset + board size for previous row)
        move    $s5, $t1                # store location of tent. later return location in v1
        slt     $t2, $t1, $zero         # is t1 less than 0?
        li      $t7, 1                  # we need a $one
        beq     $t2, $t7, no_placement  # if it is less than 0, fail!

        add     $t2, $s1, $t1           # location TENT would be placed ( - offset + board size for previous row)
        lb      $t3, 0($t2)             # whats at proposed tent spot
        beq     $t3, $zero, north_empty # spot is empty
        j       no_placement
north_empty:
        li      $t3, TENT               # put a tent in t3
        sb      $t3, 0($t2)             # store tent in spot on board
        j donedirection
south:
        add     $t1, $s3, $s0           # location TENT would be placed (offset + board size for next row)
        move    $s5, $t1                # store location of tent. later return location in v1
        mul     $t2, $s0, $s0           # max board size
        slt     $t2, $t2, $t1           # is t2 (board size) < new tent location?
        li      $t7, 1                  # we need a $one
        beq     $t2, $t7, no_placement  # if it is overflowed, no placement
        add     $t1, $s1, $t1           # memory address of tent
        lb      $t3, 0($t1)             # whats at proposed tent spot
        beq     $t3, $zero, south_empty # spot is empty
        j       no_placement
south_empty:
        li      $t3, TENT               # put a tent in t3
        sb      $t3, 0($t1)             # store tent in spot on board
        j donedirection
east:
        addi    $t1, $s3, 1             # location TENT would be placed
        move    $s5, $t1                # store location of tent. later return location in v1
        mul     $t2, $s0, $s0           # max board size
        slt     $t3, $t1, $t2           # is the tente off the board on the right?
        beq     $t3, $zero, no_placement# if t1 is not less than board size, no placement
        div     $t1, $s0                # divide TENT location by board dim
        mfhi    $t3                     # col index
        beq     $t3, $zero, no_placement# if in col 0, overflowed to next line. BAD
        add     $t2, $s1, $t1           # location of TENT offset on board 
        lb      $t3, 0($t2)             # whats at proposed tent spot
        beq     $t3, $zero, east_empty  # spot is empty
        j       no_placement            # if not empty, no placement there
east_empty:
        li      $t3, TENT               # put a tent in t3
        add     $t2, $s1, $t1           # location of TENT offset on board 
        sb      $t3, 0($t2)             # store tent in spot on board
        j donedirection
west:
        addi    $t1, $s3, -1            # location TENT would be placed
        move    $s5, $t1                # store location of tent. later return location in v1
        slti    $t3, $t1, 0             # is the tente off the board on the left?
        beq     $t3, $zero, westalong   # if on board, westalong
        j       no_placement
westalong:
        div     $t1, $s0                # divide TENT location by board dim
        mfhi    $t3                     # col index
        addi    $t2, $s0, -1            # size of column
        beq     $t3, $t2, no_placement  # if on last column (as in they are equal) then bad placement
        add     $t2, $s1, $t1           # location of TENT offset on board 
        lb      $t3, 0($t2)             # whats at proposed tent spot
        beq     $t3, $zero, west_empty  # spot is empty
        j       no_placement            # if not empty, no placement there
west_empty:
        li      $t3, TENT               # put a tent in t3
        add     $t2, $s1, $t1           # location of TENT offset on board 
        sb      $t3, 0($t2)             # store tent in spot on board
        j donedirection
donedirection:
        li      $v0, 1                  # set v0 to be true!
        move    $v1, $s5                # return the board offset of the new tent
        j end_placement
no_placement:
        li      $v0, 0                  # set v0 to be false

end_placement:
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

# Name: Check
# Takes in a new tree and sees if board is valid by tents rules
# takes treeposition in a0 and tree direction in a1
# returns a 1 in v0 if the then works, otherwise a 0
#

check:
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

        ### load all necessary values ###
        la      $s0, size               # load address of boardsize
        lb      $s0, 0($s0)             # load boardsize form address
        la      $s1, rows               # load first row sum in s1
        la      $s2, cols               # load first col sum in s2
        la      $s3, board              # load board in s3
        la      $s4, tree               # load address of tree
        lb      $s4, 0($s4)             # load tree in s4
        la      $s5, trees              # load address of tree

        move    $s6, $a0                # tree direction
        move    $s7, $a1                # which tree number

        li      $t0, 0                  # counter for board iteration
        mul     $t4, $s0, $s0           # get board size
clear_board:
        beq     $t0, $t4, done_clear    # t0 is max size, board is empty
        add     $t1, $t0, $s3           # get address of cell
        lb      $t3, 0($t1)             # put get value of cell
        li      $t2, TREE               # put TREE in t2
        beq     $t3, $t2, skip_clear    # if t3 is a TREE don't clear otherwise...
        sb      $zero, 0($t1)           # clear cell 
skip_clear:
        addi    $t0, $t0, 1             #increment
        j clear_board
done_clear:

        li      $t0, 0                  # counter for board iteration
        mul     $t4, $s0, $s0           # get board size
        li      $t5, 0                  # tree count!
iter_board:
        beq     $t0, $t4, iter_done     # t0 is max size, all cells have been visited
        add     $t1, $t0, $s3           # get address of cell
        lb      $t3, 0($t1)             # put get value of cell
        li      $t2, TREE               # put TREE in t2
        beq     $t3, $t2, treepres      # if t3 is a TREE go to treepress
        j       notatree                # no trees here sir
treepres:
        ### what to do if we are currently looking at a tree ###
        beq     $t5, $s7, newtree       # this is the newly placed tree
        j       oldtree                 # go to oldtree if not true
newtree:  
        move    $a0, $t0                # store board offset in a0, should be a tree [CHECK]
        move    $a1, $s6                # store tree direction in a1.
        jal     treeplacement           # call new function
        move    $s6, $v1                # store new board offsett of tent in s6
        beq     $v0, $zero, fail_check  # DID NOT FIT
        j       skip_oldtree
oldtree:
        move    $a0, $t0                # store board offset in a0, should be a tree [CHECK]
        add     $t6, $s5, $t5           # add t5 (the tree count) to the location of trees
        lb      $t6, 0($t6)             # load what should be in trees at this byte
        beq     $t6, $zero, skip_oldtree
        move    $a1, $t6                # put direction in treeplacement
        jal     treeplacement           # call new function to place a tree in memory
skip_oldtree:
        addi    $t5, $t5, 1             # next tree please
notatree:
        addi    $t0, $t0, 1             # increment
        j       iter_board              # move on to next cell
iter_done:


        # go through current row
        # sum up values
        # if it is greater than the row sum, return false
        div     $s6, $s0
        mfhi    $t0                     # col index
        mflo    $t1                     # row index

        mul     $t2, $t1, $s0           # get the first element in the row
        add     $t3, $t2, $s0           # get the next row element
        li      $t5, 0                  # running sum of row
sum_row:
        beq     $t2, $t3, check_row_sum
        add     $t4, $t2, $s3           # get memory address 
        lb      $t4, 0($t4)             # get value at memory address
        li      $t6, TENT               # if there is a tent there...
        beq     $t4, $t6, add_sum
        j       next_in_row
add_sum:
        addi    $t5, $t5, 1     
next_in_row:
        addi    $t2, $t2, 1
        j       sum_row
check_row_sum:
        add     $t1, $t1, $s1           # add to get memory address of row sum
        lb      $t1, 0($t1)             # get actual value of row sum
        beq     $t1, $t5, row_fine      # if the are the same, the row is fine
        slt     $t6, $t5, $t1           # if t5 (the running total) is less than t1 (valid sum)
        beq     $t6, $zero, fail_check  # if it is 0 (the running total is not less than sum)
row_fine:

        # go through current row
        # sum up values
        # if it is greater than the row sum, return false
        div     $s6, $s0
        mfhi    $t0                     # col index
        li      $t2, 0                  # how many values have we looked at
        li      $t5, 0                  # running sum of row
sum_col:
        beq     $t2, $s0, check_col_sum
        add     $t4, $t0, $s3           # get memory address 
        lb      $t4, 0($t4)             # get value at memory address
        li      $t6, TENT               # if there is a tent there...
        beq     $t4, $t6, add_sum_col   # if the same, branch and add
        j       next_in_col
add_sum_col:
        addi    $t5, $t5, 1     
next_in_col:
        addi    $t2, $t2, 1
        add     $t0, $t0, $s0           # add board size to get next value in col
        j       sum_col
check_col_sum:
        div     $s6, $s0
        mfhi    $t0                     # col index
        add     $t1, $t0, $s2           # add to get memory address of row sum
        lb      $t1, 0($t1)             # get actual value of row sum
        beq     $t1, $t5, col_fine      # if the are the same, the row is fine
        slt     $t6, $t5, $t1           # if t5 (the running total) is less than t1 (valid sum)
        beq     $t6, $zero, fail_check  # if it is 0 (the running total is not less than sum)
col_fine:

        # Check all four corners to see if being placed next to another tent
        addi    $t1, $s6, 1             # check East Position
        mul     $t2, $s0, $s0           # max board size
        slt     $t3, $t1, $t2           # is the tente off the board on the right?
        beq     $t3, $zero, east_good   # if t1 is not less than board size, no placement
        div     $t1, $s0                # divide TENT location by board dim
        mfhi    $t3                     # col index
        beq     $t3, $zero, east_good   # if in col 0, overflowed to next line. BAD
        add     $t2, $s3, $t1           # location of TENT offset on board 
        lb      $t3, 0($t2)             # whats at proposed tent spot
        li      $t4, TENT               # put a tent in t3
        beq     $t3, $t4, fail_check    # if it is a tent, invalidate the spot
east_good:
        addi    $t1, $s6, -1            # check West Position
        slti    $t3, $t1, 0             # is the tente off the board on the left?
        beq     $t3, $zero, westalongcheck
        j       west_good
westalongcheck:
        div     $t1, $s0                # divide TENT location by board dim
        mfhi    $t3                     # col index
        addi    $t2, $s0, -1            # size of column
        beq     $t3, $t2, west_good     # if on last column (as in they are equal) then bad placement
        add     $t2, $s3, $t1           # location of TENT offset on board 
        lb      $t3, 0($t2)             # whats at proposed tent spot
        li      $t4, TENT               # put a tent in t3
        beq     $t3, $t4, fail_check    # if it is a tent, invalidate the spot
west_good:
        li      $t1, -1                 # negate
        mul     $t1, $s0, $t1           # multiply -1 times board size
        add     $t1, $s6, $t1           # location TENT would be placed ( - offset + board size for previous row)
        slt     $t2, $t1, $zero         # is t1 less than 0?
        li      $t7, 1                  # we need a $one
        beq     $t2, $t7, north_good    # if it is less than 0, fail!
        add     $t2, $s3, $t1           # location of TENT offset on board 
        lb      $t3, 0($t2)             # whats at proposed tent spot
        li      $t4, TENT               # put a tent in t3
        beq     $t3, $t4, fail_check    # if it is a tent, invalidate the spot
north_good:
        add     $t1, $s6, $s0           # location TENT would be placed (offset + board size for next row)
        move    $s5, $t1                # store location of tent. later return location in v1
        mul     $t2, $s0, $s0           # max board size
        slt     $t2, $t2, $t1           # is t2 (board size) < new tent location?
        li      $t7, 1                  # we need a $one
        beq     $t2, $t7, south_good    # if it is overflowed, no placement
        add     $t2, $s3, $t1           # location of TENT offset on board 
        lb      $t3, 0($t2)             # whats at proposed tent spot
        li      $t4, TENT               # put a tent in t3
        beq     $t3, $t4, fail_check    # if it is a tent, invalidate the spot
south_good:
        li      $v0, 1          # return true
        j       pass_check
fail_check:
        li      $v0, 0          # return false
pass_check:
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

# Name: Print Board
# prints out the board according to website specifications

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
        li      $t1, 0              # counter for cols
val_loop:
        beq     $s0, $t1, done_vals # if t1 counter reaches board size, be done
        add     $t3, $s2, $t1       # get new mem address pointing at col
        lb      $t2, 0($t3)         # load byte from said address
        li      $v0, 4              # change v0 back to 4
        la      $a0, str_space      # print " "
        syscall
        li      $v0, 1              # change v0 to 1 for this integer printout
        add     $a0, $t2, $zero     # put t2 in a0 a lazy way
        syscall
        li      $v0, 4              # change v0 back to 4
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

# Name: Read Board
# reads in values from standard output that represent the game board
#

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

# Name: Exit
# Finish up the program!

exit:
    move    $a0, $s0                    # Store return code in $a0
    li      $v0, 10                     # load syscall number in $v0
    syscall                             # Execute the syscall

# Yell about various errors

error_board:
	li 	$v0, 4                  # print 1st number label	
	la 	$a0, error_board_size
	syscall
        j       exit
error_sum:
	li 	$v0, 4                  # print 1st number label	
	la 	$a0, error_sum_str
	syscall
        j       exit
error_tree:
	li 	$v0, 4                  # print 1st number label	
	la 	$a0, error_tree_str
	syscall
        j       exit
error_loc:
	li 	$v0, 4                  # print 1st number label	
	la 	$a0, error_loc_str
	syscall
        j       exit
noerror:
