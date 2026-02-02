// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(List<void Function()> functions) {
  int a = 0;
  {
    int b = 0;
    {
      int c = 0;
      for (; c < 10; c++) {
        int d = 0;
        {
          int e = 0;
          {
            int f = 0;
            for (; f < 10; f++) {
              void Function() g = () => [b, c, e, f];
              functions.add(g);
            }
          }
        }
      }
    }
  }
}

bar(List<int Function()> functions) {
  int a = 0;
  {
    int b = 0;
    for (int i = 0; i < 10; i++) {
      int c = a + i;
      {
        int d = b + i;
        functions.add(() => c + d);
      }
    }
    for (int i = 0; i < 10; i++) {
      int c = a + i;
      {
        int d = b + i;
        functions.add(() => c + d);
      }
    }
  }
}
