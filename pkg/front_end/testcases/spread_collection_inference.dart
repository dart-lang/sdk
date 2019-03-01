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

  var /*@type=List<int>*/ lhs20 = /*@typeArgs=int*/ [...spread];

  var /*@type=List<dynamic>*/ lhs21 = /*@typeArgs=dynamic*/ [...(spread as
      dynamic)];

  List<int> lhs22 = /*@typeArgs=int*/ [... /*@typeArgs=int*/ []];

  List<List<int>> lhs23 = /*@typeArgs=List<int>*/ [... /*@typeArgs=List<int>*/
    [/*@typeArgs=int*/ []]];

  int lhs30 = /*@error=InvalidAssignment*/ /*@typeArgs=int*/ [...spread];

  var /*@type=List<dynamic>*/ lhs40 = /*@typeArgs=dynamic*/ [...
    /*@error=SpreadTypeMismatch*/ notSpreadInt];

  var /*@type=List<dynamic>*/ lhs50 = /*@typeArgs=dynamic*/ [...
    /*@error=SpreadTypeMismatch*/ notSpreadFunction];
}

main() {}
