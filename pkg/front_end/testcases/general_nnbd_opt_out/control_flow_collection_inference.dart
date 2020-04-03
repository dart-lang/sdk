// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// Oracle is generic to test the inference in conditions of if-elements.
oracle<T>([T t]) => true;

testIfElement(dynamic dynVar, List<int> listInt, List<double> listDouble,
    Map<String, int> mapToInt, Map<String, double> mapToDouble) {
  var list10 = [if (oracle("foo")) 42];
  var set10 = {if (oracle("foo")) 42, null};
  var map10 = {if (oracle("foo")) "bar": 42, "baz": null};
  var list11 = [if (oracle("foo")) dynVar];
  var set11 = {if (oracle("foo")) dynVar, null};
  var map11 = {if (oracle("foo")) "bar": dynVar, "baz": null};
  var list12 = [if (oracle("foo")) [42]];
  var set12 = {if (oracle("foo")) [42], null};
  var map12 = {if (oracle("foo")) "bar": [42], "baz": null};
  var list20 = [if (oracle("foo")) ...[42]];
  var set20 = {if (oracle("foo")) ...[42], null};
  var map20 = {if (oracle("foo")) ...{"bar": 42}, "baz": null};
  var list21 = [if (oracle("foo")) ...[dynVar]];
  var set21 = {if (oracle("foo")) ...[dynVar], null};
  var map21 = {if (oracle("foo")) ...{"bar": dynVar}, "baz": null};
  var list22 = [if (oracle("foo")) ...[[42]]];
  var set22 = {if (oracle("foo")) ...[[42]], null};
  var map22 = {if (oracle("foo")) ...{"bar": [42]}, "baz": null};
  var list30 = [if (oracle("foo")) if (oracle()) ...[42]];
  var set30 = {if (oracle("foo")) if (oracle()) ...[42], null};
  var map30 = {if (oracle("foo")) if (oracle()) ...{"bar": 42}, "baz": null};
  var list31 = [if (oracle("foo")) if (oracle()) ...[dynVar]];
  var set31 = {if (oracle("foo")) if (oracle()) ...[dynVar], null};
  var map31 = {if (oracle("foo")) if (oracle()) ...{"bar": dynVar}, "baz": null};
  var list33 = [if (oracle("foo")) if (oracle()) ...[[42]]];
  var set33 = {if (oracle("foo")) if (oracle()) ...[[42]], null};
  var map33 = {if (oracle("foo")) if (oracle()) ...{"bar": [42]}, "baz": null};
  List<List<int>> list40 = [if (oracle("foo")) ...[[]]];
  Set<List<int>> set40 = {if (oracle("foo")) ...[[]], null};
  Map<String, List<int>> map40 = {if (oracle("foo")) ...{"bar", []}, "baz": null};
  List<List<int>> list41 = [if (oracle("foo")) ...{[]}];
  Set<List<int>> set41 = {if (oracle("foo")) ...{[]}, null};
  List<List<int>> list42 = [if (oracle("foo")) if (oracle()) ...[[]]];
  Set<List<int>> set42 = {if (oracle("foo")) if (oracle()) ...[[]], null};
  Map<String, List<int>> map42 = {if (oracle("foo")) if (oracle()) ...{"bar": []}, "baz": null};
  List<int> list50 = [if (oracle("foo")) ...[]];
  Set<int> set50 = {if (oracle("foo")) ...[], null};
  Map<String, int> map50 = {if (oracle("foo")) ...{}, "baz": null};
  List<int> list51 = [if (oracle("foo")) ...{}];
  Set<int> set51 = {if (oracle("foo")) ...{}, null};
  List<int> list52 = [if (oracle("foo")) if (oracle()) ...[]];
  Set<int> set52 = {if (oracle("foo")) if (oracle()) ...[], null};
  Map<String, int> map52 = {if (oracle("foo")) if (oracle()) ...{}, "baz": null};
  List<List<int>> list60 = [if (oracle("foo")) ...[[]]];
  Set<List<int>> set60 = {if (oracle("foo")) ...[[]], null};
  Map<String, List<int>> map60 = {if (oracle("foo")) ...{"bar": []}, "baz": null};
  List<List<int>> list61 = [if (oracle("foo")) if (oracle()) ...[[]]];
  Set<List<int>> set61 = {if (oracle("foo")) if (oracle()) ...[[]], null};
  Map<String, List<int>> map61 = {if (oracle("foo")) if (oracle()) ...{"bar": []}, "baz": null};
  List<List<int>> list70 = [if (oracle("foo")) []];
  Set<List<int>> set70 = {if (oracle("foo")) [], null};
  List<List<int>> list71 = [if (oracle("foo")) if (oracle()) []];
  Set<List<int>> set71 = {if (oracle("foo")) if (oracle()) [], null};
  var list80 = [if (oracle("foo")) 42 else 3.14];
  var set80 = {if (oracle("foo")) 42 else 3.14, null};
  var map80 = {if (oracle("foo")) "bar": 42 else "bar": 3.14, "baz": null};
  var list81 = [if (oracle("foo")) ...listInt else ...listDouble];
  var set81 = {if (oracle("foo")) ...listInt else ...listDouble, null};
  var map81 = {if (oracle("foo")) ...mapToInt else ...mapToDouble, "baz": null};
  var list82 = [if (oracle("foo")) ...listInt else ...dynVar];
  var set82 = {if (oracle("foo")) ...listInt else ...dynVar, null};
  var map82 = {if (oracle("foo")) ...mapToInt else ...dynVar, null};
  var list83 = [if (oracle("foo")) 42 else ...listDouble];
  var set83 = {if (oracle("foo")) ...listInt else 3.14, null};
  var map83 = {if (oracle("foo")) ...mapToInt else "bar": 3.14, "baz": null};
  List<int> list90 = [if (oracle("foo")) dynVar];
  Set<int> set90 = {if (oracle("foo")) dynVar, null};
  Map<String, int> map90 = {if (oracle("foo")) "bar": dynVar, "baz": null};
  List<int> list91 = [if (oracle("foo")) ...dynVar];
  Set<int> set91 = {if (oracle("foo")) ...dynVar, null};
  Map<String, int> map91 = {if (oracle("foo")) ...dynVar, "baz": null};
  List<int> list100 = [if (dynVar) 42];
  Set<int> set100 = {if (dynVar) 42};
  Map<int, int> map100 = {if (dynVar) 42: 42};
}

