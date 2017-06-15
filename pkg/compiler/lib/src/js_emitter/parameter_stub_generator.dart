// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.parameter_stub_generator;

import '../closure.dart' show ClosureClassElement;
import '../common.dart';
import '../common_elements.dart';
import '../constants/values.dart';
import '../elements/elements.dart'
    show
        ClassElement,
        FunctionElement,
        FunctionSignature,
        MethodElement,
        ParameterElement;
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/constant_handler_javascript.dart'
    show JavaScriptConstantCompiler;
import '../js_backend/namer.dart' show Namer;
import '../js_backend/native_data.dart';
import '../js_backend/interceptor_data.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart'
    show CodegenWorldBuilder, SelectorConstraints;
import '../world.dart' show ClosedWorld;

import 'model.dart';

import 'code_emitter_task.dart' show CodeEmitterTask, Emitter;

class ParameterStubGenerator {
  static final Set<Selector> emptySelectorSet = new Set<Selector>();

  final CommonElements _commonElements;
  final CodeEmitterTask _emitterTask;
  final JavaScriptConstantCompiler _constants;
  final Namer _namer;
  final NativeData _nativeData;
  final InterceptorData _interceptorData;
  final CodegenWorldBuilder _codegenWorldBuilder;
  final ClosedWorld _closedWorld;

  ParameterStubGenerator(
      this._commonElements,
      this._emitterTask,
      this._constants,
      this._namer,
      this._nativeData,
      this._interceptorData,
      this._codegenWorldBuilder,
      this._closedWorld);

  Emitter get _emitter => _emitterTask.emitter;

  bool needsSuperGetter(FunctionElement element) =>
      _codegenWorldBuilder.methodsNeedingSuperGetter.contains(element);

  /**
   * Generates stubs to handle invocation of methods with optional
   * arguments.
   *
   * A method like `foo([x])` may be invoked by the following
   * calls: `foo(), foo(1), foo(x: 1)`. This method generates the stub for the
   * given [selector] and returns the generated [ParameterStubMethod].
   *
   * Returns null if no stub is needed.
   *
   * Members may be invoked in two ways: directly, or through a closure. In the
   * latter case the caller invokes the closure's `call` method. This method
   * accepts two selectors. The returned stub method has the corresponding
   * name [ParameterStubMethod.name] and [ParameterStubMethod.callName] set if
   * the input selector is non-null (and the member needs a stub).
   */
  ParameterStubMethod generateParameterStub(
      MethodElement member, Selector selector, Selector callSelector) {
    CallStructure callStructure = selector.callStructure;
    FunctionSignature parameters = member.functionSignature;
    int positionalArgumentCount = callStructure.positionalArgumentCount;
    if (positionalArgumentCount == parameters.parameterCount) {
      assert(callStructure.isUnnamed);
      return null;
    }
    if (parameters.optionalParametersAreNamed &&
        callStructure.namedArgumentCount == parameters.optionalParameterCount) {
      // If the selector has the same number of named arguments as the element,
      // we don't need to add a stub. The call site will hit the method
      // directly.
      return null;
    }
    List<String> names = callStructure.getOrderedNamedArguments();

    bool isInterceptedMethod = _interceptorData.isInterceptedMethod(member);

    // If the method is intercepted, we need to also pass the actual receiver.
    int extraArgumentCount = isInterceptedMethod ? 1 : 0;
    // Use '$receiver' to avoid clashes with other parameter names. Using
    // '$receiver' works because namer.safeVariableName used for getting
    // parameter names never returns a name beginning with a single '$'.
    String receiverArgumentName = r'$receiver';

    // The parameters that this stub takes.
    List<jsAst.Parameter> parametersBuffer =
        new List<jsAst.Parameter>(selector.argumentCount + extraArgumentCount);
    // The arguments that will be passed to the real method.
    List<jsAst.Expression> argumentsBuffer = new List<jsAst.Expression>(
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

    parameters.orderedForEachParameter((_element) {
      ParameterElement element = _element;
      String jsName = _namer.safeVariableName(element.name);
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
          ConstantValue value = _constants.getConstantValue(element.constant);
          if (value == null) {
            argumentsBuffer[count] =
                _emitter.constantReference(new NullConstantValue());
          } else {
            if (!value.isNull) {
              // If the value is the null constant, we should not pass it
              // down to the native method.
              indexOfLastOptionalArgumentInParameters = count;
            }
            argumentsBuffer[count] = _emitter.constantReference(value);
          }
        }
      }
      count++;
    });

