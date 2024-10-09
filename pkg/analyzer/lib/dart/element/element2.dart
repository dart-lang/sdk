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
        LibraryLanguageVersion,
        NamespaceCombinator;
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/dart/element/element.dart'
    show
        DirectiveUri,
        DirectiveUriWithLibrary,
        DirectiveUriWithRelativeUri,
        DirectiveUriWithRelativeUriString,
        DirectiveUriWithSource,
        DirectiveUriWithUnit,
        ElementAnnotation,
        ElementKind;

/// An element or fragment that can have either annotations (metadata), a
/// documentation comment, or both associated with it.
abstract class Annotatable {
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

abstract class BindPatternVariableElement2 implements PatternVariableElement2 {}

/// A class.
///
/// The class can be defined by either a class declaration (with a class body),
/// or a mixin application (without a class body).
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassElement2 implements InterfaceElement2 {
  @override
  ClassFragment get firstFragment;

  /// Whether the class or its superclass declares a non-final instance field.
  bool get hasNonFinalField;

  /// Whether the class is abstract.
  ///
  /// A class is abstract if it has an explicit `abstract` modifier. Note, that
  /// this definition of <i>abstract</i> is different from <i>has unimplemented
  /// members</i>.
  bool get isAbstract;

  /// Whether this class is a base class.
  ///
  /// A class is a base class if it has an explicit `base` modifier, or the
  /// class has a `base` induced modifier and [isSealed] is `true` as well.
  /// The base modifier allows the class to be extended but not implemented.
  bool get isBase;

  /// Whether the class can be instantiated.
  bool get isConstructable;

  /// Whether the class represents the class 'Enum' defined in `dart:core`.
  bool get isDartCoreEnum;

  /// Whether the class represents the class 'Object' defined in `dart:core`.
  bool get isDartCoreObject;

  /// Whether the class is exhaustive.
  ///
  /// A class is exhaustive if it has the property where, in a switch, if you
  /// cover all of the subtypes of this element, then the compiler knows that
  /// you have covered all possible instances of the type.
  bool get isExhaustive;

  /// Whether the class is a final class.
  ///
  /// A class is a final class if it has an explicit `final` modifier, or the
  /// class has a `final` induced modifier and [isSealed] is `true` as well.
  /// The final modifier prohibits this class from being extended, implemented,
  /// or mixed in.
  bool get isFinal;

  /// Whether the class is an interface class.
  ///
  /// A class is an interface class if it has an explicit `interface` modifier,
  /// or the class has an `interface` induced modifier and [isSealed] is `true`
  /// as well. The interface modifier allows the class to be implemented, but
  /// not extended or mixed in.
  bool get isInterface;

  /// Whether the class is a mixin application.
  ///
  /// A class is a mixin application if it was declared using the syntax
  /// `class A = B with C;`.
  bool get isMixinApplication;

  /// Whether the class is a mixin class.
  ///
  /// A class is a mixin class if it has an explicit `mixin` modifier.
  bool get isMixinClass;

  /// Whether the class is a sealed class.
  ///
  /// A class is a sealed class if it has an explicit `sealed` modifier.
  bool get isSealed;

  /// Whether the class can validly be used as a mixin when defining another
  /// class.
  ///
  /// For classes defined by a class declaration or a mixin application, the
  /// behavior of this method is defined by the Dart Language Specification
  /// in section 9:
  /// <blockquote>
  /// It is a compile-time error if a declared or derived mixin refers to super.
  /// It is a compile-time error if a declared or derived mixin explicitly
  /// declares a constructor. It is a compile-time error if a mixin is derived
  /// from a class whose superclass is not Object.
  /// </blockquote>
  bool get isValidMixin;

  /// Whether the class, assuming that it is within scope, can be extended by
  /// classes in the given [library].
  bool isExtendableIn2(LibraryElement2 library);

  /// Whether the class, assuming that it is within scope, can be implemented by
  /// classes, mixins, and enums in the given [library].
  bool isImplementableIn2(LibraryElement2 library);

  /// Whether the class, assuming that it is within scope, can be mixed-in by
  /// classes and enums in the given [library].
  bool isMixableIn2(LibraryElement2 library);
}

/// The portion of a [ClassElement2] contributed by a single declaration.
///
/// The fragment can be defined by either a class declaration (with a class
/// body), or a mixin application (without a class body).
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassFragment implements InterfaceFragment {
  @override
  ClassElement2 get element;
}

/// An element representing a constructor defined by a class, enum, or extension
/// type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorElement2
    implements ExecutableElement2, FragmentedElement {
  @override
  ConstructorElement2 get baseElement;

  @override
  InterfaceElement2 get enclosingElement2;

  @override
  ConstructorFragment? get firstFragment;

  /// Whether the constructor is a const constructor.
  bool get isConst;

  /// Whether the constructor can be used as a default constructor - unnamed,
  /// and has no required parameters.
  bool get isDefaultConstructor;

  /// Whether the constructor represents a factory constructor.
  bool get isFactory;

  /// Whether the constructor represents a generative constructor.
  bool get isGenerative;

  @override
  String get name;

  /// The constructor to which this constructor is redirecting.
  ///
  /// Returns `null` if this constructor does not redirect to another
  /// constructor or if the library containing this constructor has not yet been
  /// resolved.
  ConstructorElement2? get redirectedConstructor2;

  /// The constructor of the superclass that this constructor invokes, or
  /// `null` if this constructor redirects to another constructor, or if the
  /// library containing this constructor has not yet been resolved.
  ConstructorElement2? get superConstructor2;
}

/// The portion of a [ConstructorElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorFragment implements ExecutableFragment {
  @override
  ConstructorElement2 get element;

  @override
  InstanceFragment? get enclosingFragment;

  /// The offset of the end of the name in this fragment.
  ///
  /// Returns `null` if the fragment has no name.
  int? get nameEnd;

  @override
  ConstructorFragment? get nextFragment;

  /// The offset of the `.` before the constructor name.
  ///
  /// Returns `null` if the constructor is unnamed.
  int? get periodOffset;

  @override
  ConstructorFragment? get previousFragment;
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
  /// In particular, they are not guaranteed to be in lexical order.
  List<Element2> get children2;

