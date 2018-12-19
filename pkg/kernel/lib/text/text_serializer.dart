// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.text_serializer;

import '../ast.dart';
import '../visitor.dart' show ExpressionVisitor;

// ==== Serialize/deserialize combinators ====
abstract class TextSerializer<T> {
  const TextSerializer();

  T readFrom(Iterator<Object> stream);
  void writeTo(StringBuffer buffer, T object);

  /// True if this serializer/deserializer writes/reads nothing.  This is true
  /// for the serializer [Nothing] and also some serializers derived from it.
  bool get isEmpty => false;
}

class Nothing extends TextSerializer<void> {
  const Nothing();

  void readFrom(Iterator<Object> stream) {}

  void writeTo(StringBuffer buffer, void ignored) {}

  bool get isEmpty => true;
}

// == Serializer/deserializers for basic Dart types
class DartInt extends TextSerializer<int> {
  const DartInt();

  int readFrom(Iterator<Object> stream) {
    if (stream.current is! String) {
      throw StateError("expected an atom, found a list");
    }
    int result = int.parse(stream.current);
    stream.moveNext();
    return result;
  }

  void writeTo(StringBuffer buffer, int object) {
    buffer.write(object);
  }
}

class DartDouble extends TextSerializer<double> {
  const DartDouble();

  double readFrom(Iterator<Object> stream) {
    if (stream.current is! String) {
      throw StateError("expected an atom, found a list");
    }
    double result = double.parse(stream.current);
    stream.moveNext();
    return result;
  }

  void writeTo(StringBuffer buffer, double object) {
    buffer.write(object);
  }
}

class DartBool extends TextSerializer<bool> {
  const DartBool();

  bool readFrom(Iterator<Object> stream) {
    if (stream.current is! String) {
      throw StateError("expected an atom, found a list");
    }
    bool result;
    if (stream.current == "true") {
      result = true;
    } else if (stream.current == "false") {
      result = false;
    } else {
      throw StateError("expected 'true' or 'false', found '${stream.current}'");
    }
    stream.moveNext();
    return result;
  }

  void writeTo(StringBuffer buffer, bool object) {
    buffer.write(object ? 'true' : 'false');
  }
}

// == Serializers for tagged (disjoint) unions.
//
// They require a function mapping serializables to a tag string.  This is
// implemented by Tagger visitors.
class ExpressionTagger extends ExpressionVisitor<String> {
  const ExpressionTagger();

  String visitIntLiteral(IntLiteral _) => "int";
  String visitDoubleLiteral(DoubleLiteral _) => "double";
  String visitBoolLiteral(BoolLiteral _) => "bool";
  String visitNullLiteral(NullLiteral _) => "null";
}

// A tagged union of serializer/deserializers.
class Case<T extends Expression> extends TextSerializer<T> {
  final List<String> tags;
  final List<TextSerializer<T>> serializers;

  const Case(this.tags, this.serializers);

  T readFrom(Iterator<Object> stream) {
    if (stream.current is! Iterator) {
      throw StateError("expected list, found atom");
    }
    Iterator nested = stream.current;
    nested.moveNext();
    if (nested.current is! String) {
      throw StateError("expected atom, found list");
    }
    String tag = nested.current;
    for (int i = 0; i < tags.length; ++i) {
      if (tags[i] == tag) {
        nested.moveNext();
        T result = serializers[i].readFrom(nested);
        if (stream.moveNext()) {
          throw StateError("extra cruft in tagged '${tag}'");
        }
        return result;
      }
    }
    throw StateError("unrecognized tag '${tag}'");
  }

  void writeTo(StringBuffer buffer, T object) {
    String tag = object.accept(const ExpressionTagger());
    for (int i = 0; i < tags.length; ++i) {
      if (tags[i] == tag) {
        buffer.write("(${tag}");
        if (!serializers[i].isEmpty) {
          buffer.write(" ");
        }
        serializers[i].writeTo(buffer, object);
        buffer.write(")");
        return;
      }
    }
    throw StateError("unrecognized tag '${tag}");
  }
}

