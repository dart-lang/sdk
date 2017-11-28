// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'lib/sources.dart';

class C {
  static A1 _privateField;
  static A2 publicField;

  static A3 _privateMethod() => null;
  static A4 publicMethod() => null;

  static A5 get _privateGetter => null;
  static A6 get publicGetter => null;

  static void set _privateSetter(A7 _) {}
  static void set publicSetter(A8 _) {}
}