testIfElementErrors(Map<int, int> map) {
  <int>[if (oracle("foo")) "bar"];
  <int>{if (oracle("foo")) "bar", null};
  <String, int>{if (oracle("foo")) "bar": "bar", "baz": null};
  <int>[if (oracle("foo")) ...["bar"]];
  <int>{if (oracle("foo")) ...["bar"], null};
  <String, int>{if (oracle("foo")) ...{"bar": "bar"}, "baz": null};
  <int>[if (oracle("foo")) ...map];
  <int>{if (oracle("foo")) ...map, null};
  <String, int>{if (oracle("foo")) ...["bar"], "baz": null};
  <String>[if (oracle("foo")) 42 else 3.14];
  <String>{if (oracle("foo")) 42 else 3.14, null};
  <String, String>{if (oracle("foo")) "bar": 42 else "baz": 3.14, "baz": null};
  <int>[if (oracle("foo")) ...map else 42];
  <int>{if (oracle("foo")) ...map else 42, null};
  <String, int>{if (oracle("foo")) ...[42] else "bar": 42, "baz": null};
  <int>[if (oracle("foo")) 42 else ...map];
  <int>{if (oracle("foo")) ...map else 42, null};
  <String, int>{if (oracle("foo")) "bar": 42 else ...[42], "baz": null};

  Set<dynamic> set10 = {if (oracle("foo")) 42 else "bar": 3.14};
  Map<dynamic, dynamic> map10 = {if (oracle("foo")) 42 else "bar": 3.14};
  Set<dynamic> set11 = {if (oracle("foo")) "bar": 3.14 else 42};
  Map<dynamic, dynamic> map11 = {if (oracle("foo")) "bar": 3.14 else 42};
  var map12 = {if (oracle("foo")) 42 else "bar": 3.14};
  var map13 = {if (oracle("foo")) "bar": 3.14 else 42};
  List<int> list20 = [if (42) 42];
  Set<int> set20 = {if (42) 42};
  Map<int, int> map30 = {if (42) 42: 42};
  List<String> list40 = <String>[if (oracle("foo")) true else 42];
  Set<String> set40 = <String>{if (oracle("foo")) true else 42};
  Map<String, int> map40 = <String, int>{if (oracle("foo")) true: 42 else 42: 42};
  Map<int, String> map41 = <int, String>{if (oracle("foo")) 42: true else 42: 42};
}

