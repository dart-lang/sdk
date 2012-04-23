// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** General options used by the compiler. */
CSSOptions options;

/** Extracts options from command-line arguments. */
void parseOptions(List<String> args, var files) {
  assert(options == null);
  options = new CSSOptions(args, files);
}

class CSSOptions {
  /** Location of corelib and other special dart libraries. */
  String libDir;

  /* The top-level dart script to compile. */
  String dartScript;

  /** Where to place the generated code. */
  String outfile;

  // Options that modify behavior significantly

  bool warningsAsErrors = false;
  bool checkOnly = false;

  // Message support
  bool throwOnErrors = false;
  bool throwOnWarnings = false;
  bool throwOnFatal = false;
  bool showInfo = false;
  bool showWarnings = true;
  bool useColors = true;

  /**
   * Options to be used later for passing to the generated code. These are all
   * the arguments after the first dart script, if any.
   */
  List<String> childArgs;

  CSSOptions(List<String> args, var files) {
    bool ignoreUnrecognizedFlags = false;
    bool passedLibDir = false;
    childArgs = [];

    // Start from 2 to skip arguments representing the compiler command
    // (python followed by frog.py).
    for (int i = 2; i < args.length; i++) {
      var arg = args[i];

      switch (arg) {
        case '--check-only':
          checkOnly = true;
          break;

        case '--verbose':
          showInfo = true;
          break;

        case '--suppress_warnings':
          showWarnings = false;
          break;

        case '--warnings_as_errors':
          warningsAsErrors = true;
          break;

        case '--throw_on_errors':
          throwOnErrors = true;
          break;

        case '--throw_on_warnings':
          throwOnWarnings = true;
          break;

        case '--no_colors':
          useColors = false;
          break;

        case '--checked':
          checkOnly = true;
          break;

        default:
          if (!ignoreUnrecognizedFlags) {
            print('unrecognized flag: "$arg"');
          }
      }
    }
  }
}
