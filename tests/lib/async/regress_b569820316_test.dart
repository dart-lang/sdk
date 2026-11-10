// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

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
    await testReturnAwaitNestedFuture();
    await testReturnAwaitTiming();
    testFutureChainingStaticTypes();
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

  // Multi-statement and mixed-return bodies exercise dart2js's `AsyncLowering`
  // (`--simple-async-to-future`).
  Future<int> syncLocalVar(int x) async {
    final y = x + 1;
    return y;
  }

  Future<int> syncMixedAwaitAndValue(bool doAwait) async {
    if (doAwait) {
      return await Future<int>.syncValue(10);
    }
    return 42;
  }

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
      syncLocalVar(41);
      syncMixedAwaitAndValue(false);
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
  final fLocalVar = syncLocalVar(41);
  final fMixedValue = syncMixedAwaitAndValue(false);
  final f1 = syncValue();
  final f2 = syncFutureAsObject();
  scheduleMicrotask(() => log.add('microtask'));
  fLiteral.then((v) => log.add('thenLiteral: $v'));
  fConst.then((v) => log.add('thenConst: ${v.length}'));
  fEmpty.then((_) => log.add('thenEmpty'));
  fLocalVar.then((v) => log.add('thenLocalVar: $v'));
  fMixedValue.then((v) => log.add('thenMixedValue: $v'));
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
      'thenLocalVar: 42',
      'thenMixedValue: 42',
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

class _Base {
  const _Base();
}

class _ConstFuture<T> extends _Base implements Future<T> {
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
  const dynamic nonIntConstant = 'not an int';

  Future<void> failSync() async {
    throw 'sync boom';
  }

  Future<int> failDynamicConstReturn() async => nonIntConstant;
  Future<int> failCastConstReturn() async => nonIntConstant as int;

  final future = failSync();
  final implicitCastFuture = checkedImplicitDowncasts
      ? failDynamicConstReturn()
      : null;
  final explicitCastFuture = failCastConstReturn();
  log.add('after call');
  future.catchError((Object e) {
    log.add('caught: $e');
  });
  implicitCastFuture?.catchError((Object e) {
    log.add('caught implicit cast: ${e is TypeError}');
    return 0;
  });
  explicitCastFuture.catchError((Object e) {
    log.add('caught explicit cast: ${e is TypeError}');
    return 0;
  });

  Timer.run(() {
    Expect.listEquals([
      'after call',
      'caught: sync boom',
      if (checkedImplicitDowncasts) 'caught implicit cast: true',
      'caught explicit cast: true',
    ], log);
    completer.complete();
  });
  return completer.future;
}

Future<void> testZoneErrorCallback() {
  final completer = Completer<void>();
  final log = <String>[];
  final rootErrorFuture = Future<void>.error('root boom')..ignore();

  Future<void> failSync() async {
    throw 'sync boom';
  }

  Future<void> failAsync() async {
    await null;
    throw 'async boom';
  }

  Future<void> failReturnAwait() async {
    return await rootErrorFuture;
  }

  runZoned(
    () {
      failSync().catchError((Object e) {
        log.add('caught: $e');
      });
      failReturnAwait().catchError((Object e) {
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
      'caught: intercepted: root boom',
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

Future<void> testReturnAwaitNestedFuture() async {
  Future<Object> foo() async {
    final fi = Future<int>.syncValue(42);
    final ffi = Future<Future<int>>.syncValue(fi);
    return await ffi;
  }

  Expect.equals(42, await foo());
}

/// Tests that `return await` completes in a single microtask when awaiting a
/// synchronously completed future or non-future (rather than adding an extra
/// microtask as lowering `return await e` to `Future.value(e)` would), ensuring
/// consistent microtask timing across backends.
///
/// Intentionally written without `async`/`await` on the outer test function so
/// the test harness does not rely on the feature under test.
Future<void> testReturnAwaitTiming() {
  final completer = Completer<void>();
  final log = <String>[];

  Future<int> returnAwaitSyncFuture() async => await Future<int>.syncValue(10);
  Future<int> returnAwaitNonFuture() async => await 20;

  final f1 = returnAwaitSyncFuture();
  final f2 = returnAwaitNonFuture();
  scheduleMicrotask(() => log.add('microtask'));
  f1.then((v) => log.add('f1: $v'));
  f2.then((v) => log.add('f2: $v'));

  Timer.run(() {
    Expect.listEquals(['f1: 10', 'f2: 20', 'microtask'], log);
    completer.complete();
  });
  return completer.future;
}

extension type const _ExtFuture(Future<int> _) implements Object {}

/// Tests that `async` functions returning an expression whose static type does
/// not directly look like a [Future] (such as `FutureOr<int>`, `FutureOr<int>?`,
/// a promoted type parameter `T & Object`, an extension type erasing to
/// [Future], or a non-[Future] superclass implemented alongside [Future]) still
/// chain a runtime [Future] value into a fresh [Future] of the function's
/// return type.
///
/// If a compiler optimization wrongly concluded from the returned expression's
/// static type that it could never evaluate to a [Future] and lowered the body
/// to `Future<R>.sync(() => x)`, `Future.sync` would return `x` directly and it
/// would retain its more specific runtime type (e.g. `Future<int>` or
/// `_ConstFuture<_Base>`).
void testFutureChainingStaticTypes() {
  Future<Object> returnFutureOrSubtype(FutureOr<int> x) async => x;
  Future<int?> returnNullableFutureOr(FutureOr<int>? x) async => x;
  Future<Object> returnPromotedTypeParam<T>(T x) async {
    if (x is Object) return x;
    return 0;
  }

  Future<Object> returnExtensionType(_ExtFuture x) async => x;
  Future<_Base> returnSubclassFuture(_Base x) async => x;

  final intFuture = Future<int>.syncValue(42);
  Expect.notType<Future<int>>(returnFutureOrSubtype(intFuture));
  Expect.notType<Future<int>>(returnNullableFutureOr(intFuture));
  Expect.notType<Future<int>>(returnPromotedTypeParam<Object?>(intFuture));
  Expect.notType<Future<int>>(returnExtensionType(_ExtFuture(intFuture)));
  Expect.notType<_ConstFuture<_Base>>(
    returnSubclassFuture(const _ConstFuture<_Base>(_Base())),
  );
}
