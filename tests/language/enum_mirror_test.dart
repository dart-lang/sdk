// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-enum

import 'dart:mirrors';

import 'package:expect/expect.dart';

enum Foo { BAR, BAZ }

main() {
  Expect.equals('Foo.BAR', Foo.BAR.toString());
  var name = reflect(Foo.BAR).invoke(#toString, []).reflectee;
  Expect.equals('Foo.BAR', name);
}
