// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This exercises Mutex and ConditionVariable from dart:concurrent library.

import 'dart:concurrent';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

@pragma('vm:shared')
late Mutex mutexSimple;

@pragma('vm:shared')
late Mutex mutexCondvar;
@pragma('vm:shared')
late ConditionVariable condVar;

void main() {
  group('mutex', () {
    test('simple', () {
      final mutex = Mutex();
      expect(mutex.runLocked(() => 42), equals(42));
    });

    Future<String> spawnHelperIsolate(int ptrAddress) {
      return Isolate.run(() {
        final ptr = Pointer<Uint8>.fromAddress(ptrAddress);

        while (true) {
          sleep(Duration(milliseconds: 10));
          if (mutexSimple.runLocked(() {
            if (ptr.value == 2) {
              return true;
            }
            ptr.value = 0;
            sleep(Duration(milliseconds: 500));
            ptr.value = 1;
            return false;
          })) {
            break;
          }
        }

        return 'success';
      });
    }

    test('isolate', () async {
      await using((arena) async {
        final ptr = arena.allocate<Uint8>(1);

        mutexSimple = Mutex();
        final helperResult = spawnHelperIsolate(ptr.address);

        while (true) {
          final sw = Stopwatch()..start();
          if (mutexSimple.runLocked(() {
            if (sw.elapsedMilliseconds > 300 && ptr.value == 1) {
              ptr.value = 2;
              return true;
            }
            return false;
          })) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 10));
        }
        expect(await helperResult, equals('success'));
      });
    });
  });

  group('condvar', () {
    Future<String> spawnHelperIsolate(int ptrAddress) {
      return Isolate.run(() {
        final ptr = Pointer<Uint8>.fromAddress(ptrAddress);

        return mutexCondvar.runLocked(() {
          ptr.value = 1;
          while (ptr.value == 1) {
            condVar.wait(mutexCondvar);
          }
          return ptr.value == 2 ? 'success' : 'failure';
        });
      });
    }

    test('isolate', () async {
      await using((arena) async {
        final ptr = arena.allocate<Uint8>(1);
        mutexCondvar = Mutex();
        condVar = ConditionVariable();

        final helperResult = spawnHelperIsolate(ptr.address);

        while (true) {
          final success = mutexCondvar.runLocked(() {
            if (ptr.value == 1) {
              ptr.value = 2;
              condVar.notify();
              return true;
            }
            return false;
          });
          if (success) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 20));
        }

        expect(await helperResult, equals('success'));
      });
    });
  });
}
