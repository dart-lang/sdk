#!/usr/bin/env bash
# Updates DEPS to the latest co19 CIPD package.

set -e
set -x

if [ ! -e tests/co19 ]; then
  echo "$0: error: Run this script at the root of the Dart SDK" >&2
  exit 1
fi

# Find the latest co19 commit.
rm -rf tests/co19/src.git
git clone https://dart.googlesource.com/co19 tests/co19/src.git
CO19=tests/co19/src.git
OLD=$(gclient getdep --var=co19_rev)
NEW=$(cd $CO19 && git fetch origin && git rev-parse origin/master)

git fetch origin
git branch cl-co19-roll-co19-to-$NEW origin/main
git checkout cl-co19-roll-co19-to-$NEW

# Update DEPS:
gclient setdep --var=co19_rev=$NEW

# Make a nice commit. Don't include the '#' character to avoid referencing Dart
# SDK issues.
git commit DEPS -m \
  "$(printf "[co19] Roll co19 to $NEW\n\n" \
  && cd $CO19 \
  && git log --date='format:%Y-%m-%d' --pretty='format:%ad %ae %s' $OLD..$NEW \
    | sed 's/\#/dart-lang\/co19\#/g')"

rm -rf tests/co19/src.git

GIT_EDITOR=true git cl upload
ISSUE=$(git config --get branch.cl-co19-roll-co19-to-$NEW.gerritissue)

git cl web
