// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library constants;


//
// Server methods
//
const String METHOD_GET_VERSION =              'server.getVersion';
const String METHOD_SHUTDOWN =                 'server.shutdown';
const String METHOD_SET_SERVER_SUBSCRIPTIONS = 'server.setSubscriptions';

//
// Analysis methods
//
const String METHOD_GET_FIXES =                  'analysis.getFixes';
const String METHOD_GET_MINOR_REFACTORINGS =     'analysis.getMinorRefactorings';
const String METHOD_SET_ANALYSIS_ROOTS =         'analysis.setAnalysisRoots';
const String METHOD_SET_PRIORITY_FILES =         'analysis.setPriorityFiles';
const String METHOD_SET_ANALYSIS_SUBSCRIPTIONS = 'analysis.setSubscriptions';
const String METHOD_UPDATE_CONTENT =             'analysis.updateContent';
const String METHOD_UPDATE_OPTIONS =             'analysis.updateOptions';
const String METHOD_UPDATE_SDKS =                'analysis.updateSdks';

//
// Server notifications
//
const String NOTIFICATION_CONNECTED  = 'server.connected';
const String NOTIFICATION_STATUS =     'server.status';

//
// Analysis notifications
//
const String NOTIFICATION_ERRORS =     'analysis.errors';
const String NOTIFICATION_HIGHLIGHTS = 'analysis.highlights';
const String NOTIFICATION_NAVIGATION = 'analysis.navigation';
const String NOTIFICATION_OUTLINE =    'analysis.outline';


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
const String REFACTORINGS = 'refactorings';
const String REGIONS = 'regions';
const String REMOVED = 'removed';
const String RETURN_TYPE = 'returnType';
const String SUBSCRIPTIONS = 'subscriptions';
const String VERSION = 'version';
