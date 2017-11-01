// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@patch
class Error {
  @patch
  static String _objectToString(Object object) {
    return Object._toString(object);
  }

  @patch
  static String _stringToSafeString(String string) {
    return JSON.encode(string);
  }

  @patch
  StackTrace get stackTrace => _stackTrace;

  StackTrace _stackTrace;
}

class _AssertionError extends Error implements AssertionError {
  _AssertionError._create(
      this._failedAssertion, this._url, this._line, this._column, this.message);

  // AssertionError_throwNew in errors.cc fishes the assertion source code
  // out of the script. It expects a Dart stack frame from class
  // _AssertionError. Thus we need a Dart stub that calls the native code.
  static _throwNew(int assertionStart, int assertionEnd, Object message) {
    _doThrowNew(assertionStart, assertionEnd, message);
  }

  static _doThrowNew(int assertionStart, int assertionEnd, Object message)
      native "AssertionError_throwNew";

  static _evaluateAssertion(condition) {
    if (identical(condition, true) || identical(condition, false)) {
      return condition;
    }
    if (condition is _Closure) {
      return condition();
    }
    if (condition is Function) {
      condition = condition();
    }
    return condition;
  }

  String get _messageString {
    if (message == null) return "is not true.";
    if (message is String) return message;
    return Error.safeToString(message);
  }

  String toString() {
    if (_url == null) {
      if (message == null) return _failedAssertion?.trim();
      return "'${_failedAssertion?.trim()}': $_messageString";
    }
    var columnInfo = "";
    if (_column > 0) {
      // Only add column information if it is valid.
      columnInfo = " pos $_column";
    }
    return "'$_url': Failed assertion: line $_line$columnInfo: "
        "'$_failedAssertion': $_messageString";
  }

  final String _failedAssertion;
  final String _url;
  final int _line;
  final int _column;
  final Object message;
}

class _TypeError extends _AssertionError implements TypeError {
  _TypeError._create(String url, int line, int column, String errorMsg)
      : super._create("is assignable", url, line, column, errorMsg);

  static _throwNew(int location, Object src_value, _Type dst_type,
      String dst_name, String bound_error_msg) native "TypeError_throwNew";

  static _throwNewIfNotLoaded(
      _LibraryPrefix prefix,
      int location,
      Object src_value,
      _Type dst_type,
      String dst_name,
      String bound_error_msg) {
    if (!prefix.isLoaded()) {
      _throwNew(location, src_value, dst_type, dst_name, bound_error_msg);
    }
  }

  String toString() => super.message;
}

class _CastError extends Error implements CastError {
  _CastError._create(this._url, this._line, this._column, this._errorMsg);

  // A CastError is allocated by TypeError._throwNew() when dst_name equals
  // Symbols::InTypeCast().

  String toString() => _errorMsg;

  // Fields _url, _line, and _column are only used for debugging purposes.
  final String _url;
  final int _line;
  final int _column;
  final String _errorMsg;
}

@patch
class FallThroughError {
  @patch
  FallThroughError._create(String url, int line)
      : _url = url,
        _line = line;

  static _throwNew(int case_clause_pos) native "FallThroughError_throwNew";

