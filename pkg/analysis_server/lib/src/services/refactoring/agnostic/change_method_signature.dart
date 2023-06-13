// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/framework/formal_parameter.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/write_invocation_arguments.dart'
    show ArgumentsTrailingComma;
import 'package:analysis_server/src/services/refactoring/framework/write_invocation_arguments.dart'
    as framework;
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analysis_server/src/utilities/selection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

/// Analyzes the selection in [refactoringContext], and either returns
/// a [ValidSelectionState], or one of [ErrorSelectionState] subtypes.
Future<SelectionState> analyzeSelection({
  required AbstractRefactoringContext refactoringContext,
}) async {
  return _SelectionAnalyzer(
    refactoringContext: refactoringContext,
  ).analyze();
}

/// Fills [builder] with changes as requested with [signatureUpdate], and
/// returns either [ChangeStatusSuccess], or [ChangeStatusFailure].
///
/// When [ChangeStatusFailure], [builder] might be filled with partial changes,
/// and must be discarded.
Future<ChangeStatus> computeSourceChange({
  required ValidSelectionState selectionState,
  required MethodSignatureUpdate signatureUpdate,
  required ChangeBuilder builder,
}) async {
  return await _SignatureUpdater(
    selectionState: selectionState,
    signatureUpdate: signatureUpdate,
  ).compute(
    builder: builder,
  );
}

/// The supertype return types from [computeSourceChange].
sealed class ChangeStatus {}

/// The supertype for any failure inside [computeSourceChange].
///
/// Currently it has no subtypes, but if more specific error message is
/// necessary, with pieces of data (e.g. nodes, names, etc), such subtypes
/// can be added.
final class ChangeStatusFailure extends ChangeStatus {}

/// The result that signals the success.
final class ChangeStatusSuccess extends ChangeStatus {}

/// The supertype for any failure inside [analyzeSelection].
sealed class ErrorSelectionState extends SelectionState {
  const ErrorSelectionState();
}

/// The description of a formal parameter, returned by [analyzeSelection].
final class FormalParameterState {
  /// The unique identifier of the formal parameter, must be used in
  /// [FormalParameterUpdate] to specify the same parameter.
  final int id;

  /// The current kind of the formal parameter.
  final FormalParameterKind kind;

  /// If a positional parameter, its index, or `null` if named.
  ///
  /// The client does not need to know it, but because [ValidSelectionState]
  /// must be passed back to [computeSourceChange], the refactoring
  /// implementation can use it.
  final int? positionalIndex;

  /// The current name of the formal parameter, provided regardless whether
  /// it is positional or named, useful for the UI.
  final String name;

  /// The extract of code for the type annotation of the formal parameter.
  ///
  /// Because it is literally what is in a source file, it can be anything,
  /// and have arbitrary length. Currently, the refactoring does not allow
  /// changing types, so this field should be read-only in UI.
  final String typeStr;

  /// If `true`, the selection covers this formal parameter.
  final bool isSelected;

  FormalParameterState({
    required this.id,
    required this.kind,
    required this.positionalIndex,
    required this.name,
    required this.typeStr,
    required this.isSelected,
  });
}

/// The description for a single formal parameter update.
class FormalParameterUpdate {
  /// The identifier of a formal parameter, from [FormalParameterState].
  /// The protocol implementation, and the IDE plugin should pass it around.
  final int id;

  /// The new kind for the formal parameter, might be the same as it were
  /// initially, or different.
  ///
  /// TODO(scheglov) We might need `defaultValueText` added.
  final FormalParameterKind kind;

  FormalParameterUpdate({
    required this.id,
    required this.kind,
  });
}

/// The description of a method signature update.
class MethodSignatureUpdate {
  /// The list of formal parameter updates. [FormalParameterUpdate] objects
  /// reference existing formal parameters with `id`. Signatures of the target
  /// method declaration, and of all corresponding methods in the containing
  /// class hierarchy, will be updated. The new formal parameters will be
  /// written in the order [formalParameters] field, with new kinds.
  ///
  /// TODO(scheglov) Test removing.
  /// TODO(scheglov) Consider adding.
  final List<FormalParameterUpdate> formalParameters;

