// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test reflectively enumerates all the methods in the system and tries to
// invoke them will all nulls. This may result in Dart exceptions or hangs, but
// should never result in crashes or JavaScript exceptions.

library test.invoke_natives;

import 'dart:mirrors';
import 'dart:async';
import 'package:expect/expect.dart';

// Methods to be skipped, by qualified name.
var blacklist = [
  // These prevent the test from exiting, typically by spawning another isolate.
  'dart.async._scheduleAsyncCallback',
  'dart.io._IOService.dispatch',
  'dart.isolate.RawReceivePort.RawReceivePort',
  'dart.isolate.ReceivePort.ReceivePort',
  'dart.isolate.ReceivePort.ReceivePort.fromRawReceivePort',
  'dart.isolate.ReceivePort.sendPort',
  'dart.isolate.ReceivePort.close',
  'dart.isolate.ReceivePort.listen',
  'dart.isolate.RawReceivePort.sendPort',
  'dart.isolate.RawReceivePort.close',
  'dart.isolate.RawReceivePort.handler=',

  // These "crash" the VM (throw uncatchable API errors).
  // TODO(15274): Fill in this list to make the test pass and provide coverage
  // against addition of new natives.
];

class Task {
  var name;
  var action;
}
var queue = new List();

checkMethod(MethodMirror m, ObjectMirror target, [origin]) {
  if (blacklist.contains(MirrorSystem.getName(m.qualifiedName))) return;

  var task = new Task();
  task.name = '${MirrorSystem.getName(m.qualifiedName)} from $origin';

  if (m.isRegularMethod) {
    task.action =
        () => target.invoke(m.simpleName, new List(m.parameters.length));
  } else if (m.isGetter) {
    task.action =
        () => target.getField(m.simpleName);
  } else if (m.isSetter) {
    task.action =
        () => target.setField(m.simpleName, null);
  } else if (m.isConstructor) {
    return;
  } else {
    throw "Unexpected method kind";
  }

  queue.add(task);
}

checkInstance(instanceMirror, origin) {
  instanceMirror.type.declarations.values
      .where((d) => d is MethodMirror)
      .forEach((m) => checkMethod(m, instanceMirror, origin));
}

checkClass(classMirror) {
  classMirror.declarations.values
      .where((d) => d is MethodMirror)
      .forEach((m) => checkMethod(m, classMirror));

  classMirror.declarations.values
      .where((d) => d is MethodMirror)
      .forEach((m) {
    if (blacklist.contains(MirrorSystem.getName(m.qualifiedName))) return;
    if (!m.isConstructor) return;
    var task = new Task();
    task.name = MirrorSystem.getName(m.qualifiedName);

    task.action = () {
      var instance = classMirror.newInstance(m.constructorName,
                                             new List(m.parameters.length));
      checkInstance(instance, task.name);
    };
    queue.add(task);
  });
}

checkLibrary(libraryMirror) {
  // Don't recurse on this test.
  if (libraryMirror.simpleName == #test.invoke_natives) return;

  libraryMirror.declarations.values
      .where((d) => d is ClassMirror)
      .forEach(checkClass);

  libraryMirror.declarations.values
      .where((d) => d is MethodMirror)
      .forEach((m) => checkMethod(m, libraryMirror));
}

var testZone;
var debug = true;

doOneTask() {
  if (queue.length == 0) {
    if (debug) print('Done');
    return;
  }

  var task = queue.removeLast();
  if (debug) print(task.name);
  try {
    task.action();
  } catch(e) {}
  // Register the next task in a timer callback so as to yield to async code
  // scheduled in the current task. This isn't necessary for the test itself,
  // but is helpful when trying to figure out which function is responsible for
  // a crash.
  testZone.createTimer(Duration.ZERO, doOneTask);
}

main() {
  currentMirrorSystem().libraries.values.forEach(checkLibrary);

  uncaughtErrorHandler(self, parent, zone, error, stack) {};
  var zoneSpec =
     new ZoneSpecification(handleUncaughtError: uncaughtErrorHandler);
  testZone = Zone.current.fork(specification: zoneSpec);
  testZone.createTimer(Duration.ZERO, doOneTask);
}
