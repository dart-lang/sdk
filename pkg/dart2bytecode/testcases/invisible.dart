// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.visible(void Function() fun) {
    print('A.visible');
    fun();
  }

  @pragma('vm:invisible')
  A.invisible(void Function() fun) {
    print('A.invisible');
    fun();
  }
}

void visible(void Function() fun) {
  print('visible()');
  fun();
}

@pragma('vm:invisible')
void invisible(void Function() fun) {
  print('invisible()');
  fun();
}

void visibleClosure(void Function() fun) {
  visibleInner() {
    print('visibleInner');
    fun();
  }

  visibleInner();
}

void invisibleClosure(void Function() fun) {
  @pragma('vm:invisible')
  invisibleInner() {
    print('invisibleInner');
    fun();
  }

  invisibleInner();
}

main() {}
