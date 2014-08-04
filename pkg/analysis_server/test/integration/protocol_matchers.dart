// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
final Matcher isServerGetVersionResult = new MatchesJsonObject(
  "server.getVersion result", {
    "version": isString
  });

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
final Matcher isServerSetSubscriptionsParams = new MatchesJsonObject(
  "server.setSubscriptions params", {
    "subscriptions": isListOf(isServerService)
  });

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
 *   "fatal": bool
 *   "message": String
 *   "stackTrace": String
 * }
 */
final Matcher isServerErrorParams = new MatchesJsonObject(
  "server.error params", {
    "fatal": isBool,
    "message": isString,
    "stackTrace": isString
  });

/**
 * server.status params
 *
 * {
 *   "analysis": optional AnalysisStatus
 * }
 */
final Matcher isServerStatusParams = new MatchesJsonObject(
  "server.status params", null, optionalFields: {
    "analysis": isAnalysisStatus
  });

/**
 * analysis.getErrors params
 *
 * {
 *   "file": FilePath
 * }
 */
final Matcher isAnalysisGetErrorsParams = new MatchesJsonObject(
  "analysis.getErrors params", {
    "file": isFilePath
  });

/**
 * analysis.getErrors result
 *
 * {
 *   "errors": List<AnalysisError>
 * }
 */
final Matcher isAnalysisGetErrorsResult = new MatchesJsonObject(
  "analysis.getErrors result", {
    "errors": isListOf(isAnalysisError)
  });

/**
 * analysis.getHover params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isAnalysisGetHoverParams = new MatchesJsonObject(
  "analysis.getHover params", {
    "file": isFilePath,
    "offset": isInt
  });

/**
 * analysis.getHover result
 *
 * {
 *   "hovers": List<HoverInformation>
 * }
 */
final Matcher isAnalysisGetHoverResult = new MatchesJsonObject(
  "analysis.getHover result", {
    "hovers": isListOf(isHoverInformation)
  });

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
final Matcher isAnalysisSetAnalysisRootsParams = new MatchesJsonObject(
  "analysis.setAnalysisRoots params", {
    "included": isListOf(isFilePath),
    "excluded": isListOf(isFilePath)
  });

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
final Matcher isAnalysisSetPriorityFilesParams = new MatchesJsonObject(
  "analysis.setPriorityFiles params", {
    "files": isListOf(isFilePath)
  });

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
final Matcher isAnalysisSetSubscriptionsParams = new MatchesJsonObject(
  "analysis.setSubscriptions params", {
    "subscriptions": isMapOf(isAnalysisService, isListOf(isFilePath))
  });

/**
 * analysis.setSubscriptions result
 */
final Matcher isAnalysisSetSubscriptionsResult = isNull;

/**
 * analysis.updateContent params
 *
 * {
 *   "files": Map<FilePath, ContentChange>
 * }
 */
final Matcher isAnalysisUpdateContentParams = new MatchesJsonObject(
  "analysis.updateContent params", {
    "files": isMapOf(isFilePath, isContentChange)
  });

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
final Matcher isAnalysisUpdateOptionsParams = new MatchesJsonObject(
  "analysis.updateOptions params", {
    "options": isAnalysisOptions
  });

/**
 * analysis.updateOptions result
 */
final Matcher isAnalysisUpdateOptionsResult = isNull;

/**
 * analysis.updateSdks params
 *
 * {
 *   "added": List<FilePath>
 *   "removed": List<FilePath>
 *   "default": optional FilePath
 * }
 */
final Matcher isAnalysisUpdateSdksParams = new MatchesJsonObject(
  "analysis.updateSdks params", {
    "added": isListOf(isFilePath),
    "removed": isListOf(isFilePath)
  }, optionalFields: {
    "default": isFilePath
  });

/**
 * analysis.updateSdks result
 */
final Matcher isAnalysisUpdateSdksResult = isNull;

