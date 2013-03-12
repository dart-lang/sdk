// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/**
 * A function element that represents a closure call. The signature is copied
 * from the given element.
 */
class ClosureInvocationElement extends FunctionElementX {
  ClosureInvocationElement(SourceString name,
                           FunctionElement other)
      : super.from(name, other, other.enclosingElement),
        methodElement = other;

  isInstanceMember() => true;

  Element getOutermostEnclosingMemberOrTopLevel() => methodElement;

  /**
   * The [member] this invocation refers to.
   */
  Element methodElement;
}

/**
 * A convenient type alias for some functions that emit keyed values.
 */
typedef void DefineStubFunction(String invocationName, jsAst.Expression value);

/**
 * A data structure for collecting fragments of a class definition.
 */
class ClassBuilder {
  final List<jsAst.Property> properties = <jsAst.Property>[];

  // Has the same signature as [DefineStubFunction].
  void addProperty(String name, jsAst.Expression value) {
    properties.add(new jsAst.Property(js.string(name), value));
  }

  jsAst.Expression toObjectInitializer() {
    return new jsAst.ObjectInitializer(properties);
  }
}

/**
 * Generates the code for all used classes in the program. Static fields (even
 * in classes) are ignored, since they can be treated as non-class elements.
 *
 * The code for the containing (used) methods must exist in the [:universe:].
 */
class CodeEmitterTask extends CompilerTask {
  bool needsInheritFunction = false;
  bool needsDefineClass = false;
  bool needsClosureClass = false;
  bool needsLazyInitializer = false;
  final Namer namer;
  ConstantEmitter constantEmitter;
  NativeEmitter nativeEmitter;
  CodeBuffer mainBuffer;
  final CodeBuffer deferredBuffer = new CodeBuffer();
  /** Shorter access to [isolatePropertiesName]. Both here in the code, as
      well as in the generated code. */
  String isolateProperties;
  String classesCollector;
  final Set<ClassElement> neededClasses = new Set<ClassElement>();
  final List<ClassElement> regularClasses = <ClassElement>[];
  final List<ClassElement> deferredClasses = <ClassElement>[];
  final List<ClassElement> nativeClasses = <ClassElement>[];

  // TODO(ngeoffray): remove this field.
  Set<ClassElement> instantiatedClasses;

  final List<jsAst.Expression> boundClosures = <jsAst.Expression>[];

  JavaScriptBackend get backend => compiler.backend;

  String get _ => compiler.enableMinification ? "" : " ";
  String get n => compiler.enableMinification ? "" : "\n";
  String get N => compiler.enableMinification ? "\n" : ";\n";

  /**
   * A cache of closures that are used to closurize instance methods.
   * A closure is dynamically bound to the instance used when
   * closurized.
   */
  final Map<int, String> boundClosureCache;

  /**
   * A cache of closures that are used to closurize instance methods
   * of interceptors. These closures are dynamically bound to the
   * interceptor instance, and the actual receiver of the method.
   */
  final Map<int, String> interceptorClosureCache;

  /**
   * Raw ClassElement symbols occuring in is-checks and type assertions.  If the
   * program contains parameterized checks `x is Set<int>` and
   * `x is Set<String>` then the ClassElement `Set` will occur once in
   * [checkedClasses].
   */
  Set<ClassElement> checkedClasses;

  /**
   * Raw Typedef symbols occuring in is-checks and type assertions.  If the
   * program contains `x is F<int>` and `x is F<bool>` then the TypedefElement
   * `F` will occur once in [checkedTypedefs].
   */
  Set<TypedefElement> checkedTypedefs;

  final bool generateSourceMap;

  Iterable<ClassElement> cachedClassesUsingTypeVariableTests;

  Iterable<ClassElement> get classesUsingTypeVariableTests {
    if (cachedClassesUsingTypeVariableTests == null) {
      cachedClassesUsingTypeVariableTests = compiler.codegenWorld.isChecks
          .where((DartType t) => t is TypeVariableType)
          .map((TypeVariableType v) => v.element.getEnclosingClass())
          .toList();
    }
    return cachedClassesUsingTypeVariableTests;
  }

  CodeEmitterTask(Compiler compiler, Namer namer, this.generateSourceMap)
      : mainBuffer = new CodeBuffer(),
        this.namer = namer,
        boundClosureCache = new Map<int, String>(),
        interceptorClosureCache = new Map<int, String>(),
        constantEmitter = new ConstantEmitter(compiler, namer),
        super(compiler) {
    nativeEmitter = new NativeEmitter(this);
  }

  void addComment(String comment, CodeBuffer buffer) {
    buffer.write(jsAst.prettyPrint(js.comment(comment), compiler));
  }

