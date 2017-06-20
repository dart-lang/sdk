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
const String tearOffPropertyName = r'$tearOff';

/// The name of the property that stores the list of fields on a constructor.
///
/// This property is only used when isolates are used.
///
/// When serializing objects we extract all fields from any given object.
/// We extract the names of all fields from a fresh empty object. This list
/// is cached on the constructor in this property to to avoid too many
/// allocations.
const String cachedClassFieldNames = r'$cachedFieldNames';

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
const String mainBoilerplate = '''
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

var functionsHaveName = (function() {
  function t() {};
  return (typeof t.name == 'string')
})();

// Sets the name property of functions, if the JS engine doesn't set the name
// itself.
// As of 2015 only IE doesn't set the name.
function setFunctionNamesIfNecessary(holders) {
  if (functionsHaveName) return;
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
  cls.#typeNameProperty = cls.name;  // Needed for RTI.
  cls.prototype.constructor = cls;
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

// Mixes in the properties of [mixin] into [cls].
function mixin(cls, mixin) {
  copyProperties(mixin.prototype, cls.prototype);
}

// Creates a lazy field.
//
// A lazy field has a storage entry, [name], which holds the value, and a
// getter ([getterName]) to access the field. If the field wasn't set before
// the first access, it is initialized with the [initializer].
function lazy(holder, name, getterName, initializer) {
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
    optionalParameterDefaultValues, callNames, funsOrNames, funType) {
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
      tearOff(funs, reflectionInfo, isStatic, name, isIntercepted);
  container[getterName] = getterFunction;
  if (isStatic) {
    fun.$tearOffPropertyName = getterFunction;
  }
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
  // This relies on the fact that types are added *after* the tear-offs have
  // been installed. The tear-off function uses the types-length to figure
  // out at which offset its types are located. If the types were added earlier
  // the offset would be wrong.
  types.push.apply(types, newTypes);
}

// Updates the given holder with the properties of the [newHolder].
// This function is used when a deferred fragment is initialized.
function updateHolder(holder, newHolder) {
  copyProperties(newHolder, holder);
  return holder;
}

// Every deferred hunk (i.e. fragment) is a function that we can invoke to
// initialize it. At this moment it contributes its data to the main hunk.
function initializeDeferredHunk(hunk) {
  // Update the typesOffset for the next deferred library.
  typesOffset = #embeddedTypes.length;

  // TODO(floitsch): extend natives.
  hunk(inherit, mixin, lazy, makeConstList, convertToFastObject, installTearOff,
       setFunctionNamesIfNecessary, updateHolder, updateTypes,
       setOrUpdateInterceptorsByTag, setOrUpdateLeafTags,
       #embeddedGlobalsObject, holders, #staticState);
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
        holders, #embeddedGlobalsObject, #staticState, inherit, mixin,
        installTearOff);
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
setFunctionNamesIfNecessary(holders);

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

// Instantiates all constants.
#constants;
// Initializes the static non-final fields (with their constant values).
#staticNonFinalFields;
// Creates lazy getters for statics that must run initializers on first access.
#lazyStatics;

// Emits the embedded globals.
#embeddedGlobals;

// Sets up the native support.
// Native-support uses setOrUpdateInterceptorsByTag and setOrUpdateLeafTags.
#nativeSupport;

// Sets up the js-interop support.
#jsInteropSupport;

// Invokes main (making sure that it records the 'current-script' value).
#invokeMain;
})()
''';

