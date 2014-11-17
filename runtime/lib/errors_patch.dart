// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors' show MirrorSystem;
import 'dart:convert' show JSON;

patch class Error {
  /* patch */ static String _objectToString(Object object) {
    return Object._toString(object);
  }

  /* patch */ static String _stringToSafeString(String string) {
    return JSON.encode(string);
  }

  /* patch */ StackTrace get stackTrace => _stackTrace;

  StackTrace _stackTrace;
}

class _AssertionError extends Error implements AssertionError {
  _AssertionError._create(
      this._failedAssertion, this._url, this._line, this._column);

  static _throwNew(int assertionStart, int assertionEnd)
      native "AssertionError_throwNew";

  String toString() {
    var columnInfo = "";
    if (_column > 0) {
      // Only add column information if it is valid.
      columnInfo = " pos $_column";
    }
    return "'$_url': Failed assertion: line $_line$columnInfo: "
        "'$_failedAssertion' is not true.";
  }
  final String _failedAssertion;
  final String _url;
  final int _line;
  final int _column;
}

class _TypeError extends _AssertionError implements TypeError {
  _TypeError._create(String url, int line, int column,
                     this._srcType, this._dstType, this._dstName,
                     this._errorMsg)
      : super._create("is assignable", url, line, column);

  static _throwNew(int location,
                   Object src_value,
                   String dst_type_name,
                   String dst_name,
                   String error_msg)
      native "TypeError_throwNew";

  String toString() {
    String str = (_errorMsg != null) ? _errorMsg : "";
    if ((_dstName != null) && (_dstName.length > 0)) {
      str = "${str}type '$_srcType' is not a subtype of "
            "type '$_dstType' of '$_dstName'.";
    } else {
      str = "${str}type error.";
    }
    return str;
  }

  final String _srcType;
  final String _dstType;
  final String _dstName;
  final String _errorMsg;
}

class _CastError extends Error implements CastError {
  _CastError._create(this._url, this._line, this._column,
                     this._srcType, this._dstType, this._dstName,
                     this._errorMsg);

  // A CastError is allocated by TypeError._throwNew() when dst_name equals
  // Exceptions::kCastErrorDstName.

  String toString() {
    String str = (_errorMsg != null) ? _errorMsg : "";
    str = "${str}type '$_srcType' is not a subtype of "
          "type '$_dstType' in type cast.";
    return str;
  }

  // Fields _url, _line, and _column are only used for debugging purposes.
  final String _url;
  final int _line;
  final int _column;
  final String _srcType;
  final String _dstType;
  final String _dstName;
  final String _errorMsg;
}

patch class FallThroughError {
  FallThroughError._create(this._url, this._line);

  static _throwNew(int case_clause_pos) native "FallThroughError_throwNew";

  /* patch */ String toString() {
    return "'$_url': Switch case fall-through at line $_line.";
  }

  // These new fields cannot be declared final, because a constructor exists
  // in the original version of this patched class.
  String _url;
  int _line;
}

class _InternalError {
  const _InternalError(this._msg);
  String toString() => "InternalError: '${_msg}'";
  final String _msg;
}

patch class CyclicInitializationError {
  static _throwNew(String variableName) {
    throw new CyclicInitializationError(variableName);
  }
}

