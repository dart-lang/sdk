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
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
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

class AugmentationImportElementImpl extends _ExistingElementImpl
    implements AugmentationImportElement {
  @override
  final int importKeywordOffset;

  @override
  final DirectiveUri uri;

  AugmentationImportElementImpl({
    required this.importKeywordOffset,
    required this.uri,
  }) : super(null, importKeywordOffset);

  @override
  LibraryOrAugmentationElementImpl get enclosingElement {
    return super.enclosingElement as LibraryOrAugmentationElementImpl;
  }

  @override
  LibraryAugmentationElementImpl? get importedAugmentation {
    var uri = this.uri;
    if (uri is DirectiveUriWithAugmentationImpl) {
      return uri.augmentation;
    }
    return null;
  }

  @override
  ElementKind get kind => ElementKind.AUGMENTATION_IMPORT;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitAugmentationImportElement(this);
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

  BindPatternVariableElementImpl(this.node, super.name, super.offset);
}

/// An [InterfaceElementImpl] which is a class.
class ClassElementImpl extends ClassOrMixinElementImpl
    with AugmentableElement<ClassElementImpl>
    implements ClassElement {
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

  @override
  set constructors(List<ConstructorElementImpl> constructors) {
    assert(!isMixinApplication);
    super.constructors = constructors;
  }

  @override
  set fields(List<FieldElementImpl> fields) {
    assert(!isMixinApplication);
    super.fields = fields;
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
    var definingClass = method?.enclosingElement as ClassElement?;
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

/// A concrete implementation of a [CompilationUnitElement].
class CompilationUnitElementImpl extends UriReferencedElementImpl
    implements CompilationUnitElement {
  /// The source that corresponds to this compilation unit.
  @override
  final Source source;

  @override
  LineInfo lineInfo;

  /// The source of the library containing this compilation unit.
  ///
  /// This is the same as the source of the containing [LibraryElement],
  /// except that it does not require the containing [LibraryElement] to be
  /// computed.
  @override
  final Source librarySource;

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

  ElementLinkedData? linkedData;

  /// Initialize a newly created compilation unit element to have the given
  /// [name].
  CompilationUnitElementImpl({
    required this.source,
    required this.librarySource,
    required this.lineInfo,
  }) : super(null, -1);

  @override
  List<PropertyAccessorElementImpl> get accessors {
    return _accessors;
  }

  /// Set the top-level accessors (getters and setters) contained in this
  /// compilation unit to the given [accessors].
  set accessors(List<PropertyAccessorElementImpl> accessors) {
    for (var accessor in accessors) {
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
  List<ClassElementImpl> get classes {
    return _classes;
  }

  /// Set the classes contained in this compilation unit to [classes].
  set classes(List<ClassElementImpl> classes) {
    for (var class_ in classes) {
      class_.enclosingElement = this;
    }
    _classes = classes;
  }

  @override
  LibraryOrAugmentationElement get enclosingElement =>
      super.enclosingElement as LibraryOrAugmentationElement;

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
      element.enclosingElement = this;
    }
    _enums = enums;
  }

  @override
  List<ExtensionElementImpl> get extensions {
    return _extensions;
  }

  /// Set the extensions contained in this compilation unit to the given
  /// [extensions].
  set extensions(List<ExtensionElementImpl> extensions) {
    for (var extension in extensions) {
      extension.enclosingElement = this;
    }
    _extensions = extensions;
  }

  @override
  List<ExtensionTypeElementImpl> get extensionTypes {
    return _extensionTypes;
  }

  set extensionTypes(List<ExtensionTypeElementImpl> elements) {
    for (var element in elements) {
      element.enclosingElement = this;
    }
    _extensionTypes = elements;
  }

  @override
  List<FunctionElementImpl> get functions {
    return _functions;
  }

  /// Set the top-level functions contained in this compilation unit to the
  ///  given[functions].
  set functions(List<FunctionElementImpl> functions) {
    for (var function in functions) {
      function.enclosingElement = this;
    }
    _functions = functions;
  }

  @override
  int get hashCode => source.hashCode;

  @override
  String get identifier => '${source.uri}';

  @override
  ElementKind get kind => ElementKind.COMPILATION_UNIT;

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
      mixin_.enclosingElement = this;
    }
    _mixins = mixins;
  }

  @override
  AnalysisSession get session => enclosingElement.session;

  @override
  List<TopLevelVariableElementImpl> get topLevelVariables {
    return _variables;
  }

  /// Set the top-level variables contained in this compilation unit to the
  ///  given[variables].
  set topLevelVariables(List<TopLevelVariableElementImpl> variables) {
    for (var variable in variables) {
      variable.enclosingElement = this;
    }
    _variables = variables;
  }

  @override
  List<TypeAliasElementImpl> get typeAliases {
    return _typeAliases;
  }

  /// Set the type aliases contained in this compilation unit to [typeAliases].
  set typeAliases(List<TypeAliasElementImpl> typeAliases) {
    for (var typeAlias in typeAliases) {
      typeAlias.enclosingElement = this;
    }
    _typeAliases = typeAliases;
  }

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
    implements ConstructorElement {
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
    var className = enclosingElement.name;
    var name = this.name;
    if (name.isNotEmpty) {
      return '$className.$name';
    } else {
      return className;
    }
  }

  @override
  InterfaceElement get enclosingElement =>
      super.enclosingElement as InterfaceElementImpl;

  @override
  bool get hasLiteral {
    if (super.hasLiteral) return true;
    var enclosingElement = this.enclosingElement;
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
  Element get nonSynthetic {
    return isSynthetic ? enclosingElement : this;
  }

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

    var augmentedDeclaration = enclosingElement.augmented.declaration;
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
          '[enclosingElement: $enclosingElement]'
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

class DirectiveUriWithAugmentationImpl extends DirectiveUriWithSourceImpl
    implements DirectiveUriWithAugmentation {
  @override
  late LibraryAugmentationElementImpl augmentation;

  DirectiveUriWithAugmentationImpl({
    required super.relativeUriString,
    required super.relativeUri,
    required super.source,
    required this.augmentation,
  });
}

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
  bool get isAlwaysThrows => _isPackageMetaGetter(_alwaysThrowsVariableName);

  @override
  bool get isConstantEvaluated => evaluationResult != null;

  bool get isDartInternalSince {
    var element = this.element;
    if (element is ConstructorElement) {
      return element.enclosingElement.name == 'Since' &&
          element.library.source.uri.toString() == 'dart:_internal';
    }
    return false;
  }

  @override
  bool get isDeprecated {
    var element = this.element;
    if (element is ConstructorElement) {
      return element.library.isDartCore &&
          element.enclosingElement.name == _deprecatedClassName;
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
        element.enclosingElement.name == className &&
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

/// A base class for concrete implementations of an [Element].
abstract class ElementImpl implements Element {
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
  List<Element> get children => const [];

  /// The length of the element's code, or `null` if the element is synthetic.
  int? get codeLength => _codeLength;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int? get codeOffset => _codeOffset;

  @override
  AnalysisContext get context {
    return _enclosingElement!.context;
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

  @override
  Element? get enclosingElement => _enclosingElement;

  /// Set the enclosing element of this element to the given [element].
  set enclosingElement(Element? element) {
    _enclosingElement = element as ElementImpl?;
  }

  /// Return the enclosing unit element (which might be the same as `this`), or
  /// `null` if this element is not contained in any compilation unit.
  CompilationUnitElementImpl get enclosingUnit {
    return _enclosingElement!.enclosingUnit;
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
  AnalysisSession? get session {
    return enclosingElement?.session;
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
    return enclosingElement?.source;
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

  /// Set this element as the enclosing element for given [element].
  void encloseElement(ElementImpl element) {
    element.enclosingElement = this;
  }

  /// Set this element as the enclosing element for given [elements].
  void encloseElements(List<Element> elements) {
    for (Element element in elements) {
      (element as ElementImpl)._enclosingElement = this;
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
      element = element.enclosingElement;
    }
    return element as E?;
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    Element element = this;
    while (element is! E) {
      var ancestor = element.enclosingElement;
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
      ancestor = ancestor.enclosingElement;
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
    implements EnumElement {
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

  List<FieldElementImpl> get constants {
    return fields.where((field) => field.isEnumConstant).toList();
  }

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
    implements ExecutableElement {
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

  @override
  Element get enclosingElement => super.enclosingElement!;

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
      (parameter as ParameterElementImpl).enclosingElement = this;
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

/// A concrete implementation of an [ExtensionElement].
class ExtensionElementImpl extends InstanceElementImpl
    with AugmentableElement<ExtensionElementImpl>
    implements ExtensionElement {
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
    int length = accessors.length;
    for (int i = 0; i < length; i++) {
      PropertyAccessorElement accessor = accessors[i];
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement? getMethod(String methodName) {
    int length = methods.length;
    for (int i = 0; i < length; i++) {
      MethodElement method = methods[i];
      if (method.name == methodName) {
        return method;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getSetter(String setterName) {
    return InterfaceElementImpl.getSetterFromAccessors(setterName, accessors);
  }
}

class ExtensionTypeElementImpl extends InterfaceElementImpl
    with AugmentableElement<ExtensionTypeElementImpl>
    implements ExtensionTypeElement {
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

  @override
  ElementKind get kind {
    return ElementKind.EXTENSION_TYPE;
  }

  @override
  ConstructorElementImpl get primaryConstructor {
    return augmented.primaryConstructor;
  }

  @override
  FieldElementImpl get representation {
    return augmented.representation;
  }

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
    implements FieldElement {
  /// True if this field inherits from a covariant parameter. This happens
  /// when it overrides a field in a supertype that is covariant.
  bool inheritsCovariant = false;

  /// Initialize a newly created synthetic field element to have the given
  /// [name] at the given [offset].
  FieldElementImpl(super.name, super.offset);

  @override
  FieldElement get declaration => this;

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
    return enclosingElement is EnumElementImpl &&
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
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);
}

/// A [ParameterElementImpl] that has the additional information of the
/// [FieldElement] associated with the parameter.
class FieldFormalParameterElementImpl extends ParameterElementImpl
    implements FieldFormalParameterElement {
  @override
  FieldElement? field;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  FieldFormalParameterElementImpl({
    required String super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

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
}

/// A concrete implementation of a [FunctionElement].
class FunctionElementImpl extends ExecutableElementImpl
    with AugmentableElement<FunctionElementImpl>
    implements FunctionElement, FunctionTypedElementImpl {
  /// Initialize a newly created function element to have the given [name] and
  /// [offset].
  FunctionElementImpl(super.name, super.offset);

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  FunctionElementImpl.forOffset(int nameOffset) : super("", nameOffset);

  @override
  ExecutableElement get declaration => this;

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
  bool get _includeNameOffsetInIdentifier {
    return super._includeNameOffsetInIdentifier ||
        enclosingElement is ExecutableElement ||
        enclosingElement is VariableElement;
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
  String get identifier => '-';

  @override
  ElementKind get kind => ElementKind.GENERIC_FUNCTION_TYPE;

  @override
  ElementLinkedData<ElementImpl>? get linkedData => null;

  @override
  List<ParameterElement> get parameters {
    return _parameters;
  }

  /// Set the parameters defined by this function type element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

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
    implements InstanceElement {
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
      accessor.enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  InstanceElementImpl? get augmentation;

  @override
  InstanceElementImpl? get augmentationTarget;

  @override
  CompilationUnitElementImpl get enclosingElement {
    return super.enclosingElement as CompilationUnitElementImpl;
  }

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
      field.enclosingElement = this;
    }
    _fields = fields;
  }

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
      method.enclosingElement = this;
    }
    _methods = methods;
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

abstract class InterfaceElementImpl extends InstanceElementImpl
    implements InterfaceElement {
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
      constructor.enclosingElement = this;
    }
    _constructors = constructors;
  }

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
        getter.enclosingElement != this);
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
        method.enclosingElement != this);
  }

  @override
  PropertyAccessorElement? lookUpInheritedConcreteSetter(
      String setterName, LibraryElement library) {
    return _implementationsOfSetter(setterName).firstWhereOrNull((setter) =>
        !setter.isAbstract &&
        !setter.isStatic &&
        setter.isAccessibleIn(library) &&
        setter.enclosingElement != this);
  }

  @override
  MethodElement? lookUpInheritedMethod(
      String methodName, LibraryElement library) {
    return _implementationsOfMethod(methodName).firstWhereOrNull((method) =>
        !method.isStatic &&
        method.isAccessibleIn(library) &&
        method.enclosingElement != this);
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

/// A concrete implementation of a [LabelElement].
class LabelElementImpl extends ElementImpl implements LabelElement {
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

  @override
  ExecutableElement get enclosingElement =>
      super.enclosingElement as ExecutableElement;

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

class LibraryAugmentationElementImpl extends LibraryOrAugmentationElementImpl
    implements LibraryAugmentationElement {
  @override
  final LibraryOrAugmentationElementImpl augmentationTarget;

  MacroGeneratedAugmentationLibrary? macroGenerated;

  LibraryAugmentationElementLinkedData? linkedData;

  LibraryAugmentationElementImpl({
    required this.augmentationTarget,
    required super.nameOffset,
  }) : super(name: null);

  @override
  // TODO(scheglov): implement accessibleExtensions
  List<ExtensionElement> get accessibleExtensions => throw UnimplementedError();

  @override
  List<AugmentationImportElementImpl> get augmentationImports {
    _readLinkedData();
    return super.augmentationImports;
  }

  @override
  FeatureSet get featureSet => augmentationTarget.featureSet;

  @Deprecated('Only non-nullable by default mode is supported')
  @override
  bool get isNonNullableByDefault => augmentationTarget.isNonNullableByDefault;

  @override
  ElementKind get kind => ElementKind.LIBRARY_AUGMENTATION;

  @override
  LibraryLanguageVersion get languageVersion {
    return augmentationTarget.languageVersion;
  }

  @override
  LibraryElementImpl get library => augmentationTarget.library;

  @override
  List<LibraryExportElementImpl> get libraryExports {
    return _libraryExports;
  }

  @override
  List<LibraryImportElementImpl> get libraryImports {
    _readLinkedData();
    return _libraryImports;
  }

  @override
  Source get librarySource => library.source;

  @override
  AnalysisSessionImpl get session => augmentationTarget.session;

  @override
  TypeProvider get typeProvider => augmentationTarget.typeProvider;

  @override
  TypeSystem get typeSystem => augmentationTarget.typeSystem;

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitLibraryAugmentationElement(this);
  }

  @override
  void _readLinkedData() {
    augmentationTarget._readLinkedData();
  }
}

/// A concrete implementation of a [LibraryElement].
class LibraryElementImpl extends LibraryOrAugmentationElementImpl
    with _HasLibraryMixin, MacroTargetElement
    implements LibraryElement {
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

  /// The list of `part` directives of this library.
  List<PartElementImpl> _parts = const <PartElementImpl>[];

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

  /// The cache for [augmentations].
  List<LibraryAugmentationElementImpl>? _augmentations;

  /// Initialize a newly created library element in the given [context] to have
  /// the given [name] and [offset].
  LibraryElementImpl(this.context, this.session, String name, int offset,
      this.nameLength, this.featureSet)
      : linkedData = null,
        super(name: name, nameOffset: offset);

  @override
  List<ExtensionElement> get accessibleExtensions => scope.extensions;

  @override
  List<AugmentationImportElementImpl> get augmentationImports {
    _readLinkedData();
    return super.augmentationImports;
  }

  @override
  set augmentationImports(List<AugmentationImportElementImpl> imports) {
    super.augmentationImports = imports;
    _augmentations = null;
  }

  /// All augmentations of this library, in the depth-first pre-order order.
  List<LibraryAugmentationElementImpl> get augmentations {
    return _augmentations ??= _computeAugmentations();
  }

  @override
  List<Element> get children => [
        ...super.children,
        ...parts,
        ..._partUnits,
      ];

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return _definingCompilationUnit;
  }

  @override
  FunctionElement? get entryPoint {
    _readLinkedData();
    return _entryPoint;
  }

  set entryPoint(FunctionElement? entryPoint) {
    _entryPoint = entryPoint;
  }

  @override
  List<LibraryElementImpl> get exportedLibraries {
    return libraryExports
        .map((import) => import.exportedLibrary)
        .nonNulls
        .toSet()
        .toList();
  }

  @override
  Namespace get exportNamespace {
    linkedData?.read(this);
    return _exportNamespace ??= Namespace({});
  }

  set exportNamespace(Namespace exportNamespace) {
    _exportNamespace = exportNamespace;
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
    _readLinkedData();
    return _fieldNameNonPromotabilityInfo!;
  }

  set fieldNameNonPromotabilityInfo(
      Map<String, FieldNameNonPromotabilityInfo>? value) {
    _fieldNameNonPromotabilityInfo = value;
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
    return libraryImports
        .map((import) => import.importedLibrary)
        .nonNulls
        .toSet()
        .toList();
  }

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
  List<LibraryExportElementImpl> get libraryExports {
    _readLinkedData();
    return _libraryExports;
  }

  @override
  List<LibraryImportElementImpl> get libraryImports {
    _readLinkedData();
    return _libraryImports;
  }

  @override
  FunctionElement get loadLibraryFunction {
    return _loadLibraryFunction;
  }

  @override
  List<ElementAnnotationImpl> get metadata {
    _readLinkedData();
    return super.metadata;
  }

  @override
  String get name => super.name!;

  @override
  List<PartElementImpl> get parts => _parts;

  set parts(List<PartElementImpl> parts) {
    for (var part in parts) {
      part.enclosingElement = this;
      var uri = part.uri;
      if (uri is DirectiveUriWithUnitImpl) {
        uri.unit.enclosingElement = this;
      }
    }
    _parts = parts;
  }

  @override
  List<PrefixElementImpl> get prefixes =>
      _prefixes ??= buildPrefixesFromImports(libraryImports);

  @override
  Namespace get publicNamespace {
    return _publicNamespace ??=
        NamespaceBuilder().createPublicNamespaceForLibrary(this);
  }

  set publicNamespace(Namespace publicNamespace) {
    _publicNamespace = publicNamespace;
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
  List<CompilationUnitElementImpl> get units {
    return [
      _definingCompilationUnit,
      ..._partUnits,
      ...augmentations.map((e) => e.definingCompilationUnit),
    ];
  }

  List<CompilationUnitElementImpl> get _partUnits {
    return parts
        .map((e) => e.uri)
        .whereType<DirectiveUriWithUnitImpl>()
        .map((e) => e.unit)
        .toList();
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
    for (var importElement in libraryImports) {
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

    if (prefix == null && name.startsWith(r'_$')) {
      for (var augmentation in augmentationImports) {
        var uri = augmentation.uri;
        if (uri is DirectiveUriWithSource &&
            uri is! DirectiveUriWithAugmentation &&
            file_paths.isGenerated(uri.relativeUriString)) {
          return true;
        }
      }
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

  List<LibraryAugmentationElementImpl> _computeAugmentations() {
    var result = <LibraryAugmentationElementImpl>[];

    void visitAugmentations(LibraryOrAugmentationElementImpl container) {
      if (container is LibraryAugmentationElementImpl) {
        result.add(container);
      }
      for (var import in container.augmentationImports) {
        var augmentation = import.importedAugmentation;
        if (augmentation != null) {
          visitAugmentations(augmentation);
        }
      }
    }

    visitAugmentations(this);
    return result.toFixedList();
  }

  @override
  void _readLinkedData() {
    linkedData?.read(this);
  }

  static List<PrefixElementImpl> buildPrefixesFromImports(
      List<LibraryImportElementImpl> imports) {
    var prefixes = HashSet<PrefixElementImpl>();
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
    implements LibraryExportElement {
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
    implements LibraryImportElement {
  @override
  final List<NamespaceCombinator> combinators;

  @override
  final int importKeywordOffset;

  @override
  final ImportElementPrefixImpl? prefix;

  @override
  final DirectiveUri uri;

  Namespace? _namespace;

  LibraryImportElementImpl({
    required this.combinators,
    required this.importKeywordOffset,
    required this.prefix,
    required this.uri,
  }) : super(null, importKeywordOffset);

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
  ElementKind get kind => ElementKind.IMPORT;

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

  List<AugmentationImportElementImpl> _augmentationImports =
      _Sentinel.augmentationImportElement;

  /// A list containing specifications of all of the imports defined in this
  /// library.
  List<LibraryExportElementImpl> _libraryExports =
      _Sentinel.libraryExportElement;

  /// A list containing specifications of all of the imports defined in this
  /// library.
  List<LibraryImportElementImpl> _libraryImports =
      _Sentinel.libraryImportElement;

  /// The cached list of prefixes.
  List<PrefixElementImpl>? _prefixes;

  /// The scope of this library, `null` if it has not been created yet.
  LibraryOrAugmentationScope? _scope;

  LibraryOrAugmentationElementImpl({
    required String? name,
    required int nameOffset,
  }) : super(name, nameOffset);

  @override
  List<AugmentationImportElementImpl> get augmentationImports {
    return _augmentationImports;
  }

  set augmentationImports(List<AugmentationImportElementImpl> imports) {
    for (var importElement in imports) {
      importElement.enclosingElement = this;
      importElement.importedAugmentation?.enclosingElement = this;
    }
    _augmentationImports = imports;
  }

  @override
  List<Element> get children => [
        ...super.children,
        definingCompilationUnit,
        ...libraryExports,
        ...libraryImports,
        ...augmentationImports,
      ];

  @override
  CompilationUnitElementImpl get definingCompilationUnit =>
      _definingCompilationUnit;

  /// Set the compilation unit that defines this library to the given
  ///  compilation[unit].
  set definingCompilationUnit(CompilationUnitElement unit) {
    assert((unit as CompilationUnitElementImpl).librarySource == unit.source);
    (unit as CompilationUnitElementImpl).enclosingElement = this;
    _definingCompilationUnit = unit;
  }

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return _definingCompilationUnit;
  }

  List<LibraryExportElementImpl> get exports_unresolved {
    return _libraryExports;
  }

  @override
  String get identifier => '${_definingCompilationUnit.source.uri}';

  List<LibraryImportElementImpl> get imports_unresolved {
    return _libraryImports;
  }

  @override
  LibraryElementImpl get library;

  @override
  List<LibraryExportElementImpl> get libraryExports {
    _readLinkedData();
    return _libraryExports;
  }

  /// Set the specifications of all of the exports defined in this library to
  /// the given list of [exports].
  set libraryExports(List<LibraryExportElementImpl> exports) {
    for (var exportElement in exports) {
      exportElement.enclosingElement = this;
    }
    _libraryExports = exports;
  }

  @override
  List<LibraryImportElementImpl> get libraryImports;

  /// Set the specifications of all of the imports defined in this library to
  /// the given list of [imports].
  set libraryImports(List<LibraryImportElementImpl> imports) {
    for (var importElement in imports) {
      importElement.enclosingElement = this;
    }
    _libraryImports = imports;
    _prefixes = null;
  }

  @override
  List<PrefixElementImpl> get prefixes =>
      _prefixes ??= buildPrefixesFromImports(libraryImports);

  @override
  LibraryOrAugmentationScope get scope {
    return _scope ??= LibraryOrAugmentationScope(this);
  }

  @override
  AnalysisSessionImpl get session;

  @override
  Source get source {
    return _definingCompilationUnit.source;
  }

  void resetScope() {
    _scope = null;
  }

  void _readLinkedData();

  static List<PrefixElementImpl> buildPrefixesFromImports(
      List<LibraryImportElementImpl> imports) {
    var prefixes = HashSet<PrefixElementImpl>();
    for (var import in imports) {
      var prefix = import.prefix;
      if (prefix != null) {
        prefixes.add(prefix.element);
      }
    }
    return prefixes.toList(growable: false);
  }
}

/// A concrete implementation of a [LocalVariableElement].
class LocalVariableElementImpl extends NonParameterVariableElementImpl
    implements LocalVariableElement {
  @override
  late bool hasInitializer;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  LocalVariableElementImpl(super.name, super.offset);

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

/// Additional information for a macro generated augmentation library.
class MacroGeneratedAugmentationLibrary {
  final String code;
  final Uint8List informativeBytes;

  MacroGeneratedAugmentationLibrary({
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
    implements AugmentedClassElement {
  @override
  ClassElementImpl get declaration;
}

mixin MaybeAugmentedEnumElementMixin on MaybeAugmentedInterfaceElementMixin
    implements AugmentedEnumElement {
  @override
  List<FieldElement> get constants {
    return fields.where((field) => field.isEnumConstant).toList();
  }

  @override
  EnumElementImpl get declaration;
}

mixin MaybeAugmentedExtensionElementMixin on MaybeAugmentedInstanceElementMixin
    implements AugmentedExtensionElement {
  @override
  DartType extendedType = InvalidTypeImpl.instance;

  @override
  ExtensionElementImpl get declaration;

  @override
  DartType get thisType => extendedType;
}

mixin MaybeAugmentedExtensionTypeElementMixin
    on MaybeAugmentedInterfaceElementMixin
    implements AugmentedExtensionTypeElement {
  @override
  late ConstructorElementImpl primaryConstructor;

  @override
  late FieldElementImpl representation;

  @override
  late DartType typeErasure;

  @override
  ExtensionTypeElementImpl get declaration;
}

mixin MaybeAugmentedInstanceElementMixin implements AugmentedInstanceElement {
  @override
  List<PropertyAccessorElement> get accessors;

  @override
  InstanceElementImpl get declaration;

  @override
  List<FieldElement> get fields;

  @override
  List<MethodElement> get methods;

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
    implements AugmentedInterfaceElement {
  InterfaceType? _thisType;

  @override
  InterfaceElementImpl get declaration;

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
  ConstructorElement? getNamedConstructor(String name) {
    name = name.ifEqualThen('new', '');
    return constructors.firstWhereOrNull((element) => element.name == name);
  }
}

mixin MaybeAugmentedMixinElementMixin on MaybeAugmentedInterfaceElementMixin
    implements AugmentedMixinElement {
  @override
  MixinElementImpl get declaration;
}

/// A concrete implementation of a [MethodElement].
class MethodElementImpl extends ExecutableElementImpl
    with AugmentableElement<MethodElementImpl>
    implements MethodElement {
  /// Is `true` if this method is `operator==`, and there is no explicit
  /// type specified for its formal parameter, in this method or in any
  /// overridden methods other than the one declared in `Object`.
  bool isOperatorEqualWithParameterTypeFromObject = false;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError? typeInferenceError;

  /// If this method is a synthetic element which is based on another method
  /// with some modifications (such as making some parameters covariant),
  /// this field contains the base method.
  MethodElement? prototype;

  /// Initialize a newly created method element to have the given [name] at the
  /// given [offset].
  MethodElementImpl(super.name, super.offset);

  @override
  MethodElement get declaration => prototype ?? this;

  @override
  String get displayName {
    String displayName = super.displayName;
    if ("unary-" == displayName) {
      return "-";
    }
    return displayName;
  }

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
  Element get nonSynthetic {
    if (isSynthetic && enclosingElement is EnumElementImpl) {
      return enclosingElement;
    }
    return this;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);
}

/// A [ClassElementImpl] representing a mixin declaration.
class MixinElementImpl extends ClassOrMixinElementImpl
    with AugmentableElement<MixinElementImpl>
    implements MixinElement {
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
class MultiplyDefinedElementImpl implements MultiplyDefinedElement {
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
  List<Element> get children => const [];

  @override
  Element? get declaration => null;

  @override
  String get displayName => name;

  @override
  String? get documentationComment => null;

  @override
  Element? get enclosingElement => null;

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
  Version? get sinceSdkVersion => null;

  @override
  Source? get source => null;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitMultiplyDefinedElement(this);

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
  E? thisOrAncestorMatching<E extends Element>(
    bool Function(Element) predicate,
  ) {
    return null;
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() => null;

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

  @override
  Element get enclosingElement => super.enclosingElement!;

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
    implements ParameterElement {
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
  ParameterElement get declaration => this;

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
  List<ParameterElement> get parameters {
    return _parameters;
  }

  /// Set the parameters defined by this executable element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  @override
  List<TypeParameterElement> get typeParameters {
    return _typeParameters;
  }

  /// Set the type parameters defined by this parameter element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
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

class PartElementImpl extends _ExistingElementImpl implements PartElement {
  @override
  final DirectiveUri uri;

  PartElementImpl({
    required this.uri,
  }) : super(null, -1);

  @override
  CompilationUnitElementImpl get enclosingUnit {
    var enclosingLibrary = enclosingElement as LibraryElementImpl;
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

/// A concrete implementation of a [PrefixElement].
class PrefixElementImpl extends _ExistingElementImpl implements PrefixElement {
  /// The scope of this prefix, `null` if it has not been created yet.
  PrefixScope? _scope;

  /// Initialize a newly created method element to have the given [name] and
  /// [nameOffset].
  PrefixElementImpl(String super.name, super.nameOffset, {super.reference});

  @override
  String get displayName => name;

  @override
  LibraryOrAugmentationElementImpl get enclosingElement =>
      super.enclosingElement as LibraryOrAugmentationElementImpl;

  @override
  List<LibraryImportElementImpl> get imports {
    return enclosingElement.libraryImports
        .where((import) => import.prefix?.element == this)
        .toList();
  }

  @override
  ElementKind get kind => ElementKind.PREFIX;

  @override
  String get name {
    return super.name!;
  }

  @override
  Scope get scope => _scope ??= PrefixScope(enclosingElement, this);

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitPrefixElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writePrefixElement(this);
  }
}

/// A concrete implementation of a [PropertyAccessorElement].
class PropertyAccessorElementImpl extends ExecutableElementImpl
    with AugmentableElement<PropertyAccessorElementImpl>
    implements PropertyAccessorElement {
  PropertyInducingElementImpl? _variable;

  /// If this method is a synthetic element which is based on another method
  /// with some modifications (such as making some parameters covariant),
  /// this field contains the base method.
  PropertyAccessorElement? prototype;

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
  PropertyAccessorElement? get correspondingSetter {
    if (isSetter) {
      return null;
    }
    return variable2?.setter;
  }

  @override
  PropertyAccessorElement get declaration => prototype ?? this;

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
      return considerCanonicalizeString("${super.name}=");
    }
    return super.name;
  }

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

  @override
  Element get enclosingElement => variable2.enclosingElement;

  @override
  bool get hasImplicitReturnType => variable2.hasImplicitType;

  @override
  bool get isGetter => true;

  @override
  Element get nonSynthetic {
    if (!variable2.isSynthetic) {
      return variable2;
    }
    assert(enclosingElement is EnumElementImpl);
    return enclosingElement;
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

  @override
  Element get enclosingElement => variable2.enclosingElement;

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
    implements PropertyInducingElement {
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
  Element get nonSynthetic {
    if (isSynthetic) {
      if (enclosingElement is EnumElementImpl) {
        // TODO(scheglov): remove 'index'?
        if (name == 'index' || name == 'values') {
          return enclosingElement;
        }
      }
      return (getter ?? setter)!;
    } else {
      return this;
    }
  }

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

/// Instances of this class are set for fields and top-level variables
/// to perform top-level type inference during linking.
abstract class PropertyInducingElementTypeInference {
  DartType perform();
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
    implements SuperFormalParameterElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  SuperFormalParameterElementImpl({
    required String super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  /// Super parameters are visible only in the initializer list scope,
  /// and introduce final variables.
  @override
  bool get isFinal => true;

  @override
  bool get isSuperFormal => true;

  @override
  ParameterElement? get superConstructorParameter {
    var enclosingElement = this.enclosingElement;
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
}

/// A concrete implementation of a [TopLevelVariableElement].
class TopLevelVariableElementImpl extends PropertyInducingElementImpl
    with AugmentableElement<TopLevelVariableElementImpl>
    implements TopLevelVariableElement {
  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  TopLevelVariableElementImpl(super.name, super.offset);

  @override
  TopLevelVariableElement get declaration => this;

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
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTopLevelVariableElement(this);
}

/// An element that represents [GenericTypeAlias].
///
/// Clients may not extend, implement or mix-in this class.
class TypeAliasElementImpl extends _ExistingElementImpl
    with
        TypeParameterizedElementMixin,
        AugmentableElement<TypeAliasElementImpl>,
        MacroTargetElement
    implements TypeAliasElement {
  /// Is `true` if the element has direct or indirect reference to itself
  /// from anywhere except a class element or type parameter bounds.
  bool hasSelfReference = false;

  bool isFunctionTypeAliasBased = false;

  @override
  ElementLinkedData? linkedData;

  ElementImpl? _aliasedElement;
  DartType? _aliasedType;

  TypeAliasElementImpl(String super.name, super.nameOffset);

  @override
  ElementImpl? get aliasedElement {
    linkedData?.read(this);
    return _aliasedElement;
  }

  set aliasedElement(ElementImpl? aliasedElement) {
    _aliasedElement = aliasedElement;
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
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

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

/// A concrete implementation of a [TypeParameterElement].
class TypeParameterElementImpl extends ElementImpl
    implements TypeParameterElement {
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
  }

  @override
  TypeParameterElement get declaration => this;

  @override
  String get displayName => name;

  bool get isLegacyCovariant {
    return _variance == null;
  }

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @override
  String get name {
    return super.name!;
  }

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
      if (other.enclosingElement == null || enclosingElement == null) {
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

/// Mixin representing an element which can have type parameters.
mixin TypeParameterizedElementMixin on ElementImpl
    implements _ExistingElementImpl, TypeParameterizedElement {
  List<TypeParameterElement> _typeParameters = const [];

  @override
  bool get isSimplyBounded => true;

  ElementLinkedData? get linkedData;

  @override
  List<TypeParameterElement> get typeParameters {
    linkedData?.read(this);
    return _typeParameters;
  }

  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (var typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameters = typeParameters;
  }

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

abstract class _ExistingElementImpl extends ElementImpl with _HasLibraryMixin {
  _ExistingElementImpl(super.name, super.offset, {super.reference});
}

mixin _HasLibraryMixin on ElementImpl {
  @override
  LibraryElementImpl get library => thisOrAncestorOfType()!;

  @override
  Source get librarySource => library.source;

  @override
  Source get source => enclosingElement!.source!;
}

/// Instances of [List]s that are used as "not yet computed" values, they
/// must be not `null`, and not identical to `const <T>[]`.
class _Sentinel {
  static final List<AugmentationImportElementImpl> augmentationImportElement =
      List.unmodifiable([]);
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
