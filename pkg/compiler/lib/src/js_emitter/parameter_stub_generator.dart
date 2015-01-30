// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class ParameterStubGenerator {
  final Namer namer;
  final Compiler compiler;
  final JavaScriptBackend backend;

  ParameterStubGenerator(this.compiler, this.namer, this.backend);

  Emitter get emitter => backend.emitter.emitter;
  CodeEmitterTask get emitterTask => backend.emitter;

  bool needsSuperGetter(FunctionElement element) =>
    compiler.codegenWorld.methodsNeedingSuperGetter.contains(element);

  /**
   * Generate stubs to handle invocation of methods with optional
   * arguments.
   *
   * A method like [: foo([x]) :] may be invoked by the following
   * calls: [: foo(), foo(1), foo(x: 1) :]. See the sources of this
   * function for detailed examples.
   */
  jsAst.Expression generateParameterStub(FunctionElement member,
                                         Selector selector) {
    FunctionSignature parameters = member.functionSignature;
    int positionalArgumentCount = selector.positionalArgumentCount;
    if (positionalArgumentCount == parameters.parameterCount) {
      assert(selector.namedArgumentCount == 0);
      return null;
    }
    if (parameters.optionalParametersAreNamed
        && selector.namedArgumentCount == parameters.optionalParameterCount) {
      // If the selector has the same number of named arguments as the element,
      // we don't need to add a stub. The call site will hit the method
      // directly.
      return null;
    }
    JavaScriptConstantCompiler handler = backend.constants;
    List<String> names = selector.getOrderedNamedArguments();

    String invocationName = namer.invocationName(selector);

    bool isInterceptedMethod = backend.isInterceptedMethod(member);

    // If the method is intercepted, we need to also pass the actual receiver.
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
      argumentsBuffer[0] = js('#', receiverArgumentName);
    }

    int optionalParameterStart = positionalArgumentCount + extraArgumentCount;
    // Includes extra receiver argument when using interceptor convention
    int indexOfLastOptionalArgumentInParameters = optionalParameterStart - 1;

    int parameterIndex = 0;
    parameters.orderedForEachParameter((ParameterElement element) {
      String jsName = backend.namer.safeName(element.name);
      assert(jsName != receiverArgumentName);
      if (count < optionalParameterStart) {
        parametersBuffer[count] = new jsAst.Parameter(jsName);
        argumentsBuffer[count] = js('#', jsName);
      } else {
        int index = names.indexOf(element.name);
        if (index != -1) {
          indexOfLastOptionalArgumentInParameters = count;
          // The order of the named arguments is not the same as the
          // one in the real method (which is in Dart source order).
          argumentsBuffer[count] = js('#', jsName);
          parametersBuffer[optionalParameterStart + index] =
              new jsAst.Parameter(jsName);
        } else {
          ConstantExpression constant = handler.getConstantForVariable(element);
          if (constant == null) {
            argumentsBuffer[count] =
                emitter.constantReference(new NullConstantValue());
          } else {
            ConstantValue value = constant.value;
            if (!value.isNull) {
              // If the value is the null constant, we should not pass it
              // down to the native method.
              indexOfLastOptionalArgumentInParameters = count;
            }
            argumentsBuffer[count] = emitter.constantReference(value);
          }
        }
      }
      count++;
    });

    var body;  // List or jsAst.Statement.
    if (member.hasFixedBackendName) {
      body = emitterTask.nativeEmitter.generateParameterStubStatements(
          member, isInterceptedMethod, invocationName,
          parametersBuffer, argumentsBuffer,
          indexOfLastOptionalArgumentInParameters);
    } else if (member.isInstanceMember) {
      if (needsSuperGetter(member)) {
        ClassElement superClass = member.enclosingClass;
        String methodName = namer.getNameOfInstanceMember(member);
        // When redirecting, we must ensure that we don't end up in a subclass.
        // We thus can't just invoke `this.foo$1.call(filledInArguments)`.
        // Instead we need to call the statically resolved target.
        //   `<class>.prototype.bar$1.call(this, argument0, ...)`.
        body = js.statement(
            'return #.#.call(this, #);',
            [backend.emitter.prototypeAccess(superClass,
                                             hasBeenInstantiated: true),
             methodName,
             argumentsBuffer]);
      } else {
        body = js.statement(
            'return this.#(#);',
            [namer.getNameOfInstanceMember(member), argumentsBuffer]);
      }
    } else {
      body = js.statement('return #(#)',
          [emitter.staticFunctionAccess(member), argumentsBuffer]);
    }

    jsAst.Fun function = js('function(#) { #; }', [parametersBuffer, body]);

    return function;
  }

  Map<Selector, jsAst.Expression> generateParameterStubs(FunctionElement member,
                                          [bool canTearOff = false]) {
    Map<Selector, jsAst.Expression> generatedStubs
        = <Selector, jsAst.Expression>{};

    if (member.enclosingElement.isClosure) {
      ClosureClassElement cls = member.enclosingElement;
      if (cls.supertype.element == backend.boundClosureClass) {
        compiler.internalError(cls.methodElement, 'Bound closure1.');
      }
      if (cls.methodElement.isInstanceMember) {
        compiler.internalError(cls.methodElement, 'Bound closure2.');
      }
    }

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
    //
    // We need to pay attention if this stub is for a function that has been
    // invoked from a subclass. Then we cannot just redirect, since that
    // would invoke the methods of the subclass. We have to compile to:
    // (1) foo$2(a, b) => MyClass.foo$4$c$d.call(this, a, b, null, null)
    // (2) foo$3$c(a, b, c) => MyClass.foo$4$c$d(this, a, b, c, null);
    // (3) foo$3$d(a, b, d) => MyClass.foo$4$c$d(this, a, b, null, d);

    Set<Selector> selectors = member.isInstanceMember
        ? compiler.codegenWorld.invokedNames[member.name]
        : null; // No stubs needed for static methods.

    /// Returns all closure call selectors renamed to match this member.
    Set<Selector> callSelectorsAsNamed() {
      if (!canTearOff) return null;
      Set<Selector> callSelectors = compiler.codegenWorld.invokedNames[
          namer.closureInvocationSelectorName];
      if (callSelectors == null) return null;
      return callSelectors.map((Selector callSelector) {
        return new Selector.call(
            member.name, member.library,
            callSelector.argumentCount, callSelector.namedArguments);
      }).toSet();
    }
    if (selectors == null) {
      selectors = callSelectorsAsNamed();
      if (selectors == null) return generatedStubs;
    } else {
      Set<Selector> callSelectors = callSelectorsAsNamed();
      if (callSelectors != null) {
        selectors = selectors.union(callSelectors);
      }
    }
    Set<Selector> untypedSelectors = new Set<Selector>();
    if (selectors != null) {
      for (Selector selector in selectors) {
        if (!selector.appliesUnnamed(member, compiler.world)) continue;
        if (untypedSelectors.add(selector.asUntyped)) {
          jsAst.Expression stub = generateParameterStub(member, selector);
          if (stub != null) {
            generatedStubs[selector] = stub;
          }
        }
      }
    }
    if (canTearOff) {
      selectors = compiler.codegenWorld.invokedNames[
          namer.closureInvocationSelectorName];
      if (selectors != null) {
        for (Selector selector in selectors) {
          selector = new Selector.call(
              member.name, member.library,
              selector.argumentCount, selector.namedArguments);
          if (!selector.appliesUnnamed(member, compiler.world)) continue;
          if (untypedSelectors.add(selector)) {
            jsAst.Expression stub = generateParameterStub(member, selector);
            if (stub != null) {
              generatedStubs[selector] = stub;
            }
          }
        }
      }
    }
    return generatedStubs;
  }
}
