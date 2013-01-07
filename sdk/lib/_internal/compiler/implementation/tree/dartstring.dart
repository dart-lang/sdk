// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of tree;

/**
 * The [DartString] type represents a Dart string value as a sequence of Unicode
 * Scalar Values.
 * After parsing, any valid [LiteralString] will contain a [DartString]
 * representing its content after removing quotes and resolving escapes in
 * its source.
 */
abstract class DartString extends Iterable<int> {
  factory DartString.empty() => const LiteralDartString("");
  // This is a convenience constructor. If you need a const literal DartString,
  // use [const LiteralDartString(string)] directly.
  factory DartString.literal(String string) => new LiteralDartString(string);
  factory DartString.rawString(SourceString source, int length) =>
      new RawSourceDartString(source, length);
  factory DartString.escapedString(SourceString source, int length) =>
      new EscapedSourceDartString(source, length);
  factory DartString.concat(DartString first, DartString second) {
    if (first.isEmpty) return second;
    if (second.isEmpty) return first;
    return new ConsDartString(first, second);
  }
  const DartString();
  int get length;
  bool get isEmpty => length == 0;
  Iterator<int> get iterator;
  String slowToString();

  bool operator ==(var other) {
    if (other is !DartString) return false;
    DartString otherString = other;
    if (length != otherString.length) return false;
    Iterator it1 = iterator;
    Iterator it2 = otherString.iterator;
    while (it1.moveNext()) {
      if (!it2.moveNext()) return false;
      if (it1.current != it2.current) return false;
    }
    return true;
  }
  String toString() => "DartString#${length}:${slowToString()}";
  SourceString get source;
}


/**
 * A [DartString] where the content is represented by an actual [String].
 */
class LiteralDartString extends DartString {
  final String string;
  const LiteralDartString(this.string);
  int get length => string.length;
  Iterator<int> get iterator => new StringCodeIterator(string);
  String slowToString() => string;
  SourceString get source => new StringWrapper(string);
}

/**
 * A [DartString] where the content comes from a slice of the program source.
 */
abstract class SourceBasedDartString extends DartString {
  String toStringCache = null;
  final SourceString source;
  final int length;
  SourceBasedDartString(this.source, this.length);
  Iterator<int> get iterator;
}

/**
 * Special case of a [SourceBasedDartString] where we know the source doesn't
 * contain any escapes.
 */
class RawSourceDartString extends SourceBasedDartString {
  RawSourceDartString(source, length) : super(source, length);
  Iterator<int> get iterator => source.iterator;
  String slowToString() {
    if (toStringCache != null) return toStringCache;
    toStringCache  = source.slowToString();
    return toStringCache;
  }
}

/**
 * General case of a [SourceBasedDartString] where the source might contain
 * escapes.
 */
class EscapedSourceDartString extends SourceBasedDartString {
  EscapedSourceDartString(source, length) : super(source, length);
  Iterator<int> get iterator {
    if (toStringCache != null) return new StringCodeIterator(toStringCache);
    return new StringEscapeIterator(source);
  }
  String slowToString() {
    if (toStringCache != null) return toStringCache;
    StringBuffer buffer = new StringBuffer();
    StringEscapeIterator it = new StringEscapeIterator(source);
    while (it.moveNext()) {
      buffer.addCharCode(it.current);
    }
    toStringCache = buffer.toString();
    return toStringCache;
  }
}

/**
 * The concatenation of two [DartString]s.
 */
class ConsDartString extends DartString {
  final DartString left;
  final DartString right;
  final int length;
  String toStringCache;
  ConsDartString(DartString left, DartString right)
      : this.left = left,
        this.right = right,
        length = left.length + right.length;

  Iterator<int> get iterator => new ConsDartStringIterator(this);

  String slowToString() {
    if (toStringCache != null) return toStringCache;
    toStringCache = left.slowToString().concat(right.slowToString());
    return toStringCache;
  }
  SourceString get source => new StringWrapper(slowToString());
}

class ConsDartStringIterator implements Iterator<int> {
  HasNextIterator<int> currentIterator;
  DartString right;
  bool hasNextLookAhead;
  int _current = null;

  ConsDartStringIterator(ConsDartString cons)
      : currentIterator = new HasNextIterator<int>(cons.left.iterator),
        right = cons.right {
    hasNextLookAhead = currentIterator.hasNext;
    if (!hasNextLookAhead) {
      nextPart();
    }
  }

  int get current => _current;

  bool moveNext() {
    if (!hasNextLookAhead) {
      _current = null;
      return false;
    }
    _current = currentIterator.next();
    hasNextLookAhead = currentIterator.hasNext;
    if (!hasNextLookAhead) {
      nextPart();
    }
    return true;
  }
  void nextPart() {
    if (right != null) {
      currentIterator = new HasNextIterator<int>(right.iterator);
      right = null;
      hasNextLookAhead = currentIterator.hasNext;
    }
  }
}

/**
 *Iterator that returns the actual string contents of a string with escapes.
 */
class StringEscapeIterator implements Iterator<int>{
  final Iterator<int> source;
  int _current = null;

  StringEscapeIterator(SourceString source) : this.source = source.iterator;

  int get current => _current;

  bool moveNext() {
    if (!source.moveNext()) {
      _current = null;
      return false;
    }
    int code = source.current;
    if (code != $BACKSLASH) {
      _current = code;
      return true;
    }
    source.moveNext();
    code = source.current;
    switch (code) {
      case $n: _current = $LF; break;
      case $r: _current = $CR; break;
      case $t: _current = $TAB; break;
      case $b: _current = $BS; break;
      case $f: _current = $FF; break;
      case $v: _current = $VTAB; break;
      case $x:
        source.moveNext();
        int value = hexDigitValue(source.current);
        source.moveNext();
        value = value * 16 + hexDigitValue(source.current);
        _current = value;
        break;
      case $u:
        int value = 0;
        source.moveNext();
        code = source.current;
        if (code == $OPEN_CURLY_BRACKET) {
          source.moveNext();
          while (source.current != $CLOSE_CURLY_BRACKET) {
            value = value * 16 + hexDigitValue(source.current);
            source.moveNext();
          }
          _current = value;
          break;
        }
        // Four digit hex value.
        value = hexDigitValue(code);
        for (int i = 0; i < 3; i++) {
          source.moveNext();
          value = value * 16 + hexDigitValue(source.current);
        }
        _current = value;
        break;
      default:
        _current = code;
    }
    return true;
  }
}