  /// Specifies whether to add the trailing comma after formal parameters.
  ///
  /// TODO(scheglov) Test for empty formal parameter lists.
  final TrailingComma formalParametersTrailingComma;

  /// Specifies whether to add the trailing comma after arguments.
  final ArgumentsTrailingComma argumentsTrailingComma;

  MethodSignatureUpdate({
    required this.formalParameters,
    required this.formalParametersTrailingComma,
    required this.argumentsTrailingComma,
  });
}

/// The error of [analyzeSelection] returned when:
/// 1. The selection does not correspond to a method declaration.
/// 2. The method does not have formal parameters.
final class NoExecutableElementSelectionState extends ErrorSelectionState {
  const NoExecutableElementSelectionState();
}

/// The supertype for all results of [analyzeSelection].
sealed class SelectionState {
  const SelectionState();
}

/// The strategy for trailing comma after formal parameters.
enum TrailingComma {
  /// Always add the trailing comma.
  always,

  /// Keep the trailing comma, if already present.
  ifPresent,

  /// Remove the trailing comma.
  never,
}

/// The error returned when something unexpected encountered.
///
/// 1. A formal parameter without the name.
/// 2. The kind of a formal parameter that we don't understand.
/// 3. A formal parameter without the type annotation.
final class UnexpectedSelectionState extends ErrorSelectionState {
  const UnexpectedSelectionState();
}

/// The valid result of [analyzeSelection].
final class ValidSelectionState extends SelectionState {
  /// The original refactoring context, used by [computeSourceChange] to
  /// access necessary objects, such as search engine.
  final AbstractRefactoringContext refactoringContext;

  /// The element of the target method, used to find corresponding methods
  /// in the class hierarchy.
  final ExecutableElement element;

  /// The current formal parameters.
  final List<FormalParameterState> formalParameters;

  ValidSelectionState({
    required this.refactoringContext,
    required this.element,
    required this.formalParameters,
  });
}

/// The target method declaration.
class _Declaration {
  final ExecutableElement element;
  final AstNode node;
  final List<FormalParameter> selected;

  _Declaration({
    required this.element,
    required this.node,
    required this.selected,
  });
}

/// Formal parameters of a declaration that match the selection.
final class _DeclarationFormalParameters {
  final List<FormalParameter> positional;
  final Map<String, FormalParameter> named;

  _DeclarationFormalParameters({
    required this.positional,
    required this.named,
  });
}

/// The class that implements [analyzeSelection].
class _SelectionAnalyzer {
  final AbstractRefactoringContext refactoringContext;

  _SelectionAnalyzer({
    required this.refactoringContext,
  });

  Future<SelectionState> analyze() async {
    final declaration = await _declaration();
    if (declaration == null) {
      return const NoExecutableElementSelectionState();
    }

    final parameterNodeList = declaration.node.formalParameterList;
    if (parameterNodeList == null) {
      return const NoExecutableElementSelectionState();
    }

    final formalParameterStateList = <FormalParameterState>[];
    var formalParameterId = 0;
    var positionalIndex = 0;
    for (final parameterNode in parameterNodeList.parameters) {
      final nameToken = parameterNode.name;
      if (nameToken == null) {
        return const UnexpectedSelectionState();
      }

      FormalParameterKind kind;
      if (parameterNode.isRequiredPositional) {
        kind = FormalParameterKind.requiredPositional;
      } else if (parameterNode.isOptionalPositional) {
        kind = FormalParameterKind.optionalPositional;
      } else if (parameterNode.isRequiredNamed) {
        kind = FormalParameterKind.requiredNamed;
      } else if (parameterNode.isOptionalNamed) {
        kind = FormalParameterKind.optionalNamed;
      } else {
        // This branch is never reached.
        return const UnexpectedSelectionState();
      }

      // TODO(scheglov) Rework this when adding support for constructors.
      TypeAnnotation? typeNode;
      final notDefault = parameterNode.notDefault;
      if (notDefault is SimpleFormalParameter) {
        typeNode = notDefault.type;
      }
      if (typeNode == null) {
        return const UnexpectedSelectionState();
      }

      formalParameterStateList.add(
        FormalParameterState(
          id: formalParameterId++,
          kind: kind,
          positionalIndex: kind.isPositional ? positionalIndex++ : null,
          name: nameToken.lexeme,
          typeStr: refactoringContext.utils.getNodeText(typeNode),
          isSelected: declaration.selected.contains(parameterNode),
        ),
      );
    }

    return ValidSelectionState(
      refactoringContext: refactoringContext,
      element: declaration.element,
      formalParameters: formalParameterStateList,
    );
  }

