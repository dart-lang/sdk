// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main(List<String> args) {
  // Hijinks to remove an analysis warning.
  dynamic local1;
  if (true) local1 = 'abcd';

  int local2 = 2;
  var longList = [1, "hello", 3, 5, 7, 11, 13, 14, 15, 16, 17, 18, 19, 20];
  var deepList = [
    new Bar(),
    [
      [
        [
          [
            [7]
          ]
        ],
        "end"
      ]
    ]
  ];

  print('hello from main');

  // throw a caught exception
  try {
    foo(local1.baz());
  } catch (e) {
    print('-----------------');
    print('caught $e');
    print('-----------------');
  }
  foo(local2);

  print(longList);
  print(deepList);
  print('exiting...');
}

void foo(int val) {
  print('val: ${val}');
}

class Bar extends FooBar {
  String field1 = "my string";
}

class FooBar {
  int field2 = 47;
}
