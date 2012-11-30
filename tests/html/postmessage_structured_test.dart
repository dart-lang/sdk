// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library postmessage_js_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:collection';  // SplayTreeMap
import 'utils.dart';

injectSource(code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = code;
  document.body.nodes.add(script);
}

main() {
  useHtmlConfiguration();

  test('js-to-dart-postmessage', () {
      // Pass an object literal from JavaScript. It should be seen as a Dart
      // Map.

      final JS_CODE = """
        window.postMessage({eggs: 3}, '*');
        """;
      var callback;
      var onSuccess = expectAsync1((e) {
          window.on.message.remove(callback);
        });
      callback = (e) {
        guardAsync(() {
            var data = e.data;
            if (data is String) return;    // Messages from unit test protocol.
            expect(data, isMap);
            expect(data['eggs'], equals(3));
            onSuccess(e);
          });
      };
      window.on.message.add(callback);
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
      var callback;
      var onSuccess = expectAsync1((e) {
          window.on.message.remove(callback);
        });
      callback = (e) {
        guardAsync(() {
            var data = e.data;
            if (data is String) return;    // Messages from unit test protocol.
            expect(data, isMap);
            if (data['recipient'] != 'DART') return;  // Hearing the sent message.
            expect(data['peas'], equals(50));
            onSuccess(e);
          });
      };
      window.on.message.add(callback);
      injectSource(JS_CODE);
      window.postMessage({'recipient': 'JS', 'curry': 'peas'}, '*');
    });

  go(testName, value) =>
      test(testName, () {
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
          var onSuccess = expectAsync0(() {});
          callback(e) {
            guardAsync(() {
                var data = e.data;
                if (data is String) return;    // Messages from unit test protocol.
                expect(data, isMap);
                if (data['recipient'] != 'DART') return;  // Not for me.
                var returnedValue = data['data'];

                window.on.message.remove(callback);
                expect(returnedValue, isNot(same(value)));
                verifyGraph(value, returnedValue);
                onSuccess();
              });
          };
          window.on.message.add(callback);
          injectSource(JS_CODE);
          window.postMessage({'recipient': 'JS', 'data': value}, '*');
        });

  var obj1 = {'a': 100, 'b': 's'};
  var obj2 = {'x': obj1, 'y': obj1};  // DAG.

  var obj3 = {};
  obj3['a'] = 100;
  obj3['b'] = obj3;  // Cycle.

  var obj4 = new SplayTreeMap<String, dynamic>();  // Different implementation.
  obj4['a'] = 100;
  obj4['b'] = 's';

  var cyclic_list = [1, 2, 3];
  cyclic_list[1] = cyclic_list;

  go('test_simple_list', [1, 2, 3]);
  go('test_map', obj1);
  go('test_DAG', obj2);
  go('test_cycle', obj3);
  go('test_simple_splay', obj4);
  go('const_array_1', const [const [1], const [2]]);
  go('const_array_dag', const [const [1], const [1]]);
  go('array_deferred_copy', [1,2,3, obj3, obj3, 6]);
  go('array_deferred_copy_2', [1,2,3, [4, 5, obj3], [obj3, 6]]);
  go('cyclic_list', cyclic_list);
}
