// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test assumes the following low thresholds:
// maxAllocatedTypesInSetSpecialization = 4,
// maxInterfaceInvocationsPerSelector = 4.

class _FieldSet {
  bool get foo1 => int.parse('1') == 1;
}

class Message {
  _FieldSet? __fieldSet;
  _FieldSet get _fieldSet => __fieldSet!;
  bool get foo1 => _fieldSet.foo1;
}

class C1 extends Message {}

class C2 extends Message {}

class C3 extends Message {}

class C4 extends Message {}

class C5 extends Message {}

List<Message> buf = [];
Message anyMessage = buf[0];

allocateClasses() {
  C1();
  C2();
  C3();
  C4();
  C5();
}

use1(Message msg) {
  if (msg.foo1) {
    print('OK');
  }
}

use2(Message msg) {
  if (msg.foo1) {
    // This code should not be tree-shaken.
    print('OK');
  }
}

triggerInvalidation() {
  C1().__fieldSet = _FieldSet();
}

main(List<String> args) {
  allocateClasses();

  // foo1 uses 'virtual get [_fieldSet] (Message+)' invocation (1).
  use1(anyMessage);

  // Use multiple 'virtual get [_fieldSet] (*)' invocations so
  // selector 'virtual get [_fieldSet]' is approximated.
  C1().foo1;
  C2().foo1;
  C3().foo1;
  C4().foo1;
  C5().foo1;

  // Now foo1 started using approximate 'virtual get [_fieldSet] (Message+)'
  // invocation (2). If (1) and (2) are not the same, then (2) would
  // overwrite (1) in the dependencies and prevent correct invalidation.
  use2(C5());

  triggerInvalidation();
}
