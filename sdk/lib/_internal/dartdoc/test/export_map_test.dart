// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'dart:async' show Future;
import 'dart:io' show Platform;

import '../lib/src/export_map.dart';
import '../../../../../tests/compiler/dart2js/memory_source_file_helper.dart'
       show MemorySourceFileProvider;
import '../../compiler/implementation/mirrors/mirrors.dart'
       show MirrorSystem, LibraryMirror;
import '../../compiler/implementation/mirrors/dart2js_mirror.dart'
       as source_mirrors;

Future<MirrorSystem> mirrorSystemFor(Map<String, String> memorySourceFiles) {
  var provider = new MemorySourceFileProvider(memorySourceFiles);
  handler(Uri uri, int begin, int end, String message, kind) {}

  var script = Uri.base.resolveUri(Platform.script);
  var libraryRoot = script.resolve('../../../../');
  // Read packages from 'memory:packages/'.
  var packageRoot = Uri.parse('memory:packages/');

  var libraries = <Uri>[];
  memorySourceFiles.forEach((String path, _) {
    if (path.startsWith('packages/')) {
      // Analyze files from 'packages/' as packages.
      libraries.add(new Uri(scheme: 'package', path: path.substring(9)));
    } else {
      libraries.add(new Uri(scheme: 'memory', path: path));
    }
  });
  libraries.add(new Uri(scheme: 'dart', path: 'async'));
  return source_mirrors.analyze(
      libraries, libraryRoot, packageRoot, provider, handler);
}

Future<ExportMap> testExports(Map<String, String> sourceFiles) {
  return mirrorSystemFor(sourceFiles).then((mirrors) {
    libMirror = (uri) => mirrors.libraries[Uri.parse(uri)];
    return new ExportMap(mirrors);
  });
}

Function libMirror;

