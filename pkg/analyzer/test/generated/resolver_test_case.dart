// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'strong_mode_test.dart';
library;

// import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:test/test.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

/// Shared infrastructure for [StrongModeStaticTypeAnalyzer2Test].
class StaticTypeAnalyzer2TestShared extends PubPackageResolutionTest {
  /// Looks up the identifier with [name] and validates that its type type
  /// stringifies to [type] and that its generics match the given stringified
  /// output.
  FunctionType expectFunctionType(
    String name,
    String type, {
    String typeParams = '[]',
    String typeFormals = '[]',
    String? identifierType,
  }) {
    identifierType ??= type;

    String typeParametersStr(List<TypeParameterElement> elements) {
      var elementsStr = elements
          .map((e) {
            return e.displayString();
          })
          .join(', ');
      return '[$elementsStr]';
    }

    SimpleIdentifier identifier = findNode.simple(name);
    var functionType = _getFunctionTypedElementType(identifier);
    assertType(functionType, type);
    expect(identifier.staticType, isNull);
    expect(typeParametersStr(functionType.typeParameters), typeFormals);
    return functionType;
  }

  /// Looks up the identifier with [name] and validates its static [type].
  ///
  /// If [type] is a string, validates that the identifier's static type
  /// stringifies to that text. Otherwise, [type] is used directly a [Matcher]
  /// to match the type.
  void expectIdentifierType(String name, String type) {
    SimpleIdentifier identifier = findNode.simple(name);
    assertType(identifier.staticType, type);
  }

  /// Looks up the initializer for the declaration containing [name] and
  /// validates its static [type].
  ///
  /// If [type] is a string, validates that the identifier's static type
  /// stringifies to that text. Otherwise, [type] is used directly a [Matcher]
  /// to match the type.
  void expectInitializerType(String name, String type) {
    var declaration = findNode.variableDeclaration(name);
    var initializer = declaration.initializer!;
    assertType(initializer.staticType, type);
  }

  FunctionType _getFunctionTypedElementType(SimpleIdentifier identifier) {
    var element = identifier.element;
    if (element is ExecutableElement) {
      return element.type;
    } else if (element is VariableElement) {
      return element.type as FunctionType;
    } else {
      fail('Unexpected element: (${element.runtimeType}) $element');
    }
  }
}
