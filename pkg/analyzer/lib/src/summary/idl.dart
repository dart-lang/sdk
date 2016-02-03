// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is an "idl" style description of the summary format.  It
 * contains abstract classes which declare the interface for reading data from
 * summaries.  It is parsed and transformed into code that implements the
 * summary format.
 *
 * The code generation process introduces the following semantics:
 * - Getters of type List never return null, and have a default value of the
 *   empty list.
 * - Getters of type int return unsigned 32-bit integers, never null, and have
 *   a default value of zero.
 * - Getters of type String never return null, and have a default value of ''.
 * - Getters of type bool never return null, and have a default value of false.
 * - Getters whose type is an enum never return null, and have a default value
 *   of the first value declared in the enum.
 *
 * Terminology used in this document:
 * - "Unlinked" refers to information that can be determined from reading a
 *   single .dart file in isolation.
 * - "Prelinked" refers to information that can be determined from the defining
 *   compilation unit of a library, plus direct imports, plus the transitive
 *   closure of exports reachable from those libraries, plus all part files
 *   constituting those libraries.
 * - "Linked" refers to all other information; in theory, this information may
 *   depend on all files in the transitive import/export closure.  However, in
 *   practice we expect that the number of additional dependencies will usually
 *   be small, since the additional dependencies only need to be consulted for
 *   type propagation, type inference, and constant evaluation, which typically
 *   have short dependency chains.
 *
 * Since we expect "linked" and "prelinked" dependencies to be similar, we only
 * rarely distinguish between them; most information is that is not "unlinked"
 * is typically considered "linked" for simplicity.
 *
 * Except as otherwise noted, synthetic elements are not stored in the summary;
 * they are re-synthesized at the time the summary is read.
 */
library analyzer.tool.summary.idl;

import 'base.dart' as base;
import 'format.dart' as generated;

/**
 * Annotation describing information which is not part of Dart semantics; in
 * other words, if this information (or any information it refers to) changes,
 * static analysis and runtime behavior of the library are unaffected.
 *
 * TODO(paulberry): some informative information is currently missing from the
 * summary format.
 */
const informative = null;

/**
 * Annotation describing information which is not part of the public API to a
 * library; in other words, if this information (or any information it refers
 * to) changes, libraries outside this one are unaffected.
 *
 * TODO(paulberry): currently the summary format does not contain private
 * information.
 */
const private = null;

/**
 * Annotation describing a class which can be the top level object in an
 * encoded summary.
 */
const topLevel = null;

/**
 * Summary information about a reference to a an entity such as a type, top
 * level executable, or executable within a class.
 */
abstract class EntityRef extends base.SummaryClass {
  /**
   * If this [EntityRef] is contained within [LinkedUnit.types], slot id (which
   * is unique within the compilation unit) identifying the target of type
   * propagation or type inference with which this [EntityRef] is associated.
   *
   * Otherwise zero.
   */
  int get slot;

  /**
   * Index into [UnlinkedUnit.references] for the entity being referred to, or
   * zero if this is a reference to a type parameter.
   */
  int get reference;

  /**
   * If this is a reference to a type parameter, one-based index into the list
   * of [UnlinkedTypeParam]s currently in effect.  Indexing is done using De
   * Bruijn index conventions; that is, innermost parameters come first, and
   * if a class or method has multiple parameters, they are indexed from right
   * to left.  So for instance, if the enclosing declaration is
   *
   *     class C<T,U> {
   *       m<V,W> {
   *         ...
   *       }
   *     }
   *
   * Then [paramReference] values of 1, 2, 3, and 4 represent W, V, U, and T,
   * respectively.
   *
   * If the type being referred to is not a type parameter, [paramReference] is
   * zero.
   */
  int get paramReference;

  /**
   * If this is a reference to a function type implicitly defined by a
   * function-typed parameter, a list of zero-based indices indicating the path
   * from the entity referred to by [reference] to the appropriate type
   * parameter.  Otherwise the empty list.
   *
   * If there are N indices in this list, then the entity being referred to is
   * the function type implicitly defined by a function-typed parameter of a
   * function-typed parameter, to N levels of nesting.  The first index in the
   * list refers to the outermost level of nesting; for example if [reference]
   * refers to the entity defined by:
   *
   *     void f(x, void g(y, z, int h(String w))) { ... }
   *
   * Then to refer to the function type implicitly defined by parameter `h`
   * (which is parameter 2 of parameter 1 of `f`), then
   * [implicitFunctionTypeIndices] should be [1, 2].
   *
   * Note that if the entity being referred to is a generic method inside a
   * generic class, then the type arguments in [typeArguments] are applied
   * first to the class and then to the method.
   */
  List<int> get implicitFunctionTypeIndices;

