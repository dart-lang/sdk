// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The [DartString] type represents a Dart string value as a sequence of Unicode
 * Scalar Values.
 * After parsing, any valid [LiteralString] will contain a [DartString]
 * representing its content after removing quotes and resolving escapes in
 * its source.
 */
abstract class DartString implements Iterable<int> {
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
  abstract int get length;
  bool get isEmpty => length == 0;
  abstract Iterator<int> iterator();
  abstract String slowToString();

  bool operator ==(var other) {
    if (other is !DartString) return false;
    DartString otherString = other;
    if (length != otherString.length) return false;
    Iterator it1 = iterator();
    Iterator it2 = otherString.iterator();
    while (it1.hasNext) {
      if (it1.next() != it2.next()) return false;
    }
    return true;
  }
  String toString() => "DartString#${length}:${slowToString()}";
  abstract SourceString get source;
}


/**
 * A [DartString] where the content is represented by an actual [String].
 */
class LiteralDartString extends DartString {
  final String string;
  const LiteralDartString(this.string);
  int get length => string.length;
  Iterator<int> iterator() => new StringCodeIterator(string);
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
  abstract Iterator<int> iterator();
}

/**
 * Special case of a [SourceBasedDartString] where we know the source doesn't
 * contain any escapes.
 */
class RawSourceDartString extends SourceBasedDartString {
  RawSourceDartString(source, length) : super(source, length);
  Iterator<int> iterator() => source.iterator();
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
  Iterator<int> iterator() {
    if (toStringCache != null) return new StringCodeIterator(toStringCache);
    return new StringEscapeIterator(source);
  }
  String slowToString() {
    if (toStringCache != null) return toStringCache;
    StringBuffer buffer = new StringBuffer();
    StringEscapeIterator it = new StringEscapeIterator(source);
    while (it.hasNext) {
      buffer.addCharCode(it.next());
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

  Iterator<int> iterator() => new ConsDartStringIterator(this);

  String slowToString() {
    if (toStringCache != null) return toStringCache;
    toStringCache = left.slowToString().concat(right.slowToString());
    return toStringCache;
  }
  SourceString get source => new StringWrapper(slowToString());
}

class ConsDartStringIterator implements Iterator<int> {
  Iterator<int> current;
  DartString right;
  bool hasNextLookAhead;
  ConsDartStringIterator(ConsDartString cons)
      : current = cons.left.iterator(),
        right = cons.right {
    hasNextLookAhead = current.hasNext;
    if (!hasNextLookAhead) {
      nextPart();
    }
  }
  bool get hasNext {
    return hasNextLookAhead;
  }
  int next() {
    assert(hasNextLookAhead);
    int result = current.next();
    hasNextLookAhead = current.hasNext;
    if (!hasNextLookAhead) {
      nextPart();
    }
    return result;
  }
  void nextPart() {
    if (right != null) {
      current = right.iterator();
      right = null;
      hasNextLookAhead = current.hasNext;
    }
  }
}

/**
 *Iterator that returns the actual string contents of a string with escapes.
 */
class StringEscapeIterator implements Iterator<int>{
  final Iterator<int> source;
  StringEscapeIterator(SourceString source) : this.source = source.iterator();
  bool get hasNext => source.hasNext;
  int next() {
    int code = source.next();
    if (!identical(code, $BACKSLASH)) {
      return code;
    }
    code = source.next();
    if (identical(code, $n)) return $LF;
    if (identical(code, $r)) return $CR;
    if (identical(code, $t)) return $TAB;
    if (identical(code, $b)) return $BS;
    if (identical(code, $f)) return $FF;
    if (identical(code, $v)) return $VTAB;
    if (identical(code, $x)) {
      int value = hexDigitValue(source.next());
      value = value * 16 + hexDigitValue(source.next());
      return value;
    }
    if (identical(code, $u)) {
      int value = 0;
      code = source.next();
      if (identical(code, $OPEN_CURLY_BRACKET)) {
        for (code = source.next();
             code != $CLOSE_CURLY_BRACKET;
             code = source.next()) {
           value = value * 16 + hexDigitValue(code);
        }
        return value;
      }
      // Four digit hex value.
      value = hexDigitValue(code);
      for (int i = 0; i < 3; i++) {
        code = source.next();
        value = value * 16 + hexDigitValue(code);
      }
      return value;
    }
    return code;
  }
}

