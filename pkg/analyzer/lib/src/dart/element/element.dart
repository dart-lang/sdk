// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    as shared;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/name_union.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/since_sdk_version.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart'
    show Namespace, NamespaceBuilder;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

/// Shared implementation of `augmentation` and `augmentationTarget`.
mixin AugmentableElement<T extends ElementImpl> on ElementImpl {
  T? _augmentation;
  ElementImpl? _augmentationTargetAny;

  T? get augmentation {
    linkedData?.read(this);
    return _augmentation;
  }

  set augmentation(T? value) {
    _augmentation = value;
  }

  T? get augmentationTarget {
    return augmentationTargetAny.ifTypeOrNull();
  }

  ElementImpl? get augmentationTargetAny {
    linkedData?.read(this);
    return _augmentationTargetAny;
  }

  set augmentationTargetAny(ElementImpl? value) {
    _augmentationTargetAny = value;
  }

  bool get isAugmentation {
    return hasModifier(Modifier.AUGMENTATION);
  }

  set isAugmentation(bool value) {
    setModifier(Modifier.AUGMENTATION, value);
  }

  bool get isAugmentationChainStart {
    return hasModifier(Modifier.AUGMENTATION_CHAIN_START);
  }

  set isAugmentationChainStart(bool value) {
    setModifier(Modifier.AUGMENTATION_CHAIN_START, value);
  }

  ElementLinkedData? get linkedData;
}

class AugmentedClassElementImpl extends AugmentedInterfaceElementImpl
    with MaybeAugmentedClassElementMixin {
  @override
  final ClassElementImpl declaration;

  AugmentedClassElementImpl(this.declaration);
}

class AugmentedEnumElementImpl extends AugmentedInterfaceElementImpl
    with MaybeAugmentedEnumElementMixin {
  @override
  final EnumElementImpl declaration;

  AugmentedEnumElementImpl(this.declaration);
}

class AugmentedExtensionElementImpl extends AugmentedInstanceElementImpl
    with MaybeAugmentedExtensionElementMixin {
  @override
  final ExtensionElementImpl declaration;

  AugmentedExtensionElementImpl(this.declaration);
}

class AugmentedExtensionTypeElementImpl extends AugmentedInterfaceElementImpl
    with MaybeAugmentedExtensionTypeElementMixin {
  @override
  final ExtensionTypeElementImpl declaration;

  AugmentedExtensionTypeElementImpl(this.declaration);
}

abstract class AugmentedInstanceElementImpl
    with MaybeAugmentedInstanceElementMixin {
  @override
  List<FieldElement> fields = [];

  @override
  List<PropertyAccessorElement> accessors = [];

  @override
  List<MethodElement> methods = [];

  @override
  // TODO(scheglov): implement metadata
  List<ElementAnnotationImpl> get metadata => throw UnimplementedError();
}

abstract class AugmentedInterfaceElementImpl
    extends AugmentedInstanceElementImpl
    with MaybeAugmentedInterfaceElementMixin {
  @override
  List<InterfaceType> interfaces = [];

  @override
  List<InterfaceType> mixins = [];

  @override
  List<ConstructorElement> constructors = [];

  @override
  String get name => super.name!;
}

class AugmentedMixinElementImpl extends AugmentedInterfaceElementImpl
    with MaybeAugmentedMixinElementMixin {
  @override
  final MixinElementImpl declaration;

  @override
  List<InterfaceType> superclassConstraints = [];

  AugmentedMixinElementImpl(this.declaration);
}

class BindPatternVariableElementImpl extends PatternVariableElementImpl
    implements BindPatternVariableElement {
  final DeclaredVariablePatternImpl node;

  /// This flag is set to `true` if this variable clashes with another
  /// pattern variable with the same name within the same pattern.
  bool isDuplicate = false;

  BindPatternVariableElementImpl(this.node, super.name, super.offset) {
    _element2 = BindPatternVariableElementImpl2(this);
  }

  @override
  BindPatternVariableElementImpl2 get element2 {
    return _element2 as BindPatternVariableElementImpl2;
  }
}

class BindPatternVariableElementImpl2 extends PatternVariableElementImpl2
    implements BindPatternVariableElement2 {
  BindPatternVariableElementImpl2(super._wrappedElement);

  @override
  BindPatternVariableElementImpl get _wrappedElement =>
      super._wrappedElement as BindPatternVariableElementImpl;
}

