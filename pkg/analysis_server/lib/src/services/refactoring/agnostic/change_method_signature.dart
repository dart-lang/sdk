// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/framework/formal_parameter.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/write_invocation_arguments.dart'
    as framework;
import 'package:analysis_server/src/services/refactoring/framework/write_invocation_arguments.dart'
    show ArgumentsTrailingComma;
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
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
/// a [Available], or [NotAvailable].
Availability analyzeAvailability({
  required AbstractRefactoringContext refactoringContext,
}) {
  return _AvailabilityAnalyzer(
    refactoringContext: refactoringContext,
  ).analyze();
}

/// Continues analysis of the selection in [available], and returns either
/// a [ValidSelectionState], or one of [ErrorSelectionState] subtypes.
Future<SelectionState> analyzeSelection({required Available available}) async {
  return _SelectionAnalyzer(available: available).analyze();
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
  ).compute(builder: builder);
}

sealed class Availability {}

sealed class Available extends Availability {
  final AbstractRefactoringContext refactoringContext;

  Available({required this.refactoringContext});

  bool get hasPositionalParameters;

  bool get hasSelectedFormalParametersToConvertToNamed => false;

  bool get hasSelectedFormalParametersToMoveLeft => false;
}

/// The supertype return types from [computeSourceChange].
sealed class ChangeStatus {}

/// The supertype for any failure inside [computeSourceChange].
///
/// Currently it has no subtypes, but if more specific error message is
/// necessary, with pieces of data (e.g. nodes, names, etc), such subtypes
/// can be added.
final class ChangeStatusFailure extends ChangeStatus {}

