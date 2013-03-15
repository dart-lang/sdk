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
                        int invocation_type,
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
      positionalArguments = arguments.sublist(0, numPositionalArguments);
    }
    Map<String, dynamic> namedArguments = new Map<String, dynamic>();
    for (int i = 0; i < numNamedArguments; i++) {
      var arg_value = arguments[numPositionalArguments + i];
      namedArguments[argumentNames[i]] = arg_value;
    }
    throw new NoSuchMethodError._withType(receiver,
                                memberName,
                                invocation_type,
                                positionalArguments,
                                namedArguments,
                                existingArgumentNames);
  }

  // Remember the type from the invocation mirror or static compilation
  // analysis when thrown directly with _throwNew. A negative value means
  // that no information is available.
  final int _invocation_type;

  const NoSuchMethodError(Object this._receiver,
                          String this._memberName,
                          List this._arguments,
                          Map<String,dynamic> this._namedArguments,
                          [List existingArgumentNames = null])
      : this._existingArgumentNames = existingArgumentNames,
        this._invocation_type = -1;

  const NoSuchMethodError._withType(Object this._receiver,
                                    String this._memberName,
                                    this._invocation_type,
                                    List this._arguments,
                                    Map<String,dynamic> this._namedArguments,
                                    [List existingArgumentNames = null])
      : this._existingArgumentNames = existingArgumentNames;


  String _developerMessage(args_mismatch) {
    if (_invocation_type < 0) {
      return "";
    }
    var type = _invocation_type & _InvocationMirror._TYPE_MASK;
    var level = (_invocation_type >> _InvocationMirror._CALL_SHIFT) &
         _InvocationMirror._CALL_MASK;
    var type_str =
        (const ["method", "getter", "setter", "getter or setter"])[type];
    var args_message = args_mismatch ? " with matching arguments" : "";
    var msg;
    switch (level) {
      case _InvocationMirror._DYNAMIC: {
        if (_receiver == null) {
          msg = "The null object does not have a $type_str '$_memberName'"
              "$args_message.";
        } else {
          msg = "Class '${_receiver.runtimeType}' has no instance $type_str "
              "'$_memberName'$args_message.";
        }
        break;
      }
      case _InvocationMirror._STATIC: {
        msg = "No static $type_str '$_memberName' declared in class "
            "'$_receiver'.";
        break;
      }
      case _InvocationMirror._CONSTRUCTOR: {
        msg = "No constructor '$_memberName' declared in class '$_receiver'.";
        break;
      }
      case _InvocationMirror._TOP_LEVEL: {
        msg = "No top-level $type_str '$_memberName' declared.";
        break;
      }
    }
    return "$msg\n\n";
  }

  /* patch */ String toString() {
    StringBuffer actual_buf = new StringBuffer();
    int i = 0;
    if (_arguments != null) {
      for (; i < _arguments.length; i++) {
        if (i > 0) {
          actual_buf.write(", ");
        }
        actual_buf.write(Error.safeToString(_arguments[i]));
      }
    }
    if (_namedArguments != null) {
      _namedArguments.forEach((String key, var value) {
        if (i > 0) {
          actual_buf.write(", ");
        }
        actual_buf.write(key);
        actual_buf.write(": ");
        actual_buf.write(Error.safeToString(value));
        i++;
      });
    }
    var args_mismatch = _existingArgumentNames != null;
    StringBuffer msg_buf = new StringBuffer(_developerMessage(args_mismatch));
    if (!args_mismatch) {
      msg_buf.write(
          "NoSuchMethodError : method not found: '$_memberName'\n"
          "Receiver: ${Error.safeToString(_receiver)}\n"
          "Arguments: [$actual_buf]");
    } else {
      String actualParameters = actual_buf.toString();
      StringBuffer formal_buf = new StringBuffer();
      for (int i = 0; i < _existingArgumentNames.length; i++) {
        if (i > 0) {
          formal_buf.write(", ");
        }
        formal_buf.write(_existingArgumentNames[i]);
      }
      String formalParameters = formal_buf.toString();
      msg_buf.write(
          "NoSuchMethodError: incorrect number of arguments passed to "
          "method named '$_memberName'\n"
          "Receiver: ${Error.safeToString(_receiver)}\n"
          "Tried calling: $_memberName($actualParameters)\n"
          "Found: $_memberName($formalParameters)");
    }
    return msg_buf.toString();
  }
}
