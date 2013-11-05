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

  bool needsDefineClass = false;
  bool needsMixinSupport = false;
  bool needsLazyInitializer = false;
  final Namer namer;
  ConstantEmitter constantEmitter;
  NativeEmitter nativeEmitter;
  CodeBuffer mainBuffer;
  final CodeBuffer deferredLibraries = new CodeBuffer();
  final CodeBuffer deferredConstants = new CodeBuffer();
  /** Shorter access to [isolatePropertiesName]. Both here in the code, as
      well as in the generated code. */
  String isolateProperties;
  String classesCollector;
  final Set<ClassElement> neededClasses = new Set<ClassElement>();
  final List<ClassElement> regularClasses = <ClassElement>[];
  final List<ClassElement> deferredClasses = <ClassElement>[];
  final List<ClassElement> nativeClasses = <ClassElement>[];
  final Map<String, String> mangledFieldNames = <String, String>{};
  final Map<String, String> mangledGlobalFieldNames = <String, String>{};
  final Set<String> recordedMangledNames = new Set<String>();

  final Map<ClassElement, Map<String, jsAst.Expression>> additionalProperties =
      new Map<ClassElement, Map<String, jsAst.Expression>>();

  // TODO(ngeoffray): remove this field.
  Set<ClassElement> instantiatedClasses;

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
   * dynamically. This doesn't work in CSP mode, and may impact startup time
   * negatively. So dart2js will emit these functions to a separate file that
   * can be optionally included to support CSP mode or for faster startup.
   */
  List<jsAst.Node> precompiledFunction = <jsAst.Node>[];

  List<jsAst.Expression> precompiledConstructorNames = <jsAst.Expression>[];

  // True if Isolate.makeConstantList is needed.
  bool hasMakeConstantList = false;

  /**
   * For classes and libraries, record code for static/top-level members.
   * Later, this code is emitted when the class or library is emitted.
   * See [bufferForElement].
   */
  // TODO(ahe): Generate statics with their class, and store only libraries in
  // this map.
  final Map<Element, List<CodeBuffer>> elementBuffers =
      new Map<Element, List<CodeBuffer>>();

  final bool generateSourceMap;

  CodeEmitterTask(Compiler compiler, Namer namer, this.generateSourceMap)
      : mainBuffer = new CodeBuffer(),
        this.namer = namer,
        constantEmitter = new ConstantEmitter(compiler, namer),
        super(compiler) {
    nativeEmitter = new NativeEmitter(this);
    containerBuilder.task = this;
    classEmitter.task = this;
    nsmEmitter.task = this;
    typeTestEmitter.task = this;
    interceptorEmitter.task = this;
    metadataEmitter.task = this;
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
      => '${namer.CURRENT_ISOLATE}.\$generateAccessor';
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

    // function generateAccessor(field, prototype, cls) {
    jsAst.Fun fun = js.fun(['field', 'accessors', 'cls'], [
      js('var len = field.length'),
      js('var code = field.charCodeAt(len - 1)'),
      js('var reflectable = false'),
      js.if_('code == $REFLECTION_MARKER', [
          js('len--'),
          js('code = field.charCodeAt(len - 1)'),
          js('field = field.substring(0, len)'),
          js('reflectable = true')
      ]),
      js('code = ((code >= $RANGE1_FIRST) && (code <= $RANGE1_LAST))'
          '    ? code - $RANGE1_ADJUST'
          '    : ((code >= $RANGE2_FIRST) && (code <= $RANGE2_LAST))'
          '      ? code - $RANGE2_ADJUST'
          '      : ((code >= $RANGE3_FIRST) && (code <= $RANGE3_LAST))'
          '        ? code - $RANGE3_ADJUST'
          '        : $NO_FIELD_CODE'),

      // if (needsAccessor) {
      js.if_('code', [
        js('var getterCode = code & 3'),
        js('var setterCode = code >> 2'),
        js('var accessorName = field = field.substring(0, len - 1)'),

        js('var divider = field.indexOf(":")'),
        js.if_('divider > 0', [  // Colon never in first position.
          js('accessorName = field.substring(0, divider)'),
          js('field = field.substring(divider + 1)')
        ]),

        // if (needsGetter) {
        js.if_('getterCode', [
          js('var args = (getterCode & 2) ? "$receiverParamName" : ""'),
          js('var receiver = (getterCode & 1) ? "this" : "$receiverParamName"'),
          js('var body = "return " + receiver + "." + field'),
          js('var property ='
             ' cls + ".prototype.${namer.getterPrefix}" + accessorName + "="'),
          js('var fn = "function(" + args + "){" + body + "}"'),
          js.if_(
              'reflectable',
              js('accessors.push(property + "\$reflectable(" + fn + ");\\n")'),
              js('accessors.push(property + fn + ";\\n")')),
        ]),

        // if (needsSetter) {
        js.if_('setterCode', [
          js('var args = (setterCode & 2)'
              '  ? "$receiverParamName,${_}$valueParamName"'
              '  : "$valueParamName"'),
          js('var receiver = (setterCode & 1) ? "this" : "$receiverParamName"'),
          js('var body = receiver + "." + field + "$_=$_$valueParamName"'),
          js('var property ='
             ' cls + ".prototype.${namer.setterPrefix}" + accessorName + "="'),
          js('var fn = "function(" + args + "){" + body + "}"'),
          js.if_(
              'reflectable',
              js('accessors.push(property + "\$reflectable(" + fn + ");\\n")'),
              js('accessors.push(property + fn + ";\\n")')),
        ]),

      ]),

      // return field;
      js.return_('field')
    ]);

    return new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration('generateAccessor'),
        fun);
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

    var defineClass = js.fun(['name', 'cls', 'fields'], [
      js('var accessors = []'),

      js('var str = "function " + cls + "("'),
      js('var body = ""'),

      js.for_('var i = 0', 'i < fields.length', 'i++', [
        js.if_('i != 0', js('str += ", "')),

        js('var field = generateAccessor(fields[i], accessors, cls)'),
        js('var parameter = "parameter_" + field'),
        js('str += parameter'),
        js('body += ("this." + field + " = " + parameter + ";\\n")')
      ]),
      js('str += ") {\\n" + body + "}\\n"'),
      js('str += cls + ".builtin\$cls=\\"" + name + "\\";\\n"'),
      js('str += "\$desc=\$collectedClasses." + cls + ";\\n"'),
      js('str += "if(\$desc instanceof Array) \$desc = \$desc[1];\\n"'),
      js('str += cls + ".prototype = \$desc;\\n"'),
      js.if_(
          'typeof defineClass.name != "string"',
          [js('str += cls + ".name=\\"" + cls + "\\";\\n"')]),
      js('str += accessors.join("")'),

      js.return_('str')
    ]);
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
    return [
      js('var inheritFrom = #',
          js.fun([], [
              new jsAst.FunctionDeclaration(
                  new jsAst.VariableDeclaration('tmp'), js.fun([], [])),
              js('var hasOwnProperty = Object.prototype.hasOwnProperty'),
              js.return_(js.fun(['constructor', 'superConstructor'], [
                  js('tmp.prototype = superConstructor.prototype'),
                  js('var object = new tmp()'),
                  js('var properties = constructor.prototype'),
                  js.forIn('member', 'properties',
                    js.if_('hasOwnProperty.call(properties, member)',
                           js('object[member] = properties[member]'))),
                  js('object.constructor = constructor'),
                  js('constructor.prototype = object'),
                  js.return_('object')
              ]))])())];
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
    List<jsAst.Node> statements = [
      js('var pendingClasses = {}'),
      js.if_('!init.allClasses', js('init.allClasses = {}')),
      js('var allClasses = init.allClasses'),

      optional(
          DEBUG_FAST_OBJECTS,
          js('print("Number of classes: "'
             r' + Object.getOwnPropertyNames($$).length)')),

      js('var hasOwnProperty = Object.prototype.hasOwnProperty'),

      js.if_('typeof dart_precompiled == "function"',
          [js('var constructors = dart_precompiled(collectedClasses)')],

          [js('var combinedConstructorFunction = "function \$reflectable(fn){'
              'fn.$reflectableField=1;return fn};\\n"+ "var \$desc;\\n"'),
           js('var constructorsList = []')]),
      js.forIn('cls', 'collectedClasses', [
        js.if_('hasOwnProperty.call(collectedClasses, cls)', [
          js('var desc = collectedClasses[cls]'),
          js.if_('desc instanceof Array', js('desc = desc[1]')),

          /* The 'fields' are either a constructor function or a
           * string encoding fields, constructor and superclass.  Get
           * the superclass and the fields in the format
           *   '[name/]Super;field1,field2'
           * from the null-string property on the descriptor.
           * The 'name/' is optional and contains the name that should be used
           * when printing the runtime type string.  It is used, for example, to
           * print the runtime type JSInt as 'int'.
           */
          js('var classData = desc[""], supr, name = cls, fields = classData'),
          optional(
              backend.hasRetainedMetadata,
              js.if_('typeof classData == "object" && '
                     'classData instanceof Array',
                     [js('classData = fields = classData[0]')])),

          js.if_('typeof classData == "string"', [
            js('var split = classData.split("/")'),
            js.if_('split.length == 2', [
              js('name = split[0]'),
              js('fields = split[1]')
            ])
          ]),

          js('var s = fields.split(";")'),
          js('fields = s[1] == "" ? [] : s[1].split(",")'),
          js('supr = s[0]'),

          optional(needsMixinSupport, js.if_('supr && supr.indexOf("+") > 0', [
            js('s = supr.split("+")'),
            js('supr = s[0]'),
            js('var mixin = collectedClasses[s[1]]'),
            js.if_('mixin instanceof Array', js('mixin = mixin[1]')),
            js.forIn('d', 'mixin', [
              js.if_('hasOwnProperty.call(mixin, d)'
                     '&& !hasOwnProperty.call(desc, d)',
                js('desc[d] = mixin[d]'))
            ]),
          ])),

          js.if_('typeof dart_precompiled != "function"',
              [js('combinedConstructorFunction +='
                  ' defineClass(name, cls, fields)'),
                 js('constructorsList.push(cls)')]),
          js.if_('supr', js('pendingClasses[cls] = supr'))
        ])
      ]),
      js.if_('typeof dart_precompiled != "function"',
          [js('combinedConstructorFunction +='
              ' "return [\\n  " + constructorsList.join(",\\n  ") + "\\n]"'),
           js('var constructors ='
              ' new Function("\$collectedClasses", combinedConstructorFunction)'
              '(collectedClasses)'),
           js('combinedConstructorFunction = null')]),
      js.for_('var i = 0', 'i < constructors.length', 'i++', [
        js('var constructor = constructors[i]'),
        js('var cls = constructor.name'),
        js('var desc = collectedClasses[cls]'),
        js('var globalObject = isolateProperties'),
        js.if_('desc instanceof Array', [
            js('globalObject = desc[0] || isolateProperties'),
            js('desc = desc[1]')
        ]),
        optional(backend.isTreeShakingDisabled,
                 js('constructor["${namer.metadataField}"] = desc')),
        js('allClasses[cls] = constructor'),
        js('globalObject[cls] = constructor'),
      ]),
      js('constructors = null'),

      js('var finishedClasses = {}'),
      js('init.interceptorsByTag = Object.create(null)'),
      js('init.leafTags = {}'),

      buildFinishClass(),
    ];

    nsmEmitter.addTrivialNsmHandlers(statements);

    statements.add(
      js.forIn('cls', 'pendingClasses', js('finishClass(cls)'))
    );
    // function(collectedClasses,
    //          isolateProperties,
    //          existingIsolateProperties)
    return js.fun(['collectedClasses', 'isolateProperties',
                   'existingIsolateProperties'], statements);
  }

  jsAst.Node optional(bool condition, jsAst.Node node) {
    return condition ? node : new jsAst.EmptyStatement();
  }

  jsAst.FunctionDeclaration buildFinishClass() {
    String specProperty = '"${namer.nativeSpecProperty}"';  // "%"

    // function finishClass(cls) {
    jsAst.Fun fun = js.fun(['cls'], [

      // TODO(8540): Remove this work around.
      /* Opera does not support 'getOwnPropertyNames'. Therefore we use
         hasOwnProperty instead. */
      js('var hasOwnProperty = Object.prototype.hasOwnProperty'),

      // if (hasOwnProperty.call(finishedClasses, cls)) return;
      js.if_('hasOwnProperty.call(finishedClasses, cls)',
             js.return_()),

      js('finishedClasses[cls] = true'),

      js('var superclass = pendingClasses[cls]'),

      // The superclass is only false (empty string) for Dart's Object class.
      // The minifier together with noSuchMethod can put methods on the
      // Object.prototype object, and they show through here, so we check that
      // we have a string.
      js.if_('!superclass || typeof superclass != "string"', js.return_()),
      js('finishClass(superclass)'),
      js('var constructor = allClasses[cls]'),
      js('var superConstructor = allClasses[superclass]'),

      js.if_(js('!superConstructor'),
             js('superConstructor ='
                    'existingIsolateProperties[superclass]')),

      js('var prototype = inheritFrom(constructor, superConstructor)'),

      optional(!nativeClasses.isEmpty,
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
          js.if_('hasOwnProperty.call(prototype, $specProperty)', [
              js('var nativeSpec = prototype[$specProperty].split(";")'),
              js.if_('nativeSpec[0]', [
                  js('var tags = nativeSpec[0].split("|")'),
                  js.for_('var i = 0', 'i < tags.length', 'i++', [
                      js('init.interceptorsByTag[tags[i]] = constructor'),
                      js('init.leafTags[tags[i]] = true')])]),
              js.if_('nativeSpec[1]', [
                  js('tags = nativeSpec[1].split("|")'),
                  optional(true, // User subclassing of native classes?
                      js.if_('nativeSpec[2]', [
                          js('var subclasses = nativeSpec[2].split("|")'),
                          js.for_('var i = 0', 'i < subclasses.length', 'i++', [
                              js('var subclass = allClasses[subclasses[i]]'),
                              js('subclass.\$nativeSuperclassTag = '
                                 'tags[0]')])])),
                  js.for_('i = 0', 'i < tags.length', 'i++', [
                      js('init.interceptorsByTag[tags[i]] = constructor'),
                      js('init.leafTags[tags[i]] = false')])])]))
    ]);

    return new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration('finishClass'),
        fun);
  }

  jsAst.Fun get finishIsolateConstructorFunction {
    // We replace the old Isolate function with a new one that initializes
    // all its fields with the initial (and often final) value of all globals.
    //
    // We also copy over old values like the prototype, and the
    // isolateProperties themselves.
    return js.fun('oldIsolate', [
      js('var isolateProperties = oldIsolate.${namer.isolatePropertiesName}'),
      new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration('Isolate'),
          js.fun([], [
            js('var hasOwnProperty = Object.prototype.hasOwnProperty'),
            js.forIn('staticName', 'isolateProperties',
              js.if_('hasOwnProperty.call(isolateProperties, staticName)',
                js('this[staticName] = isolateProperties[staticName]'))),
            // Use the newly created object as prototype. In Chrome,
            // this creates a hidden class for the object and makes
            // sure it is fast to access.
            new jsAst.FunctionDeclaration(
              new jsAst.VariableDeclaration('ForceEfficientMap'),
              js.fun([], [])),
            js('ForceEfficientMap.prototype = this'),
            js('new ForceEfficientMap()')])),
      js('Isolate.prototype = oldIsolate.prototype'),
      js('Isolate.prototype.constructor = Isolate'),
      js('Isolate.${namer.isolatePropertiesName} = isolateProperties'),
      optional(needsDefineClass,
               js('Isolate.$finishClassesProperty ='
                  ' oldIsolate.$finishClassesProperty')),
      optional(hasMakeConstantList,
               js('Isolate.makeConstantList = oldIsolate.makeConstantList')),
      js.return_('Isolate')]);
  }

  jsAst.Fun get lazyInitializerFunction {
    // function(prototype, staticName, fieldName, getterName, lazyValue) {
    var parameters = <String>['prototype', 'staticName', 'fieldName',
                              'getterName', 'lazyValue'];
    return js.fun(parameters, addLazyInitializerLogic());
  }

  List addLazyInitializerLogic() {
    String isolate = namer.CURRENT_ISOLATE;
    String cyclicThrow = namer.isolateAccess(backend.getCyclicThrowHelper());
    var lazies = [];
    if (backend.rememberLazies) {
      lazies = [
          js.if_('!init.lazies', js('init.lazies = {}')),
          js('init.lazies[fieldName] = getterName')];
    }

    return lazies..addAll([
      js('var sentinelUndefined = {}'),
      js('var sentinelInProgress = {}'),
      js('prototype[fieldName] = sentinelUndefined'),

      // prototype[getterName] = function()
      js('prototype[getterName] = #', js.fun([], [
        js('var result = $isolate[fieldName]'),

        // try
        js.try_([
          js.if_('result === sentinelUndefined', [
            js('$isolate[fieldName] = sentinelInProgress'),

            // try
            js.try_([
              js('result = $isolate[fieldName] = lazyValue()'),

            ], finallyPart: [
              // Use try-finally, not try-catch/throw as it destroys the
              // stack trace.

              // if (result === sentinelUndefined)
              js.if_('result === sentinelUndefined', [
                // if ($isolate[fieldName] === sentinelInProgress)
                js.if_('$isolate[fieldName] === sentinelInProgress', [
                  js('$isolate[fieldName] = null'),
                ])
              ])
            ])
          ], /* else */ [
            js.if_('result === sentinelInProgress',
              js('$cyclicThrow(staticName)')
            )
          ]),

          // return result;
          js.return_('result')

        ], finallyPart: [
          js('$isolate[getterName] = #',
             js.fun([], [js.return_('this[fieldName]')]))
        ])
      ]))
    ]);
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

    return [js('$lazyInitializerName = #', lazyInitializerFunction)];
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
    if (!backend.shouldRetainName(name)) {
      if (name == '' && elementOrSelector is Element) {
        // Make sure to retain names of unnamed constructors.
        if (!backend.isNeededForReflection(elementOrSelector)) return null;
      } else {
        return null;
      }
    }
    // TODO(ahe): Enable the next line when I can tell the difference between
    // an instance method and a global.  They may have the same mangled name.
    // if (recordedMangledNames.contains(mangledName)) return null;
    recordedMangledNames.add(mangledName);
    return getReflectionNameInternal(elementOrSelector, mangledName);
  }

  String getReflectionNameInternal(elementOrSelector, String mangledName) {
    String name = elementOrSelector.name;
    if (elementOrSelector.isGetter()) return name;
    if (elementOrSelector.isSetter()) {
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
    if (elementOrSelector is Selector
        || elementOrSelector.isFunction()
        || elementOrSelector.isConstructor()) {
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
        if (function.isConstructor()) {
          isConstructor = true;
          name = Elements.reconstructConstructorName(function);
        }
        requiredParameterCount = function.requiredParameterCount(compiler);
        optionalParameterCount = function.optionalParameterCount(compiler);
        FunctionSignature signature = function.computeSignature(compiler);
        if (signature.optionalParametersAreNamed) {
          var names = [];
          for (Element e in signature.optionalParameters) {
            names.add(e.name);
          }
          Selector selector = new Selector.call(
              function.name,
              function.getLibrary(),
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
    if (element.isGenerativeConstructorBody()) {
      return null;
    } else if (element.isClass()) {
      ClassElement cls = element;
      if (cls.isUnnamedMixinApplication) return null;
      return cls.name;
    }
    throw compiler.internalErrorOnElement(
        element, 'Do not know how to reflect on this $element');
  }

  String namedParametersAsReflectionNames(Selector selector) {
    if (selector.getOrderedNamedArguments().isEmpty) return '';
    String names = selector.getOrderedNamedArguments().join(':');
    return ':$names';
  }

  jsAst.FunctionDeclaration buildPrecompiledFunction() {
    // TODO(ahe): Compute a hash code.
    String name = 'dart_precompiled';

    precompiledFunction.add(
        js.return_(
            new jsAst.ArrayInitializer.from(precompiledConstructorNames)));
    precompiledFunction.insert(0, js(r'var $desc'));
    return new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration(name),
        js.fun([r'$collectedClasses'], precompiledFunction));
  }

  void generateClass(ClassElement classElement, CodeBuffer buffer) {
    classEmitter.generateClass(
        classElement, buffer, additionalProperties[classElement]);
  }

  int _selectorRank(Selector selector) {
    int arity = selector.argumentCount * 3;
    if (selector.isGetter()) return arity + 2;
    if (selector.isSetter()) return arity + 1;
    return arity;
  }

  int _compareSelectorNames(Selector selector1, Selector selector2) {
    String name1 = selector1.name.toString();
    String name2 = selector2.name.toString();
    if (name1 != name2) return Comparable.compare(name1, name2);
    return _selectorRank(selector1) - _selectorRank(selector2);
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

  void emitStaticFunctions(CodeBuffer eagerBuffer) {
    bool isStaticFunction(Element element) =>
        !element.isInstanceMember() && !element.isField();

    Iterable<Element> elements =
        backend.generatedCode.keys.where(isStaticFunction);

    for (Element element in Elements.sortedByPosition(elements)) {
      ClassBuilder builder = new ClassBuilder();
      containerBuilder.addMember(element, builder);
      builder.writeOn_DO_NOT_USE(
          bufferForElement(element, eagerBuffer), compiler, ',$n$n');
    }
  }

  void emitStaticNonFinalFieldInitializations(CodeBuffer buffer) {
    ConstantHandler handler = compiler.constantHandler;
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
          js('$isolateProperties.${namer.getNameOfGlobalField(element)} = #',
              constantEmitter.referenceInInitializationContext(initialValue));
        buffer.write(jsAst.prettyPrint(init, compiler));
        buffer.write('$N');
      });
    }
  }

  void emitLazilyInitializedStaticFields(CodeBuffer buffer) {
    ConstantHandler handler = compiler.constantHandler;
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
        List<jsAst.Expression> arguments = <jsAst.Expression>[];
        arguments.add(js(isolateProperties));
        arguments.add(js.string(element.name));
        arguments.add(js.string(namer.getNameX(element)));
        arguments.add(js.string(namer.getLazyInitializerName(element)));
        arguments.add(code);
        jsAst.Expression getter = buildLazyInitializedGetter(element);
        if (getter != null) {
          arguments.add(getter);
        }
        jsAst.Expression init = js(lazyInitializerName)(arguments);
        buffer.write(jsAst.prettyPrint(init, compiler));
        buffer.write("$N");
      }
    }
  }

  jsAst.Expression buildLazyInitializedGetter(VariableElement element) {
    // Nothing to do, the 'lazy' function will create the getter.
    return null;
  }

  void emitCompileTimeConstants(CodeBuffer eagerBuffer) {
    ConstantHandler handler = compiler.constantHandler;
    List<Constant> constants = handler.getConstantsForEmission(
        compareConstants);
    for (Constant constant in constants) {
      if (isConstantInlinedOrAlreadyEmitted(constant)) continue;
      String name = namer.constantName(constant);
      if (constant.isList()) emitMakeConstantListIfNotEmitted(eagerBuffer);
      CodeBuffer buffer = bufferForConstant(constant, eagerBuffer);
      jsAst.Expression init = js(
          '${namer.globalObjectForConstant(constant)}.$name = #',
          constantInitializerExpression(constant));
      buffer.write(jsAst.prettyPrint(init, compiler));
      buffer.write('$N');
    }
  }

  bool isConstantInlinedOrAlreadyEmitted(Constant constant) {
    if (constant.isFunction()) return true;   // Already emitted.
    if (constant.isPrimitive()) return true;  // Inlined.
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
    buffer
        ..write(namer.isolateName)
        ..write(r'''.makeConstantList = function(list) {
  list.immutable$list = true;
  list.fixed$length = true;
  return list;
};
''');
  }

  String buildIsolateSetup(CodeBuffer buffer,
                           Element appMain,
                           Element isolateMain) {
    String mainAccess = "${namer.isolateStaticClosureAccess(appMain)}";
    // Since we pass the closurized version of the main method to
    // the isolate method, we must make sure that it exists.
    return "${namer.isolateAccess(isolateMain)}($mainAccess)";
  }

  jsAst.Expression generateDispatchPropertyInitialization() {
    return js('!#', js.fun([], [
        js('var objectProto = Object.prototype'),
        js.for_('var i = 0', null, 'i++', [
            js('var property = "${generateDispatchPropertyName(0)}"'),
            js.if_('i > 0', js('property = rootProperty + "_" + i')),
            js.if_('!(property in  objectProto)',
                   js.return_(
                       js('init.dispatchPropertyName = property')))])])());
  }

  String generateDispatchPropertyName(int seed) {
    // TODO(sra): MD5 of contributing source code or URIs?
    return '___dart_dispatch_record_ZxYxX_${seed}_';
  }

  emitMain(CodeBuffer buffer) {
    if (compiler.isMockCompilation) return;
    Element main = compiler.mainFunction;
    String mainCall = null;
    if (compiler.hasIsolateSupport()) {
      Element isolateMain =
        compiler.isolateHelperLibrary.find(Compiler.START_ROOT_ISOLATE);
      mainCall = buildIsolateSetup(buffer, main, isolateMain);
    } else {
      mainCall = '${namer.isolateAccess(main)}()';
    }
    if (backend.needToInitializeDispatchProperty) {
      buffer.write(
          jsAst.prettyPrint(generateDispatchPropertyInitialization(),
                            compiler));
      buffer.write(N);
    }
    addComment('BEGIN invoke [main].', buffer);
    // This code finds the currently executing script by listening to the
    // onload event of all script tags and getting the first script which
    // finishes. Since onload is called immediately after execution this should
    // not substantially change execution order.
    buffer.write('''
;(function (callback) {
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
    dartMainRunner(function() { ${mainCall}; });
  } else {
    ${mainCall};
  }
})$N''');
    addComment('END invoke [main].', buffer);
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
        if (!element.isNative()) continue;
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

    // 5. Finally, sort the classes.
    List<ClassElement> sortedClasses = Elements.sortedByPosition(neededClasses);

    for (ClassElement element in sortedClasses) {
      if (typeTestEmitter.rtiNeededClasses.contains(element)) {
        regularClasses.add(element);
      } else if (Elements.isNativeOrExtendsNative(element)) {
        // For now, native classes and related classes cannot be deferred.
        nativeClasses.add(element);
        if (!element.isNative()) {
          assert(invariant(element, !isDeferred(element)));
          regularClasses.add(element);
        }
      } else if (isDeferred(element)) {
        deferredClasses.add(element);
      } else {
        regularClasses.add(element);
      }
    }
  }

  void emitInitFunction(CodeBuffer buffer) {
    jsAst.Fun fun = js.fun([], [
      js('$isolateProperties = {}'),
    ]
    ..addAll(buildDefineClassAndFinishClassFunctionsIfNecessary())
    ..addAll(buildLazyInitializerFunctionIfNecessary())
    ..addAll(buildFinishIsolateConstructor())
    );
    jsAst.FunctionDeclaration decl = new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration('init'), fun);
    buffer.write(jsAst.prettyPrint(decl, compiler).getText());
    if (compiler.enableMinification) buffer.write('\n');
  }

  void emitConvertToFastObjectFunction() {
    // Create an instance that uses 'properties' as prototype. This should make
    // 'properties' a fast object.
    mainBuffer.add(r'''function convertToFastObject(properties) {
  function MyClass() {};
  MyClass.prototype = properties;
  new MyClass();
''');
    if (DEBUG_FAST_OBJECTS) {
      ClassElement primitives =
          compiler.findHelper('Primitives');
      FunctionElement printHelper =
          compiler.lookupElementIn(
              primitives, 'printString');
      String printHelperName = namer.isolateAccess(printHelper);
      mainBuffer.add('''
// The following only works on V8 when run with option "--allow-natives-syntax".
if (typeof $printHelperName === "function") {
  $printHelperName("Size of global object: "
                   + String(Object.getOwnPropertyNames(properties).length)
                   + ", fast properties " + %HasFastProperties(properties));
}
''');
    }
mainBuffer.add(r'''
  return properties;
}
''');
  }

  String assembleProgram() {
    measure(() {
      // Compute the required type checks to know which classes need a
      // 'is$' method.
      typeTestEmitter.computeRequiredTypeChecks();

      computeNeededClasses();

      mainBuffer.add(buildGeneratedBy());
      addComment(HOOKS_API_USAGE, mainBuffer);

      if (!areAnyElementsDeferred) {
        mainBuffer.add('(function(${namer.CURRENT_ISOLATE})$_{$n');
      }

      for (String globalObject in Namer.reservedGlobalObjectNames) {
        // The global objects start as so-called "slow objects". For V8, this
        // means that it won't try to make map transitions as we add properties
        // to these objects. Later on, we attempt to turn these objects into
        // fast objects by calling "convertToFastObject" (see
        // [emitConvertToFastObjectFunction]).
        mainBuffer
            ..write('var ${globalObject}$_=$_{}$N')
            ..write('delete ${globalObject}.x$N');
      }

      mainBuffer.add('function ${namer.isolateName}()$_{}\n');
      mainBuffer.add('init()$N$n');
      // Shorten the code by using [namer.CURRENT_ISOLATE] as temporary.
      isolateProperties = namer.CURRENT_ISOLATE;
      mainBuffer.add(
          '$isolateProperties$_=$_$isolatePropertiesName$N');

      emitStaticFunctions(mainBuffer);

      if (!regularClasses.isEmpty ||
          !deferredClasses.isEmpty ||
          !nativeClasses.isEmpty ||
          !compiler.codegenWorld.staticFunctionsNeedingGetter.isEmpty) {
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
      if (!regularClasses.isEmpty) {
        for (ClassElement element in regularClasses) {
          generateClass(element, bufferForElement(element, mainBuffer));
        }
      }

      nativeEmitter.finishGenerateNativeClasses();
      nativeEmitter.assembleCode(nativeBuffer);

      // Might create methodClosures.
      if (!deferredClasses.isEmpty) {
        for (ClassElement element in deferredClasses) {
          generateClass(element, bufferForElement(element, mainBuffer));
        }
      }

      containerBuilder.emitStaticFunctionClosures();

      addComment('Method closures', mainBuffer);
      // Now that we have emitted all classes, we know all the method
      // closures that will be needed.
      containerBuilder.methodClosures.forEach((String code, Element closure) {
        // TODO(ahe): Some of these can be deferred.
        String mangledName = namer.getNameOfClass(closure);
        mainBuffer.add('$classesCollector.$mangledName$_=$_'
             '[${namer.globalObjectFor(closure)},$_$code]');
        mainBuffer.add("$N$n");
      });

      // After this assignment we will produce invalid JavaScript code if we use
      // the classesCollector variable.
      classesCollector = 'classesCollector should not be used from now on';

      if (!elementBuffers.isEmpty) {
        var oldClassesCollector = classesCollector;
        classesCollector = r"$$";
        if (compiler.enableMinification) {
          mainBuffer.write(';');
        }

        for (Element element in elementBuffers.keys) {
          // TODO(ahe): Should iterate over all libraries.  Otherwise, we will
          // not see libraries that only have fields.
          if (element.isLibrary()) {
            LibraryElement library = element;
            ClassBuilder builder = new ClassBuilder();
            if (classEmitter.emitFields(
                    library, builder, null, emitStatics: true)) {
              List<CodeBuffer> buffers = elementBuffers[library];
              var buffer = buffers[0];
              if (buffer == null) {
                buffers[0] = buffer = new CodeBuffer();
              }
              for (jsAst.Property property in builder.properties) {
                if (!buffer.isEmpty) buffer.write(',$n');
                buffer.addBuffer(jsAst.prettyPrint(property, compiler));
              }
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
                  js('init.mangledNames = #', map).toStatement(), compiler));
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
                  js('init.mangledGlobalNames = #', map).toStatement(),
                  compiler));
          if (compiler.enableMinification) {
            mainBuffer.write(';');
          }
        }
        mainBuffer
            ..write(getReflectionDataParser(classesCollector, namer))
            ..write('([$n');

        List<Element> sortedElements =
            Elements.sortedByPosition(elementBuffers.keys);
        bool hasPendingStatics = false;
        for (Element element in sortedElements) {
          if (!element.isLibrary()) {
            for (CodeBuffer b in elementBuffers[element]) {
              if (b != null) {
                hasPendingStatics = true;
                compiler.reportInfo(
                    element, MessageKind.GENERIC, {'text': 'Pending statics.'});
                print(b.getText());
              }
            }
            continue;
          }
          LibraryElement library = element;
          List<CodeBuffer> buffers = elementBuffers[library];
          var buffer = buffers[0];
          var uri = library.canonicalUri;
          if (uri.scheme == 'file' && compiler.sourceMapUri != null) {
            // TODO(ahe): It is a hack to use compiler.sourceMapUri
            // here.  It should be relative to the main JavaScript
            // output file.
            uri = relativize(
                compiler.sourceMapUri, library.canonicalUri, false);
          }
          if (buffer != null) {
            var metadata = metadataEmitter.buildMetadataFunction(library);
            mainBuffer
                ..write('["${library.getLibraryName()}",$_')
                ..write('"${uri}",$_')
                ..write(metadata == null
                        ? "" : jsAst.prettyPrint(metadata, compiler))
                ..write(',$_')
                ..write(namer.globalObjectFor(library))
                ..write(',$_')
                ..write('{$n')
                ..addBuffer(buffer)
                ..write('}');
            if (library == compiler.mainApp) {
              mainBuffer.write(',${n}1');
            }
            mainBuffer.write('],$n');
          }
          buffer = buffers[1];
          if (buffer != null) {
            deferredLibraries
                ..write('["${library.getLibraryName()}",$_')
                ..write('"${uri}",$_')
                ..write('[],$_')
                ..write(namer.globalObjectFor(library))
                ..write(',$_')
                ..write('{$n')
                ..addBuffer(buffer)
                ..write('}],$n');
          }
          elementBuffers[library] = const [];
        }
        if (hasPendingStatics) {
          compiler.internalError('Pending statics (see above).');
        }
        mainBuffer.write('])$N');

        emitFinishClassesInvocationIfNecessary(mainBuffer);
        classesCollector = oldClassesCollector;
      }

      containerBuilder.emitStaticFunctionGetters(mainBuffer);

      typeTestEmitter.emitRuntimeTypeSupport(mainBuffer);
      interceptorEmitter.emitGetInterceptorMethods(mainBuffer);
      // Constants in checked mode call into RTI code to set type information
      // which may need getInterceptor methods, so we have to make sure that
      // [emitGetInterceptorMethods] has been called.
      emitCompileTimeConstants(mainBuffer);
      // Static field initializations require the classes and compile-time
      // constants to be set up.
      emitStaticNonFinalFieldInitializations(mainBuffer);
      interceptorEmitter.emitOneShotInterceptors(mainBuffer);
      interceptorEmitter.emitInterceptedNames(mainBuffer);
      interceptorEmitter.emitMapTypeToInterceptor(mainBuffer);
      emitLazilyInitializedStaticFields(mainBuffer);

      mainBuffer.add(nativeBuffer);

      metadataEmitter.emitMetadata(mainBuffer);

      isolateProperties = isolatePropertiesName;
      // The following code should not use the short-hand for the
      // initialStatics.
      mainBuffer.add('${namer.CURRENT_ISOLATE}$_=${_}null$N');

      emitFinishIsolateConstructorInvocation(mainBuffer);
      mainBuffer.add(
          '${namer.CURRENT_ISOLATE}$_=${_}new ${namer.isolateName}()$N');

      emitConvertToFastObjectFunction();
      for (String globalObject in Namer.reservedGlobalObjectNames) {
        mainBuffer.add('$globalObject = convertToFastObject($globalObject)$N');
      }
      if (DEBUG_FAST_OBJECTS) {
        ClassElement primitives =
            compiler.findHelper('Primitives');
        FunctionElement printHelper =
            compiler.lookupElementIn(
                primitives, 'printString');
        String printHelperName = namer.isolateAccess(printHelper);

        mainBuffer.add('''
// The following only works on V8 when run with option "--allow-natives-syntax".
if (typeof $printHelperName === "function") {
  $printHelperName("Size of global helper object: "
                   + String(Object.getOwnPropertyNames(H).length)
                   + ", fast properties " + %HasFastProperties(H));
  $printHelperName("Size of global platform object: "
                   + String(Object.getOwnPropertyNames(P).length)
                   + ", fast properties " + %HasFastProperties(P));
  $printHelperName("Size of global dart:html object: "
                   + String(Object.getOwnPropertyNames(W).length)
                   + ", fast properties " + %HasFastProperties(W));
  $printHelperName("Size of isolate properties object: "
                   + String(Object.getOwnPropertyNames(\$).length)
                   + ", fast properties " + %HasFastProperties(\$));
  $printHelperName("Size of constant object: "
                   + String(Object.getOwnPropertyNames(C).length)
                   + ", fast properties " + %HasFastProperties(C));
  var names = Object.getOwnPropertyNames(\$);
  for (var i = 0; i < names.length; i++) {
    $printHelperName("\$." + names[i]);
  }
}
''');
        for (String object in Namer.userGlobalObjects) {
        mainBuffer.add('''
if (typeof $printHelperName === "function") {
  $printHelperName("Size of $object: "
                   + String(Object.getOwnPropertyNames($object).length)
                   + ", fast properties " + %HasFastProperties($object));
}
''');
        }
      }

      emitMain(mainBuffer);
      jsAst.FunctionDeclaration precompiledFunctionAst =
          buildPrecompiledFunction();
      emitInitFunction(mainBuffer);
      if (!areAnyElementsDeferred) {
        mainBuffer.add('})()\n');
      } else {
        mainBuffer.add('\n');
      }
      compiler.assembledCode = mainBuffer.getText();
      outputSourceMap(compiler.assembledCode, '');

      mainBuffer.write(
          jsAst.prettyPrint(
              precompiledFunctionAst, compiler,
              allowVariableMinification: false).getText());

      compiler.outputProvider('', 'precompiled.js')
          ..add(mainBuffer.getText())
          ..close();

      emitDeferredCode();

    });
    return compiler.assembledCode;
  }

  CodeBuffer bufferForElement(Element element, CodeBuffer eagerBuffer) {
    Element owner = element.getLibrary();
    if (!element.isTopLevel() && !element.isNative()) {
      // For static (not top level) elements, record their code in a buffer
      // specific to the class. For now, not supported for native classes and
      // native elements.
      ClassElement cls =
          element.getEnclosingClassOrCompilationUnit().declaration;
      if (compiler.codegenWorld.instantiatedClasses.contains(cls)
          && !cls.isNative()) {
        owner = cls;
      }
    }
    if (owner == null) {
      compiler.internalErrorOnElement(element, 'Owner is null');
    }
    List<CodeBuffer> buffers = elementBuffers.putIfAbsent(
        owner, () => <CodeBuffer>[null, null]);
    bool deferred = isDeferred(element);
    int index = deferred ? 1 : 0;
    CodeBuffer buffer = buffers[index];
    if (buffer == null) {
      buffer = buffers[index] = new CodeBuffer();
    }
    return buffer;
  }

  /**
   * Returns the appropriate buffer for [constant].  If [constant] is
   * itself an instance of a deferred type (or built from constants
   * that are instances of deferred types) attempting to use
   * [constant] before the deferred type has been loaded will not
   * work, and [constant] itself must be deferred.
   */
  CodeBuffer bufferForConstant(Constant constant, CodeBuffer eagerBuffer) {
    var queue = new Queue()..add(constant);
    while (!queue.isEmpty) {
      constant = queue.removeFirst();
      if (isDeferred(constant.computeType(compiler).element)) {
        return deferredConstants;
      }
      queue.addAll(constant.getDependencies());
    }
    return eagerBuffer;
  }



  void emitDeferredCode() {
    if (deferredLibraries.isEmpty && deferredConstants.isEmpty) return;

    var oldClassesCollector = classesCollector;
    classesCollector = r"$$";

    // It does not make sense to defer constants if there are no
    // deferred elements.
    assert(!deferredLibraries.isEmpty);

    var buffer = new CodeBuffer()
        ..write(buildGeneratedBy())
        ..write('var old${namer.CURRENT_ISOLATE}$_='
                '$_${namer.CURRENT_ISOLATE}$N'
                // TODO(ahe): This defines a lot of properties on the
                // Isolate.prototype object.  We know this will turn it into a
                // slow object in V8, so instead we should do something similar
                // to Isolate.$finishIsolateConstructor.
                '${namer.CURRENT_ISOLATE}$_='
                '$_${namer.isolateName}.prototype$N$n'
                // The classesCollector object ($$).
                '$classesCollector$_=$_{};$n')
        ..write(getReflectionDataParser(classesCollector, namer))
        ..write('([$n')
        ..addBuffer(deferredLibraries)
        ..write('])$N');

    if (!deferredClasses.isEmpty) {
      buffer.write(
          '$finishClassesName($classesCollector,$_${namer.CURRENT_ISOLATE},'
          '$_$isolatePropertiesName)$N');
    }

    buffer.write(
        // Reset the classesCollector ($$).
        '$classesCollector$_=${_}null$N$n'
        '${namer.CURRENT_ISOLATE}$_=${_}old${namer.CURRENT_ISOLATE}$N');

    classesCollector = oldClassesCollector;

    if (!deferredConstants.isEmpty) {
      buffer.addBuffer(deferredConstants);
    }

    String code = buffer.getText();
    compiler.outputProvider('part', 'js')
      ..add(code)
      ..close();
    outputSourceMap(compiler.assembledCode, 'part');
  }

  String buildGeneratedBy() {
    var suffix = '';
    if (compiler.hasBuildId) suffix = ' version: ${compiler.buildId}';
    return '// Generated by dart2js, the Dart to JavaScript compiler$suffix.\n';
  }

  String buildSourceMap(CodeBuffer buffer, SourceFile compiledFile) {
    SourceMapBuilder sourceMapBuilder =
        new SourceMapBuilder(compiler.sourceMapUri);
    buffer.forEachSourceLocation(sourceMapBuilder.addMapping);
    return sourceMapBuilder.build(compiledFile);
  }

  void outputSourceMap(String code, String name) {
    if (!generateSourceMap) return;
    // Create a source file for the compilation output. This allows using
    // [:getLine:] to transform offsets to line numbers in [SourceMapBuilder].
    SourceFile compiledFile =
        new StringSourceFile(null, compiler.assembledCode);
    String sourceMap = buildSourceMap(mainBuffer, compiledFile);
    compiler.outputProvider(name, 'js.map')
        ..add(sourceMap)
        ..close();
  }

  bool isDeferred(Element element) {
    return compiler.deferredLoadTask.isDeferred(element);
  }

  bool get areAnyElementsDeferred {
    return compiler.deferredLoadTask.areAnyElementsDeferred;
  }
}