  Future<_Declaration?> _declaration() async {
    final coveringNode = refactoringContext.coveringNode;

    switch (coveringNode) {
      case FormalParameter():
        return _declarationFormalParameter(coveringNode);
      case FormalParameterList():
        return _declarationFormalParameterList(coveringNode);
    }

    final atExecutable = _declarationExecutable(
      node: coveringNode,
      anyLocation: false,
      selected: const [],
    );
    if (atExecutable != null) {
      return atExecutable;
    }

    Element? element;
    if (coveringNode is SimpleIdentifier) {
      final invocation = coveringNode.parent;
      if (invocation is MethodInvocation &&
          invocation.methodName == coveringNode) {
        element = invocation.methodName.staticElement;
      }
    }
    if (element is! ExecutableElement) {
      return null;
    }

    // TODO(scheglov) Check that element is in an editable library.
    final declarationResult =
        await refactoringContext.sessionHelper.getElementDeclaration(element);
    final node = declarationResult?.node;
    if (node == null) {
      return null;
    }

    return _Declaration(
      element: element,
      node: node,
      selected: const [],
    );
  }

  _Declaration? _declarationExecutable({
    required AstNode? node,
    required bool anyLocation,
    required List<FormalParameter> selected,
  }) {
    bool hasGoodLocation(Token? name) {
      return anyLocation || refactoringContext.selectionIsInToken(name);
    }

    _Declaration? buildDeclaration(Declaration node) {
      final element = node.declaredElement;
      if (element is ExecutableElement) {
        return _Declaration(
          element: element,
          node: node,
          selected: selected,
        );
      }
      return null;
    }

    if (node is FunctionExpression) {
      final functionDeclaration = node.parent;
      if (functionDeclaration is FunctionDeclaration) {
        node = functionDeclaration;
      }
    }

    switch (node) {
      case FunctionDeclaration():
        if (hasGoodLocation(node.name)) {
          return buildDeclaration(node);
        }
      case MethodDeclaration():
        if (hasGoodLocation(node.name)) {
          return buildDeclaration(node);
        }
    }

    return null;
  }

  _Declaration? _declarationFormalParameter(FormalParameter node) {
    final FormalParameter formalParameter;
    if (node.parent case DefaultFormalParameter result) {
      formalParameter = result;
    } else {
      formalParameter = node;
    }

    final formalParameterList = formalParameter.parent;
    if (formalParameterList is! FormalParameterList) {
      return null;
    }

    return _declarationExecutable(
      node: formalParameterList.parent,
      anyLocation: true,
      selected: [formalParameter],
    );
  }

  _Declaration? _declarationFormalParameterList(FormalParameterList node) {
    final selection = refactoringContext.selection;
    final selectedNodes = selection?.nodesInRange();
    if (selectedNodes == null) {
      return null;
    }

    final selected = selectedNodes.whereType<FormalParameter>().toList();
    if (selected.isEmpty) {
      return null;
    }

    return _declarationExecutable(
      node: node.parent,
      anyLocation: true,
      selected: selected,
    );
  }
}

/// The class that implements [computeSourceChange].
class _SignatureUpdater {
  final ValidSelectionState selectionState;
  final MethodSignatureUpdate signatureUpdate;

  _SignatureUpdater({
    required this.selectionState,
    required this.signatureUpdate,
  });

  AbstractRefactoringContext get refactoringContext {
    return selectionState.refactoringContext;
  }

  SearchEngine get searchEngine {
    return refactoringContext.searchEngine;
  }

  AnalysisSessionHelper get sessionHelper => refactoringContext.sessionHelper;

