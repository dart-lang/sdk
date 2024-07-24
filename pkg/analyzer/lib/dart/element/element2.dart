// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart'
    show
        DirectiveUri,
        ElementAnnotation,
        ElementKind,
        ElementLocation,
        ImportElementPrefix,
        LibraryLanguageVersion,
        NamespaceCombinator;
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:pub_semver/pub_semver.dart';

abstract class BindPatternVariableElement2 implements PatternVariableElement2 {}

abstract class ClassElement2 implements InterfaceElement2 {
  bool get hasNonFinalField;

  bool get isAbstract;

  bool get isBase;

  bool get isConstructable;

  bool get isDartCoreEnum;

  bool get isDartCoreObject;

  bool get isExhaustive;

  bool get isFinal;

  bool get isInterface;

  bool get isMixinApplication;

  bool get isMixinClass;

  bool get isSealed;

  bool get isValidMixin;

  bool isExtendableIn2(LibraryElement2 library);

  bool isImplementableIn2(LibraryElement2 library);

  bool isMixableIn2(LibraryElement2 library);
}

abstract class ClassFragment implements InterfaceFragment {}

abstract class ConstructorElement2 implements ExecutableElement2, _Fragmented {
  bool get isConst;

  bool get isDefaultConstructor;

  bool get isFactory;

  bool get isGenerative;

  ConstructorElement2? get redirectedConstructor2;

  ConstructorElement2? get superConstructor2;
}

abstract class ConstructorFragment implements ExecutableFragment {
  int? get nameEnd;

  int? get periodOffset;
}

abstract class Element2 {
  Element2? get baseElement;

  List<Element2> get children2;

  String get displayName;

  Element2? get enclosingElement2;

  int get id;

  bool get isPrivate;

  bool get isPublic;

  bool get isSynthetic;

  ElementKind get kind;

  LibraryElement2? get library2;

  ElementLocation? get location;

  String? get name;

  Element2 get nonSynthetic2;

  AnalysisSession? get session;

  Version? get sinceSdkVersion;

  String displayString({bool multiline = false});

  bool isAccessibleIn2(LibraryElement2 library);

  E? thisOrAncestorMatching2<E extends Element2>(
    bool Function(Element2) predicate,
  );

  E? thisOrAncestorOfType2<E extends Element2>();
}

abstract class EnumElement2 implements InterfaceElement2 {
  List<FieldElement2> get constants2;
}

abstract class EnumFragment implements InterfaceFragment {
  List<FieldElement2> get constants;
}

abstract class ExecutableElement2 implements FunctionTypedElement2 {
  bool get hasImplicitReturnType;

  bool get isAbstract;

  bool get isAsynchronous;

  bool get isExtensionTypeMember;

  bool get isExternal;

  bool get isGenerator;

  bool get isStatic;

  bool get isSynchronous;
}

abstract class ExecutableFragment implements FunctionTypedFragment {
  bool get isAugmentation;
}

abstract class ExtensionElement2 implements InstanceElement2 {
  DartType get extendedType;
}

abstract class ExtensionFragment implements InstanceFragment {}

abstract class ExtensionTypeElement2 implements InterfaceElement2 {
  ConstructorElement2 get primaryConstructor2;

  FieldElement2 get representation2;

  DartType get typeErasure;
}

abstract class ExtensionTypeFragment implements InterfaceFragment {
  ConstructorFragment get primaryConstructor;

  FieldFragment get representation;
}

abstract class FieldElement2 implements PropertyInducingElement2 {
  bool get isAbstract;

  bool get isCovariant;

  bool get isEnumConstant;

  bool get isExternal;

  bool get isPromotable;
}

abstract class FieldFormalParameterElement2 implements FormalParameterElement {
  FieldElement2? get field2;
}

abstract class FieldFormalParameterFragment
    implements FormalParameterFragment {}

abstract class FieldFragment implements PropertyInducingFragment {}

abstract class FormalParameterElement
    implements PromotableElement2, _Annotatable, _Fragmented {
  String? get defaultValueCode;

  bool get hasDefaultValue;

  bool get isCovariant;

  bool get isInitializingFormal;

  bool get isNamed;

  bool get isOptional;

  bool get isOptionalNamed;

  bool get isOptionalPositional;

  bool get isPositional;

  bool get isRequired;

  bool get isRequiredNamed;

  bool get isRequiredPositional;

  bool get isSuperFormal;

  List<FormalParameterElement> get parameters2;

  List<TypeParameterElement2> get typeParameters2;

  void appendToWithoutDelimiters2(StringBuffer buffer);
}

abstract class FormalParameterFragment
    implements PromotableFragment, _Annotatable {}

abstract class Fragment {
  List<Fragment> get children;

  Element2 get element;

  Fragment? get enclosingFragment;

  LibraryFragment get libraryFragment;

  int? get nameOffset;

  Fragment? get nextFragment;

  Fragment? get previousFragment;
}

