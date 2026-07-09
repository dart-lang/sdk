// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  shru1(1, 1);
  shru1(2, 2);
  shru1(-1, -1);

  shruOtherInferredPositive(1, 1);
  shruOtherInferredPositive(99, 99);
  shruOtherInferredPositive(-1, 2);

  shruSix(1);
  shruSix(-1);

  shruMaskedCount(1, 1);
  shruMaskedCount(999, 999);
  shruMaskedCount(-1, -2);

  shruMaskedCount2(1, 1);
  shruMaskedCount2(999, 999);
  shruMaskedCount2(-1, -2);
}

@pragma('dart2js:noInline')
shru1(a, b) {
  return a >>> b;
}

@pragma('dart2js:noInline')
/*member: shruOtherInferredPositive:Specializer=[ShiftRightUnsigned._shruOtherPositive]*/
shruOtherInferredPositive(a, b) {
  return a >>> b;
}

@pragma('dart2js:noInline')
/*member: shruSix:Specializer=[ShiftRightUnsigned]*/
shruSix(int a) {
  return a >>> 6;
}

@pragma('dart2js:noInline')
/*member: shruMaskedCount:Specializer=[BitAnd,ShiftRightUnsigned]*/
shruMaskedCount(int a, int b) {
  return a >>> (b & 31);
}

@pragma('dart2js:noInline')
/*member: shruMaskedCount2:Specializer=[BitAnd,ShiftRightUnsigned._shruOtherPositive]*/
shruMaskedCount2(int a, int b) {
  return a >>> (b & 127);
}
