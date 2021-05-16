// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

library test.generic_mixin;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class Super<S> {}

class Mixin<M> {}

class Nixim<N> {}

class NonGenericMixinApplication1 = Super with Mixin;
class NonGenericMixinApplication2 = Super<num> with Mixin<String>;

class GenericMixinApplication1<MA> = Super<MA> with Mixin<MA>;
class GenericMixinApplication2<MA> = Super<num> with Mixin<String>;

class NonGenericClass1 extends Super with Mixin {}

class NonGenericClass2 extends Super<num> with Mixin<String> {}

class GenericClass1<C> extends Super<C> with Mixin<C> {}

class GenericClass2<C> extends Super<num> with Mixin<String> {}

class GenericMultipleMixins<A, B, C> extends Super<A> with Mixin<B>, Nixim<C> {}

main() {
  TypeMirror dynamicMirror = currentMirrorSystem().dynamicType;

  // Names of type variables are not preserved after type canonicalization
  // and are therefore not compared to expected names.

  typeArguments(
      reflectClass(NonGenericMixinApplication1).mixin, [dynamicMirror]);
  typeArguments(
      reflectClass(NonGenericMixinApplication2).mixin, [reflectClass(String)]);
  typeArguments(reflectClass(GenericMixinApplication1).mixin,
      [reflectClass(GenericMixinApplication1).typeVariables.single]);
  typeArguments(
      reflectClass(GenericMixinApplication2).mixin, [reflectClass(String)]);
  typeArguments(reflectClass(NonGenericClass1).mixin, []);
  typeArguments(reflectClass(NonGenericClass2).mixin, []);
  typeArguments(reflectClass(GenericClass1).mixin, []);
  typeArguments(reflectClass(GenericClass2).mixin, []);
  typeArguments(
      reflectClass(NonGenericClass1).superclass.mixin, [dynamicMirror]);
  typeArguments(
      reflectClass(NonGenericClass2).superclass.mixin, [reflectClass(String)]);
  typeArguments(reflectClass(GenericClass1).superclass.mixin,
      [reflectClass(GenericClass1).typeVariables.single]);
  typeArguments(
      reflectClass(GenericClass2).superclass.mixin, [reflectClass(String)]);
  typeArguments(reflectClass(GenericMultipleMixins).mixin, []);
  typeArguments(reflectClass(GenericMultipleMixins).superclass.mixin,
      [reflectClass(GenericMultipleMixins).typeVariables[2]]);
  typeArguments(reflectClass(GenericMultipleMixins).superclass.superclass.mixin,
      [reflectClass(GenericMultipleMixins).typeVariables[1]]);
  typeArguments(
      reflectClass(GenericMultipleMixins)
          .superclass
          .superclass
          .superclass
          .mixin,
      [reflectClass(GenericMultipleMixins).typeVariables[0]]);

  typeParameters(reflect(new NonGenericClass1()).type.mixin, []);
  typeParameters(reflect(new NonGenericClass2()).type.mixin, []);

  typeArguments(
      reflect(new NonGenericMixinApplication1()).type.mixin, [dynamicMirror]);
  typeArguments(reflect(new NonGenericMixinApplication2()).type.mixin,
      [reflectClass(String)]);
  typeArguments(reflect(new GenericMixinApplication1<bool>()).type.mixin,
      [reflectClass(bool)]);
  typeArguments(reflect(new GenericMixinApplication2<bool>()).type.mixin,
      [reflectClass(String)]);
  typeArguments(reflect(new NonGenericClass1()).type.mixin, []);
  typeArguments(reflect(new NonGenericClass2()).type.mixin, []);
  typeArguments(
      reflect(new GenericClass1<bool>()).type.mixin, [reflectClass(bool)]);
  typeArguments(
      reflect(new GenericClass2<bool>()).type.mixin, [reflectClass(bool)]);
  typeArguments(
      reflect(new NonGenericClass1()).type.superclass.mixin, [dynamicMirror]);
  typeArguments(reflect(new NonGenericClass2()).type.superclass.mixin,
      [reflectClass(String)]);
  typeArguments(reflect(new GenericClass1<bool>()).type.superclass.mixin,
      [reflectClass(bool)]);
  typeArguments(reflect(new GenericClass2<bool>()).type.superclass.mixin,
      [reflectClass(String)]);
  typeArguments(
      reflect(new GenericMultipleMixins<bool, String, int>()).type.mixin,
      [reflectClass(bool), reflectClass(String), reflectClass(int)]);
  typeArguments(
      reflect(new GenericMultipleMixins<bool, String, int>())
          .type
          .superclass
          .mixin,
      [reflectClass(int)]);
  typeArguments(
      reflect(new GenericMultipleMixins<bool, String, int>())
          .type
          .superclass
          .superclass
          .mixin,
      [reflectClass(String)]);
  typeArguments(
      reflect(new GenericMultipleMixins<bool, String, int>())
          .type
          .superclass
          .superclass
          .superclass
          .mixin,
      [reflectClass(bool)]);
}
