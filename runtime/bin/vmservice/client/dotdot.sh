#!/bin/sh

perl -pi -w -e 's#packages/observatory/src/elements/#../../../../packages/observatory/src/elements/#g;' $*
