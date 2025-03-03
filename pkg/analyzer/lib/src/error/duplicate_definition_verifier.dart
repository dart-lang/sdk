// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: analyzer_use_new_elements

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/file_analysis.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

class DuplicateDefinitionVerifier {
  final LibraryElementImpl _currentLibrary;
  final ErrorReporter _errorReporter;
  final DuplicationDefinitionContext context;

  final DiagnosticFactory _diagnosticFactory = DiagnosticFactory();

  DuplicateDefinitionVerifier(
    this._currentLibrary,
    this._errorReporter,
    this.context,
  );

  /// Check that the exception and stack trace parameters have different names.
  void checkCatchClause(CatchClause node) {
    var exceptionParameter = node.exceptionParameter;
    var stackTraceParameter = node.stackTraceParameter;
    if (exceptionParameter != null && stackTraceParameter != null) {
      var element = exceptionParameter.declaredElement2;
      if (element != null && element.isWildcardVariable) return;
      String exceptionName = exceptionParameter.name.lexeme;
      if (exceptionName == stackTraceParameter.name.lexeme) {
        _errorReporter.reportError(_diagnosticFactory
            .duplicateDefinitionForNodes(
                _errorReporter.source,
                CompileTimeErrorCode.DUPLICATE_DEFINITION,
                stackTraceParameter,
                exceptionParameter,
                [exceptionName]));
      }
    }
  }

  /// Check that the given list of variable declarations does not define
  /// multiple variables of the same name.
  void checkForVariables(VariableDeclarationListImpl node) {
    var definedNames = HashMap<String, ElementImpl>();
    for (var variable in node.variables) {
      _checkDuplicateIdentifier(definedNames, variable.name,
          element: variable.declaredFragment!);
    }
  }

  /// Check that all of the parameters have unique names.
  void checkParameters(FormalParameterListImpl node) {
    var definedNames = HashMap<String, ElementImpl>();
    for (var parameter in node.parameters) {
      var identifier = parameter.name;
      if (identifier != null) {
        // The identifier can be null if this is a parameter list for a generic
        // function type.

        // Skip wildcard `super._`.
        if (!_isSuperFormalWildcard(parameter, identifier)) {
          _checkDuplicateIdentifier(definedNames, identifier,
              element: parameter.declaredFragment!);
        }
      }
    }
  }

  /// Check that all of the variables have unique names.
  void checkStatements(List<StatementImpl> statements) {
    var definedNames = HashMap<String, ElementImpl>();
    for (var statement in statements) {
      if (statement is VariableDeclarationStatementImpl) {
        for (var variable in statement.variables.variables) {
          _checkDuplicateIdentifier(definedNames, variable.name,
              element: variable.declaredFragment!);
        }
      } else if (statement is FunctionDeclarationStatementImpl) {
        if (!_isWildCardFunction(statement)) {
          _checkDuplicateIdentifier(
            definedNames,
            statement.functionDeclaration.name,
            element: statement.functionDeclaration.declaredFragment!,
          );
        }
      } else if (statement is PatternVariableDeclarationStatementImpl) {
        for (var variable in statement.declaration.elements) {
          _checkDuplicateIdentifier(definedNames, variable.node.name,
              element: variable.asElement);
        }
      }
    }
  }

  /// Check that all of the parameters have unique names.
  void checkTypeParameters(TypeParameterListImpl node) {
    var definedNames = HashMap<String, ElementImpl>();
    for (var parameter in node.typeParameters) {
      _checkDuplicateIdentifier(definedNames, parameter.name,
          element: parameter.declaredFragment!);
    }
  }

