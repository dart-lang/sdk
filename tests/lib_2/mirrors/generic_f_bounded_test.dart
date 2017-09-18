// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_f_bounded;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class Magnitude<T> {}

class Real extends Magnitude<Real> {}

class Sorter<R extends Magnitude<R>> {}

class RealSorter extends Sorter<Real> {}

main() {
  ClassMirror magnitudeDecl = reflectClass(Magnitude);
  ClassMirror realDecl = reflectClass(Real);
  ClassMirror sorterDecl = reflectClass(Sorter);
  ClassMirror realSorterDecl = reflectClass(RealSorter);
  ClassMirror magnitudeOfReal = realDecl.superclass;
  ClassMirror sorterOfReal = realSorterDecl.superclass;

  Expect.isTrue(magnitudeDecl.isOriginalDeclaration);
  Expect.isTrue(realDecl.isOriginalDeclaration);
  Expect.isTrue(sorterDecl.isOriginalDeclaration);
  Expect.isTrue(realSorterDecl.isOriginalDeclaration);
  Expect.isFalse(magnitudeOfReal.isOriginalDeclaration);
  Expect.isFalse(sorterOfReal.isOriginalDeclaration);

  TypeVariableMirror tFromMagnitude = magnitudeDecl.typeVariables.single;
  TypeVariableMirror rFromSorter = sorterDecl.typeVariables.single;

  Expect.equals(reflectClass(Object), tFromMagnitude.upperBound);

  ClassMirror magnitudeOfR = rFromSorter.upperBound;
  Expect.isFalse(magnitudeOfR.isOriginalDeclaration);
  Expect.equals(magnitudeDecl, magnitudeOfR.originalDeclaration);
  Expect.equals(rFromSorter, magnitudeOfR.typeArguments.single);

  typeParameters(magnitudeDecl, [#T]);
  typeParameters(realDecl, []);
  typeParameters(sorterDecl, [#R]);
  typeParameters(realSorterDecl, []);
  typeParameters(magnitudeOfReal, [#T]);
  typeParameters(sorterOfReal, [#R]);
  typeParameters(magnitudeOfR, [#T]);

  typeArguments(magnitudeDecl, []);
  typeArguments(realDecl, []);
  typeArguments(sorterDecl, []);
  typeArguments(realSorterDecl, []);
  typeArguments(magnitudeOfReal, [realDecl]); //# 01: ok
  typeArguments(sorterOfReal, [realDecl]); //# 01: ok
  typeArguments(magnitudeOfR, [rFromSorter]);
}
