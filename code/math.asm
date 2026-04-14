// ========================================================================
// Description: 16 bit addtion
//                                                                        
// Input: Two 16-bit unsigned values in
//        num1lo:   
//        num1hi:   
//        num2lo:   
//        num2hi:   
// Output: 16-bit unsigned value in PRODUCT                               
//        resultlo:
//        resulthi:
add_16_bit: {
     clc                 // clear carry
     lda num1lo
     adc num2lo
     sta resultlo        // store sum of LSBs
     lda num1hi
     adc num2hi          // add the MSBs using carry from
     sta resulthi        // the previous calculation
     rts
}


// ========================================================================
// Description: 16 bit subtraction
//                                                                        
// Input: Two 16-bit unsigned values in
//        num1lo:   
//        num1hi:   
//        num2lo:   
//        num2hi:   
// Output: 16-bit unsigned value in PRODUCT                               
//        resultlo:
//        resulthi:
subtract_16_bit: {
     sec                 // set carry for borrow purpose
     lda num1lo
     sbc num2lo          // perform subtraction on the LSBs
     sta resultlo        // store sum of LSBs
     lda num1hi          // do the same for the MSBs, with carry
     sbc num2hi          // set according to the previous result
     sta resulthi        // the previous calculation
     rts
}

// ========================================================================
// Description: Unsigned 8-bit multiplication with unsigned 16-bit result.
//                                                                        
// Input: 8-bit unsigned value in T1                                      
//        8-bit unsigned value in T2                                      
//        Carry=0: Re-use T1 from previous multiplication (faster)        
//        Carry=1: Set T1 (slower)                                        
//                                                                        
// Output: 16-bit unsigned value in PRODUCT                               
//                                                                        
// Clobbered: PRODUCT, X, A, C                                            
//                                                                        
// Allocation setup: T1,T2 and PRODUCT preferably on Zero-page.           
//                   square1_lo, square1_hi, square2_lo, square2_hi must be
//                   page aligned. Each table are 512 bytes. Total 2kb.    
//                                                                         
// Table generation: I:0..511                                              
//                   square1_lo = <((I*I)/4)                               
//                   square1_hi = >((I*I)/4)                               
//                   square2_lo = <(((I-255)*(I-255))/4)                   
//                   square2_hi = >(((I-255)*(I-255))/4)                   
multiply_8bit_unsigned:                                              
          bcc sm0
          lda T1
          sta sm1+1
          sta sm3+1
          eor #$ff
          sta sm2+1
          sta sm4+1
sm0:      ldx T2
          sec
sm1:      lda square1_lo,x
sm2:      sbc square2_lo,x
          sta PRODUCT+0
sm3:      lda square1_hi,x
sm4:      sbc square2_hi,x
          sta PRODUCT+1   
          rts

// Description: Signed 8-bit multiplication with signed 16-bit result.
//                                                                    
// Input: 8-bit signed value in T1                                    
//        8-bit signed value in T2                                    
//        Carry=0: Re-use T1 from previous multiplication (faster)    
//        Carry=1: Set T1 (slower)                                    
//                                                                    
// Output: 16-bit signed value in PRODUCT                             
//                                                                    
// Clobbered: PRODUCT, X, A, C                                        
multiply_8bit_signed:
          jsr multiply_8bit_unsigned

          // Apply sign (See C=Hacking16 for details).
          lda T1
          bpl sm0_8
          sec
          lda PRODUCT+1
          sbc T2
          sta PRODUCT+1
sm0_8:
          lda T2
          bpl sm1_8
          sec
          lda PRODUCT+1
          sbc T1
          sta PRODUCT+1
sm1_8:
          rts

