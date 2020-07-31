// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "dart:async";
import "dart:io";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

import 'package:compiler/compiler.dart' as compiler;

import '../helpers/memory_compiler.dart';

const Map<String, String> SOURCES = const {
  "/main.dart": """
    import "foo.dart";
    main() => foo();
    """,
  "/foo.dart": """
    library foo;
    import "bar.dart";
    foo() => bar();
    """,
  "/bar.dart": """
    library bar;
    bar() => print("bar");
    """
};

Future provideInput(Uri uri) {
  dynamic source = SOURCES[uri.path];
  if (source == null) {
    // Not one of our source files, so assume it's a built-in.
    if (uri.path.endsWith('.dill')) {
      source = new File(uri.toFilePath()).readAsBytesSync();
    } else {
      source = new File(uri.toFilePath()).readAsStringSync();
    }
  }

  // Deliver the input asynchronously.
  return new Future(() => source);
}

main() {
  var entrypoint = Uri.parse("file:///main.dart");

  // Find the path to sdk/ in the repo relative to this script.
  Uri librariesSpec = sdkLibrariesSpecificationUri;
  var platformDir = sdkPlatformBinariesPath;
  asyncTest(() => compiler.compile(
          entrypoint,
          librariesSpec,
          provideInput,
          handleDiagnostic,
          ['--platform-binaries=${platformDir}']).then((code) {
        Expect.isNotNull(code);
      }));
}

void handleDiagnostic(
    Uri uri, int begin, int end, String message, compiler.Diagnostic kind) {
  print(message);
  if (kind != compiler.Diagnostic.VERBOSE_INFO) {
    throw 'Unexpected diagnostic kind $kind';
  }
}
