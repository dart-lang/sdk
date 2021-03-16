// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong --no-minify

import 'package:expect/expect.dart';

class Class1 {}

class Class2<X> {}

void main() {
  String name1 = '${Class1}';
  String name2 = '${Class2}';
  Expect.equals('Class1', name1);
  Expect.equals('Class2<dynamic>', name2);
}
