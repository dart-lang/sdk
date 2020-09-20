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

/// The name of the property that is used to find the native superclass of
/// an extended class.
///
/// Every class that extends a native class has this property set on its
/// native class.
const NATIVE_SUPERCLASS_TAG_NAME = r"$nativeSuperclassTag";

/// The name of the static-function property name.
///
/// This property is set for all tear-offs of static functions, and provides
/// the static function's unique (potentially minified) name.
const STATIC_FUNCTION_NAME_PROPERTY_NAME = r'$static_name';

/// The name of a property on the constructor function of Dart Object
/// and interceptor types, used for caching Rti types.
const CONSTRUCTOR_RTI_CACHE_PROPERTY_NAME = r'$ccache';

/// The name of the embedded global for metadata.
///
/// Use [JsBuiltin.getMetadata] instead of directly accessing this embedded
/// global.
const METADATA = 'metadata';

/// A list of types used in the program e.g. for reflection or encoding of
/// function types.
///
/// Use [JsBuiltin.getType] instead of directly accessing this embedded global.
const TYPES = 'types';

/// Returns a function that maps a name of a class to its type.
///
/// This embedded global is used by the runtime when computing the internal
/// runtime-type-information (rti) object.
const GET_TYPE_FROM_NAME = 'getTypeFromName';

/// A JS map from mangled global names to their unmangled names.
///
/// If the program does not use reflection, this embedded global may be empty
/// (but not null or undefined).
const MANGLED_GLOBAL_NAMES = 'mangledGlobalNames';

/// A JS map from mangled instance names to their unmangled names.
///
/// This embedded global is mainly used for reflection, but is also used to
/// map const-symbols (`const Symbol('x')`) to the mangled instance names.
///
/// This embedded global may be empty (but not null or undefined).
const MANGLED_NAMES = 'mangledNames';

/// A JS map from dispatch tags (usually constructor names of DOM classes) to
/// interceptor class. This map is used to find the correct interceptor for
/// native classes.
///
/// This embedded global is used for natives.
const INTERCEPTORS_BY_TAG = 'interceptorsByTag';

/// A JS map from dispatch tags (usually constructor names of DOM classes) to
/// booleans. Every tag entry of [INTERCEPTORS_BY_TAG] has a corresponding
/// entry in the leaf-tags map.
///
/// A tag-entry is true, when a class can be treated as leaf class in the
/// hierarchy. That is, even though it might have subclasses, all subclasses
/// have the same code for the used methods.
///
/// This embedded global is used for natives.
const LEAF_TAGS = 'leafTags';

/// A JS function that returns the isolate tag for a given name.
///
/// This function uses the [ISOLATE_TAG] (below) to construct a name that is
/// unique per isolate.
///
/// This embedded global is used for natives.
// TODO(floitsch): should we rename this variable to avoid confusion with
//    [INTERCEPTORS_BY_TAG] and [LEAF_TAGS].
const GET_ISOLATE_TAG = 'getIsolateTag';

/// A string that is different for each running isolate.
///
/// When this embedded global is initialized a global variable is used to
/// ensure that no other running isolate uses the same isolate-tag string.
///
/// This embedded global is used for natives.
// TODO(floitsch): should we rename this variable to avoid confusion with
//    [INTERCEPTORS_BY_TAG] and [LEAF_TAGS].
const ISOLATE_TAG = 'isolateTag';

/// An embedded global that contains the property used to store type information
/// on JavaScript Array instances. This is a Symbol (except for IE11, where is
/// is a String).
const ARRAY_RTI_PROPERTY = 'arrayRti';

/// This embedded global (a function) returns the isolate-specific dispatch-tag
/// that is used to accelerate interceptor calls.
const DISPATCH_PROPERTY_NAME = "dispatchPropertyName";

/// An embedded global that maps a [Type] to the [Interceptor] and constructors
/// for that type.
///
/// More documentation can be found in the interceptors library (close to its
/// use).
const TYPE_TO_INTERCEPTOR_MAP = "typeToInterceptorMap";

/// The current script's URI when the program was loaded.
///
/// This embedded global is set at startup, just before invoking `main`.
const CURRENT_SCRIPT = 'currentScript';

/// Contains a map from load-ids to lists of part indexes.
///
/// To load the deferred library that is represented by the load-id, the runtime
/// must load all associated URIs (named in DEFERRED_PART_URIS) and initialize
/// all the loaded hunks (DEFERRED_PART_HASHES).
///
/// This embedded global is only used for deferred loading.
const DEFERRED_LIBRARY_PARTS = 'deferredLibraryParts';

/// Contains a list of URIs (Strings), indexed by part.
///
/// The lists in the DEFERRED_LIBRARY_PARTS map contain indexes into this list.
///
/// This embedded global is only used for deferred loading.
const DEFERRED_PART_URIS = 'deferredPartUris';

