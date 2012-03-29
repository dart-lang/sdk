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
  static final String INHERIT_FUNCTION = '''
function(child, parent) {
  if (child.prototype.__proto__) {
    child.prototype.__proto__ = parent.prototype;
  } else {
    function tmp() {};
    tmp.prototype = parent.prototype;
    child.prototype = new tmp();
    child.prototype.constructor = child;
  }
}''';

  bool addedInheritFunction = false;
  final Namer namer;
  final NativeEmitter nativeEmitter;
  Set<ClassElement> generatedClasses;
  StringBuffer mainBuffer;

  CodeEmitterTask(Compiler compiler)
      : namer = compiler.namer,
        nativeEmitter = new NativeEmitter(compiler),
        generatedClasses = new Set<ClassElement>(),
        mainBuffer = new StringBuffer(),
        super(compiler);

  String get name() => 'CodeEmitter';

  String get inheritsName() => '${namer.ISOLATE}.\$inherits';

  String get objectClassName() {
    ClassElement objectClass =
        compiler.coreLibrary.find(const SourceString('Object'));
    return namer.isolatePropertyAccess(objectClass);
  }

  void addInheritFunctionIfNecessary() {
    if (addedInheritFunction) return;
    addedInheritFunction = true;
    mainBuffer.add('$inheritsName = ');
    mainBuffer.add(INHERIT_FUNCTION);
    mainBuffer.add(';\n');
  }

  void addParameterStub(FunctionElement member,
                        String attachTo(String invocationName),
                        StringBuffer buffer,
                        Selector selector,
                        bool isNative) {
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
    buffer.add('${attachTo(invocationName)} = function(');

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
            argumentsBuffer[count] =
                handler.writeJsCode(new StringBuffer(), value).toString();
          }
        }
      }
      count++;
    });
    String parametersString = Strings.join(parametersBuffer, ",");
    buffer.add('$parametersString) {\n');

    if (isNative) {
      nativeEmitter.emitParameterStub(
          member, invocationName, parametersString, argumentsBuffer,
          indexOfLastOptionalArgumentInParameters);
    } else {
      String arguments = Strings.join(argumentsBuffer, ",");
      buffer.add('  return this.${namer.getName(member)}($arguments)');
  }
    buffer.add('\n};\n');
  }

  void addParameterStubs(FunctionElement member,
                         String attachTo(String invocationName),
                         StringBuffer buffer,
                         [bool isNative = false]) {
    Set<Selector> selectors = compiler.universe.invokedNames[member.name];
    if (selectors == null) return;
    FunctionParameters parameters = member.computeParameters(compiler);
    for (Selector selector in selectors) {
      if (!selector.applies(parameters)) continue;
      addParameterStub(member, attachTo, buffer, selector, isNative);
    }
  }

  void addInstanceMember(Element member,
                         String attachTo(String name),
                         StringBuffer buffer,
                         [bool isNative = false]) {
    // TODO(floitsch): we don't need to deal with members of
    // uninstantiated classes, that have been overwritten by subclasses.

    if (member.kind === ElementKind.FUNCTION
        || member.kind === ElementKind.GENERATIVE_CONSTRUCTOR_BODY
        || member.kind === ElementKind.GETTER
        || member.kind === ElementKind.SETTER) {
      if (member.modifiers !== null && member.modifiers.isAbstract()) return;
      String codeBlock = compiler.universe.generatedCode[member];
      if (codeBlock == null) return;
      buffer.add('${attachTo(namer.getName(member))} = $codeBlock;\n');
      codeBlock = compiler.universe.generatedBailoutCode[member];
      if (codeBlock !== null) {
        String name = compiler.namer.getBailoutName(member);
        buffer.add('${attachTo(name)} = $codeBlock;\n');
      }
      FunctionElement function = member;
      FunctionParameters parameters = function.computeParameters(compiler);
      if (!parameters.optionalParameters.isEmpty()) {
        addParameterStubs(member, attachTo, buffer, isNative: isNative);
      }
    } else if (member.kind === ElementKind.FIELD) {
      // TODO(ngeoffray): Have another class generate the code for the
      // fields.
      if ((member.modifiers === null || !member.modifiers.isFinal()) &&
          compiler.universe.invokedSetters.contains(member.name)) {
        String setterName = namer.setterName(member.getLibrary(), member.name);
        String name =
            isNative ? member.name.slowToString() : namer.getName(member);
        buffer.add('${attachTo(setterName)} = function(v){\n');
        buffer.add('  this.$name = v;\n};\n');
      }
      if (compiler.universe.invokedGetters.contains(member.name)) {
        String getterName = namer.getterName(member.getLibrary(), member.name);
        String name =
            isNative ? member.name.slowToString() : namer.getName(member);
        buffer.add('${attachTo(getterName)} = function(){\n');
        buffer.add('  return this.$name;\n};\n');
      }
    } else {
      compiler.internalError('unexpected kind: "${member.kind}"',
                             element: member);
    }
    emitExtraAccessors(member, attachTo, buffer);
  }

  bool generateFieldInits(ClassElement classElement,
                          StringBuffer argumentsBuffer,
                          StringBuffer bodyBuffer) {
    bool isFirst = true;
    do {
      // TODO(floitsch): make sure there are no name clashes.
      String className = namer.getName(classElement);

      void generateFieldInit(Element member) {
        if (member.isInstanceMember() && member.kind == ElementKind.FIELD) {
          if (!isFirst) argumentsBuffer.add(', ');
          isFirst = false;
          String memberName = namer.instanceFieldName(member.getLibrary(),
                                                      member.name);
          argumentsBuffer.add('${className}_$memberName');
          bodyBuffer.add('  this.$memberName = ${className}_$memberName;\n');
        }
      }

      for (Element element in classElement.members) {
        generateFieldInit(element);
      }
      for (Element element in classElement.backendMembers) {
        generateFieldInit(element);
      }

      classElement = classElement.superclass;
    } while(classElement !== null);
  }

  void emitInherits(ClassElement cls, StringBuffer buffer) {
    ClassElement superclass = cls.superclass;
    if (superclass !== null) {
      addInheritFunctionIfNecessary();
      String className = namer.isolatePropertyAccess(cls);
      String superName = namer.isolatePropertyAccess(superclass);
      buffer.add('${inheritsName}($className, $superName);\n');
    }
  }

  void ensureGenerated(ClassElement classElement, StringBuffer buffer) {
    if (classElement == null) return;
    if (generatedClasses.contains(classElement)) return;
    generatedClasses.add(classElement);
    generateClass(classElement, buffer);
  }

  void generateClass(ClassElement classElement, StringBuffer buffer) {
    ensureGenerated(classElement.superclass, buffer);

    if (classElement.isNative()) {
      nativeEmitter.generateNativeClass(classElement);
      return;
    } else {
      // TODO(ngeoffray): Instead of switching between buffer, we
      // should create code sections, and decide where to emit them at
      // the end.
      buffer = mainBuffer;
    }

    String className = namer.isolatePropertyAccess(classElement);
    String constructorName = namer.safeName(classElement.name.slowToString());
    buffer.add('$className = function $constructorName(');
    StringBuffer bodyBuffer = new StringBuffer();
    // If the class is never instantiated we still need to set it up for
    // inheritance purposes, but we can leave its JavaScript constructor empty.
    if (compiler.universe.instantiatedClasses.contains(classElement)) {
      generateFieldInits(classElement, buffer, bodyBuffer);
    }
    buffer.add(') {\n');
    buffer.add(bodyBuffer);
    buffer.add('};\n');

    emitInherits(classElement, buffer);

    String attachTo(String name) => '$className.prototype.$name';
    for (Element member in classElement.members) {
      if (member.isInstanceMember()) {
        addInstanceMember(member, attachTo, buffer);
      }
    }
    for (Element member in classElement.backendMembers) {
      if (member.isInstanceMember()) {
        addInstanceMember(member, attachTo, buffer);
      }
    }
    generateTypeTests(classElement, (Element other) {
      buffer.add('${attachTo(namer.operatorIs(other))} = ');
      if (nativeEmitter.requiresNativeIsCheck(other)) {
        buffer.add('function() { return true; }');
      } else {
        buffer.add('true');
      }
      buffer.add(';\n');
    });

    if (classElement === compiler.objectClass && compiler.enabledNoSuchMethod) {
      // Emit the noSuchMethods on the Object prototype now, so that
      // the code in the dynamicMethod can find them. Note that the
      // code in dynamicMethod is invoked before analyzing the full JS
      // script.
      emitNoSuchMethodCalls(buffer);
    }
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
    for (ClassElement element in compiler.universe.instantiatedClasses) {
      ensureGenerated(element, buffer);
    }
  }

  void emitStaticFunctionsWithNamer(StringBuffer buffer,
                                    Map<Element, String> generatedCode,
                                    String functionNamer(Element element)) {
    generatedCode.forEach((Element element, String codeBlock) {
      if (!element.isInstanceMember()) {
        buffer.add('${functionNamer(element)} = ');
        buffer.add(codeBlock);
        buffer.add(';\n\n');
      }
    });
  }

  void emitStaticFunctions(StringBuffer buffer) {
    emitStaticFunctionsWithNamer(buffer,
                                 compiler.universe.generatedCode,
                                 namer.isolatePropertyAccess);
    emitStaticFunctionsWithNamer(buffer,
                                 compiler.universe.generatedBailoutCode,
                                 namer.isolateBailoutPropertyAccess);
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
      String staticName = namer.isolatePropertyAccess(element);
      int parameterCount = element.parameterCount(compiler);
      String invocationName =
          namer.instanceMethodName(element.getLibrary(), callElement.name,
                                   parameterCount);
      buffer.add("$staticName.$invocationName = $staticName;\n");
      addParameterStubs(callElement, (name) => '$staticName.$name', buffer);
    }
  }

  void emitDynamicFunctionGetter(StringBuffer buffer,
                                 String attachTo(String invocationName),
                                 FunctionElement member) {
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
    String isolateAccess = namer.isolatePropertyAccess(closureClassElement);
    ensureGenerated(closureClassElement.superclass, buffer);

    // Define the constructor with a name so that Object.toString can
    // find the class name of the closure class.
    buffer.add("$isolateAccess = function $name(self) ");
    buffer.add("{ this.self = self; };\n");
    emitInherits(closureClassElement, buffer);

    String prototype = "$isolateAccess.prototype";

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
    buffer.add("$prototype.$invocationName = function($joinedArgs) {\n");
    buffer.add("  return this.self.$targetName($joinedArgs);\n");
    buffer.add("};\n");
    addParameterStubs(callElement,
                      (invocationName) => '$prototype.$invocationName',
                      buffer);

    // And finally the getter.
    String getterName = namer.getterName(member.getLibrary(), member.name);
    String closureClass = namer.isolateAccess(closureClassElement);
    buffer.add("${attachTo(getterName)} = function() {\n");
    buffer.add("  return new $closureClass(this);\n");
    buffer.add("};\n");
  }

  void emitCallStubForGetter(StringBuffer buffer,
                             String attachTo(String name),
                             Element member,
                             Set<Selector> selectors) {
    String getter;
    if (member.kind == ElementKind.GETTER) {
      getter = "this.${namer.getterName(member.getLibrary(), member.name)}()";
    } else {
      getter =
          "this.${namer.instanceFieldName(member.getLibrary(), member.name)}";
    }
    for (Selector selector in selectors) {
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
      buffer.add("${attachTo(invocationName)} = function($joined) {\n");
      buffer.add("  return $getter.$closureCallName($joined);\n");
      buffer.add("};\n");
    }
  }

  void emitStaticNonFinalFieldInitializations(StringBuffer buffer) {
    // Adds initializations inside the Isolate constructor.
    // Example:
    //    function Isolate() {
    //       this.staticNonFinal = Isolate.prototype.someVal;
    //       ...
    //    }
    ConstantHandler handler = compiler.constantHandler;
    List<VariableElement> staticNonFinalFields =
        handler.getStaticNonFinalFieldsForEmission();
    if (!staticNonFinalFields.isEmpty()) buffer.add('\n');
    for (Element element in staticNonFinalFields) {
      buffer.add('  this.${namer.getName(element)} = ');
      compiler.withCurrentElement(element, () {
          handler.writeJsCodeForVariable(buffer, element);
        });
      buffer.add(';\n');
    }
  }

  void emitCompileTimeConstants(StringBuffer buffer) {
    ConstantHandler handler = compiler.constantHandler;
    List<Constant> constants = handler.getConstantsForEmission();
    String prototype = "${namer.ISOLATE}.prototype";
    bool addedMakeConstantList = false;
    for (Constant constant in constants) {
      if (!addedMakeConstantList && constant.isList()) {
        addedMakeConstantList = true;
        emitMakeConstantList(prototype, buffer);
      }
      String name = handler.getNameForConstant(constant);
      buffer.add('$prototype.$name = ');
      handler.writeJsCode(buffer, constant);
      buffer.add(';\n');
    }
  }

  void emitMakeConstantList(String prototype, StringBuffer buffer) {
    buffer.add(prototype);
    buffer.add(@'''.makeConstantList = function(list) {
  list.immutable$list = true;
  list.fixed$length = true;
  return list;
};
''');
  }

  void emitStaticFinalFieldInitializations(StringBuffer buffer) {
    ConstantHandler handler = compiler.constantHandler;
    List<VariableElement> staticFinalFields =
        handler.getStaticFinalFieldsForEmission();
    for (VariableElement element in staticFinalFields) {
      buffer.add('${namer.isolatePropertyAccess(element)} = ');
      compiler.withCurrentElement(element, () {
          handler.writeJsCodeForVariable(buffer, element);
        });
      buffer.add(';\n');
    }
  }

  void emitExtraAccessors(Element member,
                          String attachTo(String name),
                          StringBuffer buffer) {
    if (member.kind == ElementKind.GETTER || member.kind == ElementKind.FIELD) {
      Set<Selector> selectors = compiler.universe.invokedNames[member.name];
      if (selectors !== null && !selectors.isEmpty()) {
        compiler.emitter.emitCallStubForGetter(
            buffer, attachTo, member, selectors);
      }
    } else if (member.kind == ElementKind.FUNCTION) {
      if (compiler.universe.invokedGetters.contains(member.name)) {
        compiler.emitter.emitDynamicFunctionGetter(
            buffer, attachTo, member);
      }
    }
  }

  void emitNoSuchMethodCalls(StringBuffer buffer) {
    // Do not generate no such method calls if there is no class.
    if (compiler.universe.instantiatedClasses.isEmpty()) return;

    ClassElement objectClass =
        compiler.coreLibrary.find(const SourceString('Object'));
    String className = namer.isolatePropertyAccess(objectClass);
    String prototype = '$className.prototype';
    String noSuchMethodName =
        namer.instanceMethodName(null, Compiler.NO_SUCH_METHOD, 2);
    Collection<LibraryElement> libraries =
        compiler.universe.libraries.getValues();

    void generateMethod(String methodName, String jsName, Selector selector) {
      buffer.add('$prototype.$jsName = function');
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
      buffer.add("      : $objectClassName.prototype.$noSuchMethodName.call(");
      buffer.add("this, '$methodName', [$args])\n");
      buffer.add('}\n');
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
              generateMethod(methodName.slowToString(), jsName, selector);
            }
          } else {
            String jsName =
              namer.instanceMethodInvocationName(null, methodName, selector);
            generateMethod(methodName.slowToString(), jsName, selector);
          }
        }
      }
    });

    compiler.universe.invokedGetters.forEach((SourceString getterName) {
      if (getterName.isPrivate()) {
        for (LibraryElement lib in libraries) {
          String jsName = namer.getterName(lib, getterName);
          generateMethod('get ${getterName.slowToString()}', jsName,
                         Selector.GETTER);
        }
      } else {
        String jsName = namer.getterName(null, getterName);
        generateMethod('get ${getterName.slowToString()}', jsName,
                       Selector.GETTER);
      }
    });

    compiler.universe.invokedSetters.forEach((SourceString setterName) {
      if (setterName.isPrivate()) {
        for (LibraryElement lib in libraries) {
          String jsName = namer.setterName(lib, setterName);
          generateMethod('set ${setterName.slowToString()}', jsName,
                         Selector.SETTER);
        }
      } else {
        String jsName = namer.setterName(null, setterName);
        generateMethod('set ${setterName.slowToString()}', jsName,
                       Selector.SETTER);
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
      mainBuffer.add('function ${namer.ISOLATE}() {');
      emitStaticNonFinalFieldInitializations(mainBuffer);
      mainBuffer.add('}\n\n');
      emitClasses(mainBuffer);
      emitStaticFunctions(mainBuffer);
      emitStaticFunctionGetters(mainBuffer);
      emitCompileTimeConstants(mainBuffer);
      emitStaticFinalFieldInitializations(mainBuffer);
      nativeEmitter.emitDynamicDispatchMetadata();
      mainBuffer.add(
          'var ${namer.CURRENT_ISOLATE} = new ${namer.ISOLATE}();\n');
      nativeEmitter.assembleCode(mainBuffer);
      emitMain(mainBuffer);
      compiler.assembledCode = mainBuffer.toString();
    });
    return compiler.assembledCode;
  }
}
