// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the elements and fragments that are part of the element model.
///
/// The element model describes the semantic (as opposed to syntactic) structure
/// of Dart code. The syntactic structure of the code is modeled by the
/// [AST structure](../dart_ast_ast/dart_ast_ast-library.html).
///
/// The element model consists of three closely related kinds of objects:
/// elements (instances of a subclass of [Element]), fragments (instances of a
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
/// Some elements, such as a [LocalVariableElement] are declared by a single
/// declaration, but most elements can be declared by multiple declarations. A
/// fragment represents a single declaration when the corresponding element
/// can have multiple declarations. There is no fragment for an element that can
/// only have one declaration.
///
/// As with elements, fragments are organized in a tree structure. The two
/// structures parallel each other.
///
/// Every complete element structure is rooted by an instance of the class
/// [LibraryElement]. A library element represents a single Dart library. Every
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
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart' show Name;
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/src/dart/element/inheritance_manager3.dart' show Name;

@Deprecated('Use BindPatternVariableElement instead')
typedef BindPatternVariableElement2 = BindPatternVariableElement;

@Deprecated('Use ClassElement instead')
typedef ClassElement2 = ClassElement;

@Deprecated('Use ConstructorElement instead')
typedef ConstructorElement2 = ConstructorElement;

@Deprecated('Use Element instead')
typedef Element2 = Element;

@Deprecated('Use EnumElement instead')
typedef EnumElement2 = EnumElement;

@Deprecated('Use ExecutableElement instead')
typedef ExecutableElement2 = ExecutableElement;

@Deprecated('Use ExtensionElement instead')
typedef ExtensionElement2 = ExtensionElement;

@Deprecated('Use ExtensionTypeElement instead')
typedef ExtensionTypeElement2 = ExtensionTypeElement;

@Deprecated('Use FieldElement instead')
typedef FieldElement2 = FieldElement;

@Deprecated('Use FormalParameterElement instead')
typedef FieldFormalParameterElement2 = FieldFormalParameterElement;

@Deprecated('Use FunctionTypedElement instead')
typedef FunctionTypedElement2 = FunctionTypedElement;

@Deprecated('Use GenericFunctionTypeElement instead')
typedef GenericFunctionTypeElement2 = GenericFunctionTypeElement;

@Deprecated('Use InstanceElement instead')
typedef InstanceElement2 = InstanceElement;

@Deprecated('Use InterfaceElement instead')
typedef InterfaceElement2 = InterfaceElement;

@Deprecated('Use JoinPatternVariableElement instead')
typedef JoinPatternVariableElement2 = JoinPatternVariableElement;

@Deprecated('Use LabelElement instead')
typedef LabelElement2 = LabelElement;

@Deprecated('Use LibraryElement instead')
typedef LibraryElement2 = LibraryElement;

@Deprecated('Use LocalElement instead')
typedef LocalElement2 = LocalElement;

@Deprecated('Use LocalVariableElement instead')
typedef LocalVariableElement2 = LocalVariableElement;

@Deprecated('Use MethodElement instead')
typedef MethodElement2 = MethodElement;

@Deprecated('Use MixinElement instead')
typedef MixinElement2 = MixinElement;

@Deprecated('Use MultiplyDefinedElement instead')
typedef MultiplyDefinedElement2 = MultiplyDefinedElement;

@Deprecated('Use PatternVariableElement instead')
typedef PatternVariableElement2 = PatternVariableElement;

@Deprecated('Use PrefixElement instead')
typedef PrefixElement2 = PrefixElement;

@Deprecated('Use PropertyAccessorElement instead')
typedef PropertyAccessorElement2 = PropertyAccessorElement;

@Deprecated('Use PropertyInducingElement instead')
typedef PropertyInducingElement2 = PropertyInducingElement;

@Deprecated('Use SuperFormalParameterElement instead')
typedef SuperFormalParameterElement2 = SuperFormalParameterElement;

@Deprecated('Use TopLevelVariableElement instead')
typedef TopLevelVariableElement2 = TopLevelVariableElement;

@Deprecated('Use TypeAliasElement instead')
typedef TypeAliasElement2 = TypeAliasElement;

@Deprecated('Use TypeDefiningElement instead')
typedef TypeDefiningElement2 = TypeDefiningElement;

@Deprecated('Use TypeParameterElement instead')
typedef TypeParameterElement2 = TypeParameterElement;

@Deprecated('Use TypeParameterizedElement instead')
typedef TypeParameterizedElement2 = TypeParameterizedElement;

@Deprecated('Use VariableElement instead')
typedef VariableElement2 = VariableElement;

/// An element or fragment that can have either annotations (metadata), a
/// documentation comment, or both associated with it.
@Deprecated('Use Element or Fragment directly instead')
abstract class Annotatable {
  /// The content of the documentation comment (including delimiters) for this
  /// element or fragment.
  ///
  /// If the receiver is an element that has fragments, the comment will be a
  /// concatenation of the comments from all of the fragments.
  ///
  /// Returns `null` if the receiver doesn't have documentation.
  String? get documentationComment;

  /// The metadata associated with the element or fragment.
  ///
  /// If the receiver is an element that has fragments, the list will include
  /// all of the metadata from all of the fragments.
  ///
  /// The list will be empty if the receiver does not have any metadata or if
  /// the library containing this element has not yet been fully resolved.
  Metadata get metadata;

  /// The metadata associated with the element or fragment.
  ///
  /// If the receiver is an element that has fragments, the list will include
  /// all of the metadata from all of the fragments.
  ///
  /// The list will be empty if the receiver does not have any metadata or if
  /// the library containing this element has not yet been fully resolved.
  @Deprecated('Use metadata instead')
  Metadata get metadata2;
}

/// A pattern variable that is explicitly declared.
///
/// Clients may not extend, implement or mix-in this class.
abstract class BindPatternVariableElement implements PatternVariableElement {
  @override
  BindPatternVariableFragment get firstFragment;

  @override
  List<BindPatternVariableFragment> get fragments;
}

/// The portion of a [BindPatternVariableElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class BindPatternVariableFragment implements PatternVariableFragment {
  @override
  BindPatternVariableElement get element;

  @override
  BindPatternVariableFragment? get nextFragment;

  @override
  BindPatternVariableFragment? get previousFragment;
}

/// A class.
///
/// The class can be defined by either a class declaration (with a class body),
/// or a mixin application (without a class body).
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassElement implements InterfaceElement {
  @override
  ClassFragment get firstFragment;

  @override
  List<ClassFragment> get fragments;

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

  /// Whether this class can be extended outside of its library.
  bool get isExtendableOutside;

  /// Whether the class is a final class.
  ///
  /// A class is a final class if it has an explicit `final` modifier, or the
  /// class has a `final` induced modifier and [isSealed] is `true` as well.
  /// The final modifier prohibits this class from being extended, implemented,
  /// or mixed in.
  bool get isFinal;

  /// Whether the class can be implemented outside of its library.
  bool get isImplementableOutside;

  /// Whether the class is an interface class.
  ///
  /// A class is an interface class if it has an explicit `interface` modifier,
  /// or the class has an `interface` induced modifier and [isSealed] is `true`
  /// as well. The interface modifier allows the class to be implemented, but
  /// not extended or mixed in.
  bool get isInterface;

  /// Whether the class can be mixed-in outside of its library.
  bool get isMixableOutside;

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

  /// Whether the class, assuming that it is within scope, can be extended in
  /// the given [library].
  @Deprecated('Use isExtendableOutside instead')
  bool isExtendableIn(LibraryElement library);

  /// Whether the class, assuming that it is within scope, can be extended in
  /// the given [library].
  @Deprecated('Use isExtendableOutside instead')
  bool isExtendableIn2(LibraryElement library);

  /// Whether the class, assuming that it is within scope, can be implemented in
  /// the given [library].
  @Deprecated('Use isImplementableOutside instead')
  bool isImplementableIn(LibraryElement library);

  /// Whether the class, assuming that it is within scope, can be implemented in
  /// the given [library].
  @Deprecated('Use isImplementableOutside instead')
  bool isImplementableIn2(LibraryElement library);

  /// Whether the class, assuming that it is within scope, can be mixed-in in
  /// the given [library].
  @Deprecated('Use isMixableOutside instead')
  bool isMixableIn(LibraryElement library);

  /// Whether the class, assuming that it is within scope, can be mixed-in in
  /// the given [library].
  @Deprecated('Use isMixableOutside instead')
  bool isMixableIn2(LibraryElement library);
}

/// The portion of a [ClassElement] contributed by a single declaration.
///
/// The fragment can be defined by either a class declaration (with a class
/// body), or a mixin application (without a class body).
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassFragment implements InterfaceFragment {
  @override
  ClassElement get element;

  @override
  ClassFragment? get nextFragment;

  @override
  ClassFragment? get previousFragment;
}

/// An element representing a constructor defined by a class, enum, or extension
/// type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorElement implements ExecutableElement {
  @override
  ConstructorElement get baseElement;

  @override
  InterfaceElement get enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  InterfaceElement get enclosingElement2;

  @override
  ConstructorFragment get firstFragment;

  @override
  List<ConstructorFragment> get fragments;

  /// Whether the constructor is a const constructor.
  bool get isConst;

  /// Whether the constructor can be used as a default constructor - unnamed,
  /// and has no required parameters.
  bool get isDefaultConstructor;

  /// Whether the constructor represents a factory constructor.
  bool get isFactory;

  /// Whether the constructor represents a generative constructor.
  bool get isGenerative;

  /// The name of this constructor.
  ///
  /// The name of the unnamed constructor is `new`.
  @override
  String? get name;

  /// The name of this constructor.
  ///
  /// The name of the unnamed constructor is `new`.
  @Deprecated('Use name instead')
  @override
  String? get name3;

  /// The constructor to which this constructor is redirecting.
  ///
  /// Returns `null` if this constructor does not redirect to another
  /// constructor or if the library containing this constructor has not yet been
  /// resolved.
  ConstructorElement? get redirectedConstructor;

  /// The constructor to which this constructor is redirecting.
  ///
  /// Returns `null` if this constructor does not redirect to another
  /// constructor or if the library containing this constructor has not yet been
  /// resolved.
  @Deprecated('Use redirectedConstructor instead')
  ConstructorElement? get redirectedConstructor2;

  @override
  InterfaceType get returnType;

  /// The constructor of the superclass that this constructor invokes, or
  /// `null` if this constructor redirects to another constructor, or if the
  /// library containing this constructor has not yet been resolved.
  ConstructorElement? get superConstructor;

  /// The constructor of the superclass that this constructor invokes, or
  /// `null` if this constructor redirects to another constructor, or if the
  /// library containing this constructor has not yet been resolved.
  @Deprecated('Use superConstructor instead')
  ConstructorElement? get superConstructor2;
}

/// The portion of a [ConstructorElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorFragment implements ExecutableFragment {
  @override
  ConstructorElement get element;

  @override
  InstanceFragment? get enclosingFragment;

  @override
  String get name;

  @Deprecated('Use name instead')
  @override
  String get name2;

  @override
  ConstructorFragment? get nextFragment;

  /// The offset of the constructor name.
  ///
  /// For a named constructor (e.g., `ClassName.foo()``), this is the offset to
  /// the part of the constructor name that follows the `.`. For an unnamed
  /// constructor (e.g., `ClassName();`), this is the offset of the class name
  /// that appears in the constructor declaration.
  ///
  /// For an implicit constructor, this is the offset of the class name in the
  /// class declaration.
  @override
  int get offset;

  /// The offset of the `.` before the name.
  ///
  /// It is `null` if the fragment is synthetic, or does not specify an
  /// explicit name, even if [name] is `new` in this case.
  int? get periodOffset;

  @override
  ConstructorFragment? get previousFragment;

  /// The specified name of the type (e.g. class).
  ///
  /// In valid code it is the name of the [enclosingFragment], however it
  /// could be anything in invalid code, e.g. `class A { A2.named(); }`.
  ///
  /// If the fragment is synthetic, the type name is the name of the
  /// enclosing type, which itself can be `null` if its name token is
  /// synthetic.
  String? get typeName;

  /// The offset of the type (e.g. class) name.
  ///
  /// It is `null` if the fragment is synthetic.
  int? get typeNameOffset;
}

