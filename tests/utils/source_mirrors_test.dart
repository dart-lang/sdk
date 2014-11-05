// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=
// VMOptions=--print-object-histogram

// Smoke test of the dart2js compiler API.
library source_mirrors_test;

import 'dart:async';
import "package:async_helper/async_helper.dart";

import 'package:compiler/implementation/mirrors/analyze.dart';
import 'dummy_compiler_test.dart';

main() {
  asyncStart();
  Future result =
      analyze([new Uri(scheme: 'main')],
              new Uri(scheme: 'lib', path: '/'),
              new Uri(scheme: 'package', path: '/'),
              provider, handler);
  result.then((mirrorSystem) {
    if (mirrorSystem == null) {
      throw 'Analysis failed';
    }
    mirrorSystem.libraries.forEach((uri, library) {
      print(library);
      library.declarations.forEach((name, declaration) {
        print(' $name:$declaration');
      });
    });
  }, onError: (e, s) {
      throw 'Analysis failed: $e\n$s';
  }).then(asyncSuccess);
}
