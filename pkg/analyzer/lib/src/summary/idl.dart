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

import 'package:analyzer/dart/element/element.dart';

import 'base.dart' as base;
import 'base.dart' show Id, TopLevel;
import 'format.dart' as generated;

/**
 * Annotation describing information which is not part of Dart semantics; in
 * other words, if this information (or any information it refers to) changes,
 * static analysis and runtime behavior of the library are unaffected.
 *
 * Information that has purely local effect (in other words, it does not affect
 * the API of the code being analyzed) is also marked as `informative`.
 */
const informative = null;

/**
 * Information about the context of an exception in analysis driver.
 */
@TopLevel('ADEC')
abstract class AnalysisDriverExceptionContext extends base.SummaryClass {
  factory AnalysisDriverExceptionContext.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverExceptionContext(buffer);

  /**
   * The exception string.
   */
  @Id(1)
  String get exception;

  /**
   * The state of files when the exception happened.
   */
  @Id(3)
  List<AnalysisDriverExceptionFile> get files;

  /**
   * The path of the file being analyzed when the exception happened.
   */
  @Id(0)
  String get path;

  /**
   * The exception stack trace string.
   */
  @Id(2)
  String get stackTrace;
}

/**
 * Information about a single file in [AnalysisDriverExceptionContext].
 */
abstract class AnalysisDriverExceptionFile extends base.SummaryClass {
  /**
   * The content of the file.
   */
  @Id(1)
  String get content;

  /**
   * The path of the file.
   */
  @Id(0)
  String get path;
}

/**
 * Information about a resolved unit.
 */
@TopLevel('ADRU')
abstract class AnalysisDriverResolvedUnit extends base.SummaryClass {
  factory AnalysisDriverResolvedUnit.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverResolvedUnit(buffer);

  /**
   * The full list of analysis errors, both syntactic and semantic.
   */
  @Id(0)
  List<AnalysisDriverUnitError> get errors;

  /**
   * The index of the unit.
   */
  @Id(1)
  AnalysisDriverUnitIndex get index;
}

/**
 * Information about a subtype of one or more classes.
 */
abstract class AnalysisDriverSubtype extends base.SummaryClass {
  /**
   * The names of defined instance members.
   * The list is sorted in ascending order.
   */
  @Id(2)
  List<String> get members;

  /**
   * The name of the class.
   */
  @Id(0)
  String get name;

  /**
   * The identifiers of the direct supertypes.
   * The list is sorted in ascending order.
   */
  @Id(1)
  List<String> get supertypes;
}

/**
 * Information about an error in a resolved unit.
 */
abstract class AnalysisDriverUnitError extends base.SummaryClass {
  /**
   * The optional correction hint for the error.
   */
  @Id(4)
  String get correction;

  /**
   * The length of the error in the file.
   */
  @Id(1)
  int get length;

  /**
   * The message of the error.
   */
  @Id(3)
  String get message;

  /**
   * The offset from the beginning of the file.
   */
  @Id(0)
  int get offset;

  /**
   * The unique name of the error code.
   */
  @Id(2)
  String get uniqueName;
}

/**
 * Information about a resolved unit.
 */
@TopLevel('ADUI')
abstract class AnalysisDriverUnitIndex extends base.SummaryClass {
  factory AnalysisDriverUnitIndex.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverUnitIndex(buffer);

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the kind of the synthetic element.
   */
  @Id(4)
  List<IndexSyntheticElementKind> get elementKinds;

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the class member element name, or `null` if the element
   * is a top-level element.  The list is sorted in ascending order, so that the
   * client can quickly check whether an element is referenced in this index.
   */
  @Id(7)
  List<int> get elementNameClassMemberIds;

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the named parameter name, or `null` if the element is not
   * a named parameter.  The list is sorted in ascending order, so that the
   * client can quickly check whether an element is referenced in this index.
   */
  @Id(8)
  List<int> get elementNameParameterIds;

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the top-level element name, or `null` if the element is
   * the unit.  The list is sorted in ascending order, so that the client can
   * quickly check whether an element is referenced in this index.
   */
  @Id(6)
  List<int> get elementNameUnitMemberIds;

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the index into [unitLibraryUris] and [unitUnitUris] for the library
   * specific unit where the element is declared.
   */
  @Id(5)
  List<int> get elementUnits;

  /**
   * Identifier of the null string in [strings].
   */
  @Id(1)
  int get nullStringId;

  /**
   * List of unique element strings used in this index.  The list is sorted in
   * ascending order, so that the client can quickly check the presence of a
   * string in this index.
   */
  @Id(0)
  List<String> get strings;

  /**
   * The list of classes declared in the unit.
   */
  @Id(18)
  List<AnalysisDriverSubtype> get subtypes;

  /**
   * Each item of this list corresponds to the library URI of a unique library
   * specific unit referenced in the index.  It is an index into [strings] list.
   */
  @Id(2)
  List<int> get unitLibraryUris;

  /**
   * Each item of this list corresponds to the unit URI of a unique library
   * specific unit referenced in the index.  It is an index into [strings] list.
   */
  @Id(3)
  List<int> get unitUnitUris;

  /**
   * Each item of this list is the `true` if the corresponding element usage
   * is qualified with some prefix.
   */
  @Id(13)
  List<bool> get usedElementIsQualifiedFlags;

  /**
   * Each item of this list is the kind of the element usage.
   */
  @Id(10)
  List<IndexRelationKind> get usedElementKinds;

  /**
   * Each item of this list is the length of the element usage.
   */
  @Id(12)
  List<int> get usedElementLengths;

  /**
   * Each item of this list is the offset of the element usage relative to the
   * beginning of the file.
   */
  @Id(11)
  List<int> get usedElementOffsets;

  /**
   * Each item of this list is the index into [elementUnits],
   * [elementNameUnitMemberIds], [elementNameClassMemberIds] and
   * [elementNameParameterIds].  The list is sorted in ascending order, so
   * that the client can quickly find element references in this index.
   */
  @Id(9)
  List<int> get usedElements;

  /**
   * Each item of this list is the `true` if the corresponding name usage
   * is qualified with some prefix.
   */
  @Id(17)
  List<bool> get usedNameIsQualifiedFlags;

  /**
   * Each item of this list is the kind of the name usage.
   */
  @Id(15)
  List<IndexRelationKind> get usedNameKinds;

  /**
   * Each item of this list is the offset of the name usage relative to the
   * beginning of the file.
   */
  @Id(16)
  List<int> get usedNameOffsets;

  /**
   * Each item of this list is the index into [strings] for a used name.  The
   * list is sorted in ascending order, so that the client can quickly find
   * whether a name is used in this index.
   */
  @Id(14)
  List<int> get usedNames;
}

/**
 * Information about an unlinked unit.
 */
@TopLevel('ADUU')
abstract class AnalysisDriverUnlinkedUnit extends base.SummaryClass {
  factory AnalysisDriverUnlinkedUnit.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverUnlinkedUnit(buffer);

  /**
   * List of class member names defined by the unit.
   */
  @Id(3)
  List<String> get definedClassMemberNames;

  /**
   * List of top-level names defined by the unit.
   */
  @Id(2)
  List<String> get definedTopLevelNames;

  /**
   * List of external names referenced by the unit.
   */
  @Id(0)
  List<String> get referencedNames;

  /**
   * List of names which are used in `extends`, `with` or `implements` clauses
   * in the file. Import prefixes and type arguments are not included.
   */
  @Id(4)
  List<String> get subtypedNames;

  /**
   * Unlinked information for the unit.
   */
  @Id(1)
  UnlinkedUnit get unit;
}

/**
 * Information about an element code range.
 */
abstract class CodeRange extends base.SummaryClass {
  /**
   * Length of the element code.
   */
  @Id(1)
  int get length;

  /**
   * Offset of the element code relative to the beginning of the file.
   */
  @Id(0)
  int get offset;
}

/**
 * Summary information about a reference to an entity such as a type, top level
 * executable, or executable within a class.
 */
abstract class EntityRef extends base.SummaryClass {
  /**
   * The kind of entity being represented.
   */
  @Id(8)
  EntityRefKind get entityKind;

  /**
   * Notice: This will be deprecated. However, its not deprecated yet, as we're
   * keeping it for backwards compatibilty, and marking it deprecated makes it
   * unreadable.
   *
   * TODO(mfairhurst) mark this deprecated, and remove its logic.
   *
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
  @Id(4)
  List<int> get implicitFunctionTypeIndices;

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
  @Id(3)
  int get paramReference;

  /**
   * Index into [UnlinkedUnit.references] for the entity being referred to, or
   * zero if this is a reference to a type parameter.
   */
  @Id(0)
  int get reference;

