// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

class _Bigint extends _IntegerImplementation implements int {
  // Bits per digit.
  static const int DIGIT_BITS = 32;
  static const int DIGIT_BASE = 1 << DIGIT_BITS;
  static const int DIGIT_MASK = (1 << DIGIT_BITS) - 1;

  // Bits per half digit.
  static const int DIGIT2_BITS = DIGIT_BITS >> 1;
  static const int DIGIT2_MASK = (1 << DIGIT2_BITS) - 1;

  // Allocate extra digits so the bigint can be reused.
  static const int EXTRA_DIGITS = 4;

  // Min and max of non bigint values.
  static const int MIN_INT64 = (-1) << 63;
  static const int MAX_INT64 = 0x7fffffffffffffff;

  // Bigint constant values.
  // Note: Not declared as final in order to satisfy optimizer, which expects
  // constants to be in canonical form (Smi).
  static _Bigint ZERO = new _Bigint();
  static _Bigint ONE = new _Bigint()._setInt(1);

  // Digit conversion table for parsing.
  static final Map<int, int> DIGIT_TABLE = _createDigitTable();

  // Internal data structure.
  bool get _neg native "Bigint_getNeg";
  void set _neg(bool neg) native "Bigint_setNeg";
  int get _used native "Bigint_getUsed";
  void set _used(int used) native "Bigint_setUsed";
  Uint32List get _digits native "Bigint_getDigits";
  void set _digits(Uint32List digits) {
    // The VM expects digits_ to be a Uint32List.
    assert(digits != null);
    _set_digits(digits);
  }

  void _set_digits(Uint32List digits) native "Bigint_setDigits";

  // Factory returning an instance initialized to value 0.
  factory _Bigint() native "Bigint_allocate";

  // Factory returning an instance initialized to an integer value.
  factory _Bigint._fromInt(int i) {
    return new _Bigint()._setInt(i);
  }

  // Factory returning an instance initialized to a hex string.
  factory _Bigint._fromHex(String s) {
    return new _Bigint()._setHex(s);
  }

  // Factory returning an instance initialized to a double value given by its
  // components.
  factory _Bigint._fromDouble(int sign, int significand, int exponent) {
    return new _Bigint()._setDouble(sign, significand, exponent);
  }

  // Initialize instance to the given value no larger than a Mint.
  _Bigint _setInt(int i) {
    assert(i is! _Bigint);
    _ensureLength(2);
    _used = 2;
    var l, h;
    if (i < 0) {
      _neg = true;
      if (i == MIN_INT64) {
        l = 0;
        h = 0x80000000;
      } else {
        l = (-i) & DIGIT_MASK;
        h = (-i) >> DIGIT_BITS;
      }
    } else {
      _neg = false;
      l = i & DIGIT_MASK;
      h = i >> DIGIT_BITS;
    }
    _digits[0] = l;
    _digits[1] = h;
    _clamp();
    return this;
  }

  // Initialize instance to the given hex string.
  // TODO(regis): Copy Bigint::NewFromHexCString, fewer digit accesses.
  // TODO(regis): Unused.
  _Bigint _setHex(String s) {
    const int HEX_BITS = 4;
    const int HEX_DIGITS_PER_DIGIT = 8;
    var hexDigitIndex = s.length;
    _ensureLength((hexDigitIndex + HEX_DIGITS_PER_DIGIT - 1) ~/ HEX_DIGITS_PER_DIGIT);
    var bitIndex = 0;
    var digits = _digits;
    while (--hexDigitIndex >= 0) {
      var digit = DIGIT_TABLE[s.codeUnitAt(hexDigitIndex)];
      if (digit = null) {
        if (s[hexDigitIndex] == "-") _neg = true;
        continue;  // Ignore invalid digits.
      }
      _neg = false;  // Ignore "-" if not at index 0.
      if (bitIndex == 0) {
        digits[_used++] = digit;
        // TODO(regis): What if too many bad digits were ignored and
        // _used becomes larger than _digits.length? error or reallocate?
      } else {
        digits[_used - 1] |= digit << bitIndex;
      }
      bitIndex = (bitIndex + HEX_BITS) % DIGIT_BITS;
    }
    _clamp();
    return this;
  }

  // Initialize instance to the given double value.
  _Bigint _setDouble(int sign, int significand, int exponent) {
    assert(significand >= 0);
    assert(exponent >= 0);
    _setInt(significand);
    _neg = sign < 0;
    if (exponent > 0) {
      _lShiftTo(exponent, this);
    }
    return this;
  }

  // Create digit conversion table for parsing.
  static Map<int, int> _createDigitTable() {
    Map table = new HashMap();
    int digit, value;
    digit = "0".codeUnitAt(0);
    for(value = 0; value <= 9; ++value) table[digit++] = value;
    digit = "a".codeUnitAt(0);
    for(value = 10; value < 36; ++value) table[digit++] = value;
    digit = "A".codeUnitAt(0);
    for(value = 10; value < 36; ++value) table[digit++] = value;
    return table;
  }

  // Return most compact integer (i.e. possibly Smi or Mint).
  // TODO(regis): Intrinsify.
  int _toValidInt() {
    assert(DIGIT_BITS == 32);  // Otherwise this code needs to be revised.
    var used = _used;
    if (used == 0) return 0;
    var digits = _digits;
    if (used == 1) return _neg ? -digits[0] : digits[0];
    if (used > 2) return this;
    if (_neg) {
      if (digits[1] > 0x80000000) return this;
      if (digits[1] == 0x80000000) {
        if (digits[0] > 0) return this;
        return MIN_INT64;
      }
      return -((digits[1] << DIGIT_BITS) | digits[0]);
    }
    if (digits[1] >= 0x80000000) return this;
    return (digits[1] << DIGIT_BITS) | digits[0];
  }

