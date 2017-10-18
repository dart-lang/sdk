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
 *   "fixes": List<PrioritizedSourceChange>
 * }
 */
final Matcher isAnalysisErrorFixes = new LazyMatcher(() =>
    new MatchesJsonObject("AnalysisErrorFixes", {
      "error": isAnalysisError,
      "fixes": isListOf(isPrioritizedSourceChange)
    }));

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
 * AnalysisService
 *
 * enum {
 *   FOLDING
 *   HIGHLIGHTS
 *   NAVIGATION
 *   OCCURRENCES
 *   OUTLINE
 * }
 */
final Matcher isAnalysisService = new MatchesEnum("AnalysisService",
    ["FOLDING", "HIGHLIGHTS", "NAVIGATION", "OCCURRENCES", "OUTLINE"]);

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
 * ContextRoot
 *
 * {
 *   "root": FilePath
 *   "exclude": List<FilePath>
 *   "optionsFile": optional FilePath
 * }
 */
final Matcher isContextRoot = new LazyMatcher(() => new MatchesJsonObject(
    "ContextRoot", {"root": isFilePath, "exclude": isListOf(isFilePath)},
    optionalFields: {"optionsFile": isFilePath}));

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
 *   CONSTRUCTOR_INVOCATION
 *   ENUM
 *   ENUM_CONSTANT
 *   FIELD
 *   FILE
 *   FUNCTION
 *   FUNCTION_INVOCATION
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
  "CONSTRUCTOR_INVOCATION",
  "ENUM",
  "ENUM_CONSTANT",
  "FIELD",
  "FILE",
  "FUNCTION",
  "FUNCTION_INVOCATION",
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
 * KytheEntry
 *
 * {
 *   "source": KytheVName
 *   "kind": optional String
 *   "target": optional KytheVName
 *   "fact": String
 *   "value": optional List<int>
 * }
 */
final Matcher isKytheEntry = new LazyMatcher(() => new MatchesJsonObject(
        "KytheEntry", {
      "source": isKytheVName,
      "fact": isString
    }, optionalFields: {
      "kind": isString,
      "target": isKytheVName,
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
 * PrioritizedSourceChange
 *
 * {
 *   "priority": int
 *   "change": SourceChange
 * }
 */
final Matcher isPrioritizedSourceChange = new LazyMatcher(() =>
    new MatchesJsonObject("PrioritizedSourceChange",
        {"priority": isInt, "change": isSourceChange}));

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
 *   INVALID_OVERLAY_CHANGE
 *   INVALID_PARAMETER
 *   PLUGIN_ERROR
 *   UNKNOWN_REQUEST
 * }
 */
final Matcher isRequestErrorCode = new MatchesEnum("RequestErrorCode", [
  "INVALID_OVERLAY_CHANGE",
  "INVALID_PARAMETER",
  "PLUGIN_ERROR",
  "UNKNOWN_REQUEST"
]);

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
 * WatchEvent
 *
 * {
 *   "type": WatchEventType
 *   "path": FilePath
 * }
 */
final Matcher isWatchEvent = new LazyMatcher(() => new MatchesJsonObject(
    "WatchEvent", {"type": isWatchEventType, "path": isFilePath}));

/**
 * WatchEventType
 *
 * enum {
 *   ADD
 *   MODIFY
 *   REMOVE
 * }
 */
final Matcher isWatchEventType =
    new MatchesEnum("WatchEventType", ["ADD", "MODIFY", "REMOVE"]);

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
 * analysis.handleWatchEvents params
 *
 * {
 *   "events": List<WatchEvent>
 * }
 */
final Matcher isAnalysisHandleWatchEventsParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.handleWatchEvents params",
        {"events": isListOf(isWatchEvent)}));

/**
 * analysis.handleWatchEvents result
 */
final Matcher isAnalysisHandleWatchEventsResult = isNull;

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
 *   "outline": List<Outline>
 * }
 */
final Matcher isAnalysisOutlineParams = new LazyMatcher(() =>
    new MatchesJsonObject("analysis.outline params",
        {"file": isFilePath, "outline": isListOf(isOutline)}));

/**
 * analysis.setContextRoots params
 *
 * {
 *   "roots": List<ContextRoot>
 * }
 */
final Matcher isAnalysisSetContextRootsParams = new LazyMatcher(() =>
    new MatchesJsonObject(
        "analysis.setContextRoots params", {"roots": isListOf(isContextRoot)}));

/**
 * analysis.setContextRoots result
 */
final Matcher isAnalysisSetContextRootsResult = isNull;

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
 */
final Matcher isAnalysisUpdateContentResult = isNull;

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
 *   "replacementOffset": int
 *   "replacementLength": int
 *   "results": List<CompletionSuggestion>
 * }
 */
final Matcher isCompletionGetSuggestionsResult = new LazyMatcher(
    () => new MatchesJsonObject("completion.getSuggestions result", {
          "replacementOffset": isInt,
          "replacementLength": isInt,
          "results": isListOf(isCompletionSuggestion)
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
 *   "assists": List<PrioritizedSourceChange>
 * }
 */
final Matcher isEditGetAssistsResult = new LazyMatcher(() =>
    new MatchesJsonObject("edit.getAssists result",
        {"assists": isListOf(isPrioritizedSourceChange)}));

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
 * plugin.error params
 *
 * {
 *   "isFatal": bool
 *   "message": String
 *   "stackTrace": String
 * }
 */
final Matcher isPluginErrorParams = new LazyMatcher(() => new MatchesJsonObject(
    "plugin.error params",
    {"isFatal": isBool, "message": isString, "stackTrace": isString}));

/**
 * plugin.shutdown params
 */
final Matcher isPluginShutdownParams = isNull;

/**
 * plugin.shutdown result
 */
final Matcher isPluginShutdownResult = isNull;

/**
 * plugin.versionCheck params
 *
 * {
 *   "byteStorePath": FilePath
 *   "sdkPath": FilePath
 *   "version": String
 * }
 */
final Matcher isPluginVersionCheckParams = new LazyMatcher(() =>
    new MatchesJsonObject("plugin.versionCheck params", {
      "byteStorePath": isFilePath,
      "sdkPath": isFilePath,
      "version": isString
    }));

/**
 * plugin.versionCheck result
 *
 * {
 *   "isCompatible": bool
 *   "name": String
 *   "version": String
 *   "contactInfo": optional String
 *   "interestingFiles": List<String>
 * }
 */
final Matcher isPluginVersionCheckResult =
    new LazyMatcher(() => new MatchesJsonObject("plugin.versionCheck result", {
          "isCompatible": isBool,
          "name": isString,
          "version": isString,
          "interestingFiles": isListOf(isString)
        }, optionalFields: {
          "contactInfo": isString
        }));

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
