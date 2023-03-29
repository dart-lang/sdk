// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta_meta.dart';

/// Helper for verifying the validity of annotations.
class AnnotationVerifier {
  final ErrorReporter _errorReporter;

  /// The current library.
  final LibraryElement _currentLibrary;

  /// The [WorkspacePackage] in which [_currentLibrary] is declared.
  final WorkspacePackage? _workspacePackage;

  /// Whether [_currentLibrary] is part of its containing package's public API.
  late final bool _inPackagePublicApi = _workspacePackage != null &&
      _workspacePackage!.sourceIsInPublicApi(_currentLibrary.source);

  AnnotationVerifier(
    this._errorReporter,
    this._currentLibrary,
    this._workspacePackage,
  );

  void checkAnnotation(Annotation node) {
    var element = node.elementAnnotation;
    if (element == null) {
      return;
    }
    var parent = node.parent;
    if (element.isFactory) {
      _checkFactory(node, parent);
    } else if (element.isImmutable) {
      _checkImmutable(node, parent);
    } else if (element.isInternal) {
      _checkInternal(node, parent);
    } else if (element.isLiteral) {
      _checkLiteral(node, parent);
    } else if (element.isMustBeOverridden) {
      _checkMustBeOverridden(node, parent);
    } else if (element.isMustCallSuper) {
      _checkMustCallSuper(node, parent);
    } else if (element.isNonVirtual) {
      _checkNonVirtual(node, parent);
    } else if (element.isSealed) {
      _checkSealed(node, parent);
    } else if (element.isUseResult) {
      _checkUseResult(node, parent, element);
    } else if (element.isVisibleForTemplate ||
        element.isVisibleForTesting ||
        element.isVisibleForOverriding) {
      _checkVisibility(node, parent, element);
    }

    _checkKinds(node, parent, element);
  }

  /// Reports a warning if [parent] is not a valid target for a `@factory`
  /// annotation.
  void _checkFactory(AstNode node, AstNode parent) {
    if (parent is! MethodDeclaration) {
      _errorReporter
          .reportErrorForNode(WarningCode.INVALID_FACTORY_ANNOTATION, node, []);
      return;
    }
    var returnType = parent.returnType?.type;
    if (returnType is VoidType) {
      _errorReporter.reportErrorForToken(
          WarningCode.INVALID_FACTORY_METHOD_DECL,
          parent.name,
          [parent.name.lexeme]);
      return;
    }

    FunctionBody body = parent.body;
    if (body is EmptyFunctionBody) {
      // Abstract methods are OK.
      return;
    }

    // Returns `true` for expressions like `new Foo()` or `null`.
    bool factoryExpression(Expression? expression) =>
        expression is InstanceCreationExpression || expression is NullLiteral;

    if (body is ExpressionFunctionBody && factoryExpression(body.expression)) {
      return;
    } else if (body is BlockFunctionBody) {
      NodeList<Statement> statements = body.block.statements;
      if (statements.isNotEmpty) {
        Statement last = statements.last;
        if (last is ReturnStatement && factoryExpression(last.expression)) {
          return;
        }
      }
    }

    _errorReporter.reportErrorForToken(WarningCode.INVALID_FACTORY_METHOD_IMPL,
        parent.name, [parent.name.lexeme]);
  }