testForElement(dynamic dynVar, List<int> listInt, List<double> listDouble, int
    index, Map<String, int> mapStringInt, Map<String, double> mapStringDouble) {
  var list10 = [for (int i = 0; oracle("foo"); i++) 42];
  var set10 = {for (int i = 0; oracle("foo"); i++) 42, null};
  var map10 = {for (int i = 0; oracle("foo"); i++) "bar": 42, "baz": null};
  var list11 = [for (int i = 0; oracle("foo"); i++) dynVar];
  var set11 = {for (int i = 0; oracle("foo"); i++) dynVar, null};
  var map11 = {for (int i = 0; oracle("foo"); i++) "bar": dynVar, "baz": null};
  var list12 = [for (int i = 0; oracle("foo"); i++) [42]];
  var set12 = {for (int i = 0; oracle("foo"); i++) [42], null};
  var map12 = {for (int i = 0; oracle("foo"); i++) "bar": [42], "baz": null};
  var list20 = [for (int i = 0; oracle("foo"); i++) ...[42]];
  var set20 = {for (int i = 0; oracle("foo"); i++) ...[42], null};
  var map20 = {for (int i = 0; oracle("foo"); i++) ...{"bar": 42}, "baz": null};
  var list21 = [for (int i = 0; oracle("foo"); i++) ...[dynVar]];
  var set21 = {for (int i = 0; oracle("foo"); i++) ...[dynVar], null};
  var map21 = {for (int i = 0; oracle("foo"); i++) ...{"bar": dynVar}, "baz": null};
  var list22 = [for (int i = 0; oracle("foo"); i++) ...[[42]]];
  var set22 = {for (int i = 0; oracle("foo"); i++) ...[[42]], null};
  var map22 = {for (int i = 0; oracle("foo"); i++) ...{"bar": [42]}, "baz": null};
  var list30 = [for (int i = 0; oracle("foo"); i++) if (oracle()) ...[42]];
  var set30 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...[42], null};
  var map30 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...{"bar": 42}, "baz": null};
  var list31 = [for (int i = 0; oracle("foo"); i++) if (oracle()) ...[dynVar]];
  var set31 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...[dynVar], null};
  var map31 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...{"bar": dynVar}, "baz": null};
  var list33 = [for (int i = 0; oracle("foo"); i++) if (oracle()) ...[[42]]];
  var set33 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...[[42]], null};
  var map33 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...{"bar": [42]}, "baz": null};
  List<List<int>> list40 = [for (int i = 0; oracle("foo"); i++) ...[[]]];
  Set<List<int>> set40 = {for (int i = 0; oracle("foo"); i++) ...[[]], null};
  Map<String, List<int>> map40 = {for (int i = 0; oracle("foo"); i++) ...{"bar": []}, "baz": null};
  List<List<int>> list41 = [for (int i = 0; oracle("foo"); i++) ...{[]}];
  Set<List<int>> set41 = {for (int i = 0; oracle("foo"); i++) ...{[]}, null};
  List<List<int>> list42 = [for (int i = 0; oracle("foo"); i++) if (oracle()) ...[[]]];
  Set<List<int>> set42 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...[[]], null};
  Map<String, List<int>> map42 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...{"bar": []}, "baz": null};
  List<int> list50 = [for (int i = 0; oracle("foo"); i++) ...[]];
  Set<int> set50 = {for (int i = 0; oracle("foo"); i++) ...[], null};
  Map<String, int> map50 = {for (int i = 0; oracle("foo"); i++) ...{}, "baz": null};
  List<int> list51 = [for (int i = 0; oracle("foo"); i++) ...{}];
  Set<int> set51 = {for (int i = 0; oracle("foo"); i++) ...{}, null};
  List<int> list52 = [for (int i = 0; oracle("foo"); i++) if (oracle()) ...[]];
  Set<int> set52 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...[], null};
  List<List<int>> list60 = [for (int i = 0; oracle("foo"); i++) ...[[]]];
  Set<List<int>> set60 = {for (int i = 0; oracle("foo"); i++) ...[[]], null};
  Map<String, List<int>> map60 = {for (int i = 0; oracle("foo"); i++) ...{"bar": []}, "baz": null};
  List<List<int>> list61 = [for (int i = 0; oracle("foo"); i++) if (oracle()) ...[[]]];
  Set<List<int>> set61 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...[[]], null};
  Map<String, List<int>> map61 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...{"bar": []}, "baz": null};
  List<List<int>> list70 = [for (int i = 0; oracle("foo"); i++) []];
  Set<List<int>> set70 = {for (int i = 0; oracle("foo"); i++) [], null};
  Map<String, List<int>> map70 = {for (int i = 0; oracle("foo"); i++) "bar": [], "baz": null};
  List<List<int>> list71 = [for (int i = 0; oracle("foo"); i++) if (oracle()) []];
  Set<List<int>> set71 = {for (int i = 0; oracle("foo"); i++) if (oracle()) [], null};
  Map<String, List<int>> map71 = {for (int i = 0; oracle("foo"); i++) if (oracle()) "bar": [], "baz": null};
  var list80 = [for (int i = 0; oracle("foo"); i++) if (oracle()) 42 else 3.14];
  var set80 = {for (int i = 0; oracle("foo"); i++) if (oracle()) 42 else 3.14, null};
  var map80 = {for (int i = 0; oracle("foo"); i++) if (oracle()) "bar": 42 else "bar": 3.14, "baz": null};
  var list81 = [for (int i = 0; oracle("foo"); i++) if (oracle()) ...listInt else ...listDouble];
  var set81 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...listInt else ...listDouble, null};
  var map81 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...mapStringInt else ...mapStringDouble, "baz": null};
  var list82 = [for (int i = 0; oracle("foo"); i++) if (oracle()) ...listInt else ...dynVar];
  var set82 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...listInt else ...dynVar, null};
  var map82 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...mapStringInt else ...dynVar, "baz": null};
  var list83 = [for (int i = 0; oracle("foo"); i++) if (oracle()) 42 else ...listDouble];
  var set83 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...listInt else 3.14, null};
  var map83 = {for (int i = 0; oracle("foo"); i++) if (oracle()) ...mapStringInt else "bar": 3.14, "baz": null};
  List<int> list90 = [for (int i = 0; oracle("foo"); i++) dynVar];
  Set<int> set90 = {for (int i = 0; oracle("foo"); i++) dynVar, null};
  Map<String, int> map90 = {for (int i = 0; oracle("foo"); i++) "bar": dynVar, "baz": null};
  List<int> list91 = [for (int i = 0; oracle("foo"); i++) ...dynVar];
  Set<int> set91 = {for (int i = 0; oracle("foo"); i++) ...dynVar, null};
  Map<String, int> map91 = {for (int i = 0; oracle("foo"); i++) ...dynVar, "baz": null};
  List<int> list100 = <int>[for (index = 0; oracle("foo"); index++) 42];
  Set<int> set100 = <int>{for (index = 0; oracle("foo"); index++) 42};
  Map<String, int> map100 = <String, int>{for (index = 0; oracle("foo"); index++) "bar": 42};
  var list110 = [for (var i in [1, 2, 3]) i];
  var set110 = {for (var i in [1, 2, 3]) i, null};
  var map110 = {for (var i in [1, 2, 3]) "bar": i, "baz": null};
  List<int> list120 = [for (var i in dynVar) i];
  Set<int> set120 = {for (var i in dynVar) i, null};
  Map<String, int> map120 = {for (var i in dynVar) "bar": i, "baz": null};
  List<int> list130 = [for (var i = 1; i < 2; i++) i];
  Set<int> set130 = {for (var i = 1; i < 2; i++) i};
  Map<int, int> map130 = {for (var i = 1; i < 2; i++) i: i};
}