  /**
   * If this is an instantiation of a generic type or generic executable, the
   * type arguments used to instantiate it.  Trailing type arguments of type
   * `dynamic` are omitted.
   */
  List<EntityRef> get typeArguments;
}

/**
 * Information about a dependency that exists between one library and another
 * due to an "import" declaration.
 */
abstract class LinkedDependency extends base.SummaryClass {
  /**
   * The relative URI of the dependent library.  This URI is relative to the
   * importing library, even if there are intervening `export` declarations.
   * So, for example, if `a.dart` imports `b/c.dart` and `b/c.dart` exports
   * `d/e.dart`, the URI listed for `a.dart`'s dependency on `e.dart` will be
   * `b/d/e.dart`.
   */
  String get uri;

  /**
   * URI for the compilation units listed in the library's `part` declarations.
   * These URIs are relative to the importing library.
   */
  List<String> get parts;
}

/**
 * Information about a single name in the export namespace of the library that
 * is not in the public namespace.
 */
abstract class LinkedExportName extends base.SummaryClass {
  /**
   * Name of the exported entity.  For an exported setter, this name includes
   * the trailing '='.
   */
  String get name;

  /**
   * Index into [LinkedLibrary.dependencies] for the library in which the
   * entity is defined.
   */
  int get dependency;

  /**
   * Integer index indicating which unit in the exported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  int get unit;

  /**
   * The kind of the entity being referred to.
   */
  ReferenceKind get kind;
}

/**
 * Linked summary of a library.
 */
@topLevel
abstract class LinkedLibrary extends base.SummaryClass {
  factory LinkedLibrary.fromBuffer(List<int> buffer) =>
      generated.readLinkedLibrary(buffer);

  /**
   * The linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  List<LinkedUnit> get units;

  /**
   * The libraries that this library depends on (either via an explicit import
   * statement or via the implicit dependencies on `dart:core` and
   * `dart:async`).  The first element of this array is a pseudo-dependency
   * representing the library itself (it is also used for `dynamic` and
   * `void`).  This is followed by elements representing "prelinked"
   * dependencies (direct imports and the transitive closure of exports).
   * After the prelinked dependencies are elements representing "linked"
   * dependencies.
   *
   * A library is only included as a "linked" dependency if it is a true
   * dependency (e.g. a propagated or inferred type or constant value
   * implicitly refers to an element declared in the library) or
   * anti-dependency (e.g. the result of type propagation or type inference
   * depends on the lack of a certain declaration in the library).
   */
  List<LinkedDependency> get dependencies;

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   */
  List<int> get importDependencies;

  /**
   * Information about entities in the export namespace of the library that are
   * not in the public namespace of the library (that is, entities that are
   * brought into the namespace via `export` directives).
   *
   * Sorted by name.
   */
  List<LinkedExportName> get exportNames;

  /**
   * The number of elements in [dependencies] which are not "linked"
   * dependencies (that is, the number of libraries in the direct imports plus
   * the transitive closure of exports, plus the library itself).
   */
  int get numPrelinkedDependencies;
}

/**
 * Information about the resolution of an [UnlinkedReference].
 */
abstract class LinkedReference extends base.SummaryClass {
  /**
   * Index into [LinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   *
   * Zero if this entity is contained within another entity (e.g. a class
   * member).
   */
  int get dependency;

  /**
   * The kind of the entity being referred to.  For the pseudo-types `dynamic`
   * and `void`, the kind is [ReferenceKind.classOrEnum].
   */
  ReferenceKind get kind;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   *
   * Zero if this entity is contained within another entity (e.g. a class
   * member).
   */
  int get unit;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int get numTypeParameters;

  /**
   * If this [LinkedReference] doesn't have an associated [UnlinkedReference],
   * name of the entity being referred to.  For the pseudo-type `dynamic`, the
   * string is "dynamic".  For the pseudo-type `void`, the string is "void".
   */
  String get name;

