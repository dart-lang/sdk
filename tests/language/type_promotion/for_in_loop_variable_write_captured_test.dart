// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a variable declared by a for-in loop can be promoted inside the
// loop even if a closure later in the loop body writes to it.
//
// Each iteration of the loop gets a fresh copy of the loop variable, so a
// closure created in one iteration can only write to that iteration's copy.
// Therefore the closure can't invalidate a promotion that happens in the same
// iteration before the closure is created, nor can it invalidate promotions in
// other iterations.

import 'package:expect/expect.dart';
import 'package:expect/static_type_helper.dart';

void statementWriteCapturedLater(List<Object?> xs) {
  var closures = <void Function()>[];
  for (var x in xs) {
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      // Invoking closures from earlier iterations doesn't affect `x`.
      for (var closure in closures) {
        closure();
      }
      Expect.isTrue(x.isEven);
    }
    closures.add(() {
      x = null;
    });
  }
}

void statementWriteCapturedEarlier(List<Object?> xs) {
  for (var x in xs) {
    () {
      x = null;
    };
    if (x is int) {
      x.expectStaticType<Exactly<Object?>>();
    }
  }
}

void statementWriteCapturedInNestedLoop(List<Object?> xs) {
  for (var x in xs) {
    for (var i = 0; i < 2; i++) {
      // A closure created in an earlier iteration of the inner loop writes the
      // same copy of `x`, so `x` is considered write captured here and does
      // not promote.
      if (x is int) {
        x.expectStaticType<Exactly<Object?>>();
      }
      () {
        x = null;
      };
    }
  }
}

void identifierWriteCaptured(List<Object?> xs) {
  // In this form, every iteration assigns to the same variable, so the
  // promotion must be invalidated.
  Object? x;
  for (x in xs) {
    if (x is int) {
      x.expectStaticType<Exactly<Object?>>();
    }
    () {
      x = null;
    };
  }
}

Future<void> asyncStatementWriteCapturedLater(Stream<Object?> xs) async {
  await for (var x in xs) {
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
    }
    () {
      x = null;
    };
  }
}

void listElementWriteCapturedLater(List<Object?> xs) {
  [
    for (var x in xs) ...[
      if (x is int) x.expectStaticType<Exactly<int>>(),
      () {
        x = null;
      },
    ],
  ];
}

void listElementWriteCapturedEarlier(List<Object?> xs) {
  [
    for (var x in xs) ...[
      () {
        x = null;
      },
      if (x is int) x.expectStaticType<Exactly<Object?>>(),
    ],
  ];
}

void setElementWriteCapturedLater(List<Object?> xs) {
  <Object?>{
    for (var x in xs) ...[
      if (x is int) x.expectStaticType<Exactly<int>>(),
      () {
        x = null;
      },
    ],
  };
}

void mapElementWriteCapturedLater(List<Object?> xs) {
  <Object?, Object?>{
    for (var x in xs) ...{
      if (x is int) x.expectStaticType<Exactly<int>>(): null,
      () {
        x = null;
      }: null,
    },
  };
}

main() async {
  statementWriteCapturedLater([0, null, 2]);
  statementWriteCapturedEarlier([0, null]);
  statementWriteCapturedInNestedLoop([0, null]);
  identifierWriteCaptured([0, null]);
  await asyncStatementWriteCapturedLater(Stream.fromIterable([0, null]));
  listElementWriteCapturedLater([0, null]);
  listElementWriteCapturedEarlier([0, null]);
  setElementWriteCapturedLater([0, null]);
  mapElementWriteCapturedLater([0, null]);
}
