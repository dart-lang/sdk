// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.util;

import 'package:matcher/matcher.dart';

/** Utility function for optionally qualified method names */
String qualifiedName(owner, String method) {
  if (owner == null || identical(owner, anything)) {
    return method;
  } else if (owner is Matcher) {
    Description d = new StringDescription();
    d.addDescriptionOf(owner);
    d.add('.');
    d.add(method);
    return d.toString();
  } else {
    return '$owner.$method';
  }
}

/** Sentinel value for representing no argument. */
class _Sentinel {
  const _Sentinel();
}
const NO_ARG = const _Sentinel();
