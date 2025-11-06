// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToDotShorthand extends ResolvedCorrectionProducer {
  ConvertToDotShorthand({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertToDotShorthand;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!isEnabled(Feature.dot_shorthands)) return;
    await computeAssistForNode(builder, node.parent);
  }

  Future<void> computeAssistForNode(
    ChangeBuilder builder,
    AstNode? node,
  ) async {
    switch (node) {
      // e.g. `A.nam^ed()`
      case ConstructorName constructorName:
      // e.g. `pref^ix.A.named()`
      case NamedType(parent: ConstructorName constructorName):
        await convertFromConstructorName(builder, constructorName);
      // e.g. `A.meth^od()`
      case MethodInvocation():
        await convertFromMethodInvocation(builder, node);
      // e.g. `A.gett^er`
      case PrefixedIdentifier():
        await convertFromPrefixedIdentifier(builder, node);
    }
  }

  /// Whether the element of [node] matches the [typeElement], allowing us to
  /// convert the typed identifier to a dot shorthand.
  ///
  /// In the following example, the node `B.getter` is unable to be converted
  /// to a valid dot shorthand, and this method would return `false`.
  ///
  /// ```dart
  /// class A {}
  /// class B {
  ///   static A get getter => A();
  /// }
  ///
  /// A f() {
  ///   return B.getter;
  /// }
  /// ```
  bool contextTypeMatchesTypeElement(AstNode node, Element? typeElement) {
    var featureComputer = FeatureComputer(
      unitResult.libraryElement.typeSystem,
      unitResult.libraryElement.typeProvider,
    );
    var contextType = featureComputer.computeContextType(node, node.offset);
    if (contextType is! InterfaceType) return false;
    return contextType.element == typeElement;
  }

  /// Converts a constructor to a dot shorthand.
  /// (e.g. `E.named()` to `.named()` or `E()` to `.new()`)
  Future<void> convertFromConstructorName(
    ChangeBuilder builder,
    ConstructorName node,
  ) async {
    if (!contextTypeMatchesTypeElement(node, node.type.element)) return;

    // Dot shorthand constructors don't have explicit type arguments.
    // Disallow the assist if the user provided explicit arguments.
    if (node.type.typeArguments != null) return;

    if (node.name != null) {
      // Converts a named constructor e.g. `E.named()` to `.named()`.
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.node(node.type));
      });
    } else {
      // Converts an unnamed constructor e.g. `E()` to `.new()`.
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(node.type), '.new');
      });
    }
  }

  /// Converts a method invocation to a dot shorthand.
  /// (e.g. `E.id()` to `.id()`)
  Future<void> convertFromMethodInvocation(
    ChangeBuilder builder,
    MethodInvocation node,
  ) async {
    var target = node.target;
    if (target is SimpleIdentifier) {
      if (!contextTypeMatchesTypeElement(node, target.element)) return;
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.node(target));
      });
    }
  }

  /// Converts a prefix identifier to a dot shorthand. (e.g. `E.id` to `.id`)
  Future<void> convertFromPrefixedIdentifier(
    ChangeBuilder builder,
    PrefixedIdentifier node,
  ) async {
    Identifier prefix;
    if (node.prefix.element is PrefixElement) {
      prefix = node;
    } else {
      prefix = node.prefix;
    }
    if (!contextTypeMatchesTypeElement(node, prefix.element)) return;
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.node(prefix));
    });
  }
}
