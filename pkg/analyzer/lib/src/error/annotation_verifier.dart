// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta_meta.dart';

/// Helper for verifying the validity of annotations.
class AnnotationVerifier {
  final ErrorReporter _errorReporter;

  /// The current library.
  final LibraryElement2 _currentLibrary;

  /// The [WorkspacePackage] in which [_currentLibrary] is declared.
  final WorkspacePackage? _workspacePackage;

  /// Whether [_currentLibrary] is part of its containing package's public API.
  late final bool _inPackagePublicApi = _workspacePackage != null &&
      _workspacePackage
          .sourceIsInPublicApi(_currentLibrary.firstFragment.source);

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
      _checkFactory(node);
    } else if (element.isInternal) {
      _checkInternal(node);
    } else if (element.isLiteral) {
      _checkLiteral(node);
    } else if (element.isNonVirtual) {
      _checkNonVirtual(node);
    } else if (element.isReopen) {
      _checkReopen(node);
    } else if (element.isRedeclare) {
      _checkRedeclare(node);
    } else if (element.isUseResult) {
      _checkUseResult(node, element);
    } else if (element.isVisibleForTemplate ||
        element.isVisibleForTesting ||
        element.isVisibleForOverriding) {
      _checkVisibility(node, element);
    } else if (element.isVisibleOutsideTemplate) {
      _checkVisibility(node, element);
      _checkVisibleOutsideTemplate(node);
    }

    _checkKinds(node, parent, element);
  }

  /// Reports a warning at [node] if its parent is not a valid target for a
  /// `@factory` annotation.
  void _checkFactory(Annotation node) {
    var parent = node.parent;
    if (parent is! MethodDeclaration) {
      // Warning reported by `_checkKinds`.
      return;
    }
    var returnType = parent.returnType?.type;
    if (returnType is VoidType) {
      _errorReporter.atToken(
        parent.name,
        WarningCode.INVALID_FACTORY_METHOD_DECL,
        arguments: [parent.name.lexeme],
      );
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

    _errorReporter.atToken(
      parent.name,
      WarningCode.INVALID_FACTORY_METHOD_IMPL,
      arguments: [parent.name.lexeme],
    );
  }

  /// Reports a warning at [node] if its parent is not a valid target for an
  /// `@internal` annotation.
  void _checkInternal(Annotation node) {
    var parent = node.parent;
    var parentElement =
        parent.ifTypeOrNull<Declaration>()?.declaredFragment?.element;
    var parentElementIsPrivate = parentElement?.isPrivate ?? false;
    if (parent is TopLevelVariableDeclaration) {
      for (var variable in parent.variables.variables) {
        var element = variable.declaredTopLevelVariableElement;
        if (element.isPrivate) {
          _errorReporter.atNode(
            variable,
            WarningCode.INVALID_INTERNAL_ANNOTATION,
          );
        }
      }
    } else if (parent is FieldDeclaration) {
      for (var variable in parent.fields.variables) {
        var element = variable.declaredFieldElement;
        if (element.isPrivate) {
          _errorReporter.atNode(
            variable,
            WarningCode.INVALID_INTERNAL_ANNOTATION,
          );
        }
      }
    } else if (parent is ConstructorDeclaration) {
      var element = parent.declaredFragment!.element;
      var class_ = element.enclosingElement2;
      if (class_.isPrivate || parentElementIsPrivate) {
        _errorReporter.atNode(
          node.name,
          WarningCode.INVALID_INTERNAL_ANNOTATION,
        );
      }
    } else if (parentElementIsPrivate) {
      _errorReporter.atNode(
        node.name,
        WarningCode.INVALID_INTERNAL_ANNOTATION,
      );
    } else if (_inPackagePublicApi) {
      _errorReporter.atNode(
        node.name,
        WarningCode.INVALID_INTERNAL_ANNOTATION,
      );
    }
  }

  void _checkKinds(Annotation node, AstNode parent, ElementAnnotation element) {
    var kinds = element.targetKinds;
    if (kinds.isNotEmpty) {
      if (!_isValidTarget(parent, kinds)) {
        var invokedElement = element.element2!;
        var name = invokedElement.name3;
        if (invokedElement is ConstructorElement2) {
          var className = invokedElement.enclosingElement2.name3;
          if (name!.isEmpty) {
            name = className;
          } else {
            name = '$className.$name';
          }
        }
        var kindNames = kinds.map((kind) => kind.displayString).toList()
          ..sort();
        var validKinds = kindNames.commaSeparatedWithOr;
        _errorReporter.atNode(
          node.name,
          WarningCode.INVALID_ANNOTATION_TARGET,
          arguments: [name!, validKinds],
        );
        return;
      }
    }
  }

  /// Reports a warning if at [node] if its parent is not a valid target for a
  /// `@literal` annotation.
  void _checkLiteral(Annotation node) {
    var parent = node.parent;
    if (parent is! ConstructorDeclaration || parent.constKeyword == null) {
      _errorReporter.atNode(
        node.name,
        WarningCode.INVALID_LITERAL_ANNOTATION,
      );
    }
  }

  /// Reports a warning at [node] if its parent is not a valid target for a
  /// `@nonVirtual` annotation.
  void _checkNonVirtual(Annotation node) {
    var parent = node.parent;
    if (parent is FieldDeclaration) {
      if (parent.isStatic) {
        _errorReporter.atNode(
          node.name,
          WarningCode.INVALID_NON_VIRTUAL_ANNOTATION,
        );
      }
    } else if (parent is MethodDeclaration) {
      if (parent.parent is ExtensionDeclaration ||
          parent.parent is ExtensionTypeDeclaration ||
          parent.isStatic ||
          parent.isAbstract) {
        _errorReporter.atNode(
          node.name,
          WarningCode.INVALID_NON_VIRTUAL_ANNOTATION,
        );
      }
    } else {
      _errorReporter.atNode(
        node.name,
        WarningCode.INVALID_NON_VIRTUAL_ANNOTATION,
      );
    }
  }

  /// Reports a warning at [node] if its parent is not a valid target for a
  /// `@redeclare` annotation.
  void _checkRedeclare(Annotation node) {
    var parent = node.parent;
    if (parent.parent is! ExtensionTypeDeclaration ||
        parent is MethodDeclaration && parent.isStatic) {
      _errorReporter.atNode(
        node.name,
        WarningCode.INVALID_ANNOTATION_TARGET,
        arguments: [node.name.name, 'instance members of extension types'],
      );
    }
  }

  /// Reports a warning at [node] if its parent is not a valid target for a
  /// `@reopen` annotation.
  void _checkReopen(Annotation node) {
    ClassElement2? classElement;
    InterfaceElement2? superElement;

    var parent = node.parent;
    if (parent is ClassDeclaration) {
      classElement = parent.declaredFragment?.element;
      superElement = classElement?.supertype?.element3;
    } else if (parent is ClassTypeAlias) {
      classElement = parent.declaredFragment?.element;
      superElement = classElement?.supertype?.element3;
    } else {
      // If `parent` is neither of the above types, then `_checkKinds` will
      // report a warning.
      return;
    }

    if (classElement == null) {
      return;
    }
    if (superElement is! ClassElement2) {
      return;
    }
    if (classElement.isFinal ||
        classElement.isMixinClass ||
        classElement.isSealed) {
      _errorReporter.atNode(
        node.name,
        WarningCode.INVALID_REOPEN_ANNOTATION,
      );
      return;
    }
    if (classElement.library2 != superElement.library2) {
      _errorReporter.atNode(
        node.name,
        WarningCode.INVALID_REOPEN_ANNOTATION,
      );
      return;
    }
    if (classElement.isBase) {
      if (!superElement.isFinal && !superElement.isInterface) {
        _errorReporter.atNode(
          node.name,
          WarningCode.INVALID_REOPEN_ANNOTATION,
        );
        return;
      }
    } else if (!classElement.isBase &&
        !classElement.isFinal &&
        !classElement.isInterface &&
        !classElement.isSealed) {
      if (!superElement.isInterface) {
        _errorReporter.atNode(
          node.name,
          WarningCode.INVALID_REOPEN_ANNOTATION,
        );
        return;
      }
    }
  }

  /// Reports a warning if [node], a `@UseResult` annotation, references an
  /// unknown parameter as an argument to 'unless'.
  void _checkUseResult(Annotation node, ElementAnnotation element) {
    var parent = node.parent;
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
            : undefinedParameter.correspondingParameter?.name3;
        _errorReporter.atNode(
          undefinedParameter,
          WarningCode.UNDEFINED_REFERENCED_PARAMETER,
          arguments: [parameterName ?? undefinedParameter, name],
        );
      }
    }
  }

  /// Reports a warning at [node] if it is not a valid target for a
  /// visibility (`visibleForTemplate`, `visibleOutsideTemplate`,
  /// `visibleForTesting`, `visibleForOverride`) annotation.
  void _checkVisibility(Annotation node, ElementAnnotation element) {
    var parent = node.parent;
    if (parent is Declaration) {
      void reportInvalidAnnotation(String name) {
        // This method is only called on named elements, so it is safe to
        // assume that `declaredElement.name` is non-`null`.
        _errorReporter.atNode(
          node.name,
          WarningCode.INVALID_VISIBILITY_ANNOTATION,
          arguments: [name, node.name.name],
        );
      }

      void reportInvalidVisibleForOverriding() {
        _errorReporter.atNode(
          node.name,
          WarningCode.INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION,
        );
      }

      if (parent is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in parent.variables.variables) {
          var variableElement = variable.declaredTopLevelVariableElement;

          var variableName = variableElement.name3;
          if (variableName != null && Identifier.isPrivateName(variableName)) {
            reportInvalidAnnotation(variableName);
          }

          if (element.isVisibleForOverriding) {
            // Top-level variables can't be overridden.
            reportInvalidVisibleForOverriding();
          }
        }
      } else if (parent is FieldDeclaration) {
        for (VariableDeclaration variable in parent.fields.variables) {
          var fieldElement = variable.declaredFieldElement;
          if (parent.isStatic && element.isVisibleForOverriding) {
            reportInvalidVisibleForOverriding();
          }

          var fieldName = fieldElement.name3;
          if (fieldName != null && Identifier.isPrivateName(fieldName)) {
            reportInvalidAnnotation(fieldName);
          }
        }
      } else if (parent.declaredFragment?.element case var declaredElement?) {
        if (element.isVisibleForOverriding &&
            (!declaredElement.isInstanceMember ||
                declaredElement.enclosingElement2 is ExtensionTypeElement2)) {
          reportInvalidVisibleForOverriding();
        }

        var name = declaredElement.name3;
        if (name != null && Identifier.isPrivateName(name)) {
          reportInvalidAnnotation(name);
        }
      }
    } else {
      // Something other than a declaration was annotated. Whatever this is,
      // it probably warrants a Warning, but this has not been specified on
      // `visibleForTemplate` or `visibleForTesting`, so leave it alone for
      // now.
    }
  }

  /// Reports a warning at [node] if its parent is not a valid target for an
  /// `@visibleOutsideTemplate` annotation.
  void _checkVisibleOutsideTemplate(Annotation node) {
    void reportError() {
      _errorReporter.atNode(
        node.name,
        WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION,
      );
    }

    AstNode? containedDeclaration;
    switch (node.parent) {
      case ConstructorDeclaration constructorDeclaration:
        containedDeclaration = constructorDeclaration;
      case EnumConstantDeclaration enumConstant:
        containedDeclaration = enumConstant;
      case FieldDeclaration fieldDeclaration:
        containedDeclaration = fieldDeclaration;
      case MethodDeclaration methodDeclaration:
        containedDeclaration = methodDeclaration;
      default:
        reportError();
        return;
    }

    InterfaceElement2? declaredElement;
    switch (containedDeclaration.parent) {
      case ClassDeclaration classDeclaration:
        declaredElement = classDeclaration.declaredFragment?.element;
      case EnumDeclaration enumDeclaration:
        declaredElement = enumDeclaration.declaredFragment?.element;
      case MixinDeclaration mixinDeclaration:
        declaredElement = mixinDeclaration.declaredFragment?.element;
      default:
        reportError();
        return;
    }

    if (declaredElement == null) {
      reportError();
      return;
    }

    for (var annotation in declaredElement.metadata2.annotations) {
      if (annotation.isVisibleForTemplate) {
        return;
      }
    }

    reportError();
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
    // `TargetKind.overridableMember` is complex, so we handle it separately.
    if (kinds.contains(TargetKind.overridableMember)) {
      if ((target is FieldDeclaration && !target.isStatic) ||
          target is MethodDeclaration && !target.isStatic) {
        var parent = target.parent;
        if (parent is ClassDeclaration ||
            parent is ExtensionTypeDeclaration ||
            parent is MixinDeclaration) {
          // Members of `EnumDeclaration`s and `ExtensionDeclaration`s are not
          // overridable.
          return true;
        }
      }
    }

    return switch (target) {
      ClassDeclaration() =>
        kinds.contains(TargetKind.classType) || kinds.contains(TargetKind.type),
      ClassTypeAlias() =>
        kinds.contains(TargetKind.classType) || kinds.contains(TargetKind.type),
      ConstructorDeclaration() => kinds.contains(TargetKind.constructor),
      Directive() => kinds.contains(TargetKind.directive) ||
          (target.parent as CompilationUnit).directives.first == target &&
              kinds.contains(TargetKind.library),
      EnumConstantDeclaration() => kinds.contains(TargetKind.enumValue),
      EnumDeclaration() =>
        kinds.contains(TargetKind.enumType) || kinds.contains(TargetKind.type),
      ExtensionTypeDeclaration() => kinds.contains(TargetKind.extensionType),
      ExtensionDeclaration() => kinds.contains(TargetKind.extension),
      FieldDeclaration() => kinds.contains(TargetKind.field),
      FunctionDeclaration(isGetter: true) => kinds.contains(TargetKind.getter),
      FunctionDeclaration(isSetter: true) => kinds.contains(TargetKind.setter),
      FunctionDeclaration() => kinds.contains(TargetKind.function),
      MethodDeclaration(isGetter: true) => kinds.contains(TargetKind.getter),
      MethodDeclaration(isSetter: true) => kinds.contains(TargetKind.setter),
      MethodDeclaration() => kinds.contains(TargetKind.method),
      MixinDeclaration() =>
        kinds.contains(TargetKind.mixinType) || kinds.contains(TargetKind.type),
      FormalParameter() => kinds.contains(TargetKind.parameter) ||
          (target.isOptional && kinds.contains(TargetKind.optionalParameter)),
      FunctionTypeAlias() ||
      GenericTypeAlias() =>
        kinds.contains(TargetKind.typedefType) ||
            kinds.contains(TargetKind.type),
      TopLevelVariableDeclaration() =>
        kinds.contains(TargetKind.topLevelVariable),
      TypeParameter() => kinds.contains(TargetKind.typeParameter),
      // extension type Foo (int bar) {}
      //                     ^^^^^^^
      // This is not a parameter in the *traditional sense, but assume you want
      // to apply an annotation such as @mustBeConst to it; it makes sense that
      // this is a valid target.
      RepresentationDeclaration() => kinds.contains(TargetKind.parameter),
      _ => false,
    };
  }
}