  Future<ChangeStatus> compute({
    required ChangeBuilder builder,
  }) async {
    final formalParameterStatus = validateFormalParameterUpdates();
    if (formalParameterStatus is! ChangeStatusSuccess) {
      return formalParameterStatus;
    }

    final elements = await computeElements();

    for (final element in elements) {
      final declarationStatus = await updateDeclaration(
        element: element,
        builder: builder,
      );
      if (declarationStatus is! ChangeStatusSuccess) {
        return declarationStatus;
      }

      final referencesStatus = await updateReferences(
        element: element,
        builder: builder,
      );
      if (referencesStatus is! ChangeStatusSuccess) {
        return referencesStatus;
      }
    }

    return ChangeStatusSuccess();
  }

  /// Returns elements that should be updated. When the target element is
  /// a function, only the elements itself has to be updated. If the target
  /// is a class method, then every element in this class hierarchy should
  /// be updated.
  Future<List<ExecutableElement>> computeElements() async {
    final element = selectionState.element;
    if (element case ClassMemberElement member) {
      final set = await getHierarchyMembers(searchEngine, member);
      return set.whereType<ExecutableElement>().toList();
    }
    return [element];
  }

  /// Returns the [MethodDeclaration] for a [MethodElement].
  Future<AstNode?> elementDeclaration(ExecutableElement element) async {
    final helper = sessionHelper;
    final result = await helper.getElementDeclaration(element);
    return result?.node;
  }

  /// Returns the [Selection] for the [reference], using the resolved unit.
  /// Used to find [MethodInvocation]s of a [MethodElement].
  Future<Selection?> referenceSelection(SearchMatch reference) async {
    final unitResult = await referenceUnitResult(reference);
    return unitResult?.unit.select(
      offset: reference.sourceRange.offset,
      length: 0,
    );
  }

  /// Returns the resolved unit with [reference].
  Future<ResolvedUnitResult?> referenceUnitResult(
    SearchMatch reference,
  ) async {
    final element = reference.element;
    return await sessionHelper.getResolvedUnitByElement(element);
  }

  /// Replaces [argumentList] with new code that has arguments as requested
  /// by the formal parameter updates, reordering, changing kind, etc.
  Future<ChangeStatus> updateArguments({
    required ResolvedUnitResult resolvedUnit,
    required ArgumentList argumentList,
    required ChangeBuilder builder,
  }) async {
    final frameworkStatus = await framework.writeArguments(
      formalParameterUpdates: signatureUpdate.formalParameters.map((update) {
        // TODO(scheglov) Maybe support adding formal parameters.
        final existing = selectionState.formalParameters[update.id];
        final reference = _asFrameworkFormalParameterReference(existing);
        switch (update.kind) {
          case FormalParameterKind.requiredPositional:
          case FormalParameterKind.optionalPositional:
            return framework.FormalParameterUpdateExistingPositional(
              reference: reference,
            );
          case FormalParameterKind.requiredNamed:
          case FormalParameterKind.optionalNamed:
            return framework.FormalParameterUpdateExistingNamed(
              reference: reference,
              name: existing.name,
            );
        }
      }).toList(),
      trailingComma: signatureUpdate.argumentsTrailingComma,
      resolvedUnit: resolvedUnit,
      argumentList: argumentList,
      builder: builder,
    );

    switch (frameworkStatus) {
      case framework.WriteArgumentsStatusFailure():
        return ChangeStatusFailure();
      case framework.WriteArgumentsStatusSuccess():
        return ChangeStatusSuccess();
    }
  }

