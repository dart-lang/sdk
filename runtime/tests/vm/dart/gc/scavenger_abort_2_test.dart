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

  // Prevent fields from being optimized away as write-only.
  String toString() {
    return field1 +
        field2 +
        field3 +
        field4 +
        field5 +
        field6 +
        field7 +
        field8 +
        field9 +
        field10 +
        field11 +
        field12 +
        field13;
  }
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

  // Prevent fields from being optimized away as write-only.
  String toString() {
    return field1 +
        field2 +
        field3 +
        field4 +
        field5 +
        field6 +
        field7 +
        field8 +
        field9 +
        field10 +
        field11 +
        field12 +
        field13 +
        field14 +
        field15 +
        field16 +
        field17;
  }
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

  // Prevent fields from being optimized away as write-only.
  String toString() {
    return field1 +
        field2 +
        field3 +
        field4 +
        field5 +
        field6 +
        field7 +
        field8 +
        field9 +
        field10 +
        field11 +
        field12 +
        field13 +
        field14 +
        field15 +
        field16 +
        field17 +
        field18 +
        field19;
  }
}

class Old {
  dynamic next;
  dynamic new1;
  dynamic new2;
  dynamic new3;
  dynamic new4;
  dynamic new5;
  dynamic new6;
  dynamic new7;
  dynamic new8;
  dynamic new9;
  dynamic new10;
  dynamic new11;
  dynamic new12;
  dynamic new13;
  dynamic new14;
  dynamic new15;
  dynamic new16;
  dynamic new17;
  dynamic new18;
  dynamic new19;
  dynamic new20;
  dynamic new21;
  dynamic new22;
  dynamic new23;
  dynamic new24;
  dynamic new25;
  dynamic new26;
  dynamic new27;
  dynamic new28;
  dynamic new29;
  dynamic new30;
  dynamic new31;

  // Prevent fields from being optimized away as write-only.
  String toString() {
    return new1 +
        new2 +
        new3 +
        new4 +
        new5 +
        new6 +
        new7 +
        new8 +
        new9 +
        new10 +
        new11 +
        new12 +
        new13 +
        new14 +
        new15 +
        new16 +
        new17 +
        new18 +
        new19 +
        new20 +
        new21 +
        new22 +
        new23 +
        new24 +
        new25 +
        new26 +
        new27 +
        new28 +
        new29 +
        new30 +
        new31;
  }
}

fill(old) {
  // Note the allocation order is different from the field order. The objects
  // will be scavenged in field order, causing the objects to be rearranged to
  // produce new-space fragmentation.
  old.new1 = new C();
  old.new4 = new C();
  old.new7 = new C();
  old.new10 = new C();
  old.new13 = new C();
  old.new16 = new C();

  old.new2 = new B();
  old.new5 = new B();
  old.new8 = new B();
  old.new11 = new B();
  old.new14 = new B();
  old.new17 = new B();

  old.new3 = new A();
  old.new6 = new A();
  old.new9 = new A();
  old.new12 = new A();
  old.new15 = new A();
  old.new18 = new A();
}

makeOld() {
  // 2/4 MB worth of Old.
  print("PHASE1");
  var head;
  for (var i = 0; i < 16384; i++) {
    var old = new Old();
    old.next = head;
    head = old;
  }

  // 32/64 MB worth of new objects, all directly reachable from the
  // remembered set.
  print("PHASE2");
  for (var old = head; old != null; old = old.next) {
    fill(old);
  }

  print("PHASE3");
  return head;
}

main(List<String> argsIn) async {
  if (argsIn.contains("--testee")) {
    // Trigger OOM.
    // Must read the fields to prevent the writes from being optimized away. If
    // the writes are optimized away, most of the tree is collectible right away
    // and we timeout instead of triggering OOM.
    print(makeOld());
    return;
  }

  var exec = Platform.executable;
  var args = Platform.executableArguments +
      [
        "--new_gen_semi_max_size=4" /*MB*/,
        "--old_gen_heap_size=15" /*MB*/,
        "--verbose_gc",
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

  Expect.isFalse(result.stderr.contains("error: Out of memory"),
      "Should not see the C++ OUT_OF_MEMORY()");
}