/// Contains a list of hashes, indexed by part.
///
/// The lists in the DEFERRED_LIBRARY_PARTS map contain indexes into this list.
///
/// The hashes are associated with the URIs of the load-ids (see
/// [DEFERRED_PART_URIS]). They are SHA1 (or similar) hashes of the code that
/// must be loaded. By using cryptographic hashes we can (1) handle loading in
/// the same web page the parts from multiple Dart applications (2) avoid
/// loading similar code multiple times.
///
/// This embedded global is only used for deferred loading.
const DEFERRED_PART_HASHES = 'deferredPartHashes';

/// Initialize a loaded hunk.
///
/// Once a hunk (the code from a deferred URI) has been loaded it must be
/// initialized. Calling this function with the corresponding hash (see
/// [DEFERRED_LIBRARY_HASHES]) initializes the code.
///
/// This embedded global is only used for deferred loading.
const INITIALIZE_LOADED_HUNK = 'initializeLoadedHunk';

/// Returns, whether a hunk (identified by its hash) has already been loaded.
///
/// This embedded global is only used for deferred loading.
const IS_HUNK_LOADED = 'isHunkLoaded';

/// Returns, whether a hunk (identified by its hash) has already been
/// initialized.
///
/// This embedded global is only used for deferred loading.
const IS_HUNK_INITIALIZED = 'isHunkInitialized';

/// A set (implemented as map to booleans) of hunks (identified by hashes) that
/// have already been initialized.
///
/// This embedded global is only used for deferred loading.
///
/// This global is an emitter-internal embedded global, and not used by the
/// runtime. The constant remains in this file to make sure that other embedded
/// globals don't clash with it.
const DEFERRED_INITIALIZED = 'deferredInitialized';

/// A 'Universe' object used by 'dart:_rti'.
///
/// This embedded global is used for --experiment-new-rti.
const RTI_UNIVERSE = 'typeUniverse';

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
  CALL_PREFIX4,
  CALL_PREFIX5,
  CALL_CATCH_ALL,
  REQUIRED_PARAMETER_PROPERTY,
  DEFAULT_VALUES_PROPERTY,
  CALL_NAME_PROPERTY,
  DEFERRED_ACTION_PROPERTY,

  /// Prefix used for generated type argument substitutions on classes.
  OPERATOR_AS_PREFIX,

  /// Prefix used for generated type test property on classes.
  OPERATOR_IS_PREFIX,

  /// Name used for generated function types on classes and methods.
  SIGNATURE_NAME,

  /// Name of JavaScript property used to store runtime-type information on
  /// instances of parameterized classes.
  RTI_NAME,

  /// String representation of the type of the Future class.
  FUTURE_CLASS_TYPE_NAME,

  /// Field name used for determining if an object or its interceptor has
  /// JavaScript indexing behavior.
  IS_INDEXABLE_FIELD_NAME,

  /// String representation of the type of the null class.
  NULL_CLASS_TYPE_NAME,

  /// String representation of the type of the object class.
  OBJECT_CLASS_TYPE_NAME,

  /// Property name for Rti._as field.
  RTI_FIELD_AS,

  /// Property name for Rti._is field.
  RTI_FIELD_IS,
}

enum JsBuiltin {
  /// Returns the JavaScript constructor function for Dart's Object class.
  /// This can be used for type tests, as in
  ///
  ///     var constructor = JS_BUILTIN('', JsBuiltin.dartObjectConstructor);
  ///     if (JS('bool', '# instanceof #', obj, constructor))
  ///       ...
  dartObjectConstructor,

  /// Returns the JavaScript constructor function for the runtime's Closure
  /// class, the base class of all closure objects.  This can be used for type
  /// tests, as in
  ///
  ///     var constructor = JS_BUILTIN('', JsBuiltin.dartClosureConstructor);
  ///     if (JS('bool', '# instanceof #', obj, constructor))
  ///       ...
  dartClosureConstructor,

  /// Returns true if the given type is a type argument of a js-interop class
  /// or a supertype of a js-interop class.
  ///
  ///     JS_BUILTIN('bool', JsBuiltin.isJsInteropTypeArgument, o)
  isJsInteropTypeArgument,

  /// Returns the metadata of the given [index].
  ///
  ///     JS_BUILTIN('returns:var;effects:none;depends:none',
  ///                JsBuiltin.getMetadata, index);
  getMetadata,

  /// Returns the type of the given [index].
  ///
  ///     JS_BUILTIN('returns:var;effects:none;depends:none',
  ///                JsBuiltin.getType, index);
  getType,
}

/// Names of fields of the Rti Universe object.
class RtiUniverseFieldNames {
  static String evalCache = 'eC';
  static String typeRules = 'tR';
  static String erasedTypes = 'eT';
  static String typeParameterVariances = 'tPV';
  static String sharedEmptyArray = 'sEA';
}
