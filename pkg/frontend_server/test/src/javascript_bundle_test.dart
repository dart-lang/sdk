// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dev_compiler/dev_compiler.dart' show Compiler;
import 'package:frontend_server/src/javascript_bundle.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

/// Additional indexed types required by the dev_compiler's NativeTypeSet.
final Map<String, Map<String, List<String>>> additionalRequiredClasses = {
  'dart:core': {'Comparable': []},
  'dart:async': {
    'StreamIterator': ['get:current', 'moveNext', 'cancel', ''],
    '_SyncStarIterator': ['_current', '_datum', '_yieldStar'],
    '_IterationMarker': ['yieldSingle', 'yieldStar'],
  },
  'dart:_interceptors': {
    'JSBool': [],
    'JSNumber': [],
    'JSArray': [],
    'JSString': [],
    'LegacyJavaScriptObject': [],
  },
  'dart:_native_typed_data': {},
  'dart:collection': {
    'ListBase': [],
    'MapBase': [],
    'LinkedHashSet': [],
    '_HashSet': [],
    '_IdentityHashSet': [],
  },
  'dart:math': {'Rectangle': []},
  'dart:html': {},
  'dart:_rti': {'Rti': [], '_Universe': []},
  'dart:indexed_db': {},
  'dart:svg': {},
  'dart:web_audio': {},
  'dart:web_gl': {},
  'dart:_js_helper': {
    'PrivateSymbol': [],
    'LinkedMap': [],
    'IdentityMap': [],
    'LinkedSet': [],
    'IdentitySet': [],
    'SyncIterable': [],
  },
};

/// Additional indexed top level methods required by the dev_compiler.
final Map<String, List<String>> requiredTopLevels = {
  'dart:_runtime': ['assertInterop'],
  'dart:async': [
    '_asyncAwait',
    '_asyncReturn',
    '_asyncRethrow',
    '_asyncStarHelper',
    '_asyncStartSync',
    '_makeAsyncAwaitCompleter',
    '_makeSyncStarIterable',
    '_makeAsyncStarStreamController',
    '_makeSyncStarIterable',
    '_streamOfController',
    '_wrapJsFunctionForAsync',
  ],
};