  /**
   * If this [LinkedReference] doesn't have an associated [UnlinkedReference],
   * and the entity being referred to is contained within another entity, index
   * of the containing entity.  This behaves similarly to
   * [UnlinkedReference.prefixReference], however it is only used for class
   * members, not for prefixed imports.
   *
   * Containing references must always point backward; that is, for all i, if
   * LinkedUnit.references[i].containingReference != 0, then
   * LinkedUnit.references[i].containingReference < i.
   */
  int get containingReference;
}

/**
 * Linked summary of a compilation unit.
 */
abstract class LinkedUnit extends base.SummaryClass {
  /**
   * Information about the resolution of references within the compilation
   * unit.  Each element of [UnlinkedUnit.references] has a corresponding
   * element in this list (at the same index).  If this list has additional
   * elements beyond the number of elements in [UnlinkedUnit.references], those
   * additional elements are references that are only referred to implicitly
   * (e.g. elements involved in inferred or propagated types).
   */
  List<LinkedReference> get references;

  /**
   * List associating slot ids found inside the unlinked summary for the
   * compilation unit with propagated and inferred types.
   */
  List<EntityRef> get types;
}

/**
 * Enum used to indicate the kind of entity referred to by a
 * [LinkedReference].
 */
enum ReferenceKind {
  /**
   * The entity is a class or enum.
   */
  classOrEnum,

  /**
   * The entity is a constructor.
   */
  constructor,

  /**
   * The entity is a getter or setter inside a class.  Note: this is used in
   * the case where a constant refers to a static const declared inside a
   * class.
   */
  propertyAccessor,

  /**
   * The entity is a method.
   */
  method,

  /**
   * The `length` property access.
   */
  length,

  /**
   * The entity is a typedef.
   */
  typedef,

  /**
   * The entity is a top level function.
   */
  topLevelFunction,

  /**
   * The entity is a top level getter or setter.
   */
  topLevelPropertyAccessor,

  /**
   * The entity is a prefix.
   */
  prefix,

  /**
   * The entity being referred to does not exist.
   */
  unresolved
}

/**
 * Information about SDK.
 */
@topLevel
abstract class SdkBundle extends base.SummaryClass {
  factory SdkBundle.fromBuffer(List<int> buffer) =>
      generated.readSdkBundle(buffer);

  /**
   * The list of URIs of items in [linkedLibraries], e.g. `dart:core`.
   */
  List<String> get linkedLibraryUris;

  /**
   * Linked libraries.
   */
  List<LinkedLibrary> get linkedLibraries;

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  List<String> get unlinkedUnitUris;

  /**
   * Unlinked information for the compilation units constituting the SDK.
   */
  List<UnlinkedUnit> get unlinkedUnits;
}

/**
 * Unlinked summary information about a class declaration.
 */
abstract class UnlinkedClass extends base.SummaryClass {
  /**
   * Name of the class.
   */
  String get name;

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  @informative
  int get nameOffset;

  /**
   * Documentation comment for the class, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Type parameters of the class, if any.
   */
  List<UnlinkedTypeParam> get typeParameters;

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  EntityRef get supertype;

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  List<EntityRef> get mixins;

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  List<EntityRef> get interfaces;

  /**
   * Field declarations contained in the class.
   */
  List<UnlinkedVariable> get fields;

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  List<UnlinkedExecutable> get executables;

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  bool get isAbstract;

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  bool get isMixinApplication;

  /**
   * Indicates whether this class is the core "Object" class (and hence has no
   * supertype)
   */
  bool get hasNoSupertype;
}

/**
 * Unlinked summary information about a `show` or `hide` combinator in an
 * import or export declaration.
 */
abstract class UnlinkedCombinator extends base.SummaryClass {
  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  List<String> get shows;

  /**
   * List of names which are hidden.  Empty if this is a `show` combinator.
   */
  List<String> get hides;
}

/**
 * Unlinked summary information about a compile-time constant expression, or a
 * potentially constant expression.
 *
 * Constant expressions are represented using a simple stack-based language
 * where [operations] is a sequence of operations to execute starting with an
 * empty stack.  Once all operations have been executed, the stack should
 * contain a single value which is the value of the constant.  Note that some
 * operations consume additional data from the other fields of this class.
 */
