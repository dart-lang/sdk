// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

void main() {
  asyncStart();
  () async {
    await testValueCompletionAfterAwait();
    await testFutureAsValueCompletionAfterAwait();
    await testSyncValueCompletion();
    await testSyncValueReturnWithoutAwait();
    await testFutureChaining();
    await testErrorCompletionAfterAwait();
    await testSyncErrorCompletion();
    await testZoneErrorCallback();
    await testZoneCallbackRegistration();
    asyncEnd();
  }();
}

Future<void> testValueCompletionAfterAwait() {
  final completer = Completer<void>();
  final log = <String>[];

  Future<void> leaf() async {
    await null;
  }

  Future<void> mid() async {
    await leaf();
  }

  Future<void> top() async {
    await mid();
  }

  top().then((_) => log.add('top done'));
  var n = 0;
  void tick() {
    log.add('${n++}');
    if (n < 5) scheduleMicrotask(tick);
  }

  scheduleMicrotask(tick);
  Timer.run(() {
    Expect.listEquals(['top done', '0', '1', '2', '3', '4'], log);
    completer.complete();
  });
  return completer.future;
}

Future<void> testFutureAsValueCompletionAfterAwait() {
  final completer = Completer<void>();
  final log = <String>[];
  // Not a `Future<Object>`, so returning it from `leaf` completes with the
  // future as a value rather than chaining it.
  final nullFuture = Future<Object?>.syncValue(null);

  Future<Object> leaf() async {
    await null;
    return nullFuture;
  }

  Future<Object> mid() async {
    return await leaf();
  }

  Future<Object> top() async {
    return await mid();
  }

  top().then((v) => log.add('top done: ${identical(v, nullFuture)}'));
  var n = 0;
  void tick() {
    log.add('${n++}');
    if (n < 5) scheduleMicrotask(tick);
  }

  scheduleMicrotask(tick);
  Timer.run(() {
    Expect.listEquals(['top done: true', '0', '1', '2', '3', '4'], log);
    completer.complete();
  });
  return completer.future;
}

Future<void> testSyncValueCompletion() {
  final completer = Completer<void>();
  final log = <String>[];

  Future<int> leaf() async => 42;
  Future<int> mid() async => (await leaf()) + 1;
  Future<int> top() async => (await mid()) + 1;

  top().then((v) => log.add('top done: $v'));
  var n = 0;
  void tick() {
    log.add('${n++}');
    if (n < 5) scheduleMicrotask(tick);
  }

  scheduleMicrotask(tick);
  Timer.run(() {
    Expect.listEquals(['top done: 44', '0', '1', '2', '3', '4'], log);
    completer.complete();
  });
  return completer.future;
}

Future<void> testSyncValueReturnWithoutAwait() {
  final completer = Completer<void>();
  final log = <String>[];
  // Not a `Future<Object>`, so returning it from `syncFutureAsObject` completes
  // with the future as a value rather than chaining it.
  final nullFuture = Future<Object?>.syncValue(null);

  // Simple async functions returning literal/constant/implicit-null to exercise
  // dart2wasm's kernel recognition & lowering to `Future.syncValue`.
  Future<int> syncLiteral() async => 42;
  Future<List<int>> syncConst() async => const <int>[1, 2];
  Future<void> syncEmpty() async {}

  Future<int> syncValue() async {
    log.add('syncValue');
    return 42;
  }

  Future<Object> syncFutureAsObject() async {
    log.add('syncFutureAsObject');
    return nullFuture;
  }

  runZoned(
    () {
      syncLiteral();
      syncConst();
      syncEmpty();
      syncValue();
      syncFutureAsObject();
    },
    zoneSpecification: ZoneSpecification(
      scheduleMicrotask: (self, parent, zone, f) {
        log.add('unexpected microtask');
        parent.scheduleMicrotask(zone, f);
      },
    ),
  );

  final fLiteral = syncLiteral();
  final fConst = syncConst();
  final fEmpty = syncEmpty();
  final f1 = syncValue();
  final f2 = syncFutureAsObject();
  scheduleMicrotask(() => log.add('microtask'));
  fLiteral.then((v) => log.add('thenLiteral: $v'));
  fConst.then((v) => log.add('thenConst: ${v.length}'));
  fEmpty.then((_) => log.add('thenEmpty'));
  f1.then((v) => log.add('then1: $v'));
  f2.then((v) => log.add('then2: ${identical(v, nullFuture)}'));

  Timer.run(() {
    Expect.listEquals([
      'syncValue',
      'syncFutureAsObject',
      'syncValue',
      'syncFutureAsObject',
      'microtask',
      'thenLiteral: 42',
      'thenConst: 2',
      'thenEmpty',
      'then1: 42',
      'then2: true',
    ], log);
    completer.complete();
  });
  return completer.future;
}

