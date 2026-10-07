// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Resolves an annotation, and checks that it denotes a valid annotation.
///
/// The annotation expression is resolved like any other expression in a
/// constant context. Lookup failures are reported by that resolution, like
/// for any other expression. A resolved annotation must be either a read of a
/// constant variable, or an invocation of a constant constructor; other
/// resolved expressions are reported as invalid annotations. Constructor
/// invocations are verified by constant verification, like other constant
/// constructor invocations.
class AnnotationResolver {
  final TypeAnalyzer _typeAnalyzer;

  AnnotationResolver(this._typeAnalyzer);

  void resolve(AnnotationImpl node) {
    _typeAnalyzer.analyzeExpression(
      node.expression,
      _typeAnalyzer.operations.unknownType,
    );
    _typeAnalyzer.popRewrite();
    _verify(node);
  }

  void _verify(AnnotationImpl node) {
    switch (node.expression) {
      case ConstructorInvocationImpl():
      case ConstructorTearOffImpl():
      // An annotation that names a class with an unnamed constructor, such as
      // `@C`, is taken as an invocation of that constructor with missing
      // arguments.
      case TypeLiteralImpl(
        type: NamedTypeImpl(element: InterfaceElement(unnamedConstructor: _?)),
      ):
        // Constant verification reports non-constant constructors, and
        // missing arguments.
        return;
      // Type arguments without an argument list, such as `@g<int>`, are a
      // syntax error that the parser has already reported. Resolution of the
      // expression reported any lookup failure, such as `@undefined<int>`.
      case FunctionInstantiationImpl():
        return;
      case NameExpressionImpl expression:
        // A read from a receiver that couldn't be resolved, such as
        // `@undefined.foo`, was reported with the receiver.
        if (expression case ReceiverPropertyExtractionImpl(
          :NameExpressionImpl receiver,
        ) when receiver.resolution?.element == null) {
          return;
        }
        // Only a valid read is checked; the resolution of the expression
        // reported why the read is invalid, for example an undefined name.
        var element = expression.resolution?.element;
        if (element == null) {
          return;
        }
        if (element.denotesConstantVariable) {
          return;
        }
      default:
        break;
    }
    _typeAnalyzer.diagnosticReporter.report(diag.invalidAnnotation.at(node));
  }
}
