// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An accumulator of a Dart code template, consisting of strings interspersed
/// with semantic nodes representing references to part of the user's program.
///
/// This is similar to a StringBuffer, except that:
/// - [write] requires a string argument (to prevent mistakes)
/// - additional methods are provided to allow writing semantic nodes that refer
///   to classes, enumerated values, etc.  These semantic nodes will be
///   converted to simple strings at a later time.
///
/// Clients who do not need the additional semantic information may obtain the
/// final string immediately using [SimpleDartBuffer].
abstract class DartTemplateBuffer<ConstantValue extends Object,
    EnumValue extends Object, Type extends Object> {
  /// Adds a text string to the buffer.
  void write(String text);

  /// Adds a semantic node representing the given boolean value to the buffer.
  void writeBoolValue(bool value);

  /// Adds a semantic node representing the given core type to the buffer.
  ///
  /// Ideally, callers should use [writeGeneralType] instead, since it allows
  /// [Type] information to be associated with the semantic node.  However, the
  /// exhaustiveness algorithm currently uses this method for the core types
  /// `Object`, `Never`, and `Null`, because its representation of those types
  /// doesn't track the necessary [Type] semantics.
  ///
  /// TODO(paulberry): add the necessary semantics tracking to the
  /// exhaustiveness checker so that this method can be eliminated.
  void writeCoreType(String name);

  /// Adds a semantic node representing the given enumerated [value] to the
  /// buffer.
  ///
  /// [name] is a simple string representation of the enumerated value.
  ///
  /// TODO(paulberry): consider replacing [SimpleDartBuffer] with a CFE
  /// implementation of [DartTemplateBuffer] that knows how to look up the name
  /// of the enum, so that we don't need the [name] parameter.
  void writeEnumValue(EnumValue value, String name);

  /// Adds a semantic node representing the given constant [value] to the
  /// buffer.
  ///
  /// [name] is a simple string representation of constant value.
  ///
  /// This is used for any constants that are not enum values or booleans.
  ///
  /// TODO(paulberry): investigate when this method is used.  Is it possible
  /// that [ConstantValue] might be a literal (and hence won't necessarily have
  /// a name?)
  void writeGeneralConstantValue(ConstantValue value, String name);

  /// Adds a semantic node representing the given [type] to the buffer.
  ///
  /// [name] is a simple string representation of the type.
  ///
  /// TODO(paulberry): consider replacing [SimpleDartBuffer] with a CFE
  /// implementation of [DartTemplateBuffer] that knows how to look up the name
  /// of the type, so that we don't need the [name] parameter.
  ///
  /// TODO(paulberry): what happens if the type is a typedef (e.g.
  /// `typedef A = void Function();`).
  void writeGeneralType(Type type, String name);
}

/// An accumulator of a Dart code template that discards semantic information,
/// immediately producing a simple string.
class SimpleDartBuffer implements DartTemplateBuffer<Object, Object, Object> {
  final StringBuffer _buffer = new StringBuffer();

  @override
  String toString() => _buffer.toString();

  @override
  void write(String text) {
    _buffer.write(text);
  }

  @override
  void writeBoolValue(bool value) {
    _buffer.write(value);
  }

  @override
  void writeCoreType(String name) {
    _buffer.write(name);
  }

  @override
  void writeEnumValue(Object value, String name) {
    _buffer.write(name);
  }

  @override
  void writeGeneralConstantValue(Object value, String name) {
    _buffer.write(name);
  }

  @override
  void writeGeneralType(Object type, String name) {
    _buffer.write(name);
  }
}
