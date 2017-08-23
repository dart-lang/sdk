// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the element model. The element model describes the semantic (as
 * opposed to syntactic) structure of Dart code. The syntactic structure of the
 * code is modeled by the [AST structure](../ast/ast.dart).
 *
 * The element model consists of two closely related kinds of objects: elements
 * (instances of a subclass of [Element]) and types. This library defines the
 * elements, the types are defined in [type.dart](type.dart).
 *
 * Generally speaking, an element represents something that is declared in the
 * code, such as a class, method, or variable. Elements are organized in a tree
 * structure in which the children of an element are the elements that are
 * logically (and often syntactically) part of the declaration of the parent.
 * For example, the elements representing the methods and fields in a class are
 * children of the element representing the class.
 *
 * Every complete element structure is rooted by an instance of the class
 * [LibraryElement]. A library element represents a single Dart library. Every
 * library is defined by one or more compilation units (the library and all of
 * its parts). The compilation units are represented by the class
 * [CompilationUnitElement] and are children of the library that is defined by
 * them. Each compilation unit can contain zero or more top-level declarations,
 * such as classes, functions, and variables. Each of these is in turn
 * represented as an element that is a child of the compilation unit. Classes
 * contain methods and fields, methods can contain local variables, etc.
 *
 * The element model does not contain everything in the code, only those things
 * that are declared by the code. For example, it does not include any
 * representation of the statements in a method body, but if one of those
 * statements declares a local variable then the local variable will be
 * represented by an element.
 */
library analyzer.dart.element.element;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/resolution_base_classes.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/model.dart' show AnalysisTarget;