abstract class UnlinkedConst extends base.SummaryClass {
  /**
   * Sequence of operations to execute (starting with an empty stack) to form
   * the constant value.
   */
  List<UnlinkedConstOperation> get operations;

  /**
   * Sequence of unsigned 32-bit integers consumed by the operations
   * `pushArgument`, `pushInt`, `shiftOr`, `concatenate`, `invokeConstructor`,
   * `makeList`, and `makeMap`.
   */
  List<int> get ints;

  /**
   * Sequence of 64-bit doubles consumed by the operation `pushDouble`.
   */
  List<double> get doubles;

  /**
   * Sequence of strings consumed by the operations `pushString` and
   * `invokeConstructor`.
   */
  List<String> get strings;

  /**
   * Sequence of language constructs consumed by the operations
   * `pushReference`, `invokeConstructor`, `makeList`, and `makeMap`.  Note
   * that in the case of `pushReference` (and sometimes `invokeConstructor` the
   * actual entity being referred to may be something other than a type.
   */
  List<EntityRef> get references;
}

/**
 * Enum representing the various kinds of operations which may be performed to
 * produce a constant value.  These options are assumed to execute in the
 * context of a stack which is initially empty.
 */
enum UnlinkedConstOperation {
  /**
   * Push the next value from [UnlinkedConst.ints] (a 32-bit unsigned integer)
   * onto the stack.
   *
   * Note that Dart supports integers larger than 32 bits; these are
   * represented by composing 32-bit values using the [pushLongInt] operation.
   */
  pushInt,

  /**
   * Get the number of components from [UnlinkedConst.ints], then do this number
   * of times the following operations: multiple the current value by 2^32, "or"
   * it with the next value in [UnlinkedConst.ints]. The initial value is zero.
   * Push the result into the stack.
   */
  pushLongInt,

  /**
   * Push the next value from [UnlinkedConst.doubles] (a double precision
   * floating point value) onto the stack.
   */
  pushDouble,

  /**
   * Push the constant `true` onto the stack.
   */
  pushTrue,

  /**
   * Push the constant `false` onto the stack.
   */
  pushFalse,

  /**
   * Push the next value from [UnlinkedConst.strings] onto the stack.
   */
  pushString,

  /**
   * Pop the top n values from the stack (where n is obtained from
   * [UnlinkedConst.ints]), convert them to strings (if they aren't already),
   * concatenate them into a single string, and push it back onto the stack.
   *
   * This operation is used to represent constants whose value is a literal
   * string containing string interpolations.
   */
  concatenate,

  /**
   * Get the next value from [UnlinkedConst.strings], convert it to a symbol,
   * and push it onto the stack.
   */
  makeSymbol,

  /**
   * Push the constant `null` onto the stack.
   */
  pushNull,

  /**
   * Evaluate a (potentially qualified) identifier expression and push the
   * resulting value onto the stack.  The identifier to be evaluated is
   * obtained from [UnlinkedConst.references].
   *
   * This operation is used to represent the following kinds of constants
   * (which are indistinguishable from an unresolved AST alone):
   *
   * - A qualified reference to a static constant variable (e.g. `C.v`, where
   *   C is a class and `v` is a constant static variable in `C`).
   * - An identifier expression referring to a constant variable.
   * - A simple or qualified identifier denoting a class or type alias.
   * - A simple or qualified identifier denoting a top-level function or a
   *   static method.
   */
  pushReference,

  /**
   * Pop the top `n` values from the stack (where `n` is obtained from
   * [UnlinkedConst.ints]) into a list (filled from the end) and take the next
   * `n` values from [UnlinkedConst.strings] and use the lists of names and
   * values to create named arguments.  Then pop the top `m` values from the
   * stack (where `m` is obtained from [UnlinkedConst.ints]) into a list (filled
   * from the end) and use them as positional arguments.  Use the lists of
   * positional and names arguments to invoke a constant constructor obtained
   * from [UnlinkedConst.references], and push the resulting value back onto the
   * stack.
   *
   * Note that for an invocation of the form `const a.b(...)` (where no type
   * arguments are specified), it is impossible to tell from the unresolved AST
   * alone whether `a` is a class name and `b` is a constructor name, or `a` is
   * a prefix name and `b` is a class name.  For consistency between AST based
   * and elements based summaries, references to default constructors are always
   * recorded as references to corresponding classes.
   */
  invokeConstructor,

