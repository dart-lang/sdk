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
const String ANALYSIS_GET_LIBRARY_DEPENDENCIES =
    'analysis.getLibraryDependencies';
const String ANALYSIS_GET_NAVIGATION = 'analysis.getNavigation';
const String ANALYSIS_GET_REACHABLE_SOURCES = 'analysis.getReachableSources';
const String ANALYSIS_REANALYZE = 'analysis.reanalyze';
const String ANALYSIS_SET_ANALYSIS_ROOTS = 'analysis.setAnalysisRoots';
const String ANALYSIS_SET_GENERAL_SUBSCRIPTIONS =
    'analysis.setGeneralSubscriptions';
const String ANALYSIS_SET_PRIORITY_FILES = 'analysis.setPriorityFiles';
const String ANALYSIS_SET_SUBSCRIPTIONS = 'analysis.setSubscriptions';
const String ANALYSIS_UPDATE_CONTENT = 'analysis.updateContent';
const String ANALYSIS_UPDATE_OPTIONS = 'analysis.updateOptions';

//
// Analysis notifications
//
const String ANALYSIS_ANALYZED_FILES = 'analysis.analyzedFiles';
const String ANALYSIS_ERRORS = 'analysis.errors';
const String ANALYSIS_HIGHLIGHTS = 'analysis.highlights';
const String ANALYSIS_IMPLEMENTED = 'analysis.implemented';
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
const String SEARCH_GET_TYPE_HIERARCHY = 'search.getTypeHierarchy';

//
// Search notifications
//
const String SEARCH_RESULTS = 'search.results';

//
// Edit methods
//
const String EDIT_FORMAT = 'edit.format';
const String EDIT_GET_ASSISTS = 'edit.getAssists';
const String EDIT_GET_AVAILABLE_REFACTORINGS = 'edit.getAvailableRefactorings';
const String EDIT_GET_FIXES = 'edit.getFixes';
const String EDIT_GET_REFACTORING = 'edit.getRefactoring';
const String EDIT_ORGANIZE_DIRECTIVES = 'edit.organizeDirectives';
const String EDIT_SORT_MEMBERS = 'edit.sortMembers';

//
// Execution methods
//
const String EXECUTION_CREATE_CONTEXT = 'execution.createContext';
const String EXECUTION_DELETE_CONTEXT = 'execution.deleteContext';
const String EXECUTION_MAP_URI = 'execution.mapUri';
const String EXECUTION_SET_SUBSCRIPTIONS = 'execution.setSubscriptions';

//
// Execution notifications
//
const String EXECUTION_LAUNCH_DATA = 'execution.launchData';

//
// Analysis option names
//
const String ENABLE_ASYNC = 'enableAsync'; // boolean
const String ENABLE_DEFERRED_LOADING = 'enableDeferredLoading'; // boolean
const String ENABLE_ENUMS = 'enableEnums'; // boolean
const String GENERATE_DART2JS_HINTS = 'generateDart2jsHints'; // boolean
const String GENERATE_HINTS = 'generateHints'; // boolean

//
// Property names
//
const String ADD = 'add';
const String ADDED = 'added';
const String ASSISTS = 'assists';
const String CHANGE = 'change';
const String CHILDREN = 'children';
const String CLASS_ELEMENT = 'classElement';
const String CLASS_NAME = 'className';
const String CODE = 'code';
const String COMPLETION = 'completion';
const String CONTAINING_LIBRARY_NAME = 'containingLibraryName';
const String CONTAINING_LIBRARY_PATH = 'containingLibraryPath';
const String CONTENT = 'content';
const String CORRECTION = 'correction';
const String DART_DOC = 'dartdoc';
const String DEFAULT = 'default';
const String DISPLAY_NAME = 'displayName';
const String EDITS = 'edits';
const String ELEMENT = 'element';
const String ELEMENT_DESCRIPTION = 'elementDescription';
const String ELEMENT_KIND = 'elementKind';
const String EXCLUDED = 'excluded';
const String ERROR = 'error';
const String ERRORS = 'errors';
const String FATAL = 'fatal';
const String FILE = 'file';
const String FILE_STAMP = 'fileStamp';
const String FILES = 'files';
const String FIXES = 'fixes';
const String FLAGS = 'flags';
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
const String REPLACEMENT_OFFSET = 'replacementOffset';
const String REPLACEMENT_LENGTH = 'replacementLength';
const String RETURN_TYPE = 'returnType';
const String RESULTS = 'results';
const String SELECTION = 'selection';
const String SEVERITY = 'severity';
const String SELECTION_LENGTH = 'selectionLength';
const String SELECTION_OFFSET = 'selectionOffset';
const String STACK_TRACE = 'stackTrace';
const String START_COLUMN = 'startColumn';
const String START_LINE = 'startLine';
const String STATIC_TYPE = 'staticType';
const String SUBCLASSES = 'subclasses';
const String SUBSCRIPTIONS = 'subscriptions';
const String SUGGESTIONS = 'suggestions';
const String SUPERCLASS = 'superclass';
const String SUPER_CLASS_MEMBER = 'superclassMember';
const String TARGETS = 'targets';
const String TYPE = 'type';
const String VALUE = 'value';
const String VERSION = 'version';
