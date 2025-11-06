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
        name: 'bool',
        supertype: 'Object',
        constructors: [
          ConstructorSpec(
            name: 'fromEnvironment',
            formalParameters: 'String name, {bool defaultValue}',
            isConst: true,
            isFactory: true,
          ),
        ],
      ),
      ClassSpec(name: 'double', supertype: 'num'),
      ClassSpec(
        name: 'int',
        supertype: 'num',
        constructors: [
          ConstructorSpec(
            name: 'fromEnvironment',
            formalParameters: 'String name, {int defaultValue}',
            isConst: true,
            isFactory: true,
          ),
        ],
      ),
      ClassSpec(
        name: 'num',
        supertype: 'Object',
        interfaces: ['Comparable<num>'],
      ),
      ClassSpec(name: 'Comparable', typeParameters: ['T'], isAbstract: true),
      ClassSpec(name: 'Function', isAbstract: true, supertype: 'Object'),
      ClassSpec(
        name: 'Iterable',
        typeParameters: ['E'],
        isAbstract: true,
        supertype: 'Object',
      ),
      ClassSpec(
        name: 'Iterator',
        typeParameters: ['E'],
        isAbstract: true,
        supertype: 'Object',
      ),
      ClassSpec(
        name: 'List',
        typeParameters: ['E'],
        isAbstract: true,
        supertype: 'Object',
        interfaces: ['Iterable<E>'],
      ),
      ClassSpec(
        name: 'Map',
        typeParameters: ['K', 'V'],
        isAbstract: true,
        supertype: 'Object',
      ),
      ClassSpec(name: 'Null', supertype: 'Object'),
      ClassSpec(
        name: 'Object',
        methods: [
          MethodSpec(name: 'toString', returnType: 'String'),
          MethodSpec(
            name: '==',
            returnType: 'bool',
            formalParameters: 'Object other',
          ),
        ],
      ),
      ClassSpec(name: 'Record', isAbstract: true, supertype: 'Object'),
      ClassSpec(
        name: 'Set',
        typeParameters: ['E'],
        isAbstract: true,
        supertype: 'Object',
        interfaces: ['Iterable<E>'],
      ),
      ClassSpec(
        name: 'String',
        supertype: 'Object',
        constructors: [
          ConstructorSpec(
            name: 'fromEnvironment',
            formalParameters: 'String name, {String defaultValue}',
            isConst: true,
            isFactory: true,
          ),
        ],
        methods: [
          MethodSpec(name: 'toLowerCase', returnType: 'String'),
          MethodSpec(
            name: '+',
            returnType: 'String',
            formalParameters: 'String other',
          ),
        ],
      ),
      ClassSpec(
        name: 'Symbol',
        isAbstract: true,
        supertype: 'Object',
        constructors: [
          ConstructorSpec(
            isConst: true,
            isFactory: true,
            formalParameters: 'String name',
          ),
        ],
      ),
      ClassSpec(name: 'Type', isAbstract: true, supertype: 'Object'),
    ],
  ),
  'dart:async': LibrarySpec(
    uri: 'dart:async',
    classes: [
      ClassSpec(
        name: 'Future',
        typeParameters: ['T'],
        isAbstract: true,
        supertype: 'Object',
      ),
      ClassSpec(name: 'FutureOr', typeParameters: ['T'], supertype: 'Object'),
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
      analysisContext,
      rootReference,
      analysisSession,
      _sdkSpec,
    );
    return MockSdkElements._(
      coreLibrary: libraries['dart:core']!,
      asyncLibrary: libraries['dart:async']!,
    );
  }

  MockSdkElements._({required this.coreLibrary, required this.asyncLibrary});
}
