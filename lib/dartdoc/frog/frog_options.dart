// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** General options used by the compiler. */
FrogOptions options;

/** Extracts options from command-line arguments. */
void parseOptions(String homedir, List<String> args, FileSystem files) {
  assert(options == null);
  options = new FrogOptions(homedir, args, files);
}

// TODO(sigmund): make into a generic option parser...
class FrogOptions {
  /** Location of corelib and other special dart libraries. */
  String libDir;

  /* The top-level dart script to compile. */
  String dartScript;

  /* The directory to look in for "package:" scheme URIs. */
  String packageRoot;

  /** Where to place the generated code. */
  String outfile;

  // TODO(dgrove): fix this. For now, either 'sdk' or 'dev'.
  final config = 'dev';

  // Options that modify behavior significantly
  bool legOnly = false;
  bool allowMockCompilation = false;
  bool enableAsserts = false;
  bool enableTypeChecks = false;
  bool warningsAsErrors = false;
  bool verifyImplements = false; // TODO(jimhug): Implement
  bool compileAll = false;
  bool forceDynamic = false;
  bool dietParse = false;
  bool compileOnly = false;
  bool inferTypes = false;
  bool checkOnly = false;
  bool ignoreUnrecognizedFlags = false;
  bool emitCodeComments = false;

  // Specifies non-compliant behavior where array bounds checks are
  // not implemented in generated code.
  bool disableBoundsChecks = false;

  // Message support
  bool throwOnErrors = false;
  bool throwOnWarnings = false;
  bool throwOnFatal = false;
  bool showInfo = false;
  bool showWarnings = true;
  bool useColors = true;

  // Not currently settable via command line.
  // Intended for use by compiler implementer during debugging.
  // TODO(jmesserly): what are the right values for these?
  int maxInferenceIterations = 4;

  /**
   * Options to be used later for passing to the generated code. These are all
   * the arguments after the first dart script, if any.
   */
  List<String> childArgs;

  FrogOptions(String homedir, List<String> args, FileSystem files) {
    if (config == 'dev') {
      libDir = joinPaths(homedir, '/../..'); // Default value for --libdir.
    } else if (config == 'sdk') {
      libDir = joinPaths(homedir, '/../..');
    } else {
      world.error('Invalid configuration $config', null);
      throw('Invalid configuration');
    }

    bool passedLibDir = false;
    childArgs = [];

    // Start from 2 to skip arguments representing the compiler command
    // (python followed by frog.py).
    loop: for (int i = 2; i < args.length; i++) {
      var arg = args[i];
      if (tryParseSimpleOption(arg)) continue;
      if (arg.endsWith('.dart')) {
        dartScript = arg;
        childArgs = args.getRange(i + 1, args.length - i - 1);
        break loop;
      } else if (arg.startsWith('--out=')) {
        outfile = arg.substring('--out='.length);
      } else if (arg.startsWith('--libdir=')) {
        libDir = arg.substring('--libdir='.length);
        passedLibDir = true;
      } else if (arg.startsWith('--package-root')) {
        packageRoot = arg.substring('--package-root='.length);
      } else if (!ignoreUnrecognizedFlags) {
        print('unrecognized flag: "$arg"');
      }
    }

    // TODO(jimhug): Remove this hack.
    if (!passedLibDir && config == 'dev' && !files.fileExists(libDir)) {
      // Try locally
      var temp = 'frog/lib';
      if (files.fileExists(temp)) {
        libDir = temp;
      } else {
        libDir = 'lib';
      }
    }
  }

  bool tryParseSimpleOption(String option) {
    if (!option.startsWith('--')) return false;
    switch (option.replaceAll('_', '-')) {
      case '--leg':
      case '--enable-leg':
      case '--leg-only':
        legOnly = true;
        return true;

      case '--allow-mock-compilation':
        allowMockCompilation = true;
        return true;

      case '--enable-asserts':
        enableAsserts = true;
        return true;

      case '--enable-type-checks':
        enableTypeChecks = true;
        enableAsserts = true;  // TODO(kasperl): Remove once VM stops.
        return true;

      case '--verify-implements':
        verifyImplements = true;
        return true;

      case '--compile-all':
        compileAll = true;
        return true;

      case '--check-only':
        checkOnly = true;
        return true;

      case '--diet-parse':
        dietParse = true;
        return true;

      case '--ignore-unrecognized-flags':
        ignoreUnrecognizedFlags = true;
        return true;

      case '--verbose':
        showInfo = true;
        return true;

      case '--suppress-warnings':
        showWarnings = false;
        return true;

      case '--warnings-as-errors':
        warningsAsErrors = true;
        return true;

      case '--throw-on-errors':
        throwOnErrors = true;
        return true;

      case '--throw-on-warnings':
        throwOnWarnings = true;
        return true;

      case '--compile-only':
        // As opposed to compiling and running, the default behavior.
        compileOnly = true;
        return true;

      case '--Xforce-dynamic':
        forceDynamic = true;
        return true;

      case '--no-colors':
        useColors = false;
        return true;

      case '--Xinfer-types':
        inferTypes = true;
        return true;

      case '--enable-checked-mode':
      case '--checked':
        enableTypeChecks = true;
        enableAsserts = true;
        return true;

      case '--unchecked':
        disableBoundsChecks = true;
        return true;

      case '--emit-code-comments':
        emitCodeComments = true;
        return true;
    }
    return false;
  }
}
