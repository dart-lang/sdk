// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library worker_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
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
      var expectation = Worker.supported ? returnsNormally : throws;

      expect(() {
        new Worker('worker.js');
      }, expectation);
    });

    if (!Worker.supported) {
      return;
    }

    test('works', () {
      // Use Blob to make a local URL so we don't have to have a separate file.
      var blob = new Blob([workerScript], 'text/javascript');
      var url = Url.createObjectUrl(blob);
      var worker = new Worker(url);
      return worker.onMessage.first.then((e) {
        expect(e.data, 'WorkerMessage');
      });
    });
  });
}

