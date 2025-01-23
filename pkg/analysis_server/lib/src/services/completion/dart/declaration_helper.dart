// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/not_imported_completion_pass.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analysis_server/src/services/completion/dart/visibility_tracker.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer/src/workspace/pub.dart';

/// A helper class that produces candidate suggestions for all of the
/// declarations that are in scope at the completion location.
class DeclarationHelper {
  /// The completion request being processed.
  final DartCompletionRequest request;

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// The state used to compute the candidate suggestions.
  final CompletionState state;

  /// The offset of the completion location.
  final int offset;

  /// The visibility tracker used to prevent suggesting elements that have been
  /// shadowed by local declarations.
  final VisibilityTracker visibilityTracker = VisibilityTracker();

  /// Whether suggestions should be limited to only include those to which a
  /// value can be assigned: either a setter or a local variable.
  final bool mustBeAssignable;

  /// Whether suggestions should be limited to only include valid constants.
  final bool mustBeConstant;

  /// Whether suggestions should be limited to only include interface types that
  /// can be extended in the current library.
  final bool mustBeExtendable;

  /// Whether suggestions should be limited to only include interface types that
  /// can be implemented in the current library.
  final bool mustBeImplementable;

  /// Whether suggestions should be limited to only include interface types that
  /// can be mixed in in the current library.
  final bool mustBeMixable;

  /// Whether suggestions should be limited to only include methods with a
  /// non-`void` return type.
  final bool mustBeNonVoid;

  /// AWhether suggestions should be limited to only include static members.
  final bool mustBeStatic;

  /// Whether suggestions should be limited to only include types.
  final bool mustBeType;

  /// Whether suggestions should exclude type names, e.g. include only
  /// constructor invocations.
  final bool excludeTypeNames;

  /// Whether object patterns are allowed even when the context otherwise
  /// requires a constant.
  ///
  /// Ignored when [mustBeConstant] is `false`.
  final bool objectPatternAllowed;

  /// Whether suggestions should be tear-offs rather than invocations where
  /// possible.
  final bool preferNonInvocation;

  /// Whether unnamed constructors should be suggested as `.new`.
  final bool suggestUnnamedAsNew;

  /// Whether the generation of suggestions for imports should be skipped. This
  /// exists as a temporary measure that will be removed after all of the
  /// suggestions are being produced by the various passes.
  final bool skipImports;

  /// The nodes that should be excluded, for example because we identified
  /// that they were created during parsing recovery, and don't contain
  /// useful suggestions.
  final Set<AstNode> excludedNodes;

  /// The number of local variables that have already been suggested.
  int _variableDistance = 0;

  /// The operations to be performed in the [NotImportedCompletionPass].
  ///
  /// The list will be empty if the pass does not need to be run.
  List<NotImportedOperation> notImportedOperations = [];

  /// Initialize a newly created helper to add suggestions to the [collector]
  /// that are appropriate for the location at the [offset].
  ///
  /// The flags [mustBeAssignable], [mustBeConstant], [mustBeNonVoid],
  /// [mustBeStatic], and [mustBeType] are used to control which declarations
  /// are suggested. The flag [preferNonInvocation] is used to control what kind
  /// of suggestion is made for executable elements.
  ///
  /// The flag [skipImports] is a temporary measure that will be removed after
  /// all of the suggestions are being produced by the various passes.
  DeclarationHelper({
    required this.request,
    required this.collector,
    required this.state,
    required this.offset,
    required this.mustBeAssignable,
    required this.mustBeConstant,
    required this.mustBeExtendable,
    required this.mustBeImplementable,
    required this.mustBeMixable,
    required this.mustBeNonVoid,
    required this.mustBeStatic,
    required this.mustBeType,
    required this.excludeTypeNames,
    required this.objectPatternAllowed,
    required this.preferNonInvocation,
    required this.suggestUnnamedAsNew,
    required this.skipImports,
    required this.excludedNodes,
  });

  /// Return the suggestion kind that should be used for executable elements.
  CompletionSuggestionKind get _executableSuggestionKind =>
      preferNonInvocation
          ? CompletionSuggestionKind.IDENTIFIER
          : CompletionSuggestionKind.INVOCATION;

  /// Add any constructors that are visible within the current library.
  void addConstructorInvocations() {
    var library = request.libraryElement;
    var importData = ImportData(
      libraryUri: library.uri,
      prefix: null,
      isNotImported: false,
    );
    _addConstructors(library, importData);
    if (!skipImports) {
      _addImportedConstructors(library);
      _recordOperation(ConstructorsOperation(declarationHelper: this));
    }
  }

  /// Add suggestions for all constructors of [element].
  void addConstructorNamesForElement({required InterfaceElement2 element}) {
    var constructors = element.constructors2;
    for (var constructor in constructors) {
      _suggestConstructor(
        constructor,
        hasClassName: true,
        importData: null,
        isConstructorRedirect: false,
      );
    }
  }

  /// Add suggestions for all of the named constructors in the [type]. If
  /// [exclude] is not `null` it is the name of a constructor that should be
  /// omitted from the list, typically because suggesting it would result in an
  /// infinite loop.
  void addConstructorNamesForType({
    required InterfaceType type,
    String? exclude,
  }) {
    for (var constructor in type.constructors2) {
      var name = constructor.name3;
      if (name != 'new' &&
          name != exclude &&
          !(mustBeConstant && !constructor.isConst)) {
        _suggestConstructor(
          constructor,
          hasClassName: true,
          importData: null,
          isConstructorRedirect: false,
        );
      }
    }
  }

  /// Add suggestions for declarations through [prefixElement].
  void addDeclarationsThroughImportPrefix(PrefixElement2 prefixElement) {
    for (var importElement in prefixElement.imports) {
      var importedLibrary = importElement.importedLibrary2;
      if (importedLibrary == null) {
        continue;
      }

      _addDeclarationsImportedFrom(
        library: importedLibrary,
        namespace: importElement.namespace,
        prefix: null,
      );

      if (importElement.prefix2 case var importPrefix?) {
        if (importPrefix.isDeferred) {
          var matcherScore = state.matcher.score('loadLibrary');
          if (matcherScore != -1) {
            collector.addSuggestion(
              LoadLibraryFunctionSuggestion(
                kind: CompletionSuggestionKind.INVOCATION,
                element: importedLibrary.loadLibraryFunction2,
                matcherScore: matcherScore,
              ),
            );
          }
        }
      }
    }
  }

  /// Add any fields that can be initialized in the initializer list of the
  /// given [constructor]. If a [fieldToInclude] is provided, then it should not
  /// be skipped because the cursor is inside that field's name.
  void addFieldsForInitializers(
    ConstructorDeclaration constructor,
    FieldElement2? fieldToInclude,
  ) {
    var constructorElement = constructor.declaredFragment?.element;
    var containingElement = constructorElement?.enclosingElement2;
    if (containingElement == null) {
      return;
    }

    var fieldsToSkip = <FieldElement2>{};
    // Skip fields that are already initialized in the initializer list.
    for (var initializer in constructor.initializers) {
      if (initializer is ConstructorFieldInitializer) {
        var fieldElement = initializer.fieldName.element;
        if (fieldElement is FieldElement2) {
          fieldsToSkip.add(fieldElement);
        }
      }
    }
    // Skip fields that are already initialized in the parameter list.
    for (var parameter in constructor.parameters.parameters) {
      parameter = parameter.notDefault;
      if (parameter is FieldFormalParameter) {
        var parameterElement = parameter.declaredFragment?.element;
        if (parameterElement is FieldFormalParameterElement2) {
          var field = parameterElement.field2;
          if (field != null) {
            fieldsToSkip.add(field);
          }
        }
      }
    }
    fieldsToSkip.remove(fieldToInclude);

    for (var field in containingElement.fields2) {
      // Skip fields that are already initialized at their declaration.
      if (!field.isStatic &&
          !field.isSynthetic &&
          !fieldsToSkip.contains(field) &&
          (!(field.isFinal || field.isConst) || !field.hasInitializer)) {
        _suggestField(field: field);
      }
    }
  }

  /// Add suggestions for all of the top-level declarations that are exported
  /// from the [library] except for those whose name is in the set of
  /// [excludedNames].
  void addFromLibrary(LibraryElement2 library, Set<String> excludedNames) {
    for (var entry in library.exportNamespace.definedNames2.entries) {
      if (!excludedNames.contains(entry.key)) {
        _addImportedElement(entry.value);
      }
    }
  }

  /// Adds suggestions for the getters defined by the [type], except for those
  /// whose names are in the set of [excludedGetters].
  void addGetters({
    required DartType type,
    required Set<String> excludedGetters,
  }) {
    if (type is InterfaceType) {
      _addInstanceMembers(
        type: type,
        excludedGetters: excludedGetters,
        includeMethods: false,
        includeSetters: false,
      );
    } else if (type is RecordType) {
      _addFieldsOfRecordType(type: type, excludedFields: excludedGetters);
      _addMembersOfDartCoreObject();
    }
  }