// Description: Unsigned 16-bit multiplication with unsigned 32-bit result.
//                                                                         
// Input: 16-bit unsigned value in T1                                      
//        16-bit unsigned value in T2                                      
//        Carry=0: Re-use T1 from previous multiplication (faster)         
//        Carry=1: Set T1 (slower)                                         
//                                                                         
// Output: 32-bit unsigned value in PRODUCT                                
//                                                                         
// Clobbered: PRODUCT, X, A, C                                             
//                                                                         
// Allocation setup: T1,T2 and PRODUCT preferably on Zero-page.            
//                   square1_lo, square1_hi, square2_lo, square2_hi must be
//                   page aligned. Each table are 512 bytes. Total 2kb.    
//                                                                         
// Table generation: I:0..511                                              
//                   square1_lo = <((I*I)/4)                               
//                   square1_hi = >((I*I)/4)                               
//                   square2_lo = <(((I-255)*(I-255))/4)                   
//                   square2_hi = >(((I-255)*(I-255))/4)                   
multiply_16bit_unsigned:
          // <T1 * <T2 = AAaa                                        
          // <T1 * >T2 = BBbb                                        
          // >T1 * <T2 = CCcc                                        
          // >T1 * >T2 = DDdd                                        
          //                                                         
          //       AAaa                                              
          //     BBbb                                                
          //     CCcc                                                
          // + DDdd                                                  
          // ----------                                              
          //   PRODUCT!                                              

          // Setup T1 if changed
          bcc m0_16
          lda T1+0
          sta sm1a+1
          sta sm3a+1
          sta sm5a+1
          sta sm7a+1
          eor #$ff
          sta sm2a+1
          sta sm4a+1
          sta sm6a+1
          sta sm8a+1
          lda T1+1
          sta sm1b+1
          sta sm3b+1
          sta sm5b+1
          sta sm7b+1
          eor #$ff
          sta sm2b+1
          sta sm4b+1
          sta sm6b+1
          sta sm8b+1
m0_16:
          // Perform <T1 * <T2 = AAaa
          ldx T2+0
          sec
sm1a:     lda square1_lo,x
sm2a:     sbc square2_lo,x
          sta PRODUCT+0
sm3a:     lda square1_hi,x
sm4a:     sbc square2_hi,x
          sta _AA+1

          // Perform >T1_hi * <T2 = CCcc
          sec
sm1b:     lda square1_lo,x
sm2b:     sbc square2_lo,x
          sta _cc+1
sm3b:     lda square1_hi,x
sm4b:     sbc square2_hi,x
          sta _CC+1

          // Perform <T1 * >T2 = BBbb
          ldx T2+1
          sec
sm5a:     lda square1_lo,x
sm6a:     sbc square2_lo,x
          sta _bb+1
sm7a:     lda square1_hi,x
sm8a:     sbc square2_hi,x
          sta _BB+1

          // Perform >T1 * >T2 = DDdd
          sec
sm5b:     lda square1_lo,x
sm6b:     sbc square2_lo,x
          sta _dd+1
sm7b:     lda square1_hi,x
sm8b:     sbc square2_hi,x
          sta PRODUCT+3

          // Add the separate multiplications together
          clc
_AA:      lda #0
_bb:      adc #0
          sta PRODUCT+1
_BB:      lda #0
_CC:      adc #0
          sta PRODUCT+2
          bcc m1_16
          inc PRODUCT+3
          clc                                    
m1_16:                                          
_cc:      lda #0
          adc PRODUCT+1
          sta PRODUCT+1
_dd:      lda #0
          adc PRODUCT+2
          sta PRODUCT+2
          bcc m2_16
          inc PRODUCT+3
m2_16:
          rts

// Description: Signed 16-bit multiplication with signed 32-bit result.
//                                                                     
// Input: 16-bit signed value in T1                                    
//        16-bit signed value in T2                                    
//        Carry=0: Re-use T1 from previous multiplication (faster)     
//        Carry=1: Set T1 (slower)                                     
//                                                                     
// Output: 32-bit signed value in PRODUCT                              
//
// Clobbered: PRODUCT, X, A, C
multiply_16bit_signed:
          jsr multiply_16bit_unsigned

          // Apply sign (See C=Hacking16 for details).
          lda T1+1
          bpl m0_s_16
          sec
          lda PRODUCT+2
          sbc T2+0
          sta PRODUCT+2
          lda PRODUCT+3
          sbc T2+1
          sta PRODUCT+3
m0_s_16:
          lda T2+1
          bpl m1_s_16
          sec
          lda PRODUCT+2
          sbc T1+0
          sta PRODUCT+2
          lda PRODUCT+3
          sbc T1+1
          sta PRODUCT+3
m1_s_16:
          rts

// divisor:         .byte 0,0           // AKA the number that dividend is divided by
// dividend:                            // AKA the number to be divided
// result:          .byte 0,0           // the routine uses this to derive the calculated output.
// remainder:       .byte 0,0
// result = dividend ;save memory by reusing divident to store the result

divide_16_bit:
          lda #0                        // preset remainder to 0
          sta remainder
          sta remainder+1
          ldx #16                       // repeat for each bit: ...