  /// The display name of this element, or an empty string if the element does
  /// not have a name.
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
  /// This will be the element itself if it's a library element. This will be
  /// `null` if this element is a [MultiplyDefinedElement] that isn't contained
  /// in a single library.
  LibraryElement2? get library2;

  /// The location of this element in the element model.
  ///
  /// The object can be used to locate this element at a later time.
  ElementLocation? get location;

  /// The name of this element.
  ///
  /// Returns `null` if this element doesn't have a name.
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

/// An element that represents an enum.
///
/// Clients may not extend, implement or mix-in this class.
abstract class EnumElement2 implements InterfaceElement2 {
  /// The constants defined by the enum.
  List<FieldElement2> get constants2;

  @override
  EnumFragment get firstFragment;
}

/// The portion of an [EnumElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class EnumFragment implements InterfaceFragment {
  /// The constants defined by this fragment of the enum.
  List<FieldElement2> get constants2;

  @override
  EnumElement2 get element;
}

/// An element representing an executable object, including functions, methods,
/// constructors, getters, and setters.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExecutableElement2 implements FunctionTypedElement2 {
  @override
  ExecutableElement2 get baseElement;

  /// Whether the executable element did not have an explicit return type
  /// specified for it in the original source.
  bool get hasImplicitReturnType;

  /// Whether the executable element is abstract.
  ///
  /// Executable elements are abstract if they are not external, and have no
  /// body.
  bool get isAbstract;

  /// Whether the executable element is an extension type member.
  bool get isExtensionTypeMember;

  /// Whether the executable element is external.
  ///
  /// Executable elements are external if they are explicitly marked as such
  /// using the 'external' keyword.
  bool get isExternal;

  /// Whether the element is a static element.
  ///
  /// A static element is an element that is not associated with a particular
  /// instance, but rather with an entire library or class.
  bool get isStatic;
}

/// The portion of an [ExecutableElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExecutableFragment implements FunctionTypedFragment {
  @override
  ExecutableElement2 get element;

  /// Whether the body is marked as being asynchronous.
  bool get isAsynchronous;

  /// Whether the element is an augmentation.
  ///
  /// Executable elements are augmentations if they are explicitly marked as
  /// such using the 'augment' modifier.
  bool get isAugmentation;

  /// Whether the body is marked as being a generator.
  bool get isGenerator;

  /// Whether the body is marked as being synchronous.
  bool get isSynchronous;
}

/// An extension.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExtensionElement2 implements InstanceElement2 {
  /// The type that is extended by this extension.
  DartType get extendedType;

  @override
  ExtensionFragment get firstFragment;
}

/// The portion of an [ExtensionElement2] contributed by a single
/// declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class ExtensionFragment implements InstanceFragment {
  @override
  ExtensionElement2 get element;
}

/// An extension type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExtensionTypeElement2 implements InterfaceElement2 {
  @override
  ExtensionTypeFragment get firstFragment;

  /// The primary constructor of this extension.
  ConstructorElement2 get primaryConstructor2;

  /// The representation of this extension.
  FieldElement2 get representation2;

  /// The extension type erasure, obtained by recursively replacing every
  /// subterm which is an extension type by the corresponding representation
  /// type.
  DartType get typeErasure;
}

/// The portion of an [ExtensionTypeElement2] contributed by a single
/// declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class ExtensionTypeFragment implements InterfaceFragment {
  @override
  ExtensionTypeElement2 get element;

  ConstructorFragment get primaryConstructor2;

  /// The representation of this extension.
  FieldFragment get representation2;
}

/// A field defined within a class, enum, extension, or mixin.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FieldElement2 implements PropertyInducingElement2 {
  @override
  FieldElement2 get baseElement;

  @override
  FieldFragment? get firstFragment;

  /// Whether the field is abstract.
  ///
  /// Executable fields are abstract if they are declared with the `abstract`
  /// keyword.
  bool get isAbstract;

  /// Whether the field was explicitly marked as being covariant.
  bool get isCovariant;

  /// Whether the element is an enum constant.
  bool get isEnumConstant;

  /// Whether the field was explicitly marked as being external.
  bool get isExternal;

  /// Whether the field can be type promoted.
  bool get isPromotable;
}

/// A field formal parameter defined within a constructor element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FieldFormalParameterElement2 implements FormalParameterElement {
  /// The field element associated with this field formal parameter.
  ///
  /// Returns `null` if the parameter references a field that doesn't exist.
  FieldElement2? get field2;
}

/// The portion of a [FieldFormalParameterElement2] contributed by a single
/// declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class FieldFormalParameterFragment implements FormalParameterFragment {
  @override
  FieldFormalParameterElement2 get element;
}

/// The portion of a [FieldElement2] contributed by a single declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class FieldFragment implements PropertyInducingFragment {
  @override
  FieldElement2 get element;

  @override
  FieldFragment? get nextFragment;

  @override
  FieldFragment? get previousFragment;
}