/**
 * analysis.errors params
 *
 * {
 *   "file": FilePath
 *   "errors": List<AnalysisError>
 * }
 */
final Matcher isAnalysisErrorsParams = new MatchesJsonObject(
  "analysis.errors params", {
    "file": isFilePath,
    "errors": isListOf(isAnalysisError)
  });

/**
 * analysis.folding params
 *
 * {
 *   "file": FilePath
 *   "regions": List<FoldingRegion>
 * }
 */
final Matcher isAnalysisFoldingParams = new MatchesJsonObject(
  "analysis.folding params", {
    "file": isFilePath,
    "regions": isListOf(isFoldingRegion)
  });

/**
 * analysis.highlights params
 *
 * {
 *   "file": FilePath
 *   "regions": List<HighlightRegion>
 * }
 */
final Matcher isAnalysisHighlightsParams = new MatchesJsonObject(
  "analysis.highlights params", {
    "file": isFilePath,
    "regions": isListOf(isHighlightRegion)
  });

/**
 * analysis.navigation params
 *
 * {
 *   "file": FilePath
 *   "regions": List<NavigationRegion>
 * }
 */
final Matcher isAnalysisNavigationParams = new MatchesJsonObject(
  "analysis.navigation params", {
    "file": isFilePath,
    "regions": isListOf(isNavigationRegion)
  });

/**
 * analysis.occurrences params
 *
 * {
 *   "file": FilePath
 *   "occurrences": List<Occurrences>
 * }
 */
final Matcher isAnalysisOccurrencesParams = new MatchesJsonObject(
  "analysis.occurrences params", {
    "file": isFilePath,
    "occurrences": isListOf(isOccurrences)
  });

/**
 * analysis.outline params
 *
 * {
 *   "file": FilePath
 *   "outline": Outline
 * }
 */
final Matcher isAnalysisOutlineParams = new MatchesJsonObject(
  "analysis.outline params", {
    "file": isFilePath,
    "outline": isOutline
  });

/**
 * analysis.overrides params
 *
 * {
 *   "file": FilePath
 *   "overrides": List<Override>
 * }
 */
final Matcher isAnalysisOverridesParams = new MatchesJsonObject(
  "analysis.overrides params", {
    "file": isFilePath,
    "overrides": isListOf(isOverride)
  });

/**
 * completion.getSuggestions params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isCompletionGetSuggestionsParams = new MatchesJsonObject(
  "completion.getSuggestions params", {
    "file": isFilePath,
    "offset": isInt
  });

/**
 * completion.getSuggestions result
 *
 * {
 *   "id": CompletionId
 * }
 */
final Matcher isCompletionGetSuggestionsResult = new MatchesJsonObject(
  "completion.getSuggestions result", {
    "id": isCompletionId
  });

/**
 * completion.results params
 *
 * {
 *   "id": CompletionId
 *   "replacementOffset": int
 *   "replacementLength": int
 *   "results": List<CompletionSuggestion>
 *   "last": bool
 * }
 */
final Matcher isCompletionResultsParams = new MatchesJsonObject(
  "completion.results params", {
    "id": isCompletionId,
    "replacementOffset": isInt,
    "replacementLength": isInt,
    "results": isListOf(isCompletionSuggestion),
    "last": isBool
  });

/**
 * search.findElementReferences params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "includePotential": bool
 * }
 */
final Matcher isSearchFindElementReferencesParams = new MatchesJsonObject(
  "search.findElementReferences params", {
    "file": isFilePath,
    "offset": isInt,
    "includePotential": isBool
  });

/**
 * search.findElementReferences result
 *
 * {
 *   "id": SearchId
 *   "element": Element
 * }
 */
final Matcher isSearchFindElementReferencesResult = new MatchesJsonObject(
  "search.findElementReferences result", {
    "id": isSearchId,
    "element": isElement
  });

