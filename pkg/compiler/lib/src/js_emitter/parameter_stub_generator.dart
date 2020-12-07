// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.parameter_stub_generator;

import '../common_elements.dart' show JElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../io/source_information.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/namer.dart' show Namer;
import '../js_backend/native_data.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/type_reference.dart' show TypeReference;
import '../js_model/type_recipe.dart' show TypeExpressionRecipe;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/codegen_world_builder.dart';
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart' show SelectorConstraints;
import '../world.dart' show JClosedWorld;

import 'model.dart';

import 'code_emitter_task.dart' show Emitter;
import 'native_emitter.dart';

class ParameterStubGenerator {
  static final Set<Selector> emptySelectorSet = new Set<Selector>();

  final Emitter _emitter;
  final NativeEmitter _nativeEmitter;
  final Namer _namer;
  final NativeData _nativeData;
  final InterceptorData _interceptorData;
  final CodegenWorld _codegenWorld;
  final JClosedWorld _closedWorld;
  final SourceInformationStrategy _sourceInformationStrategy;

  ParameterStubGenerator(
      this._emitter,
      this._nativeEmitter,
      this._namer,
      this._nativeData,
      this._interceptorData,
      this._codegenWorld,
      this._closedWorld,
      this._sourceInformationStrategy);

  DartTypes get _dartTypes => _closedWorld.dartTypes;
  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;

  bool needsSuperGetter(FunctionEntity element) =>
      _codegenWorld.methodsNeedsSuperGetter(element);

