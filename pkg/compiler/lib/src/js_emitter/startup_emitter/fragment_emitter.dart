// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.startup_emitter.model_emitter;

/// The name of the property that stores the tear-off getter on a static
/// function.
///
/// This property is only used when isolates are used.
///
/// When serializing static functions we transmit the
/// name of the static function, but not the name of the function's getter. We
/// store the getter-function on the static function itself, which allows us to
/// find it easily.
const String _tearOffPropertyName = r'$tearOff';

/// The fast startup emitter's goal is to minimize the amount of work that the
/// JavaScript engine has to do before it can start running user code.
///
/// Whenever possible, the emitter uses object literals instead of updating
/// objects.
///
/// Example:
///
///     // Holders are initialized directly with the classes and static
///     // functions.
///     var A = { Point: function Point(x, y) { this.x = x; this.y = y },
///               someStaticFunction: function someStaticFunction() { ... } };
///
///     // Class-behavior is emitted in a prototype object that is directly
///     // assigned:
///     A.Point.prototype = { distanceTo: function(other) { ... } };
///
///     // Inheritance is achieved by updating the prototype objects (hidden in
///     // a helper function):
///     A.Point.prototype.__proto__ = H.Object.prototype;
///
/// The emitter doesn't try to be clever and emits everything beforehand. This
/// increases the output size, but improves performance.
///
// The code relies on the fact that all Dart code is inside holders. As such
// we can use "global" names however we want. As long as we don't shadow
// JavaScript variables (like `Array`) we are free to chose whatever variable
// names we want. Furthermore, the pretty-printer minifies local variables, thus
// reducing their size.
const String _mainBoilerplate = '''
(function dartProgram() {
// Copies the own properties from [from] to [to].
function copyProperties(from, to) {
  var keys = Object.keys(from);
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    to[key] = from[key];
  }
}

// Only use direct proto access to construct the prototype chain (instead of
// copying properties) on platforms where we know it works well (Chrome / d8).
var supportsDirectProtoAccess = #directAccessTestExpression;

// Sets the name property of functions, if the JS engine doesn't set the name
// itself.
// As of 2018 only IE11 doesn't set the name.
function setFunctionNamesIfNecessary(holders) {
  function t(){};
  if (typeof t.name == "string") return;

  for (var i = 0; i < holders.length; i++) {
    var holder = holders[i];
    var keys = Object.keys(holder);
    for (var j = 0; j < keys.length; j++) {
      var key = keys[j];
      var f = holder[key];
      if (typeof f == 'function') f.name = key;
    }
  }
}

// Makes [cls] inherit from [sup].
// On Chrome, Firefox and recent IEs this happens by updating the internal
// proto-property of the classes 'prototype' field.
// Older IEs use `Object.create` and copy over the properties.
function inherit(cls, sup) {
  // Note that RTI needs cls.name, but we don't need to set it anymore.
  if (#legacyJavaScript) {
    cls.prototype.constructor = cls;
  }
  cls.prototype[#operatorIsPrefix + cls.name] = cls;

  // The superclass is only null for the Dart Object.
  if (sup != null) {
    if (supportsDirectProtoAccess) {
      // Firefox doesn't like to update the prototypes, but when setting up
      // the hierarchy chain it's ok.
      cls.prototype.__proto__ = sup.prototype;
      return;
    }
    var clsPrototype = Object.create(sup.prototype);
    copyProperties(cls.prototype, clsPrototype);
    cls.prototype = clsPrototype;
  }
}

// Batched version of [inherit] for multiple classes from one superclass.
function inheritMany(sup, classes) {
  for (var i = 0; i < classes.length; i++) {
    inherit(classes[i], sup);
  }
}

// Mixes in the properties of [mixin] into [cls].
function mixin(cls, mixin) {
  copyProperties(mixin.prototype, cls.prototype);
  cls.prototype.constructor = cls;
}

// Creates a lazy field.
//
// A lazy field has a storage entry, [name], which holds the value, and a
// getter ([getterName]) to access the field. If the field wasn't set before
// the first access, it is initialized with the [initializer].
function lazyOld(holder, name, getterName, initializer) {
  var uninitializedSentinel = holder;
  holder[name] = uninitializedSentinel;
  holder[getterName] = function() {
    holder[getterName] = function() { #cyclicThrow(name) };
    var result;
    var sentinelInProgress = initializer;
    try {
      if (holder[name] === uninitializedSentinel) {
        result = holder[name] = sentinelInProgress;
        result = holder[name] = initializer();
      } else {
        result = holder[name];
      }
    } finally {
      // Use try-finally, not try-catch/throw as it destroys the stack
      // trace.
      if (result === sentinelInProgress) {
        // The lazy static (holder[name]) might have been set to a different
        // value. According to spec we still have to reset it to null, if
        // the initialization failed.
        holder[name] = null;
      }
      // TODO(floitsch): for performance reasons the function should probably
      // be unique for each static.
      holder[getterName] = function() { return this[name]; };
    }
    return result;
  };
}

// Creates a lazy field that uses non-nullable initialization semantics.
//
// A lazy field has a storage entry, [name], which holds the value, and a
// getter ([getterName]) to access the field. If the field wasn't set before
// the first access, it is initialized with the [initializer].
function lazy(holder, name, getterName, initializer) {
  var uninitializedSentinel = holder;
  holder[name] = uninitializedSentinel;
  holder[getterName] = function() {
    if (holder[name] === uninitializedSentinel) {
      holder[name] = initializer();
    }
    holder[getterName] = function() { return this[name]; };
    return holder[name];
  };
}

// Creates a lazy final field that uses non-nullable initialization semantics.
//
// A lazy field has a storage entry, [name], which holds the value, and a
// getter ([getterName]) to access the field. If the field wasn't set before
// the first access, it is initialized with the [initializer].
function lazyFinal(holder, name, getterName, initializer) {
  var uninitializedSentinel = holder;
  holder[name] = uninitializedSentinel;
  holder[getterName] = function() {
    if (holder[name] === uninitializedSentinel) {
      var value = initializer();
      if (holder[name] !== uninitializedSentinel) {
        #throwLateInitializationError(name);
      }
      holder[name] = value;
    }
    holder[getterName] = function() { return this[name]; };
    return holder[name];
  };
}

// Given a list, marks it as constant.
//
// The runtime ensures that const-lists cannot be modified.
function makeConstList(list) {
  // By assigning a function to the properties they become part of the
  // hidden class. The actual values of the fields don't matter, since we
  // only check if they exist.
  list.immutable\$list = Array;
  list.fixed\$length = Array;
  return list;
}

function convertToFastObject(properties) {
  // Create an instance that uses 'properties' as prototype. This should
  // make 'properties' a fast object.
  function t() {}
  t.prototype = properties;
  new t();
  return properties;
}

function convertAllToFastObject(arrayOfObjects) {
  for (var i = 0; i < arrayOfObjects.length; ++i) {
    convertToFastObject(arrayOfObjects[i]);
  }
}

// This variable is used by the tearOffCode to guarantee unique functions per
// tear-offs.
var functionCounter = 0;
#tearOffCode;

// Each deferred hunk comes with its own types which are added to the end
// of the types-array.
// The `funTypes` passed to the `installTearOff` function below is relative to
// the hunk the function comes from. The `typesOffset` variable encodes the
// offset at which the new types will be added.
var typesOffset = 0;

// Adapts the stored data, so it's suitable for a tearOff call.
//
// Stores the tear-off getter-function in the [container]'s [getterName]
// property.
//
// The [container] is either a class (that is, its prototype), or the holder for
// static functions.
//
// The argument [funsOrNames] is an array of strings or functions. If it is a
// name, then the function should be fetched from the container. The first
// entry in that array *must* be a string.
//
// TODO(floitsch): Change tearOffCode to accept the data directly, or create a
// different tearOffCode?
function installTearOff(
    container, getterName, isStatic, isIntercepted, requiredParameterCount,
    optionalParameterDefaultValues, callNames, funsOrNames, funType, applyIndex) {
  // A function can have several stubs (for example to fill in optional
  // arguments). We collect these functions in the `funs` array.
  var funs = [];
  for (var i = 0; i < funsOrNames.length; i++) {
    var fun = funsOrNames[i];
    if ((typeof fun) == 'string') fun = container[fun];
    fun.#callName = callNames[i];
    funs.push(fun);
  }

  // The main function to which all stubs redirect.
  var fun = funs[0];

  fun[#argumentCount] = requiredParameterCount;
  fun[#defaultArgumentValues] = optionalParameterDefaultValues;
  var reflectionInfo = funType;
  if (typeof reflectionInfo == "number") {
    // The reflectionInfo can either be a function, or a pointer into the types
    // table. If it points into the types-table we need to update the index,
    // in case the tear-off is part of a deferred hunk.
    reflectionInfo = reflectionInfo + typesOffset;
  }
  var name = funsOrNames[0];
  fun.#stubName = name;
  var getterFunction =
      tearOff(funs, applyIndex || 0, reflectionInfo, isStatic, name, isIntercepted);
  container[getterName] = getterFunction;
  if (isStatic) {
    fun.$_tearOffPropertyName = getterFunction;
  }
}

function installStaticTearOff(
    container, getterName,
    requiredParameterCount, optionalParameterDefaultValues,
    callNames, funsOrNames, funType, applyIndex) {
  // TODO(sra): Specialize installTearOff for static methods. It might be
  // possible to handle some very common simple cases directly.
  return installTearOff(
      container, getterName, true, false,
      requiredParameterCount, optionalParameterDefaultValues,
      callNames, funsOrNames, funType, applyIndex);
}

function installInstanceTearOff(
    container, getterName, isIntercepted,
    requiredParameterCount, optionalParameterDefaultValues,
    callNames, funsOrNames, funType, applyIndex) {
  // TODO(sra): Specialize installTearOff for instance methods.
  return installTearOff(
      container, getterName, false, isIntercepted,
      requiredParameterCount, optionalParameterDefaultValues,
      callNames, funsOrNames, funType, applyIndex);
}

// Instead of setting the interceptor tags directly we use this update
// function. This makes it easier for deferred fragments to contribute to the
// embedded global.
function setOrUpdateInterceptorsByTag(newTags) {
  var tags = #embeddedInterceptorTags;
  if (!tags) {
    #embeddedInterceptorTags = newTags;
    return;
  }
  copyProperties(newTags, tags);
}

// Instead of setting the leaf tags directly we use this update
// function. This makes it easier for deferred fragments to contribute to the
// embedded global.
function setOrUpdateLeafTags(newTags) {
  var tags = #embeddedLeafTags;
  if (!tags) {
    #embeddedLeafTags = newTags;
    return;
  }
  copyProperties(newTags, tags);
}

// Updates the types embedded global.
function updateTypes(newTypes) {
  var types = #embeddedTypes;
  var length = types.length;
  // The tear-off function uses another 'typesOffset' value cached in
  // [initializeDeferredHunk] so [updateTypes] can be called either before or
  // after the tearoffs have been installed.
  types.push.apply(types, newTypes);
  return length;
}

// Updates the given holder with the properties of the [newHolder].
// This function is used when a deferred fragment is initialized.
function updateHolder(holder, newHolder) {
  copyProperties(newHolder, holder);
  return holder;
}

var #hunkHelpers = (function(){
  var mkInstance = function(
      isIntercepted, requiredParameterCount, optionalParameterDefaultValues,
      callNames, applyIndex) {
    return function(container, getterName, name, funType) {
      return installInstanceTearOff(
          container, getterName, isIntercepted,
          requiredParameterCount, optionalParameterDefaultValues,
          callNames, [name], funType, applyIndex);
    }
  },

  mkStatic = function(
      requiredParameterCount, optionalParameterDefaultValues,
      callNames, applyIndex) {
    return function(container, getterName, name, funType) {
      return installStaticTearOff(
          container, getterName,
          requiredParameterCount, optionalParameterDefaultValues,
          callNames, [name], funType, applyIndex);
    }
  };

  // TODO(sra): Minify properties of 'hunkHelpers'.
  return {
    inherit: inherit,
    inheritMany: inheritMany,
    mixin: mixin,
    installStaticTearOff: installStaticTearOff,
    installInstanceTearOff: installInstanceTearOff,

        // Unintercepted methods.
    _instance_0u: mkInstance(0, 0, null, [#call0selector], 0),
    _instance_1u: mkInstance(0, 1, null, [#call1selector], 0),
    _instance_2u: mkInstance(0, 2, null, [#call2selector], 0),

        // Intercepted methods.
    _instance_0i: mkInstance(1, 0, null, [#call0selector], 0),
    _instance_1i: mkInstance(1, 1, null, [#call1selector], 0),
    _instance_2i: mkInstance(1, 2, null, [#call2selector], 0),

        // Static methods.
    _static_0: mkStatic(0, null, [#call0selector], 0),
    _static_1: mkStatic(1, null, [#call1selector], 0),
    _static_2: mkStatic(2, null, [#call2selector], 0),

    makeConstList: makeConstList,
    lazy: lazy,
    lazyFinal: lazyFinal,
    lazyOld: lazyOld,
    updateHolder: updateHolder,
    convertToFastObject: convertToFastObject,
    setFunctionNamesIfNecessary: setFunctionNamesIfNecessary,
    updateTypes: updateTypes,
    setOrUpdateInterceptorsByTag: setOrUpdateInterceptorsByTag,
    setOrUpdateLeafTags: setOrUpdateLeafTags,
  };
})();

// Every deferred hunk (i.e. fragment) is a function that we can invoke to
// initialize it. At this moment it contributes its data to the main hunk.
function initializeDeferredHunk(hunk) {
  // Update the typesOffset for the next deferred library.
  typesOffset = #embeddedTypes.length;

  // TODO(floitsch): extend natives.
  hunk(hunkHelpers, #embeddedGlobalsObject, holders, #staticState);
}

// Returns the global with the given [name].
function getGlobalFromName(name) {
  // TODO(floitsch): we are running through all holders. Since negative
  // lookups are expensive we might need to improve this.
  // Relies on the fact that all names are unique across all holders.
  for (var i = 0; i < holders.length; i++) {
    // The constant holder reuses the same names. Therefore we must skip it.
    if (holders[i] == #constantHolderReference) continue;
    // Relies on the fact that all variables are unique.
    if (holders[i][name]) return holders[i][name];
  }
}

if (#hasSoftDeferredClasses) {
  // Loads the soft-deferred classes and initializes them.
  // Updates the prototype of the given object.
  function softDef(o) {
    softDef = function(o) {};  // Replace ourselves.
    #deferredGlobal[#softId](
        holders, #embeddedGlobalsObject, #staticState,
        hunkHelpers);
    if (o != null) {
      // TODO(29574): should we do something different for Firefox?
      // If we recommend that the program triggers the load by itself before
      // classes are needed, then this line should rarely be hit.
      // Also, it is only hit at most once (per soft-deferred chunk).
      o.__proto__ = o.constructor.prototype;
    }
  }
}

if (#isTrackingAllocations) {
  var allocations = #deferredGlobal['allocations'] = {};
}

// Creates the holders.
#holders;

// If the name is not set on the functions, do it now.
hunkHelpers.setFunctionNamesIfNecessary(holders);

// TODO(floitsch): we should build this object as a literal.
var #staticStateDeclaration = {};

// Sets the prototypes of classes.
#prototypes;
// Sets aliases of methods (on the prototypes of classes).
#aliases;
// Installs the tear-offs of functions.
#tearOffs;
// Builds the inheritance structure.
#inheritance;

// Emits the embedded globals. This needs to be before constants so the embedded
// global type resources are available for generating constants.
#embeddedGlobalsPart1;

// Adds the subtype rules for the new RTI.
#typeRules;

// Adds the variance table for the new RTI.
#variances;

// Shared strings need to be initialized before constants.
#sharedStrings;

// Shared types need to be initialized before constants.
#sharedTypeRtis;

// Instantiates all constants.
#constants;

// Adds to the embedded globals. A few globals refer to constants.
#embeddedGlobalsPart2;

// Initializes the static non-final fields (with their constant values).
#staticNonFinalFields;
// Creates lazy getters for statics that must run initializers on first access.
#lazyStatics;

// Sets up the native support.
// Native-support uses setOrUpdateInterceptorsByTag and setOrUpdateLeafTags.
#nativeSupport;

// Sets up the js-interop support.
#jsInteropSupport;

// Ensure holders are in fast mode, now we have finished adding things.
convertAllToFastObject(holders);
convertToFastObject(#staticState);

// Invokes main (making sure that it records the 'current-script' value).
#invokeMain;
})()
''';