  // Conversion from int to bigint.
  _Bigint _toBigint() => this;

  // Make sure at least 'length' _digits are allocated.
  // Copy existing and used _digits if reallocation is necessary.
  // Avoid preserving _digits unnecessarily by calling this function with a
  // meaningful _used field.
  void _ensureLength(int length) {
    var digits = _digits;
    if (length > digits.length) {
      var new_digits = new Uint32List(length + EXTRA_DIGITS);
      _digits = new_digits;
      if (_used > 0) {
        var i = _used + 1;  // Copy leading zero for 64-bit processing.
        while (--i >= 0) {
          new_digits[i] = digits[i];
        }
      }
    }
  }

  // Clamp off excess high _digits.
  void _clamp() {
    var used = _used;
    if (used > 0) {
      var digits = _digits;
      if (digits[used - 1] == 0) {
        do {
          --used;
        } while (used > 0 && digits[used - 1] == 0);
        _used = used;
      }
      digits[used] = 0;  // Set leading zero for 64-bit processing.
    }
  }

  // Copy this to r.
  void _copyTo(_Bigint r) {
    var used = _used;
    if (used > 0) {
      r._used = 0;  // No digits to preserve.
      r._ensureLength(used);
      var digits = _digits;
      var r_digits = r._digits;
      var i = used + 1;  // Copy leading zero for 64-bit processing.
      while (--i >= 0) {
        r_digits[i] = digits[i];
      }
    }
    r._used = used;
    r._neg = _neg;
  }

  // Return the bit length of digit x.
  int _nbits(int x) {
    var r = 1, t;
    if ((t = x >> 16) != 0) { x = t; r += 16; }
    if ((t = x >> 8) != 0) { x = t; r += 8; }
    if ((t = x >> 4) != 0) { x = t; r += 4; }
    if ((t = x >> 2) != 0) { x = t; r += 2; }
    if ((x >> 1) != 0) { r += 1; }
    return r;
  }

  // r = this << n*DIGIT_BITS.
  void _dlShiftTo(int n, _Bigint r) {
    var used = _used;
    if (used == 0) {
      r._used = 0;
      r._neg = false;
      return;
    }
    var r_used = used + n;
    r._ensureLength(r_used);
    var digits = _digits;
    var r_digits = r._digits;
    var i = used + 1;  // Copy leading zero for 64-bit processing.
    while (--i >= 0) {
      r_digits[i + n] = digits[i];
    }
    i = n;
    while (--i >= 0) {
      r_digits[i] = 0;
    }
    r._used = r_used;
    r._neg = _neg;
  }

  // r = this >> n*DIGIT_BITS.
  void _drShiftTo(int n, _Bigint r) {
    var used = _used;
    if (used == 0) {
      r._used = 0;
      r._neg = false;
      return;
    }
    var r_used = used - n;
    if (r_used <= 0) {
      if (_neg) {
        // Set r to -1.
        r._used = 0;  // No digits to preserve.
        r._ensureLength(1);
        r._neg = true;
        r._used = 1;
        r._digits[0] = 1;
        r._digits[1] = 0;  // Set leading zero for 64-bit processing.
      } else {
        // Set r to 0.
        r._neg = false;
        r._used = 0;
      }
      return;
    }
    r._ensureLength(r_used);
    var digits = _digits;
    var r_digits = r._digits;
    for (var i = n; i < used + 1; i++) {  // Copy leading zero for 64-bit proc.
      r_digits[i - n] = digits[i];
    }
    r._used = r_used;
    r._neg = _neg;
    if (_neg) {
      // Round down if any bit was shifted out.
      for (var i = 0; i < n; i++) {
        if (digits[i] != 0) {
          r._subTo(ONE, r);
          break;
        }
      }
    }
  }

  // r = this << n.
  void _lShiftTo(int n, _Bigint r) {
    var ds = n ~/ DIGIT_BITS;
    var bs = n % DIGIT_BITS;
    if (bs == 0) {
      _dlShiftTo(ds, r);
      return;
    }
    var cbs = DIGIT_BITS - bs;
    var bm = (1 << cbs) - 1;
    var r_used = _used + ds + 1;
    r._ensureLength(r_used);
    var digits = _digits;
    var r_digits = r._digits;
    var c = 0;
    var i = _used;
    while (--i >= 0) {
      r_digits[i + ds + 1] = (digits[i] >> cbs) | c;
      c = (digits[i] & bm) << bs;
    }
    i = ds;
    while (--i >= 0) {
      r_digits[i] = 0;
    }
    r_digits[ds] = c;
    r._used = r_used;
    r._neg = _neg;
    r._clamp();
  }

  // r = this >> n.
  void _rShiftTo(int n, _Bigint r) {
    var ds = n ~/ DIGIT_BITS;
    var bs = n % DIGIT_BITS;
    if (bs == 0) {
      _drShiftTo(ds, r);
      return;
    }
    var r_used = _used - ds;
    if (r_used <= 0) {
      if (_neg) {
        // Set r to -1.
        r._neg = true;
        r._used = 0;  // No digits to preserve.
        r._ensureLength(1);
        r._used = 1;
        r._digits[0] = 1;
        r._digits[1] = 0;  // Set leading zero for 64-bit processing.
      } else {
        // Set r to 0.
        r._neg = false;
        r._used = 0;
      }
      return;
    }
    var cbs = DIGIT_BITS - bs;
    var bm = (1 << bs) - 1;
    r._ensureLength(r_used);
    var digits = _digits;
    var r_digits = r._digits;
    r_digits[0] = digits[ds] >> bs;
    var used = _used;
    for (var i = ds + 1; i < used; i++) {
      r_digits[i - ds - 1] |= (digits[i] & bm) << cbs;
      r_digits[i - ds] = digits[i] >> bs;
    }
    r._neg = _neg;
    r._used = r_used;
    r._clamp();
    if (_neg) {
      // Round down if any bit was shifted out.
      if ((digits[ds] & bm) != 0) {
        r._subTo(ONE, r);
        return;
      }
      for (var i = 0; i < ds; i++) {
        if (digits[i] != 0) {
          r._subTo(ONE, r);
          return;
        }
      }
    }
  }

