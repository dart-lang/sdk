#!/usr/bin/env bash
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This script updates the flutter engine DEPS file with the
# Dart SDK dependencies.
#
# Usage: src/flutter/third_party/dart/tools/patches/flutter-engine/apply.sh
# (run inside the root of a flutter engine checkout)

set -e

DIR=$(dirname -- "$(which -- "$0")")
. $DIR/../utils.sh

ensure_in_checkout_root

pinned_dart_sdk=$(get_pinned_dart_version)
need_runhooks=false

# Update the flutter DEPS with the revisions in the Dart SDK DEPS.
src/tools/dart/create_updated_flutter_deps.py
if ! (cd src/flutter && git diff --exit-code DEPS); then
  need_runhooks=true
fi

if [ $need_runhooks = true ]; then
  # Check if .gclient configuration specifies a cache_dir. Local caches are used
  # by bots to reduce amount of Git traffic. .gclient configuration file
  # is a well-formed Python source so use Python load_source to parse it.
  # If cache_dir is specified then we need to force update the git cache,
  # otherwise git fetch below might fail to find tags and commits we are
  # referencing.
  # Normally gclient sync would update the cache - but we are bypassing
  # it here.
  git_cache=$(python3 -c '\
import importlib.util
import importlib.machinery

def load_source(modname, filename):
    loader = importlib.machinery.SourceFileLoader(modname, filename)
    spec = importlib.util.spec_from_file_location(modname, filename, loader=loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module

config = load_source("config", ".gclient");
print(getattr(config, "cache_dir", ""))')

  # DEPS file might have been patched with new version of packages that
  # Dart SDK depends on. Get information about dependencies from the
  # DEPS file and forcefully update checkouts of those dependencies.
  gclient revinfo --ignore-dep-type=cipd | grep 'src/flutter/third_party/dart/third_party' | while read -r line; do
    # revinfo would produce lines in the following format:
    #     path: git-url@tag-or-hash
    # Where no spaces occur inside path, git-url or tag-or-hash.
    # To extract path and tag-or-hash we replace ': ' and '@' with ' '
    # and then create array from the resulting string which splits it
    # by whitespace.
    line="${line/: / }"
    line="${line/@/ }"
    line=(${line})
    dependency_path=${line[0]}
    repo=${line[1]}
    dependency_tag_or_hash=${line[2]}

    # If the dependency does not exist (e.g. was newly added) we need to clone
    # the repository first into the right location.
    if [ ! -e ${dependency_path} ]; then
      git clone ${repo} ${dependency_path}
    fi
    # Inside dependency compare HEAD to specified tag-or-hash by rev-parse'ing
    # them and comparing resulting hashes.
    # Note: tag^0 forces rev-parse to return commit hash rather then the hash of
    # the tag object itself.
    pushd ${dependency_path} > /dev/null
    if [ $(git rev-parse HEAD) != $(git rev-parse ${dependency_tag_or_hash}^0) ]; then
      echo "${dependency_path} requires update to match DEPS file"
      if [ "$git_cache" != "" ]; then
        echo "--- Forcing update of the git_cache ${git_cache}"
        git cache fetch -c ${git_cache} --all -v
      fi
      git fetch origin
      git checkout ${dependency_tag_or_hash}
    fi
    popd > /dev/null
  done
  gclient runhooks
fi
