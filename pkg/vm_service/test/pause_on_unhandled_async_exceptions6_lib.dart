import 'dart:async';
import 'common/test_helper.dart';

Stream<int> _throwingStream1(String exceptionToThrow) async* {
  for (var i = 0; i < 10; i++) {
    yield i;
  }

  throw exceptionToThrow; // LINE_A
}

Stream<int> _throwingStream2(String exceptionToThrow) async* {
  await for (var e in _throwingStream1(exceptionToThrow)) /* LINE_AA */ {
    yield e;
  }
}

Stream<int> _throwingStream3(String exceptionToThrow) async* {
  yield* _throwingStream1(exceptionToThrow); // LINE_AB
}

final streamFactories = [
  _throwingStream1,
  _throwingStream2,
  _throwingStream3,
];

Future<void> testeeMain({
  bool shouldTestUncaught = true,
}) async {
  int testCaseId = 0;
  for (var makeStream in streamFactories) {
    await testStreamCaught(() => makeStream('Caught#${testCaseId++}'));
  }

  if (shouldTestUncaught) {
    int testCaseId = 0;
    for (var makeStream in streamFactories) {
      await testStreamUncaught(() => makeStream('Uncaught#${testCaseId++}'));
    }
  }
}

Future<void> testStreamCaught(Stream<int> Function() makeStream) async {
  final c = Completer<void>();
  makeStream().listen(
    (_) {},
    onError: (_) {
      // Ignore
    },
    onDone: () {
      c.complete();
    },
  );

  await c.future;

  try {
    await makeStream().toList();
  } catch (_) {}

  try {
    await makeStream().last;
  } catch (_) {}

  try {
    await for (var _ in makeStream()) {}
  } catch (_) {}
}

Future<void> runExpectingUncaughtError(Future<void> Function() test) async {
  final done = Completer();
  Zone.current.fork(
    specification: ZoneSpecification(
      handleUncaughtError: (self, parent, zone, error, stackTrace) {
        done.complete();
      },
    ),
  ).runGuarded(test);
  await done.future;
}

Future<void> testStreamUncaught(Stream<int> Function() makeStream) async {
  await runExpectingUncaughtError(() async {
    makeStream().listen((_) {});
  });

  await runExpectingUncaughtError(() async {
    await makeStream().toList(); // LINE_B
  });

  await runExpectingUncaughtError(() async {
    await makeStream().last; // LINE_C
  });
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
