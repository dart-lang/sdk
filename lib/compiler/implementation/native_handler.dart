// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('native');
#import('dart:uri');
#import('leg.dart');
#import('elements/elements.dart');
#import('scanner/scannerlib.dart');
#import('ssa/ssa.dart');
#import('tree/tree.dart');
#import('util/util.dart');

void processNativeClasses(CodeEmitterTask emitter,
                          Collection<LibraryElement> libraries) {
  for (LibraryElement library in libraries) {
    processNativeClassesInLibrary(emitter, library);
  }
}

void addSubtypes(ClassElement cls,
                 NativeEmitter emitter) {
  for (Type type in cls.allSupertypes) {
    List<Element> subtypes = emitter.subtypes.putIfAbsent(
        type.element,
        () => <ClassElement>[]);
    subtypes.add(cls);
  }

  List<Element> directSubtypes = emitter.directSubtypes.putIfAbsent(
      cls.superclass,
      () => <ClassElement>[]);
  directSubtypes.add(cls);
}

void processNativeClassesInLibrary(CodeEmitterTask emitter,
                                   LibraryElement library) {
  bool hasNativeClass = false;
  final compiler = emitter.compiler;
  for (Link<Element> link = library.topLevelElements;
       !link.isEmpty(); link = link.tail) {
    Element element = link.head;
    if (element.kind == ElementKind.CLASS) {
      ClassElement classElement = element;
      if (classElement.isNative()) {
        hasNativeClass = true;
        compiler.registerInstantiatedClass(classElement);
        // Also parse the node to know all its methods because
        // otherwise it will only be parsed if there is a call to
        // one of its constructor.
        classElement.parseNode(compiler);
        // Resolve to setup the inheritance.
        classElement.ensureResolved(compiler);
        // Add the information that this class is a subtype of
        // its supertypes. The code emitter and the ssa builder use that
        // information.
        addSubtypes(classElement, emitter.nativeEmitter);
      }
    }
  }
  if (hasNativeClass) {
    final worlds = [compiler.enqueuer.resolution, compiler.enqueuer.codegen];
    for (var world in worlds) {
      world.registerStaticUse(compiler.findHelper(
          const SourceString('dynamicFunction')));
      world.registerStaticUse(compiler.findHelper(
          const SourceString('dynamicSetMetadata')));
      world.registerStaticUse(compiler.findHelper(
          const SourceString('defineProperty')));
      world.registerStaticUse(compiler.findHelper(
          const SourceString('toStringForNativeObject')));
    }
  }
}

void maybeEnableNative(Compiler compiler,
                       LibraryElement library,
                       Uri uri) {
  String libraryName = uri.toString();
  if (library.script.name.contains('dart/frog/tests/frog_native')
      || libraryName == 'dart:dom_deprecated'
      || libraryName == 'dart:isolate'
      || libraryName == 'dart:html') {
    library.define(new ForeignElement(
        const SourceString('native'), library), compiler);
    library.canUseNative = true;
  }

  // Additionaly, if this is a test, we allow access to foreign functions.
  if (library.script.name.contains('dart/frog/tests/frog_native')) {
    library.define(compiler.findHelper(const SourceString('JS')), compiler);
  }
}

void checkAllowedLibrary(ElementListener listener, Token token) {
  LibraryElement currentLibrary = listener.compilationUnitElement.getLibrary();
  if (!currentLibrary.canUseNative) {
    listener.recoverableError("Unexpected token", token: token);
  }
}

Token handleNativeBlockToSkip(Listener listener, Token token) {
  checkAllowedLibrary(listener, token);
  token = token.next;
  if (token.kind === STRING_TOKEN) {
    token = token.next;
  }
  if (token.stringValue === '{') {
    BeginGroupToken beginGroupToken = token;
    token = beginGroupToken.endGroup;
  }
  return token;
}

Token handleNativeClassBodyToSkip(Listener listener, Token token) {
  checkAllowedLibrary(listener, token);
  listener.handleIdentifier(token);
  token = token.next;
  if (token.kind !== STRING_TOKEN) {
    return listener.unexpected(token);
  }
  token = token.next;
  if (token.stringValue !== '{') {
    return listener.unexpected(token);
  }
  BeginGroupToken beginGroupToken = token;
  token = beginGroupToken.endGroup;
  return token;
}