  /// Check that there are no members with the same name.
  void checkUnit(CompilationUnitImpl node) {
    var fragment = node.declaredFragment!;
    var definedGetters = <String, Element>{};
    var definedSetters = <String, Element>{};

    void addWithoutChecking(CompilationUnitElement element) {
      for (PropertyAccessorElement accessor in element.accessors) {
        String name = accessor.name;
        if (accessor.isSetter) {
          name += '=';
        }
        definedGetters[name] = accessor;
      }
      for (var class_ in element.classes) {
        definedGetters[class_.name] = class_;
      }
      for (var enum_ in element.enums) {
        definedGetters[enum_.name] = enum_;
      }
      for (var extension_ in element.extensions) {
        if (extension_.name case var name?) {
          definedGetters[name] = extension_;
        }
      }
      for (var extensionType in element.extensionTypes) {
        definedGetters[extensionType.name] = extensionType;
      }
      for (var function in element.functions) {
        definedGetters[function.name] = function;
      }
      for (var mixin_ in element.mixins) {
        definedGetters[mixin_.name] = mixin_;
      }
      for (var variable in element.topLevelVariables) {
        definedGetters[variable.name] = variable;
        if (!variable.isFinal && !variable.isConst) {
          definedGetters['${variable.name}='] = variable;
        }
      }
      for (var alias in element.typeAliases) {
        definedGetters[alias.name] = alias;
      }
    }

    var libraryDeclarations = _currentLibrary.libraryDeclarations;
    for (var importPrefix in fragment.libraryImportPrefixes) {
      var name = importPrefix.name;
      if (libraryDeclarations.withName(name) case var existing?) {
        _errorReporter.reportError(
          _diagnosticFactory.duplicateDefinition(
            CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER,
            importPrefix.asElement2,
            existing,
            [name],
          ),
        );
      }
    }

    var element = node.declaredFragment!;
    if (element != _currentLibrary.definingCompilationUnit) {
      addWithoutChecking(_currentLibrary.definingCompilationUnit);
      for (var unitElement in _currentLibrary.units) {
        if (element == unitElement) {
          break;
        }
        addWithoutChecking(unitElement);
      }
    }
    for (var member in node.declarations) {
      if (member is ExtensionDeclarationImpl) {
        var identifier = member.name;
        if (identifier != null) {
          _checkDuplicateIdentifier(definedGetters, identifier,
              element: member.declaredFragment!, setterScope: definedSetters);
        }
      } else if (member is NamedCompilationUnitMemberImpl) {
        _checkDuplicateIdentifier(definedGetters, member.name,
            element: member.declaredFragment as ElementImpl,
            setterScope: definedSetters);
      } else if (member is TopLevelVariableDeclarationImpl) {
        for (var variable in member.variables.variables) {
          _checkDuplicateIdentifier(definedGetters, variable.name,
              element: variable.declaredFragment!, setterScope: definedSetters);
        }
      }
    }
  }

  /// Check whether the given [element] defined by the [identifier] is already
  /// in one of the scopes - [getterScope] or [setterScope], and produce an
  /// error if it is.
  void _checkDuplicateIdentifier(
      Map<String, Element> getterScope, Token identifier,
      {required ElementImpl element, Map<String, Element>? setterScope}) {
    if (identifier.isSynthetic || element.isWildcardVariable) {
      return;
    }

    switch (element) {
      case ExecutableElementImpl _:
        if (element.isAugmentation) return;
      case FieldElementImpl _:
        if (element.isAugmentation) return;
      case InstanceElementImpl _:
        if (element.isAugmentation) return;
      case TypeAliasElementImpl _:
        if (element.isAugmentation) return;
      case TopLevelVariableElementImpl _:
        if (element.isAugmentation) return;
    }

    // Fields define getters and setters, so check them separately.
    if (element is PropertyInducingElementImpl) {
      _checkDuplicateIdentifier(getterScope, identifier,
          element: element.getter!, setterScope: setterScope);
      var setter = element.setter;
      if (setter != null && setter.isSynthetic) {
        _checkDuplicateIdentifier(getterScope, identifier,
            element: setter, setterScope: setterScope);
      }
      return;
    }

    ErrorCode getError(Element previous, Element current) {
      if (previous is FieldFormalParameterElement &&
          current is FieldFormalParameterElement) {
        return CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER;
      }
      return CompileTimeErrorCode.DUPLICATE_DEFINITION;
    }

    var name = identifier.lexeme;
    if (element is MethodElementImpl) {
      name = element.name;
    }

    var previous = getterScope[name];
    if (previous != null) {
      if (!_isGetterSetterPair(element, previous)) {
        _errorReporter.reportError(_diagnosticFactory.duplicateDefinition(
          getError(previous, element),
          element.asElement2!,
          previous.asElement2!,
          [name],
        ));
      }
    } else {
      getterScope[name] = element;
    }

    if (setterScope != null) {
      if (element is PropertyAccessorElementImpl && element.isSetter) {
        previous = setterScope[name];
        if (previous != null) {
          _errorReporter.reportError(_diagnosticFactory.duplicateDefinition(
            getError(previous, element),
            element.asElement2,
            previous.asElement2!,
            [name],
          ));
        } else {
          setterScope[name] = element;
        }
      }
    }
  }

