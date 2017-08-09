// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

/**
 * Matchers for data types defined in the analysis server API
 */
import 'package:test/test.dart';

import 'integration_tests.dart';

/**
 * AddContentOverlay
 *
 * {
 *   "type": "add"
 *   "content": String
 * }
 */
final Matcher isAddContentOverlay = new LazyMatcher(() => new MatchesJsonObject(
    "AddContentOverlay", {"type": equals("add"), "content": isString}));

/**
 * AnalysisError
 *
 * {
 *   "severity": AnalysisErrorSeverity
 *   "type": AnalysisErrorType
 *   "location": Location
 *   "message": String
 *   "correction": optional String
 *   "code": String
 *   "hasFix": optional bool
 * }
 */
final Matcher isAnalysisError =
    new LazyMatcher(() => new MatchesJsonObject("AnalysisError", {
          "severity": isAnalysisErrorSeverity,
          "type": isAnalysisErrorType,
          "location": isLocation,
          "message": isString,
          "code": isString
        }, optionalFields: {
          "correction": isString,
          "hasFix": isBool
        }));

/**
 * AnalysisErrorFixes
 *
 * {
 *   "error": AnalysisError
 *   "fixes": List<SourceChange>
 * }
 */
final Matcher isAnalysisErrorFixes = new LazyMatcher(() =>
    new MatchesJsonObject("AnalysisErrorFixes",
        {"error": isAnalysisError, "fixes": isListOf(isSourceChange)}));

/**
 * AnalysisErrorSeverity
 *
 * enum {
 *   INFO
 *   WARNING
 *   ERROR
 * }
 */
final Matcher isAnalysisErrorSeverity =
    new MatchesEnum("AnalysisErrorSeverity", ["INFO", "WARNING", "ERROR"]);

/**
 * AnalysisErrorType
 *
 * enum {
 *   CHECKED_MODE_COMPILE_TIME_ERROR
 *   COMPILE_TIME_ERROR
 *   HINT
 *   LINT
 *   STATIC_TYPE_WARNING
 *   STATIC_WARNING
 *   SYNTACTIC_ERROR
 *   TODO
 * }
 */
final Matcher isAnalysisErrorType = new MatchesEnum("AnalysisErrorType", [
  "CHECKED_MODE_COMPILE_TIME_ERROR",
  "COMPILE_TIME_ERROR",
  "HINT",
  "LINT",
  "STATIC_TYPE_WARNING",
  "STATIC_WARNING",
  "SYNTACTIC_ERROR",
  "TODO"
]);

/**
 * AnalysisOptions
 *
 * {
 *   "enableAsync": optional bool
 *   "enableDeferredLoading": optional bool
 *   "enableEnums": optional bool
 *   "enableNullAwareOperators": optional bool
 *   "enableSuperMixins": optional bool
 *   "generateDart2jsHints": optional bool
 *   "generateHints": optional bool
 *   "generateLints": optional bool
 * }
 */
final Matcher isAnalysisOptions = new LazyMatcher(
    () => new MatchesJsonObject("AnalysisOptions", null, optionalFields: {
          "enableAsync": isBool,
          "enableDeferredLoading": isBool,
          "enableEnums": isBool,
          "enableNullAwareOperators": isBool,
          "enableSuperMixins": isBool,
          "generateDart2jsHints": isBool,
          "generateHints": isBool,
          "generateLints": isBool
        }));

/**
 * AnalysisService
 *
 * enum {
 *   CLOSING_LABELS
 *   FOLDING
 *   HIGHLIGHTS
 *   IMPLEMENTED
 *   INVALIDATE
 *   NAVIGATION
 *   OCCURRENCES
 *   OUTLINE
 *   OVERRIDES
 * }
 */
final Matcher isAnalysisService = new MatchesEnum("AnalysisService", [
  "CLOSING_LABELS",
  "FOLDING",
  "HIGHLIGHTS",
  "IMPLEMENTED",
  "INVALIDATE",
  "NAVIGATION",
  "OCCURRENCES",
  "OUTLINE",
  "OVERRIDES"
]);

/**
 * AnalysisStatus
 *
 * {
 *   "isAnalyzing": bool
 *   "analysisTarget": optional String
 * }
 */
final Matcher isAnalysisStatus = new LazyMatcher(() => new MatchesJsonObject(
    "AnalysisStatus", {"isAnalyzing": isBool},
    optionalFields: {"analysisTarget": isString}));

/**
 * ChangeContentOverlay
 *
 * {
 *   "type": "change"
 *   "edits": List<SourceEdit>
 * }
 */
final Matcher isChangeContentOverlay = new LazyMatcher(() =>
    new MatchesJsonObject("ChangeContentOverlay",
        {"type": equals("change"), "edits": isListOf(isSourceEdit)}));

/**
 * ClosingLabel
 *
 * {
 *   "offset": int
 *   "length": int
 *   "label": String
 * }
 */
final Matcher isClosingLabel = new LazyMatcher(() => new MatchesJsonObject(
    "ClosingLabel", {"offset": isInt, "length": isInt, "label": isString}));

/**
 * CompletionId
 *
 * String
 */
final Matcher isCompletionId = isString;

/**
 * CompletionSuggestion
 *
 * {
 *   "kind": CompletionSuggestionKind
 *   "relevance": int
 *   "completion": String
 *   "selectionOffset": int
 *   "selectionLength": int
 *   "isDeprecated": bool
 *   "isPotential": bool
 *   "docSummary": optional String
 *   "docComplete": optional String
 *   "declaringType": optional String
 *   "defaultArgumentListString": optional String
 *   "defaultArgumentListTextRanges": optional List<int>
 *   "element": optional Element
 *   "returnType": optional String
 *   "parameterNames": optional List<String>
 *   "parameterTypes": optional List<String>
 *   "requiredParameterCount": optional int
 *   "hasNamedParameters": optional bool
 *   "parameterName": optional String
 *   "parameterType": optional String
 *   "importUri": optional String
 * }
 */
final Matcher isCompletionSuggestion =
    new LazyMatcher(() => new MatchesJsonObject("CompletionSuggestion", {
          "kind": isCompletionSuggestionKind,
          "relevance": isInt,
          "completion": isString,
          "selectionOffset": isInt,
          "selectionLength": isInt,
          "isDeprecated": isBool,
          "isPotential": isBool
        }, optionalFields: {
          "docSummary": isString,
          "docComplete": isString,
          "declaringType": isString,
          "defaultArgumentListString": isString,
          "defaultArgumentListTextRanges": isListOf(isInt),
          "element": isElement,
          "returnType": isString,
          "parameterNames": isListOf(isString),
          "parameterTypes": isListOf(isString),
          "requiredParameterCount": isInt,
          "hasNamedParameters": isBool,
          "parameterName": isString,
          "parameterType": isString,
          "importUri": isString
        }));

/**
 * CompletionSuggestionKind
 *
 * enum {
 *   ARGUMENT_LIST
 *   IMPORT
 *   IDENTIFIER
 *   INVOCATION
 *   KEYWORD
 *   NAMED_ARGUMENT
 *   OPTIONAL_ARGUMENT
 *   PARAMETER
 * }
 */
final Matcher isCompletionSuggestionKind =
    new MatchesEnum("CompletionSuggestionKind", [
  "ARGUMENT_LIST",
  "IMPORT",
  "IDENTIFIER",
  "INVOCATION",
  "KEYWORD",
  "NAMED_ARGUMENT",
  "OPTIONAL_ARGUMENT",
  "PARAMETER"
]);

/**
 * ContextData
 *
 * {
 *   "name": String
 *   "explicitFileCount": int
 *   "implicitFileCount": int
 *   "workItemQueueLength": int
 *   "cacheEntryExceptions": List<String>
 * }
 */
final Matcher isContextData =
    new LazyMatcher(() => new MatchesJsonObject("ContextData", {
          "name": isString,
          "explicitFileCount": isInt,
          "implicitFileCount": isInt,
          "workItemQueueLength": isInt,
          "cacheEntryExceptions": isListOf(isString)
        }));

/**
 * Element
 *
 * {
 *   "kind": ElementKind
 *   "name": String
 *   "location": optional Location
 *   "flags": int
 *   "parameters": optional String
 *   "returnType": optional String
 *   "typeParameters": optional String
 * }
 */
final Matcher isElement =
    new LazyMatcher(() => new MatchesJsonObject("Element", {
          "kind": isElementKind,
          "name": isString,
          "flags": isInt
        }, optionalFields: {
          "location": isLocation,
          "parameters": isString,
          "returnType": isString,
          "typeParameters": isString
        }));

