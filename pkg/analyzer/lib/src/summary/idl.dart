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
  /// The context messages associated with the error.
  @Id(5)
  List<DiagnosticMessage> get contextMessages;

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
  @Id(2)
  List<String> get definedClassMemberNames;

  /// List of top-level names defined by the unit.
  @Id(1)
  List<String> get definedTopLevelNames;

  /// List of external names referenced by the unit.
  @Id(0)
  List<String> get referencedNames;

  /// List of names which are used in `extends`, `with` or `implements` clauses
  /// in the file. Import prefixes and type arguments are not included.
  @Id(3)
  List<String> get subtypedNames;

  /// Unlinked information for the unit.
  @Id(4)
  UnlinkedUnit2 get unit2;
}

/// Information about a single declaration.
abstract class AvailableDeclaration extends base.SummaryClass {
  @Id(0)
  List<AvailableDeclaration> get children;

  @Id(1)
  int get codeLength;

  @Id(2)
  int get codeOffset;

  @Id(3)
  String get defaultArgumentListString;

  @Id(4)
  List<int> get defaultArgumentListTextRanges;

  @Id(5)
  String get docComplete;

  @Id(6)
  String get docSummary;

  @Id(7)
  int get fieldMask;

  @Id(8)
  bool get isAbstract;

  @Id(9)
  bool get isConst;

  @Id(10)
  bool get isDeprecated;

  @Id(11)
  bool get isFinal;

  @Id(12)
  bool get isStatic;

  /// The kind of the declaration.
  @Id(13)
  AvailableDeclarationKind get kind;

  @Id(14)
  int get locationOffset;

  @Id(15)
  int get locationStartColumn;

  @Id(16)
  int get locationStartLine;

  /// The first part of the declaration name, usually the only one, for example
  /// the name of a class like `MyClass`, or a function like `myFunction`.
  @Id(17)
  String get name;

  @Id(18)
  List<String> get parameterNames;

  @Id(19)
  String get parameters;

  @Id(20)
  List<String> get parameterTypes;

  /// The partial list of relevance tags.  Not every declaration has one (for
  /// example, function do not currently), and not every declaration has to
  /// store one (for classes it can be computed when we know the library that
  /// includes this file).
  @Id(21)
  List<String> get relevanceTags;

  @Id(22)
  int get requiredParameterCount;

  @Id(23)
  String get returnType;

  @Id(24)
  String get typeParameters;
}

/// Enum of declaration kinds in available files.
enum AvailableDeclarationKind {
  CLASS,
  CLASS_TYPE_ALIAS,
  CONSTRUCTOR,
  ENUM,
  ENUM_CONSTANT,
  EXTENSION,
  FIELD,
  FUNCTION,
  FUNCTION_TYPE_ALIAS,
  GETTER,
  METHOD,
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
  @Id(1)
  DirectiveInfo get directiveInfo;

  /// Exports directives of the file.
  @Id(2)
  List<AvailableFileExport> get exports;

  /// Is `true` if this file is a library.
  @Id(3)
  bool get isLibrary;

  /// Is `true` if this file is a library, and it is deprecated.
  @Id(4)
  bool get isLibraryDeprecated;

  /// Offsets of the first character of each line in the source code.
  @informative
  @Id(5)
  List<int> get lineStarts;

  /// URIs of `part` directives.
  @Id(6)
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

/// Information about linked libraries, a group of libraries that form
/// a library cycle.
@TopLevel('CLNB')
abstract class CiderLinkedLibraryCycle extends base.SummaryClass {
  factory CiderLinkedLibraryCycle.fromBuffer(List<int> buffer) =>
      generated.readCiderLinkedLibraryCycle(buffer);

  @Id(1)
  LinkedNodeBundle get bundle;

  /// The hash signature for this linked cycle. It depends of API signatures
  /// of all files in the cycle, and on the signatures of the transitive
  /// closure of the cycle dependencies.
  @Id(0)
  List<int> get signature;
}

/// Errors for a single unit.
@TopLevel('CUEr')
abstract class CiderUnitErrors extends base.SummaryClass {
  factory CiderUnitErrors.fromBuffer(List<int> buffer) =>
      generated.readCiderUnitErrors(buffer);

  @Id(1)
  List<AnalysisDriverUnitError> get errors;

  /// The hash signature of this data.
  @Id(0)
  List<int> get signature;
}

/// Information about a compilation unit, contains the content hash
/// and unlinked summary.
@TopLevel('CUUN')
abstract class CiderUnlinkedUnit extends base.SummaryClass {
  factory CiderUnlinkedUnit.fromBuffer(List<int> buffer) =>
      generated.readCiderUnlinkedUnit(buffer);

  /// The hash signature of the contents of the file.
  @Id(0)
  List<int> get contentDigest;

  /// Unlinked summary of the compilation unit.
  @Id(1)
  UnlinkedUnit2 get unlinkedUnit;
}

abstract class DiagnosticMessage extends base.SummaryClass {
  /// The absolute and normalized path of the file associated with this message.
  @Id(0)
  String get filePath;

  /// The length of the source range associated with this message.
  @Id(1)
  int get length;

