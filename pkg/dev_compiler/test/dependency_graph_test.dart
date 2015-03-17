// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.test.dependency_graph_test;

import 'package:unittest/unittest.dart';

import 'package:dev_compiler/src/checker/dart_sdk.dart'
    show mockSdkSources, dartSdkDirectory;
import 'package:dev_compiler/src/testing.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/checker/resolver.dart';
import 'package:dev_compiler/src/dependency_graph.dart';
import 'package:dev_compiler/src/report.dart';
import 'package:path/path.dart' as path;

import 'test_util.dart';

void main() {
  configureTest();

  var options = new CompilerOptions();
  var testUriResolver;
  var context;
  var graph;

  /// Initial values for test files
  var testFiles = {
    '/index1.html': '''
        <script src="foo.js"></script>
        ''',
    '/index2.html': '''
        <script type="application/dart" src="a1.dart"></script>
        ''',
    '/index3.html': '''
        <script type="application/dart" src="a2.dart"></script>
        ''',
    '/a1.dart': '''
        library a1;
      ''',
    '/a2.dart': '''
        library a2;
        import 'a3.dart';
        import 'a4.dart';
        export 'a5.dart';
        part 'a6.dart';
      ''',
    '/a3.dart': 'library a3;',
    '/a4.dart': 'library a4; export "a10.dart";',
    '/a5.dart': 'library a5;',
    '/a6.dart': 'part of a2;',
    '/a7.dart': 'library a7;',
    '/a8.dart': 'library a8; import "a8.dart";',
    '/a9.dart': 'library a9; import "a8.dart";',
    '/a10.dart': 'library a10;',
  };

  nodeOf(String filepath) => graph.nodeFromUri(new Uri.file(filepath));

  setUp(() {
    /// We completely reset the TestUriResolver to avoid interference between
    /// tests (since some tests modify the state of the files).
    testUriResolver = new TestUriResolver(testFiles);
    context = new TypeResolver.fromMock(mockSdkSources, options,
        otherResolvers: [testUriResolver]).context;
    graph = new SourceGraph(context, new LogReporter(), options);
  });

  group('HTML deps', () {
    test('initial deps', () {
      var i1 = nodeOf('/index1.html');
      var i2 = nodeOf('/index2.html');
      expect(i1.scripts.length, 0);
      expect(i2.scripts.length, 0);
      i1.update(graph);
      i2.update(graph);
      expect(i1.scripts.length, 0);
      expect(i2.scripts.length, 1);
      expect(i2.scripts.first, nodeOf('/a1.dart'));
    });

    test('add a dep', () {
      // After initial load, dependencies are 0:
      var node = nodeOf('/index1.html');
      node.update(graph);
      expect(node.scripts.length, 0);

      // Adding the dependency is discovered on the next round of updates:
      node.source.contents.modificationTime++;
      node.source.contents.data =
          '<script type="application/dart" src="a2.dart"></script>';
      expect(node.scripts.length, 0);
      node.update(graph);
      expect(node.scripts.length, 1);
      expect(node.scripts.first, nodeOf('/a2.dart'));
    });

    test('add more deps', () {
      // After initial load, dependencies are 1:
      var node = nodeOf('/index2.html');
      node.update(graph);
      expect(node.scripts.length, 1);
      expect(node.scripts.first, nodeOf('/a1.dart'));

      node.source.contents.modificationTime++;
      node.source.contents.data +=
          '<script type="application/dart" src="a2.dart"></script>';
      expect(node.scripts.length, 1);
      node.update(graph);
      expect(node.scripts.length, 2);
      expect(node.scripts.first, nodeOf('/a1.dart'));
      expect(node.scripts.last, nodeOf('/a2.dart'));
    });

    test('remove all deps', () {
      // After initial load, dependencies are 1:
      var node = nodeOf('/index2.html');
      node.update(graph);
      expect(node.scripts.length, 1);
      expect(node.scripts.first, nodeOf('/a1.dart'));

      // Removing the dependency is discovered on the next round of updates:
      node.source.contents.modificationTime++;
      node.source.contents.data = '';
      expect(node.scripts.length, 1);
      node.update(graph);
      expect(node.scripts.length, 0);
    });
  });

  group('Dart deps', () {
    test('initial deps', () {
      var a1 = nodeOf('/a1.dart');
      var a2 = nodeOf('/a2.dart');
      expect(a1.imports.length, 0);
      expect(a1.exports.length, 0);
      expect(a1.parts.length, 0);
      expect(a2.imports.length, 0);
      expect(a2.exports.length, 0);
      expect(a2.parts.length, 0);

      a1.update(graph);
      a2.update(graph);

      expect(a1.imports.length, 0);
      expect(a1.exports.length, 0);
      expect(a1.parts.length, 0);
      expect(a2.imports.length, 2);
      expect(a2.exports.length, 1);
      expect(a2.parts.length, 1);
      expect(a2.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(a2.imports.contains(nodeOf('/a4.dart')), isTrue);
      expect(a2.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(a2.parts.contains(nodeOf('/a6.dart')), isTrue);
    });

    test('add deps', () {
      var node = nodeOf('/a1.dart');
      node.update(graph);
      expect(node.imports.length, 0);
      expect(node.exports.length, 0);
      expect(node.parts.length, 0);

      node.source.contents.modificationTime++;
      node.source.contents.data =
          'import "a3.dart"; export "a5.dart"; part "a8.dart";';
      node.update(graph);

      expect(node.imports.length, 1);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a8.dart')), isTrue);
    });

    test('remove deps', () {
      var node = nodeOf('/a2.dart');
      node.update(graph);
      expect(node.imports.length, 2);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.imports.contains(nodeOf('/a4.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a6.dart')), isTrue);

      node.source.contents.modificationTime++;
      node.source.contents.data =
          'import "a3.dart"; export "a7.dart"; part "a8.dart";';
      node.update(graph);

      expect(node.imports.length, 1);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a7.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a8.dart')), isTrue);
    });

    test('change part to library', () {
      var node = nodeOf('/a2.dart');
      node.update(graph);
      expect(node.imports.length, 2);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.imports.contains(nodeOf('/a4.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a6.dart')), isTrue);

      node.source.contents.modificationTime++;
      node.source.contents.data = '''
          library a2;
          import 'a3.dart';
          import 'a4.dart';
          export 'a5.dart';
          import 'a6.dart'; // changed from part
        ''';
      var a6 = nodeOf('/a6.dart');
      a6.source.contents.modificationTime++;
      a6.source.contents.data = '';
      node.update(graph);

      expect(node.imports.length, 3);
      expect(node.exports.length, 1);
      expect(node.parts.length, 0);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.imports.contains(nodeOf('/a4.dart')), isTrue);
      expect(node.imports.contains(nodeOf('/a6.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);

      expect(a6.imports.length, 0);
      expect(a6.exports.length, 0);
      expect(a6.parts.length, 0);
    });

    test('change library to part', () {
      var node = nodeOf('/a2.dart');
      var a4 = nodeOf('/a4.dart');
      node.update(graph);
      expect(node.imports.length, 2);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.imports.contains(nodeOf('/a4.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a6.dart')), isTrue);

      a4.update(graph);
      expect(a4.imports.length, 0);
      expect(a4.exports.length, 1);
      expect(a4.parts.length, 0);

      node.source.contents.modificationTime++;
      node.source.contents.data = '''
          library a2;
          import 'a3.dart';
          part 'a4.dart'; // changed from export
          export 'a5.dart';
          part 'a6.dart';
        ''';
      node.update(graph);

      expect(node.imports.length, 1);
      expect(node.exports.length, 1);
      expect(node.parts.length, 2);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a4.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a6.dart')), isTrue);

      // Note, technically we never modified the contents of a4 and it contains
      // an export. This is invalid Dart, but we'll let the analyzer report that
      // error instead of doing so ourselves.
      expect(a4.imports.length, 0);
      expect(a4.exports.length, 1);
      expect(a4.parts.length, 0);

      // And change it back.
      node.source.contents.modificationTime++;
      node.source.contents.data = '''
          library a2;
          import 'a3.dart';
          import 'a4.dart'; // changed again
          export 'a5.dart';
          part 'a6.dart';
        ''';
      node.update(graph);
      expect(node.imports.contains(a4), isTrue);
      expect(a4.imports.length, 0);
      expect(a4.exports.length, 1);
      expect(a4.parts.length, 0);
    });
  });

  group('local changes', () {
    group('needs rebuild', () {
      test('in HTML', () {
        var node = nodeOf('/index1.html');
        node.update(graph);
        expect(node.needsRebuild, isTrue);
        node.needsRebuild = false;

        node.update(graph);
        expect(node.needsRebuild, isFalse);

        // For now, an empty modification is enough to trigger a rebuild
        node.source.contents.modificationTime++;
        expect(node.needsRebuild, isFalse);
        node.update(graph);
        expect(node.needsRebuild, isTrue);
      });

      test('main library in Dart', () {
        var node = nodeOf('/a2.dart');
        var partNode = nodeOf('/a6.dart');
        node.update(graph);
        expect(node.needsRebuild, isTrue);
        node.needsRebuild = false;
        partNode.needsRebuild = false;

        node.update(graph);
        expect(node.needsRebuild, isFalse);

        // For now, an empty modification is enough to trigger a rebuild
        node.source.contents.modificationTime++;
        expect(node.needsRebuild, isFalse);
        node.update(graph);
        expect(node.needsRebuild, isTrue);
      });

      test('part of library in Dart', () {
        var node = nodeOf('/a2.dart');
        var importNode = nodeOf('/a3.dart');
        var exportNode = nodeOf('/a5.dart');
        var partNode = nodeOf('/a6.dart');
        node.update(graph);
        expect(node.needsRebuild, isTrue);
        node.needsRebuild = false;
        partNode.needsRebuild = false;

        node.update(graph);
        expect(node.needsRebuild, isFalse);

        // Modification in imported/exported node makes no difference for local
        // rebuild label (globally that's tested elsewhere)
        importNode.source.contents.modificationTime++;
        exportNode.source.contents.modificationTime++;
        node.update(graph);
        expect(node.needsRebuild, isFalse);
        expect(partNode.needsRebuild, isFalse);

        // Modification in part triggers change in containing library:
        partNode.source.contents.modificationTime++;
        expect(node.needsRebuild, isFalse);
        expect(partNode.needsRebuild, isFalse);
        node.update(graph);
        expect(node.needsRebuild, isTrue);
        expect(partNode.needsRebuild, isTrue);
      });
    });

    group('structure change', () {
      test('no mod in HTML', () {
        var node = nodeOf('/index2.html');
        node.update(graph);
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update(graph);
        expect(node.structureChanged, isFalse);

        // An empty modification will not trigger a structural change
        node.source.contents.modificationTime++;
        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isFalse);
      });

      test('added scripts in HTML', () {
        var node = nodeOf('/index2.html');
        node.update(graph);
        expect(node.structureChanged, isTrue);
        expect(node.scripts.length, 1);

        node.structureChanged = false;
        node.update(graph);
        expect(node.structureChanged, isFalse);

        // This change will not include new script tags:
        node.source.contents.modificationTime++;
        node.source.contents.data += '<div></div>';
        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isFalse);
        expect(node.scripts.length, 1);

        node.source.contents.modificationTime++;
        node.source.contents.data +=
            '<script type="application/dart" src="a4.dart"></script>';
        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isTrue);
        expect(node.scripts.length, 2);
      });

      test('no mod in Dart', () {
        var node = nodeOf('/a2.dart');
        var importNode = nodeOf('/a3.dart');
        var exportNode = nodeOf('/a5.dart');
        var partNode = nodeOf('/a6.dart');
        node.update(graph);
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update(graph);
        expect(node.structureChanged, isFalse);

        // These modifications make no difference at all.
        importNode.source.contents.modificationTime++;
        exportNode.source.contents.modificationTime++;
        partNode.source.contents.modificationTime++;
        node.source.contents.modificationTime++;

        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isFalse);
      });

      test('same directives, different order', () {
        var node = nodeOf('/a2.dart');
        node.update(graph);
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update(graph);
        expect(node.structureChanged, isFalse);

        // modified order of imports, but structure stays the same:
        node.source.contents.modificationTime++;
        node.source.contents.data = 'import "a4.dart"; import "a3.dart"; '
            'export "a5.dart"; part "a6.dart";';
        node.update(graph);

        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isFalse);
      });

      test('changed parts', () {
        var node = nodeOf('/a2.dart');
        node.update(graph);
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update(graph);
        expect(node.structureChanged, isFalse);

        // added one.
        node.source.contents.modificationTime++;
        node.source.contents.data = 'import "a4.dart"; import "a3.dart"; '
            'export "a5.dart"; part "a6.dart"; part "a7.dart";';
        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isTrue);

        // no change
        node.structureChanged = false;
        node.source.contents.modificationTime++;
        node.update(graph);
        expect(node.structureChanged, isFalse);

        // removed one
        node.source.contents.modificationTime++;
        node.source.contents.data = 'import "a4.dart"; import "a3.dart"; '
            'export "a5.dart"; part "a7.dart";';
        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isTrue);
      });

      test('changed import', () {
        var node = nodeOf('/a2.dart');
        node.update(graph);
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update(graph);
        expect(node.structureChanged, isFalse);

        // added one.
        node.source.contents.modificationTime++;
        node.source.contents.data =
            'import "a4.dart"; import "a3.dart"; import "a7.dart";'
            'export "a5.dart"; part "a6.dart";';
        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isTrue);

        // no change
        node.structureChanged = false;
        node.source.contents.modificationTime++;
        node.update(graph);
        expect(node.structureChanged, isFalse);

        // removed one
        node.source.contents.modificationTime++;
        node.source.contents.data = 'import "a4.dart"; import "a7.dart"; '
            'export "a5.dart"; part "a6.dart";';
        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isTrue);
      });

      test('changed exports', () {
        var node = nodeOf('/a2.dart');
        node.update(graph);
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update(graph);
        expect(node.structureChanged, isFalse);

        // added one.
        node.source.contents.modificationTime++;
        node.source.contents.data = 'import "a4.dart"; import "a3.dart";'
            'export "a5.dart"; export "a9.dart"; part "a6.dart";';
        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isTrue);

        // no change
        node.structureChanged = false;
        node.source.contents.modificationTime++;
        node.update(graph);
        expect(node.structureChanged, isFalse);

        // removed one
        node.source.contents.modificationTime++;
        node.source.contents.data = 'import "a4.dart"; import "a3.dart"; '
            'export "a5.dart"; part "a6.dart";';
        expect(node.structureChanged, isFalse);
        node.update(graph);
        expect(node.structureChanged, isTrue);
      });
    });
  });

  group('refresh structure and marks', () {
    test('initial marks', () {
      var node = nodeOf('/index3.html');
      expectGraph(node, '''
          index3.html
          |-- harmony_feature_check.js
          |-- dart_runtime.js
          |-- dart_core.js
          ''');
      refreshStructureAndMarks(node, graph);
      expectGraph(node, '''
          index3.html [needs-rebuild] [structure-changed]
          |-- a2.dart [needs-rebuild] [structure-changed]
          |    |-- a3.dart [needs-rebuild]
          |    |-- a4.dart [needs-rebuild] [structure-changed]
          |    |    |-- a10.dart [needs-rebuild]
          |    |-- a5.dart [needs-rebuild]
          |    |-- a6.dart (part) [needs-rebuild]
          |-- harmony_feature_check.js [needs-rebuild]
          |-- dart_runtime.js [needs-rebuild]
          |-- dart_core.js [needs-rebuild]
          ''');
    });

    test('cleared marks stay clear', () {
      var node = nodeOf('/index3.html');
      refreshStructureAndMarks(node, graph);
      expectGraph(node, '''
          index3.html [needs-rebuild] [structure-changed]
          |-- a2.dart [needs-rebuild] [structure-changed]
          |    |-- a3.dart [needs-rebuild]
          |    |-- a4.dart [needs-rebuild] [structure-changed]
          |    |    |-- a10.dart [needs-rebuild]
          |    |-- a5.dart [needs-rebuild]
          |    |-- a6.dart (part) [needs-rebuild]
          |-- harmony_feature_check.js [needs-rebuild]
          |-- dart_runtime.js [needs-rebuild]
          |-- dart_core.js [needs-rebuild]
          ''');
      clearMarks(node);
      expectGraph(node, '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart
          |    |-- a6.dart (part)
          |-- harmony_feature_check.js
          |-- dart_runtime.js
          |-- dart_core.js
          ''');

      refreshStructureAndMarks(node, graph);
      expectGraph(node, '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart
          |    |-- a6.dart (part)
          |-- harmony_feature_check.js
          |-- dart_runtime.js
          |-- dart_core.js
          ''');
    });

    test('needsRebuild mark updated on local modifications', () {
      var node = nodeOf('/index3.html');
      refreshStructureAndMarks(node, graph);
      clearMarks(node);
      var a3 = nodeOf('/a3.dart');
      a3.source.contents.modificationTime++;

      refreshStructureAndMarks(node, graph);
      expectGraph(node, '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart [needs-rebuild]
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart
          |    |-- a6.dart (part)
          |-- harmony_feature_check.js
          |-- dart_runtime.js
          |-- dart_core.js
          ''');
    });

    test('structuredChanged mark updated on structure modifications', () {
      var node = nodeOf('/index3.html');
      refreshStructureAndMarks(node, graph);
      clearMarks(node);
      var a5 = nodeOf('/a5.dart');
      a5.source.contents.modificationTime++;
      a5.source.contents.data = 'import "a8.dart";';

      refreshStructureAndMarks(node, graph);
      expectGraph(node, '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart [needs-rebuild] [structure-changed]
          |    |    |-- a8.dart [needs-rebuild] [structure-changed]
          |    |    |    |-- a8.dart...
          |    |-- a6.dart (part)
          |-- harmony_feature_check.js
          |-- dart_runtime.js
          |-- dart_core.js
          ''');
    });
  });

  group('server-mode', () {
    setUp(() {
      var options2 = new CompilerOptions(serverMode: true);
      context = new TypeResolver.fromMock(mockSdkSources, options2,
          otherResolvers: [testUriResolver]).context;
      graph = new SourceGraph(context, new LogReporter(), options2);
    });

    test('messages widget is automatically included', () {
      var node = nodeOf('/index3.html');
      expectGraph(node, '''
          index3.html
          |-- harmony_feature_check.js
          |-- dart_runtime.js
          |-- dart_core.js
          |-- messages_widget.js
          |-- messages.css
          ''');
      refreshStructureAndMarks(node, graph);
      expectGraph(node, '''
          index3.html [needs-rebuild] [structure-changed]
          |-- a2.dart [needs-rebuild] [structure-changed]
          |    |-- a3.dart [needs-rebuild]
          |    |-- a4.dart [needs-rebuild] [structure-changed]
          |    |    |-- a10.dart [needs-rebuild]
          |    |-- a5.dart [needs-rebuild]
          |    |-- a6.dart (part) [needs-rebuild]
          |-- harmony_feature_check.js [needs-rebuild]
          |-- dart_runtime.js [needs-rebuild]
          |-- dart_core.js [needs-rebuild]
          |-- messages_widget.js [needs-rebuild]
          |-- messages.css [needs-rebuild]
          ''');
    });
  });

  group('rebuild', () {
    var results;
    void addName(SourceNode n) => results.add(nameFor(n));

    bool buildNoTransitiveChange(SourceNode n) {
      addName(n);
      return false;
    }

    bool buildWithTransitiveChange(SourceNode n) {
      addName(n);
      return true;
    }

    setUp(() {
      results = [];
    });

    test('everything build on first run', () {
      var node = nodeOf('/index3.html');
      rebuild(node, graph, buildNoTransitiveChange);
      // Note: a6.dart is not included because it built as part of a2.dart
      expect(results, [
        'a3.dart',
        'a10.dart',
        'a4.dart',
        'a5.dart',
        'a2.dart',
        'harmony_feature_check.js',
        'dart_runtime.js',
        'dart_core.js',
        'index3.html',
      ]);

      // Marks are removed automatically by rebuild
      expectGraph(node, '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart
          |    |-- a6.dart (part)
          |-- harmony_feature_check.js
          |-- dart_runtime.js
          |-- dart_core.js
          ''');
    });

    test('nothing to do after build', () {
      var node = nodeOf('/index3.html');
      rebuild(node, graph, buildNoTransitiveChange);

      results = [];
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, []);
    });

    test('modified part triggers building library', () {
      var node = nodeOf('/index3.html');
      rebuild(node, graph, buildNoTransitiveChange);
      results = [];

      var a6 = nodeOf('/a6.dart');
      a6.source.contents.modificationTime++;
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, ['a2.dart']);

      results = [];
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, []);
    });

    test('non-API change triggers build stays local', () {
      var node = nodeOf('/index3.html');
      rebuild(node, graph, buildNoTransitiveChange);
      results = [];

      var a3 = nodeOf('/a3.dart');
      a3.source.contents.modificationTime++;
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, ['a3.dart']);

      results = [];
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, []);
    });

    test('no-API change in exported file stays local', () {
      var node = nodeOf('/index3.html');
      rebuild(node, graph, buildNoTransitiveChange);
      results = [];

      // similar to the test above, but a10 is exported from a4.
      var a3 = nodeOf('/a10.dart');
      a3.source.contents.modificationTime++;
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, ['a10.dart']);

      results = [];
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, []);
    });

    test('API change in lib, triggers build on imports', () {
      var node = nodeOf('/index3.html');
      rebuild(node, graph, buildNoTransitiveChange);
      results = [];

      var a3 = nodeOf('/a3.dart');
      a3.source.contents.modificationTime++;
      rebuild(node, graph, buildWithTransitiveChange);
      expect(results, ['a3.dart', 'a2.dart']);

      results = [];
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, []);
    });

    test('API change in export, triggers build on imports', () {
      var node = nodeOf('/index3.html');
      rebuild(node, graph, buildNoTransitiveChange);
      results = [];

      var a3 = nodeOf('/a10.dart');
      a3.source.contents.modificationTime++;
      rebuild(node, graph, buildWithTransitiveChange);

      // Node: a4.dart reexports a10.dart, but it doesn't import it, so we don't
      // need to rebuild it.
      expect(results, ['a10.dart', 'a2.dart']);

      results = [];
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, []);
    });

    test('structural change rebuilds HTML, but skips unreachable code', () {
      var node = nodeOf('/index3.html');
      rebuild(node, graph, buildNoTransitiveChange);
      results = [];

      var a2 = nodeOf('/a2.dart');
      a2.source.contents.modificationTime++;
      a2.source.contents.data = 'import "a4.dart";';

      var a3 = nodeOf('/a3.dart');
      a3.source.contents.modificationTime++;
      rebuild(node, graph, buildNoTransitiveChange);

      // a3 will become unreachable, index3 reflects structural changes.
      expect(results, ['a2.dart', 'index3.html']);

      results = [];
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, []);
    });

    test('newly discovered files get built too', () {
      var node = nodeOf('/index3.html');
      rebuild(node, graph, buildNoTransitiveChange);
      results = [];

      var a2 = nodeOf('/a2.dart');
      a2.source.contents.modificationTime++;
      a2.source.contents.data = 'import "a9.dart";';

      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, ['a8.dart', 'a9.dart', 'a2.dart', 'index3.html']);

      results = [];
      rebuild(node, graph, buildNoTransitiveChange);
      expect(results, []);
    });

    group('file upgrades', () {
      // Normally upgrading involves two changes:
      //  (a) change the affected file
      //  (b) change directive from part to import (or viceversa)
      // These could happen in any order and we should reach a consistent state
      // in the end.

      test('convert part to a library before updating the import', () {
        var node = nodeOf('/index3.html');
        var a2 = nodeOf('/a2.dart');
        var a6 = nodeOf('/a6.dart');
        rebuild(node, graph, buildNoTransitiveChange);

        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');

        // Modify the file first:
        a6.source.contents.modificationTime++;
        a6.source.contents.data = 'library a6; import "a5.dart";';
        results = [];
        rebuild(node, graph, buildNoTransitiveChange);

        // Looks to us like a change in a part, we'll report errors that the
        // part is not really a part-file. Note that a6.dart is not included
        // below, because we don't build it as a library.
        expect(results, ['a2.dart']);
        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');

        a2.source.contents.modificationTime++;
        a2.source.contents.data = '''
            library a2;
            import 'a3.dart';
            import 'a4.dart';
            import 'a6.dart'; // properly import it
            export 'a5.dart';
          ''';
        results = [];
        rebuild(node, graph, buildNoTransitiveChange);
        // Note that a6 is now included, because we haven't built it as a
        // library until now:
        expect(results, ['a6.dart', 'a2.dart', 'index3.html']);

        a6.source.contents.modificationTime++;
        results = [];
        rebuild(node, graph, buildNoTransitiveChange);
        expect(results, ['a6.dart']);

        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a6.dart
            |    |    |-- a5.dart
            |    |-- a5.dart...
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');
      });

      test('convert part to a library after updating the import', () {
        var node = nodeOf('/index3.html');
        var a2 = nodeOf('/a2.dart');
        var a6 = nodeOf('/a6.dart');
        rebuild(node, graph, buildNoTransitiveChange);

        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');

        a2.source.contents.modificationTime++;
        a2.source.contents.data = '''
            library a2;
            import 'a3.dart';
            import 'a4.dart';
            import 'a6.dart'; // properly import it
            export 'a5.dart';
          ''';
        results = [];
        rebuild(node, graph, buildNoTransitiveChange);
        expect(results, ['a6.dart', 'a2.dart', 'index3.html']);
        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a6.dart
            |    |-- a5.dart
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');

        a6.source.contents.modificationTime++;
        a6.source.contents.data = 'library a6; import "a5.dart";';
        results = [];
        rebuild(node, graph, buildNoTransitiveChange);
        expect(results, ['a6.dart', 'index3.html']);
        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a6.dart
            |    |    |-- a5.dart
            |    |-- a5.dart...
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');
      });

      test('disconnect part making it a library', () {
        var node = nodeOf('/index3.html');
        var a2 = nodeOf('/a2.dart');
        var a6 = nodeOf('/a6.dart');
        rebuild(node, graph, buildNoTransitiveChange);

        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');

        a2.source.contents.modificationTime++;
        a2.source.contents.data = '''
            library a2;
            import 'a3.dart';
            import 'a4.dart';
            export 'a5.dart';
          ''';
        a6.source.contents.modificationTime++;
        a6.source.contents.data = 'library a6; import "a5.dart";';
        results = [];
        rebuild(node, graph, buildNoTransitiveChange);
        // a6 is not here, it's not reachable so we don't build it.
        expect(results, ['a2.dart', 'index3.html']);
        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');
      });

      test('convert a library to a part', () {
        var node = nodeOf('/index3.html');
        var a2 = nodeOf('/a2.dart');
        var a5 = nodeOf('/a5.dart');
        rebuild(node, graph, buildNoTransitiveChange);

        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');

        a2.source.contents.modificationTime++;
        a2.source.contents.data = '''
            library a2;
            import 'a3.dart';
            import 'a4.dart';
            part 'a5.dart'; // make it a part
            part 'a6.dart';
          ''';
        results = [];
        rebuild(node, graph, buildNoTransitiveChange);
        expect(results, ['a2.dart', 'index3.html']);
        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart (part)
            |    |-- a6.dart (part)
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');

        a5.source.contents.modificationTime++;
        a5.source.contents.data = 'part of a2;';
        results = [];
        rebuild(node, graph, buildNoTransitiveChange);
        expect(results, ['a2.dart']);
        expectGraph(node, '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart (part)
            |    |-- a6.dart (part)
            |-- harmony_feature_check.js
            |-- dart_runtime.js
            |-- dart_core.js
            ''');
      });
    });

    group('represented non-existing files', () {
      test('recognize locally change between existing and not-existing', () {
        var n = nodeOf('/foo.dart');
        expect(n.source, isNotNull);
        expect(n.source.exists(), isFalse);
        var source = testUriResolver.files[new Uri.file('/foo.dart')];
        expect(n.source, source);
        source.contents.data = "hi";
        source.contents.modificationTime++;
        expect(n.source.exists(), isTrue);
      });

      test('non-existing files are tracked in dependencies', () {
        var node = nodeOf('/foo.dart');
        node.source.contents.data = "import 'bar.dart';";
        rebuild(node, graph, buildNoTransitiveChange);
        expect(node.allDeps.contains(nodeOf('/bar.dart')), isTrue);

        var source = nodeOf('/bar.dart').source;
        source.contents.data = "hi";
        source.contents.modificationTime++;
        results = [];
        rebuild(node, graph, buildWithTransitiveChange);
        expect(results, ['bar.dart', 'foo.dart']);
      });
    });

    group('null for non-existing files', () {
      setUp(() {
        testUriResolver =
            new TestUriResolver(testFiles, representNonExistingFiles: false);
        context = new TypeResolver.fromMock(mockSdkSources, options,
            otherResolvers: [testUriResolver]).context;
        graph = new SourceGraph(context, new LogReporter(), options);
      });

      test('recognize locally change between existing and not-existing', () {
        var n = nodeOf('/foo.dart');
        expect(n.source, isNull);
        var source = new TestSource(new Uri.file('/foo.dart'), "hi");
        testUriResolver.files[source.uri] = source;
        expect(n.source, isNull);
        n.update(graph);
        expect(n.source, source);
        expect(n.source.exists(), isTrue);
        expect(n.needsRebuild, isTrue);
      });

      test('non-existing files are tracked in dependencies', () {
        var s1 =
            new TestSource(new Uri.file('/foo.dart'), "import 'bar.dart';");
        testUriResolver.files[s1.uri] = s1;
        var node = nodeOf('/foo.dart');
        rebuild(node, graph, buildNoTransitiveChange);
        expect(node.allDeps.length, 1);
        expect(node.allDeps.contains(nodeOf('/bar.dart')), isTrue);
        expect(nodeOf('/bar.dart').source, isNull);

        var s2 = new TestSource(new Uri.file('/bar.dart'), "hi");
        testUriResolver.files[s2.uri] = s2;
        results = [];
        rebuild(node, graph, buildWithTransitiveChange);
        expect(results, ['bar.dart', 'foo.dart']);
      });
    });
  });
}

