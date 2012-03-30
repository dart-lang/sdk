// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('native');
#import('../../uri/uri.dart');
#import('leg.dart');
#import('elements/elements.dart');
#import('scanner/scannerlib.dart');
#import('ssa/ssa.dart');
#import('tree/tree.dart');
#import('util/util.dart');

void processNativeClasses(Compiler compiler,
                          Collection<LibraryElement> libraries) {
  for (LibraryElement library in libraries) {
    processNativeClassesInLibrary(compiler, library);
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
}

void processNativeClassesInLibrary(Compiler compiler,
                                   LibraryElement library) {
  bool hasNativeClass = false;
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
        NativeEmitter emitter = compiler.emitter.nativeEmitter;
        addSubtypes(classElement, emitter);
      }
    }
  }
  if (hasNativeClass) {
    compiler.registerStaticUse(compiler.findHelper(
        const SourceString('dynamicFunction')));
    compiler.registerStaticUse(compiler.findHelper(
        const SourceString('dynamicSetMetadata')));
    compiler.registerStaticUse(compiler.findHelper(
        const SourceString('defineProperty')));
    compiler.registerStaticUse(compiler.findHelper(
        const SourceString('toStringForNativeObject')));
  }
}

void maybeEnableNative(Compiler compiler,
                       LibraryElement library,
                       Uri uri) {
  String libraryName = uri.toString();
  if (library.script.name.contains('dart/frog/tests/native/src')
      || libraryName == 'dart:dom'
      || libraryName == 'dart:isolate'
      || libraryName == 'dart:html') {
    library.define(new ForeignElement(
        const SourceString('native'), library), compiler);
    library.canUseNative = true;
  }

  // Additionaly, if this is a test, we allow access to foreign functions.
  if (library.script.name.contains('dart/frog/tests/native/src')) {
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

Token handleNativeFunctionBody(ElementListener listener, Token token) {
  checkAllowedLibrary(listener, token);
  Token begin = token;
  listener.beginExpressionStatement(token);
  listener.handleIdentifier(token);
  token = token.next;
  if (token.kind === STRING_TOKEN) {
    listener.beginLiteralString(token);
    listener.endLiteralString(0);
    listener.pushNode(new NodeList.singleton(listener.popNode()));
    listener.endSend(token);
    token = token.next;
    listener.endExpressionStatement(token);
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
  NativeEmitter nativeEmitter = compiler.emitter.nativeEmitter;
  // If what we're compiling is a getter named 'typeName' and the native
  // class is named 'DOMType', we generate a call to the typeNameOf
  // function attached on the isolate.
  // The DOM classes assume that their 'typeName' property, which is
  // not a JS property on the DOM types, returns the type name.
  if (element.name == const SourceString('typeName')
      && element.isGetter()
      && nativeEmitter.toNativeName(element.enclosingElement) == 'DOMType') {
    Element element = compiler.findHelper(const SourceString('getTypeNameOf'));
    HStatic method = new HStatic(element);
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
    if (const RegExp(@'^[a-zA-Z][a-zA-Z_$0-9]*$').hasMatch(str)) {
      nativeMethodName = str;
      isRedirecting = true;
    } else {
      hasBody = true;
    }
  }

  FunctionParameters parameters = element.computeParameters(builder.compiler);
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

    String dartMethodName;
    String nativeMethodCall;

    if (element.kind == ElementKind.FUNCTION) {
      dartMethodName = builder.compiler.namer.instanceMethodName(
          element.getLibrary(), element.name, parameters.parameterCount);
      nativeMethodCall = '$receiver$nativeMethodName($foreignParameters)';
    } else if (element.kind == ElementKind.GETTER) {
      dartMethodName = builder.compiler.namer.getterName(
          element.getLibrary(), element.name);
      nativeMethodCall = '$receiver$nativeMethodName';
    } else if (element.kind == ElementKind.SETTER) {
      dartMethodName = builder.compiler.namer.setterName(
          element.getLibrary(), element.name);
      nativeMethodCall = '$receiver$nativeMethodName = $foreignParameters';
    } else {
      builder.compiler.internalError('unexpected kind: "${element.kind}"',
                                     element: element);
    }

    HInstruction thenInstruction;
    void visitThen() {
      DartString jsCode = new DartString.literal(nativeMethodCall);
      thenInstruction =
          new HForeign(jsCode, const LiteralDartString('Object'), inputs);
      builder.add(thenInstruction);
    }

    bool isNativeLiteral = false;
    bool isOverridden = false;
    NativeEmitter nativeEmitter = builder.compiler.emitter.nativeEmitter;
    if (element.enclosingElement.kind == ElementKind.CLASS) {
      ClassElement classElement = element.enclosingElement;
      String nativeName = classElement.nativeName.slowToString();
      isNativeLiteral = nativeEmitter.isNativeLiteral(nativeName);
      isOverridden = isOverriddenMethod(element, classElement, nativeEmitter);
    }
    if (!element.isInstanceMember() || isNativeLiteral || !isOverridden) {
      // We generate a direct call to the native method.
      visitThen();
      builder.stack.add(thenInstruction);
    } else {
      // Record that this method is overridden. In case of optional
      // arguments, the emitter will generate stubs to handle them,
      // and needs to know if the method is overridden.
      nativeEmitter.overriddenMethods.add(element);

      // If the method is an instance method that is overridden, we
      // generate the following code:
      // function(params) {
      //   return Object.getPrototypeOf(this).hasOwnProperty(dartMethodName))
      //      ? this.methodName(params)
      //      : Object.prototype.methodName.call(this, params);
      // }
      //
      // The property check at the beginning is to make sure we won't
      // call the method from the super class, in case the prototype of
      // 'this' does not have the method yet.
      HInstruction elseInstruction;
      void visitElse() {
        String params = arguments.isEmpty() ? '' : ', $foreignParameters';
        DartString jsCode = new DartString.literal(
            'Object.prototype.$dartMethodName.call(#$params)');
        elseInstruction =
            new HForeign(jsCode, const LiteralDartString('Object'), inputs);
        builder.add(elseInstruction);
      }

      HConstant constant = builder.graph.addConstantString(
          new DartString.literal('$dartMethodName'));
      DartString jsCode = new DartString.literal(
          'Object.getPrototypeOf(#).hasOwnProperty(#)');
      builder.push(new HForeign(
          jsCode, const LiteralDartString('Object'),
          <HInstruction>[builder.localsHandler.readThis(), constant]));

      builder.handleIf(visitThen, visitElse);

      HPhi phi = new HPhi.manyInputs(
          null, <HInstruction>[thenInstruction, elseInstruction]);
      builder.current.addPhi(phi);
      builder.stack.add(phi);
    }
    if (isRedirecting) {
      // The parser creates a return node if there is no string literal
      // after the native keyword. In case of a redirecting method, there
      // is a string literal, therefore we must emit a return instruction
      // in the builder.
      builder.push(new HReturn(builder.pop()));
    }
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