  /// The text of the message.
  @Id(2)
  String get message;

  /// The zero-based offset from the start of the file to the beginning of the
  /// source range associated with this message.
  @Id(3)
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

abstract class LinkedLanguageVersion extends base.SummaryClass {
  @Id(0)
  int get major;

  @Id(1)
  int get minor;
}

abstract class LinkedLibraryLanguageVersion extends base.SummaryClass {
  @Id(1)
  LinkedLanguageVersion get override2;

  @Id(0)
  LinkedLanguageVersion get package;
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

  @VariantId(4, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.declaredIdentifier,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.enumConstantDeclaration,
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.extensionDeclaration,
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

  @VariantId(7, variant: LinkedNodeKind.annotation)
  LinkedNode get annotation_constructorName;

  @VariantId(17, variant: LinkedNodeKind.annotation)
  int get annotation_element;

  @VariantId(8, variant: LinkedNodeKind.annotation)
  LinkedNode get annotation_name;

  @VariantId(38, variant: LinkedNodeKind.annotation)
  LinkedNodeTypeSubstitution get annotation_substitution;

  @VariantId(2, variant: LinkedNodeKind.argumentList)
  List<LinkedNode> get argumentList_arguments;

  @VariantId(6, variant: LinkedNodeKind.asExpression)
  LinkedNode get asExpression_expression;

  @VariantId(7, variant: LinkedNodeKind.asExpression)
  LinkedNode get asExpression_type;

  @VariantId(6, variant: LinkedNodeKind.assertInitializer)
  LinkedNode get assertInitializer_condition;

  @VariantId(7, variant: LinkedNodeKind.assertInitializer)
  LinkedNode get assertInitializer_message;

  @VariantId(6, variant: LinkedNodeKind.assertStatement)
  LinkedNode get assertStatement_condition;

  @VariantId(7, variant: LinkedNodeKind.assertStatement)
  LinkedNode get assertStatement_message;

  @VariantId(15, variant: LinkedNodeKind.assignmentExpression)
  int get assignmentExpression_element;

  @VariantId(6, variant: LinkedNodeKind.assignmentExpression)
  LinkedNode get assignmentExpression_leftHandSide;

  @VariantId(28, variant: LinkedNodeKind.assignmentExpression)
  UnlinkedTokenType get assignmentExpression_operator;

  @VariantId(7, variant: LinkedNodeKind.assignmentExpression)
  LinkedNode get assignmentExpression_rightHandSide;

  @VariantId(38, variant: LinkedNodeKind.assignmentExpression)
  LinkedNodeTypeSubstitution get assignmentExpression_substitution;

  @VariantId(6, variant: LinkedNodeKind.awaitExpression)
  LinkedNode get awaitExpression_expression;

  @VariantId(15, variant: LinkedNodeKind.binaryExpression)
  int get binaryExpression_element;

  @VariantId(24, variant: LinkedNodeKind.binaryExpression)
  LinkedNodeType get binaryExpression_invokeType;

  @VariantId(6, variant: LinkedNodeKind.binaryExpression)
  LinkedNode get binaryExpression_leftOperand;

  @VariantId(28, variant: LinkedNodeKind.binaryExpression)
  UnlinkedTokenType get binaryExpression_operator;

  @VariantId(7, variant: LinkedNodeKind.binaryExpression)
  LinkedNode get binaryExpression_rightOperand;

  @VariantId(38, variant: LinkedNodeKind.binaryExpression)
  LinkedNodeTypeSubstitution get binaryExpression_substitution;

  @VariantId(2, variant: LinkedNodeKind.block)
  List<LinkedNode> get block_statements;

  @VariantId(6, variant: LinkedNodeKind.blockFunctionBody)
  LinkedNode get blockFunctionBody_block;

  @VariantId(27, variant: LinkedNodeKind.booleanLiteral)
  bool get booleanLiteral_value;

  @VariantId(6, variant: LinkedNodeKind.breakStatement)
  LinkedNode get breakStatement_label;

  @VariantId(2, variant: LinkedNodeKind.cascadeExpression)
  List<LinkedNode> get cascadeExpression_sections;

  @VariantId(6, variant: LinkedNodeKind.cascadeExpression)
  LinkedNode get cascadeExpression_target;

  @VariantId(6, variant: LinkedNodeKind.catchClause)
  LinkedNode get catchClause_body;

  @VariantId(7, variant: LinkedNodeKind.catchClause)
  LinkedNode get catchClause_exceptionParameter;

  @VariantId(8, variant: LinkedNodeKind.catchClause)
  LinkedNode get catchClause_exceptionType;

  @VariantId(9, variant: LinkedNodeKind.catchClause)
  LinkedNode get catchClause_stackTraceParameter;

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

  @VariantId(5, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.mixinDeclaration,
  ])
  List<LinkedNode> get classOrMixinDeclaration_members;

  @VariantId(13, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.mixinDeclaration,
  ])
  LinkedNode get classOrMixinDeclaration_typeParameters;

  @VariantId(9, variant: LinkedNodeKind.classTypeAlias)
  LinkedNode get classTypeAlias_implementsClause;