    var body; // List or jsAst.Statement.
    if (_nativeData.hasFixedBackendName(member)) {
      body = _emitterTask.nativeEmitter.generateParameterStubStatements(
          member,
          isInterceptedMethod,
          _namer.invocationName(selector),
          parametersBuffer,
          argumentsBuffer,
          indexOfLastOptionalArgumentInParameters);
    } else if (member.isInstanceMember) {
      if (needsSuperGetter(member)) {
        ClassElement superClass = member.enclosingClass;
        jsAst.Name methodName = _namer.instanceMethodName(member);
        // When redirecting, we must ensure that we don't end up in a subclass.
        // We thus can't just invoke `this.foo$1.call(filledInArguments)`.
        // Instead we need to call the statically resolved target.
        //   `<class>.prototype.bar$1.call(this, argument0, ...)`.
        body = js.statement('return #.#.call(this, #);', [
          _emitterTask.prototypeAccess(superClass, hasBeenInstantiated: true),
          methodName,
          argumentsBuffer
        ]);
      } else {
        body = js.statement('return this.#(#);',
            [_namer.instanceMethodName(member), argumentsBuffer]);
      }
    } else {
      body = js.statement('return #(#)',
          [_emitter.staticFunctionAccess(member), argumentsBuffer]);
    }

    jsAst.Fun function = js('function(#) { #; }', [parametersBuffer, body]);

    jsAst.Name name = member.isStatic ? null : _namer.invocationName(selector);
    jsAst.Name callName =
        (callSelector != null) ? _namer.invocationName(callSelector) : null;
    return new ParameterStubMethod(name, callName, function);
  }

  // We fill the lists depending on possible/invoked selectors. For example,
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
  List<ParameterStubMethod> generateParameterStubs(FunctionEntity member,
      {bool canTearOff: true}) {
    if (member.enclosingClass != null && member.enclosingClass.isClosure) {
      ClosureClassElement cls = member.enclosingClass;
      if (cls.supertype.element == _commonElements.boundClosureClass) {
        throw new SpannableAssertionFailure(
            cls.methodElement, 'Bound closure1.');
      }
      if (cls.methodElement.isInstanceMember) {
        throw new SpannableAssertionFailure(
            cls.methodElement, 'Bound closure2.');
      }
    }

    // The set of selectors that apply to `member`. For example, for
    // a member `foo(x, [y])` the following selectors may apply:
    // `foo(x)`, and `foo(x, y)`.
    Map<Selector, SelectorConstraints> selectors;
    // The set of selectors that apply to `member` if it's name was `call`.
    // This happens when a member is torn off. In that case calls to the
    // function use the name `call`, and we must be able to handle every
    // `call` invocation that matches the signature. For example, for
    // a member `foo(x, [y])` the following selectors would be possible
    // call-selectors: `call(x)`, and `call(x, y)`.
    Map<Selector, SelectorConstraints> callSelectors;

    // Only instance members (not static methods) need stubs.
    if (member.isInstanceMember) {
      selectors = _codegenWorldBuilder.invocationsByName(member.name);
    }

    if (canTearOff) {
      String call = _namer.closureInvocationSelectorName;
      callSelectors = _codegenWorldBuilder.invocationsByName(call);
    }

    assert(emptySelectorSet.isEmpty);
    if (selectors == null) selectors = const <Selector, SelectorConstraints>{};
    if (callSelectors == null)
      callSelectors = const <Selector, SelectorConstraints>{};

    List<ParameterStubMethod> stubs = <ParameterStubMethod>[];

    if (selectors.isEmpty && callSelectors.isEmpty) {
      return stubs;
    }

    // For every call-selector the corresponding selector with the name of the
    // member.
    //
    // For example, for the call-selector `call(x, y)` the renamed selector
    // for member `foo` would be `foo(x, y)`.
    Set<Selector> renamedCallSelectors =
        callSelectors.isEmpty ? emptySelectorSet : new Set<Selector>();

    Set<Selector> untypedSelectors = new Set<Selector>();

    // Start with the callSelectors since they imply the generation of the
    // non-call version.
    for (Selector selector in callSelectors.keys) {
      Selector renamedSelector =
          new Selector.call(member.memberName, selector.callStructure);
      renamedCallSelectors.add(renamedSelector);

      if (!renamedSelector.appliesUnnamed(member)) {
        continue;
      }

      if (untypedSelectors.add(renamedSelector)) {
        ParameterStubMethod stub =
            generateParameterStub(member, renamedSelector, selector);
        if (stub != null) {
          stubs.add(stub);
        }
      }
    }

    // Now run through the actual member selectors (eg. `foo$2(x, y)` and not
    // `call$2(x, y)`. Some of them have already been generated because of the
    // call-selectors (and they are in the renamedCallSelectors set.
    for (Selector selector in selectors.keys) {
      if (renamedCallSelectors.contains(selector)) continue;
      if (!selector.appliesUnnamed(member)) continue;
      if (!selectors[selector].applies(member, selector, _closedWorld)) {
        continue;
      }

      if (untypedSelectors.add(selector)) {
        ParameterStubMethod stub =
            generateParameterStub(member, selector, null);
        if (stub != null) {
          stubs.add(stub);
        }
      }
    }

    return stubs;
  }
}
