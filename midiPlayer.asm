#Register Information
#$s0 is the starttime of the note
#$s1 is the channel of the note
#$s2 is the duration of the noe
#$s3 is the velocity(volume) of the note
#$s4 is the memory address of the notes
#$s5 is the time of the program
#$s6 is the pitch of the note

.data
.align 2
printmsg: .asciiz "Please enter the filename you wish to read (remember to add the .bin): "
printmsg2:.asciiz "File not found, are you adding .bin?: "
filename: .ascii ""
songMemory:  .space 5000000 


.text

main:
jal printstring #jumps to the subroutine forp rinting the string asking a user to input a filename
readstringlink:
jal readString #jumps to the subroutine for reading a users input
jal nameClean #jumps to the subroutine for removing the null terminator
jal filereader #reads the file

la $s4, songMemory #loads the address of where the song is started

jal channelSet #jumps to the subroutine for setting the channels

addi $s5, $0, 0 #ensure $s5 is 0
 
song:
jal noteload #jumps to the noteloader

TimeLoop:
bge $s5, $s0, startTimeHit #loops until the start time of the note loaded is less than the time passed
addi $s5, $s5, 1 #adds one to the time passed
addiu $v0, $0, 32 #Sleep syscall
add $a0, $0, 1 #Sleep for 1 millisecond

syscall
j TimeLoop #jumps back to the beginning of the loop if the starttime is still greater than the time passed

startTimeHit:

jal note #Jumps to note and stores the return address


#jumps to the bginning of the song player
j song


#The subroutine used to set the channel instruments
channelSet:
addi $t0, $0, 16 #Ensures the loop includes all 16 channels
addi $t1, $0, 0 #initialises the register for storing the channel number to 0

whileLoop:
beq $t0, $t1, whileEnd #loops through the while loop code until t0 and t1 are equal

addiu $v0, $0, 38 #sets the syscall to midi channel change
add $a0, $0, $t1 #Adds the channel number to argument 0
lb $a1, ($s4) # loads the instrument to be used into argument 1
syscall

addi $t1, $t1, 1 #adds 1 to $t1 so it moves to the next channel
add $s4, $s4, 4 #adds 4 to the note memory address so it can access the next channel number
j whileLoop

whileEnd: #end of the while loop
jr $ra

##The noteload subroutine
noteload:
starttime:
lbu $t0, ($s4) #loads the firt start time byte that isn't bitshifted
lbu $t1, 1($s4) #loads the second start time byte which is bit shifted by 8
lbu $t2, 2($s4) #loads the third start time byte which is bit shifted by 16

sll $t1, $t1, 8 #bit shifts $t1 by 8
sll $t2, $t2, 16 #bit shifts $t2 by 16

add $t0, $t0, $t1 #adds the values of $t0 and $t1 together
add $s0, $t0, $t2 #Adds the values of $t0 and $t2 together and stores it in the register for start time

channel:
lbu $s1, 4($s4) #loads the channel of the note

beq $s1, 30, main #if the channel is 30 then the song has ended 
pitch:
lbu $s6, 8($s4) #loads the pitchvalue into memory

velocity:
lbu $s3, 12($s4) #loads the velocity (volume) value into memory

duration:
lbu $t0, 16($s4) #loads the duration byte not to be bit shifted
lbu $t1, 17($s4) #loads the duration byte to be bit shifted by 8
lbu $t2, 18($s4) #loads the duration byte to be bitshifted by 16

sll $t1, $t1, 8 #bit shifts $t1 by 8
sll $t2, $t2, 16 #bit shifts $t2 by 16

add $t0, $t0, $t1 #adds the values of $t0 and $t1 together
add $s2, $t0, $t2 #Adds the values of $t0 and $t2 together and stores it in the register for duration

add $s4, $s4, 20 #adds 20 to the memory address of the notes to reach the next set of data
jr $ra #jumps to return address

#The subroutine for playing the note
note:
addiu $v0, $0, 37 #sys Instruction
add $a0, $0, $s6 #Pitch
add $a1, $0, $s2 #Duration
add $a2, $0, $s1 #Channel
add $a3, $0, $s3 #Velocity/Volume 

syscall 
jr $ra #jump to return address

#The subroutine for reading the file
filereader:
#OPEN FILES
li $v0, 13 #the syscall for file reading
la $a0, filename #the address of the filename
li $a1, 0 #open for read only
syscall 
beq $v0, -1, printstring2 #if the value in $v0 is -1 then an error has occurred trying to read the file so it jumps to the message asking the user to reinput
move $t0, $v0 #moves the file descriptor to $t0

#READS FILE
li $v0, 14 #the syscall for reading the file
la $a1, songMemory #The address to store the song data in
li $a2, 5000000 # the number of bytes to read (5MB)
move $a0, $t0 #moves the file descriptor into argument 0
syscall

#Closes file
li $v0, 16 #closes the file
move $a0, $t0 #moves the file descriptor back to $a0
syscall

jr $ra #jumps to the return address

#This subroutine is used to read the users input into memory
readString:
li $v0, 8 #the sys call for reading a string
la $a0, filename #The memory address to store the filename
li $a1, 100 #the maximum length of a filename is 100bytes

syscall

jr $ra #jumps to the return address

#This subroutine is used to remove the null terminator at the end of a users input
nameClean:
li $t0, 0       #loop counter
li $t1, 100      #loop end

clean:
beq $t0, $t1, loopend #checks to see if the entire loop has been processed
lb $t3, filename($t0) #loads the character in the string stored specififed by the loop
bne $t3, 0x0a, loopincrement #if the character isn;t 0x0a (the null terminator) increment through the loop
sb $0, filename($t0) #replace the null terminator with 0 to fix the filename so it can be read correctly

loopincrement:
addi $t0, $t0, 1 #increment $t0
j clean #jump back to the start of the loop

loopend:
jr $ra #jump back to the return address

#This is called to ask the person to enter a filename
printstring:
li $v0, 4 #the syscall for printing a string
la $a0, printmsg #the string to be printed

syscall #perform the syscall

jr $ra #jump to the return address

#This is called if an incorrect filename is entered
printstring2:
li $v0, 4 #the syscall for printing a string
la $a0, printmsg2 #the string to be printed

syscall #perform the syscall

j readstringlink #jumps back to the input for the filename
