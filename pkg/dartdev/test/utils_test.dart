// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/utils.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('pluralize', () {
    test('zero', () {
      expect(pluralize('cat', 0), 'cats');
    });

    test('one', () {
      expect(pluralize('cat', 1), 'cat');
    });

    test('many', () {
      expect(pluralize('cat', 2), 'cats');
    });
  });

  group('relativePath', () {
    test('direct', () {
      var dir = Directory('foo');
      expect(relativePath('path', dir), 'path');
    });

    test('nested', () {
      var dir = Directory('foo');
      expect(relativePath(join(dir.absolute.path, 'path'), dir), 'path');
    });
  });

  group('trimEnd', () {
    test('null string', () {
      expect(trimEnd(null, 'suffix'), null);
    });

    test('null suffix', () {
      expect(trimEnd('string', null), 'string');
    });

    test('suffix empty', () {
      expect(trimEnd('string', ''), 'string');
    });

    test('suffix miss', () {
      expect(trimEnd('string', 'suf'), 'string');
    });

    test('suffix hit', () {
      expect(trimEnd('string', 'ring'), 'st');
    });
  });

  group('castStringKeyedMap', () {
    test('fails', () {
      dynamic contents = json.decode(_packageData);
      List<dynamic> _packages = contents['packages'];
      try {
        // ignore: unused_local_variable
        List<Map<String, dynamic>> packages = _packages;
        fail('expected implicit cast to fail');
      } on TypeError {
        // TypeError is expected
      }
    });

    test('succeeds', () {
      dynamic contents = json.decode(_packageData);
      List<dynamic> _packages = contents['packages'];
      List<Map<String, dynamic>> packages =
          _packages.map<Map<String, dynamic>>(castStringKeyedMap).toList();
      expect(packages, isList);
    });
  });

  group('FileSystemEntityExtension', () {
    test('isDartFile', () {
      expect(File('foo.dart').isDartFile, isTrue);
      expect(Directory('foo.dartt').isDartFile, isFalse);
      expect(File('foo.dartt').isDartFile, isFalse);
      expect(File('foo.darrt').isDartFile, isFalse);
      expect(File('bar.bart').isDartFile, isFalse);
      expect(File('bazdart').isDartFile, isFalse);
    });

    test('name', () {
      expect(Directory('').name, '');
      expect(Directory('dirName').name, 'dirName');
      expect(Directory('dirName$separator').name, 'dirName');
      expect(File('').name, '');
      expect(File('foo.dart').name, 'foo.dart');
      expect(File('${separator}foo.dart').name, 'foo.dart');
      expect(File('bar.bart').name, 'bar.bart');
    });
  });

  group('PubUtils', () {
    test('doModifyArgs', () {
      const allCmds = ['analyze', 'help', 'pub', 'migrate'];
      expect(PubUtils.shouldModifyArgs(null, null), isFalse);
      expect(PubUtils.shouldModifyArgs([], null), isFalse);
      expect(PubUtils.shouldModifyArgs(null, []), isFalse);
      expect(PubUtils.shouldModifyArgs([], []), isFalse);
      expect(PubUtils.shouldModifyArgs(['-h'], allCmds), isFalse);
      expect(PubUtils.shouldModifyArgs(['--help'], allCmds), isFalse);
      expect(PubUtils.shouldModifyArgs(['help'], allCmds), isFalse);
      expect(PubUtils.shouldModifyArgs(['pub'], allCmds), isFalse);
      expect(PubUtils.shouldModifyArgs(['analyze', 'help', 'pub'], allCmds),
          isFalse);

      expect(PubUtils.shouldModifyArgs(['--some-flag', 'help', 'pub'], allCmds),
          isTrue);
      expect(PubUtils.shouldModifyArgs(['help', 'pub'], allCmds), isTrue);
      expect(PubUtils.shouldModifyArgs(['help', 'pub', 'publish'], allCmds),
          isTrue);
      expect(PubUtils.shouldModifyArgs(['help', 'pub', 'analyze'], allCmds),
          isTrue);
    });

    test('modifyArgs', () {
      expect(PubUtils.modifyArgs(['--some-flag', 'help', 'pub']),
          orderedEquals(['--some-flag', 'pub', '--help']));
      expect(PubUtils.modifyArgs(['help', 'pub']),
          orderedEquals(['pub', '--help']));
      expect(PubUtils.modifyArgs(['help', 'pub', 'publish']),
          orderedEquals(['pub', 'publish', '--help']));
    });
  });
}

const String _packageData = '''{
  "configVersion": 2,
  "packages": [
    {
      "name": "pedantic",
      "rootUri": "file:///Users/.../.pub-cache/hosted/pub.dartlang.org/pedantic-1.9.0",
      "packageUri": "lib/",
      "languageVersion": "2.1"
    },
    {
      "name": "args",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.3"
    }
  ],
  "generated": "2020-03-01T03:38:14.906205Z",
  "generator": "pub",
  "generatorVersion": "2.8.0-dev.10.0"
}
''';