void main() {
  Map<String, List<String>> allRequiredTypes = _combineMaps(
      CoreTypes.requiredClasses,
      additionalRequiredClasses
          .map((k, v) => new MapEntry(k, v.keys.toList())));
  List<String> allRequiredLibraries = [
    ...allRequiredTypes.keys,
    ...requiredTopLevels.keys,
  ];
  List<Library> testCoreLibraries = [];
  for (String requiredLibrary in allRequiredLibraries) {
    Library library = new Library(Uri.parse(requiredLibrary),
        fileUri: Uri.parse(requiredLibrary));
    for (String requiredClass in allRequiredTypes[requiredLibrary] ?? []) {
      library.addClass(new Class(
          name: requiredClass,
          fileUri: Uri.parse(requiredLibrary),
          procedures: [
            for (String requiredMember
                in (additionalRequiredClasses[requiredLibrary]
                        ?[requiredClass] ??
                    []))
              new Procedure(new Name(requiredMember, library),
                  ProcedureKind.Method, new FunctionNode(new EmptyStatement()),
                  fileUri: Uri.parse(requiredLibrary))
          ]));
    }
    for (String requiredMember in requiredTopLevels[requiredLibrary] ?? []) {
      library.addProcedure(new Procedure(new Name(requiredMember, library),
          ProcedureKind.Method, new FunctionNode(new EmptyStatement()),
          fileUri: Uri.parse(requiredLibrary)));
    }
    testCoreLibraries.add(library);
  }

  final PackageConfig packageConfig = PackageConfig.parseJson({
    'configVersion': 2,
    'packages': [
      {
        'name': 'a',
        'rootUri': 'file:///pkg/a',
        'packageUri': 'lib/',
      }
    ],
  }, Uri.base);
  final String multiRootScheme = 'org-dartlang-app';

  for (final bool debuggerNames in [true, false]) {
    group('Debugger module names: $debuggerNames |', () {
      test('Creates module uris for file paths', () async {
        final Uri fileUri = new Uri.file('/c.dart');

        final IncrementalJavaScriptBundler javaScriptBundler =
            new IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        final String moduleUrl =
            javaScriptBundler.urlForComponentUri(fileUri, packageConfig);
        final String moduleName = javaScriptBundler.makeModuleName(moduleUrl);
        expect(moduleUrl, '/c.dart');
        expect(moduleName, 'c.dart');
      });

      test('Creates module uris for package paths', () async {
        final Uri packageUri = Uri.parse('package:a/a.dart');

        final IncrementalJavaScriptBundler javaScriptBundler =
            new IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        final String moduleUrl =
            javaScriptBundler.urlForComponentUri(packageUri, packageConfig);
        final String moduleName = javaScriptBundler.makeModuleName(moduleUrl);
        expect(moduleUrl,
            debuggerNames ? 'packages/a/lib/a.dart' : '/packages/a/a.dart');
        expect(moduleName,
            debuggerNames ? 'packages/a/lib/a.dart' : 'packages/a/a.dart');
      });

      test('compiles JavaScript code', () async {
        final Uri uri = new Uri.file('/c.dart');
        final Library library = new Library(
          uri,
          fileUri: uri,
          procedures: [
            new Procedure(new Name('ArbitrarilyChosen'), ProcedureKind.Method,
                new FunctionNode(new Block([])),
                fileUri: uri)
          ],
        );
        final Component testComponent =
            new Component(libraries: [library, ...testCoreLibraries]);
        final IncrementalJavaScriptBundler javaScriptBundler =
            new IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        await javaScriptBundler.initialize(testComponent, uri, packageConfig);

        final _MemorySink manifestSink = new _MemorySink();
        final _MemorySink codeSink = new _MemorySink();
        final _MemorySink sourcemapSink = new _MemorySink();
        final _MemorySink metadataSink = new _MemorySink();
        final _MemorySink symbolsSink = new _MemorySink();
        final CoreTypes coreTypes = new CoreTypes(testComponent);

        final Map<String, Compiler> compilers = await javaScriptBundler.compile(
          new ClassHierarchy(testComponent, coreTypes),
          coreTypes,
          packageConfig,
          codeSink,
          manifestSink,
          sourcemapSink,
          metadataSink,
          symbolsSink,
        );

        final Map<String, dynamic> manifest =
            json.decode(utf8.decode(manifestSink.buffer));
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
        expect(compilers.keys, equals([library.importUri.toString()]));
      });

      test('converts package: uris into /packages/ uris', () async {
        Uri importUri = Uri.parse('package:a/a.dart');
        Uri fileUri = packageConfig.resolve(importUri)!;
        final Library library = new Library(
          importUri,
          fileUri: fileUri,
          procedures: [
            new Procedure(new Name('ArbitrarilyChosen'), ProcedureKind.Method,
                new FunctionNode(new Block([])),
                fileUri: fileUri)
          ],
        );

        final Component testComponent =
            new Component(libraries: [library, ...testCoreLibraries]);

        final IncrementalJavaScriptBundler javaScriptBundler =
            new IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        await javaScriptBundler.initialize(
            testComponent, importUri, packageConfig);

        final _MemorySink manifestSink = new _MemorySink();
        final _MemorySink codeSink = new _MemorySink();
        final _MemorySink sourcemapSink = new _MemorySink();
        final _MemorySink metadataSink = new _MemorySink();
        final _MemorySink symbolsSink = new _MemorySink();
        final CoreTypes coreTypes = new CoreTypes(testComponent);

        await javaScriptBundler.compile(
          new ClassHierarchy(testComponent, coreTypes),
          coreTypes,
          packageConfig,
          codeSink,
          manifestSink,
          sourcemapSink,
          metadataSink,
          symbolsSink,
        );

        final Map<String, dynamic> manifest =
            json.decode(utf8.decode(manifestSink.buffer));
        final String code = utf8.decode(codeSink.buffer);

        final String moduleUrl = javaScriptBundler.urlForComponentUri(
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
        Uri importUri = Uri.parse('$multiRootScheme:/web/main.dart');
        Uri fileUri = importUri;
        final Library library = new Library(
          importUri,
          fileUri: fileUri,
          procedures: [
            new Procedure(new Name('ArbitrarilyChosen'), ProcedureKind.Method,
                new FunctionNode(new Block([])),
                fileUri: fileUri)
          ],
        );

        final Component testComponent =
            new Component(libraries: [library, ...testCoreLibraries]);

        final IncrementalJavaScriptBundler javaScriptBundler =
            new IncrementalJavaScriptBundler(
          null,
          {},
          multiRootScheme,
          useDebuggerModuleNames: debuggerNames,
        );

        await javaScriptBundler.initialize(
            testComponent, importUri, packageConfig);

        final _MemorySink manifestSink = new _MemorySink();
        final _MemorySink codeSink = new _MemorySink();
        final _MemorySink sourcemapSink = new _MemorySink();
        final _MemorySink metadataSink = new _MemorySink();
        final _MemorySink symbolsSink = new _MemorySink();
        final CoreTypes coreTypes = new CoreTypes(testComponent);

        await javaScriptBundler.compile(
          new ClassHierarchy(testComponent, coreTypes),
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
    final Library libraryC =
        new Library(new Uri.file('/c.dart'), fileUri: new Uri.file('/c.dart'));
    final Library libraryB =
        new Library(new Uri.file('/b.dart'), fileUri: new Uri.file('/b.dart'));
    libraryC.dependencies.add(new LibraryDependency.import(libraryB));
    libraryB.dependencies.add(new LibraryDependency.import(libraryC));
    final Uri uriA = new Uri.file('/a.dart');
    final Library libraryA = new Library(
      uriA,
      fileUri: uriA,
      dependencies: [
        new LibraryDependency.import(libraryB),
      ],
      procedures: [
        new Procedure(new Name('ArbitrarilyChosen'), ProcedureKind.Method,
            new FunctionNode(new Block([])),
            fileUri: uriA)
      ],
    );
    final Component testComponent = new Component(
        libraries: [libraryA, libraryB, libraryC, ...testCoreLibraries]);

    final IncrementalJavaScriptBundler javaScriptBundler =
        new IncrementalJavaScriptBundler(
      null,
      {},
      multiRootScheme,
    );

    await javaScriptBundler.initialize(testComponent, uriA, packageConfig);

    final _MemorySink manifestSink = new _MemorySink();
    final _MemorySink codeSink = new _MemorySink();
    final _MemorySink sourcemapSink = new _MemorySink();
    final _MemorySink metadataSink = new _MemorySink();
    final _MemorySink symbolsSink = new _MemorySink();
    final CoreTypes coreTypes = new CoreTypes(testComponent);

    await javaScriptBundler.compile(
      new ClassHierarchy(testComponent, coreTypes),
      coreTypes,
      packageConfig,
      codeSink,
      manifestSink,
      sourcemapSink,
      metadataSink,
      symbolsSink,
    );

    final String code = utf8.decode(codeSink.buffer);
    final Map<String, dynamic> manifest =
        json.decode(utf8.decode(manifestSink.buffer));

    // There should only be two modules since C and B should be combined.
    final String moduleHeader = r"define(['dart_sdk'], (function load__";
    expect(moduleHeader.allMatches(code), hasLength(2));

    // Expected module headers.
    final String aModuleHeader =
        r"define(['dart_sdk'], (function load__a_dart(dart_sdk) {";
    expect(code, contains(aModuleHeader));
    final String cModuleHeader =
        r"define(['dart_sdk'], (function load__c_dart(dart_sdk) {";
    expect(code, contains(cModuleHeader));

    // Verify source map url is correct.
    expect(code, contains('sourceMappingURL=a.dart.lib.js.map'));

    final List<dynamic> offsets = manifest['/a.dart.lib.js']['sourcemap'];
    final Map<String, dynamic> sourcemapModuleA = json.decode(
        utf8.decode(sourcemapSink.buffer.sublist(offsets.first, offsets.last)));

    // Verify source maps are pointing at correct source files.
    expect(sourcemapModuleA['file'], 'a.dart.lib.js');
  });

  test('can invalidate changes to strongly connected components', () async {
    final Uri uriA = new Uri.file('/a.dart');
    final Uri uriB = new Uri.file('/b.dart');
    final Uri uriC = new Uri.file('/c.dart');

    // Create three libraries A, B, C where A is the entrypoint and B & C
    // circularly import each other.
    final Library libraryC = new Library(uriC, fileUri: uriC);
    final Library libraryB = new Library(uriB, fileUri: uriB);
    libraryC.dependencies.add(new LibraryDependency.import(libraryB));
    libraryB.dependencies.add(new LibraryDependency.import(libraryC));
    final Library libraryA = new Library(
      uriA,
      fileUri: uriA,
      dependencies: [
        new LibraryDependency.import(libraryB),
      ],
      procedures: [
        new Procedure(new Name('ArbitrarilyChosen'), ProcedureKind.Method,
            new FunctionNode(new Block([])),
            fileUri: uriA)
      ],
    );
    final Component testComponent = new Component(
        libraries: [libraryA, libraryB, libraryC, ...testCoreLibraries]);

    final IncrementalJavaScriptBundler javaScriptBundler =
        new IncrementalJavaScriptBundler(
      null,
      {},
      multiRootScheme,
    );

    await javaScriptBundler.initialize(testComponent, uriA, packageConfig);

    // Now change A and B so that they no longer import each other.
    final Library libraryC2 = new Library(uriC, fileUri: uriC);
    final Library libraryB2 = new Library(uriB, fileUri: uriB);
    libraryB2.dependencies.add(new LibraryDependency.import(libraryC2));
    final Library libraryA2 = new Library(
      uriA,
      fileUri: uriA,
      dependencies: [
        new LibraryDependency.import(libraryB2),
      ],
      procedures: [
        new Procedure(new Name('ArbitrarilyChosen'), ProcedureKind.Method,
            new FunctionNode(new Block([])),
            fileUri: uriA)
      ],
    );
    final Component partialComponent =
        new Component(libraries: [libraryA2, libraryB2, libraryC2]);

    await javaScriptBundler.invalidate(
        partialComponent, testComponent, uriA, packageConfig);

    final _MemorySink manifestSink = new _MemorySink();
    final _MemorySink codeSink = new _MemorySink();
    final _MemorySink sourcemapSink = new _MemorySink();
    final _MemorySink metadataSink = new _MemorySink();
    final _MemorySink symbolsSink = new _MemorySink();
    final CoreTypes coreTypes = new CoreTypes(testComponent);

    await javaScriptBundler.compile(
      new ClassHierarchy(testComponent, coreTypes),
      coreTypes,
      packageConfig,
      codeSink,
      manifestSink,
      sourcemapSink,
      metadataSink,
      symbolsSink,
    );

    final String code = utf8.decode(codeSink.buffer);
    final Map<String, dynamic> manifest =
        json.decode(utf8.decode(manifestSink.buffer));

    // There should be 3 modules since A, B, C are now compiled separately
    final String moduleHeader = r"define(['dart_sdk'], (function load__";
    expect(moduleHeader.allMatches(code), hasLength(3));

    // Expected module headers.
    final String aModuleHeader =
        r"define(['dart_sdk'], (function load__a_dart(dart_sdk) {";
    expect(code, contains(aModuleHeader));
    final String bModuleHeader =
        r"define(['dart_sdk'], (function load__b_dart(dart_sdk) {";
    expect(code, contains(bModuleHeader));
    final String cModuleHeader =
        r"define(['dart_sdk'], (function load__c_dart(dart_sdk) {";
    expect(code, contains(cModuleHeader));
    // Verify source map url is correct.
    expect(code, contains('sourceMappingURL=a.dart.lib.js.map'));

    final List<dynamic> offsets = manifest['/a.dart.lib.js']['sourcemap'];
    final Map<String, dynamic> sourcemapModuleA = json.decode(
        utf8.decode(sourcemapSink.buffer.sublist(offsets.first, offsets.last)));

    // Verify source maps are pointing at correct source files.
    expect(sourcemapModuleA['file'], 'a.dart.lib.js');
  });

  test('can compile using the advanced invalidation', () async {
    final Uri uriC = new Uri.file('/c.dart');
    // Given 3 libraries A -> B -> C
    final Library libraryC = new Library(
      uriC,
      fileUri: uriC,
      procedures: [
        new Procedure(new Name('CheckForContents'), ProcedureKind.Method,
            new FunctionNode(new Block([])),
            fileUri: uriC)
      ],
    );
    final Uri uriB = new Uri.file('/b.dart');
    final Library libraryB = new Library(uriB, fileUri: uriB);
    libraryB.dependencies.add(new LibraryDependency.import(libraryC));
    final Uri uriA = new Uri.file('/a.dart');
    final Library libraryA = new Library(
      uriA,
      fileUri: uriA,
      dependencies: [
        new LibraryDependency.import(libraryB),
      ],
      procedures: [
        new Procedure(new Name('ArbitrarilyChosen'), ProcedureKind.Method,
            new FunctionNode(new Block([])),
            fileUri: uriA)
      ],
    );
    final Component testComponent = new Component(
        libraries: [libraryA, libraryB, libraryC, ...testCoreLibraries]);

    final IncrementalJavaScriptBundler javaScriptBundler =
        new IncrementalJavaScriptBundler(
      null,
      {},
      multiRootScheme,
    );

    await javaScriptBundler.initialize(testComponent, uriA, packageConfig);

    // Create a new component that only contains C.
    final Library libraryC2 = new Library(
      uriC,
      fileUri: uriC,
      procedures: [
        new Procedure(new Name('AlternativeContents'), ProcedureKind.Method,
            new FunctionNode(new Block([])),
            fileUri: uriC)
      ],
    );

    final Component partialComponent = new Component(libraries: [libraryC2]);

    await javaScriptBundler.invalidate(
        partialComponent, testComponent, uriA, packageConfig);

    final _MemorySink manifestSink = new _MemorySink();
    final _MemorySink codeSink = new _MemorySink();
    final _MemorySink sourcemapSink = new _MemorySink();
    final _MemorySink metadataSink = new _MemorySink();
    final _MemorySink symbolsSink = new _MemorySink();
    final CoreTypes coreTypes = new CoreTypes(testComponent);

    await javaScriptBundler.compile(
      new ClassHierarchy(testComponent, coreTypes),
      coreTypes,
      packageConfig,
      codeSink,
      manifestSink,
      sourcemapSink,
      metadataSink,
      symbolsSink,
    );

    final String code = utf8.decode(codeSink.buffer);

    // There should be only a single module.
    final String moduleHeader = r"define(['dart_sdk'], (function load__";
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
  Future<void> close() => new Future.value();

  @override
  void noSuchMethod(Invocation invocation) {
    throw new UnsupportedError(invocation.memberName.toString());
  }
}

Map<String, List<String>> _combineMaps(
  Map<String, List<String>> left,
  Map<String, List<String>> right,
) {
  final Map<String, List<String>> result =
      new Map<String, List<String>>.of(left);
  for (String key in right.keys) {
    (result[key] ??= []).addAll(right[key]!);
  }
  return result;
}