Future<void> testFutureChaining() {
  final completer = Completer<void>();
  final log = <String>[];
  final completedFuture = Future<int>.value(42);

  Future<int> syncChain() async => completedFuture;
  Future<int> syncConstChain() async => const _ConstFuture<int>(42);

  Future<int> asyncChain() async {
    await null;
    return completedFuture;
  }

  final f1 = syncChain();
  final fConst = syncConstChain();
  final f2 = asyncChain();
  f1.then((v) => log.add('syncChain: $v'));
  fConst.then((v) => log.add('syncConstChain: $v'));
  f2.then((v) => log.add('asyncChain: $v'));

  var n = 0;
  void tick() {
    log.add('${n++}');
    if (n < 5) scheduleMicrotask(tick);
  }

  scheduleMicrotask(tick);
  Timer.run(() {
    Expect.listEquals([
      'syncChain: 42',
      'syncConstChain: 42',
      '0',
      'asyncChain: 42',
      '1',
      '2',
      '3',
      '4',
    ], log);
    completer.complete();
  });
  return completer.future;
}

class _ConstFuture<T> implements Future<T> {
  final T _value;
  const _ConstFuture(this._value);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => Future<T>.syncValue(_value).then(onValue, onError: onError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> testErrorCompletionAfterAwait() {
  final completer = Completer<void>();
  final log = <String>[];

  Future<void> leaf() async {
    await null;
    throw 'boom';
  }

  Future<void> mid() async {
    await leaf();
  }

  Future<void> top() async {
    try {
      await mid();
    } catch (e) {
      log.add('caught: $e');
    }
  }

  top().then((_) => log.add('top done'));
  var n = 0;
  void tick() {
    log.add('${n++}');
    if (n < 5) scheduleMicrotask(tick);
  }

  scheduleMicrotask(tick);
  Timer.run(() {
    Expect.listEquals([
      'caught: boom',
      'top done',
      '0',
      '1',
      '2',
      '3',
      '4',
    ], log);
    completer.complete();
  });
  return completer.future;
}

Future<void> testSyncErrorCompletion() {
  final completer = Completer<void>();
  final log = <String>[];

  Future<void> failSync() async {
    throw 'sync boom';
  }

  final future = failSync();
  log.add('after call');
  future.catchError((Object e) {
    log.add('caught: $e');
  });

  Timer.run(() {
    Expect.listEquals(['after call', 'caught: sync boom'], log);
    completer.complete();
  });
  return completer.future;
}

Future<void> testZoneErrorCallback() {
  final completer = Completer<void>();
  final log = <String>[];

  Future<void> failSync() async {
    throw 'sync boom';
  }

  Future<void> failAsync() async {
    await null;
    throw 'async boom';
  }

  runZoned(
    () {
      failSync().catchError((Object e) {
        log.add('caught: $e');
      });
      failAsync().catchError((Object e) {
        log.add('caught: $e');
        completer.complete();
      });
    },
    zoneSpecification: ZoneSpecification(
      errorCallback: (self, parent, zone, error, stackTrace) {
        return AsyncError('intercepted: $error', stackTrace);
      },
    ),
  );

  return completer.future.whenComplete(() {
    Expect.listEquals([
      'caught: intercepted: sync boom',
      'caught: intercepted: async boom',
    ], log);
  });
}

Future<void> testZoneCallbackRegistration() async {
  int registerCallbackCount = 0;
  int registerUnaryCallbackCount = 0;
  int registerBinaryCallbackCount = 0;

  final zone = Zone.current.fork(
    specification: ZoneSpecification(
      registerCallback: <R>(self, parent, zone, R Function() f) {
        registerCallbackCount++;
        return parent.registerCallback(zone, f);
      },
      registerUnaryCallback: <R, T>(self, parent, zone, R Function(T) f) {
        registerUnaryCallbackCount++;
        return parent.registerUnaryCallback(zone, f);
      },
      registerBinaryCallback:
          <R, T1, T2>(self, parent, zone, R Function(T1, T2) f) {
            registerBinaryCallbackCount++;
            return parent.registerBinaryCallback(zone, f);
          },
    ),
  );

  await zone.run(() async {
    await null;
    await Future.value(1);
    await Future.value(2);
  });

  // 3 microtasks scheduled in `zone` (`await null` and two `Future.value`
  // completions), and at most 1 unary + 1 binary continuation callback
  // registered once for the async closure (dart2js registers a single binary
  // continuation callback; VM, dart2wasm, and DDC register 1 unary + 1 binary).
  Expect.equals(3, registerCallbackCount);
  Expect.isTrue(registerUnaryCallbackCount <= 1);
  Expect.equals(1, registerBinaryCallbackCount);
}
