// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class ClassStubGenerator {
  final Namer namer;
  final Compiler compiler;
  final JavaScriptBackend backend;

  ClassStubGenerator(this.compiler, this.namer, this.backend);

  jsAst.Expression generateClassConstructor(ClassElement classElement,
                                            Iterable<String> fields) {
    // TODO(sra): Implement placeholders in VariableDeclaration position:
    //
    //     String constructorName = namer.getNameOfClass(classElement);
    //     return js.statement('function #(#) { #; }',
    //        [ constructorName, fields,
    //            fields.map(
    //                (name) => js('this.# = #', [name, name]))]));
    return js('function(#) { #; this.#();}',
        [fields,
         fields.map((name) => js('this.# = #', [name, name])),
         namer.deferredAction]);
  }

  jsAst.Expression generateGetter(Element member, String fieldName) {
    ClassElement cls = member.enclosingClass;
    String receiver = backend.isInterceptorClass(cls) ? 'receiver' : 'this';
    List<String> args = backend.isInterceptedMethod(member) ? ['receiver'] : [];
    return js('function(#) { return #.# }', [args, receiver, fieldName]);
  }

  jsAst.Expression generateSetter(Element member, String fieldName) {
    ClassElement cls = member.enclosingClass;
    String receiver = backend.isInterceptorClass(cls) ? 'receiver' : 'this';
    List<String> args = backend.isInterceptedMethod(member) ? ['receiver'] : [];
    // TODO(floitsch): remove 'return'?
    return js('function(#, v) { return #.# = v; }',
        [args, receiver, fieldName]);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [member] must be a declaration element.
   */
  Map<String, jsAst.Expression> generateCallStubsForGetter(
      Element member, Set<Selector> selectors) {
    assert(invariant(member, member.isDeclaration));

    // If the method is intercepted, the stub gets the
    // receiver explicitely and we need to pass it to the getter call.
    bool isInterceptedMethod = backend.isInterceptedMethod(member);
    bool isInterceptorClass =
        backend.isInterceptorClass(member.enclosingClass);

    const String receiverArgumentName = r'$receiver';

    jsAst.Expression buildGetter() {
      jsAst.Expression receiver =
          js(isInterceptorClass ? receiverArgumentName : 'this');
      if (member.isGetter) {
        String getterName = namer.getterForElement(member);
        if (isInterceptedMethod) {
          return js('this.#(#)', [getterName, receiver]);
        }
        return js('#.#()', [receiver, getterName]);
      } else {
        String fieldName = namer.instanceFieldPropertyName(member);
        return js('#.#', [receiver, fieldName]);
      }
    }

    Map<String, jsAst.Expression> generatedStubs = <String, jsAst.Expression>{};

    // Two selectors may match but differ only in type.  To avoid generating
    // identical stubs for each we track untyped selectors which already have
    // stubs.
    Set<Selector> generatedSelectors = new Set<Selector>();
    for (Selector selector in selectors) {
      if (selector.applies(member, compiler.world)) {
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
          arguments.add(js('#', name));
        }

        jsAst.Fun function = js(
            'function(#) { return #.#(#); }',
            [ parameters, buildGetter(), closureCallName, arguments]);

        generatedStubs[invocationName] = function;
      }
    }

    return generatedStubs;
  }

  Map<String, Selector> computeSelectorsForNsmHandlers() {

    Map<String, Selector> jsNames = <String, Selector>{};

    // Do not generate no such method handlers if there is no class.
    if (compiler.codegenWorld.directlyInstantiatedClasses.isEmpty) {
      return jsNames;
    }

    void addNoSuchMethodHandlers(String ignore, Set<Selector> selectors) {
      TypeMask objectSubclassTypeMask =
          new TypeMask.subclass(compiler.objectClass, compiler.world);

      for (Selector selector in selectors) {
        TypeMask mask = selector.mask;
        if (mask == null) mask = objectSubclassTypeMask;

        if (!mask.needsNoSuchMethodHandling(selector, compiler.world)) {
          continue;
        }
        String jsName = namer.invocationMirrorInternalName(selector);
        jsNames[jsName] = selector;
      }
    }

    compiler.codegenWorld.invokedNames.forEach(addNoSuchMethodHandlers);
    compiler.codegenWorld.invokedGetters.forEach(addNoSuchMethodHandlers);
    compiler.codegenWorld.invokedSetters.forEach(addNoSuchMethodHandlers);
    return jsNames;
  }

  StubMethod generateStubForNoSuchMethod(String name, Selector selector) {
    // Values match JSInvocationMirror in js-helper library.
    int type = selector.invocationMirrorKind;
    List<String> parameterNames =
        new List.generate(selector.argumentCount, (i) => '\$$i');

    List<jsAst.Expression> argNames =
        selector.callStructure.getOrderedNamedArguments().map((String name) =>
            js.string(name)).toList();

    String methodName = selector.invocationMirrorMemberName;
    String internalName = namer.invocationMirrorInternalName(selector);

    assert(backend.isInterceptedName(Compiler.NO_SUCH_METHOD));
    jsAst.Expression expression =
        js('''this.#noSuchMethodName(this,
                    #createInvocationMirror(#methodName,
                                            #internalName,
                                            #type,
                                            #arguments,
                                            #namedArguments))''',
           {'noSuchMethodName': namer.noSuchMethodName,
            'createInvocationMirror':
                backend.emitter.staticFunctionAccess(
                    backend.getCreateInvocationMirror()),
            'methodName':
                js.string(compiler.enableMinification
                    ? internalName : methodName),
            'internalName': js.string(internalName),
            'type': js.number(type),
            'arguments':
                new jsAst.ArrayInitializer(parameterNames.map(js).toList()),
            'namedArguments': new jsAst.ArrayInitializer(argNames)});

    jsAst.Expression function;
    if (backend.isInterceptedName(selector.name)) {
      function = js(r'function($receiver, #) { return # }',
                              [parameterNames, expression]);
    } else {
      function = js(r'function(#) { return # }', [parameterNames, expression]);
    }
    return new StubMethod(name, function);
  }
}

