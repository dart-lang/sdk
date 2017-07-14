// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/dependency_grapher.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DependencyGrapherTest);
  });
}

@reflectiveTest
class DependencyGrapherTest {
  LibraryNode checkLibrary(LibraryCycleNode cycle, String uri,
      {List<String> dependencies: const ['dart:core'],
      List<String> parts: const []}) {
    var library = cycle.libraries[Uri.parse(uri)];
    expect('${library.uri}', uri);
    expect(library.dependencies.map((dep) => '${dep.uri}'),
        unorderedEquals(dependencies));
    expect(library.parts.map((part) => '$part'), unorderedEquals(parts));
    return library;
  }

  Future<List<LibraryCycleNode>> getCycles(Map<String, String> contents,
      {List<String> startingPoints, String packagesFilePath}) async {
    // If no starting points given, assume the first entry in [contents] is the
    // single starting point.
    startingPoints ??= [contents.keys.first];
    var fileSystem = new MemoryFileSystem(Uri.parse('file:///'));
    if (packagesFilePath == null) {
      fileSystem.entityForUri(Uri.parse('.packages')).writeAsStringSync('');
    }
    contents.forEach((path, text) {
      fileSystem.entityForUri(pathos.posix.toUri(path)).writeAsStringSync(text);
    });
    // TODO(paulberry): implement and test other option possibilities.
    var options = new CompilerOptions()
      ..fileSystem = fileSystem
      ..chaseDependencies = true
      ..packagesFileUri = packagesFilePath == null
          ? Uri.parse('.packages')
          : pathos.posix.toUri(packagesFilePath);
    var graph = await graphForProgram(
        startingPoints.map(pathos.posix.toUri).toList(), options);
    return graph.topologicallySortedCycles;
  }

  /// Sort the given library cycles into a deterministic order based on their
  /// URIs for easier unit testing.
  List<LibraryCycleNode> sortCycles(Iterable<LibraryCycleNode> cycles) {
    var result = cycles.toList();
    String sortKey(LibraryCycleNode node) => node.libraries.keys.join(',');
    result.sort((a, b) => Comparable.compare(sortKey(a), sortKey(b)));
    return result;
  }

  test_explicitCoreDependency() async {
    // If "dart:core" is explicitly imported, there shouldn't be two imports of
    // "dart:core", just one.
    var cycles = await getCycles({'/foo.dart': 'import "dart:core";'});
    expect(cycles, hasLength(1));
    expect(cycles[0].libraries, hasLength(1));
    checkLibrary(cycles[0], 'file:///foo.dart');
  }

  test_exportDependency() async {
    var cycles =
        await getCycles({'/foo.dart': 'export "bar.dart";', '/bar.dart': ''});
    expect(cycles, hasLength(2));
    expect(cycles[0].libraries, hasLength(1));
    checkLibrary(cycles[0], 'file:///bar.dart');
    expect(cycles[1].libraries, hasLength(1));
    checkLibrary(cycles[1], 'file:///foo.dart',
        dependencies: ['file:///bar.dart', 'dart:core']);
  }

  test_importDependency() async {
    var cycles =
        await getCycles({'/foo.dart': 'import "bar.dart";', '/bar.dart': ''});
    expect(cycles, hasLength(2));
    expect(cycles[0].libraries, hasLength(1));
    checkLibrary(cycles[0], 'file:///bar.dart');
    expect(cycles[1].libraries, hasLength(1));
    checkLibrary(cycles[1], 'file:///foo.dart',
        dependencies: ['file:///bar.dart', 'dart:core']);
  }

  test_multipleStartingPoints() async {
    var cycles = await getCycles({
      '/a.dart': 'import "c.dart";',
      '/b.dart': 'import "c.dart";',
      '/c.dart': ''
    }, startingPoints: [
      '/a.dart',
      '/b.dart'
    ]);
    expect(cycles, hasLength(3));
    expect(cycles[0].libraries, hasLength(1));
    checkLibrary(cycles[0], 'file:///c.dart');
    // The other two cycles might be in any order, so sort them for
    // reproducibility.
    List<LibraryCycleNode> otherCycles = sortCycles(cycles.sublist(1));
    checkLibrary(otherCycles[0], 'file:///a.dart',
        dependencies: ['file:///c.dart', 'dart:core']);
    checkLibrary(otherCycles[1], 'file:///b.dart',
        dependencies: ['file:///c.dart', 'dart:core']);
  }

