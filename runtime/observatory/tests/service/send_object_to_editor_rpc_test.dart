// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'dart:async';

import 'test_helper.dart';

class _TestClass {
  _TestClass(this.x, this.y);
  var x;
  var y;
}

var myVar;

eval(Isolate isolate, String expression) async {
  // Silence analyzer.
  new _TestClass(null, null);
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'expression': expression,
  };
  return await isolate.invokeRpcNoUpgrade('evaluate', params);
}

var tests = [
  (Isolate isolate) async {
    var identifier = 'random string';
    // One instance of _TestClass retained.
    var evalResult = await eval(isolate, 'myVar = new _TestClass(null, null)');
    var params = {
      'editor': identifier,
      'objectId': evalResult['class']['id'],
    };

    var done = new Completer();
    var stream = await isolate.vm.getEventStream('_Editor');

    stream.listen((ServiceEvent e) {
      expect(e.kind, equals('_EditorObjectSelected'));
      expect(e.editor, equals(identifier));
      expect(e.object, isNotNull);
      expect(e.object.id, equals(evalResult['class']['id']));
      done.complete();
    });

    await isolate.invokeRpcNoUpgrade('_sendObjectToEditor', params);

    await done.future;
  },
];

main(args) async => runIsolateTests(args, tests);
