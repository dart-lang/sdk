// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.type_argument_is_type_variable;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class SuperSuper<SS> {}

class Super<S> extends SuperSuper<S> {}

class Generic<G> extends Super<G> {}

main() {
  // Declarations.
  ClassMirror generic = reflectClass(Generic);
  ClassMirror superOfGeneric = generic.superclass;
  ClassMirror superOfSuperOfGeneric = superOfGeneric.superclass;

  TypeVariableMirror gFromGeneric = generic.typeVariables.single;
  TypeVariableMirror sFromSuper = superOfGeneric.typeVariables.single;
  TypeVariableMirror ssFromSuperSuper =
      superOfSuperOfGeneric.typeVariables.single;

  Expect.equals(#G, gFromGeneric.simpleName);
  Expect.equals(#S, sFromSuper.simpleName);
  Expect.equals(#SS, ssFromSuperSuper.simpleName);

  typeParameters(generic, [#G]);
  typeParameters(superOfGeneric, [#S]);
  typeParameters(superOfSuperOfGeneric, [#SS]);

  typeArguments(generic, []);
  typeArguments(superOfGeneric, [gFromGeneric]);
  typeArguments(superOfSuperOfGeneric, [gFromGeneric]);

  // Instantiations.
  ClassMirror genericWithInt = reflect(new Generic<int>()).type;
  ClassMirror superOfGenericWithInt = genericWithInt.superclass;
  ClassMirror superOfSuperOfGenericWithInt = superOfGenericWithInt.superclass;

  typeParameters(genericWithInt, [#G]);
  typeParameters(superOfGenericWithInt, [#S]);
  typeParameters(superOfSuperOfGenericWithInt, [#SS]);

  typeArguments(genericWithInt, [reflectClass(int)]);
  typeArguments(superOfGenericWithInt, [reflectClass(int)]);
  typeArguments(superOfSuperOfGenericWithInt, [reflectClass(int)]);
}
