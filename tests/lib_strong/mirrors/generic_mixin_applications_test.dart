// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_mixin_applications;

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

  // Declarations.
  typeParameters(reflectClass(NonGenericMixinApplication1), []);
  typeParameters(reflectClass(NonGenericMixinApplication2), []);
  typeParameters(reflectClass(GenericMixinApplication1), [#MA]);
  typeParameters(reflectClass(GenericMixinApplication2), [#MA]);
  typeParameters(reflectClass(NonGenericClass1), []);
  typeParameters(reflectClass(NonGenericClass2), []);
  typeParameters(reflectClass(GenericClass1), [#C]);
  typeParameters(reflectClass(GenericClass2), [#C]);
  typeParameters(reflectClass(GenericMultipleMixins), [#A, #B, #C]);
  // Anonymous mixin applications have no type parameters or type arguments.
  typeParameters(reflectClass(NonGenericClass1).superclass, []);
  typeParameters(reflectClass(NonGenericClass2).superclass, []);
  typeParameters(reflectClass(GenericClass1).superclass, []);
  typeParameters(reflectClass(GenericClass2).superclass, []);

  typeArguments(reflectClass(NonGenericMixinApplication1), []);
  typeArguments(reflectClass(NonGenericMixinApplication2), []);
  typeArguments(reflectClass(GenericMixinApplication1), []);
  typeArguments(reflectClass(GenericMixinApplication2), []);
  typeArguments(reflectClass(NonGenericClass1), []);
  typeArguments(reflectClass(NonGenericClass2), []);
  typeArguments(reflectClass(GenericClass1), []);
  typeArguments(reflectClass(GenericClass2), []);
  typeArguments(reflectClass(GenericMultipleMixins), []);
  // Anonymous mixin applications have no type parameters or type arguments.
  typeArguments(
      reflectClass(NonGenericClass1).superclass.originalDeclaration, []);
  typeArguments(
      reflectClass(NonGenericClass2).superclass.originalDeclaration, []);
  typeArguments(reflectClass(GenericClass1).superclass.originalDeclaration, []);
  typeArguments(reflectClass(GenericClass2).superclass.originalDeclaration, []);

  // Instantiations.
  typeParameters(reflect(new NonGenericMixinApplication1()).type, []);
  typeParameters(reflect(new NonGenericMixinApplication2()).type, []);
  typeParameters(reflect(new GenericMixinApplication1<bool>()).type, [#MA]);
  typeParameters(reflect(new GenericMixinApplication2<bool>()).type, [#MA]);
  typeParameters(reflect(new NonGenericClass1()).type, []);
  typeParameters(reflect(new NonGenericClass2()).type, []);
  typeParameters(reflect(new GenericClass1<bool>()).type, [#C]);
  typeParameters(reflect(new GenericClass2<bool>()).type, [#C]);
  typeParameters(reflect(new GenericMultipleMixins<bool, String, int>()).type,
      [#A, #B, #C]);
  // Anonymous mixin applications have no type parameters or type arguments.
  typeParameters(reflect(new NonGenericClass1()).type.superclass, []);
  typeParameters(reflect(new NonGenericClass2()).type.superclass, []);
  typeParameters(reflect(new GenericClass1<bool>()).type.superclass, []);
  typeParameters(reflect(new GenericClass2<bool>()).type.superclass, []);

  typeArguments(reflect(new NonGenericMixinApplication1()).type, []);
  typeArguments(reflect(new NonGenericMixinApplication2()).type, []);
  typeArguments(
      reflect(new GenericMixinApplication1<bool>()).type, [reflectClass(bool)]);
  typeArguments(
      reflect(new GenericMixinApplication2<bool>()).type, [reflectClass(bool)]);
  typeArguments(reflect(new NonGenericClass1()).type, []);
  typeArguments(reflect(new NonGenericClass2()).type, []);
  typeArguments(reflect(new GenericClass1<bool>()).type, [reflectClass(bool)]);
  typeArguments(reflect(new GenericClass2<bool>()).type, [reflectClass(bool)]);
  typeArguments(reflect(new GenericMultipleMixins<bool, String, int>()).type,
      [reflectClass(bool), reflectClass(String), reflectClass(int)]);
  // Anonymous mixin applications have no type parameters or type arguments.
  typeArguments(reflect(new NonGenericClass1()).type.superclass, []);
  typeArguments(reflect(new NonGenericClass2()).type.superclass, []);
  typeArguments(reflect(new GenericClass1<bool>()).type.superclass, []);
  typeArguments(reflect(new GenericClass2<bool>()).type.superclass, []);
}
