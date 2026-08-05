// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvocationOfExtensionWithoutCallTest);
  });
}

@reflectiveTest
class InvocationOfExtensionWithoutCallTest extends PubPackageResolutionTest {
  test_instance_differentKind() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on Object {}
f() {
  E(0)();
//^^^^
// [diag.invocationOfExtensionWithoutCall] The extension 'E' doesn't define a 'call' method so the override can't be used in an invocation.
}
''');
  }
}
