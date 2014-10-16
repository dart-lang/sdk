// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of intl;
/**
 * Provides the ability to format a number in a locale-specific way. The
 * format is specified as a pattern using a subset of the ICU formatting
 * patterns.
 *
 * - `0` A single digit
 * - `#` A single digit, omitted if the value is zero
 * - `.` Decimal separator
 * - `-` Minus sign
 * - `,` Grouping separator
 * - `E` Separates mantissa and expontent
 * - `+` - Before an exponent, indicates it should be prefixed with a plus sign.
 * - `%` - In prefix or suffix, multiply by 100 and show as percentage
 * - `‰ (\u2030)` In prefix or suffix, multiply by 1000 and show as per mille
 * - `¤ (\u00A4)` Currency sign, replaced by currency name
 * - `'` Used to quote special characters
 * - `;` Used to separate the positive and negative patterns if both are present
 *
 * For example,
 *       var f = new NumberFormat("###.0#", "en_US");
 *       print(f.format(12.345));
 *       ==> 12.34
 * If the locale is not specified, it will default to the current locale. If
 * the format is not specified it will print in a basic format with at least
 * one integer digit and three fraction digits.
 *
 * There are also standard patterns available via the special constructors. e.g.
 *       var percent = new NumberFormat.percentFormat("ar");
 *       var eurosInUSFormat = new NumberFormat.currencyPattern("en_US", "€");
 * There are four such constructors: decimalFormat, percentFormat,
 * scientificFormat and currencyFormat. However, at the moment,
 * scientificFormat prints only as equivalent to "#E0" and does not take
 * into account significant digits. The currencyFormat will default to the
 * three-letter name of the currency if no explicit name/symbol is provided.
 */
class NumberFormat {
  /** Variables to determine how number printing behaves. */
  // TODO(alanknight): If these remain as variables and are set based on the
  // pattern, can we make them final?
  String _negativePrefix = '-';
  String _positivePrefix = '';
  String _negativeSuffix = '';
  String _positiveSuffix = '';
  /**
   * How many numbers in a group when using punctuation to group digits in
   * large numbers. e.g. in en_US: "1,000,000" has a grouping size of 3 digits
   * between commas.
   */
  int _groupingSize = 3;
  /**
   * In some formats the last grouping size may be different than previous
   * ones, e.g. Hindi.
   */
  int _finalGroupingSize = 3;
  /**
   * Set to true if the format has explicitly set the grouping size.
   */
  bool _groupingSizeSetExplicitly = false;
  bool _decimalSeparatorAlwaysShown = false;
  bool _useSignForPositiveExponent = false;
  bool _useExponentialNotation = false;

  int maximumIntegerDigits = 40;
  int minimumIntegerDigits = 1;
  int maximumFractionDigits = 3;
  int minimumFractionDigits = 0;
  int minimumExponentDigits = 0;

  int _multiplier = 1;

  /**
   * Stores the pattern used to create this format. This isn't used, but
   * is helpful in debugging.
   */
  String _pattern;

  /** The locale in which we print numbers. */
  final String _locale;

  /** Caches the symbols used for our locale. */
  NumberSymbols _symbols;

  /** The name (or symbol) of the currency to print. */
  String currencyName;

  /**
   * Transient internal state in which to build up the result of the format
   * operation. We can have this be just an instance variable because Dart is
   * single-threaded and unless we do an asynchronous operation in the process
   * of formatting then there will only ever be one number being formatted
   * at a time. In languages with threads we'd need to pass this on the stack.
   */
  final StringBuffer _buffer = new StringBuffer();

  /**
   * Create a number format that prints using [newPattern] as it applies in
   * [locale].
   */
  factory NumberFormat([String newPattern, String locale]) =>
      new NumberFormat._forPattern(locale, (x) => newPattern);

  /** Create a number format that prints as DECIMAL_PATTERN. */
  NumberFormat.decimalPattern([String locale]) : this._forPattern(locale,
      (x) => x.DECIMAL_PATTERN);