divloop:  asl dividend                  // dividend lb & hb*2, msb -> Carry
          rol dividend+1      
          rol remainder                 // remainder lb & hb * 2 + msb from carry
          rol remainder+1
          lda remainder
          sec
          sbc divisor                   // substract divisor to see if it fits in
          tay                           // lb result -> Y, for we may need it later
          lda remainder+1
          sbc divisor+1
          bcc skip                      // if carry=0 then divisor didn't fit in yet

          sta remainder+1               // else save substraction result as new remainder,
          sty remainder       
          inc result                    //and INCrement result cause divisor fit in 1 times

skip:     dex
          bne divloop         
          rts

// SIGNED 16-BIT DIVISION ROUTINE
// V FLAG IS RETURNED SET IF ZERO DIVIDE OCCURS
//
// THIS ROUTINE COMPUTES (DIVEND,PARTIAL)/DIVEND
// AS WELL AS (DIVEND,PARTIAL) MOD DIVEND
// URL: http://www.easy68k.com/paulrsm/6502/HYDE6502.TXT
//
// Input:           signed 16 bit number in divend, divend+1
// Output:          signed 16 bit number in result, result+1
// 
// How to use: 
// 
/* [test signed 16 bit division] ---------------------------------------------
          lda #0
          sta partial                   // 16x16 bit caclulatons - set to #0
          sta partial                   // 16x16 bit caclulatons - set to #0
          lda #<-200
          sta divend
          lda #>-200
          sta divend+1
          lda #<10
          sta divsor
          lda #>10
          sta divsor+1
          jsr signed_divide_16_bit

          lda result2
          sta calc_intersect_temp_5_low
          lda result2+1
          sta calc_intersect_temp_5_high
// [test signed 16 bit division] --------------------------------------------- */
signed_divide_16_bit:
          pha
          lda divend+1                  // check sign bits
          eor divsor+1

          and #$80
          sta sign
          jsr dabs1                     // absolute value of divsor
          jsr dabs2                     // absolute value of divend
          jsr usdiv                     // compute unsigned division
          lda divend                    // check for zero divide
          and divend+1
          cmp #$ff
          beq ovrflw
          lda sign                      // sign if result must be
          bpl sdiv1                     // negative
          jsr divneg                    // reset result to a signed negative number
sdiv1:

          lda divend 
          sta result2
          lda divend+1
          sta result2+1
          lda partial 
          sta modulo 
          lda partial+1
          sta modulo+1

          clv                           // no zero division
          pla
          rts

ovrflw:
          bit setovr                    // set overflow flag
          pla
          rts
// reset sign; e.g. number was negative, so convert to two's complement negative number
divneg:   sec
          lda #$0
          sbc divend
          sta divend
          lda #$0
          sbc divend+1
          sta divend+1
          rts
// abs(divsor)
dabs1:    lda divsor+1
          bpl dabs12
          sec
          lda #$0
          sbc divsor
          sta divsor
          lda #$0
          sbc divsor+1
          sta divsor+1
dabs12:   rts

// abs(divend)
dabs2:    lda divend+1
          bpl dabs22
          sec
          lda #$0
          sbc divend
          sta divend
          lda #$0
          sbc divend+1
          sta divend+1
dabs22:   rts

// unsigned 16-bit division
// computes (divend,partial) / divsor
// (i.e., 32 bits divided by 16 bits)
//
// How to use: 
//
/* [test unsigned 16 bit division] ---------------------------------------------
          lda #<195
          sta divend
          lda #>195
          sta divend+1
          lda #<24
          sta divsor
          lda #>24
          sta divsor+1
          lda #0
          sta partial                   // 16x16 bit caclulatons - set to #0
          sta partial                   // 16x16 bit caclulatons - set to #0
          jsr usdiv

          lda divend 
          sta result2
          lda divend+1
          sta result2+1
          lda partial 
          sta modulo 
          lda partial+1
          sta modulo+1
// [test unsigned 16 bit division] --------------------------------------------- */
usdiv:
          pha
          tya
          pha
          txa
          pha

          ldy #$10                      // set up for 16 bits
usdiv2:
          asl divend
          rol divend+1
          rol partial
          rol partial+1
          sec                           // leave divend mod divsor
          lda partial                   // in partial
          sbc divsor
          tax
          lda partial+1
          sbc divsor+1
          bcc usdiv3
          stx partial
          sta partial+$1
          inc divend