/// An expression that returns `true` if `__proto__` can be assigned to stitch
/// together a prototype chain, and the performance is good.
const String _directAccessTestExpression = r'''
  (function () {
    var cls = function () {};
    cls.prototype = {'p': {}};
    var object = new cls();
    if (!(object.__proto__ && object.__proto__.p === cls.prototype.p))
      return false;

    try {
      // Are we running on a platform where the performance is good?
      // (i.e. Chrome or d8).

      // Chrome userAgent?
      if (typeof navigator != "undefined" &&
          typeof navigator.userAgent == "string" &&
          navigator.userAgent.indexOf("Chrome/") >= 0) return true;
      // d8 version() looks like "N.N.N.N", jsshell version() like "N".
      if (typeof version == "function" &&
          version.length == 0) {
        var v = version();
        if (/^\d+\.\d+\.\d+\.\d+$/.test(v)) return true;
      }
    } catch(_) {}

    return false;
  })()
''';

/// Soft-deferred fragments are built similarly to the main fragment.

/// Deferred fragments (aka 'hunks') are built similarly to the main fragment.
///
/// However, at specific moments they need to contribute their data.
/// For example, once the holders have been created, they are included into
/// the main holders.
///
/// This template is used for Dart 2.
const String _deferredBoilerplate = '''
function(hunkHelpers, #embeddedGlobalsObject, holdersList, #staticState) {

// Builds the holders. They only contain the data for new holders.
#holders;

// If the name is not set on the functions, do it now.
hunkHelpers.setFunctionNamesIfNecessary(#deferredHoldersList);

// Updates the holders of the main-fragment. Uses the provided holdersList to
// access the main holders.
// The local holders are replaced by the combined holders. This is necessary
// for the inheritance setup below.
#updateHolders;
// Sets the prototypes of the new classes.
#prototypes;
// Add signature function types and compute the types offset in `init.types`.
// These can only refer to regular classes and in Dart 2 only closures have
// function types so the `typesOffset` has been safely computed before it's
// referred in the signatures of the `closures` below.
var #typesOffset = hunkHelpers.updateTypes(#types);
#closures;
// Sets aliases of methods (on the prototypes of classes).
#aliases;
// Installs the tear-offs of functions.
#tearOffs;
// Builds the inheritance structure.
#inheritance;

// Adds the subtype rules for the new RTI.
#typeRules;

// Adds the variance table for the new RTI.
#variances;

#sharedStrings;

#sharedTypeRtis;
// Instantiates all constants of this deferred fragment.
// Note that the constant-holder has been updated earlier and storing the
// constant values in the constant-holder makes them available globally.
#constants;
// Initializes the static non-final fields (with their constant values).
#staticNonFinalFields;
// Creates lazy getters for statics that must run initializers on first access.
#lazyStatics;

// Native-support uses setOrUpdateInterceptorsByTag and setOrUpdateLeafTags.
#nativeSupport;
}''';

///
/// However, they don't contribute anything to global namespace, but just
/// initialize existing classes. For example, they update the inheritance
/// hierarchy, and add methods the prototypes.
const String _softDeferredBoilerplate = '''
#deferredGlobal[#softId] =
  function(holdersList, #embeddedGlobalsObject, #staticState,
           hunkHelpers) {

// Installs the holders as local variables.
#installHoldersAsLocals;
// Sets the prototypes of the new classes.
#prototypes;
// Sets aliases of methods (on the prototypes of classes).
#aliases;
// Installs the tear-offs of functions.
#tearOffs;
// Builds the inheritance structure.
#inheritance;
}''';

/// This class builds a JavaScript tree for a given fragment.
///
/// A fragment is generally written into a separate file so that it can be
/// loaded dynamically when a deferred library is loaded.
///
/// This class is stateless and can be reused for different fragments.
class FragmentEmitter {
  final CompilerOptions _options;
  final DumpInfoTask _dumpInfoTask;
  final Namer _namer;
  final Emitter _emitter;
  final ConstantEmitter _constantEmitter;
  final ModelEmitter _modelEmitter;
  final NativeEmitter _nativeEmitter;
  final JClosedWorld _closedWorld;
  final CodegenWorld _codegenWorld;
  RecipeEncoder _recipeEncoder;
  RulesetEncoder _rulesetEncoder;

