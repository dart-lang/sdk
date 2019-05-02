// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file is an "idl" style description of the summary format.  It
/// contains abstract classes which declare the interface for reading data from
/// summaries.  It is parsed and transformed into code that implements the
/// summary format.
///
/// The code generation process introduces the following semantics:
/// - Getters of type List never return null, and have a default value of the
///   empty list.
/// - Getters of type int return unsigned 32-bit integers, never null, and have
///   a default value of zero.
/// - Getters of type String never return null, and have a default value of ''.
/// - Getters of type bool never return null, and have a default value of false.
/// - Getters of type double never return null, and have a default value of
///   `0.0`.
/// - Getters whose type is an enum never return null, and have a default value
///   of the first value declared in the enum.
///
/// Terminology used in this document:
/// - "Unlinked" refers to information that can be determined from reading a
///   single .dart file in isolation.
/// - "Prelinked" refers to information that can be determined from the defining
///   compilation unit of a library, plus direct imports, plus the transitive
///   closure of exports reachable from those libraries, plus all part files
///   constituting those libraries.
/// - "Linked" refers to all other information; in theory, this information may
///   depend on all files in the transitive import/export closure.  However, in
///   practice we expect that the number of additional dependencies will usually
///   be small, since the additional dependencies only need to be consulted for
///   type propagation, type inference, and constant evaluation, which typically
///   have short dependency chains.
///
/// Since we expect "linked" and "prelinked" dependencies to be similar, we only
/// rarely distinguish between them; most information is that is not "unlinked"
/// is typically considered "linked" for simplicity.
///
/// Except as otherwise noted, synthetic elements are not stored in the summary;
/// they are re-synthesized at the time the summary is read.
import 'package:analyzer/dart/element/element.dart';

import 'base.dart' as base;
import 'base.dart' show Id, TopLevel, Variant, VariantId;
import 'format.dart' as generated;

/// Annotation describing information which is not part of Dart semantics; in
/// other words, if this information (or any information it refers to) changes,
/// static analysis and runtime behavior of the library are unaffected.
///
/// Information that has purely local effect (in other words, it does not affect
/// the API of the code being analyzed) is also marked as `informative`.
const informative = null;

/// Information about the context of an exception in analysis driver.
@TopLevel('ADEC')
abstract class AnalysisDriverExceptionContext extends base.SummaryClass {
  factory AnalysisDriverExceptionContext.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverExceptionContext(buffer);

  /// The exception string.
  @Id(1)
  String get exception;

  /// The state of files when the exception happened.
  @Id(3)
  List<AnalysisDriverExceptionFile> get files;

  /// The path of the file being analyzed when the exception happened.
  @Id(0)
  String get path;

  /// The exception stack trace string.
  @Id(2)
  String get stackTrace;
}

/// Information about a single file in [AnalysisDriverExceptionContext].
abstract class AnalysisDriverExceptionFile extends base.SummaryClass {
  /// The content of the file.
  @Id(1)
  String get content;

  /// The path of the file.
  @Id(0)
  String get path;
}

/// Information about a resolved unit.
@TopLevel('ADRU')
abstract class AnalysisDriverResolvedUnit extends base.SummaryClass {
  factory AnalysisDriverResolvedUnit.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverResolvedUnit(buffer);

  /// The full list of analysis errors, both syntactic and semantic.
  @Id(0)
  List<AnalysisDriverUnitError> get errors;

  /// The index of the unit.
  @Id(1)
  AnalysisDriverUnitIndex get index;
}

/// Information about a subtype of one or more classes.
abstract class AnalysisDriverSubtype extends base.SummaryClass {
  /// The names of defined instance members.
  /// They are indexes into [AnalysisDriverUnitError.strings] list.
  /// The list is sorted in ascending order.
  @Id(1)
  List<int> get members;

  /// The name of the class.
  /// It is an index into [AnalysisDriverUnitError.strings] list.
  @Id(0)
  int get name;
}

/// Information about an error in a resolved unit.
abstract class AnalysisDriverUnitError extends base.SummaryClass {
  /// The optional correction hint for the error.
  @Id(4)
  String get correction;

  /// The length of the error in the file.
  @Id(1)
  int get length;

  /// The message of the error.
  @Id(3)
  String get message;

  /// The offset from the beginning of the file.
  @Id(0)
  int get offset;

  /// The unique name of the error code.
  @Id(2)
  String get uniqueName;
}

/// Information about a resolved unit.
@TopLevel('ADUI')
abstract class AnalysisDriverUnitIndex extends base.SummaryClass {
  factory AnalysisDriverUnitIndex.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverUnitIndex(buffer);

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the kind of the synthetic element.
  @Id(4)
  List<IndexSyntheticElementKind> get elementKinds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the class member element name, or `null` if the element
  /// is a top-level element.  The list is sorted in ascending order, so that
  /// the client can quickly check whether an element is referenced in this
  /// index.
  @Id(7)
  List<int> get elementNameClassMemberIds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the named parameter name, or `null` if the element is
  /// not a named parameter.  The list is sorted in ascending order, so that the
  /// client can quickly check whether an element is referenced in this index.
  @Id(8)
  List<int> get elementNameParameterIds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the top-level element name, or `null` if the element is
  /// the unit.  The list is sorted in ascending order, so that the client can
  /// quickly check whether an element is referenced in this index.
  @Id(6)
  List<int> get elementNameUnitMemberIds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the index into [unitLibraryUris] and [unitUnitUris] for the library
  /// specific unit where the element is declared.
  @Id(5)
  List<int> get elementUnits;

  /// Identifier of the null string in [strings].
  @Id(1)
  int get nullStringId;

  /// List of unique element strings used in this index.  The list is sorted in
  /// ascending order, so that the client can quickly check the presence of a
  /// string in this index.
  @Id(0)
  List<String> get strings;

  /// The list of classes declared in the unit.
  @Id(19)
  List<AnalysisDriverSubtype> get subtypes;

  /// The identifiers of supertypes of elements at corresponding indexes
  /// in [subtypes].  They are indexes into [strings] list. The list is sorted
  /// in ascending order.  There might be more than one element with the same
  /// value if there is more than one subtype of this supertype.
  @Id(18)
  List<int> get supertypes;

  /// Each item of this list corresponds to the library URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  @Id(2)
  List<int> get unitLibraryUris;

  /// Each item of this list corresponds to the unit URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  @Id(3)
  List<int> get unitUnitUris;

  /// Each item of this list is the `true` if the corresponding element usage
  /// is qualified with some prefix.
  @Id(13)
  List<bool> get usedElementIsQualifiedFlags;

  /// Each item of this list is the kind of the element usage.
  @Id(10)
  List<IndexRelationKind> get usedElementKinds;

  /// Each item of this list is the length of the element usage.
  @Id(12)
  List<int> get usedElementLengths;

  /// Each item of this list is the offset of the element usage relative to the
  /// beginning of the file.
  @Id(11)
  List<int> get usedElementOffsets;

  /// Each item of this list is the index into [elementUnits],
  /// [elementNameUnitMemberIds], [elementNameClassMemberIds] and
  /// [elementNameParameterIds].  The list is sorted in ascending order, so
  /// that the client can quickly find element references in this index.
  @Id(9)
  List<int> get usedElements;

  /// Each item of this list is the `true` if the corresponding name usage
  /// is qualified with some prefix.
  @Id(17)
  List<bool> get usedNameIsQualifiedFlags;

  /// Each item of this list is the kind of the name usage.
  @Id(15)
  List<IndexRelationKind> get usedNameKinds;

  /// Each item of this list is the offset of the name usage relative to the
  /// beginning of the file.
  @Id(16)
  List<int> get usedNameOffsets;

  /// Each item of this list is the index into [strings] for a used name.  The
  /// list is sorted in ascending order, so that the client can quickly find
  /// whether a name is used in this index.
  @Id(14)
  List<int> get usedNames;
}

/// Information about an unlinked unit.
@TopLevel('ADUU')
abstract class AnalysisDriverUnlinkedUnit extends base.SummaryClass {
  factory AnalysisDriverUnlinkedUnit.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverUnlinkedUnit(buffer);

  /// List of class member names defined by the unit.
  @Id(3)
  List<String> get definedClassMemberNames;

  /// List of top-level names defined by the unit.
  @Id(2)
  List<String> get definedTopLevelNames;

  /// List of external names referenced by the unit.
  @Id(0)
  List<String> get referencedNames;

  /// List of names which are used in `extends`, `with` or `implements` clauses
  /// in the file. Import prefixes and type arguments are not included.
  @Id(4)
  List<String> get subtypedNames;

  /// Unlinked information for the unit.
  @Id(1)
  UnlinkedUnit get unit;

  /// Unlinked information for the unit.
  @Id(5)
  UnlinkedUnit2 get unit2;
}

/// Information about a single declaration.
abstract class AvailableDeclaration extends base.SummaryClass {
  @Id(0)
  List<AvailableDeclaration> get children;

  @Id(1)
  String get defaultArgumentListString;

  @Id(2)
  List<int> get defaultArgumentListTextRanges;

  @Id(3)
  String get docComplete;

  @Id(4)
  String get docSummary;

  @Id(5)
  int get fieldMask;

  @Id(6)
  bool get isAbstract;

  @Id(7)
  bool get isConst;

  @Id(8)
  bool get isDeprecated;

  @Id(9)
  bool get isFinal;

  /// The kind of the declaration.
  @Id(10)
  AvailableDeclarationKind get kind;

  @Id(11)
  int get locationOffset;

  @Id(12)
  int get locationStartColumn;

  @Id(13)
  int get locationStartLine;

  /// The first part of the declaration name, usually the only one, for example
  /// the name of a class like `MyClass`, or a function like `myFunction`.
  @Id(14)
  String get name;

  @Id(15)
  List<String> get parameterNames;

  @Id(16)
  String get parameters;

  @Id(17)
  List<String> get parameterTypes;

  /// The partial list of relevance tags.  Not every declaration has one (for
  /// example, function do not currently), and not every declaration has to
  /// store one (for classes it can be computed when we know the library that
  /// includes this file).
  @Id(18)
  List<String> get relevanceTags;

  @Id(19)
  int get requiredParameterCount;

  @Id(20)
  String get returnType;

  @Id(21)
  String get typeParameters;
}

/// Enum of declaration kinds in available files.
enum AvailableDeclarationKind {
  CLASS,
  CLASS_TYPE_ALIAS,
  CONSTRUCTOR,
  ENUM,
  ENUM_CONSTANT,
  FUNCTION,
  FUNCTION_TYPE_ALIAS,
  GETTER,
  MIXIN,
  SETTER,
  VARIABLE
}

/// Information about an available, even if not yet imported file.
@TopLevel('UICF')
abstract class AvailableFile extends base.SummaryClass {
  factory AvailableFile.fromBuffer(List<int> buffer) =>
      generated.readAvailableFile(buffer);

  /// Declarations of the file.
  @Id(0)
  List<AvailableDeclaration> get declarations;

  /// The Dartdoc directives in the file.
  @Id(5)
  DirectiveInfo get directiveInfo;

  /// Exports directives of the file.
  @Id(1)
  List<AvailableFileExport> get exports;

  /// Is `true` if this file is a library.
  @Id(2)
  bool get isLibrary;

  /// Is `true` if this file is a library, and it is deprecated.
  @Id(3)
  bool get isLibraryDeprecated;

  /// URIs of `part` directives.
  @Id(4)
  List<String> get parts;
}

/// Information about an export directive.
abstract class AvailableFileExport extends base.SummaryClass {
  /// Combinators contained in this export directive.
  @Id(1)
  List<AvailableFileExportCombinator> get combinators;

  /// URI of the exported library.
  @Id(0)
  String get uri;
}

/// Information about a `show` or `hide` combinator in an export directive.
abstract class AvailableFileExportCombinator extends base.SummaryClass {
  /// List of names which are hidden.  Empty if this is a `show` combinator.
  @Id(1)
  List<String> get hides;

  /// List of names which are shown.  Empty if this is a `hide` combinator.
  @Id(0)
  List<String> get shows;
}

/// Information about an element code range.
abstract class CodeRange extends base.SummaryClass {
  /// Length of the element code.
  @Id(1)
  int get length;

  /// Offset of the element code relative to the beginning of the file.
  @Id(0)
  int get offset;
}

/// Information about the Dartdoc directives in an [AvailableFile].
abstract class DirectiveInfo extends base.SummaryClass {
  /// The names of the defined templates.
  @Id(0)
  List<String> get templateNames;

  /// The values of the defined templates.
  @Id(1)
  List<String> get templateValues;
}

/// Summary information about a reference to an entity such as a type, top level
/// executable, or executable within a class.
abstract class EntityRef extends base.SummaryClass {
  /// The kind of entity being represented.
  @Id(8)
  EntityRefKind get entityKind;

  /// Notice: This will be deprecated. However, its not deprecated yet, as we're
  /// keeping it for backwards compatibilty, and marking it deprecated makes it
  /// unreadable.
  ///
  /// TODO(mfairhurst) mark this deprecated, and remove its logic.
  ///
  /// If this is a reference to a function type implicitly defined by a
  /// function-typed parameter, a list of zero-based indices indicating the path
  /// from the entity referred to by [reference] to the appropriate type
  /// parameter.  Otherwise the empty list.
  ///
  /// If there are N indices in this list, then the entity being referred to is
  /// the function type implicitly defined by a function-typed parameter of a
  /// function-typed parameter, to N levels of nesting.  The first index in the
  /// list refers to the outermost level of nesting; for example if [reference]
  /// refers to the entity defined by:
  ///
  ///     void f(x, void g(y, z, int h(String w))) { ... }
  ///
  /// Then to refer to the function type implicitly defined by parameter `h`
  /// (which is parameter 2 of parameter 1 of `f`), then
  /// [implicitFunctionTypeIndices] should be [1, 2].
  ///
  /// Note that if the entity being referred to is a generic method inside a
  /// generic class, then the type arguments in [typeArguments] are applied
  /// first to the class and then to the method.
  @Id(4)
  List<int> get implicitFunctionTypeIndices;

  /// If the reference represents a type, the nullability of the type.
  @Id(10)
  EntityRefNullabilitySuffix get nullabilitySuffix;

  /// If this is a reference to a type parameter, one-based index into the list
  /// of [UnlinkedTypeParam]s currently in effect.  Indexing is done using De
  /// Bruijn index conventions; that is, innermost parameters come first, and
  /// if a class or method has multiple parameters, they are indexed from right
  /// to left.  So for instance, if the enclosing declaration is
  ///
  ///     class C<T,U> {
  ///       m<V,W> {
  ///         ...
  ///       }
  ///     }
  ///
  /// Then [paramReference] values of 1, 2, 3, and 4 represent W, V, U, and T,
  /// respectively.
  ///
  /// If the type being referred to is not a type parameter, [paramReference] is
  /// zero.
  @Id(3)
  int get paramReference;

  /// Index into [UnlinkedUnit.references] for the entity being referred to, or
  /// zero if this is a reference to a type parameter.
  @Id(0)
  int get reference;

  /// If this [EntityRef] appears in a syntactic context where its type
  /// arguments might need to be inferred by a method other than
  /// instantiate-to-bounds, and [typeArguments] is empty, a slot id (which is
  /// unique within the compilation unit).  If an entry appears in
  /// [LinkedUnit.types] whose [slot] matches this value, that entry will
  /// contain the complete inferred type.
  ///
  /// This is called `refinedSlot` to clarify that if it points to an inferred
  /// type, it points to a type that is a "refinement" of this one (one in which
  /// some type arguments have been inferred).
  @Id(9)
  int get refinedSlot;

  /// If this [EntityRef] is contained within [LinkedUnit.types], slot id (which
  /// is unique within the compilation unit) identifying the target of type
  /// propagation or type inference with which this [EntityRef] is associated.
  ///
  /// Otherwise zero.
  @Id(2)
  int get slot;

  /// If this [EntityRef] is a reference to a function type whose
  /// [FunctionElement] is not in any library (e.g. a function type that was
  /// synthesized by a LUB computation), the function parameters.  Otherwise
  /// empty.
  @Id(6)
  List<UnlinkedParam> get syntheticParams;

  /// If this [EntityRef] is a reference to a function type whose
  /// [FunctionElement] is not in any library (e.g. a function type that was
  /// synthesized by a LUB computation), the return type of the function.
  /// Otherwise `null`.
  @Id(5)
  EntityRef get syntheticReturnType;

  /// If this is an instantiation of a generic type or generic executable, the
  /// type arguments used to instantiate it (if any).
  @Id(1)
  List<EntityRef> get typeArguments;

  /// If this is a function type, the type parameters defined for the function
  /// type (if any).
  @Id(7)
  List<UnlinkedTypeParam> get typeParameters;
}

/// Enum used to indicate the kind of an entity reference.
enum EntityRefKind {
  /// The entity represents a named type.
  named,

  /// The entity represents a generic function type.
  genericFunctionType,

  /// The entity represents a function type that was synthesized by a LUB
  /// computation.
  syntheticFunction
}

/// Enum representing nullability suffixes in summaries.
///
/// This enum is similar to [NullabilitySuffix], but the order is different so
/// that [EntityRefNullabilitySuffix.starOrIrrelevant] can be the default.
enum EntityRefNullabilitySuffix {
  /// An indication that the canonical representation of the type under
  /// consideration ends with `*`.  Types having this nullability suffix are
  /// called "legacy types"; it has not yet been determined whether they should
  /// be unioned with the Null type.
  ///
  /// Also used in circumstances where no nullability suffix information is
  /// needed.
  starOrIrrelevant,

  /// An indication that the canonical representation of the type under
  /// consideration ends with `?`.  Types having this nullability suffix should
  /// be interpreted as being unioned with the Null type.
  question,

  /// An indication that the canonical representation of the type under
  /// consideration does not end with either `?` or `*`.
  none,
}

/// Enum used to indicate the kind of a name in index.
enum IndexNameKind {
  /// A top-level element.
  topLevel,

  /// A class member.
  classMember
}

/// Enum used to indicate the kind of an index relation.
enum IndexRelationKind {
  /// Left: class.
  ///   Is ancestor of (is extended or implemented, directly or indirectly).
  /// Right: other class declaration.
  IS_ANCESTOR_OF,

  /// Left: class.
  ///   Is extended by.
  /// Right: other class declaration.
  IS_EXTENDED_BY,

  /// Left: class.
  ///   Is implemented by.
  /// Right: other class declaration.
  IS_IMPLEMENTED_BY,

  /// Left: class.
  ///   Is mixed into.
  /// Right: other class declaration.
  IS_MIXED_IN_BY,

  /// Left: method, property accessor, function, variable.
  ///   Is invoked at.
  /// Right: location.
  IS_INVOKED_BY,

  /// Left: any element.
  ///   Is referenced (and not invoked, read/written) at.
  /// Right: location.
  IS_REFERENCED_BY,

  /// Left: unresolved member name.
  ///   Is read at.
  /// Right: location.
  IS_READ_BY,

  /// Left: unresolved member name.
  ///   Is both read and written at.
  /// Right: location.
  IS_READ_WRITTEN_BY,

  /// Left: unresolved member name.
  ///   Is written at.
  /// Right: location.
  IS_WRITTEN_BY
}

/// When we need to reference a synthetic element in [PackageIndex] we use a
/// value of this enum to specify which kind of the synthetic element we
/// actually reference.
enum IndexSyntheticElementKind {
  /// Not a synthetic element.
  notSynthetic,

  /// The unnamed synthetic constructor a class element.
  constructor,

  /// The synthetic field element.
  field,

  /// The synthetic getter of a property introducing element.
  getter,

  /// The synthetic setter of a property introducing element.
  setter,

  /// The synthetic top-level variable element.
  topLevelVariable,

  /// The synthetic `loadLibrary` element.
  loadLibrary,

  /// The synthetic `index` getter of an enum.
  enumIndex,

  /// The synthetic `values` getter of an enum.
  enumValues,

  /// The synthetic `toString` method of an enum.
  enumToString,

