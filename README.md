# Smalltro — DarkZone / Syntax 2020

C64 intro released by [DarkZone](https://darkzone.no/) at [Syntax 2020](https://www.syntaxparty.org/) in Melbourne, Australia. Originally intended as a Flashback 2020 compo entry — Covid-19 cancelled that party, so it was released at Syntax instead.

- **Release on CSDB:** https://csdb.dk/release/?id=197959
- **Run in browser:** https://jorgen.skogstad.com/8-16bit/smalltro/

## About

A C64 intro featuring a full-screen Koala bitmap, sprite-based DarkZone logo, raster interrupt effects, and a SID tune. Uses inline Exomizer crunching via [kickass-cruncher-plugins](https://github.com/p-a/kickass-cruncher-plugins) to pack bitmap data at assembly time.

Code by Agnostic (TerraCom) and Syntax Error. Graphics by Kingpin. Sprites from the Butt Fat 256kb Sprite Font Compo (CSDB #180797). Font: 7up.64c by Koefler.de. Music: PSOMA2 by SidTracker64.

## Repository layout

```
dz_smalltro_2020_v21_final.asm    Main entry point — assemble this file
code/                              Source modules (imported by main file)
macros/macros.asm                  KickAssembler macro library
bitmaps/                           C64 Koala graphics (.kla)
sprite_font/                       DarkZone logo sprite binary data
font/                              Custom character font
resources/                         SID tune
build.sh                           Build script
```

## Building

Requires [KickAssembler 5.x](https://theweb.dk/KickAssembler/), [kickass-cruncher-plugins 2.0](https://github.com/p-a/kickass-cruncher-plugins), and **Java 11+** (the cruncher plugin requires Java 11).

```bash
# With both JARs on CLASSPATH:
./build.sh

# Or explicitly:
KICKASS_CP=/path/to/KickAss.jar:/path/to/kickass-cruncher-plugins-2.0.jar ./build.sh
```

Output: `dz_smalltro_2020_v21_final.prg` — load into VICE or any C64 emulator.

## Tools used

- [KickAssembler](https://theweb.dk/KickAssembler/) — 6502 assembler
- [kickass-cruncher-plugins](https://github.com/p-a/kickass-cruncher-plugins) — inline Exomizer crunching
- [Exomizer](https://bitbucket.org/magli143/exomizer/wiki/Home) — binary cruncher (for final release `.prg`)
- [Multipaint](http://multipaint.kameli.net/) — C64 graphics
- [VICE](https://vice-emu.sourceforge.io/) — C64 emulator for testing

## Group

[DarkZone](https://darkzone.no/) is a Norwegian demogroup founded in 1992.
