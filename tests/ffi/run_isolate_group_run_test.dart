// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests IsolateGroup.runSync - what works, what doesn't.
//
// VMOptions=--experimental-shared-data
// VMOptions=--experimental-shared-data --use-slow-path
// VMOptions=--experimental-shared-data --use-slow-path --stacktrace-every=100
// VMOptions=--experimental-shared-data --dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--experimental-shared-data --test_il_serialization
// VMOptions=--experimental-shared-data --profiler --profile_vm=true
// VMOptions=--experimental-shared-data --profiler --profile_vm=false

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';
import 'dart:math';

import "package:expect/expect.dart";

import "run_isolate_group_run_test.dart" deferred as lib1;

main(List<String> args) {
  testUpdateSharedVar();
  testReturnsConstant();
  testReturnsList();
  testReturnsNotSharedFinal();
  testUpdateSharedVarWithNoInitializer();

  testFailToAccessNotSharedVarWithInitializer();
  testFailToAccessNotSharedVarWithoutInitializer();

  testFailToCaptureLateFinalVar();
  testCapturesFinalNotSharedVar();

  testCyclesBetweenClosures();

  testUpdateNotSharedStaticField();
  testUpdateSharedStringStaticVar();

  testClosure();

  testFailToPrint();

  testFailToIsolateGroupRunSyncThrows();
  testIsolateCurrent();
  testFailToIsolateExit();
  testFailToIsolateSpawn();
  testStringMethodTearoff();
  testListMethodTearoff(args);

  testFailToReceivePort();
  testFailToDeferredLibrary();
  testFailToEnvironment();

  testUserTag();
  testDoubleToString();
  testBase64Decoder();
  testRandom();
  testEncoding();
  testRecursiveToString();

  print("All tests completed :)");
}

///
@pragma('vm:shared')
var list_length = 0;

void testUpdateSharedVar() {
  IsolateGroup.runSync(() {
    final l = <int>[];
    for (int i = 0; i < 100; i++) {
      l.add(i);
    }
    list_length = l.length;
  });
  Expect.equals(100, list_length);
}

///
@pragma('vm:shared')
final foo_final = 1234;

void testReturnsNotSharedFinal() {
  Expect.equals(1234, IsolateGroup.runSync(() => foo_final));
}

///
void testReturnsConstant() {
  Expect.equals(42, IsolateGroup.runSync(() => 42));
}

///
void testReturnsList() {
  Expect.listEquals([1, 2, 3], IsolateGroup.runSync(() => [1, 2, 3]));
}

///
var foo_no_initializer;

@pragma('vm:never-inline')
updateFooNoInitializer() {
  foo_no_initializer = 78;
}

void testFailToAccessNotSharedVarWithoutInitializer() {
  updateFooNoInitializer();
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        return foo_no_initializer;
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error accessing',
  );

  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        foo_no_initializer = 456;
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error accessing',
  );
  Expect.equals(78, foo_no_initializer);
}

///
void testFailToCaptureLateFinalVar() {
  late final int late_final_var;
  late_final_var = 12;
  Expect.throws(() {
    IsolateGroup.runSync(() {
      return late_final_var;
    });
  }, (e) => e is Error && e.toString().contains("Only final"));
}

///
@pragma('vm:never-inline')
calculateTwelve() => 12;

void testCapturesFinalNotSharedVar() {
  final int late_final_var = calculateTwelve();
  Expect.equals(late_final_var, IsolateGroup.runSync(() => late_final_var));
}

///
void testCyclesBetweenClosures() {
  final int i = 0;
  final void Function() func1 = () {
    if (i > 0) {
      throw i;
    }
  };
  void func2() {
    func1();
  }

  ;
  IsolateGroup.runSync(func2);
}

///
var foo = 42;

@pragma('vm:never-inline')
updateFoo() {
  foo = 56;
}

void testFailToAccessNotSharedVarWithInitializer() {
  updateFoo();
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        return foo;
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error accessing',
  );

  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        foo = 123;
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error accessing',
  );
  Expect.equals(56, foo);
}

///
@pragma('vm:shared')
var shared_foo_no_initializer;

void testUpdateSharedVarWithNoInitializer() {
  IsolateGroup.runSync(() {
    shared_foo_no_initializer = 2345;
  });
  Expect.equals(2345, IsolateGroup.runSync(() => shared_foo_no_initializer));
}

///
class Baz {
  static late final foo;
}

@pragma('vm:never-inline')
updateBazFoo() {
  Baz.foo = 42;
}

void testUpdateNotSharedStaticField() {
  updateBazFoo();
  Expect.equals(42, Baz.foo);
}

///
@pragma('vm:shared')
String string_foo = "";