/**
 * ElementKind
 *
 * enum {
 *   CLASS
 *   CLASS_TYPE_ALIAS
 *   COMPILATION_UNIT
 *   CONSTRUCTOR
 *   ENUM
 *   ENUM_CONSTANT
 *   FIELD
 *   FILE
 *   FUNCTION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER
 *   LABEL
 *   LIBRARY
 *   LOCAL_VARIABLE
 *   METHOD
 *   PARAMETER
 *   PREFIX
 *   SETTER
 *   TOP_LEVEL_VARIABLE
 *   TYPE_PARAMETER
 *   UNIT_TEST_GROUP
 *   UNIT_TEST_TEST
 *   UNKNOWN
 * }
 */
final Matcher isElementKind = new MatchesEnum("ElementKind", [
  "CLASS",
  "CLASS_TYPE_ALIAS",
  "COMPILATION_UNIT",
  "CONSTRUCTOR",
  "ENUM",
  "ENUM_CONSTANT",
  "FIELD",
  "FILE",
  "FUNCTION",
  "FUNCTION_TYPE_ALIAS",
  "GETTER",
  "LABEL",
  "LIBRARY",
  "LOCAL_VARIABLE",
  "METHOD",
  "PARAMETER",
  "PREFIX",
  "SETTER",
  "TOP_LEVEL_VARIABLE",
  "TYPE_PARAMETER",
  "UNIT_TEST_GROUP",
  "UNIT_TEST_TEST",
  "UNKNOWN"
]);

/**
 * ExecutableFile
 *
 * {
 *   "file": FilePath
 *   "kind": ExecutableKind
 * }
 */
final Matcher isExecutableFile = new LazyMatcher(() => new MatchesJsonObject(
    "ExecutableFile", {"file": isFilePath, "kind": isExecutableKind}));

/**
 * ExecutableKind
 *
 * enum {
 *   CLIENT
 *   EITHER
 *   NOT_EXECUTABLE
 *   SERVER
 * }
 */
final Matcher isExecutableKind = new MatchesEnum(
    "ExecutableKind", ["CLIENT", "EITHER", "NOT_EXECUTABLE", "SERVER"]);

/**
 * ExecutionContextId
 *
 * String
 */
final Matcher isExecutionContextId = isString;

/**
 * ExecutionService
 *
 * enum {
 *   LAUNCH_DATA
 * }
 */
final Matcher isExecutionService =
    new MatchesEnum("ExecutionService", ["LAUNCH_DATA"]);

/**
 * FileKind
 *
 * enum {
 *   LIBRARY
 *   PART
 * }
 */
final Matcher isFileKind = new MatchesEnum("FileKind", ["LIBRARY", "PART"]);

/**
 * FilePath
 *
 * String
 */
final Matcher isFilePath = isString;

/**
 * FoldingKind
 *
 * enum {
 *   COMMENT
 *   CLASS_MEMBER
 *   DIRECTIVES
 *   DOCUMENTATION_COMMENT
 *   TOP_LEVEL_DECLARATION
 * }
 */
final Matcher isFoldingKind = new MatchesEnum("FoldingKind", [
  "COMMENT",
  "CLASS_MEMBER",
  "DIRECTIVES",
  "DOCUMENTATION_COMMENT",
  "TOP_LEVEL_DECLARATION"
]);

/**
 * FoldingRegion
 *
 * {
 *   "kind": FoldingKind
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isFoldingRegion = new LazyMatcher(() => new MatchesJsonObject(
    "FoldingRegion",
    {"kind": isFoldingKind, "offset": isInt, "length": isInt}));

/**
 * GeneralAnalysisService
 *
 * enum {
 *   ANALYZED_FILES
 * }
 */
final Matcher isGeneralAnalysisService =
    new MatchesEnum("GeneralAnalysisService", ["ANALYZED_FILES"]);

/**
 * HighlightRegion
 *
 * {
 *   "type": HighlightRegionType
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isHighlightRegion = new LazyMatcher(() => new MatchesJsonObject(
    "HighlightRegion",
    {"type": isHighlightRegionType, "offset": isInt, "length": isInt}));

/**
 * HighlightRegionType
 *
 * enum {
 *   ANNOTATION
 *   BUILT_IN
 *   CLASS
 *   COMMENT_BLOCK
 *   COMMENT_DOCUMENTATION
 *   COMMENT_END_OF_LINE
 *   CONSTRUCTOR
 *   DIRECTIVE
 *   DYNAMIC_TYPE
 *   DYNAMIC_LOCAL_VARIABLE_DECLARATION
 *   DYNAMIC_LOCAL_VARIABLE_REFERENCE
 *   DYNAMIC_PARAMETER_DECLARATION
 *   DYNAMIC_PARAMETER_REFERENCE
 *   ENUM
 *   ENUM_CONSTANT
 *   FIELD
 *   FIELD_STATIC
 *   FUNCTION
 *   FUNCTION_DECLARATION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER_DECLARATION
 *   IDENTIFIER_DEFAULT
 *   IMPORT_PREFIX
 *   INSTANCE_FIELD_DECLARATION
 *   INSTANCE_FIELD_REFERENCE
 *   INSTANCE_GETTER_DECLARATION
 *   INSTANCE_GETTER_REFERENCE
 *   INSTANCE_METHOD_DECLARATION
 *   INSTANCE_METHOD_REFERENCE
 *   INSTANCE_SETTER_DECLARATION
 *   INSTANCE_SETTER_REFERENCE
 *   INVALID_STRING_ESCAPE
 *   KEYWORD
 *   LABEL
 *   LIBRARY_NAME
 *   LITERAL_BOOLEAN
 *   LITERAL_DOUBLE
 *   LITERAL_INTEGER
 *   LITERAL_LIST
 *   LITERAL_MAP
 *   LITERAL_STRING
 *   LOCAL_FUNCTION_DECLARATION
 *   LOCAL_FUNCTION_REFERENCE
 *   LOCAL_VARIABLE
 *   LOCAL_VARIABLE_DECLARATION
 *   LOCAL_VARIABLE_REFERENCE
 *   METHOD
 *   METHOD_DECLARATION
 *   METHOD_DECLARATION_STATIC
 *   METHOD_STATIC
 *   PARAMETER
 *   SETTER_DECLARATION
 *   TOP_LEVEL_VARIABLE
 *   PARAMETER_DECLARATION
 *   PARAMETER_REFERENCE
 *   STATIC_FIELD_DECLARATION
 *   STATIC_GETTER_DECLARATION
 *   STATIC_GETTER_REFERENCE
 *   STATIC_METHOD_DECLARATION
 *   STATIC_METHOD_REFERENCE
 *   STATIC_SETTER_DECLARATION
 *   STATIC_SETTER_REFERENCE
 *   TOP_LEVEL_FUNCTION_DECLARATION
 *   TOP_LEVEL_FUNCTION_REFERENCE
 *   TOP_LEVEL_GETTER_DECLARATION
 *   TOP_LEVEL_GETTER_REFERENCE
 *   TOP_LEVEL_SETTER_DECLARATION
 *   TOP_LEVEL_SETTER_REFERENCE
 *   TOP_LEVEL_VARIABLE_DECLARATION
 *   TYPE_NAME_DYNAMIC
 *   TYPE_PARAMETER
 *   UNRESOLVED_INSTANCE_MEMBER_REFERENCE
 *   VALID_STRING_ESCAPE
 * }
 */
