// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `is` tests against some interface types are compiled to `instanceof` tests.

/*member: isRecord:function(o) {
  return o instanceof A._Record;
}*/
isRecord(o) => o is Record;

/*member: isRegExp:function(o) {
  return o instanceof A.JSSyntaxRegExp;
}*/
isRegExp(o) => o is RegExp;

/*member: isString:function(o) {
  return typeof o == "string";
}*/
isString(o) => o is String;

/*member: isType:function(o) {
  return o instanceof A._Type;
}*/
isType(o) => o is Type;

/*member: main:ignore*/
main() {
  final items = [
    1,
    'x',
    true,
    Object(),
    main,
    Type,
    (1, 2),
    (1, 2, 3),
    StringBuffer(),
    RegExp('a'),
    [1],
  ];

  for (final item in items) {
    for (final test in [isRecord, isRegExp, isString, isType]) {
      print(test(item));
    }
  }
}