  // Return 0 if abs(this) == abs(a).
  // Return a positive number if abs(this) > abs(a).
  // Return a negative number if abs(this) < abs(a).
  int _absCompareTo(_Bigint a) {
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
  int _compareTo(_Bigint a) {
    var r;
    if (_neg == a._neg) {
      r = _absCompareTo(a);
      if (_neg) {
        r = -r;
      }
    } else if (_neg) {
      r = -1;
    } else {
      r = 1;
    }
    return r;
  }

  // r_digits[0..used] = digits[0..used-1] + a_digits[0..a_used-1].
  // used >= a_used > 0.
  static void _absAdd(Uint32List digits, int used,
                      Uint32List a_digits, int a_used,
                      Uint32List r_digits) {
    var c = 0;
    for (var i = 0; i < a_used; i++) {
      c += digits[i] + a_digits[i];
      r_digits[i] = c & DIGIT_MASK;
      c >>= DIGIT_BITS;
    }
    for (var i = a_used; i < used; i++) {
      c += digits[i];
      r_digits[i] = c & DIGIT_MASK;
      c >>= DIGIT_BITS;
    }
    r_digits[used] = c;
  }

  // r_digits[0..used-1] = digits[0..used-1] - a_digits[0..a_used-1].
  // used >= a_used > 0.
  static void _absSub(Uint32List digits, int used,
                      Uint32List a_digits, int a_used,
                      Uint32List r_digits) {
    var c = 0;
    for (var i = 0; i < a_used; i++) {
      c += digits[i] - a_digits[i];
      r_digits[i] = c & DIGIT_MASK;
      c >>= DIGIT_BITS;
    }
    for (var i = a_used; i < used; i++) {
      c += digits[i];
      r_digits[i] = c & DIGIT_MASK;
      c >>= DIGIT_BITS;
    }
  }

  // r = abs(this) + abs(a).
  void _absAddTo(_Bigint a, _Bigint r) {
    var used = _used;
    var a_used = a._used;
    if (used < a_used) {
      a._absAddTo(this, r);
      return;
    }
    if (used == 0) {
      // Set r to 0.
      r._neg = false;
      r._used = 0;
      return;
    }
    if (a_used == 0) {
      _copyTo(r);
      return;
    }
    r._ensureLength(used + 1);
    _absAdd(_digits, used, a._digits, a_used, r._digits);
    r._used = used + 1;
    r._clamp();
  }

  // r = abs(this) - abs(a), with abs(this) >= abs(a).
  void _absSubTo(_Bigint a, _Bigint r) {
    assert(_absCompareTo(a) >= 0);
    var used = _used;
    if (used == 0) {
      // Set r to 0.
      r._neg = false;
      r._used = 0;
      return;
    }
    var a_used = a._used;
    if (a_used == 0) {
      _copyTo(r);
      return;
    }
    r._ensureLength(used);
    _absSub(_digits, used, a._digits, a_used, r._digits);
    r._used = used;
    r._clamp();
  }

  // r = abs(this) & abs(a).
  void _absAndTo(_Bigint a, _Bigint r) {
    var r_used = (_used < a._used) ? _used : a._used;
    r._ensureLength(r_used);
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = r._digits;
    for (var i = 0; i < r_used; i++) {
      r_digits[i] = digits[i] & a_digits[i];
    }
    r._used = r_used;
    r._clamp();
  }

  // r = abs(this) &~ abs(a).
  void _absAndNotTo(_Bigint a, _Bigint r) {
    var r_used = _used;
    r._ensureLength(r_used);
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = r._digits;
    var m = (r_used < a._used) ? r_used : a._used;
    for (var i = 0; i < m; i++) {
      r_digits[i] = digits[i] &~ a_digits[i];
    }
    for (var i = m; i < r_used; i++) {
      r_digits[i] = digits[i];
    }
    r._used = r_used;
    r._clamp();
  }

  // r = abs(this) | abs(a).
  void _absOrTo(_Bigint a, _Bigint r) {
    var used = _used;
    var a_used = a._used;
    var r_used = (used > a_used) ? used : a_used;
    r._ensureLength(r_used);
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = r._digits;
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
    r._used = r_used;
    r._clamp();
  }

  // r = abs(this) ^ abs(a).
  void _absXorTo(_Bigint a, _Bigint r) {
    var used = _used;
    var a_used = a._used;
    var r_used = (used > a_used) ? used : a_used;
    r._ensureLength(r_used);
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = r._digits;
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
    r._used = r_used;
    r._clamp();
  }

  // Return r = this & a.
  _Bigint _andTo(_Bigint a, _Bigint r) {
    if (_neg == a._neg) {
      if (_neg) {
        // (-this) & (-a) == ~(this-1) & ~(a-1)
        //                == ~((this-1) | (a-1))
        //                == -(((this-1) | (a-1)) + 1)
        _Bigint t1 = new _Bigint();
        _absSubTo(ONE, t1);
        _Bigint a1 = new _Bigint();
        a._absSubTo(ONE, a1);
        t1._absOrTo(a1, r);
        r._absAddTo(ONE, r);
        r._neg = true;  // r cannot be zero if this and a are negative.
        return r;
      }
      _absAndTo(a, r);
      r._neg = false;
      return r;
    }
    // _neg != a._neg
    var p, n;
    if (_neg) {
      p = a;
      n = this;
    } else {  // & is symmetric.
      p = this;
      n = a;
    }
    // p & (-n) == p & ~(n-1) == p &~ (n-1)
    _Bigint n1 = new _Bigint();
    n._absSubTo(ONE, n1);
    p._absAndNotTo(n1, r);
    r._neg = false;
    return r;
  }

  // Return r = this &~ a.
  _Bigint _andNotTo(_Bigint a, _Bigint r) {
    if (_neg == a._neg) {
      if (_neg) {
        // (-this) &~ (-a) == ~(this-1) &~ ~(a-1)
        //                 == ~(this-1) & (a-1)
        //                 == (a-1) &~ (this-1)
        _Bigint t1 = new _Bigint();
        _absSubTo(ONE, t1);
        _Bigint a1 = new _Bigint();
        a._absSubTo(ONE, a1);
        a1._absAndNotTo(t1, r);
        r._neg = false;
        return r;
      }
      _absAndNotTo(a, r);
      r._neg = false;
      return r;
    }
    if (_neg) {
      // (-this) &~ a == ~(this-1) &~ a
      //              == ~(this-1) & ~a
      //              == ~((this-1) | a)
      //              == -(((this-1) | a) + 1)
      _Bigint t1 = new _Bigint();
      _absSubTo(ONE, t1);
      t1._absOrTo(a, r);
      r._absAddTo(ONE, r);
      r._neg = true;  // r cannot be zero if this is negative and a is positive.
      return r;
    }
    // this &~ (-a) == this &~ ~(a-1) == this & (a-1)
    _Bigint a1 = new _Bigint();
    a._absSubTo(ONE, a1);
    _absAndTo(a1, r);
    r._neg = false;
    return r;
  }

  // Return r = this | a.
  _Bigint _orTo(_Bigint a, _Bigint r) {
    if (_neg == a._neg) {
      if (_neg) {
        // (-this) | (-a) == ~(this-1) | ~(a-1)
        //                == ~((this-1) & (a-1))
        //                == -(((this-1) & (a-1)) + 1)
        _Bigint t1 = new _Bigint();
        _absSubTo(ONE, t1);
        _Bigint a1 = new _Bigint();
        a._absSubTo(ONE, a1);
        t1._absAndTo(a1, r);
        r._absAddTo(ONE, r);
        r._neg = true;  // r cannot be zero if this and a are negative.
        return r;
      }
      _absOrTo(a, r);
      r._neg = false;
      return r;
    }
    // _neg != a._neg
    var p, n;
    if (_neg) {
      p = a;
      n = this;
    } else {  // | is symmetric.
      p = this;
      n = a;
    }
    // p | (-n) == p | ~(n-1) == ~((n-1) &~ p) == -(~((n-1) &~ p) + 1)
    _Bigint n1 = new _Bigint();
    n._absSubTo(ONE, n1);
    n1._absAndNotTo(p, r);
    r._absAddTo(ONE, r);
    r._neg = true;  // r cannot be zero if only one of this or a is negative.
    return r;
  }

  // Return r = this ^ a.
  _Bigint _xorTo(_Bigint a, _Bigint r) {
    if (_neg == a._neg) {
      if (_neg) {
        // (-this) ^ (-a) == ~(this-1) ^ ~(a-1) == (this-1) ^ (a-1)
        _Bigint t1 = new _Bigint();
        _absSubTo(ONE, t1);
        _Bigint a1 = new _Bigint();
        a._absSubTo(ONE, a1);
        t1._absXorTo(a1, r);
        r._neg = false;
        return r;
      }
      _absXorTo(a, r);
      r._neg = false;
      return r;
    }
    // _neg != a._neg
    var p, n;
    if (_neg) {
      p = a;
      n = this;
    } else {  // ^ is symmetric.
      p = this;
      n = a;
    }
    // p ^ (-n) == p ^ ~(n-1) == ~(p ^ (n-1)) == -((p ^ (n-1)) + 1)
    _Bigint n1 = new _Bigint();
    n._absSubTo(ONE, n1);
    p._absXorTo(n1, r);
    r._absAddTo(ONE, r);
    r._neg = true;  // r cannot be zero if only one of this or a is negative.
    return r;
  }

  // Return r = ~this.
  _Bigint _notTo(_Bigint r) {
    if (_neg) {
      // ~(-this) == ~(~(this-1)) == this-1
      _absSubTo(ONE, r);
      r._neg = false;
      return r;
    }
    // ~this == -this-1 == -(this+1)
    _absAddTo(ONE, r);
    r._neg = true;  // r cannot be zero if this is positive.
    return r;
  }

  // Return r = this + a.
  _Bigint _addTo(_Bigint a, _Bigint r) {
    var r_neg = _neg;
    if (_neg == a._neg) {
      // this + a == this + a
      // (-this) + (-a) == -(this + a)
      _absAddTo(a, r);
    } else {
      // this + (-a) == this - a == -(this - a)
      // (-this) + a == a - this == -(this - a)
      if (_absCompareTo(a) >= 0) {
        _absSubTo(a, r);
      } else {
        r_neg = !r_neg;
        a._absSubTo(this, r);
      }
    }
  	r._neg = r_neg;
    return r;
  }

  // Return r = this - a.
  _Bigint _subTo(_Bigint a, _Bigint r) {
  	var r_neg = _neg;
    if (_neg != a._neg) {
  		// this - (-a) == this + a
  		// (-this) - a == -(this + a)
      _absAddTo(a, r);
  	} else {
  		// this - a == this - a == -(this - a)
  		// (-this) - (-a) == a - this == -(this - a)
      if (_absCompareTo(a) >= 0) {
        _absSubTo(a, r);
  		} else {
        r_neg = !r_neg;
        a._absSubTo(this, r);
      }
    }
  	r._neg = r_neg;
    return r;
  }

  // Multiply and accumulate.
  // Input:
  //   x_digits[xi]: multiplier digit x.
  //   m_digits[i..i+n-1]: multiplicand digits.
  //   a_digits[j..j+n-1]: accumulator digits.
  // Operation:
  //   a_digits[j..j+n] += x*m_digits[i..i+n-1].
  static void _mulAdd(Uint32List x_digits, int xi,
                      Uint32List m_digits, int i,
                      Uint32List a_digits, int j, int n) {
    int x = x_digits[xi];
    if (x == 0) {
      // No-op if x is 0.
      return;
    }
    int c = 0;
    int xl = x & DIGIT2_MASK;
    int xh = x >> DIGIT2_BITS;
    while (--n >= 0) {
      int l = m_digits[i] & DIGIT2_MASK;
      int h = m_digits[i++] >> DIGIT2_BITS;
      int m = xh*l + h*xl;
      l = xl*l + ((m & DIGIT2_MASK) << DIGIT2_BITS) + a_digits[j] + c;
      c = (l >> DIGIT_BITS) + (m >> DIGIT2_BITS) + xh*h;
      a_digits[j++] = l & DIGIT_MASK;
    }
    while (c != 0) {
      int l = a_digits[j] + c;
      c = l >> DIGIT_BITS;
      a_digits[j++] = l & DIGIT_MASK;
    }
  }

  // Square and accumulate.
  // Input:
  //   x_digits[i..used-1]: digits of operand being squared.
  //   a_digits[2*i..i+used-1]: accumulator digits.
  // Operation:
  //   a_digits[2*i..i+used-1] += x_digits[i]*x_digits[i] +
  //                              2*x_digits[i]*x_digits[i+1..used-1].
  static void _sqrAdd(Uint32List x_digits, int i,
                      Uint32List a_digits, int used) {
    int x = x_digits[i];
    if (x == 0) return;
    int j = 2*i;
    int c = 0;
    int xl = x & DIGIT2_MASK;
    int xh = x >> DIGIT2_BITS;
    int m = 2*xh*xl;
    int l = xl*xl + ((m & DIGIT2_MASK) << DIGIT2_BITS) + a_digits[j];
    c = (l >> DIGIT_BITS) + (m >> DIGIT2_BITS) + xh*xh;
    a_digits[j] = l & DIGIT_MASK;
    x <<= 1;
    xl = x & DIGIT2_MASK;
    xh = x >> DIGIT2_BITS;
    int n = used - i - 1;
    int k = i + 1;
    j++;
    while (--n >= 0) {
      int l = x_digits[k] & DIGIT2_MASK;
      int h = x_digits[k++] >> DIGIT2_BITS;
      int m = xh*l + h*xl;
      l = xl*l + ((m & DIGIT2_MASK) << DIGIT2_BITS) + a_digits[j] + c;
      c = (l >> DIGIT_BITS) + (m >> DIGIT2_BITS) + xh*h;
      a_digits[j++] = l & DIGIT_MASK;
    }
    c += a_digits[i + used];
    if (c >= DIGIT_BASE) {
      a_digits[i + used] = c - DIGIT_BASE;
      a_digits[i + used + 1] = 1;
    } else {
      a_digits[i + used] = c;
    }
  }

  // r = this * a.
  void _mulTo(_Bigint a, _Bigint r) {
    // TODO(regis): Use karatsuba multiplication when appropriate.
    var used = _used;
    var a_used = a._used;
    if (used == 0 || a_used == 0) {
      r._used = 0;
      r._neg = false;
      return;
    }
    var r_used = used + a_used;
    r._ensureLength(r_used);
    var digits = _digits;
    var a_digits = a._digits;
    var r_digits = r._digits;
    r._used = r_used;
    var i = r_used + 1;  // Set leading zero for 64-bit processing.
    while (--i >= 0) {
      r_digits[i] = 0;
    }
    for (i = 0; i < a_used; ++i) {
      _mulAdd(a_digits, i, digits, 0, r_digits, i, used);
    }
    r._clamp();
    r._neg = r._used > 0 && _neg != a._neg;  // Zero cannot be negative.
  }

  // r = this^2, r != this.
  void _sqrTo(_Bigint r) {
    var used = _used;
    if (used == 0) {
      r._used = 0;
      r._neg = false;
      return;
    }
    var r_used = 2 * used;
    r._ensureLength(r_used);
    var digits = _digits;
    var r_digits = r._digits;
    var i = r_used + 1;  // Set leading zero for 64-bit processing.
    while (--i >= 0) {
      r_digits[i] = 0;
    }
    for (i = 0; i < used - 1; ++i) {
      _sqrAdd(digits, i, r_digits, used);
    }
    if (r_used > 0) {
      _mulAdd(digits, i, digits, i, r_digits, 2*i, 1);
    }
    r._used = r_used;
    r._neg = false;
    r._clamp();
  }

  // Indices of the arguments of _estQuotientDigit.
  static const int _YT = 0;  // Index of top digit of divisor y in args array.
  static const int _QD = 1;  // Index of estimated quotient digit in args array.

  // Estimate args[_QD] = digits[i]:digits[i-1] ~/ args[_YT].
  static void _estQuotientDigit(Uint32List args, Uint32List digits, int i) {
    if (digits[i] == args[_YT]) {
      args[_QD] = DIGIT_MASK;
    } else {
      // Chop off one bit, since a Mint cannot hold 2 DIGITs.
      var qd = ((digits[i] << (DIGIT_BITS - 1)) | (digits[i - 1] >> 1))
          ~/ (args[_YT] >> 1);
      if (qd > DIGIT_MASK) {
        args[_QD] = DIGIT_MASK;
      } else {
        args[_QD] = qd;
      }
    }
  }


  // Truncating division and remainder.
  // If q != null, q = trunc(this / a).
  // If r != null, r = this - a * trunc(this / a).
  void _divRemTo(_Bigint a, _Bigint q, _Bigint r) {
    if (a._used == 0) return;
    if (_used < a._used) {
      if (q != null) {
        // Set q to 0.
        q._neg = false;
        q._used = 0;
      }
      if (r != null) {
        _copyTo(r);
      }
      return;
    }
    if (r == null) {
      r = new _Bigint();
    }
    var y = new _Bigint();  // Normalized modulus.
    var nsh = DIGIT_BITS - _nbits(a._digits[a._used - 1]);
    if (nsh > 0) {
      a._lShiftTo(nsh, y);
      _lShiftTo(nsh, r);
    }
    else {
      a._copyTo(y);
      _copyTo(r);
    }
    // We consider this and a positive. Ignore the copied sign.
    y._neg = false;
    r._neg = false;
    var y_used = y._used;
    var y_digits = y._digits;
    var yt = y_digits[y_used - 1];
    if (yt == 0) return;
    var i = r._used;
    var j = i - y_used;
    _Bigint t = (q == null) ? new _Bigint() : q;
    y._dlShiftTo(j, t);
    var r_digits = r._digits;
    if (r._compareTo(t) >= 0) {
      r_digits[r._used++] = 1;
      r_digits[r._used] = 0;  // Set leading zero for 64-bit processing.
      r._subTo(t, r);
    }
    ONE._dlShiftTo(y_used, t);
    t._subTo(y, y);  // Negate y so we can replace sub with _mulAdd later.
    while (y._used < y_used) {
      y_digits[y._used++] = 0;
    }
    y_digits[y._used] = 0;  // Set leading zero for 64-bit processing.
    Uint32List args = new Uint32List(2);
    args[_YT] = yt;
    while (--j >= 0) {
      _estQuotientDigit(args, r_digits, --i);
      _mulAdd(args, _QD, y_digits, 0, r_digits, j, y_used);
      if (r_digits[i] < args[_QD]) {
        y._dlShiftTo(j, t);
        r._subTo(t, r);
        while (r_digits[i] < --args[_QD]) {
          r._subTo(t, r);
        }
      }
    }
    if (q != null) {
      r._drShiftTo(y_used, q);
      if (_neg != a._neg) {
        ZERO._subTo(q, q);
      }
    }
    r._used = y_used;
    r._clamp();
    if (nsh > 0) {
      r._rShiftTo(nsh, r);  // Denormalize remainder.
    }
    if (_neg) {
      ZERO._subTo(r, r);
    }
  }

  int get _identityHashCode {
    return this;
  }
  int operator ~() {
    _Bigint result = new _Bigint();
    _notTo(result);
    return result._toValidInt();
  }

  int get bitLength {
    if (_used == 0) return 0;
    if (_neg) return (~this).bitLength;
    return DIGIT_BITS*(_used - 1) + _nbits(_digits[_used - 1]);
  }

  // This method must support smi._toBigint()._shrFromInt(int).
  int _shrFromInt(int other) {
    if (_used == 0) return other;  // Shift amount is zero.
    if (_neg) throw "negative shift amount";  // TODO(regis): What exception?
    assert(DIGIT_BITS == 32);  // Otherwise this code needs to be revised.
    var shift;
    if ((_used > 2) || ((_used == 2) && (_digits[1] > 0x10000000))) {
      if (other < 0) {
        return -1;
      } else {
        return 0;
      }
    } else {
      shift = ((_used == 2) ? (_digits[1] << DIGIT_BITS) : 0) + _digits[0];
    }
    _Bigint result = new _Bigint();
    other._toBigint()._rShiftTo(shift, result);
    return result._toValidInt();
  }

  // This method must support smi._toBigint()._shlFromInt(int).
  // An out of memory exception is thrown if the result cannot be allocated.
  int _shlFromInt(int other) {
    if (_used == 0) return other;  // Shift amount is zero.
    if (_neg) throw "negative shift amount";  // TODO(regis): What exception?
    assert(DIGIT_BITS == 32);  // Otherwise this code needs to be revised.
    var shift;
    if (_used > 2 || (_used == 2 && _digits[1] > 0x10000000)) {
      throw new OutOfMemoryError();
    } else {
      shift = ((_used == 2) ? (_digits[1] << DIGIT_BITS) : 0) + _digits[0];
    }
    _Bigint result = new _Bigint();
    other._toBigint()._lShiftTo(shift, result);
    return result._toValidInt();
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
    if ((other is int) && (other == 0)) {
      throw const IntegerDivisionByZeroException();
    }
    return other._toBigintOrDouble()._truncDivFromInteger(this);
  }
  num operator %(num other) {
    if ((other is int) && (other == 0)) {
      throw const IntegerDivisionByZeroException();
    }
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
    if (_used == 0) {
      return this;
    }
    var r = new _Bigint();
    _copyTo(r);
    r._neg = !_neg;
    return r._toValidInt();
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
    final firstcx = _neg ? 1 : 0;  // Index of first char in str after the sign.
    final lastdx = _used - 1;  // Index of last digit in bigint.
    final bitLength = lastdx*DIGIT_BITS + _nbits(_digits[lastdx]);
    // Index of char in str. Initialize with str length.
    var cx = firstcx + (bitLength + bitsPerChar - 1) ~/ bitsPerChar;
    _OneByteString str = _OneByteString._allocate(cx);
    str._setAt(0, 0x2d);  // '-'. Is overwritten if not negative.
    final mask = radix - 1;
    var dx = 0;  // Digit index in bigint.
    var bx = 0;  // Bit index in bigint digit.
    do {
      var ch;
      if (bx > (DIGIT_BITS - bitsPerChar)) {
        ch = _digits[dx++] >> bx;
        bx += bitsPerChar - DIGIT_BITS;
        if (dx <= lastdx) {
          ch |= (_digits[dx] & ((1 << bx) - 1)) << (bitsPerChar - bx);
        }
      } else {
        ch = (_digits[dx] >> bx) & mask;
        bx += bitsPerChar;
        if (bx >= DIGIT_BITS) {
          bx -= DIGIT_BITS;
          dx++;
        }
      }
      str._setAt(--cx, _IntegerImplementation._digits.codeUnitAt(ch));
    } while (cx > firstcx);
    return str;
  }

  _leftShiftWithMask32(int count, int mask) {
    if (_used == 0) return 0;
    if (count is! _Smi) {
      _shlFromInt(count);  // Throws out of memory exception.
    }
    assert(DIGIT_BITS == 32);  // Otherwise this code needs to be revised.
    if (count > 31) return 0;
    return (_digits[0] << count) & mask;
  }

  int _bitAndFromInteger(int other) {
    _Bigint result = new _Bigint();
    other._toBigint()._andTo(this, result);
    return result._toValidInt();
  }
  int _bitOrFromInteger(int other) {
    _Bigint result = new _Bigint();
    other._toBigint()._orTo(this, result);
    return result._toValidInt();
  }
  int _bitXorFromInteger(int other) {
    _Bigint result = new _Bigint();
    other._toBigint()._xorTo(this, result);
    return result._toValidInt();
  }
  int _addFromInteger(int other) {
    _Bigint result = new _Bigint();
    other._toBigint()._addTo(this, result);
    return result._toValidInt();
  }
  int _subFromInteger(int other) {
    _Bigint result = new _Bigint();
    other._toBigint()._subTo(this, result);
    return result._toValidInt();
  }
  int _mulFromInteger(int other) {
    _Bigint result = new _Bigint();
    other._toBigint()._mulTo(this, result);
    return result._toValidInt();
  }
  int _truncDivFromInteger(int other) {
    _Bigint result = new _Bigint();
    other._toBigint()._divRemTo(this, result, null);
    return result._toValidInt();
  }
  int _moduloFromInteger(int other) {
    _Bigint result = new _Bigint();
    var ob = other._toBigint();
    other._toBigint()._divRemTo(this, null, result);
    if (result._neg) {
      if (_neg) {
        result._subTo(this, result);
      } else {
        result._addTo(this, result);
      }
    }
    return result._toValidInt();
  }
  int _remainderFromInteger(int other) {
    _Bigint result = new _Bigint();
    other._toBigint()._divRemTo(this, null, result);
    return result._toValidInt();
  }
  bool _greaterThanFromInteger(int other) {
    return other._toBigint()._compareTo(this) > 0;
  }
  bool _equalToInteger(int other) {
    return other._toBigint()._compareTo(this) == 0;
  }

  // Return -1/this % DIGIT_BASE, useful for Montgomery reduction.
  //
  //         xy == 1 (mod m)
  //         xy =  1+km
  //   xy(2-xy) = (1+km)(1-km)
  // x(y(2-xy)) = 1-k^2 m^2
  // x(y(2-xy)) == 1 (mod m^2)
  // if y is 1/x mod m, then y(2-xy) is 1/x mod m^2
  // Should reduce x and y(2-xy) by m^2 at each step to keep size bounded.
  int _invDigit() {
    if (_used == 0) return 0;
    var x = _digits[0];
    if ((x & 1) == 0) return 0;
    var y = x & 3;    // y == 1/x mod 2^2
    y = (y*(2 - (x & 0xf)*y)) & 0xf;  // y == 1/x mod 2^4
    y = (y*(2 - (x & 0xff)*y)) & 0xff;  // y == 1/x mod 2^8
    y = (y*(2 - (((x & 0xffff)*y) & 0xffff))) & 0xffff; // y == 1/x mod 2^16
    // Last step - calculate inverse mod DIGIT_BASE directly;
    // Assumes 16 < DIGIT_BITS <= 32 and assumes ability to handle 48-bit ints.
    y = (y*(2 - x*y % DIGIT_BASE)) % DIGIT_BASE;    // y == 1/x mod DIGIT_BASE
    // We really want the negative inverse, and - DIGIT_BASE < y < DIGIT_BASE.
    return (y > 0) ? DIGIT_BASE - y : -y;
  }

  // TODO(regis): Make this method private once the plumbing to invoke it from
  // dart:math is in place. Move the argument checking to dart:math.
  // Return pow(this, e) % m.
  int modPow(int e, int m) {
    if (e is! int) throw new ArgumentError(e);
    if (m is! int) throw new ArgumentError(m);
    int i = e.bitLength;
    if (i <= 0) return 1;
    if ((e is! _Bigint) || m.isEven) {
      _Reduction z = (i < 8 || m.isEven) ? new _Classic(m) : new _Montgomery(m);
      // TODO(regis): Should we use Barrett reduction for an even modulus?
      var r = new _Bigint();
      var r2 = new _Bigint();
      var g = z._convert(this);
      i--;
      g._copyTo(r);
      while (--i >= 0) {
        z._sqrTo(r, r2);
        if ((e & (1 << i)) != 0) {
          z._mulTo(r2, g, r);
        } else {
          var t = r;
          r = r2;
          r2 = t;
        }
      }
      return z._revert(r)._toValidInt();
    }
    var k;
    // TODO(regis): Are these values of k really optimal for our implementation?
    if (i < 18) k = 1;
    else if (i < 48) k = 3;
    else if (i < 144) k = 4;
    else if (i < 768) k = 5;
    else k = 6;
    _Reduction z = new _Montgomery(m);
    var n = 3;
    var k1 = k - 1;
    var km = (1 << k) - 1;
    List g = new List(km + 1);
    g[1] = z._convert(this);
    if (k > 1) {
      var g2 = new _Bigint();
      z._sqrTo(g[1], g2);
      while (n <= km) {
        g[n] = new _Bigint();
        z._mulTo(g2, g[n - 2], g[n]);
        n += 2;
      }
    }
    var j = e._used - 1;
    var w;
    var is1 = true;
    var r = new _Bigint()._setInt(1);
    var r2 = new _Bigint();
    var t;
    var e_digits = e._digits;
    i = _nbits(e_digits[j]) - 1;
    while (j >= 0) {
      if (i >= k1) {
        w = (e_digits[j] >> (i - k1)) & km;
      } else {
        w = (e_digits[j] & ((1 << (i + 1)) - 1)) << (k1 - i);
        if (j > 0) {
          w |= e_digits[j - 1] >> (DIGIT_BITS + i - k1);
        }
      }
      n = k;
      while ((w & 1) == 0) {
        w >>= 1;
        --n;
      }
      if ((i -= n) < 0) {
        i += DIGIT_BITS;
        --j;
      }
      if (is1) {  // r == 1, don't bother squaring or multiplying it.
        g[w]._copyTo(r);
        is1 = false;
      }
      else {
        while (n > 1) {
          z._sqrTo(r, r2);
          z._sqrTo(r2, r);
          n -= 2;
        }
        if (n > 0) {
          z._sqrTo(r, r2);
        } else {
          t = r;
          r = r2;
          r2 = t;
        }
        z._mulTo(r2,g[w], r);
      }

      while (j >= 0 && (e_digits[j] & (1 << i)) == 0) {
        z._sqrTo(r, r2);
        t = r;
        r = r2;
        r2 = t;
        if (--i < 0) {
          i = DIGIT_BITS - 1;
          --j;
        }
      }
    }
    return z._revert(r)._toValidInt();
  }
}

// Interface for modular reduction.
class _Reduction {
  _Bigint _convert(_Bigint x);
  _Bigint _revert(_Bigint x);
  void _mulTo(_Bigint x, _Bigint y, _Bigint r);
  void _sqrTo(_Bigint x, _Bigint r);
}

// Montgomery reduction on _Bigint.
class _Montgomery implements _Reduction {
  _Bigint _m;
  int _mused2;
  Uint32List _rho_mu;
  static const int _RHO = 0;  // Index of rho in _rho_mu array.
  static const int _MU = 1;  // Index of mu in _rho_mu array.