final Matcher isHighlightRegionType = new MatchesEnum("HighlightRegionType", [
  "ANNOTATION",
  "BUILT_IN",
  "CLASS",
  "COMMENT_BLOCK",
  "COMMENT_DOCUMENTATION",
  "COMMENT_END_OF_LINE",
  "CONSTRUCTOR",
  "DIRECTIVE",
  "DYNAMIC_TYPE",
  "DYNAMIC_LOCAL_VARIABLE_DECLARATION",
  "DYNAMIC_LOCAL_VARIABLE_REFERENCE",
  "DYNAMIC_PARAMETER_DECLARATION",
  "DYNAMIC_PARAMETER_REFERENCE",
  "ENUM",
  "ENUM_CONSTANT",
  "FIELD",
  "FIELD_STATIC",
  "FUNCTION",
  "FUNCTION_DECLARATION",
  "FUNCTION_TYPE_ALIAS",
  "GETTER_DECLARATION",
  "IDENTIFIER_DEFAULT",
  "IMPORT_PREFIX",
  "INSTANCE_FIELD_DECLARATION",
  "INSTANCE_FIELD_REFERENCE",
  "INSTANCE_GETTER_DECLARATION",
  "INSTANCE_GETTER_REFERENCE",
  "INSTANCE_METHOD_DECLARATION",
  "INSTANCE_METHOD_REFERENCE",
  "INSTANCE_SETTER_DECLARATION",
  "INSTANCE_SETTER_REFERENCE",
  "INVALID_STRING_ESCAPE",
  "KEYWORD",
  "LABEL",
  "LIBRARY_NAME",
  "LITERAL_BOOLEAN",
  "LITERAL_DOUBLE",
  "LITERAL_INTEGER",
  "LITERAL_LIST",
  "LITERAL_MAP",
  "LITERAL_STRING",
  "LOCAL_FUNCTION_DECLARATION",
  "LOCAL_FUNCTION_REFERENCE",
  "LOCAL_VARIABLE",
  "LOCAL_VARIABLE_DECLARATION",
  "LOCAL_VARIABLE_REFERENCE",
  "METHOD",
  "METHOD_DECLARATION",
  "METHOD_DECLARATION_STATIC",
  "METHOD_STATIC",
  "PARAMETER",
  "SETTER_DECLARATION",
  "TOP_LEVEL_VARIABLE",
  "PARAMETER_DECLARATION",
  "PARAMETER_REFERENCE",
  "STATIC_FIELD_DECLARATION",
  "STATIC_GETTER_DECLARATION",
  "STATIC_GETTER_REFERENCE",
  "STATIC_METHOD_DECLARATION",
  "STATIC_METHOD_REFERENCE",
  "STATIC_SETTER_DECLARATION",
  "STATIC_SETTER_REFERENCE",
  "TOP_LEVEL_FUNCTION_DECLARATION",
  "TOP_LEVEL_FUNCTION_REFERENCE",
  "TOP_LEVEL_GETTER_DECLARATION",
  "TOP_LEVEL_GETTER_REFERENCE",
  "TOP_LEVEL_SETTER_DECLARATION",
  "TOP_LEVEL_SETTER_REFERENCE",
  "TOP_LEVEL_VARIABLE_DECLARATION",
  "TYPE_NAME_DYNAMIC",
  "TYPE_PARAMETER",
  "UNRESOLVED_INSTANCE_MEMBER_REFERENCE",
  "VALID_STRING_ESCAPE"
]);

/**
 * HoverInformation
 *
 * {
 *   "offset": int
 *   "length": int
 *   "containingLibraryPath": optional String
 *   "containingLibraryName": optional String
 *   "containingClassDescription": optional String
 *   "dartdoc": optional String
 *   "elementDescription": optional String
 *   "elementKind": optional String
 *   "isDeprecated": optional bool
 *   "parameter": optional String
 *   "propagatedType": optional String
 *   "staticType": optional String
 * }
 */
final Matcher isHoverInformation =
    new LazyMatcher(() => new MatchesJsonObject("HoverInformation", {
          "offset": isInt,
          "length": isInt
        }, optionalFields: {
          "containingLibraryPath": isString,
          "containingLibraryName": isString,
          "containingClassDescription": isString,
          "dartdoc": isString,
          "elementDescription": isString,
          "elementKind": isString,
          "isDeprecated": isBool,
          "parameter": isString,
          "propagatedType": isString,
          "staticType": isString
        }));

/**
 * ImplementedClass
 *
 * {
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isImplementedClass = new LazyMatcher(() => new MatchesJsonObject(
    "ImplementedClass", {"offset": isInt, "length": isInt}));

/**
 * ImplementedMember
 *
 * {
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isImplementedMember = new LazyMatcher(() => new MatchesJsonObject(
    "ImplementedMember", {"offset": isInt, "length": isInt}));

/**
 * ImportedElements
 *
 * {
 *   "path": FilePath
 *   "prefix": String
 *   "elements": List<String>
 * }
 */
final Matcher isImportedElements = new LazyMatcher(() => new MatchesJsonObject(
    "ImportedElements",
    {"path": isFilePath, "prefix": isString, "elements": isListOf(isString)}));

/**
 * KytheEntry
 *
 * {
 *   "source": KytheVName
 *   "kind": String
 *   "target": KytheVName
 *   "fact": String
 *   "value": List<int>
 * }
 */
final Matcher isKytheEntry =
    new LazyMatcher(() => new MatchesJsonObject("KytheEntry", {
          "source": isKytheVName,
          "kind": isString,
          "target": isKytheVName,
          "fact": isString,
          "value": isListOf(isInt)
        }));

/**
 * KytheVName
 *
 * {
 *   "signature": String
 *   "corpus": String
 *   "root": String
 *   "path": String
 *   "language": String
 * }
 */
final Matcher isKytheVName =
    new LazyMatcher(() => new MatchesJsonObject("KytheVName", {
          "signature": isString,
          "corpus": isString,
          "root": isString,
          "path": isString,
          "language": isString
        }));

/**
 * LinkedEditGroup
 *
 * {
 *   "positions": List<Position>
 *   "length": int
 *   "suggestions": List<LinkedEditSuggestion>
 * }
 */
final Matcher isLinkedEditGroup =
    new LazyMatcher(() => new MatchesJsonObject("LinkedEditGroup", {
          "positions": isListOf(isPosition),
          "length": isInt,
          "suggestions": isListOf(isLinkedEditSuggestion)
        }));

/**
 * LinkedEditSuggestion
 *
 * {
 *   "value": String
 *   "kind": LinkedEditSuggestionKind
 * }
 */
final Matcher isLinkedEditSuggestion = new LazyMatcher(() =>
    new MatchesJsonObject("LinkedEditSuggestion",
        {"value": isString, "kind": isLinkedEditSuggestionKind}));

/**
 * LinkedEditSuggestionKind
 *
 * enum {
 *   METHOD
 *   PARAMETER
 *   TYPE
 *   VARIABLE
 * }
 */
final Matcher isLinkedEditSuggestionKind = new MatchesEnum(
    "LinkedEditSuggestionKind", ["METHOD", "PARAMETER", "TYPE", "VARIABLE"]);

/**
 * Location
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 *   "startLine": int
 *   "startColumn": int
 * }
 */
final Matcher isLocation =
    new LazyMatcher(() => new MatchesJsonObject("Location", {
          "file": isFilePath,
          "offset": isInt,
          "length": isInt,
          "startLine": isInt,
          "startColumn": isInt
        }));

/**
 * NavigationRegion
 *
 * {
 *   "offset": int
 *   "length": int
 *   "targets": List<int>
 * }
 */
final Matcher isNavigationRegion = new LazyMatcher(() => new MatchesJsonObject(
    "NavigationRegion",
    {"offset": isInt, "length": isInt, "targets": isListOf(isInt)}));

/**
 * NavigationTarget
 *
 * {
 *   "kind": ElementKind
 *   "fileIndex": int
 *   "offset": int
 *   "length": int
 *   "startLine": int
 *   "startColumn": int
 * }
 */
final Matcher isNavigationTarget =
    new LazyMatcher(() => new MatchesJsonObject("NavigationTarget", {
          "kind": isElementKind,
          "fileIndex": isInt,
          "offset": isInt,
          "length": isInt,
          "startLine": isInt,
          "startColumn": isInt
        }));

/**
 * Occurrences
 *
 * {
 *   "element": Element
 *   "offsets": List<int>
 *   "length": int
 * }
 */
final Matcher isOccurrences = new LazyMatcher(() => new MatchesJsonObject(
    "Occurrences",
    {"element": isElement, "offsets": isListOf(isInt), "length": isInt}));

/**
 * Outline
 *
 * {
 *   "element": Element
 *   "offset": int
 *   "length": int
 *   "children": optional List<Outline>
 * }
 */
final Matcher isOutline = new LazyMatcher(() => new MatchesJsonObject(
    "Outline", {"element": isElement, "offset": isInt, "length": isInt},
    optionalFields: {"children": isListOf(isOutline)}));

/**
 * OverriddenMember
 *
 * {
 *   "element": Element
 *   "className": String
 * }
 */
final Matcher isOverriddenMember = new LazyMatcher(() => new MatchesJsonObject(
    "OverriddenMember", {"element": isElement, "className": isString}));

/**
 * Override
 *
 * {
 *   "offset": int
 *   "length": int
 *   "superclassMember": optional OverriddenMember
 *   "interfaceMembers": optional List<OverriddenMember>
 * }
 */
final Matcher isOverride =
    new LazyMatcher(() => new MatchesJsonObject("Override", {
          "offset": isInt,
          "length": isInt
        }, optionalFields: {
          "superclassMember": isOverriddenMember,
          "interfaceMembers": isListOf(isOverriddenMember)
        }));

/**
 * Position
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isPosition = new LazyMatcher(() =>
    new MatchesJsonObject("Position", {"file": isFilePath, "offset": isInt}));

/**
 * PostfixTemplateDescriptor
 *
 * {
 *   "name": String
 *   "key": String
 *   "example": String
 * }
 */
