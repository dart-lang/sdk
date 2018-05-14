// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class T {}

empty1() {}
void empty2() {}
dynamic empty3() {} // ignore: missing_return
Object empty4() {} // ignore: missing_return

Object return1() {
  return new T();
}

void return2(int i) {
  return return2(i - 1);
}

return3() => new T();

void return4() {
  return;
}

expr1() {
  new T();
}

expr2(bool c) {
  if (c) {
    return new T();
  }
  new T();
}

expr3(bool c, Object x) {
  if (c) {
    return new T();
  }
  x.toString();
}

throw1(bool c, Object x) {
  Object y = x;
  throw y;
}

throw2(bool c, Object x) {
  if (c) {
    return new T();
  }
  throw 'Error!';
}

loop1(bool c, Object x) {
  for (;;) {}
}

loop2(bool c, Object x) {
  if (c) {
    return new T();
  }
  do {} while (false);
}

loop3(bool c, Object x) {
  if (c) {
    return new T();
  }
  L:
  for (;;) {
    break L;
  }
}

switch_(bool c, int i) {
  if (c) {
    return new T();
  }
  switch (i) {
    case 1:
      continue L;
    L:
    case 2:
      break;
  }
}

if1(bool c) {
  if (c) {
    return new T();
  } else {
    throw 'Error!';
  }
}

if2(bool c) {
  if (c) {
    return new T();
  } else {}
}

if3(bool c) {
  if (c) {
  } else {
    throw 'Error!';
  }
}

if4(bool c) {
  if (c) {
  } else {}
}

void if5(bool c) {
  if (c) {
    return if5(c);
  } else {
    L:
    for (;;) {
      while (true) {
        break L;
        return if5(!c);
      }
    }
    if (!c) {
      throw 'Error!';
    }
  }
}

label1(bool c) {
  L:
  {
    if (c) {
      return new T();
    }
    break L;
  }
}

try1(bool c) {
  if (c) {
    return new T();
  }
  try {} on ArgumentError {}
}

try2() {
  try {
    return new T();
  } on ArgumentError {}
}

try3() {
  try {
    return new T();
  } on ArgumentError {
    throw 'Error!';
  }
}

try4(bool c) {
  if (c) {
    return new T();
  }
  try {} finally {}
}

try5() {
  try {} finally {
    return new T();
  }
}

try6() {
  try {
    return new T();
  } finally {}
}

try7(bool c) {
  if (c) {
    return new T();
  }
  try {} on ArgumentError {} finally {
    throw 'Error!';
  }
}

main() {}
