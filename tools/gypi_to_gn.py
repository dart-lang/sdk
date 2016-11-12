#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Converts given gypi files to a python scope and writes the result to stdout.

It is assumed that the files contain a toplevel dictionary, and this script
will return that dictionary as a GN "scope" (see example below). This script
does not know anything about GYP and it will not expand variables or execute
conditions.

It will strip conditions blocks.

A variables block at the top level will be flattened so that the variables
appear in the root dictionary. This way they can be returned to the GN code.

Say your_file.gypi looked like this:
  {
     'sources': [ 'a.cc', 'b.cc' ],
     'defines': [ 'ENABLE_DOOM_MELON' ],
  }

You would call it like this:
  gypi_files = [ "your_file.gypi", "your_other_file.gypi" ]
  gypi_values = exec_script("//build/gypi_to_gn.py",
                            [ rebase_path(gypi_files) ],
                            "scope",
                            [ gypi_files ])

Notes:
 - The rebase_path call converts the gypi file from being relative to the
   current build file to being system absolute for calling the script, which
   will have a different current directory than this file.

 - The "scope" parameter tells GN to interpret the result as a series of GN
   variable assignments.

 - The last file argument to exec_script tells GN that the given file is a
   dependency of the build so Ninja can automatically re-run GN if the file
   changes.

Read the values into a target like this:
  component("mycomponent") {
    sources = gypi_values.your_file_sources
    defines = gypi_values.your_file_defines
  }

Sometimes your .gypi file will include paths relative to a different
directory than the current .gn file. In this case, you can rebase them to
be relative to the current directory.
  sources = rebase_path(gypi_values.your_files_sources, ".",
                        "//path/gypi/input/values/are/relative/to")

This script will tolerate a 'variables' in the toplevel dictionary or not. If
the toplevel dictionary just contains one item called 'variables', it will be
collapsed away and the result will be the contents of that dictinoary. Some
.gypi files are written with or without this, depending on how they expect to
be embedded into a .gyp file.

This script also has the ability to replace certain substrings in the input.
Generally this is used to emulate GYP variable expansion. If you passed the
argument "--replace=<(foo)=bar" then all instances of "<(foo)" in strings in
the input will be replaced with "bar":

  gypi_values = exec_script("//build/gypi_to_gn.py",
                            [ rebase_path("your_file.gypi"),
                              "--replace=<(foo)=bar"],
                            "scope",
                            [ "your_file.gypi" ])

"""

import gn_helpers
from optparse import OptionParser
import sys
import os.path

def LoadPythonDictionary(path):
  file_string = open(path).read()
  try:
    file_data = eval(file_string, {'__builtins__': None}, None)
  except SyntaxError, e:
    e.filename = path
    raise
  except Exception, e:
    raise Exception("Unexpected error while reading %s: %s" % (path, str(e)))

  assert isinstance(file_data, dict), "%s does not eval to a dictionary" % path

  # Flatten any variables to the top level.
  if 'variables' in file_data:
    file_data.update(file_data['variables'])
    del file_data['variables']

  # Strip any conditions.
  if 'conditions' in file_data:
    del file_data['conditions']
  if 'target_conditions' in file_data:
    del file_data['target_conditions']

  # Strip targets in the toplevel, since some files define these and we can't
  # slurp them in.
  if 'targets' in file_data:
    del file_data['targets']

  return file_data


def KeepOnly(values, filters):
  """Recursively filters out strings not ending in "f" from "values"""

  if isinstance(values, list):
    return [v for v in values if v.endswith(tuple(filters))]

  if isinstance(values, dict):
    result = {}
    for key, value in values.items():
      new_key = KeepOnly(key, filters)
      new_value = KeepOnly(value, filters)
      result[new_key] = new_value
    return result

  return values

def main():
  parser = OptionParser()
  parser.add_option("-k", "--keep_only", default = [], action="append",
    help="Keeps only files ending with the listed strings.")
  parser.add_option("--prefix", action="store_true",
    help="Prefix variables with base name")
  (options, args) = parser.parse_args()

  if len(args) < 1:
    raise Exception("Need at least one .gypi file to read.")

  data = {}

  for gypi in args:
    gypi_data = LoadPythonDictionary(gypi)

    if options.keep_only != []:
      gypi_data = KeepOnly(gypi_data, options.keep_only)

    # Sometimes .gypi files use the GYP syntax with percents at the end of the
    # variable name (to indicate not to overwrite a previously-defined value):
    #   'foo%': 'bar',
    # Convert these to regular variables.
    for key in gypi_data:
      if len(key) > 1 and key[len(key) - 1] == '%':
        gypi_data[key[:-1]] = gypi_data[key]
        del gypi_data[key]
    gypi_name = os.path.basename(gypi)[:-len(".gypi")]
    for key in gypi_data:
      if options.prefix:
        # Prefix all variables from this gypi file with the name to disambiguate
        data[gypi_name + "_" + key] = gypi_data[key]
      elif key in data:
        for entry in gypi_data[key]:
            data[key].append(entry)
      else:
        data[key] = gypi_data[key]

  print gn_helpers.ToGNString(data)

if __name__ == '__main__':
  try:
    main()
  except Exception, e:
    print str(e)
    sys.exit(1)
