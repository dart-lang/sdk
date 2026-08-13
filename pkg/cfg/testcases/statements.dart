// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void if1(bool c1, bool c2, bool c3) {
  if (c1 && (c2 || !c3)) {
    print('oops');
  }
}

bool condition(int i) => i % 3 == 0;

void if2() {
  if (condition(1)) {
    if (condition(2) && condition(3)) {
      print(1);
    } else if (condition(4) || condition(5)) {
      print(2);
    }
  } else {
    print(3);
  }
}

int forLoop(int n) {
  var sum = 0;
  for (var i = 0; i < n; ++i) {
    sum += i;
  }
  return sum;
}

int whileLoop(int n) {
  var sum = 0;
  var i = 0;
  while (i < n) {
    sum += i;
    if (sum > 10) break;
    ++i;
  }
  return sum;
}

int doWhileLoop(int n) {
  var sum = 0;
  var i = n;
  do {
    sum += i;
    --i;
  } while (i >= 0);
  return sum;
}

int forInLoop(List<int> list) {
  var sum = 0;
  for (var elem in list) {
    sum += elem;
  }
  return sum;
}

void breakAndContinue(int n, int m) {
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < m; j++) {
      if (j < 3) {
        continue;
      }
      if ((i + j) % 5 == 0) {
        break;
      }
    }
  }
}

void switchStatement(int x) {
  switch (x) {
    case 1:
    case 2:
      print('1-2');
      break;
    case 3:
      print('3');
      continue L4;
    L4:
    case 4:
      print('3-4');
  }
}

void tryBlocks() {
  var x = 1;
  try {
    x = 2;
    try {
      x = 3;
    } finally {
      print(x);
    }
  } catch (e) {
    print(e);
    print(x);
  }
}

int tryFinallyWithBreaks() {
  try {
    print(10);
    for (var i = 0; i < 5; ++i) {
      try {
        print(i);
        if (i % 3 == 0) {
          break;
        }
        if (i % 3 == 1) {
          continue;
        }
        if (i % 3 == 2) {
          return i;
        }
      } finally {
        print(20);
      }
    }
  } finally {
    return 42;
  }
}

void tryWithThrowRethrow(bool c1, bool c2) {
  try {
    print(1);
    if (c1) {
      throw 'Boom!';
    }
  } on Error {
    print(2);
    if (c2) {
      rethrow;
    }
  }
}

void main() {
  print('hey');
}
