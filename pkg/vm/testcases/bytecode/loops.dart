// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int test_for(List<int> list) {
  int sum = 0;
  for (int i = 0; i < list.length; i++) {
    sum = sum + list[i];
  }
  return sum;
}

int test_for_break(List<int> list) {
  int sum = 0;
  for (int i = 0; i >= 0; i++) {
    if (i >= list.length) {
      break;
    }
    sum = sum + list[i];
  }
  return sum;
}

int test_for_continue(List<int> list) {
  int sum = 0;
  for (int i = -100; i < list.length; i++) {
    if (i < 0) {
      continue;
    }
    sum = sum + list[i];
  }
  return sum;
}

int test_while(List<int> list) {
  int sum = 0;
  int i = 0;
  while (i < list.length) {
    sum = sum + list[i++];
  }
  return sum;
}

int test_do_while(List<int> list) {
  int sum = 0;
  int i = 0;
  do {
    sum = sum + list[i];
    ++i;
  } while (i < list.length);
  return sum;
}

int test_for_in(List<int> list) {
  int sum = 0;
  for (var e in list) {
    sum = sum + e;
  }
  return sum;
}

int test_for_in_with_outer_var(List<int> list) {
  int sum = 0;
  int e = 42;
  for (e in list) {
    sum = sum + e;
  }
  return sum;
}

main() {}