  test_packages() async {
    var cycles = await getCycles({
      '/foo.dart': 'import "package:foo/bar.dart";',
      '/.packages': 'foo:pkg/foo/lib\nbar:pkg/bar/lib\n',
      '/pkg/foo/lib/bar.dart': 'import "package:bar/baz.dart";',
      '/pkg/bar/lib/baz.dart': ''
    }, packagesFilePath: '/.packages');
    expect(cycles, hasLength(3));
    expect(cycles[0].libraries, hasLength(1));
    checkLibrary(cycles[0], 'package:bar/baz.dart');
    expect(cycles[1].libraries, hasLength(1));
    checkLibrary(cycles[1], 'package:foo/bar.dart',
        dependencies: ['package:bar/baz.dart', 'dart:core']);
    expect(cycles[2].libraries, hasLength(1));
    checkLibrary(cycles[2], 'file:///foo.dart',
        dependencies: ['package:foo/bar.dart', 'dart:core']);
  }

  test_parts() async {
    var cycles = await getCycles({
      '/foo.dart': 'library foo; part "a.dart"; part "b.dart";',
      '/a.dart': 'part of foo;',
      '/b.dart': 'part of foo;'
    });
    expect(cycles, hasLength(1));
    expect(cycles[0].libraries, hasLength(1));
    checkLibrary(cycles[0], 'file:///foo.dart',
        parts: ['file:///a.dart', 'file:///b.dart']);
  }

  test_relativeUris() async {
    var cycles = await getCycles({
      '/a.dart': 'import "b/c.dart";',
      '/b/c.dart': 'import "d/e.dart";',
      '/b/d/e.dart': 'import "../f.dart";',
      '/b/f.dart': ''
    });
    expect(cycles, hasLength(4));
    expect(cycles[0].libraries, hasLength(1));
    checkLibrary(cycles[0], 'file:///b/f.dart');
    expect(cycles[1].libraries, hasLength(1));
    checkLibrary(cycles[1], 'file:///b/d/e.dart',
        dependencies: ['file:///b/f.dart', 'dart:core']);
    expect(cycles[2].libraries, hasLength(1));
    checkLibrary(cycles[2], 'file:///b/c.dart',
        dependencies: ['file:///b/d/e.dart', 'dart:core']);
    expect(cycles[3].libraries, hasLength(1));
    checkLibrary(cycles[3], 'file:///a.dart',
        dependencies: ['file:///b/c.dart', 'dart:core']);
  }

  test_sdkDependency() async {
    // Dependencies on the SDK should be recorded even if SDK libraries aren't
    // being included in the graph.
    var cycles = await getCycles({'/foo.dart': 'import "dart:async";'});
    expect(cycles, hasLength(1));
    expect(cycles[0].libraries, hasLength(1));
    checkLibrary(cycles[0], 'file:///foo.dart',
        dependencies: ['dart:core', 'dart:async']);
  }

  test_simpleCycle() async {
    var cycles = await getCycles(
        {'/foo.dart': 'import "bar.dart";', '/bar.dart': 'import "foo.dart";'});
    expect(cycles, hasLength(1));
    expect(cycles[0].libraries, hasLength(2));
    var foo = checkLibrary(cycles[0], 'file:///foo.dart',
        dependencies: ['file:///bar.dart', 'dart:core']);
    var bar = checkLibrary(cycles[0], 'file:///bar.dart',
        dependencies: ['file:///foo.dart', 'dart:core']);
    expect(foo.dependencies[0], same(bar));
    expect(bar.dependencies[0], same(foo));
  }

  test_singleFile() async {
    var cycles = await getCycles({'/foo.dart': ''});
    expect(cycles, hasLength(1));
    expect(cycles[0].libraries, hasLength(1));
    checkLibrary(cycles[0], 'file:///foo.dart');
  }
}
