// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

/**
 * Generates the code for all used classes in the program. Static fields (even
 * in classes) are ignored, since they can be treated as non-class elements.
 *
 * The code for the containing (used) methods must exist in the [:universe:].
 */
class CodeEmitterTask extends CompilerTask {
  final ContainerBuilder containerBuilder = new ContainerBuilder();
  final ClassEmitter classEmitter = new ClassEmitter();
  final NsmEmitter nsmEmitter = new NsmEmitter();
  final TypeTestEmitter typeTestEmitter = new TypeTestEmitter();
  final InterceptorEmitter interceptorEmitter = new InterceptorEmitter();
  final MetadataEmitter metadataEmitter = new MetadataEmitter();

  final Set<Constant> cachedEmittedConstants;
  final CodeBuffer cachedEmittedConstantsBuffer = new CodeBuffer();
  final Map<Element, ClassBuilder> cachedClassBuilders;
  final Set<Element> cachedElements;

  bool needsDefineClass = false;
  bool needsMixinSupport = false;
  bool needsLazyInitializer = false;
  final Namer namer;
  ConstantEmitter constantEmitter;
  NativeEmitter nativeEmitter;
  Map<OutputUnit, CodeBuffer> outputBuffers = new Map<OutputUnit, CodeBuffer>();
  final CodeBuffer deferredConstants = new CodeBuffer();
  /** Shorter access to [isolatePropertiesName]. Both here in the code, as
      well as in the generated code. */
  String isolateProperties;
  String classesCollector;
  final Set<ClassElement> neededClasses = new Set<ClassElement>();
  final Map<OutputUnit, List<ClassElement>> outputClassLists =
      new Map<OutputUnit, List<ClassElement>>();
  final Map<OutputUnit, List<Constant>> outputConstantLists =
      new Map<OutputUnit, List<Constant>>();
  final List<ClassElement> nativeClasses = <ClassElement>[];
  final Map<String, String> mangledFieldNames = <String, String>{};
  final Map<String, String> mangledGlobalFieldNames = <String, String>{};
  final Set<String> recordedMangledNames = new Set<String>();

  final Map<ClassElement, Map<String, jsAst.Expression>> additionalProperties =
      new Map<ClassElement, Map<String, jsAst.Expression>>();

  /// Records if a type variable is read dynamically for type tests.
  final Set<TypeVariableElement> readTypeVariables =
      new Set<TypeVariableElement>();

  // TODO(ngeoffray): remove this field.
  Set<ClassElement> instantiatedClasses;

  JavaScriptBackend get backend => compiler.backend;
  TypeVariableHandler get typeVariableHandler => backend.typeVariableHandler;

  String get _ => space;
  String get space => compiler.enableMinification ? "" : " ";
  String get n => compiler.enableMinification ? "" : "\n";
  String get N => compiler.enableMinification ? "\n" : ";\n";

