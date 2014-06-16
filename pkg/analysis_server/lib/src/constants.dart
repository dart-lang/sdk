// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library constants;

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
const String ANALYSIS_OUTLINE = 'analysis.outline';

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
// Property names
//
const String ADDED = 'added';
const String CHILDREN = 'children';
const String CONTENT = 'content';
const String DEFAULT = 'default';
const String ELEMENT_LENGTH = 'elementLength';
const String ELEMENT_OFFSET = 'elementOffset';
const String EXCLUDED = 'excluded';
const String ERRORS = 'errors';
const String FILE = 'file';
const String FILES = 'files';
const String FIXES = 'fixes';
const String ID = 'id';
const String INCLUDED = 'included';
const String IS_ABSTRACT = 'isAbstract';
const String IS_STATIC = 'isStatic';
const String KIND = 'kind';
const String LENGTH = 'length';
const String NAME = 'name';
const String NAME_LENGTH = 'nameLength';
const String NAME_OFFSET = 'nameOffset';
const String NEW_LENGTH = 'newLength';
const String OFFSET = 'offset';
const String OLD_LENGTH = 'oldLength';
const String OPTIONS = 'options';
const String OUTLINE = 'outline';
const String PARAMETERS = 'parameters';
const String PATTERN = 'pattern';
const String REFACTORINGS = 'refactorings';
const String REGIONS = 'regions';
const String REMOVED = 'removed';
const String RETURN_TYPE = 'returnType';
const String SUBSCRIPTIONS = 'subscriptions';
const String VERSION = 'version';
