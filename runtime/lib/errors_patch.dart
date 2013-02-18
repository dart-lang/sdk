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

  const NoSuchMethodError(Object this._receiver,
                          String this._memberName,
                          List this._arguments,
                          Map<String,dynamic> this._namedArguments,
                          [List existingArgumentNames = null])
      : this._existingArgumentNames = existingArgumentNames;

  /* patch */ String toString() {
    StringBuffer actual_buf = new StringBuffer();
    int i = 0;
    if (_arguments != null) {
      for (; i < _arguments.length; i++) {
        if (i > 0) {
          actual_buf.add(", ");
        }
        actual_buf.add(Error.safeToString(_arguments[i]));
      }
    }
    if (_namedArguments != null) {
      _namedArguments.forEach((String key, var value) {
        if (i > 0) {
          actual_buf.add(", ");
        }
        actual_buf.add(key);
        actual_buf.add(": ");
        actual_buf.add(Error.safeToString(value));
        i++;
      });
    }
    StringBuffer msg_buf = new StringBuffer();
    if (_existingArgumentNames == null) {
      msg_buf.add(
          "NoSuchMethodError : method not found: '$_memberName'\n"
          "Receiver: ${Error.safeToString(_receiver)}\n"
          "Arguments: [$actual_buf]");
    } else {
      String actualParameters = actual_buf.toString();
      StringBuffer formal_buf = new StringBuffer();
      for (int i = 0; i < _existingArgumentNames.length; i++) {
        if (i > 0) {
          formal_buf.add(", ");
        }
        formal_buf.add(_existingArgumentNames[i]);
      }
      String formalParameters = formal_buf.toString();
      msg_buf.add( 
          "NoSuchMethodError: incorrect number of arguments passed to "
          "method named '$_memberName'\n"
          "Receiver: ${Error.safeToString(_receiver)}\n"
          "Tried calling: $_memberName($actualParameters)\n"
          "Found: $_memberName($formalParameters)");
    }
    return msg_buf.toString();
  }
}
