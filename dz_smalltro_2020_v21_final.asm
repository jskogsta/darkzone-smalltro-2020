/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
| DarkZone Smalltro 2020
| Context: 	Originally meant as a compo entry for Flashback 2020 in Sydney Australia. Covid-19 cancelled.
| Code: 	Agnostic
| 			Syntax Error
| Graphics: Kingpin
| Sprites:	Ripped from the Butt Fat 256kb Sprite Font Compo (URL: https://csdb.dk/release/?id=180797)
| Music: 	Unknown HVSC composer (thank you! awesome tune!)
| Sprites:	Ripped from the Butt Fat 256kb Sprite Font Compo (URL: https://csdb.dk/release/?id=180797)
| Font: 	7up.64c from Koefler.de
|
| Change log:
| 2020-02-28, dzlogo_scroll_sid8.asm
| - Changed picture loading to be native C64 Koala format so picture can be edited w/ Timanthes etc. 
| 2020-02-28, dzlogo_scroll_sid9.asm
| - New version to preserve code changes and that can revert back to clean compile version.
| 2020-03-02, dzlogo_scroll_sid10.asm
| - New version to transition code to use Exomizer cruncher/decruncher routines for data to pack file. 
| - Using https://github.com/p-a/kickass-cruncher-plugins to build inline support for Exomizer in Kick
| - Pre Exomizer = 48kb >>>> Post Exomizer = 
| 2020-09-05, dzlogo_scroll_sid11.asm
| - Added code to check sprite priority to give the illusion that the sprite text is moving behind logo
| 2020-09-06, dzlogo_scroll_sid12.asm
| - Restructured some of the sprite code. Including a sprite coordinate and direction of travel check
|   such that we can replace sprite pointers behind the logo to change the text that is displayed.
| - Size: 33272 bytes. 
|   MemExomizer: [ Screendata, Bitmap ] $8c00 - $bf3f Packed size $015e (2%) Safety distance: $0002
| - Size: 6394 bytes. Using exomizer to compress the prg file & create a compressed executable with this:
|   $ exomizer sfx sys -X 'inc $d020' dzlogo_scroll_sid12.prg -o compressed.prg
| 2020-09-13, dzlogo_scroll_sid12.asm
| - Checked whether it would make sense to Exo the picture compile time, or just lay out the memory "asis"
|   and deal with it when the final executable is compressed. It does not matter as long as you don't have
|   to move any data whilst you have the demo running. Then you can just as good lay out the memory and 
|   then compress the file when you are done. Below you can see the non-exo'd picture is 46kb VS 33kb above, 
|   but the end result file post compression is just about the same.
|     [08:11:24] [jskogsta@enterprise ../bin]$ ls -lrt
|     -rw-r--r--  1 jskogsta  staff  46913 13 Sep 08:10 dzlogo_scroll_sid12.prg
|     -rw-r--r--  1 jskogsta  staff   6411 13 Sep 08:11 compressed.prg
|     [08:11:26] [jskogsta@enterprise ../bin]$
|   Still using inline compression as then there are extra memory segments that can use used if required. 
| 2020-09-13, dzlogo_scroll_sid13.asm
| - v12 did not compile, so reverted back to v11 and added the sprite check routine from v12. Will need
|   to debug a bit and make that work next. 
| 2020-09-14, dzlogo_scroll_sid14.asm
| - have updated the sprite logic to be able to replace the sprite pointers behind the logo, which now
|   works. a bit clunky in configuring the text to display, but work... 
| - main issue now is that the banks are tight and I need to reconfigure the bank configuration to fit in
|   a full sprite character set. right now there is a conflict with the full size of the sprite character
|   set and the font_memory. saving this version as a working one and will try to reconfigure the banks.
| 2020-09-15, dzlogo_scroll_sid14.asm
| - next version where we reconfigure the vic banks
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*/
/*
Memory Map when compressed inline
----------------------------------------
Default-segment:
  $0801-$080c Basic
  $080e-$080d Basic End
  $2000-$2108 Default
  $2200-$3b7f Main ASM program start
  $6000-$771b SID Music
  $8800-$89f6 Text Mode Character Font
VIC segments:
  Hires vic_bank: 2
  Hires vic_base: 8000
  Hires screen_memory: 8c00
  Hires bitmap_address: a000
--
Memory Map when compressed executable
----------------------------------------
Default-segment:
  $0801-$080c Basic
  $080e-$080d Basic End
  $2000-$2108 Default
  $2110-$3921 Main ASM program start
  $6000-$771b SID Music
  *$8000-$8fff Bitmap buffer
  $8800-$89f6 Text Mode Character Font
  $8c00-$8fe7 Screen memory
  $a000-$bf3f Bitmap
--
*/

.plugin "se.triad.kickass.CruncherPlugins"

#import "macros/macros.asm"

// Exomizer: lets configure the setting for the Exomizer decruncher
.const EXO_LITERAL_SEQUENCES_USED = true
.const DISABLE_EXOMIZER_CACHE = true
.const EXO_ZP_BASE = $02
.const EXO_DECRUNCH_TABLE = $0200
#import "code/exomizer_decruncher.asm"

//#import "code/config_sprites.asm" 		// lets import the sprite configurations

// These statements load the raw data files. Used this originally, but switched to the C64 native Koala format below as can edit picture straigh in Timanthes
// Loading a native C64 Koala format picture that can be edited directly with Timanthes
// Koala picture format of DarkZone logo - native c64 picture converted with > retropixels < from a hires png file
.var picture1 = LoadBinary("bitmaps/2020-09-04_dzlogo_320x200_multipaint_v1.kla", BF_KOALA)

//.var music = LoadSid("resources/Active_Intro_14.sid")
.var music = LoadSid("resources/PSOMA2_v2.sid")




//  +---------------------------------------------------------------+ START
//  | VIDEO BANK CONFIGURATION - BITMAP   					            		|
//  +---------------------------------------------------------------+
.var vic_bank_bitmap = 2
.var screen_memory_bitmap_buffer_offset = $0c00 
.var bitmap_address_bitmap_buffer_offset = $2000
.var sprite_font_mem_bitmap_buffer_offset = $0400
.var custom_font_mem_bitmap_buffer_offset = $0800

.var vic_base_bitmap = $4000 * vic_bank_bitmap
.var screen_memory_bitmap = screen_memory_bitmap_buffer_offset + vic_base_bitmap
.var bitmap_address_bitmap = bitmap_address_bitmap_buffer_offset + vic_base_bitmap
.var custom_font_mem_bitmap = custom_font_mem_bitmap_buffer_offset + vic_base_bitmap

.var sprite_font_bitmap = LoadBinary("sprite_font/sprte_logo_darkzone_sprite_data_V1.raw")
.var sprite_font_mem_bitmap = sprite_font_mem_bitmap_buffer_offset + vic_base_bitmap
//.var sprite_font_bitmap = LoadBinary("sprite_font/sprte_font_V1_sprite_pad_format.raw")
//.var sprite_font_mem_bitmap = sprite_font_mem_bitmap_buffer_offset + vic_base_bitmap

// Text mode screen mode setup
.var text_mode_screen_memory = vic_base_bitmap    // text memory = $8000. Charset in $1000 which is in bank 2 mapped to character rom



// setting up for the DARKZONE sprites to be displayed
.const COORDINATES_COUNT = 256
.const VIC2 = $d000

.namespace sprites {
  .label positions = VIC2
  .label enable_bits = VIC2 + 21
  .label colors = VIC2 + 39
  .label pointers = screen_memory_bitmap + 1024 - 8
}
//	Sprite 	x coordinate 	y coordinate
//	#0 		53248/$D000 	53249/$D001
//	#1 		53250/$D002 	53251/$D003
//	#2 		53252/$D004 	53253/$D005
//	#3 		53254/$D006 	53255/$D007
//	#4 		53256/$D008 	53257/$D009
//	#5 		53258/$D00A 	53259/$D00B
//	#6 		53260/$D00C 	53261/$D00D
//	#7 		53262/$D00E 	53263/$D00F 
// The ninth and most significant bit for each of the eight sprites are "gathered" in address 53264/$D010; 
// the least significant bit here corresponds to sprite #0, and the most significant bit to sprite #7. 

.var sprite_pointer_0 = screen_memory_bitmap + $3f8 // 1016
.var sprite_pointer_1 = screen_memory_bitmap + $3f9 // 1017
.var sprite_pointer_2 = screen_memory_bitmap + $3fa // 1018
.var sprite_pointer_3 = screen_memory_bitmap + $3fb // 1019
.var sprite_pointer_4 = screen_memory_bitmap + $3fc // 1020
.var sprite_pointer_5 = screen_memory_bitmap + $3fd // 1021
.var sprite_pointer_6 = screen_memory_bitmap + $3fe // 1022
.var sprite_pointer_7 = screen_memory_bitmap + $3ff // 1023


// Lets load a new font from kofler.dot.at/c64/font_01.html . This will be loaded at font_mem above. 
// Specific URL is: http://kofler.dot.at/c64/download/7up.zip
.var font = LoadBinary("font/7up.64c", BF_C64FILE)


// The bitmap pointer has to reside in zero page because of the indirect addressing mode used
.const bitmap_pointer = $02
.const screen_color_pointer = $04

// top text scroller 
.const charpos_temp_lo = $20
.const charpos_temp_hi = $21

.const bitmap_scanline_1 = 0 				// lets set the hires graphics mode & move the text scroller
.const textscroller_scanline = 50+(18*8)-3 	// = 193 lets switch to text mode. scan line 0-50 not visible. 16*8=128. 128+50=178
.const bitmap_scanline_2 = 50+(18*8)+8  	// = 202 lets switch to text mode. scan line 0-50 not visible. 16*8=128. 128+50=178
//.const bitmap_scanline_2 = 50+(22*8)+8  	// = 202 lets switch to text mode. scan line 0-50 not visible. 16*8=128. 128+50=178

.const second_scroller_start = 50+(20*8)
.const second_scroller_end = 50+(21*8)

.label border_color = $d020

// split raster variables
.label screen_control_register_1 = $d011 	// control register 1
.label screen_control_register_2 = $d016 	// control register 2
.label intno  = $fb 			// interrupt counter 

BasicUpstart2(start)

* = $2110 "Main ASM program start"

start:    
	// bits 0-2 > %x10: RAM visible at $A000-$BFFF; KERNAL ROM visible at $E000-$FFFF.
	// http://www.awsm.de/mem64/?fbclid=IwAR1NmZ-i-bOoJlYiyXTxPtGVpGYF_eAXo8Ksr7xVamqgvSNsE1xtNyeskr8
	lda #%00110110
	sta $01

	lda #0
	sta charpos
	sta charpos+1
	sta framecount

	lda #BLACK
	sta $d020
	sta $d021

	// Lets decrunch stuff
	:EXO_DECRUNCH(crunchedBitmapAndScreen)

	// init music
	lda #music.startSong-1
	jsr music.init


//	CopyBitmap(Bitmap, bitmap_address)
//	CopyScreenMemory(Colors, screen_memory)

	// with the FLD effect that we are using, we are getting some garbage characters when we do an interrupt switch. hence have to put in emtpy characters in color memory to remove them.. 
	// zero out starting at $8ea8 for 40 characters with value $20 
	ldy #42
	lda #$20
fld_fill_more:
	sta $8ea7,Y
	dey
	bne fld_fill_more

	// fill text mode screen with space (' ') characters
	FillScreenMemory(text_mode_screen_memory, 32) 	// fill text screen with blank character. See https://www.c64-wiki.com/wiki/File:Zeichensatz-c64-poke1.jpg

	// IRQ setup - part 1
	sei
	lda #$35        // Bank out kernel and basic
	sta $01
	// Setup raster IRQ
	SetupIRQ(irq0, bitmap_scanline_1, false)

	lda #0
	sta framecount
	cli

	// lets set the sprite pointer (to the first character that's stored in memory)
	// screen memory = $0c00 within the active vic buffer. see following link for standard config details:
	// URL: https://www.c64-wiki.com/wiki/Screen_RAM
  // This is for the DARKZONE characters only in offset $0400
  ldx #$10
  stx sprite_pointer_0  // sprite pointer 0 = Character D
  ldx #$11
  stx sprite_pointer_1  // sprite pointer 1 = Character A
  ldx #$12
  stx sprite_pointer_2  // sprite pointer 2 = Character R
  ldx #$13
  stx sprite_pointer_3  // sprite pointer 3 = Character K
  ldx #$14
  stx sprite_pointer_4  // sprite pointer 4 = Character Z
  ldx #$15
  stx sprite_pointer_5  // sprite pointer 5 = Character O
  ldx #$16
  stx sprite_pointer_6  // sprite pointer 6 = Character N
  ldx #$17
  stx sprite_pointer_7  // sprite pointer 7 = Character E


	// lets enable the sprites by setting the bitmask for which sprites we want enabled
	//
	// Bit 0 ( $00000001 ) = Character D
	// Bit 1 ( $00000010 ) = Character A
	// Bit 2 ( $00000100 ) = Character R
	// Bit 3 ( $00001000 ) = Character K
	// Bit 4 ( $00010000 ) = Character Z
	// Bit 5 ( $00100000 ) = Character O
	// Bit 6 ( $01000000 ) = Character N
	// Bit 7 ( $10000000 ) = Character E
	//
	// of course - we want them all on given we're DARKZONE!
	//
	lda #%11111111
	sta sprites.enable_bits
	// lets set the colors of the sprites
	.for (var i = 0; i < 8; i++) {
		lda #GRAY
		sta sprites.colors + i
	}


	// set the ghostbyte which will be used in the transition below by the VIC to black
	lda #$ff
	sta $3fff




loop:

	ldx #0
loop_wait: 
	dex
	bne loop_wait

	ldx #0
loop_wait2: 
	dex
	bne loop_wait2

	ldx #0
loop_wait3: 
	dex
	bne loop_wait3

	jsr animate_sprites
	jsr update_sprite_pointers_scroll_text


	jmp loop


//
// Bitmap mode at scan line 0
//
irq0: {
	irq_start(end)

	inc framecount

  //  +------+-------+----------+-------------------------------------+
  //  | BITS |  BANK | STARTING |  VIC-II CHIP RANGE                  |
  //  |      |       | LOCATION |                                     |
  //  +------+-------+----------+-------------------------------------+
  //  |  00  |   3   |   49152  | ($C000-$FFFF)*                      |
  //  |  01  |   2   |   32768  | ($8000-$BFFF)                       | <<<<< SETS THIS BANK
  //  |  10  |   1   |   16384  | ($4000-$7FFF)*                      |
  //  |  11  |   0   |       0  | ($0000-$3FFF) (DEFAULT VALUE)       |
  //  +------+-------+----------+-------------------------------------+
  SwitchVICBank(vic_bank_bitmap)
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
  //  |  0011XXXX  |   3072  |  $0C00-$0FFF, 3072-4095.              | <<<<<< SETS THIS SCREEN MEMORY 
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
  SetScreenMemory(screen_memory_bitmap - vic_base_bitmap)
  // Set location of bitmap.
  //
  // Args:
  //    address: Address relative to VIC-II bank address.
  //             Valid values: $0000 (bitmap at $0000-$1FFF)
  //                           $2000 (bitmap at $2000-$3FFF) <<<<<< SETS THIS BITMAP MEMORY
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
  //  |  1000XXXX  |   8192  |  $2000-$23FF, 8192-9215.              | <<<<<< SETS THIS BIMAP MEMORY 
  //  |  1001XXXX  |   9216  |  $2400-$27FF, 9216-10239.             |  <<
  //  |  1010XXXX  |  10240  |  $2800-$2BFF, 10240-11263.            |  <<
  //  |  1011XXXX  |  11264  |  $2C00-$2FFF, 11264-12287.            |  <<
  //  |  1100XXXX  |  12288  |  $3000-$33FF, 12288-13311.            |  <<
  //  |  1101XXXX  |  13312  |  $3400-$37FF, 13312-14335.            |  <<
  //  |  1110XXXX  |  14336  |  $3800-$3BFF, 14336-15359.            |  <<
  //  |  1111XXXX  |  15360  |  $3C00-$3FFF, 15360-16383.            |  <<
  //  +------------+---------+---------------------------------------+
  SetBitmapAddress(bitmap_address_bitmap - vic_base_bitmap)
  // 
  // This following map is the reference to the bank setup that has been done
  // Use this as a reference in later sections when configuring screen memory
  //
  //  +------+-------+----------+------------------------------------+
  //  | BITS |  BANK | STARTING |  VIC-II CHIP RANGE                 |
  //  |      |       | LOCATION |                                    |
  //  +------+-------+----------+------------------------------------+
  //  |  00  |   3   |   49152  | ($C000-$FFFF)*                     |
  //  |  01  |   2   |   32768  | ($8000-$BFFF)                      | <<<<< SETS THIS BANK
  //  |  10  |   1   |   16384  | ($4000-$7FFF)*                     |
  //  |  11  |   0   |       0  | ($0000-$3FFF) (DEFAULT VALUE)      |
  //  +------+-------+----------+------------------------------------+
  //
  //  +------------+-------------------------------------------------+
  //  |            |                     LOCATION*                   |
  //  |    BITS    +---------+---------------------------------------+
  //  |            | DECIMAL |                  HEX                  |
  //  +------------+---------+---------------------------------------+
  //  |  0000XXXX  |      0  |  $0000-$03FF, 0-1023.                 | <<<<<< TEXTMODE SCREEN MEMORY. Size: 1kb
  //  |  0001XXXX  |   1024  |  $0400-$07FF, 1024-2047.   (DEFAULT)  | (((((( SPRITE MEMORY
  //  |  0010XXXX  |   2048  |  $0800-$0BFF, 2048-3071.              | (((((( CUSTOM FONT
  //  |  0011XXXX  |   3072  |  $0C00-$0FFF, 3072-4095.              | <<<<<< BITMAP MODE SCREEN MEMORY. Size: 1kb
  //  |  0100XXXX  |   4096  |  $1000-$13FF, 4096-5119.              | ROM IMAGE in BANK 0 & 2 (default)
  //  |  0101XXXX  |   5120  |  $1400-$17FF, 5120-6143.              |  <<
  //  |  0110XXXX  |   6144  |  $1800-$1BFF, 6144-7167.              | ROM IMAGE in BANK 0 & 2 (default)
  //  |  0111XXXX  |   7168  |  $1C00-$1FFF, 7168-8191.              |  <<
  //  |  1000XXXX  |   8192  |  $2000-$23FF, 8192-9215.              | <<<<<< BIMAP MEMORY 
  //  |  1001XXXX  |   9216  |  $2400-$27FF, 9216-10239.             |  <<
  //  |  1010XXXX  |  10240  |  $2800-$2BFF, 10240-11263.            |  <<
  //  |  1011XXXX  |  11264  |  $2C00-$2FFF, 11264-12287.            |  <<
  //  |  1100XXXX  |  12288  |  $3000-$33FF, 12288-13311.            |  <<
  //  |  1101XXXX  |  13312  |  $3400-$37FF, 13312-14335.            |  <<
  //  |  1110XXXX  |  14336  |  $3800-$3BFF, 14336-15359.            |  <<
  //  |  1111XXXX  |  15360  |  $3C00-$3FFF, 15360-16383.            |  <<
  //  +------------+---------+---------------------------------------+
  //
  //  +--+-------+----+----+----+----+----+----+----+----+------------------------+
  //  | #| Adr.  |Bit7|Bit6|Bit5|Bit4|Bit3|Bit2|Bit1|Bit0| Function               |
  //  +--+-------+----+----+----+----+----+----+----+----+------------------------+
  //  |24| $d018 |VM13|VM12|VM11|VM10|CB13|CB12|CB11|  - | Memory pointers        |
  //  +--+-------+----+----+----+----+----+----+----+----+------------------------+
  //  ^URL: http://www.zimmers.net/cbmpics/cbm/c64/vic-ii.txt
  //
  //  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
  //  | # | Adr.| Bit7 | Bit6 | Bit5 | Bit4 |   Bit3   |   Bit2   |   Bit1   |  Bit0  | Function               |
  //  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
  //  |24 |$D018|  Screen Pointer(A13-A10)  | Bitmap/Charset Pointer(A13-A11)| unused |                        |
  //  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
  //  ^URL: http://www.oxyron.de/html/registers_vic2.html
  //
  SetHiresBitmapMode()

	// Lets figure out what X & Y scroll offsets we need to use this time around
	ldy scroll_offset_1		// Lets load the scroll offset which is continously updated
	lda $d011 				// Load VIC-II Control register 1
	and #%11111000 			// Lets zero out YSCROLL ( https://www.c64-wiki.com/wiki/Page_208-211 )
	ora y_coords, Y 		// Lets OR what is left of the $d011 read; e.g. add in the Y value from our calculated table
	sta $d011  				// Lets store that back to $d011; e.g. set then the YSCROLL value
	lda $d016 				// Load VIC-II Control register 2
	and #%11111000 			// Lets zero out XSCROLL ( https://www.c64-wiki.com/wiki/Page_208-211 )
	ora x_coords, Y 		// Lets OR what is left of the $d016 read; e.g. add in the X value from our calculated table
	sta $d016 				// Lets store that back to $d016; e.g. set then the XSCROLL value

	iny 					// we don't iny here as we will need to load the right X & Y scroll value again in the interrupt further down.. 
	sty scroll_offset_1 	// we don't have to store it yet either.. as we will do that further down as well 

	jsr scroller_update_char_row_yscroll_1

	// second scroller
	jsr scroller_update_char_row_2
	jsr colwash
	jsr reverse_colwash

	// iterate through the play routine
	jsr music.play 


	irq_end(irq1, textscroller_scanline)
end:
	rti
}

//
// Textmode mode at scan line 50+(16*8) = 178
//
irq1: {
	irq_start(end)

	// Bits #0-#2: Vertical raster scroll.
	// Bit #3: Screen height; 0 = 24 rows; 1 = 25 rows.
	// Bit #4: 0 = Screen off, complete screen is covered by border; 1 = Screen on, normal screen contents are visible.
	// Bit #5: 0 = Text mode; 1 = Bitmap mode.
	// Bit #6: 1 = Extended background mode on.
	// Bit #7: Read: Current raster line (bit #8).
	//         Write: Raster line to generate interrupt at (bit #8).
  //
  //  +--+-------+----+----+----+----+----+----+----+----+------------------------+
  //  | #| Adr.  |Bit7|Bit6|Bit5|Bit4|Bit3|Bit2|Bit1|Bit0| Function               |
  //  +--+-------+----+----+----+----+----+----+----+----+------------------------+
  //  |17| $d011 |RST8| ECM| BMM| DEN|RSEL|    YSCROLL   | Control register 1     |
  //  +--+-------+----+----+----+----+----+--------------+------------------------+
	lda #%00011011 			// Default: $1B, %00011011
	sta $d011

	// Screen control register #2. Bits:
	// Bits #0-#2: Horizontal raster scroll.
	// Bit #3: Screen width; 0 = 38 columns; 1 = 40 columns.
	// Bit #4: 1 = Multicolor mode on.
  //
  //  +--+-------+----+----+----+----+----+----+----+----+------------------------+
  //  | #| Adr.  |Bit7|Bit6|Bit5|Bit4|Bit3|Bit2|Bit1|Bit0| Function               |
  //  +--+-------+----+----+----+----+----+----+----+----+------------------------+
  //  |22| $d016 |  - |  - | RES| MCM|CSEL|    XSCROLL   | Control register 2     |
  //  +--+-------+----+----+----+----+----+----+----+----+------------------------+
	lda framecount
	and #7
	eor #7 					    // xor bits 0-2 and leave bit 3 zero for 38 column mode
	sta $d016

	lda #%00000010      // Default: $C8, %11001000
	sta $d018

	irq_end(irq2, bitmap_scanline_2)
end:
	rti
}

//
// Bitmap mode at scan line 50+(16*8)+8 = 186
//
irq2: {
	irq_start(end)

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

//  SwitchVICBank(vic_bank_bitmap)
//  SetScreenMemory(screen_memory_bitmap - vic_base_bitmap)
//  SetBitmapAddress(bitmap_address_bitmap - vic_base_bitmap)
//  SetHiresBitmapMode()

	lda #%00111011
	sta $d011

	lda #%00001000
	sta $d016

	lda #56
	sta $d018

	irq_end(irq3, second_scroller_start)
end:
	rti
}


//
// Textmode mode at scan line TBC
//
irq3: {
	irq_start(end)

	lda #%00011011
	sta $d011

	lda framecount
	and #7
	eor #7
	sta $d016

	lda #%00000010
	sta $d018

	irq_end(irq4, second_scroller_end)
end:
	rti
}


//
// Bitmap mode at scan line TBC
//
irq4: {
	irq_start(end)

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	lda #%00111011
	sta $d011

	lda #%00001000
	sta $d016

	lda #56
	sta $d018

	irq_end(irq0, bitmap_scanline_1)
end:
	rti
}

//============================ 
// Color wash for the scroller
// 
// Color memory can NOT move. It is always located at locations 55296
// ($D800) through 56295 ($DBE7). E.g. we can move the screen memory through switching
// banks and what not, but the color memory does not. See links for further details. 
// URL: http://www.zimmers.net/cbmpics/cbm/c64/c64prg.txt
// URL: http://tnd64.unikat.sk (The Colour Washing routine)
//========================== 
colwash: {            
	lda colour+$00 
	sta colour+$28 
	ldx #$00 
cycle:                
	lda colour+$01,x 
	sta colour+$00,x 
	lda colour,x 
	sta $d800+17*40,x 
	sta $d800+18*40,x 
	inx 
	cpx #$28 
	bne cycle 
	rts
}

reverse_colwash: {
	lda colour_2+$28
	sta colour_2+$00
	ldx #$28
cycle:
	lda colour_2-$01,x
	sta colour_2+$00,x
	lda colour_2,x
	sta $d800+19*40,x 
	sta $d800+20*40,x 
	dex
	bne cycle
	rts
}

// This routine checks the sprites direction of travel and whether the sprites moved past the point when their sprite
// pointers can be replaced to present the viewer with a different text
//
check_sprites_travel_and_update_replacement_pointers: {

	// First we need to check whether the sprites are moving left or right. We want to change behind
	// the logo when they are not visible.. and hence we are chaing that the sprites are moving to the right
	// and that the sprite (x) coordinate > 150 (which we know is behind the logo)

	// this .for statement will build 8 code blocks in sequence in machine code. it will build the reference/address pointers based on the i variable.. 
	.for (var i = 0; i < 8; i++) {

		ldx current_coords + i 				// lets load the offset value 
		// lets load the current iterations x-coordinates and store to prepare for comparison against previous location to determine direction of travel
		lda x_hi_coordinates, x
		sta num1hi
		lda x_lo_coordinates, x
		sta num1lo

		// lets load the previous coordinates and store to prepare for comparison against previous location to determine direction of travel
		ldx #i
		lda current_coords_x_hi, x
		sta num2hi
		lda current_coords_x_lo, x
		sta num2lo

		// we now have the current and previous' sprites position and can do the comparison of x-coordinates to determine direction of travel & set sprite priority

		// lets find out whether the sprites are moving left or right. 
		// we will do a subtraction to find the right number; e.g. 
		// 
		// if (num1_current) > (num2_previous) then sprites are moving to the right
		// if (num1_current) < (num2_previous) then sprites are moving to the left
		//
		lda num1hi 							// compare high bytes
		cmp num2hi
		bcc sprite_moving_left				// if num1h < num2h then num1 < num2 .... use BCC to branch if the contents of the accumulator is less than that of the memory address, and BCS to branch if the accumulator holds a number equal to or larger than that in memory.
		bne sprite_moving_right					// if num1h <> num2h then num1 > num2 (so num1 >= num2)
		lda num1lo 							// compare low bytes
		cmp num2lo
		bcs sprite_moving_right					// if num1l >= num2l then num1 >= num2
	sprite_moving_left:
		// test complete - bracnhed here is NUM1 < NUM2 and we know the sprite is moving to the left
		// we can now set the on/off for directional move
		//// we need to store the output of the sprite direction test for the sprite text update
		//sprite_direction_test:	.fill 8, 0 			// 0 moving left, and 1 moving right
		lda #0
		sta sprite_direction_test, x
		//jmp sprite_direction_move_test_done
		// we know that the direction of travel is left, it is on the bottom half of the logo and we cannot replace the text, so lets set the replace to 0 and move on
		//// we need to store whether the sprite pointer can be replaced given the sprites x coordinate now is under the logo
		//sprite_pointer_replace_test:	.fill 8, 0 			// 0 can't replace, 1 can replace
		lda #0
		sta sprite_pointer_replace_test, x
		jmp sprite_checks_reset_coordinate_done
	sprite_moving_right:
		// test complete - branched here if NUM1 >= NUM2 and we know the sprite is moving to the right
		lda #1
		sta sprite_direction_test, x

		// we now know which direction the sprites are moving, and if it is moving to the right.. we need to check if it's
		// reached the specific coordinate where the sprite is behind the logo and we can update the replace tag
		ldx current_coords + i 				// lets load the offset value 
		ldy x_hi_coordinates, x 			// lets load the lo byte of the current coordinate - don't need the hi byte as we know we are < 255
		// we now have current in A and location in Y. Lets compare

		cpy #145 							// we know the coordinate in the table is 145 (decimal) so we check against that table		
		bne sprite_less_than_number			// branch is current < #145 
		// we know that the number is the same and we are ready to update the replace tag
		lda #1
		sta sprite_pointer_replace_test, x
		jmp sprite_checks_done

	sprite_less_than_number:
		// test complete - branched here is NUM1 < NUM2 and we know that the sprite is in the top left section and approaching, but less than 150 still & do not change
		//sprite_pointer_replace_test:	.fill 8, 0 			// 0 can't replace, 1 can replace
		lda #0
		sta sprite_pointer_replace_test, x
	sprite_checks_done:
		// we now have both direction of travel AND whether the sprite pointer can be replaced set up ready for the routine to do so (if required)
		// though we must also check whether they have reached the "other" side where we have to reset the replacement tag in preparation for the next iteration

		// we now know which direction the sprites are moving, and if it is moving to the right.. we need to check if it's
		// reached the specific coordinate where the sprite is behind the logo and we can update the replace tag
		ldy x_hi_coordinates, x 			// lets load the lo byte of the current coordinate - don't need the hi byte as we know we are < 255
		// we now have current in A and location in Y. Lets compare

		cpy #177 								// we know the coordinate in the table is 145 (decimal) so we check against that table		
		bne sprite_checks_reset_coordinate_done	// branch is current < #177
		// we know that the number is the same and we are ready to update the replace tag
		lda #0
		sta sprite_pointer_replace_test, x
		jmp sprite_checks_reset_coordinate_done

	sprite_checks_reset_coordinate_done:

	}
	rts
}

// This routine checks the sprites direction of travel and whether the sprites moved past the point when their sprite
// pointers can be replaced to present the viewer with a different text
update_sprite_pointers_scroll_text: {
	.for (var i = 0; i < 8; i++) {

		ldx #i 

		// the table to check is below as it holds the value whether sprite pointers can be updated - 0 can't replace, 1 can replace
		// the logic here is that we have to check each individual sprite pointer / replacement value separately as some sprites may not have reached the logo yet.. and should be left alone.. 
		ldx #i
		lda sprite_pointer_replace_test, x
		// A now holds the 0 or 1 that notes whether the sprite should be updated (or not)
		// LDA NumA    Read the value "Number"
		// BEQ Equal   Go to label "Equal" if "Number" = 0
		// ...         Execution continues here if "Number" <> 0		
		beq sprite_should_not_be_updated
		// value = 1 and should be updated
		// this table holds the current "iteration" of the sprite pointer; e.g. which "value" (character 'pointer') that the current sprite should point to
		// sprite_pointer_iteration:		.fill 8, 0			// right now this refers to the iteration number of what sprite text to display
		// lets see which iteration we are at; e.g for this character, which "offset value do we need"
		ldx #i
		lda sprite_pointer_iteration, x 			// we have the iteration - e.g. 0,1,2,3,4,5... which which scroll text to show
		sec
		sta T1
		lda #8
		sta T2
		jsr multiply_8bit_unsigned
		// we only need the lower byte (hi/lo) as we know we wont need an offset >256
		ldx PRODUCT

		// we have the table increment in X now (0,8,16..), and we now need to add in i which has the sprite number iteration
		txa
		clc
		adc #i
		tax 

		lda sprite_scroll_text, x
		// A now has the byte value that we need the sprite pointer to be updated to
		// we know that the sprite pointers are consequtive bytes in a fixed position, so can use the offset value & code only in here is we KNOW we have to change it
		//.var sprite_pointer_0 = screen_memory + $3f8 // 1016
		sta sprite_pointer_0 + i

		// we also have to increment the sprite_pointer_iteration table as that is used to determine which sprite pointer to update with
		ldx #i
		lda sprite_pointer_iteration, x
		clc
		adc #1
		sta sprite_pointer_iteration, x

		// we have to check whether the sprite iteration counter has exceeded the number of text "rounds" that we will display.. if so, we reset and start again
		ldx #i
		lda sprite_pointer_iteration, x
		cmp sprite_scroll_text_iterations
		bcs sprite_scroll_text_iterations_reset_to_zero 	// branches to time_to_set_the_reset_flag when (sprite_pointer_iteration, x) >= (#sprite_scroll_text_iterations)
		jmp sprite_scroll_text_iterations_continue
	sprite_scroll_text_iterations_reset_to_zero:
		lda #0
		sta sprite_pointer_iteration, x
	sprite_scroll_text_iterations_continue:

	sprite_should_not_be_updated:

	end:
	}
	rts
}



//	Sprite 	x coordinate 	y coordinate
//	#0 		53248/$D000 	53249/$D001
//	#1 		53250/$D002 	53251/$D003
//	#2 		53252/$D004 	53253/$D005
//	#3 		53254/$D006 	53255/$D007
//	#4 		53256/$D008 	53257/$D009
//	#5 		53258/$D00A 	53259/$D00B
//	#6 		53260/$D00C 	53261/$D00D
//	#7 		53262/$D00E 	53263/$D00F 
// The ninth and most significant bit for each of the eight sprites are "gathered" in address 53264/$D010; 
// the least significant bit here corresponds to sprite #0, and the most significant bit to sprite #7. 
//
// This was set up earlier.. which is used as a reference to the sprites position update below .. 
//
// .const VIC2 = $d000
// .namespace sprites {
//   .label positions = VIC2
//   .label enable_bits = VIC2 + 21
//   .label colors = VIC2 + 39
//   .label pointers = screen_memory + 1024 - 8
// }
//
// .. you can see in the coordinate reference details above that sprites.positions point to sprite #0 position data
//
// The following are are now the sprites.positions pointers as they are traversing this loop
//
//	Sprite 	x coordinate 	y coordinate 	character sprite
//	#0 		53248/$D000 	53249/$D001     Character D
//	#1 		53250/$D002 	53251/$D003     Character A
//	#2 		53252/$D004 	53253/$D005     Character R
//	#3 		53254/$D006 	53255/$D007     Character K
//	#4 		53256/$D008 	53257/$D009     Character Z
//	#5 		53258/$D00A 	53259/$D00B     Character O
//	#6 		53260/$D00C 	53261/$D00D     Character N
//	#7 		53262/$D00E 	53263/$D00F     Character E
//
// These are the coordinates that are which all sprites follow; e.g. the same path.. but 'following each other'
// 
//  181
//  183.94494742274946
//  186.88812091929017
//  189.82774763196008
//  192.76205683954728
//  195.68928102390595
//  198.60765693464342
//  201.51542665123614
//  ...
//
// There is an offset being used to address the right byte position variables (current_coords), which is pre-calc'ed
// to have the 'reverse' pointer effect. E.g. when loading the coordinate, it's pulling the 8th byte out, and then as 
// you traverse the table, it is reducing to 7,6,5 etc. and as such you position the sprites in the right order ..
//
// // This table holds the the reference point (table offset) for each one of the 8 sprites. This
// // is required as each sprite is using an offset (x,y) value to make the appearance of following
// // each other ... 
// current_coords:  .fill 8, 10*[7-i] 		// produces this list, which is used as a sprite coordinate reference: 70,60,50,40,30,20,10,0
// 
// .. this code works as the .for loop below expands into machine code section for each sprite
//
// Re moving sprites behind the logo - there is one challenge here that I originally did not know. 
// https://codebase64.org/doku.php?id=base:spriteintro has a table like this: 
//
//      MxDP=0:
//      
//             +-----------------------+
//             |  Background graphics  |  low priority
//           +-----------------------+ |
//           |  Foreground graphics  |-+
//         +-----------------------+ |
//         |       Sprite x        |-+
//       +-----------------------+ |
//       |     Screen border     |-+
//       |                       |   high priority
//       +-----------------------+
//      
//       MxDP=1:
//      
//             +-----------------------+
//             |  Background graphics  |  low priority
//           +-----------------------+ |
//           |       Sprite x        |-+
//         +-----------------------+ |
//         |  Foreground graphics  |-+
//       +-----------------------+ |
//       |     Screen border     |-+
//       |                       |   high priority
//       +-----------------------+
//
// In the original version of the demo, the backround picture was "switched" and sprites did not move behind.
// So checking whether colors can be switched. 
//
animate_sprites: {

	ldy #0
	// this .for statement will build 8 code blocks in sequence in machine code. it will build the reference/address pointers based on the i variable.. 
	.for (var i = 0; i < 8; i++) {

		ldx current_coords + i 				// lets load the offset value 
		lda x_hi_coordinates, x
		sta sprites.positions + 2*i + 0 	// this is storing A (now x_hi) into the right byte (see above)
		lda y_coordinates, x
		sta sprites.positions + 2*i + 1 	// this is storing A (now x_lo) into the right byte (see above)

		// based on which sprite we are on, we will load the right bitmask and store to set or clear the bit that enables sprites to move >256 pixels (e.g. 320x200)

		lda x_lo_coordinates, x 			// lets load the msb for this sprite >> 0=not set, 1=set
		bne sprite_set 						// branch is not #$00 (e.g. the msb has to be set)

		lda $d010
		and sprite_clear_table, y 			// clear
		jmp sprite_set_get_done
	sprite_set:
		lda $d010
		ora sprite_set_table, y 			// set
	sprite_set_get_done:
		sta $d010

		// we have to temporarily store X, Y & A
		stx temp_data_bytes + i + 0 
		sty temp_data_bytes + i + 1
		sta temp_data_bytes + i + 2

		////// we can use the same logic to check whether sprite is behind or in front of the logo [start]

		// lets load the current iterations x-coordinates and store to prepare for comparison against previous location to determine direction of travel
		lda current_coords_x_hi, y
		sta num2hi
		lda current_coords_x_lo, y
		sta num2lo
		// lets load the previous coordinates and store to prepare for comparison against previous location to determine direction of travel
		lda x_hi_coordinates, x
		sta num1hi
		lda x_lo_coordinates, x
		sta num1lo
		// we now have the current and previous' sprites position and can do the comparison of x-coordinates to determine direction of travel & set sprite priority

		lda num1hi 							// compare high bytes
		cmp num2hi
		bcc sprite_set_front				// if num1h < num2h then num1 < num2 .... use BCC to branch if the contents of the accumulator is less than that of the memory address, and BCS to branch if the accumulator holds a number equal to or larger than that in memory.
		bne sprite_set_back					// if num1h <> num2h then num1 > num2 (so num1 >= num2)
		lda num1lo 							// compare low bytes
		cmp num2lo
		bcs sprite_set_back					// if num1l >= num2l then num1 >= num2
	sprite_set_front:
		// test complete - bracnhed here is NUM1 < NUM2
		// E.g. sprites moving left & we want the sprite to be going IN FRONT OF the logo
		lda $d01b
		and sprite_clear_table, y 			// clear --> we have to clear the bit to make sprite move behind logo
		sta $d01b
		jmp sprite_set_front_back_done
	sprite_set_back:
		// test complete - branched here if NUM1 >= NUM2
		// E.g. sprites moving right & we want the sprite to be going BEHIND the logo
		// We have to clear the mask sprite mask $D01B to have the sprite go behind the logo
		lda $d01b
		ora sprite_set_table, y 			// set --> we have to set the bit to make sprite mode in front of logo
		sta $d01b
		// we have set the correct bitmask to enable the sprite to move behind logo 

		//  i=243.     Dec: x=139. y=73     Hex: x=8b. y=49
		//  i=244.     Dec: x=142. y=73     Hex: x=8e. y=49
		//  i=245.     Dec: x=145. y=73     Hex: x=91. y=49 <<< Lets increment the resetflag here
		//  i=246.     Dec: x=148. y=73     Hex: x=94. y=49 <<< Lets 
		//  i=247.     Dec: x=152. y=73     Hex: x=98. y=49
		//  i=248.     Dec: x=155. y=73     Hex: x=9b. y=49
		// lets check whether the x coordinate has reached the location behind the logo where the sprite pointer can be replaced
		// worth making note here that we are checking an 8 bit number. hence when the current_coordinate >255 it loops around and will then not branch
		lda current_coords_x_hi, y
		cmp #145
		bcs time_to_set_the_reset_flag	// branches to time_to_set_the_reset_flag when (current_coords_x_hi, y) >= (#145)
		// lets make sure the reset flag is not set as we have not reached #145 yet
		lda #0
		sta sprite_pointer_replace_test, y
		jmp time_to_set_the_reset_flag_DONE
	time_to_set_the_reset_flag:
		// we know that it's now reached #145 and it's time to set the reset flag
		lda #1
		sta sprite_pointer_replace_test, y
	time_to_set_the_reset_flag_DONE:


		lda current_coords_x_hi, y
		cmp #148
		bcs time_to_reset_the_reset_flag	// branches to time_to_set_the_reset_flag when (current_coords_x_hi, y) >= (#148)
//				lda #1
//				sta sprite_pointer_replace_test, y
		jmp time_to_reset_the_reset_flag_DONE
	time_to_reset_the_reset_flag:
		// we know that it's now reached #148 and it's time to reset the reset flag as the sprite pointer has already been updated in another routine
		lda #0
		sta sprite_pointer_replace_test, y
	time_to_reset_the_reset_flag_DONE:


	sprite_set_front_back_done:

		// we have to storeg & update the current sprite x-coordinated to prepare for the next rounds comparison to determine direction of travel
		ldx current_coords + i 				// lets load the offset value 
		lda x_hi_coordinates, x
		sta current_coords_x_hi + i
		lda x_lo_coordinates, x 			// lets load the msb for this sprite >> 0=not set, 1=set
		sta current_coords_x_lo + i

		////// we can use the same logic to check whether sprite is behind or in front of the logo [stop]

		// we have to restore X, Y & A
		ldx temp_data_bytes + i + 0 
		ldy temp_data_bytes + i + 1
		lda temp_data_bytes + i + 2

		iny
		inx
		cpx #COORDINATES_COUNT 				// have to check whether we have come to the end of the coordinate table. if so, reset to 0
		bne end
		ldx #0 
	end:
		txa
		sta current_coords + i
	}
	rts
}



//animate_sprites: {
//
//	ldy #0
//	.for (var i = 0; i < 8; i++) {
//		ldx current_coords + i
//		lda x_hi_coordinates, x
//		sta sprites.positions + 2*i + 0
//		lda y_coordinates, x
//		sta sprites.positions + 2*i + 1
//
//		lda x_lo_coordinates, x 		// lets load the msb for this sprite >> 0=not set, 1=set
//		bne sprite_set 					// branch is not #$00 (e.g. the msb has to be set)
//
//		lda $d010 						// clear
//		and sprite_clear_table, y
//		jmp sprite_set_get_done
//	sprite_set:
//		lda $d010
//		ora sprite_set_table, y 		// set
//	sprite_set_get_done:
//		sta $d010
//
//		iny
//		inx
//		cpx #COORDINATES_COUNT
//		bne end
//		ldx #0 
//	end:
//		txa
//		sta current_coords + i
//	}
//	rts
//
//}



//----------------------------------------------------------
//----------------------------------------------------------
// These are values for YSCROLL and what happens to the text
// scroller when we shift to text mode after hires gfx mode
// 
// We need to move the text mode scroller based on the YSCROLL
// value for $d011. That's to make sure its in the right 
// position when we change the screen mode in the interrupt 
// call.. the following applies based on manual tests:
//
// 0 = scroll is in the right position
// 1 = scroll is in the right position
// 2 = scroll shows garbage text
// 3 = scroll is in the right position
// 4 = scroll is 1 line below and needs to move 1 line up
// 5 = scroll is 1 line below and needs to move 1 line up
// 6 = scroll is 1 line below and needs to move 1 line up
// 7 = scroll is 1 line below and needs to move 1 line up
//----------------------------------------------------------

//
// Given we are changing YSCROLL values and this causes a glitch (VIC issue!), we need to correct the line that we are printing the scroller at
// dependent on this value. From manual testing, YSCROLL >=4 causes a glitch which is what we are checking for above. 
// To correct for this, lets store the scroll characters in a non-visible area of the screen (remember raster split config above), then we 
// copy in the characters to scroll in line 17 or 18 dependent on that value. That way we have a non visible line in character memory that is 
// the basis for the scroller moving at all times, but we move those character to lines 17 or 18 dependent on the YSCROLL value. That way we 
// give the illusion that the scroller stays at the same line all the time, where in fact we have to do all of this manual work to coorect the 
// VIC glitch.
//
// The following two scroll_update_char_row routines do the hard work outlined above. 
//

scroller_update_char_row_yscroll_1: {
	lda framecount
	and #7
	bne noscroll

	ldx #$00
moveline:
	// lets load the character from the non visible line 
	lda (text_mode_screen_memory)+10*40+1, x
	sta (text_mode_screen_memory)+10*40, x
	sta (text_mode_screen_memory)+17*40, x
	sta (text_mode_screen_memory)+18*40, x
	inx
	cpx #39
	bne moveline

	clc
	lda charpos
	adc #<scrolltext
	//sta $20
	sta charpos_temp_lo
	lda charpos+1
	adc #>scrolltext
	//sta $21
	sta charpos_temp_hi

	ldy #0
	//lda ($20),y
	lda (charpos_temp_lo),y
	// lets pull the next character into the visible & non-visible buffers
	sta (text_mode_screen_memory)+10*40+39
	sta (text_mode_screen_memory)+17*40+39
	sta (text_mode_screen_memory)+18*40+39

	add16_imm8(charpos, 1)

	// wrap around for scroll char pos
	lda charpos+0
	cmp #<(scrolltextend-scrolltext)
	bne noscroll
	lda charpos+1
	cmp #>(scrolltextend-scrolltext)
	bne noscroll
	lda #0
	sta charpos
	sta charpos+1
noscroll:
	rts
}

scroller_update_char_row_yscroll_2: {
	lda framecount
	and #7
	bne noscroll

	ldx #$00
moveline:
	// lets load the character from the non visible line 
	lda (text_mode_screen_memory)+10*40+1, x
	sta (text_mode_screen_memory)+10*40, x
	sta (text_mode_screen_memory)+17*40, x
	sta (text_mode_screen_memory)+18*40, x
	inx
	cpx #39
	bne moveline

	clc
	lda charpos
	adc #<scrolltext
	//sta $20
	sta charpos_temp_lo
	lda charpos+1
	adc #>scrolltext
	//sta $21
	sta charpos_temp_hi

	ldy #0
	//lda ($20),y
	lda (charpos_temp_lo),y
	// lets pull the next character into the visible & non-visible buffers
	sta (text_mode_screen_memory)+10*40+39
	sta (text_mode_screen_memory)+17*40+39
	sta (text_mode_screen_memory)+18*40+39

	add16_imm8(charpos, 1)

	// wrap around for scroll char pos
	lda charpos+0
	cmp #<(scrolltextend-scrolltext)
	bne noscroll
	lda charpos+1
	cmp #>(scrolltextend-scrolltext)
	bne noscroll
	lda #0
	sta charpos
	sta charpos+1
noscroll:
	rts
}



//scroller_update_char_row: {
//	lda framecount
//	and #7
//	bne noscroll
//
//	ldx #$00
//moveline:
//	lda (text_mode_screen_memory)+18*40+1, x
//	sta (text_mode_screen_memory)+18*40, x
//	sta (text_mode_screen_memory)+17*40, x
//	inx
//	cpx #39
//	bne moveline
//
//	clc
//	lda charpos
//	adc #<scrolltext
//	sta $20
//	lda charpos+1
//	adc #>scrolltext
//	sta $21
//
//	ldy #0
//	lda ($20),y
//	sta (text_mode_screen_memory)+18*40+39
//	sta (text_mode_screen_memory)+17*40+39
//
//	add16_imm8(charpos, 1)
//
//	// wrap around for scroll char pos
//	lda charpos+0
//	cmp #<(scrolltextend-scrolltext)
//	bne noscroll
//	lda charpos+1
//	cmp #>(scrolltextend-scrolltext)
//	bne noscroll
//	lda #0
//	sta charpos
//	sta charpos+1
//noscroll:
//	rts
//}

//
// Second text scroller
//
scroller_update_char_row_2: {
	lda framecount
	and #2
	bne noscroll

	ldx #$00
moveline:
	lda (text_mode_screen_memory)+20*40+1, x
	sta (text_mode_screen_memory)+20*40, x
	sta (text_mode_screen_memory)+19*40, x
	inx
	cpx #39
	bne moveline

	clc
	lda charpos_2
	adc #<scrolltext_2
	sta $20
	lda charpos_2+1
	adc #>scrolltext_2
	sta $21

	ldy #0
	lda ($20),y
	sta (text_mode_screen_memory)+20*40+39
	sta (text_mode_screen_memory)+19*40+39

	add16_imm8(charpos_2, 1)

	// wrap around for scroll char pos
	lda charpos_2+0
	cmp #<(scrolltextend_2-scrolltext_2)
	bne noscroll
	lda charpos_2+1
	cmp #>(scrolltextend_2-scrolltext_2)
	bne noscroll
	lda #0
	sta charpos_2
	sta charpos_2+1
noscroll:
	rts
}


// These are (x,y) coordinate tables in (320x200) space for the 8 'logo' sprites: DARKZONE
// Have to use two sets of byte tables for X given the screen size is 320 pixels wide. 
// These tables are used in the animate_sprites routine to move the sprites acrroding to 
// these generates screen coordinates. 
x_hi_coordinates:
	.fill COORDINATES_COUNT, <(position(i, COORDINATES_COUNT).getX())
x_lo_coordinates:
	.fill COORDINATES_COUNT, >(position(i, COORDINATES_COUNT).getX())


//.for (var i = 0; i < 256; i++) {
//	.print "i="+i+". x="+floor(position(i, COORDINATES_COUNT).getX())+". y="+floor(position(i, COORDINATES_COUNT).getY())
//}

.for (var i = 0; i < 256; i++) {
	.print "i="+i+".     Dec: x="+floor(position(i, COORDINATES_COUNT).getX())+". y="+floor(position(i, COORDINATES_COUNT).getY())+"     Hex: x="+toHexString(position(i, COORDINATES_COUNT).getX())+". y="+toHexString(position(i, COORDINATES_COUNT).getY())
}




//
// CALCLATE THE SPRITE PRIORITY BYTE THAT HAS TO BE SET FOR EACH X POSITION
// 
// Logic here is that we traverse the pre-calc x positions and determine whether the sprite is moving left or right. 
// if is it moving right, we know (based on how we have set it up) that the characters need to go behind the logo
//
// example: sprite 0,2,4,6  behind background, using binary. other sprites in front
// lda #%01010101   
// sta $d01b 
//
//.for (var i = 0; i < 264; i++) {
//
//	.var BitMask = 0
//
//	.for (var x = 0; x < 8; x++) {
//
//
//		// stx sprite_pointer_0	// sprite pointer 0 = Character D
//		.if ( (position(i+1, COORDINATES_COUNT).getX()) >= (position(i+0, COORDINATES_COUNT).getX()) ) {
//				// x position of next coordinate is higher & moving right. set sprite to be BEHIND logog
//				.eval BitMask = BitMask | %10000000
//			} else {
//				.eval BitMask = BitMask | %00000000
//			}
//
//		// stx sprite_pointer_0	// sprite pointer 0 = Character D
//		// stx sprite_pointer_1	// sprite pointer 1 = Character A
//		// stx sprite_pointer_2	// sprite pointer 2 = Character R
//		// stx sprite_pointer_3	// sprite pointer 3 = Character K
//		// stx sprite_pointer_4	// sprite pointer 4 = Character Z
//		// stx sprite_pointer_5	// sprite pointer 5 = Character O
//		// stx sprite_pointer_6	// sprite pointer 6 = Character N
//		// stx sprite_pointer_7	// sprite pointer 7 = Character E
//
////		.if ( (position(i+2, COORDINATES_COUNT).getX()) >= (position(i+1, COORDINATES_COUNT).getX()) ) .eval BitMask = BitMask | %01000000
////		.if ( (position(i+3, COORDINATES_COUNT).getX()) >= (position(i+2, COORDINATES_COUNT).getX()) ) .eval BitMask = BitMask | %00100000
////		.if ( (position(i+4, COORDINATES_COUNT).getX()) >= (position(i+3, COORDINATES_COUNT).getX()) ) .eval BitMask = BitMask | %00010000
////		.if ( (position(i+5, COORDINATES_COUNT).getX()) >= (position(i+4, COORDINATES_COUNT).getX()) ) .eval BitMask = BitMask | %00001000
////		.if ( (position(i+6, COORDINATES_COUNT).getX()) >= (position(i+5, COORDINATES_COUNT).getX()) ) .eval BitMask = BitMask | %00000100
////		.if ( (position(i+7, COORDINATES_COUNT).getX()) >= (position(i+6, COORDINATES_COUNT).getX()) ) .eval BitMask = BitMask | %00000010
////		.if ( (position(i+8, COORDINATES_COUNT).getX()) >= (position(i+7, COORDINATES_COUNT).getX()) ) .eval BitMask = BitMask | %00000001
//
////		.print BitMask
//
//	}
//}
//
//.for (y = 0 ; y < 8 ; y++) {
//	.var BitMask = 0
//	.for (x = 0 ; x < 4 ; x++) {
//		.var RGB_Value = RawImage.getPixel(PixelPosX+x*2,PixelPosY+y)
//		.if ([RGB_Value!=BackgroundColor]&&[CharColors.containsKey(RGB_Value) != true]) {
//			.eval CharColors.put(RGB_Value,CharColors.keys().size())
//			.eval CharColors2.put(CharColors2.keys().size(),RGB_Value)
//		}
//		.if(CharColors.get(RGB_Value) == 1) .eval BitMask = BitMask | %10000000>>x*2
//		.if(CharColors.get(RGB_Value) == 2) .eval BitMask = BitMask | %01000000>>x*2
//		.if(CharColors.get(RGB_Value) == 3) .eval BitMask = BitMask | %11000000>>x*2
//	}
//	.eval BlockDataBMP.add(BitMask)
//}


// These are the extra values generated to 264 rather than 256
//  180.99999999999997
//  183.94494742274944
//  186.88812091929012
//  189.82774763196002
//  192.7620568395473
//  195.68928102390598
//  198.60765693464342
//  201.51542665123617
// >>> YES! We can use a second .position table with 264 values to then calculate the bit / byte setup for each X coordinate for all 8 sprites.. 

//  181
//  183.94494742274946
//  186.88812091929017
//  189.82774763196008
//  192.76205683954728
//  195.68928102390595
//  198.60765693464342
//  201.51542665123614
//  204.41083864193538
//  207.2921488188244
//  210.15762158839166
//  213.0055308969878
//  215.83416127053547
//  218.64180884786697
//  221.4267824070664
//  224.18740438419857
//  226.92201188381077
//  229.62895768059877
//  232.30661121163385
//  234.9533595585528
//  237.56760841911972
//  240.1477830675741
//  242.69232930318663
//  245.19971438645166
//  247.66842796235227
//  250.09698297014143
//  252.483916539092
//  254.82779086967523
//  257.12719409963745
//  259.38074115445323
//  261.58707458164224
//  263.744865368448
//  265.8528137423857
//  267.909649954176
//  269.9141350425951
//  271.86506158077816
//  273.7612544035284
//  275.60157131519276
//  277.3849037776774
//  279.11017757819
//  280.7763534763054
//  282.38242782996485
//  283.9274332000326
//  285.4104389330454
//  286.83055172180264
//  288.1869161434619
//  289.4787151748132
//  290.7051706844237
//  291.8655439013544
//  292.95913586016866
//  293.9852878219625
//  294.9433816711644
//  295.83284028786505
//  296.65312789545277
//  297.40375038334525
//  298.0842556046234
//  298.69423364838764
//  299.23331708667297
//  299.7011811957737
//  300.0975441518452
//  300.42216720066364
//  300.67485480144285
//  300.8554547446207
//  300.9638582435445
//  301
//  300.9638582435445
//  300.8554547446207
//  300.67485480144285
//  300.42216720066364
//  300.0975441518452
//  299.7011811957737
//  299.23331708667297
//  298.69423364838764
//  298.0842556046234
//  297.40375038334525
//  296.65312789545277
//  295.83284028786505
//  294.9433816711644
//  293.9852878219625
//  292.95913586016866
//  291.8655439013544
//  290.7051706844237
//  289.4787151748132
//  288.1869161434618
//  286.83055172180264
//  285.4104389330454
//  283.9274332000326
//  282.38242782996485
//  280.7763534763054
//  279.11017757819
//  277.3849037776774
//  275.60157131519276
//  273.7612544035285
//  271.86506158077816
//  269.91413504259503
//  267.909649954176
//  265.8528137423857
//  263.744865368448
//  261.58707458164224
//  259.3807411544532
//  257.12719409963745
//  254.82779086967523
//  252.48391653909204
//  250.09698297014145
//  247.66842796235227
//  245.19971438645166
//  242.69232930318663
//  240.1477830675741
//  237.56760841911975
//  234.9533595585528
//  232.30661121163385
//  229.62895768059877
//  226.9220118838108
//  224.1874043841986
//  221.42678240706638
//  218.64180884786697
//  215.8341612705355
//  213.0055308969878
//  210.1576215883917
//  207.29214881882442
//  204.41083864193538
//  201.51542665123614
//  198.60765693464342
//  195.68928102390595
//  192.7620568395473
//  189.82774763196008
//  186.88812091929015
//  183.9449474227495
//  181.00000000000003
//  178.05505257725056
//  175.11187908070983
//  172.1722523680399
//  169.23794316045274
//  166.31071897609408
//  163.3923430653566
//  160.4845733487639
//  157.5891613580646
//  154.7078511811756
//  151.84237841160834
//  148.9944691030122
//  146.16583872946455
//  143.35819115213303
//  140.5732175929336
//  137.81259561580143
//  135.07798811618923
//  132.37104231940123
//  129.69338878836612
//  127.04664044144721
//  124.43239158088028
//  121.85221693242593
//  119.30767069681342
//  116.80028561354837
//  114.33157203764772
//  111.90301702985856
//  109.516083460908
//  107.1722091303248
//  104.87280590036256
//  102.61925884554678
//  100.41292541835779
//  98.25513463155198
//  96.14718625761431
//  94.09035004582398
//  92.0858649574049
//  90.1349384192219
//  88.2387455964716
//  86.39842868480721
//  84.61509622232259
//  82.88982242180995
//  81.22364652369458
//  79.61757217003516
//  78.07256679996735
//  76.58956106695463
//  75.16944827819741
//  73.81308385653817
//  72.52128482518683
//  71.29482931557631
//  70.13445609864559
//  69.04086413983131
//  68.0147121780375
//  67.05661832883558
//  66.16715971213493
//  65.34687210454723
//  64.59624961665473
//  63.91574439537658
//  63.30576635161236
//  62.76668291332706
//  62.298818804226286
//  61.90245584815479
//  61.57783279933638
//  61.325145198557166
//  61.14454525537931
//  61.03614175645549
//  61
//  61.03614175645549
//  61.14454525537931
//  61.325145198557166
//  61.57783279933638
//  61.9024558481548
//  62.2988188042263
//  62.766682913327045
//  63.30576635161235
//  63.915744395376564
//  64.59624961665473
//  65.3468721045472
//  66.16715971213493
//  67.05661832883558
//  68.0147121780375
//  69.04086413983136
//  70.1344560986456
//  71.29482931557632
//  72.5212848251868
//  73.81308385653816
//  75.1694482781974
//  76.58956106695462
//  78.07256679996733
//  79.61757217003513
//  81.22364652369454
//  82.88982242180991
//  84.61509622232263
//  86.39842868480726
//  88.23874559647157
//  90.13493841922187
//  92.08586495740491
//  94.09035004582397
//  96.1471862576143
//  98.25513463155194
//  100.41292541835776
//  102.61925884554675
//  104.87280590036256
//  107.17220913032482
//  109.516083460908
//  111.90301702985857
//  114.33157203764773
//  116.80028561354834
//  119.30767069681337
//  121.85221693242589
//  124.43239158088025
//  127.04664044144715
//  129.6933887883661
//  132.37104231940125
//  135.07798811618926
//  137.81259561580146
//  140.5732175929336
//  143.35819115213303
//  146.1658387294645
//  148.99446910301216
//  151.8423784116083
//  154.70785118117558
//  157.58916135806456
//  160.48457334876377
//  163.3923430653566
//  166.31071897609408
//  169.23794316045274
//  172.17225236803992
//  175.11187908070983
//  178.0550525772505

// These are the extra values generated to 264 rather than 256
//  180.99999999999997
//  183.94494742274944
//  186.88812091929012
//  189.82774763196002
//  192.7620568395473
//  195.68928102390598
//  198.60765693464342
//  201.51542665123617




y_coordinates:
	.fill COORDINATES_COUNT, position(i, COORDINATES_COUNT).getY()
// we will store the previous coordinate as we will check in the sprite routine whether we have to flip the "go behind logo" bit.. 
// if ( x_hi_new - x_hi_old ) < 0 : Sprites are still moving to the right and should be visible
// if ( x_hi_new - x_hi_old ) = 0 : Probably won't happen, but that would only be when they turn on the end, so let them be visible
// if ( x_hi_new - x_hi_old ) > 0 : Sprites are moving to the right and we need to set the "go behind" bits for sprites to move behind logo
// we are storing the old and new coordinates of each sprite. we can use that to test above whether we switch the sprite to be in front or behind the logo
x_hi_coordinates_new_check: 	.fill 8,0
x_lo_coordinate_new_check: 		.fill 8,0
y_coordinate_new_check: 		.fill 8,0

x_hi_coordinate_old_check: 		.fill 8,0
x_lo_coordinate_old_check: 		.fill 8,0
y_coordinate_old_check:			.fill 8,0

// temp variables to be used on occasions when they are needed
temp_data_bytes: 	.fill 	8*3,0

// These two tables are used in the animate_sprites routine to AND or OR the $d010 sprite msb byte
// which is required to make the sprites move across all the 320 pixels on the screen. 
sprite_clear_table:
	.byte %11111110, %11111101, %11111011, %11110111, %11101111, %11011111, %10111111, %01111111
sprite_set_table:
	.byte %00000001, %00000010, %00000100, %00001000, %00010000, %00100000, %01000000, %10000000 

// This function generates the (x,y) data table compile time, which is used in the table
// generator statements above. 
.function position(index, total_count) {
  .var top_left = Vector(23, 50, 0)
  .var x_screen_size = Vector(340, 0, 0) 		// actual screen size = 320, but using 340 as I want to move the sprites a bit further to the right to give the right illusion around the logo given it moves
  .var y_screen_size = Vector(0, 200, 0)
  .var sprite_size = Vector(24, 21, 0)
  .var center = top_left + x_screen_size/2 + y_screen_size/3.5 - sprite_size/2
  .var start = Vector(0, -40, 0)
  .var rotation = RotationMatrix(0, 0, toRadians(index*360/total_count)) 			// This makes a circle
  .var scale = ScaleMatrix(3.3, 0.6, 0) 												// This scales it to become an ellipse & also scales the elipse so sprite priority does not interfere with the logo
  .var translation = MoveMatrix(center.getX(), center.getY(), 0)
  .return translation*scale*rotation*start
}

// This table holds the the reference point (table offset) for each one of the 8 sprites. This
// is required as each sprite is using an offset (x,y) value to make the appearance of following
// each other ... 
current_coords:  		.fill 8, 10*[7-i]  	// original code
// when we iterate through the current 8 sprites in the animate sprite loop, we store the coordinates that we will use in the loops compare
// we could set start compare values here for the first iteration, so there would not be any issues as we know where the start coordinates are
// we only need x coordinates as y is only 200 in hires bitmap (320x200)
current_coords_x_hi:	.fill 8, 0
current_coords_x_lo:	.fill 8, 0
// we need to store the output of the sprite direction test for the sprite text update
// we need to store the output of the sprite direction test for the sprite text update
sprite_direction_test:			.fill 8, 0 			// 0 moving left, and 1 moving right
// we need to store whether the sprite pointer can be replaced given the sprites x coordinate now is under the logo
sprite_pointer_replace_test:	.fill 8, 0 			// 0 can't replace, 1 can replace
sprite_pointer_iteration:		.fill 8, 0			// right now this refers to the iteration number of what sprite text to display
//sprite_scroll_text: 			.byte $10,$11,$12,$13,$14,$15,$16,$17 		// DARKZONE
//								.byte $17,$16,$15,$14,$13,$12,$11,$10 		// ENOZKRAD
//sprite_scroll_text_iterations: 	.byte 2										// this has to be one more than number of "text iterations"

//sprite_scroll_text:       
//  .byte $03,$00,$11,$0a,$19,$0e,$0d,$04   // DARKZONE
//  .byte $13,$10,$21,$1a,$29,$1e,$1d,$14   // DARKZONE
//  .byte $1f,$21,$14,$22,$14,$1d,$23,$22   // PRESENTS
//  .byte $22,$1c,$10,$1b,$1b,$23,$21,$1e   // SMALLTRO
//  .byte $2a,$2a,$29,$1e,$29,$1e,$2a,$2a   // !!2020!!
//  .byte $13,$10,$21,$1a,$29,$1e,$1d,$14   // DARKZONE
//  .byte $13,$10,$21,$1a,$29,$1e,$1d,$14   // DARKZONE
//sprite_scroll_text_iterations:  .byte 7                   // this has to be one more than number of "text iterations"

//sprite_scroll_text:       
//  .byte $00,$01,$02,$03,$04,$05,$06,$07   // DARKZONE
//  .byte $00,$01,$02,$03,$04,$05,$06,$07   // DARKZONE
//  .byte $00,$01,$02,$03,$04,$05,$06,$07   // DARKZONE
//  .byte $00,$01,$02,$03,$04,$05,$06,$07   // DARKZONE
//  .byte $00,$01,$02,$03,$04,$05,$06,$07   // DARKZONE
//  .byte $00,$01,$02,$03,$04,$05,$06,$07   // DARKZONE
//  .byte $00,$01,$02,$03,$04,$05,$06,$07   // DARKZONE
//sprite_scroll_text_iterations:  .byte 7                   // this has to be one more than number of "text iterations"

// This is for the DARKZONE characters only in offset $0400
sprite_scroll_text:       
  .byte $10,$11,$12,$13,$14,$15,$16,$17   // DARKZONE
  .byte $10,$11,$12,$13,$14,$15,$16,$17   // DARKZONE
  .byte $10,$11,$12,$13,$14,$15,$16,$17   // DARKZONE
  .byte $10,$11,$12,$13,$14,$15,$16,$17   // DARKZONE
  .byte $10,$11,$12,$13,$14,$15,$16,$17   // DARKZONE
  .byte $10,$11,$12,$13,$14,$15,$16,$17   // DARKZONE
  .byte $10,$11,$12,$13,$14,$15,$16,$17   // DARKZONE
sprite_scroll_text_iterations:  .byte 7                   // this has to be one more than number of "text iterations"


//sprite_scroll_text:       
//  .byte $13,$10,$21,$1a,$29,$1e,$1d,$14   // DARKZONE
//  .byte $13,$10,$21,$1a,$29,$1e,$1d,$14   // DARKZONE
//  .byte $1f,$21,$14,$22,$14,$1d,$23,$22   // PRESENTS
//  .byte $22,$1c,$10,$1b,$1b,$23,$21,$1e   // SMALLTRO
//  .byte $2a,$2a,$29,$1e,$29,$1e,$2a,$2a   // !!2020!!
//  .byte $13,$10,$21,$1a,$29,$1e,$1d,$14   // DARKZONE
//  .byte $13,$10,$21,$1a,$29,$1e,$1d,$14   // DARKZONE
//sprite_scroll_text_iterations:  .byte 7                   // this has to be one more than number of "text iterations"


//// Representing the alphabet as the character set was imported
//sprite_scroll_text: 			
//	.byte $10,$11,$12,$13,$14,$15,$16,$17 		// ABCDEFGH
//	.byte $18,$19,$1a,$1b,$1c,$1d,$1e,$1f 		// IJKLMNOP
//	.byte $20,$21,$22,$23,$24,$25,$26,$27 		// QRSTUVWX
//	.byte $28,$29,$2a,$2b,$2c,$2d,$2e,$30 		// YZ!.
//sprite_scroll_text_iterations: 	.byte 5										// this has to be one more than number of "text iterations"


//// just used this to map to characters to configure the table able
//  $10 = A
//  $11 = B
//  $12 = C
//  $13 = D
//  $14 = E
//  $15 = F
//  $16 = G
//  $17 = H
//  $18 = I
//  $19 = J
//  $1a = K
//  $1b = L
//  $1c = M
//  $1d = N
//  $1e = O
//  $1f = P
//  $20 = Q
//  $21 = R
//  $22 = S
//  $23 = T
//  $24 = U
//  $25 = V
//  $26 = W
//  $27 = X
//  $28 = Y
//  $29 = Z
//  $2a = !
//  $2b = .


// Store the screen bitmap references for fast lookups
// Based on http://codebase64.org/doku.php?id=base:various_techniques_to_calculate_adresses_fast_common_screen_formats_for_pixel_graphics
// Store the Y (column) reference table to derive quickly the screen address
// 
//        0 -> 0+(320*0)  (first character row)
//        1 -> 1+(320*0)
//        2 -> 2+(320*0)
//        3 -> 3+(320*0)
//        4 -> 4+(320*0)
//        5 -> 5+(320*0)
//        6 -> 6+(320*0)
//        7 -> 7+(320*0)
//        
//        8 -> 0+(320*1)  (second character row)
//        9 -> 1+(320*1)
//        10-> 2+(320*1)
//        11-> 3+(320*1)
//        12-> 4+(320*1)
//        13-> 5+(320*1)
//        14-> 6+(320*1)
//        15-> 7+(320*1)
//        
//        etc.
//
// Store the X reference table to derive quickly the screen address
//
//        X table:
//        
//        X coord | value
//        
//        0 -> 0*8 (first character column)
//        1 -> 0*8
//        2 -> 0*8
//        3 -> 0*8
//        4 -> 0*8
//        5 -> 0*8
//        6 -> 0*8
//        7 -> 0*8
//        
//        8 -> 1*8 (second character column)
//        9 -> 1*8
//        10-> 1*8
//        11-> 1*8
//        12-> 1*8
//        13-> 1*8
//        14-> 1*8
//        15-> 1*8
//        
//        etc.
//
//  The color table follows the same principle. Screen memory mapped 40x25=1000 bytes.
//  Creating a screen memory lookup table so can derive memory addres by (x,y) coordinate.
// 
// These are reference tables & data variables specific to writing & updating bitmaps & colours
Y_Table_Lo: .fill 25,<(bitmap_address_bitmap+i*320)
Y_Table_Hi: .fill 25,>(bitmap_address_bitmap+i*320)
X_Table_Lo: .fill 40,<(i*8)
X_Table_Hi: .fill 40,>(i*8)
Y_Color_Table_Lo: .fill 25,<(screen_memory_bitmap+i*40)
Y_Color_Table_Hi: .fill 25,>(screen_memory_bitmap+i*40)
X_Color_Table_Lo: .fill 40,<(i)
X_Color_Table_Hi: .fill 40,>(i)
XY_block_row_height:	.byte 0
XY_block_row_width:		.byte 0
XY_block_start_row:		.byte 0
X1_block:			.byte 0
Y1_block:			.byte 0
X2_block:			.byte 0
Y2_block:			.byte 0
XY_block_temporary_1:	.byte 0
XY_block_temporary_2:	.byte 0
XY_block_temporary_3:	.byte 0
XY_block_temporary_4:	.byte 0
// **************


* = custom_font_mem_bitmap "Text Mode Character Font"
.fill font.getSize(), font.get(i)

* = music.location "SID Music"
.fill music.size, music.getData(i)


//// Here is the commented version of the code that will bring in the unpacked data. Below is the inline crunching
//// routine with Exomizer.. 
//// 
////* = bitmap_address "Bitmap"
////Bitmap: .fill picture1.getBitmapSize(), picture1.getBitmap(i)
////* = screen_memory "Screen memory"
////Colors: .fill picture1.getScreenRamSize(), picture1.getScreenRam(i)
//.modify MemExomizer(false,true) {
//    .pc = bitmap_address "Bitmap"
//    .fill picture1.getBitmapSize(), picture1.getBitmap(i)
//    .pc = screen_memory "Screendata"
//    .fill picture1.getScreenRamSize(), picture1.getScreenRam(i)
//}
//.label crunchedBitmapAndScreen = *
//



.segment Default
scroll_offset_1: .byte 0 		// we temp store the sequence number to the YSCROLL table value
scroll_offset_2: .byte 0 		// we temp store the actual YSCROLL offset value
// This will generate a 16x16 data table that has values between 0 and 7.
y_coords: .fill 256, round([sin(toRadians(4*i*360/256))+1]/2*7)
//y_coords: .fill 256, 4

// 0 = bottom is offset and needs to be corrected
// 1 = bottom is offset and needs to be corrected
// 2 = bottom is offset and needs to be corrected
// 3 = bottom is not offset & is correct
// 4 = bottom is offset and needs to be corrected
// 5 = bottom is offset and needs to be corrected
// 6 = bottom is offset and needs to be corrected
// 7 = bottom is offset and needs to be corrected

x_coords: .fill 256, round([cos(toRadians(2*i*360/256))+1]/2*7)
//x_coords: .fill 256, 0

// Scroll text 1: This is the slow one.. 
framecount: 	.byte 0
charpos:    	.byte 0, 0
scrolltext: 
    .text "* darkzone * 2020 * does it again.. smalltro.. released at syntax 2020.. shout-outs to the flashback and syntax crews "
    .text "in australia for running those events in 2019, which put some pressure on getting into some simple 6502 asm "
    .text "for old times sake. whilst not up to standard yet, in due time (like 10 years) we might. that said..  "
    .text "some quick credits.. code: agnostic & failure... logo: kingpin... tune: ps0ma (ring of ages forever!)... "
    .text "sprite font: digger of elysium from the 256b sprite font compo (hope you did not mind.. looks great!). "
    .text "font: 7up.64c from koefler.de. credits go where credits are due... "
    .text "greetz and shoutouts go to all we know, and you know you who are! "
    .text "                                             "
scrolltextend:

// Scroll text 2: This is the fast one
framecount_2: 	.byte 0
charpos_2:    	.byte 0, 0
scrolltext_2: 
    .text "er en stund siden darkzone fra norge (og ja.. litt australia og for tiden!) har produsert noe.. "
    .text "men har gjort noen craptro releaser i 2019 og fortsetter i 2020! pa tide med litt retro c64 intros "
    .text "for litt mimring! haha! uansett shout out til den norske scenen som kjente darkzone, nobliege, wild palms.. "
    .text "og seff okokrim for dems commitment til a buste en haug av oss for lenge siden. skulle trodd de hadde "
    .text "bedre ting a drive med enn det, men mimre skal vi.. til neste gang.. party on!"
    .text "                                             "
scrolltextend_2:

.align 64
colors1:
                .text "cmagcmag"
colorend:

colour:      
  .byte $09,$09,$02,$02,$08 
  .byte $08,$0a,$0a,$0f,$0f 
  .byte $07,$07,$01,$01,$01 
  .byte $01,$01,$01,$01,$01 
  .byte $01,$01,$01,$01,$01 
  .byte $01,$01,$01,$07,$07 
  .byte $0f,$0f,$0a,$0a,$08 
  .byte $08,$02,$02,$09,$09 
  .byte $00,$00,$00,$00,$00

colour_2:      
  .byte $09,$09,$02,$02,$08 
  .byte $08,$0a,$0a,$0f,$0f 
  .byte $07,$07,$01,$01,$01 
  .byte $01,$01,$01,$01,$01 
  .byte $01,$01,$01,$01,$01 
  .byte $01,$01,$01,$07,$07 
  .byte $0f,$0f,$0a,$0a,$08 
  .byte $08,$02,$02,$09,$09 
  .byte $00,$00,$00,$00,$00



// Populate the VIC screen buffers with the right data. Using memory assignments here to create specific
// memory buffers that are aligned with where the data needs to go; e.g. we load the data directly into the
// right location. We should ideally compress this data and then move it into the right location, but that
// we can do another time
* = sprite_font_mem_bitmap "Sprite Font Data"
.fill sprite_font_bitmap.getSize(), sprite_font_bitmap.get(i)

//// We have done the VIC bitmap buffers, and we need to continue placing code in the default memory segment.. 


// Here is the commented version of the code that will bring in the unpacked data. Below is the inline crunching
// routine with Exomizer.. 
// 
//* = bitmap_address "Bitmap"
//Bitmap: .fill picture1.getBitmapSize(), picture1.getBitmap(i)
//* = screen_memory "Screen memory"
//Colors: .fill picture1.getScreenRamSize(), picture1.getScreenRam(i)
.modify MemExomizer(false,true) {
    .pc = bitmap_address_bitmap "Bitmap"
    .fill picture1.getBitmapSize(), picture1.getBitmap(i)
    .pc = screen_memory_bitmap "Screendata"
    .fill picture1.getScreenRamSize(), picture1.getScreenRam(i)
}
.label crunchedBitmapAndScreen = *




//
// Codebase64: http://codebase64.org/doku.php?id=base:vicii_memory_organizing
//
// $D018/53272/VIC+24:   Memory Control Register
// 
// +----------+---------------------------------------------------+
// | Bits 7-4 |   Video Matrix Base Address (inside VIC)          |
// | Bit  3   |   Bitmap-Mode: Select Base Address (inside VIC)   |
// | Bits 3-1 |   Character Dot-Data Base Address (inside VIC)    |
// | Bit  0   |   Unused                                          |
// +----------+---------------------------------------------------+
//
// Bitmap
// 
//   $D018 = %xxxx0xxx -> bitmap is at $0000
//   $D018 = %xxxx1xxx -> bitmap is at $2000
// 
// Character memory
// 
//   $D018 = %xxxx000x -> charmem is at $0000
//   $D018 = %xxxx001x -> charmem is at $0800
//   $D018 = %xxxx010x -> charmem is at $1000 <<< TEXT MODE (Given we are using bank 2, this maps to ROM character set)
//   $D018 = %xxxx011x -> charmem is at $1800
//   $D018 = %xxxx100x -> charmem is at $2000 <<< BITMAP MODE (Used for colors on screen bitmap)
//   $D018 = %xxxx101x -> charmem is at $2800
//   $D018 = %xxxx110x -> charmem is at $3000
//   $D018 = %xxxx111x -> charmem is at $3800
// 
// Screen memory
// 
//   $D018 = %0000xxxx -> screenmem is at $0000
//   $D018 = %0001xxxx -> screenmem is at $0400
//   $D018 = %0010xxxx -> screenmem is at $0800
//   $D018 = %0011xxxx -> screenmem is at $0c00
//   $D018 = %0100xxxx -> screenmem is at $1000
//   $D018 = %0101xxxx -> screenmem is at $1400
//   $D018 = %0110xxxx -> screenmem is at $1800
//   $D018 = %0111xxxx -> screenmem is at $1c00
//   $D018 = %1000xxxx -> screenmem is at $2000 <<< BITMAP MODE (Used for the bitmap graphics on screen)
//   $D018 = %1001xxxx -> screenmem is at $2400
//   $D018 = %1010xxxx -> screenmem is at $2800
//   $D018 = %1011xxxx -> screenmem is at $2c00
//   $D018 = %1100xxxx -> screenmem is at $3000
//   $D018 = %1101xxxx -> screenmem is at $3400
//   $D018 = %1110xxxx -> screenmem is at $3800
//   $D018 = %1111xxxx -> screenmem is at $3c00
// 
// standard bitmap mode config =
//   %1000, 8: $2000-$23FF, 8192-9215 + %1xx, 4: $2000-$3FFF, 8192-16383   >>> %10001000 > 56
//   %10001000 = 136
// 
// text mode config = 
//   %000, 0: $0000-$07FF, 0-2047  >>> %00000000
//   %00000100 = 4
// 
// 

*=$4000
#import "code/math.asm"


//----------------------------------------------------------
// Print the music info while assembling
.print ""
.print "--------------------"
.print "SID Data"
.print "--------------------"
.print "location=$"+toHexString(music.location)
.print "init=$"+toHexString(music.init)
.print "play=$"+toHexString(music.play)
.print "songs="+music.songs
.print "startSong="+music.startSong
.print "size=$"+toHexString(music.size)
.print "name="+music.name
.print "author="+music.author
.print "copyright="+music.copyright
.print ""
.print "--------------------"
.print "Additional tech data"
.print "--------------------"
.print "header="+music.header
.print "header version="+music.version
.print "flags="+toBinaryString(music.flags)
.print "speed="+toBinaryString(music.speed)
.print "startpage="+music.startpage
.print "pagelength="+music.pagelength
.print ""
.print "--------------------"
.print "Hires Bitmap Buffer:"
.print "--------------------"
.print "Hires vic_bank: $" + toHexString(vic_bank_bitmap)
.print "Hires vic_base: $" + toHexString(vic_base_bitmap)
.print "Hires screen_memory: $" + toHexString(screen_memory_bitmap) + " ($" + toHexString(screen_memory_bitmap_buffer_offset) + ")"
.print "Hires bitmap_address: $" + toHexString(bitmap_address_bitmap) + " ($" + toHexString(bitmap_address_bitmap_buffer_offset) + ")"
.print "Sprite font address: $" + toHexString(sprite_font_mem_bitmap) + " ($" + toHexString(sprite_font_mem_bitmap_buffer_offset) + ")"
.print "Custom font address: $" + toHexString(custom_font_mem_bitmap) + " ($" + toHexString(custom_font_mem_bitmap_buffer_offset) + ")"
//.print ""
//.print "--------------------"
//.print "Textmode Buffer:"
//.print "--------------------"
//.print "Textmode vic_bank: $" + toHexString(vic_bank_bitmap)
//.print "Textmode vic_base: $" + toHexString(vic_base_bitmap)
//.print "Textmost screen_memory: $" + toHexString(screen_memory_bitmap) + " ($" + toHexString(screen_memory_bitmap_buffer_offset) + ")"
//.print "Textmode bitmap_address: $" + toHexString(bitmap_address_bitmap) + " ($" + toHexString(bitmap_address_bitmap_buffer_offset) + ")"
//.print "Textmode font address: $" + toHexString(sprite_font_mem_bitmap) + " ($" + toHexString(sprite_font_mem_bitmap_buffer_offset) + ")"
//.print "Textmode ustom font address: $" + toHexString(custom_font_mem_bitmap) + " ($" + toHexString(custom_font_mem_bitmap_buffer_offset) + ")"
.print ""
.print "----------------------------------"
.print "Bitmap file import - Darkzone logo"
.print "----------------------------------"
.print "Koala format="+BF_KOALA

/*







                               ..     ..ee$ $$$
     ...ee    e$$$            $$$      $$$' $$$           ..ee.$ .e$$$$e
     `$$$$.   $$$$            $$$      $$$       .e$$$e. e$$`$$$ $$$'.$$
      `$$$$.  $$$$     ...    $$$.$$e. $$$  $$$ e$$' $$e $$..$$' $$$"""'
       $$$$$. $$$$   e$$$$$.  $$$$$$$$ $$$  $$$ $$$$$$$' `$$$'   `$$$$$$
       $$$$$$.$$$$  $$$`$$$$. $$$ '$$$ $$$  $$$ $$$'   . $$$$$$.   `"""
       $$$$$$$$$$$ e$$$  $$$$ $$$  $$$ $$$  $$$ `$$$$$$' $$  $$$  .eeee.
       $$$`$$$$$$$ $$$$  $$$$ $$$ .$$' $$$. $$$  `$$$"'  `$$$$$'.$$$$$$$
       $$$ `$$$$$$ $$$$  $$$' $$$$$$' .$$"' "'            .    e$$$`$$$$
       $$$  `$$$$$ `$$$$$$$'  $$$"'                  .e$$$$$. e$$$  $$$$
       $$$   `$$$$  `$$$$'                          e$$' $$$$ $$$$. $$$$
       $$$    `$$"                                 $$$$  $$$$  $$$$$$$$$
      ,$$"'                                        `$$$$$$$$$    $$$$$$$
                                                    .""$$$$$$     ""$$$$
                                                    $$$. $$$$        $$$
                                                     `$$$$$$' `$$$. .$$$
                                                               `$$$e$$$$
                                                                `$$$$$$$
                                                         TheKON  `$$$$'
╔═──··       Smalltro 2020       ··──═╗
║                                     ║
║════════════─· Greetzz ·─════════════║
║                                     ║
║                                     ║
║══════════─· Group  Info ·─══════════║
║                                     ║
║ ┌─────────────────────────────────┐ ║
║ └────────· M e m b e r s ·────────┘ ║
║                                     ║
║                                     ║
║══════════─· Group  Info ·─══════════║
║                                     ║
║══════════─· News & Info ·─══════════║
║                                     ║
║     Global HQ: www.darkzone.no      ║
║                                     ║
║                                     ║
║                                     ║
║═════════════[13/09/2020]═[Agnostic]═║
╚═══──··     Blow me honey!    ··──═══╝







────────── █▀▀▀▀▀▀▀█▄▄▄▄▄▄ ────────────
 NOBLiEGE  █ █████▄▄▄▄▄▄ ▀█ : NAMBLA! :
────────── █ █████ █████▌ █ ───────────
 ▄█▀▀▀▀▀▀▀▀▀ ████▓ ██████ ▀▀▀▀▀▀█ ░░░
 █ ▄██▀█████ ████▓ ██████ ▓████ █
▐▌▐███ █████ ████▓ █████▌ ▓████ █▄▄▄▄▄▄
█ ███▓ █████ █████▀█████▄ ▓████ ▄▄▄▄▄ █
█ ███▓ █████ ████▓ ██████▌▐████ █████ █
█ ▀▀▀▀ █████ ████▓ ███████ ▀▀▀▀▀█████ █
▀▀▀▀▀█▄▄▄▄▄▄ ████▓ ███████ █▀▀█▄▄▄▄▄▄▄█
────────── █ ████▓ ██████▌▐▌───────────
 03/19/99  █ ▀▀▀▀▀▀▀▀▀▀▀▀ █   [xx/x1]  
────────── ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ ───────────




*/