  /**
   * Pop the top n values from the stack (where n is obtained from
   * [UnlinkedConst.ints]), place them in a [List], and push the result back
   * onto the stack.  The type parameter for the [List] is implicitly `dynamic`.
   */
  makeUntypedList,

  /**
   * Pop the top 2*n values from the stack (where n is obtained from
   * [UnlinkedConst.ints]), interpret them as key/value pairs, place them in a
   * [Map], and push the result back onto the stack.  The two type parameters
   * for the [Map] are implicitly `dynamic`.
   */
  makeUntypedMap,

  /**
   * Pop the top n values from the stack (where n is obtained from
   * [UnlinkedConst.ints]), place them in a [List], and push the result back
   * onto the stack.  The type parameter for the [List] is obtained from
   * [UnlinkedConst.references].
   */
  makeTypedList,

  /**
   * Pop the top 2*n values from the stack (where n is obtained from
   * [UnlinkedConst.ints]), interpret them as key/value pairs, place them in a
   * [Map], and push the result back onto the stack.  The two type parameters for
   * the [Map] are obtained from [UnlinkedConst.references].
   */
  makeTypedMap,

  /**
   * Pop the top 2 values from the stack, pass them to the predefined Dart
   * function `identical`, and push the result back onto the stack.
   */
  identical,

  /**
   * Pop the top 2 values from the stack, evaluate `v1 == v2`, and push the
   * result back onto the stack.
   */
  equal,

  /**
   * Pop the top 2 values from the stack, evaluate `v1 != v2`, and push the
   * result back onto the stack.
   */
  notEqual,

  /**
   * Pop the top value from the stack, compute its boolean negation, and push
   * the result back onto the stack.
   */
  not,

  /**
   * Pop the top 2 values from the stack, compute `v1 && v2`, and push the
   * result back onto the stack.
   */
  and,

  /**
   * Pop the top 2 values from the stack, compute `v1 || v2`, and push the
   * result back onto the stack.
   */
  or,

  /**
   * Pop the top value from the stack, compute its integer complement, and push
   * the result back onto the stack.
   */
  complement,

  /**
   * Pop the top 2 values from the stack, compute `v1 ^ v2`, and push the
   * result back onto the stack.
   */
  bitXor,

  /**
   * Pop the top 2 values from the stack, compute `v1 & v2`, and push the
   * result back onto the stack.
   */
  bitAnd,

  /**
   * Pop the top 2 values from the stack, compute `v1 | v2`, and push the
   * result back onto the stack.
   */
  bitOr,

  /**
   * Pop the top 2 values from the stack, compute `v1 >> v2`, and push the
   * result back onto the stack.
   */
  bitShiftRight,

  /**
   * Pop the top 2 values from the stack, compute `v1 << v2`, and push the
   * result back onto the stack.
   */
  bitShiftLeft,

  /**
   * Pop the top 2 values from the stack, compute `v1 + v2`, and push the
   * result back onto the stack.
   */
  add,

  /**
   * Pop the top value from the stack, compute its integer negation, and push
   * the result back onto the stack.
   */
  negate,

  /**
   * Pop the top 2 values from the stack, compute `v1 - v2`, and push the
   * result back onto the stack.
   */
  subtract,

  /**
   * Pop the top 2 values from the stack, compute `v1 * v2`, and push the
   * result back onto the stack.
   */
  multiply,

  /**
   * Pop the top 2 values from the stack, compute `v1 / v2`, and push the
   * result back onto the stack.
   */
  divide,

  /**
   * Pop the top 2 values from the stack, compute `v1 ~/ v2`, and push the
   * result back onto the stack.
   */
  floorDivide,

  /**
   * Pop the top 2 values from the stack, compute `v1 > v2`, and push the
   * result back onto the stack.
   */
  greater,

  /**
   * Pop the top 2 values from the stack, compute `v1 < v2`, and push the
   * result back onto the stack.
   */
  less,

  /**
   * Pop the top 2 values from the stack, compute `v1 >= v2`, and push the
   * result back onto the stack.
   */
  greaterEqual,

  /**
   * Pop the top 2 values from the stack, compute `v1 <= v2`, and push the
   * result back onto the stack.
   */
  lessEqual,

  /**
   * Pop the top 2 values from the stack, compute `v1 % v2`, and push the
   * result back onto the stack.
   */
  modulo,

