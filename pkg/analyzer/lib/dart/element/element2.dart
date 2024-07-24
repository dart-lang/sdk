// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the elements and fragments that are part of the element model.
///
/// The element model describes the semantic (as opposed to syntactic) structure
/// of Dart code. The syntactic structure of the code is modeled by the
/// [AST structure](../dart_ast_ast/dart_ast_ast-library.html).
///
/// The element model consists of three closely related kinds of objects:
/// elements (instances of a subclass of [Element2]), fragments (instances of a
/// subclass of [Fragment]) and types. This library defines the elements and
/// fragments; the types are defined in
/// [type.dart](../dart_element_type/dart_element_type-library.html).
///
/// Generally speaking, an element represents something that is declared in the
/// code, such as a class, method, or variable. Elements are organized in a tree
/// structure in which the children of an element are the elements that are
/// logically (and often syntactically) part of the declaration of the parent.
/// For example, the elements representing the methods and fields in a class are
/// children of the element representing the class.
///
/// Some elements, such as a [LocalVariableElement2] are declared by a single
/// declaration, but most elements can be declared by multiple declarations. A
/// fragment represents a single declararation when the corresponding element
/// can have multiple declarations. There is no fragment for an element that can
/// only have one declaration.
///
/// As with elements, fragments are organized in a tree structure. The two
/// structures parallel each other.
///
/// Every complete element structure is rooted by an instance of the class
/// [LibraryElement2]. A library element represents a single Dart library. Every
/// library is defined by one or more compilation units (the library and all of
/// its parts). The compilation units are represented by the class
/// [LibraryFragment].
///
/// The element model does not contain everything in the code, only those things
/// that are declared by the code. For example, it does not include any
/// representation of the statements in a method body, but if one of those
/// statements declares a local variable then the local variable will be
/// represented by an element.
///
/// @docImport 'package:analyzer/src/dart/element/member.dart';
library;

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
  @override
  ConstructorElement2 get baseElement;

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

/// The base class for all of the elements in the element model.
///
/// Generally speaking, the element model is a semantic model of the program
/// that represents things that are declared with a name and hence can be
/// referenced elsewhere in the code. There are two exceptions to the general
/// case.
///
/// First, there are elements in the element model that are created for the
/// convenience of various kinds of analysis but that don't have any
/// corresponding declaration within the source code. Such elements are marked
/// as being <i>synthetic</i>. Examples of synthetic elements include
/// - default constructors in classes that don't define any explicit
///   constructors,
/// - getters and setters that are induced by explicit field declarations,
/// - fields that are induced by explicit declarations of getters and setters,
///   and
/// - functions representing the initialization expression for a variable.
///
/// Second, there are elements in the element model that don't have, or are not
/// required to have a name. These correspond to things like unnamed functions
/// or extensions. They exist in order to more accurately represent the semantic
/// structure of the program.
///
/// Clients may not extend, implement or mix-in this class.
abstract class Element2 {
  /// The non-[Member] version of this element.
  ///
  /// If the receiver is a view on an element, such as a method from an
  /// interface type with substituted type parameters, this getter will return
  /// the corresponding element from the class, without any substitutions.
  ///
  /// If the receiver is already a non-[Member] element (or a synthetic element,
  /// such as a synthetic property accessor), this getter will return the
  /// receiver.
  Element2? get baseElement;

  /// The children of this element.
  ///
  /// There is no guarantee of the order in which the children will be returned.
  /// For example, they are not guaranteed to be in lexical order.
  List<Element2> get children2;

  /// The display name of this element, or empty string if the element does not
  /// have a name.
  ///
  /// In most cases the name and the display name are the same. They differ in
  /// cases such as setters where the `name` of some setter (`set s(x)`) is `s=`
  /// but the `displayName` is `s`.
  String get displayName;

  /// The element that either physically or logically encloses this element.
  ///
  /// Returns `null` if this element is a library because libraries are the
  /// top-level elements in the model.
  Element2? get enclosingElement2;

  /// The unique integer identifier of this element.
  int get id;

  /// Whether this element is private.
  ///
  /// Private elements are visible only within the library in which they are
  /// declared.
  bool get isPrivate;

  /// Whether this element is public.
  ///
  /// Public elements are visible within any library that imports the library
  /// in which they are declared.
  bool get isPublic;

  /// Whether this element is synthetic.
  ///
  /// A synthetic element is an element that is not represented in the source
  /// code explicitly, but is implied by the source code, such as the default
  /// constructor for a class that does not explicitly define any constructors.
  bool get isSynthetic;

  /// The kind of this element.
  ElementKind get kind;

