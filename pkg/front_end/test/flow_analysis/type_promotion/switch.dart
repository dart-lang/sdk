// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void case_falls_through_end(int i, Object o) {
  switch (i) {
    case 1:
      if (o is! int) return;
      /*int*/ o;
      break;
    case 2:
      o;
  }
  o;
}
