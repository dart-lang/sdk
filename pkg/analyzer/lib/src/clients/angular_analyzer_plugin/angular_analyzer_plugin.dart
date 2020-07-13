// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library provides additional APIs for the corresponding client.
///
/// By providing such higher level APIs we simplify the clients, and reduce
/// dependencies on analyzer internal, so can make otherwise breaking
/// changes easily.
library angular_analyzer_plugin;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/resolver/resolution_visitor.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';

/// Resolve the given [node] in the specified context.
///
/// The [componentClass] is the component class.
///
/// The [templateSource] is the file with the template.
///
/// The template might declare [localVariables], which might be referenced
/// in the node being resolved.
///
/// The [overrideAsExpression] is invoked during [AsExpression] to support
/// custom resolution behavior.
void resolveTemplateNode({
  @required ClassElement componentClass,
  @required Source templateSource,
  @required Iterable<LocalVariableElement> localVariables,
  @required AstNode node,
  @required AnalysisErrorListener errorListener,
  @required ErrorReporter errorReporter,
  OverrideAsExpression overrideAsExpression,
}) {
  final unitElement = componentClass.enclosingElement;
  final library = componentClass.library;

  final libraryScope = LibraryScope(library);
  node.accept(
    ResolutionVisitor(
      unitElement: unitElement,
      errorListener: errorListener,
      featureSet: library.context.analysisOptions.contextFeatures,
      nameScope: libraryScope,
    ),
  );

  final inheritanceManager = InheritanceManager3();
  final resolver = _AngularTemplateResolver(inheritanceManager, library,
      templateSource, library.typeProvider, errorListener,
      overrideAsExpression: overrideAsExpression);
  // fill the name scope
  final classScope = ClassScope(resolver.nameScope, componentClass);
  final localScope = EnclosedScope(classScope);
  resolver
    ..nameScope = localScope
    ..enclosingClass = componentClass;
  localVariables.forEach(localScope.define);
  // do resolve
  node.accept(resolver);
  // verify
  final verifier = ErrorVerifier(
      errorReporter, library, library.typeProvider, inheritanceManager)
    ..enclosingClass = componentClass;
  node.accept(verifier);
}

typedef OverrideAsExpression = void Function({
  @required AsExpression node,
  @required void Function(AsExpression) invokeSuper,
});

class _AngularTemplateResolver extends ResolverVisitor {
  final OverrideAsExpression overrideAsExpression;

  _AngularTemplateResolver(
    InheritanceManager3 inheritanceManager,
    LibraryElement library,
    Source source,
    TypeProvider typeProvider,
    AnalysisErrorListener errorListener, {
    @required this.overrideAsExpression,
  }) : super(inheritanceManager, library, source, typeProvider, errorListener);

  @override
  void visitAsExpression(AsExpression node) {
    if (overrideAsExpression != null) {
      overrideAsExpression(
        node: node,
        invokeSuper: (node) {
          super.visitAsExpression(node);
        },
      );
    } else {
      super.visitAsExpression(node);
    }
  }
}