  @VariantId(7, variant: LinkedNodeKind.classTypeAlias)
  LinkedNode get classTypeAlias_superclass;

  @VariantId(6, variant: LinkedNodeKind.classTypeAlias)
  LinkedNode get classTypeAlias_typeParameters;

  @VariantId(8, variant: LinkedNodeKind.classTypeAlias)
  LinkedNode get classTypeAlias_withClause;

  @VariantId(2, variant: LinkedNodeKind.comment)
  List<LinkedNode> get comment_references;

  @VariantId(33, variant: LinkedNodeKind.comment)
  List<String> get comment_tokens;

  @VariantId(29, variant: LinkedNodeKind.comment)
  LinkedNodeCommentType get comment_type;

  @VariantId(6, variant: LinkedNodeKind.commentReference)
  LinkedNode get commentReference_identifier;

  @VariantId(2, variant: LinkedNodeKind.compilationUnit)
  List<LinkedNode> get compilationUnit_declarations;

  @VariantId(3, variant: LinkedNodeKind.compilationUnit)
  List<LinkedNode> get compilationUnit_directives;

  /// The language version information.
  @VariantId(40, variant: LinkedNodeKind.compilationUnit)
  LinkedLibraryLanguageVersion get compilationUnit_languageVersion;

  @VariantId(6, variant: LinkedNodeKind.compilationUnit)
  LinkedNode get compilationUnit_scriptTag;

  @VariantId(6, variant: LinkedNodeKind.conditionalExpression)
  LinkedNode get conditionalExpression_condition;

  @VariantId(7, variant: LinkedNodeKind.conditionalExpression)
  LinkedNode get conditionalExpression_elseExpression;

  @VariantId(8, variant: LinkedNodeKind.conditionalExpression)
  LinkedNode get conditionalExpression_thenExpression;

  @VariantId(6, variant: LinkedNodeKind.configuration)
  LinkedNode get configuration_name;

  @VariantId(8, variant: LinkedNodeKind.configuration)
  LinkedNode get configuration_uri;

  @VariantId(7, variant: LinkedNodeKind.configuration)
  LinkedNode get configuration_value;

  @VariantId(6, variant: LinkedNodeKind.constructorDeclaration)
  LinkedNode get constructorDeclaration_body;

  @VariantId(2, variant: LinkedNodeKind.constructorDeclaration)
  List<LinkedNode> get constructorDeclaration_initializers;

  @VariantId(8, variant: LinkedNodeKind.constructorDeclaration)
  LinkedNode get constructorDeclaration_parameters;

  @VariantId(9, variant: LinkedNodeKind.constructorDeclaration)
  LinkedNode get constructorDeclaration_redirectedConstructor;

  @VariantId(10, variant: LinkedNodeKind.constructorDeclaration)
  LinkedNode get constructorDeclaration_returnType;

  @VariantId(6, variant: LinkedNodeKind.constructorFieldInitializer)
  LinkedNode get constructorFieldInitializer_expression;

  @VariantId(7, variant: LinkedNodeKind.constructorFieldInitializer)
  LinkedNode get constructorFieldInitializer_fieldName;

  @VariantId(15, variant: LinkedNodeKind.constructorName)
  int get constructorName_element;

  @VariantId(6, variant: LinkedNodeKind.constructorName)
  LinkedNode get constructorName_name;

  @VariantId(38, variant: LinkedNodeKind.constructorName)
  LinkedNodeTypeSubstitution get constructorName_substitution;

  @VariantId(7, variant: LinkedNodeKind.constructorName)
  LinkedNode get constructorName_type;

  @VariantId(6, variant: LinkedNodeKind.continueStatement)
  LinkedNode get continueStatement_label;

  @VariantId(6, variant: LinkedNodeKind.declaredIdentifier)
  LinkedNode get declaredIdentifier_identifier;

  @VariantId(7, variant: LinkedNodeKind.declaredIdentifier)
  LinkedNode get declaredIdentifier_type;

  @VariantId(6, variant: LinkedNodeKind.defaultFormalParameter)
  LinkedNode get defaultFormalParameter_defaultValue;

  @VariantId(26, variant: LinkedNodeKind.defaultFormalParameter)
  LinkedNodeFormalParameterKind get defaultFormalParameter_kind;

  @VariantId(7, variant: LinkedNodeKind.defaultFormalParameter)
  LinkedNode get defaultFormalParameter_parameter;

  @VariantId(6, variant: LinkedNodeKind.doStatement)
  LinkedNode get doStatement_body;

  @VariantId(7, variant: LinkedNodeKind.doStatement)
  LinkedNode get doStatement_condition;

  @VariantId(2, variant: LinkedNodeKind.dottedName)
  List<LinkedNode> get dottedName_components;

  @VariantId(21, variant: LinkedNodeKind.doubleLiteral)
  double get doubleLiteral_value;

  @VariantId(15, variant: LinkedNodeKind.emptyFunctionBody)
  int get emptyFunctionBody_fake;

  @VariantId(15, variant: LinkedNodeKind.emptyStatement)
  int get emptyStatement_fake;

  @VariantId(2, variant: LinkedNodeKind.enumDeclaration)
  List<LinkedNode> get enumDeclaration_constants;

