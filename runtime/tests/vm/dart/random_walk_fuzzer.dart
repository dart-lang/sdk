// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Random-walk fuzzer for the Dart VM.
//
// Start with all the classes and libraries and various interesting values.
// Repeatedly choose one as a receiver, construct a message it is likely to
// understand, send the message, and add the result.
//
// Intentionally not run on the build bots because through dart:io it could
// trash their setups.

library fuzzer;

import 'dart:io';
import 'dart:math';
import 'dart:mirrors';
import 'dart:typed_data';

var blacklist = [
  'dart.io.exit',
  'dart.io.exitCode',
  'dart.io.sleep',
  'dart.io.Process.killPid',
];

final bool trace = false;

void main(List<String> args) {
  int seed;
  if (args.length == 1) {
    seed = int.parse(args[0]);
  } else {
    // Dart's built-in random number generator doesn't provide access to the
    // seed when it is chosen by the implementation. We need to be able to
    // report this seed to make runs of the fuzzer reproducible, so we create
    // the seed ourselves.

    // When running on many machines in parallel, the current time alone
    // is a poor choice of seed.
    seed = 0;
    try {
      var f = new File("/dev/urandom").openSync();
      seed = (seed << 8) | f.readByteSync();
      seed = (seed << 8) | f.readByteSync();
      seed = (seed << 8) | f.readByteSync();
      seed = (seed << 8) | f.readByteSync();
      f.close();
    } catch (e) {
      print("Failed to read from /dev/urandom: $e");
    }

    seed ^= new DateTime.now().millisecondsSinceEpoch;
    seed &= 0xFFFFFFFF;
  }
  random = new Random(seed);

  // Information needed to reproduce this run.
  print("Dart VM fuzzer");
  print("Executable: ${Platform.executable}");
  print("Arguments: ${Platform.executableArguments}");
  print("Version: ${Platform.version}");
  print("Seed: ${seed}");
  print("------------------------------------------");

  setupInterestingValues();
  setupClasses();

  // Bound the number of steps in our random walk so that if any issue is found
  // it can be reproduced without having to wait too long.
  for (int i = 0; i < 100000; i++) {
    fuzz(randomElementOf(candidateReceivers));
    if (maybe(0.01)) garbageCollect();
  }
}

Random random;

bool maybe(probability) => random.nextDouble() < probability;

randomElementOf(list) {
  return list.length == 0 ? null : list[random.nextInt(list.length)];
}

class Candidate<T> {
  Candidate origin;
  String message;
  T mirror;
  trace() {
    if (origin == null) {
      print("");
    } else {
      origin.trace();
      print(" $message");
    }
    print(mirror);
  }
}

List<Candidate<ObjectMirror>> candidateReceivers =
    new List<Candidate<ObjectMirror>>();
List<Candidate<InstanceMirror>> candidateArguments =
    new List<Candidate<InstanceMirror>>();

void addInstance(var instance) {
  addInstanceMirror(reflect(instance));
}

void addInstanceMirror(InstanceMirror mirror,
    [Candidate origin, String message]) {
  var c = new Candidate<InstanceMirror>();
  c.mirror = mirror;
  c.origin = origin;
  c.message = message;

  candidateReceivers.add(c);
  candidateArguments.add(c);
}

void addObjectMirror(ObjectMirror mirror) {
  var c = new Candidate<ObjectMirror>();
  c.mirror = mirror;
  c.origin = null;
  c.message = null;

  candidateReceivers.add(c);
}

void setupInterestingValues() {
  addInstance(null);
  addInstance(true);
  addInstance(false);

  addInstance([]);
  addInstance(const []);
  addInstance({});
  addInstance(const {});

  addInstance(() => null);

  addInstance(-1);
  addInstance(0);
  addInstance(1);
  addInstance(2);

  addInstance(1 << 31);
  addInstance(1 << 31 + 1);
  addInstance(1 << 31 - 1);

  addInstance(1 << 32);
  addInstance(1 << 32 + 1);
  addInstance(1 << 32 - 1);

  addInstance(1 << 63);
  addInstance(1 << 63 + 1);
  addInstance(1 << 63 - 1);

  addInstance(1 << 64);
  addInstance(1 << 64 + 1);
  addInstance(1 << 64 - 1);

  addInstance(-1.0);
  addInstance(0.0);
  addInstance(1.0);
  addInstance(2.0);
  addInstance(double.NAN);
  addInstance(double.INFINITY);
  addInstance(double.NEGATIVE_INFINITY);
  addInstance(double.MIN_POSITIVE);
  addInstance(double.MAX_FINITE);

  addInstance("foo"); // ASCII string
  addInstance("blåbærgrød"); // Latin1 string
  addInstance("Îñţérñåţîöñåļîžåţîờñ"); // Unicode string
  addInstance("𝄞"); // Surrogate pairs
  addInstance("𝄞"[0]); // Surrogate pairs
  addInstance("𝄞"[1]); // Surrogate pairs
  addInstance("\u{0}"); // Non-printing character
  addInstance("\u{1}"); // Non-printing character
  addInstance("f\u{0}oo"); // Internal NUL
  addInstance("blåbæ\u{0}rgrød"); // Internal NUL
  addInstance("Îñţérñåţîö\u{0}ñåļîžåţîờñ"); // Internal NUL
  addInstance("\u{0}𝄞"); // Internal NUL

  for (int len = 0; len < 8; len++) {
    addInstance(fillInt(new Int8List(len)));
    addInstance(fillInt(new Int16List(len)));
    addInstance(fillInt(new Int32List(len)));
    addInstance(fillInt(new Int64List(len)));
    addInstance(fillInt(new Uint8List(len)));
    addInstance(fillInt(new Uint16List(len)));
    addInstance(fillInt(new Uint32List(len)));
    addInstance(fillInt(new Uint64List(len)));
    addInstance(fillFloat(new Float32List(len)));
    addInstance(fillFloat(new Float64List(len)));
  }

  randomInstance(ignore) {
    return randomElementOf(candidateArguments).mirror.reflectee;
  }

  for (int len = 0; len < 8; len++) {
    addInstance(new List.generate(len, randomInstance));
  }
}

