// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A function element that represents a closure call. The signature is copied
 * from the given element.
 */
class ClosureInvocationElement extends FunctionElement {
  ClosureInvocationElement(SourceString name,
                           FunctionElement other)
      : super.from(name, other, other.enclosingElement);

  isInstanceMember() => true;
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
  final Namer namer;
  final NativeEmitter nativeEmitter;
  StringBuffer boundClosureBuffer;
  StringBuffer mainBuffer;
  /** Shorter access to [isolatePropertiesName]. Both here in the code, as
      well as in the generated code. */
  String isolateProperties;

  CodeEmitterTask(Compiler compiler)
      : namer = compiler.namer,
        nativeEmitter = new NativeEmitter(compiler),
        boundClosureBuffer = new StringBuffer(),
        mainBuffer = new StringBuffer(),
        super(compiler);

  String get name() => 'CodeEmitter';

  String get defineClassName()
      => '${namer.ISOLATE}.\$defineClass';
  String get finishClassesName()
      => '${namer.ISOLATE}.\$finishClasses';
  String get finishIsolateConstructorName()
      => '${namer.ISOLATE}.\$finishIsolateConstructor';
  String get pendingClassesName()
      => '${namer.ISOLATE}.\$pendingClasses';
  String get isolatePropertiesName()
      => '${namer.ISOLATE}.${namer.ISOLATE_PROPERTIES}';

  String get defineClassFunction() {
    // Example:
    // defineClass("A", "B",
    // function(x) {          /* The JavaScript constructor. */
    //   this.x = x;
    // }, {                   /* The members inside an Object literal. */
    //  foo$1: function(y) {
    //   print(this.x + y);
    //  },
    //  bar$2: function(t, v) {
    //   this.x = t - v;
    //  },
    // });
    return """
function(cls, superclass, constructor, prototype) {
  $isolatePropertiesName[cls] = constructor;
  constructor.prototype = prototype;
  if (superclass !== "") {
    $pendingClassesName[cls] = superclass;
  }
}""";
  }

