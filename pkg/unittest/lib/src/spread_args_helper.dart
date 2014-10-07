part of unittest;

const _PLACE_HOLDER = const _ArgPlaceHolder();

/// Used to track unused positional args.
class _ArgPlaceHolder {
  const _ArgPlaceHolder();
}

/// Simulates spread arguments using named arguments.
class _SpreadArgsHelper {
  final Function callback;
  final int minExpectedCalls;
  final int maxExpectedCalls;
  final Function isDone;
  final String id;
  final String reason;
  int actualCalls = 0;
  final TestCase testCase;
  bool complete;

  _SpreadArgsHelper(Function callback, int minExpected, int maxExpected,
      String id, String reason, {bool isDone()})
      : this.callback = callback,
        minExpectedCalls = minExpected,
        maxExpectedCalls = (maxExpected == 0 && minExpected > 0)
            ? minExpected
            : maxExpected,
        this.isDone = isDone,
        this.reason = reason == null ? '' : '\n$reason',
        this.testCase = currentTestCase,
        this.id = _makeCallbackId(id, callback) {
    ensureInitialized();
    if (testCase == null) {
      throw new StateError("No valid test. Did you forget to run your test "
          "inside a call to test()?");
    }

    if (isDone != null || minExpected > 0) {
      testCase._callbackFunctionsOutstanding++;
      complete = false;
    } else {
      complete = true;
    }
  }

  static String _makeCallbackId(String id, Function callback) {
    // Try to create a reasonable id.
    if (id != null) {
      return "$id ";
    } else {
      // If the callback is not an anonymous closure, try to get the
      // name.
      var fname = callback.toString();
      var prefix = "Function '";
      var pos = fname.indexOf(prefix);
      if (pos > 0) {
        pos += prefix.length;
        var epos = fname.indexOf("'", pos);
        if (epos > 0) {
          return "${fname.substring(pos, epos)} ";
        }
      }
    }
    return '';
  }

  bool shouldCallBack() {
    ++actualCalls;
    if (testCase.isComplete) {
      // Don't run if the test is done. We don't throw here as this is not
      // the current test, but we do mark the old test as having an error
      // if it previously passed.
      if (testCase.result == PASS) {
        testCase._error(
            'Callback ${id}called ($actualCalls) after test case '
            '${testCase.description} has already been marked as '
            '${testCase.result}.$reason');
      }
      return false;
    } else if (maxExpectedCalls >= 0 && actualCalls > maxExpectedCalls) {
      throw new TestFailure('Callback ${id}called more times than expected '
                            '($maxExpectedCalls).$reason');
    }
    return true;
  }

  void after() {
    if (!complete) {
      if (minExpectedCalls > 0 && actualCalls < minExpectedCalls) return;
      if (isDone != null && !isDone()) return;

      // Mark this callback as complete and remove it from the testcase
      // oustanding callback count; if that hits zero the testcase is done.
      complete = true;
      testCase._markCallbackComplete();
    }
  }

  /// Returns a function that has as many required + positional arguments as
  /// [callback] (up to a total of 6).
  ///
  /// Optional positional arguments are supported by using const place-holders
  Function get func {
    if (callback is _Func6) return _max6;
    if (callback is _Func5) return _max5;
    if (callback is _Func4) return _max4;
    if (callback is _Func3) return _max3;
    if (callback is _Func2) return _max2;
    if (callback is _Func1) return _max1;
    if (callback is _Func0) return _max0;

    throw new ArgumentError(
        'The callback argument has more than 6 required arguments');
  }

  /// This indirection is critical. It ensures the returned function has an
  /// argument count of zero.
  _max0() => _max6();

  _max1([a0 = _PLACE_HOLDER]) => _max6(a0);

  _max2([a0 = _PLACE_HOLDER, a1 = _PLACE_HOLDER]) => _max6(a0, a1);

  _max3([a0 = _PLACE_HOLDER, a1 = _PLACE_HOLDER, a2 = _PLACE_HOLDER]) =>
      _max6(a0, a1, a2);

  _max4([a0 = _PLACE_HOLDER, a1 = _PLACE_HOLDER, a2 = _PLACE_HOLDER,
      a3 = _PLACE_HOLDER]) => _max6(a0, a1, a2, a3);

  _max5([a0 = _PLACE_HOLDER, a1 = _PLACE_HOLDER, a2 = _PLACE_HOLDER,
      a3 = _PLACE_HOLDER, a4 = _PLACE_HOLDER]) => _max6(a0, a1, a2, a3, a4);

  _max6([a0 = _PLACE_HOLDER, a1 = _PLACE_HOLDER, a2 = _PLACE_HOLDER,
      a3 = _PLACE_HOLDER, a4 = _PLACE_HOLDER, a5 = _PLACE_HOLDER]) {
    var args = [a0, a1, a2, a3, a4, a5];
    args.removeWhere((a) => a == _PLACE_HOLDER);

    return _guardAsync(
        () {
          if (shouldCallBack()) {
            return Function.apply(callback, args);
          }
        },
        after, testCase);
  }

  _guardAsync(Function tryBody, Function finallyBody, TestCase testCase) {
    assert(testCase != null);
    try {
      return tryBody();
    } catch (e, trace) {
      _registerException(testCase, e, trace);
    } finally {
      if (finallyBody != null) finallyBody();
    }
  }
}

typedef _Func0();
typedef _Func1(a);
typedef _Func2(a, b);
typedef _Func3(a, b, c);
typedef _Func4(a, b, c, d);
typedef _Func5(a, b, c, d, e);
typedef _Func6(a, b, c, d, e, f);