/**
 * An element that represents a class.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ClassElement
    implements TypeDefiningElement, TypeParameterizedElement {
  /**
   * An empty list of class elements.
   */
  static const List<ClassElement> EMPTY_LIST = const <ClassElement>[];

  /**
   * Return a list containing all of the accessors (getters and setters)
   * declared in this class.
   */
  List<PropertyAccessorElement> get accessors;

  /**
   * Return a list containing all the supertypes defined for this class and its
   * supertypes. This includes superclasses, mixins and interfaces.
   */
  List<InterfaceType> get allSupertypes;

  /**
   * Return a list containing all of the constructors declared in this class.
   */
  List<ConstructorElement> get constructors;

  /**
   * Return a list containing all of the fields declared in this class.
   */
  List<FieldElement> get fields;

  /**
   * Return `true` if this class or its superclass declares a non-final instance
   * field.
   */
  bool get hasNonFinalField;

  /**
   * Return `true` if this class has reference to super (so, for example, cannot
   * be used as a mixin).
   */
  bool get hasReferenceToSuper;

  /**
   * Return `true` if this class declares a static member.
   */
  bool get hasStaticMember;

  /**
   * Return a list containing all of the interfaces that are implemented by this
   * class.
   *
   * <b>Note:</b> Because the element model represents the state of the code, it
   * is possible for it to be semantically invalid. In particular, it is not
   * safe to assume that the inheritance structure of a class does not contain a
   * cycle. Clients that traverse the inheritance structure must explicitly
   * guard against infinite loops.
   */
  List<InterfaceType> get interfaces;

  /**
   * Return `true` if this class is abstract. A class is abstract if it has an
   * explicit `abstract` modifier. Note, that this definition of <i>abstract</i>
   * is different from <i>has unimplemented members</i>.
   */
  bool get isAbstract;

  /**
   * Return `true` if this class is defined by an enum declaration.
   */
  bool get isEnum;

  /**
   * Return `true` if this class is a mixin application.  A class is a mixin
   * application if it was declared using the syntax "class A = B with C;".
   */
  bool get isMixinApplication;

  /**
   * Return `true` if this class [isProxy], or if it inherits the proxy
   * annotation from a supertype.
   */
  bool get isOrInheritsProxy;

  /**
   * Return `true` if this element has an annotation of the form '@proxy'.
   */
  bool get isProxy;

  /**
   * Return `true` if this class can validly be used as a mixin when defining
   * another class. The behavior of this method is defined by the Dart Language
   * Specification in section 9:
   * <blockquote>
   * It is a compile-time error if a declared or derived mixin refers to super.
   * It is a compile-time error if a declared or derived mixin explicitly
   * declares a constructor. It is a compile-time error if a mixin is derived
   * from a class whose superclass is not Object.
   * </blockquote>
   */
  bool get isValidMixin;

  /**
   * Return a list containing all of the methods declared in this class.
   */
  List<MethodElement> get methods;

  /**
   * Return a list containing all of the mixins that are applied to the class
   * being extended in order to derive the superclass of this class.
   *
   * <b>Note:</b> Because the element model represents the state of the code, it
   * is possible for it to be semantically invalid. In particular, it is not
   * safe to assume that the inheritance structure of a class does not contain a
   * cycle. Clients that traverse the inheritance structure must explicitly
   * guard against infinite loops.
   */
  List<InterfaceType> get mixins;

  /**
   * Return the superclass of this class, or `null` if the class represents the
   * class 'Object'. All other classes will have a non-`null` superclass. If the
   * superclass was not explicitly declared then the implicit superclass
   * 'Object' will be returned.
   *
   * <b>Note:</b> Because the element model represents the state of the code, it
   * is possible for it to be semantically invalid. In particular, it is not
   * safe to assume that the inheritance structure of a class does not contain a
   * cycle. Clients that traverse the inheritance structure must explicitly
   * guard against infinite loops.
   */
  InterfaceType get supertype;

  @override
  InterfaceType get type;

  /**
   * Return the unnamed constructor declared in this class, or `null` if this
   * class does not declare an unnamed constructor but does declare named
   * constructors. The returned constructor will be synthetic if this class does
   * not declare any constructors, in which case it will represent the default
   * constructor for the class.
   */
  ConstructorElement get unnamedConstructor;

  @override
  NamedCompilationUnitMember computeNode();

  /**
   * Return the field (synthetic or explicit) defined in this class that has the
   * given [name], or `null` if this class does not define a field with the
   * given name.
   */
  FieldElement getField(String name);

  /**
   * Return the element representing the getter with the given [name] that is
   * declared in this class, or `null` if this class does not declare a getter
   * with the given name.
   */
  PropertyAccessorElement getGetter(String name);

  /**
   * Return the element representing the method with the given [name] that is
   * declared in this class, or `null` if this class does not declare a method
   * with the given name.
   */
  MethodElement getMethod(String name);

  /**
   * Return the named constructor declared in this class with the given [name],
   * or `null` if this class does not declare a named constructor with the given
   * name.
   */
  ConstructorElement getNamedConstructor(String name);

  /**
   * Return the element representing the setter with the given [name] that is
   * declared in this class, or `null` if this class does not declare a setter
   * with the given name.
   */
  PropertyAccessorElement getSetter(String name);

  /**
   * Determine whether the given [constructor], which exists in the superclass
   * of this class, is accessible to constructors in this class.
   */
  bool isSuperConstructorAccessible(ConstructorElement constructor);

  /**
   * Return the element representing the method that results from looking up the
   * given [methodName] in this class with respect to the given [library],
   * ignoring abstract methods, or `null` if the look up fails. The behavior of
   * this method is defined by the Dart Language Specification in section
   * 16.15.1:
   * <blockquote>
   * The result of looking up method <i>m</i> in class <i>C</i> with respect to
   * library <i>L</i> is: If <i>C</i> declares an instance method named <i>m</i>
   * that is accessible to <i>L</i>, then that method is the result of the
   * lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result
   * of the lookup is the result of looking up method <i>m</i> in <i>S</i> with
   * respect to <i>L</i>. Otherwise, we say that the lookup has failed.
   * </blockquote>
   */
  MethodElement lookUpConcreteMethod(String methodName, LibraryElement library);

  /**
   * Return the element representing the getter that results from looking up the
   * given [getterName] in this class with respect to the given [library], or
   * `null` if the look up fails. The behavior of this method is defined by the
   * Dart Language Specification in section 16.15.2:
   * <blockquote>
   * The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is: If <i>C</i> declares an
   * instance getter (respectively setter) named <i>m</i> that is accessible to
   * <i>L</i>, then that getter (respectively setter) is the result of the
   * lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result
   * of the lookup is the result of looking up getter (respectively setter)
   * <i>m</i> in <i>S</i> with respect to <i>L</i>. Otherwise, we say that the
   * lookup has failed.
   * </blockquote>
   */
  PropertyAccessorElement lookUpGetter(
      String getterName, LibraryElement library);

  /**
   * Return the element representing the getter that results from looking up the
   * given [getterName] in the superclass of this class with respect to the
   * given [library], ignoring abstract getters, or `null` if the look up fails.
   * The behavior of this method is defined by the Dart Language Specification
   * in section 16.15.2:
   * <blockquote>
   * The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is: If <i>C</i> declares an
   * instance getter (respectively setter) named <i>m</i> that is accessible to
   * <i>L</i>, then that getter (respectively setter) is the result of the
   * lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result
   * of the lookup is the result of looking up getter (respectively setter)
   * <i>m</i> in <i>S</i> with respect to <i>L</i>. Otherwise, we say that the
   * lookup has failed.
   * </blockquote>
   */
  PropertyAccessorElement lookUpInheritedConcreteGetter(
      String getterName, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the
   * given [methodName] in the superclass of this class with respect to the
   * given [library], ignoring abstract methods, or `null` if the look up fails.
   * The behavior of this method is defined by the Dart Language Specification
   * in section 16.15.1:
   * <blockquote>
   * The result of looking up method <i>m</i> in class <i>C</i> with respect to
   * library <i>L</i> is:  If <i>C</i> declares an instance method named
   * <i>m</i> that is accessible to <i>L</i>, then that method is the result of
   * the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
   * result of the lookup is the result of looking up method <i>m</i> in
   * <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
   * failed.
   * </blockquote>
   */
  MethodElement lookUpInheritedConcreteMethod(
      String methodName, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the
   * given [setterName] in the superclass of this class with respect to the
   * given [library], ignoring abstract setters, or `null` if the look up fails.
   * The behavior of this method is defined by the Dart Language Specification
   * in section 16.15.2:
   * <blockquote>
   * The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is:  If <i>C</i> declares an
   * instance getter (respectively setter) named <i>m</i> that is accessible to
   * <i>L</i>, then that getter (respectively setter) is the result of the
   * lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result
   * of the lookup is the result of looking up getter (respectively setter)
   * <i>m</i> in <i>S</i> with respect to <i>L</i>. Otherwise, we say that the
   * lookup has failed.
   * </blockquote>
   */
  PropertyAccessorElement lookUpInheritedConcreteSetter(
      String setterName, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the
   * given [methodName] in the superclass of this class with respect to the
   * given [library], or `null` if the look up fails. The behavior of this
   * method is defined by the Dart Language Specification in section 16.15.1:
   * <blockquote>
   * The result of looking up method <i>m</i> in class <i>C</i> with respect to
   * library <i>L</i> is:  If <i>C</i> declares an instance method named
   * <i>m</i> that is accessible to <i>L</i>, then that method is the result of
   * the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
   * result of the lookup is the result of looking up method <i>m</i> in
   * <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
   * failed.
   * </blockquote>
   */
  MethodElement lookUpInheritedMethod(
      String methodName, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the
   * given [methodName] in this class with respect to the given [library], or
   * `null` if the look up fails. The behavior of this method is defined by the
   * Dart Language Specification in section 16.15.1:
   * <blockquote>
   * The result of looking up method <i>m</i> in class <i>C</i> with respect to
   * library <i>L</i> is:  If <i>C</i> declares an instance method named
   * <i>m</i> that is accessible to <i>L</i>, then that method is the result of
   * the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
   * result of the lookup is the result of looking up method <i>m</i> in
   * <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
   * failed.
   * </blockquote>
   */
  MethodElement lookUpMethod(String methodName, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the
   * given [setterName] in this class with respect to the given [library], or
   * `null` if the look up fails. The behavior of this method is defined by the
   * Dart Language Specification in section 16.15.2:
   * <blockquote>
   * The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is: If <i>C</i> declares an
   * instance getter (respectively setter) named <i>m</i> that is accessible to
   * <i>L</i>, then that getter (respectively setter) is the result of the
   * lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result
   * of the lookup is the result of looking up getter (respectively setter)
   * <i>m</i> in <i>S</i> with respect to <i>L</i>. Otherwise, we say that the
   * lookup has failed.
   * </blockquote>
   */
  PropertyAccessorElement lookUpSetter(
      String setterName, LibraryElement library);
}

/**
 * An element that is contained within a [ClassElement].
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ClassMemberElement implements Element {
  @override
  ClassElement get enclosingElement;

  /**
   * Return `true` if this element is a static element. A static element is an
   * element that is not associated with a particular instance, but rather with
   * an entire library or class.
   */
  bool get isStatic;
}

/**
 * An element representing a compilation unit.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class CompilationUnitElement implements Element, UriReferencedElement {
  /**
   * An empty list of compilation unit elements.
   */
  static const List<CompilationUnitElement> EMPTY_LIST =
      const <CompilationUnitElement>[];

  /**
   * Return a list containing all of the top-level accessors (getters and
   * setters) contained in this compilation unit.
   */
  List<PropertyAccessorElement> get accessors;

  @override
  LibraryElement get enclosingElement;

  /**
   * Return a list containing all of the enums contained in this compilation
   * unit.
   */
  List<ClassElement> get enums;

  /**
   * Return a list containing all of the top-level functions contained in this
   * compilation unit.
   */
  List<FunctionElement> get functions;

  /**
   * Return a list containing all of the function type aliases contained in this
   * compilation unit.
   */
  List<FunctionTypeAliasElement> get functionTypeAliases;

  /**
   * Return `true` if this compilation unit defines a top-level function named
   * `loadLibrary`.
   */
  bool get hasLoadLibraryFunction;

  /**
   * Return the [LineInfo] for the [source], or `null` if not computed yet.
   */
  LineInfo get lineInfo;

  /**
   * Return a list containing all of the top-level variables contained in this
   * compilation unit.
   */
  List<TopLevelVariableElement> get topLevelVariables;

  /**
   * Return a list containing all of the classes contained in this compilation
   * unit.
   */
  List<ClassElement> get types;

  @override
  CompilationUnit computeNode();

  /**
   * Return the enum defined in this compilation unit that has the given [name],
   * or `null` if this compilation unit does not define an enum with the given
   * name.
   */
  ClassElement getEnum(String name);

  /**
   * Return the class defined in this compilation unit that has the given
   * [name], or `null` if this compilation unit does not define a class with the
   * given name.
   */
  ClassElement getType(String name);
}

/**
 * An element representing a constructor or a factory method defined within a
 * class.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ConstructorElement
    implements ClassMemberElement, ExecutableElement, ConstantEvaluationTarget {
  /**
   * An empty list of constructor elements.
   */
  static const List<ConstructorElement> EMPTY_LIST =
      const <ConstructorElement>[];

  /**
   * Return `true` if this constructor is a const constructor.
   */
  bool get isConst;

  /**
   * Return `true` if this constructor can be used as a default constructor -
   * unnamed and has no required parameters.
   */
  bool get isDefaultConstructor;

  /**
   * Return `true` if this constructor represents a factory constructor.
   */
  bool get isFactory;

  /**
   * Return the offset of the character immediately following the last character
   * of this constructor's name, or `null` if not named.
   */
  int get nameEnd;

  /**
   * Return the offset of the `.` before this constructor name, or `null` if
   * not named.
   */
  int get periodOffset;

  /**
   * Return the constructor to which this constructor is redirecting, or `null`
   * if this constructor does not redirect to another constructor or if the
   * library containing this constructor has not yet been resolved.
   */
  ConstructorElement get redirectedConstructor;

  @override
  ConstructorDeclaration computeNode();
}

/**
 * The base class for all of the elements in the element model. Generally
 * speaking, the element model is a semantic model of the program that
 * represents things that are declared with a name and hence can be referenced
 * elsewhere in the code.
 *
 * There are two exceptions to the general case. First, there are elements in
 * the element model that are created for the convenience of various kinds of
 * analysis but that do not have any corresponding declaration within the source
 * code. Such elements are marked as being <i>synthetic</i>. Examples of
 * synthetic elements include
 * * default constructors in classes that do not define any explicit
 *   constructors,
 * * getters and setters that are induced by explicit field declarations,
 * * fields that are induced by explicit declarations of getters and setters,
 *   and
 * * functions representing the initialization expression for a variable.
 *
 * Second, there are elements in the element model that do not have a name.
 * These correspond to unnamed functions and exist in order to more accurately
 * represent the semantic structure of the program.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Element implements AnalysisTarget, ResolutionTarget {
  /**
   * A comparator that can be used to sort elements by their name offset.
   * Elements with a smaller offset will be sorted to be before elements with a
   * larger name offset.
   */
  static final Comparator<Element> SORT_BY_OFFSET =
      (Element firstElement, Element secondElement) =>
          firstElement.nameOffset - secondElement.nameOffset;

  /**
   * Return the analysis context in which this element is defined.
   */
  AnalysisContext get context;

  /**
   * Return the display name of this element, or `null` if this element does not
   * have a name.
   *
   * In most cases the name and the display name are the same. Differences
   * though are cases such as setters where the name of some setter `set f(x)`
   * is `f=`, instead of `f`.
   */
  String get displayName;

  /**
   * Return the content of the documentation comment (including delimiters) for
   * this element, or `null` if this element does not or cannot have
   * documentation.
   */
  String get documentationComment;

  /**
   * Return the element that either physically or logically encloses this
   * element. This will be `null` if this element is a library because libraries
   * are the top-level elements in the model.
   */
  Element get enclosingElement;

  /**
   * The unique integer identifier of this element.
   */
  int get id;

  /**
   * Return `true` if this element has an annotation of the form '@deprecated'
   * or '@Deprecated('..')'.
   */
  bool get isDeprecated;

  /**
   * Return `true` if this element has an annotation of the form '@factory'.
   */
  bool get isFactory;

  /**
   * Return `true` if this element has an annotation of the form '@JS(..)'.
   */
  bool get isJS;

  /**
   * Return `true` if this element has an annotation of the form '@override'.
   */
  bool get isOverride;

  /**
   * Return `true` if this element is private. Private elements are visible only
   * within the library in which they are declared.
   */
  bool get isPrivate;

  /**
   * Return `true` if this element has an annotation of the form '@protected'.
   */
  bool get isProtected;

  /**
   * Return `true` if this element is public. Public elements are visible within
   * any library that imports the library in which they are declared.
   */
  bool get isPublic;

  /**
   * Return `true` if this element has an annotation of the form '@required'.
   */
  bool get isRequired;

  /**
   * Return `true` if this element is synthetic. A synthetic element is an
   * element that is not represented in the source code explicitly, but is
   * implied by the source code, such as the default constructor for a class
   * that does not explicitly define any constructors.
   */
  bool get isSynthetic;

  /**
   * Return the kind of element that this is.
   */
  ElementKind get kind;

  /**
   * Return the library that contains this element. This will be the element
   * itself if it is a library element. This will be `null` if this element is
   * an HTML file because HTML files are not contained in libraries.
   */
  LibraryElement get library;

  /**
   * Return an object representing the location of this element in the element
   * model. The object can be used to locate this element at a later time.
   */
  ElementLocation get location;

  /**
   * Return a list containing all of the metadata associated with this element.
   * The array will be empty if the element does not have any metadata or if the
   * library containing this element has not yet been resolved.
   */
  List<ElementAnnotation> get metadata;

  /**
   * Return the name of this element, or `null` if this element does not have a
   * name.
   */
  String get name;

  /**
   * Return the length of the name of this element in the file that contains the
   * declaration of this element, or `0` if this element does not have a name.
   */
  int get nameLength;

  /**
   * Return the offset of the name of this element in the file that contains the
   * declaration of this element, or `-1` if this element is synthetic, does not
   * have a name, or otherwise does not have an offset.
   */
  int get nameOffset;

  @override
  Source get source;

  /**
   * Return the resolved [CompilationUnit] that declares this element, or `null`
   * if this element is synthetic.
   *
   * This method is expensive, because resolved AST might have been already
   * evicted from cache, so parsing and resolving will be performed.
   */
  CompilationUnit get unit;

  /**
   * Use the given [visitor] to visit this element. Return the value returned by
   * the visitor as a result of visiting this element.
   */
  T accept<T>(ElementVisitor<T> visitor);

  /**
   * Return the documentation comment for this element as it appears in the
   * original source (complete with the beginning and ending delimiters), or
   * `null` if this element does not have a documentation comment associated
   * with it. This can be a long-running operation if the information needed to
   * access the comment is not cached.
   *
   * Throws [AnalysisException] if the documentation comment could not be
   * determined because the analysis could not be performed
   *
   * Deprecated.  Use [documentationComment] instead.
   */
  @deprecated
  String computeDocumentationComment();

  /**
   * Return the resolved [AstNode] node that declares this element, or `null` if
   * this element is synthetic or isn't contained in a compilation unit, such as
   * a [LibraryElement].
   *
   * This method is expensive, because resolved AST might be evicted from cache,
   * so parsing and resolving will be performed.
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   */
  AstNode computeNode();

  /**
   * Return the most immediate ancestor of this element for which the
   * [predicate] returns `true`, or `null` if there is no such ancestor. Note
   * that this element will never be returned.
   */
  E getAncestor<E extends Element>(Predicate<Element> predicate);

  /**
   * Return a display name for the given element that includes the path to the
   * compilation unit in which the type is defined. If [shortName] is `null`
   * then [displayName] will be used as the name of this element. Otherwise
   * the provided name will be used.
   */
  // TODO(brianwilkerson) Make the parameter optional.
  String getExtendedDisplayName(String shortName);

  /**
   * Return `true` if this element, assuming that it is within scope, is
   * accessible to code in the given [library]. This is defined by the Dart
   * Language Specification in section 3.2:
   * <blockquote>
   * A declaration <i>m</i> is accessible to library <i>L</i> if <i>m</i> is
   * declared in <i>L</i> or if <i>m</i> is public.
   * </blockquote>
   */
  bool isAccessibleIn(LibraryElement library);

  /**
   * Use the given [visitor] to visit all of the children of this element. There
   * is no guarantee of the order in which the children will be visited.
   */
  void visitChildren(ElementVisitor visitor);
}