  /// The containing unit itself.
  unit
}

/// Information about a dependency that exists between one library and another
/// due to an "import" declaration.
abstract class LinkedDependency extends base.SummaryClass {
  /// Absolute URI for the compilation units listed in the library's `part`
  /// declarations, empty string for invalid URI.
  @Id(1)
  List<String> get parts;

  /// The absolute URI of the dependent library, e.g. `package:foo/bar.dart`.
  @Id(0)
  String get uri;
}

/// Information about a single name in the export namespace of the library that
/// is not in the public namespace.
abstract class LinkedExportName extends base.SummaryClass {
  /// Index into [LinkedLibrary.dependencies] for the library in which the
  /// entity is defined.
  @Id(0)
  int get dependency;

  /// The kind of the entity being referred to.
  @Id(3)
  ReferenceKind get kind;

  /// Name of the exported entity.  For an exported setter, this name includes
  /// the trailing '='.
  @Id(1)
  String get name;

  /// Integer index indicating which unit in the exported library contains the
  /// definition of the entity.  As with indices into [LinkedLibrary.units],
  /// zero represents the defining compilation unit, and nonzero values
  /// represent parts in the order of the corresponding `part` declarations.
  @Id(2)
  int get unit;
}

/// Linked summary of a library.
@TopLevel('LLib')
abstract class LinkedLibrary extends base.SummaryClass {
  factory LinkedLibrary.fromBuffer(List<int> buffer) =>
      generated.readLinkedLibrary(buffer);

  /// The libraries that this library depends on (either via an explicit import
  /// statement or via the implicit dependencies on `dart:core` and
  /// `dart:async`).  The first element of this array is a pseudo-dependency
  /// representing the library itself (it is also used for `dynamic` and
  /// `void`).  This is followed by elements representing "prelinked"
  /// dependencies (direct imports and the transitive closure of exports).
  /// After the prelinked dependencies are elements representing "linked"
  /// dependencies.
  ///
  /// A library is only included as a "linked" dependency if it is a true
  /// dependency (e.g. a propagated or inferred type or constant value
  /// implicitly refers to an element declared in the library) or
  /// anti-dependency (e.g. the result of type propagation or type inference
  /// depends on the lack of a certain declaration in the library).
  @Id(0)
  List<LinkedDependency> get dependencies;

  /// For each export in [UnlinkedUnit.exports], an index into [dependencies]
  /// of the library being exported.
  @Id(6)
  List<int> get exportDependencies;

  /// Information about entities in the export namespace of the library that are
  /// not in the public namespace of the library (that is, entities that are
  /// brought into the namespace via `export` directives).
  ///
  /// Sorted by name.
  @Id(4)
  List<LinkedExportName> get exportNames;

  /// Indicates whether this library was summarized in "fallback mode".  If
  /// true, all other fields in the data structure have their default values.
  @deprecated
  @Id(5)
  bool get fallbackMode;

  /// For each import in [UnlinkedUnit.imports], an index into [dependencies]
  /// of the library being imported.
  @Id(1)
  List<int> get importDependencies;

  /// The number of elements in [dependencies] which are not "linked"
  /// dependencies (that is, the number of libraries in the direct imports plus
  /// the transitive closure of exports, plus the library itself).
  @Id(2)
  int get numPrelinkedDependencies;

  /// The linked summary of all the compilation units constituting the
  /// library.  The summary of the defining compilation unit is listed first,
  /// followed by the summary of each part, in the order of the `part`
  /// declarations in the defining compilation unit.
  @Id(3)
  List<LinkedUnit> get units;
}

/// Information about a linked AST node.
@Variant('kind')
abstract class LinkedNode extends base.SummaryClass {
  /// The explicit or inferred return type of a function typed node.
  @VariantId(24, variantList: [
    LinkedNodeKind.functionDeclaration,
    LinkedNodeKind.functionExpression,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericFunctionType,
    LinkedNodeKind.methodDeclaration,
  ])
  LinkedNodeType get actualReturnType;

  /// The explicit or inferred type of a variable.
  @VariantId(24, variantList: [
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.simpleFormalParameter,
    LinkedNodeKind.variableDeclaration,
  ])
  LinkedNodeType get actualType;

  @VariantId(2, variant: LinkedNodeKind.adjacentStrings)
  List<LinkedNode> get adjacentStrings_strings;