  ClassHierarchy get _classHierarchy => _closedWorld.classHierarchy;
  CommonElements get _commonElements => _closedWorld.commonElements;
  DartTypes get _dartTypes => _closedWorld.dartTypes;
  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;
  RuntimeTypesNeed get _rtiNeed => _closedWorld.rtiNeed;

  js.Name _call0Name, _call1Name, _call2Name;
  js.Name get call0Name =>
      _call0Name ??= _namer.getNameForJsGetName(null, JsGetName.CALL_PREFIX0);
  js.Name get call1Name =>
      _call1Name ??= _namer.getNameForJsGetName(null, JsGetName.CALL_PREFIX1);
  js.Name get call2Name =>
      _call2Name ??= _namer.getNameForJsGetName(null, JsGetName.CALL_PREFIX2);

  FragmentEmitter(
      this._options,
      this._dumpInfoTask,
      this._namer,
      this._emitter,
      this._constantEmitter,
      this._modelEmitter,
      this._nativeEmitter,
      this._closedWorld,
      this._codegenWorld) {
    _recipeEncoder = RecipeEncoderImpl(
        _closedWorld,
        _options.disableRtiOptimization
            ? TrivialRuntimeTypesSubstitutions(_closedWorld)
            : RuntimeTypesImpl(_closedWorld),
        _closedWorld.nativeData,
        _closedWorld.commonElements);
    _rulesetEncoder =
        RulesetEncoder(_closedWorld.dartTypes, _emitter, _recipeEncoder);
  }

  js.Expression generateEmbeddedGlobalAccess(String global) =>
      _emitter.generateEmbeddedGlobalAccess(global);

  js.Expression generateConstantReference(ConstantValue value) =>
      _modelEmitter.generateConstantReference(value);

  js.Expression classReference(Class cls) {
    return js.js('#.#', [cls.holder.name, cls.name]);
  }

  void registerEntityAst(Entity entity, js.Node code, {LibraryEntity library}) {
    _dumpInfoTask.registerEntityAst(entity, code);
    // TODO(sigmund): stop recoding associations twice, dump-info already
    // has library to element dependencies to recover this data.
    if (library != null) _dumpInfoTask.registerEntityAst(library, code);
  }

  PreFragment emitPreFragment(DeferredFragment fragment, bool estimateSize) {
    var classPrototypes = emitPrototypes(fragment, includeClosures: false);
    var closurePrototypes = emitPrototypes(fragment, includeClosures: true);
    var inheritance = emitInheritance(fragment);
    var methodAliases = emitInstanceMethodAliases(fragment);
    var tearOffs = emitInstallTearOffs(fragment);
    var constants = emitConstants(fragment);
    var typeRules = emitTypeRules(fragment);
    var variances = emitVariances(fragment);
    var staticNonFinalFields = emitStaticNonFinalFields(fragment);
    var lazyInitializers = emitLazilyInitializedStatics(fragment);
    // TODO(floitsch): only call emitNativeSupport if we need native.
    var nativeSupport = emitNativeSupport(fragment);
    return PreFragment(
        fragment,
        classPrototypes,
        closurePrototypes,
        inheritance,
        methodAliases,
        tearOffs,
        constants,
        typeRules,
        variances,
        staticNonFinalFields,
        lazyInitializers,
        nativeSupport,
        estimateSize);
  }

  js.Statement emitMainFragment(
      Program program, DeferredLoadingState deferredLoadingState) {
    MainFragment fragment = program.fragments.first;

    Iterable<Holder> nonStaticStateHolders =
        program.holders.where((Holder holder) => !holder.isStaticStateHolder);

    String softDeferredId = "softDeferred${new Random().nextInt(0x7FFFFFFF)}";

    HolderCode holderCode = emitHolders(program.holders, fragment.libraries,
        initializeEmptyHolders: true);

    js.Statement mainCode = js.js.statement(_mainBoilerplate, {
      // TODO(29455): 'hunkHelpers' displaces other names, so don't minify it.
      'hunkHelpers': js.VariableDeclaration('hunkHelpers', allowRename: false),
      'directAccessTestExpression': js.js(_directAccessTestExpression),
      'cyclicThrow': _emitter
          .staticFunctionAccess(_closedWorld.commonElements.cyclicThrowHelper),
      'throwLateInitializationError': _emitter.staticFunctionAccess(
          _closedWorld.commonElements.throwLateInitializationError),
      'operatorIsPrefix': js.string(_namer.fixedNames.operatorIsPrefix),
      'tearOffCode': new js.Block(buildTearOffCode(
          _options, _emitter, _namer, _closedWorld.commonElements)),
      'embeddedTypes': generateEmbeddedGlobalAccess(TYPES),
      'embeddedInterceptorTags':
          generateEmbeddedGlobalAccess(INTERCEPTORS_BY_TAG),
      'embeddedLeafTags': generateEmbeddedGlobalAccess(LEAF_TAGS),
      'embeddedGlobalsObject': js.js("init"),
      'staticStateDeclaration': new js.VariableDeclaration(
          _namer.staticStateHolder,
          allowRename: false),
      'staticState': js.js('#', _namer.staticStateHolder),
      'constantHolderReference': buildConstantHolderReference(program),
      'holders': holderCode.statements,
      'callName': js.string(_namer.fixedNames.callNameField),
      'stubName': js.string(_namer.stubNameField),
      'argumentCount': js.string(_namer.fixedNames.requiredParameterField),
      'defaultArgumentValues': js.string(_namer.fixedNames.defaultValuesField),
      'deferredGlobal': ModelEmitter.deferredInitializersGlobal,
      'hasSoftDeferredClasses': program.hasSoftDeferredClasses,
      'softId': js.string(softDeferredId),
      'isTrackingAllocations': _options.experimentalTrackAllocations,
      'prototypes': emitPrototypes(fragment),
      'inheritance': emitInheritance(fragment),
      'aliases': emitInstanceMethodAliases(fragment),
      'tearOffs': emitInstallTearOffs(fragment),
      'constants': emitConstants(fragment),
      'staticNonFinalFields': emitStaticNonFinalFields(fragment),
      'lazyStatics': emitLazilyInitializedStatics(fragment),
      'embeddedGlobalsPart1':
          emitEmbeddedGlobalsPart1(program, deferredLoadingState),
      'embeddedGlobalsPart2':
          emitEmbeddedGlobalsPart2(program, deferredLoadingState),
      'typeRules': emitTypeRules(fragment),
      'sharedStrings': StringReferenceResource(),
      'variances': emitVariances(fragment),
      'sharedTypeRtis': TypeReferenceResource(),
      'nativeSupport': emitNativeSupport(fragment),
      'jsInteropSupport': jsInteropAnalysis.buildJsInteropBootstrap(
              _codegenWorld, _closedWorld.nativeData, _namer) ??
          new js.EmptyStatement(),
      'invokeMain': fragment.invokeMain,

      'call0selector': js.quoteName(call0Name),
      'call1selector': js.quoteName(call1Name),
      'call2selector': js.quoteName(call2Name),
      'legacyJavaScript': _options.legacyJavaScript
    });
    if (program.hasSoftDeferredClasses) {
      mainCode = js.Block([
        js.js.statement(_softDeferredBoilerplate, {
          'deferredGlobal': ModelEmitter.deferredInitializersGlobal,
          'softId': js.string(softDeferredId),
          // TODO(floitsch): don't just reference 'init'.
          'embeddedGlobalsObject': new js.Parameter('init'),
          'staticState': new js.Parameter(_namer.staticStateHolder),
          'installHoldersAsLocals':
              emitInstallHoldersAsLocals(nonStaticStateHolders),
          'prototypes': emitPrototypes(fragment, softDeferred: true),
          'aliases': emitInstanceMethodAliases(fragment, softDeferred: true),
          'tearOffs': emitInstallTearOffs(fragment, softDeferred: true),
          'inheritance': emitInheritance(fragment, softDeferred: true),
        }),
        mainCode
      ]);
    }
    finalizeStringAndTypeReferences(mainCode);
    return mainCode;
  }

  js.Statement emitInstallHoldersAsLocals(Iterable<Holder> holders) {
    List<js.Statement> holderInits = [];
    int counter = 0;
    for (Holder holder in holders) {
      holderInits.add(new js.ExpressionStatement(new js.VariableInitialization(
          new js.VariableDeclaration(holder.name, allowRename: false),
          js.js("holdersList[#]", js.number(counter++)))));
    }
    return new js.Block(holderInits);
  }

  js.Expression emitDeferredFragment(
      FinalizedFragment fragment, List<Holder> holders) {
    HolderCode holderCode =
        emitHolders(holders, fragment.libraries, initializeEmptyHolders: false);

    List<Holder> nonStaticStateHolders = holders
        .where((Holder holder) => !holder.isStaticStateHolder)
        .toList(growable: false);

    List<js.Statement> updateHolderAssignments = [];
    for (int i = 0; i < nonStaticStateHolders.length; i++) {
      Holder holder = nonStaticStateHolders[i];
      if (holderCode.activeHolders.contains(holder)) {
        updateHolderAssignments.add(js.js.statement(
            '#holder = hunkHelpers.updateHolder(holdersList[#index], #holder)',
            {
              'index': js.number(i),
              'holder': new js.VariableUse(holder.name)
            }));
      } else {
        // TODO(sra): Change declaration followed by assignments to declarations
        // with initialization.
        updateHolderAssignments.add(js.js.statement(
            '#holder = holdersList[#index]', {
          'index': js.number(i),
          'holder': new js.VariableUse(holder.name)
        }));
      }
    }

    // TODO(sra): How do we tell if [deferredTypes] is empty? It is filled-in
    // later via the program finalizers. So we should defer the decision on the
    // emptiness of the fragment until the finalizers have run.  For now we seem
    // to get away with the fact that type indexes are either (1) main unit or
    // (2) local to the emitted unit, so there is no such thing as a type in a
    // deferred unit that is referenced from another deferred unit.  If we did
    // not emit any functions, then we probably did not use the signature types
    // in the OutputUnit's types, leaving them unused and tree-shaken.

    if (holderCode.activeHolders.isEmpty && fragment.isEmpty) {
      return null;
    }

    js.Expression code = js.js(_deferredBoilerplate, {
      // TODO(floitsch): don't just reference 'init'.
      'embeddedGlobalsObject': new js.Parameter('init'),
      'staticState': new js.Parameter(_namer.staticStateHolder),
      'holders': holderCode.statements,
      'deferredHoldersList': new js.ArrayInitializer(holderCode.activeHolders
          .map((holder) => js.js("#", holder.name))
          .toList(growable: false)),
      'updateHolders': new js.Block(updateHolderAssignments),
      'prototypes': fragment.classPrototypes,
      'closures': fragment.closurePrototypes,
      'inheritance': fragment.inheritance,
      'aliases': fragment.methodAliases,
      'tearOffs': fragment.tearOffs,
      'typeRules': fragment.typeRules,
      'variances': fragment.variances,
      'constants': fragment.constants,
      'staticNonFinalFields': fragment.staticNonFinalFields,
      'lazyStatics': fragment.lazyInitializers,
      'types': fragment.deferredTypes,
      'nativeSupport': fragment.nativeSupport,
      'typesOffset': _namer.typesOffsetName,
      'sharedStrings': StringReferenceResource(),
      'sharedTypeRtis': TypeReferenceResource(),
    });

    if (_options.experimentStartupFunctions) {
      code = js.Parentheses(code);
    }
    finalizeStringAndTypeReferences(code);
    return code;
  }

