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
 * - Fields of type int are never null, and have a default value of zero.
 * - Fields of type String are never null, and have a default value of ''.
 * - Fields of type bool are never null, and have a default value of false.
 * - Fields whose type is an enum are never null, and have a default value of
 *   the first value declared in the enum.
 *
 * Terminology used in this document:
 * - "Unlinked" refers to information that can be determined from reading the
 *   .dart file for the library itself (including all parts) and no other
 *   files.
 * - "Prelinked" refers to information that can be determined from reading the
 *   unlinked information for the library itself and the unlinked information
 *   for all direct imports (plus the transitive closure of exports reachable
 *   from those direct imports).
 * - "Linked" refers to information that can be determined only from reading
 *   the unlinked and prelinked information for the library itself and the
 *   transitive closure of its imports.
 *
 * TODO(paulberry): currently the summary format only contains unlinked and
 * prelinked information.
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
 * Information about a dependency that exists between one library and another
 * due to an "import" declaration.
 */
class PrelinkedDependency {
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
class PrelinkedExportName {
  /**
   * Name of the exported entity.  TODO(paulberry): do we include the trailing
   * '=' for a setter?
   */
  String name;

  /**
   * Index into [PrelinkedLibrary.dependencies] for the library in which the
   * entity is defined.
   */
  int dependency;

  /**
   * Integer index indicating which unit in the exported library contains the
   * definition of the entity.  As with indices into [PrelinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  int unit;

  /**
   * The kind of the entity being referred to.
   */
  PrelinkedReferenceKind kind;
}

/**
 * Pre-linked summary of a library.
 */
@topLevel
class PrelinkedLibrary {
  /**
   * The pre-linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  List<PrelinkedUnit> units;

  /**
   * The libraries that this library depends on (either via an explicit import
   * statement or via the implicit dependencies on `dart:core` and
   * `dart:async`).  The first element of this array is a pseudo-dependency
   * representing the library itself (it is also used for "dynamic").
   *
   * TODO(paulberry): consider removing this entirely and just using
   * [UnlinkedLibrary.imports].
   */
  List<PrelinkedDependency> dependencies;

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   *
   * TODO(paulberry): if [dependencies] is removed, this can be removed as
   * well, since there will effectively be a one-to-one mapping.
   */
  List<int> importDependencies;

  /**
   * Information about entities in the export namespace of the library that are
   * not in the public namespace of the library (that is, entities that are
   * brought into the namespace via `export` directives).
   *
   * Sorted by name.
   */
  List<PrelinkedExportName> exportNames;
}

/**
 * Information about the resolution of an [UnlinkedReference].
 */
class PrelinkedReference {
  /**
   * Index into [PrelinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  int dependency;

  /**
   * The kind of the entity being referred to.  For the pseudo-type `dynamic`,
   * the kind is [PrelinkedReferenceKind.classOrEnum].
   */
  PrelinkedReferenceKind kind;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [PrelinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  int unit;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int numTypeParameters;
}

/**
 * Enum used to indicate the kind of entity referred to by a
 * [PrelinkedReference].
 */
enum PrelinkedReferenceKind {
  /**
   * The entity is a class or enum.
   */
  classOrEnum,

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
 * Pre-linked summary of a compilation unit.
 */
class PrelinkedUnit {
  /**
   * For each reference in [UnlinkedUnit.references], information about how
   * that reference is resolved.
   */
  List<PrelinkedReference> references;
}

/**
 * Information about SDK.
 */
@topLevel
class SdkBundle {
  /**
   * The list of URIs of items in [prelinkedLibraries], e.g. `dart:core`.
   */
  List<String> prelinkedLibraryUris;

  /**
   * Pre-linked libraries.
   */
  List<PrelinkedLibrary> prelinkedLibraries;

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
  UnlinkedTypeRef supertype;

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  List<UnlinkedTypeRef> mixins;

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  List<UnlinkedTypeRef> interfaces;

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
   * Declared return type of the executable.  Absent if the return type is
   * `void` or the executable is a constructor.  Note that when strong mode is
   * enabled, the actual return type may be different due to type inference.
   */
  UnlinkedTypeRef returnType;

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
   * Indicates whether the executable lacks an explicit return type
   * declaration.  False for constructors and setters.
   */
  bool hasImplicitReturnType;

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  bool isExternal;
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
   * [isFunctionTyped] is `false`, the declared type.  Absent if
   * [isFunctionTyped] is `true` and the declared return type is `void`.  Note
   * that when strong mode is enabled, the actual type may be different due to
   * type inference.
   */
  UnlinkedTypeRef type;

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
   * Indicates whether this parameter lacks an explicit type declaration.
   * Always false for a function-typed parameter.
   */
  bool hasImplicitType;
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
 * TODO(paulberry): add a count of generic parameters, so that resynthesis
 * doesn't have to peek into the library to obtain this info.
 *
 * TODO(paulberry): for classes, add info about static members and
 * constructors, since this will be needed to prelink info about constants.
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
  PrelinkedReferenceKind kind;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int numTypeParameters;
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
   * Name of the entity being referred to.  The empty string refers to the
   * pseudo-type `dynamic`.
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
   * Return type of the typedef.  Absent if the return type is `void`.
   */
  UnlinkedTypeRef returnType;

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
  UnlinkedTypeRef bound;
}

/**
 * Unlinked summary information about a reference to a type.
 */
class UnlinkedTypeRef {
  /**
   * Index into [UnlinkedUnit.references] for the type being referred to, or
   * zero if this is a reference to a type parameter.
   *
   * Note that since zero is also a valid index into
   * [UnlinkedUnit.references], we cannot distinguish between references to
   * type parameters and references to types by checking [reference] against
   * zero.  To distinguish between references to type parameters and references
   * to types, check whether [paramReference] is zero.
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
   * If this is an instantiation of a generic type, the type arguments used to
   * instantiate it.  Trailing type arguments of type `dynamic` are omitted.
   */
  List<UnlinkedTypeRef> typeArguments;
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
   * zeroth element of this array is always populated and always represents a
   * reference to the pseudo-type "dynamic".
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
   * Declared type of the variable.  Note that when strong mode is enabled, the
   * actual type of the variable may be different due to type inference.
   */
  UnlinkedTypeRef type;

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
   * Indicates whether this variable lacks an explicit type declaration.
   */
  bool hasImplicitType;
}