  @VariantId(11, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.declaredIdentifier,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.enumConstantDeclaration,
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.fieldDeclaration,
    LinkedNodeKind.functionDeclaration,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
    LinkedNodeKind.importDirective,
    LinkedNodeKind.libraryDirective,
    LinkedNodeKind.methodDeclaration,
    LinkedNodeKind.mixinDeclaration,
    LinkedNodeKind.partDirective,
    LinkedNodeKind.partOfDirective,
    LinkedNodeKind.topLevelVariableDeclaration,
    LinkedNodeKind.typeParameter,
    LinkedNodeKind.variableDeclaration,
    LinkedNodeKind.variableDeclarationList,
  ])
  LinkedNode get annotatedNode_comment;

  @VariantId(4, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.declaredIdentifier,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.enumConstantDeclaration,
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.fieldDeclaration,
    LinkedNodeKind.functionDeclaration,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
    LinkedNodeKind.importDirective,
    LinkedNodeKind.libraryDirective,
    LinkedNodeKind.methodDeclaration,
    LinkedNodeKind.mixinDeclaration,
    LinkedNodeKind.partDirective,
    LinkedNodeKind.partOfDirective,
    LinkedNodeKind.topLevelVariableDeclaration,
    LinkedNodeKind.typeParameter,
    LinkedNodeKind.variableDeclaration,
    LinkedNodeKind.variableDeclarationList,
  ])
  List<LinkedNode> get annotatedNode_metadata;

  @VariantId(6, variant: LinkedNodeKind.annotation)
  LinkedNode get annotation_arguments;

  @VariantId(15, variant: LinkedNodeKind.annotation)
  int get annotation_atSign;

  @VariantId(7, variant: LinkedNodeKind.annotation)
  LinkedNode get annotation_constructorName;

  @VariantId(17, variant: LinkedNodeKind.annotation)
  int get annotation_element;

  @VariantId(23, variant: LinkedNodeKind.annotation)
  LinkedNodeType get annotation_elementType;

  @VariantId(8, variant: LinkedNodeKind.annotation)
  LinkedNode get annotation_name;

  @VariantId(16, variant: LinkedNodeKind.annotation)
  int get annotation_period;

  @VariantId(2, variant: LinkedNodeKind.argumentList)
  List<LinkedNode> get argumentList_arguments;

  @VariantId(15, variant: LinkedNodeKind.argumentList)
  int get argumentList_leftParenthesis;

  @VariantId(16, variant: LinkedNodeKind.argumentList)
  int get argumentList_rightParenthesis;

  @VariantId(15, variant: LinkedNodeKind.asExpression)
  int get asExpression_asOperator;

  @VariantId(6, variant: LinkedNodeKind.asExpression)
  LinkedNode get asExpression_expression;

  @VariantId(7, variant: LinkedNodeKind.asExpression)
  LinkedNode get asExpression_type;

  @VariantId(15, variant: LinkedNodeKind.assertInitializer)
  int get assertInitializer_assertKeyword;

  @VariantId(16, variant: LinkedNodeKind.assertInitializer)
  int get assertInitializer_comma;

  @VariantId(6, variant: LinkedNodeKind.assertInitializer)
  LinkedNode get assertInitializer_condition;

  @VariantId(17, variant: LinkedNodeKind.assertInitializer)
  int get assertInitializer_leftParenthesis;

  @VariantId(7, variant: LinkedNodeKind.assertInitializer)
  LinkedNode get assertInitializer_message;

  @VariantId(18, variant: LinkedNodeKind.assertInitializer)
  int get assertInitializer_rightParenthesis;

  @VariantId(15, variant: LinkedNodeKind.assertStatement)
  int get assertStatement_assertKeyword;

  @VariantId(16, variant: LinkedNodeKind.assertStatement)
  int get assertStatement_comma;

  @VariantId(6, variant: LinkedNodeKind.assertStatement)
  LinkedNode get assertStatement_condition;

  @VariantId(17, variant: LinkedNodeKind.assertStatement)
  int get assertStatement_leftParenthesis;

  @VariantId(7, variant: LinkedNodeKind.assertStatement)
  LinkedNode get assertStatement_message;

  @VariantId(18, variant: LinkedNodeKind.assertStatement)
  int get assertStatement_rightParenthesis;

  @VariantId(19, variant: LinkedNodeKind.assertStatement)
  int get assertStatement_semicolon;

  @VariantId(15, variant: LinkedNodeKind.assignmentExpression)
  int get assignmentExpression_element;

  @VariantId(23, variant: LinkedNodeKind.assignmentExpression)
  LinkedNodeType get assignmentExpression_elementType;

  @VariantId(6, variant: LinkedNodeKind.assignmentExpression)
  LinkedNode get assignmentExpression_leftHandSide;

  @VariantId(16, variant: LinkedNodeKind.assignmentExpression)
  int get assignmentExpression_operator;

  @VariantId(7, variant: LinkedNodeKind.assignmentExpression)
  LinkedNode get assignmentExpression_rightHandSide;

  @VariantId(15, variant: LinkedNodeKind.awaitExpression)
  int get awaitExpression_awaitKeyword;

  @VariantId(6, variant: LinkedNodeKind.awaitExpression)
  LinkedNode get awaitExpression_expression;

  @VariantId(15, variant: LinkedNodeKind.binaryExpression)
  int get binaryExpression_element;

  @VariantId(23, variant: LinkedNodeKind.binaryExpression)
  LinkedNodeType get binaryExpression_elementType;

  @VariantId(24, variant: LinkedNodeKind.binaryExpression)
  LinkedNodeType get binaryExpression_invokeType;

  @VariantId(6, variant: LinkedNodeKind.binaryExpression)
  LinkedNode get binaryExpression_leftOperand;

  @VariantId(16, variant: LinkedNodeKind.binaryExpression)
  int get binaryExpression_operator;

  @VariantId(7, variant: LinkedNodeKind.binaryExpression)
  LinkedNode get binaryExpression_rightOperand;

  @VariantId(15, variant: LinkedNodeKind.block)
  int get block_leftBracket;

  @VariantId(16, variant: LinkedNodeKind.block)
  int get block_rightBracket;

  @VariantId(2, variant: LinkedNodeKind.block)
  List<LinkedNode> get block_statements;

  @VariantId(6, variant: LinkedNodeKind.blockFunctionBody)
  LinkedNode get blockFunctionBody_block;

  @VariantId(15, variant: LinkedNodeKind.blockFunctionBody)
  int get blockFunctionBody_keyword;

  @VariantId(16, variant: LinkedNodeKind.blockFunctionBody)
  int get blockFunctionBody_star;

  @VariantId(15, variant: LinkedNodeKind.booleanLiteral)
  int get booleanLiteral_literal;

  @VariantId(27, variant: LinkedNodeKind.booleanLiteral)
  bool get booleanLiteral_value;

  @VariantId(15, variant: LinkedNodeKind.breakStatement)
  int get breakStatement_breakKeyword;

  @VariantId(6, variant: LinkedNodeKind.breakStatement)
  LinkedNode get breakStatement_label;

  @VariantId(16, variant: LinkedNodeKind.breakStatement)
  int get breakStatement_semicolon;

  @VariantId(2, variant: LinkedNodeKind.cascadeExpression)
  List<LinkedNode> get cascadeExpression_sections;

  @VariantId(6, variant: LinkedNodeKind.cascadeExpression)
  LinkedNode get cascadeExpression_target;

  @VariantId(6, variant: LinkedNodeKind.catchClause)
  LinkedNode get catchClause_body;

  @VariantId(15, variant: LinkedNodeKind.catchClause)
  int get catchClause_catchKeyword;

  @VariantId(16, variant: LinkedNodeKind.catchClause)
  int get catchClause_comma;

  @VariantId(7, variant: LinkedNodeKind.catchClause)
  LinkedNode get catchClause_exceptionParameter;

  @VariantId(8, variant: LinkedNodeKind.catchClause)
  LinkedNode get catchClause_exceptionType;

  @VariantId(17, variant: LinkedNodeKind.catchClause)
  int get catchClause_leftParenthesis;

  @VariantId(18, variant: LinkedNodeKind.catchClause)
  int get catchClause_onKeyword;

  @VariantId(19, variant: LinkedNodeKind.catchClause)
  int get catchClause_rightParenthesis;

  @VariantId(9, variant: LinkedNodeKind.catchClause)
  LinkedNode get catchClause_stackTraceParameter;

  @VariantId(15, variant: LinkedNodeKind.classDeclaration)
  int get classDeclaration_abstractKeyword;

  @VariantId(16, variant: LinkedNodeKind.classDeclaration)
  int get classDeclaration_classKeyword;

  @VariantId(6, variant: LinkedNodeKind.classDeclaration)
  LinkedNode get classDeclaration_extendsClause;

  @VariantId(27, variant: LinkedNodeKind.classDeclaration)
  bool get classDeclaration_isDartObject;

  @VariantId(8, variant: LinkedNodeKind.classDeclaration)
  LinkedNode get classDeclaration_nativeClause;

  @VariantId(7, variant: LinkedNodeKind.classDeclaration)
  LinkedNode get classDeclaration_withClause;

  @VariantId(12, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.mixinDeclaration,
  ])
  LinkedNode get classOrMixinDeclaration_implementsClause;

  @VariantId(19, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.mixinDeclaration,
  ])
  int get classOrMixinDeclaration_leftBracket;

  @VariantId(5, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.mixinDeclaration,
  ])
  List<LinkedNode> get classOrMixinDeclaration_members;

  @VariantId(18, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.mixinDeclaration,
  ])
  int get classOrMixinDeclaration_rightBracket;

  @VariantId(13, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.mixinDeclaration,
  ])
  LinkedNode get classOrMixinDeclaration_typeParameters;

  @VariantId(15, variant: LinkedNodeKind.classTypeAlias)
  int get classTypeAlias_abstractKeyword;

  @VariantId(16, variant: LinkedNodeKind.classTypeAlias)
  int get classTypeAlias_equals;

  @VariantId(9, variant: LinkedNodeKind.classTypeAlias)
  LinkedNode get classTypeAlias_implementsClause;

  @VariantId(7, variant: LinkedNodeKind.classTypeAlias)
  LinkedNode get classTypeAlias_superclass;

  @VariantId(6, variant: LinkedNodeKind.classTypeAlias)
  LinkedNode get classTypeAlias_typeParameters;

  @VariantId(8, variant: LinkedNodeKind.classTypeAlias)
  LinkedNode get classTypeAlias_withClause;

  @VariantId(34, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.compilationUnit,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.defaultFormalParameter,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionDeclaration,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.genericTypeAlias,
    LinkedNodeKind.methodDeclaration,
    LinkedNodeKind.mixinDeclaration,
    LinkedNodeKind.simpleFormalParameter,
    LinkedNodeKind.typeParameter,
    LinkedNodeKind.variableDeclaration,
  ])
  int get codeLength;

  @VariantId(33, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.compilationUnit,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.defaultFormalParameter,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionDeclaration,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.genericTypeAlias,
    LinkedNodeKind.methodDeclaration,
    LinkedNodeKind.mixinDeclaration,
    LinkedNodeKind.simpleFormalParameter,
    LinkedNodeKind.typeParameter,
    LinkedNodeKind.variableDeclaration,
  ])
  int get codeOffset;

  @VariantId(19, variantList: [
    LinkedNodeKind.hideCombinator,
    LinkedNodeKind.showCombinator,
  ])
  int get combinator_keyword;

  @VariantId(2, variant: LinkedNodeKind.comment)
  List<LinkedNode> get comment_references;

  @VariantId(28, variant: LinkedNodeKind.comment)
  List<int> get comment_tokens;

  @VariantId(29, variant: LinkedNodeKind.comment)
  LinkedNodeCommentType get comment_type;

  @VariantId(6, variant: LinkedNodeKind.commentReference)
  LinkedNode get commentReference_identifier;

  @VariantId(15, variant: LinkedNodeKind.commentReference)
  int get commentReference_newKeyword;

  @VariantId(15, variant: LinkedNodeKind.compilationUnit)
  int get compilationUnit_beginToken;

  @VariantId(2, variant: LinkedNodeKind.compilationUnit)
  List<LinkedNode> get compilationUnit_declarations;

  @VariantId(3, variant: LinkedNodeKind.compilationUnit)
  List<LinkedNode> get compilationUnit_directives;

  @VariantId(16, variant: LinkedNodeKind.compilationUnit)
  int get compilationUnit_endToken;

  @VariantId(6, variant: LinkedNodeKind.compilationUnit)
  LinkedNode get compilationUnit_scriptTag;

  @VariantId(15, variant: LinkedNodeKind.conditionalExpression)
  int get conditionalExpression_colon;

  @VariantId(6, variant: LinkedNodeKind.conditionalExpression)
  LinkedNode get conditionalExpression_condition;

  @VariantId(7, variant: LinkedNodeKind.conditionalExpression)
  LinkedNode get conditionalExpression_elseExpression;

  @VariantId(16, variant: LinkedNodeKind.conditionalExpression)
  int get conditionalExpression_question;

  @VariantId(8, variant: LinkedNodeKind.conditionalExpression)
  LinkedNode get conditionalExpression_thenExpression;

  @VariantId(18, variant: LinkedNodeKind.configuration)
  int get configuration_equalToken;

  @VariantId(15, variant: LinkedNodeKind.configuration)
  int get configuration_ifKeyword;

  @VariantId(16, variant: LinkedNodeKind.configuration)
  int get configuration_leftParenthesis;

  @VariantId(6, variant: LinkedNodeKind.configuration)
  LinkedNode get configuration_name;

  @VariantId(17, variant: LinkedNodeKind.configuration)
  int get configuration_rightParenthesis;

  @VariantId(8, variant: LinkedNodeKind.configuration)
  LinkedNode get configuration_uri;

  @VariantId(7, variant: LinkedNodeKind.configuration)
  LinkedNode get configuration_value;

  @VariantId(6, variant: LinkedNodeKind.constructorDeclaration)
  LinkedNode get constructorDeclaration_body;

  @VariantId(15, variant: LinkedNodeKind.constructorDeclaration)
  int get constructorDeclaration_constKeyword;

  @VariantId(16, variant: LinkedNodeKind.constructorDeclaration)
  int get constructorDeclaration_externalKeyword;

  @VariantId(17, variant: LinkedNodeKind.constructorDeclaration)
  int get constructorDeclaration_factoryKeyword;

  @VariantId(2, variant: LinkedNodeKind.constructorDeclaration)
  List<LinkedNode> get constructorDeclaration_initializers;

  @VariantId(7, variant: LinkedNodeKind.constructorDeclaration)
  LinkedNode get constructorDeclaration_name;

  @VariantId(8, variant: LinkedNodeKind.constructorDeclaration)
  LinkedNode get constructorDeclaration_parameters;

  @VariantId(18, variant: LinkedNodeKind.constructorDeclaration)
  int get constructorDeclaration_period;

  @VariantId(9, variant: LinkedNodeKind.constructorDeclaration)
  LinkedNode get constructorDeclaration_redirectedConstructor;

  @VariantId(10, variant: LinkedNodeKind.constructorDeclaration)
  LinkedNode get constructorDeclaration_returnType;

  @VariantId(19, variant: LinkedNodeKind.constructorDeclaration)
  int get constructorDeclaration_separator;

  @VariantId(15, variant: LinkedNodeKind.constructorFieldInitializer)
  int get constructorFieldInitializer_equals;

  @VariantId(6, variant: LinkedNodeKind.constructorFieldInitializer)
  LinkedNode get constructorFieldInitializer_expression;

  @VariantId(7, variant: LinkedNodeKind.constructorFieldInitializer)
  LinkedNode get constructorFieldInitializer_fieldName;

  @VariantId(16, variant: LinkedNodeKind.constructorFieldInitializer)
  int get constructorFieldInitializer_period;

  @VariantId(17, variant: LinkedNodeKind.constructorFieldInitializer)
  int get constructorFieldInitializer_thisKeyword;

  @VariantId(15, variant: LinkedNodeKind.constructorName)
  int get constructorName_element;

  @VariantId(23, variant: LinkedNodeKind.constructorName)
  LinkedNodeType get constructorName_elementType;

  @VariantId(6, variant: LinkedNodeKind.constructorName)
  LinkedNode get constructorName_name;

  @VariantId(16, variant: LinkedNodeKind.constructorName)
  int get constructorName_period;

  @VariantId(7, variant: LinkedNodeKind.constructorName)
  LinkedNode get constructorName_type;

  @VariantId(15, variant: LinkedNodeKind.continueStatement)
  int get continueStatement_continueKeyword;

  @VariantId(6, variant: LinkedNodeKind.continueStatement)
  LinkedNode get continueStatement_label;

  @VariantId(16, variant: LinkedNodeKind.continueStatement)
  int get continueStatement_semicolon;

  @VariantId(6, variant: LinkedNodeKind.declaredIdentifier)
  LinkedNode get declaredIdentifier_identifier;

  @VariantId(15, variant: LinkedNodeKind.declaredIdentifier)
  int get declaredIdentifier_keyword;

  @VariantId(7, variant: LinkedNodeKind.declaredIdentifier)
  LinkedNode get declaredIdentifier_type;

  @VariantId(6, variant: LinkedNodeKind.defaultFormalParameter)
  LinkedNode get defaultFormalParameter_defaultValue;

  @VariantId(26, variant: LinkedNodeKind.defaultFormalParameter)
  LinkedNodeFormalParameterKind get defaultFormalParameter_kind;

  @VariantId(7, variant: LinkedNodeKind.defaultFormalParameter)
  LinkedNode get defaultFormalParameter_parameter;

  @VariantId(15, variant: LinkedNodeKind.defaultFormalParameter)
  int get defaultFormalParameter_separator;

  @VariantId(18, variantList: [
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.importDirective,
    LinkedNodeKind.libraryDirective,
    LinkedNodeKind.partDirective,
    LinkedNodeKind.partOfDirective,
  ])
  int get directive_keyword;

  @VariantId(33, variantList: [
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.importDirective,
    LinkedNodeKind.libraryDirective,
    LinkedNodeKind.partDirective,
    LinkedNodeKind.partOfDirective,
  ])
  int get directive_semicolon;

  @VariantId(6, variant: LinkedNodeKind.doStatement)
  LinkedNode get doStatement_body;

  @VariantId(7, variant: LinkedNodeKind.doStatement)
  LinkedNode get doStatement_condition;

  @VariantId(17, variant: LinkedNodeKind.doStatement)
  int get doStatement_doKeyword;

  @VariantId(15, variant: LinkedNodeKind.doStatement)
  int get doStatement_leftParenthesis;

  @VariantId(16, variant: LinkedNodeKind.doStatement)
  int get doStatement_rightParenthesis;

  @VariantId(18, variant: LinkedNodeKind.doStatement)
  int get doStatement_semicolon;

  @VariantId(19, variant: LinkedNodeKind.doStatement)
  int get doStatement_whileKeyword;

  @VariantId(2, variant: LinkedNodeKind.dottedName)
  List<LinkedNode> get dottedName_components;

  @VariantId(15, variant: LinkedNodeKind.doubleLiteral)
  int get doubleLiteral_literal;

  @VariantId(21, variant: LinkedNodeKind.doubleLiteral)
  double get doubleLiteral_value;

  @VariantId(15, variant: LinkedNodeKind.emptyFunctionBody)
  int get emptyFunctionBody_semicolon;

  @VariantId(15, variant: LinkedNodeKind.emptyStatement)
  int get emptyStatement_semicolon;

  @VariantId(6, variant: LinkedNodeKind.enumConstantDeclaration)
  LinkedNode get enumConstantDeclaration_name;

  @VariantId(2, variant: LinkedNodeKind.enumDeclaration)
  List<LinkedNode> get enumDeclaration_constants;

  @VariantId(15, variant: LinkedNodeKind.enumDeclaration)
  int get enumDeclaration_enumKeyword;

  @VariantId(16, variant: LinkedNodeKind.enumDeclaration)
  int get enumDeclaration_leftBracket;

  @VariantId(17, variant: LinkedNodeKind.enumDeclaration)
  int get enumDeclaration_rightBracket;

  @VariantId(25, variantList: [
    LinkedNodeKind.adjacentStrings,
    LinkedNodeKind.assignmentExpression,
    LinkedNodeKind.asExpression,
    LinkedNodeKind.awaitExpression,
    LinkedNodeKind.binaryExpression,
    LinkedNodeKind.booleanLiteral,
    LinkedNodeKind.cascadeExpression,
    LinkedNodeKind.conditionalExpression,
    LinkedNodeKind.doubleLiteral,
    LinkedNodeKind.functionExpressionInvocation,
    LinkedNodeKind.indexExpression,
    LinkedNodeKind.instanceCreationExpression,
    LinkedNodeKind.integerLiteral,
    LinkedNodeKind.isExpression,
    LinkedNodeKind.listLiteral,
    LinkedNodeKind.methodInvocation,
    LinkedNodeKind.namedExpression,
    LinkedNodeKind.nullLiteral,
    LinkedNodeKind.parenthesizedExpression,
    LinkedNodeKind.prefixExpression,
    LinkedNodeKind.prefixedIdentifier,
    LinkedNodeKind.propertyAccess,
    LinkedNodeKind.postfixExpression,
    LinkedNodeKind.rethrowExpression,
    LinkedNodeKind.setOrMapLiteral,
    LinkedNodeKind.simpleIdentifier,
    LinkedNodeKind.simpleStringLiteral,
    LinkedNodeKind.stringInterpolation,
    LinkedNodeKind.superExpression,
    LinkedNodeKind.symbolLiteral,
    LinkedNodeKind.thisExpression,
    LinkedNodeKind.throwExpression,
  ])
  LinkedNodeType get expression_type;

  @VariantId(15, variant: LinkedNodeKind.expressionFunctionBody)
  int get expressionFunctionBody_arrow;

  @VariantId(6, variant: LinkedNodeKind.expressionFunctionBody)
  LinkedNode get expressionFunctionBody_expression;

  @VariantId(16, variant: LinkedNodeKind.expressionFunctionBody)
  int get expressionFunctionBody_keyword;

  @VariantId(17, variant: LinkedNodeKind.expressionFunctionBody)
  int get expressionFunctionBody_semicolon;

  @VariantId(6, variant: LinkedNodeKind.expressionStatement)
  LinkedNode get expressionStatement_expression;

  @VariantId(15, variant: LinkedNodeKind.expressionStatement)
  int get expressionStatement_semicolon;

  @VariantId(15, variant: LinkedNodeKind.extendsClause)
  int get extendsClause_extendsKeyword;

  @VariantId(6, variant: LinkedNodeKind.extendsClause)
  LinkedNode get extendsClause_superclass;

  @VariantId(15, variant: LinkedNodeKind.fieldDeclaration)
  int get fieldDeclaration_covariantKeyword;

  @VariantId(6, variant: LinkedNodeKind.fieldDeclaration)
  LinkedNode get fieldDeclaration_fields;

  @VariantId(16, variant: LinkedNodeKind.fieldDeclaration)
  int get fieldDeclaration_semicolon;

  @VariantId(17, variant: LinkedNodeKind.fieldDeclaration)
  int get fieldDeclaration_staticKeyword;

  @VariantId(8, variant: LinkedNodeKind.fieldFormalParameter)
  LinkedNode get fieldFormalParameter_formalParameters;

  @VariantId(15, variant: LinkedNodeKind.fieldFormalParameter)
  int get fieldFormalParameter_keyword;

  @VariantId(16, variant: LinkedNodeKind.fieldFormalParameter)
  int get fieldFormalParameter_period;

  @VariantId(17, variant: LinkedNodeKind.fieldFormalParameter)
  int get fieldFormalParameter_thisKeyword;

  @VariantId(6, variant: LinkedNodeKind.fieldFormalParameter)
  LinkedNode get fieldFormalParameter_type;

  @VariantId(7, variant: LinkedNodeKind.fieldFormalParameter)
  LinkedNode get fieldFormalParameter_typeParameters;

  @VariantId(15, variantList: [
    LinkedNodeKind.forEachPartsWithDeclaration,
    LinkedNodeKind.forEachPartsWithIdentifier,
  ])
  int get forEachParts_inKeyword;

  @VariantId(6, variantList: [
    LinkedNodeKind.forEachPartsWithDeclaration,
    LinkedNodeKind.forEachPartsWithIdentifier,
  ])
  LinkedNode get forEachParts_iterable;

  @VariantId(7, variant: LinkedNodeKind.forEachPartsWithDeclaration)
  LinkedNode get forEachPartsWithDeclaration_loopVariable;

  @VariantId(7, variant: LinkedNodeKind.forEachPartsWithIdentifier)
  LinkedNode get forEachPartsWithIdentifier_identifier;

  @VariantId(7, variant: LinkedNodeKind.forElement)
  LinkedNode get forElement_body;

  @VariantId(15, variant: LinkedNodeKind.formalParameterList)
  int get formalParameterList_leftDelimiter;

  @VariantId(16, variant: LinkedNodeKind.formalParameterList)
  int get formalParameterList_leftParenthesis;

  @VariantId(2, variant: LinkedNodeKind.formalParameterList)
  List<LinkedNode> get formalParameterList_parameters;

  @VariantId(17, variant: LinkedNodeKind.formalParameterList)
  int get formalParameterList_rightDelimiter;

  @VariantId(18, variant: LinkedNodeKind.formalParameterList)
  int get formalParameterList_rightParenthesis;

  @VariantId(15, variantList: [
    LinkedNodeKind.forElement,
    LinkedNodeKind.forStatement,
  ])
  int get forMixin_awaitKeyword;

  @VariantId(16, variantList: [
    LinkedNodeKind.forElement,
    LinkedNodeKind.forStatement,
  ])
  int get forMixin_forKeyword;

  @VariantId(6, variantList: [
    LinkedNodeKind.forElement,
    LinkedNodeKind.forStatement,
  ])
  LinkedNode get forMixin_forLoopParts;

  @VariantId(17, variantList: [
    LinkedNodeKind.forElement,
    LinkedNodeKind.forStatement,
  ])
  int get forMixin_leftParenthesis;

  @VariantId(19, variantList: [
    LinkedNodeKind.forElement,
    LinkedNodeKind.forStatement,
  ])
  int get forMixin_rightParenthesis;

  @VariantId(6, variantList: [
    LinkedNodeKind.forPartsWithDeclarations,
    LinkedNodeKind.forPartsWithExpression,
  ])
  LinkedNode get forParts_condition;

  @VariantId(15, variantList: [
    LinkedNodeKind.forPartsWithDeclarations,
    LinkedNodeKind.forPartsWithExpression,
  ])
  int get forParts_leftSeparator;

  @VariantId(16, variantList: [
    LinkedNodeKind.forPartsWithDeclarations,
    LinkedNodeKind.forPartsWithExpression,
  ])
  int get forParts_rightSeparator;

  @VariantId(5, variantList: [
    LinkedNodeKind.forPartsWithDeclarations,
    LinkedNodeKind.forPartsWithExpression,
  ])
  List<LinkedNode> get forParts_updaters;

  @VariantId(7, variant: LinkedNodeKind.forPartsWithDeclarations)
  LinkedNode get forPartsWithDeclarations_variables;

  @VariantId(7, variant: LinkedNodeKind.forPartsWithExpression)
  LinkedNode get forPartsWithExpression_initialization;

  @VariantId(7, variant: LinkedNodeKind.forStatement)
  LinkedNode get forStatement_body;

  @VariantId(15, variant: LinkedNodeKind.functionDeclaration)
  int get functionDeclaration_externalKeyword;

  @VariantId(6, variant: LinkedNodeKind.functionDeclaration)
  LinkedNode get functionDeclaration_functionExpression;

  @VariantId(16, variant: LinkedNodeKind.functionDeclaration)
  int get functionDeclaration_propertyKeyword;

  @VariantId(7, variant: LinkedNodeKind.functionDeclaration)
  LinkedNode get functionDeclaration_returnType;

  @VariantId(6, variant: LinkedNodeKind.functionDeclarationStatement)
  LinkedNode get functionDeclarationStatement_functionDeclaration;

  @VariantId(6, variant: LinkedNodeKind.functionExpression)
  LinkedNode get functionExpression_body;

  @VariantId(7, variant: LinkedNodeKind.functionExpression)
  LinkedNode get functionExpression_formalParameters;

  @VariantId(8, variant: LinkedNodeKind.functionExpression)
  LinkedNode get functionExpression_typeParameters;

  @VariantId(6, variant: LinkedNodeKind.functionExpressionInvocation)
  LinkedNode get functionExpressionInvocation_function;

  @VariantId(6, variant: LinkedNodeKind.functionTypeAlias)
  LinkedNode get functionTypeAlias_formalParameters;

  @VariantId(7, variant: LinkedNodeKind.functionTypeAlias)
  LinkedNode get functionTypeAlias_returnType;

  @VariantId(8, variant: LinkedNodeKind.functionTypeAlias)
  LinkedNode get functionTypeAlias_typeParameters;

  @VariantId(6, variant: LinkedNodeKind.functionTypedFormalParameter)
  LinkedNode get functionTypedFormalParameter_formalParameters;

  @VariantId(7, variant: LinkedNodeKind.functionTypedFormalParameter)
  LinkedNode get functionTypedFormalParameter_returnType;

  @VariantId(8, variant: LinkedNodeKind.functionTypedFormalParameter)
  LinkedNode get functionTypedFormalParameter_typeParameters;

  @VariantId(8, variant: LinkedNodeKind.genericFunctionType)
  LinkedNode get genericFunctionType_formalParameters;

  @VariantId(15, variant: LinkedNodeKind.genericFunctionType)
  int get genericFunctionType_functionKeyword;

  @VariantId(17, variant: LinkedNodeKind.genericFunctionType)
  int get genericFunctionType_id;

  @VariantId(16, variant: LinkedNodeKind.genericFunctionType)
  int get genericFunctionType_question;

  @VariantId(7, variant: LinkedNodeKind.genericFunctionType)
  LinkedNode get genericFunctionType_returnType;

  @VariantId(25, variant: LinkedNodeKind.genericFunctionType)
  LinkedNodeType get genericFunctionType_type;

  @VariantId(6, variant: LinkedNodeKind.genericFunctionType)
  LinkedNode get genericFunctionType_typeParameters;

  @VariantId(16, variant: LinkedNodeKind.genericTypeAlias)
  int get genericTypeAlias_equals;

  @VariantId(7, variant: LinkedNodeKind.genericTypeAlias)
  LinkedNode get genericTypeAlias_functionType;

  @VariantId(6, variant: LinkedNodeKind.genericTypeAlias)
  LinkedNode get genericTypeAlias_typeParameters;

  @VariantId(2, variant: LinkedNodeKind.hideCombinator)
  List<LinkedNode> get hideCombinator_hiddenNames;

  @VariantId(9, variant: LinkedNodeKind.ifElement)
  LinkedNode get ifElement_elseElement;

  @VariantId(8, variant: LinkedNodeKind.ifElement)
  LinkedNode get ifElement_thenElement;

  @VariantId(6, variantList: [
    LinkedNodeKind.ifElement,
    LinkedNodeKind.ifStatement,
  ])
  LinkedNode get ifMixin_condition;

  @VariantId(15, variantList: [
    LinkedNodeKind.ifElement,
    LinkedNodeKind.ifStatement,
  ])
  int get ifMixin_elseKeyword;

  @VariantId(16, variantList: [
    LinkedNodeKind.ifElement,
    LinkedNodeKind.ifStatement,
  ])
  int get ifMixin_ifKeyword;

  @VariantId(17, variantList: [
    LinkedNodeKind.ifElement,
    LinkedNodeKind.ifStatement,
  ])
  int get ifMixin_leftParenthesis;

  @VariantId(18, variantList: [
    LinkedNodeKind.ifElement,
    LinkedNodeKind.ifStatement,
  ])
  int get ifMixin_rightParenthesis;

  @VariantId(7, variant: LinkedNodeKind.ifStatement)
  LinkedNode get ifStatement_elseStatement;

  @VariantId(8, variant: LinkedNodeKind.ifStatement)
  LinkedNode get ifStatement_thenStatement;

  @VariantId(15, variant: LinkedNodeKind.implementsClause)
  int get implementsClause_implementsKeyword;

  @VariantId(2, variant: LinkedNodeKind.implementsClause)
  List<LinkedNode> get implementsClause_interfaces;

  @VariantId(15, variant: LinkedNodeKind.importDirective)
  int get importDirective_asKeyword;

  @VariantId(16, variant: LinkedNodeKind.importDirective)
  int get importDirective_deferredKeyword;

  @VariantId(6, variant: LinkedNodeKind.importDirective)
  LinkedNode get importDirective_prefix;

  @VariantId(15, variant: LinkedNodeKind.indexExpression)
  int get indexExpression_element;

  @VariantId(23, variant: LinkedNodeKind.indexExpression)
  LinkedNodeType get indexExpression_elementType;

  @VariantId(6, variant: LinkedNodeKind.indexExpression)
  LinkedNode get indexExpression_index;

  @VariantId(17, variant: LinkedNodeKind.indexExpression)
  int get indexExpression_leftBracket;

  @VariantId(16, variant: LinkedNodeKind.indexExpression)
  int get indexExpression_period;

  @VariantId(18, variant: LinkedNodeKind.indexExpression)
  int get indexExpression_rightBracket;

  @VariantId(7, variant: LinkedNodeKind.indexExpression)
  LinkedNode get indexExpression_target;

  @VariantId(27, variantList: [
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.simpleFormalParameter,
    LinkedNodeKind.variableDeclaration,
  ])
  bool get inheritsCovariant;

  @VariantId(6, variant: LinkedNodeKind.instanceCreationExpression)
  LinkedNode get instanceCreationExpression_arguments;

  @VariantId(7, variant: LinkedNodeKind.instanceCreationExpression)
  LinkedNode get instanceCreationExpression_constructorName;

  @VariantId(15, variant: LinkedNodeKind.instanceCreationExpression)
  int get instanceCreationExpression_keyword;

  @VariantId(8, variant: LinkedNodeKind.instanceCreationExpression)
  LinkedNode get instanceCreationExpression_typeArguments;

  @VariantId(15, variant: LinkedNodeKind.integerLiteral)
  int get integerLiteral_literal;

  @VariantId(16, variant: LinkedNodeKind.integerLiteral)
  int get integerLiteral_value;

  @VariantId(6, variant: LinkedNodeKind.interpolationExpression)
  LinkedNode get interpolationExpression_expression;

  @VariantId(15, variant: LinkedNodeKind.interpolationExpression)
  int get interpolationExpression_leftBracket;

  @VariantId(16, variant: LinkedNodeKind.interpolationExpression)
  int get interpolationExpression_rightBracket;

  @VariantId(15, variant: LinkedNodeKind.interpolationString)
  int get interpolationString_token;

  @VariantId(30, variant: LinkedNodeKind.interpolationString)
  String get interpolationString_value;

  @VariantId(14, variantList: [
    LinkedNodeKind.functionExpressionInvocation,
    LinkedNodeKind.methodInvocation,
  ])
  LinkedNode get invocationExpression_arguments;

  @VariantId(24, variantList: [
    LinkedNodeKind.functionExpressionInvocation,
    LinkedNodeKind.methodInvocation,
  ])
  LinkedNodeType get invocationExpression_invokeType;

  @VariantId(12, variantList: [
    LinkedNodeKind.functionExpressionInvocation,
    LinkedNodeKind.methodInvocation,
  ])
  LinkedNode get invocationExpression_typeArguments;

  @VariantId(6, variant: LinkedNodeKind.isExpression)
  LinkedNode get isExpression_expression;

  @VariantId(15, variant: LinkedNodeKind.isExpression)
  int get isExpression_isOperator;

  @VariantId(16, variant: LinkedNodeKind.isExpression)
  int get isExpression_notOperator;

  @VariantId(7, variant: LinkedNodeKind.isExpression)
  LinkedNode get isExpression_type;

  @Id(1)
  bool get isSynthetic;

  @Id(0)
  LinkedNodeKind get kind;

  @VariantId(15, variant: LinkedNodeKind.label)
  int get label_colon;

  @VariantId(6, variant: LinkedNodeKind.label)
  LinkedNode get label_label;

  @VariantId(2, variant: LinkedNodeKind.labeledStatement)
  List<LinkedNode> get labeledStatement_labels;

  @VariantId(6, variant: LinkedNodeKind.labeledStatement)
  LinkedNode get labeledStatement_statement;

  @VariantId(6, variant: LinkedNodeKind.libraryDirective)
  LinkedNode get libraryDirective_name;

  @VariantId(2, variant: LinkedNodeKind.libraryIdentifier)
  List<LinkedNode> get libraryIdentifier_components;

  @VariantId(2, variant: LinkedNodeKind.listLiteral)
  List<LinkedNode> get listLiteral_elements;

  @VariantId(15, variant: LinkedNodeKind.listLiteral)
  int get listLiteral_leftBracket;

  @VariantId(16, variant: LinkedNodeKind.listLiteral)
  int get listLiteral_rightBracket;

  @VariantId(6, variant: LinkedNodeKind.mapLiteralEntry)
  LinkedNode get mapLiteralEntry_key;

  @VariantId(15, variant: LinkedNodeKind.mapLiteralEntry)
  int get mapLiteralEntry_separator;

  @VariantId(7, variant: LinkedNodeKind.mapLiteralEntry)
  LinkedNode get mapLiteralEntry_value;

  @VariantId(19, variant: LinkedNodeKind.methodDeclaration)
  int get methodDeclaration_actualProperty;

  @VariantId(6, variant: LinkedNodeKind.methodDeclaration)
  LinkedNode get methodDeclaration_body;

  @VariantId(15, variant: LinkedNodeKind.methodDeclaration)
  int get methodDeclaration_externalKeyword;

  @VariantId(7, variant: LinkedNodeKind.methodDeclaration)
  LinkedNode get methodDeclaration_formalParameters;

  @VariantId(16, variant: LinkedNodeKind.methodDeclaration)
  int get methodDeclaration_modifierKeyword;

  @VariantId(10, variant: LinkedNodeKind.methodDeclaration)
  LinkedNode get methodDeclaration_name;

  @VariantId(17, variant: LinkedNodeKind.methodDeclaration)
  int get methodDeclaration_operatorKeyword;

  @VariantId(18, variant: LinkedNodeKind.methodDeclaration)
  int get methodDeclaration_propertyKeyword;

  @VariantId(8, variant: LinkedNodeKind.methodDeclaration)
  LinkedNode get methodDeclaration_returnType;

  @VariantId(9, variant: LinkedNodeKind.methodDeclaration)
  LinkedNode get methodDeclaration_typeParameters;

  @VariantId(6, variant: LinkedNodeKind.methodInvocation)
  LinkedNode get methodInvocation_methodName;

  @VariantId(15, variant: LinkedNodeKind.methodInvocation)
  int get methodInvocation_operator;

  @VariantId(7, variant: LinkedNodeKind.methodInvocation)
  LinkedNode get methodInvocation_target;

  @VariantId(15, variant: LinkedNodeKind.mixinDeclaration)
  int get mixinDeclaration_mixinKeyword;

  @VariantId(6, variant: LinkedNodeKind.mixinDeclaration)
  LinkedNode get mixinDeclaration_onClause;

  @VariantId(36, variant: LinkedNodeKind.mixinDeclaration)
  List<String> get mixinDeclaration_superInvokedNames;

  @VariantId(14, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.functionDeclaration,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
    LinkedNodeKind.mixinDeclaration,
  ])
  LinkedNode get namedCompilationUnitMember_name;

  @VariantId(6, variant: LinkedNodeKind.namedExpression)
  LinkedNode get namedExpression_expression;

  @VariantId(7, variant: LinkedNodeKind.namedExpression)
  LinkedNode get namedExpression_name;

  @VariantId(2, variantList: [
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.importDirective,
  ])
  List<LinkedNode> get namespaceDirective_combinators;

  @VariantId(3, variantList: [
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.importDirective,
  ])
  List<LinkedNode> get namespaceDirective_configurations;

  @VariantId(20, variantList: [
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.importDirective,
  ])
  String get namespaceDirective_selectedUri;

  @VariantId(6, variant: LinkedNodeKind.nativeClause)
  LinkedNode get nativeClause_name;

  @VariantId(15, variant: LinkedNodeKind.nativeClause)
  int get nativeClause_nativeKeyword;

  @VariantId(15, variant: LinkedNodeKind.nativeFunctionBody)
  int get nativeFunctionBody_nativeKeyword;

  @VariantId(16, variant: LinkedNodeKind.nativeFunctionBody)
  int get nativeFunctionBody_semicolon;

  @VariantId(6, variant: LinkedNodeKind.nativeFunctionBody)
  LinkedNode get nativeFunctionBody_stringLiteral;

  @VariantId(14, variantList: [
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.simpleFormalParameter,
  ])
  LinkedNode get normalFormalParameter_comment;

  @VariantId(19, variantList: [
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.simpleFormalParameter,
  ])
  int get normalFormalParameter_covariantKeyword;

  @VariantId(12, variantList: [
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.simpleFormalParameter,
  ])
  LinkedNode get normalFormalParameter_identifier;

  @VariantId(4, variantList: [
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.simpleFormalParameter,
  ])
  List<LinkedNode> get normalFormalParameter_metadata;

  @VariantId(18, variantList: [
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.simpleFormalParameter,
  ])
  int get normalFormalParameter_requiredKeyword;

  @VariantId(15, variant: LinkedNodeKind.nullLiteral)
  int get nullLiteral_literal;

  @VariantId(15, variant: LinkedNodeKind.onClause)
  int get onClause_onKeyword;

  @VariantId(2, variant: LinkedNodeKind.onClause)
  List<LinkedNode> get onClause_superclassConstraints;

  @VariantId(6, variant: LinkedNodeKind.parenthesizedExpression)
  LinkedNode get parenthesizedExpression_expression;

  @VariantId(15, variant: LinkedNodeKind.parenthesizedExpression)
  int get parenthesizedExpression_leftParenthesis;

  @VariantId(16, variant: LinkedNodeKind.parenthesizedExpression)
  int get parenthesizedExpression_rightParenthesis;

  @VariantId(6, variant: LinkedNodeKind.partOfDirective)
  LinkedNode get partOfDirective_libraryName;

  @VariantId(16, variant: LinkedNodeKind.partOfDirective)
  int get partOfDirective_ofKeyword;

  @VariantId(7, variant: LinkedNodeKind.partOfDirective)
  LinkedNode get partOfDirective_uri;

  @VariantId(15, variant: LinkedNodeKind.postfixExpression)
  int get postfixExpression_element;

  @VariantId(23, variant: LinkedNodeKind.postfixExpression)
  LinkedNodeType get postfixExpression_elementType;

  @VariantId(6, variant: LinkedNodeKind.postfixExpression)
  LinkedNode get postfixExpression_operand;

  @VariantId(16, variant: LinkedNodeKind.postfixExpression)
  int get postfixExpression_operator;

  @VariantId(6, variant: LinkedNodeKind.prefixedIdentifier)
  LinkedNode get prefixedIdentifier_identifier;

  @VariantId(15, variant: LinkedNodeKind.prefixedIdentifier)
  int get prefixedIdentifier_period;

  @VariantId(7, variant: LinkedNodeKind.prefixedIdentifier)
  LinkedNode get prefixedIdentifier_prefix;

  @VariantId(15, variant: LinkedNodeKind.prefixExpression)
  int get prefixExpression_element;

  @VariantId(23, variant: LinkedNodeKind.prefixExpression)
  LinkedNodeType get prefixExpression_elementType;

  @VariantId(6, variant: LinkedNodeKind.prefixExpression)
  LinkedNode get prefixExpression_operand;

  @VariantId(16, variant: LinkedNodeKind.prefixExpression)
  int get prefixExpression_operator;

  @VariantId(15, variant: LinkedNodeKind.propertyAccess)
  int get propertyAccess_operator;

  @VariantId(6, variant: LinkedNodeKind.propertyAccess)
  LinkedNode get propertyAccess_propertyName;

  @VariantId(7, variant: LinkedNodeKind.propertyAccess)
  LinkedNode get propertyAccess_target;

  @VariantId(6, variant: LinkedNodeKind.redirectingConstructorInvocation)
  LinkedNode get redirectingConstructorInvocation_arguments;

  @VariantId(7, variant: LinkedNodeKind.redirectingConstructorInvocation)
  LinkedNode get redirectingConstructorInvocation_constructorName;

  @VariantId(15, variant: LinkedNodeKind.redirectingConstructorInvocation)
  int get redirectingConstructorInvocation_element;

  @VariantId(23, variant: LinkedNodeKind.redirectingConstructorInvocation)
  LinkedNodeType get redirectingConstructorInvocation_elementType;

  @VariantId(16, variant: LinkedNodeKind.redirectingConstructorInvocation)
  int get redirectingConstructorInvocation_period;

  @VariantId(17, variant: LinkedNodeKind.redirectingConstructorInvocation)
  int get redirectingConstructorInvocation_thisKeyword;

  @VariantId(15, variant: LinkedNodeKind.rethrowExpression)
  int get rethrowExpression_rethrowKeyword;

  @VariantId(6, variant: LinkedNodeKind.returnStatement)
  LinkedNode get returnStatement_expression;

  @VariantId(15, variant: LinkedNodeKind.returnStatement)
  int get returnStatement_returnKeyword;

  @VariantId(16, variant: LinkedNodeKind.returnStatement)
  int get returnStatement_semicolon;

  @VariantId(15, variant: LinkedNodeKind.scriptTag)
  int get scriptTag_scriptTag;

  @VariantId(2, variant: LinkedNodeKind.setOrMapLiteral)
  List<LinkedNode> get setOrMapLiteral_elements;

  @VariantId(27, variant: LinkedNodeKind.setOrMapLiteral)
  bool get setOrMapLiteral_isMap;

  @VariantId(31, variant: LinkedNodeKind.setOrMapLiteral)
  bool get setOrMapLiteral_isSet;

  @VariantId(15, variant: LinkedNodeKind.setOrMapLiteral)
  int get setOrMapLiteral_leftBracket;

  @VariantId(16, variant: LinkedNodeKind.setOrMapLiteral)
  int get setOrMapLiteral_rightBracket;

  @VariantId(2, variant: LinkedNodeKind.showCombinator)
  List<LinkedNode> get showCombinator_shownNames;

  @VariantId(15, variant: LinkedNodeKind.simpleFormalParameter)
  int get simpleFormalParameter_keyword;

  @VariantId(6, variant: LinkedNodeKind.simpleFormalParameter)
  LinkedNode get simpleFormalParameter_type;

  @VariantId(15, variant: LinkedNodeKind.simpleIdentifier)
  int get simpleIdentifier_element;

  @VariantId(23, variant: LinkedNodeKind.simpleIdentifier)
  LinkedNodeType get simpleIdentifier_elementType;

  @VariantId(27, variant: LinkedNodeKind.simpleIdentifier)
  bool get simpleIdentifier_isDeclaration;

  @VariantId(16, variant: LinkedNodeKind.simpleIdentifier)
  int get simpleIdentifier_token;

  @VariantId(15, variant: LinkedNodeKind.simpleStringLiteral)
  int get simpleStringLiteral_token;

  @VariantId(20, variant: LinkedNodeKind.simpleStringLiteral)
  String get simpleStringLiteral_value;

  @VariantId(31, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
    LinkedNodeKind.mixinDeclaration,
  ])
  bool get simplyBoundable_isSimplyBounded;

  @VariantId(6, variant: LinkedNodeKind.spreadElement)
  LinkedNode get spreadElement_expression;

  @VariantId(15, variant: LinkedNodeKind.spreadElement)
  int get spreadElement_spreadOperator;

  @VariantId(2, variant: LinkedNodeKind.stringInterpolation)
  List<LinkedNode> get stringInterpolation_elements;

  @VariantId(6, variant: LinkedNodeKind.superConstructorInvocation)
  LinkedNode get superConstructorInvocation_arguments;

  @VariantId(7, variant: LinkedNodeKind.superConstructorInvocation)
  LinkedNode get superConstructorInvocation_constructorName;

  @VariantId(15, variant: LinkedNodeKind.superConstructorInvocation)
  int get superConstructorInvocation_element;

  @VariantId(23, variant: LinkedNodeKind.superConstructorInvocation)
  LinkedNodeType get superConstructorInvocation_elementType;

  @VariantId(16, variant: LinkedNodeKind.superConstructorInvocation)
  int get superConstructorInvocation_period;

  @VariantId(17, variant: LinkedNodeKind.superConstructorInvocation)
  int get superConstructorInvocation_superKeyword;

  @VariantId(15, variant: LinkedNodeKind.superExpression)
  int get superExpression_superKeyword;

  @VariantId(6, variant: LinkedNodeKind.switchCase)
  LinkedNode get switchCase_expression;

  @VariantId(16, variantList: [
    LinkedNodeKind.switchCase,
    LinkedNodeKind.switchDefault,
  ])
  int get switchMember_colon;

  @VariantId(15, variantList: [
    LinkedNodeKind.switchCase,
    LinkedNodeKind.switchDefault,
  ])
  int get switchMember_keyword;

  @VariantId(3, variantList: [
    LinkedNodeKind.switchCase,
    LinkedNodeKind.switchDefault,
  ])
  List<LinkedNode> get switchMember_labels;

  @VariantId(4, variantList: [
    LinkedNodeKind.switchCase,
    LinkedNodeKind.switchDefault,
  ])
  List<LinkedNode> get switchMember_statements;

  @VariantId(7, variant: LinkedNodeKind.switchStatement)
  LinkedNode get switchStatement_expression;

  @VariantId(18, variant: LinkedNodeKind.switchStatement)
  int get switchStatement_leftBracket;

  @VariantId(15, variant: LinkedNodeKind.switchStatement)
  int get switchStatement_leftParenthesis;

  @VariantId(2, variant: LinkedNodeKind.switchStatement)
  List<LinkedNode> get switchStatement_members;

  @VariantId(19, variant: LinkedNodeKind.switchStatement)
  int get switchStatement_rightBracket;

  @VariantId(16, variant: LinkedNodeKind.switchStatement)
  int get switchStatement_rightParenthesis;

  @VariantId(17, variant: LinkedNodeKind.switchStatement)
  int get switchStatement_switchKeyword;

  @VariantId(28, variant: LinkedNodeKind.symbolLiteral)
  List<int> get symbolLiteral_components;

  @VariantId(15, variant: LinkedNodeKind.symbolLiteral)
  int get symbolLiteral_poundSign;

  @VariantId(15, variant: LinkedNodeKind.thisExpression)
  int get thisExpression_thisKeyword;

  @VariantId(6, variant: LinkedNodeKind.throwExpression)
  LinkedNode get throwExpression_expression;

  @VariantId(15, variant: LinkedNodeKind.throwExpression)
  int get throwExpression_throwKeyword;

  @VariantId(35, variantList: [
    LinkedNodeKind.simpleFormalParameter,
    LinkedNodeKind.variableDeclaration,
  ])
  TopLevelInferenceError get topLevelTypeInferenceError;

  @VariantId(15, variant: LinkedNodeKind.topLevelVariableDeclaration)
  int get topLevelVariableDeclaration_semicolon;

  @VariantId(6, variant: LinkedNodeKind.topLevelVariableDeclaration)
  LinkedNode get topLevelVariableDeclaration_variableList;

  @VariantId(6, variant: LinkedNodeKind.tryStatement)
  LinkedNode get tryStatement_body;

  @VariantId(2, variant: LinkedNodeKind.tryStatement)
  List<LinkedNode> get tryStatement_catchClauses;

  @VariantId(7, variant: LinkedNodeKind.tryStatement)
  LinkedNode get tryStatement_finallyBlock;

  @VariantId(15, variant: LinkedNodeKind.tryStatement)
  int get tryStatement_finallyKeyword;

  @VariantId(16, variant: LinkedNodeKind.tryStatement)
  int get tryStatement_tryKeyword;

  @VariantId(27, variantList: [
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
  ])
  bool get typeAlias_hasSelfReference;

  @VariantId(19, variantList: [
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
  ])
  int get typeAlias_semicolon;

  @VariantId(18, variantList: [
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
  ])
  int get typeAlias_typedefKeyword;

  @VariantId(2, variant: LinkedNodeKind.typeArgumentList)
  List<LinkedNode> get typeArgumentList_arguments;

  @VariantId(15, variant: LinkedNodeKind.typeArgumentList)
  int get typeArgumentList_leftBracket;

  @VariantId(16, variant: LinkedNodeKind.typeArgumentList)
  int get typeArgumentList_rightBracket;

  @VariantId(19, variantList: [
    LinkedNodeKind.listLiteral,
    LinkedNodeKind.setOrMapLiteral,
  ])
  int get typedLiteral_constKeyword;

  @VariantId(14, variantList: [
    LinkedNodeKind.listLiteral,
    LinkedNodeKind.setOrMapLiteral,
  ])
  LinkedNode get typedLiteral_typeArguments;

  @VariantId(6, variant: LinkedNodeKind.typeName)
  LinkedNode get typeName_name;

  @VariantId(15, variant: LinkedNodeKind.typeName)
  int get typeName_question;

  @VariantId(23, variant: LinkedNodeKind.typeName)
  LinkedNodeType get typeName_type;

  @VariantId(7, variant: LinkedNodeKind.typeName)
  LinkedNode get typeName_typeArguments;

  @VariantId(6, variant: LinkedNodeKind.typeParameter)
  LinkedNode get typeParameter_bound;

  @VariantId(23, variant: LinkedNodeKind.typeParameter)
  LinkedNodeType get typeParameter_defaultType;

  @VariantId(15, variant: LinkedNodeKind.typeParameter)
  int get typeParameter_extendsKeyword;

  @VariantId(7, variant: LinkedNodeKind.typeParameter)
  LinkedNode get typeParameter_name;

  @VariantId(15, variant: LinkedNodeKind.typeParameterList)
  int get typeParameterList_leftBracket;

  @VariantId(16, variant: LinkedNodeKind.typeParameterList)
  int get typeParameterList_rightBracket;

  @VariantId(2, variant: LinkedNodeKind.typeParameterList)
  List<LinkedNode> get typeParameterList_typeParameters;

  @VariantId(14, variantList: [
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.importDirective,
    LinkedNodeKind.partDirective,
  ])
  LinkedNode get uriBasedDirective_uri;

  @VariantId(22, variantList: [
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.importDirective,
    LinkedNodeKind.partDirective,
  ])
  String get uriBasedDirective_uriContent;

  @VariantId(19, variantList: [
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.importDirective,
    LinkedNodeKind.partDirective,
  ])
  int get uriBasedDirective_uriElement;

  @VariantId(32, variant: LinkedNodeKind.variableDeclaration)
  LinkedNodeVariablesDeclaration get variableDeclaration_declaration;

  @VariantId(15, variant: LinkedNodeKind.variableDeclaration)
  int get variableDeclaration_equals;

  @VariantId(6, variant: LinkedNodeKind.variableDeclaration)
  LinkedNode get variableDeclaration_initializer;

  @VariantId(7, variant: LinkedNodeKind.variableDeclaration)
  LinkedNode get variableDeclaration_name;

  @VariantId(15, variant: LinkedNodeKind.variableDeclarationList)
  int get variableDeclarationList_keyword;

  @VariantId(16, variant: LinkedNodeKind.variableDeclarationList)
  int get variableDeclarationList_lateKeyword;

  @VariantId(6, variant: LinkedNodeKind.variableDeclarationList)
  LinkedNode get variableDeclarationList_type;

  @VariantId(2, variant: LinkedNodeKind.variableDeclarationList)
  List<LinkedNode> get variableDeclarationList_variables;

  @VariantId(15, variant: LinkedNodeKind.variableDeclarationStatement)
  int get variableDeclarationStatement_semicolon;

  @VariantId(6, variant: LinkedNodeKind.variableDeclarationStatement)
  LinkedNode get variableDeclarationStatement_variables;

  @VariantId(6, variant: LinkedNodeKind.whileStatement)
  LinkedNode get whileStatement_body;

  @VariantId(7, variant: LinkedNodeKind.whileStatement)
  LinkedNode get whileStatement_condition;

  @VariantId(15, variant: LinkedNodeKind.whileStatement)
  int get whileStatement_leftParenthesis;

  @VariantId(16, variant: LinkedNodeKind.whileStatement)
  int get whileStatement_rightParenthesis;

  @VariantId(17, variant: LinkedNodeKind.whileStatement)
  int get whileStatement_whileKeyword;

  @VariantId(2, variant: LinkedNodeKind.withClause)
  List<LinkedNode> get withClause_mixinTypes;

  @VariantId(15, variant: LinkedNodeKind.withClause)
  int get withClause_withKeyword;

  @VariantId(6, variant: LinkedNodeKind.yieldStatement)
  LinkedNode get yieldStatement_expression;

  @VariantId(17, variant: LinkedNodeKind.yieldStatement)
  int get yieldStatement_semicolon;

  @VariantId(16, variant: LinkedNodeKind.yieldStatement)
  int get yieldStatement_star;

  @VariantId(15, variant: LinkedNodeKind.yieldStatement)
  int get yieldStatement_yieldKeyword;
}

