// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library worker_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(Worker.supported, isTrue);
    });
  });

  var workerScript = '''postMessage('WorkerMessage');''';

  group('functional', () {
    test('unsupported', () {
      if (!Worker.supported) {
        expect(() => new Worker('worker.js'), throws);
      } else {
        new Worker('worker.js').onError.first.then(expectAsync((e) {
          // This event is expected, "worker.js" doesn't exist.  But the event
          // *sometimes* propagates to window.onerror in Firefox which causes
          // this test to fail, so let's stop any further propagation:
          e.preventDefault();
          e.stopImmediatePropagation();
        }));
      }
    });

    if (!Worker.supported) {
      return;
    }

    test('works', () {
      // Use Blob to make a local URL so we don't have to have a separate file.
      var blob = new Blob([workerScript], 'text/javascript');
      var url = Url.createObjectUrl(blob);
      var worker = new Worker(url);
      var test = expectAsync((e) {
        expect(e.data, 'WorkerMessage');
      });
      worker.onMessage.first.then(test);
    });
  });
}
