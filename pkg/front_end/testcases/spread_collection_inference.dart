// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test case checks that inference works for spread collections, and that
// the errors are reported when necessary.

/*@testedFeatures=inference,error*/

foo() {
  List<int> spread = <int>[1, 2, 3];
  Map<String, int> mapSpread = <String, int>{"foo": 4, "bar": 2};
  int notSpreadInt = 42;
  int Function() notSpreadFunction = null;

  var /*@type=List<dynamic>*/ lhs10 = /*@typeArgs=dynamic*/ [...
    /*@typeArgs=dynamic*/ []];

  var /*@type=Set<dynamic>*/ set10 = <dynamic>{... /*@typeArgs=dynamic*/ []};

  var /*@type=Map<dynamic, dynamic>*/ map10 = <dynamic, dynamic>{...
    /*@typeArgs=dynamic, dynamic*/ {}};

  var /*@type=Map<dynamic, dynamic>*/ map10ambiguous =
    /*@typeArgs=dynamic, dynamic*/ {...  /*@typeArgs=dynamic, dynamic*/ {}};

  var /*@type=List<int>*/ lhs20 = /*@typeArgs=int*/ [...spread];

  var /*@type=Set<int>*/ set20 = /*@typeArgs=int*/ {...spread, 42};

  var /*@type=Set<int>*/ set20ambiguous = /*@typeArgs=int*/ {...spread};

  var /*@type=Map<String, int>*/ map20 = /*@typeArgs=String, int*/
    {...mapSpread, "baz": 42};

  var /*@type=Map<String, int>*/ map20ambiguous = /*@typeArgs=String, int*/
    {...mapSpread};

  var /*@type=List<dynamic>*/ lhs21 = /*@typeArgs=dynamic*/ [...(spread as
      dynamic)];

  var /*@type=Set<dynamic>*/ set21 = /*@typeArgs=dynamic*/ {...(spread as
      dynamic), 42};

  var /*@type=Map<dynamic, dynamic>*/ map21 = /*@typeArgs=dynamic, dynamic*/
    {...(mapSpread as dynamic), "baz": 42};

  dynamic map21ambiguous = /*@error=CantDisambiguateNotEnoughInformation*/ {...
    (mapSpread as dynamic)};

  List<int> lhs22 = /*@typeArgs=int*/ [... /*@typeArgs=int*/ []];

  Set<int> set22 = /*@typeArgs=int*/ {... /*@typeArgs=int*/ [], 42};

  Set<int> set22ambiguous = /*@typeArgs=int*/ {... /*@typeArgs=int*/ []};

  Map<String, int> map22 = /*@typeArgs=String, int*/
    {... /*@typeArgs=String, int*/ {}};

  List<List<int>> lhs23 = /*@typeArgs=List<int>*/ [... /*@typeArgs=List<int>*/
    [/*@typeArgs=int*/ []]];

  Set<List<int>> set23 = /*@typeArgs=List<int>*/ {... /*@typeArgs=List<int>*/
    [/*@typeArgs=int*/ []], <int>[42]};

  Set<List<int>> set23ambiguous = /*@typeArgs=List<int>*/
    {... /*@typeArgs=List<int>*/ [/*@typeArgs=int*/ []]};

  Map<String, List<int>> map23 = /*@typeArgs=String, List<int>*/
    {... /*@typeArgs=String, List<int>*/ {"baz": /*@typeArgs=int*/ []}};

  dynamic map24ambiguous = /*@error=CantDisambiguateAmbiguousInformation*/ {...
    spread, ...mapSpread};

  int lhs30 = /*@error=InvalidAssignment*/ /*@typeArgs=int*/ [...spread];

  int set30 = /*@error=InvalidAssignment*/ /*@typeArgs=int*/ {...spread, 42};

  int set30ambiguous = /*@error=InvalidAssignment*/ /*@typeArgs=int*/
    {...spread};

  int map30 = /*@error=InvalidAssignment*/ /*@typeArgs=String, int*/
    {...mapSpread, "baz": 42};

  int map30ambiguous = /*@error=InvalidAssignment*/ /*@typeArgs=String, int*/
    {...mapSpread};

  List<dynamic> lhs40 = <dynamic>[... /*@error=SpreadTypeMismatch*/
    notSpreadInt];

  Set<dynamic> set40 = <dynamic>{... /*@error=SpreadTypeMismatch*/
    notSpreadInt};

  Map<dynamic, dynamic> map40 = <dynamic, dynamic>{...
    /*@error=SpreadMapEntryTypeMismatch*/ notSpreadInt};

  List<dynamic> lhs50 = <dynamic> [... /*@error=SpreadTypeMismatch*/
    notSpreadFunction];

  Set<dynamic> set50 = <dynamic> {... /*@error=SpreadTypeMismatch*/
    notSpreadFunction};

  Map<dynamic, dynamic> map50 = <dynamic, dynamic>{...
    /*@error=SpreadMapEntryTypeMismatch*/ notSpreadFunction};

  List<String> lhs60 = <String>[... /*@error=SpreadElementTypeMismatch*/
    spread];

  Set<String> set60 = <String>{... /*@error=SpreadElementTypeMismatch*/ spread};

  Map<int, int> map60 = <int, int>{...
    /*@error=SpreadMapEntryElementKeyTypeMismatch*/ mapSpread};

  Map<String, String> map61 = <String, String>{...
    /*@error=SpreadMapEntryElementValueTypeMismatch*/ mapSpread};

  List<int> lhs70 = <int>[... /*@error=NonNullAwareSpreadIsNull*/ null];

  Set<int> set70 = <int>{... /*@error=NonNullAwareSpreadIsNull*/ null};

  var /*@type=Set<dynamic>*/ set71ambiguous = /*@typeArgs=dynamic*/
    {... /*@error=NonNullAwareSpreadIsNull*/ null, ... /*@typeArgs=dynamic*/
      []};

  Map<String, int> map70 = <String, int>{... /*@error=NonNullAwareSpreadIsNull*/
    null};

  List<int> lhs80 = <int>[...?null];

  Set<int> set80 = <int>{...?null};

  var /*@type=Set<dynamic>*/ set81ambiguous = /*@typeArgs=dynamic*/
    {...?null, ... /*@typeArgs=dynamic*/ []};

  Map<String, int> map80 = <String, int>{...?null};
}

main() {}
