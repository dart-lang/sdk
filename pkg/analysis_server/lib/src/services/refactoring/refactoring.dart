// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/convert_getter_to_method.dart';
import 'package:analysis_server/src/services/refactoring/convert_method_to_getter.dart';
import 'package:analysis_server/src/services/refactoring/extract_local.dart';
import 'package:analysis_server/src/services/refactoring/extract_method.dart';
import 'package:analysis_server/src/services/refactoring/extract_widget.dart';
import 'package:analysis_server/src/services/refactoring/inline_local.dart';
import 'package:analysis_server/src/services/refactoring/inline_method.dart';
import 'package:analysis_server/src/services/refactoring/move_file.dart';
import 'package:analysis_server/src/services/refactoring/rename_class_member.dart';
import 'package:analysis_server/src/services/refactoring/rename_constructor.dart';
import 'package:analysis_server/src/services/refactoring/rename_extension_member.dart';
import 'package:analysis_server/src/services/refactoring/rename_import.dart';
import 'package:analysis_server/src/services/refactoring/rename_label.dart';
import 'package:analysis_server/src/services/refactoring/rename_library.dart';
import 'package:analysis_server/src/services/refactoring/rename_local.dart';
import 'package:analysis_server/src/services/refactoring/rename_unit_member.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show RefactoringMethodParameter, SourceChange;

/// [Refactoring] to convert getters into normal [MethodDeclaration]s.
abstract class ConvertGetterToMethodRefactoring implements Refactoring {
  /// Returns a new [ConvertMethodToGetterRefactoring] instance for converting
  /// [element] and all the corresponding hierarchy elements.
  factory ConvertGetterToMethodRefactoring(SearchEngine searchEngine,
      AnalysisSession session, PropertyAccessorElement element) {
    return ConvertGetterToMethodRefactoringImpl(searchEngine, session, element);
  }
}

/// [Refactoring] to convert normal [MethodDeclaration]s into getters.
abstract class ConvertMethodToGetterRefactoring implements Refactoring {
  /// Returns a new [ConvertMethodToGetterRefactoring] instance for converting
  /// [element] and all the corresponding hierarchy elements.
  factory ConvertMethodToGetterRefactoring(SearchEngine searchEngine,
      AnalysisSession session, ExecutableElement element) {
    return ConvertMethodToGetterRefactoringImpl(searchEngine, element);
  }
}

/// [Refactoring] to extract an expression into a local variable declaration.
abstract class ExtractLocalRefactoring implements Refactoring {
  /// Returns a new [ExtractLocalRefactoring] instance.
  factory ExtractLocalRefactoring(ResolvedUnitResult resolveResult,
      int selectionOffset, int selectionLength) = ExtractLocalRefactoringImpl;

  /// The lengths of the expressions that cover the specified selection,
  /// from the down most to the up most.
  List<int> get coveringExpressionLengths;

  /// The offsets of the expressions that cover the specified selection,
  /// from the down most to the up most.
  List<int> get coveringExpressionOffsets;

  /// True if all occurrences of the expression within the scope in which the
  /// variable will be defined should be replaced by a reference to the local
  /// variable. The expression used to initiate the refactoring will always be
  /// replaced.
  set extractAll(bool extractAll);

  /// The lengths of the expressions that would be replaced by a reference to
  /// the variable. The lengths correspond to the offsets. In other words, for a
  /// given expression, if the offset of that expression is offsets[i], then the
  /// length of that expression is lengths[i].
  List<int> get lengths;

  /// The name that the local variable should be given.
  set name(String name);

  /// The proposed names for the local variable.
  ///
  /// The first proposal should be used as the "best guess" (if it exists).
  List<String> get names;

  /// The offsets of the expressions that would be replaced by a reference to
  /// the variable.
  List<int> get offsets;

  /// Validates that the [name] is a valid identifier and is appropriate for
  /// local variable.
  ///
  /// It does not perform all the checks (such as checking for conflicts with
  /// any existing names in any of the scopes containing the current name), as
  /// many of these checks require search engine. Use [checkFinalConditions] for
  /// this level of checking.
  RefactoringStatus checkName();

  /// Return `true` if refactoring is available, possibly without checking all
  /// initial conditions.
  bool isAvailable();
}

/// [Refactoring] to extract an [Expression] or [Statement]s into a new method.
abstract class ExtractMethodRefactoring implements Refactoring {
  /// Returns a new [ExtractMethodRefactoring] instance.
  factory ExtractMethodRefactoring(
      SearchEngine searchEngine,
      ResolvedUnitResult resolveResult,
      int selectionOffset,
      int selectionLength) {
    return ExtractMethodRefactoringImpl(
        searchEngine, resolveResult, selectionOffset, selectionLength);
  }

  /// True if a getter could be created rather than a method.
  bool get canCreateGetter;

  /// True if a getter should be created rather than a method.
  set createGetter(bool createGetter);

