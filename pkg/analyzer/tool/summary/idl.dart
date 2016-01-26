// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is an "idl" style description of the summary format.  It is not
 * executed directly; instead it is parsed and transformed into code that
 * implements the summary format.
 *
 * The code generation process introduces the following non-typical semantics:
 * - Fields of type List are never null, and have a default value of the empty
 *   list.
 * - Fields of type int are unsigned 32-bit integers, never null, and have a
 *   default value of zero.
 * - Fields of type String are never null, and have a default value of ''.
 * - Fields of type bool are never null, and have a default value of false.
 * - Fields whose type is an enum are never null, and have a default value of
 *   the first value declared in the enum.
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
class EntityRef {
  /**
   * If this [EntityRef] is contained within [LinkedUnit.types], slot id (which
   * is unique within the compilation unit) identifying the target of type
   * propagation or type inference with which this [EntityRef] is associated.
   *
   * Otherwise zero.
   */
  int slot;

  /**
   * Index into [UnlinkedUnit.references] for the entity being referred to, or
   * zero if this is a reference to a type parameter.
   */
  int reference;

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
  int paramReference;

  /**
   * If this is an instantiation of a generic type or generic executable, the
   * type arguments used to instantiate it.  Trailing type arguments of type
   * `dynamic` are omitted.
   */
  List<EntityRef> typeArguments;
}

/**
 * Information about a dependency that exists between one library and another
 * due to an "import" declaration.
 */
class LinkedDependency {
  /**
   * The relative URI of the dependent library.  This URI is relative to the
   * importing library, even if there are intervening `export` declarations.
   * So, for example, if `a.dart` imports `b/c.dart` and `b/c.dart` exports
   * `d/e.dart`, the URI listed for `a.dart`'s dependency on `e.dart` will be
   * `b/d/e.dart`.
   */
  String uri;

  /**
   * URI for the compilation units listed in the library's `part` declarations.
   * These URIs are relative to the importing library.
   */
  List<String> parts;
}

/**
 * Information about a single name in the export namespace of the library that
 * is not in the public namespace.
 */
class LinkedExportName {
  /**
   * Name of the exported entity.  TODO(paulberry): do we include the trailing
   * '=' for a setter?
   */
  String name;

  /**
   * Index into [LinkedLibrary.dependencies] for the library in which the
   * entity is defined.
   */
  int dependency;

  /**
   * Integer index indicating which unit in the exported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  int unit;

  /**
   * The kind of the entity being referred to.
   */
  ReferenceKind kind;
}

/**
 * Linked summary of a library.
 */
@topLevel
class LinkedLibrary {
  /**
   * The linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  List<LinkedUnit> units;

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
  List<LinkedDependency> dependencies;

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   */
  List<int> importDependencies;

  /**
   * Information about entities in the export namespace of the library that are
   * not in the public namespace of the library (that is, entities that are
   * brought into the namespace via `export` directives).
   *
   * Sorted by name.
   */
  List<LinkedExportName> exportNames;

  /**
   * The number of elements in [dependencies] which are not "linked"
   * dependencies (that is, the number of libraries in the direct imports plus
   * the transitive closure of exports, plus the library itself).
   */
  int numPrelinkedDependencies;
}

/**
 * Information about the resolution of an [UnlinkedReference].
 */
class LinkedReference {
  /**
   * Index into [LinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  int dependency;

  /**
   * The kind of the entity being referred to.  For the pseudo-types `dynamic`
   * and `void`, the kind is [ReferenceKind.classOrEnum].
   */
  ReferenceKind kind;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  int unit;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int numTypeParameters;

  /**
   * If this [LinkedReference] doesn't have an associated [UnlinkedReference],
   * name of the entity being referred to.  For the pseudo-type `dynamic`, the
   * string is "dynamic".  For the pseudo-type `void`, the string is "void".
   */
  String name;
}

/**
 * Linked summary of a compilation unit.
 */
class LinkedUnit {
  /**
   * Information about the resolution of references within the compilation
   * unit.  Each element of [UnlinkedUnit.references] has a corresponding
   * element in this list (at the same index).  If this list has additional
   * elements beyond the number of elements in [UnlinkedUnit.references], those
   * additional elements are references that are only referred to implicitly
   * (e.g. elements involved in inferred or propagated types).
   */
  List<LinkedReference> references;

  /**
   * List associating slot ids found inside the unlinked summary for the
   * compilation unit with propagated and inferred types.
   */
  List<EntityRef> types;
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
   * The entity is a static const field.
   */
  constField,

  /**
   * The entity is a static method.
   */
  staticMethod,

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
class SdkBundle {
  /**
   * The list of URIs of items in [linkedLibraries], e.g. `dart:core`.
   */
  List<String> linkedLibraryUris;