/// Meaning of a URI referenced in a directive.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUri {}

/// [DirectiveUriWithSource] that references a [LibraryElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithLibrary extends DirectiveUriWithSource {
  /// The library referenced by the [source].
  LibraryElement get library;

  /// The library referenced by the [source].
  @Deprecated('Use library instead')
  LibraryElement get library2;
}

/// [DirectiveUriWithRelativeUriString] that can be parsed into a relative URI.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithRelativeUri
    extends DirectiveUriWithRelativeUriString {
  /// The relative URI, parsed from [relativeUriString].
  Uri get relativeUri;
}

/// [DirectiveUri] for which we can get its relative URI string.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithRelativeUriString extends DirectiveUri {
  /// The relative URI string specified in code.
  String get relativeUriString;
}

/// [DirectiveUriWithRelativeUri] that resolves to a [Source].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithSource extends DirectiveUriWithRelativeUri {
  /// The result of resolving [relativeUri] against the enclosing URI.
  Source get source;
}

/// [DirectiveUriWithSource] that references a [LibraryFragment].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithUnit extends DirectiveUriWithSource {
  /// The library fragment referenced by the [source].
  LibraryFragment get libraryFragment;
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
abstract class Element {
  /// The non-[SubstitutedElementImpl] version of this element.
  ///
  /// If the receiver is a view on an element, such as a method from an
  /// interface type with substituted type parameters, this getter will return
  /// the corresponding element from the class, without any substitutions.
  ///
  /// If the receiver is already a non-[SubstitutedElementImpl] element (or a
  /// synthetic element, such as a synthetic property accessor), this getter
  /// will return the receiver.
  Element get baseElement;

  /// The children of this element.
  ///
  /// There is no guarantee of the order in which the children will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<Element> get children;

  /// The children of this element.
  ///
  /// There is no guarantee of the order in which the children will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  @Deprecated('Use children instead')
  List<Element> get children2;

  /// The display name of this element, or an empty string if the element does
  /// not have a name.
  ///
  /// In most cases the name and the display name are the same. They differ in
  /// cases such as setters where the `name` of some setter (`set s(x)`) is `s=`
  /// but the `displayName` is `s`.
  String get displayName;

  /// The content of the documentation comment (including delimiters) for this
  /// element.
  ///
  /// This is a concatenation of the comments from all of the fragments.
  ///
  /// Returns `null` if the element doesn't have documentation.
  String? get documentationComment;

  /// The element that either physically or logically encloses this element.
  ///
  /// Returns `null` if this element is a library because libraries are the
  /// top-level elements in the model.
  Element? get enclosingElement;

  /// The element that either physically or logically encloses this element.
  ///
  /// Returns `null` if this element is a library because libraries are the
  /// top-level elements in the model.
  @Deprecated('Use enclosingElement instead')
  Element? get enclosingElement2;

  /// The first fragment in the chain of fragments that are merged to make this
  /// element.
  ///
  /// The other fragments in the chain can be accessed using successive
  /// invocations of [Fragment.nextFragment].
  Fragment get firstFragment;

  /// The fragments this element consists of.
  List<Fragment> get fragments;

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
  LibraryElement? get library;

  /// Library that contains this element.
  ///
  /// This will be the element itself if it's a library element. This will be
  /// `null` if this element is a [MultiplyDefinedElement] that isn't contained
  /// in a single library.
  @Deprecated('Use library instead')
  LibraryElement? get library2;

  /// The name to use for lookup in maps.
  ///
  /// It is usually the same as [name], with a few special cases.
  ///
  /// Just like [name], it can be `null` if the element does not have
  /// a name, for example an unnamed extension, or because of parser recovery.
  ///
  /// For a [SetterElement] the result has `=` at the end.
  ///
  /// For an unary operator `-` the result is `unary-`.
  /// For a binary operator `-` the result is just `-`.
  String? get lookupName;

  /// The metadata associated with the element.
  ///
  /// It includes all annotations from all of the fragments.
  ///
  /// The list will be empty if the element does not have any metadata.
  Metadata get metadata;

  /// The name of this element.
  ///
  /// Returns `null` if this element doesn't have a name.
  ///
  /// See [Fragment.name] for details.
  String? get name;

  /// The name of this element.
  ///
  /// Returns `null` if this element doesn't have a name.
  ///
  /// See [Fragment.name] for details.
  @Deprecated('Use name instead')
  String? get name3;

  /// The non-synthetic element that caused this element to be created.
  ///
  /// If this element is not synthetic, then the element itself is returned.
  ///
  /// If this element is synthetic, then the corresponding non-synthetic
  /// element is returned. For example, for a synthetic getter of a
  /// non-synthetic field the field is returned; for a synthetic constructor
  /// the enclosing class is returned.
  Element get nonSynthetic;

  /// The non-synthetic element that caused this element to be created.
  ///
  /// If this element is not synthetic, then the element itself is returned.
  ///
  /// If this element is synthetic, then the corresponding non-synthetic
  /// element is returned. For example, for a synthetic getter of a
  /// non-synthetic field the field is returned; for a synthetic constructor
  /// the enclosing class is returned.
  @Deprecated('Use nonSynthetic instead')
  Element get nonSynthetic2;

  /// The analysis session in which this element is defined.
  AnalysisSession? get session;

  /// The version where the associated SDK API was added.
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

  /// Uses the given [visitor] to visit this element.
  ///
  /// Returns the value returned by the visitor as a result of visiting this
  /// element.
  T? accept<T>(ElementVisitor2<T> visitor);

  /// Uses the given [visitor] to visit this element.
  ///
  /// Returns the value returned by the visitor as a result of visiting this
  /// element.
  @Deprecated('Use accept instead')
  T? accept2<T>(ElementVisitor2<T> visitor);

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
  String displayString({bool multiline = false, bool preferTypeAlias = false});

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
  @Deprecated('Use displayString instead')
  String displayString2({bool multiline = false, bool preferTypeAlias = false});

  /// Returns a display name for the given element that includes the path to the
  /// compilation unit in which the type is defined. If [shortName] is `null`
  /// then [displayName] will be used as the name of this element. Otherwise
  /// the provided name will be used.
  String getExtendedDisplayName({String? shortName});

  /// Returns a display name for the given element that includes the path to the
  /// compilation unit in which the type is defined. If [shortName] is `null`
  /// then [displayName] will be used as the name of this element. Otherwise
  /// the provided name will be used.
  @Deprecated('Use getExtendedDisplayName instead')
  String getExtendedDisplayName2({String? shortName});

  /// Whether the element, assuming that it is within scope, is accessible to
  /// code in the given [library].
  ///
  /// This is defined by the Dart Language Specification in section 6.2:
  /// <blockquote>
  /// A declaration <i>m</i> is accessible to a library <i>L</i> if <i>m</i> is
  /// declared in <i>L</i> or if <i>m</i> is public.
  /// </blockquote>
  bool isAccessibleIn(LibraryElement library);

  /// Whether the element, assuming that it is within scope, is accessible to
  /// code in the given [library].
  ///
  /// This is defined by the Dart Language Specification in section 6.2:
  /// <blockquote>
  /// A declaration <i>m</i> is accessible to a library <i>L</i> if <i>m</i> is
  /// declared in <i>L</i> or if <i>m</i> is public.
  /// </blockquote>
  @Deprecated('Use isAccessibleIn instead')
  bool isAccessibleIn2(LibraryElement library);

  /// Returns either this element or the most immediate ancestor of this element
  /// for which the [predicate] returns `true`.
  ///
  /// Returns `null` if there is no such element.
  Element? thisOrAncestorMatching(bool Function(Element) predicate);

  /// Returns either this element or the most immediate ancestor of this element
  /// for which the [predicate] returns `true`.
  ///
  /// Returns `null` if there is no such element.
  @Deprecated('Use thisOrAncestorMatching instead')
  Element? thisOrAncestorMatching2(bool Function(Element) predicate);

  /// Returns either this element or the most immediate ancestor of this element
  /// that has the given type.
  ///
  /// Returns `null` if there is no such element.
  E? thisOrAncestorOfType<E extends Element>();

  /// Returns either this element or the most immediate ancestor of this element
  /// that has the given type.
  ///
  /// Returns `null` if there is no such element.
  @Deprecated('Use thisOrAncestorOfType instead')
  E? thisOrAncestorOfType2<E extends Element>();

  /// Uses the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  void visitChildren<T>(ElementVisitor2<T> visitor);

  /// Uses the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  @Deprecated('Use visitChildren instead')
  void visitChildren2<T>(ElementVisitor2<T> visitor);
}

/// A single annotation associated with an element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ElementAnnotation {
  /// The errors that were produced while computing a value for this
  /// annotation, or `null` if no value has been computed.
  ///
  /// If a value has been produced but no errors were generated, then the
  /// list will be empty.
  List<Diagnostic>? get constantEvaluationErrors;

  /// Returns the element referenced by this annotation.
  ///
  /// In valid code this element can be a [GetterElement] of a constant
  /// top-level variable, or a constant static field of a class; or a
  /// constant [ConstructorElement].
  ///
  /// In invalid code this element can be `null`, or a reference to any
  /// other element.
  Element? get element;

  /// Returns the element referenced by this annotation.
  ///
  /// In valid code this element can be a [GetterElement] of a constant
  /// top-level variable, or a constant static field of a class; or a
  /// constant [ConstructorElement].
  ///
  /// In invalid code this element can be `null`, or a reference to any
  /// other element.
  @Deprecated('Use element instead')
  Element? get element2;

  /// Whether the annotation marks the associated function as always throwing.
  bool get isAlwaysThrows;

  /// Whether the annotation marks the associated element as not needing to be
  /// awaited.
  bool get isAwaitNotRequired;

  /// Whether the annotation marks the associated element as being deprecated.
  bool get isDeprecated;

  /// Whether the annotation marks the associated element as not to be stored.
  bool get isDoNotStore;

  /// Whether the annotation marks the associated member as not to be used.
  bool get isDoNotSubmit;

  /// Whether the annotation marks the associated element as experimental.
  bool get isExperimental;

  /// Whether the annotation marks the associated member as a factory.
  bool get isFactory;

  /// Whether the annotation marks the associated class and its subclasses as
  /// being immutable.
  bool get isImmutable;

  /// Whether the annotation marks the associated element as being internal to
  /// its package.
  bool get isInternal;

  /// Whether the annotation marks the associated member as running a single
  /// test.
  bool get isIsTest;

  /// Whether the annotation marks the associated member as running a test
  /// group.
  bool get isIsTestGroup;

  /// Whether the annotation marks the associated element with the `JS`
  /// annotation.
  bool get isJS;

  /// Whether the annotation marks the associated constructor as being literal.
  bool get isLiteral;

  /// Whether the annotation marks the associated returned element as
  /// requiring a constant argument.
  bool get isMustBeConst;

  /// Whether the annotation marks the associated member as requiring
  /// subclasses to override this member.
  bool get isMustBeOverridden;

  /// Whether the annotation marks the associated member as requiring
  /// overriding methods to call super.
  bool get isMustCallSuper;

  /// Whether the annotation marks the associated member as being non-virtual.
  bool get isNonVirtual;

  /// Whether the annotation marks the associated type as having "optional"
  /// type arguments.
  bool get isOptionalTypeArgs;

  /// Whether the annotation marks the associated method as being expected to
  /// override an inherited method.
  bool get isOverride;

  /// Whether the annotation marks the associated member as being protected.
  bool get isProtected;

  /// Whether the annotation marks the associated class as implementing a proxy
  /// object.
  bool get isProxy;

  /// Whether the annotation marks the associated member as redeclaring.
  bool get isRedeclare;

  /// Whether the annotation marks the associated member as being reopened.
  bool get isReopen;

  /// Whether the annotation marks the associated member as being required.
  bool get isRequired;

  /// Whether the annotation marks the associated class as being sealed.
  bool get isSealed;

  /// Whether the annotation marks the associated class as being intended to
  /// be used as an annotation.
  bool get isTarget;

  /// Whether the annotation marks the associated returned element as
  /// requiring use.
  bool get isUseResult;

  /// Whether the annotation marks the associated member as being visible for
  /// overriding only.
  bool get isVisibleForOverriding;

  /// Whether the annotation marks the associated member as being visible for
  /// template files.
  bool get isVisibleForTemplate;

  /// Whether the annotation marks the associated member as being visible for
  /// testing.
  bool get isVisibleForTesting;

  /// Whether the annotation marks the associated member as being visible
  /// outside of template files.
  bool get isVisibleOutsideTemplate;

  /// Whether the annotation marks the associated member as being a widget
  /// factory.
  bool get isWidgetFactory;

  /// The library fragment that contains this annotation.
  LibraryFragment get libraryFragment;

  /// Returns a representation of the value of this annotation, forcing the
  /// value to be computed if it had not previously been computed, or `null`
  /// if the value of this annotation could not be computed because of errors.
  DartObject? computeConstantValue();

  /// Returns a textual description of this annotation in a form approximating
  /// valid source.
  ///
  /// The returned string will not be valid source primarily in the case where
  /// the annotation itself is not well-formed.
  String toSource();
}

