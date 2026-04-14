#!/bin/bash
# Build Smalltro using KickAssembler 5.x + kickass-cruncher-plugins 2.0
# Requires Java 11+ (uses Exomizer inline crunching via kickass-cruncher-plugins)
#
# https://theweb.dk/KickAssembler/
# https://github.com/p-a/kickass-cruncher-plugins
#
# Usage:
#   KICKASS_CP=/path/to/KickAss.jar:/path/to/kickass-cruncher-plugins-2.0.jar ./build.sh
#
# Or set CLASSPATH to include both JARs and run:
#   java cml.kickass.KickAssembler dz_smalltro_2020_v21_final.asm

KICKASS_CP="${KICKASS_CP:-$CLASSPATH}"
java -cp "$KICKASS_CP" cml.kickass.KickAssembler dz_smalltro_2020_v21_final.asm