/// Information about a group of libraries linked together, for example because
/// they form a single cycle, or because they represent a single build artifact.
@TopLevel('LNBn')
abstract class LinkedNodeBundle extends base.SummaryClass {
  factory LinkedNodeBundle.fromBuffer(List<int> buffer) =>
      generated.readLinkedNodeBundle(buffer);

  @Id(1)
  List<LinkedNodeLibrary> get libraries;

  /// The shared list of references used in the [libraries].
  @Id(0)
  LinkedNodeReferences get references;
}

/// Types of comments.
enum LinkedNodeCommentType { block, documentation, endOfLine }

/// Kinds of formal parameters.
enum LinkedNodeFormalParameterKind {
  requiredPositional,
  optionalPositional,
  optionalNamed,
  requiredNamed
}

/// Kinds of [LinkedNode].
enum LinkedNodeKind {
  adjacentStrings,
  annotation,
  argumentList,
  asExpression,
  assertInitializer,
  assertStatement,
  assignmentExpression,
  awaitExpression,
  binaryExpression,
  block,
  blockFunctionBody,
  booleanLiteral,
  breakStatement,
  cascadeExpression,
  catchClause,
  classDeclaration,
  classTypeAlias,
  comment,
  commentReference,
  compilationUnit,
  conditionalExpression,
  configuration,
  constructorDeclaration,
  constructorFieldInitializer,
  constructorName,
  continueStatement,
  declaredIdentifier,
  defaultFormalParameter,
  doubleLiteral,
  doStatement,
  dottedName,
  emptyFunctionBody,
  emptyStatement,
  enumConstantDeclaration,
  enumDeclaration,
  exportDirective,
  expressionFunctionBody,
  expressionStatement,
  extendsClause,
  fieldDeclaration,
  fieldFormalParameter,
  formalParameterList,
  forEachPartsWithDeclaration,
  forEachPartsWithIdentifier,
  forElement,
  forPartsWithDeclarations,
  forPartsWithExpression,
  forStatement,
  functionDeclaration,
  functionDeclarationStatement,
  functionExpression,
  functionExpressionInvocation,
  functionTypeAlias,
  functionTypedFormalParameter,
  genericFunctionType,
  genericTypeAlias,
  hideCombinator,
  ifElement,
  ifStatement,
  implementsClause,
  importDirective,
  instanceCreationExpression,
  indexExpression,
  integerLiteral,
  interpolationExpression,
  interpolationString,
  isExpression,
  label,
  labeledStatement,
  libraryDirective,
  libraryIdentifier,
  listLiteral,
  mapLiteralEntry,
  methodDeclaration,
  methodInvocation,
  mixinDeclaration,
  namedExpression,
  nativeClause,
  nativeFunctionBody,
  nullLiteral,
  onClause,
  parenthesizedExpression,
  partDirective,
  partOfDirective,
  postfixExpression,
  prefixExpression,
  prefixedIdentifier,
  propertyAccess,
  redirectingConstructorInvocation,
  rethrowExpression,
  returnStatement,
  scriptTag,
  setOrMapLiteral,
  showCombinator,
  simpleFormalParameter,
  simpleIdentifier,
  simpleStringLiteral,
  spreadElement,
  stringInterpolation,
  superConstructorInvocation,
  superExpression,
  switchCase,
  switchDefault,
  switchStatement,
  symbolLiteral,
  thisExpression,
  throwExpression,
  topLevelVariableDeclaration,
  tryStatement,
  typeArgumentList,
  typeName,
  typeParameter,
  typeParameterList,
  variableDeclaration,
  variableDeclarationList,
  variableDeclarationStatement,
  whileStatement,
  withClause,
  yieldStatement,
}