  bool _isSuperFormalWildcard(FormalParameter parameter, Token identifier) {
    if (parameter is DefaultFormalParameter) {
      parameter = parameter.parameter;
    }
    return parameter is SuperFormalParameter &&
        identifier.lexeme == '_' &&
        _currentLibrary.featureSet.isEnabled(Feature.wildcard_variables);
  }

  bool _isWildCardFunction(FunctionDeclarationStatement statement) =>
      statement.functionDeclaration.name.lexeme == '_' &&
      _currentLibrary.hasWildcardVariablesFeatureEnabled;

  static bool _isGetterSetterPair(Element a, Element b) {
    if (a is PropertyAccessorElement && b is PropertyAccessorElement) {
      return a.isGetter && b.isSetter || a.isSetter && b.isGetter;
    }
    return false;
  }
}

/// Information to pass from declarations to augmentations.
class DuplicationDefinitionContext {
  final Map<InstanceElement, _InstanceElementContext> _instanceElementContexts =
      {};
}

class MemberDuplicateDefinitionVerifier {
  final InheritanceManager3 _inheritanceManager;
  final LibraryElement _currentLibrary;
  final CompilationUnitElementImpl _currentUnit;
  final ErrorReporter _errorReporter;
  final DuplicationDefinitionContext context;
  final DiagnosticFactory _diagnosticFactory = DiagnosticFactory();

  MemberDuplicateDefinitionVerifier._(
    this._inheritanceManager,
    this._currentLibrary,
    this._currentUnit,
    this._errorReporter,
    this.context,
  );

  void _checkClass(ClassDeclarationImpl node) {
    _checkClassMembers(node.declaredFragment!, node.members);
  }

  /// Check that there are no members with the same name.
  void _checkClassMembers(
    InstanceElement fragment,
    List<ClassMemberImpl> members,
  ) {
    var declarationElement = fragment.augmented.firstFragment;

    var elementContext = _getElementContext(declarationElement);
    var constructorNames = elementContext.constructorNames;
    var instanceGetters = elementContext.instanceGetters;
    var instanceSetters = elementContext.instanceSetters;
    var staticGetters = elementContext.staticGetters;
    var staticSetters = elementContext.staticSetters;

    for (var member in members) {
      switch (member) {
        case ConstructorDeclarationImpl():
          // Augmentations are not declarations, can have multiple.
          if (member.augmentKeyword != null) {
            continue;
          }
          if (member.returnType.name != declarationElement.name) {
            // [member] is erroneous; do not count it as a possible duplicate.
            continue;
          }
          var name = member.name?.lexeme ?? '';
          if (name == 'new') {
            name = '';
          }
          if (!constructorNames.add(name)) {
            if (name.isEmpty) {
              _errorReporter.atConstructorDeclaration(
                member,
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
              );
            } else {
              _errorReporter.atConstructorDeclaration(
                member,
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
                arguments: [name],
              );
            }
          }
        case FieldDeclarationImpl():
          for (var field in member.fields.variables) {
            _checkDuplicateIdentifier(
              member.isStatic ? staticGetters : instanceGetters,
              field.name,
              element: field.declaredFragment!,
              setterScope: member.isStatic ? staticSetters : instanceSetters,
            );
            if (fragment is EnumElement) {
              _checkValuesDeclarationInEnum(field.name);
            }
          }
        case MethodDeclarationImpl():
          _checkDuplicateIdentifier(
            member.isStatic ? staticGetters : instanceGetters,
            member.name,
            element: member.declaredFragment!,
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
          if (fragment is EnumElement) {
            if (!(member.isStatic && member.isSetter)) {
              _checkValuesDeclarationInEnum(member.name);
            }
          }
      }
    }

    if (declarationElement is InterfaceElement) {
      _checkConflictingConstructorAndStatic(
        interfaceElement: declarationElement,
        staticGetters: staticGetters,
        staticSetters: staticSetters,
      );
    }
  }

  void _checkClassStatic(
    InstanceElement fragment,
    List<ClassMember> members,
  ) {
    var declarationElement = fragment.augmented.firstFragment;

    var elementContext = _getElementContext(declarationElement);
    var instanceGetters = elementContext.instanceGetters;
    var instanceSetters = elementContext.instanceSetters;

    // Check for local static members conflicting with local instance members.
    // TODO(scheglov): This code is duplicated for enums. But for classes it is
    // separated also into ErrorVerifier - where we check inherited.
    for (ClassMember member in members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          for (VariableDeclaration field in member.fields.variables) {
            var identifier = field.name;
            String name = identifier.lexeme;
            if (instanceGetters.containsKey(name) ||
                instanceSetters.containsKey(name)) {
              if (declarationElement is InterfaceElement) {
                String className = declarationElement.name;
                _errorReporter.atToken(
                  identifier,
                  CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
                  arguments: [className, name, className],
                );
              }
            }
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          var identifier = member.name;
          String name = identifier.lexeme;
          if (instanceGetters.containsKey(name) ||
              instanceSetters.containsKey(name)) {
            if (declarationElement is InterfaceElement) {
              String className = declarationElement.name;
              _errorReporter.atToken(
                identifier,
                CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
                arguments: [className, name, className],
              );
            }
          }
        }
      }
    }
  }

