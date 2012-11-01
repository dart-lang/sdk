// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Object {

  // Helpers used to implement hashCode. If a hashCode is used we remember it
  // using an Expando object. A new hashCode value is calculated using a Random
  // number generator.
  static Expando _hashCodeExp = new Expando("Object.hashCode");
  static Random _hashCodeRnd = new Random();

  /* patch */ int get hashCode {
    var result = _hashCodeExp[this];
    if (result == null) {
      result = _hashCodeRnd.nextInt(0x40000000);  // Stay in Smi range.
      _hashCodeExp[this] = result;
    }
    return result;
  }

  /* patch */ String toString() native "Object_toString";
  // A statically dispatched version of Object.toString.
  static String _toString(obj) native "Object_toString";

  dynamic _noSuchMethod(String functionName, List args)
      native "Object_noSuchMethod";

  /* patch */ dynamic noSuchMethod(InvocationMirror invocation) {
    var methodName = invocation.memberName;
    var args = invocation.positionalArguments;
    return _noSuchMethod(methodName, args);
  }

  /* patch */ Type get runtimeType native "Object_runtimeType";
}
