// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const generatorConfigDefaultJson = <String, dynamic>{'a': 1};

void helper(Map<String, dynamic> input) {
  print(input);
}

void main() {
  final nullValueMap = Map.fromEntries(
      generatorConfigDefaultJson.entries.map((e) => MapEntry(e.key, null)));
  helper(nullValueMap);
}