  void _checkConflictingConstructorAndStatic({
    required InterfaceElement interfaceElement,
    required Map<String, Element> staticGetters,
    required Map<String, Element> staticSetters,
  }) {
    for (var constructor in interfaceElement.constructors) {
      var name = constructor.name;
      var staticMember = staticGetters[name] ?? staticSetters[name];
      if (staticMember is PropertyAccessorElement) {
        CompileTimeErrorCode errorCode;
        if (staticMember.isSynthetic) {
          errorCode =
              CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD;
        } else if (staticMember.isGetter) {
          errorCode =
              CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER;
        } else {
          errorCode =
              CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER;
        }
        _errorReporter.atElement2(
          constructor.asElement2,
          errorCode,
          arguments: [name],
        );
      } else if (staticMember is MethodElement) {
        _errorReporter.atElement2(
          constructor.asElement2,
          CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD,
          arguments: [name],
        );
      }
    }
  }

  /// Check whether the given [element] defined by the [identifier] is already
  /// in one of the scopes - [getterScope] or [setterScope], and produce an
  /// error if it is.
  void _checkDuplicateIdentifier(
      Map<String, Element> getterScope, Token identifier,
      {required Element element, Map<String, Element>? setterScope}) {
    if (identifier.isSynthetic || element.isWildcardVariable) {
      return;
    }

    switch (element) {
      case ExecutableElement _:
        if (element.isAugmentation) return;
      case FieldElement _:
        if (element.isAugmentation) return;
      case InstanceElement _:
        if (element.isAugmentation) return;
      case TypeAliasElement _:
        if (element.isAugmentation) return;
      case TopLevelVariableElement _:
        if (element.isAugmentation) return;
    }

    // Fields define getters and setters, so check them separately.
    if (element is PropertyInducingElement) {
      _checkDuplicateIdentifier(getterScope, identifier,
          element: element.getter!, setterScope: setterScope);
      var setter = element.setter;
      if (setter != null && setter.isSynthetic) {
        _checkDuplicateIdentifier(getterScope, identifier,
            element: setter, setterScope: setterScope);
      }
      return;
    }

    var name = switch (element) {
      MethodElement() => element.name,
      _ => identifier.lexeme,
    };

    var previous = getterScope[name];
    if (previous != null) {
      if (!_isGetterSetterPair(element, previous)) {
        _errorReporter.reportError(
          _diagnosticFactory.duplicateDefinition(
            CompileTimeErrorCode.DUPLICATE_DEFINITION,
            element.asElement2!,
            previous.asElement2!,
            [name],
          ),
        );
      }
    } else {
      getterScope[name] = element;
    }

    if (setterScope != null) {
      if (element is PropertyAccessorElement && element.isSetter) {
        previous = setterScope[name];
        if (previous != null) {
          _errorReporter.reportError(
            _diagnosticFactory.duplicateDefinition(
              CompileTimeErrorCode.DUPLICATE_DEFINITION,
              element.asElement2,
              previous.asElement2!,
              [name],
            ),
          );
        } else {
          setterScope[name] = element;
        }
      }
    }
  }

