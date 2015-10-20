// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is an "idl" style description of the summary format.  It is not
 * executed directly; instead it is parsed and transformed into code that
 * implements the summary format.
 *
 * The code generation process introduces the following non-typical semantics:
 * - Fields of type List have a default value of the empty list.
 * - Fields of type int have a default value of zero.
 * - Fields of type String have a defauld value of ''.
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
 * Annotation used to mark possible values of a "flags" field.  These will be
 * transformed into static constants.
 */
class Flag {
  final String name;
  final int value;
  final String comment;

  const Flag(this.name, this.value, this.comment);
}

/**
 * Information about a dependency that exists between one library and another
 * due to an "import" declaration.
 */
class PrelinkedDependency {
  /**
   * The relative URI used to import one library from the other.
   */
  String uri;
}

/**
 * Pre-linked summary of a library.
 */
class PrelinkedLibrary {
  /**
   * The unlinked library summary.
   */
  UnlinkedLibrary unlinked;

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
   * For each import in [UnlinkedLibrary.imports], an index into [dependencies]
   * of the library being imported.
   *
   * TODO(paulberry): if [dependencies] is removed, this can be removed as
   * well, since there will effectively be a one-to-one mapping.
   */
  List<int> importDependencies;

  /**
   * For each reference in [UnlinkedLibrary.references], information about how
   * that reference is resolved.
   */
  List<PrelinkedReference> references;
}

/**
 * Information about the resolution of an [UnlinkedReference].
 */
class PrelinkedReference {
  /**
   * Index into [LibraryElement.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  int dependency;

  @Flag('CLASS', 0, 'Indicates that the thing being referred to is a class')
  @Flag('TYPEDEF', 1, 'Indicates that the thing being referred to is a typedef')
  @Flag('OTHER', 2,
      'Indicates that the thing being referred to is a variable or executable')
  @Flag('UNRESOLVED', 3,
      'Indicates that the thing being referred to was not found')
  int flags;
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
   * Index into [UnlinkedLibrary.units] indicating which compilation unit the
   * class is declared in.
   */
  @informative
  int unit;

  /**
   * Type parameters of the class, if any.
   */
  List<UnlinkedTypeParam> typeParameters;

  /**
   * Supertype of the class, or `null` if the class doesn't explicitly declare
   * a supertype.
   */
  UnlinkedTypeRef supertype;

  /**
   * Mixins appering in a `with` clause, if any.
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

  @Flag(
      'ABSTRACT', 1, 'Set if the class is declared with the `abstract` keyword')
  @Flag('MIXIN_APP', 2,
      'Set if the class is declared using mixin appliation syntax')
  int flags;
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
 * Unlinked summary information about an enum declaration.
 */
class UnlinkedEnum {
  /**
   * Name of the enum type.
   */
  String name;

  /**
   * Values listed in the enum declaration.
   */
  List<UnlinkedEnumValue> values;

  /**
   * Index into [UnlinkedLibrary.units] indicating which compilation unit the
   * enum is declared in.
   */
  @informative
  int unit;
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
   * Index into [UnlinkedLibrary.units] indicating which compilation unit the
   * executable is declared in.  Zero for executables which are nested inside
   * another declaration (i.e. local functions and method declarations).
   */
  @informative
  int unit;

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  List<UnlinkedTypeParam> typeParameters;

  /**
   * Declared return type of the executable.  Absent if the return type is
   * `void`.  Note that when strong mode is enabled, the actual return type may
   * be different due to type inference.
   */
  UnlinkedTypeRef returnType;

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters, and setters have a single parameter.
   */
  List<UnlinkedParam> parameters;

  @Flag('FUNCTION', 0,
      'Indicates that the declaration is for a function or method')
  @Flag('GETTER', 1, 'Indicates that the declaration is for a getter')
  @Flag('SETTER', 2, 'Indicates that the declaration is for a setter')
  @Flag('CONSTRUCTOR', 3, 'Indicates that the declaration is for a constructor')
  @Flag('ABSTRACT', 4, 'Set if the declaration lacks a function body')
  @Flag('STATIC', 8, 'Set if the declaration includes the `static` keyword')
  @Flag('CONST', 16,
      'Set if the declaration includes the `const` keyword (constructors only)')
  @Flag('FACTORY', 32,
      'Set if the declaration includes the `factory` keyword (constructors only)')
  int flags;
}

/**
 * Unlinked summary information about an export declaration.
 */
class UnlinkedExport {
  /**
   * Relative URI used to reference the exported library.
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
   * Relative URI used to reference the imported library.
   */
  String uri;

  /**
   * Offset of the "import" keyword.  Zero for implicit imports.
   *
   * Note that explicit imports may also have an offset of zero.  To
   * distinguish explicit from implicit imports, look for the presence of the
   * [IMPLICIT] flag.
   */
  @informative
  int offset;

  /**
   * Index into [UnlinkedLibrary.prefixes] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  int prefix;

  /**
   * Combinators contained in this import declaration.
   */
  List<UnlinkedCombinator> combinators;

