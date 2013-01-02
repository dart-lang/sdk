// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Error {
  /* patch */ static String _objectToString(Object object) {
    return Object._toString(object);
  }
}

patch class NoSuchMethodError {
  // The compiler emits a call to _throwNew when it cannot resolve a static
  // method at compile time. The receiver is actually the literal class of the
  // unresolved method.
  static void _throwNew(Object receiver,
                        String memberName,
                        List arguments,
                        List argumentNames,
                        List existingArgumentNames) {
    int numNamedArguments = argumentNames == null ? 0 : argumentNames.length;
    int numPositionalArguments = arguments == null ? 0 : arguments.length;
    numPositionalArguments -= numNamedArguments;
    List positionalArguments;
    if (numPositionalArguments == 0) {
      positionalArguments = [];
    } else {
      positionalArguments = arguments.getRange(0, numPositionalArguments);
    }
    Map<String, dynamic> namedArguments = new Map<String, dynamic>();
    for (int i = 0; i < numNamedArguments; i++) {
      var arg_value = arguments[numPositionalArguments + i];
      namedArguments[argumentNames[i]] = arg_value;
    }
    throw new NoSuchMethodError(receiver,
                                memberName,
                                positionalArguments,
                                namedArguments,
                                existingArgumentNames);
  }
}
