#!/bin/bash

function add_dependency_override() {
  local name=$1
  local path=$2
  if ! cat pubspec.yaml | grep "dependency_overrides:" ; then
    echo "dependency_overrides:" >> pubspec.yaml
  fi
  local pubspec=`cat pubspec.yaml | grep -v "$name: .path: "`
  echo "$pubspec" > pubspec.yaml
  if [[ -n "$path" ]]; then
    echo "  $name: {path: $path}" >> pubspec.yaml
  fi
}

function checkout_dependency_override_from_github() {
  local dependency_name=$1
  local org_project=$2
  local branch=$3
  local path=${4:-/}

  local url=https://github.com/$org_project

  echo "** Checking out $dependency_name override from $url$path#$branch"

  : ${TMPDIR:="/tmp"}
  local dep_dir=$TMPDIR/dependency_overrides/$dependency_name

  [[ -d `dirname $dep_dir` ]] || mkdir `dirname $dep_dir`

  if [[ -d $dep_dir ]]; then
    # Check there's no local modifications before removing existing directory.
    (
      cd $dep_dir
      if git status -s | grep . ; then
        echo "Found local modifications in $dep_dir: aborting"
        exit 1
      fi
    )
    rm -fR $dep_dir
  fi

  if [[ "$path" == "/" ]]; then
    # Checkout only the branch, with no history:
    git clone --depth 1 --branch $branch $url $dep_dir
  else
    (
      mkdir $dep_dir
      cd $dep_dir

      # Sparse-checkout only the path + branch, with no history:
      git init
      git remote add origin $url
      git config core.sparsecheckout true
      echo $path >> .git/info/sparse-checkout
      git pull --depth=1 origin $branch
    )
  fi
  add_dependency_override $dependency_name $dep_dir$path
}
