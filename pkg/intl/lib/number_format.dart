// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("number_format");

#import('dart:math');

#import("intl.dart");
#import("number_symbols.dart");
#import("number_symbols_data.dart");

class NumberFormat {
  /** Variables to determine how number printing behaves. */
  // TODO(alanknight): If these remain as variables and are set based on the
  // pattern, can we make them final?
  String _negativePrefix = '-';
  String _positivePrefix = '';
  String _negativeSuffix = '';
  String _positiveSuffix = '';
  /** How many numbers in a group when using punctuation to group digits in
   * large numbers. e.g. in en_US: "1,000,000" has a grouping size of 3 digits
   * between commas.
   */
  int _groupingSize = 3;
  bool _decimalSeparatorAlwaysShown = false;
  bool _useExponentialNotation = false;
  int _maximumIntegerDigits = 40;
  int _minimumIntegerDigits = 1;
  int _maximumFractionDigits = 3; // invariant, >= minFractionDigits
  int _minimumFractionDigits = 0;
  int _minimumExponentDigits = 0;
  bool _useSignForPositiveExponent = false;

  /** The locale in which we print numbers. */
  final String _locale;

  /** Caches the symbols used for our locale. */
  NumberSymbols _symbols;

  /**
   * Transient internal state in which to build up the result of the format
   * operation. We can have this be just an instance variable because Dart is
   * single-threaded and unless we do an asynchronous operation in the process
   * of formatting then there will only ever be one number being formatted
   * at a time. In languages with threads we'd need to pass this on the stack.
   */
  StringBuffer _buffer;

  /**
   * Create a number format that prints in [newPattern] as it applies in
   * [locale].
   */
  NumberFormat([String newPattern, String locale]):
    _locale = Intl.verifiedLocale(locale) {
    // TODO(alanknight): There will need to be some kind of async setup
    // operations so as not to bring along every locale in every program.
    _symbols = numberFormatSymbols[_locale];
    _setPattern(newPattern);
  }

  /**
   * Return the locale code in which we operate, e.g. 'en_US' or 'pt'.
   */
  String get locale => _locale;

  /**
   * Return the symbols which are used in our locale. Cache them to avoid
   * repeated lookup.
   */
  NumberSymbols get symbols {
    return _symbols;
  }

  // TODO(alanknight): Actually use the pattern and locale.
  _setPattern(String x) {}

  /**
   * Format [number] according to our pattern and return the formatted string.
   */
  String format(num number) {
    // TODO(alanknight): Do we have to do anything for printing numbers bidi?
    // Or are they always printed left to right?
    if (number.isNaN()) return symbols.NAN;
    if (number.isInfinite()) return "${_signPrefix(number)}${symbols.INFINITY}";

    _newBuffer();
    _add(_signPrefix(number));
    _formatNumber(number.abs());
    _add(_signSuffix(number));

    var result = _buffer.toString();
    _buffer = null;
    return result;
  }

  /**
   * Format the main part of the number in the form dictated by the pattern.
   */
  void _formatNumber(num number) {
    if (_useExponentialNotation) {
      _formatExponential(number);
    } else {
      _formatFixed(number);
    }
  }

  /** Format the number in exponential notation. */
  _formatExponential(num number) {
    if (number == 0.0) {
      _formatFixed(number);
      _formatExponent(0);
      return;
    }

    var exponent = (log(number) / log(10)).floor();
    var mantissa = number / pow(10, exponent);

    if (_minimumIntegerDigits < 1) {
      exponent++;
      mantissa /= 10;
    } else {
      exponent -= _minimumIntegerDigits - 1;
      mantissa *= pow(10, _minimumIntegerDigits - 1);
    }
    _formatFixed(number);
    _formatExponent(exponent);
  }

  /**
   * Format the exponent portion, e.g. in "1.3e-5" the "e-5".
   */
  void _formatExponent(num exponent) {
    _add(symbols.EXP_SYMBOL);
    if (exponent < 0) {
      exponent = -exponent;
      _add(symbols.MINUS_SIGN);
    } else if (_useSignForPositiveExponent) {
      _add(symbols.PLUS_SIGN);
    }
    _pad(_minimumExponentDigits, exponent.toString());
  }

