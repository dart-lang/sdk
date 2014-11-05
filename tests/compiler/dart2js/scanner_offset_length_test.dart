// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'package:compiler/src/scanner/scannerlib.dart';

Token scan(String text) =>
    new StringScanner.fromString(text, includeComments: true).tokenize();

check(String text) {
  Token token = scan(text);
  while (token.kind != EOF_TOKEN) {
    Expect.equals(token.value.length, token.charCount);

    var start = token.charOffset;
    var end = token.charOffset + token.charCount;

    Expect.isTrue(start < text.length,
        'start=$start < text.length=${text.length}: $text');

    Expect.isTrue(end <= text.length,
        'end=$end <= text.length=${text.length}: $text');

    Expect.isTrue(start <= end, 'start=$end <= end=$end: $text');

    var substring = text.substring(start, end);

    Expect.stringEquals(token.value, substring,
        'token.value=${token.value} == '
        'text.substring(start,end)=${substring}: $text');

    print('$text: [$start,$end]:$token');

    token = token.next;
  }
}

main() {
    check('foo'); // identifier
    check('\'\''); // empty string
    check('\'foo\''); // simple string
    check('\'\$foo\''); // interpolation, identifier
    check('\'\${foo}\''); // interpolation, expression

    check('//'); // single line comment
    check('/**/'); // multi line comment
}
