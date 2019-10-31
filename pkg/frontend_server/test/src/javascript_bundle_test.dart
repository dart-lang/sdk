// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:frontend_server/src/javascript_bundle.dart';
import 'package:frontend_server/src/strong_components.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
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
    'ListMixin',
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
  'dart:web_sql': [],
  'dart:_js_helper': [
    'PrivateSymbol',
    'LinkedMap',
    'IdentityMap',
    'SyncIterable',
  ],
};

void main() {
  final allRequiredTypes =
      _combineMaps(CoreTypes.requiredClasses, additionalRequiredClasses);
  final testCoreLibraries = [
    for (String requiredLibrary in allRequiredTypes.keys)
      Library(Uri.parse(requiredLibrary), classes: [
        for (String requiredClass in allRequiredTypes[requiredLibrary])
          Class(name: requiredClass),
      ]),
  ];

  test('compiles JavaScript code', () async {
    final library = Library(
      Uri.file('/c.dart'),
      fileUri: Uri.file('/c.dart'),
      procedures: [
        Procedure(Name('ArbitrarilyChosen'), ProcedureKind.Method,
            FunctionNode(Block([])))
      ],
    );
    final testComponent = Component(libraries: [library, ...testCoreLibraries]);
    final strongComponents =
        StrongComponents(testComponent, Uri.file('/c.dart'));
    strongComponents.computeModules();
    final javaScriptBundler =
        JavaScriptBundler(testComponent, strongComponents);
    final manifestSink = _MemorySink();
    final codeSink = _MemorySink();
    final sourcemapSink = _MemorySink();

    javaScriptBundler.compile(ClassHierarchy(testComponent),
        CoreTypes(testComponent), codeSink, manifestSink, sourcemapSink);

    final Map manifest = json.decode(utf8.decode(manifestSink.buffer));
    final String code = utf8.decode(codeSink.buffer);

    expect(manifest, {
      '/c.dart.js': {
        'code': [0, codeSink.buffer.length],
        'sourcemap': [0, sourcemapSink.buffer.length],
      },
    });
    expect(code, contains('ArbitrarilyChosen'));

    // verify source map url is correct.
    expect(code, contains('sourceMappingURL=c.dart.js.map'));
  });

  test('can combine strongly connected components', () {
    // Create three libraries A, B, C where A is the entrypoint and B & C
    // circularly import each other.
    final libraryC = Library(Uri.file('/c.dart'), fileUri: Uri.file('/c.dart'));
    final libraryB = Library(Uri.file('/b.dart'), fileUri: Uri.file('/b.dart'));
    libraryC.dependencies.add(LibraryDependency.import(libraryB));
    libraryB.dependencies.add(LibraryDependency.import(libraryC));
    final libraryA = Library(
      Uri.file('/a.dart'),
      fileUri: Uri.file('/a.dart'),
      dependencies: [
        LibraryDependency.import(libraryB),
      ],
      procedures: [
        Procedure(Name('ArbitrarilyChosen'), ProcedureKind.Method,
            FunctionNode(Block([])))
      ],
    );
    final testComponent = Component(
        libraries: [libraryA, libraryB, libraryC, ...testCoreLibraries]);

    final strongComponents =
        StrongComponents(testComponent, Uri.file('/a.dart'));
    strongComponents.computeModules();
    final javaScriptBundler =
        JavaScriptBundler(testComponent, strongComponents);
    final manifestSink = _MemorySink();
    final codeSink = _MemorySink();
    final sourcemapSink = _MemorySink();

    javaScriptBundler.compile(ClassHierarchy(testComponent),
        CoreTypes(testComponent), codeSink, manifestSink, sourcemapSink);

    final code = utf8.decode(codeSink.buffer);
    final manifest = json.decode(utf8.decode(manifestSink.buffer));

    // There should only be two modules since C and B should be combined.
    const moduleHeader = r"define(['dart_sdk'], function(dart_sdk) {";

    expect(moduleHeader.allMatches(code), hasLength(2));

    // verify source map url is correct.
    expect(code, contains('sourceMappingURL=a.dart.js.map'));

    final offsets = manifest['/a.dart.js']['sourcemap'];
    final sourcemapModuleA = json.decode(
        utf8.decode(sourcemapSink.buffer.sublist(offsets.first, offsets.last)));

    // verify source maps are pointing at correct source files.
    expect(sourcemapModuleA['file'], 'a.dart');
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
    result[key] ??= [];
    result[key].addAll(right[key]);
  }
  return result;
}