  @patch
  String toString() {
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

@patch
class UnsupportedError {
  static _throwNew(String msg) {
    throw new UnsupportedError(msg);
  }
}

@patch
class CyclicInitializationError {
  static _throwNew(String variableName) {
    throw new CyclicInitializationError(variableName);
  }
}

@patch
class AbstractClassInstantiationError {
  AbstractClassInstantiationError._create(
      this._className, this._url, this._line);

  static _throwNew(int case_clause_pos, String className)
      native "AbstractClassInstantiationError_throwNew";

  @patch
  String toString() {
    return "Cannot instantiate abstract class $_className: "
        "_url '$_url' line $_line";
  }

  // These new fields cannot be declared final, because a constructor exists
  // in the original version of this patched class.
  String _url;
  int _line;
}

@patch
class NoSuchMethodError {
  // TODO(regis): Move _receiver declaration here:
  // final Object _receiver;
  final _InvocationMirror _invocation;

  @patch
  NoSuchMethodError.withInvocation(Object receiver, Invocation invocation)
      : _receiver = receiver,
        _invocation = invocation as _InvocationMirror;

  // The compiler emits a call to _throwNew when it cannot resolve a static
  // method at compile time. The receiver is actually the literal class of the
  // unresolved method.
  static void _throwNew(Object receiver, String memberName, int invocation_type,
      Object typeArguments, List arguments, List argumentNames) {
    throw new NoSuchMethodError._withType(receiver, memberName, invocation_type,
        typeArguments, arguments, argumentNames);
  }

  static void _throwNewIfNotLoaded(
      _LibraryPrefix prefix,
      Object receiver,
      String memberName,
      int invocation_type,
      Object typeArguments,
      List arguments,
      List argumentNames) {
    if (!prefix.isLoaded()) {
      _throwNew(receiver, memberName, invocation_type, typeArguments, arguments,
          argumentNames);
    }
  }

  // TODO(regis): Deprecated member still used by dart2js to be removed.
  // Remember the type from the invocation mirror or static compilation
  // analysis when thrown directly with _throwNew. A negative value means
  // that no information is available.
  final int _invocation_type;

  // TODO(regis): Deprecated constructor still used by dart2js to be removed.
  @patch
  NoSuchMethodError(Object receiver, Symbol memberName,
      List positionalArguments, Map<Symbol, dynamic> namedArguments,
      [List existingArgumentNames = null])
      : _receiver = receiver,
        _memberName = memberName,
        _arguments = positionalArguments,
        _namedArguments = namedArguments,
        _existingArgumentNames = existingArgumentNames,
        _invocation_type = -1;

  // Helper to build a map of named arguments.
  static Map<Symbol, dynamic> _NamedArgumentsMap(
      List arguments, List argumentNames) {
    Map<Symbol, dynamic> namedArguments = new Map<Symbol, dynamic>();
    int numPositionalArguments = arguments.length - argumentNames.length;
    for (int i = 0; i < argumentNames.length; i++) {
      var arg_value = arguments[numPositionalArguments + i];
      namedArguments[new Symbol(argumentNames[i])] = arg_value;
    }
    return namedArguments;
  }

  // Constructor called from Exceptions::ThrowByType(kNoSuchMethod) and from
  // _throwNew above, taking a TypeArguments object rather than an unpacked list
  // of types, as well as a list of all arguments and a list of names, rather
  // than a separate list of positional arguments and a map of named arguments.
  NoSuchMethodError._withType(
      this._receiver,
      String memberName,
      int invocation_type,
      Object typeArguments,
      List arguments,
      List argumentNames)
      : this._invocation = new _InvocationMirror._withType(
            new Symbol(memberName),
            invocation_type,
            typeArguments != null
                ? _InvocationMirror._unpackTypeArguments(typeArguments)
                : null,
            argumentNames != null
                ? arguments.sublist(0, arguments.length - argumentNames.length)
                : arguments,
            argumentNames != null
                ? _NamedArgumentsMap(arguments, argumentNames)
                : null);

  static String _existingMethodSignature(Object receiver, String methodName,
      int invocationType) native "NoSuchMethodError_existingMethodSignature";

  @patch
  String toString() {
    // TODO(regis): Remove this null check once dart2js is updated.
    if (_invocation == null) {
      // Use deprecated version of toString.
      return _toStringDeprecated();
    }
    String memberName =
        internal.Symbol.computeUnmangledName(_invocation.memberName);
    var level = (_invocation._type >> _InvocationMirror._LEVEL_SHIFT) &
        _InvocationMirror._LEVEL_MASK;
    var kind = _invocation._type & _InvocationMirror._KIND_MASK;
    if (kind == _InvocationMirror._LOCAL_VAR) {
      return "NoSuchMethodError: Cannot assign to final variable '$memberName'";
    }

    StringBuffer typeArgumentsBuf = null;
    var typeArguments = _invocation.typeArguments;
    if ((typeArguments != null) && (typeArguments.length > 0)) {
      typeArgumentsBuf = new StringBuffer();
      typeArgumentsBuf.write("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i > 0) {
          typeArgumentsBuf.write(", ");
        }
        typeArgumentsBuf.write(Error.safeToString(typeArguments[i]));
      }
      typeArgumentsBuf.write(">");
    }
    StringBuffer argumentsBuf = new StringBuffer();
    var positionalArguments = _invocation.positionalArguments;
    int argumentCount = 0;
    if (positionalArguments != null) {
      for (; argumentCount < positionalArguments.length; argumentCount++) {
        if (argumentCount > 0) {
          argumentsBuf.write(", ");
        }
        argumentsBuf
            .write(Error.safeToString(positionalArguments[argumentCount]));
      }
    }
    var namedArguments = _invocation.namedArguments;
    if (namedArguments != null) {
      namedArguments.forEach((Symbol key, var value) {
        if (argumentCount > 0) {
          argumentsBuf.write(", ");
        }
        argumentsBuf.write(internal.Symbol.computeUnmangledName(key));
        argumentsBuf.write(": ");
        argumentsBuf.write(Error.safeToString(value));
        argumentCount++;
      });
    }
    String existingSig =
        _existingMethodSignature(_receiver, memberName, _invocation._type);
    String argsMsg = existingSig != null ? " with matching arguments" : "";

    String kindBuf;
    if (kind >= 0 && kind < 5) {
      kindBuf = (const [
        "method",
        "getter",
        "setter",
        "getter or setter",
        "variable"
      ])[kind];
    }

    StringBuffer msgBuf = new StringBuffer("NoSuchMethodError: ");
    bool is_type_call = false;
    switch (level) {
      case _InvocationMirror._DYNAMIC:
        {
          if (_receiver == null) {
            if (existingSig != null) {
              msgBuf.writeln("The null object does not have a $kindBuf "
                  "'$memberName'$argsMsg.");
            } else {
              msgBuf.writeln("The $kindBuf '$memberName' was called on null.");
            }
          } else {
            if (_receiver is _Closure) {
              msgBuf.writeln("Closure call with mismatched arguments: "
                  "function '$memberName'");
            } else if (_receiver is _Type && memberName == "call") {
              is_type_call = true;
              String name = _receiver.toString();
              msgBuf.writeln("Attempted to use type '$name' as a function. "
                  "Since types do not define a method 'call', this is not "
                  "possible. Did you intend to call the $name constructor and "
                  "forget the 'new' operator?");
            } else {
              msgBuf.writeln("Class '${_receiver.runtimeType}' has no instance "
                  "$kindBuf '$memberName'$argsMsg.");
            }
          }
          break;
        }
      case _InvocationMirror._SUPER:
        {
          msgBuf.writeln("Super class of class '${_receiver.runtimeType}' has "
              "no instance $kindBuf '$memberName'$argsMsg.");
          memberName = "super.$memberName";
          break;
        }
      case _InvocationMirror._STATIC:
        {
          msgBuf.writeln("No static $kindBuf '$memberName'$argsMsg "
              "declared in class '$_receiver'.");
          break;
        }
      case _InvocationMirror._CONSTRUCTOR:
        {
          msgBuf.writeln("No constructor '$memberName'$argsMsg declared "
              "in class '$_receiver'.");
          memberName = "new $memberName";
          break;
        }
      case _InvocationMirror._TOP_LEVEL:
        {
          msgBuf.writeln("No top-level $kindBuf '$memberName'$argsMsg "
              "declared.");
          break;
        }
    }

    if (level == _InvocationMirror._TOP_LEVEL) {
      msgBuf.writeln("Receiver: top-level");
    } else {
      msgBuf.writeln("Receiver: ${Error.safeToString(_receiver)}");
    }

    if (kind == _InvocationMirror._METHOD) {
      String m = is_type_call ? "$_receiver" : "$memberName";
      msgBuf.write("Tried calling: $m");
      if (typeArgumentsBuf != null) {
        msgBuf.write(typeArgumentsBuf);
      }
      msgBuf.write("($argumentsBuf)");
    } else if (argumentCount == 0) {
      msgBuf.write("Tried calling: $memberName");
    } else if (kind == _InvocationMirror._SETTER) {
      msgBuf.write("Tried calling: $memberName$argumentsBuf");
    } else {
      msgBuf.write("Tried calling: $memberName = $argumentsBuf");
    }

    if (existingSig != null) {
      msgBuf.write("\nFound: $memberName$existingSig");
    }

    return msgBuf.toString();
  }

  // TODO(regis): Remove this function once dart2js is updated.
  String _toStringDeprecated() {
    var level = (_invocation_type >> _InvocationMirror._LEVEL_SHIFT) &
        _InvocationMirror._LEVEL_MASK;
    var type = _invocation_type & _InvocationMirror._KIND_MASK;
    String memberName = (_memberName == null)
        ? ""
        : internal.Symbol.computeUnmangledName(_memberName);

    if (type == _InvocationMirror._LOCAL_VAR) {
      return "NoSuchMethodError: Cannot assign to final variable '$memberName'";
    }

    StringBuffer arguments = new StringBuffer();
    int argumentCount = 0;
    if (_arguments != null) {
      for (; argumentCount < _arguments.length; argumentCount++) {
        if (argumentCount > 0) {
          arguments.write(", ");
        }
        arguments.write(Error.safeToString(_arguments[argumentCount]));
      }
    }
    if (_namedArguments != null) {
      _namedArguments.forEach((Symbol key, var value) {
        if (argumentCount > 0) {
          arguments.write(", ");
        }
        arguments.write(internal.Symbol.computeUnmangledName(key));
        arguments.write(": ");
        arguments.write(Error.safeToString(value));
        argumentCount++;
      });
    }
    bool args_mismatch = _existingArgumentNames != null;
    String args_message = args_mismatch ? " with matching arguments" : "";

    String type_str;
    if (type >= 0 && type < 5) {
      type_str = (const [
        "method",
        "getter",
        "setter",
        "getter or setter",
        "variable"
      ])[type];
    }

    StringBuffer msg_buf = new StringBuffer("NoSuchMethodError: ");
    bool is_type_call = false;
    switch (level) {
      case _InvocationMirror._DYNAMIC:
        {
          if (_receiver == null) {
            if (args_mismatch) {
              msg_buf.writeln("The null object does not have a $type_str "
                  "'$memberName'$args_message.");
            } else {
              msg_buf
                  .writeln("The $type_str '$memberName' was called on null.");
            }
          } else {
            if (_receiver is _Closure) {
              msg_buf.writeln("Closure call with mismatched arguments: "
                  "function '$memberName'");
            } else if (_receiver is _Type && memberName == "call") {
              is_type_call = true;
              String name = _receiver.toString();
              msg_buf.writeln("Attempted to use type '$name' as a function. "
                  "Since types do not define a method 'call', this is not "
                  "possible. Did you intend to call the $name constructor and "
                  "forget the 'new' operator?");
            } else {
              msg_buf
                  .writeln("Class '${_receiver.runtimeType}' has no instance "
                      "$type_str '$memberName'$args_message.");
            }
          }
          break;
        }
      case _InvocationMirror._SUPER:
        {
          msg_buf.writeln("Super class of class '${_receiver.runtimeType}' has "
              "no instance $type_str '$memberName'$args_message.");
          memberName = "super.$memberName";
          break;
        }
      case _InvocationMirror._STATIC:
        {
          msg_buf.writeln("No static $type_str '$memberName'$args_message "
              "declared in class '$_receiver'.");
          break;
        }
      case _InvocationMirror._CONSTRUCTOR:
        {
          msg_buf.writeln("No constructor '$memberName'$args_message declared "
              "in class '$_receiver'.");
          memberName = "new $memberName";
          break;
        }
      case _InvocationMirror._TOP_LEVEL:
        {
          msg_buf.writeln("No top-level $type_str '$memberName'$args_message "
              "declared.");
          break;
        }
    }

    if (level == _InvocationMirror._TOP_LEVEL) {
      msg_buf.writeln("Receiver: top-level");
    } else {
      msg_buf.writeln("Receiver: ${Error.safeToString(_receiver)}");
    }

    if (type == _InvocationMirror._METHOD) {
      String m = is_type_call ? "$_receiver" : "$memberName";
      msg_buf.write("Tried calling: $m($arguments)");
    } else if (argumentCount == 0) {
      msg_buf.write("Tried calling: $memberName");
    } else if (type == _InvocationMirror._SETTER) {
      msg_buf.write("Tried calling: $memberName$arguments");
    } else {
      msg_buf.write("Tried calling: $memberName = $arguments");
    }

    if (args_mismatch) {
      StringBuffer formalParameters = new StringBuffer();
      for (int i = 0; i < _existingArgumentNames.length; i++) {
        if (i > 0) {
          formalParameters.write(", ");
        }
        formalParameters.write(_existingArgumentNames[i]);
      }
      msg_buf.write("\nFound: $memberName($formalParameters)");
    }

    return msg_buf.toString();
  }
}

class _CompileTimeError extends Error {
  final String _errorMsg;
  _CompileTimeError(this._errorMsg);
  String toString() => _errorMsg;
}

dynamic _classRangeAssert(int position, dynamic instance, _Type type, int cid,
    int lowerLimit, int upperLimit) {
  if ((cid < lowerLimit || cid > upperLimit) && instance != null) {
    _TypeError._throwNew(position, instance, type, " in type cast", null);
  }

  return instance;
}

dynamic _classIdEqualsAssert(
    int position, dynamic instance, _Type type, int cid, int otherCid) {
  if (cid != otherCid && instance != null) {
    _TypeError._throwNew(position, instance, type, " in type cast", null);
  }

  return instance;
}

/// Used by Fasta to report a runtime error when a final field with an
/// initializer is also initialized in a generative constructor.
///
/// Note: in strong mode, this is a compile-time error and this class becomes
/// obsolete.
class _DuplicatedFieldInitializerError extends Error {
  final String _name;

  _DuplicatedFieldInitializerError(this._name);

  toString() => "Error: field '$_name' is already initialized.";
}

@patch
class _ConstantExpressionError {
  @patch
  _throw(error) => throw error;
}
