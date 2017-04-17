// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Foo {}

main() {
  Expect.stringEquals('Foo', '${new Foo().runtimeType}');
  Expect.stringEquals('foo', MirrorSystem.getName(new Symbol('foo')));
}
