// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
/**
 * The mirror matchers library provides some additional matchers that
 * make use of dart:mirrors.
 *
 * ## Installing ##
 *
 * Use [pub][] to install this package. Add the following to your `pubspec.yaml`
 * file.
 *
 *     dependencies:
 *       unittest: any
 *
 * Then run `pub install`.
 *
 * Import this into your Dart code with:
 *
 *     import 'package:unittest/mirror_matchers.dart';
 *
 * For more information, see the [unittest package on pub.dartlang.org].
 * (http://pub.dartlang.org/packages/unittest).
 *
 * [pub]: http://pub.dartlang.org
 * [pkg]: http://pub.dartlang.org/packages/mirror_matchers
 */
library mirror_matchers;

import 'dart:mirrors';

import 'matcher.dart';

/**
 * Returns a matcher that checks if a class instance has a property
 * with name [name], and optionally, if that property in turn satisfies
 * a [matcher].
 */
Matcher hasProperty(String name, [matcher]) =>
  new _HasProperty(name, matcher == null ? null : wrapMatcher(matcher));

class _HasProperty extends Matcher {
  final String _name;
  final Matcher _matcher;

  const _HasProperty(this._name, [this._matcher]);

  bool matches(item, Map matchState) {
    var mirror = reflect(item);
    var classMirror = mirror.type;
    var symbol = new Symbol(_name);
    if (!classMirror.getters.containsKey(symbol)) {
      addStateInfo(matchState, {'reason': 'has no property named "$_name"'});
      return false;
    }
    if (_matcher == null) return true;
    var result = mirror.getField(symbol);
    var resultMatches = _matcher.matches(result.reflectee, matchState);
    if (!resultMatches) {
      addStateInfo(matchState, {'value': result.reflectee});
    }
    return resultMatches;
  }

  Description describe(Description description) {
    description.add('has property "$_name"');
    if (_matcher != null) {
      description.add(' which matches ').addDescriptionOf(_matcher);
    }
    return description;
  }

  Description describeMismatch(item, Description mismatchDescription,
                               Map matchState, bool verbose) {
    var reason = matchState == null ? null : matchState['reason'];
    if (reason != null) {
      mismatchDescription.add(reason);
    } else {
      mismatchDescription.add('has property "$_name" with value ').
        addDescriptionOf(matchState['value']);
      var innerDescription = new StringDescription();
      _matcher.describeMismatch(matchState['value'], innerDescription,
          matchState['state'], verbose);
      if (innerDescription.length > 0) {
        mismatchDescription.add(' which ').add(innerDescription.toString());
      }
    }
    return mismatchDescription;
  }
}
