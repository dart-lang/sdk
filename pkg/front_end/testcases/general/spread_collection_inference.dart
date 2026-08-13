// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test case checks that inference works for spread collections, and that
// the errors are reported when necessary.

Map<K, V> bar<K, V>() => throw '';

foo(dynamic dynVar) {
  List<int> spread = <int>[1, 2, 3];
  Map<String, int> mapSpread = <String, int>{"foo": 4, "bar": 2};
  int notSpreadInt = 42;
  int Function()? notSpreadFunction = null;
  // Note that all values are actually ints.
  Map<int, num> mapIntNum = <int, num>{42: 42};
  List<num> listNum = <num>[42];

  var lhs10 = [...[]];

  var set10 = <dynamic>{...[]};

  var map10 = <dynamic, dynamic>{...{}};

  var map10ambiguous = {...{}};

  var lhs20 = [...spread];

  var set20 = {...spread, 42};

  var set20ambiguous = {...spread};

  var map20 = {...mapSpread, "baz": 42};

  var map20ambiguous = {...mapSpread};

  var lhs21 = [...(spread as dynamic)];

  var set21 = {...(spread as dynamic), 42};

  var map21 = {...(mapSpread as dynamic), "baz": 42};

  dynamic map21ambiguous = {...(mapSpread as dynamic)};

  List<int> lhs22 = [...[]];

  Set<int> set22 = {...[], 42};

  Set<int> set22ambiguous = {...[]};

  Map<String, int> map22 = {...{}};

  List<List<int>> lhs23 = [
    ...[[]],
  ];

  Set<List<int>> set23 = {
    ...[[]],
    <int>[42],
  };

  Set<List<int>> set23ambiguous = {
    ...[[]],
  };

  Map<String, List<int>> map23 = {
    ...{"baz": []},
  };

  dynamic map24ambiguous = {...spread, ...mapSpread};

  int lhs30 = [...spread];

  int set30 = {...spread, 42};

  int set30ambiguous = {...spread};

  int map30 = {...mapSpread, "baz": 42};

  int map30ambiguous = {...mapSpread};

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

  var set71ambiguous = {...null, ...[]};

  Map<String, int> map70 = <String, int>{...null};

  List<int> lhs80 = <int>[...?null];

  Set<int> set80 = <int>{...?null};

  var set81ambiguous = {...?null, ...[]};

  Map<String, int> map80 = <String, int>{...?null};

  var map90 = <String, int>{...bar()};

  List<int> list100 = <int>[...listNum];

  Map<num, int> map100 = <num, int>{...mapIntNum};

  List<int> list110 = <int>[...dynVar];

  Map<num, int> map110 = <num, int>{...dynVar};
}

main() {}
