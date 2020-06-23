// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'dart:developer';

import "get_source_report_with_mixin_lib2.dart";
import "get_source_report_with_mixin_lib3.dart";

const String lib1Filename = "get_source_report_with_mixin_lib1";
const String lib3Filename = "get_source_report_with_mixin_lib3";

void testFunction() {
  final Test1 test1 = new Test1();
  test1.foo();
  final Test2 test2 = new Test2();
  test2.bar();
  debugger();
  print("done");
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
    Script foundScript;
    for (Script script in scripts) {
      if (script.uri.contains(lib1Filename)) {
        foundScript = script;
        break;
      }
    }

    Set<int> hits;
    {
      // Get report for everything; then collect for lib1.
      final Map<String, Object> params = {
        'reports': ['Coverage'],
      };
      final coverage =
          await isolate.invokeRpcNoUpgrade('getSourceReport', params);
      hits = getHitsForLib1(coverage, lib1Filename);
      expect(hits.length, greaterThanOrEqualTo(2));
      print(hits);
    }
    {
      // Now get report for the lib1 only.
      final Map<String, Object> params = {
        'reports': ['Coverage'],
        'scriptId': foundScript.id
      };
      final coverage =
          await isolate.invokeRpcNoUpgrade('getSourceReport', params);
      final Set<int> localHits = getHitsForLib1(coverage, lib1Filename);
      expect(localHits.length, equals(hits.length));
      expect(hits.toList()..sort(), equals(localHits.toList()..sort()));
      print(localHits);
    }
  },
];

Set<int> getHitsForLib1(Map coverage, String uriContains) {
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
