// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

library get_object_rpc_test;

import 'dart:typed_data';
import 'dart:convert' show base64;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

class _DummyClass {
  static var dummyVar = 11;
  void dummyFunction() {}
}

class _DummySubClass extends _DummyClass {}

void warmup() {
  // Silence analyzer.
  new _DummySubClass();
  new _DummyClass().dummyFunction();
}

eval(Isolate isolate, String expression) async {
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'expression': expression,
  };
  return await isolate.invokeRpcNoUpgrade('evaluate', params);
}

var uint8List = new Uint8List.fromList([3, 2, 1]);
var uint64List = new Uint64List.fromList([3, 2, 1]);

var tests = [
  // null object.
  (Isolate isolate) async {
    var params = {
      'objectId': 'objects/null',
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Null'));
    expect(result['id'], equals('objects/null'));
    expect(result['valueAsString'], equals('null'));
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('Null'));
    expect(result['size'], isPositive);
  },

  // bool object.
  (Isolate isolate) async {
    var params = {
      'objectId': 'objects/bool-true',
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Bool'));
    expect(result['id'], equals('objects/bool-true'));
    expect(result['valueAsString'], equals('true'));
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('bool'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
  },

  // int object.
  (Isolate isolate) async {
    var params = {
      'objectId': 'objects/int-123',
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Int'));
    expect(result['_vmType'], equals('Smi'));
    expect(result['id'], equals('objects/int-123'));
    expect(result['valueAsString'], equals('123'));
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Smi'));
    expect(result['size'], isZero);
    expect(result['fields'], isEmpty);
  },

  // A string
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, '"Chattanooga"');
    var params = {
      'objectId': evalResult['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('String'));
    expect(result['_vmType'], equals('String'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], equals('Chattanooga'));
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_OneByteString'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(11));
    expect(result['offset'], isNull);
    expect(result['count'], isNull);
  },

  // String prefix.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, '"Chattanooga"');
    var params = {
      'objectId': evalResult['id'],
      'count': 4,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('String'));
    expect(result['_vmType'], equals('String'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], equals('Chat'));
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_OneByteString'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(11));
    expect(result['offset'], isNull);
    expect(result['count'], equals(4));
  },

  // String subrange.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, '"Chattanooga"');
    var params = {
      'objectId': evalResult['id'],
      'offset': 4,
      'count': 6,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('String'));
    expect(result['_vmType'], equals('String'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], equals('tanoog'));
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_OneByteString'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(11));
    expect(result['offset'], equals(4));
    expect(result['count'], equals(6));
  },

  // String with wacky offset.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, '"Chattanooga"');
    var params = {
      'objectId': evalResult['id'],
      'offset': 100,
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('String'));
    expect(result['_vmType'], equals('String'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], equals(''));
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_OneByteString'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(11));
    expect(result['offset'], equals(11));
    expect(result['count'], equals(0));
  },

  // A built-in List.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, '[3, 2, 1]');
    var params = {
      'objectId': evalResult['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('List'));
    expect(result['_vmType'], equals('GrowableObjectArray'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_GrowableList'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], isNull);
    expect(result['count'], isNull);
    expect(result['elements'].length, equals(3));
    expect(result['elements'][0]['type'], equals('@Instance'));
    expect(result['elements'][0]['kind'], equals('Int'));
    expect(result['elements'][0]['valueAsString'], equals('3'));
    expect(result['elements'][1]['type'], equals('@Instance'));
    expect(result['elements'][1]['kind'], equals('Int'));
    expect(result['elements'][1]['valueAsString'], equals('2'));
    expect(result['elements'][2]['type'], equals('@Instance'));
    expect(result['elements'][2]['kind'], equals('Int'));
    expect(result['elements'][2]['valueAsString'], equals('1'));
  },

  // List prefix.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, '[3, 2, 1]');
    var params = {
      'objectId': evalResult['id'],
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('List'));
    expect(result['_vmType'], equals('GrowableObjectArray'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_GrowableList'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], isNull);
    expect(result['count'], equals(2));
    expect(result['elements'].length, equals(2));
    expect(result['elements'][0]['type'], equals('@Instance'));
    expect(result['elements'][0]['kind'], equals('Int'));
    expect(result['elements'][0]['valueAsString'], equals('3'));
    expect(result['elements'][1]['type'], equals('@Instance'));
    expect(result['elements'][1]['kind'], equals('Int'));
    expect(result['elements'][1]['valueAsString'], equals('2'));
  },

  // List suffix.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, '[3, 2, 1]');
    var params = {
      'objectId': evalResult['id'],
      'offset': 2,
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('List'));
    expect(result['_vmType'], equals('GrowableObjectArray'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_GrowableList'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], equals(2));
    expect(result['count'], equals(1));
    expect(result['elements'].length, equals(1));
    expect(result['elements'][0]['type'], equals('@Instance'));
    expect(result['elements'][0]['kind'], equals('Int'));
    expect(result['elements'][0]['valueAsString'], equals('1'));
  },

  // List with wacky offset.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, '[3, 2, 1]');
    var params = {
      'objectId': evalResult['id'],
      'offset': 100,
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('List'));
    expect(result['_vmType'], equals('GrowableObjectArray'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_GrowableList'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], equals(3));
    expect(result['count'], equals(0));
    expect(result['elements'], isEmpty);
  },

  // A built-in Map.
  (Isolate isolate) async {
    // Call eval to get a Dart map.
    var evalResult = await eval(isolate, '{"x": 3, "y": 4, "z": 5}');
    var params = {
      'objectId': evalResult['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Map'));
    expect(result['_vmType'], equals('LinkedHashMap'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_InternalLinkedHashMap'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], isNull);
    expect(result['count'], isNull);
    expect(result['associations'].length, equals(3));
    expect(result['associations'][0]['key']['type'], equals('@Instance'));
    expect(result['associations'][0]['key']['kind'], equals('String'));
    expect(result['associations'][0]['key']['valueAsString'], equals('x'));
    expect(result['associations'][0]['value']['type'], equals('@Instance'));
    expect(result['associations'][0]['value']['kind'], equals('Int'));
    expect(result['associations'][0]['value']['valueAsString'], equals('3'));
    expect(result['associations'][1]['key']['type'], equals('@Instance'));
    expect(result['associations'][1]['key']['kind'], equals('String'));
    expect(result['associations'][1]['key']['valueAsString'], equals('y'));
    expect(result['associations'][1]['value']['type'], equals('@Instance'));
    expect(result['associations'][1]['value']['kind'], equals('Int'));
    expect(result['associations'][1]['value']['valueAsString'], equals('4'));
    expect(result['associations'][2]['key']['type'], equals('@Instance'));
    expect(result['associations'][2]['key']['kind'], equals('String'));
    expect(result['associations'][2]['key']['valueAsString'], equals('z'));
    expect(result['associations'][2]['value']['type'], equals('@Instance'));
    expect(result['associations'][2]['value']['kind'], equals('Int'));
    expect(result['associations'][2]['value']['valueAsString'], equals('5'));
  },

  // Map prefix.
  (Isolate isolate) async {
    // Call eval to get a Dart map.
    var evalResult = await eval(isolate, '{"x": 3, "y": 4, "z": 5}');
    var params = {
      'objectId': evalResult['id'],
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Map'));
    expect(result['_vmType'], equals('LinkedHashMap'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_InternalLinkedHashMap'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], isNull);
    expect(result['count'], equals(2));
    expect(result['associations'].length, equals(2));
    expect(result['associations'][0]['key']['type'], equals('@Instance'));
    expect(result['associations'][0]['key']['kind'], equals('String'));
    expect(result['associations'][0]['key']['valueAsString'], equals('x'));
    expect(result['associations'][0]['value']['type'], equals('@Instance'));
    expect(result['associations'][0]['value']['kind'], equals('Int'));
    expect(result['associations'][0]['value']['valueAsString'], equals('3'));
    expect(result['associations'][1]['key']['type'], equals('@Instance'));
    expect(result['associations'][1]['key']['kind'], equals('String'));
    expect(result['associations'][1]['key']['valueAsString'], equals('y'));
    expect(result['associations'][1]['value']['type'], equals('@Instance'));
    expect(result['associations'][1]['value']['kind'], equals('Int'));
    expect(result['associations'][1]['value']['valueAsString'], equals('4'));
  },

  // Map suffix.
  (Isolate isolate) async {
    // Call eval to get a Dart map.
    var evalResult = await eval(isolate, '{"x": 3, "y": 4, "z": 5}');
    var params = {
      'objectId': evalResult['id'],
      'offset': 2,
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Map'));
    expect(result['_vmType'], equals('LinkedHashMap'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_InternalLinkedHashMap'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], equals(2));
    expect(result['count'], equals(1));
    expect(result['associations'].length, equals(1));
    expect(result['associations'][0]['key']['type'], equals('@Instance'));
    expect(result['associations'][0]['key']['kind'], equals('String'));
    expect(result['associations'][0]['key']['valueAsString'], equals('z'));
    expect(result['associations'][0]['value']['type'], equals('@Instance'));
    expect(result['associations'][0]['value']['kind'], equals('Int'));
    expect(result['associations'][0]['value']['valueAsString'], equals('5'));
  },

  // Map with wacky offset
  (Isolate isolate) async {
    // Call eval to get a Dart map.
    var evalResult = await eval(isolate, '{"x": 3, "y": 4, "z": 5}');
    var params = {
      'objectId': evalResult['id'],
      'offset': 100,
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Map'));
    expect(result['_vmType'], equals('LinkedHashMap'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_InternalLinkedHashMap'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], equals(3));
    expect(result['count'], equals(0));
    expect(result['associations'], isEmpty);
  },

  // Uint8List.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, 'uint8List');
    var params = {
      'objectId': evalResult['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Uint8List'));
    expect(result['_vmType'], equals('TypedData'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Uint8List'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], isNull);
    expect(result['count'], isNull);
    expect(result['bytes'], equals('AwIB'));
    Uint8List bytes = base64.decode(result['bytes']);
    expect(bytes.buffer.asUint8List().toString(), equals('[3, 2, 1]'));
  },

  // Uint8List prefix.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, 'uint8List');
    var params = {
      'objectId': evalResult['id'],
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Uint8List'));
    expect(result['_vmType'], equals('TypedData'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Uint8List'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], isNull);
    expect(result['count'], equals(2));
    expect(result['bytes'], equals('AwI='));
    Uint8List bytes = base64.decode(result['bytes']);
    expect(bytes.buffer.asUint8List().toString(), equals('[3, 2]'));
  },

  // Uint8List suffix.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, 'uint8List');
    var params = {
      'objectId': evalResult['id'],
      'offset': 2,
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Uint8List'));
    expect(result['_vmType'], equals('TypedData'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Uint8List'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], equals(2));
    expect(result['count'], equals(1));
    expect(result['bytes'], equals('AQ=='));
    Uint8List bytes = base64.decode(result['bytes']);
    expect(bytes.buffer.asUint8List().toString(), equals('[1]'));
  },

  // Uint8List with wacky offset.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, 'uint8List');
    var params = {
      'objectId': evalResult['id'],
      'offset': 100,
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Uint8List'));
    expect(result['_vmType'], equals('TypedData'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Uint8List'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], equals(3));
    expect(result['count'], equals(0));
    expect(result['bytes'], equals(''));
  },

  // Uint64List.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, 'uint64List');
    var params = {
      'objectId': evalResult['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Uint64List'));
    expect(result['_vmType'], equals('TypedData'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Uint64List'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], isNull);
    expect(result['count'], isNull);
    expect(result['bytes'], equals('AwAAAAAAAAACAAAAAAAAAAEAAAAAAAAA'));
    Uint8List bytes = base64.decode(result['bytes']);
    expect(bytes.buffer.asUint64List().toString(), equals('[3, 2, 1]'));
  },

  // Uint64List prefix.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, 'uint64List');
    var params = {
      'objectId': evalResult['id'],
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Uint64List'));
    expect(result['_vmType'], equals('TypedData'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Uint64List'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], isNull);
    expect(result['count'], equals(2));
    expect(result['bytes'], equals('AwAAAAAAAAACAAAAAAAAAA=='));
    Uint8List bytes = base64.decode(result['bytes']);
    expect(bytes.buffer.asUint64List().toString(), equals('[3, 2]'));
  },

  // Uint64List suffix.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, 'uint64List');
    var params = {
      'objectId': evalResult['id'],
      'offset': 2,
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Uint64List'));
    expect(result['_vmType'], equals('TypedData'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Uint64List'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], equals(2));
    expect(result['count'], equals(1));
    expect(result['bytes'], equals('AQAAAAAAAAA='));
    Uint8List bytes = base64.decode(result['bytes']);
    expect(bytes.buffer.asUint64List().toString(), equals('[1]'));
  },

  // Uint64List with wacky offset.
  (Isolate isolate) async {
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, 'uint64List');
    var params = {
      'objectId': evalResult['id'],
      'offset': 100,
      'count': 2,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Uint64List'));
    expect(result['_vmType'], equals('TypedData'));
    expect(result['id'], startsWith('objects/'));
    expect(result['valueAsString'], isNull);
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Uint64List'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['length'], equals(3));
    expect(result['offset'], equals(3));
    expect(result['count'], equals(0));
    expect(result['bytes'], equals(''));
  },

  // An expired object.
  (Isolate isolate) async {
    var params = {
      'objectId': 'objects/99999999',
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Sentinel'));
    expect(result['kind'], startsWith('Expired'));
    expect(result['valueAsString'], equals('<expired>'));
    expect(result['class'], isNull);
    expect(result['size'], isNull);
  },

  // library.
  (Isolate isolate) async {
    var params = {
      'objectId': isolate.rootLibrary.id,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Library'));
    expect(result['id'], startsWith('libraries/'));
    expect(result['name'], equals('get_object_rpc_test'));
    expect(result['uri'], startsWith('file:'));
    expect(result['uri'], endsWith('get_object_rpc_test.dart'));
    expect(result['debuggable'], equals(true));
    expect(result['dependencies'].length, isPositive);
    expect(result['dependencies'][0]['target']['type'], equals('@Library'));
    expect(result['scripts'].length, isPositive);
    expect(result['scripts'][0]['type'], equals('@Script'));
    expect(result['variables'].length, isPositive);
    expect(result['variables'][0]['type'], equals('@Field'));
    expect(result['functions'].length, isPositive);
    expect(result['functions'][0]['type'], equals('@Function'));
    expect(result['classes'].length, isPositive);
    expect(result['classes'][0]['type'], equals('@Class'));
  },

  // invalid library.
  (Isolate isolate) async {
    var params = {
      'objectId': 'libraries/9999999',
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('getObject', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message,
          "getObject: invalid 'objectId' parameter: libraries/9999999");
    }
    expect(caughtException, isTrue);
  },

  // script.
  (Isolate isolate) async {
    // Get the library first.
    var params = {
      'objectId': isolate.rootLibrary.id,
    };
    var libResult = await isolate.invokeRpcNoUpgrade('getObject', params);
    // Get the first script.
    params = {
      'objectId': libResult['scripts'][0]['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Script'));
    expect(result['id'], startsWith('libraries/'));
    expect(result['uri'], startsWith('file:'));
    expect(result['uri'], endsWith('get_object_rpc_test.dart'));
    expect(result['_kind'], equals(ifKernel('kernel', 'script')));
    expect(result['library']['type'], equals('@Library'));
    expect(result['source'], startsWith('// Copyright (c)'));
    expect(result['tokenPosTable'].length, isPositive);
    expect(result['tokenPosTable'][0], new isInstanceOf<List>());
    expect(result['tokenPosTable'][0].length, isPositive);
    expect(result['tokenPosTable'][0][0], new isInstanceOf<int>());
  },

  // invalid script.
  (Isolate isolate) async {
    var params = {
      'objectId': 'scripts/9999999',
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('getObject', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message,
          "getObject: invalid 'objectId' parameter: scripts/9999999");
    }
    expect(caughtException, isTrue);
  },

  // class
  (Isolate isolate) async {
    // Call eval to get a class id.
    var evalResult = await eval(isolate, 'new _DummyClass()');
    var params = {
      'objectId': evalResult['class']['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Class'));
    expect(result['id'], startsWith('classes/'));
    expect(result['name'], equals('_DummyClass'));
    expect(result['_vmName'], startsWith('_DummyClass@'));
    expect(result['abstract'], equals(false));
    expect(result['const'], equals(false));
    expect(result['_finalized'], equals(true));
    expect(result['_implemented'], equals(false));
    expect(result['_patch'], equals(false));
    expect(result['library']['type'], equals('@Library'));
    expect(result['location']['type'], equals('SourceLocation'));
    expect(result['super']['type'], equals('@Class'));
    expect(result['interfaces'].length, isZero);
    expect(result['fields'].length, isPositive);
    expect(result['fields'][0]['type'], equals('@Field'));
    expect(result['functions'].length, isPositive);
    expect(result['functions'][0]['type'], equals('@Function'));
    expect(result['subclasses'].length, isPositive);
    expect(result['subclasses'][0]['type'], equals('@Class'));
  },

  // invalid class.
  (Isolate isolate) async {
    var params = {
      'objectId': 'classes/9999999',
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('getObject', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message,
          "getObject: invalid 'objectId' parameter: classes/9999999");
    }
    expect(caughtException, isTrue);
  },

  // type.
  (Isolate isolate) async {
    // Call eval to get a class id.
    var evalResult = await eval(isolate, 'new _DummyClass()');
    var id = "${evalResult['class']['id']}/types/0";
    var params = {
      'objectId': id,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('Type'));
    expect(result['id'], equals(id));
    expect(result['class']['type'], equals('@Class'));
    expect(result['class']['name'], equals('_Type'));
    expect(result['size'], isPositive);
    expect(result['fields'], isEmpty);
    expect(result['typeClass']['type'], equals('@Class'));
    expect(result['typeClass']['name'], equals('_DummyClass'));
  },

  // invalid type.
  (Isolate isolate) async {
    var evalResult = await eval(isolate, 'new _DummyClass()');
    var id = "${evalResult['class']['id']}/types/9999999";
    var params = {
      'objectId': id,
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('getObject', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(
          e.message, startsWith("getObject: invalid 'objectId' parameter: "));
    }
    expect(caughtException, isTrue);
  },

  // function.
  (Isolate isolate) async {
    // Call eval to get a class id.
    var evalResult = await eval(isolate, 'new _DummyClass()');
    var id = "${evalResult['class']['id']}/functions/dummyFunction";
    var params = {
      'objectId': id,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Function'));
    expect(result['id'], equals(id));
    expect(result['name'], equals('dummyFunction'));
    expect(result['_kind'], equals('RegularFunction'));
    expect(result['static'], equals(false));
    expect(result['const'], equals(false));
    expect(result['location']['type'], equals('SourceLocation'));
    expect(result['code']['type'], equals('@Code'));
    expect(result['_optimizable'], equals(true));
    expect(result['_inlinable'], equals(true));
    expect(result['_usageCounter'], isPositive);
    expect(result['_optimizedCallSiteCount'], isZero);
    expect(result['_deoptimizations'], isZero);
  },

  // invalid function.
  (Isolate isolate) async {
    // Call eval to get a class id.
    var evalResult = await eval(isolate, 'new _DummyClass()');
    var id = "${evalResult['class']['id']}/functions/invalid";
    var params = {
      'objectId': id,
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('getObject', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(
          e.message, startsWith("getObject: invalid 'objectId' parameter: "));
    }
    expect(caughtException, isTrue);
  },

  // field
  (Isolate isolate) async {
    // Call eval to get a class id.
    var evalResult = await eval(isolate, 'new _DummyClass()');
    var id = "${evalResult['class']['id']}/fields/dummyVar";
    var params = {
      'objectId': id,
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Field'));
    expect(result['id'], equals(id));
    expect(result['name'], equals('dummyVar'));
    expect(result['const'], equals(false));
    expect(result['static'], equals(true));
    expect(result['final'], equals(false));
    expect(result['location']['type'], equals('SourceLocation'));
    expect(result['staticValue']['valueAsString'], equals('11'));
    expect(result['_guardNullable'], isNotNull);
    expect(result['_guardClass'], isNotNull);
    expect(result['_guardLength'], isNotNull);
  },

  // invalid field.
  (Isolate isolate) async {
    // Call eval to get a class id.
    var evalResult = await eval(isolate, 'new _DummyClass()');
    var id = "${evalResult['class']['id']}/fields/mythicalField";
    var params = {
      'objectId': id,
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('getObject', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(
          e.message, startsWith("getObject: invalid 'objectId' parameter: "));
    }
    expect(caughtException, isTrue);
  },

  // code.
  (Isolate isolate) async {
    // Call eval to get a class id.
    var evalResult = await eval(isolate, 'new _DummyClass()');
    var funcId = "${evalResult['class']['id']}/functions/dummyFunction";
    var params = {
      'objectId': funcId,
    };
    var funcResult = await isolate.invokeRpcNoUpgrade('getObject', params);
    params = {
      'objectId': funcResult['code']['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    expect(result['type'], equals('Code'));
    expect(result['name'], equals('_DummyClass.dummyFunction'));
    expect(result['_vmName'], equals('dummyFunction'));
    expect(result['kind'], equals('Dart'));
    expect(result['_optimized'], new isInstanceOf<bool>());
    expect(result['function']['type'], equals('@Function'));
    expect(result['_startAddress'], new isInstanceOf<String>());
    expect(result['_endAddress'], new isInstanceOf<String>());
    expect(result['_objectPool'], isNotNull);
    expect(result['_disassembly'], isNotNull);
    expect(result['_descriptors'], isNotNull);
    expect(
        result['_inlinedFunctions'], anyOf([isNull, new isInstanceOf<List>()]));
    expect(
        result['_inlinedIntervals'], anyOf([isNull, new isInstanceOf<List>()]));
  },

  // invalid code.
  (Isolate isolate) async {
    var params = {
      'objectId': 'code/0',
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('getObject', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message, "getObject: invalid 'objectId' parameter: code/0");
    }
    expect(caughtException, isTrue);
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