Token handleNativeClassBody(Listener listener, Token token) {
  checkAllowedLibrary(listener, token);
  token = token.next;
  if (token.kind !== STRING_TOKEN) {
    listener.unexpected(token);
  } else {
    token = token.next;
  }
  return token;
}

RegExp nativeRedirectionRegExp = const RegExp(@'^[a-zA-Z][a-zA-Z_$0-9]*$');

Token handleNativeFunctionBody(ElementListener listener, Token token) {
  checkAllowedLibrary(listener, token);
  Token begin = token;
  listener.beginExpressionStatement(token);
  listener.handleIdentifier(token);
  token = token.next;
  if (token.kind === STRING_TOKEN) {
    listener.beginLiteralString(token);
    listener.endLiteralString(0);
    LiteralString str = listener.popNode();
    listener.pushNode(new NodeList.singleton(str));
    listener.endSend(token);
    token = token.next;
    // If this native method is just redirecting to another method,
    // we add a return node to match the SSA builder expectations.
    if (nativeRedirectionRegExp.hasMatch(str.dartString.slowToString())) {
      listener.endReturnStatement(true, begin, token);
    } else {
      listener.endExpressionStatement(token);
    }
  } else {
    listener.pushNode(new NodeList.empty());
    listener.endSend(token);
    listener.endReturnStatement(true, begin, token);
  }
  listener.endFunctionBody(1, begin, token);
  // TODO(ngeoffray): expect a ';'.
  return token.next;
}

SourceString checkForNativeClass(ElementListener listener) {
  SourceString nativeName;
  Node node = listener.nodes.head;
  if (node != null
      && node.asIdentifier() != null
      && node.asIdentifier().source.stringValue == 'native') {
    nativeName = node.asIdentifier().token.next.value;
    listener.popNode();
  }
  return nativeName;
}

bool isOverriddenMethod(FunctionElement element,
                        ClassElement cls,
                        NativeEmitter nativeEmitter) {
  List<ClassElement> subtypes = nativeEmitter.subtypes[cls];
  if (subtypes == null) return false;
  for (ClassElement subtype in subtypes) {
    if (subtype.lookupLocalMember(element.name) != null) return true;
  }
  return false;
}