  void finalizeStringAndTypeReferences(js.Node code) {
    StringReferenceFinalizer stringFinalizer =
        StringReferenceFinalizerImpl(_options.enableMinification);
    stringFinalizer.addCode(code);
    stringFinalizer.finalize();
    TypeReferenceFinalizer finalizer = TypeReferenceFinalizerImpl(
        _emitter, _commonElements, _recipeEncoder, _options.enableMinification);
    finalizer.addCode(code);
    finalizer.finalize();
  }

  /// Emits all holders, except for the static-state holder.
  ///
  /// The emitted holders contain classes (only the constructors) and all
  /// static functions.
  HolderCode emitHolders(List<Holder> holders, List<Library> libraries,
      {bool initializeEmptyHolders}) {
    assert(initializeEmptyHolders != null);
    // Skip the static-state holder in this function.
    holders = holders
        .where((Holder holder) => !holder.isStaticStateHolder)
        .toList(growable: false);

    Map<Holder, List<js.Property>> holderCode = {};

    for (Holder holder in holders) {
      holderCode[holder] = <js.Property>[];
    }

    for (Library library in libraries) {
      for (StaticMethod method in library.statics) {
        assert(!method.holder.isStaticStateHolder);
        Map<js.Name, js.Expression> propertyMap = emitStaticMethod(method);
        propertyMap.forEach((js.Name key, js.Expression value) {
          var property = new js.Property(js.quoteName(key), value);
          holderCode[method.holder].add(property);
          registerEntityAst(method.element, property, library: library.element);
        });
      }
      for (Class cls in library.classes) {
        assert(!cls.holder.isStaticStateHolder);
        js.Expression constructor = emitConstructor(cls);
        var property = new js.Property(js.quoteName(cls.name), constructor);
        registerEntityAst(cls.element, property, library: library.element);
        holderCode[cls.holder].add(property);
      }
    }

    List<js.VariableInitialization> holderInitializations = [];
    List<Holder> activeHolders = [];

    for (Holder holder in holders) {
      List<js.Property> properties = holderCode[holder];
      if (properties.isEmpty) {
        holderInitializations.add(new js.VariableInitialization(
            new js.VariableDeclaration(holder.name, allowRename: false),
            initializeEmptyHolders
                ? new js.ObjectInitializer(properties)
                : null));
      } else {
        activeHolders.add(holder);
        holderInitializations.add(new js.VariableInitialization(
            new js.VariableDeclaration(holder.name, allowRename: false),
            new js.ObjectInitializer(properties)));
      }
    }

    // The generated code looks like this:
    //
    //    {
    //      var H = {...}, ..., G = {...};
    //      var holders = [ H, ..., G ]; // Main unit only.
    //    }

    List<js.Statement> statements = [];
    statements.add(new js.ExpressionStatement(new js.VariableDeclarationList(
        holderInitializations,
        indentSplits: false)));
    if (initializeEmptyHolders) {
      statements.add(js.js.statement(
          'var holders = #',
          new js.ArrayInitializer(holders
              .map((holder) => new js.VariableUse(holder.name))
              .toList(growable: false))));
    }
    return new HolderCode(
      activeHolders: activeHolders,
      statements: new js.Block(statements),
    );
  }

  /// Returns a reference to the constant holder, or the JS-literal `null`.
  js.Expression buildConstantHolderReference(Program program) {
    Holder constantHolder = program.holders.firstWhere(
        (Holder holder) => holder.isConstantsHolder,
        orElse: () => null);
    if (constantHolder == null) return new js.LiteralNull();
    return new js.VariableUse(constantHolder.name);
  }

  /// Emits the given [method].
  ///
  /// A Dart method might result in several JavaScript functions, if it
  /// requires stubs. The returned map contains the original method and all
  /// the stubs it needs.
  Map<js.Name, js.Expression> emitStaticMethod(StaticMethod method) {
    Map<js.Name, js.Expression> jsMethods = {};

    // We don't need to install stub-methods. They can only be used when there
    // are tear-offs, in which case they are emitted there.
    assert(() {
      if (method is StaticDartMethod) {
        return method.needsTearOff || method.parameterStubs.isEmpty;
      }
      return true;
    }());
    jsMethods[method.name] = method.code;

    return jsMethods;
  }

  /// Emits a constructor for the given class [cls].
  ///
  /// The constructor is statically built.
  js.Expression emitConstructor(Class cls) {
    js.Name name = cls.name;
    // If the class is not directly instantiated we only need it for inheritance
    // or RTI. In either case we don't need its fields.
    if (cls.isNative || !cls.isDirectlyInstantiated) {
      return js.js('function #() { }', name);
    }

    var statements = <js.Statement>[];
    var parameters = <js.Parameter>[];
    var thisRef;

    if (cls.isSoftDeferred) {
      statements.add(js.js.statement('softDef(this)'));
    } else if (_options.experimentalTrackAllocations) {
      String qualifiedName =
          "${cls.element.library.canonicalUri}:${cls.element.name}";
      statements.add(js.js.statement('allocations["$qualifiedName"] = true'));
    }

    List<Field> emittedFields = cls.fields.where((f) => !f.isElided).toList();

    // If there are many references to `this`, cache it in a local.
    if (emittedFields.length + (cls.hasRtiField ? 1 : 0) >= 4) {
      // Parameters are named t0, t1, etc, so '_' will not conflict. Forcing '_'
      // in minified mode works because no parameter or local also minifies to
      // '_' (the minifier doesn't know '_' is available).
      js.Name underscore = new StringBackedName('_');
      statements.add(js.js.statement('var # = this;', underscore));
      thisRef = underscore;
    } else {
      thisRef = js.js('this');
    }

    // Chain assignments of the same value, e.g. `this.b = this.a = null`.
    // Limit chain length so that the JavaScript parser has bounded recursion.
    const int maxChainLength = 30;
    js.Expression assignment = null;
    int chainLength = 0;
    ConstantValue previousConstant = null;
    void flushAssignment() {
      if (assignment != null) {
        statements.add(js.js.statement('#;', assignment));
        assignment = null;
        chainLength = 0;
        previousConstant = null;
      }
    }

    for (Field field in emittedFields) {
      ConstantValue constant = field.initializerInAllocator;
      if (constant != null) {
        if (constant == previousConstant && chainLength < maxChainLength) {
          assignment = js.js('#.# = #', [thisRef, field.name, assignment]);
        } else {
          flushAssignment();
          assignment = js.js('#.# = #', [
            thisRef,
            field.name,
            _constantEmitter.generate(constant),
          ]);
        }
        ++chainLength;
        previousConstant = constant;
      } else {
        flushAssignment();
        js.Parameter parameter = new js.Parameter('t${parameters.length}');
        parameters.add(parameter);
        statements.add(
            js.js.statement('#.# = #', [thisRef, field.name, parameter.name]));
      }
    }
    flushAssignment();

    if (cls.hasRtiField) {
      js.Parameter parameter = new js.Parameter('t${parameters.length}');
      parameters.add(parameter);
      statements.add(js.js.statement(
          '#.# = #', [thisRef, _namer.rtiFieldJsName, parameter.name]));
    }

    return js.js('function #(#) { # }', [name, parameters, statements]);
  }

  /// Emits the prototype-section of the fragment.
  ///
  /// This section updates the prototype-property of all constructors in the
  /// global holders.
  ///
  /// [softDeferred] determine whether prototypes for soft deferred classes are
  /// generated.
  ///
  /// If [includeClosures] is `true` only prototypes for closure classes are
  /// generated, if [includeClosures] is `false` only prototypes for non-closure
  /// classes are generated. Otherwise prototypes for all classes are generated.
  js.Statement emitPrototypes(Fragment fragment,
      {bool softDeferred = false, bool includeClosures}) {
    List<js.Statement> assignments = fragment.libraries
        .expand((Library library) => library.classes)
        .where((Class cls) {
      if (includeClosures != null) {
        if (cls.element.isClosure != includeClosures) {
          return false;
        }
      }
      return cls.isSoftDeferred == softDeferred;
    }).map((Class cls) {
      var proto = js.js.statement(
          '#.prototype = #;', [classReference(cls), emitPrototype(cls)]);
      ClassEntity element = cls.element;
      registerEntityAst(element, proto, library: element.library);
      return proto;
    }).toList(growable: false);

    return new js.Block(assignments);
  }

