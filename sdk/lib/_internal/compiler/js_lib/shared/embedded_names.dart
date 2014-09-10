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
const INTERCEPTED_NAMES = 'interceptedNames';
const MANGLED_GLOBAL_NAMES = 'mangledGlobalNames';
const MANGLED_NAMES = 'mangledNames';
const LIBRARIES = 'libraries';
const ALL_CLASSES = 'allClasses';
const METADATA = 'metadata';
const INTERCEPTORS_BY_TAG = 'interceptorsByTag';
const LEAF_TAGS = 'leafTags';
const LAZIES = 'lazies';
const GET_ISOLATE_TAG = 'getIsolateTag';
const ISOLATE_TAG = 'isolateTag';
const CURRENT_SCRIPT = 'currentScript';