  /**
   * Linked libraries.
   */
  List<LinkedLibrary> linkedLibraries;

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  List<String> unlinkedUnitUris;

  /**
   * Unlinked information for the compilation units constituting the SDK.
   */
  List<UnlinkedUnit> unlinkedUnits;
}

/**
 * Unlinked summary information about a class declaration.
 */
class UnlinkedClass {
  /**
   * Name of the class.
   */
  String name;

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  @informative
  int nameOffset;

  /**
   * Documentation comment for the class, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment documentationComment;

  /**
   * Type parameters of the class, if any.
   */
  List<UnlinkedTypeParam> typeParameters;

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  EntityRef supertype;

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  List<EntityRef> mixins;

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  List<EntityRef> interfaces;

  /**
   * Field declarations contained in the class.
   */
  List<UnlinkedVariable> fields;

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  List<UnlinkedExecutable> executables;

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  bool isAbstract;

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  bool isMixinApplication;

  /**
   * Indicates whether this class is the core "Object" class (and hence has no
   * supertype)
   */
  bool hasNoSupertype;
}

/**
 * Unlinked summary information about a `show` or `hide` combinator in an
 * import or export declaration.
 */
class UnlinkedCombinator {
  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  List<String> shows;

  /**
   * List of names which are hidden.  Empty if this is a `show` combinator.
   */
  List<String> hides;
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
class UnlinkedConst {
  /**
   * Sequence of operations to execute (starting with an empty stack) to form
   * the constant value.
   */
  List<UnlinkedConstOperation> operations;

  /**
   * Sequence of unsigned 32-bit integers consumed by the operations
   * `pushArgument`, `pushInt`, `shiftOr`, `concatenate`, `invokeConstructor`,
   * `makeList`, and `makeMap`.
   */
  List<int> ints;

  /**
   * Sequence of 64-bit doubles consumed by the operation `pushDouble`.
   */
  List<double> doubles;

  /**
   * Sequence of strings consumed by the operations `pushString` and
   * `invokeConstructor`.
   */
  List<String> strings;

  /**
   * Sequence of language constructs consumed by the operations
   * `pushReference`, `invokeConstructor`, `makeList`, and `makeMap`.  Note
   * that in the case of `pushReference` (and sometimes `invokeConstructor` the
   * actual entity being referred to may be something other than a type.
   */
  List<EntityRef> references;
}

/**
 * Enum representing the various kinds of operations which may be performed to
 * produce a constant value.  These options are assumed to execute in the
 * context of a stack which is initially empty.
 */
enum UnlinkedConstOperation {
  /**
   * Push the value of the n-th constructor argument (where n is obtained from
   * [UnlinkedConst.ints]) onto the stack.
   */
  pushArgument,

  /**
   * Push the next value from [UnlinkedConst.ints] (a 32-bit unsigned integer)
   * onto the stack.
   *
   * Note that Dart supports integers larger than 32 bits; these are
   * represented by composing 32 bit values using the [shiftOr] operation.
   */
  pushInt,

  /**
   * Pop the top value off the stack, which should be an integer.  Multiply it
   * by 2^32, "or" in the next value from [UnlinkedConst.ints] (which is
   * interpreted as a 32-bit unsigned integer), and push the result back onto
   * the stack.
   */
  shiftOr,

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
   * Pop the top value from the stack which should be string, convert it to
   * a symbol, and push it back onto the stack.
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
   *
   * This is also used to represent `v1 != v2`, by composition with [not].
   */
  equal,

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
class UnlinkedDocumentationComment {
  /**
   * Text of the documentation comment, with '\r\n' replaced by '\n'.
   *
   * References appearing within the doc comment in square brackets are not
   * specially encoded.
   */
  String text;

  /**
   * Offset of the beginning of the documentation comment relative to the
   * beginning of the file.
   */
  int offset;

  /**
   * Length of the documentation comment (prior to replacing '\r\n' with '\n').
   */
  int length;
}

/**
 * Unlinked summary information about an enum declaration.
 */
class UnlinkedEnum {
  /**
   * Name of the enum type.
   */
  String name;

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  @informative
  int nameOffset;

  /**
   * Documentation comment for the enum, or `null` if there is no documentation
   * comment.
   */
  @informative
  UnlinkedDocumentationComment documentationComment;

  /**
   * Values listed in the enum declaration, in declaration order.
   */
  List<UnlinkedEnumValue> values;
}

/**
 * Unlinked summary information about a single enumerated value in an enum
 * declaration.
 */
class UnlinkedEnumValue {
  /**
   * Name of the enumerated value.
   */
  String name;

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  @informative
  int nameOffset;

