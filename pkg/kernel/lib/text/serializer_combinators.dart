// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.serializer_combinators;

import 'dart:convert' show json;

import '../ast.dart' show Node;
import '../canonical_name.dart' show CanonicalName;
import 'text_serializer.dart' show Tagger;

class DeserializationEnvironment<T extends Node> {
  final Map<String, T> locals = <String, T>{};

  final Map<String, T> binders = <String, T>{};

  final DeserializationEnvironment<T> parent;

  final Set<String> usedNames = new Set<String>();

  DeserializationEnvironment(this.parent) {
    if (parent != null) {
      usedNames.addAll(parent.usedNames);
    }
  }

  T lookup(String name) => locals[name] ?? parent?.lookup(name);

  T addBinder(String name, T node) {
    if (usedNames.contains(name)) {
      throw StateError("name '$name' is already declared in this scope");
    }
    usedNames.add(name);
    return binders[name] = node;
  }

  void close() {
    locals.addAll(binders);
    binders.clear();
  }
}

class SerializationEnvironment<T extends Node> {
  final Map<T, String> locals = new Map<T, String>.identity();

  final Map<T, String> binders = new Map<T, String>.identity();

  int nameCount;

  final SerializationEnvironment<T> parent;

  static const String separator = "^";

  static final int codeOfZero = "0".codeUnitAt(0);

  static final int codeOfNine = "9".codeUnitAt(0);

  SerializationEnvironment(this.parent) {
    nameCount = (parent?.nameCount ?? 0);
  }

  String lookup(T node) => locals[node] ?? parent?.lookup(node);

  String addBinder(T node, String name) {
    int prefixLength = name.length - 1;
    bool isOnlyDigits = true;
    while (prefixLength >= 0 && name[prefixLength] != separator) {
      int code = name.codeUnitAt(prefixLength);
      isOnlyDigits = isOnlyDigits && (codeOfZero <= code && code <= codeOfNine);
      --prefixLength;
    }
    if (prefixLength < 0 || !isOnlyDigits) {
      prefixLength = name.length;
    }
    String prefix = name.substring(0, prefixLength);
    return binders[node] = "$prefix$separator${nameCount++}";
  }

  void close() {
    locals.addAll(binders);
    binders.clear();
  }
}

class DeserializationState {
  final DeserializationEnvironment environment;
  final CanonicalName nameRoot;

  DeserializationState(this.environment, this.nameRoot);
}

class SerializationState {
  final SerializationEnvironment environment;

  SerializationState(this.environment);
}

abstract class TextSerializer<T> {
  const TextSerializer();

  T readFrom(Iterator<Object> stream, DeserializationState state);
  void writeTo(StringBuffer buffer, T object, SerializationState state);

  /// True if this serializer/deserializer writes/reads nothing.  This is true
  /// for the serializer [Nothing] and also some serializers derived from it.
  bool get isEmpty => false;
}

class Nothing extends TextSerializer<void> {
  const Nothing();

  void readFrom(Iterator<Object> stream, DeserializationState _) {}

  void writeTo(StringBuffer buffer, void ignored, SerializationState _) {}

  bool get isEmpty => true;
}

class DartString extends TextSerializer<String> {
  const DartString();

  String readFrom(Iterator<Object> stream, DeserializationState _) {
    if (stream.current is! String) {
      throw StateError("expected an atom, found a list");
    }
    String result = json.decode(stream.current);
    stream.moveNext();
    return result;
  }

  void writeTo(StringBuffer buffer, String object, SerializationState _) {
    buffer.write(json.encode(object));
  }
}

class DartInt extends TextSerializer<int> {
  const DartInt();

  int readFrom(Iterator<Object> stream, DeserializationState _) {
    if (stream.current is! String) {
      throw StateError("expected an atom, found a list");
    }
    int result = int.parse(stream.current);
    stream.moveNext();
    return result;
  }

  void writeTo(StringBuffer buffer, int object, SerializationState _) {
    buffer.write(object);
  }
}

class DartDouble extends TextSerializer<double> {
  const DartDouble();

  double readFrom(Iterator<Object> stream, DeserializationState _) {
    if (stream.current is! String) {
      throw StateError("expected an atom, found a list");
    }
    double result = double.parse(stream.current);
    stream.moveNext();
    return result;
  }

  void writeTo(StringBuffer buffer, double object, SerializationState _) {
    buffer.write(object);
  }
}

class DartBool extends TextSerializer<bool> {
  const DartBool();

  bool readFrom(Iterator<Object> stream, DeserializationState _) {
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

  void writeTo(StringBuffer buffer, bool object, SerializationState _) {
    buffer.write(object ? 'true' : 'false');
  }
}

// == Serializers for tagged (disjoint) unions.
//
// They require a function mapping serializables to a tag string.  This is
// implemented by Tagger visitors.
// A tagged union of serializer/deserializers.
class Case<T extends Node> extends TextSerializer<T> {
  final Tagger<T> tagger;
  final List<String> tags;
  final List<TextSerializer<T>> serializers;

  Case(this.tagger, this.tags, this.serializers);

  Case.uninitialized(this.tagger)
      : tags = [],
        serializers = [];

