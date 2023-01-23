// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util';

import 'export.dart';
import 'mock.dart';

void main() {
  createDartExport<DartClass>(DartClass());
  createStaticInteropMock<StaticInterop, DartClass>(DartClass());
}