  /** Create a number format that prints as PERCENT_PATTERN. */
  NumberFormat.percentPattern([String locale]) : this._forPattern(locale,
      (x) => x.PERCENT_PATTERN);

  /** Create a number format that prints as SCIENTIFIC_PATTERN. */
  NumberFormat.scientificPattern([String locale]) : this._forPattern(locale,
      (x) => x.SCIENTIFIC_PATTERN);

  /**
   * Create a number format that prints as CURRENCY_PATTERN. If provided,
   * use [nameOrSymbol] in place of the default currency name. e.g.
   *        var eurosInCurrentLocale = new NumberFormat
   *            .currencyPattern(Intl.defaultLocale, "€");
   */
  NumberFormat.currencyPattern([String locale, String nameOrSymbol]) :
      this._forPattern(locale, (x) => x.CURRENCY_PATTERN, nameOrSymbol);

  /**
   * Create a number format that prints in a pattern we get from
   * the [getPattern] function using the locale [locale].
   */
  NumberFormat._forPattern(String locale, Function getPattern,
      [this.currencyName]) :
        _locale = Intl.verifiedLocale(locale, localeExists) {
    _symbols = numberFormatSymbols[_locale];
    if (currencyName == null) {
      currencyName = _symbols.DEF_CURRENCY_CODE;
    }
    _setPattern(getPattern(_symbols));
  }

  /**
   * Return the locale code in which we operate, e.g. 'en_US' or 'pt'.
   */
  String get locale => _locale;

  /**
   * Return true if the locale exists, or if it is null. The null case
   * is interpreted to mean that we use the default locale.
   */
  static bool localeExists(localeName) {
    if (localeName == null) return false;
    return numberFormatSymbols.containsKey(localeName);
  }

  /**
   * Return the symbols which are used in our locale. Cache them to avoid
   * repeated lookup.
   */
  NumberSymbols get symbols => _symbols;

  /**
   * Format [number] according to our pattern and return the formatted string.
   */
  String format(num number) {
    // TODO(alanknight): Do we have to do anything for printing numbers bidi?
    // Or are they always printed left to right?
    if (number.isNaN) return symbols.NAN;
    if (number.isInfinite) return "${_signPrefix(number)}${symbols.INFINITY}";

    _add(_signPrefix(number));
    _formatNumber(number.abs() * _multiplier);
    _add(_signSuffix(number));

    var result = _buffer.toString();
    _buffer.clear();
    return result;
  }

  /**
   * Parse the number represented by the string. If it's not
   * parseable, throws a [FormatException].
   */
  num parse(String text) => new _NumberParser(this, text).value;

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
  void _formatExponential(num number) {
    if (number == 0.0) {
      _formatFixed(number);
      _formatExponent(0);
      return;
    }

    var exponent = (log(number) / log(10)).floor();
    var mantissa = number / pow(10.0, exponent);

    var minIntDigits = minimumIntegerDigits;
    if (maximumIntegerDigits > 1 && maximumIntegerDigits > minimumIntegerDigits)
        {
      // A repeating range is defined; adjust to it as follows.
      // If repeat == 3, we have 6,5,4=>3; 3,2,1=>0; 0,-1,-2=>-3;
      // -3,-4,-5=>-6, etc. This takes into account that the
      // exponent we have here is off by one from what we expect;
      // it is for the format 0.MMMMMx10^n.
      while ((exponent % maximumIntegerDigits) != 0) {
        mantissa *= 10;
        exponent--;
      }
      minIntDigits = 1;
    } else {
      // No repeating range is defined, use minimum integer digits.
      if (minimumIntegerDigits < 1) {
        exponent++;
        mantissa /= 10;
      } else {
        exponent -= minimumIntegerDigits - 1;
        mantissa *= pow(10, minimumIntegerDigits - 1);
      }
    }
    _formatFixed(mantissa);
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
    _pad(minimumExponentDigits, exponent.toString());
  }

  /** Used to test if we have exceeded Javascript integer limits. */
  final _maxInt = pow(2, 52);

