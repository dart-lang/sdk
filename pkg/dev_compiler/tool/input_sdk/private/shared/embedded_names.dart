// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains the names of globals that are embedded into the output by the
/// compiler.
///
/// Variables embedded this way should be access with `JS_EMBEDDED_GLOBAL` from
/// the `_foreign_helper` library.
///
/// This library is shared between the compiler and the runtime system.
library dart2js._embedded_names;

const DISPATCH_PROPERTY_NAME = "dispatchPropertyName";
const TYPE_INFORMATION = 'typeInformation';
const GLOBAL_FUNCTIONS = 'globalFunctions';
const STATICS = 'statics';

/**
 * If [JSInvocationMirror._invokeOn] is being used, this embedded global
 * contains a JavaScript map with the names of methods that are
 * intercepted.
 */
const INTERCEPTED_NAMES = 'interceptedNames';

const MANGLED_GLOBAL_NAMES = 'mangledGlobalNames';
const MANGLED_NAMES = 'mangledNames';
const LIBRARIES = 'libraries';
const FINISHED_CLASSES = 'finishedClasses';
const ALL_CLASSES = 'allClasses';
const METADATA = 'metadata';
const INTERCEPTORS_BY_TAG = 'interceptorsByTag';
const LEAF_TAGS = 'leafTags';
const LAZIES = 'lazies';
const GET_ISOLATE_TAG = 'getIsolateTag';
const ISOLATE_TAG = 'isolateTag';
const CURRENT_SCRIPT = 'currentScript';
const DEFERRED_LIBRARY_URIS = 'deferredLibraryUris';
const DEFERRED_LIBRARY_HASHES = 'deferredLibraryHashes';
const INITIALIZE_LOADED_HUNK = 'initializeLoadedHunk';
const IS_HUNK_LOADED = 'isHunkLoaded';
const IS_HUNK_INITIALIZED = 'isHunkInitialized';
const DEFERRED_INITIALIZED = 'deferredInitialized';
const CLASS_ID_EXTRACTOR = 'classIdExtractor';
const CLASS_FIELDS_EXTRACTOR = 'classFieldsExtractor';
const INSTANCE_FROM_CLASS_ID = "instanceFromClassId";
const INITIALIZE_EMPTY_INSTANCE = "initializeEmptyInstance";
const TYPEDEF_TYPE_PROPERTY_NAME = r"$typedefType";
const TYPEDEF_PREDICATE_PROPERTY_NAME = r"$$isTypedef";
const NATIVE_SUPERCLASS_TAG_NAME = r"$nativeSuperclassTag";

const MAP_TYPE_TO_INTERCEPTOR = "mapTypeToInterceptor";
