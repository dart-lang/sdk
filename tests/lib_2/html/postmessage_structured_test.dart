// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library postmessage_js_test;

import 'dart:async';
import 'dart:html';
import 'dart:collection' show HashMap, SplayTreeMap;
import 'dart:typed_data';

import 'package:expect/minitest.dart';

import 'utils.dart';

final isMap = predicate((v) => v is Map);

void injectSource(String code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = code;
  document.body.append(script);
}

Future go(String name, dynamic value) {
  // Round-trip graph from Dart to JavaScript and back.

  final JS_CODE = """
            window.addEventListener('message', handler);
            function handler(e) {
              var data = e.data;
              if (typeof data == 'string') return;
              if (data.recipient != 'JS') return;
              window.console.log(data.data);
              var response = {recipient: 'DART', data: data.data};
              window.removeEventListener('message', handler);
              window.postMessage(response, '*');
            }
            """;
  final done = new Completer();
  var subscription;
  subscription = window.onMessage.listen((e) {
    var data = e.data;
    if (data is String) return; // Messages from unit test protocol.
    if (data['recipient'] != 'DART') return; // Not for me.
    try {
      subscription.cancel();
      expect(data, isMap);
      var returnedValue = data['data'];
      expect(returnedValue, notEquals(value));
      verifyGraph(value, returnedValue);
      done.complete();
    } catch (e) {
      done.completeError('$name failed: $e');
    }
  });
  injectSource(JS_CODE);
  window.postMessage({'recipient': 'JS', 'data': value}, '*');
  return done.future;
}

Future primitives() async {
  await testJsToDartPostmessage();

  var obj1 = {'a': 100, 'b': 's'};
  var obj2 = {'x': obj1, 'y': obj1}; // DAG.

  var obj3 = <String, dynamic>{};
  obj3['a'] = 100;
  obj3['b'] = obj3; // Cycle.

  var obj4 = new SplayTreeMap<String, dynamic>(); // Different implementation.
  obj4['a'] = 100;
  obj4['b'] = 's';

  var cyclic_list = <dynamic>[1, 2, 3];
  cyclic_list[1] = cyclic_list;

  await go('test_simple_list', [1, 2, 3]);
  await go('test_map', obj1);
  await go('test_DAG', obj2);
  await go('test_cycle', obj3);
  await go('test_simple_splay', obj4);
  await go('const_array_1', const [
    const [1],
    const [2]
  ]);
  await go('const_array_dag', const [
    const [1],
    const [1]
  ]);
  await go('array_deferred_copy', [1, 2, 3, obj3, obj3, 6]);
  await go('array_deferred_copy_2', [
    1,
    2,
    3,
    [4, 5, obj3],
    [obj3, 6]
  ]);
  await go('cyclic_list', cyclic_list);
}

Future testJsToDartPostmessage() {
  // Pass an object literal from JavaScript. It should be seen as a Dart Map.
  final JS_CODE = """
        window.postMessage({eggs: 3}, '*');
        """;
  final done = new Completer();
  var subscription = null;
  subscription = window.onMessage.listen((e) {
    var data = e.data;
    if (data is String) return; //    Messages from unit test protocol.
    try {
      subscription.cancel();
      expect(data, isMap);
      expect(data['eggs'], equals(3));
      done.complete();
    } catch (e) {
      done.completeError(e);
    }
  });
  injectSource(JS_CODE);
  return done.future;
}

Future morePrimitives() async {
  await testJsToDartNullPrototypeEventdata();
}

Future testJsToDartNullPrototypeEventdata() {
  // Pass an object with a null prototype from JavaScript.
  // It should be seen as a Dart Map.
  final JS_CODE = """
       // Call anonymous function to create a local scope.
       (function() {
          var o = Object.create(null);
          o.eggs = 3;
          var foo = new MessageEvent('stuff', {data: o});
          window.dispatchEvent(foo);
        })();
      """;
  final done = new Completer();
  var subscription = null;
  subscription = window.on['stuff'].listen((e) {
    var data = (e as MessageEvent).data;
    if (data is String) return; // Messages from unit test protocol.
    try {
      subscription.cancel();
      expect(data, isMap);
      expect(data['eggs'], equals(3));
      done.complete();
    } catch (e) {
      done.completeError(e);
    }
  });
  injectSource(JS_CODE);
  return done.future;
}

Future typedArrays() async {
  var array_buffer = new Uint8List(16).buffer;
  var view_a = new Float32List.view(array_buffer, 0, 4);
  var view_b = new Uint8List.view(array_buffer, 1, 13);
  var typed_arrays_list = [view_a, array_buffer, view_b];

  // Note that FF is failing this test because in the sent message:
  // view_a.buffer == array_buffer
  // But in the response:
  // view_a.buffer != array_buffer
  await go('typed_arrays_list', typed_arrays_list);
}

Future iframe() async {
  await postMessageClonesData();
}

Future postMessageClonesData() {
  var iframe = new IFrameElement();
  var future = iframe.onLoad.first.then((_) {
    iframe.contentWindow.postMessage(new HashMap<String, num>(), '*');
  });
  iframe.src = 'about:blank';
  document.body.append(iframe);

  return future;
}

main() async {
  await primitives();
  await morePrimitives();
  await typedArrays();
  await iframe();
}