  /**
   * Documentation comment for the enum value, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment documentationComment;
}

/**
 * Unlinked summary information about a function, method, getter, or setter
 * declaration.
 */
class UnlinkedExecutable {
  /**
   * Name of the executable.  For setters, this includes the trailing "=".  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the empty string.
   */
  String name;

  /**
   * Offset of the executable name relative to the beginning of the file.  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the offset of the class name (i.e. the
   * offset of the second "C" in "class C { C(); }").
   */
  @informative
  int nameOffset;

  /**
   * Documentation comment for the executable, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment documentationComment;

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  List<UnlinkedTypeParam> typeParameters;

  /**
   * Declared return type of the executable.  Absent if the executable is a
   * constructor or the return type is implicit.
   */
  EntityRef returnType;

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters (hence this will be the empty list), and setters have a single
   * parameter.
   */
  List<UnlinkedParam> parameters;

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  UnlinkedExecutableKind kind;

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  bool isAbstract;

  /**
   * Indicates whether the executable is declared using the `static` keyword.
   *
   * Note that for top level executables, this flag is false, since they are
   * not declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  bool isStatic;

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  bool isConst;

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  bool isFactory;

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  bool isExternal;

  /**
   * If this executable's return type is inferrable, nonzero slot id
   * identifying which entry in [LinkedLibrary.types] contains the inferred
   * return type.  If there is no matching entry in [LinkedLibrary.types], then
   * no return type was inferred for this variable, so its static type is
   * `dynamic`.
   */
  int inferredReturnTypeSlot;
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
class UnlinkedExportNonPublic {
  /**
   * Offset of the "export" keyword.
   */
  @informative
  int offset;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  @informative
  int uriOffset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  @informative
  int uriEnd;
}

/**
 * Unlinked summary information about an export declaration (stored inside
 * [UnlinkedPublicNamespace]).
 */
class UnlinkedExportPublic {
  /**
   * URI used in the source code to reference the exported library.
   */
  String uri;

  /**
   * Combinators contained in this import declaration.
   */
  List<UnlinkedCombinator> combinators;
}

/**
 * Unlinked summary information about an import declaration.
 */
class UnlinkedImport {
  /**
   * URI used in the source code to reference the imported library.
   */
  String uri;

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  @informative
  int offset;

  /**
   * Index into [UnlinkedUnit.references] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  int prefixReference;

  /**
   * Combinators contained in this import declaration.
   */
  List<UnlinkedCombinator> combinators;

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  bool isDeferred;

  /**
   * Indicates whether the import declaration is implicit.
   */
  bool isImplicit;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  @informative
  int uriOffset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  @informative
  int uriEnd;

  /**
   * Offset of the prefix name relative to the beginning of the file, or zero
   * if there is no prefix.
   */
  @informative
  int prefixOffset;
}

/**
 * Unlinked summary information about a function parameter.
 */
class UnlinkedParam {
  /**
   * Name of the parameter.
   */
  String name;

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  @informative
  int nameOffset;

  /**
   * If [isFunctionTyped] is `true`, the declared return type.  If
   * [isFunctionTyped] is `false`, the declared type.  Absent if the type is
   * implicit.
   */
  EntityRef type;

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  List<UnlinkedParam> parameters;

  /**
   * Kind of the parameter.
   */
  UnlinkedParamKind kind;

  /**
   * Indicates whether this is a function-typed parameter.
   */
  bool isFunctionTyped;

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  bool isInitializingFormal;

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
  int inferredTypeSlot;
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
class UnlinkedPart {
  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  @informative
  int uriOffset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  @informative
  int uriEnd;
}

/**
 * Unlinked summary information about a specific name contributed by a
 * compilation unit to a library's public namespace.
 *
 * TODO(paulberry): some of this information is redundant with information
 * elsewhere in the summary.  Consider reducing the redundancy to reduce
 * summary size.
 */
class UnlinkedPublicName {
  /**
   * The name itself.
   */
  String name;

  /**
   * The kind of object referred to by the name.
   */
  ReferenceKind kind;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int numTypeParameters;

  /**
   * If this [UnlinkedPublicName] is a class, the list of members which can be
   * referenced from constants - static constant fields, static methods, and
   * constructors.  Otherwise empty.
   */
  List<UnlinkedPublicName> constMembers;
}

/**
 * Unlinked summary information about what a compilation unit contributes to a
 * library's public namespace.  This is the subset of [UnlinkedUnit] that is
 * required from dependent libraries in order to perform prelinking.
 */
@topLevel
class UnlinkedPublicNamespace {
  /**
   * Public names defined in the compilation unit.
   *
   * TODO(paulberry): consider sorting these names to reduce unnecessary
   * relinking.
   */
  List<UnlinkedPublicName> names;

