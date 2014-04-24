library typed_mock;

import 'dart:collection' show Queue;

Behavior _lastBehavior;


/// Enables stubbing methods.
/// Use it when you want the mock to return particular value when particular
/// method is called.
Behavior when(_ignored) {
  try {
    return _lastBehavior;
  } finally {
    // clear to prevent memory leak
    _lastBehavior = null;
  }
}


class Behavior {
  final Symbol _member;

  bool _thenFunctionEnabled = false;
  Function _thenFunction;

  bool _returnAlwaysEnabled = false;
  var _returnAlways;

  bool _throwExceptionEnabled = false;
  var _throwException;

  Behavior(this._member);

  Behavior thenInvoke(Function function) {
    _reset();
    _thenFunctionEnabled = true;
    _thenFunction = function;
    return this;
  }

  Behavior thenReturn(value) {
    _reset();
    _returnAlwaysEnabled = true;
    _returnAlways = value;
    return this;
  }

  Behavior thenThrow(exception) {
    _reset();
    _throwExceptionEnabled = true;
    _throwException = exception;
    return this;
  }

  _reset() {
    _thenFunctionEnabled = false;
    _returnAlwaysEnabled = false;
    _throwExceptionEnabled = false;
  }

  dynamic getReturnValue(Invocation invocation) {
    // function
    if (_thenFunctionEnabled) {
      return Function.apply(_thenFunction, invocation.positionalArguments,
          invocation.namedArguments);
    }
    // always
    if (_returnAlwaysEnabled) {
      return _returnAlways;
    }
    // exception
    if (_throwExceptionEnabled) {
      throw _throwException;
    }
    // no value
    return null;
  }
}


class TypedMock {
  final Map<Symbol, Behavior> _behaviors = {};

  noSuchMethod(Invocation invocation) {
    var member = invocation.memberName;
    Behavior behavior = _behaviors[member];
    if (behavior == null) {
      behavior = new Behavior(member);
      _behaviors[member] = behavior;
    }
    _lastBehavior = behavior;
    return behavior.getReturnValue(invocation);
  }
}
