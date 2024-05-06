// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class V {
  String buf = "";

  void write(String value) {
    buf += value;
  }

  String recurseA(int i) {
    if (i > 0) {
      write(recurseA(i - 1));
      return '[$i]';
    } else {
      return '[0]';
    }
  }

  String recurseB(int i) {
    if (i > 0) {
      write('x' + recurseB(i - 1));
      return '[$i]';
    } else {
      return '[0]';
    }
  }
}

void main() {
  final v1 = V();
  v1.recurseA(3);
  Expect.equals('[0][1][2]', v1.buf);

  final v2 = V();
  v2.recurseB(3);
  Expect.equals('x[0]x[1]x[2]', v2.buf);
}