  /**
   * Export declarations in the compilation unit.
   */
  List<UnlinkedExportPublic> exports;

  /**
   * URIs referenced by part declarations in the compilation unit.
   */
  List<String> parts;
}

/**
 * Unlinked summary information about a name referred to in one library that
 * might be defined in another.
 */
class UnlinkedReference {
  /**
   * Name of the entity being referred to.  For the pseudo-type `dynamic`, the
   * string is "dynamic".  For the pseudo-type `void`, the string is "void".
   */
  String name;

  /**
   * Prefix used to refer to the entity, or zero if no prefix is used.  This is
   * an index into [UnlinkedUnit.references].
   *
   * Prefix references must always point backward; that is, for all i, if
   * UnlinkedUnit.references[i].prefixReference != 0, then
   * UnlinkedUnit.references[i].prefixReference < i.
   */
  int prefixReference;
}

/**
 * Unlinked summary information about a typedef declaration.
 */
class UnlinkedTypedef {
  /**
   * Name of the typedef.
   */
  String name;

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  @informative
  int nameOffset;

  /**
   * Documentation comment for the typedef, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment documentationComment;

  /**
   * Type parameters of the typedef, if any.
   */
  List<UnlinkedTypeParam> typeParameters;

  /**
   * Return type of the typedef.
   */
  EntityRef returnType;

  /**
   * Parameters of the executable, if any.
   */
  List<UnlinkedParam> parameters;
}

/**
 * Unlinked summary information about a type parameter declaration.
 */
class UnlinkedTypeParam {
  /**
   * Name of the type parameter.
   */
  String name;

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  @informative
  int nameOffset;

  /**
   * Bound of the type parameter, if a bound is explicitly declared.  Otherwise
   * null.
   */
  EntityRef bound;
}

/**
 * Unlinked summary information about a compilation unit ("part file").
 */
@topLevel
class UnlinkedUnit {
  /**
   * Name of the library (from a "library" declaration, if present).
   */
  String libraryName;

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  @informative
  int libraryNameOffset;

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  @informative
  int libraryNameLength;

  /**
   * Documentation comment for the library, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment libraryDocumentationComment;

  /**
   * Unlinked public namespace of this compilation unit.
   */
  UnlinkedPublicNamespace publicNamespace;

  /**
   * Top level and prefixed names referred to by this compilation unit.  The
   * zeroth element of this array is always populated and is used to represent
   * the absence of a reference in places where a reference is optional (for
   * example [UnlinkedReference.prefixReference or
   * UnlinkedImport.prefixReference]).
   */
  List<UnlinkedReference> references;

  /**
   * Classes declared in the compilation unit.
   */
  List<UnlinkedClass> classes;

  /**
   * Enums declared in the compilation unit.
   */
  List<UnlinkedEnum> enums;

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  List<UnlinkedExecutable> executables;

  /**
   * Export declarations in the compilation unit.
   */
  List<UnlinkedExportNonPublic> exports;

  /**
   * Import declarations in the compilation unit.
   */
  List<UnlinkedImport> imports;

  /**
   * Part declarations in the compilation unit.
   */
  List<UnlinkedPart> parts;

  /**
   * Typedefs declared in the compilation unit.
   */
  List<UnlinkedTypedef> typedefs;

  /**
   * Top level variables declared in the compilation unit.
   */
  List<UnlinkedVariable> variables;
}

/**
 * Unlinked summary information about a top level variable, local variable, or
 * a field.
 */
class UnlinkedVariable {
  /**
   * Name of the variable.
   */
  String name;

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  @informative
  int nameOffset;

  /**
   * Documentation comment for the variable, or `null` if there is no
   * documentation comment.
   */
  @informative
  UnlinkedDocumentationComment documentationComment;

  /**
   * Declared type of the variable.  Absent if the type is implicit.
   */
  EntityRef type;

  /**
   * If [isConst] is true, and the variable has an initializer, the constant
   * expression in the initializer.
   */
  UnlinkedConst constExpr;

  /**
   * Indicates whether the variable is declared using the `static` keyword.
   *
   * Note that for top level variables, this flag is false, since they are not
   * declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  bool isStatic;

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  bool isFinal;

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  bool isConst;

  /**
   * If this variable is propagable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the propagated type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then this variable's
   * propagated type is the same as its declared type.
   *
   * Non-propagable variables have a [propagatedTypeSlot] of zero.
   */
  int propagatedTypeSlot;

  /**
   * If this variable is inferrable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the inferred type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then no type was
   * inferred for this variable, so its static type is `dynamic`.
   */
  int inferredTypeSlot;
}
