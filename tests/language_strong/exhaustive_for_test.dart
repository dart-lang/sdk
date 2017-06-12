// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing for statement.

import "package:expect/expect.dart";

// Test several variations of for loops:
//   * With or without an initializer.
//   * With or without a test.
//   * With or without an update.
//   * With or without a continue.
//   * With or without a fall through exit from the body.
//   * With or without a break.

// Note that some possibilities are infinite loops and so not tested.
// Combinations that do not have a break or a test but do have a
// fall through from the body or a continue will never exit the loop.

// Each loop test function sets a status containing a bit for each part of
// the loop that is present, and then clears the bit as that part of the
// loop is executed.  The test expectation should be 0 (all present parts
// were executed), except for a few cases where an update expression is
// unreachable due to a break or return in the loop body.

const int INIT = 1;
const int TEST = 2;
const int UPDATE = 4;
const int CONTINUE = 8;
const int FALL = 16;
const int BREAK = 32;

var status;

void loop0() {
  status = 0;
  for (;;) {
    return;
  }
}

void loop1() {
  status = INIT;
  for (status &= ~INIT;;) {
    return;
  }
}

void loop2() {
  status = TEST;
  for (; (status &= ~TEST) != 0;) {
    return;
  }
}

void loop3() {
  status = INIT | TEST;
  for (status &= ~INIT; (status &= ~TEST) != 0;) {
    return;
  }
}

void loop4() {
  status = UPDATE;
  for (;; status &= ~UPDATE) {
    return;
  }
}

void loop5() {
  status = INIT | UPDATE;
  for (status &= ~INIT;; status &= ~UPDATE) {
    return;
  }
}

void loop6() {
  status = TEST | UPDATE;
  for (; (status &= ~TEST) != 0; status &= ~UPDATE) {
    return;
  }
}

void loop7() {
  status = INIT | TEST | UPDATE;
  for (status &= ~INIT; (status &= ~TEST) != 0; status &= ~UPDATE) {
    return;
  }
}

// Infinite loop not tested.
void loop8() {
  status = CONTINUE;
  for (;;) {
    status &= ~CONTINUE;
    continue;
  }
}

// Infinite loop not tested.
void loop9() {
  status = INIT | CONTINUE;
  for (status &= ~INIT;;) {
    status &= ~CONTINUE;
    continue;
  }
}

void loop10() {
  status = TEST | CONTINUE;
  for (; (status &= ~TEST) != 0;) {
    status &= ~CONTINUE;
    continue;
  }
}

void loop11() {
  status = INIT | TEST | CONTINUE;
  for (status &= ~INIT; (status &= ~TEST) != 0;) {
    status &= ~CONTINUE;
    continue;
  }
}

// Infinite loop.
void loop12() {
  status = UPDATE | CONTINUE;
  for (;; status &= ~UPDATE) {
    status &= ~CONTINUE;
    continue;
  }
}

// Infinite loop.
void loop13() {
  status = INIT | UPDATE | CONTINUE;
  for (status &= ~INIT;; status &= ~UPDATE) {
    status &= ~CONTINUE;
    continue;
  }
}

void loop14() {
  status = TEST | UPDATE | CONTINUE;
  for (; (status &= ~TEST) != 0; status &= ~UPDATE) {
    status &= ~CONTINUE;
    continue;
  }
}

void loop15() {
  status = INIT | TEST | UPDATE | CONTINUE;
  for (status &= ~INIT; (status &= ~TEST) != 0; status &= ~UPDATE) {
    status &= ~CONTINUE;
    continue;
  }
}

// Infinite loop.
void loop16() {
  status = FALL;
  for (;;) {
    status &= ~FALL;
  }
}

// Infinite loop.
void loop17() {
  status = INIT | FALL;
  for (status &= ~INIT;;) {
    status &= ~FALL;
  }
}

void loop18() {
  status = TEST | FALL;
  for (; (status &= ~TEST) != 0;) {
    status &= ~FALL;
  }
}

void loop19() {
  status = INIT | TEST | FALL;
  for (status &= ~INIT; (status &= ~TEST) != 0;) {
    status &= ~FALL;
  }
}

// Infinite loop.
void loop20() {
  status = UPDATE | FALL;
  for (;; status &= ~UPDATE) {
    status &= ~FALL;
  }
}

// Infinite loop.
void loop21() {
  status = INIT | UPDATE | FALL;
  for (status &= ~INIT;; status &= ~UPDATE) {
    status &= ~FALL;
  }
}