  void addImportPrefixes() {
    var library = request.libraryElement;
    for (var element in library.firstFragment.libraryImports2) {
      var importPrefix = element.prefix2;
      if (importPrefix == null) {
        continue;
      }

      var prefixElement = importPrefix.element;
      if (!visibilityTracker.isVisible(
        element: prefixElement,
        importData: null,
      )) {
        continue;
      }

      if (prefixElement.name3.isEmptyOrNull) {
        continue;
      }

      if (prefixElement.isWildcardVariable) {
        continue;
      }

      var importedLibrary = element.importedLibrary2;
      if (importedLibrary == null) {
        continue;
      }
      var matcherScore = state.matcher.score(prefixElement.displayName);
      if (matcherScore != -1) {
        collector.addSuggestion(
          ImportPrefixSuggestion(
            libraryElement: importedLibrary,
            prefixElement: prefixElement,
            matcherScore: matcherScore,
          ),
        );
      }
    }
  }

  /// Add any instance members defined for the given [type].
  ///
  /// If [onlySuper] is `true`, then only the members that are valid after a
  /// `super` expression (those from superclasses) will be added.
  void addInstanceMembersOfType(DartType type, {bool onlySuper = false}) {
    if (type is TypeParameterType) {
      type = type.bound;
    }
    if (type is InterfaceType) {
      _addInstanceMembers(
        type: type,
        excludedGetters: const {},
        includeMethods: !mustBeAssignable,
        includeSetters: true,
        onlySuper: onlySuper,
      );
    } else if (type is RecordType) {
      _addFieldsOfRecordType(type: type, excludedFields: const {});
      _addMembersOfDartCoreObject();
      _addExtensionMembers(
        type: type,
        excludedGetters: const {},
        includeMethods: !mustBeAssignable,
        includeSetters: true,
      );
      _recordOperation(
        InstanceExtensionMembersOperation(
          declarationHelper: this,
          type: type,
          excludedGetters: const {},
          includeMethods: !mustBeAssignable,
          includeSetters: true,
        ),
      );
    } else if (type is FunctionType) {
      _suggestFunctionCall();
      _addMembersOfDartCoreObject();
    } else if (type is DynamicType) {
      _addMembersOfDartCoreObject();
    }
  }

  /// Add any declarations that are visible at the completion location,
  /// given that the completion location is within the [node]. This includes
  /// local variables, local functions, parameters, members of the enclosing
  /// declaration, and top-level declarations in the enclosing library.
  void addLexicalDeclarations(AstNode node) {
    var containingMember =
        mustBeType ? _addLocalTypes(node) : _addLocalDeclarations(node);
    if (containingMember == null) {
      return;
    }
    AstNode? parent = containingMember.parent ?? containingMember;
    if (parent is ClassMember) {
      assert(node is CommentReference);
      parent = parent.parent;
    } else if (parent is CompilationUnit) {
      parent = containingMember;
    }
    CompilationUnitMember? topLevelMember;
    if (parent is CompilationUnitMember) {
      topLevelMember = parent;
      _addMembersOfEnclosingNode(parent);
      parent = parent.parent;
    }
    if (parent is CompilationUnit) {
      var library = parent.declaredFragment?.element;
      if (library != null) {
        _addTopLevelDeclarations(library);
        addImportPrefixes();
        if (!skipImports) {
          _addImportedDeclarations(library);
        }
        _recordOperation(StaticMembersOperation(declarationHelper: this));
      }
    }
    if (topLevelMember != null && !mustBeStatic && !mustBeType) {
      _addInheritedMembers(topLevelMember);
    }
  }

  /// Add members from the given [ExtensionElement2].
  void addMembersFromExtensionElement(
    ExtensionElement2 extension, {
    ImportData? importData,
  }) {
    var extendedType = extension.extendedType;
    var referencingInterface =
        (extendedType is InterfaceType) ? extendedType.element3 : null;
    for (var method in extension.methods2) {
      if (!method.isStatic) {
        _suggestMethod(
          method: method,
          importData: importData,
          referencingInterface: referencingInterface,
        );
      }
    }
    for (var accessor in extension.getters2) {
      if (!accessor.isStatic) {
        _suggestProperty(
          accessor: accessor,
          referencingInterface: referencingInterface,
          importData: importData,
        );
      }
    }
    for (var accessor in extension.setters2) {
      if (!accessor.isStatic) {
        _suggestProperty(
          accessor: accessor,
          referencingInterface: referencingInterface,
          importData: importData,
        );
      }
    }
  }

  /// Adds suggestions for any constructors that are visible within the not yet
  /// imported [library].
  void addNotImportedConstructors(LibraryElement2 library) {
    var importData = ImportData(
      libraryUri: library.uri,
      prefix: null,
      isNotImported: true,
    );
    _addConstructors(library, importData);
  }

  /// Add members from all the applicable extensions that are visible in the
  /// not yet imported [library] that are applicable for the given [type].
  void addNotImportedExtensionMethods({
    required LibraryElement2 library,
    required DartType type,
    required Set<String> excludedGetters,
    required bool includeMethods,
    required bool includeSetters,
  }) {
    var libraryElement = library;
    var applicableExtensions = library.exportNamespace.definedNames2.values
        .whereType<ExtensionElement2>()
        .applicableTo(
          targetLibrary: libraryElement,
          // Ignore nullability, consistent with non-extension members.
          targetType:
              (type.isDartCoreNull
                      ? type
                      : library.typeSystem.promoteToNonNull(type))
                  as TypeImpl,
          strictCasts: false,
        );
    var importData = ImportData(
      libraryUri: library.uri,
      prefix: null,
      isNotImported: true,
    );
    for (var instantiatedExtension in applicableExtensions) {
      var extension = instantiatedExtension.extension;
      if (extension.isVisibleIn(request.libraryElement)) {
        addMembersFromExtensionElement(extension, importData: importData);
      }
    }
  }

  /// Adds suggestions for any top-level declarations that are visible within
  /// the not yet imported [library].
  void addNotImportedTopLevelDeclarations(LibraryElement2 library) {
    var importData = ImportData(
      libraryUri: library.uri,
      prefix: null,
      isNotImported: true,
    );
    _addExternalTopLevelDeclarations(
      library: library,
      namespace: library.exportNamespace,
      importData: importData,
    );
  }

  /// Add any parameters from the super constructor of the constructor
  /// containing the [node] that can be referenced as a super parameter.
  void addParametersFromSuperConstructor(SuperFormalParameter node) {
    var element = node.declaredFragment?.element;
    if (element is! SuperFormalParameterElementImpl2) {
      return;
    }

    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }

    var constructorElement = constructor.declaredFragment?.element;
    if (constructorElement is! ConstructorElementImpl2) {
      return;
    }

    var superConstructor = constructorElement.superConstructor2;
    if (superConstructor == null) {
      return;
    }

