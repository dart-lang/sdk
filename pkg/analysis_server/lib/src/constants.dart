// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//
// Server methods
//
const String ADD = 'add';
const String ADDED = 'added';
const String ANALYSIS_ANALYZED_FILES = 'analysis.analyzedFiles';

//
// Server notifications
//
const String ANALYSIS_ERRORS = 'analysis.errors';
const String ANALYSIS_GET_ERRORS = 'analysis.getErrors';
const String ANALYSIS_GET_HOVER = 'analysis.getHover';

//
// Analysis methods
//
const String ANALYSIS_GET_LIBRARY_DEPENDENCIES =
    'analysis.getLibraryDependencies';
const String ANALYSIS_GET_NAVIGATION = 'analysis.getNavigation';
const String ANALYSIS_GET_REACHABLE_SOURCES = 'analysis.getReachableSources';
const String ANALYSIS_HIGHLIGHTS = 'analysis.highlights';
const String ANALYSIS_IMPLEMENTED = 'analysis.implemented';
const String ANALYSIS_NAVIGATION = 'analysis.navigation';
const String ANALYSIS_OCCURRENCES = 'analysis.occurrences';
const String ANALYSIS_OUTLINE = 'analysis.outline';
const String ANALYSIS_OVERRIDES = 'analysis.overrides';
const String ANALYSIS_REANALYZE = 'analysis.reanalyze';
const String ANALYSIS_SET_ANALYSIS_ROOTS = 'analysis.setAnalysisRoots';
const String ANALYSIS_SET_GENERAL_SUBSCRIPTIONS =
    'analysis.setGeneralSubscriptions';

//
// Analysis notifications
//
const String ANALYSIS_SET_PRIORITY_FILES = 'analysis.setPriorityFiles';
const String ANALYSIS_SET_SUBSCRIPTIONS = 'analysis.setSubscriptions';
const String ANALYSIS_UPDATE_CONTENT = 'analysis.updateContent';
const String ANALYSIS_UPDATE_OPTIONS = 'analysis.updateOptions';
const String ASSISTS = 'assists';
const String CHANGE = 'change';
const String CHILDREN = 'children';
const String CLASS_ELEMENT = 'classElement';

//
// Code Completion methods
//
const String CLASS_NAME = 'className';

//
// Code Completion notifications
//
const String CODE = 'code';

//
// Search methods
//
const String COMPLETION = 'completion';
const String COMPLETION_GET_SUGGESTIONS = 'completion.getSuggestions';
const String COMPLETION_RESULTS = 'completion.results';
const String CONTAINING_LIBRARY_NAME = 'containingLibraryName';
const String CONTAINING_LIBRARY_PATH = 'containingLibraryPath';

//
// Search notifications
//
const String CONTENT = 'content';

//
// Edit methods
//
const String CORRECTION = 'correction';
const String DART_DOC = 'dartdoc';
const String DEFAULT = 'default';
const String DISPLAY_NAME = 'displayName';
const String EDIT_FORMAT = 'edit.format';
const String EDIT_GET_ASSISTS = 'edit.getAssists';
const String EDIT_SORT_MEMBERS = 'edit.sortMembers';
const String EDITS = 'edits';

//
// Diagnostic methods
//
const String DIAGNOSTIC_GET_DIAGNOSTICS = 'diagnostic.getDiagnostics';
const String DIAGNOSTIC_GET_SERVER_PORT = 'diagnostic.getServerPort';

//
// Analytics methods
//
const String ANALYTICS_IS_ENABLED = 'analytics.isEnabled';
const String ANALYTICS_ENABLE = 'analytics.enable';
const String ANALYTICS_SEND_EVENT = 'analytics.sendEvent';
const String ANALYTICS_SEND_TIMING = 'analytics.sendTiming';

//
// Execution methods
//
const String EDIT_GET_AVAILABLE_REFACTORINGS = 'edit.getAvailableRefactorings';
const String EDIT_GET_FIXES = 'edit.getFixes';
const String EDIT_GET_REFACTORING = 'edit.getRefactoring';
const String EDIT_GET_STATEMENT_COMPLETION = "edit.getStatementCompletion";

//
// Execution notifications
//
const String EDIT_ORGANIZE_DIRECTIVES = 'edit.organizeDirectives';

//
// Analysis option names
//
const String ELEMENT = 'element'; // boolean
const String ELEMENT_DESCRIPTION = 'elementDescription'; // boolean
const String ELEMENT_KIND = 'elementKind'; // boolean
const String ENABLE_ASYNC = 'enableAsync'; // boolean
const String ENABLE_DEFERRED_LOADING = 'enableDeferredLoading'; // boolean

