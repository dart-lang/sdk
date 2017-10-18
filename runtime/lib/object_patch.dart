// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

int _getHash(obj) native "Object_getHash";
int _setHash(obj, hash) native "Object_setHash";

@patch
class Object {
  // The VM has its own implementation of equals.
  @patch
  bool operator ==(other) native "Object_equals";

  // Helpers used to implement hashCode. If a hashCode is used, we remember it
  // in a weak table in the VM (32 bit) or in the header of the object (64
  // bit). A new hashCode value is calculated using a random number generator.
  static final _hashCodeRnd = new Random();

  static int _objectHashCode(obj) {
    var result = _getHash(obj);
    if (result == 0) {
      // We want the hash to be a Smi value greater than 0.
      result = _hashCodeRnd.nextInt(0x40000000);
      do {
        result = _hashCodeRnd.nextInt(0x40000000);
      } while (result == 0);
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

  @patch
  dynamic noSuchMethod(Invocation invocation) {
    // TODO(regis): Remove temp constructor identifier 'withInvocation'.
    throw new NoSuchMethodError.withInvocation(this, invocation);
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
}
