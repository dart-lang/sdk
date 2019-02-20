// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.serializer_combinators;

import 'dart:convert' show json;

import '../ast.dart' show Node;
import '../canonical_name.dart' show CanonicalName;
import 'text_serializer.dart' show Tagger;

class DeserializationEnvironment<T extends Node> {
  final DeserializationEnvironment<T> parent;

  final Map<String, T> locals = <String, T>{};

  final Map<String, T> binders = <String, T>{};

  final Set<String> usedNames;

  DeserializationEnvironment(this.parent)
      : usedNames = parent?.usedNames?.toSet() ?? new Set<String>();

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
  final SerializationEnvironment<T> parent;

  final Map<T, String> locals = new Map<T, String>.identity();

  final Map<T, String> binders = new Map<T, String>.identity();

  int nameCount;

  SerializationEnvironment(this.parent) : nameCount = parent?.nameCount ?? 0;

  String lookup(T node) => locals[node] ?? parent?.lookup(node);

  String addBinder(T node, String name) {
    final String separator = "^";
    final int codeOfZero = "0".codeUnitAt(0);
    final int codeOfNine = "9".codeUnitAt(0);

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

/// Introduces a binder to the environment.
///
/// Serializes an object and uses it as a binder for the name that is retrieved
/// from the object using [nameGetter] and (temporarily) modified using
/// [nameSetter].  The binder is added to the enclosing environment.
class Binder<T extends Node> extends TextSerializer<T> {
  final TextSerializer<T> contents;
  final String Function(T) nameGetter;
  final void Function(T, String) nameSetter;

  const Binder(this.contents, this.nameGetter, this.nameSetter);

  T readFrom(Iterator<Object> stream, DeserializationState state) {
    T object = contents.readFrom(stream, state);
    state.environment.addBinder(nameGetter(object), object);
    return object;
  }

  void writeTo(StringBuffer buffer, T object, SerializationState state) {
    String oldName = nameGetter(object);
    String newName = state.environment.addBinder(object, oldName);
    nameSetter(object, newName);
    contents.writeTo(buffer, object, state);
    nameSetter(object, oldName);
  }
}

/// Binds binders from one term in the other.
///
/// Serializes a [Tuple2] of [pattern] and [term], closing [term] over the
/// binders found in [pattern].  The binders aren't added to the enclosing
/// environment.
class Bind<P, T> extends TextSerializer<Tuple2<P, T>> {
  final TextSerializer<P> pattern;
  final TextSerializer<T> term;

  const Bind(this.pattern, this.term);

  Tuple2<P, T> readFrom(Iterator<Object> stream, DeserializationState state) {
    var bindingState = new DeserializationState(
        new DeserializationEnvironment(state.environment), state.nameRoot);
    P first = pattern.readFrom(stream, bindingState);
    bindingState.environment.close();
    T second = term.readFrom(stream, bindingState);
    return new Tuple2(first, second);
  }

  void writeTo(
      StringBuffer buffer, Tuple2<P, T> tuple, SerializationState state) {
    var bindingState =
        new SerializationState(new SerializationEnvironment(state.environment));
    pattern.writeTo(buffer, tuple.first, bindingState);
    bindingState.environment.close();
    buffer.write(' ');
    term.writeTo(buffer, tuple.second, bindingState);
  }
}

/// Binds binders from one term in the other and adds them to the environment.
///
/// Serializes a [Tuple2] of [pattern] and [term], closing [term] over the
/// binders found in [pattern].  The binders are added to the enclosing
/// environment.
class Rebind<P, T> extends TextSerializer<Tuple2<P, T>> {
  final TextSerializer<P> pattern;
  final TextSerializer<T> term;

  const Rebind(this.pattern, this.term);

  Tuple2<P, T> readFrom(Iterator<Object> stream, DeserializationState state) {
    P first = pattern.readFrom(stream, state);
    var closedState = new DeserializationState(
        new DeserializationEnvironment(state.environment)
          ..binders.addAll(state.environment.binders)
          ..close(),
        state.nameRoot);
    T second = term.readFrom(stream, closedState);
    return new Tuple2(first, second);
  }

  void writeTo(
      StringBuffer buffer, Tuple2<P, T> tuple, SerializationState state) {
    pattern.writeTo(buffer, tuple.first, state);
    var closedState =
        new SerializationState(new SerializationEnvironment(state.environment)
          ..binders.addAll(state.environment.binders)
          ..close());
    buffer.write(' ');
    term.writeTo(buffer, tuple.second, closedState);
  }
}

class Zip<T, T1, T2> extends TextSerializer<List<T>> {
  final TextSerializer<Tuple2<List<T1>, List<T2>>> lists;
  final T Function(T1, T2) zip;
  final Tuple2<T1, T2> Function(T) unzip;

  const Zip(this.lists, this.zip, this.unzip);

  List<T> readFrom(Iterator<Object> stream, DeserializationState state) {
    Tuple2<List<T1>, List<T2>> toZip = lists.readFrom(stream, state);
    List<T1> firsts = toZip.first;
    List<T2> seconds = toZip.second;
    List<T> zipped = new List<T>(toZip.first.length);
    for (int i = 0; i < zipped.length; ++i) {
      zipped[i] = zip(firsts[i], seconds[i]);
    }
    return zipped;
  }

  void writeTo(StringBuffer buffer, List<T> zipped, SerializationState state) {
    List<T1> firsts = new List<T1>(zipped.length);
    List<T2> seconds = new List<T2>(zipped.length);
    for (int i = 0; i < zipped.length; ++i) {
      Tuple2<T1, T2> tuple = unzip(zipped[i]);
      firsts[i] = tuple.first;
      seconds[i] = tuple.second;
    }
    lists.writeTo(buffer, new Tuple2(firsts, seconds), state);
  }
}
