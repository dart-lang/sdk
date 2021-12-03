// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/196606044.
//
// Verifies that instance.type.instanceMembers contains 'isNotEmpty'
// member for a List literal.

import 'package:expect/expect.dart';
import 'dart:mirrors';

dynamic object = <int>[1, 2, 3];
String name = 'isNotEmpty';

main() {
  var instance = reflect(object);
  var member = instance.type.instanceMembers[new Symbol(name)];
  Expect.isNotNull(member);
  var invocation = instance.getField(member!.simpleName);
  Expect.isNotNull(invocation);
  Expect.equals(true, invocation.reflectee);
}