  /// Library that contains this element.
  ///
  /// This will be the element itself if it is a library element. This will be
  /// `null` if this element is [MultiplyDefinedElement] that is not contained
  /// in a single library.
  LibraryElement2? get library2;

  /// The location of this element in the element model.
  ///
  /// The object can be used to locate this element at a later time.
  ElementLocation? get location;

  /// The name of this element.
  ///
  /// Returns `null` if this element does not have a name.
  String? get name;

  /// The non-synthetic element that caused this element to be created.
  ///
  /// If this element is not synthetic, then the element itself is returned.
  ///
  /// If this element is synthetic, then the corresponding non-synthetic
  /// element is returned. For example, for a synthetic getter of a
  /// non-synthetic field the field is returned; for a synthetic constructor
  /// the enclosing class is returned.
  Element2 get nonSynthetic2;

  /// The analysis session in which this element is defined.
  AnalysisSession? get session;

  /// The presentation of this element as it should appear when presented to
  /// users.
  ///
  /// If [multiline] is `true`, then the string may be wrapped over multiple
  /// lines with newlines to improve formatting. For example, function
  /// signatures may be formatted as if they had trailing commas.
  ///
  /// If [preferTypeAlias] is `true` and the element represents a type defined
  /// by a type alias, then the name of the type alias will be used in the
  /// returned string rather than the name of the type being aliased.
  ///
  /// Clients should not depend on the content of the returned value as it will
  /// be changed if doing so would improve the UX.
  String displayString2({bool multiline = false, bool preferTypeAlias = false});

  /// Whether the element, assuming that it is within scope, is accessible to
  /// code in the given [library].
  ///
  /// This is defined by the Dart Language Specification in section 6.2:
  /// <blockquote>
  /// A declaration <i>m</i> is accessible to a library <i>L</i> if <i>m</i> is
  /// declared in <i>L</i> or if <i>m</i> is public.
  /// </blockquote>
  bool isAccessibleIn2(LibraryElement2 library);

  /// Returns either this element or the most immediate ancestor of this element
  /// for which the [predicate] returns `true`.
  ///
  /// Returns `null` if there is no such element.
  E? thisOrAncestorMatching2<E extends Element2>(
    bool Function(Element2) predicate,
  );

  /// Returns either this element or the most immediate ancestor of this element
  /// that has the given type.
  ///
  /// Returns `null` if there is no such element.
  E? thisOrAncestorOfType2<E extends Element2>();
}

abstract class EnumElement2 implements InterfaceElement2 {
  List<FieldElement2> get constants2;
}

abstract class EnumFragment implements InterfaceFragment {
  List<FieldElement2> get constants;
}

abstract class ExecutableElement2 implements FunctionTypedElement2 {
  @override
  ExecutableElement2 get baseElement;

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
  @override
  FieldElement2 get baseElement;

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
  @override
  FormalParameterElement get baseElement;

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
  @override
  GetterElement get baseElement;

  SetterElement? get correspondingSetter2;

  PropertyInducingElement2? get variable2;
}

abstract class GetterFragment implements ExecutableFragment {
  SetterFragment? get correspondingSetter;

  PropertyInducingFragment? get variable;
}

abstract class InstanceElement2
    implements TypeDefiningElement2, TypeParameterizedElement2 {
  @override
  LibraryElement2 get enclosingElement2;

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
  @override
  // TODO(brianwilkerson): We shouldn't be inheriting this member.
  ExecutableElement2 get enclosingElement2;

  ExecutableFragment get enclosingFunction;

  @override
  LibraryElement2 get library2;
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

  @override
  LibraryElement2 get library2;

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
  @override
  LocalVariableElement2 get baseElement;

  ExecutableFragment get enclosingFunction;

  bool get hasInitializer;
}

abstract class MethodElement2 implements ExecutableElement2, _Fragmented {
  @override
  MethodElement2 get baseElement;

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
  @override
  LibraryElement2 get enclosingElement2;

  List<LibraryImport> get imports2;

  @override
  LibraryElement2 get library2;

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
  @override
  SetterElement get baseElement;

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
  @override
  TopLevelFunctionElement get baseElement;

  bool get isDartCoreIdentical;

  bool get isEntryPoint;
}

abstract class TopLevelFunctionFragment implements ExecutableFragment {}

abstract class TopLevelVariableElement2 implements PropertyInducingElement2 {
  @override
  TopLevelVariableElement2 get baseElement;

  bool get isExternal;
}

abstract class TopLevelVariableFragment implements PropertyInducingFragment {}

abstract class TypeAliasElement2
    implements TypeParameterizedElement2, TypeDefiningElement2 {
  Element2? get aliasedElement2;

  DartType get aliasedType;

  @override
  LibraryElement2 get enclosingElement2;

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

  @override
  LibraryElement2 get library2;
}

