// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests uses of `@JSExport` and `createDartExport`.

import 'dart:js_interop';

import 'package:js/js_util.dart';

import 'validation_lib.dart';

void testNumberOfExports() {
  createDartExport(ExportAll());
  createDartExport(ExportSome());
  createDartExport(NoAnnotations());
  // [error column 3]
  // [web] Class 'NoAnnotations' does not have a `@JSExport` on it or any of its members.
  createDartExport(ExportNoneQualify());
  createDartExport(ExportEmpty());
  createDartExport(ExportWithNoExportSuperclass());
  createDartExport(ExportWithEmptyExportSuperclass());
  createDartExport(NoExportWithExportSuperclass());
  // [error column 3]
  // [web] Class 'NoExportWithExportSuperclass' does not have a `@JSExport` on it or any of its members.
}

void testUseDartInterface() {
  // Needs to be an interface type.
  createDartExport<InvalidType>(() {});
  // [error column 3]
  // [web] Type argument 'void Function()' needs to be an interface type.

  // Can't use an interop class.
  createDartExport(StaticInterop());
  // [error column 3]
  // [web] Type argument 'StaticInterop' needs to be a non-JS interop type.
}

void testCollisions() {
  createDartExport(RenameCollision());
  createDartExport(GetSetNoCollision());
}

void testClassExportWithValue() {
  createDartExport(ClassWithValue());
}

void testClassWithGenerics() {
  createDartExport(GenericAll());
  createDartExport(GenericSome());
  createDartExport(GenericSome<int>());
}

void main() {
  testNumberOfExports();
  testUseDartInterface();
  testCollisions();
  testClassExportWithValue();
  testClassWithGenerics();
}
