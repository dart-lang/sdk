// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

class _TestClass {
  _TestClass();
  // Make sure these fields are not removed by the tree shaker.
  @pragma("vm:entry-point")
  dynamic x;
  @pragma("vm:entry-point")
  dynamic y;
}

dynamic target1 = new _TestClass();
dynamic target2 = new _TestClass();
dynamic target3 = new _TestClass();
dynamic target4 = new _TestClass();
dynamic target5 = new _TestClass();
dynamic target6 = new _TestClass();
Expando<_TestClass> expando = Expando<_TestClass>();
@pragma("vm:entry-point") // Prevent obfuscation
dynamic globalObject = new _TestClass();
@pragma("vm:entry-point") // Prevent obfuscation
dynamic globalList = new List<dynamic>.filled(100, null);
@pragma("vm:entry-point") // Prevent obfuscation
dynamic globalMap1 = new Map();
@pragma("vm:entry-point") // Prevent obfuscation
dynamic globalMap2 = new Map();

void warmup() {
  globalObject.x = target1;
  globalObject.y = target2;
  globalList[12] = target3;
  globalMap1['key'] = target4;
  globalMap2[target5] = 'value';
}

@pragma("vm:entry-point")
getGlobalObject() => globalObject;

@pragma("vm:entry-point")
takeTarget1() {
  var tmp = target1;
  target1 = null;
  return tmp;
}

@pragma("vm:entry-point")
takeTarget2() {
  var tmp = target2;
  target2 = null;
  return tmp;
}

@pragma("vm:entry-point")
takeTarget3() {
  var tmp = target3;
  target3 = null;
  return tmp;
}

@pragma("vm:entry-point")
takeTarget4() {
  var tmp = target4;
  target4 = null;
  return tmp;
}

@pragma("vm:entry-point")
takeTarget5() {
  var tmp = target5;
  target5 = null;
  return tmp;
}

@pragma("vm:entry-point")
takeExpandoTarget() {
  var tmp = target6;
  target6 = null;
  var tmp2 = _TestClass();
  expando[tmp] = tmp2;
  return tmp2;
}

@pragma("vm:entry-point")
getTrue() => true;

invoke(Isolate isolate, String selector) async {
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'selector': selector,
    'argumentIds': <String>[],
  };
  return await isolate.invokeRpcNoUpgrade('invoke', params);
}

var tests = <IsolateTest>[
  // simple path
  (Isolate isolate) async {
    var obj = await invoke(isolate, 'getGlobalObject');
    var params = {
      'targetId': obj['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['gcRootType'], 'user global');
    expect(result['elements'].length, equals(2));
    expect(result['elements'][1]['value']['name'], equals('globalObject'));
  },

  // missing limit.
  (Isolate isolate) async {
    var obj = await invoke(isolate, 'getGlobalObject');
    var params = {
      'targetId': obj['id'],
    };
    bool caughtException = false;
    try {
      await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.data!['details'],
          "getRetainingPath expects the \'limit\' parameter");
    }
    expect(caughtException, isTrue);
  },

  (Isolate isolate) async {
    var target1 = await invoke(isolate, 'takeTarget1');
    var params = {
      'targetId': target1['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['gcRootType'], 'user global');
    expect(result['elements'].length, equals(3));
    expect(result['elements'][1]['parentField'], equals('x'));
    expect(result['elements'][2]['value']['name'], equals('globalObject'));
  },

  (Isolate isolate) async {
    var target2 = await invoke(isolate, 'takeTarget2');
    var params = {
      'targetId': target2['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['gcRootType'], 'user global');
    expect(result['elements'].length, equals(3));
    expect(result['elements'][1]['parentField'], equals('y'));
    expect(result['elements'][2]['value']['name'], equals('globalObject'));
  },

  (Isolate isolate) async {
    var target3 = await invoke(isolate, 'takeTarget3');
    var params = {
      'targetId': target3['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['gcRootType'], 'user global');
    expect(result['elements'].length, equals(3));
    expect(result['elements'][1]['parentListIndex'], equals(12));
    expect(result['elements'][2]['value']['name'], equals('globalList'));
  },

  (Isolate isolate) async {
    var target4 = await invoke(isolate, 'takeTarget4');
    var params = {
      'targetId': target4['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['gcRootType'], 'user global');
    expect(result['elements'].length, equals(3));
    expect(
        result['elements'][1]['parentMapKey']['valueAsString'], equals('key'));
    expect(result['elements'][2]['value']['name'], equals('globalMap1'));
  },

  (Isolate isolate) async {
    var target5 = await invoke(isolate, 'takeTarget5');
    var params = {
      'targetId': target5['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(3));
    expect(result['elements'][1]['parentMapKey']['class']['name'],
        equals('_TestClass'));
    expect(result['elements'][2]['value']['name'], equals('globalMap2'));
  },

  (Isolate isolate) async {
    // Regression test for https://github.com/dart-lang/sdk/issues/44016
    var target6 = await invoke(isolate, 'takeExpandoTarget');
    var params = {
      'targetId': target6['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(5));
    expect(result['elements'][1]['parentMapKey']['class']['name'],
        equals('_TestClass'));
    expect(result['elements'][2]['parentListIndex'], isNotNull);
    expect(result['elements'][3]['value']['class']['name'], 'Expando');
    expect(result['elements'][4]['value']['name'], 'expando');
  },

  // object store
  (Isolate isolate) async {
    var obj = await invoke(isolate, 'getTrue');
    var params = {
      'targetId': obj['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(
        result['gcRootType'] == 'class table' ||
            result['gcRootType'] == 'isolate_object store',
        true);
    expect(result['elements'].length, 0);
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