/// A formal parameter defined by an executable element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FormalParameterElement
    implements PromotableElement2, Annotatable, FragmentedElement {
  @override
  FormalParameterElement get baseElement;

  /// The code of the default value.
  ///
  /// Returns `null` if no default value.
  String? get defaultValueCode;

  @override
  FormalParameterFragment? get firstFragment;

  /// The formal parameters defined by this formal parameter.
  ///
  /// A parameter will only define other parameters if it is a function typed
  /// formal parameter.
  List<FormalParameterElement> get formalParameters;

  /// Whether the parameter has a default value.
  bool get hasDefaultValue;

  /// Whether the parameter is covariant, meaning it is allowed to have a
  /// narrower type in an override.
  bool get isCovariant;

  /// Whether the parameter is an initializing formal parameter.
  bool get isInitializingFormal;

  /// Whether the parameter is a named parameter.
  ///
  /// Named parameters that are annotated with the `@required` annotation are
  /// considered optional. Named parameters that are annotated with the
  /// `required` syntax are considered required.
  bool get isNamed;

  /// Whether the parameter is an optional parameter.
  ///
  /// Optional parameters can either be positional or named. Named parameters
  /// that are annotated with the `@required` annotation are considered
  /// optional. Named parameters that are annotated with the `required` syntax
  /// are considered required.
  bool get isOptional;

  /// Whether the parameter is both an optional and named parameter.
  ///
  /// Named parameters that are annotated with the `@required` annotation are
  /// considered optional. Named parameters that are annotated with the
  /// `required` syntax are considered required.
  bool get isOptionalNamed;

  /// Whether the parameter is both an optional and positional parameter.
  bool get isOptionalPositional;

  /// Whether the parameter is a positional parameter.
  ///
  /// Positional parameters can either be required or optional.
  bool get isPositional;

  /// Whether the parameter is either a required positional parameter, or a
  /// named parameter with the `required` keyword.
  ///
  /// Note: the presence or absence of the `@required` annotation does not
  /// change the meaning of this getter. The parameter `{@required int x}`
  /// will return `false` and the parameter `{@required required int x}`
  /// will return `true`.
  bool get isRequired;

  /// Whether the parameter is both a required and named parameter.
  ///
  /// Named parameters that are annotated with the `@required` annotation are
  /// considered optional. Named parameters that are annotated with the
  /// `required` syntax are considered required.
  bool get isRequiredNamed;

  /// Whether the parameter is both a required and positional parameter.
  bool get isRequiredPositional;

  /// Whether the parameter is a super formal parameter.
  bool get isSuperFormal;

  /// The type parameters defined by this parameter.
  ///
  /// A parameter will only define type parameters if it is a function typed
  /// parameter.
  List<TypeParameterElement2> get typeParameters2;

  /// Appends the type, name and possibly the default value of this parameter
  /// to the given [buffer].
  void appendToWithoutDelimiters2(StringBuffer buffer);
}

/// The portion of a [FormalParameterElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class FormalParameterFragment
    implements PromotableFragment, Annotatable {
  @override
  FormalParameterElement get element;

  @override
  FormalParameterFragment? get nextFragment;

  @override
  FormalParameterFragment? get previousFragment;
}

/// A fragment that wholly or partially defines an element.
///
/// When an element is defined by one or more fragments, those fragments form an
/// augmentation chain. This is represented in the element model as a
/// doubly-linked list.
///
/// In valid code the first fragment is the base declaration and all of the
/// other fragments are augmentations. This can be violated in the element model
/// in the case of invalid code, such as when an augmentation is declared even
/// though there is no base declaration.
abstract class Fragment {
  /// The children of this fragment.
  ///
  /// There is no guarantee of the order in which the children will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<Fragment> get children3;

  /// The element composed from this fragment and possibly other fragments.
  Element2 get element;

  /// The fragment that either physically or logically encloses this fragment.
  ///
  /// Returns `null` if this fragment is the root fragment of a library because
  /// there are no fragments above the root fragment of a library.
  Fragment? get enclosingFragment;

  /// The library fragment that contains this fragment.
  ///
  /// This will be the fragment itself if it is a library fragment.
  LibraryFragment get libraryFragment;

  /// The name of this fragment.
  ///
  /// Returns `null` if this fragment doesn't have a name.
  String? get name;

  /// The offset of the name in this fragment.
  ///
  /// Returns `null` if the fragment has no name.
  int? get nameOffset;

  /// The next fragment in the augmentation chain.
  ///
  /// Returns `null` if this is the last fragment in the chain.
  Fragment? get nextFragment;

  /// The previous fragment in the augmentation chain.
  ///
  /// Returns `null` if this is the first fragment in the chain.
  Fragment? get previousFragment;
}

/// An element that can be defined by multiple fragments.
abstract class FragmentedElement {
  /// The first fragment in the chain of fragments that are merged to make this
  /// element. Or `null` if this element is synthetic, so has no fragments.
  ///
  /// The other fragments in the chain can be accessed using
  /// [Fragment.nextFragment].
  Fragment? get firstFragment;
}

/// An element that has a [FunctionType] as its [type].
///
/// This also provides convenient access to the parameters and return type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypedElement2 implements TypeParameterizedElement2 {
  /// The formal parameters defined by this element.
  List<FormalParameterElement> get formalParameters;

  /// The return type defined by this element.
  DartType get returnType;

  /// The type defined by this element.
  FunctionType get type;
}

/// The portion of a [FunctionTypedElement2] contributed by a single declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class FunctionTypedFragment implements TypeParameterizedFragment {
  @override
  FunctionTypedElement2 get element;

  /// The formal parameters defined by this fragment.
  List<FormalParameterFragment> get formalParameters;
}

/// The pseudo-declaration that defines a generic function type.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class GenericFunctionTypeElement2
    implements FunctionTypedElement2, FragmentedElement {}

/// The portion of a [GenericFunctionTypeElement2] coming from a single
/// declaration.
abstract class GenericFunctionTypeFragment implements FunctionTypedFragment {
  @override
  GenericFunctionTypeElement2 get element;

  @override
  LibraryFragment? get enclosingFragment;

  @override
  GenericFunctionTypeFragment? get nextFragment;

  @override
  GenericFunctionTypeFragment? get previousFragment;
}

/// A getter.
///
/// Getters can either be defined explicitly or they can be induced by either a
/// top-level variable or a field. Induced getters are synthetic.
///
/// Clients may not extend, implement or mix-in this class.
abstract class GetterElement implements ExecutableElement2, FragmentedElement {
  @override
  GetterElement get baseElement;

  /// The setter that corresponds to (has the same name as) this getter, or
  /// `null` if there is no corresponding setter.
  SetterElement? get correspondingSetter2;

  @override
  GetterFragment? get firstFragment;

  @override
  String get name;

  /// The field or top-level variable associated with this getter.
  ///
  /// If this getter was explicitly defined (is not synthetic) then the variable
  /// associated with it will be synthetic.
  PropertyInducingElement2? get variable3;
}

/// The portion of a [GetterElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class GetterFragment implements ExecutableFragment {
  /// The setter that corresponds to (has the same name as) this getter, or
  /// `null` if there is no corresponding setter.
  SetterFragment? get correspondingSetter2;

  // TODO(brianwilkerson): This should override `element` to be more specific,
  //  but can't because the Impl class supports both getters and setters.
  // @override
  // GetterElement get element;

  @override
  String get name;

  /// The field or top-level variable associated with this getter.
  ///
  /// If this getter was explicitly defined (is not synthetic) then the variable
  /// associated with it will be synthetic.
  PropertyInducingFragment? get variable3;
}