/// An [InterfaceElementImpl] which is a class.
class ClassElementImpl extends ClassOrMixinElementImpl
    with AugmentableElement<ClassElementImpl>
    implements ClassElement, ClassFragment {
  late MaybeAugmentedClassElementMixin augmentedInternal =
      NotAugmentedClassElementImpl(this);

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  ClassElementImpl(super.name, super.offset);

  @override
  set accessors(List<PropertyAccessorElementImpl> accessors) {
    assert(!isMixinApplication);
    super.accessors = accessors;
  }

  /// If we can find all possible subtypes of this class, return them.
  ///
  /// If the class is final, all its subtypes are declared in this library.
  ///
  /// If the class is sealed, and all its subtypes are either final or sealed,
  /// then these subtypes are all subtypes that are possible.
  List<InterfaceType>? get allSubtypes {
    if (isFinal) {
      var result = <InterfaceType>[];
      for (var element in library.topLevelElements) {
        if (element is InterfaceElement && element != this) {
          var elementThis = element.thisType;
          if (elementThis.asInstanceOf(this) != null) {
            result.add(elementThis);
          }
        }
      }
      return result;
    }

    if (isSealed) {
      var result = <InterfaceType>[];
      for (var element in library.topLevelElements) {
        if (element is! InterfaceElement || identical(element, this)) {
          continue;
        }

        var elementThis = element.thisType;
        if (elementThis.asInstanceOf(this) == null) {
          continue;
        }

        switch (element) {
          case ClassElement _:
            if (element.isFinal || element.isSealed) {
              result.add(elementThis);
            } else {
              return null;
            }
          case EnumElement _:
            result.add(elementThis);
          case MixinElement _:
            return null;
        }
      }
      return result;
    }

    return null;
  }

  @override
  MaybeAugmentedClassElementMixin get augmented {
    if (isAugmentation) {
      if (augmentationTarget case var augmentationTarget?) {
        return augmentationTarget.augmented;
      }
    }

    linkedData?.read(this);
    return augmentedInternal;
  }

  AugmentedClassElementImpl? get augmentedIfReally {
    if (augmentationTarget != null) {
      if (augmented case AugmentedClassElementImpl augmented) {
        return augmented;
      }
    }
    return null;
  }

  @override
  set constructors(List<ConstructorElementImpl> constructors) {
    assert(!isMixinApplication);
    super.constructors = constructors;
  }

  @override
  ClassElement2 get element => super.element as ClassElement2;

  @override
  set fields(List<FieldElementImpl> fields) {
    assert(!isMixinApplication);
    super.fields = fields;
  }

  bool get hasExtendsClause {
    return hasModifier(Modifier.HAS_EXTENDS_CLAUSE);
  }

  set hasExtendsClause(bool value) {
    setModifier(Modifier.HAS_EXTENDS_CLAUSE, value);
  }

  bool get hasGenerativeConstConstructor {
    return constructors.any((c) => !c.isFactory && c.isConst);
  }

  @override
  bool get hasNonFinalField {
    var classesToVisit = <InterfaceElement>[];
    var visitedClasses = <InterfaceElement>{};
    classesToVisit.add(this);
    while (classesToVisit.isNotEmpty) {
      var currentElement = classesToVisit.removeAt(0);
      if (visitedClasses.add(currentElement)) {
        // check fields
        for (FieldElement field in currentElement.fields) {
          if (!field.isFinal &&
              !field.isConst &&
              !field.isStatic &&
              !field.isSynthetic) {
            return true;
          }
        }
        // check mixins
        for (InterfaceType mixinType in currentElement.mixins) {
          classesToVisit.add(mixinType.element);
        }
        // check super
        var supertype = currentElement.supertype;
        if (supertype != null) {
          classesToVisit.add(supertype.element);
        }
      }
    }
    // not found
    return false;
  }

  /// Return `true` if the class has a concrete `noSuchMethod()` method distinct
  /// from the one declared in class `Object`, as per the Dart Language
  /// Specification (section 10.4).
  bool get hasNoSuchMethod {
    MethodElement? method = lookUpConcreteMethod(
        FunctionElement.NO_SUCH_METHOD_METHOD_NAME, library);
    var definingClass = method?.enclosingElement3 as ClassElement?;
    return definingClass != null && !definingClass.isDartCoreObject;
  }

  @override
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  @override
  bool get isConstructable => !isSealed && !isAbstract;

  @override
  bool get isDartCoreEnum {
    return name == 'Enum' && library.isDartCore;
  }

  @override
  bool get isDartCoreObject {
    return name == 'Object' && library.isDartCore;
  }

  bool get isDartCoreRecord {
    return name == 'Record' && library.isDartCore;
  }

  bool get isEnumLike {
    // Must be a concrete class.
    if (isAbstract) {
      return false;
    }

    // With only private non-factory constructors.
    for (var constructor in constructors) {
      if (constructor.isPublic || constructor.isFactory) {
        return false;
      }
    }

    // With 2+ static const fields with the type of this class.
    var numberOfElements = 0;
    for (var field in fields) {
      if (field.isStatic && field.isConst && field.type == thisType) {
        numberOfElements++;
      }
    }
    if (numberOfElements < 2) {
      return false;
    }

    // No subclasses in the library.
    for (var unit in library.units) {
      for (var class_ in unit.classes) {
        if (class_.supertype?.element == this) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  bool get isExhaustive => isSealed;

  @override
  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  set isFinal(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  @override
  bool get isInterface {
    return hasModifier(Modifier.INTERFACE);
  }

  set isInterface(bool isInterface) {
    setModifier(Modifier.INTERFACE, isInterface);
  }

  bool get isMacro {
    return hasModifier(Modifier.MACRO);
  }

  set isMacro(bool isMacro) {
    setModifier(Modifier.MACRO, isMacro);
  }

  @override
  bool get isMixinApplication {
    return hasModifier(Modifier.MIXIN_APPLICATION);
  }

  /// Set whether this class is a mixin application.
  set isMixinApplication(bool isMixinApplication) {
    setModifier(Modifier.MIXIN_APPLICATION, isMixinApplication);
  }

  @override
  bool get isMixinClass {
    return hasModifier(Modifier.MIXIN_CLASS);
  }

  set isMixinClass(bool isMixinClass) {
    setModifier(Modifier.MIXIN_CLASS, isMixinClass);
  }

  @override
  bool get isSealed {
    return hasModifier(Modifier.SEALED);
  }

  set isSealed(bool isSealed) {
    setModifier(Modifier.SEALED, isSealed);
  }

  @override
  bool get isValidMixin {
    var supertype = this.supertype;
    if (supertype != null && !supertype.isDartCoreObject) {
      return false;
    }
    for (ConstructorElement constructor in constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        return false;
      }
    }
    return true;
  }

  @override
  ElementKind get kind => ElementKind.CLASS;

  @override
  set methods(List<MethodElementImpl> methods) {
    assert(!isMixinApplication);
    super.methods = methods;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitClassElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeClassElement(this);
  }

  @override
  bool isExtendableIn(LibraryElement library) {
    if (library == this.library) {
      return true;
    }
    return !isInterface && !isFinal && !isSealed;
  }

  @override
  bool isImplementableIn(LibraryElement library) {
    if (library == this.library) {
      return true;
    }
    return !isBase && !isFinal && !isSealed;
  }

  @override
  bool isMixableIn(LibraryElement library) {
    if (library == this.library) {
      return true;
    } else if (this.library.featureSet.isEnabled(Feature.class_modifiers)) {
      return isMixinClass && !isInterface && !isFinal && !isSealed;
    }
    return true;
  }

  @override
  void _buildMixinAppConstructors() {
    // Do nothing if not a mixin application.
    if (!isMixinApplication) {
      return;
    }

    // Assign to break a possible infinite recursion during computing.
    _constructors = const <ConstructorElementImpl>[];

    var superType = supertype;
    if (superType == null) {
      // Shouldn't ever happen, since the only classes with no supertype are
      // Object and mixins, and they aren't a mixin application. But for
      // safety's sake just assume an empty list.
      assert(false);
      _constructors = <ConstructorElementImpl>[];
      return;
    }

    var superElement = superType.element as ClassElementImpl;

    var constructorsToForward = superElement.constructors
        .where((constructor) => constructor.isAccessibleIn(library))
        .where((constructor) => !constructor.isFactory);

    // Figure out the type parameter substitution we need to perform in order
    // to produce constructors for this class.  We want to be robust in the
    // face of errors, so drop any extra type arguments and fill in any missing
    // ones with `dynamic`.
    var superClassParameters = superElement.typeParameters;
    List<DartType> argumentTypes = List<DartType>.filled(
        superClassParameters.length, DynamicTypeImpl.instance);
    for (int i = 0; i < superType.typeArguments.length; i++) {
      if (i >= argumentTypes.length) {
        break;
      }
      argumentTypes[i] = superType.typeArguments[i];
    }
    var substitution =
        Substitution.fromPairs(superClassParameters, argumentTypes);

    bool typeHasInstanceVariables(InterfaceType type) =>
        type.element.fields.any((e) => !e.isSynthetic);

    // Now create an implicit constructor for every constructor found above,
    // substituting type parameters as appropriate.
    _constructors = constructorsToForward.map((superclassConstructor) {
      var name = superclassConstructor.name;
      var implicitConstructor = ConstructorElementImpl(name, -1);
      implicitConstructor.isSynthetic = true;
      implicitConstructor.name = name;
      implicitConstructor.nameOffset = -1;

      var containerRef = reference!.getChild('@constructor');
      var referenceName = name.ifNotEmptyOrElse('new');
      var implicitReference = containerRef.getChild(referenceName);
      implicitConstructor.reference = implicitReference;
      implicitReference.element = implicitConstructor;

      var hasMixinWithInstanceVariables = mixins.any(typeHasInstanceVariables);
      implicitConstructor.isConst =
          superclassConstructor.isConst && !hasMixinWithInstanceVariables;
      List<ParameterElement> superParameters = superclassConstructor.parameters;
      int count = superParameters.length;
      var argumentsForSuperInvocation = <ExpressionImpl>[];
      if (count > 0) {
        var implicitParameters = <ParameterElement>[];
        for (int i = 0; i < count; i++) {
          ParameterElement superParameter = superParameters[i];
          ParameterElementImpl implicitParameter;
          if (superParameter is ConstVariableElement) {
            var constVariable = superParameter as ConstVariableElement;
            implicitParameter = DefaultParameterElementImpl(
              name: superParameter.name,
              nameOffset: -1,
              // ignore: deprecated_member_use_from_same_package
              parameterKind: superParameter.parameterKind,
            )..constantInitializer = constVariable.constantInitializer;
            if (superParameter.isNamed) {
              var reference = implicitReference
                  .getChild('@parameter')
                  .getChild(implicitParameter.name);
              implicitParameter.reference = reference;
              reference.element = implicitParameter;
            }
          } else {
            implicitParameter = ParameterElementImpl(
              name: superParameter.name,
              nameOffset: -1,
              // ignore: deprecated_member_use_from_same_package
              parameterKind: superParameter.parameterKind,
            );
          }
          implicitParameter.isConst = superParameter.isConst;
          implicitParameter.isFinal = superParameter.isFinal;
          implicitParameter.isSynthetic = true;
          implicitParameter.type =
              substitution.substituteType(superParameter.type);
          implicitParameters.add(implicitParameter);
          argumentsForSuperInvocation.add(
            SimpleIdentifierImpl(
              StringToken(TokenType.STRING, implicitParameter.name, -1),
            )
              ..staticElement = implicitParameter
              ..setPseudoExpressionStaticType(implicitParameter.type),
          );
        }
        implicitConstructor.parameters = implicitParameters.toFixedList();
      }
      implicitConstructor.enclosingElement3 = this;
      implicitConstructor.enclosingElement = this;
      // TODO(scheglov): Why do we manually map parameters types above?
      implicitConstructor.superConstructor =
          ConstructorMember.from(superclassConstructor, superType);

      var isNamed = superclassConstructor.name.isNotEmpty;
      implicitConstructor.constantInitializers = [
        SuperConstructorInvocationImpl(
          superKeyword: Tokens.super_(),
          period: isNamed ? Tokens.period() : null,
          constructorName: isNamed
              ? (SimpleIdentifierImpl(
                  StringToken(TokenType.STRING, superclassConstructor.name, -1),
                )..staticElement = superclassConstructor)
              : null,
          argumentList: ArgumentListImpl(
            leftParenthesis: Tokens.openParenthesis(),
            arguments: argumentsForSuperInvocation,
            rightParenthesis: Tokens.closeParenthesis(),
          ),
        )..staticElement = superclassConstructor,
      ];

      return implicitConstructor;
    }).toList(growable: false);
  }
}

abstract class ClassOrMixinElementImpl extends InterfaceElementImpl {
  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  ClassOrMixinElementImpl(super.name, super.offset);

  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  set isBase(bool isBase) {
    setModifier(Modifier.BASE, isBase);
  }
}

/// A concrete implementation of a [CompilationUnitElement] or
/// [LibraryFragment].
class CompilationUnitElementImpl extends UriReferencedElementImpl
    implements CompilationUnitElement, LibraryFragment {
  /// The source that corresponds to this compilation unit.
  @override
  final Source source;

  @override
  LineInfo lineInfo;

  @override
  final LibraryElementImpl library;

  // TODO(scheglov): Remove after removing [LibraryAugmentationElementImpl].
  late LibraryOrAugmentationElementImpl libraryOrAugmentationElement;

  /// The libraries exported by this unit.
  List<LibraryExportElementImpl> _libraryExports =
      _Sentinel.libraryExportElement;

  /// The libraries imported by this unit.
  List<LibraryImportElementImpl> _libraryImports =
      _Sentinel.libraryImportElement;

  /// The cached list of prefixes from [libraryImports].
  List<PrefixElementImpl>? _libraryImportPrefixes;

  /// The cached list of prefixes from [prefixes].
  List<PrefixElementImpl2>? _libraryImportPrefixes2;

  /// The parts included by this unit.
  List<PartElementImpl> _parts = const <PartElementImpl>[];

  /// A list containing all of the top-level accessors (getters and setters)
  /// contained in this compilation unit.
  List<PropertyAccessorElementImpl> _accessors = const [];

  List<ClassElementImpl> _classes = const [];

  /// A list containing all of the enums contained in this compilation unit.
  List<EnumElementImpl> _enums = const [];

  /// A list containing all of the extensions contained in this compilation
  /// unit.
  List<ExtensionElementImpl> _extensions = const [];

  List<ExtensionTypeElementImpl> _extensionTypes = const [];

  /// A list containing all of the top-level functions contained in this
  /// compilation unit.
  List<FunctionElementImpl> _functions = const [];

  List<MixinElementImpl> _mixins = const [];

  /// A list containing all of the type aliases contained in this compilation
  /// unit.
  List<TypeAliasElementImpl> _typeAliases = const [];

  /// A list containing all of the variables contained in this compilation unit.
  List<TopLevelVariableElementImpl> _variables = const [];

  /// The scope of this fragment, `null` if it has not been created yet.
  LibraryFragmentScope? _scope;

  MacroGeneratedLibraryFragment? macroGenerated;

  ElementLinkedData? linkedData;

  /// Initialize a newly created compilation unit element to have the given
  /// [name].
  CompilationUnitElementImpl({
    required this.library,
    required this.source,
    required this.lineInfo,
  }) : super(null, -1);

  @override
  List<ExtensionElement> get accessibleExtensions {
    return scope.accessibleExtensions;
  }

  @override
  List<ExtensionElement2> get accessibleExtensions2 {
    return scope.accessibleExtensions
        .map((element) => element.augmentation as ExtensionElement2)
        .toList();
  }

  @override
  List<PropertyAccessorElementImpl> get accessors {
    return _accessors;
  }

  /// Set the top-level accessors (getters and setters) contained in this
  /// compilation unit to the given [accessors].
  set accessors(List<PropertyAccessorElementImpl> accessors) {
    for (var accessor in accessors) {
      accessor.enclosingElement3 = this;
      accessor.enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  List<Element> get children => [
        ...super.children,
        ...accessors,
        ...classes,
        ...enums,
        ...extensions,
        ...extensionTypes,
        ...functions,
        ...mixins,
        ...typeAliases,
        ...topLevelVariables,
      ];

  @override
  List<Fragment> get children3 => children.cast<Fragment>();

  @override
  List<ClassElementImpl> get classes {
    return _classes;
  }

  /// Set the classes contained in this compilation unit to [classes].
  set classes(List<ClassElementImpl> classes) {
    for (var class_ in classes) {
      class_.enclosingElement3 = this;
      class_.enclosingElement = this;
    }
    _classes = classes;
  }

  @override
  List<ClassFragment> get classes2 => classes.cast<ClassFragment>();

  @override
  LibraryElementImpl get element => library;

  @override
  LibraryOrAugmentationElement get enclosingElement =>
      libraryOrAugmentationElement;

  @override
  CompilationUnitElementImpl? get enclosingElement3 {
    return super.enclosingElement3 as CompilationUnitElementImpl?;
  }

  @override
  LibraryFragment? get enclosingFragment => null;

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return this;
  }

  @override
  List<EnumElementImpl> get enums {
    return _enums;
  }

  /// Set the enums contained in this compilation unit to the given [enums].
  set enums(List<EnumElementImpl> enums) {
    for (var element in enums) {
      element.enclosingElement3 = this;
      element.enclosingElement = this;
    }
    _enums = enums;
  }

  @override
  List<EnumFragment> get enums2 => enums.cast<EnumFragment>();

  @override
  List<ExtensionElementImpl> get extensions {
    return _extensions;
  }

  /// Set the extensions contained in this compilation unit to the given
  /// [extensions].
  set extensions(List<ExtensionElementImpl> extensions) {
    for (var extension in extensions) {
      extension.enclosingElement3 = this;
      extension.enclosingElement = this;
    }
    _extensions = extensions;
  }

  @override
  List<ExtensionFragment> get extensions2 =>
      extensions.cast<ExtensionFragment>();

  @override
  List<ExtensionTypeElementImpl> get extensionTypes {
    return _extensionTypes;
  }

  set extensionTypes(List<ExtensionTypeElementImpl> elements) {
    for (var element in elements) {
      element.enclosingElement3 = this;
      element.enclosingElement = this;
    }
    _extensionTypes = elements;
  }

  @override
  List<ExtensionTypeFragment> get extensionTypes2 =>
      extensionTypes.cast<ExtensionTypeFragment>();

  @override
  List<LibraryFragmentInclude> get fragmentIncludes =>
      libraryImportPrefixes.cast<LibraryFragmentInclude>();

  @override
  List<FunctionElementImpl> get functions {
    return _functions;
  }

  /// Set the top-level functions contained in this compilation unit to the
  ///  given[functions].
  set functions(List<FunctionElementImpl> functions) {
    for (var function in functions) {
      function.enclosingElement3 = this;
      function.enclosingElement = this;
    }
    _functions = functions;
  }

  @override
  List<TopLevelFunctionFragment> get functions2 =>
      functions.cast<TopLevelFunctionFragment>();

  @override
  List<GetterFragment> get getters => accessors
      .where((element) => element.isGetter)
      .cast<GetterFragment>()
      .toList();

  @override
  int get hashCode => source.hashCode;

  @override
  String get identifier => '${source.uri}';

  @override
  ElementKind get kind => ElementKind.COMPILATION_UNIT;

  @override
  List<LibraryExportElementImpl> get libraryExports {
    linkedData?.read(this);
    return _libraryExports;
  }

  set libraryExports(List<LibraryExportElementImpl> exports) {
    for (var exportElement in exports) {
      exportElement.enclosingElement3 = this;
      exportElement.enclosingElement = library;
    }
    _libraryExports = exports;
  }

  @override
  List<LibraryExport> get libraryExports2 =>
      libraryExports.cast<LibraryExport>();

  List<LibraryExportElementImpl> get libraryExports_unresolved {
    return _libraryExports;
  }

  @override
  LibraryFragment get libraryFragment => this;

  @override
  List<PrefixElementImpl> get libraryImportPrefixes {
    return _libraryImportPrefixes ??= _buildLibraryImportPrefixes();
  }

  @override
  List<LibraryImportElementImpl> get libraryImports {
    linkedData?.read(this);
    return _libraryImports;
  }

  set libraryImports(List<LibraryImportElementImpl> imports) {
    for (var importElement in imports) {
      importElement.enclosingElement3 = this;
      importElement.enclosingElement = library;
    }
    _libraryImports = imports;
    _libraryImportPrefixes = null;
  }

  @override
  List<LibraryImportElementImpl> get libraryImports2 =>
      libraryImports.cast<LibraryImportElementImpl>();

  List<LibraryImportElementImpl> get libraryImports_unresolved {
    return _libraryImports;
  }

  @override
  Source get librarySource => library.source;

  @override
  List<ElementAnnotationImpl> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  List<MixinElementImpl> get mixins {
    return _mixins;
  }

  /// Set the mixins contained in this compilation unit to the given [mixins].
  set mixins(List<MixinElementImpl> mixins) {
    for (var mixin_ in mixins) {
      mixin_.enclosingElement3 = this;
      mixin_.enclosingElement = this;
    }
    _mixins = mixins;
  }

  @override
  List<MixinFragment> get mixins2 => mixins.cast<MixinFragment>();

  @override
  LibraryFragment? get nextFragment {
    var units = library.units;
    var index = units.indexOf(this);
    return units.elementAtOrNull(index + 1);
  }

  @override
  List<PartElementImpl> get parts => _parts;

  set parts(List<PartElementImpl> parts) {
    for (var part in parts) {
      part.enclosingElement3 = this;
      part.enclosingElement = library;
      var uri = part.uri;
      if (uri is DirectiveUriWithUnitImpl) {
        uri.unit.libraryOrAugmentationElement = library;
        uri.unit.enclosingElement3 = this;
        uri.unit.enclosingElement = library;
      }
    }
    _parts = parts;
  }

  @override
  List<PrefixElementImpl2> get prefixes {
    return _libraryImportPrefixes2 ??= _buildLibraryImportPrefixes2();
  }

  @override
  LibraryFragment? get previousFragment {
    var units = library.units;
    var index = units.indexOf(this);
    if (index >= 1) {
      return units[index - 1];
    }
    return null;
  }

  @override
  LibraryFragmentScope get scope {
    return _scope ??= LibraryFragmentScope(this);
  }

  @override
  AnalysisSession get session => library.session;

  @override
  List<SetterFragment> get setters => accessors
      .where((element) => element.isSetter)
      .cast<SetterFragment>()
      .toList();

  @override
  List<TopLevelVariableElementImpl> get topLevelVariables {
    return _variables;
  }

  /// Set the top-level variables contained in this compilation unit to the
  ///  given[variables].
  set topLevelVariables(List<TopLevelVariableElementImpl> variables) {
    for (var variable in variables) {
      variable.enclosingElement3 = this;
      variable.enclosingElement = this;
    }
    _variables = variables;
  }

  @override
  List<TopLevelVariableFragment> get topLevelVariables2 =>
      topLevelVariables.cast<TopLevelVariableFragment>();

  @override
  List<TypeAliasElementImpl> get typeAliases {
    return _typeAliases;
  }

  /// Set the type aliases contained in this compilation unit to [typeAliases].
  set typeAliases(List<TypeAliasElementImpl> typeAliases) {
    for (var typeAlias in typeAliases) {
      typeAlias.enclosingElement3 = this;
      typeAlias.enclosingElement = this;
    }
    _typeAliases = typeAliases;
  }

  @override
  List<TypeAliasFragment> get typeAliases2 =>
      typeAliases.cast<TypeAliasFragment>();

  @override
  bool operator ==(Object other) =>
      other is CompilationUnitElementImpl && source == other.source;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitCompilationUnitElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeCompilationUnitElement(this);
  }

  @override
  ClassElement? getClass(String className) {
    for (var class_ in classes) {
      if (class_.name == className) {
        return class_;
      }
    }
    return null;
  }

  @override
  EnumElement? getEnum(String name) {
    for (var element in enums) {
      if (element.name == name) {
        return element;
      }
    }
    return null;
  }

  /// Returns the mixin defined in this compilation unit that has the given
  /// [name], or `null` if this compilation unit does not define a mixin with
  /// the given name.
  MixinElement? getMixin(String name) {
    for (var mixin in mixins) {
      if (mixin.name == name) {
        return mixin;
      }
    }
    return null;
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }

  /// Indicates whether it is unnecessary to report an undefined identifier
  /// error for an identifier reference with the given [name] and optional
  /// [prefix].
  ///
  /// This method is intended to reduce spurious errors in circumstances where
  /// an undefined identifier occurs as the result of a missing (most likely
  /// code generated) file.  It will only return `true` in a circumstance where
  /// the current library is guaranteed to have at least one other error (due to
  /// a missing part or import), so there is no risk that ignoring the undefined
  /// identifier would cause an invalid program to be treated as valid.
  bool shouldIgnoreUndefined({
    required String? prefix,
    required String name,
  }) {
    for (var libraryFragment in withEnclosing) {
      for (var importElement in libraryFragment.libraryImports) {
        if (importElement.prefix?.element.name == prefix &&
            importElement.importedLibrary?.isSynthetic != false) {
          var showCombinators = importElement.combinators
              .whereType<ShowElementCombinator>()
              .toList();
          if (prefix != null && showCombinators.isEmpty) {
            return true;
          }
          for (var combinator in showCombinators) {
            if (combinator.shownNames.contains(name)) {
              return true;
            }
          }
        }
      }
    }

    if (prefix == null && name.startsWith(r'_$')) {
      for (var partElement in parts) {
        var uri = partElement.uri;
        if (uri is DirectiveUriWithSource &&
            uri is! DirectiveUriWithUnit &&
            file_paths.isGenerated(uri.relativeUriString)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Convenience wrapper around [shouldIgnoreUndefined] that calls it for a
  /// given (possibly prefixed) identifier [node].
  bool shouldIgnoreUndefinedIdentifier(Identifier node) {
    if (node is PrefixedIdentifier) {
      return shouldIgnoreUndefined(
        prefix: node.prefix.name,
        name: node.identifier.name,
      );
    }

    return shouldIgnoreUndefined(
      prefix: null,
      name: (node as SimpleIdentifier).name,
    );
  }

  /// Convenience wrapper around [shouldIgnoreUndefined] that calls it for a
  /// given (possibly prefixed) named type [node].
  bool shouldIgnoreUndefinedNamedType(NamedType node) {
    return shouldIgnoreUndefined(
      prefix: node.importPrefix?.name.lexeme,
      name: node.name2.lexeme,
    );
  }

  List<PrefixElementImpl> _buildLibraryImportPrefixes() {
    var prefixes = <PrefixElementImpl>{};
    for (var import in libraryImports) {
      var prefix = import.prefix?.element;
      if (prefix != null) {
        prefixes.add(prefix);
      }
    }
    return prefixes.toFixedList();
  }

  List<PrefixElementImpl2> _buildLibraryImportPrefixes2() {
    var prefixes = <PrefixElementImpl2>{};
    for (var import in libraryImports2) {
      var prefix = import.prefix2?.element;
      if (prefix != null) {
        prefixes.add(prefix);
      }
    }
    return prefixes.toFixedList();
  }
}

/// A [FieldElement] for a 'const' or 'final' field that has an initializer.
///
// TODO(paulberry): we should rename this class to reflect the fact that it's
// used for both const and final fields.  However, we shouldn't do so until
// we've created an API for reading the values of constants; until that API is
// available, clients are likely to read constant values by casting to
// ConstFieldElementImpl, so it would be a breaking change to rename this
// class.
class ConstFieldElementImpl extends FieldElementImpl with ConstVariableElement {
  /// Initialize a newly created synthetic field element to have the given
  /// [name] and [offset].
  ConstFieldElementImpl(super.name, super.offset);

  @override
  ExpressionImpl? get constantInitializer {
    linkedData?.read(this);
    return super.constantInitializer;
  }
}

/// A [LocalVariableElement] for a local 'const' variable that has an
/// initializer.
class ConstLocalVariableElementImpl extends LocalVariableElementImpl
    with ConstVariableElement {
  /// Initialize a newly created local variable element to have the given [name]
  /// and [offset].
  ConstLocalVariableElementImpl(super.name, super.offset);
}

/// A concrete implementation of a [ConstructorElement].
class ConstructorElementImpl extends ExecutableElementImpl
    with AugmentableElement<ConstructorElementImpl>, ConstructorElementMixin
    implements ConstructorElement, ConstructorFragment {
  /// The super-constructor which this constructor is invoking, or `null` if
  /// this constructor is not generative, or is redirecting, or the
  /// super-constructor is not resolved, or the enclosing class is `Object`.
  ///
  // TODO(scheglov): We cannot have both super and redirecting constructors.
  // So, ideally we should have some kind of "either" or "variant" here.
  ConstructorElement? _superConstructor;

  /// The constructor to which this constructor is redirecting.
  ConstructorElement? _redirectedConstructor;

  /// The initializers for this constructor (used for evaluating constant
  /// instance creation expressions).
  List<ConstructorInitializer> _constantInitializers = const [];

  @override
  int? periodOffset;

  @override
  int? nameEnd;

  /// For every constructor we initially set this flag to `true`, and then
  /// set it to `false` during computing constant values if we detect that it
  /// is a part of a cycle.
  bool isCycleFree = true;

  @override
  bool isConstantEvaluated = false;

  /// The element corresponding to this fragment.
  ConstructorElement2? _element;

  /// Initialize a newly created constructor element to have the given [name]
  /// and [offset].
  ConstructorElementImpl(super.name, super.offset);

  ConstructorElementImpl? get augmentedDeclaration {
    if (isAugmentation) {
      return augmentationTarget?.augmentedDeclaration;
    } else {
      return this;
    }
  }

  /// Return the constant initializers for this element, which will be empty if
  /// there are no initializers, or `null` if there was an error in the source.
  List<ConstructorInitializer> get constantInitializers {
    linkedData?.read(this);
    return _constantInitializers;
  }

  set constantInitializers(List<ConstructorInitializer> constantInitializers) {
    _constantInitializers = constantInitializers;
  }

  @override
  ConstructorElement get declaration => this;

  @override
  String get displayName {
    var className = enclosingElement3.name;
    var name = this.name;
    if (name.isNotEmpty) {
      return '$className.$name';
    } else {
      return className;
    }
  }

  @override
  ConstructorElement2 get element {
    if (_element != null) {
      return _element!;
    }
    ConstructorFragment firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return ConstructorElementImpl2(firstFragment as ConstructorElementImpl);
  }

  set element(ConstructorElement2 element) => _element = element;

  @Deprecated('Use enclosingElement3 instead')
  @override
  InterfaceElement get enclosingElement =>
      super.enclosingElement as InterfaceElementImpl;

  @override
  InterfaceElement get enclosingElement3 =>
      super.enclosingElement3 as InterfaceElementImpl;

  @override
  InstanceFragment? get enclosingFragment =>
      enclosingElement3 as InstanceFragment;

  @override
  bool get hasLiteral {
    if (super.hasLiteral) return true;
    var enclosingElement = enclosingElement3;
    if (enclosingElement is! ExtensionTypeElement) return false;
    return this == enclosingElement.primaryConstructor &&
        enclosingElement.hasLiteral;
  }

  @override
  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  /// Set whether this constructor represents a 'const' constructor.
  set isConst(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  @override
  bool get isFactory {
    return hasModifier(Modifier.FACTORY);
  }

  /// Set whether this constructor represents a factory method.
  set isFactory(bool isFactory) {
    setModifier(Modifier.FACTORY, isFactory);
  }

  @override
  ElementKind get kind => ElementKind.CONSTRUCTOR;

  @override
  int get nameLength {
    var nameEnd = this.nameEnd;
    if (nameEnd == null) {
      return 0;
    } else {
      return nameEnd - nameOffset;
    }
  }

  @override
  ConstructorFragment? get nextFragment => augmentation;

  @override
  Element get nonSynthetic {
    return isSynthetic ? enclosingElement3 : this;
  }

  @override
  ConstructorFragment? get previousFragment => augmentationTarget;

  @override
  ConstructorElement? get redirectedConstructor {
    linkedData?.read(this);
    return _redirectedConstructor;
  }

  set redirectedConstructor(ConstructorElement? redirectedConstructor) {
    _redirectedConstructor = redirectedConstructor;
  }

  @override
  InterfaceType get returnType {
    var result = _returnType;
    if (result != null) {
      return result as InterfaceType;
    }

    var augmentedDeclaration = enclosingElement3.augmented.declaration;
    result = augmentedDeclaration.thisType;
    return _returnType = result as InterfaceType;
  }

  @override
  set returnType(DartType returnType) {
    assert(false);
  }

  @override
  ConstructorElement? get superConstructor {
    linkedData?.read(this);
    return _superConstructor;
  }

  set superConstructor(ConstructorElement? superConstructor) {
    _superConstructor = superConstructor;
  }

  @override
  FunctionType get type {
    // TODO(scheglov): Remove "element" in the breaking changes branch.
    return _type ??= FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  set type(FunctionType type) {
    assert(false);
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  /// Ensures that dependencies of this constructor, such as default values
  /// of formal parameters, are evaluated.
  void computeConstantDependencies() {
    if (!isConstantEvaluated) {
      computeConstants(
        declaredVariables: context.declaredVariables,
        constants: [this],
        featureSet: library.featureSet,
        configuration: ConstantEvaluationConfiguration(),
      );
    }
  }
}

class ConstructorElementImpl2 extends ExecutableElementImpl2
    with
        FragmentedExecutableElementMixin<ConstructorFragment>,
        FragmentedFunctionTypedElementMixin<ConstructorFragment>,
        FragmentedTypeParameterizedElementMixin<ConstructorFragment>,
        FragmentedAnnotatableElementMixin<ConstructorFragment>,
        FragmentedElementMixin<ConstructorFragment>
    implements ConstructorElement2 {
  @override
  final ConstructorElementImpl firstFragment;

  ConstructorElementImpl2(this.firstFragment) {
    ConstructorElementImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as ConstructorElementImpl?;
    }
  }

  @override
  ConstructorElement2 get baseElement => this;

  @override
  InterfaceElement2 get enclosingElement2 =>
      (firstFragment._enclosingElement3 as InterfaceFragment).element;

  @override
  bool get isConst => firstFragment.isConst;

  @override
  bool get isDefaultConstructor => firstFragment.isDefaultConstructor;

  @override
  bool get isFactory => firstFragment.isFactory;

  @override
  bool get isGenerative => firstFragment.isGenerative;

  @override
  ElementKind get kind => ElementKind.CONSTRUCTOR;

  @override
  String get name => firstFragment.name;

  @override
  ConstructorElement2? get redirectedConstructor2 =>
      (firstFragment.redirectedConstructor?.declaration
              as ConstructorElementImpl?)
          ?.element;

  @override
  ConstructorElement2? get superConstructor2 =>
      (firstFragment.superConstructor?.declaration as ConstructorElementImpl?)
          ?.element;
}

/// Common implementation for methods defined in [ConstructorElement].
mixin ConstructorElementMixin implements ConstructorElement {
  @override
  bool get isDefaultConstructor {
    // unnamed
    if (name.isNotEmpty) {
      return false;
    }
    // no required parameters
    for (ParameterElement parameter in parameters) {
      if (parameter.isRequired) {
        return false;
      }
    }
    // OK, can be used as default constructor
    return true;
  }

  @override
  bool get isGenerative {
    return !isFactory;
  }
}

/// A [TopLevelVariableElement] for a top-level 'const' variable that has an
/// initializer.
class ConstTopLevelVariableElementImpl extends TopLevelVariableElementImpl
    with ConstVariableElement {
  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  ConstTopLevelVariableElementImpl(super.name, super.offset);

  @override
  ExpressionImpl? get constantInitializer {
    linkedData?.read(this);
    return super.constantInitializer;
  }
}

/// Mixin used by elements that represent constant variables and have
/// initializers.
///
/// Note that in correct Dart code, all constant variables must have
/// initializers.  However, analyzer also needs to handle incorrect Dart code,
/// in which case there might be some constant variables that lack initializers.
/// This interface is only used for constant variables that have initializers.
///
/// This class is not intended to be part of the public API for analyzer.
mixin ConstVariableElement implements ElementImpl, ConstantEvaluationTarget {
  /// If this element represents a constant variable, and it has an initializer,
  /// a copy of the initializer for the constant.  Otherwise `null`.
  ///
  /// Note that in correct Dart code, all constant variables must have
  /// initializers.  However, analyzer also needs to handle incorrect Dart code,
  /// in which case there might be some constant variables that lack
  /// initializers.
  ExpressionImpl? constantInitializer;

  Constant? _evaluationResult;

  Constant? get evaluationResult => _evaluationResult;

  set evaluationResult(Constant? evaluationResult) {
    _evaluationResult = evaluationResult;
  }

  @override
  bool get isConstantEvaluated => _evaluationResult != null;

  /// Return a representation of the value of this variable, forcing the value
  /// to be computed if it had not previously been computed, or `null` if either
  /// this variable was not declared with the 'const' modifier or if the value
  /// of this variable could not be computed because of errors.
  DartObject? computeConstantValue() {
    if (evaluationResult == null) {
      var library = this.library;
      // TODO(scheglov): https://github.com/dart-lang/sdk/issues/47915
      if (library == null) {
        throw StateError(
          '[library: null][this: ($runtimeType) $this]'
          '[enclosingElement: $enclosingElement3]'
          '[reference: $reference]',
        );
      }
      computeConstants(
        declaredVariables: context.declaredVariables,
        constants: [this],
        featureSet: library.featureSet,
        configuration: ConstantEvaluationConfiguration(),
      );
    }

    if (evaluationResult case DartObjectImpl result) {
      return result;
    }
    return null;
  }
}

/// A [FieldFormalParameterElementImpl] for parameters that have an initializer.
class DefaultFieldFormalParameterElementImpl
    extends FieldFormalParameterElementImpl with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultFieldFormalParameterElementImpl({
    required super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  String? get defaultValueCode {
    return constantInitializer?.toSource();
  }
}

/// A [ParameterElement] for parameters that have an initializer.
class DefaultParameterElementImpl extends ParameterElementImpl
    with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultParameterElementImpl({
    required super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  String? get defaultValueCode {
    return constantInitializer?.toSource();
  }
}

class DefaultSuperFormalParameterElementImpl
    extends SuperFormalParameterElementImpl with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultSuperFormalParameterElementImpl({
    required super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  String? get defaultValueCode {
    if (isRequired) {
      return null;
    }

    var constantInitializer = this.constantInitializer;
    if (constantInitializer != null) {
      return constantInitializer.toSource();
    }

    if (_superConstructorParameterDefaultValue != null) {
      return superConstructorParameter?.defaultValueCode;
    }

    return null;
  }

  @override
  Constant? get evaluationResult {
    if (constantInitializer != null) {
      return super.evaluationResult;
    }

    var superConstructorParameter = this.superConstructorParameter?.declaration;
    if (superConstructorParameter is ParameterElementImpl) {
      return superConstructorParameter.evaluationResult;
    }

    return null;
  }

  DartObject? get _superConstructorParameterDefaultValue {
    var superDefault = superConstructorParameter?.computeConstantValue();
    if (superDefault == null) {
      return null;
    }

    var superDefaultType = superDefault.type;
    if (superDefaultType == null) {
      return null;
    }

    var typeSystem = library?.typeSystem;
    if (typeSystem == null) {
      return null;
    }

    var requiredType = type.extensionTypeErasure;
    if (typeSystem.isSubtypeOf(superDefaultType, requiredType)) {
      return superDefault;
    }

    return null;
  }

  @override
  DartObject? computeConstantValue() {
    if (constantInitializer != null) {
      return super.computeConstantValue();
    }

    return _superConstructorParameterDefaultValue;
  }
}

class DeferredImportElementPrefixImpl extends ImportElementPrefixImpl
    implements DeferredImportElementPrefix {
  DeferredImportElementPrefixImpl({
    required super.element,
  });
}

class DirectiveUriImpl implements DirectiveUri {}

class DirectiveUriWithLibraryImpl extends DirectiveUriWithSourceImpl
    implements DirectiveUriWithLibrary {
  @override
  late LibraryElementImpl library;

  DirectiveUriWithLibraryImpl({
    required super.relativeUriString,
    required super.relativeUri,
    required super.source,
    required this.library,
  });

  DirectiveUriWithLibraryImpl.read({
    required super.relativeUriString,
    required super.relativeUri,
    required super.source,
  });
}

class DirectiveUriWithRelativeUriImpl
    extends DirectiveUriWithRelativeUriStringImpl
    implements DirectiveUriWithRelativeUri {
  @override
  final Uri relativeUri;

  DirectiveUriWithRelativeUriImpl({
    required super.relativeUriString,
    required this.relativeUri,
  });
}

class DirectiveUriWithRelativeUriStringImpl extends DirectiveUriImpl
    implements DirectiveUriWithRelativeUriString {
  @override
  final String relativeUriString;

  DirectiveUriWithRelativeUriStringImpl({
    required this.relativeUriString,
  });
}

class DirectiveUriWithSourceImpl extends DirectiveUriWithRelativeUriImpl
    implements DirectiveUriWithSource {
  @override
  final Source source;

  DirectiveUriWithSourceImpl({
    required super.relativeUriString,
    required super.relativeUri,
    required this.source,
  });
}

class DirectiveUriWithUnitImpl extends DirectiveUriWithRelativeUriImpl
    implements DirectiveUriWithUnit {
  @override
  final CompilationUnitElementImpl unit;

  DirectiveUriWithUnitImpl({
    required super.relativeUriString,
    required super.relativeUri,
    required this.unit,
  });

  @override
  Source get source => unit.source;
}

/// The synthetic element representing the declaration of the type `dynamic`.
class DynamicElementImpl extends ElementImpl implements TypeDefiningElement {
  /// Return the unique instance of this class.
  static DynamicElementImpl get instance => DynamicTypeImpl.instance.element;

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  DynamicElementImpl() : super(Keyword.DYNAMIC.lexeme, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.DYNAMIC;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => null;
}

/// A concrete implementation of an [ElementAnnotation].
class ElementAnnotationImpl implements ElementAnnotation {
  /// The name of the top-level variable used to mark that a function always
  /// throws, for dead code purposes.
  static const String _alwaysThrowsVariableName = 'alwaysThrows';

  /// The name of the class used to mark an element as being deprecated.
  static const String _deprecatedClassName = 'Deprecated';

  /// The name of the top-level variable used to mark an element as being
  /// deprecated.
  static const String _deprecatedVariableName = 'deprecated';

  /// The name of the top-level variable used to mark an element as not to be
  /// stored.
  static const String _doNotStoreVariableName = 'doNotStore';

  /// The name of the top-level variable used to mark a declaration as not to be
  /// used (for ephemeral testing and debugging only).
  static const String _doNotSubmitVariableName = 'doNotSubmit';

  /// The name of the top-level variable used to mark a method as being a
  /// factory.
  static const String _factoryVariableName = 'factory';

  /// The name of the top-level variable used to mark a class and its subclasses
  /// as being immutable.
  static const String _immutableVariableName = 'immutable';

  /// The name of the top-level variable used to mark an element as being
  /// internal to its package.
  static const String _internalVariableName = 'internal';

  /// The name of the top-level variable used to mark a constructor as being
  /// literal.
  static const String _literalVariableName = 'literal';

  /// The name of the top-level variable used to mark a returned element as
  /// requiring use.
  static const String _mustBeConstVariableName = 'mustBeConst';

  /// The name of the top-level variable used to mark a type as having
  /// "optional" type arguments.
  static const String _optionalTypeArgsVariableName = 'optionalTypeArgs';

  /// The name of the top-level variable used to mark a function as running
  /// a single test.
  static const String _isTestVariableName = 'isTest';

  /// The name of the top-level variable used to mark a function as running
  /// a test group.
  static const String _isTestGroupVariableName = 'isTestGroup';

  /// The name of the class used to JS annotate an element.
  static const String _jsClassName = 'JS';

  /// The name of `_js_annotations` library, used to define JS annotations.
  static const String _jsLibName = '_js_annotations';

  /// The name of `meta` library, used to define analysis annotations.
  static const String _metaLibName = 'meta';

  /// The name of `meta_meta` library, used to define annotations for other
  /// annotations.
  static const String _metaMetaLibName = 'meta_meta';

  /// The name of the top-level variable used to mark a method as requiring
  /// subclasses to override this method.
  static const String _mustBeOverridden = 'mustBeOverridden';

  /// The name of the top-level variable used to mark a method as requiring
  /// overriders to call super.
  static const String _mustCallSuperVariableName = 'mustCallSuper';

  /// The name of `angular.meta` library, used to define angular analysis
  /// annotations.
  static const String _angularMetaLibName = 'angular.meta';

  /// The name of the top-level variable used to mark a member as being nonVirtual.
  static const String _nonVirtualVariableName = 'nonVirtual';

  /// The name of the top-level variable used to mark a method as being expected
  /// to override an inherited method.
  static const String _overrideVariableName = 'override';

  /// The name of the top-level variable used to mark a method as being
  /// protected.
  static const String _protectedVariableName = 'protected';

  /// The name of the top-level variable used to mark a member as redeclaring.
  static const String _redeclareVariableName = 'redeclare';

  /// The name of the top-level variable used to mark a class or mixin as being
  /// reopened.
  static const String _reopenVariableName = 'reopen';

  /// The name of the class used to mark a parameter as being required.
  static const String _requiredClassName = 'Required';

  /// The name of the top-level variable used to mark a parameter as being
  /// required.
  static const String _requiredVariableName = 'required';

  /// The name of the top-level variable used to mark a class as being sealed.
  static const String _sealedVariableName = 'sealed';

  /// The name of the class used to annotate a class as an annotation with a
  /// specific set of target element kinds.
  static const String _targetClassName = 'Target';

  /// The name of the class used to mark a returned element as requiring use.
  static const String _useResultClassName = 'UseResult';

  /// The name of the top-level variable used to mark a returned element as
  /// requiring use.
  static const String _useResultVariableName = 'useResult';

  /// The name of the top-level variable used to mark a member as being visible
  /// for overriding only.
  static const String _visibleForOverridingName = 'visibleForOverriding';

  /// The name of the top-level variable used to mark a method as being
  /// visible for templates.
  static const String _visibleForTemplateVariableName = 'visibleForTemplate';

  /// The name of the top-level variable used to mark a method as being
  /// visible for testing.
  static const String _visibleForTestingVariableName = 'visibleForTesting';

  /// The name of the top-level variable used to mark a method as being
  /// visible outside of template files.
  static const String _visibleOutsideTemplateVariableName =
      'visibleOutsideTemplate';

  @override
  Element? element;

  /// The compilation unit in which this annotation appears.
  CompilationUnitElementImpl compilationUnit;

  /// The AST of the annotation itself, cloned from the resolved AST for the
  /// source code.
  late AnnotationImpl annotationAst;

  /// The result of evaluating this annotation as a compile-time constant
  /// expression, or `null` if the compilation unit containing the variable has
  /// not been resolved.
  Constant? evaluationResult;

  /// Any additional errors, other than [evaluationResult] being an
  /// [InvalidConstant], that came from evaluating the constant expression,
  /// or `null` if the compilation unit containing the variable has
  /// not been resolved.
  ///
  // TODO(kallentu): Remove this field once we fix up g3's dependency on
  // annotations having a valid result as well as unresolved errors.
  List<AnalysisError>? additionalErrors;

  /// Initialize a newly created annotation. The given [compilationUnit] is the
  /// compilation unit in which the annotation appears.
  ElementAnnotationImpl(this.compilationUnit);

  @override
  List<AnalysisError> get constantEvaluationErrors {
    var evaluationResult = this.evaluationResult;
    var additionalErrors = this.additionalErrors;
    if (evaluationResult is InvalidConstant) {
      // When we have an [InvalidConstant], we don't report the additional
      // errors because this result contains the most relevant error.
      return [
        AnalysisError.tmp(
          source: source,
          offset: evaluationResult.offset,
          length: evaluationResult.length,
          errorCode: evaluationResult.errorCode,
          arguments: evaluationResult.arguments,
          contextMessages: evaluationResult.contextMessages,
        )
      ];
    }
    return additionalErrors ?? const <AnalysisError>[];
  }

  @override
  AnalysisContext get context => compilationUnit.library.context;

  @override
  Element2? get element2 {
    return element?.asElement2;
  }

  @override
  bool get isAlwaysThrows => _isPackageMetaGetter(_alwaysThrowsVariableName);

  @override
  bool get isConstantEvaluated => evaluationResult != null;

  bool get isDartInternalSince {
    var element = this.element;
    if (element is ConstructorElement) {
      return element.enclosingElement3.name == 'Since' &&
          element.library.source.uri.toString() == 'dart:_internal';
    }
    return false;
  }

  @override
  bool get isDeprecated {
    var element = this.element;
    if (element is ConstructorElement) {
      return element.library.isDartCore &&
          element.enclosingElement3.name == _deprecatedClassName;
    } else if (element is PropertyAccessorElement) {
      return element.library.isDartCore &&
          element.name == _deprecatedVariableName;
    }
    return false;
  }

  @override
  bool get isDoNotStore => _isPackageMetaGetter(_doNotStoreVariableName);

  @override
  bool get isDoNotSubmit => _isPackageMetaGetter(_doNotSubmitVariableName);

  @override
  bool get isFactory => _isPackageMetaGetter(_factoryVariableName);

  @override
  bool get isImmutable => _isPackageMetaGetter(_immutableVariableName);

  @override
  bool get isInternal => _isPackageMetaGetter(_internalVariableName);

  @override
  bool get isIsTest => _isPackageMetaGetter(_isTestVariableName);

  @override
  bool get isIsTestGroup => _isPackageMetaGetter(_isTestGroupVariableName);

  @override
  bool get isJS =>
      _isConstructor(libraryName: _jsLibName, className: _jsClassName);

  @override
  bool get isLiteral => _isPackageMetaGetter(_literalVariableName);

  @override
  bool get isMustBeConst => _isPackageMetaGetter(_mustBeConstVariableName);

  @override
  bool get isMustBeOverridden => _isPackageMetaGetter(_mustBeOverridden);

  @override
  bool get isMustCallSuper => _isPackageMetaGetter(_mustCallSuperVariableName);

  @override
  bool get isNonVirtual => _isPackageMetaGetter(_nonVirtualVariableName);

  @override
  bool get isOptionalTypeArgs =>
      _isPackageMetaGetter(_optionalTypeArgsVariableName);

  @override
  bool get isOverride => _isDartCoreGetter(_overrideVariableName);

  /// Return `true` if this is an annotation of the form
  /// `@pragma("vm:entry-point")`.
  bool get isPragmaVmEntryPoint {
    if (_isConstructor(libraryName: 'dart.core', className: 'pragma')) {
      var value = computeConstantValue();
      var nameValue = value?.getField('name');
      return nameValue?.toStringValue() == 'vm:entry-point';
    }
    return false;
  }

  @override
  bool get isProtected => _isPackageMetaGetter(_protectedVariableName);

  @override
  bool get isProxy => false;

  @override
  bool get isRedeclare => _isPackageMetaGetter(_redeclareVariableName);

  @override
  bool get isReopen => _isPackageMetaGetter(_reopenVariableName);

  @override
  bool get isRequired =>
      _isConstructor(
          libraryName: _metaLibName, className: _requiredClassName) ||
      _isPackageMetaGetter(_requiredVariableName);

  @override
  bool get isSealed => _isPackageMetaGetter(_sealedVariableName);

  @override
  bool get isTarget => _isConstructor(
      libraryName: _metaMetaLibName, className: _targetClassName);

  @override
  bool get isUseResult =>
      _isConstructor(
          libraryName: _metaLibName, className: _useResultClassName) ||
      _isPackageMetaGetter(_useResultVariableName);

  @override
  bool get isVisibleForOverriding =>
      _isPackageMetaGetter(_visibleForOverridingName);

  @override
  bool get isVisibleForTemplate => _isTopGetter(
      libraryName: _angularMetaLibName, name: _visibleForTemplateVariableName);

  @override
  bool get isVisibleForTesting =>
      _isPackageMetaGetter(_visibleForTestingVariableName);

  @override
  bool get isVisibleOutsideTemplate => _isTopGetter(
      libraryName: _angularMetaLibName,
      name: _visibleOutsideTemplateVariableName);

  @override
  LibraryElement get library => compilationUnit.library;

  /// Get the library containing this annotation.
  @override
  Source get librarySource => compilationUnit.librarySource;

  @override
  Source get source => compilationUnit.source;

  @override
  DartObject? computeConstantValue() {
    if (evaluationResult == null) {
      computeConstants(
        declaredVariables: context.declaredVariables,
        constants: [this],
        featureSet: compilationUnit.library.featureSet,
        configuration: ConstantEvaluationConfiguration(),
      );
    }

    if (evaluationResult case DartObjectImpl result) {
      return result;
    }
    return null;
  }

  @override
  String toSource() => annotationAst.toSource();

  @override
  String toString() => '@$element';

  bool _isConstructor({
    required String libraryName,
    required String className,
  }) {
    var element = this.element;
    return element is ConstructorElement &&
        element.enclosingElement3.name == className &&
        element.library.name == libraryName;
  }

  bool _isDartCoreGetter(String name) {
    return _isTopGetter(
      libraryName: 'dart.core',
      name: name,
    );
  }

  bool _isPackageMetaGetter(String name) {
    return _isTopGetter(
      libraryName: _metaLibName,
      name: name,
    );
  }

  bool _isTopGetter({
    required String libraryName,
    required String name,
  }) {
    var element = this.element;
    return element is PropertyAccessorElement &&
        element.name == name &&
        element.library.name == libraryName;
  }
}

/// A base class for concrete implementations of an [Element] or [Element2].
abstract class ElementImpl implements Element, Element2 {
  static const _metadataFlag_isReady = 1 << 0;
  static const _metadataFlag_hasDeprecated = 1 << 1;
  static const _metadataFlag_hasOverride = 1 << 2;

  /// Cached values for [sinceSdkVersion].
  ///
  /// Only very few elements have `@Since()` annotations, so instead of adding
  /// an instance field to [ElementImpl], we attach this information this way.
  /// We ask it only when [Modifier.HAS_SINCE_SDK_VERSION_VALUE] is `true`, so
  /// don't pay for a hash lookup when we know that the result is `null`.
  static final Expando<Version> _sinceSdkVersion = Expando<Version>();

  static int _NEXT_ID = 0;

  @override
  final int id = _NEXT_ID++;

  /// The enclosing element of this element, or `null` if this element is at the
  /// root of the element structure.
  ElementImpl? _enclosingElement;

  /// The enclosing element of this element, or `null` if this element is at the
  /// root of the element structure.
  ElementImpl? _enclosingElement3;

  Reference? reference;

  /// The name of this element.
  String? _name;

  /// The offset of the name of this element in the file that contains the
  /// declaration of this element.
  int _nameOffset = 0;

  /// The modifiers associated with this element.
  EnumSet<Modifier> _modifiers = EnumSet.empty();

  /// A list containing all of the metadata associated with this element.
  List<ElementAnnotationImpl> _metadata = const [];

  /// Cached flags denoting presence of specific annotations in [_metadata].
  int _metadataFlags = 0;

  /// A cached copy of the calculated hashCode for this element.
  int? _cachedHashCode;

  /// A cached copy of the calculated location for this element.
  ElementLocation? _cachedLocation;

  /// The documentation comment for this element.
  String? _docComment;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int? _codeOffset;

  /// The length of the element's code, or `null` if the element is synthetic.
  int? _codeLength;

  /// Initialize a newly created element to have the given [name] at the given
  /// [_nameOffset].
  ElementImpl(this._name, this._nameOffset, {this.reference}) {
    reference?.element = this;
  }

  @override
  Element2? get baseElement => this;

  @override
  List<Element> get children => const [];

  @override
  List<Element2> get children2 => children.cast<Element2>();

  /// The length of the element's code, or `null` if the element is synthetic.
  int? get codeLength => _codeLength;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int? get codeOffset => _codeOffset;

  @override
  AnalysisContext get context {
    return library!.context;
  }

  @override
  Element get declaration => this;

  @override
  String get displayName => _name ?? '';

  @override
  String? get documentationComment => _docComment;

  /// The documentation comment source for this element.
  set documentationComment(String? doc) {
    _docComment = doc;
  }

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element? get enclosingElement => _enclosingElement;

  /// Set the enclosing element of this element to the given [element].
  set enclosingElement(Element? element) {
    _enclosingElement = element as ElementImpl?;
  }

  @override
  Element2? get enclosingElement2 {
    var candidate = _enclosingElement3;
    if (candidate is CompilationUnitElementImpl ||
        candidate is AugmentableElement) {
      throw UnsupportedError('Cannot get an enclosingElement2 for a fragment');
    }
    return candidate as Element2?;
  }

  @override
  Element? get enclosingElement3 => _enclosingElement3;

  /// Set the enclosing element of this element to the given [element].
  set enclosingElement3(Element? element) {
    _enclosingElement3 = element as ElementImpl?;
  }

  /// Return the enclosing unit element (which might be the same as `this`), or
  /// `null` if this element is not contained in any compilation unit.
  CompilationUnitElementImpl get enclosingUnit {
    return _enclosingElement3!.enclosingUnit;
  }

  @override
  bool get hasAlwaysThrows {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isAlwaysThrows) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasDeprecated {
    return (_getMetadataFlags() & _metadataFlag_hasDeprecated) != 0;
  }

  @override
  bool get hasDoNotStore {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDoNotStore) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasDoNotSubmit {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDoNotSubmit) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasFactory {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isFactory) {
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode {
    // TODO(scheglov): We might want to re-visit this optimization in the future.
    // We cache the hash code value as this is a very frequently called method.
    return _cachedHashCode ??= location.hashCode;
  }

  @override
  bool get hasImmutable {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isImmutable) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasInternal {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isInternal) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTest {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTest) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTestGroup {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTestGroup) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasJS {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isJS) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasLiteral {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isLiteral) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustBeConst {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustBeConst) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustBeOverridden {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustBeOverridden) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustCallSuper {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustCallSuper) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasNonVirtual {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isNonVirtual) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOptionalTypeArgs {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isOptionalTypeArgs) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOverride {
    return (_getMetadataFlags() & _metadataFlag_hasOverride) != 0;
  }

  /// Return `true` if this element has an annotation of the form
  /// `@pragma("vm:entry-point")`.
  bool get hasPragmaVmEntryPoint {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isPragmaVmEntryPoint) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasProtected {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isProtected) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasRedeclare {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isRedeclare) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasReopen {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isReopen) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasRequired {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isRequired) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasSealed {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isSealed) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasUseResult {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isUseResult) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForOverriding {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForOverriding) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTemplate {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTemplate) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTesting {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTesting) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleOutsideTemplate {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleOutsideTemplate) {
        return true;
      }
    }
    return false;
  }

  /// Return an identifier that uniquely identifies this element among the
  /// children of this element's parent.
  String get identifier {
    var identifier = name!;

    if (_includeNameOffsetInIdentifier) {
      identifier += "@$nameOffset";
    }

    return considerCanonicalizeString(identifier);
  }

  bool get isNonFunctionTypeAliasesEnabled {
    return library!.featureSet.isEnabled(Feature.nonfunction_type_aliases);
  }

  @override
  bool get isPrivate {
    var name = this.name;
    if (name == null) {
      return true;
    }
    return Identifier.isPrivateName(name);
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isSynthetic {
    return hasModifier(Modifier.SYNTHETIC);
  }

  /// Set whether this element is synthetic.
  set isSynthetic(bool isSynthetic) {
    setModifier(Modifier.SYNTHETIC, isSynthetic);
  }

  @override
  LibraryElementImpl? get library => thisOrAncestorOfType();

  @override
  LibraryElement2? get library2 => thisOrAncestorOfType2();

  @override
  Source? get librarySource => library?.source;

  @override
  ElementLocation get location {
    return _cachedLocation ??= ElementLocationImpl.con1(this);
  }

  @override
  List<ElementAnnotationImpl> get metadata {
    return _metadata;
  }

  set metadata(List<ElementAnnotationImpl> metadata) {
    _metadata = metadata;
  }

  @override
  String? get name => _name;

  /// Changes the name of this element.
  set name(String? name) {
    _name = name;
  }

  @override
  int get nameLength => displayName.length;

  @override
  int get nameOffset => _nameOffset;

  /// Sets the offset of the name of this element in the file that contains the
  /// declaration of this element.
  set nameOffset(int offset) {
    _nameOffset = offset;
  }

  @override
  Element get nonSynthetic => this;

  @override
  Element2 get nonSynthetic2 => this;

  @override
  AnalysisSession? get session {
    return enclosingElement3?.session;
  }

  @override
  Version? get sinceSdkVersion {
    if (!hasModifier(Modifier.HAS_SINCE_SDK_VERSION_COMPUTED)) {
      setModifier(Modifier.HAS_SINCE_SDK_VERSION_COMPUTED, true);
      var result = SinceSdkVersionComputer().compute(this);
      if (result != null) {
        _sinceSdkVersion[this] = result;
        setModifier(Modifier.HAS_SINCE_SDK_VERSION_VALUE, true);
      }
    }
    if (hasModifier(Modifier.HAS_SINCE_SDK_VERSION_VALUE)) {
      return _sinceSdkVersion[this];
    }
    return null;
  }

  @override
  Source? get source {
    return enclosingElement3?.source;
  }

  /// Whether to include the [nameOffset] in [identifier] to disambiguiate
  /// elements that might otherwise have the same identifier.
  bool get _includeNameOffsetInIdentifier {
    var element = this;
    if (element is AugmentableElement) {
      return element.isAugmentation;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ElementImpl &&
        other.kind == kind &&
        other.location == location;
  }

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeAbstractElement(this);
  }

  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    var builder = ElementDisplayStringBuilder(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
    appendTo(builder);
    return builder.toString();
  }

  /// Set this element as the enclosing element for given [element].
  void encloseElement(ElementImpl element) {
    element.enclosingElement3 = this;
    element.enclosingElement = this;
  }

  /// Set this element as the enclosing element for given [elements].
  void encloseElements(List<Element> elements) {
    for (Element element in elements) {
      element as ElementImpl;
      element._enclosingElement3 = this;
      element._enclosingElement = this;
    }
  }

  @override
  String getDisplayString({
    @Deprecated('Only non-nullable by default mode is supported')
    bool withNullability = true,
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    var builder = ElementDisplayStringBuilder(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
    appendTo(builder);
    return builder.toString();
  }

  @override
  String getExtendedDisplayName(String? shortName) {
    shortName ??= displayName;
    var source = this.source;
    return "$shortName (${source?.fullName})";
  }

  /// Return `true` if this element has the given [modifier] associated with it.
  bool hasModifier(Modifier modifier) => _modifiers[modifier];

  @override
  bool isAccessibleIn(LibraryElement library) {
    if (Identifier.isPrivateName(name!)) {
      return library == this.library;
    }
    return true;
  }

  @override
  bool isAccessibleIn2(LibraryElement2 library) {
    if (Identifier.isPrivateName(name!)) {
      return library == library2;
    }
    return true;
  }

  void resetMetadataFlags() {
    _metadataFlags = 0;
  }

  /// Set the code range for this element.
  void setCodeRange(int offset, int length) {
    _codeOffset = offset;
    _codeLength = length;
  }

  /// Set whether the given [modifier] is associated with this element to
  /// correspond to the given [value].
  void setModifier(Modifier modifier, bool value) {
    _modifiers = _modifiers.updated(modifier, value);
  }

  @override
  E? thisOrAncestorMatching<E extends Element>(
    bool Function(Element) predicate,
  ) {
    Element? element = this;
    while (element != null && !predicate(element)) {
      element = element.enclosingElement3;
    }
    return element as E?;
  }

  @override
  E? thisOrAncestorMatching2<E extends Element2>(
    bool Function(Element2) predicate,
  ) {
    Element2? element = this;
    while (element != null && !predicate(element)) {
      element = element.enclosingElement2;
    }
    return element as E?;
  }

  @override
  E? thisOrAncestorMatching3<E extends Element>(
    bool Function(Element) predicate,
  ) {
    Element? element = this;
    while (element != null && !predicate(element)) {
      element = (element as ElementImpl).enclosingElement3;
    }
    return element as E?;
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    if (E == LibraryElement || E == LibraryElementImpl) {
      if (enclosingElement3 case LibraryElementImpl library) {
        return library as E;
      }
      return thisOrAncestorOfType<CompilationUnitElementImpl>()?.library as E?;
    }

    Element element = this;
    while (element is! E) {
      var ancestor = element.enclosingElement3;
      if (ancestor == null) return null;
      element = ancestor;
    }
    return element;
  }

  @override
  E? thisOrAncestorOfType2<E extends Element2>() {
    if (E == LibraryElement2 || E == LibraryElementImpl) {
      if (enclosingElement3 case LibraryElementImpl library) {
        return library as E;
      }
      return thisOrAncestorOfType<CompilationUnitElementImpl>()?.library as E?;
    }

    Element2 element = this;
    while (element is! E) {
      var ancestor = element.enclosingElement2;
      if (ancestor == null) return null;
      element = ancestor;
    }
    return element;
  }

  @override
  E? thisOrAncestorOfType3<E extends Element>() {
    Element element = this;
    while (element is! E) {
      var ancestor = element.enclosingElement3;
      if (ancestor == null) return null;
      element = ancestor;
    }
    return element;
  }

  @override
  String toString() {
    return getDisplayString();
  }

  /// Use the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child in children) {
      child.accept(visitor);
    }
  }

  /// Return flags that denote presence of a few specific annotations.
  int _getMetadataFlags() {
    var result = _metadataFlags;

    // Has at least `_metadataFlag_isReady`.
    if (result != 0) {
      return result;
    }

    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDeprecated) {
        result |= _metadataFlag_hasDeprecated;
      } else if (annotation.isOverride) {
        result |= _metadataFlag_hasOverride;
      }
    }

    result |= _metadataFlag_isReady;
    return _metadataFlags = result;
  }
}

abstract class ElementImpl2 implements Element2 {
  ElementLocation? _cachedLocation;

  @override
  final int id = ElementImpl._NEXT_ID++;

  @override
  Element2? get baseElement => this;

  @override
  List<Element2> get children2 => const [];

  @override
  String get displayName => name ?? '';

  @override
  // TODO(augmentations): implement enclosingElement2
  Element2? get enclosingElement2 => throw UnimplementedError();

  /// Return an identifier that uniquely identifies this element among the
  /// children of this element's parent.
  String get identifier {
    var identifier = name!;
    // TODO(augmentations): Figure out how to get a unique identifier. In the
    //  old model we sometimes used the offset of the name to disambiguate
    //  between elements, but we can't do that anymore because the name can
    //  appear at multiple offsets.
    return considerCanonicalizeString(identifier);
  }

  @override
  bool get isPrivate {
    var name = this.name;
    if (name == null) {
      return true;
    }
    return Identifier.isPrivateName(name);
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  ElementLocation? get location {
    return _cachedLocation ??= ElementLocationImpl.fromElement(this);
  }

  @override
  Element2 get nonSynthetic2 => this;

  @override
  AnalysisSession? get session {
    return enclosingElement2?.session;
  }

  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  });

  @override
  bool isAccessibleIn2(LibraryElement2 library) {
    var name = this.name;
    if (name == null || Identifier.isPrivateName(name)) {
      return library == library2;
    }
    return true;
  }

  @override
  E? thisOrAncestorMatching2<E extends Element2>(
      bool Function(Element2 p1) predicate) {
    Element2? element = this;
    while (element != null && !predicate(element)) {
      element = element.enclosingElement2;
    }
    return element as E?;
  }

  @override
  E? thisOrAncestorOfType2<E extends Element2>() {
    Element2 element = this;
    while (element is! E) {
      var ancestor = element.enclosingElement2;
      if (ancestor == null) return null;
      element = ancestor;
    }
    return element;
  }

  @override
  String toString() {
    return displayString2();
  }
}

/// A concrete implementation of an [ElementLocation].
class ElementLocationImpl implements ElementLocation {
  /// The character used to separate components in the encoded form.
  static const int _separatorChar = 0x3B;

  /// The path to the element whose location is represented by this object.
  late final List<String> _components;

  /// Initialize a newly created location to represent the given [element].
  ElementLocationImpl.con1(Element element) {
    List<String> components = <String>[];
    Element? ancestor = element;
    while (ancestor != null) {
      components.insert(0, (ancestor as ElementImpl).identifier);
      if (ancestor is CompilationUnitElementImpl) {
        components.insert(0, ancestor.library.identifier);
        break;
      }
      ancestor = ancestor.enclosingElement3;
    }
    _components = components.toFixedList();
  }

  /// Initialize a newly created location from the given [encoding].
  ElementLocationImpl.con2(String encoding) {
    _components = _decode(encoding);
  }

  /// Initialize a newly created location from the given [components].
  ElementLocationImpl.con3(List<String> components) {
    _components = components;
  }

  /// Initialize a newly created location to represent the given [element].
  ElementLocationImpl.fromElement(Element2 element) {
    List<String> components = <String>[];
    Element2? ancestor = element;
    while (ancestor != null) {
      components.insert(0, (ancestor as ElementImpl2).identifier);
      ancestor = ancestor.enclosingElement2;
    }
    _components = components.toFixedList();
  }

  @override
  List<String> get components => _components;

  @override
  String get encoding {
    StringBuffer buffer = StringBuffer();
    int length = _components.length;
    for (int i = 0; i < length; i++) {
      if (i > 0) {
        buffer.writeCharCode(_separatorChar);
      }
      _encode(buffer, _components[i]);
    }
    return buffer.toString();
  }

  @override
  int get hashCode => Object.hashAll(_components);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is ElementLocationImpl) {
      List<String> otherComponents = other._components;
      int length = _components.length;
      if (otherComponents.length != length) {
        return false;
      }
      for (int i = 0; i < length; i++) {
        if (_components[i] != otherComponents[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() => encoding;

  /// Decode the [encoding] of a location into a list of components and return
  /// the components.
  List<String> _decode(String encoding) {
    List<String> components = <String>[];
    StringBuffer buffer = StringBuffer();
    int index = 0;
    int length = encoding.length;
    while (index < length) {
      int currentChar = encoding.codeUnitAt(index);
      if (currentChar == _separatorChar) {
        if (index + 1 < length &&
            encoding.codeUnitAt(index + 1) == _separatorChar) {
          buffer.writeCharCode(_separatorChar);
          index += 2;
        } else {
          components.add(buffer.toString());
          buffer = StringBuffer();
          index++;
        }
      } else {
        buffer.writeCharCode(currentChar);
        index++;
      }
    }
    components.add(buffer.toString());
    return components;
  }

  /// Append an encoded form of the given [component] to the given [buffer].
  void _encode(StringBuffer buffer, String component) {
    int length = component.length;
    for (int i = 0; i < length; i++) {
      int currentChar = component.codeUnitAt(i);
      if (currentChar == _separatorChar) {
        buffer.writeCharCode(_separatorChar);
      }
      buffer.writeCharCode(currentChar);
    }
  }
}

/// An [InterfaceElementImpl] which is an enum.
class EnumElementImpl extends InterfaceElementImpl
    with AugmentableElement<EnumElementImpl>
    implements EnumElement, EnumFragment {
  late MaybeAugmentedEnumElementMixin augmentedInternal =
      NotAugmentedEnumElementImpl(this);

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  EnumElementImpl(super.name, super.offset);

  @override
  MaybeAugmentedEnumElementMixin get augmented {
    if (isAugmentation) {
      if (augmentationTarget case var augmentationTarget?) {
        return augmentationTarget.augmented;
      }
    }

    linkedData?.read(this);
    return augmentedInternal;
  }

  AugmentedEnumElementImpl? get augmentedIfReally {
    if (augmentationTarget != null) {
      if (augmented case AugmentedEnumElementImpl augmented) {
        return augmented;
      }
    }
    return null;
  }

  List<FieldElementImpl> get constants {
    return fields.where((field) => field.isEnumConstant).toList();
  }

  @override
  List<FieldElement2> get constants2 => constants.cast<FieldElement2>();

  @override
  EnumElement2 get element => super.element as EnumElement2;

  @override
  ElementKind get kind => ElementKind.ENUM;

  ConstFieldElementImpl? get valuesField {
    for (var field in fields) {
      if (field is ConstFieldElementImpl &&
          field.name == 'values' &&
          field.isSyntheticEnumField) {
        return field;
      }
    }
    return null;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitEnumElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeEnumElement(this);
  }
}

/// A base class for concrete implementations of an [ExecutableElement].
abstract class ExecutableElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin, MacroTargetElement
    implements ExecutableElement, ExecutableFragment {
  /// A list containing all of the parameters defined by this executable
  /// element.
  List<ParameterElement> _parameters = const [];

  /// The inferred return type of this executable element.
  DartType? _returnType;

  /// The type of function defined by this executable element.
  FunctionType? _type;

  @override
  ElementLinkedData? linkedData;

  /// Initialize a newly created executable element to have the given [name] and
  /// [offset].
  ExecutableElementImpl(String super.name, super.offset, {super.reference});

  @override
  List<Element> get children => [
        ...super.children,
        ...typeParameters,
        ...parameters,
      ];

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element get enclosingElement => super.enclosingElement!;

  @override
  Element get enclosingElement3 {
    return super.enclosingElement3!;
  }

  @override
  List<FormalParameterFragment> get formalParameters =>
      parameters.cast<FormalParameterFragment>();

  @override
  bool get hasImplicitReturnType {
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

  /// Set whether this executable element has an implicit return type.
  set hasImplicitReturnType(bool hasImplicitReturnType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitReturnType);
  }

  bool get invokesSuperSelf {
    return hasModifier(Modifier.INVOKES_SUPER_SELF);
  }

  set invokesSuperSelf(bool value) {
    setModifier(Modifier.INVOKES_SUPER_SELF, value);
  }

  @override
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isAsynchronous {
    return hasModifier(Modifier.ASYNCHRONOUS);
  }

  /// Set whether this executable element's body is asynchronous.
  set isAsynchronous(bool isAsynchronous) {
    setModifier(Modifier.ASYNCHRONOUS, isAsynchronous);
  }

  @override
  bool get isAugmentation => hasModifier(Modifier.AUGMENTATION);

  @override
  bool get isExtensionTypeMember {
    return hasModifier(Modifier.EXTENSION_TYPE_MEMBER);
  }

  set isExtensionTypeMember(bool value) {
    setModifier(Modifier.EXTENSION_TYPE_MEMBER, value);
  }

  @override
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  /// Set whether this executable element is external.
  set isExternal(bool isExternal) {
    setModifier(Modifier.EXTERNAL, isExternal);
  }

  @override
  bool get isGenerator {
    return hasModifier(Modifier.GENERATOR);
  }

  /// Set whether this method's body is a generator.
  set isGenerator(bool isGenerator) {
    setModifier(Modifier.GENERATOR, isGenerator);
  }

  @override
  bool get isOperator => false;

  @override
  bool get isStatic {
    return hasModifier(Modifier.STATIC);
  }

  set isStatic(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  bool get isSynchronous => !isAsynchronous;

  @override
  List<ElementAnnotationImpl> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name {
    return super.name!;
  }

  @override
  List<ParameterElement> get parameters {
    linkedData?.read(this);
    return _parameters;
  }

  /// Set the parameters defined by this executable element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement3 = this;
      parameter.enclosingElement = this;
    }
    _parameters = parameters;
  }

  List<ParameterElement> get parameters_unresolved {
    return _parameters;
  }

  @override
  DartType get returnType {
    linkedData?.read(this);
    return _returnType!;
  }

  set returnType(DartType returnType) {
    _returnType = returnType;
    // We do this because of return type inference. At the moment when we
    // create a local function element we don't know yet its return type,
    // because we have not done static type analysis yet.
    // It somewhere it between we access the type of this element, so it gets
    // cached in the element. When we are done static type analysis, we then
    // should clear this cached type to make it right.
    // TODO(scheglov): Remove when type analysis is done in the single pass.
    _type = null;
  }

  @override
  FunctionType get type {
    if (_type != null) return _type!;

    return _type = FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  set type(FunctionType type) {
    _type = type;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

abstract class ExecutableElementImpl2 extends FunctionTypedElementImpl2
    implements ExecutableElement2 {
  @override
  ExecutableElement2 get baseElement => this;
}

/// A concrete implementation of an [ExtensionElement].
class ExtensionElementImpl extends InstanceElementImpl
    with AugmentableElement<ExtensionElementImpl>
    implements ExtensionElement, ExtensionFragment {
  late MaybeAugmentedExtensionElementMixin augmentedInternal =
      NotAugmentedExtensionElementImpl(this);

  /// Initialize a newly created extension element to have the given [name] at
  /// the given [offset] in the file that contains the declaration of this
  /// element.
  ExtensionElementImpl(super.name, super.nameOffset);

  @override
  MaybeAugmentedExtensionElementMixin get augmented {
    if (isAugmentation) {
      if (augmentationTarget case var augmentationTarget?) {
        return augmentationTarget.augmented;
      }
    }

    linkedData?.read(this);
    return augmentedInternal;
  }

  AugmentedExtensionElementImpl? get augmentedIfReally {
    if (augmentationTarget != null) {
      if (augmented case AugmentedExtensionElementImpl augmented) {
        return augmented;
      }
    }
    return null;
  }

  @override
  List<Element> get children => [
        ...super.children,
        ...accessors,
        ...fields,
        ...methods,
        ...typeParameters,
      ];

  @override
  String get displayName => name ?? '';

  @override
  ExtensionElement2 get element => super.element as ExtensionElement2;

  @override
  DartType get extendedType {
    return augmented.extendedType;
  }

  @override
  String get identifier {
    if (reference != null) {
      return reference!.name;
    }
    return super.identifier;
  }

  @override
  bool get isSimplyBounded => true;

  @override
  ElementKind get kind => ElementKind.EXTENSION;

  @override
  List<ElementAnnotationImpl> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  DartType get thisType => extendedType;

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitExtensionElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExtensionElement(this);
  }

  @override
  FieldElement? getField(String name) {
    for (FieldElement fieldElement in fields) {
      if (name == fieldElement.name) {
        return fieldElement;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getGetter(String getterName) {
    for (var accessor in augmented.accessors) {
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement? getMethod(String methodName) {
    for (var method in augmented.methods) {
      if (method.name == methodName) {
        return method;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getSetter(String setterName) {
    return InterfaceElementImpl.getSetterFromAccessors(
      setterName,
      augmented.accessors,
    );
  }
}

class ExtensionTypeElementImpl extends InterfaceElementImpl
    with AugmentableElement<ExtensionTypeElementImpl>
    implements ExtensionTypeElement, ExtensionTypeFragment {
  late MaybeAugmentedExtensionTypeElementMixin augmentedInternal =
      NotAugmentedExtensionTypeElementImpl(this);

  /// Whether the element has direct or indirect reference to itself,
  /// in representation.
  bool hasRepresentationSelfReference = false;

  /// Whether the element has direct or indirect reference to itself,
  /// in implemented superinterfaces.
  bool hasImplementsSelfReference = false;

  ExtensionTypeElementImpl(super.name, super.nameOffset);

  @override
  MaybeAugmentedExtensionTypeElementMixin get augmented {
    if (isAugmentation) {
      if (augmentationTarget case var augmentationTarget?) {
        return augmentationTarget.augmented;
      }
    }

    linkedData?.read(this);
    return augmentedInternal;
  }

  AugmentedExtensionTypeElementImpl? get augmentedIfReally {
    if (augmentationTarget != null) {
      if (augmented case AugmentedExtensionTypeElementImpl augmented) {
        return augmented;
      }
    }
    return null;
  }

  @override
  ExtensionTypeElement2 get element => super.element as ExtensionTypeElement2;

  @override
  ElementKind get kind {
    return ElementKind.EXTENSION_TYPE;
  }

  @override
  ConstructorElementImpl get primaryConstructor {
    return augmented.primaryConstructor;
  }

  @override
  ConstructorFragment get primaryConstructor2 =>
      primaryConstructor as ConstructorFragment;

  @override
  FieldElementImpl get representation {
    return augmented.representation;
  }

  @override
  FieldFragment get representation2 => representation as FieldFragment;

  @override
  DartType get typeErasure {
    return augmented.typeErasure;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitExtensionTypeElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExtensionTypeElement(this);
  }
}

/// A concrete implementation of a [FieldElement].
class FieldElementImpl extends PropertyInducingElementImpl
    with AugmentableElement<FieldElementImpl>
    implements FieldElement, FieldFragment {
  /// True if this field inherits from a covariant parameter. This happens
  /// when it overrides a field in a supertype that is covariant.
  bool inheritsCovariant = false;

  /// The element corresponding to this fragment.
  FieldElement2? _element;

  /// Initialize a newly created synthetic field element to have the given
  /// [name] at the given [offset].
  FieldElementImpl(super.name, super.offset);

  @override
  FieldElement get declaration => this;

  @override
  FieldElement2 get element {
    if (_element != null) {
      return _element!;
    }
    FieldFragment firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return FieldElementImpl2(firstFragment as FieldElementImpl);
  }

  set element(FieldElement2 element) => _element = element;

  @override
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isCovariant {
    return hasModifier(Modifier.COVARIANT);
  }

  /// Set whether this field is explicitly marked as being covariant.
  set isCovariant(bool isCovariant) {
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isEnumConstant {
    return hasModifier(Modifier.ENUM_CONSTANT);
  }

  set isEnumConstant(bool isEnumConstant) {
    setModifier(Modifier.ENUM_CONSTANT, isEnumConstant);
  }

  @override
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  @override
  bool get isPromotable {
    return hasModifier(Modifier.PROMOTABLE);
  }

  set isPromotable(bool value) {
    setModifier(Modifier.PROMOTABLE, value);
  }

  /// Return `true` if this element is a synthetic enum field.
  ///
  /// It is synthetic because it is not written explicitly in code, but it
  /// is different from other synthetic fields, because its getter is also
  /// synthetic.
  ///
  /// Such fields are `index`, `_name`, and `values`.
  bool get isSyntheticEnumField {
    return enclosingElement3 is EnumElementImpl &&
        isSynthetic &&
        getter?.isSynthetic == true &&
        setter == null;
  }

  @override
  ElementKind get kind => ElementKind.FIELD;

  @override
  List<ElementAnnotationImpl> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  FieldFragment? get nextFragment => super.nextFragment as FieldFragment?;

  @override
  FieldFragment? get previousFragment =>
      super.previousFragment as FieldFragment?;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);
}

class FieldElementImpl2 extends PropertyInducingElementImpl2
    with
        FragmentedAnnotatableElementMixin<FieldFragment>,
        FragmentedElementMixin<FieldFragment>
    implements FieldElement2 {
  @override
  final FieldElementImpl firstFragment;

  FieldElementImpl2(this.firstFragment) {
    FieldElementImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as FieldElementImpl?;
    }
  }

  @override
  FieldElement2 get baseElement => this;

  @override
  Element2? get enclosingElement2 =>
      (firstFragment._enclosingElement3 as InstanceFragment).element;

  @override
  GetterElement? get getter2 => firstFragment.getter?.element as GetterElement?;

  @override
  bool get hasImplicitType => firstFragment.hasImplicitType;

  @override
  bool get isAbstract => firstFragment.isAbstract;

  @override
  bool get isConst => firstFragment.isConst;

  @override
  bool get isCovariant => firstFragment.isCovariant;

  @override
  bool get isEnumConstant => firstFragment.isEnumConstant;

  @override
  bool get isExternal => firstFragment.isExternal;

  @override
  bool get isFinal => firstFragment.isFinal;

  @override
  bool get isLate => firstFragment.isLate;

  @override
  bool get isPromotable => firstFragment.isPromotable;

  @override
  bool get isStatic => firstFragment.isStatic;

  @override
  ElementKind get kind => ElementKind.FIELD;

  @override
  String get name => firstFragment.name;

  @override
  SetterElement? get setter2 => firstFragment.setter?.element as SetterElement?;

  @override
  DartType get type => firstFragment.type;

  @override
  DartObject? computeConstantValue() => firstFragment.computeConstantValue();
}

/// A [ParameterElementImpl] that has the additional information of the
/// [FieldElement] associated with the parameter.
class FieldFormalParameterElementImpl extends ParameterElementImpl
    implements FieldFormalParameterElement, FieldFormalParameterFragment {
  @override
  FieldElement? field;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  FieldFormalParameterElementImpl({
    required String super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  FieldFormalParameterElement2 get element =>
      super.element as FieldFormalParameterElement2;

  /// Initializing formals are visible only in the "formal parameter
  /// initializer scope", which is the current scope of the initializer list
  /// of the constructor, and which is enclosed in the scope where the
  /// constructor is declared. And according to the specification, they
  /// introduce final local variables, always, regardless whether the field
  /// is final.
  @override
  bool get isFinal => true;

  @override
  bool get isInitializingFormal => true;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);

  @override
  FormalParameterElement _createElement(
          FormalParameterFragment firstFragment) =>
      FieldFormalParameterElementImpl2(firstFragment as ParameterElementImpl);
}

class FieldFormalParameterElementImpl2 extends FormalParameterElementImpl
    implements FieldFormalParameterElement2 {
  FieldFormalParameterElementImpl2(super.firstFragment);

  @override
  FieldElement2? get field2 =>
      ((firstFragment as FieldFormalParameterElementImpl).field
              as FieldFragment)
          .element;

  @override
  String get name => firstFragment.name;
}

class FormalParameterElementImpl extends PromotableElementImpl2
    with
        FragmentedAnnotatableElementMixin<FormalParameterFragment>,
        FragmentedElementMixin<FormalParameterFragment>
    implements FormalParameterElement {
  @override
  final ParameterElementImpl firstFragment;

  FormalParameterElementImpl(this.firstFragment) {
    ParameterElementImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as ParameterElementImpl?;
    }
  }

  @override
  FormalParameterElement get baseElement => this;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  String? get defaultValueCode => firstFragment.defaultValueCode;

  @override
  Element2? get enclosingElement2 =>
      (firstFragment._enclosingElement3 as Fragment).element;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  List<FormalParameterElement> get formalParameters => firstFragment.parameters
      .map((fragment) => (fragment as ParameterElementImpl).element)
      .toList();

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get hasDefaultValue => firstFragment.hasDefaultValue;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get hasImplicitType => firstFragment.hasImplicitType;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isConst => firstFragment.isConst;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isCovariant => firstFragment.isCovariant;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isFinal => firstFragment.isFinal;

  @override
  bool get isInitializingFormal => firstFragment.isInitializingFormal;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isLate => firstFragment.isLate;

  @override
  bool get isNamed => firstFragment.isNamed;

  @override
  bool get isOptional => firstFragment.isOptional;

  @override
  bool get isOptionalNamed => firstFragment.isOptionalNamed;

  @override
  bool get isOptionalPositional => firstFragment.isOptionalPositional;

  @override
  bool get isPositional => firstFragment.isPositional;

  @override
  bool get isRequired => firstFragment.isRequired;

  @override
  bool get isRequiredNamed => firstFragment.isRequiredNamed;

  @override
  bool get isRequiredPositional => firstFragment.isRequiredPositional;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isStatic => firstFragment.isStatic;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isSuperFormal => firstFragment.isSuperFormal;

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  LibraryElement2 get library2 =>
      firstFragment.thisOrAncestorOfType<LibraryElementImpl>()
          as LibraryElement2;

  @override
  String get name => firstFragment.name;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  DartType get type => firstFragment.type;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  List<TypeParameterElement2> get typeParameters2 => const [];

  @override
  void appendToWithoutDelimiters2(StringBuffer buffer) {
    // TODO(augmentations): Implement the merge of formal parameters.
    firstFragment.appendToWithoutDelimiters(buffer);
  }

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  DartObject? computeConstantValue() => firstFragment.computeConstantValue();
  // firstFragment.typeParameters
  //     .map((fragment) => (fragment as TypeParameterElementImpl).element)
  //     .toList();
}

mixin FragmentedAnnotatableElementMixin<E extends Fragment>
    implements FragmentedElementMixin<E> {
  String? get documentationComment {
    var buffer = StringBuffer();
    for (var fragment in _fragments) {
      var comment = fragment.documentationCommentOrNull;
      if (comment != null) {
        if (buffer.isNotEmpty) {
          buffer.writeln();
          buffer.writeln();
        }
        buffer.write(comment);
      }
    }
    if (buffer.isEmpty) {
      return null;
    }
    return buffer.toString();
  }

  bool get hasAlwaysThrows {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isAlwaysThrows) {
        return true;
      }
    }
    return false;
  }

  bool get hasDeprecated {
    // TODO(augmentations): Consider optimizing this similar `ElementImpl`.
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDeprecated) {
        return true;
      }
    }
    return false;
  }

  bool get hasDoNotStore {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDoNotStore) {
        return true;
      }
    }
    return false;
  }

  bool get hasDoNotSubmit {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDoNotSubmit) {
        return true;
      }
    }
    return false;
  }

  bool get hasFactory {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isFactory) {
        return true;
      }
    }
    return false;
  }

  bool get hasImmutable {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isImmutable) {
        return true;
      }
    }
    return false;
  }

  bool get hasInternal {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isInternal) {
        return true;
      }
    }
    return false;
  }

  bool get hasIsTest {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTest) {
        return true;
      }
    }
    return false;
  }

  bool get hasIsTestGroup {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTestGroup) {
        return true;
      }
    }
    return false;
  }

  bool get hasJS {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isJS) {
        return true;
      }
    }
    return false;
  }

  bool get hasLiteral {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isLiteral) {
        return true;
      }
    }
    return false;
  }

  bool get hasMustBeConst {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustBeConst) {
        return true;
      }
    }
    return false;
  }

  bool get hasMustBeOverridden {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustBeOverridden) {
        return true;
      }
    }
    return false;
  }

  bool get hasMustCallSuper {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustCallSuper) {
        return true;
      }
    }
    return false;
  }

  bool get hasNonVirtual {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isNonVirtual) {
        return true;
      }
    }
    return false;
  }

  bool get hasOptionalTypeArgs {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isOptionalTypeArgs) {
        return true;
      }
    }
    return false;
  }

  bool get hasOverride {
    // TODO(augmentations): Consider optimizing this similar `ElementImpl`.
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isOverride) {
        return true;
      }
    }
    return false;
  }

  bool get hasProtected {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isProtected) {
        return true;
      }
    }
    return false;
  }

  bool get hasRedeclare {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isRedeclare) {
        return true;
      }
    }
    return false;
  }

  bool get hasReopen {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isReopen) {
        return true;
      }
    }
    return false;
  }

  bool get hasRequired {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isRequired) {
        return true;
      }
    }
    return false;
  }

  bool get hasSealed {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isSealed) {
        return true;
      }
    }
    return false;
  }

  bool get hasUseResult {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isUseResult) {
        return true;
      }
    }
    return false;
  }

  bool get hasVisibleForOverriding {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForOverriding) {
        return true;
      }
    }
    return false;
  }

  bool get hasVisibleForTemplate {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTemplate) {
        return true;
      }
    }
    return false;
  }

  bool get hasVisibleForTesting {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTesting) {
        return true;
      }
    }
    return false;
  }

  bool get hasVisibleOutsideTemplate {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleOutsideTemplate) {
        return true;
      }
    }
    return false;
  }

  List<ElementAnnotation> get metadata {
    var result = <ElementAnnotation>[];
    for (var fragment in _fragments) {
      result.addAll(fragment.metadataOrEmpty);
    }
    return result;
  }

  Version? get sinceSdkVersion {
    var annotations = metadata.cast<ElementAnnotationImpl>();
    return SinceSdkVersionComputer.fromAnnotations(annotations);
  }
}