final Matcher isPostfixTemplateDescriptor = new LazyMatcher(() =>
    new MatchesJsonObject("PostfixTemplateDescriptor",
        {"name": isString, "key": isString, "example": isString}));

/**
 * PubStatus
 *
 * {
 *   "isListingPackageDirs": bool
 * }
 */
final Matcher isPubStatus = new LazyMatcher(
    () => new MatchesJsonObject("PubStatus", {"isListingPackageDirs": isBool}));

/**
 * RefactoringFeedback
 *
 * {
 * }
 */
final Matcher isRefactoringFeedback =
    new LazyMatcher(() => new MatchesJsonObject("RefactoringFeedback", null));

/**
 * RefactoringKind
 *
 * enum {
 *   CONVERT_GETTER_TO_METHOD
 *   CONVERT_METHOD_TO_GETTER
 *   EXTRACT_LOCAL_VARIABLE
 *   EXTRACT_METHOD
 *   INLINE_LOCAL_VARIABLE
 *   INLINE_METHOD
 *   MOVE_FILE
 *   RENAME
 *   SORT_MEMBERS
 * }
 */
final Matcher isRefactoringKind = new MatchesEnum("RefactoringKind", [
  "CONVERT_GETTER_TO_METHOD",
  "CONVERT_METHOD_TO_GETTER",
  "EXTRACT_LOCAL_VARIABLE",
  "EXTRACT_METHOD",
  "INLINE_LOCAL_VARIABLE",
  "INLINE_METHOD",
  "MOVE_FILE",
  "RENAME",
  "SORT_MEMBERS"
]);

/**
 * RefactoringMethodParameter
 *
 * {
 *   "id": optional String
 *   "kind": RefactoringMethodParameterKind
 *   "type": String
 *   "name": String
 *   "parameters": optional String
 * }
 */
final Matcher isRefactoringMethodParameter = new LazyMatcher(() =>
    new MatchesJsonObject("RefactoringMethodParameter", {
      "kind": isRefactoringMethodParameterKind,
      "type": isString,
      "name": isString
    }, optionalFields: {
      "id": isString,
      "parameters": isString
    }));

/**
 * RefactoringMethodParameterKind
 *
 * enum {
 *   REQUIRED
 *   POSITIONAL
 *   NAMED
 * }
 */
final Matcher isRefactoringMethodParameterKind = new MatchesEnum(
    "RefactoringMethodParameterKind", ["REQUIRED", "POSITIONAL", "NAMED"]);

/**
 * RefactoringOptions
 *
 * {
 * }
 */
final Matcher isRefactoringOptions =
    new LazyMatcher(() => new MatchesJsonObject("RefactoringOptions", null));

/**
 * RefactoringProblem
 *
 * {
 *   "severity": RefactoringProblemSeverity
 *   "message": String
 *   "location": optional Location
 * }
 */
final Matcher isRefactoringProblem = new LazyMatcher(() =>
    new MatchesJsonObject("RefactoringProblem",
        {"severity": isRefactoringProblemSeverity, "message": isString},
        optionalFields: {"location": isLocation}));

/**
 * RefactoringProblemSeverity
 *
 * enum {
 *   INFO
 *   WARNING
 *   ERROR
 *   FATAL
 * }
 */
final Matcher isRefactoringProblemSeverity = new MatchesEnum(
    "RefactoringProblemSeverity", ["INFO", "WARNING", "ERROR", "FATAL"]);

/**
 * RemoveContentOverlay
 *
 * {
 *   "type": "remove"
 * }
 */
final Matcher isRemoveContentOverlay = new LazyMatcher(() =>
    new MatchesJsonObject("RemoveContentOverlay", {"type": equals("remove")}));

/**
 * RequestError
 *
 * {
 *   "code": RequestErrorCode
 *   "message": String
 *   "stackTrace": optional String
 * }
 */
final Matcher isRequestError = new LazyMatcher(() => new MatchesJsonObject(
    "RequestError", {"code": isRequestErrorCode, "message": isString},
    optionalFields: {"stackTrace": isString}));

/**
 * RequestErrorCode
 *
 * enum {
 *   CONTENT_MODIFIED
 *   DEBUG_PORT_COULD_NOT_BE_OPENED
 *   FILE_NOT_ANALYZED
 *   FORMAT_INVALID_FILE
 *   FORMAT_WITH_ERRORS
 *   GET_ERRORS_INVALID_FILE
 *   GET_IMPORTED_ELEMENTS_INVALID_FILE
 *   GET_NAVIGATION_INVALID_FILE
 *   GET_REACHABLE_SOURCES_INVALID_FILE
 *   IMPORT_ELEMENTS_INVALID_FILE
 *   INVALID_ANALYSIS_ROOT
 *   INVALID_EXECUTION_CONTEXT
 *   INVALID_FILE_PATH_FORMAT
 *   INVALID_OVERLAY_CHANGE
 *   INVALID_PARAMETER
 *   INVALID_REQUEST
 *   ORGANIZE_DIRECTIVES_ERROR
 *   REFACTORING_REQUEST_CANCELLED
 *   SERVER_ALREADY_STARTED
 *   SERVER_ERROR
 *   SORT_MEMBERS_INVALID_FILE
 *   SORT_MEMBERS_PARSE_ERRORS
 *   UNANALYZED_PRIORITY_FILES
 *   UNKNOWN_REQUEST
 *   UNKNOWN_SOURCE
 *   UNSUPPORTED_FEATURE
 * }
 */
final Matcher isRequestErrorCode = new MatchesEnum("RequestErrorCode", [
  "CONTENT_MODIFIED",
  "DEBUG_PORT_COULD_NOT_BE_OPENED",
  "FILE_NOT_ANALYZED",
  "FORMAT_INVALID_FILE",
  "FORMAT_WITH_ERRORS",
  "GET_ERRORS_INVALID_FILE",
  "GET_IMPORTED_ELEMENTS_INVALID_FILE",
  "GET_NAVIGATION_INVALID_FILE",
  "GET_REACHABLE_SOURCES_INVALID_FILE",
  "IMPORT_ELEMENTS_INVALID_FILE",
  "INVALID_ANALYSIS_ROOT",
  "INVALID_EXECUTION_CONTEXT",
  "INVALID_FILE_PATH_FORMAT",
  "INVALID_OVERLAY_CHANGE",
  "INVALID_PARAMETER",
  "INVALID_REQUEST",
  "ORGANIZE_DIRECTIVES_ERROR",
  "REFACTORING_REQUEST_CANCELLED",
  "SERVER_ALREADY_STARTED",
  "SERVER_ERROR",
  "SORT_MEMBERS_INVALID_FILE",
  "SORT_MEMBERS_PARSE_ERRORS",
  "UNANALYZED_PRIORITY_FILES",
  "UNKNOWN_REQUEST",
  "UNKNOWN_SOURCE",
  "UNSUPPORTED_FEATURE"
]);

/**
 * SearchId
 *
 * String
 */
final Matcher isSearchId = isString;

/**
 * SearchResult
 *
 * {
 *   "location": Location
 *   "kind": SearchResultKind
 *   "isPotential": bool
 *   "path": List<Element>
 * }
 */
final Matcher isSearchResult =
    new LazyMatcher(() => new MatchesJsonObject("SearchResult", {
          "location": isLocation,
          "kind": isSearchResultKind,
          "isPotential": isBool,
          "path": isListOf(isElement)
        }));

/**
 * SearchResultKind
 *
 * enum {
 *   DECLARATION
 *   INVOCATION
 *   READ
 *   READ_WRITE
 *   REFERENCE
 *   UNKNOWN
 *   WRITE
 * }
 */
final Matcher isSearchResultKind = new MatchesEnum("SearchResultKind", [
  "DECLARATION",
  "INVOCATION",
  "READ",
  "READ_WRITE",
  "REFERENCE",
  "UNKNOWN",
  "WRITE"
]);

/**
 * ServerService
 *
 * enum {
 *   STATUS
 * }
 */
final Matcher isServerService = new MatchesEnum("ServerService", ["STATUS"]);

/**
 * SourceChange
 *
 * {
 *   "message": String
 *   "edits": List<SourceFileEdit>
 *   "linkedEditGroups": List<LinkedEditGroup>
 *   "selection": optional Position
 * }
 */
final Matcher isSourceChange =
    new LazyMatcher(() => new MatchesJsonObject("SourceChange", {
          "message": isString,
          "edits": isListOf(isSourceFileEdit),
          "linkedEditGroups": isListOf(isLinkedEditGroup)
        }, optionalFields: {
          "selection": isPosition
        }));

/**
 * SourceEdit
 *
 * {
 *   "offset": int
 *   "length": int
 *   "replacement": String
 *   "id": optional String
 * }
 */
