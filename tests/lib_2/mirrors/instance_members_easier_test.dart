// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.instance_members;

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'declarations_model_easier.dart' as declarations_model;

selectKeys(map, predicate) {
  return map.keys.where((key) => predicate(map[key]));
}

class EasierSuperclass {
  shuper() {}
  static staticShuper() {}
}

class EasierMixin {
  mixin() {}
  static staticMixin() {}
}

class EasierMixinApplication extends EasierSuperclass with EasierMixin {
  application() {}
  static staticApplication() {}
}

class Derived extends EasierMixinApplication {
  derived() {}
  static staticDerived() {}
}

main() {
  ClassMirror cm = reflectClass(declarations_model.Class);

  Expect.setEquals([
    #+,
    #instanceVariable,
    const Symbol('instanceVariable='),
    #instanceGetter,
    const Symbol('instanceSetter='),
    #instanceMethod,
    #-,
    #inheritedInstanceVariable,
    const Symbol('inheritedInstanceVariable='),
    #inheritedInstanceGetter,
    const Symbol('inheritedInstanceSetter='),
    #inheritedInstanceMethod,
    #hashCode,
    #runtimeType,
    #==,
    #noSuchMethod,
    #toString
  ], selectKeys(cm.instanceMembers, (dm) => !dm.isPrivate));
  // Filter out private to avoid implementation-specific members of Object.

  Expect.setEquals([
    #instanceVariable,
    const Symbol('instanceVariable='),
    #inheritedInstanceVariable,
    const Symbol('inheritedInstanceVariable=')
  ], selectKeys(cm.instanceMembers, (dm) => !dm.isPrivate && dm.isSynthetic));

  cm = reflectClass(Derived);
  Expect.setEquals([
    #derived,
    #shuper,
    #mixin,
    #application,
    #hashCode,
    #runtimeType,
    #==,
    #noSuchMethod,
    #toString
  ], selectKeys(cm.instanceMembers, (dm) => !dm.isPrivate));

  cm = reflectClass(EasierMixinApplication);
  Expect.setEquals([
    #shuper,
    #mixin,
    #application,
    #hashCode,
    #runtimeType,
    #==,
    #noSuchMethod,
    #toString
  ], selectKeys(cm.instanceMembers, (dm) => !dm.isPrivate));
}