  _Montgomery(m) {
    _m = m._toBigint();
    _mused2 = 2*_m._used;
    _rho_mu = new Uint32List(2);
    _rho_mu[_RHO] = _m._invDigit();
  }

  // args[_MU] = args[_RHO]*digits[i] mod DIGIT_BASE.
  static void _mulMod(Uint32List args, Uint32List digits, int i) {
    const int MU_MASK = (1 << (_Bigint.DIGIT_BITS - _Bigint.DIGIT2_BITS)) - 1;
    var rhol = args[_RHO] & _Bigint.DIGIT2_MASK;
    var rhoh = args[_RHO] >> _Bigint.DIGIT2_BITS;
    var dh = digits[i] >> _Bigint.DIGIT2_BITS;
    var dl = digits[i] & _Bigint.DIGIT2_MASK;
    args[_MU] =
        (dl*rhol + (((dl*rhoh + dh*rhol) & MU_MASK) << _Bigint.DIGIT2_BITS))
        & _Bigint.DIGIT_MASK;
  }

  // Return x*R mod _m
  _Bigint _convert(_Bigint x) {
    var r = new _Bigint();
    x.abs()._dlShiftTo(_m._used, r);
    r._divRemTo(_m, null, r);
    if (x._neg && !r._neg && r._used > 0) {
      _m._subTo(r, r);
    }
    return r;
  }

