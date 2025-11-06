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
      var element = exceptionParameter.declaredFragment?.element;
      if (element != null && element.isWildcardVariable) return;
      String exceptionName = exceptionParameter.name.lexeme;
      if (exceptionName == stackTraceParameter.name.lexeme) {
        _diagnosticReporter.reportError(
          _diagnosticFactory.duplicateDefinitionForNodes(
            _diagnosticReporter.source,
            CompileTimeErrorCode.duplicateDefinition,
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
    var definedNames = <String, ElementImpl>{};
    for (var variable in node.variables) {
      _checkDuplicateIdentifier(
        definedNames,
        variable.name,
        fragment: variable.declaredFragment,
      );
    }
  }

  /// Check that all of the parameters have unique names.
  void checkParameters(FormalParameterListImpl node) {
    var definedNames = <String, ElementImpl>{};
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
            fragment: parameter.declaredFragment,
          );
        }
      }
    }
  }

  /// Check that all of the variables have unique names.
  void checkStatements(List<StatementImpl> statements) {
    var definedNames = <String, ElementImpl>{};
    for (var statement in statements) {
      if (statement is VariableDeclarationStatementImpl) {
        for (var variable in statement.variables.variables) {
          _checkDuplicateIdentifier(
            definedNames,
            variable.name,
            fragment: variable.declaredFragment,
          );
        }
      } else if (statement is FunctionDeclarationStatementImpl) {
        if (!_isWildCardFunction(statement)) {
          _checkDuplicateIdentifier(
            definedNames,
            statement.functionDeclaration.name,
            fragment: statement.functionDeclaration.declaredFragment,
          );
        }
      } else if (statement is PatternVariableDeclarationStatementImpl) {
        for (var variable in statement.declaration.elements) {
          _checkDuplicateIdentifier(
            definedNames,
            variable.node.name,
            fragment: variable.firstFragment,
          );
        }
      }
    }
  }

  /// Check that all of the parameters have unique names.
  void checkTypeParameters(TypeParameterListImpl node) {
    var definedNames = <String, ElementImpl>{};
    for (var parameter in node.typeParameters) {
      _checkDuplicateIdentifier(
        definedNames,
        parameter.name,
        fragment: parameter.declaredFragment,
      );
    }
  }

  /// Check that there are no members with the same name.
  void checkUnit(CompilationUnitImpl node) {
    var fragment = node.declaredFragment!;
    var definedGetters = <String, ElementImpl>{};
    var definedSetters = <String, ElementImpl>{};

    void addWithoutChecking(LibraryFragmentImpl libraryFragment) {
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
      for (var fragment in libraryFragment.classes) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.enums) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.extensions) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.extensionTypes) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.functions) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.mixins) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.typeAliases) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
    }

    var libraryDeclarations = _currentLibrary.libraryDeclarations;
    for (var importPrefix in fragment.prefixes) {
      var name = importPrefix.name;
      if (name != null) {
        if (libraryDeclarations.withName(name) case var existing?) {
          _diagnosticReporter.reportError(
            _diagnosticFactory.duplicateDefinition(
              CompileTimeErrorCode.prefixCollidesWithTopLevelMember,
              importPrefix.firstFragment,
              existing as ElementImpl,
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
              fragment: declaredFragment,
              setterScope: definedSetters,
            );
          }
        }
      } else if (member is NamedCompilationUnitMemberImpl) {
        var declaredFragment = member.declaredFragment!;
        _checkDuplicateIdentifier(
          definedGetters,
          member.name,
          fragment: declaredFragment,
          setterScope: definedSetters,
        );
      } else if (member is TopLevelVariableDeclarationImpl) {
        for (var variable in member.variables.variables) {
          var declaredFragment = variable.declaredFragment;
          declaredFragment as TopLevelVariableFragmentImpl;
          if (!declaredFragment.isAugmentation) {
            var declaredElement = declaredFragment.element;
            _checkDuplicateIdentifier(
              definedGetters,
              variable.name,
              originFragment: declaredFragment,
              fragment: declaredElement.getter?.firstFragment,
              setterScope: definedSetters,
            );
            if (declaredElement.definesSetter) {
              _checkDuplicateIdentifier(
                definedGetters,
                variable.name,
                originFragment: declaredFragment,
                fragment: declaredElement.setter?.firstFragment,
                setterScope: definedSetters,
              );
            }
          }
        }
      }
    }
  }

  /// Check whether the given [fragment] defined by the [identifier] is already
  /// in one of the scopes - [getterScope] or [setterScope], and produce an
  /// error if it is.
  void _checkDuplicateIdentifier(
    Map<String, ElementImpl> getterScope,
    Token identifier, {
    FragmentImpl? originFragment,
    required FragmentImpl? fragment,
    Map<String, ElementImpl>? setterScope,
  }) {
    if (identifier.isSynthetic) {
      return;
    }
    if (fragment == null || fragment.element.isWildcardVariable) {
      return;
    }
    if (fragment.isAugmentation) {
      return;
    }

    originFragment ??= fragment;

    var lookupName = fragment.element.lookupName;
    if (lookupName == null) {
      return;
    }

    if (_reportedTokens.contains(identifier)) {
      return;
    }

    DiagnosticCode getDiagnostic(ElementImpl previous, FragmentImpl current) {
      if (previous is FieldFormalParameterElement &&
          current is FieldFormalParameterFragment) {
        return CompileTimeErrorCode.duplicateFieldFormalParameter;
      }
      return CompileTimeErrorCode.duplicateDefinition;
    }

    if (fragment is SetterFragment) {
      if (setterScope != null) {
        var previous = setterScope[lookupName];
        if (previous != null) {
          _reportedTokens.add(identifier);
          _diagnosticReporter.reportError(
            _diagnosticFactory.duplicateDefinition(
              getDiagnostic(previous, fragment),
              originFragment,
              previous,
              [lookupName],
            ),
          );
        } else {
          setterScope[lookupName] = fragment.element;
        }
      }
    } else {
      var previous = getterScope[lookupName];
      if (previous != null) {
        _reportedTokens.add(identifier);
        _diagnosticReporter.reportError(
          _diagnosticFactory.duplicateDefinition(
            getDiagnostic(previous, fragment),
            originFragment,
            previous,
            [lookupName],
          ),
        );
      } else {
        getterScope[lookupName] = fragment.element;
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
    var instanceScope = elementContext.instanceScope;
    var staticScope = elementContext.staticScope;

    for (var member in members) {
      switch (member) {
        case ConstructorDeclarationImpl():
          // Augmentations are not declarations, can have multiple.
          if (member.augmentKeyword != null) {
            continue;
          }
          if (member.returnType.name != firstFragment.name) {
            // [member] is erroneous; do not count it as a possible duplicate.
            continue;
          }
          var name = member.name?.lexeme ?? 'new';
          if (!constructorNames.add(name)) {
            if (name == 'new') {
              _diagnosticReporter.atConstructorDeclaration(
                member,
                CompileTimeErrorCode.duplicateConstructorDefault,
              );
            } else {
              _diagnosticReporter.atConstructorDeclaration(
                member,
                CompileTimeErrorCode.duplicateConstructorName,
                arguments: [name],
              );
            }
          }
        case FieldDeclarationImpl():
          for (var field in member.fields.variables) {
            var fieldFragment = field.declaredFragment!;
            fieldFragment as FieldFragmentImpl;
            var fieldElement = fieldFragment.element;
            _checkDuplicateIdentifier(
              member.isStatic ? staticScope : instanceScope,
              field.name,
              fragment: fieldElement.getter!.firstFragment,
              originFragment: fieldFragment,
            );
            if (fieldElement.setter case var setter?) {
              _checkDuplicateIdentifier(
                member.isStatic ? staticScope : instanceScope,
                field.name,
                fragment: setter.firstFragment,
                originFragment: fieldFragment,
              );
            }
            if (fragment is EnumFragmentImpl) {
              _checkValuesDeclarationInEnum(field.name);
            }
          }
        case MethodDeclarationImpl():
          _checkDuplicateIdentifier(
            member.isStatic ? staticScope : instanceScope,
            member.name,
            fragment: member.declaredFragment!,
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
        staticScope: staticScope,
      );
    }
  }

  void _checkClassStatic(
    InstanceFragmentImpl fragment,
    List<ClassMember> members,
  ) {
    var firstFragment = fragment.element.firstFragment;

    var elementContext = _getElementContext(firstFragment);
    var instanceScope = elementContext.instanceScope;

    // Check for local static members conflicting with local instance members.
    // TODO(scheglov): This code is duplicated for enums. But for classes it is
    // separated also into ErrorVerifier - where we check inherited.
    for (ClassMember member in members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          for (VariableDeclaration field in member.fields.variables) {
            var identifier = field.name;
            String name = identifier.lexeme;
            if (instanceScope.containsKey(name)) {
              if (firstFragment is InterfaceFragmentImpl) {
                String className = firstFragment.name ?? '';
                _diagnosticReporter.atToken(
                  identifier,
                  CompileTimeErrorCode.conflictingStaticAndInstance,
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
          if (instanceScope.containsKey(name)) {
            if (firstFragment is InterfaceFragmentImpl) {
              String className = firstFragment.name ?? '';
              _diagnosticReporter.atToken(
                identifier,
                CompileTimeErrorCode.conflictingStaticAndInstance,
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
    required Map<String, _ScopeEntry> staticScope,
  }) {
    for (var constructor in interfaceElement.constructors) {
      var name = constructor.name;

      // It is already an error to declare a member named 'new'.
      if (name == 'new') {
        continue;
      }

      var state = staticScope[name];
      switch (state) {
        case null:
          // ok
          break;
        case _ScopeEntryElement(
          element: PropertyAccessorElementImpl staticMember2,
        ):
          CompileTimeErrorCode errorCode;
          if (staticMember2.isSynthetic) {
            errorCode =
                CompileTimeErrorCode.conflictingConstructorAndStaticField;
          } else if (staticMember2 is GetterElementImpl) {
            errorCode =
                CompileTimeErrorCode.conflictingConstructorAndStaticGetter;
          } else {
            errorCode =
                CompileTimeErrorCode.conflictingConstructorAndStaticSetter;
          }
          _diagnosticReporter.atElement2(
            constructor.asElement2,
            errorCode,
            arguments: [name],
          );
        case _ScopeEntryElement(element: MethodElementImpl()):
          _diagnosticReporter.atElement2(
            constructor.asElement2,
            CompileTimeErrorCode.conflictingConstructorAndStaticMethod,
            arguments: [name],
          );
        case _ScopeEntryGetterSetterPair():
          _diagnosticReporter.atElement2(
            constructor.asElement2,
            state.getter.isSynthetic
                ? CompileTimeErrorCode.conflictingConstructorAndStaticField
                : CompileTimeErrorCode.conflictingConstructorAndStaticGetter,
            arguments: [name],
          );
        case _ScopeEntryElement(:var element):
          throw StateError(
            'Unexpected type in duplicate map: ${element.runtimeType}',
          );
      }
    }
  }

  /// Checks whether the given [fragment] defined by the [identifier] conflicts
  /// with an element already in [scope], and produces an error if it is.
  void _checkDuplicateIdentifier(
    Map<String, _ScopeEntry> scope,
    Token identifier, {
    required FragmentImpl fragment,
    FragmentImpl? originFragment,
  }) {
    if (identifier.isSynthetic || fragment.element.isWildcardVariable) {
      return;
    }

    if (fragment.isAugmentation) {
      return;
    }

    var name = switch (fragment) {
      MethodFragmentImpl() => fragment.element.lookupName ?? '',
      _ => identifier.lexeme,
    };

    var scopeEntry = scope[name];
    switch (scopeEntry) {
      case null:
        scope[name] = _ScopeEntryElement(fragment.element);
      case _ScopeEntryElement(element: GetterElementImpl previous)
          when fragment is SetterFragmentImpl:
        scope[name] = _ScopeEntryGetterSetterPair(
          getter: previous,
          setter: fragment.element,
        );
      case _ScopeEntryElement(element: SetterElementImpl previous)
          when fragment is GetterFragmentImpl:
        scope[name] = _ScopeEntryGetterSetterPair(
          getter: fragment.element,
          setter: previous,
        );
      case _ScopeEntryGetterSetterPair(setter: ElementImpl previous)
          when fragment is SetterFragmentImpl:
      case _ScopeEntryGetterSetterPair(getter: ElementImpl previous):
      case _ScopeEntryElement(element: ElementImpl previous):
        if (!identical(previous, fragment.element)) {
          _diagnosticReporter.reportError(
            _diagnosticFactory.duplicateDefinition(
              CompileTimeErrorCode.duplicateDefinition,
              originFragment ?? fragment,
              previous,
              [name],
            ),
          );
        }
    }
  }

  /// Check that there are no members with the same name.
  void _checkEnum(EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var firstFragment = fragment.element.firstFragment;
    var declarationName = firstFragment.name;

    var elementContext = _getElementContext(firstFragment);
    var staticScope = elementContext.staticScope;

    for (var constant in node.constants) {
      if (constant.name.lexeme == declarationName) {
        _diagnosticReporter.atToken(
          constant.name,
          CompileTimeErrorCode.enumConstantSameNameAsEnclosing,
        );
      }
      var constantFragment = constant.declaredFragment!;
      var constantGetter = constantFragment.element.getter!;
      _checkDuplicateIdentifier(
        staticScope,
        constant.name,
        fragment: constantGetter.firstFragment,
        originFragment: constantFragment,
      );
      _checkValuesDeclarationInEnum(constant.name);
    }

    _checkClassMembers(fragment, node.members);

    if (declarationName == 'values') {
      _diagnosticReporter.atToken(
        node.name,
        CompileTimeErrorCode.enumWithNameValues,
      );
    }

    for (var accessor in fragment.accessors) {
      if (accessor.isStatic) {
        continue;
      }
      if (accessor.libraryFragment.source != _currentUnit.source) {
        continue;
      }
      var baseName = accessor.displayName;
      var inherited = _getInheritedMember(fragment.element, baseName);
      if (inherited is InternalMethodElement) {
        _diagnosticReporter.atElement2(
          accessor.asElement2,
          CompileTimeErrorCode.conflictingFieldAndMethod,
          arguments: [
            firstFragment.displayName,
            baseName,
            inherited.enclosingElement!.name!,
          ],
        );
      }
    }

    for (var method in fragment.methods) {
      if (method.isStatic) {
        continue;
      }
      if (method.libraryFragment.source != _currentUnit.source) {
        continue;
      }
      var baseName = method.displayName;
      var inherited = _getInheritedMember(fragment.element, baseName);
      if (inherited is InternalPropertyAccessorElement) {
        _diagnosticReporter.atElement2(
          method.asElement2,
          CompileTimeErrorCode.conflictingMethodAndField,
          arguments: [
            firstFragment.displayName,
            baseName,
            inherited.enclosingElement.name!,
          ],
        );
      }
    }
  }

  void _checkEnumStatic(EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var firstFragment = fragment.element.firstFragment;
    var declarationName = firstFragment.name;
    if (declarationName == null) {
      return;
    }

    for (var accessor in fragment.accessors) {
      if (accessor.libraryFragment.source != _currentUnit.source) {
        continue;
      }
      var baseName = accessor.displayName;
      if (accessor.isStatic) {
        var instance = _getInterfaceMember(fragment.element, baseName);
        if (instance != null && baseName != 'values') {
          _diagnosticReporter.atElement2(
            accessor.asElement2,
            CompileTimeErrorCode.conflictingStaticAndInstance,
            arguments: [declarationName, baseName, declarationName],
          );
        }
      }
    }

    for (var method in fragment.methods) {
      if (method.libraryFragment.source != _currentUnit.source) {
        continue;
      }
      var baseName = method.displayName;
      if (method.isStatic) {
        var instance = _getInterfaceMember(fragment.element, baseName);
        if (instance != null) {
          _diagnosticReporter.atElement2(
            method.asElement2,
            CompileTimeErrorCode.conflictingStaticAndInstance,
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
    var instanceScope = elementContext.instanceScope;

    for (var member in node.members) {
      if (member is FieldDeclarationImpl) {
        if (member.isStatic) {
          for (var field in member.fields.variables) {
            var identifier = field.name;
            var name = identifier.lexeme;
            if (instanceScope.containsKey(name)) {
              _diagnosticReporter.atToken(
                identifier,
                CompileTimeErrorCode.extensionConflictingStaticAndInstance,
                arguments: [name],
              );
            }
          }
        }
      } else if (member is MethodDeclarationImpl) {
        if (member.isStatic) {
          var identifier = member.name;
          var name = identifier.lexeme;
          if (instanceScope.containsKey(name)) {
            _diagnosticReporter.atToken(
              identifier,
              CompileTimeErrorCode.extensionConflictingStaticAndInstance,
              arguments: [name],
            );
          }
        }
      }
    }
  }

  void _checkExtensionType(ExtensionTypeDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    var firstFragment = element.firstFragment;
    var primaryConstructorName = element.primaryConstructor.name!;
    var representationGetter = element.representation.getter!;
    var elementContext = _getElementContext(firstFragment);
    elementContext.constructorNames.add(primaryConstructorName);
    if (representationGetter.name case var getterName?) {
      elementContext.instanceScope[getterName] = _ScopeEntryElement(
        representationGetter,
      );
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
        CompileTimeErrorCode.valuesDeclarationInEnum,
      );
    }
  }

  _InstanceElementContext _getElementContext(InstanceFragmentImpl element) {
    return context._instanceElementContexts[element] ??=
        _InstanceElementContext();
  }

  InternalExecutableElement? _getInheritedMember(
    InterfaceElementImpl element,
    String baseName,
  ) {
    var libraryUri = _currentLibrary.uri;

    var getterName = Name(libraryUri, baseName);
    var getter = _inheritanceManager.getInherited(element, getterName);
    if (getter != null) {
      return getter;
    }

    var setterName = Name(libraryUri, '$baseName=');
    return _inheritanceManager.getInherited(element, setterName);
  }

  InternalExecutableElement? _getInterfaceMember(
    InterfaceElementImpl element,
    String baseName,
  ) {
    var libraryUri = _currentLibrary.uri;

    var getterName = Name(libraryUri, baseName);
    var getter = _inheritanceManager.getMember(element, getterName);
    if (getter != null) {
      return getter;
    }

    var setterName = Name(libraryUri, '$baseName=');
    return _inheritanceManager.getMember(element, setterName);
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
}

/// Information accumulated for a single declaration and its augmentations.
class _InstanceElementContext {
  final Set<String> constructorNames = {};
  final Map<String, _ScopeEntry> instanceScope = {};
  final Map<String, _ScopeEntry> staticScope = {};
}

sealed class _ScopeEntry {}

class _ScopeEntryElement extends _ScopeEntry {
  final ElementImpl element;

  _ScopeEntryElement(this.element)
    : assert(element is! PropertyInducingElementImpl);
}

class _ScopeEntryGetterSetterPair extends _ScopeEntry {
  final GetterElementImpl getter;
  final SetterElementImpl setter;

  _ScopeEntryGetterSetterPair({required this.getter, required this.setter});
}