/**
 * search.findMemberDeclarations params
 *
 * {
 *   "name": String
 * }
 */
final Matcher isSearchFindMemberDeclarationsParams = new MatchesJsonObject(
  "search.findMemberDeclarations params", {
    "name": isString
  });

/**
 * search.findMemberDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 */
final Matcher isSearchFindMemberDeclarationsResult = new MatchesJsonObject(
  "search.findMemberDeclarations result", {
    "id": isSearchId
  });

/**
 * search.findMemberReferences params
 *
 * {
 *   "name": String
 * }
 */
final Matcher isSearchFindMemberReferencesParams = new MatchesJsonObject(
  "search.findMemberReferences params", {
    "name": isString
  });

/**
 * search.findMemberReferences result
 *
 * {
 *   "id": SearchId
 * }
 */
final Matcher isSearchFindMemberReferencesResult = new MatchesJsonObject(
  "search.findMemberReferences result", {
    "id": isSearchId
  });

/**
 * search.findTopLevelDeclarations params
 *
 * {
 *   "pattern": String
 * }
 */
final Matcher isSearchFindTopLevelDeclarationsParams = new MatchesJsonObject(
  "search.findTopLevelDeclarations params", {
    "pattern": isString
  });

/**
 * search.findTopLevelDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 */
final Matcher isSearchFindTopLevelDeclarationsResult = new MatchesJsonObject(
  "search.findTopLevelDeclarations result", {
    "id": isSearchId
  });

/**
 * search.getTypeHierarchy params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isSearchGetTypeHierarchyParams = new MatchesJsonObject(
  "search.getTypeHierarchy params", {
    "file": isFilePath,
    "offset": isInt
  });

/**
 * search.getTypeHierarchy result
 *
 * {
 *   "hierarchy": TypeHierarchyItem
 * }
 */
final Matcher isSearchGetTypeHierarchyResult = new MatchesJsonObject(
  "search.getTypeHierarchy result", {
    "hierarchy": isTypeHierarchyItem
  });

/**
 * search.results params
 *
 * {
 *   "id": SearchId
 *   "results": List<SearchResult>
 *   "last": bool
 * }
 */
final Matcher isSearchResultsParams = new MatchesJsonObject(
  "search.results params", {
    "id": isSearchId,
    "results": isListOf(isSearchResult),
    "last": isBool
  });

/**
 * edit.applyRefactoring params
 *
 * {
 *   "id": RefactoringId
 * }
 */
final Matcher isEditApplyRefactoringParams = new MatchesJsonObject(
  "edit.applyRefactoring params", {
    "id": isRefactoringId
  });

/**
 * edit.applyRefactoring result
 *
 * {
 *   "status": List<RefactoringProblem>
 *   "change": SourceChange
 * }
 */
final Matcher isEditApplyRefactoringResult = new MatchesJsonObject(
  "edit.applyRefactoring result", {
    "status": isListOf(isRefactoringProblem),
    "change": isSourceChange
  });

/**
 * edit.createRefactoring params
 *
 * {
 *   "kindId": RefactoringKind
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isEditCreateRefactoringParams = new MatchesJsonObject(
  "edit.createRefactoring params", {
    "kindId": isRefactoringKind,
    "file": isFilePath,
    "offset": isInt,
    "length": isInt
  });

/**
 * edit.createRefactoring result
 *
 * {
 *   "id": RefactoringId
 *   "status": List<RefactoringProblem>
 * }
 */
final Matcher isEditCreateRefactoringResult = new MatchesJsonObject(
  "edit.createRefactoring result", {
    "id": isRefactoringId,
    "status": isListOf(isRefactoringProblem)
  });

/**
 * edit.deleteRefactoring params
 *
 * {
 *   "id": RefactoringId
 * }
 */
final Matcher isEditDeleteRefactoringParams = new MatchesJsonObject(
  "edit.deleteRefactoring params", {
    "id": isRefactoringId
  });