/// An element whose instance members can refer to `this`.
///
/// Clients may not extend, implement or mix-in this class.
abstract class InstanceElement2
    implements TypeDefiningElement2, TypeParameterizedElement2 {
  @override
  LibraryElement2 get enclosingElement2;

  /// The fields declared in this element.
  List<FieldElement2> get fields2;

  @override
  InstanceFragment get firstFragment;

  /// The getters declared in this element.
  List<GetterElement> get getters2;

  @override
  LibraryElement2 get library2;

  /// The methods declared in this element.
  List<MethodElement2> get methods2;

  /// The setters declared in this element.
  List<SetterElement> get setters2;

  /// The type of a `this` expression.
  DartType get thisType;
}

/// The portion of an [InstanceElement2] contributed by a single declaration.
abstract class InstanceFragment
    implements TypeDefiningFragment, TypeParameterizedFragment {
  @override
  InstanceElement2 get element;

  @override
  LibraryFragment? get enclosingFragment;

  /// The fields declared in this fragment.
  List<FieldFragment> get fields2;

  /// The getters declared in this fragment.
  List<GetterFragment> get getters;

  /// Whether the fragment is an augmentation.
  ///
  /// If `true`, the declaration has the explicit `augment` modifier.
  bool get isAugmentation;

  /// The methods declared in this fragment.
  List<MethodFragment> get methods2;

  @override
  InstanceFragment? get nextFragment;

  @override
  InstanceFragment? get previousFragment;

  /// The setters declared in this fragment.
  List<SetterFragment> get setters;
}

/// An element that defines an [InterfaceType].
///
/// Clients may not extend, implement or mix-in this class.
abstract class InterfaceElement2 implements InstanceElement2 {
  /// All the supertypes defined for this element and its supertypes.
  ///
  /// This includes superclasses, mixins, interfaces, and superclass
  /// constraints.
  List<InterfaceType> get allSupertypes;

  /// The constructors defined for this element.
  ///
  /// The list is empty for [MixinElement].
  List<ConstructorElement2> get constructors2;

  @override
  InterfaceFragment get firstFragment;

  /// The interfaces that are implemented by this class.
  ///
  /// <b>Note:</b> Because the element model represents the state of the code,
  /// it is possible for it to be semantically invalid. In particular, it is not
  /// safe to assume that the inheritance structure of a class does not contain
  /// a cycle. Clients that traverse the inheritance structure must explicitly
  /// guard against infinite loops.
  List<InterfaceType> get interfaces;

  /// The mixins that are applied to the class being extended in order to
  /// derive the superclass of this class.
  ///
  /// [ClassElement] and [EnumElement] can have mixins.
  ///
  /// [MixinElement] cannot have mixins, so an empty list is returned.
  ///
  /// <b>Note:</b> Because the element model represents the state of the code,
  /// it is possible for it to be semantically invalid. In particular, it is not
  /// safe to assume that the inheritance structure of a class does not contain
  /// a cycle. Clients that traverse the inheritance structure must explicitly
  /// guard against infinite loops.
  List<InterfaceType> get mixins;

  @override
  String get name;

  /// The superclass of this element.
  ///
  /// For [ClassElement] returns `null` only if this class is `Object`. If the
  /// superclass is not explicitly specified, or the superclass cannot be
  /// resolved, then the implicit superclass `Object` is returned.
  ///
  /// For [EnumElement] returns `Enum` from `dart:core`.
  ///
  /// For [MixinElement] always returns `null`.
  ///
  /// <b>Note:</b> Because the element model represents the state of the code,
  /// it is possible for it to be semantically invalid. In particular, it is not
  /// safe to assume that the inheritance structure of a class does not contain
  /// a cycle. Clients that traverse the inheritance structure must explicitly
  /// guard against infinite loops.
  InterfaceType? get supertype;

  @override
  InterfaceType get thisType;

  /// The unnamed constructor declared directly in this class.
  ///
  /// If the class does not declare any constructors, a synthetic default
  /// constructor will be returned.
  ConstructorElement2? get unnamedConstructor2;

  /// Create the [InterfaceType] for this element with the given
  /// [typeArguments] and [nullabilitySuffix].
  InterfaceType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  });
}

/// The portion of an [InterfaceElement2] contributed by a single declaration.
abstract class InterfaceFragment implements InstanceFragment {
  /// The constructors declared in this fragment.
  ///
  /// The list is empty for [MixinFragment].
  List<ConstructorFragment> get constructors2;

  @override
  InterfaceElement2 get element;

  /// The interfaces that are implemented by this fragment.
  List<InterfaceType> get interfaces;

  /// The mixins that are applied by this fragment.
  ///
  /// [ClassFragment] and [EnumFragment] can have mixins.
  ///
  /// [MixinFragment] cannot have mixins, so the empty list is returned.
  List<InterfaceType> get mixins;

  @override
  String get name;

  /// The superclass declared by this fragment.
  InterfaceType? get supertype;
}

/// A pattern variable that is a join of other pattern variables, created
/// for a logical-or patterns, or shared `case` bodies in `switch` statements.
///
/// Clients may not extend, implement or mix-in this class.
abstract class JoinPatternVariableElement2 implements PatternVariableElement2 {
  /// Whether the [variables] are consistent, present in all branches,
  /// and have the same type and finality.
  bool get isConsistent;

  /// The variables that join into this variable.
  List<PatternVariableElement2> get variables2;
}

/// A label associated with a statement.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LabelElement2 implements Element2 {
  @override
  // TODO(brianwilkerson): We shouldn't be inheriting this member.
  ExecutableElement2? get enclosingElement2;

  /// The function in which the variable is defined.
  ExecutableFragment get enclosingFunction;

  @override
  LibraryElement2 get library2;

  @override
  String get name;

  /// The offset of the name in this element.
  int get nameOffset;
}