/// A directive within a library fragment.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ElementDirective
    implements
        Annotatable // ignore:deprecated_member_use_from_same_package
        {
  /// The library fragment that contains this object.
  LibraryFragment get libraryFragment;

  /// The metadata associated with the element or fragment.
  ///
  /// If the receiver is an element that has fragments, the list will include
  /// all of the metadata from all of the fragments.
  ///
  /// The list will be empty if the receiver does not have any metadata or if
  /// the library containing this element has not yet been fully resolved.
  @override
  Metadata get metadata;

  /// The interpretation of the URI specified in the directive.
  DirectiveUri get uri;
}

/// The kind of elements in the element model.
///
/// Clients may not extend, implement or mix-in this class.
class ElementKind implements Comparable<ElementKind> {
  static const ElementKind AUGMENTATION_IMPORT = ElementKind(
    'AUGMENTATION_IMPORT',
    0,
    "augmentation import",
  );

  static const ElementKind CLASS = ElementKind('CLASS', 1, "class");

  static const ElementKind CLASS_AUGMENTATION = ElementKind(
    'CLASS_AUGMENTATION',
    2,
    "class augmentation",
  );

  static const ElementKind COMPILATION_UNIT = ElementKind(
    'COMPILATION_UNIT',
    3,
    "compilation unit",
  );

  static const ElementKind CONSTRUCTOR = ElementKind(
    'CONSTRUCTOR',
    4,
    "constructor",
  );

  static const ElementKind DYNAMIC = ElementKind('DYNAMIC', 5, "<dynamic>");

  static const ElementKind ENUM = ElementKind('ENUM', 6, "enum");

  static const ElementKind ERROR = ElementKind('ERROR', 7, "<error>");

  static const ElementKind EXPORT = ElementKind(
    'EXPORT',
    8,
    "export directive",
  );

  static const ElementKind EXTENSION = ElementKind('EXTENSION', 9, "extension");

  static const ElementKind EXTENSION_TYPE = ElementKind(
    'EXTENSION_TYPE',
    10,
    "extension type",
  );

  static const ElementKind FIELD = ElementKind('FIELD', 11, "field");

  static const ElementKind FUNCTION = ElementKind('FUNCTION', 12, "function");

  static const ElementKind GENERIC_FUNCTION_TYPE = ElementKind(
    'GENERIC_FUNCTION_TYPE',
    13,
    'generic function type',
  );

  static const ElementKind GETTER = ElementKind('GETTER', 14, "getter");

  static const ElementKind IMPORT = ElementKind(
    'IMPORT',
    15,
    "import directive",
  );

  static const ElementKind LABEL = ElementKind('LABEL', 16, "label");

  static const ElementKind LIBRARY = ElementKind('LIBRARY', 17, "library");

  static const ElementKind LIBRARY_AUGMENTATION = ElementKind(
    'LIBRARY_AUGMENTATION',
    18,
    "library augmentation",
  );

  static const ElementKind LOCAL_VARIABLE = ElementKind(
    'LOCAL_VARIABLE',
    19,
    "local variable",
  );

  static const ElementKind METHOD = ElementKind('METHOD', 20, "method");

  static const ElementKind MIXIN = ElementKind('MIXIN', 21, "mixin");

  static const ElementKind NAME = ElementKind('NAME', 22, "<name>");

  static const ElementKind NEVER = ElementKind('NEVER', 23, "<never>");

  static const ElementKind PARAMETER = ElementKind(
    'PARAMETER',
    24,
    "parameter",
  );

  static const ElementKind PART = ElementKind('PART', 25, "part");

  static const ElementKind PREFIX = ElementKind('PREFIX', 26, "import prefix");

  static const ElementKind RECORD = ElementKind('RECORD', 27, "record");

  static const ElementKind SETTER = ElementKind('SETTER', 28, "setter");

  static const ElementKind TOP_LEVEL_VARIABLE = ElementKind(
    'TOP_LEVEL_VARIABLE',
    29,
    "top level variable",
  );

  static const ElementKind FUNCTION_TYPE_ALIAS = ElementKind(
    'FUNCTION_TYPE_ALIAS',
    30,
    "function type alias",
  );

  static const ElementKind TYPE_PARAMETER = ElementKind(
    'TYPE_PARAMETER',
    31,
    "type parameter",
  );

  static const ElementKind TYPE_ALIAS = ElementKind(
    'TYPE_ALIAS',
    32,
    "type alias",
  );

  static const ElementKind UNIVERSE = ElementKind('UNIVERSE', 33, "<universe>");

  static const List<ElementKind> values = [
    CLASS,
    CLASS_AUGMENTATION,
    COMPILATION_UNIT,
    CONSTRUCTOR,
    DYNAMIC,
    ENUM,
    ERROR,
    EXPORT,
    EXTENSION,
    EXTENSION_TYPE,
    FIELD,
    FUNCTION,
    GENERIC_FUNCTION_TYPE,
    GETTER,
    IMPORT,
    LABEL,
    LIBRARY,
    LOCAL_VARIABLE,
    METHOD,
    MIXIN,
    NAME,
    NEVER,
    PARAMETER,
    PART,
    PREFIX,
    RECORD,
    SETTER,
    TOP_LEVEL_VARIABLE,
    FUNCTION_TYPE_ALIAS,
    TYPE_PARAMETER,
    UNIVERSE,
  ];

  /// The name of this element kind.
  final String name;

  /// The ordinal value of the element kind.
  final int ordinal;

  /// The name displayed in the UI for this kind of element.
  final String displayName;

  /// Initialize a newly created element kind to have the given [displayName].
  const ElementKind(this.name, this.ordinal, this.displayName);

  @override
  int compareTo(ElementKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/// An object that can be used to visit an element structure.
///
/// Clients may not extend, implement or mix-in this class. There are classes
/// that implement this interface that provide useful default behaviors in
/// `package:analyzer/dart/element/visitor.dart`. A couple of the most useful
/// include
/// * SimpleElementVisitor which implements every visit method by doing nothing,
/// * RecursiveElementVisitor which will cause every node in a structure to be
///   visited, and
/// * ThrowingElementVisitor which implements every visit method by throwing an
///   exception.
abstract class ElementVisitor2<R> {
  R? visitClassElement(ClassElement element);

  R? visitConstructorElement(ConstructorElement element);

  R? visitEnumElement(EnumElement element);

  R? visitExtensionElement(ExtensionElement element);

  R? visitExtensionTypeElement(ExtensionTypeElement element);

  R? visitFieldElement(FieldElement element);

  R? visitFieldFormalParameterElement(FieldFormalParameterElement element);

  R? visitFormalParameterElement(FormalParameterElement element);

  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element);

  R? visitGetterElement(GetterElement element);

  R? visitLabelElement(LabelElement element);

  R? visitLibraryElement(LibraryElement element);

  R? visitLocalFunctionElement(LocalFunctionElement element);

  R? visitLocalVariableElement(LocalVariableElement element);

  R? visitMethodElement(MethodElement element);

  R? visitMixinElement(MixinElement element);

  R? visitMultiplyDefinedElement(MultiplyDefinedElement element);

  R? visitPrefixElement(PrefixElement element);

  R? visitSetterElement(SetterElement element);

  R? visitSuperFormalParameterElement(SuperFormalParameterElement element);

  R? visitTopLevelFunctionElement(TopLevelFunctionElement element);

  R? visitTopLevelVariableElement(TopLevelVariableElement element);

  R? visitTypeAliasElement(TypeAliasElement element);

  R? visitTypeParameterElement(TypeParameterElement element);
}

/// An element that represents an enum.
///
/// Clients may not extend, implement or mix-in this class.
abstract class EnumElement implements InterfaceElement {
  /// The constants defined by the enum.
  List<FieldElement> get constants;

  /// The constants defined by the enum.
  @Deprecated('Use constants instead')
  List<FieldElement> get constants2;

  @override
  EnumFragment get firstFragment;

  @override
  List<EnumFragment> get fragments;
}

/// The portion of an [EnumElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class EnumFragment implements InterfaceFragment {
  /// The constants defined by this fragment of the enum.
  List<FieldElement> get constants;

  /// The constants defined by this fragment of the enum.
  @Deprecated('Use constants instead')
  List<FieldElement> get constants2;

  @override
  EnumElement get element;

  @override
  EnumFragment? get nextFragment;

  @override
  EnumFragment? get previousFragment;
}

/// An element representing an executable object, including functions, methods,
/// constructors, getters, and setters.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExecutableElement implements FunctionTypedElement {
  @override
  ExecutableElement get baseElement;

  @override
  ExecutableFragment get firstFragment;

  @override
  List<ExecutableFragment> get fragments;

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

/// The portion of an [ExecutableElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExecutableFragment implements FunctionTypedFragment {
  @override
  ExecutableElement get element;

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

  /// Whether this fragment is synthetic.
  ///
  /// A synthetic fragment is a fragment that is not represented in the source
  /// code explicitly, but is implied by the source code, such as the default
  /// constructor for a class that does not explicitly define any constructors.
  bool get isSynthetic;

  @override
  LibraryFragment get libraryFragment;

  @override
  ExecutableFragment? get nextFragment;

  @override
  ExecutableFragment? get previousFragment;
}

/// An extension.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExtensionElement implements InstanceElement {
  /// The type that is extended by this extension.
  DartType get extendedType;

  @override
  ExtensionFragment get firstFragment;

  @override
  List<ExtensionFragment> get fragments;
}

/// The portion of an [ExtensionElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class ExtensionFragment implements InstanceFragment {
  @override
  ExtensionElement get element;

  @override
  ExtensionFragment? get nextFragment;

  /// The offset of the extension name.
  ///
  /// If the extension has no name, this is the offset of the `extension`
  /// keyword.
  @override
  int get offset;

  @override
  ExtensionFragment? get previousFragment;
}

/// An extension type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExtensionTypeElement implements InterfaceElement {
  @override
  ExtensionTypeFragment get firstFragment;

  @override
  List<ExtensionTypeFragment> get fragments;

  /// The primary constructor of this extension.
  ConstructorElement get primaryConstructor;

  /// The primary constructor of this extension.
  @Deprecated('Use primaryConstructor instead')
  ConstructorElement get primaryConstructor2;

  /// The representation of this extension.
  FieldElement get representation;

  /// The representation of this extension.
  @Deprecated('Use representation instead')
  FieldElement get representation2;

  /// The extension type erasure, obtained by recursively replacing every
  /// subterm which is an extension type by the corresponding representation
  /// type.
  DartType get typeErasure;
}

