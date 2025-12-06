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

var foo = 42;
var foo_no_initializer;

@pragma('vm:shared')
var shared_foo_no_initializer;

@pragma('vm:shared')
final foo_final = 1234;

@pragma('vm:never-inline')
updateFoo() {
  foo = 56;
}

@pragma('vm:never-inline')
updateFooNoInitializer() {
  foo_no_initializer = 78;
}

class Baz {
  static late final foo;
}

@pragma('vm:never-inline')
bar() {
  Baz.foo = 42;
}

@pragma('vm:shared')
var list_length = 0;

@pragma('vm:shared')
String string_foo = "";

@pragma('vm:shared')
SendPort? sp;

StringMethodTearoffTest() {
  @pragma('vm:shared')
  final stringTearoff = "abc".toString;
  IsolateGroup.runSync(() {
    stringTearoff;
  });
}

ListMethodTearoffTest(List<String> args) {
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

thefun() {}

@pragma('vm:shared')
String default_tag = "";

@pragma('vm:shared')
double pi = 3.14159;

main(List<String> args) {
  IsolateGroup.runSync(() {
    final l = <int>[];
    for (int i = 0; i < 100; i++) {
      l.add(i);
    }
    list_length = l.length;
  });
  Expect.equals(100, list_length);

  Expect.equals(42, IsolateGroup.runSync(() => 42));

  Expect.listEquals([1, 2, 3], IsolateGroup.runSync(() => [1, 2, 3]));

  Expect.equals(1234, IsolateGroup.runSync(() => foo_final));

  IsolateGroup.runSync(() {
    shared_foo_no_initializer = 2345;
  });
  Expect.equals(2345, IsolateGroup.runSync(() => shared_foo_no_initializer));

  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        throw "error";
      });
    },
    (e) => e == "error",
    'Expect thrown error',
  );

  // Documenting current limitations.
  Expect.notEquals(() {
    IsolateGroup.runSync(() {
      return Isolate.current;
    });
  }, Isolate.current);

  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        print('42');
      });
    },
    (e) => e is Error && e.toString().contains("AccessError"),
    'Expect error printing',
  );

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

  {
    bar();
    Expect.equals(42, Baz.foo);
  }

  IsolateGroup.runSync(() {
    string_foo = "foo bar";
  });
  Expect.equals("foo bar", string_foo);

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

  Expect.throws(() {
    IsolateGroup.runSync(() {
      Isolate.exit();
    });
  }, (e) => e.toString().contains("Attempt to access isolate static field"));

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

  StringMethodTearoffTest();
  ListMethodTearoffTest(args);

  {
    final rp = ReceivePort();
    Expect.throws(
      () {
        IsolateGroup.runSync(() {
          sp = rp.sendPort;
        });
      },
      (e) =>
          e is ArgumentError &&
          e.toString().contains("Only trivially-immutable"),
    );
    rp.close();
  }

  // deferred libraries can't be used from isolate group callbacks.
  Expect.throws(() {
    IsolateGroup.runSync(() {
      lib1.thefun();
    });
  }, (e) => e is ArgumentError && e.toString().contains("Only available when"));

  // environment can't be accessed from isolate group callbacks.
  Expect.throws(() {
    IsolateGroup.runSync(() {
      new bool.hasEnvironment("Anything");
    });
  }, (e) => e is ArgumentError && e.toString().contains("Only available when"));

  IsolateGroup.runSync(() {
    default_tag = UserTag.defaultTag.toString();
  });
  Expect.notEquals("", default_tag);

  final result = IsolateGroup.runSync(() {
    return pi.toString();
  });
  Expect.equals("3.14159", result);
  final resultIdentical = IsolateGroup.runSync(() {
    return identical(pi.toString(), pi.toString());
  });
  Expect.isTrue(resultIdentical);

  Expect.listEquals(
    "abcdefghijklmnopqrstuvwxyz".codeUnits,
    IsolateGroup.runSync(() {
      return Base64Decoder().convert("YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXo=");
    }),
  );

  IsolateGroup.runSync(() {
    Random().nextInt(10);
  });

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

  print("All tests completed :)");
}
