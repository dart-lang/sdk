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

  void emitGetInterceptorMethod(CodeBuffer buffer,
                                String key,
                                Set<ClassElement> classes) {
    jsAst.Expression interceptorFor(ClassElement cls) {
      return js('#.prototype', namer.elementAccess(cls));
    }

    /**
     * Build a JavaScrit AST node for doing a type check on
     * [cls]. [cls] must be a non-native interceptor class.
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
      return js.statement('if (#) return #', [condition, interceptorFor(cls)]);
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

    List<jsAst.Statement> statements = <jsAst.Statement>[];

    if (hasNumber) {
      jsAst.Statement whenNumber;

      /// Note: there are two number classes in play: Dart's [num],
      /// and JavaScript's Number (typeof receiver == 'number').  This
      /// is the fallback used when we have determined that receiver
      /// is a JavaScript Number.
      jsAst.Expression interceptorForNumber = interceptorFor(
          hasDouble ? backend.jsDoubleClass : backend.jsNumberClass);

      if (hasInt) {
        whenNumber = js.statement('''{
            if (Math.floor(receiver) == receiver) return #;
            return #;
        }''', [interceptorFor(backend.jsIntClass), interceptorForNumber]);
      } else {
        whenNumber = js.statement('return #', interceptorForNumber);
      }
      statements.add(
          js.statement('if (typeof receiver == "number") #;', whenNumber));
    }

    if (hasString) {
      statements.add(buildInterceptorCheck(backend.jsStringClass));
    }
    if (hasNull) {
      statements.add(buildInterceptorCheck(backend.jsNullClass));
    } else {
      // Returning "undefined" or "null" here will provoke a JavaScript
      // TypeError which is later identified as a null-error by
      // [unwrapException] in js_helper.dart.
      statements.add(
          js.statement('if (receiver == null) return receiver'));
    }
    if (hasBool) {
      statements.add(buildInterceptorCheck(backend.jsBoolClass));
    }
    // TODO(ahe): It might be faster to check for Array before
    // function and bool.
    if (hasArray) {
      statements.add(buildInterceptorCheck(backend.jsArrayClass));
    }

    if (hasNative) {
      statements.add(js.statement(r'''{
          if (typeof receiver != "object") return receiver;
          if (receiver instanceof #) return receiver;
          return #(receiver);
      }''', [
          namer.elementAccess(compiler.objectClass),
          namer.elementAccess(backend.getNativeInterceptorMethod)]));

    } else {
      ClassElement jsUnknown = backend.jsUnknownJavaScriptObjectClass;
      if (compiler.codegenWorld
              .directlyInstantiatedClasses.contains(jsUnknown)) {
        statements.add(
            js.statement('if (!(receiver instanceof #)) return #;',
                [namer.elementAccess(compiler.objectClass),
                 interceptorFor(jsUnknown)]));
      }

      statements.add(js.statement('return receiver'));
    }

    buffer.write(jsAst.prettyPrint(
        js('''${namer.globalObjectFor(backend.interceptorsLibrary)}.# =
              function(receiver) { #; }''',
            [key, statements]),
        compiler));
    buffer.write(N);
  }

  /**
   * Emit all versions of the [:getInterceptor:] method.
   */
  void emitGetInterceptorMethods(CodeBuffer buffer) {
    emitter.addComment('getInterceptor methods', buffer);
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

    if (selector.isOperator) {
      String name = selector.name;
      if (name == '==') {
        return js.statement('''{
          if (receiver == null) return a0 == null;
          if (typeof receiver != "object")
            return a0 != null && receiver === a0;
        }''');
      }
      if (!classes.contains(backend.jsIntClass)
          && !classes.contains(backend.jsNumberClass)
          && !classes.contains(backend.jsDoubleClass)) {
        return null;
      }
      if (selector.argumentCount == 1) {
        // The following operators do not map to a JavaScript operator.
        if (name == '~/' || name == '<<' || name == '%' || name == '>>') {
          return null;
        }
        jsAst.Expression result = js('receiver $name a0');
        if (name == '&' || name == '|' || name == '^') {
          result = js('# >>> 0', result);
        }
        return js.statement(
            'if (typeof receiver == "number" && typeof a0 == "number")'
            '  return #;',
            result);
      } else if (name == 'unary-') {
        return js.statement(
            'if (typeof receiver == "number") return -receiver');
      } else {
        assert(name == '~');
        return js.statement('''
          if (typeof receiver == "number" && Math.floor(receiver) == receiver)
            return (~receiver) >>> 0;
          ''');
      }
    } else if (selector.isIndex || selector.isIndexSet) {
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
      bool containsJsIndexable =
          backend.jsIndexingBehaviorInterface.isResolved && classes.any((cls) {
        return compiler.world.isSubtypeOf(cls,
            backend.jsIndexingBehaviorInterface);
      });
      // The index set operator requires a check on its set value in
      // checked mode, so we don't optimize the interceptor if the
      // compiler has type assertions enabled.
      if (selector.isIndexSet
          && (compiler.enableTypeAssertions || !containsArray)) {
        return null;
      }
      if (!containsArray && !containsString) {
        return null;
      }
      jsAst.Expression arrayCheck = js('receiver.constructor == Array');
      jsAst.Expression indexableCheck =
          backend.generateIsJsIndexableCall(js('receiver'), js('receiver'));

      jsAst.Expression orExp(left, right) {
        return left == null ? right : js('# || #', [left, right]);
      }

      if (selector.isIndex) {
        jsAst.Expression typeCheck;
        if (containsArray) {
          typeCheck = arrayCheck;
        }

        if (containsString) {
          typeCheck = orExp(typeCheck, js('typeof receiver == "string"'));
        }

        if (containsJsIndexable) {
          typeCheck = orExp(typeCheck, indexableCheck);
        }

        return js.statement('''
          if (#)
            if ((a0 >>> 0) === a0 && a0 < receiver.length)
              return receiver[a0];
          ''', typeCheck);
      } else {
        jsAst.Expression typeCheck;
        if (containsArray) {
          typeCheck = arrayCheck;
        }

        if (containsJsIndexable) {
          typeCheck = orExp(typeCheck, indexableCheck);
        }

        return js.statement(r'''
          if (# && !receiver.immutable$list &&
              (a0 >>> 0) === a0 && a0 < receiver.length)
            return receiver[a0] = a1;
          ''', typeCheck);
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

      List<String> parameterNames = <String>[];
      parameterNames.add('receiver');

      if (selector.isSetter) {
        parameterNames.add('value');
      } else {
        for (int i = 0; i < selector.argumentCount; i++) {
          parameterNames.add('a$i');
        }
      }

      String invocationName = backend.namer.invocationName(selector);
      String globalObject = namer.globalObjectFor(backend.interceptorsLibrary);

      jsAst.Statement optimizedPath =
          fastPathForOneShotInterceptor(selector, classes);
      if (optimizedPath == null) optimizedPath = js.statement(';');

      jsAst.Expression assignment = js('${globalObject}.# = function(#) {'
          '  #;'
          '  return #.#(receiver).#(#) }',
          [name, parameterNames,
           optimizedPath,
           globalObject, getInterceptorName, invocationName, parameterNames]);

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
        js('${emitter.isolateProperties}.# = #', [name, array]);

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
    JavaScriptConstantCompiler handler = backend.constants;
    List<ConstantValue> constants =
        handler.getConstantsForEmission(emitter.compareConstants);
    for (ConstantValue constant in constants) {
      if (constant is TypeConstantValue) {
        TypeConstantValue typeConstant = constant;
        Element element = typeConstant.representedType.element;
        if (element is ClassElement) {
          ClassElement classElement = element;
          if (!analysis.needsClass(classElement)) continue;

          elements.add(emitter.constantReference(constant));
          elements.add(namer.elementAccess(classElement));

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
                    backend.namer.elementAccess(member)));
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
        js('${emitter.isolateProperties}.# = #', [name, array]);

    buffer.write(jsAst.prettyPrint(assignment, compiler));
    buffer.write(N);
  }
}
