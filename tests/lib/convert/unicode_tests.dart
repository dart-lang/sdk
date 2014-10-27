// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unicode_tests;

// Google favorite: "Îñţérñåţîöñåļîžåţîờñ".
const INTER_BYTES = const [0xc3, 0x8e, 0xc3, 0xb1, 0xc5, 0xa3, 0xc3, 0xa9, 0x72,
                           0xc3, 0xb1, 0xc3, 0xa5, 0xc5, 0xa3, 0xc3, 0xae, 0xc3,
                           0xb6, 0xc3, 0xb1, 0xc3, 0xa5, 0xc4, 0xbc, 0xc3, 0xae,
                           0xc5, 0xbe, 0xc3, 0xa5, 0xc5, 0xa3, 0xc3, 0xae, 0xe1,
                           0xbb, 0x9d, 0xc3, 0xb1];
const INTER_STRING = "Îñţérñåţîöñåļîžåţîờñ";

// Blueberry porridge in Danish: "blåbærgrød".
const BLUEBERRY_BYTES = const [0x62, 0x6c, 0xc3, 0xa5, 0x62, 0xc3, 0xa6, 0x72,
                               0x67, 0x72, 0xc3, 0xb8, 0x64];
const BLUEBERRY_STRING = "blåbærgrød";

// "சிவா அணாமாைல", that is "Siva Annamalai" in Tamil.
const SIVA_BYTES1 = const [0xe0, 0xae, 0x9a, 0xe0, 0xae, 0xbf, 0xe0, 0xae, 0xb5,
                           0xe0, 0xae, 0xbe, 0x20, 0xe0, 0xae, 0x85, 0xe0, 0xae,
                           0xa3, 0xe0, 0xae, 0xbe, 0xe0, 0xae, 0xae, 0xe0, 0xae,
                           0xbe, 0xe0, 0xaf, 0x88, 0xe0, 0xae, 0xb2];
const SIVA_STRING1 = "சிவா அணாமாைல";

// "िसवा अणामालै", that is "Siva Annamalai" in Devanagari.
const SIVA_BYTES2 = const [0xe0, 0xa4, 0xbf, 0xe0, 0xa4, 0xb8, 0xe0, 0xa4, 0xb5,
                           0xe0, 0xa4, 0xbe, 0x20, 0xe0, 0xa4, 0x85, 0xe0, 0xa4,
                           0xa3, 0xe0, 0xa4, 0xbe, 0xe0, 0xa4, 0xae, 0xe0, 0xa4,
                           0xbe, 0xe0, 0xa4, 0xb2, 0xe0, 0xa5, 0x88];
const SIVA_STRING2 = "िसवा अणामालै";

// DESERET CAPITAL LETTER BEE, unicode 0x10412(0xD801+0xDC12)
// UTF-8: F0 90 90 92
const BEE_BYTES = const [0xf0, 0x90, 0x90, 0x92];
const BEE_STRING = "𐐒";

const DIGIT_BYTES = const [ 0x35 ];
const DIGIT_STRING = "5";

const ASCII_BYTES = const [ 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
                            0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x70,
                            0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
                            0x79, 0x7A ];
const ASCII_STRING = "abcdefghijklmnopqrstuvwxyz";

const BIGGEST_ASCII_BYTES = const [ 0x7F ];
const BIGGEST_ASCII_STRING = "\x7F";

const SMALLEST_2_UTF8_UNIT_BYTES = const [ 0xC2, 0x80 ];
const SMALLEST_2_UTF8_UNIT_STRING = "\u{80}";

const BIGGEST_2_UTF8_UNIT_BYTES = const [ 0xDF, 0xBF ];
const BIGGEST_2_UTF8_UNIT_STRING = "\u{7FF}";

const SMALLEST_3_UTF8_UNIT_BYTES = const [ 0xE0, 0xA0, 0x80 ];
const SMALLEST_3_UTF8_UNIT_STRING = "\u{800}";

const BIGGEST_3_UTF8_UNIT_BYTES = const [ 0xEF, 0xBF, 0xBF ];
const BIGGEST_3_UTF8_UNIT_STRING = "\u{FFFF}";

const SMALLEST_4_UTF8_UNIT_BYTES = const [ 0xF0, 0x90, 0x80, 0x80 ];
const SMALLEST_4_UTF8_UNIT_STRING = "\u{10000}";

const BIGGEST_4_UTF8_UNIT_BYTES = const [ 0xF4, 0x8F, 0xBF, 0xBF ];
const BIGGEST_4_UTF8_UNIT_STRING = "\u{10FFFF}";

const _TEST_PAIRS = const [
    const [ const [], "" ],
    const [ INTER_BYTES, INTER_STRING ],
    const [ BLUEBERRY_BYTES, BLUEBERRY_STRING ],
    const [ SIVA_BYTES1, SIVA_STRING1 ],
    const [ SIVA_BYTES2, SIVA_STRING2 ],
    const [ BEE_BYTES, BEE_STRING ],
    const [ DIGIT_BYTES, DIGIT_STRING ],
    const [ ASCII_BYTES, ASCII_STRING ],
    const [ BIGGEST_ASCII_BYTES, BIGGEST_ASCII_STRING ],
    const [ SMALLEST_2_UTF8_UNIT_BYTES, SMALLEST_2_UTF8_UNIT_STRING ],
    const [ BIGGEST_2_UTF8_UNIT_BYTES, BIGGEST_2_UTF8_UNIT_STRING ],
    const [ SMALLEST_3_UTF8_UNIT_BYTES, SMALLEST_3_UTF8_UNIT_STRING ],
    const [ BIGGEST_3_UTF8_UNIT_BYTES, BIGGEST_3_UTF8_UNIT_STRING ],
    const [ SMALLEST_4_UTF8_UNIT_BYTES, SMALLEST_4_UTF8_UNIT_STRING ],
    const [ BIGGEST_4_UTF8_UNIT_BYTES, BIGGEST_4_UTF8_UNIT_STRING ],
    ];

List<List> _expandTestPairs() {
  assert(2 == BEE_STRING.length);
  var tests = [];
  tests.addAll(_TEST_PAIRS);
  tests.addAll(_TEST_PAIRS.map((test) {
    var bytes = test[0];
    var string = test[1];
    var longBytes = [];
    var longString = "";
    for (int i = 0; i < 100; i++) {
      longBytes.addAll(bytes);
      longString += string;
    }
    return [longBytes, longString];
  }));
  return tests;
}

final List UNICODE_TESTS = _expandTestPairs();