// A serializer/deserializer that unwraps/wraps nodes before serialization and
// after deserialization.
class Wrapped<S, K> extends TextSerializer<K> {
  final S Function(K) unwrap;
  final K Function(S) wrap;
  final TextSerializer<S> contents;

  const Wrapped(this.unwrap, this.wrap, this.contents);

  K readFrom(Iterator<Object> stream) {
    return wrap(contents.readFrom(stream));
  }

  void writeTo(StringBuffer buffer, K object) {
    contents.writeTo(buffer, unwrap(object));
  }

  bool get isEmpty => contents.isEmpty;
}

// S-expressions
//
// An S-expression is an atom or an S-list, an atom is a string that does not
// contain the delimiters '(', ')', or ' ', and an S-list is a space delimited
// sequence of S-expressions enclosed in parentheses:
//
// <S-expression> ::= <Atom>
//                  | <S-list>
// <S-list>       ::= '(' ')'
//                  | '(' <S-expression> {' ' <S-expression>}* ')'
//
// We use an iterator to read S-expressions.  The iterator produces a stream
// of atoms (strings) and nested iterators (S-lists).
class TextIterator implements Iterator<Object /* String | TextIterator */ > {
  static int space = ' '.codeUnitAt(0);
  static int lparen = '('.codeUnitAt(0);
  static int rparen = ')'.codeUnitAt(0);

  final String input;
  int index;

  TextIterator(this.input, this.index);

  // Consume spaces.
  void skipWhitespace() {
    while (index < input.length && input.codeUnitAt(index) == space) {
      ++index;
    }
  }

  // Consume the rest of a nested S-expression and the closing delimiter.
  void skipToEndOfNested() {
    if (current is TextIterator) {
      TextIterator it = current;
      while (it.moveNext());
      index = it.index + 1;
    }
  }

  void skipToEndOfAtom() {
    do {
      if (index >= input.length) return;
      int codeUnit = input.codeUnitAt(index);
      if (codeUnit == space || codeUnit == rparen) return;
      ++index;
    } while (true);
  }

  @override
  Object current = null;

  @override
  bool moveNext() {
    skipToEndOfNested();
    skipWhitespace();
    if (index >= input.length || input.codeUnitAt(index) == rparen) {
      current = null;
      return false;
    }
    if (input.codeUnitAt(index) == lparen) {
      current = new TextIterator(input, index + 1);
      return true;
    }
    int start = index;
    skipToEndOfAtom();
    current = input.substring(start, index);
    return true;
  }
}

// ==== Serializers for BasicLiterals
const TextSerializer<BasicLiteral> basicLiteralSerializer = Case([
  "int",
  "double",
  "bool",
  "null"
], [
  intLiteralSerializer,
  doubleLiteralSerializer,
  boolLiteralSerializer,
  nullLiteralSerializer
]);

const TextSerializer<IntLiteral> intLiteralSerializer =
    Wrapped(unwrapIntLiteral, wrapIntLiteral, DartInt());

int unwrapIntLiteral(IntLiteral literal) => literal.value;

IntLiteral wrapIntLiteral(int value) => new IntLiteral(value);

const TextSerializer<DoubleLiteral> doubleLiteralSerializer =
    Wrapped(unwrapDoubleLiteral, wrapDoubleLiteral, DartDouble());

double unwrapDoubleLiteral(DoubleLiteral literal) => literal.value;

DoubleLiteral wrapDoubleLiteral(double value) => new DoubleLiteral(value);

const TextSerializer<BoolLiteral> boolLiteralSerializer =
    Wrapped(unwrapBoolLiteral, wrapBoolLiteral, DartBool());

bool unwrapBoolLiteral(BoolLiteral literal) => literal.value;

BoolLiteral wrapBoolLiteral(bool value) => new BoolLiteral(value);

const TextSerializer<NullLiteral> nullLiteralSerializer =
    Wrapped(unwrapNullLiteral, wrapNullLiteral, Nothing());

void unwrapNullLiteral(NullLiteral literal) {}

NullLiteral wrapNullLiteral(void ignored) => new NullLiteral();
