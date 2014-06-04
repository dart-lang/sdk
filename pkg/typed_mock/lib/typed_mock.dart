library typed_mock;


_InvocationMatcher _lastMatcher;

/// Enables stubbing methods.
///
/// Use it when you want the mock to return a particular value when a particular
/// method, getter or setter is called.
///
///     when(obj.testProperty).thenReturn(10);
///     expect(obj.testProperty, 10); // pass
///
/// You can specify multiple matchers, which are checked one after another.
///
///     when(obj.testMethod(anyInt)).thenReturn('was int');
///     when(obj.testMethod(anyString)).thenReturn('was String');
///     expect(obj.testMethod(42), 'was int'); // pass
///     expect(obj.testMethod('foo'), 'was String'); // pass
///
/// You can even provide a function to calculate results.
/// Function can be also used to capture invocation arguments (if you test some
/// consumer).
///
///     when(obj.testMethod(anyInt)).thenInvoke((int p) => 10 + p);
///     expect(obj.testMethod(1), 11); // pass
///     expect(obj.testMethod(5), 15); // pass
Behavior when(_ignored) {
  try {
    var mock = _lastMatcher._mock;
    mock._removeLastInvocation();
    // set behavior
    var behavior = new Behavior._(_lastMatcher);
    _lastMatcher._behavior = behavior;
    return behavior;
  } finally {
    // clear to prevent memory leak
    _lastMatcher = null;
  }
}

/// Verifies certain behavior happened a specified number of times.
Verifier verify(_ignored) {
  try {
    var mock = _lastMatcher._mock;
    mock._removeLastInvocation();
    // set verifier
    return new Verifier._(mock, _lastMatcher);
  } finally {
    // clear to prevent memory leak
    _lastMatcher = null;
  }
}


/// Verifies that the given mock doesn't have any unverified interaction.
void verifyNoMoreInteractions(TypedMock mock) {
  var notVerified = mock._computeNotVerifiedInvocations();
  // OK
  if (notVerified.isEmpty) {
    return;
  }
  // fail
  var invocationsString = _getInvocationsString(notVerified);
  throw new VerifyError('Unexpected interactions:\n$invocationsString');
}


/// Verifies that no interactions happened on the given mock.
void verifyZeroInteractions(TypedMock mock) {
  var invocations = mock._invocations;
  // OK
  if (invocations.isEmpty) {
    return;
  }
  // fail
  var invocationsString = _getInvocationsString(invocations);
  throw new VerifyError('Unexpected interactions:\n$invocationsString');
}


/// [VerifyError] is thrown when one of the [verify] checks fails.
class VerifyError {
  final String message;
  VerifyError(this.message);
  String toString() => 'VerifyError: $message';
}


String _getInvocationsString(Iterable<Invocation> invocations) {
  var buffer = new StringBuffer();
  invocations.forEach((invocation) {
    var member = invocation.memberName;
    buffer.write(member);
    buffer.write(' ');
    buffer.write(invocation.positionalArguments);
    buffer.write(' ');
    buffer.write(invocation.namedArguments);
    buffer.writeln();
  });
  return buffer.toString();
}


class _InvocationMatcher {
  final Symbol _member;
  final TypedMock _mock;
  final List<ArgumentMatcher> _matchers = [];

  Behavior _behavior;

