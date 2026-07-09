import 'dart:async';
import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/test.dart';

base class TestRunningIsolate extends RunningIsolate {
  TestRunningIsolate({required super.id, required super.name});
}

base class TestIsolateManager extends IsolateManager {
  @override
  Future<RpcResponse> sendToIsolate({
    required String method,
    required Map<String, Object?> params,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('IsolateManager', () {
    test('ignores system isolates when assigning the root isolate', () async {
      final manager = TestIsolateManager();

      // A system isolate starts first.
      final systemIsolate = TestRunningIsolate(id: 1, name: 'vm-service');
      manager.isolateStarted(isolate: systemIsolate, isSystemIsolate: true);

      // The root isolate id should not be set yet.
      expect(
        () => manager.lookupIsolateFromParams(
          method: 'foo',
          params: {'isolateId': 'isolates/root'},
        ),
        throwsA(isA<Exception>()),
      );

      // A non-system isolate starts next.
      final normalIsolate = TestRunningIsolate(id: 2, name: 'main');
      manager.isolateStarted(isolate: normalIsolate);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Now the root isolate ID should point to the normal isolate.
      final rootIsolate = manager.lookupIsolateFromParams(
        method: 'foo',
        params: {'isolateId': 'isolates/root'},
      );
      expect(rootIsolate, isNotNull);
      expect(rootIsolate!.id, equals(2));
    });

    test('exposes state getter on RunningIsolate', () {
      final isolate = TestRunningIsolate(id: 1, name: 'main');
      expect(isolate.state, equals(IsolateState.unknown));
    });
  });
}