expectGraph(SourceNode node, String expectation) {
  expect(printReachable(node), equalsIgnoringWhitespace(expectation));
}

nameFor(SourceNode node) => path.basename(node.uri.path);
printReachable(SourceNode node) {
  var seen = new Set();
  var sb = new StringBuffer();
  helper(n, {indent: 0}) {
    if (indent > 0) {
      sb
        ..write("|   " * (indent - 1))
        ..write("|-- ");
    }
    sb.write(nameFor(n));
    if (seen.contains(n)) {
      sb.write('...\n');
      return;
    }
    seen.add(n);
    sb
      ..write(' ')
      ..write(n.needsRebuild ? '[needs-rebuild] ' : '')
      ..write(n.structureChanged ? '[structure-changed] ' : ' ')
      ..write('\n');
    n.depsWithoutParts.forEach((e) => helper(e, indent: indent + 1));
    if (n is DartSourceNode) {
      n.parts.forEach((e) {
        sb
          ..write("|   " * indent)
          ..write("|--  ")
          ..write(nameFor(e))
          ..write(" (part) ")
          ..write(e.needsRebuild ? '[needs-rebuild] ' : '')
          ..write(e.structureChanged ? '[structure-changed] ' : ' ')
          ..write('\n');
      });
    }
  }
  helper(node);
  return sb.toString();
}

bool _same(Set a, Set b) => a.length == b.length && a.containsAll(b);
