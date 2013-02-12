#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module generates Dart Chrome APIs from the Chrome IDL files."""

import sys
import os

# The path to the JSON Schema Compiler, which can be run to generate the files.
# Lives in the Chromium repository, so needs to be pulled in somehow.
COMPILER = "../../../third_party/chrome_api_tools/compiler.py"

# The path to the Chrome IDL files. They live in the Chromium repository, so
# need to be pulled in somehow.
API_DIR = "../../../third_party/chrome_api/"

# The path to the custom overrides directory, containing override files.
OVERRIDES_DIR = "../src/chrome/custom_dart/"

# The path to where the generated .dart files should be saved.
OUTPUT_DIR = "../src/chrome/"

# The path to where the output template file is. This file will be populated
# with TEMPLATE_CONTENT, followed by the list of generated .dart files.
OUTPUT_TEMPLATE = "../templates/html/dart2js/chrome_dart2js.darttemplate"

# The content to fill OUTPUT_TEMPLATE with. Will be followed by a list of the
# names of the generated .dart files.
TEMPLATE_CONTENT = """
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:chrome library.

/// Native wrappers for the Chrome Packaged App APIs.
///
/// These functions allow direct access to the Packaged App APIs, allowing
/// Chrome Packaged Apps to be written using Dart.
///
/// For more information on these APIs, see the Chrome.* APIs Documentation:
///   http://developer.chrome.com/extensions/api_index.html
library chrome;

import 'dart:_foreign_helper' show JS;
/* TODO(sashab): Add "show convertDartClosureToJS" once 'show' works. */
import 'dart:_js_helper';
import 'dart:html_common';
import 'dart:html';

part "$AUXILIARY_DIR/chrome/utils.dart";
part "$AUXILIARY_DIR/chrome/chrome.dart";

// Generated files below this line.
"""

# The format for adding files to TEMPLATE_CONTENT. Will be substituted with the
# filename (not including the extension) of the IDL/JSON file.
TEMPLATE_FILE_FORMAT = 'part "$AUXILIARY_DIR/chrome/%s.dart";'

# A list of schema files to generate.
# TODO(sashab): Later, use the ones from API_DIR/api.gyp and
# API_DIR/_permission_features.json (for 'platform_apps').
API_FILES = [
    "app_window.idl",
    "app_runtime.idl",
]

if __name__ == "__main__":
  # Generate each file.
  for filename in API_FILES:
    result = os.system('python "%s" -g dart -D "%s" -d "%s" -r "%s" "%s"' % (
        COMPILER, OVERRIDES_DIR, OUTPUT_DIR, API_DIR,
        os.path.join(API_DIR, filename)))
    if result != 0:
        print "Error occurred during generation of %s" % (
            os.path.join(API_DIR, filename))
        sys.exit(1)
    else:
      print "Generated %s successfully to %s.dart" % (
          os.path.join(API_DIR, filename),
          os.path.join(OUTPUT_DIR, os.path.splitext(filename)[0]))

  # Generate the template.
  files_to_add = (TEMPLATE_FILE_FORMAT % os.path.splitext(f)[0]
                  for f in API_FILES)
  with open(OUTPUT_TEMPLATE, 'w') as template_file:
    template_file.write(TEMPLATE_CONTENT)
    template_file.write('\n'.join(files_to_add))
  print "Generated template succesfully."