patch class AbstractClassInstantiationError {
  AbstractClassInstantiationError._create(
      this._className, this._url, this._line);

  static _throwNew(int case_clause_pos, String className)
      native "AbstractClassInstantiationError_throwNew";

  /* patch */ String toString() {
    return "Cannot instantiate abstract class $_className: "
           "_url '$_url' line $_line";
  }

  // These new fields cannot be declared final, because a constructor exists
  // in the original version of this patched class.
  String _url;
  int _line;
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
      // Differ between no arguments specified and 0 arguments.
      // TODO(srdjan): This can currently occur for unresolvable static methods.
      // In that case, the arguments are evaluated but not passed to the
      // throwing stub (see EffectGraphVisitor::BuildThrowNoSuchMethodError and
      // Parser::ThrowNoSuchMethodError)).
      positionalArguments = argumentNames == null ? null : [];
    } else {
      positionalArguments = arguments.sublist(0, numPositionalArguments);
    }
    Map<Symbol, dynamic> namedArguments = new Map<Symbol, dynamic>();
    for (int i = 0; i < numNamedArguments; i++) {
      var arg_value = arguments[numPositionalArguments + i];
      namedArguments[new Symbol(argumentNames[i])] = arg_value;
    }
    throw new NoSuchMethodError._withType(receiver,
                                          new Symbol(memberName),
                                          invocation_type,
                                          positionalArguments,
                                          namedArguments,
                                          existingArgumentNames);
  }

  // Remember the type from the invocation mirror or static compilation
  // analysis when thrown directly with _throwNew. A negative value means
  // that no information is available.
  final int _invocation_type;

  NoSuchMethodError(Object this._receiver,
                    Symbol this._memberName,
                    List this._arguments,
                    Map<Symbol, dynamic> this._namedArguments,
                    [List existingArgumentNames = null])
      : this._existingArgumentNames = existingArgumentNames,
        this._invocation_type = -1;

  // This constructor seems to be called with either strings or
  // values read from another NoSuchMethodError.
  NoSuchMethodError._withType(Object this._receiver,
                              /*String|Symbol*/ memberName,
                              this._invocation_type,
                              List this._arguments,
                              Map<dynamic, dynamic> namedArguments,
                              [List existingArgumentNames = null])
      : this._memberName =
            (memberName is String) ? new Symbol(memberName) : memberName,
        this._namedArguments =
            (namedArguments == null)
                ? null
                : new Map<Symbol, dynamic>.fromIterable(
                    namedArguments.keys,
                    key: (k) => (k is String) ? new Symbol(k) : k,
                    value: (k) => namedArguments[k]),
        this._existingArgumentNames = existingArgumentNames;


  String _developerMessage(args_mismatch) {
    if (_invocation_type < 0) {
      return "";
    }
    var type = _invocation_type & _InvocationMirror._TYPE_MASK;
    var level = (_invocation_type >> _InvocationMirror._CALL_SHIFT) &
         _InvocationMirror._CALL_MASK;
    var type_str =
        (const ["method", "getter", "setter", "getter or setter", "variable"])[type];
    var args_message = args_mismatch ? " with matching arguments" : "";
    var msg;
    var memberName =
        (_memberName == null) ? "" : MirrorSystem.getName(_memberName);

    if (type == _InvocationMirror._LOCAL_VAR) {
      return "cannot assign to final variable '$memberName'.\n\n";
    }
    switch (level) {
      case _InvocationMirror._DYNAMIC: {
        if (_receiver == null) {
          msg = "The null object does not have a $type_str '$memberName'"
              "$args_message.";
        } else {
          if (_receiver is Function) {
            msg = "Closure call with mismatched arguments: "
                "function '$memberName'";
          } else {
            msg = "Class '${_receiver.runtimeType}' has no instance $type_str "
                "'$memberName'$args_message.";
          }
        }
        break;
      }
      case _InvocationMirror._SUPER: {
        msg = "Super class of class '${_receiver.runtimeType}' has no instance "
              "$type_str '$memberName'$args_message.";
        break;
      }
      case _InvocationMirror._STATIC: {
        msg = "No static $type_str '$memberName' declared in class "
            "'$_receiver'.";
        break;
      }
      case _InvocationMirror._CONSTRUCTOR: {
        msg = "No constructor '$memberName'$args_message declared in class '$_receiver'.";
        break;
      }
      case _InvocationMirror._TOP_LEVEL: {
        msg = "No top-level $type_str '$memberName'$args_message declared.";
        break;
      }
    }
    return "$msg\n\n";
  }

  /* patch */ String toString() {
    StringBuffer actual_buf = new StringBuffer();
    int i = 0;
    if (_arguments == null) {
      // Actual arguments unknown.
      // TODO(srdjan): Remove once arguments are passed for unresolvable
      // static methods.
      actual_buf.write("...");
    } else {
      for (; i < _arguments.length; i++) {
        if (i > 0) {
          actual_buf.write(", ");
        }
        actual_buf.write(Error.safeToString(_arguments[i]));
      }
    }
    if (_namedArguments != null) {
      _namedArguments.forEach((Symbol key, var value) {
        if (i > 0) {
          actual_buf.write(", ");
        }
        actual_buf.write(MirrorSystem.getName(key));
        actual_buf.write(": ");
        actual_buf.write(Error.safeToString(value));
        i++;
      });
    }
    var args_mismatch = _existingArgumentNames != null;
    StringBuffer msg_buf = new StringBuffer(_developerMessage(args_mismatch));
    String receiver_str;
    var level = (_invocation_type >> _InvocationMirror._CALL_SHIFT) &
        _InvocationMirror._CALL_MASK;
    if ( level == _InvocationMirror._TOP_LEVEL) {
      receiver_str = "top-level";
    } else {
      receiver_str = Error.safeToString(_receiver);
    }
    var memberName =
        (_memberName == null) ? "" : MirrorSystem.getName(_memberName);
    var type = _invocation_type & _InvocationMirror._TYPE_MASK;
    if (type == _InvocationMirror._LOCAL_VAR) {
      msg_buf.write(
          "NoSuchMethodError: cannot assign to final variable '$memberName'");
    } else if (!args_mismatch) {
      msg_buf.write(
          "NoSuchMethodError: method not found: '$memberName'\n"
          "Receiver: $receiver_str\n"
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
          "method named '$memberName'\n"
          "Receiver: $receiver_str\n"
          "Tried calling: $memberName($actualParameters)\n"
          "Found: $memberName($formalParameters)");
    }
    return msg_buf.toString();
  }
}

class _JavascriptIntegerOverflowError extends Error {
  final Object _value;

  _JavascriptIntegerOverflowError(this._value);
  String toString() => "Javascript Integer Overflow: $_value";
}

class _JavascriptCompatibilityError extends Error {
  final String _msg;

  _JavascriptCompatibilityError(this._msg);
  String toString() => "Javascript Compatibility Error: $_msg";
}