  /**
   * Pop the top 3 values from the stack, compute `v1 ? v2 : v3`, and push the
   * result back onto the stack.
   */
  conditional,

  /**
   * Pop the top value from the stack, evaluate `v.length`, and push the result
   * back onto the stack.
   */
  length,
}

/**
 * Unlinked summary information about a documentation comment.
 */
abstract class UnlinkedDocumentationComment extends base.SummaryClass {
  /**
   * Text of the documentation comment, with '\r\n' replaced by '\n'.
   *
   * References appearing within the doc comment in square brackets are not
   * specially encoded.
   */
  String get text;

  /**
   * Offset of the beginning of the documentation comment relative to the
   * beginning of the file.
   */
  int get offset;

  /**
   * Length of the documentation comment (prior to replacing '\r\n' with '\n').
   */
  int get length;
}

/**
 * Unlinked summary information about an enum declaration.
 */
abstract class UnlinkedEnum extends base.SummaryClass {
  /**
   * Name of the enum type.
   */
  String get name;

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  @informative
  int get nameOffset;

  /**
   * Documentation comment for the enum, or `null` if there is no documentation
   * comment.
   */
  @informative
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Values listed in the enum declaration, in declaration order.
   */
  List<UnlinkedEnumValue> get values;
}

/**
 * Unlinked summary information about a single enumerated value in an enum
 * declaration.
 */
abstract class UnlinkedEnumValue extends base.SummaryClass {
  /**
   * Name of the enumerated value.
   */
  String get name;

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  @informative
  int get nameOffset;

  /**
   * Documentation comment for the enum value, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment get documentationComment;
}

/**
 * Unlinked summary information about a function, method, getter, or setter
 * declaration.
 */
abstract class UnlinkedExecutable extends base.SummaryClass {
  /**
   * Name of the executable.  For setters, this includes the trailing "=".  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the empty string.
   */
  String get name;

  /**
   * Offset of the executable name relative to the beginning of the file.  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the offset of the class name (i.e. the
   * offset of the second "C" in "class C { C(); }").
   */
  @informative
  int get nameOffset;

  /**
   * Documentation comment for the executable, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  List<UnlinkedTypeParam> get typeParameters;

  /**
   * Declared return type of the executable.  Absent if the executable is a
   * constructor or the return type is implicit.
   */
  EntityRef get returnType;

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters (hence this will be the empty list), and setters have a single
   * parameter.
   */
  List<UnlinkedParam> get parameters;

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  UnlinkedExecutableKind get kind;

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  bool get isAbstract;

  /**
   * Indicates whether the executable is declared using the `static` keyword.
   *
   * Note that for top level executables, this flag is false, since they are
   * not declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  bool get isStatic;

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  bool get isConst;

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  bool get isFactory;

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  bool get isExternal;

  /**
   * If this executable's return type is inferrable, nonzero slot id
   * identifying which entry in [LinkedLibrary.types] contains the inferred
   * return type.  If there is no matching entry in [LinkedLibrary.types], then
   * no return type was inferred for this variable, so its static type is
   * `dynamic`.
   */
  int get inferredReturnTypeSlot;
}

/**
 * Enum used to indicate the kind of an executable.
 */
enum UnlinkedExecutableKind {
  /**
   * Executable is a function or method.
   */
  functionOrMethod,

  /**
   * Executable is a getter.
   */
  getter,

  /**
   * Executable is a setter.
   */
  setter,

  /**
   * Executable is a constructor.
   */
  constructor
}

/**
 * Unlinked summary information about an export declaration (stored outside
 * [UnlinkedPublicNamespace]).
 */
abstract class UnlinkedExportNonPublic extends base.SummaryClass {
  /**
   * Offset of the "export" keyword.
   */
  @informative
  int get offset;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  @informative
  int get uriOffset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  @informative
  int get uriEnd;
}

/**
 * Unlinked summary information about an export declaration (stored inside
 * [UnlinkedPublicNamespace]).
 */
abstract class UnlinkedExportPublic extends base.SummaryClass {
  /**
   * URI used in the source code to reference the exported library.
   */
  String get uri;

