// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main(List<String> args) {
  Set<String> fooSet = {
    ...args,
    "hello",
    ...{"x": "y"}.keys,
    for (String s in args) ...{
      "$s",
      "${s}_2",
    },
    if (args.length == 42) ...{
      "length",
      "is",
      "42",
    },
  };
  print(fooSet);

  Set<String> fooSet2 = {
    ...args,
    ...{"x": "y"}.keys,
    for (String s in args) ...{
      "$s",
      "${s}_2",
    },
    if (args.length == 42) ...{
      "length",
      "is",
      "42",
    },
  };
  print(fooSet2);

  List<String> fooList = [
    ...args,
    "hello",
    ...{"x": "y"}.keys,
    for (String s in args) ...[
      "$s",
      "${s}_2",
    ],
    if (args.length == 42) ...[
      "length",
      "is",
      "42",
    ],
  ];
  print(fooList);

  Map<String, String> fooMap = {
    "hello": "world",
    for (String s in args) ...{
      "$s": "${s}_2",
    },
    if (args.length == 42) ...{
      "length": "42",
      "is": "42",
      "42": "!",
    },
  };
  print(fooMap);
}
