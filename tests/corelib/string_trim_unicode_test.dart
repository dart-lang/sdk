// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Range {
  final int from;
  final int to;
  const Range(this.from, this.to);
}

class StringTrimTest {
  static testMain() {
    var spaces = [
        const Range(9, 13),  // Control characters, not in the Zs category.
        const Range(32, 32),
        const Range(0xa0, 0xa0),
        const Range(0x1680, 0x1680),
        const Range(0x180e, 0x180e),
        const Range(0x2000, 0x200a),
        // LINE SEPARATOR, category Zl and PARAGRAPH SEPARATOR, category Zp.
        const Range(0x2028, 0x2029),
        const Range(0x202f, 0x202f),
        const Range(0x205f, 0x205f),
        const Range(0x3000, 0x3000),
        const Range(0xfeff, 0xfeff)];  // Unicode BOM.
    for (int range in spaces) {
      for (int i = range.from - 1; i <= range.to + 1; i++) {
        print("Check $i");
        if (i >= range.from && i <= range.to) {
          Expect.equals(
              new String.fromCharCodes([i, 'f'.charCodeAt(0), i]).trim(), 'f');
        } else {
          Expect.isFalse('f' ==
              new String.fromCharCodes([i, 'f'.charCodeAt(0), i]).trim());
        }
      }
    }
    // 0x85 NEL Next line is not in the Unicode Zs category and it not special
    // cased in the ES5 spec either.
    Expect.isFalse('f' ==
        new String.fromCharCodes([0x85, 'f'.charCodeAt(0), 0x85]).trim());
  }
}

main() {
  StringTrimTest.testMain();
}