mixin FragmentedElementMixin<E extends Fragment> implements _Fragmented<E> {
  bool get isSynthetic {
    if (firstFragment is ElementImpl) {
      return (firstFragment as ElementImpl).isSynthetic;
    }
    // We should never get to this point.
    assert(false, 'Fragment does not implement ElementImpl');
    return false;
  }

  LibraryElement2? get library2 {
    if (firstFragment is ElementImpl) {
      return (firstFragment as ElementImpl).library2;
    }
    // We should never get to this point.
    assert(false, 'Fragment does not implement ElementImpl');
    return null;
  }

  /// A list of all of the fragments from which this element is composed.
  List<E> get _fragments {
    var result = <E>[];
    E? current = firstFragment;
    while (current != null) {
      result.add(current);
      current = current.nextFragment as E?;
    }
    return result;
  }

  String displayString2(
      {bool multiline = false, bool preferTypeAlias = false}) {
    var builder = ElementDisplayStringBuilder(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
    var fragment = firstFragment;
    if (fragment is! ElementImpl) {
      throw UnsupportedError('Fragment is not an ElementImpl');
    }
    (fragment as ElementImpl).appendTo(builder);
    return builder.toString();
  }
}

mixin FragmentedExecutableElementMixin<E extends ExecutableFragment>
    implements FragmentedElementMixin<E> {
  List<FormalParameterElement> get formalParameters {
    return firstFragment!.formalParameters
        .map((fragment) => fragment.element)
        .toList();
  }

  bool get hasImplicitReturnType {
    for (var fragment in _fragments) {
      if (!(fragment as ExecutableElementImpl).hasImplicitReturnType) {
        return false;
      }
    }
    return true;
  }

  bool get isAbstract {
    for (var fragment in _fragments) {
      if (!(fragment as ExecutableElementImpl).isAbstract) {
        return false;
      }
    }
    return true;
  }

  bool get isExtensionTypeMember =>
      (firstFragment as ExecutableElementImpl).isExtensionTypeMember;

  bool get isExternal {
    for (var fragment in _fragments) {
      if ((fragment as ExecutableElementImpl).isExternal) {
        return true;
      }
    }
    return false;
  }

  bool get isStatic => (firstFragment as ExecutableElementImpl).isStatic;
}

mixin FragmentedFunctionTypedElementMixin<E extends ExecutableFragment>
    implements FragmentedElementMixin<E> {
  // TODO(augmentations): This might be wrong. The parameters need to be a
  //  merge of the parameters of all of the fragments, but this probably doesn't
  //  account for missing data (such as the parameter types).
  List<FormalParameterElement> get formalParameters {
    var fragment = firstFragment;
    return switch (fragment) {
      FunctionTypedElementImpl(:var parameters) => parameters
          .map((fragment) => (fragment as FormalParameterFragment).element)
          .toList(),
      ExecutableElementImpl(:var parameters) => parameters
          .map((fragment) => (fragment as FormalParameterFragment).element)
          .toList(),
      _ => throw UnsupportedError(
          'Cannot get formal parameters for ${fragment.runtimeType}'),
    };
  }

  DartType get returnType => type.returnType;

  // TODO(augmentations): This is wrong. The function type needs to be a merge
  //  of the function types of all of the fragments, but I don't know how to
  //  perform that merge.
  FunctionType get type {
    if (firstFragment is ExecutableElementImpl) {
      return (firstFragment as ExecutableElementImpl).type;
    } else if (firstFragment is FunctionTypedElementImpl) {
      return (firstFragment as FunctionTypedElementImpl).type;
    }
    throw UnimplementedError();
  }
}

mixin FragmentedTypeParameterizedElementMixin<
    E extends TypeParameterizedFragment> implements FragmentedElementMixin<E> {
  bool get isSimplyBounded {
    var fragment = firstFragment;
    if (fragment is TypeParameterizedElementMixin) {
      return fragment.isSimplyBounded;
    }
    return true;
  }

  List<TypeParameterElement2> get typeParameters2 {
    var fragment = firstFragment;
    if (fragment is TypeParameterizedElementMixin) {
      return fragment.typeParameters
          .map((fragment) => (fragment as TypeParameterFragment).element)
          .toList();
    }
    return const [];
  }
}

/// A concrete implementation of a [FunctionElement].
class FunctionElementImpl extends ExecutableElementImpl
    with AugmentableElement<FunctionElementImpl>
    implements
        FunctionElement,
        FunctionTypedElementImpl,
        TopLevelFunctionFragment {
  late final LocalFunctionElementImpl element2 = LocalFunctionElementImpl(this);

  /// The element corresponding to this fragment.
  TopLevelFunctionElement? _element;

  /// Initialize a newly created function element to have the given [name] and
  /// [offset].
  FunctionElementImpl(super.name, super.offset);

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  FunctionElementImpl.forOffset(int nameOffset) : super("", nameOffset);

  @override
  ExecutableElement get declaration => this;

  @override
  TopLevelFunctionElement get element {
    if (_element != null) {
      return _element!;
    }
    TopLevelFunctionFragment firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return TopLevelFunctionElementImpl(firstFragment as FunctionElementImpl);
  }

  set element(TopLevelFunctionElement element) => _element = element;

  @override
  Fragment? get enclosingFragment {
    if (enclosingElement3 is CompilationUnitElement) {
      // TODO(augmentations): Support the fragment chain.
      return enclosingElement3 as LibraryFragment;
    } else {
      // Local functions cannot be augmented.
      throw UnsupportedError('This is not a fragment');
    }
  }

  @override
  bool get isDartCoreIdentical {
    return isStatic && name == 'identical' && library.isDartCore;
  }

  @override
  bool get isEntryPoint {
    return isStatic && displayName == FunctionElement.MAIN_FUNCTION_NAME;
  }

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  TopLevelFunctionFragment? get nextFragment {
    if (enclosingElement3 is CompilationUnitElement) {
      // TODO(augmentations): Support the fragment chain.
      return null;
    } else {
      // Local functions cannot be augmented.
      throw UnsupportedError('This is not a fragment');
    }
  }

  @override
  TopLevelFunctionFragment? get previousFragment {
    if (enclosingElement3 is CompilationUnitElement) {
      // TODO(augmentations): Support the fragment chain.
      return null;
    } else {
      // Local functions cannot be augmented.
      throw UnsupportedError('This is not a fragment');
    }
  }

  @override
  bool get _includeNameOffsetInIdentifier {
    return super._includeNameOffsetInIdentifier ||
        enclosingElement3 is ExecutableElement ||
        enclosingElement3 is VariableElement;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFunctionElement(this);
}

/// Common internal interface shared by elements whose type is a function type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypedElementImpl
    implements _ExistingElementImpl, FunctionTypedElement {
  set returnType(DartType returnType);
}

abstract class FunctionTypedElementImpl2 extends TypeParameterizedElementImpl2
    implements FunctionTypedElement2 {}

/// The element used for a generic function type.
///
/// Clients may not extend, implement or mix-in this class.
class GenericFunctionTypeElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin
    implements GenericFunctionTypeElement, FunctionTypedElementImpl {
  /// The declared return type of the function.
  DartType? _returnType;

  /// The elements representing the parameters of the function.
  List<ParameterElement> _parameters = const [];

  /// Is `true` if the type has the question mark, so is nullable.
  bool isNullable = false;

  /// The type defined by this element.
  FunctionType? _type;

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  GenericFunctionTypeElementImpl.forOffset(int nameOffset)
      : super("", nameOffset);

  @override
  List<Element> get children => [
        ...super.children,
        ...typeParameters,
        ...parameters,
      ];

  @override
  GenericFunctionTypeElement2 get element =>
      throw UnsupportedError('This is not a fragment');

  @override
  LibraryFragment? get enclosingFragment =>
      throw UnsupportedError('This is not a fragment');

  @override
  String get identifier => '-';

  @override
  ElementKind get kind => ElementKind.GENERIC_FUNCTION_TYPE;

  @override
  ElementLinkedData<ElementImpl>? get linkedData => null;

  @override
  GenericFunctionTypeFragment? get nextFragment =>
      throw UnsupportedError('This is not a fragment');

  @override
  List<ParameterElement> get parameters {
    return _parameters;
  }

  /// Set the parameters defined by this function type element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement3 = this;
      parameter.enclosingElement = this;
    }
    _parameters = parameters;
  }

  @override
  GenericFunctionTypeFragment? get previousFragment =>
      throw UnsupportedError('This is not a fragment');

  @override
  DartType get returnType {
    return _returnType!;
  }

  /// Set the return type defined by this function type element to the given
  /// [returnType].
  @override
  set returnType(DartType returnType) {
    _returnType = returnType;
  }

  @override
  FunctionType get type {
    if (_type != null) return _type!;

    return _type = FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix:
          isNullable ? NullabilitySuffix.question : NullabilitySuffix.none,
    );
  }

  /// Set the function type defined by this function type element to the given
  /// [type].
  set type(FunctionType type) {
    _type = type;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitGenericFunctionTypeElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeGenericFunctionTypeElement(this);
  }
}

