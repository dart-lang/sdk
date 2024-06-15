// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This exercises 'vm:shared' pragma.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

sealed class Mutex {
  Mutex._();

  factory Mutex() => Platform.isWindows ? WindowsMutex() : PosixMutex();

  factory Mutex.fromAddress(int address) => Platform.isWindows
      ? WindowsMutex.fromAddress(address)
      : PosixMutex.fromAddress(address);

  int get rawAddress;

  void lock();

  void unlock();

  R holdingLock<R>(R Function() action) {
    lock();
    try {
      return action();
    } finally {
      unlock();
    }
  }
}

//
// POSIX threading primitives
//

/// Represents `pthread_mutex_t`
final class PthreadMutex extends Opaque {}

/// Represents `pthread_cond_t`
final class PthreadCond extends Opaque {}

@Native<Int Function(Pointer<PthreadMutex>, Pointer<Void>)>()
external int pthread_mutex_init(
    Pointer<PthreadMutex> mutex, Pointer<Void> attrs);

@Native<Int Function(Pointer<PthreadMutex>)>()
external int pthread_mutex_lock(Pointer<PthreadMutex> mutex);

@Native<Int Function(Pointer<PthreadMutex>)>()
external int pthread_mutex_unlock(Pointer<PthreadMutex> mutex);

@Native<Int Function(Pointer<PthreadMutex>)>()
external int pthread_mutex_destroy(Pointer<PthreadMutex> cond);

@Native<Int Function(Pointer<PthreadCond>, Pointer<Void>)>()
external int pthread_cond_init(Pointer<PthreadCond> cond, Pointer<Void> attrs);

@Native<Int Function(Pointer<PthreadCond>, Pointer<PthreadMutex>)>()
external int pthread_cond_wait(
    Pointer<PthreadCond> cond, Pointer<PthreadMutex> mutex);

@Native<Int Function(Pointer<PthreadCond>)>()
external int pthread_cond_destroy(Pointer<PthreadCond> cond);

@Native<Int Function(Pointer<PthreadCond>)>()
external int pthread_cond_signal(Pointer<PthreadCond> cond);

class PosixMutex extends Mutex {
  static const _sizeInBytes = 64;

  final Pointer<PthreadMutex> _impl;

  // TODO(@mraleph) this should be a native finalizer, also we probably want to
  // do reference counting on the mutex so that the last owner destroys it.
  static final _finalizer = Finalizer<Pointer<PthreadMutex>>((ptr) {
    pthread_mutex_destroy(ptr);
    calloc.free(ptr);
  });

  PosixMutex()
      : _impl = calloc.allocate(PosixMutex._sizeInBytes),
        super._() {
    if (pthread_mutex_init(_impl, nullptr) != 0) {
      calloc.free(_impl);
      throw StateError('failed to initialize mutex');
    }
    _finalizer.attach(this, _impl);
  }

  PosixMutex.fromAddress(int address)
      : _impl = Pointer.fromAddress(address),
        super._();

  @override
  void lock() {
    if (pthread_mutex_lock(_impl) != 0) {
      throw StateError('failed to lock mutex');
    }
  }

  @override
  void unlock() {
    if (pthread_mutex_unlock(_impl) != 0) {
      throw StateError('failed to unlock mutex');
    }
  }

  @override
  int get rawAddress => _impl.address;
}

//
// WinAPI implementation of the synchronization primitives
//

final class SRWLOCK extends Opaque {}

@Native<Void Function(Pointer<SRWLOCK>)>()
external void InitializeSRWLock(Pointer<SRWLOCK> lock);
@Native<Void Function(Pointer<SRWLOCK>)>()
external void AcquireSRWLockExclusive(Pointer<SRWLOCK> lock);
@Native<Void Function(Pointer<SRWLOCK>)>()
external void ReleaseSRWLockExclusive(Pointer<SRWLOCK> mutex);

class WindowsMutex extends Mutex {
  static const _sizeInBytes = 8;

  final Pointer<SRWLOCK> _impl;

  // TODO(@mraleph) this should be a native finalizer, also we probably want to
  // do reference counting on the mutex so that the last owner destroys it.
  static final _finalizer = Finalizer<Pointer<SRWLOCK>>((ptr) {
    calloc.free(ptr);
  });

  WindowsMutex()
      : _impl = calloc.allocate(WindowsMutex._sizeInBytes),
        super._() {
    InitializeSRWLock(_impl);
    _finalizer.attach(this, _impl);
  }

  WindowsMutex.fromAddress(int address)
      : _impl = Pointer.fromAddress(address),
        super._();

  @override
  void lock() => AcquireSRWLockExclusive(_impl);

  @override
  void unlock() => ReleaseSRWLockExclusive(_impl);

  @override
  int get rawAddress => _impl.address;
}

class WorkItem {
  int i;
  int result = 0;

  WorkItem(this.i);

  doWork(SendPort results) {
    // Calculate fibonacci number i.
    if (i < 3) {
      result = 1;
    } else {
      int pp = 1;
      int p = 1;
      int j = 3;
      while (j <= i) {
        result = pp + p;
        pp = p;
        p = result;
        j++;
      }
    }
    results.send(<int>[i, result]);
  }
}

class SharedState {
  @pragma('vm:shared')
  static late int totalProcessed;
}

int totalWorkItems = 10000;
int numberOfWorkers = 8;

@pragma('vm:shared')
late List<WorkItem> workItems;
@pragma('vm:shared')
late int lastProcessed;
@pragma('vm:shared')
late Mutex mutex;

late var rpResults;
late var results = <int, int>{};

@pragma('vm:never-inline')
void init() {
  SharedState.totalProcessed = 0;
  lastProcessed = 0;
  workItems = List<WorkItem>.generate(totalWorkItems, (i) => WorkItem(i + 1));
  mutex = Mutex();
}

void main(List<String> args) async {
  asyncStart();
  if (args.length > 0) {
    totalWorkItems = int.parse(args[0]);
    if (args.length > 1) {
      numberOfWorkers = int.parse(args[1]);
    }
  }
  print('workItems: $totalWorkItems workers: $numberOfWorkers');

  init();

  rpResults = RawReceivePort((message) {
    Expect.isFalse(results.containsKey(message[0]));
    results[message[0]] = message[1];
  });
  var sendPort = rpResults.sendPort;

  var list = List.generate(
      numberOfWorkers,
      (index) => Isolate.run(() async {
            int countProcessed = 0;
            while (true) {
              var mine = mutex.holdingLock(() => lastProcessed++);
              if (mine >= workItems.length) {
                break;
              }
              workItems[mine].doWork(sendPort);
              countProcessed++;
              mutex.holdingLock(() => SharedState.totalProcessed++);
              await Future.delayed(Duration(seconds: 0));
            }
            print('worker $index processed $countProcessed items');
          }, debugName: 'worker $index'));
  await Future.wait(list);
  rpResults.close();
  Expect.equals(results.keys.length, totalWorkItems);
  Expect.equals(SharedState.totalProcessed, totalWorkItems);
  print('all ${SharedState.totalProcessed} done');
  asyncEnd();
}