/// The portion of an [ExtensionTypeElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class ExtensionTypeFragment implements InterfaceFragment {
  @override
  ExtensionTypeElement get element;

  @override
  ExtensionTypeFragment? get nextFragment;

  @override
  ExtensionTypeFragment? get previousFragment;

  /// The primary constructor of this extension.
  @Deprecated('Use ExtensionTypeElement.primaryConstructor instead')
  ConstructorFragment get primaryConstructor;

  /// The primary constructor of this extension.
  @Deprecated('Use primaryConstructor instead')
  ConstructorFragment get primaryConstructor2;

  /// The representation of this extension.
  @Deprecated('Use ExtensionTypeElement.representation instead')
  FieldFragment get representation;

  /// The representation of this extension.
  @Deprecated('Use representation instead')
  FieldFragment get representation2;
}

/// A field defined within a class, enum, extension, or mixin.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FieldElement implements PropertyInducingElement {
  @override
  FieldElement get baseElement;

  @override
  InstanceElement get enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  InstanceElement get enclosingElement2;

  @override
  FieldFragment get firstFragment;

  @override
  List<FieldFragment> get fragments;

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
abstract class FieldFormalParameterElement implements FormalParameterElement {
  /// The field element associated with this field formal parameter.
  ///
  /// Returns `null` if the parameter references a field that doesn't exist.
  FieldElement? get field;

  /// The field element associated with this field formal parameter.
  ///
  /// Returns `null` if the parameter references a field that doesn't exist.
  @Deprecated('Use field instead')
  FieldElement? get field2;

  @override
  FieldFormalParameterFragment get firstFragment;

  @override
  List<FieldFormalParameterFragment> get fragments;
}

/// The portion of a [FieldFormalParameterElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class FieldFormalParameterFragment implements FormalParameterFragment {
  @override
  FieldFormalParameterElement get element;

  @override
  FieldFormalParameterFragment? get nextFragment;

  @override
  FieldFormalParameterFragment? get previousFragment;
}

/// The portion of a [FieldElement] contributed by a single declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class FieldFragment implements PropertyInducingFragment {
  @override
  FieldElement get element;

  @override
  FieldFragment? get nextFragment;

  /// The offset of the field name.
  ///
  /// If the field declaration is implicit, this is the offset of the name of
  /// the containing element (e.g., for the `values` field of an enum, this is
  /// the offset of the enum name).
  @override
  int get offset;

  @override
  FieldFragment? get previousFragment;
}

/// A formal parameter defined by an executable element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FormalParameterElement
    implements
        VariableElement,
        Annotatable, // ignore:deprecated_member_use_from_same_package
        LocalElement {
  @override
  FormalParameterElement get baseElement;

  /// The code of the default value.
  ///
  /// Returns `null` if no default value.
  String? get defaultValueCode;

  @override
  FormalParameterFragment get firstFragment;

  /// The formal parameters defined by this formal parameter.
  ///
  /// A parameter will only define other parameters if it is a function typed
  /// formal parameter.
  List<FormalParameterElement> get formalParameters;

  @override
  List<FormalParameterFragment> get fragments;

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
  List<TypeParameterElement> get typeParameters;

  /// The type parameters defined by this parameter.
  ///
  /// A parameter will only define type parameters if it is a function typed
  /// parameter.
  @Deprecated('Use typeParameters instead')
  List<TypeParameterElement> get typeParameters2;

  /// Appends the type, name and possibly the default value of this parameter
  /// to the given [buffer].
  void appendToWithoutDelimiters(StringBuffer buffer);

  /// Appends the type, name and possibly the default value of this parameter
  /// to the given [buffer].
  @Deprecated('Use appendToWithoutDelimiters instead')
  void appendToWithoutDelimiters2(StringBuffer buffer);
}

/// The portion of a [FormalParameterElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class FormalParameterFragment
    implements
        VariableFragment,
        Annotatable, // ignore:deprecated_member_use_from_same_package
        LocalFragment {
  @override
  FormalParameterElement get element;

  @override
  FormalParameterFragment? get nextFragment;

  /// The offset of the parameter name.
  ///
  /// If the parameter is implicit (because it's the parameter of an implicit
  /// setter that's induced by a field or top level variable declaration), this
  /// is the offset of the field or top level variable name.
  @override
  int get offset;

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
  List<Fragment> get children;

  /// The children of this fragment.
  ///
  /// There is no guarantee of the order in which the children will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  @Deprecated('Use children instead')
  List<Fragment> get children3;

  /// The content of the documentation comment (including delimiters) for this
  /// fragment.
  ///
  /// Returns `null` if the fragment doesn't have documentation.
  String? get documentationComment;

  /// The element composed from this fragment and possibly other fragments.
  Element get element;

  /// The fragment that either physically or logically encloses this fragment.
  ///
  /// Returns `null` if this fragment is the root fragment of a library because
  /// there are no fragments above the root fragment of a library.
  Fragment? get enclosingFragment;

  /// The library fragment that contains this fragment.
  ///
  /// This will be the fragment itself if it is a library fragment.
  LibraryFragment? get libraryFragment;

  /// The metadata associated with the fragment.
  ///
  /// The list will be empty if the fragment does not have any metadata.
  Metadata get metadata;

  /// The name of the fragment.
  ///
  /// Never empty.
  ///
  /// If a fragment, e.g. an [ExtensionFragment], does not have a name,
  /// then the name is `null`.
  ///
  /// For an unnamed [ConstructorFragment] the name is `new`, but [nameOffset]
  /// is `null`. If there is an explicit `ClassName.new`, the name is also
  /// `new`, and [nameOffset] is not `null`. For a synthetic default unnamed
  /// [ConstructorElement] there is always a synthetic [ConstructorFragment]
  /// with the name `new`, and [nameOffset] is `null`.
  ///
  /// If the fragment declaration node does not have the name specified, and
  /// the parser inserted a synthetic token, then the name is `null`, and
  /// [nameOffset] is `null`.
  ///
  /// For a synthetic [GetterFragment] or [SetterFragment] the name is the
  /// name of the corresponding non-synthetic [PropertyInducingFragment],
  /// which is usually not `null`, but could be. And `nameOffset2` is `null`
  /// for such synthetic fragments.
  ///
  /// For a [SetterFragment] this is the identifier, without `=` at the end.
  ///
  /// For both unary and binary `-` operator this is `-`.
  String? get name;

  /// The name of the fragment.
  ///
  /// Never empty.
  ///
  /// If a fragment, e.g. an [ExtensionFragment], does not have a name,
  /// then the name is `null`.
  ///
  /// For an unnamed [ConstructorFragment] the name is `new`, but [nameOffset]
  /// is `null`. If there is an explicit `ClassName.new`, the name is also
  /// `new`, and [nameOffset] is not `null`. For a synthetic default unnamed
  /// [ConstructorElement] there is always a synthetic [ConstructorFragment]
  /// with the name `new`, and [nameOffset] is `null`.
  ///
  /// If the fragment declaration node does not have the name specified, and
  /// the parser inserted a synthetic token, then the name is `null`, and
  /// [nameOffset] is `null`.
  ///
  /// For a synthetic [GetterFragment] or [SetterFragment] the name is the
  /// name of the corresponding non-synthetic [PropertyInducingFragment],
  /// which is usually not `null`, but could be. And `nameOffset2` is `null`
  /// for such synthetic fragments.
  ///
  /// For a [SetterFragment] this is the identifier, without `=` at the end.
  ///
  /// For both unary and binary `-` operator this is `-`.
  @Deprecated('Use name instead')
  String? get name2;

  /// The offset of the [name] of this element.
  ///
  /// If a fragment, e.g. an [ExtensionFragment], does not have a name,
  /// then the name offset is `null`.
  ///
  /// If the fragment declaration node does not have the name specified, and
  /// the parser inserted a synthetic token, then the name is `null`, and
  /// the name offset is `null`.
  ///
  /// For a synthetic fragment, e.g. [ConstructorFragment] the name offset
  /// is `null`.
  int? get nameOffset;

  /// The offset of the [name] of this element.
  ///
  /// If a fragment, e.g. an [ExtensionFragment], does not have a name,
  /// then the name offset is `null`.
  ///
  /// If the fragment declaration node does not have the name specified, and
  /// the parser inserted a synthetic token, then the name is `null`, and
  /// the name offset is `null`.
  ///
  /// For a synthetic fragment, e.g. [ConstructorFragment] the name offset
  /// is `null`.
  @Deprecated('Use nameOffset instead')
  int? get nameOffset2;

  /// The next fragment in the augmentation chain.
  ///
  /// Returns `null` if this is the last fragment in the chain.
  Fragment? get nextFragment;

  /// A canonical offset to the fragment within the source file.
  ///
  /// If the fragment has a name, this is equal to [nameOffset]. Otherwise it
  /// is the offset of some character within the fragment; see subclasses for
  /// more information.
  ///
  /// If the fragment is of a kind that would normally have a name, but there is
  /// no name due to error recovery, then the exact offset is unspecified, but
  /// is guaranteed to be within the span of the tokens that constitute the
  /// fragment's declaration.
  int get offset;

  /// The previous fragment in the augmentation chain.
  ///
  /// Returns `null` if this is the first fragment in the chain.
  Fragment? get previousFragment;
}

/// An element that has a [FunctionType] as its [type].
///
/// This also provides convenient access to the parameters and return type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypedElement implements TypeParameterizedElement {
  @override
  FunctionTypedFragment get firstFragment;

  /// The formal parameters defined by this element.
  List<FormalParameterElement> get formalParameters;

  @override
  List<FunctionTypedFragment> get fragments;

  /// The return type defined by this element.
  DartType get returnType;

  /// The type defined by this element.
  FunctionType get type;
}

/// The portion of a [FunctionTypedElement] contributed by a single declaration.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class FunctionTypedFragment implements TypeParameterizedFragment {
  @override
  FunctionTypedElement get element;

  /// The formal parameters defined by this fragment.
  List<FormalParameterFragment> get formalParameters;

  @override
  FunctionTypedFragment? get nextFragment;

  @override
  FunctionTypedFragment? get previousFragment;
}

/// The pseudo-declaration that defines a generic function type.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class GenericFunctionTypeElement implements FunctionTypedElement {
  @override
  GenericFunctionTypeFragment get firstFragment;

  @override
  List<GenericFunctionTypeFragment> get fragments;
}

/// The portion of a [GenericFunctionTypeElement] coming from a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class GenericFunctionTypeFragment implements FunctionTypedFragment {
  @override
  GenericFunctionTypeElement get element;

  @override
  GenericFunctionTypeFragment? get nextFragment;

  /// The offset of the generic function type.
  ///
  /// Generic function types are not named, so the offset is the offset of the
  /// first token in the generic function type.
  @override
  int get offset;

  @override
  GenericFunctionTypeFragment? get previousFragment;
}

/// A getter.
///
/// Getters can either be defined explicitly or they can be induced by either a
/// top-level variable or a field. Induced getters are synthetic.
///
/// Clients may not extend, implement or mix-in this class.
abstract class GetterElement implements PropertyAccessorElement {
  @override
  GetterElement get baseElement;

  /// The setter that corresponds to (has the same name as) this getter, or
  /// `null` if there is no corresponding setter.
  SetterElement? get correspondingSetter;

  /// The setter that corresponds to (has the same name as) this getter, or
  /// `null` if there is no corresponding setter.
  @Deprecated('Use correspondingSetter instead')
  SetterElement? get correspondingSetter2;

  @override
  GetterFragment get firstFragment;

  @override
  List<GetterFragment> get fragments;
}

/// The portion of a [GetterElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class GetterFragment implements PropertyAccessorFragment {
  @override
  GetterElement get element;

  @override
  GetterFragment? get nextFragment;

  /// The offset of the getter name.
  ///
  /// If the getter is implicit (because it's induced by a field or top level
  /// variable declaration), this is the offset of the field or top level
  /// variable name.
  @override
  int get offset;

  @override
  GetterFragment? get previousFragment;
}

