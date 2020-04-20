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
    return json.encode(string);
  }

  @patch
  StackTrace? get stackTrace => _stackTrace;

  @pragma("vm:entry-point")
  StackTrace? _stackTrace;
}

class _AssertionError extends Error implements AssertionError {
  @pragma("vm:entry-point")
  _AssertionError._create(
      this._failedAssertion, this._url, this._line, this._column, this.message);

  // AssertionError_throwNew in errors.cc fishes the assertion source code
  // out of the script. It expects a Dart stack frame from class
  // _AssertionError. Thus we need a Dart stub that calls the native code.
  @pragma("vm:entry-point", "call")
  static _throwNew(int assertionStart, int assertionEnd, Object? message) {
    _doThrowNew(assertionStart, assertionEnd, message);
  }

  static _doThrowNew(int assertionStart, int assertionEnd, Object? message)
      native "AssertionError_throwNew";

  @pragma("vm:entry-point", "call")
  static _evaluateAssertion(condition) {
    if (identical(condition, true) || identical(condition, false)) {
      return condition;
    }
    if (condition is _Closure) {
      return (condition as dynamic)();
    }
    if (condition is Function) {
      condition = condition();
    }
    return condition;
  }

  String get _messageString {
    final msg = message;
    if (msg == null) return "is not true.";
    if (msg is String) return msg;
    return Error.safeToString(msg);
  }

  String toString() {
    if (_url == null) {
      if (message == null) return _failedAssertion.trim();
      return "'${_failedAssertion.trim()}': $_messageString";
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
  final Object? message;
}

class _TypeError extends Error implements TypeError, CastError {
  @pragma("vm:entry-point")
  _TypeError._create(this._url, this._line, this._column, this._message);

  @pragma("vm:entry-point", "call")
  static _throwNew(int location, Object srcValue, _Type dstType, String dstName)
      native "TypeError_throwNew";

  String toString() => _message;

  final String _url;
  final int _line;
  final int _column;
  final String _message;
}

class _CastError extends Error implements CastError, TypeError {
  @pragma("vm:entry-point")
  _CastError._create(this._url, this._line, this._column, this._errorMsg);

  // A CastError is allocated by TypeError._throwNew() when dstName equals
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
  @pragma("vm:entry-point")
  FallThroughError._create(this._url, this._line);

  static _throwNew(int caseClausePos) native "FallThroughError_throwNew";

  @patch
  String toString() {
    return "'$_url': Switch case fall-through at line $_line.";
  }

  // These new fields cannot be declared final, because a constructor exists
  // in the original version of this patched class.
  String? _url;
  int _line = 0;
}

class _InternalError {
  @pragma("vm:entry-point")
  const _InternalError(this._msg);
  String toString() => "InternalError: '${_msg}'";
  final String _msg;
}

@patch
@pragma("vm:entry-point")
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
  @pragma("vm:entry-point")
  AbstractClassInstantiationError._create(
      this._className, this._url, this._line);

  static _throwNew(int caseClausePos, String className)
      native "AbstractClassInstantiationError_throwNew";

  @patch
  String toString() {
    return "Cannot instantiate abstract class $_className: "
        "_url '$_url' line $_line";
  }

  // These new fields cannot be declared final, because a constructor exists
  // in the original version of this patched class.
  String? _url;
  int _line = 0;
}

@patch
class NoSuchMethodError {
  // Deprecated members to be removed.
  Symbol? _memberName;
  List? _arguments;
  Map<Symbol, dynamic>? _namedArguments;
  List? _existingArgumentNames;

  final Object _receiver;
  final _InvocationMirror? _invocation;

  // Issue(dartbug.com/127160): Remove the cast to [_InvocationMirror].
  @patch
  NoSuchMethodError.withInvocation(Object receiver, Invocation invocation)
      : _receiver = receiver,
        _invocation = invocation as _InvocationMirror;

  static void _throwNewInvocation(Object receiver, Invocation invocation) {
    throw new NoSuchMethodError.withInvocation(receiver, invocation);
  }

  // The compiler emits a call to _throwNew when it cannot resolve a static
  // method at compile time. The receiver is actually the literal class of the
  // unresolved method.
  @pragma("vm:entry-point", "call")
  static void _throwNew(Object receiver, String memberName, int invocationType,
      Object? typeArguments, List? arguments, List? argumentNames) {
    throw new NoSuchMethodError._withType(receiver, memberName, invocationType,
        typeArguments, arguments, argumentNames);
  }

  static void _throwNewIfNotLoaded(
      _LibraryPrefix prefix,
      Object receiver,
      String memberName,
      int invocationType,
      Object typeArguments,
      List arguments,
      List argumentNames) {
    if (!prefix.isLoaded()) {
      _throwNew(receiver, memberName, invocationType, typeArguments, arguments,
          argumentNames);
    }
  }