/**
 * A single annotation associated with an element.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ElementAnnotation
    implements ConstantEvaluationTarget, ResolutionTarget {
  /**
   * An empty list of annotations.
   */
  static const List<ElementAnnotation> EMPTY_LIST = const <ElementAnnotation>[];

  /**
   * Return a representation of the value of this annotation.
   *
   * Return `null` if the value of this annotation could not be computed because
   * of errors.
   */
  DartObject get constantValue;

  /**
   * Return the element representing the field, variable, or const constructor
   * being used as an annotation.
   */
  Element get element;

  /**
   * Return `true` if this annotation marks the associated element as being
   * deprecated.
   */
  bool get isDeprecated;

  /**
   * Return `true` if this annotation marks the associated member as a factory.
   */
  bool get isFactory;

  /**
   * Return `true` if this annotation marks the associated class and its
   * subclasses as being immutable.
   */
  bool get isImmutable;

  /**
   * Return `true` if this annotation marks the associated element with the `JS`
   * annotation.
   */
  bool get isJS;

  /**
   * Return `true` if this annotation marks the associated member as requiring
   * overriding methods to call super.
   */
  bool get isMustCallSuper;

  /**
   * Return `true` if this annotation marks the associated method as being
   * expected to override an inherited method.
   */
  bool get isOverride;

  /**
   * Return `true` if this annotation marks the associated member as being
   * protected.
   */
  bool get isProtected;

  /**
   * Return `true` if this annotation marks the associated class as implementing
   * a proxy object.
   */
  bool get isProxy;

  /**
   * Return `true` if this annotation marks the associated member as being
   * required.
   */
  bool get isRequired;

  /**
   * Return a representation of the value of this annotation, forcing the value
   * to be computed if it had not previously been computed, or `null` if the
   * value of this annotation could not be computed because of errors.
   */
  DartObject computeConstantValue();

  /**
   * Return a textual description of this annotation in a form approximating
   * valid source. The returned string will not be valid source primarily in the
   * case where the annotation itself is not well-formed.
   */
  String toSource();
}