  void computeRequiredTypeChecks() {
    assert(checkedClasses == null && checkedTypedefs == null);

    compiler.codegenWorld.addImplicitChecks(classesUsingTypeVariableTests);

    checkedClasses = new Set<ClassElement>();
    checkedTypedefs = new Set<TypedefElement>();
    compiler.codegenWorld.isChecks.forEach((DartType t) {
      if (t is InterfaceType) {
        checkedClasses.add(t.element);
      } else if (t is TypedefType) {
        checkedTypedefs.add(t.element);
      }
    });
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
  String get supportsProtoName
      => 'supportsProto';
  String get lazyInitializerName
      => '${namer.isolateName}.\$lazy';

  // Compact field specifications.  The format of the field specification is
  // <accessorName>:<fieldName><suffix> where the suffix and accessor name
  // prefix are optional.  The suffix directs the generation of getter and
  // setter methods.  Each of the getter and setter has two bits to determine
  // the calling convention.  Setter listed below, getter is similar.
  //
  //     00: no setter
  //     01: function(value) { this.field = value; }
  //     10: function(receiver, value) { receiver.field = value; }
  //     11: function(receiver, value) { this.field = value; }
  //
  // The suffix encodes 4 bits using three ASCII ranges of non-identifier
  // characters.
  static const FIELD_CODE_CHARACTERS = r"<=>?@{|}~%&'()*";
  static const NO_FIELD_CODE = 0;
  static const FIRST_FIELD_CODE = 1;
  static const RANGE1_FIRST = 0x3c;   //  <=>?@    encodes 1..5
  static const RANGE1_LAST = 0x40;
  static const RANGE2_FIRST = 0x7b;   //  {|}~     encodes 6..9
  static const RANGE2_LAST = 0x7e;
  static const RANGE3_FIRST = 0x25;   //  %&'()*+  encodes 10..16
  static const RANGE3_LAST = 0x2b;

  jsAst.FunctionDeclaration get generateAccessorFunction {
    const RANGE1_SIZE = RANGE1_LAST - RANGE1_FIRST + 1;
    const RANGE2_SIZE = RANGE2_LAST - RANGE2_FIRST + 1;
    const RANGE1_ADJUST = - (FIRST_FIELD_CODE - RANGE1_FIRST);
    const RANGE2_ADJUST = - (FIRST_FIELD_CODE + RANGE1_SIZE - RANGE2_FIRST);
    const RANGE3_ADJUST =
        - (FIRST_FIELD_CODE + RANGE1_SIZE + RANGE2_SIZE - RANGE3_FIRST);

    String receiverParamName = compiler.enableMinification ? "r" : "receiver";
    String valueParamName = compiler.enableMinification ? "v" : "value";

    // function generateAccessor(field, prototype) {
    jsAst.Fun fun = js.fun(['field', 'prototype'], [
      js['var len = field.length'],
      js['var code = field.charCodeAt(len - 1)'],
      js['code = ((code >= $RANGE1_FIRST) && (code <= $RANGE1_LAST))'
          '    ? code - $RANGE1_ADJUST'
          '    : ((code >= $RANGE2_FIRST) && (code <= $RANGE2_LAST))'
          '      ? code - $RANGE2_ADJUST'
          '      : ((code >= $RANGE3_FIRST) && (code <= $RANGE3_LAST))'
          '        ? code - $RANGE3_ADJUST'
          '        : $NO_FIELD_CODE'],

      // if (needsAccessor) {
      js.if_('code', [
        js['var getterCode = code & 3'],
        js['var setterCode = code >> 2'],
        js['var accessorName = field = field.substring(0, len - 1)'],

        js['var divider = field.indexOf(":")'],
        js.if_('divider > 0', [  // Colon never in first position.
          js['accessorName = field.substring(0, divider)'],
          js['field = field.substring(divider + 1)']
        ]),

        // if (needsGetter) {
        js.if_('getterCode', [
          js['var args = (getterCode & 2) ? "$receiverParamName" : ""'],
          js['var receiver = (getterCode & 1) ? "this" : "$receiverParamName"'],
          js['var body = "return " + receiver + "." + field'],
          js['prototype["${namer.getterPrefix}" + accessorName] = '
                 'new Function(args, body)']
        ]),

        // if (needsSetter) {
        js.if_('setterCode', [
          js['var args = (setterCode & 2)'
              '  ? "$receiverParamName,${_}$valueParamName"'
              '  : "$valueParamName"'],
          js['var receiver = (setterCode & 1) ? "this" : "$receiverParamName"'],
          js['var body = receiver + "." + field + "$_=$_$valueParamName"'],
          js['prototype["${namer.setterPrefix}" + accessorName] = '
                 'new Function(args, body)']
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

    // function(cls, fields, prototype) {
    var defineClass = js.fun(['cls', 'fields', 'prototype'], [
      js['var constructor'],

      // if (typeof fields == "function") {
      js.if_(js['typeof fields == "function"'], [
        js['constructor = fields']
      ], /* else */ [
        js['var str = "function " + cls + "("'],
        js['var body = ""'],

        // for (var i = 0; i < fields.length; i++) {
        js.for_(js['var i = 0'], js['i < fields.length'], js['i++'], [
          // if (i != 0) str += ", ";
          js.if_(js['i != 0'], js['str += ", "']),

          js['var field = fields[i]'],
          js['field = generateAccessor(field, prototype)'],
          js['str += field'],
          js['body += ("this." + field + " = " + field + ";\\n")']
        ]),

        js['str += (") {" + body + "}\\nreturn " + cls)'],

        js['constructor = (new Function(str))()']
      ]),

      js['constructor.prototype = prototype'],
      js['constructor.builtin\$cls = cls'],

      // return constructor;
      js.return_('constructor')
    ]);
    // Declare a function called "generateAccessor".  This is used in
    // defineClassFunction (it's a local declaration in init()).
    return [
        generateAccessorFunction,
        js['$generateAccessorHolder = generateAccessor'],
        new jsAst.FunctionDeclaration(
            new jsAst.VariableDeclaration('defineClass'), defineClass) ];
  }

  /** Needs defineClass to be defined. */
  List buildProtoSupportCheck() {
    // On Firefox and Webkit browsers we can manipulate the __proto__
    // directly. Opera claims to have __proto__ support, but it is buggy.
    // So we have to do more checks.
    // Opera bug was filed as DSK-370158, and fixed as CORE-47615
    // (http://my.opera.com/desktopteam/blog/2012/07/20/more-12-01-fixes).
    // If the browser does not support __proto__ we need to instantiate an
    // object with the correct (internal) prototype set up correctly, and then
    // copy the members.
    // TODO(8541): Remove this work around.

    return [
      js['var $supportsProtoName = false'],
      js['var tmp = (defineClass("c", ["f?"], {})).prototype'],

      js.if_(js['tmp.__proto__'], [
        js['tmp.__proto__ = {}'],
        js.if_(js[r'typeof tmp.get$f != "undefined"'],
               js['$supportsProtoName = true'])

      ])
    ];
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

    // function(collectedClasses,
    //          isolateProperties,
    //          existingIsolateProperties) {
    return js.fun(['collectedClasses', 'isolateProperties',
                   'existingIsolateProperties'], [
      js['var pendingClasses = {}'],

      js['var hasOwnProperty = Object.prototype.hasOwnProperty'],

      // for (var cls in collectedClasses) {
      js.forIn('cls', 'collectedClasses', [
        // if (hasOwnProperty.call(collectedClasses, cls)) {
        js.if_(js['hasOwnProperty.call(collectedClasses, cls)'], [
          js['var desc = collectedClasses[cls]'],

          /* The 'fields' are either a constructor function or a
           * string encoding fields, constructor and superclass.  Get
           * the superclass and the fields in the format
           * Super;field1,field2 from the null-string property on the
           * descriptor.
           */
          // var fields = desc[""], supr;
          js['var fields = desc[""], supr'],

          js.if_(js['typeof fields == "string"'], [
            js['var s = fields.split(";")'],
            js['supr = s[0]'],
            js['fields = s[1] == "" ? [] : s[1].split(",")'],
          ], /* else */ [
            js['supr = desc.super']
          ]),

          js['isolateProperties[cls] = defineClass(cls, fields, desc)'],

          // if (supr) pendingClasses[cls] = supr;
          js.if_(js['supr'], js['pendingClasses[cls] = supr'])
        ])
      ]),

      js['var finishedClasses = {}'],

      // function finishClass(cls) { ... }
      buildFinishClass(),

      // for (var cls in pendingClasses) finishClass(cls);
      js.forIn('cls', 'pendingClasses', js['finishClass']('cls'))
    ]);
  }

  jsAst.FunctionDeclaration buildFinishClass() {
    // function finishClass(cls) {
    jsAst.Fun fun = js.fun(['cls'], [

      // TODO(8540): Remove this work around.
      /* Opera does not support 'getOwnPropertyNames'. Therefore we use
         hasOwnProperty instead. */
      js['var hasOwnProperty = Object.prototype.hasOwnProperty'],

      // if (hasOwnProperty.call(finishedClasses, cls)) return;
      js.if_(js['hasOwnProperty.call(finishedClasses, cls)'],
             js.return_()),

      js['finishedClasses[cls] = true'],
      js['var superclass = pendingClasses[cls]'],

      /* The superclass is only false (empty string) for Dart's Object class. */
      js.if_(js['!superclass'], js.return_()),
      js['finishClass(superclass)'],
      js['var constructor = isolateProperties[cls]'],
      js['var superConstructor = isolateProperties[superclass]'],

      // if (!superConstructor)
      //   superConstructor = existingIsolateProperties[superclass];
      js.if_(js['superConstructor'].not,
             js['superConstructor'].assign(
                 js['existingIsolateProperties'][js['superclass']])),

      js['var prototype = constructor.prototype'],

      // if ($supportsProtoName) {
      js.if_(supportsProtoName, [
        js['prototype.__proto__ = superConstructor.prototype'],
        js['prototype.constructor = constructor'],

      ], /* else */ [
        // function tmp() {};
        new jsAst.FunctionDeclaration(
            new jsAst.VariableDeclaration('tmp'),
            js.fun([], [])),

        js['tmp.prototype = superConstructor.prototype'],
        js['var newPrototype = new tmp()'],

        js['constructor.prototype = newPrototype'],
        js['newPrototype.constructor = constructor'],

        // for (var member in prototype) {
        js.forIn('member', 'prototype', [
          /* Short version of: if (member == '') */
          // if (!member) continue;
          js.if_(js['!member'], new jsAst.Continue(null)),

          // if (hasOwnProperty.call(prototype, member)) {
          js.if_(js['hasOwnProperty.call(prototype, member)'], [
            js['newPrototype[member] = prototype[member]']
          ])
        ])

      ])
    ]);

    return new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration('finishClass'),
        fun);
  }

  jsAst.Fun get finishIsolateConstructorFunction {
    String isolate = namer.isolateName;
    // We replace the old Isolate function with a new one that initializes
    // all its field with the initial (and often final) value of all globals.
    // This has two advantages:
    //   1. the properties are in the object itself (thus avoiding to go through
    //      the prototype when looking up globals.
    //   2. a new isolate goes through a (usually well optimized) constructor
    //      function of the form: "function() { this.x = ...; this.y = ...; }".
    //
    // Example: If [isolateProperties] is an object containing: x = 3 and
    // A = function A() { /* constructor of class A. */ }, then we generate:
    // str = "{
    //   var isolateProperties = Isolate.$isolateProperties;
    //   this.x = isolateProperties.x;
    //   this.A = isolateProperties.A;
    // }";
    // which is then dynamically evaluated:
    //   var newIsolate = new Function(str);
    //
    // We also copy over old values like the prototype, and the
    // isolateProperties themselves.

    List copyFinishClasses = [];
    if (needsDefineClass) {
      copyFinishClasses.add(
          // newIsolate.$finishClasses = oldIsolate.$finishClasses;
          js['newIsolate'][finishClassesProperty].assign(
              js['oldIsolate'][finishClassesProperty]));
    }

    // function(oldIsolate) {
    return js.fun('oldIsolate', [
      js['var isolateProperties = oldIsolate.${namer.isolatePropertiesName}'],

      js[r'isolateProperties.$currentScript ='
              'typeof document == "object" ?'
              '(document.currentScript ||'
                     'document.scripts[document.scripts.length - 1]) :'
              'null'],

      js['var isolatePrototype = oldIsolate.prototype'],
      js['var str = "{\\n"'],
      js['str += '
             '"var properties = $isolate.${namer.isolatePropertiesName};\\n"'],
      js['var hasOwnProperty = Object.prototype.hasOwnProperty'],

      // for (var staticName in isolateProperties) {
      js.forIn('staticName', 'isolateProperties', [
        js.if_(js['hasOwnProperty.call(isolateProperties, staticName)'], [
          js['str += ("this." + staticName + "= properties." + staticName + '
                          '";\\n")']
        ])
      ]),

      js['str += "}\\n"'],

      js['var newIsolate = new Function(str)'],
      js['newIsolate.prototype = isolatePrototype'],
      js['isolatePrototype.constructor = newIsolate'],
      js['newIsolate.${namer.isolatePropertiesName} = isolateProperties'],
    ]..addAll(copyFinishClasses)
     ..addAll([

      // return newIsolate;
      js.return_('newIsolate')
    ]));
  }

  jsAst.Fun get lazyInitializerFunction {
    String isolate = namer.CURRENT_ISOLATE;

    // function(prototype, staticName, fieldName, getterName, lazyValue) {
    var parameters = <String>['prototype', 'staticName', 'fieldName',
                              'getterName', 'lazyValue'];
    return js.fun(parameters, [
      js['var getter = new Function("{ return $isolate." + fieldName + ";}")'],
    ]..addAll(addLazyInitializerLogic())
    );
  }

  List addLazyInitializerLogic() {
    String isolate = namer.CURRENT_ISOLATE;
    String cyclicThrow = namer.isolateAccess(backend.getCyclicThrowHelper());

    return [
      js['var sentinelUndefined = {}'],
      js['var sentinelInProgress = {}'],
      js['prototype[fieldName] = sentinelUndefined'],

      // prototype[getterName] = function() {
      js['prototype'][js['getterName']].assign(js.fun([], [
        js['var result = $isolate[fieldName]'],

        // try {
        js.try_([
          js.if_(js['result === sentinelUndefined'], [
            js['$isolate[fieldName] = sentinelInProgress'],

            // try {
            js.try_([
              js['result = $isolate[fieldName] = lazyValue()'],

            ], finallyPart: [
              // Use try-finally, not try-catch/throw as it destroys the
              // stack trace.

              // if (result === sentinelUndefined) {
              js.if_(js['result === sentinelUndefined'], [
                // if ($isolate[fieldName] === sentinelInProgress) {
                js.if_(js['$isolate[fieldName] === sentinelInProgress'], [
                  js['$isolate[fieldName] = null'],
                ])
              ])
            ])
          ], /* else */ [
            js.if_(js['result === sentinelInProgress'],
              js['$cyclicThrow(staticName)']
            )
          ]),

          // return result;
          js.return_('result')

        ], finallyPart: [
          js['$isolate[getterName] = getter']
        ])
      ]))
    ];
  }

  List buildDefineClassAndFinishClassFunctionsIfNecessary() {
    if (!needsDefineClass) return [];
    return defineClassFunction
    ..addAll(buildProtoSupportCheck())
    ..addAll([
      js[finishClassesName].assign(finishClassesFunction)
    ]);
  }

  List buildLazyInitializerFunctionIfNecessary() {
    if (!needsLazyInitializer) return [];

    // $lazyInitializerName = $lazyInitializerFunction
    return [js[lazyInitializerName].assign(lazyInitializerFunction)];
  }

  List buildFinishIsolateConstructor() {
    return [
      // $finishIsolateConstructorName = $finishIsolateConstructorFunction
      js[finishIsolateConstructorName].assign(finishIsolateConstructorFunction)
    ];
  }

  void emitFinishIsolateConstructorInvocation(CodeBuffer buffer) {
    String isolate = namer.isolateName;
    buffer.write("$isolate = $finishIsolateConstructorName($isolate)$N");
  }

  /**
   * Generate stubs to handle invocation of methods with optional
   * arguments.
   *
   * A method like [: foo([x]) :] may be invoked by the following
   * calls: [: foo(), foo(1), foo(x: 1) :]. See the sources of this
   * function for detailed examples.
   */
  void addParameterStub(FunctionElement member,
                        Selector selector,
                        DefineStubFunction defineStub,
                        Set<String> alreadyGenerated) {
    FunctionSignature parameters = member.computeSignature(compiler);
    int positionalArgumentCount = selector.positionalArgumentCount;
    if (positionalArgumentCount == parameters.parameterCount) {
      assert(selector.namedArgumentCount == 0);
      return;
    }
    if (parameters.optionalParametersAreNamed
        && selector.namedArgumentCount == parameters.optionalParameterCount) {
      // If the selector has the same number of named arguments as
      // the element, we don't need to add a stub. The call site will
      // hit the method directly.
      return;
    }
    ConstantHandler handler = compiler.constantHandler;
    List<SourceString> names = selector.getOrderedNamedArguments();

    String invocationName = namer.invocationName(selector);
    if (alreadyGenerated.contains(invocationName)) return;
    alreadyGenerated.add(invocationName);

    bool isInterceptedMethod = backend.isInterceptedMethod(member);

    // If the method is intercepted, we need to also pass
    // the actual receiver.
    int extraArgumentCount = isInterceptedMethod ? 1 : 0;
    // Use '$receiver' to avoid clashes with other parameter names. Using
    // '$receiver' works because [:namer.safeName:] used for getting parameter
    // names never returns a name beginning with a single '$'.
    String receiverArgumentName = r'$receiver';

    // The parameters that this stub takes.
    List<jsAst.Parameter> parametersBuffer =
        new List<jsAst.Parameter>(selector.argumentCount + extraArgumentCount);
    // The arguments that will be passed to the real method.
    List<jsAst.Expression> argumentsBuffer =
        new List<jsAst.Expression>(
            parameters.parameterCount + extraArgumentCount);

    int count = 0;
    if (isInterceptedMethod) {
      count++;
      parametersBuffer[0] = new jsAst.Parameter(receiverArgumentName);
      argumentsBuffer[0] = js[receiverArgumentName];
    }

    int indexOfLastOptionalArgumentInParameters = positionalArgumentCount - 1;
    TreeElements elements =
        compiler.enqueuer.resolution.getCachedElements(member);

    parameters.orderedForEachParameter((Element element) {
      String jsName = backend.namer.safeName(element.name.slowToString());
      assert(jsName != receiverArgumentName);
      int optionalParameterStart = positionalArgumentCount + extraArgumentCount;
      if (count < optionalParameterStart) {
        parametersBuffer[count] = new jsAst.Parameter(jsName);
        argumentsBuffer[count] = js[jsName];
      } else {
        int index = names.indexOf(element.name);
        if (index != -1) {
          indexOfLastOptionalArgumentInParameters = count;
          // The order of the named arguments is not the same as the
          // one in the real method (which is in Dart source order).
          argumentsBuffer[count] = js[jsName];
          parametersBuffer[optionalParameterStart + index] =
              new jsAst.Parameter(jsName);
        // Note that [elements] may be null for a synthesized [member].
        } else if (elements != null && elements.isParameterChecked(element)) {
          argumentsBuffer[count] = constantReference(SentinelConstant.SENTINEL);
        } else {
          Constant value = handler.initialVariableValues[element];
          if (value == null) {
            argumentsBuffer[count] = constantReference(new NullConstant());
          } else {
            if (!value.isNull()) {
              // If the value is the null constant, we should not pass it
              // down to the native method.
              indexOfLastOptionalArgumentInParameters = count;
            }
            argumentsBuffer[count] = constantReference(value);
          }
        }
      }
      count++;
    });

    List body;
    if (member.hasFixedBackendName()) {
      body = nativeEmitter.generateParameterStubStatements(
          member, invocationName, parametersBuffer, argumentsBuffer,
          indexOfLastOptionalArgumentInParameters);
    } else {
      body = [js.return_(js['this'][namer.getName(member)](argumentsBuffer))];
    }

    jsAst.Fun function = js.fun(parametersBuffer, body);

    defineStub(invocationName, function);
  }

  void addParameterStubs(FunctionElement member,
                         DefineStubFunction defineStub) {
    // We fill the lists depending on the selector. For example,
    // take method foo:
    //    foo(a, b, {c, d});
    //
    // We may have multiple ways of calling foo:
    // (1) foo(1, 2);
    // (2) foo(1, 2, c: 3);
    // (3) foo(1, 2, d: 4);
    // (4) foo(1, 2, c: 3, d: 4);
    // (5) foo(1, 2, d: 4, c: 3);
    //
    // What we generate at the call sites are:
    // (1) foo$2(1, 2);
    // (2) foo$3$c(1, 2, 3);
    // (3) foo$3$d(1, 2, 4);
    // (4) foo$4$c$d(1, 2, 3, 4);
    // (5) foo$4$c$d(1, 2, 3, 4);
    //
    // The stubs we generate are (expressed in Dart):
    // (1) foo$2(a, b) => foo$4$c$d(a, b, null, null)
    // (2) foo$3$c(a, b, c) => foo$4$c$d(a, b, c, null);
    // (3) foo$3$d(a, b, d) => foo$4$c$d(a, b, null, d);
    // (4) No stub generated, call is direct.
    // (5) No stub generated, call is direct.

    // Keep a cache of which stubs have already been generated, to
    // avoid duplicates. Note that even if selectors are
    // canonicalized, we would still need this cache: a typed selector
    // on A and a typed selector on B could yield the same stub.
    Set<String> generatedStubNames = new Set<String>();
    if (compiler.enabledFunctionApply
        && member.name == namer.closureInvocationSelectorName) {
      // If [Function.apply] is called, we pessimistically compile all
      // possible stubs for this closure.
      FunctionSignature signature = member.computeSignature(compiler);
      Set<Selector> selectors = signature.optionalParametersAreNamed
          ? computeNamedSelectors(signature, member)
          : computeOptionalSelectors(signature, member);
      for (Selector selector in selectors) {
        addParameterStub(member, selector, defineStub, generatedStubNames);
      }
    } else {
      Set<Selector> selectors = compiler.codegenWorld.invokedNames[member.name];
      if (selectors == null) return;
      for (Selector selector in selectors) {
        if (!selector.applies(member, compiler)) continue;
        addParameterStub(member, selector, defineStub, generatedStubNames);
      }
    }
  }

  /**
   * Compute the set of possible selectors in the presence of named
   * parameters.
   */
  Set<Selector> computeNamedSelectors(FunctionSignature signature,
                                      FunctionElement element) {
    Set<Selector> selectors = new Set<Selector>();
    // Add the selector that does not have any optional argument.
    selectors.add(new Selector(SelectorKind.CALL,
                               element.name,
                               element.getLibrary(),
                               signature.requiredParameterCount,
                               <SourceString>[]));

    // For each optional parameter, we iterator over the set of
    // already computed selectors and create new selectors with that
    // parameter now being passed.
    signature.forEachOptionalParameter((Element element) {
      Set<Selector> newSet = new Set<Selector>();
      selectors.forEach((Selector other) {
        List<SourceString> namedArguments = [element.name];
        namedArguments.addAll(other.namedArguments);
        newSet.add(new Selector(other.kind,
                                other.name,
                                other.library,
                                other.argumentCount + 1,
                                namedArguments));
      });
      selectors.addAll(newSet);
    });
    return selectors;
  }

  /**
   * Compute the set of possible selectors in the presence of optional
   * non-named parameters.
   */
  Set<Selector> computeOptionalSelectors(FunctionSignature signature,
                                         FunctionElement element) {
    Set<Selector> selectors = new Set<Selector>();
    // Add the selector that does not have any optional argument.
    selectors.add(new Selector(SelectorKind.CALL,
                               element.name,
                               element.getLibrary(),
                               signature.requiredParameterCount,
                               <SourceString>[]));

    // For each optional parameter, we increment the number of passed
    // argument.
    for (int i = 1; i <= signature.optionalParameterCount; i++) {
      selectors.add(new Selector(SelectorKind.CALL,
                                 element.name,
                                 element.getLibrary(),
                                 signature.requiredParameterCount + i,
                                 <SourceString>[]));
    }
    return selectors;
  }

  bool instanceFieldNeedsGetter(Element member) {
    assert(member.isField());
    if (fieldAccessNeverThrows(member)) return false;
    return compiler.codegenWorld.hasInvokedGetter(member, compiler);
  }

  bool instanceFieldNeedsSetter(Element member) {
    assert(member.isField());
    if (fieldAccessNeverThrows(member)) return false;
    return (!member.modifiers.isFinalOrConst())
        && compiler.codegenWorld.hasInvokedSetter(member, compiler);
  }

  // We never access a field in a closure (a captured variable) without knowing
  // that it is there.  Therefore we don't need to use a getter (that will throw
  // if the getter method is missing), but can always access the field directly.
  static bool fieldAccessNeverThrows(Element element) {
    return element is ClosureFieldElement;
  }

  String compiledFieldName(Element member) {
    assert(member.isField());
    return member.hasFixedBackendName()
        ? member.fixedBackendName()
        : namer.getName(member);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [member] must be a declaration element.
   */
  void addInstanceMember(Element member, ClassBuilder builder) {
    assert(invariant(member, member.isDeclaration));
    // TODO(floitsch): we don't need to deal with members of
    // uninstantiated classes, that have been overwritten by subclasses.

    if (member.isFunction()
        || member.isGenerativeConstructorBody()
        || member.isAccessor()) {
      if (member.isAbstract(compiler)) return;
      jsAst.Expression code = backend.generatedCode[member];
      if (code == null) return;
      builder.addProperty(namer.getName(member), code);
      code = backend.generatedBailoutCode[member];
      if (code != null) {
        builder.addProperty(namer.getBailoutName(member), code);
      }
      FunctionElement function = member;
      FunctionSignature parameters = function.computeSignature(compiler);
      if (!parameters.optionalParameters.isEmpty) {
        addParameterStubs(member, builder.addProperty);
      }
    } else if (!member.isField()) {
      compiler.internalError('unexpected kind: "${member.kind}"',
                             element: member);
    }
    emitExtraAccessors(member, builder);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [classElement] must be a declaration element.
   */
  void emitInstanceMembers(ClassElement classElement,
                           ClassBuilder builder) {
    assert(invariant(classElement, classElement.isDeclaration));

    void visitMember(ClassElement enclosing, Element member) {
      assert(invariant(classElement, member.isDeclaration));
      if (member.isInstanceMember()) {
        addInstanceMember(member, builder);
      }
    }

    // TODO(kasperl): We should make sure to only emit one version of
    // overridden methods. Right now, we rely on the ordering so the
    // methods pulled in from mixins are replaced with the members
    // from the class definition.

    // If the class is a native class, we have to add the instance
    // members defined in the non-native mixin applications used by
    // the class.
    visitNativeMixins(classElement, (MixinApplicationElement mixin) {
      mixin.forEachMember(
          visitMember,
          includeBackendMembers: true,
          includeSuperMembers: false);
    });

    classElement.implementation.forEachMember(
        visitMember,
        includeBackendMembers: true,
        includeSuperMembers: false);

    void generateIsTest(Element other) {
      jsAst.Expression code;
      if (other == compiler.objectClass && other != classElement) {
        // Avoid emitting [:$isObject:] on all classes but [Object].
        return;
      }
      if (nativeEmitter.requiresNativeIsCheck(other)) {
        code = js.fun([], [js.return_(true)]);
      } else {
        code = new jsAst.LiteralBool(true);
      }
      builder.addProperty(namer.operatorIs(other), code);
    }

    void generateSubstitution(Element other, {bool emitNull: false}) {
      RuntimeTypeInformation rti = backend.rti;
      // TODO(karlklose): support typedefs with variables.
      jsAst.Expression expression;
      bool needsNativeCheck = nativeEmitter.requiresNativeIsCheck(other);
      if (other.kind == ElementKind.CLASS) {
        String substitution = rti.getSupertypeSubstitution(classElement, other,
            alwaysGenerateFunction: true);
        if (substitution != null) {
          expression = new jsAst.LiteralExpression(substitution);
        } else if (emitNull || needsNativeCheck) {
          expression = new jsAst.LiteralNull();
        }
      }
      if (expression != null) {
        if (needsNativeCheck) {
          expression = js.fun([], js.return_(expression));
        }
        builder.addProperty(namer.substitutionName(other), expression);
      }
    }

    generateIsTestsOn(classElement, generateIsTest, generateSubstitution);

    if (identical(classElement, compiler.objectClass)
        && compiler.enabledNoSuchMethod) {
      // Emit the noSuchMethod handlers on the Object prototype now,
      // so that the code in the dynamicFunction helper can find
      // them. Note that this helper is invoked before analyzing the
      // full JS script.
      if (!nativeEmitter.handleNoSuchMethod) {
        emitNoSuchMethodHandlers(builder.addProperty);
      }
    }
  }

  void emitRuntimeTypeSupport(CodeBuffer buffer) {
    RuntimeTypeInformation rti = backend.rti;
    TypeChecks typeChecks = rti.getRequiredChecks();

    /// Classes that are not instantiated and native classes need a holder
    /// object for their checks, because there will be no class defined for
    /// them.
    bool needsHolder(ClassElement cls) {
      return !neededClasses.contains(cls) || cls.isNative() ||
        rti.isJsNative(cls);
    }

    /**
     * Generates a holder object if it is needed.  A holder is a JavaScript
     * object literal with a field [builtin$cls] that contains the name of the
     * class as a string (just like object constructors do).  The is-checks for
     * the class are are added to the holder object later.
     */
    void maybeGenerateHolder(ClassElement cls) {
      if (!needsHolder(cls)) return;
      String holder = namer.isolateAccess(cls);
      String name = namer.getName(cls);
      buffer.write('$holder$_=$_{builtin\$cls:$_"$name"');
      buffer.write('}$N');
    }

    // Create representation objects for classes that we do not have a class
    // definition for (because they are uninstantiated or native).
    for (ClassElement cls in rti.allArguments) {
      maybeGenerateHolder(cls);
    }

    // Add checks to the constructors of instantiated classes or to the created
    // holder object.
    for (ClassElement cls in typeChecks) {
      String holder = namer.isolateAccess(cls);
      for (ClassElement check in typeChecks[cls]) {
        buffer.write('$holder.${namer.operatorIs(check)}$_=${_}true$N');
        String body = rti.getSupertypeSubstitution(cls, check);
        if (body != null) {
          buffer.write('$holder.${namer.substitutionName(check)}$_=${_}$body$N');
        }
      };
    }
  }

  void visitNativeMixins(ClassElement classElement,
                         void visit(MixinApplicationElement mixinApplication)) {
    if (!classElement.isNative()) return;
    // Use recursion to make sure to visit the superclasses before the
    // subclasses. Once we start keeping track of the emitted fields
    // and members, we're going to want to visit these in the other
    // order so we get the most specialized definition first.
    void recurse(ClassElement cls) {
      if (cls == null || !cls.isMixinApplication) return;
      recurse(cls.superclass);
      assert(!cls.isNative());
      visit(cls);
    }
    recurse(classElement.superclass);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [classElement] must be a declaration element.
   */
  void visitClassFields(ClassElement classElement,
                        void addField(Element member,
                                      String name,
                                      String accessorName,
                                      bool needsGetter,
                                      bool needsSetter,
                                      bool needsCheckedSetter)) {
    assert(invariant(classElement, classElement.isDeclaration));
    // If the class is never instantiated we still need to set it up for
    // inheritance purposes, but we can simplify its JavaScript constructor.
    bool isInstantiated =
        compiler.codegenWorld.instantiatedClasses.contains(classElement);

    void visitField(ClassElement enclosingClass, Element member) {
      assert(invariant(classElement, member.isDeclaration));
      LibraryElement library = member.getLibrary();
      SourceString name = member.name;
      bool isPrivate = name.isPrivate();

      // Keep track of whether or not we're dealing with a field mixin
      // into a native class.
      bool isMixinNativeField =
          classElement.isNative() && enclosingClass.isMixinApplication;

      // See if we can dynamically create getters and setters.
      // We can only generate getters and setters for [classElement] since
      // the fields of super classes could be overwritten with getters or
      // setters.
      bool needsGetter = false;
      bool needsSetter = false;
      // We need to name shadowed fields differently, so they don't clash with
      // the non-shadowed field.
      bool isShadowed = false;
      if (isMixinNativeField || identical(enclosingClass, classElement)) {
        needsGetter = instanceFieldNeedsGetter(member);
        needsSetter = instanceFieldNeedsSetter(member);
      } else {
        isShadowed = classElement.isShadowedByField(member);
      }

      if ((isInstantiated && !enclosingClass.isNative())
          || needsGetter
          || needsSetter) {
        String accessorName = isShadowed
            ? namer.shadowedFieldName(member)
            : namer.getName(member);
        String fieldName = member.hasFixedBackendName()
            ? member.fixedBackendName()
            : (isMixinNativeField ? member.name.slowToString() : accessorName);
        bool needsCheckedSetter = false;
        if (needsSetter) {
          if (compiler.enableTypeAssertions
              && canGenerateCheckedSetter(member)) {
            needsCheckedSetter = true;
            needsSetter = false;
          }
        }
        // Getters and setters with suffixes will be generated dynamically.
        addField(member,
                 fieldName,
                 accessorName,
                 needsGetter,
                 needsSetter,
                 needsCheckedSetter);
      }
    }

    // TODO(kasperl): We should make sure to only emit one version of
    // overridden fields. Right now, we rely on the ordering so the
    // fields pulled in from mixins are replaced with the fields from
    // the class definition.

    // If the class is a native class, we have to add the fields
    // defined in the non-native mixin applications used by the class.
    visitNativeMixins(classElement, (MixinApplicationElement mixin) {
      mixin.forEachInstanceField(
          visitField,
          includeBackendMembers: true,
          includeSuperMembers: false);
    });

    // If a class is not instantiated then we add the field just so we can
    // generate the field getter/setter dynamically. Since this is only
    // allowed on fields that are in [classElement] we don't need to visit
    // superclasses for non-instantiated classes.
    classElement.implementation.forEachInstanceField(
        visitField,
        includeBackendMembers: true,
        includeSuperMembers: isInstantiated && !classElement.isNative());
  }

  void generateGetter(Element member, String fieldName, String accessorName,
                      ClassBuilder builder) {
    String getterName = namer.getterNameFromAccessorName(accessorName);
    String receiver = backend.isInterceptorClass(member.getEnclosingClass())
        ? 'receiver' : 'this';
    List<String> args = backend.isInterceptedMethod(member)
        ? ['receiver']
        : [];
    builder.addProperty(getterName,
        js.fun(args, js.return_(js[receiver][fieldName])));
  }

  void generateSetter(Element member, String fieldName, String accessorName,
                      ClassBuilder builder) {
    String setterName = namer.setterNameFromAccessorName(accessorName);
    String receiver = backend.isInterceptorClass(member.getEnclosingClass())
        ? 'receiver' : 'this';
    List<String> args = backend.isInterceptedMethod(member)
        ? ['receiver', 'v']
        : ['v'];
    builder.addProperty(setterName,
        js.fun(args, js[receiver][fieldName].assign('v')));
  }

  bool canGenerateCheckedSetter(Element member) {
    DartType type = member.computeType(compiler);
    if (type.element.isTypeVariable()
        || type.element == compiler.dynamicClass
        || type.element == compiler.objectClass) {
      // TODO(ngeoffray): Support type checks on type parameters.
      return false;
    }
    return true;
  }

  void generateCheckedSetter(Element member,
                             String fieldName,
                             String accessorName,
                             ClassBuilder builder) {
    assert(canGenerateCheckedSetter(member));
    DartType type = member.computeType(compiler);
    // TODO(ahe): Generate a dynamic type error here.
    if (type.element.isErroneous()) return;
    FunctionElement helperElement
        = backend.getCheckedModeHelper(type, typeCast: false);
    String helperName = namer.isolateAccess(helperElement);
    List<jsAst.Expression> arguments = <jsAst.Expression>[js['v']];
    if (helperElement.computeSignature(compiler).parameterCount != 1) {
      arguments.add(js.string(namer.operatorIs(type.element)));
    }

    String setterName = namer.setterNameFromAccessorName(accessorName);
    String receiver = backend.isInterceptorClass(member.getEnclosingClass())
        ? 'receiver' : 'this';
    List<String> args = backend.isInterceptedMethod(member)
        ? ['receiver', 'v']
        : ['v'];
    builder.addProperty(setterName,
        js.fun(args,
            js[receiver][fieldName].assign(js[helperName](arguments))));
  }

  void emitClassConstructor(ClassElement classElement, ClassBuilder builder) {
    /* Do nothing. */
  }

  void emitSuper(String superName, ClassBuilder builder) {
    /* Do nothing. */
  }

  void emitClassFields(ClassElement classElement,
                       ClassBuilder builder,
                       { String superClass: "",
                         bool classIsNative: false }) {
    String separator = '';
    StringBuffer buffer = new StringBuffer();
    if (!classIsNative) {
      buffer.write('$superClass;');
    }
    visitClassFields(classElement, (Element member,
                                    String name,
                                    String accessorName,
                                    bool needsGetter,
                                    bool needsSetter,
                                    bool needsCheckedSetter) {
      // Ignore needsCheckedSetter - that is handled below.
      bool needsAccessor = (needsGetter || needsSetter);
      // We need to output the fields for non-native classes so we can auto-
      // generate the constructor.  For native classes there are no
      // constructors, so we don't need the fields unless we are generating
      // accessors at runtime.
      if (!classIsNative || needsAccessor) {
        buffer.write(separator);
        separator = ',';
        if (!needsAccessor) {
          // Emit field for constructor generation.
          assert(!classIsNative);
          buffer.write(name);
        } else {
          // Emit (possibly renaming) field name so we can add accessors at
          // runtime.
          buffer.write(accessorName);
          if (name != accessorName) {
            buffer.write(':$name');
            // Only the native classes can have renaming accessors.
            assert(classIsNative);
          }

          int getterCode = 0;
          if (needsGetter) {
            // 01:  function() { return this.field; }
            // 10:  function(receiver) { return receiver.field; }
            // 11:  function(receiver) { return this.field; }
            getterCode += backend.fieldHasInterceptedGetter(member) ? 2 : 0;
            getterCode += backend.isInterceptorClass(classElement) ? 0 : 1;
            // TODO(sra): 'isInterceptorClass' might not be the correct test for
            // methods forced to use the interceptor convention because the
            // method's class was elsewhere mixed-in to an interceptor.
            assert(getterCode != 0);
          }
          int setterCode = 0;
          if (needsSetter) {
            // 01:  function(value) { this.field = value; }
            // 10:  function(receiver, value) { receiver.field = value; }
            // 11:  function(receiver, value) { this.field = value; }
            setterCode += backend.fieldHasInterceptedSetter(member) ? 2 : 0;
            setterCode += backend.isInterceptorClass(classElement) ? 0 : 1;
            assert(setterCode != 0);
          }
          int code = getterCode + (setterCode << 2);
          buffer.write(FIELD_CODE_CHARACTERS[code - FIRST_FIELD_CODE]);
        }
      }
    });

    String compactClassData = buffer.toString();
    if (compactClassData.length > 0) {
      builder.addProperty('', js.string(compactClassData));
    }
  }

  void emitClassGettersSetters(ClassElement classElement,
                               ClassBuilder builder) {

    visitClassFields(classElement, (Element member,
                                    String name,
                                    String accessorName,
                                    bool needsGetter,
                                    bool needsSetter,
                                    bool needsCheckedSetter) {
      compiler.withCurrentElement(member, () {
        if (needsCheckedSetter) {
          assert(!needsSetter);
          generateCheckedSetter(member, name, accessorName, builder);
        }
        if (!getterAndSetterCanBeImplementedByFieldSpec) {
          if (needsGetter) {
            generateGetter(member, name, accessorName, builder);
          }
          if (needsSetter) {
            generateSetter(member, name, accessorName, builder);
          }
        }
      });
    });
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [classElement] must be a declaration element.
   */
  void generateClass(ClassElement classElement, CodeBuffer buffer) {
    assert(invariant(classElement, classElement.isDeclaration));
    assert(invariant(classElement, !classElement.isNative()));

    needsDefineClass = true;
    String className = namer.getName(classElement);

    // Find the first non-native superclass.
    ClassElement superclass = classElement.superclass;
    while (superclass != null && superclass.isNative()) {
      superclass = superclass.superclass;
    }

    String superName = "";
    if (superclass != null) {
      superName = namer.getName(superclass);
    }

    ClassBuilder builder = new ClassBuilder();

    emitClassConstructor(classElement, builder);
    emitSuper(superName, builder);
    emitClassFields(classElement, builder,
                    superClass: superName, classIsNative: false);
    emitClassGettersSetters(classElement, builder);
    emitInstanceMembers(classElement, builder);

    jsAst.Expression init =
        js[classesCollector][className].assign(builder.toObjectInitializer());
    buffer.write(jsAst.prettyPrint(init, compiler));
    buffer.write('$N$n');
  }

  bool get getterAndSetterCanBeImplementedByFieldSpec => true;

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

  Iterable<Element> getTypedefChecksOn(DartType type) {
    bool isSubtype(TypedefElement typedef) {
      FunctionType typedefType =
          typedef.computeType(compiler).unalias(compiler);
      return compiler.types.isSubtype(type, typedefType);
    }
    return checkedTypedefs.where(isSubtype).toList()
        ..sort(Elements.compareByPosition);
  }

  /**
   * Generate "is tests" for [cls]: itself, and the "is tests" for the
   * classes it implements and type argument substitution functions for these
   * tests.   We don't need to add the "is tests" of the super class because
   * they will be inherited at runtime, but we may need to generate the
   * substitutions, because they may have changed.
   */
  void generateIsTestsOn(ClassElement cls,
                         void emitIsTest(Element element),
                         void emitSubstitution(Element element, {emitNull})) {
    if (checkedClasses.contains(cls)) {
      emitIsTest(cls);
      emitSubstitution(cls);
    }

    RuntimeTypeInformation rti = backend.rti;
    ClassElement superclass = cls.superclass;

    bool haveSameTypeVariables(ClassElement a, ClassElement b) {
      if (a.isClosure()) return true;
      return a.typeVariables == b.typeVariables;
    }

    if (superclass != null && superclass != compiler.objectClass &&
        !haveSameTypeVariables(cls, superclass)) {
      // We cannot inherit the generated substitutions, because the type
      // variable layout for this class is different.  Instead we generate
      // substitutions for all checks and make emitSubstitution a NOP for the
      // rest of this function.
      Set<ClassElement> emitted = new Set<ClassElement>();
      // TODO(karlklose): move the computation of these checks to
      // RuntimeTypeInformation.
      if (compiler.world.needsRti(cls)) {
        emitSubstitution(superclass, emitNull: true);
        emitted.add(superclass);
      }
      for (DartType supertype in cls.allSupertypes) {
        ClassElement superclass = supertype.element;
        if (classesUsingTypeVariableTests.contains(superclass)) {
          emitSubstitution(superclass, emitNull: true);
          emitted.add(superclass);
        }
        for (ClassElement check in checkedClasses) {
          if (supertype.element == check && !emitted.contains(check)) {
            // Generate substitution.  If no substitution is necessary, emit
            // [:null:] to overwrite a (possibly) existing substitution from the
            // super classes.
            emitSubstitution(check, emitNull: true);
            emitted.add(check);
          }
        }
      }
      void emitNothing(_, {emitNull}) {};
      emitSubstitution = emitNothing;
    }

    Set<Element> generated = new Set<Element>();
    // A class that defines a [:call:] method implicitly implements
    // [Function] and needs checks for all typedefs that are used in is-checks.
    if (checkedClasses.contains(compiler.functionClass) ||
        !checkedTypedefs.isEmpty) {
      FunctionElement call = cls.lookupLocalMember(Compiler.CALL_OPERATOR_NAME);
      if (call == null) {
        // If [cls] is a closure, it has a synthetic call operator method.
        call = cls.lookupBackendMember(Compiler.CALL_OPERATOR_NAME);
      }
      if (call != null) {
        generateInterfacesIsTests(compiler.functionClass,
                                  emitIsTest,
                                  emitSubstitution,
                                  generated);
        getTypedefChecksOn(call.computeType(compiler)).forEach(emitIsTest);
      }
    }

    for (DartType interfaceType in cls.interfaces) {
      generateInterfacesIsTests(interfaceType.element, emitIsTest,
                                emitSubstitution, generated);
    }

    // For native classes, we also have to run through their mixin
    // applications and make sure we deal with 'is' tests correctly
    // for those.
    visitNativeMixins(cls, (MixinApplicationElement mixin) {
      for (DartType interfaceType in mixin.interfaces) {
        ClassElement interfaceElement = interfaceType.element;
        generateInterfacesIsTests(interfaceType.element, emitIsTest,
                                  emitSubstitution, generated);
      }
    });
  }

  /**
   * Generate "is tests" where [cls] is being implemented.
   */
  void generateInterfacesIsTests(ClassElement cls,
                                 void emitIsTest(ClassElement element),
                                 void emitSubstitution(ClassElement element),
                                 Set<Element> alreadyGenerated) {
    void tryEmitTest(ClassElement check) {
      if (!alreadyGenerated.contains(check) && checkedClasses.contains(check)) {
        alreadyGenerated.add(check);
        emitIsTest(check);
        emitSubstitution(check);
      }
    };

    tryEmitTest(cls);

    for (DartType interfaceType in cls.interfaces) {
      Element element = interfaceType.element;
      tryEmitTest(element);
      generateInterfacesIsTests(element, emitIsTest, emitSubstitution,
                                alreadyGenerated);
    }

    // We need to also emit "is checks" for the superclass and its supertypes.
    ClassElement superclass = cls.superclass;
    if (superclass != null) {
      tryEmitTest(superclass);
      generateInterfacesIsTests(superclass, emitIsTest, emitSubstitution,
                                alreadyGenerated);
    }
  }

  /**
   * Return a function that returns true if its argument is a class
   * that needs to be emitted.
   */
  Function computeClassFilter() {
    Set<ClassElement> unneededClasses = new Set<ClassElement>();
    // The [Bool] class is not marked as abstract, but has a factory
    // constructor that always throws. We never need to emit it.
    unneededClasses.add(compiler.boolClass);

    // Go over specialized interceptors and then constants to know which
    // interceptors are needed.
    Set<ClassElement> needed = new Set<ClassElement>();
    backend.specializedGetInterceptors.forEach(
        (_, Collection<ClassElement> elements) {
          needed.addAll(elements);
        }
    );

    // Add interceptors referenced by constants.
    ConstantHandler handler = compiler.constantHandler;
    List<Constant> constants = handler.getConstantsForEmission();
    for (Constant constant in constants) {
      if (constant is InterceptorConstant) {
        needed.add(constant.dispatchedType.element);
      }
    }

    // Add unneeded interceptors to the [unneededClasses] set.
    for (ClassElement interceptor in backend.interceptedClasses) {
      if (!needed.contains(interceptor)
          && interceptor != compiler.objectClass) {
        unneededClasses.add(interceptor);
      }
    }

    return (ClassElement cls) => !unneededClasses.contains(cls);
  }

  void emitClosureClassIfNeeded(CodeBuffer buffer) {
    // The closure class could have become necessary because of the generation
    // of stubs.
    ClassElement closureClass = compiler.closureClass;
    if (needsClosureClass && !instantiatedClasses.contains(closureClass)) {
      generateClass(closureClass, bufferForElement(closureClass, buffer));
    }
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

  void emitStaticFunction(CodeBuffer buffer,
                          String name,
                          jsAst.Expression functionExpression) {
    jsAst.Expression assignment =
        js[isolateProperties][name].assign(functionExpression);
    buffer.write(jsAst.prettyPrint(assignment, compiler));
    buffer.write('$N$n');
  }

  void emitStaticFunctions(CodeBuffer eagerBuffer) {
    bool isStaticFunction(Element element) =>
        !element.isInstanceMember() && !element.isField();

    Iterable<Element> elements =
        backend.generatedCode.keys.where(isStaticFunction);
    Set<Element> pendingElementsWithBailouts =
        backend.generatedBailoutCode.keys
            .where(isStaticFunction)
            .toSet();

    for (Element element in Elements.sortedByPosition(elements)) {
      CodeBuffer buffer = bufferForElement(element, eagerBuffer);
      jsAst.Expression code = backend.generatedCode[element];
      emitStaticFunction(buffer, namer.getName(element), code);
      jsAst.Expression bailoutCode = backend.generatedBailoutCode[element];
      if (bailoutCode != null) {
        pendingElementsWithBailouts.remove(element);
        emitStaticFunction(buffer, namer.getBailoutName(element), bailoutCode);
      }
    }

    // Is it possible the primary function was inlined but the bailout was not?
    for (Element element in
             Elements.sortedByPosition(pendingElementsWithBailouts)) {
      CodeBuffer buffer = bufferForElement(element, eagerBuffer);
      jsAst.Expression bailoutCode = backend.generatedBailoutCode[element];
      emitStaticFunction(buffer, namer.getBailoutName(element), bailoutCode);
    }
  }

  void emitStaticFunctionGetters(CodeBuffer eagerBuffer) {
    Set<FunctionElement> functionsNeedingGetter =
        compiler.codegenWorld.staticFunctionsNeedingGetter;
    for (FunctionElement element in
             Elements.sortedByPosition(functionsNeedingGetter)) {
      CodeBuffer buffer = bufferForElement(element, eagerBuffer);

      // The static function does not have the correct name. Since
      // [addParameterStubs] use the name to create its stubs we simply
      // create a fake element with the correct name.
      // Note: the callElement will not have any enclosingElement.
      FunctionElement callElement =
          new ClosureInvocationElement(namer.closureInvocationSelectorName,
                                       element);
      String staticName = namer.getName(element);
      String invocationName = namer.instanceMethodName(callElement);
      String fieldAccess = '$isolateProperties.$staticName';
      buffer.write("$fieldAccess.$invocationName$_=$_$fieldAccess$N");

      addParameterStubs(callElement, (String name, jsAst.Expression value) {
        jsAst.Expression assignment =
            js[isolateProperties][staticName][name].assign(value);
        buffer.write(jsAst.prettyPrint(assignment.toStatement(), compiler));
        buffer.write('$N');
      });

      // If a static function is used as a closure we need to add its name
      // in case it is used in spawnFunction.
      String fieldName = namer.STATIC_CLOSURE_NAME_NAME;
      buffer.write('$fieldAccess.$fieldName$_=$_"$staticName"$N');
      getTypedefChecksOn(element.computeType(compiler)).forEach(
        (Element typedef) {
          String operator = namer.operatorIs(typedef);
          buffer.write('$fieldAccess.$operator$_=${_}true$N');
        }
      );
    }
  }

  void emitBoundClosureClassHeader(String mangledName,
                                   String superName,
                                   List<String> fieldNames,
                                   ClassBuilder builder) {
    builder.addProperty('',
        js.string("$superName;${fieldNames.join(',')}"));
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [member] must be a declaration element.
   */
  void emitDynamicFunctionGetter(FunctionElement member,
                                 DefineStubFunction defineStub) {
    assert(invariant(member, member.isDeclaration));
    // For every method that has the same name as a property-get we create a
    // getter that returns a bound closure. Say we have a class 'A' with method
    // 'foo' and somewhere in the code there is a dynamic property get of
    // 'foo'. Then we generate the following code (in pseudo Dart/JavaScript):
    //
    // class A {
    //    foo(x, y, z) { ... } // Original function.
    //    get foo { return new BoundClosure499(this, "foo"); }
    // }
    // class BoundClosure499 extends Closure {
    //   var self;
    //   BoundClosure499(this.self, this.name);
    //   $call3(x, y, z) { return self[name](x, y, z); }
    // }

    // TODO(floitsch): share the closure classes with other classes
    // if they share methods with the same signature. Currently we do this only
    // if there are no optional parameters. Closures with optional parameters
    // are more difficult to canonicalize because they would need to have the
    // same default values.

    bool hasOptionalParameters = member.optionalParameterCount(compiler) != 0;
    int parameterCount = member.parameterCount(compiler);

    Map<int, String> cache;
    String extraArg = null;
    // Intercepted methods take an extra parameter, which is the
    // receiver of the call.
    bool inInterceptor = backend.isInterceptedMethod(member);
    if (inInterceptor) {
      cache = interceptorClosureCache;
      extraArg = 'receiver';
    } else {
      cache = boundClosureCache;
    }
    List<String> fieldNames = compiler.enableMinification
        ? inInterceptor ? const ['a', 'b', 'c']
                        : const ['a', 'b']
        : inInterceptor ? const ['self', 'target', 'receiver']
                        : const ['self', 'target'];

    Iterable<Element> typedefChecks =
        getTypedefChecksOn(member.computeType(compiler));
    bool hasTypedefChecks = !typedefChecks.isEmpty;

    bool canBeShared = !hasOptionalParameters && !hasTypedefChecks;

    String closureClass = canBeShared ? cache[parameterCount] : null;
    if (closureClass == null) {
      // Either the class was not cached yet, or there are optional parameters.
      // Create a new closure class.
      String name;
      if (canBeShared) {
        if (inInterceptor) {
          name = 'BoundClosure\$i${parameterCount}';
        } else {
          name = 'BoundClosure\$${parameterCount}';
        }
      } else {
        name = 'Bound_${member.name.slowToString()}'
            '_${member.enclosingElement.name.slowToString()}';
      }

      ClassElement closureClassElement = new ClosureClassElement(
          null, new SourceString(name), compiler, member,
          member.getCompilationUnit());
      String mangledName = namer.getName(closureClassElement);
      String superName = namer.getName(closureClassElement.superclass);
      needsClosureClass = true;

      // Define the constructor with a name so that Object.toString can
      // find the class name of the closure class.
      ClassBuilder boundClosureBuilder = new ClassBuilder();
      emitBoundClosureClassHeader(
          mangledName, superName, fieldNames, boundClosureBuilder);
      // Now add the methods on the closure class. The instance method does not
      // have the correct name. Since [addParameterStubs] use the name to create
      // its stubs we simply create a fake element with the correct name.
      // Note: the callElement will not have any enclosingElement.
      FunctionElement callElement =
          new ClosureInvocationElement(namer.closureInvocationSelectorName,
                                       member);

      String invocationName = namer.instanceMethodName(callElement);

      List<String> parameters = <String>[];
      List<jsAst.Expression> arguments = <jsAst.Expression>[];
      if (inInterceptor) {
        arguments.add(js['this'][fieldNames[2]]);
      }
      for (int i = 0; i < parameterCount; i++) {
        String name = 'p$i';
        parameters.add(name);
        arguments.add(js[name]);
      }

      jsAst.Expression fun = js.fun(
          parameters,
          js.return_(
              js['this'][fieldNames[0]][js['this'][fieldNames[1]]](arguments)));
      boundClosureBuilder.addProperty(invocationName, fun);

      addParameterStubs(callElement, boundClosureBuilder.addProperty);
      typedefChecks.forEach((Element typedef) {
        String operator = namer.operatorIs(typedef);
        boundClosureBuilder.addProperty(operator, new jsAst.LiteralBool(true));
      });

      boundClosures.add(
          js[classesCollector][mangledName].assign(
              boundClosureBuilder.toObjectInitializer()));

      closureClass = namer.isolateAccess(closureClassElement);

      // Cache it.
      if (canBeShared) {
        cache[parameterCount] = closureClass;
      }
    }

    // And finally the getter.
    String getterName = namer.getterName(member);
    String targetName = namer.instanceMethodName(member);

    List<String> parameters = <String>[];
    List<jsAst.Expression> arguments = <jsAst.Expression>[];
    arguments.add(js['this']);
    arguments.add(js.string(targetName));
    if (inInterceptor) {
      parameters.add(extraArg);
      arguments.add(js[extraArg]);
    }

    jsAst.Expression getterFunction = js.fun(
        parameters,
        js.return_(js[closureClass].newWith(arguments)));

    defineStub(getterName, getterFunction);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [member] must be a declaration element.
   */
  void emitCallStubForGetter(Element member,
                             Set<Selector> selectors,
                             DefineStubFunction defineStub) {
    assert(invariant(member, member.isDeclaration));
    LibraryElement memberLibrary = member.getLibrary();
    // If the method is intercepted, the stub gets the
    // receiver explicitely and we need to pass it to the getter call.
    bool isInterceptedMethod = backend.isInterceptedMethod(member);

    const String receiverArgumentName = r'$receiver';

    jsAst.Expression buildGetter() {
      if (member.isGetter()) {
        String getterName = namer.getterName(member);
        return js['this'][getterName](
            isInterceptedMethod
                ? <jsAst.Expression>[js[receiverArgumentName]]
                : <jsAst.Expression>[]);
      } else {
        String fieldName = member.hasFixedBackendName()
            ? member.fixedBackendName()
            : namer.instanceFieldName(member);
        return js['this'][fieldName];
      }
    }

    // Two selectors may match but differ only in type.  To avoid generating
    // identical stubs for each we track untyped selectors which already have
    // stubs.
    Set<Selector> generatedSelectors = new Set<Selector>();

    for (Selector selector in selectors) {
      if (selector.applies(member, compiler)) {
        selector = selector.asUntyped;
        if (generatedSelectors.contains(selector)) continue;
        generatedSelectors.add(selector);

        String invocationName = namer.invocationName(selector);
        Selector callSelector = new Selector.callClosureFrom(selector);
        String closureCallName = namer.invocationName(callSelector);

        List<jsAst.Parameter> parameters = <jsAst.Parameter>[];
        List<jsAst.Expression> arguments = <jsAst.Expression>[];
        if (isInterceptedMethod) {
          parameters.add(new jsAst.Parameter(receiverArgumentName));
        }

        for (int i = 0; i < selector.argumentCount; i++) {
          String name = 'arg$i';
          parameters.add(new jsAst.Parameter(name));
          arguments.add(js[name]);
        }

        jsAst.Fun function = js.fun(
            parameters,
            js.return_(buildGetter()[closureCallName](arguments)));

        defineStub(invocationName, function);
      }
    }
  }

  void emitStaticNonFinalFieldInitializations(CodeBuffer buffer) {
    ConstantHandler handler = compiler.constantHandler;
    Iterable<VariableElement> staticNonFinalFields =
        handler.getStaticNonFinalFieldsForEmission();
    for (Element element in Elements.sortedByPosition(staticNonFinalFields)) {
      // [:interceptedNames:] is handled in [emitInterceptedNames].
      if (element == backend.interceptedNames) continue;
      compiler.withCurrentElement(element, () {
        Constant initialValue = handler.getInitialValueFor(element);
        jsAst.Expression init =
          js[isolateProperties][namer.getName(element)].assign(
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
        assert(backend.generatedBailoutCode[element] == null);
        jsAst.Expression code = backend.generatedCode[element];
        assert(code != null);
        // The code only computes the initial value. We build the lazy-check
        // here:
        //   lazyInitializer(prototype, 'name', fieldName, getterName, initial);
        // The name is used for error reporting. The 'initial' must be a
        // closure that constructs the initial value.
        List<jsAst.Expression> arguments = <jsAst.Expression>[];
        arguments.add(js[isolateProperties]);
        arguments.add(js.string(element.name.slowToString()));
        arguments.add(js.string(namer.getName(element)));
        arguments.add(js.string(namer.getLazyInitializerName(element)));
        arguments.add(code);
        jsAst.Expression getter = buildLazyInitializedGetter(element);
        if (getter != null) {
          arguments.add(getter);
        }
        jsAst.Expression init = js[lazyInitializerName](arguments);
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
    List<Constant> constants = handler.getConstantsForEmission();
    bool addedMakeConstantList = false;
    for (Constant constant in constants) {
      // No need to emit functions. We already did that.
      if (constant.isFunction()) continue;
      // Numbers, strings and booleans are currently always inlined.
      if (constant.isPrimitive()) continue;

      String name = namer.constantName(constant);
      // The name is null when the constant is already a JS constant.
      // TODO(floitsch): every constant should be registered, so that we can
      // share the ones that take up too much space (like some strings).
      if (name == null) continue;
      if (!addedMakeConstantList && constant.isList()) {
        addedMakeConstantList = true;
        emitMakeConstantList(eagerBuffer);
      }
      CodeBuffer buffer =
          bufferForElement(constant.computeType(compiler).element, eagerBuffer);
      jsAst.Expression init = js[isolateProperties][name].assign(
          constantInitializerExpression(constant));
      buffer.write(jsAst.prettyPrint(init, compiler));
      buffer.write('$N');
    }
  }

  void emitMakeConstantList(CodeBuffer buffer) {
    buffer.write(namer.isolateName);
    buffer.write(r'''.makeConstantList = function(list) {
  list.immutable$list = true;
  list.fixed$length = true;
  return list;
};
''');
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [member] must be a declaration element.
   */
  void emitExtraAccessors(Element member, ClassBuilder builder) {
    assert(invariant(member, member.isDeclaration));
    if (member.isGetter() || member.isField()) {
      Set<Selector> selectors = compiler.codegenWorld.invokedNames[member.name];
      if (selectors != null && !selectors.isEmpty) {
        emitCallStubForGetter(member, selectors, builder.addProperty);
      }
    } else if (member.isFunction()) {
      if (compiler.codegenWorld.hasInvokedGetter(member, compiler)) {
        emitDynamicFunctionGetter(member, builder.addProperty);
      }
    }
  }

  void emitNoSuchMethodHandlers(DefineStubFunction defineStub) {
    // Do not generate no such method handlers if there is no class.
    if (compiler.codegenWorld.instantiatedClasses.isEmpty) return;

    String noSuchMethodName = namer.publicInstanceMethodNameByArity(
        Compiler.NO_SUCH_METHOD, Compiler.NO_SUCH_METHOD_ARG_COUNT);

    Element createInvocationMirrorElement =
        compiler.findHelper(const SourceString("createInvocationMirror"));
    String createInvocationMirrorName =
        namer.getName(createInvocationMirrorElement);

    // Keep track of the JavaScript names we've already added so we
    // do not introduce duplicates (bad for code size).
    Set<String> addedJsNames = new Set<String>();

    jsAst.Expression generateMethod(String jsName, Selector selector) {
      // Values match JSInvocationMirror in js-helper library.
      int type = selector.invocationMirrorKind;
      String methodName = selector.invocationMirrorMemberName;
      List<jsAst.Parameter> parameters = <jsAst.Parameter>[];
      CodeBuffer args = new CodeBuffer();
      for (int i = 0; i < selector.argumentCount; i++) {
        parameters.add(new jsAst.Parameter('\$$i'));
      }

      List<jsAst.Expression> argNames =
          selector.getOrderedNamedArguments().map((SourceString name) =>
              js.string(name.slowToString())).toList();

      String internalName = namer.invocationMirrorInternalName(selector);

      String createInvocationMirror = namer.getName(
          compiler.createInvocationMirrorElement);

      assert(backend.isInterceptedName(Compiler.NO_SUCH_METHOD));
      jsAst.Expression expression = js['this.$noSuchMethodName'](
          [js['this'],
           js[namer.CURRENT_ISOLATE][createInvocationMirror]([
               js.string(methodName),
               js.string(internalName),
               type,
               new jsAst.ArrayInitializer.from(
                   parameters.map((param) => js[param.name]).toList()),
               new jsAst.ArrayInitializer.from(argNames)])]);
      parameters = backend.isInterceptedName(selector.name)
          ? ([new jsAst.Parameter('\$receiver')]..addAll(parameters))
          : parameters;
      return js.fun(parameters, js.return_(expression));
    }

    void addNoSuchMethodHandlers(SourceString ignore, Set<Selector> selectors) {
      // Cache the object class and type.
      ClassElement objectClass = compiler.objectClass;
      DartType objectType = objectClass.computeType(compiler);

      for (Selector selector in selectors) {
        // Introduce a helper function that determines if the given
        // class has a member that matches the current name and
        // selector (grabbed from the scope).
        bool hasMatchingMember(ClassElement holder) {
          Element element = holder.lookupSelector(selector);
          return (element != null)
              ? selector.applies(element, compiler)
              : false;
        }

        // If the selector is typed, we check to see if that type may
        // have a user-defined noSuchMethod implementation. If not, we
        // skip the selector altogether.

        // TODO(kasperl): This shouldn't depend on the internals of
        // the type mask. Move more of this code to the type mask.
        ClassElement receiverClass = objectClass;
        TypeMask mask = selector.mask;
        if (mask != null) {
          // If the mask is empty it doesn't contain a noSuchMethod
          // handler -- not even if it is nullable.
          if (mask.isEmpty) continue;
          receiverClass = mask.base.element;
        }

        // If the receiver class is guaranteed to have a member that
        // matches what we're looking for, there's no need to
        // introduce a noSuchMethod handler. It will never be called.
        //
        // As an example, consider this class hierarchy:
        //
        //                   A    <-- noSuchMethod
        //                  / \
        //                 C   B  <-- foo
        //
        // If we know we're calling foo on an object of type B we
        // don't have to worry about the noSuchMethod method in A
        // because objects of type B implement foo. On the other hand,
        // if we end up calling foo on something of type C we have to
        // add a handler for it.
        if (hasMatchingMember(receiverClass)) continue;

        // If the holders of all user-defined noSuchMethod
        // implementations that might be applicable to the receiver
        // type have a matching member for the current name and
        // selector, we avoid introducing a noSuchMethod handler.
        //
        // As an example, consider this class hierarchy:
        //
        //                       A    <-- foo
        //                      / \
        //   noSuchMethod -->  B   C  <-- bar
        //                     |   |
        //                     C   D  <-- noSuchMethod
        //
        // When calling foo on an object of type A, we know that the
        // implementations of noSuchMethod are in the classes B and D
        // that also (indirectly) implement foo, so we do not need a
        // handler for it.
        //
        // If we're calling bar on an object of type D, we don't need
        // the handler either because all objects of type D implement
        // bar through inheritance.
        //
        // If we're calling bar on an object of type A we do need the
        // handler because we may have to call B.noSuchMethod since B
        // does not implement bar.
        Iterable<ClassElement> holders =
            compiler.world.locateNoSuchMethodHolders(selector);
        if (holders.every(hasMatchingMember)) continue;
        String jsName = namer.invocationMirrorInternalName(selector);
        if (!addedJsNames.contains(jsName)) {
          jsAst.Expression method = generateMethod(jsName, selector);
          defineStub(jsName, method);
          addedJsNames.add(jsName);
        }
      }
    }

    compiler.codegenWorld.invokedNames.forEach(addNoSuchMethodHandlers);
    compiler.codegenWorld.invokedGetters.forEach(addNoSuchMethodHandlers);
    compiler.codegenWorld.invokedSetters.forEach(addNoSuchMethodHandlers);
  }

  String buildIsolateSetup(CodeBuffer buffer,
                           Element appMain,
                           Element isolateMain) {
    String mainAccess = "${namer.isolateAccess(appMain)}";
    String currentIsolate = "${namer.CURRENT_ISOLATE}";
    // Since we pass the closurized version of the main method to
    // the isolate method, we must make sure that it exists.
    if (!compiler.codegenWorld.staticFunctionsNeedingGetter.contains(appMain)) {
      Selector selector = new Selector.callClosure(0);
      String invocationName = namer.invocationName(selector);
      buffer.write("$mainAccess.$invocationName = $mainAccess$N");
    }
    return "${namer.isolateAccess(isolateMain)}($mainAccess)";
  }

  emitMain(CodeBuffer buffer) {
    if (compiler.isMockCompilation) return;
    Element main = compiler.mainApp.find(Compiler.MAIN);
    String mainCall = null;
    if (compiler.hasIsolateSupport()) {
      Element isolateMain =
        compiler.isolateHelperLibrary.find(Compiler.START_ROOT_ISOLATE);
      mainCall = buildIsolateSetup(buffer, main, isolateMain);
    } else {
      mainCall = '${namer.isolateAccess(main)}()';
    }
    addComment('BEGIN invoke [main].', buffer);
    buffer.write("""
if (typeof document !== "undefined" && document.readyState !== "complete") {
  document.addEventListener("readystatechange", function () {
    if (document.readyState == "complete") {
      if (typeof dartMainRunner === "function") {
        dartMainRunner(function() { ${mainCall}; });
      } else {
        ${mainCall};
      }
    }
  }, false);
} else {
  if (typeof dartMainRunner === "function") {
    dartMainRunner(function() { ${mainCall}; });
  } else {
    ${mainCall};
  }
}
""");
    addComment('END invoke [main].', buffer);
  }

  void emitGetInterceptorMethod(CodeBuffer buffer,
                                String key,
                                Collection<ClassElement> classes) {
    jsAst.Statement buildReturnInterceptor(ClassElement cls) {
      return js.return_(js[namer.isolateAccess(cls)]['prototype']);
    }

    jsAst.VariableUse receiver = js['receiver'];
    /**
     * Build a JavaScrit AST node for doing a type check on
     * [cls]. [cls] must be an interceptor class.
     */
    jsAst.Statement buildInterceptorCheck(ClassElement cls) {
      jsAst.Expression condition;
      assert(backend.isInterceptorClass(cls));
      if (cls == backend.jsBoolClass) {
        condition = receiver.typeof.equals(js.string('boolean'));
      } else if (cls == backend.jsIntClass ||
                 cls == backend.jsDoubleClass ||
                 cls == backend.jsNumberClass) {
        throw 'internal error';
      } else if (cls == backend.jsArrayClass ||
                 cls == backend.jsMutableArrayClass ||
                 cls == backend.jsFixedArrayClass ||
                 cls == backend.jsExtendableArrayClass) {
        condition = receiver['constructor'].equals('Array');
      } else if (cls == backend.jsStringClass) {
        condition = receiver.typeof.equals(js.string('string'));
      } else if (cls == backend.jsNullClass) {
        condition = receiver.equals(new jsAst.LiteralNull());
      } else if (cls == backend.jsFunctionClass) {
        condition = receiver.typeof.equals(js.string('function'));
      } else {
        throw 'internal error';
      }
      return js.if_(condition, buildReturnInterceptor(cls));
    }

    bool hasArray = false;
    bool hasBool = false;
    bool hasDouble = false;
    bool hasFunction = false;
    bool hasInt = false;
    bool hasNull = false;
    bool hasNumber = false;
    bool hasString = false;
    for (ClassElement cls in classes) {
      if (cls == backend.jsArrayClass ||
          cls == backend.jsMutableArrayClass ||
          cls == backend.jsFixedArrayClass ||
          cls == backend.jsExtendableArrayClass) hasArray = true;
      else if (cls == backend.jsBoolClass) hasBool = true;
      else if (cls == backend.jsDoubleClass) hasDouble = true;
      else if (cls == backend.jsFunctionClass) hasFunction = true;
      else if (cls == backend.jsIntClass) hasInt = true;
      else if (cls == backend.jsNullClass) hasNull = true;
      else if (cls == backend.jsNumberClass) hasNumber = true;
      else if (cls == backend.jsStringClass) hasString = true;
      else {
        assert(cls == compiler.objectClass);
      }
    }
    if (hasDouble) {
      hasNumber = true;
    }
    if (hasInt) hasNumber = true;

    jsAst.Block block = new jsAst.Block.empty();

    if (hasNumber) {
      jsAst.Statement whenNumber;

      /// Note: there are two number classes in play: Dart's [num],
      /// and JavaScript's Number (typeof receiver == 'number').  This
      /// is the fallback used when we have determined that receiver
      /// is a JavaScript Number.
      jsAst.Return returnNumberClass = buildReturnInterceptor(
          hasDouble ? backend.jsDoubleClass : backend.jsNumberClass);

      if (hasInt) {
        jsAst.Expression isInt = js['Math']['floor'](receiver).equals(receiver);
        whenNumber = js.block([
            js.if_(isInt, buildReturnInterceptor(backend.jsIntClass)),
            returnNumberClass]);
      } else {
        whenNumber = returnNumberClass;
      }
      block.statements.add(
          js.if_(receiver.typeof.equals(js.string('number')),
                 whenNumber));
    }

    if (hasString) {
      block.statements.add(buildInterceptorCheck(backend.jsStringClass));
    }
    if (hasNull) {
      block.statements.add(buildInterceptorCheck(backend.jsNullClass));
    } else {
      // Returning "undefined" here will provoke a JavaScript
      // TypeError which is later identified as a null-error by
      // [unwrapException] in js_helper.dart.
      block.statements.add(js.if_(receiver.equals(new jsAst.LiteralNull()),
                                  js.return_(js.undefined())));
    }
    if (hasFunction) {
      block.statements.add(buildInterceptorCheck(backend.jsFunctionClass));
    }
    if (hasBool) {
      block.statements.add(buildInterceptorCheck(backend.jsBoolClass));
    }
    // TODO(ahe): It might be faster to check for Array before
    // function and bool.
    if (hasArray) {
      block.statements.add(buildInterceptorCheck(backend.jsArrayClass));
    }
    block.statements.add(js.return_(receiver));

    buffer.write(jsAst.prettyPrint(
        js[isolateProperties][key].assign(js.fun(['receiver'], block)),
        compiler));
    buffer.write(N);
  }

  /**
   * Emit all versions of the [:getInterceptor:] method.
   */
  void emitGetInterceptorMethods(CodeBuffer buffer) {
    var specializedGetInterceptors = backend.specializedGetInterceptors;
    for (String name in specializedGetInterceptors.keys.toList()..sort()) {
      Collection<ClassElement> classes = specializedGetInterceptors[name];
      emitGetInterceptorMethod(buffer, name, classes);
    }
  }

  /**
   * Compute all the classes that must be emitted.
   */
  void computeNeededClasses() {
    instantiatedClasses =
        compiler.codegenWorld.instantiatedClasses.where(computeClassFilter())
            .toSet();

    // The set of classes that must be emitted are based on instantiated
    // classes.
    neededClasses.addAll(instantiatedClasses);

    // Then add all superclasses of these classes.
    for (ClassElement element in neededClasses.toList() /* copy */) {
      for (ClassElement superclass = element.superclass;
          superclass != null;
          superclass = superclass.superclass) {
        if (neededClasses.contains(superclass)) break;
        neededClasses.add(superclass);
      }
    }

    // Finally, sort the classes.
    List<ClassElement> sortedClasses = Elements.sortedByPosition(neededClasses);

    // If we need noSuchMethod support, we run through all needed
    // classes to figure out if we need the support on any native
    // class. If so, we let the native emitter deal with it.
    if (compiler.enabledNoSuchMethod) {
      SourceString noSuchMethodName = Compiler.NO_SUCH_METHOD;
      Selector noSuchMethodSelector = new Selector.noSuchMethod();
      for (ClassElement element in sortedClasses) {
        if (!element.isNative()) continue;
        Element member = element.lookupLocalMember(noSuchMethodName);
        if (member == null) continue;
        if (noSuchMethodSelector.applies(member, compiler)) {
          nativeEmitter.handleNoSuchMethod = true;
          break;
        }
      }
    }

    for (ClassElement element in sortedClasses) {
      if (element.isNative()) {
        // For now, native classes cannot be deferred.
        nativeClasses.add(element);
      } else if (isDeferred(element)) {
        deferredClasses.add(element);
      } else {
        regularClasses.add(element);
      }
    }
  }

  // Optimize performance critical one shot interceptors.
  jsAst.Statement tryOptimizeOneShotInterceptor(Selector selector,
                                                Set<ClassElement> classes) {
    jsAst.Expression isNumber(String variable) {
      return js[variable].typeof.equals(js.string('number'));
    }

    jsAst.Expression isNotObject(String variable) {
      return js[variable].typeof.equals(js.string('object')).not;
    }

    jsAst.Expression isInt(String variable) {
      jsAst.Expression receiver = js[variable];
      return isNumber(variable).binary('&&',
          js['Math']['floor'](receiver).equals(receiver));
    }

    jsAst.Expression tripleShiftZero(jsAst.Expression receiver) {
      return receiver.binary('>>>', js.toExpression(0));
    }

    if (selector.isOperator()) {
      String name = selector.name.stringValue;
      if (name == '==') {
        // Unfolds to:
        // [: if (receiver == null) return a0 == null;
        //    if (typeof receiver != 'object') {
        //      return a0 != null && receiver === a0;
        //    }
        // :].
        List<jsAst.Statement> body = <jsAst.Statement>[];
        body.add(js.if_(js['receiver'].equals(new jsAst.LiteralNull()),
                        js.return_(js['a0'].equals(new jsAst.LiteralNull()))));
        body.add(js.if_(
            isNotObject('receiver'),
            js.return_(js['a0'].equals(new jsAst.LiteralNull()).not.binary(
                '&&', js['receiver'].strictEquals(js['a0'])))));
        return new jsAst.Block(body);
      }
      if (!classes.contains(backend.jsIntClass)
          && !classes.contains(backend.jsNumberClass)
          && !classes.contains(backend.jsDoubleClass)) {
        return null;
      }
      if (selector.argumentCount == 1) {
        // The following operators do not map to a JavaScript
        // operator.
        if (name != '~/' && name != '<<' && name != '%' && name != '>>') {
          jsAst.Expression result = js['receiver'].binary(name, js['a0']);
          if (name == '&' || name == '|' || name == '^') {
            result = tripleShiftZero(result);
          }
          // Unfolds to:
          // [: if (typeof receiver == "number" && typeof a0 == "number")
          //      return receiver op a0;
          // :].
          return js.if_(
              isNumber('receiver').binary('&&', isNumber('a0')),
              js.return_(result));
        }
      } else if (name == 'unary-') {
        // operator~ does not map to a JavaScript operator.
        // Unfolds to:
        // [: if (typeof receiver == "number") return -receiver:].
        return js.if_(
            isNumber('receiver'),
            js.return_(new jsAst.Prefix('-', js['receiver'])));
      } else {
        assert(name == '~');
        return js.if_(
            isInt('receiver'),
            js.return_(
                tripleShiftZero(new jsAst.Prefix(name, js['receiver']))));
      }
    } else if (selector.isIndex() || selector.isIndexSet()) {
      // For an index operation, this code generates:
      //
      // [: if (receiver.constructor == Array || typeof receiver == "string") {
      //      if (a0 >>> 0 === a0 && a0 < receiver.length) {
      //        return receiver[a0];
      //      }
      //    }
      // :]
      //
      // For an index set operation, this code generates:
      //
      // [: if (receiver.constructor == Array && !receiver.immutable$list) {
      //      if (a0 >>> 0 === a0 && a0 < receiver.length) {
      //        return receiver[a0] = a1;
      //      }
      //    }
      // :]
      bool containsArray = classes.contains(backend.jsArrayClass);
      bool containsString = classes.contains(backend.jsStringClass);
      // The index set operator requires a check on its set value in
      // checked mode, so we don't optimize the interceptor if the
      // compiler has type assertions enabled.
      if (selector.isIndexSet()
          && (compiler.enableTypeAssertions || !containsArray)) {
        return null;
      }
      if (!containsArray && !containsString) {
        return null;
      }
      jsAst.Expression receiver = js['receiver'];
      jsAst.Expression arg0 = js['a0'];
      jsAst.Expression isIntAndAboveZero =
          arg0.binary('>>>', js.toExpression(0)).strictEquals(arg0);
      jsAst.Expression belowLength = arg0.binary('<', receiver['length']);
      jsAst.Expression arrayCheck = receiver['constructor'].equals('Array');

      if (selector.isIndex()) {
        jsAst.Expression stringCheck =
            receiver.typeof.equals(js.string('string'));
        jsAst.Expression typeCheck;
        if (containsArray) {
          if (containsString) {
            typeCheck = arrayCheck.binary('||', stringCheck);
          } else {
            typeCheck = arrayCheck;
          }
        } else {
          assert(containsString);
          typeCheck = stringCheck;
        }

        return js.if_(typeCheck,
                      js.if_(isIntAndAboveZero.binary('&&', belowLength),
                             js.return_(receiver[arg0])));
      } else {
        jsAst.Expression isImmutableArray = arrayCheck.binary(
            '&&', receiver[r'immutable$list'].not);
        return js.if_(isImmutableArray.binary(
                      '&&', isIntAndAboveZero.binary('&&', belowLength)),
                      js.return_(receiver[arg0].assign(js['a1'])));
      }
    }
    return null;
  }

  void emitOneShotInterceptors(CodeBuffer buffer) {
    List<String> names = backend.oneShotInterceptors.keys.toList();
    names.sort();
    for (String name in names) {
      Selector selector = backend.oneShotInterceptors[name];
      Set<ClassElement> classes =
          backend.getInterceptedClassesOn(selector.name);
      String getInterceptorName =
          namer.getInterceptorName(backend.getInterceptorMethod, classes);

      List<jsAst.Parameter> parameters = <jsAst.Parameter>[];
      List<jsAst.Expression> arguments = <jsAst.Expression>[];
      parameters.add(new jsAst.Parameter('receiver'));
      arguments.add(js['receiver']);

      if (selector.isSetter()) {
        parameters.add(new jsAst.Parameter('value'));
        arguments.add(js['value']);
      } else {
        for (int i = 0; i < selector.argumentCount; i++) {
          String argName = 'a$i';
          parameters.add(new jsAst.Parameter(argName));
          arguments.add(js[argName]);
        }
      }

      List<jsAst.Statement> body = <jsAst.Statement>[];
      jsAst.Statement optimizedPath =
          tryOptimizeOneShotInterceptor(selector, classes);
      if (optimizedPath != null) {
        body.add(optimizedPath);
      }

      String invocationName = backend.namer.invocationName(selector);
      body.add(js.return_(
          js[isolateProperties][getInterceptorName]('receiver')[invocationName](
              arguments)));

      jsAst.Fun function = js.fun(parameters, body);

      jsAst.PropertyAccess property =
          js[isolateProperties][name];

      buffer.write(jsAst.prettyPrint(property.assign(function), compiler));
      buffer.write(N);
    }
  }

  /**
   * If [:invokeOn:] has been compiled, emit all the possible selector names
   * that are intercepted into the [:interceptedNames:] top-level
   * variable. The implementation of [:invokeOn:] will use it to
   * determine whether it should call the method with an extra
   * parameter.
   */
  void emitInterceptedNames(CodeBuffer buffer) {
    if (!compiler.enabledInvokeOn) return;
    String name = backend.namer.getName(backend.interceptedNames);
    jsAst.PropertyAccess property = js[isolateProperties][name];

    int index = 0;
    List<jsAst.ArrayElement> elements = backend.usedInterceptors.map(
      (Selector selector) {
        jsAst.Literal str = js.string(namer.invocationName(selector));
        return new jsAst.ArrayElement(index++, str);
      }).toList();
    jsAst.ArrayInitializer array = new jsAst.ArrayInitializer(
        backend.usedInterceptors.length,
        elements);

    buffer.write(jsAst.prettyPrint(property.assign(array), compiler));
    buffer.write(N);
  }

  void emitInitFunction(CodeBuffer buffer) {
    jsAst.Fun fun = js.fun([], [
      js['$isolateProperties = {}'],
    ]
    ..addAll(buildDefineClassAndFinishClassFunctionsIfNecessary())
    ..addAll(buildLazyInitializerFunctionIfNecessary())
    ..addAll(buildFinishIsolateConstructor())
    );
    jsAst.FunctionDeclaration decl = new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration('init'), fun);
    buffer.write(jsAst.prettyPrint(decl, compiler).getText());
  }

  String assembleProgram() {
    measure(() {
      computeNeededClasses();

      // Compute the required type checks to know which classes need a
      // 'is$' method.
      computeRequiredTypeChecks();

      mainBuffer.add(GENERATED_BY);
      addComment(HOOKS_API_USAGE, mainBuffer);
      mainBuffer.add('function ${namer.isolateName}()$_{}\n');
      mainBuffer.add('init()$N$n');
      // Shorten the code by using [namer.CURRENT_ISOLATE] as temporary.
      isolateProperties = namer.CURRENT_ISOLATE;
      mainBuffer.add(
          'var $isolateProperties$_=$_$isolatePropertiesName$N');

      if (!regularClasses.isEmpty ||
          !deferredClasses.isEmpty ||
          !nativeClasses.isEmpty) {
        // Shorten the code by using "$$" as temporary.
        classesCollector = r"$$";
        mainBuffer.add('var $classesCollector$_=$_{}$N$n');
      }

      // Emit native classes on [nativeBuffer].  As a side-effect,
      // this will produce "bound closures" in [boundClosures].  The
      // bound closures are JS AST nodes that add properties to $$
      // [classesCollector].  The bound closures are not emitted until
      // we have emitted all other classes (native or not).
      final CodeBuffer nativeBuffer = new CodeBuffer();
      if (!nativeClasses.isEmpty) {
        addComment('Native classes', nativeBuffer);
        for (ClassElement element in nativeClasses) {
          nativeEmitter.generateNativeClass(element);
        }
      }
      nativeEmitter.assembleCode(nativeBuffer);

      // Might also create boundClosures.
      if (!regularClasses.isEmpty) {
        addComment('Classes', mainBuffer);
        for (ClassElement element in regularClasses) {
          generateClass(element, mainBuffer);
        }
      }

      // Might also create boundClosures.
      if (!deferredClasses.isEmpty) {
        emitDeferredPreambleWhenEmpty(deferredBuffer);
        deferredBuffer.add('\$\$$_=$_{}$N');

        for (ClassElement element in deferredClasses) {
          generateClass(element, deferredBuffer);
        }

        deferredBuffer.add('$finishClassesName(\$\$,'
                           '$_${namer.CURRENT_ISOLATE},'
                           '$_$isolatePropertiesName)$N');
        // Reset the map.
        deferredBuffer.add("\$\$$_=${_}null$N$n");
      }

      emitClosureClassIfNeeded(mainBuffer);

      addComment('Bound closures', mainBuffer);
      // Now that we have emitted all classes, we know all the bound
      // closures that will be needed.
      for (jsAst.Node node in boundClosures) {
        // TODO(ahe): Some of these can be deferred.
        mainBuffer.add(jsAst.prettyPrint(node, compiler));
        mainBuffer.add("$N$n");
      }

      emitFinishClassesInvocationIfNecessary(mainBuffer);

      // After this assignment we will produce invalid JavaScript code if we use
      // the classesCollector variable.
      classesCollector = 'classesCollector should not be used from now on';

      emitStaticFunctions(mainBuffer);
      emitStaticFunctionGetters(mainBuffer);

      emitRuntimeTypeSupport(mainBuffer);
      emitCompileTimeConstants(mainBuffer);
      // Static field initializations require the classes and compile-time
      // constants to be set up.
      emitStaticNonFinalFieldInitializations(mainBuffer);
      emitOneShotInterceptors(mainBuffer);
      emitInterceptedNames(mainBuffer);
      emitGetInterceptorMethods(mainBuffer);
      emitLazilyInitializedStaticFields(mainBuffer);

      isolateProperties = isolatePropertiesName;
      // The following code should not use the short-hand for the
      // initialStatics.
      mainBuffer.add('var ${namer.CURRENT_ISOLATE}$_=${_}null$N');

      emitFinishIsolateConstructorInvocation(mainBuffer);
      mainBuffer.add('var ${namer.CURRENT_ISOLATE}$_='
                     '${_}new ${namer.isolateName}()$N');

      mainBuffer.add(nativeBuffer);

      emitMain(mainBuffer);
      emitInitFunction(mainBuffer);
      compiler.assembledCode = mainBuffer.getText();
      outputSourceMap(mainBuffer, compiler.assembledCode, '');

      emitDeferredCode(deferredBuffer);

    });
    return compiler.assembledCode;
  }

  CodeBuffer bufferForElement(Element element, CodeBuffer eagerBuffer) {
    if (!isDeferred(element)) return eagerBuffer;
    emitDeferredPreambleWhenEmpty(deferredBuffer);
    return deferredBuffer;
  }

  void emitDeferredCode(CodeBuffer buffer) {
    if (buffer.isEmpty) return;

    buffer.write(n);

    buffer.write(
        '${namer.CURRENT_ISOLATE}$_=${_}old${namer.CURRENT_ISOLATE}$N');

    String code = buffer.getText();
    compiler.outputProvider('part', 'js')
      ..add(code)
      ..close();
    outputSourceMap(buffer, compiler.assembledCode, 'part');
  }

  void emitDeferredPreambleWhenEmpty(CodeBuffer buffer) {
    if (!buffer.isEmpty) return;

    buffer.write(GENERATED_BY);

    buffer.write('var old${namer.CURRENT_ISOLATE}$_='
                 '$_${namer.CURRENT_ISOLATE}$N');

    // TODO(ahe): This defines a lot of properties on the
    // Isolate.prototype object.  We know this will turn it into a
    // slow object in V8, so instead we should do something similar to
    // Isolate.$finishIsolateConstructor.
    buffer.write('${namer.CURRENT_ISOLATE}$_='
                 '$_${namer.isolateName}.prototype$N$n');
  }

  String buildSourceMap(CodeBuffer buffer, SourceFile compiledFile) {
    SourceMapBuilder sourceMapBuilder = new SourceMapBuilder();
    buffer.forEachSourceLocation(sourceMapBuilder.addMapping);
    return sourceMapBuilder.build(compiledFile);
  }

  void outputSourceMap(CodeBuffer buffer, String code, String name) {
    if (!generateSourceMap) return;
    SourceFile compiledFile = new SourceFile(null, compiler.assembledCode);
    String sourceMap = buildSourceMap(mainBuffer, compiledFile);
    compiler.outputProvider(name, 'js.map')
        ..add(sourceMap)
        ..close();
  }

  bool isDeferred(Element element) {
    return compiler.deferredLoadTask.isDeferred(element);
  }

  // TODO(ahe): Remove this when deferred loading is fully implemented.
  void warnNotImplemented(Element element, String message) {
    compiler.reportMessage(compiler.spanFromSpannable(element),
                           MessageKind.GENERIC.error({'text': message}),
                           api.Diagnostic.WARNING);
  }
}

const String GENERATED_BY = """
// Generated by dart2js, the Dart to JavaScript compiler.
""";
const String HOOKS_API_USAGE = """
// The code supports the following hooks:
// dartPrint(message)   - if this function is defined it is called
//                        instead of the Dart [print] method.
// dartMainRunner(main) - if this function is defined, the Dart [main]
//                        method will not be invoked directly.
//                        Instead, a closure that will invoke [main] is
//                        passed to [dartMainRunner].
""";
