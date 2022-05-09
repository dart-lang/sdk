// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'causal_stacks/utils.dart';

main() async {
  StackTrace trace = StackTrace.empty;

  A.visible(() => trace = StackTrace.current);
  await assertStack([
    r'^#0      main.<anonymous closure>',
    r'^#1      new A.visible',
    r'^#2      main',
    IGNORE_REMAINING_STACK,
  ], trace);

  A.invisible(() => trace = StackTrace.current);
  await assertStack([
    r'^#0      main.<anonymous closure>',
    r'^#1      main',
    IGNORE_REMAINING_STACK,
  ], trace);

  visible(() => trace = StackTrace.current);
  await assertStack([
    r'^#0      main.<anonymous closure>',
    r'^#1      visible',
    r'^#2      main',
    IGNORE_REMAINING_STACK,
  ], trace);

  invisible(() => trace = StackTrace.current);
  await assertStack([
    r'^#0      main.<anonymous closure>',
    r'^#1      main',
    IGNORE_REMAINING_STACK,
  ], trace);

  visibleClosure(() => trace = StackTrace.current);
  await assertStack([
    r'^#0      main.<anonymous closure>',
    r'^#1      visibleClosure.visibleInner',
    r'^#2      visibleClosure',
    r'^#3      main',
    IGNORE_REMAINING_STACK,
  ], trace);

  invisibleClosure(() => trace = StackTrace.current);
  await assertStack([
    r'^#0      main.<anonymous closure>',
    r'^#1      invisibleClosure',
    r'^#2      main',
    IGNORE_REMAINING_STACK,
  ], trace);
}

class A {
  A.visible(void Function() fun) {
    fun();
  }

  @pragma('vm:invisible')
  A.invisible(void Function() fun) {
    fun();
  }
}

void visible(void Function() fun) => fun();

@pragma('vm:invisible')
void invisible(void Function() fun) => fun();

void visibleClosure(void Function() fun) {
  visibleInner() {
    fun();
  }

  visibleInner();
}

void invisibleClosure(void Function() fun) {
  @pragma('vm:invisible')
  invisibleInner() {
    fun();
  }

  invisibleInner();
}
