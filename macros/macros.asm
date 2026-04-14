//
// Switch bank in VIC-II
//
// Args:
//    bank: bank number to switch to. Valid values: 0-3.
//
.macro SwitchVICBank(bank) {
    //
    // The VIC-II chip can only access 16K bytes at a time. In order to
    // have it access all of the 64K available, we have to tell it to look
    // at one of four banks.
    //
    // This is controller by bits 0 and 1 in $dd00 (PORT A of CIA #2).
    //
    //  +------+-------+----------+-------------------------------------+
    //  | BITS |  BANK | STARTING |  VIC-II CHIP RANGE                  |
    //  |      |       | LOCATION |                                     |
    //  +------+-------+----------+-------------------------------------+
    //  |  00  |   3   |   49152  | ($C000-$FFFF)*                      |
    //  |  01  |   2   |   32768  | ($8000-$BFFF)                       |
    //  |  10  |   1   |   16384  | ($4000-$7FFF)*                      |
    //  |  11  |   0   |       0  | ($0000-$3FFF) (DEFAULT VALUE)       |
    //  +------+-------+----------+-------------------------------------+
    .var bits=%11

    .if (bank==0) .eval bits=%11
    .if (bank==1) .eval bits=%10
    .if (bank==2) .eval bits=%01
    .if (bank==3) .eval bits=%00

    .print "bits=%" + toBinaryString(bits)

    //
    // Set Data Direction for CIA #2, Port A to output
    //
    lda $dd02
    and #%11111100  // Mask the bits we're interested in.
    ora #$03        // Set bits 0 and 1.
    sta $dd02

    //
    // Tell VIC-II to switch to bank
    //
    lda $dd00
    and #%11111100
    ora #bits
    sta $dd00
}

//
// Switch location of screen memory.
//
// Args:
//   address: Address relative to current VIC-II bank base address.
//            Valid values: $0000-$3c00. Must be a multiple of $0400.
//
.macro SetScreenMemory(address) {
    // 
    // The most significant nibble of $D018 selects where the screen is
    // located in the current VIC-II bank.
    //
    //  +------------+-------------------------------------------------+
    //  |            |                     LOCATION*                   |
    //  |    BITS    +---------+---------------------------------------+
    //  |            | DECIMAL |                  HEX                  |
    //  +------------+---------+---------------------------------------+
    //  |  0000XXXX  |      0  |  $0000-$03FF, 0-1023.                 |
    //  |  0001XXXX  |   1024  |  $0400-$07FF, 1024-2047.   (DEFAULT)  |
    //  |  0010XXXX  |   2048  |  $0800-$0BFF, 2048-3071.              |
    //  |  0011XXXX  |   3072  |  $0C00-$0FFF, 3072-4095.              |
    //  |  0100XXXX  |   4096  |  $1000-$13FF, 4096-5119.              |
    //  |  0101XXXX  |   5120  |  $1400-$17FF, 5120-6143.              |
    //  |  0110XXXX  |   6144  |  $1800-$1BFF, 6144-7167.              |
    //  |  0111XXXX  |   7168  |  $1C00-$1FFF, 7168-8191.              |
    //  |  1000XXXX  |   8192  |  $2000-$23FF, 8192-9215.              |
    //  |  1001XXXX  |   9216  |  $2400-$27FF, 9216-10239.             |
    //  |  1010XXXX  |  10240  |  $2800-$2BFF, 10240-11263.            |
    //  |  1011XXXX  |  11264  |  $2C00-$2FFF, 11264-12287.            |
    //  |  1100XXXX  |  12288  |  $3000-$33FF, 12288-13311.            |
    //  |  1101XXXX  |  13312  |  $3400-$37FF, 13312-14335.            |
    //  |  1110XXXX  |  14336  |  $3800-$3BFF, 14336-15359.            |
    //  |  1111XXXX  |  15360  |  $3C00-$3FFF, 15360-16383.            |
    //  +------------+---------+---------------------------------------+
    //
    .var bits = (address / $0400) << 4

    lda $d018
    and #%00001111
    ora #bits
    sta $d018
}


