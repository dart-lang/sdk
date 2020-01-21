#!/usr/bin/env bash
#
# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

set -ex

#
# Build a workspace component from a package.
#
# $1: the name of the package
# $2: the name of the repository (same as package if missing)
# $3: branch to clone from (master if missing).  Do not select multiple
#     different branches for the same repo, that
#     will not work and is not enforced.
# $4: subdirectory of the repository applicable to the package (root if missing)
function make_clone_from_package {
  local package_name="$1"
  local repo_name="$2"
  local branch="$3"
  local subdir="$4"

  [ -z "${repo_name}" ] && repo_name=${package_name}
  [ -z "${branch}" ] && branch=master
  [ -z "${subdir}" ] && subdir=.

  add_repo_to_workspace "${repo_name}" "${branch}"
  ln -sfn "_repos/${repo_name}/${subdir}" "${package_name}"

  grep -v "^${package_name}:file://" .packages >> .packages.new || true
  echo "${package_name}:file://$(pwd)/$(readlink ${package_name})/lib" \
    >> .packages.new
  mv .packages.new .packages
}

# HACK ALERT: no associative arrays in bash 3 and eval is a bad idea.  Use
# files instead.  :-(
repos_changed_this_run="`mktemp`"
done_this_run="`mktemp`"
trap _cleanup EXIT
function _cleanup {
  rm -f "${done_this_run}" "${repos_changed_this_run}"
}

# Returns true if we have already processed this repository or package.
#
# Repository names are prefixed with "_repos/", package names are plain.
#
# $1: repository or package name
function already_done_this_run {
  grep -q "^$1$" "${done_this_run}"
  return $?
}

# Adds the parameter to the run log file.
#
# $1: package name, or repository name prefixed with '_repos/'.
function log_this_run {
  echo "$1" >> "${done_this_run}"
}

# Returns true if when pulling this repository it changed.
#
# Unlike `already_done_this_run`, repository names are plain.
#
# $1: repository name
function repo_changed_this_run {
  grep -q "^$1$" "${repos_changed_this_run}"
  return $?
}

# Adds the parameter to the repository changed log.
#
# $1: repository name
function log_repo_changed_this_run {
  echo "$1" >> "${repos_changed_this_run}"
}

#
# Add a git repository to the workspace.
#
# $1: the name of the repository
# $2: branch to clone from
function add_repo_to_workspace {
  local repo_name="$1"
  local branch="$2"
  local clone

  local curr_head
  local prev_head

  if already_done_this_run "_repos/${repo_name}" ; then return 0 ; fi
  log_this_run "_repos/${repo_name}"

  if [ -d "_repos/${repo_name}" ] ; then
    pushd "_repos/${repo_name}"
    prev_head="$(git rev-parse HEAD)"
    ${NO_UPDATE} git pull originHTTP ${branch}
    curr_head="$(git rev-parse HEAD)"
    if [ "${prev_head}" != "${curr_head}" ] ; then
      log_repo_changed_this_run "${repo_name}"
    fi
    popd
    return $?
  fi

  case "${repo_name}" in
    archive) clone="git@github.com:brendan-duncan/${repo_name}.git" ;;
    build_verify) clone="git@github.com:kevmoo/${repo_name}.git" ;;
    build_version) clone="git@github.com:kevmoo/${repo_name}.git" ;;
    csv) clone="git@github.com:close2/csv.git" ;;
    git) clone="git@github.com:kevmoo/${repo_name}.git" ;;
    node-interop) clone="git@github.com:pulyaevskiy/node-interop.git" ;;
    node_preamble) clone="git@github.com:mbullington/${repo_name}.dart.git" ;;
    source_gen_test) clone="git@github.com:kevmoo/${repo_name}.git" ;;
    quiver-dart) clone="git@github.com:google/${repo_name}.git" ;;
    uuid) clone="git@github.com:Daegalus/dart-uuid.git" ;;
    *.dart) clone="git@github.com:google/${repo_name}" ;;
    *)
      clone="git@github.com:dart-lang/${repo_name}.git"
      echo "WARNING: using default for ${repo_name}, this might not work"
    ;;
  esac

  mkdir -p _repos
  pushd "_repos"
  git init "${repo_name}"
  pushd "${repo_name}"
  git remote add "origin" -t "${branch}" "${clone}"
  # Use HTTP for pulls to reduce authentication overhead and excessive pressing
  # of authentication tokens.  This means we might be prompted for
  # username/password if a package does not exist, but that's
  # the tradeoff.
  git remote add "originHTTP" -t "${branch}" \
    $(echo "${clone}" | sed s,^git@github.com:,https://github.com/,g)
  git config core.sparsecheckout true
  echo "**" >> .git/info/sparse-checkout
  echo "!**/.packages" >> .git/info/sparse-checkout
  echo "!**/pubspec.lock" >> .git/info/sparse-checkout
  echo "!**/.dart_tool/package_config.json" >> .git/info/sparse-checkout
  # TODO(jcollins-g): Usual bag of tricks does not work to stop git pull from
  # prompting and force it to hard fail if authentication is required.  Why?
  if ! git pull --depth=1 originHTTP ; then
    echo error cloning: "${clone}".  Cleaning up
    popd
    # We remove the repository here so that if you're iteratively adding new
    # repository configurations, a rerun of the script will re-initialize the
    # misconfigured repository.
    rm -rf "${repo_name}"
    popd
    return 2
  fi
  log_repo_changed_this_run "${repo_name}"
  popd
  popd
}


