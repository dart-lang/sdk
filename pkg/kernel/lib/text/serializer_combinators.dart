// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.serializer_combinators;

import 'dart:convert' show json;

import '../ast.dart' show Node;
import '../canonical_name.dart' show CanonicalName;
import 'text_serializer.dart' show Tagger;

class DeserializationEnvironment<T extends Node> {
  final DeserializationEnvironment<T>? parent;

  final Map<String, T> locals = <String, T>{};

  final Map<String, T> binders = <String, T>{};

  final Map<T, String> distinctNames = new Map<T, String>.identity();

  DeserializationEnvironment(this.parent);

  T lookup(String name) =>
      locals[name] ??
      parent?.lookup(name) ??
      (throw StateError("No local '${name}' found in this scope."));

  T addBinder(T node, String distinctName) {
    if (lookupDistinctName(node) != null) {
      throw StateError(
          "Name '${distinctName}' is already declared in this scope.");
    }
    distinctNames[node] = distinctName;
    return binders[distinctName] = node;
  }

  // TODO(dmitryas): Consider combining with [addBinder] into a single method.
  void extend() {
    locals.addAll(binders);
    binders.clear();
  }

  String? lookupDistinctName(T object) {
    return distinctNames[object] ?? parent?.lookupDistinctName(object);
  }
}

class SerializationEnvironment<T extends Node> {
  final SerializationEnvironment<T>? parent;

  final Map<T, String> locals = new Map<T, String>.identity();

  final Map<T, String> binders = new Map<T, String>.identity();

  int nameCount;

  Map<T, String> distinctNames = new Map<T, String>.identity();

  SerializationEnvironment(this.parent) : nameCount = parent?.nameCount ?? 0;

  String lookup(T node) =>
      locals[node] ??
      parent?.lookup(node) ??
      (throw StateError("No name for ${node} found in this scope."));

  String addBinder(T node, {String? nameClue}) {
    final String separator = "^";
    final int codeOfZero = "0".codeUnitAt(0);
    final int codeOfNine = "9".codeUnitAt(0);

    String prefix;
    if (nameClue != null) {
      int prefixLength = nameClue.length - 1;
      bool isOnlyDigits = true;
      while (prefixLength >= 0 && nameClue[prefixLength] != separator) {
        int code = nameClue.codeUnitAt(prefixLength);
        isOnlyDigits =
            isOnlyDigits && (codeOfZero <= code && code <= codeOfNine);
        --prefixLength;
      }
      if (prefixLength < 0 || !isOnlyDigits) {
        prefixLength = nameClue.length;
      }
      prefix = nameClue.substring(0, prefixLength);
    } else {
      prefix = "ID";
    }
    String distinctName = "$prefix$separator${nameCount++}";
    // The following checks for an internal error, not an error caused by the
    // user. So, an assert is used instead of an exception.
    assert(
        lookupDistinctName(node) == null,
        "Can't assign distinct name '${distinctName}' "
        "to an object of kind '${node.runtimeType}': "
        "it's already known by name '${lookupDistinctName(node)}'.");
    distinctNames[node] = distinctName;
    return binders[node] = distinctName;
  }

  // TODO(dmitryas): Consider combining with [addBinder] into a single method.
  void extend() {
    locals.addAll(binders);
    binders.clear();
  }

  String? lookupDistinctName(T object) {
    return distinctNames[object] ?? parent?.lookupDistinctName(object);
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

  T readFrom(Iterator<Object?> stream, DeserializationState? state);
  void writeTo(StringBuffer buffer, T object, SerializationState? state);

  /// True if this serializer/deserializer writes/reads nothing.  This is true
  /// for the serializer [Nothing] and also some serializers derived from it.
  bool get isEmpty => false;
}

class Nothing extends TextSerializer<void> {
  const Nothing();

  @override
  void readFrom(Iterator<Object?> stream, DeserializationState? _) {}

