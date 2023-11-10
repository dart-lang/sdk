// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 'scope-marker';

class Class {
  var field = /*
   class=Class,
   member=field
  */
      x;

  empty() {
    /*
     class=Class,
     member=empty
    */
    x;
  }

  oneParameter(a) {
    /*
     class=Class,
     member=oneParameter,
     variables=[a]
    */
    x;
  }

  twoParameters(a, b) {
    /*
     class=Class,
     member=twoParameters,
     variables=[
      a,
      b]
    */
    x;
  }

  optionalParameter(a, [b]) {
    /*
     class=Class,
     member=optionalParameter,
     variables=[
      a,
      b]
    */
    x;
  }

  namedParameter(a, {b}) {
    /*
     class=Class,
     member=namedParameter,
     variables=[
      a,
      b]
    */
    x;
  }

  oneTypeParameter<T>() {
    /*
     class=Class,
     member=oneTypeParameter,
     typeParameters=[T]
    */
    x;
  }
}

class GenericClass<T> {
  classTypeParameter() {
    /*
     class=GenericClass,
     member=classTypeParameter,
     typeParameters=[T]
    */
    x;
  }

  mixedTypeParameter<S>() {
    /*
     class=GenericClass,
     member=mixedTypeParameter,
     typeParameters=[
      S,
      T]
    */
    x;
  }
}