/// Information about a single library in a [LinkedNodeBundle].
abstract class LinkedNodeLibrary extends base.SummaryClass {
  @Id(2)
  List<int> get exports;

  @Id(3)
  String get name;

  @Id(5)
  int get nameLength;

  @Id(4)
  int get nameOffset;

  @Id(1)
  List<LinkedNodeUnit> get units;

  @Id(0)
  String get uriStr;
}

/// Flattened tree of declarations referenced from [LinkedNode]s.
abstract class LinkedNodeReferences extends base.SummaryClass {
  @Id(1)
  List<String> get name;

  @Id(0)
  List<int> get parent;
}

/// Information about a Dart type.
abstract class LinkedNodeType extends base.SummaryClass {
  @Id(0)
  List<LinkedNodeTypeFormalParameter> get functionFormalParameters;

  @Id(1)
  LinkedNodeType get functionReturnType;

  @Id(2)
  List<LinkedNodeTypeTypeParameter> get functionTypeParameters;

  @Id(8)
  int get genericTypeAliasReference;

  @Id(9)
  List<LinkedNodeType> get genericTypeAliasTypeArguments;

  /// Reference to a [LinkedNodeReferences].
  @Id(3)
  int get interfaceClass;

  @Id(4)
  List<LinkedNodeType> get interfaceTypeArguments;

  @Id(5)
  LinkedNodeTypeKind get kind;

  @Id(10)
  EntityRefNullabilitySuffix get nullabilitySuffix;

  @Id(6)
  int get typeParameterElement;

  @Id(7)
  int get typeParameterId;
}

/// Information about a formal parameter in a function type.
abstract class LinkedNodeTypeFormalParameter extends base.SummaryClass {
  @Id(0)
  LinkedNodeFormalParameterKind get kind;

  @Id(1)
  String get name;

  @Id(2)
  LinkedNodeType get type;
}

/// Kinds of [LinkedNodeType]s.
enum LinkedNodeTypeKind {
  bottom,
  dynamic_,
  function,
  interface,
  typeParameter,
  void_
}

/// Information about a type parameter in a function type.
abstract class LinkedNodeTypeTypeParameter extends base.SummaryClass {
  @Id(1)
  LinkedNodeType get bound;

  @Id(0)
  String get name;
}

/// Information about a single library in a [LinkedNodeLibrary].
abstract class LinkedNodeUnit extends base.SummaryClass {
  @Id(3)
  bool get isSynthetic;

  /// Offsets of the first character of each line in the source code.
  @informative
  @Id(4)
  List<int> get lineStarts;

  @Id(2)
  LinkedNode get node;

  @Id(1)
  UnlinkedTokens get tokens;

  @Id(0)
  String get uriStr;
}

/// Information about a top-level declaration, or a field declaration that
/// contributes information to [LinkedNodeKind.variableDeclaration].
abstract class LinkedNodeVariablesDeclaration extends base.SummaryClass {
  @Id(0)
  LinkedNode get comment;

  @Id(1)
  bool get isConst;

  @Id(2)
  bool get isCovariant;

  @Id(3)
  bool get isFinal;

  @Id(4)
  bool get isStatic;
}

/// Information about the resolution of an [UnlinkedReference].
abstract class LinkedReference extends base.SummaryClass {
  /// If this [LinkedReference] doesn't have an associated [UnlinkedReference],
  /// and the entity being referred to is contained within another entity, index
  /// of the containing entity.  This behaves similarly to
  /// [UnlinkedReference.prefixReference], however it is only used for class
  /// members, not for prefixed imports.
  ///
  /// Containing references must always point backward; that is, for all i, if
  /// LinkedUnit.references[i].containingReference != 0, then
  /// LinkedUnit.references[i].containingReference < i.
  @Id(5)
  int get containingReference;

  /// Index into [LinkedLibrary.dependencies] indicating which imported library
  /// declares the entity being referred to.
  ///
  /// Zero if this entity is contained within another entity (e.g. a class
  /// member), or if [kind] is [ReferenceKind.prefix].
  @Id(1)
  int get dependency;

  /// The kind of the entity being referred to.  For the pseudo-types `dynamic`
  /// and `void`, the kind is [ReferenceKind.classOrEnum].
  @Id(2)
  ReferenceKind get kind;

  /// If [kind] is [ReferenceKind.function] (that is, the entity being referred
  /// to is a local function), the index of the function within
  /// [UnlinkedExecutable.localFunctions].  Otherwise zero.
  @deprecated
  @Id(6)
  int get localIndex;

  /// If this [LinkedReference] doesn't have an associated [UnlinkedReference],
  /// name of the entity being referred to.  For the pseudo-type `dynamic`, the
  /// string is "dynamic".  For the pseudo-type `void`, the string is "void".
  @Id(3)
  String get name;

  /// If the entity being referred to is generic, the number of type parameters
  /// it declares (does not include type parameters of enclosing entities).
  /// Otherwise zero.
  @Id(4)
  int get numTypeParameters;

  /// Integer index indicating which unit in the imported library contains the
  /// definition of the entity.  As with indices into [LinkedLibrary.units],
  /// zero represents the defining compilation unit, and nonzero values
  /// represent parts in the order of the corresponding `part` declarations.
  ///
  /// Zero if this entity is contained within another entity (e.g. a class
  /// member).
  @Id(0)
  int get unit;
}

/// Linked summary of a compilation unit.
abstract class LinkedUnit extends base.SummaryClass {
  /// List of slot ids (referring to [UnlinkedExecutable.constCycleSlot])
  /// corresponding to const constructors that are part of cycles.
  @Id(2)
  List<int> get constCycles;

  /// List of slot ids (referring to [UnlinkedClass.notSimplyBoundedSlot] or
  /// [UnlinkedTypedef.notSimplyBoundedSlot]) corresponding to classes and
  /// typedefs that are not simply bounded.
  @Id(5)
  List<int> get notSimplyBounded;

  /// List of slot ids (referring to [UnlinkedParam.inheritsCovariantSlot] or
  /// [UnlinkedVariable.inheritsCovariantSlot]) corresponding to parameters
  /// that inherit `@covariant` behavior from a base class.
  @Id(3)
  List<int> get parametersInheritingCovariant;

  /// Information about the resolution of references within the compilation
  /// unit.  Each element of [UnlinkedUnit.references] has a corresponding
  /// element in this list (at the same index).  If this list has additional
  /// elements beyond the number of elements in [UnlinkedUnit.references], those
  /// additional elements are references that are only referred to implicitly
  /// (e.g. elements involved in inferred or propagated types).
  @Id(0)
  List<LinkedReference> get references;

  /// The list of type inference errors.
  @Id(4)
  List<TopLevelInferenceError> get topLevelInferenceErrors;

  /// List associating slot ids found inside the unlinked summary for the
  /// compilation unit with propagated and inferred types.
  @Id(1)
  List<EntityRef> get types;
}

/// Summary information about a package.
@TopLevel('PBdl')
abstract class PackageBundle extends base.SummaryClass {
  factory PackageBundle.fromBuffer(List<int> buffer) =>
      generated.readPackageBundle(buffer);

  /// MD5 hash of the non-informative fields of the [PackageBundle] (not
  /// including this one).  This can be used to identify when the API of a
  /// package may have changed.
  @Id(7)
  @deprecated
  String get apiSignature;

  /// Information about the packages this package depends on, if known.
  @Id(8)
  @informative
  @deprecated
  List<PackageDependencyInfo> get dependencies;

  /// Linked libraries.
  @Id(0)
  List<LinkedLibrary> get linkedLibraries;

  /// The list of URIs of items in [linkedLibraries], e.g. `dart:core` or
  /// `package:foo/bar.dart`.
  @Id(1)
  List<String> get linkedLibraryUris;

  /// Major version of the summary format.  See
  /// [PackageBundleAssembler.currentMajorVersion].
  @Id(5)
  int get majorVersion;

  /// Minor version of the summary format.  See
  /// [PackageBundleAssembler.currentMinorVersion].
  @Id(6)
  int get minorVersion;

  /// List of MD5 hashes of the files listed in [unlinkedUnitUris].  Each hash
  /// is encoded as a hexadecimal string using lower case letters.
  @Id(4)
  @deprecated
  @informative
  List<String> get unlinkedUnitHashes;

  /// Unlinked information for the compilation units constituting the package.
  @Id(2)
  List<UnlinkedUnit> get unlinkedUnits;

  /// The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
  @Id(3)
  List<String> get unlinkedUnitUris;
}

/// Information about a single dependency of a summary package.
@deprecated
abstract class PackageDependencyInfo extends base.SummaryClass {
  /// API signature of this dependency.
  @Id(0)
  String get apiSignature;

  /// If this dependency summarizes any files whose URI takes the form
  /// "package:<package_name>/...", a list of all such package names, sorted
  /// lexicographically.  Otherwise empty.
  @Id(2)
  List<String> get includedPackageNames;

  /// Indicates whether this dependency summarizes any files whose URI takes the
  /// form "dart:...".
  @Id(4)
  bool get includesDartUris;

  /// Indicates whether this dependency summarizes any files whose URI takes the
  /// form "file:...".
  @Id(3)
  bool get includesFileUris;

  /// Relative path to the summary file for this dependency.  This is intended
  /// as a hint to help the analysis server locate summaries of dependencies.
  /// We don't specify precisely what this path is relative to, but we expect
  /// it to be relative to a directory the analysis server can find (e.g. for
  /// projects built using Bazel, it would be relative to the "bazel-bin"
  /// directory).
  ///
  /// Absent if the path is not known.
  @Id(1)
  String get summaryPath;
}

/// Index information about a package.
@TopLevel('Indx')
abstract class PackageIndex extends base.SummaryClass {
  factory PackageIndex.fromBuffer(List<int> buffer) =>
      generated.readPackageIndex(buffer);

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the kind of the synthetic element.
  @Id(5)
  List<IndexSyntheticElementKind> get elementKinds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the class member element name, or `null` if the element
  /// is a top-level element.  The list is sorted in ascending order, so that
  /// the client can quickly check whether an element is referenced in this
  /// [PackageIndex].
  @Id(7)
  List<int> get elementNameClassMemberIds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the named parameter name, or `null` if the element is
  /// not a named parameter.  The list is sorted in ascending order, so that the
  /// client can quickly check whether an element is referenced in this
  /// [PackageIndex].
  @Id(8)
  List<int> get elementNameParameterIds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the top-level element name, or `null` if the element is
  /// the unit.  The list is sorted in ascending order, so that the client can
  /// quickly check whether an element is referenced in this [PackageIndex].
  @Id(1)
  List<int> get elementNameUnitMemberIds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the index into [unitLibraryUris] and [unitUnitUris] for the library
  /// specific unit where the element is declared.
  @Id(0)
  List<int> get elementUnits;

  /// List of unique element strings used in this [PackageIndex].  The list is
  /// sorted in ascending order, so that the client can quickly check the
  /// presence of a string in this [PackageIndex].
  @Id(6)
  List<String> get strings;

  /// Each item of this list corresponds to the library URI of a unique library
  /// specific unit referenced in the [PackageIndex].  It is an index into
  /// [strings] list.
  @Id(2)
  List<int> get unitLibraryUris;

  /// List of indexes of each unit in this [PackageIndex].
  @Id(4)
  List<UnitIndex> get units;

  /// Each item of this list corresponds to the unit URI of a unique library
  /// specific unit referenced in the [PackageIndex].  It is an index into
  /// [strings] list.
  @Id(3)
  List<int> get unitUnitUris;
}

/// Enum used to indicate the kind of entity referred to by a
/// [LinkedReference].
enum ReferenceKind {
  /// The entity is a class or enum.
  classOrEnum,

  /// The entity is a constructor.
  constructor,

  /// The entity is a getter or setter inside a class.  Note: this is used in
  /// the case where a constant refers to a static const declared inside a
  /// class.
  propertyAccessor,

  /// The entity is a method.
  method,

  /// The entity is a typedef.
  typedef,

  /// The entity is a local function.
  function,

  /// The entity is a local variable.
  variable,

  /// The entity is a top level function.
  topLevelFunction,

  /// The entity is a top level getter or setter.
  topLevelPropertyAccessor,

  /// The entity is a prefix.
  prefix,

  /// The entity being referred to does not exist.
  unresolved,

  /// The entity is a typedef expressed using generic function type syntax.
  genericFunctionTypedef
}

/// Summary information about a top-level type inference error.
abstract class TopLevelInferenceError extends base.SummaryClass {
  /// The [kind] specific arguments.
  @Id(2)
  List<String> get arguments;

  /// The kind of the error.
  @Id(1)
  TopLevelInferenceErrorKind get kind;

  /// The slot id (which is unique within the compilation unit) identifying the
  /// target of type inference with which this [TopLevelInferenceError] is
  /// associated.
  @Id(0)
  int get slot;
}

/// Enum used to indicate the kind of the error during top-level inference.
enum TopLevelInferenceErrorKind {
  assignment,
  instanceGetter,
  dependencyCycle,
  overrideConflictFieldType,
  overrideConflictReturnType,
  overrideConflictParameterType
}

/// Enum used to indicate the style of a typedef.
enum TypedefStyle {
  /// A typedef that defines a non-generic function type. The syntax is
  /// ```
  /// 'typedef' returnType? identifier typeParameters? formalParameterList ';'
  /// ```
  /// The typedef can have type parameters associated with it, but the function
  /// type that results from applying type arguments does not.
  functionType,

  /// A typedef expressed using generic function type syntax. The syntax is
  /// ```
  /// typeAlias ::=
  ///     'typedef' identifier typeParameters? '=' genericFunctionType ';'
  /// genericFunctionType ::=
  ///     returnType? 'Function' typeParameters? parameterTypeList
  /// ```
  /// Both the typedef itself and the function type that results from applying
  /// type arguments can have type parameters.
  genericFunctionType
}

/// Index information about a unit in a [PackageIndex].
abstract class UnitIndex extends base.SummaryClass {
  /// Each item of this list is the kind of an element defined in this unit.
  @Id(6)
  List<IndexNameKind> get definedNameKinds;

  /// Each item of this list is the name offset of an element defined in this
  /// unit relative to the beginning of the file.
  @Id(7)
  List<int> get definedNameOffsets;

  /// Each item of this list corresponds to an element defined in this unit.  It
  /// is an index into [PackageIndex.strings] list.  The list is sorted in
  /// ascending order, so that the client can quickly find name definitions in
  /// this [UnitIndex].
  @Id(5)
  List<int> get definedNames;

  /// Index into [PackageIndex.unitLibraryUris] and [PackageIndex.unitUnitUris]
  /// for the library specific unit that corresponds to this [UnitIndex].
  @Id(0)
  int get unit;

