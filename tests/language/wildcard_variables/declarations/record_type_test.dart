// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow positional record fields named `_` in record types.

// SharedOptions=--enable-experiment=wildcard-variables

import 'dart:async';

import 'package:expect/expect.dart';

typedef R = (int _, int _);

void main() {
  (int _, int _) record;
  record = (1, 2);
  Expect.equals(1, record.$1);
  Expect.equals(2, record.$2);

  R rType = (1, 2);
  Expect.equals(1, rType.$1);
  Expect.equals(2, rType.$2);

  // Has a named field (which cannot be `_`).
  (int _, int _, {int x}) recordX;
  recordX = (1, 2, x: 3);
  Expect.equals(1, recordX.$1);
  Expect.equals(2, recordX.$2);

  // In composite types.
  (int _, int _) functionReturn() => (1, 2);
  (int _, int _) Function() functionTypeReturn() => functionReturn;
  (int _, int _) functionArgument((int _, int _) _) => (1, 2);
  (int _, int _)? nullableType;
  FutureOr<(int _, int _)> futureOrType = record;
  List<(int _, int _)> listOfType = [(1, 2)];

  // In type tests, where it promotes.

  // True value that promotion cannot recognize.
  // Used to prevent promotion from affecting later tests.
  bool truth() => DateTime.now().millisecondsSinceEpoch > 0; //

  Object? maybeRecord = truth() ? record : "not a record";

  if (truth() && maybeRecord is (int _, int _)) {
    Expect.equals(1, maybeRecord.$1);
    Expect.equals(2, maybeRecord.$2);
  } else {
    Expect.fail("is check failed");
  }

  if (truth()) {
    maybeRecord as (int _, int _);
    Expect.equals(1, maybeRecord.$1);
    Expect.equals(2, maybeRecord.$2);
  }

  if (truth()) {
    (int _, int _) implicitDowncast = (maybeRecord as dynamic);
    Expect.equals(1, implicitDowncast.$1);
    Expect.equals(2, implicitDowncast.$2);
  }

  try {
    throw record;
  } on (int _, int _) catch (onClauseTest) {
    Expect.equals(1, onClauseTest.$1);
    Expect.equals(2, onClauseTest.$2);
  }

  // Type tests in patterns.
  switch (record as dynamic) {
    case R(:var $1, :var $2):
      Expect.equals(1, $1);
      Expect.equals(2, $2);
    default:
      Expect.fail("Not here!");
  }
  switch (record as dynamic) {
    case (int _, int _) pair:
      {
        // Occurs as type here, not pattern.
        Expect.equals(1, pair.$1);
        Expect.equals(2, pair.$2);
      }
    default:
      Expect.fail("Not here!");
  }
}