  @VariantId(25, variantList: [
    LinkedNodeKind.assignmentExpression,
    LinkedNodeKind.asExpression,
    LinkedNodeKind.awaitExpression,
    LinkedNodeKind.binaryExpression,
    LinkedNodeKind.cascadeExpression,
    LinkedNodeKind.conditionalExpression,
    LinkedNodeKind.functionExpressionInvocation,
    LinkedNodeKind.indexExpression,
    LinkedNodeKind.instanceCreationExpression,
    LinkedNodeKind.integerLiteral,
    LinkedNodeKind.listLiteral,
    LinkedNodeKind.methodInvocation,
    LinkedNodeKind.nullLiteral,
    LinkedNodeKind.parenthesizedExpression,
    LinkedNodeKind.prefixExpression,
    LinkedNodeKind.prefixedIdentifier,
    LinkedNodeKind.propertyAccess,
    LinkedNodeKind.postfixExpression,
    LinkedNodeKind.rethrowExpression,
    LinkedNodeKind.setOrMapLiteral,
    LinkedNodeKind.simpleIdentifier,
    LinkedNodeKind.superExpression,
    LinkedNodeKind.symbolLiteral,
    LinkedNodeKind.thisExpression,
    LinkedNodeKind.throwExpression,
  ])
  LinkedNodeType get expression_type;

  @VariantId(6, variant: LinkedNodeKind.expressionFunctionBody)
  LinkedNode get expressionFunctionBody_expression;

  @VariantId(6, variant: LinkedNodeKind.expressionStatement)
  LinkedNode get expressionStatement_expression;

  @VariantId(6, variant: LinkedNodeKind.extendsClause)
  LinkedNode get extendsClause_superclass;

  @VariantId(7, variant: LinkedNodeKind.extensionDeclaration)
  LinkedNode get extensionDeclaration_extendedType;

  @VariantId(5, variant: LinkedNodeKind.extensionDeclaration)
  List<LinkedNode> get extensionDeclaration_members;

  @VariantId(20, variant: LinkedNodeKind.extensionDeclaration)
  String get extensionDeclaration_refName;

  @VariantId(6, variant: LinkedNodeKind.extensionDeclaration)
  LinkedNode get extensionDeclaration_typeParameters;

  @VariantId(2, variant: LinkedNodeKind.extensionOverride)
  List<LinkedNode> get extensionOverride_arguments;

  @VariantId(24, variant: LinkedNodeKind.extensionOverride)
  LinkedNodeType get extensionOverride_extendedType;

  @VariantId(7, variant: LinkedNodeKind.extensionOverride)
  LinkedNode get extensionOverride_extensionName;

  @VariantId(8, variant: LinkedNodeKind.extensionOverride)
  LinkedNode get extensionOverride_typeArguments;

  @VariantId(39, variant: LinkedNodeKind.extensionOverride)
  List<LinkedNodeType> get extensionOverride_typeArgumentTypes;

  @VariantId(6, variant: LinkedNodeKind.fieldDeclaration)
  LinkedNode get fieldDeclaration_fields;

  @VariantId(8, variant: LinkedNodeKind.fieldFormalParameter)
  LinkedNode get fieldFormalParameter_formalParameters;

  @VariantId(6, variant: LinkedNodeKind.fieldFormalParameter)
  LinkedNode get fieldFormalParameter_type;

  @VariantId(7, variant: LinkedNodeKind.fieldFormalParameter)
  LinkedNode get fieldFormalParameter_typeParameters;

  @Id(18)
  int get flags;

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

  @VariantId(2, variant: LinkedNodeKind.formalParameterList)
  List<LinkedNode> get formalParameterList_parameters;

  @VariantId(6, variantList: [
    LinkedNodeKind.forElement,
    LinkedNodeKind.forStatement,
  ])
  LinkedNode get forMixin_forLoopParts;

  @VariantId(6, variantList: [
    LinkedNodeKind.forPartsWithDeclarations,
    LinkedNodeKind.forPartsWithExpression,
  ])
  LinkedNode get forParts_condition;

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

  @VariantId(6, variant: LinkedNodeKind.functionDeclaration)
  LinkedNode get functionDeclaration_functionExpression;

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

  @VariantId(17, variant: LinkedNodeKind.genericFunctionType)
  int get genericFunctionType_id;

  @VariantId(7, variant: LinkedNodeKind.genericFunctionType)
  LinkedNode get genericFunctionType_returnType;

  @VariantId(25, variant: LinkedNodeKind.genericFunctionType)
  LinkedNodeType get genericFunctionType_type;

  @VariantId(6, variant: LinkedNodeKind.genericFunctionType)
  LinkedNode get genericFunctionType_typeParameters;

  @VariantId(7, variant: LinkedNodeKind.genericTypeAlias)
  LinkedNode get genericTypeAlias_functionType;

  @VariantId(6, variant: LinkedNodeKind.genericTypeAlias)
  LinkedNode get genericTypeAlias_typeParameters;

  @VariantId(9, variant: LinkedNodeKind.ifElement)
  LinkedNode get ifElement_elseElement;

