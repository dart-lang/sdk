// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/spec/generate_files".

/**
 * Matchers for data types defined in the analysis server API
 */
library test.integration.protocol.matchers;

import 'package:unittest/unittest.dart';

import 'integration_tests.dart';


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
final Matcher isServerGetVersionResult = new LazyMatcher(() => new MatchesJsonObject(
  "server.getVersion result", {
    "version": isString
  }));

/**
 * server.shutdown params
 */
final Matcher isServerShutdownParams = isNull;

/**
 * server.shutdown result
 */
final Matcher isServerShutdownResult = isNull;

/**
 * server.setSubscriptions params
 *
 * {
 *   "subscriptions": List<ServerService>
 * }
 */
final Matcher isServerSetSubscriptionsParams = new LazyMatcher(() => new MatchesJsonObject(
  "server.setSubscriptions params", {
    "subscriptions": isListOf(isServerService)
  }));

/**
 * server.setSubscriptions result
 */
final Matcher isServerSetSubscriptionsResult = isNull;

/**
 * server.connected params
 */
final Matcher isServerConnectedParams = isNull;

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
  "server.error params", {
    "isFatal": isBool,
    "message": isString,
    "stackTrace": isString
  }));

/**
 * server.status params
 *
 * {
 *   "analysis": optional AnalysisStatus
 * }
 */
final Matcher isServerStatusParams = new LazyMatcher(() => new MatchesJsonObject(
  "server.status params", null, optionalFields: {
    "analysis": isAnalysisStatus
  }));

/**
 * analysis.getErrors params
 *
 * {
 *   "file": FilePath
 * }
 */
final Matcher isAnalysisGetErrorsParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.getErrors params", {
    "file": isFilePath
  }));

/**
 * analysis.getErrors result
 *
 * {
 *   "errors": List<AnalysisError>
 * }
 */
final Matcher isAnalysisGetErrorsResult = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.getErrors result", {
    "errors": isListOf(isAnalysisError)
  }));

/**
 * analysis.getHover params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isAnalysisGetHoverParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.getHover params", {
    "file": isFilePath,
    "offset": isInt
  }));

/**
 * analysis.getHover result
 *
 * {
 *   "hovers": List<HoverInformation>
 * }
 */
final Matcher isAnalysisGetHoverResult = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.getHover result", {
    "hovers": isListOf(isHoverInformation)
  }));

/**
 * analysis.reanalyze params
 */
final Matcher isAnalysisReanalyzeParams = isNull;

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
 * }
 */
final Matcher isAnalysisSetAnalysisRootsParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.setAnalysisRoots params", {
    "included": isListOf(isFilePath),
    "excluded": isListOf(isFilePath)
  }));

/**
 * analysis.setAnalysisRoots result
 */
final Matcher isAnalysisSetAnalysisRootsResult = isNull;

/**
 * analysis.setPriorityFiles params
 *
 * {
 *   "files": List<FilePath>
 * }
 */
final Matcher isAnalysisSetPriorityFilesParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.setPriorityFiles params", {
    "files": isListOf(isFilePath)
  }));

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
final Matcher isAnalysisSetSubscriptionsParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.setSubscriptions params", {
    "subscriptions": isMapOf(isAnalysisService, isListOf(isFilePath))
  }));

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
final Matcher isAnalysisUpdateContentParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.updateContent params", {
    "files": isMapOf(isFilePath, isOneOf([isAddContentOverlay, isChangeContentOverlay, isRemoveContentOverlay]))
  }));

/**
 * analysis.updateContent result
 */
final Matcher isAnalysisUpdateContentResult = isNull;

/**
 * analysis.updateOptions params
 *
 * {
 *   "options": AnalysisOptions
 * }
 */
final Matcher isAnalysisUpdateOptionsParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.updateOptions params", {
    "options": isAnalysisOptions
  }));

/**
 * analysis.updateOptions result
 */
final Matcher isAnalysisUpdateOptionsResult = isNull;

/**
 * analysis.errors params
 *
 * {
 *   "file": FilePath
 *   "errors": List<AnalysisError>
 * }
 */
final Matcher isAnalysisErrorsParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.errors params", {
    "file": isFilePath,
    "errors": isListOf(isAnalysisError)
  }));

/**
 * analysis.flushResults params
 *
 * {
 *   "files": List<FilePath>
 * }
 */
final Matcher isAnalysisFlushResultsParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.flushResults params", {
    "files": isListOf(isFilePath)
  }));

/**
 * analysis.folding params
 *
 * {
 *   "file": FilePath
 *   "regions": List<FoldingRegion>
 * }
 */
final Matcher isAnalysisFoldingParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.folding params", {
    "file": isFilePath,
    "regions": isListOf(isFoldingRegion)
  }));

/**
 * analysis.highlights params
 *
 * {
 *   "file": FilePath
 *   "regions": List<HighlightRegion>
 * }
 */
final Matcher isAnalysisHighlightsParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.highlights params", {
    "file": isFilePath,
    "regions": isListOf(isHighlightRegion)
  }));

/**
 * analysis.navigation params
 *
 * {
 *   "file": FilePath
 *   "regions": List<NavigationRegion>
 * }
 */
final Matcher isAnalysisNavigationParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.navigation params", {
    "file": isFilePath,
    "regions": isListOf(isNavigationRegion)
  }));

/**
 * analysis.occurrences params
 *
 * {
 *   "file": FilePath
 *   "occurrences": List<Occurrences>
 * }
 */
final Matcher isAnalysisOccurrencesParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.occurrences params", {
    "file": isFilePath,
    "occurrences": isListOf(isOccurrences)
  }));

/**
 * analysis.outline params
 *
 * {
 *   "file": FilePath
 *   "outline": Outline
 * }
 */
final Matcher isAnalysisOutlineParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.outline params", {
    "file": isFilePath,
    "outline": isOutline
  }));

/**
 * analysis.overrides params
 *
 * {
 *   "file": FilePath
 *   "overrides": List<Override>
 * }
 */
final Matcher isAnalysisOverridesParams = new LazyMatcher(() => new MatchesJsonObject(
  "analysis.overrides params", {
    "file": isFilePath,
    "overrides": isListOf(isOverride)
  }));

/**
 * completion.getSuggestions params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isCompletionGetSuggestionsParams = new LazyMatcher(() => new MatchesJsonObject(
  "completion.getSuggestions params", {
    "file": isFilePath,
    "offset": isInt
  }));

/**
 * completion.getSuggestions result
 *
 * {
 *   "id": CompletionId
 * }
 */
final Matcher isCompletionGetSuggestionsResult = new LazyMatcher(() => new MatchesJsonObject(
  "completion.getSuggestions result", {
    "id": isCompletionId
  }));

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
final Matcher isCompletionResultsParams = new LazyMatcher(() => new MatchesJsonObject(
  "completion.results params", {
    "id": isCompletionId,
    "replacementOffset": isInt,
    "replacementLength": isInt,
    "results": isListOf(isCompletionSuggestion),
    "isLast": isBool
  }));

/**
 * search.findElementReferences params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "includePotential": bool
 * }
 */
final Matcher isSearchFindElementReferencesParams = new LazyMatcher(() => new MatchesJsonObject(
  "search.findElementReferences params", {
    "file": isFilePath,
    "offset": isInt,
    "includePotential": isBool
  }));

/**
 * search.findElementReferences result
 *
 * {
 *   "id": optional SearchId
 *   "element": optional Element
 * }
 */
final Matcher isSearchFindElementReferencesResult = new LazyMatcher(() => new MatchesJsonObject(
  "search.findElementReferences result", null, optionalFields: {
    "id": isSearchId,
    "element": isElement
  }));

/**
 * search.findMemberDeclarations params
 *
 * {
 *   "name": String
 * }
 */
final Matcher isSearchFindMemberDeclarationsParams = new LazyMatcher(() => new MatchesJsonObject(
  "search.findMemberDeclarations params", {
    "name": isString
  }));

/**
 * search.findMemberDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 */
final Matcher isSearchFindMemberDeclarationsResult = new LazyMatcher(() => new MatchesJsonObject(
  "search.findMemberDeclarations result", {
    "id": isSearchId
  }));

/**
 * search.findMemberReferences params
 *
 * {
 *   "name": String
 * }
 */
final Matcher isSearchFindMemberReferencesParams = new LazyMatcher(() => new MatchesJsonObject(
  "search.findMemberReferences params", {
    "name": isString
  }));

/**
 * search.findMemberReferences result
 *
 * {
 *   "id": SearchId
 * }
 */
