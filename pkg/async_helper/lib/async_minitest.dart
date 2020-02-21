// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A minimal, dependency-free emulation layer for a subset of the
/// unittest/test API used by the language and core library.
///
/// Compared with `minitest.dart`, this library supports and expects
/// asynchronous tests. It uses a `Zone` per test to collect errors in the
/// correct test.
/// It does not support `setUp` or `tearDown` methods,
/// and matchers are severely restricted.
///
/// A number of our language and core library tests were written against the
/// unittest package, which is now deprecated in favor of the new test package.
/// The latter is much better feature-wise, but is also quite complex and has
/// many dependencies. For low-level language and core library tests, we don't
/// want to have to pull in a large number of dependencies and be able to run
/// them correctly in order to run a test, so we want to test them against
/// something simpler.
///
/// When possible, we just use the tiny expect library. But to avoid rewriting
/// all of the existing tests that use unittest, they can instead use this,
/// which shims the unittest API with as little code as possible and calls into
/// expect.
///
/// Eventually, it would be good to refactor those tests to use the expect
/// package directly and remove this.
import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

void group(String name, body()) {
  var oldName = _pushName(name);
  try {
    body();
  } finally {
    _popName(oldName);
  }
}

void test(String name, body()) {
  var oldName = _pushName(name);
  var test = new _Test(_currentName)..asyncWait();
  var result =
      runZoned(body, zoneValues: {_testToken: test}, onError: test.fail);
  if (result is Future) {
    result.then((_) {
      test.asyncDone();
    }, onError: test.fail);
  } else {
    // Ensure all tests get to be set up first.
    scheduleMicrotask(test.asyncDone);
  }
  _popName(oldName);
}

void expect(dynamic value, dynamic matcher, {String reason}) {
  Matcher m;
  if (matcher is _Matcher) {
    m = matcher.call;
  } else if (matcher is! Matcher) {
    m = equals(matcher);
  } else {
    m = matcher;
  }
  m(value);
}

R Function() expectAsync0<R>(R Function() f, {int count = 1}) {
  var test = _currentTest..asyncWait(count);
  return () {
    var result = f();
    test.asyncDone();
    return result;
  };
}

R Function(A) expectAsync1<R, A>(R Function(A) f, {int count = 1}) {
  var test = _currentTest..asyncWait(count);
  return (A a) {
    var result = f(a);
    test.asyncDone();
    return result;
  };
}

R Function(A, B) expectAsync2<R, A, B>(R Function(A, B) f, {int count = 1}) {
  var test = _currentTest..asyncWait(count);
  return (A a, B b) {
    var result = f(a, b);
    test.asyncDone();
    return result;
  };
}

dynamic expectAsync(Function f, {int count = 1}) {
  var f2 = f; // Avoid type-promoting f, we want dynamic invocations.
  var test = _currentTest;
  if (f2 is Function(Null, Null, Null, Null, Null)) {
    test.asyncWait(count);
    return ([a, b, c, d, e]) {
      var result = f(a, b, c, d, e);
      test.asyncDone();
      return result;
    };
  }
  if (f2 is Function(Null, Null, Null, Null)) {
    test.asyncWait(count);
    return ([a, b, c, d]) {
      var result = f(a, b, c, d);
      test.asyncDone();
      return result;
    };
  }
  if (f2 is Function(Null, Null, Null)) {
    test.asyncWait(count);
    return ([a, b, c]) {
      var result = f(a, b, c);
      test.asyncDone();
      return result;
    };
  }
  if (f2 is Function(Null, Null)) {
    test.asyncWait(count);
    return ([a, b]) {
      var result = f(a, b);
      test.asyncDone();
      return result;
    };
  }
  if (f2 is Function(Null)) {
    test.asyncWait(count);
    return ([a]) {
      var result = f(a);
      test.asyncDone();
      return result;
    };
  }
  if (f2 is Function()) {
    test.asyncWait(count);
    return () {
      var result = f();
      test.asyncDone();
      return result;
    };
  }
  throw new UnsupportedError(
      "expectAsync only accepts up to five arguemnt functions");
}

// Matchers
typedef Matcher = void Function(dynamic);

Matcher same(dynamic o) => (v) {
      Expect.identical(o, v);
    };

Matcher equals(dynamic o) => (v) {
      Expect.deepEquals(o, v);
    };

Matcher greaterThan(num n) => (dynamic v) {
      Expect.type<num>(v);
      num value = v;
      if (value > n) return;
      Expect.fail("$v is not greater than $n");
    };