  // Return x/R mod _m
  _Bigint _revert(_Bigint x) {
    var r = new _Bigint();
    x._copyTo(r);
    _reduce(r);
    return r;
  }

  // x = x/R mod _m
  void _reduce(_Bigint x) {
    x._ensureLength(_mused2 + 1);
    var x_digits = x._digits;
    while (x._used <= _mused2) {  // Pad x so _mulAdd has enough room later.
      x_digits[x._used++] = 0;
    }
    x_digits[x._used] = 0;  // Set leading zero for 64-bit processing.
    var m_used = _m._used;
    var m_digits = _m._digits;
    for (var i = 0; i < m_used; i++) {
      _mulMod(_rho_mu, x_digits, i);
      _Bigint._mulAdd(_rho_mu, _MU, m_digits, 0, x_digits, i, m_used);
    }
    x._clamp();
    x._drShiftTo(m_used, x);
    if (x._compareTo(_m) >= 0) {
      x._subTo(_m, x);
    }
  }

  // r = x^2/R mod _m ; x != r
  void _sqrTo(_Bigint x, _Bigint r) {
    x._sqrTo(r);
    _reduce(r);
  }

  // r = x*y/R mod _m ; x, y != r
  void _mulTo(_Bigint x, _Bigint y, _Bigint r) {
    x._mulTo(y, r);
    _reduce(r);
  }
}

// Modular reduction using "classic" algorithm.
class _Classic implements _Reduction {
  _Bigint _m;

  _Classic(int m) {
    _m = m._toBigint();
  }

  _Bigint _convert(_Bigint x) {
    if (x._neg || x._compareTo(_m) >= 0) {
      var r = new _Bigint();
      x._divRemTo(_m, null, r);
      if (x._neg && !r._neg && r._used > 0) {
        _m._subTo(r, r);
      }
      return r;
    }
    return x;
  }

  _Bigint _revert(_Bigint x) {
    return x;
  }

  void _reduce(_Bigint x) {
    x._divRemTo(_m, null, x);
  }

  void _sqrTo(_Bigint x, _Bigint r) {
    x._sqrTo(r);
    _reduce(r);
  }

  void _mulTo(_Bigint x, _Bigint y, _Bigint r) {
    x._mulTo(y, r);
    _reduce(r);
  }
}
