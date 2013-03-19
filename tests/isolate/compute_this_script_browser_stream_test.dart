// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that spawn works even when there are many script files in the page.
// This requires computing correctly the URL to the orignal script, so we can
// pass it to the web worker APIs.
library compute_this_script;

import 'dart:html';
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

child() {
  var sink;
  stream.listen((msg) {
    sink = msg;
  }, onDone: () {
    sink.add("done");
    sink.close();
  });
}

main() {
  useHtmlConfiguration();
  var script = new ScriptElement();
  document.body.append(script);
  test('spawn with other script tags in page', () {
    var box = new MessageBox();
    box.stream.listen(expectAsync1((msg) {
      expect(msg, equals("done"));
    }));

    IsolateSink s = streamSpawnFunction(child);
    s.add(box.sink);
    s.close();
  });
}
