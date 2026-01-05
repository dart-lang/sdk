// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test reflectively enumerates all the methods in the system and tries to
// invoke them with various basic values (nulls, ints, etc). This may result in
// Dart exceptions or hangs, but should never result in crashes.

// Environment=TSAN_OPTIONS=report_thread_leaks=0

// Library name is used by test.
library test.invoke_natives;

import 'dart:mirrors';
import 'dart:async';
import 'dart:io';

import 'package:expect/async_helper.dart';

// Methods to be skipped, by qualified name.
var denylist = [
  // Don't recurse on this test.
  'test.invoke_natives',

  // Don't exit the test prematurely.
  'dart.io.exit',
  'dart.isolate.Isolate.exit',

  // Don't change the exit code, which may fool the test harness.
  'dart.io.exitCode',

  // Don't mess with the async-helper framework.
  RegExp(r"^async_helper."),

  // Don't kill random other processes.
  'dart.io.Process.killPid',

  // Don't break into the debugger.
  'dart.developer.debugger',

  // Don't run blocking io calls.
  'dart.io.sleep',
  RegExp(r"Sync$"),

  // Don't call private methods in `dart:async` as they may circumvent the zoned
  // error handling below.
  RegExp(r"^dart\.async\._"),

  // Don't try to invoke FFI Natives on simulator.
  // TODO(http://dartbug.com/48365): Support FFI in simulators.
  'dart._internal.FinalizerEntry.setExternalSize',

  // Don't instantiate structs with bogus memory.
  'dart.ffi._AsTypedListFinalizerData',

  // Don't instantiate callables with random function pointers.
  'dart.ffi._NativeCallableIsolateLocal',

  // Don't write heap snapshots or profile to random files.
  'dart.developer.NativeRuntime.writeHeapSnapshotToFile',
  'dart.developer.NativeRuntime.streamTimelineTo',
];

bool isDenylisted(Symbol qualifiedSymbol) {
  var qualifiedString = MirrorSystem.getName(qualifiedSymbol);
  for (var pattern in denylist) {
    if (qualifiedString.contains(pattern)) {
      print('Skipping $qualifiedString');
      return true;
    }
  }
  return false;
}

class Task {
  dynamic name;
  dynamic action;
}

var queue = <Task>[];

void checkMethod(MethodMirror m, ObjectMirror target, [origin]) {
  if (isDenylisted(m.qualifiedName)) return;

  var task = Task();
  task.name = '${MirrorSystem.getName(m.qualifiedName)} from $origin';

  if (m.isRegularMethod) {
    task.action = () => target.invoke(
      m.simpleName,
      List.filled(m.parameters.length, fuzzArgument),
    );
  } else if (m.isGetter) {
    task.action = () => target.getField(m.simpleName);
  } else if (m.isSetter) {
    task.action = () => target.setField(m.simpleName, null);
  } else if (m.isConstructor) {
    return;
  } else {
    throw "Unexpected method kind";
  }

  queue.add(task);
}

void checkInstance(instanceMirror, origin) {
  ClassMirror? klass = instanceMirror.type;
  while (klass != null) {
    instanceMirror.type.declarations.values
        .where((d) => d is MethodMirror && !d.isStatic)
        .forEach((m) => checkMethod(m, instanceMirror, origin));
    klass = klass.superclass;
  }
}

void checkClass(classMirror) {
  classMirror.declarations.values
      .where((d) => d is MethodMirror && d.isStatic)
      .forEach((m) => checkMethod(m, classMirror));

  classMirror.declarations.values
      .where((d) => d is MethodMirror && d.isConstructor)
      .forEach((m) {
        if (isDenylisted(m.qualifiedName)) return;
        var task = Task();
        task.name = MirrorSystem.getName(m.qualifiedName);

        task.action = () {
          var instance = classMirror.newInstance(
            m.constructorName,
            List.filled(m.parameters.length, fuzzArgument),
          );
          checkInstance(instance, task.name);
        };
        queue.add(task);
      });
}

void checkLibrary(libraryMirror) {
  print(libraryMirror.simpleName);
  if (isDenylisted(libraryMirror.qualifiedName)) return;

  libraryMirror.declarations.values
      .where((d) => d is ClassMirror)
      .forEach(checkClass);

  libraryMirror.declarations.values
      .where((d) => d is MethodMirror)
      .forEach((m) => checkMethod(m, libraryMirror));
}

var testZone;

void doOneTask() {
  if (queue.length == 0) {
    print('Done: $fuzzArgument');
    fuzzNext();
    return;
  }

  var task = queue.removeLast();
  print(task.name);
  try {
    task.action();
  } catch (e) {}

  // Register the next task in a timer callback so as to yield to async code
  // scheduled in the current task. This isn't necessary for the test itself,
  // but is helpful when trying to figure out which function is responsible for
  // a crash.
  testZone.createTimer(Duration.zero, doOneTask);
}

var fuzzArgument;

var fuzzArguments = [null, 1, false, 'string', List.filled(0, null)];

void main() {
  asyncStart();
  fuzzNext();
}

void fuzzNext() {
  if (fuzzArguments.isEmpty) {
    asyncEnd();
    // Forcibly exit as we likely opened sockets and timers during the fuzzing.
    exit(0);
  }

  fuzzArgument = fuzzArguments.removeLast();

  print('Fuzzing with $fuzzArgument');

  currentMirrorSystem().libraries.values.forEach(checkLibrary);

  var valueObjects = [
    true,
    false,
    null,
    [],
    {},
    dynamic,
    0,
    0xEFFFFFF,
    0xFFFFFFFF,
    0xFFFFFFFFFFFFFFFF,
    3.14159,
    "foo",
    'blåbærgrød',
    'Îñţérñåţîöñåļîžåţîờñ',
    "\u{1D11E}",
    #symbol,
  ];
  valueObjects.forEach((v) => checkInstance(reflect(v), 'value object'));

  void uncaughtErrorHandler(self, parent, zone, error, stack) {
    // Ignore any errors.
  }

  var zoneSpec = ZoneSpecification(handleUncaughtError: uncaughtErrorHandler);
  testZone = Zone.current.fork(specification: zoneSpec);
  testZone.createTimer(Duration.zero, doOneTask);
}