class GetterElementImpl extends ExecutableElementImpl2
    with
        FragmentedExecutableElementMixin<GetterFragment>,
        FragmentedFunctionTypedElementMixin<GetterFragment>,
        FragmentedTypeParameterizedElementMixin<GetterFragment>,
        FragmentedAnnotatableElementMixin<GetterFragment>,
        FragmentedElementMixin<GetterFragment>
    implements GetterElement {
  @override
  final PropertyAccessorElementImpl firstFragment;

  GetterElementImpl(this.firstFragment) {
    PropertyAccessorElementImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as PropertyAccessorElementImpl?;
    }
  }

  @override
  GetterElement get baseElement => super.baseElement as GetterElement;

  @override
  SetterElement? get correspondingSetter2 =>
      firstFragment.correspondingSetter2?.element as SetterElement?;

  @override
  Element2? get enclosingElement2 => firstFragment.enclosingFragment?.element;

  @override
  bool get isExternal => firstFragment.isExternal;

  @override
  ElementKind get kind => ElementKind.GETTER;

  @override
  String get name => firstFragment.name;

  @override
  PropertyInducingElement2? get variable3 => firstFragment.variable2?.element;
}

/// A concrete implementation of a [HideElementCombinator].
class HideElementCombinatorImpl implements HideElementCombinator {
  @override
  List<String> hiddenNames = const [];

  @override
  int offset = 0;

  @override
  int end = -1;

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("hide ");
    int count = hiddenNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      buffer.write(hiddenNames[i]);
    }
    return buffer.toString();
  }
}

class ImportElementPrefixImpl implements ImportElementPrefix {
  @override
  final PrefixElementImpl element;

  ImportElementPrefixImpl({
    required this.element,
  });
}

