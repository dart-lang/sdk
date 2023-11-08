// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.startup_emitter.model_emitter;

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
///     Object.setPrototypeOf(A.Point.prototype, H.Object.prototype);
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

if (#startupMetrics) {
  // Stash the metrics on the main unit IIFE.
  // TODO(sra): When the JavaScript local renamer is more intelligent, we can
  // simply use a local variable.
  (dartProgram.$STARTUP_METRICS = ${ModelEmitter.startupMetricsGlobal})
      .add("dartProgramMs");
}

if (#isCollectingRuntimeMetrics) {
  dartProgram.$RUNTIME_METRICS = Object.create(null);
  var allocations = dartProgram.$RUNTIME_METRICS['allocations'] = Object.create(null);
}

// Copies the own properties from [from] to [to].
function copyProperties(from, to) {
  var keys = Object.keys(from);
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    to[key] = from[key];
  }
}

// Copies the own properties from [from] to [to] if not already present in [to].
function mixinPropertiesHard(from, to) {
  var keys = Object.keys(from);
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    if (!to.hasOwnProperty(key)) {
      to[key] = from[key];
    }
  }
}
// Copies the own properties from [from] to [to] (specialized version of
// `mixinPropertiesHard` when it is known the properties are disjoint).
function mixinPropertiesEasy(from, to) {
  Object.assign(to, from);
}

// Only use direct proto access to construct the prototype chain (instead of
// copying properties) on platforms where we know it works well (Chrome / d8).
var supportsDirectProtoAccess = #directAccessTestExpression;

