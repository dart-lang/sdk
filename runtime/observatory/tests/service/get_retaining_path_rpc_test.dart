// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override

import 'dart:async';

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

class _TestClass {
  _TestClass(this.x, this.y);
  var x;
  var y;
}

var target1;
var target2;
var target3;
var globalObject;
var globalList;

void warmup() {
  target1 = new _TestClass(null, null);
  target2 = new _TestClass(null, null);
  globalObject = new _TestClass(target1, target2);

  target3 = new _TestClass(null, null);
  globalList = new List(100);
  globalList[12] = target3;
}

eval(Isolate isolate, String expression) async {
  Map params = {
    'targetId': isolate.rootLib.id,
    'expression': expression,
  };
  return await isolate.invokeRpcNoUpgrade('eval', params);
}

var tests = [
  // simple path
  (Isolate isolate) async {
    var obj = await eval(isolate, 'globalObject');
    var params = {
      'targetId': obj['id'],
      'limit': 4,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['elements'][1]['value']['name'], equals('globalObject'));
  },

  // missing limit.
  (Isolate isolate) async {
    var obj = await eval(isolate, 'globalObject');
    var params = {
      'targetId': obj['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['message'], contains("invalid 'limit' parameter"));
  },

  (Isolate isolate) async {
    var target1 = await eval(
        isolate, '() { var tmp = target1; target1 = null; return tmp;} ()');
    var params = {
      'targetId': target1['id'],
      'limit': 4,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'][0]['parentField']['name'], equals('x'));
    expect(result['elements'][2]['value']['name'], equals('globalObject'));
  },

  (Isolate isolate) async {
    var target2 = await eval(
        isolate, '() { var tmp = target2; target2 = null; return tmp;} ()');
    var params = {
      'targetId': target2['id'],
      'limit': 4,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'][0]['parentField']['name'], equals('y'));
    expect(result['elements'][2]['value']['name'], equals('globalObject'));
  },

  (Isolate isolate) async {
    var target3 = await eval(
        isolate, '() { var tmp = target3; target3 = null; return tmp;} ()');
    var params = {
      'targetId': target3['id'],
      'limit': 4,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'][0]['parentListIndex'], equals(12));
    expect(result['elements'][2]['value']['name'], equals('globalList'));
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore:warmup);