  /// Emits the prototype of the given class [cls].
  ///
  /// The prototype is generated as object literal. Inheritance is ignored.
  ///
  /// The prototype also includes the `is-property` that every class must have.
  // TODO(floitsch): we could avoid that property if we knew that it wasn't
  //    needed.
  js.Expression emitPrototype(Class cls) {
    Iterable<Method> methods = cls.methods;
    Iterable<Method> checkedSetters = cls.checkedSetters;
    Iterable<Method> isChecks = cls.isChecks;
    Iterable<Method> callStubs = cls.callStubs;
    Iterable<Method> noSuchMethodStubs = cls.noSuchMethodStubs;
    Iterable<Method> gettersSetters = generateGettersSetters(cls);
    Iterable<Method> allMethods = [
      methods,
      checkedSetters,
      isChecks,
      callStubs,
      noSuchMethodStubs,
      gettersSetters
    ].expand((x) => x);

    List<js.Property> properties = [];

    if (cls.superclass == null) {
      // ie11 might require us to set 'constructor' but we aren't 100% sure.
      if (_options.legacyJavaScript) {
        properties
            .add(js.Property(js.string("constructor"), classReference(cls)));
      }

      properties.add(js.Property(_namer.operatorIs(cls.element), js.number(1)));
    }

    allMethods.forEach((Method method) {
      emitInstanceMethod(method)
          .forEach((js.Expression name, js.Expression code) {
        var prop = js.Property(name, code);
        registerEntityAst(method.element, prop);
        properties.add(prop);
      });
    });

    if (cls.isClosureBaseClass) {
      // Closures extend a common base class, so we can put properties on the
      // prototype for common values.

      // Closures taking exactly one argument are common.
      properties.add(js.Property(js.string(_namer.fixedNames.callCatchAllName),
          js.quoteName(call1Name)));
      properties.add(js.Property(
          js.string(_namer.fixedNames.requiredParameterField), js.number(1)));

      // Most closures have no optional arguments.
      properties.add(js.Property(
          js.string(_namer.fixedNames.defaultValuesField),
          new js.LiteralNull()));
    }

    return new js.ObjectInitializer(properties);
  }

  /// Generates a getter for the given [field].
  Method generateGetter(Field field) {
    assert(field.needsGetter);

    js.Expression code;
    if (field.isElided) {
      ConstantValue constantValue = field.constantValue;
      assert(
          constantValue != null, "No constant value for elided field: $field");
      if (constantValue == null) {
        // This should never occur because codegen member usage is now limited
        // by closed world member usage. In the case we've missed a spot we
        // cautiously generate a null constant.
        constantValue = new NullConstantValue();
      }
      code = js.js(
          "function() { return #; }", generateConstantReference(constantValue));
    } else {
      String template;
      if (field.needsInterceptedGetterOnReceiver) {
        template = "function(receiver) { return receiver[#]; }";
      } else if (field.needsInterceptedGetterOnThis) {
        template = "function(receiver) { return this[#]; }";
      } else {
        assert(!field.needsInterceptedGetter);
        template = "function() { return this[#]; }";
      }
      js.Expression fieldName = js.quoteName(field.name);
      code = js.js(template, fieldName);
    }
    js.Name getterName = _namer.deriveGetterName(field.accessorName);
    return new StubMethod(getterName, code);
  }

  /// Generates a setter for the given [field].
  Method generateSetter(Field field) {
    assert(field.needsUncheckedSetter);

    String template;
    js.Expression code;
    if (field.isElided) {
      code = js.js("function() { }");
    } else {
      if (field.needsInterceptedSetterOnReceiver) {
        template = "function(receiver, val) { return receiver[#] = val; }";
      } else if (field.needsInterceptedSetterOnThis) {
        template = "function(receiver, val) { return this[#] = val; }";
      } else {
        assert(!field.needsInterceptedSetter);
        template = "function(val) { return this[#] = val; }";
      }
      js.Expression fieldName = js.quoteName(field.name);
      code = js.js(template, fieldName);
    }

    js.Name setterName = _namer.deriveSetterName(field.accessorName);
    return new StubMethod(setterName, code);
  }

  /// Generates all getters and setters the given class [cls] needs.
  Iterable<Method> generateGettersSetters(Class cls) {
    Iterable<Method> getters = cls.fields
        .where((Field field) => field.needsGetter)
        .map(generateGetter);

    Iterable<Method> setters = cls.fields
        .where((Field field) => field.needsUncheckedSetter)
        .map(generateSetter);

    return [getters, setters].expand((x) => x);
  }

  /// Emits the given instance [method].
  ///
  /// The given method may be a stub-method (for example for is-checks).
  ///
  /// If it is a Dart-method, all necessary stub-methods are emitted, too. In
  /// that case the returned map contains more than just one entry.
  ///
  /// If the method is a closure call-method, also returns the necessary
  /// properties in case the closure can be applied.
  Map<js.Expression, js.Expression> emitInstanceMethod(Method method) {
    var properties = <js.Expression, js.Expression>{};

    properties[method.name] = method.code;
    if (method is InstanceMethod) {
      for (ParameterStubMethod stubMethod in method.parameterStubs) {
        properties[stubMethod.name] = stubMethod.code;
      }

      if (method.isClosureCallMethod && method.canBeApplied) {
        // TODO(sra): We should also add these properties for the user-defined
        // `call` method on classes. Function.apply is currently broken for
        // complex cases. [forceAdd] might be true when this is fixed.
        bool forceAdd = !method.isClosureCallMethod;

        // Common case of "call*": "call$1" is stored on the Closure class.
        if (method.applyIndex != 0 ||
            method.parameterStubs.isNotEmpty ||
            method.requiredParameterCount != 1 ||
            forceAdd) {
          js.Name applyName = method.applyIndex == 0
              ? method.name
              : method.parameterStubs[method.applyIndex - 1].name;
          properties[js.string(_namer.fixedNames.callCatchAllName)] =
              js.quoteName(applyName);
        }
        // Common case of '1' is stored on the Closure class.
        if (method.requiredParameterCount != 1 || forceAdd) {
          properties[js.string(_namer.fixedNames.requiredParameterField)] =
              js.number(method.requiredParameterCount);
        }

        js.Expression defaultValues =
            _encodeOptionalParameterDefaultValues(method);
        // Default values property of `null` is stored on the common JS
        // superclass.
        if (defaultValues is! js.LiteralNull || forceAdd) {
          properties[js.string(_namer.fixedNames.defaultValuesField)] =
              defaultValues;
        }
      }
    }

    return properties;
  }

  /// Emits the inheritance block of the fragment.
  ///
  /// In this section prototype chains are updated and mixin functions are
  /// copied.
  js.Statement emitInheritance(Fragment fragment, {bool softDeferred = false}) {
    List<js.Statement> inheritCalls = [];
    List<js.Statement> mixinCalls = [];
    // local caches of functions to allow minifaction of function name in call.
    LocalAliases locals = LocalAliases();

    Set<Class> classesInFragment = Set();
    for (Library library in fragment.libraries) {
      classesInFragment.addAll(library.classes
          .where(((Class cls) => cls.isSoftDeferred == softDeferred)));
    }

    Map<Class, List<Class>> subclasses = {};
    Set<Class> seen = Set();

    void collect(cls) {
      if (cls == null || seen.contains(cls)) return;

      Class superclass = cls.superclass;
      if (classesInFragment.contains(superclass)) {
        collect(superclass);
      }

      subclasses.putIfAbsent(superclass, () => <Class>[]).add(cls);

      seen.add(cls);
    }

    for (Library library in fragment.libraries) {
      for (Class cls in library.classes) {
        if (cls.isSoftDeferred != softDeferred) continue;
        collect(cls);
        if (cls.mixinClass != null) {
          js.Statement statement = js.js.statement('#(#, #)', [
            locals.find('_mixin', 'hunkHelpers.mixin'),
            classReference(cls),
            classReference(cls.mixinClass),
          ]);
          registerEntityAst(cls.element, statement, library: library.element);
          mixinCalls.add(statement);
        }
      }
    }

    for (Class superclass in subclasses.keys) {
      List<Class> list = subclasses[superclass];
      js.Expression superclassReference = (superclass == null)
          ? new js.LiteralNull()
          : classReference(superclass);
      if (list.length == 1) {
        Class cls = list.single;
        var statement = js.js.statement('#(#, #)', [
          locals.find('_inherit', 'hunkHelpers.inherit'),
          classReference(cls),
          superclassReference
        ]);
        registerEntityAst(cls.element, statement, library: cls.element.library);
        inheritCalls.add(statement);
      } else {
        List<js.Expression> listElements = [];
        // Since inheritMany shares the superclass reference, we attribute it
        // only to the first subclass.
        ClassEntity firstClass = list.first.element;
        registerEntityAst(firstClass, superclassReference,
            library: firstClass.library);
        for (Class cls in list) {
          js.Expression reference = classReference(cls);
          registerEntityAst(cls.element, reference,
              library: cls.element.library);
          listElements.add(reference);
        }
        inheritCalls.add(js.js.statement('#(#, #)', [
          locals.find('_inheritMany', 'hunkHelpers.inheritMany'),
          superclassReference,
          js.ArrayInitializer(listElements)
        ]));
      }
    }

    List<js.Statement> statements = [];
    if (locals.isNotEmpty) {
      statements.add(locals.toStatement());
    }
    statements.addAll(inheritCalls);
    statements.addAll(mixinCalls);
    return wrapPhase('inheritance', statements);
  }

  /// Emits the setup of method aliases.
  ///
  /// This step consists of simply copying JavaScript functions to their
  /// aliased names so they point to the same function.
  js.Statement emitInstanceMethodAliases(Fragment fragment,
      {bool softDeferred = false}) {
    List<js.Statement> assignments = [];

    for (Library library in fragment.libraries) {
      for (Class cls in library.classes) {
        if (cls.isSoftDeferred != softDeferred) continue;
        bool firstAlias = true;
        for (InstanceMethod method in cls.methods) {
          if (method.aliasName != null) {
            if (firstAlias) {
              firstAlias = false;
              js.Statement statement = js.js.statement(
                  assignments.isEmpty
                      ? 'var _ = #.prototype;'
                      : '_ = #.prototype',
                  classReference(cls));
              registerEntityAst(method.element, statement);
              assignments.add(statement);
            }
            js.Statement statement = js.js.statement('_.# = _.#',
                [js.quoteName(method.aliasName), js.quoteName(method.name)]);
            registerEntityAst(method.element, statement);
            assignments.add(statement);
          }
        }
      }
    }
    return wrapPhase('aliases', assignments);
  }

