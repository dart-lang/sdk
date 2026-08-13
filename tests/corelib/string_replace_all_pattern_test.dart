// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "string_replace_all_common.dart";

main() {
  testAll(Wrapper.wrap);
}

/// A wrapper that is not recognizable as a String or RegExp.
class Wrapper implements Pattern {
  final Pattern _pattern;
  Wrapper(this._pattern);

  static Pattern wrap(Pattern p) => Wrapper(p);

  Iterable<Match> allMatches(String string, [int start = 0]) =>
      _pattern.allMatches(string, start);

  Match? matchAsPrefix(String string, [int start = 0]) =>
      _pattern.matchAsPrefix(string, start);

  String toString() => "Wrap($_pattern)";
}
