// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:expect/expect.dart";

// The sizes of these classes are co-prime multiples of the allocation unit to
// increase the likelihood that scavenging fails from fragmentation.

// header + 13 fields = 7 allocation units
class A {
  dynamic field1;
  dynamic field2;
  dynamic field3;
  dynamic field4;
  dynamic field5;
  dynamic field6;
  dynamic field7;
  dynamic field8;
  dynamic field9;
  dynamic field10;
  dynamic field11;
  dynamic field12;
  dynamic field13;
}

// header + 17 fields = 9 allocation units
class B {
  dynamic field1;
  dynamic field2;
  dynamic field3;
  dynamic field4;
  dynamic field5;
  dynamic field6;
  dynamic field7;
  dynamic field8;
  dynamic field9;
  dynamic field10;
  dynamic field11;
  dynamic field12;
  dynamic field13;
  dynamic field14;
  dynamic field15;
  dynamic field16;
  dynamic field17;
}

// header + 19 fields = 10 allocation units
class C {
  dynamic field1;
  dynamic field2;
  dynamic field3;
  dynamic field4;
  dynamic field5;
  dynamic field6;
  dynamic field7;
  dynamic field8;
  dynamic field9;
  dynamic field10;
  dynamic field11;
  dynamic field12;
  dynamic field13;
  dynamic field14;
  dynamic field15;
  dynamic field16;
  dynamic field17;
  dynamic field18;
  dynamic field19;
}

makeA(n) {
  var a = new A();
  if (n > 0) {
    a.field1 = makeB(n - 1);
    a.field2 = makeC(n - 1);
    a.field3 = makeB(n - 1);
    a.field4 = makeC(n - 1);
  }
  return a;
}

makeB(n) {
  var b = new B();
  if (n > 0) {
    b.field1 = makeC(n - 1);
    b.field2 = makeA(n - 1);
    b.field3 = makeC(n - 1);
    b.field4 = makeA(n - 1);
  }
  return b;
}

makeC(n) {
  var c = new C();
  if (n > 0) {
    c.field1 = makeA(n - 1);
    c.field2 = makeB(n - 1);
    c.field3 = makeA(n - 1);
    c.field4 = makeB(n - 1);
  }
  return c;
}

readFields(x) {
  print(x.field1);
  print(x.field2);
  print(x.field3);
  print(x.field4);
}

main(List<String> argsIn) async {
  if (argsIn.contains("--testee")) {
    // Trigger OOM.
    // Must read the fields to prevent the writes from being optimized away. If
    // the writes are optimized away, most of the tree is collectible right away
    // and we timeout instead of triggering OOM.
    readFields(makeA(50));
    readFields(makeB(50));
    readFields(makeC(50));
    return;
  }

  var exec = Platform.executable;
  var args = Platform.executableArguments +
      [
        "--old_gen_heap_size=15" /*MB*/,
        "--verbose_gc",
        "--verify_after_gc",
        "--verify_store_buffer",
        Platform.script.toFilePath(),
        "--testee"
      ];
  print("+ $exec ${args.join(' ')}");

  var result = await Process.run(exec, args);
  print("Command stdout:");
  print(result.stdout);
  print("Command stderr:");
  print(result.stderr);

  Expect.equals(255, result.exitCode,
      "Should see runtime exception error code, not SEGV");

  Expect.isTrue(
      result.stderr.contains("Unhandled exception:\nOut of Memory") ||
          result.stderr.contains("Unhandled exception:\r\nOut of Memory"),
      "Should see the Dart OutOfMemoryError");

  // --verbose_gc not available in product mode
  if (!new bool.fromEnvironment("dart.vm.product")) {
    Expect.isTrue(result.stderr.contains("Aborting scavenge"),
        "Should abort scavenge at least once");
  }

  Expect.isFalse(result.stderr.contains("error: Out of memory"),
      "Should not see the C++ OUT_OF_MEMORY()");
}