/// A combinator that causes some of the names in a namespace to be hidden when
/// being imported.
///
/// Clients may not extend, implement or mix-in this class.
abstract class HideElementCombinator implements NamespaceCombinator {
  /// The names that are not to be made visible in the importing library even
  /// if they are defined in the imported library.
  List<String> get hiddenNames;
}

/// An element whose instance members can refer to `this`.
///
/// Clients may not extend, implement or mix-in this class.
abstract class InstanceElement
    implements TypeDefiningElement, TypeParameterizedElement {
  @override
  InstanceElement get baseElement;

  @override
  LibraryElement get enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  LibraryElement get enclosingElement2;

  /// The fields declared in this element.
  List<FieldElement> get fields;

  /// The fields declared in this element.
  @Deprecated('Use fields instead')
  List<FieldElement> get fields2;

  @override
  InstanceFragment get firstFragment;

  @override
  List<InstanceFragment> get fragments;

  /// The getters declared in this element.
  List<GetterElement> get getters;

  /// The getters declared in this element.
  @Deprecated('Use getters instead')
  List<GetterElement> get getters2;

  /// The methods declared in this element.
  List<MethodElement> get methods;

  /// The methods declared in this element.
  @Deprecated('Use methods instead')
  List<MethodElement> get methods2;

  /// The setters declared in this element.
  List<SetterElement> get setters;

  /// The setters declared in this element.
  @Deprecated('Use setters instead')
  List<SetterElement> get setters2;

  /// The type of a `this` expression.
  DartType get thisType;

  /// Returns the field from [fields] that has the given [name].
  FieldElement? getField(String name);

  /// Returns the field from [fields] that has the given [name].
  @Deprecated('Use getField instead')
  FieldElement? getField2(String name);

  /// Returns the getter from [getters] that has the given [name].
  GetterElement? getGetter(String name);

  /// Returns the getter from [getters] that has the given [name].
  @Deprecated('Use getGetter instead')
  GetterElement? getGetter2(String name);

  /// Returns the method from [methods] that has the given [name].
  MethodElement? getMethod(String name);

  /// Returns the method from [methods] that has the given [name].
  @Deprecated('Use getMethod instead')
  MethodElement? getMethod2(String name);

  /// Returns the setter from [setters] that has the given [name].
  SetterElement? getSetter(String name);

  /// Returns the setter from [setters] that has the given [name].
  @Deprecated('Use getSetter instead')
  SetterElement? getSetter2(String name);

  /// Returns the element representing the getter that results from looking up
  /// the given [name] in this class with respect to the given [library],
  /// or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 17.18 Lookup.
  GetterElement? lookUpGetter({
    required String name,
    required LibraryElement library,
  });

  /// Returns the element representing the getter that results from looking up
  /// the given [name] in this class with respect to the given [library],
  /// or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 17.18 Lookup.
  @Deprecated('Use lookUpGetter instead')
  GetterElement? lookUpGetter2({
    required String name,
    required LibraryElement library,
  });

  /// Returns the element representing the method that results from looking up
  /// the given [name] in this class with respect to the given [library],
  /// or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 17.18 Lookup.
  MethodElement? lookUpMethod({
    required String name,
    required LibraryElement library,
  });

  /// Returns the element representing the method that results from looking up
  /// the given [name] in this class with respect to the given [library],
  /// or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 17.18 Lookup.
  @Deprecated('Use lookUpMethod instead')
  MethodElement? lookUpMethod2({
    required String name,
    required LibraryElement library,
  });

  /// Returns the element representing the setter that results from looking up
  /// the given [name] in this class with respect to the given [library],
  /// or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 17.18 Lookup.
  SetterElement? lookUpSetter({
    required String name,
    required LibraryElement library,
  });

  /// Returns the element representing the setter that results from looking up
  /// the given [name] in this class with respect to the given [library],
  /// or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 17.18 Lookup.
  @Deprecated('Use lookUpSetter instead')
  SetterElement? lookUpSetter2({
    required String name,
    required LibraryElement library,
  });
}

/// The portion of an [InstanceElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class InstanceFragment
    implements TypeDefiningFragment, TypeParameterizedFragment {
  @override
  InstanceElement get element;

  @override
  LibraryFragment? get enclosingFragment;

  /// The fields declared in this fragment.
  List<FieldFragment> get fields;

  /// The fields declared in this fragment.
  @Deprecated('Use fields instead')
  List<FieldFragment> get fields2;

  /// The getters declared in this fragment.
  List<GetterFragment> get getters;

  /// Whether the fragment is an augmentation.
  ///
  /// If `true`, the declaration has the explicit `augment` modifier.
  bool get isAugmentation;

  @override
  LibraryFragment get libraryFragment;

  /// The methods declared in this fragment.
  List<MethodFragment> get methods;

  /// The methods declared in this fragment.
  @Deprecated('Use methods instead')
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
abstract class InterfaceElement implements InstanceElement {
  /// All the supertypes defined for this element and its supertypes.
  ///
  /// This includes superclasses, mixins, interfaces, and superclass
  /// constraints.
  List<InterfaceType> get allSupertypes;

  /// The constructors defined for this element.
  ///
  /// The list is empty for [MixinElement].
  List<ConstructorElement> get constructors;

  /// The constructors defined for this element.
  ///
  /// The list is empty for [MixinElement].
  @Deprecated('Use constructors instead')
  List<ConstructorElement> get constructors2;

  @override
  InterfaceFragment get firstFragment;

  @override
  List<InterfaceFragment> get fragments;

  /// Returns a map of all concrete members that this type inherits from
  /// superclasses and mixins, keyed by the member's [Name].
  ///
  /// Members declared in this type have no effect on the map. This means that:
  /// - If this type contains a member named `foo`, but none of its superclasses
  ///   or mixins contains a member named `foo`, then there will be no entry for
  ///   `foo` in the map.
  /// - If this type contains a member named `foo`, and one of its superclasses
  ///   or mixins contains a member named `foo`, then there will be an entry for
  ///   `foo` in this map, pointing to the declaration inherited from the
  ///   superclass or mixin.
  ///
  /// This method is potentially expensive, since it needs to consider all
  /// possible inherited names. If you only need to look up a certain specific
  /// name (or names), use [getInheritedConcreteMember] instead.
  Map<Name, ExecutableElement> get inheritedConcreteMembers;

  /// Returns a map of all members that this type inherits from supertypes via
  /// `extends`, `with`, `implements`, or `on` clauses, keyed by the member's
  /// [Name].
  ///
  /// Members declared in this type have no effect on the map. This means that:
  /// - If this type contains a member named `foo`, but none of its supertypes
  ///   contains a member named `foo`, then there will be no entry for `foo` in
  ///   the map.
  /// - If this type contains a member named `foo`, and one of its supertypes
  ///   contains a member named `foo`, then there will be an entry for `foo` in
  ///   this map, pointing to the declaration inherited from the supertype.
  ///
  /// This method is potentially expensive, since it needs to consider all
  /// possible inherited names. If you only need to look up a certain specific
  /// name (or names), use [getInheritedMember] instead.
  Map<Name, ExecutableElement> get inheritedMembers;

  /// Returns a map of all members in the type's interface, keyed by the
  /// member's [Name].
  ///
  /// Note that some names are not declared directly on [thisType], but are
  /// inherited from supertypes.
  ///
  /// This method is potentially expensive, since it needs to consider all
  /// possible interface names. If you only need to look up a certain specific
  /// name (or names), use [getInterfaceMember] instead.
  Map<Name, ExecutableElement> get interfaceMembers;

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
  ConstructorElement? get unnamedConstructor;

  /// The unnamed constructor declared directly in this class.
  ///
  /// If the class does not declare any constructors, a synthetic default
  /// constructor will be returned.
  @Deprecated('Use unnamedConstructor instead')
  ConstructorElement? get unnamedConstructor2;

  /// Returns the most specific member with the given [name] that this type
  /// inherits from a superclass or mixin.
  ///
  /// Returns `null` if no member is inherited.
  ///
  /// This method is semantically equivalent to calling
  /// [inheritedConcreteMembers] and then using the `[]` operator, but it
  /// potentially has better performance, since it does not need to consider all
  /// possible inherited names.
  ExecutableElement? getInheritedConcreteMember(Name name);

  /// Returns the most specific member with the given [name] that this type
  /// inherits from a supertype via an `extends`, `with`, `implements`, or `on`
  /// clause.
  ///
  /// Returns `null` if no member is inherited because the member is not
  /// declared at all, or because there is no the most specific signature.
  ///
  /// This method is semantically equivalent to calling [inheritedMembers] and
  /// then using the `[]` operator, but it potentially has better performance,
  /// since it does not need to consider all possible inherited names.
  ExecutableElement? getInheritedMember(Name name);

  /// Returns the most specific member with the given [name] in this type's
  /// interface.
  ///
  /// Returns `null` if there is no member with the given [name] in this type's
  /// interface, either because the member is not declared at all, or because of
  /// a conflict between inherited members.
  ///
  /// This method is semantically equivalent to calling [interfaceMembers] and
  /// then using the `[]` operator, but it potentially has better performance,
  /// since it does not need to consider all possible interface names.
  ExecutableElement? getInterfaceMember(Name name);

  /// Returns the constructor from [constructors] that has the given [name].
  ConstructorElement? getNamedConstructor(String name);

  /// Returns the constructor from [constructors] that has the given [name].
  @Deprecated('Use getNamedConstructor instead')
  ConstructorElement? getNamedConstructor2(String name);

  /// Returns all members of mixins, superclasses, and interfaces that a member
  /// with the given [name], defined in this element, would override; or `null`
  /// if no members would be overridden.
  ///
  /// Transitive overrides are not included unless there is a direct path to
  /// them. For example, if classes `A`, `B`, and `C` are defined as follows:
  ///
  ///     class A { void m() {} }
  ///     class B extends A { void m() {} }
  ///     class C extends B { void m() {} }
  ///
  /// Then a [getOverridden] query for name `m` on class `C` would return just a
  /// single result: the element for `B.m`.
  ///
  /// However, if the example were changed so that `class C` both `extends B`
  /// *and* `implements A`, then a list containing both `A.m` and `B.m` would be
  /// returned.
  List<ExecutableElement>? getOverridden(Name name);

  /// Create the [InterfaceType] for this element with the given
  /// [typeArguments] and [nullabilitySuffix].
  InterfaceType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  });

  /// Returns the element representing the method that results from looking up
  /// the given [methodName] in this class with respect to the given [library],
  /// ignoring abstract methods, or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.1:
  /// <blockquote>
  /// The result of looking up method <i>m</i> in class <i>C</i> with respect to
  /// library <i>L</i> is: If <i>C</i> declares an instance method named
  /// <i>m</i> that is accessible to <i>L</i>, then that method is the result of
  /// the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
  /// result of the lookup is the result of looking up method <i>m</i> in
  /// <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
  /// failed.
  /// </blockquote>
  // TODO(scheglov): Deprecate and remove it.
  MethodElement? lookUpConcreteMethod(
    String methodName,
    LibraryElement library,
  );

  /// Returns the element representing the method that results from looking up
  /// the given [methodName] in the superclass of this class with respect to the
  /// given [library], or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.1:
  /// <blockquote>
  /// The result of looking up method <i>m</i> in class <i>C</i> with respect to
  /// library <i>L</i> is:  If <i>C</i> declares an instance method named
  /// <i>m</i> that is accessible to <i>L</i>, then that method is the result of
  /// the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
  /// result of the lookup is the result of looking up method <i>m</i> in
  /// <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
  /// failed.
  /// </blockquote>
  MethodElement? lookUpInheritedMethod({
    required String methodName,
    required LibraryElement library,
  });

  /// Returns the element representing the method that results from looking up
  /// the given [methodName] in the superclass of this class with respect to the
  /// given [library], or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.1:
  /// <blockquote>
  /// The result of looking up method <i>m</i> in class <i>C</i> with respect to
  /// library <i>L</i> is:  If <i>C</i> declares an instance method named
  /// <i>m</i> that is accessible to <i>L</i>, then that method is the result of
  /// the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
  /// result of the lookup is the result of looking up method <i>m</i> in
  /// <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
  /// failed.
  /// </blockquote>
  @Deprecated('Use lookUpInheritedMethod instead')
  MethodElement? lookUpInheritedMethod2({
    required String methodName,
    required LibraryElement library,
  });
}

