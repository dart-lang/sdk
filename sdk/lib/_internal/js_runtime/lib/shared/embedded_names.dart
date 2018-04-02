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

/// The name of the property that is used to mark a type as typedef.
///
/// Without reflection typedefs are removed (expanded to their function type)
/// but with reflection an object is needed to have the typedef's name. The
/// object is marked with this property.
///
/// This property name only lives on internal type-objects and is only used
/// when reflection is enabled.
const TYPEDEF_PREDICATE_PROPERTY_NAME = r"$$isTypedef";

/// The name of the property that is used to find the function type of a
/// typedef.
///
/// Without reflection typedefs are removed (expanded to their function type)
/// but with reflection an object is needed to have the typedef's name.
///
/// The typedef's object contains a pointer to its function type (as an index
/// into the embedded global [TYPES]) in this property.
///
/// This property name only lives on internal type-objects and is only used
/// when reflection is enabled.
const TYPEDEF_TYPE_PROPERTY_NAME = r"$typedefType";

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

/// If [JSInvocationMirror._invokeOn] is being used, this embedded global
/// contains a JavaScript map with the names of methods that are
/// intercepted.
const INTERCEPTED_NAMES = 'interceptedNames';

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

/// Returns a function that creates a new Isolate (its static state).
///
/// (floitsch): Note that this embedded global will probably go away, since one
/// JS heap will only contain one Dart isolate.
const CREATE_NEW_ISOLATE = 'createNewIsolate';

/// Returns a class-id of the given instance.
///
/// The extracted id can be used to built a new instance of the same type
/// (see [INSTANCE_FROM_CLASS_ID].
///
/// This embedded global is used for serialization in the isolate-library.
const CLASS_ID_EXTRACTOR = 'classIdExtractor';

/// Returns an empty instance of the given class-id.
///
/// Given a class-id (see [CLASS_ID_EXTRACTOR]) returns an empty instance.
///
/// This embedded global is used for deserialization in the isolate-library.
const INSTANCE_FROM_CLASS_ID = "instanceFromClassId";

/// Returns a list of (mangled) field names for the given instance.
///
/// The list of fields can be used to extract the instance's values and then
/// initialize an empty instance (see [INITIALIZE_EMPTY_INSTANCE].
///
/// This embedded global is used for serialization in the isolate-library.
const CLASS_FIELDS_EXTRACTOR = 'classFieldsExtractor';

/// Initializes the given empty instance with the given fields.
///
/// The given fields are in an array and must be in the same order as the
/// field-names obtained by [CLASS_FIELDS_EXTRACTOR].
///
/// This embedded global is used for deserialization in the isolate-library.
const INITIALIZE_EMPTY_INSTANCE = "initializeEmptyInstance";

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

/// Returns a function that creates all precompiled functions (in particular
/// constructors).
///
/// That is, the function returns the array that the full emitter would
/// otherwise build dynamically when it finishes all classes.
///
/// This constant is only used in CSP mode.
///
/// This global is an emitter-internal embedded global, and not used by the
/// runtime. The constant remains in this file to make sure that other embedded
/// globals don't clash with it.
const PRECOMPILED = 'precompiled';

/// An emitter-internal embedded global. This global is not used by the runtime.
const FINISHED_CLASSES = 'finishedClasses';

/// An emitter-internal embedded global. This global is not used by the runtime.
///
/// The constant remains in this file to make sure that other embedded globals
/// don't clash with it.
///
/// It can be used by the compiler to store a mapping from static function names
/// to dart-closure getters (which can be useful for
/// [JsBuiltin.createDartClosureFromNameOfStaticFunction].
const GLOBAL_FUNCTIONS = 'globalFunctions';

/// An emitter-internal embedded global. This global is not used by the runtime.
///
/// The constant remains in this file to make sure that other embedded globals
/// don't clash with it.
///
/// This embedded global stores a function that returns a dart-closure getter
/// for a given static function name.
///
/// This embedded global is used to implement
/// [JsBuiltin.createDartClosureFromNameOfStaticFunction], and is only
/// used with isolates.
const STATIC_FUNCTION_NAME_TO_CLOSURE = 'staticFunctionNameToClosure';

/// A JavaScript object literal that maps the (minified) JavaScript constructor
/// name (as given by [JsBuiltin.rawRtiToJsConstructorName] to the
/// JavaScript constructor.
///
/// This embedded global is only used by reflection.
const ALL_CLASSES = 'allClasses';

/// A map from element to type information.
///
/// This embedded global is only used by reflection.
const TYPE_INFORMATION = 'typeInformation';

/// A map from statics to their descriptors.
///
/// This embedded global is only used by reflection.
const STATICS = 'statics';

/// An array of library descriptors.
///
/// The descriptor contains information such as name, uri, classes, ...
///
/// This embedded global is only used by reflection.
const LIBRARIES = 'libraries';

