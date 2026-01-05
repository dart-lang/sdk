// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/analysis/file_analysis.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

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
    _checkClassMembers(node.declaredFragment!, node.body.members);
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

          // Skip if the typeName is wrong.
          if (member.typeName case var typeName?) {
            if (typeName.name != firstFragment.name) {
              continue;
            }
          }

          var name = member.name?.lexeme ?? 'new';
          if (!constructorNames.add(name)) {
            if (name == 'new') {
              _diagnosticReporter.atConstructorDeclaration(
                member,
                diag.duplicateConstructorDefault,
              );
            } else {
              _diagnosticReporter.atConstructorDeclaration(
                member,
                diag.duplicateConstructorName,
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
        case PrimaryConstructorBodyImpl():
          // Not an actual declaration.
          break;
      }
    }

    if (firstFragment is InterfaceFragmentImpl) {
      _checkConflictingConstructorAndStatic(
        interfaceFragment: firstFragment,
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
                _diagnosticReporter.report(
                  diag.conflictingStaticAndInstance
                      .withArguments(
                        className: className,
                        memberName: name,
                        conflictingClassName: className,
                      )
                      .at(identifier),
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
              _diagnosticReporter.report(
                diag.conflictingStaticAndInstance
                    .withArguments(
                      className: className,
                      memberName: name,
                      conflictingClassName: className,
                    )
                    .at(identifier),
              );
            }
          }
        }
      }
    }
  }

  void _checkConflictingConstructorAndStatic({
    required InterfaceFragmentImpl interfaceFragment,
    required Map<String, _ScopeEntry> staticScope,
  }) {
    for (var constructor in interfaceFragment.constructors) {
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
          _diagnosticReporter.report(
            switch (staticMember2) {
                  PropertyAccessorElementImpl(isOriginVariable: true) =>
                    diag.conflictingConstructorAndStaticField,
                  GetterElementImpl() =>
                    diag.conflictingConstructorAndStaticGetter,
                  _ => diag.conflictingConstructorAndStaticSetter,
                }
                .withArguments(name: name)
                .atSourceRange(
                  constructor.asElement2.diagnosticRange(_currentUnit.source),
                ),
          );
        case _ScopeEntryElement(element: MethodElementImpl()):
          _diagnosticReporter.report(
            diag.conflictingConstructorAndStaticMethod
                .withArguments(name: name)
                .atSourceRange(
                  constructor.asElement2.diagnosticRange(_currentUnit.source),
                ),
          );
        case _ScopeEntryGetterSetterPair():
          _diagnosticReporter.report(
            (state.getter.isOriginVariable
                    ? diag.conflictingConstructorAndStaticField
                    : diag.conflictingConstructorAndStaticGetter)
                .withArguments(name: name)
                .atSourceRange(
                  constructor.asElement2.diagnosticRange(_currentUnit.source),
                ),
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
              diag.duplicateDefinition,
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

    var elementContext = _getElementContext(firstFragment);
    var staticScope = elementContext.staticScope;

    for (var constant in node.body.constants) {
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

    _checkClassMembers(fragment, node.body.members);

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
        _diagnosticReporter.report(
          diag.conflictingFieldAndMethod
              .withArguments(
                className: firstFragment.displayName,
                fieldName: baseName,
                conflictingClassName: inherited.enclosingElement!.name!,
              )
              .atSourceRange(
                accessor.asElement2.diagnosticRange(_currentUnit.source),
              ),
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
        _diagnosticReporter.report(
          diag.conflictingMethodAndField
              .withArguments(
                className: firstFragment.displayName,
                methodName: baseName,
                conflictingClassName: inherited.enclosingElement.name!,
              )
              .atSourceRange(
                method.asElement2.diagnosticRange(_currentUnit.source),
              ),
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
          _diagnosticReporter.report(
            diag.conflictingStaticAndInstance
                .withArguments(
                  className: declarationName,
                  memberName: baseName,
                  conflictingClassName: declarationName,
                )
                .atSourceRange(
                  accessor.asElement2.diagnosticRange(_currentUnit.source),
                ),
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
          _diagnosticReporter.report(
            diag.conflictingStaticAndInstance
                .withArguments(
                  className: declarationName,
                  memberName: baseName,
                  conflictingClassName: declarationName,
                )
                .atSourceRange(
                  method.asElement2.diagnosticRange(_currentUnit.source),
                ),
          );
        }
      }
    }
  }

  /// Check that there are no members with the same name.
  void _checkExtension(covariant ExtensionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    _checkClassMembers(fragment, node.body.members);
  }

  void _checkExtensionStatic(covariant ExtensionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var firstFragment = fragment.element.firstFragment;

    var elementContext = _getElementContext(firstFragment);
    var instanceScope = elementContext.instanceScope;

    for (var member in node.body.members) {
      if (member is FieldDeclarationImpl) {
        if (member.isStatic) {
          for (var field in member.fields.variables) {
            var identifier = field.name;
            var name = identifier.lexeme;
            if (instanceScope.containsKey(name)) {
              _diagnosticReporter.atToken(
                identifier,
                diag.extensionConflictingStaticAndInstance,
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
              diag.extensionConflictingStaticAndInstance,
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

    _checkClassMembers(firstFragment, node.body.members);
  }

  void _checkMixin(MixinDeclarationImpl node) {
    _checkClassMembers(node.declaredFragment!, node.body.members);
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
          _checkClassStatic(fragment, declaration.body.members);
        case EnumDeclarationImpl():
          _checkEnumStatic(declaration);
        case ExtensionDeclarationImpl():
          _checkExtensionStatic(declaration);
        case ExtensionTypeDeclarationImpl():
          var fragment = declaration.declaredFragment!;
          _checkClassStatic(fragment, declaration.body.members);
        case MixinDeclarationImpl():
          var fragment = declaration.declaredFragment!;
          _checkClassStatic(fragment, declaration.body.members);
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
      _diagnosticReporter.report(diag.valuesDeclarationInEnum.at(name));
    }
  }

  _InstanceElementContext _getElementContext(InstanceFragmentImpl fragment) {
    return context._instanceElementContexts[fragment] ??=
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
        fileAnalysis.fragment,
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
