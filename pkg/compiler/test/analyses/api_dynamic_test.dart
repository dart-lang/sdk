// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import '../helpers/memory_compiler.dart';
import 'analysis_helper.dart';

// TODO(johnniwinther): Remove unneeded dynamic accesses from platform source
// code.
main(List<String> args) {
  var goldenFile = isDart2jsNnbd ? 'api_allowed_nnbd.json' : 'api_allowed.json';
  asyncTest(() async {
    await run(
        Uri.parse('memory:main.dart'), 'pkg/compiler/test/analyses/$goldenFile',
        analyzedUrisFilter: (Uri uri) => uri.scheme == 'dart',
        memorySourceFiles: {'main.dart': 'main() {}'},
        verbose: args.contains('-v'),
        generate: args.contains('-g'));
  });
}