  /// True if all occurrences of the expression or statements should be replaced
  /// by an invocation of the method. The expression or statements used to
  /// initiate the refactoring will always be replaced.
  set extractAll(bool extractAll);

  /// The lengths of the expressions or statements that would be replaced by an
  /// invocation of the method. The lengths correspond to the offsets.
  /// In other words, for a given expression (or block of statements), if the
  /// offset of that expression is offsets[i], then the length of that
  /// expression is lengths[i].
  List<int> get lengths;

  /// The name that the method should be given.
  set name(String name);

  /// The proposed names for the method.
  ///
  /// The first proposal should be used as the "best guess" (if it exists).
  List<String> get names;

  /// The offsets of the expressions or statements that would be replaced by an
  /// invocation of the method.
  List<int> get offsets;

  /// The proposed parameters for the method.
  List<RefactoringMethodParameter> get parameters;

  /// The parameters that should be defined for the method.
  set parameters(List<RefactoringMethodParameter> parameters);

  /// The proposed return type for the method.
  String get returnType;

  /// The return type that should be defined for the method.
  set returnType(String returnType);

  /// Validates that the [name] is a valid identifier and is appropriate for a
  /// method.
  ///
  /// It does not perform all the checks (such as checking for conflicts with
  /// any existing names in any of the scopes containing the current name), as
  /// many of these checks require search engine. Use [checkFinalConditions] for
  /// this level of checking.
  RefactoringStatus checkName();

  /// Return `true` if refactoring is available, possibly without checking all
  /// initial conditions.
  bool isAvailable();
}

/// [Refactoring] to extract a widget creation expression or a method returning
/// a widget, into a new stateless or stateful widget.
abstract class ExtractWidgetRefactoring implements Refactoring {
  /// Returns a new [ExtractWidgetRefactoring] instance.
  factory ExtractWidgetRefactoring(SearchEngine searchEngine,
      ResolvedUnitResult resolveResult, int offset, int length) {
    return ExtractWidgetRefactoringImpl(
        searchEngine, resolveResult, offset, length);
  }

  /// The name that the class should be given.
  set name(String name);

  /// Validates that the [name] is a valid identifier and is appropriate for a
  /// class.
  ///
  /// It does not perform all the checks (such as checking for conflicts with
  /// any existing names in any of the scopes containing the current name), as
  /// many of these checks require search engine. Use [checkFinalConditions] for
  /// this level of checking.
  RefactoringStatus checkName();

  /// Return `true` if refactoring is available, possibly without checking all
  /// initial conditions.
  bool isAvailable();
}

/// [Refactoring] to inline a local [VariableElement].
abstract class InlineLocalRefactoring implements Refactoring {
  /// Returns a new [InlineLocalRefactoring] instance.
  factory InlineLocalRefactoring(
      SearchEngine searchEngine, ResolvedUnitResult resolveResult, int offset) {
    return InlineLocalRefactoringImpl(searchEngine, resolveResult, offset);
  }

  /// Returns the number of references to the [VariableElement].
  int get referenceCount;

  /// Returns the name of the variable being inlined.
  String get variableName;
}

/// [Refactoring] to inline an [ExecutableElement].
abstract class InlineMethodRefactoring implements Refactoring {
  /// Returns a new [InlineMethodRefactoring] instance.
  factory InlineMethodRefactoring(
      SearchEngine searchEngine, ResolvedUnitResult resolveResult, int offset) {
    return InlineMethodRefactoringImpl(searchEngine, resolveResult, offset);
  }

  /// The name of the class enclosing the method being inlined.
  /// If not a class member is being inlined, then `null`.
  String get className;

  /// True if the method being inlined should be removed.
  /// It is an error if this field is `true` and [inlineAll] is `false`.
  set deleteSource(bool deleteSource);

  /// True if all invocations of the method should be inlined, or false if only
  /// the invocation site used to create this refactoring should be inlined.
  set inlineAll(bool inlineAll);

  /// True if the declaration of the method is selected.
  /// So, all references should be inlined.
  bool get isDeclaration;

  /// The name of the method (or function) being inlined.
  String get methodName;
}

/// [Refactoring] to move/rename a file.
abstract class MoveFileRefactoring implements Refactoring {
  /// Returns a new [MoveFileRefactoring] instance.
  factory MoveFileRefactoring(
      ResourceProvider resourceProvider,
      RefactoringWorkspace workspace,
      ResolvedUnitResult resolveResult,
      String oldFilePath) {
    return MoveFileRefactoringImpl(
        resourceProvider, workspace, resolveResult, oldFilePath);
  }

  /// The new file path to which the given file is being moved.
  set newFile(String newName);
}

/// Abstract interface for all refactorings.
abstract class Refactoring {
  /// The ids of source edits that are not known to be valid.
  ///
  /// An edit is not known to be valid if there was insufficient type
  /// information for the server to be able to determine whether or not the code
  /// needs to be modified, such as when a member is being renamed and there is
  /// a reference to a member from an unknown type. This field will be omitted
  /// if the change field is omitted or if there are no potential edits for the
  /// refactoring.
  List<String> get potentialEditIds;

