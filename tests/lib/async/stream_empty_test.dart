// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test empty stream.
import "package:expect/expect.dart";
import "dart:async";
import 'package:async_helper/async_helper.dart';

main() async {
  await asyncTest(() async {
    // Is a `const` constructor.
    // Can be called with optional boolean to say whether broadcast or not.
    await asyncTest(() => emptyTest(const Stream<int>.empty(), true));
    await asyncTest(
        () => emptyTest(const Stream<int>.empty(broadcast: true), true));
    await asyncTest(
        () => emptyTest(const Stream<int>.empty(broadcast: false), false));

    // Check that the behavior is consistent with other empty multi-subscription
    // streams.
    await asyncTest(() => emptyTest(Stream<int>.fromIterable(<int>[]), false));
    await asyncTest(() =>
        emptyTest((StreamController<int>.broadcast()..close()).stream, true));
    await asyncTest(
        () => emptyTest(Stream<int>.multi((c) => c.close()), false));
  });
  await flushMicrotasks();
}

// Function which fails the test if it gets called.
void unreachable([a, b]) {
  Expect.fail("Unreachable");
}

/// Check that something happens once.
class Checker {
  bool checked = false;
  void check() {
    if (checked) Expect.fail("Checked more than once");
    checked = true;
  }
}

Future<void> emptyTest(Stream<int> s, bool broadcast) async {
  var checker = Checker();
  // Respects type parameter (not a `Stream<Never>`)
  Expect.notType<Stream<String>>(s);

  // Has the expected `isBroadcast`.
  Expect.equals(broadcast, s.isBroadcast);

  StreamSubscription<int> sub =
      s.listen(unreachable, onError: unreachable, onDone: checker.check);
  // Type parameter of subscription repspects stream.
  // Not a `StreamSubscription<Never>`.
  Expect.isFalse(sub is StreamSubscription<String>);

  Expect.isFalse(sub.isPaused);
  // Doesn't do callback immediately in response to listen.
  Expect.isFalse(checker.checked);
  await flushMicrotasks();
  // Completes eventually, after a microtask.
  Expect.isTrue(checker.checked);
  Expect.isFalse(sub.isPaused);

  // Can listen more than once, whether broadcast stream or not.
  checker = Checker();
  StreamSubscription<int> sub2 =
      s.listen(unreachable, onError: unreachable, onDone: checker.check);
  // Respects pauses.
  sub2.pause();
  Expect.isTrue(sub2.isPaused);
  sub2.pause();
  Expect.isTrue(sub2.isPaused);
  sub2.pause(Future<int>.value(0));
  Expect.isTrue(sub2.isPaused);

  await flushMicrotasks();
  Expect.isTrue(sub2.isPaused);
  Expect.isFalse(checker.checked);

  // Resumes when all pauses resumed.
  sub2.resume();
  Expect.isTrue(sub2.isPaused);
  await flushMicrotasks();
  Expect.isFalse(checker.checked);
  Expect.isTrue(sub2.isPaused);

  sub2.resume();
  Expect.isFalse(sub2.isPaused);
  await flushMicrotasks();
  Expect.isTrue(checker.checked);
  Expect.isFalse(sub2.isPaused);

  // Can't pause after done.
  sub2.pause(Future<int>.value(0));
  Expect.isFalse(sub2.isPaused);
  sub2.pause();
  Expect.isFalse(sub2.isPaused);

  // Respects cancel.
  var sub3 = s.listen(unreachable, onError: unreachable, onDone: unreachable);
  sub3.cancel();
  sub3.onDone(unreachable);
  Expect.isFalse(sub3.isPaused);
  await flushMicrotasks();
  Expect.isFalse(sub3.isPaused);

  // Can't pause after cancel
  sub3.pause();
  Expect.isFalse(sub3.isPaused);
  sub3.pause(Future<int>.value(0));
  Expect.isFalse(sub3.isPaused);
  // No errors.

  // Respects cancel while paused.
  var sub4 = s.listen(unreachable, onError: unreachable, onDone: unreachable);
  sub4.pause();
  sub4.cancel();
  sub4.onDone(unreachable);
  await flushMicrotasks();
  sub4.resume();
  await flushMicrotasks();

  // Check that the stream is zone-aware.
  // Registers onDone callback.
  var log = [];
  late final Zone zone;

  void callback1() {
    // Run in correct zone.
    Expect.equals(zone, Zone.current);
    log.add("don1");
  }

  void callback2() {
    // Run in correct zone.
    Expect.equals(zone, Zone.current);
    log.add("don2");
  }

  zone = Zone.current.fork(
      specification: ZoneSpecification(registerCallback: <R>(s, p, z, f) {
    if (f == callback1) log.add("reg1");
    if (f == callback2) log.add("reg2");
    return p.registerCallback<R>(z, f);
  }, run: <R>(s, p, z, f) {
    if (f == callback1) log.add("run1");
    if (f == callback2) log.add("run2");
    return p.run<R>(z, f);
  }));

  await zone.run(() async {
    var s = Stream<int>.empty();

    var sub = s.listen(unreachable, onError: unreachable, onDone: callback1);
    sub.onDone(callback2);
  });
  await flushMicrotasks();
  Expect.listEquals(["reg1", "reg2", "run2", "don2"], log);
}

Future flushMicrotasks() => new Future.delayed(Duration.zero);
