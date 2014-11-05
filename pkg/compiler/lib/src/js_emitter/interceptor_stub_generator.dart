// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class InterceptorStubGenerator {
  final Compiler compiler;
  final Namer namer;
  final JavaScriptBackend backend;

  InterceptorStubGenerator(this.compiler, this.namer, this.backend);

  jsAst.Expression generateGetInterceptorMethod(Set<ClassElement> classes) {
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

    return js('''function(receiver) { #; }''', new jsAst.Block(statements));
  }

  // Returns a statement that takes care of performance critical
  // common case for a one-shot interceptor, or null if there is no
  // fast path.
  jsAst.Statement _fastPathForOneShotInterceptor(Selector selector,
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

  jsAst.Expression generateOneShotInterceptor(String name) {
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
        _fastPathForOneShotInterceptor(selector, classes);
    if (optimizedPath == null) optimizedPath = js.statement(';');

    return js(
        'function(#) { #; return #.#(receiver).#(#) }',
        [parameterNames,
         optimizedPath,
         globalObject, getInterceptorName, invocationName, parameterNames]);
  }
}