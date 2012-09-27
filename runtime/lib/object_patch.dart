// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Object {

  // Helpers used to implement hashCode. If a hashCode is used we remember it
  // using an Expando object. A new hashCode value is calculated using a Random
  // number generator.
  static Expando _hashCodeExp = new Expando("Object.hashCode");
  static Random _hashCodeRnd = new Random();

  /* patch */ int hashCode() {
    var result = _hashCodeExp[this];
    if (result == null) {
      result = _hashCodeRnd.nextInt(0x40000000);  // Stay in Smi range.
      _hashCodeExp[this] = result;
    }
    return result;
  }

  /* patch */ String toString() => _toString(this);

  /* patch */ Dynamic noSuchMethod(String functionName, List args) {
    _noSuchMethod(this, functionName, args);
  }

  // Not yet supported.
  /* patch */ Type get runtimeType => null;

  static void _noSuchMethod(Object obj, String functionName, List args)
      native "Object_noSuchMethod";

  static String _toString(Object obj) native "Object_toString";
}