usdiv3:
          dey
          bne usdiv2

          pla
          tax
          pla
          tay
          pla
          rts




// usmul- unsigned 16-bit multiplication.
//        32 bit result is returned in locations
//        (mulplr, partial).
//
//
/* [test unsigned 16 bit multiplication] ---------------------------------------------
          lda #<25
          sta mulplr
          lda #>25
          sta mulplr+1
          lda #<66
          sta mulcnd
          lda #>66
          sta mulcnd+1
          lda #$0                       // must set partial to zero
          sta partial
          sta partial+1
          jsr usmul                     // perform the multiplication
          lda mulplr                    // move product to result
          sta result
          lda mulplr+1
          sta result+1
// [test unsigned 16 bit multiplication] --------------------------------------------- */
usmul16bit:
          pha
          tya
          pha
usmul1:   ldy #$10                      // set up for 16-bit multiply
usmul2:   lda mulplr                    // test l.o. bit to see if set
          lsr
          bcc usmul4
          clc                           // l.o. bit set, add mulcnd to
          lda partial                   //partial product
          adc mulcnd
          sta partial
          lda partial+1
          adc mulcnd+1
          sta partial+1
          // shift result into mulplr and get the next bit
          // of the multiplier into the low!order bit of
          // mulplr
usmul4:   ror partial+$1
          ror partial
          ror mulplr+$1
          ror mulplr
          // see if done yet
          dey
          bne usmul2
          pla
          tay
          pla
          rts


// signed 16-bit multiplication
/* [test signed 16 bit multiplication] ---------------------------------------------
          lda #<-25
          sta mulplr
          lda #>-25
          sta mulplr+1
          lda #<66
          sta mulcnd
          lda #>66
          sta mulcnd+1
          lda #$0                       // must set partial to zero
          sta partial
          sta partial+1
          jsr smul16bit                 // perform the multiplication
          lda mulplr                    // move product to result
          sta result
          lda mulplr+1
          sta result+1
// [test signed 16 bit multiplication] --------------------------------------------- */
smul16bit:
          pha
          tya
          pha

          lda mulcnd+1                  // test sign bits
          eor mulplr+1                  // to see if h.o bits are unequ
          and #$80
          sta sign                      // save sign status
          jsr abs1                      // take absolute value of mulplr
          jsr abs2                      // take absolute value of mulcnd
          jsr usmul16bit                // unsigned multiply
          lda sign                      // test sign flag
          bpl smul1                     // if not set, result is correct
          jsr negate                    // negate result

smul1:    pla
          tay
          pla
          rts

abs1:     lda mulplr+1                  // see if negative
          bpl abs12

negate:
          sec                           // negate mulplr
          lda #$0
          sbc mulplr
          sta mulplr
          lda #$0
          sbc mulplr+1
          sta mulplr+1

abs12:    rts

abs2:     lda mulcnd+1                  // see if negative
          bpl abs22
          sec                           // negate mulcnd
          lda #$0
          sbc mulcnd
          sta mulcnd
          lda #$0
          sbc mulcnd+1
          sta mulcnd+1
abs22:    rts

// ================================================================================================================================================ [START]
// Data & Variables
n_flag_divs:             .byte 0
prod:                    .byte 0,0
// ================================================================================================================================================
// subroutine: signed divide by offset 64 (multiplier8, sum8) 
divide_signed: {
     lda #$00
     sta n_flag_divs

     lda multiplier8
     bpl skip_comp_divide_signed

     sec 
     lda #$00
     sbc sum8
     sta sum8
     lda #$00
     sbc multiplier8
     sta multiplier8          // takes complement of product 

     lda #$01
     sta n_flag_divs          // quotient will be negative 

skip_comp_divide_signed:
     lda sum8
     sta $fe             // shift = $fe, holds bits to recover
     lda multiplier8
     sta sum8
     lda #$00
     sta multiplier8          // /256

     asl $fe
     rol sum8
     rol multiplier8          // *2 => /256 * 2 = /128
     asl $fe
     rol sum8
     rol multiplier8          // *2 => /128 * 2 = /64


     lda n_flag_divs 
     bne comp_quotient        // if 8 bit result must be negative ,take complement 

     rts 

comp_quotient:
     sec
     lda #$00
     sbc sum8
     sta sum8

     rts 
}