main() {
  group('ExportMap', () {
    test('with an empty library', () {
      return testExports({'lib.dart': ''}).then((map) {
        var lib = libMirror('memory:lib.dart');
        var nonexistent = libMirror('memory:nonexistent.dart');

        var expectedExports = {};
        expectedExports[lib] = [];
        expect(map.exports, equals(expectedExports));
        expect(map.transitiveExports(lib), isEmpty);
        expect(map.transitiveExports(nonexistent), isEmpty);
      });
    });

    test('with one library with one export', () {
      return testExports({
        'a.dart': 'export "b.dart";',
        'b.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, b)
        ]));

        expect(map.transitiveExports(a), unorderedEquals([
          new Export(a, b)
        ]));

        expect(map.exports[b], isEmpty);

        expect(map.transitiveExports(b), isEmpty);
      });
    });

    test('with one library with multiple exports', () {
      return testExports({
        'a.dart': 'export "b.dart";\nexport "c.dart";',
        'b.dart': '', 'c.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');
        var c = libMirror('memory:c.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, b),
          new Export(a, c)
        ]));

        expect(map.transitiveExports(a), unorderedEquals([
          new Export(a, b),
          new Export(a, c)
        ]));

        expect(map.exports[b], isEmpty);
        expect(map.transitiveExports(b), isEmpty);
        expect(map.exports[c], isEmpty);
        expect(map.transitiveExports(c), isEmpty);
      });
    });

    test('with two libraries each with one export', () {
      return testExports({
        'a.dart': 'export "a_export.dart";',
        'b.dart': 'export "b_export.dart";',
        'a_export.dart': '',
        'b_export.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');
        var a_export = libMirror('memory:a_export.dart');
        var b_export = libMirror('memory:b_export.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, a_export),
        ]));
        expect(map.transitiveExports(a), unorderedEquals([
          new Export(a, a_export),
        ]));

        expect(map.transitiveExports(b), unorderedEquals([
          new Export(b, b_export),
        ]));
        expect(map.exports[b], unorderedEquals([
          new Export(b, b_export)
        ]));

        expect(map.exports[a_export], isEmpty);
        expect(map.transitiveExports(a_export), isEmpty);
        expect(map.exports[b_export], isEmpty);
        expect(map.transitiveExports(b_export), isEmpty);
      });
    });

    test('with a transitive export', () {
      return testExports({
        'a.dart': 'export "b.dart";',
        'b.dart': 'export "c.dart";',
        'c.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');
        var c = libMirror('memory:c.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, b),
        ]));
        expect(map.transitiveExports(a), unorderedEquals([
          new Export(a, b),
          new Export(a, c),
        ]));

        expect(map.exports[b], unorderedEquals([
          new Export(b, c),
        ]));
        expect(map.transitiveExports(b), unorderedEquals([
          new Export(b, c),
        ]));

        expect(map.exports[c], isEmpty);
        expect(map.transitiveExports(c), isEmpty);
      });
    });

    test('with an export through an import', () {
      return testExports({
        'a.dart': 'import "b.dart";',
        'b.dart': 'export "c.dart";',
        'c.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');
        var c = libMirror('memory:c.dart');

        expect(map.exports[b], unorderedEquals([
          new Export(b, c),
        ]));
        expect(map.transitiveExports(b), unorderedEquals([
          new Export(b, c),
        ]));

        expect(map.exports[a], isEmpty);
        expect(map.exports[c], isEmpty);
        expect(map.transitiveExports(a), isEmpty);
        expect(map.transitiveExports(c), isEmpty);
      });
    });

    test('with an export with a show combinator', () {
      return testExports({
        'a.dart': 'export "b.dart" show x, y;',
        'b.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, b, show: ['x', 'y'])
        ]));
      });
    });

    test('with an export with a hide combinator', () {
      return testExports({
        'a.dart': 'export "b.dart" hide x, y;',
        'b.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, b, hide: ['x', 'y'])
        ]));
      });
    });

    test('with an export with a show and a hide combinator', () {
      return testExports({
        'a.dart': 'export "b.dart" show x, y hide y, z;',
        'b.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, b, show: ['x'])
        ]));
      });
    });

    test('composes transitive exports', () {
      return testExports({
        'a.dart': 'export "b.dart" hide x;',
        'b.dart': 'export "c.dart" hide y;',
        'c.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');
        var c = libMirror('memory:c.dart');

        expect(map.transitiveExports(a), unorderedEquals([
          new Export(a, b, hide: ['x']),
          new Export(a, c, hide: ['x', 'y'])
        ]));
      });
    });

    test('merges adjacent exports', () {
      return testExports({
        'a.dart': '''
            export "b.dart" show x, y;
            export "b.dart" hide y, z;
        ''',
        'b.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, b, hide: ['z']),
        ]));
        expect(map.transitiveExports(a), unorderedEquals([
          new Export(a, b, hide: ['z']),
        ]));
      });
    });

    test('merges adjacent exports transitively', () {
      return testExports({
        'a.dart': 'export "b.dart";\nexport "c.dart";',
        'b.dart': 'export "d.dart" show x, y;',
        'c.dart': 'export "d.dart" hide y, z;',
        'd.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('memory:b.dart');
        var c = libMirror('memory:c.dart');
        var d = libMirror('memory:d.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, b),
          new Export(a, c),
        ]));
        expect(map.transitiveExports(a), unorderedEquals([
          new Export(a, b),
          new Export(a, c),
          new Export(a, d, hide: ['z']),
        ]));
      });
    });

    test('resolves package: exports', () {
      return testExports({
        'a.dart': 'export "package:b/b.dart";',
        'packages/b/b.dart': ''
      }).then((map) {
        var a = libMirror('memory:a.dart');
        var b = libMirror('package:b/b.dart');
        expect(map.exports[a], unorderedEquals([
          new Export(a, b)
        ]));
      });
    });

    test('ignores dart: exports', () {
      return testExports({'a.dart': 'export "dart:async";'}).then((map) {
        var a = libMirror('memory:a.dart');

        expect(map.exports[a], isEmpty);
      });
    });

    test('.parse() resolves package: imports', () {
      return testExports({
        'packages/a/a.dart': 'export "package:b/b.dart";',
        'packages/b/b.dart': ''
      }).then((map) {
        var a = libMirror('package:a/a.dart');
        var b = libMirror('package:b/b.dart');

        expect(map.exports[a], unorderedEquals([
          new Export(a, b)
        ]));
      });
    });

    test('.parse() ignores dart: imports', () {
      return testExports({}).then((map) {
        expect(map.exports, isEmpty);
      });
    });
  });

  group('Export', () {
    test('normalizes hide and show', () {
      expect(new Export(null, null, show: ['x', 'y'], hide: ['y', 'z']),
          equals(new Export(null, null, show: ['x'])));
    });

    test("doesn't care about the order of show or hide", () {
      expect(new Export(null, null, show: ['x', 'y']),
          equals(new Export(null, null, show: ['y', 'x'])));
      expect(new Export(null, null, hide: ['x', 'y']),
          equals(new Export(null, null, hide: ['y', 'x'])));
    });

    test('with no combinators considers anything visible', () {
      var export = new Export(null, null);
      expect(export.isMemberVisible('x'), isTrue);
      expect(export.isMemberVisible('y'), isTrue);
      expect(export.isMemberVisible('z'), isTrue);
    });

    test('with hide combinators considers anything not hidden visible', () {
      var export = new Export(null, null, hide: ['x', 'y']);
      expect(export.isMemberVisible('x'), isFalse);
      expect(export.isMemberVisible('y'), isFalse);
      expect(export.isMemberVisible('z'), isTrue);
    });

    test('with show combinators considers anything not shown invisible', () {
      var export = new Export(null, null, show: ['x', 'y']);
      expect(export.isMemberVisible('x'), isTrue);
      expect(export.isMemberVisible('y'), isTrue);
      expect(export.isMemberVisible('z'), isFalse);
    });

    test('composing uses the parent exporter and child path', () {
      return testExports({
        'exporter1.dart': '',
        'exporter2.dart': '',
        'path1.dart': '',
        'path2.dart': ''
      }).then((map) {
        var exporter1 = libMirror('memory:exporter1.dart');
        var exporter2 = libMirror('memory:exporter2.dart');
        var path1 = libMirror('memory:path1.dart');
        var path2 = libMirror('memory:path2.dart');
        expect(new Export(exporter1, path1)
                .compose(new Export(exporter2, path2)),
            equals(new Export(exporter1, path2)));
      });
    });

    test('composing show . show takes the intersection', () {
      expect(new Export(null, null, show: ['x', 'y'])
              .compose(new Export(null, null, show: ['y', 'z'])),
          equals(new Export(null, null, show: ['y'])));
    });

    test('composing show . hide takes the difference', () {
      expect(new Export(null, null, show: ['x', 'y'])
              .compose(new Export(null, null, hide: ['y', 'z'])),
          equals(new Export(null, null, show: ['x'])));
    });

    test('composing hide . show takes the reverse difference', () {
      expect(new Export(null, null, hide: ['x', 'y'])
              .compose(new Export(null, null, show: ['y', 'z'])),
          equals(new Export(null, null, show: ['z'])));
    });

    test('composing hide . hide takes the union', () {
      expect(new Export(null, null, hide: ['x', 'y'])
              .compose(new Export(null, null, hide: ['y', 'z'])),
          equals(new Export(null, null, hide: ['x', 'y', 'z'])));
    });

    test('merging requires identical exporters and paths', () {
      return testExports({
        'exporter1.dart': '',
        'exporter2.dart': '',
        'path1.dart': '',
        'path2.dart': ''
      }).then((map) {
          var exporter1 = libMirror('memory:exporter1.dart');
          var exporter2 = libMirror('memory:exporter2.dart');
          var path1 = libMirror('memory:path1.dart');
          var path2 = libMirror('memory:path2.dart');
        expect(() => new Export(exporter1, null)
                .merge(new Export(exporter2, null)),
            throwsA(isArgumentError));
        expect(() => new Export(null, path1)
                .merge(new Export(null, path2)),
            throwsA(isArgumentError));
        expect(new Export(null, null)
                    .merge(new Export(null, null)),
            equals(new Export(null, null)));
      });
    });

    test('merging show + show takes the union', () {
      expect(new Export(null, null, show: ['x', 'y'])
              .merge(new Export(null, null, show: ['y', 'z'])),
          equals(new Export(null, null, show: ['x', 'y', 'z'])));
    });

    test('merging show + hide takes the difference', () {
      expect(new Export(null, null, show: ['x', 'y'])
              .merge(new Export(null, null, hide: ['y', 'z'])),
          equals(new Export(null, null, hide: ['z'])));
    });

    test('merging hide + show takes the difference', () {
      expect(new Export(null, null, hide: ['x', 'y'])
              .merge(new Export(null, null, show: ['y', 'z'])),
          equals(new Export(null, null, hide: ['x'])));
    });

    test('merging hide + hide takes the intersection', () {
      expect(new Export(null, null, hide: ['x', 'y'])
              .merge(new Export(null, null, hide: ['y', 'z'])),
          equals(new Export(null, null, hide: ['y'])));
    });
  });
}