  String get finishClassesFunction() {
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
function() {
  var pendingClasses = $pendingClassesName;
'''/* FinishClasses can be called multiple times. This means that we need to
      clear the pendingClasses property. */'''
  $pendingClassesName = {};
  var finishedClasses = {};
  function finishClass(cls) {
    if (finishedClasses[cls]) return;
    finishedClasses[cls] = true;
    var superclass = pendingClasses[cls];
'''/* The superclass is only false (empty string) for Dart's Object class. */'''
    if (!superclass) return;
    finishClass(superclass);
    var constructor = $isolatePropertiesName[cls];
    var superConstructor = $isolatePropertiesName[superclass];
    var prototype = constructor.prototype;
    if (prototype.__proto__) {
'''/* On Firefox and Webkit browsers we can manipulate the __proto__
      directly. */'''
      prototype.__proto__ = superConstructor.prototype;
      prototype.constructor = constructor;
    } else {
'''/* On the remaining browsers we need to instantiate an object with the
      correct (internal) prototype set up correctly, and then copy the
      members. */'''
      function tmp() {};
      tmp.prototype = superConstructor.prototype;
      var newPrototype = new tmp();
      constructor.prototype = newPrototype;
      newPrototype.constructor = constructor;
'''/* Opera does not support 'getOwnPropertyNames'. Therefore we use
      hosOwnProperty instead. */'''
      var hasOwnProperty = Object.prototype.hasOwnProperty;
      for (var member in prototype) {
        if (hasOwnProperty.call(prototype, member)) {
          newPrototype[member] = prototype[member];
        }
      }
    }
  }
  for (var cls in pendingClasses) finishClass(cls);
}''';
  }

  String get finishIsolateConstructorFunction() {
    String isolate = namer.ISOLATE;
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
  var isolateProperties = oldIsolate.${namer.ISOLATE_PROPERTIES};
  var isolatePrototype = oldIsolate.prototype;
  var str = "{\\n";
  str += "var isolateProperties = $isolate.${namer.ISOLATE_PROPERTIES};\\n";
  for (var staticName in isolateProperties) {
    if (Object.prototype.hasOwnProperty.call(isolateProperties, staticName)) {
      str += "this." + staticName + "= isolateProperties." + staticName + ";\\n";
    }
  }
  str += "}\\n";
  var newIsolate = new Function(str);
  newIsolate.prototype = isolatePrototype;
  isolatePrototype.constructor = newIsolate;
  newIsolate.${namer.ISOLATE_PROPERTIES} = isolateProperties;
  return newIsolate;
}""";
  }

  void addDefineClassAndFinishClassFunctionsIfNecessary(StringBuffer buffer) {
    String isolate = namer.ISOLATE;
    buffer.add("$defineClassName = $defineClassFunction;\n");
    buffer.add("$pendingClassesName = {};\n");
    buffer.add("$finishClassesName = $finishClassesFunction;\n");
  }

  void emitFinishIsolateConstructor(StringBuffer buffer) {
    String name = finishIsolateConstructorName;
    String value = finishIsolateConstructorFunction;
    buffer.add("$name = $value;\n");
  }

  void emitFinishIsolateConstructorInvocation(StringBuffer buffer) {
    String isolate = namer.ISOLATE;
    buffer.add("$isolate = $finishIsolateConstructorName($isolate);\n");
  }

  void addParameterStub(FunctionElement member,
                        Selector selector,
                        void defineInstanceMember(String invocationName,
                                                  String definition)) {
    FunctionParameters parameters = member.computeParameters(compiler);
    int positionalArgumentCount = selector.positionalArgumentCount;
    if (positionalArgumentCount == parameters.parameterCount) {
      assert(selector.namedArgumentCount == 0);
      return;
    }
    ConstantHandler handler = compiler.constantHandler;
    List<SourceString> names = selector.getOrderedNamedArguments();

    String invocationName =
        namer.instanceMethodInvocationName(member.getLibrary(), member.name,
                                           selector);
    StringBuffer buffer = new StringBuffer();
    buffer.add('function(');

    // The parameters that this stub takes.
    List<String> parametersBuffer = new List<String>(selector.argumentCount);
    // The arguments that will be passed to the real method.
    List<String> argumentsBuffer = new List<String>(parameters.parameterCount);

    // We fill the lists depending on the selector. For example,
    // take method foo:
    //    foo(a, b, [c, d]);
    //
    // We may have multiple ways of calling foo:
    // (1) foo(1, 2, 3, 4)
    // (2) foo(1, 2);
    // (3) foo(1, 2, 3);
    // (4) foo(1, 2, c: 3);
    // (5) foo(1, 2, d: 4);
    // (6) foo(1, 2, c: 3, d: 4);
    // (7) foo(1, 2, d: 4, c: 3);
    //
    // What we generate at the call sites are:
    // (1) foo$4(1, 2, 3, 4)
    // (2) foo$2(1, 2);
    // (3) foo$3(1, 2, 3);
    // (4) foo$3$c(1, 2, 3);
    // (5) foo$3$d(1, 2, 4);
    // (6) foo$4$c$d(1, 2, 3, 4);
    // (7) foo$4$c$d(1, 2, 3, 4);
    //
    // The stubs we generate are (expressed in Dart):
    // (1) No stub generated, call is direct.
    // (2) foo$2(a, b) => foo$4(a, b, null, null)
    // (3) foo$3(a, b, c) => foo$4(a, b, c, null)
    // (4) foo$3$c(a, b, c) => foo$4(a, b, c, null);
    // (5) foo$3$d(a, b, d) => foo$4(a, b, null, d);
    // (6) foo$4$c$d(a, b, c, d) => foo$4(a, b, c, d);
    // (7) Same as (5).
    //
    // We need to generate a stub for (5) because the order of the
    // stub arguments and the real method may be different.

    int count = 0;
    int indexOfLastOptionalArgumentInParameters = positionalArgumentCount - 1;
    parameters.forEachParameter((Element element) {
      String jsName = JsNames.getValid(element.name.slowToString());
      if (count < positionalArgumentCount) {
        parametersBuffer[count] = jsName;
        argumentsBuffer[count] = jsName;
      } else {
        int index = names.indexOf(element.name);
        if (index != -1) {
          indexOfLastOptionalArgumentInParameters = count;
          // The order of the named arguments is not the same as the
          // one in the real method (which is in Dart source order).
          argumentsBuffer[count] = jsName;
          parametersBuffer[selector.positionalArgumentCount + index] = jsName;
        } else {
          Constant value = handler.initialVariableValues[element];
          if (value == null) {
            argumentsBuffer[count] = '(void 0)';
          } else {
            if (!value.isNull()) {
              // If the value is the null constant, we should not pass it
              // down to the native method.
              indexOfLastOptionalArgumentInParameters = count;
            }
            StringBuffer argumentBuffer = new StringBuffer();
            handler.writeConstant(argumentBuffer, value);
            argumentsBuffer[count] = argumentBuffer.toString();
          }
        }
      }
      count++;
    });
    String parametersString = Strings.join(parametersBuffer, ",");
    buffer.add('$parametersString) {\n');

    if (member.isNative()) {
      nativeEmitter.generateParameterStub(
          member, invocationName, parametersString, argumentsBuffer,
          indexOfLastOptionalArgumentInParameters, buffer);
    } else {
      String arguments = Strings.join(argumentsBuffer, ",");
      buffer.add('  return this.${namer.getName(member)}($arguments)');
    }
    buffer.add('\n}');
    defineInstanceMember(invocationName, buffer.toString());
  }

  void addParameterStubs(FunctionElement member,
                         void defineInstanceMember(String invocationName,
                                                   String definition)) {
    Set<Selector> selectors = compiler.universe.invokedNames[member.name];
    if (selectors == null) return;
    for (Selector selector in selectors) {
      if (!selector.applies(member, compiler)) continue;
      addParameterStub(member, selector, defineInstanceMember);
    }
  }

  void addInstanceMember(Element member,
                         void defineInstanceMember(String invocationName,
                                                   String definition)) {
    // TODO(floitsch): we don't need to deal with members of
    // uninstantiated classes, that have been overwritten by subclasses.

    if (member.kind === ElementKind.FUNCTION
        || member.kind === ElementKind.GENERATIVE_CONSTRUCTOR_BODY
        || member.kind === ElementKind.GETTER
        || member.kind === ElementKind.SETTER) {
      if (member.modifiers !== null && member.modifiers.isAbstract()) return;
      String codeBlock = compiler.universe.generatedCode[member];
      if (codeBlock == null) return;
      defineInstanceMember(namer.getName(member), codeBlock);
      codeBlock = compiler.universe.generatedBailoutCode[member];
      if (codeBlock !== null) {
        defineInstanceMember(compiler.namer.getBailoutName(member), codeBlock);
      }
      FunctionElement function = member;
      FunctionParameters parameters = function.computeParameters(compiler);
      if (!parameters.optionalParameters.isEmpty()) {
        addParameterStubs(member, defineInstanceMember);
      }
    } else if (member.kind === ElementKind.FIELD) {
      // TODO(ngeoffray): Have another class generate the code for the
      // fields.
      if ((member.modifiers === null || !member.modifiers.isFinal()) &&
          compiler.universe.hasSetter(member, compiler)) {
        String setterName = namer.setterName(member.getLibrary(), member.name);
        String name = member.isNative()
            ? member.name.slowToString()
            : namer.getName(member);
        defineInstanceMember(setterName, "function(v) { this.$name = v; }");
      }
      if (compiler.universe.hasGetter(member, compiler)) {
        String getterName = namer.getterName(member.getLibrary(), member.name);
        String name = member.isNative()
            ? member.name.slowToString()
            : namer.getName(member);
        defineInstanceMember(getterName, "function() { return this.$name; }");
      }
    } else {
      compiler.internalError('unexpected kind: "${member.kind}"',
                             element: member);
    }
    emitExtraAccessors(member, defineInstanceMember);
  }

  bool generateFieldInits(ClassElement classElement,
                          StringBuffer argumentsBuffer,
                          StringBuffer bodyBuffer) {
    bool isFirst = true;
    void generateFieldInit(ClassElement enclosingClass, Element member) {
      // TODO(floitsch): make sure there are no name clashes.
      String className = namer.getName(enclosingClass);
      if (!isFirst) argumentsBuffer.add(', ');
      isFirst = false;
      String memberName = namer.instanceFieldName(member.getLibrary(),
                                                  member.name);
      String parameter;
      if (classElement === enclosingClass) {
        parameter = memberName;
      } else {
        parameter = '${className}_$memberName';
      }
      argumentsBuffer.add(parameter);
      bodyBuffer.add('  this.$memberName = $parameter;\n');
    }

    classElement.forEachInstanceField(generateFieldInit,
                                      includeBackendMembers: true,
                                      includeSuperMembers: true);
  }

  void generateClass(ClassElement classElement, StringBuffer buffer) {
    needsDefineClass = true;

    if (classElement.isNative()) {
      nativeEmitter.generateNativeClass(classElement);
      return;
    } else {
      // TODO(ngeoffray): Instead of switching between buffer, we
      // should create code sections, and decide where to emit them at
      // the end.
      buffer = mainBuffer;
    }

    String className = namer.getName(classElement);
    ClassElement superclass = classElement.superclass;
    String superName = "";
    if (superclass !== null) {
      superName = namer.getName(superclass);
    }
    String constructorName = namer.safeName(classElement.name.slowToString());
    buffer.add('$defineClassName("$className", "$superName", ');
    buffer.add('function $constructorName(');
    StringBuffer bodyBuffer = new StringBuffer();
    // If the class is never instantiated we still need to set it up for
    // inheritance purposes, but we can leave its JavaScript constructor empty.
    if (compiler.universe.instantiatedClasses.contains(classElement)) {
      generateFieldInits(classElement, buffer, bodyBuffer);
    }
    buffer.add(') {\n');
    buffer.add(bodyBuffer);
    buffer.add(' }, ');

    buffer.add('{\n');

    void defineInstanceMember(String name, String value) {
      buffer.add(' $name: $value,\n');
    }

    classElement.forEachMember(includeBackendMembers: true,
                               f: (ClassElement enclosing, Element member) {
      if (member.isInstanceMember()) {
        addInstanceMember(member, defineInstanceMember);
      }
    });

    generateTypeTests(classElement, (Element other) {
      if (nativeEmitter.requiresNativeIsCheck(other)) {
        defineInstanceMember(namer.operatorIs(other),
                             'function() { return true; }');
      } else {
        defineInstanceMember(namer.operatorIs(other), 'true');
      }
    });

    if (classElement === compiler.objectClass && compiler.enabledNoSuchMethod) {
      // Emit the noSuchMethods on the Object prototype now, so that
      // the code in the dynamicMethod can find them. Note that the
      // code in dynamicMethod is invoked before analyzing the full JS
      // script.
      emitNoSuchMethodCalls(defineInstanceMember);
    }
    buffer.add('});\n\n');
  }

  void generateTypeTests(ClassElement cls,
                         void generateTypeTest(ClassElement element)) {
    if (compiler.universe.isChecks.contains(cls)) {
      generateTypeTest(cls);
    }
    generateInterfacesIsTests(cls, generateTypeTest, new Set<Element>());
  }

  void generateInterfacesIsTests(ClassElement cls,
                                 void generateTypeTest(ClassElement element),
                                 Set<Element> alreadyGenerated) {
    for (Type interfaceType in cls.interfaces) {
      Element element = interfaceType.element;
      if (!alreadyGenerated.contains(element) &&
          compiler.universe.isChecks.contains(element)) {
        alreadyGenerated.add(element);
        generateTypeTest(element);
      }
      generateInterfacesIsTests(element, generateTypeTest, alreadyGenerated);
    }
  }

  void emitClasses(StringBuffer buffer) {
    Set<ClassElement> instantiatedClasses =
        compiler.universe.instantiatedClasses;
    Set<ClassElement> neededClasses =
        new Set<ClassElement>.from(instantiatedClasses);
    for (ClassElement element in instantiatedClasses) {
      for (ClassElement superclass = element.superclass;
           superclass !== null;
           superclass = superclass.superclass) {
        if (neededClasses.contains(superclass)) break;
        neededClasses.add(superclass);
      }
    }
    for (ClassElement element in neededClasses) {
      generateClass(element, buffer);
    }

    // The closure class could have become necessary because of the generation
    // of stubs.
    ClassElement closureClass = compiler.closureClass;
    if (needsClosureClass && !instantiatedClasses.contains(closureClass)) {
      generateClass(closureClass, buffer);
    }
  }

  void emitFinishClassesInvocationIfNecessary(StringBuffer buffer) {
    if (needsDefineClass) buffer.add("$finishClassesName();\n");
  }

  void emitStaticFunctionsWithNamer(StringBuffer buffer,
                                    Map<Element, String> generatedCode,
                                    String functionNamer(Element element)) {
    generatedCode.forEach((Element element, String codeBlock) {
      if (!element.isInstanceMember()) {
        String functionName = functionNamer(element);
        buffer.add('$isolateProperties.$functionName = $codeBlock;\n\n');
      }
    });
  }

  void emitStaticFunctions(StringBuffer buffer) {
    emitStaticFunctionsWithNamer(buffer,
                                 compiler.universe.generatedCode,
                                 namer.getName);
    emitStaticFunctionsWithNamer(buffer,
                                 compiler.universe.generatedBailoutCode,
                                 namer.getBailoutName);
  }

  void emitStaticFunctionGetters(StringBuffer buffer) {
    Set<FunctionElement> functionsNeedingGetter =
        compiler.universe.staticFunctionsNeedingGetter;
    for (FunctionElement element in functionsNeedingGetter) {
      // The static function does not have the correct name. Since
      // [addParameterStubs] use the name to create its stubs we simply
      // create a fake element with the correct name.
      // Note: the callElement will not have any enclosingElement.
      FunctionElement callElement =
          new ClosureInvocationElement(Namer.CLOSURE_INVOCATION_NAME, element);
      String staticName = namer.getName(element);
      int parameterCount = element.parameterCount(compiler);
      String invocationName =
          namer.instanceMethodName(element.getLibrary(), callElement.name,
                                   parameterCount);
      String fieldAccess = '$isolateProperties.$staticName';
      buffer.add("$fieldAccess.$invocationName = $fieldAccess;\n");
      addParameterStubs(callElement, (String name, String value) {
        buffer.add('$fieldAccess.$name = $value;\n');
      });
    }
  }

  void emitDynamicFunctionGetter(FunctionElement member,
                                 defineInstanceMember(String invocationName,
                                                      String definition)) {
    // For every method that has the same name as a property-get we create a
    // getter that returns a bound closure. Say we have a class 'A' with method
    // 'foo' and somewhere in the code there is a dynamic property get of
    // 'foo'. Then we generate the following code (in pseudo Dart):
    //
    // class A {
    //    foo(x, y, z) { ... } // Original function.
    //    get foo() { return new BoundClosure499(this); }
    // }
    // class BoundClosure499 extends Closure {
    //   var self;
    //   BoundClosure499(this.self);
    //   $call3(x, y, z) { return self.foo(x, y, z); }
    // }

    // TODO(floitsch): share the closure classes with other classes
    // if they share methods with the same signature.

    // The closure class.
    SourceString name = const SourceString("BoundClosure");
    ClassElement closureClassElement =
        new ClosureClassElement(compiler, member.getCompilationUnit());
    String mangledName = namer.getName(closureClassElement);
    String superName = namer.getName(closureClassElement.superclass);
    needsClosureClass = true;

    // Define the constructor with a name so that Object.toString can
    // find the class name of the closure class.
    boundClosureBuffer.add("$defineClassName('$mangledName', '$superName', ");
    boundClosureBuffer.add("function $name(self) { this.self = self; }, {\n");

    // Now add the methods on the closure class. The instance method does not
    // have the correct name. Since [addParameterStubs] use the name to create
    // its stubs we simply create a fake element with the correct name.
    // Note: the callElement will not have any enclosingElement.
    FunctionElement callElement =
        new ClosureInvocationElement(Namer.CLOSURE_INVOCATION_NAME, member);

    int parameterCount = member.parameterCount(compiler);
    String invocationName =
        namer.instanceMethodName(member.getLibrary(),
                                 callElement.name, parameterCount);
    String targetName = namer.instanceMethodName(member.getLibrary(),
                                                 member.name, parameterCount);
    List<String> arguments = new List<String>(parameterCount);
    for (int i = 0; i < parameterCount; i++) {
      arguments[i] = "arg$i";
    }
    String joinedArgs = Strings.join(arguments, ", ");
    boundClosureBuffer.add(
        "$invocationName: function($joinedArgs) {\n");
    boundClosureBuffer.add("  return this.self.$targetName($joinedArgs);\n");
    boundClosureBuffer.add("},\n");
    addParameterStubs(callElement, (String stubName, String memberValue) {
      boundClosureBuffer.add('$stubName: $memberValue,\n');
    });
    boundClosureBuffer.add("});\n");

    // And finally the getter.
    String getterName = namer.getterName(member.getLibrary(), member.name);
    String closureClass = namer.isolateAccess(closureClassElement);
    defineInstanceMember(getterName,
                         "function() { return new $closureClass(this); }");
  }

  void emitCallStubForGetter(Element member,
                             Set<Selector> selectors,
                             void defineInstanceMember(String invocationName,
                                                       String definition)) {
    String getter;
    if (member.kind == ElementKind.GETTER) {
      getter = "this.${namer.getterName(member.getLibrary(), member.name)}()";
    } else {
      getter =
          "this.${namer.instanceFieldName(member.getLibrary(), member.name)}";
    }
    for (Selector selector in selectors) {
      if (selector.applies(member, compiler)) {
        String invocationName =
            namer.instanceMethodInvocationName(member.getLibrary(), member.name,
                                               selector);
        SourceString callName = Namer.CLOSURE_INVOCATION_NAME;
        String closureCallName =
            namer.instanceMethodInvocationName(member.getLibrary(), callName,
                                               selector);
        List<String> arguments = <String>[];
        for (int i = 0; i < selector.argumentCount; i++) {
          arguments.add("arg$i");
        }
        String joined = Strings.join(arguments, ", ");
        defineInstanceMember(
            invocationName,
            "function($joined) { return $getter.$closureCallName($joined); }");
      }
    }
  }

  void emitStaticNonFinalFieldInitializations(StringBuffer buffer) {
    ConstantHandler handler = compiler.constantHandler;
    List<VariableElement> staticNonFinalFields =
        handler.getStaticNonFinalFieldsForEmission();
    for (Element element in staticNonFinalFields) {
      buffer.add('$isolateProperties.${namer.getName(element)} = ');
      compiler.withCurrentElement(element, () {
          handler.writeJsCodeForVariable(buffer, element);
        });
      buffer.add(';\n');
    }
  }

  void emitCompileTimeConstants(StringBuffer buffer) {
    ConstantHandler handler = compiler.constantHandler;
    List<Constant> constants = handler.getConstantsForEmission();
    bool addedMakeConstantList = false;
    for (Constant constant in constants) {
      String name = handler.getNameForConstant(constant);
      // The name is null when the constant is already a JS constant.
      // TODO(floitsch): every constant should be registered, so that we can
      // share the ones that take up too much space (like some strings).
      if (name === null) continue;
      if (!addedMakeConstantList && constant.isList()) {
        addedMakeConstantList = true;
        emitMakeConstantList(buffer);
      }
      buffer.add('$isolateProperties.$name = ');
      handler.writeJsCode(buffer, constant);
      buffer.add(';\n');
    }
  }

  void emitMakeConstantList(StringBuffer buffer) {
    buffer.add(namer.ISOLATE);
    buffer.add(@'''.makeConstantList = function(list) {
  list.immutable$list = true;
  list.fixed$length = true;
  return list;
};
''');
  }

  void emitExtraAccessors(Element member,
                          void defineInstanceMember(String invocationName,
                                                    String definition)) {
    if (member.kind == ElementKind.GETTER || member.kind == ElementKind.FIELD) {
      Set<Selector> selectors = compiler.universe.invokedNames[member.name];
      if (selectors !== null && !selectors.isEmpty()) {
        compiler.emitter.emitCallStubForGetter(member, selectors,
                                               defineInstanceMember);
      }
    } else if (member.kind == ElementKind.FUNCTION) {
      if (compiler.universe.hasGetter(member, compiler)) {
        compiler.emitter.emitDynamicFunctionGetter(member,
                                                   defineInstanceMember);
      }
    }
  }

  void emitNoSuchMethodCalls(void defineInstanceMember(String invocationName,
                                                       String definition)) {
    // Do not generate no such method calls if there is no class.
    if (compiler.universe.instantiatedClasses.isEmpty()) return;

    ClassElement objectClass =
        compiler.coreLibrary.find(const SourceString('Object'));
    String runtimeObjectPrototype =
        '${namer.isolateAccess(objectClass)}.prototype';
    String noSuchMethodName =
        namer.instanceMethodName(null, Compiler.NO_SUCH_METHOD, 2);
    Collection<LibraryElement> libraries =
        compiler.universe.libraries.getValues();

    String generateMethod(String methodName, Selector selector) {
      StringBuffer buffer = new StringBuffer();
      buffer.add('function');
      StringBuffer args = new StringBuffer();
      for (int i = 0; i < selector.argumentCount; i++) {
        if (i != 0) args.add(', ');
        args.add('arg$i');
      }
      // We need to check if the object has a noSuchMethod. If not, it
      // means the object is a native object, and we can just call our
      // generic noSuchMethod. Note that when calling this method, the
      // 'this' object is not a Dart object.
      buffer.add(' ($args) {\n');
      buffer.add('  return this.$noSuchMethodName\n');
      buffer.add("      ? this.$noSuchMethodName('$methodName', [$args])\n");
      buffer.add("      : $runtimeObjectPrototype.$noSuchMethodName.call(");
      buffer.add("this, '$methodName', [$args])\n");
      buffer.add('}');
      return buffer.toString();
    }

    compiler.universe.invokedNames.forEach((SourceString methodName,
                                            Set<Selector> selectors) {
      if (objectClass.lookupLocalMember(methodName) === null
          && methodName != Namer.OPERATOR_EQUALS) {
        for (Selector selector in selectors) {
          if (methodName.isPrivate()) {
            for (LibraryElement lib in libraries) {
              String jsName =
                namer.instanceMethodInvocationName(lib, methodName, selector);
              String method =
                  generateMethod(methodName.slowToString(), selector);
              defineInstanceMember(jsName, method);
            }
          } else {
            String jsName =
              namer.instanceMethodInvocationName(null, methodName, selector);
            String method = generateMethod(methodName.slowToString(), selector);
            defineInstanceMember(jsName, method);
          }
        }
      }
    });

    compiler.universe.invokedGetters.forEach((SourceString getterName,
                                              Set<Selector> selectors) {
      if (getterName.isPrivate()) {
        for (LibraryElement lib in libraries) {
          String jsName = namer.getterName(lib, getterName);
          String method = generateMethod('get ${getterName.slowToString()}',
                                         Selector.GETTER);
          defineInstanceMember(jsName, method);
        }
      } else {
        String jsName = namer.getterName(null, getterName);
        String method = generateMethod('get ${getterName.slowToString()}',
                                       Selector.GETTER);
        defineInstanceMember(jsName, method);
      }
    });

    compiler.universe.invokedSetters.forEach((SourceString setterName,
                                              Set<Selector> selectors) {
      if (setterName.isPrivate()) {
        for (LibraryElement lib in libraries) {
          String jsName = namer.setterName(lib, setterName);
          String method = generateMethod('set ${setterName.slowToString()}',
                                         Selector.SETTER);
          defineInstanceMember(jsName, method);
        }
      } else {
        String jsName = namer.setterName(null, setterName);
        String method = generateMethod('set ${setterName.slowToString()}',
                                       Selector.SETTER);
        defineInstanceMember(jsName, method);
      }
    });
  }

  String buildIsolateSetup(StringBuffer buffer,
                           Element appMain,
                           Element isolateMain) {
    String mainAccess = "${namer.isolateAccess(appMain)}";
    String currentIsolate = "${namer.CURRENT_ISOLATE}";
    String mainEnsureGetter = '';
    // Since we pass the closurized version of the main method to
    // the isolate method, we must make sure that it exists.
    if (!compiler.universe.staticFunctionsNeedingGetter.contains(appMain)) {
      String invocationName =
          "${namer.closureInvocationName(Selector.INVOCATION_0)}";
      mainEnsureGetter = "$mainAccess.$invocationName = $mainAccess";
    }

    // TODO(ngeoffray): These globals are currently required by the isolate
    // library, but since leg already generates code on an Isolate object, they
    // are not really needed. We should remove them once Leg replaces Frog.
    buffer.add("""
var \$globalThis = $currentIsolate;
var \$globalState;
var \$globals;
var \$isWorker;
var \$supportsWorkers;
var \$thisScriptUrl;
function \$static_init(){};

function \$initGlobals(context) {
  context.isolateStatics = new ${namer.ISOLATE}();
}
function \$setGlobals(context) {
  $currentIsolate = context.isolateStatics;
  \$globalThis = $currentIsolate;
}
$mainEnsureGetter
""");
  return "${namer.isolateAccess(isolateMain)}($mainAccess)";
  }

  emitMain(StringBuffer buffer) {
    if (compiler.isMockCompilation) return;
    Element main = compiler.mainApp.find(Compiler.MAIN);
    String mainCall = null;
    if (compiler.isolateLibrary != null) {
      Element isolateMain =
        compiler.isolateLibrary.find(Compiler.START_ROOT_ISOLATE);
      mainCall = buildIsolateSetup(buffer, main, isolateMain);
    } else {
      mainCall = '${namer.isolateAccess(main)}()';
    }
    buffer.add("""
if (typeof window != 'undefined' && typeof document != 'undefined' &&
    window.addEventListener && document.readyState == 'loading') {
  window.addEventListener('DOMContentLoaded', function(e) {
    ${mainCall};
  });
} else {
  ${mainCall};
}
""");
  }

  String assembleProgram() {
    measure(() {
      mainBuffer.add('function ${namer.ISOLATE}() {}\n');
      mainBuffer.add('init();\n\n');
      // Shorten the code by using [namer.CURRENT_ISOLATE] as temporary.
      isolateProperties = namer.CURRENT_ISOLATE;
      mainBuffer.add('var $isolateProperties = $isolatePropertiesName;\n');
      emitClasses(mainBuffer);
      mainBuffer.add(boundClosureBuffer);
      // Clear the buffer, so that we can reuse it for the native classes.
      boundClosureBuffer.clear();
      emitStaticFunctions(mainBuffer);
      emitStaticFunctionGetters(mainBuffer);
      // We need to finish the classes before we construct compile time
      // constants.
      emitFinishClassesInvocationIfNecessary(mainBuffer);
      emitCompileTimeConstants(mainBuffer);
      // Static field initializations require the classes and compile-time
      // constants to be set up.
      emitStaticNonFinalFieldInitializations(mainBuffer);

      isolateProperties = isolatePropertiesName;
      // The following code should not use the short-hand for the
      // initialStatics.
      mainBuffer.add('var ${namer.CURRENT_ISOLATE} = null;\n');
      nativeEmitter.emitDynamicDispatchMetadata();
      mainBuffer.add(boundClosureBuffer);
      emitFinishClassesInvocationIfNecessary(mainBuffer);

      emitFinishIsolateConstructorInvocation(mainBuffer);
      mainBuffer.add(
        'var ${namer.CURRENT_ISOLATE} = new ${namer.ISOLATE}();\n');

      nativeEmitter.assembleCode(mainBuffer);
      emitMain(mainBuffer);
      mainBuffer.add('function init() {\n');
      mainBuffer.add('  $isolateProperties = {};\n');
      addDefineClassAndFinishClassFunctionsIfNecessary(mainBuffer);
      emitFinishIsolateConstructor(mainBuffer);
      mainBuffer.add('}\n');
      compiler.assembledCode = mainBuffer.toString();
    });
    return compiler.assembledCode;
  }
}
