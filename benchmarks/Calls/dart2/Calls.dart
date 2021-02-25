// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Micro-benchmarks for sync/sync*/async/async* functionality.

// @dart=2.9

import 'dart:async';

const int iterationLimitAsync = 200;
const int sumOfIterationLimitAsync =
    iterationLimitAsync * (iterationLimitAsync - 1) ~/ 2;

const int iterationLimitSync = 5000;
const int sumOfIterationLimitSync =
    iterationLimitSync * (iterationLimitSync - 1) ~/ 2;

Future main() async {
  final target = Target();
  final target2 = Target2();
  final target3 = Target3();

  // Ensure the call sites will have another target in the ICData.
  await performAwaitCallsClosureTargetPolymorphic(returnAsync);
  await performAwaitCallsClosureTargetPolymorphic(returnFuture);
  await performAwaitCallsClosureTargetPolymorphic(returnFutureOr);
  await performAwaitAsyncCallsInstanceTargetPolymorphic(target);
  await performAwaitAsyncCallsInstanceTargetPolymorphic(target2);
  await performAwaitAsyncCallsInstanceTargetPolymorphic(target3);
  await performAwaitFutureCallsInstanceTargetPolymorphic(target);
  await performAwaitFutureCallsInstanceTargetPolymorphic(target2);
  await performAwaitFutureCallsInstanceTargetPolymorphic(target3);
  await performAwaitFutureOrCallsInstanceTargetPolymorphic(target);
  await performAwaitFutureOrCallsInstanceTargetPolymorphic(target2);
  await performAwaitFutureOrCallsInstanceTargetPolymorphic(target3);
  performSyncCallsInstanceTargetPolymorphic(target);
  performSyncCallsInstanceTargetPolymorphic(target2);
  performSyncCallsInstanceTargetPolymorphic(target3);
  await performAwaitAsyncCallsInstanceTargetPolymorphicManyAwaits(target);
  await performAwaitAsyncCallsInstanceTargetPolymorphicManyAwaits(target2);
  await performAwaitAsyncCallsInstanceTargetPolymorphicManyAwaits(target3);

  await performAwaitForIterationPolymorphic(generateNumbersAsyncStar);
  await performAwaitForIterationPolymorphic(generateNumbersAsyncStar2);
  await performAwaitForIterationPolymorphic(generateNumbersManualAsync);
  await performAwaitForIterationPolymorphic(generateNumbersAsyncStarManyYields);
  performSyncIterationPolymorphic(generateNumbersSyncStar);
  performSyncIterationPolymorphic(generateNumbersSyncStar2);
  performSyncIterationPolymorphic(generateNumbersManual);
  performSyncIterationPolymorphic(generateNumbersSyncStarManyYields);

  await AsyncCallBenchmark('Calls.AwaitAsyncCall', performAwaitAsyncCalls)
      .report();
  await AsyncCallBenchmark('Calls.AwaitAsyncCallClosureTargetPolymorphic',
      () => performAwaitCallsClosureTargetPolymorphic(returnAsync)).report();
  await AsyncCallBenchmark('Calls.AwaitAsyncCallInstanceTargetPolymorphic',
      () => performAwaitAsyncCallsInstanceTargetPolymorphic(target)).report();

  await AsyncCallBenchmark('Calls.AwaitFutureCall', performAwaitFutureCalls)
      .report();
  await AsyncCallBenchmark('Calls.AwaitFutureCallClosureTargetPolymorphic',
      () => performAwaitCallsClosureTargetPolymorphic(returnFuture)).report();
  await AsyncCallBenchmark('Calls.AwaitFutureCallInstanceTargetPolymorphic',
      () => performAwaitFutureCallsInstanceTargetPolymorphic(target)).report();

  await AsyncCallBenchmark('Calls.AwaitFutureOrCall', performAwaitFutureOrCalls)
      .report();
  await AsyncCallBenchmark('Calls.AwaitFutureOrCallClosureTargetPolymorphic',
      () => performAwaitCallsClosureTargetPolymorphic(returnFutureOr)).report();
  await AsyncCallBenchmark('Calls.AwaitFutureOrCallInstanceTargetPolymorphic',
          () => performAwaitFutureOrCallsInstanceTargetPolymorphic(target))
      .report();
  await AsyncCallBenchmark(
          'Calls.AwaitFutureOrCallInstanceTargetPolymorphicManyAwaits',
          () =>
              performAwaitAsyncCallsInstanceTargetPolymorphicManyAwaits(target))
      .report();

  await AsyncCallBenchmark('Calls.AwaitForAsyncStarStreamPolymorphic',
          () => performAwaitForIterationPolymorphic(generateNumbersAsyncStar))
      .report();
  await AsyncCallBenchmark(
      'Calls.AwaitForAsyncStarStreamPolymorphicManyYields',
      () => performAwaitForIterationPolymorphic(
          generateNumbersAsyncStarManyYields)).report();
  await AsyncCallBenchmark('Calls.AwaitForManualStreamPolymorphic',
          () => performAwaitForIterationPolymorphic(generateNumbersManualAsync))
      .report();

  SyncCallBenchmark('Calls.SyncCall', performSyncCalls).report();
  SyncCallBenchmark('Calls.SyncCallClosureTarget',
      () => performSyncCallsClosureTarget(returnSync)).report();
  SyncCallBenchmark('Calls.SyncCallInstanceTargetPolymorphic',
      () => performSyncCallsInstanceTargetPolymorphic(target)).report();

  SyncCallBenchmark('Calls.IterableSyncStarIterablePolymorphic',
      () => performSyncIterationPolymorphic(generateNumbersSyncStar)).report();
  SyncCallBenchmark('Calls.IterableManualIterablePolymorphic',
      () => performSyncIterationPolymorphic(generateNumbersManual)).report();
  SyncCallBenchmark(
      'Calls.IterableManualIterablePolymorphicManyYields',
      () => performSyncIterationPolymorphic(
          generateNumbersSyncStarManyYields)).report();
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> performAwaitCallsClosureTargetPolymorphic(
    FutureOr<int> Function(int) fun) async {
  int sum = 0;
  for (int i = 0; i < iterationLimitAsync; ++i) {
    sum += await fun(i);
  }
  if (sum != sumOfIterationLimitAsync) throw 'BUG';
  return iterationLimitAsync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> performAwaitAsyncCallsInstanceTargetPolymorphic(
    Target target) async {
  int sum = 0;
  for (int i = 0; i < iterationLimitAsync; ++i) {
    sum += await target.returnAsync(i);
  }
  if (sum != sumOfIterationLimitAsync) throw 'BUG';
  return iterationLimitAsync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> performAwaitFutureCallsInstanceTargetPolymorphic(
    Target target) async {
  int sum = 0;
  for (int i = 0; i < iterationLimitAsync; ++i) {
    sum += await target.returnFuture(i);
  }
  if (sum != sumOfIterationLimitAsync) throw 'BUG';
  return iterationLimitAsync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> performAwaitFutureOrCallsInstanceTargetPolymorphic(
    Target target) async {
  int sum = 0;
  for (int i = 0; i < iterationLimitAsync; ++i) {
    sum += await target.returnFutureOr(i);
  }
  if (sum != sumOfIterationLimitAsync) throw 'BUG';
  return iterationLimitAsync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> performAwaitAsyncCalls() async {
  int sum = 0;
  for (int i = 0; i < iterationLimitAsync; ++i) {
    sum += await returnAsync(i);
  }
  if (sum != sumOfIterationLimitAsync) throw 'BUG';
  return iterationLimitAsync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> performAwaitFutureCalls() async {
  int sum = 0;
  for (int i = 0; i < iterationLimitAsync; ++i) {
    sum += await returnFuture(i);
  }
  if (sum != sumOfIterationLimitAsync) throw 'BUG';
  return iterationLimitAsync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> performAwaitFutureOrCalls() async {
  int sum = 0;
  for (int i = 0; i < iterationLimitAsync; ++i) {
    sum += await returnFutureOr(i);
  }
  if (sum != sumOfIterationLimitAsync) throw 'BUG';
  return iterationLimitAsync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> performAwaitAsyncCallsInstanceTargetPolymorphicManyAwaits(
    Target t) async {
  int sum = 0;
  int i = 0;

  final int blockLimit = iterationLimitAsync - (iterationLimitAsync % 80);
  while (i < blockLimit) {
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
    sum += await t.returnAsync(i++);
  }

  while (i < iterationLimitAsync) {
    sum += await t.returnAsync(i++);
  }

  if (sum != sumOfIterationLimitAsync) throw 'BUG';

  return iterationLimitAsync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> performAwaitForIterationPolymorphic(
    Stream<int> Function(int) fun) async {
  int sum = 0;
  await for (int value in fun(iterationLimitAsync)) {
    sum += value;
  }
  if (sum != sumOfIterationLimitAsync) throw 'BUG';
  return iterationLimitAsync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
int performSyncCallsClosureTarget(int Function(int) fun) {
  int sum = 0;
  for (int i = 0; i < iterationLimitSync; ++i) {
    sum += fun(i);
  }
  if (sum != sumOfIterationLimitSync) throw 'BUG';
  return iterationLimitSync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
int performSyncCallsInstanceTargetPolymorphic(Target target) {
  int sum = 0;
  for (int i = 0; i < iterationLimitSync; ++i) {
    sum += target.returnSync(i);
  }
  if (sum != sumOfIterationLimitSync) throw 'BUG';
  return iterationLimitSync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
int performSyncCalls() {
  int sum = 0;
  for (int i = 0; i < iterationLimitSync; ++i) {
    sum += returnSync(i);
  }
  if (sum != sumOfIterationLimitSync) throw 'BUG';
  return iterationLimitSync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
int performSyncIterationPolymorphic(Iterable<int> Function(int) fun) {
  int sum = 0;
  for (int value in fun(iterationLimitSync)) {
    sum += value;
  }
  if (sum != sumOfIterationLimitSync) throw 'BUG';
  return iterationLimitSync;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
FutureOr<int> returnFutureOr(int i) => i;

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> returnFuture(int i) => Future.value(i);

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Future<int> returnAsync(int i) async => i;

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Stream<int> generateNumbersAsyncStar(int limit) async* {
  for (int i = 0; i < limit; ++i) {
    yield i;
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Stream<int> generateNumbersAsyncStar2(int limit) async* {
  for (int i = 0; i < limit; ++i) {
    yield i;
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Stream<int> generateNumbersManualAsync(int limit) {
  int current = 0;
  final controller = StreamController<int>(sync: true);
  void emit() {
    while (true) {
      if (controller.isPaused || !controller.hasListener) return;
      if (current < limit) {
        controller.add(current++);
      } else {
        controller.close();
        return;
      }
    }
  }

  void run() {
    scheduleMicrotask(emit);
  }

  controller.onListen = run;
  controller.onResume = run;

  return controller.stream;
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
int returnSync(int i) => i;

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Iterable<int> generateNumbersSyncStar(int limit) sync* {
  for (int i = 0; i < limit; ++i) {
    yield i;
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Iterable<int> generateNumbersSyncStar2(int limit) sync* {
  for (int i = 0; i < limit; ++i) {
    yield i;
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Iterable<int> generateNumbersManual(int limit) =>
    Iterable<int>.generate(limit, (int i) => i);

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Iterable<int> generateNumbersSyncStarManyYields(int limit) sync* {
  int i = 0;

  final int blockLimit = limit - (limit % (20 * 7));
  while (i < blockLimit) {
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
  }

  while (i < limit) {
    yield i++;
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Stream<int> generateNumbersAsyncStarManyYields(int limit) async* {
  int i = 0;

  final int blockLimit = limit - (limit % (20 * 7));
  while (i < blockLimit) {
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
    yield i++;
  }

  while (i < limit) {
    yield i++;
  }
}

class Target {
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  FutureOr<int> returnFutureOr(int i) => i;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Future<int> returnFuture(int i) => Future.value(i);

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Future<int> returnAsync(int i) async => i;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  int returnSync(int i) => i;
}

class Target2 extends Target {
  @override
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  FutureOr<int> returnFutureOr(int i) => i;

  @override
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Future<int> returnFuture(int i) => Future.value(i);

  @override
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Future<int> returnAsync(int i) async => i;

  @override
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  int returnSync(int i) => i;
}

class Target3 extends Target {
  @override
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  FutureOr<int> returnFutureOr(int i) => i;

  @override
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Future<int> returnFuture(int i) => Future.value(i);

  @override
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Future<int> returnAsync(int i) async => i;

  @override
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  int returnSync(int i) => i;
}

typedef PerformSyncCallsFunction = int Function();
typedef PerformAsyncCallsFunction = Future<int> Function();

class SyncCallBenchmark {
  final String name;
  final PerformSyncCallsFunction performCalls;

  SyncCallBenchmark(this.name, this.performCalls);

  // Returns the number of nanoseconds per call.
  double measureFor(Duration duration) {
    final sw = Stopwatch()..start();
    final durationInMicroseconds = duration.inMicroseconds;

    int numberOfCalls = 0;
    int totalMicroseconds = 0;
    do {
      numberOfCalls += performCalls();
      totalMicroseconds = sw.elapsedMicroseconds;
    } while (totalMicroseconds < durationInMicroseconds);

    final int totalNanoseconds = sw.elapsed.inMicroseconds * 1000;
    return totalNanoseconds / numberOfCalls;
  }

  // Runs warmup phase, runs benchmark and reports result.
  void report() {
    // Warmup for 200 ms.
    measureFor(const Duration(milliseconds: 100));

    // Run benchmark for 2 seconds.
    final double nsPerCall = measureFor(const Duration(seconds: 2));

    // Report result.
    print('$name(RunTimeRaw): $nsPerCall ns.');
  }
}

class AsyncCallBenchmark {
  final String name;
  final PerformAsyncCallsFunction performCalls;

  AsyncCallBenchmark(this.name, this.performCalls);

  // Returns the number of nanoseconds per call.
  Future<double> measureFor(Duration duration) async {
    final sw = Stopwatch()..start();
    final durationInMicroseconds = duration.inMicroseconds;

    int numberOfCalls = 0;
    int totalMicroseconds = 0;
    do {
      numberOfCalls += await performCalls();
      totalMicroseconds = sw.elapsedMicroseconds;
    } while (totalMicroseconds < durationInMicroseconds);

    final int totalNanoseconds = sw.elapsed.inMicroseconds * 1000;
    return totalNanoseconds / numberOfCalls;
  }

  // Runs warmup phase, runs benchmark and reports result.
  Future report() async {
    // Warmup for 100 ms.
    await measureFor(const Duration(milliseconds: 100));

    // Run benchmark for 2 seconds.
    final double nsPerCall = await measureFor(const Duration(seconds: 2));

    // Report result.
    print('$name(RunTimeRaw): $nsPerCall ns.');
  }
}
