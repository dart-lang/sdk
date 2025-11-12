// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

const String PROTOCOL_VERSION = '1.40.0';

const String analysisNotificationAnalyzedFiles = 'analysis.analyzedFiles';
const String analysisNotificationAnalyzedFilesDirectories = 'directories';
const String analysisNotificationClosingLabels = 'analysis.closingLabels';
const String analysisNotificationClosingLabelsFile = 'file';
const String analysisNotificationClosingLabelsLabels = 'labels';
const String analysisNotificationErrors = 'analysis.errors';
const String analysisNotificationErrorsErrors = 'errors';
const String analysisNotificationErrorsFile = 'file';
const String analysisNotificationFlushResults = 'analysis.flushResults';
const String analysisNotificationFlushResultsFiles = 'files';
const String analysisNotificationFolding = 'analysis.folding';
const String analysisNotificationFoldingFile = 'file';
const String analysisNotificationFoldingRegions = 'regions';
const String analysisNotificationHighlights = 'analysis.highlights';
const String analysisNotificationHighlightsFile = 'file';
const String analysisNotificationHighlightsRegions = 'regions';
const String analysisNotificationImplemented = 'analysis.implemented';
const String analysisNotificationImplementedClasses = 'classes';
const String analysisNotificationImplementedFile = 'file';
const String analysisNotificationImplementedMembers = 'members';
const String analysisNotificationInvalidate = 'analysis.invalidate';
const String analysisNotificationInvalidateDelta = 'delta';
const String analysisNotificationInvalidateFile = 'file';
const String analysisNotificationInvalidateLength = 'length';
const String analysisNotificationInvalidateOffset = 'offset';
const String analysisNotificationNavigation = 'analysis.navigation';
const String analysisNotificationNavigationFile = 'file';
const String analysisNotificationNavigationFiles = 'files';
const String analysisNotificationNavigationRegions = 'regions';
const String analysisNotificationNavigationTargets = 'targets';
const String analysisNotificationOccurrences = 'analysis.occurrences';
const String analysisNotificationOccurrencesFile = 'file';
const String analysisNotificationOccurrencesOccurrences = 'occurrences';
const String analysisNotificationOutline = 'analysis.outline';
const String analysisNotificationOutlineFile = 'file';
const String analysisNotificationOutlineKind = 'kind';
const String analysisNotificationOutlineLibraryName = 'libraryName';
const String analysisNotificationOutlineOutline = 'outline';
const String analysisNotificationOverrides = 'analysis.overrides';
const String analysisNotificationOverridesFile = 'file';
const String analysisNotificationOverridesOverrides = 'overrides';
const String analysisRequestGetErrors = 'analysis.getErrors';
const String analysisRequestGetErrorsFile = 'file';
const String analysisRequestGetHover = 'analysis.getHover';
const String analysisRequestGetHoverFile = 'file';
const String analysisRequestGetHoverOffset = 'offset';
const String analysisRequestGetImportedElements =
    'analysis.getImportedElements';
const String analysisRequestGetImportedElementsFile = 'file';
const String analysisRequestGetImportedElementsLength = 'length';
const String analysisRequestGetImportedElementsOffset = 'offset';
const String analysisRequestGetLibraryDependencies =
    'analysis.getLibraryDependencies';
const String analysisRequestGetNavigation = 'analysis.getNavigation';
const String analysisRequestGetNavigationFile = 'file';
const String analysisRequestGetNavigationLength = 'length';
const String analysisRequestGetNavigationOffset = 'offset';
const String analysisRequestGetReachableSources =
    'analysis.getReachableSources';
const String analysisRequestGetReachableSourcesFile = 'file';
const String analysisRequestGetSignature = 'analysis.getSignature';
const String analysisRequestGetSignatureFile = 'file';
const String analysisRequestGetSignatureOffset = 'offset';
const String analysisRequestReanalyze = 'analysis.reanalyze';
const String analysisRequestSetAnalysisRoots = 'analysis.setAnalysisRoots';
const String analysisRequestSetAnalysisRootsExcluded = 'excluded';
const String analysisRequestSetAnalysisRootsIncluded = 'included';
const String analysisRequestSetAnalysisRootsPackageRoots = 'packageRoots';
const String analysisRequestSetGeneralSubscriptions =
    'analysis.setGeneralSubscriptions';
