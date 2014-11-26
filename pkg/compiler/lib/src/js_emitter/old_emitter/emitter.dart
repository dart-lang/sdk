// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;


class OldEmitter implements Emitter {
  final Compiler compiler;
  final CodeEmitterTask task;

  final ContainerBuilder containerBuilder = new ContainerBuilder();
  final ClassEmitter classEmitter = new ClassEmitter();
  final NsmEmitter nsmEmitter = new NsmEmitter();
  TypeTestEmitter get typeTestEmitter => task.typeTestEmitter;
  final InterceptorEmitter interceptorEmitter = new InterceptorEmitter();
  final MetadataEmitter metadataEmitter = new MetadataEmitter();

  final Set<ConstantValue> cachedEmittedConstants;
  final CodeBuffer cachedEmittedConstantsBuffer = new CodeBuffer();
  final Map<Element, ClassBuilder> cachedClassBuilders;
  final Set<Element> cachedElements;

  bool needsDefineClass = false;
  bool needsMixinSupport = false;
  bool needsLazyInitializer = false;
  final Namer namer;
  ConstantEmitter constantEmitter;
  NativeEmitter get nativeEmitter => task.nativeEmitter;

  // The full code that is written to each hunk part-file.
  Map<OutputUnit, CodeBuffer> outputBuffers = new Map<OutputUnit, CodeBuffer>();
  final CodeBuffer deferredConstants = new CodeBuffer();

  /** Shorter access to [isolatePropertiesName]. Both here in the code, as
      well as in the generated code. */
  String isolateProperties;
  String classesCollector;
  Set<ClassElement> get neededClasses => task.neededClasses;
  Map<OutputUnit, List<ClassElement>> get outputClassLists
      => task.outputClassLists;
  Map<OutputUnit, List<ConstantValue>> get outputConstantLists
      => task.outputConstantLists;
  List<ClassElement> get nativeClasses => task.nativeClasses;
  final Map<String, String> mangledFieldNames = <String, String>{};
  final Map<String, String> mangledGlobalFieldNames = <String, String>{};
  final Set<String> recordedMangledNames = new Set<String>();

  final Map<ClassElement, Map<String, jsAst.Expression>> additionalProperties =
      new Map<ClassElement, Map<String, jsAst.Expression>>();

  List<TypedefElement> get typedefsNeededForReflection =>
      task.typedefsNeededForReflection;

  JavaScriptBackend get backend => compiler.backend;
  TypeVariableHandler get typeVariableHandler => backend.typeVariableHandler;

  String get _ => space;
  String get space => compiler.enableMinification ? "" : " ";
  String get n => compiler.enableMinification ? "" : "\n";
  String get N => compiler.enableMinification ? "\n" : ";\n";

  CodeBuffer getBuffer(OutputUnit outputUnit) {
    return outputBuffers.putIfAbsent(outputUnit, () => new CodeBuffer());
  }

  CodeBuffer get mainBuffer {
    return getBuffer(compiler.deferredLoadTask.mainOutputUnit);
  }

  /**
   * List of expressions and statements that will be included in the
   * precompiled function.
   *
   * To save space, dart2js normally generates constructors and accessors
   * dynamically. This doesn't work in CSP mode, and may impact startup time
   * negatively. So dart2js will emit these functions to a separate file that
   * can be optionally included to support CSP mode or for faster startup.
   */
  Map<OutputUnit, List<jsAst.Node>> _cspPrecompiledFunctions =
      new Map<OutputUnit, List<jsAst.Node>>();

  Map<OutputUnit, List<jsAst.Expression>> _cspPrecompiledConstructorNames =
      new Map<OutputUnit, List<jsAst.Expression>>();

  /**
   * Accumulate properties for classes and libraries, describing their
   * static/top-level members.
   * Later, these members are emitted when the class or library is emitted.
   *
   * See [getElementDescriptor].
   */
  // TODO(ahe): Generate statics with their class, and store only libraries in
  // this map.
  final Map<Element, ClassBuilder> elementDescriptors =
      new Map<Element, ClassBuilder>();

  final bool generateSourceMap;

  OldEmitter(Compiler compiler, Namer namer, this.generateSourceMap, this.task)
      : this.compiler = compiler,
        this.namer = namer,
        cachedEmittedConstants = compiler.cacheStrategy.newSet(),
        cachedClassBuilders = compiler.cacheStrategy.newMap(),
        cachedElements = compiler.cacheStrategy.newSet() {
    constantEmitter =
        new ConstantEmitter(compiler, namer, makeConstantListTemplate);
    containerBuilder.emitter = this;
    classEmitter.emitter = this;
    nsmEmitter.emitter = this;
    interceptorEmitter.emitter = this;
    metadataEmitter.emitter = this;
  }

  List<jsAst.Node> cspPrecompiledFunctionFor(OutputUnit outputUnit) {
    return _cspPrecompiledFunctions.putIfAbsent(
        outputUnit,
        () => new List<jsAst.Node>());
  }

  List<jsAst.Expression> cspPrecompiledConstructorNamesFor(
      OutputUnit outputUnit) {
    return _cspPrecompiledConstructorNames.putIfAbsent(
        outputUnit,
        () => new List<jsAst.Expression>());
  }

  /// Erases the precompiled information for csp mode for all output units.
  /// Used by the incremental compiler.
  void clearCspPrecompiledNodes() {
    _cspPrecompiledFunctions.clear();
    _cspPrecompiledConstructorNames.clear();
  }

  void addComment(String comment, CodeBuffer buffer) {
    buffer.write(jsAst.prettyPrint(js.comment(comment), compiler));
  }

  jsAst.Expression constantReference(ConstantValue value) {
    return constantEmitter.reference(value);
  }

  jsAst.Expression constantInitializerExpression(ConstantValue value) {
    return constantEmitter.initializationExpression(value);
  }

  String get name => 'CodeEmitter';

  String get currentGenerateAccessorName
      => '${namer.currentIsolate}.\$generateAccessor';
  String get generateAccessorHolder
      => '$isolatePropertiesName.\$generateAccessor';
  String get finishClassesProperty
      => r'$finishClasses';
  String get finishClassesName
      => '${namer.isolateName}.$finishClassesProperty';
  String get finishIsolateConstructorName
      => '${namer.isolateName}.\$finishIsolateConstructor';
  String get isolatePropertiesName
      => '${namer.isolateName}.${namer.isolatePropertiesName}';
  String get lazyInitializerName
      => '${namer.isolateName}.\$lazy';
  String get initName => 'init';
  String get makeConstListProperty
      => namer.getMappedInstanceName('makeConstantList');

  /// For deferred loading we communicate the initializers via this global var.
  final String deferredInitializers = r"$dart_deferred_initializers";

  /// All the global state can be passed around with this variable.
  String get globalsHolder => namer.getMappedGlobalName("globalsHolder");

  jsAst.Expression generateEmbeddedGlobalAccess(String global) {
    return js(generateEmbeddedGlobalAccessString(global));
  }

  String generateEmbeddedGlobalAccessString(String global) {
    // TODO(floitsch): don't use 'init' as global embedder storage.
    return '$initName.$global';
  }

  jsAst.FunctionDeclaration get generateAccessorFunction {
    const RANGE1_SIZE = RANGE1_LAST - RANGE1_FIRST + 1;
    const RANGE2_SIZE = RANGE2_LAST - RANGE2_FIRST + 1;
    const RANGE1_ADJUST = - (FIRST_FIELD_CODE - RANGE1_FIRST);
    const RANGE2_ADJUST = - (FIRST_FIELD_CODE + RANGE1_SIZE - RANGE2_FIRST);
    const RANGE3_ADJUST =
        - (FIRST_FIELD_CODE + RANGE1_SIZE + RANGE2_SIZE - RANGE3_FIRST);

    String receiverParamName = compiler.enableMinification ? "r" : "receiver";
    String valueParamName = compiler.enableMinification ? "v" : "value";
    String reflectableField = namer.reflectableField;

    return js.statement('''
      function generateAccessor(fieldDescriptor, accessors, cls) {
        var fieldInformation = fieldDescriptor.split("-");
        var field = fieldInformation[0];
        var len = field.length;
        var code = field.charCodeAt(len - 1);
        var reflectable;
        if (fieldInformation.length > 1) reflectable = true;
             else reflectable = false;
        code = ((code >= $RANGE1_FIRST) && (code <= $RANGE1_LAST))
              ? code - $RANGE1_ADJUST
              : ((code >= $RANGE2_FIRST) && (code <= $RANGE2_LAST))
                ? code - $RANGE2_ADJUST
                : ((code >= $RANGE3_FIRST) && (code <= $RANGE3_LAST))
                  ? code - $RANGE3_ADJUST
                  : $NO_FIELD_CODE;

        if (code) {  // needsAccessor
          var getterCode = code & 3;
          var setterCode = code >> 2;
          var accessorName = field = field.substring(0, len - 1);

          var divider = field.indexOf(":");
          if (divider > 0) { // Colon never in first position.
            accessorName = field.substring(0, divider);
            field = field.substring(divider + 1);
          }

          if (getterCode) {  // needsGetter
            var args = (getterCode & 2) ? "$receiverParamName" : "";
            var receiver = (getterCode & 1) ? "this" : "$receiverParamName";
            var body = "return " + receiver + "." + field;
            var property =
                cls + ".prototype.${namer.getterPrefix}" + accessorName + "=";
            var fn = "function(" + args + "){" + body + "}";
            if (reflectable)
              accessors.push(property + "\$reflectable(" + fn + ");\\n");
            else
              accessors.push(property + fn + ";\\n");
          }

          if (setterCode) {  // needsSetter
            var args = (setterCode & 2)
                ? "$receiverParamName,${_}$valueParamName"
                : "$valueParamName";
            var receiver = (setterCode & 1) ? "this" : "$receiverParamName";
            var body = receiver + "." + field + "$_=$_$valueParamName";
            var property =
                cls + ".prototype.${namer.setterPrefix}" + accessorName + "=";
            var fn = "function(" + args + "){" + body + "}";
            if (reflectable)
              accessors.push(property + "\$reflectable(" + fn + ");\\n");
            else
              accessors.push(property + fn + ";\\n");
          }
        }

        return field;
      }''');
  }

