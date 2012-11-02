// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:utf';
import '../../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart';
import '../../../sdk/lib/_internal/compiler/implementation/scanner/scanner_implementation.dart';
import '../../../sdk/lib/_internal/compiler/implementation/util/characters.dart';
part '../../../sdk/lib/_internal/compiler/implementation/scanner/byte_strings.dart';
part '../../../sdk/lib/_internal/compiler/implementation/scanner/byte_array_scanner.dart';

Token scan(List<int> bytes) => new ByteArrayScanner(bytes).tokenize();

bool isRunningOnJavaScript() => 1 === 1.0;

main() {
  // Google favorite: "Îñţérñåţîöñåļîžåţîờñ".
  Token token = scan([0xc3, 0x8e, 0xc3, 0xb1, 0xc5, 0xa3, 0xc3, 0xa9, 0x72,
                      0xc3, 0xb1, 0xc3, 0xa5, 0xc5, 0xa3, 0xc3, 0xae, 0xc3,
                      0xb6, 0xc3, 0xb1, 0xc3, 0xa5, 0xc4, 0xbc, 0xc3, 0xae,
                      0xc5, 0xbe, 0xc3, 0xa5, 0xc5, 0xa3, 0xc3, 0xae, 0xe1,
                      0xbb, 0x9d, 0xc3, 0xb1, $EOF]);
  Expect.stringEquals("Îñţérñåţîöñåļîžåţîờñ", token.value.slowToString());

  // Blueberry porridge in Danish: "blåbærgrød".
  token = scan([0x62, 0x6c, 0xc3, 0xa5, 0x62, 0xc3, 0xa6, 0x72, 0x67, 0x72,
                0xc3, 0xb8, 0x64, $EOF]);
  Expect.stringEquals("blåbærgrød", token.value.slowToString());

  // "சிவா அணாமாைல", that is "Siva Annamalai" in Tamil.
  token = scan([0xe0, 0xae, 0x9a, 0xe0, 0xae, 0xbf, 0xe0, 0xae, 0xb5, 0xe0,
                0xae, 0xbe, 0x20, 0xe0, 0xae, 0x85, 0xe0, 0xae, 0xa3, 0xe0,
                0xae, 0xbe, 0xe0, 0xae, 0xae, 0xe0, 0xae, 0xbe, 0xe0, 0xaf,
                0x88, 0xe0, 0xae, 0xb2, $EOF]);
  Expect.stringEquals("சிவா", token.value.slowToString());
  Expect.stringEquals("அணாமாைல", token.next.value.slowToString());

  // "िसवा अणामालै", that is "Siva Annamalai" in Devanagari.
  token = scan([0xe0, 0xa4, 0xbf, 0xe0, 0xa4, 0xb8, 0xe0, 0xa4, 0xb5, 0xe0,
                0xa4, 0xbe, 0x20, 0xe0, 0xa4, 0x85, 0xe0, 0xa4, 0xa3, 0xe0,
                0xa4, 0xbe, 0xe0, 0xa4, 0xae, 0xe0, 0xa4, 0xbe, 0xe0, 0xa4,
                0xb2, 0xe0, 0xa5, 0x88, $EOF]);
  Expect.stringEquals("िसवा", token.value.slowToString());
  Expect.stringEquals("अणामालै", token.next.value.slowToString());

  if (!isRunningOnJavaScript()) {
    // DESERET CAPITAL LETTER BEE, unicode 0x10412(0xD801+0xDC12)
    // UTF-8: F0 90 90 92
    token = scan([0xf0, 0x90, 0x90, 0x92, $EOF]);
    Expect.stringEquals("𐐒", token.value.slowToString());
  } else {
    print('Skipping non-BMP character test');
  }

  // Regression test for issue 1761.
  // "#!"
  token = scan([0x23, 0x21, $EOF]);
  Expect.equals(token.info, EOF_INFO); // Treated as a comment.

  // Regression test for issue 1761.
  // "#! Hello, World!"
  token = scan([0x23, 0x21, 0x20, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20,
                0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21, $EOF]);
  Expect.equals(token.info, EOF_INFO); // Treated as a comment.
}