  /**
   * Combinators contained in this import declaration.
   */
  List<UnlinkedCombinator> get combinators;
}

/**
 * Unlinked summary information about an import declaration.
 */
abstract class UnlinkedImport extends base.SummaryClass {
  /**
   * URI used in the source code to reference the imported library.
   */
  String get uri;

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  @informative
  int get offset;

  /**
   * Index into [UnlinkedUnit.references] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  int get prefixReference;

  /**
   * Combinators contained in this import declaration.
   */
  List<UnlinkedCombinator> get combinators;

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  bool get isDeferred;

  /**
   * Indicates whether the import declaration is implicit.
   */
  bool get isImplicit;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  @informative
  int get uriOffset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  @informative
  int get uriEnd;

  /**
   * Offset of the prefix name relative to the beginning of the file, or zero
   * if there is no prefix.
   */
  @informative
  int get prefixOffset;
}

/**
 * Unlinked summary information about a function parameter.
 */
abstract class UnlinkedParam extends base.SummaryClass {
  /**
   * Name of the parameter.
   */
  String get name;

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  @informative
  int get nameOffset;

  /**
   * If [isFunctionTyped] is `true`, the declared return type.  If
   * [isFunctionTyped] is `false`, the declared type.  Absent if the type is
   * implicit.
   */
  EntityRef get type;

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  List<UnlinkedParam> get parameters;

  /**
   * Kind of the parameter.
   */
  UnlinkedParamKind get kind;

  /**
   * Indicates whether this is a function-typed parameter.
   */
  bool get isFunctionTyped;

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  bool get isInitializingFormal;

  /**
   * If this parameter's type is inferrable, nonzero slot id identifying which
   * entry in [LinkedLibrary.types] contains the inferred type.  If there is no
   * matching entry in [LinkedLibrary.types], then no type was inferred for
   * this variable, so its static type is `dynamic`.
   *
   * Note that although strong mode considers initializing formals to be
   * inferrable, they are not marked as such in the summary; if their type is
   * not specified, they always inherit the static type of the corresponding
   * field.
   */
  int get inferredTypeSlot;
}

/**
 * Enum used to indicate the kind of a parameter.
 */
enum UnlinkedParamKind {
  /**
   * Parameter is required.
   */
  required,

  /**
   * Parameter is positional optional (enclosed in `[]`)
   */
  positional,

  /**
   * Parameter is named optional (enclosed in `{}`)
   */
  named
}

/**
 * Unlinked summary information about a part declaration.
 */
abstract class UnlinkedPart extends base.SummaryClass {
  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  @informative
  int get uriOffset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  @informative
  int get uriEnd;
}

/**
 * Unlinked summary information about a specific name contributed by a
 * compilation unit to a library's public namespace.
 *
 * TODO(paulberry): some of this information is redundant with information
 * elsewhere in the summary.  Consider reducing the redundancy to reduce
 * summary size.
 */
abstract class UnlinkedPublicName extends base.SummaryClass {
  /**
   * The name itself.
   */
  String get name;

  /**
   * The kind of object referred to by the name.
   */
  ReferenceKind get kind;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int get numTypeParameters;

  /**
   * If this [UnlinkedPublicName] is a class, the list of members which can be
   * referenced from constants - static constant fields, static methods, and
   * constructors.  Otherwise empty.
   */
  List<UnlinkedPublicName> get constMembers;
}

/**
 * Unlinked summary information about what a compilation unit contributes to a
 * library's public namespace.  This is the subset of [UnlinkedUnit] that is
 * required from dependent libraries in order to perform prelinking.
 */
@topLevel
abstract class UnlinkedPublicNamespace extends base.SummaryClass {
  factory UnlinkedPublicNamespace.fromBuffer(List<int> buffer) =>
      generated.readUnlinkedPublicNamespace(buffer);

  /**
   * Public names defined in the compilation unit.
   *
   * TODO(paulberry): consider sorting these names to reduce unnecessary
   * relinking.
   */
  List<UnlinkedPublicName> get names;

  /**
   * Export declarations in the compilation unit.
   */
  List<UnlinkedExportPublic> get exports;

  /**
   * URIs referenced by part declarations in the compilation unit.
   */
  List<String> get parts;
}

/**
 * Unlinked summary information about a name referred to in one library that
 * might be defined in another.
 */
abstract class UnlinkedReference extends base.SummaryClass {
  /**
   * Name of the entity being referred to.  For the pseudo-type `dynamic`, the
   * string is "dynamic".  For the pseudo-type `void`, the string is "void".
   */
  String get name;

