### SNAKE GAME IN ASSEMBLY
### Requires bitmap display and keyboard simulator connected

### BITMAP SETTINGS
### Unit Width in pixels: 8 			         
### Unit Heigh in pixels: 8				  
### Display Width in pixels: 512 -> 64 squares/row	  
### Display Height in pixels: 256 -> 32 squares/column

### PSEUDO CODE 
-> User starts the game

loadInitialGameState(){
    drawBackground();
    drawWall();
    drawSnake();
    drawFood();
}
gameLoop(){
    getUserInput();

    if user input is valid then:
        changeSnakeDirection();
    updateNewHeadPosition();

    check new position:

        if position == food then:
            increaseScore();
            generateNewFood();
            drawNewHead();
            goto gameLoop

        if position == blank then:
            deleteOldTail();
            updateNewTailPosition();
            drawNewHead();
            goto gameLoop

        if position == wall or body then:
            printGameOverMessageAndScore();
            ask player if they want to play again:
                if answer == yes then:
                    goto loadInitialGameState
                else:
                    end the game
}
-> The game ends

### NOTES
# Valid input is that user can't move up while the snake is moving down,
# can't move left when the snake is moving right, etc...

# In order to move the snake forward, we delete tail and draw head,
# if snake eats the food then we only draw new head.

# The direction code works like the pointer in a singly linked list, 
# it is used to move to the new tail after we delete the old tail.

.data

    ### MEMORY
    squares:         .space  8192           # 2048 squares x 4 bytes = 8192 bytes
                                            # Note: every square has 8 hex charater
                                            # First 2 charater is direction code (00, 01, 02, 03)
                                            # 6 lower charater is color code in hex
    bgcolor:        .word   0xcefad0        # light green
    wallcolor:      .word   0x008631        # dark green
    snakecolor:     .word   0x0000ff        # blue
    foodcolor:      .word   0xff0000        # red
    up:             .word   0x01000000      # direction code for up
    down:           .word   0x02000000      # direction code for down 
    left:           .word   0x03000000      # direction code for left
    right:          .word   0x04000000      # direction code for up
    gameOverStr:    .asciiz "Game over! Your score: "
    endline:        .asciiz "\n"
    askPlayer:      .asciiz "\nDo you want to play again?"

    ### REGISTER
    # $s0 = score
    # $s1 = address of the head square in memory
    # $s2 = address of the tail square in memory
    # $s3 = current direction

.text

####################### BEGIN FUNCTION #######################
### LOAD INTIAL GAME STATE
begin:
    li  $s0, 0              # reset points before new game
    li  $s3, 0              # reset direction
    sw  $zero, 0xffff0004   # reset user input
                            # $s1 and $s2 will be reset in draw procedure

### DRAW BACKGROUND
    la  $t0, squares        # load base address
    li  $t1, 2048           # number of squares
    lw  $t2, bgcolor        # load background color: light green
loop1:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 4         # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, loop1          # keep drawing if no of squares > 0


### DRAW WALL
    # Variables for top wall
    la $t0, squares         # load base address
    li $t1, 64              # number of squares in a row
    lw $t2, wallcolor       # load wall color: dark green
drawTopWall:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 4         # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, drawTopWall    # keep drawing if no of squares > 0

    # Variables for bottom wall
    la  $t0, squares            # load base address
    add $t0, $t0, 7936          # move to the bottom left corner
    la  $t1, 64                 # number of squares in a row
drawBottomWall:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 4         # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, drawBottomWall # keep drawing if no of squares > 0

    # Variables for left wall
    la  $t0, squares            # load base address
    add $t0, $t0, 256           # move to the first column, top second square
    la  $t1, 30                 # number of squares in a column - 2
drawLeftWall:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 256       # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, drawLeftWall   # keep drawing if no of squares > 0

    # Variables for right wall
    la  $t0, squares            # load base address
    add $t0, $t0, 508           # move to the last column, top second square
    la  $t1, 30                 # number of squares in a column - 2
drawRightWall:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 256       # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, drawRightWall  # keep drawing if no of squares > 0


### DRAW INITIAL SNAKE, SET INITIAL VALUE TO HEAD AND TAIL
    la  $t0, squares        # load base address
    add $t0, $t0, 3964      # move to middle of the screen
    add $s1, $t0, $zero     # set initial head address
    lw  $t1, snakecolor     # load snake color
    sw  $t1, 0($t0)         # load color to square

    lw  $t2, right          # right value
    add $t1, $t1, $t2       # square value = color + direction
    sw  $t1, -4($t0)        # load square value to square
    sw  $t1, -8($t0)        # load square value to square

    add $t0, $t0, -8        # set initial tail address
    add $s2, $t0, $zero     

### DRAW INITIAL FOOD
    jal randomFoodLocation

### START THE GAME
    j   gameLoop

#################### SNAKE FUNCTION ########################
updateHead:
### SET OLD HEAD DIRECTION
    lw  $t0, 0($s1)             # load head value
    add $t0, $t0, $s3           # add direction to value   
    sw  $t0, 0($s1)             # put value back
### UPDATE NEW HEAD POSITION
    lw  $t0, up
    beq $s3, $t0, moveHeadUp
    lw  $t0, down
    beq $s3, $t0, moveHeadDown
    lw  $t0, left
    beq $s3, $t0, moveHeadLeft
    lw  $t0, right
    beq $s3, $t0, moveHeadRight

