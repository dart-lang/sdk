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
  // Don't recurse on this test.
  'test.invoke_natives',

  // Don't exit the test pre-maturely.
  'dart.io.exit',

  // Don't run blocking io calls.
  new RegExp(r".*Sync$"),

  // These prevent the test from exiting.
  'dart.async._scheduleAsyncCallback',
  'dart.async._setTimerFactoryClosure',

  'dart.isolate._startMainIsolate',
  'dart.isolate._startIsolate',
  'dart.io.sleep',
  'dart.io.HttpServer.HttpServer.listenOn',

  // These either cause the VM to segfault or throw uncatchable API errors.
  // TODO(15274): Fix them and remove from blacklist.
  'dart.io._IOService.dispatch',
  new RegExp(r'.*_RandomAccessFile.*'),
  'dart.io._StdIOUtils._socketType',
  'dart.io._StdIOUtils._getStdioOutputStream',
  'dart.io._Filter.newZLibInflateFilter',
  'dart.io._Filter.newZLibDeflateFilter',
  'dart.io._FileSystemWatcher._listenOnSocket',
  'dart.io.SystemEncoding.decode',
  'dart.io.SystemEncoding.encode',
];

bool isBlacklisted(Symbol qualifiedSymbol) {
  var qualifiedString = MirrorSystem.getName(qualifiedSymbol);
  for (var pattern in blacklist) {
    if (qualifiedString.contains(pattern)) return true;
  }
  return false;
}

class Task {
  var name;
  var action;
}
var queue = new List();

checkMethod(MethodMirror m, ObjectMirror target, [origin]) {
  if (isBlacklisted(m.qualifiedName)) return;

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
  ClassMirror klass = instanceMirror.type;
  while (klass != null) {
    instanceMirror.type.declarations.values
        .where((d) => d is MethodMirror && !d.isStatic)
        .forEach((m) => checkMethod(m, instanceMirror, origin));
    klass = klass.superclass;
  }
}

checkClass(classMirror) {
  classMirror.declarations.values
      .where((d) => d is MethodMirror && d.isStatic)
      .forEach((m) => checkMethod(m, classMirror));

  classMirror.declarations.values
      .where((d) => d is MethodMirror && d.isConstructor)
      .forEach((m) {
    if (isBlacklisted(m.qualifiedName)) return;
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
  print(libraryMirror.simpleName);
  if (isBlacklisted(libraryMirror.qualifiedName)) return;

  libraryMirror.declarations.values
      .where((d) => d is ClassMirror)
      .forEach(checkClass);

  libraryMirror.declarations.values
      .where((d) => d is MethodMirror)
      .forEach((m) => checkMethod(m, libraryMirror));
}

var testZone;

doOneTask() {
  if (queue.length == 0) {
    print('Done');
    return;
  }

  var task = queue.removeLast();
  print(task.name);
  try {
    task.action();
  } catch(e) {}

  // Register the next task in a timer callback so as to yield to async code
  // scheduled in the current task. This isn't necessary for the test itself,
  // but is helpful when trying to figure out which function is responsible for
  // a crash.
  testZone.createTimer(Duration.ZERO, doOneTask);
}

main([args]) {
  currentMirrorSystem().libraries.values.forEach(checkLibrary);

  var valueObjects =
    [true, false, null,
     0, 0xEFFFFFF, 0xFFFFFFFF, 0xFFFFFFFFFFFFFFFF,
     "foo", 'blåbærgrød', 'Îñţérñåţîöñåļîžåţîờñ'];
  valueObjects.forEach((v) => checkInstance(reflect(v), 'value object'));

  uncaughtErrorHandler(self, parent, zone, error, stack) {};
  var zoneSpec =
     new ZoneSpecification(handleUncaughtError: uncaughtErrorHandler);
  testZone = Zone.current.fork(specification: zoneSpec);
  testZone.createTimer(Duration.ZERO, doOneTask);
}
