// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.constants;

//
// Server methods
//
const String SERVER_GET_VERSION = 'server.getVersion';
const String SERVER_SHUTDOWN = 'server.shutdown';
const String SERVER_SET_SUBSCRIPTIONS = 'server.setSubscriptions';

//
// Server notifications
//
const String SERVER_CONNECTED = 'server.connected';
const String SERVER_ERROR = 'server.error';
const String SERVER_STATUS = 'server.status';

//
// Analysis methods
//
const String ANALYSIS_GET_ERRORS = 'analysis.getErrors';
const String ANALYSIS_GET_HOVER = 'analysis.getHover';
const String ANALYSIS_SET_ANALYSIS_ROOTS = 'analysis.setAnalysisRoots';
const String ANALYSIS_SET_PRIORITY_FILES = 'analysis.setPriorityFiles';
const String ANALYSIS_SET_SUBSCRIPTIONS = 'analysis.setSubscriptions';
const String ANALYSIS_UPDATE_CONTENT = 'analysis.updateContent';
const String ANALYSIS_UPDATE_OPTIONS = 'analysis.updateOptions';
const String ANALYSIS_UPDATE_SDKS = 'analysis.updateSdks';

//
// Analysis notifications
//
const String ANALYSIS_ERRORS = 'analysis.errors';
const String ANALYSIS_HIGHLIGHTS = 'analysis.highlights';
const String ANALYSIS_NAVIGATION = 'analysis.navigation';
const String ANALYSIS_OCCURRENCES = 'analysis.occurrences';
const String ANALYSIS_OUTLINE = 'analysis.outline';
const String ANALYSIS_OVERRIDES = 'analysis.overrides';

//
// Code Completion methods
//
const String COMPLETION_GET_SUGGESTIONS = 'completion.getSuggestions';

//
// Code Completion notifications
//
const String COMPLETION_RESULTS = 'completion.results';

//
// Search methods
//
const String SEARCH_FIND_ELEMENT_REFERENCES = 'search.findElementReferences';
const String SEARCH_FIND_MEMBER_DECLARATIONS = 'search.findMemberDeclarations';
const String SEARCH_FIND_MEMBER_REFERENCES = 'search.findMemberReferences';
const String SEARCH_FIND_TOP_LEVEL_DECLARATIONS =
    'search.findTopLevelDeclarations';

//
// Search notifications
//
const String SEARCH_RESULTS = 'search.results';

//
// Edit methods
//
const String EDIT_APPLY_REFACTORING = 'edit.applyRefactoring';
const String EDIT_CREATE_REFACTORING = 'edit.createRefactoring';
const String EDIT_DELETE_REFACTORING = 'edit.deleteRefactoring';
const String EDIT_GET_ASSISTS = 'edit.getAssists';
const String EDIT_GET_FIXES = 'edit.getFixes';
const String EDIT_GET_REFACTORINGS = 'edit.getRefactorings';
const String EDIT_SET_REFACTORING_OPTIONS = 'edit.setRefactoringOptions';

//
// Analysis option names
//
const String ANALYZE_ANGULAR = 'analyzeAngular'; // boolean
const String ANALYZE_POLYMER = 'analyzePolymer'; // boolean
const String ENABLE_ASYNC = 'enableAsync'; // boolean
const String ENABLE_DEFERRED_LOADING = 'enableDeferredLoading'; // boolean
const String ENABLE_ENUMS = 'enableEnums'; // boolean
const String GENERATE_DART2JS_HINTS = 'generateDart2jsHints'; // boolean
const String GENERATE_HINTS = 'generateHints'; // boolean
