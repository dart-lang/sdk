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
///     A.Point.prototype.__proto__ = H.Object.prototype;
///
/// The emitter doesn't try to be clever and emits everything beforehand. This
/// increases the output size, but improves performance.
///
// The code relies on the fact that all Dart code is inside holders. As such
// we can use "global" names however we want. As long as we don't shadow
// JavaScript variables (like `Array`) we are free to chose whatever variable
// names we want. Furthermore, the minifier reduces the names of the variables.
const String mainBoilerplate = '''
{
// Declare deferred-initializer global, which is used to keep track of the
// loaded fragments.
#deferredInitializer;

(function() {
// Copies the own properties from [from] to [to].
function copyProperties(from, to) {
  var keys = Object.keys(from);
  for (var i = 0; i < keys.length; i++) {
    to[keys[i]] = from[keys[i]];
  }
}

// Makes [cls] inherit from [sup].
// On Chrome, Firefox and recent IEs this happens by updating the internal
// proto-property of the classes 'prototype' field.
// Older IEs use `Object.create` and copy over the properties.
function inherit(cls, sup) {
  // TODO(floitsch): IE doesn't support changing the __proto__ property. There,
  // we need to copy the properties instead.
  cls.#typeNameProperty = cls.name;  // Needed for RTI.
  cls.prototype.constructor = cls;
  cls.prototype[#operatorIsPrefix + cls.name] = cls;

  // The superclass is only null for the Dart Object.
  if (sup != null) {
    cls.prototype.__proto__ = sup.prototype;
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
  holder[name] = null;
  holder[getterName] = function() {
    holder[getterName] = function() { #cyclicThrow(name) };
    var result;
    var sentinelInProgress = initializer;
    try {
      result = holder[name] = sentinelInProgress;
      result = holder[name] = initializer();
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

// TODO(floitsch): provide code for tear-offs.

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
  types.push.apply(types, newTypes);
}

// Updates the given holder with the properties of the [newHolder].
// This function is used when a deferred fragment is initialized.
function updateHolder(holder, newHolder) {
  // TODO(floitsch): updating the prototype (instead of copying) is
  // *horribly* inefficient in Firefox. There we should just copy the
  // properties.
  var oldPrototype = holder.__proto__;
  newHolder.__proto__ = oldPrototype;
  holder.__proto__ = newHolder;
  return holder;
}

// Every deferred hunk (i.e. fragment) is a function that we can invoke to
// initialize it. At this moment it contributes its data to the main hunk.
function initializeDeferredHunk(hunk) {
  // TODO(floitsch): extend natives.
  hunk(inherit, mixin, lazy, makeConstList, installTearOff,
       updateHolder, updateTypes, updateInterceptorsByTag, updateLeafTags,
       #embeddedGlobalsObject, #holdersList, #staticState);
}

// Creates the holders.
#holders;
// TODO(floitsch): if name is not set (for example in IE), run through all
// functions and set the name.

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

// Emits the embedded globals.
#embeddedGlobals;

// Sets up the native support.
// Native-support uses setOrUpdateInterceptorsByTag and setOrUpdateLeafTags.
#nativeSupport;

// Instantiates all constants.
#constants;
// Initializes the static non-final fields (with their constant values).
#staticNonFinalFields;
// Creates lazy getters for statics that must run initializers on first access.
#lazyStatics;

// Invokes main (making sure that it records the 'current-script' value).
#invokeMain;
})();
}''';