moveHeadUp:
    add $s1, $s1, -256          # move 64 squares back x 4 bytes
    j   checkCollision
moveHeadDown:
    add $s1, $s1, 256           # move 64 squares forward x 4 bytes
    j   checkCollision
moveHeadLeft:
    add $s1, $s1, -4            # move 1 squares back x 4 bytes
    j   checkCollision
moveHeadRight:
    add $s1, $s1, 4             # move 1 squares forward x 4 bytes
    j   checkCollision

### CHECK COLLISION
checkCollision:
    lw  $t0, 0($s1)             # load color of the head snake square b4 drawing
    lw  $t1, foodcolor          # load food color
    beq $t0, $t1, foodEvent     # branch if new head == food
    lw  $t1, bgcolor            # load background color
    beq $t0, $t1, cont          # continue if head == background color

    # If we get to here it means head == wallcolor or snakecolor
    j   gameOver

### DELETE OLD TAIL AND UPDATE NEW TAIL
cont:
    lw  $t0, 0($s2)             # get old tail value
    li  $t1, 0xff000000
    and $t0, $t0, $t1           # get the first 2 bytes (direction of old tail)
                                # to move to the next tail
    # DELETE OLD TAIL
    lw  $t1, bgcolor            
    sw  $t1, 0($s2)             # set old tail == bgcolor

    # UPDATE NEW TAIL
    lw  $t1, up                 
    beq $t0, $t1, moveTailUp    
    lw  $t1, down
    beq $t0, $t1, moveTailDown
    lw  $t1, left
    beq $t0, $t1, moveTailLeft
    lw  $t1, right
    beq $t0, $t1, moveTailRight

moveTailUp:
    add $s2, $s2, -256
    j   drawHead
moveTailDown:
    add $s2, $s2, 256
    j   drawHead
moveTailLeft:
    add $s2, $s2, -4
    j   drawHead
moveTailRight:
    add $s2, $s2, 4
    j   drawHead

### DRAW HEAD 
drawHead:
    lw  $t0, snakecolor     # load snake color
    sw  $t0, 0($s1)         # load color to head square
    j   gameLoop

##################### FOOD FUNCTION ########################
foodEvent:
    add $s0, $s0, 1             # increment score by 1
    jal randomFoodLocation      # draw new food
    
    j   drawHead                # back to update snake
                                # on food event we don't delete tail

randomFoodLocation:
    # Generate the location of apple
    li  $v0, 42
    li  $a1, 2047       # upperbound = 2047
    syscall             # a0 = rand[0, 2047]

    # Check if location is valid
    la  $t0, squares    # base address
    sll $a0, $a0, 2     # a0 = a0 * 4
    add $t0, $t0, $a0   # address of the randomized square

    lw  $t1, 0($t0)                     # load randomized square's color
    lw  $t2, bgcolor                    # load bg color
    bne $t1, $t2, randomFoodLocation    # rerandom if square's color != bg color
                                        # (square is occupied)

drawFood:
    lw  $t1, foodcolor      # load food color
    sw  $t1, 0($t0)         # to the randomized square
    jr  $ra

##################### GAME FUNCTION ########################
gameLoop:
    lw  $t0, 0xffff0004         # get user input

    li  $v0, 32           # syscall code for sleep
    li  $a0, 50           # sleep for 50ms -> 20 fps
    syscall

    beq $t0, 119, changeUp      # input charater == 'w'
    beq $t0, 115, changeDown    # input charater == 's'
    beq $t0, 97, changeLeft     # input charater == 'a'
    beq $t0, 100, changeRight   # input charater == 'd'

    j   gameLoop                # game does not start 
                                # until user press one of the move keys

changeUp:
    lw  $t1, down               # the snake is not allow to change direction
    beq $s3, $t1, updateHead    # to <Up> when it's moving <Down>   

    lw  $s3, up                 # change direction
    j   updateHead              # update next status of the snake
changeDown:
    lw  $t1, up                 # the snake is not allow to change direction
    beq $s3, $t1, updateHead    # to <Down> when it's moving <Up>

    lw  $s3, down               # change direction
    j   updateHead              # update next status of the snake
changeLeft:
    lw      $t1, right              # the snake is not allow to change direction
    beq     $s3, $t1, updateHead    # to <Right> when it's moving <Left>
    beqz    $s3, gameLoop           # the initial position
                                    # does not allow player to move left

    lw  $s3, left               # change direction
    j   updateHead              # update next status of the snake
changeRight:
    lw  $t1, left               # the snake is not allow to change direction
    beq $s3, $t1, updateHead    # to <Left> when it's moving <Right>

    lw  $s3, right              # change direction
    j   updateHead              # update next status of the snake
    

gameOver:
    # Print game over and players' score message
    li  $v0, 4
    la  $a0, gameOverStr
    syscall
    li  $v0, 1
    add $a0, $s0, $zero         # score is at $s0
    syscall
    li  $v0, 4
    la  $a0, endline
    syscall

    # Ask player if they want to play again
    li  $v0, 50
    la  $a0, askPlayer
    syscall
    
    beqz    $a0, begin            # if yes = player chooses to play again
    li      $v0, 10               # else terminate program
    syscall
