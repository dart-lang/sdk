// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'mixed_mixin.dart';

class B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

class DiBq1 extends C1 implements Bq {}