void handleSsaNative(SsaBuilder builder, Send node) {
  Compiler compiler = builder.compiler;
  FunctionElement element = builder.work.element;
  element.setNative();
  NativeEmitter nativeEmitter = builder.emitter.nativeEmitter;
  // If what we're compiling is a getter named 'typeName' and the native
  // class is named 'DOMType', we generate a call to the typeNameOf
  // function attached on the isolate.
  // The DOM classes assume that their 'typeName' property, which is
  // not a JS property on the DOM types, returns the type name.
  if (element.name == const SourceString('typeName')
      && element.isGetter()
      && nativeEmitter.toNativeName(element.enclosingElement) == 'DOMType') {
    Element methodElement =
        compiler.findHelper(const SourceString('getTypeNameOf'));
    HStatic method = new HStatic(methodElement);
    builder.add(method);
    builder.push(new HInvokeStatic(Selector.INVOCATION_1,
        <HInstruction>[method, builder.localsHandler.readThis()]));
    return;
  }

  HInstruction convertDartClosure(Element parameter) {
    HInstruction local = builder.localsHandler.readLocal(parameter);
    // TODO(ngeoffray): by better analyzing the function type and
    // its formal parameters, we could pass a method with a defined arity.
    builder.push(new HStatic(builder.interceptors.getClosureConverter()));
    List<HInstruction> callInputs = <HInstruction>[builder.pop(), local];
    HInstruction closure = new HInvokeStatic(Selector.INVOCATION_1, callInputs);
    builder.add(closure);
    return closure;
  }


  // Check which pattern this native method follows:
  // 1) foo() native; hasBody = false, isRedirecting = false
  // 2) foo() native "bar"; hasBody = false, isRedirecting = true
  // 3) foo() native "return 42"; hasBody = true, isRedirecting = false
  bool hasBody = false;
  bool isRedirecting = false;
  String nativeMethodName = element.name.slowToString();
  if (!node.arguments.isEmpty()) {
    if (!node.arguments.tail.isEmpty()) {
      builder.compiler.cancel('More than one argument to native');
    }
    LiteralString jsCode = node.arguments.head;
    String str = jsCode.dartString.slowToString();
    if (nativeRedirectionRegExp.hasMatch(str)) {
      nativeMethodName = str;
      isRedirecting = true;
      nativeEmitter.addRedirectingMethod(element, nativeMethodName);
    } else {
      hasBody = true;
    }
  }

  if (!hasBody) {
    nativeEmitter.nativeMethods.add(element);
  }

  FunctionSignature parameters = element.computeSignature(builder.compiler);
  if (!hasBody) {
    List<String> arguments = <String>[];
    List<HInstruction> inputs = <HInstruction>[];
    String receiver = '';
    if (element.isInstanceMember()) {
      receiver = '#.';
      inputs.add(builder.localsHandler.readThis());
    }
    parameters.forEachParameter((Element parameter) {
      Type type = parameter.computeType(compiler);
      HInstruction input = builder.localsHandler.readLocal(parameter);
      if (type is FunctionType) input = convertDartClosure(parameter);
      inputs.add(input);
      arguments.add('#');
    });

    String foreignParameters = Strings.join(arguments, ',');
    String nativeMethodCall;
    if (element.kind == ElementKind.FUNCTION) {
      nativeMethodCall = '$receiver$nativeMethodName($foreignParameters)';
    } else if (element.kind == ElementKind.GETTER) {
      nativeMethodCall = '$receiver$nativeMethodName';
    } else if (element.kind == ElementKind.SETTER) {
      nativeMethodCall = '$receiver$nativeMethodName = $foreignParameters';
    } else {
      builder.compiler.internalError('unexpected kind: "${element.kind}"',
                                     element: element);
    }

    DartString jsCode = new DartString.literal(nativeMethodCall);
    builder.push(
        new HForeign(jsCode, const LiteralDartString('Object'), inputs));
  } else {
    // This is JS code written in a Dart file with the construct
    // native """ ... """;. It does not work well with mangling,
    // but there should currently be no clash between leg mangling
    // and the library where this construct is being used. This
    // mangling problem will go away once we switch these libraries
    // to use Leg's 'JS' function.
    parameters.forEachParameter((Element parameter) {
      Type type = parameter.computeType(compiler);
      if (type is FunctionType) {
        HInstruction jsClosure = convertDartClosure(parameter);
        // Because the JS code references the argument name directly,
        // we must keep the name and assign the JS closure to it.
        builder.add(new HForeign(
            new DartString.literal('${parameter.name.slowToString()} = #'),
            const LiteralDartString('void'),
            <HInstruction>[jsClosure]));
      }
    });
    LiteralString jsCode = node.arguments.head;
    builder.push(new HForeign(jsCode.dartString,
                              const LiteralDartString('Object'),
                              <HInstruction>[]));
  }
}

void generateMethodWithPrototypeCheckForElement(Compiler compiler,
                                                StringBuffer buffer,
                                                FunctionElement element,
                                                String code,
                                                String parameters) {
  String methodName;
  Namer namer = compiler.namer;
  if (element.kind == ElementKind.FUNCTION) {
    FunctionSignature signature = element.computeSignature(compiler);
    methodName = namer.instanceMethodName(
        element.getLibrary(), element.name, signature.parameterCount);
  } else if (element.kind == ElementKind.GETTER) {
    methodName = namer.getterName(element.getLibrary(), element.name);
  } else if (element.kind == ElementKind.SETTER) {
    methodName = namer.setterName(element.getLibrary(), element.name);
  } else {
    compiler.internalError('unexpected kind: "${element.kind}"',
                           element: element);
  }

  generateMethodWithPrototypeCheck(
      compiler, buffer, methodName, code, parameters);
}


// If a method is overridden, we must check if the prototype of
// 'this' has the method available. Otherwise, we may end up
// calling the method from the super class. If the method is not
// available, we make a direct call to Object.prototype.$methodName.
// This method will patch the prototype of 'this' to the real method.
void generateMethodWithPrototypeCheck(Compiler compiler,
                                      StringBuffer buffer,
                                      String methodName,
                                      String code,
                                      String parameters) {
  buffer.add("  if (Object.getPrototypeOf(this).hasOwnProperty");
  buffer.add("('$methodName')) {\n");
  buffer.add("  $code");
  buffer.add("  } else {\n");
  buffer.add("    return Object.prototype.$methodName.call(this");
  buffer.add(parameters == '' ? '' : ', $parameters');
  buffer.add(");\n");
  buffer.add("  }\n");
}
