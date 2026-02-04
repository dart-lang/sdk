// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests uses of `@JSExport` and `createJSInteropWrapper`.

import 'dart:js_interop';

import 'validation_lib.dart';

void testNumberOfExports() {
  createJSInteropWrapper(ExportAll());
  createJSInteropWrapper(ExportSome());
  createJSInteropWrapper(NoAnnotations());
  // [error column 3]
  // [web] Class 'NoAnnotations' does not have a `@JSExport` on it or any of its members.
  createJSInteropWrapper(ExportNoneQualify());
  createJSInteropWrapper(ExportEmpty());
  createJSInteropWrapper(ExportWithNoExportSuperclass());
  createJSInteropWrapper(ExportWithEmptyExportSuperclass());
  createJSInteropWrapper(NoExportWithExportSuperclass());
  // [error column 3]
  // [web] Class 'NoExportWithExportSuperclass' does not have a `@JSExport` on it or any of its members.
}

void testUseDartInterface() {
  // Needs to be an interface type.
  createJSInteropWrapper<InvalidType>(() {});
  // [error column 3]
  // [web] Type argument 'void Function()' needs to be an interface type.

  // Can't use an interop class.
  createJSInteropWrapper(StaticInterop());
  // [error column 3]
  // [web] Type argument 'StaticInterop' needs to be a non-JS interop type.
}

void testCollisions() {
  createJSInteropWrapper(RenameCollision());
  createJSInteropWrapper(GetSetNoCollision());
}

void testClassExportWithValue() {
  createJSInteropWrapper(ClassWithValue());
}

void testClassWithGenerics() {
  createJSInteropWrapper(GenericAll());
  createJSInteropWrapper(GenericSome());
  createJSInteropWrapper(GenericSome<int>());
}

void main() {
  testNumberOfExports();
  testUseDartInterface();
  testCollisions();
  testClassExportWithValue();
  testClassWithGenerics();
}