  /**
   * Prefix used to refer to the entity, or zero if no prefix is used.  This is
   * an index into [UnlinkedUnit.references].
   *
   * Prefix references must always point backward; that is, for all i, if
   * UnlinkedUnit.references[i].prefixReference != 0, then
   * UnlinkedUnit.references[i].prefixReference < i.
   */
  int get prefixReference;
}

/**
 * Unlinked summary information about a typedef declaration.
 */
abstract class UnlinkedTypedef extends base.SummaryClass {
  /**
   * Name of the typedef.
   */
  String get name;

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  @informative
  int get nameOffset;

  /**
   * Documentation comment for the typedef, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Type parameters of the typedef, if any.
   */
  List<UnlinkedTypeParam> get typeParameters;

  /**
   * Return type of the typedef.
   */
  EntityRef get returnType;

  /**
   * Parameters of the executable, if any.
   */
  List<UnlinkedParam> get parameters;
}

/**
 * Unlinked summary information about a type parameter declaration.
 */
abstract class UnlinkedTypeParam extends base.SummaryClass {
  /**
   * Name of the type parameter.
   */
  String get name;

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  @informative
  int get nameOffset;

  /**
   * Bound of the type parameter, if a bound is explicitly declared.  Otherwise
   * null.
   */
  EntityRef get bound;
}

/**
 * Unlinked summary information about a compilation unit ("part file").
 */
@topLevel
abstract class UnlinkedUnit extends base.SummaryClass {
  factory UnlinkedUnit.fromBuffer(List<int> buffer) =>
      generated.readUnlinkedUnit(buffer);

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  String get libraryName;

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  @informative
  int get libraryNameOffset;

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  @informative
  int get libraryNameLength;

  /**
   * Documentation comment for the library, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment get libraryDocumentationComment;

  /**
   * Unlinked public namespace of this compilation unit.
   */
  UnlinkedPublicNamespace get publicNamespace;

  /**
   * Top level and prefixed names referred to by this compilation unit.  The
   * zeroth element of this array is always populated and is used to represent
   * the absence of a reference in places where a reference is optional (for
   * example [UnlinkedReference.prefixReference or
   * UnlinkedImport.prefixReference]).
   */
  List<UnlinkedReference> get references;

  /**
   * Classes declared in the compilation unit.
   */
  List<UnlinkedClass> get classes;

  /**
   * Enums declared in the compilation unit.
   */
  List<UnlinkedEnum> get enums;

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  List<UnlinkedExecutable> get executables;

  /**
   * Export declarations in the compilation unit.
   */
  List<UnlinkedExportNonPublic> get exports;

  /**
   * Import declarations in the compilation unit.
   */
  List<UnlinkedImport> get imports;

  /**
   * Part declarations in the compilation unit.
   */
  List<UnlinkedPart> get parts;

  /**
   * Typedefs declared in the compilation unit.
   */
  List<UnlinkedTypedef> get typedefs;

  /**
   * Top level variables declared in the compilation unit.
   */
  List<UnlinkedVariable> get variables;
}

/**
 * Unlinked summary information about a top level variable, local variable, or
 * a field.
 */
abstract class UnlinkedVariable extends base.SummaryClass {
  /**
   * Name of the variable.
   */
  String get name;

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  @informative
  int get nameOffset;

  /**
   * Documentation comment for the variable, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Declared type of the variable.  Absent if the type is implicit.
   */
  EntityRef get type;

  /**
   * If [isConst] is true, and the variable has an initializer, the constant
   * expression in the initializer.
   */
  UnlinkedConst get constExpr;

  /**
   * Indicates whether the variable is declared using the `static` keyword.
   *
   * Note that for top level variables, this flag is false, since they are not
   * declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  bool get isStatic;

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  bool get isFinal;

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  bool get isConst;

  /**
   * If this variable is propagable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the propagated type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then this variable's
   * propagated type is the same as its declared type.
   *
   * Non-propagable variables have a [propagatedTypeSlot] of zero.
   */
  int get propagatedTypeSlot;

  /**
   * If this variable is inferrable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the inferred type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then no type was
   * inferred for this variable, so its static type is `dynamic`.
   */
  int get inferredTypeSlot;
}
