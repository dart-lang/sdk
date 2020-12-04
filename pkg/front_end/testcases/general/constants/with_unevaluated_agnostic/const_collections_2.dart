// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const List<String> listWithUnevaluatedUnevaluatedFirst = [
  String.fromEnvironment("foo"),
  String.fromEnvironment("bar"),
  "hello",
  "world"
];

const List<String> listWithUnevaluatedUnevaluatedMiddle = [
  "A",
  "few",
  "strings",
  String.fromEnvironment("foo"),
  String.fromEnvironment("bar"),
  "hello",
  "world",
  "and",
  "more"
];

const Set<String> setWithUnevaluatedUnevaluatedFirst = {
  // only one or the empty string (when evaluated with an empty environment)
  // will conflict!
  String.fromEnvironment("foo"),
  "hello",
  "world"
};

const Set<String> setWithUnevaluatedUnevaluatedMiddle = {
  "A",
  "few",
  "strings",
  // only one or the empty string (when evaluated with an empty environment)
  // will conflict!
  String.fromEnvironment("foo"),
  "hello",
  "world",
  "and",
  "more"
};

const Map<String, int> mapWithUnevaluatedUnevaluatedFirst = {
  // only one or the empty string (when evaluated with an empty environment)
  // will conflict!
  String.fromEnvironment("foo"): 42,
  "hello": 42,
  "world": 42
};

const Map<String, int> mapWithUnevaluatedUnevaluatedMiddle = {
  "A": 42,
  "few": 42,
  "strings": 42,
  // only one or the empty string (when evaluated with an empty environment)
  // will conflict!
  String.fromEnvironment("foo"): 42,
  "hello": 42,
  "world": 42,
  "and": 42,
  "more": 42
};