  @Flag('DEFERRED', 1, 'Set if this declaration uses the `deferred` keyword')
  @Flag('IMPLICIT', 2, 'Set if this is an implicit import')
  int flags;
}

/**
 * Unlinked summary of an entire library.
 */
class UnlinkedLibrary {
  /**
   * Top level and prefixed names referred to by this library.
   */
  List<UnlinkedReference> references;

  /**
   * Information about the units constituting this library.  The first unit
   * listed is always the defining compilation unit.
   */
  List<UnlinkedUnit> units;

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  String name;

  /**
   * Classes declared in the library.
   */
  List<UnlinkedClass> classes;

  /**
   * Enums declared in the library.
   */
  List<UnlinkedEnum> enums;

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the library.
   */
  List<UnlinkedExecutable> executables;

  /**
   * Export declarations in the library.
   */
  List<UnlinkedExport> exports;

  /**
   * Import declarations in the library.
   */
  List<UnlinkedImport> imports;

  /**
   * Typedefs declared in the library.
   */
  List<UnlinkedTypedef> typedefs;

  /**
   * Top level variables declared in the library.
   */
  List<UnlinkedVariable> variables;

  /**
   * Prefixes introduced by import declarations.  The first element in this
   * array is a pseudo-prefix used by references made with no prefix.
   */
  List<UnlinkedPrefix> prefixes;
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
   * If this is a function-typed parameter, the declared return type.
   * Otherwise, the declared type.  Absent if this is a function-typed
   * parameter and the declared return type is `void`.  Note that when strong
   * mode is enabled, the actual type may be different due to type inference.
   */
  UnlinkedTypeRef type;

  /**
   * If this is a function-typed parameter, the parameters of the function
   * type.
   */
  List<UnlinkedParam> parameters;

  @Flag('REQUIRED', 0, 'Indicates that this is a required parameter')
  @Flag(
      'POSITIONAL', 1, 'Indicates that this is a positional optional parameter')
  @Flag('NAMED', 2, 'Indicates that this is a named optional parameter')
  @Flag('FUNCTION_TYPED', 4, 'Set if this is a function-typed parameter')
  @Flag('INITIALIZING_FORMAL', 8,
      'Set if this is an initializing formal parameter')
  int flags;
}

class UnlinkedPrefix {
  /**
   * The name of the prefix, or the empty string in the case of the
   * pseudo-prefix which represents "no prefix".
   */
  String name;
}

/**
 * Unlinked summary information about a name referred to in one library that
 * might be defined in another.
 */
class UnlinkedReference {
  /**
   * Name of the entity being referred to.
   */
  String name;

  /**
   * Prefix used to refer to the entity.  This is an index into
   * [UnlinkedLibrary.prefixes].
   */
  int prefix;
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
   * Index into [UnlinkedLibrary.units] indicating which compilation unit the
   * typedef is declared in.
   */
  @informative
  int unit;

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
   * Index into [UnlinkedLibrary.references] for the type being referred to, or
   * zero if this is a reference to a type parameter.
   */
  int reference;

  /**
   * If this is a reference to a type parameter, one-based index into
   * [UnlinkedClass.typeParameters] or [UnlinkedTypedef.typeParameters] for the
   * parameter being referenced.  Otherwise zero.
   *
   * If generic method syntax is enabled, this may also be a one-based index
   * into [UnlinkedExecutable.typeParameters].  Note that this creates an
   * ambiguity since it allows executables with type parameters to be nested
   * inside other declarations with type parameters (which might themselves be
   * executables).  The ambiguity is resolved by considering this to be a
   * one-based index into a list that concatenates all type parameters that are
   * in scope, listing the outermost type parameters first.
   */
  int paramReference;

  /**
   * If this is an instantiation of a generic type, the type arguments used to
   * instantiate it.  Trailing type arguments of type `dynamic` are omitted.
   */
  List<UnlinkedTypeRef> typeArguments;
}

/**
 * Unlinked summary information about a compilation unit ("part file").  Note
 * that since a declaration can be moved from one part file to another without
 * changing semantics, the declarations themselves aren't stored here; they are
 * stored in [UnlinkedLibrary] and they refer to [UnlinkedUnit]s via an index
 * into [UnlinkedLibrary.units].
 */
class UnlinkedUnit {
  /**
   * String used in the defining compilation unit to reference the part file.
   * Empty for the defining compilation unit itself.
   */
  String uri;
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
   * Index into [UnlinkedLibrary.units] indicating which compilation unit the
   * variable is declared in.  Zero for variables which are nested inside
   * another declaration (i.e. local variables and fields).
   */
  @informative
  int unit;

  /**
   * Declared type of the variable.  Note that when strong mode is enabled, the
   * actual type of the variable may be different due to type inference.
   */
  UnlinkedTypeRef type;

  @Flag('STATIC', 1, 'Set if the declaration includes the `static` keyword')
  @Flag('FINAL', 2, 'Set if the declaration includes the `final` keyword')
  @Flag('CONST', 4, 'Set if the declaration includes the `const` keyword')
  int flags;
}