  /**
   * If this [EntityRef] is contained within [LinkedUnit.types], slot id (which
   * is unique within the compilation unit) identifying the target of type
   * propagation or type inference with which this [EntityRef] is associated.
   *
   * Otherwise zero.
   */
  @Id(2)
  int get slot;

  /**
   * If this [EntityRef] is a reference to a function type whose
   * [FunctionElement] is not in any library (e.g. a function type that was
   * synthesized by a LUB computation), the function parameters.  Otherwise
   * empty.
   */
  @Id(6)
  List<UnlinkedParam> get syntheticParams;

  /**
   * If this [EntityRef] is a reference to a function type whose
   * [FunctionElement] is not in any library (e.g. a function type that was
   * synthesized by a LUB computation), the return type of the function.
   * Otherwise `null`.
   */
  @Id(5)
  EntityRef get syntheticReturnType;

  /**
   * If this is an instantiation of a generic type or generic executable, the
   * type arguments used to instantiate it (if any).
   */
  @Id(1)
  List<EntityRef> get typeArguments;

  /**
   * If this is a function type, the type parameters defined for the function
   * type (if any).
   */
  @Id(7)
  List<UnlinkedTypeParam> get typeParameters;
}

/**
 * Enum used to indicate the kind of an entity reference.
 */
enum EntityRefKind {
  /**
   * The entity represents a named type.
   */
  named,

  /**
   * The entity represents a generic function type.
   */
  genericFunctionType,

  /**
   * The entity represents a function type that was synthesized by a LUB
   * computation.
   */
  syntheticFunction
}

/**
 * Enum used to indicate the kind of a name in index.
 */
enum IndexNameKind {
  /**
   * A top-level element.
   */
  topLevel,

  /**
   * A class member.
   */
  classMember
}

/**
 * Enum used to indicate the kind of an index relation.
 */
enum IndexRelationKind {
  /**
   * Left: class.
   *   Is ancestor of (is extended or implemented, directly or indirectly).
   * Right: other class declaration.
   */
  IS_ANCESTOR_OF,

  /**
   * Left: class.
   *   Is extended by.
   * Right: other class declaration.
   */
  IS_EXTENDED_BY,

  /**
   * Left: class.
   *   Is implemented by.
   * Right: other class declaration.
   */
  IS_IMPLEMENTED_BY,

  /**
   * Left: class.
   *   Is mixed into.
   * Right: other class declaration.
   */
  IS_MIXED_IN_BY,

  /**
   * Left: method, property accessor, function, variable.
   *   Is invoked at.
   * Right: location.
   */
  IS_INVOKED_BY,

  /**
   * Left: any element.
   *   Is referenced (and not invoked, read/written) at.
   * Right: location.
   */
  IS_REFERENCED_BY,

  /**
   * Left: unresolved member name.
   *   Is read at.
   * Right: location.
   */
  IS_READ_BY,

  /**
   * Left: unresolved member name.
   *   Is both read and written at.
   * Right: location.
   */
  IS_READ_WRITTEN_BY,

  /**
   * Left: unresolved member name.
   *   Is written at.
   * Right: location.
   */
  IS_WRITTEN_BY
}

/**
 * When we need to reference a synthetic element in [PackageIndex] we use a
 * value of this enum to specify which kind of the synthetic element we
 * actually reference.
 */
enum IndexSyntheticElementKind {
  /**
   * Not a synthetic element.
   */
  notSynthetic,

  /**
   * The unnamed synthetic constructor a class element.
   */
  constructor,

  /**
   * The synthetic field element.
   */
  field,

  /**
   * The synthetic getter of a property introducing element.
   */
  getter,

  /**
   * The synthetic setter of a property introducing element.
   */
  setter,

  /**
   * The synthetic top-level variable element.
   */
  topLevelVariable,

  /**
   * The synthetic `loadLibrary` element.
   */
  loadLibrary,

  /**
   * The synthetic `index` getter of an enum.
   */
  enumIndex,

  /**
   * The synthetic `values` getter of an enum.
   */
  enumValues,

  /**
   * The containing unit itself.
   */
  unit
}

/**
 * Information about a dependency that exists between one library and another
 * due to an "import" declaration.
 */
abstract class LinkedDependency extends base.SummaryClass {
  /**
   * Absolute URI for the compilation units listed in the library's `part`
   * declarations, empty string for invalid URI.
   */
  @Id(1)
  List<String> get parts;

  /**
   * The absolute URI of the dependent library, e.g. `package:foo/bar.dart`.
   */
  @Id(0)
  String get uri;
}

/**
 * Information about a single name in the export namespace of the library that
 * is not in the public namespace.
 */
abstract class LinkedExportName extends base.SummaryClass {
  /**
   * Index into [LinkedLibrary.dependencies] for the library in which the
   * entity is defined.
   */
  @Id(0)
  int get dependency;

  /**
   * The kind of the entity being referred to.
   */
  @Id(3)
  ReferenceKind get kind;

  /**
   * Name of the exported entity.  For an exported setter, this name includes
   * the trailing '='.
   */
  @Id(1)
  String get name;

  /**
   * Integer index indicating which unit in the exported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  @Id(2)
  int get unit;
}

/**
 * Linked summary of a library.
 */
@TopLevel('LLib')
abstract class LinkedLibrary extends base.SummaryClass {
  factory LinkedLibrary.fromBuffer(List<int> buffer) =>
      generated.readLinkedLibrary(buffer);

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
  @Id(0)
  List<LinkedDependency> get dependencies;

  /**
   * For each export in [UnlinkedUnit.exports], an index into [dependencies]
   * of the library being exported.
   */
  @Id(6)
  List<int> get exportDependencies;

  /**
   * Information about entities in the export namespace of the library that are
   * not in the public namespace of the library (that is, entities that are
   * brought into the namespace via `export` directives).
   *
   * Sorted by name.
   */
  @Id(4)
  List<LinkedExportName> get exportNames;

  /**
   * Indicates whether this library was summarized in "fallback mode".  If
   * true, all other fields in the data structure have their default values.
   */
  @deprecated
  @Id(5)
  bool get fallbackMode;

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   */
  @Id(1)
  List<int> get importDependencies;

  /**
   * The number of elements in [dependencies] which are not "linked"
   * dependencies (that is, the number of libraries in the direct imports plus
   * the transitive closure of exports, plus the library itself).
   */
  @Id(2)
  int get numPrelinkedDependencies;

  /**
   * The linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  @Id(3)
  List<LinkedUnit> get units;
}

/**
 * Information about the resolution of an [UnlinkedReference].
 */
abstract class LinkedReference extends base.SummaryClass {
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
  @Id(5)
  int get containingReference;

  /**
   * Index into [LinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   *
   * Zero if this entity is contained within another entity (e.g. a class
   * member), or if [kind] is [ReferenceKind.prefix].
   */
  @Id(1)
  int get dependency;

  /**
   * The kind of the entity being referred to.  For the pseudo-types `dynamic`
   * and `void`, the kind is [ReferenceKind.classOrEnum].
   */
  @Id(2)
  ReferenceKind get kind;

  /**
   * If [kind] is [ReferenceKind.function] (that is, the entity being referred
   * to is a local function), the index of the function within
   * [UnlinkedExecutable.localFunctions].  Otherwise zero.
   */
  @deprecated
  @Id(6)
  int get localIndex;

  /**
   * If this [LinkedReference] doesn't have an associated [UnlinkedReference],
   * name of the entity being referred to.  For the pseudo-type `dynamic`, the
   * string is "dynamic".  For the pseudo-type `void`, the string is "void".
   */
  @Id(3)
  String get name;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it declares (does not include type parameters of enclosing entities).
   * Otherwise zero.
   */
  @Id(4)
  int get numTypeParameters;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   *
   * Zero if this entity is contained within another entity (e.g. a class
   * member).
   */
  @Id(0)
  int get unit;
}

/**
 * Linked summary of a compilation unit.
 */
abstract class LinkedUnit extends base.SummaryClass {
  /**
   * List of slot ids (referring to [UnlinkedExecutable.constCycleSlot])
   * corresponding to const constructors that are part of cycles.
   */
  @Id(2)
  List<int> get constCycles;

