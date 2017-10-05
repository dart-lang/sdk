// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/*
 * Copyright (c) 2003-2005  Tom Wu
 * Copyright (c) 2012 Adam Singer (adam@solvr.io)
 * All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
 *
 * IN NO EVENT SHALL TOM WU BE LIABLE FOR ANY SPECIAL, INCIDENTAL,
 * INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND, OR ANY DAMAGES WHATSOEVER
 * RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER OR NOT ADVISED OF
 * THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF LIABILITY, ARISING OUT
 * OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * In addition, the following condition applies:
 *
 * All redistributions must retain an intact copy of this copyright notice
 * and disclaimer.
 */

// A big integer number is represented by a sign, an array of 32-bit unsigned
// integers in little endian format, and a number of used digits in that array.
// The code makes sure that an even number of digits is always accessible and
// meaningful, so that pairs of digits can be processed as 64-bit unsigned
// numbers on a 64-bit platform. This requires the initialization of a leading
// zero if the number of used digits is odd.
class _Bigint extends _IntegerImplementation implements int {
  // Bits per digit.
  static const int _DIGIT_BITS = 32;
  static const int _LOG2_DIGIT_BITS = 5;
  static const int _DIGIT_BASE = 1 << _DIGIT_BITS;
  static const int _DIGIT_MASK = (1 << _DIGIT_BITS) - 1;

  // Bits per half digit.
  static const int _DIGIT2_BITS = _DIGIT_BITS >> 1;
  static const int _DIGIT2_MASK = (1 << _DIGIT2_BITS) - 1;

  // Bits per 2 digits. Used to perform modulo 2^64 arithmetic.
  // Note: in --limit-ints-to-64-bits mode most arithmetic operations are
  // already modulo 2^64. Still, it is harmless to apply _TWO_DIGITS_MASK:
  // (1 << _TWO_DIGITS_BITS) is 0 (all bits are shifted out), so
  // _TWO_DIGITS_MASK is -1 (its bit pattern is 0xffffffffffffffff).
  static const int _TWO_DIGITS_BITS = _DIGIT_BITS << 1;
  static const int _TWO_DIGITS_MASK = (1 << _TWO_DIGITS_BITS) - 1;

  // Min and max of non bigint values.
  static const int _MIN_INT64 = (-1) << 63;
  static const int _MAX_INT64 = 0x7fffffffffffffff;

  // Bigint constant values.
  // Note: Not declared as final in order to satisfy optimizer, which expects
  // constants to be in canonical form (Smi).
  static _Bigint _MINUS_ONE = new _Bigint._fromInt(-1);
  static _Bigint _ZERO = new _Bigint._fromInt(0);
  static _Bigint _ONE = new _Bigint._fromInt(1);

  // Result cache for last _divRem call.
  static Uint32List _lastDividend_digits;
  static int _lastDividend_used;
  static Uint32List _lastDivisor_digits;
  static int _lastDivisor_used;
  static Uint32List _lastQuoRem_digits;
  static int _lastQuoRem_used;
  static int _lastRem_used;
  static int _lastRem_nsh;

  // Internal data structure.
  bool get _neg native "Bigint_getNeg";
  int get _used native "Bigint_getUsed";
  Uint32List get _digits native "Bigint_getDigits";

  // Factory returning an instance initialized with the given field values.
  // The 'digits' array is first clamped and 'used' is reduced accordingly.
  // A leading zero digit may be initialized to guarantee that digit pairs can
  // be processed as 64-bit values on 64-bit platforms.
  factory _Bigint(bool neg, int used, Uint32List digits)
      native "Bigint_allocate";

  // Factory returning an instance initialized to an integer value no larger
  // than a Mint.
  factory _Bigint._fromInt(int i) {
    assert(i is! _Bigint);
    var neg;
    var l, h;
    if (i < 0) {
      neg = true;
      if (i == _MIN_INT64) {
        l = 0;
        h = 0x80000000;
      } else {
        l = (-i) & _DIGIT_MASK;
        h = (-i) >> _DIGIT_BITS;
      }
    } else {
      neg = false;
      l = i & _DIGIT_MASK;
      h = i >> _DIGIT_BITS;
    }
    var digits = new Uint32List(2);
    digits[0] = l;
    digits[1] = h;
    return new _Bigint(neg, 2, digits);
  }

  // Allocate an array of the given length (+1 for at least one leading zero
  // digit if odd) and copy digits[from..to-1] starting at index 0, followed by
  // leading zero digits.
  static Uint32List _cloneDigits(
      Uint32List digits, int from, int to, int length) {
    length += length & 1; // Even number of digits.
    var r_digits = new Uint32List(length);
    var n = to - from;
    for (var i = 0; i < n; i++) {
      r_digits[i] = digits[from + i];
    }
    return r_digits;
  }

  // Return most compact integer (i.e. possibly Smi or Mint).
  int _toValidInt() {
    assert(_DIGIT_BITS == 32); // Otherwise this code needs to be revised.
    var used = _used;
    if (used == 0) return 0;
    var digits = _digits;
    if (used == 1) return _neg ? -digits[0] : digits[0];
    if (used > 2) return this;
    if (_neg) {
      if (digits[1] > 0x80000000) return this;
      if (digits[1] == 0x80000000) {
        if (digits[0] > 0) return this;
        return _MIN_INT64;
      }
      return -((digits[1] << _DIGIT_BITS) | digits[0]);
    }
    if (digits[1] >= 0x80000000) return this;
    return (digits[1] << _DIGIT_BITS) | digits[0];
  }

  // Conversion from int to bigint.
  _Bigint _toBigint() => this;

  // Return -this.
  _Bigint _negate() {
    var used = _used;
    if (used == 0) {
      return this;
    }
    return new _Bigint(!_neg, used, _digits);
  }

  // Return abs(this).
  _Bigint _abs() {
    var neg = _neg;
    if (!neg) {
      return this;
    }
    return new _Bigint(!neg, _used, _digits);
  }

  // Return the bit length of digit x.
  static int _nbits(int x) {
    var r = 1, t;
    if ((t = x >> 16) != 0) {
      x = t;
      r += 16;
    }
    if ((t = x >> 8) != 0) {
      x = t;
      r += 8;
    }
    if ((t = x >> 4) != 0) {
      x = t;
      r += 4;
    }
    if ((t = x >> 2) != 0) {
      x = t;
      r += 2;
    }
    if ((x >> 1) != 0) {
      r += 1;
    }
    return r;
  }

  // Return this << n*_DIGIT_BITS.
  _Bigint _dlShift(int n) {
    final used = _used;
    if (used == 0) {
      return _ZERO;
    }
    final r_used = used + n;
    final digits = _digits;
    final r_digits = new Uint32List(r_used + (r_used & 1));
    var i = used;
    while (--i >= 0) {
      r_digits[i + n] = digits[i];
    }
    return new _Bigint(_neg, r_used, r_digits);
  }

  // r_digits[0..r_used-1] = x_digits[0..x_used-1] << n*_DIGIT_BITS.
  // Return r_used.
  static int _dlShiftDigits(
      Uint32List x_digits, int x_used, int n, Uint32List r_digits) {
    if (x_used == 0) {
      return 0;
    }
    if (n == 0 && identical(r_digits, x_digits)) {
      return x_used;
    }
    final r_used = x_used + n;
    assert(r_digits.length >= r_used + (r_used & 1));
    var i = x_used;
    while (--i >= 0) {
      r_digits[i + n] = x_digits[i];
    }
    i = n;
    while (--i >= 0) {
      r_digits[i] = 0;
    }
    if (r_used.isOdd) {
      r_digits[r_used] = 0;
    }
    return r_used;
  }

  // Return this >> n*_DIGIT_BITS.
  _Bigint _drShift(int n) {
    final used = _used;
    if (used == 0) {
      return _ZERO;
    }
    final r_used = used - n;
    if (r_used <= 0) {
      return _neg ? _MINUS_ONE : _ZERO;
    }
    final digits = _digits;
    final r_digits = new Uint32List(r_used + (r_used & 1));
    for (var i = n; i < used; i++) {
      r_digits[i - n] = digits[i];
    }
    final r = new _Bigint(_neg, r_used, r_digits);
    if (_neg) {
      // Round down if any bit was shifted out.
      for (var i = 0; i < n; i++) {
        if (digits[i] != 0) {
          return r._sub(_ONE);
        }
      }
    }
    return r;
  }

  // r_digits[0..r_used-1] = x_digits[0..x_used-1] >> n*_DIGIT_BITS.
  // Return r_used.
  static int _drShiftDigits(
      Uint32List x_digits, int x_used, int n, Uint32List r_digits) {
    final r_used = x_used - n;
    if (r_used <= 0) {
      return 0;
    }
    assert(r_digits.length >= r_used + (r_used & 1));
    for (var i = n; i < x_used; i++) {
      r_digits[i - n] = x_digits[i];
    }
    if (r_used.isOdd) {
      r_digits[r_used] = 0;
    }
    return r_used;
  }

  // r_digits[ds..x_used+ds] = x_digits[0..x_used-1] << (n % _DIGIT_BITS)
  // where ds = ceil(n / _DIGIT_BITS)
  // Doesn't clear digits below ds.
  static void _lsh(
      Uint32List x_digits, int x_used, int n, Uint32List r_digits) {
    final ds = n ~/ _DIGIT_BITS;
    final bs = n % _DIGIT_BITS;
    final cbs = _DIGIT_BITS - bs;
    final bm = (1 << cbs) - 1;
    var c = 0;
    var i = x_used;
    while (--i >= 0) {
      final d = x_digits[i];
      r_digits[i + ds + 1] = (d >> cbs) | c;
      c = (d & bm) << bs;
    }
    r_digits[ds] = c;
  }

  // Return this << n.
  _Bigint _lShift(int n) {
    final ds = n ~/ _DIGIT_BITS;
    final bs = n % _DIGIT_BITS;
    if (bs == 0) {
      return _dlShift(ds);
    }
    var r_used = _used + ds + 1;
    var r_digits = new Uint32List(r_used + 2 - (r_used & 1)); // for 64-bit.
    _lsh(_digits, _used, n, r_digits);
    return new _Bigint(_neg, r_used, r_digits);
  }