final Matcher isSearchFindMemberReferencesResult = new LazyMatcher(() => new MatchesJsonObject(
  "search.findMemberReferences result", {
    "id": isSearchId
  }));

/**
 * search.findTopLevelDeclarations params
 *
 * {
 *   "pattern": String
 * }
 */
final Matcher isSearchFindTopLevelDeclarationsParams = new LazyMatcher(() => new MatchesJsonObject(
  "search.findTopLevelDeclarations params", {
    "pattern": isString
  }));

/**
 * search.findTopLevelDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 */
final Matcher isSearchFindTopLevelDeclarationsResult = new LazyMatcher(() => new MatchesJsonObject(
  "search.findTopLevelDeclarations result", {
    "id": isSearchId
  }));

/**
 * search.getTypeHierarchy params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isSearchGetTypeHierarchyParams = new LazyMatcher(() => new MatchesJsonObject(
  "search.getTypeHierarchy params", {
    "file": isFilePath,
    "offset": isInt
  }));

/**
 * search.getTypeHierarchy result
 *
 * {
 *   "hierarchyItems": optional List<TypeHierarchyItem>
 * }
 */
final Matcher isSearchGetTypeHierarchyResult = new LazyMatcher(() => new MatchesJsonObject(
  "search.getTypeHierarchy result", null, optionalFields: {
    "hierarchyItems": isListOf(isTypeHierarchyItem)
  }));

/**
 * search.results params
 *
 * {
 *   "id": SearchId
 *   "results": List<SearchResult>
 *   "isLast": bool
 * }
 */
