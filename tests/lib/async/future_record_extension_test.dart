// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import '../../language/static_type_helper.dart';

void main() async {
  asyncStart();
  var fi = Future<int>.value(2);
  var fb = Future<bool>.value(true);
  var fs = Future<String>.value("s");
  var fie = Future<int>.error("ie", StackTrace.empty)..ignore();
  var fbe = Future<bool>.error("be", StackTrace.empty)..ignore();
  var fse = Future<String>.error("se", StackTrace.empty)..ignore();
  var fsn = Completer<String>().future; // Never completes.

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
      Expect.equals("be", e.errors.$2?.error);
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
      Expect.equals("ie", e.errors.$1?.error);
      Expect.equals("be", e.errors.$2?.error);
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
      Expect.equals("se", e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
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
      Expect.equals("be", e.errors.$1?.error);
      Expect.equals("se", e.errors.$2?.error);
      Expect.equals("ie", e.errors.$3?.error);
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
      Expect.equals("ie", e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals("se", e.errors.$4?.error);
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
      Expect.equals("se", e.errors.$1?.error);
      Expect.equals("ie", e.errors.$2?.error);
      Expect.equals("be", e.errors.$3?.error);
      Expect.equals("se", e.errors.$4?.error);
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
      Expect.equals("be", e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals("ie", e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
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
      Expect.equals("ie", e.errors.$1?.error);
      Expect.equals("be", e.errors.$2?.error);
      Expect.equals("se", e.errors.$3?.error);
      Expect.equals("ie", e.errors.$4?.error);
      Expect.equals("be", e.errors.$5?.error);
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
      Expect.equals("se", e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals("be", e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
      Expect.equals("ie", e.errors.$6?.error);
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
      Expect.equals("be", e.errors.$1?.error);
      Expect.equals("se", e.errors.$2?.error);
      Expect.equals("ie", e.errors.$3?.error);
      Expect.equals("be", e.errors.$4?.error);
      Expect.equals("se", e.errors.$5?.error);
      Expect.equals("ie", e.errors.$6?.error);
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
      Expect.equals("ie", e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals("se", e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
      Expect.equals("be", e.errors.$6?.error);
      Expect.isNull(e.errors.$7);
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
      Expect.equals("se", e.errors.$1?.error);
      Expect.equals("ie", e.errors.$2?.error);
      Expect.equals("be", e.errors.$3?.error);
      Expect.equals("se", e.errors.$4?.error);
      Expect.equals("ie", e.errors.$5?.error);
      Expect.equals("be", e.errors.$6?.error);
      Expect.equals("se", e.errors.$7?.error);
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
      Expect.equals("be", e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals("ie", e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
      Expect.equals("se", e.errors.$6?.error);
      Expect.isNull(e.errors.$7);
      Expect.equals("be", e.errors.$8?.error);
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
      Expect.equals("ie", e.errors.$1?.error);
      Expect.equals("be", e.errors.$2?.error);
      Expect.equals("se", e.errors.$3?.error);
      Expect.equals("ie", e.errors.$4?.error);
      Expect.equals("be", e.errors.$5?.error);
      Expect.equals("se", e.errors.$6?.error);
      Expect.equals("ie", e.errors.$7?.error);
      Expect.equals("be", e.errors.$8?.error);
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
      Expect.equals("se", e.errors.$2?.error);
      Expect.isNull(e.errors.$3);
      Expect.equals("be", e.errors.$4?.error);
      Expect.isNull(e.errors.$5);
      Expect.equals("ie", e.errors.$6?.error);
      Expect.isNull(e.errors.$7);
      Expect.equals("se", e.errors.$8?.error);
      Expect.isNull(e.errors.$9);
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
      Expect.equals("be", e.errors.$1?.error);
      Expect.equals("se", e.errors.$2?.error);
      Expect.equals("ie", e.errors.$3?.error);
      Expect.equals("be", e.errors.$4?.error);
      Expect.equals("se", e.errors.$5?.error);
      Expect.equals("ie", e.errors.$6?.error);
      Expect.equals("be", e.errors.$7?.error);
      Expect.equals("se", e.errors.$8?.error);
      Expect.equals("ie", e.errors.$9?.error);
    } on Object catch (e) {
      Expect.fail("Did not throw expected error: ${e.runtimeType}");
    }
  }

  asyncEnd();
}
