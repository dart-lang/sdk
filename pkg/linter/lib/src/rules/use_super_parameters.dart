// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/utilities/extensions/string.dart'; // ignore: implementation_imports
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use super-initializer parameters where possible.';

/// Return a set containing the elements of all of the parameters that are
/// referenced in the constructor [body].
Set<FormalParameterElement> _referencedParameters(FunctionBody? body) {
  if (body == null) return const {};
  var collector = _ReferencedParameterCollector();
  body.accept(collector);
  return collector.foundParameters;
}

class UseSuperParameters extends MultiAnalysisRule {
  new()
    : super(
        name: LintNames.use_super_parameters,
        description: _desc,
        state: const RuleState.experimental(),
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.useSuperParametersMultiple,
    diag.useSuperParametersSingle,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.super_parameters)) return;

    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _ReferencedParameterCollector extends RecursiveAstVisitor<void> {
  final Set<FormalParameterElement> foundParameters = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if (element is FormalParameterElement) {
      foundParameters.add(element);
    }
  }
}

class _Visitor(final MultiAnalysisRule rule, final RuleContext context)
    extends SimpleAstVisitor<void> {
  /// Reports the [parameters] that can be converted to super parameters.
  ///
  /// Parameters in [referencedParameters] can't be converted.
  void _reportSuperCandidates(
    SourceRange errorRange,
    SuperConstructorInvocation superInvocation,
    FormalParameterList parameters,
    Set<FormalParameterElement> referencedParameters,
  ) {
    final names = _superCandidates(
      superInvocation,
      parameters,
      referencedParameters,
    ).map((candidate) => candidate.displayName);
    if (names.isEmpty) return;

    final hasMultipleNames = names.length > 1;
    rule.reportAtOffset(
      errorRange.offset,
      errorRange.length,
      diagnosticCode: hasMultipleNames
          ? diag.useSuperParametersMultiple
          : diag.useSuperParametersSingle,
      arguments: [
        hasMultipleNames ? names.quotedAndCommaSeparatedWithAnd : names.single,
      ],
    );
  }

  /// The elements of [parameters] that can be converted to super parameters.
  List<FormalParameterElement> _superCandidates(
    SuperConstructorInvocation superInvocation,
    FormalParameterList parameters,
    Set<FormalParameterElement> referencedParameters,
  ) {
    final superConstructor = superInvocation.element;
    if (superConstructor == null) return const [];

    // TODO(pq): consolidate logic shared w/ server
    //  (https://github.com/dart-lang/linter/issues/3263)

    final candidates = parameters.parameters
        .map((parameter) => parameter.declaredFragment?.element)
        .nonNulls
        .where((parameter) {
          final isSuperCandidate =
              parameter is! FieldFormalParameterElement &&
              !referencedParameters.contains(parameter);
          final matchesSuperParameter = _matchesSuperParameter(
            parameter,
            superInvocation,
          );

          return isSuperCandidate && matchesSuperParameter;
        });
    final positionalCandidates = candidates.where(
      (candidate) => candidate.isPositional,
    );
    final namedCandidates = candidates.where((candidate) => candidate.isNamed);

    // A constructor can't declare positional super parameters while also
    // passing positional arguments to `super`, so positional parameters are
    // only convertible if they replace every positional argument, in order.
    final positionalArgumentElements = superInvocation.argumentList.arguments
        .where((argument) => argument is! NamedArgument)
        .map((argument) => argument.referencedElement);
    final replacesAllPositionalArguments = const IterableEquality<Element?>()
        .equals(positionalCandidates, positionalArgumentElements);

    return [
      if (replacesAllPositionalArguments) ...positionalCandidates,
      ...namedCandidates,
    ];
  }

  /// Whether [parameter] is passed through unchanged to a parameter of the
  /// super constructor whose type is a supertype of the type of [parameter].
  bool _matchesSuperParameter(
    FormalParameterElement parameter,
    SuperConstructorInvocation superInvocation,
  ) {
    final superParameter = superInvocation.argumentList.arguments
        .firstWhereOrNull((argument) => argument.forwards(parameter))
        ?.correspondingParameter;

    return superParameter != null &&
        context.typeSystem.isSubtypeOf(parameter.type, superParameter.type);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final superInvocation = node.initializers
        .whereType<SuperConstructorInvocation>()
        .singleOrNull;
    if (superInvocation == null) return;

    _reportSuperCandidates(
      node.errorRange,
      superInvocation,
      node.parameters,
      _referencedParameters(node.body),
    );
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    final superInvocation = node.body?.initializers
        .whereType<SuperConstructorInvocation>()
        .singleOrNull;
    final classDeclaration = node.parent;
    if (superInvocation == null || classDeclaration is! ClassDeclaration) {
      return;
    }

    // References anywhere in the class body prevent conversion, except in the
    // initializer list, where the parameters remain in scope once converted.
    final collector = _ReferencedParameterCollector();
    for (final member in classDeclaration.body.members) {
      if (member is PrimaryConstructorBody) {
        member.body.accept(collector);
      } else {
        member.accept(collector);
      }
    }
    _reportSuperCandidates(
      node.errorRange,
      superInvocation,
      node.formalParameters,
      collector.foundParameters,
    );
  }
}

extension _ArgumentForwarding on Argument {
  /// The element referenced by this argument's expression, if it is a simple
  /// identifier.
  Element? get referencedElement {
    final expression = argumentExpression;

    return expression is SimpleIdentifier ? expression.element : null;
  }

  /// Whether this argument passes [parameter] through unchanged, by name if
  /// [parameter] is named and by position otherwise.
  bool forwards(FormalParameterElement parameter) {
    final argument = this;
    final referencesParameter = referencedElement == parameter;
    final isPassedByName =
        argument is NamedArgument && argument.name.lexeme == parameter.name;
    final isPassedByPosition = argument is! NamedArgument;

    return referencesParameter &&
        (parameter.isNamed ? isPassedByName : isPassedByPosition);
  }
}
