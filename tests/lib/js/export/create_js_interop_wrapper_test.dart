// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test various uses of exports that are returned from `createJSInteropWrapper`.

import 'dart:js_interop';

import 'functional_test_lib.dart';

class UseCreateJSInteropWrapper implements WrapperCreator {
  JSObject createExportAll(ExportAll instance) =>
      createJSInteropWrapper(instance);
  JSObject createExportSome(ExportSome instance) =>
      createJSInteropWrapper(instance);
  JSObject createInheritance(Inheritance instance) =>
      createJSInteropWrapper(instance);
  JSObject createInheritanceShadowed(InheritanceShadowed instance) =>
      createJSInteropWrapper(instance);
  JSObject createOverrides(Overrides instance) =>
      createJSInteropWrapper(instance);
  JSObject createArity(Arity instance) => createJSInteropWrapper(instance);
}

void main() {
  test(UseCreateJSInteropWrapper());
}
