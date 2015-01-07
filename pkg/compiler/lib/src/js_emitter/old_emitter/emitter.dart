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
  final TypeTestEmitter typeTestEmitter = new TypeTestEmitter();
  final InterceptorEmitter interceptorEmitter = new InterceptorEmitter();
  final MetadataEmitter metadataEmitter = new MetadataEmitter();

  final Set<ConstantValue> cachedEmittedConstants;
  final CodeBuffer cachedEmittedConstantsBuffer = new CodeBuffer();
  final Map<Element, ClassBuilder> cachedClassBuilders;
  final Set<Element> cachedElements;

  bool needsClassSupport = false;
  bool needsMixinSupport = false;
  bool needsLazyInitializer = false;
  /// This is set to true in ContainerBuilder if the program contains
  /// function elements that need extra handling. In this case the element is
  /// stored along with an array containing the needed information.
  bool needsArrayInitializerSupport = false;
  final Namer namer;
  ConstantEmitter constantEmitter;
  NativeEmitter get nativeEmitter => task.nativeEmitter;
  TypeTestRegistry get typeTestRegistry => task.typeTestRegistry;

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
   * dynamically. This doesn't work in CSP mode, so dart2js emits them directly
   * when in CSP mode.
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
    typeTestEmitter.emitter = this;
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

  @override
  jsAst.Expression constantReference(ConstantValue value) {
    return constantEmitter.reference(value);
  }

  jsAst.Expression constantInitializerExpression(ConstantValue value) {
    return constantEmitter.initializationExpression(value);
  }

  String get name => 'CodeEmitter';

  String get finishIsolateConstructorName
      => '${namer.isolateName}.\$finishIsolateConstructor';
  String get isolatePropertiesName
      => '${namer.isolateName}.${namer.isolatePropertiesName}';
  String get lazyInitializerProperty
      => r'$lazy';
  String get lazyInitializerName
      => '${namer.isolateName}.${lazyInitializerProperty}';
  String get initName => 'init';

  String get makeConstListProperty
      => namer.getMappedInstanceName('makeConstantList');

  /// The name of the property that contains all field names.
  ///
  /// This property is added to constructors when isolate support is enabled.
  static const String FIELD_NAMES_PROPERTY_NAME = r"$__fields__";

  /// For deferred loading we communicate the initializers via this global var.
  final String deferredInitializers = r"$dart_deferred_initializers";

  /// All the global state can be passed around with this variable.
  String get globalsHolder => namer.getMappedGlobalName("globalsHolder");

  @override
  jsAst.Expression generateEmbeddedGlobalAccess(String global) {
    return js(generateEmbeddedGlobalAccessString(global));
  }

  String generateEmbeddedGlobalAccessString(String global) {
    // TODO(floitsch): don't use 'init' as global embedder storage.
    return '$initName.$global';
  }

  jsAst.PropertyAccess globalPropertyAccess(Element element) {
    String name = namer.getNameX(element);
    jsAst.PropertyAccess pa = new jsAst.PropertyAccess.field(
        new jsAst.VariableUse(namer.globalObjectFor(element)),
        name);
    return pa;
  }

  @override
  jsAst.Expression isolateLazyInitializerAccess(FieldElement element) {
     return jsAst.js('#.#', [namer.globalObjectFor(element),
                             namer.getLazyInitializerName(element)]);
   }

  @override
  jsAst.Expression isolateStaticClosureAccess(FunctionElement element) {
     return jsAst.js('#.#()',
         [namer.globalObjectFor(element), namer.getStaticClosureName(element)]);
   }

  @override
  jsAst.PropertyAccess staticFieldAccess(FieldElement element) {
    return globalPropertyAccess(element);
  }

  @override
  jsAst.PropertyAccess staticFunctionAccess(FunctionElement element) {
    return globalPropertyAccess(element);
  }

  @override
  jsAst.PropertyAccess constructorAccess(ClassElement element) {
    return globalPropertyAccess(element);
  }

  @override
  jsAst.PropertyAccess prototypeAccess(ClassElement element,
                                       bool hasBeenInstantiated) {
    return jsAst.js('#.prototype', constructorAccess(element));
  }

  @override
  jsAst.PropertyAccess interceptorClassAccess(ClassElement element) {
    return globalPropertyAccess(element);
  }

  @override
  jsAst.PropertyAccess typeAccess(Element element) {
    return globalPropertyAccess(element);
  }

  List<jsAst.Statement> buildTrivialNsmHandlers(){
    return nsmEmitter.buildTrivialNsmHandlers();
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

  List<jsAst.Node> get defineClassFunction {
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

    bool hasIsolateSupport = compiler.hasIsolateSupport;
    String fieldNamesProperty = FIELD_NAMES_PROPERTY_NAME;

    jsAst.Expression defineClass = js('''
        function(name, fields) {
          var accessors = [];
    
          var str = "function " + name + "(";
          var body = "";
          if (#hasIsolateSupport) { var fieldNames = ""; }
    
          for (var i = 0; i < fields.length; i++) {
            if(i != 0) str += ", ";
    
            var field = generateAccessor(fields[i], accessors, name);
            if (#hasIsolateSupport) { fieldNames += "'" + field + "',"; }
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
          if (#hasIsolateSupport) {
            str += name + ".$fieldNamesProperty=[" + fieldNames + "];\\n";
          }
          str += accessors.join("");
    
          return str;
        }''', { 'hasIsolateSupport': hasIsolateSupport });

    // Declare a function called "generateAccessor".  This is used in
    // defineClassFunction.
    List result = <jsAst.Node>[
        generateAccessorFunction,
        new jsAst.FunctionDeclaration(
            new jsAst.VariableDeclaration('defineClass'), defineClass) ];

    if (compiler.hasIncrementalSupport) {
      result.add(
          js(r'#.defineClass = defineClass', [namer.accessIncrementalHelper]));
    }

    if (hasIsolateSupport) {
      jsAst.Expression classIdExtractorAccess =
          generateEmbeddedGlobalAccess(embeddedNames.CLASS_ID_EXTRACTOR);
      var classIdExtractorAssignment =
          js('# = function(o) { return o.constructor.name; }',
              classIdExtractorAccess);

      jsAst.Expression classFieldsExtractorAccess =
          generateEmbeddedGlobalAccess(embeddedNames.CLASS_FIELDS_EXTRACTOR);
      var classFieldsExtractorAssignment = js('''
      # = function(o) {
        var fieldNames = o.constructor.$fieldNamesProperty;
        if (!fieldNames) return [];  // TODO(floitsch): do something else here.
        var result = [];
        result.length = fieldNames.length;
        for (var i = 0; i < fieldNames.length; i++) {
          result[i] = o[fieldNames[i]];
        }
        return result;
      }''', classFieldsExtractorAccess);

      jsAst.Expression instanceFromClassIdAccess =
          generateEmbeddedGlobalAccess(embeddedNames.INSTANCE_FROM_CLASS_ID);
      jsAst.Expression allClassesAccess =
          generateEmbeddedGlobalAccess(embeddedNames.ALL_CLASSES);
      var instanceFromClassIdAssignment =
          js('# = function(name) { return new #[name](); }',
             [instanceFromClassIdAccess, allClassesAccess]);

      jsAst.Expression initializeEmptyInstanceAccess =
          generateEmbeddedGlobalAccess(embeddedNames.INITIALIZE_EMPTY_INSTANCE);
      var initializeEmptyInstanceAssignment = js('''
      # = function(name, o, fields) {
        #[name].apply(o, fields);
        return o;
      }''', [ initializeEmptyInstanceAccess, allClassesAccess ]);

      result.addAll([classIdExtractorAssignment,
                     classFieldsExtractorAssignment,
                     instanceFromClassIdAssignment,
                     initializeEmptyInstanceAssignment]);
    }

    return result;
  }

  /** Needs defineClass to be defined. */
  jsAst.Expression buildInheritFrom() {
    jsAst.Expression result = js(r'''
        function() {
          function tmp() {}
          var hasOwnProperty = Object.prototype.hasOwnProperty;
          return function (constructor, superConstructor) {
            if (superConstructor == null) {
              // TODO(21896): this test shouldn't be necessary. Without it
              // we have a crash in language/mixin_only_for_rti and
              // pkg/analysis_server/tool/spec/check_all_test.
              if (constructor == null) return;

              // Fix up the the Dart Object class' prototype.
              var prototype = constructor.prototype;
              prototype.constructor = constructor;
              return prototype;
            }
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
      result = js(
          r'#.inheritFrom = #', [namer.accessIncrementalHelper, result]);
    }
    return js(r'var inheritFrom = #', [result]);
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

        var superclass = processedClasses.pending[cls];

        if (#needsMixinSupport) {
          if (superclass && superclass.indexOf("+") > 0) {
            var s = superclass.split("+");
            superclass = s[0];
            var mixinClass = s[1];
            finishClass(mixinClass);
            var mixin = allClasses[mixinClass];
            // TODO(21896): this test shouldn't be necessary. Without it
            // we have a crash in language/mixin_only_for_rti and
            // pkg/analysis_server/tool/spec/check_all_test.
            if (mixin) {
              var mixinPrototype = mixin.prototype;
              var clsPrototype = allClasses[cls].prototype;
              for (var d in mixinPrototype) {
                if (hasOwnProperty.call(mixinPrototype, d) &&
                    !hasOwnProperty.call(clsPrototype, d))
                  clsPrototype[d] = mixinPrototype[d];
              }
            }
          }
        }

        // The superclass is only false (empty string) for the Dart Object
        // class.  The minifier together with noSuchMethod can put methods on
        // the Object.prototype object, and they show through here, so we check
        // that we have a string.
        if (!superclass || typeof superclass != "string") {
          inheritFrom(allClasses[cls], null);
          return;
        }
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
                    subclass.#nativeSuperclassTagName = tags[0];
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
           'needsMixinSupport': needsMixinSupport,
           'hasNativeClasses': nativeClasses.isNotEmpty,
           'nativeSuperclassTagName': embeddedNames.NATIVE_SUPERCLASS_TAG_NAME,
           'interceptorsByTagAccess': interceptorsByTagAccess,
           'leafTagsAccess': leafTagsAccess,
           'allowNativesSubclassing': true});
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
         new jsAst.ArrayInitializer(
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

  void emitStaticFunctions(List<Element> staticFunctions) {
    for (Element element in staticFunctions) {
      ClassBuilder builder = new ClassBuilder(element, namer);
      containerBuilder.addMember(element, builder);
      getElementDescriptor(element).properties.addAll(builder.properties);
    }
  }

  void emitStaticNonFinalFieldInitializations(CodeBuffer buffer,
                                              OutputUnit outputUnit) {
    JavaScriptConstantCompiler handler = backend.constants;
    Iterable<VariableElement> staticNonFinalFields =
        handler.getStaticNonFinalFieldsForEmission();
    for (Element element in Elements.sortedByPosition(staticNonFinalFields)) {
      // [:interceptedNames:] is handled in [emitInterceptedNames].
      if (element == backend.interceptedNames) continue;
      // `mapTypeToInterceptor` is handled in [emitMapTypeToInterceptor].
      if (element == backend.mapTypeToInterceptor) continue;
      compiler.withCurrentElement(element, () {
        jsAst.Expression initialValue;
        if (outputUnit !=
            compiler.deferredLoadTask.outputUnitForElement(element)) {
          if (outputUnit == compiler.deferredLoadTask.mainOutputUnit) {
            // In the main output-unit we output a stub initializer for deferred
            // variables, such that `isolateProperties` stays a fast object.
            initialValue = jsAst.number(0);
          } else {
            // Don't output stubs outside the main output file.
            return;
          }
        } else {
          initialValue = constantEmitter.referenceInInitializationContext(
              handler.getInitialValueFor(element).value);

        }
        jsAst.Expression init =
          js('$isolateProperties.# = #',
              [namer.getNameOfGlobalField(element), initialValue]);
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
        jsAst.Expression init =
            buildLazilyInitializedStaticField(element, isolateProperties);
        if (init == null) continue;
        buffer.write(
            jsAst.prettyPrint(init, compiler, monitor: compiler.dumpInfoTask));
        buffer.write("$N");
      }
    }
  }

  jsAst.Expression buildLazilyInitializedStaticField(
      VariableElement element, String isolateProperties) {
    jsAst.Expression code = backend.generatedCode[element];
    // The code is null if we ended up not needing the lazily
    // initialized field after all because of constant folding
    // before code generation.
    if (code == null) return null;
    // The code only computes the initial value. We build the lazy-check
    // here:
    //   lazyInitializer(prototype, 'name', fieldName, getterName, initial);
    // The name is used for error reporting. The 'initial' must be a
    // closure that constructs the initial value.
    return js('#(#,#,#,#,#)',
        [js(lazyInitializerName),
            js(isolateProperties),
            js.string(element.name),
            js.string(namer.getNameX(element)),
            js.string(namer.getLazyInitializerName(element)),
            code]);
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
      jsAst.Expression init = buildConstantInitializer(constant);
      buffer.write(jsAst.prettyPrint(init, compiler,
                                     monitor: compiler.dumpInfoTask));
      buffer.write('$N');
    }
    if (compiler.hasIncrementalSupport && isMainBuffer) {
      mainBuffer.write(cachedEmittedConstantsBuffer);
    }
  }

  jsAst.Expression buildConstantInitializer(ConstantValue constant) {
    String name = namer.constantName(constant);
    return js('#.# = #',
              [namer.globalObjectForConstant(constant), name,
               constantInitializerExpression(constant)]);
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
    jsAst.Expression mainAccess = isolateStaticClosureAccess(appMain);
    // Since we pass the closurized version of the main method to
    // the isolate method, we must make sure that it exists.
    return js('function(a){ #(#, a); }',
        [backend.emitter.staticFunctionAccess(isolateMain), mainAccess]);
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
      mainCallClosure = js(
          'function() { return #(); }',
          backend.emitter.staticFunctionAccess(main));
    } else {
      mainCallClosure = backend.emitter.staticFunctionAccess(main);
    }

    if (NativeGenerator.needsIsolateAffinityTagInitialization(backend)) {
      jsAst.Statement nativeBoilerPlate =
          NativeGenerator.generateIsolateAffinityTagInitialization(
              backend,
              generateEmbeddedGlobalAccess,
              js("convertToFastObject", []));
      buffer.write(jsAst.prettyPrint(nativeBoilerPlate,
                                     compiler, monitor: compiler.dumpInfoTask));
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
  #currentScript = currentScript;

  if (typeof dartMainRunner === "function") {
    dartMainRunner(#mainCallClosure, []);
  } else {
    #mainCallClosure([]);
  }
})''', {'currentScript': currentScriptAccess,
        'mainCallClosure': mainCallClosure});

    buffer.write(';');
    buffer.write(jsAst.prettyPrint(invokeMain,
                 compiler, monitor: compiler.dumpInfoTask));
    buffer.write(N);
    addComment('END invoke [main].', buffer);
  }

  void emitInitFunction(CodeBuffer buffer) {
    String isolate = namer.currentIsolate;
    jsAst.Expression allClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.ALL_CLASSES);
    jsAst.Expression interceptorsByTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.INTERCEPTORS_BY_TAG);
    jsAst.Expression leafTagsAccess =
        generateEmbeddedGlobalAccess(embeddedNames.LEAF_TAGS);
    jsAst.Expression finishedClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.FINISHED_CLASSES);
    jsAst.Expression cyclicThrow =
        staticFunctionAccess(backend.getCyclicThrowHelper());
    jsAst.Expression laziesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.LAZIES);

    jsAst.FunctionDeclaration decl = js.statement('''
      function init() {
        $isolateProperties = Object.create(null);
        #allClasses = Object.create(null);
        #interceptorsByTag = Object.create(null);
        #leafTags = Object.create(null);
        #finishedClasses = Object.create(null);

        if (#needsLazyInitializer) {
          $lazyInitializerName = function (prototype, staticName, fieldName,
                                           getterName, lazyValue) {
            if (!#lazies) #lazies = Object.create(null);
            #lazies[fieldName] = getterName;
  
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
                    #cyclicThrow(staticName);
                }
  
                return result;
              } finally {
                $isolate[getterName] = function() { return this[fieldName]; };
              }
            }
          }
        }

        // We replace the old Isolate function with a new one that initializes
        // all its fields with the initial (and often final) value of all
        // globals.
        //
        // We also copy over old values like the prototype, and the
        // isolateProperties themselves.
        $finishIsolateConstructorName = function (oldIsolate) {
          var isolateProperties = oldIsolate.#isolatePropertiesName;
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
          Isolate.#isolatePropertiesName = isolateProperties;
          if (#outputContainsConstantList) {
            Isolate.#makeConstListProperty = oldIsolate.#makeConstListProperty;
          }
          if (#hasIncrementalSupport) {
            Isolate.#lazyInitializerProperty =
                oldIsolate.#lazyInitializerProperty;
          }
          return Isolate;
      }
        
      }''', {'allClasses': allClassesAccess,
            'interceptorsByTag': interceptorsByTagAccess,
            'leafTags': leafTagsAccess,
            'finishedClasses': finishedClassesAccess,
            'needsLazyInitializer': needsLazyInitializer,
            'lazies': laziesAccess, 'cyclicThrow': cyclicThrow,
            'isolatePropertiesName': namer.isolatePropertiesName,
            'outputContainsConstantList': task.outputContainsConstantList,
            'makeConstListProperty': makeConstListProperty,
            'hasIncrementalSupport': compiler.hasIncrementalSupport,
            'lazyInitializerProperty': lazyInitializerProperty,});

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

    mainBuffer.write(jsAst.prettyPrint(convertToFastObject, compiler));
    mainBuffer.write(N);
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
                                  jsAst.Expression constructorAst,
                                  List<String> fields) {
    cspPrecompiledFunctionFor(outputUnit).add(
        new jsAst.FunctionDeclaration(
            new jsAst.VariableDeclaration(constructorName), constructorAst));

    String fieldNamesProperty = FIELD_NAMES_PROPERTY_NAME;
    bool hasIsolateSupport = compiler.hasIsolateSupport;
    jsAst.Node fieldNamesArray =
        hasIsolateSupport ? js.stringArray(fields) : new jsAst.LiteralNull();

    cspPrecompiledFunctionFor(outputUnit).add(js.statement(r'''
        {
          #constructorName.builtin$cls = #constructorNameString;
          if (!"name" in #constructorName)
              #constructorName.name = #constructorNameString;
          $desc = $collectedClasses.#constructorName;
          if ($desc instanceof Array) $desc = $desc[1];
          #constructorName.prototype = $desc;
          ''' /* next string is not a raw string */ '''
          if (#hasIsolateSupport) {
            #constructorName.$fieldNamesProperty = #fieldNamesArray;
          } 
        }''',
        {"constructorName": constructorName,
         "constructorNameString": js.string(constructorName),
         "hasIsolateSupport": hasIsolateSupport,
         "fieldNamesArray": fieldNamesArray}));

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
      if (classEmitter.emitFields(library, builder, emitStatics: true)) {
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
      ClassBuilder builder = new ClassBuilder(typedef, namer);
      builder.addProperty(embeddedNames.TYPEDEF_TYPE_PROPERTY_NAME,
                          js.number(typeIndex));
      builder.addProperty(embeddedNames.TYPEDEF_PREDICATE_PROPERTY_NAME,
                          js.boolean(true));

      // We can be pretty sure that the objectClass is initialized, since
      // typedefs are only emitted with reflection, which requires lots of
      // classes.
      assert(compiler.objectClass != null);
      builder.superName = namer.getNameOfClass(compiler.objectClass);
      jsAst.Node declaration = builder.toObjectInitializer();
      String mangledName = namer.getNameX(typedef);
      String reflectionName = getReflectionName(typedef, mangledName);
      getElementDescriptor(library)
          ..addProperty(mangledName, declaration)
          ..addProperty("+$reflectionName", js.string(''));
      // Also emit a trivial constructor for CSP mode.
      String constructorName = mangledName;
      jsAst.Expression constructorAst = js('function() {}');
      List<String> fieldNames = [];
      emitPrecompiledConstructor(mainOutputUnit,
                                 constructorName,
                                 constructorAst,
                                 fieldNames);
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

    mainBuffer.write(buildGeneratedBy());
    addComment(HOOKS_API_USAGE, mainBuffer);

    if (isProgramSplit) {
      /// For deferred loading we communicate the initializers via this global
      /// variable. The deferred hunks will add their initialization to this.
      /// The semicolon is important in minified mode, without it the
      /// following parenthesis looks like a call to the object literal.
      mainBuffer..write(
          'self.${deferredInitializers} = self.${deferredInitializers} || '
          'Object.create(null);$n');
    }

    // Using a named function here produces easier to read stack traces in
    // Chrome/V8.
    mainBuffer.write('(function(${namer.currentIsolate})$_{\n');
    if (compiler.hasIncrementalSupport) {
      mainBuffer.write(jsAst.prettyPrint(js.statement(
          """
{
  #helper = #helper || Object.create(null);
  #helper.patch = function(a) { eval(a)};
  #helper.schemaChange = #schemaChange;
  #helper.addMethod = #addMethod;
  #helper.extractStubs = function(array, name, isStatic, originalDescriptor) {
    var descriptor = Object.create(null);
    this.addStubs(descriptor, array, name, isStatic, originalDescriptor, []);
    return descriptor;
  };
}""",
          { 'helper': js('this.#', [namer.incrementalHelperName]),
            'schemaChange': buildSchemaChangeFunction(),
            'addMethod': buildIncrementalAddMethod() }), compiler));
    }
    if (isProgramSplit) {
      /// We collect all the global state of the, so it can be passed to the
      /// initializer of deferred files.
      mainBuffer.write('var ${globalsHolder}$_=${_}Object.create(null)$N');
    }

    jsAst.Statement mapFunction = js.statement('''
// [map] returns an object that V8 shouldn't try to optimize with a hidden
// class. This prevents a potential performance problem where V8 tries to build
// a hidden class for an object used as a hashMap.
// It requires fewer characters to declare a variable as a parameter than
// with `var`.
  function map(x) {
    x = Object.create(null);
    x.x = 0;
    delete x.x;
    return x;
  }
''');
    mainBuffer.write(jsAst.prettyPrint(mapFunction, compiler));
    for (String globalObject in Namer.reservedGlobalObjectNames) {
      // The global objects start as so-called "slow objects". For V8, this
      // means that it won't try to make map transitions as we add properties
      // to these objects. Later on, we attempt to turn these objects into
      // fast objects by calling "convertToFastObject" (see
      // [emitConvertToFastObjectFunction]).
      mainBuffer.write('var ${globalObject}$_=${_}');
      if(isProgramSplit) {
        mainBuffer.write('${globalsHolder}.$globalObject$_=${_}');
      }
      mainBuffer.write('map()$N');
    }

    mainBuffer.write('function ${namer.isolateName}()$_{}\n');
    if (isProgramSplit) {
      mainBuffer.write(
          '${globalsHolder}.${namer.isolateName}$_=$_${namer.isolateName}$N'
          '${globalsHolder}.$initName$_=${_}$initName$N'
          '${globalsHolder}.$parseReflectionDataName$_=$_'
            '$parseReflectionDataName$N');
    }
    mainBuffer.write('init()$N$n');
    mainBuffer.write('$isolateProperties$_=$_$isolatePropertiesName$N');

    emitStaticFunctions(task.outputStaticLists[mainOutputUnit]);

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
          ..write(
              jsAst.prettyPrint(
                  getReflectionDataParser(this, backend),
                  compiler))
          ..write(n);

      // The argument to reflectionDataParser is assigned to a temporary 'dart'
      // so that 'dart.' will appear as the prefix to dart methods in stack
      // traces and profile entries.
      mainBuffer..write('var dart = [$n')
                ..write(libraryBuffer)
                ..write(']$N')
                ..write('$parseReflectionDataName(dart)$N');
    }

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
    emitStaticNonFinalFieldInitializations(mainBuffer, mainOutputUnit);
    interceptorEmitter.emitInterceptedNames(mainBuffer);
    interceptorEmitter.emitMapTypeToInterceptor(mainBuffer);
    emitLazilyInitializedStaticFields(mainBuffer);

    mainBuffer.writeln();
    mainBuffer.write(nativeBuffer);

    metadataEmitter.emitMetadata(mainBuffer);

    isolateProperties = isolatePropertiesName;
    // The following code should not use the short-hand for the
    // initialStatics.
    mainBuffer.write('${namer.currentIsolate}$_=${_}null$N');

    emitFinishIsolateConstructorInvocation(mainBuffer);
    mainBuffer.write(
        '${namer.currentIsolate}$_=${_}new ${namer.isolateName}()$N');

    emitConvertToFastObjectFunction();
    for (String globalObject in Namer.reservedGlobalObjectNames) {
      mainBuffer.write('$globalObject = convertToFastObject($globalObject)$N');
    }
    if (DEBUG_FAST_OBJECTS) {
      mainBuffer.write(r'''
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
      mainBuffer.write('''
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
    mainBuffer.write('})()\n');

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
      mainBuffer.write(
          generateSourceMapTag(compiler.sourceMapUri, compiler.outputUri));
      assembledCode = mainBuffer.getText();
    }

    compiler.outputProvider('', 'js')
        ..add(assembledCode)
        ..close();
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

  /// Used by incremental compilation to patch up an object ([holder]) with a
  /// new (or updated) method.  [arrayOrFunction] is either the new method, or
  /// an array containing the method (see
  /// [ContainerBuilder.addMemberMethodFromInfo]). [name] is the name of the
  /// new method. [isStatic] tells if method is static (or
  /// top-level). [globalFunctionsAccess] is a reference to
  /// [embeddedNames.GLOBAL_FUNCTIONS].
  jsAst.Fun buildIncrementalAddMethod() {
    return js(r"""
function(originalDescriptor, name, holder, isStatic, globalFunctionsAccess) {
  var arrayOrFunction = originalDescriptor[name];
  var method;
  if (arrayOrFunction.constructor === Array) {
    var existing = holder[name];
    var array = arrayOrFunction;

    // Each method may have a number of stubs associated. For example, if an
    // instance method supports multiple arguments, a stub for each matching
    // selector. There is also a getter stub for tear-off getters. For example,
    // an instance method foo([a]) may have the following stubs: foo$0, foo$1,
    // and get$foo (here exemplified using unminified names).
    // [extractStubs] returns a JavaScript object whose own properties
    // corresponds to the stubs.
    var descriptor =
        this.extractStubs(array, name, isStatic, originalDescriptor);
    method = descriptor[name];

    // Iterate through the properties of descriptor and copy the stubs to the
    // existing holder (for instance methods, a prototype).
    for (var property in descriptor) {
      if (!Object.prototype.hasOwnProperty.call(descriptor, property)) continue;
      var stub = descriptor[property];
      var existingStub = holder[property];
      if (stub === method || !existingStub || !stub.$getterStub) {
        // Not replacing an existing getter stub.
        holder[property] = stub;
        continue;
      }
      if (!stub.$getterStub) {
        var error = new Error('Unexpected stub.');
        error.stub = stub;
        throw error;
      }

      // Existing getter stubs need special treatment as they may already have
      // been called and produced a closure.
      this.pendingStubs = this.pendingStubs || [];
      // It isn't safe to invoke the stub yet.
      this.pendingStubs.push((function(holder, stub, existingStub, existing,
                                       method) {
        return function() {
          var receiver = isStatic ? holder : new holder.constructor();
          // Invoke the existing stub to obtain the tear-off closure.
          existingStub = existingStub.call(receiver);
          // Invoke the new stub to create a tear-off closure we can use as a
          // prototype.
          stub = stub.call(receiver);

          // Copy the properties from the new tear-off's prototype to the
          // prototype of the existing tear-off.
          var newProto = stub.constructor.prototype;
          var existingProto = existingStub.constructor.prototype;
          for (var stubProperty in newProto) {
            if (!Object.prototype.hasOwnProperty.call(newProto, stubProperty))
              continue;
            existingProto[stubProperty] = newProto[stubProperty];
          }

          // Update all the existing stub's references to [existing] to
          // [method]. Instance tear-offs are call-by-name, so this isn't
          // necessary for those.
          if (!isStatic) return;
          for (var reference in existingStub) {
            if (existingStub[reference] === existing) {
              existingStub[reference] = method;
            }
          }
        }
      })(holder, stub, existingStub, existing, method));
    }
  } else {
    method = arrayOrFunction;
    holder[name] = method;
  }
  if (isStatic) globalFunctionsAccess[name] = method;
}""");
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

  int emitProgram(Program program) {
    // Shorten the code by using [namer.currentIsolate] as temporary.
    isolateProperties = namer.currentIsolate;

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

    // Return the total program size.
    return outputBuffers.values.fold(0, (a, b) => a + b.length);
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
      if (compiler.codegenWorld.directlyInstantiatedClasses.contains(cls) &&
          !cls.isNative &&
          compiler.deferredLoadTask.outputUnitForElement(element) ==
              compiler.deferredLoadTask.outputUnitForElement(cls)) {
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
    jsAst.Statement functions = js.statement('''
        {
          // Function for checking if a hunk is loaded given its hash.
          #isHunkLoaded = function(hunkHash) {
            return !!$deferredInitializers[hunkHash];
          };
          #deferredInitialized = new Object(null);
          // Function for checking if a hunk is initialized given its hash.
          #isHunkInitialized = function(hunkHash) {
            return #deferredInitialized[hunkHash];
          };
          // Function for initializing a loaded hunk, given its hash.
          #initializeLoadedHunk = function(hunkHash) {
            $deferredInitializers[hunkHash](
            $globalsHolder, ${namer.currentIsolate});
            #deferredInitialized[hunkHash] = true;
          };
        }
        ''', {"isHunkLoaded": generateEmbeddedGlobalAccess(
                  embeddedNames.IS_HUNK_LOADED),
              "isHunkInitialized": generateEmbeddedGlobalAccess(
                  embeddedNames.IS_HUNK_INITIALIZED),
              "initializeLoadedHunk": generateEmbeddedGlobalAccess(
                  embeddedNames.INITIALIZE_LOADED_HUNK),
              "deferredInitialized": generateEmbeddedGlobalAccess(
                  embeddedNames.DEFERRED_INITIALIZED)});
    buffer.write(jsAst.prettyPrint(functions,
        compiler, monitor: compiler.dumpInfoTask));
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
            new jsAst.ArrayInitializer(
                values.map(js.escapedString).toList())));
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
          ..write('var $parseReflectionDataName$_=$_'
                    '$globalsHolder.$parseReflectionDataName$N')
          ..write('var ${namer.isolateName}$_=$_'
                    '${globalsHolder}.${namer.isolateName}$N');
      if (libraryDescriptorBuffer != null) {
      // TODO(ahe): This defines a lot of properties on the
      // Isolate.prototype object.  We know this will turn it into a
      // slow object in V8, so instead we should do something similar
      // to Isolate.$finishIsolateConstructor.
         outputBuffer
           ..write('var ${namer.currentIsolate}$_=$_$isolatePropertiesName$N')
            // The argument to reflectionDataParser is assigned to a temporary
            // 'dart' so that 'dart.' will appear as the prefix to dart methods
            // in stack traces and profile entries.
           ..write('var dart = [$n ')
           ..addBuffer(libraryDescriptorBuffer)
           ..write(']$N')
           ..write('$parseReflectionDataName(dart)$N');

      }

      // Set the currentIsolate variable to the current isolate (which is
      // provided as second argument).
      // We need to do this, because we use the same variable for setting up
      // the isolate-properties and for storing the current isolate. During
      // the setup (the code above this lines) we must set the variable to
      // the isolate-properties.
      // After we have done the setup it must point to the current Isolate.
      // Otherwise all methods/functions accessing isolate variables will
      // access the wrong object.
      outputBuffer.write("${namer.currentIsolate}$_=${_}arguments[1]$N");

      emitCompileTimeConstants(outputBuffer, outputUnit);
      emitStaticNonFinalFieldInitializations(outputBuffer, outputUnit);
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

      outputBuffer.write('${deferredInitializers}["$hash"]$_=$_'
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
        outputBuffer.write(generateSourceMapTag(mapUri, partUri));
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