/// A library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryElement2
    implements Element2, Annotatable, FragmentedElement {
  /// The classes defined in this library.
  ///
  /// There is no guarantee of the order in which the classes will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<ClassElement2> get classes;

  /// The entry point for this library.
  ///
  /// Returns `null` if this library doesn't have an entry point.
  ///
  /// The entry point is defined to be a zero, one, or two argument top-level
  /// function whose name is `main`.
  TopLevelFunctionElement? get entryPoint2;

  /// The enums defined in this library.
  ///
  /// There is no guarantee of the order in which the enums will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<EnumElement2> get enums;

  /// The libraries that are exported from this library.
  ///
  /// There is no guarantee of the order in which the libraries will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  // TODO(brianwilkerson): Consider removing this from the public API. It isn't
  //  clear that it's useful, given that it ignores hide and show clauses.
  @Deprecated('Use CompilationUnitElement.libraryExports')
  List<LibraryElement2> get exportedLibraries2;

  /// The export [Namespace] of this library.
  Namespace get exportNamespace;

  /// The extensions defined in this library.
  ///
  /// There is no guarantee of the order in which the extensions will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  List<ExtensionElement2> get extensions;

  /// The extension types defined in this library.
  ///
  /// There is no guarantee of the order in which the extension types will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  List<ExtensionTypeElement2> get extensionTypes;

  /// The set of features available to this library.
  ///
  /// Determined by the combination of the language version for the enclosing
  /// package, enabled experiments, and the presence of a `// @dart` language
  /// version override comment at the top of the files that make up the library.
  FeatureSet get featureSet;

  @override
  LibraryFragment get firstFragment;

  /// The fragments this library consists of.
  ///
  /// This includes the defining fragment, and fragments included using the
  /// `part` directive.
  List<LibraryFragment> get fragments;

  /// The functions defined in this library.
  ///
  /// There is no guarantee of the order in which the functions will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  List<TopLevelFunctionElement> get functions;

  /// The getters defined in this library.
  ///
  /// There is no guarantee of the order in which the getters will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<GetterElement> get getters;

  /// The identifier that uniquely identifies this element among the children
  /// of this element's parent.
  String get identifier;

  /// Whether the library is the `dart:async` library.
  bool get isDartAsync;

  /// Whether the library is the `dart:core` library.
  bool get isDartCore;

  /// Whether the library is part of the SDK.
  bool get isInSdk;

  /// The language version for this library.
  LibraryLanguageVersion get languageVersion;

  @override
  LibraryElement2 get library2;

  /// The element representing the synthetic function `loadLibrary`.
  ///
  /// Technically the function is implicitly defined for this library only if
  /// the library is imported using a deferred import, but the element is always
  /// defined for performance reasons.
  TopLevelFunctionElement get loadLibraryFunction2;

  /// The mixins defined in this library.
  ///
  /// There is no guarantee of the order in which the mixins will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<MixinElement2> get mixins;

  /// The public [Namespace] of this library.
  Namespace get publicNamespace;

  /// The setters defined in this library.
  ///
  /// There is no guarantee of the order in which the setters will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<SetterElement> get setters;

  /// The top level variables defined in this library.
  ///
  /// There is no guarantee of the order in which the top level variables will
  /// be returned. In particular, they are not guaranteed to be in lexical
  /// order.
  List<TopLevelVariableElement2> get topLevelVariables;

  /// The type aliases defined in this library.
  ///
  /// There is no guarantee of the order in which the type aliases will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  List<TypeAliasElement2> get typeAliases;

  /// The [TypeProvider] that is used in this library.
  TypeProvider get typeProvider;

  /// The [TypeSystem] that is used in this library.
  TypeSystem get typeSystem;
}

/// An export directive within a library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryExport {
  /// The combinators that were specified as part of the `export` directive.
  ///
  /// The combinators are in the order in which they were specified.
  List<NamespaceCombinator> get combinators;

  /// The [LibraryElement], if [uri] is a [DirectiveUriWithLibrary].
  LibraryElement2? get exportedLibrary2;

  /// The offset of the `export` keyword.
  int get exportKeywordOffset;

  /// The interpretation of the URI specified in the directive.
  DirectiveUri get uri;
}

/// The portion of a [LibraryElement2] coming from a single compilation unit.
abstract class LibraryFragment implements Fragment, Annotatable {
  /// The extension elements accessible within this fragment.
  List<ExtensionElement2> get accessibleExtensions2;

  /// The fragments of the classes declared in this fragment.
  List<ClassFragment> get classes2;

  @override
  LibraryElement2 get element;

  @override
  LibraryFragment? get enclosingFragment;

  /// The fragments of the enums declared in this fragment.
  List<EnumFragment> get enums2;

  /// The fragments of the extensions declared in this fragment.
  List<ExtensionFragment> get extensions2;

  /// The fragments of the extension types declared in this fragment.
  List<ExtensionTypeFragment> get extensionTypes2;

  /// The `part` directives within this fragment.
  // TODO(brianwilkerson): Rename this, `libraryExports2`, and `libraryImports2`
  //  to be consistent with each other.
  List<LibraryFragmentInclude> get fragmentIncludes;

  /// The fragments of the top-level functions declared in this fragment.
  List<TopLevelFunctionFragment> get functions2;

  /// The fragments of the top-level getters declared in this fragment.
  List<GetterFragment> get getters;

  /// The libraries exported by this unit.
  List<LibraryExport> get libraryExports2;

  /// The libraries imported by this unit.
  List<LibraryImport> get libraryImports2;

  /// The [LineInfo] for the fragment.
  LineInfo get lineInfo;

  /// The fragments of the mixins declared in this fragment.
  List<MixinFragment> get mixins2;

  @override
  LibraryFragment? get nextFragment;

  /// The prefixes used by [libraryImports2].
  ///
  /// Each prefix can be used in more than one `import` directive.
  List<PrefixElement2> get prefixes;

  @override
  LibraryFragment? get previousFragment;

  /// The scope used to resolve names within the fragment.
  ///
  /// It includes all of the elements that are declared in the library, and all
  /// of the elements imported into this fragment or parent fragments.
  Scope get scope;

  /// The fragments of the top-level setters declared in this fragment.
  List<SetterFragment> get setters;

  /// The source associated with this fragment.
  Source get source;

  /// The fragments of the top-level variables declared in this fragment.
  List<TopLevelVariableFragment> get topLevelVariables2;

  /// The fragments of the type aliases declared in this fragment.
  List<TypeAliasFragment> get typeAliases2;
}

