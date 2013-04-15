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
    if (this == null) {
      return 2011;  // The year Dart was announced and a prime.
    }
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

  _noSuchMethod(bool isMethod,
                String memberName,
                int type,
                List arguments,
                Map<String, dynamic> namedArguments)
      native "Object_noSuchMethod";

  /* patch */ noSuchMethod(Invocation invocation) {
    return _noSuchMethod(invocation.isMethod,
                         invocation.memberName,
                         invocation._type,
                         invocation.positionalArguments,
                         invocation.namedArguments);
  }

  /* patch */ Type get runtimeType native "Object_runtimeType";

  // Call this function instead of inlining instanceof, thus collecting
  // type feedback and reducing code size of unoptimized code.
  bool _instanceOf(instantiator,
                   instantiator_type_arguments,
                   type,
                   bool negate)
      native "Object_instanceOf";

  // Call this function instead of inlining 'as', thus collecting type
  // feedback. Returns receiver.
  _as(instantiator, instantiator_type_arguments, type) native "Object_as";
}