const String analysisRequestSetGeneralSubscriptionsSubscriptions =
    'subscriptions';
const String analysisRequestSetPriorityFiles = 'analysis.setPriorityFiles';
const String analysisRequestSetPriorityFilesFiles = 'files';
const String analysisRequestSetSubscriptions = 'analysis.setSubscriptions';
const String analysisRequestSetSubscriptionsSubscriptions = 'subscriptions';
const String analysisRequestUpdateContent = 'analysis.updateContent';
const String analysisRequestUpdateContentFiles = 'files';
const String analysisRequestUpdateOptions = 'analysis.updateOptions';
const String analysisRequestUpdateOptionsOptions = 'options';
const String analysisResponseGetErrorsErrors = 'errors';
const String analysisResponseGetHoverHovers = 'hovers';
const String analysisResponseGetImportedElementsElements = 'elements';
const String analysisResponseGetLibraryDependenciesLibraries = 'libraries';
const String analysisResponseGetLibraryDependenciesPackageMap = 'packageMap';
const String analysisResponseGetNavigationFiles = 'files';
const String analysisResponseGetNavigationRegions = 'regions';
const String analysisResponseGetNavigationTargets = 'targets';
const String analysisResponseGetReachableSourcesSources = 'sources';
const String analysisResponseGetSignatureDartdoc = 'dartdoc';
const String analysisResponseGetSignatureName = 'name';
const String analysisResponseGetSignatureParameters = 'parameters';
const String analyticsRequestEnable = 'analytics.enable';
const String analyticsRequestEnableValue = 'value';
const String analyticsRequestIsEnabled = 'analytics.isEnabled';
const String analyticsRequestSendEvent = 'analytics.sendEvent';
const String analyticsRequestSendEventAction = 'action';
const String analyticsRequestSendTiming = 'analytics.sendTiming';
const String analyticsRequestSendTimingEvent = 'event';
const String analyticsRequestSendTimingMillis = 'millis';
const String analyticsResponseIsEnabledEnabled = 'enabled';
const String completionNotificationExistingImports =
    'completion.existingImports';
const String completionNotificationExistingImportsFile = 'file';
const String completionNotificationExistingImportsImports = 'imports';
const String completionRequestGetSuggestionDetails2 =
    'completion.getSuggestionDetails2';
const String completionRequestGetSuggestionDetails2Completion = 'completion';
const String completionRequestGetSuggestionDetails2File = 'file';
const String completionRequestGetSuggestionDetails2LibraryUri = 'libraryUri';
const String completionRequestGetSuggestionDetails2Offset = 'offset';
const String completionRequestGetSuggestions2 = 'completion.getSuggestions2';
const String completionRequestGetSuggestions2CompletionCaseMatchingMode =
    'completionCaseMatchingMode';
const String completionRequestGetSuggestions2CompletionMode = 'completionMode';
const String completionRequestGetSuggestions2File = 'file';
const String completionRequestGetSuggestions2InvocationCount =
    'invocationCount';
const String completionRequestGetSuggestions2MaxResults = 'maxResults';
const String completionRequestGetSuggestions2Offset = 'offset';
const String completionRequestGetSuggestions2Timeout = 'timeout';
const String completionRequestRegisterLibraryPaths =
    'completion.registerLibraryPaths';
const String completionRequestRegisterLibraryPathsPaths = 'paths';
const String completionResponseGetSuggestionDetails2Change = 'change';
const String completionResponseGetSuggestionDetails2Completion = 'completion';
const String completionResponseGetSuggestions2IsIncomplete = 'isIncomplete';
const String completionResponseGetSuggestions2ReplacementLength =
    'replacementLength';