  /**
   * List of slot ids (referring to [UnlinkedParam.inheritsCovariantSlot] or
   * [UnlinkedVariable.inheritsCovariantSlot]) corresponding to parameters
   * that inherit `@covariant` behavior from a base class.
   */
  @Id(3)
  List<int> get parametersInheritingCovariant;

  /**
   * Information about the resolution of references within the compilation
   * unit.  Each element of [UnlinkedUnit.references] has a corresponding
   * element in this list (at the same index).  If this list has additional
   * elements beyond the number of elements in [UnlinkedUnit.references], those
   * additional elements are references that are only referred to implicitly
   * (e.g. elements involved in inferred or propagated types).
   */
  @Id(0)
  List<LinkedReference> get references;

  /**
   * The list of type inference errors.
   */
  @Id(4)
  List<TopLevelInferenceError> get topLevelInferenceErrors;

  /**
   * List associating slot ids found inside the unlinked summary for the
   * compilation unit with propagated and inferred types.
   */
  @Id(1)
  List<EntityRef> get types;
}

/**
 * Summary information about a package.
 */
@TopLevel('PBdl')
abstract class PackageBundle extends base.SummaryClass {
  factory PackageBundle.fromBuffer(List<int> buffer) =>
      generated.readPackageBundle(buffer);

  /**
   * MD5 hash of the non-informative fields of the [PackageBundle] (not
   * including this one).  This can be used to identify when the API of a
   * package may have changed.
   */
  @Id(7)
  String get apiSignature;

  /**
   * Information about the packages this package depends on, if known.
   */
  @Id(8)
  @informative
  List<PackageDependencyInfo> get dependencies;

  /**
   * Linked libraries.
   */
  @Id(0)
  List<LinkedLibrary> get linkedLibraries;

  /**
   * The list of URIs of items in [linkedLibraries], e.g. `dart:core` or
   * `package:foo/bar.dart`.
   */
  @Id(1)
  List<String> get linkedLibraryUris;

  /**
   * Major version of the summary format.  See
   * [PackageBundleAssembler.currentMajorVersion].
   */
  @Id(5)
  int get majorVersion;

  /**
   * Minor version of the summary format.  See
   * [PackageBundleAssembler.currentMinorVersion].
   */
  @Id(6)
  int get minorVersion;

  /**
   * List of MD5 hashes of the files listed in [unlinkedUnitUris].  Each hash
   * is encoded as a hexadecimal string using lower case letters.
   */
  @Id(4)
  @informative
  List<String> get unlinkedUnitHashes;

  /**
   * Unlinked information for the compilation units constituting the package.
   */
  @Id(2)
  List<UnlinkedUnit> get unlinkedUnits;

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  @Id(3)
  List<String> get unlinkedUnitUris;
}

/**
 * Information about a single dependency of a summary package.
 */
abstract class PackageDependencyInfo extends base.SummaryClass {
  /**
   * API signature of this dependency.
   */
  @Id(0)
  String get apiSignature;

  /**
   * If this dependency summarizes any files whose URI takes the form
   * "package:<package_name>/...", a list of all such package names, sorted
   * lexicographically.  Otherwise empty.
   */
  @Id(2)
  List<String> get includedPackageNames;

  /**
   * Indicates whether this dependency summarizes any files whose URI takes the
   * form "dart:...".
   */
  @Id(4)
  bool get includesDartUris;

  /**
   * Indicates whether this dependency summarizes any files whose URI takes the
   * form "file:...".
   */
  @Id(3)
  bool get includesFileUris;

  /**
   * Relative path to the summary file for this dependency.  This is intended as
   * a hint to help the analysis server locate summaries of dependencies.  We
   * don't specify precisely what this path is relative to, but we expect it to
   * be relative to a directory the analysis server can find (e.g. for projects
   * built using Bazel, it would be relative to the "bazel-bin" directory).
   *
   * Absent if the path is not known.
   */
  @Id(1)
  String get summaryPath;
}

/**
 * Index information about a package.
 */
@TopLevel('Indx')
abstract class PackageIndex extends base.SummaryClass {
  factory PackageIndex.fromBuffer(List<int> buffer) =>
      generated.readPackageIndex(buffer);

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the kind of the synthetic element.
   */
  @Id(5)
  List<IndexSyntheticElementKind> get elementKinds;

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the class member element name, or `null` if the element
   * is a top-level element.  The list is sorted in ascending order, so that the
   * client can quickly check whether an element is referenced in this
   * [PackageIndex].
   */
  @Id(7)
  List<int> get elementNameClassMemberIds;

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the named parameter name, or `null` if the element is not
   * a named parameter.  The list is sorted in ascending order, so that the
   * client can quickly check whether an element is referenced in this
   * [PackageIndex].
   */
  @Id(8)
  List<int> get elementNameParameterIds;

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the identifier of the top-level element name, or `null` if the element is
   * the unit.  The list is sorted in ascending order, so that the client can
   * quickly check whether an element is referenced in this [PackageIndex].
   */
  @Id(1)
  List<int> get elementNameUnitMemberIds;

  /**
   * Each item of this list corresponds to a unique referenced element.  It is
   * the index into [unitLibraryUris] and [unitUnitUris] for the library
   * specific unit where the element is declared.
   */
  @Id(0)
  List<int> get elementUnits;

  /**
   * List of unique element strings used in this [PackageIndex].  The list is
   * sorted in ascending order, so that the client can quickly check the
   * presence of a string in this [PackageIndex].
   */
  @Id(6)
  List<String> get strings;

  /**
   * Each item of this list corresponds to the library URI of a unique library
   * specific unit referenced in the [PackageIndex].  It is an index into
   * [strings] list.
   */
  @Id(2)
  List<int> get unitLibraryUris;

  /**
   * List of indexes of each unit in this [PackageIndex].
   */
  @Id(4)
  List<UnitIndex> get units;

  /**
   * Each item of this list corresponds to the unit URI of a unique library
   * specific unit referenced in the [PackageIndex].  It is an index into
   * [strings] list.
   */
  @Id(3)
  List<int> get unitUnitUris;
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
   * The entity is a typedef.
   */
  typedef,

  /**
   * The entity is a local function.
   */
  function,

  /**
   * The entity is a local variable.
   */
  variable,

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
  unresolved,

  /**
   * The entity is a typedef expressed using generic function type syntax.
   */
  genericFunctionTypedef
}

/**
 * Summary information about a top-level type inference error.
 */
abstract class TopLevelInferenceError extends base.SummaryClass {
  /**
   * The [kind] specific arguments.
   */
  @Id(2)
  List<String> get arguments;

  /**
   * The kind of the error.
   */
  @Id(1)
  TopLevelInferenceErrorKind get kind;

  /**
   * The slot id (which is unique within the compilation unit) identifying the
   * target of type inference with which this [TopLevelInferenceError] is
   * associated.
   */
  @Id(0)
  int get slot;
}

/**
 * Enum used to indicate the kind of the error during top-level inference.
 */
enum TopLevelInferenceErrorKind {
  assignment,
  instanceGetter,
  dependencyCycle,
  overrideConflictFieldType,
  overrideConflictReturnType,
  overrideConflictParameterType
}

/**
 * Enum used to indicate the style of a typedef.
 */
enum TypedefStyle {
  /**
   * A typedef that defines a non-generic function type. The syntax is
   * ```
   * 'typedef' returnType? identifier typeParameters? formalParameterList ';'
   * ```
   * The typedef can have type parameters associated with it, but the function
   * type that results from applying type arguments does not.
   */
  functionType,

  /**
   * A typedef expressed using generic function type syntax. The syntax is
   * ```
   * typeAlias ::=
   *     'typedef' identifier typeParameters? '=' genericFunctionType ';'
   * genericFunctionType ::=
   *     returnType? 'Function' typeParameters? parameterTypeList
   * ```
   * Both the typedef itself and the function type that results from applying
   * type arguments can have type parameters.
   */
  genericFunctionType
}

/**
 * Index information about a unit in a [PackageIndex].
 */
abstract class UnitIndex extends base.SummaryClass {
  /**
   * Each item of this list is the kind of an element defined in this unit.
   */
  @Id(6)
  List<IndexNameKind> get definedNameKinds;

  /**
   * Each item of this list is the name offset of an element defined in this
   * unit relative to the beginning of the file.
   */
  @Id(7)
  List<int> get definedNameOffsets;

