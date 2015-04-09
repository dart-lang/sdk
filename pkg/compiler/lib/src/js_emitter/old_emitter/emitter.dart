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
  final InterceptorEmitter interceptorEmitter = new InterceptorEmitter();

  // TODO(johnniwinther): Wrap these fields in a caching strategy.
  final Set<ConstantValue> cachedEmittedConstants;
  final CodeBuffer cachedEmittedConstantsBuffer = new CodeBuffer();
  final Map<Element, ClassBuilder> cachedClassBuilders;
  final Set<Element> cachedElements;

  bool needsClassSupport = false;
  bool needsMixinSupport = false;
  bool needsLazyInitializer = false;

  /// True if [ContainerBuilder.addMemberMethodFromInfo] used "structured info",
  /// that is, some function was needed for reflection, had stubs, or had a
  /// super alias.
  bool needsStructuredMemberInfo = false;

  final Namer namer;
  ConstantEmitter constantEmitter;
  NativeEmitter get nativeEmitter => task.nativeEmitter;
  TypeTestRegistry get typeTestRegistry => task.typeTestRegistry;

  // The full code that is written to each hunk part-file.
  Map<OutputUnit, CodeOutput> outputBuffers = new Map<OutputUnit, CodeOutput>();

  /** Shorter access to [isolatePropertiesName]. Both here in the code, as
      well as in the generated code. */
  String isolateProperties;
  String classesCollector;
  Set<ClassElement> get neededClasses => task.neededClasses;
  Map<OutputUnit, List<ClassElement>> get outputClassLists
      => task.outputClassLists;
  Map<OutputUnit, List<ConstantValue>> get outputConstantLists
      => task.outputConstantLists;
  final Map<String, String> mangledFieldNames = <String, String>{};
  final Map<String, String> mangledGlobalFieldNames = <String, String>{};
  final Set<String> recordedMangledNames = new Set<String>();

  List<TypedefElement> get typedefsNeededForReflection =>
      task.typedefsNeededForReflection;

  JavaScriptBackend get backend => compiler.backend;
  TypeVariableHandler get typeVariableHandler => backend.typeVariableHandler;

  String get _ => space;
  String get space => compiler.enableMinification ? "" : " ";
  String get n => compiler.enableMinification ? "" : "\n";
  String get N => compiler.enableMinification ? "\n" : ";\n";

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
    constantEmitter = new ConstantEmitter(
        compiler, namer, this.constantReference, makeConstantListTemplate);
    containerBuilder.emitter = this;
    classEmitter.emitter = this;
    nsmEmitter.emitter = this;
    interceptorEmitter.emitter = this;
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

  void addComment(String comment, CodeOutput output) {
    output.addBuffer(jsAst.prettyPrint(js.comment(comment), compiler));
  }

  @override
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

  @override
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

  @override
  jsAst.Expression constantReference(ConstantValue value) {
    if (value.isFunction) {
      FunctionConstantValue functionConstant = value;
      return isolateStaticClosureAccess(functionConstant.element);
    }

    // We are only interested in the "isInlined" part, but it does not hurt to
    // test for the other predicates.
    if (isConstantInlinedOrAlreadyEmitted(value)) {
      return constantEmitter.generate(value);
    }
    return js('#.#', [namer.globalObjectForConstant(value),
                      namer.constantName(value)]);
  }

  jsAst.Expression constantInitializerExpression(ConstantValue value) {
    return constantEmitter.generate(value);
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

  String get makeConstListProperty => namer.internalGlobal('makeConstantList');

  /// The name of the property that contains all field names.
  ///
  /// This property is added to constructors when isolate support is enabled.
  static const String FIELD_NAMES_PROPERTY_NAME = r"$__fields__";

  /// For deferred loading we communicate the initializers via this global var.
  final String deferredInitializers = r"$dart_deferred_initializers";

  /// Contains the global state that is needed to initialize and load a
  /// deferred library.
  String get globalsHolder => namer.internalGlobal("globalsHolder");

  @override
  jsAst.Expression generateEmbeddedGlobalAccess(String global) {
    return js(generateEmbeddedGlobalAccessString(global));
  }

  String generateEmbeddedGlobalAccessString(String global) {
    // TODO(floitsch): don't use 'init' as global embedder storage.
    return '$initName.$global';
  }

  jsAst.PropertyAccess globalPropertyAccess(Element element) {
    String name = namer.globalPropertyName(element);
    jsAst.PropertyAccess pa = new jsAst.PropertyAccess.field(
        new jsAst.VariableUse(namer.globalObjectFor(element)),
        name);
    return pa;
  }

  @override
  jsAst.Expression isolateLazyInitializerAccess(FieldElement element) {
     return jsAst.js('#.#', [namer.globalObjectFor(element),
                             namer.lazyInitializerName(element)]);
   }

  @override
  jsAst.Expression isolateStaticClosureAccess(FunctionElement element) {
     return jsAst.js('#.#()',
         [namer.globalObjectFor(element), namer.staticClosureName(element)]);
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

    jsAst.Expression defineClass = js(r'''
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
            body += ("this." + field + " = " + parameter + ";\n");
          }
          str += ") {\n" + body + "}\n";
          str += name + ".builtin$cls=\"" + name + "\";\n";
          str += "$desc=$collectedClasses." + name + ";\n";
          str += "if($desc instanceof Array) $desc = \$desc[1];\n";
          str += name + ".prototype = $desc;\n";
          if (typeof defineClass.name != "string") {
            str += name + ".name=\"" + name + "\";\n";
          }
          if (#hasIsolateSupport) {
            str += name + "." + #fieldNamesProperty + "=[" + fieldNames
                   + "];\n";
          }
          str += accessors.join("");

          return str;
        }''', { 'hasIsolateSupport': hasIsolateSupport,
                'fieldNamesProperty': js.string(fieldNamesProperty)});

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
      jsAst.Expression createNewIsolateFunctionAccess =
          generateEmbeddedGlobalAccess(embeddedNames.CREATE_NEW_ISOLATE);
      var createIsolateAssignment =
          js('# = function() { return new ${namer.isolateName}(); }',
             createNewIsolateFunctionAccess);

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

      result.addAll([createIsolateAssignment,
                     classIdExtractorAssignment,
                     classFieldsExtractorAssignment,
                     instanceFromClassIdAssignment,
                     initializeEmptyInstanceAssignment]);
    }

    return result;
  }

  /** Needs defineClass to be defined. */
  jsAst.Expression buildInheritFrom() {
    jsAst.Expression result = js(r"""
        function() {
          function tmp() {}
          return function (constructor, superConstructor) {
            if (superConstructor == null) {
              // Fix up the the Dart Object class' prototype.
              var prototype = constructor.prototype;
              prototype.constructor = constructor;
              prototype.#isObject = constructor;
              return prototype;
            }
            tmp.prototype = superConstructor.prototype;
            var object = new tmp();
            var properties = constructor.prototype;
            var members = Object.keys(properties);
            for (var i = 0; i < members.length; i++) {
              var member = members[i];
              object[member] = properties[member];
            }
            // Use a function for `true` here, as functions are stored in the
            // hidden class and not as properties in the object.
            object[#operatorIsPrefix + constructor.name] = constructor;
            object.constructor = constructor;
            constructor.prototype = object;
            return object;
          };
        }()
      """, { 'operatorIsPrefix' : js.string(namer.operatorIsPrefix),
             'isObject' : namer.operatorIs(compiler.objectClass) });
    if (compiler.hasIncrementalSupport) {
      result = js(
          r'#.inheritFrom = #', [namer.accessIncrementalHelper, result]);
    }
    return js(r'var inheritFrom = #', [result]);
  }

  jsAst.Statement buildFinishClass(bool needsNativeSupport) {
    String specProperty = '"${namer.nativeSpecProperty}"';  // "%"

    jsAst.Expression finishedClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.FINISHED_CLASSES);

    jsAst.Expression nativeInfoAccess = js('prototype[$specProperty]', []);
    jsAst.Expression constructorAccess = js('constructor', []);
    Function subclassReadGenerator =
        (jsAst.Expression subclass) => js('allClasses[#]', subclass);
    jsAst.Expression interceptorsByTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.INTERCEPTORS_BY_TAG);
    jsAst.Expression leafTagsAccess =
        generateEmbeddedGlobalAccess(embeddedNames.LEAF_TAGS);
    jsAst.Statement nativeInfoHandler = nativeEmitter.buildNativeInfoHandler(
        nativeInfoAccess,
        constructorAccess,
        subclassReadGenerator,
        interceptorsByTagAccess,
        leafTagsAccess);

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
            var mixinPrototype = mixin.prototype;
            var clsPrototype = allClasses[cls].prototype;

            var properties = Object.keys(mixinPrototype);
            for (var i = 0; i < properties.length; i++) {
              var d = properties[i];
              if (!hasOwnProperty.call(clsPrototype, d))
                clsPrototype[d] = mixinPrototype[d];
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

        if (#needsNativeSupport)
          if (Object.prototype.hasOwnProperty.call(prototype, $specProperty))
            #nativeInfoHandler
      }
    }''', {'finishedClassesAccess': finishedClassesAccess,
           'needsMixinSupport': needsMixinSupport,
           'needsNativeSupport': needsNativeSupport,
           'nativeInfoHandler': nativeInfoHandler});
  }

  void emitFinishIsolateConstructorInvocation(CodeOutput output) {
    String isolate = namer.isolateName;
    output.add("$isolate = $finishIsolateConstructorName($isolate)$N");
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

  jsAst.Statement buildCspPrecompiledFunctionFor(
      OutputUnit outputUnit) {
    // TODO(ahe): Compute a hash code.
    // TODO(sigurdm): Avoid this precompiled function. Generated
    // constructor-functions and getter/setter functions can be stored in the
    // library-description table. Setting properties on these can be moved to
    // finishClasses.
    return js.statement('''
      # = function (\$collectedClasses) {
        var \$desc;
        #;
        return #;
      };''',
        [generateEmbeddedGlobalAccess(embeddedNames.PRECOMPILED),
         cspPrecompiledFunctionFor(outputUnit),
         new jsAst.ArrayInitializer(
             cspPrecompiledConstructorNamesFor(outputUnit))]);
  }

  void emitClass(Class cls, ClassBuilder enclosingBuilder) {
    ClassElement classElement = cls.element;
    compiler.withCurrentElement(classElement, () {
      if (compiler.hasIncrementalSupport) {
        ClassBuilder cachedBuilder =
            cachedClassBuilders.putIfAbsent(classElement, () {
              ClassBuilder builder = new ClassBuilder(classElement, namer);
              classEmitter.emitClass(cls, builder);
              return builder;
            });
        invariant(classElement, cachedBuilder.fields.isEmpty);
        invariant(classElement, cachedBuilder.superName == null);
        invariant(classElement, cachedBuilder.functionType == null);
        invariant(classElement, cachedBuilder.fieldMetadata == null);
        enclosingBuilder.properties.addAll(cachedBuilder.properties);
      } else {
        classEmitter.emitClass(cls, enclosingBuilder);
      }
    });
  }

  void emitStaticFunctions(Iterable<Method> staticFunctions) {
    if (staticFunctions == null) return;

    for (Method method in staticFunctions) {
      Element element = method.element;
      // We need to filter out null-elements for the interceptors.
      // TODO(floitsch): use the precomputed interceptors here.
      if (element == null) continue;
      ClassBuilder builder = new ClassBuilder(element, namer);
      containerBuilder.addMemberMethod(method, builder);
      getElementDescriptor(element).properties.addAll(builder.properties);
    }
  }

  void emitStaticNonFinalFieldInitializations(CodeOutput output,
                                              OutputUnit outputUnit) {
    void emitInitialization(Element element, jsAst.Expression initialValue) {
      jsAst.Expression init =
        js('$isolateProperties.# = #',
            [namer.globalPropertyName(element), initialValue]);
      output.addBuffer(jsAst.prettyPrint(init, compiler,
                                         monitor: compiler.dumpInfoTask));
      output.add('$N');
    }

    bool inMainUnit = (outputUnit == compiler.deferredLoadTask.mainOutputUnit);
    JavaScriptConstantCompiler handler = backend.constants;

    Iterable<Element> fields = task.outputStaticNonFinalFieldLists[outputUnit];
    // If the outputUnit does not contain any static non-final fields, then
    // [fields] is `null`.
    if (fields != null) {
      for (Element element in fields) {
        compiler.withCurrentElement(element, () {
          ConstantValue constant = handler.getInitialValueFor(element).value;
          emitInitialization(element, constantReference(constant));
        });
      }
    }

    if (inMainUnit && task.outputStaticNonFinalFieldLists.length > 1) {
      // In the main output-unit we output a stub initializer for deferred
      // variables, so that `isolateProperties` stays a fast object.
      task.outputStaticNonFinalFieldLists.forEach(
          (OutputUnit fieldsOutputUnit, Iterable<VariableElement> fields) {
        if (fieldsOutputUnit == outputUnit) return;  // Skip the main unit.
        for (Element element in fields) {
          compiler.withCurrentElement(element, () {
            emitInitialization(element, jsAst.number(0));
          });
        }
      });
    }
  }

  void emitLazilyInitializedStaticFields(CodeOutput output) {
    JavaScriptConstantCompiler handler = backend.constants;
    List<VariableElement> lazyFields =
        handler.getLazilyInitializedFieldsForEmission();
    if (!lazyFields.isEmpty) {
      needsLazyInitializer = true;
      for (VariableElement element in Elements.sortedByPosition(lazyFields)) {
        jsAst.Expression init =
            buildLazilyInitializedStaticField(element, isolateProperties);
        if (init == null) continue;
        output.addBuffer(
            jsAst.prettyPrint(init, compiler, monitor: compiler.dumpInfoTask));
        output.add("$N");
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
            js.string(namer.globalPropertyName(element)),
            js.string(namer.lazyInitializerName(element)),
            code]);
  }

  void emitMetadata(List<String> globalMetadata, CodeOutput output) {
    String metadataAccess =
        generateEmbeddedGlobalAccessString(embeddedNames.METADATA);
    output.add('$metadataAccess$_=$_[');
    for (String metadata in globalMetadata) {
      if (metadata is String) {
        if (metadata != 'null') {
          output.add(metadata);
        }
      } else {
        throw 'Unexpected value in metadata: ${Error.safeToString(metadata)}';
      }
      output.add(',$n');
    }
    output.add('];$n');
  }

  void emitCompileTimeConstants(CodeOutput output,
                                List<Constant> constants,
                                {bool isMainFragment}) {
    assert(isMainFragment != null);

    if (constants.isEmpty) return;
    CodeOutput constantOutput = output;
    if (compiler.hasIncrementalSupport && isMainFragment) {
      constantOutput = cachedEmittedConstantsBuffer;
    }
    for (Constant constant in constants) {
      ConstantValue constantValue = constant.value;
      if (compiler.hasIncrementalSupport && isMainFragment) {
        if (cachedEmittedConstants.contains(constantValue)) continue;
        cachedEmittedConstants.add(constantValue);
      }
      jsAst.Expression init = buildConstantInitializer(constantValue);
      constantOutput.addBuffer(
          jsAst.prettyPrint(init, compiler, monitor: compiler.dumpInfoTask));
      constantOutput.add('$N');
    }
    if (compiler.hasIncrementalSupport && isMainFragment) {
      output.addBuffer(constantOutput);
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

  void emitMakeConstantList(CodeOutput output) {
    output.addBuffer(
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
    output.add(N);
  }

  void emitFunctionThatReturnsNull(CodeOutput output) {
    output.addBuffer(
        jsAst.prettyPrint(
            js.statement('#.# = function() {}',
                         [backend.namer.currentIsolate,
                          backend.rti.getFunctionThatReturnsNullName]),
            compiler, monitor: compiler.dumpInfoTask));
    output.add(N);
  }

  jsAst.Expression generateFunctionThatReturnsNull() {
    return js("#.#", [backend.namer.currentIsolate,
                      backend.rti.getFunctionThatReturnsNullName]);
  }

  emitMain(CodeOutput output, jsAst.Statement invokeMain) {
    if (compiler.isMockCompilation) return;

    if (NativeGenerator.needsIsolateAffinityTagInitialization(backend)) {
      jsAst.Statement nativeBoilerPlate =
          NativeGenerator.generateIsolateAffinityTagInitialization(
              backend,
              generateEmbeddedGlobalAccess,
              js("convertToFastObject", []));
      output.addBuffer(jsAst.prettyPrint(
          nativeBoilerPlate, compiler, monitor: compiler.dumpInfoTask));
    }

    output.add(';');
    addComment('BEGIN invoke [main].', output);
    output.addBuffer(jsAst.prettyPrint(invokeMain,
                     compiler, monitor: compiler.dumpInfoTask));
    output.add(N);
    addComment('END invoke [main].', output);
  }

  void emitInitFunction(CodeOutput output) {
    String isolate = namer.currentIsolate;
    jsAst.Expression allClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.ALL_CLASSES);
    jsAst.Expression getTypeFromNameAccess =
        generateEmbeddedGlobalAccess(embeddedNames.GET_TYPE_FROM_NAME);
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
        #getTypeFromName = function(name) {return #allClasses[name];};
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

            var staticNames = Object.keys(isolateProperties);
            for (var i = 0; i < staticNames.length; i++) {
              var staticName = staticNames[i];
              this[staticName] = isolateProperties[staticName];
            }

            // Reset lazy initializers to null.
            // When forcing the object to fast mode (below) v8 will consider
            // functions as part the object's map. Since we will change them
            // (after the first call to the getter), we would have a map
            // transition.
            var lazies = init.lazies;
            var lazyInitializers = lazies ? Object.keys(lazies) : [];
            for (var i = 0; i < lazyInitializers.length; i++) {
               this[lazies[lazyInitializers[i]]] = null;
            }

            // Use the newly created object as prototype. In Chrome,
            // this creates a hidden class for the object and makes
            // sure it is fast to access.
            function ForceEfficientMap() {}
            ForceEfficientMap.prototype = this;
            new ForceEfficientMap();

            // Now, after being a fast map we can set the lazies again.
            for (var i = 0; i < lazyInitializers.length; i++) {
              var lazyInitName = lazies[lazyInitializers[i]];
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
            'getTypeFromName': getTypeFromNameAccess,
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

    output.addBuffer(
        jsAst.prettyPrint(decl, compiler, monitor: compiler.dumpInfoTask));
    if (compiler.enableMinification) {
      output.add('\n');
    }
  }

  void emitConvertToFastObjectFunction(CodeOutput output) {
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

    output.addBuffer(jsAst.prettyPrint(convertToFastObject, compiler));
    output.add(N);
  }

  void writeLibraryDescriptors(CodeOutput output, LibraryElement library) {
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

    jsAst.Fun metadata = task.metadataCollector.buildMetadataFunction(library);

    jsAst.ObjectInitializer initializers = descriptor.toObjectInitializer();

    compiler.dumpInfoTask.registerElementAst(library, metadata);
    compiler.dumpInfoTask.registerElementAst(library, initializers);
    output
        ..add('["$libraryName",$_')
        ..add('"${uri}",$_');
    if (metadata != null) {
      output.addBuffer(jsAst.prettyPrint(metadata,
                                         compiler,
                                         monitor: compiler.dumpInfoTask));
    }
    output
        ..add(',$_')
        ..add(namer.globalObjectFor(library))
        ..add(',$_')
        ..addBuffer(jsAst.prettyPrint(initializers,
                                      compiler,
                                      monitor: compiler.dumpInfoTask))
        ..add(library == compiler.mainApp ? ',${n}1' : "")
        ..add('],$n');
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

  void emitTypedefs() {
    OutputUnit mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;

    // Emit all required typedef declarations into the main output unit.
    // TODO(karlklose): unify required classes and typedefs to declarations
    // and have builders for each kind.
    for (TypedefElement typedef in typedefsNeededForReflection) {
      LibraryElement library = typedef.library;
      // TODO(karlklose): add a TypedefBuilder and move this code there.
      DartType type = typedef.alias;
      int typeIndex = task.metadataCollector.reifyType(type);
      ClassBuilder builder = new ClassBuilder(typedef, namer);
      builder.addProperty(embeddedNames.TYPEDEF_TYPE_PROPERTY_NAME,
                          js.number(typeIndex));
      builder.addProperty(embeddedNames.TYPEDEF_PREDICATE_PROPERTY_NAME,
                          js.boolean(true));

      // We can be pretty sure that the objectClass is initialized, since
      // typedefs are only emitted with reflection, which requires lots of
      // classes.
      assert(compiler.objectClass != null);
      builder.superName = namer.className(compiler.objectClass);
      jsAst.Node declaration = builder.toObjectInitializer();
      String mangledName = namer.globalPropertyName(typedef);
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

  void emitMangledNames(CodeOutput output) {
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
      output.addBuffer(
          jsAst.prettyPrint(
              js.statement('# = #', [mangledNamesAccess, map]),
              compiler,
              monitor: compiler.dumpInfoTask));
      if (compiler.enableMinification) {
        output.add(';');
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
      output.addBuffer(
          jsAst.prettyPrint(
              js.statement('# = #', [mangledGlobalNamesAccess, map]),
              compiler,
              monitor: compiler.dumpInfoTask));
      if (compiler.enableMinification) {
        output.add(';');
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

  void emitLibrary(Library library) {
    LibraryElement libraryElement = library.element;

    emitStaticFunctions(library.statics);

    ClassBuilder libraryBuilder = getElementDescriptor(libraryElement);
    for (Class cls in library.classes) {
      emitClass(cls, libraryBuilder);
    }

    classEmitter.emitFields(library, libraryBuilder, emitStatics: true);
  }

  void emitMainOutputUnit(Program program,
                          Map<OutputUnit, String> deferredLoadHashes) {
    MainFragment mainFragment = program.fragments.first;
    OutputUnit mainOutputUnit = mainFragment.outputUnit;

    LineColumnCollector lineColumnCollector;
    List<CodeOutputListener> codeOutputListeners;
    if (generateSourceMap) {
      lineColumnCollector = new LineColumnCollector();
      codeOutputListeners = <CodeOutputListener>[lineColumnCollector];
    }

    CodeOutput mainOutput =
        new StreamCodeOutput(compiler.outputProvider('', 'js'),
                             codeOutputListeners);
    outputBuffers[mainOutputUnit] = mainOutput;

    bool isProgramSplit = program.isSplit;

    mainOutput.add(buildGeneratedBy());
    addComment(HOOKS_API_USAGE, mainOutput);

    if (isProgramSplit) {
      /// For deferred loading we communicate the initializers via this global
      /// variable. The deferred hunks will add their initialization to this.
      /// The semicolon is important in minified mode, without it the
      /// following parenthesis looks like a call to the object literal.
      mainOutput.add(
          'self.${deferredInitializers} = self.${deferredInitializers} || '
          'Object.create(null);$n');
    }

    // Using a named function here produces easier to read stack traces in
    // Chrome/V8.
    mainOutput.add('(function(${namer.currentIsolate})$_{\n');
    if (compiler.hasIncrementalSupport) {
      mainOutput.addBuffer(jsAst.prettyPrint(js.statement(
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
      /// We collect all the global state, so it can be passed to the
      /// initializer of deferred files.
      mainOutput.add('var ${globalsHolder}$_=${_}Object.create(null)$N');
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
    mainOutput.addBuffer(jsAst.prettyPrint(mapFunction, compiler));
    for (String globalObject in Namer.reservedGlobalObjectNames) {
      // The global objects start as so-called "slow objects". For V8, this
      // means that it won't try to make map transitions as we add properties
      // to these objects. Later on, we attempt to turn these objects into
      // fast objects by calling "convertToFastObject" (see
      // [emitConvertToFastObjectFunction]).
      mainOutput.add('var ${globalObject}$_=${_}');
      if(isProgramSplit) {
        mainOutput.add('${globalsHolder}.$globalObject$_=${_}');
      }
      mainOutput.add('map()$N');
    }

    mainOutput.add('function ${namer.isolateName}()$_{}\n');
    if (isProgramSplit) {
      mainOutput.add(
          '${globalsHolder}.${namer.isolateName}$_=$_${namer.isolateName}$N'
          '${globalsHolder}.$initName$_=${_}$initName$N'
          '${globalsHolder}.$parseReflectionDataName$_=$_'
            '$parseReflectionDataName$N');
    }
    mainOutput.add('init()$N$n');
    mainOutput.add('$isolateProperties$_=$_$isolatePropertiesName$N');

    emitFunctionThatReturnsNull(mainOutput);
    mainFragment.libraries.forEach(emitLibrary);

    Iterable<LibraryElement> libraries =
        task.outputLibraryLists[mainOutputUnit];
    if (libraries == null) libraries = [];
    emitTypedefs();
    emitMangledNames(mainOutput);

    checkEverythingEmitted(elementDescriptors.keys);

    CodeBuffer libraryBuffer = new CodeBuffer();
    for (LibraryElement library in Elements.sortedByPosition(libraries)) {
      writeLibraryDescriptors(libraryBuffer, library);
      elementDescriptors.remove(library);
    }

    bool needsNativeSupport = program.needsNativeSupport;
    mainOutput
        ..addBuffer(
            jsAst.prettyPrint(
                getReflectionDataParser(this, backend, needsNativeSupport),
                compiler))
        ..add(n);

    // The argument to reflectionDataParser is assigned to a temporary 'dart'
    // so that 'dart.' will appear as the prefix to dart methods in stack
    // traces and profile entries.
    mainOutput..add('var dart = [$n')
              ..addBuffer(libraryBuffer)
              ..add(']$N');
    if (compiler.useContentSecurityPolicy) {
      jsAst.Statement precompiledFunctionAst =
          buildCspPrecompiledFunctionFor(mainOutputUnit);
      mainOutput.addBuffer(
          jsAst.prettyPrint(
              precompiledFunctionAst,
              compiler,
              monitor: compiler.dumpInfoTask,
              allowVariableMinification: false));
      mainOutput.add(N);
    }

    mainOutput.add('$parseReflectionDataName(dart)$N');

    interceptorEmitter.emitGetInterceptorMethods(mainOutput);
    interceptorEmitter.emitOneShotInterceptors(mainOutput);

    if (task.outputContainsConstantList) {
      emitMakeConstantList(mainOutput);
    }

    // Constants in checked mode call into RTI code to set type information
    // which may need getInterceptor (and one-shot interceptor) methods, so
    // we have to make sure that [emitGetInterceptorMethods] and
    // [emitOneShotInterceptors] have been called.
    emitCompileTimeConstants(
        mainOutput, mainFragment.constants, isMainFragment: true);

    emitDeferredBoilerPlate(mainOutput, deferredLoadHashes);

    if (compiler.deferredMapUri != null) {
      outputDeferredMap();
    }

    // Static field initializations require the classes and compile-time
    // constants to be set up.
    emitStaticNonFinalFieldInitializations(mainOutput, mainOutputUnit);
    interceptorEmitter.emitTypeToInterceptorMap(program, mainOutput);
    emitLazilyInitializedStaticFields(mainOutput);

    mainOutput.add('\n');

    emitMetadata(task.metadataCollector.globalMetadata, mainOutput);

    isolateProperties = isolatePropertiesName;
    // The following code should not use the short-hand for the
    // initialStatics.
    mainOutput.add('${namer.currentIsolate}$_=${_}null$N');

    emitFinishIsolateConstructorInvocation(mainOutput);
    mainOutput.add(
        '${namer.currentIsolate}$_=${_}new ${namer.isolateName}()$N');

    emitConvertToFastObjectFunction(mainOutput);
    for (String globalObject in Namer.reservedGlobalObjectNames) {
      mainOutput.add('$globalObject = convertToFastObject($globalObject)$N');
    }
    if (DEBUG_FAST_OBJECTS) {
      mainOutput.add(r'''
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
      mainOutput.add('''
        if (typeof print === "function") {
           print("Size of $object: "
                 + String(Object.getOwnPropertyNames($object).length)
                 + ", fast properties " + HasFastProperties($object));
}
''');
      }
    }

    emitInitFunction(mainOutput);
    emitMain(mainOutput, mainFragment.invokeMain);

    mainOutput.add('})()\n');


    if (generateSourceMap) {
      mainOutput.add(
          generateSourceMapTag(compiler.sourceMapUri, compiler.outputUri));
    }

    mainOutput.close();

    if (generateSourceMap) {
      outputSourceMap(mainOutput, lineColumnCollector, '',
          compiler.sourceMapUri, compiler.outputUri);
    }
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
  Map<OutputUnit, String> emitDeferredOutputUnits(Program program) {
    if (!program.isSplit) return const {};

    Map<OutputUnit, CodeBuffer> outputBuffers =
        new Map<OutputUnit, CodeBuffer>();

    for (Fragment fragment in program.deferredFragments) {
      OutputUnit outputUnit = fragment.outputUnit;


      fragment.libraries.forEach(emitLibrary);

      if (elementDescriptors.isNotEmpty) {
        Iterable<LibraryElement> libraries =
            task.outputLibraryLists[outputUnit];
        if (libraries == null) libraries = [];

        // TODO(johnniwinther): Avoid creating [CodeBuffer]s.
        CodeBuffer buffer = new CodeBuffer();
        outputBuffers[outputUnit] = buffer;
        for (LibraryElement library in Elements.sortedByPosition(libraries)) {
          writeLibraryDescriptors(buffer, library);
          elementDescriptors.remove(library);
        }
      }
    }

    return emitDeferredCode(program, outputBuffers);
  }

  int emitProgram(ProgramBuilder programBuilder) {
    Program program = programBuilder.buildProgram(
        storeFunctionTypesInMetadata: true);

    // Shorten the code by using [namer.currentIsolate] as temporary.
    isolateProperties = namer.currentIsolate;

    // Emit deferred units first, so we have their hashes.
    // Map from OutputUnit to a hash of its content. The hash uniquely
    // identifies the code of the output-unit. It does not include
    // boilerplate JS code, like the sourcemap directives or the hash
    // itself.
    Map<OutputUnit, String> deferredLoadHashes =
        emitDeferredOutputUnits(program);
    emitMainOutputUnit(program, deferredLoadHashes);

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

  /// Emits support-code for deferred loading into [output].
  void emitDeferredBoilerPlate(CodeOutput output,
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
    output.addBuffer(jsAst.prettyPrint(functions,
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
        uris.add(backend.deferredPartFileName(outputUnit.name));
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
      output.addBuffer(jsAst.prettyPrint(
          js("# = #", [globalName, initializer]),
          compiler, monitor: compiler.dumpInfoTask));
      output.add('$N');
    }

    emitMapping(embeddedNames.DEFERRED_LIBRARY_URIS, deferredLibraryUris);
    emitMapping(embeddedNames.DEFERRED_LIBRARY_HASHES,
                deferredLibraryHashes);
  }

  /// Emits code for all output units except the main.
  /// Returns a mapping from outputUnit to a hash of the corresponding hunk that
  /// can be used for calling the initializer.
  Map<OutputUnit, String> emitDeferredCode(
      Program program,
      Map<OutputUnit, CodeBuffer> deferredBuffers) {

    Map<OutputUnit, String> hunkHashes = new Map<OutputUnit, String>();

    for (Fragment fragment in program.deferredFragments) {
      OutputUnit outputUnit = fragment.outputUnit;

      CodeOutput libraryDescriptorBuffer = deferredBuffers[outputUnit];

      List<CodeOutputListener> outputListeners = <CodeOutputListener>[];
      Hasher hasher = new Hasher();
      outputListeners.add(hasher);

      LineColumnCollector lineColumnCollector;
      if (generateSourceMap) {
        lineColumnCollector = new LineColumnCollector();
        outputListeners.add(lineColumnCollector);
      }

      String partPrefix =
          backend.deferredPartFileName(outputUnit.name, addExtension: false);
      CodeOutput output = new StreamCodeOutput(
          compiler.outputProvider(partPrefix, 'part.js'),
          outputListeners);

      outputBuffers[outputUnit] = output;

      output
          ..add(buildGeneratedBy())
          ..add('${deferredInitializers}.current$_=$_'
                   'function$_(${globalsHolder}) {$N');
      for (String globalObject in Namer.reservedGlobalObjectNames) {
        output
            .add('var $globalObject$_=$_'
                     '${globalsHolder}.$globalObject$N');
      }
      output
          ..add('var init$_=$_${globalsHolder}.init$N')
          ..add('var $parseReflectionDataName$_=$_'
                    '$globalsHolder.$parseReflectionDataName$N')
          ..add('var ${namer.isolateName}$_=$_'
                    '${globalsHolder}.${namer.isolateName}$N');
      if (libraryDescriptorBuffer != null) {
        // TODO(ahe): This defines a lot of properties on the
        // Isolate.prototype object.  We know this will turn it into a
        // slow object in V8, so instead we should do something similar
        // to Isolate.$finishIsolateConstructor.
        output
            ..add('var ${namer.currentIsolate}$_=$_$isolatePropertiesName$N')
            // The argument to reflectionDataParser is assigned to a temporary
            // 'dart' so that 'dart.' will appear as the prefix to dart methods
            // in stack traces and profile entries.
            ..add('var dart = [$n ')
            ..addBuffer(libraryDescriptorBuffer)
            ..add(']$N');

        if (compiler.useContentSecurityPolicy) {
          jsAst.Statement precompiledFunctionAst =
              buildCspPrecompiledFunctionFor(outputUnit);

          output.addBuffer(
              jsAst.prettyPrint(
                  precompiledFunctionAst, compiler,
                  monitor: compiler.dumpInfoTask,
                  allowVariableMinification: false));
          output.add(N);
        }
        output.add('$parseReflectionDataName(dart)$N');
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
      output.add("${namer.currentIsolate}$_=${_}arguments[1]$N");

      emitCompileTimeConstants(
          output, fragment.constants, isMainFragment: false);
      emitStaticNonFinalFieldInitializations(output, outputUnit);

      output.add('}$N');
      // Make a unique hash of the code (before the sourcemaps are added)
      // This will be used to retrieve the initializing function from the global
      // variable.
      String hash = hasher.getHash();

      output.add('${deferredInitializers}["$hash"]$_=$_'
                       '${deferredInitializers}.current$N');

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

        output.add(generateSourceMapTag(mapUri, partUri));
        output.close();
        outputSourceMap(output, lineColumnCollector, partName,
                        mapUri, partUri);
      } else {
        output.close();
      }

      hunkHashes[outputUnit] = hash;
    }
    return hunkHashes;
  }

  String buildGeneratedBy() {
    var suffix = '';
    if (compiler.hasBuildId) suffix = ' version: ${compiler.buildId}';
    return '// Generated by dart2js, the Dart to JavaScript compiler$suffix.\n';
  }

  void outputSourceMap(CodeOutput output,
                       LineColumnProvider lineColumnProvider,
                       String name,
                       [Uri sourceMapUri,
                        Uri fileUri]) {
    if (!generateSourceMap) return;
    // Create a source file for the compilation output. This allows using
    // [:getLine:] to transform offsets to line numbers in [SourceMapBuilder].
    SourceMapBuilder sourceMapBuilder =
            new SourceMapBuilder(sourceMapUri, fileUri, lineColumnProvider);
    output.forEachSourceLocation(sourceMapBuilder.addMapping);
    String sourceMap = sourceMapBuilder.build();
    compiler.outputProvider(name, 'js.map')
        ..add(sourceMap)
        ..close();
  }

  void outputDeferredMap() {
    Map<String, dynamic> mapping = new Map<String, dynamic>();
    // Json does not support comments, so we embed the explanation in the
    // data.
    mapping["_comment"] = "This mapping shows which compiled `.js` files are "
        "needed for a given deferred library import.";
    mapping.addAll(compiler.deferredLoadTask.computeDeferredMap());
    compiler.outputProvider(compiler.deferredMapUri.path, 'deferred_map')
        ..add(const JsonEncoder.withIndent("  ").convert(mapping))
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