const String completionResponseGetSuggestions2ReplacementOffset =
    'replacementOffset';
const String completionResponseGetSuggestions2Suggestions = 'suggestions';
const String diagnosticRequestGetDiagnostics = 'diagnostic.getDiagnostics';
const String diagnosticRequestGetServerPort = 'diagnostic.getServerPort';
const String diagnosticResponseGetDiagnosticsContexts = 'contexts';
const String diagnosticResponseGetServerPortPort = 'port';
const String editRequestBulkFixes = 'edit.bulkFixes';
const String editRequestBulkFixesCodes = 'codes';
const String editRequestBulkFixesInTestMode = 'inTestMode';
const String editRequestBulkFixesIncluded = 'included';
const String editRequestBulkFixesUpdatePubspec = 'updatePubspec';
const String editRequestFormat = 'edit.format';
const String editRequestFormatFile = 'file';
const String editRequestFormatIfEnabled = 'edit.formatIfEnabled';
const String editRequestFormatIfEnabledDirectories = 'directories';
const String editRequestFormatLineLength = 'lineLength';
const String editRequestFormatSelectionLength = 'selectionLength';
const String editRequestFormatSelectionOffset = 'selectionOffset';
const String editRequestGetAssists = 'edit.getAssists';
const String editRequestGetAssistsFile = 'file';
const String editRequestGetAssistsLength = 'length';
const String editRequestGetAssistsOffset = 'offset';
const String editRequestGetAvailableRefactorings =
    'edit.getAvailableRefactorings';
const String editRequestGetAvailableRefactoringsFile = 'file';
const String editRequestGetAvailableRefactoringsLength = 'length';
const String editRequestGetAvailableRefactoringsOffset = 'offset';
const String editRequestGetFixes = 'edit.getFixes';
const String editRequestGetFixesFile = 'file';
const String editRequestGetFixesOffset = 'offset';
const String editRequestGetPostfixCompletion = 'edit.getPostfixCompletion';
const String editRequestGetPostfixCompletionFile = 'file';
const String editRequestGetPostfixCompletionKey = 'key';
const String editRequestGetPostfixCompletionOffset = 'offset';
const String editRequestGetRefactoring = 'edit.getRefactoring';
const String editRequestGetRefactoringFile = 'file';
const String editRequestGetRefactoringKind = 'kind';
const String editRequestGetRefactoringLength = 'length';
const String editRequestGetRefactoringOffset = 'offset';
const String editRequestGetRefactoringOptions = 'options';
const String editRequestGetRefactoringValidateOnly = 'validateOnly';
const String editRequestGetStatementCompletion = 'edit.getStatementCompletion';
const String editRequestGetStatementCompletionFile = 'file';
const String editRequestGetStatementCompletionOffset = 'offset';
const String editRequestImportElements = 'edit.importElements';
const String editRequestImportElementsElements = 'elements';
const String editRequestImportElementsFile = 'file';
const String editRequestImportElementsOffset = 'offset';
const String editRequestIsPostfixCompletionApplicable =
    'edit.isPostfixCompletionApplicable';
const String editRequestIsPostfixCompletionApplicableFile = 'file';
const String editRequestIsPostfixCompletionApplicableKey = 'key';
const String editRequestIsPostfixCompletionApplicableOffset = 'offset';
const String editRequestListPostfixCompletionTemplates =
    'edit.listPostfixCompletionTemplates';