/**
 * The kind of elements in the element model.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ElementKind implements Comparable<ElementKind> {
  static const ElementKind CLASS = const ElementKind('CLASS', 0, "class");

  static const ElementKind COMPILATION_UNIT =
      const ElementKind('COMPILATION_UNIT', 1, "compilation unit");

  static const ElementKind CONSTRUCTOR =
      const ElementKind('CONSTRUCTOR', 2, "constructor");

  static const ElementKind DYNAMIC =
      const ElementKind('DYNAMIC', 3, "<dynamic>");

  static const ElementKind ERROR = const ElementKind('ERROR', 4, "<error>");

  static const ElementKind EXPORT =
      const ElementKind('EXPORT', 5, "export directive");

  static const ElementKind FIELD = const ElementKind('FIELD', 6, "field");

  static const ElementKind FUNCTION =
      const ElementKind('FUNCTION', 7, "function");

  static const ElementKind GENERIC_FUNCTION_TYPE =
      const ElementKind('GENERIC_FUNCTION_TYPE', 8, 'generic function type');

  static const ElementKind GETTER = const ElementKind('GETTER', 9, "getter");

  static const ElementKind IMPORT =
      const ElementKind('IMPORT', 10, "import directive");

  static const ElementKind LABEL = const ElementKind('LABEL', 11, "label");

  static const ElementKind LIBRARY =
      const ElementKind('LIBRARY', 12, "library");

  static const ElementKind LOCAL_VARIABLE =
      const ElementKind('LOCAL_VARIABLE', 13, "local variable");

  static const ElementKind METHOD = const ElementKind('METHOD', 14, "method");

  static const ElementKind NAME = const ElementKind('NAME', 15, "<name>");

  static const ElementKind PARAMETER =
      const ElementKind('PARAMETER', 16, "parameter");

  static const ElementKind PREFIX =
      const ElementKind('PREFIX', 17, "import prefix");

  static const ElementKind SETTER = const ElementKind('SETTER', 18, "setter");

  static const ElementKind TOP_LEVEL_VARIABLE =
      const ElementKind('TOP_LEVEL_VARIABLE', 19, "top level variable");

  static const ElementKind FUNCTION_TYPE_ALIAS =
      const ElementKind('FUNCTION_TYPE_ALIAS', 20, "function type alias");

  static const ElementKind TYPE_PARAMETER =
      const ElementKind('TYPE_PARAMETER', 21, "type parameter");

  static const ElementKind UNIVERSE =
      const ElementKind('UNIVERSE', 22, "<universe>");

  static const List<ElementKind> values = const [
    CLASS,
    COMPILATION_UNIT,
    CONSTRUCTOR,
    DYNAMIC,
    ERROR,
    EXPORT,
    FIELD,
    FUNCTION,
    GENERIC_FUNCTION_TYPE,
    GETTER,
    IMPORT,
    LABEL,
    LIBRARY,
    LOCAL_VARIABLE,
    METHOD,
    NAME,
    PARAMETER,
    PREFIX,
    SETTER,
    TOP_LEVEL_VARIABLE,
    FUNCTION_TYPE_ALIAS,
    TYPE_PARAMETER,
    UNIVERSE
  ];

  /**
   * The name of this element kind.
   */
  final String name;

  /**
   * The ordinal value of the element kind.
   */
  final int ordinal;

  /**
   * The name displayed in the UI for this kind of element.
   */
  final String displayName;

  /**
   * Initialize a newly created element kind to have the given [displayName].
   */
  const ElementKind(this.name, this.ordinal, this.displayName);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(ElementKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;

  /**
   * Return the kind of the given [element], or [ERROR] if the element is
   * `null`. This is a utility method that can reduce the need for null checks
   * in other places.
   */
  static ElementKind of(Element element) {
    if (element == null) {
      return ERROR;
    }
    return element.kind;
  }
}