  /// Generates stubs to fill in missing optional named or positional arguments
  /// and missing type arguments.  Returns `null` if no stub is needed.
  ///
  /// Methods like `foo([x])` and `bar({x})` may be invoked by the following
  /// calls: `foo(), foo(1), bar(), bar(x: 1)`. This method generates the stub
  /// for the given [selector] and returns the generated [ParameterStubMethod].
  ///
  /// Members may be invoked in two ways: directly, or through a closure. In the
  /// latter case the caller invokes the tear-off closure's `call` method. This
  /// method [generateParameterStub] accepts two selectors. The returned stub
  /// method has the corresponding name [ParameterStubMethod.name] and
  /// [ParameterStubMethod.callName] set if the input selector is non-null (and
  /// the member needs a stub).
  ParameterStubMethod generateParameterStub(
      FunctionEntity member, Selector selector, Selector callSelector) {
    // The naming here can be a bit confusing. There is a call site somewhere
    // that calls the stub via the [selector], which has a [CallStructure], so
    // the *Call*Structure determines the *parameters* of the stub. The body of
    // the stub calls the member which has a [ParameterStructure], so the
    // *Parameter*Structure determines the *arguments* of the forwarding call.

    CallStructure callStructure = selector.callStructure;
    ParameterStructure parameterStructure = member.parameterStructure;
    int positionalArgumentCount = callStructure.positionalArgumentCount;
    assert(callStructure.typeArgumentCount == 0 ||
        callStructure.typeArgumentCount == parameterStructure.typeParameters);

    // We don't need a stub if the arguments match the target parameters,
    // i.e. there are no missing optional arguments or types. The selector
    // applies to the member, so we can check using counts.
    if (callStructure.typeArgumentCount == parameterStructure.typeParameters) {
      if (positionalArgumentCount == parameterStructure.totalParameters) {
        // Positional optional arguments are all provided.
        assert(callStructure.isUnnamed);
        return null;
      }
      if (parameterStructure.namedParameters.isNotEmpty &&
          callStructure.namedArgumentCount ==
              parameterStructure.namedParameters.length) {
        // Named optional arguments are all provided.
        return null;
      }
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
    List<jsAst.Parameter> stubParameters = new List<jsAst.Parameter>.filled(
        extraArgumentCount +
            selector.argumentCount +
            selector.typeArgumentCount,
        null);
    // The arguments that will be passed to the real method.
    List<jsAst.Expression> targetArguments = new List<jsAst.Expression>.filled(
        extraArgumentCount +
            parameterStructure.totalParameters +
            parameterStructure.typeParameters,
        null);

    int count = 0;
    if (isInterceptedMethod) {
      count++;
      stubParameters[0] = new jsAst.Parameter(receiverArgumentName);
      targetArguments[0] = js('#', receiverArgumentName);
    }

    int optionalParameterStart = positionalArgumentCount + extraArgumentCount;
    // Includes extra receiver argument when using interceptor convention
    int indexOfLastOptionalArgumentInParameters = optionalParameterStart - 1;

    _elementEnvironment.forEachParameter(member,
        (_, String name, ConstantValue value) {
      String jsName = _namer.safeVariableName(name);
      assert(jsName != receiverArgumentName);
      if (count < optionalParameterStart) {
        stubParameters[count] = new jsAst.Parameter(jsName);
        targetArguments[count] = js('#', jsName);
      } else {
        int index = names.indexOf(name);
        if (index != -1) {
          indexOfLastOptionalArgumentInParameters = count;
          // The order of the named arguments is not the same as the
          // one in the real method (which is in Dart source order).
          targetArguments[count] = js('#', jsName);
          stubParameters[optionalParameterStart + index] =
              new jsAst.Parameter(jsName);
        } else {
          if (value == null) {
            targetArguments[count] =
                _emitter.constantReference(new NullConstantValue());
          } else {
            if (!value.isNull) {
              // If the value is the null constant, we should not pass it
              // down to the native method.
              indexOfLastOptionalArgumentInParameters = count;
            }
            targetArguments[count] = _emitter.constantReference(value);
          }
        }
      }
      count++;
    });

    if (parameterStructure.typeParameters > 0) {
      int parameterIndex =
          stubParameters.length - parameterStructure.typeParameters;
      for (TypeVariableType typeVariable
          in _closedWorld.elementEnvironment.getFunctionTypeVariables(member)) {
        if (selector.typeArgumentCount == 0) {
          DartType defaultType = _closedWorld.elementEnvironment
              .getTypeVariableDefaultType(typeVariable.element);
          defaultType = _eraseTypeVariablesToAny(defaultType);
          targetArguments[count++] =
              TypeReference(TypeExpressionRecipe(defaultType));
        } else {
          String jsName = '\$${typeVariable.element.name}';
          stubParameters[parameterIndex++] = new jsAst.Parameter(jsName);
          targetArguments[count++] = js('#', jsName);
        }
      }
    }

    var body; // List or jsAst.Statement.
    if (_nativeData.hasFixedBackendName(member)) {
      body = _nativeEmitter.generateParameterStubStatements(
          member,
          isInterceptedMethod,
          _namer.invocationName(selector),
          stubParameters,
          targetArguments,
          indexOfLastOptionalArgumentInParameters);
    } else if (member.isInstanceMember) {
      if (needsSuperGetter(member)) {
        ClassEntity superClass = member.enclosingClass;
        jsAst.Name methodName = _namer.instanceMethodName(member);
        // When redirecting, we must ensure that we don't end up in a subclass.
        // We thus can't just invoke `this.foo$1.call(filledInArguments)`.
        // Instead we need to call the statically resolved target.
        //   `<class>.prototype.bar$1.call(this, argument0, ...)`.
        body = js.statement('return #.#.call(this, #);', [
          _emitter.prototypeAccess(superClass, hasBeenInstantiated: true),
          methodName,
          targetArguments
        ]);
      } else {
        body = js.statement('return this.#(#);',
            [_namer.instanceMethodName(member), targetArguments]);
      }
    } else {
      body = js.statement('return #(#)',
          [_emitter.staticFunctionAccess(member), targetArguments]);
    }

    SourceInformationBuilder sourceInformationBuilder =
        _sourceInformationStrategy.createBuilderForContext(member);
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildStub(member, callStructure);

    jsAst.Fun function = js('function(#) { #; }', [stubParameters, body])
        .withSourceInformation(sourceInformation);

    jsAst.Name name = member.isStatic ? null : _namer.invocationName(selector);
    jsAst.Name callName =
        (callSelector != null) ? _namer.invocationName(callSelector) : null;
    return new ParameterStubMethod(name, callName, function, element: member);
  }

  DartType _eraseTypeVariablesToAny(DartType type) {
    if (!type.containsTypeVariables) return type;
    Set<TypeVariableType> variables = Set();
    type.forEachTypeVariable(variables.add);
    assert(variables.isNotEmpty);
    return _dartTypes.subst(List.filled(variables.length, _dartTypes.anyType()),
        variables.toList(), type);
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
      {bool canTearOff, bool canBeApplied}) {
    assert(canTearOff != null);
    assert(canBeApplied != null);
    // The set of selectors that apply to `member`. For example, for
    // a member `foo(x, [y])` the following selectors may apply:
    // `foo(x)`, and `foo(x, y)`.
    Map<Selector, SelectorConstraints> liveSelectors;
    // The set of selectors that apply to `member` if it's name was `call`.
    // This happens when a member is torn off. In that case calls to the
    // function use the name `call`, and we must be able to handle every
    // `call` invocation that matches the signature. For example, for
    // a member `foo(x, [y])` the following selectors would be possible
    // call-selectors: `call(x)`, and `call(x, y)`.
    Map<Selector, SelectorConstraints> callSelectors;

    int memberTypeParameters = member.parameterStructure.typeParameters;

    // Only instance members (not static methods) need stubs.
    if (member.isInstanceMember) {
      liveSelectors = _codegenWorld.invocationsByName(member.name);
    }

    if (canTearOff) {
      String call = _namer.closureInvocationSelectorName;
      callSelectors = _codegenWorld.invocationsByName(call);
    }

    assert(emptySelectorSet.isEmpty);
    liveSelectors ??= const <Selector, SelectorConstraints>{};
    callSelectors ??= const <Selector, SelectorConstraints>{};

    List<ParameterStubMethod> stubs = <ParameterStubMethod>[];

    if (liveSelectors.isEmpty &&
        callSelectors.isEmpty &&
        // Function.apply might need a stub to default the type parameter.
        !(canBeApplied && memberTypeParameters > 0)) {
      return stubs;
    }

    // For every call-selector the corresponding selector with the name of the
    // member.
    //
    // For example, for the call-selector `call(x, y)` the renamed selector
    // for member `foo` would be `foo(x, y)`.
    Set<Selector> renamedCallSelectors = new Set<Selector>();

    Set<Selector> stubSelectors = new Set<Selector>();

    // Start with closure-call selectors, since since they imply the generation
    // of the non-call version.
    if (canBeApplied && memberTypeParameters > 0) {
      // Function.apply calls the function with no type arguments, so generic
      // methods need the stub to default the type arguments.
      // This has to be the first stub.
      Selector namedSelector = new Selector.fromElement(member).toNonGeneric();
      Selector closureSelector =
          namedSelector.isClosureCall ? null : namedSelector.toCallSelector();

      renamedCallSelectors.add(namedSelector);
      stubSelectors.add(namedSelector);
      ParameterStubMethod stub =
          generateParameterStub(member, namedSelector, closureSelector);
      assert(stub != null);
      stubs.add(stub);
    }

    for (Selector selector in callSelectors.keys) {
      Selector renamedSelector =
          new Selector.call(member.memberName, selector.callStructure);
      renamedCallSelectors.add(renamedSelector);

      if (!renamedSelector.appliesUnnamed(member)) {
        continue;
      }

      if (stubSelectors.add(renamedSelector)) {
        ParameterStubMethod stub =
            generateParameterStub(member, renamedSelector, selector);
        if (stub != null) {
          stubs.add(stub);
        }
      }

      // A generic method might need to support `call<T>(x)` for a generic
      // instantiation stub without `call<T>(x)` being in [callSelectors].
      // [selector] will be `call(x)` (that already passes the appliesUnnamed
      // check by defaulting type arguments), and the method will be generic.
      //
      // This is basically the same logic as above, but with type arguments.
      if (selector.callStructure.typeArgumentCount == 0) {
        if (memberTypeParameters > 0) {
          Selector renamedSelectorWithTypeArguments = new Selector.call(
              member.memberName,
              selector.callStructure
                  .withTypeArgumentCount(memberTypeParameters));
          renamedCallSelectors.add(renamedSelectorWithTypeArguments);

          if (stubSelectors.add(renamedSelectorWithTypeArguments)) {
            Selector closureSelector =
                new Selector.callClosureFrom(renamedSelectorWithTypeArguments);
            ParameterStubMethod stub = generateParameterStub(
                member, renamedSelectorWithTypeArguments, closureSelector);
            if (stub != null) {
              stubs.add(stub);
            }
          }
        }
      }
    }

    // Now run through the actual member selectors (eg. `foo$2(x, y)` and not
    // `call$2(x, y)`). Some of them have already been generated because of the
    // call-selectors and they are in the renamedCallSelectors set.
    for (Selector selector in liveSelectors.keys) {
      if (renamedCallSelectors.contains(selector)) continue;
      if (!selector.appliesUnnamed(member)) continue;
      if (!liveSelectors[selector]
          .canHit(member, selector.memberName, _closedWorld)) {
        continue;
      }

      if (stubSelectors.add(selector)) {
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
