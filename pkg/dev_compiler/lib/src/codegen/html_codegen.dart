// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:logging/logging.dart' show Logger;

// TODO(jmesserly): the string interpolation in these could lead to injection
// bugs. Not really a security issue since input is trusted, but the resulting
// parse tree may not match expectations if interpolated strings contain quotes.

/// A script tag that loads the .js code for a compiled library.
Node libraryInclude(String jsUrl) =>
    parseFragment('<script src="$jsUrl"></script>\n');

/// A script tag that invokes the main function on the entry point library.
Node invokeMain(String mainLibraryName) {
  var code = mainLibraryName == null
      ? 'console.error("dev_compiler error: main was not generated");'
      // TODO(vsm): Can we simplify this?
      // See: https://github.com/dart-lang/dev_compiler/issues/164
      : "dart_library.start('$mainLibraryName');";
  return parseFragment('<script>$code</script>\n');
}

final _log = new Logger('dev_compiler.src.codegen.html_codegen');
