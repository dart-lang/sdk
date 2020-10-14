// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const List<bool> listWithUnevaluated = [
  bool.fromEnvironment("foo"),
  bool.fromEnvironment("bar"),
  true,
];
const List<bool> listWithUnevaluatedSpread = [
  true,
  ...listWithUnevaluated,
  false
];

const Set<bool> setWithUnevaluated = {
  bool.fromEnvironment("foo"),
  bool.fromEnvironment("bar"),
  true,
};
const Set<bool> setWithUnevaluatedSpread = {true, ...setWithUnevaluated, false};

const a = <int>[];
const b = <int?>[];
const setNotAgnosticOK = {a, b};

const Map<bool> MapWithUnevaluated = {
  bool.fromEnvironment("foo"): bool.fromEnvironment("bar"),
};

const mapNotAgnosticOK = {a: 0, b: 1};

main() {
  print(listWithUnevaluated);
  print(listWithUnevaluatedSpread);
  print(setWithUnevaluated);
  print(setWithUnevaluatedSpread);
  print({"hello"});
  print(const {"hello"});
}
