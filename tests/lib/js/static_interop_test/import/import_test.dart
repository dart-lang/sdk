// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

extension type Module(JSObject _) implements JSObject {
  external String testModuleFunction();
}

void main() {
  asyncTest(() async {
    final module = Module(await importModule(
            '/root_dart/tests/lib/js/static_interop_test/import/module.mjs'
                .toJS)
        .toDart);
    Expect.equals(module.testModuleFunction(), 'success');
  });
}