  _InvocationMatcher(this._mock, this._member, Invocation invocation) {
    invocation.positionalArguments.forEach((argument) {
      ArgumentMatcher matcher;
      if (argument is ArgumentMatcher) {
        matcher = argument;
      } else {
        matcher = new _ArgumentMatcher_equals(argument);
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
      if (!matcher.matches(argument)) {
        return false;
      }
    }
    return true;
  }
}


class Behavior {
  final _InvocationMatcher _matcher;

  Behavior._(this._matcher);

  bool _thenFunctionEnabled = false;
  Function _thenFunction;

  bool _returnAlwaysEnabled = false;
  var _returnAlways;

  bool _returnListEnabled = false;
  List _returnList;
  int _returnListIndex;

  bool _throwExceptionEnabled = false;
  var _throwException;

  /// Invokes the given [function] with actual arguments and returns its result.
  Behavior thenInvoke(Function function) {
    _reset();
    _thenFunctionEnabled = true;
    _thenFunction = function;
    return this;
  }

  /// Returns the specific value.
  Behavior thenReturn(value) {
    _reset();
    _returnAlwaysEnabled = true;
    _returnAlways = value;
    return this;
  }

  /// Returns values from the [list] starting from first to the last.
  /// If the end of list is reached a [StateError] is thrown.
  Behavior thenReturnList(List list) {
    _reset();
    _returnListEnabled = true;
    _returnList = list;
    _returnListIndex = 0;
    return this;
  }

  /// Throws the specified [exception] object.
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
        throw new StateError('All ${_returnList.length} elements for '
            '${_matcher._member} from $_returnList have been exhausted.');
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


class Verifier {
  final TypedMock _mock;
  final _InvocationMatcher _matcher;

  Verifier._(this._mock, this._matcher);

  /// Marks matching interactions as verified and never fails.
  void any() {
    // mark as verified, but don't check the actual count
    _count();
  }

  /// Verifies that there was no matching interactions.
  void never() {
    times(0);
  }

  /// Verifies that there was excatly one martching interaction.
  void once() {
    times(1);
  }

  /// Verifies that there was the specified number of matching interactions.
  void times(int expected) {
    var times = _count();
    if (times != expected) {
      var member = _matcher._member;
      throw new VerifyError('$expected expected, but $times'
          ' invocations of $member recorded.');
    }
  }

  /// Verifies that there was at least the specified number of matching
  /// interactions.
  void atLeast(int expected) {
    var times = _count();
    if (times < expected) {
      var member = _matcher._member;
      throw new VerifyError('At least $expected expected, but only $times'
          ' invocations of $member recorded.');
    }
  }

  /// Verifies that there was at least one matching interaction.
  void atLeastOnce() {
    var times = _count();
    if (times == 0) {
      var member = _matcher._member;
      throw new VerifyError('At least one expected, but only zero'
          ' invocations of $member recorded.');
    }
  }

  /// Verifies that there was at most the specified number of matching
  /// interactions.
  void atMost(int expected) {
    var times = _count();
    if (times > expected) {
      var member = _matcher._member;
      throw new VerifyError('At most $expected expected, but $times'
          ' invocations of $member recorded.');
    }
  }

  int _count() {
    var times = 0;
    _mock._invocations.forEach((invocation) {
      if (invocation.memberName != _matcher._member) {
        return;
      }
      if (!_matcher.match(invocation)) {
        return;
      }
      _mock._verifiedInvocations.add(invocation);
      times++;
    });
    return times;
  }
}


/// A class to extend mocks from.
/// It supports specifying behavior using [when] and validation of interactions
/// using [verify].
///
///     abstract class Name {
///       String get firstName;
///       String get lastName;
///     }
///     class NameMock extends TypedMock implements Name {
///       noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
///     }
class TypedMock {
  final Map<Symbol, List<_InvocationMatcher>> _matchersMap = {};

  final List<Invocation> _invocations = [];
  final Set<Invocation> _verifiedInvocations = new Set<Invocation>();

  noSuchMethod(Invocation invocation) {
    _invocations.add(invocation);
    var member = invocation.memberName;
    // prepare invocation matchers
    var matchers = _matchersMap[member];
    if (matchers == null) {
      matchers = [];
      _matchersMap[member] = matchers;
    }
    // check if there is a matcher
    for (var matcher in matchers) {
      if (matcher.match(invocation)) {
        _lastMatcher = matcher;
        // generate value if there is a behavior
        if (matcher._behavior != null) {
          return matcher._behavior._getReturnValue(invocation);
        }
        // probably verification
        return null;
      }
    }
    // add a new matcher
    var matcher = new _InvocationMatcher(this, member, invocation);
    matchers.add(matcher);
    _lastMatcher = matcher;
  }

  Iterable<Invocation> _computeNotVerifiedInvocations() {
    notVerified(e) => !_verifiedInvocations.contains(e);
    return _invocations.where(notVerified);
  }

  void _removeLastInvocation() {
    _invocations.removeLast();
  }
}


/// [ArgumentMatcher] checks whether the given argument satisfies some
/// condition.
abstract class ArgumentMatcher {
  const ArgumentMatcher();

  /// Checks whether this matcher accepts the given argument.
  bool matches(val);
}


class _ArgumentMatcher_equals extends ArgumentMatcher {
  final expected;

  const _ArgumentMatcher_equals(this.expected);

  @override
  bool matches(val) {
    return val == expected;
  }
}


class _ArgumentMatcher_anyBool extends ArgumentMatcher {
  const _ArgumentMatcher_anyBool();

  @override
  bool matches(val) {
    return val is bool;
  }
}

/// Matches any [bool] value.
final anyBool = const _ArgumentMatcher_anyBool() as dynamic;


class _ArgumentMatcher_anyInt extends ArgumentMatcher {
  const _ArgumentMatcher_anyInt();

  @override
  bool matches(val) {
    return val is int;
  }
}

/// Matches any [int] value.
final anyInt = const _ArgumentMatcher_anyInt() as dynamic;


class _ArgumentMatcher_anyObject extends ArgumentMatcher {
  const _ArgumentMatcher_anyObject();

  @override
  bool matches(val) {
    return true;
  }
}

/// Matches any [Object] (or subclass) value.
final anyObject = const _ArgumentMatcher_anyObject() as dynamic;


class _ArgumentMatcher_anyString extends ArgumentMatcher {
  const _ArgumentMatcher_anyString();

  @override
  bool matches(val) {
    return val is String;
  }
}

/// Matches any [String] value.
final anyString = const _ArgumentMatcher_anyString() as dynamic;