const String editRequestOrganizeDirectives = 'edit.organizeDirectives';
const String editRequestOrganizeDirectivesFile = 'file';
const String editRequestSortMembers = 'edit.sortMembers';
const String editRequestSortMembersFile = 'file';
const String editResponseBulkFixesDetails = 'details';
const String editResponseBulkFixesEdits = 'edits';
const String editResponseBulkFixesMessage = 'message';
const String editResponseFormatEdits = 'edits';
const String editResponseFormatIfEnabledEdits = 'edits';
const String editResponseFormatSelectionLength = 'selectionLength';
const String editResponseFormatSelectionOffset = 'selectionOffset';
const String editResponseGetAssistsAssists = 'assists';
const String editResponseGetAvailableRefactoringsKinds = 'kinds';
const String editResponseGetFixesFixes = 'fixes';
const String editResponseGetPostfixCompletionChange = 'change';
const String editResponseGetRefactoringChange = 'change';
const String editResponseGetRefactoringFeedback = 'feedback';
const String editResponseGetRefactoringFinalProblems = 'finalProblems';
const String editResponseGetRefactoringInitialProblems = 'initialProblems';
const String editResponseGetRefactoringOptionsProblems = 'optionsProblems';
const String editResponseGetRefactoringPotentialEdits = 'potentialEdits';
const String editResponseGetStatementCompletionChange = 'change';
const String editResponseGetStatementCompletionWhitespaceOnly =
    'whitespaceOnly';
const String editResponseImportElementsEdit = 'edit';
const String editResponseIsPostfixCompletionApplicableValue = 'value';
const String editResponseListPostfixCompletionTemplatesTemplates = 'templates';
const String editResponseOrganizeDirectivesEdit = 'edit';
const String editResponseSortMembersEdit = 'edit';
const String executionNotificationLaunchData = 'execution.launchData';
const String executionNotificationLaunchDataFile = 'file';
const String executionNotificationLaunchDataKind = 'kind';
const String executionNotificationLaunchDataReferencedFiles = 'referencedFiles';
const String executionRequestCreateContext = 'execution.createContext';
const String executionRequestCreateContextContextRoot = 'contextRoot';
const String executionRequestDeleteContext = 'execution.deleteContext';
const String executionRequestDeleteContextId = 'id';
const String executionRequestGetSuggestions = 'execution.getSuggestions';
const String executionRequestGetSuggestionsCode = 'code';
const String executionRequestGetSuggestionsContextFile = 'contextFile';
const String executionRequestGetSuggestionsContextOffset = 'contextOffset';
const String executionRequestGetSuggestionsExpressions = 'expressions';
const String executionRequestGetSuggestionsOffset = 'offset';
const String executionRequestGetSuggestionsVariables = 'variables';
const String executionRequestMapUri = 'execution.mapUri';
const String executionRequestMapUriFile = 'file';
const String executionRequestMapUriId = 'id';
const String executionRequestMapUriUri = 'uri';
const String executionRequestSetSubscriptions = 'execution.setSubscriptions';
const String executionRequestSetSubscriptionsSubscriptions = 'subscriptions';
const String executionResponseCreateContextId = 'id';
const String executionResponseGetSuggestionsExpressions = 'expressions';
const String executionResponseGetSuggestionsSuggestions = 'suggestions';
const String executionResponseMapUriFile = 'file';
const String executionResponseMapUriUri = 'uri';
const String flutterNotificationOutline = 'flutter.outline';
const String flutterNotificationOutlineFile = 'file';
const String flutterNotificationOutlineOutline = 'outline';
const String flutterRequestGetWidgetDescription =
    'flutter.getWidgetDescription';
const String flutterRequestGetWidgetDescriptionFile = 'file';
const String flutterRequestGetWidgetDescriptionOffset = 'offset';
const String flutterRequestSetSubscriptions = 'flutter.setSubscriptions';
const String flutterRequestSetSubscriptionsSubscriptions = 'subscriptions';
const String flutterRequestSetWidgetPropertyValue =
    'flutter.setWidgetPropertyValue';
const String flutterRequestSetWidgetPropertyValueId = 'id';
const String flutterRequestSetWidgetPropertyValueValue = 'value';
const String flutterResponseGetWidgetDescriptionProperties = 'properties';
const String flutterResponseSetWidgetPropertyValueChange = 'change';
const String lspNotificationNotification = 'lsp.notification';
const String lspNotificationNotificationLspNotification = 'lspNotification';
const String lspRequestHandle = 'lsp.handle';
const String lspRequestHandleLspMessage = 'lspMessage';
const String lspResponseHandleLspResponse = 'lspResponse';
const String searchNotificationResults = 'search.results';
const String searchNotificationResultsId = 'id';
const String searchNotificationResultsIsLast = 'isLast';
const String searchNotificationResultsResults = 'results';
const String searchRequestFindElementReferences =
    'search.findElementReferences';
