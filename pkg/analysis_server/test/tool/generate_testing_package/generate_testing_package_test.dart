// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

import '../../../tool/generate_testing_package.dart';

void main() {
  late Directory parent;

  setUp(() {
    parent = Directory.systemTemp.createTempSync('generate_testing_package');
  });

  tearDown(() {
    parent.deleteSync(recursive: true);
  });

  Future<_Package> generate({
    int libraryCount = 10,
    bool useBarrelFile = false,
    bool useCoreBarrelCycle = false,
  }) async {
    await generateTestingPackage(
      parent,
      libraryCount: libraryCount,
      classCount: 1,
      methodCount: 1,
      parameterCount: 1,
      useBarrelFile: useBarrelFile,
      useCoreBarrelCycle: useCoreBarrelCycle,
      useJsonSerializable: false,
    );
    return _Package.read(Directory('${parent.path}/test_package'));
  }

  group('default', () {
    test('writes only the libraries and the pubspec', () async {
      var package = await generate(libraryCount: 4);
      expect(package.libraries, [
        'lib1.dart',
        'lib2.dart',
        'lib3.dart',
        'lib4.dart',
      ]);
      expect(package.pubspec, contains('name: test_package'));
    });

    test('has no library cycle', () async {
      var package = await generate();
      expect(package.librariesOnCycle, isEmpty);
    });
  });

  group('useBarrelFile', () {
    test('barrel exports the first half of the libraries', () async {
      var package = await generate(libraryCount: 4, useBarrelFile: true);
      expect(package.exportsOf('barrel.dart'), ['lib1.dart', 'lib2.dart']);
      expect(package.libraries, isNot(contains('core.dart')));
    });

    test('has no library cycle', () async {
      var package = await generate(useBarrelFile: true);
      expect(package.librariesOnCycle, isEmpty);
    });
  });

  group('useCoreBarrelCycle', () {
    test('core exports every library, in order, and imports nothing', () async {
      var package = await generate(useCoreBarrelCycle: true);
      expect(package.exportsOf('core.dart'), [
        for (var i = 1; i <= 10; i++) 'lib$i.dart',
      ]);
      expect(package.importsOf('core.dart'), isEmpty);
    });

    test('every library imports core exactly once', () async {
      var package = await generate(useCoreBarrelCycle: true);
      for (var i = 1; i <= 10; i++) {
        expect(
          package.importsOf('lib$i.dart').where((uri) => uri == 'core.dart'),
          ['core.dart'],
          reason: 'lib$i.dart',
        );
      }
    });

    test('makes core and every library one library cycle', () async {
      var package = await generate(useCoreBarrelCycle: true);
      var libraries = package.libraries.where((name) => name != 'core.dart');
      expect(libraries, hasLength(10));
      for (var library in libraries) {
        expect(
          package.reaches(library, 'core.dart'),
          isTrue,
          reason: '$library should reach core.dart',
        );
        expect(
          package.reaches('core.dart', library),
          isTrue,
          reason: 'core.dart should reach $library',
        );
      }
      expect(package.librariesOnCycle, package.libraries);
    });

    test('with a single library, the library and core form a cycle', () async {
      var package = await generate(libraryCount: 1, useCoreBarrelCycle: true);
      expect(package.exportsOf('core.dart'), ['lib1.dart']);
      expect(package.importsOf('lib1.dart'), ['core.dart']);
      expect(package.librariesOnCycle, ['core.dart', 'lib1.dart']);
    });

    test('combined with useBarrelFile keeps both barrels', () async {
      var package = await generate(
        libraryCount: 4,
        useBarrelFile: true,
        useCoreBarrelCycle: true,
      );
      expect(package.exportsOf('barrel.dart'), ['lib1.dart', 'lib2.dart']);
      expect(package.exportsOf('core.dart'), [
        'lib1.dart',
        'lib2.dart',
        'lib3.dart',
        'lib4.dart',
      ]);
      for (var i = 1; i <= 4; i++) {
        expect(
          package.importsOf('lib$i.dart').where((uri) => uri == 'core.dart'),
          ['core.dart'],
          reason: 'lib$i.dart',
        );
      }
    });
  });
}

/// The libraries of a generated package, and the directives between them.
class _Package {
  final String pubspec;

  /// The names of the files in `lib`, sorted.
  final List<String> libraries;

  final Map<String, List<String>> _imports = {};
  final Map<String, List<String>> _exports = {};

  factory read(Directory directory) {
    var libDirectory = Directory('${directory.path}/lib');
    var names = [
      for (var entity in libDirectory.listSync())
        if (entity is File) _basename(entity.path),
    ]..sort(_compareNames);
    var package = _Package._(
      File('${directory.path}/pubspec.yaml').readAsStringSync(),
      names,
    );
    for (var name in names) {
      // Throws on a syntax error, so every generated file must be valid Dart.
      var unit = parseString(
        content: File('${libDirectory.path}/$name').readAsStringSync(),
      ).unit;
      package._imports[name] = [
        for (var directive in unit.directives.whereType<ImportDirective>())
          _basename(directive.uri.stringValue!),
      ];
      package._exports[name] = [
        for (var directive in unit.directives.whereType<ExportDirective>())
          _basename(directive.uri.stringValue!),
      ];
    }
    return package;
  }

  new _(this.pubspec, this.libraries);

  /// The libraries that are part of a cycle of imports and exports, sorted.
  List<String> get librariesOnCycle => [
    for (var name in libraries)
      if (_successors(name).any((next) => reaches(next, name))) name,
  ];

  /// The files exported by [library], in directive order.
  List<String> exportsOf(String library) => _exports[library]!;

  /// The files imported by [library], in directive order.
  List<String> importsOf(String library) => _imports[library]!;

  /// Whether [to] can be reached from [from] by following imports and exports.
  /// A file reaches itself.
  bool reaches(String from, String to) {
    var visited = <String>{};
    var pending = [from];
    while (pending.isNotEmpty) {
      var current = pending.removeLast();
      if (current == to) return true;
      if (visited.add(current)) {
        pending.addAll(_successors(current));
      }
    }
    return false;
  }

  Iterable<String> _successors(String library) => [
    ...?_imports[library],
    ...?_exports[library],
  ];

  static String _basename(String path) => path.split(RegExp('[/:]')).last;

  /// Compares `lib2.dart` before `lib10.dart`, and the others by name.
  static int _compareNames(String a, String b) {
    var aIndex = int.tryParse(
      RegExp(r'^lib(\d+)\.dart$').firstMatch(a)?[1] ?? '',
    );
    var bIndex = int.tryParse(
      RegExp(r'^lib(\d+)\.dart$').firstMatch(b)?[1] ?? '',
    );
    if (aIndex != null && bIndex != null) return aIndex.compareTo(bIndex);
    return a.compareTo(b);
  }
}
