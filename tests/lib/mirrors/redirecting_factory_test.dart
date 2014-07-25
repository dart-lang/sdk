// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";
import "package:expect/expect.dart";
import "stringify.dart";

class Class<T1, T2> {
  final field;
  Class(this.field);

  factory Class.factoryNoOptional(a, b) => new Class<T1, T2>(a - b);
  factory Class.redirectingFactoryNoOptional(a, b) = Class.factoryNoOptional;

  factory Class.factoryUnnamedOptional(a, [b = 42]) => new Class<T1, T2>(a - b);
  factory Class.redirectingFactoryUnnamedOptional(a, [b]) =
      Class.factoryUnnamedOptional;

  factory Class.factoryNamedOptional(a, {b: 42}) {
    return new Class<T1, T2>(a - b);
  }

  factory Class.redirectingFactoryNamedOptional(a, {b}) =
      Class.factoryNamedOptional;

  factory Class.factoryMoreNamedOptional(a, {b: 0, c: 2}) {
    return new Class<T1, T2>(a - b - c);
  }

  factory Class.redirectingFactoryMoreNamedOptional(a, {b}) =
      Class.factoryMoreNamedOptional;

  factory Class.factoryMoreUnnamedOptional(a, [b = 0, c = 2]) {
    return new Class<T1, T2>(a - b - c);
  }

  factory Class.redirectingFactoryMoreUnnamedOptional(a, [b]) =
      Class.factoryMoreUnnamedOptional;

  factory Class.redirectingFactoryStringIntTypeParameters(a, b) =
      Class<String, int>.factoryNoOptional;

  factory Class.redirectingFactoryStringTypeParameters(a, b) =
      Class
        <String>  /// 02: static type warning
      .factoryNoOptional;

  factory Class.redirectingFactoryTypeParameters(a, b) =
      Class<T1, T2>.factoryNoOptional;

  factory Class.redirectingFactoryReversedTypeParameters(a, b) =
      Class<T2, T1>.factoryNoOptional;
}

main() {
  var classMirror = reflectClass(Class);

  var instanceMirror = classMirror.newInstance(const Symbol(''), [2]);
  Expect.equals(2, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryNoOptional, [8, 6]);
  Expect.equals(2, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryUnnamedOptional, [43, 1]);
  Expect.equals(42, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryMoreUnnamedOptional, [43, 1]);
  Expect.equals(40, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryStringIntTypeParameters, [43, 1]);
  Expect.equals(42, instanceMirror.reflectee.field);
  Expect.isTrue(instanceMirror.reflectee is Class<String, int>);
  Expect.isFalse(instanceMirror.reflectee is Class<int, String>);

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryStringTypeParameters, [43, 1]);
  Expect.equals(42, instanceMirror.reflectee.field);
  Expect.isTrue(instanceMirror.reflectee is Class<String, int>);
  Expect.isTrue(instanceMirror.reflectee is Class<String, String>);
  Expect.isTrue(instanceMirror.reflectee is Class<int, String>);

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryUnnamedOptional, [43]);
  Expect.equals(1, instanceMirror.reflectee.field);

  bool isDart2js = false;
  isDart2js = true; /// 01: ok
  if (isDart2js) return;

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryNamedOptional, [43]);
  Expect.equals(1, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryNamedOptional,
      [43],
      new Map()..[#b] = 1);
  Expect.equals(42, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryMoreNamedOptional,
      [43],
      new Map()..[#b] = 1);
  Expect.equals(40, instanceMirror.reflectee.field);

  classMirror = reflect(new Class<String, int>(42)).type;
  instanceMirror = classMirror.newInstance(
      #redirectingFactoryTypeParameters, [43, 1]);
  Expect.equals(42, instanceMirror.reflectee.field);
  Expect.isTrue(instanceMirror.reflectee is Class<String, int>);
  Expect.isFalse(instanceMirror.reflectee is Class<int, String>);

  instanceMirror = classMirror.newInstance(
      #redirectingFactoryReversedTypeParameters, [43, 1]);
  Expect.equals(42, instanceMirror.reflectee.field);
  Expect.isTrue(instanceMirror.reflectee is Class<int, String>);
  Expect.isFalse(instanceMirror.reflectee is Class<String, int>);
}

