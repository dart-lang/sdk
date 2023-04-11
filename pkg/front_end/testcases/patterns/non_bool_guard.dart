// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String test1(List<int> v) {
  switch (v) {
    case [var a, _] when a - 1:
      return "match";
    default:
      return "no match";
  }
}

String test2(List<int> v) {
  if (v case [var a, _] when a - 1) {
    return "match";
  }
  return "no match";
}

String test3(List<int> v) =>
  switch (v) {
    [var a, _] when a - 1 => "match",
    _ => "no match"
  };
