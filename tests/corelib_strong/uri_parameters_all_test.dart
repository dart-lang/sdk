// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';

main() {
  testAll(["a", "b", "c"]);
  testAll([""]);
  testAll(["a"]);
  testAll(["", ""]);
  testAll(["baz"]);

  testParse("z&y&w&z", {
    "z": ["", ""],
    "y": [""],
    "w": [""]
  });
  testParse("x=42&y=42&x=37&y=37", {
    "x": ["42", "37"],
    "y": ["42", "37"]
  });
  testParse("x&x&x&x&x", {
    "x": ["", "", "", "", ""]
  });
  testParse("x=&&y", {
    "x": [""],
    "y": [""]
  });
}

testAll(List values) {
  var uri =
      new Uri(scheme: "foo", path: "bar", queryParameters: {"baz": values});
  var list = uri.queryParametersAll["baz"];
  Expect.listEquals(values, list);
}

testParse(query, results) {
  var uri = new Uri(scheme: "foo", path: "bar", query: query);
  var params = uri.queryParametersAll;
  for (var k in results.keys) {
    Expect.listEquals(results[k], params[k]);
  }
  uri = new Uri(scheme: "foo", path: "bar", queryParameters: results);
  params = uri.queryParametersAll;
  for (var k in results.keys) {
    Expect.listEquals(results[k], params[k]);
  }
}