/// An expression that returns `true` if `__proto__` can be assigned to stitch
/// together a prototype chain, and the performance is good.
const String directAccessTestExpression = r'''
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

/// Deferred fragments (aka 'hunks') are built similarly to the main fragment.
///
/// However, at specific moments they need to contribute their data.
/// For example, once the holders have been created, they are included into
/// the main holders.
const String deferredBoilerplate = '''
function(inherit, mixin, lazy, makeConstList, convertToFastObject,
         installTearOff, setFunctionNamesIfNecessary, updateHolder, updateTypes,
         setOrUpdateInterceptorsByTag, setOrUpdateLeafTags,
         #embeddedGlobalsObject, holdersList, #staticState) {

// Builds the holders. They only contain the data for new holders.
#holders;

// If the name is not set on the functions, do it now.
setFunctionNamesIfNecessary(#deferredHoldersList);

// Updates the holders of the main-fragment. Uses the provided holdersList to
// access the main holders.
// The local holders are replaced by the combined holders. This is necessary
// for the inheritance setup below.
#updateHolders;
// Sets the prototypes of the new classes.
#prototypes;
// Sets aliases of methods (on the prototypes of classes).
#aliases;
// Installs the tear-offs of functions.
#tearOffs;
// Builds the inheritance structure.
#inheritance;

// Instantiates all constants of this deferred fragment.
// Note that the constant-holder has been updated earlier and storing the
// constant values in the constant-holder makes them available globally.
#constants;
// Initializes the static non-final fields (with their constant values).
#staticNonFinalFields;
// Creates lazy getters for statics that must run initializers on first access.
#lazyStatics;

updateTypes(#types);

// Native-support uses setOrUpdateInterceptorsByTag and setOrUpdateLeafTags.
#nativeSupport;
}''';

/// Soft-deferred fragments are built similarly to the main fragment.
///
/// However, they don't contribute anything to global namespace, but just
/// initialize existing classes. For example, they update the inheritance
/// hierarchy, and add methods the prototypes.
const String softDeferredBoilerplate = '''
#deferredGlobal[#softId] =
    function(holdersList, #embeddedGlobalsObject, #staticState, inherit, mixin,
    installTearOff) {

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

/**
 * This class builds a JavaScript tree for a given fragment.
 *
 * A fragment is generally written into a separate file so that it can be
 * loaded dynamically when a deferred library is loaded.
 *
 * This class is stateless and can be reused for different fragments.
 */
class FragmentEmitter {
  final Compiler compiler;
  final Namer namer;
  final JavaScriptBackend backend;
  final ConstantEmitter constantEmitter;
  final ModelEmitter modelEmitter;
  final ClosedWorld _closedWorld;

  FragmentEmitter(this.compiler, this.namer, this.backend, this.constantEmitter,
      this.modelEmitter, this._closedWorld);

  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  js.Expression generateEmbeddedGlobalAccess(String global) =>
      modelEmitter.generateEmbeddedGlobalAccess(global);

  js.Expression generateConstantReference(ConstantValue value) =>
      modelEmitter.generateConstantReference(value);

  js.Expression classReference(Class cls) {
    return js.js('#.#', [cls.holder.name, cls.name]);
  }

  js.Statement emitMainFragment(Program program,
      Map<DeferredFragment, _DeferredFragmentHash> deferredLoadHashes) {
    MainFragment fragment = program.fragments.first;

    Iterable<Holder> nonStaticStateHolders =
        program.holders.where((Holder holder) => !holder.isStaticStateHolder);

    String softDeferredId = "softDeferred${new Random().nextInt(0x7FFFFFFF)}";

    js.Statement mainCode = js.js.statement(mainBoilerplate, {
      'directAccessTestExpression': js.js(directAccessTestExpression),
      'typeNameProperty': js.string(ModelEmitter.typeNameProperty),
      'cyclicThrow': backend.emitter
          .staticFunctionAccess(_closedWorld.commonElements.cyclicThrowHelper),
      'operatorIsPrefix': js.string(namer.operatorIsPrefix),
      'tearOffCode': new js.Block(buildTearOffCode(compiler.options,
          backend.emitter.emitter, backend.namer, _closedWorld.commonElements)),
      'embeddedTypes': generateEmbeddedGlobalAccess(TYPES),
      'embeddedInterceptorTags':
          generateEmbeddedGlobalAccess(INTERCEPTORS_BY_TAG),
      'embeddedLeafTags': generateEmbeddedGlobalAccess(LEAF_TAGS),
      'embeddedGlobalsObject': js.js("init"),
      'staticStateDeclaration': new js.VariableDeclaration(
          namer.staticStateHolder,
          allowRename: false),
      'staticState': js.js('#', namer.staticStateHolder),
      'constantHolderReference': buildConstantHolderReference(program),
      'holders': emitHolders(program.holders, fragment),
      'callName': js.string(namer.callNameField),
      'stubName': js.string(namer.stubNameField),
      'argumentCount': js.string(namer.requiredParameterField),
      'defaultArgumentValues': js.string(namer.defaultValuesField),
      'deferredGlobal': ModelEmitter.deferredInitializersGlobal,
      'hasSoftDeferredClasses': program.hasSoftDeferredClasses,
      'softId': js.string(softDeferredId),
      'isTrackingAllocations': compiler.options.experimentalTrackAllocations,
      'prototypes': emitPrototypes(fragment),
      'inheritance': emitInheritance(fragment),
      'aliases': emitInstanceMethodAliases(fragment),
      'tearOffs': emitInstallTearOffs(fragment),
      'constants': emitConstants(fragment),
      'staticNonFinalFields': emitStaticNonFinalFields(fragment),
      'lazyStatics': emitLazilyInitializedStatics(fragment),
      'embeddedGlobals': emitEmbeddedGlobals(program, deferredLoadHashes),
      'nativeSupport': program.needsNativeSupport
          ? emitNativeSupport(fragment)
          : new js.EmptyStatement(),
      'jsInteropSupport': backend.nativeBasicData.isJsInteropUsed
          ? backend.jsInteropAnalysis.buildJsInteropBootstrap()
          : new js.EmptyStatement(),
      'invokeMain': fragment.invokeMain,
    });
    if (program.hasSoftDeferredClasses) {
      return new js.Block([
        js.js.statement(softDeferredBoilerplate, {
          'deferredGlobal': ModelEmitter.deferredInitializersGlobal,
          'softId': js.string(softDeferredId),
          // TODO(floitsch): don't just reference 'init'.
          'embeddedGlobalsObject': new js.Parameter('init'),
          'staticState': new js.Parameter(namer.staticStateHolder),
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
    return mainCode;
  }

  js.Statement emitInstallHoldersAsLocals(Iterable<Holder> holders) {
    List<js.Statement> holderInits = <js.Statement>[];
    int counter = 0;
    for (Holder holder in holders) {
      holderInits.add(new js.ExpressionStatement(new js.VariableInitialization(
          new js.VariableDeclaration(holder.name, allowRename: false),
          js.js("holdersList[#]", js.number(counter++)))));
    }
    return new js.Block(holderInits);
  }

  js.Expression emitDeferredFragment(DeferredFragment fragment,
      js.Expression deferredTypes, List<Holder> holders) {
    List<Holder> nonStaticStateHolders = holders
        .where((Holder holder) => !holder.isStaticStateHolder)
        .toList(growable: false);

    List<js.Statement> updateHolderAssignments = <js.Statement>[];
    for (int i = 0; i < nonStaticStateHolders.length; i++) {
      Holder holder = nonStaticStateHolders[i];
      updateHolderAssignments.add(js.js.statement(
          '#holder = updateHolder(holdersList[#index], #holder)',
          {'index': js.number(i), 'holder': new js.VariableUse(holder.name)}));
    }

    // TODO(floitsch): don't just reference 'init'.
    return js.js(deferredBoilerplate, {
      'embeddedGlobalsObject': new js.Parameter('init'),
      'staticState': new js.Parameter(namer.staticStateHolder),
      'holders': emitHolders(holders, fragment),
      'deferredHoldersList': new js.ArrayInitializer(nonStaticStateHolders
          .map((holder) => js.js("#", holder.name))
          .toList(growable: false)),
      'updateHolders': new js.Block(updateHolderAssignments),
      'prototypes': emitPrototypes(fragment),
      'inheritance': emitInheritance(fragment),
      'aliases': emitInstanceMethodAliases(fragment),
      'tearOffs': emitInstallTearOffs(fragment),
      'constants': emitConstants(fragment),
      'staticNonFinalFields': emitStaticNonFinalFields(fragment),
      'lazyStatics': emitLazilyInitializedStatics(fragment),
      'types': deferredTypes,
      // TODO(floitsch): only call emitNativeSupport if we need native.
      'nativeSupport': emitNativeSupport(fragment),
    });
  }

  /// Emits all holders, except for the static-state holder.
  ///
  /// The emitted holders contain classes (only the constructors) and all
  /// static functions.
  js.Statement emitHolders(List<Holder> holders, Fragment fragment) {
    // Skip the static-state holder in this function.
    holders = holders
        .where((Holder holder) => !holder.isStaticStateHolder)
        .toList(growable: false);

    Map<Holder, Map<js.Name, js.Expression>> holderCode =
        <Holder, Map<js.Name, js.Expression>>{};

    for (Holder holder in holders) {
      holderCode[holder] = <js.Name, js.Expression>{};
    }

    for (Library library in fragment.libraries) {
      for (StaticMethod method in library.statics) {
        assert(!method.holder.isStaticStateHolder);
        var staticMethod = emitStaticMethod(method);
        if (compiler.options.dumpInfo) {
          for (var code in staticMethod.values) {
            compiler.dumpInfoTask.registerElementAst(method.element, code);
            compiler.dumpInfoTask.registerElementAst(library.element, code);
          }
        }
        holderCode[method.holder].addAll(staticMethod);
      }
      for (Class cls in library.classes) {
        assert(!cls.holder.isStaticStateHolder);
        var constructor = emitConstructor(cls);
        compiler.dumpInfoTask.registerElementAst(cls.element, constructor);
        compiler.dumpInfoTask.registerElementAst(library.element, constructor);
        holderCode[cls.holder][cls.name] = constructor;
      }
    }

    js.VariableInitialization emitHolderInitialization(Holder holder) {
      List<js.Property> properties = <js.Property>[];
      holderCode[holder].forEach((js.Name key, js.Expression value) {
        properties.add(new js.Property(js.quoteName(key), value));
      });

      return new js.VariableInitialization(
          new js.VariableDeclaration(holder.name, allowRename: false),
          new js.ObjectInitializer(properties));
    }

    // The generated code looks like this:
    //
    //    {
    //      var H = {...}, ..., G = {...};
    //      var holders = [ H, ..., G ];
    //    }

    List<js.Statement> statements = [
      new js.ExpressionStatement(new js.VariableDeclarationList(
          holders.map(emitHolderInitialization).toList())),
      js.js.statement(
          'var holders = #',
          new js.ArrayInitializer(holders
              .map((holder) => new js.VariableUse(holder.name))
              .toList(growable: false)))
    ];
    return new js.Block(statements);
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
    Map<js.Name, js.Expression> jsMethods = <js.Name, js.Expression>{};

    // We don't need to install stub-methods. They can only be used when there
    // are tear-offs, in which case they are emitted there.
    assert(() {
      if (method is StaticDartMethod) {
        return method.needsTearOff || method.parameterStubs.isEmpty;
      }
      return true;
    });
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
    var parameters = <js.Name>[];
    var thisRef;

    if (cls.isSoftDeferred) {
      statements.add(js.js.statement('softDef(this)'));
    } else if (compiler.options.experimentalTrackAllocations) {
      String qualifiedName =
          "${cls.element.library.canonicalUri}:${cls.element.name}";
      statements.add(js.js.statement('allocations["$qualifiedName"] = true'));
    }

    // If there are many references to `this`, cache it in a local.
    if (cls.fields.length + (cls.hasRtiField ? 1 : 0) >= 4) {
      // TODO(29455): Fix js_ast printer and minifier to avoid conflicts between
      // js.Name and string-named variables, then use '_' in the js template
      // text.

      // We pick '_' in minified mode because no field minifies to '_'. This
      // avoids a conflict with one of the parameters which are named the same
      // as the fields.  Unminified, a field might have the name '_', so we pick
      // '$_', which is an impossible member name since we escape '$'s in names.
      js.Name underscore = compiler.options.enableMinification
          ? new StringBackedName('_')
          : new StringBackedName(r'$_');
      statements.add(js.js.statement('var # = this;', underscore));
      thisRef = underscore;
    } else {
      thisRef = js.js('this');
    }

    for (Field field in cls.fields) {
      js.Name paramName = field.name;
      parameters.add(paramName);
      statements
          .add(js.js.statement('#.# = #', [thisRef, field.name, paramName]));
    }

    if (cls.hasRtiField) {
      js.Name paramName = namer.rtiFieldJsName;
      parameters.add(paramName);
      statements.add(js.js
          .statement('#.# = #', [thisRef, namer.rtiFieldJsName, paramName]));
    }

    return js.js('function #(#) { # }', [name, parameters, statements]);
  }

  /// Emits the prototype-section of the fragment.
  ///
  /// This section updates the prototype-property of all constructors in the
  /// global holders.
  js.Statement emitPrototypes(Fragment fragment, {softDeferred = false}) {
    List<js.Statement> assignments = fragment.libraries
        .expand((Library library) => library.classes)
        .where((Class cls) => cls.isSoftDeferred == softDeferred)
        .map((Class cls) {
      var proto = js.js.statement(
          '#.prototype = #;', [classReference(cls), emitPrototype(cls)]);
      ClassElement element = cls.element;
      compiler.dumpInfoTask.registerElementAst(element, proto);
      compiler.dumpInfoTask.registerElementAst(element.library, proto);
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

    List<js.Property> properties = <js.Property>[];

    if (cls.superclass == null) {
      // TODO(sra): What is this doing? Document or remove.
      properties
          .add(new js.Property(js.string("constructor"), classReference(cls)));
      properties
          .add(new js.Property(namer.operatorIs(cls.element), js.number(1)));
    }

    allMethods.forEach((Method method) {
      emitInstanceMethod(method)
          .forEach((js.Expression name, js.Expression code) {
        var prop = new js.Property(name, code);
        compiler.dumpInfoTask.registerElementAst(method.element, prop);
        properties.add(prop);
      });
    });

    if (cls.isClosureBaseClass) {
      // Closures extend a common base class, so we can put properties on the
      // prototype for common values.

      // Most closures have no optional arguments.
      properties.add(new js.Property(
          js.string(namer.defaultValuesField), new js.LiteralNull()));
    }

    return new js.ObjectInitializer(properties);
  }

  /// Generates a getter for the given [field].
  Method generateGetter(Field field) {
    assert(field.needsGetter);

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
    js.Expression code = js.js(template, fieldName);
    js.Name getterName = namer.deriveGetterName(field.accessorName);
    return new StubMethod(getterName, code);
  }

  /// Generates a setter for the given [field].
  Method generateSetter(Field field) {
    assert(field.needsUncheckedSetter);

    String template;
    if (field.needsInterceptedSetterOnReceiver) {
      template = "function(receiver, val) { return receiver[#] = val; }";
    } else if (field.needsInterceptedSetterOnThis) {
      template = "function(receiver, val) { return this[#] = val; }";
    } else {
      assert(!field.needsInterceptedSetter);
      template = "function(val) { return this[#] = val; }";
    }

    js.Expression fieldName = js.quoteName(field.name);
    js.Expression code = js.js(template, fieldName);
    js.Name setterName = namer.deriveSetterName(field.accessorName);
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

        properties[js.string(namer.callCatchAllName)] =
            js.quoteName(method.name);
        properties[js.string(namer.requiredParameterField)] =
            js.number(method.requiredParameterCount);

        js.Expression defaultValues =
            _encodeOptionalParameterDefaultValues(method);
        // Default values property of `null` is stored on the common JS
        // superclass.
        if (defaultValues is! js.LiteralNull || forceAdd) {
          properties[js.string(namer.defaultValuesField)] = defaultValues;
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
    List<js.Statement> inheritCalls = <js.Statement>[];
    List<js.Statement> mixinCalls = <js.Statement>[];

    Set<Class> classesInFragment = new Set<Class>();
    for (Library library in fragment.libraries) {
      classesInFragment.addAll(library.classes
          .where(((Class cls) => cls.isSoftDeferred == softDeferred)));
    }

    Map<Class, List<Class>> subclasses = <Class, List<Class>>{};
    Set<Class> seen = new Set<Class>();

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

        if (cls.isMixinApplication) {
          MixinApplication mixin = cls;
          mixinCalls.add(js.js.statement('mixin(#, #)',
              [classReference(cls), classReference(mixin.mixinClass)]));
        }
      }
    }

    js.Expression temp = null;
    for (Class superclass in subclasses.keys) {
      List<Class> list = subclasses[superclass];
      js.Expression superclassReference = (superclass == null)
          ? new js.LiteralNull()
          : classReference(superclass);
      if (list.length == 1) {
        inheritCalls.add(js.js.statement('inherit(#, #)',
            [classReference(list.single), superclassReference]));
      } else {
        // Hold common superclass in temporary for sequence of calls.
        if (temp == null) {
          String tempName = '_';
          temp = new js.VariableUse(tempName);
          var declaration = new js.VariableDeclaration(tempName);
          inheritCalls.add(
              js.js.statement('var # = #', [declaration, superclassReference]));
        } else {
          inheritCalls
              .add(js.js.statement('# = #', [temp, superclassReference]));
        }
        for (Class cls in list) {
          inheritCalls.add(
              js.js.statement('inherit(#, #)', [classReference(cls), temp]));
        }
      }
    }

    return wrapPhase('inheritance', inheritCalls.toList()..addAll(mixinCalls));
  }

  /// Emits the setup of method aliases.
  ///
  /// This step consists of simply copying JavaScript functions to their
  /// aliased names so they point to the same function.
  js.Statement emitInstanceMethodAliases(Fragment fragment,
      {bool softDeferred = false}) {
    List<js.Statement> assignments = <js.Statement>[];

    for (Library library in fragment.libraries) {
      for (Class cls in library.classes) {
        if (cls.isSoftDeferred != softDeferred) continue;
        for (InstanceMethod method in cls.methods) {
          if (method.aliasName != null) {
            assignments.add(js.js.statement('#.prototype.# = #.prototype.#', [
              classReference(cls),
              js.quoteName(method.aliasName),
              classReference(cls),
              js.quoteName(method.name)
            ]));
          }
        }
      }
    }
    return new js.Block(assignments);
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
      List<js.Property> properties = <js.Property>[];
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

  /// Emits the statement that installs a tear off for a method.
  ///
  /// Tear-offs might be passed to `Function.apply` which means that all
  /// calling-conventions (with or without optional positional/named arguments)
  /// are possible. As such, the tear-off needs enough information to fill in
  /// missing parameters.
  js.Statement emitInstallTearOff(js.Expression container, DartMethod method) {
    List<js.Name> callNames = <js.Name>[];
    List<js.Expression> funsOrNames = <js.Expression>[];

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
    js.ArrayInitializer funsOrNamesArray = new js.ArrayInitializer(funsOrNames);

    bool isIntercepted = false;
    if (method is InstanceMethod) {
      MethodElement element = method.element;
      isIntercepted = _interceptorData.isInterceptedMethod(element);
    }
    int requiredParameterCount = 0;
    js.Expression optionalParameterDefaultValues = new js.LiteralNull();
    if (method.canBeApplied) {
      requiredParameterCount = method.requiredParameterCount;
      optionalParameterDefaultValues =
          _encodeOptionalParameterDefaultValues(method);
    }

    return js.js.statement(
        '''
        installTearOff(#container, #getterName, #isStatic, #isIntercepted,
                       #requiredParameterCount, #optionalParameterDefaultValues,
                       #callNames, #funsOrNames, #funType)''',
        {
          "container": container,
          "getterName": js.quoteName(method.tearOffName),
          // 'Truthy' values are ok for `isStatic` and `isIntercepted`.
          "isStatic": js.number(method.isStatic ? 1 : 0),
          "isIntercepted": js.number(isIntercepted ? 1 : 0),
          "requiredParameterCount": js.number(requiredParameterCount),
          "optionalParameterDefaultValues": optionalParameterDefaultValues,
          "callNames": callNameArray,
          "funsOrNames": funsOrNamesArray,
          "funType": method.functionType,
        });
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
    List<js.Statement> inits = <js.Statement>[];
    js.Expression temp;

    for (Library library in fragment.libraries) {
      for (StaticMethod method in library.statics) {
        // TODO(floitsch): can there be anything else than a StaticDartMethod?
        if (method is StaticDartMethod) {
          if (method.needsTearOff) {
            Holder holder = method.holder;
            inits.add(
                emitInstallTearOff(new js.VariableUse(holder.name), method));
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
          inits.add(emitInstallTearOff(reference, method));
          reference = temp; // Second and subsequent calls use temp.
        }
      }
    }
    return wrapPhase('installTearOffs', inits);
  }

  /// Emits the constants section.
  js.Statement emitConstants(Fragment fragment) {
    List<js.Statement> assignments = <js.Statement>[];
    for (Constant constant in fragment.constants) {
      // TODO(floitsch): instead of just updating the constant holder, we should
      // find the constants that don't have any dependency on other constants
      // and create an object-literal with them (and assign it to the
      // constant-holder variable).
      var assignment = js.js.statement('#.# = #', [
        constant.holder.name,
        constant.name,
        constantEmitter.generate(constant.value)
      ]);
      compiler.dumpInfoTask.registerConstantAst(constant.value, assignment);
      assignments.add(assignment);
    }
    return wrapPhase('constants', assignments);
  }

  /// Emits the static non-final fields section.
  ///
  /// This section initializes all static non-final fields that don't require
  /// an initializer.
  js.Statement emitStaticNonFinalFields(Fragment fragment) {
    List<StaticField> fields = fragment.staticNonFinalFields;
    // TODO(floitsch): instead of assigning the fields one-by-one we should
    // create a literal and assign it to the static-state holder.
    // TODO(floitsch): if we don't make a literal we should at least initialize
    // statics that have the same initial value in the same expression:
    //    `$.x = $.y = $.z = null;`.
    Iterable<js.Statement> statements = fields.map((StaticField field) {
      assert(field.holder.isStaticStateHolder);
      return js.js
          .statement("#.# = #;", [field.holder.name, field.name, field.code]);
    });
    return wrapPhase('staticFields', statements.toList());
  }

  /// Emits lazy fields.
  ///
  /// This section initializes all static (final and non-final) fields that
  /// require an initializer.
  js.Statement emitLazilyInitializedStatics(Fragment fragment) {
    List<StaticField> fields = fragment.staticLazilyInitializedFields;
    Iterable<js.Statement> statements = fields.map((StaticField field) {
      assert(field.holder.isStaticStateHolder);
      return js.js.statement("lazy(#, #, #, #);", [
        field.holder.name,
        js.quoteName(field.name),
        js.quoteName(namer.deriveLazyInitializerName(field.name)),
        field.code
      ]);
    });

    return wrapPhase('lazyInitializers', statements.toList());
  }

  /// Emits the embedded globals that are needed for deferred loading.
  ///
  /// This function is only invoked for the main fragment.
  ///
  /// The [loadMap] contains a map from load-ids (for each deferred library)
  /// to the list of generated fragments that must be installed when the
  /// deferred library is loaded.
  Iterable<js.Property> emitEmbeddedGlobalsForDeferredLoading(
      Map<String, List<Fragment>> loadMap,
      Map<DeferredFragment, _DeferredFragmentHash> deferredLoadHashes) {
    if (loadMap.isEmpty) return [];

    List<js.Property> globals = <js.Property>[];

    js.ArrayInitializer fragmentUris(List<Fragment> fragments) {
      return js.stringArray(fragments.map((Fragment fragment) =>
          "${fragment.outputFileName}.${ModelEmitter.deferredExtension}"));
    }

    js.ArrayInitializer fragmentHashes(List<Fragment> fragments) {
      return new js.ArrayInitializer(fragments
          .map((fragment) => deferredLoadHashes[fragment])
          .toList(growable: false));
    }

    List<js.Property> uris = new List<js.Property>(loadMap.length);
    List<js.Property> hashes = new List<js.Property>(loadMap.length);
    int count = 0;
    loadMap.forEach((String loadId, List<Fragment> fragmentList) {
      uris[count] =
          new js.Property(js.string(loadId), fragmentUris(fragmentList));
      hashes[count] =
          new js.Property(js.string(loadId), fragmentHashes(fragmentList));
      count++;
    });

    globals.add(new js.Property(
        js.string(DEFERRED_LIBRARY_URIS), new js.ObjectInitializer(uris)));
    globals.add(new js.Property(
        js.string(DEFERRED_LIBRARY_HASHES), new js.ObjectInitializer(hashes)));
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

    /// See [emitEmbeddedGlobalsForDeferredLoading] for the format of the
    /// deferred hunk.
    js.Expression initializeLoadedHunkFunction = js.js(
        """
            function(hash) {
              initializeDeferredHunk($deferredGlobal[hash]);
              #deferredInitialized[hash] = true;
            }""",
        {
          'deferredInitialized':
              generateEmbeddedGlobalAccess(DEFERRED_INITIALIZED)
        });

    globals.add(new js.Property(
        js.string(INITIALIZE_LOADED_HUNK), initializeLoadedHunkFunction));

    return globals;
  }

  /// Emits the [MANGLED_GLOBAL_NAMES] embedded global.
  ///
  /// This global maps minified names for selected classes (some important
  /// core classes, and some native classes) to their unminified names.
  js.Property emitMangledGlobalNames() {
    List<js.Property> names = <js.Property>[];

    CommonElements commonElements = _closedWorld.commonElements;
    // We want to keep the original names for the most common core classes when
    // calling toString on them.
    List<ClassElement> nativeClassesNeedingUnmangledName = [
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
          js.quoteName(namer.className(element)), js.string(element.name)));
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
    List<js.Property> metadataGlobals = <js.Property>[];

    js.Property createGlobal(js.Expression metadata, String global) {
      return new js.Property(js.string(global), metadata);
    }

    metadataGlobals.add(createGlobal(program.metadata, METADATA));
    js.Expression types =
        program.metadataTypesForOutputUnit(program.mainFragment.outputUnit);
    metadataGlobals.add(createGlobal(types, TYPES));

    return metadataGlobals;
  }

  /// Emits all embedded globals.
  js.Statement emitEmbeddedGlobals(Program program,
      Map<DeferredFragment, _DeferredFragmentHash> deferredLoadHashes) {
    List<js.Property> globals = <js.Property>[];

    if (program.loadMap.isNotEmpty) {
      globals.addAll(emitEmbeddedGlobalsForDeferredLoading(
          program.loadMap, deferredLoadHashes));
    }

    if (program.typeToInterceptorMap != null) {
      globals.add(new js.Property(
          js.string(TYPE_TO_INTERCEPTOR_MAP), program.typeToInterceptorMap));
    }

    if (program.hasIsolateSupport) {
      String staticStateName = namer.staticStateHolder;
      // TODO(floitsch): this doesn't create a new isolate, but just reuses
      // the current static state. Since we don't run multiple isolates in the
      // same JavaScript context (except for testing) this shouldn't have any
      // impact on real-world programs, though.
      globals.add(new js.Property(js.string(CREATE_NEW_ISOLATE),
          js.js('function () { return $staticStateName; }')));

      js.Expression nameToClosureFunction = js.js('''
        // First fetch the static function. From there we can execute its
        // getter function which builds a Dart closure.
        function(name) {
           var staticFunction = getGlobalFromName(name);
           var getterFunction = staticFunction.$tearOffPropertyName;
           return getterFunction();
         }''');
      globals.add(new js.Property(
          js.string(STATIC_FUNCTION_NAME_TO_CLOSURE), nameToClosureFunction));

      globals.add(new js.Property(js.string(CLASS_ID_EXTRACTOR),
          js.js('function(o) { return o.constructor.name; }')));

      js.Expression extractFieldsFunction = js.js('''
      function(o) {
        var constructor = o.constructor;
        var fieldNames = constructor.$cachedClassFieldNames;
        if (!fieldNames) {
          // Extract the fields from an empty unmodified object.
          var empty = new constructor();
          // This gives us the keys that the constructor sets.
          fieldNames = constructor.$cachedClassFieldNames = Object.keys(empty);
        }
        var result = new Array(fieldNames.length);
        for (var i = 0; i < fieldNames.length; i++) {
          result[i] = o[fieldNames[i]];
        }
        return result;
      }''');
      globals.add(new js.Property(
          js.string(CLASS_FIELDS_EXTRACTOR), extractFieldsFunction));

      js.Expression createInstanceFromClassIdFunction = js.js('''
        function(name) {
          var constructor = getGlobalFromName(name);
          return new constructor();
        }
      ''');
      globals.add(new js.Property(js.string(INSTANCE_FROM_CLASS_ID),
          createInstanceFromClassIdFunction));

      js.Expression initializeEmptyInstanceFunction = js.js('''
      function(name, o, fields) {
        var constructor = o.constructor;
        // By construction the object `o` is an empty object with the same
        // keys as the one we used in the extract-fields function.
        var fieldNames = Object.keys(o);
        if (fieldNames.length != fields.length) {
          throw new Error("Mismatch during deserialization.");
        }
        for (var i = 0; i < fields.length; i++) {
          o[fieldNames[i]] = fields[i];
        }
        return o;
      }''');
      globals.add(new js.Property(js.string(INITIALIZE_EMPTY_INSTANCE),
          initializeEmptyInstanceFunction));
    }

    globals.add(emitMangledGlobalNames());

    // The [MANGLED_NAMES] table must contain the mapping for const symbols.
    // Without const symbols, the table is only relevant for reflection and
    // therefore unused in this emitter.
    List<js.Property> mangledNamesProperties = <js.Property>[];
    program.symbolsMap.forEach((js.Name mangledName, String unmangledName) {
      mangledNamesProperties
          .add(new js.Property(mangledName, js.string(unmangledName)));
    });
    globals.add(new js.Property(js.string(MANGLED_NAMES),
        new js.ObjectInitializer(mangledNamesProperties)));

    globals.add(emitGetTypeFromName());

    globals.addAll(emitMetadata(program));

    if (program.needsNativeSupport) {
      globals.add(new js.Property(
          js.string(INTERCEPTORS_BY_TAG), new js.LiteralNull()));
      globals.add(new js.Property(js.string(LEAF_TAGS), new js.LiteralNull()));
    }

    js.ObjectInitializer globalsObject = new js.ObjectInitializer(globals);

    return js.js.statement('var init = #;', globalsObject);
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
    List<js.Statement> statements = <js.Statement>[];

    // The isolate-affinity tag must only be initialized once per program.
    if (fragment.isMainFragment &&
        NativeGenerator
            .needsIsolateAffinityTagInitialization(_closedWorld.backendUsage)) {
      statements.add(NativeGenerator.generateIsolateAffinityTagInitialization(
          _closedWorld.backendUsage,
          generateEmbeddedGlobalAccess,
          js.js(
              """
        // On V8, the 'intern' function converts a string to a symbol, which
        // makes property access much faster.
        function (s) {
          var o = {};
          o[s] = 1;
          return Object.keys(convertToFastObject(o))[0];
        }""",
              [])));
    }

    Map<String, js.Expression> interceptorsByTag = <String, js.Expression>{};
    Map<String, js.Expression> leafTags = <String, js.Expression>{};
    List<js.Statement> subclassAssignments = <js.Statement>[];

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
    statements.add(js.js.statement("setOrUpdateInterceptorsByTag(#);",
        js.objectLiteral(interceptorsByTag)));
    statements.add(
        js.js.statement("setOrUpdateLeafTags(#);", js.objectLiteral(leafTags)));
    statements.addAll(subclassAssignments);

    return wrapPhase('nativeSupport', statements);
  }
}