  // r_digits[0..r_used-1] = x_digits[0..x_used-1] << n.
  // Return r_used.
  static int _lShiftDigits(
      Uint32List x_digits, int x_used, int n, Uint32List r_digits) {
    final ds = n ~/ _DIGIT_BITS;
    final bs = n % _DIGIT_BITS;
    if (bs == 0) {
      return _dlShiftDigits(x_digits, x_used, ds, r_digits);
    }
    var r_used = x_used + ds + 1;
    assert(r_digits.length >= r_used + 2 - (r_used & 1)); // for 64-bit.
    _lsh(x_digits, x_used, n, r_digits);
    var i = ds;
    while (--i >= 0) {
      r_digits[i] = 0;
    }
    if (r_digits[r_used - 1] == 0) {
      r_used--; // Clamp result.
    } else if (r_used.isOdd) {
      r_digits[r_used] = 0;
    }
    return r_used;
  }

  // r_digits[0..r_used-1] = x_digits[0..x_used-1] >> n.
  static void _rsh(
      Uint32List x_digits, int x_used, int n, Uint32List r_digits) {
    final ds = n ~/ _DIGIT_BITS;
    final bs = n % _DIGIT_BITS;
    final cbs = _DIGIT_BITS - bs;
    final bm = (1 << bs) - 1;
    var c = x_digits[ds] >> bs;
    final last = x_used - ds - 1;
    for (var i = 0; i < last; i++) {
      final d = x_digits[i + ds + 1];
      r_digits[i] = ((d & bm) << cbs) | c;
      c = d >> bs;
    }
    r_digits[last] = c;
  }

  // Return this >> n.
  _Bigint _rShift(int n) {
    final ds = n ~/ _DIGIT_BITS;
    final bs = n % _DIGIT_BITS;
    if (bs == 0) {
      return _drShift(ds);
    }
    final used = _used;
    final r_used = used - ds;
    if (r_used <= 0) {
      return _neg ? _MINUS_ONE : _ZERO;
    }
    final digits = _digits;
    final r_digits = new Uint32List(r_used + (r_used & 1));
    _rsh(digits, used, n, r_digits);
    final r = new _Bigint(_neg, r_used, r_digits);
    if (_neg) {
      // Round down if any bit was shifted out.
      if ((digits[ds] & ((1 << bs) - 1)) != 0) {
        return r._sub(_ONE);
      }
      for (var i = 0; i < ds; i++) {
        if (digits[i] != 0) {
          return r._sub(_ONE);
        }
      }
    }
    return r;
  }

  // r_digits[0..r_used-1] = x_digits[0..x_used-1] >> n.
  // Return r_used.
  static int _rShiftDigits(
      Uint32List x_digits, int x_used, int n, Uint32List r_digits) {
    final ds = n ~/ _DIGIT_BITS;
    final bs = n % _DIGIT_BITS;
    if (bs == 0) {
      return _drShiftDigits(x_digits, x_used, ds, r_digits);
    }
    var r_used = x_used - ds;
    if (r_used <= 0) {
      return 0;
    }
    assert(r_digits.length >= r_used + (r_used & 1));
    _rsh(x_digits, x_used, n, r_digits);
    if (r_digits[r_used - 1] == 0) {
      r_used--; // Clamp result.
    } else if (r_used.isOdd) {
      r_digits[r_used] = 0;
    }
    return r_used;
  }

  // Return 0 if abs(this) == abs(a).
  // Return a positive number if abs(this) > abs(a).
  // Return a negative number if abs(this) < abs(a).
  int _absCompare(_Bigint a) {
    var r = _used - a._used;
    if (r == 0) {
      var i = _used;
      var digits = _digits;
      var a_digits = a._digits;
      while (--i >= 0 && (r = digits[i] - a_digits[i]) == 0);
    }
    return r;
  }

  // Return 0 if this == a.
  // Return a positive number if this > a.
  // Return a negative number if this < a.
  int _compare(_Bigint a) {
    if (_neg == a._neg) {
      var r = _absCompare(a);
      return _neg ? -r : r;
    }
    return _neg ? -1 : 1;
  }

  // Compare digits[0..used-1] with a_digits[0..a_used-1].
  // Return 0 if equal.
  // Return a positive number if larger.
  // Return a negative number if smaller.
  static int _compareDigits(
      Uint32List digits, int used, Uint32List a_digits, int a_used) {
    var r = used - a_used;
    if (r == 0) {
      var i = a_used;
      while (--i >= 0 && (r = digits[i] - a_digits[i]) == 0);
    }
    return r;
  }

  // r_digits[0..used] = digits[0..used-1] + a_digits[0..a_used-1].
  // used >= a_used > 0.
  // Note: Intrinsics on 64-bit platforms process digit pairs at even indices.
  static void _absAdd(Uint32List digits, int used, Uint32List a_digits,
      int a_used, Uint32List r_digits) {
    assert(used >= a_used && a_used > 0);
    // Verify that digit pairs are accessible for 64-bit processing.
    assert(digits.length > ((used - 1) | 1));
    assert(a_digits.length > ((a_used - 1) | 1));
    assert(r_digits.length > (used | 1));
    var c = 0;
    for (var i = 0; i < a_used; i++) {
      c += digits[i] + a_digits[i];
      r_digits[i] = c & _DIGIT_MASK;
      c >>= _DIGIT_BITS;
    }
    for (var i = a_used; i < used; i++) {
      c += digits[i];
      r_digits[i] = c & _DIGIT_MASK;
      c >>= _DIGIT_BITS;
    }
    r_digits[used] = c;
  }

  // r_digits[0..used-1] = digits[0..used-1] - a_digits[0..a_used-1].
  // used >= a_used > 0.
  // Note: Intrinsics on 64-bit platforms process digit pairs at even indices.
  static void _absSub(Uint32List digits, int used, Uint32List a_digits,
      int a_used, Uint32List r_digits) {
    assert(used >= a_used && a_used > 0);
    // Verify that digit pairs are accessible for 64-bit processing.
    assert(digits.length > ((used - 1) | 1));
    assert(a_digits.length > ((a_used - 1) | 1));
    assert(r_digits.length > ((used - 1) | 1));
    var c = 0;
    for (var i = 0; i < a_used; i++) {
      c += digits[i] - a_digits[i];
      r_digits[i] = c & _DIGIT_MASK;
      c >>= _DIGIT_BITS;
    }
    for (var i = a_used; i < used; i++) {
      c += digits[i];
      r_digits[i] = c & _DIGIT_MASK;
      c >>= _DIGIT_BITS;
    }
  }

  // Return abs(this) + abs(a) with sign set according to neg.
  _Bigint _absAddSetSign(_Bigint a, bool neg) {
    var used = _used;
    var a_used = a._used;
    if (used < a_used) {
      return a._absAddSetSign(this, neg);
    }
    if (used == 0) {
      assert(!neg);
      return _ZERO;
    }
    if (a_used == 0) {
      return _neg == neg ? this : this._negate();
    }
    var r_used = used + 1;
    var r_digits = new Uint32List(r_used + (r_used & 1));
    _absAdd(_digits, used, a._digits, a_used, r_digits);
    return new _Bigint(neg, r_used, r_digits);
  }

  // Return abs(this) - abs(a) with sign set according to neg.
  // Requirement: abs(this) >= abs(a).
  _Bigint _absSubSetSign(_Bigint a, bool neg) {
    assert(_absCompare(a) >= 0);
    var used = _used;
    if (used == 0) {
      assert(!neg);
      return _ZERO;
    }
    var a_used = a._used;
    if (a_used == 0) {
      return _neg == neg ? this : this._negate();
    }
    var r_digits = new Uint32List(used + (used & 1));
    _absSub(_digits, used, a._digits, a_used, r_digits);
    return new _Bigint(neg, used, r_digits);
  }

  // Return abs(this) & abs(a) with sign set according to neg.
  _Bigint _absAndSetSign(_Bigint a, bool neg) {
    var r_used = (_used < a._used) ? _used : a._used;
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = new Uint32List(r_used + (r_used & 1));
    for (var i = 0; i < r_used; i++) {
      r_digits[i] = digits[i] & a_digits[i];
    }
    return new _Bigint(neg, r_used, r_digits);
  }

  // Return abs(this) &~ abs(a) with sign set according to neg.
  _Bigint _absAndNotSetSign(_Bigint a, bool neg) {
    var r_used = _used;
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = new Uint32List(r_used + (r_used & 1));
    var m = (r_used < a._used) ? r_used : a._used;
    for (var i = 0; i < m; i++) {
      r_digits[i] = digits[i] & ~a_digits[i];
    }
    for (var i = m; i < r_used; i++) {
      r_digits[i] = digits[i];
    }
    return new _Bigint(neg, r_used, r_digits);
  }

  // Return abs(this) | abs(a) with sign set according to neg.
  _Bigint _absOrSetSign(_Bigint a, bool neg) {
    var used = _used;
    var a_used = a._used;
    var r_used = (used > a_used) ? used : a_used;
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = new Uint32List(r_used + (r_used & 1));
    var l, m;
    if (used < a_used) {
      l = a;
      m = used;
    } else {
      l = this;
      m = a_used;
    }
    for (var i = 0; i < m; i++) {
      r_digits[i] = digits[i] | a_digits[i];
    }
    var l_digits = l._digits;
    for (var i = m; i < r_used; i++) {
      r_digits[i] = l_digits[i];
    }
    return new _Bigint(neg, r_used, r_digits);
  }

  // Return abs(this) ^ abs(a) with sign set according to neg.
  _Bigint _absXorSetSign(_Bigint a, bool neg) {
    var used = _used;
    var a_used = a._used;
    var r_used = (used > a_used) ? used : a_used;
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = new Uint32List(r_used + (r_used & 1));
    var l, m;
    if (used < a_used) {
      l = a;
      m = used;
    } else {
      l = this;
      m = a_used;
    }
    for (var i = 0; i < m; i++) {
      r_digits[i] = digits[i] ^ a_digits[i];
    }
    var l_digits = l._digits;
    for (var i = m; i < r_used; i++) {
      r_digits[i] = l_digits[i];
    }
    return new _Bigint(neg, r_used, r_digits);
  }

