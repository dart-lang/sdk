// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/kernel/hot_reload_delta_inspector.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart';
import 'package:test/test.dart';

import 'memory_compiler.dart';

Future<void> main() async {
  group('const classes', () {
    final deltaInspector = HotReloadDeltaInspector();
    test('rejection when removing only const constructor', () async {
      final initialSource = '''
          var globalVariable;

          class A {
            final String s;
            const A(this.s);
          }

          main() {
            globalVariable = const A('hello');
            print(globalVariable.s);
          }
          ''';
      final deltaSource = '''
          var globalVariable;

          class A {
            final String s;
            A(this.s);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) = await compileComponents(
        initialSource,
        deltaSource,
      );
      expect(
        deltaInspector.compareGenerations(initial, delta),
        unorderedEquals([
          'Const class cannot become non-const: '
              "Library:'memory:///main.dart' "
              'Class: A',
        ]),
      );
    });
    test('multiple rejections when removing only const constructors', () async {
      final initialSource = '''
          var globalA, globalB, globalC, globalD;

          class A {
            final String s;
            const A(this.s);
          }

          class B {
            final String s;
            const B(this.s);
          }

          class C {
            final String s;
            C(this.s);
          }

          class D {
            final String s;
            const D(this.s);
          }

          main() {
            globalA = const A('hello');
            globalB = const B('world');
            globalC = C('hello');
            globalD = const D('world');
            print(globalA.s);
            print(globalB.s);
            print(globalC.s);
            print(globalD.s);
          }
          ''';
      final deltaSource = '''
          var globalA, globalB, globalC, globalD;

          class A {
            final String s;
            A(this.s);
          }

          class B {
            final String s;
            const B(this.s);
          }

          class C {
            final String s;
            C(this.s);
          }

          class D {
            final String s;
            D(this.s);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) = await compileComponents(
        initialSource,
        deltaSource,
      );
      expect(
        deltaInspector.compareGenerations(initial, delta),
        unorderedEquals([
          'Const class cannot become non-const: '
              "Library:'memory:///main.dart' "
              'Class: A',
          'Const class cannot become non-const: '
              "Library:'memory:///main.dart' "
              'Class: D',
        ]),
      );
    });

    test(
      'no error when removing const constructor while adding another',
      () async {
        final initialSource = '''
          var globalVariable;

          class A {
            final String s;
            const A(this.s);
          }

          main() {
            globalVariable = const A('hello');
            print(globalVariable.s);
          }
          ''';
        final deltaSource = '''
          var globalVariable;

          class A {
            final String s;
            A(this.s);
            const A.named(this.s);
          }

          main() {
            print('hello world');
          }
          ''';
        final (:initial, :delta) = await compileComponents(
          initialSource,
          deltaSource,
        );
        expect(deltaInspector.compareGenerations(initial, delta), isEmpty);
      },
    );
    test('rejection when removing a field', () async {
      final initialSource = '''
          var globalVariable;

          class A {
            final String s, t, w;
            const A(this.s, this.t, this.w);
          }

          main() {
            globalVariable = const A('hello', 'world', '!');
            print(globalVariable.s);
          }
          ''';
      final deltaSource = '''
          var globalVariable;

          class A {
            final String s, t;
            const A(this.s, this.t);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) = await compileComponents(
        initialSource,
        deltaSource,
      );
      expect(
        deltaInspector.compareGenerations(initial, delta),
        unorderedEquals([
          'Const class cannot remove fields: '
              "Library:'memory:///main.dart' Class: A",
        ]),
      );
    });
    test('rejection when removing a field while adding another', () async {
      final initialSource = '''
          var globalVariable;

          class A {
            final String s, t, w;
            const A(this.s, this.t, this.w);
          }

          main() {
            globalVariable = const A('hello', 'world', '!');
            print(globalVariable.s);
          }
          ''';
      final deltaSource = '''
          var globalVariable;

          class A {
            final String s, t, x;
            const A(this.s, this.t, this.x);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) = await compileComponents(
        initialSource,
        deltaSource,
      );
      expect(
        deltaInspector.compareGenerations(initial, delta),
        unorderedEquals([
          'Const class cannot remove fields: '
              "Library:'memory:///main.dart' Class: A",
        ]),
      );
    });
    test(
      'no error when removing field while also making class const',
      () async {
        final initialSource = '''
          var globalVariable;

          class A {
            final String s, t, w;
            A(this.s, this.t, this.w);
          }

          main() {
            globalVariable = A('hello', 'world', '!');
            print(globalVariable.s);
          }
          ''';
        final deltaSource = '''
          var globalVariable;

          class A {
            final String s, t;
            const A(this.s, this.t);
          }

          main() {
            print('hello world');
          }
          ''';
        final (:initial, :delta) = await compileComponents(
          initialSource,
          deltaSource,
        );
        expect(
          () => deltaInspector.compareGenerations(initial, delta),
          returnsNormally,
        );
      },
    );
  });
  group('deleted top level members appear in delta library metadata', () {
    final deltaInspector = HotReloadDeltaInspector();
    test('method', () async {
      final initialSource = '''
          void retainedMethod() {}

          dynamic get retainedGetter => null;

          set retainedSetter(dynamic value) {}

          void deleted() {}
          ''';
      final deltaSource = '''
          void retainedMethod() {}

          dynamic get retainedGetter => null;

          set retainedSetter(dynamic value) {}
          ''';
      final (:initial, :delta) = await compileComponents(
        initialSource,
        deltaSource,
      );
      expect(
        () => deltaInspector.compareGenerations(initial, delta),
        returnsNormally,
      );
      final repo =
          delta.metadata[hotReloadLibraryMetadataTag]
              as HotReloadLibraryMetadataRepository;
      repo.mapToIndexedNodes(LibraryIndex.all(delta));
      final metadata =
          repo.mapping[delta.libraries.firstWhere(
            (l) => l.importUri.toString() == 'memory:///main.dart',
          )]!;
      expect(metadata.deletedStaticProcedureNames, orderedEquals(['deleted']));
    });
    test('getter', () async {
      final initialSource = '''
          void retainedMethod() {}

          dynamic get retainedGetter => null;

          set retainedSetter(dynamic value) {}

          dynamic get deletedGetter => null;
          ''';
      final deltaSource = '''
          void retainedMethod() {}

          dynamic get retainedGetter => null;

          set retainedSetter(dynamic value) {}
          ''';
      final (:initial, :delta) = await compileComponents(
        initialSource,
        deltaSource,
      );
      expect(
        () => deltaInspector.compareGenerations(initial, delta),
        returnsNormally,
      );
      final repo =
          delta.metadata[hotReloadLibraryMetadataTag]
              as HotReloadLibraryMetadataRepository;
      repo.mapToIndexedNodes(LibraryIndex.all(delta));
      final metadata =
          repo.mapping[delta.libraries.firstWhere(
            (l) => l.importUri.toString() == 'memory:///main.dart',
          )]!;
      expect(
        metadata.deletedStaticProcedureNames,
        orderedEquals(['deletedGetter']),
      );
    });
    test('setter', () async {
      final initialSource = '''
          void retainedMethod() {}

          dynamic get retainedGetter => null;

          set retainedSetter(dynamic value) {}

          set deletedSetter(dynamic value) {}
          ''';
      final deltaSource = '''
          void retainedMethod() {}

          dynamic get retainedGetter => null;

          set retainedSetter(dynamic value) {}
          ''';
      final (:initial, :delta) = await compileComponents(
        initialSource,
        deltaSource,
      );
      expect(
        () => deltaInspector.compareGenerations(initial, delta),
        returnsNormally,
      );
      final repo =
          delta.metadata[hotReloadLibraryMetadataTag]
              as HotReloadLibraryMetadataRepository;
      repo.mapToIndexedNodes(LibraryIndex.all(delta));
      final metadata =
          repo.mapping[delta.libraries.firstWhere(
            (l) => l.importUri.toString() == 'memory:///main.dart',
          )]!;
      expect(
        metadata.deletedStaticProcedureNames,
        orderedEquals(['deletedSetter']),
      );
    });
  });

  group('Non-hot-reloadable packages ', () {
    final packageName = 'test_package';

    final deltaInspector = HotReloadDeltaInspector(
      nonHotReloadablePackages: {packageName},
    );
    test('reject reloads when a member is added.', () async {
      final initialAndDeltaSource =
          '''
          import 'package:$packageName/file.dart';
          main() {}
          ''';
      final initialPackageSource = 'class Foo {}';
      final deltaPackageSource = 'class Foo { int member = 100; }';
      final (:initial, :delta) = await compileComponents(
        initialAndDeltaSource,
        initialAndDeltaSource,
        initialPackageSource: initialPackageSource,
        deltaPackageSource: deltaPackageSource,
        packageName: packageName,
      );
      expect(
        deltaInspector.compareGenerations(initial, delta),
        unorderedEquals([
          'Attempting to hot reload a modified library from a package '
              'marked as non-hot-reloadable: '
              "Library: 'package:$packageName/file.dart'",
        ]),
      );
    });
    test('reject reloads when a member is removed.', () async {
      final initialAndDeltaSource =
          '''
          import 'package:$packageName/file.dart';
          main() {}
          ''';
      final initialPackageSource = 'class Foo { int member = 100; }';
      final deltaPackageSource = 'class Foo {}';
      final (:initial, :delta) = await compileComponents(
        initialAndDeltaSource,
        initialAndDeltaSource,
        initialPackageSource: initialPackageSource,
        deltaPackageSource: deltaPackageSource,
        packageName: packageName,
      );
      expect(
        deltaInspector.compareGenerations(initial, delta),
        unorderedEquals([
          'Attempting to hot reload a modified library from a package '
              'marked as non-hot-reloadable: '
              "Library: 'package:$packageName/file.dart'",
        ]),
      );
    });
    test('accept reloads when introduced but not modified.', () async {
      final initialSource = '''
          main() {}
          ''';
      final initialAndDeltaPackageSource = 'class Foo { int member = 100; }';
      final deltaSource =
          '''
          import 'package:$packageName/file.dart';
          main() {}
          ''';
      final (:initial, :delta) = await compileComponents(
        initialSource,
        deltaSource,
        initialPackageSource: initialAndDeltaPackageSource,
        deltaPackageSource: initialAndDeltaPackageSource,
        packageName: packageName,
      );
      expect(
        () => deltaInspector.compareGenerations(initial, delta),
        returnsNormally,
      );
    });
  });
}