  /// Replaces formal parameters of [element] with new code as requested
  /// by the formal parameter updates, reordering, changing kind, etc.
  Future<ChangeStatus> updateDeclaration({
    required ExecutableElement element,
    required ChangeBuilder builder,
  }) async {
    final path = element.source.fullName;

    final unitResult = await sessionHelper.getResolvedUnitByElement(element);
    if (unitResult == null) {
      return ChangeStatusFailure();
    }

    final utils = CorrectionUtils(unitResult);

    /// Returns the code without the `required` modifier.
    String withoutRequired(FormalParameter existing) {
      final notDefault = existing.notDefault;
      final requiredToken = notDefault.requiredKeyword;
      if (requiredToken != null) {
        final before = utils.getRangeText(
          range.startStart(existing, requiredToken),
        );
        final after = utils.getRangeText(
          range.startEnd(requiredToken.next!, existing),
        );
        return '$before $after';
      } else {
        return utils.getNodeText(existing);
      }
    }

    /// Returns the code with the `required` modifier.
    String withRequired(FormalParameter existing) {
      final notDefault = existing.notDefault;
      final requiredToken = notDefault.requiredKeyword;
      if (requiredToken != null) {
        return utils.getNodeText(existing);
      } else {
        final after = utils.getNodeText(notDefault);
        return 'required $after';
      }
    }

    final elementNode = await elementDeclaration(element);
    if (elementNode == null) {
      return ChangeStatusFailure();
    }

    final formalParameterList = elementNode.formalParameterList;
    if (formalParameterList == null) {
      return ChangeStatusFailure();
    }

    final existingFormalParameters = _declarationFormalParameters(
      formalParameterList: formalParameterList,
    );
    if (existingFormalParameters == null) {
      return ChangeStatusFailure();
    }

    final requiredPositionalWrites = <String>[];
    final optionalPositionalWrites = <String>[];
    final namedWrites = <String>[];
    for (final update in signatureUpdate.formalParameters) {
      final FormalParameter? existing;
      final id = update.id;
      final formalParameterState =
          selectionState.formalParameters.elementAtOrNull2(id);
      if (formalParameterState == null) {
        return ChangeStatusFailure();
      }
      final positionalIndex = formalParameterState.positionalIndex;
      if (positionalIndex != null) {
        existing = existingFormalParameters.positional
            .elementAtOrNull2(positionalIndex);
        if (existing == null) {
          return ChangeStatusFailure();
        }
      } else {
        existing =
            existingFormalParameters.named.remove(formalParameterState.name);
        if (existing == null) {
          continue;
        }
      }

      final notDefault = existing.notDefault;
      switch (notDefault) {
        case NormalFormalParameter():
          switch (update.kind) {
            case FormalParameterKind.requiredPositional:
              final text = utils.getNodeText(notDefault);
              requiredPositionalWrites.add(text);
            case FormalParameterKind.optionalPositional:
              final text = withoutRequired(existing);
              optionalPositionalWrites.add(text);
            case FormalParameterKind.requiredNamed:
              final text = withRequired(existing);
              namedWrites.add(text);
            case FormalParameterKind.optionalNamed:
              final text = withoutRequired(existing);
              namedWrites.add(text);
          }
        default:
          return ChangeStatusFailure();
      }
    }
    // TODO(scheglov) add back remaining named formal parameters

    await builder.addDartFileEdit(path, (builder) {
      builder.addReplacement(
        range.node(formalParameterList),
        (builder) {
          builder.write('(');
          var hasParameterWritten = false;

          void writeOptionalParameters({
            required List<String> parameters,
            required String leftSeparator,
            required String rightSeparator,
          }) {
            if (parameters.isNotEmpty) {
              if (hasParameterWritten) {
                builder.write(', ');
                hasParameterWritten = false;
              }
              builder.write(leftSeparator);
              for (final writeParameter in parameters) {
                if (hasParameterWritten) {
                  builder.write(', ');
                }
                builder.write(writeParameter);
                hasParameterWritten = true;
              }
              writeFormalParametersTrailingComma(
                formalParameterList: formalParameterList,
                builder: builder,
              );
              builder.write(rightSeparator);
            }
          }

          // Write required positional parameters.
          for (final writeParameter in requiredPositionalWrites) {
            if (hasParameterWritten) {
              builder.write(', ');
            }
            builder.write(writeParameter);
            hasParameterWritten = true;
          }

          // Write optional positional parameters.
          writeOptionalParameters(
            parameters: optionalPositionalWrites,
            leftSeparator: '[',
            rightSeparator: ']',
          );

          // Write named parameters.
          writeOptionalParameters(
            parameters: namedWrites,
            leftSeparator: '{',
            rightSeparator: '}',
          );
          builder.write(')');
        },
      );
      builder.format(range.node(formalParameterList));
    });

    return ChangeStatusSuccess();
  }