void loop22() {
  status = TEST | UPDATE | FALL;
  for (; (status &= ~TEST) != 0; status &= ~UPDATE) {
    status &= ~FALL;
  }
}

void loop23() {
  status = INIT | TEST | UPDATE | FALL;
  for (status &= ~INIT; (status &= ~TEST) != 0; status &= ~UPDATE) {
    status &= ~FALL;
  }
}

// Infinite loop.
void loop24() {
  status = CONTINUE | FALL;
  for (;;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~FALL;
  }
}

// Infinite loop.
void loop25() {
  status = INIT | CONTINUE | FALL;
  for (status &= ~INIT;;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~FALL;
  }
}

void loop26() {
  status = TEST | CONTINUE | FALL;
  for (; (status &= ~TEST) != 0;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~FALL;
  }
}

void loop27() {
  status = INIT | TEST | CONTINUE | FALL;
  for (status &= ~INIT; (status &= ~TEST) != 0;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~FALL;
  }
}

// Infinite loop.
void loop28() {
  status = UPDATE | CONTINUE | FALL;
  for (;; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~FALL;
  }
}

// Infinite loop.
void loop29() {
  status = INIT | UPDATE | CONTINUE | FALL;
  for (status &= ~INIT;; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~FALL;
  }
}

void loop30() {
  status = TEST | UPDATE | CONTINUE | FALL;
  for (; (status &= ~TEST) != 0; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~FALL;
  }
}

void loop31() {
  status = INIT | TEST | UPDATE | CONTINUE | FALL;
  for (status &= ~INIT; (status &= ~TEST) != 0; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~FALL;
  }
}

void loop32() {
  status = BREAK;
  for (;;) {
    status &= ~BREAK;
    break;
  }
}

void loop33() {
  status = INIT | BREAK;
  for (status &= ~INIT;;) {
    status &= ~BREAK;
    break;
  }
}

void loop34() {
  status = TEST | BREAK;
  for (; (status &= ~TEST) != 0;) {
    status &= ~BREAK;
    break;
  }
}

void loop35() {
  status = INIT | TEST | BREAK;
  for (status &= ~INIT; (status &= ~TEST) != 0;) {
    status &= ~BREAK;
    break;
  }
}

void loop36() {
  status = UPDATE | BREAK;
  for (;; status &= ~UPDATE) {
    status &= ~BREAK;
    break;
  }
}

void loop37() {
  status = INIT | UPDATE | BREAK;
  for (status &= ~INIT;; status &= ~UPDATE) {
    status &= ~BREAK;
    break;
  }
}

void loop38() {
  status = TEST | UPDATE | BREAK;
  for (; (status &= ~TEST) != 0; status &= ~UPDATE) {
    status &= ~BREAK;
    break;
  }
}

void loop39() {
  status = INIT | TEST | UPDATE | BREAK;
  for (status &= ~INIT; (status &= ~TEST) != 0; status &= ~UPDATE) {
    status &= ~BREAK;
    break;
  }
}

void loop40() {
  status = CONTINUE | BREAK;
  for (;;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~BREAK;
    break;
  }
}

void loop41() {
  status = INIT | CONTINUE | BREAK;
  for (status &= ~INIT;;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~BREAK;
    break;
  }
}

void loop42() {
  status = TEST | CONTINUE | BREAK;
  for (; (status &= ~TEST) != 0;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~BREAK;
    break;
  }
}

void loop43() {
  status = INIT | TEST | CONTINUE | BREAK;
  for (status &= ~INIT; (status &= ~TEST) != 0;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~BREAK;
    break;
  }
}

void loop44() {
  status = UPDATE | CONTINUE | BREAK;
  for (;; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~BREAK;
    break;
  }
}

void loop45() {
  status = INIT | UPDATE | CONTINUE | BREAK;
  for (status &= ~INIT;; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~BREAK;
    break;
  }
}

void loop46() {
  status = TEST | UPDATE | CONTINUE | BREAK;
  for (; (status &= ~TEST) != 0; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~BREAK;
    break;
  }
}

void loop47() {
  status = INIT | TEST | UPDATE | CONTINUE | BREAK;
  for (status &= ~INIT; (status &= ~TEST) != 0; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    status &= ~BREAK;
    break;
  }
}

