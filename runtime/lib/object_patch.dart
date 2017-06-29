// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@patch
class Object {
  // The VM has its own implementation of equals.
  @patch
  bool operator ==(other) native "Object_equals";

  // Helpers used to implement hashCode. If a hashCode is used, we remember it
  // in a weak table in the VM. A new hashCode value is calculated using a
  // number generator.
  static final _hashCodeRnd = new Random();

  // Shared static implementation for hashCode and _identityHashCode.
  static _getHash(obj) native "Object_getHash";
  static _setHash(obj, hash) native "Object_setHash";

  static int _objectHashCode(obj) {
    var result = _getHash(obj);
    if (result == 0) {
      // We want the hash to be a Smi value greater than 0.
      result = _hashCodeRnd.nextInt(0x40000000);
      while (result == 0) {
        result = _hashCodeRnd.nextInt(0x40000000);
      }
      _setHash(obj, result);
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

  _noSuchMethod(bool isMethod, String memberName, int type, List arguments,
      Map<String, dynamic> namedArguments) native "Object_noSuchMethod";

  @patch
  dynamic noSuchMethod(Invocation invocation) {
    return _noSuchMethod(
        invocation.isMethod,
        internal.Symbol.getName(invocation.memberName),
        invocation._type,
        invocation.positionalArguments,
        _symbolMapToStringMap(invocation.namedArguments));
  }

  @patch
  Type get runtimeType native "Object_runtimeType";

  static bool _haveSameRuntimeType(a, b) native "Object_haveSameRuntimeType";

  // Call this function instead of inlining instanceof, thus collecting
  // type feedback and reducing code size of unoptimized code.
  bool _instanceOf(instantiatorTypeArguments, functionTypeArguments, type)
      native "Object_instanceOf";

  // Group of functions for implementing fast simple instance of.
  bool _simpleInstanceOf(type) native "Object_simpleInstanceOf";
  bool _simpleInstanceOfTrue(type) => true;
  bool _simpleInstanceOfFalse(type) => false;

  // Call this function instead of inlining 'as', thus collecting type
  // feedback. Returns receiver.
  _as(instantiatorTypeArguments, functionTypeArguments, type)
      native "Object_as";

  static _symbolMapToStringMap(Map<Symbol, dynamic> map) {
    var result = new Map<String, dynamic>();
    map.forEach((Symbol key, value) {
      result[internal.Symbol.getName(key)] = value;
    });
    return result;
  }
}