final Matcher isSearchResultsParams = new LazyMatcher(() => new MatchesJsonObject(
  "search.results params", {
    "id": isSearchId,
    "results": isListOf(isSearchResult),
    "isLast": isBool
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
final Matcher isEditGetAssistsParams = new LazyMatcher(() => new MatchesJsonObject(
  "edit.getAssists params", {
    "file": isFilePath,
    "offset": isInt,
    "length": isInt
  }));

/**
 * edit.getAssists result
 *
 * {
 *   "assists": List<SourceChange>
 * }
 */
final Matcher isEditGetAssistsResult = new LazyMatcher(() => new MatchesJsonObject(
  "edit.getAssists result", {
    "assists": isListOf(isSourceChange)
  }));

/**
 * edit.getAvailableRefactorings params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isEditGetAvailableRefactoringsParams = new LazyMatcher(() => new MatchesJsonObject(
  "edit.getAvailableRefactorings params", {
    "file": isFilePath,
    "offset": isInt,
    "length": isInt
  }));

/**
 * edit.getAvailableRefactorings result
 *
 * {
 *   "kinds": List<RefactoringKind>
 * }
 */
final Matcher isEditGetAvailableRefactoringsResult = new LazyMatcher(() => new MatchesJsonObject(
  "edit.getAvailableRefactorings result", {
    "kinds": isListOf(isRefactoringKind)
  }));

/**
 * edit.getFixes params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isEditGetFixesParams = new LazyMatcher(() => new MatchesJsonObject(
  "edit.getFixes params", {
    "file": isFilePath,
    "offset": isInt
  }));

/**
 * edit.getFixes result
 *
 * {
 *   "fixes": List<AnalysisErrorFixes>
 * }
 */
final Matcher isEditGetFixesResult = new LazyMatcher(() => new MatchesJsonObject(
  "edit.getFixes result", {
    "fixes": isListOf(isAnalysisErrorFixes)
  }));

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
final Matcher isEditGetRefactoringParams = new LazyMatcher(() => new MatchesJsonObject(
  "edit.getRefactoring params", {
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
 *   "problems": List<RefactoringProblem>
 *   "feedback": optional RefactoringFeedback
 *   "change": optional SourceChange
 *   "potentialEdits": optional List<String>
 * }
 */
final Matcher isEditGetRefactoringResult = new LazyMatcher(() => new MatchesJsonObject(
  "edit.getRefactoring result", {
    "problems": isListOf(isRefactoringProblem)
  }, optionalFields: {
    "feedback": isRefactoringFeedback,
    "change": isSourceChange,
    "potentialEdits": isListOf(isString)
  }));

/**
 * execution.createContext params
 *
 * {
 *   "contextRoot": FilePath
 * }
 */
final Matcher isExecutionCreateContextParams = new LazyMatcher(() => new MatchesJsonObject(
  "execution.createContext params", {
    "contextRoot": isFilePath
  }));

/**
 * execution.createContext result
 *
 * {
 *   "id": ExecutionContextId
 * }
 */
final Matcher isExecutionCreateContextResult = new LazyMatcher(() => new MatchesJsonObject(
  "execution.createContext result", {
    "id": isExecutionContextId
  }));

/**
 * execution.deleteContext params
 *
 * {
 *   "id": ExecutionContextId
 * }
 */
final Matcher isExecutionDeleteContextParams = new LazyMatcher(() => new MatchesJsonObject(
  "execution.deleteContext params", {
    "id": isExecutionContextId
  }));

/**
 * execution.deleteContext result
 */
final Matcher isExecutionDeleteContextResult = isNull;

/**
 * execution.mapUri params
 *
 * {
 *   "id": ExecutionContextId
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 */
final Matcher isExecutionMapUriParams = new LazyMatcher(() => new MatchesJsonObject(
  "execution.mapUri params", {
    "id": isExecutionContextId
  }, optionalFields: {
    "file": isFilePath,
    "uri": isString
  }));

/**
 * execution.mapUri result
 *
 * {
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 */
final Matcher isExecutionMapUriResult = new LazyMatcher(() => new MatchesJsonObject(
  "execution.mapUri result", null, optionalFields: {
    "file": isFilePath,
    "uri": isString
  }));

/**
 * execution.setSubscriptions params
 *
 * {
 *   "subscriptions": List<ExecutionService>
 * }
 */
final Matcher isExecutionSetSubscriptionsParams = new LazyMatcher(() => new MatchesJsonObject(
  "execution.setSubscriptions params", {
    "subscriptions": isListOf(isExecutionService)
  }));

/**
 * execution.setSubscriptions result
 */
final Matcher isExecutionSetSubscriptionsResult = isNull;

/**
 * execution.launchData params
 *
 * {
 *   "executables": List<ExecutableFile>
 *   "dartToHtml": Map<FilePath, List<FilePath>>
 *   "htmlToDart": Map<FilePath, List<FilePath>>
 * }
 */
final Matcher isExecutionLaunchDataParams = new LazyMatcher(() => new MatchesJsonObject(
  "execution.launchData params", {
    "executables": isListOf(isExecutableFile),
    "dartToHtml": isMapOf(isFilePath, isListOf(isFilePath)),
    "htmlToDart": isMapOf(isFilePath, isListOf(isFilePath))
  }));

/**
 * AddContentOverlay
 *
 * {
 *   "type": "add"
 *   "content": String
 * }
 */
final Matcher isAddContentOverlay = new LazyMatcher(() => new MatchesJsonObject(
  "AddContentOverlay", {
    "type": equals("add"),
    "content": isString
  }));

/**
 * AnalysisError
 *
 * {
 *   "severity": AnalysisErrorSeverity
 *   "type": AnalysisErrorType
 *   "location": Location
 *   "message": String
 *   "correction": optional String
 * }
 */
final Matcher isAnalysisError = new LazyMatcher(() => new MatchesJsonObject(
  "AnalysisError", {
    "severity": isAnalysisErrorSeverity,
    "type": isAnalysisErrorType,
    "location": isLocation,
    "message": isString
  }, optionalFields: {
    "correction": isString
  }));

/**
 * AnalysisErrorFixes
 *
 * {
 *   "error": AnalysisError
 *   "fixes": List<SourceChange>
 * }
 */
final Matcher isAnalysisErrorFixes = new LazyMatcher(() => new MatchesJsonObject(
  "AnalysisErrorFixes", {
    "error": isAnalysisError,
    "fixes": isListOf(isSourceChange)
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
final Matcher isAnalysisErrorSeverity = new MatchesEnum("AnalysisErrorSeverity", [
  "INFO",
  "WARNING",
  "ERROR"
]);

/**
 * AnalysisErrorType
 *
 * enum {
 *   COMPILE_TIME_ERROR
 *   HINT
 *   STATIC_TYPE_WARNING
 *   STATIC_WARNING
 *   SYNTACTIC_ERROR
 *   TODO
 * }
 */
final Matcher isAnalysisErrorType = new MatchesEnum("AnalysisErrorType", [
  "COMPILE_TIME_ERROR",
  "HINT",
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
 *   "generateDart2jsHints": optional bool
 *   "generateHints": optional bool
 * }
 */
final Matcher isAnalysisOptions = new LazyMatcher(() => new MatchesJsonObject(
  "AnalysisOptions", null, optionalFields: {
    "enableAsync": isBool,
    "enableDeferredLoading": isBool,
    "enableEnums": isBool,
    "generateDart2jsHints": isBool,
    "generateHints": isBool
  }));

/**
 * AnalysisService
 *
 * enum {
 *   FOLDING
 *   HIGHLIGHTS
 *   NAVIGATION
 *   OCCURRENCES
 *   OUTLINE
 *   OVERRIDES
 * }
 */
final Matcher isAnalysisService = new MatchesEnum("AnalysisService", [
  "FOLDING",
  "HIGHLIGHTS",
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
  "AnalysisStatus", {
    "isAnalyzing": isBool
  }, optionalFields: {
    "analysisTarget": isString
  }));

/**
 * ChangeContentOverlay
 *
 * {
 *   "type": "change"
 *   "edits": List<SourceEdit>
 * }
 */
final Matcher isChangeContentOverlay = new LazyMatcher(() => new MatchesJsonObject(
  "ChangeContentOverlay", {
    "type": equals("change"),
    "edits": isListOf(isSourceEdit)
  }));

/**
 * CompletionId
 *
 * String
 */
final Matcher isCompletionId = isString;

/**
 * CompletionRelevance
 *
 * enum {
 *   LOW
 *   DEFAULT
 *   HIGH
 * }
 */
final Matcher isCompletionRelevance = new MatchesEnum("CompletionRelevance", [
  "LOW",
  "DEFAULT",
  "HIGH"
]);

/**
 * CompletionSuggestion
 *
 * {
 *   "kind": CompletionSuggestionKind
 *   "relevance": CompletionRelevance
 *   "completion": String
 *   "selectionOffset": int
 *   "selectionLength": int
 *   "isDeprecated": bool
 *   "isPotential": bool
 *   "docSummary": optional String
 *   "docComplete": optional String
 *   "declaringType": optional String
 *   "returnType": optional String
 *   "parameterNames": optional List<String>
 *   "parameterTypes": optional List<String>
 *   "requiredParameterCount": optional int
 *   "positionalParameterCount": optional int
 *   "parameterName": optional String
 *   "parameterType": optional String
 * }
 */
final Matcher isCompletionSuggestion = new LazyMatcher(() => new MatchesJsonObject(
  "CompletionSuggestion", {
    "kind": isCompletionSuggestionKind,
    "relevance": isCompletionRelevance,
    "completion": isString,
    "selectionOffset": isInt,
    "selectionLength": isInt,
    "isDeprecated": isBool,
    "isPotential": isBool
  }, optionalFields: {
    "docSummary": isString,
    "docComplete": isString,
    "declaringType": isString,
    "returnType": isString,
    "parameterNames": isListOf(isString),
    "parameterTypes": isListOf(isString),
    "requiredParameterCount": isInt,
    "positionalParameterCount": isInt,
    "parameterName": isString,
    "parameterType": isString
  }));

/**
 * CompletionSuggestionKind
 *
 * enum {
 *   ARGUMENT_LIST
 *   CLASS
 *   CLASS_ALIAS
 *   CONSTRUCTOR
 *   FIELD
 *   FUNCTION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER
 *   IMPORT
 *   KEYWORD
 *   LIBRARY_PREFIX
 *   LOCAL_VARIABLE
 *   METHOD
 *   METHOD_NAME
 *   NAMED_ARGUMENT
 *   OPTIONAL_ARGUMENT
 *   PARAMETER
 *   SETTER
 *   TOP_LEVEL_VARIABLE
 *   TYPE_PARAMETER
 * }
 */
final Matcher isCompletionSuggestionKind = new MatchesEnum("CompletionSuggestionKind", [
  "ARGUMENT_LIST",
  "CLASS",
  "CLASS_ALIAS",
  "CONSTRUCTOR",
  "FIELD",
  "FUNCTION",
  "FUNCTION_TYPE_ALIAS",
  "GETTER",
  "IMPORT",
  "KEYWORD",
  "LIBRARY_PREFIX",
  "LOCAL_VARIABLE",
  "METHOD",
  "METHOD_NAME",
  "NAMED_ARGUMENT",
  "OPTIONAL_ARGUMENT",
  "PARAMETER",
  "SETTER",
  "TOP_LEVEL_VARIABLE",
  "TYPE_PARAMETER"
]);

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
 * }
 */
final Matcher isElement = new LazyMatcher(() => new MatchesJsonObject(
  "Element", {
    "kind": isElementKind,
    "name": isString,
    "flags": isInt
  }, optionalFields: {
    "location": isLocation,
    "parameters": isString,
    "returnType": isString
  }));

/**
 * ElementKind
 *
 * enum {
 *   CLASS
 *   CLASS_TYPE_ALIAS
 *   COMPILATION_UNIT
 *   CONSTRUCTOR
 *   FIELD
 *   FUNCTION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER
 *   LIBRARY
 *   LOCAL_VARIABLE
 *   METHOD
 *   PARAMETER
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
  "FIELD",
  "FUNCTION",
  "FUNCTION_TYPE_ALIAS",
  "GETTER",
  "LIBRARY",
  "LOCAL_VARIABLE",
  "METHOD",
  "PARAMETER",
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
  "ExecutableFile", {
    "file": isFilePath,
    "kind": isExecutableKind
  }));

/**
 * ExecutableKind
 *
 * enum {
 *   CLIENT
 *   EITHER
 *   SERVER
 * }
 */
final Matcher isExecutableKind = new MatchesEnum("ExecutableKind", [
  "CLIENT",
  "EITHER",
  "SERVER"
]);

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
final Matcher isExecutionService = new MatchesEnum("ExecutionService", [
  "LAUNCH_DATA"
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
  "FoldingRegion", {
    "kind": isFoldingKind,
    "offset": isInt,
    "length": isInt
  }));

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
  "HighlightRegion", {
    "type": isHighlightRegionType,
    "offset": isInt,
    "length": isInt
  }));

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
 *   FIELD
 *   FIELD_STATIC
 *   FUNCTION
 *   FUNCTION_DECLARATION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER_DECLARATION
 *   IDENTIFIER_DEFAULT
 *   IMPORT_PREFIX
 *   KEYWORD
 *   LITERAL_BOOLEAN
 *   LITERAL_DOUBLE
 *   LITERAL_INTEGER
 *   LITERAL_LIST
 *   LITERAL_MAP
 *   LITERAL_STRING
 *   LOCAL_VARIABLE
 *   LOCAL_VARIABLE_DECLARATION
 *   METHOD
 *   METHOD_DECLARATION
 *   METHOD_DECLARATION_STATIC
 *   METHOD_STATIC
 *   PARAMETER
 *   SETTER_DECLARATION
 *   TOP_LEVEL_VARIABLE
 *   TYPE_NAME_DYNAMIC
 *   TYPE_PARAMETER
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
  "FIELD",
  "FIELD_STATIC",
  "FUNCTION",
  "FUNCTION_DECLARATION",
  "FUNCTION_TYPE_ALIAS",
  "GETTER_DECLARATION",
  "IDENTIFIER_DEFAULT",
  "IMPORT_PREFIX",
  "KEYWORD",
  "LITERAL_BOOLEAN",
  "LITERAL_DOUBLE",
  "LITERAL_INTEGER",
  "LITERAL_LIST",
  "LITERAL_MAP",
  "LITERAL_STRING",
  "LOCAL_VARIABLE",
  "LOCAL_VARIABLE_DECLARATION",
  "METHOD",
  "METHOD_DECLARATION",
  "METHOD_DECLARATION_STATIC",
  "METHOD_STATIC",
  "PARAMETER",
  "SETTER_DECLARATION",
  "TOP_LEVEL_VARIABLE",
  "TYPE_NAME_DYNAMIC",
  "TYPE_PARAMETER"
]);

/**
 * HoverInformation
 *
 * {
 *   "offset": int
 *   "length": int
 *   "containingLibraryPath": optional String
 *   "containingLibraryName": optional String
 *   "dartdoc": optional String
 *   "elementDescription": optional String
 *   "elementKind": optional String
 *   "parameter": optional String
 *   "propagatedType": optional String
 *   "staticType": optional String
 * }
 */
final Matcher isHoverInformation = new LazyMatcher(() => new MatchesJsonObject(
  "HoverInformation", {
    "offset": isInt,
    "length": isInt
  }, optionalFields: {
    "containingLibraryPath": isString,
    "containingLibraryName": isString,
    "dartdoc": isString,
    "elementDescription": isString,
    "elementKind": isString,
    "parameter": isString,
    "propagatedType": isString,
    "staticType": isString
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
final Matcher isLinkedEditGroup = new LazyMatcher(() => new MatchesJsonObject(
  "LinkedEditGroup", {
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
final Matcher isLinkedEditSuggestion = new LazyMatcher(() => new MatchesJsonObject(
  "LinkedEditSuggestion", {
    "value": isString,
    "kind": isLinkedEditSuggestionKind
  }));

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
final Matcher isLinkedEditSuggestionKind = new MatchesEnum("LinkedEditSuggestionKind", [
  "METHOD",
  "PARAMETER",
  "TYPE",
  "VARIABLE"
]);

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
final Matcher isLocation = new LazyMatcher(() => new MatchesJsonObject(
  "Location", {
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
 *   "targets": List<Element>
 * }
 */
final Matcher isNavigationRegion = new LazyMatcher(() => new MatchesJsonObject(
  "NavigationRegion", {
    "offset": isInt,
    "length": isInt,
    "targets": isListOf(isElement)
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
  "Occurrences", {
    "element": isElement,
    "offsets": isListOf(isInt),
    "length": isInt
  }));

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
  "Outline", {
    "element": isElement,
    "offset": isInt,
    "length": isInt
  }, optionalFields: {
    "children": isListOf(isOutline)
  }));

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
final Matcher isOverride = new LazyMatcher(() => new MatchesJsonObject(
  "Override", {
    "offset": isInt,
    "length": isInt
  }, optionalFields: {
    "superclassMember": isOverriddenMember,
    "interfaceMembers": isListOf(isOverriddenMember)
  }));

/**
 * OverriddenMember
 *
 * {
 *   "element": Element
 *   "className": String
 * }
 */
final Matcher isOverriddenMember = new LazyMatcher(() => new MatchesJsonObject(
  "OverriddenMember", {
    "element": isElement,
    "className": isString
  }));

/**
 * Position
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isPosition = new LazyMatcher(() => new MatchesJsonObject(
  "Position", {
    "file": isFilePath,
    "offset": isInt
  }));

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
 *   RENAME
 * }
 */
final Matcher isRefactoringKind = new MatchesEnum("RefactoringKind", [
  "CONVERT_GETTER_TO_METHOD",
  "CONVERT_METHOD_TO_GETTER",
  "EXTRACT_LOCAL_VARIABLE",
  "EXTRACT_METHOD",
  "INLINE_LOCAL_VARIABLE",
  "INLINE_METHOD",
  "RENAME"
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
final Matcher isRefactoringMethodParameter = new LazyMatcher(() => new MatchesJsonObject(
  "RefactoringMethodParameter", {
    "kind": isRefactoringMethodParameterKind,
    "type": isString,
    "name": isString
  }, optionalFields: {
    "id": isString,
    "parameters": isString
  }));

/**
 * RefactoringFeedback
 *
 * {
 * }
 */
final Matcher isRefactoringFeedback = new LazyMatcher(() => new MatchesJsonObject(
  "RefactoringFeedback", null));

/**
 * RefactoringOptions
 *
 * {
 * }
 */
final Matcher isRefactoringOptions = new LazyMatcher(() => new MatchesJsonObject(
  "RefactoringOptions", null));

/**
 * RefactoringMethodParameterKind
 *
 * enum {
 *   REQUIRED
 *   POSITIONAL
 *   NAMED
 * }
 */
final Matcher isRefactoringMethodParameterKind = new MatchesEnum("RefactoringMethodParameterKind", [
  "REQUIRED",
  "POSITIONAL",
  "NAMED"
]);

/**
 * RefactoringProblem
 *
 * {
 *   "severity": RefactoringProblemSeverity
 *   "message": String
 *   "location": optional Location
 * }
 */
final Matcher isRefactoringProblem = new LazyMatcher(() => new MatchesJsonObject(
  "RefactoringProblem", {
    "severity": isRefactoringProblemSeverity,
    "message": isString
  }, optionalFields: {
    "location": isLocation
  }));

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
final Matcher isRefactoringProblemSeverity = new MatchesEnum("RefactoringProblemSeverity", [
  "INFO",
  "WARNING",
  "ERROR",
  "FATAL"
]);

/**
 * RemoveContentOverlay
 *
 * {
 *   "type": "remove"
 * }
 */
final Matcher isRemoveContentOverlay = new LazyMatcher(() => new MatchesJsonObject(
  "RemoveContentOverlay", {
    "type": equals("remove")
  }));

/**
 * RequestError
 *
 * {
 *   "code": RequestErrorCode
 *   "message": String
 *   "data": optional object
 * }
 */
final Matcher isRequestError = new LazyMatcher(() => new MatchesJsonObject(
  "RequestError", {
    "code": isRequestErrorCode,
    "message": isString
  }, optionalFields: {
    "data": isObject
  }));

/**
 * RequestErrorCode
 *
 * enum {
 *   GET_ERRORS_INVALID_FILE
 *   INVALID_OVERLAY_CHANGE
 *   INVALID_PARAMETER
 *   INVALID_REQUEST
 *   SERVER_ALREADY_STARTED
 *   UNANALYZED_PRIORITY_FILES
 *   UNKNOWN_REQUEST
 *   UNSUPPORTED_FEATURE
 * }
 */
final Matcher isRequestErrorCode = new MatchesEnum("RequestErrorCode", [
  "GET_ERRORS_INVALID_FILE",
  "INVALID_OVERLAY_CHANGE",
  "INVALID_PARAMETER",
  "INVALID_REQUEST",
  "SERVER_ALREADY_STARTED",
  "UNANALYZED_PRIORITY_FILES",
  "UNKNOWN_REQUEST",
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
final Matcher isSearchResult = new LazyMatcher(() => new MatchesJsonObject(
  "SearchResult", {
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
final Matcher isServerService = new MatchesEnum("ServerService", [
  "STATUS"
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
final Matcher isSourceChange = new LazyMatcher(() => new MatchesJsonObject(
  "SourceChange", {
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
  "SourceEdit", {
    "offset": isInt,
    "length": isInt,
    "replacement": isString
  }, optionalFields: {
    "id": isString
  }));

/**
 * SourceFileEdit
 *
 * {
 *   "file": FilePath
 *   "edits": List<SourceEdit>
 * }
 */
final Matcher isSourceFileEdit = new LazyMatcher(() => new MatchesJsonObject(
  "SourceFileEdit", {
    "file": isFilePath,
    "edits": isListOf(isSourceEdit)
  }));

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
final Matcher isTypeHierarchyItem = new LazyMatcher(() => new MatchesJsonObject(
  "TypeHierarchyItem", {
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
 * extractLocalVariable feedback
 *
 * {
 *   "names": List<String>
 *   "offsets": List<int>
 *   "lengths": List<int>
 * }
 */
final Matcher isExtractLocalVariableFeedback = new LazyMatcher(() => new MatchesJsonObject(
  "extractLocalVariable feedback", {
    "names": isListOf(isString),
    "offsets": isListOf(isInt),
    "lengths": isListOf(isInt)
  }));

/**
 * extractLocalVariable options
 *
 * {
 *   "name": String
 *   "extractAll": bool
 * }
 */
final Matcher isExtractLocalVariableOptions = new LazyMatcher(() => new MatchesJsonObject(
  "extractLocalVariable options", {
    "name": isString,
    "extractAll": isBool
  }));

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
final Matcher isExtractMethodFeedback = new LazyMatcher(() => new MatchesJsonObject(
  "extractMethod feedback", {
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
final Matcher isExtractMethodOptions = new LazyMatcher(() => new MatchesJsonObject(
  "extractMethod options", {
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
final Matcher isInlineLocalVariableFeedback = new LazyMatcher(() => new MatchesJsonObject(
  "inlineLocalVariable feedback", {
    "name": isString,
    "occurrences": isInt
  }));

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
final Matcher isInlineMethodFeedback = new LazyMatcher(() => new MatchesJsonObject(
  "inlineMethod feedback", {
    "methodName": isString,
    "isDeclaration": isBool
  }, optionalFields: {
    "className": isString
  }));

/**
 * inlineMethod options
 *
 * {
 *   "deleteSource": bool
 *   "inlineAll": bool
 * }
 */
final Matcher isInlineMethodOptions = new LazyMatcher(() => new MatchesJsonObject(
  "inlineMethod options", {
    "deleteSource": isBool,
    "inlineAll": isBool
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
final Matcher isRenameFeedback = new LazyMatcher(() => new MatchesJsonObject(
  "rename feedback", {
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
final Matcher isRenameOptions = new LazyMatcher(() => new MatchesJsonObject(
  "rename options", {
    "newName": isString
  }));