  /// Updates arguments of invocations of [element].
  Future<ChangeStatus> updateReferences({
    required ExecutableElement element,
    required ChangeBuilder builder,
  }) async {
    final references = await searchEngine.searchReferences(element);
    for (final reference in references) {
      final unitResult = await referenceUnitResult(reference);
      if (unitResult == null) {
        return ChangeStatusFailure();
      }

      final selection = await referenceSelection(reference);
      if (selection == null) {
        return ChangeStatusFailure();
      }

      MethodInvocation? invocation;
      final coveringNode = selection.coveringNode;
      if (coveringNode is MethodInvocation) {
        invocation = coveringNode;
      } else if (coveringNode is SimpleIdentifier) {
        invocation = coveringNode.parent.ifTypeOrNull();
      }
      if (invocation == null) {
        return ChangeStatusFailure();
      }

      final result = await updateArguments(
        resolvedUnit: unitResult,
        argumentList: invocation.argumentList,
        builder: builder,
      );
      if (result is! ChangeStatusSuccess) {
        return result;
      }
    }

    return ChangeStatusSuccess();
  }

  /// Checks requested updates for formal parameters.
  ///
  /// For example, it is not allowed to have both optional positional, and
  /// any named formal parameters.
  ///
  /// TODO(scheglov) check no required positional arter optional
  ChangeStatus validateFormalParameterUpdates() {
    final updates = signatureUpdate.formalParameters;

    final optionalPositional = updates.where((e) {
      return e.kind.isOptionalPositional;
    }).toList();

    final named = updates.where((e) {
      return e.kind.isNamed;
    }).toList();

    if (optionalPositional.isNotEmpty && named.isNotEmpty) {
      return ChangeStatusFailure();
    }

    return ChangeStatusSuccess();
  }

  void writeFormalParametersTrailingComma({
    required FormalParameterList formalParameterList,
    required DartEditBuilder builder,
  }) {
    switch (signatureUpdate.formalParametersTrailingComma) {
      case TrailingComma.always:
        builder.write(',');
      case TrailingComma.ifPresent:
        if (formalParameterList.hasTrailingComma) {
          builder.write(',');
        }
      case TrailingComma.never:
        break;
    }
  }

  FormalParameterReference _asFrameworkFormalParameterReference(
    FormalParameterState existing,
  ) {
    final positionalIndex = existing.positionalIndex;
    if (positionalIndex != null) {
      return PositionalFormalParameterReference(positionalIndex);
    } else {
      return NamedFormalParameterReference(existing.name);
    }
  }

  /// If [formalParameterList] does not have the same number and kind of
  /// positional formal parameters, returns `null`.
  ///
  /// Otherwise, returns separated positional and named formal parameters.
  _DeclarationFormalParameters? _declarationFormalParameters({
    required FormalParameterList formalParameterList,
  }) {
    final positional = <FormalParameter>[];
    final named = <String, FormalParameter>{};
    for (final formalParameter in formalParameterList.parameters) {
      if (formalParameter.isPositional) {
        positional.add(formalParameter);
      } else {
        final name = formalParameter.name?.lexeme;
        if (name == null) {
          return null;
        }
        named[name] = formalParameter;
      }
    }

    final selectionPositional = selectionState.formalParameters
        .where((state) => state.kind.isPositional)
        .toList();
    if (positional.length != selectionPositional.length) {
      return null;
    }

    for (var i = 0; i < positional.length; i++) {
      final positionalKind = positional[i].isRequiredPositional
          ? FormalParameterKind.requiredPositional
          : FormalParameterKind.optionalPositional;
      if (positionalKind != selectionPositional[i].kind) {
        return null;
      }
    }

    return _DeclarationFormalParameters(
      positional: positional,
      named: named,
    );
  }
}

extension on FormalParameterList {
  bool get hasTrailingComma {
    final last = parameters.lastOrNull;
    final nextToken = last?.endToken.next;
    return nextToken != null && nextToken.type == TokenType.COMMA;
  }
}

extension on AstNode {
  FormalParameterList? get formalParameterList {
    final self = this;
    switch (self) {
      case FunctionDeclaration():
        return self.functionExpression.parameters;
      case MethodDeclaration():
        return self.parameters;
    }
    return null;
  }
}
