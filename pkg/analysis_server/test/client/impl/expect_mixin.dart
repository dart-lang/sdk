// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';

typedef _Predicate<T> = bool Function(T value);

/// Lightweight expect that can be run outside of a test context.
class ExpectMixin {
  void expect(actual, matcher, {String reason}) {
    matcher = _wrapMatcher(matcher);
    var matchState = {};
    try {
      if ((matcher as Matcher).matches(actual, matchState)) {
        return;
      }
    } catch (e, trace) {
      reason ??= '$e at $trace';
    }
    throw Exception(reason);
  }

  static Matcher _wrapMatcher(x) {
    if (x is Matcher) {
      return x;
    } else if (x is _Predicate<Object>) {
      // x is already a predicate that can handle anything
      return predicate(x);
    } else if (x is _Predicate<Null>) {
      // x is a unary predicate, but expects a specific type
      // so wrap it.
      // ignore: unnecessary_lambdas
      return predicate((a) => (x as dynamic)(a));
    } else {
      return equals(x);
    }
  }
}