  @VariantId(8, variant: LinkedNodeKind.ifElement)
  LinkedNode get ifElement_thenElement;

  @VariantId(6, variantList: [
    LinkedNodeKind.ifElement,
    LinkedNodeKind.ifStatement,
  ])
  LinkedNode get ifMixin_condition;

  @VariantId(7, variant: LinkedNodeKind.ifStatement)
  LinkedNode get ifStatement_elseStatement;

  @VariantId(8, variant: LinkedNodeKind.ifStatement)
  LinkedNode get ifStatement_thenStatement;

  @VariantId(2, variant: LinkedNodeKind.implementsClause)
  List<LinkedNode> get implementsClause_interfaces;

  @VariantId(1, variant: LinkedNodeKind.importDirective)
  String get importDirective_prefix;

  @VariantId(15, variant: LinkedNodeKind.indexExpression)
  int get indexExpression_element;

  @VariantId(6, variant: LinkedNodeKind.indexExpression)
  LinkedNode get indexExpression_index;

  @VariantId(38, variant: LinkedNodeKind.indexExpression)
  LinkedNodeTypeSubstitution get indexExpression_substitution;

  @VariantId(7, variant: LinkedNodeKind.indexExpression)
  LinkedNode get indexExpression_target;

  @VariantId(36, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.compilationUnit,
    LinkedNodeKind.compilationUnit,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.defaultFormalParameter,
    LinkedNodeKind.enumConstantDeclaration,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.extensionDeclaration,
    LinkedNodeKind.fieldDeclaration,
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionDeclaration,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
    LinkedNodeKind.hideCombinator,
    LinkedNodeKind.importDirective,
    LinkedNodeKind.libraryDirective,
    LinkedNodeKind.methodDeclaration,
    LinkedNodeKind.mixinDeclaration,
    LinkedNodeKind.partDirective,
    LinkedNodeKind.partOfDirective,
    LinkedNodeKind.showCombinator,
    LinkedNodeKind.simpleFormalParameter,
    LinkedNodeKind.topLevelVariableDeclaration,
    LinkedNodeKind.typeParameter,
    LinkedNodeKind.variableDeclaration,
    LinkedNodeKind.variableDeclarationList,
  ])
  @informative
  int get informativeId;

  @VariantId(27, variantList: [
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.simpleFormalParameter,
    LinkedNodeKind.variableDeclaration,
  ])
  bool get inheritsCovariant;

  @VariantId(2, variant: LinkedNodeKind.instanceCreationExpression)
  List<LinkedNode> get instanceCreationExpression_arguments;

  @VariantId(7, variant: LinkedNodeKind.instanceCreationExpression)
  LinkedNode get instanceCreationExpression_constructorName;

  @VariantId(8, variant: LinkedNodeKind.instanceCreationExpression)
  LinkedNode get instanceCreationExpression_typeArguments;

  @VariantId(16, variant: LinkedNodeKind.integerLiteral)
  int get integerLiteral_value;

  @VariantId(6, variant: LinkedNodeKind.interpolationExpression)
  LinkedNode get interpolationExpression_expression;

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

  @VariantId(7, variant: LinkedNodeKind.isExpression)
  LinkedNode get isExpression_type;

  @Id(0)
  LinkedNodeKind get kind;

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

  @VariantId(3, variant: LinkedNodeKind.listLiteral)
  List<LinkedNode> get listLiteral_elements;

  @VariantId(6, variant: LinkedNodeKind.mapLiteralEntry)
  LinkedNode get mapLiteralEntry_key;

  @VariantId(7, variant: LinkedNodeKind.mapLiteralEntry)
  LinkedNode get mapLiteralEntry_value;

  @VariantId(6, variant: LinkedNodeKind.methodDeclaration)
  LinkedNode get methodDeclaration_body;

  @VariantId(7, variant: LinkedNodeKind.methodDeclaration)
  LinkedNode get methodDeclaration_formalParameters;

  @VariantId(31, variant: LinkedNodeKind.methodDeclaration)
  bool get methodDeclaration_hasOperatorEqualWithParameterTypeFromObject;

  @VariantId(8, variant: LinkedNodeKind.methodDeclaration)
  LinkedNode get methodDeclaration_returnType;

  @VariantId(9, variant: LinkedNodeKind.methodDeclaration)
  LinkedNode get methodDeclaration_typeParameters;

  @VariantId(6, variant: LinkedNodeKind.methodInvocation)
  LinkedNode get methodInvocation_methodName;

  @VariantId(7, variant: LinkedNodeKind.methodInvocation)
  LinkedNode get methodInvocation_target;

  @VariantId(6, variant: LinkedNodeKind.mixinDeclaration)
  LinkedNode get mixinDeclaration_onClause;

  @VariantId(34, variant: LinkedNodeKind.mixinDeclaration)
  List<String> get mixinDeclaration_superInvokedNames;

  @Id(37)
  String get name;

  @VariantId(6, variant: LinkedNodeKind.namedExpression)
  LinkedNode get namedExpression_expression;

  @VariantId(7, variant: LinkedNodeKind.namedExpression)
  LinkedNode get namedExpression_name;

