// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'dart:mirrors';
import 'package:expect/expect.dart';

class S<T> {
  T n() {
    return null;
  }
}

class M<T, U> {
  T m() { return null;}
  U n() { return null;}
}

class N<T, U> {
  U m() { return null;}
}

class A extends S<String> {}
class O<V> extends S<V> with M<String,V> {}
class P<W> extends S<W> with M<W, String>, N<String, W> {}
class TE extends S<String> with M<int, String>, N<String, int> {}

testOriginal() {
  ClassMirror s = reflectClass(S);
  ClassMirror m = reflectClass(M);
  ClassMirror o = reflectClass(O);
  ClassMirror p = reflectClass(P);
  ClassMirror mixinApplicationSuperO = o.superclass;
  ClassMirror sOfV = mixinApplicationSuperO.superclass;
  ClassMirror mOfStringAndW = mixinApplicationSuperO.mixin;
  ClassMirror mixinApplicationSuperP = p.superclass;
  ClassMirror nOfStringAndW = mixinApplicationSuperP.mixin;
  ClassMirror mixinApplicationSuperSuperP = mixinApplicationSuperP.superclass;
  ClassMirror sOfW = mixinApplicationSuperSuperP.superclass;
  ClassMirror mOfWAndString = mixinApplicationSuperSuperP.mixin;
  TypeVariableMirror oV = o.typeVariables[0];
  TypeVariableMirror pW = p.typeVariables[0];
  TypeMirror stringMirror = reflectType(String);

  Expect.isTrue(o.isOriginalDeclaration);
  Expect.isTrue(p.isOriginalDeclaration);
  Expect.isFalse(mixinApplicationSuperO.isOriginalDeclaration);
  Expect.isFalse(mOfStringAndW.isOriginalDeclaration);
  Expect.isFalse(sOfV.isOriginalDeclaration);
  Expect.isFalse(mixinApplicationSuperP.isOriginalDeclaration);
  Expect.isFalse(nOfStringAndW.isOriginalDeclaration);
  Expect.isFalse(mixinApplicationSuperSuperP.isOriginalDeclaration);
  Expect.isFalse(sOfW.isOriginalDeclaration);
  Expect.isFalse(mOfWAndString.isOriginalDeclaration);

  Expect.isTrue(mixinApplicationSuperO.typeVariables.isEmpty);
  Expect.isTrue(mixinApplicationSuperO.typeArguments.isEmpty);
  Expect.isTrue(mixinApplicationSuperP.typeVariables.isEmpty);
  Expect.isTrue(mixinApplicationSuperP.typeArguments.isEmpty);
  Expect.isTrue(mixinApplicationSuperSuperP.typeVariables.isEmpty);
  Expect.isTrue(mixinApplicationSuperSuperP.typeArguments.isEmpty);

  Expect.equals(oV, sOfV.typeArguments.single);

  MethodMirror sOfVMethod = sOfV.declarations[#n];
  MethodMirror mOfStringAndWMethodM = mOfStringAndW.declarations[#m];
  MethodMirror mOfStringAndWMethodN = mOfStringAndW.declarations[#n];
  MethodMirror nOfStringAndWMethodM = nOfStringAndW.declarations[#m];
  MethodMirror sOfWMethodN = sOfW.declarations[#n];
  MethodMirror mOfWAndStringMethodM = mOfWAndString.declarations[#m];
  MethodMirror mOfWAndStringMethodN = mOfWAndString.declarations[#n];
  MethodMirror superOMethodN = mixinApplicationSuperO.declarations[#n];
  MethodMirror superOMethodM = mixinApplicationSuperO.declarations[#m];

  Expect.equals(oV, sOfVMethod.returnType);
  Expect.equals(stringMirror, mOfStringAndW.typeArguments.first);
  Expect.equals(oV, mOfStringAndW.typeArguments.last);
  Expect.equals(stringMirror, mOfStringAndWMethodM.returnType);
  Expect.equals(oV, mOfStringAndWMethodN.returnType);

  Expect.equals(stringMirror, nOfStringAndW.typeArguments.first);
  Expect.equals(pW, nOfStringAndW.typeArguments.last);
  Expect.equals(pW, nOfStringAndWMethodM.returnType);
  Expect.equals(pW, sOfW.typeArguments.single);
  Expect.equals(pW, sOfWMethodN.returnType);
  Expect.equals(pW, mOfWAndString.typeArguments.first);
  Expect.equals(stringMirror, mOfWAndString.typeArguments.last);
  Expect.equals(pW, mOfWAndStringMethodM.returnType);
  Expect.equals(stringMirror, mOfWAndStringMethodN.returnType);

  Expect.equals(oV, superOMethodN.returnType);
  Expect.equals(stringMirror, superOMethodM.returnType);

}

testInstance() {
  ClassMirror s = reflectClass(S);
  ClassMirror m = reflectClass(M);
  ClassMirror o = reflect(new O<int>()).type;
  ClassMirror p = reflect(new P<int>()).type;
  ClassMirror mixinApplicationSuperO = o.superclass;
  ClassMirror cOfInt = mixinApplicationSuperO.superclass;

  ClassMirror mOfStringAndInt = mixinApplicationSuperO.mixin;
  ClassMirror mixinApplicationSuperP = p.superclass;
  ClassMirror nOfStringAndInt = mixinApplicationSuperP.mixin;
  ClassMirror mixinApplicationSuperSuperP = mixinApplicationSuperP.superclass;
  ClassMirror sOfW = mixinApplicationSuperSuperP.superclass;
  ClassMirror mOfWAndString = mixinApplicationSuperSuperP.mixin;
  TypeMirror oInt = o.typeArguments[0];
  TypeMirror pInt = p.typeArguments[0];
  TypeMirror stringMirror = reflectType(String);
  TypeMirror intMirror = reflectType(int);

  Expect.isFalse(o.isOriginalDeclaration);
  Expect.isFalse(p.isOriginalDeclaration);
  Expect.isFalse(mixinApplicationSuperO.isOriginalDeclaration);
  Expect.isFalse(mOfStringAndInt.isOriginalDeclaration);
  Expect.isFalse(cOfInt.isOriginalDeclaration);
  Expect.isFalse(mixinApplicationSuperP.isOriginalDeclaration);
  Expect.isFalse(nOfStringAndInt.isOriginalDeclaration);
  Expect.isFalse(mixinApplicationSuperSuperP.isOriginalDeclaration);
  Expect.isFalse(sOfW.isOriginalDeclaration);
  Expect.isFalse(mOfWAndString.isOriginalDeclaration);

  Expect.isTrue(mixinApplicationSuperO.typeVariables.isEmpty);
  Expect.isTrue(mixinApplicationSuperO.typeArguments.isEmpty);
  Expect.isTrue(mixinApplicationSuperP.typeVariables.isEmpty);
  Expect.isTrue(mixinApplicationSuperP.typeArguments.isEmpty);
  Expect.isTrue(mixinApplicationSuperSuperP.typeVariables.isEmpty);
  Expect.isTrue(mixinApplicationSuperSuperP.typeArguments.isEmpty);

  MethodMirror cOfIntMethod = cOfInt.declarations[#n];
  MethodMirror mOfStringAndIntMethodM = mOfStringAndInt.declarations[#m];
  MethodMirror mOfStringAndIntMethodN = mOfStringAndInt.declarations[#n];
  MethodMirror nOfStringAndIntMethodM = nOfStringAndInt.declarations[#m];
  MethodMirror sOfWMethodN = sOfW.declarations[#n];
  MethodMirror mOfWAndStringMethodM = mOfWAndString.declarations[#m];
  MethodMirror mOfWAndStringMethodN = mOfWAndString.declarations[#n];
  MethodMirror superOMethodN = mixinApplicationSuperO.declarations[#n];
  MethodMirror superOMethodM = mixinApplicationSuperO.declarations[#m];

  Expect.equals(oInt, cOfInt.typeArguments.single);
  Expect.equals(oInt, cOfIntMethod.returnType);
  Expect.equals(stringMirror, mOfStringAndInt.typeArguments.first);
  Expect.equals(oInt, mOfStringAndInt.typeArguments.last);
  Expect.equals(stringMirror, mOfStringAndIntMethodM.returnType);
  Expect.equals(oInt, mOfStringAndIntMethodN.returnType);

  Expect.equals(stringMirror, nOfStringAndInt.typeArguments.first);
  Expect.equals(pInt, nOfStringAndInt.typeArguments.last);
  Expect.equals(pInt, nOfStringAndIntMethodM.returnType);
  Expect.equals(pInt, sOfW.typeArguments.single);
  Expect.equals(pInt, sOfWMethodN.returnType);
  Expect.equals(pInt, mOfWAndString.typeArguments.first);
  Expect.equals(stringMirror, mOfWAndString.typeArguments.last);
  Expect.equals(pInt, mOfWAndStringMethodM.returnType);
  Expect.equals(stringMirror, mOfWAndStringMethodN.returnType);

  Expect.equals(oInt, superOMethodN.returnType);
  Expect.equals(stringMirror, superOMethodM.returnType);
}

main() {
  testOriginal();
  testInstance();
}