/**
 * The location of an element within the element model.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ElementLocation {
  /**
   * Return the path to the element whose location is represented by this
   * object. Clients must not modify the returned array.
   */
  List<String> get components;

  /**
   * Return an encoded representation of this location that can be used to
   * create a location that is equal to this location.
   */
  String get encoding;
}

/**
 * An object that can be used to visit an element structure.
 *
 * Clients may not extend, implement or mix-in this class. There are classes
 * that implement this interface that provide useful default behaviors in
 * `package:analyzer/dart/ast/visitor.dart`. A couple of the most useful include
 * * SimpleElementVisitor which implements every visit method by doing nothing,
 * * RecursiveElementVisitor which will cause every node in a structure to be
 *   visited, and
 * * ThrowingElementVisitor which implements every visit method by throwing an
 *   exception.
 */
abstract class ElementVisitor<R> {
  R visitClassElement(ClassElement element);

  R visitCompilationUnitElement(CompilationUnitElement element);

  R visitConstructorElement(ConstructorElement element);

  R visitExportElement(ExportElement element);

  R visitFieldElement(FieldElement element);

  R visitFieldFormalParameterElement(FieldFormalParameterElement element);

  R visitFunctionElement(FunctionElement element);

  R visitFunctionTypeAliasElement(FunctionTypeAliasElement element);

  R visitGenericFunctionTypeElement(GenericFunctionTypeElement element);

  R visitImportElement(ImportElement element);

  R visitLabelElement(LabelElement element);

  R visitLibraryElement(LibraryElement element);

  R visitLocalVariableElement(LocalVariableElement element);

  R visitMethodElement(MethodElement element);

  R visitMultiplyDefinedElement(MultiplyDefinedElement element);

  R visitParameterElement(ParameterElement element);

  R visitPrefixElement(PrefixElement element);

  R visitPropertyAccessorElement(PropertyAccessorElement element);

  R visitTopLevelVariableElement(TopLevelVariableElement element);

  R visitTypeParameterElement(TypeParameterElement element);
}

/**
 * An element representing an executable object, including functions, methods,
 * constructors, getters, and setters.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ExecutableElement implements FunctionTypedElement {
  /**
   * An empty list of executable elements.
   */
  static const List<ExecutableElement> EMPTY_LIST = const <ExecutableElement>[];

  /**
   * Return a list containing all of the functions defined within this
   * executable element.
   */
  List<FunctionElement> get functions;

  /**
   * Return `true` if this executable element did not have an explicit return
   * type specified for it in the original source. Note that if there was no
   * explicit return type, and if the element model is fully populated, then
   * the [returnType] will not be `null`.
   */
  bool get hasImplicitReturnType;

  /**
   * Return `true` if this executable element is abstract. Executable elements
   * are abstract if they are not external and have no body.
   */
  bool get isAbstract;

  /**
   * Return `true` if this executable element has body marked as being
   * asynchronous.
   */
  bool get isAsynchronous;

  /**
   * Return `true` if this executable element is external. Executable elements
   * are external if they are explicitly marked as such using the 'external'
   * keyword.
   */
  bool get isExternal;

  /**
   * Return `true` if this executable element has a body marked as being a
   * generator.
   */
  bool get isGenerator;

  /**
   * Return `true` if this executable element is an operator. The test may be
   * based on the name of the executable element, in which case the result will
   * be correct when the name is legal.
   */
  bool get isOperator;

  /**
   * Return `true` if this element is a static element. A static element is an
   * element that is not associated with a particular instance, but rather with
   * an entire library or class.
   */
  bool get isStatic;

  /**
   * Return `true` if this executable element has a body marked as being
   * synchronous.
   */
  bool get isSynchronous;
}

/**
 * An export directive within a library.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ExportElement implements Element, UriReferencedElement {
  /**
   * An empty list of export elements.
   */
  static const List<ExportElement> EMPTY_LIST = const <ExportElement>[];

  /**
   * Return a list containing the combinators that were specified as part of the
   * export directive in the order in which they were specified.
   */
  List<NamespaceCombinator> get combinators;

  /**
   * Return the library that is exported from this library by this export
   * directive.
   */
  LibraryElement get exportedLibrary;
}

/**
 * A field defined within a type.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FieldElement
    implements ClassMemberElement, PropertyInducingElement {
  /**
   * An empty list of field elements.
   */
  static const List<FieldElement> EMPTY_LIST = const <FieldElement>[];

  /**
   * Return {@code true} if this element is an enum constant.
   */
  bool get isEnumConstant;

  /**
   * Returns `true` if this field can be overridden in strong mode.
   */
  bool get isVirtual;

  @override
  AstNode computeNode();
}

/**
 * A field formal parameter defined within a constructor element.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FieldFormalParameterElement implements ParameterElement {
  /**
   * Return the field element associated with this field formal parameter, or
   * `null` if the parameter references a field that doesn't exist.
   */
  FieldElement get field;
}

/**
 * A (non-method) function. This can be either a top-level function, a local
 * function, a closure, or the initialization expression for a field or
 * variable.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionElement implements ExecutableElement, LocalElement {
  /**
   * An empty list of function elements.
   */
  static const List<FunctionElement> EMPTY_LIST = const <FunctionElement>[];

  /**
   * The name of the method that can be implemented by a class to allow its
   * instances to be invoked as if they were a function.
   */
  static final String CALL_METHOD_NAME = "call";

  /**
   * The name of the synthetic function defined for libraries that are deferred.
   */
  static final String LOAD_LIBRARY_NAME = "loadLibrary";

  /**
   * The name of the function used as an entry point.
   */
  static const String MAIN_FUNCTION_NAME = "main";

  /**
   * The name of the method that will be invoked if an attempt is made to invoke
   * an undefined method on an object.
   */
  static final String NO_SUCH_METHOD_METHOD_NAME = "noSuchMethod";

  /**
   * Return `true` if the function is an entry point, i.e. a top-level function
   * and has the name `main`.
   */
  bool get isEntryPoint;

  @override
  FunctionDeclaration computeNode();
}

