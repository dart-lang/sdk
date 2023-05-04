// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:frontend_server/src/javascript_bundle.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

/// Additional indexed types required by the dev_compiler's NativeTypeSet.
final Map<String, List<String>> additionalRequiredClasses = {
  'dart:core': ['Comparable'],
  'dart:async': [
    'StreamIterator',
    '_AsyncStarImpl',
  ],
  'dart:_interceptors': [
    'JSBool',
    'JSNumber',
    'JSArray',
    'JSString',
  ],
  'dart:_native_typed_data': [],
  'dart:collection': [
    'ListBase',
    'MapBase',
    'LinkedHashSet',
    '_HashSet',
    '_IdentityHashSet',
  ],
  'dart:math': ['Rectangle'],
  'dart:html': [],
  'dart:indexed_db': [],
  'dart:svg': [],
  'dart:web_audio': [],
  'dart:web_gl': [],
  'dart:_js_helper': [
    'PrivateSymbol',
    'LinkedMap',
    'IdentityMap',
    'SyncIterable',
  ],
};

/// Additional indexed top level methods required by the dev_compiler.
final Map<String, List<String>> requiredMethods = {
  'dart:_runtime': ['assertInterop'],
};

void main() {
  final allRequiredTypes =
      _combineMaps(CoreTypes.requiredClasses, additionalRequiredClasses);
  final allRequiredLibraries = {
    ...allRequiredTypes.keys,
    ...requiredMethods.keys
  };
  final testCoreLibraries = [
    for (String requiredLibrary in allRequiredLibraries)
      Library(Uri.parse(requiredLibrary),
          fileUri: Uri.parse(requiredLibrary),
          classes: [
            for (String requiredClass
                in allRequiredTypes[requiredLibrary] ?? [])
              Class(name: requiredClass, fileUri: Uri.parse(requiredLibrary)),
          ],
          procedures: [
            for (var requiredMethod in requiredMethods[requiredLibrary] ?? [])
              Procedure(Name(requiredMethod), ProcedureKind.Method,
                  FunctionNode(EmptyStatement()),
                  fileUri: Uri.parse(requiredLibrary)),
          ]),
  ];

  final packageConfig = PackageConfig.parseJson({
    'configVersion': 2,
    'packages': [
      {
        'name': 'a',
        'rootUri': 'file:///pkg/a',
        'packageUri': 'lib/',
      }
    ],
  }, Uri.base);
  final multiRootScheme = 'org-dartlang-app';

  for (final debuggerNames in [true, false]) {
    group('Debugger module names: $debuggerNames |', () {
      test('Creates module uris for file paths', () async {
        final fileUri = Uri.file('/c.dart');

        final javaScriptBundler = IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        final moduleUrl =
            javaScriptBundler.urlForComponentUri(fileUri, packageConfig);
        final moduleName = javaScriptBundler.makeModuleName(moduleUrl);
        expect(moduleUrl, '/c.dart');
        expect(moduleName, 'c.dart');
      });

      test('Creates module uris for package paths', () async {
        final packageUri = Uri.parse('package:a/a.dart');

        final javaScriptBundler = IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        final moduleUrl =
            javaScriptBundler.urlForComponentUri(packageUri, packageConfig);
        final moduleName = javaScriptBundler.makeModuleName(moduleUrl);
        expect(moduleUrl,
            debuggerNames ? 'packages/a/lib/a.dart' : '/packages/a/a.dart');
        expect(moduleName,
            debuggerNames ? 'packages/a/lib/a.dart' : 'packages/a/a.dart');
      });

      test('compiles JavaScript code', () async {
        final uri = Uri.file('/c.dart');
        final library = Library(
          uri,
          fileUri: uri,
          procedures: [
            Procedure(Name('ArbitrarilyChosen'), ProcedureKind.Method,
                FunctionNode(Block([])),
                fileUri: uri)
          ],
        );
        final testComponent =
            Component(libraries: [library, ...testCoreLibraries]);
        final javaScriptBundler = IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        await javaScriptBundler.initialize(testComponent, uri, packageConfig);

        final manifestSink = _MemorySink();
        final codeSink = _MemorySink();
        final sourcemapSink = _MemorySink();
        final metadataSink = _MemorySink();
        final symbolsSink = _MemorySink();
        final coreTypes = CoreTypes(testComponent);

        final compilers = await javaScriptBundler.compile(
          ClassHierarchy(testComponent, coreTypes),
          coreTypes,
          packageConfig,
          codeSink,
          manifestSink,
          sourcemapSink,
          metadataSink,
          symbolsSink,
        );

        final Map manifest = json.decode(utf8.decode(manifestSink.buffer));
        final String code = utf8.decode(codeSink.buffer);

        expect(manifest, {
          '/c.dart.lib.js': {
            'code': [0, codeSink.buffer.length],
            'sourcemap': [0, sourcemapSink.buffer.length],
          },
        });
        expect(code, contains('ArbitrarilyChosen'));

        // Verify source map url is correct.
        expect(code, contains('sourceMappingURL=c.dart.lib.js.map'));

        // Verify program compilers are created.
        final moduleUrl = javaScriptBundler.urlForComponentUri(
            library.importUri, packageConfig);
        final moduleName = javaScriptBundler.makeModuleName(moduleUrl);
        expect(compilers.keys, equals([moduleName]));
      });

      test('converts package: uris into /packages/ uris', () async {
        var importUri = Uri.parse('package:a/a.dart');
        var fileUri = packageConfig.resolve(importUri)!;
        final library = Library(
          importUri,
          fileUri: fileUri,
          procedures: [
            Procedure(Name('ArbitrarilyChosen'), ProcedureKind.Method,
                FunctionNode(Block([])),
                fileUri: fileUri)
          ],
        );

        final testComponent =
            Component(libraries: [library, ...testCoreLibraries]);

        final javaScriptBundler = IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        await javaScriptBundler.initialize(
            testComponent, importUri, packageConfig);

        final manifestSink = _MemorySink();
        final codeSink = _MemorySink();
        final sourcemapSink = _MemorySink();
        final metadataSink = _MemorySink();
        final symbolsSink = _MemorySink();
        final coreTypes = CoreTypes(testComponent);

        await javaScriptBundler.compile(
          ClassHierarchy(testComponent, coreTypes),
          coreTypes,
          packageConfig,
          codeSink,
          manifestSink,
          sourcemapSink,
          metadataSink,
          symbolsSink,
        );

        final Map manifest = json.decode(utf8.decode(manifestSink.buffer));
        final String code = utf8.decode(codeSink.buffer);

        final moduleUrl = javaScriptBundler.urlForComponentUri(
            library.importUri, packageConfig);

        expect(manifest, {
          '$moduleUrl.lib.js': {
            'code': [0, codeSink.buffer.length],
            'sourcemap': [0, sourcemapSink.buffer.length],
          },
        });
        expect(code, contains('ArbitrarilyChosen'));

        // Verify source map url is correct.
        expect(code, contains('sourceMappingURL=a.dart.lib.js.map'));
      });

      test('multi-root uris create modules relative to the root', () async {
        var importUri = Uri.parse('$multiRootScheme:/web/main.dart');
        var fileUri = importUri;
        final library = Library(
          importUri,
          fileUri: fileUri,
          procedures: [
            Procedure(Name('ArbitrarilyChosen'), ProcedureKind.Method,
                FunctionNode(Block([])),
                fileUri: fileUri)
          ],
        );

        final testComponent =
            Component(libraries: [library, ...testCoreLibraries]);

        final javaScriptBundler = IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        await javaScriptBundler.initialize(
            testComponent, importUri, packageConfig);

        final manifestSink = _MemorySink();
        final codeSink = _MemorySink();
        final sourcemapSink = _MemorySink();
        final metadataSink = _MemorySink();
        final symbolsSink = _MemorySink();
        final coreTypes = CoreTypes(testComponent);

        await javaScriptBundler.compile(
          ClassHierarchy(testComponent, coreTypes),
          coreTypes,
          packageConfig,
          codeSink,
          manifestSink,
          sourcemapSink,
          metadataSink,
          symbolsSink,
        );

        final Map manifest = json.decode(utf8.decode(manifestSink.buffer));
        final String code = utf8.decode(codeSink.buffer);

        expect(manifest, {
          '${importUri.path}.lib.js': {
            'code': [0, codeSink.buffer.length],
            'sourcemap': [0, sourcemapSink.buffer.length],
          },
        });
        expect(code, contains('ArbitrarilyChosen'));

        // Verify source map url is correct.
        expect(code, contains('sourceMappingURL=main.dart.lib.js.map'));
      });
    });
  }

  test('can combine strongly connected components', () async {
    // Create three libraries A, B, C where A is the entrypoint and B & C
    // circularly import each other.
    final libraryC = Library(Uri.file('/c.dart'), fileUri: Uri.file('/c.dart'));
    final libraryB = Library(Uri.file('/b.dart'), fileUri: Uri.file('/b.dart'));
    libraryC.dependencies.add(LibraryDependency.import(libraryB));
    libraryB.dependencies.add(LibraryDependency.import(libraryC));
    final uriA = Uri.file('/a.dart');
    final libraryA = Library(
      uriA,
      fileUri: uriA,
      dependencies: [
        LibraryDependency.import(libraryB),
      ],
      procedures: [
        Procedure(Name('ArbitrarilyChosen'), ProcedureKind.Method,
            FunctionNode(Block([])),
            fileUri: uriA)
      ],
    );
    final testComponent = Component(
        libraries: [libraryA, libraryB, libraryC, ...testCoreLibraries]);

    final javaScriptBundler = IncrementalJavaScriptBundler(
      null,
      {},
      multiRootScheme,
    );

    await javaScriptBundler.initialize(testComponent, uriA, packageConfig);

    final manifestSink = _MemorySink();
    final codeSink = _MemorySink();
    final sourcemapSink = _MemorySink();
    final metadataSink = _MemorySink();
    final symbolsSink = _MemorySink();
    final coreTypes = CoreTypes(testComponent);

    await javaScriptBundler.compile(
      ClassHierarchy(testComponent, coreTypes),
      coreTypes,
      packageConfig,
      codeSink,
      manifestSink,
      sourcemapSink,
      metadataSink,
      symbolsSink,
    );

    final code = utf8.decode(codeSink.buffer);
    final manifest = json.decode(utf8.decode(manifestSink.buffer));

    // There should only be two modules since C and B should be combined.
    final moduleHeader = r"define(['dart_sdk'], (function load__";
    expect(moduleHeader.allMatches(code), hasLength(2));

    // Expected module headers.
    final aModuleHeader =
        r"define(['dart_sdk'], (function load__a_dart(dart_sdk) {";
    expect(code, contains(aModuleHeader));
    final cModuleHeader =
        r"define(['dart_sdk'], (function load__c_dart(dart_sdk) {";
    expect(code, contains(cModuleHeader));

    // Verify source map url is correct.
    expect(code, contains('sourceMappingURL=a.dart.lib.js.map'));

    final offsets = manifest['/a.dart.lib.js']['sourcemap'];
    final sourcemapModuleA = json.decode(
        utf8.decode(sourcemapSink.buffer.sublist(offsets.first, offsets.last)));

    // Verify source maps are pointing at correct source files.
    expect(sourcemapModuleA['file'], 'a.dart.lib.js');
  });

  test('can invalidate changes to strongly connected components', () async {
    final uriA = Uri.file('/a.dart');
    final uriB = Uri.file('/b.dart');
    final uriC = Uri.file('/c.dart');

    // Create three libraries A, B, C where A is the entrypoint and B & C
    // circularly import each other.
    final libraryC = Library(uriC, fileUri: uriC);
    final libraryB = Library(uriB, fileUri: uriB);
    libraryC.dependencies.add(LibraryDependency.import(libraryB));
    libraryB.dependencies.add(LibraryDependency.import(libraryC));
    final libraryA = Library(
      uriA,
      fileUri: uriA,
      dependencies: [
        LibraryDependency.import(libraryB),
      ],
      procedures: [
        Procedure(Name('ArbitrarilyChosen'), ProcedureKind.Method,
            FunctionNode(Block([])),
            fileUri: uriA)
      ],
    );
    final testComponent = Component(
        libraries: [libraryA, libraryB, libraryC, ...testCoreLibraries]);

    final javaScriptBundler = IncrementalJavaScriptBundler(
      null,
      {},
      multiRootScheme,
    );

    await javaScriptBundler.initialize(testComponent, uriA, packageConfig);

    // Now change A and B so that they no longer import each other.
    final libraryC2 = Library(uriC, fileUri: uriC);
    final libraryB2 = Library(uriB, fileUri: uriB);
    libraryB2.dependencies.add(LibraryDependency.import(libraryC2));
    final libraryA2 = Library(
      uriA,
      fileUri: uriA,
      dependencies: [
        LibraryDependency.import(libraryB2),
      ],
      procedures: [
        Procedure(Name('ArbitrarilyChosen'), ProcedureKind.Method,
            FunctionNode(Block([])),
            fileUri: uriA)
      ],
    );
    final partialComponent =
        Component(libraries: [libraryA2, libraryB2, libraryC2]);

    await javaScriptBundler.invalidate(
        partialComponent, testComponent, uriA, packageConfig);

    final manifestSink = _MemorySink();
    final codeSink = _MemorySink();
    final sourcemapSink = _MemorySink();
    final metadataSink = _MemorySink();
    final symbolsSink = _MemorySink();
    final coreTypes = CoreTypes(testComponent);

    await javaScriptBundler.compile(
      ClassHierarchy(testComponent, coreTypes),
      coreTypes,
      packageConfig,
      codeSink,
      manifestSink,
      sourcemapSink,
      metadataSink,
      symbolsSink,
    );

    final code = utf8.decode(codeSink.buffer);
    final manifest = json.decode(utf8.decode(manifestSink.buffer));

    // There should be 3 modules since A, B, C are now compiled separately
    final moduleHeader = r"define(['dart_sdk'], (function load__";
    expect(moduleHeader.allMatches(code), hasLength(3));

    // Expected module headers.
    final aModuleHeader =
        r"define(['dart_sdk'], (function load__a_dart(dart_sdk) {";
    expect(code, contains(aModuleHeader));
    final bModuleHeader =
        r"define(['dart_sdk'], (function load__b_dart(dart_sdk) {";
    expect(code, contains(bModuleHeader));
    final cModuleHeader =
        r"define(['dart_sdk'], (function load__c_dart(dart_sdk) {";
    expect(code, contains(cModuleHeader));
    // Verify source map url is correct.
    expect(code, contains('sourceMappingURL=a.dart.lib.js.map'));

    final offsets = manifest['/a.dart.lib.js']['sourcemap'];
    final sourcemapModuleA = json.decode(
        utf8.decode(sourcemapSink.buffer.sublist(offsets.first, offsets.last)));

    // Verify source maps are pointing at correct source files.
    expect(sourcemapModuleA['file'], 'a.dart.lib.js');
  });

  test('can compile using the advanced invalidation', () async {
    final uriC = Uri.file('/c.dart');
    // Given 3 libraries A -> B -> C
    final libraryC = Library(
      uriC,
      fileUri: uriC,
      procedures: [
        Procedure(Name('CheckForContents'), ProcedureKind.Method,
            FunctionNode(Block([])),
            fileUri: uriC)
      ],
    );
    final uriB = Uri.file('/b.dart');
    final libraryB = Library(uriB, fileUri: uriB);
    libraryB.dependencies.add(LibraryDependency.import(libraryC));
    final uriA = Uri.file('/a.dart');
    final libraryA = Library(
      uriA,
      fileUri: uriA,
      dependencies: [
        LibraryDependency.import(libraryB),
      ],
      procedures: [
        Procedure(Name('ArbitrarilyChosen'), ProcedureKind.Method,
            FunctionNode(Block([])),
            fileUri: uriA)
      ],
    );
    final testComponent = Component(
        libraries: [libraryA, libraryB, libraryC, ...testCoreLibraries]);

    final javaScriptBundler = IncrementalJavaScriptBundler(
      null,
      {},
      multiRootScheme,
    );

    await javaScriptBundler.initialize(testComponent, uriA, packageConfig);

    // Create a new component that only contains C.
    final libraryC2 = Library(
      uriC,
      fileUri: uriC,
      procedures: [
        Procedure(Name('AlternativeContents'), ProcedureKind.Method,
            FunctionNode(Block([])),
            fileUri: uriC)
      ],
    );

    final partialComponent = Component(libraries: [libraryC2]);

    await javaScriptBundler.invalidate(
        partialComponent, testComponent, uriA, packageConfig);

    final manifestSink = _MemorySink();
    final codeSink = _MemorySink();
    final sourcemapSink = _MemorySink();
    final metadataSink = _MemorySink();
    final symbolsSink = _MemorySink();
    final coreTypes = CoreTypes(testComponent);

    await javaScriptBundler.compile(
      ClassHierarchy(testComponent, coreTypes),
      coreTypes,
      packageConfig,
      codeSink,
      manifestSink,
      sourcemapSink,
      metadataSink,
      symbolsSink,
    );

    final code = utf8.decode(codeSink.buffer);

    // There should be only a single module.
    final moduleHeader = r"define(['dart_sdk'], (function load__";
    expect(moduleHeader.allMatches(code), hasLength(1));

    // C source code should be updated.
    expect(code, contains('AlternativeContents'));
  });
}

class _MemorySink implements IOSink {
  final List<int> buffer = <int>[];

  @override
  void add(List<int> data) {
    buffer.addAll(data);
  }

  @override
  Future<void> close() => Future.value();

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnsupportedError(invocation.memberName.toString());
  }
}

Map<String, List<String>> _combineMaps(
  Map<String, List<String>> left,
  Map<String, List<String>> right,
) {
  final result = Map<String, List<String>>.from(left);
  for (String key in right.keys) {
    (result[key] ??= []).addAll(right[key]!);
  }
  return result;
}