/// Test only helper compiles [initialSource] and [deltaSource] and returns two
/// kernel components.
///
/// Auto-generates a fake package_config.json if [packageName] is provided.
/// Supports a single package named [packageName] containing a single file
/// whose source contents across one generation are [initialPackageSource] and
/// [deltaPackageSource].
Future<({Component initial, Component delta})> compileComponents(
  String initialSource,
  String deltaSource, {
  Uri? baseUri,
  String? packageName,
  String initialPackageSource = '',
  String deltaPackageSource = '',
}) async {
  baseUri ??= memoryDirectory;

  final fileName = 'main.dart';
  final packageFileName = 'lib/file.dart';
  final fileUri = Uri(scheme: baseUri.scheme, host: '', path: fileName);
  final memoryFileMap = {fileName: initialSource};

  // Generate a fake package_config.json and package.
  Uri? packageConfigUri;
  if (packageName != null) {
    packageConfigUri = baseUri.resolve('package_config.json');
    memoryFileMap['package_config.json'] = generateFakePackagesFile(
      packageName: packageName,
    );
    memoryFileMap[packageFileName] = initialPackageSource;
  }
  final initialResult = await incrementalComponentFromMemory(
    memoryFileMap,
    fileUri,
    baseUri: baseUri,
    packageConfigUri: packageConfigUri,
  );
  expect(
    initialResult.errors,
    isEmpty,
    reason: 'Initial source produced compile time errors.',
  );

  memoryFileMap[fileName] = deltaSource;
  if (packageName != null) {
    memoryFileMap[packageFileName] = initialPackageSource;
  }
  final deltaResult = await incrementalComponentFromMemory(
    memoryFileMap,
    fileUri,
    baseUri: baseUri,
    packageConfigUri: packageConfigUri,
    initialCompilerState: initialResult.initialCompilerState,
  );
  expect(
    deltaResult.errors,
    isEmpty,
    reason: 'Delta source produced compile time errors.',
  );
  return (
    initial: initialResult.ddcResult.component,
    delta: deltaResult.ddcResult.component,
  );
}

String generateFakePackagesFile({
  required String packageName,
  String rootUri = '/',
  String packageUri = 'lib/',
}) {
  return '''
{
  "configVersion": 0,
  "packages": [
    {
      "name": "$packageName",
      "rootUri": "$rootUri",
      "packageUri": "$packageUri",
      "languageVersion": "3.4"
    }
  ]
}
''';
}
