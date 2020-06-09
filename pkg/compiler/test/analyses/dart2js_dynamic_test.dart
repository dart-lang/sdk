// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'analysis_helper.dart';

/// Filter function used to only analysis dart2js source code.
bool dart2jsOnly(Uri uri) {
  String text = '$uri';
  for (String path in [
    'package:compiler/',
    'package:js_ast/',
    'package:dart2js_info/',
    'package:js_runtime/'
  ]) {
    if (text.startsWith(path)) {
      return true;
    }
  }
  return false;
}

// TODO(johnniwinther): Remove unneeded dynamic accesses from dart2js source
// code.
main(List<String> args) {
  asyncTest(() async {
    await run(Uri.parse('package:compiler/src/dart2js.dart'),
        'pkg/compiler/test/analyses/dart2js_allowed.json',
        analyzedUrisFilter: dart2jsOnly,
        verbose: args.contains('-v'),
        generate: args.contains('-g'));
  });
}