# Tries pub get multiple times since it occasionally fails.
# Returns false if we ran out of retries.
function pub_get_with_retries {
  for try in 1 2 3 4 5 ; do
    if pub get ; then return 0 ; fi
    sleep $[$try * $try]
  done
  return 1
}


#
# Add a package, recursively, to the workspace.  A package may add its own
# repository, or use an existing one.
#
# $1: the package name.  Must be one of the packages we know the location of.
#
function add_package_to_workspace {
  local package_name="$1"

  if already_done_this_run "${package_name}" ; then return 0 ; fi
  log_this_run "${package_name}"

  if [ -d "${package_name}" ] ; then {
    pushd "${package_name}"
    prev_head="$(git rev-parse HEAD)"
    popd
  } ; fi

  local repo

  case "${package_name}" in
    _fe_analyzer_shared) repo=sdk
      make_clone_from_package _fe_analyzer_shared "${repo}" master pkg/_fe_analyzer_shared ;;
    analysis_tool) repo=sdk
      make_clone_from_package analysis_tool "${repo}" master pkg/analysis_tool ;;
    analyzer) repo=sdk
      make_clone_from_package analyzer "${repo}" master pkg/analyzer ;;
    build) repo=build
      make_clone_from_package build "${repo}" master build ;;
    build_config) repo=build
      make_clone_from_package build_config "${repo}" master build_config ;;
    build_daemon) repo=build
      make_clone_from_package build_daemon "${repo}" master build_daemon ;;
    build_integration) repo=sdk
      make_clone_from_package build_integration "${repo}" master pkg/build_integration ;;
    build_modules) repo=build
      make_clone_from_package build_modules "${repo}" master build_modules ;;
    build_node_compilers) repo=node-interop
      make_clone_from_package build_node_compilers "${repo}" master build_node_compilers ;;
    build_resolvers) repo=build
      make_clone_from_package build_resolvers "${repo}" master build_resolvers ;;
    build_runner) repo=build
      make_clone_from_package build_runner "${repo}" master build_runner ;;
    build_runner_core) repo=build
      make_clone_from_package build_runner_core "${repo}" master build_runner_core;;
    build_test) repo=build
      make_clone_from_package build_test "${repo}" master build_test ;;
    build_vm_compilers) repo=build
      make_clone_from_package build_vm_compilers "${repo}" master build_vm_compilers ;;
    build_web_compilers) repo=build
      make_clone_from_package build_web_compilers "${repo}" master build_web_compilers ;;
    built_collection) repo=built_collection.dart
      make_clone_from_package built_collection "${repo}" ;;
    built_value) repo=built_value.dart
      make_clone_from_package built_value "${repo}" master built_value ;;
    built_value_generator) repo=built_value.dart
      make_clone_from_package built_value_generator "${repo}" master built_value_generator ;;
    checked_yaml) repo=json_serializable
      make_clone_from_package checked_yaml "${repo}" master checked_yaml ;;
    expect) repo=sdk
      make_clone_from_package expect "${repo}" master pkg/expect ;;
    front_end) repo=sdk
      make_clone_from_package front_end "${repo}" master pkg/front_end ;;
    grinder) repo=grinder.dart
      make_clone_from_package grinder "${repo}" ;;
    kernel) repo=sdk
      make_clone_from_package kernel "${repo}" master pkg/kernel ;;
    meta) repo=sdk
      make_clone_from_package meta "${repo}" master pkg/meta ;;
    node_interop) repo=node-interop
      make_clone_from_package node_interop "${repo}" master node_interop ;;
    node_io) repo=node-interop
      make_clone_from_package node_io "${repo}" master node_io ;;
    js) repo=sdk
      make_clone_from_package js "${repo}" master pkg/js ;;
    json_annotation) repo=json_serializable
      make_clone_from_package json_annotation "${repo}" master json_annotation ;;
    json_serializable) repo=json_serializable
      make_clone_from_package json_serializable "${repo}" master json_serializable ;;
    protobuf) repo=protobuf
      make_clone_from_package protobuf "${repo}" master protobuf ;;
    scratch_space) repo=build
      make_clone_from_package scratch_space "${repo}" master scratch_space ;;
    source_gen) repo=source_gen
      make_clone_from_package source_gen "${repo}" master source_gen ;;
    source_gen_test) repo=source_gen_test
      make_clone_from_package source_gen_test "${repo}" ;;
    test) repo=test
      make_clone_from_package test "${repo}" master pkgs/test ;;
    test_api) repo=test
      make_clone_from_package test_api "${repo}" master pkgs/test_api ;;
    test_core) repo=test
      make_clone_from_package test_core "${repo}" master pkgs/test_core ;;
    testing) repo=sdk
      make_clone_from_package testing "${repo}" master pkg/testing ;;
    vm_service) repo=sdk
      make_clone_from_package vm_service "${repo}" master pkg/vm_service ;;
    quiver) repo=quiver-dart
      make_clone_from_package quiver "${repo}" ;;
    *) repo="${package_name}"
      make_clone_from_package "${package_name}" ;;
  esac

  # Use the .packages file to check for packages we've completed in the
  # past, and refresh them all.  This enables us to detect if we need to rerun
  # pub for any of them.
  if [ -e ".packages" -a -z "${HAVE_DONE_GLOBAL_REFRESH}" ] ; then
    HAVE_DONE_GLOBAL_REFRESH=1
    for n in $(grep -v '^#' ".packages" | cut -f 1 -d :) ; do
      add_package_to_workspace "$n"
    done
  fi

  if [ "${package_name}" = "kernel" ] ; then
    # HACK ALERT: kernel depends on unpublished packages, so we can't use pub.
    for n in args meta expect front_end test testing ; do
      add_package_to_workspace "$n"
    done
  else
    pushd "${package_name}"
    if [ -n "${NO_UPDATE}" ] || repo_changed_this_run "${repo}" ; then
      pub_get_with_retries
      popd
      # HACK ALERT: assumes '.pub-cache' is in the path of the real pub cache.
      # Packages referring to other packages via path in pubspec.yaml are not
      # supported at all and we do not include dependencies derived that way
      # exclusively.
      for n in $(grep -v '^#' "${package_name}/.packages" | grep '.pub-cache' | cut -f 1 -d :) ; do
        add_package_to_workspace "$n"
      done
    else
      popd
    fi
  fi
  rm -f "${package_name}/.packages"
  rm -f "${package_name}/pubspec.lock"
  rm -f "${package_name}/.dart_tool/package_config.json"
}


#
# Creates a flat workspace for the given package name.
#
# All repositories are checked out no more than once under _repos.  These
# clones are "stock" without full history but should still be usable to make
# changes on -- the main issue is that all of them have any checked in
# .packages, pubspec.lock, or package_config.json files hidden.  This could
# impact test running in the SDK if dev_dependencies are not fully specified in
# pubspec.yaml -- modify this script to add the necessary entries if need be.
#
# Symlinks to package directories are placed in the root of the workspace for
# convenience.
#
# One .packages file to rule them all is placed in the root of the workspace --
# do not run pub get yourself on any of the packages.
#
# Set "NO_UPDATE" to "echo" to not try git pull on existing repos and to assume
# we always have to re-pub-get.  This is useful in debugging the script and
# iteratively adding repository configurations.
#
# This script might be able to update your existing workspace, or it might
# trash it completely.  Make backups.
#
function main {
  if [ -z "$1" -o -z "$2" ] ; then
    echo usage: $0 source_package_name workspace_dir
    return 2
  fi

  DEST_WORKSPACE_ROOT="$2"

  mkdir -p ${DEST_WORKSPACE_ROOT}
  cd ${DEST_WORKSPACE_ROOT}

  add_package_to_workspace "$1"
}


main "$@"