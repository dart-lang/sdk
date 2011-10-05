// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringsTests {
  method() {
    var x;
    x = "a simple constant";
    x = 'a simple constant';

    x = "an escaped quote \".";
    x = 'an escaped quote \'.';

    x = "a new \n line";
    x = 'a new \n line';

    x = """
    multiline 1
    multiline 2
    """;
    x = '''
    multiline 1
    multiline 2
    ''';

    x = """multiline 1
    multiline 2
    """;
    x = '''multiline 1
    multiline 2
    ''';
  }
}