final Matcher isSourceEdit = new LazyMatcher(() => new MatchesJsonObject(
    "SourceEdit", {"offset": isInt, "length": isInt, "replacement": isString},
    optionalFields: {"id": isString}));

/**
 * SourceFileEdit
 *
 * {
 *   "file": FilePath
 *   "fileStamp": long
 *   "edits": List<SourceEdit>
 * }
 */
final Matcher isSourceFileEdit = new LazyMatcher(() => new MatchesJsonObject(
    "SourceFileEdit",
    {"file": isFilePath, "fileStamp": isInt, "edits": isListOf(isSourceEdit)}));

/**
 * TypeHierarchyItem
 *
 * {
 *   "classElement": Element
 *   "displayName": optional String
 *   "memberElement": optional Element
 *   "superclass": optional int
 *   "interfaces": List<int>
 *   "mixins": List<int>
 *   "subclasses": List<int>
 * }
 */
final Matcher isTypeHierarchyItem =
    new LazyMatcher(() => new MatchesJsonObject("TypeHierarchyItem", {
          "classElement": isElement,
          "interfaces": isListOf(isInt),
          "mixins": isListOf(isInt),
          "subclasses": isListOf(isInt)
        }, optionalFields: {
          "displayName": isString,
          "memberElement": isElement,
          "superclass": isInt
        }));

/**
 * analysis.analyzedFiles params
 *
 * {
 *   "directories": List<FilePath>
 * }
 */
final Matcher isAnalysisAnalyzedFilesParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.analyzedFiles params",
        {"directories": isListOf(isFilePath)}));

/**
 * analysis.closingLabels params
 *
 * {
 *   "file": FilePath
 *   "labels": List<ClosingLabel>
 * }
 */
final Matcher isAnalysisClosingLabelsParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.closingLabels params",
        {"file": isFilePath, "labels": isListOf(isClosingLabel)}));

/**
 * analysis.errors params
 *
 * {
 *   "file": FilePath
 *   "errors": List<AnalysisError>
 * }
 */
final Matcher isAnalysisErrorsParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.errors params",
        {"file": isFilePath, "errors": isListOf(isAnalysisError)}));

/**
 * analysis.flushResults params
 *
 * {
 *   "files": List<FilePath>
 * }
 */
final Matcher isAnalysisFlushResultsParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "analysis.flushResults params", {"files": isListOf(isFilePath)}));

/**
 * analysis.folding params
 *
 * {
 *   "file": FilePath
 *   "regions": List<FoldingRegion>
 * }
 */
final Matcher isAnalysisFoldingParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.folding params",
        {"file": isFilePath, "regions": isListOf(isFoldingRegion)}));

/**
 * analysis.getErrors params
 *
 * {
 *   "file": FilePath
 * }
 */
final Matcher isAnalysisGetErrorsParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.getErrors params", {"file": isFilePath}));

/**
 * analysis.getErrors result
 *
 * {
 *   "errors": List<AnalysisError>
 * }
 */
final Matcher isAnalysisGetErrorsResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "analysis.getErrors result", {"errors": isListOf(isAnalysisError)}));

/**
 * analysis.getHover params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isAnalysisGetHoverParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "analysis.getHover params", {"file": isFilePath, "offset": isInt}));

/**
 * analysis.getHover result
 *
 * {
 *   "hovers": List<HoverInformation>
 * }
 */
final Matcher isAnalysisGetHoverResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "analysis.getHover result", {"hovers": isListOf(isHoverInformation)}));

/**
 * analysis.getImportedElements params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isAnalysisGetImportedElementsParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.getImportedElements params",
        {"file": isFilePath, "offset": isInt, "length": isInt}));

/**
 * analysis.getImportedElements result
 *
 * {
 *   "elements": List<ImportedElements>
 * }
 */
final Matcher isAnalysisGetImportedElementsResult = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.getImportedElements result",
        {"elements": isListOf(isImportedElements)}));

/**
 * analysis.getLibraryDependencies params
 */
final Matcher isAnalysisGetLibraryDependenciesParams = isNull;

/**
 * analysis.getLibraryDependencies result
 *
 * {
 *   "libraries": List<FilePath>
 *   "packageMap": Map<String, Map<String, List<FilePath>>>
 * }
 */
final Matcher isAnalysisGetLibraryDependenciesResult = new LazyMatcher(
    () => new MatchesJsonObject("analysis.getLibraryDependencies result", {
          "libraries": isListOf(isFilePath),
          "packageMap":
              isMapOf(isString, isMapOf(isString, isListOf(isFilePath)))
        }));

/**
 * analysis.getNavigation params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isAnalysisGetNavigationParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.getNavigation params",
        {"file": isFilePath, "offset": isInt, "length": isInt}));

/**
 * analysis.getNavigation result
 *
 * {
 *   "files": List<FilePath>
 *   "targets": List<NavigationTarget>
 *   "regions": List<NavigationRegion>
 * }
 */
final Matcher isAnalysisGetNavigationResult = new LazyMatcher(
    () => new MatchesJsonObject("analysis.getNavigation result", {
          "files": isListOf(isFilePath),
          "targets": isListOf(isNavigationTarget),
          "regions": isListOf(isNavigationRegion)
        }));

/**
 * analysis.getReachableSources params
 *
 * {
 *   "file": FilePath
 * }
 */
final Matcher isAnalysisGetReachableSourcesParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "analysis.getReachableSources params", {"file": isFilePath}));

/**
 * analysis.getReachableSources result
 *
 * {
 *   "sources": Map<String, List<String>>
 * }
 */
final Matcher isAnalysisGetReachableSourcesResult = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.getReachableSources result",
        {"sources": isMapOf(isString, isListOf(isString))}));

/**
 * analysis.highlights params
 *
 * {
 *   "file": FilePath
 *   "regions": List<HighlightRegion>
 * }
 */
final Matcher isAnalysisHighlightsParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.highlights params",
        {"file": isFilePath, "regions": isListOf(isHighlightRegion)}));

/**
 * analysis.implemented params
 *
 * {
 *   "file": FilePath
 *   "classes": List<ImplementedClass>
 *   "members": List<ImplementedMember>
 * }
 */
final Matcher isAnalysisImplementedParams =
    new LazyMatcher(() => new MatchesJsonObject("analysis.implemented params", {
          "file": isFilePath,
          "classes": isListOf(isImplementedClass),
          "members": isListOf(isImplementedMember)
        }));

/**
 * analysis.invalidate params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 *   "delta": int
 * }
 */
final Matcher isAnalysisInvalidateParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.invalidate params", {
      "file": isFilePath,
      "offset": isInt,
      "length": isInt,
      "delta": isInt
    }));

/**
 * analysis.navigation params
 *
 * {
 *   "file": FilePath
 *   "regions": List<NavigationRegion>
 *   "targets": List<NavigationTarget>
 *   "files": List<FilePath>
 * }
 */
final Matcher isAnalysisNavigationParams =
    new LazyMatcher(() => new MatchesJsonObject("analysis.navigation params", {
          "file": isFilePath,
          "regions": isListOf(isNavigationRegion),
          "targets": isListOf(isNavigationTarget),
          "files": isListOf(isFilePath)
        }));

/**
 * analysis.occurrences params
 *
 * {
 *   "file": FilePath
 *   "occurrences": List<Occurrences>
 * }
 */
final Matcher isAnalysisOccurrencesParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.occurrences params",
        {"file": isFilePath, "occurrences": isListOf(isOccurrences)}));

/**
 * analysis.outline params
 *
 * {
 *   "file": FilePath
 *   "kind": FileKind
 *   "libraryName": optional String
 *   "outline": Outline
 * }
 */
final Matcher isAnalysisOutlineParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.outline params",
        {"file": isFilePath, "kind": isFileKind, "outline": isOutline},
        optionalFields: {"libraryName": isString}));

/**
 * analysis.overrides params
 *
 * {
 *   "file": FilePath
 *   "overrides": List<Override>
 * }
 */
final Matcher isAnalysisOverridesParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.overrides params",
        {"file": isFilePath, "overrides": isListOf(isOverride)}));

/**
 * analysis.reanalyze params
 *
 * {
 *   "roots": optional List<FilePath>
 * }
 */
final Matcher isAnalysisReanalyzeParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.reanalyze params", null,
        optionalFields: {"roots": isListOf(isFilePath)}));

/**
 * analysis.reanalyze result
 */
final Matcher isAnalysisReanalyzeResult = isNull;

/**
 * analysis.setAnalysisRoots params
 *
 * {
 *   "included": List<FilePath>
 *   "excluded": List<FilePath>
 *   "packageRoots": optional Map<FilePath, FilePath>
 * }
 */