abstract class FunctionTypedElement2 implements TypeParameterizedElement2 {
  List<FormalParameterElement> get parameters2;

  DartType get returnType;

  FunctionType get type;
}

abstract class FunctionTypedFragment implements TypeParameterizedFragment {
  List<FormalParameterFragment> get parameters;
}

abstract class GenericFunctionTypeElement2
    implements FunctionTypedElement2, _Fragmented {}

abstract class GenericFunctionTypeFragment implements FunctionTypedFragment {}

abstract class GetterElement implements ExecutableElement2, _Fragmented {
  SetterElement? get correspondingSetter2;

  PropertyInducingElement2? get variable2;
}

abstract class GetterFragment implements ExecutableFragment {
  SetterFragment? get correspondingSetter;

  PropertyInducingFragment? get variable;
}

abstract class InstanceElement2
    implements TypeDefiningElement2, TypeParameterizedElement2 {
  List<FieldElement2> get fields;

  List<GetterElement> get getters;

  List<MethodElement2> get methods;

  List<SetterElement> get setters;

  DartType get thisType;
}

abstract class InstanceFragment
    implements TypeDefiningFragment, TypeParameterizedFragment {
  List<FieldFragment> get fields2;

  List<GetterFragment> get getters;

  bool get isAugmentation;

  List<MethodFragment> get methods2;

  List<SetterFragment> get setters;
}

abstract class InterfaceElement2 implements InstanceElement2 {
  List<InterfaceType> get allSupertypes;

  List<ConstructorElement2> get constructors2;

  List<InterfaceType> get interfaces;

  List<InterfaceType> get mixins;

  InterfaceType? get supertype;

  ConstructorElement2? get unnamedConstructor2;

  InterfaceType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  });
}

abstract class InterfaceFragment implements InstanceFragment {
  List<ConstructorFragment> get constructors;

  List<InterfaceType> get interfaces;

  List<InterfaceType> get mixins;

  InterfaceType? get supertype;
}

abstract class JoinPatternVariableElement2 implements PatternVariableElement2 {
  bool get isConsistent;

  List<PatternVariableElement2> get variables2;
}

abstract class LabelElement2 implements Element2 {
  ExecutableFragment get enclosingFunction;
}

abstract class LibraryElement2 implements Element2, _Annotatable, _Fragmented {
  List<ExtensionElement2> get accessibleExtensions;

  List<ClassElement2> get classes;

  TopLevelFunctionElement? get entryPoint;

  List<EnumElement2> get enums;

  List<LibraryElement2> get exportedLibraries2;

  Namespace get exportNamespace;

  List<ExtensionElement2> get extensions;

  List<ExtensionTypeElement2> get extensionTypes;

  FeatureSet get featureSet;

  List<TopLevelFunctionElement> get functions;

  List<GetterElement> get getters;

  String get identifier;

  bool get isDartAsync;

  bool get isDartCore;

  bool get isInSdk;

  LibraryLanguageVersion get languageVersion;

  TopLevelFunctionElement get loadLibraryFunction;

  List<MixinElement2> get mixins;

  Namespace get publicNamespace;

  List<SetterElement> get setters;

  List<TopLevelVariableElement2> get topLevelVariables;

  List<TypeAliasElement2> get typeAliases;

  TypeProvider get typeProvider;

  TypeSystem get typeSystem;
}

abstract class LibraryExport {
  List<NamespaceCombinator> get combinators;

  LibraryElement2? get exportedLibrary2;

  int get exportKeywordOffset;

  DirectiveUri get uri;
}

abstract class LibraryFragment implements Fragment, _Annotatable {
  List<ClassFragment> get classes2;

  List<EnumFragment> get enums2;

  List<ExtensionFragment> get extensions2;

  List<ExtensionTypeFragment> get extensionTypes2;

  List<TopLevelFunctionFragment> get functions2;

  List<GetterFragment> get getters;

  List<LibraryExport> get libraryExports;

  List<LibraryImport> get libraryImports;

  LineInfo get lineInfo;

  List<MixinFragment> get mixins2;

  List<PartInclude> get partIncludes;

  List<PrefixElement2> get prefixes;

  Scope get scope;

  List<SetterFragment> get setters;

  List<TopLevelVariableFragment> get topLevelVariables2;

  List<TypeAliasFragment> get typeAliases2;
}

abstract class LibraryImport {
  List<NamespaceCombinator> get combinators;

  LibraryElement2? get importedLibrary2;

  int get importKeywordOffset;

  Namespace get namespace;

  ImportElementPrefix? get prefix;

  DirectiveUri get uri;
}

abstract class LocalFunctionElement implements ExecutableElement2 {
  ExecutableFragment get enclosingFunction;
}

abstract class LocalVariableElement2 implements PromotableElement2 {
  ExecutableFragment get enclosingFunction;

  bool get hasInitializer;
}

abstract class MethodElement2 implements ExecutableElement2, _Fragmented {
  bool get isOperator;
}