  /// Each item of this list is the `true` if the corresponding element usage
  /// is qualified with some prefix.
  @Id(11)
  List<bool> get usedElementIsQualifiedFlags;

  /// Each item of this list is the kind of the element usage.
  @Id(4)
  List<IndexRelationKind> get usedElementKinds;

  /// Each item of this list is the length of the element usage.
  @Id(1)
  List<int> get usedElementLengths;

  /// Each item of this list is the offset of the element usage relative to the
  /// beginning of the file.
  @Id(2)
  List<int> get usedElementOffsets;

  /// Each item of this list is the index into [PackageIndex.elementUnits] and
  /// [PackageIndex.elementOffsets].  The list is sorted in ascending order, so
  /// that the client can quickly find element references in this [UnitIndex].
  @Id(3)
  List<int> get usedElements;

  /// Each item of this list is the `true` if the corresponding name usage
  /// is qualified with some prefix.
  @Id(12)
  List<bool> get usedNameIsQualifiedFlags;

  /// Each item of this list is the kind of the name usage.
  @Id(10)
  List<IndexRelationKind> get usedNameKinds;

  /// Each item of this list is the offset of the name usage relative to the
  /// beginning of the file.
  @Id(9)
  List<int> get usedNameOffsets;

  /// Each item of this list is the index into [PackageIndex.strings] for a
  /// used name.  The list is sorted in ascending order, so that the client can
  /// quickly find name uses in this [UnitIndex].
  @Id(8)
  List<int> get usedNames;
}

/// Unlinked summary information about a class declaration.
abstract class UnlinkedClass extends base.SummaryClass {
  /// Annotations for this class.
  @Id(5)
  List<UnlinkedExpr> get annotations;

  /// Code range of the class.
  @informative
  @Id(13)
  CodeRange get codeRange;

  /// Documentation comment for the class, or `null` if there is no
  /// documentation comment.
  @informative
  @Id(6)
  UnlinkedDocumentationComment get documentationComment;

  /// Executable objects (methods, getters, and setters) contained in the class.
  @Id(2)
  List<UnlinkedExecutable> get executables;

  /// Field declarations contained in the class.
  @Id(4)
  List<UnlinkedVariable> get fields;

  /// Indicates whether this class is the core "Object" class (and hence has no
  /// supertype)
  @Id(12)
  bool get hasNoSupertype;

  /// Interfaces appearing in an `implements` clause, if any.
  @Id(7)
  List<EntityRef> get interfaces;

  /// Indicates whether the class is declared with the `abstract` keyword.
  @Id(8)
  bool get isAbstract;

  /// Indicates whether the class is declared using mixin application syntax.
  @Id(11)
  bool get isMixinApplication;

  /// Mixins appearing in a `with` clause, if any.
  @Id(10)
  List<EntityRef> get mixins;

  /// Name of the class.
  @Id(0)
  String get name;

  /// Offset of the class name relative to the beginning of the file.
  @informative
  @Id(1)
  int get nameOffset;

  /// If the class might not be simply bounded, a nonzero slot id which is unique
  /// within this compilation unit.  If this id is found in
  /// [LinkedUnit.notSimplyBounded], then at least one of this class's type
  /// parameters is not simply bounded, hence this class can't be used as a raw
  /// type when specifying the bound of a type parameter.
  ///
  /// Otherwise, zero.
  @Id(16)
  int get notSimplyBoundedSlot;

  /// Superclass constraints for this mixin declaration. The list will be empty
  /// if this class is not a mixin declaration, or if the declaration does not
  /// have an `on` clause (in which case the type `Object` is implied).
  @Id(14)
  List<EntityRef> get superclassConstraints;

  /// Names of methods, getters, setters, and operators that this mixin
  /// declaration super-invokes.  For setters this includes the trailing "=".
  /// The list will be empty if this class is not a mixin declaration.
  @Id(15)
  List<String> get superInvokedNames;

  /// Supertype of the class, or `null` if either (a) the class doesn't
  /// explicitly declare a supertype (and hence has supertype `Object`), or (b)
  /// the class *is* `Object` (and hence has no supertype).
  @Id(3)
  EntityRef get supertype;

  /// Type parameters of the class, if any.
  @Id(9)
  List<UnlinkedTypeParam> get typeParameters;
}

/// Unlinked summary information about a `show` or `hide` combinator in an
/// import or export declaration.
abstract class UnlinkedCombinator extends base.SummaryClass {
  /// If this is a `show` combinator, offset of the end of the list of shown
  /// names.  Otherwise zero.
  @informative
  @Id(3)
  int get end;

  /// List of names which are hidden.  Empty if this is a `show` combinator.
  @Id(1)
  List<String> get hides;

  /// If this is a `show` combinator, offset of the `show` keyword.  Otherwise
  /// zero.
  @informative
  @Id(2)
  int get offset;

  /// List of names which are shown.  Empty if this is a `hide` combinator.
  @Id(0)
  List<String> get shows;
}

/// Unlinked summary information about a single import or export configuration.
abstract class UnlinkedConfiguration extends base.SummaryClass {
  /// The name of the declared variable whose value is being used in the
  /// condition.
  @Id(0)
  String get name;

  /// The URI of the implementation library to be used if the condition is true.
  @Id(2)
  String get uri;

  /// The value to which the value of the declared variable will be compared,
  /// or `true` if the condition does not include an equality test.
  @Id(1)
  String get value;
}

/// Unlinked summary information about a constructor initializer.
abstract class UnlinkedConstructorInitializer extends base.SummaryClass {
  /// If there are `m` [arguments] and `n` [argumentNames], then each argument
  /// from [arguments] with index `i` such that `n + i - m >= 0`, should be used
  /// with the name at `n + i - m`.
  @Id(4)
  List<String> get argumentNames;

  /// If [kind] is `thisInvocation` or `superInvocation`, the arguments of the
  /// invocation.  Otherwise empty.
  @Id(3)
  List<UnlinkedExpr> get arguments;

  /// If [kind] is `field`, the expression of the field initializer.
  /// Otherwise `null`.
  @Id(1)
  UnlinkedExpr get expression;

  /// The kind of the constructor initializer (field, redirect, super).
  @Id(2)
  UnlinkedConstructorInitializerKind get kind;

  /// If [kind] is `field`, the name of the field declared in the class.  If
  /// [kind] is `thisInvocation`, the name of the constructor, declared in this
  /// class, to redirect to.  If [kind] is `superInvocation`, the name of the
  /// constructor, declared in the superclass, to invoke.
  @Id(0)
  String get name;
}

/// Enum used to indicate the kind of an constructor initializer.
enum UnlinkedConstructorInitializerKind {
  /// Initialization of a field.
  field,

  /// Invocation of a constructor in the same class.
  thisInvocation,

  /// Invocation of a superclass' constructor.
  superInvocation,

  /// Invocation of `assert`.
  assertInvocation
}

/// Unlinked summary information about a documentation comment.
abstract class UnlinkedDocumentationComment extends base.SummaryClass {
  /// Length of the documentation comment (prior to replacing '\r\n' with '\n').
  @Id(0)
  @deprecated
  int get length;

  /// Offset of the beginning of the documentation comment relative to the
  /// beginning of the file.
  @Id(2)
  @deprecated
  int get offset;

  /// Text of the documentation comment, with '\r\n' replaced by '\n'.
  ///
  /// References appearing within the doc comment in square brackets are not
  /// specially encoded.
  @Id(1)
  String get text;
}

/// Unlinked summary information about an enum declaration.
abstract class UnlinkedEnum extends base.SummaryClass {
  /// Annotations for this enum.
  @Id(4)
  List<UnlinkedExpr> get annotations;

  /// Code range of the enum.
  @informative
  @Id(5)
  CodeRange get codeRange;

  /// Documentation comment for the enum, or `null` if there is no documentation
  /// comment.
  @informative
  @Id(3)
  UnlinkedDocumentationComment get documentationComment;

  /// Name of the enum type.
  @Id(0)
  String get name;

  /// Offset of the enum name relative to the beginning of the file.
  @informative
  @Id(1)
  int get nameOffset;

  /// Values listed in the enum declaration, in declaration order.
  @Id(2)
  List<UnlinkedEnumValue> get values;
}

/// Unlinked summary information about a single enumerated value in an enum
/// declaration.
abstract class UnlinkedEnumValue extends base.SummaryClass {
  /// Annotations for this value.
  @Id(3)
  List<UnlinkedExpr> get annotations;

  /// Documentation comment for the enum value, or `null` if there is no
  /// documentation comment.
  @informative
  @Id(2)
  UnlinkedDocumentationComment get documentationComment;

  /// Name of the enumerated value.
  @Id(0)
  String get name;

  /// Offset of the enum value name relative to the beginning of the file.
  @informative
  @Id(1)
  int get nameOffset;
}

/// Unlinked summary information about a function, method, getter, or setter
/// declaration.
abstract class UnlinkedExecutable extends base.SummaryClass {
  /// Annotations for this executable.
  @Id(6)
  List<UnlinkedExpr> get annotations;

  /// If this executable's function body is declared using `=>`, the expression
  /// to the right of the `=>`.  May be omitted if neither type inference nor
  /// constant evaluation depends on the function body.
  @Id(29)
  UnlinkedExpr get bodyExpr;

  /// Code range of the executable.
  @informative
  @Id(26)
  CodeRange get codeRange;

  /// If a constant [UnlinkedExecutableKind.constructor], the constructor
  /// initializers.  Otherwise empty.
  @Id(14)
  List<UnlinkedConstructorInitializer> get constantInitializers;

  /// If [kind] is [UnlinkedExecutableKind.constructor] and [isConst] is `true`,
  /// a nonzero slot id which is unique within this compilation unit.  If this
  /// id is found in [LinkedUnit.constCycles], then this constructor is part of
  /// a cycle.
  ///
  /// Otherwise, zero.
  @Id(25)
  int get constCycleSlot;

  /// Documentation comment for the executable, or `null` if there is no
  /// documentation comment.
  @informative
  @Id(7)
  UnlinkedDocumentationComment get documentationComment;

  /// If this executable's return type is inferable, nonzero slot id
  /// identifying which entry in [LinkedUnit.types] contains the inferred
  /// return type.  If there is no matching entry in [LinkedUnit.types], then
  /// no return type was inferred for this variable, so its static type is
  /// `dynamic`.
  @Id(5)
  int get inferredReturnTypeSlot;

  /// Indicates whether the executable is declared using the `abstract` keyword.
  @Id(10)
  bool get isAbstract;

  /// Indicates whether the executable has body marked as being asynchronous.
  @informative
  @Id(27)
  bool get isAsynchronous;

  /// Indicates whether the executable is declared using the `const` keyword.
  @Id(12)
  bool get isConst;

  /// Indicates whether the executable is declared using the `external` keyword.
  @Id(11)
  bool get isExternal;

  /// Indicates whether the executable is declared using the `factory` keyword.
  @Id(8)
  bool get isFactory;

  /// Indicates whether the executable has body marked as being a generator.
  @informative
  @Id(28)
  bool get isGenerator;

  /// Indicates whether the executable is a redirected constructor.
  @Id(13)
  bool get isRedirectedConstructor;

  /// Indicates whether the executable is declared using the `static` keyword.
  ///
  /// Note that for top level executables, this flag is false, since they are
  /// not declared using the `static` keyword (even though they are considered
  /// static for semantic purposes).
  @Id(9)
  bool get isStatic;

  /// The kind of the executable (function/method, getter, setter, or
  /// constructor).
  @Id(4)
  UnlinkedExecutableKind get kind;

  /// The list of local functions.
  @Id(18)
  List<UnlinkedExecutable> get localFunctions;

  /// The list of local labels.
  @informative
  @deprecated
  @Id(22)
  List<String> get localLabels;

  /// The list of local variables.
  @informative
  @deprecated
  @Id(19)
  List<UnlinkedVariable> get localVariables;

  /// Name of the executable.  For setters, this includes the trailing "=".  For
  /// named constructors, this excludes the class name and excludes the ".".
  /// For unnamed constructors, this is the empty string.
  @Id(1)
  String get name;

  /// If [kind] is [UnlinkedExecutableKind.constructor] and [name] is not empty,
  /// the offset of the end of the constructor name.  Otherwise zero.
  @informative
  @Id(23)
  int get nameEnd;

  /// Offset of the executable name relative to the beginning of the file.  For
  /// named constructors, this excludes the class name and excludes the ".".
  /// For unnamed constructors, this is the offset of the class name (i.e. the
  /// offset of the second "C" in "class C { C(); }").
  @informative
  @Id(0)
  int get nameOffset;

  /// Parameters of the executable, if any.  Note that getters have no
  /// parameters (hence this will be the empty list), and setters have a single
  /// parameter.
  @Id(2)
  List<UnlinkedParam> get parameters;

  /// If [kind] is [UnlinkedExecutableKind.constructor] and [name] is not empty,
  /// the offset of the period before the constructor name.  Otherwise zero.
  @informative
  @Id(24)
  int get periodOffset;

  /// If [isRedirectedConstructor] and [isFactory] are both `true`, the
  /// constructor to which this constructor redirects; otherwise empty.
  @Id(15)
  EntityRef get redirectedConstructor;

  /// If [isRedirectedConstructor] is `true` and [isFactory] is `false`, the
  /// name of the constructor that this constructor redirects to; otherwise
  /// empty.
  @Id(17)
  String get redirectedConstructorName;

  /// Declared return type of the executable.  Absent if the executable is a
  /// constructor or the return type is implicit.  Absent for executables
  /// associated with variable initializers and closures, since these
  /// executables may have return types that are not accessible via direct
  /// imports.
  @Id(3)
  EntityRef get returnType;

  /// Type parameters of the executable, if any.  Empty if support for generic
  /// method syntax is disabled.
  @Id(16)
  List<UnlinkedTypeParam> get typeParameters;

  /// If a local function, the length of the visible range; zero otherwise.
  @informative
  @Id(20)
  int get visibleLength;

  /// If a local function, the beginning of the visible range; zero otherwise.
  @informative
  @Id(21)
  int get visibleOffset;
}

/// Enum used to indicate the kind of an executable.
enum UnlinkedExecutableKind {
  /// Executable is a function or method.
  functionOrMethod,

  /// Executable is a getter.
  getter,

  /// Executable is a setter.
  setter,

  /// Executable is a constructor.
  constructor
}

/// Unlinked summary information about an export declaration (stored outside
/// [UnlinkedPublicNamespace]).
abstract class UnlinkedExportNonPublic extends base.SummaryClass {
  /// Annotations for this export directive.
  @Id(3)
  List<UnlinkedExpr> get annotations;

  /// Offset of the "export" keyword.
  @informative
  @Id(0)
  int get offset;

  /// End of the URI string (including quotes) relative to the beginning of the
  /// file.
  @informative
  @Id(1)
  int get uriEnd;

  /// Offset of the URI string (including quotes) relative to the beginning of
  /// the file.
  @informative
  @Id(2)
  int get uriOffset;
}

/// Unlinked summary information about an export declaration (stored inside
/// [UnlinkedPublicNamespace]).
abstract class UnlinkedExportPublic extends base.SummaryClass {
  /// Combinators contained in this export declaration.
  @Id(1)
  List<UnlinkedCombinator> get combinators;

  /// Configurations used to control which library will actually be loaded at
  /// run-time.
  @Id(2)
  List<UnlinkedConfiguration> get configurations;

  /// URI used in the source code to reference the exported library.
  @Id(0)
  String get uri;
}

/// Unlinked summary information about an expression.
///
/// Expressions are represented using a simple stack-based language
/// where [operations] is a sequence of operations to execute starting with an
/// empty stack.  Once all operations have been executed, the stack should
/// contain a single value which is the value of the constant.  Note that some
/// operations consume additional data from the other fields of this class.
abstract class UnlinkedExpr extends base.SummaryClass {
  /// Sequence of operators used by assignment operations.
  @Id(6)
  List<UnlinkedExprAssignOperator> get assignmentOperators;

  /// Sequence of 64-bit doubles consumed by the operation `pushDouble`.
  @Id(4)
  List<double> get doubles;

  /// Sequence of unsigned 32-bit integers consumed by the operations
  /// `pushArgument`, `pushInt`, `shiftOr`, `concatenate`, `invokeConstructor`,
  /// `makeList`, and `makeMap`.
  @Id(1)
  List<int> get ints;

  /// Indicates whether the expression is a valid potentially constant
  /// expression.
  @Id(5)
  bool get isValidConst;

  /// Sequence of operations to execute (starting with an empty stack) to form
  /// the constant value.
  @Id(0)
  List<UnlinkedExprOperation> get operations;

  /// Sequence of language constructs consumed by the operations
  /// `pushReference`, `invokeConstructor`, `makeList`, and `makeMap`.  Note
  /// that in the case of `pushReference` (and sometimes `invokeConstructor` the
  /// actual entity being referred to may be something other than a type.
  @Id(2)
  List<EntityRef> get references;

  /// String representation of the expression in a form suitable to be tokenized
  /// and parsed.
  @Id(7)
  String get sourceRepresentation;

  /// Sequence of strings consumed by the operations `pushString` and
  /// `invokeConstructor`.
  @Id(3)
  List<String> get strings;
}

/// Enum representing the various kinds of assignment operations combined
/// with:
///    [UnlinkedExprOperation.assignToRef],
///    [UnlinkedExprOperation.assignToProperty],
///    [UnlinkedExprOperation.assignToIndex].
enum UnlinkedExprAssignOperator {
  /// Perform simple assignment `target = operand`.
  assign,

  /// Perform `target ??= operand`.
  ifNull,

  /// Perform `target *= operand`.
  multiply,

  /// Perform `target /= operand`.
  divide,

  /// Perform `target ~/= operand`.
  floorDivide,

  /// Perform `target %= operand`.
  modulo,

  /// Perform `target += operand`.
  plus,

  /// Perform `target -= operand`.
  minus,

  /// Perform `target <<= operand`.
  shiftLeft,

  /// Perform `target >>= operand`.
  shiftRight,

  /// Perform `target &= operand`.
  bitAnd,

  /// Perform `target ^= operand`.
  bitXor,

  /// Perform `target |= operand`.
  bitOr,

  /// Perform `++target`.
  prefixIncrement,

  /// Perform `--target`.
  prefixDecrement,

  /// Perform `target++`.
  postfixIncrement,

  /// Perform `target++`.
  postfixDecrement,
}

/// Enum representing the various kinds of operations which may be performed to
/// in an expression.  These options are assumed to execute in the
/// context of a stack which is initially empty.
enum UnlinkedExprOperation {
  /// Push the next value from [UnlinkedExpr.ints] (a 32-bit unsigned integer)
  /// onto the stack.
  ///
  /// Note that Dart supports integers larger than 32 bits; these are
  /// represented by composing 32-bit values using the [pushLongInt] operation.
  pushInt,

  /// Get the number of components from [UnlinkedExpr.ints], then do this number
  /// of times the following operations: multiple the current value by 2^32,
  /// "or" it with the next value in [UnlinkedExpr.ints]. The initial value is
  /// zero. Push the result into the stack.
  pushLongInt,

  /// Push the next value from [UnlinkedExpr.doubles] (a double precision
  /// floating point value) onto the stack.
  pushDouble,

  /// Push the constant `true` onto the stack.
  pushTrue,

  /// Push the constant `false` onto the stack.
  pushFalse,

  /// Push the next value from [UnlinkedExpr.strings] onto the stack.
  pushString,

  /// Pop the top n values from the stack (where n is obtained from
  /// [UnlinkedExpr.ints]), convert them to strings (if they aren't already),
  /// concatenate them into a single string, and push it back onto the stack.
  ///
  /// This operation is used to represent constants whose value is a literal
  /// string containing string interpolations.
  concatenate,

  /// Get the next value from [UnlinkedExpr.strings], convert it to a symbol,
  /// and push it onto the stack.
  makeSymbol,

  /// Push the constant `null` onto the stack.
  pushNull,

  /// Push the value of the function parameter with the name obtained from
  /// [UnlinkedExpr.strings].
  pushParameter,