/**
 * edit.deleteRefactoring result
 */
final Matcher isEditDeleteRefactoringResult = isNull;

/**
 * edit.getAssists params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isEditGetAssistsParams = new MatchesJsonObject(
  "edit.getAssists params", {
    "file": isFilePath,
    "offset": isInt,
    "length": isInt
  });

/**
 * edit.getAssists result
 *
 * {
 *   "assists": List<SourceChange>
 * }
 */
final Matcher isEditGetAssistsResult = new MatchesJsonObject(
  "edit.getAssists result", {
    "assists": isListOf(isSourceChange)
  });

/**
 * edit.getFixes params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
final Matcher isEditGetFixesParams = new MatchesJsonObject(
  "edit.getFixes params", {
    "file": isFilePath,
    "offset": isInt
  });

/**
 * edit.getFixes result
 *
 * {
 *   "fixes": List<ErrorFixes>
 * }
 */
final Matcher isEditGetFixesResult = new MatchesJsonObject(
  "edit.getFixes result", {
    "fixes": isListOf(isErrorFixes)
  });

/**
 * edit.getRefactorings params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isEditGetRefactoringsParams = new MatchesJsonObject(
  "edit.getRefactorings params", {
    "file": isFilePath,
    "offset": isInt,
    "length": isInt
  });

/**
 * edit.getRefactorings result
 *
 * {
 *   "kinds": List<RefactoringKind>
 * }
 */
final Matcher isEditGetRefactoringsResult = new MatchesJsonObject(
  "edit.getRefactorings result", {
    "kinds": isListOf(isRefactoringKind)
  });

/**
 * edit.setRefactoringOptions params
 *
 * {
 *   "id": RefactoringId
 * }
 */
final Matcher isEditSetRefactoringOptionsParams = new MatchesJsonObject(
  "edit.setRefactoringOptions params", {
    "id": isRefactoringId
  });

/**
 * edit.setRefactoringOptions result
 *
 * {
 *   "status": List<RefactoringProblem>
 * }
 */
final Matcher isEditSetRefactoringOptionsResult = new MatchesJsonObject(
  "edit.setRefactoringOptions result", {
    "status": isListOf(isRefactoringProblem)
  });

/**
 * debug.createContext params
 *
 * {
 *   "contextRoot": FilePath
 * }
 */
final Matcher isDebugCreateContextParams = new MatchesJsonObject(
  "debug.createContext params", {
    "contextRoot": isFilePath
  });

/**
 * debug.createContext result
 *
 * {
 *   "id": DebugContextId
 * }
 */
final Matcher isDebugCreateContextResult = new MatchesJsonObject(
  "debug.createContext result", {
    "id": isDebugContextId
  });

/**
 * debug.deleteContext params
 *
 * {
 *   "id": DebugContextId
 * }
 */
final Matcher isDebugDeleteContextParams = new MatchesJsonObject(
  "debug.deleteContext params", {
    "id": isDebugContextId
  });

/**
 * debug.deleteContext result
 */
final Matcher isDebugDeleteContextResult = isNull;

/**
 * debug.mapUri params
 *
 * {
 *   "id": DebugContextId
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 */
final Matcher isDebugMapUriParams = new MatchesJsonObject(
  "debug.mapUri params", {
    "id": isDebugContextId
  }, optionalFields: {
    "file": isFilePath,
    "uri": isString
  });

/**
 * debug.mapUri result
 *
 * {
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 */
final Matcher isDebugMapUriResult = new MatchesJsonObject(
  "debug.mapUri result", null, optionalFields: {
    "file": isFilePath,
    "uri": isString
  });

/**
 * debug.setSubscriptions params
 *
 * {
 *   "subscriptions": List<DebugService>
 * }
 */
final Matcher isDebugSetSubscriptionsParams = new MatchesJsonObject(
  "debug.setSubscriptions params", {
    "subscriptions": isListOf(isDebugService)
  });