  /**
   * Each item of this list corresponds to an element defined in this unit.  It
   * is an index into [PackageIndex.strings] list.  The list is sorted in
   * ascending order, so that the client can quickly find name definitions in
   * this [UnitIndex].
   */
  @Id(5)
  List<int> get definedNames;

  /**
   * Index into [PackageIndex.unitLibraryUris] and [PackageIndex.unitUnitUris]
   * for the library specific unit that corresponds to this [UnitIndex].
   */
  @Id(0)
  int get unit;

  /**
   * Each item of this list is the `true` if the corresponding element usage
   * is qualified with some prefix.
   */
  @Id(11)
  List<bool> get usedElementIsQualifiedFlags;

  /**
   * Each item of this list is the kind of the element usage.
   */
  @Id(4)
  List<IndexRelationKind> get usedElementKinds;

  /**
   * Each item of this list is the length of the element usage.
   */
  @Id(1)
  List<int> get usedElementLengths;

  /**
   * Each item of this list is the offset of the element usage relative to the
   * beginning of the file.
   */
  @Id(2)
  List<int> get usedElementOffsets;

  /**
   * Each item of this list is the index into [PackageIndex.elementUnits] and
   * [PackageIndex.elementOffsets].  The list is sorted in ascending order, so
   * that the client can quickly find element references in this [UnitIndex].
   */
  @Id(3)
  List<int> get usedElements;

  /**
   * Each item of this list is the `true` if the corresponding name usage
   * is qualified with some prefix.
   */
  @Id(12)
  List<bool> get usedNameIsQualifiedFlags;

  /**
   * Each item of this list is the kind of the name usage.
   */
  @Id(10)
  List<IndexRelationKind> get usedNameKinds;

  /**
   * Each item of this list is the offset of the name usage relative to the
   * beginning of the file.
   */
  @Id(9)
  List<int> get usedNameOffsets;

  /**
   * Each item of this list is the index into [PackageIndex.strings] for a
   * used name.  The list is sorted in ascending order, so that the client can
   * quickly find name uses in this [UnitIndex].
   */
  @Id(8)
  List<int> get usedNames;
}

/**
 * Unlinked summary information about a class declaration.
 */
abstract class UnlinkedClass extends base.SummaryClass {
  /**
   * Annotations for this class.
   */
  @Id(5)
  List<UnlinkedExpr> get annotations;

  /**
   * Code range of the class.
   */
  @informative
  @Id(13)
  CodeRange get codeRange;

  /**
   * Documentation comment for the class, or `null` if there is no
   * documentation comment.
   */
  @informative
  @Id(6)
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  @Id(2)
  List<UnlinkedExecutable> get executables;

  /**
   * Field declarations contained in the class.
   */
  @Id(4)
  List<UnlinkedVariable> get fields;

  /**
   * Indicates whether this class is the core "Object" class (and hence has no
   * supertype)
   */
  @Id(12)
  bool get hasNoSupertype;

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  @Id(7)
  List<EntityRef> get interfaces;

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  @Id(8)
  bool get isAbstract;

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  @Id(11)
  bool get isMixinApplication;

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  @Id(10)
  List<EntityRef> get mixins;

  /**
   * Name of the class.
   */
  @Id(0)
  String get name;

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  @informative
  @Id(1)
  int get nameOffset;

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  @Id(3)
  EntityRef get supertype;

  /**
   * Type parameters of the class, if any.
   */
  @Id(9)
  List<UnlinkedTypeParam> get typeParameters;
}

/**
 * Unlinked summary information about a `show` or `hide` combinator in an
 * import or export declaration.
 */
abstract class UnlinkedCombinator extends base.SummaryClass {
  /**
   * If this is a `show` combinator, offset of the end of the list of shown
   * names.  Otherwise zero.
   */
  @informative
  @Id(3)
  int get end;

  /**
   * List of names which are hidden.  Empty if this is a `show` combinator.
   */
  @Id(1)
  List<String> get hides;

  /**
   * If this is a `show` combinator, offset of the `show` keyword.  Otherwise
   * zero.
   */
  @informative
  @Id(2)
  int get offset;

  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  @Id(0)
  List<String> get shows;
}

/**
 * Unlinked summary information about a single import or export configuration.
 */
abstract class UnlinkedConfiguration extends base.SummaryClass {
  /**
   * The name of the declared variable whose value is being used in the
   * condition.
   */
  @Id(0)
  String get name;

  /**
   * The URI of the implementation library to be used if the condition is true.
   */
  @Id(2)
  String get uri;

  /**
   * The value to which the value of the declared variable will be compared,
   * or `true` if the condition does not include an equality test.
   */
  @Id(1)
  String get value;
}

/**
 * Unlinked summary information about a constructor initializer.
 */
abstract class UnlinkedConstructorInitializer extends base.SummaryClass {
  /**
   * If there are `m` [arguments] and `n` [argumentNames], then each argument
   * from [arguments] with index `i` such that `n + i - m >= 0`, should be used
   * with the name at `n + i - m`.
   */
  @Id(4)
  List<String> get argumentNames;

  /**
   * If [kind] is `thisInvocation` or `superInvocation`, the arguments of the
   * invocation.  Otherwise empty.
   */
  @Id(3)
  List<UnlinkedExpr> get arguments;

  /**
   * If [kind] is `field`, the expression of the field initializer.
   * Otherwise `null`.
   */
  @Id(1)
  UnlinkedExpr get expression;

  /**
   * The kind of the constructor initializer (field, redirect, super).
   */
  @Id(2)
  UnlinkedConstructorInitializerKind get kind;

  /**
   * If [kind] is `field`, the name of the field declared in the class.  If
   * [kind] is `thisInvocation`, the name of the constructor, declared in this
   * class, to redirect to.  If [kind] is `superInvocation`, the name of the
   * constructor, declared in the superclass, to invoke.
   */
  @Id(0)
  String get name;
}

/**
 * Enum used to indicate the kind of an constructor initializer.
 */
enum UnlinkedConstructorInitializerKind {
  /**
   * Initialization of a field.
   */
  field,

  /**
   * Invocation of a constructor in the same class.
   */
  thisInvocation,

  /**
   * Invocation of a superclass' constructor.
   */
  superInvocation,

  /**
   * Invocation of `assert`.
   */
  assertInvocation
}

/**
 * Unlinked summary information about a documentation comment.
 */
abstract class UnlinkedDocumentationComment extends base.SummaryClass {
  /**
   * Length of the documentation comment (prior to replacing '\r\n' with '\n').
   */
  @Id(0)
  @deprecated
  int get length;

  /**
   * Offset of the beginning of the documentation comment relative to the
   * beginning of the file.
   */
  @Id(2)
  @deprecated
  int get offset;

  /**
   * Text of the documentation comment, with '\r\n' replaced by '\n'.
   *
   * References appearing within the doc comment in square brackets are not
   * specially encoded.
   */
  @Id(1)
  String get text;
}

/**
 * Unlinked summary information about an enum declaration.
 */
abstract class UnlinkedEnum extends base.SummaryClass {
  /**
   * Annotations for this enum.
   */
  @Id(4)
  List<UnlinkedExpr> get annotations;

  /**
   * Code range of the enum.
   */
  @informative
  @Id(5)
  CodeRange get codeRange;

  /**
   * Documentation comment for the enum, or `null` if there is no documentation
   * comment.
   */
  @informative
  @Id(3)
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Name of the enum type.
   */
  @Id(0)
  String get name;

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  @informative
  @Id(1)
  int get nameOffset;

  /**
   * Values listed in the enum declaration, in declaration order.
   */
  @Id(2)
  List<UnlinkedEnumValue> get values;
}

/**
 * Unlinked summary information about a single enumerated value in an enum
 * declaration.
 */
abstract class UnlinkedEnumValue extends base.SummaryClass {
  /**
   * Documentation comment for the enum value, or `null` if there is no
   * documentation comment.
   */
  @informative
  @Id(2)
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Name of the enumerated value.
   */
  @Id(0)
  String get name;

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  @informative
  @Id(1)
  int get nameOffset;
}

/**
 * Unlinked summary information about a function, method, getter, or setter
 * declaration.
 */
abstract class UnlinkedExecutable extends base.SummaryClass {
  /**
   * Annotations for this executable.
   */
  @Id(6)
  List<UnlinkedExpr> get annotations;