const String searchRequestFindElementReferencesFile = 'file';
const String searchRequestFindElementReferencesIncludePotential =
    'includePotential';
const String searchRequestFindElementReferencesOffset = 'offset';
const String searchRequestFindMemberDeclarations =
    'search.findMemberDeclarations';
const String searchRequestFindMemberDeclarationsName = 'name';
const String searchRequestFindMemberReferences = 'search.findMemberReferences';
const String searchRequestFindMemberReferencesName = 'name';
const String searchRequestFindTopLevelDeclarations =
    'search.findTopLevelDeclarations';
const String searchRequestFindTopLevelDeclarationsPattern = 'pattern';
const String searchRequestGetElementDeclarations =
    'search.getElementDeclarations';
const String searchRequestGetElementDeclarationsFile = 'file';
const String searchRequestGetElementDeclarationsMaxResults = 'maxResults';
const String searchRequestGetElementDeclarationsPattern = 'pattern';
const String searchRequestGetTypeHierarchy = 'search.getTypeHierarchy';
const String searchRequestGetTypeHierarchyFile = 'file';
const String searchRequestGetTypeHierarchyOffset = 'offset';
const String searchRequestGetTypeHierarchySuperOnly = 'superOnly';
const String searchResponseFindElementReferencesElement = 'element';
const String searchResponseFindElementReferencesId = 'id';
const String searchResponseFindMemberDeclarationsId = 'id';
const String searchResponseFindMemberReferencesId = 'id';
const String searchResponseFindTopLevelDeclarationsId = 'id';
const String searchResponseGetElementDeclarationsDeclarations = 'declarations';
const String searchResponseGetElementDeclarationsFiles = 'files';
const String searchResponseGetTypeHierarchyHierarchyItems = 'hierarchyItems';
const String serverNotificationConnected = 'server.connected';
const String serverNotificationConnectedPid = 'pid';
const String serverNotificationConnectedVersion = 'version';
const String serverNotificationError = 'server.error';
const String serverNotificationErrorIsFatal = 'isFatal';
const String serverNotificationErrorMessage = 'message';
const String serverNotificationErrorStackTrace = 'stackTrace';
const String serverNotificationLog = 'server.log';
const String serverNotificationLogEntry = 'entry';
const String serverNotificationPluginError = 'server.pluginError';
const String serverNotificationPluginErrorMessage = 'message';
const String serverNotificationStatus = 'server.status';
const String serverNotificationStatusAnalysis = 'analysis';
const String serverNotificationStatusPub = 'pub';
const String serverRequestCancelRequest = 'server.cancelRequest';
const String serverRequestCancelRequestId = 'id';
const String serverRequestGetVersion = 'server.getVersion';
const String serverRequestOpenUrlRequest = 'server.openUrlRequest';
const String serverRequestOpenUrlRequestUrl = 'url';
const String serverRequestSetClientCapabilities =
    'server.setClientCapabilities';
const String serverRequestSetClientCapabilitiesLspCapabilities =
    'lspCapabilities';
const String serverRequestSetClientCapabilitiesRequests = 'requests';
const String serverRequestSetClientCapabilitiesSupportsUris = 'supportsUris';
const String serverRequestSetSubscriptions = 'server.setSubscriptions';
const String serverRequestSetSubscriptionsSubscriptions = 'subscriptions';
const String serverRequestShowMessageRequest = 'server.showMessageRequest';
const String serverRequestShowMessageRequestActions = 'actions';
const String serverRequestShowMessageRequestMessage = 'message';
const String serverRequestShowMessageRequestType = 'type';
const String serverRequestShutdown = 'server.shutdown';
const String serverResponseGetVersionVersion = 'version';
const String serverResponseShowMessageRequestAction = 'action';
