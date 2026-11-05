// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

// Prevent inlining and Binaryen duplicate-function-elimination so `exception1`
// and `exception2` remain distinct frames in stack traces when unminified.
@pragma('vm:never-inline')
@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
void exception1(String e) {
  if (identical(e, '1')) return;
  throw e;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
void exception2(String e) {
  if (identical(e, '2')) return;
  throw e;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
void doSyncThrow1() {
  try {
    exception1('outer');
  } on Object {
    try {
      exception2('inner');
    } on Object {
      // ignore
    }
    rethrow;
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
void doSyncThrow2() {
  try {
    exception2('outer');
  } on Object {
    try {
      exception1('inner');
    } on Object {
      try {
        exception1('more inner');
      } on Object {
        // ignore
      }
    }
    rethrow;
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
void doSyncThrow3() {
  try {
    exception1('outer');
  } on Object {
    try {
      // don't throw
    } on Object {
      try {
        // also don't throw
      } on Object {
        // ignore
      }
    }
    rethrow;
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
void doSyncThrow4() {
  try {
    exception1('outer');
  } on Object {
    try {
      exception2('inner');
    } on bool {}
    rethrow;
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
void doSyncThrowFinally() {
  try {
    exception1('outer');
  } finally {
    // empty finalizer
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
void doSyncThrowNestedFinally() {
  try {
    exception1('outer');
  } finally {
    try {
      exception2('inner');
    } on Object {
      // ignore
    }
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
List<String> testTryFinallyInLoop() {
  final log = <String>[];
  for (int i = 0; i < 4; i++) {
    label:
    try {
      log.add('try:$i');
      if (i == 0) {
        break label;
      }
      if (i == 1) {
        try {
          throw 'err';
        } finally {
          log.add('inner-finally:$i');
        }
      }
    } catch (e) {
      log.add('catch:$i:$e');
    } finally {
      log.add('finally:$i');
    }
    log.add('after:$i');
  }
  return log;
}

void main() {
  try {
    doSyncThrow1();
    Expect.fail('should throw');
  } catch (e, s) {
    Expect.equals(e, 'outer');
    if (symbolicUnminifiedStackTraces) {
      // Verify stack trace integrity of the rethrow when symbols are preserved
      Expect.isTrue('$s'.contains('exception1'));
      Expect.isTrue('$s'.contains('doSyncThrow1'));
    }
  }

  try {
    doSyncThrow2();
    Expect.fail('should throw');
  } catch (e, s) {
    Expect.equals(e, 'outer');
    if (symbolicUnminifiedStackTraces) {
      Expect.isTrue('$s'.contains('exception2'));
      Expect.isTrue('$s'.contains('doSyncThrow2'));
    }
  }

  try {
    doSyncThrow3();
    Expect.fail('should throw');
  } catch (e, s) {
    Expect.equals(e, 'outer');
    if (symbolicUnminifiedStackTraces) {
      Expect.isTrue('$s'.contains('exception1'));
      Expect.isTrue('$s'.contains('doSyncThrow3'));
    }
  }

  try {
    doSyncThrow4();
    Expect.fail('should throw');
  } catch (e, s) {
    Expect.equals(e, 'inner');
    if (symbolicUnminifiedStackTraces) {
      Expect.isTrue('$s'.contains('exception2'));
      Expect.isTrue('$s'.contains('doSyncThrow4'));
    }
  }

  try {
    doSyncThrowFinally();
    Expect.fail('should throw');
  } catch (e, s) {
    Expect.equals(e, 'outer');
    if (symbolicUnminifiedStackTraces) {
      Expect.isTrue('$s'.contains('exception1'));
      Expect.isTrue('$s'.contains('doSyncThrowFinally'));
    }
  }

  try {
    doSyncThrowNestedFinally();
    Expect.fail('should throw');
  } catch (e, s) {
    Expect.equals(e, 'outer');
    if (symbolicUnminifiedStackTraces) {
      Expect.isTrue('$s'.contains('exception1'));
      Expect.isTrue('$s'.contains('doSyncThrowNestedFinally'));
    }
  }

  Expect.listEquals([
    'try:0',
    'finally:0',
    'after:0',
    'try:1',
    'inner-finally:1',
    'catch:1:err',
    'finally:1',
    'after:1',
    'try:2',
    'finally:2',
    'after:2',
    'try:3',
    'finally:3',
    'after:3',
  ], testTryFinallyInLoop());
}
