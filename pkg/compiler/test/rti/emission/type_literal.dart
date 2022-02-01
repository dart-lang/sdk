// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

/*class: Class1:typeLiteral*/
class Class1 {}

/*class: Class2:typeLiteral*/
class Class2<X> {}

void main() {
  String name1 = '${Class1}';
  String name2 = '${Class2}';
  makeLive('Class1' == name1);
  makeLive('Class2<dynamic>' == name2);
}