/**
 * debug.setSubscriptions result
 */
final Matcher isDebugSetSubscriptionsResult = isNull;

/**
 * debug.launchData params
 *
 * {
 *   "executables": List<ExecutableFile>
 *   "dartToHtml": Map<FilePath, List<FilePath>>
 *   "htmlToDart": Map<FilePath, List<FilePath>>
 * }
 */
final Matcher isDebugLaunchDataParams = new MatchesJsonObject(
  "debug.launchData params", {
    "executables": isListOf(isExecutableFile),
    "dartToHtml": isMapOf(isFilePath, isListOf(isFilePath)),
    "htmlToDart": isMapOf(isFilePath, isListOf(isFilePath))
  });

/**
 * AnalysisError
 *
 * {
 *   "severity": ErrorSeverity
 *   "type": ErrorType
 *   "location": Location
 *   "message": String
 *   "correction": optional String
 * }
 */
final Matcher isAnalysisError = new MatchesJsonObject(
  "AnalysisError", {
    "severity": isErrorSeverity,
    "type": isErrorType,
    "location": isLocation,
    "message": isString
  }, optionalFields: {
    "correction": isString
  });

/**
 * AnalysisOptions
 *
 * {
 *   "analyzeAngular": optional bool
 *   "analyzePolymer": optional bool
 *   "enableAsync": optional bool
 *   "enableDeferredLoading": optional bool
 *   "enableEnums": optional bool
 *   "generateDart2jsHints": optional bool
 *   "generateHints": optional bool
 * }
 */
final Matcher isAnalysisOptions = new MatchesJsonObject(
  "AnalysisOptions", null, optionalFields: {
    "analyzeAngular": isBool,
    "analyzePolymer": isBool,
    "enableAsync": isBool,
    "enableDeferredLoading": isBool,
    "enableEnums": isBool,
    "generateDart2jsHints": isBool,
    "generateHints": isBool
  });

/**
 * AnalysisService
 *
 * enum {
 *   ERRORS
 *   FOLDING
 *   HIGHLIGHTS
 *   NAVIGATION
 *   OCCURRENCES
 *   OUTLINE
 *   OVERRIDES
 * }
 */