  List get defineClassFunction {
    // First the class name, then the field names in an array and the members
    // (inside an Object literal).
    // The caller can also pass in the constructor as a function if needed.
    //
    // Example:
    // defineClass("A", ["x", "y"], {
    //  foo$1: function(y) {
    //   print(this.x + y);
    //  },
    //  bar$2: function(t, v) {
    //   this.x = t - v;
    //  },
    // });

    var defineClass = js('''function(name, fields) {
      var accessors = [];

      var str = "function " + name + "(";
      var body = "";

      for (var i = 0; i < fields.length; i++) {
        if(i != 0) str += ", ";

        var field = generateAccessor(fields[i], accessors, name);
        var parameter = "parameter_" + field;
        str += parameter;
        body += ("this." + field + " = " + parameter + ";\\n");
      }
      str += ") {\\n" + body + "}\\n";
      str += name + ".builtin\$cls=\\"" + name + "\\";\\n";
      str += "\$desc=\$collectedClasses." + name + ";\\n";
      str += "if(\$desc instanceof Array) \$desc = \$desc[1];\\n";
      str += name + ".prototype = \$desc;\\n";
      if (typeof defineClass.name != "string") {
        str += name + ".name=\\"" + name + "\\";\\n";
      }
      str += accessors.join("");

      return str;
    }''');
    // Declare a function called "generateAccessor".  This is used in
    // defineClassFunction (it's a local declaration in init()).
    List<jsAst.Node> saveDefineClass = [];
    if (compiler.hasIncrementalSupport) {
      saveDefineClass.add(
          js(r'self.$dart_unsafe_eval.defineClass = defineClass'));
    }
    return [
        generateAccessorFunction,
        js('$generateAccessorHolder = generateAccessor'),
        new jsAst.FunctionDeclaration(
            new jsAst.VariableDeclaration('defineClass'), defineClass) ]
        ..addAll(saveDefineClass);
  }

  /** Needs defineClass to be defined. */
  jsAst.Expression buildInheritFrom() {
    jsAst.Expression result = js(r'''
        function() {
          function tmp() {}
          var hasOwnProperty = Object.prototype.hasOwnProperty;
          return function (constructor, superConstructor) {
            tmp.prototype = superConstructor.prototype;
            var object = new tmp();
            var properties = constructor.prototype;
            for (var member in properties) {
              if (hasOwnProperty.call(properties, member)) {
                object[member] = properties[member];
              }
            }
            object.constructor = constructor;
            constructor.prototype = object;
            return object;
          };
        }()
      ''');
    if (compiler.hasIncrementalSupport) {
      result = js(r'self.$dart_unsafe_eval.inheritFrom = #', [result]);
    }
    return js(r'var inheritFrom = #', [result]);
  }