  CodeBuffer get mainBuffer {
    return outputBuffers.putIfAbsent(compiler.deferredLoadTask.mainOutputUnit,
        () => new CodeBuffer());
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
  List<jsAst.Node> precompiledFunction = <jsAst.Node>[];

  List<jsAst.Expression> precompiledConstructorNames = <jsAst.Expression>[];

  // True if Isolate.makeConstantList is needed.
  bool hasMakeConstantList = false;

  /**
   * Accumulate properties for classes and libraries, describing their
   * static/top-level members.
   * Later, these members are emitted when the class or library is emitted.
   *
   * For supporting deferred loading we keep one list per output unit.
   *
   * See [getElementDecriptor].
   */
  // TODO(ahe): Generate statics with their class, and store only libraries in
  // this map.
  final Map<Element, Map<OutputUnit, ClassBuilder>> elementDescriptors
      = new Map<Element, Map<OutputUnit, ClassBuilder>>();

  final bool generateSourceMap;

  CodeEmitterTask(Compiler compiler, Namer namer, this.generateSourceMap)
      : this.namer = namer,
        constantEmitter = new ConstantEmitter(compiler, namer),
        cachedEmittedConstants = compiler.cacheStrategy.newSet(),
        cachedClassBuilders = compiler.cacheStrategy.newMap(),
        cachedElements = compiler.cacheStrategy.newSet(),
        super(compiler) {
    nativeEmitter = new NativeEmitter(this);
    containerBuilder.task = this;
    classEmitter.task = this;
    nsmEmitter.task = this;
    typeTestEmitter.task = this;
    interceptorEmitter.task = this;
    metadataEmitter.task = this;
    // TODO(18886): Remove this call (and the show in the import) once the
    // memory-leak in the VM is fixed.
    templateManager.clear();
  }

  void addComment(String comment, CodeBuffer buffer) {
    buffer.write(jsAst.prettyPrint(js.comment(comment), compiler));
  }

  jsAst.Expression constantReference(Constant value) {
    return constantEmitter.reference(value);
  }

  jsAst.Expression constantInitializerExpression(Constant value) {
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

    var defineClass = js('''function(name, cls, fields) {
      var accessors = [];

      var str = "function " + cls + "(";
      var body = "";

      for (var i = 0; i < fields.length; i++) {
        if(i != 0) str += ", ";

        var field = generateAccessor(fields[i], accessors, cls);
        var parameter = "parameter_" + field;
        str += parameter;
        body += ("this." + field + " = " + parameter + ";\\n");
      }
      str += ") {\\n" + body + "}\\n";
      str += cls + ".builtin\$cls=\\"" + name + "\\";\\n";
      str += "\$desc=\$collectedClasses." + cls + ";\\n";
      str += "if(\$desc instanceof Array) \$desc = \$desc[1];\\n";
      str += cls + ".prototype = \$desc;\\n";
      if (typeof defineClass.name != "string") {
        str += cls + ".name=\\"" + cls + "\\";\\n";
      }
      str += accessors.join("");

      return str;
    }''');
    // Declare a function called "generateAccessor".  This is used in
    // defineClassFunction (it's a local declaration in init()).
    return [
        generateAccessorFunction,
        js('$generateAccessorHolder = generateAccessor'),
        new jsAst.FunctionDeclaration(
            new jsAst.VariableDeclaration('defineClass'), defineClass) ];
  }

  /** Needs defineClass to be defined. */
  List buildInheritFrom() {
    return [js(r'''
        var inheritFrom = function() {
          function tmp() {}
          var hasOwnProperty = Object.prototype.hasOwnProperty;
          return function (constructor, superConstructor) {
            tmp.prototype = superConstructor.prototype;
            var object = new tmp();
            var properties = constructor.prototype;
            for (var member in properties)
              if (hasOwnProperty.call(properties, member))
                object[member] = properties[member];
            object.constructor = constructor;
            constructor.prototype = object;
            return object;
          };
        }()
      ''')];
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

    return js('''
      function(collectedClasses, isolateProperties, existingIsolateProperties) {
        var pendingClasses = {};
        if (!init.allClasses) init.allClasses = {};
        var allClasses = init.allClasses;

        if (#)  // DEBUG_FAST_OBJECTS
          print("Number of classes: " +
              Object.getOwnPropertyNames(\$\$).length);

        var hasOwnProperty = Object.prototype.hasOwnProperty;

        if (typeof dart_precompiled == "function") {
          var constructors = dart_precompiled(collectedClasses);
        } else {
          var combinedConstructorFunction =
             "function \$reflectable(fn){fn.$reflectableField=1;return fn};\\n"+
             "var \$desc;\\n";
          var constructorsList = [];
        }

        for (var cls in collectedClasses) {
          if (hasOwnProperty.call(collectedClasses, cls)) {
            var desc = collectedClasses[cls];
            if (desc instanceof Array) desc = desc[1];

            /* The 'fields' are either a constructor function or a
             * string encoding fields, constructor and superclass.  Get
             * the superclass and the fields in the format
             *   '[name/]Super;field1,field2'
             * from the CLASS_DESCRIPTOR_PROPERTY property on the descriptor.
             * The 'name/' is optional and contains the name that should be used
             * when printing the runtime type string.  It is used, for example,
             * to print the runtime type JSInt as 'int'.
             */
            var classData = desc["${namer.classDescriptorProperty}"],
                supr, name = cls, fields = classData;
            if (#)  // backend.hasRetainedMetadata
              if (typeof classData == "object" &&
                  classData instanceof Array) {
                classData = fields = classData[0];
              }
            if (typeof classData == "string") {
              var split = classData.split("/");
              if (split.length == 2) {
                name = split[0];
                fields = split[1];
              }
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
                    return function(){ return init.metadata[s]; };
                  })(functionSignature);
            }

            if (#)  // needsMixinSupport
              if (supr && supr.indexOf("+") > 0) {
                s = supr.split("+");
                supr = s[0];
                var mixin = collectedClasses[s[1]];
                if (mixin instanceof Array) mixin = mixin[1];
                for(var d in mixin) {
                  if (hasOwnProperty.call(mixin, d) &&
                      !hasOwnProperty.call(desc, d))
                    desc[d] = mixin[d];
                }
              }

            if (typeof dart_precompiled != "function") {
              combinedConstructorFunction += defineClass(name, cls, fields);
              constructorsList.push(cls);
            }
            if (supr) pendingClasses[cls] = supr;
          }
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
          if (#) //backend.isTreeShakingDisabled,
            constructor["${namer.metadataField}"] = desc;
          allClasses[cls] = constructor;
          globalObject[cls] = constructor;
        }

        constructors = null;

        var finishedClasses = {};
        init.interceptorsByTag = Object.create(null);
        init.leafTags = {};

        #;  // buildFinishClass(),

        #;  // buildTrivialNsmHandlers()

        for (var cls in pendingClasses) finishClass(cls);
      }''', [
          DEBUG_FAST_OBJECTS,
          backend.hasRetainedMetadata,
          needsMixinSupport,
          backend.isTreeShakingDisabled,
          buildFinishClass(),
          nsmEmitter.buildTrivialNsmHandlers()]);
  }

  jsAst.Node optional(bool condition, jsAst.Node node) {
    return condition ? node : new jsAst.EmptyStatement();
  }

  jsAst.FunctionDeclaration buildFinishClass() {
    String specProperty = '"${namer.nativeSpecProperty}"';  // "%"

    return js.statement('''
      function finishClass(cls) {

        // TODO(8540): Remove this work around.
        // Opera does not support 'getOwnPropertyNames'. Therefore we use
        //   hasOwnProperty instead.
        var hasOwnProperty = Object.prototype.hasOwnProperty;

        if (hasOwnProperty.call(finishedClasses, cls)) return;

        finishedClasses[cls] = true;

        var superclass = pendingClasses[cls];

        // The superclass is only false (empty string) for the Dart Object
        // class.  The minifier together with noSuchMethod can put methods on
        // the Object.prototype object, and they show through here, so we check
        // that we have a string.
        if (!superclass || typeof superclass != "string") return;
        finishClass(superclass);
        var constructor = allClasses[cls];
        var superConstructor = allClasses[superclass];

        if (!superConstructor)
          superConstructor = existingIsolateProperties[superclass];

        var prototype = inheritFrom(constructor, superConstructor);

        if (#) {  // !nativeClasses.isEmpty,
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
          if (hasOwnProperty.call(prototype, $specProperty)) {
            var nativeSpec = prototype[$specProperty].split(";");
            if (nativeSpec[0]) {
              var tags = nativeSpec[0].split("|");
              for (var i = 0; i < tags.length; i++) {
                init.interceptorsByTag[tags[i]] = constructor;
                init.leafTags[tags[i]] = true;
              }
            }
            if (nativeSpec[1]) {
              tags = nativeSpec[1].split("|");
              if (#) {  // User subclassing of native classes?
                if (nativeSpec[2]) {
                  var subclasses = nativeSpec[2].split("|");
                  for (var i = 0; i < subclasses.length; i++) {
                    var subclass = allClasses[subclasses[i]];
                    subclass.\$nativeSuperclassTag = tags[0];
                  }
                }
                for (i = 0; i < tags.length; i++) {
                  init.interceptorsByTag[tags[i]] = constructor;
                  init.leafTags[tags[i]] = false;
                }
              }
            }
          }
        }
      }''', [!nativeClasses.isEmpty, true]);
  }

  jsAst.Fun get finishIsolateConstructorFunction {
    // We replace the old Isolate function with a new one that initializes
    // all its fields with the initial (and often final) value of all globals.
    //
    // We also copy over old values like the prototype, and the
    // isolateProperties themselves.
    return js('''
      function (oldIsolate) {
        var isolateProperties = oldIsolate.#;
        function Isolate() {
          var hasOwnProperty = Object.prototype.hasOwnProperty;
          for (var staticName in isolateProperties)
            if (hasOwnProperty.call(isolateProperties, staticName))
              this[staticName] = isolateProperties[staticName];
          // Use the newly created object as prototype. In Chrome,
          // this creates a hidden class for the object and makes
          // sure it is fast to access.
          function ForceEfficientMap() {}
          ForceEfficientMap.prototype = this;
          new ForceEfficientMap();
        }
        Isolate.prototype = oldIsolate.prototype;
        Isolate.prototype.constructor = Isolate;
        Isolate.# = isolateProperties;
        if (#)
          Isolate.# = oldIsolate.#;
        if (#)
          Isolate.# = oldIsolate.#;
        return Isolate;
      }''',
        [namer.isolatePropertiesName, namer.isolatePropertiesName,
         needsDefineClass, finishClassesProperty, finishClassesProperty,
         hasMakeConstantList, makeConstListProperty, makeConstListProperty ]);
  }

  jsAst.Fun get lazyInitializerFunction {
    String isolate = namer.currentIsolate;
    jsAst.Expression cyclicThrow =
        namer.elementAccess(backend.getCyclicThrowHelper());

    return js('''
      function (prototype, staticName, fieldName, getterName, lazyValue) {
        if (#) {
          if (!init.lazies) init.lazies = {};
          init.lazies[fieldName] = getterName;
        }

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
                  if ($isolate[fieldName] === sentinelInProgress)
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
    ''', [backend.rememberLazies, cyclicThrow]);
  }

  List buildDefineClassAndFinishClassFunctionsIfNecessary() {
    if (!needsDefineClass) return [];
    return defineClassFunction
    ..addAll(buildInheritFrom())
    ..addAll([
      js('$finishClassesName = #', finishClassesFunction)
    ]);
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
    String name = elementOrSelector.name;
    if (elementOrSelector.isGetter) return name;
    if (elementOrSelector.isSetter) {
      if (!mangledName.startsWith(namer.setterPrefix)) return '$name=';
      String base = mangledName.substring(namer.setterPrefix.length);
      String getter = '${namer.getterPrefix}$base';
      mangledFieldNames[getter] = name;
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
    }
    throw compiler.internalError(element,
        'Do not know how to reflect on this $element.');
  }

  String namedParametersAsReflectionNames(Selector selector) {
    if (selector.getOrderedNamedArguments().isEmpty) return '';
    String names = selector.getOrderedNamedArguments().join(':');
    return ':$names';
  }

  jsAst.FunctionDeclaration buildPrecompiledFunction() {
    // TODO(ahe): Compute a hash code.
    return js.statement('''
      function dart_precompiled(\$collectedClasses) {
        var \$desc;
        #;
        return #;
      }''', [
          precompiledFunction,
          new jsAst.ArrayInitializer.from(precompiledConstructorNames)]);
  }

  void generateClass(ClassElement classElement, ClassBuilder properties) {
    compiler.withCurrentElement(classElement, () {
      if (compiler.hasIncrementalSupport) {
        ClassBuilder builder =
            cachedClassBuilders.putIfAbsent(classElement, () {
              ClassBuilder builder = new ClassBuilder(namer);
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

  /**
   * Return a function that returns true if its argument is a class
   * that needs to be emitted.
   */
  Function computeClassFilter() {
    if (backend.isTreeShakingDisabled) return (ClassElement cls) => true;

    Set<ClassElement> unneededClasses = new Set<ClassElement>();
    // The [Bool] class is not marked as abstract, but has a factory
    // constructor that always throws. We never need to emit it.
    unneededClasses.add(compiler.boolClass);

    // Go over specialized interceptors and then constants to know which
    // interceptors are needed.
    Set<ClassElement> needed = new Set<ClassElement>();
    backend.specializedGetInterceptors.forEach(
        (_, Iterable<ClassElement> elements) {
          needed.addAll(elements);
        }
    );

    // Add interceptors referenced by constants.
    needed.addAll(interceptorEmitter.interceptorsReferencedFromConstants());

    // Add unneeded interceptors to the [unneededClasses] set.
    for (ClassElement interceptor in backend.interceptedClasses) {
      if (!needed.contains(interceptor)
          && interceptor != compiler.objectClass) {
        unneededClasses.add(interceptor);
      }
    }

    // These classes are just helpers for the backend's type system.
    unneededClasses.add(backend.jsMutableArrayClass);
    unneededClasses.add(backend.jsFixedArrayClass);
    unneededClasses.add(backend.jsExtendableArrayClass);
    unneededClasses.add(backend.jsUInt32Class);
    unneededClasses.add(backend.jsUInt31Class);
    unneededClasses.add(backend.jsPositiveIntClass);

    return (ClassElement cls) => !unneededClasses.contains(cls);
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

  void emitStaticFunctions() {
    bool isStaticFunction(Element element) =>
        !element.isInstanceMember && !element.isField;

    Iterable<Element> elements =
        backend.generatedCode.keys.where(isStaticFunction);

    for (Element element in Elements.sortedByPosition(elements)) {
      ClassBuilder builder = new ClassBuilder(namer);
      containerBuilder.addMember(element, builder);
      getElementDecriptor(element).properties.addAll(builder.properties);
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
        Constant initialValue = handler.getInitialValueFor(element);
        jsAst.Expression init =
          js('$isolateProperties.# = #',
              [namer.getNameOfGlobalField(element),
               constantEmitter.referenceInInitializationContext(initialValue)]);
        buffer.write(jsAst.prettyPrint(init, compiler));
        buffer.write('$N');
        compiler.dumpInfoTask.registerGeneratedCode(element, init);
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
        jsAst.Expression getter = buildLazyInitializedGetter(element);
        jsAst.Expression init = js('#(#,#,#,#,#,#)',
            [js(lazyInitializerName),
                js(isolateProperties),
                js.string(element.name),
                js.string(namer.getNameX(element)),
                js.string(namer.getLazyInitializerName(element)),
                code,
                getter == null ? [] : [getter]]);
        buffer.write(jsAst.prettyPrint(init, compiler));
        buffer.write("$N");
      }
    }
  }

  jsAst.Expression buildLazyInitializedGetter(VariableElement element) {
    // Nothing to do, the 'lazy' function will create the getter.
    return null;
  }

  void emitCompileTimeConstants(CodeBuffer buffer, OutputUnit outputUnit) {
    List<Constant> constants = outputConstantLists[outputUnit];
    if (constants == null) return;
    bool isMainBuffer = buffer == mainBuffer;
    if (compiler.hasIncrementalSupport && isMainBuffer) {
      buffer = cachedEmittedConstantsBuffer;
    }
    for (Constant constant in constants) {
      if (compiler.hasIncrementalSupport && isMainBuffer) {
        if (cachedEmittedConstants.contains(constant)) continue;
        cachedEmittedConstants.add(constant);
      }
      String name = namer.constantName(constant);
      if (constant.isList) emitMakeConstantListIfNotEmitted(buffer);
      jsAst.Expression init = js('#.# = #',
          [namer.globalObjectForConstant(constant), name,
           constantInitializerExpression(constant)]);
      buffer.write(jsAst.prettyPrint(init, compiler));
      buffer.write('$N');
    }
    if (compiler.hasIncrementalSupport && isMainBuffer) {
      mainBuffer.add(cachedEmittedConstantsBuffer);
    }
  }

  bool isConstantInlinedOrAlreadyEmitted(Constant constant) {
    if (constant.isFunction) return true;    // Already emitted.
    if (constant.isPrimitive) return true;   // Inlined.
    if (constant.isDummy) return true;       // Inlined.
    // The name is null when the constant is already a JS constant.
    // TODO(floitsch): every constant should be registered, so that we can
    // share the ones that take up too much space (like some strings).
    if (namer.constantName(constant) == null) return true;
    return false;
  }

  int compareConstants(Constant a, Constant b) {
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

  void emitMakeConstantListIfNotEmitted(CodeBuffer buffer) {
    if (hasMakeConstantList) return;
    hasMakeConstantList = true;
    buffer.write(
        jsAst.prettyPrint(
            js.statement(r'''#.# = function(list) {
                                     list.immutable$list = #;
                                     list.fixed$length = #;
                                     return list;
                                   }''',
                         [namer.isolateName, makeConstListProperty, initName,
                          initName]),
            compiler));
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
   * Emits code that sets `init.isolateTag` to a unique string.
   */
  jsAst.Expression generateIsolateAffinityTagInitialization() {
    return js('''
      !function() {
        // On V8, the 'intern' function converts a string to a symbol, which
        // makes property access much faster.
        function intern(s) {
          var o = {};
          o[s] = 1;
          return Object.keys(convertToFastObject(o))[0];
        }

        init.getIsolateTag = function(name) {
          return intern("___dart_" + name + init.isolateTag);
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
            init.isolateTag = property;
            break;
          }
        }
      }()
    ''');
  }

  jsAst.Expression generateDispatchPropertyNameInitialization() {
    return js(
        'init.dispatchPropertyName = init.getIsolateTag("dispatch_record")');
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
    } else {
      mainCallClosure = namer.elementAccess(main);
    }

    if (backend.needToInitializeIsolateAffinityTag) {
      buffer.write(
          jsAst.prettyPrint(generateIsolateAffinityTagInitialization(),
                            compiler));
      buffer.write(N);
    }
    if (backend.needToInitializeDispatchProperty) {
      assert(backend.needToInitializeIsolateAffinityTag);
      buffer.write(
          jsAst.prettyPrint(generateDispatchPropertyNameInitialization(),
              compiler));
      buffer.write(N);
    }

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
  init.currentScript = currentScript;

  if (typeof dartMainRunner === "function") {
    dartMainRunner(#, []);
  } else {
    #([]);
  }
})$N''', [mainCallClosure, mainCallClosure]);

    buffer.write(';');
    buffer.write(jsAst.prettyPrint(invokeMain, compiler));
    buffer.write(N);
    addComment('END invoke [main].', buffer);
  }

  /**
   * Compute all the constants that must be emitted.
   */
  void computeNeededConstants() {
    JavaScriptConstantCompiler handler = backend.constants;
    List<Constant> constants = handler.getConstantsForEmission(
        compiler.hasIncrementalSupport ? null : compareConstants);
    for (Constant constant in constants) {
      if (isConstantInlinedOrAlreadyEmitted(constant)) continue;
      OutputUnit constantUnit =
          compiler.deferredLoadTask.outputUnitForConstant(constant);
      if (constantUnit == null) {
        // The back-end introduces some constants, like "InterceptorConstant" or
        // some list constants. They are emitted in the main output-unit.
        // TODO(sigurdm): We should track those constants.
        constantUnit = compiler.deferredLoadTask.mainOutputUnit;
      }
      outputConstantLists.putIfAbsent(constantUnit, () => new List<Constant>())
          .add(constant);
    }
  }

  /**
   * Compute all the classes that must be emitted.
   */
  void computeNeededClasses() {
    instantiatedClasses =
        compiler.codegenWorld.instantiatedClasses.where(computeClassFilter())
            .toSet();

    void addClassWithSuperclasses(ClassElement cls) {
      neededClasses.add(cls);
      for (ClassElement superclass = cls.superclass;
          superclass != null;
          superclass = superclass.superclass) {
        neededClasses.add(superclass);
      }
    }

    void addClassesWithSuperclasses(Iterable<ClassElement> classes) {
      for (ClassElement cls in classes) {
        addClassWithSuperclasses(cls);
      }
    }

    // 1. We need to generate all classes that are instantiated.
    addClassesWithSuperclasses(instantiatedClasses);

    // 2. Add all classes used as mixins.
    Set<ClassElement> mixinClasses = neededClasses
        .where((ClassElement element) => element.isMixinApplication)
        .map(computeMixinClass)
        .toSet();
    neededClasses.addAll(mixinClasses);

    // 3. If we need noSuchMethod support, we run through all needed
    // classes to figure out if we need the support on any native
    // class. If so, we let the native emitter deal with it.
    if (compiler.enabledNoSuchMethod) {
      String noSuchMethodName = Compiler.NO_SUCH_METHOD;
      Selector noSuchMethodSelector = compiler.noSuchMethodSelector;
      for (ClassElement element in neededClasses) {
        if (!element.isNative) continue;
        Element member = element.lookupLocalMember(noSuchMethodName);
        if (member == null) continue;
        if (noSuchMethodSelector.applies(member, compiler)) {
          nativeEmitter.handleNoSuchMethod = true;
          break;
        }
      }
    }

    // 4. Find all classes needed for rti.
    // It is important that this is the penultimate step, at this point,
    // neededClasses must only contain classes that have been resolved and
    // codegen'd. The rtiNeededClasses may contain additional classes, but
    // these are thought to not have been instantiated, so we neeed to be able
    // to identify them later and make sure we only emit "empty shells" without
    // fields, etc.
    typeTestEmitter.computeRtiNeededClasses();
    typeTestEmitter.rtiNeededClasses.removeAll(neededClasses);
    // rtiNeededClasses now contains only the "empty shells".
    neededClasses.addAll(typeTestEmitter.rtiNeededClasses);

    // TODO(18175, floitsch): remove once issue 18175 is fixed.
    if (neededClasses.contains(backend.jsIntClass)) {
      neededClasses.add(compiler.intClass);
    }
    if (neededClasses.contains(backend.jsDoubleClass)) {
      neededClasses.add(compiler.doubleClass);
    }
    if (neededClasses.contains(backend.jsNumberClass)) {
      neededClasses.add(compiler.numClass);
    }
    if (neededClasses.contains(backend.jsStringClass)) {
      neededClasses.add(compiler.stringClass);
    }
    if (neededClasses.contains(backend.jsBoolClass)) {
      neededClasses.add(compiler.boolClass);
    }
    if (neededClasses.contains(backend.jsArrayClass)) {
      neededClasses.add(compiler.listClass);
    }

    // 5. Finally, sort the classes.
    List<ClassElement> sortedClasses = Elements.sortedByPosition(neededClasses);

    for (ClassElement element in sortedClasses) {
      if (typeTestEmitter.rtiNeededClasses.contains(element)) {
        // TODO(sigurdm): We might be able to defer some of these.
        outputClassLists.putIfAbsent(compiler.deferredLoadTask.mainOutputUnit,
            () => new List<ClassElement>()).add(element);
      } else if (Elements.isNativeOrExtendsNative(element)) {
        // For now, native classes and related classes cannot be deferred.
        nativeClasses.add(element);
        if (!element.isNative) {
          assert(invariant(element,
                           !compiler.deferredLoadTask.isDeferred(element)));
          outputClassLists.putIfAbsent(compiler.deferredLoadTask.mainOutputUnit,
              () => new List<ClassElement>()).add(element);
        }
      } else {
        outputClassLists.putIfAbsent(
            compiler.deferredLoadTask.outputUnitForElement(element),
            () => new List<ClassElement>())
            .add(element);
      }
    }
  }

  void emitInitFunction(CodeBuffer buffer) {
    jsAst.FunctionDeclaration decl = js.statement('''
      function init() {
        $isolateProperties = {};
        #; #; #;
      }''', [
          buildDefineClassAndFinishClassFunctionsIfNecessary(),
          buildLazyInitializerFunctionIfNecessary(),
          buildFinishIsolateConstructor()]);

    buffer.write(jsAst.prettyPrint(decl, compiler).getText());
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

  void writeLibraryDescriptors(LibraryElement library) {
    var uri = library.canonicalUri;
    if (uri.scheme == 'file' && compiler.outputUri != null) {
      uri = relativize(compiler.outputUri, library.canonicalUri, false);
    }
    Map<OutputUnit, ClassBuilder> descriptors =
        elementDescriptors[library];

    for (OutputUnit outputUnit in compiler.deferredLoadTask.allOutputUnits) {
      ClassBuilder descriptor =
          descriptors.putIfAbsent(outputUnit, () => new ClassBuilder(namer));
      if (descriptor.properties.isEmpty) continue;
      bool isDeferred =
          outputUnit != compiler.deferredLoadTask.mainOutputUnit;
      jsAst.Fun metadata = metadataEmitter.buildMetadataFunction(library);

      jsAst.ObjectInitializer initializers =
          descriptor.toObjectInitializer();
      CodeBuffer outputBuffer =
          outputBuffers.putIfAbsent(outputUnit, () => new CodeBuffer());
      int sizeBefore = outputBuffer.length;
      outputBuffers[outputUnit]
          ..write('["${library.getLibraryName()}",$_')
          ..write('"${uri}",$_')
          ..write(metadata == null ? "" : jsAst.prettyPrint(metadata, compiler))
          ..write(',$_')
          ..write(namer.globalObjectFor(library))
          ..write(',$_')
          ..write(jsAst.prettyPrint(initializers, compiler))
          ..write(library == compiler.mainApp ? ',${n}1' : "")
          ..write('],$n');
      int sizeAfter = outputBuffer.length;
      compiler.dumpInfoTask.codeSizeCounter
          .countCode(library, sizeAfter - sizeBefore);
    }
  }

  String assembleProgram() {
    measure(() {
      invalidateCaches();

      // Compute the required type checks to know which classes need a
      // 'is$' method.
      typeTestEmitter.computeRequiredTypeChecks();

      computeNeededClasses();

      mainBuffer.add(buildGeneratedBy());
      addComment(HOOKS_API_USAGE, mainBuffer);

      if (!compiler.deferredLoadTask.splitProgram) {
        mainBuffer.add('(function(${namer.currentIsolate})$_{$n');
      }

      // Using a named function here produces easier to read stack traces in
      // Chrome/V8.
      mainBuffer.add('function dart(){${_}this.x$_=${_}0$_}');
      for (String globalObject in Namer.reservedGlobalObjectNames) {
        // The global objects start as so-called "slow objects". For V8, this
        // means that it won't try to make map transitions as we add properties
        // to these objects. Later on, we attempt to turn these objects into
        // fast objects by calling "convertToFastObject" (see
        // [emitConvertToFastObjectFunction]).
        mainBuffer
            ..write('var ${globalObject}$_=${_}new dart$N')
            ..write('delete ${globalObject}.x$N');
      }

      mainBuffer.add('function ${namer.isolateName}()$_{}\n');
      mainBuffer.add('init()$N$n');
      // Shorten the code by using [namer.currentIsolate] as temporary.
      isolateProperties = namer.currentIsolate;
      mainBuffer.add(
          '$isolateProperties$_=$_$isolatePropertiesName$N');

      emitStaticFunctions();

      // Only output the classesCollector if we actually have any classes.
      if (!(nativeClasses.isEmpty &&
            compiler.codegenWorld.staticFunctionsNeedingGetter.isEmpty &&
          outputClassLists.values.every((classList) => classList.isEmpty))) {
        // Shorten the code by using "$$" as temporary.
        classesCollector = r"$$";
        mainBuffer.add('var $classesCollector$_=$_{}$N$n');
      }

      // Emit native classes on [nativeBuffer].
      // Might create methodClosures.
      final CodeBuffer nativeBuffer = new CodeBuffer();
      if (!nativeClasses.isEmpty) {
        addComment('Native classes', nativeBuffer);
        addComment('Native classes', mainBuffer);
        nativeEmitter.generateNativeClasses(nativeClasses, mainBuffer,
            additionalProperties);
      }

      // As a side-effect, emitting classes will produce "bound closures" in
      // [methodClosures].  The bound closures are JS AST nodes that add
      // properties to $$ [classesCollector].  The bound closures are not
      // emitted until we have emitted all other classes (native or not).

      // Might create methodClosures.
      for (List<ClassElement> outputClassList in outputClassLists.values) {
        for (ClassElement element in outputClassList) {
          generateClass(element, getElementDecriptor(element));
        }
      }

      nativeEmitter.finishGenerateNativeClasses();
      nativeEmitter.assembleCode(nativeBuffer);


      // After this assignment we will produce invalid JavaScript code if we use
      // the classesCollector variable.
      classesCollector = 'classesCollector should not be used from now on';

      // TODO(sigurdm): Need to check this for each outputUnit.
      if (!elementDescriptors.isEmpty) {
        var oldClassesCollector = classesCollector;
        classesCollector = r"$$";
        if (compiler.enableMinification) {
          mainBuffer.write(';');
        }

        for (Element element in elementDescriptors.keys) {
          // TODO(ahe): Should iterate over all libraries.  Otherwise, we will
          // not see libraries that only have fields.
          if (element.isLibrary) {
            LibraryElement library = element;
            ClassBuilder builder = new ClassBuilder(namer);
            if (classEmitter.emitFields(
                    library, builder, null, emitStatics: true)) {
              OutputUnit mainUnit = compiler.deferredLoadTask.mainOutputUnit;
              getElementDescriptorForOutputUnit(library, mainUnit)
                  .properties.addAll(builder.toObjectInitializer().properties);
            }
          }
        }

        if (!mangledFieldNames.isEmpty) {
          var keys = mangledFieldNames.keys.toList();
          keys.sort();
          var properties = [];
          for (String key in keys) {
            var value = js.string('${mangledFieldNames[key]}');
            properties.add(new jsAst.Property(js.string(key), value));
          }
          var map = new jsAst.ObjectInitializer(properties);
          mainBuffer.write(
              jsAst.prettyPrint(
                  js.statement('init.mangledNames = #', map), compiler));
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
          var map = new jsAst.ObjectInitializer(properties);
          mainBuffer.write(
              jsAst.prettyPrint(
                  js.statement('init.mangledGlobalNames = #', map),
                  compiler));
          if (compiler.enableMinification) {
            mainBuffer.write(';');
          }
        }
        mainBuffer
            ..write('(')
            ..write(
                jsAst.prettyPrint(
                    getReflectionDataParser(classesCollector, backend),
                    compiler))
            ..write(')')
            ..write('([$n');

        List<Element> sortedElements =
            Elements.sortedByPosition(elementDescriptors.keys);

        Iterable<Element> pendingStatics;
        if (!compiler.hasIncrementalSupport) {
          pendingStatics = sortedElements.where((element) {
              return !element.isLibrary &&
                  elementDescriptors[element].values.any((descriptor) =>
                      descriptor != null);
          });

          pendingStatics.forEach((element) =>
              compiler.reportInfo(
                  element, MessageKind.GENERIC, {'text': 'Pending statics.'}));
        }
        for (LibraryElement library in sortedElements.where((element) =>
            element.isLibrary)) {
          writeLibraryDescriptors(library);
          elementDescriptors[library] = const {};
        }
        if (pendingStatics != null && !pendingStatics.isEmpty) {
          compiler.internalError(pendingStatics.first,
              'Pending statics (see above).');
        }
        mainBuffer.write('])$N');

        emitFinishClassesInvocationIfNecessary(mainBuffer);
        classesCollector = oldClassesCollector;
      }
      OutputUnit mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
      typeTestEmitter.emitRuntimeTypeSupport(mainBuffer, mainOutputUnit);
      interceptorEmitter.emitGetInterceptorMethods(mainBuffer);
      interceptorEmitter.emitOneShotInterceptors(mainBuffer);
      // Constants in checked mode call into RTI code to set type information
      // which may need getInterceptor (and one-shot interceptor) methods, so
      // we have to make sure that [emitGetInterceptorMethods] and
      // [emitOneShotInterceptors] have been called.
      computeNeededConstants();
      emitCompileTimeConstants(mainBuffer, mainOutputUnit);

      // Write a javascript mapping from Deferred import load ids (derrived from
      // the import prefix.) to a list of lists of js hunks to load.
      // TODO(sigurdm): Create a syntax tree for this.
      // TODO(sigurdm): Also find out where to place it.
      mainBuffer.write("\$.libraries_to_load = {");
      for (String loadId in compiler.deferredLoadTask.hunksToLoad.keys) {
        // TODO(sigurdm): Escape these strings.
        mainBuffer.write('"$loadId":[');
        for (List<OutputUnit> outputUnits in
            compiler.deferredLoadTask.hunksToLoad[loadId]) {
          mainBuffer.write("[");
          for (OutputUnit outputUnit in outputUnits) {
            mainBuffer
              .write('"${outputUnit.partFileName(compiler)}.part.js", ');
          }
          mainBuffer.write("],");
        }
        mainBuffer.write("],\n");
      }
      mainBuffer.write("}$N");
      // Static field initializations require the classes and compile-time
      // constants to be set up.
      emitStaticNonFinalFieldInitializations(mainBuffer);
      interceptorEmitter.emitInterceptedNames(mainBuffer);
      interceptorEmitter.emitMapTypeToInterceptor(mainBuffer);
      emitLazilyInitializedStaticFields(mainBuffer);

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

      emitMain(mainBuffer);
      jsAst.FunctionDeclaration precompiledFunctionAst =
          buildPrecompiledFunction();
      emitInitFunction(mainBuffer);
      if (!compiler.deferredLoadTask.splitProgram) {
        mainBuffer.add('})()\n');
      } else {
        mainBuffer.add('\n');
      }

      if (compiler.useContentSecurityPolicy) {
        mainBuffer.write(
            jsAst.prettyPrint(
                precompiledFunctionAst, compiler,
                allowVariableMinification: false).getText());
      }

      String assembledCode = mainBuffer.getText();
      String sourceMapTags = "";
      if (generateSourceMap) {
        outputSourceMap(assembledCode, mainBuffer, '',
            compiler.sourceMapUri, compiler.outputUri);
        sourceMapTags =
            generateSourceMapTag(compiler.sourceMapUri, compiler.outputUri);
      }
      compiler.outputProvider('', 'js')
          ..add(assembledCode)
          ..add(sourceMapTags)
          ..close();
      compiler.assembledCode = assembledCode;

      if (!compiler.useContentSecurityPolicy) {
        mainBuffer.write("""
{
  var message =
      'Deprecation: Automatic generation of output for Content Security\\n' +
      'Policy is deprecated and will be removed with the next development\\n' +
      'release. Use the --csp option to generate CSP restricted output.';
  if (typeof dartPrint == "function") {
    dartPrint(message);
  } else if (typeof console == "object" && typeof console.log == "function") {
    console.log(message);
  } else if (typeof print == "function") {
    print(message);
  }
}\n""");

        mainBuffer.write(
            jsAst.prettyPrint(
                precompiledFunctionAst, compiler,
                allowVariableMinification: false).getText());

        compiler.outputProvider('', 'precompiled.js')
            ..add(mainBuffer.getText())
            ..close();
      }
      emitDeferredCode();

      if (backend.requiresPreamble &&
          !backend.htmlLibraryIsLoaded) {
        compiler.reportHint(NO_LOCATION_SPANNABLE, MessageKind.PREAMBLE);
      }
    });
    return compiler.assembledCode;
  }

  String generateSourceMapTag(Uri sourceMapUri, Uri fileUri) {
    if (sourceMapUri != null && fileUri != null) {
      // Using # is the new proposed standard. @ caused problems in Internet
      // Explorer due to "Conditional Compilation Statements" in JScript,
      // see:
      // http://msdn.microsoft.com/en-us/library/7kx09ct1(v=vs.80).aspx
      // About source maps, see:
      // https://docs.google.com/a/google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit
      // TODO(http://dartbug.com/11914): Remove @ line.
      String sourceMapFileName = relativize(fileUri, sourceMapUri, false);
      return '''

//# sourceMappingURL=$sourceMapFileName
//@ sourceMappingURL=$sourceMapFileName
''';
    }
    return '';
  }

  ClassBuilder getElementDescriptorForOutputUnit(Element element,
                                                 OutputUnit outputUnit) {
    Map<OutputUnit, ClassBuilder> descriptors =
        elementDescriptors.putIfAbsent(
            element, () => new Map<OutputUnit, ClassBuilder>());
    return descriptors.putIfAbsent(outputUnit,
        () => new ClassBuilder(namer));
  }

  ClassBuilder getElementDecriptor(Element element) {
    Element owner = element.library;
    if (!element.isTopLevel && !element.isNative) {
      // For static (not top level) elements, record their code in a buffer
      // specific to the class. For now, not supported for native classes and
      // native elements.
      ClassElement cls =
          element.enclosingClassOrCompilationUnit.declaration;
      if (compiler.codegenWorld.instantiatedClasses.contains(cls)
          && !cls.isNative) {
        owner = cls;
      }
    }
    if (owner == null) {
      compiler.internalError(element, 'Owner is null.');
    }
    return getElementDescriptorForOutputUnit(owner,
        compiler.deferredLoadTask.outputUnitForElement(element));
  }

  void emitDeferredCode() {
    for (OutputUnit outputUnit in compiler.deferredLoadTask.allOutputUnits) {
      if (outputUnit == compiler.deferredLoadTask.mainOutputUnit) continue;
      CodeBuffer outputBuffer = outputBuffers.putIfAbsent(outputUnit,
          () => new CodeBuffer());

      var oldClassesCollector = classesCollector;
      classesCollector = r"$$";

      var buffer = new CodeBuffer()
        ..write(buildGeneratedBy())
        ..write('var old${namer.currentIsolate}$_='
                '$_${namer.currentIsolate}$N'
                // TODO(ahe): This defines a lot of properties on the
                // Isolate.prototype object.  We know this will turn it into a
                // slow object in V8, so instead we should do something similar
                // to Isolate.$finishIsolateConstructor.
                '${namer.currentIsolate}$_='
                '$_${namer.isolateName}.prototype$N$n'
                // The classesCollector object ($$).
                '$classesCollector$_=$_{};$n')
        ..write('(')
        ..write(
            jsAst.prettyPrint(
                getReflectionDataParser(classesCollector, backend),
                compiler))
        ..write(')')
        ..write('([$n')
        ..addBuffer(outputBuffer)
        ..write('])$N');

      if (outputClassLists.containsKey(outputUnit)) {
        buffer.write(
            '$finishClassesName($classesCollector,$_${namer.currentIsolate},'
            '$_$isolatePropertiesName)$N');
      }

      buffer.write(
          // Reset the classesCollector ($$).
          '$classesCollector$_=${_}null$N$n'
          '${namer.currentIsolate}$_=${_}old${namer.currentIsolate}$N');

      classesCollector = oldClassesCollector;

      typeTestEmitter.emitRuntimeTypeSupport(buffer, outputUnit);

      emitCompileTimeConstants(buffer, outputUnit);

      String code = buffer.getText();
      compiler.outputProvider(outputUnit.partFileName(compiler), 'part.js')
        ..add(code)
        ..close();

      // TODO(johnniwinther): Support source maps for deferred code.
    }
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

  void registerReadTypeVariable(TypeVariableElement element) {
    readTypeVariables.add(element);
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