  @override
  void writeTo(StringBuffer buffer, void ignored, SerializationState? _) {}

  @override
  bool get isEmpty => true;
}

class DartString extends TextSerializer<String> {
  const DartString();

  @override
  String readFrom(Iterator<Object?> stream, DeserializationState? _) {
    Object? current = stream.current;
    if (current is! String) {
      throw StateError("Expected an atom, found a list: '${current}'.");
    }
    String result = json.decode(current);
    stream.moveNext();
    return result;
  }

  @override
  void writeTo(StringBuffer buffer, String object, SerializationState? _) {
    buffer.write(json.encode(object));
  }
}

class DartInt extends TextSerializer<int> {
  const DartInt();

  @override
  int readFrom(Iterator<Object?> stream, DeserializationState? _) {
    Object? current = stream.current;
    if (current is! String) {
      throw StateError("Expected an atom, found a list: '${current}'.");
    }
    int result = int.parse(current);
    stream.moveNext();
    return result;
  }

  @override
  void writeTo(StringBuffer buffer, int object, SerializationState? _) {
    buffer.write(object);
  }
}

class DartDouble extends TextSerializer<double> {
  const DartDouble();

  @override
  double readFrom(Iterator<Object?> stream, DeserializationState? _) {
    Object? current = stream.current;
    if (current is! String) {
      throw StateError("Expected an atom, found a list: '${current}'.");
    }
    double result = double.parse(current);
    stream.moveNext();
    return result;
  }

  @override
  void writeTo(StringBuffer buffer, double object, SerializationState? _) {
    buffer.write(object);
  }
}

class DartBool extends TextSerializer<bool> {
  const DartBool();

  @override
  bool readFrom(Iterator<Object?> stream, DeserializationState? _) {
    Object? current = stream.current;
    if (current is! String) {
      throw StateError("Expected an atom, found a list: '${current}'.");
    }
    bool result;
    if (current == "true") {
      result = true;
    } else if (current == "false") {
      result = false;
    } else {
      throw StateError("Expected 'true' or 'false', found '${current}'");
    }
    stream.moveNext();
    return result;
  }

  @override
  void writeTo(StringBuffer buffer, bool object, SerializationState? _) {
    buffer.write(object ? 'true' : 'false');
  }
}

class UriSerializer extends TextSerializer<Uri> {
  const UriSerializer();

  @override
  Uri readFrom(Iterator<Object?> stream, DeserializationState? state) {
    String uriAsString = const DartString().readFrom(stream, state);
    return Uri.parse(uriAsString);
  }

  @override
  void writeTo(StringBuffer buffer, Uri object, SerializationState? state) {
    const DartString().writeTo(buffer, object.toString(), state);
  }
}

// == Serializers for tagged (disjoint) unions.
//
// They require a function mapping serializables to a tag string.  This is
// implemented by Tagger visitors.
// A tagged union of serializer/deserializers.
class Case<T> extends TextSerializer<T> {
  final Tagger<T> tagger;
  final List<String> _tags;
  final List<TextSerializer<T>> _serializers;

  Case(this.tagger, Map<String, TextSerializer<T>> tagsAndSerializers)
      : _tags = tagsAndSerializers.keys.toList(),
        _serializers = tagsAndSerializers.values.toList();

  Case.uninitialized(this.tagger)
      : _tags = [],
        _serializers = [];

  void registerTags(Map<String, TextSerializer<T>> tagsAndSerializers) {
    _tags.addAll(tagsAndSerializers.keys);
    _serializers.addAll(tagsAndSerializers.values);
  }