//
// Enter hires bitmap mode (a.k.a. standard bitmap mode)
//
.macro SetHiresBitmapMode() {
    //
    // Clear extended color mode (bit 6) and set bitmap mode (bit 5)
    //
    lda $d011
    and #%10111111
    ora #%00100000
    sta $d011

    //
    // Clear multi color mode (bit 4)
    //
    lda $d016
    and #%11101111
    sta $d016
}

.macro ResetStandardBitMapMode() {
    lda $d011
    and #%11011111
    sta $d011
}

//
// Set location of bitmap.
//
// Args:
//    address: Address relative to VIC-II bank address.
//             Valid values: $0000 (bitmap at $0000-$1FFF)
//                           $2000 (bitmap at $2000-$3FFF)
//
.macro SetBitmapAddress(address) {
    //
    // In standard bitmap mode the location of the bitmap area can
    // be set to either BANK address + $0000 or BANK address + $2000
    //
    // By setting bit 3, we can configure which of the locations to use.
    //

    .var bits=0

    lda $d018

    .if (address == $0000) {            // this is chosen > bitmap address = 
        and #%11110111
    }

    .if (address == $2000) {
        ora #%00001000
    }

    .if (address == $0c00) {
        lda #%00111000
    }

    sta $d018
}

.macro FillBitmap(addr, value) {
    ldx #$00
    lda #value
!loop:
    sta addr,x
    sta (addr + $100),x
    sta (addr + $200),x
    sta (addr + $300),x
    sta (addr + $400),x
    sta (addr + $500),x
    sta (addr + $600),x
    sta (addr + $700),x
    sta (addr + $800),x
    sta (addr + $900),x
    sta (addr + $a00),x
    sta (addr + $b00),x
    sta (addr + $c00),x
    sta (addr + $d00),x
    sta (addr + $e00),x
    sta (addr + $f00),x
    sta (addr + $1000),x
    sta (addr + $1100),x
    sta (addr + $1200),x
    sta (addr + $1300),x
    sta (addr + $1400),x
    sta (addr + $1500),x
    sta (addr + $1600),x
    sta (addr + $1700),x
    sta (addr + $1800),x
    sta (addr + $1900),x
    sta (addr + $1a00),x
    sta (addr + $1b00),x
    sta (addr + $1c00),x
    sta (addr + $1d00),x
    sta (addr + $1e00),x
    sta (addr + $1f00),x
    dex
    bne !loop-
}


//
// Calcilates the 40x25 cell reference bitmap memory.
// Args:
//    X: X register filled with the X-axis cell number that we are wanting to reference. Value 0-39.
//    Y: Y register filled with the Y-axis cell number that we are wanting to reference. Value 0-24.
// Output: 
//    bitmap_pointer (in zero page) updated with 16-bit memory address to the cell reference sought.
//
.macro CalculateBlockAddress() {
    clc
    lda Y_Table_Lo,y
    adc X_Table_Lo,x
    sta bitmap_pointer+0
    lda Y_Table_Hi,y
    adc X_Table_Hi,x
    sta bitmap_pointer+1
}

//
// Calcilates the 40x25 cell reference screen memory.
// Args:
//    X: X register filled with the X-axis cell number that we are wanting to reference. Value 0-39.
//    Y: Y register filled with the Y-axis cell number that we are wanting to reference. Value 0-24.
// Output: 
//    bitmap_pointer (in zero page) updated with 16-bit memory address to the cell reference sought.
//
.macro CalculateScreenBlockAddress() {
    clc
    lda Y_Color_Table_Lo,y
    adc X_Color_Table_Lo,x
    sta screen_color_pointer+0
    lda Y_Color_Table_Hi,y
    adc X_Color_Table_Hi,x
    sta screen_color_pointer+1
}