  /**
   * If this executable's function body is declared using `=>`, the expression
   * to the right of the `=>`.  May be omitted if neither type inference nor
   * constant evaluation depends on the function body.
   */
  @Id(29)
  UnlinkedExpr get bodyExpr;

  /**
   * Code range of the executable.
   */
  @informative
  @Id(26)
  CodeRange get codeRange;

  /**
   * If a constant [UnlinkedExecutableKind.constructor], the constructor
   * initializers.  Otherwise empty.
   */
  @Id(14)
  List<UnlinkedConstructorInitializer> get constantInitializers;

  /**
   * If [kind] is [UnlinkedExecutableKind.constructor] and [isConst] is `true`,
   * a nonzero slot id which is unique within this compilation unit.  If this id
   * is found in [LinkedUnit.constCycles], then this constructor is part of a
   * cycle.
   *
   * Otherwise, zero.
   */
  @Id(25)
  int get constCycleSlot;

  /**
   * Documentation comment for the executable, or `null` if there is no
   * documentation comment.
   */
  @informative
  @Id(7)
  UnlinkedDocumentationComment get documentationComment;

  /**
   * If this executable's return type is inferable, nonzero slot id
   * identifying which entry in [LinkedUnit.types] contains the inferred
   * return type.  If there is no matching entry in [LinkedUnit.types], then
   * no return type was inferred for this variable, so its static type is
   * `dynamic`.
   */
  @Id(5)
  int get inferredReturnTypeSlot;

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  @Id(10)
  bool get isAbstract;

  /**
   * Indicates whether the executable has body marked as being asynchronous.
   */
  @informative
  @Id(27)
  bool get isAsynchronous;

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  @Id(12)
  bool get isConst;

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  @Id(11)
  bool get isExternal;

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  @Id(8)
  bool get isFactory;

  /**
   * Indicates whether the executable has body marked as being a generator.
   */
  @informative
  @Id(28)
  bool get isGenerator;

  /**
   * Indicates whether the executable is a redirected constructor.
   */
  @Id(13)
  bool get isRedirectedConstructor;

  /**
   * Indicates whether the executable is declared using the `static` keyword.
   *
   * Note that for top level executables, this flag is false, since they are
   * not declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  @Id(9)
  bool get isStatic;

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  @Id(4)
  UnlinkedExecutableKind get kind;

  /**
   * The list of local functions.
   */
  @Id(18)
  List<UnlinkedExecutable> get localFunctions;

  /**
   * The list of local labels.
   */
  @informative
  @deprecated
  @Id(22)
  List<String> get localLabels;

  /**
   * The list of local variables.
   */
  @informative
  @deprecated
  @Id(19)
  List<UnlinkedVariable> get localVariables;

  /**
   * Name of the executable.  For setters, this includes the trailing "=".  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the empty string.
   */
  @Id(1)
  String get name;

  /**
   * If [kind] is [UnlinkedExecutableKind.constructor] and [name] is not empty,
   * the offset of the end of the constructor name.  Otherwise zero.
   */
  @informative
  @Id(23)
  int get nameEnd;

  /**
   * Offset of the executable name relative to the beginning of the file.  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the offset of the class name (i.e. the
   * offset of the second "C" in "class C { C(); }").
   */
  @informative
  @Id(0)
  int get nameOffset;

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters (hence this will be the empty list), and setters have a single
   * parameter.
   */
  @Id(2)
  List<UnlinkedParam> get parameters;

  /**
   * If [kind] is [UnlinkedExecutableKind.constructor] and [name] is not empty,
   * the offset of the period before the constructor name.  Otherwise zero.
   */
  @informative
  @Id(24)
  int get periodOffset;

  /**
   * If [isRedirectedConstructor] and [isFactory] are both `true`, the
   * constructor to which this constructor redirects; otherwise empty.
   */
  @Id(15)
  EntityRef get redirectedConstructor;

  /**
   * If [isRedirectedConstructor] is `true` and [isFactory] is `false`, the
   * name of the constructor that this constructor redirects to; otherwise
   * empty.
   */
  @Id(17)
  String get redirectedConstructorName;

  /**
   * Declared return type of the executable.  Absent if the executable is a
   * constructor or the return type is implicit.  Absent for executables
   * associated with variable initializers and closures, since these
   * executables may have return types that are not accessible via direct
   * imports.
   */
  @Id(3)
  EntityRef get returnType;

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  @Id(16)
  List<UnlinkedTypeParam> get typeParameters;

  /**
   * If a local function, the length of the visible range; zero otherwise.
   */
  @informative
  @Id(20)
  int get visibleLength;

  /**
   * If a local function, the beginning of the visible range; zero otherwise.
   */
  @informative
  @Id(21)
  int get visibleOffset;
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
   * Annotations for this export directive.
   */
  @Id(3)
  List<UnlinkedExpr> get annotations;

  /**
   * Offset of the "export" keyword.
   */
  @informative
  @Id(0)
  int get offset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  @informative
  @Id(1)
  int get uriEnd;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  @informative
  @Id(2)
  int get uriOffset;
}

/**
 * Unlinked summary information about an export declaration (stored inside
 * [UnlinkedPublicNamespace]).
 */
abstract class UnlinkedExportPublic extends base.SummaryClass {
  /**
   * Combinators contained in this export declaration.
   */
  @Id(1)
  List<UnlinkedCombinator> get combinators;

  /**
   * Configurations used to control which library will actually be loaded at
   * run-time.
   */
  @Id(2)
  List<UnlinkedConfiguration> get configurations;

  /**
   * URI used in the source code to reference the exported library.
   */
  @Id(0)
  String get uri;
}

/**
 * Unlinked summary information about an expression.
 *
 * Expressions are represented using a simple stack-based language
 * where [operations] is a sequence of operations to execute starting with an
 * empty stack.  Once all operations have been executed, the stack should
 * contain a single value which is the value of the constant.  Note that some
 * operations consume additional data from the other fields of this class.
 */
abstract class UnlinkedExpr extends base.SummaryClass {
  /**
   * Sequence of operators used by assignment operations.
   */
  @Id(6)
  List<UnlinkedExprAssignOperator> get assignmentOperators;

  /**
   * Sequence of 64-bit doubles consumed by the operation `pushDouble`.
   */
  @Id(4)
  List<double> get doubles;

  /**
   * Sequence of unsigned 32-bit integers consumed by the operations
   * `pushArgument`, `pushInt`, `shiftOr`, `concatenate`, `invokeConstructor`,
   * `makeList`, and `makeMap`.
   */
  @Id(1)
  List<int> get ints;

  /**
   * Indicates whether the expression is a valid potentially constant
   * expression.
   */
  @Id(5)
  bool get isValidConst;

  /**
   * Sequence of operations to execute (starting with an empty stack) to form
   * the constant value.
   */
  @Id(0)
  List<UnlinkedExprOperation> get operations;

  /**
   * Sequence of language constructs consumed by the operations
   * `pushReference`, `invokeConstructor`, `makeList`, and `makeMap`.  Note
   * that in the case of `pushReference` (and sometimes `invokeConstructor` the
   * actual entity being referred to may be something other than a type.
   */
  @Id(2)
  List<EntityRef> get references;

  /**
   * Sequence of strings consumed by the operations `pushString` and
   * `invokeConstructor`.
   */
  @Id(3)
  List<String> get strings;
}

/**
 * Enum representing the various kinds of assignment operations combined
 * with:
 *    [UnlinkedExprOperation.assignToRef],
 *    [UnlinkedExprOperation.assignToProperty],
 *    [UnlinkedExprOperation.assignToIndex].
 */
enum UnlinkedExprAssignOperator {
  /**
   * Perform simple assignment `target = operand`.
   */
  assign,

  /**
   * Perform `target ??= operand`.
   */
  ifNull,

  /**
   * Perform `target *= operand`.
   */
  multiply,

  /**
   * Perform `target /= operand`.
   */
  divide,

  /**
   * Perform `target ~/= operand`.
   */
  floorDivide,

  /**
   * Perform `target %= operand`.
   */
  modulo,

  /**
   * Perform `target += operand`.
   */
  plus,

  /**
   * Perform `target -= operand`.
   */
  minus,

  /**
   * Perform `target <<= operand`.
   */
  shiftLeft,

  /**
   * Perform `target >>= operand`.
   */
  shiftRight,

  /**
   * Perform `target &= operand`.
   */
  bitAnd,

  /**
   * Perform `target ^= operand`.
   */
  bitXor,