  /**
   * Format the basic number portion, inluding the fractional digits.
   */
  void _formatFixed(num number) {
    // Very fussy math to get integer and fractional parts.
    var power = pow(10, maximumFractionDigits);
    var shiftedNumber = (number * power);
    // We must not roundToDouble() an int or it will lose precision. We must not
    // round() a large double or it will take its loss of precision and
    // preserve it in an int, which we will then print to the right
    // of the decimal place. Therefore, only roundToDouble if we are already
    // a double.
    if (shiftedNumber is double) {
      shiftedNumber = shiftedNumber.roundToDouble();
    }
    var intValue, fracValue;
    if (shiftedNumber.isInfinite) {
      intValue = number.toInt();
      fracValue = 0;
    } else {
      intValue = shiftedNumber.round() ~/ power;
      fracValue = (shiftedNumber - intValue * power).floor();
    }
    var fractionPresent = minimumFractionDigits > 0 || fracValue > 0;

    // If the int part is larger than 2^52 and we're on Javascript (so it's
    // really a float) it will lose precision, so pad out the rest of it
    // with zeros. Check for Javascript by seeing if an integer is double.
    var paddingDigits = '';
    if (1 is double && intValue > _maxInt) {
      var howManyDigitsTooBig = (log(intValue) / LN10).ceil() - 16;
      var divisor = pow(10, howManyDigitsTooBig).round();
      paddingDigits = symbols.ZERO_DIGIT * howManyDigitsTooBig.toInt();

      intValue = (intValue / divisor).truncate();
    }
    var integerDigits = "${intValue}${paddingDigits}".codeUnits;
    var digitLength = integerDigits.length;

    if (_hasPrintableIntegerPart(intValue)) {
      _pad(minimumIntegerDigits - digitLength);
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
    var fractionCodes = fractionPart.codeUnits;
    var fractionLength = fractionPart.length;
    while (fractionCodes[fractionLength - 1] == _zero &&
        fractionLength > minimumFractionDigits + 1) {
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
  bool _hasPrintableIntegerPart(int intValue) =>
      intValue > 0 || minimumIntegerDigits > 0;

  /** A group of methods that provide support for writing digits and other
   * required characters into [_buffer] easily.
   */
  void _add(String x) { _buffer.write(x);}
  void _addCharCode(int x) { _buffer.writeCharCode(x);}
  void _addZero() { _buffer.write(symbols.ZERO_DIGIT);}
  void _addDigit(int x) { _buffer.writeCharCode(_localeZero + x - _zero);}

  /** Print padding up to [numberOfDigits] above what's included in [basic]. */
  void _pad(int numberOfDigits, [String basic = '']) {
    for (var i = 0; i < numberOfDigits - basic.length; i++) {
      _add(symbols.ZERO_DIGIT);
    }
    for (var x in basic.codeUnits) {
      _addDigit(x);
    }
  }

  /**
   * We are printing the digits of the number from left to right. We may need
   * to print a thousands separator or other grouping character as appropriate
   * to the locale. So we find how many places we are from the end of the number
   * by subtracting our current [position] from the [totalLength] and printing
   * the separator character every [_groupingSize] digits, with the final
   * grouping possibly being of a different size, [_finalGroupingSize].
   */
  void _group(int totalLength, int position) {
    var distanceFromEnd = totalLength - position;
    if (distanceFromEnd <= 1 || _groupingSize <= 0) return;
    if (distanceFromEnd == _finalGroupingSize + 1) {
      _add(symbols.GROUP_SEP);
    } else if ((distanceFromEnd > _finalGroupingSize) &&
        (distanceFromEnd - _finalGroupingSize) % _groupingSize == 1) {
      _add(symbols.GROUP_SEP);
    }
  }

  /** Returns the code point for the character '0'. */
  final _zero = '0'.codeUnits.first;

  /** Returns the code point for the locale's zero digit. */
  // Note that there is a slight risk of a locale's zero digit not fitting
  // into a single code unit, but it seems very unlikely, and if it did,
  // there's a pretty good chance that our assumptions about being able to do
  // arithmetic on it would also be invalid.
  get _localeZero => symbols.ZERO_DIGIT.codeUnits.first;

  /**
   * Returns the prefix for [x] based on whether it's positive or negative.
   * In en_US this would be '' and '-' respectively.
   */
  String _signPrefix(num x) => x.isNegative ? _negativePrefix : _positivePrefix;

  /**
   * Returns the suffix for [x] based on wether it's positive or negative.
   * In en_US there are no suffixes for positive or negative.
   */
  String _signSuffix(num x) => x.isNegative ? _negativeSuffix : _positiveSuffix;

  void _setPattern(String newPattern) {
    if (newPattern == null) return;
    // Make spaces non-breaking
    _pattern = newPattern.replaceAll(' ', '\u00a0');
    var parser = new _NumberFormatParser(this, newPattern, currencyName);
    parser.parse();
  }

  String toString() => "NumberFormat($_locale, $_pattern)";
}

/**
 *  A one-time object for parsing a particular numeric string. One-time here
 * means an instance can only parse one string. This is implemented by
 * transforming from a locale-specific format to one that the system can parse,
 * then calls the system parsing methods on it.
 */
class _NumberParser {

  /** The format for which we are parsing. */
  final NumberFormat format;

  /** The text we are parsing. */
  final String text;

  /** What we use to iterate over the input text. */
  final _Stream input;

  /**
   * The result of parsing [text] according to [format]. Automatically
   * populated in the constructor.
   */
  num value;

  /** The symbols used by our format. */
  NumberSymbols get symbols => format.symbols;

  /** Where we accumulate the normalized representation of the number. */
  final StringBuffer _normalized = new StringBuffer();

  /**
   * Did we see something that indicates this is, or at least might be,
   * a positive number.
   */
  bool gotPositive = false;

  /**
   * Did we see something that indicates this is, or at least might be,
   * a negative number.
   */
  bool gotNegative = false;
  /**
   * Did we see the required positive suffix at the end. Should
   * match [gotPositive].
   */
  bool gotPositiveSuffix = false;
  /**
   * Did we see the required negative suffix at the end. Should
   * match [gotNegative].
   */
  bool gotNegativeSuffix = false;

  /** Should we stop parsing before hitting the end of the string. */
  bool done = false;

  /** Have we already skipped over any required prefixes. */
  bool prefixesSkipped = false;

  /** If the number is percent or permill, what do we divide by at the end. */
  int scale = 1;

  String get _positivePrefix => format._positivePrefix;
  String get _negativePrefix => format._negativePrefix;
  String get _positiveSuffix => format._positiveSuffix;
  String get _negativeSuffix => format._negativeSuffix;
  int get _zero => format._zero;
  int get _localeZero => format._localeZero;

  /**
   *  Create a new [_NumberParser] on which we can call parse().
   */
  _NumberParser(this.format, text) : this.text = text,
      this.input = new _Stream(text) {
    value = parse();
  }

  /**
   *  The strings we might replace with functions that return the replacement
   * values. They are functions because we might need to check something
   * in the context. Note that the ordering is important here. For example,
   * [symbols.PERCENT] might be " %", and we must handle that before we
   * look at an individual space.
   */
  Map<String, Function> get replacements => _replacements == null ?
      _replacements = _initializeReplacements() : _replacements;

  var _replacements;

  Map _initializeReplacements() => {
      symbols.DECIMAL_SEP: () => '.',
      symbols.EXP_SYMBOL: () => 'E',
      symbols.GROUP_SEP: handleSpace,
      symbols.PERCENT: () {
        scale = _NumberFormatParser._PERCENT_SCALE;
        return '';
      },
      symbols.PERMILL: () {
        scale = _NumberFormatParser._PER_MILLE_SCALE;
        return '';
      },
      ' ' : handleSpace,
      '\u00a0' : handleSpace,
      '+': () => '+',
      '-': () => '-',
    };

  invalidFormat() =>
      throw new FormatException("Invalid number: ${input.contents}");

  /**
   * Replace a space in the number with the normalized form. If space is not
   * a significant character (normally grouping) then it's just invalid. If it
   * is the grouping character, then it's only valid if it's followed by a
   * digit. e.g. '$12 345.00'
   */
  handleSpace() =>
      groupingIsNotASpaceOrElseItIsSpaceFollowedByADigit ? '' : invalidFormat();

  /**
   * Determine if a space is a valid character in the number. See [handleSpace].
   */
  bool get groupingIsNotASpaceOrElseItIsSpaceFollowedByADigit {
    if (symbols.GROUP_SEP != '\u00a0' || symbols.GROUP_SEP != ' ') return true;
    var peeked = input.peek(symbols.GROUP_SEP.length + 1);
    return asDigit(peeked[peeked.length - 1]) != null;
  }

  /**
   * Turn [char] into a number representing a digit, or null if it doesn't
   * represent a digit in this locale.
   */
  int asDigit(String char) {
    var charCode = char.codeUnitAt(0);
    var digitValue = charCode - _localeZero;
    if (digitValue >= 0 && digitValue < 10) {
      return digitValue;
    } else {
      return null;
    }
  }

  /**
   * Check to see if the input begins with either the positive or negative
   * prefixes. Set the [gotPositive] and [gotNegative] variables accordingly.
   */
  void checkPrefixes({bool skip: false}) {
    bool checkPrefix(String prefix, skip) {
        var matched = prefix.isNotEmpty && input.startsWith(prefix);
        if (skip && matched) input.read(prefix.length);
        return matched;
    }

    // TODO(alanknight): There's a faint possibility of a bug here where
    // a positive prefix is followed by a negative prefix that's also a valid
    // part of the number, but that seems very unlikely.
    if (checkPrefix(_positivePrefix, skip)) gotPositive = true;
    if (checkPrefix(_negativePrefix, skip)) gotNegative = true;

    // Copied from Closure. It doesn't seem to be necessary to pass the test
    // suite, so I'm not sure it's really needed.
    if (gotPositive && gotNegative) {
      if (_positivePrefix.length > _negativePrefix.length) {
        gotNegative = false;
      } else if (_negativePrefix.length > _positivePrefix.length) {
        gotPositive = false;
      }
    }
  }

  /**
   * If the rest of our input is either the positive or negative suffix,
   * set [gotPositiveSuffix] or [gotNegativeSuffix] accordingly.
   */
  void checkSuffixes() {
    var remainder = input.rest();
    if (remainder == _positiveSuffix) gotPositiveSuffix = true;
    if (remainder == _negativeSuffix) gotNegativeSuffix = true;
  }

  /**
   * We've encountered a character that's not a digit. Go through our
   * replacement rules looking for how to handle it. If we see something
   * that's not a digit and doesn't have a replacement, then we're done
   * and the number is probably invalid.
   */
  void processNonDigit() {
    for (var key in replacements.keys) {
      if (input.startsWith(key)) {
        _normalized.write(replacements[key]());
        input.read(key.length);
        return;
      }
    }
    // It might just be a prefix that we haven't skipped. We don't want to
    // skip them initially because they might also be semantically meaningful,
    // e.g. leading %. So we allow them through the loop, but only once.
    if (input.index == 0 && !prefixesSkipped) {
      prefixesSkipped = true;
      checkPrefixes(skip: true);
    } else {
      done = true;
    }
  }

  /**
   * Parse [text] and return the resulting number. Throws [FormatException]
   * if we can't parse it.
   */
  num parse() {
    if (text == symbols.NAN) return double.NAN;
    if (text == "$_positivePrefix${symbols.INFINITY}$_positiveSuffix") {
      return double.INFINITY;
    }
    if (text == "$_negativePrefix${symbols.INFINITY}$_negativeSuffix") {
      return double.NEGATIVE_INFINITY;
    }

    checkPrefixes();
    var parsed = parseNumber(input);

    if (gotPositive && !gotPositiveSuffix) invalidNumber();
    if (gotNegative && !gotNegativeSuffix) invalidNumber();
    if (!input.atEnd()) invalidNumber();

    return parsed;
  }

  /** The number is invalid, throw a [FormatException]. */
  void invalidNumber() =>
      throw new FormatException("Invalid Number: ${input.contents}");

  /**
   * Parse the number portion of the input, i.e. not any prefixes or suffixes,
   * and assuming NaN and Infinity are already handled.
   */
  num parseNumber(_Stream input) {
    while (!done && !input.atEnd()) {
      int digit = asDigit(input.peek());
      if (digit != null) {
        _normalized.writeCharCode(_zero + digit);
        input.next();
      } else {
        processNonDigit();
      }
      checkSuffixes();
    }

    var normalizedText = _normalized.toString();
    var parsed = int.parse(normalizedText, onError: (message) => null);
    if (parsed == null) parsed = double.parse(normalizedText);
    return parsed / scale;
  }
}

/**
 * Private class that parses the numeric formatting pattern and sets the
 * variables in [format] to appropriate values. Instances of this are
 * transient and store parsing state in instance variables, so can only be used
 * to parse a single pattern.
 */
class _NumberFormatParser {

  /**
   * The special characters in the pattern language. All others are treated
   * as literals.
   */
  static const _PATTERN_SEPARATOR = ';';
  static const _QUOTE = "'";
  static const _PATTERN_DIGIT = '#';
  static const _PATTERN_ZERO_DIGIT = '0';
  static const _PATTERN_GROUPING_SEPARATOR = ',';
  static const _PATTERN_DECIMAL_SEPARATOR = '.';
  static const _PATTERN_CURRENCY_SIGN = '\u00A4';
  static const _PATTERN_PER_MILLE = '\u2030';
  static const _PER_MILLE_SCALE = 1000;
  static const _PATTERN_PERCENT = '%';
  static const _PERCENT_SCALE = 100;
  static const _PATTERN_EXPONENT = 'E';
  static const _PATTERN_PLUS = '+';

  /** The format whose state we are setting. */
  final NumberFormat format;

  /** The pattern we are parsing. */
  final _StringIterator pattern;

  /** We can be passed a specific currency symbol, regardless of the locale. */
  String currencyName;

  /**
   * Create a new [_NumberFormatParser] for a particular [NumberFormat] and
   * [input] pattern.
   */
  _NumberFormatParser(this.format, input, this.currencyName) :
      pattern = _iterator(input) {
    pattern.moveNext();
  }

  /** The [NumberSymbols] for the locale in which our [format] prints. */
  NumberSymbols get symbols => format.symbols;

  /** Parse the input pattern and set the values. */
  void parse() {
    format._positivePrefix = _parseAffix();
    var trunk = _parseTrunk();
    format._positiveSuffix = _parseAffix();
    // If we have separate positive and negative patterns, now parse the
    // the negative version.
    if (pattern.current == _NumberFormatParser._PATTERN_SEPARATOR) {
      pattern.moveNext();
      format._negativePrefix = _parseAffix();
      // Skip over the negative trunk, verifying that it's identical to the
      // positive trunk.
      for (var each in _iterable(trunk)) {
        if (pattern.current != each && pattern.current != null) {
          throw new FormatException(
              "Positive and negative trunks must be the same");
        }
        pattern.moveNext();
      }
      format._negativeSuffix = _parseAffix();
    } else {
      // If no negative affix is specified, they share the same positive affix.
      format._negativePrefix = format._negativePrefix + format._positivePrefix;
      format._negativeSuffix = format._positiveSuffix + format._negativeSuffix;
    }
  }

  /**
   * Variable used in parsing prefixes and suffixes to keep track of
   * whether or not we are in a quoted region.
   */
  bool inQuote = false;

  /**
   * Parse a prefix or suffix and return the prefix/suffix string. Note that
   * this also may modify the state of [format].
   */
  String _parseAffix() {
    var affix = new StringBuffer();
    inQuote = false;
    while (parseCharacterAffix(affix) && pattern.moveNext());
    return affix.toString();
  }

  /**
   * Parse an individual character as part of a prefix or suffix.  Return true
   * if we should continue to look for more affix characters, and false if
   * we have reached the end.
   */
  bool parseCharacterAffix(StringBuffer affix) {
    var ch = pattern.current;
    if (ch == null) return false;
    if (ch == _QUOTE) {
      if (pattern.peek == _QUOTE) {
        pattern.moveNext();
        affix.write(_QUOTE); // 'don''t'
      } else {
        inQuote = !inQuote;
      }
      return true;
    }

    if (inQuote) {
      affix.write(ch);
    } else {
      switch (ch) {
        case _PATTERN_DIGIT:
        case _PATTERN_ZERO_DIGIT:
        case _PATTERN_GROUPING_SEPARATOR:
        case _PATTERN_DECIMAL_SEPARATOR:
        case _PATTERN_SEPARATOR:
          return false;
        case _PATTERN_CURRENCY_SIGN:
          // TODO(alanknight): Handle the local/global/portable currency signs
          affix.write(currencyName);
          break;
        case _PATTERN_PERCENT:
          if (format._multiplier != 1 && format._multiplier != _PERCENT_SCALE) {
            throw new FormatException('Too many percent/permill');
          }
          format._multiplier = _PERCENT_SCALE;
          affix.write(symbols.PERCENT);
          break;
        case _PATTERN_PER_MILLE:
          if (format._multiplier != 1 &&
              format._multiplier != _PER_MILLE_SCALE) {
            throw new FormatException('Too many percent/permill');
          }
          format._multiplier = _PER_MILLE_SCALE;
          affix.write(symbols.PERMILL);
          break;
        default:
          affix.write(ch);
      }
    }
    return true;
  }

  /** Variables used in [_parseTrunk] and [parseTrunkCharacter]. */
  var decimalPos = -1;
  var digitLeftCount = 0;
  var zeroDigitCount = 0;
  var digitRightCount = 0;
  var groupingCount = -1;

  /**
   * Parse the "trunk" portion of the pattern, the piece that doesn't include
   * positive or negative prefixes or suffixes.
   */
  String _parseTrunk() {
    var loop = true;
    var trunk = new StringBuffer();
    while (pattern.current != null && loop) {
      loop = parseTrunkCharacter(trunk);
    }

    if (zeroDigitCount == 0 && digitLeftCount > 0 && decimalPos >= 0) {
      // Handle '###.###' and '###.' and '.###'
      // Handle '.###'
      var n = decimalPos == 0 ? 1 : decimalPos;
      digitRightCount = digitLeftCount - n;
      digitLeftCount = n - 1;
      zeroDigitCount = 1;
    }

    // Do syntax checking on the digits.
    if (decimalPos < 0 && digitRightCount > 0 ||
        decimalPos >= 0 && (decimalPos < digitLeftCount ||
            decimalPos > digitLeftCount + zeroDigitCount) ||
            groupingCount == 0) {
      throw new FormatException('Malformed pattern "${pattern.input}"');
    }
    var totalDigits = digitLeftCount + zeroDigitCount + digitRightCount;

    format.maximumFractionDigits =
        decimalPos >= 0 ? totalDigits - decimalPos : 0;
    if (decimalPos >= 0) {
      format.minimumFractionDigits =
          digitLeftCount + zeroDigitCount - decimalPos;
      if (format.minimumFractionDigits < 0) {
        format.minimumFractionDigits = 0;
      }
    }

    // The effectiveDecimalPos is the position the decimal is at or would be at
    // if there is no decimal. Note that if decimalPos<0, then digitTotalCount
    // == digitLeftCount + zeroDigitCount.
    var effectiveDecimalPos = decimalPos >= 0 ? decimalPos : totalDigits;
    format.minimumIntegerDigits = effectiveDecimalPos - digitLeftCount;
    if (format._useExponentialNotation) {
      format.maximumIntegerDigits = digitLeftCount +
          format.minimumIntegerDigits;

      // In exponential display, we need to at least show something.
      if (format.maximumFractionDigits == 0 &&
          format.minimumIntegerDigits == 0) {
        format.minimumIntegerDigits = 1;
      }
    }

    format._finalGroupingSize = max(0, groupingCount);
    if (!format._groupingSizeSetExplicitly) {
      format._groupingSize = format._finalGroupingSize;
    }
    format._decimalSeparatorAlwaysShown = decimalPos == 0 ||
        decimalPos == totalDigits;

    return trunk.toString();
  }

  /**
   * Parse an individual character of the trunk. Return true if we should
   * continue to look for additional trunk characters or false if we have
   * reached the end.
   */
  bool parseTrunkCharacter(trunk) {
    var ch = pattern.current;
    switch (ch) {
      case _PATTERN_DIGIT:
        if (zeroDigitCount > 0) {
          digitRightCount++;
        } else {
          digitLeftCount++;
        }
        if (groupingCount >= 0 && decimalPos < 0) {
          groupingCount++;
        }
        break;
      case _PATTERN_ZERO_DIGIT:
        if (digitRightCount > 0) {
          throw new FormatException('Unexpected "0" in pattern "' +
              pattern.input + '"');
        }
        zeroDigitCount++;
        if (groupingCount >= 0 && decimalPos < 0) {
          groupingCount++;
        }
        break;
      case _PATTERN_GROUPING_SEPARATOR:
        if (groupingCount > 0) {
          format._groupingSizeSetExplicitly = true;
          format._groupingSize = groupingCount;
        }
        groupingCount = 0;
        break;
      case _PATTERN_DECIMAL_SEPARATOR:
        if (decimalPos >= 0) {
          throw new FormatException(
              'Multiple decimal separators in pattern "$pattern"');
        }
        decimalPos = digitLeftCount + zeroDigitCount + digitRightCount;
        break;
      case _PATTERN_EXPONENT:
        trunk.write(ch);
        if (format._useExponentialNotation) {
          throw new FormatException(
              'Multiple exponential symbols in pattern "$pattern"');
        }
        format._useExponentialNotation = true;
        format.minimumExponentDigits = 0;

        // exponent pattern can have a optional '+'.
        pattern.moveNext();
        var nextChar = pattern.current;
        if (nextChar == _PATTERN_PLUS) {
          trunk.write(pattern.current);
          pattern.moveNext();
          format._useSignForPositiveExponent = true;
        }

        // Use lookahead to parse out the exponential part
        // of the pattern, then jump into phase 2.
        while (pattern.current == _PATTERN_ZERO_DIGIT) {
          trunk.write(pattern.current);
          pattern.moveNext();
          format.minimumExponentDigits++;
        }

        if ((digitLeftCount + zeroDigitCount) < 1 ||
            format.minimumExponentDigits < 1) {
          throw new FormatException('Malformed exponential pattern "$pattern"');
        }
        return false;
      default:
        return false;
    }
    trunk.write(ch);
    pattern.moveNext();
    return true;
  }
}

/**
 * Returns an [Iterable] on the string as a list of substrings.
 */
Iterable _iterable(String s) => new _StringIterable(s);

/**
 * Return an iterator on the string as a list of substrings.
 */
Iterator _iterator(String s) => new _StringIterator(s);

// TODO(nweiz): remove this when issue 3780 is fixed.
/**
 * Provides an Iterable that wraps [_iterator] so it can be used in a `for`
 * loop.
 */
class _StringIterable extends IterableBase<String> {
  final Iterator<String> iterator;

  _StringIterable(String s) : iterator = _iterator(s);
}

/**
 * Provides an iterator over a string as a list of substrings, and also
 * gives us a lookahead of one via the [peek] method.
 */
class _StringIterator implements Iterator<String> {
  final String input;
  int nextIndex = 0;
  String _current = null;

  _StringIterator(input) : input = _validate(input);

  String get current => _current;

  bool moveNext() {
    if (nextIndex >= input.length) {
      _current = null;
      return false;
    }
    _current = input[nextIndex++];
    return true;
  }

  String get peek => nextIndex >= input.length ? null : input[nextIndex];

  Iterator<String> get iterator => this;

  static String _validate(input) {
    if (input is! String) throw new ArgumentError(input);
    return input;
  }

}