Matcher greaterThanOrEqualTo(num n) => (dynamic v) {
      Expect.type<num>(v);
      num value = v;
      if (value >= n) return;
      Expect.fail("$v is not greater than $n");
    };

Matcher lessThan(num n) => (dynamic v) {
      Expect.type<num>(v);
      num value = v;
      if (value < n) return;
      Expect.fail("$v is not less than $n");
    };

Matcher lessThanOrEqualTo(num n) => (dynamic v) {
      Expect.type<num>(v);
      num value = v;
      if (value <= n) return;
      Expect.fail("$v is not less than $n");
    };

void isTrue(dynamic v) {
  Expect.isTrue(v);
}

void isFalse(dynamic v) {
  Expect.isFalse(v);
}

void isNull(dynamic o) {
  Expect.isNull(o);
}

bool isStateError(dynamic o) {
  Expect.type<StateError>(o);
}

void _checkThrow<T>(dynamic v, void onError(error)) {
  if (v is Future) {
    var test = _currentTest..asyncWait();
    v.then((_) {
      Expect.fail("Did not throw");
    }, onError: (e, s) {
      if (e is! T) throw e;
      if (onError != null) onError(e);
      test.asyncDone();
    });
    return;
  }
  Expect.throws<T>(v, (e) {
    onError(e);
    return true;
  });
}

void throws(dynamic v) {
  _checkThrow<Object>(v, (_) {});
}

Matcher throwsA(matcher) => (dynamic o) {
      _checkThrow<Object>(o, (error) {
        expect(error, matcher);
      });
    };

Matcher completion(matcher) => (dynamic o) {
      Expect.type<Future>(o);
      Future future = o;
      _currentTest.asyncWait();
      future.then((value) {
        expect(value, matcher);
        _currentTest.asyncDone();
      });
    };

void completes(dynamic o) {
  Expect.type<Future>(o);
  Future future = o;
  _currentTest.asyncWait();
  future.then((_) {
    _currentTest.asyncDone();
  });
}

void isMap(dynamic o) {
  Expect.type<Map>(o);
}

void isList(dynamic o) {
  Expect.type<List>(o);
}

void isNotNull(dynamic o) {
  Expect.isNotNull(o);
}

abstract class _Matcher {
  void call(dynamic o);
}

class isInstanceOf<T> implements _Matcher {
  void call(dynamic o) {
    Expect.type<T>(o);
  }
}

void throwsArgumentError(dynamic v) {
  _checkThrow<ArgumentError>(v, (_) {});
}

String fail(String message) {
  Expect.fail("$message");
}

// Internal helpers.

// The current combined name of the nesting [group] or [test].
String _currentName = null;

String _pushName(String newName) {
  var oldName = _currentName;
  if (oldName == null) {
    _currentName = newName;
  } else {
    _currentName = "$oldName $newName";
  }
  return oldName;
}

void _popName(String oldName) {
  _currentName = oldName;
}

// Key for zone value holding current test object.
final Object _testToken = new Object();

_Test get _currentTest =>
    Zone.current[_testToken] ?? (throw new StateError("Not inside test!"));

class _Test {
  static int activeTests = 0;
  static int failedTests = 0;

  final String name;
  bool completed = false;
  bool failed = false;
  int asyncExpected = 0;
  _Test(this.name) {
    activeTests++;
  }

  void asyncWait([int n = 1]) {
    if (completed) {
      print("ERROR: $name: New operations started after completion."
          "${StackTrace.current}");
    } else if (asyncExpected == 0) {
      asyncStart(); // Matched by asyncEnd in [_complete];
    }
    asyncExpected += n;
  }

  void asyncDone() {
    if (asyncExpected == 0) {
      print("ERROR: $name: More asyncEnds than asyncStarts.\n"
          "${StackTrace.current}");
    } else {
      asyncExpected--;
      if (asyncExpected == 0 && !completed) {
        print("SUCCESS: $name");
        _complete();
      }
    }
  }

  void fail(Object error, StackTrace stack) {
    if (!completed) {
      failed = true;
      failedTests++;
      print("FAILURE: $name: $error\n$stack");
      _complete();
    } else {
      if (!failed) {
        failed = true;
        failedTests++;
      }
      print("FAILURE: $name: (after completion) $error\n$stack");
    }
  }

  void _complete() {
    assert(!completed);
    completed = true;
    activeTests--;
    if (failedTests == 0) {
      asyncEnd();
    } else if (activeTests == 0) {
      Zone.root.scheduleMicrotask(() {
        Expect.fail("$failedTests tests failed");
      });
    }
  }
}
