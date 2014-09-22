#!/bin/bash
#
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Script to create a Debian wheezy chroot environment for building Dart
# Debian packages.
#

function usage {
  USAGE="Usage: $0 i386|amd64 [target dir] [be|dev|<stable version>]]\n
\n
The first mandatory argument speciifies the CPU architecture using\n
the Debian convention (e.g. i386 and amd64).\n
\n
The second optional argument specifies the destination\n
directory. This defaults to 'debian_<architecture>'.\n
\n
The third optional argument specifies whether the chroot is\n
populated with a Dart checkout. Use 'be' for bleeding edge, 'dev'\n
for trunk/developer or the specific version number for a stable\n
version (e.g. 1.2)."

  echo -e $USAGE
  exit 1
}

# Expect one to three arguments, architecture, optional directory and
# optional channel.
if [ $# -lt 1 ] || [ $# -gt 3 ]
then
  usage
fi

ARCH=$1

if [ -n "$2" ]
then
  CHROOT=$2
else
  CHROOT=debian_$ARCH
fi

if [ -n "$3" ]
then
  CHANNEL=$3
fi

if [ "$ARCH" != "i386" ] && [ "$ARCH" != "amd64" ]
then
  usage
fi

SVN_REPRO="http://dart.googlecode.com/svn/"
if [ -n "$CHANNEL" ]
then
  if [ "$CHANNEL" == "be" ]
  then
    SVN_PATH="branches/bleeding_edge/deps/all.deps"
  elif [ "$CHANNEL" == "dev" ]
  then
    SVN_PATH="trunk/deps/all.deps"
  else
    SVN_PATH="branches/$CHANNEL/deps/all.deps"
  fi
  SRC_URI=$SVN_REPRO$SVN_PATH
fi

# Create Debian wheezy chroot.
debootstrap --arch=$ARCH --components=main,restricted,universe,multiverse \
    wheezy $CHROOT http://http.us.debian.org/debian/
chroot $CHROOT apt-get update
chroot $CHROOT apt-get -y install \
    debhelper python g++-4.6 git subversion

# Add chrome-bot user.
chroot $CHROOT groupadd --gid 1000 chrome-bot
chroot $CHROOT useradd --gid 1000 --uid 1000 --create-home chrome-bot
mkdir $CHROOT/b
chown 1000:1000 $CHROOT/b

# Create trampoline script for running the initialization as chrome-bot.
cat << EOF > $CHROOT/b/init_chroot_trampoline.sh
#!/bin/sh
su -c /b/init_chroot.sh chrome-bot
EOF

# Create initialization script which does nothing.
cat << 'EOF' > $CHROOT/b/init_chroot.sh
#!/bin/sh
cd /b
EOF

# If the channel is set extend the initialization script to check out
# the Dart sources. This uses two cat commands as the first part needs
# to bypass variable interpretation.
if [ -n "$SRC_URI" ]
then
cat << 'EOF' >> $CHROOT/b/init_chroot.sh
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$PATH:/b/depot_tools
EOF

cat << EOF >> $CHROOT/b/init_chroot.sh
gclient config $SRC_URI
gclient sync
gclient runhooks
EOF
fi

chmod 755 $CHROOT/b/init_chroot_trampoline.sh

chown 1000:1000 $CHROOT/b/init_chroot.sh
chmod 755 $CHROOT/b/init_chroot.sh
chroot $CHROOT /bin/sh /b/init_chroot_trampoline.sh