  /// Encodes the optional default values so that the runtime Function.apply
  /// can use them.
  js.Expression _encodeOptionalParameterDefaultValues(DartMethod method) {
    // TODO(herhut): Replace [js.LiteralNull] with [js.ArrayHole].
    if (method.optionalParameterDefaultValues is List) {
      List<ConstantValue> defaultValues = method.optionalParameterDefaultValues;
      if (defaultValues.isEmpty) {
        return new js.LiteralNull();
      }
      Iterable<js.Expression> elements =
          defaultValues.map(generateConstantReference);
      return js.js('function() { return #; }',
          new js.ArrayInitializer(elements.toList()));
    } else {
      Map<String, ConstantValue> defaultValues =
          method.optionalParameterDefaultValues;
      List<js.Property> properties = [];
      List<String> names = defaultValues.keys.toList(growable: false);
      // Sort the names the same way we sort them for the named-argument calling
      // convention.
      names.sort();

      for (String name in names) {
        ConstantValue value = defaultValues[name];
        properties.add(
            new js.Property(js.string(name), generateConstantReference(value)));
      }
      return js.js(
          'function() { return #; }', new js.ObjectInitializer(properties));
    }
  }

  /// Wraps the statement in a named function to that it shows up as a unit in
  /// profiles.
  // TODO(sra): Should this be conditional?
  js.Statement wrapPhase(String name, List<js.Statement> statements) {
    js.Block block = new js.Block(statements);
    if (statements.isEmpty) return block;
    return js.js.statement('(function #(){#})();', [name, block]);
  }

  /// Emits the section that installs tear-off getters.
  js.Statement emitInstallTearOffs(Fragment fragment,
      {bool softDeferred = false}) {
    LocalAliases locals = LocalAliases();

    /// Emits the statement that installs a tear off for a method.
    ///
    /// Tear-offs might be passed to `Function.apply` which means that all
    /// calling-conventions (with or without optional positional/named
    /// arguments) are possible. As such, the tear-off needs enough information
    /// to fill in missing parameters.
    js.Statement emitInstallTearOff(
        js.Expression container, DartMethod method) {
      List<js.Name> callNames = [];
      List<js.Expression> funsOrNames = [];

      /// Adds the stub-method's code or name to the [funsOrNames] array.
      ///
      /// Static methods don't need stub-methods except for tear-offs. As such,
      /// they are not emitted in the prototype, but directly passed here.
      ///
      /// Instance-methods install the stub-methods in their prototype, and we
      /// use string-based redirections to find them there.
      void addFunOrName(StubMethod stubMethod) {
        if (method.isStatic) {
          funsOrNames.add(stubMethod.code);
        } else {
          funsOrNames.add(js.quoteName(stubMethod.name));
        }
      }

      callNames.add(method.callName);
      // The first entry in the funsOrNames-array must be a string.
      funsOrNames.add(js.quoteName(method.name));
      for (ParameterStubMethod stubMethod in method.parameterStubs) {
        callNames.add(stubMethod.callName);
        addFunOrName(stubMethod);
      }

      js.ArrayInitializer callNameArray =
          new js.ArrayInitializer(callNames.map(js.quoteName).toList());
      js.ArrayInitializer funsOrNamesArray =
          new js.ArrayInitializer(funsOrNames);

      bool isIntercepted = false;
      if (method is InstanceMethod) {
        isIntercepted = method.isIntercepted;
      }

      int requiredParameterCount = method.requiredParameterCount;
      js.Expression optionalParameterDefaultValues = new js.LiteralNull();
      if (method.canBeApplied) {
        optionalParameterDefaultValues =
            _encodeOptionalParameterDefaultValues(method);
      }

      var applyIndex = js.number(method.applyIndex);

      if (method.isStatic) {
        if (requiredParameterCount <= 2 &&
            callNames.length == 1 &&
            optionalParameterDefaultValues is js.LiteralNull &&
            method.applyIndex == 0) {
          js.Statement finish(int arity) {
            // Short form for exactly 0/1/2 arguments.
            var install =
                locals.find('_static_${arity}', 'hunkHelpers._static_${arity}');
            return js.js.statement('''
                #install(#container, #getterName, #name, #funType)''', {
              "install": install,
              "container": container,
              "getterName": js.quoteName(method.tearOffName),
              "name": funsOrNames.single,
              "funType": method.functionType,
            });
          }

          var installedName = callNames.single;
          if (installedName == call0Name) return finish(0);
          if (installedName == call1Name) return finish(1);
          if (installedName == call2Name) return finish(2);
        }

        var install =
            locals.find('_static', 'hunkHelpers.installStaticTearOff');
        return js.js.statement('''
            #install(#container, #getterName,
                     #requiredParameterCount, #optionalParameterDefaultValues,
                      #callNames, #funsOrNames, #funType, #applyIndex)''', {
          "install": install,
          "container": container,
          "getterName": js.quoteName(method.tearOffName),
          "requiredParameterCount": js.number(requiredParameterCount),
          "optionalParameterDefaultValues": optionalParameterDefaultValues,
          "callNames": callNameArray,
          "funsOrNames": funsOrNamesArray,
          "funType": method.functionType,
          "applyIndex": applyIndex,
        });
      } else {
        if (requiredParameterCount <= 2 &&
            callNames.length == 1 &&
            optionalParameterDefaultValues is js.LiteralNull &&
            method.applyIndex == 0) {
          js.Statement finish(int arity) {
            // Short form for exactly 0/1/2 arguments.
            String isInterceptedTag = isIntercepted ? 'i' : 'u';
            var install = locals.find('_instance_${arity}_${isInterceptedTag}',
                'hunkHelpers._instance_${arity}${isInterceptedTag}');
            return js.js.statement('''
                #install(#container, #getterName, #name, #funType)''', {
              "install": install,
              "container": container,
              "getterName": js.quoteName(method.tearOffName),
              "name": funsOrNames.single,
              "funType": method.functionType,
            });
          }

          var installedName = callNames.single;
          if (installedName == call0Name) return finish(0);
          if (installedName == call1Name) return finish(1);
          if (installedName == call2Name) return finish(2);
        }

        var install =
            locals.find('_instance', 'hunkHelpers.installInstanceTearOff');
        return js.js.statement('''
            #install(#container, #getterName, #isIntercepted,
                     #requiredParameterCount, #optionalParameterDefaultValues,
                     #callNames, #funsOrNames, #funType, #applyIndex)''', {
          "install": install,
          "container": container,
          "getterName": js.quoteName(method.tearOffName),
          // 'Truthy' values are ok for `isIntercepted`.
          "isIntercepted": js.number(isIntercepted ? 1 : 0),
          "requiredParameterCount": js.number(requiredParameterCount),
          "optionalParameterDefaultValues": optionalParameterDefaultValues,
          "callNames": callNameArray,
          "funsOrNames": funsOrNamesArray,
          "funType": method.functionType,
          "applyIndex": applyIndex,
        });
      }
    }

    List<js.Statement> inits = [];
    js.Expression temp;

    for (Library library in fragment.libraries) {
      for (StaticMethod method in library.statics) {
        // TODO(floitsch): can there be anything else than a StaticDartMethod?
        if (method is StaticDartMethod) {
          if (method.needsTearOff) {
            Holder holder = method.holder;
            js.Statement statement =
                emitInstallTearOff(new js.VariableUse(holder.name), method);
            registerEntityAst(method.element, statement,
                library: library.element);
            inits.add(statement);
          }
        }
      }
      for (Class cls in library.classes) {
        if (cls.isSoftDeferred != softDeferred) continue;
        var methods = cls.methods.where((dynamic m) => m.needsTearOff).toList();
        js.Expression container = js.js("#.prototype", classReference(cls));
        js.Expression reference = container;
        if (methods.length > 1) {
          if (temp == null) {
            inits.add(js.js.statement('var _;'));
            temp = js.js('_');
          }
          // First call uses assignment to temp to cache the container.
          reference = js.js('# = #', [temp, container]);
        }
        for (InstanceMethod method in methods) {
          js.Statement statement = emitInstallTearOff(reference, method);
          registerEntityAst(method.element, statement);
          inits.add(statement);
          reference = temp; // Second and subsequent calls use temp.
        }
      }
    }

    if (locals.isNotEmpty) {
      inits.insert(0, locals.toStatement());
    }

    return wrapPhase('installTearOffs', inits);
  }

  /// Emits the constants section.
  js.Statement emitConstants(Fragment fragment) {
    List<js.Statement> assignments = [];
    bool hasList = false;
    for (Constant constant in fragment.constants) {
      // TODO(25230): We only need to name constants that are used from function
      // bodies or from other constants in a different part.
      var assignment = js.js.statement('#.# = #', [
        constant.holder.name,
        constant.name,
        _constantEmitter.generate(constant.value)
      ]);
      _dumpInfoTask.registerConstantAst(constant.value, assignment);
      assignments.add(assignment);
      if (constant.value.isList) hasList = true;
    }
    if (hasList) {
      assignments.insert(
          0, js.js.statement('var makeConstList = hunkHelpers.makeConstList;'));
    }
    return wrapPhase('constants', assignments);
  }

  /// Emits the static non-final fields section.
  ///
  /// This section initializes all static non-final fields that don't require
  /// an initializer.
  js.Statement emitStaticNonFinalFields(Fragment fragment) {
    List<StaticField> fields = fragment.staticNonFinalFields;
    // TODO(sra): Chain assignments that have the same value, i.e.
    //
    //    $.x = null; $.y = null; $.z = null;
    // -->
    //    $.z = $.y = $.x = null;
    //
    Iterable<js.Statement> statements = fields.map((StaticField field) {
      assert(field.holder.isStaticStateHolder);
      js.Statement statement;
      if (field.isInitializedByConstant) {
        statement = js.js
            .statement("#.# = #;", [field.holder.name, field.name, field.code]);
      } else {
        // This is a bit of a hack. Field initializers are generated as a
        // function ending with a return statement. We replace the function
        // with the body block and replace the return statement with an
        // assignment to the field.
        //
        // Since unneeded blocks are not generated in the output,
        // the statement(s) of the initializes are inlined in the emitted code.
        //
        // This is a cheap way of supporting eager fields (as opposed to
        // generating one SSA graph for all eager fields) though it does not
        // avoid redundant declaration of local variable, for instance for
        // type arguments.
        js.Fun code = field.code;
        assert(code != null, "No code for $field");
        if (code.params.isEmpty &&
            code.body.statements.length == 1 &&
            code.body.statements.last is js.Return) {
          // For now we only support initializers of the form
          //
          //   function() { return e; }
          //
          // To avoid unforeseen consequences of having parameters and locals
          // in the initializer code.
          js.Return last = code.body.statements.last;
          statement = js.js.statement(
              "#.# = #;", [field.holder.name, field.name, last.value]);
        } else {
          // Safe fallback in the event of a field initializer with no return
          // statement as the last statement.
          statement = js.js
              .statement("#.# = #();", [field.holder.name, field.name, code]);
        }
      }
      registerEntityAst(field.element, statement,
          library: field.element.library);
      return statement;
    });
    return wrapPhase('staticFields', statements.toList());
  }

