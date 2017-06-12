// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library postmessage_js_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import 'dart:collection'; // SplayTreeMap
import 'dart:typed_data';
import 'utils.dart';

injectSource(code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = code;
  document.body.append(script);
}

main() {
  useHtmlIndividualConfiguration();

  go(testName, value) => test(testName, () {
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
        var completed = false;
        var subscription = null;
        subscription = window.onMessage.listen(expectAsyncUntil((e) {
          var data = e.data;
          if (data is String) return; // Messages from unit test protocol.
          if (data['recipient'] != 'DART') return; // Not for me.
          completed = true;
          subscription.cancel();
          expect(data, isMap);
          var returnedValue = data['data'];
          expect(returnedValue, isNot(same(value)));
          verifyGraph(value, returnedValue);
        }, () => completed));
        injectSource(JS_CODE);
        window.postMessage({'recipient': 'JS', 'data': value}, '*');
      });

  group('primitives', () {
    test('js-to-dart-postmessage', () {
      // Pass an object literal from JavaScript. It should be seen as a Dart
      // Map.

      final JS_CODE = """
        window.postMessage({eggs: 3}, '*');
        """;
      var completed = false;
      var subscription = null;
      subscription = window.onMessage.listen(expectAsyncUntil((e) {
        var data = e.data;
        if (data is String) return; //    Messages from unit test protocol.
        completed = true;
        subscription.cancel();
        expect(data, isMap);
        expect(data['eggs'], equals(3));
      }, () => completed));
      injectSource(JS_CODE);
    });

    test('dart-to-js-to-dart-postmessage', () {
      // Pass dictionaries between Dart and JavaScript.

      final JS_CODE = """
        window.addEventListener('message', handler);
        function handler(e) {
          var data = e.data;
          if (typeof data == 'string') return;
          if (data.recipient != 'JS') return;
          var response = {recipient: 'DART'};
          response[data['curry']] = 50;
          window.removeEventListener('message', handler);
          window.postMessage(response, '*');
        }
        """;
      var completed = false;
      var subscription = null;
      subscription = window.onMessage.listen(expectAsyncUntil((e) {
        var data = e.data;
        if (data is String) return; //    Messages from unit test protocol.
        if (data['recipient'] != 'DART') return; // Hearing the sent message.
        completed = true;
        subscription.cancel();
        expect(data, isMap);
        expect(data['peas'], equals(50));
      }, () => completed));
      injectSource(JS_CODE);
      window.postMessage({'recipient': 'JS', 'curry': 'peas'}, '*');
    });

    var obj1 = {'a': 100, 'b': 's'};
    var obj2 = {'x': obj1, 'y': obj1}; // DAG.

    var obj3 = {};
    obj3['a'] = 100;
    obj3['b'] = obj3; // Cycle.

    var obj4 = new SplayTreeMap<String, dynamic>(); // Different implementation.
    obj4['a'] = 100;
    obj4['b'] = 's';

    var cyclic_list = [1, 2, 3];
    cyclic_list[1] = cyclic_list;

    go('test_simple_list', [1, 2, 3]);
    go('test_map', obj1);
    go('test_DAG', obj2);
    go('test_cycle', obj3);
    go('test_simple_splay', obj4);
    go('const_array_1', const [
      const [1],
      const [2]
    ]);
    go('const_array_dag', const [
      const [1],
      const [1]
    ]);
    go('array_deferred_copy', [1, 2, 3, obj3, obj3, 6]);
    go('array_deferred_copy_2', [
      1,
      2,
      3,
      [4, 5, obj3],
      [obj3, 6]
    ]);
    go('cyclic_list', cyclic_list);
  });

  group('more_primitives', () {
    test('js-to-dart-null-prototype-eventdata', () {
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
      var completed = false;
      var subscription = null;
      subscription =
          window.on['stuff'].listen(expectAsyncUntil((MessageEvent e) {
        var data = e.data;
        if (data is String) return; //    Messages from unit test protocol.
        completed = true;
        subscription.cancel();
        expect(data, isMap);
        expect(data['eggs'], equals(3));
      }, () => completed));
      injectSource(JS_CODE);
    });
  });

  group('typed_arrays', () {
    var array_buffer = new Uint8List(16).buffer;
    var view_a = new Float32List.view(array_buffer, 0, 4);
    var view_b = new Uint8List.view(array_buffer, 1, 13);
    var typed_arrays_list = [view_a, array_buffer, view_b];

    // Note that FF is failing this test because in the sent message:
    // view_a.buffer == array_buffer
    // But in the response:
    // view_a.buffer != array_buffer
    go('typed_arrays_list', typed_arrays_list);
  });

  group('iframe', () {
    test('postMessage clones data', () {
      var iframe = new IFrameElement();
      var future = iframe.onLoad.first.then((_) {
        iframe.contentWindow.postMessage(new HashMap<String, num>(), '*');
      });
      iframe.src = 'about:blank';
      document.body.append(iframe);

      return future;
    });
  });
}