  /**
   * Format the basic number portion, inluding the fractional digits.
   */
  void _formatFixed(num number) {
    // Round the number.
    var power = pow(10, _maximumFractionDigits);
    var intValue = number.truncate().toInt();
    var multiplied = (number * power).round();
    var fracValue = (multiplied - intValue * power).floor().toInt();
    var fractionPresent = _minimumFractionDigits > 0 || fracValue > 0;

    // On dartj2s the integer part may be large enough to be a floating
    // point value, in which case we reduce it until it is small enough
    // to be printed as an integer and pad the remainder with zeros.
    var paddingDigits = new StringBuffer();
    while ((intValue & 0x7fffffff) != intValue) {
      paddingDigits.add(symbols.ZERO_DIGIT);
      intValue = intValue ~/ 10;
    }
    var integerDigits = "${intValue}${paddingDigits}".charCodes();
    var digitLength = integerDigits.length;

    if (_hasPrintableIntegerPart(intValue)) {
      _pad(_minimumIntegerDigits - digitLength);
      for (var i = 0; i < digitLength; i++) {
        _addDigit(integerDigits[i]);
        _group(digitLength, i);
      }
    } else if (!fractionPresent) {
      // If neither fraction nor integer part exists, just print zero.
      _addZero();
    }

    _decimalSeparator(fractionPresent);
    _formatFractionPart((fracValue + power).toString());
  }

  /**
   * Format the part after the decimal place in a fixed point number.
   */
  void _formatFractionPart(String fractionPart) {
    var fractionCodes = fractionPart.charCodes();
    var fractionLength = fractionPart.length;
    while (fractionPart[fractionLength - 1] == '0' &&
           fractionLength > _minimumFractionDigits + 1) {
      fractionLength--;
    }
    for (var i = 1; i < fractionLength; i++) {
      _addDigit(fractionCodes[i]);
    }
  }

  /** Print the decimal separator if appropriate. */
  void _decimalSeparator(bool fractionPresent) {
    if (_decimalSeparatorAlwaysShown || fractionPresent) {
      _add(symbols.DECIMAL_SEP);
    }
  }

  /**
   * Return true if we have a main integer part which is printable, either
   * because we have digits left of the decimal point, or because there are
   * a minimum number of printable digits greater than 1.
   */
  bool _hasPrintableIntegerPart(int intValue) {
    return intValue > 0 || _minimumIntegerDigits > 0;
  }

  /**
   * Create a new empty buffer. See comment on [_buffer] variable for why
   * we have it as an instance variable rather than passing it on the stack.
   */
  void _newBuffer() { _buffer = new StringBuffer(); }

  /** A group of methods that provide support for writing digits and other
   * required characters into [_buffer] easily.
   */
  void _add(String x) { _buffer.add(x);}
  void _addCharCode(int x) { _buffer.addCharCode(x); }
  void _addZero() { _buffer.add(symbols.ZERO_DIGIT); }
  void _addDigit(int x) { _buffer.addCharCode(_localeZero + x - _zero); }

  /** Print padding up to [numberOfDigits] above what's included in [basic]. */
  void _pad(int numberOfDigits, [String basic = '']) {
    for (var i = 0; i < numberOfDigits - basic.length; i++) {
      _add(symbols.ZERO_DIGIT);
    }
    for (var x in basic.charCodes()) {
      _addDigit(x);
    }
  }

  /**
   * We are printing the digits of the number from left to right. We may need
   * to print a thousands separator or other grouping character as appropriate
   * to the locale. So we find how many places we are from the end of the number
   * by subtracting our current [position] from the [totalLength] and print
   * the separator character every [_groupingSize] digits.
   */
  void _group(int totalLength, int position) {
    var distanceFromEnd = totalLength - position;
    if (distanceFromEnd <= 1 || _groupingSize <= 0) return;
    if (distanceFromEnd % _groupingSize == 1) {
      _add(symbols.GROUP_SEP);
    }
  }

  /** Returns the code point for the character '0'. */
  int get _zero => '0'.charCodes()[0];

  /** Returns the code point for the locale's zero digit. */
  int get _localeZero => symbols.ZERO_DIGIT.charCodeAt(0);

  /**
   * Returns the prefix for [x] based on whether it's positive or negative.
   * In en_US this would be '' and '-' respectively.
   */
  String _signPrefix(num x) {
    return x.isNegative() ? _negativePrefix : _positivePrefix;
  }

  /**
   * Returns the suffix for [x] based on wether it's positive or negative.
   * In en_US there are no suffixes for positive or negative.
   */
  String _signSuffix(num x) {
    return x.isNegative() ? _negativeSuffix : _positiveSuffix;
  }
}