final Matcher isAnalysisService = isIn([
  "ERRORS",
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
 *   "analyzing": bool
 *   "analysisTarget": optional String
 * }
 */
final Matcher isAnalysisStatus = new MatchesJsonObject(
  "AnalysisStatus", {
    "analyzing": isBool
  }, optionalFields: {
    "analysisTarget": isString
  });

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
final Matcher isCompletionRelevance = isIn([
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
final Matcher isCompletionSuggestion = new MatchesJsonObject(
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
  });

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
 *   LIBRARY_PREFIX
 *   METHOD
 *   METHOD_NAME
 *   NAMED_ARGUMENT
 *   OPTIONAL_ARGUMENT
 *   PARAMETER
 *   SETTER
 *   TOP_LEVEL_VARIABLE
 *   TYPE_PARAMETER
 *   VARIABLE
 * }
 */
final Matcher isCompletionSuggestionKind = isIn([
  "ARGUMENT_LIST",
  "CLASS",
  "CLASS_ALIAS",
  "CONSTRUCTOR",
  "FIELD",
  "FUNCTION",
  "FUNCTION_TYPE_ALIAS",
  "GETTER",
  "IMPORT",
  "LIBRARY_PREFIX",
  "METHOD",
  "METHOD_NAME",
  "NAMED_ARGUMENT",
  "OPTIONAL_ARGUMENT",
  "PARAMETER",
  "SETTER",
  "TOP_LEVEL_VARIABLE",
  "TYPE_PARAMETER",
  "VARIABLE"
]);

/**
 * ContentChange
 *
 * {
 *   "content": String
 *   "offset": optional int
 *   "oldLength": optional int
 *   "newLength": optional int
 * }
 */
final Matcher isContentChange = new MatchesJsonObject(
  "ContentChange", {
    "content": isString
  }, optionalFields: {
    "offset": isInt,
    "oldLength": isInt,
    "newLength": isInt
  });

/**
 * DebugContextId
 *
 * String
 */
final Matcher isDebugContextId = isString;

/**
 * DebugService
 *
 * enum {
 *   LAUNCH_DATA
 * }
 */
final Matcher isDebugService = isIn([
  "LAUNCH_DATA"
]);

/**
 * Element
 *
 * {
 *   "kind": ElementKind
 *   "name": String
 *   "location": Location
 *   "flags": int
 *   "parameters": optional String
 *   "returnType": optional String
 * }
 */
final Matcher isElement = new MatchesJsonObject(
  "Element", {
    "kind": isElementKind,
    "name": isString,
    "location": isLocation,
    "flags": isInt
  }, optionalFields: {
    "parameters": isString,
    "returnType": isString
  });

/**
 * ElementKind
 *
 * enum {
 *   CLASS
 *   CLASS_TYPE_ALIAS
 *   COMPILATION_UNIT
 *   CONSTRUCTOR
 *   GETTER
 *   FIELD
 *   FUNCTION
 *   FUNCTION_TYPE_ALIAS
 *   LIBRARY
 *   LOCAL_VARIABLE
 *   METHOD
 *   SETTER
 *   TOP_LEVEL_VARIABLE
 *   TYPE_PARAMETER
 *   UNKNOWN
 *   UNIT_TEST_GROUP
 *   UNIT_TEST_TEST
 * }
 */
final Matcher isElementKind = isIn([
  "CLASS",
  "CLASS_TYPE_ALIAS",
  "COMPILATION_UNIT",
  "CONSTRUCTOR",
  "GETTER",
  "FIELD",
  "FUNCTION",
  "FUNCTION_TYPE_ALIAS",
  "LIBRARY",
  "LOCAL_VARIABLE",
  "METHOD",
  "SETTER",
  "TOP_LEVEL_VARIABLE",
  "TYPE_PARAMETER",
  "UNKNOWN",
  "UNIT_TEST_GROUP",
  "UNIT_TEST_TEST"
]);

/**
 * Error
 *
 * {
 *   "code": String
 *   "message": String
 *   "data": optional object
 * }
 */
final Matcher isError = new MatchesJsonObject(
  "Error", {
    // TODO(paulberry): the API spec says "code" should be a string, but the
    // server is currently outputting integers.
    "code": isInt,
    "message": isString
  }, optionalFields: {
    "data": isObject
  });

/**
 * ErrorFixes
 *
 * {
 *   "error": AnalysisError
 *   "fixes": List<SourceChange>
 * }
 */
final Matcher isErrorFixes = new MatchesJsonObject(
  "ErrorFixes", {
    "error": isAnalysisError,
    "fixes": isListOf(isSourceChange)
  });

/**
 * ErrorSeverity
 *
 * enum {
 *   INFO
 *   WARNING
 *   ERROR
 * }
 */
final Matcher isErrorSeverity = isIn([
  "INFO",
  "WARNING",
  "ERROR"
]);

/**
 * ErrorType
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
final Matcher isErrorType = isIn([
  "COMPILE_TIME_ERROR",
  "HINT",
  "STATIC_TYPE_WARNING",
  "STATIC_WARNING",
  "SYNTACTIC_ERROR",
  "TODO"
]);

/**
 * ExecutableFile
 *
 * {
 *   "file": FilePath
 *   "offset": ExecutableKind
 * }
 */
final Matcher isExecutableFile = new MatchesJsonObject(
  "ExecutableFile", {
    "file": isFilePath,
    "offset": isExecutableKind
  });

/**
 * ExecutableKind
 *
 * enum {
 *   CLIENT
 *   EITHER
 *   SERVER
 * }
 */
final Matcher isExecutableKind = isIn([
  "CLIENT",
  "EITHER",
  "SERVER"
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
final Matcher isFoldingKind = isIn([
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
final Matcher isFoldingRegion = new MatchesJsonObject(
  "FoldingRegion", {
    "kind": isFoldingKind,
    "offset": isInt,
    "length": isInt
  });

/**
 * HighlightRegion
 *
 * {
 *   "type": HighlightRegionType
 *   "offset": int
 *   "length": int
 * }
 */
final Matcher isHighlightRegion = new MatchesJsonObject(
  "HighlightRegion", {
    "type": isHighlightRegionType,
    "offset": isInt,
    "length": isInt
  });

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
 *   FUNCTION_DECLARATION
 *   FUNCTION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER_DECLARATION
 *   KEYWORD
 *   IDENTIFIER_DEFAULT
 *   IMPORT_PREFIX
 *   LITERAL_BOOLEAN
 *   LITERAL_DOUBLE
 *   LITERAL_INTEGER
 *   LITERAL_LIST
 *   LITERAL_MAP
 *   LITERAL_STRING
 *   LOCAL_VARIABLE_DECLARATION
 *   LOCAL_VARIABLE
 *   METHOD_DECLARATION
 *   METHOD_DECLARATION_STATIC
 *   METHOD
 *   METHOD_STATIC
 *   PARAMETER
 *   SETTER_DECLARATION
 *   TOP_LEVEL_VARIABLE
 *   TYPE_NAME_DYNAMIC
 *   TYPE_PARAMETER
 * }
 */
final Matcher isHighlightRegionType = isIn([
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
  "FUNCTION_DECLARATION",
  "FUNCTION",
  "FUNCTION_TYPE_ALIAS",
  "GETTER_DECLARATION",
  "KEYWORD",
  "IDENTIFIER_DEFAULT",
  "IMPORT_PREFIX",
  "LITERAL_BOOLEAN",
  "LITERAL_DOUBLE",
  "LITERAL_INTEGER",
  "LITERAL_LIST",
  "LITERAL_MAP",
  "LITERAL_STRING",
  "LOCAL_VARIABLE_DECLARATION",
  "LOCAL_VARIABLE",
  "METHOD_DECLARATION",
  "METHOD_DECLARATION_STATIC",
  "METHOD",
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
final Matcher isHoverInformation = new MatchesJsonObject(
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
  });

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
final Matcher isLocation = new MatchesJsonObject(
  "Location", {
    "file": isFilePath,
    "offset": isInt,
    "length": isInt,
    "startLine": isInt,
    "startColumn": isInt
  });

/**
 * NavigationRegion
 *
 * {
 *   "offset": int
 *   "length": int
 *   "targets": List<Element>
 * }
 */
final Matcher isNavigationRegion = new MatchesJsonObject(
  "NavigationRegion", {
    "offset": isInt,
    "length": isInt,
    "targets": isListOf(isElement)
  });

/**
 * Occurrences
 *
 * {
 *   "element": Element
 *   "offsets": List<int>
 *   "length": int
 * }
 */
final Matcher isOccurrences = new MatchesJsonObject(
  "Occurrences", {
    "element": isElement,
    "offsets": isListOf(isInt),
    "length": isInt
  });

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
final Matcher isOutline = new MatchesJsonObject(
  "Outline", {
    "element": isElement,
    "offset": isInt,
    "length": isInt
  }, optionalFields: {
    "children": isListOf(isOutline)
  });

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
final Matcher isOverride = new MatchesJsonObject(
  "Override", {
    "offset": isInt,
    "length": isInt
  }, optionalFields: {
    "superclassMember": isOverriddenMember,
    "interfaceMembers": isListOf(isOverriddenMember)
  });

/**
 * OverriddenMember
 *
 * {
 *   "element": Element
 *   "className": String
 * }
 */
final Matcher isOverriddenMember = new MatchesJsonObject(
  "OverriddenMember", {
    "element": isElement,
    "className": isString
  });

/**
 * Parameter
 *
 * {
 *   "type": String
 *   "name": String
 * }
 */
final Matcher isParameter = new MatchesJsonObject(
  "Parameter", {
    "type": isString,
    "name": isString
  });

/**
 * RefactoringId
 *
 * String
 */
final Matcher isRefactoringId = isString;

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
final Matcher isRefactoringKind = isIn([
  "CONVERT_GETTER_TO_METHOD",
  "CONVERT_METHOD_TO_GETTER",
  "EXTRACT_LOCAL_VARIABLE",
  "EXTRACT_METHOD",
  "INLINE_LOCAL_VARIABLE",
  "INLINE_METHOD",
  "RENAME"
]);

/**
 * RefactoringProblem
 *
 * {
 *   "severity": RefactoringProblemSeverity
 *   "message": String
 *   "location": Location
 * }
 */
final Matcher isRefactoringProblem = new MatchesJsonObject(
  "RefactoringProblem", {
    "severity": isRefactoringProblemSeverity,
    "message": isString,
    "location": isLocation
  });

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
final Matcher isRefactoringProblemSeverity = isIn([
  "INFO",
  "WARNING",
  "ERROR",
  "FATAL"
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
final Matcher isSearchResult = new MatchesJsonObject(
  "SearchResult", {
    "location": isLocation,
    "kind": isSearchResultKind,
    "isPotential": isBool,
    "path": isListOf(isElement)
  });

/**
 * SearchResultKind
 *
 * enum {
 *   DECLARATION
 *   INVOCATION
 *   READ
 *   READ_WRITE
 *   REFERENCE
 *   WRITE
 * }
 */
final Matcher isSearchResultKind = isIn([
  "DECLARATION",
  "INVOCATION",
  "READ",
  "READ_WRITE",
  "REFERENCE",
  "WRITE"
]);

/**
 * ServerService
 *
 * enum {
 *   STATUS
 * }
 */
final Matcher isServerService = isIn([
  "STATUS"
]);

/**
 * SourceChange
 *
 * {
 *   "message": String
 *   "edits": List<SourceFileEdit>
 * }
 */
final Matcher isSourceChange = new MatchesJsonObject(
  "SourceChange", {
    "message": isString,
    "edits": isListOf(isSourceFileEdit)
  });

/**
 * SourceEdit
 *
 * {
 *   "offset": int
 *   "length": int
 *   "replacement": String
 * }
 */
final Matcher isSourceEdit = new MatchesJsonObject(
  "SourceEdit", {
    "offset": isInt,
    "length": isInt,
    "replacement": isString
  });

/**
 * SourceFileEdit
 *
 * {
 *   "file": FilePath
 *   "edits": List<SourceEdit>
 * }
 */
final Matcher isSourceFileEdit = new MatchesJsonObject(
  "SourceFileEdit", {
    "file": isFilePath,
    "edits": isListOf(isSourceEdit)
  });

/**
 * TypeHierarchyItem
 *
 * {
 *   "classElement": Element
 *   "displayName": optional String
 *   "memberElement": optional Element
 *   "superclass": optional TypeHierarchyItem
 *   "interfaces": List<TypeHierarchyItem>
 *   "mixins": List<TypeHierarchyItem>
 *   "subclasses": List<TypeHierarchyItem>
 * }
 */
final Matcher isTypeHierarchyItem = new MatchesJsonObject(
  "TypeHierarchyItem", {
    "classElement": isElement,
    "interfaces": isListOf(isTypeHierarchyItem),
    "mixins": isListOf(isTypeHierarchyItem),
    "subclasses": isListOf(isTypeHierarchyItem)
  }, optionalFields: {
    "displayName": isString,
    "memberElement": isElement,
    "superclass": isTypeHierarchyItem
  });

