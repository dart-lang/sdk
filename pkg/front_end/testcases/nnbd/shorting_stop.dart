// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int field = 0;
  Class get next => this;
  int operator [](int key) => key;
  void operator []=(int key, int value) {}
}

main() {
  test(new Class());
}

test(Class? c) {
  c?.next.field; // ok
  throwsInStrong(() => c?.field + 2); // error
  ++c?.field; // ok
  c?.field++; // ok
  throwsInStrong(() => (c?.next).field); // error
  throwsInStrong(() => -c?.field); // error

  c?.next[0].isEven; // ok
  throwsInStrong(() => c?.next[0] + 2); // error
  ++c?.next[0]; // ok
  c?.next[0]++; // ok
  throwsInStrong(() => (c?.next[0]).isEven); // error
  throwsInStrong(() => -c?.next[0]); // error
}

final bool inStrongMode = _inStrongMode();

bool _inStrongMode() {
  var f = (String? s) {
    s.length; // This will be an invalid expression in strong mode.
  };
  try {
    f("foo");
  } catch (e) {
    return true;
  }
  return false;
}

void throwsInStrong(void Function() f) {
  if (inStrongMode) {
    try {
      f();
    } catch (e) {
      print(e);
      return;
    }
    throw 'Expected exception.';
  } else {
    f();
  }
}
