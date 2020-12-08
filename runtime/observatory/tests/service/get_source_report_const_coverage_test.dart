// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'dart:developer';

import 'get_source_report_const_coverage_lib.dart' as lib;

const String filename = "get_source_report_const_coverage_test";
const Set<int> expectedLinesHit = {20, 22, 26};
const Set<int> expectedLinesNotHit = {24};

class Foo {
  final int x;
  // Expect this constructor to be coverage by coverage.
  const Foo([int? x]) : this.x = x ?? 42;
  // Expect this constructor to be coverage by coverage too.
  const Foo.named1([int? x]) : this.x = x ?? 42;
  // Expect this constructor to *NOT* be coverage by coverage.
  const Foo.named2([int? x]) : this.x = x ?? 42;
  // Expect this constructor to be coverage by coverage too (from lib).
  const Foo.named3([int? x]) : this.x = x ?? 42;
}

void testFunction() {
  const foo = Foo();
  const foo2 = Foo();
  const fooIdentical = identical(foo, foo2);
  print(fooIdentical);

  const namedFoo = Foo.named1();
  const namedFoo2 = Foo.named1();
  const namedIdentical = identical(namedFoo, namedFoo2);
  print(fooIdentical);

  debugger();

  // That this is called after (or at all) is not relevent for the code
  // coverage of constants.
  lib.testFunction();

  print("Done");
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    final stack = await isolate.getStack();

    // Make sure we are in the right place.
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    expect(stack['frames'][0].function.name, equals('testFunction'));

    final List<Script> scripts = await isolate.getScripts();
    Script? foundScript;
    for (Script script in scripts) {
      if (script.uri.contains(filename)) {
        foundScript = script;
        break;
      }
    }

    Set<int> hits;
    {
      // Get report for everything; then collect for this library.
      final Map<String, Object> params = {
        'reports': ['Coverage'],
      };
      final coverage =
          await isolate.invokeRpcNoUpgrade('getSourceReport', params);
      hits = getHitsFor(coverage, filename);
      await foundScript!.load();
      final Set<int> lines = {};
      for (int hit in hits) {
        // We expect every hit to be translatable to line
        // (i.e. tokenToLine to return non-null).
        lines.add(foundScript.tokenToLine(hit)!);
      }
      print("Token position hits: $hits --- line hits: $lines");
      expect(lines.intersection(expectedLinesHit), equals(expectedLinesHit));
      expect(lines.intersection(expectedLinesNotHit), isEmpty);
    }
    {
      // Now get report for the this file only.
      final Map<String, Object> params = {
        'reports': ['Coverage'],
        'scriptId': foundScript.id!
      };
      final coverage =
          await isolate.invokeRpcNoUpgrade('getSourceReport', params);
      final Set<int> localHits = getHitsFor(coverage, filename);
      expect(localHits.length, equals(hits.length));
      expect(hits.toList()..sort(), equals(localHits.toList()..sort()));
      print(localHits);
    }
  },
];

Set<int> getHitsFor(Map coverage, String uriContains) {
  final List scripts = coverage["scripts"];
  final Set<int> scriptIdsWanted = {};
  for (int i = 0; i < scripts.length; i++) {
    final Map script = scripts[i];
    final String scriptUri = script["uri"];
    if (scriptUri.contains(uriContains)) {
      scriptIdsWanted.add(i);
    }
  }
  final List ranges = coverage["ranges"];
  final Set<int> hits = {};
  for (int i = 0; i < ranges.length; i++) {
    final Map range = ranges[i];
    if (scriptIdsWanted.contains(range["scriptIndex"])) {
      if (range["coverage"] != null) {
        for (int hit in range["coverage"]["hits"]) {
          hits.add(hit);
        }
      }
    }
  }
  return hits;
}

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