/// Creates two JavaScript functions: `tearOffGetter` and `tearOff`.
///
/// `tearOffGetter` is internal and only used by `tearOff`.
///
/// `tearOff` takes the following arguments:
///   * `funcs`: a list of functions. These are the functions representing the
///    member that is torn off. There can be more than one, since a member
///    can have several stubs.
///    Each function must have the `$callName` property set.
///   * `reflectionInfo`: contains reflective information, and the function
///    type. TODO(floitsch): point to where this is specified.
///   * `isStatic`.
///   * `name`.
///   * `isIntercepted.
List<jsAst.Statement> buildTearOffCode(JavaScriptBackend backend) {
  Namer namer = backend.namer;
  Compiler compiler = backend.compiler;

  Element closureFromTearOff = backend.findHelper('closureFromTearOff');
  String tearOffAccessText;
  jsAst.Expression tearOffAccessExpression;
  String tearOffGlobalObjectName;
  String tearOffGlobalObject;
  if (closureFromTearOff != null) {
    // We need both the AST that references [closureFromTearOff] and a string
    // for the NoCsp version that constructs a function.
    tearOffAccessExpression =
        backend.emitter.staticFunctionAccess(closureFromTearOff);
    tearOffAccessText =
        jsAst.prettyPrint(tearOffAccessExpression, compiler).getText();
    tearOffGlobalObjectName = tearOffGlobalObject =
        namer.globalObjectFor(closureFromTearOff);
  } else {
    // Default values for mocked-up test libraries.
    tearOffAccessText =
        r'''function() { throw 'Helper \'closureFromTearOff\' missing.' }''';
    tearOffAccessExpression = js(tearOffAccessText);
    tearOffGlobalObjectName = 'MissingHelperFunction';
    tearOffGlobalObject = '($tearOffAccessText())';
  }

  jsAst.Statement tearOffGetter;
  if (!compiler.useContentSecurityPolicy) {
    // This template is uncached because it is constructed from code fragments
    // that can change from compilation to compilation.  Some of these could be
    // avoided, except for the string literals that contain the compiled access
    // path to 'closureFromTearOff'.
    tearOffGetter = js.uncachedStatementTemplate('''
function tearOffGetter(funcs, reflectionInfo, name, isIntercepted) {
  return isIntercepted
      ? new Function("funcs", "reflectionInfo", "name",
                     "$tearOffGlobalObjectName", "c",
          "return function tearOff_" + name + (functionCounter++) + "(x) {" +
            "if (c === null) c = $tearOffAccessText(" +
                "this, funcs, reflectionInfo, false, [x], name);" +
                "return new c(this, funcs[0], x, name);" +
                "}")(funcs, reflectionInfo, name, $tearOffGlobalObject, null)
      : new Function("funcs", "reflectionInfo", "name",
                     "$tearOffGlobalObjectName", "c",
          "return function tearOff_" + name + (functionCounter++)+ "() {" +
            "if (c === null) c = $tearOffAccessText(" +
                "this, funcs, reflectionInfo, false, [], name);" +
                "return new c(this, funcs[0], null, name);" +
                "}")(funcs, reflectionInfo, name, $tearOffGlobalObject, null);
}''').instantiate([]);
  } else {
    tearOffGetter = js.statement('''
      function tearOffGetter(funcs, reflectionInfo, name, isIntercepted) {
        var cache = null;
        return isIntercepted
            ? function(x) {
                if (cache === null) cache = #(
                    this, funcs, reflectionInfo, false, [x], name);
                return new cache(this, funcs[0], x, name);
              }
            : function() {
                if (cache === null) cache = #(
                    this, funcs, reflectionInfo, false, [], name);
                return new cache(this, funcs[0], null, name);
              };
      }''', [tearOffAccessExpression, tearOffAccessExpression]);
  }

  jsAst.Statement tearOff = js.statement('''
    function tearOff(funcs, reflectionInfo, isStatic, name, isIntercepted) {
      var cache;
      return isStatic
          ? function() {
              if (cache === void 0) cache = #tearOff(
                  this, funcs, reflectionInfo, true, [], name).prototype;
              return cache;
            }
          : tearOffGetter(funcs, reflectionInfo, name, isIntercepted);
    }''',  {'tearOff': tearOffAccessExpression});

  return <jsAst.Statement>[tearOffGetter, tearOff];
}