  /// Check that there are no members with the same name.
  void _checkEnum(EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var declarationElement = fragment.augmented.firstFragment;
    var declarationName = declarationElement.name;

    var elementContext = _getElementContext(declarationElement);
    var staticGetters = elementContext.staticGetters;

    for (var constant in node.constants) {
      if (constant.name.lexeme == declarationName) {
        _errorReporter.atToken(
          constant.name,
          CompileTimeErrorCode.ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING,
        );
      }
      _checkDuplicateIdentifier(staticGetters, constant.name,
          element: constant.declaredFragment!);
      _checkValuesDeclarationInEnum(constant.name);
    }

    _checkClassMembers(fragment, node.members);

    if (declarationName == 'values') {
      _errorReporter.atToken(
        node.name,
        CompileTimeErrorCode.ENUM_WITH_NAME_VALUES,
      );
    }

    for (var accessor in fragment.accessors) {
      if (accessor.isStatic) {
        continue;
      }
      if (accessor.source != _currentUnit.source) {
        continue;
      }
      var baseName = accessor.displayName;
      var inherited = _getInheritedMember(declarationElement, baseName);
      if (inherited is MethodElement) {
        _errorReporter.atElement2(
          accessor.asElement2,
          CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD,
          arguments: [
            declarationElement.displayName,
            baseName,
            inherited.enclosingElement3.displayName,
          ],
        );
      }
    }

    for (var method in fragment.methods) {
      if (method.isStatic) {
        continue;
      }
      if (method.source != _currentUnit.source) {
        continue;
      }
      var baseName = method.displayName;
      var inherited = _getInheritedMember(declarationElement, baseName);
      if (inherited is PropertyAccessorElement) {
        _errorReporter.atElement2(
          method.asElement2,
          CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD,
          arguments: [
            declarationElement.displayName,
            baseName,
            inherited.enclosingElement3.displayName,
          ],
        );
      }
    }
  }

  void _checkEnumStatic(EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var declarationElement = fragment.augmented.firstFragment;
    var declarationName = declarationElement.name;

    for (var accessor in fragment.accessors) {
      if (accessor.source != _currentUnit.source) {
        continue;
      }
      var baseName = accessor.displayName;
      if (accessor.isStatic) {
        var instance = _getInterfaceMember(declarationElement, baseName);
        if (instance != null && baseName != 'values') {
          _errorReporter.atElement2(
            accessor.asElement2,
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
            arguments: [declarationName, baseName, declarationName],
          );
        }
      }
    }

    for (var method in fragment.methods) {
      if (method.source != _currentUnit.source) {
        continue;
      }
      var baseName = method.displayName;
      if (method.isStatic) {
        var instance = _getInterfaceMember(declarationElement, baseName);
        if (instance != null) {
          _errorReporter.atElement2(
            method.asElement2,
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
            arguments: [declarationName, baseName, declarationName],
          );
        }
      }
    }
  }

  /// Check that there are no members with the same name.
  void _checkExtension(covariant ExtensionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    _checkClassMembers(fragment, node.members);
  }

  void _checkExtensionStatic(covariant ExtensionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var declarationElement = fragment.augmented.firstFragment;

    var elementContext = _getElementContext(declarationElement);
    var instanceGetters = elementContext.instanceGetters;
    var instanceSetters = elementContext.instanceSetters;

    for (var member in node.members) {
      if (member is FieldDeclarationImpl) {
        if (member.isStatic) {
          for (var field in member.fields.variables) {
            var identifier = field.name;
            var name = identifier.lexeme;
            if (instanceGetters.containsKey(name) ||
                instanceSetters.containsKey(name)) {
              _errorReporter.atToken(
                identifier,
                CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE,
                arguments: [name],
              );
            }
          }
        }
      } else if (member is MethodDeclarationImpl) {
        if (member.isStatic) {
          var identifier = member.name;
          var name = identifier.lexeme;
          if (instanceGetters.containsKey(name) ||
              instanceSetters.containsKey(name)) {
            _errorReporter.atToken(
              identifier,
              CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE,
              arguments: [name],
            );
          }
        }
      }
    }
  }

  void _checkExtensionType(ExtensionTypeDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.augmented.firstFragment;
    var primaryConstructorName = element.constructors.first.name;
    var representationGetter = element.representation.getter!;
    _getElementContext(element)
      ..constructorNames.add(primaryConstructorName)
      ..instanceGetters[representationGetter.name] = representationGetter;

    _checkClassMembers(element, node.members);
  }

  void _checkMixin(MixinDeclarationImpl node) {
    _checkClassMembers(node.declaredFragment!, node.members);
  }