/// The signal that the [ConstructorDeclaration] with a super formal parameter
/// was found. This is not supported by the refactoring.
///
// TODO(scheglov): Make [ChangeStatusFailure] sealed.
final class ChangeStatusFailureSuperFormalParameter
    extends ChangeStatusFailure {
  final ConstructorDeclaration constructorDeclaration;

  ChangeStatusFailureSuperFormalParameter({
    required this.constructorDeclaration,
  });
}

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

  /// The element, used internally for `super` conversion.
  final ParameterElement element;

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
    required this.element,
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
  // TODO(scheglov): We might need `defaultValueText` added.
  final FormalParameterKind kind;

  /// Whether the formal parameter should be made `super`.
  final bool withSuper;

  FormalParameterUpdate({
    required this.id,
    required this.kind,
    this.withSuper = false,
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
  // TODO(scheglov): Consider adding.
  final List<FormalParameterUpdate> formalParameters;

  /// Normally, after writing formal parameters in the order specified by
  /// [formalParameters], we write any remaining named formal parameters.
  /// So, here we record names that are explicitly removed.
  final Set<String> removedNamedFormalParameters;

  /// Specifies whether to add the trailing comma after formal parameters.
  final TrailingComma formalParametersTrailingComma;

  /// Specifies whether to add the trailing comma after arguments.
  final ArgumentsTrailingComma argumentsTrailingComma;

  MethodSignatureUpdate({
    required this.formalParameters,
    this.removedNamedFormalParameters = const {},
    required this.formalParametersTrailingComma,
    required this.argumentsTrailingComma,
  });
}

/// The error of [analyzeSelection] returned when:
/// 1. The selection does not correspond to a method declaration.
/// 2. The method does not have formal parameters.
final class NoExecutableElementSelectionState extends ErrorSelectionState {}

sealed class NotAvailable extends Availability {}

final class NotAvailableExternalElement extends NotAvailable {}

final class NotAvailableNoExecutableElement extends NotAvailable {}

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

class _AvailabilityAnalyzer {
  final AbstractRefactoringContext refactoringContext;

  _AvailabilityAnalyzer({required this.refactoringContext});

  Availability analyze() {
    var declaration = _declaration();
    if (declaration != null) {
      return _AvailableWithDeclaration(
        refactoringContext: refactoringContext,
        declaration: declaration,
      );
    }

    return _executableElement();
  }

  _Declaration? _declaration() {
    var coveringNode = refactoringContext.coveringNode;

    switch (coveringNode) {
      case FormalParameter():
        return _declarationFormalParameter(coveringNode);
      case FormalParameterList():
        return _declarationFormalParameterList(coveringNode);
    }

    return _declarationExecutable(
      node: coveringNode,
      anyLocation: false,
      selected: const [],
    );
  }

  /// [node] is either an executable declaration itself, or a node that is
  /// unambiguously associated with one.
  _Declaration? _declarationExecutable({
    required AstNode? node,
    required bool anyLocation,
    required List<FormalParameter> selected,
  }) {
    bool hasGoodLocation(Token? name) {
      return anyLocation || refactoringContext.selectionIsInToken(name);
    }

    _Declaration? buildDeclaration(Declaration node) {
      var element = node.declaredElement;
      if (element is ExecutableElement) {
        return _Declaration(element: element, node: node, selected: selected);
      }
      return null;
    }

    node = node?.declaration;
    switch (node) {
      case ConstructorDeclaration():
        var nameRange = range.startEnd(
          node.returnType,
          node.name ?? node.returnType,
        );
        var selectionRange = refactoringContext.selectionRange;
        if (anyLocation || nameRange.covers(selectionRange)) {
          return buildDeclaration(node);
        }
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
    FormalParameter formalParameter;
    if (node.parent case DefaultFormalParameter result) {
      formalParameter = result;
    } else {
      formalParameter = node;
    }

    var formalParameterList = formalParameter.parent;
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
    var selection = refactoringContext.selection;
    var selectedNodes = selection?.nodesInRange();
    if (selectedNodes == null) {
      return null;
    }

    var selected = selectedNodes.whereType<FormalParameter>().toList();
    if (selected.isEmpty) {
      return null;
    }

    return _declarationExecutable(
      node: node.parent,
      anyLocation: true,
      selected: selected,
    );
  }

  Availability _executableElement() {
    var coveringNode = refactoringContext.coveringNode;

    Element? element;
    if (coveringNode is SimpleIdentifier) {
      var invocation = coveringNode.parent;
      if (invocation is MethodInvocation &&
          invocation.methodName == coveringNode) {
        element = invocation.methodName.staticElement;
      }
    }

    if (element is! ExecutableElement) {
      return NotAvailableNoExecutableElement();
    }

    var libraryFilePath = element.librarySource.fullName;
    if (!refactoringContext.workspace.containsFile(libraryFilePath)) {
      return NotAvailableExternalElement();
    }

    return _AvailableWithExecutableElement(
      refactoringContext: refactoringContext,
      element: element,
    );
  }
}

final class _AvailableWithDeclaration extends Available {
  final _Declaration declaration;

  _AvailableWithDeclaration({
    required super.refactoringContext,
    required this.declaration,
  });

  @override
  bool get hasPositionalParameters {
    return declaration.element.parameters.any((e) => e.isPositional);
  }

  @override
  bool get hasSelectedFormalParametersToConvertToNamed {
    var selected = declaration.selected;
    if (selected.isEmpty) {
      return false;
    }

    // If all selected are already required named, nothing to do.
    if (selected.every((e) => e.isRequiredNamed)) {
      return false;
    }

    var formalParameterList = declaration.node.formalParameterList;
    if (formalParameterList == null) {
      return false;
    }

    var others = formalParameterList.parameters.toSet();
    others.removeAll(selected);

    // We cannot convert, if there are remaining optional positional.
    for (var other in others) {
      if (other.isOptionalPositional) {
        return false;
      }
    }

    return true;
  }

  @override
  bool get hasSelectedFormalParametersToMoveLeft {
    var selected = declaration.selected;
    var firstSelected = selected.firstOrNull;
    if (firstSelected == null) {
      return false;
    }

    var formalParameterList = declaration.node.formalParameterList;
    if (formalParameterList == null) {
      return false;
    }

    var all = formalParameterList.parameters.toList();
    var firstSelectedIndex = all.indexOf(firstSelected);
    if (firstSelectedIndex < 1) {
      return false;
    }

    var previous = all[firstSelectedIndex - 1];
    if (firstSelected.isOptionalPositional && !previous.isOptionalPositional) {
      return false;
    }
    if (firstSelected.isNamed && !previous.isNamed) {
      return false;
    }

    return true;
  }
}

final class _AvailableWithExecutableElement extends Available {
  final ExecutableElement element;

  _AvailableWithExecutableElement({
    required super.refactoringContext,
    required this.element,
  });

  @override
  bool get hasPositionalParameters {
    return element.parameters.any((e) => e.isPositional);
  }
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

  _DeclarationFormalParameters({required this.positional, required this.named});
}

/// The class that implements [analyzeSelection].
class _SelectionAnalyzer {
  final Available available;

  _SelectionAnalyzer({required this.available});

  AbstractRefactoringContext get refactoringContext {
    return available.refactoringContext;
  }

  Future<SelectionState> analyze() async {
    var declaration = await _declaration();
    if (declaration == null) {
      return NoExecutableElementSelectionState();
    }

    var parameterNodeList = declaration.node.formalParameterList;
    if (parameterNodeList == null) {
      return NoExecutableElementSelectionState();
    }

    var formalParameterStateList = <FormalParameterState>[];
    var formalParameterId = 0;
    var positionalIndex = 0;
    for (var parameterNode in parameterNodeList.parameters) {
      var nameToken = parameterNode.name;
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

      var parameterElement = parameterNode.declaredElement;
      if (parameterElement == null) {
        return const UnexpectedSelectionState();
      }

      var typeStr = parameterElement.type.getDisplayString();

      formalParameterStateList.add(
        FormalParameterState(
          id: formalParameterId++,
          element: parameterElement,
          kind: kind,
          positionalIndex: kind.isPositional ? positionalIndex++ : null,
          name: nameToken.lexeme,
          typeStr: typeStr,
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

  /// Converts [available] into a [_Declaration].
  Future<_Declaration?> _declaration() async {
    switch (available) {
      case _AvailableWithDeclaration(:var declaration):
        return declaration;
      case _AvailableWithExecutableElement(:var element):
        var node = await _elementDeclaration(element);
        if (node == null) {
          return null;
        }

        return _Declaration(element: element, node: node, selected: const []);
    }
  }

  Future<AstNode?> _elementDeclaration(ExecutableElement element) async {
    var helper = refactoringContext.sessionHelper;
    var nodeResult = await helper.getElementDeclaration(element);
    return nodeResult?.node;
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

  Future<ChangeStatus> compute({required ChangeBuilder builder}) async {
    var formalParameterStatus = validateFormalParameterUpdates();
    if (formalParameterStatus is! ChangeStatusSuccess) {
      return formalParameterStatus;
    }

    var elements = await computeElements();

    for (var element in elements) {
      var declarationStatus = await updateDeclaration(
        element: element,
        builder: builder,
      );
      if (declarationStatus is! ChangeStatusSuccess) {
        return declarationStatus;
      }

      var referencesStatus = await updateReferences(
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
    var element = selectionState.element;
    if (element case ClassMemberElement member) {
      var set = await getHierarchyMembers(searchEngine, member);
      return set.whereType<ExecutableElement>().toList();
    }
    return [element];
  }

  /// Returns the [MethodDeclaration] for a [MethodElement].
  Future<AstNode?> elementDeclaration(ExecutableElement element) async {
    var helper = sessionHelper;
    var result = await helper.getElementDeclaration(element);
    return result?.node;
  }

  /// Returns the [Selection] for the [reference], using the resolved unit.
  /// Used to find [MethodInvocation]s of a [MethodElement].
  Future<Selection?> referenceSelection(SearchMatch reference) async {
    var unitResult = await referenceUnitResult(reference);
    return unitResult?.unit.select(
      offset: reference.sourceRange.offset,
      length: 0,
    );
  }

  /// Returns the resolved unit with [reference].
  Future<ResolvedUnitResult?> referenceUnitResult(SearchMatch reference) async {
    var element = reference.element;
    return await sessionHelper.getResolvedUnitByElement(element);
  }

  /// Replaces [argumentList] with new code that has arguments as requested
  /// by the formal parameter updates, reordering, changing kind, etc.
  Future<ChangeStatus> updateArguments({
    required Set<FormalParameterUpdate> excludedFormalParameters,
    required ResolvedUnitResult resolvedUnit,
    required ArgumentList argumentList,
    required ChangeBuilder builder,
  }) async {
    var formalParameters =
        signatureUpdate.formalParameters
            .whereNot(excludedFormalParameters.contains)
            .toList();

    var frameworkStatus = await framework.writeArguments(
      formalParameterUpdates:
          formalParameters.map((update) {
            // TODO(scheglov): Maybe support adding formal parameters.
            var existing = selectionState.formalParameters[update.id];
            var reference = _asFrameworkFormalParameterReference(existing);
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
      removedNamedFormalParameters:
          signatureUpdate.removedNamedFormalParameters,
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
    var path = element.source.fullName;

    var unitResult = await sessionHelper.getResolvedUnitByElement(element);
    if (unitResult == null) {
      return ChangeStatusFailure();
    }

    var utils = CorrectionUtils(unitResult);

    /// Returns the code without the `required` modifier.
    String withoutRequired(
      FormalParameter existing, {
      required bool withSuper,
    }) {
      var notDefault = existing.notDefault;
      var requiredToken = notDefault.requiredKeyword;
      if (requiredToken != null) {
        var before = utils.getRangeText(
          range.startStart(existing, requiredToken),
        );
        var after = utils.getRangeText(
          range.startEnd(requiredToken.next!, existing),
        );
        return '$before $after';
      } else {
        if (withSuper) {
          var nameToken = notDefault.name!;
          var before = utils.getRangeText(
            range.startStart(existing, nameToken),
          );
          var after = utils.getRangeText(range.startEnd(nameToken, existing));
          return '${before}super.$after';
        } else {
          return utils.getNodeText(existing);
        }
      }
    }

    /// Returns the code with the `required` modifier.
    String withRequired(FormalParameter existing, {required bool withSuper}) {
      var notDefault = existing.notDefault;
      var requiredToken = notDefault.requiredKeyword;
      if (requiredToken != null) {
        if (withSuper) {
          var nameToken = notDefault.name!;
          var before = utils.getRangeText(
            range.startStart(requiredToken.next!, nameToken),
          );
          return 'required ${before}super.${nameToken.lexeme}';
        } else {
          return utils.getNodeText(existing);
        }
      } else {
        if (withSuper) {
          var nameToken = notDefault.name!;
          var before = utils.getRangeText(
            range.startStart(notDefault, nameToken),
          );
          return 'required ${before}super.${nameToken.lexeme}';
        } else {
          var after = utils.getNodeText(notDefault);
          return 'required $after';
        }
      }
    }

    var elementNode = await elementDeclaration(element);
    if (elementNode == null) {
      return ChangeStatusFailure();
    }

    var formalParameterList = elementNode.formalParameterList;
    if (formalParameterList == null) {
      return ChangeStatusFailure();
    }

    var existingFormalParameters = _declarationFormalParameters(
      formalParameterList: formalParameterList,
    );
    if (existingFormalParameters == null) {
      return ChangeStatusFailure();
    }

    var requiredPositionalWrites = <String>[];
    var optionalPositionalWrites = <String>[];
    var namedWrites = <String>[];
    for (var update in signatureUpdate.formalParameters) {
      FormalParameter? existing;
      var id = update.id;
      var formalParameterState = selectionState.formalParameters
          .elementAtOrNull2(id);
      if (formalParameterState == null) {
        return ChangeStatusFailure();
      }
      var positionalIndex = formalParameterState.positionalIndex;
      if (positionalIndex != null) {
        existing = existingFormalParameters.positional.elementAtOrNull2(
          positionalIndex,
        );
        if (existing == null) {
          return ChangeStatusFailure();
        }
      } else {
        var name = formalParameterState.name;
        existing = existingFormalParameters.named.remove(name);
        if (existing == null) {
          continue;
        }
      }

      var notDefault = existing.notDefault;
      switch (notDefault) {
        case NormalFormalParameter():
          switch (update.kind) {
            case FormalParameterKind.requiredPositional:
              var text = withoutRequired(
                notDefault,
                withSuper: update.withSuper,
              );
              requiredPositionalWrites.add(text);
            case FormalParameterKind.optionalPositional:
              var text = withoutRequired(existing, withSuper: update.withSuper);
              optionalPositionalWrites.add(text);
            case FormalParameterKind.requiredNamed:
              var text = withRequired(existing, withSuper: update.withSuper);
              namedWrites.add(text);
            case FormalParameterKind.optionalNamed:
              var text = withoutRequired(existing, withSuper: update.withSuper);
              namedWrites.add(text);
          }
        default:
          return ChangeStatusFailure();
      }
    }

    // Add back remaining named formal parameters.
    var removedNamed = signatureUpdate.removedNamedFormalParameters;
    existingFormalParameters.named.forEach((name, node) {
      if (removedNamed.contains(name)) {
        return;
      }
      var text = utils.getNodeText(node);
      namedWrites.add(text);
    });

    await builder.addDartFileEdit(path, (builder) {
      builder.addReplacement(range.node(formalParameterList), (builder) {
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
            for (var writeParameter in parameters) {
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
        for (var writeParameter in requiredPositionalWrites) {
          if (hasParameterWritten) {
            builder.write(', ');
          }
          builder.write(writeParameter);
          hasParameterWritten = true;
        }

        // Maybe write the trailing comma.
        if (requiredPositionalWrites.isNotEmpty &&
            optionalPositionalWrites.isEmpty &&
            namedWrites.isEmpty) {
          writeFormalParametersTrailingComma(
            formalParameterList: formalParameterList,
            builder: builder,
          );
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
      });
      builder.format(range.node(formalParameterList));
    });

    return ChangeStatusSuccess();
  }

  /// Updates arguments of invocations of [element].
  Future<ChangeStatus> updateReferences({
    required ExecutableElement element,
    required ChangeBuilder builder,
  }) async {
    var references = await searchEngine.searchReferences(element);
    for (var reference in references) {
      var unitResult = await referenceUnitResult(reference);
      if (unitResult == null) {
        return ChangeStatusFailure();
      }

      var selection = await referenceSelection(reference);
      if (selection == null) {
        return ChangeStatusFailure();
      }

      ArgumentList argumentList;
      var invocation = selection.invocation;
      switch (invocation) {
        case ConstructorDeclaration constructor:
          return ChangeStatusFailureSuperFormalParameter(
            constructorDeclaration: constructor,
          );
        case InstanceCreationExpression instanceCreation:
          argumentList = instanceCreation.argumentList;
        case MethodInvocation invocation:
          argumentList = invocation.argumentList;
        case RedirectingConstructorInvocation invocation:
          argumentList = invocation.argumentList;
        case SuperConstructorInvocation invocation:
          argumentList = invocation.argumentList;
        default:
          return ChangeStatusFailure();
      }

      var excludedParameters = <FormalParameterUpdate>{};
      if (invocation is SuperConstructorInvocation) {
        var result = await _rewriteToNamedSuper(
          builder: builder,
          unitResult: unitResult,
          invocation: invocation,
          excludedParameters: excludedParameters,
        );
        if (result is! ChangeStatusSuccess) {
          return result;
        }
      }

      var result = await updateArguments(
        excludedFormalParameters: excludedParameters,
        resolvedUnit: unitResult,
        argumentList: argumentList,
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
  ChangeStatus validateFormalParameterUpdates() {
    var updates = signatureUpdate.formalParameters;

    var optionalPositionalCount = 0;
    var namedCount = 0;
    for (var update in updates) {
      switch (update.kind) {
        case FormalParameterKind.requiredPositional:
          if (optionalPositionalCount > 0 || namedCount > 0) {
            return ChangeStatusFailure();
          }
        case FormalParameterKind.optionalPositional:
          if (namedCount > 0) {
            return ChangeStatusFailure();
          }
          optionalPositionalCount++;
        case FormalParameterKind.requiredNamed:
        case FormalParameterKind.optionalNamed:
          if (optionalPositionalCount > 0) {
            return ChangeStatusFailure();
          }
          namedCount++;
      }
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
    var positionalIndex = existing.positionalIndex;
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
    var positional = <FormalParameter>[];
    var named = <String, FormalParameter>{};
    for (var formalParameter in formalParameterList.parameters) {
      if (formalParameter.isPositional) {
        positional.add(formalParameter);
      } else {
        var name = formalParameter.name?.lexeme;
        if (name == null) {
          return null;
        }
        named[name] = formalParameter;
      }
    }

    var selectionPositional =
        selectionState.formalParameters
            .where((state) => state.kind.isPositional)
            .toList();
    if (positional.length != selectionPositional.length) {
      return null;
    }

    for (var i = 0; i < positional.length; i++) {
      var positionalKind =
          positional[i].isRequiredPositional
              ? FormalParameterKind.requiredPositional
              : FormalParameterKind.optionalPositional;
      if (positionalKind != selectionPositional[i].kind) {
        return null;
      }
    }

    return _DeclarationFormalParameters(positional: positional, named: named);
  }

  /// Attempts to rewrite explicit arguments to `super()` invocation into
  /// implicit arguments using `{super.name}` formal parameters.
  Future<ChangeStatus> _rewriteToNamedSuper({
    required ChangeBuilder builder,
    required ResolvedUnitResult unitResult,
    required SuperConstructorInvocation invocation,
    required Set<FormalParameterUpdate> excludedParameters,
  }) async {
    var argumentList = invocation.argumentList;

    var constructorDeclaration = invocation.parent;
    if (constructorDeclaration is! ConstructorDeclaration) {
      return ChangeStatusSuccess();
    }

    var parameterElementsToSuper = <ParameterElement>{};
    for (var update in signatureUpdate.formalParameters) {
      if (update.kind.isNamed) {
        var existing = selectionState.formalParameters[update.id];
        var reference = _asFrameworkFormalParameterReference(existing);
        var argument = reference.argumentFrom(argumentList);
        if (argument is! SimpleIdentifier) {
          continue;
        }

        var parameterElement = argument.staticElement;
        if (parameterElement is! ParameterElement) {
          continue;
        }

        // We need the names to be the same to use `super.named`.
        // If not, we still can use explicit argument to `super()`.
        // TODO(scheglov): can we have a lint for this?
        if (argument.name != existing.name) {
          continue;
        }

        excludedParameters.add(update);
        parameterElementsToSuper.add(parameterElement);
      }
    }

    // Prepare for recursive update of the constructor.
    var availability = analyzeAvailability(
      refactoringContext: AbstractRefactoringContext(
        searchEngine: searchEngine,
        startSessions: refactoringContext.startSessions,
        resolvedLibraryResult: refactoringContext.resolvedLibraryResult,
        resolvedUnitResult: unitResult,
        clientCapabilities: refactoringContext.clientCapabilities,
        selectionOffset: constructorDeclaration.offset,
        selectionLength: 0,
        includeExperimental: true,
      ),
    );
    if (availability is! Available) {
      return ChangeStatusFailure();
    }

    var selection = await analyzeSelection(available: availability);
    if (selection is! ValidSelectionState) {
      return ChangeStatusFailure();
    }

    var formalParameterUpdatesNotNamed = <FormalParameterUpdate>[];
    var formalParameterUpdatesNamed = <FormalParameterUpdate>[];
    for (var formalParameter in selection.formalParameters) {
      var element = formalParameter.element;
      if (element.isNamed) {
        formalParameterUpdatesNamed.add(
          FormalParameterUpdate(
            id: formalParameter.id,
            kind: FormalParameterKind.fromElement(element),
            withSuper: true,
          ),
        );
      } else if (parameterElementsToSuper.contains(element)) {
        formalParameterUpdatesNamed.add(
          FormalParameterUpdate(
            id: formalParameter.id,
            kind: FormalParameterKind.requiredNamed,
            withSuper: true,
          ),
        );
      } else {
        formalParameterUpdatesNotNamed.add(
          FormalParameterUpdate(
            id: formalParameter.id,
            kind: formalParameter.kind,
          ),
        );
      }
    }

    var status = await computeSourceChange(
      selectionState: selection,
      signatureUpdate: MethodSignatureUpdate(
        formalParameters: [
          ...formalParameterUpdatesNotNamed,
          ...formalParameterUpdatesNamed,
        ],
        formalParametersTrailingComma:
            signatureUpdate.formalParametersTrailingComma,
        argumentsTrailingComma: signatureUpdate.argumentsTrailingComma,
      ),
      builder: builder,
    );
    if (status is! ChangeStatusSuccess) {
      return status;
    }

    // TODO(scheglov): Remove empty `super()`.

    return ChangeStatusSuccess();
  }
}

extension on AstNode {
  AstNode? get declaration {
    var self = this;
    if (self is FunctionExpression) {
      var functionDeclaration = self.parent;
      if (functionDeclaration is FunctionDeclaration) {
        return functionDeclaration;
      }
    }

    if (self is SimpleIdentifier) {
      var constructorDeclaration = self.parent;
      if (constructorDeclaration is ConstructorDeclaration) {
        if (constructorDeclaration.returnType == self) {
          return constructorDeclaration;
        }
      }
    }

    switch (self) {
      case ConstructorDeclaration():
      case FunctionDeclaration():
      case MethodDeclaration():
        return self;
    }

    return null;
  }

  FormalParameterList? get formalParameterList {
    var self = this;
    switch (self) {
      case ConstructorDeclaration():
        return self.parameters;
      case FunctionDeclaration():
        return self.functionExpression.parameters;
      case MethodDeclaration():
        return self.parameters;
    }
    return null;
  }
}

extension _FormalParameterListExtension on FormalParameterList {
  bool get hasTrailingComma {
    var last = parameters.lastOrNull;
    var nextToken = last?.endToken.next;
    return nextToken != null && nextToken.type == TokenType.COMMA;
  }
}

extension _SelectionExtension on Selection {
  AstNode? get invocation {
    var node = coveringNode;
    switch (node) {
      case RedirectingConstructorInvocation():
      case SuperConstructorInvocation():
        return node;
    }

    var parent = node.parent;
    switch (parent) {
      case MethodInvocation():
        if (isCoveredByNode(parent.methodName)) {
          return parent;
        }
      case RedirectingConstructorInvocation():
        if (isCoveredByToken(parent.thisKeyword)) {
          return parent;
        }
      case SuperConstructorInvocation():
        if (isCoveredByToken(parent.superKeyword)) {
          return parent;
        }
    }

    var parent2 = parent?.parent;
    switch (parent2) {
      case InstanceCreationExpression():
        if (isCoveredByNode(parent2.constructorName)) {
          return parent2;
        }
    }

    return null;
  }
}