void fillInt(TypedData d) {
  for (var i = 0; i < d.length; i++) {
    d[i] = random.nextInt(0xFFFFFFFF);
  }
}

void fillFloat(TypedData d) {
  for (var i = 0; i < d.length; i++) {
    d[i] = random.nextDouble();
  }
}

void setupClasses() {
  currentMirrorSystem().libraries.values.forEach((lib) {
    if (lib.simpleName == #fuzzer) return; // Don't recurse.
    addObjectMirror(lib);
    lib.declarations.values.forEach((decl) {
      if (decl is ClassMirror) {
        addObjectMirror(decl);
      }
    });
  });
}

MethodMirror randomMethodOf(receiver) {
  if (receiver is ClassMirror) {
    return randomElementOf(receiver.declarations.values
        .where((d) => d is MethodMirror && d.isStatic)
        .toList());
  } else if (receiver is LibraryMirror) {
    return randomElementOf(
        receiver.declarations.values.where((d) => d is MethodMirror).toList());
  } else if (receiver is InstanceMirror) {
    var methods = [];
    var cls = receiver.type;
    while (cls != reflectClass(Object)) {
      cls.declarations.values.forEach((d) {
        if (d is MethodMirror && !d.isStatic) methods.add(d);
      });
      cls = cls.superclass;
    }
    return randomElementOf(methods);
  }
  throw new Error("UNREACHABLE");
}

String prettyMessageName(receiver, method) {
  var r = "?", m = "?";
  if (receiver is InstanceMirror) {
    r = MirrorSystem.getName(receiver.type.simpleName);
  } else if (receiver is ClassMirror) {
    r = MirrorSystem.getName(receiver.simpleName);
    r = "$r class";
  } else if (receiver is LibraryMirror) {
    r = MirrorSystem.getName(receiver.simpleName);
    r = "$r lib";
  }
  m = MirrorSystem.getName(method.simpleName);
  return "$r>>#$m";
}

void fuzz(Candidate c) {
  ObjectMirror receiver = c.mirror;
  MethodMirror method = randomMethodOf(receiver);
  if (method == null) return;
  if (blacklist.contains(MirrorSystem.getName(method.qualifiedName))) return;

  List positional = randomPositionalArgumentsFor(method);
  Map named = randomNamedArgumentsFor(method);
  InstanceMirror result;

  String message = prettyMessageName(receiver, method);
  if (trace) {
    c.trace();
    print(message);
  }

  if (method.isConstructor) {
    try {
      result = receiver.newInstance(method.simpleName, positional, named);
    } catch (e) {}
  } else if (method.isRegularMethod) {
    try {
      result = receiver.invoke(method.simpleName, positional, named);
    } catch (e) {}
  } else if (method.isGetter) {
    try {
      result = receiver.getField(method.simpleName);
    } catch (e) {}
  } else if (method.isSetter) {
    try {
      result = receiver.setField(method.simpleName, positional[0]);
    } catch (e) {}
  }

  if (result != null) {
    addInstanceMirror(result, c, message);
  }
}

InstanceMirror randomArgumentWithBias(TypeMirror bias) {
  if (maybe(0.75)) {
    for (var candidate in candidateArguments) {
      if (candidate.mirror.type.isAssignableTo(bias)) {
        return candidate.mirror;
      }
    }
  }
  return randomElementOf(candidateArguments).mirror;
}

List randomPositionalArgumentsFor(MethodMirror method) {
  var result = [];
  for (int i = 0; i < method.parameters.length; i++) {
    ParameterMirror p = method.parameters[i];
    if (!p.isNamed && (!p.isOptional || maybe(0.5))) {
      result.add(randomArgumentWithBias(p.type));
    }
  }
  return result;
}

Map randomNamedArgumentsFor(MethodMirror method) {
  var result = {};
  for (int i = 0; i < method.parameters.length; i++) {
    ParameterMirror p = method.parameters[i];
    if (p.isNamed && maybe(0.5)) {
      result[p.simpleName] = randomArgumentWithBias(p.type);
    }
  }

  return result;
}

void garbageCollect() {
  // Chain a bunch of moderately sized arrays, then let go of them. Using a
  // moderate size avoids our allocations going directly to a large object
  // page in old space.
  var n;
  for (int i = 0; i < 2048; i++) {
    var m = new List(512);
    m[0] = n;
    n = m;
  }
}