  void _checkUnit(CompilationUnitImpl node) {
    for (var node in node.declarations) {
      switch (node) {
        case ClassDeclarationImpl():
          _checkClass(node);
        case ExtensionDeclarationImpl():
          _checkExtension(node);
        case EnumDeclarationImpl():
          _checkEnum(node);
        case ExtensionTypeDeclarationImpl():
          _checkExtensionType(node);
        case MixinDeclarationImpl():
          _checkMixin(node);
        case ClassTypeAliasImpl():
        case FunctionDeclarationImpl():
        case FunctionTypeAliasImpl():
        case GenericTypeAliasImpl():
        case TopLevelVariableDeclarationImpl():
        // Do nothing.
      }
    }
  }

  void _checkUnitStatic(CompilationUnitImpl node) {
    for (var declaration in node.declarations) {
      switch (declaration) {
        case ClassDeclarationImpl():
          var fragment = declaration.declaredFragment!;
          _checkClassStatic(fragment, declaration.members);
        case EnumDeclarationImpl():
          _checkEnumStatic(declaration);
        case ExtensionDeclarationImpl():
          _checkExtensionStatic(declaration);
        case ExtensionTypeDeclarationImpl():
          var fragment = declaration.declaredFragment!;
          _checkClassStatic(fragment, declaration.members);
        case MixinDeclarationImpl():
          var fragment = declaration.declaredFragment!;
          _checkClassStatic(fragment, declaration.members);
        case ClassTypeAliasImpl():
        case FunctionDeclarationImpl():
        case FunctionTypeAliasImpl():
        case GenericTypeAliasImpl():
        case TopLevelVariableDeclarationImpl():
        // Do nothing.
      }
    }
  }

  void _checkValuesDeclarationInEnum(Token name) {
    if (name.lexeme == 'values') {
      _errorReporter.atToken(
        name,
        CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM,
      );
    }
  }

  _InstanceElementContext _getElementContext(InstanceElement element) {
    return context._instanceElementContexts[element] ??=
        _InstanceElementContext();
  }

  ExecutableElement? _getInheritedMember(
      InterfaceElement element, String baseName) {
    var libraryUri = _currentLibrary.source.uri;

    var getterName = Name(libraryUri, baseName);
    var getter = _inheritanceManager.getInherited2(element, getterName);
    if (getter != null) {
      return getter;
    }

    var setterName = Name(libraryUri, '$baseName=');
    return _inheritanceManager.getInherited2(element, setterName);
  }

  ExecutableElement? _getInterfaceMember(
      InterfaceElement element, String baseName) {
    var libraryUri = _currentLibrary.source.uri;

    var getterName = Name(libraryUri, baseName);
    var getter = _inheritanceManager.getMember2(element, getterName);
    if (getter != null) {
      return getter;
    }

    var setterName = Name(libraryUri, '$baseName=');
    return _inheritanceManager.getMember2(element, setterName);
  }

  static void checkLibrary({
    required InheritanceManager3 inheritance,
    required LibraryVerificationContext libraryVerificationContext,
    required LibraryElement libraryElement,
    required Map<FileState, FileAnalysis> files,
  }) {
    MemberDuplicateDefinitionVerifier forUnit(FileAnalysis fileAnalysis) {
      return MemberDuplicateDefinitionVerifier._(
        inheritance,
        libraryElement,
        fileAnalysis.element,
        fileAnalysis.errorReporter,
        libraryVerificationContext.duplicationDefinitionContext,
      );
    }

    // Check all instance members.
    for (var fileAnalysis in files.values) {
      forUnit(fileAnalysis)._checkUnit(fileAnalysis.unit);
    }

    // Check all static members.
    for (var fileAnalysis in files.values) {
      forUnit(fileAnalysis)._checkUnitStatic(fileAnalysis.unit);
    }
  }

  static bool _isGetterSetterPair(Element a, Element b) {
    if (a is PropertyAccessorElement && b is PropertyAccessorElement) {
      return a.isGetter && b.isSetter || a.isSetter && b.isGetter;
    }
    return false;
  }
}

/// Information accumulated for a single declaration and its augmentations.
class _InstanceElementContext {
  final Set<String> constructorNames = {};
  final Map<String, Element> instanceGetters = {};
  final Map<String, Element> instanceSetters = {};
  final Map<String, Element> staticGetters = {};
  final Map<String, Element> staticSetters = {};
}