  /// Evaluate a (potentially qualified) identifier expression and push the
  /// resulting value onto the stack.  The identifier to be evaluated is
  /// obtained from [UnlinkedExpr.references].
  ///
  /// This operation is used to represent the following kinds of constants
  /// (which are indistinguishable from an unresolved AST alone):
  ///
  /// - A qualified reference to a static constant variable (e.g. `C.v`, where
  ///   C is a class and `v` is a constant static variable in `C`).
  /// - An identifier expression referring to a constant variable.
  /// - A simple or qualified identifier denoting a class or type alias.
  /// - A simple or qualified identifier denoting a top-level function or a
  ///   static method.
  pushReference,

  /// Pop the top value from the stack, extract the value of the property with
  /// the name obtained from [UnlinkedExpr.strings], and push the result back
  /// onto the stack.
  extractProperty,

  /// Pop the top `n` values from the stack (where `n` is obtained from
  /// [UnlinkedExpr.ints]) into a list (filled from the end) and take the next
  /// `n` values from [UnlinkedExpr.strings] and use the lists of names and
  /// values to create named arguments.  Then pop the top `m` values from the
  /// stack (where `m` is obtained from [UnlinkedExpr.ints]) into a list (filled
  /// from the end) and use them as positional arguments.  Use the lists of
  /// positional and names arguments to invoke a constant constructor obtained
  /// from [UnlinkedExpr.references], and push the resulting value back onto the
  /// stack.
  ///
  /// Arguments are skipped, and `0` are specified as the numbers of arguments
  /// on the stack, if the expression is not a constant. We store expression of
  /// variable initializers to perform top-level inference, and arguments are
  /// never used to infer types.
  ///
  /// Note that for an invocation of the form `const a.b(...)` (where no type
  /// arguments are specified), it is impossible to tell from the unresolved AST
  /// alone whether `a` is a class name and `b` is a constructor name, or `a` is
  /// a prefix name and `b` is a class name.  For consistency between AST based
  /// and elements based summaries, references to default constructors are
  /// always recorded as references to corresponding classes.
  invokeConstructor,

  /// Pop the top n values from the stack (where n is obtained from
  /// [UnlinkedExpr.ints]), place them in a [List], and push the result back
  /// onto the stack.  The type parameter for the [List] is implicitly
  /// `dynamic`.
  makeUntypedList,

  /// Pop the top 2*n values from the stack (where n is obtained from
  /// [UnlinkedExpr.ints]), interpret them as key/value pairs, place them in a
  /// [Map], and push the result back onto the stack.  The two type parameters
  /// for the [Map] are implicitly `dynamic`.
  ///
  /// To be replaced with [makeUntypedSetOrMap] for unified collections.
  makeUntypedMap,

  /// Pop the top n values from the stack (where n is obtained from
  /// [UnlinkedExpr.ints]), place them in a [List], and push the result back
  /// onto the stack.  The type parameter for the [List] is obtained from
  /// [UnlinkedExpr.references].
  makeTypedList,

  /// Pop the top 2*n values from the stack (where n is obtained from
  /// [UnlinkedExpr.ints]), interpret them as key/value pairs, place them in a
  /// [Map], and push the result back onto the stack.  The two type parameters
  /// for the [Map] are obtained from [UnlinkedExpr.references].
  ///
  /// To be replaced with [makeTypedMap2] for unified collections. This is not
  /// forwards compatible with [makeTypedMap2] because it expects
  /// [CollectionElement]s instead of pairs of [Expression]s.
  makeTypedMap,

  /// Pop the top 2 values from the stack, evaluate `v1 == v2`, and push the
  /// result back onto the stack.
  equal,

  /// Pop the top 2 values from the stack, evaluate `v1 != v2`, and push the
  /// result back onto the stack.
  notEqual,

  /// Pop the top value from the stack, compute its boolean negation, and push
  /// the result back onto the stack.
  not,

  /// Pop the top 2 values from the stack, compute `v1 && v2`, and push the
  /// result back onto the stack.
  and,

  /// Pop the top 2 values from the stack, compute `v1 || v2`, and push the
  /// result back onto the stack.
  or,

  /// Pop the top value from the stack, compute its integer complement, and push
  /// the result back onto the stack.
  complement,

  /// Pop the top 2 values from the stack, compute `v1 ^ v2`, and push the
  /// result back onto the stack.
  bitXor,

  /// Pop the top 2 values from the stack, compute `v1 & v2`, and push the
  /// result back onto the stack.
  bitAnd,

  /// Pop the top 2 values from the stack, compute `v1 | v2`, and push the
  /// result back onto the stack.
  bitOr,

  /// Pop the top 2 values from the stack, compute `v1 >> v2`, and push the
  /// result back onto the stack.
  bitShiftRight,

  /// Pop the top 2 values from the stack, compute `v1 << v2`, and push the
  /// result back onto the stack.
  bitShiftLeft,

  /// Pop the top 2 values from the stack, compute `v1 + v2`, and push the
  /// result back onto the stack.
  add,

  /// Pop the top value from the stack, compute its integer negation, and push
  /// the result back onto the stack.
  negate,

  /// Pop the top 2 values from the stack, compute `v1 - v2`, and push the
  /// result back onto the stack.
  subtract,

  /// Pop the top 2 values from the stack, compute `v1 * v2`, and push the
  /// result back onto the stack.
  multiply,

  /// Pop the top 2 values from the stack, compute `v1 / v2`, and push the
  /// result back onto the stack.
  divide,

  /// Pop the top 2 values from the stack, compute `v1 ~/ v2`, and push the
  /// result back onto the stack.
  floorDivide,

  /// Pop the top 2 values from the stack, compute `v1 > v2`, and push the
  /// result back onto the stack.
  greater,

  /// Pop the top 2 values from the stack, compute `v1 < v2`, and push the
  /// result back onto the stack.
  less,

  /// Pop the top 2 values from the stack, compute `v1 >= v2`, and push the
  /// result back onto the stack.
  greaterEqual,

  /// Pop the top 2 values from the stack, compute `v1 <= v2`, and push the
  /// result back onto the stack.
  lessEqual,

  /// Pop the top 2 values from the stack, compute `v1 % v2`, and push the
  /// result back onto the stack.
  modulo,

  /// Pop the top 3 values from the stack, compute `v1 ? v2 : v3`, and push the
  /// result back onto the stack.
  conditional,

  /// Pop from the stack `value` and get the next `target` reference from
  /// [UnlinkedExpr.references] - a top-level variable (prefixed or not), an
  /// assignable field of a class (prefixed or not), or a sequence of getters
  /// ending with an assignable property `a.b.b.c.d.e`.  In general `a.b` cannot
  /// not be distinguished between: `a` is a prefix and `b` is a top-level
  /// variable; or `a` is an object and `b` is the name of a property.  Perform
  /// `reference op= value` where `op` is the next assignment operator from
  /// [UnlinkedExpr.assignmentOperators].  Push `value` back into the stack.
  ///
  /// If the assignment operator is a prefix/postfix increment/decrement, then
  /// `value` is not present in the stack, so it should not be popped and the
  /// corresponding value of the `target` after/before update is pushed into the
  /// stack instead.
  assignToRef,

  /// Pop from the stack `target` and `value`.  Get the name of the property
  /// from `UnlinkedConst.strings` and assign the `value` to the named property
  /// of the `target`.  This operation is used when we know that the `target`
  /// is an object reference expression, e.g. `new Foo().a.b.c` or `a.b[0].c.d`.
  /// Perform `target.property op= value` where `op` is the next assignment
  /// operator from [UnlinkedExpr.assignmentOperators].  Push `value` back into
  /// the stack.
  ///
  /// If the assignment operator is a prefix/postfix increment/decrement, then
  /// `value` is not present in the stack, so it should not be popped and the
  /// corresponding value of the `target` after/before update is pushed into the
  /// stack instead.
  assignToProperty,

  /// Pop from the stack `index`, `target` and `value`.  Perform
  /// `target[index] op= value`  where `op` is the next assignment operator from
  /// [UnlinkedExpr.assignmentOperators].  Push `value` back into the stack.
  ///
  /// If the assignment operator is a prefix/postfix increment/decrement, then
  /// `value` is not present in the stack, so it should not be popped and the
  /// corresponding value of the `target` after/before update is pushed into the
  /// stack instead.
  assignToIndex,

  /// Pop from the stack `index` and `target`.  Push into the stack the result
  /// of evaluation of `target[index]`.
  extractIndex,

  /// Pop the top `n` values from the stack (where `n` is obtained from
  /// [UnlinkedExpr.ints]) into a list (filled from the end) and take the next
  /// `n` values from [UnlinkedExpr.strings] and use the lists of names and
  /// values to create named arguments.  Then pop the top `m` values from the
  /// stack (where `m` is obtained from [UnlinkedExpr.ints]) into a list (filled
  /// from the end) and use them as positional arguments.  Use the lists of
  /// positional and names arguments to invoke a method (or a function) with
  /// the reference from [UnlinkedExpr.references].  If `k` is nonzero (where
  /// `k` is obtained from [UnlinkedExpr.ints]), obtain `k` type arguments from
  /// [UnlinkedExpr.references] and use them as generic type arguments for the
  /// aforementioned method or function.  Push the result of the invocation onto
  /// the stack.
  ///
  /// Arguments are skipped, and `0` are specified as the numbers of arguments
  /// on the stack, if the expression is not a constant. We store expression of
  /// variable initializers to perform top-level inference, and arguments are
  /// never used to infer types.
  ///
  /// In general `a.b` cannot not be distinguished between: `a` is a prefix and
  /// `b` is a top-level function; or `a` is an object and `b` is the name of a
  /// method.  This operation should be used for a sequence of identifiers
  /// `a.b.b.c.d.e` ending with an invokable result.
  invokeMethodRef,

  /// Pop the top `n` values from the stack (where `n` is obtained from
  /// [UnlinkedExpr.ints]) into a list (filled from the end) and take the next
  /// `n` values from [UnlinkedExpr.strings] and use the lists of names and
  /// values to create named arguments.  Then pop the top `m` values from the
  /// stack (where `m` is obtained from [UnlinkedExpr.ints]) into a list (filled
  /// from the end) and use them as positional arguments.  Use the lists of
  /// positional and names arguments to invoke the method with the name from
  /// [UnlinkedExpr.strings] of the target popped from the stack.  If `k` is
  /// nonzero (where `k` is obtained from [UnlinkedExpr.ints]), obtain `k` type
  /// arguments from [UnlinkedExpr.references] and use them as generic type
  /// arguments for the aforementioned method.  Push the result of the
  /// invocation onto the stack.
  ///
  /// Arguments are skipped, and `0` are specified as the numbers of arguments
  /// on the stack, if the expression is not a constant. We store expression of
  /// variable initializers to perform top-level inference, and arguments are
  /// never used to infer types.
  ///
  /// This operation should be used for invocation of a method invocation
  /// where `target` is known to be an object instance.
  invokeMethod,

  /// Begin a new cascade section.  Duplicate the top value of the stack.
  cascadeSectionBegin,

  /// End a new cascade section.  Pop the top value from the stack and throw it
  /// away.
  cascadeSectionEnd,

  /// Pop the top value from the stack and cast it to the type with reference
  /// from [UnlinkedExpr.references], push the result into the stack.
  typeCast,

  /// Pop the top value from the stack and check whether it is a subclass of the
  /// type with reference from [UnlinkedExpr.references], push the result into
  /// the stack.
  typeCheck,

  /// Pop the top value from the stack and raise an exception with this value.
  throwException,

  /// Obtain two values `n` and `m` from [UnlinkedExpr.ints].  Then, starting at
  /// the executable element for the expression being evaluated, if n > 0, pop
  /// to the nth enclosing function element.  Then, push the mth local function
  /// of that element onto the stack.
  pushLocalFunctionReference,

  /// Pop the top two values from the stack.  If the first value is non-null,
  /// keep it and discard the second.  Otherwise, keep the second and discard
  /// the first.
  ifNull,

  /// Pop the top value from the stack.  Treat it as a Future and await its
  /// completion.  Then push the awaited value onto the stack.
  await,

  /// Push an abstract value onto the stack. Abstract values mark the presence
  /// of a value, but whose details are not included.
  ///
  /// This is not used by the summary generators today, but it will be used to
  /// experiment with prunning the initializer expression tree, so only
  /// information that is necessary gets included in the output summary file.
  pushUntypedAbstract,

  /// Get the next type reference from [UnlinkedExpr.references] and push an
  /// abstract value onto the stack that has that type.
  ///
  /// Like [pushUntypedAbstract], this is also not used by the summary
  /// generators today. The plan is to experiment with prunning the initializer
  /// expression tree, and include just enough type information to perform
  /// strong-mode type inference, but not all the details of how this type was
  /// obtained.
  pushTypedAbstract,

  /// Push an error onto the stack.
  ///
  /// Like [pushUntypedAbstract], this is not used by summary generators today.
  /// This will be used to experiment with prunning the const expression tree.
  /// If a constant has an error, we can omit the subexpression containing the
  /// error and only include a marker that an error was detected.
  pushError,

  /// Push `this` expression onto the stack.
  pushThis,

  /// Push `super` expression onto the stack.
  pushSuper,

  /// Pop the top n values from the stack (where n is obtained from
  /// [UnlinkedExpr.ints]), place them in a [Set], and push the result back
  /// onto the stack.  The type parameter for the [Set] is implicitly
  /// `dynamic`.
  makeUntypedSet,

  /// Pop the top n values from the stack (where n is obtained from
  /// [UnlinkedExpr.ints]), place them in a [Set], and push the result back
  /// onto the stack.  The type parameter for the [Set] is obtained from
  /// [UnlinkedExpr.references].
  makeTypedSet,

  /// Pop the top n values from the stack (where n is obtained from
  /// [UnlinkedExpr.ints]), which should be [CollectionElement]s, place them in
  /// a [SetOrMap], and push the result back onto the stack.
  makeUntypedSetOrMap,

  /// Pop the top n values from the stack (where n is obtained from
  /// [UnlinkedExpr.ints]), which should be [CollectionElement]s, place them in
  /// a [Map], and push the result back onto the stack. The two type parameters
  /// for the [Map] are obtained from [UnlinkedExpr.references].
  ///
  /// To replace [makeTypedMap] for unified collections. This is not backwards
  /// compatible with [makeTypedMap] because it expects [CollectionElement]s
  /// instead of pairs of [Expression]s.
  makeTypedMap2,

  /// Pop the top 2 values from the stack, place them in a [MapLiteralEntry],
  /// and push the result back onto the stack.
  makeMapLiteralEntry,

  /// Pop the top value from the stack, convert it to a spread element of type
  /// `...`, and push the result back onto the stack.
  spreadElement,

  /// Pop the top value from the stack, convert it to a spread element of type
  /// `...?`, and push the result back onto the stack.
  nullAwareSpreadElement,

  /// Pop the top two values from the stack.  The first is a condition
  /// and the second is a collection element.  Push an "if" element having the
  /// given condition, with the collection element as its "then" clause.
  ifElement,

  /// Pop the top three values from the stack.  The first is a condition and the
  /// other two are collection elements.  Push an "if" element having the given
  /// condition, with the two collection elements as its "then" and "else"
  /// clauses, respectively.
  ifElseElement,

  /// Pop the top n+2 values from the stack, where n is obtained from
  /// [UnlinkedExpr.ints].  The first two are the initialization and condition
  /// of the for-loop; the remainder are the updaters.
  forParts,

  /// Pop the top 2 values from the stack.  The first is the for loop parts.
  /// The second is the body.
  forElement,

  /// Push the empty expression (used for missing initializers and conditions in
  /// `for` loops)
  pushEmptyExpression,

  /// Add a variable to the current scope whose name is obtained from
  /// [UnlinkedExpr.strings].  This is separate from [variableDeclaration]
  /// because the scope of the variable includes its own initializer.
  variableDeclarationStart,

  /// Pop the top value from the stack, and use it as the initializer for a
  /// variable declaration; the variable being declared is obtained by looking
  /// at the nth variable most recently added to the scope (where n counts from
  /// zero and is obtained from [UnlinkedExpr.ints]).
  variableDeclaration,

  /// Pop the top n values from the stack, which should all be variable
  /// declarations, and use them to create an untyped for-initializer
  /// declaration.  The value of n is obtained from [UnlinkedExpr.ints].
  forInitializerDeclarationsUntyped,

  /// Pop the top n values from the stack, which should all be variable
  /// declarations, and use them to create a typed for-initializer
  /// declaration.  The value of n is obtained from [UnlinkedExpr.ints].  The
  /// type is obtained from [UnlinkedExpr.references].
  forInitializerDeclarationsTyped,

  /// Pop from the stack `value` and get a string from [UnlinkedExpr.strings].
  /// Use this string to look up a parameter.  Perform `parameter op= value`,
  /// where `op` is the next assignment operator from
  /// [UnlinkedExpr.assignmentOperators].  Push `value` back onto the stack.
  ///
  /// If the assignment operator is a prefix/postfix increment/decrement, then
  /// `value` is not present in the stack, so it should not be popped and the
  /// corresponding value of the parameter after/before update is pushed onto
  /// the stack instead.
  assignToParameter,

  /// Pop from the stack an identifier and an expression, and create for-each
  /// parts of the form `identifier in expression`.
  forEachPartsWithIdentifier,

  /// Pop the top 2 values from the stack.  The first is the for loop parts.
  /// The second is the body.
  forElementWithAwait,

  /// Pop an expression from the stack, and create for-each parts of the form
  /// `var name in expression`, where `name` is obtained from
  /// [UnlinkedExpr.strings].
  forEachPartsWithUntypedDeclaration,

  /// Pop an expression from the stack, and create for-each parts of the form
  /// `Type name in expression`, where `name` is obtained from
  /// [UnlinkedExpr.strings], and `Type` is obtained from
  /// [UnlinkedExpr.references].
  forEachPartsWithTypedDeclaration,

  /// Pop the top 2 values from the stack, compute `v1 >>> v2`, and push the
  /// result back onto the stack.
  bitShiftRightLogical,
}

/// Unlinked summary information about an import declaration.
abstract class UnlinkedImport extends base.SummaryClass {
  /// Annotations for this import declaration.
  @Id(8)
  List<UnlinkedExpr> get annotations;

  /// Combinators contained in this import declaration.
  @Id(4)
  List<UnlinkedCombinator> get combinators;

  /// Configurations used to control which library will actually be loaded at
  /// run-time.
  @Id(10)
  List<UnlinkedConfiguration> get configurations;

  /// Indicates whether the import declaration uses the `deferred` keyword.
  @Id(9)
  bool get isDeferred;

  /// Indicates whether the import declaration is implicit.
  @Id(5)
  bool get isImplicit;

  /// If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
  /// is true, zero.
  @informative
  @Id(0)
  int get offset;

  /// Offset of the prefix name relative to the beginning of the file, or zero
  /// if there is no prefix.
  @informative
  @Id(6)
  int get prefixOffset;

  /// Index into [UnlinkedUnit.references] of the prefix declared by this
  /// import declaration, or zero if this import declaration declares no prefix.
  ///
  /// Note that multiple imports can declare the same prefix.
  @Id(7)
  int get prefixReference;

  /// URI used in the source code to reference the imported library.
  @Id(1)
  String get uri;

  /// End of the URI string (including quotes) relative to the beginning of the
  /// file.  If [isImplicit] is true, zero.
  @informative
  @Id(2)
  int get uriEnd;

  /// Offset of the URI string (including quotes) relative to the beginning of
  /// the file.  If [isImplicit] is true, zero.
  @informative
  @Id(3)
  int get uriOffset;
}

/// Unlinked summary information about a function parameter.
abstract class UnlinkedParam extends base.SummaryClass {
  /// Annotations for this parameter.
  @Id(9)
  List<UnlinkedExpr> get annotations;

  /// Code range of the parameter.
  @informative
  @Id(7)
  CodeRange get codeRange;

