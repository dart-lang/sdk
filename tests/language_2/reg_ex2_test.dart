// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

class RegEx2Test {
  static void testMain() {
    final helloPattern = new RegExp("with (hello)");
    String s = "this is a string with hello somewhere";
    Match match = helloPattern.firstMatch(s);
    if (match != null) {
      print("got match");
      int groupCount = match.groupCount;
      print("groupCount is $groupCount");
      print("group 0 is ${match.group(0)}");
      print("group 1 is ${match.group(1)}");
    } else {
      print("match not round");
    }
    print("done");
  }
}

main() {
  RegEx2Test.testMain();
}
