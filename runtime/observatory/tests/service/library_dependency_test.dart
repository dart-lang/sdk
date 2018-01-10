// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

export 'dart:collection';
import 'dart:mirrors' as mirrors;
import 'dart:convert' deferred as convert;

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var lib = await isolate.rootLibrary.load();
    // Use mirrors to shutup the analyzer.
    mirrors.currentMirrorSystem();
    importOf(String uri) {
      return lib.dependencies.singleWhere((dep) => dep.target.uri == uri);
    }

    expect(importOf("dart:collection").isImport, isFalse);
    expect(importOf("dart:collection").isExport, isTrue);
    expect(importOf("dart:collection").isDeferred, isFalse);
    expect(importOf("dart:collection").prefix, equals(null));

    expect(importOf("dart:mirrors").isImport, isTrue);
    expect(importOf("dart:mirrors").isExport, isFalse);
    expect(importOf("dart:mirrors").isDeferred, isFalse);
    expect(importOf("dart:mirrors").prefix, equals("mirrors"));

    expect(importOf("dart:convert").isImport, isTrue);
    expect(importOf("dart:convert").isExport, isFalse);
    expect(importOf("dart:convert").isDeferred, isTrue);
    expect(importOf("dart:convert").prefix, equals("convert"));
  },
  (Isolate isolate) async {
    return convert.loadLibrary();
  }
];

main(args) => runIsolateTests(args, tests);