  @override
  T readFrom(Iterator<Object?> stream, DeserializationState? state) {
    Object? iterator = stream.current;
    if (iterator is! Iterator<Object?>) {
      throw StateError("Expected list, found atom: '${iterator}'.");
    }
    iterator.moveNext();
    Object? element = iterator.current;
    if (element is! String) {
      throw StateError("Expected atom, found list: '${element}'.");
    }
    String tag = element;
    for (int i = 0; i < _tags.length; ++i) {
      if (_tags[i] == tag) {
        iterator.moveNext();
        T result = _serializers[i].readFrom(iterator, state);
        if (iterator.moveNext()) {
          throw StateError(
              "Extra data in tagged '${tag}': '${iterator.current}'.");
        }
        stream.moveNext();
        return result;
      }
    }
    throw StateError("Unrecognized tag '${tag}'.");
  }

  @override
  void writeTo(StringBuffer buffer, T object, SerializationState? state) {
    String tag = tagger.tag(object);
    for (int i = 0; i < _tags.length; ++i) {
      if (_tags[i] == tag) {
        buffer.write("(${tag}");
        if (!_serializers[i].isEmpty) {
          buffer.write(" ");
        }
        _serializers[i].writeTo(buffer, object, state);
        buffer.write(")");
        return;
      }
    }
    throw StateError("Unrecognized tag '${tag}'.");
  }
}

// A serializer/deserializer that unwraps/wraps nodes before serialization and
// after deserialization.
class Wrapped<S, K> extends TextSerializer<K> {
  final S Function(K) unwrap;
  final K Function(S) wrap;
  final TextSerializer<S> contents;

  const Wrapped(this.unwrap, this.wrap, this.contents);

  @override
  K readFrom(Iterator<Object?> stream, DeserializationState? state) {
    return wrap(contents.readFrom(stream, state));
  }

  @override
  void writeTo(StringBuffer buffer, K object, SerializationState? state) {
    contents.writeTo(buffer, unwrap(object), state);
  }

  @override
  bool get isEmpty => contents.isEmpty;
}

class ScopedUse<T extends Node> extends TextSerializer<T> {
  final DartString stringSerializer = const DartString();

  const ScopedUse();

  @override
  T readFrom(Iterator<Object?> stream, DeserializationState? state) {
    if (state == null) {
      throw StateError(
          "No deserialization state provided for ${runtimeType}.readFrom.");
    }
    return state.environment.lookup(stringSerializer.readFrom(stream, null))
        as T;
  }

  @override
  void writeTo(StringBuffer buffer, T object, SerializationState? state) {
    if (state == null) {
      throw StateError(
          "No serialization state provided for ${runtimeType}.writeTo.");
    }
    stringSerializer.writeTo(buffer, state.environment.lookup(object), null);
  }
}

// A serializer/deserializer for pairs.
class Tuple2Serializer<T1, T2> extends TextSerializer<Tuple2<T1, T2>> {
  final TextSerializer<T1> first;
  final TextSerializer<T2> second;

  const Tuple2Serializer(this.first, this.second);

  @override
  Tuple2<T1, T2> readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    return new Tuple2(
        first.readFrom(stream, state), second.readFrom(stream, state));
  }

  @override
  void writeTo(
      StringBuffer buffer, Tuple2<T1, T2> object, SerializationState? state) {
    first.writeTo(buffer, object.first, state);
    if (!second.isEmpty) buffer.write(' ');
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

  @override
  Tuple3<T1, T2, T3> readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    return new Tuple3(first.readFrom(stream, state),
        second.readFrom(stream, state), third.readFrom(stream, state));
  }

  @override
  void writeTo(StringBuffer buffer, Tuple3<T1, T2, T3> object,
      SerializationState? state) {
    first.writeTo(buffer, object.first, state);
    if (!second.isEmpty) buffer.write(' ');
    second.writeTo(buffer, object.second, state);
    if (!third.isEmpty) buffer.write(' ');
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

  @override
  Tuple4<T1, T2, T3, T4> readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    return new Tuple4(
        first.readFrom(stream, state),
        second.readFrom(stream, state),
        third.readFrom(stream, state),
        fourth.readFrom(stream, state));
  }