abstract class MethodFragment implements ExecutableFragment {}

abstract class MixinElement2 implements InterfaceElement2 {
  bool get isBase;

  List<InterfaceType> get superclassConstraints;

  bool isImplementableIn2(LibraryElement2 library);
}

abstract class MixinFragment implements InterfaceFragment {
  List<InterfaceType> get superclassConstraints;
}

abstract class MultiplyDefinedElement2 implements Element2 {
  List<Element2> get conflictingElements2;
}

abstract class MultiplyInheritedExecutableElement2
    implements ExecutableElement2 {
  List<ExecutableElement2> get inheritedElements2;
}

abstract class PartInclude {
  DirectiveUri get uri;
}

abstract class PatternVariableElement2 implements LocalVariableElement2 {
  JoinPatternVariableElement2? get join2;
}

abstract class PrefixElement2 implements Element2 {
  List<LibraryImport> get imports2;

  Scope get scope;
}

abstract class PromotableElement2 implements VariableElement2 {}

abstract class PromotableFragment implements VariableFragment {}

abstract class PropertyInducingElement2
    implements VariableElement2, _Fragmented {
  GetterElement? get getter;

  bool get hasInitializer;

  SetterElement? get setter;
}

abstract class PropertyInducingFragment implements VariableFragment {
  GetterElement? get getter;

  bool get hasInitializer;

  SetterElement? get setter;
}

abstract class SetterElement implements ExecutableElement2, _Fragmented {
  GetterElement? get correspondingGetter2;

  PropertyInducingElement2? get variable2;
}

abstract class SetterFragment implements ExecutableFragment {
  GetterFragment? get correspondingGetter;

  PropertyInducingFragment? get variable;
}

abstract class SuperFormalParameterElement2 implements FormalParameterElement {
  FormalParameterElement? get superConstructorParameter2;
}

abstract class SuperFormalParameterFragment
    implements FormalParameterFragment {}

abstract class TopLevelFunctionElement
    implements ExecutableElement2, _Fragmented {
  bool get isDartCoreIdentical;

  bool get isEntryPoint;
}

abstract class TopLevelFunctionFragment implements ExecutableFragment {}

abstract class TopLevelVariableElement2 implements PropertyInducingElement2 {
  bool get isExternal;
}

abstract class TopLevelVariableFragment implements PropertyInducingFragment {}

abstract class TypeAliasElement2
    implements TypeParameterizedElement2, TypeDefiningElement2 {
  Element2? get aliasedElement2;

  DartType get aliasedType;

  DartType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  });
}

abstract class TypeAliasFragment
    implements TypeParameterizedFragment, TypeDefiningFragment {}

abstract class TypeDefiningElement2
    implements Element2, _Annotatable, _Fragmented {
  // TODO(brianwilkerson): Evaluate to see whether this type is actually needed
  //  after converting clients to the new API.
}

abstract class TypeDefiningFragment implements Fragment, _Annotatable {}

abstract class TypeParameterElement2 implements TypeDefiningElement2 {
  DartType? get bound;

  TypeParameterType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  });
}

abstract class TypeParameterFragment implements TypeDefiningFragment {}

abstract class TypeParameterizedElement2 implements Element2, _Annotatable {
  bool get isSimplyBounded;

  List<TypeParameterElement2> get typeParameters2;
}

abstract class TypeParameterizedFragment implements Fragment, _Annotatable {}

abstract class UndefinedElement2 implements Element2 {}

abstract class VariableElement2 implements Element2 {
  bool get hasImplicitType;

  bool get isConst;

  bool get isFinal;

  bool get isLate;

  bool get isStatic;

  DartType get type;

  DartObject? computeConstantValue();
}

abstract class VariableFragment implements Fragment {}

/// An element or fragment that can have either annotations (metadata) or a
/// documentation comment associated with it.
abstract class _Annotatable {
  String? get documentationComment;

  bool get hasAlwaysThrows;

  bool get hasDeprecated;

  bool get hasDoNotStore;

  bool get hasDoNotSubmit;

  bool get hasFactory;

  bool get hasImmutable;

  bool get hasInternal;

  bool get hasIsTest;

  bool get hasIsTestGroup;

  bool get hasJS;

  bool get hasLiteral;

  bool get hasMustBeConst;

  bool get hasMustBeOverridden;

  bool get hasMustCallSuper;

  bool get hasNonVirtual;

  bool get hasOptionalTypeArgs;

  bool get hasOverride;

  bool get hasProtected;

  bool get hasRedeclare;

  bool get hasReopen;

  bool get hasRequired;

  bool get hasSealed;

  bool get hasUseResult;

  bool get hasVisibleForOverriding;

  bool get hasVisibleForTemplate;

  bool get hasVisibleForTesting;

  bool get hasVisibleOutsideTemplate;

  List<ElementAnnotation> get metadata;
}

abstract class _Fragmented {
  Fragment get firstFragment;
}