testForElementErrors(Map<int, int> map, List<int> list) async {
  <int>[for (int i = 0; oracle("foo"); i++) "bar"];
  <int>{for (int i = 0; oracle("foo"); i++) "bar", null};
  <int, int>{for (int i = 0; oracle("foo"); i++) "bar": "bar", "baz": null};
  <int>[for (int i = 0; oracle("foo"); i++) ...["bar"]];
  <int>{for (int i = 0; oracle("foo"); i++) ...["bar"], null};
  <int, int>{for (int i = 0; oracle("foo"); i++) ...{"bar": "bar"}, "baz": null};
  <int>[for (int i = 0; oracle("foo"); i++) ...map];
  <int>{for (int i = 0; oracle("foo"); i++) ...map, null};
  <int, int>{for (int i = 0; oracle("foo"); i++) ...list, 42: null};
  <String>[for (int i = 0; oracle("foo"); i++) if (oracle()) 42 else 3.14];
  <String>{for (int i = 0; oracle("foo"); i++) if (oracle()) 42 else 3.14, null};
  <String, String>{for (int i = 0; oracle("foo"); i++) if (oracle()) "bar": 42 else "bar": 3.14, "baz": null};
  <int>[for (int i = 0; oracle("foo"); i++) if (oracle()) ...map else 42];
  <int>{for (int i = 0; oracle("foo"); i++) if (oracle()) ...map else 42, null};
  <String, int>{for (int i = 0; oracle("foo"); i++) if (oracle()) ...list else "bar": 42, "baz": null};
  <int>[for (int i = 0; oracle("foo"); i++) if (oracle()) 42 else ...map];
  <int>{for (int i = 0; oracle("foo"); i++) if (oracle()) 42 else ...map, null};
  <String, int>{for (int i = 0; oracle("foo"); i++) if (oracle()) "bar": 42 else ...list, "baz": null};

  final i = 0;
  <int>[for (i in <int>[1]) i];
  <int>{for (i in <int>[1]) i, null};
	<String, int>{for (i in <int>[1]) "bar": i, "baz": null};

  var list10 = [for (var i in "not iterable") i];
  var set10 = {for (var i in "not iterable") i, null};
  var map10 = {for (var i in "not iterable") "bar": i, "baz": null};
  var list20 = [for (int i in ["not", "int"]) i];
  var set20 = {for (int i in ["not", "int"]) i, null};
  var map20 = {for (int i in ["not", "int"]) "bar": i, "baz": null};
  var list30 = [await for (var i in "not stream") i];
  var set30 = {await for (var i in "not stream") i, null};
  var map30 = {await for (var i in "not stream") "bar": i, "baz": null};
  var list40 = [await for (int i in Stream.fromIterable(["not", "int"])) i];
  var set40 = {await for (int i in Stream.fromIterable(["not", "int"])) i, null};
  var map40 = {await for (int i in Stream.fromIterable(["not", "int"])) "bar": i, "baz": null};
  var list50 = [await for (;;) 42];
  var set50 = {await for (;;) 42, null};
  var map50 = {await for (;;) "bar": 42, "baz": null};
  var list60 = [for (; "not bool";) 42];
  var set60 = {for (; "not bool";) 42, null};
  var map60 = {for (; "not bool";) "bar": 42, "baz": null};
}

testForElementErrorsNotAsync(Stream<int> stream) {
  <int>[await for (int i in stream) i];
  <int>{await for (int i in stream) i};
  <String, int>{await for (int i in stream) "bar": i};
}

class A {}

class B extends A {
  int get foo => 42;
}

testPromotion(A a) {
  List<int> list10 = [if (a is B) a.foo];
  Set<int> set10 = {if (a is B) a.foo};
  Map<int, int> map10 = {if (a is B) a.foo: a.foo};
}

main() {}
