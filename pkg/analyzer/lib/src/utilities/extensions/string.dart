// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension IntExtension on int {
  bool get isComma => this == 0x2C;

  bool get isDigit => this >= 0x30 && this <= 0x39;

  /// Whether this, as an ASCII character, is a newline or carriage return
  /// character.
  bool get isEOL => this == 0x0D || this == 0x0A;

  bool get isEqual => this == 0x3D;

  bool get isLetter =>
      (this >= 0x41 && this <= 0x5A) || (this >= 0x61 && this <= 0x7A);

  bool get isLetterOrDigit => isLetter || isDigit;

  bool get isLetterOrDigitOrUnderscore => isLetter || isDigit || isUnderscore;

  /// Whether this, as an ASCII character, is a newline (not a carriage
  /// return) character.
  bool get isLF => this == 0x0A;

  bool get isSlash => this == 0x2F;

  /// Whether this, as an ASCII character, is a space or tab character.
  bool get isSpace => this == 0x20 || this == 0x09;

  bool get isUnderscore => this == 0x5F;

  /// Whether this, as an ASCII character, is a space (as per [isSpace]) or EOL
  /// character (as per [isEOL]).
  bool get isWhitespace => isSpace || isEOL;

  int? get nullIfNegative => isNegative ? null : this;
}

extension IterableOfStringExtension on Iterable<String> {
  /// Produce a comma-separated representation of this iterable, with the last
  /// element preceded by 'and' when there are more than two elements in this
  /// iterable.
  String get commaSeparatedWithAnd => _commaSeparated('and');

  /// Produce a comma-separated representation of this iterable, with the last
  /// element preceded by 'or' when there are more than two elements in this
  /// iterable.
  String get commaSeparatedWithOr => _commaSeparated('or');

  /// Produce a comma-separated representation of this iterable, with the last
  /// element preceded by 'and' when there are more than two elements in this
  /// iterable, and a pair of single quotes surrounding each element.
  String get quotedAndCommaSeparatedWithAnd =>
      _commaSeparated('and', quoted: true);

  /// Produce a comma-separated representation of this iterable, with the last
  /// element preceded by 'or' when there are more than two elements in this
  /// iterable, and a pair of single quotes surrounding each element.
  String get quotedAndCommaSeparatedWithOr =>
      _commaSeparated('or', quoted: true);

  /// Produce a comma-separated representation of this iterable, with the last
  /// element preceded by the [conjunction] when there are more than two
  /// elements in this iterable.
  ///
  /// Each element is surrounded by a pair of single quotes if [quoted] is true.
  String _commaSeparated(String conjunction, {bool quoted = false}) {
    var iterator = this.iterator;

    // If has zero elements.
    if (!iterator.moveNext()) {
      return '';
    }
    var first = iterator.current;

    // If has one element.
    if (!iterator.moveNext()) {
      return quoted ? "'$first'" : first;
    }
    var second = iterator.current;

    // If has two elements.
    if (!iterator.moveNext()) {
      return quoted
          ? "'$first' $conjunction '$second'"
          : '$first $conjunction $second';
    }
    var third = iterator.current;

    var buffer = StringBuffer();
    _writeElement(buffer, first, quoted);
    buffer.write(', ');
    _writeElement(buffer, second, quoted);

    var nextToWrite = third;
    while (iterator.moveNext()) {
      buffer.write(', ');
      _writeElement(buffer, nextToWrite, quoted);
      nextToWrite = iterator.current;
    }
    buffer.write(', ');
    buffer.write(conjunction);
    buffer.write(' ');
    _writeElement(buffer, nextToWrite, quoted);
    return buffer.toString();
  }

  void _writeElement(StringBuffer buffer, String element, bool quoted) {
    if (quoted) {
      buffer.write("'");
    }
    buffer.write(element);
    if (quoted) {
      buffer.write("'");
    }
  }
}

extension Pluralized on String {
  String pluralized(int count) => count == 1 ? toString() : '${toString()}s';
}

extension StringExtension on String {
  String? get nullIfEmpty {
    return isNotEmpty ? this : null;
  }

  /// If [length] is above the [limit], replace the middle with `...`.
  String elideTo(int limit) {
    if (length > limit) {
      var headLength = limit ~/ 2 - 1;
      var tailLength = limit - headLength - 3;
      return '${substring(0, headLength)}...${substring(length - tailLength)}';
    }
    return this;
  }

  /// If this is equal to [value], return [then], otherwise return `this`.
  String ifEqualThen(String value, String then) {
    return this == value ? then : this;
  }

  String ifNotEmptyOrElse(String orElse) {
    return isNotEmpty ? this : orElse;
  }

  String removePrefixOrSelf(String prefix) {
    if (startsWith(prefix)) {
      return substring(prefix.length);
    } else {
      return this;
    }
  }

  String? removeSuffix(String suffix) {
    if (endsWith(suffix)) {
      return substring(0, length - suffix.length);
    } else {
      return null;
    }
  }

  /// Converts `camelCase` / `PascalCase` to `SCREAMING_SNAKE_CASE`.
  /// Examples:
  ///  - camelCase        -> CAMEL_CASE
  ///  - HTTPRequest      -> HTTP_REQUEST
  ///  - myURLId2Parser   -> MY_URL_ID_2_PARSER
  ///  - _privateField    -> _PRIVATE_FIELD
  String toScreamingSnake() {
    if (isEmpty) return this;

    // Preserve leading underscores (e.g., Dart private members).
    var leading = RegExp(r'^_+').stringMatch(this) ?? '';
    var result = substring(leading.length);

    // Split lower/digit -> Upper (e.g., "fooBar" -> "foo_Bar", "v2X" -> "v2_X").
    result = result.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match[1]}_${match[2]}',
    );

    // Split acronym -> Word (e.g., "HTMLParser" -> "HTML_Parser").
    result = result.replaceAllMapped(
      RegExp(r'([A-Z]+)([A-Z][a-z])'),
      (match) => '${match[1]}_${match[2]}',
    );

    // Separate letters and digits both ways (e.g., "ID10T" -> "ID_10_T").
    result = result.replaceAllMapped(
      RegExp(r'([A-Za-z])([0-9])'),
      (match) => '${match[1]}_${match[2]}',
    );
    result = result.replaceAllMapped(
      RegExp(r'([0-9])([A-Za-z])'),
      (match) => '${match[1]}_${match[2]}',
    );

    // Normalize separators and scream.
    result = result.replaceAll(RegExp(r'_+'), '_');
    return leading + result.toUpperCase();
  }
}