  @VariantId(34, variantList: [
    LinkedNodeKind.hideCombinator,
    LinkedNodeKind.showCombinator,
    LinkedNodeKind.symbolLiteral,
  ])
  List<String> get names;

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

  @VariantId(6, variant: LinkedNodeKind.nativeFunctionBody)
  LinkedNode get nativeFunctionBody_stringLiteral;

  @VariantId(4, variantList: [
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.simpleFormalParameter,
  ])
  List<LinkedNode> get normalFormalParameter_metadata;

  @VariantId(15, variant: LinkedNodeKind.nullLiteral)
  int get nullLiteral_fake;

  @VariantId(2, variant: LinkedNodeKind.onClause)
  List<LinkedNode> get onClause_superclassConstraints;

  @VariantId(6, variant: LinkedNodeKind.parenthesizedExpression)
  LinkedNode get parenthesizedExpression_expression;

  @VariantId(6, variant: LinkedNodeKind.partOfDirective)
  LinkedNode get partOfDirective_libraryName;

  @VariantId(7, variant: LinkedNodeKind.partOfDirective)
  LinkedNode get partOfDirective_uri;

  @VariantId(15, variant: LinkedNodeKind.postfixExpression)
  int get postfixExpression_element;

  @VariantId(6, variant: LinkedNodeKind.postfixExpression)
  LinkedNode get postfixExpression_operand;

  @VariantId(28, variant: LinkedNodeKind.postfixExpression)
  UnlinkedTokenType get postfixExpression_operator;

  @VariantId(38, variant: LinkedNodeKind.postfixExpression)
  LinkedNodeTypeSubstitution get postfixExpression_substitution;

  @VariantId(6, variant: LinkedNodeKind.prefixedIdentifier)
  LinkedNode get prefixedIdentifier_identifier;

  @VariantId(7, variant: LinkedNodeKind.prefixedIdentifier)
  LinkedNode get prefixedIdentifier_prefix;

  @VariantId(15, variant: LinkedNodeKind.prefixExpression)
  int get prefixExpression_element;

  @VariantId(6, variant: LinkedNodeKind.prefixExpression)
  LinkedNode get prefixExpression_operand;

  @VariantId(28, variant: LinkedNodeKind.prefixExpression)
  UnlinkedTokenType get prefixExpression_operator;

  @VariantId(38, variant: LinkedNodeKind.prefixExpression)
  LinkedNodeTypeSubstitution get prefixExpression_substitution;

  @VariantId(28, variant: LinkedNodeKind.propertyAccess)
  UnlinkedTokenType get propertyAccess_operator;

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

  @VariantId(38, variant: LinkedNodeKind.redirectingConstructorInvocation)
  LinkedNodeTypeSubstitution get redirectingConstructorInvocation_substitution;

  @VariantId(6, variant: LinkedNodeKind.returnStatement)
  LinkedNode get returnStatement_expression;

  @VariantId(3, variant: LinkedNodeKind.setOrMapLiteral)
  List<LinkedNode> get setOrMapLiteral_elements;

  @VariantId(6, variant: LinkedNodeKind.simpleFormalParameter)
  LinkedNode get simpleFormalParameter_type;

  @VariantId(15, variant: LinkedNodeKind.simpleIdentifier)
  int get simpleIdentifier_element;

  @VariantId(38, variant: LinkedNodeKind.simpleIdentifier)
  LinkedNodeTypeSubstitution get simpleIdentifier_substitution;

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

  @VariantId(35, variant: LinkedNodeKind.spreadElement)
  UnlinkedTokenType get spreadElement_spreadOperator;

  @VariantId(2, variant: LinkedNodeKind.stringInterpolation)
  List<LinkedNode> get stringInterpolation_elements;

  @VariantId(6, variant: LinkedNodeKind.superConstructorInvocation)
  LinkedNode get superConstructorInvocation_arguments;

  @VariantId(7, variant: LinkedNodeKind.superConstructorInvocation)
  LinkedNode get superConstructorInvocation_constructorName;

  @VariantId(15, variant: LinkedNodeKind.superConstructorInvocation)
  int get superConstructorInvocation_element;

  @VariantId(38, variant: LinkedNodeKind.superConstructorInvocation)
  LinkedNodeTypeSubstitution get superConstructorInvocation_substitution;

  @VariantId(6, variant: LinkedNodeKind.switchCase)
  LinkedNode get switchCase_expression;

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

  @VariantId(2, variant: LinkedNodeKind.switchStatement)
  List<LinkedNode> get switchStatement_members;

  @VariantId(6, variant: LinkedNodeKind.throwExpression)
  LinkedNode get throwExpression_expression;

  @VariantId(32, variantList: [
    LinkedNodeKind.methodDeclaration,
    LinkedNodeKind.simpleFormalParameter,
    LinkedNodeKind.variableDeclaration,
  ])
  TopLevelInferenceError get topLevelTypeInferenceError;

  @VariantId(6, variant: LinkedNodeKind.topLevelVariableDeclaration)
  LinkedNode get topLevelVariableDeclaration_variableList;

  @VariantId(6, variant: LinkedNodeKind.tryStatement)
  LinkedNode get tryStatement_body;

