// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';

const _sdkSpec = {
  'dart:core': LibrarySpec(
    uri: 'dart:core',
    classes: [
      ClassSpec(
        'class bool extends Object',
        constructors: [
          ConstructorSpec(
            'const factory fromEnvironment(String name, {bool defaultValue})',
          ),
        ],
      ),
      ClassSpec('class double extends num'),
      ClassSpec(
        'class int extends num',
        constructors: [
          ConstructorSpec(
            'const factory fromEnvironment(String name, {int defaultValue})',
          ),
        ],
      ),
      ClassSpec('class num extends Object implements Comparable<num>'),
      ClassSpec('abstract class Comparable<T>'),
      ClassSpec('abstract class Function extends Object'),
      ClassSpec('abstract class Iterable<E> extends Object'),
      ClassSpec('abstract class Iterator<E> extends Object'),
      ClassSpec('abstract class List<E> extends Object implements Iterable<E>'),
      ClassSpec('abstract class Map<K, V> extends Object'),
      ClassSpec('class Null extends Object'),
      ClassSpec(
        'class Object',
        methods: [
          MethodSpec('String toString()'),
          MethodSpec('bool operator ==(Object other)'),
        ],
      ),
      ClassSpec('abstract class Record extends Object'),
      ClassSpec('abstract class Set<E> extends Object implements Iterable<E>'),
      ClassSpec(
        'class String extends Object',
        constructors: [
          ConstructorSpec(
            'const factory fromEnvironment(String name, {String defaultValue})',
          ),
        ],
        methods: [
          MethodSpec('String toLowerCase()'),
          MethodSpec('String operator +(String other)'),
        ],
      ),
      ClassSpec(
        'abstract class Symbol extends Object',
        constructors: [ConstructorSpec('const factory new(String name)')],
      ),
      ClassSpec('abstract class Type extends Object'),
    ],
  ),
  'dart:async': LibrarySpec(
    uri: 'dart:async',
    imports: ['dart:core'],
    classes: [
      ClassSpec('abstract class Future<T> extends Object'),
      ClassSpec('class FutureOr<T> extends Object'),
    ],
  ),
};

class MockSdkElements {
  final LibraryElementImpl coreLibrary;
  final LibraryElementImpl asyncLibrary;

  factory MockSdkElements(
    engine.AnalysisContext analysisContext,
    Reference rootReference,
    AnalysisSessionImpl analysisSession,
  ) {
    var libraries = buildLibrariesFromSpec(
      analysisContext: analysisContext,
      rootReference: rootReference,
      analysisSession: analysisSession,
      specs: _sdkSpec,
    );
    return MockSdkElements._(
      coreLibrary: libraries['dart:core']!,
      asyncLibrary: libraries['dart:async']!,
    );
  }

  MockSdkElements._({required this.coreLibrary, required this.asyncLibrary});
}
