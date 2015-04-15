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

/// If [JSInvocationMirror._invokeOn] is being used, this embedded global
/// contains a JavaScript map with the names of methods that are
/// intercepted.
const INTERCEPTED_NAMES = 'interceptedNames';

/// A JS map from mangled global names to their unmangled names.
///
/// If the program does not use reflection may be empty (but not null or
/// undefined).
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
const PRECOMPILED = 'precompiled';

/// A list of types used in the program e.g. for reflection or encoding of
/// function types.
const TYPES = 'types';

/// Returns a function that creates a new Isolate (its static state).
///
/// (floitsch): Note that this will probably go away, since one JS heap will
/// only contain one Dart isolate.
const CREATE_NEW_ISOLATE = 'createNewIsolate';

const CLASS_ID_EXTRACTOR = 'classIdExtractor';
const CLASS_FIELDS_EXTRACTOR = 'classFieldsExtractor';
const INSTANCE_FROM_CLASS_ID = "instanceFromClassId";
const INITIALIZE_EMPTY_INSTANCE = "initializeEmptyInstance";
const TYPEDEF_TYPE_PROPERTY_NAME = r"$typedefType";
const TYPEDEF_PREDICATE_PROPERTY_NAME = r"$$isTypedef";
const NATIVE_SUPERCLASS_TAG_NAME = r"$nativeSuperclassTag";

/// Returns the type given the name of a class.
/// This function is called by the runtime when computing rti.
const GET_TYPE_FROM_NAME = 'getTypeFromName';
const TYPE_TO_INTERCEPTOR_MAP = "typeToInterceptorMap";

/// Names that are supported by [JS_GET_NAME].
// TODO(herhut): Make entries lower case (as in fields) and find a better name.
enum JsGetName {
  GETTER_PREFIX,
  SETTER_PREFIX,
  CALL_PREFIX,
  CALL_PREFIX0,
  CALL_PREFIX1,
  CALL_PREFIX2,
  CALL_PREFIX3,
  CALL_CATCH_ALL,
  REFLECTABLE,
  CLASS_DESCRIPTOR_PROPERTY,
  REQUIRED_PARAMETER_PROPERTY,
  DEFAULT_VALUES_PROPERTY,
  CALL_NAME_PROPERTY,
  DEFERRED_ACTION_PROPERTY
}