  // Return this & a.
  _Bigint _and(_Bigint a) {
    if (_neg == a._neg) {
      if (_neg) {
        // (-this) & (-a) == ~(this-1) & ~(a-1)
        //                == ~((this-1) | (a-1))
        //                == -(((this-1) | (a-1)) + 1)
        _Bigint t1 = _absSubSetSign(_ONE, true);
        _Bigint a1 = a._absSubSetSign(_ONE, true);
        // Result cannot be zero if this and a are negative.
        return t1._absOrSetSign(a1, true)._absAddSetSign(_ONE, true);
      }
      return _absAndSetSign(a, false);
    }
    // _neg != a._neg
    var p, n;
    if (_neg) {
      p = a;
      n = this;
    } else {
      // & is symmetric.
      p = this;
      n = a;
    }
    // p & (-n) == p & ~(n-1) == p &~ (n-1)
    _Bigint n1 = n._absSubSetSign(_ONE, false);
    return p._absAndNotSetSign(n1, false);
  }

  // Return this &~ a.
  _Bigint _andNot(_Bigint a) {
    if (_neg == a._neg) {
      if (_neg) {
        // (-this) &~ (-a) == ~(this-1) &~ ~(a-1)
        //                 == ~(this-1) & (a-1)
        //                 == (a-1) &~ (this-1)
        _Bigint t1 = _absSubSetSign(_ONE, true);
        _Bigint a1 = a._absSubSetSign(_ONE, true);
        return a1._absAndNotSetSign(t1, false);
      }
      return _absAndNotSetSign(a, false);
    }
    if (_neg) {
      // (-this) &~ a == ~(this-1) &~ a
      //              == ~(this-1) & ~a
      //              == ~((this-1) | a)
      //              == -(((this-1) | a) + 1)
      _Bigint t1 = _absSubSetSign(_ONE, true);
      // Result cannot be zero if this is negative and a is positive.
      return t1._absOrSetSign(a, true)._absAddSetSign(_ONE, true);
    }
    // this &~ (-a) == this &~ ~(a-1) == this & (a-1)
    _Bigint a1 = a._absSubSetSign(_ONE, true);
    return _absAndSetSign(a1, false);
  }

  // Return this | a.
  _Bigint _or(_Bigint a) {
    if (_neg == a._neg) {
      if (_neg) {
        // (-this) | (-a) == ~(this-1) | ~(a-1)
        //                == ~((this-1) & (a-1))
        //                == -(((this-1) & (a-1)) + 1)
        _Bigint t1 = _absSubSetSign(_ONE, true);
        _Bigint a1 = a._absSubSetSign(_ONE, true);
        // Result cannot be zero if this and a are negative.
        return t1._absAndSetSign(a1, true)._absAddSetSign(_ONE, true);
      }
      return _absOrSetSign(a, false);
    }
    // _neg != a._neg
    var p, n;
    if (_neg) {
      p = a;
      n = this;
    } else {
      // | is symmetric.
      p = this;
      n = a;
    }
    // p | (-n) == p | ~(n-1) == ~((n-1) &~ p) == -(~((n-1) &~ p) + 1)
    _Bigint n1 = n._absSubSetSign(_ONE, true);
    // Result cannot be zero if only one of this or a is negative.
    return n1._absAndNotSetSign(p, true)._absAddSetSign(_ONE, true);
  }

  // Return this ^ a.
  _Bigint _xor(_Bigint a) {
    if (_neg == a._neg) {
      if (_neg) {
        // (-this) ^ (-a) == ~(this-1) ^ ~(a-1) == (this-1) ^ (a-1)
        _Bigint t1 = _absSubSetSign(_ONE, true);
        _Bigint a1 = a._absSubSetSign(_ONE, true);
        return t1._absXorSetSign(a1, false);
      }
      return _absXorSetSign(a, false);
    }
    // _neg != a._neg
    var p, n;
    if (_neg) {
      p = a;
      n = this;
    } else {
      // ^ is symmetric.
      p = this;
      n = a;
    }
    // p ^ (-n) == p ^ ~(n-1) == ~(p ^ (n-1)) == -((p ^ (n-1)) + 1)
    _Bigint n1 = n._absSubSetSign(_ONE, true);
    // Result cannot be zero if only one of this or a is negative.
    return p._absXorSetSign(n1, true)._absAddSetSign(_ONE, true);
  }

  // Return ~this.
  _Bigint _not() {
    if (_neg) {
      // ~(-this) == ~(~(this-1)) == this-1
      return _absSubSetSign(_ONE, false);
    }
    // ~this == -this-1 == -(this+1)
    // Result cannot be zero if this is positive.
    return _absAddSetSign(_ONE, true);
  }

  // Return this + a.
  _Bigint _add(_Bigint a) {
    var neg = _neg;
    if (neg == a._neg) {
      // this + a == this + a
      // (-this) + (-a) == -(this + a)
      return _absAddSetSign(a, neg);
    }
    // this + (-a) == this - a == -(this - a)
    // (-this) + a == a - this == -(this - a)
    if (_absCompare(a) >= 0) {
      return _absSubSetSign(a, neg);
    }
    return a._absSubSetSign(this, !neg);
  }

  // Return this - a.
  _Bigint _sub(_Bigint a) {
    var neg = _neg;
    if (neg != a._neg) {
      // this - (-a) == this + a
      // (-this) - a == -(this + a)
      return _absAddSetSign(a, neg);
    }
    // this - a == this - a == -(this - a)
    // (-this) - (-a) == a - this == -(this - a)
    if (_absCompare(a) >= 0) {
      return _absSubSetSign(a, neg);
    }
    return a._absSubSetSign(this, !neg);
  }

  // Multiply and accumulate.
  // Input:
  //   x_digits[xi]: multiplier digit x.
  //   m_digits[i..i+n-1]: multiplicand digits.
  //   a_digits[j..j+n-1]: accumulator digits.
  // Operation:
  //   a_digits[j..j+n] += x_digits[xi]*m_digits[i..i+n-1].
  //   return 1.
  // Note: Intrinsics on 64-bit platforms process digit pairs at even indices
  //   and return 2.
  static int _mulAdd(Uint32List x_digits, int xi, Uint32List m_digits, int i,
      Uint32List a_digits, int j, int n) {
    // Verify that digit pairs are accessible for 64-bit processing.
    assert(x_digits.length > (xi | 1));
    assert(m_digits.length > ((i + n - 1) | 1));
    assert(a_digits.length > ((j + n) | 1));
    int x = x_digits[xi];
    if (x == 0) {
      // No-op if x is 0.
      return 1;
    }
    int c = 0;
    int xl = x & _DIGIT2_MASK;
    int xh = x >> _DIGIT2_BITS;
    while (--n >= 0) {
      int l = m_digits[i] & _DIGIT2_MASK;
      int h = m_digits[i++] >> _DIGIT2_BITS;
      int m = xh * l + h * xl;
      l = xl * l + ((m & _DIGIT2_MASK) << _DIGIT2_BITS) + a_digits[j] + c;
      c = (l >> _DIGIT_BITS) + (m >> _DIGIT2_BITS) + xh * h;
      a_digits[j++] = l & _DIGIT_MASK;
    }
    while (c != 0) {
      int l = a_digits[j] + c;
      c = l >> _DIGIT_BITS;
      a_digits[j++] = l & _DIGIT_MASK;
    }
    return 1;
  }

  // Square and accumulate.
  // Input:
  //   x_digits[i..used-1]: digits of operand being squared.
  //   a_digits[2*i..i+used-1]: accumulator digits.
  // Operation:
  //   a_digits[2*i..i+used-1] += x_digits[i]*x_digits[i] +
  //                              2*x_digits[i]*x_digits[i+1..used-1].
  //   return 1.
  // Note: Intrinsics on 64-bit platforms process digit pairs at even indices
  //   and return 2.
  static int _sqrAdd(
      Uint32List x_digits, int i, Uint32List a_digits, int used) {
    // Verify that digit pairs are accessible for 64-bit processing.
    assert(x_digits.length > ((used - 1) | 1));
    assert(a_digits.length > ((i + used - 1) | 1));
    int x = x_digits[i];
    if (x == 0) return 1;
    int j = 2 * i;
    int c = 0;
    int xl = x & _DIGIT2_MASK;
    int xh = x >> _DIGIT2_BITS;
    int m = 2 * xh * xl;
    int l = xl * xl + ((m & _DIGIT2_MASK) << _DIGIT2_BITS) + a_digits[j];
    c = (l >> _DIGIT_BITS) + (m >> _DIGIT2_BITS) + xh * xh;
    a_digits[j] = l & _DIGIT_MASK;
    x <<= 1;
    xl = x & _DIGIT2_MASK;
    xh = x >> _DIGIT2_BITS;
    int n = used - i - 1;
    int k = i + 1;
    j++;
    while (--n >= 0) {
      int l = x_digits[k] & _DIGIT2_MASK;
      int h = x_digits[k++] >> _DIGIT2_BITS;
      int m = xh * l + h * xl;
      l = xl * l + ((m & _DIGIT2_MASK) << _DIGIT2_BITS) + a_digits[j] + c;
      c = (l >> _DIGIT_BITS) + (m >> _DIGIT2_BITS) + xh * h;
      a_digits[j++] = l & _DIGIT_MASK;
    }
    c += a_digits[i + used];
    if (c >= _DIGIT_BASE) {
      a_digits[i + used] = c - _DIGIT_BASE;
      a_digits[i + used + 1] = 1;
    } else {
      a_digits[i + used] = c;
    }
    return 1;
  }

