// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  List<int>? list = null;
  print(<int>[1, 2, ...?list, 3]);
  print(<int>[1, 2, ...?null, 3]);
  var list1 = [...?list];
  var list2 = [...?null];
  var list3 = [1, 2, ...?list, 3];
  var list4 = [1, 2, ...?null, 3];

  Set<int>? set = null;
  print(<int>{1, 2, ...?set, 3});
  print(<int>{1, 2, ...?null, 3});
  var set1 = {...?set};
  var set3 = {1, 2, ...?set, 3};
  var set4 = {1, 2, ...?null, 3};

  Map<int, int>? map = null;
  print(<int, int>{1: 1, 2: 2, ...?map, 3: 3});
  print(<int, int>{1: 1, 2: 2, ...?null, 3: 3});
  var map1 = {...?map};
  var map3 = {1: 1, 2: 2, ...?map, 3: 3};
  var map4 = {1: 1, 2: 2, ...?null, 3: 3};
}