  @override
  void writeTo(StringBuffer buffer, Tuple4<T1, T2, T3, T4> object,
      SerializationState? state) {
    first.writeTo(buffer, object.first, state);
    if (!second.isEmpty) buffer.write(' ');
    second.writeTo(buffer, object.second, state);
    if (!third.isEmpty) buffer.write(' ');
    third.writeTo(buffer, object.third, state);
    if (!fourth.isEmpty) buffer.write(' ');
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

class Tuple5Serializer<T1, T2, T3, T4, T5>
    extends TextSerializer<Tuple5<T1, T2, T3, T4, T5>> {
  final TextSerializer<T1> first;
  final TextSerializer<T2> second;
  final TextSerializer<T3> third;
  final TextSerializer<T4> fourth;
  final TextSerializer<T5> fifth;

  const Tuple5Serializer(
      this.first, this.second, this.third, this.fourth, this.fifth);

  @override
  Tuple5<T1, T2, T3, T4, T5> readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    return new Tuple5(
        first.readFrom(stream, state),
        second.readFrom(stream, state),
        third.readFrom(stream, state),
        fourth.readFrom(stream, state),
        fifth.readFrom(stream, state));
  }

  @override
  void writeTo(StringBuffer buffer, Tuple5<T1, T2, T3, T4, T5> object,
      SerializationState? state) {
    first.writeTo(buffer, object.first, state);
    if (!second.isEmpty) buffer.write(' ');
    second.writeTo(buffer, object.second, state);
    if (!third.isEmpty) buffer.write(' ');
    third.writeTo(buffer, object.third, state);
    if (!fourth.isEmpty) buffer.write(' ');
    fourth.writeTo(buffer, object.fourth, state);
    if (!fifth.isEmpty) buffer.write(' ');
    fifth.writeTo(buffer, object.fifth, state);
  }
}

class Tuple5<T1, T2, T3, T4, T5> {
  final T1 first;
  final T2 second;
  final T3 third;
  final T4 fourth;
  final T5 fifth;

  const Tuple5(this.first, this.second, this.third, this.fourth, this.fifth);
}

class Tuple6Serializer<T1, T2, T3, T4, T5, T6>
    extends TextSerializer<Tuple6<T1, T2, T3, T4, T5, T6>> {
  final TextSerializer<T1> first;
  final TextSerializer<T2> second;
  final TextSerializer<T3> third;
  final TextSerializer<T4> fourth;
  final TextSerializer<T5> fifth;
  final TextSerializer<T6> sixth;

  const Tuple6Serializer(
      this.first, this.second, this.third, this.fourth, this.fifth, this.sixth);

  @override
  Tuple6<T1, T2, T3, T4, T5, T6> readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    return new Tuple6(
        first.readFrom(stream, state),
        second.readFrom(stream, state),
        third.readFrom(stream, state),
        fourth.readFrom(stream, state),
        fifth.readFrom(stream, state),
        sixth.readFrom(stream, state));
  }

  @override
  void writeTo(StringBuffer buffer, Tuple6<T1, T2, T3, T4, T5, T6> object,
      SerializationState? state) {
    first.writeTo(buffer, object.first, state);
    if (!second.isEmpty) buffer.write(' ');
    second.writeTo(buffer, object.second, state);
    if (!third.isEmpty) buffer.write(' ');
    third.writeTo(buffer, object.third, state);
    if (!fourth.isEmpty) buffer.write(' ');
    fourth.writeTo(buffer, object.fourth, state);
    if (!fifth.isEmpty) buffer.write(' ');
    fifth.writeTo(buffer, object.fifth, state);
    if (!sixth.isEmpty) buffer.write(' ');
    sixth.writeTo(buffer, object.sixth, state);
  }
}

class Tuple6<T1, T2, T3, T4, T5, T6> {
  final T1 first;
  final T2 second;
  final T3 third;
  final T4 fourth;
  final T5 fifth;
  final T6 sixth;