  @VariantId(2, variant: LinkedNodeKind.tryStatement)
  List<LinkedNode> get tryStatement_catchClauses;

  @VariantId(7, variant: LinkedNodeKind.tryStatement)
  LinkedNode get tryStatement_finallyBlock;

  @VariantId(27, variantList: [
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
  ])
  bool get typeAlias_hasSelfReference;

  @VariantId(2, variant: LinkedNodeKind.typeArgumentList)
  List<LinkedNode> get typeArgumentList_arguments;

  @VariantId(2, variantList: [
    LinkedNodeKind.listLiteral,
    LinkedNodeKind.setOrMapLiteral,
  ])
  List<LinkedNode> get typedLiteral_typeArguments;

  @VariantId(6, variant: LinkedNodeKind.typeName)
  LinkedNode get typeName_name;

  @VariantId(23, variant: LinkedNodeKind.typeName)
  LinkedNodeType get typeName_type;

  @VariantId(2, variant: LinkedNodeKind.typeName)
  List<LinkedNode> get typeName_typeArguments;

  @VariantId(6, variant: LinkedNodeKind.typeParameter)
  LinkedNode get typeParameter_bound;

  @VariantId(23, variant: LinkedNodeKind.typeParameter)
  LinkedNodeType get typeParameter_defaultType;

  @VariantId(28, variant: LinkedNodeKind.typeParameter)
  UnlinkedTokenType get typeParameter_variance;

  @VariantId(2, variant: LinkedNodeKind.typeParameterList)
  List<LinkedNode> get typeParameterList_typeParameters;

  @VariantId(11, variantList: [
    LinkedNodeKind.classDeclaration,
  ])
  LinkedNode get unused11;

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

  @VariantId(6, variant: LinkedNodeKind.variableDeclaration)
  LinkedNode get variableDeclaration_initializer;

  @VariantId(6, variant: LinkedNodeKind.variableDeclarationList)
  LinkedNode get variableDeclarationList_type;

  @VariantId(2, variant: LinkedNodeKind.variableDeclarationList)
  List<LinkedNode> get variableDeclarationList_variables;

  @VariantId(6, variant: LinkedNodeKind.variableDeclarationStatement)
  LinkedNode get variableDeclarationStatement_variables;

  @VariantId(6, variant: LinkedNodeKind.whileStatement)
  LinkedNode get whileStatement_body;

  @VariantId(7, variant: LinkedNodeKind.whileStatement)
  LinkedNode get whileStatement_condition;

  @VariantId(2, variant: LinkedNodeKind.withClause)
  List<LinkedNode> get withClause_mixinTypes;

  @VariantId(6, variant: LinkedNodeKind.yieldStatement)
  LinkedNode get yieldStatement_expression;
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
  extensionDeclaration,
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
  extensionOverride,
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

  /// The typedef this function type is created for.
  @Id(9)
  int get functionTypedef;

  @Id(10)
  List<LinkedNodeType> get functionTypedefTypeArguments;

  @Id(2)
  List<LinkedNodeTypeTypeParameter> get functionTypeParameters;

  /// Reference to a [LinkedNodeReferences].
  @Id(3)
  int get interfaceClass;

  @Id(4)
  List<LinkedNodeType> get interfaceTypeArguments;

  @Id(5)
  LinkedNodeTypeKind get kind;

  @Id(8)
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

/// Information about a type substitution.
abstract class LinkedNodeTypeSubstitution extends base.SummaryClass {
  @Id(2)
  bool get isLegacy;

  @Id(1)
  List<LinkedNodeType> get typeArguments;

  @Id(0)
  List<int> get typeParameters;
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
  bool get isNNBD;

  @Id(2)
  bool get isSynthetic;

  @Id(1)
  LinkedNode get node;

  /// If the unit is a part, the URI specified in the `part` directive.
  /// Otherwise empty.
  @Id(4)
  String get partUriStr;

  /// The absolute URI.
  @Id(0)
  String get uriStr;
}

/// Summary information about a package.
@TopLevel('PBdl')
abstract class PackageBundle extends base.SummaryClass {
  factory PackageBundle.fromBuffer(List<int> buffer) =>
      generated.readPackageBundle(buffer);

  /// The version 2 of the summary.
  @Id(0)
  LinkedNodeBundle get bundle2;

  /// The SDK specific data, if this bundle is for SDK.
  @Id(1)
  PackageBundleSdk get sdk;
}

/// Summary information about a package.
abstract class PackageBundleSdk extends base.SummaryClass {
  /// The content of the `allowed_experiments.json` from SDK.
  @Id(0)
  String get allowedExperimentsJson;
}

/// Summary information about a top-level type inference error.
abstract class TopLevelInferenceError extends base.SummaryClass {
  /// The [kind] specific arguments.
  @Id(1)
  List<String> get arguments;