  /// Code that needs to be run before first invocation of
  /// [finishClassesFunction], but should only be run once.
  jsAst.Expression get initFinishClasses {
    jsAst.Expression allClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.ALL_CLASSES);
    jsAst.Expression interceptorsByTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.INTERCEPTORS_BY_TAG);
    jsAst.Expression leafTagsAccess =
        generateEmbeddedGlobalAccess(embeddedNames.LEAF_TAGS);
    jsAst.Expression finishedClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.FINISHED_CLASSES);

    return js('''
        (function(){
         # = Object.create(null);  // embedded allClasses.
         # = Object.create(null);  // embedded interceptorsByTag.
         # = Object.create(null);  // embedded leafTags.
         # = Object.create(null);  // embedded finishedClasses
        })()
      ''', [allClassesAccess,
            interceptorsByTagAccess,
            leafTagsAccess,
            finishedClassesAccess]);
  }

  jsAst.Fun get finishClassesFunction {
    // Class descriptions are collected in a JS object.
    // 'finishClasses' takes all collected descriptions and sets up
    // the prototype.
    // Once set up, the constructors prototype field satisfy:
    //  - it contains all (local) members.
    //  - its internal prototype (__proto__) points to the superclass'
    //    prototype field.
    //  - the prototype's constructor field points to the JavaScript
    //    constructor.
    // For engines where we have access to the '__proto__' we can manipulate
    // the object literal directly. For other engines we have to create a new
    // object and copy over the members.

    String reflectableField = namer.reflectableField;
    jsAst.Expression allClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.ALL_CLASSES);
    jsAst.Expression metadataAccess =
        generateEmbeddedGlobalAccess(embeddedNames.METADATA);

    return js('''
      function(collectedClasses, isolateProperties, existingIsolateProperties) {
        var pendingClasses = Object.create(null);
        var allClasses = #allClasses;
        var constructors;

        if (#debugFastObjects)
          print("Number of classes: " +
              Object.getOwnPropertyNames(\$\$).length);

        var hasOwnProperty = Object.prototype.hasOwnProperty;

        if (typeof dart_precompiled == "function") {
          constructors = dart_precompiled(collectedClasses);
        } else {
          var combinedConstructorFunction =
             "function \$reflectable(fn){fn.$reflectableField=1;return fn};\\n"+
             "var \$desc;\\n";
          var constructorsList = [];
        }

        for (var cls in collectedClasses) {
          var desc = collectedClasses[cls];
          if (desc instanceof Array) desc = desc[1];

          /* The 'fields' are either a constructor function or a
           * string encoding fields, constructor and superclass. Gets the
           * superclass and fields in the format
           *   'Super;field1,field2'
           * from the CLASS_DESCRIPTOR_PROPERTY property on the descriptor.
           */
          var classData = desc["${namer.classDescriptorProperty}"],
              supr, fields = classData;
          if (#hasRetainedMetadata)
            if (typeof classData == "object" &&
                classData instanceof Array) {
              classData = fields = classData[0];
            }
          var s = fields.split(";");
          fields = s[1] == "" ? [] : s[1].split(",");
          supr = s[0];
          split = supr.split(":");
          if (split.length == 2) {
            supr = split[0];
            var functionSignature = split[1];
            if (functionSignature)
              desc.\$signature = (function(s) {
                  return function(){ return #metadata[s]; };
                })(functionSignature);
          }

          if (#needsMixinSupport)
            if (supr && supr.indexOf("+") > 0) {
              s = supr.split("+");
              supr = s[0];
              var mixin = collectedClasses[s[1]];
              if (mixin instanceof Array) mixin = mixin[1];
              for (var d in mixin) {
                if (hasOwnProperty.call(mixin, d) &&
                    !hasOwnProperty.call(desc, d))
                  desc[d] = mixin[d];
              }
            }

          if (typeof dart_precompiled != "function") {
            combinedConstructorFunction += defineClass(cls, fields);
            constructorsList.push(cls);
          }
          if (supr) pendingClasses[cls] = supr;
        }

        if (typeof dart_precompiled != "function") {
          combinedConstructorFunction +=
             "return [\\n  " + constructorsList.join(",\\n  ") + "\\n]";
           var constructors =
            new Function("\$collectedClasses", combinedConstructorFunction)
            (collectedClasses);
          combinedConstructorFunction = null;
        }

        for (var i = 0; i < constructors.length; i++) {
          var constructor = constructors[i];
          var cls = constructor.name;
          var desc = collectedClasses[cls];
          var globalObject = isolateProperties;
          if (desc instanceof Array) {
            globalObject = desc[0] || isolateProperties;
            desc = desc[1];
          }
          if (#isTreeShakingDisabled)
            constructor["${namer.metadataField}"] = desc;
          allClasses[cls] = constructor;
          globalObject[cls] = constructor;
        }

        constructors = null;

        #finishClassFunction;

        #trivialNsmHandlers;

        for (var cls in pendingClasses) finishClass(cls);
      }''', { 'allClasses': allClassesAccess,
              'debugFastObjects': DEBUG_FAST_OBJECTS,
              'hasRetainedMetadata': backend.hasRetainedMetadata,
              'metadata': metadataAccess,
              'needsMixinSupport': needsMixinSupport,
              'isTreeShakingDisabled': backend.isTreeShakingDisabled,
              'finishClassFunction': buildFinishClass(),
              'trivialNsmHandlers': nsmEmitter.buildTrivialNsmHandlers()});
  }

  jsAst.Node optional(bool condition, jsAst.Node node) {
    return condition ? node : new jsAst.EmptyStatement();
  }

  jsAst.Statement buildFinishClass() {
    String specProperty = '"${namer.nativeSpecProperty}"';  // "%"

    jsAst.Expression finishedClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.FINISHED_CLASSES);
    jsAst.Expression interceptorsByTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.INTERCEPTORS_BY_TAG);
    jsAst.Expression leafTagsAccess =
        generateEmbeddedGlobalAccess(embeddedNames.LEAF_TAGS);

    return js.statement('''
    {
      var finishedClasses = #finishedClassesAccess;

      function finishClass(cls) {

        if (finishedClasses[cls]) return;
        finishedClasses[cls] = true;

        var superclass = pendingClasses[cls];
        // The superclass is only false (empty string) for the Dart Object
        // class.  The minifier together with noSuchMethod can put methods on
        // the Object.prototype object, and they show through here, so we check
        // that we have a string.
        if (!superclass || typeof superclass != "string") return;
        finishClass(superclass);
        var superConstructor = allClasses[superclass];

        if (!superConstructor)
          superConstructor = existingIsolateProperties[superclass];

        var constructor = allClasses[cls];
        var prototype = inheritFrom(constructor, superConstructor);

        if (#hasNativeClasses) {
          // The property looks like this:
          //
          // HtmlElement: {
          //     "%": "HTMLDivElement|HTMLAnchorElement;HTMLElement;FancyButton"
          //
          // The first two semicolon-separated parts contain dispatch tags, the
          // third contains the JavaScript names for classes.
          //
          // The tags indicate that JavaScript objects with the dispatch tags
          // (usually constructor names) HTMLDivElement, HTMLAnchorElement and
          // HTMLElement all map to the Dart native class named HtmlElement.
          // The first set is for effective leaf nodes in the hierarchy, the
          // second set is non-leaf nodes.
          //
          // The third part contains the JavaScript names of Dart classes that
          // extend the native class. Here, FancyButton extends HtmlElement, so
          // the runtime needs to know that window.HTMLElement.prototype is the
          // prototype that needs to be extended in creating the custom element.
          //
          // The information is used to build tables referenced by
          // getNativeInterceptor and custom element support.
          if (Object.prototype.hasOwnProperty.call(prototype, $specProperty)) {
            var nativeSpec = prototype[$specProperty].split(";");
            if (nativeSpec[0]) {
              var tags = nativeSpec[0].split("|");
              for (var i = 0; i < tags.length; i++) {
                #interceptorsByTagAccess[tags[i]] = constructor;
                #leafTagsAccess[tags[i]] = true;
              }
            }
            if (nativeSpec[1]) {
              tags = nativeSpec[1].split("|");
              if (#allowNativesSubclassing) {
                if (nativeSpec[2]) {
                  var subclasses = nativeSpec[2].split("|");
                  for (var i = 0; i < subclasses.length; i++) {
                    var subclass = allClasses[subclasses[i]];
                    subclass.\$nativeSuperclassTag = tags[0];
                  }
                }
                for (i = 0; i < tags.length; i++) {
                  #interceptorsByTagAccess[tags[i]] = constructor;
                  #leafTagsAccess[tags[i]] = false;
                }
              }
            }
          }
        }
      }
    }''', {'finishedClassesAccess': finishedClassesAccess,
           'hasNativeClasses': nativeClasses.isNotEmpty,
           'interceptorsByTagAccess': interceptorsByTagAccess,
           'leafTagsAccess': leafTagsAccess,
           'allowNativesSubclassing': true});
  }

  jsAst.Fun get finishIsolateConstructorFunction {
    // We replace the old Isolate function with a new one that initializes
    // all its fields with the initial (and often final) value of all globals.
    //
    // We also copy over old values like the prototype, and the
    // isolateProperties themselves.
    return js('''
      function (oldIsolate) {
        var isolateProperties = oldIsolate.#;  // isolatePropertiesName
        function Isolate() {
          var hasOwnProperty = Object.prototype.hasOwnProperty;
          for (var staticName in isolateProperties)
            if (hasOwnProperty.call(isolateProperties, staticName))
              this[staticName] = isolateProperties[staticName];

          // Reset lazy initializers to null.
          // When forcing the object to fast mode (below) v8 will consider
          // functions as part the object's map. Since we will change them
          // (after the first call to the getter), we would have a map
          // transition.
          var lazies = init.lazies;
          for (var lazyInit in lazies) {
             this[lazies[lazyInit]] = null;
          }

          // Use the newly created object as prototype. In Chrome,
          // this creates a hidden class for the object and makes
          // sure it is fast to access.
          function ForceEfficientMap() {}
          ForceEfficientMap.prototype = this;
          new ForceEfficientMap();

          // Now, after being a fast map we can set the lazies again.
          for (var lazyInit in lazies) {
            var lazyInitName = lazies[lazyInit];
            this[lazyInitName] = isolateProperties[lazyInitName];
          }
        }
        Isolate.prototype = oldIsolate.prototype;
        Isolate.prototype.constructor = Isolate;
        Isolate.# = isolateProperties;  // isolatePropertiesName
        if (#)  // needsDefineClass.
          Isolate.# = oldIsolate.#;  // finishClassesProperty * 2
        if (#)  // outputContainsConstantList
          Isolate.# = oldIsolate.#; // makeConstListProperty * 2
        return Isolate;
      }''',
        [namer.isolatePropertiesName, namer.isolatePropertiesName,
         needsDefineClass, finishClassesProperty, finishClassesProperty,
         task.outputContainsConstantList,
         makeConstListProperty, makeConstListProperty ]);
  }

  jsAst.Fun get lazyInitializerFunction {
    String isolate = namer.currentIsolate;
    jsAst.Expression cyclicThrow =
        namer.elementAccess(backend.getCyclicThrowHelper());
    jsAst.Expression laziesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.LAZIES);

    return js('''
      function (prototype, staticName, fieldName, getterName, lazyValue) {
        if (!#) # = Object.create(null);
        #[fieldName] = getterName;

        var sentinelUndefined = {};
        var sentinelInProgress = {};
        prototype[fieldName] = sentinelUndefined;

        prototype[getterName] = function () {
          var result = $isolate[fieldName];
          try {
            if (result === sentinelUndefined) {
              $isolate[fieldName] = sentinelInProgress;

              try {
                result = $isolate[fieldName] = lazyValue();
              } finally {
                // Use try-finally, not try-catch/throw as it destroys the
                // stack trace.
                if (result === sentinelUndefined)
                  $isolate[fieldName] = null;
              }
            } else {
              if (result === sentinelInProgress)
                #(staticName);
            }

            return result;
          } finally {
            $isolate[getterName] = function() { return this[fieldName]; };
          }
        }
      }
    ''', [laziesAccess, laziesAccess,
          laziesAccess,
          cyclicThrow]);
  }

  List buildDefineClassAndFinishClassFunctionsIfNecessary() {
    if (!needsDefineClass) return [];
    return defineClassFunction
        ..add(buildInheritFrom())
        ..add(js('$finishClassesName = #', finishClassesFunction))
        ..add(initFinishClasses);
  }

  List buildLazyInitializerFunctionIfNecessary() {
    if (!needsLazyInitializer) return [];

    return [js('# = #', [js(lazyInitializerName), lazyInitializerFunction])];
  }

  List buildFinishIsolateConstructor() {
    return [
      js('$finishIsolateConstructorName = #', finishIsolateConstructorFunction)
    ];
  }

  void emitFinishIsolateConstructorInvocation(CodeBuffer buffer) {
    String isolate = namer.isolateName;
    buffer.write("$isolate = $finishIsolateConstructorName($isolate)$N");
  }

  /// In minified mode we want to keep the name for the most common core types.
  bool _isNativeTypeNeedingReflectionName(Element element) {
    if (!element.isClass) return false;
    return (element == compiler.intClass ||
            element == compiler.doubleClass ||
            element == compiler.numClass ||
            element == compiler.stringClass ||
            element == compiler.boolClass ||
            element == compiler.nullClass ||
            element == compiler.listClass);
  }

  /// Returns the "reflection name" of an [Element] or [Selector].
  /// The reflection name of a getter 'foo' is 'foo'.
  /// The reflection name of a setter 'foo' is 'foo='.
  /// The reflection name of a method 'foo' is 'foo:N:M:O', where N is the
  /// number of required arguments, M is the number of optional arguments, and
  /// O is the named arguments.
  /// The reflection name of a constructor is similar to a regular method but
  /// starts with 'new '.
  /// The reflection name of class 'C' is 'C'.
  /// An anonymous mixin application has no reflection name.
  /// This is used by js_mirrors.dart.
  String getReflectionName(elementOrSelector, String mangledName) {
    String name = elementOrSelector.name;
    if (backend.shouldRetainName(name) ||
        elementOrSelector is Element &&
        // Make sure to retain names of unnamed constructors, and
        // for common native types.
        ((name == '' &&
          backend.isAccessibleByReflection(elementOrSelector)) ||
         _isNativeTypeNeedingReflectionName(elementOrSelector))) {

      // TODO(ahe): Enable the next line when I can tell the difference between
      // an instance method and a global.  They may have the same mangled name.
      // if (recordedMangledNames.contains(mangledName)) return null;
      recordedMangledNames.add(mangledName);
      return getReflectionNameInternal(elementOrSelector, mangledName);
    }
    return null;
  }

  String getReflectionNameInternal(elementOrSelector, String mangledName) {
    String name =
        namer.privateName(elementOrSelector.library, elementOrSelector.name);
    if (elementOrSelector.isGetter) return name;
    if (elementOrSelector.isSetter) {
      if (!mangledName.startsWith(namer.setterPrefix)) return '$name=';
      String base = mangledName.substring(namer.setterPrefix.length);
      String getter = '${namer.getterPrefix}$base';
      mangledFieldNames.putIfAbsent(getter, () => name);
      assert(mangledFieldNames[getter] == name);
      recordedMangledNames.add(getter);
      // TODO(karlklose,ahe): we do not actually need to store information
      // about the name of this setter in the output, but it is needed for
      // marking the function as invokable by reflection.
      return '$name=';
    }
    if (elementOrSelector is Element && elementOrSelector.isClosure) {
      // Closures are synthesized and their name might conflict with existing
      // globals. Assign an illegal name, and make sure they don't clash
      // with each other.
      return " $mangledName";
    }
    if (elementOrSelector is Selector
        || elementOrSelector.isFunction
        || elementOrSelector.isConstructor) {
      int requiredParameterCount;
      int optionalParameterCount;
      String namedArguments = '';
      bool isConstructor = false;
      if (elementOrSelector is Selector) {
        Selector selector = elementOrSelector;
        requiredParameterCount = selector.argumentCount;
        optionalParameterCount = 0;
        namedArguments = namedParametersAsReflectionNames(selector);
      } else {
        FunctionElement function = elementOrSelector;
        if (function.isConstructor) {
          isConstructor = true;
          name = Elements.reconstructConstructorName(function);
        }
        FunctionSignature signature = function.functionSignature;
        requiredParameterCount = signature.requiredParameterCount;
        optionalParameterCount = signature.optionalParameterCount;
        if (signature.optionalParametersAreNamed) {
          var names = [];
          for (Element e in signature.optionalParameters) {
            names.add(e.name);
          }
          Selector selector = new Selector.call(
              function.name,
              function.library,
              requiredParameterCount,
              names);
          namedArguments = namedParametersAsReflectionNames(selector);
        } else {
          // Named parameters are handled differently by mirrors.  For unnamed
          // parameters, they are actually required if invoked
          // reflectively. Also, if you have a method c(x) and c([x]) they both
          // get the same mangled name, so they must have the same reflection
          // name.
          requiredParameterCount += optionalParameterCount;
          optionalParameterCount = 0;
        }
      }
      String suffix =
          // TODO(ahe): We probably don't need optionalParameterCount in the
          // reflection name.
          '$name:$requiredParameterCount:$optionalParameterCount'
          '$namedArguments';
      return (isConstructor) ? 'new $suffix' : suffix;
    }
    Element element = elementOrSelector;
    if (element.isGenerativeConstructorBody) {
      return null;
    } else if (element.isClass) {
      ClassElement cls = element;
      if (cls.isUnnamedMixinApplication) return null;
      return cls.name;
    } else if (element.isTypedef) {
      return element.name;
    }
    throw compiler.internalError(element,
        'Do not know how to reflect on this $element.');
  }

  String namedParametersAsReflectionNames(Selector selector) {
    if (selector.getOrderedNamedArguments().isEmpty) return '';
    String names = selector.getOrderedNamedArguments().join(':');
    return ':$names';
  }

  jsAst.FunctionDeclaration buildCspPrecompiledFunctionFor(
      OutputUnit outputUnit) {
    // TODO(ahe): Compute a hash code.
    return js.statement('''
      function dart_precompiled(\$collectedClasses) {
        var \$desc;
        #;
        return #;
      }''',
        [cspPrecompiledFunctionFor(outputUnit),
         new jsAst.ArrayInitializer.from(
             cspPrecompiledConstructorNamesFor(outputUnit))]);
  }

  void generateClass(ClassElement classElement, ClassBuilder properties) {
    compiler.withCurrentElement(classElement, () {
      if (compiler.hasIncrementalSupport) {
        ClassBuilder builder =
            cachedClassBuilders.putIfAbsent(classElement, () {
              ClassBuilder builder = new ClassBuilder(classElement, namer);
              classEmitter.generateClass(
                  classElement, builder, additionalProperties[classElement]);
              return builder;
            });
        invariant(classElement, builder.fields.isEmpty);
        invariant(classElement, builder.superName == null);
        invariant(classElement, builder.functionType == null);
        invariant(classElement, builder.fieldMetadata == null);
        properties.properties.addAll(builder.properties);
      } else {
        classEmitter.generateClass(
            classElement, properties, additionalProperties[classElement]);
      }
    });
  }

  void emitFinishClassesInvocationIfNecessary(CodeBuffer buffer) {
    if (needsDefineClass) {
      buffer.write('$finishClassesName($classesCollector,'
                   '$_$isolateProperties,'
                   '${_}null)$N');

      // Reset the map.
      buffer.write("$classesCollector$_=${_}null$N$n");
    }
  }

  void emitStaticFunctions(List<Element> staticFunctions) {
    for (Element element in staticFunctions) {
      ClassBuilder builder = new ClassBuilder(element, namer);
      containerBuilder.addMember(element, builder);
      getElementDescriptor(element).properties.addAll(builder.properties);
    }
  }

  void emitStaticNonFinalFieldInitializations(CodeBuffer buffer) {
    JavaScriptConstantCompiler handler = backend.constants;
    Iterable<VariableElement> staticNonFinalFields =
        handler.getStaticNonFinalFieldsForEmission();
    for (Element element in Elements.sortedByPosition(staticNonFinalFields)) {
      // [:interceptedNames:] is handled in [emitInterceptedNames].
      if (element == backend.interceptedNames) continue;
      // `mapTypeToInterceptor` is handled in [emitMapTypeToInterceptor].
      if (element == backend.mapTypeToInterceptor) continue;
      compiler.withCurrentElement(element, () {
        ConstantValue initialValue = handler.getInitialValueFor(element).value;
        jsAst.Expression init =
          js('$isolateProperties.# = #',
              [namer.getNameOfGlobalField(element),
               constantEmitter.referenceInInitializationContext(initialValue)]);
        buffer.write(jsAst.prettyPrint(init, compiler,
                                       monitor: compiler.dumpInfoTask));
        buffer.write('$N');
      });
    }
  }

  void emitLazilyInitializedStaticFields(CodeBuffer buffer) {
    JavaScriptConstantCompiler handler = backend.constants;
    List<VariableElement> lazyFields =
        handler.getLazilyInitializedFieldsForEmission();
    if (!lazyFields.isEmpty) {
      needsLazyInitializer = true;
      for (VariableElement element in Elements.sortedByPosition(lazyFields)) {
        jsAst.Expression code = backend.generatedCode[element];
        // The code is null if we ended up not needing the lazily
        // initialized field after all because of constant folding
        // before code generation.
        if (code == null) continue;
        // The code only computes the initial value. We build the lazy-check
        // here:
        //   lazyInitializer(prototype, 'name', fieldName, getterName, initial);
        // The name is used for error reporting. The 'initial' must be a
        // closure that constructs the initial value.
        jsAst.Expression init = js('#(#,#,#,#,#)',
            [js(lazyInitializerName),
                js(isolateProperties),
                js.string(element.name),
                js.string(namer.getNameX(element)),
                js.string(namer.getLazyInitializerName(element)),
                code]);
        buffer.write(jsAst.prettyPrint(init, compiler,
                                       monitor: compiler.dumpInfoTask));
        buffer.write("$N");
      }
    }
  }

  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    if (constant.isFunction) return true;    // Already emitted.
    if (constant.isPrimitive) return true;   // Inlined.
    if (constant.isDummy) return true;       // Inlined.
    // The name is null when the constant is already a JS constant.
    // TODO(floitsch): every constant should be registered, so that we can
    // share the ones that take up too much space (like some strings).
    if (namer.constantName(constant) == null) return true;
    return false;
  }

  int compareConstants(ConstantValue a, ConstantValue b) {
    // Inlined constants don't affect the order and sometimes don't even have
    // names.
    int cmp1 = isConstantInlinedOrAlreadyEmitted(a) ? 0 : 1;
    int cmp2 = isConstantInlinedOrAlreadyEmitted(b) ? 0 : 1;
    if (cmp1 + cmp2 < 2) return cmp1 - cmp2;

    // Emit constant interceptors first. Constant interceptors for primitives
    // might be used by code that builds other constants.  See Issue 18173.
    if (a.isInterceptor != b.isInterceptor) {
      return a.isInterceptor ? -1 : 1;
    }

    // Sorting by the long name clusters constants with the same constructor
    // which compresses a tiny bit better.
    int r = namer.constantLongName(a).compareTo(namer.constantLongName(b));
    if (r != 0) return r;
    // Resolve collisions in the long name by using the constant name (i.e. JS
    // name) which is unique.
    return namer.constantName(a).compareTo(namer.constantName(b));
  }

  void emitCompileTimeConstants(CodeBuffer buffer, OutputUnit outputUnit) {
    List<ConstantValue> constants = outputConstantLists[outputUnit];
    if (constants == null) return;
    bool isMainBuffer = buffer == mainBuffer;
    if (compiler.hasIncrementalSupport && isMainBuffer) {
      buffer = cachedEmittedConstantsBuffer;
    }
    for (ConstantValue constant in constants) {
      if (compiler.hasIncrementalSupport && isMainBuffer) {
        if (cachedEmittedConstants.contains(constant)) continue;
        cachedEmittedConstants.add(constant);
      }
      String name = namer.constantName(constant);
      jsAst.Expression init = js('#.# = #',
          [namer.globalObjectForConstant(constant), name,
           constantInitializerExpression(constant)]);
      buffer.write(jsAst.prettyPrint(init, compiler,
                                     monitor: compiler.dumpInfoTask));
      buffer.write('$N');
    }
    if (compiler.hasIncrementalSupport && isMainBuffer) {
      mainBuffer.add(cachedEmittedConstantsBuffer);
    }
  }

  jsAst.Template get makeConstantListTemplate {
    // TODO(floitsch): there is no harm in caching the template.
    return jsAst.js.uncachedExpressionTemplate(
        '${namer.isolateName}.$makeConstListProperty(#)');
  }

  void emitMakeConstantList(CodeBuffer buffer) {
    buffer.write(
        jsAst.prettyPrint(
            // Functions are stored in the hidden class and not as properties in
            // the object. We never actually look at the value, but only want
            // to know if the property exists.
            js.statement(r'''#.# = function(list) {
                                     list.immutable$list = Array;
                                     list.fixed$length = Array;
                                     return list;
                                   }''',
                         [namer.isolateName, makeConstListProperty]),
            compiler, monitor: compiler.dumpInfoTask));
    buffer.write(N);
  }

  /// Returns the code equivalent to:
  ///   `function(args) { $.startRootIsolate(X.main$closure(), args); }`
  jsAst.Expression buildIsolateSetupClosure(Element appMain,
                                            Element isolateMain) {
    jsAst.Expression mainAccess = namer.isolateStaticClosureAccess(appMain);
    // Since we pass the closurized version of the main method to
    // the isolate method, we must make sure that it exists.
    return js('function(a){ #(#, a); }',
        [namer.elementAccess(isolateMain), mainAccess]);
  }

  /**
   * Emits code that sets the `isolateTag embedded global to a unique string.
   */
  jsAst.Expression generateIsolateAffinityTagInitialization() {
    jsAst.Expression getIsolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.GET_ISOLATE_TAG);
    jsAst.Expression isolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.ISOLATE_TAG);

    return js('''
      !function() {
        // On V8, the 'intern' function converts a string to a symbol, which
        // makes property access much faster.
        function intern(s) {
          var o = {};
          o[s] = 1;
          return Object.keys(convertToFastObject(o))[0];
        }

        # = function(name) {  // embedded getIsolateTag
          return intern("___dart_" + name + #);  // embedded isolateTag
        };

        // To ensure that different programs loaded into the same context (page)
        // use distinct dispatch properies, we place an object on `Object` to
        // contain the names already in use.
        var tableProperty = "___dart_isolate_tags_";
        var usedProperties = Object[tableProperty] ||
            (Object[tableProperty] = Object.create(null));

        var rootProperty = "_${generateIsolateTagRoot()}";
        for (var i = 0; ; i++) {
          var property = intern(rootProperty + "_" + i + "_");
          if (!(property in usedProperties)) {
            usedProperties[property] = 1;
            # = property;  // embedded isolateTag
            break;
          }
        }
      }()
    ''', [getIsolateTagAccess,
          isolateTagAccess,
          isolateTagAccess]);
  }

  jsAst.Expression generateDispatchPropertyNameInitialization() {
    jsAst.Expression dispatchPropertyNameAccess =
        generateEmbeddedGlobalAccess(embeddedNames.DISPATCH_PROPERTY_NAME);
    jsAst.Expression getIsolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.GET_ISOLATE_TAG);
    return js('# = #("dispatch_record")',
        [dispatchPropertyNameAccess,
         getIsolateTagAccess]);
  }

  String generateIsolateTagRoot() {
    // TODO(sra): MD5 of contributing source code or URIs?
    return 'ZxYxX';
  }

  emitMain(CodeBuffer buffer) {
    if (compiler.isMockCompilation) return;
    Element main = compiler.mainFunction;
    jsAst.Expression mainCallClosure = null;
    if (compiler.hasIsolateSupport) {
      Element isolateMain =
        backend.isolateHelperLibrary.find(JavaScriptBackend.START_ROOT_ISOLATE);
      mainCallClosure = buildIsolateSetupClosure(main, isolateMain);
    } else if (compiler.hasIncrementalSupport) {
      mainCallClosure =
          js('function() { return #(); }', namer.elementAccess(main));
    } else {
      mainCallClosure = namer.elementAccess(main);
    }

    if (backend.needToInitializeIsolateAffinityTag) {
      buffer.write(
          jsAst.prettyPrint(generateIsolateAffinityTagInitialization(),
                            compiler, monitor: compiler.dumpInfoTask));
      buffer.write(N);
    }
    if (backend.needToInitializeDispatchProperty) {
      assert(backend.needToInitializeIsolateAffinityTag);
      buffer.write(
          jsAst.prettyPrint(generateDispatchPropertyNameInitialization(),
              compiler, monitor: compiler.dumpInfoTask));
      buffer.write(N);
    }

    jsAst.Expression currentScriptAccess =
        generateEmbeddedGlobalAccess(embeddedNames.CURRENT_SCRIPT);

    addComment('BEGIN invoke [main].', buffer);
    // This code finds the currently executing script by listening to the
    // onload event of all script tags and getting the first script which
    // finishes. Since onload is called immediately after execution this should
    // not substantially change execution order.
    jsAst.Statement invokeMain = js.statement('''
(function (callback) {
  if (typeof document === "undefined") {
    callback(null);
    return;
  }
  if (document.currentScript) {
    callback(document.currentScript);
    return;
  }

  var scripts = document.scripts;
  function onLoad(event) {
    for (var i = 0; i < scripts.length; ++i) {
      scripts[i].removeEventListener("load", onLoad, false);
    }
    callback(event.target);
  }
  for (var i = 0; i < scripts.length; ++i) {
    scripts[i].addEventListener("load", onLoad, false);
  }
})(function(currentScript) {
  # = currentScript;  // embedded currentScript.

  if (typeof dartMainRunner === "function") {
    dartMainRunner(#, []);  // mainCallClosure.
  } else {
    #([]);  // mainCallClosure.
  }
})$N''', [currentScriptAccess,
          mainCallClosure,
          mainCallClosure]);

    buffer.write(';');
    buffer.write(jsAst.prettyPrint(invokeMain,
                 compiler, monitor: compiler.dumpInfoTask));
    buffer.write(N);
    addComment('END invoke [main].', buffer);
  }

  void emitInitFunction(CodeBuffer buffer) {
    jsAst.FunctionDeclaration decl = js.statement('''
      function init() {
        $isolateProperties = Object.create(null);
        #; #; #;
      }''', [
          buildDefineClassAndFinishClassFunctionsIfNecessary(),
          buildLazyInitializerFunctionIfNecessary(),
          buildFinishIsolateConstructor()]);

    buffer.write(jsAst.prettyPrint(decl,
                 compiler, monitor: compiler.dumpInfoTask).getText());
    if (compiler.enableMinification) buffer.write('\n');
  }

  void emitConvertToFastObjectFunction() {
    List<jsAst.Statement> debugCode = <jsAst.Statement>[];
    if (DEBUG_FAST_OBJECTS) {
      debugCode.add(js.statement(r'''
        // The following only works on V8 when run with option
        // "--allow-natives-syntax".  We use'new Function' because the
         // miniparser does not understand V8 native syntax.
        if (typeof print === "function") {
          var HasFastProperties =
            new Function("a", "return %HasFastProperties(a)");
          print("Size of global object: "
                   + String(Object.getOwnPropertyNames(properties).length)
                   + ", fast properties " + HasFastProperties(properties));
        }'''));
    }

    jsAst.Statement convertToFastObject = js.statement(r'''
      function convertToFastObject(properties) {
        // Create an instance that uses 'properties' as prototype. This should
        // make 'properties' a fast object.
        function MyClass() {};
        MyClass.prototype = properties;
        new MyClass();
        #;
        return properties;
      }''', [debugCode]);

    mainBuffer.add(jsAst.prettyPrint(convertToFastObject, compiler));
    mainBuffer.add(N);
  }

  void writeLibraryDescriptors(CodeBuffer buffer, LibraryElement library) {
    var uri = "";
    if (!compiler.enableMinification || backend.mustPreserveUris) {
      uri = library.canonicalUri;
      if (uri.scheme == 'file' && compiler.outputUri != null) {
        uri = relativize(compiler.outputUri, library.canonicalUri, false);
      }
    }
    ClassBuilder descriptor = elementDescriptors[library];
    if (descriptor == null) {
      // Nothing of the library was emitted.
      // TODO(floitsch): this should not happen. We currently have an example
      // with language/prefix6_negative_test.dart where we have an instance
      // method without its corresponding class.
      return;
    }

    String libraryName =
        (!compiler.enableMinification || backend.mustRetainLibraryNames) ?
        library.getLibraryName() :
        "";

    jsAst.Fun metadata = metadataEmitter.buildMetadataFunction(library);

    jsAst.ObjectInitializer initializers = descriptor.toObjectInitializer();

    compiler.dumpInfoTask.registerElementAst(library, metadata);
    compiler.dumpInfoTask.registerElementAst(library, initializers);
    buffer
        ..write('["$libraryName",$_')
        ..write('"${uri}",$_')
        ..write(metadata == null ? "" : jsAst.prettyPrint(metadata,
                                              compiler,
                                              monitor: compiler.dumpInfoTask))
        ..write(',$_')
        ..write(namer.globalObjectFor(library))
        ..write(',$_')
        ..write(jsAst.prettyPrint(initializers,
                                  compiler,
                                  monitor: compiler.dumpInfoTask))
        ..write(library == compiler.mainApp ? ',${n}1' : "")
        ..write('],$n');
  }

  void emitPrecompiledConstructor(OutputUnit outputUnit,
                                  String constructorName,
                                  jsAst.Expression constructorAst) {
    cspPrecompiledFunctionFor(outputUnit).add(
        new jsAst.FunctionDeclaration(
            new jsAst.VariableDeclaration(constructorName), constructorAst));
    cspPrecompiledFunctionFor(outputUnit).add(
    js.statement(r'''{
          #.builtin$cls = #;
          if (!"name" in #)
              #.name = #;
          $desc=$collectedClasses.#;
          if ($desc instanceof Array) $desc = $desc[1];
          #.prototype = $desc;
        }''',
        [   constructorName, js.string(constructorName),
            constructorName,
            constructorName, js.string(constructorName),
            constructorName,
            constructorName
         ]));

    cspPrecompiledConstructorNamesFor(outputUnit).add(js('#', constructorName));
  }

  /// Extracts the output name of the compiler's outputUri.
  String deferredPartFileName(OutputUnit outputUnit,
                              {bool addExtension: true}) {
    String outPath = compiler.outputUri != null
        ? compiler.outputUri.path
        : "out";
    String outName = outPath.substring(outPath.lastIndexOf('/') + 1);
    String extension = addExtension ? ".part.js" : "";
    if (outputUnit == compiler.deferredLoadTask.mainOutputUnit) {
      return "$outName$extension";
    } else {
      String name = outputUnit.name;
      return "${outName}_$name$extension";
    }
  }

  void emitLibraries(Iterable<LibraryElement> libraries) {
    if (libraries.isEmpty) return;

    // TODO(karlklose): document what kinds of fields this loop adds to the
    // library class builder.
    for (LibraryElement element in libraries) {
      LibraryElement library = element;
      ClassBuilder builder = new ClassBuilder(library, namer);
      if (classEmitter.emitFields(library, builder, null, emitStatics: true)) {
        jsAst.ObjectInitializer initializer = builder.toObjectInitializer();
        compiler.dumpInfoTask.registerElementAst(builder.element, initializer);
        getElementDescriptor(library).properties.addAll(initializer.properties);
      }
    }
  }

  void emitTypedefs() {
    OutputUnit mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;

    // Emit all required typedef declarations into the main output unit.
    // TODO(karlklose): unify required classes and typedefs to declarations
    // and have builders for each kind.
    for (TypedefElement typedef in typedefsNeededForReflection) {
      OutputUnit mainUnit = compiler.deferredLoadTask.mainOutputUnit;
      LibraryElement library = typedef.library;
      // TODO(karlklose): add a TypedefBuilder and move this code there.
      DartType type = typedef.alias;
      int typeIndex = metadataEmitter.reifyType(type);
      String typeReference =
          encoding.encodeTypedefFieldDescriptor(typeIndex);
      jsAst.Property descriptor = new jsAst.Property(
          js.string(namer.classDescriptorProperty),
          js.string(typeReference));
      jsAst.Node declaration = new jsAst.ObjectInitializer([descriptor]);
      String mangledName = namer.getNameX(typedef);
      String reflectionName = getReflectionName(typedef, mangledName);
      getElementDescriptor(library)
          ..addProperty(mangledName, declaration)
          ..addProperty("+$reflectionName", js.string(''));
      // Also emit a trivial constructor for CSP mode.
      String constructorName = mangledName;
      jsAst.Expression constructorAst = js('function() {}');
      emitPrecompiledConstructor(mainOutputUnit,
                                 constructorName,
                                 constructorAst);
    }
  }

  void emitMangledNames() {
    if (!mangledFieldNames.isEmpty) {
      var keys = mangledFieldNames.keys.toList();
      keys.sort();
      var properties = [];
      for (String key in keys) {
        var value = js.string('${mangledFieldNames[key]}');
        properties.add(new jsAst.Property(js.string(key), value));
      }

      jsAst.Expression mangledNamesAccess =
          generateEmbeddedGlobalAccess(embeddedNames.MANGLED_NAMES);
      var map = new jsAst.ObjectInitializer(properties);
      mainBuffer.write(
          jsAst.prettyPrint(
              js.statement('# = #', [mangledNamesAccess, map]),
              compiler,
              monitor: compiler.dumpInfoTask));
      if (compiler.enableMinification) {
        mainBuffer.write(';');
      }
    }
    if (!mangledGlobalFieldNames.isEmpty) {
      var keys = mangledGlobalFieldNames.keys.toList();
      keys.sort();
      var properties = [];
      for (String key in keys) {
        var value = js.string('${mangledGlobalFieldNames[key]}');
        properties.add(new jsAst.Property(js.string(key), value));
      }
      jsAst.Expression mangledGlobalNamesAccess =
          generateEmbeddedGlobalAccess(embeddedNames.MANGLED_GLOBAL_NAMES);
      var map = new jsAst.ObjectInitializer(properties);
      mainBuffer.write(
          jsAst.prettyPrint(
              js.statement('# = #', [mangledGlobalNamesAccess, map]),
              compiler,
              monitor: compiler.dumpInfoTask));
      if (compiler.enableMinification) {
        mainBuffer.write(';');
      }
    }
  }

  void checkEverythingEmitted(Iterable<Element> elements) {
    List<Element> pendingStatics;
    if (!compiler.hasIncrementalSupport) {
      pendingStatics =
          Elements.sortedByPosition(elements.where((e) => !e.isLibrary));

      pendingStatics.forEach((element) =>
          compiler.reportInfo(
              element, MessageKind.GENERIC, {'text': 'Pending statics.'}));
    }

    if (pendingStatics != null && !pendingStatics.isEmpty) {
      compiler.internalError(pendingStatics.first,
          'Pending statics (see above).');
    }
  }

  void emitMainOutputUnit(Map<OutputUnit, String> deferredLoadHashes,
                          CodeBuffer nativeBuffer) {
    bool isProgramSplit = compiler.deferredLoadTask.isProgramSplit;
    OutputUnit mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;

    mainBuffer.add(buildGeneratedBy());
    addComment(HOOKS_API_USAGE, mainBuffer);

    if (isProgramSplit) {
      /// For deferred loading we communicate the initializers via this global
      /// variable. The deferred hunks will add their initialization to this.
      /// The semicolon is important in minified mode, without it the
      /// following parenthesis looks like a call to the object literal.
      mainBuffer..add(
          'self.${deferredInitializers} = self.${deferredInitializers} || '
          'Object.create(null);$n');
    }

    // Using a named function here produces easier to read stack traces in
    // Chrome/V8.
    mainBuffer.add('(function(${namer.currentIsolate})$_{\n');
    if (compiler.hasIncrementalSupport) {
      mainBuffer.add(
          'this.\$dart_unsafe_eval ='
          ' this.\$dart_unsafe_eval || Object.create(null)$N');
      mainBuffer.add(
          'this.\$dart_unsafe_eval.patch = function(a) { eval(a) }$N');
      String schemaChange =
          jsAst.prettyPrint(buildSchemaChangeFunction(), compiler).getText();
      mainBuffer.add(
          'this.\$dart_unsafe_eval.schemaChange$_=$_$schemaChange$N');
    }
    if (isProgramSplit) {
      /// We collect all the global state of the, so it can be passed to the
      /// initializer of deferred files.
      mainBuffer.add('var ${globalsHolder}$_=${_}Object.create(null)$N');
    }
    mainBuffer.add('function dart()$_{$n'
        '${_}${_}this.x$_=${_}0$N'
        '${_}${_}delete this.x$N'
        '}$n');
    for (String globalObject in Namer.reservedGlobalObjectNames) {
      // The global objects start as so-called "slow objects". For V8, this
      // means that it won't try to make map transitions as we add properties
      // to these objects. Later on, we attempt to turn these objects into
      // fast objects by calling "convertToFastObject" (see
      // [emitConvertToFastObjectFunction]).
      mainBuffer.write('var ${globalObject}$_=${_}');
      if(isProgramSplit) {
        mainBuffer.add('${globalsHolder}.$globalObject$_=${_}');
      }
      mainBuffer.write('new dart$N');
    }

    mainBuffer.add('function ${namer.isolateName}()$_{}\n');
    if (isProgramSplit) {
      mainBuffer
        .write('${globalsHolder}.${namer.isolateName}$_=$_'
               '${namer.isolateName}$N'
               '${globalsHolder}.$initName$_=${_}$initName$N');
    }
    mainBuffer.add('init()$N$n');
    mainBuffer.add('$isolateProperties$_=$_$isolatePropertiesName$N');

    emitStaticFunctions(task.outputStaticLists[mainOutputUnit]);

    // Only output the classesCollector if we actually have any classes.
    if (!(nativeClasses.isEmpty &&
          compiler.codegenWorld.staticFunctionsNeedingGetter.isEmpty &&
          outputClassLists.values.every((classList) => classList.isEmpty) &&
          typedefsNeededForReflection.isEmpty)) {
      // Shorten the code by using "$$" as temporary.
      classesCollector = r"$$";
      mainBuffer.add('var $classesCollector$_=${_}Object.create(null)$N$n');
    }

    if (!nativeClasses.isEmpty) {
      addComment('Native classes', mainBuffer);
    }

    List<ClassElement> classes = task.outputClassLists[mainOutputUnit];
    if (classes != null) {
      for (ClassElement element in classes) {
        generateClass(element, getElementDescriptor(element));
      }
    }

    if (compiler.enableMinification) {
      mainBuffer.write(';');
    }

    if (elementDescriptors.isNotEmpty) {
      Iterable<LibraryElement> libraries =
          task.outputLibraryLists[mainOutputUnit];
      if (libraries == null) libraries = [];
      emitLibraries(libraries);
      emitTypedefs();
      emitMangledNames();

      checkEverythingEmitted(elementDescriptors.keys);

      CodeBuffer libraryBuffer = new CodeBuffer();
      for (LibraryElement library in Elements.sortedByPosition(libraries)) {
        writeLibraryDescriptors(libraryBuffer, library);
        elementDescriptors.remove(library);
      }

      mainBuffer
          ..write('(')
          ..write(
              jsAst.prettyPrint(
                  getReflectionDataParser(classesCollector, backend),
                  compiler))
          ..write(')')
          ..write('([$n')
          ..add(libraryBuffer)
          ..write('])$N');

      emitFinishClassesInvocationIfNecessary(mainBuffer);
    }

    typeTestEmitter.emitRuntimeTypeSupport(mainBuffer, mainOutputUnit);
    interceptorEmitter.emitGetInterceptorMethods(mainBuffer);
    interceptorEmitter.emitOneShotInterceptors(mainBuffer);

    if (task.outputContainsConstantList) {
      emitMakeConstantList(mainBuffer);
    }

    // Constants in checked mode call into RTI code to set type information
    // which may need getInterceptor (and one-shot interceptor) methods, so
    // we have to make sure that [emitGetInterceptorMethods] and
    // [emitOneShotInterceptors] have been called.
    emitCompileTimeConstants(mainBuffer, mainOutputUnit);

    emitDeferredBoilerPlate(mainBuffer, deferredLoadHashes);

    // Static field initializations require the classes and compile-time
    // constants to be set up.
    emitStaticNonFinalFieldInitializations(mainBuffer);
    interceptorEmitter.emitInterceptedNames(mainBuffer);
    interceptorEmitter.emitMapTypeToInterceptor(mainBuffer);
    emitLazilyInitializedStaticFields(mainBuffer);

    mainBuffer.writeln();
    mainBuffer.add(nativeBuffer);

    metadataEmitter.emitMetadata(mainBuffer);

    isolateProperties = isolatePropertiesName;
    // The following code should not use the short-hand for the
    // initialStatics.
    mainBuffer.add('${namer.currentIsolate}$_=${_}null$N');

    emitFinishIsolateConstructorInvocation(mainBuffer);
    mainBuffer.add(
        '${namer.currentIsolate}$_=${_}new ${namer.isolateName}()$N');

    emitConvertToFastObjectFunction();
    for (String globalObject in Namer.reservedGlobalObjectNames) {
      mainBuffer.add('$globalObject = convertToFastObject($globalObject)$N');
    }
    if (DEBUG_FAST_OBJECTS) {
      mainBuffer.add(r'''
          // The following only works on V8 when run with option
          // "--allow-natives-syntax".  We use'new Function' because the
          // miniparser does not understand V8 native syntax.
          if (typeof print === "function") {
            var HasFastProperties =
              new Function("a", "return %HasFastProperties(a)");
            print("Size of global helper object: "
                   + String(Object.getOwnPropertyNames(H).length)
                   + ", fast properties " + HasFastProperties(H));
            print("Size of global platform object: "
                   + String(Object.getOwnPropertyNames(P).length)
                   + ", fast properties " + HasFastProperties(P));
            print("Size of global dart:html object: "
                   + String(Object.getOwnPropertyNames(W).length)
                   + ", fast properties " + HasFastProperties(W));
            print("Size of isolate properties object: "
                   + String(Object.getOwnPropertyNames($).length)
                   + ", fast properties " + HasFastProperties($));
           print("Size of constant object: "
                   + String(Object.getOwnPropertyNames(C).length)
                   + ", fast properties " + HasFastProperties(C));
           var names = Object.getOwnPropertyNames($);
           for (var i = 0; i < names.length; i++) {
             print("$." + names[i]);
           }
         }
''');
      for (String object in Namer.userGlobalObjects) {
      mainBuffer.add('''
        if (typeof print === "function") {
           print("Size of $object: "
                 + String(Object.getOwnPropertyNames($object).length)
                 + ", fast properties " + HasFastProperties($object));
}
''');
      }
    }

    jsAst.FunctionDeclaration precompiledFunctionAst =
        buildCspPrecompiledFunctionFor(mainOutputUnit);
    emitInitFunction(mainBuffer);
    emitMain(mainBuffer);
    mainBuffer.add('})()\n');

    if (compiler.useContentSecurityPolicy) {
      mainBuffer.write(
          jsAst.prettyPrint(
              precompiledFunctionAst,
              compiler,
              monitor: compiler.dumpInfoTask,
              allowVariableMinification: false).getText());
    }

    String assembledCode = mainBuffer.getText();
    if (generateSourceMap) {
      outputSourceMap(assembledCode, mainBuffer, '',
          compiler.sourceMapUri, compiler.outputUri);
      mainBuffer.add(
          generateSourceMapTag(compiler.sourceMapUri, compiler.outputUri));
      assembledCode = mainBuffer.getText();
    }

    compiler.outputProvider('', 'js')
        ..add(assembledCode)
        ..close();
    compiler.assembledCode = assembledCode;
  }

  /// Used by incremental compilation to patch up the prototype of
  /// [oldConstructor] for use as prototype of [newConstructor].
  jsAst.Fun buildSchemaChangeFunction() {
    return js('''
function(newConstructor, oldConstructor, superclass) {
  // Invariant: newConstructor.prototype has no interesting properties besides
  // generated accessors. These are copied to oldPrototype which will be
  // updated by other incremental changes.
  if (superclass != null) {
    this.inheritFrom(newConstructor, superclass);
  }
  var oldPrototype = oldConstructor.prototype;
  var newPrototype = newConstructor.prototype;
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  for (var property in newPrototype) {
    if (hasOwnProperty.call(newPrototype, property)) {
      // Copy generated accessors.
      oldPrototype[property] = newPrototype[property];
    }
  }
  oldPrototype.__proto__ = newConstructor.prototype.__proto__;
  oldPrototype.constructor = newConstructor;
  newConstructor.prototype = oldPrototype;
  return newConstructor;
}''');
  }

  /// Returns a map from OutputUnit to a hash of its content. The hash uniquely
  /// identifies the code of the output-unit. It does not include
  /// boilerplate JS code, like the sourcemap directives or the hash
  /// itself.
  Map<OutputUnit, String> emitDeferredOutputUnits() {
    if (!compiler.deferredLoadTask.isProgramSplit) return const {};

    Map<OutputUnit, CodeBuffer> outputBuffers =
        new Map<OutputUnit, CodeBuffer>();

    for (OutputUnit outputUnit in compiler.deferredLoadTask.allOutputUnits) {
      if (outputUnit == compiler.deferredLoadTask.mainOutputUnit) continue;

      List<Element> functions = task.outputStaticLists[outputUnit];
      if (functions != null) {
        emitStaticFunctions(functions);
      }

      List<ClassElement> classes = task.outputClassLists[outputUnit];
      if (classes != null) {
        for (ClassElement element in classes) {
          generateClass(element, getElementDescriptor(element));
        }
      }

      if (elementDescriptors.isNotEmpty) {
        Iterable<LibraryElement> libraries =
            task.outputLibraryLists[outputUnit];
        if (libraries == null) libraries = [];
        emitLibraries(libraries);

        CodeBuffer buffer = new CodeBuffer();
        outputBuffers[outputUnit] = buffer;
        for (LibraryElement library in Elements.sortedByPosition(libraries)) {
          writeLibraryDescriptors(buffer, library);
          elementDescriptors.remove(library);
        }
      }
    }

    return emitDeferredCode(outputBuffers);
  }

  CodeBuffer buildNativesBuffer() {
    // Emit native classes on [nativeBuffer].
    final CodeBuffer nativeBuffer = new CodeBuffer();

    if (nativeClasses.isEmpty) return nativeBuffer;


    addComment('Native classes', nativeBuffer);

    nativeEmitter.generateNativeClasses(nativeClasses, mainBuffer,
        additionalProperties);

    nativeEmitter.finishGenerateNativeClasses();
    nativeEmitter.assembleCode(nativeBuffer);

    return nativeBuffer;
  }

  void emitProgram(Program program) {
    // Shorten the code by using [namer.currentIsolate] as temporary.
    isolateProperties = namer.currentIsolate;

    classesCollector = r"$$";

    // Emit deferred units first, so we have their hashes.
    // Map from OutputUnit to a hash of its content. The hash uniquely
    // identifies the code of the output-unit. It does not include
    // boilerplate JS code, like the sourcemap directives or the hash
    // itself.
    Map<OutputUnit, String> deferredLoadHashes = emitDeferredOutputUnits();
    CodeBuffer nativeBuffer = buildNativesBuffer();
    emitMainOutputUnit(deferredLoadHashes, nativeBuffer);

    if (backend.requiresPreamble &&
        !backend.htmlLibraryIsLoaded) {
      compiler.reportHint(NO_LOCATION_SPANNABLE, MessageKind.PREAMBLE);
    }
  }

  String generateSourceMapTag(Uri sourceMapUri, Uri fileUri) {
    if (sourceMapUri != null && fileUri != null) {
      String sourceMapFileName = relativize(fileUri, sourceMapUri, false);
      return '''

//# sourceMappingURL=$sourceMapFileName
''';
    }
    return '';
  }

  ClassBuilder getElementDescriptor(Element element) {
    Element owner = element.library;
    if (!element.isLibrary && !element.isTopLevel && !element.isNative) {
      // For static (not top level) elements, record their code in a buffer
      // specific to the class. For now, not supported for native classes and
      // native elements.
      ClassElement cls =
          element.enclosingClassOrCompilationUnit.declaration;
      if (compiler.codegenWorld.directlyInstantiatedClasses.contains(cls)
          && !cls.isNative) {
        owner = cls;
      }
    }
    if (owner == null) {
      compiler.internalError(element, 'Owner is null.');
    }
    return elementDescriptors.putIfAbsent(
        owner,
        () => new ClassBuilder(owner, namer));
  }

  /// Emits support-code for deferred loading into [buffer].
  void emitDeferredBoilerPlate(CodeBuffer buffer,
                               Map<OutputUnit, String> deferredLoadHashes) {
    // Function for checking if a hunk is loaded given its hash.
    buffer.write(jsAst.prettyPrint(
        js('# = function(hunkHash) {'
           '  return !!$deferredInitializers[hunkHash];'
           '}', generateEmbeddedGlobalAccess(embeddedNames.IS_HUNK_LOADED)),
        compiler, monitor: compiler.dumpInfoTask));
    buffer.write('$N');
    // Function for initializing a loaded hunk, given its hash.
    buffer.write(jsAst.prettyPrint(
        js('# = function(hunkHash) {'
           '  $deferredInitializers[hunkHash]('
                '$globalsHolder, ${namer.currentIsolate})'
           '}',
           generateEmbeddedGlobalAccess(
               embeddedNames.INITIALIZE_LOADED_HUNK)),
        compiler, monitor: compiler.dumpInfoTask));
    buffer.write('$N');
    // Write a javascript mapping from Deferred import load ids (derrived
    // from the import prefix.) to a list of lists of uris of hunks to load,
    // and a corresponding mapping to a list of hashes used by
    // INITIALIZE_LOADED_HUNK and IS_HUNK_LOADED.
    Map<String, List<String>> deferredLibraryUris =
        new Map<String, List<String>>();
    Map<String, List<String>> deferredLibraryHashes =
        new Map<String, List<String>>();
    compiler.deferredLoadTask.hunksToLoad.forEach(
                  (String loadId, List<OutputUnit>outputUnits) {
      List<String> uris = new List<String>();
      List<String> hashes = new List<String>();
      deferredLibraryHashes[loadId] = new List<String>();
      for (OutputUnit outputUnit in outputUnits) {
        uris.add(deferredPartFileName(outputUnit));
        hashes.add(deferredLoadHashes[outputUnit]);
      }

      deferredLibraryUris[loadId] = uris;
      deferredLibraryHashes[loadId] = hashes;
    });

    void emitMapping(String name, Map<String, List<String>> mapping) {
      List<jsAst.Property> properties = new List<jsAst.Property>();
      mapping.forEach((String key, List<String> values) {
        properties.add(new jsAst.Property(js.escapedString(key),
            new jsAst.ArrayInitializer.from(
                values.map(js.escapedString))));
      });
      jsAst.Node initializer =
          new jsAst.ObjectInitializer(properties, isOneLiner: true);

      jsAst.Node globalName = generateEmbeddedGlobalAccess(name);
      buffer.write(jsAst.prettyPrint(
          js("# = #", [globalName, initializer]),
          compiler, monitor: compiler.dumpInfoTask));
      buffer.write('$N');

    }

    emitMapping(embeddedNames.DEFERRED_LIBRARY_URIS, deferredLibraryUris);
    emitMapping(embeddedNames.DEFERRED_LIBRARY_HASHES,
                deferredLibraryHashes);
  }

  /// Emits code for all output units except the main.
  /// Returns a mapping from outputUnit to a hash of the corresponding hunk that
  /// can be used for calling the initializer.
  Map<OutputUnit, String> emitDeferredCode(
      Map<OutputUnit, CodeBuffer> deferredBuffers) {

    Map<OutputUnit, String> hunkHashes = new Map<OutputUnit, String>();

    for (OutputUnit outputUnit in compiler.deferredLoadTask.allOutputUnits) {
      if (outputUnit == compiler.deferredLoadTask.mainOutputUnit) continue;

      CodeBuffer libraryDescriptorBuffer = deferredBuffers[outputUnit];

      CodeBuffer outputBuffer = new CodeBuffer();

      outputBuffer..write(buildGeneratedBy())
        ..write('${deferredInitializers}.current$_=$_'
                'function$_(${globalsHolder}) {$N');
      for (String globalObject in Namer.reservedGlobalObjectNames) {
        outputBuffer
            .write('var $globalObject$_=$_'
                   '${globalsHolder}.$globalObject$N');
      }
      outputBuffer
          ..write('var init$_=$_${globalsHolder}.init$N')
          ..write('var ${namer.isolateName}$_=$_'
                    '${globalsHolder}.${namer.isolateName}$N');
      if (libraryDescriptorBuffer != null) {
      // TODO(ahe): This defines a lot of properties on the
      // Isolate.prototype object.  We know this will turn it into a
      // slow object in V8, so instead we should do something similar
      // to Isolate.$finishIsolateConstructor.
         outputBuffer
           ..write('var ${namer.currentIsolate}$_=$_$isolatePropertiesName$N')
           // The classesCollector object ($$).
           ..write('$classesCollector$_=${_}Object.create(null);$n')
           ..write('(')
           ..write(
               jsAst.prettyPrint(
                   getReflectionDataParser(classesCollector, backend),
                   compiler, monitor: compiler.dumpInfoTask))
           ..write(')')
           ..write('([$n')
           ..addBuffer(libraryDescriptorBuffer)
           ..write('])$N');

        if (outputClassLists.containsKey(outputUnit)) {
          outputBuffer.write(
              '$finishClassesName($classesCollector,$_${namer.currentIsolate},'
              '$_$isolatePropertiesName)$N');
        }

      }

      // Set the currentIsolate variable to the current isolate (which is
      // provided as second argument).
      // We need to do this, because we use the same variable for setting up
      // the isolate-properties and for storing the current isolate. During
      // the setup (the code above this lines) we must set the variable to
      // the isolate-properties.
      // After we have done the setup (finishing with `finishClasses`) it must
      // point to the current Isolate. Otherwise all methods/functions
      // accessing isolate variables will access the wrong object.
      outputBuffer.write("${namer.currentIsolate}$_=${_}arguments[1]$N");
      typeTestEmitter.emitRuntimeTypeSupport(outputBuffer, outputUnit);

      emitCompileTimeConstants(outputBuffer, outputUnit);
      outputBuffer.write('}$N');

      if (compiler.useContentSecurityPolicy) {
        jsAst.FunctionDeclaration precompiledFunctionAst =
            buildCspPrecompiledFunctionFor(outputUnit);

        outputBuffer.write(
            jsAst.prettyPrint(
                precompiledFunctionAst, compiler,
                monitor: compiler.dumpInfoTask,
                allowVariableMinification: false).getText());
      }

      // Make a unique hash of the code (before the sourcemaps are added)
      // This will be used to retrieve the initializing function from the global
      // variable.
      String hash = hashOfString(outputBuffer.getText());

      outputBuffer.add('${deferredInitializers}["$hash"]$_=$_'
                       '${deferredInitializers}.current$N');

      String partPrefix = deferredPartFileName(outputUnit, addExtension: false);
      if (generateSourceMap) {
        Uri mapUri, partUri;
        Uri sourceMapUri = compiler.sourceMapUri;
        Uri outputUri = compiler.outputUri;

        String partName = "$partPrefix.part";

        if (sourceMapUri != null) {
          String mapFileName = partName + ".js.map";
          List<String> mapSegments = sourceMapUri.pathSegments.toList();
          mapSegments[mapSegments.length - 1] = mapFileName;
          mapUri = compiler.sourceMapUri.replace(pathSegments: mapSegments);
        }

        if (outputUri != null) {
          String partFileName = partName + ".js";
          List<String> partSegments = outputUri.pathSegments.toList();
          partSegments[partSegments.length - 1] = partFileName;
          partUri = compiler.outputUri.replace(pathSegments: partSegments);
        }

        outputSourceMap(outputBuffer.getText(), outputBuffer, partName,
            mapUri, partUri);
        outputBuffer.add(generateSourceMapTag(mapUri, partUri));
      }

      outputBuffers[outputUnit] = outputBuffer;
      compiler.outputProvider(partPrefix, 'part.js')
        ..add(outputBuffer.getText())
        ..close();

      hunkHashes[outputUnit] = hash;
    }
    return hunkHashes;
  }

  String buildGeneratedBy() {
    var suffix = '';
    if (compiler.hasBuildId) suffix = ' version: ${compiler.buildId}';
    return '// Generated by dart2js, the Dart to JavaScript compiler$suffix.\n';
  }

  void outputSourceMap(String code, CodeBuffer buffer, String name,
                       [Uri sourceMapUri, Uri fileUri]) {
    if (!generateSourceMap) return;
    // Create a source file for the compilation output. This allows using
    // [:getLine:] to transform offsets to line numbers in [SourceMapBuilder].
    SourceFile compiledFile = new StringSourceFile(null, code);
    SourceMapBuilder sourceMapBuilder =
            new SourceMapBuilder(sourceMapUri, fileUri, compiledFile);
    buffer.forEachSourceLocation(sourceMapBuilder.addMapping);
    String sourceMap = sourceMapBuilder.build();
    compiler.outputProvider(name, 'js.map')
        ..add(sourceMap)
        ..close();
  }

  void invalidateCaches() {
    if (!compiler.hasIncrementalSupport) return;
    if (cachedElements.isEmpty) return;
    for (Element element in compiler.enqueuer.codegen.newlyEnqueuedElements) {
      if (element.isInstanceMember) {
        cachedClassBuilders.remove(element.enclosingClass);

        nativeEmitter.cachedBuilders.remove(element.enclosingClass);

      }
    }
  }
}
