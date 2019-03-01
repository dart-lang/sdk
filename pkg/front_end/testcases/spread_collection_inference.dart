// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test case checks that inference works for spread collections, and that
// the errors are reported when necessary.

/*@testedFeatures=inference,error*/

foo() {
  List<int> spread = <int>[1, 2, 3];
  int notSpreadInt = 42;
  int Function() notSpreadFunction = null;

  var /*@type=List<dynamic>*/ lhs10 = /*@typeArgs=dynamic*/ [...
    /*@typeArgs=dynamic*/ []];

  var /*@type=Set<dynamic>*/ set10 = <dynamic>{... /*@typeArgs=dynamic*/ []};

  var /*@type=List<int>*/ lhs20 = /*@typeArgs=int*/ [...spread];

  var /*@type=Set<int>*/ set20 = /*@typeArgs=int*/ {...spread, 42};

  var /*@type=List<dynamic>*/ lhs21 = /*@typeArgs=dynamic*/ [...(spread as
      dynamic)];

  var /*@type=Set<dynamic>*/ set21 = /*@typeArgs=dynamic*/ {...(spread as
      dynamic), 42};

  List<int> lhs22 = /*@typeArgs=int*/ [... /*@typeArgs=int*/ []];

  Set<int> set22 = /*@typeArgs=int*/ {... /*@typeArgs=int*/ [], 42};

  List<List<int>> lhs23 = /*@typeArgs=List<int>*/ [... /*@typeArgs=List<int>*/
    [/*@typeArgs=int*/ []]];

  Set<List<int>> set23 = /*@typeArgs=List<int>*/ {... /*@typeArgs=List<int>*/
    [/*@typeArgs=int*/ []], <int>[42]};

  int lhs30 = /*@error=InvalidAssignment*/ /*@typeArgs=int*/ [...spread];

  int set30 = /*@error=InvalidAssignment*/ /*@typeArgs=int*/ {...spread, 42};

  var /*@type=List<dynamic>*/ lhs40 = /*@typeArgs=dynamic*/ [...
    /*@error=SpreadTypeMismatch*/ notSpreadInt];

  var /*@type=Set<dynamic>*/ set40 = /*@typeArgs=dynamic*/ {...
    /*@error=SpreadTypeMismatch*/ notSpreadInt, 42};

  var /*@type=List<dynamic>*/ lhs50 = /*@typeArgs=dynamic*/ [...
    /*@error=SpreadTypeMismatch*/ notSpreadFunction];

  var /*@type=Set<dynamic>*/ set50 = /*@typeArgs=dynamic*/ {...
    /*@error=SpreadTypeMismatch*/ notSpreadFunction, 42};
}

main() {}
