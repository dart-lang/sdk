// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Oracle is generic to test the inference in conditions of if-elements.
oracle<T>([T t]) => true;

testIfElement(dynamic dynVar, List<int> listInt, List<double> listDouble) {
  var list10 = [if (oracle("foo")) 42];
  var set10 = {if (oracle("foo")) 42, null};
  var list11 = [if (oracle("foo")) dynVar];
  var set11 = {if (oracle("foo")) dynVar, null};
  var list12 = [if (oracle("foo")) [42]];
  var set12 = {if (oracle("foo")) [42], null};
  var list20 = [if (oracle("foo")) ...[42]];
  var set20 = {if (oracle("foo")) ...[42], null};
  var list21 = [if (oracle("foo")) ...[dynVar]];
  var set21 = {if (oracle("foo")) ...[dynVar], null};
  var list22 = [if (oracle("foo")) ...[[42]]];
  var set22 = {if (oracle("foo")) ...[[42]], null};
  var list30 = [if (oracle("foo")) if (oracle()) ...[42]];
  var set30 = {if (oracle("foo")) if (oracle()) ...[42], null};
  var list31 = [if (oracle("foo")) if (oracle()) ...[dynVar]];
  var set31 = {if (oracle("foo")) if (oracle()) ...[dynVar], null};
  var list33 = [if (oracle("foo")) if (oracle()) ...[[42]]];
  var set33 = {if (oracle("foo")) if (oracle()) ...[[42]], null};
  List<List<int>> list40 = [if (oracle("foo")) ...[[]]];
  Set<List<int>> set40 = {if (oracle("foo")) ...[[]], null};
  List<List<int>> list41 = [if (oracle("foo")) ...{[]}];
  Set<List<int>> set41 = {if (oracle("foo")) ...{[]}, null};
  List<List<int>> list42 = [if (oracle("foo")) if (oracle()) ...[[]]];
  Set<List<int>> set42 = {if (oracle("foo")) if (oracle()) ...[[]], null};
  List<int> list50 = [if (oracle("foo")) ...[]];
  Set<int> set50 = {if (oracle("foo")) ...[], null};
  List<int> list51 = [if (oracle("foo")) ...{}];
  Set<int> set51 = {if (oracle("foo")) ...{}, null};
  List<int> list52 = [if (oracle("foo")) if (oracle()) ...[]];
  Set<int> set52 = {if (oracle("foo")) if (oracle()) ...[], null};
  List<List<int>> list60 = [if (oracle("foo")) ...[[]]];
  Set<List<int>> set60 = {if (oracle("foo")) ...[[]], null};
  List<List<int>> list61 = [if (oracle("foo")) if (oracle()) ...[[]]];
  Set<List<int>> set61 = {if (oracle("foo")) if (oracle()) ...[[]], null};
  List<List<int>> list70 = [if (oracle("foo")) []];
  Set<List<int>> set70 = {if (oracle("foo")) [], null};
  List<List<int>> list71 = [if (oracle("foo")) if (oracle()) []];
  Set<List<int>> set71 = {if (oracle("foo")) if (oracle()) [], null};
  var list80 = [if (oracle("foo")) 42 else 3.14];
  var set80 = {if (oracle("foo")) 42 else 3.14, null};
  var list81 = [if (oracle("foo")) ...listInt else ...listDouble];
  var set81 = {if (oracle("foo")) ...listInt else ...listDouble, null};
  var list82 = [if (oracle("foo")) ...listInt else ...dynVar];
  var set82 = {if (oracle("foo")) ...listInt else ...dynVar, null};
  var list83 = [if (oracle("foo")) 42 else ...listDouble];
  var set83 = {if (oracle("foo")) ...listInt else 3.14, null};
  List<int> list90 = [if (oracle("foo")) dynVar];
  Set<int> set90 = {if (oracle("foo")) dynVar, null};
  List<int> list91 = [if (oracle("foo")) ...dynVar];
  Set<int> set91 = {if (oracle("foo")) ...dynVar, null};
}

testIfElementErrors(Map<int, int> map) {
  <int>[if (oracle("foo")) "bar"];
  <int>{if (oracle("foo")) "bar", null};
  <int>[if (oracle("foo")) ...["bar"]];
  <int>{if (oracle("foo")) ...["bar"], null};
  <int>[if (oracle("foo")) ...map];
  <int>{if (oracle("foo")) ...map, null};
  <String>[if (oracle("foo")) 42 else 3.14];
  <String>{if (oracle("foo")) 42 else 3.14, null};
  <int>[if (oracle("foo")) ...map else 42];
  <int>{if (oracle("foo")) ...map else 42, null};
  <int>[if (oracle("foo")) 42 else ...map];
  <int>{if (oracle("foo")) ...map else 42, null};
}

main() {}