final Matcher isAnalysisSetAnalysisRootsParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.setAnalysisRoots params",
        {"included": isListOf(isFilePath), "excluded": isListOf(isFilePath)},
        optionalFields: {"packageRoots": isMapOf(isFilePath, isFilePath)}));

/**
 * analysis.setAnalysisRoots result
 */
final Matcher isAnalysisSetAnalysisRootsResult = isNull;

/**
 * analysis.setGeneralSubscriptions params
 *
 * {
 *   "subscriptions": List<GeneralAnalysisService>
 * }
 */
final Matcher isAnalysisSetGeneralSubscriptionsParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.setGeneralSubscriptions params",
        {"subscriptions": isListOf(isGeneralAnalysisService)}));

/**
 * analysis.setGeneralSubscriptions result
 */
final Matcher isAnalysisSetGeneralSubscriptionsResult = isNull;

/**
 * analysis.setPriorityFiles params
 *
 * {
 *   "files": List<FilePath>
 * }
 */
final Matcher isAnalysisSetPriorityFilesParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "analysis.setPriorityFiles params", {"files": isListOf(isFilePath)}));

/**
 * analysis.setPriorityFiles result
 */
final Matcher isAnalysisSetPriorityFilesResult = isNull;

/**
 * analysis.setSubscriptions params
 *
 * {
 *   "subscriptions": Map<AnalysisService, List<FilePath>>
 * }
 */
final Matcher isAnalysisSetSubscriptionsParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.setSubscriptions params",
        {"subscriptions": isMapOf(isAnalysisService, isListOf(isFilePath))}));

/**
 * analysis.setSubscriptions result
 */
final Matcher isAnalysisSetSubscriptionsResult = isNull;

/**
 * analysis.updateContent params
 *
 * {
 *   "files": Map<FilePath, AddContentOverlay | ChangeContentOverlay | RemoveContentOverlay>
 * }
 */
final Matcher isAnalysisUpdateContentParams = new LazyMatcher(
    () => new MatchesJsonObject("analysis.updateContent params", {
          "files": isMapOf(
              isFilePath,
              isOneOf([
                isAddContentOverlay,
                isChangeContentOverlay,
                isRemoveContentOverlay
              ]))
        }));

/**
 * analysis.updateContent result
 *
 * {
 * }
 */
final Matcher isAnalysisUpdateContentResult = new LazyMatcher(
    () => new MatchesJsonObject("analysis.updateContent result", null));

/**
 * analysis.updateOptions params
 *
 * {
 *   "options": AnalysisOptions
 * }
 */
final Matcher isAnalysisUpdateOptionsParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "analysis.updateOptions params", {"options": isAnalysisOptions}));

/**
 * analysis.updateOptions result
 */
final Matcher isAnalysisUpdateOptionsResult = isNull;

/**
 * analytics.enable params
 *
 * {
 *   "value": bool
 * }
 */
final Matcher isAnalyticsEnableParams = new LazyMatcher(
    () => new MatchesJsonObject("analytics.enable params", {"value": isBool}));

/**
 * analytics.enable result
 */
final Matcher isAnalyticsEnableResult = isNull;

/**
 * analytics.isEnabled params
 */
final Matcher isAnalyticsIsEnabledParams = isNull;

/**
 * analytics.isEnabled result
 *
 * {
 *   "enabled": bool
 * }
 */
final Matcher isAnalyticsIsEnabledResult = new LazyMatcher(() =>
    new MatchesJsonObject("analytics.isEnabled result", {"enabled": isBool}));

/**
 * analytics.sendEvent params
 *
 * {
 *   "action": String
 * }
 */
final Matcher isAnalyticsSendEventParams = new LazyMatcher(() =>
    new MatchesJsonObject("analytics.sendEvent params", {"action": isString}));

/**
 * analytics.sendEvent result
 */
final Matcher isAnalyticsSendEventResult = isNull;

/**
 * analytics.sendTiming params
 *
 * {
 *   "event": String
 *   "millis": int
 * }
 */
final Matcher isAnalyticsSendTimingParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "analytics.sendTiming params", {"event": isString, "millis": isInt}));

/**
 * analytics.sendTiming result
 */
final Matcher isAnalyticsSendTimingResult = isNull;

/**
 * completion.getSuggestions params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isCompletionGetSuggestionsParams = new LazyMatcher(() =>
    new MatchesJsonObject("completion.getSuggestions params",
        {"file": isFilePath, "offset": isInt}));

/**
 * completion.getSuggestions result
 *
 * {
 *   "id": CompletionId
 * }
 */
final Matcher isCompletionGetSuggestionsResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "completion.getSuggestions result", {"id": isCompletionId}));

/**
 * completion.results params
 *
 * {
 *   "id": CompletionId
 *   "replacementOffset": int
 *   "replacementLength": int
 *   "results": List<CompletionSuggestion>
 *   "isLast": bool
 * }
 */
final Matcher isCompletionResultsParams =
    new LazyMatcher(() => new MatchesJsonObject("completion.results params", {
          "id": isCompletionId,
          "replacementOffset": isInt,
          "replacementLength": isInt,
          "results": isListOf(isCompletionSuggestion),
          "isLast": isBool
        }));

/**
 * convertGetterToMethod feedback
 */
final Matcher isConvertGetterToMethodFeedback = isNull;

/**
 * convertGetterToMethod options
 */
final Matcher isConvertGetterToMethodOptions = isNull;

/**
 * convertMethodToGetter feedback
 */
final Matcher isConvertMethodToGetterFeedback = isNull;

/**
 * convertMethodToGetter options
 */
final Matcher isConvertMethodToGetterOptions = isNull;

/**
 * diagnostic.getDiagnostics params
 */
final Matcher isDiagnosticGetDiagnosticsParams = isNull;

/**
 * diagnostic.getDiagnostics result
 *
 * {
 *   "contexts": List<ContextData>
 * }
 */
final Matcher isDiagnosticGetDiagnosticsResult = new LazyMatcher(() =>
    new MatchesJsonObject("diagnostic.getDiagnostics result",
        {"contexts": isListOf(isContextData)}));

/**
 * diagnostic.getServerPort params
 */
final Matcher isDiagnosticGetServerPortParams = isNull;

/**
 * diagnostic.getServerPort result
 *
 * {
 *   "port": int
 * }
 */
final Matcher isDiagnosticGetServerPortResult = new LazyMatcher(() =>
    new MatchesJsonObject("diagnostic.getServerPort result", {"port": isInt}));

/**
 * edit.format params
 *
 * {
 *   "file": FilePath
 *   "selectionOffset": int
 *   "selectionLength": int
 *   "lineLength": optional int
 * }
 */
final Matcher isEditFormatParams = new LazyMatcher(() => new MatchesJsonObject(
    "edit.format params",
    {"file": isFilePath, "selectionOffset": isInt, "selectionLength": isInt},
    optionalFields: {"lineLength": isInt}));

/**
 * edit.format result
 *
 * {
 *   "edits": List<SourceEdit>
 *   "selectionOffset": int
 *   "selectionLength": int
 * }
 */
final Matcher isEditFormatResult =
    new LazyMatcher(() => new MatchesJsonObject("edit.format result", {
          "edits": isListOf(isSourceEdit),
          "selectionOffset": isInt,
          "selectionLength": isInt
        }));

/**
 * edit.getAssists params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isEditGetAssistsParams = new LazyMatcher(() =>
    new MatchesJsonObject("edit.getAssists params",
        {"file": isFilePath, "offset": isInt, "length": isInt}));

/**
 * edit.getAssists result
 *
 * {
 *   "assists": List<SourceChange>
 * }
 */
final Matcher isEditGetAssistsResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "edit.getAssists result", {"assists": isListOf(isSourceChange)}));

/**
 * edit.getAvailableRefactorings params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isEditGetAvailableRefactoringsParams = new LazyMatcher(() =>
    new MatchesJsonObject("edit.getAvailableRefactorings params",
        {"file": isFilePath, "offset": isInt, "length": isInt}));

/**
 * edit.getAvailableRefactorings result
 *
 * {
 *   "kinds": List<RefactoringKind>
 * }
 */
final Matcher isEditGetAvailableRefactoringsResult = new LazyMatcher(() =>
    new MatchesJsonObject("edit.getAvailableRefactorings result",
        {"kinds": isListOf(isRefactoringKind)}));

/**
 * edit.getFixes params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isEditGetFixesParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "edit.getFixes params", {"file": isFilePath, "offset": isInt}));

/**
 * edit.getFixes result
 *
 * {
 *   "fixes": List<AnalysisErrorFixes>
 * }
 */