// subroutine: signed divide by offset 64 (prod, prod+1) 
divide_prod_signed: {
     lda #$00
     sta n_flag_divs

     lda prod
     bpl skip_comp_divide_signed2    

     sec 
     lda #$00
     sbc prod+1 
     sta prod+1 
     lda #$00
     sbc prod
     sta prod       // takes complement of product 

     lda #$01
     sta n_flag_divs     // quotient will be negative 
                
skip_comp_divide_signed2:
     lda prod+1
     sta $fe             // shift = $fe, holds bits to recover
     lda prod 
     sta prod+1
     lda #$00
     sta prod            // /256

     asl $fe
     rol prod+1
     rol prod            // *2 => /256 * 2 = /128
     asl $fe
     rol prod+1
     rol prod            // *2 => /128 * 2 = /64

     // a bit faster than using lsr and ror instructions 

     lda n_flag_divs 
     bne comp_quotient2  // if 8 bit result must be negative ,take complement 

     rts 

comp_quotient2:
     lda #$00
     sbc prod+1
     sta prod+1

     rts 
}
// ================================================================================================================================================ [STOP]


// ================================================================================================================================================ [START]
// Data & Variables
multiplicand_sign8:      .byte 0
multiplier_sign8:        .byte 0
multiplicand8:           .byte 0
multiplier8:             .byte 0   // high byte of product
sum8:                    .byte 0   // low byte of product                       
// subroutine: signed 8 bit multiply (used for rotations and projections)
multiply_ab8: {
     lda #$00
     sta sum8

     sta multiplicand_sign8
     // multiplicand8 sign positive
     sta multiplier_sign8     // multiplier8 sign positive

     ldx #8              // number of bits

     lda multiplicand8        // checks sign on high byte - first round A = 63 or %0011 1111
     bpl skip_multiplicand_comp8   // %0011 1111 so high bit = 0 and we do not branch

     sec            // set carry
     lda #<256           // A = %0000 0000 - or 'zero'
     sbc multiplicand8        // 0 - 63
     sta multiplicand8        // takes complement of multiplicand8 - stores mutltiplican8 = 63

     inc multiplicand_sign8   // and set sign to negative
     // multiplicand8 sign set to negative
                
skip_multiplicand_comp8:

     lda multiplier8          // A = 221 or %1101 1101 so high bit set and number is neg
     bpl loop8           // checks sign on high byte 

     sec

     lda #<256
     sbc multiplier8
     sta multiplier8          // takes complement of multiplier8 

     inc multiplier_sign8 
          // multiplier8 sign set to negative

// fast multiply 
loop8:
     lda #>square_low
     sta mod12+2
     lda #>square_high
     sta mod22+2

     clc
     lda multiplicand8
     adc multiplier8
     bcc skip_inc

     inc mod12+2
     inc mod22+2
      
skip_inc:
     tax

     sec
     lda multiplicand8
     sbc multiplier8             
     bcs no_diff_fix

     sec
     lda multiplier8
     sbc multiplicand8
                
no_diff_fix:
     tay

     sec
mod12:
     lda square_low,x 
     sbc square_low,y
     sta sum8

mod22:
     lda square_high, x
     sbc square_high, y
     sta multiplier8

     // multiplier8 is high byte, sum8 is low byte 
     // sign of product evaluation

     lda multiplicand_sign8
     eor multiplier_sign8         

     beq skip_product_complement8 
     // if product is positive, skip product complement

     sec
     lda #< 65536
     sbc sum8
     sta sum8
     lda #> 65536
     sbc multiplier8
     sta multiplier8     // takes 2 complement of product (16 bit)

skip_product_complement8:
     rts
}
// ================================================================================================================================================ [STOP]


// --------------------------------------------------------------------------------------------------------------------------------------------------- [MATH START]
// Math based routines
// --------------------------------------------------------------------------------------------------------------------------------------------------- [MATH START]


// used for the 16 bit addition & subtraction routines
num1lo:                       .byte 0
num1hi:                       .byte 0
num2lo:                       .byte 0
num2hi:                       .byte 0
resultlo:                .byte 0
resulthi:                .byte 0

// Allocation setup: T1,T2 and PRODUCT preferably on Zero-page.            
//                   square1_lo, square1_hi, square2_lo, square2_hi must be
//                   page aligned. Each table are 512 bytes. Total 2kb.    
//                                                                         
// Table generation: I:0..511                                              
//                   square1_lo = <((I*I)/4)                               
//                   square1_hi = >((I*I)/4)                               
//                   square2_lo = <(((I-255)*(I-255))/4)                   
//                   square2_hi = >(((I-255)*(I-255))/4)                   
//.pc = * "Multiplication tables for fast maths"
.align $100         // Alignment to the nearest page boundary saves a cycle
square1_lo:         .fill 512, <[[i*i]/4]
square1_hi:         .fill 512, >[[i*i]/4]
square2_lo:         .fill 512, <[[[i-255]*[i-255]]/4]
square2_hi:         .fill 512, >[[[i-255]*[i-255]]/4]

