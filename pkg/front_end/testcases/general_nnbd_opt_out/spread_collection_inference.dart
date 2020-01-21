// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// This test case checks that inference works for spread collections, and that
// the errors are reported when necessary.

/*@testedFeatures=inference*/

Map<K, V> bar<K, V>() => null;

foo(dynamic dynVar) {
  List<int> spread = <int>[1, 2, 3];
  Map<String, int> mapSpread = <String, int>{"foo": 4, "bar": 2};
  int notSpreadInt = 42;
  int Function() notSpreadFunction = null;
  // Note that all values are actually ints.
  Map<int, num> mapIntNum = <int, num>{42: 42};
  List<num> listNum = <num>[42];

  var /*@ type=List<dynamic>* */ lhs10 = /*@ typeArgs=dynamic */ [
    ...
    /*@ typeArgs=dynamic */ []
  ];

  var /*@ type=Set<dynamic>* */ set10 = <dynamic>{
    ... /*@ typeArgs=dynamic */ []
  };

  var /*@ type=Map<dynamic, dynamic>* */ map10 = <dynamic, dynamic>{
    ...
    /*@ typeArgs=dynamic, dynamic */ {}
  };

  var /*@ type=Map<dynamic, dynamic>* */ map10ambiguous =
      /*@ typeArgs=dynamic, dynamic */ {
    ... /*@ typeArgs=dynamic, dynamic */ {}
  };

  var /*@ type=List<int*>* */ lhs20 = /*@ typeArgs=int* */ [...spread];

  var /*@ type=Set<int*>* */ set20 = /*@ typeArgs=int* */ {...spread, 42};

  var /*@ type=Set<int*>* */ set20ambiguous = /*@ typeArgs=int* */ {...spread};

  var /*@ type=Map<String*, int*>* */ map20 = /*@ typeArgs=String*, int* */
      {...mapSpread, "baz": 42};

  var /*@ type=Map<String*, int*>* */ map20ambiguous = /*@ typeArgs=String*, int* */
      {...mapSpread};

  var /*@ type=List<dynamic>* */ lhs21 = /*@ typeArgs=dynamic */ [
    ...(spread as dynamic)
  ];

  var /*@ type=Set<dynamic>* */ set21 = /*@ typeArgs=dynamic */ {
    ...(spread as dynamic),
    42
  };

  var /*@ type=Map<dynamic, dynamic>* */ map21 = /*@ typeArgs=dynamic, dynamic */
      {...(mapSpread as dynamic), "baz": 42};

  dynamic map21ambiguous = {...(mapSpread as dynamic)};

  List<int> lhs22 = /*@ typeArgs=int* */ [... /*@ typeArgs=int* */ []];

  Set<int> set22 = /*@ typeArgs=int* */ {... /*@ typeArgs=int* */ [], 42};

  Set<int> set22ambiguous = /*@ typeArgs=int* */ {... /*@ typeArgs=int* */ []};

  Map<String, int> map22 = /*@ typeArgs=String*, int* */
      {... /*@ typeArgs=String*, int* */ {}};

  List<List<int>> lhs23 = /*@ typeArgs=List<int*>* */ [
    ... /*@ typeArgs=List<int*>* */
    [/*@ typeArgs=int* */ []]
  ];

  Set<List<int>> set23 = /*@ typeArgs=List<int*>* */ {
    ... /*@ typeArgs=List<int*>* */
    [/*@ typeArgs=int* */ []],
    <int>[42]
  };

  Set<List<int>> set23ambiguous = /*@ typeArgs=List<int*>* */
      {
    ... /*@ typeArgs=List<int*>* */ [/*@ typeArgs=int* */ []]
  };

  Map<String, List<int>> map23 = /*@ typeArgs=String*, List<int*>* */
      {
    ... /*@ typeArgs=String*, List<int*>* */ {"baz": /*@ typeArgs=int* */ [] }
  };

  dynamic map24ambiguous = {...spread, ...mapSpread};

  int lhs30 = /*@ typeArgs=int* */ [...spread];

  int set30 = /*@ typeArgs=int* */ {...spread, 42};

  int set30ambiguous = /*@ typeArgs=int* */
      {...spread};

  int map30 = /*@ typeArgs=String*, int* */
      {...mapSpread, "baz": 42};

  int map30ambiguous = /*@ typeArgs=String*, int* */
      {...mapSpread};

  List<dynamic> lhs40 = <dynamic>[...notSpreadInt];

  Set<dynamic> set40 = <dynamic>{...notSpreadInt};

  Map<dynamic, dynamic> map40 = <dynamic, dynamic>{...notSpreadInt};

  List<dynamic> lhs50 = <dynamic>[...notSpreadFunction];

  Set<dynamic> set50 = <dynamic>{...notSpreadFunction};

  Map<dynamic, dynamic> map50 = <dynamic, dynamic>{...notSpreadFunction};

  List<String> lhs60 = <String>[...spread];

  Set<String> set60 = <String>{...spread};

  Map<int, int> map60 = <int, int>{...mapSpread};

  Map<String, String> map61 = <String, String>{...mapSpread};

  List<int> lhs70 = <int>[...null];

  Set<int> set70 = <int>{...null};

  var /*@ type=Set<dynamic>* */ set71ambiguous = /*@ typeArgs=dynamic */
      {
    ...null,
    ... /*@ typeArgs=dynamic */
    []
  };

  Map<String, int> map70 = <String, int>{...null};

  List<int> lhs80 = <int>[...?null];

  Set<int> set80 = <int>{...?null};

  var /*@ type=Set<dynamic>* */ set81ambiguous = /*@ typeArgs=dynamic */
      {...?null, ... /*@ typeArgs=dynamic */ []};

  Map<String, int> map80 = <String, int>{...?null};

  var /*@ type=Map<String*, int*>* */ map90 = <String, int>{
    ... /*@ typeArgs=String*, int* */ bar()
  };

  List<int> list100 = <int>[...listNum];

  Map<num, int> map100 = <num, int>{...mapIntNum};

  List<int> list110 = <int>[...dynVar];

  Map<num, int> map110 = <num, int>{...dynVar};
}

main() {}
