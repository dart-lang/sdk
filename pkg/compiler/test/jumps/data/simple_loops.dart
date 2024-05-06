// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

simpleForLoop(count) {
  for (int i = 0; i < count; i++) {
    print(i);
  }
}

simpleForLoopWithBreak(count) {
  /*0@break*/ for (int i = 0; i < count; i = i + 1) {
    if (i % 2 == 0) /*target=0*/ break;
    print(i);
  }
}

simpleForLoopWithContinue(count) {
  /*0@continue*/ for (int i = 0; i < count; i = i + 1) {
    if (i % 2 == 0) /*target=0*/ continue;
    print(i);
  }
}

simpleForLoopWithBreakAndContinue(count) {
  /*0@break,continue*/ for (int i = 0; i < count; i = i + 1) {
    if (i % 2 == 0) /*target=0*/ continue;
    if (i % 3 == 0) /*target=0*/ break;
    print(i);
  }
}

simpleForLoopWithLabelledBreak(count) {
  outer:
  /*0@break*/
  for (int i = 0; i < count; i = i + 1) {
    if (i % 2 == 0) /*target=0*/ break outer;
    print(i);
  }
}

simpleForLoopWithLabelledContinue(count) {
  outer:
  /*0@continue*/
  for (int i = 0; i < count; i = i + 1) {
    if (i % 2 == 0) /*target=0*/ continue outer;
    print(i);
  }
}

simpleForInLoop(list) {
  for (int i in list) {
    print(i);
  }
}

simpleForInLoopWithBreak(list) {
  /*0@break*/ for (int i in list) {
    if (i % 2 == 0) /*target=0*/ break;
    print(i);
  }
}

simpleForInLoopWithContinue(list) {
  /*0@continue*/ for (int i in list) {
    if (i % 2 == 0) /*target=0*/ continue;
    print(i);
  }
}

simpleForInLoopWithBreakAndContinue(list) {
  /*0@break,continue*/ for (int i in list) {
    if (i % 2 == 0) /*target=0*/ continue;
    if (i % 3 == 0) /*target=0*/ break;
    print(i);
  }
}

simpleForInLoopWithLabelledBreak(list) {
  outer:
  /*0@break*/
  for (int i in list) {
    if (i % 2 == 0) /*target=0*/ break outer;
    print(i);
  }
}

simpleForInLoopWithLabelledContinue(list) {
  outer:
  /*0@continue*/
  for (int i in list) {
    if (i % 2 == 0) /*target=0*/ continue outer;
    print(i);
  }
}

simpleWhileLoop(count) {
  int i = 0;
  while (i < count) {
    print(i);
    i = i + 1;
  }
}

simpleWhileLoopWithBreak(count) {
  int i = 0;
  /*0@break*/ while (i < count) {
    if (i % 2 == 0) /*target=0*/ break;
    print(i);
    i = i + 1;
  }
}

simpleWhileLoopWithContinue(count) {
  int i = 0;
  /*0@continue*/ while (i < count) {
    if (i % 2 == 0) /*target=0*/ continue;
    print(i);
    i = i + 1;
  }
}

simpleWhileLoopWithBreakAndContinue(count) {
  int i = 0;
  /*0@break,continue*/ while (i < count) {
    if (i % 2 == 0) /*target=0*/ continue;
    if (i % 3 == 0) /*target=0*/ break;
    print(i);
  }
}

simpleWhileLoopWithLabelledBreak(count) {
  int i = 0;
  outer:
  /*0@break*/
  while (i < count) {
    if (i % 2 == 0) /*target=0*/ break outer;
    print(i);
    i = i + 1;
  }
}

simpleWhileLoopWithLabelledContinue(count) {
  int i = 0;
  outer:
  /*0@continue*/
  while (i < count) {
    if (i % 2 == 0) /*target=0*/ continue outer;
    print(i);
    i = i + 1;
  }
}

simpleDoLoop(count) {
  int i = 0;
  do {
    print(i);
    i = i + 1;
  } while (i < count);
}

simpleDoLoopWithBreak(count) {
  int i = 0;
  /*0@break*/ do {
    if (i % 2 == 0) /*target=0*/ break;
    print(i);
    i = i + 1;
  } while (i < count);
}

simpleDoLoopWithContinue(count) {
  int i = 0;
  /*0@continue*/ do {
    if (i % 2 == 0) /*target=0*/ continue;
    print(i);
    i = i + 1;
  } while (i < count);
}

simpleDoLoopWithBreakAndContinue(count) {
  int i = 0;
  /*0@break,continue*/ do {
    if (i % 2 == 0) /*target=0*/ continue;
    if (i % 3 == 0) /*target=0*/ break;
    print(i);
  } while (i < count);
}

simpleDoLoopWithLabelledBreak(count) {
  int i = 0;
  outer:
  /*0@break*/
  do {
    if (i % 2 == 0) /*target=0*/ break outer;
    print(i);
    i = i + 1;
  } while (i < count);
}

simpleDoLoopWithLabelledContinue(count) {
  int i = 0;
  outer:
  /*0@continue*/
  do {
    if (i % 2 == 0) /*target=0*/ continue outer;
    print(i);
    i = i + 1;
  } while (i < count);
}

main() {
  simpleForLoop(10);
  simpleForLoopWithBreak(10);
  simpleForLoopWithContinue(10);
  simpleForLoopWithBreakAndContinue(10);
  simpleForLoopWithLabelledBreak(10);
  simpleForLoopWithLabelledContinue(10);

  simpleForInLoop([1, 2, 3, 4]);
  simpleForInLoopWithBreak([1, 2, 3, 4]);
  simpleForInLoopWithContinue([1, 2, 3, 4]);
  simpleForInLoopWithBreakAndContinue([1, 2, 3, 4]);
  simpleForInLoopWithLabelledBreak([1, 2, 3, 4]);
  simpleForInLoopWithLabelledContinue([1, 2, 3, 4]);

  simpleWhileLoop(10);
  simpleWhileLoopWithBreak(10);
  simpleWhileLoopWithContinue(10);
  simpleWhileLoopWithBreakAndContinue(10);
  simpleWhileLoopWithLabelledBreak(10);
  simpleWhileLoopWithLabelledContinue(10);

  simpleDoLoop(10);
  simpleDoLoopWithBreak(10);
  simpleDoLoopWithContinue(10);
  simpleDoLoopWithBreakAndContinue(10);
  simpleDoLoopWithLabelledBreak(10);
  simpleDoLoopWithLabelledContinue(10);
}
