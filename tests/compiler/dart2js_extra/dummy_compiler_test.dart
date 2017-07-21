// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Smoke test of the dart2js compiler API.
library dummy_compiler;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler.dart';

import '../dart2js/mock_libraries.dart';

String libProvider(Uri uri) {
  if (uri.path.endsWith(".platform")) {
    return DEFAULT_PLATFORM_CONFIG;
  }
  if (uri.path.endsWith("/core.dart")) {
    return buildLibrarySource(DEFAULT_CORE_LIBRARY);
  } else if (uri.path.endsWith('core_patch.dart')) {
    return DEFAULT_PATCH_CORE_SOURCE;
  } else if (uri.path.endsWith('internal.dart')) {
    return buildLibrarySource(DEFAULT_INTERNAL_LIBRARY);
  } else if (uri.path.endsWith('interceptors.dart')) {
    return buildLibrarySource(DEFAULT_INTERCEPTORS_LIBRARY);
  } else if (uri.path.endsWith('js_helper.dart')) {
    return buildLibrarySource(DEFAULT_JS_HELPER_LIBRARY);
  } else if (uri.path.endsWith('isolate_helper.dart')) {
    return buildLibrarySource(DEFAULT_ISOLATE_HELPER_LIBRARY);
  } else if (uri.path.endsWith('/async.dart')) {
    return buildLibrarySource(DEFAULT_ASYNC_LIBRARY);
  } else {
    return "library lib${uri.path.replaceAll('/', '.')};";
  }
}

Future<String> provider(Uri uri) {
  String source;
  if (uri.scheme == "main") {
    source = "main() {}";
  } else if (uri.scheme == "lib") {
    source = libProvider(uri);
  } else {
    throw "unexpected URI $uri";
  }
  return new Future.value(source);
}

void handler(Uri uri, int begin, int end, String message, Diagnostic kind) {
  if (uri == null) {
    print('$kind: $message');
  } else {
    print('$uri:$begin:$end: $kind: $message');
  }
}

main() {
  asyncStart();
  Future<CompilationResult> result = compile(
      new Uri(scheme: 'main'),
      new Uri(scheme: 'lib', path: '/'),
      new Uri(scheme: 'package', path: '/'),
      provider,
      handler);
  result.then((CompilationResult result) {
    if (!result.isSuccess) {
      throw 'Compilation failed';
    }
  }, onError: (e, s) {
    throw 'Compilation failed: $e\n$s';
  }).then(asyncSuccess);
}