  // Return this * a.
  _Bigint _mul(_Bigint a) {
    // TODO(regis): Use karatsuba multiplication when appropriate.
    var used = _used;
    var a_used = a._used;
    if (used == 0 || a_used == 0) {
      return _ZERO;
    }
    var r_used = used + a_used;
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = new Uint32List(r_used + (r_used & 1));
    var i = 0;
    while (i < a_used) {
      i += _mulAdd(a_digits, i, digits, 0, r_digits, i, used);
    }
    return new _Bigint(_neg != a._neg, r_used, r_digits);
  }

  // r_digits[0..r_used-1] = x_digits[0..x_used-1]*a_digits[0..a_used-1].
  // Return r_used = x_used + a_used.
  static int _mulDigits(Uint32List x_digits, int x_used, Uint32List a_digits,
      int a_used, Uint32List r_digits) {
    var r_used = x_used + a_used;
    var i = r_used + (r_used & 1);
    assert(r_digits.length >= i);
    while (--i >= 0) {
      r_digits[i] = 0;
    }
    i = 0;
    while (i < a_used) {
      i += _mulAdd(a_digits, i, x_digits, 0, r_digits, i, x_used);
    }
    return r_used;
  }

  // Return this^2.
  _Bigint _sqr() {
    var used = _used;
    if (used == 0) {
      return _ZERO;
    }
    var r_used = 2 * used;
    var digits = _digits;
    var r_digits = new Uint32List(r_used);
    // Since r_used is even, no need for a leading zero for 64-bit processing.
    var i = 0;
    while (i < used - 1) {
      i += _sqrAdd(digits, i, r_digits, used);
    }
    // The last step is already done if digit pairs were processed above.
    if (i < used) {
      _mulAdd(digits, i, digits, i, r_digits, 2 * i, 1);
    }
    return new _Bigint(false, r_used, r_digits);
  }

  // r_digits[0..r_used-1] = x_digits[0..x_used-1]*x_digits[0..x_used-1].
  // Return r_used = 2*x_used.
  static int _sqrDigits(Uint32List x_digits, int x_used, Uint32List r_digits) {
    var r_used = 2 * x_used;
    assert(r_digits.length >= r_used);
    // Since r_used is even, no need for a leading zero for 64-bit processing.
    var i = r_used;
    while (--i >= 0) {
      r_digits[i] = 0;
    }
    i = 0;
    while (i < x_used - 1) {
      i += _sqrAdd(x_digits, i, r_digits, x_used);
    }
    // The last step is already done if digit pairs were processed above.
    if (i < x_used) {
      _mulAdd(x_digits, i, x_digits, i, r_digits, 2 * i, 1);
    }
    return r_used;
  }

  // Indices of the arguments of _estQuotientDigit.
  // For 64-bit processing by intrinsics on 64-bit platforms, the top digit pair
  // of divisor y is provided in the args array, and a 64-bit estimated quotient
  // is returned. However, on 32-bit platforms, the low 32-bit digit is ignored
  // and only one 32-bit digit is returned as the estimated quotient.
  static const int _YT_LO = 0; // Low digit of top digit pair of y, for 64-bit.
  static const int _YT = 1; // Top digit of divisor y.
  static const int _QD = 2; // Estimated quotient.
  static const int _QD_HI = 3; // High digit of estimated quotient, for 64-bit.

  // Operation:
  //   Estimate args[_QD] = digits[i-1..i] ~/ args[_YT]
  //   return 1
  // Note: Intrinsics on 64-bit platforms process a digit pair (i always odd):
  //   Estimate args[_QD.._QD_HI] = digits[i-3..i] ~/ args[_YT_LO.._YT]
  //   return 2
  static int _estQuotientDigit(Uint32List args, Uint32List digits, int i) {
    // Verify that digit pairs are accessible for 64-bit processing.
    assert(digits.length >= 4);
    if (digits[i] == args[_YT]) {
      args[_QD] = _DIGIT_MASK;
    } else {
      // Chop off one bit, since a Mint cannot hold 2 DIGITs.
      var qd = ((digits[i] << (_DIGIT_BITS - 1)) | (digits[i - 1] >> 1)) ~/
          (args[_YT] >> 1);
      if (qd > _DIGIT_MASK) {
        args[_QD] = _DIGIT_MASK;
      } else {
        args[_QD] = qd;
      }
    }
    return 1;
  }

  // Return trunc(this / a), a != 0.
  _Bigint _div(_Bigint a) {
    assert(a._used > 0);
    if (_used < a._used) {
      return _ZERO;
    }
    _divRem(a);
    // Return quotient, i.e.
    // _lastQuoRem_digits[_lastRem_used.._lastQuoRem_used-1] with proper sign.
    var lastQuo_used = _lastQuoRem_used - _lastRem_used;
    var quo_digits = _cloneDigits(
        _lastQuoRem_digits, _lastRem_used, _lastQuoRem_used, lastQuo_used);
    var quo = new _Bigint(false, lastQuo_used, quo_digits);
    if ((_neg != a._neg) && (quo._used > 0)) {
      quo = quo._negate();
    }
    return quo;
  }

  // Return this - a * trunc(this / a), a != 0.
  _Bigint _rem(_Bigint a) {
    assert(a._used > 0);
    if (_used < a._used) {
      return this;
    }
    _divRem(a);
    // Return remainder, i.e.
    // denormalized _lastQuoRem_digits[0.._lastRem_used-1] with proper sign.
    var rem_digits =
        _cloneDigits(_lastQuoRem_digits, 0, _lastRem_used, _lastRem_used);
    var rem = new _Bigint(false, _lastRem_used, rem_digits);
    if (_lastRem_nsh > 0) {
      rem = rem._rShift(_lastRem_nsh); // Denormalize remainder.
    }
    if (_neg && (rem._used > 0)) {
      rem = rem._negate();
    }
    return rem;
  }

  // Cache concatenated positive quotient and normalized positive remainder.
  void _divRem(_Bigint a) {
    // Check if result is already cached (identical on Bigint is too expensive).
    if ((this._used == _lastDividend_used) &&
        (a._used == _lastDivisor_used) &&
        identical(this._digits, _lastDividend_digits) &&
        identical(a._digits, _lastDivisor_digits)) {
      return;
    }
    var nsh = _DIGIT_BITS - _nbits(a._digits[a._used - 1]);
    // For 64-bit processing, make sure y has an even number of digits.
    if (a._used.isOdd) {
      nsh += _DIGIT_BITS;
    }
    // Concatenated positive quotient and normalized positive remainder.
    var r_digits;
    var r_used;
    // Normalized positive divisor.
    var y_digits;
    var y_used;
    if (nsh > 0) {
      y_digits = new Uint32List(a._used + 5); // +5 for norm. and 64-bit.
      y_used = _lShiftDigits(a._digits, a._used, nsh, y_digits);
      r_digits = new Uint32List(_used + 5); // +5 for normalization and 64-bit.
      r_used = _lShiftDigits(_digits, _used, nsh, r_digits);
    } else {
      y_digits = a._digits;
      y_used = a._used;
      r_digits = _cloneDigits(_digits, 0, _used, _used + 2);
      r_used = _used;
    }
    Uint32List yt_qd = new Uint32List(4);
    yt_qd[_YT_LO] = y_digits[y_used - 2];
    yt_qd[_YT] = y_digits[y_used - 1];
    // For 64-bit processing, make sure y_used, i, and j are even.
    assert(y_used.isEven);
    var i = r_used + (r_used & 1);
    var j = i - y_used;
    // t_digits is a temporary array of i digits.
    var t_digits = new Uint32List(i);
    var t_used = _dlShiftDigits(y_digits, y_used, j, t_digits);
    // Explicit first division step in case normalized dividend is larger or
    // equal to shifted normalized divisor.
    if (_compareDigits(r_digits, r_used, t_digits, t_used) >= 0) {
      assert(i == r_used);
      r_digits[r_used++] = 1; // Quotient = 1.
      // Subtract divisor from remainder.
      _absSub(r_digits, r_used, t_digits, t_used, r_digits);
    } else {
      // Account for possible carry in _mulAdd step.
      r_digits[r_used++] = 0;
    }
    r_digits[r_used] = 0; // Leading zero for 64-bit processing.
    // Negate y so we can later use _mulAdd instead of non-existent _mulSub.
    var ny_digits = new Uint32List(y_used + 2);
    ny_digits[y_used] = 1;
    _absSub(ny_digits, y_used + 1, y_digits, y_used, ny_digits);
    // ny_digits is read-only and has y_used digits (possibly including several
    // leading zeros) plus a leading zero for 64-bit processing.
    // r_digits is modified during iteration.
    // r_digits[0..y_used-1] is the current remainder.
    // r_digits[y_used..r_used-1] is the current quotient.
    --i;
    while (j > 0) {
      var d0 = _estQuotientDigit(yt_qd, r_digits, i);
      j -= d0;
      var d1 = _mulAdd(yt_qd, _QD, ny_digits, 0, r_digits, j, y_used);
      // _estQuotientDigit and _mulAdd must agree on the number of digits to
      // process.
      assert(d0 == d1);
      if (d0 == 1) {
        if (r_digits[i] < yt_qd[_QD]) {
          var t_used = _dlShiftDigits(ny_digits, y_used, j, t_digits);
          _absSub(r_digits, r_used, t_digits, t_used, r_digits);
          while (r_digits[i] < --yt_qd[_QD]) {
            _absSub(r_digits, r_used, t_digits, t_used, r_digits);
          }
        }
      } else {
        assert(d0 == 2);
        assert(r_digits[i] <= yt_qd[_QD_HI]);
        if ((r_digits[i] < yt_qd[_QD_HI]) || (r_digits[i - 1] < yt_qd[_QD])) {
          var t_used = _dlShiftDigits(ny_digits, y_used, j, t_digits);
          _absSub(r_digits, r_used, t_digits, t_used, r_digits);
          if (yt_qd[_QD] == 0) {
            --yt_qd[_QD_HI];
          }
          --yt_qd[_QD];
          assert(r_digits[i] <= yt_qd[_QD_HI]);
          while (
              (r_digits[i] < yt_qd[_QD_HI]) || (r_digits[i - 1] < yt_qd[_QD])) {
            _absSub(r_digits, r_used, t_digits, t_used, r_digits);
            if (yt_qd[_QD] == 0) {
              --yt_qd[_QD_HI];
            }
            --yt_qd[_QD];
            assert(r_digits[i] <= yt_qd[_QD_HI]);
          }
        }
      }
      i -= d0;
    }
    // Cache result.
    _lastDividend_digits = _digits;
    _lastDividend_used = _used;
    _lastDivisor_digits = a._digits;
    _lastDivisor_used = a._used;
    _lastQuoRem_digits = r_digits;
    _lastQuoRem_used = r_used;
    _lastRem_used = y_used;
    _lastRem_nsh = nsh;
  }

