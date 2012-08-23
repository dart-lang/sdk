// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class JSSyntaxRegExp implements RegExp {
  external const JSSyntaxRegExp(String pattern,
                                [bool multiLine, bool ignoreCase]);
  external Match firstMatch(String str);
  external Iterable<Match> allMatches(String str);
  external bool hasMatch(String str);
  external String stringMatch(String str);
  external String get pattern();
  external bool get multiLine();
  external bool get ignoreCase();
}
