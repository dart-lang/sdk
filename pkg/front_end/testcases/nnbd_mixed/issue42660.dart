// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8
import 'issue42660_lib.dart';

void main() {
  f().m();
  (f)().m();
  p.m();
  var c = new Class();
  c.f().m();
  (c.f)().m();
  c.p.m();
  c[0].m();
  (-c).m();
  (c + 4).m();
  c..p.m()..f().m()..[0].m();
  new Class()..p.m()..f().m()..[0].m();
}