  /// Reports a warning if [parent] is not a valid target for an `@immutable`
  /// annotation.
  void _checkImmutable(AstNode node, AstNode parent) {
    // TODO(srawlins): Switch this annotation to use `TargetKinds`.
    if (parent is! ClassDeclaration &&
        parent is! ClassTypeAlias &&
        parent is! MixinDeclaration) {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_IMMUTABLE_ANNOTATION, node, []);
    }
  }

  /// Reports a warning at [node] if [parent] is not a valid target for an
  /// `@internal` annotation.
  void _checkInternal(AstNode node, AstNode parent) {
    var parentElement = parent is Declaration ? parent.declaredElement : null;
    var parentElementIsPrivate = parentElement?.isPrivate ?? false;
    if (parent is TopLevelVariableDeclaration) {
      for (var variable in parent.variables.variables) {
        var element = variable.declaredElement as TopLevelVariableElement;
        if (Identifier.isPrivateName(element.name)) {
          _errorReporter.reportErrorForNode(
              WarningCode.INVALID_INTERNAL_ANNOTATION, variable, []);
        }
      }
    } else if (parent is FieldDeclaration) {
      for (var variable in parent.fields.variables) {
        var element = variable.declaredElement as FieldElement;
        if (Identifier.isPrivateName(element.name)) {
          _errorReporter.reportErrorForNode(
              WarningCode.INVALID_INTERNAL_ANNOTATION, variable, []);
        }
      }
    } else if (parent is ConstructorDeclaration) {
      var class_ = parent.declaredElement!.enclosingElement;
      if (class_.isPrivate || parentElementIsPrivate) {
        _errorReporter.reportErrorForNode(
            WarningCode.INVALID_INTERNAL_ANNOTATION, node, []);
      }
    } else if (parentElementIsPrivate) {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_INTERNAL_ANNOTATION, node, []);
    } else if (_inPackagePublicApi) {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_INTERNAL_ANNOTATION, node, []);
    }
  }

  void _checkKinds(Annotation node, AstNode parent, ElementAnnotation element) {
    var kinds = element.targetKinds;
    if (kinds.isNotEmpty) {
      if (!_isValidTarget(parent, kinds)) {
        var invokedElement = element.element!;
        var name = invokedElement.name;
        if (invokedElement is ConstructorElement) {
          var className = invokedElement.enclosingElement.name;
          if (name!.isEmpty) {
            name = className;
          } else {
            name = '$className.$name';
          }
        }
        var kindNames = kinds.map((kind) => kind.displayString).toList()
          ..sort();
        var validKinds = kindNames.commaSeparatedWithOr;
        // Annotations always refer to named elements, so we can safely assume
        // that `name` is non-`null`.
        _errorReporter.reportErrorForNode(WarningCode.INVALID_ANNOTATION_TARGET,
            node.name, [name!, validKinds]);
        return;
      }
    }
  }

  /// Reports a warning if [parent] is not a valid target for a `@literal`
  /// annotation.
  void _checkLiteral(AstNode node, AstNode parent) {
    if (parent is! ConstructorDeclaration || parent.constKeyword == null) {
      _errorReporter
          .reportErrorForNode(WarningCode.INVALID_LITERAL_ANNOTATION, node, []);
    }
  }

  /// Reports a warning if [parent] is not a valid target for a
  /// `@mustBeOverridden` annotation.
  void _checkMustBeOverridden(Annotation node, AstNode parent) {
    if ((parent is MethodDeclaration && parent.isStatic) ||
        (parent is FieldDeclaration && parent.isStatic) ||
        parent.parent is ExtensionDeclaration ||
        parent.parent is EnumDeclaration) {
      _errorReporter.reportErrorForNode(
        WarningCode.INVALID_ANNOTATION_TARGET,
        node,
        [node.name.name, 'instance members of classes and mixins'],
      );
    }
  }

  /// Reports a warning if [parent] is not a valid target for a `@mustCallSuper`
  /// annotation.
  void _checkMustCallSuper(Annotation node, AstNode parent) {
    if ((parent is MethodDeclaration && parent.isStatic) ||
        (parent is FieldDeclaration && parent.isStatic) ||
        parent.parent is ExtensionDeclaration ||
        parent.parent is EnumDeclaration) {
      _errorReporter.reportErrorForNode(
        WarningCode.INVALID_ANNOTATION_TARGET,
        node,
        [node.name.name, 'instance members of classes and mixins'],
      );
    }
  }

  /// Reports a warning if [parent] is not a valid target for a `@nonVirtual`
  /// annotation.
  void _checkNonVirtual(AstNode node, AstNode parent) {
    if (parent is FieldDeclaration) {
      if (parent.isStatic) {
        _errorReporter.reportErrorForNode(
            WarningCode.INVALID_NON_VIRTUAL_ANNOTATION, node);
      }
    } else if (parent is MethodDeclaration) {
      if (parent.parent is ExtensionDeclaration ||
          parent.isStatic ||
          parent.isAbstract) {
        _errorReporter.reportErrorForNode(
            WarningCode.INVALID_NON_VIRTUAL_ANNOTATION, node);
      }
    } else {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_NON_VIRTUAL_ANNOTATION, node);
    }
  }

  /// Reports a warning if [parent] is not a valid target for a `@sealed`
  /// annotation.
  void _checkSealed(AstNode node, AstNode parent) {
    if (!(parent is ClassDeclaration || parent is ClassTypeAlias)) {
      _errorReporter.reportErrorForNode(
          WarningCode.INVALID_SEALED_ANNOTATION, node);
    }
  }

  /// Reports a warning if [parent] is not a valid target for a `@useResult`
  /// annotation.
  void _checkUseResult(
      Annotation node, AstNode parent, ElementAnnotation element) {
    // Check for a reference to an undefined parameter in a `@UseResult.unless`
    // annotation.
    var undefinedParameter =
        _findUndefinedUseResultParameter(element, node, parent);
    if (undefinedParameter != null) {
      String? name;
      if (parent is FunctionDeclaration) {
        name = parent.name.lexeme;
      } else if (parent is MethodDeclaration) {
        name = parent.name.lexeme;
      }
      if (name != null) {
        var parameterName = undefinedParameter is SimpleStringLiteral
            ? undefinedParameter.value
            : undefinedParameter.staticParameterElement?.name;
        _errorReporter.reportErrorForNode(
            WarningCode.UNDEFINED_REFERENCED_PARAMETER,
            undefinedParameter,
            [parameterName ?? undefinedParameter, name]);
      }
    }
  }

  /// Reports a warning at [node] if it is not a valid target for a
  /// visibility (`visibleForTemplate`, `visibileForTesting`,
  /// `visibleForOverride`) annotation.
  void _checkVisibility(
      Annotation node, AstNode parent, ElementAnnotation element) {
    if (parent is Declaration) {
      void reportInvalidAnnotation(Element declaredElement) {
        // This method is only called on named elements, so it is safe to
        // assume that `declaredElement.name` is non-`null`.
        _errorReporter.reportErrorForNode(
            WarningCode.INVALID_VISIBILITY_ANNOTATION,
            node,
            [declaredElement.name!, node.name.name]);
      }

      void reportInvalidVisibleForOverriding(Element declaredElement) {
        _errorReporter.reportErrorForNode(
            WarningCode.INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION, node);
      }

      if (parent is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in parent.variables.variables) {
          var variableElement =
              variable.declaredElement as TopLevelVariableElement;

          if (Identifier.isPrivateName(variableElement.name)) {
            reportInvalidAnnotation(variableElement);
          }

          if (element.isVisibleForOverriding == true) {
            // Top-level variables can't be overridden.
            reportInvalidVisibleForOverriding(variableElement);
          }
        }
      } else if (parent is FieldDeclaration) {
        for (VariableDeclaration variable in parent.fields.variables) {
          var fieldElement = variable.declaredElement as FieldElement;
          if (parent.isStatic && element.isVisibleForOverriding == true) {
            reportInvalidVisibleForOverriding(fieldElement);
          }

          if (Identifier.isPrivateName(fieldElement.name)) {
            reportInvalidAnnotation(fieldElement);
          }
        }
      } else if (parent.declaredElement != null) {
        final declaredElement = parent.declaredElement!;
        if (element.isVisibleForOverriding &&
            !declaredElement.isInstanceMember) {
          reportInvalidVisibleForOverriding(declaredElement);
        }

        var name = declaredElement.name;
        if (name != null && Identifier.isPrivateName(name)) {
          reportInvalidAnnotation(declaredElement);
        }
      }
    } else {
      // Something other than a declaration was annotated. Whatever this is,
      // it probably warrants a Warning, but this has not been specified on
      // `visibleForTemplate` or `visibleForTesting`, so leave it alone for
      // now.
    }
  }

  /// Returns an expression (for error-reporting purposes) associated with a
  /// `@useResult` `unless` argument, if the associated parameter is undefined.
  Expression? _findUndefinedUseResultParameter(
      ElementAnnotation element, Annotation node, AstNode parent) {
    var constructorName = node.name;
    if (constructorName is! PrefixedIdentifier ||
        constructorName.identifier.name != 'unless') {
      return null;
    }

    var unlessParam = element
        .computeConstantValue()
        ?.getField('parameterDefined')
        ?.toStringValue();
    if (unlessParam == null) {
      return null;
    }

    Expression? checkParams(FormalParameterList? parameterList) {
      if (parameterList == null) {
        return null;
      }

      for (var parameter in parameterList.parameters) {
        if (parameter.name?.lexeme == unlessParam) {
          return null;
        }
      }

      // Find and return the parameter value node.
      var arguments = node.arguments?.arguments;
      if (arguments == null) {
        return null;
      }

      for (var arg in arguments) {
        if (arg is NamedExpression &&
            arg.name.label.name == 'parameterDefined') {
          return arg.expression;
        }
      }

      return null;
    }

    if (parent is FunctionDeclarationImpl) {
      return checkParams(parent.functionExpression.parameters);
    }
    if (parent is MethodDeclarationImpl) {
      return checkParams(parent.parameters);
    }

    return null;
  }

  /// Returns whether it is valid to have an annotation on the given [target]
  /// when the annotation is marked as being valid for the given [kinds] of
  /// targets.
  bool _isValidTarget(AstNode target, Set<TargetKind> kinds) {
    if (target is ClassDeclaration) {
      return kinds.contains(TargetKind.classType) ||
          kinds.contains(TargetKind.type);
    } else if (target is Directive) {
      return (target.parent as CompilationUnit).directives.first == target &&
          kinds.contains(TargetKind.library);
    } else if (target is EnumDeclaration) {
      return kinds.contains(TargetKind.enumType) ||
          kinds.contains(TargetKind.type);
    } else if (target is ExtensionDeclaration) {
      return kinds.contains(TargetKind.extension);
    } else if (target is FieldDeclaration) {
      return kinds.contains(TargetKind.field);
    } else if (target is FunctionDeclaration) {
      if (target.isGetter) {
        return kinds.contains(TargetKind.getter);
      }
      if (target.isSetter) {
        return kinds.contains(TargetKind.setter);
      }
      return kinds.contains(TargetKind.function);
    } else if (target is MethodDeclaration) {
      if (target.isGetter) {
        return kinds.contains(TargetKind.getter);
      }
      if (target.isSetter) {
        return kinds.contains(TargetKind.setter);
      }
      return kinds.contains(TargetKind.method);
    } else if (target is MixinDeclaration) {
      return kinds.contains(TargetKind.mixinType) ||
          kinds.contains(TargetKind.type);
    } else if (target is FormalParameter) {
      return kinds.contains(TargetKind.parameter);
    } else if (target is FunctionTypeAlias || target is GenericTypeAlias) {
      return kinds.contains(TargetKind.typedefType) ||
          kinds.contains(TargetKind.type);
    } else if (target is TopLevelVariableDeclaration) {
      return kinds.contains(TargetKind.topLevelVariable);
    }
    return false;
  }
}