/// A 'part' directive within a library fragment.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryFragmentInclude {
  /// The interpretation of the URI specified in the directive.
  DirectiveUri get uri;
}

/// An import directive within a library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryImport {
  /// The combinators that were specified as part of the `import` directive.
  ///
  /// The combinators are in the order in which they were specified.
  List<NamespaceCombinator> get combinators;

  /// The [LibraryElement], if [uri] is a [DirectiveUriWithLibrary].
  LibraryElement2? get importedLibrary2;

  /// The offset of the `import` keyword.
  int get importKeywordOffset;

  /// Whether this import is synthetic.
  ///
  /// A synthetic import is an import that is not represented in the source
  /// code explicitly, but is implied by the source code. This only happens for
  /// an implicit import of `dart:core`.
  bool get isSynthetic;

  /// The [Namespace] that this directive contributes to the containing library.
  Namespace get namespace;

  /// The prefix fragment that was specified as part of the import directive.
  ///
  /// Returns `null` if there was no prefix specified.
  PrefixFragment? get prefix2;

  /// The interpretation of the URI specified in the directive.
  DirectiveUri get uri;
}

/// A local function.
///
/// This can be either a local function, a closure, or the initialization
/// expression for a field or variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalFunctionElement implements ExecutableElement2 {
  /// The function in which the variable is defined.
  ExecutableFragment get enclosingFunction;

  /// The offset of the name of this element in the file that contains the
  /// declaration of this element, or `-1` if this element is synthetic, does
  /// not have a name, or otherwise does not have an offset.
  int get nameOffset;
}

/// A local variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalVariableElement2 implements PromotableElement2 {
  @override
  LocalVariableElement2 get baseElement;

  /// The function in which the variable is defined.
  ExecutableFragment get enclosingFunction;

  /// Whether the variable has an initializer at declaration.
  bool get hasInitializer;

  /// The offset of the name in this element.
  int get nameOffset;
}

/// A method.
///
/// The method can be either an instance method, an operator, or a static
/// method.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MethodElement2 implements ExecutableElement2, FragmentedElement {
  @override
  MethodElement2 get baseElement;

  @override
  MethodFragment? get firstFragment;

  /// Whether the method defines an operator.
  ///
  /// The test might be based on the name of the executable element, in which
  /// case the result will be correct when the name is legal.
  bool get isOperator;

  @override
  String get name;
}

/// The portion of a [MethodElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MethodFragment implements ExecutableFragment {
  @override
  MethodElement2 get element;

  @override
  InstanceFragment? get enclosingFragment;

  @override
  String get name;

  @override
  MethodFragment? get nextFragment;

  @override
  MethodFragment? get previousFragment;
}

/// An element that represents a mixin.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MixinElement2 implements InterfaceElement2 {
  @override
  MixinFragment get firstFragment;

  /// Whether the mixin is a base mixin.
  ///
  /// A mixin is a base mixin if it has an explicit `base` modifier.
  /// The base modifier allows a mixin to be mixed in, but not implemented.
  bool get isBase;

  /// The superclass constraints defined for this mixin.
  ///
  /// If the declaration does not have an `on` clause, then the list will
  /// contain the type for the class `Object`.
  ///
  /// <b>Note:</b> Because the element model represents the state of the code,
  /// it is possible for it to be semantically invalid. In particular, it is not
  /// safe to assume that the inheritance structure of a class does not contain
  /// a cycle. Clients that traverse the inheritance structure must explicitly
  /// guard against infinite loops.
  List<InterfaceType> get superclassConstraints;

  /// Whether the element, assuming that it is within scope, is
  /// implementable to classes, mixins, and enums in the given [library].
  bool isImplementableIn2(LibraryElement2 library);
}

/// The portion of a [PrefixElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MixinFragment implements InterfaceFragment {
  @override
  MixinElement2 get element;

  /// The superclass constraints defined for this mixin.
  ///
  /// If the declaration does not have an `on` clause, then the list will
  /// contain the type for the class `Object`.
  ///
  /// <b>Note:</b> Because the element model represents the state of the code,
  /// it is possible for it to be semantically invalid. In particular, it is not
  /// safe to assume that the inheritance structure of a class does not contain
  /// a cycle. Clients that traverse the inheritance structure must explicitly
  /// guard against infinite loops.
  List<InterfaceType> get superclassConstraints;
}

/// A pseudo-element that represents multiple elements defined within a single
/// scope that have the same name. This situation is not allowed by the
/// language, so objects implementing this interface always represent an error.
/// As a result, most of the normal operations on elements do not make sense
/// and will return useless results.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MultiplyDefinedElement2 implements Element2 {
  /// The elements that were defined within the scope to have the same name.
  List<Element2> get conflictingElements2;
}

/// A pattern variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PatternVariableElement2 implements LocalVariableElement2 {
  /// The variable in which this variable joins with other pattern variables
  /// with the same name, in a logical-or pattern, or shared case scope.
  JoinPatternVariableElement2? get join2;
}

/// A prefix used to import one or more libraries into another library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PrefixElement2 implements Element2, FragmentedElement {
  /// There is no enclosing element for import prefixes, which are elements,
  /// but exist inside a single [LibraryFragment], not an element.
  @override
  Null get enclosingElement2;

  @override
  PrefixFragment get firstFragment;

  /// The imports that share this prefix.
  List<LibraryImport> get imports;

  @override
  LibraryElement2 get library2;

  @override
  String get name;

  /// The name lookup scope for this import prefix.
  ///
  /// It consists of elements imported into the enclosing library with this
  /// prefix. The namespace combinators of the import directives are taken
  /// into account.
  Scope get scope;
}

/// The portion of a [PrefixElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PrefixFragment implements Fragment {
  @override
  PrefixElement2 get element;

  @override
  LibraryFragment? get enclosingFragment;

  /// Whether the [LibraryImport] is deferred.
  bool get isDeferred;

  @override
  String get name;

  @override
  PrefixFragment? get nextFragment;

  @override
  PrefixFragment? get previousFragment;
}

/// A variable that might be subject to type promotion.  This might be a local
/// variable or a parameter.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PromotableElement2 implements VariableElement2 {
  @override
  String get name;
}

