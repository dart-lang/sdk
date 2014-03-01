#! /bin/bash

# Update git submodules
git submodule init
git submodule update

# Set up the android environment
source tools/android/setup.sh

cat > load-list.txt <<EOF
^[a].*
EOF
./run-tests.sh -b Remote --remote-executor http://localhost:9515 --remote-caps="chromeOptions=androidPackage=$CHROME_APP" --load-list load-list.txt --verbose || exit 1
cat > load-list.txt <<EOF
^[^a].*
EOF
./run-tests.sh -b Remote --remote-executor http://localhost:9515 --remote-caps="chromeOptions=androidPackage=$CHROME_APP" --load-list load-list.txt --verbose || exit 1

echo "Run $ANDROID_DIR/stop.sh if finished."
