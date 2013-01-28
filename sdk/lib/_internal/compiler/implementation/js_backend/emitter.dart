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
typedef void DefineStubFunction(String invocationName, js.Expression value);

/**
 * A data structure for collecting fragments of a class definition.
 */
class ClassBuilder {
  final List<js.Property> properties = <js.Property>[];

  // Has the same signature as [DefineStubFunction].
  void addProperty(String name, js.Expression value) {
    properties.add(new js.Property(js.string(name), value));
  }

  js.Expression toObjectInitializer() => new js.ObjectInitializer(properties);
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
  CodeBuffer boundClosureBuffer;
  CodeBuffer mainBuffer;
  /** Shorter access to [isolatePropertiesName]. Both here in the code, as
      well as in the generated code. */
  String isolateProperties;
  String classesCollector;
  Set<ClassElement> neededClasses;
  // TODO(ngeoffray): remove this field.
  Set<ClassElement> instantiatedClasses;

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

  CodeEmitterTask(Compiler compiler, Namer namer, this.generateSourceMap)
      : boundClosureBuffer = new CodeBuffer(),
        mainBuffer = new CodeBuffer(),
        this.namer = namer,
        boundClosureCache = new Map<int, String>(),
        interceptorClosureCache = new Map<int, String>(),
        constantEmitter = new ConstantEmitter(compiler, namer),
        super(compiler) {
    nativeEmitter = new NativeEmitter(this);
  }

