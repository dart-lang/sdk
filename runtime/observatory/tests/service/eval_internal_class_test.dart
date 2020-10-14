// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library root = await isolate.rootLibrary.load() as Library;

    Class classLibrary = await root.clazz!.load() as Class;
    print(classLibrary);
    {
      bool caughtExceptions = false;
      try {
        dynamic result = await classLibrary.evaluate('3 + 4');
        print(result);
      } on ServerRpcException catch (e) {
        expect(e.toString(), contains('can be evaluated only'));
        caughtExceptions = true;
      }
      expect(caughtExceptions, isTrue);
    }

    Class classClass = await classLibrary.clazz!.load() as Class;
    print(classClass);
    {
      bool caughtExceptions = false;
      try {
        dynamic result = await classClass.evaluate('3 + 4');
        print(result);
      } on ServerRpcException catch (e) {
        expect(e.toString(), contains('can be evaluated only'));
        caughtExceptions = true;
      }
      expect(caughtExceptions, isTrue);
    }

    Instance someArray =
        await root.evaluate("new List<dynamic>.filled(2, null)") as Instance;
    print(someArray);
    expect(someArray is Instance, isTrue);
    Class classArray = await someArray.clazz!.load() as Class;
    print(classArray);
    dynamic result = await classArray.evaluate('3 + 4');
    print(result);
    expect(result is Instance, isTrue);
    expect(result.valueAsString, equals('7'));
  },
];

main(args) => runIsolateTests(args, tests);