  // Customized version of _rem() minimizing allocations for use in reduction.
  // Input:
  //   x_digits[0..x_used-1]: positive dividend.
  //   y_digits[0..y_used-1]: normalized positive divisor.
  //   ny_digits[0..y_used-1]: negated y_digits.
  //   nsh: normalization shift amount.
  //   yt_qd: top y digit(s) and place holder for estimated quotient digit(s).
  //   t_digits: temp array of 2*y_used digits.
  //   r_digits: result digits array large enough to temporarily hold
  //             concatenated quotient and normalized remainder.
  // Output:
  //   r_digits[0..r_used-1]: positive remainder.
  // Returns r_used.
  static int _remDigits(
      Uint32List x_digits,
      int x_used,
      Uint32List y_digits,
      int y_used,
      Uint32List ny_digits,
      int nsh,
      Uint32List yt_qd,
      Uint32List t_digits,
      Uint32List r_digits) {
    // Initialize r_digits to normalized positive dividend.
    var r_used = _lShiftDigits(x_digits, x_used, nsh, r_digits);
    // For 64-bit processing, make sure y_used, i, and j are even.
    assert(y_used.isEven);
    var i = r_used + (r_used & 1);
    var j = i - y_used;
    var t_used = _dlShiftDigits(y_digits, y_used, j, t_digits);
    // Explicit first division step in case normalized dividend is larger or
    // equal to shifted normalized divisor.
    if (_compareDigits(r_digits, r_used, t_digits, t_used) >= 0) {
      assert(i == r_used);
      r_digits[r_used++] = 1; // Quotient = 1.
      // Subtract divisor from remainder.
      _absSub(r_digits, r_used, t_digits, t_used, r_digits);
    } else {
      // Account for possible carry in _mulAdd step.
      r_digits[r_used++] = 0;
    }
    r_digits[r_used] = 0; // Leading zero for 64-bit processing.
    // Negated y_digits passed in ny_digits allow the use of _mulAdd instead of
    // unimplemented _mulSub.
    // ny_digits is read-only and has y_used digits (possibly including several
    // leading zeros) plus a leading zero for 64-bit processing.
    // r_digits is modified during iteration.
    // r_digits[0..y_used-1] is the current remainder.
    // r_digits[y_used..r_used-1] is the current quotient.
    --i;
    while (j > 0) {
      var d0 = _estQuotientDigit(yt_qd, r_digits, i);
      j -= d0;
      var d1 = _mulAdd(yt_qd, _QD, ny_digits, 0, r_digits, j, y_used);
      // _estQuotientDigit and _mulAdd must agree on the number of digits to
      // process.
      assert(d0 == d1);
      if (d0 == 1) {
        if (r_digits[i] < yt_qd[_QD]) {
          var t_used = _dlShiftDigits(ny_digits, y_used, j, t_digits);
          _absSub(r_digits, r_used, t_digits, t_used, r_digits);
          while (r_digits[i] < --yt_qd[_QD]) {
            _absSub(r_digits, r_used, t_digits, t_used, r_digits);
          }
        }
      } else {
        assert(d0 == 2);
        assert(r_digits[i] <= yt_qd[_QD_HI]);
        if ((r_digits[i] < yt_qd[_QD_HI]) || (r_digits[i - 1] < yt_qd[_QD])) {
          var t_used = _dlShiftDigits(ny_digits, y_used, j, t_digits);
          _absSub(r_digits, r_used, t_digits, t_used, r_digits);
          if (yt_qd[_QD] == 0) {
            --yt_qd[_QD_HI];
          }
          --yt_qd[_QD];
          assert(r_digits[i] <= yt_qd[_QD_HI]);
          while (
              (r_digits[i] < yt_qd[_QD_HI]) || (r_digits[i - 1] < yt_qd[_QD])) {
            _absSub(r_digits, r_used, t_digits, t_used, r_digits);
            if (yt_qd[_QD] == 0) {
              --yt_qd[_QD_HI];
            }
            --yt_qd[_QD];
            assert(r_digits[i] <= yt_qd[_QD_HI]);
          }
        }
      }
      i -= d0;
    }
    // Return remainder, i.e. denormalized r_digits[0..y_used-1].
    r_used = y_used;
    if (nsh > 0) {
      // Denormalize remainder.
      r_used = _rShiftDigits(r_digits, r_used, nsh, r_digits);
    }
    return r_used;
  }

  int get hashCode => this;
  int get _identityHashCode => this;

  int operator ~() {
    return _not()._toValidInt();
  }

  int get bitLength {
    if (_used == 0) return 0;
    if (_neg) return (~this).bitLength;
    return _DIGIT_BITS * (_used - 1) + _nbits(_digits[_used - 1]);
  }

  // This method must support smi._toBigint()._shrFromInt(int).
  int _shrFromInt(int other) {
    if (_used == 0) return other; // Shift amount is zero.
    if (_neg) throw new RangeError.range(this, 0, null);
    assert(_DIGIT_BITS == 32); // Otherwise this code needs to be revised.
    var shift;
    if ((_used > 2) || ((_used == 2) && (_digits[1] > 0x10000000))) {
      if (other < 0) {
        return -1;
      } else {
        return 0;
      }
    } else {
      shift = ((_used == 2) ? (_digits[1] << _DIGIT_BITS) : 0) + _digits[0];
    }
    return other._toBigint()._rShift(shift)._toValidInt();
  }

  // This method must support smi._toBigint()._shlFromInt(int).
  // An out of memory exception is thrown if the result cannot be allocated.
  int _shlFromInt(int other) {
    if (_used == 0) return other; // Shift amount is zero.
    if (_neg) throw new RangeError.range(this, 0, null);
    assert(_DIGIT_BITS == 32); // Otherwise this code needs to be revised.
    var shift;
    if (_used > 2 || (_used == 2 && _digits[1] > 0x10000000)) {
      if (other == 0) return 0; // Shifted value is zero.
      throw new OutOfMemoryError();
    } else {
      shift = ((_used == 2) ? (_digits[1] << _DIGIT_BITS) : 0) + _digits[0];
    }
    return other._toBigint()._lShift(shift)._toValidInt();
  }

  // Overriden operators and methods.

  // The following operators override operators of _IntegerImplementation for
  // efficiency, but are not necessary for correctness. They shortcut native
  // calls that would return null because the receiver is _Bigint.
  num operator +(num other) {
    return other._toBigintOrDouble()._addFromInteger(this);
  }

  num operator -(num other) {
    return other._toBigintOrDouble()._subFromInteger(this);
  }

  num operator *(num other) {
    return other._toBigintOrDouble()._mulFromInteger(this);
  }

  num operator ~/(num other) {
    return other._toBigintOrDouble()._truncDivFromInteger(this);
  }

  num operator %(num other) {
    return other._toBigintOrDouble()._moduloFromInteger(this);
  }

  int operator &(int other) {
    return other._toBigintOrDouble()._bitAndFromInteger(this);
  }

  int operator |(int other) {
    return other._toBigintOrDouble()._bitOrFromInteger(this);
  }

  int operator ^(int other) {
    return other._toBigintOrDouble()._bitXorFromInteger(this);
  }

  int operator >>(int other) {
    return other._toBigintOrDouble()._shrFromInt(this);
  }

  int operator <<(int other) {
    return other._toBigintOrDouble()._shlFromInt(this);
  }
  // End of operator shortcuts.

  int operator -() {
    return _negate()._toValidInt();
  }

  int get sign {
    return (_used == 0) ? 0 : _neg ? -1 : 1;
  }

  bool get isEven => _used == 0 || (_digits[0] & 1) == 0;
  bool get isNegative => _neg;

  String _toPow2String(int radix) {
    if (_used == 0) return "0";
    assert(radix & (radix - 1) == 0);
    final bitsPerChar = radix.bitLength - 1;
    final firstcx = _neg ? 1 : 0; // Index of first char in str after the sign.
    final lastdx = _used - 1; // Index of last digit in bigint.
    final bitLength = lastdx * _DIGIT_BITS + _nbits(_digits[lastdx]);
    // Index of char in str. Initialize with str length.
    var cx = firstcx + (bitLength + bitsPerChar - 1) ~/ bitsPerChar;
    _OneByteString str = _OneByteString._allocate(cx);
    str._setAt(0, 0x2d); // '-'. Is overwritten if not negative.
    final mask = radix - 1;
    var dx = 0; // Digit index in bigint.
    var bx = 0; // Bit index in bigint digit.
    do {
      var ch;
      if (bx > (_DIGIT_BITS - bitsPerChar)) {
        ch = _digits[dx++] >> bx;
        bx += bitsPerChar - _DIGIT_BITS;
        if (dx <= lastdx) {
          ch |= (_digits[dx] & ((1 << bx) - 1)) << (bitsPerChar - bx);
        }
      } else {
        ch = (_digits[dx] >> bx) & mask;
        bx += bitsPerChar;
        if (bx >= _DIGIT_BITS) {
          bx -= _DIGIT_BITS;
          dx++;
        }
      }
      str._setAt(--cx, _IntegerImplementation._digits.codeUnitAt(ch));
    } while (cx > firstcx);
    return str;
  }

  int _bitAndFromSmi(int other) => _bitAndFromInteger(other);

  int _bitAndFromInteger(int other) {
    return other._toBigint()._and(this)._toValidInt();
  }

  int _bitOrFromInteger(int other) {
    return other._toBigint()._or(this)._toValidInt();
  }

  int _bitXorFromInteger(int other) {
    return other._toBigint()._xor(this)._toValidInt();
  }