/// The portion of an [InterfaceElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class InterfaceFragment implements InstanceFragment {
  /// The constructors declared in this fragment.
  ///
  /// The list is empty for [MixinFragment].
  List<ConstructorFragment> get constructors;

  /// The constructors declared in this fragment.
  ///
  /// The list is empty for [MixinFragment].
  @Deprecated('Use constructors instead')
  List<ConstructorFragment> get constructors2;

  @override
  InterfaceElement get element;

  /// The interfaces that are implemented by this fragment.
  @Deprecated('Use InterfaceElement.interfaces instead')
  List<InterfaceType> get interfaces;

  /// The mixins that are applied by this fragment.
  ///
  /// [ClassFragment] and [EnumFragment] can have mixins.
  ///
  /// [MixinFragment] cannot have mixins, so the empty list is returned.
  @Deprecated('Use InterfaceElement.mixins instead')
  List<InterfaceType> get mixins;

  @override
  InterfaceFragment? get nextFragment;

  @override
  InterfaceFragment? get previousFragment;

  /// The superclass declared by this fragment.
  @Deprecated('Use InterfaceElement.supertype instead')
  InterfaceType? get supertype;
}

/// A pattern variable that is a join of other pattern variables, created
/// for a logical-or patterns, or shared `case` bodies in `switch` statements.
///
/// Clients may not extend, implement or mix-in this class.
abstract class JoinPatternVariableElement implements PatternVariableElement {
  @override
  JoinPatternVariableFragment get firstFragment;

  @override
  List<JoinPatternVariableFragment> get fragments;

  /// Whether the [variables] are consistent.
  ///
  /// The variables are consistent if they are present in all branches, and have
  /// the same type and finality.
  bool get isConsistent;

  /// The variables that join into this variable.
  List<PatternVariableElement> get variables;

  /// The variables that join into this variable.
  @Deprecated('Use variables instead')
  List<PatternVariableElement> get variables2;
}

/// The portion of a [JoinPatternVariableElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class JoinPatternVariableFragment implements PatternVariableFragment {
  @override
  JoinPatternVariableElement get element;

  @override
  JoinPatternVariableFragment? get nextFragment;

  /// The offset of the first variable in the join.
  @override
  int get offset;

  @override
  JoinPatternVariableFragment? get previousFragment;
}

/// A label associated with a statement.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LabelElement implements Element {
  @override
  // TODO(brianwilkerson): We shouldn't be inheriting this member.
  ExecutableElement? get enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  ExecutableElement? get enclosingElement2;

  @override
  LabelFragment get firstFragment;

  @override
  List<LabelFragment> get fragments;

  @override
  LibraryElement get library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2;
}

/// The portion of a [LabelElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LabelFragment implements Fragment {
  @override
  LabelElement get element;

  @override
  LabelFragment? get nextFragment;

  @override
  LabelFragment? get previousFragment;
}

/// A library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryElement
    implements
        Element,
        Annotatable // ignore:deprecated_member_use_from_same_package
        {
  /// The classes defined in this library.
  ///
  /// There is no guarantee of the order in which the classes will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<ClassElement> get classes;

  /// The entry point for this library.
  ///
  /// Returns `null` if this library doesn't have an entry point.
  ///
  /// The entry point is defined to be a zero, one, or two argument top-level
  /// function whose name is `main`.
  TopLevelFunctionElement? get entryPoint;

  /// The entry point for this library.
  ///
  /// Returns `null` if this library doesn't have an entry point.
  ///
  /// The entry point is defined to be a zero, one, or two argument top-level
  /// function whose name is `main`.
  @Deprecated('Use entryPoint instead')
  TopLevelFunctionElement? get entryPoint2;

  /// The enums defined in this library.
  ///
  /// There is no guarantee of the order in which the enums will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<EnumElement> get enums;

  /// The libraries that are exported from this library.
  ///
  /// There is no guarantee of the order in which the libraries will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  // TODO(brianwilkerson): Consider removing this from the public API. It isn't
  //  clear that it's useful, given that it ignores hide and show clauses.
  List<LibraryElement> get exportedLibraries;

  /// The libraries that are exported from this library.
  ///
  /// There is no guarantee of the order in which the libraries will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  // TODO(brianwilkerson): Consider removing this from the public API. It isn't
  //  clear that it's useful, given that it ignores hide and show clauses.
  @Deprecated('Use exportedLibraries instead')
  List<LibraryElement> get exportedLibraries2;

  /// The export [Namespace] of this library.
  Namespace get exportNamespace;

  /// The extensions defined in this library.
  ///
  /// There is no guarantee of the order in which the extensions will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  List<ExtensionElement> get extensions;

  /// The extension types defined in this library.
  ///
  /// There is no guarantee of the order in which the extension types will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  List<ExtensionTypeElement> get extensionTypes;

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
  @override
  List<LibraryFragment> get fragments;

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
  LibraryElement get library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2;

  /// The element representing the synthetic function `loadLibrary`.
  ///
  /// Technically the function is implicitly defined for this library only if
  /// the library is imported using a deferred import, but the element is always
  /// defined for performance reasons.
  TopLevelFunctionElement get loadLibraryFunction;

  /// The element representing the synthetic function `loadLibrary`.
  ///
  /// Technically the function is implicitly defined for this library only if
  /// the library is imported using a deferred import, but the element is always
  /// defined for performance reasons.
  @Deprecated('Use loadLibraryFunction instead')
  TopLevelFunctionElement get loadLibraryFunction2;

  /// The mixins defined in this library.
  ///
  /// There is no guarantee of the order in which the mixins will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<MixinElement> get mixins;

  /// The public [Namespace] of this library.
  Namespace get publicNamespace;

  /// The analysis session in which this library is defined.
  @override
  AnalysisSession get session;

  /// The setters defined in this library.
  ///
  /// There is no guarantee of the order in which the setters will be returned.
  /// In particular, they are not guaranteed to be in lexical order.
  List<SetterElement> get setters;

  /// The functions defined in this library.
  ///
  /// There is no guarantee of the order in which the functions will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  List<TopLevelFunctionElement> get topLevelFunctions;

  /// The top level variables defined in this library.
  ///
  /// There is no guarantee of the order in which the top level variables will
  /// be returned. In particular, they are not guaranteed to be in lexical
  /// order.
  List<TopLevelVariableElement> get topLevelVariables;

  /// The type aliases defined in this library.
  ///
  /// There is no guarantee of the order in which the type aliases will be
  /// returned. In particular, they are not guaranteed to be in lexical order.
  List<TypeAliasElement> get typeAliases;

  /// The [TypeProvider] that is used in this library.
  TypeProvider get typeProvider;

  /// The [TypeSystem] that is used in this library.
  TypeSystem get typeSystem;

  /// The canonical URI of the library.
  ///
  /// This is the same URI as `firstFragment.source.uri` returns.
  Uri get uri;

  /// Returns the class defined in this library that has the given [name].
  ClassElement? getClass(String name);

  /// Returns the class defined in this library that has the given [name].
  @Deprecated('Use getClass instead')
  ClassElement? getClass2(String name);

  /// Returns the enum defined in this library that has the given [name].
  EnumElement? getEnum(String name);

  /// Returns the enum defined in this library that has the given [name].
  @Deprecated('Use getEnum instead')
  EnumElement? getEnum2(String name);

  /// Returns the extension defined in this library that has the given [name].
  ExtensionElement? getExtension(String name);

  /// Returns the extension type defined in this library that has the
  /// given [name].
  ExtensionTypeElement? getExtensionType(String name);

  /// Returns the getter defined in this library that has the given [name].
  GetterElement? getGetter(String name);

  /// Returns the mixin defined in this library that has the given [name].
  MixinElement? getMixin(String name);

  /// Returns the mixin defined in this library that has the given [name].
  @Deprecated('Use getMixin instead')
  MixinElement? getMixin2(String name);

  /// Returns the setter defined in this library that has the given [name].
  SetterElement? getSetter(String name);

  /// Returns the function defined in this library that has the given [name].
  TopLevelFunctionElement? getTopLevelFunction(String name);

  /// Returns the top-level variable defined in this library that has the
  /// given [name].
  TopLevelVariableElement? getTopLevelVariable(String name);

  /// Returns the type alias defined in this library that has the given [name].
  TypeAliasElement? getTypeAlias(String name);
}

/// An `export` directive within a library fragment.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryExport implements ElementDirective {
  /// The combinators that were specified as part of the `export` directive.
  ///
  /// The combinators are in the order in which they were specified.
  List<NamespaceCombinator> get combinators;

  /// The [LibraryElement], if [uri] is a [DirectiveUriWithLibrary].
  LibraryElement? get exportedLibrary;

  /// The [LibraryElement], if [uri] is a [DirectiveUriWithLibrary].
  @Deprecated('Use exportedLibrary instead')
  LibraryElement? get exportedLibrary2;

  /// The offset of the `export` keyword.
  int get exportKeywordOffset;
}

/// The portion of a [LibraryElement] coming from a single compilation unit.
abstract class LibraryFragment implements Fragment {
  /// The extension elements accessible within this fragment.
  List<ExtensionElement> get accessibleExtensions;

  /// The extension elements accessible within this fragment.
  @Deprecated('Use accessibleExtensions instead')
  List<ExtensionElement> get accessibleExtensions2;

  /// The fragments of the classes declared in this fragment.
  List<ClassFragment> get classes;

  /// The fragments of the classes declared in this fragment.
  @Deprecated('Use classes instead')
  List<ClassFragment> get classes2;

  @override
  LibraryElement get element;

  @override
  LibraryFragment? get enclosingFragment;

  /// The fragments of the enums declared in this fragment.
  List<EnumFragment> get enums;

  /// The fragments of the enums declared in this fragment.
  @Deprecated('Use enums instead')
  List<EnumFragment> get enums2;

  /// The fragments of the extensions declared in this fragment.
  List<ExtensionFragment> get extensions;

  /// The fragments of the extensions declared in this fragment.
  @Deprecated('Use extensions instead')
  List<ExtensionFragment> get extensions2;

  /// The fragments of the extension types declared in this fragment.
  List<ExtensionTypeFragment> get extensionTypes;

  /// The fragments of the extension types declared in this fragment.
  @Deprecated('Use extensionTypes instead')
  List<ExtensionTypeFragment> get extensionTypes2;

  /// The fragments of the top-level functions declared in this fragment.
  List<TopLevelFunctionFragment> get functions;

  /// The fragments of the top-level functions declared in this fragment.
  @Deprecated('Use functions instead')
  List<TopLevelFunctionFragment> get functions2;

  /// The fragments of the top-level getters declared in this fragment.
  List<GetterFragment> get getters;

  /// The libraries that are imported by this unit.
  ///
  /// This includes all of the libraries that are imported using a prefix, and
  /// those that are imported without a prefix.
  List<LibraryElement> get importedLibraries;

  /// The libraries that are imported by this unit.
  ///
  /// This includes all of the libraries that are imported using a prefix, and
  /// those that are imported without a prefix.
  @Deprecated('Use importedLibraries instead')
  List<LibraryElement> get importedLibraries2;

  /// The libraries exported by this unit.
  List<LibraryExport> get libraryExports;

  /// The libraries exported by this unit.
  @Deprecated('Use libraryExports instead')
  List<LibraryExport> get libraryExports2;

  /// The libraries imported by this unit.
  List<LibraryImport> get libraryImports;

  /// The libraries imported by this unit.
  @Deprecated('Use libraryImports instead')
  List<LibraryImport> get libraryImports2;

  /// The [LineInfo] for the fragment.
  LineInfo get lineInfo;

