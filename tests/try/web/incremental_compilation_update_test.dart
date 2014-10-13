// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.incremental_compilation_update_test;

import 'dart:html';

import 'dart:async' show
    Future;

import 'package:async_helper/async_helper.dart' show
    asyncTest;

import 'sandbox.dart' show
    appendIFrame,
    listener;

import 'web_compiler_test_case.dart' show
    WebCompilerTestCase,
    WebInputProvider;

void main() => asyncTest(() {
  listener.start();

  IFrameElement iframe =
      appendIFrame(
          '/root_dart/tests/try/web/incremental_compilation_update.html',
          document.body)
          ..style.width = '90vw'
          ..style.height = '90vh';

  return listener.expect('iframe-ready').then((_) {
    WebCompilerTestCase test =
        new WebCompilerTestCase("main() { print('Hello, World!'); }");
    return test.run().then((String jsCode) {
        var objectUrl =
            Url.createObjectUrl(new Blob([jsCode], 'application/javascript'));

        iframe.contentWindow.postMessage(['add-script', objectUrl], '*');
        return listener.expect(['Hello, World!', 'iframe-dart-main-done']).then(
            (_) {
              WebInputProvider inputProvider =
                  test.incrementalCompiler.inputProvider;
              Uri uri = test.scriptUri.resolve('?v2');
              inputProvider.cachedSources[uri] = new Future.value(
                  "main() { print('Hello, Brave New World!'); }");
              Future future = test.incrementalCompiler.compileUpdates(
                  {test.scriptUri: uri});
              return future.then((String update) {
                iframe.contentWindow.postMessage(['apply-update', update], '*');

                return listener.expect(
                    ['Hello, Brave New World!',
                     'iframe-dart-updated-main-done']);
              });
            });
    });
  }).then((_) {
    // Remove the iframe to work around a bug in test.dart.
    iframe.remove();
  });
});
