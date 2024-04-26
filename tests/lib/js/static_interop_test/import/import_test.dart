// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:async_helper/async_helper.dart';
import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

extension type Module(JSObject o) implements JSObject {
  external String testModuleFunction();
}

void main() {
  asyncTest(() async {
    final module = Module(await importModule(
            '/root_dart/tests/lib/js/static_interop_test/import/module.mjs')
        .toDart);
    expect(module.testModuleFunction(), 'success');
  });
}
