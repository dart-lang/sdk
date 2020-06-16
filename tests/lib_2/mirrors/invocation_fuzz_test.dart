// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test reflectively enumerates all the methods in the system and tries to
// invoke them with various basic values (nulls, ints, etc). This may result in
// Dart exceptions or hangs, but should never result in crashes or JavaScript
// exceptions.

library test.invoke_natives;

import 'dart:mirrors';
import 'dart:async';
import 'dart:io';

// Methods to be skipped, by qualified name.
var denylist = [
  // Don't recurse on this test.
  'test.invoke_natives',

  // Don't exit the test pre-maturely.
  'dart.io.exit',

  // Don't change the exit code, which may fool the test harness.
  'dart.io.exitCode',

  // Don't kill random other processes.
  'dart.io.Process.killPid',

  // Don't break into the debugger.
  'dart.developer.debugger',

  // Don't run blocking io calls.
  'dart.io.sleep',
  new RegExp(r".*Sync$"),

  // Don't call private methods in dart.async as they may circumvent the zoned
  // error handling below.
  new RegExp(r"^dart\.async\._.*$"),
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

var queue = new List<Task>();

checkMethod(MethodMirror m, ObjectMirror target, [origin]) {
  if (isDenylisted(m.qualifiedName)) return;

  var task = new Task();
  task.name = '${MirrorSystem.getName(m.qualifiedName)} from $origin';

  if (m.isRegularMethod) {
    task.action = () => target.invoke(
        m.simpleName, new List.filled(m.parameters.length, fuzzArgument));
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
    if (isDenylisted(m.qualifiedName)) return;
    var task = new Task();
    task.name = MirrorSystem.getName(m.qualifiedName);

    task.action = () {
      var instance = classMirror.newInstance(m.constructorName,
          new List.filled(m.parameters.length, fuzzArgument));
      checkInstance(instance, task.name);
    };
    queue.add(task);
  });
}

checkLibrary(libraryMirror) {
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

doOneTask() {
  if (queue.length == 0) {
    print('Done');
    // Forcibly exit as we likely opened sockets and timers during the fuzzing.
    exit(0);
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

main() {
  fuzzArgument = null;
  fuzzArgument = 1; // //# smi: ok
  fuzzArgument = false; // //# false: ok
  fuzzArgument = 'string'; // //# string: ok
  fuzzArgument = new List(0); // //# emptyarray: ok

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
    #symbol
  ];
  valueObjects.forEach((v) => checkInstance(reflect(v), 'value object'));

  void uncaughtErrorHandler(self, parent, zone, error, stack) {}

  var zoneSpec =
      new ZoneSpecification(handleUncaughtError: uncaughtErrorHandler);
  testZone = Zone.current.fork(specification: zoneSpec);
  testZone.createTimer(Duration.zero, doOneTask);
}
