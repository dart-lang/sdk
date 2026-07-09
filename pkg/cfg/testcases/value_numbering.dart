// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int test1(List<int> data, int i) {
  if (data[i - 1] > 0) {
    return data[i - 1];
  }
  return 0;
}

void test2(Object? obj) {
  if (obj is String) {
    print(obj.length);
    if (obj.isNotEmpty) {
      print(obj.codeUnitAt(0));
    }
  }
}

void test3(Object value) {
  switch (value) {
    case int() when value > 5 && value < 10:
      print('case 1');
    case int() when value > 5:
      print('case 2');
  }
}

void main() {}
