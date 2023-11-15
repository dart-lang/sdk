// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 'scope-marker';

class Class {
  var field;

  Class.empty()
      : field = /*
   class=Class,
   member=empty
  */
            x {
    /*
     class=Class,
     member=empty
    */
    x;
  }

  Class.oneParameter(a)
      : field = /*
   class=Class,
   member=oneParameter,
   variables=[a]
  */
            x {
    /*
     class=Class,
     member=oneParameter,
     variables=[a]
    */
    x;
  }

  Class.twoParameters(a, b)
      : field = /*
   class=Class,
   member=twoParameters,
   variables=[
    a,
    b]
  */
            x {
    /*
     class=Class,
     member=twoParameters,
     variables=[
      a,
      b]
    */
    x;
  }

  Class.optionalParameter(a, [b])
      : field = /*
   class=Class,
   member=optionalParameter,
   variables=[
    a,
    b]
  */
            x {
    /*
     class=Class,
     member=optionalParameter,
     variables=[
      a,
      b]
    */
    x;
  }

  Class.namedParameter(a, {b})
      : field = /*
   class=Class,
   member=namedParameter,
   variables=[
    a,
    b]
  */
            x {
    /*
     class=Class,
     member=namedParameter,
     variables=[
      a,
      b]
    */
    x;
  }
}
