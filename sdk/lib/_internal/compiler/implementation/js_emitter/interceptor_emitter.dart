// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class InterceptorEmitter extends CodeEmitterHelper {
  final Set<String> interceptorInvocationNames = new Set<String>();

  void recordMangledNameOfMemberMethod(FunctionElement member, String name) {
    if (backend.isInterceptedMethod(member)) {
      interceptorInvocationNames.add(name);
    }
  }

  Set<ClassElement> interceptorsReferencedFromConstants() {
    Set<ClassElement> classes = new Set<ClassElement>();
    ConstantHandler handler = compiler.constantHandler;
    List<Constant> constants = handler.getConstantsForEmission();
    for (Constant constant in constants) {
      if (constant is InterceptorConstant) {
        InterceptorConstant interceptorConstant = constant;
        classes.add(interceptorConstant.dispatchedType.element);
      }
    }
    return classes;
  }

  void emitGetInterceptorMethod(CodeBuffer buffer,
                                String key,
                                Set<ClassElement> classes) {
    jsAst.Statement buildReturnInterceptor(ClassElement cls) {
      return js.return_(js(namer.isolateAccess(cls))['prototype']);
    }

    /**
     * Build a JavaScrit AST node for doing a type check on
     * [cls]. [cls] must be an interceptor class.
     */
    jsAst.Statement buildInterceptorCheck(ClassElement cls) {
      jsAst.Expression condition;
      assert(backend.isInterceptorClass(cls));
      if (cls == backend.jsBoolClass) {
        condition = js('(typeof receiver) == "boolean"');
      } else if (cls == backend.jsIntClass ||
                 cls == backend.jsDoubleClass ||
                 cls == backend.jsNumberClass) {
        throw 'internal error';
      } else if (cls == backend.jsArrayClass ||
                 cls == backend.jsMutableArrayClass ||
                 cls == backend.jsFixedArrayClass ||
                 cls == backend.jsExtendableArrayClass) {
        condition = js('receiver.constructor == Array');
      } else if (cls == backend.jsStringClass) {
        condition = js('(typeof receiver) == "string"');
      } else if (cls == backend.jsNullClass) {
        condition = js('receiver == null');
      } else {
        throw 'internal error';
      }
      return js.if_(condition, buildReturnInterceptor(cls));
    }

    bool hasArray = false;
    bool hasBool = false;
    bool hasDouble = false;
    bool hasInt = false;
    bool hasNull = false;
    bool hasNumber = false;
    bool hasString = false;
    bool hasNative = false;
    bool anyNativeClasses = compiler.enqueuer.codegen.nativeEnqueuer
          .hasInstantiatedNativeClasses();

    for (ClassElement cls in classes) {
      if (cls == backend.jsArrayClass ||
          cls == backend.jsMutableArrayClass ||
          cls == backend.jsFixedArrayClass ||
          cls == backend.jsExtendableArrayClass) hasArray = true;
      else if (cls == backend.jsBoolClass) hasBool = true;
      else if (cls == backend.jsDoubleClass) hasDouble = true;
      else if (cls == backend.jsIntClass) hasInt = true;
      else if (cls == backend.jsNullClass) hasNull = true;
      else if (cls == backend.jsNumberClass) hasNumber = true;
      else if (cls == backend.jsStringClass) hasString = true;
      else {
        // The set of classes includes classes mixed-in to interceptor classes
        // and user extensions of native classes.
        //
        // The set of classes also includes the 'primitive' interceptor
        // PlainJavaScriptObject even when it has not been resolved, since it is
        // only resolved through the reference in getNativeInterceptor when
        // getNativeInterceptor is marked as used.  Guard against probing
        // unresolved PlainJavaScriptObject by testing for anyNativeClasses.

        if (anyNativeClasses) {
          if (Elements.isNativeOrExtendsNative(cls)) hasNative = true;
        }
      }
    }
    if (hasDouble) {
      hasNumber = true;
    }
    if (hasInt) hasNumber = true;

    if (classes.containsAll(backend.interceptedClasses)) {
      // I.e. this is the general interceptor.
      hasNative = anyNativeClasses;
    }

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
        jsAst.Expression isInt = js('Math.floor(receiver) == receiver');
        whenNumber = js.block([
            js.if_(isInt, buildReturnInterceptor(backend.jsIntClass)),
            returnNumberClass]);
      } else {
        whenNumber = returnNumberClass;
      }
      block.statements.add(
          js.if_('(typeof receiver) == "number"',
                 whenNumber));
    }

    if (hasString) {
      block.statements.add(buildInterceptorCheck(backend.jsStringClass));
    }
    if (hasNull) {
      block.statements.add(buildInterceptorCheck(backend.jsNullClass));
    } else {
      // Returning "undefined" or "null" here will provoke a JavaScript
      // TypeError which is later identified as a null-error by
      // [unwrapException] in js_helper.dart.
      block.statements.add(js.if_('receiver == null',
                                  js.return_(js('receiver'))));
    }
    if (hasBool) {
      block.statements.add(buildInterceptorCheck(backend.jsBoolClass));
    }
    // TODO(ahe): It might be faster to check for Array before
    // function and bool.
    if (hasArray) {
      block.statements.add(buildInterceptorCheck(backend.jsArrayClass));
    }

    if (hasNative) {
      block.statements.add(
          js.if_(
              js('(typeof receiver) != "object"'),
              js.return_(js('receiver'))));

      // if (receiver instanceof $.Object) return receiver;
      // return $.getNativeInterceptor(receiver);
      block.statements.add(
          js.if_(js('receiver instanceof #',
                    js(namer.isolateAccess(compiler.objectClass))),
                 js.return_(js('receiver'))));
      block.statements.add(
          js.return_(
              js(namer.isolateAccess(backend.getNativeInterceptorMethod))(
                  ['receiver'])));

    } else {
      ClassElement jsUnknown = backend.jsUnknownJavaScriptObjectClass;
      if (compiler.codegenWorld.instantiatedClasses.contains(jsUnknown)) {
        block.statements.add(
            js.if_(js('!(receiver instanceof #)',
                      js(namer.isolateAccess(compiler.objectClass))),
                   buildReturnInterceptor(jsUnknown)));
      }

      block.statements.add(js.return_(js('receiver')));
    }

    buffer.write(jsAst.prettyPrint(
        js('${namer.globalObjectFor(compiler.interceptorsLibrary)}.$key = #',
           js.fun(['receiver'], block)),
        compiler));
    buffer.write(N);
  }

  /**
   * Emit all versions of the [:getInterceptor:] method.
   */
  void emitGetInterceptorMethods(CodeBuffer buffer) {
    task.addComment('getInterceptor methods', buffer);
    Map<String, Set<ClassElement>> specializedGetInterceptors =
        backend.specializedGetInterceptors;
    for (String name in specializedGetInterceptors.keys.toList()..sort()) {
      Set<ClassElement> classes = specializedGetInterceptors[name];
      emitGetInterceptorMethod(buffer, name, classes);
    }
  }

  // Returns a statement that takes care of performance critical
  // common case for a one-shot interceptor, or null if there is no
  // fast path.
  jsAst.Statement fastPathForOneShotInterceptor(Selector selector,
                                                Set<ClassElement> classes) {
    jsAst.Expression isNumber(String variable) {
      return js('typeof $variable == "number"');
    }

    jsAst.Expression isNotObject(String variable) {
      return js('typeof $variable != "object"');
    }

    jsAst.Expression isInt(String variable) {
      return isNumber(variable).binary('&&',
          js('Math.floor($variable) == $variable'));
    }

    jsAst.Expression tripleShiftZero(jsAst.Expression receiver) {
      return receiver.binary('>>>', js('0'));
    }

    if (selector.isOperator()) {
      String name = selector.name;
      if (name == '==') {
        // Unfolds to:
        //    if (receiver == null) return a0 == null;
        //    if (typeof receiver != 'object') {
        //      return a0 != null && receiver === a0;
        //    }
        List<jsAst.Statement> body = <jsAst.Statement>[];
        body.add(js.if_('receiver == null', js.return_(js('a0 == null'))));
        body.add(js.if_(
            isNotObject('receiver'),
            js.return_(js('a0 != null && receiver === a0'))));
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
        if (name == '~/' || name == '<<' || name == '%' || name == '>>') {
          return null;
        }
        jsAst.Expression result = js('receiver').binary(name, js('a0'));
        if (name == '&' || name == '|' || name == '^') {
          result = tripleShiftZero(result);
        }
        // Unfolds to:
        //    if (typeof receiver == "number" && typeof a0 == "number")
        //      return receiver op a0;
        return js.if_(
            isNumber('receiver').binary('&&', isNumber('a0')),
            js.return_(result));
      } else if (name == 'unary-') {
        // [: if (typeof receiver == "number") return -receiver :].
        return js.if_(isNumber('receiver'),
                      js.return_(js('-receiver')));
      } else {
        assert(name == '~');
        return js.if_(isInt('receiver'),
                      js.return_(js('~receiver >>> 0')));
      }
    } else if (selector.isIndex() || selector.isIndexSet()) {
      // For an index operation, this code generates:
      //
      //    if (receiver.constructor == Array || typeof receiver == "string") {
      //      if (a0 >>> 0 === a0 && a0 < receiver.length) {
      //        return receiver[a0];
      //      }
      //    }
      //
      // For an index set operation, this code generates:
      //
      //    if (receiver.constructor == Array && !receiver.immutable$list) {
      //      if (a0 >>> 0 === a0 && a0 < receiver.length) {
      //        return receiver[a0] = a1;
      //      }
      //    }
      bool containsArray = classes.contains(backend.jsArrayClass);
      bool containsString = classes.contains(backend.jsStringClass);
      bool containsJsIndexable = classes.any((cls) {
        return compiler.world.isSubtype(
            backend.jsIndexingBehaviorInterface, cls);
      });
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
      jsAst.Expression isIntAndAboveZero = js('a0 >>> 0 === a0');
      jsAst.Expression belowLength = js('a0 < receiver.length');
      jsAst.Expression arrayCheck = js('receiver.constructor == Array');
      jsAst.Expression indexableCheck =
          backend.generateIsJsIndexableCall(js('receiver'), js('receiver'));

      jsAst.Expression orExp(left, right) {
        return left == null ? right : left.binary('||', right);
      }

      if (selector.isIndex()) {
        jsAst.Expression stringCheck = js('typeof receiver == "string"');
        jsAst.Expression typeCheck;
        if (containsArray) {
          typeCheck = arrayCheck;
        }

        if (containsString) {
          typeCheck = orExp(typeCheck, stringCheck);
        }

        if (containsJsIndexable) {
          typeCheck = orExp(typeCheck, indexableCheck);
        }

        return js.if_(typeCheck,
                      js.if_(isIntAndAboveZero.binary('&&', belowLength),
                             js.return_(js('receiver[a0]'))));
      } else {
        jsAst.Expression typeCheck;
        if (containsArray) {
          typeCheck = arrayCheck;
        }

        if (containsJsIndexable) {
          typeCheck = orExp(typeCheck, indexableCheck);
        }

        jsAst.Expression isImmutableArray = typeCheck.binary(
            '&&', js(r'!receiver.immutable$list'));
        return js.if_(isImmutableArray.binary(
                      '&&', isIntAndAboveZero.binary('&&', belowLength)),
                      js.return_(js('receiver[a0] = a1')));
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
      arguments.add(js('receiver'));

      if (selector.isSetter()) {
        parameters.add(new jsAst.Parameter('value'));
        arguments.add(js('value'));
      } else {
        for (int i = 0; i < selector.argumentCount; i++) {
          String argName = 'a$i';
          parameters.add(new jsAst.Parameter(argName));
          arguments.add(js(argName));
        }
      }

      List<jsAst.Statement> body = <jsAst.Statement>[];
      jsAst.Statement optimizedPath =
          fastPathForOneShotInterceptor(selector, classes);
      if (optimizedPath != null) {
        body.add(optimizedPath);
      }

      String invocationName = backend.namer.invocationName(selector);
      String globalObject = namer.globalObjectFor(compiler.interceptorsLibrary);
      body.add(js.return_(
          js(globalObject)[getInterceptorName]('receiver')[invocationName](
              arguments)));

      jsAst.Expression assignment =
          js('${globalObject}.$name = #', js.fun(parameters, body));

      buffer.write(jsAst.prettyPrint(assignment, compiler));
      buffer.write(N);
    }
  }

  /**
   * If [JSInvocationMirror._invokeOn] has been compiled, emit all the
   * possible selector names that are intercepted into the
   * [interceptedNames] top-level variable. The implementation of
   * [_invokeOn] will use it to determine whether it should call the
   * method with an extra parameter.
   */
  void emitInterceptedNames(CodeBuffer buffer) {
    // TODO(ahe): We should not generate the list of intercepted names at
    // compile time, it can be generated automatically at runtime given
    // subclasses of Interceptor (which can easily be identified).
    if (!compiler.enabledInvokeOn) return;

    // TODO(ahe): We should roll this into
    // [emitStaticNonFinalFieldInitializations].
    String name = backend.namer.getNameOfGlobalField(backend.interceptedNames);

    int index = 0;
    var invocationNames = interceptorInvocationNames.toList()..sort();
    List<jsAst.ArrayElement> elements = invocationNames.map(
      (String invocationName) {
        jsAst.Literal str = js.string(invocationName);
        return new jsAst.ArrayElement(index++, str);
      }).toList();
    jsAst.ArrayInitializer array =
        new jsAst.ArrayInitializer(invocationNames.length, elements);

    jsAst.Expression assignment =
        js('${task.isolateProperties}.$name = #', array);

    buffer.write(jsAst.prettyPrint(assignment, compiler));
    buffer.write(N);
  }

  /**
   * Emit initializer for [mapTypeToInterceptor] data structure used by
   * [findInterceptorForType].  See declaration of [mapTypeToInterceptor] in
   * `interceptors.dart`.
   */
  void emitMapTypeToInterceptor(CodeBuffer buffer) {
    // TODO(sra): Perhaps inject a constant instead?
    CustomElementsAnalysis analysis = backend.customElementsAnalysis;
    if (!analysis.needsTable) return;

    List<jsAst.Expression> elements = <jsAst.Expression>[];
    ConstantHandler handler = compiler.constantHandler;
    List<Constant> constants =
        handler.getConstantsForEmission(task.compareConstants);
    for (Constant constant in constants) {
      if (constant is TypeConstant) {
        TypeConstant typeConstant = constant;
        Element element = typeConstant.representedType.element;
        if (element is ClassElement) {
          ClassElement classElement = element;
          if (!analysis.needsClass(classElement)) continue;

          elements.add(backend.emitter.constantReference(constant));
          elements.add(js(namer.isolateAccess(classElement)));

          // Create JavaScript Object map for by-name lookup of generative
          // constructors.  For example, the class A has three generative
          // constructors
          //
          //     class A {
          //       A() {}
          //       A.foo() {}
          //       A.bar() {}
          //     }
          //
          // Which are described by the map
          //
          //     {"": A.A$, "foo": A.A$foo, "bar": A.A$bar}
          //
          // We expect most of the time the map will be a singleton.
          var properties = [];
          for (Element member in analysis.constructors(classElement)) {
            properties.add(
                new jsAst.Property(
                    js.string(member.name),
                    new jsAst.VariableUse(
                        backend.namer.isolateAccess(member))));
          }

          var map = new jsAst.ObjectInitializer(properties);
          elements.add(map);
        }
      }
    }

    jsAst.ArrayInitializer array = new jsAst.ArrayInitializer.from(elements);
    String name =
        backend.namer.getNameOfGlobalField(backend.mapTypeToInterceptor);
    jsAst.Expression assignment =
        js('${task.isolateProperties}.$name = #', array);

    buffer.write(jsAst.prettyPrint(assignment, compiler));
    buffer.write(N);
  }
}