void loop48() {
  status = FALL | BREAK;
  for (;;) {
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop49() {
  status = INIT | FALL | BREAK;
  for (status &= ~INIT;;) {
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop50() {
  status = TEST | FALL | BREAK;
  for (; (status &= ~TEST) != 0;) {
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop51() {
  status = INIT | TEST | FALL | BREAK;
  for (status &= ~INIT; (status &= ~TEST) != 0;) {
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop52() {
  status = UPDATE | FALL | BREAK;
  for (;; status &= ~UPDATE) {
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop53() {
  status = INIT | UPDATE | FALL | BREAK;
  for (status &= ~INIT;; status &= ~UPDATE) {
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop54() {
  status = TEST | UPDATE | FALL | BREAK;
  for (; (status &= ~TEST) != 0; status &= ~UPDATE) {
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop55() {
  status = INIT | TEST | UPDATE | FALL | BREAK;
  for (status &= ~INIT; (status &= ~TEST) != 0; status &= ~UPDATE) {
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop56() {
  status = CONTINUE | FALL | BREAK;
  for (;;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop57() {
  status = INIT | CONTINUE | FALL | BREAK;
  for (status &= ~INIT;;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop58() {
  status = TEST | CONTINUE | FALL | BREAK;
  for (; (status &= ~TEST) != 0;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop59() {
  status = INIT | TEST | CONTINUE | FALL | BREAK;
  for (status &= ~INIT; (status &= ~TEST) != 0;) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop60() {
  status = UPDATE | CONTINUE | FALL | BREAK;
  for (;; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop61() {
  status = INIT | UPDATE | CONTINUE | FALL | BREAK;
  for (status &= ~INIT;; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop62() {
  status = TEST | UPDATE | CONTINUE | FALL | BREAK;
  for (; (status &= ~TEST) != 0; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void loop63() {
  status = INIT | TEST | UPDATE | CONTINUE | FALL | BREAK;
  for (status &= ~INIT; (status &= ~TEST) != 0; status &= ~UPDATE) {
    if ((status & CONTINUE) == CONTINUE) {
      status &= ~CONTINUE;
      continue;
    }
    if ((status & FALL) == FALL) {
      status &= ~FALL;
    } else {
      status &= ~BREAK;
      break;
    }
  }
}

void main() {
  loop0();
  Expect.equals(0, status);
  loop1();
  Expect.equals(0, status);
  loop2();
  Expect.equals(0, status);
  loop3();
  Expect.equals(0, status);

  // The next four tests return with status UPDATE because they return
  // before the update expression is reached.
  loop4();
  Expect.equals(UPDATE, status);
  loop5();
  Expect.equals(UPDATE, status);
  loop6();
  Expect.equals(UPDATE, status);
  loop7();
  Expect.equals(UPDATE, status);

  loop10();
  Expect.equals(0, status);
  loop11();
  Expect.equals(0, status);
  loop14();
  Expect.equals(0, status);
  loop15();
  Expect.equals(0, status);
  loop18();
  Expect.equals(0, status);
  loop19();
  Expect.equals(0, status);
  loop22();
  Expect.equals(0, status);
  loop23();
  Expect.equals(0, status);
  loop26();
  Expect.equals(0, status);
  loop27();
  Expect.equals(0, status);
  loop30();
  Expect.equals(0, status);
  loop31();
  Expect.equals(0, status);
  loop32();
  Expect.equals(0, status);
  loop33();
  Expect.equals(0, status);
  loop34();
  Expect.equals(0, status);
  loop35();
  Expect.equals(0, status);

  // The next four tests return with status UPDATE because they break from
  // the loop before the update expression is reached.
  loop36();
  Expect.equals(4, status);
  loop37();
  Expect.equals(4, status);
  loop38();
  Expect.equals(4, status);
  loop39();
  Expect.equals(4, status);

  loop40();
  Expect.equals(0, status);
  loop41();
  Expect.equals(0, status);
  loop42();
  Expect.equals(0, status);
  loop43();
  Expect.equals(0, status);
  loop44();
  Expect.equals(0, status);
  loop45();
  Expect.equals(0, status);
  loop46();
  Expect.equals(0, status);
  loop47();
  Expect.equals(0, status);
  loop48();
  Expect.equals(0, status);
  loop49();
  Expect.equals(0, status);
  loop50();
  Expect.equals(0, status);
  loop51();
  Expect.equals(0, status);
  loop52();
  Expect.equals(0, status);
  loop53();
  Expect.equals(0, status);
  loop54();
  Expect.equals(0, status);
  loop55();
  Expect.equals(0, status);
  loop56();
  Expect.equals(0, status);
  loop57();
  Expect.equals(0, status);
  loop58();
  Expect.equals(0, status);
  loop59();
  Expect.equals(0, status);
  loop60();
  Expect.equals(0, status);
  loop61();
  Expect.equals(0, status);
  loop62();
  Expect.equals(0, status);
  loop63();
  Expect.equals(0, status);
}
