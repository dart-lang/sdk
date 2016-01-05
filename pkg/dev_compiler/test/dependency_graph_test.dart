// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.test.dependency_graph_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:dev_compiler/src/analysis_context.dart';
import 'package:dev_compiler/src/compiler.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/report.dart';
import 'package:dev_compiler/src/server/dependency_graph.dart';

import 'testing.dart';

void main() {
  var options = new CompilerOptions(
      runtimeDir: '/dev_compiler_runtime/',
      sourceOptions: new SourceResolverOptions(useMockSdk: true));
  MemoryResourceProvider testResourceProvider;
  ResourceUriResolver testUriResolver;
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
    testResourceProvider = createTestResourceProvider(testFiles);
    testUriResolver = new ResourceUriResolver(testResourceProvider);
    context = createAnalysisContextWithSources(options.sourceOptions,
        fileResolvers: [testUriResolver]);
    graph = new SourceGraph(context, new LogReporter(context), options);
  });

  updateFile(Source source, [String newContents]) {
    var path = testResourceProvider.pathContext.fromUri(source.uri);
    if (newContents == null) newContents = source.contents.data;
    testResourceProvider.updateFile(path, newContents);
  }

  group('HTML deps', () {
    test('initial deps', () {
      var i1 = nodeOf('/index1.html');
      var i2 = nodeOf('/index2.html');
      expect(i1.scripts.length, 0);
      expect(i2.scripts.length, 0);
      i1.update();
      i2.update();
      expect(i1.scripts.length, 0);
      expect(i2.scripts.length, 1);
      expect(i2.scripts.first, nodeOf('/a1.dart'));
    });

    test('add a dep', () {
      // After initial load, dependencies are 0:
      var node = nodeOf('/index1.html');
      node.update();
      expect(node.scripts.length, 0);

      // Adding the dependency is discovered on the next round of updates:
      updateFile(node.source,
          '<script type="application/dart" src="a2.dart"></script>');
      expect(node.scripts.length, 0);
      node.update();
      expect(node.scripts.length, 1);
      expect(node.scripts.first, nodeOf('/a2.dart'));
    });

    test('add more deps', () {
      // After initial load, dependencies are 1:
      var node = nodeOf('/index2.html');
      node.update();
      expect(node.scripts.length, 1);
      expect(node.scripts.first, nodeOf('/a1.dart'));

      updateFile(
          node.source,
          node.source.contents.data +
              '<script type="application/dart" src="a2.dart"></script>');
      expect(node.scripts.length, 1);
      node.update();
      expect(node.scripts.length, 2);
      expect(node.scripts.first, nodeOf('/a1.dart'));
      expect(node.scripts.last, nodeOf('/a2.dart'));
    });

    test('remove all deps', () {
      // After initial load, dependencies are 1:
      var node = nodeOf('/index2.html');
      node.update();
      expect(node.scripts.length, 1);
      expect(node.scripts.first, nodeOf('/a1.dart'));

      // Removing the dependency is discovered on the next round of updates:
      updateFile(node.source, '');
      expect(node.scripts.length, 1);
      node.update();
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

      a1.update();
      a2.update();

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
      node.update();
      expect(node.imports.length, 0);
      expect(node.exports.length, 0);
      expect(node.parts.length, 0);

      updateFile(
          node.source, 'import "a3.dart"; export "a5.dart"; part "a8.dart";');
      node.update();

      expect(node.imports.length, 1);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a8.dart')), isTrue);
    });

    test('remove deps', () {
      var node = nodeOf('/a2.dart');
      node.update();
      expect(node.imports.length, 2);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.imports.contains(nodeOf('/a4.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a6.dart')), isTrue);

      updateFile(
          node.source, 'import "a3.dart"; export "a7.dart"; part "a8.dart";');
      node.update();

      expect(node.imports.length, 1);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a7.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a8.dart')), isTrue);
    });

    test('change part to library', () {
      var node = nodeOf('/a2.dart');
      node.update();
      expect(node.imports.length, 2);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.imports.contains(nodeOf('/a4.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a6.dart')), isTrue);

      updateFile(
          node.source,
          '''
          library a2;
          import 'a3.dart';
          import 'a4.dart';
          export 'a5.dart';
          import 'a6.dart'; // changed from part
        ''');
      var a6 = nodeOf('/a6.dart');
      updateFile(a6.source, '');
      node.update();

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
      node.update();
      expect(node.imports.length, 2);
      expect(node.exports.length, 1);
      expect(node.parts.length, 1);
      expect(node.imports.contains(nodeOf('/a3.dart')), isTrue);
      expect(node.imports.contains(nodeOf('/a4.dart')), isTrue);
      expect(node.exports.contains(nodeOf('/a5.dart')), isTrue);
      expect(node.parts.contains(nodeOf('/a6.dart')), isTrue);

      a4.update();
      expect(a4.imports.length, 0);
      expect(a4.exports.length, 1);
      expect(a4.parts.length, 0);

      updateFile(
          node.source,
          '''
          library a2;
          import 'a3.dart';
          part 'a4.dart'; // changed from export
          export 'a5.dart';
          part 'a6.dart';
        ''');
      node.update();

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
      updateFile(
          node.source,
          '''
          library a2;
          import 'a3.dart';
          import 'a4.dart'; // changed again
          export 'a5.dart';
          part 'a6.dart';
        ''');
      node.update();
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
        node.update();
        expect(node.needsRebuild, isTrue);
        node.needsRebuild = false;

        node.update();
        expect(node.needsRebuild, isFalse);

        // For now, an empty modification is enough to trigger a rebuild
        updateFile(node.source);
        expect(node.needsRebuild, isFalse);
        node.update();
        expect(node.needsRebuild, isTrue);
      });

      test('main library in Dart', () {
        var node = nodeOf('/a2.dart');
        var partNode = nodeOf('/a6.dart');
        node.update();
        expect(node.needsRebuild, isTrue);
        node.needsRebuild = false;
        partNode.needsRebuild = false;

        node.update();
        expect(node.needsRebuild, isFalse);

        // For now, an empty modification is enough to trigger a rebuild
        updateFile(node.source);
        expect(node.needsRebuild, isFalse);
        node.update();
        expect(node.needsRebuild, isTrue);
      });

      test('part of library in Dart', () {
        var node = nodeOf('/a2.dart');
        var importNode = nodeOf('/a3.dart');
        var exportNode = nodeOf('/a5.dart');
        var partNode = nodeOf('/a6.dart');
        node.update();
        expect(node.needsRebuild, isTrue);
        node.needsRebuild = false;
        partNode.needsRebuild = false;

        node.update();
        expect(node.needsRebuild, isFalse);

        // Modification in imported/exported node makes no difference for local
        // rebuild label (globally that's tested elsewhere)
        updateFile(importNode.source);
        updateFile(exportNode.source);
        node.update();
        expect(node.needsRebuild, isFalse);
        expect(partNode.needsRebuild, isFalse);

        // Modification in part triggers change in containing library:
        updateFile(partNode.source);
        expect(node.needsRebuild, isFalse);
        expect(partNode.needsRebuild, isFalse);
        node.update();
        expect(node.needsRebuild, isTrue);
        expect(partNode.needsRebuild, isTrue);
      });
    });

    group('structure change', () {
      test('no mod in HTML', () {
        var node = nodeOf('/index2.html');
        node.update();
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update();
        expect(node.structureChanged, isFalse);

        // An empty modification will not trigger a structural change
        updateFile(node.source);
        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isFalse);
      });

      test('added scripts in HTML', () {
        var node = nodeOf('/index2.html');
        node.update();
        expect(node.structureChanged, isTrue);
        expect(node.scripts.length, 1);

        node.structureChanged = false;
        node.update();
        expect(node.structureChanged, isFalse);

        // This change will not include new script tags:
        updateFile(node.source, node.source.contents.data + '<div></div>');
        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isFalse);
        expect(node.scripts.length, 1);

        updateFile(
            node.source,
            node.source.contents.data +
                '<script type="application/dart" src="a4.dart"></script>');
        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isTrue);
        expect(node.scripts.length, 2);
      });

      test('no mod in Dart', () {
        var node = nodeOf('/a2.dart');
        var importNode = nodeOf('/a3.dart');
        var exportNode = nodeOf('/a5.dart');
        var partNode = nodeOf('/a6.dart');
        node.update();
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update();
        expect(node.structureChanged, isFalse);

        // These modifications make no difference at all.
        updateFile(importNode.source);
        updateFile(exportNode.source);
        updateFile(partNode.source);
        updateFile(node.source);

        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isFalse);
      });

      test('same directives, different order', () {
        var node = nodeOf('/a2.dart');
        node.update();
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update();
        expect(node.structureChanged, isFalse);

        // modified order of imports, but structure stays the same:
        updateFile(
            node.source,
            'import "a4.dart"; import "a3.dart"; '
            'export "a5.dart"; part "a6.dart";');
        node.update();

        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isFalse);
      });

      test('changed parts', () {
        var node = nodeOf('/a2.dart');
        node.update();
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update();
        expect(node.structureChanged, isFalse);

        // added one.
        updateFile(
            node.source,
            'import "a4.dart"; import "a3.dart"; '
            'export "a5.dart"; part "a6.dart"; part "a7.dart";');
        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isTrue);

        // no change
        node.structureChanged = false;
        updateFile(node.source);
        node.update();
        expect(node.structureChanged, isFalse);

        // removed one
        updateFile(node.source);
        updateFile(
            node.source,
            'import "a4.dart"; import "a3.dart"; '
            'export "a5.dart"; part "a7.dart";');
        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isTrue);
      });

      test('changed import', () {
        var node = nodeOf('/a2.dart');
        node.update();
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update();
        expect(node.structureChanged, isFalse);

        // added one.
        updateFile(
            node.source,
            'import "a4.dart"; import "a3.dart"; import "a7.dart";'
            'export "a5.dart"; part "a6.dart";');
        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isTrue);

        // no change
        node.structureChanged = false;
        updateFile(node.source);
        node.update();
        expect(node.structureChanged, isFalse);

        // removed one
        updateFile(
            node.source,
            'import "a4.dart"; import "a7.dart"; '
            'export "a5.dart"; part "a6.dart";');
        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isTrue);
      });

      test('changed exports', () {
        var node = nodeOf('/a2.dart');
        node.update();
        expect(node.structureChanged, isTrue);
        node.structureChanged = false;

        node.update();
        expect(node.structureChanged, isFalse);

        // added one.
        updateFile(
            node.source,
            'import "a4.dart"; import "a3.dart";'
            'export "a5.dart"; export "a9.dart"; part "a6.dart";');
        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isTrue);

        // no change
        node.structureChanged = false;
        updateFile(node.source);
        node.update();
        expect(node.structureChanged, isFalse);

        // removed one
        updateFile(
            node.source,
            'import "a4.dart"; import "a3.dart"; '
            'export "a5.dart"; part "a6.dart";');
        expect(node.structureChanged, isFalse);
        node.update();
        expect(node.structureChanged, isTrue);
      });
    });
  });

  group('refresh structure and marks', () {
    test('initial marks', () {
      var node = nodeOf('/index3.html');
      expectGraph(
          node,
          '''
          index3.html
          $_RUNTIME_GRAPH
          ''');
      refreshStructureAndMarks(node);
      expectGraph(
          node,
          '''
          index3.html [needs-rebuild] [structure-changed]
          |-- a2.dart [needs-rebuild] [structure-changed]
          |    |-- a3.dart [needs-rebuild]
          |    |-- a4.dart [needs-rebuild] [structure-changed]
          |    |    |-- a10.dart [needs-rebuild]
          |    |-- a5.dart [needs-rebuild]
          |    |-- a6.dart (part) [needs-rebuild]
          $_RUNTIME_GRAPH_REBUILD
          ''');
    });

    test('cleared marks stay clear', () {
      var node = nodeOf('/index3.html');
      refreshStructureAndMarks(node);
      expectGraph(
          node,
          '''
          index3.html [needs-rebuild] [structure-changed]
          |-- a2.dart [needs-rebuild] [structure-changed]
          |    |-- a3.dart [needs-rebuild]
          |    |-- a4.dart [needs-rebuild] [structure-changed]
          |    |    |-- a10.dart [needs-rebuild]
          |    |-- a5.dart [needs-rebuild]
          |    |-- a6.dart (part) [needs-rebuild]
          $_RUNTIME_GRAPH_REBUILD
          ''');
      clearMarks(node);
      expectGraph(
          node,
          '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart
          |    |-- a6.dart (part)
          $_RUNTIME_GRAPH
          ''');

      refreshStructureAndMarks(node);
      expectGraph(
          node,
          '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart
          |    |-- a6.dart (part)
          $_RUNTIME_GRAPH
          ''');
    });

    test('needsRebuild mark updated on local modifications', () {
      var node = nodeOf('/index3.html');
      refreshStructureAndMarks(node);
      clearMarks(node);
      var a3 = nodeOf('/a3.dart');
      updateFile(a3.source);

      refreshStructureAndMarks(node);
      expectGraph(
          node,
          '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart [needs-rebuild]
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart
          |    |-- a6.dart (part)
          $_RUNTIME_GRAPH
          ''');
    });

    test('structuredChanged mark updated on structure modifications', () {
      var node = nodeOf('/index3.html');
      refreshStructureAndMarks(node);
      clearMarks(node);
      var a5 = nodeOf('/a5.dart');
      updateFile(a5.source, 'import "a8.dart";');

      refreshStructureAndMarks(node);
      expectGraph(
          node,
          '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart [needs-rebuild] [structure-changed]
          |    |    |-- a8.dart [needs-rebuild] [structure-changed]
          |    |    |    |-- a8.dart...
          |    |-- a6.dart (part)
          $_RUNTIME_GRAPH
          ''');
    });
  });

  group('server-mode', () {
    setUp(() {
      var opts = new CompilerOptions(
          runtimeDir: '/dev_compiler_runtime/',
          sourceOptions: new SourceResolverOptions(useMockSdk: true),
          serverMode: true);
      context = createAnalysisContextWithSources(opts.sourceOptions,
          fileResolvers: [testUriResolver]);
      graph = new SourceGraph(context, new LogReporter(context), opts);
    });

    test('messages widget is automatically included', () {
      var node = nodeOf('/index3.html');
      expectGraph(
          node,
          '''
          index3.html
          $_RUNTIME_GRAPH
          |-- messages_widget.js
          |-- messages.css
          ''');
      refreshStructureAndMarks(node);
      expectGraph(
          node,
          '''
          index3.html [needs-rebuild] [structure-changed]
          |-- a2.dart [needs-rebuild] [structure-changed]
          |    |-- a3.dart [needs-rebuild]
          |    |-- a4.dart [needs-rebuild] [structure-changed]
          |    |    |-- a10.dart [needs-rebuild]
          |    |-- a5.dart [needs-rebuild]
          |    |-- a6.dart (part) [needs-rebuild]
          $_RUNTIME_GRAPH_REBUILD
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
      rebuild(node, buildNoTransitiveChange);
      // Note: a6.dart is not included because it built as part of a2.dart
      expect(
          results,
          ['a3.dart', 'a10.dart', 'a4.dart', 'a5.dart', 'a2.dart']
            ..addAll(runtimeFilesWithoutPath)
            ..add('index3.html'));

      // Marks are removed automatically by rebuild
      expectGraph(
          node,
          '''
          index3.html
          |-- a2.dart
          |    |-- a3.dart
          |    |-- a4.dart
          |    |    |-- a10.dart
          |    |-- a5.dart
          |    |-- a6.dart (part)
          $_RUNTIME_GRAPH
          ''');
    });

    test('nothing to do after build', () {
      var node = nodeOf('/index3.html');
      rebuild(node, buildNoTransitiveChange);

      results = [];
      rebuild(node, buildNoTransitiveChange);
      expect(results, []);
    });

    test('modified part triggers building library', () {
      var node = nodeOf('/index3.html');
      rebuild(node, buildNoTransitiveChange);
      results = [];

      var a6 = nodeOf('/a6.dart');
      updateFile(a6.source);
      rebuild(node, buildNoTransitiveChange);
      expect(results, ['a2.dart']);

      results = [];
      rebuild(node, buildNoTransitiveChange);
      expect(results, []);
    });

    test('non-API change triggers build stays local', () {
      var node = nodeOf('/index3.html');
      rebuild(node, buildNoTransitiveChange);
      results = [];

      var a3 = nodeOf('/a3.dart');
      updateFile(a3.source);
      rebuild(node, buildNoTransitiveChange);
      expect(results, ['a3.dart']);

      results = [];
      rebuild(node, buildNoTransitiveChange);
      expect(results, []);
    });

    test('no-API change in exported file stays local', () {
      var node = nodeOf('/index3.html');
      rebuild(node, buildNoTransitiveChange);
      results = [];

      // similar to the test above, but a10 is exported from a4.
      var a3 = nodeOf('/a10.dart');
      updateFile(a3.source);
      rebuild(node, buildNoTransitiveChange);
      expect(results, ['a10.dart']);

      results = [];
      rebuild(node, buildNoTransitiveChange);
      expect(results, []);
    });

    test('API change in lib, triggers build on imports', () {
      var node = nodeOf('/index3.html');
      rebuild(node, buildNoTransitiveChange);
      results = [];

      var a3 = nodeOf('/a3.dart');
      updateFile(a3.source);
      rebuild(node, buildWithTransitiveChange);
      expect(results, ['a3.dart', 'a2.dart']);

      results = [];
      rebuild(node, buildNoTransitiveChange);
      expect(results, []);
    });

    test('API change in export, triggers build on imports', () {
      var node = nodeOf('/index3.html');
      rebuild(node, buildNoTransitiveChange);
      results = [];

      var a3 = nodeOf('/a10.dart');
      updateFile(a3.source);
      rebuild(node, buildWithTransitiveChange);

      // Node: a4.dart reexports a10.dart, but it doesn't import it, so we don't
      // need to rebuild it.
      expect(results, ['a10.dart', 'a2.dart']);

      results = [];
      rebuild(node, buildNoTransitiveChange);
      expect(results, []);
    });

    test('structural change rebuilds HTML, but skips unreachable code', () {
      var node = nodeOf('/index3.html');
      rebuild(node, buildNoTransitiveChange);
      results = [];

      var a2 = nodeOf('/a2.dart');
      updateFile(a2.source, 'import "a4.dart";');

      var a3 = nodeOf('/a3.dart');
      updateFile(a3.source);
      rebuild(node, buildNoTransitiveChange);

      // a3 will become unreachable, index3 reflects structural changes.
      expect(results, ['a2.dart', 'index3.html']);

      results = [];
      rebuild(node, buildNoTransitiveChange);
      expect(results, []);
    });

    test('newly discovered files get built too', () {
      var node = nodeOf('/index3.html');
      rebuild(node, buildNoTransitiveChange);
      results = [];

      var a2 = nodeOf('/a2.dart');
      updateFile(a2.source, 'import "a9.dart";');

      rebuild(node, buildNoTransitiveChange);
      expect(results, ['a8.dart', 'a9.dart', 'a2.dart', 'index3.html']);

      results = [];
      rebuild(node, buildNoTransitiveChange);
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
        rebuild(node, buildNoTransitiveChange);

        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            $_RUNTIME_GRAPH
            ''');

        // Modify the file first:
        updateFile(a6.source, 'library a6; import "a5.dart";');
        results = [];
        rebuild(node, buildNoTransitiveChange);

        // Looks to us like a change in a part, we'll report errors that the
        // part is not really a part-file. Note that a6.dart is not included
        // below, because we don't build it as a library.
        expect(results, ['a2.dart']);
        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            $_RUNTIME_GRAPH
            ''');

        updateFile(
            a2.source,
            '''
            library a2;
            import 'a3.dart';
            import 'a4.dart';
            import 'a6.dart'; // properly import it
            export 'a5.dart';
          ''');
        results = [];
        rebuild(node, buildNoTransitiveChange);
        // Note that a6 is now included, because we haven't built it as a
        // library until now:
        expect(results, ['a6.dart', 'a2.dart', 'index3.html']);

        updateFile(a6.source);
        results = [];
        rebuild(node, buildNoTransitiveChange);
        expect(results, ['a6.dart']);

        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a6.dart
            |    |    |-- a5.dart
            |    |-- a5.dart...
            $_RUNTIME_GRAPH
            ''');
      });

      test('convert part to a library after updating the import', () {
        var node = nodeOf('/index3.html');
        var a2 = nodeOf('/a2.dart');
        var a6 = nodeOf('/a6.dart');
        rebuild(node, buildNoTransitiveChange);

        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            $_RUNTIME_GRAPH
            ''');

        updateFile(
            a2.source,
            '''
            library a2;
            import 'a3.dart';
            import 'a4.dart';
            import 'a6.dart'; // properly import it
            export 'a5.dart';
          ''');
        results = [];
        rebuild(node, buildNoTransitiveChange);
        expect(results, ['a6.dart', 'a2.dart', 'index3.html']);
        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a6.dart
            |    |-- a5.dart
            $_RUNTIME_GRAPH
            ''');

        updateFile(a6.source, 'library a6; import "a5.dart";');
        results = [];
        rebuild(node, buildNoTransitiveChange);
        expect(results, ['a6.dart', 'index3.html']);
        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a6.dart
            |    |    |-- a5.dart
            |    |-- a5.dart...
            $_RUNTIME_GRAPH
            ''');
      });

      test('disconnect part making it a library', () {
        var node = nodeOf('/index3.html');
        var a2 = nodeOf('/a2.dart');
        var a6 = nodeOf('/a6.dart');
        rebuild(node, buildNoTransitiveChange);

        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            $_RUNTIME_GRAPH
            ''');

        updateFile(
            a2.source,
            '''
            library a2;
            import 'a3.dart';
            import 'a4.dart';
            export 'a5.dart';
          ''');
        updateFile(a6.source, 'library a6; import "a5.dart";');
        results = [];
        rebuild(node, buildNoTransitiveChange);
        // a6 is not here, it's not reachable so we don't build it.
        expect(results, ['a2.dart', 'index3.html']);
        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            $_RUNTIME_GRAPH
            ''');
      });

      test('convert a library to a part', () {
        var node = nodeOf('/index3.html');
        var a2 = nodeOf('/a2.dart');
        var a5 = nodeOf('/a5.dart');
        rebuild(node, buildNoTransitiveChange);

        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart
            |    |-- a6.dart (part)
            $_RUNTIME_GRAPH
            ''');

        updateFile(
            a2.source,
            '''
            library a2;
            import 'a3.dart';
            import 'a4.dart';
            part 'a5.dart'; // make it a part
            part 'a6.dart';
          ''');
        results = [];
        rebuild(node, buildNoTransitiveChange);
        expect(results, ['a2.dart', 'index3.html']);
        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart (part)
            |    |-- a6.dart (part)
            $_RUNTIME_GRAPH
            ''');

        updateFile(a5.source, 'part of a2;');
        results = [];
        rebuild(node, buildNoTransitiveChange);
        expect(results, ['a2.dart']);
        expectGraph(
            node,
            '''
            index3.html
            |-- a2.dart
            |    |-- a3.dart
            |    |-- a4.dart
            |    |    |-- a10.dart
            |    |-- a5.dart (part)
            |    |-- a6.dart (part)
            $_RUNTIME_GRAPH
            ''');
      });
    });

    group('represented non-existing files', () {
      test('recognize locally change between existing and not-existing', () {
        var n = nodeOf('/foo.dart');
        expect(n.source, isNotNull);
        expect(n.source.exists(), isFalse);
        var source = testUriResolver.resolveAbsolute(new Uri.file('/foo.dart'));
        expect(n.source, source);
        updateFile(source, "hi");
        expect(n.source.exists(), isTrue);
      });

      test('non-existing files are tracked in dependencies', () {
        var node = nodeOf('/foo.dart');
        updateFile(node.source, "import 'bar.dart';");
        rebuild(node, buildNoTransitiveChange);
        expect(node.allDeps.contains(nodeOf('/bar.dart')), isTrue);

        var source = nodeOf('/bar.dart').source;
        updateFile(source, "hi");
        results = [];
        rebuild(node, buildWithTransitiveChange);
        expect(results, ['bar.dart', 'foo.dart']);
      });
    });

    group('null for non-existing files', () {
      setUp(() {
        context = createAnalysisContextWithSources(options.sourceOptions,
            fileResolvers: [testUriResolver]);
        graph = new SourceGraph(context, new LogReporter(context), options);
      });

      test('recognize locally change between existing and not-existing', () {
        var n = nodeOf('/foo.dart');
        expect(n.source.exists(), isFalse);
        var source =
            testResourceProvider.newFile('/foo.dart', 'hi').createSource();
        expect(
            testUriResolver.resolveAbsolute(new Uri.file('/foo.dart')), source);
        expect(n.source, source);
        expect(n.source.exists(), isTrue);
        n.update();
        expect(n.needsRebuild, isTrue);
      });

      test('non-existing files are tracked in dependencies', () {
        testResourceProvider
            .newFile('/foo.dart', "import 'bar.dart';")
            .createSource();
        var node = nodeOf('/foo.dart');
        rebuild(node, buildNoTransitiveChange);
        expect(node.allDeps.length, 1);
        expect(node.allDeps.contains(nodeOf('/bar.dart')), isTrue);
        expect(nodeOf('/bar.dart').source.exists(), isFalse);

        testResourceProvider.newFile('/bar.dart', 'hi').createSource();
        results = [];
        rebuild(node, buildWithTransitiveChange);
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
      sb..write("|   " * (indent - 1))..write("|-- ");
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

final runtimeFilesWithoutPath = defaultRuntimeFiles
    .map((f) => f.replaceAll('dart/', ''))
    .toList(growable: false);
final _RUNTIME_GRAPH = runtimeFilesWithoutPath.map((s) => '|--  $s').join('\n');
final _RUNTIME_GRAPH_REBUILD =
    runtimeFilesWithoutPath.map((s) => '|--  $s [needs-rebuild]').join('\n');
