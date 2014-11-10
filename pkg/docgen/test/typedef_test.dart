// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.test.typedef;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

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
      var path = p.join(d.defaultRoot, 'docs', 'root_lib.json');
      var rootLibJson = new File(path).readAsStringSync();

      var rootLib = JSON.decode(rootLibJson) as Map<String, dynamic>;

      //
      // Validate function doc references
      //
      var testMethod = rootLib['functions']['methods']['testMethod']
          as Map<String, dynamic>;

      expect(testMethod['comment'], _TEST_METHOD_COMMENT);

      var classes = rootLib['classes'] as Map<String, dynamic>;

      expect(classes, hasLength(3));

      expect(classes['class'], isList);
      expect(classes['error'], isList);

      var typeDefs = classes['typedef'] as Map<String, dynamic>;
      var comparator = typeDefs['testTypedef'] as Map<String, dynamic>;

      expect(comparator['preview'], _TEST_TYPEDEF_PREVIEW);

      expect(comparator['comment'], _TEST_TYPEDEF_COMMENT);
    });

    schedule(() {
      var path = p.join(d.defaultRoot, 'docs', 'root_lib.RootClass.json');
      var rootClassJson = new File(path).readAsStringSync();

      var rootClass = JSON.decode(rootClassJson) as Map<String, dynamic>;

      var defaultCtor = rootClass['methods']['constructors'][''] as Map;

      expect(defaultCtor['qualifiedName'], 'root_lib.RootClass.RootClass-');
    });
  });
}

// TOOD: [List<A>] is not formatted correctly - issue 16771
const _TEST_METHOD_COMMENT = '<p>Processes an '
    '<a>root_lib.testMethod.input</a> of type <a>root_lib.C</a> '
    'instance for testing.</p>\n<p>To eliminate import warnings for '
    '<a>root_lib.A</a> and to test typedefs.</p>\n<p>It\'s important that the'
    ' <a>dart:core</a>&lt;A> for param <a>root_lib.testMethod.listOfA</a> '
    'is not empty.</p>';

// TODO: [input] is not turned into a param refenece
// TODO(kevmoo): <a>test_lib.C</a> should be <a>root_lib.C</a> - Issues 18352
const _TEST_TYPEDEF_PREVIEW = '<p>Processes an input of type '
    '<a>test_lib.C</a> instance for testing.</p>';

// TOOD: [List<A>] is not formatted correctly - issue 16771
// TODO: [listOfA] is not turned into a param reference
// TODO(kevmoo): <a>test_lib.C</a> should be <a>root_lib.C</a> - Issues 18352
final _TEST_TYPEDEF_COMMENT = _TEST_TYPEDEF_PREVIEW + '\n<p>To eliminate import'
    ' warnings for <a>test_lib.A</a> and to test typedefs.</p>\n<p>It\'s '
    'important that the <a>dart:core</a>&lt;A> for param listOfA is not '
    'empty.</p>';

