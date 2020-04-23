// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

void main() {
  const BitNot(42, 4294967253).check();
  const BitNot(4294967253, 42).check();
  const BitNot(-42, 41).check();
  const BitNot(-1, 0).check();
  const BitNot(0, 0xFFFFFFFF).check();
  const BitNot(4294967295, 0).check();
  const BitNot(0x12121212121212, 0xEDEDEDED).check();
  const BitNot(0x7fffffff00000000, 0xffffffff).check();
  const BitNot(0x8000000000000000, 0xffffffff).check();

  const Negate(0, -0).check();
  const Negate(-0, 0).check();
  const Negate(0.0, -0.0).check();
  const Negate(-0.0, 0.0).check();
  const Negate(-0.0, 0).check();
  const Negate(-0, 0.0).check();
  const Negate(0, -0.0).check();
  const Negate(0.0, -0).check();
  const Negate(1, -1).check();
  const Negate(-1, 1).check();
  const Negate(1.0, -1.0).check();
  const Negate(-1.0, 1.0).check();
  const Negate(3.14, -3.14).check();
  const Negate(-3.14, 3.14).check();
  const Negate(4294967295, -4294967295).check();
  const Negate(-4294967295, 4294967295).check();
  const Negate(4294967295.5, -4294967295.5).check();
  const Negate(-4294967295.5, 4294967295.5).check();
  const Negate(4294967296, -4294967296).check();
  const Negate(-4294967296, 4294967296).check();
  const Negate(4294967296.5, -4294967296.5).check();
  const Negate(-4294967296.5, 4294967296.5).check();
  const Negate(9007199254740991, -9007199254740991).check();
  const Negate(-9007199254740991, 9007199254740991).check();
  const Negate(9007199254740991.5, -9007199254740991.5).check();
  const Negate(-9007199254740991.5, 9007199254740991.5).check();
  const Negate(9007199254740992, -9007199254740992).check();
  const Negate(-9007199254740992, 9007199254740992).check();
  const Negate(9007199254740992.5, -9007199254740992.5).check();
  const Negate(-9007199254740992.5, 9007199254740992.5).check();
  const Negate(double.infinity, double.negativeInfinity).check();
  const Negate(double.negativeInfinity, double.infinity).check();
  const Negate(double.maxFinite, -double.maxFinite).check();
  const Negate(-double.maxFinite, double.maxFinite).check();
  const Negate(double.minPositive, -double.minPositive).check();
  const Negate(-double.minPositive, double.minPositive).check();
  const Negate(double.nan, double.nan).check();
  const Negate(0x7fffffff00000000, -0x7fffffff00000000).check();
  const Negate(-0x7fffffff00000000, 0x7fffffff00000000).check();
  const Negate(0x8000000000000000, -0x8000000000000000).check();
  const Negate(-0x8000000000000000, 0x8000000000000000).check();

  const Not(true, false).check();
  const Not(false, true).check();

  const BitAnd(314159, 271828, 262404).check();
  const BitAnd(271828, 314159, 262404).check();
  const BitAnd(0, 0, 0).check();
  const BitAnd(-1, 0, 0).check();
  const BitAnd(-1, 314159, 314159).check();
  const BitAnd(-1, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitAnd(0xff, -4, 0xfc).check();
  const BitAnd(0, 0xFFFFFFFF, 0).check();
  const BitAnd(0xFFFFFFFF, 0, 0).check();
  const BitAnd(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitAnd(0x123456789ABC, 0xEEEEEEEEEEEE, 0x46688AAC).check();
  const BitAnd(0x7fffffff00008000, 0x8000000000008000, 0x8000).check();
  const BitAnd(0x8000000000008000, 0x7fffffff00008000, 0x8000).check();
  const BitAnd(true, true, true).check();
  const BitAnd(true, false, false).check();
  const BitAnd(false, true, false).check();
  const BitAnd(false, false, false).check();

  const BitOr(314159, 271828, 323583).check();
  const BitOr(271828, 314159, 323583).check();
  const BitOr(0, 0, 0).check();
  const BitOr(-8, 0, 0xFFFFFFF8).check();
  const BitOr(-8, 271828, 0xFFFFFFFC).check();
  const BitOr(-8, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitOr(0x1, -4, 0xFFFFFFFD).check();
  const BitOr(0, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitOr(0xFFFFFFFF, 0, 0xFFFFFFFF).check();
  const BitOr(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitOr(0x123456789ABC, 0x111111111111, 0x57799BBD).check();
  const BitOr(0x7000000080000000, 0x8000000000008000, 0x80008000).check();
  const BitOr(0x8000000000008000, 0x7000000080000000, 0x80008000).check();
  const BitOr(true, true, true).check();
  const BitOr(true, false, true).check();
  const BitOr(false, true, true).check();
  const BitOr(false, false, false).check();

  const BitXor(314159, 271828, 61179).check();
  const BitXor(271828, 314159, 61179).check();
  const BitXor(0, 0, 0).check();
  const BitXor(-1, 0, 0xFFFFFFFF).check();
  const BitXor(-256, 1, 0xFFFFFF01).check();
  const BitXor(-256, -255, 1).check();
  const BitXor(0, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitXor(0xFFFFFFFF, 0, 0xFFFFFFFF).check();
  const BitXor(0xFFFFFFFF, 0xFFFFFFFF, 0).check();
  const BitXor(0x123456789ABC, 0x111111111111, 0x47698BAD).check();
  const BitXor(0x7000000012340000, 0x8000000011110000, 0x03250000).check();
  const BitXor(0x8000000011110000, 0x7000000012340000, 0x03250000).check();
  const BitXor(true, true, false).check();
  const BitXor(true, false, true).check();
  const BitXor(false, true, true).check();
  const BitXor(false, false, false).check();

  const ShiftLeft(42, 0, 42).check();
  const ShiftLeft(42, 5, 1344).check();
  const ShiftLeft(1, 31, 0x80000000).check();
  const ShiftLeft(1, 32, 0).check();
  const ShiftLeft(1, 100, 0).check();
  const ShiftLeft(0, 0, 0).check();
  const ShiftLeft(0, 5, 0).check();
  const ShiftLeft(0, 31, 0).check();
  const ShiftLeft(0, 32, 0).check();
  const ShiftLeft(0, 100, 0).check();
  const ShiftLeft(-1, 0, 0xFFFFFFFF).check();
  const ShiftLeft(-1, 5, 0xFFFFFFE0).check();
  const ShiftLeft(-1, 31, 0x80000000).check();
  const ShiftLeft(-1, 32, 0).check();
  const ShiftLeft(-1, 100, 0).check();
  const ShiftLeft(0x7000000000008000, 0, 0x8000).check();
  const ShiftLeft(0x7000000000008000, 1, 0x10000).check();
  const ShiftLeft(0x7000000000008000, 16, 0x80000000).check();
  const ShiftLeft(0x7000000000008000, 17, 0x0).check();
  const ShiftLeft(0x8000000000008000, 0, 0x8000).check();
  const ShiftLeft(0x8000000000008000, 1, 0x10000).check();
  const ShiftLeft(0x8000000000008000, 16, 0x80000000).check();
  const ShiftLeft(0x8000000000008000, 17, 0x0).check();

  const ShiftRight(8675309, 0, 8675309).check();
  const ShiftRight(8675309, 5, 271103).check();
  const ShiftRight(0xFEDCBA98, 0, 0xFEDCBA98).check();
  const ShiftRight(0xFEDCBA98, 5, 0x07F6E5D4).check();
  const ShiftRight(0xFEDCBA98, 31, 1).check();
  const ShiftRight(0xFEDCBA98, 32, 0).check();
  const ShiftRight(0xFEDCBA98, 100, 0).check();
  const ShiftRight(0xFFFFFEDCBA98, 0, 0xFEDCBA98).check();
  const ShiftRight(0xFFFFFEDCBA98, 5, 0x07F6E5D4).check();
  const ShiftRight(0xFFFFFEDCBA98, 31, 1).check();
  const ShiftRight(0xFFFFFEDCBA98, 32, 0).check();
  const ShiftRight(0xFFFFFEDCBA98, 100, 0).check();
  const ShiftRight(-1, 0, 0xFFFFFFFF).check();
  const ShiftRight(-1, 5, 0xFFFFFFFF).check();
  const ShiftRight(-1, 31, 0xFFFFFFFF).check();
  const ShiftRight(-1, 32, 0xFFFFFFFF).check();
  const ShiftRight(-1, 100, 0xFFFFFFFF).check();
  const ShiftRight(-1073741824, 0, 0xC0000000).check();
  const ShiftRight(-1073741824, 5, 0xFE000000).check();
  const ShiftRight(-1073741824, 31, 0xFFFFFFFF).check();
  const ShiftRight(-1073741824, 32, 0xFFFFFFFF).check();
  const ShiftRight(-1073741824, 100, 0xFFFFFFFF).check();
  const ShiftRight(0x7000000000008000, 0, 0x8000).check();
  const ShiftRight(0x7000000000008000, 1, 0x4000).check();
  const ShiftRight(0x7000000000008000, 15, 0x1).check();
  const ShiftRight(0x7000000000008000, 16, 0).check();
  const ShiftRight(0x8000000000008000, 0, 0x8000).check();
  const ShiftRight(0x8000000000008000, 1, 0x4000).check();
  const ShiftRight(0x8000000000008000, 15, 0x1).check();
  const ShiftRight(0x8000000000008000, 16, 0).check();

  const BooleanAnd(true, true, true).check();
  const BooleanAnd(true, false, false).check();
  const BooleanAnd(false, true, false).check();
  const BooleanAnd(false, false, false).check();
  const BooleanAnd(false, null, false).check();

  const BooleanOr(true, true, true).check();
  const BooleanOr(true, false, true).check();
  const BooleanOr(false, true, true).check();
  const BooleanOr(false, false, false).check();
  const BooleanOr(true, null, true).check();

  const Subtract(314159, 271828, 42331).check();
  const Subtract(271828, 314159, -42331).check();
  const Subtract(0, 0, 0).check();
  const Subtract(0, 42, -42).check();
  const Subtract(0, -42, 42).check();
  const Subtract(42, 0, 42).check();
  const Subtract(42, 42, 0).check();
  const Subtract(42, -42, 84).check();
  const Subtract(-42, 0, -42).check();
  const Subtract(-42, 42, -84).check();
  const Subtract(-42, -42, 0).check();
  const Subtract(4294967295, -1, 4294967296).check();
  const Subtract(4294967296, -1, 4294967297).check();
  const Subtract(9007199254740991, -1, 9007199254740992).check();
  const Subtract(9007199254740992, -1, 9007199254740992).check();
  const Subtract(9007199254740992, -100, 9007199254741092).check();
  const Subtract(-4294967295, 1, -4294967296).check();
  const Subtract(-4294967296, 1, -4294967297).check();
  const Subtract(-9007199254740991, 1, -9007199254740992).check();
  const Subtract(-9007199254740992, 1, -9007199254740992).check();
  const Subtract(-9007199254740992, 100, -9007199254741092).check();
  const Subtract(
          0x7fffffff00000000, -0x7fffffff00000000, 2 * 0x7fffffff00000000)
      .check();
  const Subtract(4.2, 1.5, 2.7).check();
  const Subtract(1.5, 4.2, -2.7).check();
  const Subtract(1.5, 0, 1.5).check();
  const Subtract(0, 1.5, -1.5).check();
  const Subtract(1.5, 1.5, 0.0).check();
  const Subtract(-1.5, -1.5, 0.0).check();
  const Subtract(0.0, 0.0, 0.0).check();
  const Subtract(0.0, -0.0, 0.0).check();
  const Subtract(-0.0, 0.0, -0.0).check();
  const Subtract(-0.0, -0.0, 0.0).check();
  const Subtract(double.maxFinite, -double.maxFinite, double.infinity).check();
  const Subtract(-double.maxFinite, double.maxFinite, double.negativeInfinity)
      .check();
  const Subtract(1.5, double.nan, double.nan).check();
  const Subtract(double.nan, 1.5, double.nan).check();
  const Subtract(double.nan, double.nan, double.nan).check();
  const Subtract(double.nan, double.infinity, double.nan).check();
  const Subtract(double.nan, double.negativeInfinity, double.nan).check();
  const Subtract(double.infinity, double.nan, double.nan).check();
  const Subtract(double.negativeInfinity, double.nan, double.nan).check();
  const Subtract(double.infinity, double.maxFinite, double.infinity).check();
  const Subtract(double.infinity, -double.maxFinite, double.infinity).check();
  const Subtract(
          double.negativeInfinity, double.maxFinite, double.negativeInfinity)
      .check();
  const Subtract(
          double.negativeInfinity, -double.maxFinite, double.negativeInfinity)
      .check();
  const Subtract(1.5, double.infinity, double.negativeInfinity).check();
  const Subtract(1.5, double.negativeInfinity, double.infinity).check();
  const Subtract(double.infinity, double.infinity, double.nan).check();
  const Subtract(double.infinity, double.negativeInfinity, double.infinity)
      .check();
  const Subtract(
          double.negativeInfinity, double.infinity, double.negativeInfinity)
      .check();
  const Subtract(double.negativeInfinity, double.negativeInfinity, double.nan)
      .check();
  const Subtract(double.minPositive, double.minPositive, 0.0).check();
  const Subtract(-double.minPositive, -double.minPositive, 0.0).check();

  const Multiply(6, 7, 42).check();
  const Multiply(-6, 7, -42).check();
  const Multiply(6, -7, -42).check();
  const Multiply(-6, -7, 42).check();
  const Multiply(0, 0, 0).check();
  const Multiply(0, 7, 0).check();
  const Multiply(6, 0, 0).check();
  const Multiply(65536, 65536, 4294967296).check();
  const Multiply(4294967296, -1, -4294967296).check();
  const Multiply(-1, 4294967296, -4294967296).check();
  const Multiply(134217728, 134217728, 18014398509481984).check();
  const Multiply(18014398509481984, -1, -18014398509481984).check();
  const Multiply(-1, 18014398509481984, -18014398509481984).check();
  const Multiply(9000000000000000, 9000000000000000, 8.1e31).check();
  const Multiply(0x7fff000000000000, 0x8000000000000000, 8.506799558180535e37)
      .check();
  const Multiply(0x8000000000000000, 1.2, 11068046444225730000.0).check();
  const Multiply(3.14, 2.72, 8.5408).check();
  const Multiply(-3.14, 2.72, -8.5408).check();
  const Multiply(3.14, -2.72, -8.5408).check();
  const Multiply(-3.14, -2.72, 8.5408).check();
  const Multiply(3.14, 0, 0.0).check();
  const Multiply(0, 2.72, 0.0).check();
  const Multiply(0.0, 0.0, 0.0).check();
  const Multiply(0.0, -0.0, -0.0).check();
  const Multiply(-0.0, 0.0, -0.0).check();
  const Multiply(-0.0, -0.0, 0.0).check();
  const Multiply(double.maxFinite, double.maxFinite, double.infinity).check();
  const Multiply(double.maxFinite, -double.maxFinite, double.negativeInfinity)
      .check();
  const Multiply(-double.maxFinite, double.maxFinite, double.negativeInfinity)
      .check();
  const Multiply(-double.maxFinite, -double.maxFinite, double.infinity).check();
  const Multiply(0, double.nan, double.nan).check();
  const Multiply(double.nan, 0, double.nan).check();
  const Multiply(double.nan, double.nan, double.nan).check();
  const Multiply(0, double.infinity, double.nan).check();
  const Multiply(double.infinity, 0, double.nan).check();
  const Multiply(0, double.negativeInfinity, double.nan).check();
  const Multiply(double.negativeInfinity, 0, double.nan).check();
  const Multiply(-0.0, double.infinity, double.nan).check();
  const Multiply(double.infinity, -0.0, double.nan).check();
  const Multiply(-0.0, double.negativeInfinity, double.nan).check();
  const Multiply(double.negativeInfinity, -0.0, double.nan).check();
  const Multiply(double.infinity, double.infinity, double.infinity).check();
  const Multiply(
          double.infinity, double.negativeInfinity, double.negativeInfinity)
      .check();
  const Multiply(
          double.negativeInfinity, double.infinity, double.negativeInfinity)
      .check();
  const Multiply(
          double.negativeInfinity, double.negativeInfinity, double.infinity)
      .check();
  const Multiply(double.minPositive, 0.5, 0.0).check();
  const Multiply(double.minPositive, -0.5, -0.0).check();
  const Multiply(-double.minPositive, 0.5, -0.0).check();
  const Multiply(-double.minPositive, -0.5, 0.0).check();
  const Multiply(1e-300, -1e-300, -0.0).check();
  const Multiply(double.minPositive, double.infinity, double.infinity).check();
  const Multiply(
          double.minPositive, double.negativeInfinity, double.negativeInfinity)
      .check();
  const Multiply(double.minPositive, double.maxFinite, 8.881784197001251e-16)
      .check();

  const Modulo(27, 314159, 27).check();
  const Modulo(27, 1, 0).check();
  const Modulo(27, -1, 0).check();
  const Modulo(-27, 1, 0).check();
  const Modulo(-27, -1, 0).check();
  const Modulo(314159, 27, 14).check();
  const Modulo(314159, -27, 14).check();
  const Modulo(-314159, 27, 13).check();
  const Modulo(-314159, -27, 13).check();
  const Modulo(4294967295, 4294967296, 4294967295).check();
  const Modulo(4294967295, -4294967296, 4294967295).check();
  const Modulo(-4294967295, 4294967296, 1).check();
  const Modulo(-4294967295, -4294967296, 1).check();
  const Modulo(9007199254740991, 9007199254740992, 9007199254740991).check();
  const Modulo(9007199254740991, -9007199254740992, 9007199254740991).check();
  const Modulo(-9007199254740991, 9007199254740992, 1).check();
  const Modulo(-9007199254740991, -9007199254740992, 1).check();
  const Modulo(2.71828, 3.14159, 2.71828).check();
  const Modulo(2.71828, 1, 0.71828).check();
  const Modulo(2.71828, -1, 0.71828).check();
  const Modulo(-2.71828, 1, 0.28171999999999997).check();
  const Modulo(-2.71828, -1, 0.28171999999999997).check();
  const Modulo(27.1828, 3.14159, 2.0500800000000012).check();
  const Modulo(27.1828, -3.14159, 2.0500800000000012).check();
  const Modulo(-27.1828, 3.14159, 1.0915099999999986).check();
  const Modulo(-27.1828, -3.14159, 1.0915099999999986).check();
  const Modulo(42, double.nan, double.nan).check();
  const Modulo(double.nan, 42, double.nan).check();
  const Modulo(0, double.nan, double.nan).check();
  const Modulo(double.nan, double.nan, double.nan).check();
  const Modulo(double.infinity, double.nan, double.nan).check();
  const Modulo(double.nan, double.infinity, double.nan).check();
  const Modulo(0.0, double.infinity, 0).check();
  const Modulo(-0.0, double.infinity, 0).check();
  const Modulo(0.0, double.negativeInfinity, 0).check();
  const Modulo(-0.0, double.negativeInfinity, 0).check();
  const Modulo(42, double.infinity, 42).check();
  const Modulo(-42, double.infinity, double.infinity).check();
  const Modulo(42, double.negativeInfinity, 42).check();
  const Modulo(-42, double.negativeInfinity, double.infinity).check();
  const Modulo(double.infinity, 42, double.nan).check();
  const Modulo(double.infinity, -42, double.nan).check();
  const Modulo(double.negativeInfinity, 42, double.nan).check();
  const Modulo(double.negativeInfinity, -42, double.nan).check();
  const Modulo(double.infinity, double.infinity, double.nan).check();
  const Modulo(double.negativeInfinity, double.infinity, double.nan).check();
  const Modulo(double.infinity, double.negativeInfinity, double.nan).check();
  const Modulo(double.negativeInfinity, double.negativeInfinity, double.nan)
      .check();

  const TruncatingDivide(27, 314159, 0).check();
  const TruncatingDivide(27, 1, 27).check();
  const TruncatingDivide(27, -1, -27).check();
  const TruncatingDivide(-27, 1, -27).check();
  const TruncatingDivide(-27, -1, 27).check();
  const TruncatingDivide(314159, 27, 11635).check();
  const TruncatingDivide(314159, -27, -11635).check();
  const TruncatingDivide(-314159, 27, -11635).check();
  const TruncatingDivide(-314159, -27, 11635).check();
  const TruncatingDivide(4294967295, 4294967296, 0).check();
  const TruncatingDivide(4294967295, -4294967296, 0).check();
  const TruncatingDivide(-4294967295, 4294967296, 0).check();
  const TruncatingDivide(-4294967295, -4294967296, 0).check();
  const TruncatingDivide(9007199254740991, 9007199254740992, 0).check();
  const TruncatingDivide(9007199254740991, -9007199254740992, 0).check();
  const TruncatingDivide(-9007199254740991, 9007199254740992, 0).check();
  const TruncatingDivide(-9007199254740991, -9007199254740992, 0).check();
  const TruncatingDivide(4294967295, 0.5, 8589934590).check();
  const TruncatingDivide(4294967295, -0.5, -8589934590).check();
  const TruncatingDivide(-4294967295, 0.5, -8589934590).check();
  const TruncatingDivide(-4294967295, -0.5, 8589934590).check();
  const TruncatingDivide(9007199254740991, 0.5, 18014398509481982).check();
  const TruncatingDivide(9007199254740991, -0.5, -18014398509481982).check();
  const TruncatingDivide(-9007199254740991, 0.5, -18014398509481982).check();
  const TruncatingDivide(-9007199254740991, -0.5, 18014398509481982).check();
  const TruncatingDivide(0x8000000000000000, -1, -0x8000000000000000).check();
  const TruncatingDivide(0x6000000000000000, 0.5, 0xC000000000000000).check();
  const TruncatingDivide(2.71828, 3.14159, 0).check();
  const TruncatingDivide(2.71828, 1, 2).check();
  const TruncatingDivide(2.71828, -1, -2).check();
  const TruncatingDivide(-2.71828, 1, -2).check();
  const TruncatingDivide(-2.71828, -1, 2).check();
  const TruncatingDivide(27.1828, 3.14159, 8).check();
  const TruncatingDivide(27.1828, -3.14159, -8).check();
  const TruncatingDivide(-27.1828, 3.14159, -8).check();
  const TruncatingDivide(-27.1828, -3.14159, 8).check();
  const TruncatingDivide(0.0, double.infinity, 0).check();
  const TruncatingDivide(-0.0, double.infinity, 0).check();
  const TruncatingDivide(0.0, double.negativeInfinity, 0).check();
  const TruncatingDivide(-0.0, double.negativeInfinity, 0).check();
  const TruncatingDivide(42, double.infinity, 0).check();
  const TruncatingDivide(-42, double.infinity, 0).check();
  const TruncatingDivide(42, double.negativeInfinity, 0).check();
  const TruncatingDivide(-42, double.negativeInfinity, 0).check();

  const Divide(27, 3, 9).check();
  const Divide(27, 1, 27).check();
  const Divide(27, -1, -27).check();
  const Divide(-27, 1, -27).check();
  const Divide(-27, -1, 27).check();
  const Divide(0, 1, 0).check();
  const Divide(0, -1, -0.0).check();
  const Divide(-0.0, 1, -0.0).check();
  const Divide(-0.0, -1, 0).check();
  const Divide(314159, 27, 11635.518518518518).check();
  const Divide(314159, -27, -11635.518518518518).check();
  const Divide(-314159, 27, -11635.518518518518).check();
  const Divide(-314159, -27, 11635.518518518518).check();
  const Divide(4294967295, 4294967296, 0.9999999997671694).check();
  const Divide(4294967295, -4294967296, -0.9999999997671694).check();
  const Divide(-4294967295, 4294967296, -0.9999999997671694).check();
  const Divide(-4294967295, -4294967296, 0.9999999997671694).check();
  const Divide(9007199254740991, 9007199254740992, 0.9999999999999999).check();
  const Divide(9007199254740991, -9007199254740992, -0.9999999999999999)
      .check();
  const Divide(-9007199254740991, 9007199254740992, -0.9999999999999999)
      .check();
  const Divide(-9007199254740991, -9007199254740992, 0.9999999999999999)
      .check();
  const Divide(4294967296, 4294967295, 1.0000000002328306).check();
  const Divide(4294967296, -4294967295, -1.0000000002328306).check();
  const Divide(-4294967296, 4294967295, -1.0000000002328306).check();
  const Divide(-4294967296, -4294967295, 1.0000000002328306).check();
  const Divide(9007199254740992, 9007199254740991, 1.0000000000000002).check();
  const Divide(9007199254740992, -9007199254740991, -1.0000000000000002)
      .check();
  const Divide(-9007199254740992, 9007199254740991, -1.0000000000000002)
      .check();
  const Divide(-9007199254740992, -9007199254740991, 1.0000000000000002)
      .check();
  const Divide(4294967295, 0.5, 8589934590).check();
  const Divide(4294967295, -0.5, -8589934590).check();
  const Divide(-4294967295, 0.5, -8589934590).check();
  const Divide(-4294967295, -0.5, 8589934590).check();
  const Divide(9007199254740991, 0.5, 18014398509481982).check();
  const Divide(9007199254740991, -0.5, -18014398509481982).check();
  const Divide(-9007199254740991, 0.5, -18014398509481982).check();
  const Divide(-9007199254740991, -0.5, 18014398509481982).check();
  const Divide(2.71828, 3.14159, 0.8652561282662601).check();
  const Divide(2.71828, 1, 2.71828).check();
  const Divide(2.71828, -1, -2.71828).check();
  const Divide(-2.71828, 1, -2.71828).check();
  const Divide(-2.71828, -1, 2.71828).check();
  const Divide(27.1828, 3.14159, 8.652561282662601).check();
  const Divide(27.1828, -3.14159, -8.652561282662601).check();
  const Divide(-27.1828, 3.14159, -8.652561282662601).check();
  const Divide(-27.1828, -3.14159, 8.652561282662601).check();
  const Divide(1, 0, double.infinity).check();
  const Divide(1, -0.0, double.negativeInfinity).check();
  const Divide(-1, 0, double.negativeInfinity).check();
  const Divide(-1, -0.0, double.infinity).check();
  const Divide(0, 0, double.nan).check();
  const Divide(0, -0.0, double.nan).check();
  const Divide(-0.0, 0, double.nan).check();
  const Divide(-0.0, -0.0, double.nan).check();
  const Divide(double.infinity, 0, double.infinity).check();
  const Divide(double.infinity, -0.0, double.negativeInfinity).check();
  const Divide(double.negativeInfinity, 0, double.negativeInfinity).check();
  const Divide(double.negativeInfinity, -0.0, double.infinity).check();
  const Divide(double.nan, 0, double.nan).check();
  const Divide(double.nan, -0.0, double.nan).check();
  const Divide(double.nan, 1, double.nan).check();
  const Divide(1, double.nan, double.nan).check();
  const Divide(0, double.nan, double.nan).check();
  const Divide(double.nan, double.nan, double.nan).check();
  const Divide(double.nan, double.infinity, double.nan).check();
  const Divide(double.infinity, double.nan, double.nan).check();
  const Divide(double.negativeInfinity, double.nan, double.nan).check();
  const Divide(double.infinity, 1, double.infinity).check();
  const Divide(double.infinity, -1, double.negativeInfinity).check();
  const Divide(double.negativeInfinity, 1, double.negativeInfinity).check();
  const Divide(double.negativeInfinity, -1, double.infinity).check();
  const Divide(0, double.infinity, 0).check();
  const Divide(0, double.negativeInfinity, -0.0).check();
  const Divide(-0.0, double.infinity, -0.0).check();
  const Divide(-0.0, double.negativeInfinity, 0).check();
  const Divide(1, double.infinity, 0).check();
  const Divide(1, double.negativeInfinity, -0.0).check();
  const Divide(-1, double.infinity, -0.0).check();
  const Divide(-1, double.negativeInfinity, 0).check();
  const Divide(double.infinity, double.infinity, double.nan).check();
  const Divide(double.minPositive, double.maxFinite, 0).check();
  const Divide(double.minPositive, -double.maxFinite, -0.0).check();
  const Divide(-double.minPositive, double.maxFinite, -0.0).check();
  const Divide(-double.minPositive, -double.maxFinite, 0).check();
  const Divide(double.maxFinite, double.minPositive, double.infinity).check();
  const Divide(double.maxFinite, -double.minPositive, double.negativeInfinity)
      .check();
  const Divide(-double.maxFinite, double.minPositive, double.negativeInfinity)
      .check();
  const Divide(-double.maxFinite, -double.minPositive, double.infinity).check();

  const Add("", "", "").check();
  const Add("foo", "", "foo").check();
  const Add("", "bar", "bar").check();
  const Add("foo", "bar", "foobar").check();
  const Add(314159, 271828, 585987).check();
  const Add(314159, -271828, 42331).check();
  const Add(-314159, 271828, -42331).check();
  const Add(-314159, -271828, -585987).check();
  const Add(0, 0, 0).check();
  const Add(0, 42, 42).check();
  const Add(0, -42, -42).check();
  const Add(42, 0, 42).check();
  const Add(42, 42, 84).check();
  const Add(42, -42, 0).check();
  const Add(-42, 0, -42).check();
  const Add(-42, 42, 0).check();
  const Add(-42, -42, -84).check();
  const Add(4294967295, 1, 4294967296).check();
  const Add(4294967296, 1, 4294967297).check();
  const Add(9007199254740991, 1, 9007199254740992).check();
  const Add(9007199254740992, 1, 9007199254740992).check();
  const Add(9007199254740992, 100, 9007199254741092).check();
  const Add(-4294967295, -1, -4294967296).check();
  const Add(-4294967296, -1, -4294967297).check();
  const Add(-9007199254740991, -1, -9007199254740992).check();
  const Add(-9007199254740992, -1, -9007199254740992).check();
  const Add(-9007199254740992, -100, -9007199254741092).check();
  const Add(4.2, 1.5, 5.7).check();
  const Add(4.2, -1.5, 2.7).check();
  const Add(-4.2, 1.5, -2.7).check();
  const Add(-4.2, -1.5, -5.7).check();
  const Add(1.5, 0, 1.5).check();
  const Add(0, 1.5, 1.5).check();
  const Add(1.5, -1.5, 0.0).check();
  const Add(-1.5, 1.5, 0.0).check();
  const Add(0.0, 0.0, 0.0).check();
  const Add(0.0, -0.0, 0.0).check();
  const Add(-0.0, 0.0, 0.0).check();
  const Add(-0.0, -0.0, -0.0).check();
  const Add(double.maxFinite, double.maxFinite, double.infinity).check();
  const Add(-double.maxFinite, -double.maxFinite, double.negativeInfinity)
      .check();
  const Add(1.5, double.nan, double.nan).check();
  const Add(double.nan, 1.5, double.nan).check();
  const Add(double.nan, double.nan, double.nan).check();
  const Add(double.nan, double.infinity, double.nan).check();
  const Add(double.nan, double.negativeInfinity, double.nan).check();
  const Add(double.infinity, double.nan, double.nan).check();
  const Add(double.negativeInfinity, double.nan, double.nan).check();
  const Add(double.infinity, -double.maxFinite, double.infinity).check();
  const Add(double.infinity, double.maxFinite, double.infinity).check();
  const Add(double.negativeInfinity, -double.maxFinite, double.negativeInfinity)
      .check();
  const Add(double.negativeInfinity, double.maxFinite, double.negativeInfinity)
      .check();
  const Add(1.5, double.negativeInfinity, double.negativeInfinity).check();
  const Add(1.5, double.infinity, double.infinity).check();
  const Add(double.infinity, double.infinity, double.infinity).check();
  const Add(double.infinity, double.negativeInfinity, double.nan).check();
  const Add(double.negativeInfinity, double.infinity, double.nan).check();
  const Add(double.negativeInfinity, double.negativeInfinity,
          double.negativeInfinity)
      .check();
  const Add(double.minPositive, -double.minPositive, 0.0).check();
  const Add(-double.minPositive, double.minPositive, 0.0).check();

  const Less(double.nan, double.nan, false).check();
  const Less(double.nan, double.infinity, false).check();
  const Less(double.infinity, double.nan, false).check();
  const Less(double.nan, double.maxFinite, false).check();
  const Less(double.maxFinite, double.nan, false).check();
  const Less(double.nan, -double.maxFinite, false).check();
  const Less(-double.maxFinite, double.nan, false).check();
  const Less(double.nan, double.negativeInfinity, false).check();
  const Less(double.negativeInfinity, double.nan, false).check();
  const Less(double.negativeInfinity, double.negativeInfinity, false).check();
  const Less(double.negativeInfinity, -double.maxFinite, true).check();
  const Less(-double.maxFinite, double.negativeInfinity, false).check();
  const Less(-double.maxFinite, -double.maxFinite, false).check();
  const Less(-double.maxFinite, -9007199254740992, true).check();
  const Less(-9007199254740992, -double.maxFinite, false).check();
  const Less(-9007199254740992, -9007199254740992, false).check();
  const Less(-9007199254740992, -4294967296, true).check();
  const Less(-4294967296, -9007199254740992, false).check();
  const Less(-4294967296, -4294967296, false).check();
  const Less(-4294967296, -42, true).check();
  const Less(-42, -4294967296, false).check();
  const Less(-42, -42, false).check();
  const Less(-42, -42.0, false).check();
  const Less(-42.0, -42, false).check();
  const Less(-42.0, -42.0, false).check();
  const Less(-42, -3.14, true).check();
  const Less(-3.14, -42, false).check();
  const Less(-3.14, -3.14, false).check();
  const Less(-3.14, -double.minPositive, true).check();
  const Less(-double.minPositive, -3.14, false).check();
  const Less(-double.minPositive, -double.minPositive, false).check();
  const Less(-double.minPositive, -0.0, true).check();
  const Less(-0.0, -double.minPositive, false).check();
  const Less(-0.0, -0.0, false).check();
  const Less(0, 0, false).check();
  const Less(0.0, 0.0, false).check();
  const Less(-0.0, 0, false).check();
  const Less(0, -0.0, false).check();
  const Less(-0.0, 0.0, false).check();
  const Less(0.0, -0.0, false).check();
  const Less(0, 0.0, false).check();
  const Less(0.0, 0, false).check();
  const Less(0.0, double.minPositive, true).check();
  const Less(double.minPositive, 0.0, false).check();
  const Less(double.minPositive, double.minPositive, false).check();
  const Less(double.minPositive, 3.14, true).check();
  const Less(3.14, double.minPositive, false).check();
  const Less(3.14, 3.14, false).check();
  const Less(3.14, 42, true).check();
  const Less(42, 3.14, false).check();
  const Less(42.0, 42.0, false).check();
  const Less(42, 42.0, false).check();
  const Less(42.0, 42, false).check();
  const Less(42, 42, false).check();
  const Less(42, 4294967296, true).check();
  const Less(4294967296, 42, false).check();
  const Less(4294967296, 4294967296, false).check();
  const Less(4294967296, 9007199254740992, true).check();
  const Less(9007199254740992, 4294967296, false).check();
  const Less(9007199254740992, 9007199254740992, false).check();
  const Less(9007199254740992, double.maxFinite, true).check();
  const Less(double.maxFinite, 9007199254740992, false).check();
  const Less(double.maxFinite, double.maxFinite, false).check();
  const Less(double.maxFinite, double.infinity, true).check();
  const Less(double.infinity, double.maxFinite, false).check();
  const Less(double.infinity, double.infinity, false).check();
  const Less(0x7fffffff00000000, 0x8000000000000000, true).check();
  const Less(0x8000000000000000, 0x7fffffff00000000, false).check();

  const LessEqual(double.nan, double.nan, false).check();
  const LessEqual(double.nan, double.infinity, false).check();
  const LessEqual(double.infinity, double.nan, false).check();
  const LessEqual(double.nan, double.maxFinite, false).check();
  const LessEqual(double.maxFinite, double.nan, false).check();
  const LessEqual(double.nan, -double.maxFinite, false).check();
  const LessEqual(-double.maxFinite, double.nan, false).check();
  const LessEqual(double.nan, double.negativeInfinity, false).check();
  const LessEqual(double.negativeInfinity, double.nan, false).check();
  const LessEqual(double.negativeInfinity, double.negativeInfinity, true)
      .check();
  const LessEqual(double.negativeInfinity, -double.maxFinite, true).check();
  const LessEqual(-double.maxFinite, double.negativeInfinity, false).check();
  const LessEqual(-double.maxFinite, -double.maxFinite, true).check();
  const LessEqual(-double.maxFinite, -9007199254740992, true).check();
  const LessEqual(-9007199254740992, -double.maxFinite, false).check();
  const LessEqual(-9007199254740992, -9007199254740992, true).check();
  const LessEqual(-9007199254740992, -4294967296, true).check();
  const LessEqual(-4294967296, -9007199254740992, false).check();
  const LessEqual(-4294967296, -4294967296, true).check();
  const LessEqual(-4294967296, -42, true).check();
  const LessEqual(-42, -4294967296, false).check();
  const LessEqual(-42, -42, true).check();
  const LessEqual(-42, -42.0, true).check();
  const LessEqual(-42.0, -42, true).check();
  const LessEqual(-42.0, -42.0, true).check();
  const LessEqual(-42, -3.14, true).check();
  const LessEqual(-3.14, -42, false).check();
  const LessEqual(-3.14, -3.14, true).check();
  const LessEqual(-3.14, -double.minPositive, true).check();
  const LessEqual(-double.minPositive, -3.14, false).check();
  const LessEqual(-double.minPositive, -double.minPositive, true).check();
  const LessEqual(-double.minPositive, -0.0, true).check();
  const LessEqual(-0.0, -double.minPositive, false).check();
  const LessEqual(-0.0, -0.0, true).check();
  const LessEqual(0, 0, true).check();
  const LessEqual(0.0, 0.0, true).check();
  const LessEqual(-0.0, 0, true).check();
  const LessEqual(0, -0.0, true).check();
  const LessEqual(-0.0, 0.0, true).check();
  const LessEqual(0.0, -0.0, true).check();
  const LessEqual(0, 0.0, true).check();
  const LessEqual(0.0, 0, true).check();
  const LessEqual(0.0, double.minPositive, true).check();
  const LessEqual(double.minPositive, 0.0, false).check();
  const LessEqual(double.minPositive, double.minPositive, true).check();
  const LessEqual(double.minPositive, 3.14, true).check();
  const LessEqual(3.14, double.minPositive, false).check();
  const LessEqual(3.14, 3.14, true).check();
  const LessEqual(3.14, 42, true).check();
  const LessEqual(42, 3.14, false).check();
  const LessEqual(42.0, 42.0, true).check();
  const LessEqual(42, 42.0, true).check();
  const LessEqual(42.0, 42, true).check();
  const LessEqual(42, 42, true).check();
  const LessEqual(42, 4294967296, true).check();
  const LessEqual(4294967296, 42, false).check();
  const LessEqual(4294967296, 4294967296, true).check();
  const LessEqual(4294967296, 9007199254740992, true).check();
  const LessEqual(9007199254740992, 4294967296, false).check();
  const LessEqual(9007199254740992, 9007199254740992, true).check();
  const LessEqual(9007199254740992, double.maxFinite, true).check();
  const LessEqual(double.maxFinite, 9007199254740992, false).check();
  const LessEqual(double.maxFinite, double.maxFinite, true).check();
  const LessEqual(double.maxFinite, double.infinity, true).check();
  const LessEqual(double.infinity, double.maxFinite, false).check();
  const LessEqual(double.infinity, double.infinity, true).check();
  const LessEqual(0x7fffffff00000000, 0x8000000000000000, true).check();
  const LessEqual(0x8000000000000000, 0x7fffffff00000000, false).check();

  const Greater(double.nan, double.nan, false).check();
  const Greater(double.nan, double.infinity, false).check();
  const Greater(double.infinity, double.nan, false).check();
  const Greater(double.nan, double.maxFinite, false).check();
  const Greater(double.maxFinite, double.nan, false).check();
  const Greater(double.nan, -double.maxFinite, false).check();
  const Greater(-double.maxFinite, double.nan, false).check();
  const Greater(double.nan, double.negativeInfinity, false).check();
  const Greater(double.negativeInfinity, double.nan, false).check();
  const Greater(double.negativeInfinity, double.negativeInfinity, false)
      .check();
  const Greater(double.negativeInfinity, -double.maxFinite, false).check();
  const Greater(-double.maxFinite, double.negativeInfinity, true).check();
  const Greater(-double.maxFinite, -double.maxFinite, false).check();
  const Greater(-double.maxFinite, -9007199254740992, false).check();
  const Greater(-9007199254740992, -double.maxFinite, true).check();
  const Greater(-9007199254740992, -9007199254740992, false).check();
  const Greater(-9007199254740992, -4294967296, false).check();
  const Greater(-4294967296, -9007199254740992, true).check();
  const Greater(-4294967296, -4294967296, false).check();
  const Greater(-4294967296, -42, false).check();
  const Greater(-42, -4294967296, true).check();
  const Greater(-42, -42, false).check();
  const Greater(-42, -42.0, false).check();
  const Greater(-42.0, -42, false).check();
  const Greater(-42.0, -42.0, false).check();
  const Greater(-42, -3.14, false).check();
  const Greater(-3.14, -42, true).check();
  const Greater(-3.14, -3.14, false).check();
  const Greater(-3.14, -double.minPositive, false).check();
  const Greater(-double.minPositive, -3.14, true).check();
  const Greater(-double.minPositive, -double.minPositive, false).check();
  const Greater(-double.minPositive, -0.0, false).check();
  const Greater(-0.0, -double.minPositive, true).check();
  const Greater(-0.0, -0.0, false).check();
  const Greater(0, 0, false).check();
  const Greater(0.0, 0.0, false).check();
  const Greater(-0.0, 0, false).check();
  const Greater(0, -0.0, false).check();
  const Greater(-0.0, 0.0, false).check();
  const Greater(0.0, -0.0, false).check();
  const Greater(0, 0.0, false).check();
  const Greater(0.0, 0, false).check();
  const Greater(0.0, double.minPositive, false).check();
  const Greater(double.minPositive, 0.0, true).check();
  const Greater(double.minPositive, double.minPositive, false).check();
  const Greater(double.minPositive, 3.14, false).check();
  const Greater(3.14, double.minPositive, true).check();
  const Greater(3.14, 3.14, false).check();
  const Greater(3.14, 42, false).check();
  const Greater(42, 3.14, true).check();
  const Greater(42.0, 42.0, false).check();
  const Greater(42, 42.0, false).check();
  const Greater(42.0, 42, false).check();
  const Greater(42, 42, false).check();
  const Greater(42, 4294967296, false).check();
  const Greater(4294967296, 42, true).check();
  const Greater(4294967296, 4294967296, false).check();
  const Greater(4294967296, 9007199254740992, false).check();
  const Greater(9007199254740992, 4294967296, true).check();
  const Greater(9007199254740992, 9007199254740992, false).check();
  const Greater(9007199254740992, double.maxFinite, false).check();
  const Greater(double.maxFinite, 9007199254740992, true).check();
  const Greater(double.maxFinite, double.maxFinite, false).check();
  const Greater(double.maxFinite, double.infinity, false).check();
  const Greater(double.infinity, double.maxFinite, true).check();
  const Greater(double.infinity, double.infinity, false).check();
  const Greater(0x7fffffff00000000, 0x8000000000000000, false).check();
  const Greater(0x8000000000000000, 0x7fffffff00000000, true).check();

  const GreaterEqual(double.nan, double.nan, false).check();
  const GreaterEqual(double.nan, double.infinity, false).check();
  const GreaterEqual(double.infinity, double.nan, false).check();
  const GreaterEqual(double.nan, double.maxFinite, false).check();
  const GreaterEqual(double.maxFinite, double.nan, false).check();
  const GreaterEqual(double.nan, -double.maxFinite, false).check();
  const GreaterEqual(-double.maxFinite, double.nan, false).check();
  const GreaterEqual(double.nan, double.negativeInfinity, false).check();
  const GreaterEqual(double.negativeInfinity, double.nan, false).check();
  const GreaterEqual(double.negativeInfinity, double.negativeInfinity, true)
      .check();
  const GreaterEqual(double.negativeInfinity, -double.maxFinite, false).check();
  const GreaterEqual(-double.maxFinite, double.negativeInfinity, true).check();
  const GreaterEqual(-double.maxFinite, -double.maxFinite, true).check();
  const GreaterEqual(-double.maxFinite, -9007199254740992, false).check();
  const GreaterEqual(-9007199254740992, -double.maxFinite, true).check();
  const GreaterEqual(-9007199254740992, -9007199254740992, true).check();
  const GreaterEqual(-9007199254740992, -4294967296, false).check();
  const GreaterEqual(-4294967296, -9007199254740992, true).check();
  const GreaterEqual(-4294967296, -4294967296, true).check();
  const GreaterEqual(-4294967296, -42, false).check();
  const GreaterEqual(-42, -4294967296, true).check();
  const GreaterEqual(-42, -42, true).check();
  const GreaterEqual(-42, -42.0, true).check();
  const GreaterEqual(-42.0, -42, true).check();
  const GreaterEqual(-42.0, -42.0, true).check();
  const GreaterEqual(-42, -3.14, false).check();
  const GreaterEqual(-3.14, -42, true).check();
  const GreaterEqual(-3.14, -3.14, true).check();
  const GreaterEqual(-3.14, -double.minPositive, false).check();
  const GreaterEqual(-double.minPositive, -3.14, true).check();
  const GreaterEqual(-double.minPositive, -double.minPositive, true).check();
  const GreaterEqual(-double.minPositive, -0.0, false).check();
  const GreaterEqual(-0.0, -double.minPositive, true).check();
  const GreaterEqual(-0.0, -0.0, true).check();
  const GreaterEqual(0, 0, true).check();
  const GreaterEqual(0.0, 0.0, true).check();
  const GreaterEqual(-0.0, 0, true).check();
  const GreaterEqual(0, -0.0, true).check();
  const GreaterEqual(-0.0, 0.0, true).check();
  const GreaterEqual(0.0, -0.0, true).check();
  const GreaterEqual(0, 0.0, true).check();
  const GreaterEqual(0.0, 0, true).check();
  const GreaterEqual(0.0, double.minPositive, false).check();
  const GreaterEqual(double.minPositive, 0.0, true).check();
  const GreaterEqual(double.minPositive, double.minPositive, true).check();
  const GreaterEqual(double.minPositive, 3.14, false).check();
  const GreaterEqual(3.14, double.minPositive, true).check();
  const GreaterEqual(3.14, 3.14, true).check();
  const GreaterEqual(3.14, 42, false).check();
  const GreaterEqual(42, 3.14, true).check();
  const GreaterEqual(42.0, 42.0, true).check();
  const GreaterEqual(42, 42.0, true).check();
  const GreaterEqual(42.0, 42, true).check();
  const GreaterEqual(42, 42, true).check();
  const GreaterEqual(42, 4294967296, false).check();
  const GreaterEqual(4294967296, 42, true).check();
  const GreaterEqual(4294967296, 4294967296, true).check();
  const GreaterEqual(4294967296, 9007199254740992, false).check();
  const GreaterEqual(9007199254740992, 4294967296, true).check();
  const GreaterEqual(9007199254740992, 9007199254740992, true).check();
  const GreaterEqual(9007199254740992, double.maxFinite, false).check();
  const GreaterEqual(double.maxFinite, 9007199254740992, true).check();
  const GreaterEqual(double.maxFinite, double.maxFinite, true).check();
  const GreaterEqual(double.maxFinite, double.infinity, false).check();
  const GreaterEqual(double.infinity, double.maxFinite, true).check();
  const GreaterEqual(double.infinity, double.infinity, true).check();
  const GreaterEqual(0x7fffffff00000000, 0x8000000000000000, false).check();
  const GreaterEqual(0x8000000000000000, 0x7fffffff00000000, true).check();

  const Equals(null, null, true).check();
  const Equals(null, "", false).check();
  const Equals("", null, false).check();
  const Equals("", "", true).check();
  const Equals(true, true, true).check();
  const Equals(false, false, true).check();
  const Equals(true, false, false).check();
  const Equals(false, true, false).check();
  const Equals(0, false, false).check();
  const Equals(true, 1, false).check();
  const Equals(double.nan, double.nan, false).check();
  const Equals(0, 0, true).check();
  const Equals(0.0, 0.0, true).check();
  const Equals(-0.0, -0.0, true).check();
  const Equals(0, 0.0, true).check();
  const Equals(0.0, 0, true).check();
  const Equals(0, -0.0, true).check();
  const Equals(-0.0, 0, true).check();
  const Equals(0.0, -0.0, true).check();
  const Equals(-0.0, 0.0, true).check();
  const Equals(1, 1, true).check();
  const Equals(1.0, 1.0, true).check();
  const Equals(1, 1.0, true).check();
  const Equals(1.0, 1, true).check();
  const Equals(double.infinity, double.infinity, true).check();
  const Equals(double.infinity, double.negativeInfinity, false).check();
  const Equals(double.negativeInfinity, double.infinity, false).check();
  const Equals(double.negativeInfinity, double.negativeInfinity, true).check();
  const Equals(0x8000000000000000, 0x8000000000000000, true).check();
  const Equals(0x8000000000000000, -9223372036854775808, false).check();

  const Identity(null, null, true).check();
  const Identity(null, "", false).check();
  const Identity("", null, false).check();
  const Identity("", "", true).check();
  const Identity(true, true, true).check();
  const Identity(false, false, true).check();
  const Identity(true, false, false).check();
  const Identity(false, true, false).check();
  const Identity(0, false, false).check();
  const Identity(true, 1, false).check();
  const Identity(double.nan, double.nan, false).check();
  const Identity(0, 0, true).check();
  const Identity(0.0, 0.0, true).check();
  const Identity(-0.0, -0.0, true).check();
  const Identity(0, 0.0, true).check();
  const Identity(0.0, 0, true).check();
  const Identity(0, -0.0, true).check();
  const Identity(-0.0, 0, true).check();
  const Identity(0.0, -0.0, true).check();
  const Identity(-0.0, 0.0, true).check();
  const Identity(1, 1, true).check();
  const Identity(1.0, 1.0, true).check();
  const Identity(1, 1.0, true).check();
  const Identity(1.0, 1, true).check();
  const Identity(double.infinity, double.infinity, true).check();
  const Identity(double.infinity, double.negativeInfinity, false).check();
  const Identity(double.negativeInfinity, double.infinity, false).check();
  const Identity(double.negativeInfinity, double.negativeInfinity, true)
      .check();
  const Identity(0x8000000000000000, 0x8000000000000000, true).check();
  const Identity(0x8000000000000000, -9223372036854775808, false).check();

  const IfNull(null, null, null).check();
  const IfNull(null, 1, 1).check();
  const IfNull("foo", 1, "foo").check();
  const IfNull("foo", null, "foo").check();
}

/// Wraps [Expect.equals] to accommodate JS equality semantics.
///
/// Naively using [Expect.equals] causes JS values to be compared with `===`.
/// This can yield some unintended results:
///
/// * Since `NaN === NaN` is `false`, [Expect.equals] will throw even if both
///   values are `NaN`. Therefore, we check for `NaN` specifically.
/// * Since `0.0 === -0.0` is `true`, [Expect.equals] will fail to throw if one
///   constant evaluation results in `0` or `0.0` and the other results in
///   `-0.0`. Therefore, we additionally check that both values have the same
///   sign in this case.
void jsEquals(expected, actual, [String reason = null]) {
  if (expected is num && actual is num) {
    if (expected.isNaN && actual.isNaN) return;
  }

  Expect.equals(expected, actual, reason);

  if (expected == 0 && actual == 0) {
    Expect.equals(
        expected.isNegative,
        actual.isNegative,
        (reason == null ? "" : "$reason ") +
            "${expected.toString()} and "
            "${actual.toString()} have different signs.");
  }
}

abstract class TestOp {
  final expected;
  final result;

  const TestOp(this.expected, this.result);

  @pragma('dart2js:noInline')
  checkAll(evalResult) {
    jsEquals(expected, result,
        "Frontend constant evaluation does not yield expected value.");
    jsEquals(expected, evalResult,
        "Backend constant evaluation does not yield expected value.");
    jsEquals(expected, eval(), "eval() does not yield expected value.");
  }

  eval();
}

class BitNot extends TestOp {
  final arg;

  const BitNot(this.arg, expected) : super(expected, ~arg);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => ~arg;
}

class Negate extends TestOp {
  final arg;

  const Negate(this.arg, expected) : super(expected, -arg);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => -arg;
}

class Not extends TestOp {
  final arg;

  const Not(this.arg, expected) : super(expected, !arg);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => !arg;
}

class BitAnd extends TestOp {
  final arg1;
  final arg2;

  const BitAnd(this.arg1, this.arg2, expected) : super(expected, arg1 & arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 & arg2;
}

class BitOr extends TestOp {
  final arg1;
  final arg2;

  const BitOr(this.arg1, this.arg2, expected) : super(expected, arg1 | arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 | arg2;
}

class BitXor extends TestOp {
  final arg1;
  final arg2;

  const BitXor(this.arg1, this.arg2, expected) : super(expected, arg1 ^ arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 ^ arg2;
}

class ShiftLeft extends TestOp {
  final arg1;
  final arg2;

  const ShiftLeft(this.arg1, this.arg2, expected)
      : super(expected, arg1 << arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 << arg2;
}

class ShiftRight extends TestOp {
  final arg1;
  final arg2;

  const ShiftRight(this.arg1, this.arg2, expected)
      : super(expected, arg1 >> arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 >> arg2;
}

class BooleanAnd extends TestOp {
  final arg1;
  final arg2;

  const BooleanAnd(this.arg1, this.arg2, expected)
      : super(expected, arg1 && arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 && arg2;
}

class BooleanOr extends TestOp {
  final arg1;
  final arg2;

  const BooleanOr(this.arg1, this.arg2, expected)
      : super(expected, arg1 || arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 || arg2;
}

class Subtract extends TestOp {
  final arg1;
  final arg2;

  const Subtract(this.arg1, this.arg2, expected) : super(expected, arg1 - arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 - arg2;
}

class Multiply extends TestOp {
  final arg1;
  final arg2;

  const Multiply(this.arg1, this.arg2, expected) : super(expected, arg1 * arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 * arg2;
}

class Modulo extends TestOp {
  final arg1;
  final arg2;

  const Modulo(this.arg1, this.arg2, expected) : super(expected, arg1 % arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 % arg2;
}

class TruncatingDivide extends TestOp {
  final arg1;
  final arg2;

  const TruncatingDivide(this.arg1, this.arg2, expected)
      : super(expected, arg1 ~/ arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 ~/ arg2;
}

class Divide extends TestOp {
  final arg1;
  final arg2;

  const Divide(this.arg1, this.arg2, expected) : super(expected, arg1 / arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 / arg2;
}

class Add extends TestOp {
  final arg1;
  final arg2;

  const Add(this.arg1, this.arg2, expected) : super(expected, arg1 + arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @pragma('dart2js:tryInline')
  eval() => arg1 + arg2;
}

class Less extends TestOp {
  final arg1;
  final arg2;

  const Less(this.arg1, this.arg2, expected) : super(expected, arg1 < arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @pragma('dart2js:tryInline')
  eval() => arg1 < arg2;
}

class LessEqual extends TestOp {
  final arg1;
  final arg2;

  const LessEqual(this.arg1, this.arg2, expected)
      : super(expected, arg1 <= arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @pragma('dart2js:tryInline')
  eval() => arg1 <= arg2;
}

class Greater extends TestOp {
  final arg1;
  final arg2;

  const Greater(this.arg1, this.arg2, expected) : super(expected, arg1 > arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @pragma('dart2js:tryInline')
  eval() => arg1 > arg2;
}

class GreaterEqual extends TestOp {
  final arg1;
  final arg2;

  const GreaterEqual(this.arg1, this.arg2, expected)
      : super(expected, arg1 >= arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @pragma('dart2js:tryInline')
  eval() => arg1 >= arg2;
}

class Equals extends TestOp {
  final arg1;
  final arg2;

  const Equals(this.arg1, this.arg2, expected) : super(expected, arg1 == arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @pragma('dart2js:tryInline')
  eval() => arg1 == arg2;
}

class Identity extends TestOp {
  final arg1;
  final arg2;

  const Identity(this.arg1, this.arg2, expected)
      : super(expected, identical(arg1, arg2));

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @pragma('dart2js:tryInline')
  eval() => identical(arg1, arg2);
}

class IfNull extends TestOp {
  final arg1;
  final arg2;

  const IfNull(this.arg1, this.arg2, expected) : super(expected, arg1 ?? arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @pragma('dart2js:tryInline')
  eval() => arg1 ?? arg2;
}
