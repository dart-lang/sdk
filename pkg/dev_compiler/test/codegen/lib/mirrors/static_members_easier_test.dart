// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.static_members;

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'stringify.dart';
import 'declarations_model_easier.dart' as declarations_model;

selectKeys(map, predicate) {
  return map.keys.where((key) => predicate(map[key]));
}

main() {
  ClassMirror cm = reflectClass(declarations_model.Class);
  LibraryMirror lm = cm.owner;

  Expect.setEquals(
    [#staticVariable,
     const Symbol('staticVariable='),
     #staticGetter,
     const Symbol('staticSetter='),
     #staticMethod,
     ],
    selectKeys(cm.staticMembers, (dm) => true));

  Expect.setEquals(
    [#staticVariable,
     const Symbol('staticVariable=')],
    selectKeys(cm.staticMembers, (dm) => dm.isSynthetic));
}