/**
 * A function type alias (`typedef`).
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionTypeAliasElement
    implements FunctionTypedElement, TypeDefiningElement {
  /**
   * An empty array of type alias elements.
   */
  static List<FunctionTypeAliasElement> EMPTY_LIST =
      new List<FunctionTypeAliasElement>(0);

  @override
  CompilationUnitElement get enclosingElement;

  @override
  TypeAlias computeNode();
}

/**
 * An element that has a [FunctionType] as its [type].
 *
 * This also provides convenient access to the parameters and return type.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionTypedElement implements TypeParameterizedElement {
  /**
   * Return a list containing all of the parameters defined by this executable
   * element.
   */
  List<ParameterElement> get parameters;

  /**
   * Return the return type defined by this element. If the element model is
   * fully populated, then the [returnType] will not be `null`, even if no
   * return type was explicitly specified.
   */
  DartType get returnType;

  @override
  FunctionType get type;
}

/**
 * The pseudo-declaration that defines a generic function type.
 *
 * Clients may not extend, implement, or mix-in this class.
 */
abstract class GenericFunctionTypeElement implements FunctionTypedElement {}

/**
 * A [FunctionTypeAliasElement] whose returned function type has a [type]
 * parameter.
 *
 * Clients may not extend, implement, or mix-in this class.
 */
abstract class GenericTypeAliasElement implements FunctionTypeAliasElement {
  /**
   * Return the generic function type element representing the generic function
   * type on the right side of the equals.
   */
  GenericFunctionTypeElement get function;
}

/**
 * A combinator that causes some of the names in a namespace to be hidden when
 * being imported.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class HideElementCombinator implements NamespaceCombinator {
  /**
   * Return a list containing the names that are not to be made visible in the
   * importing library even if they are defined in the imported library.
   */
  List<String> get hiddenNames;
}

/**
 * A single import directive within a library.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ImportElement implements Element, UriReferencedElement {
  /**
   * An empty list of import elements.
   */
  static const List<ImportElement> EMPTY_LIST = const <ImportElement>[];

  /**
   * Return a list containing the combinators that were specified as part of the
   * import directive in the order in which they were specified.
   */
  List<NamespaceCombinator> get combinators;

  /**
   * Return the library that is imported into this library by this import
   * directive.
   */
  LibraryElement get importedLibrary;

  /**
   * Return `true` if this import is for a deferred library.
   */
  bool get isDeferred;

  /**
   * Return the prefix that was specified as part of the import directive, or
   * `null` if there was no prefix specified.
   */
  PrefixElement get prefix;

  /**
   * Return the offset of the prefix of this import in the file that contains
   * this import directive, or `-1` if this import is synthetic, does not have a
   * prefix, or otherwise does not have an offset.
   */
  int get prefixOffset;
}

/**
 * A label associated with a statement.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class LabelElement implements Element {
  /**
   * An empty list of label elements.
   */
  static const List<LabelElement> EMPTY_LIST = const <LabelElement>[];

  @override
  ExecutableElement get enclosingElement;
}

/**
 * A library.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class LibraryElement implements Element {
  /**
   * An empty list of library elements.
   */
  static const List<LibraryElement> EMPTY_LIST = const <LibraryElement>[];

  /**
   * Return the compilation unit that defines this library.
   */
  CompilationUnitElement get definingCompilationUnit;

  /**
   * Return the entry point for this library, or `null` if this library does not
   * have an entry point. The entry point is defined to be a zero argument
   * top-level function whose name is `main`.
   */
  FunctionElement get entryPoint;

  /**
   * Return a list containing all of the libraries that are exported from this
   * library.
   */
  List<LibraryElement> get exportedLibraries;

  /**
   * The export [Namespace] of this library, `null` if it has not been
   * computed yet.
   */
  Namespace get exportNamespace;

  /**
   * Return a list containing all of the exports defined in this library.
   */
  List<ExportElement> get exports;

  /**
   * Return `true` if the defining compilation unit of this library contains at
   * least one import directive whose URI uses the "dart-ext" scheme.
   */
  bool get hasExtUri;

  /**
   * Return `true` if this library defines a top-level function named
   * `loadLibrary`.
   */
  bool get hasLoadLibraryFunction;

  /**
   * Return an identifier that uniquely identifies this element among the
   * children of this element's parent.
   */
  String get identifier;

  /**
   * Return a list containing all of the libraries that are imported into this
   * library. This includes all of the libraries that are imported using a
   * prefix (also available through the prefixes returned by [getPrefixes]) and
   * those that are imported without a prefix.
   */
  List<LibraryElement> get importedLibraries;

  /**
   * Return a list containing all of the imports defined in this library.
   */
  List<ImportElement> get imports;

  /**
   * Return `true` if this library is an application that can be run in the
   * browser.
   */
  bool get isBrowserApplication;

  /**
   * Return `true` if this library is the dart:async library.
   */
  bool get isDartAsync;

  /**
   * Return `true` if this library is the dart:core library.
   */
  bool get isDartCore;

  /**
   * Return `true` if this library is part of the SDK.
   */
  bool get isInSdk;

  /**
   * Return a list containing the strongly connected component in the
   * import/export graph in which the current library resides.
   */
  List<LibraryElement> get libraryCycle;

  /**
   * Return the element representing the synthetic function `loadLibrary` that
   * is implicitly defined for this library if the library is imported using a
   * deferred import.
   */
  FunctionElement get loadLibraryFunction;

  /**
   * Return a list containing all of the compilation units that are included in
   * this library using a `part` directive. This does not include the defining
   * compilation unit that contains the `part` directives.
   */
  List<CompilationUnitElement> get parts;

  /**
   * Return a list containing elements for each of the prefixes used to `import`
   * libraries into this library. Each prefix can be used in more than one
   * `import` directive.
   */
  List<PrefixElement> get prefixes;

  /**
   * The public [Namespace] of this library, `null` if it has not been
   * computed yet.
   */
  Namespace get publicNamespace;

  /**
   * Return a list containing all of the compilation units this library consists
   * of. This includes the defining compilation unit and units included using
   * the `part` directive.
   */
  List<CompilationUnitElement> get units;

  /**
   * Return a list containing all of the imports that share the given [prefix],
   * or an empty array if there are no such imports.
   */
  List<ImportElement> getImportsWithPrefix(PrefixElement prefix);

  /**
   * Return the class defined in this library that has the given [name], or
   * `null` if this library does not define a class with the given name.
   */
  ClassElement getType(String className);
}

