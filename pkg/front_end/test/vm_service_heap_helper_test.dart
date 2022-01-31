// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:front_end/src/api_unstable/util.dart';

import "vm_service_heap_helper.dart" as helper;

Future<void> main(List<String> args) async {
  if (args.contains("--leak")) {
    return doLeak();
  }

  List<helper.Interest> interests = <helper.Interest>[];
  interests.add(
    new helper.Interest(
      Platform.script,
      "LeakMe",
      ["unique"],
    ),
  );
  interests.add(
    new helper.Interest(
      Platform.script,
      "LeakMe2",
      ["uniquePart1", "uniquePart2"],
    ),
  );
  LeakFinderTest heapHelper = new LeakFinderTest(
    interests: interests,
    prettyPrints: [
      new helper.Interest(
        Platform.script,
        "LeakMe",
        ["unique", "forPrettyPrinting"],
      ),
      new helper.Interest(
        Platform.script,
        "LeakMe2",
        ["uniquePart1", "uniquePart2", "forPrettyPrinting"],
      ),
    ],
    throwOnPossibleLeak: false,
  );

  await heapHelper.start(
    [
      "--enable-asserts",
      Platform.script.toString(),
      "--leak",
    ],
    stderrReceiver: (s) {},
    stdoutReceiver: (s) {},
  );
  List<String> expectedData = [
    '1: no leak',
    '2: 2: [LeakMe[unique: "a", forPrettyPrinting: "1"], '
        'LeakMe[unique: "a", forPrettyPrinting: "3"]]',
    '3: 2: [LeakMe[unique: "a", forPrettyPrinting: "1"], '
        'LeakMe[unique: "a", forPrettyPrinting: "3"]]',
    '3: 2: [LeakMe[unique: "b", forPrettyPrinting: "2"], '
        'LeakMe[unique: "b", forPrettyPrinting: "4"]]',
    '4: no leak',
    '5: no leak',
    '6: 2: ['
        'LeakMe2[uniquePart1: "a", uniquePart2: "a", forPrettyPrinting: "1"], '
        'LeakMe2[uniquePart1: "a", uniquePart2: "a", forPrettyPrinting: "4"]'
        ']',
  ];
  List<String> leakData = await heapHelper.completer.future;
  if (!equalLists(expectedData, leakData)) {
    throw "Expected and actual not equal:\n\n"
        "- ${expectedData.join("\n- ")}\n\n"
        "vs\n\n"
        "- ${leakData.join("\n- ")}";
  }

  print("Done!");
}

void doLeak() {
  {
    LeakMe a = new LeakMe("a", "1");
    LeakMe b = new LeakMe("b", "2");
    // Expect no leaks.
    debugger();
    LeakMe a2 = new LeakMe("a", "3");
    // Expect one leak: We find leaks for class `LeakMe` based on the first
    // field (`unique`). Now we have two objects with the same data ("a") for
    // this field: `a` and `a2`. That's a leak as we've defined it.
    debugger();
    LeakMe b2 = new LeakMe("b", "4");
    // Expect two leaks: We find leaks for class `LeakMe` based on the first
    // field (`unique`). Now we have two objects with data "a" (`a` and `a2`)
    // and two objects with data "b" (`b` and `b2`).
    debugger();
    print("$a, $b, $a2, $b2");
  }
  {
    LeakMe2 a = new LeakMe2("a", "a", "1");
    LeakMe2 b = new LeakMe2("b", "b", "2");
    // Expect no leaks.
    debugger();
    LeakMe2 a2 = new LeakMe2("a", "foo", "3");
    // Expect no leak.
    debugger();
    LeakMe2 a3 = new LeakMe2("a", "a", "4");
    // Expect one leak: We find leaks for class `LeakMe2` based on the first
    // field AND the second field (`uniquePart1` and `uniquePart2`). Now we have
    // two objects with the same data in both fields ("a" and "a" for part 1 and
    // part 2) namely the objects saved in variables `a` and `a3`.
    // Notice how the object in variable `a2` did not introduce a leak even
    // though part 1 match ("a") as part 2 doesn't ("a" vs "foo").
    debugger();
    print("$a, $b, $a2, $a3");
  }
}

class LeakMe {
  final String unique;
  final String forPrettyPrinting;

  LeakMe(this.unique, this.forPrettyPrinting);
}

class LeakMe2 {
  final String uniquePart1;
  final String uniquePart2;
  final String forPrettyPrinting;

  LeakMe2(this.uniquePart1, this.uniquePart2, this.forPrettyPrinting);
}

class LeakFinderTest extends helper.VMServiceHeapHelperSpecificExactLeakFinder {
  List<String> leakData = [];
  @override
  int iterationNumber = -1;
  Completer<List<String>> completer = new Completer<List<String>>();

  LeakFinderTest({
    required List<helper.Interest> interests,
    required List<helper.Interest> prettyPrints,
    required bool throwOnPossibleLeak,
  }) : super(
            interests: interests,
            prettyPrints: prettyPrints,
            throwOnPossibleLeak: throwOnPossibleLeak);

  @override
  void processExited(int exitCode) {
    print("Process exited!");
    leakData.sort();
    completer.complete(leakData);
  }

  @override
  void leakDetected(String duplicate, int count, List<String> prettyPrints) {
    prettyPrints.sort();
    leakData.add("$iterationNumber: $count: $prettyPrints");
  }

  @override
  void noLeakDetected() {
    leakData.add("$iterationNumber: no leak");
  }

  @override
  bool shouldDoAnotherIteration(int iterationNumber) {
    this.iterationNumber = iterationNumber;
    return iterationNumber <= 6;
  }
}
