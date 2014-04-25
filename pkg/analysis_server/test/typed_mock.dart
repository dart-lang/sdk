library typed_mock;


_InvocationMatcher _lastMatcher;


/// Enables stubbing methods.
/// Use it when you want the mock to return particular value when particular
/// method is called.
Behavior when(_ignored) {
  try {
    var behavior = new Behavior();
    _lastMatcher._behavior = behavior;
    return behavior;
  } finally {
    // clear to prevent memory leak
    _lastMatcher = null;
  }
}


class _InvocationMatcher {
  List<ArgumentMatcher> _matchers = [];

  Behavior _behavior;

  _InvocationMatcher(Invocation invocation) {
    invocation.positionalArguments.forEach((argument) {
      ArgumentMatcher matcher;
      if (argument is ArgumentMatcher) {
        matcher = argument;
      } else {
        matcher = equals(argument);
      }
      _matchers.add(matcher);
    });
  }

  bool match(Invocation invocation) {
    var arguments = invocation.positionalArguments;
    if (arguments.length != _matchers.length) {
      return false;
    }
    for (int i = 0; i < _matchers.length; i++) {
      var matcher = _matchers[i];
      var argument = arguments[i];
      if (!matcher.match(argument)) {
        return false;
      }
    }
    return true;
  }
}

class Behavior {
  bool _thenFunctionEnabled = false;
  Function _thenFunction;

  bool _returnAlwaysEnabled = false;
  var _returnAlways;

  bool _returnListEnabled = false;
  List _returnList;
  int _returnListIndex;

  bool _throwExceptionEnabled = false;
  var _throwException;

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

  Behavior thenReturnList(List list) {
    _reset();
    _returnListEnabled = true;
    _returnList = list;
    _returnListIndex = 0;
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
    _returnListEnabled = false;
    _throwExceptionEnabled = false;
  }

  dynamic _getReturnValue(Invocation invocation) {
    // function
    if (_thenFunctionEnabled) {
      return Function.apply(_thenFunction, invocation.positionalArguments,
          invocation.namedArguments);
    }
    // always
    if (_returnAlwaysEnabled) {
      return _returnAlways;
    }
    // list
    if (_returnListEnabled) {
      if (_returnListIndex >= _returnList.length) {
        throw new StateError('List of ${_returnList.length} elements'
          ' $_returnList has been exhausted.');
      }
      return _returnList[_returnListIndex++];
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
  final Map<Symbol, List<_InvocationMatcher>> _invocationMatchersMap = {};

  noSuchMethod(Invocation invocation) {
    var member = invocation.memberName;
    // prepare invocation matchers
    var matchers = _invocationMatchersMap[member];
    if (matchers == null) {
      matchers = [];
      _invocationMatchersMap[member] = matchers;
    }
    // check if there is a matcher
    for (var matcher in matchers) {
      if (matcher.match(invocation)) {
        _lastMatcher = matcher;
        return matcher._behavior._getReturnValue(invocation);
      }
    }
    // add a new matcher
    _InvocationMatcher matcher = new _InvocationMatcher(invocation);
    matchers.add(matcher);
    _lastMatcher = matcher;
  }
}


abstract class ArgumentMatcher {
  bool match(val);
}


class _ArgumentMatcher_equals extends ArgumentMatcher {
  final expected;

  _ArgumentMatcher_equals(this.expected);

  @override
  bool match(val) {
    return val == expected;
  }
}

equals(expected) {
  return new _ArgumentMatcher_equals(expected);
}


class _ArgumentMatcher_anyBool extends ArgumentMatcher {
  @override
  bool match(val) {
    return val is bool;
  }
}

final anyBool = new _ArgumentMatcher_anyBool();


class _ArgumentMatcher_anyInt extends ArgumentMatcher {
  @override
  bool match(val) {
    return val is int;
  }
}

final anyInt = new _ArgumentMatcher_anyInt();


class _ArgumentMatcher_anyObject extends ArgumentMatcher {
  @override
  bool match(val) {
    return true;
  }
}

final anyObject = new _ArgumentMatcher_anyObject();


class _ArgumentMatcher_anyString extends ArgumentMatcher {
  @override
  bool match(val) {
    return val is String;
  }
}

final anyString = new _ArgumentMatcher_anyString();