/**
 * An element that can be (but is not required to be) defined within a method
 * or function (an [ExecutableElement]).
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class LocalElement implements Element {
  /**
   * Return a source range that covers the approximate portion of the source in
   * which the name of this element is visible, or `null` if there is no single
   * range of characters within which the element name is visible.
   *
   * * For a local variable, this is the source range of the block that
   *   encloses the variable declaration.
   * * For a parameter, this includes the body of the method or function that
   *   declares the parameter.
   * * For a local function, this is the source range of the block that
   *   encloses the variable declaration.
   * * For top-level functions, `null` will be returned because they are
   *   potentially visible in multiple sources.
   */
  SourceRange get visibleRange;
}

/**
 * A local variable.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class LocalVariableElement implements LocalElement, VariableElement {
  /**
   * An empty list of field elements.
   */
  static const List<LocalVariableElement> EMPTY_LIST =
      const <LocalVariableElement>[];
}

/**
 * An element that represents a method defined within a type.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MethodElement implements ClassMemberElement, ExecutableElement {
  /**
   * An empty list of method elements.
   */
  static const List<MethodElement> EMPTY_LIST = const <MethodElement>[];

  @override
  MethodDeclaration computeNode();

  /**
   * Gets the reified type of a tear-off of this method.
   *
   * If any of the parameters in the method are covariant, they are replaced
   * with Object in the returned type. If no covariant parameters are present,
   * returns `this`.
   */
  @deprecated
  FunctionType getReifiedType(DartType objectType);
}

/**
 * A pseudo-element that represents multiple elements defined within a single
 * scope that have the same name. This situation is not allowed by the language,
 * so objects implementing this interface always represent an error. As a
 * result, most of the normal operations on elements do not make sense and will
 * return useless results.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MultiplyDefinedElement implements Element {
  /**
   * Return a list containing all of the elements that were defined within the
   * scope to have the same name.
   */
  List<Element> get conflictingElements;

  /**
   * Return the type of this element as the dynamic type.
   */
  DartType get type;
}

/**
 * An [ExecutableElement], with the additional information of a list of
 * [ExecutableElement]s from which this element was composed.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MultiplyInheritedExecutableElement implements ExecutableElement {
  /**
   * Return a list containing all of the executable elements defined within this
   * executable element.
   */
  List<ExecutableElement> get inheritedElements;
}

/**
 * An object that controls how namespaces are combined.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NamespaceCombinator {
  /**
   * An empty list of namespace combinators.
   */
  static const List<NamespaceCombinator> EMPTY_LIST =
      const <NamespaceCombinator>[];
}

/**
 * A parameter defined within an executable element.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ParameterElement
    implements LocalElement, VariableElement, ConstantEvaluationTarget {
  /**
   * An empty list of parameter elements.
   */
  static const List<ParameterElement> EMPTY_LIST = const <ParameterElement>[];

  /**
   * Return the Dart code of the default value, or `null` if no default value.
   */
  String get defaultValueCode;

  /**
   * Return `true` if this parameter is covariant, meaning it is allowed to have
   * a narrower type in an override.
   */
  bool get isCovariant;

  /**
   * Return `true` if this parameter is an initializing formal parameter.
   */
  bool get isInitializingFormal;

  /**
   * Return the kind of this parameter.
   */
  ParameterKind get parameterKind;

  /**
   * Return a list containing all of the parameters defined by this parameter.
   * A parameter will only define other parameters if it is a function typed
   * parameter.
   */
  List<ParameterElement> get parameters;

  /**
   * Return a list containing all of the type parameters defined by this
   * parameter. A parameter will only define other parameters if it is a
   * function typed parameter.
   */
  List<TypeParameterElement> get typeParameters;

  /**
   * Append the type, name and possibly the default value of this parameter to
   * the given [buffer].
   */
  void appendToWithoutDelimiters(StringBuffer buffer);

  @override
  FormalParameter computeNode();
}

/**
 * A prefix used to import one or more libraries into another library.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PrefixElement implements Element {
  /**
   * An empty list of prefix elements.
   */
  static const List<PrefixElement> EMPTY_LIST = const <PrefixElement>[];

  @override
  LibraryElement get enclosingElement;

  /**
   * Return the empty list.
   *
   * Deprecated: this getter was intended to return a list containing all of
   * the libraries that are imported using this prefix, but it was never
   * implemented.  Due to lack of demand, it is being removed.
   */
  @deprecated
  List<LibraryElement> get importedLibraries;
}

/**
 * A getter or a setter. Note that explicitly defined property accessors
 * implicitly define a synthetic field. Symmetrically, synthetic accessors are
 * implicitly created for explicitly defined fields. The following rules apply:
 *
 * * Every explicit field is represented by a non-synthetic [FieldElement].
 * * Every explicit field induces a getter and possibly a setter, both of which
 *   are represented by synthetic [PropertyAccessorElement]s.
 * * Every explicit getter or setter is represented by a non-synthetic
 *   [PropertyAccessorElement].
 * * Every explicit getter or setter (or pair thereof if they have the same
 *   name) induces a field that is represented by a synthetic [FieldElement].
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PropertyAccessorElement implements ExecutableElement {
  /**
   * An empty list of property accessor elements.
   */
  static const List<PropertyAccessorElement> EMPTY_LIST =
      const <PropertyAccessorElement>[];

  /**
   * Return the accessor representing the getter that corresponds to (has the
   * same name as) this setter, or `null` if this accessor is not a setter or if
   * there is no corresponding getter.
   */
  PropertyAccessorElement get correspondingGetter;

  /**
   * Return the accessor representing the setter that corresponds to (has the
   * same name as) this getter, or `null` if this accessor is not a getter or if
   * there is no corresponding setter.
   */
  PropertyAccessorElement get correspondingSetter;

  /**
   * Return `true` if this accessor represents a getter.
   */
  bool get isGetter;

  /**
   * Return `true` if this accessor represents a setter.
   */
  bool get isSetter;

  /**
   * Return the field or top-level variable associated with this accessor. If
   * this accessor was explicitly defined (is not synthetic) then the variable
   * associated with it will be synthetic.
   */
  PropertyInducingElement get variable;
}