  int _addFromInteger(int other) {
    return other._toBigint()._add(this)._toValidInt();
  }

  int _subFromInteger(int other) {
    return other._toBigint()._sub(this)._toValidInt();
  }

  int _mulFromInteger(int other) {
    return other._toBigint()._mul(this)._toValidInt();
  }

  int _truncDivFromInteger(int other) {
    if (_used == 0) {
      throw const IntegerDivisionByZeroException();
    }
    return other._toBigint()._div(this)._toValidInt();
  }

  int _moduloFromInteger(int other) {
    if (_used == 0) {
      throw const IntegerDivisionByZeroException();
    }
    _Bigint result = other._toBigint()._rem(this);
    if (result._neg) {
      if (_neg) {
        result = result._sub(this);
      } else {
        result = result._add(this);
      }
    }
    return result._toValidInt();
  }

  int _remainderFromInteger(int other) {
    if (_used == 0) {
      throw const IntegerDivisionByZeroException();
    }
    return other._toBigint()._rem(this)._toValidInt();
  }

  bool _greaterThanFromInteger(int other) {
    return other._toBigint()._compare(this) > 0;
  }

  bool _equalToInteger(int other) {
    return other._toBigint()._compare(this) == 0;
  }

  // Returns pow(this, e) % m, with e >= 0, m > 0.
  int modPow(int e, int m) {
    if (e is! int) {
      throw new ArgumentError.value(e, "exponent", "not an integer");
    }
    if (m is! int) {
      throw new ArgumentError.value(m, "modulus", "not an integer");
    }
    if (e < 0) throw new RangeError.range(e, 0, null, "exponent");
    if (m <= 0) throw new RangeError.range(m, 1, null, "modulus");
    if (e == 0) return 1;
    m = m._toBigint();
    final m_used = m._used;
    final m_used2p4 = 2 * m_used + 4;
    final e_bitlen = e.bitLength;
    if (e_bitlen <= 0) return 1;
    final bool cannotUseMontgomery = m.isEven || _abs() >= m;
    if (cannotUseMontgomery || e_bitlen < 64) {
      _Reduction z = (cannotUseMontgomery || e_bitlen < 8)
          ? new _Classic(m)
          : new _Montgomery(m);
      // TODO(regis): Should we use Barrett reduction for an even modulus and a
      // large exponent?
      var r_digits = new Uint32List(m_used2p4);
      var r2_digits = new Uint32List(m_used2p4);
      var g_digits = new Uint32List(m_used + (m_used & 1));
      var g_used = z._convert(this, g_digits);
      // Initialize r with g.
      var j = g_used + (g_used & 1); // Copy leading zero if any.
      while (--j >= 0) {
        r_digits[j] = g_digits[j];
      }
      var r_used = g_used;
      var r2_used;
      var i = e_bitlen - 1;
      while (--i >= 0) {
        r2_used = z._sqr(r_digits, r_used, r2_digits);
        if ((e & (1 << i)) != 0) {
          r_used = z._mul(r2_digits, r2_used, g_digits, g_used, r_digits);
        } else {
          var t_digits = r_digits;
          var t_used = r_used;
          r_digits = r2_digits;
          r_used = r2_used;
          r2_digits = t_digits;
          r2_used = t_used;
        }
      }
      return z._revert(r_digits, r_used)._toValidInt();
    }
    e = e._toBigint();
    var k;
    if (e_bitlen < 18)
      k = 1;
    else if (e_bitlen < 48)
      k = 3;
    else if (e_bitlen < 144)
      k = 4;
    else if (e_bitlen < 768)
      k = 5;
    else
      k = 6;
    _Reduction z = new _Montgomery(m);
    var n = 3;
    final k1 = k - 1;
    final km = (1 << k) - 1;
    List g_digits = new List(km + 1);
    List g_used = new List(km + 1);
    g_digits[1] = new Uint32List(m_used + (m_used & 1));
    g_used[1] = z._convert(this, g_digits[1]);
    if (k > 1) {
      var g2_digits = new Uint32List(m_used2p4);
      var g2_used = z._sqr(g_digits[1], g_used[1], g2_digits);
      while (n <= km) {
        g_digits[n] = new Uint32List(m_used2p4);
        g_used[n] = z._mul(
            g2_digits, g2_used, g_digits[n - 2], g_used[n - 2], g_digits[n]);
        n += 2;
      }
    }
    var w;
    var is1 = true;
    var r_digits = _ONE._digits;
    var r_used = _ONE._used;
    var r2_digits = new Uint32List(m_used2p4);
    var r2_used;
    var e_digits = e._digits;
    var j = e._used - 1;
    var i = _nbits(e_digits[j]) - 1;
    while (j >= 0) {
      if (i >= k1) {
        w = (e_digits[j] >> (i - k1)) & km;
      } else {
        w = (e_digits[j] & ((1 << (i + 1)) - 1)) << (k1 - i);
        if (j > 0) {
          w |= e_digits[j - 1] >> (_DIGIT_BITS + i - k1);
        }
      }
      n = k;
      while ((w & 1) == 0) {
        w >>= 1;
        --n;
      }
      if ((i -= n) < 0) {
        i += _DIGIT_BITS;
        --j;
      }
      if (is1) {
        // r == 1, don't bother squaring or multiplying it.
        r_digits = new Uint32List(m_used2p4);
        r_used = g_used[w];
        var gw_digits = g_digits[w];
        var ri = r_used + (r_used & 1); // Copy leading zero if any.
        while (--ri >= 0) {
          r_digits[ri] = gw_digits[ri];
        }
        is1 = false;
      } else {
        while (n > 1) {
          r2_used = z._sqr(r_digits, r_used, r2_digits);
          r_used = z._sqr(r2_digits, r2_used, r_digits);
          n -= 2;
        }
        if (n > 0) {
          r2_used = z._sqr(r_digits, r_used, r2_digits);
        } else {
          var t_digits = r_digits;
          var t_used = r_used;
          r_digits = r2_digits;
          r_used = r2_used;
          r2_digits = t_digits;
          r2_used = t_used;
        }
        r_used = z._mul(r2_digits, r2_used, g_digits[w], g_used[w], r_digits);
      }
      while (j >= 0 && (e_digits[j] & (1 << i)) == 0) {
        r2_used = z._sqr(r_digits, r_used, r2_digits);
        var t_digits = r_digits;
        var t_used = r_used;
        r_digits = r2_digits;
        r_used = r2_used;
        r2_digits = t_digits;
        r2_used = t_used;
        if (--i < 0) {
          i = _DIGIT_BITS - 1;
          --j;
        }
      }
    }
    assert(!is1);
    return z._revert(r_digits, r_used)._toValidInt();
  }

