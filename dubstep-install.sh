#!/bin/sh

rm -rf /System/Applications/GWorkspace.app
. /System/Library/Makefiles/GNUstep.sh
export GNUSTEP_INSTALLATION_DOMAIN=SYSTEM
./configure && gmake && gmake install