final Matcher isEditGetFixesResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "edit.getFixes result", {"fixes": isListOf(isAnalysisErrorFixes)}));

/**
 * edit.getPostfixCompletion params
 *
 * {
 *   "file": FilePath
 *   "key": String
 *   "offset": int
 * }
 */
final Matcher isEditGetPostfixCompletionParams = new LazyMatcher(() =>
    new MatchesJsonObject("edit.getPostfixCompletion params",
        {"file": isFilePath, "key": isString, "offset": isInt}));

/**
 * edit.getPostfixCompletion result
 *
 * {
 *   "change": SourceChange
 * }
 */
final Matcher isEditGetPostfixCompletionResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "edit.getPostfixCompletion result", {"change": isSourceChange}));

/**
 * edit.getRefactoring params
 *
 * {
 *   "kind": RefactoringKind
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 *   "validateOnly": bool
 *   "options": optional RefactoringOptions
 * }
 */
final Matcher isEditGetRefactoringParams =
    new LazyMatcher(() => new MatchesJsonObject("edit.getRefactoring params", {
          "kind": isRefactoringKind,
          "file": isFilePath,
          "offset": isInt,
          "length": isInt,
          "validateOnly": isBool
        }, optionalFields: {
          "options": isRefactoringOptions
        }));

/**
 * edit.getRefactoring result
 *
 * {
 *   "initialProblems": List<RefactoringProblem>
 *   "optionsProblems": List<RefactoringProblem>
 *   "finalProblems": List<RefactoringProblem>
 *   "feedback": optional RefactoringFeedback
 *   "change": optional SourceChange
 *   "potentialEdits": optional List<String>
 * }
 */
final Matcher isEditGetRefactoringResult =
    new LazyMatcher(() => new MatchesJsonObject("edit.getRefactoring result", {
          "initialProblems": isListOf(isRefactoringProblem),
          "optionsProblems": isListOf(isRefactoringProblem),
          "finalProblems": isListOf(isRefactoringProblem)
        }, optionalFields: {
          "feedback": isRefactoringFeedback,
          "change": isSourceChange,
          "potentialEdits": isListOf(isString)
        }));

/**
 * edit.getStatementCompletion params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isEditGetStatementCompletionParams = new LazyMatcher(() =>
    new MatchesJsonObject("edit.getStatementCompletion params",
        {"file": isFilePath, "offset": isInt}));

/**
 * edit.getStatementCompletion result
 *
 * {
 *   "change": SourceChange
 *   "whitespaceOnly": bool
 * }
 */
final Matcher isEditGetStatementCompletionResult = new LazyMatcher(() =>
    new MatchesJsonObject("edit.getStatementCompletion result",
        {"change": isSourceChange, "whitespaceOnly": isBool}));

/**
 * edit.importElements params
 *
 * {
 *   "file": FilePath
 *   "elements": List<ImportedElements>
 * }
 */
final Matcher isEditImportElementsParams = new LazyMatcher(() =>
    new MatchesJsonObject("edit.importElements params",
        {"file": isFilePath, "elements": isListOf(isImportedElements)}));

/**
 * edit.importElements result
 *
 * {
 *   "edits": List<SourceEdit>
 * }
 */
final Matcher isEditImportElementsResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "edit.importElements result", {"edits": isListOf(isSourceEdit)}));

/**
 * edit.isPostfixCompletionApplicable params
 *
 * {
 *   "file": FilePath
 *   "key": String
 *   "offset": int
 * }
 */
final Matcher isEditIsPostfixCompletionApplicableParams = new LazyMatcher(() =>
    new MatchesJsonObject("edit.isPostfixCompletionApplicable params",
        {"file": isFilePath, "key": isString, "offset": isInt}));

/**
 * edit.isPostfixCompletionApplicable result
 *
 * {
 *   "value": bool
 * }
 */
final Matcher isEditIsPostfixCompletionApplicableResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "edit.isPostfixCompletionApplicable result", {"value": isBool}));

/**
 * edit.listPostfixCompletionTemplates params
 */
final Matcher isEditListPostfixCompletionTemplatesParams = isNull;

/**
 * edit.listPostfixCompletionTemplates result
 *
 * {
 *   "templates": List<PostfixTemplateDescriptor>
 * }
 */
final Matcher isEditListPostfixCompletionTemplatesResult = new LazyMatcher(() =>
    new MatchesJsonObject("edit.listPostfixCompletionTemplates result",
        {"templates": isListOf(isPostfixTemplateDescriptor)}));

/**
 * edit.organizeDirectives params
 *
 * {
 *   "file": FilePath
 * }
 */
final Matcher isEditOrganizeDirectivesParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "edit.organizeDirectives params", {"file": isFilePath}));

/**
 * edit.organizeDirectives result
 *
 * {
 *   "edit": SourceFileEdit
 * }
 */
final Matcher isEditOrganizeDirectivesResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "edit.organizeDirectives result", {"edit": isSourceFileEdit}));

/**
 * edit.sortMembers params
 *
 * {
 *   "file": FilePath
 * }
 */
final Matcher isEditSortMembersParams = new LazyMatcher(() =>
    new MatchesJsonObject("edit.sortMembers params", {"file": isFilePath}));

/**
 * edit.sortMembers result
 *
 * {
 *   "edit": SourceFileEdit
 * }
 */
final Matcher isEditSortMembersResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "edit.sortMembers result", {"edit": isSourceFileEdit}));

/**
 * execution.createContext params
 *
 * {
 *   "contextRoot": FilePath
 * }
 */
final Matcher isExecutionCreateContextParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "execution.createContext params", {"contextRoot": isFilePath}));

/**
 * execution.createContext result
 *
 * {
 *   "id": ExecutionContextId
 * }
 */
final Matcher isExecutionCreateContextResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "execution.createContext result", {"id": isExecutionContextId}));

/**
 * execution.deleteContext params
 *
 * {
 *   "id": ExecutionContextId
 * }
 */
final Matcher isExecutionDeleteContextParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "execution.deleteContext params", {"id": isExecutionContextId}));

/**
 * execution.deleteContext result
 */
final Matcher isExecutionDeleteContextResult = isNull;

/**
 * execution.launchData params
 *
 * {
 *   "file": FilePath
 *   "kind": optional ExecutableKind
 *   "referencedFiles": optional List<FilePath>
 * }
 */
final Matcher isExecutionLaunchDataParams = new LazyMatcher(() =>
    new MatchesJsonObject("execution.launchData params", {
      "file": isFilePath
    }, optionalFields: {
      "kind": isExecutableKind,
      "referencedFiles": isListOf(isFilePath)
    }));

/**
 * execution.mapUri params
 *
 * {
 *   "id": ExecutionContextId
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 */
final Matcher isExecutionMapUriParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "execution.mapUri params", {"id": isExecutionContextId},
        optionalFields: {"file": isFilePath, "uri": isString}));

/**
 * execution.mapUri result
 *
 * {
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 */
final Matcher isExecutionMapUriResult = new LazyMatcher(() =>
    new MatchesJsonObject("execution.mapUri result", null,
        optionalFields: {"file": isFilePath, "uri": isString}));

/**
 * execution.setSubscriptions params
 *
 * {
 *   "subscriptions": List<ExecutionService>
 * }
 */
final Matcher isExecutionSetSubscriptionsParams = new LazyMatcher(() =>
    new MatchesJsonObject("execution.setSubscriptions params",
        {"subscriptions": isListOf(isExecutionService)}));

/**
 * execution.setSubscriptions result
 */
final Matcher isExecutionSetSubscriptionsResult = isNull;

/**
 * extractLocalVariable feedback
 *
 * {
 *   "coveringExpressionOffsets": optional List<int>
 *   "coveringExpressionLengths": optional List<int>
 *   "names": List<String>
 *   "offsets": List<int>
 *   "lengths": List<int>
 * }
 */
final Matcher isExtractLocalVariableFeedback = new LazyMatcher(
    () => new MatchesJsonObject("extractLocalVariable feedback", {
          "names": isListOf(isString),
          "offsets": isListOf(isInt),
          "lengths": isListOf(isInt)
        }, optionalFields: {
          "coveringExpressionOffsets": isListOf(isInt),
          "coveringExpressionLengths": isListOf(isInt)
        }));

/**
 * extractLocalVariable options
 *
 * {
 *   "name": String
 *   "extractAll": bool
 * }
 */
final Matcher isExtractLocalVariableOptions = new LazyMatcher(() =>
    new MatchesJsonObject("extractLocalVariable options",
        {"name": isString, "extractAll": isBool}));