T1:                 .word 0
T2:                 .word 0
PRODUCT:            .word 0,0

mulcnd:             .byte 0,0
mulplr:             .byte 0,0
divisor:            .byte 0,0           // AKA the number that dividend is divided by
dividend:                               // AKA the number to be divided
result:             .byte 0,0           // the routine uses this to derive the calculated output.
remainder:          .byte 0,0

divend:             .byte 0,0
divsor:             .byte 0,0
sign:               .byte 0
setovr:             .byte $40
partial:            .byte 0,0
modulo:             .byte 0,0
result2:            .byte 0,0

// squares 0...510 high bytes
square_high:
     .byte  0 , 0 , 0 , 0 , 0
     .byte  0 , 0 , 0 , 0 , 0
     .byte  0 , 0 , 0 , 0 , 0
     .byte  0 , 0 , 0 , 0 , 0
     .byte  0 , 0 , 0 , 0 , 0
     .byte  0 , 0 , 0 , 0 , 0
     .byte  0 , 0 , 1 , 1 , 1
     .byte  1 , 1 , 1 , 1 , 1
     .byte  1 , 1 , 1 , 1 , 1
     .byte  1 , 2 , 2 , 2 , 2
     .byte  2 , 2 , 2 , 2 , 2
     .byte  2 , 3 , 3 , 3 , 3
     .byte  3 , 3 , 3 , 3 , 4
     .byte  4 , 4 , 4 , 4 , 4
     .byte  4 , 4 , 5 , 5 , 5
     .byte  5 , 5 , 5 , 5 , 6
     .byte  6 , 6 , 6 , 6 , 6
     .byte  7 , 7 , 7 , 7 , 7
     .byte  7 , 8 , 8 , 8 , 8
     .byte  8 , 9 , 9 , 9 , 9
     // ***************************

     .byte  9 , 9 , 10 , 10 , 10
     .byte  10 , 10 , 11 , 11 , 11
     .byte  11 , 12 , 12 , 12 , 12
     .byte  12 , 13 , 13 , 13 , 13
     .byte  14 , 14 , 14 , 14 , 15
     .byte  15 , 15 , 15 , 16 , 16
     .byte  16 , 16 , 17 , 17 , 17
     .byte  17 , 18 , 18 , 18 , 18
     .byte  19 , 19 , 19 , 19 , 20
     .byte  20 , 20 , 21 , 21 , 21
     .byte  21 , 22 , 22 , 22 , 23
     .byte  23 , 23 , 24 , 24 , 24
     .byte  25 , 25 , 25 , 25 , 26
     .byte  26 , 26 , 27 , 27 , 27
     .byte  28 , 28 , 28 , 29 , 29
     .byte  29 , 30 , 30 , 30 , 31
     .byte  31 , 31 , 32 , 32 , 33
     .byte  33 , 33 , 34 , 34 , 34
     .byte  35 , 35 , 36 , 36 , 36
     .byte  37 , 37 , 37 , 38 , 38
     // ***************************

     .byte  39 , 39 , 39 , 40 , 40
     .byte  41 , 41 , 41 , 42 , 42
     .byte  43 , 43 , 43 , 44 , 44
     .byte  45 , 45 , 45 , 46 , 46
     .byte  47 , 47 , 48 , 48 , 49
     .byte  49 , 49 , 50 , 50 , 51
     .byte  51 , 52 , 52 , 53 , 53
     .byte  53 , 54 , 54 , 55 , 55
     .byte  56 , 56 , 57 , 57 , 58
     .byte  58 , 59 , 59 , 60 , 60
     .byte  61 , 61 , 62 , 62 , 63
     .byte  63 , 64 , 64 , 65 , 65
     .byte  66 , 66 , 67 , 67 , 68
     .byte  68 , 69 , 69 , 70 , 70
     .byte  71 , 71 , 72 , 72 , 73
     .byte  73 , 74 , 74 , 75 , 76
     .byte  76 , 77 , 77 , 78 , 78
     .byte  79 , 79 , 80 , 81 , 81
     .byte  82 , 82 , 83 , 83 , 84
     .byte  84 , 85 , 86 , 86 , 87
     // ***************************

     .byte  87 , 88 , 89 , 89 , 90
     .byte  90 , 91 , 92 , 92 , 93
     .byte  93 , 94 , 95 , 95 , 96
     .byte  96 , 97 , 98 , 98 , 99
     .byte  100 , 100 , 101 , 101 , 102
     .byte  103 , 103 , 104 , 105 , 105
     .byte  106 , 106 , 107 , 108 , 108
     .byte  109 , 110 , 110 , 111 , 112
     .byte  112 , 113 , 114 , 114 , 115
     .byte  116 , 116 , 117 , 118 , 118
     .byte  119 , 120 , 121 , 121 , 122
     .byte  123 , 123 , 124 , 125 , 125
     .byte  126 , 127 , 127 , 128 , 129
     .byte  130 , 130 , 131 , 132 , 132
     .byte  133 , 134 , 135 , 135 , 136
     .byte  137 , 138 , 138 , 139 , 140
     .byte  141 , 141 , 142 , 143 , 144
     .byte  144 , 145 , 146 , 147 , 147
     .byte  148 , 149 , 150 , 150 , 151
     .byte  152 , 153 , 153 , 154 , 155
     // ***************************

     .byte  156 , 157 , 157 , 158 , 159
     .byte  160 , 160 , 161 , 162 , 163
     .byte  164 , 164 , 165 , 166 , 167
     .byte  168 , 169 , 169 , 170 , 171
     .byte  172 , 173 , 173 , 174 , 175
     .byte  176 , 177 , 178 , 178 , 179
     .byte  180 , 181 , 182 , 183 , 183
     .byte  184 , 185 , 186 , 187 , 188
     .byte  189 , 189 , 190 , 191 , 192
     .byte  193 , 194 , 195 , 196 , 196
     .byte  197 , 198 , 199 , 200 , 201
     .byte  202 , 203 , 203 , 204 , 205
     .byte  206 , 207 , 208 , 209 , 210
     .byte  211 , 212 , 212 , 213 , 214
     .byte  215 , 216 , 217 , 218 , 219
     .byte  220 , 221 , 222 , 223 , 224
     .byte  225 , 225 , 226 , 227 , 228
     .byte  229 , 230 , 231 , 232 , 233
     .byte  234 , 235 , 236 , 237 , 238
     .byte  239 , 240 , 241 , 242 , 243
     // ***************************

     .byte  244 , 245 , 246 , 247 , 248
     .byte  249 , 250 , 251 , 252 , 253
     .byte  254 

     // ***************************