  /// The fragments of the mixins declared in this fragment.
  List<MixinFragment> get mixins;

  /// The fragments of the mixins declared in this fragment.
  @Deprecated('Use mixins instead')
  List<MixinFragment> get mixins2;

  @override
  LibraryFragment? get nextFragment;

  /// If this is the first fragment in the library and the library has `library`
  /// declaration that specifies a name, the offset of the name; otherwise zero.
  @override
  int get offset;

  /// The `part` directives within this fragment.
  List<PartInclude> get partIncludes;

  /// The prefixes used by [libraryImports].
  ///
  /// Each prefix can be used in more than one `import` directive.
  List<PrefixElement> get prefixes;

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
  List<TopLevelVariableFragment> get topLevelVariables;

  /// The fragments of the top-level variables declared in this fragment.
  @Deprecated('Use topLevelVariables instead')
  List<TopLevelVariableFragment> get topLevelVariables2;

  /// The fragments of the type aliases declared in this fragment.
  List<TypeAliasFragment> get typeAliases;

  /// The fragments of the type aliases declared in this fragment.
  @Deprecated('Use typeAliases instead')
  List<TypeAliasFragment> get typeAliases2;
}

/// An `import` directive within a library fragment.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryImport implements ElementDirective {
  /// The combinators that were specified as part of the `import` directive.
  ///
  /// The combinators are in the order in which they were specified.
  List<NamespaceCombinator> get combinators;

  /// The [LibraryElement], if [uri] is a [DirectiveUriWithLibrary].
  LibraryElement? get importedLibrary;

  /// The [LibraryElement], if [uri] is a [DirectiveUriWithLibrary].
  @Deprecated('Use importedLibrary instead')
  LibraryElement? get importedLibrary2;

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
  PrefixFragment? get prefix;

  /// The prefix fragment that was specified as part of the import directive.
  ///
  /// Returns `null` if there was no prefix specified.
  @Deprecated('Use prefix instead')
  PrefixFragment? get prefix2;
}

class LibraryLanguageVersion {
  /// The version for the whole package that contains this library.
  final Version package;

  /// The version specified using `@dart` override, `null` if absent or invalid.
  final Version? override;

  LibraryLanguageVersion({required this.package, required this.override});

  /// The effective language version for the library.
  Version get effective {
    return override ?? package;
  }
}

/// An element that can be (but is not required to be) defined within a method
/// or function (an [ExecutableFragment]).
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalElement implements Element {}

/// The portion of an [LocalElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalFragment implements Fragment {}

/// A local function.
///
/// This can be either a local function, a closure, or the initialization
/// expression for a field or variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalFunctionElement implements ExecutableElement, LocalElement {
  @override
  LocalFunctionFragment get firstFragment;

  @override
  List<LocalFunctionFragment> get fragments;
}

/// The portion of a [LocalFunctionElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalFunctionFragment
    implements ExecutableFragment, LocalFragment {
  @override
  LocalFunctionElement get element;

  @override
  LocalFunctionFragment? get nextFragment;

  /// The offset of the local function name.
  ///
  /// If the local function has no name (because it's a function expression),
  /// this is the offset of the `(` that begins the function expression.
  @override
  int get offset;

  @override
  LocalFunctionFragment? get previousFragment;
}

/// A local variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalVariableElement
    implements
        VariableElement,
        LocalElement,
        Annotatable // ignore:deprecated_member_use_from_same_package
        {
  @override
  LocalVariableElement get baseElement;

  @override
  LocalVariableFragment get firstFragment;

  @override
  List<LocalVariableFragment> get fragments;
}

/// The portion of a [LocalVariableElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalVariableFragment
    implements VariableFragment, LocalFragment {
  @override
  LocalVariableElement get element;

  @override
  LocalVariableFragment? get nextFragment;

  @override
  LocalVariableFragment? get previousFragment;
}

/// The metadata (annotations) associated with an element or fragment.
abstract class Metadata {
  /// The annotations associated with the associated element or fragment.
  ///
  /// If the metadata is associated with an element that has fragments, the list
  /// will include all of the annotations from all of the fragments.
  ///
  /// The list will be empty if the associated element or fragment does not have
  /// any annotations or if the library containing the holder has not yet been
  /// fully resolved.
  List<ElementAnnotation> get annotations;

  /// Whether the receiver has an annotation of the form `@alwaysThrows`.
  bool get hasAlwaysThrows;

  /// Whether the receiver has an annotation of the form `@awaitNotRequired`.
  bool get hasAwaitNotRequired;

  /// Whether the receiver has an annotation of the form `@deprecated`
  /// or `@Deprecated('..')`.
  bool get hasDeprecated;

  /// Whether the receiver has an annotation of the form `@doNotStore`.
  bool get hasDoNotStore;

  /// Whether the receiver has an annotation of the form `@doNotSubmit`.
  bool get hasDoNotSubmit;

  /// Whether the receiver has an annotation of the form `@experimental`.
  bool get hasExperimental;

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

  /// Whether the receiver has an annotation of the form `@widgetFactory`.
  bool get hasWidgetFactory;
}

/// A method.
///
/// The method can be either an instance method, an operator, or a static
/// method.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MethodElement implements ExecutableElement {
  /// The name of the method that can be implemented by a class to allow its
  /// instances to be invoked as if they were a function.
  static final String CALL_METHOD_NAME = "call";

  /// The name of the method that will be invoked if an attempt is made to
  /// invoke an undefined method on an object.
  static final String NO_SUCH_METHOD_METHOD_NAME = "noSuchMethod";

  @override
  MethodElement get baseElement;

  @override
  MethodFragment get firstFragment;

  @override
  List<MethodFragment> get fragments;

  /// Whether the method defines an operator.
  ///
  /// The test might be based on the name of the executable element, in which
  /// case the result will be correct when the name is legal.
  bool get isOperator;
}

/// The portion of a [MethodElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MethodFragment implements ExecutableFragment {
  @override
  MethodElement get element;

  @override
  InstanceFragment? get enclosingFragment;

  @override
  MethodFragment? get nextFragment;

  @override
  MethodFragment? get previousFragment;
}

/// An element that represents a mixin.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MixinElement implements InterfaceElement {
  @override
  MixinFragment get firstFragment;

  @override
  List<MixinFragment> get fragments;

  /// Whether the mixin is a base mixin.
  ///
  /// A mixin is a base mixin if it has an explicit `base` modifier.
  /// The base modifier allows a mixin to be mixed in, but not implemented.
  bool get isBase;

  /// Whether the mixin can be implemented by declarations outside of its
  /// library.
  bool get isImplementableOutside;

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

  /// Whether the mixin, assuming that it is within scope, is implementable by
  /// declarations in the given [library].
  @Deprecated('Use isImplementableOutside instead')
  bool isImplementableIn(LibraryElement library);

  /// Whether the mixin, assuming that it is within scope, is implementable by
  /// declarations in the given [library].
  @Deprecated('Use isImplementableOutside instead')
  bool isImplementableIn2(LibraryElement library);
}

/// The portion of a [PrefixElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MixinFragment implements InterfaceFragment {
  @override
  MixinElement get element;

  @override
  MixinFragment? get nextFragment;

  @override
  MixinFragment? get previousFragment;

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
abstract class MultiplyDefinedElement implements Element {
  /// The elements that were defined within the scope to have the same name.
  List<Element> get conflictingElements;

  /// The elements that were defined within the scope to have the same name.
  @Deprecated('Use conflictingElements instead')
  List<Element> get conflictingElements2;

  @override
  MultiplyDefinedFragment get firstFragment;

  @override
  List<MultiplyDefinedFragment> get fragments;
}

/// The fragment for a [MultiplyDefinedElement].
///
/// It has no practical use, and exists for consistency, so that the
/// corresponding element has a fragment.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MultiplyDefinedFragment implements Fragment {
  @override
  MultiplyDefinedElement get element;

  @override
  Null get nextFragment;

  /// Always returns zero.
  @override
  int get offset;

  @override
  Null get previousFragment;
}

/// An object that controls how namespaces are combined.
///
/// Clients may not extend, implement or mix-in this class.
sealed class NamespaceCombinator {
  /// The offset of the character immediately following the last character of
  /// this node.
  int get end;

  /// The offset of the first character of this node.
  int get offset;
}

/// A 'part' directive within a library fragment.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PartInclude implements ElementDirective {
  /// The [LibraryFragment], if [uri] is a [DirectiveUriWithUnit].
  LibraryFragment? get includedFragment;

  /// The offset of the `part` keyword.
  int get partKeywordOffset;
}

/// A pattern variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PatternVariableElement implements LocalVariableElement {
  @override
  PatternVariableFragment get firstFragment;

  @override
  List<PatternVariableFragment> get fragments;

  /// The variable in which this variable joins with other pattern variables
  /// with the same name, in a logical-or pattern, or shared case scope.
  JoinPatternVariableElement? get join;

  /// The variable in which this variable joins with other pattern variables
  /// with the same name, in a logical-or pattern, or shared case scope.
  @Deprecated('Use join instead')
  JoinPatternVariableElement? get join2;
}

/// The portion of a [PatternVariableElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PatternVariableFragment implements LocalVariableFragment {
  @override
  PatternVariableElement get element;

  /// The variable in which this variable joins with other pattern variables
  /// with the same name, in a logical-or pattern, or shared case scope.
  JoinPatternVariableFragment? get join;

  /// The variable in which this variable joins with other pattern variables
  /// with the same name, in a logical-or pattern, or shared case scope.
  @Deprecated('Use join instead')
  JoinPatternVariableFragment? get join2;

  @override
  PatternVariableFragment? get nextFragment;

  @override
  PatternVariableFragment? get previousFragment;
}

/// A prefix used to import one or more libraries into another library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PrefixElement implements Element {
  /// There is no enclosing element for import prefixes, which are elements,
  /// but exist inside a single [LibraryFragment], not an element.
  @override
  Null get enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  Null get enclosingElement2;

  @override
  PrefixFragment get firstFragment;

  @override
  List<PrefixFragment> get fragments;

  /// The imports that share this prefix.
  List<LibraryImport> get imports;

  @override
  LibraryElement get library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2;

  /// The name lookup scope for this import prefix.
  ///
  /// It consists of elements imported into the enclosing library with this
  /// prefix. The namespace combinators of the import directives are taken
  /// into account.
  Scope get scope;
}

/// The portion of a [PrefixElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PrefixFragment implements Fragment {
  @override
  PrefixElement get element;

  @override
  LibraryFragment? get enclosingFragment;

  /// Whether the [LibraryImport] is deferred.
  bool get isDeferred;

  @override
  PrefixFragment? get nextFragment;

  @override
  PrefixFragment? get previousFragment;
}

/// A getter or a setter.
///
/// Property accessors can either be defined explicitly or they can be induced
/// by either a top-level variable or a field. Induced property accessors are
/// synthetic.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PropertyAccessorElement implements ExecutableElement {
  @override
  PropertyAccessorElement get baseElement;

  @override
  Element get enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  Element get enclosingElement2;

  @override
  PropertyAccessorFragment get firstFragment;

  @override
  List<PropertyAccessorFragment> get fragments;

  /// The field or top-level variable associated with this getter.
  ///
  /// If this getter was explicitly defined (is not synthetic) then the variable
  /// associated with it will be synthetic.
  PropertyInducingElement get variable;

  /// The field or top-level variable associated with this getter.
  ///
  /// If this getter was explicitly defined (is not synthetic) then the variable
  /// associated with it will be synthetic.
  @Deprecated('Use variable instead')
  PropertyInducingElement? get variable3;
}

/// The portion of a [GetterElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PropertyAccessorFragment implements ExecutableFragment {
  @override
  PropertyAccessorElement get element;

  @override
  PropertyAccessorFragment? get nextFragment;

  @override
  PropertyAccessorFragment? get previousFragment;
}

