// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib1.dart' as exported;
import 'dart:core' as imported;
import 'main_lib2.dart' as imported;
import 'main_lib3.dart' as imported;

testImported() {
  void f(imported.dynamic d) {}
  imported.Never n;
  <imported.Never>[];
  imported.Duplicate d;
  new imported.Duplicate();
  <imported.Duplicate>[];
  imported.NonExisting e;
  new imported.NonExisting();
  <imported.NonExisting>[];
}

testExported() {
  void f(exported.dynamic d) {}
  exported.Never n;
  <exported.Never>[];
  exported.Duplicate d;
  new exported.Duplicate();
  <exported.Duplicate>[];
  exported.NonExisting e;
  new exported.NonExisting();
  <exported.NonExisting>[];
}
