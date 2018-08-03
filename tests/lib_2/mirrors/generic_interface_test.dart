// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_bounded;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class Interface<T> {}

class Bounded<S extends num> {}

class Fixed implements Interface<int> {}

class Generic<R> implements Interface<R> {}

class Bienbounded implements Bounded<int> {}

class Malbounded implements Bounded<String> {} // //# 01: compile-time error
class FBounded implements Interface<FBounded> {}

class Mixin {}

class FixedMixinApplication = Object with Mixin implements Interface<int>;
class GenericMixinApplication<X> = Object with Mixin implements Interface<X>;

class FixedClass extends Object with Mixin implements Interface<int> {}

class GenericClass<Y> extends Object with Mixin implements Interface<Y> {}

main() {
  TypeMirror dynamicMirror = currentMirrorSystem().dynamicType;

  ClassMirror interfaceDecl = reflectClass(Interface);
  ClassMirror boundedDecl = reflectClass(Bounded);

  ClassMirror interfaceOfInt = reflectClass(Fixed).superinterfaces.single;
  ClassMirror interfaceOfR = reflectClass(Generic).superinterfaces.single;
  ClassMirror interfaceOfBool =
      reflect(new Generic<bool>()).type.superinterfaces.single;

  ClassMirror boundedOfInt = reflectClass(Bienbounded).superinterfaces.single;
  ClassMirror boundedOfString = reflectClass(Malbounded).superinterfaces.single; // //# 01: continued
  ClassMirror interfaceOfFBounded =
      reflectClass(FBounded).superinterfaces.single;

  ClassMirror interfaceOfInt2 =
      reflectClass(FixedMixinApplication).superinterfaces.single;
  ClassMirror interfaceOfX =
      reflectClass(GenericMixinApplication).superinterfaces.single;
  ClassMirror interfaceOfDouble = reflect(new GenericMixinApplication<double>())
      .type
      .superinterfaces
      .single;
  ClassMirror interfaceOfInt3 = reflectClass(FixedClass).superinterfaces.single;
  ClassMirror interfaceOfY = reflectClass(GenericClass).superinterfaces.single;
  ClassMirror interfaceOfDouble2 =
      reflect(new GenericClass<double>()).type.superinterfaces.single;

  Expect.isTrue(interfaceDecl.isOriginalDeclaration);
  Expect.isTrue(boundedDecl.isOriginalDeclaration);

  Expect.isFalse(interfaceOfInt.isOriginalDeclaration);
  Expect.isFalse(interfaceOfR.isOriginalDeclaration);
  Expect.isFalse(interfaceOfBool.isOriginalDeclaration);
  Expect.isFalse(boundedOfInt.isOriginalDeclaration);
  Expect.isFalse(boundedOfString.isOriginalDeclaration); // //# 01: continued
  Expect.isFalse(interfaceOfFBounded.isOriginalDeclaration);
  Expect.isFalse(interfaceOfInt2.isOriginalDeclaration);
  Expect.isFalse(interfaceOfX.isOriginalDeclaration);
  Expect.isFalse(interfaceOfDouble.isOriginalDeclaration);
  Expect.isFalse(interfaceOfInt3.isOriginalDeclaration);
  Expect.isFalse(interfaceOfY.isOriginalDeclaration);
  Expect.isFalse(interfaceOfDouble2.isOriginalDeclaration);

  TypeVariableMirror tFromInterface = interfaceDecl.typeVariables.single;
  TypeVariableMirror sFromBounded = boundedDecl.typeVariables.single;
  TypeVariableMirror rFromGeneric = reflectClass(Generic).typeVariables.single;
  TypeVariableMirror xFromGenericMixinApplication =
      reflectClass(GenericMixinApplication).typeVariables.single;
  TypeVariableMirror yFromGenericClass =
      reflectClass(GenericClass).typeVariables.single;

  Expect.equals(reflectClass(Object), tFromInterface.upperBound);
  Expect.equals(reflectClass(num), sFromBounded.upperBound);
  Expect.equals(reflectClass(Object), rFromGeneric.upperBound);
  Expect.equals(reflectClass(Object), xFromGenericMixinApplication.upperBound);
  Expect.equals(reflectClass(Object), yFromGenericClass.upperBound);

  typeParameters(interfaceDecl, [#T]);
  typeParameters(boundedDecl, [#S]);
  typeParameters(interfaceOfInt, [#T]);
  typeParameters(interfaceOfR, [#T]);
  typeParameters(interfaceOfBool, [#T]);
  typeParameters(boundedOfInt, [#S]);
  typeParameters(boundedOfString, [#S]); // //# 01: continued
  typeParameters(interfaceOfFBounded, [#T]);
  typeParameters(interfaceOfInt2, [#T]);
  typeParameters(interfaceOfX, [#T]);
  typeParameters(interfaceOfDouble, [#T]);
  typeParameters(interfaceOfInt3, [#T]);
  typeParameters(interfaceOfY, [#T]);
  typeParameters(interfaceOfDouble2, [#T]);

  typeArguments(interfaceDecl, []);
  typeArguments(boundedDecl, []);
  typeArguments(interfaceOfInt, [reflectClass(int)]);
  typeArguments(interfaceOfR, [rFromGeneric]);
  typeArguments(interfaceOfBool, [reflectClass(bool)]);
  typeArguments(boundedOfInt, [reflectClass(int)]);
  typeArguments(boundedOfString, [reflectClass(String)]); // //# 01: continued
  typeArguments(interfaceOfFBounded, [reflectClass(FBounded)]);
  typeArguments(interfaceOfInt2, [reflectClass(int)]);
  typeArguments(interfaceOfX, [xFromGenericMixinApplication]);
  typeArguments(interfaceOfDouble, [reflectClass(double)]);
  typeArguments(interfaceOfInt3, [reflectClass(int)]);
  typeArguments(interfaceOfY, [yFromGenericClass]);
  typeArguments(interfaceOfDouble2, [reflectClass(double)]);
}