  /// The kind of the error.
  @Id(0)
  TopLevelInferenceErrorKind get kind;
}

/// Enum used to indicate the kind of the error during top-level inference.
enum TopLevelInferenceErrorKind {
  assignment,
  instanceGetter,
  dependencyCycle,
  overrideConflictFieldType,
  overrideNoCombinedSuperSignature,
}

@Variant('kind')
abstract class UnlinkedInformativeData extends base.SummaryClass {
  @VariantId(2, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.compilationUnit,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.defaultFormalParameter,
    LinkedNodeKind.enumConstantDeclaration,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.extensionDeclaration,
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

  @VariantId(3, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.compilationUnit,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.defaultFormalParameter,
    LinkedNodeKind.enumConstantDeclaration,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.extensionDeclaration,
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

  @VariantId(9, variantList: [
    LinkedNodeKind.hideCombinator,
    LinkedNodeKind.showCombinator,
  ])
  int get combinatorEnd;

  @VariantId(8, variantList: [
    LinkedNodeKind.hideCombinator,
    LinkedNodeKind.showCombinator,
  ])
  int get combinatorKeywordOffset;

  /// Offsets of the first character of each line in the source code.
  @VariantId(7, variant: LinkedNodeKind.compilationUnit)
  List<int> get compilationUnit_lineStarts;

  @VariantId(6, variant: LinkedNodeKind.constructorDeclaration)
  int get constructorDeclaration_periodOffset;

  @VariantId(5, variant: LinkedNodeKind.constructorDeclaration)
  int get constructorDeclaration_returnTypeOffset;

  /// If the parameter has a default value, the source text of the constant
  /// expression in the default value.  Otherwise the empty string.
  @VariantId(10, variant: LinkedNodeKind.defaultFormalParameter)
  String get defaultFormalParameter_defaultValueCode;

  @VariantId(1, variantList: [
    LinkedNodeKind.exportDirective,
    LinkedNodeKind.importDirective,
    LinkedNodeKind.libraryDirective,
    LinkedNodeKind.partDirective,
    LinkedNodeKind.partOfDirective,
  ])
  int get directiveKeywordOffset;

  @VariantId(4, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.enumConstantDeclaration,
    LinkedNodeKind.extensionDeclaration,
    LinkedNodeKind.fieldDeclaration,
    LinkedNodeKind.functionDeclaration,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
    LinkedNodeKind.libraryDirective,
    LinkedNodeKind.methodDeclaration,
    LinkedNodeKind.mixinDeclaration,
    LinkedNodeKind.topLevelVariableDeclaration,
  ])
  List<String> get documentationComment_tokens;

  @VariantId(8, variant: LinkedNodeKind.importDirective)
  int get importDirective_prefixOffset;

  /// The kind of the node.
  @Id(0)
  LinkedNodeKind get kind;

  @VariantId(1, variantList: [
    LinkedNodeKind.classDeclaration,
    LinkedNodeKind.classTypeAlias,
    LinkedNodeKind.constructorDeclaration,
    LinkedNodeKind.enumConstantDeclaration,
    LinkedNodeKind.enumDeclaration,
    LinkedNodeKind.extensionDeclaration,
    LinkedNodeKind.fieldFormalParameter,
    LinkedNodeKind.functionDeclaration,
    LinkedNodeKind.functionTypedFormalParameter,
    LinkedNodeKind.functionTypeAlias,
    LinkedNodeKind.genericTypeAlias,
    LinkedNodeKind.methodDeclaration,
    LinkedNodeKind.mixinDeclaration,
    LinkedNodeKind.simpleFormalParameter,
    LinkedNodeKind.typeParameter,
    LinkedNodeKind.variableDeclaration,
  ])
  int get nameOffset;
}

/// Unlinked summary information about a namespace directive.
abstract class UnlinkedNamespaceDirective extends base.SummaryClass {
  /// The configurations that control which library will actually be used.
  @Id(0)
  List<UnlinkedNamespaceDirectiveConfiguration> get configurations;

  /// The URI referenced by this directive, nad used by default when none
  /// of the [configurations] matches.
  @Id(1)
  String get uri;
}

/// Unlinked summary information about a namespace directive configuration.
abstract class UnlinkedNamespaceDirectiveConfiguration
    extends base.SummaryClass {
  /// The name of the declared variable used in the condition.
  @Id(0)
  String get name;

  /// The URI to be used if the condition is true.
  @Id(2)
  String get uri;

  /// The value to which the value of the declared variable will be compared,
  /// or the empty string if the condition does not include an equality test.
  @Id(1)
  String get value;
}

/// Enum of token types, corresponding to AST token types.
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
  INOUT,
  OUT,
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
  List<UnlinkedNamespaceDirective> get exports;

  /// Is `true` if the unit contains a `library` directive.
  @Id(6)
  bool get hasLibraryDirective;

  /// Is `true` if the unit contains a `part of` directive.
  @Id(3)
  bool get hasPartOfDirective;

  /// URIs of `import` directives.
  @Id(2)
  List<UnlinkedNamespaceDirective> get imports;

  @Id(7)
  List<UnlinkedInformativeData> get informativeData;

  /// Offsets of the first character of each line in the source code.
  @informative
  @Id(5)
  List<int> get lineStarts;

  /// URI of the `part of` directive.
  @Id(8)
  String get partOfUri;

  /// URIs of `part` directives.
  @Id(4)
  List<String> get parts;
}
