// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test expectations for 'class_mirror_type_variables_data.dart'.

library class_mirror_type_variables_expect;

import "dart:mirrors";

import "package:expect/expect.dart";

/// The interface of [Env] is shared between the runtime and the source mirrors
/// test.
abstract class Env {
  ClassMirror getA();
  ClassMirror getB();
  ClassMirror getC();
  ClassMirror getD();
  ClassMirror getE();
  ClassMirror getF();
  ClassMirror getNoTypeParams();
  ClassMirror getObject();
  ClassMirror getString();
  ClassMirror getHelperOfString();
}

void test(Env env) {
  testNoTypeParams(env);
  testA(env);
  testBAndC(env);
  testD(env);
  testE(env);
  testF(env);
}

testNoTypeParams(Env env) {
  ClassMirror cm = env.getNoTypeParams();
  Expect.equals(cm.typeVariables.length, 0);
}

void testA(Env env) {
  ClassMirror a = env.getA();
  Expect.equals(2, a.typeVariables.length);

  TypeVariableMirror aT = a.typeVariables[0];
  TypeVariableMirror aS = a.typeVariables[1];
  ClassMirror aTBound = aT.upperBound;
  ClassMirror aSBound = aS.upperBound;

  Expect.isTrue(aTBound.isOriginalDeclaration);
  Expect.isTrue(aSBound.isOriginalDeclaration);

  Expect.equals(env.getObject(), aTBound);
  Expect.equals(env.getString(), aSBound);
}

void testBAndC(Env env) {
  ClassMirror b = env.getB();
  ClassMirror c = env.getC();

  Expect.equals(1, b.typeVariables.length);
  Expect.equals(1, c.typeVariables.length);

  TypeVariableMirror bZ = b.typeVariables[0];
  TypeVariableMirror cZ = c.typeVariables[0];
  ClassMirror bZBound = bZ.upperBound;
  ClassMirror cZBound = cZ.upperBound;

  Expect.isFalse(bZBound.isOriginalDeclaration);
  Expect.isFalse(cZBound.isOriginalDeclaration);

  Expect.notEquals(bZBound, cZBound);
  Expect.equals(b, bZBound.originalDeclaration);
  Expect.equals(b, cZBound.originalDeclaration);

  TypeMirror bZBoundTypeArgument = bZBound.typeArguments.single;
  TypeMirror cZBoundTypeArgument = cZBound.typeArguments.single;
  TypeVariableMirror bZBoundTypeVariable = bZBound.typeVariables.single;
  TypeVariableMirror cZBoundTypeVariable = cZBound.typeVariables.single;

  Expect.equals(b, bZ.owner);
  Expect.equals(c, cZ.owner);
  Expect.equals(b, bZBoundTypeVariable.owner);
  Expect.equals(b, cZBoundTypeVariable.owner);
  Expect.equals(b, bZBoundTypeArgument.owner);
  Expect.equals(c, cZBoundTypeArgument.owner);

  Expect.notEquals(bZ, cZ);
  Expect.equals(bZ, bZBoundTypeArgument);
  Expect.equals(cZ, cZBoundTypeArgument);
  Expect.equals(bZ, bZBoundTypeVariable);
  Expect.equals(bZ, cZBoundTypeVariable);
}

testD(Env env) {
  ClassMirror cm = env.getD();
  Expect.equals(3, cm.typeVariables.length);
  var values = cm.typeVariables;
  values.forEach((e) {
    Expect.equals(true, e is TypeVariableMirror);
  });
  Expect.equals(#R, values.elementAt(0).simpleName);
  Expect.equals(#S, values.elementAt(1).simpleName);
  Expect.equals(#T, values.elementAt(2).simpleName);
}

void testE(Env env) {
  ClassMirror e = env.getE();
  TypeVariableMirror eR = e.typeVariables.single;
  ClassMirror mapRAndHelperOfString = eR.upperBound;

  Expect.isFalse(mapRAndHelperOfString.isOriginalDeclaration);
  Expect.equals(eR, mapRAndHelperOfString.typeArguments.first);
  Expect.equals(
      env.getHelperOfString(), mapRAndHelperOfString.typeArguments.last);
}

void testF(Env env) {
  ClassMirror f = env.getF();
  TypeVariableMirror fZ = f.typeVariables[0];
  ClassMirror fZBound = fZ.upperBound;
  ClassMirror fZBoundTypeArgument = fZBound.typeArguments.single;

  Expect.equals(1, f.typeVariables.length);
  Expect.isFalse(fZBound.isOriginalDeclaration);
  Expect.isFalse(fZBoundTypeArgument.isOriginalDeclaration);
  Expect.equals(f, fZBoundTypeArgument.originalDeclaration);
  Expect.equals(fZ, fZBoundTypeArgument.typeArguments.single);
}
