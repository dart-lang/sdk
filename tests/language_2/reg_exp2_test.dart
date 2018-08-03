// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

import "package:expect/expect.dart";

class RegExp2Test {
  static String findImageTag_(String text, String extensions) {
    final re = new RegExp('src="(http://\\S+\\.(${extensions}))"');
    print('REGEXP findImageTag_ $extensions text: \n$text');
    final match = re.firstMatch(text);
    print('REGEXP findImageTag_ $extensions SUCCESS');
    if (match != null) {
      return match[1];
    } else {
      return null;
    }
  }

  static testMain() {
    String text =
        '''<img src="http://cdn.archinect.net/images/514x/c0/c0p3qo202oxp0e6z.jpg" width="514" height="616" border="0" title="" alt=""><em><p>My last entry was in December of 2009. I suppose I never was particularly good about updating this thing, but it seems a bit ridiculous that I couldn't be bothered to post once about the many, many things that have gone on since then. My apologies. I guess I could start by saying that the world looks like a very different place than it did back in second year.</p></em>

''';
    String extensions = 'jpg|jpeg|png';
    String tag = findImageTag_(text, extensions);
    Expect.isNotNull(tag);
  }
}

main() {
  RegExp2Test.testMain();
}