/// The portion of a [PromotableElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PromotableFragment implements VariableFragment {
  @override
  PromotableElement2 get element;

  @override
  String get name;
}

/// A variable that has an associated getter and possibly a setter. Note that
/// explicitly defined variables implicitly define a synthetic getter and that
/// non-`final` explicitly defined variables implicitly define a synthetic
/// setter. Symmetrically, synthetic fields are implicitly created for
/// explicitly defined getters and setters. The following rules apply:
///
/// * Every explicit variable is represented by a non-synthetic
///   [PropertyInducingElement].
/// * Every explicit variable induces a getter and possibly a setter, both of
///   which are represented by synthetic [PropertyAccessorElement]s.
/// * Every explicit getter or setter is represented by a non-synthetic
///   [PropertyAccessorElement].
/// * Every explicit getter or setter (or pair thereof if they have the same
///   name) induces a variable that is represented by a synthetic
///   [PropertyInducingElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class PropertyInducingElement2
    implements VariableElement2, Annotatable, FragmentedElement {
  @override
  PropertyInducingFragment? get firstFragment;

  /// The getter associated with this variable.
  ///
  /// If this variable was explicitly defined (is not synthetic) then the
  /// getter associated with it will be synthetic.
  GetterElement? get getter2;

  @override
  String get name;

  /// The setter associated with this variable.
  ///
  /// Returns `null` if the variable is effectively `final` and therefore does
  /// not have a setter associated with it.
  ///
  /// This can happen either because the variable is explicitly defined as
  /// being `final` or because the variable is induced by an explicit getter
  /// that does not have a corresponding setter. If this variable was
  /// explicitly defined (is not synthetic) then the setter associated with
  /// it will be synthetic.
  SetterElement? get setter2;
}

/// The portion of a [PropertyInducingElement2] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PropertyInducingFragment
    implements VariableFragment, Annotatable {
  @override
  PropertyInducingElement2 get element;

  /// The getter associated with this variable.
  ///
  /// If this variable was explicitly defined (is not synthetic) then the
  /// getter associated with it will be synthetic.
  GetterFragment? get getter2;

  /// Whether the variable has an initializer at declaration.
  bool get hasInitializer;

  /// Whether the element is an augmentation.
  ///
  /// Property indicing fragments are augmentations if they are explicitly
  /// marked as such using the 'augment' modifier.
  bool get isAugmentation;

  /// Whether the fragment is a static fragment.
  ///
  /// A static fragment is a fragment that is not associated with a particular
  /// instance, but rather with an entire library or class.
  bool get isStatic;

  /// Whether this fragment is synthetic.
  ///
  /// A synthetic fragment is a fragment that is not represented in the source
  /// code explicitly, but is implied by the source code, such as the default
  /// constructor for a class that does not explicitly define any constructors.
  // TODO(brianwilkerson): Should synthetic elements have a fragment?
  bool get isSynthetic;

  @override
  String get name;

  @override
  PropertyInducingFragment? get nextFragment;

  @override
  PropertyInducingFragment? get previousFragment;

  /// The setter associated with this variable.
  ///
  /// Returns `null` if the variable is effectively `final` and therefore
  /// doesn't have a setter associated with it.
  ///
  /// This can happen either because the variable is explicitly defined as
  /// being `final` or because the variable is induced by an explicit getter
  /// that does not have a corresponding setter. If this variable was
  /// explicitly defined (is not synthetic) then the setter associated with
  /// it will be synthetic.
  SetterFragment? get setter2;
}

/// A setter.
///
/// Setters can either be defined explicitly or they can be induced by either a
/// top-level variable or a field. Induced setters are synthetic.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SetterElement implements ExecutableElement2, FragmentedElement {
  @override
  SetterElement get baseElement;

  /// The getter that corresponds to (has the same name as) this setter, or
  /// `null` if there is no corresponding getter.
  GetterElement? get correspondingGetter2;

  @override
  SetterFragment? get firstFragment;

  @override
  String get name;

  /// The field or top-level variable associated with this setter.
  ///
  /// If this setter was explicitly defined (is not synthetic) then the variable
  /// associated with it will be synthetic.
  PropertyInducingElement2? get variable3;
}

/// The portion of a [SetterElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SetterFragment implements ExecutableFragment {
  /// The getter that corresponds to (has the same name as) this setter, or
  /// `null` if there is no corresponding getter.
  GetterFragment? get correspondingGetter2;

  // TODO(brianwilkerson): This should override `element` to be more specific,
  //  but can't because the Impl class supports both getters and setters.
  // @override
  // SetterElement get element;

  @override
  String get name;

  /// The field or top-level variable associated with this setter.
  ///
  /// If this setter was explicitly defined (is not synthetic) then the variable
  /// associated with it will be synthetic.
  PropertyInducingFragment? get variable3;
}

/// A super formal parameter.
///
/// Super formal parameters can only be defined within a constructor element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SuperFormalParameterElement2 implements FormalParameterElement {
  /// The associated super-constructor parameter, from the super-constructor
  /// that is referenced by the implicit or explicit super-constructor
  /// invocation.
  ///
  /// Can be `null` for erroneous code - not existing super-constructor,
  /// no corresponding parameter in the super-constructor.
  FormalParameterElement? get superConstructorParameter2;
}

/// The portion of a [SuperFormalParameterElement2] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SuperFormalParameterFragment implements FormalParameterFragment {
  @override
  SuperFormalParameterElement2 get element;
}

/// A top-level function.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TopLevelFunctionElement
    implements ExecutableElement2, FragmentedElement {
  @override
  TopLevelFunctionElement get baseElement;

  @override
  TopLevelFunctionFragment get firstFragment;

  /// Whether the function represents `identical` from the `dart:core` library.
  bool get isDartCoreIdentical;

  /// Whether the function is an entry point.
  ///
  /// A top-level function is an entry point if it has the name `main`.
  bool get isEntryPoint;
}

/// The portion of a [TopLevelFunctionElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TopLevelFunctionFragment implements ExecutableFragment {
  @override
  TopLevelFunctionElement get element;

  @override
  TopLevelFunctionFragment? get nextFragment;

  @override
  TopLevelFunctionFragment? get previousFragment;
}