  /// Emits lazy fields.
  ///
  /// This section initializes all static (final and non-final) fields that
  /// require an initializer.
  js.Statement emitLazilyInitializedStatics(Fragment fragment) {
    List<StaticField> fields = fragment.staticLazilyInitializedFields;
    List<js.Statement> statements = [];
    LocalAliases locals = LocalAliases();
    for (StaticField field in fields) {
      assert(field.holder.isStaticStateHolder);
      String helper = field.usesNonNullableInitialization
          ? field.isFinal
              ? locals.find('_lazyFinal', 'hunkHelpers.lazyFinal')
              : locals.find('_lazy', 'hunkHelpers.lazy')
          : locals.find('_lazyOld', 'hunkHelpers.lazyOld');
      js.Statement statement = js.js.statement("#(#, #, #, #);", [
        helper,
        field.holder.name,
        js.quoteName(field.name),
        js.quoteName(field.getterName),
        field.code,
      ]);

      registerEntityAst(field.element, statement,
          library: field.element.library);
      statements.add(statement);
    }

    if (locals.isNotEmpty) {
      statements.insert(0, locals.toStatement());
    }

    return wrapPhase('lazyInitializers', statements);
  }

  /// Emits the embedded globals that are needed for deferred loading.
  ///
  /// This function is only invoked for the main fragment.
  ///
  /// The [loadMap] contains a map from load-ids (for each deferred library)
  /// to the list of generated fragments that must be installed when the
  /// deferred library is loaded.
  Iterable<js.Property> emitEmbeddedGlobalsForDeferredLoading(
      DeferredLoadingState deferredLoadingState) {
    List<js.Property> globals = [];

    globals.add(new js.Property(
        js.string(DEFERRED_INITIALIZED), js.js("Object.create(null)")));

    String deferredGlobal = ModelEmitter.deferredInitializersGlobal;
    js.Expression isHunkLoadedFunction =
        js.js("function(hash) { return !!$deferredGlobal[hash]; }");
    globals
        .add(new js.Property(js.string(IS_HUNK_LOADED), isHunkLoadedFunction));

    js.Expression isHunkInitializedFunction = js.js(
        "function(hash) { return !!#deferredInitialized[hash]; }", {
      'deferredInitialized': generateEmbeddedGlobalAccess(DEFERRED_INITIALIZED)
    });
    globals.add(new js.Property(
        js.string(IS_HUNK_INITIALIZED), isHunkInitializedFunction));

    /// See [finalizeDeferredLoadingData] for the format of the deferred hunk.
    js.Expression initializeLoadedHunkFunction = js.js("""
            function(hash) {
              var hunk = $deferredGlobal[hash];
              if (hunk == null) {
                throw "DeferredLoading state error: code with hash '" +
                    hash + "' was not loaded";
              }
              initializeDeferredHunk(hunk);
              #deferredInitialized[hash] = true;
            }""", {
      'deferredInitialized': generateEmbeddedGlobalAccess(DEFERRED_INITIALIZED)
    });

    globals.add(new js.Property(
        js.string(INITIALIZE_LOADED_HUNK), initializeLoadedHunkFunction));

    globals.add(new js.Property(js.string(DEFERRED_LIBRARY_PARTS),
        deferredLoadingState.deferredLibraryParts));
    globals.add(new js.Property(
        js.string(DEFERRED_PART_URIS), deferredLoadingState.deferredPartUris));
    globals.add(new js.Property(js.string(DEFERRED_PART_HASHES),
        deferredLoadingState.deferredPartHashes));

    return globals;
  }

  // Create data used for loading and initializing the hunks for a deferred
  // import. There are three parts: a map from loadId to list of parts, where
  // parts are represented as an index; an array of uris indexed by part; and an
  // array of hashes indexed by part.
  // [deferredLoadHashes] may have missing entries to indicate empty parts.
  void finalizeDeferredLoadingData(
      Map<String, List<FinalizedFragment>> loadMap,
      Map<FinalizedFragment, String> deferredLoadHashes,
      DeferredLoadingState deferredLoadingState) {
    if (loadMap.isEmpty) return;

    Map<FinalizedFragment, int> fragmentIndexes = {};
    List<String> fragmentUris = [];
    List<String> fragmentHashes = [];

    List<js.Property> libraryPartsMapEntries = [];

    loadMap.forEach((String loadId, List<FinalizedFragment> fragmentList) {
      List<js.Expression> indexes = [];
      for (FinalizedFragment fragment in fragmentList) {
        String fragmentHash = deferredLoadHashes[fragment];
        if (fragmentHash == null) continue;
        int index = fragmentIndexes[fragment];
        if (index == null) {
          index = fragmentIndexes[fragment] = fragmentIndexes.length;
          fragmentUris.add(
              "${fragment.outputFileName}.${ModelEmitter.deferredExtension}");
          fragmentHashes.add(fragmentHash);
        }
        indexes.add(js.number(index));
      }
      libraryPartsMapEntries
          .add(js.Property(js.string(loadId), js.ArrayInitializer(indexes)));
    });

    deferredLoadingState.deferredLibraryParts.setValue(
        js.ObjectInitializer(libraryPartsMapEntries, isOneLiner: false));
    deferredLoadingState.deferredPartUris
        .setValue(js.stringArray(fragmentUris));
    deferredLoadingState.deferredPartHashes
        .setValue(js.stringArray(fragmentHashes));
  }

  /// Emits the [MANGLED_GLOBAL_NAMES] embedded global.
  ///
  /// This global maps minified names for selected classes (some important
  /// core classes, and some native classes) to their unminified names.
  js.Property emitMangledGlobalNames() {
    List<js.Property> names = [];

    CommonElements commonElements = _closedWorld.commonElements;
    // We want to keep the original names for the most common core classes when
    // calling toString on them.
    List<ClassEntity> nativeClassesNeedingUnmangledName = [
      commonElements.intClass,
      commonElements.doubleClass,
      commonElements.numClass,
      commonElements.stringClass,
      commonElements.boolClass,
      commonElements.nullClass,
      commonElements.listClass
    ];
    // TODO(floitsch): this should probably be on a per-fragment basis.
    nativeClassesNeedingUnmangledName.forEach((element) {
      names.add(new js.Property(
          js.quoteName(_namer.className(element)), js.string(element.name)));
    });

    return new js.Property(
        js.string(MANGLED_GLOBAL_NAMES), new js.ObjectInitializer(names));
  }

  /// Emits the [GET_TYPE_FROM_NAME] embedded global.
  ///
  /// This embedded global provides a way to go from a class name (which is
  /// also the constructor's name) to the constructor itself.
  js.Property emitGetTypeFromName() {
    js.Expression function = js.js("getGlobalFromName");
    return new js.Property(js.string(GET_TYPE_FROM_NAME), function);
  }

  /// Emits the [METADATA] embedded global.
  ///
  /// The metadata itself has already been computed earlier and is stored in
  /// the [program].
  List<js.Property> emitMetadata(Program program) {
    List<js.Property> metadataGlobals = [];

    js.Property createGlobal(js.Expression metadata, String global) {
      return new js.Property(js.string(global), metadata);
    }

    var mainUnit = program.mainFragment.outputUnit;
    js.Expression metadata = program.metadataForOutputUnit(mainUnit);
    metadataGlobals.add(createGlobal(metadata, METADATA));
    js.Expression types = program.metadataTypesForOutputUnit(mainUnit);
    metadataGlobals.add(createGlobal(types, TYPES));

    return metadataGlobals;
  }

  /// Emits all embedded globals.
  js.Statement emitEmbeddedGlobalsPart1(
      Program program, DeferredLoadingState deferredLoadingState) {
    List<js.Property> globals = [];

    if (program.loadMap.isNotEmpty) {
      globals
          .addAll(emitEmbeddedGlobalsForDeferredLoading(deferredLoadingState));
    }

    if (program.typeToInterceptorMap != null) {
      // This property is assigned later.
      // Initialize property to avoid map transitions.
      globals.add(
          js.Property(js.string(TYPE_TO_INTERCEPTOR_MAP), js.LiteralNull()));
    }

    globals.add(js.Property(js.string(RTI_UNIVERSE), createRtiUniverse()));

    globals.add(emitMangledGlobalNames());

    // The [MANGLED_NAMES] table must contain the mapping for const symbols.
    // Without const symbols, the table is only relevant for reflection and
    // therefore unused in this emitter.
    // TODO(johnniwinther): Remove the need for adding an empty list of
    // mangled names.
    globals.add(js.Property(
        js.string(MANGLED_NAMES), js.ObjectInitializer(<js.Property>[])));

    globals.add(emitGetTypeFromName());

    globals.addAll(emitMetadata(program));

    if (program.needsNativeSupport) {
      globals
          .add(js.Property(js.string(INTERCEPTORS_BY_TAG), js.LiteralNull()));
      globals.add(js.Property(js.string(LEAF_TAGS), js.LiteralNull()));
    }

    globals.add(js.Property(
        js.string(ARRAY_RTI_PROPERTY),
        _options.legacyJavaScript
            ? js.js(
                r'typeof Symbol == "function" && typeof Symbol() == "symbol"'
                r'    ? Symbol("$ti")'
                r'    : "$ti"')
            : js.js(r'Symbol("$ti")')));

    js.ObjectInitializer globalsObject =
        js.ObjectInitializer(globals, isOneLiner: false);

    return js.js.statement('var init = #;', globalsObject);
  }

  /// Finish setting up embedded globals.
  js.Statement emitEmbeddedGlobalsPart2(
      Program program, DeferredLoadingState deferredLoadingState) {
    List<js.Statement> statements = [];
    if (program.typeToInterceptorMap != null) {
      statements.add(js.js.statement('init.# = #;',
          [js.string(TYPE_TO_INTERCEPTOR_MAP), program.typeToInterceptorMap]));
    }
    return js.Block(statements);
  }