/// Deferred fragments (aka 'hunks') are built similarly to the main fragment.
///
/// However, at specific moments they need to contribute their data.
/// For example, once the holders have been created, they are included into
/// the main holders.
const String deferredBoilerplate = '''
{
#deferredInitializers.current =
function(inherit, mixin, lazy, makeConstList, installTearOff,
          updateHolder, updateTypes,
          setOrUpdateInterceptorsByTag, setOrUpdateLeafTags,
          #embeddedGlobalsObject, holdersList, #staticState) {

// Builds the holders. They only contain the data for new holders.
#holders;
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

updateTypes(#types);

// Native-support uses setOrUpdateInterceptorsByTag and setOrUpdateLeafTags.
#nativeSupport;

// Instantiates all constants of this deferred fragment.
// Note that the constant-holder has been updated earlier and storing the
// constant values in the constant-holder makes them available globally.
#constants;
// Initializes the static non-final fields (with their constant values).
#staticNonFinalFields;
// Creates lazy getters for statics that must run initializers on first access.
#lazyStatics;
};
// TODO(floitsch): this last line should be outside the AST, since it
// requires to know the hash of the part of the code above this comment.
#deferredInitializers[#hash] = #deferredInitializers.current;
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

  FragmentEmitter(this.compiler, this.namer, this.backend, this.constantEmitter,
      this.modelEmitter);

  js.Expression generateEmbeddedGlobalAccess(String global) =>
      modelEmitter.generateEmbeddedGlobalAccess(global);

  js.Expression generateConstantReference(ConstantValue value) =>
      modelEmitter.generateConstantReference(value);

  js.Expression classReference(Class cls) {
    return js.js('#.#', [cls.holder.name, cls.name]);
  }

  js.Statement emitMainFragment(Program program) {
    MainFragment fragment = program.fragments.first;

    return js.js.statement(mainBoilerplate,
        {'deferredInitializer': emitDeferredInitializerGlobal(program.loadMap),
         'typeNameProperty': js.string(ModelEmitter.typeNameProperty),
         'cyclicThrow': backend.emitter.staticFunctionAccess(
                 backend.getCyclicThrowHelper()),
         'operatorIsPrefix': js.string(namer.operatorIsPrefix),
         'embeddedTypes': generateEmbeddedGlobalAccess(TYPES),
         'embeddedInterceptorTags':
             generateEmbeddedGlobalAccess(INTERCEPTORS_BY_TAG),
         'embeddedLeafTags': generateEmbeddedGlobalAccess(LEAF_TAGS),
         'embeddedGlobalsObject': js.js("init"),
         'holdersList': new js.ArrayInitializer(program.holders.map((holder) {
           return js.js("#", holder.name);
         }).toList()),
         'staticStateDeclaration': new js.VariableDeclaration(
             namer.staticStateHolder, allowRename: false),
         'staticState': js.js('#', namer.staticStateHolder),
         'holders': emitHolders(program.holders, fragment),
         'callName': js.string(namer.callNameField),
         'argumentCount': js.string(namer.requiredParameterField),
         'defaultArgumentValues': js.string(namer.defaultValuesField),
         'prototypes': emitPrototypes(fragment),
         'inheritance': emitInheritance(fragment),
         'aliases': emitInstanceMethodAliases(fragment),
         'tearOffs': emitInstallTearOffs(fragment),
         'constants': emitConstants(fragment),
         'staticNonFinalFields': emitStaticNonFinalFields(fragment),
         'lazyStatics': emitLazilyInitializedStatics(fragment),
         'embeddedGlobals': emitEmbeddedGlobals(program),
         'nativeSupport': program.needsNativeSupport
              ? emitNativeSupport(fragment)
              : new js.EmptyStatement(),
         'invokeMain': fragment.invokeMain,
         });
  }

  js.Statement emitDeferredFragment(DeferredFragment fragment,
                                    js.Expression deferredTypes,
                                    List<Holder> holders) {
    List<js.Statement> updateHolderAssignments = <js.Statement>[];
    for (int i = 0; i < holders.length; i++) {
      Holder holder = holders[i];
      if (holder.isStaticStateHolder) continue;
      updateHolderAssignments.add(js.js.statement(
          '#holder = updateHolder(holdersList[#index], #holder)',
          {'index': js.number(i),
            'holder': new js.VariableUse(holder.name)}));
    }

    // TODO(floitsch): if name is not set, run through all functions and set the
    // name for IE.
    // TODO(floitsch): don't just reference 'init'.
    return js.js.statement(deferredBoilerplate,
    {'deferredInitializers':
          js.js('#', ModelEmitter.deferredInitializersGlobal),
      'embeddedGlobalsObject': new js.Parameter('init'),
      'staticState': new js.Parameter(namer.staticStateHolder),
      'holders': emitHolders(holders, fragment),
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
      'hash': js.number(fragment.hashCode),
    });
  }

  js.Statement emitDeferredInitializerGlobal(Map loadMap) {
    if (loadMap.isEmpty) return new js.Block.empty();

    return js.js.statement("""
    if (typeof(${ModelEmitter.deferredInitializersGlobal}) === 'undefined')
      var ${ModelEmitter.deferredInitializersGlobal} = Object.create(null);""");
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
        holderCode[method.holder].addAll(emitStaticMethod(method));
      }
      for (Class cls in library.classes) {
        assert(!cls.holder.isStaticStateHolder);
        holderCode[cls.holder][cls.name] = emitConstructor(cls);
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
      new js.ExpressionStatement(
          new js.VariableDeclarationList(holders
              .map(emitHolderInitialization)
              .toList())),
      js.js.statement('var holders = #', new js.ArrayInitializer(
          holders
              .map((holder) => new js.VariableUse(holder.name))
              .toList(growable: false)))];
    return new js.Block(statements);
  }

  /// Emits the given [method].
  ///
  /// A Dart method might result in several JavaScript functions, if it
  /// requires stubs. The returned map contains the original method and all
  /// the stubs it needs.
  Map<js.Name, js.Expression> emitStaticMethod(StaticMethod method) {
    Map<js.Name, js.Expression> jsMethods = <js.Name, js.Expression>{};

    jsMethods[method.name] = method.code;
    // TODO(floitsch): can there be anything else than a StaticDartMethod?
    if (method is StaticDartMethod) {
      for (ParameterStubMethod stubMethod in method.parameterStubs) {
        jsMethods[stubMethod.name] = stubMethod.code;
      }
    }

    return jsMethods;
  }

  /// Emits a constructor for the given class [cls].
  ///
  /// The constructor is statically built.
  js.Expression emitConstructor(Class cls) {
    List<js.Name> fieldNames = const <js.Name>[];

    // If the class is not directly instantiated we only need it for inheritance
    // or RTI. In either case we don't need its fields.
    if (cls.isDirectlyInstantiated && !cls.isNative) {
      fieldNames = cls.fields.map((Field field) => field.name).toList();
    }
    js.Name name = cls.name;

    Iterable<js.Name> assignments = fieldNames.map((js.Name field) {
      return js.js("this.#field = #field", {"field": field});
    });

    return js.js('function #(#) { # }', [name, fieldNames, assignments]);
  }

  /// Emits the prototype-section of the fragment.
  ///
  /// This section updates the prototype-property of all constructors in the
  /// global holders.
  js.Statement emitPrototypes(Fragment fragment) {
    List<js.Statement> assignments = fragment.libraries
        .expand((Library library) => library.classes)
        .map((Class cls) => js.js.statement(
            '#.prototype = #;',
            [classReference(cls), emitPrototype(cls)]))
        .toList(growable: false);

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
    Iterable<Method> isChecks = cls.isChecks;
    Iterable<Method> callStubs = cls.callStubs;
    Iterable<Method> typeVariableReaderStubs = cls.typeVariableReaderStubs;
    Iterable<Method> noSuchMethodStubs = cls.noSuchMethodStubs;
    Iterable<Method> gettersSetters = generateGettersSetters(cls);
    Iterable<Method> allMethods =
    [methods, isChecks, callStubs, typeVariableReaderStubs,
    noSuchMethodStubs, gettersSetters].expand((x) => x);

    List<js.Property> properties = <js.Property>[];

    if (cls.superclass == null) {
      properties.add(new js.Property(js.string("constructor"),
      classReference(cls)));
      properties.add(new js.Property(namer.operatorIs(cls.element),
      js.number(1)));
    }

    allMethods.forEach((Method method) {
      emitInstanceMethod(method).forEach((js.Name name, js.Expression code) {
        properties.add(new js.Property(name, code));
      });
    });

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
  Map<js.Name, js.Expression> emitInstanceMethod(Method method) {
    Map<js.Name, js.Expression> jsMethods = <js.Name, js.Expression>{};

    jsMethods[method.name] = method.code;
    if (method is InstanceMethod) {
      for (ParameterStubMethod stubMethod in method.parameterStubs) {
        jsMethods[stubMethod.name] = stubMethod.code;
      }
    }

    return jsMethods;
  }

  /// Emits the inheritance block of the fragment.
  ///
  /// In this section prototype chains are updated and mixin functions are
  /// copied.
  js.Statement emitInheritance(Fragment fragment) {
    List<js.Expression> inheritCalls = <js.Expression>[];
    List<js.Expression> mixinCalls = <js.Expression>[];

    for (Library library in fragment.libraries) {
      for (Class cls in library.classes) {
        js.Expression superclassReference = (cls.superclass == null)
            ? new js.LiteralNull()
            : classReference(cls.superclass);

        inheritCalls.add(js.js('inherit(#, #)',
            [classReference(cls), superclassReference]));

        if (cls.isMixinApplication) {
          MixinApplication mixin = cls;
          mixinCalls.add(js.js('mixin(#, #)',
              [classReference(cls), classReference(mixin.mixinClass)]));
        }
      }
    }

    return new js.Block([inheritCalls, mixinCalls]
        .expand((e) => e)
        .map((e) => new js.ExpressionStatement(e))
        .toList(growable: false));
  }

  /// Emits the setup of method aliases.
  ///
  /// This step consists of simply copying JavaScript functions to their
  /// aliased names so they point to the same function.
  js.Statement emitInstanceMethodAliases(Fragment fragment) {
    List<js.Statement> assignments = <js.Statement>[];

    for (Library library in fragment.libraries) {
      for (Class cls in library.classes) {
        for (InstanceMethod method in cls.methods) {
          if (method.aliasName != null) {
            assignments.add(js.js.statement(
                '#.prototype.# = #.prototype.#',
                [classReference(cls), js.quoteName(method.aliasName),
                 classReference(cls), js.quoteName(method.name)]));

          }
        }
      }
    }
    return new js.Block(assignments);
  }

  /// Emits the section that installs tear-off getters.
  js.Statement emitInstallTearOffs(fragment) {
    throw new UnimplementedError('emitInstallTearOffs');
  }

  /// Emits the constants section.
  js.Statement emitConstants(Fragment fragment) {
    List<js.Statement> assignments = <js.Statement>[];
    for (Constant constant in fragment.constants) {
      // TODO(floitsch): instead of just updating the constant holder, we should
      // find the constants that don't have any dependency on other constants
      // and create an object-literal with them (and assign it to the
      // constant-holder variable).
      assignments.add(js.js.statement('#.# = #',
          [constant.holder.name,
           constant.name,
           constantEmitter.generate(constant.value)]));
    }
    return new js.Block(assignments);
  }


  /// Emits the static non-final fields section.
  ///
  /// This section initializes all static non-final fields that don't require
  /// an initializer.
  js.Block emitStaticNonFinalFields(Fragment fragment) {
    List<StaticField> fields = fragment.staticNonFinalFields;
    // TODO(floitsch): instead of assigning the fields one-by-one we should
    // create a literal and assign it to the static-state holder.
    // TODO(floitsch): if we don't make a literal we should at least initialize
    // statics that have the same initial value in the same expression:
    //    `$.x = $.y = $.z = null;`.
    Iterable<js.Statement> statements = fields.map((StaticField field) {
      assert(field.holder.isStaticStateHolder);
      return js.js.statement("#.# = #;",
          [field.holder.name, field.name, field.code]);
    });
    return new js.Block(statements.toList());
  }

  /// Emits lazy fields.
  ///
  /// This section initializes all static (final and non-final) fields that
  /// require an initializer.
  js.Block emitLazilyInitializedStatics(Fragment fragment) {
    List<StaticField> fields = fragment.staticLazilyInitializedFields;
    Iterable<js.Statement> statements = fields.map((StaticField field) {
      assert(field.holder.isStaticStateHolder);
      return js.js.statement("lazy(#, #, #, #);",
          [field.holder.name,
           js.quoteName(field.name),
           js.quoteName(namer.deriveLazyInitializerName(field.name)),
           field.code]);
    });

    return new js.Block(statements.toList());
  }

  emitEmbeddedGlobals(program) {
    throw new UnimplementedError('emitEmbeddedGlobals');
  }

  emitNativeSupport(fragment) {
    throw new UnimplementedError('emitNativeSupport');
  }
}