/**
 * A variable that has an associated getter and possibly a setter. Note that
 * explicitly defined variables implicitly define a synthetic getter and that
 * non-`final` explicitly defined variables implicitly define a synthetic
 * setter. Symmetrically, synthetic fields are implicitly created for explicitly
 * defined getters and setters. The following rules apply:
 *
 * * Every explicit variable is represented by a non-synthetic
 *   [PropertyInducingElement].
 * * Every explicit variable induces a getter and possibly a setter, both of
 *   which are represented by synthetic [PropertyAccessorElement]s.
 * * Every explicit getter or setter is represented by a non-synthetic
 *   [PropertyAccessorElement].
 * * Every explicit getter or setter (or pair thereof if they have the same
 *   name) induces a variable that is represented by a synthetic
 *   [PropertyInducingElement].
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PropertyInducingElement implements VariableElement {
  /**
   * An empty list of elements.
   */
  static const List<PropertyInducingElement> EMPTY_LIST =
      const <PropertyInducingElement>[];

  /**
   * Return the getter associated with this variable. If this variable was
   * explicitly defined (is not synthetic) then the getter associated with it
   * will be synthetic.
   */
  PropertyAccessorElement get getter;

  /**
   * Return the propagated type of this variable, or `null` if type propagation
   * has not been performed, for example because the variable is not final.
   */
  DartType get propagatedType;

  /**
   * Return the setter associated with this variable, or `null` if the variable
   * is effectively `final` and therefore does not have a setter associated with
   * it. (This can happen either because the variable is explicitly defined as
   * being `final` or because the variable is induced by an explicit getter that
   * does not have a corresponding setter.) If this variable was explicitly
   * defined (is not synthetic) then the setter associated with it will be
   * synthetic.
   */
  PropertyAccessorElement get setter;
}

/**
 * A combinator that cause some of the names in a namespace to be visible (and
 * the rest hidden) when being imported.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ShowElementCombinator implements NamespaceCombinator {
  /**
   * Return the offset of the character immediately following the last character
   * of this node.
   */
  int get end;

  /**
   * Return the offset of the 'show' keyword of this element.
   */
  int get offset;

  /**
   * Return a list containing the names that are to be made visible in the
   * importing library if they are defined in the imported library.
   */
  List<String> get shownNames;
}

/**
 * A top-level variable.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TopLevelVariableElement implements PropertyInducingElement {
  /**
   * An empty list of top-level variable elements.
   */
  static const List<TopLevelVariableElement> EMPTY_LIST =
      const <TopLevelVariableElement>[];

  @override
  VariableDeclaration computeNode();
}

/**
 * An element that defines a type.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypeDefiningElement implements Element {
  /**
   * Return the type defined by this element.
   */
  DartType get type;
}

/**
 * A type parameter.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypeParameterElement implements TypeDefiningElement {
  /**
   * An empty list of type parameter elements.
   */
  static const List<TypeParameterElement> EMPTY_LIST =
      const <TypeParameterElement>[];

  /**
   * Return the type representing the bound associated with this parameter, or
   * `null` if this parameter does not have an explicit bound.
   */
  DartType get bound;

  @override
  TypeParameterType get type;
}

/**
 * An element that has type parameters, such as a class or a typedef. This also
 * includes functions and methods if support for generic methods is enabled.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypeParameterizedElement implements Element {
  /**
   * The type of this element, which will be a parameterized type.
   */
  ParameterizedType get type;

  /**
   * Return a list containing all of the type parameters declared by this
   * element directly. This does not include type parameters that are declared
   * by any enclosing elements.
   */
  List<TypeParameterElement> get typeParameters;
}

/**
 * A pseudo-elements that represents names that are undefined. This situation is
 * not allowed by the language, so objects implementing this interface always
 * represent an error. As a result, most of the normal operations on elements do
 * not make sense and will return useless results.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class UndefinedElement implements Element {}

/**
 * An element included into a library using some URI.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class UriReferencedElement implements Element {
  /**
   * Return the URI that is used to include this element into the enclosing
   * library, or `null` if this is the defining compilation unit of a library.
   */
  String get uri;

  /**
   * Return the offset of the character immediately following the last character
   * of this node's URI, or `-1` for synthetic import.
   */
  int get uriEnd;

  /**
   * Return the offset of the URI in the file, or `-1` if this element is
   * synthetic.
   */
  int get uriOffset;
}

/**
 * A variable. There are more specific subclasses for more specific kinds of
 * variables.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class VariableElement implements Element, ConstantEvaluationTarget {
  /**
   * An empty list of variable elements.
   */
  static const List<VariableElement> EMPTY_LIST = const <VariableElement>[];

  /**
   * Return a representation of the value of this variable.
   *
   * Return `null` if either this variable was not declared with the 'const'
   * modifier or if the value of this variable could not be computed because of
   * errors.
   */
  DartObject get constantValue;

  /**
   * Return `true` if this variable element did not have an explicit type
   * specified for it.
   */
  bool get hasImplicitType;

  /**
   * Return a synthetic function representing this variable's initializer, or
   * `null` if this variable does not have an initializer. The function will
   * have no parameters. The return type of the function will be the
   * compile-time type of the initialization expression.
   */
  FunctionElement get initializer;

  /**
   * Return `true` if this variable was declared with the 'const' modifier.
   */
  bool get isConst;

  /**
   * Return `true` if this variable was declared with the 'final' modifier.
   * Variables that are declared with the 'const' modifier will return `false`
   * even though they are implicitly final.
   */
  bool get isFinal;

  /**
   * Return `true` if this variable is potentially mutated somewhere in a
   * closure. This information is only available for local variables (including
   * parameters) and only after the compilation unit containing the variable has
   * been resolved.
   *
   * This getter is deprecated--it now returns `true` for all local variables
   * and parameters.  Please use [FunctionBody.isPotentiallyMutatedInClosure]
   * instead.
   */
  @deprecated
  bool get isPotentiallyMutatedInClosure;

  /**
   * Return `true` if this variable is potentially mutated somewhere in its
   * scope. This information is only available for local variables (including
   * parameters) and only after the compilation unit containing the variable has
   * been resolved.
   *
   * This getter is deprecated--it now returns `true` for all local variables
   * and parameters.  Please use [FunctionBody.isPotentiallyMutatedInClosure]
   * instead.
   */
  @deprecated
  bool get isPotentiallyMutatedInScope;

  /**
   * Return `true` if this element is a static variable, as per section 8 of the
   * Dart Language Specification:
   *
   * > A static variable is a variable that is not associated with a particular
   * > instance, but rather with an entire library or class. Static variables
   * > include library variables and class variables. Class variables are
   * > variables whose declaration is immediately nested inside a class
   * > declaration and includes the modifier static. A library variable is
   * > implicitly static.
   */
  bool get isStatic;

  /**
   * Return the declared type of this variable, or `null` if the variable did
   * not have a declared type (such as if it was declared using the keyword
   * 'var').
   */
  DartType get type;

  /**
   * Return a representation of the value of this variable, forcing the value
   * to be computed if it had not previously been computed, or `null` if either
   * this variable was not declared with the 'const' modifier or if the value of
   * this variable could not be computed because of errors.
   */
  DartObject computeConstantValue();
}