  /**
   * Perform `target |= operand`.
   */
  bitOr,

  /**
   * Perform `++target`.
   */
  prefixIncrement,

  /**
   * Perform `--target`.
   */
  prefixDecrement,

  /**
   * Perform `target++`.
   */
  postfixIncrement,

  /**
   * Perform `target++`.
   */
  postfixDecrement,
}

/**
 * Enum representing the various kinds of operations which may be performed to
 * in an expression.  These options are assumed to execute in the
 * context of a stack which is initially empty.
 */
enum UnlinkedExprOperation {
  /**
   * Push the next value from [UnlinkedExpr.ints] (a 32-bit unsigned integer)
   * onto the stack.
   *
   * Note that Dart supports integers larger than 32 bits; these are
   * represented by composing 32-bit values using the [pushLongInt] operation.
   */
  pushInt,

  /**
   * Get the number of components from [UnlinkedExpr.ints], then do this number
   * of times the following operations: multiple the current value by 2^32, "or"
   * it with the next value in [UnlinkedExpr.ints]. The initial value is zero.
   * Push the result into the stack.
   */
  pushLongInt,

  /**
   * Push the next value from [UnlinkedExpr.doubles] (a double precision
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
   * Push the next value from [UnlinkedExpr.strings] onto the stack.
   */
  pushString,

  /**
   * Pop the top n values from the stack (where n is obtained from
   * [UnlinkedExpr.ints]), convert them to strings (if they aren't already),
   * concatenate them into a single string, and push it back onto the stack.
   *
   * This operation is used to represent constants whose value is a literal
   * string containing string interpolations.
   */
  concatenate,

  /**
   * Get the next value from [UnlinkedExpr.strings], convert it to a symbol,
   * and push it onto the stack.
   */
  makeSymbol,

  /**
   * Push the constant `null` onto the stack.
   */
  pushNull,

  /**
   * Push the value of the function parameter with the name obtained from
   * [UnlinkedExpr.strings].
   */
  pushParameter,

  /**
   * Evaluate a (potentially qualified) identifier expression and push the
   * resulting value onto the stack.  The identifier to be evaluated is
   * obtained from [UnlinkedExpr.references].
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
   * Pop the top value from the stack, extract the value of the property with
   * the name obtained from [UnlinkedExpr.strings], and push the result back
   * onto the stack.
   */
  extractProperty,

  /**
   * Pop the top `n` values from the stack (where `n` is obtained from
   * [UnlinkedExpr.ints]) into a list (filled from the end) and take the next
   * `n` values from [UnlinkedExpr.strings] and use the lists of names and
   * values to create named arguments.  Then pop the top `m` values from the
   * stack (where `m` is obtained from [UnlinkedExpr.ints]) into a list (filled
   * from the end) and use them as positional arguments.  Use the lists of
   * positional and names arguments to invoke a constant constructor obtained
   * from [UnlinkedExpr.references], and push the resulting value back onto the
   * stack.
   *
   * Arguments are skipped, and `0` are specified as the numbers of arguments
   * on the stack, if the expression is not a constant. We store expression of
   * variable initializers to perform top-level inference, and arguments are
   * never used to infer types.
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
   * [UnlinkedExpr.ints]), place them in a [List], and push the result back
   * onto the stack.  The type parameter for the [List] is implicitly `dynamic`.
   */
  makeUntypedList,

  /**
   * Pop the top 2*n values from the stack (where n is obtained from
   * [UnlinkedExpr.ints]), interpret them as key/value pairs, place them in a
   * [Map], and push the result back onto the stack.  The two type parameters
   * for the [Map] are implicitly `dynamic`.
   */
  makeUntypedMap,

  /**
   * Pop the top n values from the stack (where n is obtained from
   * [UnlinkedExpr.ints]), place them in a [List], and push the result back
   * onto the stack.  The type parameter for the [List] is obtained from
   * [UnlinkedExpr.references].
   */
  makeTypedList,

  /**
   * Pop the top 2*n values from the stack (where n is obtained from
   * [UnlinkedExpr.ints]), interpret them as key/value pairs, place them in a
   * [Map], and push the result back onto the stack.  The two type parameters
   * for the [Map] are obtained from [UnlinkedExpr.references].
   */
  makeTypedMap,

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
   * Pop from the stack `value` and get the next `target` reference from
   * [UnlinkedExpr.references] - a top-level variable (prefixed or not), an
   * assignable field of a class (prefixed or not), or a sequence of getters
   * ending with an assignable property `a.b.b.c.d.e`.  In general `a.b` cannot
   * not be distinguished between: `a` is a prefix and `b` is a top-level
   * variable; or `a` is an object and `b` is the name of a property.  Perform
   * `reference op= value` where `op` is the next assignment operator from
   * [UnlinkedExpr.assignmentOperators].  Push `value` back into the stack.
   *
   * If the assignment operator is a prefix/postfix increment/decrement, then
   * `value` is not present in the stack, so it should not be popped and the
   * corresponding value of the `target` after/before update is pushed into the
   * stack instead.
   */
  assignToRef,

  /**
   * Pop from the stack `target` and `value`.  Get the name of the property from
   * `UnlinkedConst.strings` and assign the `value` to the named property of the
   * `target`.  This operation is used when we know that the `target` is an
   * object reference expression, e.g. `new Foo().a.b.c` or `a.b[0].c.d`.
   * Perform `target.property op= value` where `op` is the next assignment
   * operator from [UnlinkedExpr.assignmentOperators].  Push `value` back into
   * the stack.
   *
   * If the assignment operator is a prefix/postfix increment/decrement, then
   * `value` is not present in the stack, so it should not be popped and the
   * corresponding value of the `target` after/before update is pushed into the
   * stack instead.
   */
  assignToProperty,

  /**
   * Pop from the stack `index`, `target` and `value`.  Perform
   * `target[index] op= value`  where `op` is the next assignment operator from
   * [UnlinkedExpr.assignmentOperators].  Push `value` back into the stack.
   *
   * If the assignment operator is a prefix/postfix increment/decrement, then
   * `value` is not present in the stack, so it should not be popped and the
   * corresponding value of the `target` after/before update is pushed into the
   * stack instead.
   */
  assignToIndex,

  /**
   * Pop from the stack `index` and `target`.  Push into the stack the result
   * of evaluation of `target[index]`.
   */
  extractIndex,

  /**
   * Pop the top `n` values from the stack (where `n` is obtained from
   * [UnlinkedExpr.ints]) into a list (filled from the end) and take the next
   * `n` values from [UnlinkedExpr.strings] and use the lists of names and
   * values to create named arguments.  Then pop the top `m` values from the
   * stack (where `m` is obtained from [UnlinkedExpr.ints]) into a list (filled
   * from the end) and use them as positional arguments.  Use the lists of
   * positional and names arguments to invoke a method (or a function) with
   * the reference from [UnlinkedExpr.references].  If `k` is nonzero (where
   * `k` is obtained from [UnlinkedExpr.ints]), obtain `k` type arguments from
   * [UnlinkedExpr.references] and use them as generic type arguments for the
   * aforementioned method or function.  Push the result of the invocation onto
   * the stack.
   *
   * Arguments are skipped, and `0` are specified as the numbers of arguments
   * on the stack, if the expression is not a constant. We store expression of
   * variable initializers to perform top-level inference, and arguments are
   * never used to infer types.
   *
   * In general `a.b` cannot not be distinguished between: `a` is a prefix and
   * `b` is a top-level function; or `a` is an object and `b` is the name of a
   * method.  This operation should be used for a sequence of identifiers
   * `a.b.b.c.d.e` ending with an invokable result.
   */
  invokeMethodRef,

  /**
   * Pop the top `n` values from the stack (where `n` is obtained from
   * [UnlinkedExpr.ints]) into a list (filled from the end) and take the next
   * `n` values from [UnlinkedExpr.strings] and use the lists of names and
   * values to create named arguments.  Then pop the top `m` values from the
   * stack (where `m` is obtained from [UnlinkedExpr.ints]) into a list (filled
   * from the end) and use them as positional arguments.  Use the lists of
   * positional and names arguments to invoke the method with the name from
   * [UnlinkedExpr.strings] of the target popped from the stack.  If `k` is
   * nonzero (where `k` is obtained from [UnlinkedExpr.ints]), obtain `k` type
   * arguments from [UnlinkedExpr.references] and use them as generic type
   * arguments for the aforementioned method.  Push the result of the
   * invocation onto the stack.
   *
   * Arguments are skipped, and `0` are specified as the numbers of arguments
   * on the stack, if the expression is not a constant. We store expression of
   * variable initializers to perform top-level inference, and arguments are
   * never used to infer types.
   *
   * This operation should be used for invocation of a method invocation
   * where `target` is known to be an object instance.
   */
  invokeMethod,

