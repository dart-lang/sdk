// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

class Class<T1, T2> {
  final field;
  Class(this.field);

  factory Class.factoryNoOptional(a, b) => Class<T1, T2>(a - b);
  factory Class.redirectingFactoryNoOptional(a, b) = Class.factoryNoOptional;

  factory Class.factoryUnnamedOptional(a, [b = 42]) => Class<T1, T2>(a - b);
  factory Class.redirectingFactoryUnnamedOptional(a, [b]) =
      Class.factoryUnnamedOptional;

  factory Class.factoryNamedOptional(a, {b = 42}) {
    return Class<T1, T2>(a - b);
  }

  factory Class.redirectingFactoryNamedOptional(a, {b}) =
      Class.factoryNamedOptional;

  factory Class.factoryMoreNamedOptional(a, {b = 0, c = 2}) {
    return Class<T1, T2>(a - b - c);
  }

  factory Class.redirectingFactoryMoreNamedOptional(a, {b}) =
      Class<T1, T2>.factoryMoreNamedOptional;

  factory Class.factoryMoreUnnamedOptional(a, [b = 0, c = 2]) {
    return Class<T1, T2>(a - b - c);
  }

  factory Class.redirectingFactoryMoreUnnamedOptional(a, [b]) =
      Class<T1, T2>.factoryMoreUnnamedOptional;

  factory Class.redirectingFactoryTypeParameters(a, b) =
      Class<T1, T2>.factoryNoOptional;
}

void main() {
  var classMirror = reflectClass(Class) as ClassMirror;

  var instanceMirror = classMirror.newInstance(Symbol.empty, [2]);
  Expect.equals(2, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(#redirectingFactoryNoOptional, [
    8,
    6,
  ]);
  Expect.equals(2, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(#redirectingFactoryUnnamedOptional, [
    43,
    1,
  ]);
  Expect.equals(42, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(
    #redirectingFactoryMoreUnnamedOptional,
    [43, 1],
  );
  Expect.equals(40, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(#redirectingFactoryUnnamedOptional, [
    43,
  ]);
  Expect.equals(1, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(#redirectingFactoryNamedOptional, [
    43,
  ]);
  Expect.equals(1, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(
    #redirectingFactoryNamedOptional,
    [43],
    {#b: 1},
  );
  Expect.equals(42, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(
    #redirectingFactoryMoreNamedOptional,
    [43],
    {#b: 1},
  );
  Expect.equals(40, instanceMirror.reflectee.field);

  classMirror = reflect(Class<String, int>(42)).type;
  instanceMirror = classMirror.newInstance(#redirectingFactoryTypeParameters, [
    43,
    1,
  ]);
  Expect.equals(42, instanceMirror.reflectee.field);
  Expect.isTrue(instanceMirror.reflectee is Class<String, int>);
  Expect.isFalse(instanceMirror.reflectee is Class<int, String>);
}
