// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of various space-saving contractions of calls to
// `throwUnsupportedOperation`.

import 'dart:_foreign_helper' show ArrayFlags, HArrayFlagsCheck;

@pragma('dart2js:never-inline')
// The operation and verb are both elided.
/*member: indexSetter:function() {
  A.throwUnsupportedOperation(B.List_empty);
}*/
indexSetter() {
  HArrayFlagsCheck(const [], ArrayFlags.constant, ArrayFlags.unmodifiableCheck,
      '[]=', 'modify');
}

@pragma('dart2js:never-inline')
// The operation is reduced to an index but cannot be elided because it is
// followed by a non-elided verb.
/*member: indexSetterUnusualVerb:function() {
  A.throwUnsupportedOperation(B.List_empty, 0, "change contents of");
}*/
indexSetterUnusualVerb() {
  HArrayFlagsCheck(const [], ArrayFlags.constant, ArrayFlags.unmodifiableCheck,
      '[]=', 'change contents of');
}

@pragma('dart2js:never-inline')
// The verb is elided.
/*member: unusualOperationModify:function() {
  A.throwUnsupportedOperation(B.List_empty, "rub");
}*/
unusualOperationModify() {
  HArrayFlagsCheck(const [], ArrayFlags.constant, ArrayFlags.unmodifiableCheck,
      'rub', 'modify');
}

@pragma('dart2js:never-inline')
// The operation is left as a string and verb is
/*member: unusualOperationRemoveFrom:function() {
  A.throwUnsupportedOperation(B.List_empty, "rub", 1);
}*/
unusualOperationRemoveFrom() {
  HArrayFlagsCheck(const [], ArrayFlags.constant, ArrayFlags.unmodifiableCheck,
      'rub', 'remove from');
}

@pragma('dart2js:never-inline')
// The operation and verb are left as strings.
/*member: unusualOperationAndVerb:function() {
  A.throwUnsupportedOperation(B.List_empty, "rub", "burnish");
}*/
unusualOperationAndVerb() {
  HArrayFlagsCheck(const [], ArrayFlags.constant, ArrayFlags.unmodifiableCheck,
      'rub', 'burnish');
}

@pragma('dart2js:never-inline')
// The operation is reduced to an index and the verb is elided.
/*member: knownOperationModify:function() {
  A.throwUnsupportedOperation(B.List_empty, 10);
}*/
knownOperationModify() {
  HArrayFlagsCheck(const [], ArrayFlags.constant, ArrayFlags.unmodifiableCheck,
      'setUint16', 'modify');
}

@pragma('dart2js:never-inline')
// The operation and verb are combined to a single number.
/*member: knownOperationAndVerb:function() {
  A.throwUnsupportedOperation(B.List_empty, 16);
}*/
knownOperationAndVerb() {
  HArrayFlagsCheck(const [], ArrayFlags.constant, ArrayFlags.unmodifiableCheck,
      'removeWhere', 'remove from');
}

/*member: main:ignore*/
main() {
  indexSetter();
  indexSetterUnusualVerb();
  unusualOperationModify();
  unusualOperationRemoveFrom();
  unusualOperationAndVerb();
  knownOperationModify();
  knownOperationAndVerb();
}