/// A map from lazy statics to their initializers.
///
/// This embedded global is only used by reflection.
const LAZIES = 'lazies';

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
  REFLECTABLE,
  CLASS_DESCRIPTOR_PROPERTY,
  REQUIRED_PARAMETER_PROPERTY,
  DEFAULT_VALUES_PROPERTY,
  CALL_NAME_PROPERTY,
  DEFERRED_ACTION_PROPERTY,

  /// Prefix used for generated type argument substitutions on classes.
  OPERATOR_AS_PREFIX,

  /// Name used for generated function types on classes and methods.
  SIGNATURE_NAME,

  /// Name of JavaScript property used to store runtime-type information on
  /// instances of parameterized classes.
  RTI_NAME,

  /// Name used to tag typedefs.
  TYPEDEF_TAG,

  /// Name used to tag a function type.
  FUNCTION_TYPE_TAG,

  /// Name used to tag bounds of a generic function type. If bounds are present,
  /// the property value is an Array of bounds (the length gives the number of
  /// type parameters). If absent, the type is not a generic function type.
  FUNCTION_TYPE_GENERIC_BOUNDS_TAG,

  /// Name used to tag void return in function type representations in
  /// JavaScript.
  FUNCTION_TYPE_VOID_RETURN_TAG,

  /// Name used to tag return types in function type representations in
  /// JavaScript.
  FUNCTION_TYPE_RETURN_TYPE_TAG,

  /// Name used to tag required parameters in function type representations
  /// in JavaScript.
  FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG,

  /// Name used to tag optional parameters in function type representations
  /// in JavaScript.
  FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG,

  /// Name used to tag named parameters in function type representations in
  /// JavaScript.
  FUNCTION_TYPE_NAMED_PARAMETERS_TAG,

  /// Name used to tag a FutureOr type.
  FUTURE_OR_TAG,

  /// Name used to tag type arguments types in FutureOr type representations in
  /// JavaScript.
  FUTURE_OR_TYPE_ARGUMENT_TAG,

  /// String representation of the type of the Future class.
  FUTURE_CLASS_TYPE_NAME,

  /// Field name used for determining if an object or its interceptor has
  /// JavaScript indexing behavior.
  IS_INDEXABLE_FIELD_NAME,

  /// String representation of the type of the null class.
  NULL_CLASS_TYPE_NAME,

  /// String representation of the type of the object class.
  OBJECT_CLASS_TYPE_NAME,

  /// String representation of the type of the function class.
  FUNCTION_CLASS_TYPE_NAME,
}

enum JsBuiltin {
  /// Returns the JavaScript constructor function for Dart's Object class.
  /// This can be used for type tests, as in
  ///
  ///     var constructor = JS_BUILTIN('', JsBuiltin.dartObjectConstructor);
  ///     if (JS('bool', '# instanceof #', obj, constructor))
  ///       ...
  dartObjectConstructor,

  /// Returns the JavaScript-constructor name given an [isCheckProperty].
  ///
  /// This relies on a deterministic encoding of is-check properties (for
  /// example `$isFoo` for a class `Foo`). In minified code the returned
  /// classname is the minified name of the class.
  ///
  ///     JS_BUILTIN('returns:String;depends:none;effects:none',
  ///                JsBuiltin.isCheckPropertyToJsConstructorName,
  ///                isCheckProperty);
  isCheckPropertyToJsConstructorName,

  /// Returns true if the given type is a function type. Returns false for
  /// the one `Function` type singleton. (See [isFunctionTypeSingleton]).
  ///
  ///     JS_BUILTIN('bool', JsBuiltin.isFunctionType, o)
  isFunctionType,

  /// Returns true if the given type is a FutureOr type.
  ///
  ///     JS_BUILTIN('bool', JsBuiltin.isFutureOrType, o)
  isFutureOrType,

  /// Returns true if the given type is the `void` type.
  ///
  ///     JS_BUILTIN('bool', JsBuiltin.isVoidType, o)
  isVoidType,

  /// Returns true if the given type is the `dynamic` type.
  ///
  ///     JS_BUILTIN('bool', JsBuiltin.isDynamicType, o)
  isDynamicType,

  /// Returns the JavaScript-constructor name given an rti encoding.
  ///
  ///     JS_BUILTIN('String', JsBuiltin.rawRtiToJsConstructorName, rti)
  rawRtiToJsConstructorName,

  /// Returns the raw runtime type of the given object. The given argument
  /// [o] should be the interceptor (for non-Dart objects).
  ///
  ///     JS_BUILTIN('', JsBuiltin.rawRuntimeType, o)
  rawRuntimeType,

  /// Returns whether the given type is a subtype of other.
  ///
  /// The argument `other` is the name of the potential supertype. It is
  /// computed by `runtimeTypeToString`;
  ///
  /// *The `other` name must be passed in before the `type`.*
  ///
  ///     JS_BUILTIN('returns:bool;effects:none;depends:none',
  ///                JsBuiltin.isSubtype, other, type);
  isSubtype,

  /// Returns true if the given type equals the type given as second
  /// argument. Use the JS_GET_NAME helpers to get the type representation
  /// for various Dart classes.
  ///
  ///     JS_BUILTIN('returns:bool;effects:none;depends:none',
  ///                JsBuiltin.isFunctionTypeLiteral, type, name);
  isGivenTypeRti,

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

  /// Returns a Dart closure for the global function with the given [name].
  ///
  /// The [name] is the globally unique (minified) JavaScript name of the
  /// function (same as the one stored in [STATIC_FUNCTION_NAME_PROPERTY_NAME])
  ///
  /// This builtin is used when a static closure was sent to a different
  /// isolate.
  ///
  ///     JS_BUILTIN('returns:Function',
  ///                JsBuiltin.createDartClosureFromNameOfStaticFunction, name);
  createDartClosureFromNameOfStaticFunction,
}
