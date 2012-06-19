// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Matches a [Future] that completes successfully with a value. Note that this
 * creates an asynchronous expectation. The call to `expect()` that includes
 * this will return immediately and execution will continue. Later, when the
 * future completes, the actual expectation will run.
 *
 * To test that a Future completes with an exception, you can use [throws] and
 * [throwsA].
 */
Matcher completes = const _Completes(null);

/**
 * Matches a [Future] that completes succesfully with a value that matches
 * [matcher]. Note that this creates an asynchronous expectation. The call to
 * `expect()` that includes this will return immediately and execution will
 * continue. Later, when the future completes, the actual expectation will run.
 *
 * To test that a Future completes with an exception, you can use [throws] and
 * [throwsA].
 */
Matcher completion(matcher) => new _Completes(wrapMatcher(matcher));

class _Completes extends BaseMatcher {
  final Matcher _matcher;

  const _Completes(this._matcher);

  bool matches(item) {
    if (item is! Future) return false;

    item.onComplete(expectAsync1((future) {
      expect(future.hasValue,
          reason: 'Expected future to complete successfully, but it failed');
      if (_matcher != null) expect(future.value, _matcher);
    }));

    return true;
  }

  Description describe(Description description) {
    if (_matcher == null) {
      description.add('completes successfully');
    } else {
      description.add('completes to a value that ').addDescriptionOf(_matcher);
    }
    return description;
  }
}