// Each of the 1000 bytes in screen memory controls the color displayed for one cell. 
// The bytes in screen memory are in the same order as the cells in the bitmap (the color 
// of cell 650 is controlled by byte 650 in screen memory).
// 
// In each byte, four bits are used to control the color of each bit in the corresponding 
// cell of the bitmap, and four bits are used to control the color of bits equal to zero. 
// These bits are arranged in each byte of screen memory as follows:
//
// BIT CONFIGURATION FOR BYTES IN SCREEN MEMORY
//   +----------+----------+
//   | Bits 7-4 | Bits 3-0 |
//   +----------+----------+
//   | 7 6 5 4  | 3 2 1 0  |
//   +----------+----------+
//   | color of | color of |
//   | bits = 1 | bits = 0 |
//   +----------+----------+
//
//   Colors of squares in bit map mode do not come from color memory, as
//     they do in the character modes. Instead, colors are taken from screen
//     memory. The upper 4 bits of screen memory become the color of any bit
//     that is set to 1 in the 8 by 8 area controlled by that screen memory
//     location. The lower 4 bits become the color of any bit that is set to
//     a 0.
//
// COLOR CODES
//   +---------+-----------+  +---------+-----------+
//   | Dec Hex |   Color   |  | Dec Hex |   Color   |
//   |  0   0  |  BLACK    |  |  8   8  |  ORANGE   |
//   |  1   1  |  WHITE    |  |  9   9  |  BROWN    |
//   |  2   2  |  RED      |  | 10   A  |  LT RED   |
//   |  3   3  |  CYAN     |  | 11   B  |  GRAY 1   |
//   |  4   4  |  PURPLE   |  | 12   C  |  GRAY 2   |
//   |  5   5  |  GREEN    |  | 13   D  |  LT GREEN |
//   |  6   6  |  BLUE     |  | 14   E  |  LT BLUE  |
//   |  7   7  |  YELLOW   |  | 15   F  |  GRAY 3   |
//   +---------+-----------+  +---------+-----------+
//
// EXAMPLE
//  $32 = %00110010 = CYAN WHITE
//  $20 = %00100000 = WHITE BLACK
//  $02 = %00000010 = WHITE BLACK
//  $03 = %00000011 = BLACK CYAN



//
// Fill screen memory ROWS (only) with a value. Full rows only; e.g. full screen cells.
// Args:
//    y1: first row that we are going to fill. Value 0-24.
//    y2: last row that we are going to fill. Value 0-24.
// Notes:
//    y2 has to be bigger than y1. No tests are being made to either check for that or other conditions.
//
.macro FillBitmapBlockRows(y1, y2, bit_pattern, color) {

    sec
    lda y2
    sbc y1
    sta XY_block_row_height
    sta XY_block_temporary_1        // store temporay height as we have to traverse both screen & colors
 
    clc
    lda XY_block_row_height
    adc y1
    sta XY_block_start_row
    sta XY_block_temporary_2        // store temporay start row as we have to traverse both screen & colors

    // fill bitmap memory with required bit pattern
outerloop:
    ldx #39 // Column
loop:
    ldy XY_block_start_row // Row
    CalculateBlockAddress()
    lda #bit_pattern
    ldy #7
innerloop:
    sta (bitmap_pointer),y
    dey
    bpl innerloop
    dex
    bpl loop
    dec XY_block_start_row
    dec XY_block_row_height
    bpl outerloop

    // fill rows in screen memory with required colors
loop2: 
    ldx #0                                  // we need to set X=0 as we need the first address of the line
    ldy XY_block_temporary_2
    CalculateScreenBlockAddress()
    lda #color
    ldy #39                                 // we are setting the offset to 39 and counting down as we fill color
innerloop2: 
    sta (screen_color_pointer),y
    dey
    bpl innerloop2                          // when 0 we have drawn the full line ..
    dec XY_block_temporary_2                // we have to decrement the starting row as we need the next line
    dec XY_block_temporary_1                // decrement the heigh of the "box" as when 0 we break out..
    bpl loop2
}


