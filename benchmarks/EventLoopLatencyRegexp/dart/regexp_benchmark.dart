// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class RegexpBenchmark {
  void run() {
    final re = RegExp(r'(x+)*y');
    // ignore: prefer_interpolation_to_compose_strings
    final s = 'x' * 26 + '';
    re.allMatches(s).iterator.moveNext();
  }
}