  // TODO(regis): Deprecated member still used by dart2js to be removed.
  // Remember the type from the invocation mirror or static compilation
  // analysis when thrown directly with _throwNew. A negative value means
  // that no information is available.
  int _invocationType = -1;

  // TODO(regis): Deprecated constructor still used by dart2js to be removed.
  @patch
  NoSuchMethodError(Object receiver, Symbol memberName,
      List positionalArguments, Map<Symbol, dynamic> namedArguments,
      [List? existingArgumentNames = null])
      : _receiver = receiver,
        _invocation = null,
        _memberName = memberName,
        _arguments = positionalArguments,
        _namedArguments = namedArguments,
        _existingArgumentNames = existingArgumentNames,
        _invocationType = -1;

  // Helper to build a map of named arguments.
  static Map<Symbol, dynamic> _NamedArgumentsMap(
      List arguments, List argumentNames) {
    Map<Symbol, dynamic> namedArguments = new Map<Symbol, dynamic>();
    int numPositionalArguments = arguments.length - argumentNames.length;
    for (int i = 0; i < argumentNames.length; i++) {
      final argValue = arguments[numPositionalArguments + i];
      namedArguments[new Symbol(argumentNames[i])] = argValue;
    }
    return namedArguments;
  }

  // Constructor called from Exceptions::ThrowByType(kNoSuchMethod) and from
  // _throwNew above, taking a TypeArguments object rather than an unpacked list
  // of types, as well as a list of all arguments and a list of names, rather
  // than a separate list of positional arguments and a map of named arguments.
  @pragma("vm:entry-point")
  NoSuchMethodError._withType(
      this._receiver,
      String memberName,
      int invocationType,
      Object? typeArguments,
      List? arguments,
      List? argumentNames)
      : this._invocation = new _InvocationMirror._withType(
            new Symbol(memberName),
            invocationType,
            typeArguments != null
                // TODO(33073): Use actual count of type arguments in place of 0.
                ? _InvocationMirror._unpackTypeArguments(typeArguments, 0)
                : null,
            argumentNames != null
                ? arguments!.sublist(0, arguments.length - argumentNames.length)
                : arguments,
            argumentNames != null
                ? _NamedArgumentsMap(arguments!, argumentNames)
                : null);

  static String? _existingMethodSignature(Object receiver, String methodName,
      int invocationType) native "NoSuchMethodError_existingMethodSignature";

  @patch
  String toString() {
    // TODO(regis): Remove this null check once dart2js is updated.
    final localInvocation = _invocation;
    if (localInvocation == null) {
      // Use deprecated version of toString.
      return _toStringDeprecated();
    }
    var internalName = localInvocation.memberName as internal.Symbol;
    String memberName = internal.Symbol.computeUnmangledName(internalName);

    var level = (localInvocation._type >> _InvocationMirror._LEVEL_SHIFT) &
        _InvocationMirror._LEVEL_MASK;
    var kind = localInvocation._type & _InvocationMirror._KIND_MASK;
    if (kind == _InvocationMirror._LOCAL_VAR) {
      return "NoSuchMethodError: Cannot assign to final variable '$memberName'";
    }

    StringBuffer? typeArgumentsBuf = null;
    final typeArguments = localInvocation.typeArguments;
    if ((typeArguments != null) && (typeArguments.length > 0)) {
      final argsBuf = new StringBuffer();
      argsBuf.write("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i > 0) {
          argsBuf.write(", ");
        }
        argsBuf.write(Error.safeToString(typeArguments[i]));
      }
      argsBuf.write(">");
      typeArgumentsBuf = argsBuf;
    }
    StringBuffer argumentsBuf = new StringBuffer();
    var positionalArguments = localInvocation.positionalArguments;
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
    var namedArguments = localInvocation.namedArguments;
    if (namedArguments != null) {
      namedArguments.forEach((Symbol key, var value) {
        if (argumentCount > 0) {
          argumentsBuf.write(", ");
        }
        var internalName = key as internal.Symbol;
        argumentsBuf.write(internal.Symbol.computeUnmangledName(internalName));
        argumentsBuf.write(": ");
        argumentsBuf.write(Error.safeToString(value));
        argumentCount++;
      });
    }
    String? existingSig =
        _existingMethodSignature(_receiver, memberName, localInvocation._type);
    String argsMsg = existingSig != null ? " with matching arguments" : "";

    assert(kind >= 0 && kind < 5);
    final String kindBuf = (const [
      "method",
      "getter",
      "setter",
      "getter or setter",
      "variable"
    ])[kind];

    StringBuffer msgBuf = new StringBuffer("NoSuchMethodError: ");
    bool isTypeCall = false;
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
              isTypeCall = true;
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
      String m = isTypeCall ? "$_receiver" : "$memberName";
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
    var level = (_invocationType >> _InvocationMirror._LEVEL_SHIFT) &
        _InvocationMirror._LEVEL_MASK;
    var type = _invocationType & _InvocationMirror._KIND_MASK;
    String memberName = (_memberName == null)
        ? ""
        : internal.Symbol.computeUnmangledName(_memberName as internal.Symbol);

