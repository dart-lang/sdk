// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.test.typedef;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:unittest/matcher.dart';

import 'util.dart';
import '../lib/docgen.dart' as dg;

void main() {

  setUp(() {
    scheduleTempDir();
  });

  test('typedef gen', () {
    schedule(() {
      var codeDir = getMultiLibraryCodePath();
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen([codeDir], out: p.join(d.defaultRoot, 'docs'));
    });

    schedule(() {
      var path = p.join(d.defaultRoot, 'docs', 'test_lib-bar.json');
      var dartCoreJson = new File(path).readAsStringSync();

      var testLibBar = JSON.decode(dartCoreJson) as Map<String, dynamic>;

      //
      // Validate function doc references
      //
      var generateFoo = testLibBar['functions']['methods']['generateFoo']
          as Map<String, dynamic>;

      expect(generateFoo['comment'], '<p><a>test_lib-bar.generateFoo.input</a> '
          'is of type <a>test_lib-bar.C</a> returns an <a>test_lib.A</a>.</p>');

      var classes = testLibBar['classes'] as Map<String, dynamic>;

      expect(classes, hasLength(3));

      expect(classes['class'], isList);
      expect(classes['error'], isList);

      var typeDefs = classes['typedef'] as Map<String, dynamic>;
      var comparator = typeDefs['AnATransformer'] as Map<String, dynamic>;

      var expectedPreview = '<p>Processes a [C] instance for testing.</p>';

      expect(comparator['preview'], expectedPreview);

      var expectedComment = expectedPreview + '\n'
          '<p>To eliminate import warnings for [A] and to test typedefs.</p>';

      expect(comparator['comment'], expectedComment);
    });
  });
}