//
// Fill screen memory ROWS (only) with a value. Full rows only; e.g. full screen cells.
// Args:
//    x1: Top left most cell that we are going to fill. Value 0-39. 
//    y1: first row that we are going to fill. Value 0-24.
//    x2: Bottom right most cell that we are going to fill. Value 0-39. 
//    y2: last row that we are going to fill. Value 0-24.
// Notes:
//    x2 has to be bigger than x1. No tests are being made to either check for that or other conditions.
//    y2 has to be bigger than y1. No tests are being made to either check for that or other conditions.
//
.macro FillBitmapBlockRectangle(x1, y1, x2, y2, bit_pattern, color) {

    sec
    lda y2
    sbc y1
    sta XY_block_row_height              // store the height of the rectangle
    sta XY_block_temporary_1

    sec
    lda x2
    sbc x1
    sta XY_block_row_width              // store the width of the rectangle
    //sta XY_block_temporary_2

    clc
    lda XY_block_row_height
    adc y1
    sta XY_block_start_row              // store the bottom-est starting row
    sta XY_block_temporary_3

    // fill bitmap memory with required bit pattern
outerloop:
    lda XY_block_row_width              // width of box
    sta XY_block_temporary_2            // width of box
    ldx x2                              // need the right most column (x2)
    stx XY_block_temporary_4            // right most column
loop:
    ldx XY_block_temporary_4            // right most column
    //ldy XY_block_start_row 
    ldy XY_block_temporary_3            // starting row
    CalculateBlockAddress()
    lda #0
    ldy #7
innerloop:
    sta (bitmap_pointer),y
    dey
    bpl innerloop
    // we have filled one char - need to move column & width pointer down
    dec XY_block_temporary_4            // dec column counter
    dec XY_block_temporary_2            // dec box width
    bpl loop
    //dec XY_block_start_row
    dec XY_block_temporary_3            // dec starting row
    dec XY_block_temporary_1            // dec height of box
    bpl outerloop

    // populate temporary variables. probably could use the main variables to save cycles as they are not needed really anymore ..
    lda XY_block_row_height 
    sta XY_block_temporary_1            // height of box
    lda XY_block_row_width
    sta XY_block_temporary_2            // width of box
    lda XY_block_start_row
    sta XY_block_temporary_3            // starting row
    ldx x2
    stx XY_block_temporary_4            // right most column

    // fill screen memory with required colors
loop2: 
    lda XY_block_row_width
    sta XY_block_temporary_2                // width of box - counted down
    ldx #0                                  // starting column (left most)
    ldy XY_block_temporary_3                // starting row
    CalculateScreenBlockAddress()
    lda #color
    ldy x2                                  // need to right most column as the Y reference
innerloop2: 
    sta (screen_color_pointer),y
    dey                                     // move column pointer to the left
    dec XY_block_temporary_2                // dec width of the box
    bpl innerloop2                          // when 0 we have drawn the full line ..
    dec XY_block_temporary_3                // dec starting row
    dec XY_block_temporary_1                // dec the height of the box. when 0 it's done & exit
    bpl loop2

}