// squares 0...510 low bytes
square_low:
     .byte  0 , 0 , 1 , 2 , 4
     .byte  6 , 9 , 12 , 16 , 20
     .byte  25 , 30 , 36 , 42 , 49
     .byte  56 , 64 , 72 , 81 , 90
     .byte  100 , 110 , 121 , 132 , 144
     .byte  156 , 169 , 182 , 196 , 210
     .byte  225 , 240 , 0 , 16 , 33
     .byte  50 , 68 , 86 , 105 , 124
     .byte  144 , 164 , 185 , 206 , 228
     .byte  250 , 17 , 40 , 64 , 88
     .byte  113 , 138 , 164 , 190 , 217
     .byte  244 , 16 , 44 , 73 , 102
     .byte  132 , 162 , 193 , 224 , 0
     .byte  32 , 65 , 98 , 132 , 166
     .byte  201 , 236 , 16 , 52 , 89
     .byte  126 , 164 , 202 , 241 , 24
     .byte  64 , 104 , 145 , 186 , 228
     .byte  14 , 57 , 100 , 144 , 188
     .byte  233 , 22 , 68 , 114 , 161
     .byte  208 , 0 , 48 , 97 , 146
     // ***************************

     .byte  196 , 246 , 41 , 92 , 144
     .byte  196 , 249 , 46 , 100 , 154
     .byte  209 , 8 , 64 , 120 , 177
     .byte  234 , 36 , 94 , 153 , 212
     .byte  16 , 76 , 137 , 198 , 4
     .byte  66 , 129 , 192 , 0 , 64
     .byte  129 , 194 , 4 , 70 , 137
     .byte  204 , 16 , 84 , 153 , 222
     .byte  36 , 106 , 177 , 248 , 64
     .byte  136 , 209 , 26 , 100 , 174
     .byte  249 , 68 , 144 , 220 , 41
     .byte  118 , 196 , 18 , 97 , 176
     .byte  0 , 80 , 161 , 242 , 68
     .byte  150 , 233 , 60 , 144 , 228
     .byte  57 , 142 , 228 , 58 , 145
     .byte  232 , 64 , 152 , 241 , 74
     .byte  164 , 254 , 89 , 180 , 16
     .byte  108 , 201 , 38 , 132 , 226
     .byte  65 , 160 , 0 , 96 , 193
     .byte  34 , 132 , 230 , 73 , 172
     // ***************************

     .byte  16 , 116 , 217 , 62 , 164
     .byte  10 , 113 , 216 , 64 , 168
     .byte  17 , 122 , 228 , 78 , 185
     .byte  36 , 144 , 252 , 105 , 214
     .byte  68 , 178 , 33 , 144 , 0
     .byte  112 , 225 , 82 , 196 , 54
     .byte  169 , 28 , 144 , 4 , 121
     .byte  238 , 100 , 218 , 81 , 200
     .byte  64 , 184 , 49 , 170 , 36
     .byte  158 , 25 , 148 , 16 , 140
     .byte  9 , 134 , 4 , 130 , 1
     .byte  128 , 0 , 128 , 1 , 130
     .byte  4 , 134 , 9 , 140 , 16
     .byte  148 , 25 , 158 , 36 , 170
     .byte  49 , 184 , 64 , 200 , 81
     .byte  218 , 100 , 238 , 121 , 4
     .byte  144 , 28 , 169 , 54 , 196
     .byte  82 , 225 , 112 , 0 , 144
     .byte  33 , 178 , 68 , 214 , 105
     .byte  252 , 144 , 36 , 185 , 78
     // ***************************

     .byte  228 , 122 , 17 , 168 , 64
     .byte  216 , 113 , 10 , 164 , 62
     .byte  217 , 116 , 16 , 172 , 73
     .byte  230 , 132 , 34 , 193 , 96
     .byte  0 , 160 , 65 , 226 , 132
     .byte  38 , 201 , 108 , 16 , 180
     .byte  89 , 254 , 164 , 74 , 241
     .byte  152 , 64 , 232 , 145 , 58
     .byte  228 , 142 , 57 , 228 , 144
     .byte  60 , 233 , 150 , 68 , 242
     .byte  161 , 80 , 0 , 176 , 97
     .byte  18 , 196 , 118 , 41 , 220
     .byte  144 , 68 , 249 , 174 , 100
     .byte  26 , 209 , 136 , 64 , 248
     .byte  177 , 106 , 36 , 222 , 153
     .byte  84 , 16 , 204 , 137 , 70
     .byte  4 , 194 , 129 , 64 , 0
     .byte  192 , 129 , 66 , 4 , 198
     .byte  137 , 76 , 16 , 212 , 153
     .byte  94 , 36 , 234 , 177 , 120
     // ***************************

     .byte  64 , 8 , 209 , 154 , 100
     .byte  46 , 249 , 196 , 144 , 92
     .byte  41 , 246 , 196 , 146 , 97
     .byte  48 , 0 , 208 , 161 , 114
     .byte  68 , 22 , 233 , 188 , 144
     .byte  100 , 57 , 14 , 228 , 186
     .byte  145 , 104 , 64 , 24 , 241
     .byte  202 , 164 , 126 , 89 , 52
     .byte  16 , 236 , 201 , 166 , 132
     .byte  98 , 65 , 32 , 0 , 224
     .byte  193 , 162 , 132 , 102 , 73
     .byte  44 , 16 , 244 , 217 , 190
     .byte  164 , 138 , 113 , 88 , 64
     .byte  40 , 17 , 250 , 228 , 206
     .byte  185 , 164 , 144 , 124 , 105
     .byte  86 , 68 , 50 , 33 , 16
     .byte  0 , 240 , 225 , 210 , 196
     .byte  182 , 169 , 156 , 144 , 132
     .byte  121 , 110 , 100 , 90 , 81
     .byte  72 , 64 , 56 , 49 , 42
     // ***************************

     .byte  36 , 30 , 25 , 20 , 16
     .byte  12 , 9 , 6 , 4 , 2
     .byte  1 

// --------------------------------------------------------------------------------------------------------------------------------------------------- [MATH STOP]


