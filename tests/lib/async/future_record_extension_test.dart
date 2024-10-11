// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import 'package:expect/async_helper.dart';
import "package:expect/expect.dart";

final fi = Future<int>.value(2);
final fb = Future<bool>.value(true);
final fs = Future<String>.value("s");
final ie = StateError("ie error");
final be = StateError("be error");
final se = StateError("se error");
final stie = StackTrace.fromString("ie stack");
final stbe = StackTrace.fromString("be stack");
final stse = StackTrace.fromString("se stack");
final fie = Future<int>.error(ie, stie)..ignore();
final fbe = Future<bool>.error(be, stbe)..ignore();
final fse = Future<String>.error(se, stse)..ignore();
final fsn = Completer<String>().future; // Never completes.
final errorStackMapping = {ie: stie, be: stbe, se: stse};

void main() async {
  asyncStart();

  {
    // 2-tuple `wait` getter.

    // No error.
    var r = await (fi, fb).wait;
    Expect.equals((2, true), r);

    // Some error.
    try {
      await (fi, fbe).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<(int?, bool?),
        (AsyncError?, AsyncError?)> catch (e, s) {
      Expect.equals((2, null), e.values);
      Expect.isNull(e.errors.$1);
      Expect.equals(be, e.errors.$2?.error);
      checkDefaultError(e, 1, [be]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }

    // All error.
    try {
      await (fie, fbe).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<(int?, bool?),
        (AsyncError?, AsyncError?)> catch (e, s) {
      Expect.equals((null, null), e.values);
      Expect.equals(ie, e.errors.$1?.error);
      Expect.equals(be, e.errors.$2?.error);
      checkDefaultError(e, 2, [ie, be]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }
  }

  {
    // 3-tuple `wait` getter.

    // No error.
    var r = await (fb, fs, fi).wait;
    Expect.equals((true, "s", 2), r);

    // Some error.
    try {
      await (fb, fse, fi).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<(bool?, String?, int?),
        (AsyncError?, AsyncError?, AsyncError?)> catch (e, s) {
      Expect.equals((true, null, 2), e.values);
      Expect.isNull(e.errors.$1);
      Expect.equals(se, e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      checkDefaultError(e, 1, [se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }

    // All error.
    try {
      await (fbe, fse, fie).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<(bool?, String?, int?),
        (AsyncError?, AsyncError?, AsyncError?)> catch (e, s) {
      Expect.equals((null, null, null), e.values);
      Expect.equals(be, e.errors.$1?.error);
      Expect.equals(se, e.errors.$2?.error);
      Expect.equals(ie, e.errors.$3?.error);
      checkDefaultError(e, 3, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }
  }

  {
    // 4-tuple `wait` getter.

    // No error.
    var r = await (fs, fi, fb, fs).wait;
    Expect.equals(("s", 2, true, "s"), r);

    // Some error.
    try {
      await (fs, fie, fb, fse).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<(String?, int?, bool?, String?),
        (AsyncError?, AsyncError?, AsyncError?, AsyncError?)> catch (e, s) {
      Expect.equals(("s", null, true, null), e.values);
      Expect.isNull(e.errors.$1);
      Expect.equals(ie, e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals(se, e.errors.$4?.error);
      checkDefaultError(e, 2, [ie, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }

    // All error.
    try {
      await (fse, fie, fbe, fse).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<(String?, int?, bool?, String?),
        (AsyncError?, AsyncError?, AsyncError?, AsyncError?)> catch (e, s) {
      Expect.equals((null, null, null, null), e.values);
      Expect.equals(se, e.errors.$1?.error);
      Expect.equals(ie, e.errors.$2?.error);
      Expect.equals(be, e.errors.$3?.error);
      Expect.equals(se, e.errors.$4?.error);
      checkDefaultError(e, 4, [se, ie, be]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }
  }

  {
    // 5-tuple `wait` getter.

    // No error.
    var r = await (fi, fb, fs, fi, fb).wait;
    Expect.equals((2, true, "s", 2, true), r);

    // Some error.
    try {
      await (fi, fbe, fs, fie, fb).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (int?, bool?, String?, int?, bool?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals((2, null, "s", null, true), e.values);
      Expect.isNull(e.errors.$1);
      Expect.equals(be, e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals(ie, e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
      checkDefaultError(e, 2, [ie, be]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }

    // All error.
    try {
      await (fie, fbe, fse, fie, fbe).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (int?, bool?, String?, int?, bool?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals((null, null, null, null, null), e.values);
      Expect.equals(ie, e.errors.$1?.error);
      Expect.equals(be, e.errors.$2?.error);
      Expect.equals(se, e.errors.$3?.error);
      Expect.equals(ie, e.errors.$4?.error);
      Expect.equals(be, e.errors.$5?.error);
      checkDefaultError(e, 5, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }
  }

  {
    // 6-tuple `wait` getter.

    // No error.
    var r = await (fb, fs, fi, fb, fs, fi).wait;
    Expect.equals((true, "s", 2, true, "s", 2), r);

    // Some error.
    try {
      await (fb, fse, fi, fbe, fs, fie).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (bool?, String?, int?, bool?, String?, int?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals((true, null, 2, null, "s", null), e.values);
      Expect.isNull(e.errors.$1);
      Expect.equals(se, e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals(be, e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
      Expect.equals(ie, e.errors.$6?.error);
      checkDefaultError(e, 3, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }

    // All error.
    try {
      await (fbe, fse, fie, fbe, fse, fie).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (bool?, String?, int?, bool?, String?, int?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals((null, null, null, null, null, null), e.values);
      Expect.equals(be, e.errors.$1?.error);
      Expect.equals(se, e.errors.$2?.error);
      Expect.equals(ie, e.errors.$3?.error);
      Expect.equals(be, e.errors.$4?.error);
      Expect.equals(se, e.errors.$5?.error);
      Expect.equals(ie, e.errors.$6?.error);
      checkDefaultError(e, 6, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }
  }

  {
    // 7-tuple `wait` getter.

    // No error.
    var r = await (fs, fi, fb, fs, fi, fb, fs).wait;
    Expect.equals(("s", 2, true, "s", 2, true, "s"), r);

    // Some error.
    try {
      await (fs, fie, fb, fse, fi, fbe, fs).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (String?, int?, bool?, String?, int?, bool?, String?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals(("s", null, true, null, 2, null, "s"), e.values);
      Expect.isNull(e.errors.$1);
      Expect.equals(ie, e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals(se, e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
      Expect.equals(be, e.errors.$6?.error);
      Expect.isNull(e.errors.$7);
      checkDefaultError(e, 3, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }

    // All error.
    try {
      await (fse, fie, fbe, fse, fie, fbe, fse).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (String?, int?, bool?, String?, int?, bool?, String?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals((null, null, null, null, null, null, null), e.values);
      Expect.equals(se, e.errors.$1?.error);
      Expect.equals(ie, e.errors.$2?.error);
      Expect.equals(be, e.errors.$3?.error);
      Expect.equals(se, e.errors.$4?.error);
      Expect.equals(ie, e.errors.$5?.error);
      Expect.equals(be, e.errors.$6?.error);
      Expect.equals(se, e.errors.$7?.error);
      checkDefaultError(e, 7, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }
  }

  {
    // 8-tuple `wait` getter.

    // No error.
    var r = await (fi, fb, fs, fi, fb, fs, fi, fb).wait;
    Expect.equals((2, true, "s", 2, true, "s", 2, true), r);

    // Some error.
    try {
      await (fi, fbe, fs, fie, fb, fse, fi, fbe).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (int?, bool?, String?, int?, bool?, String?, int?, bool?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals((2, null, "s", null, true, null, 2, null), e.values);
      Expect.isNull(e.errors.$1);
      Expect.equals(be, e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals(ie, e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
      Expect.equals(se, e.errors.$6?.error);
      Expect.isNull(e.errors.$7);
      Expect.equals(be, e.errors.$8?.error);
      checkDefaultError(e, 4, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }

    // All error.
    try {
      await (fie, fbe, fse, fie, fbe, fse, fie, fbe).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (int?, bool?, String?, int?, bool?, String?, int?, bool?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals((null, null, null, null, null, null, null, null), e.values);
      Expect.equals(ie, e.errors.$1?.error);
      Expect.equals(be, e.errors.$2?.error);
      Expect.equals(se, e.errors.$3?.error);
      Expect.equals(ie, e.errors.$4?.error);
      Expect.equals(be, e.errors.$5?.error);
      Expect.equals(se, e.errors.$6?.error);
      Expect.equals(ie, e.errors.$7?.error);
      Expect.equals(be, e.errors.$8?.error);
      checkDefaultError(e, 8, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }
  }

  {
    // 9-tuple `wait` getter.

    // No error.
    var r = await (fb, fs, fi, fb, fs, fi, fb, fs, fi).wait;
    Expect.equals((true, "s", 2, true, "s", 2, true, "s", 2), r);

    // Some error.
    try {
      await (fb, fse, fi, fbe, fs, fie, fb, fse, fi).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (bool?, String?, int?, bool?, String?, int?, bool?, String?, int?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals((true, null, 2, null, "s", null, true, null, 2), e.values);
      Expect.isNull(e.errors.$1);
      Expect.equals(se, e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals(be, e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
      Expect.equals(ie, e.errors.$6?.error);
      Expect.isNull(e.errors.$7);
      Expect.equals(se, e.errors.$8?.error);
      Expect.isNull(e.errors.$9);
      checkDefaultError(e, 4, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }

    // All error.
    try {
      await (fbe, fse, fie, fbe, fse, fie, fbe, fse, fie).wait;
      Expect.fail("Did not throw");
    } on ParallelWaitError<
        (bool?, String?, int?, bool?, String?, int?, bool?, String?, int?),
        (
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?,
          AsyncError?
        )> catch (e, s) {
      Expect.equals(
          (null, null, null, null, null, null, null, null, null), e.values);
      Expect.equals(be, e.errors.$1?.error);
      Expect.equals(se, e.errors.$2?.error);
      Expect.equals(ie, e.errors.$3?.error);
      Expect.equals(be, e.errors.$4?.error);
      Expect.equals(se, e.errors.$5?.error);
      Expect.equals(ie, e.errors.$6?.error);
      Expect.equals(be, e.errors.$7?.error);
      Expect.equals(se, e.errors.$8?.error);
      Expect.equals(ie, e.errors.$9?.error);
      checkDefaultError(e, 9, [ie, be, se]);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }
  }

  asyncEnd();
}

void checkDefaultError(
    ParallelWaitError error, int errorCount, List<Object> expectedErrors) {
  var toString = error.toString();
  if (errorCount > 1) {
    Expect.contains("ParallelWaitError($errorCount errors):", toString);
  } else {
    Expect.contains("ParallelWaitError:", toString);
  }
  for (var expectedError in expectedErrors) {
    if (toString.contains(expectedError.toString())) {
      var expectedStack = errorStackMapping[expectedError]!;
      Expect.equals(error.stackTrace.toString(), expectedStack.toString());
      return;
    }
  }
  Expect.fail("Error toString did not contain one of the expected errors");
}