//
// Property names
//
const String ENABLE_ENUMS = 'enableEnums';
const String ERROR = 'error';
const String ERRORS = 'errors';
const String EXCLUDED = 'excluded';
const String EXECUTION_CREATE_CONTEXT = 'execution.createContext';
const String EXECUTION_DELETE_CONTEXT = 'execution.deleteContext';
const String EXECUTION_LAUNCH_DATA = 'execution.launchData';
const String EXECUTION_MAP_URI = 'execution.mapUri';
const String EXECUTION_SET_SUBSCRIPTIONS = 'execution.setSubscriptions';
const String FATAL = 'fatal';
const String FILE = 'file';
const String FILE_STAMP = 'fileStamp';
const String FILES = 'files';
const String FIXES = 'fixes';
const String FLAGS = 'flags';
const String GENERATE_DART2JS_HINTS = 'generateDart2jsHints';
const String GENERATE_HINTS = 'generateHints';
const String HAS_FIX = 'hasFix';
const String HIERARCHY_ITEMS = 'hierarchyItems';
const String HOVERS = 'hovers';
const String ID = 'id';
const String INCLUDE_POTENTIAL = 'includePotential';
const String INCLUDED = 'included';
const String INTERFACE_MEMBERS = 'interfaceMembers';
const String INTERFACES = 'interfaces';
const String IS_ABSTRACT = 'isAbstract';
const String IS_DEPRECATED = 'isDeprecated';
const String IS_POTENTIAL = 'isPotential';
const String IS_STATIC = 'isStatic';
const String KIND = 'kind';
const String KINDS = 'kinds';
const String LAST = 'last';
const String LENGTH = 'length';
const String LINKED_EDIT_GROUPS = 'linkedEditGroups';
const String LOCATION = 'location';
const String MEMBER_ELEMENT = 'memberElement';
const String MESSAGE = 'message';
const String MIXINS = 'mixins';
const String NAME = 'name';
const String OCCURRENCES = 'occurrences';
const String OFFSET = 'offset';
const String OFFSETS = 'offsets';
const String OPTIONS = 'options';
const String OUTLINE = 'outline';
const String OVERRIDES = 'overrides';
const String PARAMETER = 'parameter';
const String PARAMETERS = 'parameters';
const String PATH = 'path';
const String PATTERN = 'pattern';
const String POSITIONS = 'positions';
const String PROPAGATED_TYPE = 'propagatedType';
const String REFACTORINGS = 'refactorings';
const String REGIONS = 'regions';
const String RELEVANCE = 'relevance';
const String REMOVE = 'remove';
const String REMOVED = 'removed';
const String REPLACEMENT = 'replacement';
const String REPLACEMENT_LENGTH = 'replacementLength';
const String REPLACEMENT_OFFSET = 'replacementOffset';
const String RESULTS = 'results';
const String RETURN_TYPE = 'returnType';
const String SEARCH_FIND_ELEMENT_REFERENCES = 'search.findElementReferences';
const String SEARCH_FIND_MEMBER_DECLARATIONS = 'search.findMemberDeclarations';
const String SEARCH_FIND_MEMBER_REFERENCES = 'search.findMemberReferences';
const String SEARCH_FIND_TOP_LEVEL_DECLARATIONS =
    'search.findTopLevelDeclarations';
const String SEARCH_GET_TYPE_HIERARCHY = 'search.getTypeHierarchy';
const String SEARCH_RESULTS = 'search.results';
const String SELECTION = 'selection';
const String SELECTION_LENGTH = 'selectionLength';
const String SELECTION_OFFSET = 'selectionOffset';
const String SERVER_CONNECTED = 'server.connected';
const String SERVER_ERROR = 'server.error';
const String SERVER_GET_VERSION = 'server.getVersion';
const String SERVER_SET_SUBSCRIPTIONS = 'server.setSubscriptions';
const String SERVER_SHUTDOWN = 'server.shutdown';
const String SERVER_STATUS = 'server.status';
const String SEVERITY = 'severity';
const String STACK_TRACE = 'stackTrace';
const String START_COLUMN = 'startColumn';
const String START_LINE = 'startLine';
const String STATIC_TYPE = 'staticType';
const String SUBCLASSES = 'subclasses';
const String SUBSCRIPTIONS = 'subscriptions';
const String SUGGESTIONS = 'suggestions';
const String SUPER_CLASS_MEMBER = 'superclassMember';
const String SUPERCLASS = 'superclass';
const String TARGETS = 'targets';
const String TYPE = 'type';
const String VALUE = 'value';
const String VERSION = 'version';
