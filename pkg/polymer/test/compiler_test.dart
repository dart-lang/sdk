// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** End-to-end tests for the [Compiler] API. */
library compiler_test;

import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as path;
import 'package:polymer/src/messages.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'testing.dart';

main() {
  useCompactVMConfiguration();

  test('recursive dependencies', () {
    var messages = new Messages.silent();
    var compiler = createCompiler({
      'index.html': '<head>'
                    '<link rel="import" href="foo.html">'
                    '<link rel="import" href="bar.html">'
                    '<body><x-foo></x-foo><x-bar></x-bar>'
                    '<script type="application/dart">main() {}</script>',
      'foo.html': '<head><link rel="import" href="bar.html">'
                  '<body><polymer-element name="x-foo" constructor="Foo">'
                  '<template><x-bar>',
      'bar.html': '<head><link rel="import" href="foo.html">'
                  '<body><polymer-element name="x-bar" constructor="Boo">'
                  '<template><x-foo>',
    }, messages);

    compiler.run().then(expectAsync1((e) {
      MockFileSystem fs = compiler.fileSystem;
      expect(fs.readCount, equals({
        'index.html': 1,
        'foo.html': 1,
        'bar.html': 1
      }), reason: 'Actual:\n  ${fs.readCount}');

      var outputs = compiler.output.map((o) => o.path);
      expect(outputs, equals([
        'foo.html.dart',
        'foo.html.dart.map',
        'bar.html.dart',
        'bar.html.dart.map',
        'index.html.dart',
        'index.html.dart.map',
        'index.html_bootstrap.dart',
        'index.html',
      ].map((p) => path.join('out', p))));
    }));
  });

  group('missing files', () {
    test('main script', () {
      var messages = new Messages.silent();
      var compiler = createCompiler({
        'index.html': '<head></head><body>'
            '<script type="application/dart" src="notfound.dart"></script>'
            '</body>',
      }, messages);

      compiler.run().then(expectAsync1((e) {
        var msgs = messages.messages.where((m) =>
            m.message.contains('unable')).toList();

        expect(msgs.length, 1);
        expect(msgs[0].level, Level.SEVERE);
        expect(msgs[0].message, contains('unable to open file'));
        expect(msgs[0].span, isNotNull);
        expect(msgs[0].span.sourceUrl, 'index.html');

        MockFileSystem fs = compiler.fileSystem;
        expect(fs.readCount, { 'index.html': 1, 'notfound.dart': 1 });

        var outputs = compiler.output.map((o) => o.path.toString());
        expect(outputs, []);
      }));
    });

    test('component html', () {
      var messages = new Messages.silent();
      var compiler = createCompiler({
        'index.html': '<head>'
            '<link rel="import" href="notfound.html">'
            '<body><x-foo>'
            '<script type="application/dart">main() {}</script>',
      }, messages);

      compiler.run().then(expectAsync1((e) {
        var msgs = messages.messages.where((m) =>
            m.message.contains('unable')).toList();

        expect(msgs.length, 1);
        expect(msgs[0].level, Level.SEVERE);
        expect(msgs[0].message, contains('unable to open file'));
        expect(msgs[0].span, isNotNull);
        expect(msgs[0].span.sourceUrl, 'index.html');

        MockFileSystem fs = compiler.fileSystem;
        expect(fs.readCount, { 'index.html': 1, 'notfound.html': 1 });

        var outputs = compiler.output.map((o) => o.path.toString());
        expect(outputs, []);
      }));
    });

    test('component script', () {
      var messages = new Messages.silent();
      var compiler = createCompiler({
        'index.html': '<head>'
            '<link rel="import" href="foo.html">'
            '<body><x-foo></x-foo>'
            '<script type="application/dart">main() {}</script>'
            '</body>',
        'foo.html': '<body><polymer-element name="x-foo" constructor="Foo">'
            '<template></template>'
            '<script type="application/dart" src="notfound.dart"></script>',
      }, messages);

      compiler.run().then(expectAsync1((e) {
        var msgs = messages.messages.where((m) =>
            m.message.contains('unable')).toList();

        expect(msgs.length, 1);
        expect(msgs[0].level, Level.SEVERE);
        expect(msgs[0].message, contains('unable to open file'));

        MockFileSystem fs = compiler.fileSystem;
        expect(fs.readCount,
            { 'index.html': 1, 'foo.html': 1, 'notfound.dart': 1  });

        var outputs = compiler.output.map((o) => o.path.toString());
        expect(outputs, []);
      }));
    });
  });
}
