// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test various uses of exports that are returned from `createDartExport`.

import 'dart:js_interop';

import 'package:js/js_util.dart';

import 'functional_test_lib.dart';

class UseCreateDartExport implements WrapperCreator {
  JSObject createExportAll(ExportAll instance) =>
      createDartExport(instance) as JSObject;
  JSObject createExportSome(ExportSome instance) =>
      createDartExport(instance) as JSObject;
  JSObject createInheritance(Inheritance instance) =>
      createDartExport(instance) as JSObject;
  JSObject createInheritanceShadowed(InheritanceShadowed instance) =>
      createDartExport(instance) as JSObject;
  JSObject createOverrides(Overrides instance) =>
      createDartExport(instance) as JSObject;
  JSObject createArity(Arity instance) =>
      createDartExport(instance) as JSObject;
}

void main() {
  test(UseCreateDartExport());
}
