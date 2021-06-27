// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:exact-result-type", "dart:core#_Smi")
int _getHash(obj) native "Object_getHash";

/// Set hash code associated with the object if it is not set yet
/// and return the current hash code. See [Object._objectHashCode]
/// for why this function needs to check for already set hash code.
@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:exact-result-type", "dart:core#_Smi")
int _setHashIfNotSetYet(obj, int hash) native "Object_setHashIfNotSetYet";

@patch
@pragma("vm:entry-point")
class Object {
  // The VM has its own implementation of equals.
  @patch
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:prefer-inline")
  bool operator ==(Object other) native "Object_equals";

  // Helpers used to implement hashCode. If a hashCode is used, we remember it
  // in a weak table in the VM (32 bit) or in the header of the object (64
  // bit). A new hashCode value is calculated using a random number generator.
  static final _hashCodeRnd = new Random();

  static int _objectHashCode(obj) {
    var result = _getHash(obj);
    if (result == 0) {
      // We want the hash to be a Smi value greater than 0.
      do {
        result = _hashCodeRnd.nextInt(0x40000000);
      } while (result == 0);

      // Caveat: we might be interrupted by vm-service which then
      // can initialize [this] object's hash code, that is why we need to
      // return the return value of [_setHashIfNotSetYet] rather than
      // returning [result] itself.
      return _setHashIfNotSetYet(obj, result);
    }
    return result;
  }

  @patch
  int get hashCode => _objectHashCode(this);
  int get _identityHashCode => _objectHashCode(this);

  @patch
  String toString() native "Object_toString";
  // A statically dispatched version of Object.toString.
  static String _toString(obj) native "Object_toString";

  @patch
  @pragma("vm:entry-point", "call")
  dynamic noSuchMethod(Invocation invocation) {
    // TODO(regis): Remove temp constructor identifier 'withInvocation'.
    throw new NoSuchMethodError.withInvocation(this, invocation);
  }

  @patch
  @pragma("vm:recognized", "asm-intrinsic")
  // Result type is either "dart:core#_Type" or "dart:core#_FunctionType".
  Type get runtimeType native "Object_runtimeType";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:entry-point", "call")
  @pragma("vm:exact-result-type", bool)
  static bool _haveSameRuntimeType(a, b) native "Object_haveSameRuntimeType";

  // Call this function instead of inlining instanceof, thus collecting
  // type feedback and reducing code size of unoptimized code.
  @pragma("vm:entry-point", "call")
  bool _instanceOf(instantiatorTypeArguments, functionTypeArguments, type)
      native "Object_instanceOf";

  // Group of functions for implementing fast simple instance of.
  @pragma("vm:entry-point", "call")
  bool _simpleInstanceOf(type) native "Object_simpleInstanceOf";
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