  void computeRequiredTypeChecks() {
    assert(checkedClasses == null);
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

  js.Expression constantReference(Constant value) {
    return constantEmitter.reference(value);
  }

  js.Expression constantInitializerExpression(Constant value) {
    return constantEmitter.initializationExpression(value);
  }

  String get name => 'CodeEmitter';

  String get defineClassName
      => '${namer.isolateName}.\$defineClass';
  String get currentGenerateAccessorName
      => '${namer.CURRENT_ISOLATE}.\$generateAccessor';
  String get generateAccessorHolder
      => '$isolatePropertiesName.\$generateAccessor';
  String get finishClassesName
      => '${namer.isolateName}.\$finishClasses';
  String get finishIsolateConstructorName
      => '${namer.isolateName}.\$finishIsolateConstructor';
  String get pendingClassesName
      => '${namer.isolateName}.\$pendingClasses';
  String get isolatePropertiesName
      => '${namer.isolateName}.${namer.isolatePropertiesName}';
  String get supportsProtoName
      => 'supportsProto';
  String get lazyInitializerName
      => '${namer.isolateName}.\$lazy';

  // Property name suffixes.  If the accessors are renaming then the format
  // is <accessorName>:<fieldName><suffix>.  We use the suffix to know whether
  // to look for the ':' separator in order to avoid doing the indexOf operation
  // on every single property (they are quite rare).  None of these characters
  // are legal in an identifier and they are related by bit patterns.
  // setter          <          0x3c
  // both            =          0x3d
  // getter          >          0x3e
  // renaming setter |          0x7c
  // renaming both   }          0x7d
  // renaming getter ~          0x7e
  const SUFFIX_MASK = 0x3f;
  const FIRST_SUFFIX_CODE = 0x3c;
  const SETTER_CODE = 0x3c;
  const GETTER_SETTER_CODE = 0x3d;
  const GETTER_CODE = 0x3e;
  const RENAMING_FLAG = 0x40;
  String needsGetterCode(String variable) => '($variable & 3) > 0';
  String needsSetterCode(String variable) => '($variable & 2) == 0';
  String isRenaming(String variable) => '($variable & $RENAMING_FLAG) != 0';

  String get generateAccessorFunction {
    return """
function generateAccessor(field, prototype) {
  var len = field.length;
  var lastCharCode = field.charCodeAt(len - 1);
  var needsAccessor = (lastCharCode & $SUFFIX_MASK) >= $FIRST_SUFFIX_CODE;
  if (needsAccessor) {
    var needsGetter = ${needsGetterCode('lastCharCode')};
    var needsSetter = ${needsSetterCode('lastCharCode')};
    var renaming = ${isRenaming('lastCharCode')};
    var accessorName = field = field.substring(0, len - 1);
    if (renaming) {
      var divider = field.indexOf(":");
      accessorName = field.substring(0, divider);
      field = field.substring(divider + 1);
    }
    if (needsGetter) {
      var getterString = "return this." + field + ";";
      prototype["get\$" + accessorName] = new Function(getterString);
    }
    if (needsSetter) {
      var setterString = "this." + field + " = v;";
      prototype["set\$" + accessorName] = new Function("v", setterString);
    }
  }
  return field;
}""";
  }

  String get defineClassFunction {
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
    return """
function(cls, fields, prototype) {
  var constructor;
  if (typeof fields == 'function') {
    constructor = fields;
  } else {
    var str = "function " + cls + "(";
    var body = "";
    for (var i = 0; i < fields.length; i++) {
      if (i != 0) str += ", ";
      var field = fields[i];
      field = generateAccessor(field, prototype);
      str += field;
      body += "this." + field + " = " + field + ";\\n";
    }
    str += ") {" + body + "}\\n";
    str += "return " + cls + ";";
    constructor = new Function(str)();
  }
  constructor.prototype = prototype;
  constructor.builtin\$cls = cls;
  return constructor;
}""";
  }

  /** Needs defineClass to be defined. */
  String get protoSupportCheck {
    // On Firefox and Webkit browsers we can manipulate the __proto__
    // directly. Opera claims to have __proto__ support, but it is buggy.
    // So we have to do more checks.
    // Opera bug was filed as DSK-370158, and fixed as CORE-47615
    // (http://my.opera.com/desktopteam/blog/2012/07/20/more-12-01-fixes).
    // If the browser does not support __proto__ we need to instantiate an
    // object with the correct (internal) prototype set up correctly, and then
    // copy the members.

    return '''
var $supportsProtoName = false;
var tmp = $defineClassName('c', ['f?'], {}).prototype;
if (tmp.__proto__) {
  tmp.__proto__ = {};
  if (typeof tmp.get\$f !== 'undefined') $supportsProtoName = true;
}
''';
  }

  String get finishClassesFunction {
    // 'defineClass' does not require the classes to be constructed in order.
    // Classes are initially just stored in the 'pendingClasses' field.
    // 'finishClasses' takes all pending classes and sets up the prototype.
    // Once set up, the constructors prototype field satisfy:
    //  - it contains all (local) members.
    //  - its internal prototype (__proto__) points to the superclass'
    //    prototype field.
    //  - the prototype's constructor field points to the JavaScript
    //    constructor.
    // For engines where we have access to the '__proto__' we can manipulate
    // the object literal directly. For other engines we have to create a new
    // object and copy over the members.
    return '''
function(collectedClasses) {
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  for (var cls in collectedClasses) {
    if (hasOwnProperty.call(collectedClasses, cls)) {
      var desc = collectedClasses[cls];
'''/* The 'fields' are either a constructor function or a string encoding
      fields, constructor and superclass.  Get the superclass and the fields
      in the format Super;field1,field2 from the null-string property on the
      descriptor. */'''
      var fields = desc[''], supr;
      if (typeof fields == 'string') {
        var s = fields.split(';'); supr = s[0];
        fields = s[1] == '' ? [] : s[1].split(',');
      } else {
        supr = desc['super'];
      }
      $isolatePropertiesName[cls] = $defineClassName(cls, fields, desc);
      if (supr) $pendingClassesName[cls] = supr;
    }
  }
  var pendingClasses = $pendingClassesName;
'''/* FinishClasses can be called multiple times. This means that we need to
      clear the pendingClasses property. */'''
  $pendingClassesName = {};
  var finishedClasses = {};
  function finishClass(cls) {
'''/* Opera does not support 'getOwnPropertyNames'. Therefore we use
      hasOwnProperty instead. */'''
    var hasOwnProperty = Object.prototype.hasOwnProperty;
    if (hasOwnProperty.call(finishedClasses, cls)) return;
    finishedClasses[cls] = true;
    var superclass = pendingClasses[cls];
'''/* The superclass is only false (empty string) for Dart's Object class. */'''
    if (!superclass) return;
    finishClass(superclass);
    var constructor = $isolatePropertiesName[cls];
    var superConstructor = $isolatePropertiesName[superclass];
    var prototype = constructor.prototype;
    if ($supportsProtoName) {
      prototype.__proto__ = superConstructor.prototype;
      prototype.constructor = constructor;
    } else {
      function tmp() {};
      tmp.prototype = superConstructor.prototype;
      var newPrototype = new tmp();
      constructor.prototype = newPrototype;
      newPrototype.constructor = constructor;
      for (var member in prototype) {
        if (!member) continue;  '''/* Short version of: if (member == '') */'''
        if (hasOwnProperty.call(prototype, member)) {
          newPrototype[member] = prototype[member];
        }
      }
    }
  }
  for (var cls in pendingClasses) finishClass(cls);
}''';
  }

  String get finishIsolateConstructorFunction {
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
    return """function(oldIsolate) {
  var isolateProperties = oldIsolate.${namer.isolatePropertiesName};
  var isolatePrototype = oldIsolate.prototype;
  var str = "{\\n";
  str += "var properties = $isolate.${namer.isolatePropertiesName};\\n";
  for (var staticName in isolateProperties) {
    if (Object.prototype.hasOwnProperty.call(isolateProperties, staticName)) {
      str += "this." + staticName + "= properties." + staticName + ";\\n";
    }
  }
  str += "}\\n";
  var newIsolate = new Function(str);
  newIsolate.prototype = isolatePrototype;
  isolatePrototype.constructor = newIsolate;
  newIsolate.${namer.isolatePropertiesName} = isolateProperties;
  return newIsolate;
}""";
  }

  String get lazyInitializerFunction {
    String isolate = namer.CURRENT_ISOLATE;
    return """
function(prototype, staticName, fieldName, getterName, lazyValue) {
  var getter = new Function("{ return $isolate." + fieldName + ";}");
$lazyInitializerLogic
}""";
  }

  String get lazyInitializerLogic {
    String isolate = namer.CURRENT_ISOLATE;
    JavaScriptBackend backend = compiler.backend;
    String cyclicThrow = namer.isolateAccess(backend.cyclicThrowHelper);
    return """
  var sentinelUndefined = {};
  var sentinelInProgress = {};
  prototype[fieldName] = sentinelUndefined;
  prototype[getterName] = function() {
    var result = $isolate[fieldName];
    try {
      if (result === sentinelUndefined) {
        $isolate[fieldName] = sentinelInProgress;
        try {
          result = $isolate[fieldName] = lazyValue();
        } finally {
""" // Use try-finally, not try-catch/throw as it destroys the stack trace.
"""
          if (result === sentinelUndefined) {
            if ($isolate[fieldName] === sentinelInProgress) {
              $isolate[fieldName] = null;
            }
          }
        }
      } else if (result === sentinelInProgress) {
        $cyclicThrow(staticName);
      }
      return result;
    } finally {
      $isolate[getterName] = getter;
    }
  };""";
  }

  void addDefineClassAndFinishClassFunctionsIfNecessary(CodeBuffer buffer) {
    if (needsDefineClass) {
      // Declare function called generateAccessor.  This is used in
      // defineClassFunction (it's a local declaration in init()).
      buffer.add("$generateAccessorFunction$N");
      buffer.add("$generateAccessorHolder = generateAccessor$N");
      buffer.add("$defineClassName = $defineClassFunction$N");
      buffer.add(protoSupportCheck);
      buffer.add("$pendingClassesName = {}$N");
      buffer.add("$finishClassesName = $finishClassesFunction$N");
    }
  }

  void addLazyInitializerFunctionIfNecessary(CodeBuffer buffer) {
    if (needsLazyInitializer) {
      buffer.add("$lazyInitializerName = $lazyInitializerFunction$N");
    }
  }

  void emitFinishIsolateConstructor(CodeBuffer buffer) {
    String name = finishIsolateConstructorName;
    String value = finishIsolateConstructorFunction;
    buffer.add("$name = $value$N");
  }

  void emitFinishIsolateConstructorInvocation(CodeBuffer buffer) {
    String isolate = namer.isolateName;
    buffer.add("$isolate = $finishIsolateConstructorName($isolate)$N");
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

    JavaScriptBackend backend = compiler.backend;
    bool isInterceptorClass =
        backend.isInterceptorClass(member.getEnclosingClass());

    // If the method is in an interceptor class, we need to also pass
    // the actual receiver.
    int extraArgumentCount = isInterceptorClass ? 1 : 0;
    // Use '$receiver' to avoid clashes with other parameter names. Using
    // '$receiver' works because [:namer.safeName:] used for getting parameter
    // names never returns a name beginning with a single '$'.
    String receiverArgumentName = r'$receiver';

    // The parameters that this stub takes.
    List<js.Parameter> parametersBuffer =
        new List<js.Parameter>.fixedLength(
            selector.argumentCount + extraArgumentCount);
    // The arguments that will be passed to the real method.
    List<js.Expression> argumentsBuffer =
        new List<js.Expression>.fixedLength(
            parameters.parameterCount + extraArgumentCount);

    int count = 0;
    if (isInterceptorClass) {
      count++;
      parametersBuffer[0] = new js.Parameter(receiverArgumentName);
      argumentsBuffer[0] = new js.VariableUse(receiverArgumentName);
    }

    int indexOfLastOptionalArgumentInParameters = positionalArgumentCount - 1;
    TreeElements elements =
        compiler.enqueuer.resolution.getCachedElements(member);

    parameters.orderedForEachParameter((Element element) {
      String jsName = backend.namer.safeName(element.name.slowToString());
      assert(jsName != receiverArgumentName);
      int optionalParameterStart = positionalArgumentCount + extraArgumentCount;
      if (count < optionalParameterStart) {
        parametersBuffer[count] = new js.Parameter(jsName);
        argumentsBuffer[count] = new js.VariableUse(jsName);
      } else {
        int index = names.indexOf(element.name);
        if (index != -1) {
          indexOfLastOptionalArgumentInParameters = count;
          // The order of the named arguments is not the same as the
          // one in the real method (which is in Dart source order).
          argumentsBuffer[count] = new js.VariableUse(jsName);
          parametersBuffer[optionalParameterStart + index] =
              new js.Parameter(jsName);
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

    List<js.Statement> body;
    if (member.hasFixedBackendName()) {
      body = nativeEmitter.generateParameterStubStatements(
          member, invocationName, parametersBuffer, argumentsBuffer,
          indexOfLastOptionalArgumentInParameters);
    } else {
      body = <js.Statement>[
          new js.Return(
              new js.VariableUse('this')
                  .dot(namer.getName(member))
                  .callWith(argumentsBuffer))];
    }

    js.Fun function = new js.Fun(parametersBuffer, new js.Block(body));

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
    return compiler.codegenWorld.hasInvokedGetter(member, compiler);
  }

  bool instanceFieldNeedsSetter(Element member) {
    assert(member.isField());
    return (!member.modifiers.isFinalOrConst())
        && compiler.codegenWorld.hasInvokedSetter(member, compiler);
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
      js.Expression code = compiler.codegenWorld.generatedCode[member];
      if (code == null) return;
      builder.addProperty(namer.getName(member), code);
      code = compiler.codegenWorld.generatedBailoutCode[member];
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
    JavaScriptBackend backend = compiler.backend;
    if (classElement == backend.objectInterceptorClass) {
      emitInterceptorMethods(builder);
      // The ObjectInterceptor does not have any instance methods.
      return;
    }

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

    generateIsTestsOn(classElement, (Element other) {
      js.Expression code;
      if (compiler.objectClass == other) return;
      if (nativeEmitter.requiresNativeIsCheck(other)) {
        code = js.fun([], js.block1(js.return_(new js.LiteralBool(true))));
      } else {
        code = new js.LiteralBool(true);
      }
      builder.addProperty(namer.operatorIs(other), code);
    });

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

    if (backend.isInterceptorClass(classElement)) {
      // The operator== method in [:Object:] does not take the same
      // number of arguments as an intercepted method, therefore we
      // explicitely add one to all interceptor classes. Note that we
      // would not have do do that if all intercepted methods had
      // a calling convention where the receiver is the first
      // parameter.
      String name = backend.namer.publicInstanceMethodNameByArity(
          const SourceString('=='), 1);
      Function kind = (classElement == backend.jsNullClass)
          ? js.equals
          : js.strictEquals;
      builder.addProperty(name, js.fun(['receiver', 'a'],
          js.block1(js.return_(kind(js.use('receiver'), js.use('a'))))));
    }
  }

  void emitRuntimeClassesAndTests(CodeBuffer buffer) {
    JavaScriptBackend backend = compiler.backend;
    RuntimeTypeInformation rti = backend.rti;

    TypeChecks typeChecks = rti.computeRequiredChecks();

    bool needsHolder(ClassElement cls) {
      return !neededClasses.contains(cls) || cls.isNative() ||
          rti.isJsNative(cls);
    }

    void maybeGenerateHolder(ClassElement cls) {
      if (!needsHolder(cls)) return;

      String holder = namer.isolateAccess(cls);
      String name = namer.getName(cls);
      buffer.add("$holder$_=$_{builtin\$cls:$_'$name'");
      for (ClassElement check in typeChecks[cls]) {
        buffer.add(',$_${namer.operatorIs(check)}:${_}true');
      };
      buffer.add('}$N');
    }

    // Create representation objects for classes that we do not have a class
    // definition for (because they are uninstantiated or native).
    for (ClassElement cls in rti.allArguments) {
      maybeGenerateHolder(cls);
    }

    // Add checks to the constructors of instantiated classes.
    for (ClassElement cls in typeChecks) {
      if (needsHolder(cls)) {
        // We already emitted the is-checks in the object definition for this
        // class.
        continue;
      }
      String holder = namer.isolateAccess(cls);
      for (ClassElement check in typeChecks[cls]) {
        buffer.add('$holder.${namer.operatorIs(check)}$_=${_}true$N');
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
        if (needsSetter && compiler.enableTypeAssertions
            && canGenerateCheckedSetter(member)) {
          needsCheckedSetter = true;
          needsSetter = false;
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
    builder.addProperty(getterName,
        js.fun([], js.block1(js.return_(js.use('this').dot(fieldName)))));
  }

  void generateSetter(Element member, String fieldName, String accessorName,
                      ClassBuilder builder) {
    String setterName = namer.setterNameFromAccessorName(accessorName);
    builder.addProperty(setterName,
        js.fun(['v'],
            js.block1(
                new js.ExpressionStatement(
                    js.assign(js.use('this').dot(fieldName), js.use('v'))))));
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
    SourceString helper = compiler.backend.getCheckedModeHelper(type);
    FunctionElement helperElement = compiler.findHelper(helper);
    String helperName = namer.isolateAccess(helperElement);
    List<js.Expression> arguments = <js.Expression>[js.use('v')];
    if (helperElement.computeSignature(compiler).parameterCount != 1) {
      arguments.add(js.string(namer.operatorIs(type.element)));
    }

    String setterName = namer.setterNameFromAccessorName(accessorName);
    builder.addProperty(setterName,
        js.fun(['v'],
            js.block1(
                new js.ExpressionStatement(
                    js.assign(
                        js.use('this').dot(fieldName),
                        js.call(js.use(helperName), arguments))))));
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
                         bool classIsNative: false}) {
    bool isFirstField = true;
    StringBuffer buffer = new StringBuffer();
    if (!classIsNative) {
      buffer.add('$superClass;');
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
        // Emit correct commas.
        if (isFirstField) {
          isFirstField = false;
        } else {
          buffer.add(',');
        }
        int flag = 0;
        if (!needsAccessor) {
          // Emit field for constructor generation.
          assert(!classIsNative);
          buffer.add(name);
        } else {
          // Emit (possibly renaming) field name so we can add accessors at
          // runtime.
          buffer.add(accessorName);
          if (name != accessorName) {
            buffer.add(':$name');
            // Only the native classes can have renaming accessors.
            assert(classIsNative);
            flag = RENAMING_FLAG;
          }
        }
        if (needsGetter && needsSetter) {
          buffer.addCharCode(GETTER_SETTER_CODE + flag);
        } else if (needsGetter) {
          buffer.addCharCode(GETTER_CODE + flag);
        } else if (needsSetter) {
          buffer.addCharCode(SETTER_CODE + flag);
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
    if (classElement.isNative()) {
      nativeEmitter.generateNativeClass(classElement);
      return;
    } else {
      // TODO(ngeoffray): Instead of switching between buffer, we
      // should create code sections, and decide where to emit them at
      // the end.
      buffer = mainBuffer;
    }

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

    js.Expression init =
        js.assign(
            js.use(classesCollector).dot(className),
            builder.toObjectInitializer());
    buffer.add(js.prettyPrint(init, compiler));
    buffer.add('$N$n');
  }

  bool get getterAndSetterCanBeImplementedByFieldSpec => true;

  void emitInterceptorMethods(ClassBuilder builder) {
    JavaScriptBackend backend = compiler.backend;
    // Emit forwarders for the ObjectInterceptor class. We need to
    // emit all possible sends on intercepted methods.
    for (Selector selector in backend.usedInterceptors) {

      List<js.Parameter> parameters = <js.Parameter>[];
      List<js.Expression> arguments = <js.Expression>[];
      parameters.add(new js.Parameter('receiver'));

      String name = backend.namer.invocationName(selector);
      if (selector.isSetter()) {
        parameters.add(new js.Parameter('value'));
        arguments.add(new js.VariableUse('value'));
      } else {
        for (int i = 0; i < selector.argumentCount; i++) {
          String argName = 'a$i';
          parameters.add(new js.Parameter(argName));
          arguments.add(new js.VariableUse(argName));
        }
      }
      js.Fun function =
          new js.Fun(parameters,
              new js.Block(
                  <js.Statement>[
                      new js.Return(
                          new js.VariableUse('receiver')
                              .dot(name)
                              .callWith(arguments))]));
      builder.addProperty(name, function);
    }
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
   * classes it implements. We don't need to add the "is tests" of the
   * super class because they will be inherited at runtime.
   */
  void generateIsTestsOn(ClassElement cls,
                         void emitIsTest(Element element)) {
    if (checkedClasses.contains(cls)) {
      emitIsTest(cls);
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
                                  generated);
        getTypedefChecksOn(call.computeType(compiler)).forEach(emitIsTest);
      }
    }

    for (DartType interfaceType in cls.interfaces) {
      generateInterfacesIsTests(interfaceType.element, emitIsTest, generated);
    }

    // For native classes, we also have to run through their mixin
    // applications and make sure we deal with 'is' tests correctly
    // for those.
    visitNativeMixins(cls, (MixinApplicationElement mixin) {
      for (DartType interfaceType in mixin.interfaces) {
        ClassElement interfaceElement = interfaceType.element;
        generateInterfacesIsTests(interfaceType.element, emitIsTest, generated);
      }
    });
  }

  /**
   * Generate "is tests" where [cls] is being implemented.
   */
  void generateInterfacesIsTests(ClassElement cls,
                                 void emitIsTest(ClassElement element),
                                 Set<Element> alreadyGenerated) {
    void tryEmitTest(ClassElement cls) {
      if (!alreadyGenerated.contains(cls) && checkedClasses.contains(cls)) {
        alreadyGenerated.add(cls);
        emitIsTest(cls);
      }
    };

    tryEmitTest(cls);

    for (DartType interfaceType in cls.interfaces) {
      Element element = interfaceType.element;
      tryEmitTest(element);
      generateInterfacesIsTests(element, emitIsTest, alreadyGenerated);
    }

    // We need to also emit "is checks" for the superclass and its supertypes.
    ClassElement superclass = cls.superclass;
    if (superclass != null) {
      tryEmitTest(superclass);
      generateInterfacesIsTests(superclass, emitIsTest, alreadyGenerated);
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

    JavaScriptBackend backend = compiler.backend;

    // Go over specialized interceptors and then constants to know which
    // interceptors are needed.
    Set<ClassElement> needed = new Set<ClassElement>();
    backend.specializedGetInterceptors.forEach(
        (_, Collection<ClassElement> elements) {
          needed.addAll(elements);
        }
    );

    ConstantHandler handler = compiler.constantHandler;
    List<Constant> constants = handler.getConstantsForEmission();
    for (Constant constant in constants) {
      if (constant is ConstructedConstant) {
        Element element = constant.computeType(compiler).element;
        if (backend.isInterceptorClass(element)) {
          needed.add(element);
        }
      }
    }

    // Add unneeded interceptors to the [unneededClasses] set.
    for (ClassElement interceptor in backend.interceptedClasses.keys) {
      if (!needed.contains(interceptor)) {
        unneededClasses.add(interceptor);
      }
    }

    return (ClassElement cls) => !unneededClasses.contains(cls);
  }

  void emitClasses(CodeBuffer buffer) {
    // Compute the required type checks to know which classes need a
    // 'is$' method.
    computeRequiredTypeChecks();
    List<ClassElement> sortedClasses =
        new List<ClassElement>.from(neededClasses);
    sortedClasses.sort((ClassElement class1, ClassElement class2) {
      // We sort by the ids of the classes. There is no guarantee that these
      // ids are meaningful (or even deterministic), but in the current
      // implementation they are increasing within a source file.
      return class1.id - class2.id;
    });

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
      generateClass(element, buffer);
    }

    // The closure class could have become necessary because of the generation
    // of stubs.
    ClassElement closureClass = compiler.closureClass;
    if (needsClosureClass && !instantiatedClasses.contains(closureClass)) {
      generateClass(closureClass, buffer);
    }
  }

  void emitFinishClassesInvocationIfNecessary(CodeBuffer buffer) {
    if (needsDefineClass) {
      buffer.add("$finishClassesName($classesCollector)$N");
      // Reset the map.
      buffer.add("$classesCollector$_=$_{}$N");
    }
  }

  void emitStaticFunction(CodeBuffer buffer,
                          String name,
                          js.Expression functionExpression) {
    js.Expression assignment =
        js.assign(js.use(isolateProperties).dot(name), functionExpression);
    buffer.add(js.prettyPrint(assignment, compiler));
    buffer.add('$N$n');
  }

  void emitStaticFunctions(CodeBuffer buffer) {
    bool isStaticFunction(Element element) =>
        !element.isInstanceMember() && !element.isField();

    Iterable<Element> elements =
        compiler.codegenWorld.generatedCode.keys.where(isStaticFunction);
    Set<Element> pendingElementsWithBailouts =
        compiler.codegenWorld.generatedBailoutCode.keys
            .where(isStaticFunction)
            .toSet();

    for (Element element in Elements.sortedByPosition(elements)) {
      js.Expression code = compiler.codegenWorld.generatedCode[element];
      emitStaticFunction(buffer, namer.getName(element), code);
      js.Expression bailoutCode =
          compiler.codegenWorld.generatedBailoutCode[element];
      if (bailoutCode != null) {
        pendingElementsWithBailouts.remove(element);
        emitStaticFunction(buffer, namer.getBailoutName(element), bailoutCode);
      }
    }

    // Is it possible the primary function was inlined but the bailout was not?
    for (Element element in
             Elements.sortedByPosition(pendingElementsWithBailouts)) {
      js.Expression bailoutCode =
          compiler.codegenWorld.generatedBailoutCode[element];
      emitStaticFunction(buffer, namer.getBailoutName(element), bailoutCode);
    }
  }

  void emitStaticFunctionGetters(CodeBuffer buffer) {
    Set<FunctionElement> functionsNeedingGetter =
        compiler.codegenWorld.staticFunctionsNeedingGetter;
    for (FunctionElement element in
             Elements.sortedByPosition(functionsNeedingGetter)) {
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
      buffer.add("$fieldAccess.$invocationName$_=$_$fieldAccess$N");

      addParameterStubs(callElement, (String name, js.Expression value) {
        js.Expression assignment =
            js.assign(
                js.use(isolateProperties).dot(staticName).dot(name),
                value);
        buffer.add(
            js.prettyPrint(new js.ExpressionStatement(assignment), compiler));
        buffer.add('$N');
      });

      // If a static function is used as a closure we need to add its name
      // in case it is used in spawnFunction.
      String fieldName = namer.STATIC_CLOSURE_NAME_NAME;
      buffer.add('$fieldAccess.$fieldName$_=$_"$staticName"$N');
      getTypedefChecksOn(element.computeType(compiler)).forEach(
        (Element typedef) {
          String operator = namer.operatorIs(typedef);
          buffer.add('$fieldAccess.$operator$_=${_}true$N');
        }
      );
    }
  }

  void emitBoundClosureClassHeader(String mangledName,
                                   String superName,
                                   List<String> fieldNames,
                                   ClassBuilder builder) {
    builder.addProperty('',
        js.string("$superName;${Strings.join(fieldNames,',')}"));
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
    // Methods on interceptor classes take an extra parameter, which is the
    // actual receiver of the call.
    JavaScriptBackend backend = compiler.backend;
    bool inInterceptor = backend.isInterceptorClass(member.getEnclosingClass());
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
      SourceString name = const SourceString("BoundClosure");
      ClassElement closureClassElement = new ClosureClassElement(
          name, compiler, member, member.getCompilationUnit());
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

      List<js.Parameter> parameters = <js.Parameter>[];
      List<js.Expression> arguments = <js.Expression>[];
      if (inInterceptor) {
        arguments.add(new js.This().dot(fieldNames[2]));
      }
      for (int i = 0; i < parameterCount; i++) {
        String name = 'p$i';
        parameters.add(new js.Parameter(name));
        arguments.add(new js.VariableUse(name));
      }

      js.Expression fun =
          new js.Fun(parameters,
              new js.Block(
                  <js.Statement>[
                      new js.Return(
                          new js.PropertyAccess(
                              new js.This().dot(fieldNames[0]),
                              new js.This().dot(fieldNames[1]))
                          .callWith(arguments))]));
      boundClosureBuilder.addProperty(invocationName, fun);

      addParameterStubs(callElement, boundClosureBuilder.addProperty);
      typedefChecks.forEach((Element typedef) {
        String operator = namer.operatorIs(typedef);
        boundClosureBuilder.addProperty(operator, new js.LiteralBool(true));
      });

      js.Expression init =
          js.assign(
              js.use(classesCollector).dot(mangledName),
              boundClosureBuilder.toObjectInitializer());
      boundClosureBuffer.add(js.prettyPrint(init, compiler));
      boundClosureBuffer.add("$N");

      closureClass = namer.isolateAccess(closureClassElement);

      // Cache it.
      if (canBeShared) {
        cache[parameterCount] = closureClass;
      }
    }

    // And finally the getter.
    String getterName = namer.getterName(member);
    String targetName = namer.instanceMethodName(member);

    List<js.Parameter> parameters = <js.Parameter>[];
    List<js.Expression> arguments = <js.Expression>[];
    arguments.add(new js.This());
    arguments.add(js.string(targetName));
    if (inInterceptor) {
      parameters.add(new js.Parameter(extraArg));
      arguments.add(new js.VariableUse(extraArg));
    }

    js.Expression getterFunction =
        new js.Fun(parameters,
            new js.Block(
                <js.Statement>[
                    new js.Return(
                        new js.New(
                            new js.VariableUse(closureClass),
                            arguments))]));

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
    JavaScriptBackend backend = compiler.backend;
    // If the class is an interceptor class, the stub gets the
    // receiver explicitely and we need to pass it to the getter call.
    bool isInterceptorClass =
        backend.isInterceptorClass(member.getEnclosingClass());

    const String receiverArgumentName = r'$receiver';

    js.Expression buildGetter() {
      if (member.isGetter()) {
        String getterName = namer.getterName(member);
        return new js.VariableUse('this').dot(getterName).callWith(
            isInterceptorClass
                ? <js.Expression>[new js.VariableUse(receiverArgumentName)]
                : <js.Expression>[]);
      } else {
        String fieldName = member.hasFixedBackendName()
            ? member.fixedBackendName()
            : namer.instanceFieldName(member);
        return new js.VariableUse('this').dot(fieldName);
      }
    }

    for (Selector selector in selectors) {
      if (selector.applies(member, compiler)) {
        String invocationName = namer.invocationName(selector);
        Selector callSelector = new Selector.callClosureFrom(selector);
        String closureCallName = namer.invocationName(callSelector);

        List<js.Parameter> parameters = <js.Parameter>[];
        List<js.Expression> arguments = <js.Expression>[];
        if (isInterceptorClass) {
          parameters.add(new js.Parameter(receiverArgumentName));
        }

        for (int i = 0; i < selector.argumentCount; i++) {
          String name = 'arg$i';
          parameters.add(new js.Parameter(name));
          arguments.add(new js.VariableUse(name));
        }

        js.Fun function =
            new js.Fun(parameters,
                new js.Block(
                    <js.Statement>[
                        new js.Return(
                            buildGetter().dot(closureCallName)
                                .callWith(arguments))]));

        defineStub(invocationName, function);
      }
    }
  }

  void emitStaticNonFinalFieldInitializations(CodeBuffer buffer) {
    ConstantHandler handler = compiler.constantHandler;
    Iterable<VariableElement> staticNonFinalFields =
        handler.getStaticNonFinalFieldsForEmission();
    for (Element element in Elements.sortedByPosition(staticNonFinalFields)) {
      compiler.withCurrentElement(element, () {
        Constant initialValue = handler.getInitialValueFor(element);
        js.Expression init =
            new js.Assignment(
                new js.PropertyAccess.field(
                    new js.VariableUse(isolateProperties),
                    namer.getName(element)),
                constantEmitter.referenceInInitializationContext(initialValue));
        buffer.add(js.prettyPrint(init, compiler));
        buffer.add('$N');
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
        assert(compiler.codegenWorld.generatedBailoutCode[element] == null);
        js.Expression code = compiler.codegenWorld.generatedCode[element];
        assert(code != null);
        // The code only computes the initial value. We build the lazy-check
        // here:
        //   lazyInitializer(prototype, 'name', fieldName, getterName, initial);
        // The name is used for error reporting. The 'initial' must be a
        // closure that constructs the initial value.
        List<js.Expression> arguments = <js.Expression>[];
        arguments.add(js.use(isolateProperties));
        arguments.add(js.string(element.name.slowToString()));
        arguments.add(js.string(namer.getName(element)));
        arguments.add(js.string(namer.getLazyInitializerName(element)));
        arguments.add(code);
        js.Expression getter = buildLazyInitializedGetter(element);
        if (getter != null) {
          arguments.add(getter);
        }
        js.Expression init = js.call(js.use(lazyInitializerName), arguments);
        buffer.add(js.prettyPrint(init, compiler));
        buffer.add("$N");
      }
    }
  }

  js.Expression buildLazyInitializedGetter(VariableElement element) {
    // Nothing to do, the 'lazy' function will create the getter.
    return null;
  }

  void emitCompileTimeConstants(CodeBuffer buffer) {
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
        emitMakeConstantList(buffer);
      }
      js.Expression init =
          new js.Assignment(
              new js.PropertyAccess.field(
                  new js.VariableUse(isolateProperties),
                  name),
              constantInitializerExpression(constant));
      buffer.add(js.prettyPrint(init, compiler));
      buffer.add('$N');
    }
  }

  void emitMakeConstantList(CodeBuffer buffer) {
    buffer.add(namer.isolateName);
    buffer.add(r'''.makeConstantList = function(list) {
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

    // Keep track of the noSuchMethod holders for each possible
    // receiver type.
    Map<ClassElement, Set<ClassElement>> noSuchMethodHolders =
        new Map<ClassElement, Set<ClassElement>>();
    Set<ClassElement> noSuchMethodHoldersFor(DartType type) {
      ClassElement element = type.element;
      Set<ClassElement> result = noSuchMethodHolders[element];
      if (result == null) {
        // For now, we check the entire world to see if an object of
        // the given type may have a user-defined noSuchMethod
        // implementation. We could do better by only looking at
        // instantiated (or otherwise needed) classes.
        result = compiler.world.findNoSuchMethodHolders(type);
        noSuchMethodHolders[element] = result;
      }
      return result;
    }

    js.Expression generateMethod(String jsName, Selector selector) {
      // Values match JSInvocationMirror in js-helper library.
      int type = selector.invocationMirrorKind;
      String methodName = selector.invocationMirrorMemberName;
      List<js.Parameter> parameters = <js.Parameter>[];
      CodeBuffer args = new CodeBuffer();
      for (int i = 0; i < selector.argumentCount; i++) {
        parameters.add(new js.Parameter('\$$i'));
      }

      List<js.Expression> argNames =
          selector.getOrderedNamedArguments().mappedBy((SourceString name) =>
              js.string(name.slowToString())).toList();

      String internalName = namer.invocationMirrorInternalName(selector);

      String createInvocationMirror = namer.getName(
          compiler.createInvocationMirrorElement);

      js.Expression expression =
          new js.This()
          .dot(noSuchMethodName)
          .callWith(
              <js.Expression>[
                  new js.VariableUse(namer.CURRENT_ISOLATE)
                  .dot(createInvocationMirror)
                  .callWith(
                      <js.Expression>[
                          js.string(methodName),
                          js.string(internalName),
                          new js.LiteralNumber('$type'),
                          new js.ArrayInitializer.from(
                              parameters.mappedBy((param) => js.use(param.name))
                                        .toList()),
                          new js.ArrayInitializer.from(argNames)])]);
      js.Expression function =
          new js.Fun(parameters,
              new js.Block(<js.Statement>[new js.Return(expression)]));
      return function;
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
          Element element = holder.lookupMember(selector.name);
          if (element == null) return false;

          // TODO(kasperl): Consider folding this logic into the
          // Selector.applies() method.
          if (element is AbstractFieldElement) {
            AbstractFieldElement field = element;
            if (selector.isGetter()) {
              return field.getter != null;
            } else if (selector.isSetter()) {
              return field.setter != null;
            } else {
              return false;
            }
          } else if (element is VariableElement) {
            if (selector.isSetter() && element.modifiers.isFinalOrConst()) {
              return false;
            }
          }
          return selector.applies(element, compiler);
        }

        // If the selector is typed, we check to see if that type may
        // have a user-defined noSuchMethod implementation. If not, we
        // skip the selector altogether.
        DartType receiverType = objectType;
        ClassElement receiverClass = objectClass;
        if (selector is TypedSelector) {
          TypedSelector typedSelector = selector;
          receiverType = typedSelector.receiverType;
          receiverClass = receiverType.element;
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
        Set<ClassElement> holders = noSuchMethodHoldersFor(receiverType);
        if (holders.every(hasMatchingMember)) continue;
        String jsName = namer.invocationMirrorInternalName(selector);
        if (!addedJsNames.contains(jsName)) {
          js.Expression method = generateMethod(jsName, selector);
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
      buffer.add("$mainAccess.$invocationName = $mainAccess$N");
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
    if (!compiler.enableMinification) {
      buffer.add("""

//
// BEGIN invoke [main].
//
""");
    }
    buffer.add("""
if (typeof document !== 'undefined' && document.readyState !== 'complete') {
  document.addEventListener('readystatechange', function () {
    if (document.readyState == 'complete') {
      if (typeof dartMainRunner === 'function') {
        dartMainRunner(function() { ${mainCall}; });
      } else {
        ${mainCall};
      }
    }
  }, false);
} else {
  if (typeof dartMainRunner === 'function') {
    dartMainRunner(function() { ${mainCall}; });
  } else {
    ${mainCall};
  }
}
""");
    if (!compiler.enableMinification) {
      buffer.add("""
//
// END invoke [main].
//

""");
    }
  }

  void emitGetInterceptorMethod(CodeBuffer buffer,
                                String objectName,
                                String key,
                                Collection<ClassElement> classes) {
    js.Statement buildReturnInterceptor(ClassElement cls) {
      return js.return_(js.fieldAccess(js.use(namer.isolateAccess(cls)),
                                       'prototype'));
    }

    js.VariableUse receiver = js.use('receiver');
    JavaScriptBackend backend = compiler.backend;

    /**
     * Build a JavaScrit AST node for doing a type check on
     * [cls]. [cls] must be an interceptor class.
     */
    js.Statement buildInterceptorCheck(ClassElement cls) {
      js.Expression condition;
      assert(backend.isInterceptorClass(cls));
      if (cls == backend.jsBoolClass) {
        condition = js.equals(js.typeOf(receiver), js.string('boolean'));
      } else if (cls == backend.jsIntClass ||
                 cls == backend.jsDoubleClass ||
                 cls == backend.jsNumberClass) {
        throw 'internal error';
      } else if (cls == backend.jsArrayClass) {
        condition = js.equals(js.fieldAccess(receiver, 'constructor'),
                              js.use('Array'));
      } else if (cls == backend.jsStringClass) {
        condition = js.equals(js.typeOf(receiver), js.string('string'));
      } else if (cls == backend.jsNullClass) {
        condition = js.equals(receiver, new js.LiteralNull());
      } else if (cls == backend.jsFunctionClass) {
        condition = js.equals(js.typeOf(receiver), js.string('function'));
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
      if (cls == backend.jsArrayClass) hasArray = true;
      else if (cls == backend.jsBoolClass) hasBool = true;
      else if (cls == backend.jsDoubleClass) hasDouble = true;
      else if (cls == backend.jsFunctionClass) hasFunction = true;
      else if (cls == backend.jsIntClass) hasInt = true;
      else if (cls == backend.jsNullClass) hasNull = true;
      else if (cls == backend.jsNumberClass) hasNumber = true;
      else if (cls == backend.jsStringClass) hasString = true;
      else throw 'Internal error: $cls';
    }
    if (hasDouble) {
      assert(!hasNumber);
      hasNumber = true;
    }
    if (hasInt) hasNumber = true;

    js.Block block = new js.Block.empty();

    if (hasNumber) {
      js.Statement whenNumber;

      /// Note: there are two number classes in play: Dart's [num],
      /// and JavaScript's Number (typeof receiver == 'number').  This
      /// is the fallback used when we have determined that receiver
      /// is a JavaScript Number.
      js.Return returnNumberClass = buildReturnInterceptor(
          hasDouble ? backend.jsDoubleClass : backend.jsNumberClass);

      if (hasInt) {
        js.Expression isInt =
            js.equals(js.call(js.fieldAccess(js.use('Math'), 'floor'),
                              [receiver]),
                      receiver);
        (whenNumber = js.emptyBlock()).statements
          ..add(js.if_(isInt, buildReturnInterceptor(backend.jsIntClass)))
          ..add(returnNumberClass);
      } else {
        whenNumber = returnNumberClass;
      }
      block.statements.add(
          js.if_(js.equals(js.typeOf(receiver), js.string('number')),
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
      block.statements.add(js.if_(js.equals(receiver, new js.LiteralNull()),
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
    block.statements.add(js.return_(js.fieldAccess(js.use(objectName),
                                                   'prototype')));

    js.PropertyAccess name = js.fieldAccess(js.use(isolateProperties), key);
    buffer.add(js.prettyPrint(js.assign(name, js.fun(['receiver'], block)),
                              compiler));
    buffer.add(N);
  }

  /**
   * Emit all versions of the [:getInterceptor:] method.
   */
  void emitGetInterceptorMethods(CodeBuffer buffer) {
    JavaScriptBackend backend = compiler.backend;
    // If no class needs to be intercepted, just return.
    if (backend.objectInterceptorClass == null) return;
    String objectName = namer.isolateAccess(backend.objectInterceptorClass);
    backend.specializedGetInterceptors.forEach(
        (String key, Collection<ClassElement> classes) {
          emitGetInterceptorMethod(buffer, objectName, key, classes);
        });
  }

  void computeNeededClasses() {
    instantiatedClasses =
        compiler.codegenWorld.instantiatedClasses.where(computeClassFilter())
            .toSet();
    neededClasses = new Set<ClassElement>.from(instantiatedClasses);
    for (ClassElement element in instantiatedClasses) {
      for (ClassElement superclass = element.superclass;
          superclass != null;
          superclass = superclass.superclass) {
        if (neededClasses.contains(superclass)) break;
        neededClasses.add(superclass);
      }
    }
  }

  void emitOneShotInterceptors(CodeBuffer buffer) {
    JavaScriptBackend backend = compiler.backend;
    for (Selector selector in backend.oneShotInterceptors) {
      Set<ClassElement> classes = backend.getInterceptedClassesOn(selector);
      String oneShotInterceptorName = namer.oneShotInterceptorName(selector);
      String getInterceptorName =
          namer.getInterceptorName(backend.getInterceptorMethod, classes);

      List<js.Parameter> parameters = <js.Parameter>[];
      List<js.Expression> arguments = <js.Expression>[];
      parameters.add(new js.Parameter('receiver'));
      arguments.add(js.use('receiver'));

      if (selector.isSetter()) {
        parameters.add(new js.Parameter('value'));
        arguments.add(js.use('value'));
      } else {
        for (int i = 0; i < selector.argumentCount; i++) {
          String argName = 'a$i';
          parameters.add(new js.Parameter(argName));
          arguments.add(js.use(argName));
        }
      }

      String invocationName = backend.namer.invocationName(selector);
      js.Fun function =
          new js.Fun(parameters,
              js.block1(js.return_(
                        js.use(isolateProperties)
                            .dot(getInterceptorName)
                            .callWith([js.use('receiver')])
                            .dot(invocationName)
                            .callWith(arguments))));

      js.PropertyAccess property =
          js.fieldAccess(js.use(isolateProperties), oneShotInterceptorName);

      buffer.add(js.prettyPrint(js.assign(property, function), compiler));
      buffer.add(N);
    }
  }

  String assembleProgram() {
    measure(() {
      computeNeededClasses();

      mainBuffer.add(GENERATED_BY);
      if (!compiler.enableMinification) mainBuffer.add(HOOKS_API_USAGE);
      mainBuffer.add('function ${namer.isolateName}()$_{}\n');
      mainBuffer.add('init()$N$n');
      // Shorten the code by using "$$" as temporary.
      classesCollector = r"$$";
      mainBuffer.add('var $classesCollector$_=$_{}$N');
      // Shorten the code by using [namer.CURRENT_ISOLATE] as temporary.
      isolateProperties = namer.CURRENT_ISOLATE;
      mainBuffer.add(
          'var $isolateProperties$_=$_$isolatePropertiesName$N');
      emitClasses(mainBuffer);
      mainBuffer.add(boundClosureBuffer);
      // Clear the buffer, so that we can reuse it for the native classes.
      boundClosureBuffer.clear();
      emitStaticFunctions(mainBuffer);
      emitStaticFunctionGetters(mainBuffer);
      // We need to finish the classes before we construct compile time
      // constants.
      emitFinishClassesInvocationIfNecessary(mainBuffer);
      emitRuntimeClassesAndTests(mainBuffer);
      emitCompileTimeConstants(mainBuffer);
      // Static field initializations require the classes and compile-time
      // constants to be set up.
      emitStaticNonFinalFieldInitializations(mainBuffer);
      emitOneShotInterceptors(mainBuffer);
      emitGetInterceptorMethods(mainBuffer);
      emitLazilyInitializedStaticFields(mainBuffer);

      isolateProperties = isolatePropertiesName;
      // The following code should not use the short-hand for the
      // initialStatics.
      mainBuffer.add('var ${namer.CURRENT_ISOLATE}$_=${_}null$N');
      mainBuffer.add(boundClosureBuffer);
      emitFinishClassesInvocationIfNecessary(mainBuffer);
      // After this assignment we will produce invalid JavaScript code if we use
      // the classesCollector variable.
      classesCollector = 'classesCollector should not be used from now on';

      emitFinishIsolateConstructorInvocation(mainBuffer);
      mainBuffer.add('var ${namer.CURRENT_ISOLATE}$_='
                     '${_}new ${namer.isolateName}()$N');

      nativeEmitter.assembleCode(mainBuffer);
      emitMain(mainBuffer);
      mainBuffer.add('function init()$_{\n');
      mainBuffer.add('$isolateProperties$_=$_{}$N');
      addDefineClassAndFinishClassFunctionsIfNecessary(mainBuffer);
      addLazyInitializerFunctionIfNecessary(mainBuffer);
      emitFinishIsolateConstructor(mainBuffer);
      mainBuffer.add('}\n');
      compiler.assembledCode = mainBuffer.getText();

      if (generateSourceMap) {
        SourceFile compiledFile = new SourceFile(null, compiler.assembledCode);
        String sourceMap = buildSourceMap(mainBuffer, compiledFile);
        // TODO(podivilov): We should find a better way to return source maps to
        // compiler. Using diagnostic handler for that purpose is a temporary
        // hack.
        compiler.reportDiagnostic(
            null, sourceMap, new api.Diagnostic(-1, 'source map'));
      }
    });
    return compiler.assembledCode;
  }

  String buildSourceMap(CodeBuffer buffer, SourceFile compiledFile) {
    SourceMapBuilder sourceMapBuilder = new SourceMapBuilder();
    buffer.forEachSourceLocation(sourceMapBuilder.addMapping);
    return sourceMapBuilder.build(compiledFile);
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