abstract class InstanceElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin, MacroTargetElement
    implements InstanceElement, InstanceFragment {
  @override
  ElementLinkedData? linkedData;

  List<FieldElementImpl> _fields = _Sentinel.fieldElement;

  List<PropertyAccessorElementImpl> _accessors =
      _Sentinel.propertyAccessorElement;

  List<MethodElementImpl> _methods = _Sentinel.methodElement;

  InstanceElementImpl(super.name, super.nameOffset);

  @override
  List<PropertyAccessorElementImpl> get accessors {
    if (!identical(_accessors, _Sentinel.propertyAccessorElement)) {
      return _accessors;
    }

    linkedData?.readMembers(this);
    return _accessors;
  }

  set accessors(List<PropertyAccessorElementImpl> accessors) {
    for (var accessor in accessors) {
      accessor.enclosingElement3 = this;
      accessor.enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  InstanceElementImpl? get augmentation;

  @override
  InstanceElementImpl? get augmentationTarget;

  @override
  InstanceElement2 get element => augmented as InstanceElement2;

  @Deprecated('Use enclosingElement3 instead')
  @override
  CompilationUnitElementImpl get enclosingElement {
    return super.enclosingElement as CompilationUnitElementImpl;
  }

  @override
  CompilationUnitElementImpl get enclosingElement3 {
    return super.enclosingElement3 as CompilationUnitElementImpl;
  }

  @override
  LibraryFragment? get enclosingFragment => enclosingElement3;

  @override
  List<FieldElementImpl> get fields {
    if (!identical(_fields, _Sentinel.fieldElement)) {
      return _fields;
    }

    linkedData?.readMembers(this);
    return _fields;
  }

  set fields(List<FieldElementImpl> fields) {
    for (var field in fields) {
      field.enclosingElement3 = this;
      field.enclosingElement = this;
    }
    _fields = fields;
  }

  @override
  List<FieldFragment> get fields2 => fields.cast<FieldFragment>();

  @override
  List<GetterFragment> get getters =>
      accessors.where((e) => e.isGetter).cast<GetterFragment>().toList();

  @override
  bool get isAugmentation => augmentationTarget != null;

  @override
  List<ElementAnnotationImpl> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  List<MethodElementImpl> get methods {
    if (!identical(_methods, _Sentinel.methodElement)) {
      return _methods;
    }

    linkedData?.readMembers(this);
    return _methods;
  }

  set methods(List<MethodElementImpl> methods) {
    for (var method in methods) {
      method.enclosingElement3 = this;
      method.enclosingElement = this;
    }
    _methods = methods;
  }

  @override
  List<MethodFragment> get methods2 => methods.cast<MethodFragment>();

  @override
  InstanceFragment? get nextFragment => augmentation as InstanceFragment?;

  @override
  InstanceFragment? get previousFragment =>
      augmentationTarget as InstanceFragment?;

  @override
  List<SetterFragment> get setters =>
      accessors.where((e) => e.isSetter).cast<SetterFragment>().toList();

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

abstract class InterfaceElementImpl extends InstanceElementImpl
    implements InterfaceElement, InterfaceFragment {
  /// A list containing all of the mixins that are applied to the class being
  /// extended in order to derive the superclass of this class.
  List<InterfaceType> _mixins = const [];

  /// A list containing all of the interfaces that are implemented by this
  /// class.
  List<InterfaceType> _interfaces = const [];

  /// This callback is set during mixins inference to handle reentrant calls.
  List<InterfaceType>? Function(InterfaceElementImpl)? mixinInferenceCallback;

  InterfaceType? _supertype;

  /// The cached result of [allSupertypes].
  List<InterfaceType>? _allSupertypes;

  /// A flag indicating whether the types associated with the instance members
  /// of this class have been inferred.
  bool hasBeenInferred = false;

  /// The non-nullable instance of this element, without alias.
  /// Should be used only when the element has no type parameters.
  InterfaceType? _nonNullableInstance;

  /// The nullable instance of this element, without alias.
  /// Should be used only when the element has no type parameters.
  InterfaceType? _nullableInstance;

  List<ConstructorElementImpl> _constructors = _Sentinel.constructorElement;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  InterfaceElementImpl(super.name, super.offset);

  @override
  List<InterfaceType> get allSupertypes {
    return _allSupertypes ??=
        library.session.classHierarchy.implementedInterfaces(this);
  }

  @override
  InterfaceElementImpl? get augmentation;

  @override
  InterfaceElementImpl? get augmentationTarget;

  @override
  AugmentedInterfaceElement get augmented;

  @override
  List<Element> get children => [
        ...super.children,
        ...accessors,
        ...fields,
        ...constructors,
        ...methods,
        ...typeParameters,
      ];

  @override
  List<ConstructorElementImpl> get constructors {
    if (!identical(_constructors, _Sentinel.constructorElement)) {
      return _constructors;
    }

    _buildMixinAppConstructors();
    linkedData?.readMembers(this);
    return _constructors;
  }

  set constructors(List<ConstructorElementImpl> constructors) {
    for (var constructor in constructors) {
      constructor.enclosingElement3 = this;
      constructor.enclosingElement = this;
    }
    _constructors = constructors;
  }

  @override
  List<ConstructorFragment> get constructors2 =>
      constructors.cast<ConstructorFragment>();

  @override
  String get displayName => name;

  @override
  List<InterfaceType> get interfaces {
    linkedData?.read(this);
    return _interfaces;
  }

  set interfaces(List<InterfaceType> interfaces) {
    _interfaces = interfaces;
  }

  /// Return `true` if this class represents the class '_Enum' defined in the
  /// dart:core library.
  bool get isDartCoreEnumImpl {
    return name == '_Enum' && library.isDartCore;
  }

  /// Return `true` if this class represents the class 'Function' defined in the
  /// dart:core library.
  bool get isDartCoreFunctionImpl {
    return name == 'Function' && library.isDartCore;
  }

  @override
  bool get isSimplyBounded {
    return hasModifier(Modifier.SIMPLY_BOUNDED);
  }

  set isSimplyBounded(bool isSimplyBounded) {
    setModifier(Modifier.SIMPLY_BOUNDED, isSimplyBounded);
  }

  @override
  List<InterfaceType> get mixins {
    if (mixinInferenceCallback != null) {
      var mixins = mixinInferenceCallback!(this);
      if (mixins != null) {
        return _mixins = mixins;
      }
    }

    linkedData?.read(this);
    return _mixins;
  }

  set mixins(List<InterfaceType> mixins) {
    _mixins = mixins;
  }

  @override
  String get name {
    return super.name!;
  }

  @override
  InterfaceType? get supertype {
    linkedData?.read(this);
    return _supertype;
  }

  set supertype(InterfaceType? value) {
    _supertype = value;
  }

  @override
  InterfaceType get thisType {
    return augmented.thisType;
  }

  @override
  ConstructorElement? get unnamedConstructor {
    return constructors.firstWhereOrNull((element) => element.name.isEmpty);
  }

  /// This element and all its augmentations, in order.
  Iterable<InterfaceElementImpl> get withAugmentations sync* {
    InterfaceElementImpl? current = this;
    while (current != null) {
      yield current;
      current = current.augmentation;
    }
  }

  @override
  FieldElement? getField(String name) {
    return fields.firstWhereOrNull((fieldElement) => name == fieldElement.name);
  }

  @override
  PropertyAccessorElement? getGetter(String getterName) {
    return accessors.firstWhereOrNull(
        (accessor) => accessor.isGetter && accessor.name == getterName);
  }

  @override
  MethodElement? getMethod(String methodName) {
    return methods.firstWhereOrNull((method) => method.name == methodName);
  }

  @override
  ConstructorElement? getNamedConstructor(String name) {
    if (name == 'new') {
      // A constructor declared as `C.new` is unnamed, and is modeled as such.
      name = '';
    }
    return constructors.firstWhereOrNull((element) => element.name == name);
  }

  @override
  PropertyAccessorElement? getSetter(String setterName) {
    return getSetterFromAccessors(setterName, accessors);
  }

  @override
  InterfaceType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    assert(typeArguments.length == typeParameters.length);

    if (typeArguments.isEmpty) {
      switch (nullabilitySuffix) {
        case NullabilitySuffix.none:
          if (_nonNullableInstance case var instance?) {
            return instance;
          }
        case NullabilitySuffix.question:
          if (_nullableInstance case var instance?) {
            return instance;
          }
        case NullabilitySuffix.star:
          // TODO(scheglov): remove together with `star`
          break;
      }
    }

    var result = InterfaceTypeImpl(
      element: this,
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );

    if (typeArguments.isEmpty) {
      switch (nullabilitySuffix) {
        case NullabilitySuffix.none:
          _nonNullableInstance = result;
        case NullabilitySuffix.question:
          _nullableInstance = result;
        case NullabilitySuffix.star:
          // TODO(scheglov): remove together with `star`
          break;
      }
    }

    return result;
  }

  @override
  MethodElement? lookUpConcreteMethod(
      String methodName, LibraryElement library) {
    return _implementationsOfMethod(methodName).firstWhereOrNull(
        (method) => !method.isAbstract && method.isAccessibleIn(library));
  }

  @Deprecated('Use `element.augmented.lookUpGetter`.')
  @override
  PropertyAccessorElement? lookUpGetter(
      String getterName, LibraryElement library) {
    return _implementationsOfGetter(getterName)
        .firstWhereOrNull((getter) => getter.isAccessibleIn(library));
  }

  @override
  PropertyAccessorElement? lookUpInheritedConcreteGetter(
      String getterName, LibraryElement library) {
    return _implementationsOfGetter(getterName).firstWhereOrNull((getter) =>
        !getter.isAbstract &&
        !getter.isStatic &&
        getter.isAccessibleIn(library) &&
        getter.enclosingElement3 != this);
  }

  ExecutableElement? lookUpInheritedConcreteMember(
      String name, LibraryElement library) {
    if (name.endsWith('=')) {
      return lookUpInheritedConcreteSetter(name, library);
    } else {
      return lookUpInheritedConcreteMethod(name, library) ??
          lookUpInheritedConcreteGetter(name, library);
    }
  }

  @override
  MethodElement? lookUpInheritedConcreteMethod(
      String methodName, LibraryElement library) {
    return _implementationsOfMethod(methodName).firstWhereOrNull((method) =>
        !method.isAbstract &&
        !method.isStatic &&
        method.isAccessibleIn(library) &&
        method.enclosingElement3 != this);
  }

  @override
  PropertyAccessorElement? lookUpInheritedConcreteSetter(
      String setterName, LibraryElement library) {
    return _implementationsOfSetter(setterName).firstWhereOrNull((setter) =>
        !setter.isAbstract &&
        !setter.isStatic &&
        setter.isAccessibleIn(library) &&
        setter.enclosingElement3 != this);
  }

  @override
  MethodElement? lookUpInheritedMethod(
      String methodName, LibraryElement library) {
    return _implementationsOfMethod(methodName).firstWhereOrNull((method) =>
        !method.isStatic &&
        method.isAccessibleIn(library) &&
        method.enclosingElement3 != this);
  }

  @Deprecated('Use `element.augmented.lookUpMethod`.')
  @override
  MethodElement? lookUpMethod(String methodName, LibraryElement library) {
    return _implementationsOfMethod(methodName).firstWhereOrNull(
        (MethodElement method) => method.isAccessibleIn(library));
  }

  @Deprecated('Use `element.augmented.lookUpSetter`.')
  @override
  PropertyAccessorElement? lookUpSetter(
      String setterName, LibraryElement library) {
    return _implementationsOfSetter(setterName).firstWhereOrNull(
        (PropertyAccessorElement setter) => setter.isAccessibleIn(library));
  }

  /// Return the static getter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  PropertyAccessorElement? lookupStaticGetter(
      String name, LibraryElement library) {
    return _implementationsOfGetter(name).firstWhereOrNull(
        (element) => element.isStatic && element.isAccessibleIn(library));
  }

  /// Return the static method with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  MethodElement? lookupStaticMethod(String name, LibraryElement library) {
    return _implementationsOfMethod(name).firstWhereOrNull(
        (element) => element.isStatic && element.isAccessibleIn(library));
  }

  /// Return the static setter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  PropertyAccessorElement? lookupStaticSetter(
      String name, LibraryElement library) {
    return _implementationsOfSetter(name).firstWhereOrNull(
        (element) => element.isStatic && element.isAccessibleIn(library));
  }

  void resetCachedAllSupertypes() {
    _allSupertypes = null;
  }

  /// Builds constructors for this mixin application.
  void _buildMixinAppConstructors() {}

  /// Return an iterable containing all of the implementations of a getter with
  /// the given [getterName] that are defined in this class and any superclass
  /// of this class (but not in interfaces).
  ///
  /// The getters that are returned are not filtered in any way. In particular,
  /// they can include getters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The getters are returned based on the depth of their defining class; if
  /// this class contains a definition of the getter it will occur first, if
  /// Object contains a definition of the getter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfGetter(
      String getterName) sync* {
    var visitedClasses = <InterfaceElement>{};
    InterfaceElement? classElement = this;
    while (classElement != null && visitedClasses.add(classElement)) {
      var getter = classElement.getGetter(getterName);
      if (getter != null) {
        yield getter;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        getter = mixin.element.getGetter(getterName);
        if (getter != null) {
          yield getter;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  /// Return an iterable containing all of the implementations of a method with
  /// the given [methodName] that are defined in this class and any superclass
  /// of this class (but not in interfaces).
  ///
  /// The methods that are returned are not filtered in any way. In particular,
  /// they can include methods that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The methods are returned based on the depth of their defining class; if
  /// this class contains a definition of the method it will occur first, if
  /// Object contains a definition of the method it will occur last.
  Iterable<MethodElement> _implementationsOfMethod(String methodName) sync* {
    var visitedClasses = <InterfaceElement>{};
    InterfaceElement? classElement = this;
    while (classElement != null && visitedClasses.add(classElement)) {
      var method = classElement.getMethod(methodName);
      if (method != null) {
        yield method;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        method = mixin.element.getMethod(methodName);
        if (method != null) {
          yield method;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  /// Return an iterable containing all of the implementations of a setter with
  /// the given [setterName] that are defined in this class and any superclass
  /// of this class (but not in interfaces).
  ///
  /// The setters that are returned are not filtered in any way. In particular,
  /// they can include setters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The setters are returned based on the depth of their defining class; if
  /// this class contains a definition of the setter it will occur first, if
  /// Object contains a definition of the setter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfSetter(
      String setterName) sync* {
    var visitedClasses = <InterfaceElement>{};
    InterfaceElement? classElement = this;
    while (classElement != null && visitedClasses.add(classElement)) {
      var setter = classElement.getSetter(setterName);
      if (setter != null) {
        yield setter;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        setter = mixin.element.getSetter(setterName);
        if (setter != null) {
          yield setter;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  static PropertyAccessorElement? getSetterFromAccessors(
      String setterName, List<PropertyAccessorElement> accessors) {
    // Do we need the check for isSetter below?
    if (!setterName.endsWith('=')) {
      setterName += '=';
    }
    return accessors.firstWhereOrNull(
        (accessor) => accessor.isSetter && accessor.name == setterName);
  }
}

class JoinPatternVariableElementImpl extends PatternVariableElementImpl
    implements JoinPatternVariableElement {
  @override
  final List<PatternVariableElementImpl> variables;

  shared.JoinedPatternVariableInconsistency inconsistency;

  /// The identifiers that reference this element.
  final List<SimpleIdentifier> references = [];

  JoinPatternVariableElementImpl(
    super.name,
    super.offset,
    this.variables,
    this.inconsistency,
  ) {
    for (var component in variables) {
      component.join = this;
    }
  }

  @override
  int get hashCode => identityHashCode(this);

  @override
  bool get isConsistent {
    return inconsistency == shared.JoinedPatternVariableInconsistency.none;
  }

  /// Returns this variable, and variables that join into it.
  List<PatternVariableElementImpl> get transitiveVariables {
    var result = <PatternVariableElementImpl>[];

    void append(PatternVariableElementImpl variable) {
      result.add(variable);
      if (variable is JoinPatternVariableElementImpl) {
        for (var variable in variable.variables) {
          append(variable);
        }
      }
    }

    append(this);
    return result;
  }

  @override
  bool operator ==(Object other) => identical(other, this);
}

class JoinPatternVariableElementImpl2 extends PatternVariableElementImpl2
    implements JoinPatternVariableElement2 {
  JoinPatternVariableElementImpl2(super._wrappedElement);

  @override
  bool get isConsistent => _wrappedElement.isConsistent;

  @override
  List<PatternVariableElement2> get variables2 => _wrappedElement.variables
      .map((element) => PatternVariableElementImpl2.fromElement(element))
      .toList();

  @override
  JoinPatternVariableElementImpl get _wrappedElement =>
      super._wrappedElement as JoinPatternVariableElementImpl;
}

/// A concrete implementation of a [LabelElement].
class LabelElementImpl extends ElementImpl implements LabelElement {
  late final LabelElementImpl2 element2 = LabelElementImpl2(this);

  /// A flag indicating whether this label is associated with a `switch` member
  /// (`case` or `default`).
  // TODO(brianwilkerson): Make this a modifier.
  final bool _onSwitchMember;

  /// Initialize a newly created label element to have the given [name].
  /// [onSwitchMember] should be `true` if this label is associated with a
  /// `switch` member.
  LabelElementImpl(String super.name, super.nameOffset, this._onSwitchMember);

  @override
  String get displayName => name;

  @Deprecated('Use enclosingElement3 instead')
  @override
  ExecutableElement get enclosingElement =>
      super.enclosingElement as ExecutableElement;

  @override
  ExecutableElement get enclosingElement3 =>
      super.enclosingElement3 as ExecutableElement;

  /// Return `true` if this label is associated with a `switch` member (`case
  /// ` or`default`).
  bool get isOnSwitchMember => _onSwitchMember;

  @override
  ElementKind get kind => ElementKind.LABEL;

  @override
  String get name => super.name!;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitLabelElement(this);
}

class LabelElementImpl2 extends ElementImpl2
    with WrappedElementMixin
    implements LabelElement2 {
  @override
  final LabelElementImpl _wrappedElement;

  LabelElementImpl2(this._wrappedElement);

  @override
  LabelElement2 get baseElement => this;

  @override
  ExecutableElement2? get enclosingElement2 =>
      super.enclosingElement2 as ExecutableElement2?;

  @override
  ExecutableFragment get enclosingFunction {
    var element = _wrappedElement.enclosingElement3;
    if (element is! ExecutableElementImpl) {
      throw StateError(
          'Expected to find ExecutableElement, but found ${element.runtimeType}');
    }
    return element;
  }

  @override
  LibraryElement2 get library2 => super.library2!;

  @override
  int get nameOffset => _wrappedElement.nameOffset;
}

/// A concrete implementation of a [LibraryElement] or [LibraryElement2].
class LibraryElementImpl extends LibraryOrAugmentationElementImpl
    with _HasLibraryMixin, MacroTargetElement
    implements LibraryElement, LibraryElement2 {
  /// The analysis context in which this library is defined.
  @override
  final AnalysisContext context;

  @override
  AnalysisSessionImpl session;

  /// The language version for the library.
  LibraryLanguageVersion? _languageVersion;

  bool hasTypeProviderSystemSet = false;

  @override
  late TypeProviderImpl typeProvider;

  @override
  late TypeSystemImpl typeSystem;

  late List<ExportedReference> exportedReferences;

  @override
  LibraryElementLinkedData? linkedData;

  /// The union of names for all searchable elements in this library.
  ElementNameUnion nameUnion = ElementNameUnion.empty();

  @override
  final FeatureSet featureSet;

  /// The entry point for this library, or `null` if this library does not have
  /// an entry point.
  FunctionElement? _entryPoint;

  /// The element representing the synthetic function `loadLibrary` that is
  /// defined for this library, or `null` if the element has not yet been
  /// created.
  late FunctionElement _loadLibraryFunction;

  @override
  int nameLength;

  /// The export [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace? _exportNamespace;

  /// The public [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace? _publicNamespace;

  /// The macro executor for the bundle to which this library belongs.
  BundleMacroExecutor? bundleMacroExecutor;

  /// Information about why non-promotable private fields in the library are not
  /// promotable.
  ///
  /// See [fieldNameNonPromotabilityInfo].
  Map<String, FieldNameNonPromotabilityInfo>? _fieldNameNonPromotabilityInfo;

  /// The map of top-level declarations, from all units.
  LibraryDeclarations? _libraryDeclarations;

  /// Initialize a newly created library element in the given [context] to have
  /// the given [name] and [offset].
  LibraryElementImpl(this.context, this.session, String name, int offset,
      this.nameLength, this.featureSet)
      : linkedData = null,
        super(name: name, nameOffset: offset);

  @Deprecated('Use CompilationUnitElement.accessibleExtensions instead')
  @override
  List<ExtensionElement> get accessibleExtensions {
    return scope.accessibleExtensions;
  }

  @override
  List<Element> get children => [
        definingCompilationUnit,
        // ignore:deprecated_member_use_from_same_package
        ...libraryExports,
        // ignore:deprecated_member_use_from_same_package
        ...libraryImports,
        // ignore:deprecated_member_use_from_same_package
        ...parts,
        ..._partUnits,
      ];

  @override
  List<ClassElement2> get classes {
    var declarations = <ClassElement2>{};
    for (var unit in units) {
      declarations.addAll(
          unit._classes.map((element) => element.augmented as ClassElement2));
    }
    return declarations.toList();
  }

  @override
  Null get enclosingElement3 => null;

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return _definingCompilationUnit;
  }

  @override
  FunctionElement? get entryPoint {
    linkedData?.read(this);
    return _entryPoint;
  }

  set entryPoint(FunctionElement? entryPoint) {
    _entryPoint = entryPoint;
  }

  @override
  TopLevelFunctionElement? get entryPoint2 =>
      entryPoint as TopLevelFunctionElement?;

  @override
  List<EnumElement2> get enums {
    var declarations = <EnumElement2>{};
    for (var unit in units) {
      declarations.addAll(
          unit._enums.map((element) => element.augmented as EnumElement2));
    }
    return declarations.toList();
  }

  @override
  List<LibraryElementImpl> get exportedLibraries {
    return fragments
        .expand((fragment) => fragment.libraryExports)
        .map((export) => export.exportedLibrary)
        .nonNulls
        .toSet()
        .toList();
  }

  @Deprecated('Use CompilationUnitElement.libraryExports')
  @override
  List<LibraryElement2> get exportedLibraries2 =>
      exportedLibraries.cast<LibraryElement2>();

  @override
  Namespace get exportNamespace {
    linkedData?.read(this);
    return _exportNamespace ??= Namespace({});
  }

  set exportNamespace(Namespace exportNamespace) {
    _exportNamespace = exportNamespace;
  }

  @override
  List<ExtensionElement2> get extensions {
    var declarations = <ExtensionElement2>{};
    for (var unit in units) {
      declarations.addAll(unit._extensions
          .map((element) => element.augmented as ExtensionElement2));
    }
    return declarations.toList();
  }

  @override
  List<ExtensionTypeElement2> get extensionTypes {
    var declarations = <ExtensionTypeElement2>{};
    for (var unit in units) {
      declarations.addAll(unit._extensionTypes
          .map((element) => element.augmented as ExtensionTypeElement2));
    }
    return declarations.toList();
  }

  /// Information about why non-promotable private fields in the library are not
  /// promotable.
  ///
  /// If field promotion is not enabled in this library, this field is still
  /// populated, so that the analyzer can figure out whether enabling field
  /// promotion would cause a field to be promotable.
  ///
  /// There are two ways an access to a private property name might not be
  /// promotable: the property might be non-promotable for a reason inherent to
  /// itself (e.g. it's declared as a concrete getter rather than a field, or
  /// it's a non-final field), or the property might have the same name as an
  /// inherently non-promotable property elsewhere in the same library (in which
  /// case the inherently non-promotable property is said to be "conflicting").
  ///
  /// When a compile-time error occurs because a property is non-promotable due
  /// conflicting properties elsewhere in the library, the analyzer needs to be
  /// able to find the conflicting properties in order to generate context
  /// messages. This data structure allows that, by mapping each non-promotable
  /// private name to the set of conflicting declarations.
  ///
  /// If a field in the library has a private name and that name does not appear
  /// as a key in this map, the field is promotable.
  Map<String, FieldNameNonPromotabilityInfo> get fieldNameNonPromotabilityInfo {
    linkedData?.read(this);
    return _fieldNameNonPromotabilityInfo!;
  }

  set fieldNameNonPromotabilityInfo(
      Map<String, FieldNameNonPromotabilityInfo>? value) {
    _fieldNameNonPromotabilityInfo = value;
  }

  @override
  LibraryFragment get firstFragment =>
      definingCompilationUnit as LibraryFragment;

  @override
  List<CompilationUnitElementImpl> get fragments {
    return [
      _definingCompilationUnit,
      ..._partUnits,
    ];
  }

  @override
  List<TopLevelFunctionElement> get functions {
    var declarations = <TopLevelFunctionElement>{};
    for (var unit in units) {
      declarations.addAll(unit._functions
          .map((fragment) => (fragment as TopLevelFunctionFragment).element));
    }
    return declarations.toList();
  }

  @override
  List<GetterElement> get getters {
    var declarations = <GetterElement>{};
    for (var unit in units) {
      declarations.addAll(unit._accessors
          .where((accessor) => accessor.isGetter)
          .map((accessor) =>
              (accessor as GetterFragment).element as GetterElement));
    }
    return declarations.toList();
  }

  bool get hasPartOfDirective {
    return hasModifier(Modifier.HAS_PART_OF_DIRECTIVE);
  }

  set hasPartOfDirective(bool hasPartOfDirective) {
    setModifier(Modifier.HAS_PART_OF_DIRECTIVE, hasPartOfDirective);
  }

  @override
  String get identifier => '${_definingCompilationUnit.source.uri}';

  @override
  List<LibraryElementImpl> get importedLibraries {
    return fragments
        .expand((fragment) => fragment.libraryImports)
        .map((import) => import.importedLibrary)
        .nonNulls
        .toSet()
        .toList();
  }

  @Deprecated('Not used anymore')
  @override
  bool get isBrowserApplication =>
      entryPoint != null && isOrImportsBrowserLibrary;

  @override
  bool get isDartAsync => name == "dart.async";

  @override
  bool get isDartCore => name == "dart.core";

  @override
  bool get isInSdk {
    var uri = definingCompilationUnit.source.uri;
    return DartUriResolver.isDartUri(uri);
  }

  @Deprecated('Only non-nullable by default mode is supported')
  @override
  bool get isNonNullableByDefault {
    return featureSet.isEnabled(Feature.non_nullable);
  }

  /// Return `true` if the receiver directly or indirectly imports the
  /// 'dart:html' libraries.
  @Deprecated('Not used anymore')
  bool get isOrImportsBrowserLibrary {
    List<LibraryElement> visited = <LibraryElement>[];
    var htmlLibSource = context.sourceFactory.forUri(DartSdk.DART_HTML);
    visited.add(this);
    for (int index = 0; index < visited.length; index++) {
      LibraryElement library = visited[index];
      var source = library.definingCompilationUnit.source;
      if (source == htmlLibSource) {
        return true;
      }
      for (LibraryElement importedLibrary in library.importedLibraries) {
        if (!visited.contains(importedLibrary)) {
          visited.add(importedLibrary);
        }
      }
      for (LibraryElement exportedLibrary in library.exportedLibraries) {
        if (!visited.contains(exportedLibrary)) {
          visited.add(exportedLibrary);
        }
      }
    }
    return false;
  }

  @override
  ElementKind get kind => ElementKind.LIBRARY;

  @override
  LibraryLanguageVersion get languageVersion {
    return _languageVersion ??= LibraryLanguageVersion(
      package: ExperimentStatus.currentVersion,
      override: null,
    );
  }

  set languageVersion(LibraryLanguageVersion languageVersion) {
    _languageVersion = languageVersion;
  }

  @override
  LibraryElementImpl get library => this;

  @override
  LibraryElement2 get library2 => this;

  LibraryDeclarations get libraryDeclarations {
    return _libraryDeclarations ??= LibraryDeclarations(this);
  }

  @override
  FunctionElement get loadLibraryFunction {
    return _loadLibraryFunction;
  }

  @override
  TopLevelFunctionElement get loadLibraryFunction2 =>
      loadLibraryFunction as TopLevelFunctionElement;

  @override
  List<ElementAnnotationImpl> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  List<MixinElement2> get mixins {
    var declarations = <MixinElement2>{};
    for (var unit in units) {
      declarations.addAll(
          unit._mixins.map((element) => element.augmented as MixinElement2));
    }
    return declarations.toList();
  }

  @override
  String get name => super.name!;

  @Deprecated('Use CompilationUnitElement.parts')
  @override
  List<PartElementImpl> get parts {
    return definingCompilationUnit.parts;
  }

  @override
  Namespace get publicNamespace {
    return _publicNamespace ??=
        NamespaceBuilder().createPublicNamespaceForLibrary(this);
  }

  set publicNamespace(Namespace publicNamespace) {
    _publicNamespace = publicNamespace;
  }

  @override
  List<SetterElement> get setters {
    var declarations = <SetterElement>{};
    for (var unit in units) {
      declarations.addAll(unit._accessors
          .where((accessor) => accessor.isSetter)
          .map((accessor) =>
              (accessor as SetterFragment).element as SetterElement));
    }
    return declarations.toList();
  }

  @override
  Source get source {
    return _definingCompilationUnit.source;
  }

  @override
  Iterable<Element> get topLevelElements sync* {
    for (var unit in units) {
      yield* unit.accessors;
      yield* unit.classes;
      yield* unit.enums;
      yield* unit.extensions;
      yield* unit.extensionTypes;
      yield* unit.functions;
      yield* unit.mixins;
      yield* unit.topLevelVariables;
      yield* unit.typeAliases;
    }
  }

  @override
  List<TopLevelVariableElement2> get topLevelVariables {
    var declarations = <TopLevelVariableElement2>{};
    for (var unit in units) {
      declarations.addAll(unit._variables
          .map((fragment) => (fragment as TopLevelVariableFragment).element));
    }
    return declarations.toList();
  }

  @override
  List<TypeAliasElement2> get typeAliases {
    var declarations = <TypeAliasElement2>{};
    for (var unit in units) {
      declarations.addAll(unit._typeAliases
          .map((fragment) => (fragment as TypeAliasFragment).element));
    }
    return declarations.toList();
  }

  @override
  List<CompilationUnitElementImpl> get units {
    return [
      _definingCompilationUnit,
      ..._partUnits,
    ];
  }

  List<CompilationUnitElementImpl> get _partUnits {
    var result = <CompilationUnitElementImpl>[];

    void visitParts(CompilationUnitElementImpl unit) {
      for (var part in unit.parts) {
        if (part.uri case DirectiveUriWithUnitImpl uri) {
          var unit = uri.unit;
          result.add(unit);
          visitParts(unit);
        }
      }
    }

    visitParts(definingCompilationUnit);
    return result;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitLibraryElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeLibraryElement(this);
  }

  /// Create the [FunctionElement] to be returned by [loadLibraryFunction].
  /// The [typeProvider] must be already set.
  void createLoadLibraryFunction() {
    _loadLibraryFunction =
        FunctionElementImpl(FunctionElement.LOAD_LIBRARY_NAME, -1)
          ..enclosingElement = library
          ..enclosingElement3 = library
          ..isSynthetic = true
          ..returnType = typeProvider.futureDynamicType;
  }

  @override
  ClassElement? getClass(String name) {
    for (var unitElement in units) {
      var element = unitElement.getClass(name);
      if (element != null) {
        return element;
      }
    }
    return null;
  }

  EnumElement? getEnum(String name) {
    for (var unitElement in units) {
      var element = unitElement.getEnum(name);
      if (element != null) {
        return element;
      }
    }
    return null;
  }

  MixinElement? getMixin(String name) {
    for (var unitElement in units) {
      var element = unitElement.getMixin(name);
      if (element != null) {
        return element;
      }
    }
    return null;
  }

  /// Return `true` if [reference] comes only from deprecated exports.
  bool isFromDeprecatedExport(ExportedReference reference) {
    if (reference is ExportedReferenceExported) {
      for (var location in reference.locations) {
        var export = location.exportOf(this);
        if (!export.hasDeprecated) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  void resetScope() {
    _libraryDeclarations = null;
    for (var fragment in units) {
      fragment._scope = null;
    }
  }

  @Deprecated('Only non-nullable by default mode is supported')
  @override
  T toLegacyElementIfOptOut<T extends Element>(T element) {
    return element;
  }

  @Deprecated('Only non-nullable by default mode is supported')
  @override
  DartType toLegacyTypeIfOptOut(DartType type) {
    return type;
  }

  static List<PrefixElementImpl> buildPrefixesFromImports(
      List<LibraryImportElementImpl> imports) {
    var prefixes = <PrefixElementImpl>{};
    for (var element in imports) {
      var prefix = element.prefix?.element;
      if (prefix != null) {
        prefixes.add(prefix);
      }
    }
    return prefixes.toList(growable: false);
  }
}

class LibraryExportElementImpl extends _ExistingElementImpl
    implements LibraryExportElement, LibraryExport {
  @override
  final List<NamespaceCombinator> combinators;

  @override
  final int exportKeywordOffset;

  @override
  final DirectiveUri uri;

  LibraryExportElementImpl({
    required this.combinators,
    required this.exportKeywordOffset,
    required this.uri,
  }) : super(null, exportKeywordOffset);

  @override
  LibraryElementImpl? get exportedLibrary {
    var uri = this.uri;
    if (uri is DirectiveUriWithLibraryImpl) {
      return uri.library;
    }
    return null;
  }

  @override
  LibraryElement2? get exportedLibrary2 => exportedLibrary;

  @override
  int get hashCode => identityHashCode(this);

  @override
  String get identifier => 'export@$nameOffset';

  @override
  ElementKind get kind => ElementKind.EXPORT;

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitLibraryExportElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExportElement(this);
  }
}

class LibraryImportElementImpl extends _ExistingElementImpl
    implements LibraryImportElement, LibraryImport {
  @override
  final List<NamespaceCombinator> combinators;

  @override
  final int importKeywordOffset;

  @override
  final ImportElementPrefixImpl? prefix;

  @override
  final PrefixFragmentImpl? prefix2;

  @override
  final DirectiveUri uri;

  Namespace? _namespace;

  LibraryImportElementImpl({
    required this.combinators,
    required this.importKeywordOffset,
    required this.prefix,
    required this.prefix2,
    required this.uri,
  }) : super(null, importKeywordOffset);

  @override
  CompilationUnitElementImpl get enclosingElement3 {
    return super.enclosingElement3 as CompilationUnitElementImpl;
  }

  @override
  int get hashCode => identityHashCode(this);

  @override
  String get identifier => 'import@$nameOffset';

  @override
  LibraryElementImpl? get importedLibrary {
    var uri = this.uri;
    if (uri is DirectiveUriWithLibraryImpl) {
      return uri.library;
    }
    return null;
  }

  @override
  LibraryElement2? get importedLibrary2 => importedLibrary;

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  LibraryElementImpl get library2 => super.library2 as LibraryElementImpl;

  @override
  Namespace get namespace {
    var uri = this.uri;
    if (uri is DirectiveUriWithLibrary) {
      return _namespace ??=
          NamespaceBuilder().createImportNamespaceForDirective(
        importedLibrary: uri.library,
        combinators: combinators,
        prefix: prefix?.element,
      );
    }
    return Namespace.EMPTY;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitLibraryImportElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeImportElement(this);
  }
}

/// A concrete implementation of a [LibraryOrAugmentationElement].
abstract class LibraryOrAugmentationElementImpl extends ElementImpl
    implements LibraryOrAugmentationElement {
  /// The compilation unit that defines this library.
  late CompilationUnitElementImpl _definingCompilationUnit;

  LibraryOrAugmentationElementImpl({
    required String? name,
    required int nameOffset,
  }) : super(name, nameOffset);

  @override
  CompilationUnitElementImpl get definingCompilationUnit =>
      _definingCompilationUnit;

  /// Set the compilation unit that defines this library to the given
  ///  compilation[unit].
  set definingCompilationUnit(CompilationUnitElementImpl unit) {
    unit.libraryOrAugmentationElement = this;
    unit.enclosingElement = this;
    _definingCompilationUnit = unit;
  }

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return _definingCompilationUnit;
  }

  @override
  String get identifier => '${_definingCompilationUnit.source.uri}';

  @override
  LibraryElementImpl get library;

  @Deprecated('Use CompilationUnitElement.libraryExports')
  @override
  List<LibraryExportElementImpl> get libraryExports {
    return definingCompilationUnit.libraryExports;
  }

  @Deprecated('Use CompilationUnitElement.libraryImports')
  @override
  List<LibraryImportElementImpl> get libraryImports {
    return definingCompilationUnit.libraryImports;
  }

  @Deprecated('Use CompilationUnitElement.libraryImportPrefixes')
  @override
  List<PrefixElementImpl> get prefixes {
    return definingCompilationUnit.libraryImportPrefixes;
  }

  @Deprecated('Use CompilationUnitElement.scope')
  @override
  LibraryFragmentScope get scope {
    return definingCompilationUnit.scope;
  }

  @override
  AnalysisSessionImpl get session;

  @override
  Source get source {
    return _definingCompilationUnit.source;
  }
}

class LocalFunctionElementImpl extends ExecutableElementImpl2
    with WrappedElementMixin
    implements LocalFunctionElement {
  @override
  final FunctionElementImpl _wrappedElement;

  LocalFunctionElementImpl(this._wrappedElement);

  @override
  String? get documentationComment => _wrappedElement.documentationComment;

  @override
  ExecutableFragment get enclosingFunction {
    var element = _wrappedElement.enclosingElement3;
    if (element is! ExecutableElementImpl) {
      throw StateError(
          'Expected to find ExecutableElement, but found ${element.runtimeType}');
    }
    return element;
  }

  @override
  List<FormalParameterElement> get formalParameters =>
      _wrappedElement.formalParameters
          .map((fragment) => fragment.element)
          .toList();

  @override
  bool get hasAlwaysThrows => _wrappedElement.hasAlwaysThrows;

  @override
  bool get hasDeprecated => _wrappedElement.hasDeprecated;

  @override
  bool get hasDoNotStore => _wrappedElement.hasDoNotStore;

  @override
  bool get hasDoNotSubmit => _wrappedElement.hasDoNotSubmit;

  @override
  bool get hasFactory => _wrappedElement.hasFactory;

  @override
  bool get hasImmutable => _wrappedElement.hasImmutable;

  @override
  bool get hasImplicitReturnType => _wrappedElement.hasImplicitReturnType;

  @override
  bool get hasInternal => _wrappedElement.hasInternal;

  @override
  bool get hasIsTest => _wrappedElement.hasIsTest;

  @override
  bool get hasIsTestGroup => _wrappedElement.hasIsTestGroup;

  @override
  bool get hasJS => _wrappedElement.hasJS;

  @override
  bool get hasLiteral => _wrappedElement.hasLiteral;

  @override
  bool get hasMustBeConst => _wrappedElement.hasMustBeConst;

  @override
  bool get hasMustBeOverridden => _wrappedElement.hasMustBeOverridden;

  @override
  bool get hasMustCallSuper => _wrappedElement.hasMustCallSuper;

  @override
  bool get hasNonVirtual => _wrappedElement.hasNonVirtual;

  @override
  bool get hasOptionalTypeArgs => _wrappedElement.hasOptionalTypeArgs;

  @override
  bool get hasOverride => _wrappedElement.hasOverride;

  @override
  bool get hasProtected => _wrappedElement.hasProtected;

  @override
  bool get hasRedeclare => _wrappedElement.hasRedeclare;

  @override
  bool get hasReopen => _wrappedElement.hasReopen;

  @override
  bool get hasRequired => _wrappedElement.hasRequired;

  @override
  bool get hasSealed => _wrappedElement.hasSealed;

  @override
  bool get hasUseResult => _wrappedElement.hasUseResult;

  @override
  bool get hasVisibleForOverriding => _wrappedElement.hasVisibleForOverriding;

  @override
  bool get hasVisibleForTemplate => _wrappedElement.hasVisibleForTemplate;

  @override
  bool get hasVisibleForTesting => _wrappedElement.hasVisibleForTesting;

  @override
  bool get hasVisibleOutsideTemplate =>
      _wrappedElement.hasVisibleOutsideTemplate;

  @override
  bool get isAbstract => _wrappedElement.isAbstract;

  @override
  bool get isExtensionTypeMember => _wrappedElement.isExtensionTypeMember;

  @override
  bool get isExternal => false;

  @override
  bool get isSimplyBounded => _wrappedElement.isSimplyBounded;

  @override
  bool get isStatic => _wrappedElement.isStatic;

  @override
  List<ElementAnnotation> get metadata => _wrappedElement.metadata;

  @override
  int get nameOffset => _wrappedElement.nameOffset;

  @override
  DartType get returnType => _wrappedElement.returnType;

  @override
  Version? get sinceSdkVersion => _wrappedElement.sinceSdkVersion;

  @override
  FunctionType get type => _wrappedElement.type;

  @override
  List<TypeParameterElement2> get typeParameters2 =>
      _wrappedElement.typeParameters
          .map((fragment) => (fragment as TypeParameterFragment).element)
          .toList();
}

/// A concrete implementation of a [LocalVariableElement].
class LocalVariableElementImpl extends NonParameterVariableElementImpl
    implements LocalVariableElement {
  late LocalVariableElementImpl2 _element2 = LocalVariableElementImpl2(this);

  @override
  late bool hasInitializer;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  LocalVariableElementImpl(super.name, super.offset);

  LocalVariableElementImpl2 get element2 => _element2;

  @override
  String get identifier {
    return '$name$nameOffset';
  }

  @override
  bool get isLate {
    return hasModifier(Modifier.LATE);
  }

  @override
  ElementKind get kind => ElementKind.LOCAL_VARIABLE;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitLocalVariableElement(this);
}

class LocalVariableElementImpl2 extends PromotableElementImpl2
    with WrappedElementMixin
    implements LocalVariableElement2 {
  @override
  final LocalVariableElementImpl _wrappedElement;

  LocalVariableElementImpl2(this._wrappedElement);

  @override
  LocalVariableElement2 get baseElement => this;

  @override
  ExecutableFragment get enclosingFunction {
    var element = _wrappedElement.enclosingElement3;
    if (element is! ExecutableElementImpl) {
      throw StateError(
          'Expected to find ExecutableElement, but found ${element.runtimeType}');
    }
    return element;
  }

  @override
  bool get hasImplicitType => _wrappedElement.hasImplicitType;

  @override
  bool get hasInitializer => _wrappedElement.hasInitializer;

  @override
  bool get isConst => _wrappedElement.isConst;

  @override
  bool get isFinal => _wrappedElement.isFinal;

  @override
  bool get isLate => _wrappedElement.isLate;

  @override
  bool get isStatic => _wrappedElement.isStatic;

  @override
  int get nameOffset => _wrappedElement.nameOffset;

  @override
  DartType get type => _wrappedElement.type;

  LocalVariableElementImpl get wrappedElement {
    return _wrappedElement;
  }

  @override
  DartObject? computeConstantValue() => _wrappedElement.computeConstantValue();
}

/// Additional information for a macro generated fragment.
class MacroGeneratedLibraryFragment {
  final String code;
  final Uint8List informativeBytes;

  MacroGeneratedLibraryFragment({
    required this.code,
    required this.informativeBytes,
  });
}

mixin MacroTargetElement on ElementImpl {
  /// Diagnostics registered while applying macros to this element.
  List<AnalyzerMacroDiagnostic> _macroDiagnostics = const [];

  ElementLinkedData? get linkedData;

  /// Diagnostics registered while applying macros to this element.
  List<AnalyzerMacroDiagnostic> get macroDiagnostics {
    linkedData?.read(this);
    return _macroDiagnostics;
  }

  set macroDiagnostics(List<AnalyzerMacroDiagnostic> value) {
    _macroDiagnostics = value;
  }

  void addMacroDiagnostic(AnalyzerMacroDiagnostic diagnostic) {
    _macroDiagnostics = [..._macroDiagnostics, diagnostic];
  }
}

mixin MaybeAugmentedClassElementMixin on MaybeAugmentedInterfaceElementMixin
    implements AugmentedClassElement, ClassElement2 {
  @override
  ClassElementImpl get declaration;

  @override
  ClassElementImpl get firstFragment => declaration;

  @override
  bool get hasNonFinalField => declaration.hasNonFinalField;

  @override
  bool get isAbstract => declaration.isAbstract;

  @override
  bool get isBase => declaration.isBase;

  @override
  bool get isConstructable => declaration.isConstructable;

  @override
  bool get isDartCoreEnum => declaration.isDartCoreEnum;

  @override
  bool get isDartCoreObject => declaration.isDartCoreObject;

  @override
  bool get isExhaustive => declaration.isExhaustive;

  @override
  bool get isFinal => declaration.isFinal;

  @override
  bool get isInterface => declaration.isInterface;

  @override
  bool get isMixinApplication => declaration.isMixinApplication;

  @override
  bool get isMixinClass => declaration.isMixinClass;

  @override
  bool get isSealed => declaration.isSealed;

  @override
  bool get isValidMixin => declaration.isValidMixin;

  @override
  bool isExtendableIn2(LibraryElement2 library) =>
      declaration.isExtendableIn(library as LibraryElement);

  @override
  bool isImplementableIn2(LibraryElement2 library) =>
      declaration.isImplementableIn(library as LibraryElement);

  @override
  bool isMixableIn2(LibraryElement2 library) =>
      declaration.isMixableIn(library as LibraryElement);
}

mixin MaybeAugmentedEnumElementMixin on MaybeAugmentedInterfaceElementMixin
    implements AugmentedEnumElement, EnumElement2 {
  @override
  List<FieldElement> get constants {
    return fields.where((field) => field.isEnumConstant).toList();
  }

  @override
  List<FieldElement2> get constants2 => constants.cast<FieldElement2>();

  @override
  EnumElementImpl get declaration;

  @override
  EnumFragment get firstFragment => declaration;
}

mixin MaybeAugmentedExtensionElementMixin on MaybeAugmentedInstanceElementMixin
    implements AugmentedExtensionElement, ExtensionElement2 {
  @override
  DartType extendedType = InvalidTypeImpl.instance;

  @override
  ExtensionElementImpl get declaration;

  @override
  ExtensionElementImpl get firstFragment => declaration;

  @override
  DartType get thisType => extendedType;
}

mixin MaybeAugmentedExtensionTypeElementMixin
    on MaybeAugmentedInterfaceElementMixin
    implements AugmentedExtensionTypeElement, ExtensionTypeElement2 {
  @override
  late ConstructorElementImpl primaryConstructor;

  @override
  late FieldElementImpl representation;

  @override
  late DartType typeErasure;

  @override
  ExtensionTypeElementImpl get declaration;

  @override
  ExtensionTypeElementImpl get firstFragment => declaration;

  @override
  ConstructorElement2 get primaryConstructor2 =>
      representation as ConstructorElement2;

  @override
  FieldElement2 get representation2 => representation as FieldElement2;
}

mixin MaybeAugmentedInstanceElementMixin
    implements
        AugmentedInstanceElement,
        InstanceElement2,
        TypeParameterizedElement2 {
  @override
  List<PropertyAccessorElement> get accessors;

  @override
  Element2? get baseElement => declaration.baseElement;

  @override
  List<Element2> get children2 => declaration.children2;

  @override
  InstanceElementImpl get declaration;

  @override
  String get displayName => declaration.displayName;

  @override
  String? get documentationComment => declaration.documentationComment;

  @override
  LibraryElement2 get enclosingElement2 => declaration.library;

  @override
  List<FieldElement> get fields;

  @override
  List<FieldElement2> get fields2 =>
      fields.map((e) => e.asElement2 as FieldElement2?).nonNulls.toList();

  @override
  InstanceFragment get firstFragment => declaration;

  @override
  List<GetterElement> get getters2 => accessors
      .where((e) => e.isGetter)
      .map((e) => e.asElement2 as GetterElement?)
      .nonNulls
      .toList();

  @override
  bool get hasAlwaysThrows => declaration.hasAlwaysThrows;

  @override
  bool get hasDeprecated => declaration.hasDeprecated;

  @override
  bool get hasDoNotStore => declaration.hasDoNotStore;

  @override
  bool get hasDoNotSubmit => declaration.hasDoNotSubmit;

  @override
  bool get hasFactory => declaration.hasFactory;

  @override
  bool get hasImmutable => declaration.hasImmutable;

  @override
  bool get hasInternal => declaration.hasInternal;

  @override
  bool get hasIsTest => declaration.hasIsTest;

  @override
  bool get hasIsTestGroup => declaration.hasIsTestGroup;

  @override
  bool get hasJS => declaration.hasJS;

  @override
  bool get hasLiteral => declaration.hasLiteral;

  @override
  bool get hasMustBeConst => declaration.hasMustBeConst;

  @override
  bool get hasMustBeOverridden => declaration.hasMustBeOverridden;

  @override
  bool get hasMustCallSuper => declaration.hasMustCallSuper;

  @override
  bool get hasNonVirtual => declaration.hasNonVirtual;

  @override
  bool get hasOptionalTypeArgs => declaration.hasOptionalTypeArgs;

  @override
  bool get hasOverride => declaration.hasOverride;

  @override
  bool get hasProtected => declaration.hasProtected;

  @override
  bool get hasRedeclare => declaration.hasRedeclare;

  @override
  bool get hasReopen => declaration.hasReopen;

  @override
  bool get hasRequired => declaration.hasRequired;

  @override
  bool get hasSealed => declaration.hasSealed;

  @override
  bool get hasUseResult => declaration.hasUseResult;

  @override
  bool get hasVisibleForOverriding => declaration.hasVisibleForOverriding;

  @override
  bool get hasVisibleForTemplate => declaration.hasVisibleForTemplate;

  @override
  bool get hasVisibleForTesting => declaration.hasVisibleForTesting;

  @override
  bool get hasVisibleOutsideTemplate => declaration.hasVisibleOutsideTemplate;

  @override
  int get id => declaration.id;

  @override
  bool get isPrivate => declaration.isPrivate;

  @override
  bool get isPublic => declaration.isPublic;

  @override
  bool get isSimplyBounded => declaration.isSimplyBounded;

  @override
  bool get isSynthetic => declaration.isSynthetic;

  @override
  ElementKind get kind => declaration.kind;

  @override
  LibraryElement2 get library2 => declaration.library2!;

  @override
  ElementLocation? get location => declaration.location;

  @override
  List<ElementAnnotation> get metadata => declaration.metadata;

  @override
  List<MethodElement> get methods;

  @override
  List<MethodElement2> get methods2 =>
      methods.map((e) => e.asElement2 as MethodElement2?).nonNulls.toList();

  @override
  String? get name => declaration.name;

  @override
  Element2 get nonSynthetic2 =>
      isSynthetic ? enclosingElement2 : this as Element2;

  @override
  AnalysisSession? get session => declaration.session;

  @override
  List<SetterElement> get setters2 => accessors
      .where((e) => e.isSetter)
      .map((e) => e.asElement2 as SetterElement?)
      .nonNulls
      .toList();

  @override
  Version? get sinceSdkVersion => declaration.sinceSdkVersion;

  @override
  List<TypeParameterElement2> get typeParameters2 => declaration.typeParameters
      .map((fragment) => (fragment as TypeParameterFragment).element)
      .toList();

  @override
  String displayString2(
          {bool multiline = false, bool preferTypeAlias = false}) =>
      declaration.getDisplayString(
          multiline: multiline, preferTypeAlias: preferTypeAlias);

  @override
  FieldElement? getField(String name) {
    var length = fields.length;
    for (var i = 0; i < length; i++) {
      var field = fields[i];
      if (field.name == name) {
        return field;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getGetter(String name) {
    var length = accessors.length;
    for (var i = 0; i < length; i++) {
      var accessor = accessors[i];
      if (accessor.isGetter && accessor.name == name) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement? getMethod(String name) {
    var length = methods.length;
    for (var i = 0; i < length; i++) {
      var method = methods[i];
      if (method.name == name) {
        return method;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getSetter(String name) {
    if (!name.endsWith('=')) {
      name += '=';
    }
    return accessors.firstWhereOrNull(
        (accessor) => accessor.isSetter && accessor.name == name);
  }

  @override
  bool isAccessibleIn2(LibraryElement2 library) =>
      declaration.isAccessibleIn(library as LibraryElement);

  @override
  PropertyAccessorElement? lookUpGetter({
    required String name,
    required LibraryElement library,
  }) {
    return _implementationsOfGetter(name)
        .firstWhereOrNull((getter) => getter.isAccessibleIn(library));
  }

  @override
  MethodElement? lookUpMethod({
    required String name,
    required LibraryElement library,
  }) {
    return _implementationsOfMethod(name).firstWhereOrNull(
        (MethodElement method) => method.isAccessibleIn(library));
  }

  @override
  PropertyAccessorElement? lookUpSetter({
    required String name,
    required LibraryElement library,
  }) {
    return _implementationsOfSetter(name).firstWhereOrNull(
        (PropertyAccessorElement setter) => setter.isAccessibleIn(library));
  }

  @override
  E? thisOrAncestorMatching2<E extends Element2>(
    bool Function(Element2) predicate,
  ) =>
      declaration.thisOrAncestorMatching2(predicate);

  @override
  E? thisOrAncestorOfType2<E extends Element2>() =>
      declaration.thisOrAncestorOfType2<E>();

  /// Return an iterable containing all of the implementations of a getter with
  /// the given [name] that are defined in this class and any superclass of this
  /// class (but not in interfaces).
  ///
  /// The getters that are returned are not filtered in any way. In particular,
  /// they can include getters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The getters are returned based on the depth of their defining class; if
  /// this class contains a definition of the getter it will occur first, if
  /// Object contains a definition of the getter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfGetter(
      String name) sync* {
    var visitedClasses = <AugmentedInstanceElement>{};
    AugmentedInstanceElement? augmented = this;
    while (augmented != null && visitedClasses.add(augmented)) {
      var getter = augmented.getGetter(name);
      if (getter != null) {
        yield getter;
      }
      if (augmented is! AugmentedInterfaceElement) {
        return;
      }
      for (InterfaceType mixin in augmented.mixins.reversed) {
        getter = mixin.element.augmented.getGetter(name);
        if (getter != null) {
          yield getter;
        }
      }
      augmented = augmented.declaration.supertype?.element.augmented;
    }
  }

  /// Return an iterable containing all of the implementations of a method with
  /// the given [name] that are defined in this class and any superclass of this
  /// class (but not in interfaces).
  ///
  /// The methods that are returned are not filtered in any way. In particular,
  /// they can include methods that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The methods are returned based on the depth of their defining class; if
  /// this class contains a definition of the method it will occur first, if
  /// Object contains a definition of the method it will occur last.
  Iterable<MethodElement> _implementationsOfMethod(String name) sync* {
    var visitedClasses = <AugmentedInstanceElement>{};
    AugmentedInstanceElement? augmented = this;
    while (augmented != null && visitedClasses.add(augmented)) {
      var method = augmented.getMethod(name);
      if (method != null) {
        yield method;
      }
      if (augmented is! AugmentedInterfaceElement) {
        return;
      }
      for (InterfaceType mixin in augmented.mixins.reversed) {
        method = mixin.element.augmented.getMethod(name);
        if (method != null) {
          yield method;
        }
      }
      augmented = augmented.declaration.supertype?.element.augmented;
    }
  }

  /// Return an iterable containing all of the implementations of a setter with
  /// the given [name] that are defined in this class and any superclass of this
  /// class (but not in interfaces).
  ///
  /// The setters that are returned are not filtered in any way. In particular,
  /// they can include setters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The setters are returned based on the depth of their defining class; if
  /// this class contains a definition of the setter it will occur first, if
  /// Object contains a definition of the setter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfSetter(
      String name) sync* {
    var visitedClasses = <AugmentedInstanceElement>{};
    AugmentedInstanceElement? augmented = this;
    while (augmented != null && visitedClasses.add(augmented)) {
      var setter = augmented.getSetter(name);
      if (setter != null) {
        yield setter;
      }
      if (augmented is! AugmentedInterfaceElement) {
        return;
      }
      for (InterfaceType mixin in augmented.mixins.reversed) {
        setter = mixin.element.augmented.getSetter(name);
        if (setter != null) {
          yield setter;
        }
      }
      augmented = augmented.declaration.supertype?.element.augmented;
    }
  }
}

mixin MaybeAugmentedInterfaceElementMixin on MaybeAugmentedInstanceElementMixin
    implements AugmentedInterfaceElement, InterfaceElement2 {
  InterfaceType? _thisType;

  @override
  List<InterfaceType> get allSupertypes => declaration.allSupertypes;

  @override
  List<ConstructorElement2> get constructors2 => constructors
      .map((constructor) =>
          (constructor.declaration as ConstructorElementImpl).element)
      .toList();

  @override
  InterfaceElementImpl get declaration;

  @override
  List<InterfaceType> get interfaces => declaration.interfaces;

  @override
  List<InterfaceType> get mixins => declaration.mixins;

  @override
  InterfaceType? get supertype => declaration.supertype;

  @override
  InterfaceType get thisType {
    if (_thisType == null) {
      List<DartType> typeArguments;
      var typeParameters = declaration.typeParameters;
      if (typeParameters.isNotEmpty) {
        typeArguments = typeParameters.map<DartType>((t) {
          return t.instantiate(nullabilitySuffix: NullabilitySuffix.none);
        }).toFixedList();
      } else {
        typeArguments = const <DartType>[];
      }
      return _thisType = declaration.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }
    return _thisType!;
  }

  @override
  ConstructorElement? get unnamedConstructor {
    return constructors.firstWhereOrNull((element) => element.name.isEmpty);
  }

  @override
  ConstructorElement2? get unnamedConstructor2 =>
      unnamedConstructor.asElement2 as ConstructorElement2;

  @override
  ConstructorElement? getNamedConstructor(String name) {
    name = name.ifEqualThen('new', '');
    return constructors.firstWhereOrNull((element) => element.name == name);
  }

  @override
  InterfaceType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) =>
      declaration.instantiate(
          typeArguments: typeArguments, nullabilitySuffix: nullabilitySuffix);
}

mixin MaybeAugmentedMixinElementMixin on MaybeAugmentedInterfaceElementMixin
    implements AugmentedMixinElement, MixinElement2 {
  @override
  MixinElementImpl get declaration;

  @override
  MixinElementImpl get firstFragment => declaration;

  @override
  bool get isBase => declaration.isBase;

  @override
  bool isImplementableIn2(LibraryElement2 library) =>
      declaration.isImplementableIn(library as LibraryElement);
}

/// A concrete implementation of a [MethodElement].
class MethodElementImpl extends ExecutableElementImpl
    with AugmentableElement<MethodElementImpl>
    implements MethodElement, MethodFragment {
  /// Is `true` if this method is `operator==`, and there is no explicit
  /// type specified for its formal parameter, in this method or in any
  /// overridden methods other than the one declared in `Object`.
  bool isOperatorEqualWithParameterTypeFromObject = false;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError? typeInferenceError;

  /// The element corresponding to this fragment.
  MethodElement2? _element;

  /// Initialize a newly created method element to have the given [name] at the
  /// given [offset].
  MethodElementImpl(super.name, super.offset);

  @override
  MethodElement get declaration => this;

  @override
  String get displayName {
    String displayName = super.displayName;
    if ("unary-" == displayName) {
      return "-";
    }
    return displayName;
  }

  @override
  MethodElement2 get element {
    if (_element != null) {
      return _element!;
    }
    MethodFragment firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return MethodElementImpl2(firstFragment as MethodElementImpl);
  }

  set element(MethodElement2 element) => _element = element;

  @override
  InstanceFragment? get enclosingFragment =>
      enclosingElement3 as InstanceFragment;

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isOperator {
    String name = displayName;
    if (name.isEmpty) {
      return false;
    }
    int first = name.codeUnitAt(0);
    return !((0x61 <= first && first <= 0x7A) ||
        (0x41 <= first && first <= 0x5A) ||
        first == 0x5F ||
        first == 0x24);
  }

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  String get name {
    String name = super.name;
    if (name == '-' && parameters.isEmpty) {
      return 'unary-';
    }
    return name;
  }

  @override
  MethodFragment? get nextFragment => augmentation;

  @override
  Element get nonSynthetic {
    if (isSynthetic && enclosingElement3 is EnumElementImpl) {
      return enclosingElement3;
    }
    return this;
  }

  @override
  MethodFragment? get previousFragment => augmentationTarget;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);
}

class MethodElementImpl2 extends ExecutableElementImpl2
    with
        FragmentedExecutableElementMixin<MethodFragment>,
        FragmentedFunctionTypedElementMixin<MethodFragment>,
        FragmentedTypeParameterizedElementMixin<MethodFragment>,
        FragmentedAnnotatableElementMixin<MethodFragment>,
        FragmentedElementMixin<MethodFragment>
    implements MethodElement2 {
  @override
  final MethodElementImpl firstFragment;

  MethodElementImpl2(this.firstFragment) {
    MethodElementImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as MethodElementImpl?;
    }
  }

  @override
  MethodElement2 get baseElement => this;

  @override
  Element2? get enclosingElement2 =>
      (firstFragment._enclosingElement3 as InstanceFragment).element;

  @override
  bool get isOperator => firstFragment.isOperator;

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  String get name => firstFragment.name;
}

/// A [ClassElementImpl] representing a mixin declaration.
class MixinElementImpl extends ClassOrMixinElementImpl
    with AugmentableElement<MixinElementImpl>
    implements MixinElement, MixinFragment {
  List<InterfaceType> _superclassConstraints = const [];

  /// Names of methods, getters, setters, and operators that this mixin
  /// declaration super-invokes.  For setters this includes the trailing "=".
  /// The list will be empty if this class is not a mixin declaration.
  late List<String> superInvokedNames;

  late MaybeAugmentedMixinElementMixin augmentedInternal =
      NotAugmentedMixinElementImpl(this);

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  MixinElementImpl(super.name, super.offset);

  @override
  MaybeAugmentedMixinElementMixin get augmented {
    if (isAugmentation) {
      if (augmentationTarget case var augmentationTarget?) {
        return augmentationTarget.augmented;
      }
    }

    linkedData?.read(this);
    return augmentedInternal;
  }

  AugmentedMixinElementImpl? get augmentedIfReally {
    if (augmentationTarget != null) {
      if (augmented case AugmentedMixinElementImpl augmented) {
        return augmented;
      }
    }
    return null;
  }

  @override
  MixinElement2 get element => super.element as MixinElement2;

  @override
  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  @override
  ElementKind get kind => ElementKind.MIXIN;

  @override
  List<InterfaceType> get mixins => const [];

  @override
  set mixins(List<InterfaceType> mixins) {
    throw StateError('Attempt to set mixins for a mixin declaration.');
  }

  @override
  List<InterfaceType> get superclassConstraints {
    linkedData?.read(this);
    return _superclassConstraints;
  }

  set superclassConstraints(List<InterfaceType> superclassConstraints) {
    _superclassConstraints = superclassConstraints;
  }

  @override
  InterfaceType? get supertype => null;

  @override
  set supertype(InterfaceType? supertype) {
    throw StateError('Attempt to set a supertype for a mixin declaration.');
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitMixinElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeMixinElement(this);
  }

  @override
  bool isImplementableIn(LibraryElement library) {
    if (library == this.library) {
      return true;
    }
    return !isBase;
  }
}

/// The constants for all of the modifiers defined by the Dart language and for
/// a few additional flags that are useful.
///
/// Clients may not extend, implement or mix-in this class.
enum Modifier {
  /// Indicates that the modifier 'abstract' was applied to the element.
  ABSTRACT,

  /// Indicates that an executable element has a body marked as being
  /// asynchronous.
  ASYNCHRONOUS,

  /// Indicates that the modifier 'augment' was applied to the element.
  AUGMENTATION,

  /// Indicates that the element is the start of the augmentation chain,
  /// in the simplest case - the declaration. But could be an augmentation
  /// that has no augmented declaration (which is a compile-time error).
  AUGMENTATION_CHAIN_START,

  /// Indicates that the modifier 'base' was applied to the element.
  BASE,

  /// Indicates that the modifier 'const' was applied to the element.
  CONST,

  /// Indicates that the modifier 'covariant' was applied to the element.
  COVARIANT,

  /// Indicates that the class is `Object` from `dart:core`.
  DART_CORE_OBJECT,

  /// Indicates that the import element represents a deferred library.
  DEFERRED,

  /// Indicates that a class element was defined by an enum declaration.
  ENUM,

  /// Indicates that the element is an enum constant field.
  ENUM_CONSTANT,

  /// Indicates that the element is an extension type member.
  EXTENSION_TYPE_MEMBER,

  /// Indicates that a class element was defined by an enum declaration.
  EXTERNAL,

  /// Indicates that the modifier 'factory' was applied to the element.
  FACTORY,

  /// Indicates that the modifier 'final' was applied to the element.
  FINAL,

  /// Indicates that an executable element has a body marked as being a
  /// generator.
  GENERATOR,

  /// Indicates that the pseudo-modifier 'get' was applied to the element.
  GETTER,

  /// Indicates that this class has an explicit `extends` clause.
  HAS_EXTENDS_CLAUSE,

  /// A flag used for libraries indicating that the variable has an explicit
  /// initializer.
  HAS_INITIALIZER,

  /// A flag used for libraries indicating that the defining compilation unit
  /// has a `part of` directive, meaning that this unit should be a part,
  /// but is used as a library.
  HAS_PART_OF_DIRECTIVE,

  /// Indicates that the value of [Element.sinceSdkVersion] was computed.
  HAS_SINCE_SDK_VERSION_COMPUTED,

  /// [HAS_SINCE_SDK_VERSION_COMPUTED] and the value was not `null`.
  HAS_SINCE_SDK_VERSION_VALUE,

  /// Indicates that the associated element did not have an explicit type
  /// associated with it. If the element is an [ExecutableElement], then the
  /// type being referred to is the return type.
  IMPLICIT_TYPE,

  /// Indicates that the modifier 'interface' was applied to the element.
  INTERFACE,

  /// Indicates that the method invokes the super method with the same name.
  INVOKES_SUPER_SELF,

  /// Indicates that modifier 'lazy' was applied to the element.
  LATE,

  /// Indicates that a class is a macro builder.
  MACRO,

  /// Indicates that a class is a mixin application.
  MIXIN_APPLICATION,

  /// Indicates that a class is a mixin class.
  MIXIN_CLASS,

  PROMOTABLE,

  /// Indicates whether the type of a [PropertyInducingElementImpl] should be
  /// used to infer the initializer. We set it to `false` if the type was
  /// inferred from the initializer itself.
  SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE,

  /// Indicates that the modifier 'sealed' was applied to the element.
  SEALED,

  /// Indicates that the pseudo-modifier 'set' was applied to the element.
  SETTER,

  /// See [TypeParameterizedElement.isSimplyBounded].
  SIMPLY_BOUNDED,

  /// Indicates that the modifier 'static' was applied to the element.
  STATIC,

  /// Indicates that the element does not appear in the source code but was
  /// implicitly created. For example, if a class does not define any
  /// constructors, an implicit zero-argument constructor will be created and it
  /// will be marked as being synthetic.
  SYNTHETIC
}

/// A concrete implementation of a [MultiplyDefinedElement].
class MultiplyDefinedElementImpl implements MultiplyDefinedElement, Element2 {
  /// The unique integer identifier of this element.
  @override
  final int id = ElementImpl._NEXT_ID++;

  /// The analysis context in which the multiply defined elements are defined.
  @override
  final AnalysisContext context;

  @override
  final AnalysisSession session;

  /// The name of the conflicting elements.
  @override
  final String name;

  @override
  final List<Element> conflictingElements;

  /// Initialize a newly created element in the given [context] to represent
  /// the given non-empty [conflictingElements].
  MultiplyDefinedElementImpl(
      this.context, this.session, this.name, this.conflictingElements);

  @override
  Element2? get baseElement => null;

  @override
  List<Element> get children => const [];

  @override
  List<Element2> get children2 => const [];

  @override
  Element? get declaration => null;

  @override
  String get displayName => name;

  @override
  String? get documentationComment => null;

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element? get enclosingElement => null;

  @override
  Element2? get enclosingElement2 => null;

  @override
  Element? get enclosingElement3 => null;

  @override
  bool get hasAlwaysThrows => false;

  @override
  bool get hasDeprecated => false;

  @override
  bool get hasDoNotStore => false;

  @override
  bool get hasDoNotSubmit => false;

  @override
  bool get hasFactory => false;

  @override
  bool get hasImmutable => false;

  @override
  bool get hasInternal => false;

  @override
  bool get hasIsTest => false;

  @override
  bool get hasIsTestGroup => false;

  @override
  bool get hasJS => false;

  @override
  bool get hasLiteral => false;

  @override
  bool get hasMustBeConst => false;

  @override
  bool get hasMustBeOverridden => false;

  @override
  bool get hasMustCallSuper => false;

  @override
  bool get hasNonVirtual => false;

  @override
  bool get hasOptionalTypeArgs => false;

  @override
  bool get hasOverride => false;

  @override
  bool get hasProtected => false;

  @override
  bool get hasRedeclare => false;

  @override
  bool get hasReopen => false;

  @override
  bool get hasRequired => false;

  @override
  bool get hasSealed => false;

  @override
  bool get hasUseResult => false;

  @override
  bool get hasVisibleForOverriding => false;

  @override
  bool get hasVisibleForTemplate => false;

  @override
  bool get hasVisibleForTesting => false;

  @override
  bool get hasVisibleOutsideTemplate => false;

  @override
  bool get isPrivate {
    throw UnimplementedError();
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isSynthetic => true;

  bool get isVisibleForTemplate => false;

  bool get isVisibleOutsideTemplate => false;

  @override
  ElementKind get kind => ElementKind.ERROR;

  @override
  LibraryElement? get library => null;

  @override
  LibraryElement2? get library2 => null;

  @override
  Source? get librarySource => null;

  @override
  ElementLocation? get location => null;

  @override
  List<ElementAnnotationImpl> get metadata {
    return const <ElementAnnotationImpl>[];
  }

  @override
  int get nameLength => 0;

  @override
  int get nameOffset => -1;

  @override
  Element get nonSynthetic => this;

  @override
  Element2 get nonSynthetic2 => this;

  @override
  Version? get sinceSdkVersion => null;

  @override
  Source? get source => null;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitMultiplyDefinedElement(this);

  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    // TODO(scheglov): implement displayString2
    throw UnimplementedError();
  }

  @override
  String getDisplayString({
    @Deprecated('Only non-nullable by default mode is supported')
    bool withNullability = true,
    bool multiline = false,
  }) {
    var elementsStr = conflictingElements.map((e) {
      return e.getDisplayString();
    }).join(', ');
    return '[$elementsStr]';
  }

  @override
  String getExtendedDisplayName(String? shortName) {
    if (shortName != null) {
      return shortName;
    }
    return displayName;
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    for (Element element in conflictingElements) {
      if (element.isAccessibleIn(library)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool isAccessibleIn2(LibraryElement2 library) {
    // TODO(scheglov): implement isAccessibleIn2
    throw UnimplementedError();
  }

  @override
  E? thisOrAncestorMatching<E extends Element>(
    bool Function(Element) predicate,
  ) {
    return null;
  }

  @override
  E? thisOrAncestorMatching2<E extends Element2>(
    bool Function(Element2 p1) predicate,
  ) {
    return null;
  }

  @override
  E? thisOrAncestorMatching3<E extends Element>(
    bool Function(Element) predicate,
  ) {
    return null;
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() => null;

  @override
  E? thisOrAncestorOfType2<E extends Element2>() {
    return null;
  }

  @override
  E? thisOrAncestorOfType3<E extends Element>() => null;

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    bool needsSeparator = false;
    void writeList(List<Element> elements) {
      for (Element element in elements) {
        if (needsSeparator) {
          buffer.write(", ");
        } else {
          needsSeparator = true;
        }
        buffer.write(
          element.getDisplayString(),
        );
      }
    }

    buffer.write("[");
    writeList(conflictingElements);
    buffer.write("]");
    return buffer.toString();
  }

  /// Use the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child in children) {
      child.accept(visitor);
    }
  }
}

/// The synthetic element representing the declaration of the type `Never`.
class NeverElementImpl extends ElementImpl implements TypeDefiningElement {
  /// The unique instance of this class.
  static final instance = NeverElementImpl._();

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  NeverElementImpl._() : super('Never', -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.NEVER;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => null;

  DartType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  }) {
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        return NeverTypeImpl.instanceNullable;
      case NullabilitySuffix.star:
        // TODO(scheglov): remove together with `star`
        return NeverTypeImpl.instanceNullable;
      case NullabilitySuffix.none:
        return NeverTypeImpl.instance;
    }
  }
}

/// A [VariableElementImpl], which is not a parameter.
abstract class NonParameterVariableElementImpl extends VariableElementImpl
    with _HasLibraryMixin {
  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  NonParameterVariableElementImpl(String super.name, super.offset);

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element get enclosingElement => super.enclosingElement!;

  @override
  Element get enclosingElement3 => super.enclosingElement3!;

  bool get hasInitializer {
    return hasModifier(Modifier.HAS_INITIALIZER);
  }

  /// Set whether this variable has an initializer.
  set hasInitializer(bool hasInitializer) {
    setModifier(Modifier.HAS_INITIALIZER, hasInitializer);
  }
}

class NotAugmentedClassElementImpl extends NotAugmentedInterfaceElementImpl
    with MaybeAugmentedClassElementMixin {
  @override
  final ClassElementImpl element;

  NotAugmentedClassElementImpl(this.element);

  @override
  ClassElementImpl get declaration => element;

  @override
  AugmentedClassElementImpl toAugmented() {
    var augmented = AugmentedClassElementImpl(declaration);
    declaration.augmentedInternal = augmented;
    return augmented;
  }
}

class NotAugmentedEnumElementImpl extends NotAugmentedInterfaceElementImpl
    with MaybeAugmentedEnumElementMixin {
  @override
  final EnumElementImpl element;

  NotAugmentedEnumElementImpl(this.element);

  @override
  EnumElementImpl get declaration => element;

  @override
  AugmentedEnumElementImpl toAugmented() {
    var augmented = AugmentedEnumElementImpl(declaration);
    declaration.augmentedInternal = augmented;
    return augmented;
  }
}

class NotAugmentedExtensionElementImpl extends NotAugmentedInstanceElementImpl
    with MaybeAugmentedExtensionElementMixin {
  @override
  final ExtensionElementImpl element;

  NotAugmentedExtensionElementImpl(this.element);

  @override
  ExtensionElementImpl get declaration => element;

  @override
  AugmentedExtensionElementImpl toAugmented() {
    var augmented = AugmentedExtensionElementImpl(declaration);
    augmented.extendedType = extendedType;
    declaration.augmentedInternal = augmented;
    return augmented;
  }
}

class NotAugmentedExtensionTypeElementImpl
    extends NotAugmentedInterfaceElementImpl
    with MaybeAugmentedExtensionTypeElementMixin {
  @override
  final ExtensionTypeElementImpl element;

  NotAugmentedExtensionTypeElementImpl(this.element);

  @override
  ExtensionTypeElementImpl get declaration => element;

  @override
  AugmentedExtensionTypeElementImpl toAugmented() {
    var augmented = AugmentedExtensionTypeElementImpl(declaration);
    augmented.primaryConstructor = primaryConstructor;
    augmented.representation = representation;
    declaration.augmentedInternal = augmented;
    return augmented;
  }
}

abstract class NotAugmentedInstanceElementImpl
    with MaybeAugmentedInstanceElementMixin {
  @override
  List<PropertyAccessorElement> get accessors {
    return element.accessors;
  }

  InstanceElementImpl get element;

  @override
  List<FieldElement> get fields {
    return element.fields;
  }

  @override
  List<ElementAnnotationImpl> get metadata {
    return element.metadata;
  }

  @override
  List<MethodElement> get methods {
    return element.methods;
  }

  /// Returns the empty augmented version, without members.
  AugmentedInstanceElementImpl toAugmented();
}

abstract class NotAugmentedInterfaceElementImpl
    extends NotAugmentedInstanceElementImpl
    with MaybeAugmentedInterfaceElementMixin {
  @override
  List<ConstructorElement> get constructors {
    return element.constructors;
  }

  @override
  InterfaceElementImpl get declaration;

  @override
  InterfaceElementImpl get element;

  @override
  List<InterfaceType> get interfaces {
    return element.interfaces;
  }

  @override
  List<InterfaceType> get mixins {
    return element.mixins;
  }

  @override
  String get name => element.name;

  @override
  ConstructorElement? get unnamedConstructor {
    return element.unnamedConstructor;
  }

  @override
  ConstructorElement? getNamedConstructor(String name) {
    return element.getNamedConstructor(name);
  }
}

class NotAugmentedMixinElementImpl extends NotAugmentedInterfaceElementImpl
    with MaybeAugmentedMixinElementMixin {
  @override
  final MixinElementImpl element;

  NotAugmentedMixinElementImpl(this.element);

  @override
  MixinElementImpl get declaration => element;

  @override
  List<InterfaceType> get superclassConstraints {
    return element.superclassConstraints;
  }

  @override
  AugmentedMixinElementImpl toAugmented() {
    var augmented = AugmentedMixinElementImpl(declaration);
    declaration.augmentedInternal = augmented;
    return augmented;
  }
}

/// A concrete implementation of a [ParameterElement].
class ParameterElementImpl extends VariableElementImpl
    with ParameterElementMixin
    implements ParameterElement, FormalParameterFragment {
  /// A list containing all of the parameters defined by this parameter element.
  /// There will only be parameters if this parameter is a function typed
  /// parameter.
  List<ParameterElement> _parameters = const [];

  /// A list containing all of the type parameters defined for this parameter
  /// element. There will only be parameters if this parameter is a function
  /// typed parameter.
  List<TypeParameterElement> _typeParameters = const [];

  @override
  final ParameterKind parameterKind;

  @override
  String? defaultValueCode;

  /// True if this parameter inherits from a covariant parameter. This happens
  /// when it overrides a method in a supertype that has a corresponding
  /// covariant parameter.
  bool inheritsCovariant = false;

  /// The element corresponding to this fragment.
  FormalParameterElement? _element;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  ParameterElementImpl({
    required String? name,
    required int nameOffset,
    required this.parameterKind,
  }) : super(name, nameOffset);

  /// Creates a synthetic parameter with [name], [type] and [parameterKind].
  factory ParameterElementImpl.synthetic(
      String? name, DartType type, ParameterKind parameterKind) {
    var element = ParameterElementImpl(
      name: name,
      nameOffset: -1,
      parameterKind: parameterKind,
    );
    element.type = type;
    element.isSynthetic = true;
    return element;
  }

  @override
  List<Element> get children => parameters;

  @override
  List<Fragment> get children3 => const [];

  @override
  ParameterElement get declaration => this;

  @override
  FormalParameterElement get element {
    if (_element != null) {
      return _element!;
    }
    FormalParameterFragment firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return _createElement(firstFragment);
  }

  set element(FormalParameterElement element) => _element = element;

  @override
  Fragment? get enclosingFragment => enclosingElement3 as Fragment?;

  @override
  bool get hasDefaultValue {
    return defaultValueCode != null;
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    return false;
  }

  /// Return true if this parameter is explicitly marked as being covariant.
  bool get isExplicitlyCovariant {
    return hasModifier(Modifier.COVARIANT);
  }

  /// Set whether this variable parameter is explicitly marked as being
  /// covariant.
  set isExplicitlyCovariant(bool isCovariant) {
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isInitializingFormal => false;

  @override
  bool get isLate => false;

  @override
  bool get isSuperFormal => false;

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  LibraryFragment get libraryFragment =>
      thisOrAncestorOfType<CompilationUnitElementImpl>() as LibraryFragment;

  @override
  // TODO(augmentations): Support chaining between the fragments.
  FormalParameterFragment? get nextFragment => null;

  @override
  List<ParameterElement> get parameters {
    return _parameters;
  }

  /// Set the parameters defined by this executable element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement3 = this;
      parameter.enclosingElement = this;
    }
    _parameters = parameters;
  }

  @override
  // TODO(augmentations): Support chaining between the fragments.
  FormalParameterFragment? get previousFragment => null;

  @override
  List<TypeParameterElement> get typeParameters {
    return _typeParameters;
  }

  /// Set the type parameters defined by this parameter element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement3 = this;
      parameter.enclosingElement = this;
    }
    _typeParameters = typeParameters;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameter(this);
  }

  FormalParameterElement _createElement(
          FormalParameterFragment firstFragment) =>
      FormalParameterElementImpl(firstFragment as ParameterElementImpl);
}

/// The parameter of an implicit setter.
// Pre-existing name.
// ignore: camel_case_types
class ParameterElementImpl_ofImplicitSetter extends ParameterElementImpl {
  final PropertyAccessorElementImpl_ImplicitSetter setter;

  ParameterElementImpl_ofImplicitSetter(this.setter)
      : super(
          name: considerCanonicalizeString('_${setter.variable2.name}'),
          nameOffset: -1,
          parameterKind: ParameterKind.REQUIRED,
        ) {
    enclosingElement3 = setter;
    enclosingElement = setter;
    isSynthetic = true;
  }

  @override
  bool get inheritsCovariant {
    var variable = setter.variable2;
    if (variable is FieldElementImpl) {
      return variable.inheritsCovariant;
    }
    return false;
  }

  @override
  set inheritsCovariant(bool value) {
    var variable = setter.variable2;
    if (variable is FieldElementImpl) {
      variable.inheritsCovariant = value;
    }
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    return false;
  }

  @override
  bool get isExplicitlyCovariant {
    var variable = setter.variable2;
    if (variable is FieldElementImpl) {
      return variable.isCovariant;
    }
    return false;
  }

  @override
  Element get nonSynthetic {
    return setter.variable2;
  }

  @override
  DartType get type => setter.variable2.type;

  @override
  set type(DartType type) {
    assert(false); // Should never be called.
  }
}

/// A mixin that provides a common implementation for methods defined in
/// [ParameterElement].
mixin ParameterElementMixin implements ParameterElement {
  @override
  bool get isNamed => parameterKind.isNamed;

  @override
  bool get isOptional => parameterKind.isOptional;

  @override
  bool get isOptionalNamed => parameterKind.isOptionalNamed;

  @override
  bool get isOptionalPositional => parameterKind.isOptionalPositional;

  @override
  bool get isPositional => parameterKind.isPositional;

  @override
  bool get isRequired => parameterKind.isRequired;

  @override
  bool get isRequiredNamed => parameterKind.isRequiredNamed;

  @override
  bool get isRequiredPositional => parameterKind.isRequiredPositional;

  @override
  // Overridden to remove the 'deprecated' annotation.
  ParameterKind get parameterKind;

  @override
  void appendToWithoutDelimiters(
    StringBuffer buffer, {
    @Deprecated('Only non-nullable by default mode is supported')
    bool withNullability = true,
  }) {
    buffer.write(
      type.getDisplayString(
        // ignore:deprecated_member_use_from_same_package
        withNullability: withNullability,
      ),
    );
    buffer.write(' ');
    buffer.write(displayName);
    if (defaultValueCode != null) {
      buffer.write(' = ');
      buffer.write(defaultValueCode);
    }
  }
}

class PartElementImpl extends _ExistingElementImpl
    implements PartElement, LibraryFragmentInclude {
  @override
  final DirectiveUri uri;

  PartElementImpl({
    required this.uri,
  }) : super(null, -1);

  @override
  CompilationUnitElementImpl get enclosingUnit {
    var enclosingLibrary = enclosingElement3 as LibraryElementImpl;
    return enclosingLibrary._definingCompilationUnit;
  }

  @override
  String get identifier => 'part';

  @override
  ElementKind get kind => ElementKind.PART;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitPartElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writePartElement(this);
  }
}

class PatternVariableElementImpl extends LocalVariableElementImpl
    implements PatternVariableElement {
  @override
  JoinPatternVariableElementImpl? join;

  /// This flag is set to `true` while we are visiting the [WhenClause] of
  /// the [GuardedPattern] that declares this variable.
  bool isVisitingWhenClause = false;

  PatternVariableElementImpl(super.name, super.offset);

  /// Return the root [join], or self.
  PatternVariableElementImpl get rootVariable {
    return join?.rootVariable ?? this;
  }
}

class PatternVariableElementImpl2 extends LocalVariableElementImpl2
    implements PatternVariableElement2 {
  PatternVariableElementImpl2(super._wrappedElement);

  @override
  JoinPatternVariableElement2? get join2 =>
      JoinPatternVariableElementImpl2(_wrappedElement.join!);

  @override
  PatternVariableElementImpl get _wrappedElement =>
      super._wrappedElement as PatternVariableElementImpl;

  static PatternVariableElement2 fromElement(
      PatternVariableElementImpl element) {
    if (element is JoinPatternVariableElementImpl) {
      return JoinPatternVariableElementImpl2(element);
    } else if (element is BindPatternVariableElementImpl) {
      return BindPatternVariableElementImpl2(element);
    }
    return PatternVariableElementImpl2(element);
  }
}

/// A concrete implementation of a [PrefixElement].
class PrefixElementImpl extends _ExistingElementImpl implements PrefixElement {
  /// The scope of this prefix, `null` if not set yet.
  PrefixScope? _scope;

  /// Initialize a newly created method element to have the given [name] and
  /// [nameOffset].
  PrefixElementImpl(String super.name, super.nameOffset, {super.reference});

  @override
  String get displayName => name;

  PrefixElementImpl2 get element2 {
    return enclosingElement3.prefixes.firstWhere((element) {
      return element.name == name;
    });
  }

  @Deprecated('Use enclosingElement3 instead')
  @override
  LibraryOrAugmentationElementImpl get enclosingElement =>
      super.enclosingElement as LibraryOrAugmentationElementImpl;

  @override
  LibraryElement2 get enclosingElement2 => enclosingElement3 as LibraryElement2;

  @override
  CompilationUnitElementImpl get enclosingElement3 {
    return _enclosingElement3 as CompilationUnitElementImpl;
  }

  @override
  List<LibraryImportElementImpl> get imports {
    return enclosingElement3.libraryImports
        .where((import) => import.prefix?.element == this)
        .toList();
  }

  @override
  ElementKind get kind => ElementKind.PREFIX;

  @override
  LibraryElement2 get library2 => library as LibraryElement2;

  @override
  String get name {
    return super.name!;
  }

  @override
  PrefixScope get scope {
    enclosingElement3.scope;
    // SAFETY: The previous statement initializes this field.
    return _scope!;
  }

  set scope(PrefixScope value) {
    _scope = value;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitPrefixElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writePrefixElement(this);
  }
}

class PrefixElementImpl2 extends ElementImpl2 implements PrefixElement2 {
  final Reference reference;

  @override
  final PrefixFragmentImpl firstFragment;

  PrefixFragmentImpl lastFragment;

  PrefixElementImpl2({
    required this.reference,
    required this.firstFragment,
  }) : lastFragment = firstFragment {
    reference.element2 = this;
  }

  @override
  Null get enclosingElement2 => null;

  List<PrefixFragmentImpl> get fragments {
    return [
      for (PrefixFragmentImpl? fragment = firstFragment;
          fragment != null;
          fragment = fragment.nextFragment)
        fragment
    ];
  }

  @override
  List<LibraryImportElementImpl> get imports {
    return firstFragment.enclosingFragment.libraryImports
        .where((import) => import.prefix2?.element == this)
        .toList();
  }

  @override
  bool get isSynthetic => false;

  @override
  ElementKind get kind => ElementKind.PREFIX;

  @override
  LibraryElementImpl get library2 {
    return firstFragment.libraryFragment.element;
  }

  @override
  String get name => firstFragment.name;

  @override
  // TODO(scheglov): implement scope
  Scope get scope => throw UnimplementedError();

  void addFragment(PrefixFragmentImpl fragment) {
    lastFragment.nextFragment = fragment;
    fragment.previousFragment = lastFragment;
    lastFragment = fragment;
  }

  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    var builder = ElementDisplayStringBuilder(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
    builder.writePrefixElement2(this);
    return builder.toString();
  }
}

class PrefixFragmentImpl implements PrefixFragment {
  @override
  final CompilationUnitElementImpl enclosingFragment;

  @override
  final String name;

  @override
  int nameOffset;

  @override
  final bool isDeferred;

  @override
  late final PrefixElementImpl2 element;

  @override
  PrefixFragmentImpl? previousFragment;

  @override
  PrefixFragmentImpl? nextFragment;

  PrefixFragmentImpl({
    required this.enclosingFragment,
    required this.name,
    required this.nameOffset,
    required this.isDeferred,
  });

  @override
  List<Fragment> get children3 => const [];

  @override
  CompilationUnitElementImpl get libraryFragment => enclosingFragment;
}

abstract class PromotableElementImpl2 extends VariableElementImpl2
    implements PromotableElement2 {}

/// A concrete implementation of a [PropertyAccessorElement].
class PropertyAccessorElementImpl extends ExecutableElementImpl
    with AugmentableElement<PropertyAccessorElementImpl>
    implements PropertyAccessorElement, GetterFragment, SetterFragment {
  PropertyInducingElementImpl? _variable;

  /// The element corresponding to this fragment.
  ///
  /// The element will always be an instance of either `GetterElement` or
  /// `SetterElement`.
  ExecutableElement2? _element;

  /// Initialize a newly created property accessor element to have the given
  /// [name] and [offset].
  PropertyAccessorElementImpl(super.name, super.offset);

  /// Initialize a newly created synthetic property accessor element to be
  /// associated with the given [variable].
  PropertyAccessorElementImpl.forVariable(PropertyInducingElementImpl variable,
      {Reference? reference})
      : _variable = variable,
        super(variable.name, -1, reference: reference) {
    isAbstract = variable is FieldElementImpl && variable.isAbstract;
    isStatic = variable.isStatic;
    isSynthetic = true;
  }

  @override
  PropertyAccessorElementImpl? get augmentationTarget {
    if (super.augmentationTarget case var target?) {
      if (target.kind == kind) {
        return target;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? get correspondingGetter {
    if (isGetter) {
      return null;
    }
    return variable2?.getter;
  }

  @override
  GetterFragment? get correspondingGetter2 =>
      correspondingGetter as GetterFragment?;

  @override
  PropertyAccessorElement? get correspondingSetter {
    if (isSetter) {
      return null;
    }
    return variable2?.setter;
  }

  @override
  SetterFragment? get correspondingSetter2 =>
      correspondingSetter as SetterFragment?;

  @override
  PropertyAccessorElement get declaration => this;

  @override
  ExecutableElement2 get element {
    if (_element != null) {
      return _element!;
    }
    PropertyAccessorElementImpl firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment as PropertyAccessorElementImpl;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    if (isGetter) {
      return GetterElementImpl(firstFragment);
    } else {
      return SetterElementImpl(firstFragment);
    }
  }

  set element(ExecutableElement2 element) => _element = element;

  @override
  Fragment? get enclosingFragment {
    var enclosing = enclosingElement3;
    if (enclosing is InstanceFragment) {
      return enclosing as InstanceFragment;
    } else if (enclosing is CompilationUnitElementImpl) {
      return enclosing as LibraryFragment;
    }
    throw UnsupportedError('Not a fragment: ${enclosing.runtimeType}');
  }

  @override
  String get identifier {
    String name = displayName;
    String suffix = isGetter ? "?" : "=";
    return considerCanonicalizeString("$name$suffix");
  }

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isGetter {
    return hasModifier(Modifier.GETTER);
  }

  /// Set whether this accessor is a getter.
  set isGetter(bool isGetter) {
    setModifier(Modifier.GETTER, isGetter);
  }

  @override
  bool get isSetter {
    return hasModifier(Modifier.SETTER);
  }

  /// Set whether this accessor is a setter.
  set isSetter(bool isSetter) {
    setModifier(Modifier.SETTER, isSetter);
  }

  @override
  ElementKind get kind {
    if (isGetter) {
      return ElementKind.GETTER;
    }
    return ElementKind.SETTER;
  }

  @override
  List<ElementAnnotationImpl> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name {
    if (isSetter) {
      return "${super.name}=";
    }
    return super.name;
  }

  @override
  ExecutableFragment? get nextFragment => augmentation;

  @override
  ExecutableFragment? get previousFragment => augmentationTarget;

  @Deprecated('Use variable2')
  @override
  PropertyInducingElementImpl get variable {
    return variable2!;
  }

  @override
  PropertyInducingElementImpl? get variable2 {
    linkedData?.read(this);
    return _variable;
  }

  set variable2(PropertyInducingElementImpl? value) {
    _variable = value;
  }

  @override
  PropertyInducingFragment? get variable3 => variable2;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitPropertyAccessorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(
      this,
      (isGetter ? 'get ' : 'set ') + displayName,
    );
  }
}

/// Implicit getter for a [PropertyInducingElementImpl].
// Pre-existing name.
// ignore: camel_case_types
class PropertyAccessorElementImpl_ImplicitGetter
    extends PropertyAccessorElementImpl {
  /// Create the implicit getter and bind it to the [property].
  PropertyAccessorElementImpl_ImplicitGetter(
      PropertyInducingElementImpl property,
      {Reference? reference})
      : super.forVariable(property, reference: reference) {
    property.getter = this;
    reference?.element = this;
  }

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element get enclosingElement => variable2.enclosingElement;

  @override
  Element get enclosingElement3 => variable2.enclosingElement3;

  @override
  bool get hasImplicitReturnType => variable2.hasImplicitType;

  @override
  bool get isGetter => true;

  @override
  Element get nonSynthetic {
    if (!variable2.isSynthetic) {
      return variable2;
    }
    assert(enclosingElement3 is EnumElementImpl);
    return enclosingElement3;
  }

  @override
  DartType get returnType => variable2.type;

  @override
  set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  Version? get sinceSdkVersion => variable2.sinceSdkVersion;

  @override
  FunctionType get type {
    return _type ??= FunctionTypeImpl(
      typeFormals: const <TypeParameterElement>[],
      parameters: const <ParameterElement>[],
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  set type(FunctionType type) {
    assert(false); // Should never be called.
  }

  @override
  PropertyInducingElementImpl get variable2 => super.variable2!;
}

/// Implicit setter for a [PropertyInducingElementImpl].
// Pre-existing name.
// ignore: camel_case_types
class PropertyAccessorElementImpl_ImplicitSetter
    extends PropertyAccessorElementImpl {
  /// Create the implicit setter and bind it to the [property].
  PropertyAccessorElementImpl_ImplicitSetter(
      PropertyInducingElementImpl property,
      {Reference? reference})
      : super.forVariable(property, reference: reference) {
    property.setter = this;
  }

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element get enclosingElement => variable2.enclosingElement;

  @override
  Element get enclosingElement3 => variable2.enclosingElement3;

  @override
  bool get isSetter => true;

  @override
  Element get nonSynthetic => variable2;

  @override
  List<ParameterElement> get parameters {
    if (_parameters.isNotEmpty) {
      return _parameters;
    }

    return _parameters = List.generate(
        1, (_) => ParameterElementImpl_ofImplicitSetter(this),
        growable: false);
  }

  @override
  DartType get returnType => VoidTypeImpl.instance;

  @override
  set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  Version? get sinceSdkVersion => variable2.sinceSdkVersion;

  @override
  FunctionType get type {
    return _type ??= FunctionTypeImpl(
      typeFormals: const <TypeParameterElement>[],
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  set type(FunctionType type) {
    assert(false); // Should never be called.
  }

  @override
  PropertyInducingElementImpl get variable2 => super.variable2!;
}

/// A concrete implementation of a [PropertyInducingElement].
abstract class PropertyInducingElementImpl
    extends NonParameterVariableElementImpl
    with MacroTargetElement
    implements PropertyInducingElement, PropertyInducingFragment {
  /// The getter associated with this element.
  @override
  PropertyAccessorElementImpl? getter;

  /// The setter associated with this element, or `null` if the element is
  /// effectively `final` and therefore does not have a setter associated with
  /// it.
  @override
  PropertyAccessorElementImpl? setter;

  /// This field is set during linking, and performs type inference for
  /// this property. After linking this field is always `null`.
  PropertyInducingElementTypeInference? typeInference;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError? typeInferenceError;

  @override
  ElementLinkedData? linkedData;

  /// Initialize a newly created synthetic element to have the given [name] and
  /// [offset].
  PropertyInducingElementImpl(super.name, super.offset) {
    setModifier(Modifier.SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE, true);
  }

  @override
  List<Fragment> get children3 => const [];

  @override
  Fragment? get enclosingFragment => enclosingElement3 as Fragment;

  @override
  GetterFragment? get getter2 => getter as GetterFragment?;

  /// Return `true` if this variable needs the setter.
  bool get hasSetter {
    if (isConst) {
      return false;
    }

    if (isLate) {
      return !isFinal || !hasInitializer;
    }

    return !isFinal;
  }

  @override
  bool get isConstantEvaluated => true;

  @override
  bool get isLate {
    return hasModifier(Modifier.LATE);
  }

  @override
  LibraryFragment get libraryFragment =>
      thisOrAncestorOfType<CompilationUnitElement>() as LibraryFragment;

  @override
  PropertyInducingFragment? get nextFragment =>
      augmentation as PropertyInducingFragment?;

  @override
  Element get nonSynthetic {
    if (isSynthetic) {
      if (enclosingElement3 is EnumElementImpl) {
        // TODO(scheglov): remove 'index'?
        if (name == 'index' || name == 'values') {
          return enclosingElement3;
        }
      }
      return (getter ?? setter)!;
    } else {
      return this;
    }
  }

  @override
  PropertyInducingFragment? get previousFragment =>
      augmentationTarget as PropertyInducingFragment?;

  // @override
  // bool get hasInitializer;

  @override
  SetterFragment? get setter2 => setter as SetterFragment?;

  bool get shouldUseTypeForInitializerInference {
    return hasModifier(Modifier.SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE);
  }

  set shouldUseTypeForInitializerInference(bool value) {
    setModifier(Modifier.SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE, value);
  }

  @override
  DartType get type {
    linkedData?.read(this);
    if (_type != null) return _type!;

    if (isSynthetic) {
      if (getter != null) {
        return _type = getter!.returnType;
      } else if (setter != null) {
        List<ParameterElement> parameters = setter!.parameters;
        return _type = parameters.isNotEmpty
            ? parameters[0].type
            : DynamicTypeImpl.instance;
      } else {
        return _type = DynamicTypeImpl.instance;
      }
    }

    // We must be linking, and the type has not been set yet.
    _type = typeInference!.perform();
    shouldUseTypeForInitializerInference = false;
    return _type!;
  }

  @override
  set type(DartType type) {
    super.type = type;
    // Reset cached types of synthetic getters and setters.
    // TODO(scheglov): Consider not caching these types.
    if (!isSynthetic) {
      var getter = this.getter;
      if (getter is PropertyAccessorElementImpl_ImplicitGetter) {
        getter._type = null;
      }
      var setter = this.setter;
      if (setter is PropertyAccessorElementImpl_ImplicitSetter) {
        setter._type = null;
      }
    }
  }

  void bindReference(Reference reference) {
    this.reference = reference;
    reference.element = this;
  }

  PropertyAccessorElementImpl createImplicitGetter(Reference reference) {
    assert(getter == null);
    return getter = PropertyAccessorElementImpl_ImplicitGetter(
      this,
      reference: reference,
    );
  }

  PropertyAccessorElementImpl createImplicitSetter(Reference reference) {
    assert(hasSetter);
    assert(setter == null);
    return setter = PropertyAccessorElementImpl_ImplicitSetter(
      this,
      reference: reference,
    );
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

abstract class PropertyInducingElementImpl2 extends VariableElementImpl2
    implements PropertyInducingElement2 {
  @override
  String get name;
}

/// Instances of this class are set for fields and top-level variables
/// to perform top-level type inference during linking.
abstract class PropertyInducingElementTypeInference {
  DartType perform();
}

class SetterElementImpl extends ExecutableElementImpl2
    with
        FragmentedExecutableElementMixin<SetterFragment>,
        FragmentedFunctionTypedElementMixin<SetterFragment>,
        FragmentedTypeParameterizedElementMixin<SetterFragment>,
        FragmentedAnnotatableElementMixin<SetterFragment>,
        FragmentedElementMixin<SetterFragment>
    implements SetterElement {
  @override
  final PropertyAccessorElementImpl firstFragment;

  SetterElementImpl(this.firstFragment) {
    PropertyAccessorElementImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as PropertyAccessorElementImpl?;
    }
  }

  @override
  SetterElement get baseElement => this;

  @override
  GetterElement? get correspondingGetter2 =>
      firstFragment.correspondingGetter2?.element as GetterElement?;

  @override
  String get displayName => name.substring(0, name.length - 1);

  @override
  Element2? get enclosingElement2 => firstFragment.enclosingFragment?.element;

  @override
  bool get isExternal => firstFragment.isExternal;

  @override
  ElementKind get kind => ElementKind.SETTER;

  @override
  String get name => firstFragment.name;

  @override
  PropertyInducingElement2? get variable3 => firstFragment.variable2?.element;
}

/// A concrete implementation of a [ShowElementCombinator].
class ShowElementCombinatorImpl implements ShowElementCombinator {
  @override
  List<String> shownNames = const [];

  @override
  int offset = 0;

  @override
  int end = -1;

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("show ");
    int count = shownNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      buffer.write(shownNames[i]);
    }
    return buffer.toString();
  }
}

class SuperFormalParameterElementImpl extends ParameterElementImpl
    implements SuperFormalParameterElement, SuperFormalParameterFragment {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  SuperFormalParameterElementImpl({
    required String super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  SuperFormalParameterElement2 get element =>
      super.element as SuperFormalParameterElement2;

  /// Super parameters are visible only in the initializer list scope,
  /// and introduce final variables.
  @override
  bool get isFinal => true;

  @override
  bool get isSuperFormal => true;

  @override
  ParameterElement? get superConstructorParameter {
    var enclosingElement = enclosingElement3;
    if (enclosingElement is ConstructorElementImpl) {
      var superConstructor = enclosingElement.superConstructor;
      if (superConstructor != null) {
        var superParameters = superConstructor.parameters;
        if (isNamed) {
          return superParameters
              .firstWhereOrNull((e) => e.isNamed && e.name == name);
        } else {
          var index = indexIn(enclosingElement);
          var positionalSuperParameters =
              superParameters.where((e) => e.isPositional).toList();
          if (index >= 0 && index < positionalSuperParameters.length) {
            return positionalSuperParameters[index];
          }
        }
      }
    }
    return null;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitSuperFormalParameterElement(this);

  /// Return the index of this super-formal parameter among other super-formals.
  int indexIn(ConstructorElementImpl enclosingElement) {
    return enclosingElement.parameters
        .whereType<SuperFormalParameterElementImpl>()
        .toList()
        .indexOf(this);
  }

  @override
  FormalParameterElement _createElement(
          FormalParameterFragment firstFragment) =>
      SuperFormalParameterElementImpl2(firstFragment as ParameterElementImpl);
}

class SuperFormalParameterElementImpl2 extends FormalParameterElementImpl
    implements SuperFormalParameterElement2 {
  SuperFormalParameterElementImpl2(super.firstFragment);

  @override
  FormalParameterElement? get superConstructorParameter2 =>
      ((firstFragment as SuperFormalParameterElementImpl)
              .superConstructorParameter as FormalParameterFragment?)
          ?.element;
}

class TopLevelFunctionElementImpl extends ExecutableElementImpl2
    with
        FragmentedExecutableElementMixin<TopLevelFunctionFragment>,
        FragmentedFunctionTypedElementMixin<TopLevelFunctionFragment>,
        FragmentedTypeParameterizedElementMixin<TopLevelFunctionFragment>,
        FragmentedAnnotatableElementMixin<TopLevelFunctionFragment>,
        FragmentedElementMixin<TopLevelFunctionFragment>
    implements TopLevelFunctionElement {
  @override
  final FunctionElementImpl firstFragment;

  TopLevelFunctionElementImpl(this.firstFragment) {
    FunctionElementImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as FunctionElementImpl?;
    }
  }

  @override
  TopLevelFunctionElement get baseElement => this;

  @override
  Element2? get enclosingElement2 => firstFragment._enclosingElement3?.library2;

  @override
  bool get isDartCoreIdentical => firstFragment.isDartCoreIdentical;

  @override
  bool get isEntryPoint => firstFragment.isEntryPoint;

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  String? get name => firstFragment.name;
}

/// A concrete implementation of a [TopLevelVariableElement].
class TopLevelVariableElementImpl extends PropertyInducingElementImpl
    with AugmentableElement<TopLevelVariableElementImpl>
    implements TopLevelVariableElement, TopLevelVariableFragment {
  /// The element corresponding to this fragment.
  TopLevelVariableElement2? _element;

  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  TopLevelVariableElementImpl(super.name, super.offset);

  @override
  TopLevelVariableElement get declaration => this;

  @override
  TopLevelVariableElement2 get element {
    if (_element != null) {
      return _element!;
    }
    TopLevelVariableFragment firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return TopLevelVariableElementImpl2(
        firstFragment as TopLevelVariableElementImpl);
  }

  set element(TopLevelVariableElement2 element) => _element = element;

  @override
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  @override
  bool get isStatic => true;

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  @override
  List<ElementAnnotationImpl> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  TopLevelVariableFragment? get nextFragment =>
      super.nextFragment as TopLevelVariableFragment?;

  @override
  TopLevelVariableFragment? get previousFragment =>
      super.previousFragment as TopLevelVariableFragment?;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTopLevelVariableElement(this);
}

class TopLevelVariableElementImpl2 extends PropertyInducingElementImpl2
    with
        FragmentedAnnotatableElementMixin<TopLevelVariableFragment>,
        FragmentedElementMixin<TopLevelVariableFragment>
    implements TopLevelVariableElement2 {
  @override
  final TopLevelVariableElementImpl firstFragment;

  TopLevelVariableElementImpl2(this.firstFragment) {
    TopLevelVariableElementImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as TopLevelVariableElementImpl?;
    }
  }

  @override
  TopLevelVariableElement2 get baseElement => this;

  @override
  LibraryElement2 get enclosingElement2 =>
      firstFragment.library as LibraryElement2;

  @override
  GetterElement? get getter2 =>
      firstFragment.getter2?.element as GetterElement?;

  @override
  bool get hasImplicitType => firstFragment.hasImplicitType;

  @override
  bool get isConst => firstFragment.isConst;

  @override
  bool get isExternal => firstFragment.isExternal;

  @override
  bool get isFinal => firstFragment.isFinal;

  @override
  bool get isLate => firstFragment.isLate;

  @override
  bool get isStatic => firstFragment.isStatic;

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  @override
  String get name => firstFragment.name;

  @override
  SetterElement? get setter2 =>
      firstFragment.setter2?.element as SetterElement?;

  @override
  DartType get type => firstFragment.type;

  @override
  DartObject? computeConstantValue() => firstFragment.computeConstantValue();
}

/// An element that represents [GenericTypeAlias].
///
/// Clients may not extend, implement or mix-in this class.
class TypeAliasElementImpl extends _ExistingElementImpl
    with
        TypeParameterizedElementMixin,
        AugmentableElement<TypeAliasElementImpl>,
        MacroTargetElement
    implements TypeAliasElement, TypeAliasFragment {
  /// Is `true` if the element has direct or indirect reference to itself
  /// from anywhere except a class element or type parameter bounds.
  bool hasSelfReference = false;

  bool isFunctionTypeAliasBased = false;

  @override
  ElementLinkedData? linkedData;

  ElementImpl? _aliasedElement;
  DartType? _aliasedType;

  /// The element corresponding to this fragment.
  TypeAliasElement2? _element;

  TypeAliasElementImpl(String super.name, super.nameOffset);

  @override
  ElementImpl? get aliasedElement {
    linkedData?.read(this);
    return _aliasedElement;
  }

  set aliasedElement(ElementImpl? aliasedElement) {
    _aliasedElement = aliasedElement;
    aliasedElement?.enclosingElement3 = this;
    aliasedElement?.enclosingElement = this;
  }

  @override
  DartType get aliasedType {
    linkedData?.read(this);
    return _aliasedType!;
  }

  set aliasedType(DartType rawType) {
    _aliasedType = rawType;
  }

  /// The aliased type, might be `null` if not yet linked.
  DartType? get aliasedTypeRaw => _aliasedType;

  @override
  String get displayName => name;

  @override
  TypeAliasElement2 get element {
    if (_element != null) {
      return _element!;
    }
    TypeAliasFragment firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return TypeAliasElementImpl2(firstFragment as TypeAliasElementImpl);
  }

  set element(TypeAliasElement2 element) => _element = element;

  @Deprecated('Use enclosingElement3 instead')
  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

  @override
  CompilationUnitElement get enclosingElement3 =>
      super.enclosingElement3 as CompilationUnitElement;

  @override
  LibraryFragment? get enclosingFragment =>
      enclosingElement3 as LibraryFragment;

  /// Returns whether this alias is a "proper rename" of [aliasedClass], as
  /// defined in the constructor-tearoffs specification.
  bool get isProperRename {
    var aliasedType_ = aliasedType;
    if (aliasedType_ is! InterfaceType) {
      return false;
    }
    var aliasedClass = aliasedType_.element;
    var typeArguments = aliasedType_.typeArguments;
    var typeParameterCount = typeParameters.length;
    if (typeParameterCount != aliasedClass.typeParameters.length) {
      return false;
    }
    for (var i = 0; i < typeParameterCount; i++) {
      var bound = typeParameters[i].bound ?? library.typeProvider.dynamicType;
      var aliasedBound = aliasedClass.typeParameters[i].bound ??
          library.typeProvider.dynamicType;
      if (!library.typeSystem.isSubtypeOf(bound, aliasedBound) ||
          !library.typeSystem.isSubtypeOf(aliasedBound, bound)) {
        return false;
      }
      var typeArgument = typeArguments[i];
      if (typeArgument is TypeParameterType &&
          typeParameters[i] != typeArgument.element) {
        return false;
      }
    }
    return true;
  }

  @override
  bool get isSimplyBounded {
    return hasModifier(Modifier.SIMPLY_BOUNDED);
  }

  set isSimplyBounded(bool isSimplyBounded) {
    setModifier(Modifier.SIMPLY_BOUNDED, isSimplyBounded);
  }

  @override
  ElementKind get kind {
    if (isNonFunctionTypeAliasesEnabled) {
      return ElementKind.TYPE_ALIAS;
    } else {
      return ElementKind.FUNCTION_TYPE_ALIAS;
    }
  }

  @override
  List<ElementAnnotationImpl> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name {
    return super.name!;
  }

  @override
  // TODO(augmentations): Support the fragment chain.
  TypeAliasFragment? get nextFragment => null;

  @override
  // TODO(augmentations): Support the fragment chain.
  TypeAliasFragment? get previousFragment => null;

  /// Instantiates this type alias with its type parameters as arguments.
  DartType get rawType {
    List<DartType> typeArguments;
    if (typeParameters.isNotEmpty) {
      typeArguments = typeParameters.map<DartType>((t) {
        return t.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }).toList();
    } else {
      typeArguments = const <DartType>[];
    }
    return instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitTypeAliasElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeAliasElement(this);
  }

  @override
  DartType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    if (hasSelfReference) {
      if (isNonFunctionTypeAliasesEnabled) {
        return DynamicTypeImpl.instance;
      } else {
        return _errorFunctionType(nullabilitySuffix);
      }
    }

    var substitution = Substitution.fromPairs(typeParameters, typeArguments);
    var type = substitution.substituteType(aliasedType);

    var resultNullability = type.nullabilitySuffix == NullabilitySuffix.question
        ? NullabilitySuffix.question
        : nullabilitySuffix;

    if (type is FunctionType) {
      return FunctionTypeImpl(
        typeFormals: type.typeFormals,
        parameters: type.parameters,
        returnType: type.returnType,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else if (type is InterfaceType) {
      return InterfaceTypeImpl(
        element: type.element,
        typeArguments: type.typeArguments,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else if (type is RecordTypeImpl) {
      return RecordTypeImpl(
        positionalFields: type.positionalFields,
        namedFields: type.namedFields,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else if (type is TypeParameterType) {
      return TypeParameterTypeImpl(
        element: type.element,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else {
      return (type as TypeImpl).withNullability(resultNullability);
    }
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }

  FunctionTypeImpl _errorFunctionType(NullabilitySuffix nullabilitySuffix) {
    return FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

class TypeAliasElementImpl2 extends TypeDefiningElementImpl2
    with
        FragmentedAnnotatableElementMixin<TypeAliasFragment>,
        FragmentedElementMixin<TypeAliasFragment>
    implements TypeAliasElement2 {
  @override
  final TypeAliasElementImpl firstFragment;

  TypeAliasElementImpl2(this.firstFragment) {
    TypeAliasElementImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as TypeAliasElementImpl?;
    }
  }

  @override
  Element2? get aliasedElement2 =>
      (firstFragment.aliasedElement as Fragment?)?.element;

  @override
  DartType get aliasedType => firstFragment.aliasedType;

  @override
  TypeAliasElementImpl2 get baseElement => this;

  @override
  LibraryElement2 get enclosingElement2 =>
      firstFragment.library as LibraryElement2;

  @override
  bool get isSimplyBounded => firstFragment.isSimplyBounded;

  @override
  ElementKind get kind => ElementKind.TYPE_ALIAS;

  @override
  String get name => firstFragment.name;

  @override
  List<TypeParameterElement2> get typeParameters2 =>
      firstFragment.typeParameters2
          .map((fragment) => fragment.element)
          .toList();

  @override
  DartType instantiate(
          {required List<DartType> typeArguments,
          required NullabilitySuffix nullabilitySuffix}) =>
      firstFragment.instantiate(
          typeArguments: typeArguments, nullabilitySuffix: nullabilitySuffix);
}

abstract class TypeDefiningElementImpl2 extends ElementImpl2
    implements TypeDefiningElement2 {}

/// A concrete implementation of a [TypeParameterElement].
class TypeParameterElementImpl extends ElementImpl
    implements TypeParameterElement, TypeParameterFragment {
  /// The default value of the type parameter. It is used to provide the
  /// corresponding missing type argument in type annotations and as the
  /// fall-back type value in type inference.
  DartType? defaultType;

  /// The type representing the bound associated with this parameter, or `null`
  /// if this parameter does not have an explicit bound.
  DartType? _bound;

  /// The value representing the variance modifier keyword, or `null` if
  /// there is no explicit variance modifier, meaning legacy covariance.
  shared.Variance? _variance;

  /// The element corresponding to this fragment.
  TypeParameterElementImpl2? _element;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  TypeParameterElementImpl(String super.name, super.offset);

  /// Initialize a newly created synthetic type parameter element to have the
  /// given [name], and with [synthetic] set to true.
  TypeParameterElementImpl.synthetic(String name) : super(name, -1) {
    isSynthetic = true;
  }

  @override
  DartType? get bound {
    return _bound;
  }

  set bound(DartType? bound) {
    _bound = bound;
    if (_element case var element?) {
      if (!identical(element.bound, bound)) {
        element.bound = bound;
      }
    }
  }

  @override
  List<Fragment> get children3 => const [];

  @override
  TypeParameterElement get declaration => this;

  @override
  String get displayName => name;

  @override
  TypeParameterElementImpl2 get element {
    if (_element != null) {
      return _element!;
    }
    TypeParameterFragment firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return TypeParameterElementImpl2(
      firstFragment: firstFragment as TypeParameterElementImpl,
      name: firstFragment.name,
      bound: firstFragment.bound,
    );
  }

  set element(TypeParameterElementImpl2 element) {
    _element = element;
  }

  @override
  Fragment? get enclosingFragment => enclosingElement3 as Fragment?;

  bool get isLegacyCovariant {
    return _variance == null;
  }

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @override
  LibraryFragment get libraryFragment =>
      thisOrAncestorOfType<CompilationUnitElementImpl>() as LibraryFragment;

  @override
  String get name {
    return super.name!;
  }

  @override
  // TODO(augmentations): Support chaining between the fragments.
  TypeParameterFragment? get nextFragment => null;

  @override
  // TODO(augmentations): Support chaining between the fragments.
  TypeParameterFragment? get previousFragment => null;

  shared.Variance get variance {
    return _variance ?? shared.Variance.covariant;
  }

  set variance(shared.Variance? newVariance) => _variance = newVariance;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is TypeParameterElement) {
      if (other.enclosingElement3 == null || enclosingElement3 == null) {
        return identical(other, this);
      }
      return other.location == location;
    }
    return false;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTypeParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeParameter(this);
  }

  /// Computes the variance of the [typeParameter] in the [type].
  shared.Variance computeVarianceInType(DartType type) {
    if (type is TypeParameterType) {
      if (type.element == this) {
        return shared.Variance.covariant;
      } else {
        return shared.Variance.unrelated;
      }
    } else if (type is InterfaceType) {
      var result = shared.Variance.unrelated;
      for (int i = 0; i < type.typeArguments.length; ++i) {
        var argument = type.typeArguments[i];
        var parameter = type.element.typeParameters[i];

        // TODO(kallentu): : Clean up TypeParameterElementImpl casting once
        // variance is added to the interface.
        var parameterVariance =
            (parameter as TypeParameterElementImpl).variance;
        result = result
            .meet(parameterVariance.combine(computeVarianceInType(argument)));
      }
      return result;
    } else if (type is FunctionType) {
      var result = computeVarianceInType(type.returnType);

      for (var parameter in type.typeFormals) {
        // If [parameter] is referenced in the bound at all, it makes the
        // variance of [parameter] in the entire type invariant.  The invocation
        // of [computeVariance] below is made to simply figure out if [variable]
        // occurs in the bound.
        var bound = parameter.bound;
        if (bound != null && !computeVarianceInType(bound).isUnrelated) {
          result = shared.Variance.invariant;
        }
      }

      for (var parameter in type.parameters) {
        result = result.meet(
          shared.Variance.contravariant.combine(
            computeVarianceInType(parameter.type),
          ),
        );
      }
      return result;
    }
    return shared.Variance.unrelated;
  }

  @override
  TypeParameterType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return TypeParameterTypeImpl(
      element: this,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

class TypeParameterElementImpl2 extends TypeDefiningElementImpl2
    with
        FragmentedAnnotatableElementMixin<TypeParameterFragment>,
        FragmentedElementMixin<TypeParameterFragment>
    implements TypeParameterElement2 {
  @override
  final TypeParameterElementImpl? firstFragment;

  @override
  final String name;

  DartType? _bound;

  /// When [firstFragment] is `null`, we still want to have some for the
  /// old element model.
  TypeParameterElementImpl? _syntheticFirstFragment;

  TypeParameterElementImpl2({
    required this.firstFragment,
    required this.name,
    required DartType? bound,
  }) : _bound = bound {
    var fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment as TypeParameterElementImpl?;
    }
  }

  @override
  TypeParameterElement2 get baseElement => this;

  @override
  DartType? get bound => _bound;

  set bound(DartType? value) {
    _bound = value;
    _syntheticFirstFragment?.bound = _bound;
  }

  @override
  Element2? get enclosingElement2 {
    if (firstFragment case var firstFragment?) {
      return (firstFragment._enclosingElement3 as Fragment).element;
    }
    return null;
  }

  TypeParameterElementImpl get firstFragmentOrSynthetic {
    return firstFragment ??
        (_syntheticFirstFragment ??= TypeParameterElementImpl(name, -1)
          ..isSynthetic = true
          ..bound = bound);
  }

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @override
  LibraryElement2 get library2 => super.library2!;

  @override
  TypeParameterType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return firstFragmentOrSynthetic.instantiate(
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

abstract class TypeParameterizedElementImpl2 extends ElementImpl2
    implements TypeParameterizedElement2 {}

/// Mixin representing an element which can have type parameters.
mixin TypeParameterizedElementMixin on ElementImpl
    implements
        _ExistingElementImpl,
        TypeParameterizedElement,
        TypeParameterizedFragment {
  List<TypeParameterElement> _typeParameters = const [];

  @override
  List<Fragment> get children3 => children.whereType<Fragment>().toList();

  @override
  bool get isSimplyBounded => true;

  @override
  LibraryFragment get libraryFragment => enclosingUnit;

  ElementLinkedData? get linkedData;

  @override
  List<TypeParameterElement> get typeParameters {
    linkedData?.read(this);
    return _typeParameters;
  }

  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (var typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement3 = this;
      typeParameter.enclosingElement = this;
    }
    _typeParameters = typeParameters;
  }

  @override
  List<TypeParameterFragment> get typeParameters2 =>
      typeParameters.cast<TypeParameterFragment>();

  List<TypeParameterElement> get typeParameters_unresolved {
    return _typeParameters;
  }
}

/// A concrete implementation of a [UriReferencedElement].
abstract class UriReferencedElementImpl extends _ExistingElementImpl
    implements UriReferencedElement {
  /// The offset of the URI in the file, or `-1` if this node is synthetic.
  int _uriOffset = -1;

  /// The offset of the character immediately following the last character of
  /// this node's URI, or `-1` if this node is synthetic.
  int _uriEnd = -1;

  /// The URI that is specified by this directive.
  String? _uri;

  /// Initialize a newly created import element to have the given [name] and
  /// [offset]. The offset may be `-1` if the element is synthetic.
  UriReferencedElementImpl(super.name, super.offset);

  /// Return the URI that is specified by this directive.
  @override
  String? get uri => _uri;

  /// Set the URI that is specified by this directive to be the given [uri].
  set uri(String? uri) {
    _uri = uri;
  }

  /// Return the offset of the character immediately following the last
  /// character of this node's URI, or `-1` if this node is synthetic.
  @override
  int get uriEnd => _uriEnd;

  /// Set the offset of the character immediately following the last character
  /// of this node's URI to the given [offset].
  set uriEnd(int offset) {
    _uriEnd = offset;
  }

  /// Return the offset of the URI in the file, or `-1` if this node is
  /// synthetic.
  @override
  int get uriOffset => _uriOffset;

  /// Set the offset of the URI in the file to the given [offset].
  set uriOffset(int offset) {
    _uriOffset = offset;
  }
}

/// A concrete implementation of a [VariableElement].
abstract class VariableElementImpl extends ElementImpl
    implements VariableElement {
  /// The type of this variable.
  DartType? _type;

  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  VariableElementImpl(super.name, super.offset);

  /// If this element represents a constant variable, and it has an initializer,
  /// a copy of the initializer for the constant.  Otherwise `null`.
  ///
  /// Note that in correct Dart code, all constant variables must have
  /// initializers.  However, analyzer also needs to handle incorrect Dart code,
  /// in which case there might be some constant variables that lack
  /// initializers.
  Expression? get constantInitializer => null;

  @override
  VariableElement get declaration => this;

  @override
  String get displayName => name;

  /// Return the result of evaluating this variable's initializer as a
  /// compile-time constant expression, or `null` if this variable is not a
  /// 'const' variable, if it does not have an initializer, or if the
  /// compilation unit containing the variable has not been resolved.
  Constant? get evaluationResult => null;

  /// Set the result of evaluating this variable's initializer as a compile-time
  /// constant expression to the given [result].
  set evaluationResult(Constant? result) {
    throw StateError("Invalid attempt to set a compile-time constant result");
  }

  @override
  bool get hasImplicitType {
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

  /// Set whether this variable element has an implicit type.
  set hasImplicitType(bool hasImplicitType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitType);
  }

  /// Set whether this variable is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  /// Set whether this variable is const.
  set isConst(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  @override
  bool get isConstantEvaluated => true;

  /// Set whether this variable is external.
  set isExternal(bool isExternal) {
    setModifier(Modifier.EXTERNAL, isExternal);
  }

  @override
  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  /// Set whether this variable is final.
  set isFinal(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  /// Set whether this variable is late.
  set isLate(bool isLate) {
    setModifier(Modifier.LATE, isLate);
  }

  @override
  bool get isStatic => hasModifier(Modifier.STATIC);

  set isStatic(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  String get name => super.name!;

  @override
  DartType get type => _type!;

  set type(DartType type) {
    _type = type;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }

  @override
  DartObject? computeConstantValue() => null;
}

abstract class VariableElementImpl2 extends ElementImpl2
    implements VariableElement2 {}

mixin WrappedElementMixin implements ElementImpl2 {
  @override
  bool get isSynthetic => _wrappedElement.isSynthetic;

  @override
  ElementKind get kind => _wrappedElement.kind;

  @override
  LibraryElement2? get library2 => _wrappedElement.library2;

  @override
  String get name => _wrappedElement.name!;

  ElementImpl get _wrappedElement;

  @override
  String displayString2(
          {bool multiline = false, bool preferTypeAlias = false}) =>
      _wrappedElement.displayString2(
          multiline: multiline, preferTypeAlias: preferTypeAlias);
}

abstract class _ExistingElementImpl extends ElementImpl with _HasLibraryMixin {
  _ExistingElementImpl(super.name, super.offset, {super.reference});
}

/// An element that can be declared in multiple fragments.
abstract class _Fragmented<E extends Fragment> {
  E? get firstFragment;
}

mixin _HasLibraryMixin on ElementImpl {
  @override
  LibraryElementImpl get library => thisOrAncestorOfType()!;

  @override
  Source get librarySource => library.source;

  @override
  Source get source => enclosingElement3!.source!;
}

/// Instances of [List]s that are used as "not yet computed" values, they
/// must be not `null`, and not identical to `const <T>[]`.
class _Sentinel {
  static final List<ConstructorElementImpl> constructorElement =
      List.unmodifiable([]);
  static final List<FieldElementImpl> fieldElement = List.unmodifiable([]);
  static final List<LibraryExportElementImpl> libraryExportElement =
      List.unmodifiable([]);
  static final List<LibraryImportElementImpl> libraryImportElement =
      List.unmodifiable([]);
  static final List<MethodElementImpl> methodElement = List.unmodifiable([]);
  static final List<PropertyAccessorElementImpl> propertyAccessorElement =
      List.unmodifiable([]);
}

extension on Fragment {
  String? get documentationCommentOrNull {
    // TODO(brianwilkerson): I think that all fragments are annotatable. If
    //  that's true then this getter isn't necessary and should be removed.
    return switch (this) {
      LibraryFragment(:var documentationComment) => documentationComment,
      TypeDefiningFragment(:var documentationComment) => documentationComment,
      TypeParameterizedFragment(:var documentationComment) =>
        documentationComment,
      FormalParameterFragment(:var documentationComment) =>
        documentationComment,
      _ => null,
    };
  }

  List<ElementAnnotation> get metadataOrEmpty {
    // TODO(brianwilkerson): I think that all fragments are annotatable. If
    //  that's true then this getter isn't necessary and should be removed.
    return switch (this) {
      LibraryFragment(:var metadata) => metadata,
      PropertyInducingFragment(:var metadata) => metadata,
      TypeDefiningFragment(:var metadata) => metadata,
      TypeParameterizedFragment(:var metadata) => metadata,
      FormalParameterFragment(:var metadata) => metadata,
      _ => const [],
    };
  }
}
