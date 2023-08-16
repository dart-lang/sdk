// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'mocks.dart';

main() {
  group('IsolateManager', () {
    final adapter = MockDartCliDebugAdapter();
    final isolateManager = adapter.isolateManager;

    setUp(() async {
      isolateManager.debug = true;
      isolateManager.debugSdkLibraries = false;
      isolateManager.debugExternalPackageLibraries = true;
      await isolateManager.registerIsolate(
        adapter.mockService.isolate1,
        EventKind.kIsolateStart,
      );
      await isolateManager.registerIsolate(
        adapter.mockService.isolate2,
        EventKind.kIsolateStart,
      );
    });

    test('sends only changes to SDK libraries debuggable flag', () async {
      // Default is false, so should not send anything.
      isolateManager.debugSdkLibraries = false;
      await isolateManager.applyDebugOptions();
      expect(
        adapter.mockService.requests,
        isNot(
          contains(startsWith('setLibraryDebuggable(isolate1, libSdk,')),
        ),
      );

      // Changing to non-default should send a request.
      isolateManager.debugSdkLibraries = true;
      await isolateManager.applyDebugOptions();
      expect(
        adapter.mockService.requests,
        contains('setLibraryDebuggable(isolate1, libSdk, true)'),
      );

      // Setting back to default should now send.
      isolateManager.debugSdkLibraries = false;
      await isolateManager.applyDebugOptions();
      expect(
        adapter.mockService.requests,
        contains('setLibraryDebuggable(isolate1, libSdk, false)'),
      );
    });

    test('sends only changes to external package libraries debuggable flag',
        () async {
      // Default is true, so should not send anything.
      isolateManager.debugExternalPackageLibraries = true;
      await isolateManager.applyDebugOptions();
      expect(
        adapter.mockService.requests,
        isNot(
          contains(
              startsWith('setLibraryDebuggable(isolate1, libPkgExternal,')),
        ),
      );

      // Changing to non-default should send a request.
      isolateManager.debugExternalPackageLibraries = false;
      await isolateManager.applyDebugOptions();
      expect(
        adapter.mockService.requests,
        contains('setLibraryDebuggable(isolate1, libPkgExternal, false)'),
      );

      // Setting back to default should now send.
      isolateManager.debugExternalPackageLibraries = true;
      await isolateManager.applyDebugOptions();
      expect(
        adapter.mockService.requests,
        contains('setLibraryDebuggable(isolate1, libPkgExternal, true)'),
      );
    });

    /// Local packages are always debuggable, in the VM and because we have no
    /// settings. No changes should ever cause requests for them.
    test('never sends values for local package libraries debuggable flag',
        () async {
      isolateManager.debugSdkLibraries = true;
      isolateManager.debugExternalPackageLibraries = true;
      await isolateManager.applyDebugOptions();

      isolateManager.debugSdkLibraries = false;
      isolateManager.debugExternalPackageLibraries = false;
      await isolateManager.applyDebugOptions();

      expect(
        adapter.mockService.requests,
        isNot(
          contains(startsWith('setLibraryDebuggable(isolate1, libPkgLocal,')),
        ),
      );
    });

    test('clears thread data on resume', () async {
      final thread1 = isolateManager.threads[0];
      final thread2 = isolateManager.threads[1];

      // Store some data in both threads.
      final ref1 = thread1.storeData("test1");
      final ref2 = thread2.storeData("test2");

      // Resume thread1
      thread1.paused = true; // Fake pause to allow resume.
      await isolateManager.resumeThread(thread1.isolateNumber);

      // Ensure thread1 had data cleared, but thread2 did not.
      expect(isolateManager.getStoredData(ref1), isNull);
      expect(isolateManager.getStoredData(ref2), isNotNull);
    });
  });
}