  /**
   * Begin a new cascade section.  Duplicate the top value of the stack.
   */
  cascadeSectionBegin,

  /**
   * End a new cascade section.  Pop the top value from the stack and throw it
   * away.
   */
  cascadeSectionEnd,

  /**
   * Pop the top value from the stack and cast it to the type with reference
   * from [UnlinkedExpr.references], push the result into the stack.
   */
  typeCast,

  /**
   * Pop the top value from the stack and check whether it is a subclass of the
   * type with reference from [UnlinkedExpr.references], push the result into
   * the stack.
   */
  typeCheck,

  /**
   * Pop the top value from the stack and raise an exception with this value.
   */
  throwException,

  /**
   * Obtain two values `n` and `m` from [UnlinkedExpr.ints].  Then, starting at
   * the executable element for the expression being evaluated, if n > 0, pop to
   * the nth enclosing function element.  Then, push the mth local function of
   * that element onto the stack.
   */
  pushLocalFunctionReference,

  /**
   * Pop the top two values from the stack.  If the first value is non-null,
   * keep it and discard the second.  Otherwise, keep the second and discard the
   * first.
   */
  ifNull,

  /**
   * Pop the top value from the stack.  Treat it as a Future and await its
   * completion.  Then push the awaited value onto the stack.
   */
  await,

  /**
   * Push an abstract value onto the stack. Abstract values mark the presence of
   * a value, but whose details are not included.
   *
   * This is not used by the summary generators today, but it will be used to
   * experiment with prunning the initializer expression tree, so only
   * information that is necessary gets included in the output summary file.
   */
  pushUntypedAbstract,

  /**
   * Get the next type reference from [UnlinkedExpr.references] and push an
   * abstract value onto the stack that has that type.
   *
   * Like [pushUntypedAbstract], this is also not used by the summary generators
   * today. The plan is to experiment with prunning the initializer expression
   * tree, and include just enough type information to perform strong-mode type
   * inference, but not all the details of how this type was obtained.
   */
  pushTypedAbstract,

  /**
   * Push an error onto the stack.
   *
   * Like [pushUntypedAbstract], this is not used by summary generators today.
   * This will be used to experiment with prunning the const expression tree. If
   * a constant has an error, we can omit the subexpression containing the error
   * and only include a marker that an error was detected.
   */
  pushError,

  /**
   * Push `this` expression onto the stack.
   */
  pushThis,

  /**
   * Push `super` expression onto the stack.
   */
  pushSuper,
}

/**
 * Unlinked summary information about an import declaration.
 */
abstract class UnlinkedImport extends base.SummaryClass {
  /**
   * Annotations for this import declaration.
   */
  @Id(8)
  List<UnlinkedExpr> get annotations;

  /**
   * Combinators contained in this import declaration.
   */
  @Id(4)
  List<UnlinkedCombinator> get combinators;

  /**
   * Configurations used to control which library will actually be loaded at
   * run-time.
   */
  @Id(10)
  List<UnlinkedConfiguration> get configurations;

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  @Id(9)
  bool get isDeferred;

  /**
   * Indicates whether the import declaration is implicit.
   */
  @Id(5)
  bool get isImplicit;

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  @informative
  @Id(0)
  int get offset;

  /**
   * Offset of the prefix name relative to the beginning of the file, or zero
   * if there is no prefix.
   */
  @informative
  @Id(6)
  int get prefixOffset;

  /**
   * Index into [UnlinkedUnit.references] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  @Id(7)
  int get prefixReference;

  /**
   * URI used in the source code to reference the imported library.
   */
  @Id(1)
  String get uri;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  @informative
  @Id(2)
  int get uriEnd;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  @informative
  @Id(3)
  int get uriOffset;
}

/**
 * Unlinked summary information about a function parameter.
 */
abstract class UnlinkedParam extends base.SummaryClass {
  /**
   * Annotations for this parameter.
   */
  @Id(9)
  List<UnlinkedExpr> get annotations;

  /**
   * Code range of the parameter.
   */
  @informative
  @Id(7)
  CodeRange get codeRange;

  /**
   * If the parameter has a default value, the source text of the constant
   * expression in the default value.  Otherwise the empty string.
   */
  @informative
  @Id(13)
  String get defaultValueCode;

  /**
   * If this parameter's type is inferable, nonzero slot id identifying which
   * entry in [LinkedLibrary.types] contains the inferred type.  If there is no
   * matching entry in [LinkedLibrary.types], then no type was inferred for
   * this variable, so its static type is `dynamic`.
   *
   * Note that although strong mode considers initializing formals to be
   * inferable, they are not marked as such in the summary; if their type is
   * not specified, they always inherit the static type of the corresponding
   * field.
   */
  @Id(2)
  int get inferredTypeSlot;

  /**
   * If this is a parameter of an instance method, a nonzero slot id which is
   * unique within this compilation unit.  If this id is found in
   * [LinkedUnit.parametersInheritingCovariant], then this parameter inherits
   * `@covariant` behavior from a base class.
   *
   * Otherwise, zero.
   */
  @Id(14)
  int get inheritsCovariantSlot;

  /**
   * The synthetic initializer function of the parameter.  Absent if the
   * variable does not have an initializer.
   */
  @Id(12)
  UnlinkedExecutable get initializer;

  /**
   * Indicates whether this parameter is explicitly marked as being covariant.
   */
  @Id(15)
  bool get isExplicitlyCovariant;

  /**
   * Indicates whether the parameter is declared using the `final` keyword.
   */
  @Id(16)
  bool get isFinal;

  /**
   * Indicates whether this is a function-typed parameter. A parameter is
   * function-typed if the declaration of the parameter has explicit formal
   * parameters
   * ```
   * int functionTyped(int p)
   * ```
   * but is not function-typed if it does not, even if the type of the parameter
   * is a function type.
   */
  @Id(5)
  bool get isFunctionTyped;

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  @Id(6)
  bool get isInitializingFormal;

  /**
   * Kind of the parameter.
   */
  @Id(4)
  UnlinkedParamKind get kind;

  /**
   * Name of the parameter.
   */
  @Id(0)
  String get name;

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  @informative
  @Id(1)
  int get nameOffset;

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  @Id(8)
  List<UnlinkedParam> get parameters;

  /**
   * If [isFunctionTyped] is `true`, the declared return type.  If
   * [isFunctionTyped] is `false`, the declared type.  Absent if the type is
   * implicit.
   */
  @Id(3)
  EntityRef get type;

  /**
   * The length of the visible range.
   */
  @informative
  @Id(10)
  int get visibleLength;

  /**
   * The beginning of the visible range.
   */
  @informative
  @Id(11)
  int get visibleOffset;
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
   * Annotations for this part declaration.
   */
  @Id(2)
  List<UnlinkedExpr> get annotations;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  @informative
  @Id(0)
  int get uriEnd;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  @informative
  @Id(1)
  int get uriOffset;
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
   * The kind of object referred to by the name.
   */
  @Id(1)
  ReferenceKind get kind;

  /**
   * If this [UnlinkedPublicName] is a class, the list of members which can be
   * referenced statically - static fields, static methods, and constructors.
   * Otherwise empty.
   *
   * Unnamed constructors are not included since they do not constitute a
   * separate name added to any namespace.
   */
  @Id(2)
  List<UnlinkedPublicName> get members;

  /**
   * The name itself.
   */
  @Id(0)
  String get name;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  @Id(3)
  int get numTypeParameters;
}

/**
 * Unlinked summary information about what a compilation unit contributes to a
 * library's public namespace.  This is the subset of [UnlinkedUnit] that is
 * required from dependent libraries in order to perform prelinking.
 */
@TopLevel('UPNS')
abstract class UnlinkedPublicNamespace extends base.SummaryClass {
  factory UnlinkedPublicNamespace.fromBuffer(List<int> buffer) =>
      generated.readUnlinkedPublicNamespace(buffer);

  /**
   * Export declarations in the compilation unit.
   */
  @Id(2)
  List<UnlinkedExportPublic> get exports;