  T readFrom(Iterator<Object> stream, DeserializationState state) {
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
        T result = serializers[i].readFrom(nested, state);
        if (nested.moveNext()) {
          throw StateError("extra cruft in tagged '${tag}'");
        }
        stream.moveNext();
        return result;
      }
    }
    throw StateError("unrecognized tag '${tag}'");
  }

  void writeTo(StringBuffer buffer, T object, SerializationState state) {
    String tag = tagger.tag(object);
    for (int i = 0; i < tags.length; ++i) {
      if (tags[i] == tag) {
        buffer.write("(${tag}");
        if (!serializers[i].isEmpty) {
          buffer.write(" ");
        }
        serializers[i].writeTo(buffer, object, state);
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

  Wrapped(this.unwrap, this.wrap, this.contents);

  K readFrom(Iterator<Object> stream, DeserializationState state) {
    return wrap(contents.readFrom(stream, state));
  }

  void writeTo(StringBuffer buffer, K object, SerializationState state) {
    contents.writeTo(buffer, unwrap(object), state);
  }

  bool get isEmpty => contents.isEmpty;
}

class ScopedUse<T extends Node> extends TextSerializer<T> {
  final DartString stringSerializer = const DartString();

  const ScopedUse();

  T readFrom(Iterator<Object> stream, DeserializationState state) {
    return state.environment.lookup(stringSerializer.readFrom(stream, null));
  }

  void writeTo(StringBuffer buffer, T object, SerializationState state) {
    stringSerializer.writeTo(buffer, state.environment.lookup(object), null);
  }
}

// A serializer/deserializer for pairs.
class Tuple2Serializer<T1, T2> extends TextSerializer<Tuple2<T1, T2>> {
  final TextSerializer<T1> first;
  final TextSerializer<T2> second;

  const Tuple2Serializer(this.first, this.second);

  Tuple2<T1, T2> readFrom(Iterator<Object> stream, DeserializationState state) {
    return new Tuple2(
        first.readFrom(stream, state), second.readFrom(stream, state));
  }

  void writeTo(
      StringBuffer buffer, Tuple2<T1, T2> object, SerializationState state) {
    first.writeTo(buffer, object.first, state);
    buffer.write(' ');
    second.writeTo(buffer, object.second, state);
  }
}

class Tuple2<T1, T2> {
  final T1 first;
  final T2 second;

  const Tuple2(this.first, this.second);
}

class Tuple3Serializer<T1, T2, T3> extends TextSerializer<Tuple3<T1, T2, T3>> {
  final TextSerializer<T1> first;
  final TextSerializer<T2> second;
  final TextSerializer<T3> third;

  const Tuple3Serializer(this.first, this.second, this.third);

  Tuple3<T1, T2, T3> readFrom(
      Iterator<Object> stream, DeserializationState state) {
    return new Tuple3(first.readFrom(stream, state),
        second.readFrom(stream, state), third.readFrom(stream, state));
  }

  void writeTo(StringBuffer buffer, Tuple3<T1, T2, T3> object,
      SerializationState state) {
    first.writeTo(buffer, object.first, state);
    buffer.write(' ');
    second.writeTo(buffer, object.second, state);
    buffer.write(' ');
    third.writeTo(buffer, object.third, state);
  }
}

class Tuple3<T1, T2, T3> {
  final T1 first;
  final T2 second;
  final T3 third;

  const Tuple3(this.first, this.second, this.third);
}

class Tuple4Serializer<T1, T2, T3, T4>
    extends TextSerializer<Tuple4<T1, T2, T3, T4>> {
  final TextSerializer<T1> first;
  final TextSerializer<T2> second;
  final TextSerializer<T3> third;
  final TextSerializer<T4> fourth;

  const Tuple4Serializer(this.first, this.second, this.third, this.fourth);

  Tuple4<T1, T2, T3, T4> readFrom(
      Iterator<Object> stream, DeserializationState state) {
    return new Tuple4(
        first.readFrom(stream, state),
        second.readFrom(stream, state),
        third.readFrom(stream, state),
        fourth.readFrom(stream, state));
  }

  void writeTo(StringBuffer buffer, Tuple4<T1, T2, T3, T4> object,
      SerializationState state) {
    first.writeTo(buffer, object.first, state);
    buffer.write(' ');
    second.writeTo(buffer, object.second, state);
    buffer.write(' ');
    third.writeTo(buffer, object.third, state);
    buffer.write(' ');
    fourth.writeTo(buffer, object.fourth, state);
  }
}

class Tuple4<T1, T2, T3, T4> {
  final T1 first;
  final T2 second;
  final T3 third;
  final T4 fourth;

  const Tuple4(this.first, this.second, this.third, this.fourth);
}

// A serializer/deserializer for lists.
class ListSerializer<T> extends TextSerializer<List<T>> {
  final TextSerializer<T> elements;

  const ListSerializer(this.elements);

  List<T> readFrom(Iterator<Object> stream, DeserializationState state) {
    if (stream.current is! Iterator) {
      throw StateError("expected a list, found an atom");
    }
    Iterator<Object> list = stream.current;
    list.moveNext();
    List<T> result = [];
    while (list.current != null) {
      result.add(elements.readFrom(list, state));
    }
    stream.moveNext();
    return result;
  }

  void writeTo(StringBuffer buffer, List<T> object, SerializationState state) {
    buffer.write('(');
    for (int i = 0; i < object.length; ++i) {
      if (i != 0) buffer.write(' ');
      elements.writeTo(buffer, object[i], state);
    }
    buffer.write(')');
  }
}

class Optional<T> extends TextSerializer<T> {
  final TextSerializer<T> contents;

  const Optional(this.contents);

  T readFrom(Iterator<Object> stream, DeserializationState state) {
    if (stream.current == '_') {
      stream.moveNext();
      return null;
    }
    return contents.readFrom(stream, state);
  }

  void writeTo(StringBuffer buffer, T object, SerializationState state) {
    if (object == null) {
      buffer.write('_');
    } else {
      contents.writeTo(buffer, object, state);
    }
  }
}