  /// Returns the human readable name of this [Refactoring].
  String get refactoringName;

  /// Checks all conditions - [checkInitialConditions] and
  /// [checkFinalConditions] to decide if refactoring can be performed.
  Future<RefactoringStatus> checkAllConditions();

  /// Validates environment to check if this refactoring can be performed.
  ///
  /// This check may be slow, because many refactorings use search engine.
  Future<RefactoringStatus> checkFinalConditions();

  /// Validates arguments to check if this refactoring can be performed.
  ///
  /// This check should be quick because it is used often as arguments change.
  Future<RefactoringStatus> checkInitialConditions();

  /// Returns the [Change] to apply to perform this refactoring.
  Future<SourceChange> createChange();
}

/// Information about the workspace refactorings operate it.
class RefactoringWorkspace {
  final Iterable<AnalysisDriver> drivers;
  final SearchEngine searchEngine;

  RefactoringWorkspace(this.drivers, this.searchEngine);

  /// Whether the [element] is defined in a file that is in a context root.
  bool containsElement(Element element) {
    return containsFile(element.source.fullName);
  }

  /// Whether the file with the given [path] is in a context root.
  bool containsFile(String path) {
    return drivers.any((driver) {
      return driver.contextRoot.containsFile(path);
    });
  }

  /// Returns the drivers that have [path] in a context root.
  Iterable<AnalysisDriver> driversContaining(String path) {
    return drivers.where((driver) {
      return driver.contextRoot.containsFile(path);
    });
  }
}

/// Abstract [Refactoring] for renaming some [Element].
abstract class RenameRefactoring implements Refactoring {
  /// Returns a new [RenameRefactoring] instance for renaming [element],
  /// maybe `null` if there is no support for renaming [Element]s of the given
  /// type.
  factory RenameRefactoring(RefactoringWorkspace workspace,
      ResolvedUnitResult resolvedUnit, Element element) {
    var session = resolvedUnit.session;
    if (element == null) {
      return null;
    }
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    if (element.enclosingElement is CompilationUnitElement) {
      return RenameUnitMemberRefactoringImpl(workspace, resolvedUnit, element);
    }
    if (element is ConstructorElement) {
      return RenameConstructorRefactoringImpl(workspace, session, element);
    }
    if (element is ImportElement) {
      return RenameImportRefactoringImpl(workspace, session, element);
    }
    if (element is LabelElement) {
      return RenameLabelRefactoringImpl(workspace, element);
    }
    if (element is LibraryElement) {
      return RenameLibraryRefactoringImpl(workspace, element);
    }
    if (element is LocalElement) {
      return RenameLocalRefactoringImpl(workspace, element);
    }
    if (element.enclosingElement is ClassElement) {
      return RenameClassMemberRefactoringImpl(workspace, session, element);
    }
    if (element.enclosingElement is ExtensionElement) {
      return RenameExtensionMemberRefactoringImpl(workspace, session, element);
    }
    return null;
  }

  /// Returns the human-readable description of the kind of element being
  /// renamed (such as “class” or “function type alias”).
  String get elementKindName;

  /// Sets the new name for the [Element].
  set newName(String newName);

  /// Returns the old name of the [Element] being renamed.
  String get oldName;

  /// Validates that the [newName] is a valid identifier and is appropriate for
  /// the type of the [Element] being renamed.
  ///
  /// It does not perform all the checks (such as checking for conflicts with
  /// any existing names in any of the scopes containing the current name), as
  /// many of these checks require search engine. Use [checkFinalConditions] for
  /// this level of checking.
  RefactoringStatus checkNewName();

  /// Given a node/element, finds the best element to rename (for example
  /// the class when on the `new` keyword).
  static RenameRefactoringElement getElementToRename(
      AstNode node, Element element) {
    var offset = node.offset;
    var length = node.length;

    if (node is SimpleIdentifier && element is ParameterElement) {
      element = declaredParameterElement(node, element);
    }

    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }

    // Use the prefix offset/length when renaming an import directive.
    if (node is ImportDirective && element is ImportElement) {
      if (node.prefix != null) {
        offset = node.prefix.offset;
        length = node.prefix.length;
      } else {
        // -1 means the name does not exist yet.
        offset = -1;
        length = 0;
      }
    }

    // Rename the class when on `new` in an instance creation.
    if (node is InstanceCreationExpression) {
      var creation = node;
      var typeIdentifier = creation.constructorName.type.name;
      element = typeIdentifier.staticElement;
      offset = typeIdentifier.offset;
      length = typeIdentifier.length;
    }

    return RenameRefactoringElement(element, offset, length);
  }
}

class RenameRefactoringElement {
  final Element element;
  final int offset;
  final int length;

  RenameRefactoringElement(this.element, this.offset, this.length);
}