  // If inv is false, returns gcd(x, y).
  // If inv is true and gcd(x, y) = 1, returns d, so that c*x + d*y = 1.
  // If inv is true and gcd(x, y) != 1, throws Exception("Not coprime").
  static int _binaryGcd(_Bigint x, _Bigint y, bool inv) {
    var x_digits = x._digits;
    var y_digits = y._digits;
    var x_used = x._used;
    var y_used = y._used;
    var m_used = x_used > y_used ? x_used : y_used;
    final m_len = m_used + (m_used & 1);
    x_digits = _cloneDigits(x_digits, 0, x_used, m_len);
    y_digits = _cloneDigits(y_digits, 0, y_used, m_len);
    int s = 0;
    if (inv) {
      if ((y_used == 1) && (y_digits[0] == 1)) return 1;
      if ((y_used == 0) || (y_digits[0].isEven && x_digits[0].isEven)) {
        throw new Exception("Not coprime");
      }
    } else {
      if (x_used == 0) {
        throw new ArgumentError.value(0, "this", "must not be zero");
      }
      if (y_used == 0) {
        throw new ArgumentError.value(0, "other", "must not be zero");
      }
      if (((x_used == 1) && (x_digits[0] == 1)) ||
          ((y_used == 1) && (y_digits[0] == 1))) return 1;
      bool xy_cloned = false;
      while (((x_digits[0] & 1) == 0) && ((y_digits[0] & 1) == 0)) {
        _rsh(x_digits, x_used, 1, x_digits);
        _rsh(y_digits, y_used, 1, y_digits);
        s++;
      }
      if (s >= _DIGIT_BITS) {
        var sd = s >> _LOG2_DIGIT_BITS;
        x_used -= sd;
        y_used -= sd;
        m_used -= sd;
      }
      if ((y_digits[0] & 1) == 1) {
        var t_digits = x_digits;
        var t_used = x_used;
        x_digits = y_digits;
        x_used = y_used;
        y_digits = t_digits;
        y_used = t_used;
      }
    }
    var u_digits = _cloneDigits(x_digits, 0, x_used, m_len);
    var v_digits = _cloneDigits(y_digits, 0, y_used, m_len + 2); // +2 for lsh.
    final bool ac = (x_digits[0] & 1) == 0;

    // Variables a, b, c, and d require one more digit.
    final abcd_used = m_used + 1;
    final abcd_len = abcd_used + (abcd_used & 1) + 2; // +2 to satisfy _absAdd.
    var a_digits, b_digits, c_digits, d_digits;
    bool a_neg, b_neg, c_neg, d_neg;
    if (ac) {
      a_digits = new Uint32List(abcd_len);
      a_neg = false;
      a_digits[0] = 1;
      c_digits = new Uint32List(abcd_len);
      c_neg = false;
    }
    b_digits = new Uint32List(abcd_len);
    b_neg = false;
    d_digits = new Uint32List(abcd_len);
    d_neg = false;
    d_digits[0] = 1;

    while (true) {
      while ((u_digits[0] & 1) == 0) {
        _rsh(u_digits, m_used, 1, u_digits);
        if (ac) {
          if (((a_digits[0] & 1) == 1) || ((b_digits[0] & 1) == 1)) {
            if (a_neg) {
              if ((a_digits[m_used] != 0) ||
                  (_compareDigits(a_digits, m_used, y_digits, m_used)) > 0) {
                _absSub(a_digits, abcd_used, y_digits, m_used, a_digits);
              } else {
                _absSub(y_digits, m_used, a_digits, m_used, a_digits);
                a_neg = false;
              }
            } else {
              _absAdd(a_digits, abcd_used, y_digits, m_used, a_digits);
            }
            if (b_neg) {
              _absAdd(b_digits, abcd_used, x_digits, m_used, b_digits);
            } else if ((b_digits[m_used] != 0) ||
                (_compareDigits(b_digits, m_used, x_digits, m_used) > 0)) {
              _absSub(b_digits, abcd_used, x_digits, m_used, b_digits);
            } else {
              _absSub(x_digits, m_used, b_digits, m_used, b_digits);
              b_neg = true;
            }
          }
          _rsh(a_digits, abcd_used, 1, a_digits);
        } else if ((b_digits[0] & 1) == 1) {
          if (b_neg) {
            _absAdd(b_digits, abcd_used, x_digits, m_used, b_digits);
          } else if ((b_digits[m_used] != 0) ||
              (_compareDigits(b_digits, m_used, x_digits, m_used) > 0)) {
            _absSub(b_digits, abcd_used, x_digits, m_used, b_digits);
          } else {
            _absSub(x_digits, m_used, b_digits, m_used, b_digits);
            b_neg = true;
          }
        }
        _rsh(b_digits, abcd_used, 1, b_digits);
      }
      while ((v_digits[0] & 1) == 0) {
        _rsh(v_digits, m_used, 1, v_digits);
        if (ac) {
          if (((c_digits[0] & 1) == 1) || ((d_digits[0] & 1) == 1)) {
            if (c_neg) {
              if ((c_digits[m_used] != 0) ||
                  (_compareDigits(c_digits, m_used, y_digits, m_used) > 0)) {
                _absSub(c_digits, abcd_used, y_digits, m_used, c_digits);
              } else {
                _absSub(y_digits, m_used, c_digits, m_used, c_digits);
                c_neg = false;
              }
            } else {
              _absAdd(c_digits, abcd_used, y_digits, m_used, c_digits);
            }
            if (d_neg) {
              _absAdd(d_digits, abcd_used, x_digits, m_used, d_digits);
            } else if ((d_digits[m_used] != 0) ||
                (_compareDigits(d_digits, m_used, x_digits, m_used) > 0)) {
              _absSub(d_digits, abcd_used, x_digits, m_used, d_digits);
            } else {
              _absSub(x_digits, m_used, d_digits, m_used, d_digits);
              d_neg = true;
            }
          }
          _rsh(c_digits, abcd_used, 1, c_digits);
        } else if ((d_digits[0] & 1) == 1) {
          if (d_neg) {
            _absAdd(d_digits, abcd_used, x_digits, m_used, d_digits);
          } else if ((d_digits[m_used] != 0) ||
              (_compareDigits(d_digits, m_used, x_digits, m_used) > 0)) {
            _absSub(d_digits, abcd_used, x_digits, m_used, d_digits);
          } else {
            _absSub(x_digits, m_used, d_digits, m_used, d_digits);
            d_neg = true;
          }
        }
        _rsh(d_digits, abcd_used, 1, d_digits);
      }
      if (_compareDigits(u_digits, m_used, v_digits, m_used) >= 0) {
        _absSub(u_digits, m_used, v_digits, m_used, u_digits);
        if (ac) {
          if (a_neg == c_neg) {
            var a_cmp_c =
                _compareDigits(a_digits, abcd_used, c_digits, abcd_used);
            if (a_cmp_c > 0) {
              _absSub(a_digits, abcd_used, c_digits, abcd_used, a_digits);
            } else {
              _absSub(c_digits, abcd_used, a_digits, abcd_used, a_digits);
              a_neg = !a_neg && (a_cmp_c != 0);
            }
          } else {
            _absAdd(a_digits, abcd_used, c_digits, abcd_used, a_digits);
          }
        }
        if (b_neg == d_neg) {
          var b_cmp_d =
              _compareDigits(b_digits, abcd_used, d_digits, abcd_used);
          if (b_cmp_d > 0) {
            _absSub(b_digits, abcd_used, d_digits, abcd_used, b_digits);
          } else {
            _absSub(d_digits, abcd_used, b_digits, abcd_used, b_digits);
            b_neg = !b_neg && (b_cmp_d != 0);
          }
        } else {
          _absAdd(b_digits, abcd_used, d_digits, abcd_used, b_digits);
        }
      } else {
        _absSub(v_digits, m_used, u_digits, m_used, v_digits);
        if (ac) {
          if (c_neg == a_neg) {
            var c_cmp_a =
                _compareDigits(c_digits, abcd_used, a_digits, abcd_used);
            if (c_cmp_a > 0) {
              _absSub(c_digits, abcd_used, a_digits, abcd_used, c_digits);
            } else {
              _absSub(a_digits, abcd_used, c_digits, abcd_used, c_digits);
              c_neg = !c_neg && (c_cmp_a != 0);
            }
          } else {
            _absAdd(c_digits, abcd_used, a_digits, abcd_used, c_digits);
          }
        }
        if (d_neg == b_neg) {
          var d_cmp_b =
              _compareDigits(d_digits, abcd_used, b_digits, abcd_used);
          if (d_cmp_b > 0) {
            _absSub(d_digits, abcd_used, b_digits, abcd_used, d_digits);
          } else {
            _absSub(b_digits, abcd_used, d_digits, abcd_used, d_digits);
            d_neg = !d_neg && (d_cmp_b != 0);
          }
        } else {
          _absAdd(d_digits, abcd_used, b_digits, abcd_used, d_digits);
        }
      }
      // Exit loop if u == 0.
      var i = m_used;
      while ((i > 0) && (u_digits[i - 1] == 0)) --i;
      if (i == 0) break;
    }
    if (!inv) {
      if (s > 0) {
        m_used = _lShiftDigits(v_digits, m_used, s, v_digits);
      }
      return new _Bigint(false, m_used, v_digits)._toValidInt();
    }
    // No inverse if v != 1.
    var i = m_used - 1;
    while ((i > 0) && (v_digits[i] == 0)) --i;
    if ((i != 0) || (v_digits[0] != 1)) {
      throw new Exception("Not coprime");
    }

    if (d_neg) {
      if ((d_digits[m_used] != 0) ||
          (_compareDigits(d_digits, m_used, x_digits, m_used) > 0)) {
        _absSub(d_digits, abcd_used, x_digits, m_used, d_digits);
        if ((d_digits[m_used] != 0) ||
            (_compareDigits(d_digits, m_used, x_digits, m_used) > 0)) {
          _absSub(d_digits, abcd_used, x_digits, m_used, d_digits);
        } else {
          _absSub(x_digits, m_used, d_digits, m_used, d_digits);
          d_neg = false;
        }
      } else {
        _absSub(x_digits, m_used, d_digits, m_used, d_digits);
        d_neg = false;
      }
    } else if ((d_digits[m_used] != 0) ||
        (_compareDigits(d_digits, m_used, x_digits, m_used) > 0)) {
      _absSub(d_digits, abcd_used, x_digits, m_used, d_digits);
      if ((d_digits[m_used] != 0) ||
          (_compareDigits(d_digits, m_used, x_digits, m_used) > 0)) {
        _absSub(d_digits, abcd_used, x_digits, m_used, d_digits);
      }
    }
    return new _Bigint(false, m_used, d_digits)._toValidInt();
  }

  // Returns 1/this % m, with m > 0.
  int modInverse(int m) {
    if (m is! int) {
      throw new ArgumentError.value(m, "modulus", "not an integer");
    }
    if (m <= 0) throw new RangeError.range(m, 1, null, "modulus");
    if (m == 1) return 0;
    m = m._toBigint();
    var t = this;
    if (t._neg || (t._absCompare(m) >= 0)) {
      t %= m;
      t = t._toBigint();
    }
    return _binaryGcd(m, t, true);
  }

  // Returns gcd of abs(this) and abs(other).
  int gcd(int other) {
    if (other is! int) {
      throw new ArgumentError.value(other, "other", "not an integer");
    }
    if (other == 0) {
      return this.abs();
    }
    return _binaryGcd(this, other._toBigint(), false);
  }
}

// Interface for modular reduction.
class _Reduction {
  // Return the number of digits used by r_digits.
  int _convert(_Bigint x, Uint32List r_digits);
  int _mul(Uint32List x_digits, int x_used, Uint32List y_digits, int y_used,
      Uint32List r_digits);
  int _sqr(Uint32List x_digits, int x_used, Uint32List r_digits);

  // Return x reverted to _Bigint.
  _Bigint _revert(Uint32List x_digits, int x_used);
}

// Montgomery reduction on _Bigint.
class _Montgomery implements _Reduction {
  _Bigint _m; // Modulus.
  int _mused2p2;
  Uint32List _args;
  int _digits_per_step; // Number of digits processed in one step. 1 or 2.
  static const int _X = 0; // Index of x.
  static const int _X_HI = 1; // Index of high 32-bits of x (64-bit only).
  static const int _RHO = 2; // Index of rho.
  static const int _RHO_HI = 3; // Index of high 32-bits of rho (64-bit only).
  static const int _MU = 4; // Index of mu.
  static const int _MU_HI = 5; // Index of high 32-bits of mu (64-bit only).

  _Montgomery(m) {
    _m = m._toBigint();
    _mused2p2 = 2 * _m._used + 2;
    _args = new Uint32List(6);
    // Determine if we can process digit pairs by calling an intrinsic.
    _digits_per_step = _mulMod(_args, _args, 0);
    _args[_X] = _m._digits[0];
    if (_digits_per_step == 1) {
      _invDigit(_args);
    } else {
      assert(_digits_per_step == 2);
      _args[_X_HI] = _m._digits[1];
      _invDigitPair(_args);
    }
  }