/// A variable that has an associated getter and possibly a setter. Note that
/// explicitly defined variables implicitly define a synthetic getter and that
/// non-`final` explicitly defined variables implicitly define a synthetic
/// setter. Symmetrically, synthetic fields are implicitly created for
/// explicitly defined getters and setters. The following rules apply:
///
/// * Every explicit variable is represented by a non-synthetic
///   [PropertyInducingElement].
/// * Every explicit variable induces a synthetic [GetterElement],
///   possibly a synthetic [SetterElement.
/// * Every explicit getter by a non-synthetic [GetterElement].
/// * Every explicit setter by a non-synthetic [SetterElement].
/// * Every explicit getter or setter (or pair thereof if they have the same
///   name) induces a variable that is represented by a synthetic
///   [PropertyInducingElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class PropertyInducingElement
    implements
        VariableElement,
        Annotatable // ignore:deprecated_member_use_from_same_package
        {
  @override
  PropertyInducingFragment get firstFragment;

  @override
  List<PropertyInducingFragment> get fragments;

  /// The getter associated with this variable.
  ///
  /// If this variable was explicitly defined (is not synthetic) then the
  /// getter associated with it will be synthetic.
  GetterElement? get getter;

  /// The getter associated with this variable.
  ///
  /// If this variable was explicitly defined (is not synthetic) then the
  /// getter associated with it will be synthetic.
  @Deprecated('Use getter instead')
  GetterElement? get getter2;

  /// Whether any fragment of this variable has an initializer at declaration.
  bool get hasInitializer;

  @override
  LibraryElement get library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2;

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
  SetterElement? get setter;

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
  @Deprecated('Use setter instead')
  SetterElement? get setter2;
}

/// The portion of a [PropertyInducingElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PropertyInducingFragment
    implements
        VariableFragment,
        Annotatable // ignore:deprecated_member_use_from_same_package
        {
  @override
  PropertyInducingElement get element;

  /// Whether the variable has an initializer at declaration.
  bool get hasInitializer;

  /// Whether the element is an augmentation.
  ///
  /// Property inducing fragments are augmentations if they are explicitly
  /// marked as such using the 'augment' modifier.
  bool get isAugmentation;

  /// Whether this fragment is synthetic.
  ///
  /// A synthetic fragment is a fragment that is not represented in the source
  /// code explicitly, but is implied by the source code, such as the default
  /// constructor for a class that does not explicitly define any constructors.
  bool get isSynthetic;

  @override
  LibraryFragment get libraryFragment;

  @override
  PropertyInducingFragment? get nextFragment;

  @override
  PropertyInducingFragment? get previousFragment;
}

/// A setter.
///
/// Setters can either be defined explicitly or they can be induced by either a
/// top-level variable or a field. Induced setters are synthetic.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SetterElement implements PropertyAccessorElement {
  @override
  SetterElement get baseElement;

  /// The getter that corresponds to (has the same name as) this setter, or
  /// `null` if there is no corresponding getter.
  GetterElement? get correspondingGetter;

  /// The getter that corresponds to (has the same name as) this setter, or
  /// `null` if there is no corresponding getter.
  @Deprecated('Use correspondingGetter instead')
  GetterElement? get correspondingGetter2;

  @override
  SetterFragment get firstFragment;

  @override
  List<SetterFragment> get fragments;
}

/// The portion of a [SetterElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SetterFragment implements PropertyAccessorFragment {
  @override
  SetterElement get element;

  @override
  SetterFragment? get nextFragment;

  /// The offset of the setter name.
  ///
  /// If the setter is implicit (because it's induced by a field or top level
  /// variable declaration), this is the offset of the field or top level
  /// variable name.
  @override
  int get offset;

  @override
  SetterFragment? get previousFragment;
}

/// A combinator that cause some of the names in a namespace to be visible (and
/// the rest hidden) when being imported.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ShowElementCombinator implements NamespaceCombinator {
  /// The names that are to be made visible in the importing library if they
  /// are defined in the imported library.
  List<String> get shownNames;
}

/// A super formal parameter.
///
/// Super formal parameters can only be defined within a constructor element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SuperFormalParameterElement implements FormalParameterElement {
  @override
  SuperFormalParameterFragment get firstFragment;

  @override
  List<SuperFormalParameterFragment> get fragments;

  /// The associated super-constructor parameter, from the super-constructor
  /// that is referenced by the implicit or explicit super-constructor
  /// invocation.
  ///
  /// Can be `null` for erroneous code - not existing super-constructor,
  /// no corresponding parameter in the super-constructor.
  FormalParameterElement? get superConstructorParameter;

  /// The associated super-constructor parameter, from the super-constructor
  /// that is referenced by the implicit or explicit super-constructor
  /// invocation.
  ///
  /// Can be `null` for erroneous code - not existing super-constructor,
  /// no corresponding parameter in the super-constructor.
  @Deprecated('Use superConstructorParameter instead')
  FormalParameterElement? get superConstructorParameter2;
}

/// The portion of a [SuperFormalParameterElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SuperFormalParameterFragment implements FormalParameterFragment {
  @override
  SuperFormalParameterElement get element;

  @override
  SuperFormalParameterFragment? get nextFragment;

  @override
  SuperFormalParameterFragment? get previousFragment;
}

/// A top-level function.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TopLevelFunctionElement implements ExecutableElement {
  /// The name of the function used as an entry point.
  static const String MAIN_FUNCTION_NAME = "main";

  /// The name of the synthetic function defined for libraries that are
  /// deferred.
  static final String LOAD_LIBRARY_NAME = "loadLibrary";

  @override
  TopLevelFunctionElement get baseElement;

  @override
  TopLevelFunctionFragment get firstFragment;

  @override
  List<TopLevelFunctionFragment> get fragments;

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
abstract class TopLevelVariableElement implements PropertyInducingElement {
  @override
  TopLevelVariableElement get baseElement;

  @override
  TopLevelVariableFragment get firstFragment;

  @override
  List<TopLevelVariableFragment> get fragments;

  /// Whether the field was explicitly marked as being external.
  bool get isExternal;
}

/// The portion of a [TopLevelVariableElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TopLevelVariableFragment implements PropertyInducingFragment {
  @override
  TopLevelVariableElement get element;

  @override
  TopLevelVariableFragment? get nextFragment;

  @override
  TopLevelVariableFragment? get previousFragment;
}

/// A type alias (`typedef`).
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeAliasElement
    implements TypeParameterizedElement, TypeDefiningElement {
  /// If the aliased type has structure, return the corresponding element.
  /// For example, it could be [GenericFunctionTypeElement].
  ///
  /// If there is no structure, return `null`.
  Element? get aliasedElement;

  /// If the aliased type has structure, return the corresponding element.
  /// For example, it could be [GenericFunctionTypeElement].
  ///
  /// If there is no structure, return `null`.
  @Deprecated('Use aliasedElement instead')
  Element? get aliasedElement2;

  /// The aliased type.
  ///
  /// If non-function type aliases feature is enabled for the enclosing library,
  /// this type might be just anything. If the feature is disabled, return
  /// a [FunctionType].
  DartType get aliasedType;

  @override
  LibraryElement get enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  LibraryElement get enclosingElement2;

  @override
  TypeAliasFragment get firstFragment;

  @override
  List<TypeAliasFragment> get fragments;

  /// Returns the type resulting from instantiating this typedef with the given
  /// [typeArguments] and [nullabilitySuffix].
  ///
  /// Note that this always instantiates the typedef itself, so for a
  /// [TypeAliasElement] the returned [DartType] might still be a generic
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

/// The portion of a [TypeAliasElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeAliasFragment
    implements TypeParameterizedFragment, TypeDefiningFragment {
  @override
  TypeAliasElement get element;

  @override
  LibraryFragment? get enclosingFragment;

  @override
  TypeAliasFragment? get nextFragment;

  @override
  TypeAliasFragment? get previousFragment;
}

/// An element that defines a type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeDefiningElement
    implements
        Element,
        Annotatable // ignore:deprecated_member_use_from_same_package
        {
  // TODO(brianwilkerson): Evaluate to see whether this type is actually needed
  //  after converting clients to the new API.

  @override
  TypeDefiningFragment get firstFragment;

  @override
  List<TypeDefiningFragment> get fragments;
}

/// The portion of a [TypeDefiningElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeDefiningFragment
    implements
        Fragment,
        Annotatable // ignore:deprecated_member_use_from_same_package
        {
  @override
  TypeDefiningElement get element;

  @override
  TypeDefiningFragment? get nextFragment;

  /// The offset of the type name.
  ///
  /// If the type in the language specification and not in any source file
  /// (e.g., `dynamic`), this value is zero.
  @override
  int get offset;

  @override
  TypeDefiningFragment? get previousFragment;
}

/// A type parameter.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterElement implements TypeDefiningElement {
  @override
  TypeParameterElement get baseElement;

  /// The type representing the bound associated with this parameter.
  ///
  /// Returns `null` if this parameter does not have an explicit bound. Being
  /// able to distinguish between an implicit and explicit bound is needed by
  /// the instantiate to bounds algorithm.`
  DartType? get bound;

  @override
  TypeParameterFragment get firstFragment;

  @override
  List<TypeParameterFragment> get fragments;

  /// Returns the [TypeParameterType] with the given [nullabilitySuffix] for
  /// this type parameter.
  TypeParameterType instantiate({required NullabilitySuffix nullabilitySuffix});
}

/// The portion of a [TypeParameterElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterFragment implements TypeDefiningFragment {
  @override
  TypeParameterElement get element;

  @override
  TypeParameterFragment? get nextFragment;

  @override
  TypeParameterFragment? get previousFragment;
}

/// An element that has type parameters, such as a class, typedef, or method.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterizedElement
    implements
        Element,
        Annotatable // ignore:deprecated_member_use_from_same_package
        {
  @override
  TypeParameterizedFragment get firstFragment;

  @override
  List<TypeParameterizedFragment> get fragments;

  /// If the element defines a type, indicates whether the type may safely
  /// appear without explicit type arguments as the bounds of a type parameter
  /// declaration.
  ///
  /// If the element does not define a type, returns `true`.
  bool get isSimplyBounded;

  @override
  LibraryElement get library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2;

  /// The type parameters declared by this element directly.
  ///
  /// This does not include type parameters that are declared by any enclosing
  /// elements.
  List<TypeParameterElement> get typeParameters;

  /// The type parameters declared by this element directly.
  ///
  /// This does not include type parameters that are declared by any enclosing
  /// elements.
  @Deprecated('Use typeParameters instead')
  List<TypeParameterElement> get typeParameters2;
}

/// The portion of a [TypeParameterizedElement] contributed by a single
/// declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterizedFragment
    implements
        Fragment,
        Annotatable // ignore:deprecated_member_use_from_same_package
        {
  @override
  TypeParameterizedElement get element;

  @override
  TypeParameterizedFragment? get nextFragment;

  @override
  TypeParameterizedFragment? get previousFragment;

  /// The type parameters declared by this fragment directly.
  ///
  /// This does not include type parameters that are declared by any enclosing
  /// fragments.
  List<TypeParameterFragment> get typeParameters;

  /// The type parameters declared by this fragment directly.
  ///
  /// This does not include type parameters that are declared by any enclosing
  /// fragments.
  @Deprecated('Use typeParameters instead')
  List<TypeParameterFragment> get typeParameters2;
}

/// A variable.
///
/// There are more specific subclasses for more specific kinds of variables.
///
/// Clients may not extend, implement or mix-in this class.
abstract class VariableElement implements Element {
  /// The constant initializer for this constant variable, or the default
  /// value for this formal parameter.
  ///
  /// Is `null` if this variable is not a constant, or does not have the
  /// initializer or the default value specified.
  Expression? get constantInitializer;

  @override
  VariableFragment get firstFragment;

  @override
  List<VariableFragment> get fragments;

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

/// The portion of a [VariableElement] contributed by a single declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class VariableFragment implements Fragment {
  @override
  VariableElement get element;

  @override
  VariableFragment? get nextFragment;

  @override
  VariableFragment? get previousFragment;
}
