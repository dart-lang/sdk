// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library call_site_data_test;

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

class A { foo() => 'A'; }
class B { foo() => 'B'; }
class C { foo() => 'C'; }
class D { foo() => 'D'; }
class E { foo() => 'E'; }
class F { foo() => 'F'; }
class G { foo() => 'G'; }
class H { foo() => 'H'; }

monomorphic(fooable) {
  fooable.foo();
  return null;
}
polymorphic(fooable) {
  fooable.foo();
  return null;
}
megamorphic(fooable) {
  fooable.foo();
  return null;
}

script() {
  for (int i = 0; i < 10; i++) monomorphic(new A());

  for (int i = 0; i < 10; i++) polymorphic(new A());
  for (int i = 0; i < 20; i++) polymorphic(new B());
  for (int i = 0; i < 30; i++) polymorphic(new C());

  for (int i = 0; i < 10; i++) megamorphic(new A());
  for (int i = 0; i < 20; i++) megamorphic(new B());
  for (int i = 0; i < 30; i++) megamorphic(new C());
  for (int i = 0; i < 40; i++) megamorphic(new D());
  for (int i = 0; i < 50; i++) megamorphic(new E());
  for (int i = 0; i < 60; i++) megamorphic(new F());
  for (int i = 0; i < 70; i++) megamorphic(new G());
  for (int i = 0; i < 80; i++) megamorphic(new H());
}


Set<String> stringifyCacheEntries(Map callSite) {
  return callSite['cacheEntries'].map((entry) {
    return "${entry['receiverClass']['name']}:${entry['count']}";
  }).toSet();
}

var tests = [
(Isolate isolate) {
  return isolate.rootLib.load().then((Library lib) {
    var monomorphic = lib.functions.singleWhere((f) => f.name == 'monomorphic');
    var polymorphic = lib.functions.singleWhere((f) => f.name == 'polymorphic');
    var megamorphic = lib.functions.singleWhere((f) => f.name == 'megamorphic');

    List tests = [];
    tests.add(isolate.invokeRpcNoUpgrade('getCallSiteData',
                                         { 'targetId': monomorphic.id })
                .then((Map response) {
                    print("Monomorphic: $response");
                    expect(response['type'], equals('_CallSiteData'));
                    expect(response['function']['id'], equals(monomorphic.id));
                    expect(response['callSites'], isList);
                    expect(response['callSites'], hasLength(1));
                    Map callSite = response['callSites'].single;
                    expect(callSite['name'], equals('foo'));
                    // expect(callSite['deoptReasons'], equals(''));
                    expect(stringifyCacheEntries(callSite),
                           equals(['A:10'].toSet()));
                }));

    tests.add(isolate.invokeRpcNoUpgrade('getCallSiteData',
                                         { 'targetId': polymorphic.id })
                .then((Map response) {
                    print("Polymorphic: $response");
                    expect(response['type'], equals('_CallSiteData'));
                    expect(response['function']['id'], equals(polymorphic.id));
                    expect(response['callSites'], isList);
                    expect(response['callSites'], hasLength(1));
                    Map callSite = response['callSites'].single;
                    expect(callSite['name'], equals('foo'));
                    // expect(callSite['deoptReasons'], equals(''));
                    expect(stringifyCacheEntries(callSite),
                           equals(['A:10', 'B:20', 'C:30'].toSet()));
                }));

    tests.add(isolate.invokeRpcNoUpgrade('getCallSiteData',
                                         { 'targetId': megamorphic.id })
                .then((Map response) {
                    print("Megamorphic: $response");
                    expect(response['type'], equals('_CallSiteData'));
                    expect(response['function']['id'], equals(megamorphic.id));
                    expect(response['callSites'], isList);
                    expect(response['callSites'], hasLength(1));
                    Map callSite = response['callSites'].single;
                    expect(callSite['name'], equals('foo'));
                    // expect(callSite['deoptReasons'], equals(''));
                    expect(stringifyCacheEntries(callSite),
                           equals(['A:10', 'B:20', 'C:30', 'D:40',
                                   'E:50', 'F:60', 'G:70', 'H:80'].toSet()));
                }));

    return Future.wait(tests);
  });
},

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