void testUpdateSharedStringStaticVar() {
  IsolateGroup.runSync(() {
    string_foo = "foo bar";
  });
  Expect.equals("foo bar", string_foo);
}

///
@pragma('vm:never-inline')
@pragma('vm:shared')
var closure = () {
  return 42;
};
void testClosure() {
  final result = IsolateGroup.runSync(() {
    return closure();
  });
  Expect.equals(42, result);
}

///
void testFailToPrint() {
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        print('42');
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error printing',
  );
}

///
void testFailToIsolateGroupRunSyncThrows() {
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        throw "error";
      });
    },
    (e) => e == "error",
    'Expect thrown error',
  );
}

///
void testIsolateCurrent() {
  Expect.notEquals(() {
    IsolateGroup.runSync(() {
      return Isolate.current;
    });
  }, Isolate.current);
}

///
void testFailToIsolateExit() {
  Expect.throws(() {
    IsolateGroup.runSync(() {
      Isolate.exit();
    });
  }, (e) => e.toString().contains("Attempt to access isolate static field"));
}

///
void testFailToIsolateSpawn() {
  Expect.throws(() {
    IsolateGroup.runSync(() {
      Isolate.spawn((_) {}, null);
    });
  }, (e) => e.toString().contains("Attempt to access isolate static field"));

  Expect.throws(() {
    IsolateGroup.runSync(() {
      Isolate.spawnUri(Uri.parse("http://127.0.0.1"), [], (_) {});
    });
  }, (e) => e.toString().contains("Attempt to access isolate static field"));
}

///
testStringMethodTearoff() {
  @pragma('vm:shared')
  final stringTearoff = "abc".toString;
  IsolateGroup.runSync(() {
    stringTearoff;
  });
}

///
testListMethodTearoff(List<String> args) {
  final listTearoff = args.insert;
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        listTearoff;
      });
    },
    (e) =>
        e is ArgumentError && e.toString().contains("Only trivially-immutable"),
  );
}

///
@pragma('vm:shared')
SendPort? sp;

void testFailToReceivePort() {
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        ReceivePort();
      });
    },
    (e) =>
        e is ArgumentError &&
        e.toString().contains("Only available when running in context"),
  );

  final rp = ReceivePort();
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        sp = rp.sendPort;
      });
    },
    (e) =>
        e is ArgumentError && e.toString().contains("Only trivially-immutable"),
  );
  rp.close();
}

///
thefun() {}

void testFailToDeferredLibrary() {
  Expect.throws(() {
    IsolateGroup.runSync(() {
      lib1.thefun();
    });
  }, (e) => e is ArgumentError && e.toString().contains("Only available when"));
}

///
void testFailToEnvironment() {
  Expect.throws(() {
    IsolateGroup.runSync(() {
      new bool.hasEnvironment("Anything");
    });
  }, (e) => e is ArgumentError && e.toString().contains("Only available when"));
}

///
@pragma('vm:shared')
String default_tag = "";

void testUserTag() {
  IsolateGroup.runSync(() {
    default_tag = UserTag.defaultTag.toString();
  });
  Expect.notEquals("", default_tag);
}

///
@pragma('vm:shared')
double pi = 3.14159;

void testDoubleToString() {
  final result = IsolateGroup.runSync(() {
    return pi.toString();
  });
  Expect.equals("3.14159", result);
  final resultIdentical = IsolateGroup.runSync(() {
    return identical(pi.toString(), pi.toString());
  });
  Expect.isTrue(resultIdentical);
}

///
void testBase64Decoder() {
  Expect.listEquals(
    "abcdefghijklmnopqrstuvwxyz".codeUnits,
    IsolateGroup.runSync(() {
      return Base64Decoder().convert("YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXo=");
    }),
  );
}

///
void testRandom() {
  IsolateGroup.runSync(() {
    Random().nextInt(10);
  });
}

///
void testEncoding() {
  Expect.listEquals(
    [0x31, 0x32, 0x33, 0x61, 0x62, 0x63],
    IsolateGroup.runSync(
      () => Encoding.getByName("us-ascii")!.encode("123abc"),
    ),
  );
  Expect.identical(
    ascii,
    IsolateGroup.runSync(() => Encoding.getByName("us-ascii")),
  );
  Expect.identical(
    utf8,
    IsolateGroup.runSync(() => Encoding.getByName("utf-8")),
  );
}

///
void testRecursiveToString() {
  Expect.equals(
    "[foo, bar, [...], baz]",
    IsolateGroup.runSync(() {
      var l = <Object>["foo", "bar"];
      l.add(l);
      l.add("baz");
      return l.toString();
    }),
  );
}