/**
 * extractMethod feedback
 *
 * {
 *   "offset": int
 *   "length": int
 *   "returnType": String
 *   "names": List<String>
 *   "canCreateGetter": bool
 *   "parameters": List<RefactoringMethodParameter>
 *   "offsets": List<int>
 *   "lengths": List<int>
 * }
 */
final Matcher isExtractMethodFeedback =
    new LazyMatcher(() => new MatchesJsonObject("extractMethod feedback", {
          "offset": isInt,
          "length": isInt,
          "returnType": isString,
          "names": isListOf(isString),
          "canCreateGetter": isBool,
          "parameters": isListOf(isRefactoringMethodParameter),
          "offsets": isListOf(isInt),
          "lengths": isListOf(isInt)
        }));

/**
 * extractMethod options
 *
 * {
 *   "returnType": String
 *   "createGetter": bool
 *   "name": String
 *   "parameters": List<RefactoringMethodParameter>
 *   "extractAll": bool
 * }
 */
final Matcher isExtractMethodOptions =
    new LazyMatcher(() => new MatchesJsonObject("extractMethod options", {
          "returnType": isString,
          "createGetter": isBool,
          "name": isString,
          "parameters": isListOf(isRefactoringMethodParameter),
          "extractAll": isBool
        }));

/**
 * inlineLocalVariable feedback
 *
 * {
 *   "name": String
 *   "occurrences": int
 * }
 */
final Matcher isInlineLocalVariableFeedback = new LazyMatcher(() =>
    new MatchesJsonObject("inlineLocalVariable feedback",
        {"name": isString, "occurrences": isInt}));

/**
 * inlineLocalVariable options
 */
final Matcher isInlineLocalVariableOptions = isNull;

/**
 * inlineMethod feedback
 *
 * {
 *   "className": optional String
 *   "methodName": String
 *   "isDeclaration": bool
 * }
 */
final Matcher isInlineMethodFeedback = new LazyMatcher(() =>
    new MatchesJsonObject("inlineMethod feedback",
        {"methodName": isString, "isDeclaration": isBool},
        optionalFields: {"className": isString}));

/**
 * inlineMethod options
 *
 * {
 *   "deleteSource": bool
 *   "inlineAll": bool
 * }
 */
final Matcher isInlineMethodOptions = new LazyMatcher(() =>
    new MatchesJsonObject(
        "inlineMethod options", {"deleteSource": isBool, "inlineAll": isBool}));

/**
 * kythe.getKytheEntries params
 *
 * {
 *   "file": FilePath
 * }
 */
final Matcher isKytheGetKytheEntriesParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "kythe.getKytheEntries params", {"file": isFilePath}));

/**
 * kythe.getKytheEntries result
 *
 * {
 *   "entries": List<KytheEntry>
 *   "files": List<FilePath>
 * }
 */
final Matcher isKytheGetKytheEntriesResult = new LazyMatcher(() =>
    new MatchesJsonObject("kythe.getKytheEntries result",
        {"entries": isListOf(isKytheEntry), "files": isListOf(isFilePath)}));

/**
 * moveFile feedback
 */
final Matcher isMoveFileFeedback = isNull;

/**
 * moveFile options
 *
 * {
 *   "newFile": FilePath
 * }
 */
final Matcher isMoveFileOptions = new LazyMatcher(
    () => new MatchesJsonObject("moveFile options", {"newFile": isFilePath}));

/**
 * rename feedback
 *
 * {
 *   "offset": int
 *   "length": int
 *   "elementKindName": String
 *   "oldName": String
 * }
 */
final Matcher isRenameFeedback =
    new LazyMatcher(() => new MatchesJsonObject("rename feedback", {
          "offset": isInt,
          "length": isInt,
          "elementKindName": isString,
          "oldName": isString
        }));

/**
 * rename options
 *
 * {
 *   "newName": String
 * }
 */
final Matcher isRenameOptions = new LazyMatcher(
    () => new MatchesJsonObject("rename options", {"newName": isString}));

/**
 * search.findElementReferences params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "includePotential": bool
 * }
 */
final Matcher isSearchFindElementReferencesParams = new LazyMatcher(() =>
    new MatchesJsonObject("search.findElementReferences params",
        {"file": isFilePath, "offset": isInt, "includePotential": isBool}));

/**
 * search.findElementReferences result
 *
 * {
 *   "id": optional SearchId
 *   "element": optional Element
 * }
 */
final Matcher isSearchFindElementReferencesResult = new LazyMatcher(() =>
    new MatchesJsonObject("search.findElementReferences result", null,
        optionalFields: {"id": isSearchId, "element": isElement}));

/**
 * search.findMemberDeclarations params
 *
 * {
 *   "name": String
 * }
 */
final Matcher isSearchFindMemberDeclarationsParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "search.findMemberDeclarations params", {"name": isString}));

/**
 * search.findMemberDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 */
final Matcher isSearchFindMemberDeclarationsResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "search.findMemberDeclarations result", {"id": isSearchId}));

/**
 * search.findMemberReferences params
 *
 * {
 *   "name": String
 * }
 */
final Matcher isSearchFindMemberReferencesParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "search.findMemberReferences params", {"name": isString}));

/**
 * search.findMemberReferences result
 *
 * {
 *   "id": SearchId
 * }
 */
final Matcher isSearchFindMemberReferencesResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "search.findMemberReferences result", {"id": isSearchId}));

/**
 * search.findTopLevelDeclarations params
 *
 * {
 *   "pattern": String
 * }
 */
final Matcher isSearchFindTopLevelDeclarationsParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "search.findTopLevelDeclarations params", {"pattern": isString}));

/**
 * search.findTopLevelDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 */
final Matcher isSearchFindTopLevelDeclarationsResult = new LazyMatcher(() =>
    new MatchesJsonObject(
        "search.findTopLevelDeclarations result", {"id": isSearchId}));

/**
 * search.getTypeHierarchy params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "superOnly": optional bool
 * }
 */
final Matcher isSearchGetTypeHierarchyParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "search.getTypeHierarchy params", {"file": isFilePath, "offset": isInt},
        optionalFields: {"superOnly": isBool}));

/**
 * search.getTypeHierarchy result
 *
 * {
 *   "hierarchyItems": optional List<TypeHierarchyItem>
 * }
 */
final Matcher isSearchGetTypeHierarchyResult = new LazyMatcher(() =>
    new MatchesJsonObject("search.getTypeHierarchy result", null,
        optionalFields: {"hierarchyItems": isListOf(isTypeHierarchyItem)}));

/**
 * search.results params
 *
 * {
 *   "id": SearchId
 *   "results": List<SearchResult>
 *   "isLast": bool
 * }
 */
final Matcher isSearchResultsParams = new LazyMatcher(() =>
    new MatchesJsonObject("search.results params", {
      "id": isSearchId,
      "results": isListOf(isSearchResult),
      "isLast": isBool
    }));

/**
 * server.connected params
 *
 * {
 *   "version": String
 *   "pid": int
 *   "sessionId": optional String
 * }
 */
final Matcher isServerConnectedParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "server.connected params", {"version": isString, "pid": isInt},
        optionalFields: {"sessionId": isString}));

/**
 * server.error params
 *
 * {
 *   "isFatal": bool
 *   "message": String
 *   "stackTrace": String
 * }
 */
final Matcher isServerErrorParams = new LazyMatcher(() => new MatchesJsonObject(
    "server.error params",
    {"isFatal": isBool, "message": isString, "stackTrace": isString}));

/**
 * server.getVersion params
 */
final Matcher isServerGetVersionParams = isNull;

/**
 * server.getVersion result
 *
 * {
 *   "version": String
 * }
 */
final Matcher isServerGetVersionResult = new LazyMatcher(() =>
    new MatchesJsonObject("server.getVersion result", {"version": isString}));

/**
 * server.setSubscriptions params
 *
 * {
 *   "subscriptions": List<ServerService>
 * }
 */
final Matcher isServerSetSubscriptionsParams = new LazyMatcher(() =>
    new MatchesJsonObject("server.setSubscriptions params",
        {"subscriptions": isListOf(isServerService)}));

/**
 * server.setSubscriptions result
 */
final Matcher isServerSetSubscriptionsResult = isNull;

/**
 * server.shutdown params
 */
final Matcher isServerShutdownParams = isNull;

/**
 * server.shutdown result
 */
final Matcher isServerShutdownResult = isNull;

/**
 * server.status params
 *
 * {
 *   "analysis": optional AnalysisStatus
 *   "pub": optional PubStatus
 * }
 */
final Matcher isServerStatusParams = new LazyMatcher(() =>
    new MatchesJsonObject("server.status params", null,
        optionalFields: {"analysis": isAnalysisStatus, "pub": isPubStatus}));
