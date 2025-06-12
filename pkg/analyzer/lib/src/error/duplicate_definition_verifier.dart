// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  final DiagnosticReporter _diagnosticReporter;
  final DuplicationDefinitionContext context;

  final DiagnosticFactory _diagnosticFactory = DiagnosticFactory();
  final Set<Token> _reportedTokens = Set.identity();

  DuplicateDefinitionVerifier(
    this._currentLibrary,
    this._diagnosticReporter,
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
        _diagnosticReporter.reportError(
          _diagnosticFactory.duplicateDefinitionForNodes(
            _diagnosticReporter.source,
            CompileTimeErrorCode.DUPLICATE_DEFINITION,
            stackTraceParameter,
            exceptionParameter,
            [exceptionName],
          ),
        );
      }
    }
  }

  /// Check that the given list of variable declarations does not define
  /// multiple variables of the same name.
  void checkForVariables(VariableDeclarationListImpl node) {
    var definedNames = <String, Element>{};
    for (var variable in node.variables) {
      _checkDuplicateIdentifier(
        definedNames,
        variable.name,
        element: variable.declaredFragment!.element,
      );
    }
  }

  /// Check that all of the parameters have unique names.
  void checkParameters(FormalParameterListImpl node) {
    var definedNames = <String, Element>{};
    for (var parameter in node.parameters) {
      var identifier = parameter.name;
      if (identifier != null) {
        // The identifier can be null if this is a parameter list for a generic
        // function type.

        // Skip wildcard `super._`.
        if (!_isSuperFormalWildcard(parameter, identifier)) {
          _checkDuplicateIdentifier(
            definedNames,
            identifier,
            element: parameter.declaredFragment!.element,
          );
        }
      }
    }
  }

  /// Check that all of the variables have unique names.
  void checkStatements(List<StatementImpl> statements) {
    var definedNames = <String, Element>{};
    for (var statement in statements) {
      if (statement is VariableDeclarationStatementImpl) {
        for (var variable in statement.variables.variables) {
          _checkDuplicateIdentifier(
            definedNames,
            variable.name,
            element: variable.declaredFragment!.element,
          );
        }
      } else if (statement is FunctionDeclarationStatementImpl) {
        if (!_isWildCardFunction(statement)) {
          _checkDuplicateIdentifier(
            definedNames,
            statement.functionDeclaration.name,
            element: statement.functionDeclaration.declaredFragment!.element,
          );
        }
      } else if (statement is PatternVariableDeclarationStatementImpl) {
        for (var variable in statement.declaration.elements) {
          _checkDuplicateIdentifier(
            definedNames,
            variable.node.name,
            element: variable,
          );
        }
      }
    }
  }

  /// Check that all of the parameters have unique names.
  void checkTypeParameters(TypeParameterListImpl node) {
    var definedNames = <String, Element>{};
    for (var parameter in node.typeParameters) {
      _checkDuplicateIdentifier(
        definedNames,
        parameter.name,
        element: parameter.declaredFragment!.element,
      );
    }
  }

  /// Check that there are no members with the same name.
  void checkUnit(CompilationUnitImpl node) {
    var fragment = node.declaredFragment!;
    var definedGetters = <String, Element>{};
    var definedSetters = <String, Element>{};

    void addWithoutChecking(LibraryFragment libraryFragment) {
      for (var fragment in libraryFragment.getters) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.setters) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedSetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.classes2) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.enums2) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.extensions2) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.extensionTypes2) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.functions2) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.mixins2) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.typeAliases2) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
    }

    var libraryDeclarations = _currentLibrary.libraryDeclarations;
    for (var importPrefix in fragment.prefixes) {
      var name = importPrefix.name3;
      if (name != null) {
        if (libraryDeclarations.withName(name) case var existing?) {
          _diagnosticReporter.reportError(
            _diagnosticFactory.duplicateDefinition(
              CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER,
              importPrefix,
              existing,
              [name],
            ),
          );
        }
      }
    }

    // TODO(scheglov): carry across resolved units
    var currentLibraryFragment = node.declaredFragment!;
    for (var libraryFragment in _currentLibrary.fragments) {
      if (libraryFragment == currentLibraryFragment) {
        break;
      }
      addWithoutChecking(libraryFragment);
    }

    for (var member in node.declarations) {
      if (member is ExtensionDeclarationImpl) {
        var identifier = member.name;
        if (identifier != null) {
          var declaredFragment = member.declaredFragment!;
          if (!declaredFragment.isAugmentation) {
            _checkDuplicateIdentifier(
              definedGetters,
              identifier,
              element: declaredFragment.element,
              setterScope: definedSetters,
            );
          }
        }
      } else if (member is NamedCompilationUnitMemberImpl) {
        var declaredFragment = member.declaredFragment!;
        var augmentable = declaredFragment as AugmentableFragment;
        if (!augmentable.isAugmentation) {
          _checkDuplicateIdentifier(
            definedGetters,
            member.name,
            element: declaredFragment.element,
            setterScope: definedSetters,
          );
        }
      } else if (member is TopLevelVariableDeclarationImpl) {
        for (var variable in member.variables.variables) {
          var declaredFragment = variable.declaredFragment;
          declaredFragment as TopLevelVariableFragmentImpl;
          if (!declaredFragment.isAugmentation) {
            _checkDuplicateIdentifier(
              definedGetters,
              variable.name,
              element: declaredFragment.element.getter2,
              setterScope: definedSetters,
            );
            if (declaredFragment.element.definesSetter) {
              _checkDuplicateIdentifier(
                definedGetters,
                variable.name,
                element: declaredFragment.element.setter2,
                setterScope: definedSetters,
              );
            }
          }
        }
      }
    }
  }

  /// Check whether the given [element] defined by the [identifier] is already
  /// in one of the scopes - [getterScope] or [setterScope], and produce an
  /// error if it is.
  void _checkDuplicateIdentifier(
    Map<String, Element> getterScope,
    Token identifier, {
    required Element? element,
    Map<String, Element>? setterScope,
  }) {
    if (identifier.isSynthetic) {
      return;
    }
    if (element == null || element.isWildcardVariable) {
      return;
    }
    if (element case AugmentableFragment augmentable) {
      if (augmentable.isAugmentation) {
        return;
      }
    }

    var lookupName = element.lookupName;
    if (lookupName == null) {
      return;
    }

    if (_reportedTokens.contains(identifier)) {
      return;
    }

    DiagnosticCode getDiagnostic(Element previous, Element current) {
      if (previous is FieldFormalParameterElement &&
          current is FieldFormalParameterElement) {
        return CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER;
      }
      return CompileTimeErrorCode.DUPLICATE_DEFINITION;
    }

    if (element is SetterElement) {
      if (setterScope != null) {
        var previous = setterScope[lookupName];
        if (previous != null) {
          _reportedTokens.add(identifier);
          _diagnosticReporter.reportError(
            _diagnosticFactory.duplicateDefinition(
              getDiagnostic(previous, element),
              element,
              previous,
              [lookupName],
            ),
          );
        } else {
          setterScope[lookupName] = element;
        }
      }
    } else {
      var previous = getterScope[lookupName];
      if (previous != null) {
        _reportedTokens.add(identifier);
        _diagnosticReporter.reportError(
          _diagnosticFactory.duplicateDefinition(
            getDiagnostic(previous, element),
            element,
            previous,
            [lookupName],
          ),
        );
      } else {
        getterScope[lookupName] = element;
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
}

/// Information to pass from declarations to augmentations.
class DuplicationDefinitionContext {
  final Map<InstanceFragmentImpl, _InstanceElementContext>
  _instanceElementContexts = {};
}

class MemberDuplicateDefinitionVerifier {
  final InheritanceManager3 _inheritanceManager;
  final LibraryElementImpl _currentLibrary;
  final LibraryFragmentImpl _currentUnit;
  final DiagnosticReporter _diagnosticReporter;
  final DuplicationDefinitionContext context;
  final DiagnosticFactory _diagnosticFactory = DiagnosticFactory();

  MemberDuplicateDefinitionVerifier._(
    this._inheritanceManager,
    this._currentLibrary,
    this._currentUnit,
    this._diagnosticReporter,
    this.context,
  );

  void _checkClass(ClassDeclarationImpl node) {
    _checkClassMembers(node.declaredFragment!, node.members);
  }

  /// Check that there are no members with the same name.
  void _checkClassMembers(
    InstanceFragmentImpl fragment,
    List<ClassMemberImpl> members,
  ) {
    var firstFragment = fragment.element.firstFragment;

    var elementContext = _getElementContext(firstFragment);
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
          if (member.returnType.name != firstFragment.name2) {
            // [member] is erroneous; do not count it as a possible duplicate.
            continue;
          }
          var name = member.name?.lexeme ?? 'new';
          if (!constructorNames.add(name)) {
            if (name == 'new') {
              _diagnosticReporter.atConstructorDeclaration(
                member,
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
              );
            } else {
              _diagnosticReporter.atConstructorDeclaration(
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
            if (fragment is EnumFragmentImpl) {
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
          if (fragment is EnumFragmentImpl) {
            if (!(member.isStatic && member.isSetter)) {
              _checkValuesDeclarationInEnum(member.name);
            }
          }
      }
    }

    if (firstFragment is InterfaceFragmentImpl) {
      _checkConflictingConstructorAndStatic(
        interfaceElement: firstFragment,
        staticGetters: staticGetters,
        staticSetters: staticSetters,
      );
    }
  }

  void _checkClassStatic(
    InstanceFragmentImpl fragment,
    List<ClassMember> members,
  ) {
    var firstFragment = fragment.element.firstFragment;

    var elementContext = _getElementContext(firstFragment);
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
              if (firstFragment is InterfaceFragmentImpl) {
                String className = firstFragment.name2 ?? '';
                _diagnosticReporter.atToken(
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
            if (firstFragment is InterfaceFragmentImpl) {
              String className = firstFragment.name2 ?? '';
              _diagnosticReporter.atToken(
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
    required InterfaceFragmentImpl interfaceElement,
    required Map<String, FragmentImpl> staticGetters,
    required Map<String, FragmentImpl> staticSetters,
  }) {
    for (var constructor in interfaceElement.constructors) {
      var name = constructor.name2;

      // It is already an error to declare a member named 'new'.
      if (name == 'new') {
        continue;
      }

      var staticMember = staticGetters[name] ?? staticSetters[name];
      if (staticMember is PropertyAccessorFragmentImpl) {
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
        _diagnosticReporter.atElement2(
          constructor.asElement2,
          errorCode,
          arguments: [name],
        );
      } else if (staticMember is MethodFragmentImpl) {
        _diagnosticReporter.atElement2(
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
    Map<String, FragmentImpl> getterScope,
    Token identifier, {
    required FragmentImpl element,
    Map<String, FragmentImpl>? setterScope,
  }) {
    if (identifier.isSynthetic || element.asElement2.isWildcardVariable) {
      return;
    }

    switch (element) {
      case ExecutableFragmentImpl _:
        if (element.isAugmentation) return;
      case FieldFragmentImpl _:
        if (element.isAugmentation) return;
      case InstanceFragmentImpl _:
        if (element.isAugmentation) return;
      case TypeAliasFragmentImpl _:
        if (element.isAugmentation) return;
      case TopLevelVariableFragmentImpl _:
        if (element.isAugmentation) return;
    }

    // Fields define getters and setters, so check them separately.
    if (element is PropertyInducingElementImpl) {
      _checkDuplicateIdentifier(
        getterScope,
        identifier,
        element: element.getter!,
        setterScope: setterScope,
      );
      var setter = element.setter;
      if (setter != null && setter.isSynthetic) {
        _checkDuplicateIdentifier(
          getterScope,
          identifier,
          element: setter,
          setterScope: setterScope,
        );
      }
      return;
    }

    var name = switch (element) {
      MethodFragmentImpl() => element.element.lookupName ?? '',
      _ => identifier.lexeme,
    };

    var previous = getterScope[name];
    if (previous != null) {
      if (!_isGetterSetterPair(element, previous)) {
        _diagnosticReporter.reportError(
          _diagnosticFactory.duplicateDefinition(
            CompileTimeErrorCode.DUPLICATE_DEFINITION,
            element.asElement2!,
            previous.asElement2!,
            [name],
          ),
        );
      } else {
        // Getter setter pair. Make sure the *getter* is in the getter map.
        if (element is PropertyAccessorFragmentImpl && element.isGetter) {
          getterScope[name] = element;
        }
      }
    } else {
      getterScope[name] = element;
    }

    if (setterScope != null) {
      if (element is PropertyAccessorFragmentImpl && element.isSetter) {
        previous = setterScope[name];
        if (previous != null) {
          _diagnosticReporter.reportError(
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
    var firstFragment = fragment.element.firstFragment;
    var declarationName = firstFragment.name2;

    var elementContext = _getElementContext(firstFragment);
    var staticGetters = elementContext.staticGetters;

    for (var constant in node.constants) {
      if (constant.name.lexeme == declarationName) {
        _diagnosticReporter.atToken(
          constant.name,
          CompileTimeErrorCode.ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING,
        );
      }
      _checkDuplicateIdentifier(
        staticGetters,
        constant.name,
        element: constant.declaredFragment!,
      );
      _checkValuesDeclarationInEnum(constant.name);
    }

    _checkClassMembers(fragment, node.members);

    if (declarationName == 'values') {
      _diagnosticReporter.atToken(
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
      var inherited = _getInheritedMember(firstFragment, baseName);
      if (inherited is MethodFragmentImpl) {
        _diagnosticReporter.atElement2(
          accessor.asElement2,
          CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD,
          arguments: [
            firstFragment.displayName,
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
      var inherited = _getInheritedMember(firstFragment, baseName);
      if (inherited is PropertyAccessorFragmentImpl) {
        _diagnosticReporter.atElement2(
          method.asElement2,
          CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD,
          arguments: [
            firstFragment.displayName,
            baseName,
            inherited.enclosingElement3.displayName,
          ],
        );
      }
    }
  }

  void _checkEnumStatic(EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var firstFragment = fragment.element.firstFragment;
    var declarationName = firstFragment.name2;
    if (declarationName == null) {
      return;
    }

    for (var accessor in fragment.accessors) {
      if (accessor.source != _currentUnit.source) {
        continue;
      }
      var baseName = accessor.displayName;
      if (accessor.isStatic) {
        var instance = _getInterfaceMember(firstFragment, baseName);
        if (instance != null && baseName != 'values') {
          _diagnosticReporter.atElement2(
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
        var instance = _getInterfaceMember(firstFragment, baseName);
        if (instance != null) {
          _diagnosticReporter.atElement2(
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
    var firstFragment = fragment.element.firstFragment;

    var elementContext = _getElementContext(firstFragment);
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
              _diagnosticReporter.atToken(
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
            _diagnosticReporter.atToken(
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
    var firstFragment = fragment.element.firstFragment;
    var primaryConstructorName = firstFragment.constructors.first.name2;
    var representationGetter = firstFragment.representation.getter!;
    var elementContext = _getElementContext(firstFragment);
    elementContext.constructorNames.add(primaryConstructorName);
    if (representationGetter.name2 case var getterName?) {
      elementContext.instanceGetters[getterName] = representationGetter;
    }

    _checkClassMembers(firstFragment, node.members);
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
      _diagnosticReporter.atToken(
        name,
        CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM,
      );
    }
  }

  _InstanceElementContext _getElementContext(InstanceFragmentImpl element) {
    return context._instanceElementContexts[element] ??=
        _InstanceElementContext();
  }

  ExecutableElementOrMember? _getInheritedMember(
    InterfaceFragmentImpl element,
    String baseName,
  ) {
    var libraryUri = _currentLibrary.source.uri;

    var getterName = Name(libraryUri, baseName);
    var getter = _inheritanceManager.getInherited2(element, getterName);
    if (getter != null) {
      return getter;
    }

    var setterName = Name(libraryUri, '$baseName=');
    return _inheritanceManager.getInherited2(element, setterName);
  }

  ExecutableElementOrMember? _getInterfaceMember(
    InterfaceFragmentImpl element,
    String baseName,
  ) {
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
    required LibraryElementImpl libraryElement,
    required Map<FileState, FileAnalysis> files,
  }) {
    MemberDuplicateDefinitionVerifier forUnit(FileAnalysis fileAnalysis) {
      return MemberDuplicateDefinitionVerifier._(
        inheritance,
        libraryElement,
        fileAnalysis.element,
        fileAnalysis.diagnosticReporter,
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

  static bool _isGetterSetterPair(FragmentImpl a, FragmentImpl b) {
    if (a is PropertyAccessorFragmentImpl &&
        b is PropertyAccessorFragmentImpl) {
      return a.isGetter && b.isSetter || a.isSetter && b.isGetter;
    }
    return false;
  }
}

/// Information accumulated for a single declaration and its augmentations.
class _InstanceElementContext {
  final Set<String> constructorNames = {};
  final Map<String, FragmentImpl> instanceGetters = {};
  final Map<String, FragmentImpl> instanceSetters = {};
  final Map<String, FragmentImpl> staticGetters = {};
  final Map<String, FragmentImpl> staticSetters = {};
}