    if (node.isNamed) {
      var superConstructorInvocation =
          constructor.initializers
              .whereType<SuperConstructorInvocation>()
              .singleOrNull;
      var specified = <String>{
        ...constructorElement.formalParameters.map((e) => e.name3).nonNulls,
        ...?superConstructorInvocation?.argumentList.arguments
            .whereType<NamedExpression>()
            .map((e) => e.name.label.name),
      };
      for (var superParameter in superConstructor.formalParameters) {
        if (superParameter.isNamed &&
            !specified.contains(superParameter.name3)) {
          _suggestSuperParameter(superParameter);
        }
      }
    } else if (node.isPositional) {
      var indexOfThis = element.indexIn(constructorElement);
      var superPositionalList =
          superConstructor.formalParameters
              .where((parameter) => parameter.isPositional)
              .toList();
      if (indexOfThis >= 0 && indexOfThis < superPositionalList.length) {
        var superPositional = superPositionalList[indexOfThis];
        _suggestSuperParameter(superPositional);
      }
    }
  }

  /// Add suggestions for all of the constructor in the [library] that could be
  /// a redirection target for the [redirectingConstructor].
  void addPossibleRedirectionsInLibrary(
    ConstructorElement2 redirectingConstructor,
    LibraryElement2 library,
  ) {
    var classElement = redirectingConstructor.enclosingElement2;
    var classType = classElement.thisType;
    var typeSystem = library.typeSystem;
    for (var classElement in library.classes) {
      if (typeSystem.isSubtypeOf(classElement.thisType, classType)) {
        for (var constructor in classElement.constructors2) {
          if (constructor != redirectingConstructor &&
              constructor.isAccessibleIn2(library)) {
            _suggestConstructor(
              constructor,
              hasClassName: false,
              importData: null,
              isConstructorRedirect: true,
            );
          }
        }
      }
    }
  }

  /// Add any static members defined by the given [element].
  void addStaticMembersOfElement(Element2 element) {
    if (element is TypeAliasElement2) {
      var aliasedType = element.aliasedType;
      if (aliasedType is InterfaceType) {
        element = aliasedType.element3;
      }
    }
    switch (element) {
      case EnumElement2():
        _addStaticMembers(
          getters: element.getters2,
          setters: element.setters2,
          constructors: element.constructors2,
          containingElement: element,
          fields: element.fields2,
          methods: element.methods2,
        );
      case ExtensionElement2():
        _addStaticMembers(
          getters: element.getters2,
          setters: element.setters2,
          constructors: const [],
          containingElement: element,
          fields: element.fields2,
          methods: element.methods2,
        );
      case InterfaceElement2():
        _addStaticMembers(
          getters: element.getters2,
          setters: element.setters2,
          constructors: element.constructors2,
          containingElement: element,
          fields: element.fields2,
          methods: element.methods2,
        );
    }
  }

  /// Adds suggestions for any constructors that are declared within the
  /// [library].
  void _addConstructors(LibraryElement2 library, ImportData importData) {
    for (var element in library.classes) {
      _suggestConstructors(
        element.constructors2,
        importData,
        allowNonFactory: !element.isAbstract,
      );
    }
    for (var element in library.enums) {
      _suggestConstructors(element.constructors2, importData);
    }
    for (var element in library.extensionTypes) {
      _suggestConstructors(element.constructors2, importData);
    }
    for (var element in library.typeAliases) {
      _addConstructorsForAliasedElement(element, importData);
    }
  }

  /// Adds suggestions for any constructors that are visible through type
  /// aliases declared within the `importData.libraryUri`.
  void _addConstructorsForAliasedElement(
    TypeAliasElement2 alias,
    ImportData? importData,
  ) {
    var aliasedElement = alias.aliasedElement2;
    if (aliasedElement is ClassElement2) {
      _suggestConstructors(
        aliasedElement.constructors2,
        importData,
        allowNonFactory: !aliasedElement.isAbstract,
      );
    } else if (aliasedElement is ExtensionTypeElement2) {
      _suggestConstructors(aliasedElement.constructors2, importData);
    } else if (aliasedElement is MixinElement2) {
      _suggestConstructors(aliasedElement.constructors2, importData);
    }
  }

  /// Adds suggestions for any constructors that are visible within the
  /// [library].
  void _addConstructorsImportedFrom({
    required LibraryElement2 library,
    required Namespace namespace,
    required String? prefix,
  }) {
    var importData = ImportData(
      libraryUri: library.uri,
      prefix: prefix,
      isNotImported: false,
    );
    for (var element in namespace.definedNames2.values) {
      switch (element) {
        case ClassElement2():
          _suggestConstructors(
            element.constructors2,
            importData,
            allowNonFactory: !element.isAbstract,
          );
        case ExtensionTypeElement2():
          _suggestConstructors(element.constructors2, importData);
        case TypeAliasElement2():
          _addConstructorsForAliasedElement(element, importData);
      }
    }
  }

  /// Adds suggestions for any top-level declarations that are visible within
  /// the [library].
  void _addDeclarationsImportedFrom({
    required LibraryElement2 library,
    required Namespace namespace,
    required String? prefix,
  }) {
    // Don't suggest declarations in wildcard prefixed namespaces.
    if (_isWildcard(prefix)) return;

    var importData = ImportData(
      libraryUri: library.uri,
      prefix: prefix,
      isNotImported: false,
    );
    _addExternalTopLevelDeclarations(
      library: library,
      namespace: namespace,
      importData: importData,
    );
  }

  /// Add members from all the applicable extensions that are visible for the
  /// given [InterfaceType].
  void _addExtensionMembers({
    required DartType type,
    required Set<String> excludedGetters,
    required bool includeMethods,
    required bool includeSetters,
  }) {
    var libraryElement = request.libraryElement;
    var libraryFragment = request.libraryFragment;

    var accessibleExtensions = libraryFragment.accessibleExtensions2;
    var applicableExtensions = accessibleExtensions.applicableTo(
      targetLibrary: libraryElement,
      // Ignore nullability, consistent with non-extension members.
      targetType:
          (type.isDartCoreNull
                  ? type
                  : libraryElement.typeSystem.promoteToNonNull(type))
              as TypeImpl,
      strictCasts: false,
    );
    for (var instantiatedExtension in applicableExtensions) {
      var extension = instantiatedExtension.extension;
      if (includeMethods) {
        for (var method in extension.methods2) {
          if (!method.isStatic) {
            _suggestMethod(method: method);
          }
        }
      }
      for (var getter in extension.getters2) {
        if (!getter.isSynthetic) {
          _suggestProperty(accessor: getter);
        } else {
          // All fields induce a getter.
          var variable = getter.variable3;
          if (variable is FieldElement2) {
            _suggestField(field: variable);
          }
        }
      }
      for (var setter in extension.setters2) {
        if (!setter.isSynthetic) {
          if (includeSetters) {
            _suggestProperty(accessor: setter);
          }
        } else {
          // Avoid visiting a field twice. All fields induce a getter, but only
          // non-final fields induce a setter, so we don't add a suggestion for a
          // synthetic setter.
        }
      }
    }
  }

  /// Adds suggestions for any top-level declarations that are visible within
  /// the [library].
  ///
  /// The [library] is a library other than the library in which completion is
  /// being requested.
  ///
  /// The [namespace] is the export namespace of the [library].
  ///
  /// The [importData] indicates how the library is, or should be, imported.
  void _addExternalTopLevelDeclarations({
    required LibraryElement2 library,
    required Namespace namespace,
    required ImportData importData,
  }) {
    for (var element in namespace.definedNames2.values) {
      switch (element) {
        case ClassElement2():
          _suggestClass(element, importData);
        case EnumElement2():
          _suggestEnum(element, importData);
        case ExtensionElement2():
          if (!mustBeType) {
            _suggestExtension(element, importData);
          }
        case ExtensionTypeElement2():
          _suggestExtensionType(element, importData);
        case TopLevelFunctionElement():
          if (!mustBeType) {
            _suggestTopLevelFunction(element, importData);
          }
        case MixinElement2():
          _suggestMixin(element, importData);
        case GetterElement():
          if (!mustBeType) {
            _suggestTopLevelProperty(element, importData);
          }
        case SetterElement():
          if (!mustBeType) {
            // Do not add synthetic setters, as these may prevent adding getters,
            // they are both tracked with the same name in the
            // [VisibilityTracker].
            if (element.isSynthetic) {
              break;
            }
            _suggestTopLevelProperty(element, importData);
          }
        case TopLevelVariableElement2():
          if (!mustBeType) {
            _suggestTopLevelVariable(element, importData);
          }
        case TypeAliasElement2():
          _suggestTypeAlias(element, importData);
      }
    }
  }

  /// Add suggestions for any of the fields defined by the record [type] except
  /// for those whose names are in the set of [excludedFields].
  void _addFieldsOfRecordType({
    required RecordType type,
    required Set<String> excludedFields,
  }) {
    for (var (index, field) in type.positionalFields.indexed) {
      _suggestRecordField(field: field, name: '\$${index + 1}');
    }

    for (var field in type.namedFields) {
      if (!excludedFields.contains(field.name)) {
        _suggestRecordField(field: field, name: field.name);
      }
    }
  }

  /// Adds suggestions for any constructors that are imported into the
  /// [library].
  void _addImportedConstructors(LibraryElement2 library) {
    // TODO(brianwilkerson): This will create suggestions for elements that
    //  conflict with different elements imported from a different library. Not
    //  sure whether that's the desired behavior.
    for (var importElement in library.firstFragment.libraryImports2) {
      var importedLibrary = importElement.importedLibrary2;
      if (importedLibrary != null) {
        _addConstructorsImportedFrom(
          library: importedLibrary,
          namespace: importElement.namespace,
          prefix: importElement.prefix2?.element.name3,
        );
      }
    }
  }

  /// Adds suggestions for any top-level declarations that are imported into the
  /// [library].
  void _addImportedDeclarations(LibraryElement2 library) {
    // TODO(brianwilkerson): This will create suggestions for elements that
    //  conflict with different elements imported from a different library. Not
    //  sure whether that's the desired behavior.
    for (var importElement in library.firstFragment.libraryImports2) {
      var importedLibrary = importElement.importedLibrary2;
      if (importedLibrary != null) {
        _addDeclarationsImportedFrom(
          library: importedLibrary,
          namespace: importElement.namespace,
          prefix: importElement.prefix2?.element.name3,
        );
        if (importedLibrary.isDartCore && mustBeType) {
          var name = 'Never';
          var matcherScore = state.matcher.score(name);
          if (matcherScore != -1) {
            collector.addSuggestion(
              NameSuggestion(name: name, matcherScore: matcherScore),
            );
          }
        }
      }
    }
  }

  /// Adds a suggestion for the top-level [element].
  void _addImportedElement(Element2 element) {
    var matcherScore = state.matcher.score(element.displayName);
    if (matcherScore != -1) {
      var suggestion = switch (element) {
        ClassElement2() => ClassSuggestion(
          importData: null,
          element: element,
          matcherScore: matcherScore,
        ),
        EnumElement2() => EnumSuggestion(
          importData: null,
          element: element,
          matcherScore: matcherScore,
        ),
        ExtensionElement2() => ExtensionSuggestion(
          importData: null,
          element: element,
          matcherScore: matcherScore,
        ),
        ExtensionTypeElement2() => ExtensionTypeSuggestion(
          importData: null,
          element: element,
          matcherScore: matcherScore,
        ),
        TopLevelFunctionElement() => TopLevelFunctionSuggestion(
          importData: null,
          element: element,
          kind: _executableSuggestionKind,
          matcherScore: matcherScore,
        ),
        MixinElement2() => MixinSuggestion(
          importData: null,
          element: element,
          matcherScore: matcherScore,
        ),
        PropertyAccessorElement2() => _createSuggestionFromTopLevelProperty(
          element,
          matcherScore,
        ),
        TopLevelVariableElement2() => TopLevelVariableSuggestion(
          importData: null,
          element: element,
          matcherScore: matcherScore,
        ),
        TypeAliasElement2() => TypeAliasSuggestion(
          importData: null,
          element: element,
          matcherScore: matcherScore,
        ),
        _ => null,
      };
      if (suggestion != null) {
        collector.addSuggestion(suggestion);
      }
    }
  }

  /// Adds suggestions for any instance members inherited by the
  /// [containingMember].
  void _addInheritedMembers(CompilationUnitMember containingMember) {
    var fragment = switch (containingMember) {
      ClassDeclaration() => containingMember.declaredFragment,
      EnumDeclaration() => containingMember.declaredFragment,
      ExtensionDeclaration() => containingMember.declaredFragment,
      ExtensionTypeDeclaration() => containingMember.declaredFragment,
      MixinDeclaration() => containingMember.declaredFragment,
      ClassTypeAlias() => containingMember.declaredFragment,
      GenericTypeAlias() => containingMember.declaredFragment,
      _ => null,
    };
    var element = fragment?.element;
    if (!mustBeStatic && element is ExtensionElement2) {
      var thisType = element.thisType;
      if (thisType is InterfaceType) {
        _addInstanceMembers(
          type: thisType,
          excludedGetters: {},
          includeMethods: true,
          includeSetters: true,
        );
      }
      return;
    }
    if (element is! InterfaceElement2) {
      return;
    }
    var referencingInterface = _referencingInterfaceFor(element);
    var members = request.inheritanceManager.getInheritedMap(element);
    for (var member in members.values) {
      switch (member) {
        case MethodElement2():
          _suggestMethod(
            method: member,
            referencingInterface: referencingInterface,
          );
        case PropertyAccessorElement2():
          _suggestProperty(
            accessor: member,
            referencingInterface: referencingInterface,
          );
      }
    }
  }

  /// Adds completion suggestions for instance members of the given [type].
  ///
  /// Suggestions will not be added for any getters whose names are in the set
  /// of [excludedGetters].
  ///
  /// Suggestions for methods will only be added if [includeMethods] is `true`.
  ///
  /// Suggestions for setters will only be added if [includeSetters] is `true`.
  ///
  /// If [onlySuper] is `true`, only valid super members will be suggested.
  void _addInstanceMembers({
    required InterfaceType type,
    required Set<String> excludedGetters,
    required bool includeMethods,
    required bool includeSetters,
    bool onlySuper = false,
  }) {
    var substitution = Substitution.fromInterfaceType(type);
    var map =
        onlySuper
            ? request.inheritanceManager.getInheritedConcreteMap(type.element3)
            : request.inheritanceManager.getInterface2(type.element3).map2;

    var membersByName = <String, List<ExecutableElement2>>{};
    for (var rawMember in map.values) {
      if (_canAccessInstanceMember(rawMember)) {
        var name = rawMember.displayName;
        membersByName
            .putIfAbsent(name, () => <ExecutableElement2>[])
            .add(rawMember);
      }
    }
    var referencingInterface = _referencingInterfaceFor(type.element3);
    for (var entry in membersByName.entries) {
      var members = entry.value;
      var rawMember = members.bestMember;
      if (rawMember is MethodElement2) {
        if (includeMethods) {
          // Exclude static methods when completion on an instance.
          var member = ExecutableMember.from(rawMember, substitution);
          _suggestMethod(
            method: member as MethodElement2,
            referencingInterface: referencingInterface,
          );
        }
      } else if (rawMember is GetterElement) {
        if (!excludedGetters.contains(entry.key)) {
          var member = ExecutableMember.from(rawMember, substitution);
          _suggestProperty(
            accessor: member as PropertyAccessorElement2,
            referencingInterface: referencingInterface,
          );
        }
      } else if (rawMember is SetterElement) {
        if (includeSetters) {
          var member = ExecutableMember.from(rawMember, substitution);
          _suggestProperty(
            accessor: member as PropertyAccessorElement2,
            referencingInterface: referencingInterface,
          );
        }
      }
    }
    if ((type.isDartCoreFunction && !onlySuper) ||
        type.allSupertypes.any((type) => type.isDartCoreFunction)) {
      _suggestFunctionCall(); // from builder
    }
    // Add members from extensions. Members from extensions accessible in the
    // same library as the completion location are suggested in this pass.
    // Members from extensions that are not currently imported are suggested in
    // the second pass.
    _addExtensionMembers(
      type: type,
      excludedGetters: excludedGetters,
      includeMethods: includeMethods,
      includeSetters: includeSetters,
    );
    _recordOperation(
      InstanceExtensionMembersOperation(
        declarationHelper: this,
        type: type,
        excludedGetters: excludedGetters,
        includeMethods: includeMethods,
        includeSetters: includeSetters,
      ),
    );
  }

  /// Adds suggestions for any local declarations that are visible at the
  /// completion location, given that the completion location is within the
  /// [node].
  ///
  /// This includes local variables, local functions, parameters, and type
  /// parameters defined on local functions.
  ///
  /// Return the member containing the local declarations that were added, or
  /// `null` if there is an error such as the AST being malformed or we
  /// encountered an AST structure that isn't handled correctly.
  ///
  /// The returned member can be either a [ClassMember] or a
  /// [CompilationUnitMember].
  AstNode? _addLocalDeclarations(AstNode node) {
    AstNode? previousNode;
    AstNode? currentNode = node;
    while (currentNode != null) {
      switch (currentNode) {
        case Block():
          _visitStatements(currentNode.statements, previousNode);
        case CatchClause():
          _visitCatchClause(currentNode);
        case CommentReference():
          return _visitCommentReference(currentNode);
        case ConstructorDeclaration():
          _visitParameterList(currentNode.parameters);
          return currentNode;
        case DeclaredVariablePattern():
          _visitDeclaredVariablePattern(currentNode);
        case FieldDeclaration():
          return currentNode;
        case ForElement(forLoopParts: var parts):
          if (parts != previousNode) {
            _visitForLoopParts(parts);
          }
        case ForStatement(forLoopParts: var parts):
          if (parts != previousNode) {
            _visitForLoopParts(parts);
          }
        case ForPartsWithDeclarations(:var variables):
          if (variables != previousNode) {
            _visitForLoopParts(currentNode);
          }
        case FunctionDeclaration(:var parent):
          if (parent is! FunctionDeclarationStatement) {
            return currentNode;
          }
        case FunctionDeclarationStatement():
          var declaration = currentNode.functionDeclaration;
          var functionElement = declaration.declaredFragment?.element;
          if (functionElement != null) {
            _suggestLocalFunction(functionElement);
          }
        case FunctionExpression():
          _visitParameterList(currentNode.parameters);
          _visitTypeParameterList(currentNode.typeParameters);
        case IfElement():
          _visitIfElement(currentNode);
        case IfStatement():
          _visitIfStatement(currentNode);
        case MethodDeclaration():
          _visitParameterList(currentNode.parameters);
          _visitTypeParameterList(currentNode.typeParameters);
          return currentNode;
        case SwitchCase():
          _visitStatements(currentNode.statements, previousNode);
        case SwitchDefault():
          _visitStatements(currentNode.statements, previousNode);
        case SwitchExpressionCase():
          _visitSwitchExpressionCase(currentNode);
        case SwitchPatternCase():
          _visitSwitchPatternCase(currentNode, previousNode);
        case VariableDeclarationList():
          _visitVariableDeclarationList(currentNode, previousNode);
        case CompilationUnit():
        case CompilationUnitMember():
          return currentNode;
      }
      previousNode = currentNode;
      currentNode = currentNode.parent;
    }
    return currentNode;
  }

  /// Adds suggestions for any local types that are visible at the completion
  /// location, given that the completion location is within the [node].
  ///
  /// This includes only type parameters.
  ///
  /// Return the member containing the local declarations that were added, or
  /// `null` if there is an error such as the AST being malformed or we
  /// encountered an AST structure that isn't handled correctly.
  ///
  /// The returned member can be either a [ClassMember] or a
  /// [CompilationUnitMember].
  AstNode? _addLocalTypes(AstNode node) {
    AstNode? currentNode = node;
    while (currentNode != null) {
      switch (currentNode) {
        case CommentReference():
          return currentNode;
        case ConstructorDeclaration():
          _visitParameterList(currentNode.parameters);
          return currentNode;
        case FieldDeclaration():
          return currentNode;
        case FunctionDeclaration(:var parent):
          if (parent is! FunctionDeclarationStatement) {
            return currentNode;
          }
        case FunctionExpression():
          _visitTypeParameterList(currentNode.typeParameters);
        case GenericFunctionType():
          _visitTypeParameterList(currentNode.typeParameters);
        case MethodDeclaration():
          _visitTypeParameterList(currentNode.typeParameters);
          return currentNode;
        case CompilationUnit():
        case CompilationUnitMember():
          return currentNode;
      }
      currentNode = currentNode.parent;
    }
    return currentNode;
  }

  /// Adds suggestions for the instance members declared on `Object`.
  void _addMembersOfDartCoreObject() {
    _addInstanceMembers(
      type: request.objectType,
      excludedGetters: const {},
      includeMethods: true,
      includeSetters: true,
    );
  }

  /// Completion is inside the declaration of the [element].
  void _addMembersOfEnclosingInstance(InstanceElement2 element) {
    var referencingInterface = _referencingInterfaceFor(element);

    for (var accessor in element.getters2) {
      if (!accessor.isSynthetic && (!mustBeStatic || accessor.isStatic)) {
        _suggestProperty(
          accessor: accessor,
          referencingInterface: referencingInterface,
        );
      }
    }

    for (var accessor in element.setters2) {
      if (!accessor.isSynthetic && (!mustBeStatic || accessor.isStatic)) {
        _suggestProperty(
          accessor: accessor,
          referencingInterface: referencingInterface,
        );
      }
    }

    for (var field in element.fields2) {
      if (!field.isSynthetic && (!mustBeStatic || field.isStatic)) {
        _suggestField(field: field, referencingInterface: referencingInterface);
      }
    }

    for (var method in element.methods2) {
      if (!mustBeStatic || method.isStatic) {
        _suggestMethod(
          method: method,
          referencingInterface: referencingInterface,
        );
      }
    }
    var thisType = element.thisType;
    if (thisType is InterfaceType) {
      _addExtensionMembers(
        type: thisType,
        excludedGetters: {},
        includeMethods: true,
        includeSetters: true,
      );
    }
  }

  /// Completion is inside [declaration].
  void _addMembersOfEnclosingNode(CompilationUnitMember declaration) {
    switch (declaration) {
      case ClassDeclaration():
        var element = declaration.declaredFragment?.element;
        if (element != null) {
          if (!mustBeType) {
            _addMembersOfEnclosingInstance(element);
          }
          _suggestTypeParameters(element.typeParameters2);
        }
      case ClassTypeAlias():
        var element = declaration.declaredFragment?.element;
        if (element != null) {
          _suggestTypeParameters(element.typeParameters2);
        }
      case EnumDeclaration():
        var element = declaration.declaredFragment?.element;
        if (element != null) {
          if (!mustBeType) {
            _addMembersOfEnclosingInstance(element);
          }
          _suggestTypeParameters(element.typeParameters2);
        }
      case ExtensionDeclaration():
        var element = declaration.declaredFragment?.element;
        if (element != null) {
          if (!mustBeType) {
            _addMembersOfEnclosingInstance(element);
          }
          _suggestTypeParameters(element.typeParameters2);
        }
      case ExtensionTypeDeclaration():
        var element = declaration.declaredFragment?.element;
        if (element != null) {
          if (!mustBeType) {
            _addMembersOfEnclosingInstance(element);
            var fieldElement = element.representation2;
            _suggestField(field: fieldElement);
          }
          _suggestTypeParameters(element.typeParameters2);
        }
      case FunctionTypeAlias():
        var element = declaration.declaredFragment?.element;
        if (element != null) {
          _suggestTypeParameters(element.typeParameters2);
        }
      case GenericTypeAlias():
        var element = declaration.declaredFragment?.element;
        if (element is TypeAliasElement2) {
          _suggestTypeParameters(element.typeParameters2);
        }
      case MixinDeclaration():
        var element = declaration.declaredFragment?.element;
        if (element != null) {
          if (!mustBeType) {
            _addMembersOfEnclosingInstance(element);
          }
          _suggestTypeParameters(element.typeParameters2);
        }
    }
  }

  /// Adds the static [getters], [setters], [constructors], [fields], and
  /// [methods] defined by the [containingElement].
  void _addStaticMembers({
    required List<GetterElement> getters,
    required List<SetterElement> setters,
    required List<ConstructorElement2> constructors,
    required Element2 containingElement,
    required List<FieldElement2> fields,
    required List<MethodElement2> methods,
  }) {
    for (var getter in getters) {
      if (getter.isStatic &&
          !getter.isSynthetic &&
          getter.isVisibleIn(request.libraryElement)) {
        _suggestProperty(accessor: getter);
      }
    }
    for (var setter in setters) {
      if (setter.isStatic &&
          !setter.isSynthetic &&
          setter.isVisibleIn(request.libraryElement)) {
        _suggestProperty(accessor: setter);
      }
    }
    for (var field in fields) {
      if (field.isStatic &&
          (!field.isSynthetic ||
              (containingElement is EnumElement2 && field.name3 == 'values')) &&
          field.isVisibleIn(request.libraryElement)) {
        if (field.isEnumConstant) {
          var enumElement = field.enclosingElement2;
          var matcherScore = state.matcher.score(
            '${enumElement.name3}.${field.name3}',
          );
          if (matcherScore != -1) {
            var suggestion = EnumConstantSuggestion(
              importData: null,
              element: field,
              includeEnumName: false,
              matcherScore: matcherScore,
            );
            collector.addSuggestion(suggestion);
          }
        } else {
          _suggestField(field: field);
        }
      }
    }
    if (!mustBeAssignable) {
      var allowNonFactory =
          containingElement is ClassElement2 && !containingElement.isAbstract;
      for (var constructor in constructors) {
        if (constructor.isVisibleIn(request.libraryElement) &&
            (allowNonFactory || constructor.isFactory)) {
          _suggestConstructor(
            constructor,
            hasClassName: true,
            importData: null,
            isConstructorRedirect: false,
          );
        }
      }
      for (var method in methods) {
        if (method.isStatic && method.isVisibleIn(request.libraryElement)) {
          _suggestMethod(method: method);
        }
      }
    }
  }

  /// Adds suggestions for any top-level declarations that are visible within
  /// the [library].
  ///
  /// The [library] is the library in which completion is being requested.
  void _addTopLevelDeclarations(LibraryElement2 library) {
    for (var element in library.classes) {
      _suggestClass(element, null);
    }
    for (var element in library.enums) {
      _suggestEnum(element, null);
    }
    // TODO(brianwilkerson): This should suggest extensions that have static
    //  members. We appear to not have any tests for this case.
    for (var element in library.extensionTypes) {
      _suggestExtensionType(element, null);
    }
    for (var element in library.mixins) {
      _suggestMixin(element, null);
    }
    for (var element in library.typeAliases) {
      _suggestTypeAlias(element, null);
    }
    if (!mustBeType) {
      for (var element in library.getters) {
        if (!element.isSynthetic) {
          _suggestTopLevelProperty(element, null);
        }
      }
      for (var element in library.setters) {
        if (!element.isSynthetic) {
          if (element.correspondingGetter2 == null) {
            _suggestTopLevelProperty(element, null);
          }
        }
      }
      for (var element in library.extensions) {
        if (element.name3 != null) {
          _suggestExtension(element, null);
        }
      }
      for (var element in library.topLevelFunctions) {
        _suggestTopLevelFunction(element, null);
      }
      for (var element in library.topLevelVariables) {
        if (!element.isSynthetic) {
          _suggestTopLevelVariable(element, null);
        }
      }
    }
  }

  bool _canAccessInstanceMember(ExecutableElement2 element) {
    if (element.isStatic) {
      return false;
    }

    var requestLibrary = request.libraryElement;
    if (!element.isAccessibleIn2(requestLibrary)) {
      return false;
    }

    if (element.isInternal) {
      switch (request.fileState.workspacePackage) {
        case PubPackage pubPackage:
          var librarySource = element.library2.firstFragment.source;
          if (!pubPackage.contains(librarySource)) {
            return false;
          }
      }
    }

    if (element.isProtected) {
      var elementInterface = element.enclosingElement2;
      if (elementInterface is! InterfaceElement2) {
        return false;
      }

      if (elementInterface.library2 != requestLibrary) {
        var contextInterface = request.target.enclosingInterfaceElement;
        if (contextInterface == null) {
          return false;
        }

        var contextType = contextInterface.thisType;
        if (contextType.asInstanceOf2(elementInterface) == null) {
          return false;
        }
      }
    }

    if (element.isVisibleForTesting) {
      if (element.library2 != requestLibrary) {
        var fileState = request.fileState;
        switch (fileState.workspacePackage) {
          case PubPackage pubPackage:
            // Must be in the same package.
            var librarySource = element.library2.firstFragment.source;
            if (!pubPackage.contains(librarySource)) {
              return false;
            }
            // Must be in the `test` directory.
            if (!pubPackage.isInTestDirectory(fileState.resource)) {
              return false;
            }
        }
      }
    }

    return true;
  }

  ImportableSuggestion? _createSuggestionFromTopLevelProperty(
    PropertyAccessorElement2 element,
    double matcherScore, {
    ImportData? importData,
  }) {
    if (element.isSynthetic) {
      if (element is GetterElement) {
        var variable = element.variable3;
        if (variable is TopLevelVariableElement2) {
          return TopLevelVariableSuggestion(
            importData: importData,
            element: variable,
            matcherScore: matcherScore,
          );
        }
      }
    } else {
      if (element is GetterElement) {
        return TopLevelGetterSuggestion(
          importData: importData,
          element: element,
          matcherScore: matcherScore,
        );
      } else {
        return TopLevelSetterSuggestion(
          importData: importData,
          element: element as SetterElement,
          matcherScore: matcherScore,
        );
      }
    }
    return null;
  }

  /// Returns `true` if the [identifier] is a wildcard (a single `_`).
  bool _isWildcard(String? identifier) => identifier == '_';

  /// Record that the given [operation] should be performed in the second pass.
  void _recordOperation(NotImportedOperation operation) {
    notImportedOperations.add(operation);
  }

  /// Returns the interface element for the type of `this` within the
  /// declaration of the given class-like [element].
  InterfaceElement2? _referencingInterfaceFor(Element2 element) {
    if (element is InterfaceElement2) {
      return element;
    } else if (element is InstanceElement2) {
      var thisElement = element.thisType.element3;
      if (thisElement is InterfaceElement2) {
        return thisElement;
      }
    }
    return null;
  }

  /// Adds a suggestion for the class represented by the [element].
  void _suggestClass(ClassElement2 element, ImportData? importData) {
    if (visibilityTracker.isVisible(element: element, importData: importData)) {
      if ((mustBeExtendable &&
              !element.isExtendableIn2(request.libraryElement)) ||
          (mustBeImplementable &&
              !element.isImplementableIn2(request.libraryElement)) ||
          (mustBeMixable && !element.isMixableIn2(request.libraryElement))) {
        return;
      }
      if (!(mustBeConstant && !objectPatternAllowed) && !excludeTypeNames) {
        var matcherScore = state.matcher.score(element.displayName);
        if (matcherScore != -1) {
          var suggestion = ClassSuggestion(
            importData: importData,
            element: element,
            matcherScore: matcherScore,
          );
          collector.addSuggestion(suggestion);
        }
      }
      if (!mustBeType) {
        _suggestStaticFields(element.fields2, importData);
        _suggestConstructors(
          element.constructors2,
          importData,
          allowNonFactory: !element.isAbstract,
        );
      }
    }
  }

  /// Adds a suggestion for the constructor represented by the [element].
  void _suggestConstructor(
    ConstructorElement2 element, {
    required ImportData? importData,
    required bool hasClassName,
    required bool isConstructorRedirect,
  }) {
    if (mustBeAssignable) {
      return;
    }

    if (!element.isVisibleIn(request.libraryElement)) {
      return;
    }
    if (importData?.isNotImported ?? false) {
      if (!visibilityTracker.isVisible(
        element: element.enclosingElement2,
        importData: importData,
      )) {
        // If the constructor is on a class from a not-yet-imported library and
        // the class isn't visible, then we shouldn't suggest it.
        //
        // We could consider computing a prefix and updating the [importData] in
        // order to avoid the collision, but we don't currently do that for any
        // not-yet-imported elements (nor for imported elements that are
        // shadowed by local declarations).
        return;
      }
    } else {
      // Add the class to the visibility tracker so that we will know later that
      // any non-imported elements with the same name are not visible.
      visibilityTracker.isVisible(
        element: element.enclosingElement2,
        importData: importData,
      );
    }

    // TODO(keertip): Compute the completion string.
    var matcherScore = state.matcher.score(element.displayName);
    if (matcherScore != -1) {
      var isTearOff =
          preferNonInvocation || (mustBeConstant && !element.isConst);

      var suggestion = ConstructorSuggestion(
        importData: importData,
        element: element,
        hasClassName: hasClassName,
        isTearOff: isTearOff,
        isRedirect: isConstructorRedirect,
        suggestUnnamedAsNew: suggestUnnamedAsNew || isTearOff,
        matcherScore: matcherScore,
      );
      collector.addSuggestion(suggestion);
    }
  }

  /// Adds a suggestion for each of the [constructors].
  void _suggestConstructors(
    List<ConstructorElement2> constructors,
    ImportData? importData, {
    bool allowNonFactory = true,
  }) {
    if (mustBeAssignable) {
      return;
    }
    for (var constructor in constructors) {
      if (constructor.isVisibleIn(request.libraryElement) &&
          (allowNonFactory || constructor.isFactory)) {
        _suggestConstructor(
          constructor,
          hasClassName: false,
          importData: importData,
          isConstructorRedirect: false,
        );
      }
    }
  }

  /// Adds a suggestion for the enum represented by the [element].
  void _suggestEnum(EnumElement2 element, ImportData? importData) {
    if (visibilityTracker.isVisible(element: element, importData: importData)) {
      if (mustBeExtendable || mustBeImplementable || mustBeMixable) {
        return;
      }
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = EnumSuggestion(
          importData: importData,
          element: element,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }

      if (!mustBeType) {
        _suggestStaticFields(element.fields2, importData);
        _suggestConstructors(
          element.constructors2,
          importData,
          allowNonFactory: false,
        );
      }
    }
  }

  /// Adds a suggestion for the extension represented by the [element].
  void _suggestExtension(ExtensionElement2 element, ImportData? importData) {
    if (visibilityTracker.isVisible(element: element, importData: importData)) {
      if (mustBeExtendable || mustBeImplementable || mustBeMixable) {
        return;
      }
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = ExtensionSuggestion(
          importData: importData,
          element: element,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }
      if (!mustBeType) {
        _suggestStaticFields(element.fields2, importData);
      }
    }
  }

  /// Adds a suggestion for the extension type represented by the [element].
  void _suggestExtensionType(
    ExtensionTypeElement2 element,
    ImportData? importData,
  ) {
    if (visibilityTracker.isVisible(element: element, importData: importData)) {
      if (mustBeExtendable || mustBeImplementable || mustBeMixable) {
        return;
      }
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = ExtensionTypeSuggestion(
          importData: importData,
          element: element,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }
      if (!mustBeType) {
        _suggestStaticFields(element.fields2, importData);
        _suggestConstructors(element.constructors2, importData);
      }
    }
  }

  /// Adds a suggestion for the [field].
  ///
  /// The [referencingInterface] is used to compute the inheritance distance to
  /// an instance member, and should not be provided for static members. If a
  /// [referencingInterface] is provided, it should be the class in which
  /// completion was requested.
  void _suggestField({
    required FieldElement2 field,
    InterfaceElement2? referencingInterface,
  }) {
    if (visibilityTracker.isVisible(element: field, importData: null)) {
      if ((mustBeAssignable && field.setter2 == null) ||
          (mustBeConstant && !field.isConst)) {
        return;
      }
      var matcherScore = state.matcher.score(field.displayName);
      if (matcherScore != -1) {
        var suggestion = FieldSuggestion(
          element: field,
          matcherScore: matcherScore,
          referencingInterface: referencingInterface,
        );
        collector.addSuggestion(suggestion);
      }
    }
  }

  /// Adds a suggestion for the method `call` defined on the class `Function`.
  void _suggestFunctionCall() {
    var matcherScore = state.matcher.score('call');
    if (matcherScore != -1) {
      collector.addSuggestion(FunctionCall(matcherScore: matcherScore));
    }
  }

  /// Adds a suggestion for the local function represented by the [element].
  void _suggestLocalFunction(ExecutableElement2 element) {
    if (element is LocalFunctionElement &&
        visibilityTracker.isVisible(element: element, importData: null)) {
      if (mustBeAssignable ||
          mustBeConstant ||
          (mustBeNonVoid && element.returnType is VoidType)) {
        return;
      }
      // Don't suggest wildcard local functions.
      if (_isWildcard(element.name3)) return;
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = LocalFunctionSuggestion(
          kind: _executableSuggestionKind,
          element: element,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }
    }
  }

  /// Adds a suggestion for the [method].
  ///
  /// If [ignoreVisibility] is `true` then the visibility tracker will not be
  /// used to determine whether the element is shadowed. This should be used
  /// when suggesting a member accessed through a target.
  ///
  /// The [referencingInterface] is used to compute the inheritance distance to
  /// an instance member, and should not be provided for static members. If a
  /// [referencingInterface] is provided, it should be the class in which
  /// completion was requested.
  void _suggestMethod({
    required MethodElement2 method,
    bool ignoreVisibility = false,
    ImportData? importData,
    InterfaceElement2? referencingInterface,
  }) {
    if (ignoreVisibility ||
        visibilityTracker.isVisible(element: method, importData: importData)) {
      if (mustBeAssignable ||
          mustBeConstant ||
          (mustBeNonVoid && method.returnType is VoidType)) {
        return;
      }
      var matcherScore = state.matcher.score(method.displayName);
      if (matcherScore != -1) {
        var enclosingElement = method.enclosingElement2;
        if (method.name3 == 'setState' &&
            enclosingElement is ClassElement2 &&
            enclosingElement.isExactState) {
          var suggestion = SetStateMethodSuggestion(
            element: method,
            importData: importData,
            referencingInterface: referencingInterface,
            matcherScore: matcherScore,
            indent: state.indent,
          );
          collector.addSuggestion(suggestion);
          return;
        }
        var suggestion = MethodSuggestion(
          kind: _executableSuggestionKind,
          element: method,
          importData: importData,
          matcherScore: matcherScore,
          referencingInterface: referencingInterface,
        );
        collector.addSuggestion(suggestion);
      }
    }
  }

  /// Adds a suggestion for the mixin represented by the [element].
  void _suggestMixin(MixinElement2 element, ImportData? importData) {
    if (visibilityTracker.isVisible(element: element, importData: importData)) {
      if (mustBeExtendable ||
          (mustBeImplementable &&
              !element.isImplementableIn2(request.libraryElement))) {
        return;
      }
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = MixinSuggestion(
          importData: importData,
          element: element,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }
      if (!mustBeType) {
        _suggestStaticFields(element.fields2, importData);
      }
    }
  }

  /// Adds a suggestion for the parameter represented by the [element].
  void _suggestParameter(FormalParameterElement element) {
    if (visibilityTracker.isVisible(element: element, importData: null)) {
      if (mustBeConstant || _isWildcard(element.name3)) {
        return;
      }
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = FormalParameterSuggestion(
          element: element,
          distance: _variableDistance++,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }
    }
  }

  /// Adds a suggestion for the getter or setter represented by the [accessor].
  ///
  /// If [ignoreVisibility] is `true` then the visibility tracker will not be
  /// used to determine whether the element is shadowed. This should be used
  /// when suggesting a member accessed through a target.
  ///
  /// The [referencingInterface] is used to compute the inheritance distance to
  /// an instance member, and should not be provided for static members. If a
  /// [referencingInterface] is provided, it should be the class in which
  /// completion was requested.
  void _suggestProperty({
    required PropertyAccessorElement2 accessor,
    bool ignoreVisibility = false,
    ImportData? importData,
    InterfaceElement2? referencingInterface,
  }) {
    if (ignoreVisibility ||
        visibilityTracker.isVisible(
          element: accessor,
          importData: importData,
        )) {
      if ((mustBeAssignable &&
              accessor is GetterElement &&
              accessor.correspondingSetter2 == null) ||
          mustBeConstant ||
          (mustBeNonVoid && accessor.returnType is VoidType)) {
        return;
      }
      var matcherScore = state.matcher.score(accessor.displayName);
      if (matcherScore != -1) {
        if (accessor.isSynthetic) {
          // Avoid visiting a field twice. All fields induce a getter, but only
          // non-final fields induce a setter, so we don't add a suggestion for a
          // synthetic setter.
          if (accessor is GetterElement) {
            var variable = accessor.variable3;
            if (variable is FieldElement2) {
              var suggestion = FieldSuggestion(
                element: variable,
                matcherScore: matcherScore,
                referencingInterface: referencingInterface,
              );
              collector.addSuggestion(suggestion);
            }
          }
        } else {
          if (accessor is GetterElement) {
            var suggestion = GetterSuggestion(
              element: accessor,
              importData: importData,
              matcherScore: matcherScore,
              referencingInterface: referencingInterface,
            );
            collector.addSuggestion(suggestion);
          } else {
            var suggestion = SetterSuggestion(
              element: accessor as SetterElement,
              importData: importData,
              matcherScore: matcherScore,
              referencingInterface: referencingInterface,
            );
            collector.addSuggestion(suggestion);
          }
        }
      }
    }
  }

  /// Adds a suggestion for the record type [field] with the given [name].
  void _suggestRecordField({
    required RecordTypeField field,
    required String name,
  }) {
    var matcherScore = state.matcher.score(name);
    if (matcherScore != -1) {
      collector.addSuggestion(
        RecordFieldSuggestion(
          field: field,
          name: name,
          matcherScore: matcherScore,
        ),
      );
    }
  }

  /// Adds a suggestion for the enum constant represented by the [element].
  /// The [importData] should be provided if the enum is imported.
  void _suggestStaticField(FieldElement2 element, ImportData? importData) {
    if (!element.isStatic ||
        (mustBeAssignable && !(element.isFinal || element.isConst)) ||
        (mustBeConstant && !element.isConst)) {
      return;
    }
    var contextType = request.contextType;
    if (contextType != null &&
        request.libraryElement.typeSystem.isSubtypeOf(
          element.type,
          contextType,
        )) {
      if (element.isEnumConstant) {
        var enumElement = element.enclosingElement2;
        var matcherScore = state.matcher.score(
          '${enumElement.displayName}.${element.displayName}',
        );
        if (matcherScore != -1) {
          var suggestion = EnumConstantSuggestion(
            importData: importData,
            element: element,
            matcherScore: matcherScore,
          );
          collector.addSuggestion(suggestion);
        }
      } else {
        var matcherScore = state.matcher.score(element.displayName);
        if (matcherScore != -1) {
          if (element.isSynthetic) {
            var getter = element.getter2;
            if (getter != null) {
              if (getter.isSynthetic) {
                var variable = getter.variable3;
                if (variable is FieldElement2) {
                  var suggestion = FieldSuggestion(
                    element: variable,
                    matcherScore: matcherScore,
                    referencingInterface: null,
                  );
                  collector.addSuggestion(suggestion);
                }
              } else {
                var suggestion = GetterSuggestion(
                  element: getter,
                  importData: importData,
                  referencingInterface: null,
                  matcherScore: matcherScore,
                  withEnclosingName: true,
                );
                collector.addSuggestion(suggestion);
              }
            }
          } else {
            var suggestion = StaticFieldSuggestion(
              importData: importData,
              element: element,
              matcherScore: matcherScore,
            );
            collector.addSuggestion(suggestion);
          }
        }
      }
    }
  }

  /// Adds a suggestion for each of the static fields in the list of [fields].
  void _suggestStaticFields(
    List<FieldElement2> fields,
    ImportData? importData,
  ) {
    for (var field in fields) {
      if (field.isVisibleIn(request.libraryElement)) {
        _suggestStaticField(field, importData);
      }
    }
  }

  /// Adds a suggestion for a parameter that is in the super constructor.
  void _suggestSuperParameter(FormalParameterElement element) {
    var matcherScore = state.matcher.score(element.displayName);
    if (matcherScore != -1) {
      collector.addSuggestion(
        SuperParameterSuggestion(element: element, matcherScore: matcherScore),
      );
    }
  }

  /// Adds a suggestion for the function represented by the [element].
  void _suggestTopLevelFunction(
    TopLevelFunctionElement element,
    ImportData? importData,
  ) {
    if (visibilityTracker.isVisible(element: element, importData: importData)) {
      if (mustBeAssignable ||
          mustBeConstant ||
          (mustBeNonVoid && element.returnType is VoidType) ||
          mustBeType) {
        return;
      }
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = TopLevelFunctionSuggestion(
          importData: importData,
          element: element,
          matcherScore: matcherScore,
          kind: _executableSuggestionKind,
        );
        collector.addSuggestion(suggestion);
      }
    }
  }

  /// Adds a suggestion for the getter or setter represented by the [element].
  void _suggestTopLevelProperty(
    PropertyAccessorElement2 element,
    ImportData? importData,
  ) {
    if (visibilityTracker.isVisible(element: element, importData: importData)) {
      if ((mustBeAssignable &&
              element is GetterElement &&
              element.correspondingSetter2 == null) ||
          (mustBeConstant && !element.isConst) ||
          (mustBeNonVoid && element.returnType is VoidType) ||
          mustBeType) {
        return;
      }
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = _createSuggestionFromTopLevelProperty(
          element,
          matcherScore,
          importData: importData,
        );
        if (suggestion != null) {
          collector.addSuggestion(suggestion);
        }
      }
    }
  }

  /// Adds a suggestion for the getter or setter represented by the [element].
  void _suggestTopLevelVariable(
    TopLevelVariableElement2 element,
    ImportData? importData,
  ) {
    if (visibilityTracker.isVisible(element: element, importData: importData)) {
      if ((mustBeAssignable && element.setter2 == null) ||
          mustBeConstant && !element.isConst ||
          mustBeType) {
        return;
      }
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = TopLevelVariableSuggestion(
          importData: importData,
          element: element,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }
    }
  }

  /// Adds a suggestion for the type alias represented by the [element].
  void _suggestTypeAlias(TypeAliasElement2 element, ImportData? importData) {
    if (visibilityTracker.isVisible(element: element, importData: importData)) {
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = TypeAliasSuggestion(
          importData: importData,
          element: element,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }
      if (!mustBeType) {
        _addConstructorsForAliasedElement(element, importData);
      }
    }
  }

  /// Adds a suggestion for the type parameter represented by the [element].
  void _suggestTypeParameter(TypeParameterElement2 element) {
    if (visibilityTracker.isVisible(element: element, importData: null)) {
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = TypeParameterSuggestion(
          element: element,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }
    }
  }

  /// Adds a suggestion for each of the [typeParameters].
  void _suggestTypeParameters(List<TypeParameterElement2> typeParameters) {
    for (var parameter in typeParameters) {
      if (!_isWildcard(parameter.name3)) {
        _suggestTypeParameter(parameter);
      }
    }
  }

  /// Adds a suggestion for the local variable represented by the [element].
  void _suggestVariable(LocalVariableElement2 element) {
    if (element.isWildcardVariable) return;
    if (visibilityTracker.isVisible(element: element, importData: null)) {
      if (mustBeConstant && !element.isConst) {
        return;
      }
      var matcherScore = state.matcher.score(element.displayName);
      if (matcherScore != -1) {
        var suggestion = LocalVariableSuggestion(
          element: element,
          distance: _variableDistance++,
          matcherScore: matcherScore,
        );
        collector.addSuggestion(suggestion);
      }
    }
  }

  void _visitCatchClause(CatchClause node) {
    var exceptionElement = node.exceptionParameter?.declaredElement2;
    if (exceptionElement != null) {
      _suggestVariable(exceptionElement);
    }

    var stackTraceElement = node.stackTraceParameter?.declaredElement2;
    if (stackTraceElement != null) {
      _suggestVariable(stackTraceElement);
    }
  }

  AstNode? _visitCommentReference(CommentReference node) {
    var comment = node.parent;
    var member = comment?.parent;
    switch (member) {
      case ConstructorDeclaration():
        _visitParameterList(member.parameters);
      case FunctionDeclaration():
        var functionExpression = member.functionExpression;
        _visitParameterList(functionExpression.parameters);
        _visitTypeParameterList(functionExpression.typeParameters);
      case FunctionExpression():
        _visitParameterList(member.parameters);
        _visitTypeParameterList(member.typeParameters);
      case MethodDeclaration():
        _visitParameterList(member.parameters);
        _visitTypeParameterList(member.typeParameters);
    }
    return comment;
  }

  void _visitDeclaredVariablePattern(DeclaredVariablePattern pattern) {
    var declaredElement = pattern.declaredElement2;
    if (declaredElement != null) {
      _suggestVariable(declaredElement);
    }
  }

  void _visitForLoopParts(ForLoopParts node) {
    if (node is ForEachPartsWithDeclaration) {
      var declaredElement = node.loopVariable.declaredElement2;
      if (declaredElement != null) {
        _suggestVariable(declaredElement);
      }
    } else if (node is ForEachPartsWithPattern) {
      _visitPattern(node.pattern);
    } else if (node is ForPartsWithDeclarations) {
      var variables = node.variables;
      for (var variable in variables.variables) {
        var declaredElement = variable.declaredElement2;
        if (declaredElement is LocalVariableElement2) {
          _suggestVariable(declaredElement);
        }
      }
    } else if (node is ForPartsWithPattern) {
      _visitPattern(node.variables.pattern);
    }
  }

  void _visitIfElement(IfElement node) {
    var elseKeyword = node.elseKeyword;
    if (elseKeyword == null || offset < elseKeyword.offset) {
      var pattern = node.caseClause?.guardedPattern.pattern;
      if (pattern != null) {
        _visitPattern(pattern);
      }
    }
  }

  void _visitIfStatement(IfStatement node) {
    var elseKeyword = node.elseKeyword;
    if (elseKeyword == null || offset < elseKeyword.offset) {
      var pattern = node.caseClause?.guardedPattern.pattern;
      if (pattern != null) {
        _visitPattern(pattern);
      }
    }
  }

  void _visitParameterList(FormalParameterList? parameterList) {
    if (parameterList != null) {
      for (var param in parameterList.parameters) {
        var declaredElement = param.declaredFragment?.element;
        if (declaredElement != null) {
          _suggestParameter(declaredElement);
        }
      }
    }
  }

  void _visitPattern(DartPattern pattern) {
    switch (pattern) {
      case CastPattern(:var pattern):
        _visitPattern(pattern);
      case DeclaredVariablePattern():
        _visitDeclaredVariablePattern(pattern);
      case ListPattern():
        for (var element in pattern.elements) {
          if (element is DartPattern) {
            _visitPattern(element);
          } else if (element is RestPatternElement) {
            var elementPattern = element.pattern;
            if (elementPattern != null) {
              _visitPattern(elementPattern);
            }
          }
        }
      case LogicalAndPattern():
        _visitPattern(pattern.leftOperand);
        _visitPattern(pattern.rightOperand);
      case LogicalOrPattern():
        _visitPattern(pattern.leftOperand);
        _visitPattern(pattern.rightOperand);
      case MapPattern():
        for (var element in pattern.elements) {
          if (element is MapPatternEntry) {
            _visitPattern(element.value);
          } else if (element is RestPatternElement) {
            var elementPattern = element.pattern;
            if (elementPattern != null) {
              _visitPattern(elementPattern);
            }
          }
        }
      case NullAssertPattern():
        _visitPattern(pattern.pattern);
      case NullCheckPattern():
        _visitPattern(pattern.pattern);
      case ObjectPattern():
        for (var field in pattern.fields) {
          _visitPattern(field.pattern);
        }
      case ParenthesizedPattern():
        _visitPattern(pattern.pattern);
      case RecordPattern():
        for (var field in pattern.fields) {
          _visitPattern(field.pattern);
        }
      case _:
      // Do nothing
    }
  }

  void _visitStatements(NodeList<Statement> statements, AstNode? child) {
    // Visit the statements in reverse order so that shadowing declarations are
    // found before the declarations they shadow.
    for (var i = statements.length - 1; i >= 0; i--) {
      var statement = statements[i];
      if (statement == child) {
        // Skip the child that was passed in because we will have already
        // visited it and don't want to suggest declared variables twice.
        continue;
      }
      // TODO(brianwilkerson): I think we need to compare to the end of the
      //  statement for variable declarations and the offset for functions.
      if (statement.offset < offset) {
        if (statement is VariableDeclarationStatement) {
          var variables = statement.variables;
          for (var variable in variables.variables) {
            if (variable.end < offset) {
              var declaredElement = variable.declaredElement2;
              if (declaredElement != null) {
                _suggestVariable(declaredElement);
              }
            }
          }
        } else if (statement is FunctionDeclarationStatement) {
          var declaration = statement.functionDeclaration;
          if (declaration.offset < offset) {
            var name = declaration.name.lexeme;
            if (name.isNotEmpty) {
              var declaredElement = declaration.declaredFragment?.element;
              if (declaredElement != null) {
                _suggestLocalFunction(declaredElement);
              }
            }
          }
        } else if (statement is PatternVariableDeclarationStatement) {
          var declaration = statement.declaration;
          if (declaration.end < offset) {
            _visitPattern(declaration.pattern);
          }
        }
      }
    }
  }

  void _visitSwitchExpressionCase(SwitchExpressionCase node) {
    if (offset >= node.arrow.end) {
      _visitPattern(node.guardedPattern.pattern);
    }
  }

  void _visitSwitchPatternCase(SwitchPatternCase node, AstNode? child) {
    if (offset >= node.colon.end) {
      _visitStatements(node.statements, child);
      _visitPattern(node.guardedPattern.pattern);
      var parent = node.parent;
      if (parent is SwitchStatement) {
        var members = parent.members;
        var index = members.indexOf(node) - 1;
        while (index >= 0) {
          var member = members[index];
          if (member is SwitchPatternCase && member.statements.isEmpty) {
            _visitPattern(member.guardedPattern.pattern);
          } else {
            break;
          }
          index--;
        }
      }
    }
  }

  void _visitTypeParameterList(TypeParameterList? typeParameters) {
    if (typeParameters == null) {
      return;
    }

    if (excludedNodes.contains(typeParameters)) {
      return;
    }

    for (var typeParameter in typeParameters.typeParameters) {
      var element = typeParameter.declaredFragment?.element;
      if (element != null) {
        if (!_isWildcard(element.name3)) {
          _suggestTypeParameter(element);
        }
      }
    }
  }

  void _visitVariableDeclarationList(
    VariableDeclarationList node,
    AstNode? child,
  ) {
    var variables = node.variables;
    if (child is VariableDeclaration) {
      var index = variables.indexOf(child);
      for (var i = index - 1; i >= 0; i--) {
        var element = variables[i].declaredElement2;
        if (element != null) {
          _suggestVariable(element);
        }
      }
    }
  }
}

extension on Element2 {
  /// Whether this element is visible within the [referencingLibrary].
  ///
  /// An element is visible if it's declared in the [referencingLibrary] or if
  /// the name is not private.
  bool isVisibleIn(LibraryElement2 referencingLibrary) {
    if (library2 == referencingLibrary) {
      return true;
    }
    var name = name3;
    return name != null && !Identifier.isPrivateName(name);
  }
}

extension on List<ExecutableElement2> {
  /// Returns the element in this list that is the best element to suggest.
  ///
  /// Getters are preferred over setters, otherwise the first element in the
  /// list is returned under the assumption that it's lower in the hierarchy.
  ExecutableElement2 get bestMember {
    ExecutableElement2 bestMember = this[0];
    if (bestMember is SetterElement) {
      for (var i = 1; i < length; i++) {
        var member = this[i];
        if (member is GetterElement) {
          return member;
        }
      }
    }
    return bestMember;
  }
}

extension on PropertyAccessorElement2 {
  /// Whether this accessor is an accessor for a constant variable.
  bool get isConst {
    if (isSynthetic) {
      if (variable3 case var variable?) {
        return variable.isConst;
      }
    }
    return false;
  }
}
