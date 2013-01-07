// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Short string.
var s = "0123456789";
// Long string.
var l = "$s$s$s$s$s$s$s$s$s$s";
// Very long string.
var v = "$l$l$l$l$l$l$l$l$l$l";


testSliceSuccess() {
  // Test different ways to get the same slice from a string.
  testSlice(String string, int start, int end) {
    int length = string.length;
    String expect = string.substring(start, end);
    Expect.equals(expect, string.slice(start, end), "#${length}[$start:$end]");
    if (start < length) {
      // If start == length, there is no negative representation of the position.
      Expect.equals(expect, string.slice(start - length, end),
                    "#${length}[${start - length}:$end]");
    }
    if (end < length) {
      Expect.equals(expect, string.slice(start, end - length),
                    "#${length}[$start:${end - length}]");
      Expect.equals(expect, string.slice(start - length, end - length),
                    "#${length}[${start-length}:${end-length}]");
    } else {
      Expect.equals(expect, string.slice(start),
                    "#${length}[$start]");
      if (start < length) {
        Expect.equals(expect, string.slice(start - length),
                      "#${length}[${start-length}]");
        if (start == 0) {
          Expect.equals(string, string.slice(), "#$length[:]");
        }
      }
    }
  }

  testSliceCombinations(String string) {
    int length = string.length;
    List<int> positions = [0, 1, string.length >> 1, length - 1, length];
    for (int i = 0; i < positions.length; i++) {
      for (int j = i; j < positions.length; j++) {
        testSlice(string, positions[i], positions[j]);
      }
    }
  }

  testSliceCombinations(s);
  testSliceCombinations(l);
  testSliceCombinations(v);
}

testSliceError() {
  function expectRangeError(void thunk()) {
    Expect.throws(thunk, (e) => e is RangeError);
  };
  function expectArgumentError(void thunk()) {
    Expect.throws(thunk, (e) => e is ArgumentError);
  };
  function badType(void thunk()) {
    bool checkedMode = false;
    assert(checkedMode = true);
    Expect.throws(thunk,
                  (e) => checkedMode ? e is TypeError : e is ArgumentError);
  }

  // Invalid start:
  expectRangeError(() => s.slice(11));
  expectRangeError(() => s.slice(-11));
  // Invalid end:
  expectRangeError(() => s.slice(0, 11));
  expectRangeError(() => s.slice(0, -11));
  // Non-int:
  badType(() => s.slice(1.5));
  badType(() => s.slice(0, 1.5));
  badType(() => s.slice("1"));
  badType(() => s.slice(0, "1"));
  // Bad order:
  expectArgumentError(() => s.slice(5, 4));
  expectArgumentError(() => s.slice(-5, 4));
  expectArgumentError(() => s.slice(5, -6));
  expectArgumentError(() => s.slice(-5, -6));
}


main() {
  testSliceSuccess();
  testSliceError();
}
