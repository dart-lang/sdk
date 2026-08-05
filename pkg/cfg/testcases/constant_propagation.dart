// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int test1(int x) {
  int y;
  if (x == x) {
    if (x + 1 == x + 1) {
      y = 1;
    } else {
      y = 3;
    }
  } else {
    y = 5;
  }
  return y + 1;
}

void test2() {
  var x = 0;
  for (;;) {
    if (x == 0) break;
    x = x + 1;
  }
}

void test3(int x, int y) {
  if (true) {
    x = 10;
  }
  var z = y;
  if (x > 20) {
    z = y + 10;
  }
  try {
    ++z;
    if (x > 30) {
      print('I can throw');
    }
  } catch (_) {
    print(z);
  }
}

void test4(int x, int z) {
  if (true) {
    x = 10;
  }
  int y;
  switch (x) {
    case 1:
      y = 10;
    case 2:
      y = 20;
    case 10:
      y = z;
    default:
      y = -1;
  }
  print(y);
}

void nullCheck(int? x) {
  if (1 != 2) {
    x = 10;
  }
  print(x!);
}

void stringInterpolation(String s, int x) {
  if (true) {
    s = 'abc';
    x = 10;
  }
  final str1 = 's = $s, x = $x';
  print('result: $str1');
}

void boolNot(bool x) {
  if (true) {
    x = true;
  }
  print(!x);
}

// Constant propagation changes order of block predecessors in this function.
void reorderPredecessors(List<int> bytes, int i, int end, bool c1, bool c2) {
  int state = bytes[i++];
  int byte = bytes[i++];
  loop:
  while (true) {
    multibyte:
    while (true) {
      state = byte;
      if (state == 42) {
        if (i == end) break loop;
        break multibyte;
      } else if (c1) {
        if (c2) {
          state = 42;
        } else {
          print(state);
          return;
        }
      }
      if (i == end) break loop;
      byte = bytes[i++];
    }

    byte = bytes[i++];
    if (byte < 128) {
      break loop;
    }
  }

  if (state > 5) {
    print(state);
  }
}

void main() {}
