// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var i = 1;

Map<int, String>? nullableMap = {1: "Let", 2: "it", 3: "be"};

List<int>? nullableList = [1, 2, 3];

dynamic dynamicMap = {1: "Let", 2: "it", 3: "be"};

dynamic dynamicList = [1, 2, 3];

var map1 = {
  if (i > 0) ...nullableMap, // error
  if (i > 0) ...dynamicMap, // ok
  if (i > 0) ...nullableMap!, // ok
};

var set1 = {
  0,
  if (i > 0) ...nullableList, // error
  if (i > 0) ...dynamicList, // ok
  if (i > 0) ...nullableList! // ok
};

var list1 = [
  if (i > 0) ...nullableList, // error
  if (i > 0) ...dynamicList, // ok
  if (i > 0) ...nullableList!, // ok
];

testMap<X extends dynamic, Y extends Map<int, String>?,
    Z extends Map<int, String>>(X x, Y y, Z z) {
  var map2 = {
    if (i > 0) ...x, // error
    if (i > 0) ...y, // error
    if (i > 0) ...z, // ok
    if (i > 0) ...y!, // ok
  };
}

testIterables<X extends dynamic, Y extends List<int>?, Z extends List<int>>(
    X x, Y y, Z z) {
  var set2 = {
    0,
    if (i > 0) ...x, // error
    if (i > 0) ...y, // error
    if (i > 0) ...z, // ok
  };
  var list2 = [
    if (i > 0) ...x, // error
    if (i > 0) ...y, // error
    if (i > 0) ...z, // ok
  ];
}

main() {}
