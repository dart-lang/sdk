// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 'scope-marker';

class Class {
  static var field = /*
   class=Class,
   member=field
  */
      x;

  static empty() {
    /*
     class=Class,
     member=empty,
     static
    */
    x;
  }

  static oneParameter(a) {
    /*
     class=Class,
     member=oneParameter,
     static,
     variables=[a]
    */
    x;
  }

  static twoParameters(a, b) {
    /*
     class=Class,
     member=twoParameters,
     static,
     variables=[
      a,
      b]
    */
    x;
  }

  static optionalParameter(a, [b]) {
    /*
     class=Class,
     member=optionalParameter,
     static,
     variables=[
      a,
      b]
    */
    x;
  }

  static namedParameter(a, {b}) {
    /*
     class=Class,
     member=namedParameter,
     static,
     variables=[
      a,
      b]
    */
    x;
  }

  static oneTypeParameter<T>() {
    /*
     class=Class,
     member=oneTypeParameter,
     static,
     typeParameters=[T]
    */
    x;
  }
}
