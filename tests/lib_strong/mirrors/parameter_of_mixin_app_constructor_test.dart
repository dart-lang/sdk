// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.parameter_of_mixin_app_constructor;

import 'dart:mirrors';
import 'stringify.dart';

class MapView {
  final _map;
  MapView(map) : this._map = map;
}

abstract class UnmodifiableMapMixin {
  someFunctionality() {}
}

class UnmodifiableMapView1 extends MapView with UnmodifiableMapMixin {
  UnmodifiableMapView1(map1) : super(map1);
}

class UnmodifiableMapView2 = MapView with UnmodifiableMapMixin;

class S {
  S(int p1, String p2);
}

class M1 {}

class M2 {}

class M3 {}

class MorePlumbing = S with M1, M2, M3;

soleConstructorOf(ClassMirror cm) {
  return cm.declarations.values
      .where((dm) => dm is MethodMirror && dm.isConstructor)
      .single;
}

main() {
  ClassMirror umv1 = reflectClass(UnmodifiableMapView1);
  expect(
      '[Parameter(s(map1) in s(UnmodifiableMapView1),'
      ' type = Type(s(dynamic), top-level))]',
      soleConstructorOf(umv1).parameters);
  expect(
      '[Parameter(s(map) in s(test.parameter_of_mixin_app_constructor.MapView'
      ' with test.parameter_of_mixin_app_constructor.UnmodifiableMapMixin),'
      ' final, type = Type(s(dynamic), top-level))]',
      soleConstructorOf(umv1.superclass).parameters);
  expect(
      '[Parameter(s(map) in s(MapView),'
      ' type = Type(s(dynamic), top-level))]',
      soleConstructorOf(umv1.superclass.superclass).parameters);
  expect('[]',
      soleConstructorOf(umv1.superclass.superclass.superclass).parameters);

  ClassMirror umv2 = reflectClass(UnmodifiableMapView2);
  expect(
      '[Parameter(s(map) in s(UnmodifiableMapView2),'
      ' final, type = Type(s(dynamic), top-level))]',
      soleConstructorOf(umv2).parameters);
  expect(
      '[Parameter(s(map) in s(MapView),'
      ' type = Type(s(dynamic), top-level))]',
      soleConstructorOf(umv2.superclass).parameters);
  expect('[]', soleConstructorOf(umv2.superclass.superclass).parameters);

  ClassMirror mp = reflectClass(MorePlumbing);
  expect(
      '[Parameter(s(p1) in s(MorePlumbing),'
      ' final, type = Type(s(dynamic), top-level)),'
      ' Parameter(s(p2) in s(MorePlumbing),'
      ' final, type = Type(s(dynamic), top-level))]',
      soleConstructorOf(mp).parameters);
  expect(
      '[Parameter(s(p1) in s(test.parameter_of_mixin_app_constructor.S'
      ' with test.parameter_of_mixin_app_constructor.M1,'
      ' test.parameter_of_mixin_app_constructor.M2),'
      ' final, type = Type(s(dynamic), top-level)),'
      ' Parameter(s(p2) in s(test.parameter_of_mixin_app_constructor.S'
      ' with test.parameter_of_mixin_app_constructor.M1,'
      ' test.parameter_of_mixin_app_constructor.M2),'
      ' final, type = Type(s(dynamic), top-level))]',
      soleConstructorOf(mp.superclass).parameters);
  expect(
      '[Parameter(s(p1) in s(test.parameter_of_mixin_app_constructor.S'
      ' with test.parameter_of_mixin_app_constructor.M1),'
      ' final, type = Type(s(dynamic), top-level)),'
      ' Parameter(s(p2) in s(test.parameter_of_mixin_app_constructor.S'
      ' with test.parameter_of_mixin_app_constructor.M1),'
      ' final, type = Type(s(dynamic), top-level))]',
      soleConstructorOf(mp.superclass.superclass).parameters);
  expect(
      '[Parameter(s(p1) in s(S),'
      ' type = Class(s(int) in s(dart.core), top-level)),'
      ' Parameter(s(p2) in s(S),'
      ' type = Class(s(String) in s(dart.core), top-level))]',
      soleConstructorOf(mp.superclass.superclass.superclass).parameters);
  expect(
      '[]',
      soleConstructorOf(mp.superclass.superclass.superclass.superclass)
          .parameters);
}
