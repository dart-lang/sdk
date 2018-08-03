// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

import 'dart:collection';

/**
 * We represent the current stack trace by an integer. From time to time we
 * increment the variable. This corresponds to a new stack trace.
 */
int stackTrace = 0;
List restoredStackTrace = [];

List events = [];

ZoneCallback<R> debugZoneRegisterCallback<R>(
    Zone self, ZoneDelegate parent, Zone origin, R f()) {
  List savedTrace = [stackTrace]..addAll(restoredStackTrace);
  return parent.registerCallback(origin, () {
    restoredStackTrace = savedTrace;
    return f();
  });
}

ZoneUnaryCallback<R, T> debugZoneRegisterUnaryCallback<R, T>(
    Zone self, ZoneDelegate parent, Zone origin, R f(T arg)) {
  List savedTrace = [stackTrace]..addAll(restoredStackTrace);
  return parent.registerUnaryCallback(origin, (arg) {
    restoredStackTrace = savedTrace;
    return f(arg);
  });
}

T debugZoneRun<T>(Zone self, ZoneDelegate parent, Zone origin, T f()) {
  stackTrace++;
  restoredStackTrace = [];
  return parent.run(origin, f);
}

R debugZoneRunUnary<R, T>(
    Zone self, ZoneDelegate parent, Zone origin, R f(T arg), T arg) {
  stackTrace++;
  restoredStackTrace = [];
  return parent.runUnary(origin, f, arg);
}

List expectedDebugTrace;

void debugUncaughtHandler(
    Zone self, ZoneDelegate parent, Zone origin, error, StackTrace stackTrace) {
  events.add("handling uncaught error $error");
  Expect.listEquals(expectedDebugTrace, restoredStackTrace);
  // Suppress the error and don't propagate to parent.
}

const DEBUG_SPECIFICATION = const ZoneSpecification(
    registerCallback: debugZoneRegisterCallback,
    registerUnaryCallback: debugZoneRegisterUnaryCallback,
    run: debugZoneRun,
    runUnary: debugZoneRunUnary,
    handleUncaughtError: debugUncaughtHandler);

main() {
  Completer done = new Completer();

  // runGuarded calls run, captures the synchronous error (if any) and
  // gives that one to handleUncaughtError.

  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked;
  forked = Zone.current.fork(specification: DEBUG_SPECIFICATION);

  asyncStart();

  int openTests = 0;

  openTests++;
  forked.run(() {
    int forkTrace = stackTrace;
    scheduleMicrotask(() {
      int scheduleMicrotaskTrace = stackTrace;
      scheduleMicrotask(() {
        expectedDebugTrace = [scheduleMicrotaskTrace, forkTrace];
        openTests--;
        if (openTests == 0) {
          done.complete();
        }
        throw "foo";
      });
      expectedDebugTrace = [forkTrace];
      throw "bar";
    });
  });

  Expect.listEquals([], restoredStackTrace);
  Zone forked2 = forked.fork();
  Zone forked3 = forked2.fork();
  int fork2Trace;
  int fork3Trace;
  var f2;
  var globalTrace = stackTrace;
  var f = forked3.bindCallback(() {
    Expect.identical(forked3, Zone.current);
    fork2Trace = stackTrace;
    f2 = forked2.bindCallback(() {
      Expect.identical(forked2, Zone.current);
      Expect.listEquals([fork2Trace, globalTrace], restoredStackTrace);
      fork3Trace = stackTrace;
      openTests--;
      if (openTests == 0) {
        done.complete();
      }
      scheduleMicrotask(() {
        expectedDebugTrace = [fork3Trace, fork2Trace, globalTrace];
        throw "gee";
      });
    });
  });
  openTests++;
  f();
  f2();

  done.future.whenComplete(() {
    // We don't really care for the order.
    events.sort();
    Expect.listEquals([
      "handling uncaught error bar",
      "handling uncaught error foo",
      "handling uncaught error gee"
    ], events);
    asyncEnd();
  });
}