  /**
   * Public names defined in the compilation unit.
   *
   * TODO(paulberry): consider sorting these names to reduce unnecessary
   * relinking.
   */
  @Id(0)
  List<UnlinkedPublicName> get names;

  /**
   * URIs referenced by part declarations in the compilation unit.
   */
  @Id(1)
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
   * For the pseudo-type `bottom`, the string is "*bottom*".
   */
  @Id(0)
  String get name;

  /**
   * Prefix used to refer to the entity, or zero if no prefix is used.  This is
   * an index into [UnlinkedUnit.references].
   *
   * Prefix references must always point backward; that is, for all i, if
   * UnlinkedUnit.references[i].prefixReference != 0, then
   * UnlinkedUnit.references[i].prefixReference < i.
   */
  @Id(1)
  int get prefixReference;
}

/**
 * Unlinked summary information about a typedef declaration.
 */
abstract class UnlinkedTypedef extends base.SummaryClass {
  /**
   * Annotations for this typedef.
   */
  @Id(4)
  List<UnlinkedExpr> get annotations;

  /**
   * Code range of the typedef.
   */
  @informative
  @Id(7)
  CodeRange get codeRange;

  /**
   * Documentation comment for the typedef, or `null` if there is no
   * documentation comment.
   */
  @informative
  @Id(6)
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Name of the typedef.
   */
  @Id(0)
  String get name;

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  @informative
  @Id(1)
  int get nameOffset;

  /**
   * Parameters of the executable, if any.
   */
  @Id(3)
  List<UnlinkedParam> get parameters;

  /**
   * If [style] is [TypedefStyle.functionType], the return type of the typedef.
   * If [style] is [TypedefStyle.genericFunctionType], the function type being
   * defined.
   */
  @Id(2)
  EntityRef get returnType;

  /**
   * The style of the typedef.
   */
  @Id(8)
  TypedefStyle get style;

  /**
   * Type parameters of the typedef, if any.
   */
  @Id(5)
  List<UnlinkedTypeParam> get typeParameters;
}

/**
 * Unlinked summary information about a type parameter declaration.
 */
abstract class UnlinkedTypeParam extends base.SummaryClass {
  /**
   * Annotations for this type parameter.
   */
  @Id(3)
  List<UnlinkedExpr> get annotations;

  /**
   * Bound of the type parameter, if a bound is explicitly declared.  Otherwise
   * null.
   */
  @Id(2)
  EntityRef get bound;

  /**
   * Code range of the type parameter.
   */
  @informative
  @Id(4)
  CodeRange get codeRange;

  /**
   * Name of the type parameter.
   */
  @Id(0)
  String get name;

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  @informative
  @Id(1)
  int get nameOffset;
}

/**
 * Unlinked summary information about a compilation unit ("part file").
 */
@TopLevel('UUnt')
abstract class UnlinkedUnit extends base.SummaryClass {
  factory UnlinkedUnit.fromBuffer(List<int> buffer) =>
      generated.readUnlinkedUnit(buffer);

  /**
   * MD5 hash of the non-informative fields of the [UnlinkedUnit] (not
   * including this one) as 16 unsigned 8-bit integer values.  This can be used
   * to identify when the API of a unit may have changed.
   */
  @Id(19)
  List<int> get apiSignature;

  /**
   * Classes declared in the compilation unit.
   */
  @Id(2)
  List<UnlinkedClass> get classes;

  /**
   * Code range of the unit.
   */
  @informative
  @Id(15)
  CodeRange get codeRange;

  /**
   * Enums declared in the compilation unit.
   */
  @Id(12)
  List<UnlinkedEnum> get enums;

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  @Id(4)
  List<UnlinkedExecutable> get executables;

  /**
   * Export declarations in the compilation unit.
   */
  @Id(13)
  List<UnlinkedExportNonPublic> get exports;

  /**
   * If this compilation unit was summarized in fallback mode, the path where
   * the compilation unit may be found on disk.  Otherwise empty.
   *
   * When this field is non-empty, all other fields in the data structure have
   * their default values.
   */
  @deprecated
  @Id(16)
  String get fallbackModePath;

  /**
   * Import declarations in the compilation unit.
   */
  @Id(5)
  List<UnlinkedImport> get imports;

  /**
   * Indicates whether the unit contains a "part of" declaration.
   */
  @Id(18)
  bool get isPartOf;

  /**
   * Annotations for the library declaration, or the empty list if there is no
   * library declaration.
   */
  @Id(14)
  List<UnlinkedExpr> get libraryAnnotations;

  /**
   * Documentation comment for the library, or `null` if there is no
   * documentation comment.
   */
  @informative
  @Id(9)
  UnlinkedDocumentationComment get libraryDocumentationComment;

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  @Id(6)
  String get libraryName;

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  @informative
  @Id(7)
  int get libraryNameLength;

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  @informative
  @Id(8)
  int get libraryNameOffset;

  /**
   * Offsets of the first character of each line in the source code.
   */
  @informative
  @Id(17)
  List<int> get lineStarts;

  /**
   * Part declarations in the compilation unit.
   */
  @Id(11)
  List<UnlinkedPart> get parts;

  /**
   * Unlinked public namespace of this compilation unit.
   */
  @Id(0)
  UnlinkedPublicNamespace get publicNamespace;

  /**
   * Top level and prefixed names referred to by this compilation unit.  The
   * zeroth element of this array is always populated and is used to represent
   * the absence of a reference in places where a reference is optional (for
   * example [UnlinkedReference.prefixReference or
   * UnlinkedImport.prefixReference]).
   */
  @Id(1)
  List<UnlinkedReference> get references;

  /**
   * Typedefs declared in the compilation unit.
   */
  @Id(10)
  List<UnlinkedTypedef> get typedefs;

  /**
   * Top level variables declared in the compilation unit.
   */
  @Id(3)
  List<UnlinkedVariable> get variables;
}

/**
 * Unlinked summary information about a top level variable, local variable, or
 * a field.
 */
abstract class UnlinkedVariable extends base.SummaryClass {
  /**
   * Annotations for this variable.
   */
  @Id(8)
  List<UnlinkedExpr> get annotations;

  /**
   * Code range of the variable.
   */
  @informative
  @Id(5)
  CodeRange get codeRange;

  /**
   * Documentation comment for the variable, or `null` if there is no
   * documentation comment.
   */
  @informative
  @Id(10)
  UnlinkedDocumentationComment get documentationComment;

  /**
   * If this variable is inferable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the inferred type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then no type was
   * inferred for this variable, so its static type is `dynamic`.
   */
  @Id(9)
  int get inferredTypeSlot;

  /**
   * If this is an instance non-final field, a nonzero slot id which is unique
   * within this compilation unit.  If this id is found in
   * [LinkedUnit.parametersInheritingCovariant], then the parameter of the
   * synthetic setter inherits `@covariant` behavior from a base class.
   *
   * Otherwise, zero.
   */
  @Id(15)
  int get inheritsCovariantSlot;

  /**
   * The synthetic initializer function of the variable.  Absent if the variable
   * does not have an initializer.
   */
  @Id(13)
  UnlinkedExecutable get initializer;

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  @Id(6)
  bool get isConst;

  /**
   * Indicates whether this variable is declared using the `covariant` keyword.
   * This should be false for everything except instance fields.
   */
  @Id(14)
  bool get isCovariant;

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  @Id(7)
  bool get isFinal;

  /**
   * Indicates whether the variable is declared using the `static` keyword.
   *
   * Note that for top level variables, this flag is false, since they are not
   * declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  @Id(4)
  bool get isStatic;

  /**
   * Name of the variable.
   */
  @Id(0)
  String get name;

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  @informative
  @Id(1)
  int get nameOffset;

  /**
   * If this variable is propagable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the propagated type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then this variable's
   * propagated type is the same as its declared type.
   *
   * Non-propagable variables have a [propagatedTypeSlot] of zero.
   */
  @Id(2)
  int get propagatedTypeSlot;

  /**
   * Declared type of the variable.  Absent if the type is implicit.
   */
  @Id(3)
  EntityRef get type;

  /**
   * If a local variable, the length of the visible range; zero otherwise.
   */
  @deprecated
  @informative
  @Id(11)
  int get visibleLength;

  /**
   * If a local variable, the beginning of the visible range; zero otherwise.
   */
  @deprecated
  @informative
  @Id(12)
  int get visibleOffset;
}
