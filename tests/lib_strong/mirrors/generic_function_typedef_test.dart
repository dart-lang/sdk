// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_function_typedef;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

typedef bool NonGenericPredicate(num n);
typedef bool GenericPredicate<T>(T t);
typedef S GenericTransform<S>(S s);

class C<R> {
  GenericPredicate<num> predicateOfNum;
  GenericTransform<String> transformOfString;
  GenericTransform<R> transformOfR;
}

reflectTypeDeclaration(t) => reflectType(t).originalDeclaration;

main() {
  TypeMirror dynamicMirror = currentMirrorSystem().dynamicType;

  TypedefMirror predicateOfNum =
      (reflectClass(C).declarations[#predicateOfNum] as VariableMirror).type;
  TypedefMirror transformOfString =
      (reflectClass(C).declarations[#transformOfString] as VariableMirror).type;
  TypedefMirror transformOfR =
      (reflectClass(C).declarations[#transformOfR] as VariableMirror).type;
  TypedefMirror transformOfDouble = (reflect(new C<double>())
          .type
          .declarations[#transformOfR] as VariableMirror)
      .type;

  TypeVariableMirror tFromGenericPredicate =
      reflectTypeDeclaration(GenericPredicate).typeVariables[0];
  TypeVariableMirror sFromGenericTransform =
      reflectTypeDeclaration(GenericTransform).typeVariables[0];
  TypeVariableMirror rFromC = reflectClass(C).typeVariables[0];

  // Typedefs.
  typeParameters(reflectTypeDeclaration(NonGenericPredicate), []);
  typeParameters(reflectTypeDeclaration(GenericPredicate), [#T]);
  typeParameters(reflectTypeDeclaration(GenericTransform), [#S]);
  typeParameters(predicateOfNum, [#T]);
  typeParameters(transformOfString, [#S]);
  typeParameters(transformOfR, [#S]);
  typeParameters(transformOfDouble, [#S]);

  typeArguments(reflectTypeDeclaration(NonGenericPredicate), []);
  typeArguments(reflectTypeDeclaration(GenericPredicate), []);
  typeArguments(reflectTypeDeclaration(GenericTransform), []);
  typeArguments(predicateOfNum, [reflectClass(num)]);
  typeArguments(transformOfString, [reflectClass(String)]);
  typeArguments(transformOfR, [rFromC]);
  typeArguments(transformOfDouble, [reflectClass(double)]);

  Expect.isTrue(
      reflectTypeDeclaration(NonGenericPredicate).isOriginalDeclaration);
  Expect.isTrue(reflectTypeDeclaration(GenericPredicate).isOriginalDeclaration);
  Expect.isTrue(reflectTypeDeclaration(GenericTransform).isOriginalDeclaration);
  Expect.isFalse(predicateOfNum.isOriginalDeclaration);
  Expect.isFalse(transformOfString.isOriginalDeclaration);
  Expect.isFalse(transformOfR.isOriginalDeclaration);
  Expect.isFalse(transformOfDouble.isOriginalDeclaration);

  // Function types.
  typeParameters(reflectTypeDeclaration(NonGenericPredicate).referent, []);
  typeParameters(reflectTypeDeclaration(GenericPredicate).referent, []);
  typeParameters(reflectTypeDeclaration(GenericTransform).referent, []);
  typeParameters(predicateOfNum.referent, []);
  typeParameters(transformOfString.referent, []);
  typeParameters(transformOfR.referent, []);
  typeParameters(transformOfDouble.referent, []);

  typeArguments(reflectTypeDeclaration(NonGenericPredicate).referent, []);
  typeArguments(reflectTypeDeclaration(GenericPredicate).referent, []);
  typeArguments(reflectTypeDeclaration(GenericTransform).referent, []);
  typeArguments(predicateOfNum.referent, []);
  typeArguments(transformOfString.referent, []);
  typeArguments(transformOfR.referent, []);
  typeArguments(transformOfDouble.referent, []);

  // Function types are always non-generic. Only the typedef is generic.
  Expect.isTrue(reflectTypeDeclaration(NonGenericPredicate)
      .referent
      .isOriginalDeclaration);
  Expect.isTrue(
      reflectTypeDeclaration(GenericPredicate).referent.isOriginalDeclaration);
  Expect.isTrue(
      reflectTypeDeclaration(GenericTransform).referent.isOriginalDeclaration);
  Expect.isTrue(predicateOfNum.referent.isOriginalDeclaration);
  Expect.isTrue(transformOfString.referent.isOriginalDeclaration);
  Expect.isTrue(transformOfR.referent.isOriginalDeclaration);
  Expect.isTrue(transformOfDouble.referent.isOriginalDeclaration);

  Expect.equals(reflectClass(num),
      reflectTypeDeclaration(NonGenericPredicate).referent.parameters[0].type);
  Expect.equals(tFromGenericPredicate,
      reflectTypeDeclaration(GenericPredicate).referent.parameters[0].type);
  Expect.equals(sFromGenericTransform,
      reflectTypeDeclaration(GenericTransform).referent.parameters[0].type);

  Expect.equals(reflectClass(num), predicateOfNum.referent.parameters[0].type);
  Expect.equals(
      reflectClass(String), transformOfString.referent.parameters[0].type);
  Expect.equals(rFromC, transformOfR.referent.parameters[0].type);
  Expect.equals(
      reflectClass(double), transformOfDouble.referent.parameters[0].type);

  Expect.equals(reflectClass(bool),
      reflectTypeDeclaration(NonGenericPredicate).referent.returnType);
  Expect.equals(reflectClass(bool),
      reflectTypeDeclaration(GenericPredicate).referent.returnType);
  Expect.equals(sFromGenericTransform,
      reflectTypeDeclaration(GenericTransform).referent.returnType);
  Expect.equals(reflectClass(bool), predicateOfNum.referent.returnType);
  Expect.equals(reflectClass(String), transformOfString.referent.returnType);
  Expect.equals(rFromC, transformOfR.referent.returnType);
  Expect.equals(reflectClass(double), transformOfDouble.referent.returnType);
}
