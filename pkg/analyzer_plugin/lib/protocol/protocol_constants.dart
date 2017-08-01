// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

const String ANALYSIS_NOTIFICATION_ERRORS = 'analysis.errors';
const String ANALYSIS_NOTIFICATION_ERRORS_ERRORS = 'errors';
const String ANALYSIS_NOTIFICATION_ERRORS_FILE = 'file';
const String ANALYSIS_NOTIFICATION_FOLDING = 'analysis.folding';
const String ANALYSIS_NOTIFICATION_FOLDING_FILE = 'file';
const String ANALYSIS_NOTIFICATION_FOLDING_REGIONS = 'regions';
const String ANALYSIS_NOTIFICATION_HIGHLIGHTS = 'analysis.highlights';
const String ANALYSIS_NOTIFICATION_HIGHLIGHTS_FILE = 'file';
const String ANALYSIS_NOTIFICATION_HIGHLIGHTS_REGIONS = 'regions';
const String ANALYSIS_NOTIFICATION_NAVIGATION = 'analysis.navigation';
const String ANALYSIS_NOTIFICATION_NAVIGATION_FILE = 'file';
const String ANALYSIS_NOTIFICATION_NAVIGATION_FILES = 'files';
const String ANALYSIS_NOTIFICATION_NAVIGATION_REGIONS = 'regions';
const String ANALYSIS_NOTIFICATION_NAVIGATION_TARGETS = 'targets';
const String ANALYSIS_NOTIFICATION_OCCURRENCES = 'analysis.occurrences';
const String ANALYSIS_NOTIFICATION_OCCURRENCES_FILE = 'file';
const String ANALYSIS_NOTIFICATION_OCCURRENCES_OCCURRENCES = 'occurrences';
const String ANALYSIS_NOTIFICATION_OUTLINE = 'analysis.outline';
const String ANALYSIS_NOTIFICATION_OUTLINE_FILE = 'file';
const String ANALYSIS_NOTIFICATION_OUTLINE_OUTLINE = 'outline';
const String ANALYSIS_REQUEST_GET_NAVIGATION = 'analysis.getNavigation';
const String ANALYSIS_REQUEST_GET_NAVIGATION_FILE = 'file';
const String ANALYSIS_REQUEST_GET_NAVIGATION_LENGTH = 'length';
const String ANALYSIS_REQUEST_GET_NAVIGATION_OFFSET = 'offset';
const String ANALYSIS_REQUEST_HANDLE_WATCH_EVENTS =
    'analysis.handleWatchEvents';
const String ANALYSIS_REQUEST_HANDLE_WATCH_EVENTS_EVENTS = 'events';
const String ANALYSIS_REQUEST_SET_CONTEXT_ROOTS = 'analysis.setContextRoots';
const String ANALYSIS_REQUEST_SET_CONTEXT_ROOTS_ROOTS = 'roots';
const String ANALYSIS_REQUEST_SET_PRIORITY_FILES = 'analysis.setPriorityFiles';
const String ANALYSIS_REQUEST_SET_PRIORITY_FILES_FILES = 'files';
const String ANALYSIS_REQUEST_SET_SUBSCRIPTIONS = 'analysis.setSubscriptions';
const String ANALYSIS_REQUEST_SET_SUBSCRIPTIONS_SUBSCRIPTIONS = 'subscriptions';
const String ANALYSIS_REQUEST_UPDATE_CONTENT = 'analysis.updateContent';
const String ANALYSIS_REQUEST_UPDATE_CONTENT_FILES = 'files';
const String ANALYSIS_RESPONSE_GET_NAVIGATION_FILES = 'files';
const String ANALYSIS_RESPONSE_GET_NAVIGATION_REGIONS = 'regions';
const String ANALYSIS_RESPONSE_GET_NAVIGATION_TARGETS = 'targets';
const String COMPLETION_REQUEST_GET_SUGGESTIONS = 'completion.getSuggestions';
const String COMPLETION_REQUEST_GET_SUGGESTIONS_FILE = 'file';
const String COMPLETION_REQUEST_GET_SUGGESTIONS_OFFSET = 'offset';
const String COMPLETION_RESPONSE_GET_SUGGESTIONS_REPLACEMENT_LENGTH =
    'replacementLength';