    if (type == _InvocationMirror._LOCAL_VAR) {
      return "NoSuchMethodError: Cannot assign to final variable '$memberName'";
    }

    StringBuffer arguments = new StringBuffer();
    int argumentCount = 0;
    final args = _arguments;
    if (args != null) {
      for (; argumentCount < args.length; argumentCount++) {
        if (argumentCount > 0) {
          arguments.write(", ");
        }
        arguments.write(Error.safeToString(args[argumentCount]));
      }
    }
    _namedArguments?.forEach((Symbol key, var value) {
      if (argumentCount > 0) {
        arguments.write(", ");
      }
      var internalName = key as internal.Symbol;
      arguments.write(internal.Symbol.computeUnmangledName(internalName));
      arguments.write(": ");
      arguments.write(Error.safeToString(value));
      argumentCount++;
    });
    bool argsMismatch = _existingArgumentNames != null;
    String argsMessage = argsMismatch ? " with matching arguments" : "";

    final String typeStr = (type >= 0 && type < 5)
        ? (const [
            "method",
            "getter",
            "setter",
            "getter or setter",
            "variable"
          ])[type]
        : "";

    StringBuffer msgBuf = new StringBuffer("NoSuchMethodError: ");
    bool isTypeCall = false;
    switch (level) {
      case _InvocationMirror._DYNAMIC:
        {
          if (_receiver == null) {
            if (argsMismatch) {
              msgBuf.writeln("The null object does not have a $typeStr "
                  "'$memberName'$argsMessage.");
            } else {
              msgBuf.writeln("The $typeStr '$memberName' was called on null.");
            }
          } else {
            if (_receiver is _Closure) {
              msgBuf.writeln("Closure call with mismatched arguments: "
                  "function '$memberName'");
            } else if (_receiver is _Type && memberName == "call") {
              isTypeCall = true;
              String name = _receiver.toString();
              msgBuf.writeln("Attempted to use type '$name' as a function. "
                  "Since types do not define a method 'call', this is not "
                  "possible. Did you intend to call the $name constructor and "
                  "forget the 'new' operator?");
            } else {
              msgBuf.writeln("Class '${_receiver.runtimeType}' has no instance "
                  "$typeStr '$memberName'$argsMessage.");
            }
          }
          break;
        }
      case _InvocationMirror._SUPER:
        {
          msgBuf.writeln("Super class of class '${_receiver.runtimeType}' has "
              "no instance $typeStr '$memberName'$argsMessage.");
          memberName = "super.$memberName";
          break;
        }
      case _InvocationMirror._STATIC:
        {
          msgBuf.writeln("No static $typeStr '$memberName'$argsMessage "
              "declared in class '$_receiver'.");
          break;
        }
      case _InvocationMirror._CONSTRUCTOR:
        {
          msgBuf.writeln("No constructor '$memberName'$argsMessage declared "
              "in class '$_receiver'.");
          memberName = "new $memberName";
          break;
        }
      case _InvocationMirror._TOP_LEVEL:
        {
          msgBuf.writeln("No top-level $typeStr '$memberName'$argsMessage "
              "declared.");
          break;
        }
    }

    if (level == _InvocationMirror._TOP_LEVEL) {
      msgBuf.writeln("Receiver: top-level");
    } else {
      msgBuf.writeln("Receiver: ${Error.safeToString(_receiver)}");
    }

    if (type == _InvocationMirror._METHOD) {
      String m = isTypeCall ? "$_receiver" : "$memberName";
      msgBuf.write("Tried calling: $m($arguments)");
    } else if (argumentCount == 0) {
      msgBuf.write("Tried calling: $memberName");
    } else if (type == _InvocationMirror._SETTER) {
      msgBuf.write("Tried calling: $memberName$arguments");
    } else {
      msgBuf.write("Tried calling: $memberName = $arguments");
    }

    if (argsMismatch) {
      StringBuffer formalParameters = new StringBuffer();
      final argumentNames = _existingArgumentNames!;
      for (int i = 0; i < argumentNames.length; i++) {
        if (i > 0) {
          formalParameters.write(", ");
        }
        formalParameters.write(argumentNames[i]);
      }
      msgBuf.write("\nFound: $memberName($formalParameters)");
    }

    return msgBuf.toString();
  }
}

@pragma("vm:entry-point")
class _CompileTimeError extends Error {
  final String _errorMsg;
  _CompileTimeError(this._errorMsg);
  String toString() => _errorMsg;
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

class _LateInitializationError extends Error
    implements LateInitializationError {
  @pragma("vm:entry-point")
  _LateInitializationError(this._name);

  @pragma("vm:entry-point")
  static void _throwNew(String name) {
    throw _LateInitializationError(name);
  }

  String toString() => "LateInitializationError: $_name";

  final String _name;
}
