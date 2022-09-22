// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:exact-result-type", "dart:core#_Smi")
@pragma("vm:external-name", "Object_getHash")
external int _getHash(obj);

@patch
@pragma("vm:entry-point")
class Object {
  // The VM has its own implementation of equals.
  @patch
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "Object_equals")
  external bool operator ==(Object other);

  @patch
  int get hashCode => _getHash(this);
  int get _identityHashCode => _getHash(this);

  @patch
  @pragma("vm:external-name", "Object_toString")
  external String toString();
  // A statically dispatched version of Object.toString.
  @pragma("vm:external-name", "Object_toString")
  external static String _toString(obj);

  @patch
  @pragma("vm:entry-point", "call")
  dynamic noSuchMethod(Invocation invocation) {
    // TODO(regis): Remove temp constructor identifier 'withInvocation'.
    throw new NoSuchMethodError.withInvocation(this, invocation);
  }

  @patch
  @pragma("vm:recognized", "asm-intrinsic")
  // Result type is either "dart:core#_Type" or "dart:core#_FunctionType".
  @pragma("vm:external-name", "Object_runtimeType")
  external Type get runtimeType;

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:entry-point", "call")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "Object_haveSameRuntimeType")
  external static bool _haveSameRuntimeType(a, b);

  // Call this function instead of inlining instanceof, thus collecting
  // type feedback and reducing code size of unoptimized code.
  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "Object_instanceOf")
  external bool _instanceOf(
      instantiatorTypeArguments, functionTypeArguments, type);

  // Group of functions for implementing fast simple instance of.
  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "Object_simpleInstanceOf")
  external bool _simpleInstanceOf(type);
  @pragma("vm:entry-point", "call")
  bool _simpleInstanceOfTrue(type) => true;
  @pragma("vm:entry-point", "call")
  bool _simpleInstanceOfFalse(type) => false;
}

// Used by DartLibraryCalls::Equals.
@pragma("vm:entry-point", "call")
bool _objectEquals(Object? o1, Object? o2) => o1 == o2;

// Used by DartLibraryCalls::HashCode.
@pragma("vm:entry-point", "call")
int _objectHashCode(Object? obj) => obj.hashCode;

// Used by DartLibraryCalls::ToString.
@pragma("vm:entry-point", "call")
String _objectToString(Object? obj) => obj.toString();

// Used by DartEntry::InvokeNoSuchMethod.
@pragma("vm:entry-point", "call")
dynamic _objectNoSuchMethod(Object? obj, Invocation invocation) =>
    obj.noSuchMethod(invocation);

// Base class for record instances.
// TODO(dartbug.com/49719): create a separate patch file for this class.
@pragma("vm:entry-point")
class _Record {
  factory _Record._uninstantiable() {
    throw "Unreachable";
  }

  // Do not inline to avoid mixing _fieldAt with
  // record field accesses.
  @pragma("vm:never-inline")
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! _Record) {
      return false;
    }

    _Record otherRec = unsafeCast<_Record>(other);
    final int numFields = _numFields;
    if (numFields != otherRec._numFields ||
        !identical(_fieldNames, otherRec._fieldNames)) {
      return false;
    }

    for (int i = 0; i < numFields; ++i) {
      if (_fieldAt(i) != otherRec._fieldAt(i)) {
        return false;
      }
    }
    return true;
  }

  // Do not inline to avoid mixing _fieldAt with
  // record field accesses.
  @pragma("vm:never-inline")
  int get hashCode {
    final int numFields = _numFields;
    int hash = numFields;
    hash = SystemHash.combine(hash, identityHashCode(_fieldNames));
    for (int i = 0; i < numFields; ++i) {
      hash = SystemHash.combine(hash, _fieldAt(i).hashCode);
    }
    return SystemHash.finish(hash);
  }

  // Do not inline to avoid mixing _fieldAt with
  // record field accesses.
  @pragma("vm:never-inline")
  String toString() {
    StringBuffer buffer = StringBuffer("(");
    final int numFields = _numFields;
    final _List fieldNames = _fieldNames;
    final int numPositionalFields = numFields - fieldNames.length;
    for (int i = 0; i < numFields; ++i) {
      if (i != 0) {
        buffer.write(", ");
      }
      if (i >= numPositionalFields) {
        buffer.write(unsafeCast<String>(fieldNames[i - numPositionalFields]));
        buffer.write(": ");
      }
      buffer.write(_fieldAt(i).toString());
    }
    buffer.write(")");
    return buffer.toString();
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external int get _numFields;

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external _List get _fieldNames;

  // Currently compiler does not take into account aliasing
  // between access to record fields via _fieldAt and
  // via record.foo / record.$n.
  // So this method should only be used in methods
  // which only access record fields with _fieldAt and
  // annotated with @pragma("vm:never-inline").
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external Object? _fieldAt(int index);
}