  const Tuple6(
      this.first, this.second, this.third, this.fourth, this.fifth, this.sixth);
}

class Tuple7Serializer<T1, T2, T3, T4, T5, T6, T7>
    extends TextSerializer<Tuple7<T1, T2, T3, T4, T5, T6, T7>> {
  final TextSerializer<T1> first;
  final TextSerializer<T2> second;
  final TextSerializer<T3> third;
  final TextSerializer<T4> fourth;
  final TextSerializer<T5> fifth;
  final TextSerializer<T6> sixth;
  final TextSerializer<T7> seventh;

  const Tuple7Serializer(this.first, this.second, this.third, this.fourth,
      this.fifth, this.sixth, this.seventh);

  @override
  Tuple7<T1, T2, T3, T4, T5, T6, T7> readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    return new Tuple7(
        first.readFrom(stream, state),
        second.readFrom(stream, state),
        third.readFrom(stream, state),
        fourth.readFrom(stream, state),
        fifth.readFrom(stream, state),
        sixth.readFrom(stream, state),
        seventh.readFrom(stream, state));
  }

  @override
  void writeTo(StringBuffer buffer, Tuple7<T1, T2, T3, T4, T5, T6, T7> object,
      SerializationState? state) {
    first.writeTo(buffer, object.first, state);
    if (!second.isEmpty) buffer.write(' ');
    second.writeTo(buffer, object.second, state);
    if (!third.isEmpty) buffer.write(' ');
    third.writeTo(buffer, object.third, state);
    if (!fourth.isEmpty) buffer.write(' ');
    fourth.writeTo(buffer, object.fourth, state);
    if (!fifth.isEmpty) buffer.write(' ');
    fifth.writeTo(buffer, object.fifth, state);
    if (!sixth.isEmpty) buffer.write(' ');
    sixth.writeTo(buffer, object.sixth, state);
    if (!seventh.isEmpty) buffer.write(' ');
    seventh.writeTo(buffer, object.seventh, state);
  }
}

class Tuple7<T1, T2, T3, T4, T5, T6, T7> {
  final T1 first;
  final T2 second;
  final T3 third;
  final T4 fourth;
  final T5 fifth;
  final T6 sixth;
  final T7 seventh;

  const Tuple7(this.first, this.second, this.third, this.fourth, this.fifth,
      this.sixth, this.seventh);
}

class Tuple8Serializer<T1, T2, T3, T4, T5, T6, T7, T8>
    extends TextSerializer<Tuple8<T1, T2, T3, T4, T5, T6, T7, T8>> {
  final TextSerializer<T1> first;
  final TextSerializer<T2> second;
  final TextSerializer<T3> third;
  final TextSerializer<T4> fourth;
  final TextSerializer<T5> fifth;
  final TextSerializer<T6> sixth;
  final TextSerializer<T7> seventh;
  final TextSerializer<T8> eighth;

  const Tuple8Serializer(this.first, this.second, this.third, this.fourth,
      this.fifth, this.sixth, this.seventh, this.eighth);

  @override
  Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    return new Tuple8(
        first.readFrom(stream, state),
        second.readFrom(stream, state),
        third.readFrom(stream, state),
        fourth.readFrom(stream, state),
        fifth.readFrom(stream, state),
        sixth.readFrom(stream, state),
        seventh.readFrom(stream, state),
        eighth.readFrom(stream, state));
  }

  @override
  void writeTo(
      StringBuffer buffer,
      Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> object,
      SerializationState? state) {
    first.writeTo(buffer, object.first, state);
    if (!second.isEmpty) buffer.write(' ');
    second.writeTo(buffer, object.second, state);
    if (!third.isEmpty) buffer.write(' ');
    third.writeTo(buffer, object.third, state);
    if (!fourth.isEmpty) buffer.write(' ');
    fourth.writeTo(buffer, object.fourth, state);
    if (!fifth.isEmpty) buffer.write(' ');
    fifth.writeTo(buffer, object.fifth, state);
    if (!sixth.isEmpty) buffer.write(' ');
    sixth.writeTo(buffer, object.sixth, state);
    if (!seventh.isEmpty) buffer.write(' ');
    seventh.writeTo(buffer, object.seventh, state);
    if (!eighth.isEmpty) buffer.write(' ');
    eighth.writeTo(buffer, object.eighth, state);
  }
}

class Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> {
  final T1 first;
  final T2 second;
  final T3 third;
  final T4 fourth;
  final T5 fifth;
  final T6 sixth;
  final T7 seventh;
  final T8 eighth;

  const Tuple8(this.first, this.second, this.third, this.fourth, this.fifth,
      this.sixth, this.seventh, this.eighth);
}

// A serializer/deserializer for lists.
class ListSerializer<T> extends TextSerializer<List<T>> {
  final TextSerializer<T> elements;

  const ListSerializer(this.elements);

  @override
  List<T> readFrom(Iterator<Object?> stream, DeserializationState? state) {
    Object? iterator = stream.current;
    if (iterator is! Iterator<Object?>) {
      throw StateError("Expected a list, found an atom: '${iterator}'.");
    }
    iterator.moveNext();
    List<T> result = [];
    while (iterator.current != null) {
      result.add(elements.readFrom(iterator, state));
    }
    stream.moveNext();
    return result;
  }

  @override
  void writeTo(StringBuffer buffer, List<T> object, SerializationState? state) {
    buffer.write('(');
    for (int i = 0; i < object.length; ++i) {
      if (i != 0) buffer.write(' ');
      elements.writeTo(buffer, object[i], state);
    }
    buffer.write(')');
  }
}

class Optional<T> extends TextSerializer<T?> {
  final TextSerializer<T> contents;

  const Optional(this.contents);

  @override
  T? readFrom(Iterator<Object?> stream, DeserializationState? state) {
    if (stream.current == '_') {
      stream.moveNext();
      return null;
    }
    return contents.readFrom(stream, state);
  }