.macro CopyBitmap(sourceaddr, destaddr) {
    ldx #$00
copy_bitmap_loop:
    lda sourceaddr,x
    sta destaddr,x
    lda (sourceaddr + $100),x
    sta (destaddr + $100),x
    lda (sourceaddr + $200),x
    sta (destaddr + $200),x
    lda (sourceaddr + $300),x
    sta (destaddr + $300),x
    lda (sourceaddr + $400),x
    sta (destaddr + $400),x
    lda (sourceaddr + $500),x
    sta (destaddr + $500),x
    lda (sourceaddr + $600),x
    sta (destaddr + $600),x
    lda (sourceaddr + $700),x
    sta (destaddr + $700),x
    lda (sourceaddr + $800),x
    sta (destaddr + $800),x
    lda (sourceaddr + $900),x
    sta (destaddr + $900),x
    lda (sourceaddr + $a00),x
    sta (destaddr + $a00),x
    lda (sourceaddr + $b00),x
    sta (destaddr + $b00),x
    lda (sourceaddr + $c00),x
    sta (destaddr + $c00),x
    lda (sourceaddr + $d00),x
    sta (destaddr + $d00),x
    lda (sourceaddr + $e00),x
    sta (destaddr + $e00),x
    lda (sourceaddr + $f00),x
    sta (destaddr + $f00),x
    lda (sourceaddr + $1000),x
    sta (destaddr + $1000),x
    lda (sourceaddr + $1100),x
    sta (destaddr + $1100),x
    lda (sourceaddr + $1200),x
    sta (destaddr + $1200),x
    lda (sourceaddr + $1300),x
    sta (destaddr + $1300),x
    lda (sourceaddr + $1400),x
    sta (destaddr + $1400),x
    lda (sourceaddr + $1500),x
    sta (destaddr + $1500),x
    lda (sourceaddr + $1600),x
    sta (destaddr + $1600),x
    lda (sourceaddr + $1700),x
    sta (destaddr + $1700),x
    lda (sourceaddr + $1800),x
    sta (destaddr + $1800),x
    lda (sourceaddr + $1900),x
    sta (destaddr + $1900),x
    lda (sourceaddr + $1a00),x
    sta (destaddr + $1a00),x
    lda (sourceaddr + $1b00),x
    sta (destaddr + $1b00),x
    lda (sourceaddr + $1c00),x
    sta (destaddr + $1c00),x
    lda (sourceaddr + $1d00),x
    sta (destaddr + $1d00),x
    lda (sourceaddr + $1e00),x
    sta (destaddr + $1e00),x
    lda (sourceaddr + $1f00),x
    sta (destaddr + $1f00),x
    dex
    txa 
    cmp #0
    beq done
    jmp copy_bitmap_loop
done: 
    //bne copy_bitmap_loop
}



//
// Fill screen memory with a value.
//
// Args:
//      address: Absolute base address of screen memory.
//      value: byte value to fill screen memory with
//
.macro FillScreenMemory(address, value) {
    //
    // Screen memory is 40 * 25 = 1000 bytes ($3E8 bytes)
    //
    ldx #$00
    lda #value
    // fill the first 255*3=765 bytes
!loop:
    sta address,x
    sta (address + $100),x
    sta (address + $200),x
    dex
    bne !loop-

    // fill the last 232 bytes; e.g. 
    ldx #$e8
!loop:
    sta (address + $2ff),x     // Start one byte below the area we're clearing
                               // That way we can bail directly when zero without an additional comparison
    dex
    bne !loop-
}


//
// Copy screen memory with a value. Used typically to copy color scheme for bitmap
//
// Args:
//      sourceaddress: Absolute base address of screen memory.
//      sourceaddress: Absolute base address of screen memory.
//
.macro CopyScreenMemory(sourceaddr, destaddr) {
    //
    // Screen memory is 40 * 25 = 1000 bytes ($3E8 bytes)
    //
    ldx #$00
copy_loop_1:
    lda sourceaddr,x
    sta destaddr,x
    lda (sourceaddr + $100),x
    sta (destaddr + $100),x
    lda (sourceaddr + $200),x
    sta (destaddr + $200),x
    dex
    bne copy_loop_1

    ldx #$e8
copy_loop_2:
    lda (sourceaddr + $2ff),x     // Start one byte below the area we're clearing
    sta (destaddr + $2ff),x       // Start one byte below the area we're clearing
                                  // That way we can bail directly when zero without an additional comparison
    dex
    bne copy_loop_2
}


//
// Makes program halt until space is pressed. Useful when debugging.
//
.macro WaitForSpace() {
checkdown:
    lda $dc01
    cmp #$ef
    bne checkdown

checkup:
    lda $dc01
    cmp #$ef
    beq checkup
}