abstract class TypeDefiningFragment implements Fragment, _Annotatable {}

abstract class TypeParameterElement2 implements TypeDefiningElement2 {
  @override
  TypeParameterElement2 get baseElement;

  DartType? get bound;

  @override
  LibraryElement2 get library2;

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

/// An element or fragment that can have either annotations (metadata), a
/// documentation comment, or both associated with it.
abstract class _Annotatable {
  /// The content of the documentation comment (including delimiters) for this
  /// element or fragment.
  ///
  /// If the receiver is an element that has fragments, the comment will be a
  /// concatenation of the comments from all of the fragments.
  ///
  /// Returns `null` if the receiver doesn't have documentation.
  String? get documentationComment;

  /// Whether the receiver has an annotation of the form `@alwaysThrows`.
  bool get hasAlwaysThrows;

  /// Whether the receiver has an annotation of the form `@deprecated`
  /// or `@Deprecated('..')`.
  bool get hasDeprecated;

  /// Whether the receiver has an annotation of the form `@doNotStore`.
  bool get hasDoNotStore;

  /// Whether the receiver has an annotation of the form `@doNotSubmit`.
  bool get hasDoNotSubmit;

  /// Whether the receiver has an annotation of the form `@factory`.
  bool get hasFactory;

  /// Whether the receiver has an annotation of the form `@immutable`.
  bool get hasImmutable;

  /// Whether the receiver has an annotation of the form `@internal`.
  bool get hasInternal;

  /// Whether the receiver has an annotation of the form `@isTest`.
  bool get hasIsTest;

  /// Whether the receiver has an annotation of the form `@isTestGroup`.
  bool get hasIsTestGroup;

  /// Whether the receiver has an annotation of the form `@JS(..)`.
  bool get hasJS;

  /// Whether the receiver has an annotation of the form `@literal`.
  bool get hasLiteral;

  /// Whether the receiver has an annotation of the form `@mustBeConst`.
  bool get hasMustBeConst;

  /// Whether the receiver has an annotation of the form `@mustBeOverridden`.
  bool get hasMustBeOverridden;

  /// Whether the receiver has an annotation of the form `@mustCallSuper`.
  bool get hasMustCallSuper;

  /// Whether the receiver has an annotation of the form `@nonVirtual`.
  bool get hasNonVirtual;

  /// Whether the receiver has an annotation of the form `@optionalTypeArgs`.
  bool get hasOptionalTypeArgs;

  /// Whether the receiver has an annotation of the form `@override`.
  bool get hasOverride;

  /// Whether the receiver has an annotation of the form `@protected`.
  bool get hasProtected;

  /// Whether the receiver has an annotation of the form `@redeclare`.
  bool get hasRedeclare;

  /// Whether the receiver has an annotation of the form `@reopen`.
  bool get hasReopen;

  /// Whether the receiver has an annotation of the form `@required`.
  bool get hasRequired;

  /// Whether the receiver has an annotation of the form `@sealed`.
  bool get hasSealed;

  /// Whether the receiver has an annotation of the form `@useResult`
  /// or `@UseResult('..')`.
  bool get hasUseResult;

  /// Whether the receiver has an annotation of the form `@visibleForOverriding`.
  bool get hasVisibleForOverriding;

  /// Whether the receiver has an annotation of the form `@visibleForTemplate`.
  bool get hasVisibleForTemplate;

  /// Whether the receiver has an annotation of the form `@visibleForTesting`.
  bool get hasVisibleForTesting;

  /// Whether the receiver has an annotation of the form
  /// `@visibleOutsideTemplate`.
  bool get hasVisibleOutsideTemplate;

  /// The metadata associated with the element or fragment.
  ///
  /// If the receiver is an element that has fragments, the list will include
  /// all of the metadata from all of the fragments.
  ///
  /// The list will be empty if the receiver does not have any metadata or if
  /// the library containing this element has not yet been fully resolved.
  List<ElementAnnotation> get metadata;

  /// The version where this SDK API was added.
  ///
  /// A `@Since()` annotation can be applied to a library declaration,
  /// any public declaration in a library, or in a class, or to an optional
  /// parameter, etc.
  ///
  /// The returned version is "effective", so that if a library is annotated
  /// then all elements of the library inherit it; or if a class is annotated
  /// then all members and constructors of the class inherit it.
  ///
  /// If multiple `@Since()` annotations apply to the same element, the latest
  /// version takes precedence.
  ///
  /// Returns `null` if the element is not declared in the SDK, or doesn't have
  /// a `@Since()` annotation applied to it.
  Version? get sinceSdkVersion;
}

/// An element that can be declared in multiple fragments.
abstract class _Fragmented {
  Fragment get firstFragment;
}
