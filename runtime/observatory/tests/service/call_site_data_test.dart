// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_filter=doesNotExist
// ^Force code to be unoptimized so the invocation counts are accurate.

library call_site_data_test;

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

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

class Static {
  static staticMethod() => 2;
}
staticCall() {
  Static.staticMethod();
  return null;
}
constructorCall() {
  new Static();
  return null;
}
topLevelMethod() => "TOP";
topLevelCall() {
  topLevelMethod();
  return null;
}

class Super { bar() => "Super"; }
class Sub extends Super { bar() => super.bar(); }

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

  for (int i = 0; i < 10; i++) staticCall();

  for (int i = 0; i < 10; i++) constructorCall();

  for (int i = 0; i < 10; i++) topLevelCall();

  for (int i = 0; i < 15; i++) new Sub().bar();
}


Set<String> stringifyCacheEntries(Map callSite) {
  return callSite['cacheEntries'].map((entry) {
    return "${entry['receiverContainer']['name']}:${entry['count']}";
  }).toSet();
}


testMonomorphic(Isolate isolate) async {
  Library lib = await isolate.rootLibrary.load();
  ServiceFunction func =
     lib.functions.singleWhere((f) => f.name == 'monomorphic');
  Map response = await isolate.invokeRpcNoUpgrade('_getCallSiteData',
                                                  { 'targetId': func.id });
  expect(response['type'], equals('CodeCoverage'));
  Map callSite = response['coverage'].single['callSites'].single;
  expect(callSite['name'], equals('foo'));
  expect(stringifyCacheEntries(callSite),
         equals(['A:10'].toSet()));
}

testPolymorphic(Isolate isolate) async {
  Library lib = await isolate.rootLibrary.load();
  ServiceFunction func =
     lib.functions.singleWhere((f) => f.name == 'polymorphic');
  Map response = await isolate.invokeRpcNoUpgrade('_getCallSiteData',
                                                  { 'targetId': func.id });
  expect(response['type'], equals('CodeCoverage'));
  Map callSite = response['coverage'].single['callSites'].single;
  expect(callSite['name'], equals('foo'));
  expect(stringifyCacheEntries(callSite),
         equals(['A:10', 'B:20', 'C:30'].toSet()));
}

testMegamorphic(Isolate isolate) async {
  Library lib = await isolate.rootLibrary.load();
  ServiceFunction func =
     lib.functions.singleWhere((f) => f.name == 'megamorphic');
  Map response = await isolate.invokeRpcNoUpgrade('_getCallSiteData',
                                                  { 'targetId': func.id });
  expect(response['type'], equals('CodeCoverage'));
  Map callSite = response['coverage'].single['callSites'].single;
  expect(callSite['name'], equals('foo'));
  expect(stringifyCacheEntries(callSite),
         equals(['A:10', 'B:20', 'C:30', 'D:40',
                 'E:50', 'F:60', 'G:70', 'H:80'].toSet()));
}

testStaticCall(Isolate isolate) async {
  Library lib = await isolate.rootLibrary.load();
  ServiceFunction func =
     lib.functions.singleWhere((f) => f.name == 'staticCall');
  Map response = await isolate.invokeRpcNoUpgrade('_getCallSiteData',
                                                  { 'targetId': func.id });
  expect(response['type'], equals('CodeCoverage'));
  Map callSite = response['coverage'].single['callSites'].single;
  expect(callSite['name'], equals('staticMethod'));
  expect(stringifyCacheEntries(callSite),
         equals(['Static:10'].toSet()));
}

testConstructorCall(Isolate isolate) async {
  Library lib = await isolate.rootLibrary.load();
  ServiceFunction func =
     lib.functions.singleWhere((f) => f.name == 'constructorCall');
  Map response = await isolate.invokeRpcNoUpgrade('_getCallSiteData',
                                                  { 'targetId': func.id });
  expect(response['type'], equals('CodeCoverage'));
  Map callSite = response['coverage'].single['callSites'].single;
  expect(callSite['name'], equals('Static.'));
  expect(stringifyCacheEntries(callSite),
         equals(['Static:10'].toSet()));
}

testTopLevelCall(Isolate isolate) async {
  Library lib = await isolate.rootLibrary.load();
  ServiceFunction func =
     lib.functions.singleWhere((f) => f.name == 'topLevelCall');
  Map response = await isolate.invokeRpcNoUpgrade('_getCallSiteData',
                                                  { 'targetId': func.id });
  expect(response['type'], equals('CodeCoverage'));
  Map callSite = response['coverage'].single['callSites'].single;
  expect(callSite['name'], equals('topLevelMethod'));
  expect(stringifyCacheEntries(callSite),
         equals(['call_site_data_test:10'].toSet()));
}

testSuperCall(Isolate isolate) async {
  Library lib = await isolate.rootLibrary.load();
  Class cls = await lib.classes.singleWhere((f) => f.name == 'Sub').load();
  ServiceFunction func = cls.functions.singleWhere((f) => f.name == 'bar');
  Map response = await isolate.invokeRpcNoUpgrade('_getCallSiteData',
                                                  { 'targetId': func.id });
  expect(response['type'], equals('CodeCoverage'));
  Map callSite = response['coverage'].single['callSites'].single;
  expect(callSite['name'], equals('bar'));
  expect(stringifyCacheEntries(callSite),
         equals(['Super:15'].toSet()));
}

var tests = [
    testMonomorphic,
    testPolymorphic,
    testMegamorphic,
    testStaticCall,
    testConstructorCall,
    testTopLevelCall,
    testSuperCall ];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