//----------------------------------------------------------
//  Macros
//----------------------------------------------------------
.macro SetupIRQ(IRQaddr,IRQline,IRQlineHi) {
    lda #$7f        // Disable CIA IRQ's
    sta $dc0d
    sta $dd0d

    lda #<IRQaddr   // Install RASTER IRQ
    ldx #>IRQaddr   // into Hardware
    sta $fffe       // Interrupt Vector
    stx $ffff

    lda #$01        // Enable RASTER IRQs
    sta $d01a
    lda #IRQline    // IRQ raster line
    sta $d012
    .if (IRQline > 255) {
        .error "supports only less than 256 lines"
    }
    lda $d011   // clear IRQ raster line bit 8
    and #$7f
    sta $d011

    asl $d019  // Ack any previous raster interrupt
    bit $dc0d  // reading the interrupt control registers
    bit $dd0d  // clears them
}
//----------------------------------------------------------
.macro EndIRQ(nextIRQaddr,nextIRQline,IRQlineHi) {
    asl $d019
    lda #<nextIRQaddr
    sta $fffe
    lda #>nextIRQaddr
    sta $ffff
    lda #nextIRQline
    sta $d012
    .if(IRQlineHi) {
        lda $d011
        ora #$80
        sta $d011
    }
}

.macro irq_start(end_lbl) {
    sta end_lbl-6
    stx end_lbl-4
    sty end_lbl-2
}

.macro irq_end(next, line) {
    :EndIRQ(next, line, false)
    lda #$00
    ldx #$00
    ldy #$00
    rti
}

// Setup stable raster IRQ NOTE: cannot be set on a badline or the second
// interrupt happens before we store the stack pointer (among other things)
.macro double_irq(end, stableIRQ) {
    //The CPU cycles spent to get in here                [7]
    irq_start(end) // 4+4+4 cycles

    lda #<stableIRQ     // Set IRQ Vector                [4]
    ldx #>stableIRQ     // to point to the               [4]
                        // next part of the
    sta $fffe           // Stable IRQ                    [4]
    stx $ffff           //                               [4]
    inc $d012           // set raster interrupt to the next line   [6]
    asl $d019           // Ack raster interrupt          [6]
    tsx                 // Store the stack pointer!      [2]
    cli                 //                               [2]
    // Total spent cycles up to this point   [51]
    nop        //                      [53]
    nop        //                      [55]
    nop        //                      [57]
    nop        //                      [59]
    nop        //Execute nop's         [61]
    nop        //until next RASTER     [63]
    nop        //IRQ Triggers
}


.macro add16_imm8(res, lo) {
    clc
    lda res
    adc #lo
    sta res+0
    lda res+1
    adc #0
    sta res+1
}



// Timing code - pause code for a set defined number of cycles
// :pause #10  // Waits 10 cycles 
// :pause2 #63 // Waits 63 cycles
.pseudocommand pause cycles {
    :ensureImmediateArgument(cycles)
    .var x = floor(cycles.getValue())
    .if (x<2) .error "Cant make a pause on " + x + " cycles"

    // Take care of odd cyclecount  
    .if ([x&1]==1) {
        bit $00
        .eval x=x-3
    }   
    
    // Take care of the rest
    .if (x>0)
        :nop #x/2
}

//---------------------------------
// repetition commands 
//---------------------------------
.macro ensureImmediateArgument(arg) {
    .if (arg.getType()!=AT_IMMEDIATE)   .error "The argument must be immediate!" 
}
.pseudocommand asl x {
    :ensureImmediateArgument(x)
    .for (var i=0; i<x.getValue(); i++) asl
}
.pseudocommand lsr x {
    :ensureImmediateArgument(x)
    .for (var i=0; i<x.getValue(); i++) lsr
}
.pseudocommand rol x {
    :ensureImmediateArgument(x)
    .for (var i=0; i<x.getValue(); i++) rol
}
.pseudocommand ror x {
    :ensureImmediateArgument(x)
    .for (var i=0; i<x.getValue(); i++) ror
}

.pseudocommand pla x {
    :ensureImmediateArgument(x)
    .for (var i=0; i<x.getValue(); i++) pla
}

.pseudocommand nop x {
    :ensureImmediateArgument(x)
    .for (var i=0; i<x.getValue(); i++) nop
}




