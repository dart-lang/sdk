// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as pathos;
import 'package:unittest/unittest.dart';

import '../lib/src/export_map.dart';
import '../lib/src/dartdoc/utils.dart';

String tempDir;

main() {
  group('ExportMap', () {
    setUp(createTempDir);
    tearDown(deleteTempDir);

    test('with an empty library', () {
      createLibrary('lib.dart');
      var map = parse(['lib.dart']);

      var expectedExports = {};
      expectedExports[libPath('lib.dart')] = [];
      expect(map.exports, equals(expectedExports));
      expect(map.allExportedFiles, isEmpty);
      expect(map.transitiveExports(libPath('lib.dart')), isEmpty);
      expect(map.transitiveExports(libPath('nonexistent.dart')), isEmpty);
    });

    test('with one library with one export', () {
      createLibrary('a.dart', 'export "b.dart";');
      createLibrary('b.dart');
      var map = parse(['a.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart'))
      ]));

      expect(map.transitiveExports(libPath('a.dart')), unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart'))
      ]));

      expect(map.allExportedFiles, unorderedEquals([libPath('b.dart')]));

      expect(map.exports[libPath('b.dart')], isEmpty);
      expect(map.transitiveExports(libPath('b.dart')), isEmpty);
    });

    test('with one library with multiple exports', () {
      createLibrary('a.dart', 'export "b.dart";\nexport "c.dart";');
      createLibrary('b.dart');
      createLibrary('c.dart');
      var map = parse(['a.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart')),
        new Export(libPath('a.dart'), libPath('c.dart'))
      ]));

      expect(map.transitiveExports(libPath('a.dart')), unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart')),
        new Export(libPath('a.dart'), libPath('c.dart'))
      ]));

      expect(map.allExportedFiles, unorderedEquals([
        libPath('b.dart'), libPath('c.dart')
      ]));

      expect(map.exports[libPath('b.dart')], isEmpty);
      expect(map.transitiveExports(libPath('b.dart')), isEmpty);
      expect(map.exports[libPath('c.dart')], isEmpty);
      expect(map.transitiveExports(libPath('c.dart')), isEmpty);
    });

    test('with two libraries each with one export', () {
      createLibrary('a.dart', 'export "a_export.dart";');
      createLibrary('b.dart', 'export "b_export.dart";');
      createLibrary('a_export.dart');
      createLibrary('b_export.dart');
      var map = parse(['a.dart', 'b.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath('a_export.dart')),
      ]));
      expect(map.transitiveExports(libPath('a.dart')), unorderedEquals([
        new Export(libPath('a.dart'), libPath('a_export.dart')),
      ]));

      expect(map.transitiveExports(libPath('b.dart')), unorderedEquals([
        new Export(libPath('b.dart'), libPath('b_export.dart')),
      ]));
      expect(map.exports[libPath('b.dart')], unorderedEquals([
        new Export(libPath('b.dart'), libPath('b_export.dart'))
      ]));

      expect(map.allExportedFiles, unorderedEquals([
        libPath('a_export.dart'), libPath('b_export.dart')
      ]));

      expect(map.exports[libPath('a_export.dart')], isEmpty);
      expect(map.transitiveExports(libPath('a_export.dart')), isEmpty);
      expect(map.exports[libPath('b_export.dart')], isEmpty);
      expect(map.transitiveExports(libPath('b_export.dart')), isEmpty);
    });

    test('with a transitive export', () {
      createLibrary('a.dart', 'export "b.dart";');
      createLibrary('b.dart', 'export "c.dart";');
      createLibrary('c.dart');
      var map = parse(['a.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart')),
      ]));
      expect(map.transitiveExports(libPath('a.dart')), unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart')),
        new Export(libPath('a.dart'), libPath('c.dart')),
      ]));

      expect(map.exports[libPath('b.dart')], unorderedEquals([
        new Export(libPath('b.dart'), libPath('c.dart')),
      ]));
      expect(map.transitiveExports(libPath('b.dart')), unorderedEquals([
        new Export(libPath('b.dart'), libPath('c.dart')),
      ]));

      expect(map.allExportedFiles, unorderedEquals([
        libPath('b.dart'), libPath('c.dart')
      ]));

      expect(map.exports[libPath('c.dart')], isEmpty);
      expect(map.transitiveExports(libPath('c.dart')), isEmpty);
    });

    test('with an export through an import', () {
      createLibrary('a.dart', 'import "b.dart";');
      createLibrary('b.dart', 'export "c.dart";');
      createLibrary('c.dart');
      var map = parse(['a.dart']);

      expect(map.exports[libPath('b.dart')], unorderedEquals([
        new Export(libPath('b.dart'), libPath('c.dart')),
      ]));
      expect(map.transitiveExports(libPath('b.dart')), unorderedEquals([
        new Export(libPath('b.dart'), libPath('c.dart')),
      ]));

      expect(map.allExportedFiles, unorderedEquals([libPath('c.dart')]));

      expect(map.exports[libPath('a.dart')], isEmpty);
      expect(map.exports[libPath('c.dart')], isEmpty);
      expect(map.transitiveExports(libPath('a.dart')), isEmpty);
      expect(map.transitiveExports(libPath('c.dart')), isEmpty);
    });

    test('with an export with a show combinator', () {
      createLibrary('a.dart', 'export "b.dart" show x, y;');
      createLibrary('b.dart');
      var map = parse(['a.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart'), show: ['x', 'y'])
      ]));
    });

    test('with an export with a hide combinator', () {
      createLibrary('a.dart', 'export "b.dart" hide x, y;');
      createLibrary('b.dart');
      var map = parse(['a.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart'), hide: ['x', 'y'])
      ]));
    });

    test('with an export with a show and a hide combinator', () {
      createLibrary('a.dart', 'export "b.dart" show x, y hide y, z;');
      createLibrary('b.dart');
      var map = parse(['a.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart'), show: ['x'])
      ]));
    });

    test('composes transitive exports', () {
      createLibrary('a.dart', 'export "b.dart" hide x;');
      createLibrary('b.dart', 'export "c.dart" hide y;');
      createLibrary('c.dart');
      var map = parse(['a.dart']);

      expect(map.transitiveExports(libPath('a.dart')), unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart'), hide: ['x']),
        new Export(libPath('a.dart'), libPath('c.dart'), hide: ['x', 'y'])
      ]));
    });

    test('merges adjacent exports', () {
      createLibrary('a.dart', '''
          export "b.dart" show x, y;
          export "b.dart" hide y, z;
      ''');
      createLibrary('b.dart');
      var map = parse(['a.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart'), hide: ['z']),
      ]));
      expect(map.transitiveExports(libPath('a.dart')), unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart'), hide: ['z']),
      ]));
    });

    test('merges adjacent exports transitively', () {
      createLibrary('a.dart', 'export "b.dart";\nexport "c.dart";');
      createLibrary('b.dart', 'export "d.dart" show x, y;');
      createLibrary('c.dart', 'export "d.dart" hide y, z;');
      createLibrary('d.dart');
      var map = parse(['a.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart')),
        new Export(libPath('a.dart'), libPath('c.dart')),
      ]));
      expect(map.transitiveExports(libPath('a.dart')), unorderedEquals([
        new Export(libPath('a.dart'), libPath('b.dart')),
        new Export(libPath('a.dart'), libPath('c.dart')),
        new Export(libPath('a.dart'), libPath('d.dart'), hide: ['z']),
      ]));
    });

    test('resolves package: exports', () {
      createLibrary('a.dart', 'export "package:b/b.dart";');
      var bPath = pathos.join('packages', 'b', 'b.dart');
      createLibrary(bPath);
      var map = parse(['a.dart']);

      expect(map.exports[libPath('a.dart')], unorderedEquals([
        new Export(libPath('a.dart'), libPath(bPath))
      ]));
    });

    test('ignores dart: exports', () {
      createLibrary('a.dart', 'export "dart:async";');
      var map = parse(['a.dart']);
      expect(map.exports[libPath('a.dart')], isEmpty);
    });

    test('.parse() resolves package: imports', () {
      var aPath = pathos.join('packages', 'a', 'a.dart');
      createLibrary(aPath, 'export "package:b/b.dart";');
      var bPath = pathos.join('packages', 'b', 'b.dart');
      createLibrary(bPath);
      var map = new ExportMap.parse(
          [Uri.parse('package:a/a.dart')],
          pathos.join(tempDir, 'packages'));

      expect(map.exports[libPath(aPath)], unorderedEquals([
        new Export(libPath(aPath), libPath(bPath))
      ]));
    });

    test('.parse() ignores dart: imports', () {
      var map = new ExportMap.parse(
          [Uri.parse('dart:async')],
          pathos.join(tempDir, 'packages'));
      expect(map.exports, isEmpty);
    });
  });

  group('Export', () {
    test('normalizes hide and show', () {
      expect(new Export('', '', show: ['x', 'y'], hide: ['y', 'z']),
          equals(new Export('', '', show: ['x'])));
    });

    test("doesn't care about the order of show or hide", () {
      expect(new Export('', '', show: ['x', 'y']),
          equals(new Export('', '', show: ['y', 'x'])));
      expect(new Export('', '', hide: ['x', 'y']),
          equals(new Export('', '', hide: ['y', 'x'])));
    });

    test('with no combinators considers anything visible', () {
      var export = new Export('', '');
      expect(export.isMemberVisible('x'), isTrue);
      expect(export.isMemberVisible('y'), isTrue);
      expect(export.isMemberVisible('z'), isTrue);
    });

    test('with hide combinators considers anything not hidden visible', () {
      var export = new Export('', '', hide: ['x', 'y']);
      expect(export.isMemberVisible('x'), isFalse);
      expect(export.isMemberVisible('y'), isFalse);
      expect(export.isMemberVisible('z'), isTrue);
    });

    test('with show combinators considers anything not shown invisible', () {
      var export = new Export('', '', show: ['x', 'y']);
      expect(export.isMemberVisible('x'), isTrue);
      expect(export.isMemberVisible('y'), isTrue);
      expect(export.isMemberVisible('z'), isFalse);
    });

    test('composing uses the parent exporter and child path', () {
      expect(new Export('exporter1.dart', 'path1.dart')
              .compose(new Export('exporter2.dart', 'path2.dart')),
          equals(new Export('exporter1.dart', 'path2.dart')));
    });

    test('composing show . show takes the intersection', () {
      expect(new Export('', '', show: ['x', 'y'])
              .compose(new Export('', '', show: ['y', 'z'])),
          equals(new Export('', '', show: ['y'])));
    });

    test('composing show . hide takes the difference', () {
      expect(new Export('', '', show: ['x', 'y'])
              .compose(new Export('', '', hide: ['y', 'z'])),
          equals(new Export('', '', show: ['x'])));
    });

    test('composing hide . show takes the reverse difference', () {
      expect(new Export('', '', hide: ['x', 'y'])
              .compose(new Export('', '', show: ['y', 'z'])),
          equals(new Export('', '', show: ['z'])));
    });

    test('composing hide . hide takes the union', () {
      expect(new Export('', '', hide: ['x', 'y'])
              .compose(new Export('', '', hide: ['y', 'z'])),
          equals(new Export('', '', hide: ['x', 'y', 'z'])));
    });

    test('merging requires identical exporters and paths', () {
      expect(() => new Export('exporter1.dart', '')
              .merge(new Export('exporter2.dart', '')),
          throwsA(isArgumentError));
      expect(() => new Export('', 'path1.dart')
              .merge(new Export('', 'path2.dart')),
          throwsA(isArgumentError));
      expect(new Export('', '').merge(new Export('', '')),
          equals(new Export('', '')));
    });

    test('merging show + show takes the union', () {
      expect(new Export('', '', show: ['x', 'y'])
              .merge(new Export('', '', show: ['y', 'z'])),
          equals(new Export('', '', show: ['x', 'y', 'z'])));
    });

    test('merging show + hide takes the difference', () {
      expect(new Export('', '', show: ['x', 'y'])
              .merge(new Export('', '', hide: ['y', 'z'])),
          equals(new Export('', '', hide: ['z'])));
    });

    test('merging hide + show takes the difference', () {
      expect(new Export('', '', hide: ['x', 'y'])
              .merge(new Export('', '', show: ['y', 'z'])),
          equals(new Export('', '', hide: ['x'])));
    });

    test('merging hide + hide takes the intersection', () {
      expect(new Export('', '', hide: ['x', 'y'])
              .merge(new Export('', '', hide: ['y', 'z'])),
          equals(new Export('', '', hide: ['y'])));
    });
  });
}

ExportMap parse(List<String> libraries) {
  return new ExportMap.parse(
      libraries.map(libPath).map(pathos.toUri),
      pathos.join(tempDir, 'packages'));
}

void createLibrary(String name, [String contents]) {
  if (contents == null) contents = '';
  new Directory(pathos.dirname(libPath(name))).createSync(recursive: true);
  new File(libPath(name)).writeAsStringSync('''
      library ${pathos.basename(name)};
      $contents
  ''');
}

String libPath(String name) => pathos.normalize(pathos.join(tempDir, name));

void createTempDir() {
  tempDir = Directory.systemTemp.createTempSync('dartdoc_').path;
  new Directory(pathos.join(tempDir, 'packages')).createSync();
}

void deleteTempDir() {
  new Directory(tempDir).deleteSync(recursive: true);
}
