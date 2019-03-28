// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_tests;

import 'package:expect/expect.dart';
import 'package:quiver/collection.dart';
import 'dart:convert';

main() {
  testListJsonable();
  testListNotToJsonable();
  testMapJsonable();
  testMapNotToJsonable();
}

class ListJsonable extends DelegatingList implements ToJsonable {
  final delegate = [4,5,6];
  @override
  String toJson() {
    return '"Custom return ListJsonable"';
  }
}

void testListJsonable() {
  var encoded = json.encode([
    ListJsonable(),
    {"2": ListJsonable()}
  ]);
  Expect.equals(
      '["Custom return ListJsonable",{"2":"Custom return ListJsonable"}]',
      encoded);
}

class ListNotToJsonable extends DelegatingList {
  final delegate = [4,5,6];
  @override
  String toJson() {
    return '"Custom return ListNotToJsonable"';
  }
}

void testListNotToJsonable() {
  var encoded = json.encode([
    ListNotToJsonable(),
    {"2": ListNotToJsonable()}
  ]);
  Expect.equals('[[4,5,6],{"2":[4,5,6]}]', encoded);
}

class MapJsonable extends DelegatingMap implements ToJsonable {
  final delegate = {'a': 'b'};
  @override
  String toJson() {
    return '"Custom return MapJsonable"';
  }
}

void testMapJsonable() {
  var encoded = json.encode([
    MapJsonable(),
    {"2": MapJsonable()}
  ]);
  Expect.equals('["Custom return MapJsonable",{"2":"Custom return MapJsonable"}]', encoded);
}

class MapNotToJsonable extends DelegatingMap {
  final delegate = {'a': 'b'};
  @override
  String toJson() {
    return '"Custom return MapNotToJsonable"';
  }
}

void testMapNotToJsonable() {
  var encoded = json.encode([
    MapNotToJsonable(),
    {"2": MapNotToJsonable()}
  ]);
  Expect.equals('[{"a":"b"},{"2":{"a":"b"}}]', encoded);
}