const String COMPLETION_RESPONSE_GET_SUGGESTIONS_REPLACEMENT_OFFSET =
    'replacementOffset';
const String COMPLETION_RESPONSE_GET_SUGGESTIONS_RESULTS = 'results';
const String EDIT_REQUEST_GET_ASSISTS = 'edit.getAssists';
const String EDIT_REQUEST_GET_ASSISTS_FILE = 'file';
const String EDIT_REQUEST_GET_ASSISTS_LENGTH = 'length';
const String EDIT_REQUEST_GET_ASSISTS_OFFSET = 'offset';
const String EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS =
    'edit.getAvailableRefactorings';
const String EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS_FILE = 'file';
const String EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS_LENGTH = 'length';
const String EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS_OFFSET = 'offset';
const String EDIT_REQUEST_GET_FIXES = 'edit.getFixes';
const String EDIT_REQUEST_GET_FIXES_FILE = 'file';
const String EDIT_REQUEST_GET_FIXES_OFFSET = 'offset';
const String EDIT_REQUEST_GET_REFACTORING = 'edit.getRefactoring';
const String EDIT_REQUEST_GET_REFACTORING_FILE = 'file';
const String EDIT_REQUEST_GET_REFACTORING_KIND = 'kind';
const String EDIT_REQUEST_GET_REFACTORING_LENGTH = 'length';
const String EDIT_REQUEST_GET_REFACTORING_OFFSET = 'offset';
const String EDIT_REQUEST_GET_REFACTORING_OPTIONS = 'options';
const String EDIT_REQUEST_GET_REFACTORING_VALIDATE_ONLY = 'validateOnly';
const String EDIT_RESPONSE_GET_ASSISTS_ASSISTS = 'assists';
const String EDIT_RESPONSE_GET_AVAILABLE_REFACTORINGS_KINDS = 'kinds';
const String EDIT_RESPONSE_GET_FIXES_FIXES = 'fixes';
const String EDIT_RESPONSE_GET_REFACTORING_CHANGE = 'change';
const String EDIT_RESPONSE_GET_REFACTORING_FEEDBACK = 'feedback';
const String EDIT_RESPONSE_GET_REFACTORING_FINAL_PROBLEMS = 'finalProblems';
const String EDIT_RESPONSE_GET_REFACTORING_INITIAL_PROBLEMS = 'initialProblems';
const String EDIT_RESPONSE_GET_REFACTORING_OPTIONS_PROBLEMS = 'optionsProblems';
const String EDIT_RESPONSE_GET_REFACTORING_POTENTIAL_EDITS = 'potentialEdits';
const String PLUGIN_NOTIFICATION_ERROR = 'plugin.error';
const String PLUGIN_NOTIFICATION_ERROR_IS_FATAL = 'isFatal';
const String PLUGIN_NOTIFICATION_ERROR_MESSAGE = 'message';
const String PLUGIN_NOTIFICATION_ERROR_STACK_TRACE = 'stackTrace';
const String PLUGIN_REQUEST_SHUTDOWN = 'plugin.shutdown';
const String PLUGIN_REQUEST_VERSION_CHECK = 'plugin.versionCheck';
const String PLUGIN_REQUEST_VERSION_CHECK_BYTE_STORE_PATH = 'byteStorePath';
const String PLUGIN_REQUEST_VERSION_CHECK_SDK_PATH = 'sdkPath';
const String PLUGIN_REQUEST_VERSION_CHECK_VERSION = 'version';
const String PLUGIN_RESPONSE_VERSION_CHECK_CONTACT_INFO = 'contactInfo';
const String PLUGIN_RESPONSE_VERSION_CHECK_INTERESTING_FILES =
    'interestingFiles';
const String PLUGIN_RESPONSE_VERSION_CHECK_IS_COMPATIBLE = 'isCompatible';
const String PLUGIN_RESPONSE_VERSION_CHECK_NAME = 'name';
const String PLUGIN_RESPONSE_VERSION_CHECK_VERSION = 'version';