// Makes [cls] inherit from [sup].
// On Chrome, Firefox and recent IEs this happens by updating the internal
// proto-property of the classes 'prototype' field.
// Older IEs use `Object.create` and copy over the properties.
function inherit(cls, sup) {
  // cls.prototype.constructor carries the cached RTI. We could avoid this by
  // using ES6 classes, but the side effects of this need to be tested.
  cls.prototype.constructor = cls;
  cls.prototype[#operatorIsPrefix + cls.name] = cls;

  // The superclass is only null for the Dart Object.
  if (sup != null) {
    if (supportsDirectProtoAccess) {
      // Firefox doesn't like to update the prototypes, but when setting up
      // the hierarchy chain it's ok.
      Object.setPrototypeOf(cls.prototype, sup.prototype);
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
function mixinEasy(cls, mixin) {
  mixinPropertiesEasy(mixin.prototype, cls.prototype);
  cls.prototype.constructor = cls;
}
function mixinHard(cls, mixin) {
  mixinPropertiesHard(mixin.prototype, cls.prototype);
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

// Creates a lazy final static field that uses non-nullable initialization
// semantics.
//
// A lazy final field has a storage entry, [name], which holds the value, and a
// getter ([getterName]) to access the field. The field is initialized on first
// access with the [initializer].
function lazyFinal(holder, name, getterName, initializer) {
  var uninitializedSentinel = holder;
  holder[name] = uninitializedSentinel;
  holder[getterName] = function() {
    if (holder[name] === uninitializedSentinel) {
      var value = initializer();
      if (holder[name] !== uninitializedSentinel) {
        // Since there is no setter, the only way to get here is via bounded
        // recursion, where `initializer` calls the lazy final getter.
        #throwLateFieldADI(name);
      }
      holder[name] = value;
    }
    // TODO(sra): Does the value need to be stored in the holder at all?
    // Potentially a call to the getter could be replaced with an access to
    // holder slot if dominated by a previous call to the getter. Does the
    // optimizer do this? If so, within a single function, the dominance
    // relations should allow a local copy via GVN, so it is not that valuable
    // an optimization for a `final` static variable.
    var finalValue = holder[name];
    holder[getterName] = function() { return finalValue; };
    return finalValue;
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
// The `funType` passed to the `installTearOff` function below is relative to
// the hunk the function comes from. The `typesOffset` variable encodes the
// offset at which the new types will be added.
var typesOffset = 0;

/// Collect and canonicalize tear-off parameters.
///
/// [container] is either the `prototype` of a class constructor, or the holder
/// for static functions.
///
/// [funsOrNames] is an array of strings or functions. If it is a
/// name, then the function should be fetched from the container. The first
/// entry in that array *must* be a string.
// TODO(sra): It might be more readable to manually inline and simplify at the
// two calls. It would need to be assessed as it would likely make the object
// references polymorphic.
function tearOffParameters(
    container, isStatic, isIntercepted,
    requiredParameterCount, optionalParameterDefaultValues,
    callNames, funsOrNames, funType, applyIndex, needsDirectAccess) {
  if (typeof funType == "number") {
    // The [funType] can be a string type recipe or an index into the types
    // table.  If it points into the types-table we need to update the index, in
    // case the tear-off is part of a deferred hunk.
    funType += typesOffset;
  }
  return {
    #tpContainer: container,
    #tpIsStatic: isStatic,
    #tpIsIntercepted: isIntercepted,
    #tpRequiredParameterCount: requiredParameterCount,
    #tpOptionalParameterDefaultValues: optionalParameterDefaultValues,
    #tpCallNames: callNames,
    #tpFunctionsOrNames: funsOrNames,
    #tpFunctionType: funType,
    #tpApplyIndex: applyIndex || 0,
    #tpNeedsDirectAccess: needsDirectAccess,
  }
}

/// Stores the static tear-off getter-function in the [holder]'s [getterName]
/// property.
function installStaticTearOff(
    holder, getterName,
    requiredParameterCount, optionalParameterDefaultValues,
    callNames, funsOrNames, funType, applyIndex) {
  // TODO(sra): Specialize for very common simple cases.
  var parameters = tearOffParameters(
      holder, true, false,
      requiredParameterCount, optionalParameterDefaultValues,
      callNames, funsOrNames, funType, applyIndex, false);
  var getterFunction = staticTearOffGetter(parameters);
  // TODO(sra): Returning [getterFunction] would be more versatile. We might
  // want to store the static tearoff getter in a different holder, or in no
  // holder if it is immediately called from the constant pool and otherwise
  // unreferenced.
  holder[getterName] = getterFunction;
}

/// Stores the instance tear-off getter-function in the [prototype]'s
/// [getterName] property.
function installInstanceTearOff(
    prototype, getterName, isIntercepted,
    requiredParameterCount, optionalParameterDefaultValues,
    callNames, funsOrNames, funType, applyIndex, needsDirectAccess) {
  isIntercepted = !!isIntercepted; // force to Boolean.
  var parameters = tearOffParameters(
      prototype, false, isIntercepted,
      requiredParameterCount, optionalParameterDefaultValues,
      callNames, funsOrNames, funType, applyIndex, !!needsDirectAccess);
  var getterFunction = instanceTearOffGetter(isIntercepted, parameters);
  prototype[getterName] = getterFunction;
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
          callNames, [name], funType, applyIndex,
          /*needsDirectAccess:*/ false);
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
    mixin: mixinEasy,
    mixinHard: mixinHard,
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

// Creates the holders.
#holders;

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
})();
''';

/// An expression that returns `true` if `setPrototypeOf` can be called to stitch
/// together a prototype chain, and the performance is good.
const String _directAccessTestExpression = r'''
  (function () {
    var cls = function () {};
    cls.prototype = {'p': {}};
    var object = new cls();
    if (!(Object.getPrototypeOf(object) && Object.getPrototypeOf(object).p === cls.prototype.p))
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
if (#isCollectingRuntimeMetrics) {
  var allocations = #embeddedGlobalsObject.#runtimeMetrics['allocations'];
}
// Builds the holders. They only contain the data for new holders.
// If names are not set on functions, we do it now. Finally, updates the
// holders of the main-fragment. Uses the provided holdersList to access the
// main holders.
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

/// This class builds a JavaScript tree for a given fragment.
///
/// A fragment is generally written into a separate file so that it can be
/// loaded dynamically when a deferred library is loaded.
///
/// This class is stateless and can be reused for different fragments.
class FragmentEmitter {
  final CompilerOptions _options;
  final DumpInfoJsAstRegistry _dumpInfoRegistry;
  final Namer _namer;
  final Emitter _emitter;
  final ConstantEmitter _constantEmitter;
  final ModelEmitter _modelEmitter;
  final NativeEmitter _nativeEmitter;
  final JClosedWorld _closedWorld;
  final CodegenWorld _codegenWorld;
  final RecipeEncoder _recipeEncoder;
  late final RulesetEncoder _rulesetEncoder =
      RulesetEncoder(_emitter, _recipeEncoder);
  final DeferredHolderExpressionFinalizer _holderFinalizer;

  ClassHierarchy get _classHierarchy => _closedWorld.classHierarchy;
  CommonElements get _commonElements => _closedWorld.commonElements;
  DartTypes get _dartTypes => _closedWorld.dartTypes;
  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;
  RuntimeTypesNeed get _rtiNeed => _closedWorld.rtiNeed;

  late final js.Name call0Name =
      _namer.getNameForJsGetName(null, JsGetName.CALL_PREFIX0);
  late final js.Name call1Name =
      _namer.getNameForJsGetName(null, JsGetName.CALL_PREFIX1);
  late final js.Name call2Name =
      _namer.getNameForJsGetName(null, JsGetName.CALL_PREFIX2);
  late final List<js.Name> callNamesByArity = [call0Name, call1Name, call2Name];

  FragmentEmitter(
      this._options,
      this._dumpInfoRegistry,
      this._namer,
      this._emitter,
      this._constantEmitter,
      this._modelEmitter,
      this._nativeEmitter,
      this._closedWorld,
      this._codegenWorld)
      : _holderFinalizer =
            DeferredHolderExpressionFinalizerImpl(_closedWorld.commonElements),
        _recipeEncoder = RecipeEncoderImpl(
            _closedWorld,
            _options.disableRtiOptimization
                ? TrivialRuntimeTypesSubstitutions(_closedWorld)
                : RuntimeTypesImpl(_closedWorld),
            _closedWorld.nativeData,
            _closedWorld.commonElements);

  js.Expression generateEmbeddedGlobalAccess(String global) =>
      _emitter.generateEmbeddedGlobalAccess(global);

  js.Expression generateConstantReference(ConstantValue value) =>
      _modelEmitter.generateConstantReference(value);

  js.Expression classReference(Class cls) {
    // TODO(joshualitt): This should be generated by
    // [DeferredHolderExpressionFinalizer].
    return js
        .js('#.#', [_namer.readGlobalObjectForClass(cls.element), cls.name]);
  }

  void registerEntityAst(Entity? entity, js.Node code,
      {LibraryEntity? library}) {
    _dumpInfoRegistry.registerEntityAst(entity, code);
    // TODO(sigmund): stop recoding associations twice, dump-info already
    // has library to element dependencies to recover this data.
    if (library != null) _dumpInfoRegistry.registerEntityAst(library, code);
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
    int size = 0;
    if (estimateSize) {
      var estimator = SizeEstimator();
      estimator.visit(classPrototypes);
      estimator.visit(closurePrototypes);
      estimator.visit(inheritance);
      estimator.visit(methodAliases);
      estimator.visit(tearOffs);
      estimator.visit(constants);
      estimator.visit(typeRules);
      estimator.visit(variances);
      estimator.visit(staticNonFinalFields);
      estimator.visit(lazyInitializers);
      estimator.visit(nativeSupport);
      size = estimator.charCount;
    }
    var emittedOutputUnit = EmittedOutputUnit(
        fragment,
        fragment.outputUnit,
        fragment.libraries,
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
        nativeSupport);
    return PreFragment(fragment.outputFileName, emittedOutputUnit, size);
  }

  js.Statement emitMainFragment(
      Program program,
      Map<String, List<FinalizedFragment>> fragmentsToLoad,
      DeferredLoadingState deferredLoadingState) {
    final fragment = program.fragments.first as MainFragment;

    // Emit holder code.
    var holderCode = emitHolderCode(fragment.libraries);
    var holderDeclaration = DeferredHolderResource(
        DeferredHolderResourceKind.mainFragment,
        mainResourceName,
        [fragment],
        holderCode);
    js.Statement mainCode = js.js.statement(_mainBoilerplate, {
      // TODO(29455): 'hunkHelpers' displaces other names, so don't minify it.
      'hunkHelpers': js.VariableDeclaration('hunkHelpers', allowRename: false),
      'directAccessTestExpression': js.js(_directAccessTestExpression),
      'cyclicThrow': _emitter
          .staticFunctionAccess(_closedWorld.commonElements.cyclicThrowHelper),
      'throwLateFieldADI': _emitter
          .staticFunctionAccess(_closedWorld.commonElements.throwLateFieldADI),
      'operatorIsPrefix': js.string(_namer.fixedNames.operatorIsPrefix),
      'tearOffCode': js.Block(
          buildTearOffCode(_options, _emitter, _closedWorld.commonElements)),
      'embeddedTypes': generateEmbeddedGlobalAccess(TYPES),
      'embeddedInterceptorTags':
          generateEmbeddedGlobalAccess(INTERCEPTORS_BY_TAG),
      'embeddedLeafTags': generateEmbeddedGlobalAccess(LEAF_TAGS),
      'embeddedGlobalsObject': js.js("init"),
      'staticStateDeclaration': DeferredHolderParameter(),
      'staticState': DeferredHolderParameter(),
      'holders': holderDeclaration,
      'startupMetrics': _closedWorld.backendUsage.requiresStartupMetrics,

      // Tearoff parameters:
      'tpContainer': js.string(TearOffParametersPropertyNames.container),
      'tpIsStatic': js.string(TearOffParametersPropertyNames.isStatic),
      'tpIsIntercepted':
          js.string(TearOffParametersPropertyNames.isIntercepted),
      'tpRequiredParameterCount':
          js.string(TearOffParametersPropertyNames.requiredParameterCount),
      'tpOptionalParameterDefaultValues': js.string(
          TearOffParametersPropertyNames.optionalParameterDefaultValues),
      'tpCallNames': js.string(TearOffParametersPropertyNames.callNames),
      'tpFunctionsOrNames':
          js.string(TearOffParametersPropertyNames.funsOrNames),
      'tpFunctionType': js.string(TearOffParametersPropertyNames.funType),
      'tpApplyIndex': js.string(TearOffParametersPropertyNames.applyIndex),
      'tpNeedsDirectAccess':
          js.string(TearOffParametersPropertyNames.needsDirectAccess),

      //'callName': js.string(_namer.fixedNames.callNameField),
      //'stubName': js.string(_namer.stubNameField),
      //'argumentCount': js.string(_namer.fixedNames.requiredParameterField),
      //'defaultArgumentValues': js.string(_namer.fixedNames.defaultValuesField),
      'isCollectingRuntimeMetrics': _options.experimentalTrackAllocations,
      'prototypes': emitPrototypes(fragment),
      'inheritance': emitInheritance(fragment),
      'aliases': emitInstanceMethodAliases(fragment),
      'tearOffs': emitInstallTearOffs(fragment),
      'constants': emitConstants(fragment),
      'staticNonFinalFields': emitStaticNonFinalFields(fragment),
      'lazyStatics': emitLazilyInitializedStatics(fragment),
      'embeddedGlobalsPart1': emitEmbeddedGlobalsPart1(
          program, fragmentsToLoad, deferredLoadingState),
      'embeddedGlobalsPart2':
          emitEmbeddedGlobalsPart2(program, deferredLoadingState),
      'typeRules': emitTypeRules(fragment),
      'sharedStrings': StringReferenceResource(),
      'variances': emitVariances(fragment),
      'sharedTypeRtis': TypeReferenceResource(),
      'nativeSupport': emitNativeSupport(fragment),
      'jsInteropSupport': jsInteropAnalysis.buildJsInteropBootstrap(
              _codegenWorld, _closedWorld.nativeData, _namer) ??
          js.EmptyStatement(),
      'invokeMain': fragment.invokeMain,

      'call0selector': js.quoteName(call0Name),
      'call1selector': js.quoteName(call1Name),
      'call2selector': js.quoteName(call2Name),
    });
    // We assume emitMainFragment will be the last piece of code we emit.
    finalizeCode(mainResourceName, mainCode, holderCode, finalizeHolders: true);
    return mainCode;
  }

  js.Expression? emitCodeFragment(CodeFragment fragment) {
    var holderCode = emitHolderCode(fragment.libraries);

    // TODO(sra): How do we tell if [deferredTypes] is empty? It is filled-in
    // later via the program finalizers. So we should defer the decision on the
    // emptiness of the fragment until the finalizers have run.  For now we seem
    // to get away with the fact that type indexes are either (1) main unit or
    // (2) local to the emitted unit, so there is no such thing as a type in a
    // deferred unit that is referenced from another deferred unit.  If we did
    // not emit any functions, then we probably did not use the signature types
    // in the OutputUnit's types, leaving them unused and tree-shaken.

    if (holderCode.isEmpty && fragment.isEmpty) {
      return null;
    }

    var resourceName = fragment.canonicalOutputUnit.name;
    var updateHolders = DeferredHolderResource(
        DeferredHolderResourceKind.deferredFragment,
        resourceName,
        fragment.fragments,
        holderCode);
    js.Expression code = js.js(_deferredBoilerplate, {
      // TODO(floitsch): don't just reference 'init'.
      'embeddedGlobalsObject': js.Parameter('init'),
      'isCollectingRuntimeMetrics': _options.experimentalTrackAllocations,
      'staticState': DeferredHolderParameter(),
      'runtimeMetrics': RUNTIME_METRICS,
      'updateHolders': updateHolders,
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
    finalizeCode(resourceName, code, holderCode);
    return code;
  }

  /// Adds code to a finalizer.
  void addCodeToFinalizer(void Function(js.Node) addCode, js.Node fragmentCode,
      Map<Entity, List<js.Property>> holderCode) {
    addCode(fragmentCode);
    for (var properties in holderCode.values) {
      for (var property in properties) {
        addCode(property);
      }
    }
  }

  /// Finalizes the code for a fragment, and optionally finalizes holders.
  /// Finalizing holders must be the last step of the emitter.
  void finalizeCode(String resourceName, js.Node code,
      Map<Entity, List<js.Property>> holderCode,
      {bool finalizeHolders = false}) {
    StringReferenceFinalizer stringFinalizer =
        StringReferenceFinalizerImpl(_options.enableMinification);
    addCodeToFinalizer(stringFinalizer.addCode, code, holderCode);
    stringFinalizer.finalize();
    TypeReferenceFinalizer typeFinalizer = TypeReferenceFinalizerImpl(
        _emitter, _commonElements, _recipeEncoder, _options.enableMinification);
    addCodeToFinalizer(typeFinalizer.addCode, code, holderCode);
    typeFinalizer.finalize();

    // DeferredHolders need to be finalized last. In addition, finalizing
    // holders needs to be the very last thing the [FragmentEmitter] does before
    // we actually emit code. This is to ensure all holders are registered.
    // Note: Unlike the above finalizers, which are created and finalized
    // per output unit, the holderFinalizer is a whole-program finalizer,
    // which collects deferred [Node]s from each call to `finalizeCode`
    // before begin finalized once for the last (main) unit.
    void _addCode(js.Node code) {
      _holderFinalizer.addCode(resourceName, code);
    }

    addCodeToFinalizer(_addCode, code, holderCode);
    if (finalizeHolders) {
      _holderFinalizer.finalize();
    }
  }

  /// Emits holder code for a list of libraries. We emit [Property]s directly
  /// into a map keyed by [Entity] because we don't yet know anything about the
  /// structure of the underlying holders and thus we cannot emit this code
  /// directly into the ast.
  Map<Entity, List<js.Property>> emitHolderCode(List<Library> libraries) {
    Map<Entity, List<js.Property>> holderCode = {};
    for (Library library in libraries) {
      for (StaticMethod method in library.statics) {
        Map<js.Name, js.Expression> propertyMap = emitStaticMethod(method);
        propertyMap.forEach((js.Name key, js.Expression value) {
          final property =
              js.MethodDefinition(js.quoteName(key), value as js.Fun);
          final Entity holderKey =
              method is StaticStubMethod ? method.library : method.element!;
          assert(method is! StaticStubMethod ||
              method.library == _commonElements.interceptorsLibrary);
          (holderCode[holderKey] ??= []).add(property);
          registerEntityAst(method.element, property, library: library.element);
        });
      }
      for (Class cls in library.classes) {
        js.Expression constructor = emitConstructor(cls);
        var property = js.Property(js.quoteName(cls.name), constructor);
        (holderCode[cls.element] ??= []).add(property);
        registerEntityAst(cls.element, property, library: library.element);
      }
    }
    return holderCode;
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
    jsMethods[method.name!] = method.code;

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

    if (_options.experimentalTrackAllocations) {
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
      js.Name underscore = StringBackedName('_');
      statements.add(js.js.statement('var # = this;', underscore));
      thisRef = underscore;
    } else {
      thisRef = js.js('this');
    }

    // Chain assignments of the same value, e.g. `this.b = this.a = null`.
    // Limit chain length so that the JavaScript parser has bounded recursion.
    const int maxChainLength = 30;
    js.Expression? assignment;
    int chainLength = 0;
    ConstantValue? previousConstant;
    void flushAssignment() {
      if (assignment != null) {
        statements.add(js.js.statement('#;', assignment));
        assignment = null;
        chainLength = 0;
        previousConstant = null;
      }
    }

    for (Field field in emittedFields) {
      final constant = field.initializerInAllocator;
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
        js.Parameter parameter = js.Parameter('t${parameters.length}');
        parameters.add(parameter);
        statements.add(
            js.js.statement('#.# = #', [thisRef, field.name, parameter.name]));
      }
    }
    flushAssignment();

    if (cls.hasRtiField) {
      js.Parameter parameter = js.Parameter('t${parameters.length}');
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
  /// If [includeClosures] is `true` only prototypes for closure classes are
  /// generated, if [includeClosures] is `false` only prototypes for non-closure
  /// classes are generated. Otherwise prototypes for all classes are generated.
  js.Statement emitPrototypes(Fragment fragment, {bool? includeClosures}) {
    List<js.Statement> assignments = fragment.libraries
        .expand((Library library) => library.classes)
        .where((Class cls) {
      if (includeClosures != null) {
        if (cls.element.isClosure != includeClosures) {
          return false;
        }
      }
      return true;
    }).map((Class cls) {
      var proto = js.js.statement(
          '#.prototype = #;', [classReference(cls), emitPrototype(cls)]);
      ClassEntity element = cls.element;
      registerEntityAst(element, proto, library: element.library);
      return proto;
    }).toList(growable: false);

    return js.Block(assignments);
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
    Iterable<Method> gettersSetters = cls.gettersSetters;
    Iterable<Method> allMethods = [
      ...methods,
      ...checkedSetters,
      ...isChecks,
      ...callStubs,
      ...noSuchMethodStubs,
      ...gettersSetters
    ];

    List<js.Property> properties = [];

    if (cls.superclass == null) {
      // This is Dart `Object`. Add properties that are usually added by
      // `inherit`.

      // TODO(sra): Adding properties here appears to be redundant with the call
      // to `inherit(P.Object, null)` in the generated code. See if we can
      // remove that.

      properties.add(js.Property(_namer.operatorIs(cls.element), js.number(1)));
    }

    allMethods.forEach((Method method) {
      emitInstanceMethod(method)
          .forEach((js.Expression name, js.Expression code) {
        js.Property property = code is js.Fun
            ? js.MethodDefinition(name, code)
            : js.Property(name, code);
        registerEntityAst(method.element, property);
        properties.add(property);
      });
    });

    // Closures have metadata that is often the same. We avoid repeated metadata
    // by putting it on a shared superclass. It is overridden in the subclass if
    // necessary.

    final arity = cls.sharedClosureApplyMetadata;
    if (arity != null) {
      // This is a closure base class that has the specialized `Function.apply`
      // metadata for functions taking exactly [arity] arguments.
      properties.add(js.Property(js.string(_namer.fixedNames.callCatchAllName),
          js.quoteName(callNamesByArity[arity])));
      properties.add(js.Property(
          js.string(_namer.fixedNames.requiredParameterField),
          js.number(arity)));
    }

    if (cls.isClosureBaseClass) {
      // Most closures have no optional arguments.
      properties.add(js.Property(
          js.string(_namer.fixedNames.defaultValuesField), js.LiteralNull()));
    }

    // `prototype` properties for record classes.
    if (cls.recordShapeRecipe != null) {
      properties.add(js.Property(js.string(_namer.fixedNames.recordShapeRecipe),
          cls.recordShapeRecipe!));
    }
    if (cls.recordShapeTag != null) {
      properties.add(js.Property(js.string(_namer.fixedNames.recordShapeTag),
          js.number(cls.recordShapeTag!)));
    }

    return js.ObjectInitializer(properties);
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

    properties[method.name!] = method.code;
    if (method is InstanceMethod) {
      for (ParameterStubMethod stubMethod in method.parameterStubs) {
        properties[stubMethod.name!] = stubMethod.code;
      }

      if (method.isClosureCallMethod && method.canBeApplied) {
        // The `call` method might flow to `Function.apply`, so the metadata for
        // `Function.apply` is needed.

        // Avoid adding the metadata if a superclass has the same metadata.
        if (!method.inheritsApplyMetadata) {
          final applyName = method.applyIndex == 0
              ? method.name!
              : method.parameterStubs[method.applyIndex - 1].name!;
          properties[js.string(_namer.fixedNames.callCatchAllName)] =
              js.quoteName(applyName);
          properties[js.string(_namer.fixedNames.requiredParameterField)] =
              js.number(method.requiredParameterCount);

          js.Expression defaultValues =
              _encodeOptionalParameterDefaultValues(method);
          // Default values property of `null` is stored on the common JS
          // superclass.
          if (defaultValues is! js.LiteralNull) {
            properties[js.string(_namer.fixedNames.defaultValuesField)] =
                defaultValues;
          }
        }
      }
    }

    return properties;
  }

  /// Emits the inheritance block of the fragment.
  ///
  /// In this section prototype chains are updated and mixin functions are
  /// copied.
  js.Statement emitInheritance(Fragment fragment) {
    List<js.Statement> inheritCalls = [];
    List<js.Statement> mixinCalls = [];
    // local caches of functions to allow minification of function name in call.
    LocalAliases locals = LocalAliases();

    Set<Class> classesInFragment = Set();
    for (Library library in fragment.libraries) {
      classesInFragment.addAll(library.classes);
    }

    Map<Class?, List<Class>> subclasses = {};
    Set<Class> seen = Set();

    void collect(Class? cls) {
      if (cls == null || seen.contains(cls)) return;

      final superclass = cls.superclass;
      if (classesInFragment.contains(superclass)) {
        collect(superclass);
      }

      subclasses.putIfAbsent(superclass, () => []).add(cls);

      seen.add(cls);
    }

    for (Library library in fragment.libraries) {
      for (Class cls in library.classes) {
        collect(cls);
        if (cls.mixinClass != null) {
          js.Statement statement = js.js.statement('#(#, #)', [
            _hasSimpleMixin(cls)
                ? locals.find('_mixin', 'hunkHelpers.mixin')
                : locals.find('_mixinHard', 'hunkHelpers.mixinHard'),
            classReference(cls),
            classReference(cls.mixinClass!),
          ]);
          registerEntityAst(cls.element, statement, library: library.element);
          mixinCalls.add(statement);
        }
      }
    }

    subclasses.forEach((superclass, list) {
      js.Expression superclassReference =
          (superclass == null) ? js.LiteralNull() : classReference(superclass);
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
    });

    List<js.Statement> statements = [];
    if (locals.isNotEmpty) {
      statements.add(locals.toStatement());
    }
    statements.addAll(inheritCalls);
    statements.addAll(mixinCalls);
    return wrapPhase('inheritance', statements);
  }

  /// Determines if the mixin methods can be applied to a mixin application
  /// class by a simple copy, or whether the class defines properties that would
  /// be clobbered by block-copying the mixin's properties, so a slower checking
  /// copy is needed.
  bool _hasSimpleMixin(Class cls) {
    List<Method> allMethods(Class cls) {
      return [
        ...cls.methods,
        ...cls.checkedSetters,
        ...cls.isChecks,
        ...cls.callStubs,
        ...cls.noSuchMethodStubs,
        ...cls.gettersSetters
      ];
    }

    final clsMethods = allMethods(cls);
    if (clsMethods.isEmpty) return true;
    // TODO(sra): Compare methods with those of `cls.mixinClass` to see if the
    // methods (and hence properties) will actually clash. If they are
    // non-overlapping, a simple copy might still be possible.
    return false;
  }

  /// Emits the setup of method aliases.
  ///
  /// This step consists of simply copying JavaScript functions to their
  /// aliased names so they point to the same function.
  js.Statement emitInstanceMethodAliases(Fragment fragment) {
    List<js.Statement> assignments = [];

    for (Library library in fragment.libraries) {
      for (Class cls in library.classes) {
        bool firstAlias = true;
        for (final method in cls.methods) {
          final aliasName = (method as InstanceMethod).aliasName;
          final element = method.element!;
          if (aliasName != null) {
            if (firstAlias) {
              firstAlias = false;
              js.Statement statement = js.js.statement(
                  assignments.isEmpty
                      ? 'var _ = #.prototype;'
                      : '_ = #.prototype',
                  classReference(cls));
              registerEntityAst(element, statement);
              assignments.add(statement);
            }
            js.Statement statement = js.js.statement('_.# = _.#',
                [js.quoteName(aliasName), js.quoteName(method.name!)]);
            registerEntityAst(element, statement);
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
        return js.LiteralNull();
      }
      Iterable<js.Expression> elements =
          defaultValues.map(generateConstantReference);
      return js.js(
          'function() { return #; }', js.ArrayInitializer(elements.toList()));
    } else {
      Map<String, ConstantValue> defaultValues =
          method.optionalParameterDefaultValues;
      List<js.Property> properties = [];
      List<String> names = defaultValues.keys.toList(growable: false);
      // Sort the names the same way we sort them for the named-argument calling
      // convention.
      names.sort();

      for (String name in names) {
        final value = defaultValues[name]!;
        properties.add(
            js.Property(js.string(name), generateConstantReference(value)));
      }
      return js.js(
          'function() { return #; }', js.ObjectInitializer(properties));
    }
  }

  /// Wraps the statement in a named function to that it shows up as a unit in
  /// profiles.
  // TODO(sra): Should this be conditional?
  js.Statement wrapPhase(String name, List<js.Statement> statements) {
    js.Block block = js.Block(statements);
    if (statements.isEmpty) return block;
    return js.js.statement('(function #(){#})();', [name, block]);
  }

  /// Emits the section that installs tear-off getters.
  js.Statement emitInstallTearOffs(Fragment fragment) {
    LocalAliases locals = LocalAliases();

    /// Emits the statement that installs a tear off for a method.
    ///
    /// Tear-offs might be passed to `Function.apply` which means that all
    /// calling-conventions (with or without optional positional/named
    /// arguments) are possible. As such, the tear-off needs enough information
    /// to fill in missing parameters.
    js.Statement emitInstallTearOff(
        js.Expression? container, DartMethod method) {
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
          funsOrNames.add(js.quoteName(stubMethod.name!));
        }
      }

      callNames.add(method.callName!);
      // The first entry in the funsOrNames-array must be a string.
      funsOrNames.add(js.quoteName(method.name!));
      for (ParameterStubMethod stubMethod in method.parameterStubs) {
        final callName = stubMethod.callName;
        // `callName` might be `null` if the method is called directly with some
        // CallStructure but it can be proven that the tearoff not called with
        // with that CallStructure, e.g. the closure does no need the defaulting
        // of arguments but some direct call does.
        if (callName != null) {
          callNames.add(callName);
          addFunOrName(stubMethod);
        }
      }

      final callNameArray =
          js.ArrayInitializer([...callNames.map(js.quoteName)]);
      final funsOrNamesArray = js.ArrayInitializer(funsOrNames);

      bool isIntercepted = false;
      if (method is InstanceMethod) {
        isIntercepted = method.isIntercepted;
      }

      int requiredParameterCount = method.requiredParameterCount;
      js.Expression optionalParameterDefaultValues = js.LiteralNull();
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
              "getterName": js.quoteName(method.tearOffName!),
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
          "getterName": js.quoteName(method.tearOffName!),
          "requiredParameterCount": js.number(requiredParameterCount),
          "optionalParameterDefaultValues": optionalParameterDefaultValues,
          "callNames": callNameArray,
          "funsOrNames": funsOrNamesArray,
          "funType": method.functionType,
          "applyIndex": applyIndex,
        });
      } else {
        bool tearOffNeedsDirectAccess =
            (method as InstanceMethod).tearOffNeedsDirectAccess;
        if (requiredParameterCount <= 2 &&
            callNames.length == 1 &&
            optionalParameterDefaultValues is js.LiteralNull &&
            method.applyIndex == 0 &&
            !tearOffNeedsDirectAccess) {
          js.Statement finish(int arity) {
            // Short form for exactly 0/1/2 arguments.
            String isInterceptedTag = isIntercepted ? 'i' : 'u';
            var install = locals.find('_instance_${arity}_${isInterceptedTag}',
                'hunkHelpers._instance_${arity}${isInterceptedTag}');
            return js.js.statement('''
                #install(#container, #getterName, #name, #funType)''', {
              "install": install,
              "container": container,
              "getterName": js.quoteName(method.tearOffName!),
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
                     #callNames, #funsOrNames, #funType, #applyIndex,
                     #tearOffNeedsDirectAccess)''', {
          "install": install,
          "container": container,
          "getterName": js.quoteName(method.tearOffName!),
          // 'Truthy' values are ok for `isIntercepted`.
          "isIntercepted": js.number(isIntercepted ? 1 : 0),
          "requiredParameterCount": js.number(requiredParameterCount),
          "optionalParameterDefaultValues": optionalParameterDefaultValues,
          "callNames": callNameArray,
          "funsOrNames": funsOrNamesArray,
          "funType": method.functionType,
          "applyIndex": applyIndex,
          // 'Truthy' values are ok for `tearOffNeedsDirectAccess`.
          "tearOffNeedsDirectAccess":
              js.number(tearOffNeedsDirectAccess ? 1 : 0),
        });
      }
    }

    List<js.Statement> inits = [];
    js.Expression? temp;

    for (Library library in fragment.libraries) {
      for (StaticMethod method in library.statics) {
        // TODO(floitsch): can there be anything else than a StaticDartMethod?
        if (method is StaticDartMethod) {
          if (method.needsTearOff) {
            js.Statement statement = emitInstallTearOff(
                _namer.readGlobalObjectForMember(method.element!), method);
            registerEntityAst(method.element, statement,
                library: library.element);
            inits.add(statement);
          }
        }
      }
      for (Class cls in library.classes) {
        var methods =
            cls.methods.where((m) => (m as DartMethod).needsTearOff).toList();
        js.Expression container = js.js("#.prototype", classReference(cls));
        js.Expression? reference = container;
        if (methods.length > 1) {
          if (temp == null) {
            inits.add(js.js.statement('var _;'));
            temp = js.js('_');
          }
          // First call uses assignment to temp to cache the container.
          reference = js.js('# = #', [temp, container]);
        }
        for (final method in methods) {
          js.Statement statement =
              emitInstallTearOff(reference, method as InstanceMethod);
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
        _namer.globalObjectForConstant(constant.value),
        constant.name,
        _constantEmitter.generate(constant.value)
      ]);
      _dumpInfoRegistry.registerConstantAst(constant.value, assignment);
      assignments.add(assignment);
      if (constant.value is ListConstantValue) hasList = true;
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
      // TODO(joshualitt): Distribute fields into per-unit holders and use a
      // deferred holder expression for the field assignment left-hand-side.
      js.Expression location =
          js.js('#.#', [_namer.globalObjectForStaticState(), field.name]);
      js.Statement statement;
      if (field.isInitializedByConstant) {
        statement = js.js.statement("# = #;", [location, field.code]);
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
        final code = field.code as js.Fun;
        final bodyStatements = code.body.statements;
        if (code.params.isEmpty &&
            bodyStatements.length == 1 &&
            bodyStatements.last is js.Return) {
          // For now we only support initializers of the form
          //
          //   function() { return e; }
          //
          // To avoid unforeseen consequences of having parameters and locals
          // in the initializer code.
          final last = bodyStatements.last as js.Return;
          statement = js.js.statement("# = #;", [location, last.value]);
        } else {
          // Safe fallback in the event of a field initializer with no return
          // statement as the last statement.
          statement = js.js.statement("# = #();", [location, code]);
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
      String helper = field.usesNonNullableInitialization
          ? field.isFinal
              ? locals.find('_lazyFinal', 'hunkHelpers.lazyFinal')
              : locals.find('_lazy', 'hunkHelpers.lazy')
          : locals.find('_lazyOld', 'hunkHelpers.lazyOld');
      js.Expression staticFieldCode = field.code;
      if (staticFieldCode is js.Fun) {
        js.Fun fun = staticFieldCode;
        staticFieldCode = js.ArrowFunction(fun.params, fun.body,
                asyncModifier: fun.asyncModifier)
            .withInformationFrom(fun);
      }
      js.Statement statement = js.js.statement("#(#, #, #, #);", [
        helper,
        _namer.globalObjectForStaticState(),
        js.quoteName(field.name),
        js.quoteName(field.getterName!),
        staticFieldCode,
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
      DeferredLoadingState deferredLoadingState,
      {required bool isSplit}) {
    List<js.Property> globals = [];

    globals.add(js.Property(
        js.string(DEFERRED_INITIALIZED), js.js("Object.create(null)")));

    String deferredGlobal = ModelEmitter.deferredInitializersGlobal;
    js.Expression isHunkLoadedFunction =
        js.js("function(hash) { return !!$deferredGlobal[hash]; }");
    globals.add(js.Property(js.string(IS_HUNK_LOADED), isHunkLoadedFunction));

    js.Expression isHunkInitializedFunction = js.js(
        "function(hash) { return !!#deferredInitialized[hash]; }", {
      'deferredInitialized': generateEmbeddedGlobalAccess(DEFERRED_INITIALIZED)
    });
    globals.add(
        js.Property(js.string(IS_HUNK_INITIALIZED), isHunkInitializedFunction));

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

    if (isSplit) {
      js.Expression eventLog = js.js("$deferredGlobal.eventLog");
      globals.add(js.Property(js.string(INITIALIZATION_EVENT_LOG), eventLog));
    }

    globals.add(js.Property(
        js.string(INITIALIZE_LOADED_HUNK), initializeLoadedHunkFunction));

    globals.add(js.Property(js.string(DEFERRED_LIBRARY_PARTS),
        deferredLoadingState.deferredLibraryParts));
    globals.add(js.Property(
        js.string(DEFERRED_PART_URIS), deferredLoadingState.deferredPartUris));
    globals.add(js.Property(js.string(DEFERRED_PART_HASHES),
        deferredLoadingState.deferredPartHashes));

    return globals;
  }

  // Create data used for loading and initializing the hunks for a deferred
  // import. There are three parts: a map from loadId to list of parts, where
  // parts are represented as an index; an array of uris indexed by part; and an
  // array of hashes indexed by part.
  // [deferredLoadHashes] may have missing entries to indicate empty parts.
  void finalizeDeferredLoadingData(
      Map<String, List<CodeFragment>> codeFragmentsToLoad,
      Map<CodeFragment, FinalizedFragment> codeFragmentMap,
      Map<CodeFragment, String> deferredLoadHashes,
      DeferredLoadingState deferredLoadingState) {
    if (codeFragmentsToLoad.isEmpty) return;

    // We store a map of indices to uris and hashes. Because multiple
    // [CodeFragments] can map to a single file, a uri may appear multiple times
    // in [fragmentUris] once per [CodeFragment] reference in that file.
    // TODO(joshualitt): Use a string table to avoid duplicating part file
    // names.
    Map<CodeFragment, int> fragmentIndexes = {};
    List<String> fragmentUris = [];
    List<String> fragmentHashes = [];

    List<js.Property> libraryPartsMapEntries = [];

    codeFragmentsToLoad
        .forEach((String loadId, List<CodeFragment> codeFragments) {
      List<js.Expression> indexes = [];
      for (var codeFragment in codeFragments) {
        var fragment = codeFragmentMap[codeFragment];
        final codeFragmentHash = deferredLoadHashes[codeFragment];
        if (codeFragmentHash == null) continue;
        int? index = fragmentIndexes[codeFragment];
        if (index == null) {
          index = fragmentIndexes[codeFragment] = fragmentIndexes.length;
          fragmentUris.add(
              "${fragment!.outputFileName}.${ModelEmitter.deferredExtension}");
          fragmentHashes.add(codeFragmentHash);
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
      names.add(js.Property(
          js.quoteName(_namer.className(element)), js.string(element.name)));
    });

    return js.Property(
        js.string(MANGLED_GLOBAL_NAMES), js.ObjectInitializer(names));
  }

  /// Emits the [METADATA] embedded global.
  ///
  /// The metadata itself has already been computed earlier and is stored in
  /// the [program].
  List<js.Property> emitMetadata(Program program) {
    List<js.Property> metadataGlobals = [];

    js.Property createGlobal(js.Expression metadata, String global) {
      return js.Property(js.string(global), metadata);
    }

    var mainUnit = program.mainFragment.outputUnit;
    js.Expression types = program.metadataTypesForOutputUnit(mainUnit);
    metadataGlobals.add(createGlobal(types, TYPES));

    return metadataGlobals;
  }

  /// Emits all embedded globals.
  js.Statement emitEmbeddedGlobalsPart1(
      Program program,
      Map<String, List<FinalizedFragment>> fragmentsToLoad,
      DeferredLoadingState deferredLoadingState) {
    List<js.Property> globals = [];

    if (fragmentsToLoad.isNotEmpty) {
      globals.addAll(emitEmbeddedGlobalsForDeferredLoading(deferredLoadingState,
          isSplit: program.isSplit));
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
    globals
        .add(js.Property(js.string(MANGLED_NAMES), js.ObjectInitializer([])));

    globals.addAll(emitMetadata(program));

    if (program.needsNativeSupport) {
      globals
          .add(js.Property(js.string(INTERCEPTORS_BY_TAG), js.LiteralNull()));
      globals.add(js.Property(js.string(LEAF_TAGS), js.LiteralNull()));
    }

    globals.add(
        js.Property(js.string(ARRAY_RTI_PROPERTY), js.js(r'Symbol("$ti")')));

    if (_closedWorld.backendUsage.requiresStartupMetrics) {
      // Copy the metrics object that was stored on the main unit IIFE.
      globals.add(js.Property(
          js.string(STARTUP_METRICS), js.js('dartProgram.$STARTUP_METRICS')));
    }

    if (_options.experimentalTrackAllocations) {
      // Copy the metrics object that was stored on the main unit IIFE.
      globals.add(js.Property(
          js.string(RUNTIME_METRICS), js.js('dartProgram.$RUNTIME_METRICS')));
    }

    final recordStubs = (program.mainFragment as MainFragment).recordTypeStubs;
    if (recordStubs != null) {
      globals.add(js.Property(
          js.string(RECORD_TYPE_TEST_COMBINATORS_PROPERTY), recordStubs));
    }

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

    ClassEntity legacyJsObjectClass =
        _commonElements.jsLegacyJavaScriptObjectClass;

    Map<ClassTypeData, List<ClassTypeData>> nativeRedirections =
        _nativeEmitter.typeRedirections;

    Ruleset ruleset = Ruleset.empty(_dartTypes);
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

      bool isInterop =
          _classHierarchy.isSubclassOf(element, legacyJsObjectClass);

      if (isInterop && element != legacyJsObjectClass) {
        ruleset.addRedirection(element, legacyJsObjectClass);
      } else {
        Iterable<TypeCheck> checks = typeData.classChecks.checks;
        Iterable<InterfaceType> supertypes = isInterop
            ? checks
                .map((check) => _elementEnvironment.getJsInteropType(check.cls))
            : checks.map(
                (check) => _dartTypes.asInstanceOf(targetType, check.cls)!);

        Map<TypeVariableType, DartType> typeVariables = {};
        Set<TypeVariableType> namedTypeVariables = typeData.namedTypeVariables;
        nativeRedirections[typeData]?.forEach((ClassTypeData redirectee) {
          namedTypeVariables.addAll(redirectee.namedTypeVariables);
        });
        for (TypeVariableType typeVariable in typeData.namedTypeVariables) {
          TypeVariableEntity element = typeVariable.element;
          final typeDeclaration = element.typeDeclaration as ClassEntity;
          final supertype = isInterop
              ? _elementEnvironment.getJsInteropType(typeDeclaration)
              : _dartTypes.asInstanceOf(targetType, typeDeclaration)!;
          List<DartType> supertypeArguments = supertype.typeArguments;
          typeVariables[typeVariable] = supertypeArguments[element.index];
        }
        ruleset.addEntry(targetType, supertypes, typeVariables);
      }
    });

    // We add native redirections only to the main fragment in order to avoid
    // duplicating them in multiple deferred units.
    if (fragment.outputUnit.isMainOutput) {
      nativeRedirections
          .forEach((ClassTypeData target, List<ClassTypeData> redirectees) {
        for (ClassTypeData redirectee in redirectees) {
          ruleset.addRedirection(redirectee.element, target.element);
        }
      });
    }

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
          for (String tag in cls.nativeLeafTags!) {
            interceptorsByTag[tag] = classReference(cls);
            leafTags[tag] = js.LiteralBool(true);
          }
        }
        if (cls.nativeNonLeafTags != null) {
          for (String tag in cls.nativeNonLeafTags!) {
            interceptorsByTag[tag] = classReference(cls);
            leafTags[tag] = js.LiteralBool(false);
          }
          if (cls.nativeExtensions != null) {
            List<Class> subclasses = cls.nativeExtensions!;
            js.Expression base = js.string(cls.nativeNonLeafTags![0]);

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
    // TODO(sra): Refine the impacts to accurately predict whether we need this
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

class DeferredLoadingState {
  final deferredLibraryParts = DeferredPrimaryExpression();
  final deferredPartUris = DeferredPrimaryExpression();
  final deferredPartHashes = DeferredPrimaryExpression();
}

class DeferredPrimaryExpression extends js.DeferredExpression {
  late final js.Expression _value;

  /// Set the value for this deferred expression.
  ///
  /// Ensure this is called exactly once before calling the [value] getter.
  void setValue(js.Expression value) {
    assert(value.precedenceLevel == this.precedenceLevel);
    _value = value;
  }

  @override
  js.Expression get value {
    return _value;
  }

  @override
  int get precedenceLevel => js_precedence.PRIMARY;
}
