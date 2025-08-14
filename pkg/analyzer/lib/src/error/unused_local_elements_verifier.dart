// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart'
    show JoinPatternVariableElementImpl, MetadataImpl;
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/member.dart'
    show SubstitutedExecutableElementImpl;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';

/// An [AstVisitor] that fills [UsedLocalElements].
class GatherUsedLocalElementsVisitor extends RecursiveAstVisitor<void> {
  final UsedLocalElements usedElements = UsedLocalElements();

  final LibraryElement _enclosingLibrary;
  InterfaceElement? _enclosingClass;
  ExecutableElement? _enclosingExec;

  /// Non-null when the visitor is inside an [IsExpression]'s type.
  IsExpression? _enclosingIsExpression;

  /// Non-null when the visitor is inside a [VariableDeclarationList]'s type.
  VariableDeclarationList? _enclosingVariableDeclaration;

  GatherUsedLocalElementsVisitor(this._enclosingLibrary);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var element = node.element;
    if (element != null) {
      usedElements.members.add(element);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var element = node.element;
    usedElements.addMember(element);
    super.visitBinaryExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    var exceptionParameter = node.exceptionParameter;
    var stackTraceParameter = node.stackTraceParameter;
    if (exceptionParameter != null) {
      var element = exceptionParameter.declaredFragment?.element;
      usedElements.addCatchException(element);
      if (stackTraceParameter != null || node.onKeyword == null) {
        usedElements.addElement(element);
      }
    }
    if (stackTraceParameter != null) {
      var element = stackTraceParameter.declaredFragment?.element;
      usedElements.addCatchStackTrace(element);
    }
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var element = node.declaredFragment?.element;
    if (element != null) {
      if (element.metadata.hasJS) {
        usedElements.addElement(element);
      }
    }

    var enclosingClassOld = _enclosingClass;
    try {
      _enclosingClass = node.declaredFragment?.element;
      super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = enclosingClassOld;
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var element = node.declaredFragment!.element;
    var redirectedConstructor = node.redirectedConstructor;
    if (redirectedConstructor != null) {
      var redirectedElement = redirectedConstructor.element;
      if (redirectedElement != null) {
        // TODO(scheglov): Only if not _isPubliclyAccessible
        _matchParameters(
          element.formalParameters,
          redirectedElement.formalParameters,
          (first, second) {
            usedElements.addElement(second);
          },
        );
      }
    }

    super.visitConstructorDeclaration(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var element = node.declaredFragment?.element;
    if (element is SuperFormalParameterElement) {
      usedElements.addElement(element.superConstructorParameter);
    }

    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    usedElements.addElement(node.constructorElement?.baseElement);

    var argumentList = node.arguments?.argumentList;
    if (argumentList != null) {
      _addParametersForArguments(argumentList);
    }

    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var enclosingExecOld = _enclosingExec;
    try {
      _enclosingExec = node.declaredFragment?.element;
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingExec = enclosingExecOld;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      usedElements.addElement(node.declaredFragment?.element);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    usedElements.addElement(node.element);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (!Identifier.isPrivateName(node.name.lexeme)) {
      var type = node.type.type;
      if (type is InterfaceTypeImpl) {
        for (var constructor in type.constructors) {
          if (!Identifier.isPrivateName(constructor.name!)) {
            usedElements.addElement(constructor);
          }
        }
      }
    }
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    var element = node.writeOrReadElement;
    usedElements.addMember(element);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _addParametersForArguments(node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    var enclosingIsExpressionOld = _enclosingIsExpression;
    node.expression.accept(this);
    try {
      _enclosingIsExpression = node;
      node.type.accept(this);
    } finally {
      _enclosingIsExpression = enclosingIsExpressionOld;
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var enclosingExecOld = _enclosingExec;
    try {
      _enclosingExec = node.declaredFragment?.element;
      super.visitMethodDeclaration(node);
    } finally {
      _enclosingExec = enclosingExecOld;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var function = node.methodName.element;
    if (function is LocalFunctionElement ||
        function is MethodElement ||
        function is TopLevelFunctionElement) {
      _addParametersForArguments(node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _useIdentifierElement(node.element, parent: node);
    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    usedElements.addMember(node.element);
    usedElements.addReadMember(node.element);
    super.visitPatternField(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    var element = node.element;
    usedElements.addMember(element);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var element = node.element;
    usedElements.addMember(element);
    super.visitPrefixExpression(node);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    usedElements.addMember(node.element);
    usedElements.addReadMember(node.element);
    super.visitRelationalPattern(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    if (_inCommentReference(node)) {
      return;
    }
    var element = node.writeOrReadElement;
    // Store un-parameterized members.
    if (element is SubstitutedExecutableElementImpl) {
      element = element.baseElement;
    }
    var variable = element.ifTypeOrNull<PropertyAccessorElement>()?.variable;
    bool isIdentifierRead = _isReadIdentifier(node);
    if (element is PropertyAccessorElement &&
        isIdentifierRead &&
        variable is TopLevelVariableElement) {
      if (element.isSynthetic) {
        usedElements.addElement(variable);
      } else {
        usedElements.members.add(element);
        _addMemberAndCorrespondingGetter(element);
      }
    } else if (element is LocalVariableElement) {
      if (isIdentifierRead) {
        usedElements.addElement(element);
      }
    } else {
      var parent = node.parent!;
      _useIdentifierElement(node.readElement, parent: parent);
      _useIdentifierElement(node.writeElement, parent: parent);
      _useIdentifierElement(node.element, parent: parent);
      var grandparent = parent.parent;
      // If [node] is a tear-off, assume all parameters are used.
      var functionReferenceIsCall =
          (element is ExecutableElement && parent is MethodInvocation) ||
          // named constructor
          (element is ConstructorElement &&
              parent is ConstructorName &&
              grandparent is InstanceCreationExpression) ||
          // unnamed constructor
          (element is InterfaceElement &&
              grandparent is ConstructorName &&
              grandparent.parent is InstanceCreationExpression);
      if (element is ExecutableElement &&
          isIdentifierRead &&
          !functionReferenceIsCall) {
        for (var parameter in element.formalParameters) {
          usedElements.addElement(parameter);
        }
      }
      var enclosingElement = element?.enclosingElement;
      if (element == null) {
        if (isIdentifierRead) {
          usedElements.unresolvedReadMembers.add(node.name);
        }
      } else if (enclosingElement is EnumElement && element.name == 'values') {
        // If the 'values' static accessor of the enum is accessed, then all of
        // the enum values have been read.
        for (var field in enclosingElement.fields) {
          if (field.isEnumConstant) {
            usedElements.readMembers.add(field.getter!);
          }
        }
      } else if ((enclosingElement is InterfaceElement ||
              enclosingElement is ExtensionElement) &&
          !identical(element, _enclosingExec)) {
        usedElements.members.add(element);
        if (isIdentifierRead) {
          _addMemberAndCorrespondingGetter(element);
        }
      }
    }
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _addParametersForArguments(node.argumentList);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    node.metadata.accept(this);
    var enclosingVariableDeclarationOld = _enclosingVariableDeclaration;
    try {
      _enclosingVariableDeclaration = node;
      node.type?.accept(this);
    } finally {
      _enclosingVariableDeclaration = enclosingVariableDeclarationOld;
    }
    node.variables.accept(this);
  }

  /// Add [element] as a used member and, if [element] is a setter, add its
  /// corresponding getter as a used member.
  void _addMemberAndCorrespondingGetter(Element element) {
    if (element is SetterElement) {
      usedElements.addMember(element.correspondingGetter);
      usedElements.addReadMember(element.correspondingGetter);
    } else {
      usedElements.addReadMember(element);
    }
  }

  void _addParametersForArguments(ArgumentList argumentList) {
    for (var argument in argumentList.arguments) {
      var parameter = argument.correspondingParameter;
      usedElements.addElement(parameter);
    }
  }

  /// Marks the [element] as used in the library.
  void _useIdentifierElement(Element? element, {required AstNode parent}) {
    if (element == null) {
      return;
    }
    // Check if [element] is a local element.
    if (!identical(element.library, _enclosingLibrary)) {
      return;
    }
    // Ignore references to an element from itself.
    if (identical(element, _enclosingClass)) {
      return;
    }
    if (identical(element, _enclosingExec)) {
      return;
    }
    // Ignore places where the element is not actually used.
    // TODO(scheglov): Do we need 'parent' at all?
    if (parent is NamedType) {
      if (element is InterfaceElement) {
        var enclosingVariableDeclaration = _enclosingVariableDeclaration;
        if (enclosingVariableDeclaration != null) {
          // If it's a field's type, it still counts as used.
          if (enclosingVariableDeclaration.parent is! FieldDeclaration) {
            return;
          }
        } else if (_enclosingIsExpression != null) {
          // An interface type found in an `is` expression is not used.
          return;
        }
      }
    }
    // OK
    usedElements.addElement(element);
  }

  /// Returns whether [identifier] is found in a [CommentReference].
  static bool _inCommentReference(SimpleIdentifier identifier) {
    var parent = identifier.parent;
    return parent is CommentReference || parent?.parent is CommentReference;
  }

  /// Returns whether the value of [node] is _only_ being read at this position.
  ///
  /// Returns `false` if [node] is not a read access, or if [node] is a combined
  /// read/write access.
  static bool _isReadIdentifier(SimpleIdentifier node) {
    // Not reading at all.
    if (!node.inGetterContext()) {
      return false;
    }
    // Check if useless reading.
    AstNode parent = node.parent!;

    if (parent.parent is ExpressionStatement) {
      if (parent is PrefixExpression || parent is PostfixExpression) {
        // v++;
        // ++v;
        return false;
      }
      if (parent is AssignmentExpression && parent.leftHandSide == node) {
        // v ??= doSomething();
        //   vs.
        // v += 2;
        var operatorType = parent.operator.type;
        return operatorType == TokenType.QUESTION_QUESTION_EQ;
      }
    }
    // OK
    return true;
  }

  /// Invokes [f] for corresponding positional and named parameters.
  /// Ignores parameters that don't have a corresponding pair.
  // TODO(scheglov): There might be a better place for this function.
  static void _matchParameters(
    List<FormalParameterElement> firstList,
    List<FormalParameterElement> secondList,
    void Function(FormalParameterElement first, FormalParameterElement second)
    f,
  ) {
    Map<String, FormalParameterElement>? firstNamed;
    Map<String, FormalParameterElement>? secondNamed;
    var firstPositional = <FormalParameterElement>[];
    var secondPositional = <FormalParameterElement>[];
    for (var element in firstList) {
      if (element.isNamed) {
        (firstNamed ??= {})[element.name!] = element;
      } else {
        firstPositional.add(element);
      }
    }
    for (var element in secondList) {
      if (element.isNamed) {
        (secondNamed ??= {})[element.name!] = element;
      } else {
        secondPositional.add(element);
      }
    }

    var positionalLength = math.min(
      firstPositional.length,
      secondPositional.length,
    );
    for (var i = 0; i < positionalLength; i++) {
      f(firstPositional[i], secondPositional[i]);
    }

    if (firstNamed != null && secondNamed != null) {
      for (var firstEntry in firstNamed.entries) {
        var second = secondNamed[firstEntry.key];
        if (second != null) {
          f(firstEntry.value, second);
        }
      }
    }
  }
}

/// Instances of the class [UnusedLocalElementsVerifier] traverse an AST
/// looking for cases of [WarningCode.unusedElement],
/// [WarningCode.unusedField],
/// [WarningCode.unusedLocalVariable], etc.
class UnusedLocalElementsVerifier extends RecursiveAstVisitor<void> {
  /// The error listener to which errors will be reported.
  final DiagnosticListener _diagnosticListener;

  /// The elements know to be used.
  final UsedLocalElements _usedElements;

  /// The URI of the library being verified.
  final Uri _libraryUri;

  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  /// The current set of pattern variable elements, used to track whether _all_
  /// within a [PatternVariableDeclaration] are used.
  List<BindPatternVariableElement>? _patternVariableElements;

  /// Create a new instance of the [UnusedLocalElementsVerifier].
  UnusedLocalElementsVerifier(
    this._diagnosticListener,
    this._usedElements,
    LibraryElement library,
  ) : _libraryUri = library.uri,
      _wildCardVariablesEnabled = library.featureSet.isEnabled(
        Feature.wildcard_variables,
      );

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    _visitLocalVariableElement(node.declaredFragment!.element);
    super.visitCatchClauseParameter(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var declaredElement = node.declaredFragment!.element;
    _visitClassElement(declaredElement);

    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.name != null) {
      var declaredElement = node.declaredFragment!.element;
      _visitConstructorElement(declaredElement);
    }

    super.visitConstructorDeclaration(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _visitLocalVariableElement(node.declaredFragment!.element);
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(
    covariant DeclaredVariablePatternImpl node,
  ) {
    var declaredElement = node.declaredFragment!.element;
    if (!declaredElement.isDuplicate) {
      var patternVariableElements = _patternVariableElements;
      if (patternVariableElements != null) {
        patternVariableElements.add(declaredElement);
      } else {
        _visitLocalVariableElement(declaredElement);
      }
    }

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    var declaredElement = node.declaredFragment!.element;
    _visitFieldElement(declaredElement);

    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    var declaredElement = node.declaredFragment!.element;
    _visitClassElement(declaredElement);

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    var declaredElement = node.declaredFragment!.element;
    _visitClassElement(declaredElement);

    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var field in node.fields.variables) {
      _visitFieldElement(field.declaredFragment!.element as FieldElement);
    }

    super.visitFieldDeclaration(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var fragment in node.parameterFragments) {
      var element = fragment!.element;
      if (!_isUsedElement(element)) {
        _reportDiagnosticForElement(
          WarningCode.unusedElementParameter,
          element,
          [element.displayName],
        );
      }
    }
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    for (var variable in node.variables.variables) {
      _visitLocalVariableElement(
        variable.declaredFragment!.element as LocalVariableElement,
      );
    }

    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement is LocalFunctionElement) {
      _visitLocalFunctionElement(declaredElement);
    } else if (declaredElement is PropertyAccessorElement) {
      _visitPropertyAccessorElement(declaredElement);
    } else if (declaredElement is TopLevelFunctionElement) {
      _visitTopLevelFunctionElement(declaredElement);
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    var declaredElement = node.declaredFragment!.element;
    _visitTypeAliasElement(declaredElement);

    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    var declaredElement = node.declaredFragment?.element as TypeAliasElement;
    _visitTypeAliasElement(declaredElement);

    super.visitGenericTypeAlias(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement is MethodElement) {
      _visitMethodElement(declaredElement);
    } else if (declaredElement is PropertyAccessorElement) {
      _visitPropertyAccessorElement(declaredElement);
    }

    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var declaredElement = node.declaredFragment!.element;
    _visitClassElement(declaredElement);

    super.visitMixinDeclaration(node);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    var outerPatternVariableElements = _patternVariableElements;
    var patternVariableElements = _patternVariableElements = [];
    try {
      super.visitPatternVariableDeclaration(node);
      var elementsToReport = <BindPatternVariableElement>[];
      for (var element in patternVariableElements) {
        var isUsed = _usedElements.elements.contains(element);
        // Don't report any of the declared variables as unused, if any of them
        // are used. This allows for a consistent set of patterns to be used,
        // in a case where some declared variables are used, and some are just
        // present to help match, for example, a record shape, or a list, etc.
        if (isUsed) {
          return;
        }
        if (!_isNamedWildcard(element)) {
          elementsToReport.add(element);
        }
      }
      for (var element in elementsToReport) {
        _reportDiagnosticForElement(WarningCode.unusedLocalVariable, element, [
          element.displayName,
        ]);
      }
    } finally {
      _patternVariableElements = outerPatternVariableElements;
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      var element = node.element;
      if (element is ConstructorElement) {
        _visitConstructorElement(element);
      } else if (element is FieldElement) {
        _visitFieldElement(element);
      } else if (element is LocalFunctionElement) {
        _visitLocalFunctionElement(element);
      } else if (element is InterfaceElement) {
        _visitClassElement(element);
      } else if (element is LocalVariableElement) {
        _visitLocalVariableElement(element);
      } else if (element is MethodElement) {
        _visitMethodElement(element);
      } else if (element is PropertyAccessorElement) {
        _visitPropertyAccessorElement(element);
      } else if (element is TopLevelVariableElement) {
        _visitTopLevelVariableElement(element);
      } else if (element is TypeAliasElement) {
        _visitTypeAliasElement(element);
      }
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var variable in node.variables.variables) {
      _visitTopLevelVariableElement(
        variable.declaredFragment?.element as TopLevelVariableElement,
      );
    }

    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    for (var variable in node.variables.variables) {
      _visitLocalVariableElement(
        variable.declaredFragment!.element as LocalVariableElement,
      );
    }

    super.visitVariableDeclarationStatement(node);
  }

  /// Returns the parameter element, if any, that corresponds to the given
  /// parameter in the overridden element.
  FormalParameterElement? _getCorrespondingParameter(
    FormalParameterElement parameter,
    ExecutableElement overridden,
    ExecutableElement enclosingElement,
  ) {
    FormalParameterElement? correspondingParameter;
    if (parameter.isNamed) {
      correspondingParameter = overridden.formalParameters.firstWhereOrNull(
        (p) => p.name == parameter.name,
      );
    } else {
      var parameterIndex = 0;
      var parameterCount = enclosingElement.formalParameters.length;
      while (parameterIndex < parameterCount) {
        if (enclosingElement.formalParameters[parameterIndex] == parameter) {
          break;
        }
        parameterIndex++;
      }
      if (overridden.formalParameters.length <= parameterIndex) {
        // Something is wrong with the overridden element. Ignore it.
        return null;
      }
      correspondingParameter = overridden.formalParameters[parameterIndex];
    }
    return correspondingParameter;
  }

  /// Returns whether the name of [element] should be treated as a wildcard.
  bool _isNamedWildcard(LocalElement element) {
    if (_wildCardVariablesEnabled) {
      return element.isWildcardVariable;
    } else {
      var name = element.name;
      if (name == null) return false;
      return name.codeUnits.every((e) => e == 0x5F /* '_' */);
    }
  }

  bool _isPrivateClassOrExtension(Element element) =>
      (element is InterfaceElement || element is ExtensionElement) &&
      element.isPrivate;

  /// Returns whether [element] is accessible outside of the library in which
  /// it is declared.
  bool _isPubliclyAccessible(ExecutableElement element) {
    if (element.isPrivate) {
      return false;
    }
    var enclosingElement = element.enclosingElement;

    if (enclosingElement is EnumElement) {
      if (element is ConstructorElement && element.isGenerative) {
        return false;
      }
    }
    if (enclosingElement is InterfaceElement) {
      if (enclosingElement.isPrivate) {
        if (element.isStatic || element is ConstructorElement) {
          return false;
        }
      }
    }

    if (enclosingElement is ExtensionElement) {
      return enclosingElement.isPublic;
    }

    return true;
  }

  /// Returns whether [element] is a private element which is read somewhere in
  /// the library.
  bool _isReadMember(Element element) {
    bool elementIsStaticVariable =
        element is VariableElement && element.isStatic;
    if (element.isPublic) {
      if (_isPrivateClassOrExtension(element.enclosingElement!) &&
          elementIsStaticVariable) {
        // Public static fields of private classes, mixins, and extensions are
        // inaccessible from outside the library in which they are declared.
      } else {
        return true;
      }
    }
    if (element.isSynthetic) {
      return true;
    }
    if (element is FieldElement) {
      var getter = element.getter;
      if (getter == null) {
        return false;
      }
      element = getter;
    }
    if (_usedElements.readMembers.contains(element) ||
        _usedElements.unresolvedReadMembers.contains(element.name)) {
      return true;
    }

    if (elementIsStaticVariable) {
      return false;
    }
    return _overridesUsedElement(element);
  }

  bool _isUsedElement(Element element) {
    if (element.isSynthetic) {
      return true;
    }
    if (element is LocalVariableElement ||
        element is LocalFunctionElement && !element.isStatic) {
      // local variable or function
    } else if (element is FormalParameterElement) {
      var enclosingElement = element.enclosingElement;
      // Only report unused parameters of constructors, methods, and top-level
      // functions.
      if (enclosingElement is! ConstructorElement &&
          enclosingElement is! MethodElement &&
          enclosingElement is! TopLevelFunctionElement) {
        return true;
      }

      if (!element.isOptional) {
        return true;
      }
      if (enclosingElement is ConstructorElement &&
          enclosingElement.enclosingElement.typeParameters.isNotEmpty) {
        // There is an issue matching arguments of instance creation
        // expressions for generic classes with parameters, so for now,
        // consider every parameter of a constructor of a generic class
        // "used". See https://github.com/dart-lang/sdk/issues/47839.
        return true;
      }
      if (enclosingElement is ConstructorElement) {
        var superConstructor = enclosingElement.superConstructor;
        if (superConstructor != null) {
          var correspondingParameter = _getCorrespondingParameter(
            element,
            superConstructor,
            enclosingElement,
          );
          if (correspondingParameter != null) {
            if (correspondingParameter.isRequiredNamed ||
                correspondingParameter.isRequiredPositional) {
              return true;
            }
          }
        }
      }
      if (enclosingElement is ExecutableElement) {
        if (enclosingElement.typeParameters.isNotEmpty) {
          // There is an issue matching arguments of generic function
          // invocations with parameters, so for now, consider every parameter
          // of a generic function "used". See
          // https://github.com/dart-lang/sdk/issues/47839.
          return true;
        }
        if (_isPubliclyAccessible(enclosingElement)) {
          return true;
        }
        if (_overridesUsedParameter(element, enclosingElement)) {
          return true;
        }
      }
    } else {
      if (element.isPublic) {
        return true;
      }
    }
    if (_hasPragmaVmEntryPoint(element)) {
      return true;
    }
    return _usedElements.elements.contains(element);
  }

  bool _isUsedMember(ExecutableElement element) {
    if (_isPubliclyAccessible(element)) {
      return true;
    }
    if (element.isSynthetic) {
      return true;
    }
    if (_hasPragmaVmEntryPoint(element)) {
      return true;
    }
    if (_usedElements.members.contains(element)) {
      return true;
    }
    if (_usedElements.elements.contains(element)) {
      return true;
    }

    return _overridesUsedElement(element);
  }

  Iterable<ExecutableElement> _overriddenElements(Element element) {
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is InterfaceElement) {
      var elementName = element.name;
      if (elementName != null) {
        Name name = Name(_libraryUri, elementName);
        var overridden = enclosingElement.getOverridden(name);
        if (overridden == null) {
          return const [];
        }
        return overridden.map(
          (e) => (e is SubstitutedExecutableElementImpl) ? e.baseElement : e,
        );
      }
    }
    return [];
  }

  /// Check if [element] is a class member which overrides a super class's class
  /// member which is used.
  bool _overridesUsedElement(Element element) {
    return _overriddenElements(
      element,
    ).any((e) => _usedElements.members.contains(e) || _overridesUsedElement(e));
  }

  /// Check if [element] is a parameter of a method which overrides a super
  /// class's method in which the corresponding parameter is used.
  bool _overridesUsedParameter(
    FormalParameterElement element,
    ExecutableElement enclosingElement,
  ) {
    var overriddenElements = _overriddenElements(enclosingElement);
    for (var overridden in overriddenElements) {
      FormalParameterElement? correspondingParameter =
          _getCorrespondingParameter(element, overridden, enclosingElement);
      // The parameter was added in the override.
      if (correspondingParameter == null) {
        continue;
      }
      // The parameter was made optional in the override.
      if (correspondingParameter.isRequiredNamed ||
          correspondingParameter.isRequiredPositional) {
        return true;
      }
      if (_usedElements.elements.contains(correspondingParameter)) {
        return true;
      }
    }
    return false;
  }

  void _reportDiagnosticForElement(
    DiagnosticCode code,
    Element? element,
    List<Object> arguments,
  ) {
    if (element != null) {
      var fragment = element.firstFragment;
      _diagnosticListener.onDiagnostic(
        Diagnostic.tmp(
          source: fragment.libraryFragment!.source,
          offset:
              fragment.nameOffset ??
              fragment.enclosingFragment?.nameOffset ??
              0,
          length: fragment.name?.length ?? 0,
          diagnosticCode: code,
          arguments: arguments,
        ),
      );
    }
  }

  void _visitClassElement(InterfaceElement element) {
    if (!_isUsedElement(element)) {
      _reportDiagnosticForElement(WarningCode.unusedElement, element, [
        element.displayName,
      ]);
    }
  }

  void _visitConstructorElement(ConstructorElement element) {
    // Only complain about an unused constructor if it is not the only
    // constructor in the class. A single unused, private constructor may serve
    // the purpose of preventing the class from being extended. In serving this
    // purpose, the constructor is "used."
    if (element.enclosingElement.constructors.length > 1 &&
        !_isUsedMember(element)) {
      _reportDiagnosticForElement(WarningCode.unusedElement, element, [
        element.displayName,
      ]);
    }
  }

  void _visitFieldElement(FieldElement element) {
    if (!_isReadMember(element)) {
      _reportDiagnosticForElement(WarningCode.unusedField, element, [
        element.displayName,
      ]);
    }
  }

  void _visitLocalFunctionElement(LocalFunctionElement element) {
    if (!_isUsedElement(element)) {
      if (_wildCardVariablesEnabled && _isNamedWildcard(element)) return;
      _reportDiagnosticForElement(WarningCode.unusedElement, element, [
        element.displayName,
      ]);
    }
  }

  void _visitLocalVariableElement(LocalVariableElement element) {
    if (!_isUsedElement(element) && !_isNamedWildcard(element)) {
      DiagnosticCode code;
      if (_usedElements.isCatchException(element)) {
        code = WarningCode.unusedCatchClause;
      } else if (_usedElements.isCatchStackTrace(element)) {
        code = WarningCode.unusedCatchStack;
      } else {
        code = WarningCode.unusedLocalVariable;
      }
      _reportDiagnosticForElement(code, element, [element.displayName]);
    }
  }

  void _visitMethodElement(MethodElement element) {
    if (!_isUsedMember(element)) {
      _reportDiagnosticForElement(WarningCode.unusedElement, element, [
        element.displayName,
      ]);
    }
  }

  void _visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!_isUsedMember(element)) {
      _reportDiagnosticForElement(WarningCode.unusedElement, element, [
        element.displayName,
      ]);
    }
  }

  void _visitTopLevelFunctionElement(TopLevelFunctionElement element) {
    if (!_isUsedElement(element)) {
      _reportDiagnosticForElement(WarningCode.unusedElement, element, [
        element.displayName,
      ]);
    }
  }

  void _visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (!_isUsedElement(element)) {
      _reportDiagnosticForElement(WarningCode.unusedElement, element, [
        element.displayName,
      ]);
    }
  }

  void _visitTypeAliasElement(TypeAliasElement element) {
    if (!_isUsedElement(element)) {
      _reportDiagnosticForElement(WarningCode.unusedElement, element, [
        element.displayName,
      ]);
    }
  }

  static bool _hasPragmaVmEntryPoint(Element element) {
    return (element.metadata as MetadataImpl).hasPragmaVmEntryPoint;
  }
}

/// A container with sets of used [Element]s.
/// All these elements are defined in a single compilation unit or a library.
class UsedLocalElements {
  /// Resolved, locally defined elements that are used or potentially can be
  /// used.
  final HashSet<Element> elements = HashSet<Element>();

  /// [LocalVariableElement]s that represent exceptions in [CatchClause]s.
  final HashSet<LocalVariableElement> catchExceptionElements =
      HashSet<LocalVariableElement>();

  /// [LocalVariableElement]s that represent stack traces in [CatchClause]s.
  final HashSet<LocalVariableElement> catchStackTraceElements =
      HashSet<LocalVariableElement>();

  /// Resolved class members that are referenced in the library.
  final HashSet<Element> members = HashSet<Element>();

  /// Resolved class members that are read in the library.
  final HashSet<Element> readMembers = HashSet<Element>();

  /// Unresolved class members that are read in the library.
  final HashSet<String> unresolvedReadMembers = HashSet<String>();

  UsedLocalElements();

  factory UsedLocalElements.merge(List<UsedLocalElements> parts) {
    UsedLocalElements result = UsedLocalElements();
    int length = parts.length;
    for (int i = 0; i < length; i++) {
      UsedLocalElements part = parts[i];
      result.elements.addAll(part.elements);
      result.catchExceptionElements.addAll(part.catchExceptionElements);
      result.catchStackTraceElements.addAll(part.catchStackTraceElements);
      result.members.addAll(part.members);
      result.readMembers.addAll(part.readMembers);
      result.unresolvedReadMembers.addAll(part.unresolvedReadMembers);
    }
    return result;
  }

  void addCatchException(Element? element) {
    if (element is LocalVariableElement) {
      catchExceptionElements.add(element);
    }
  }

  void addCatchStackTrace(Element? element) {
    if (element is LocalVariableElement) {
      catchStackTraceElements.add(element);
    }
  }

  void addElement(Element? element) {
    if (element is JoinPatternVariableElementImpl) {
      elements.addAll(element.transitiveVariables);
    } else if (element is SubstitutedExecutableElementImpl) {
      elements.add(element.baseElement);
    } else if (element != null) {
      elements.add(element);
    }
  }

  void addMember(Element? element) {
    // Store un-parameterized members.
    if (element is SubstitutedExecutableElementImpl) {
      element = element.baseElement;
    }

    if (element != null) {
      members.add(element);
    }
  }

  void addReadMember(Element? element) {
    // Store un-parameterized members.
    if (element is SubstitutedExecutableElementImpl) {
      element = element.baseElement;
    }

    if (element != null) {
      readMembers.add(element);
    }
  }

  bool isCatchException(LocalVariableElement element) {
    return catchExceptionElements.contains(element);
  }

  bool isCatchStackTrace(LocalVariableElement element) {
    return catchStackTraceElements.contains(element);
  }
}