  // Calculates -1/x % _DIGIT_BASE, x is 32-bit digit.
  //         xy == 1 (mod m)
  //         xy =  1+km
  //   xy(2-xy) = (1+km)(1-km)
  // x(y(2-xy)) = 1-k^2 m^2
  // x(y(2-xy)) == 1 (mod m^2)
  // if y is 1/x mod m, then y(2-xy) is 1/x mod m^2
  // Should reduce x and y(2-xy) by m^2 at each step to keep size bounded.
  //
  // Operation:
  //   args[_RHO] = 1/args[_X] mod _DIGIT_BASE.
  static void _invDigit(Uint32List args) {
    var x = args[_X];
    var y = x & 3; // y == 1/x mod 2^2
    y = (y * (2 - (x & 0xf) * y)) & 0xf; // y == 1/x mod 2^4
    y = (y * (2 - (x & 0xff) * y)) & 0xff; // y == 1/x mod 2^8
    y = (y * (2 - (((x & 0xffff) * y) & 0xffff))) & 0xffff; // y == 1/x mod 2^16
    // Last step - calculate inverse mod _DIGIT_BASE directly;
    // Assumes 16 < _DIGIT_BITS <= 32 and assumes ability to handle 48-bit ints.
    y = (y * (2 - x * y % _Bigint._DIGIT_BASE)) % _Bigint._DIGIT_BASE;
    // y == 1/x mod _DIGIT_BASE
    y = -y; // We really want the negative inverse.
    args[_RHO] = y & _Bigint._DIGIT_MASK;
  }

  // Calculates -1/x % _DIGIT_BASE^2, x is a pair of 32-bit digits.
  // Operation:
  //   args[_RHO.._RHO_HI] = 1/args[_X.._X_HI] mod _DIGIT_BASE^2.
  static void _invDigitPair(Uint32List args) {
    var xl = args[_X]; // Lower 32-bit digit of x.
    var y = xl & 3; // y == 1/x mod 2^2
    y = (y * (2 - (xl & 0xf) * y)) & 0xf; // y == 1/x mod 2^4
    y = (y * (2 - (xl & 0xff) * y)) & 0xff; // y == 1/x mod 2^8
    y = (y * (2 - (((xl & 0xffff) * y) & 0xffff))) &
        0xffff; // y == 1/x mod 2^16
    y = (y * (2 - ((xl * y) & 0xffffffff))) & 0xffffffff; // y == 1/x mod 2^32
    var x = (args[_X_HI] << _Bigint._DIGIT_BITS) | xl;
    y = (y * (2 - ((x * y) & _Bigint._TWO_DIGITS_MASK))) &
        _Bigint._TWO_DIGITS_MASK;
    // y == 1/x mod _DIGIT_BASE^2
    y = -y; // We really want the negative inverse.
    args[_RHO] = y & _Bigint._DIGIT_MASK;
    args[_RHO_HI] = (y >> _Bigint._DIGIT_BITS) & _Bigint._DIGIT_MASK;
  }

  // Operation:
  //   args[_MU] = args[_RHO]*digits[i] mod _DIGIT_BASE.
  //   return 1.
  // Note: Intrinsics on 64-bit platforms process digit pairs at even indices:
  //   args[_MU.._MU_HI] = args[_RHO.._RHO_HI]*digits[i..i+1] mod _DIGIT_BASE^2.
  //   return 2.
  static int _mulMod(Uint32List args, Uint32List digits, int i) {
    // Verify that digit pairs are accessible for 64-bit processing.
    assert(digits.length > (i | 1));
    const int MU_MASK = (1 << (_Bigint._DIGIT_BITS - _Bigint._DIGIT2_BITS)) - 1;
    var rhol = args[_RHO] & _Bigint._DIGIT2_MASK;
    var rhoh = args[_RHO] >> _Bigint._DIGIT2_BITS;
    var dh = digits[i] >> _Bigint._DIGIT2_BITS;
    var dl = digits[i] & _Bigint._DIGIT2_MASK;
    args[_MU] = (dl * rhol +
            (((dl * rhoh + dh * rhol) & MU_MASK) << _Bigint._DIGIT2_BITS)) &
        _Bigint._DIGIT_MASK;
    return 1;
  }

  // r = x*R mod _m.
  // Return r_used.
  int _convert(_Bigint x, Uint32List r_digits) {
    // Montgomery reduction only works if abs(x) < _m.
    assert(x._abs() < _m);
    var r = x._abs()._dlShift(_m._used)._rem(_m);
    if (x._neg && !r._neg && r._used > 0) {
      r = _m._sub(r);
    }
    var used = r._used;
    var digits = r._digits;
    var i = used + (used & 1);
    while (--i >= 0) {
      r_digits[i] = digits[i];
    }
    return used;
  }

  _Bigint _revert(Uint32List x_digits, int x_used) {
    var r_digits = new Uint32List(_mused2p2);
    var i = x_used + (x_used & 1);
    while (--i >= 0) {
      r_digits[i] = x_digits[i];
    }
    var r_used = _reduce(r_digits, x_used);
    return new _Bigint(false, r_used, r_digits);
  }

  // x = x/R mod _m.
  // Return x_used.
  int _reduce(Uint32List x_digits, int x_used) {
    while (x_used < _mused2p2) {
      // Pad x so _mulAdd has enough room later.
      x_digits[x_used++] = 0;
    }
    var m_used = _m._used;
    var m_digits = _m._digits;
    var i = 0;
    while (i < m_used) {
      var d = _mulMod(_args, x_digits, i);
      assert(d == _digits_per_step);
      d = _Bigint._mulAdd(_args, _MU, m_digits, 0, x_digits, i, m_used);
      assert(d == _digits_per_step);
      i += d;
    }
    // Clamp x.
    while (x_used > 0 && x_digits[x_used - 1] == 0) {
      --x_used;
    }
    // Shift right by m_used digits or, if processing pairs, by i (even) digits.
    x_used = _Bigint._drShiftDigits(x_digits, x_used, i, x_digits);
    if (_Bigint._compareDigits(x_digits, x_used, m_digits, m_used) >= 0) {
      _Bigint._absSub(x_digits, x_used, m_digits, m_used, x_digits);
    }
    // Clamp x.
    while (x_used > 0 && x_digits[x_used - 1] == 0) {
      --x_used;
    }
    return x_used;
  }

  int _sqr(Uint32List x_digits, int x_used, Uint32List r_digits) {
    var r_used = _Bigint._sqrDigits(x_digits, x_used, r_digits);
    return _reduce(r_digits, r_used);
  }

  int _mul(Uint32List x_digits, int x_used, Uint32List y_digits, int y_used,
      Uint32List r_digits) {
    var r_used =
        _Bigint._mulDigits(x_digits, x_used, y_digits, y_used, r_digits);
    return _reduce(r_digits, r_used);
  }
}

// Modular reduction using "classic" algorithm.
class _Classic implements _Reduction {
  _Bigint _m; // Modulus.
  _Bigint _norm_m; // Normalized _m.
  Uint32List _neg_norm_m_digits; // Negated _norm_m digits.
  int _m_nsh; // Normalization shift amount.
  Uint32List _mt_qd; // Top _norm_m digit(s) and place holder for
  // estimated quotient digit(s).
  Uint32List _t_digits; // Temporary digits used during reduction.

  _Classic(int m) {
    _m = m._toBigint();
    // Preprocess arguments to _remDigits.
    var nsh = _Bigint._DIGIT_BITS - _Bigint._nbits(_m._digits[_m._used - 1]);
    // For 64-bit processing, make sure _norm_m_digits has an even number of
    // digits.
    if (_m._used.isOdd) {
      nsh += _Bigint._DIGIT_BITS;
    }
    _m_nsh = nsh;
    _norm_m = _m._lShift(nsh);
    var nm_used = _norm_m._used;
    assert(nm_used.isEven);
    _mt_qd = new Uint32List(4);
    _mt_qd[_Bigint._YT_LO] = _norm_m._digits[nm_used - 2];
    _mt_qd[_Bigint._YT] = _norm_m._digits[nm_used - 1];
    // Negate _norm_m so we can use _mulAdd instead of unimplemented _mulSub.
    var neg_norm_m = _Bigint._ONE._dlShift(nm_used)._sub(_norm_m);
    if (neg_norm_m._used < nm_used) {
      _neg_norm_m_digits =
          _Bigint._cloneDigits(neg_norm_m._digits, 0, nm_used, nm_used);
    } else {
      _neg_norm_m_digits = neg_norm_m._digits;
    }
    // _neg_norm_m_digits is read-only and has nm_used digits (possibly
    // including several leading zeros) plus a leading zero for 64-bit
    // processing.
    _t_digits = new Uint32List(2 * nm_used);
  }

  int _convert(_Bigint x, Uint32List r_digits) {
    var digits;
    var used;
    if (x._neg || x._compare(_m) >= 0) {
      var r = x._rem(_m);
      if (x._neg && !r._neg && r._used > 0) {
        r = _m._sub(r);
      }
      assert(!r._neg);
      used = r._used;
      digits = r._digits;
    } else {
      used = x._used;
      digits = x._digits;
    }
    var i = used + (used & 1); // Copy leading zero if any.
    while (--i >= 0) {
      r_digits[i] = digits[i];
    }
    return used;
  }

  _Bigint _revert(Uint32List x_digits, int x_used) {
    return new _Bigint(false, x_used, x_digits);
  }

  int _reduce(Uint32List x_digits, int x_used) {
    if (x_used < _m._used) {
      return x_used;
    }
    // The function _remDigits(...) is optimized for reduction and equivalent to
    // calling _convert(_revert(x_digits, x_used)._rem(_m), x_digits);
    return _Bigint._remDigits(x_digits, x_used, _norm_m._digits, _norm_m._used,
        _neg_norm_m_digits, _m_nsh, _mt_qd, _t_digits, x_digits);
  }

  int _sqr(Uint32List x_digits, int x_used, Uint32List r_digits) {
    var r_used = _Bigint._sqrDigits(x_digits, x_used, r_digits);
    return _reduce(r_digits, r_used);
  }

  int _mul(Uint32List x_digits, int x_used, Uint32List y_digits, int y_used,
      Uint32List r_digits) {
    var r_used =
        _Bigint._mulDigits(x_digits, x_used, y_digits, y_used, r_digits);
    return _reduce(r_digits, r_used);
  }
}
