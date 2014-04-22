// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.call_matcher;

import 'package:matcher/matcher.dart';

import 'util.dart';

/**
 * A [CallMatcher] is a special matcher used to match method calls (i.e.
 * a method name and set of arguments). It is not a [Matcher] like the
 * unit test [Matcher], but instead represents a method name and a
 * collection of [Matcher]s, one per argument, that will be applied
 * to the parameters to decide if the method call is a match.
 */
class CallMatcher {
  Matcher nameFilter;
  List<Matcher> argMatchers;

  /**
   * Constructor for [CallMatcher]. [name] can be null to
   * match anything, or a literal [String], a predicate [Function],
   * or a [Matcher]. The various arguments can be scalar values or
   * [Matcher]s.
   */
  CallMatcher([name,
              arg0 = NO_ARG,
              arg1 = NO_ARG,
              arg2 = NO_ARG,
              arg3 = NO_ARG,
              arg4 = NO_ARG,
              arg5 = NO_ARG,
              arg6 = NO_ARG,
              arg7 = NO_ARG,
              arg8 = NO_ARG,
              arg9 = NO_ARG]) {
    if (name == null) {
      nameFilter = anything;
    } else {
      nameFilter = wrapMatcher(name);
    }
    argMatchers = new List<Matcher>();
    if (identical(arg0, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg0));
    if (identical(arg1, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg1));
    if (identical(arg2, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg2));
    if (identical(arg3, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg3));
    if (identical(arg4, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg4));
    if (identical(arg5, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg5));
    if (identical(arg6, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg6));
    if (identical(arg7, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg7));
    if (identical(arg8, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg8));
    if (identical(arg9, NO_ARG)) return;
    argMatchers.add(wrapMatcher(arg9));
  }

  /**
   * We keep our behavior specifications in a Map, which is keyed
   * by the [CallMatcher]. To make the keys unique and to get a
   * descriptive value for the [CallMatcher] we have this override
   * of [toString()].
   */
  String toString() {
    Description d = new StringDescription();
    d.addDescriptionOf(nameFilter);
    // If the nameFilter was a simple string - i.e. just a method name -
    // strip the quotes to make this more natural in appearance.
    if (d.toString()[0] == "'") {
      d.replace(d.toString().substring(1, d.toString().length - 1));
    }
    d.add('(');
    for (var i = 0; i < argMatchers.length; i++) {
      if (i > 0) d.add(', ');
      d.addDescriptionOf(argMatchers[i]);
    }
    d.add(')');
    return d.toString();
  }

  /**
   * Given a [method] name and list of [arguments], return true
   * if it matches this [CallMatcher.
   */
  bool matches(String method, List arguments) {
    var matchState = {};
    if (!nameFilter.matches(method, matchState)) {
      return false;
    }
    var numArgs = (arguments == null) ? 0 : arguments.length;
    if (numArgs < argMatchers.length) {
      throw new Exception("Less arguments than matchers for $method.");
    }
    for (var i = 0; i < argMatchers.length; i++) {
      if (!argMatchers[i].matches(arguments[i], matchState)) {
        return false;
      }
    }
    return true;
  }
}

/**
 * Returns a [CallMatcher] for the specified signature. [method] can be
 * null to match anything, or a literal [String], a predicate [Function],
 * or a [Matcher]. The various arguments can be scalar values or [Matcher]s.
 * To match getters and setters, use "get " and "set " prefixes on the names.
 * For example, for a property "foo", you could use "get foo" and "set foo"
 * as literal string arguments to callsTo to match the getter and setter
 * of "foo".
 */
CallMatcher callsTo([method,
                     arg0 = NO_ARG,
                     arg1 = NO_ARG,
                     arg2 = NO_ARG,
                     arg3 = NO_ARG,
                     arg4 = NO_ARG,
                     arg5 = NO_ARG,
                     arg6 = NO_ARG,
                     arg7 = NO_ARG,
                     arg8 = NO_ARG,
                     arg9 = NO_ARG]) {
  return new CallMatcher(method, arg0, arg1, arg2, arg3, arg4,
      arg5, arg6, arg7, arg8, arg9);
}
