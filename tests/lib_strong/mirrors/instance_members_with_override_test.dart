// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.instance_members_with_override;

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'package:meta/meta.dart' show virtual;

class S {
  @virtual
  var field;
  @virtual
  final finalField = 0;
  method() {}
  get getter {}
  set setter(x) {}
  notOverridden() {}
}

abstract class C extends S {
  var field;
  final finalField = 0;
  method() {}
  get getter {}
  set setter(x) {}
  /* abstract */ notOverridden();
}

selectKeys(map, predicate) {
  return map.keys.where((key) => predicate(map[key]));
}

main() {
  ClassMirror sMirror = reflectClass(S);
  ClassMirror cMirror = reflectClass(C);

  Expect.setEquals([
    #field,
    const Symbol('field='),
    #finalField,
    #method,
    #getter,
    const Symbol('setter='),
    #notOverridden,
    #hashCode,
    #runtimeType,
    #==,
    #noSuchMethod,
    #toString
  ], selectKeys(sMirror.instanceMembers, (dm) => !dm.isPrivate));
  // Filter out private to avoid implementation-specific members of Object.

  Expect.equals(sMirror, sMirror.instanceMembers[#field].owner);
  Expect.equals(sMirror, sMirror.instanceMembers[const Symbol('field=')].owner);
  Expect.equals(sMirror, sMirror.instanceMembers[#finalField].owner);
  Expect.equals(sMirror, sMirror.instanceMembers[#method].owner);
  Expect.equals(sMirror, sMirror.instanceMembers[#getter].owner);
  Expect.equals(
      sMirror, sMirror.instanceMembers[const Symbol('setter=')].owner);

  Expect.setEquals([
    #field,
    const Symbol('field='),
    #finalField,
    #method,
    #getter,
    const Symbol('setter='),
    #notOverridden,
    #hashCode,
    #runtimeType,
    #==,
    #noSuchMethod,
    #toString
  ], selectKeys(cMirror.instanceMembers, (dm) => !dm.isPrivate));
  // Filter out private to avoid implementation-specific members of Object.

  Expect.equals(cMirror, cMirror.instanceMembers[#field].owner);
  Expect.equals(cMirror, cMirror.instanceMembers[const Symbol('field=')].owner);
  Expect.equals(cMirror, cMirror.instanceMembers[#finalField].owner);
  Expect.equals(cMirror, cMirror.instanceMembers[#method].owner);
  Expect.equals(cMirror, cMirror.instanceMembers[#getter].owner);
  Expect.equals(
      cMirror, cMirror.instanceMembers[const Symbol('setter=')].owner);

  Expect.equals(sMirror, sMirror.instanceMembers[#notOverridden].owner);
  Expect.equals(sMirror, cMirror.instanceMembers[#notOverridden].owner);
}
