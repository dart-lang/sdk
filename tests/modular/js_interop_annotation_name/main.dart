// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that constant `@JS` and `@JSExport` values can be fetched modularly.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/expect.dart';

import 'mid.dart';

void main() {
  addTopLevel();
  // Interpolating `topLevelConstantName` here is intentional. See `mid.dart`.
  eval("globalThis.$topLevelConstantName = 'topLevelConstant';");
  eval('''
    globalThis.JSClass = function() {};
    globalThis.JSClass.prototype.baseMember = function() {
      return 'baseMember';
    };
  ''');

  Expect.equals('topLevel', topLevel);
  Expect.equals('topLevelConstant', topLevelConstant);
  Expect.equals('baseMember', JSClass().member());

  final wrapper = createJSInteropWrapper(Export());
  Expect.isTrue(wrapper.has(Mid.exportName));
  Expect.equals(
    'baseExport',
    wrapper.callMethod<JSString>(Mid.exportName.toJS).toDart,
  );
}
