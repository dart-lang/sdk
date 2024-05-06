#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Usage: scan_deps.py --deps <DEPS file> --output <parsed lockfile>
#
# This script extracts the dependencies provided from the DEPS file and
# finds the appropriate git commit hash per dependency for osv-scanner
# to use in checking for vulnerabilities.
# It is expected that the lockfile output of this script is then
# uploaded using GitHub actions to be used by the osv-scanner reusable action.

import argparse
import json
import os
import re
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(sys.argv[0])
CHECKOUT_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
DEP_CLONE_DIR = CHECKOUT_ROOT + '/clone-test'
DEPS = os.path.join(CHECKOUT_ROOT, 'DEPS')


# Used in parsing the DEPS file.
class VarImpl:
  _env_vars = {
      'host_cpu': 'x64',
      'host_os': 'linux',
  }

  def __init__(self, local_scope):
    self._local_scope = local_scope

  def lookup(self, var_name):
    """Implements the Var syntax."""
    if var_name in self._local_scope.get('vars', {}):
      return self._local_scope['vars'][var_name]
    # Inject default values for env variables.
    if var_name in self._env_vars:
      return self._env_vars[var_name]
    raise Exception('Var is not defined: %s' % var_name)


def extract_deps(deps_file):
  local_scope = {}
  var = VarImpl(local_scope)
  global_scope = {
      'Var': var.lookup,
      'deps_os': {},
  }
  # Read the content.
  with open(deps_file, 'r') as file:
    deps_content = file.read()

  # Eval the content.
  exec(deps_content, global_scope, local_scope)

  if not os.path.exists(DEP_CLONE_DIR):
    os.mkdir(DEP_CLONE_DIR)  # Clone deps with upstream into temporary dir.

  # Extract the deps and filter.
  deps = local_scope.get('deps', {})
  filtered_osv_deps = []
  for _, dep in deps.items():
    # We currently do not support packages or cipd which are represented
    # as dictionaries.
    if not isinstance(dep, str):
      continue

    dep_split = dep.rsplit('@', 1)
    filtered_osv_deps.append({
          'package': {'name': dep_split[0], 'commit': dep_split[1]}
      })

  try:
    # Clean up cloned upstream dependency directory.
    shutil.rmtree(
        DEP_CLONE_DIR
    )  # Use shutil.rmtree since dir could be non-empty.
  except OSError as clone_dir_error:
    print(
        'Error cleaning up clone directory: %s : %s' %
        (DEP_CLONE_DIR, clone_dir_error.strerror)
    )

  osv_result = {
      'packageSource': {'path': deps_file, 'type': 'lockfile'},
      'packages': filtered_osv_deps
  }
  return osv_result


def parse_args(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to find common ancestor commit SHAs'
  )

  parser.add_argument(
      '--deps',
      '-d',
      type=str,
      help='Input DEPS file to extract.',
      default=os.path.join(CHECKOUT_ROOT, 'DEPS')
  )
  parser.add_argument(
      '--output',
      '-o',
      type=str,
      help='Output osv-scanner compatible deps file.',
      default=os.path.join(CHECKOUT_ROOT, 'osv-lockfile.json')
  )

  return parser.parse_args(args)


def write_manifest(deps, manifest_file):
  output = {'results': [deps]}
  print(json.dumps(output, indent=2))
  with open(manifest_file, 'w') as manifest:
    json.dump(output, manifest, indent=2)


def main(argv):
  args = parse_args(argv)
  deps = extract_deps(args.deps)
  write_manifest(deps, args.output)
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))