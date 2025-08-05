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
import 'dart:isolate';

import "package:expect/expect.dart";

var foo = 42;
var foo_no_initializer;

@pragma('vm:shared')
var shared_foo_no_initializer;

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

main() {
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

  print("All tests completed :)");
}