  @override
  void writeTo(StringBuffer buffer, T? object, SerializationState? state) {
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
class Binder<T extends Node> extends TextSerializer<Tuple2<String?, T>> {
  final Tuple2Serializer<String, T> namedContents;

  Binder(TextSerializer<T> contents)
      : namedContents = new Tuple2Serializer(const DartString(), contents);

  @override
  Tuple2<String, T> readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    if (state == null) {
      throw StateError(
          "No deserialization state provided for ${runtimeType}.readFrom.");
    }
    Tuple2<String, T> namedObject = namedContents.readFrom(stream, state);
    String name = namedObject.first;
    T object = namedObject.second;
    state.environment.addBinder(object, name);
    return new Tuple2(name, object);
  }

  @override
  void writeTo(StringBuffer buffer, Tuple2<String?, T> namedObject,
      SerializationState? state) {
    if (state == null) {
      throw StateError(
          "No serialization state provided for ${runtimeType}.writeTo.");
    }
    String? nameClue = namedObject.first;
    T object = namedObject.second;
    String distinctName =
        state.environment.addBinder(object, nameClue: nameClue);
    namedContents.writeTo(buffer, new Tuple2(distinctName, object), state);
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

  @override
  Tuple2<P, T> readFrom(Iterator<Object?> stream, DeserializationState? state) {
    if (state == null) {
      throw StateError(
          "No deserialization state provided for ${runtimeType}.readFrom.");
    }
    DeserializationState bindingState = new DeserializationState(
        new DeserializationEnvironment(state.environment), state.nameRoot);
    P first = pattern.readFrom(stream, bindingState);
    bindingState.environment.extend();
    T second = term.readFrom(stream, bindingState);
    return new Tuple2(first, second);
  }

  @override
  void writeTo(
      StringBuffer buffer, Tuple2<P, T> tuple, SerializationState? state) {
    if (state == null) {
      throw StateError(
          "No serialization state provided for ${runtimeType}.writeTo.");
    }
    SerializationState bindingState =
        new SerializationState(new SerializationEnvironment(state.environment));
    pattern.writeTo(buffer, tuple.first, bindingState);
    bindingState.environment.extend();
    buffer.write(' ');
    term.writeTo(buffer, tuple.second, bindingState);
  }
}

/// Nested binding pattern that also binds binders from one term in the other.
///
/// Serializes a [Tuple2] of [pattern1] and [pattern2], closing [pattern2] over
/// the binders found in [pattern1].  The binders from both [pattern1] and
/// [pattern2] are added to the enclosing environment.
class Rebind<P, T> extends TextSerializer<Tuple2<P, T>> {
  final TextSerializer<P> pattern1;
  final TextSerializer<T> pattern2;

  const Rebind(this.pattern1, this.pattern2);

  @override
  Tuple2<P, T> readFrom(Iterator<Object?> stream, DeserializationState? state) {
    if (state == null) {
      throw StateError(
          "No deserialization state provided for ${runtimeType}.readFrom.");
    }
    P first = pattern1.readFrom(stream, state);
    DeserializationState closedState = new DeserializationState(
        new DeserializationEnvironment(state.environment)
          ..binders.addAll(state.environment.binders)
          ..extend(),
        state.nameRoot);
    T second = pattern2.readFrom(stream, closedState);
    state.environment.binders.addAll(closedState.environment.binders);
    return new Tuple2(first, second);
  }

  @override
  void writeTo(
      StringBuffer buffer, Tuple2<P, T> tuple, SerializationState? state) {
    if (state == null) {
      throw StateError(
          "No serialization state provided for ${runtimeType}.writeTo.");
    }
    pattern1.writeTo(buffer, tuple.first, state);
    SerializationState closedState =
        new SerializationState(new SerializationEnvironment(state.environment)
          ..binders.addAll(state.environment.binders)
          ..extend());
    buffer.write(' ');
    pattern2.writeTo(buffer, tuple.second, closedState);
    state.environment.binders.addAll(closedState.environment.binders);
  }
}

class Zip<T, T1, T2> extends TextSerializer<List<T>> {
  final TextSerializer<Tuple2<List<T1>, List<T2>>> lists;
  final T Function(T1, T2) zip;
  final Tuple2<T1, T2> Function(T) unzip;

  const Zip(this.lists, this.zip, this.unzip);

  @override
  List<T> readFrom(Iterator<Object?> stream, DeserializationState? state) {
    Tuple2<List<T1>, List<T2>> toZip = lists.readFrom(stream, state);
    List<T1> firsts = toZip.first;
    List<T> zipped;
    if (firsts.isEmpty) {
      zipped = <T>[];
    } else {
      List<T2> seconds = toZip.second;
      zipped =
          new List<T>.filled(toZip.first.length, zip(firsts[0], seconds[0]));
      for (int i = 1; i < zipped.length; ++i) {
        zipped[i] = zip(firsts[i], seconds[i]);
      }
    }
    return zipped;
  }

  @override
  void writeTo(StringBuffer buffer, List<T> zipped, SerializationState? state) {
    List<T1> firsts;
    List<T2> seconds;
    if (zipped.isEmpty) {
      firsts = <T1>[];
      seconds = <T2>[];
    } else {
      Tuple2<T1, T2> initial = unzip(zipped[0]);
      firsts = new List<T1>.filled(zipped.length, initial.first);
      seconds = new List<T2>.filled(zipped.length, initial.second);
      for (int i = 1; i < zipped.length; ++i) {
        Tuple2<T1, T2> tuple = unzip(zipped[i]);
        firsts[i] = tuple.first;
        seconds[i] = tuple.second;
      }
    }
    lists.writeTo(buffer, new Tuple2(firsts, seconds), state);
  }
}