  /// If the parameter has a default value, the source text of the constant
  /// expression in the default value.  Otherwise the empty string.
  @informative
  @Id(13)
  String get defaultValueCode;

  /// If this parameter's type is inferable, nonzero slot id identifying which
  /// entry in [LinkedLibrary.types] contains the inferred type.  If there is no
  /// matching entry in [LinkedLibrary.types], then no type was inferred for
  /// this variable, so its static type is `dynamic`.
  ///
  /// Note that although strong mode considers initializing formals to be
  /// inferable, they are not marked as such in the summary; if their type is
  /// not specified, they always inherit the static type of the corresponding
  /// field.
  @Id(2)
  int get inferredTypeSlot;

  /// If this is a parameter of an instance method, a nonzero slot id which is
  /// unique within this compilation unit.  If this id is found in
  /// [LinkedUnit.parametersInheritingCovariant], then this parameter inherits
  /// `@covariant` behavior from a base class.
  ///
  /// Otherwise, zero.
  @Id(14)
  int get inheritsCovariantSlot;

  /// The synthetic initializer function of the parameter.  Absent if the
  /// variable does not have an initializer.
  @Id(12)
  UnlinkedExecutable get initializer;

  /// Indicates whether this parameter is explicitly marked as being covariant.
  @Id(15)
  bool get isExplicitlyCovariant;

  /// Indicates whether the parameter is declared using the `final` keyword.
  @Id(16)
  bool get isFinal;

  /// Indicates whether this is a function-typed parameter. A parameter is
  /// function-typed if the declaration of the parameter has explicit formal
  /// parameters
  /// ```
  /// int functionTyped(int p)
  /// ```
  /// but is not function-typed if it does not, even if the type of the
  /// parameter is a function type.
  @Id(5)
  bool get isFunctionTyped;

  /// Indicates whether this is an initializing formal parameter (i.e. it is
  /// declared using `this.` syntax).
  @Id(6)
  bool get isInitializingFormal;

  /// Kind of the parameter.
  @Id(4)
  UnlinkedParamKind get kind;

  /// Name of the parameter.
  @Id(0)
  String get name;

  /// Offset of the parameter name relative to the beginning of the file.
  @informative
  @Id(1)
  int get nameOffset;

  /// If [isFunctionTyped] is `true`, the parameters of the function type.
  @Id(8)
  List<UnlinkedParam> get parameters;

  /// If [isFunctionTyped] is `true`, the declared return type.  If
  /// [isFunctionTyped] is `false`, the declared type.  Absent if the type is
  /// implicit.
  @Id(3)
  EntityRef get type;

  /// The length of the visible range.
  @informative
  @Id(10)
  int get visibleLength;

  /// The beginning of the visible range.
  @informative
  @Id(11)
  int get visibleOffset;
}

/// Enum used to indicate the kind of a parameter.
enum UnlinkedParamKind {
  /// Parameter is required and positional.
  requiredPositional,

  /// Parameter is optional and positional (enclosed in `[]`)
  optionalPositional,

  /// Parameter is optional and named (enclosed in `{}`)
  optionalNamed,

  /// Parameter is required and named (enclosed in `{}`).
  requiredNamed
}

/// Unlinked summary information about a part declaration.
abstract class UnlinkedPart extends base.SummaryClass {
  /// Annotations for this part declaration.
  @Id(2)
  List<UnlinkedExpr> get annotations;

  /// End of the URI string (including quotes) relative to the beginning of the
  /// file.
  @informative
  @Id(0)
  int get uriEnd;

  /// Offset of the URI string (including quotes) relative to the beginning of
  /// the file.
  @informative
  @Id(1)
  int get uriOffset;
}

/// Unlinked summary information about a specific name contributed by a
/// compilation unit to a library's public namespace.
///
/// TODO(paulberry): some of this information is redundant with information
/// elsewhere in the summary.  Consider reducing the redundancy to reduce
/// summary size.
abstract class UnlinkedPublicName extends base.SummaryClass {
  /// The kind of object referred to by the name.
  @Id(1)
  ReferenceKind get kind;

  /// If this [UnlinkedPublicName] is a class, the list of members which can be
  /// referenced statically - static fields, static methods, and constructors.
  /// Otherwise empty.
  ///
  /// Unnamed constructors are not included since they do not constitute a
  /// separate name added to any namespace.
  @Id(2)
  List<UnlinkedPublicName> get members;

  /// The name itself.
  @Id(0)
  String get name;

  /// If the entity being referred to is generic, the number of type parameters
  /// it accepts.  Otherwise zero.
  @Id(3)
  int get numTypeParameters;
}

/// Unlinked summary information about what a compilation unit contributes to a
/// library's public namespace.  This is the subset of [UnlinkedUnit] that is
/// required from dependent libraries in order to perform prelinking.
@TopLevel('UPNS')
abstract class UnlinkedPublicNamespace extends base.SummaryClass {
  factory UnlinkedPublicNamespace.fromBuffer(List<int> buffer) =>
      generated.readUnlinkedPublicNamespace(buffer);

  /// Export declarations in the compilation unit.
  @Id(2)
  List<UnlinkedExportPublic> get exports;

  /// Public names defined in the compilation unit.
  ///
  /// TODO(paulberry): consider sorting these names to reduce unnecessary
  /// relinking.
  @Id(0)
  List<UnlinkedPublicName> get names;

  /// URIs referenced by part declarations in the compilation unit.
  @Id(1)
  List<String> get parts;
}

/// Unlinked summary information about a name referred to in one library that
/// might be defined in another.
abstract class UnlinkedReference extends base.SummaryClass {
  /// Name of the entity being referred to.  For the pseudo-type `dynamic`, the
  /// string is "dynamic".  For the pseudo-type `void`, the string is "void".
  /// For the pseudo-type `bottom`, the string is "*bottom*".
  @Id(0)
  String get name;

  /// Prefix used to refer to the entity, or zero if no prefix is used.  This is
  /// an index into [UnlinkedUnit.references].
  ///
  /// Prefix references must always point backward; that is, for all i, if
  /// UnlinkedUnit.references[i].prefixReference != 0, then
  /// UnlinkedUnit.references[i].prefixReference < i.
  @Id(1)
  int get prefixReference;
}

/// TODO(scheglov) document
enum UnlinkedTokenKind { nothing, comment, keyword, simple, string }

/// TODO(scheglov) document
abstract class UnlinkedTokens extends base.SummaryClass {
  /// The token that corresponds to this token, or `0` if this token is not
  /// the first of a pair of matching tokens (such as parentheses).
  @Id(0)
  List<int> get endGroup;

  /// Return `true` if this token is a synthetic token. A synthetic token is a
  /// token that was introduced by the parser in order to recover from an error
  /// in the code.
  @Id(1)
  List<bool> get isSynthetic;

  @Id(2)
  List<UnlinkedTokenKind> get kind;

  @Id(3)
  List<int> get length;

  @Id(4)
  List<String> get lexeme;

  /// The next token in the token stream, `0` for [UnlinkedTokenType.EOF] or
  /// the last comment token.
  @Id(5)
  List<int> get next;

  @Id(6)
  List<int> get offset;

  /// The first comment token in the list of comments that precede this token,
  /// or `0` if there are no comments preceding this token. Additional comments
  /// can be reached by following the token stream using [next] until `0` is
  /// reached.
  @Id(7)
  List<int> get precedingComment;

  @Id(8)
  List<UnlinkedTokenType> get type;
}

/// TODO(scheglov) document
enum UnlinkedTokenType {
  NOTHING,
  ABSTRACT,
  AMPERSAND,
  AMPERSAND_AMPERSAND,
  AMPERSAND_EQ,
  AS,
  ASSERT,
  ASYNC,
  AT,
  AWAIT,
  BACKPING,
  BACKSLASH,
  BANG,
  BANG_EQ,
  BANG_EQ_EQ,
  BAR,
  BAR_BAR,
  BAR_EQ,
  BREAK,
  CARET,
  CARET_EQ,
  CASE,
  CATCH,
  CLASS,
  CLOSE_CURLY_BRACKET,
  CLOSE_PAREN,
  CLOSE_SQUARE_BRACKET,
  COLON,
  COMMA,
  CONST,
  CONTINUE,
  COVARIANT,
  DEFAULT,
  DEFERRED,
  DO,
  DOUBLE,
  DYNAMIC,
  ELSE,
  ENUM,
  EOF,
  EQ,
  EQ_EQ,
  EQ_EQ_EQ,
  EXPORT,
  EXTENDS,
  EXTERNAL,
  FACTORY,
  FALSE,
  FINAL,
  FINALLY,
  FOR,
  FUNCTION,
  FUNCTION_KEYWORD,
  GET,
  GT,
  GT_EQ,
  GT_GT,
  GT_GT_EQ,
  GT_GT_GT,
  GT_GT_GT_EQ,
  HASH,
  HEXADECIMAL,
  HIDE,
  IDENTIFIER,
  IF,
  IMPLEMENTS,
  IMPORT,
  IN,
  INDEX,
  INDEX_EQ,
  INT,
  INTERFACE,
  IS,
  LATE,
  LIBRARY,
  LT,
  LT_EQ,
  LT_LT,
  LT_LT_EQ,
  MINUS,
  MINUS_EQ,
  MINUS_MINUS,
  MIXIN,
  MULTI_LINE_COMMENT,
  NATIVE,
  NEW,
  NULL,
  OF,
  ON,
  OPEN_CURLY_BRACKET,
  OPEN_PAREN,
  OPEN_SQUARE_BRACKET,
  OPERATOR,
  PART,
  PATCH,
  PERCENT,
  PERCENT_EQ,
  PERIOD,
  PERIOD_PERIOD,
  PERIOD_PERIOD_PERIOD,
  PERIOD_PERIOD_PERIOD_QUESTION,
  PLUS,
  PLUS_EQ,
  PLUS_PLUS,
  QUESTION,
  QUESTION_PERIOD,
  QUESTION_QUESTION,
  QUESTION_QUESTION_EQ,
  REQUIRED,
  RETHROW,
  RETURN,
  SCRIPT_TAG,
  SEMICOLON,
  SET,
  SHOW,
  SINGLE_LINE_COMMENT,
  SLASH,
  SLASH_EQ,
  SOURCE,
  STAR,
  STAR_EQ,
  STATIC,
  STRING,
  STRING_INTERPOLATION_EXPRESSION,
  STRING_INTERPOLATION_IDENTIFIER,
  SUPER,
  SWITCH,
  SYNC,
  THIS,
  THROW,
  TILDE,
  TILDE_SLASH,
  TILDE_SLASH_EQ,
  TRUE,
  TRY,
  TYPEDEF,
  VAR,
  VOID,
  WHILE,
  WITH,
  YIELD,
}

/// Unlinked summary information about a typedef declaration.
abstract class UnlinkedTypedef extends base.SummaryClass {
  /// Annotations for this typedef.
  @Id(4)
  List<UnlinkedExpr> get annotations;

  /// Code range of the typedef.
  @informative
  @Id(7)
  CodeRange get codeRange;

  /// Documentation comment for the typedef, or `null` if there is no
  /// documentation comment.
  @informative
  @Id(6)
  UnlinkedDocumentationComment get documentationComment;

  /// Name of the typedef.
  @Id(0)
  String get name;

  /// Offset of the typedef name relative to the beginning of the file.
  @informative
  @Id(1)
  int get nameOffset;

  /// If the typedef might not be simply bounded, a nonzero slot id which is
  /// unique within this compilation unit.  If this id is found in
  /// [LinkedUnit.notSimplyBounded], then at least one of this typedef's type
  /// parameters is not simply bounded, hence this typedef can't be used as a
  /// raw type when specifying the bound of a type parameter.
  ///
  /// Otherwise, zero.
  @Id(9)
  int get notSimplyBoundedSlot;

  /// Parameters of the executable, if any.
  @Id(3)
  List<UnlinkedParam> get parameters;

  /// If [style] is [TypedefStyle.functionType], the return type of the typedef.
  /// If [style] is [TypedefStyle.genericFunctionType], the function type being
  /// defined.
  @Id(2)
  EntityRef get returnType;

  /// The style of the typedef.
  @Id(8)
  TypedefStyle get style;

  /// Type parameters of the typedef, if any.
  @Id(5)
  List<UnlinkedTypeParam> get typeParameters;
}

/// Unlinked summary information about a type parameter declaration.
abstract class UnlinkedTypeParam extends base.SummaryClass {
  /// Annotations for this type parameter.
  @Id(3)
  List<UnlinkedExpr> get annotations;

  /// Bound of the type parameter, if a bound is explicitly declared.  Otherwise
  /// null.
  @Id(2)
  EntityRef get bound;

  /// Code range of the type parameter.
  @informative
  @Id(4)
  CodeRange get codeRange;

  /// Name of the type parameter.
  @Id(0)
  String get name;

  /// Offset of the type parameter name relative to the beginning of the file.
  @informative
  @Id(1)
  int get nameOffset;
}

/// Unlinked summary information about a compilation unit ("part file").
@TopLevel('UUnt')
abstract class UnlinkedUnit extends base.SummaryClass {
  factory UnlinkedUnit.fromBuffer(List<int> buffer) =>
      generated.readUnlinkedUnit(buffer);

  /// MD5 hash of the non-informative fields of the [UnlinkedUnit] (not
  /// including this one) as 16 unsigned 8-bit integer values.  This can be used
  /// to identify when the API of a unit may have changed.
  @Id(19)
  List<int> get apiSignature;

  /// Classes declared in the compilation unit.
  @Id(2)
  List<UnlinkedClass> get classes;

  /// Code range of the unit.
  @informative
  @Id(15)
  CodeRange get codeRange;

  /// Enums declared in the compilation unit.
  @Id(12)
  List<UnlinkedEnum> get enums;

  /// Top level executable objects (functions, getters, and setters) declared in
  /// the compilation unit.
  @Id(4)
  List<UnlinkedExecutable> get executables;

  /// Export declarations in the compilation unit.
  @Id(13)
  List<UnlinkedExportNonPublic> get exports;

  /// If this compilation unit was summarized in fallback mode, the path where
  /// the compilation unit may be found on disk.  Otherwise empty.
  ///
  /// When this field is non-empty, all other fields in the data structure have
  /// their default values.
  @deprecated
  @Id(16)
  String get fallbackModePath;

  /// Import declarations in the compilation unit.
  @Id(5)
  List<UnlinkedImport> get imports;

  /// Indicates whether the unit contains a "part of" declaration.
  @Id(18)
  bool get isPartOf;

  /// Annotations for the library declaration, or the empty list if there is no
  /// library declaration.
  @Id(14)
  List<UnlinkedExpr> get libraryAnnotations;

  /// Documentation comment for the library, or `null` if there is no
  /// documentation comment.
  @informative
  @Id(9)
  UnlinkedDocumentationComment get libraryDocumentationComment;

  /// Name of the library (from a "library" declaration, if present).
  @Id(6)
  String get libraryName;

  /// Length of the library name as it appears in the source code (or 0 if the
  /// library has no name).
  @informative
  @Id(7)
  int get libraryNameLength;

  /// Offset of the library name relative to the beginning of the file (or 0 if
  /// the library has no name).
  @informative
  @Id(8)
  int get libraryNameOffset;

  /// Offsets of the first character of each line in the source code.
  @informative
  @Id(17)
  List<int> get lineStarts;

  /// Mixins declared in the compilation unit.
  @Id(20)
  List<UnlinkedClass> get mixins;

  /// Part declarations in the compilation unit.
  @Id(11)
  List<UnlinkedPart> get parts;

  /// Unlinked public namespace of this compilation unit.
  @Id(0)
  UnlinkedPublicNamespace get publicNamespace;

  /// Top level and prefixed names referred to by this compilation unit.  The
  /// zeroth element of this array is always populated and is used to represent
  /// the absence of a reference in places where a reference is optional (for
  /// example [UnlinkedReference.prefixReference or
  /// UnlinkedImport.prefixReference]).
  @Id(1)
  List<UnlinkedReference> get references;

  /// Typedefs declared in the compilation unit.
  @Id(10)
  List<UnlinkedTypedef> get typedefs;

  /// Top level variables declared in the compilation unit.
  @Id(3)
  List<UnlinkedVariable> get variables;
}

/// Unlinked summary information about a compilation unit.
@TopLevel('UUN2')
abstract class UnlinkedUnit2 extends base.SummaryClass {
  factory UnlinkedUnit2.fromBuffer(List<int> buffer) =>
      generated.readUnlinkedUnit2(buffer);

  /// The MD5 hash signature of the API portion of this unit. It depends on all
  /// tokens that might affect APIs of declarations in the unit.
  @Id(0)
  List<int> get apiSignature;

  /// URIs of `export` directives.
  @Id(1)
  List<String> get exports;

  /// URIs of `import` directives.
  @Id(2)
  List<String> get imports;

  /// Is `true` if the unit contains a `part of` directive.
  @Id(3)
  bool get isPartOf;

  /// Offsets of the first character of each line in the source code.
  @informative
  @Id(5)
  List<int> get lineStarts;

  /// URIs of `part` directives.
  @Id(4)
  List<String> get parts;
}

/// Unlinked summary information about a top level variable, local variable, or
/// a field.
abstract class UnlinkedVariable extends base.SummaryClass {
  /// Annotations for this variable.
  @Id(8)
  List<UnlinkedExpr> get annotations;

  /// Code range of the variable.
  @informative
  @Id(5)
  CodeRange get codeRange;

  /// Documentation comment for the variable, or `null` if there is no
  /// documentation comment.
  @informative
  @Id(10)
  UnlinkedDocumentationComment get documentationComment;

  /// If this variable is inferable, nonzero slot id identifying which entry in
  /// [LinkedLibrary.types] contains the inferred type for this variable.  If
  /// there is no matching entry in [LinkedLibrary.types], then no type was
  /// inferred for this variable, so its static type is `dynamic`.
  @Id(9)
  int get inferredTypeSlot;

  /// If this is an instance non-final field, a nonzero slot id which is unique
  /// within this compilation unit.  If this id is found in
  /// [LinkedUnit.parametersInheritingCovariant], then the parameter of the
  /// synthetic setter inherits `@covariant` behavior from a base class.
  ///
  /// Otherwise, zero.
  @Id(15)
  int get inheritsCovariantSlot;

  /// The synthetic initializer function of the variable.  Absent if the
  /// variable does not have an initializer.
  @Id(13)
  UnlinkedExecutable get initializer;

  /// Indicates whether the variable is declared using the `const` keyword.
  @Id(6)
  bool get isConst;

  /// Indicates whether this variable is declared using the `covariant` keyword.
  /// This should be false for everything except instance fields.
  @Id(14)
  bool get isCovariant;

  /// Indicates whether the variable is declared using the `final` keyword.
  @Id(7)
  bool get isFinal;

  /// Indicates whether the variable is declared using the `late` keyword.
  @Id(16)
  bool get isLate;

  /// Indicates whether the variable is declared using the `static` keyword.
  ///
  /// Note that for top level variables, this flag is false, since they are not
  /// declared using the `static` keyword (even though they are considered
  /// static for semantic purposes).
  @Id(4)
  bool get isStatic;

  /// Name of the variable.
  @Id(0)
  String get name;

  /// Offset of the variable name relative to the beginning of the file.
  @informative
  @Id(1)
  int get nameOffset;

  /// If this variable is propagable, nonzero slot id identifying which entry in
  /// [LinkedLibrary.types] contains the propagated type for this variable.  If
  /// there is no matching entry in [LinkedLibrary.types], then this variable's
  /// propagated type is the same as its declared type.
  ///
  /// Non-propagable variables have a [propagatedTypeSlot] of zero.
  @Id(2)
  int get propagatedTypeSlot;

  /// Declared type of the variable.  Absent if the type is implicit.
  @Id(3)
  EntityRef get type;

  /// If a local variable, the length of the visible range; zero otherwise.
  @deprecated
  @informative
  @Id(11)
  int get visibleLength;

  /// If a local variable, the beginning of the visible range; zero otherwise.
  @deprecated
  @informative
  @Id(12)
  int get visibleOffset;
}
