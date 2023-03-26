// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:observatory/service_io.dart";
import "package:test/test.dart";

import "test_helper.dart";

@pragma("vm:entry-point")
class Class {}

@pragma("vm:entry-point")
class Subclass extends Class {}

@pragma("vm:entry-point")
class Implementor implements Class {}

@pragma("vm:entry-point")
var aClass;
@pragma("vm:entry-point")
var aSubclass;
@pragma("vm:entry-point")
var anImplementor;

@pragma("vm:entry-point")
allocate() {
  aClass = new Class();
  aSubclass = new Subclass();
  anImplementor = new Implementor();
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    invoke(String selector) async {
      Map params = {
        "targetId": isolate.rootLibrary.id,
        "selector": selector,
        "argumentIds": <String>[],
      };
      return await isolate.invokeRpcNoUpgrade("invoke", params);
    }

    Future<int> instanceCount(String className,
        {bool includeSubclasses = false,
        bool includeImplementors = false}) async {
      Map params = {
        "objectId": isolate.rootLibrary.classes
            .singleWhere((cls) => cls.name == className)
            .id,
        "includeSubclasses": includeSubclasses,
        "includeImplementers": includeImplementors,
      };
      var result =
          await isolate.invokeRpcNoUpgrade("getInstancesAsList", params);
      expect(result["type"], equals("@Instance"));
      expect(result["kind"], equals("List"));
      return result["length"] as int;
    }

    await isolate.rootLibrary.load();

    expect(await instanceCount("Class"), equals(0));
    expect(await instanceCount("Class", includeSubclasses: true), equals(0));
    expect(await instanceCount("Class", includeImplementors: true), equals(0));

    await invoke("allocate");

    expect(await instanceCount("Class"), equals(1));
    expect(await instanceCount("Class", includeSubclasses: true), equals(2));
    expect(await instanceCount("Class", includeImplementors: true), equals(3));
  },
];

main(args) async => runIsolateTests(args, tests);
