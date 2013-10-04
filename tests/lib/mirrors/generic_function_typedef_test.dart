// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_function_typedef;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_test.dart';

typedef bool NonGenericPredicate(num);
typedef bool GenericPredicate<T>(T);
typedef S GenericTransform<S>(S);

class C<R> {
  GenericPredicate<num> predicateOfNum;
  GenericTransform<String> transformOfString;
  GenericTransform<R> transformOfR;
}

main() {
  TypeMirror dynamicMirror = currentMirrorSystem().dynamicType;

  TypedefMirror predicateOfNum = reflectClass(C).variables[#predicateOfNum].type;
  TypedefMirror transformOfString = reflectClass(C).variables[#transformOfString].type;
  TypedefMirror transformOfR = reflectClass(C).variables[#transformOfR].type;
  TypedefMirror transformOfDouble = reflect(new C<double>()).type.variables[#transformOfR].type;

  TypeVariableMirror rFromC = reflectClass(C).typeVariables[0];

  // Typedefs.
  typeParameters(reflectClass(NonGenericPredicate), []);
  typeParameters(reflectClass(GenericPredicate), [#T]);
  typeParameters(reflectClass(GenericTransform), [#S]);
  typeParameters(predicateOfNum, [#T]);
  typeParameters(transformOfString, [#S]);
  typeParameters(transformOfR, [#R]);
  typeParameters(transformOfDouble, [#R]);

  typeArguments(reflectClass(NonGenericPredicate), []);
  typeArguments(reflectClass(GenericPredicate), []);
  typeArguments(reflectClass(GenericTransform), []);
  typeArguments(predicateOfNum, [reflectClass(num)]);
  typeArguments(transformOfString, [reflectClass(String)]);
  typeArguments(transformOfR, [rFromC]);
  typeArguments(transformOfDouble, [reflect(double)]);

  Expect.isTrue(reflectClass(NonGenericPredicate).isOriginalDeclaration);
  Expect.isTrue(reflectClass(GenericPredicate).isOriginalDeclaration);
  Expect.isTrue(reflectClass(GenericTransform).isOriginalDeclaration);  
  Expect.isFalse(predicateOfNum.isOriginalDeclaration);  
  Expect.isFalse(transformOfString.isOriginalDeclaration);  
  Expect.isFalse(transformOfR.isOriginalDeclaration);  
  Expect.isFalse(transformOfDouble.isOriginalDeclaration);  

  // Function types.
  typeParameters(reflectClass(NonGenericPredicate).referent, []);
  typeParameters(reflectClass(GenericPredicate).referent, []);
  typeParameters(reflectClass(GenericTransform).referent, []);
  typeParameters(predicateOfNum.referent, []);
  typeParameters(transformOfString.referent, []);
  typeParameters(transformOfR.referent, []);
  typeParameters(transformOfDouble.referent, []);

  typeArguments(reflectClass(NonGenericPredicate).referent, []);
  typeArguments(reflectClass(GenericPredicate).referent, []);
  typeArguments(reflectClass(GenericTransform).referent, []);
  typeArguments(predicateOfNum.referent, []);
  typeArguments(transformOfString.referent, []);
  typeArguments(transformOfR.referent, []);
  typeArguments(transformOfDouble.referent, []);

  // Function types are always non-generic. Only the typedef is generic.
  Expect.isTrue(reflectClass(NonGenericPredicate).referent.isOriginalDeclaration);
  Expect.isTrue(reflectClass(GenericPredicate).referent.isOriginalDeclaration);
  Expect.isTrue(reflectClass(GenericTransform).referent.isOriginalDeclaration);  
  Expect.isTrue(predicateOfNum.referent.isOriginalDeclaration);  
  Expect.isTrue(transformOfString.referent.isOriginalDeclaration); 
  Expect.isTrue(transformOfR.referent.isOriginalDeclaration); // Er, but here we don't have concrete types...
  Expect.isTrue(transformOfDouble.referent.isOriginalDeclaration); 

  Expect.equals(reflectClass(num),
                reflectClass(NonGenericPredicate).referent.parameters[0].type);
  Expect.equals(dynamicMirror,
                reflectClass(GenericPredicate).referent.parameters[0].type);
  Expect.equals(dynamicMirror,
                reflectClass(GenericTransform).referent.parameters[0].type);
  Expect.equals(reflectClass(num),
                predicateOfNum.referent.parameters[0].type);
  Expect.equals(reflectClass(String),
                transformOfString.referent.parameters[0].type);
  Expect.equals(rFromC,
                transformOfR.referent.parameters[0].type);
  Expect.equals(reflectClass(double),
                transformOfDouble.referent.parameters[0].type);

  Expect.equals(reflectClass(bool),
                reflectClass(NonGenericPredicate).referent.returnType);
  Expect.equals(reflectClass(bool),
                reflectClass(GenericPredicate).referent.returnType);
  Expect.equals(dynamicMirror,
                reflectClass(GenericTransform).referent.returnType);
  Expect.equals(reflectClass(bool),
                predicateOfNum.referent.returnType);
  Expect.equals(reflectClass(String),
                transformOfString.referent.returnType);
  Expect.equals(rFromC,
                transformOfR.referent.returnType);
  Expect.equals(reflectClass(double),
                transformOfDouble.referent.returnType);
}
