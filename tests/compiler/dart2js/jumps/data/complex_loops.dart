// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

simpleForInLoopWithContinue(list) {
  /*0@continue*/ for (int i in list) {
    if (i % 2 == 0) /*target=0*/ continue;
    print(i);
  }
}

complexForInLoopWithContinueLookalike1(list) {
  for (int i in list) {
    label:
    /*0@break*/
    {
      if (i % 2 == 0) /*target=0*/ break label;
      print(i);
    }
    print(i);
  }
}

complexForInLoopWithContinueLookalike2(list) {
  /*0@continue*/
  for (int i in list) {
    label:
    {
      if (i % 2 == 0) /*target=0*/ break label;
      print(i);
    }
  }
}

labelledBreakInNestedWhileLoop(bool condition()) {
  int i = 111;
  /*0@break*/ while (condition()) {
    label:
    /*1@break*/ {
      while (condition()) {
        /*target=1*/ break label;
      }
      i--;
    }
    /*target=0*/ break;
  }
  return i;
}

nestedLoopsWithInnerBreak(list) {
  for (int i in list) {
    /*0@break*/ for (int j in list) {
      if (i % j == 0) /*target=0*/ break;
      print(i);
    }
  }
}

nestedLoopsWithInnerContinue(list) {
  for (int i in list) {
    /*0@continue*/ for (int j in list) {
      if (i % j == 0) /*target=0*/ continue;
      print(i);
    }
  }
}

nestedLoopsWithLabelledBreak(list) {
  outer:
  /*0@break*/
  for (int i in list) {
    for (int j in list) {
      if (i % j == 0) /*target=0*/ break outer;
      print(i);
    }
  }
}

nestedLoopsWithLabelledContinue(list) {
  outer:
  /*0@continue*/
  for (int i in list) {
    for (int j in list) {
      if (i % j == 0) /*target=0*/ continue outer;
      print(i);
    }
  }
}

main() {
  simpleForInLoopWithContinue([1, 2, 3, 4]);
  complexForInLoopWithContinueLookalike1([1, 2, 3, 4]);
  complexForInLoopWithContinueLookalike2([1, 2, 3, 4]);
  labelledBreakInNestedWhileLoop(() => true);
  nestedLoopsWithInnerBreak([1, 2, 3, 4]);
  nestedLoopsWithInnerContinue([1, 2, 3, 4]);
  nestedLoopsWithLabelledBreak([1, 2, 3, 4]);
  nestedLoopsWithLabelledContinue([1, 2, 3, 4]);
}
