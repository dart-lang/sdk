// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 'scope-marker';

empty() {
  /*
   member=empty,
   static
  */
  x;
}

oneParameter(a) {
  /*
   member=oneParameter,
   static,
   variables=[a]
  */
  x;
}

twoParameters(a, b) {
  /*
   member=twoParameters,
   static,
   variables=[
    a,
    b]
  */
  x;
}

optionalParameter(a, [b]) {
  /*
   member=optionalParameter,
   static,
   variables=[
    a,
    b]
  */
  x;
}

namedParameter(a, {b}) {
  /*
   member=namedParameter,
   static,
   variables=[
    a,
    b]
  */
  x;
}

oneTypeParameter<T>() {
  /*
   member=oneTypeParameter,
   static,
   typeParameters=[T]
  */
  x;
}

var field = /*member=field*/ x;