  js.Block emitTypeRules(Fragment fragment) {
    List<js.Statement> statements = [];

    bool addJsObjectRedirections = false;
    ClassEntity jsObjectClass = _commonElements.jsJavaScriptObjectClass;
    InterfaceType jsObjectType = _elementEnvironment.getThisType(jsObjectClass);

    Map<ClassTypeData, List<ClassTypeData>> nativeRedirections =
        _nativeEmitter.typeRedirections;

    Ruleset ruleset = Ruleset.empty();
    Map<ClassEntity, int> erasedTypes = {};
    Iterable<ClassTypeData> classTypeData =
        fragment.libraries.expand((Library library) => library.classTypeData);
    classTypeData.forEach((ClassTypeData typeData) {
      ClassEntity element = typeData.element;
      InterfaceType targetType = _elementEnvironment.getThisType(element);

      // TODO(fishythefish): Prune uninstantiated classes.
      if (_rtiNeed.classHasErasedTypeArguments(element)) {
        erasedTypes[element] = targetType.typeArguments.length;
      }

      bool isInterop = _classHierarchy.isSubclassOf(element, jsObjectClass);

      Iterable<TypeCheck> checks = typeData.classChecks?.checks ?? [];
      Iterable<InterfaceType> supertypes = isInterop
          ? checks
              .map((check) => _elementEnvironment.getJsInteropType(check.cls))
          : checks
              .map((check) => _dartTypes.asInstanceOf(targetType, check.cls));

      Map<TypeVariableType, DartType> typeVariables = {};
      Set<TypeVariableType> namedTypeVariables = typeData.namedTypeVariables;
      nativeRedirections[typeData]?.forEach((ClassTypeData redirectee) {
        namedTypeVariables.addAll(redirectee.namedTypeVariables);
      });
      for (TypeVariableType typeVariable in typeData.namedTypeVariables) {
        TypeVariableEntity element = typeVariable.element;
        InterfaceType supertype = isInterop
            ? _elementEnvironment.getJsInteropType(element.typeDeclaration)
            : _dartTypes.asInstanceOf(targetType, element.typeDeclaration);
        List<DartType> supertypeArguments = supertype.typeArguments;
        typeVariables[typeVariable] = supertypeArguments[element.index];
      }

      if (isInterop) {
        ruleset.addEntry(jsObjectType, supertypes, typeVariables);
        addJsObjectRedirections = true;
      } else {
        ruleset.addEntry(targetType, supertypes, typeVariables);
      }
    });

    if (addJsObjectRedirections) {
      _classHierarchy
          .strictSubclassesOf(jsObjectClass)
          .forEach((ClassEntity subclass) {
        ruleset.addRedirection(subclass, jsObjectClass);
      });
    }

    nativeRedirections
        .forEach((ClassTypeData target, List<ClassTypeData> redirectees) {
      for (ClassTypeData redirectee in redirectees) {
        ruleset.addRedirection(redirectee.element, target.element);
      }
    });

    if (ruleset.isNotEmpty) {
      FunctionEntity addRules = _closedWorld.commonElements.rtiAddRulesMethod;
      statements.add(js.js.statement('#(init.#,JSON.parse(#));', [
        _emitter.staticFunctionAccess(addRules),
        RTI_UNIVERSE,
        _rulesetEncoder.encodeRuleset(ruleset),
      ]));
    }

    if (erasedTypes.isNotEmpty) {
      FunctionEntity addErasedTypes =
          _closedWorld.commonElements.rtiAddErasedTypesMethod;
      statements.add(js.js.statement('#(init.#,JSON.parse(#));', [
        _emitter.staticFunctionAccess(addErasedTypes),
        RTI_UNIVERSE,
        _rulesetEncoder.encodeErasedTypes(erasedTypes),
      ]));
    }

    return js.Block(statements);
  }

  js.Statement emitVariances(Fragment fragment) {
    if (!_options.enableVariance) {
      return js.EmptyStatement();
    }

    Map<ClassEntity, List<Variance>> typeParameterVariances = {};
    Iterable<Class> classes =
        fragment.libraries.expand((Library library) => library.classes);
    classes.forEach((Class cls) {
      ClassEntity element = cls.element;
      List<Variance> classVariances =
          _elementEnvironment.getTypeVariableVariances(element);

      // Emit variances for a class only if there is at least one explicit
      // variance defined.
      bool hasOnlyLegacyVariance = classVariances
          .every((variance) => variance == Variance.legacyCovariant);
      if (!hasOnlyLegacyVariance) {
        typeParameterVariances[element] = classVariances;
      }
    });

    if (typeParameterVariances.isNotEmpty) {
      FunctionEntity addVariances =
          _closedWorld.commonElements.rtiAddTypeParameterVariancesMethod;
      return js.js.statement('#(init.#,JSON.parse(#));', [
        _emitter.staticFunctionAccess(addVariances),
        RTI_UNIVERSE,
        _rulesetEncoder.encodeTypeParameterVariances(typeParameterVariances),
      ]);
    }

    return js.EmptyStatement();
  }

  /// Returns an expression that creates the initial Rti Universe.
  ///
  /// This needs to be kept in sync with `_Universe.create` in `dart:_rti`.
  js.Expression createRtiUniverse() {
    List<js.Property> universeFields = [];
    void initField(String name, String value) {
      universeFields.add(js.Property(js.string(name), js.js(value)));
    }

    initField(RtiUniverseFieldNames.evalCache, 'new Map()');
    initField(RtiUniverseFieldNames.typeRules, '{}');
    initField(RtiUniverseFieldNames.erasedTypes, '{}');
    initField(RtiUniverseFieldNames.typeParameterVariances, '{}');
    initField(RtiUniverseFieldNames.sharedEmptyArray, '[]');

    return js.ObjectInitializer(universeFields);
  }

  /// Emits data needed for native classes.
  ///
  /// We don't try to reduce the size of the native data, but rather build
  /// JavaScript object literals that contain all the information directly.
  /// This means that the output size is bigger, but that the startup is faster.
  ///
  /// This function is the static equivalent of
  /// [NativeGenerator.buildNativeInfoHandler].
  js.Statement emitNativeSupport(Fragment fragment) {
    List<js.Statement> statements = [];

    // The isolate-affinity tag must only be initialized once per program.
    if (fragment.isMainFragment &&
        NativeGenerator.needsIsolateAffinityTagInitialization(
            _closedWorld.backendUsage)) {
      statements.add(NativeGenerator.generateIsolateAffinityTagInitialization(
          _closedWorld.backendUsage, generateEmbeddedGlobalAccess, js.js("""
        // On V8, the 'intern' function converts a string to a symbol, which
        // makes property access much faster.
        // TODO(sra): Use Symbol on non-IE11 browsers.
        function (s) {
          var o = {};
          o[s] = 1;
          return Object.keys(hunkHelpers.convertToFastObject(o))[0];
        }""", [])));
    }

    Map<String, js.Expression> interceptorsByTag = {};
    Map<String, js.Expression> leafTags = {};
    List<js.Statement> subclassAssignments = [];

    for (Library library in fragment.libraries) {
      for (Class cls in library.classes) {
        if (cls.nativeLeafTags != null) {
          for (String tag in cls.nativeLeafTags) {
            interceptorsByTag[tag] = classReference(cls);
            leafTags[tag] = new js.LiteralBool(true);
          }
        }
        if (cls.nativeNonLeafTags != null) {
          for (String tag in cls.nativeNonLeafTags) {
            interceptorsByTag[tag] = classReference(cls);
            leafTags[tag] = new js.LiteralBool(false);
          }
          if (cls.nativeExtensions != null) {
            List<Class> subclasses = cls.nativeExtensions;
            js.Expression base = js.string(cls.nativeNonLeafTags[0]);

            for (Class subclass in subclasses) {
              subclassAssignments.add(js.js.statement('#.# = #;', [
                classReference(subclass),
                NATIVE_SUPERCLASS_TAG_NAME,
                base
              ]));
            }
          }
        }
      }
    }

    // Emit the empty objects for main fragment in case we emit
    // getNativeInterceptor.
    // TODO(sra): Refine the impacts to accuratley predict whether we need this
    // at all, and delete 'setOrUpdateInterceptorsByTag' if it is not called.
    if (fragment.isMainFragment || interceptorsByTag.isNotEmpty) {
      statements.add(js.js.statement(
          "hunkHelpers.setOrUpdateInterceptorsByTag(#);",
          js.objectLiteral(interceptorsByTag)));
    }
    if (fragment.isMainFragment || leafTags.isNotEmpty) {
      statements.add(js.js.statement(
          "hunkHelpers.setOrUpdateLeafTags(#);", js.objectLiteral(leafTags)));
    }
    statements.addAll(subclassAssignments);

    return wrapPhase('nativeSupport', statements);
  }
}

class LocalAliases {
  final Map<String, js.Expression> _locals = {};

  bool get isEmpty => _locals.isEmpty;
  bool get isNotEmpty => !isEmpty;

  String find(String alias, String expression) {
    _locals[alias] ??= js.js(expression);
    return alias;
  }

  js.Statement toStatement() {
    List<js.VariableInitialization> initializations = [];
    _locals.forEach((local, value) {
      initializations
          .add(js.VariableInitialization(js.VariableDeclaration(local), value));
    });
    return js.ExpressionStatement(js.VariableDeclarationList(initializations));
  }
}

/// Code to initialize holder with ancillary information.
class HolderCode {
  final List<Holder> activeHolders;
  js.Statement statements;
  HolderCode({this.activeHolders, this.statements});
}

class DeferredLoadingState {
  final deferredLibraryParts = new DeferredPrimaryExpression();
  final deferredPartUris = new DeferredPrimaryExpression();
  final deferredPartHashes = new DeferredPrimaryExpression();
}

class DeferredPrimaryExpression extends js.DeferredExpression {
  js.Expression _value;

  void setValue(js.Expression value) {
    assert(_value == null);
    assert(value.precedenceLevel == this.precedenceLevel);
    _value = value;
  }

  @override
  js.Expression get value {
    assert(_value != null);
    return _value;
  }

  @override
  int get precedenceLevel => js_precedence.PRIMARY;
}