/// A top-level variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TopLevelVariableElement2 implements PropertyInducingElement2 {
  @override
  TopLevelVariableElement2 get baseElement;

  @override
  TopLevelVariableFragment? get firstFragment;

  /// Whether the field was explicitly marked as being external.
  bool get isExternal;
}

/// The portion of a [TopLevelVariableElement2] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TopLevelVariableFragment implements PropertyInducingFragment {
  @override
  TopLevelVariableElement2 get element;

  @override
  TopLevelVariableFragment? get nextFragment;

  @override
  TopLevelVariableFragment? get previousFragment;
}

/// A type alias (`typedef`).
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeAliasElement2
    implements TypeParameterizedElement2, TypeDefiningElement2 {
  /// If the aliased type has structure, return the corresponding element.
  /// For example, it could be [GenericFunctionTypeElement].
  ///
  /// If there is no structure, return `null`.
  Element2? get aliasedElement2;

  /// The aliased type.
  ///
  /// If non-function type aliases feature is enabled for the enclosing library,
  /// this type might be just anything. If the feature is disabled, return
  /// a [FunctionType].
  DartType get aliasedType;

  @override
  LibraryElement2 get enclosingElement2;

  @override
  TypeAliasFragment get firstFragment;

  @override
  String get name;

  /// Returns the type resulting from instantiating this typedef with the given
  /// [typeArguments] and [nullabilitySuffix].
  ///
  /// Note that this always instantiates the typedef itself, so for a
  /// [TypeAliasElement2] the returned [DartType] might still be a generic
  /// type, with type formals. For example, if the typedef is:
  ///
  ///     typedef F<T> = void Function<U>(T, U);
  ///
  /// then `F<int>` will produce `void Function<U>(int, U)`.
  DartType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  });
}

/// The portion of a [TypeAliasElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeAliasFragment
    implements TypeParameterizedFragment, TypeDefiningFragment {
  @override
  TypeAliasElement2 get element;

  @override
  LibraryFragment? get enclosingFragment;

  @override
  String get name;

  @override
  TypeAliasFragment? get nextFragment;

  @override
  TypeAliasFragment? get previousFragment;
}

/// An element that defines a type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeDefiningElement2
    implements Element2, Annotatable, FragmentedElement {
  // TODO(brianwilkerson): Evaluate to see whether this type is actually needed
  //  after converting clients to the new API.
}

/// The portion of a [TypeDefiningElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeDefiningFragment implements Fragment, Annotatable {
  @override
  TypeDefiningElement2 get element;
}

/// A type parameter.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterElement2 implements TypeDefiningElement2 {
  @override
  TypeParameterElement2 get baseElement;

  /// The type representing the bound associated with this parameter.
  ///
  /// Returns `null` if this parameter does not have an explicit bound. Being
  /// able to distinguish between an implicit and explicit bound is needed by
  /// the instantiate to bounds algorithm.`
  DartType? get bound;

  @override
  TypeParameterFragment? get firstFragment;

  @override
  LibraryElement2 get library2;

  @override
  String get name;

  /// Returns the [TypeParameterType] with the given [nullabilitySuffix] for
  /// this type parameter.
  TypeParameterType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  });
}

/// The portion of a [TypeParameterElement2] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterFragment implements TypeDefiningFragment {
  @override
  TypeParameterElement2 get element;

  @override
  String get name;

  @override
  TypeParameterFragment? get nextFragment;

  @override
  TypeParameterFragment? get previousFragment;
}

/// An element that has type parameters, such as a class, typedef, or method.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterizedElement2 implements Element2, Annotatable {
  /// If the element defines a type, indicates whether the type may safely
  /// appear without explicit type arguments as the bounds of a type parameter
  /// declaration.
  ///
  /// If the element does not define a type, returns `true`.
  bool get isSimplyBounded;

  /// The type parameters declared by this element directly.
  ///
  /// This does not include type parameters that are declared by any enclosing
  /// elements.
  List<TypeParameterElement2> get typeParameters2;
}

/// The portion of a [TypeParameterizedElement2] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterizedFragment implements Fragment, Annotatable {
  @override
  TypeParameterizedElement2 get element;

  /// The type parameters declared by this fragment directly.
  ///
  /// This does not include type parameters that are declared by any enclosing
  /// fragments.
  List<TypeParameterFragment> get typeParameters2;
}

/// A pseudo-element that represents names that are undefined.
///
/// This situation is not allowed by the language, so objects implementing this
/// interface always represent an error. As a result, most of the normal
/// operations on elements do not make sense and will return useless results.
///
/// Clients may not extend, implement or mix-in this class.
abstract class UndefinedElement2 implements Element2 {}

/// A variable.
///
/// There are more specific subclasses for more specific kinds of variables.
///
/// Clients may not extend, implement or mix-in this class.
abstract class VariableElement2 implements Element2 {
  /// Whether the variable element did not have an explicit type specified
  /// for it.
  bool get hasImplicitType;

  /// Whether the variable was declared with the 'const' modifier.
  bool get isConst;

  /// Whether the variable was declared with the 'final' modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  bool get isFinal;

  /// Whether the variable uses late evaluation semantics.
  bool get isLate;

  /// Whether the element is a static variable, as per section 8 of the Dart
  /// Language Specification:
  ///
  /// > A static variable is a variable that is not associated with a particular
  /// > instance, but rather with an entire library or class. Static variables
  /// > include library variables and class variables. Class variables are
  /// > variables whose declaration is immediately nested inside a class
  /// > declaration and includes the modifier static. A library variable is
  /// > implicitly static.
  bool get isStatic;

  /// The declared type of this variable.
  DartType get type;

  /// Returns a representation of the value of this variable.
  ///
  /// If the value had not previously been computed, it will be computed as a
  /// result of invoking this method.
  ///
  /// Returns `null` if either this variable was not declared with the 'const'
  /// modifier or if the value of this variable could not be computed because of
  /// errors.
  DartObject? computeConstantValue();
}

/// The portion of a [VariableElement2] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class VariableFragment implements Fragment {
  @override
  VariableElement2 get element;

  /// Whether the variable was declared with the 'const' modifier.
  bool get isConst;

  /// Whether the variable was declared with the 'final' modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  bool get isFinal;
}
