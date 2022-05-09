// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.class_stub_generator;

import 'package:js_runtime/shared/embedded_names.dart'
    show TearOffParametersPropertyNames;

import '../common/elements.dart' show CommonElements;
import '../common/names.dart' show Identifiers, Selectors;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/field_analysis.dart';
import '../js_backend/namer.dart' show Namer;
import '../js_backend/interceptor_data.dart' show InterceptorData;
import '../options.dart';
import '../universe/codegen_world_builder.dart';
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart' show SelectorConstraints;
import '../world.dart' show JClosedWorld;

import 'code_emitter_task.dart';
import 'model.dart';

class ClassStubGenerator {
  final Namer _namer;
  final CodegenWorld _codegenWorld;
  final JClosedWorld _closedWorld;
  final bool enableMinification;
  final Emitter _emitter;
  final CommonElements _commonElements;

  ClassStubGenerator(this._emitter, this._commonElements, this._namer,
      this._codegenWorld, this._closedWorld,
      {this.enableMinification});

  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  /// Documentation wanted -- johnniwinther
  ///
  /// Invariant: [member] must be a declaration element.
  Map<jsAst.Name, jsAst.Expression> generateCallStubsForGetter(
      MemberEntity member, Map<Selector, SelectorConstraints> selectors) {
    // If the method is intercepted, the stub gets the
    // receiver explicitly and we need to pass it to the getter call.
    bool isInterceptedMethod = _interceptorData.isInterceptedMethod(member);
    bool isInterceptedClass =
        _interceptorData.isInterceptedClass(member.enclosingClass);

    const String receiverArgumentName = r'$receiver';

    jsAst.Expression buildGetter() {
      jsAst.Expression receiver =
          js(isInterceptedClass ? receiverArgumentName : 'this');
      if (member.isGetter) {
        jsAst.Name getterName = _namer.getterForElement(member);
        if (isInterceptedMethod) {
          return js('this.#(#)', [getterName, receiver]);
        }
        return js('#.#()', [receiver, getterName]);
      } else {
        FieldAnalysisData fieldData =
            _closedWorld.fieldAnalysis.getFieldData(member);
        if (fieldData.isEffectivelyConstant) {
          return _emitter.constantReference(fieldData.constantValue);
        } else {
          jsAst.Name fieldName = _namer.instanceFieldPropertyName(member);
          return js('#.#', [receiver, fieldName]);
        }
      }
    }

    Map<jsAst.Name, jsAst.Expression> generatedStubs = {};

    // Two selectors may match but differ only in type.  To avoid generating
    // identical stubs for each we track untyped selectors which already have
    // stubs.
    Set<Selector> generatedSelectors = {};
    for (Selector selector in selectors.keys) {
      if (generatedSelectors.contains(selector)) continue;
      if (!selector.appliesUnnamed(member)) continue;
      if (selectors[selector]
          .canHit(member, selector.memberName, _closedWorld)) {
        generatedSelectors.add(selector);

        jsAst.Name invocationName = _namer.invocationName(selector);
        Selector callSelector = Selector.callClosureFrom(selector);
        jsAst.Name closureCallName = _namer.invocationName(callSelector);

        List<jsAst.Parameter> parameters = [];
        List<jsAst.Expression> arguments = [];
        if (isInterceptedMethod) {
          parameters.add(jsAst.Parameter(receiverArgumentName));
        }

        for (int i = 0; i < selector.argumentCount; i++) {
          String name = 'arg$i';
          parameters.add(jsAst.Parameter(name));
          arguments.add(js('#', name));
        }

        for (int i = 0; i < selector.typeArgumentCount; i++) {
          String name = '\$T${i + 1}';
          parameters.add(jsAst.Parameter(name));
          arguments.add(js('#', name));
        }

        jsAst.Fun function = js('function(#) { return #.#(#); }',
            [parameters, buildGetter(), closureCallName, arguments]);

        generatedStubs[invocationName] = function;
      }
    }

    return generatedStubs;
  }

  Map<jsAst.Name, Selector> computeSelectorsForNsmHandlers() {
    Map<jsAst.Name, Selector> jsNames = {};

    // Do not generate no such method handlers if there is no class.
    if (_codegenWorld.directlyInstantiatedClasses.isEmpty) {
      return jsNames;
    }

    void addNoSuchMethodHandlers(
        String ignore, Map<Selector, SelectorConstraints> selectors) {
      for (Selector selector in selectors.keys) {
        if (selector == Selectors.runtimeType_ ||
            selector == Selectors.equals ||
            selector == Selectors.toString_ ||
            selector == Selectors.hashCode_ ||
            selector == Selectors.noSuchMethod_) {
          // Skip Object methods since these need no noSuchMethod handling
          // regardless of the precision of the selector constraints.
          continue;
        }

        SelectorConstraints maskSet = selectors[selector];
        if (maskSet.needsNoSuchMethodHandling(selector, _closedWorld)) {
          jsAst.Name jsName = _namer.invocationMirrorInternalName(selector);
          jsNames[jsName] = selector;
        }
      }
    }

    _codegenWorld.forEachInvokedName(addNoSuchMethodHandlers);
    _codegenWorld.forEachInvokedGetter(addNoSuchMethodHandlers);
    _codegenWorld.forEachInvokedSetter(addNoSuchMethodHandlers);
    return jsNames;
  }

  StubMethod generateStubForNoSuchMethod(jsAst.Name name, Selector selector) {
    // Values match JSInvocationMirror in js-helper library.
    int type = selector.invocationMirrorKind;
    List<String> parameterNames =
        List.generate(selector.argumentCount, (i) => '\$$i') +
            List.generate(selector.typeArgumentCount, (i) => '\$T${i + 1}');

    List<jsAst.Expression> argNames = selector.callStructure
        .getOrderedNamedArguments()
        .map((String name) => js.string(name))
        .toList();

    jsAst.Name methodName = _namer.asName(selector.invocationMirrorMemberName);
    jsAst.Name internalName = _namer.invocationMirrorInternalName(selector);

    assert(_interceptorData.isInterceptedName(Identifiers.noSuchMethod_));
    bool isIntercepted = _interceptorData.isInterceptedName(selector.name);
    jsAst.Expression expression = js('''this.#noSuchMethodName(#receiver,
                    #createInvocationMirror(#methodName,
                                            #internalName,
                                            #type,
                                            #arguments,
                                            #namedArguments,
                                            #typeArgumentCount))''', {
      'receiver': isIntercepted ? r'$receiver' : 'this',
      'noSuchMethodName': _namer.noSuchMethodName,
      'createInvocationMirror':
          _emitter.staticFunctionAccess(_commonElements.createInvocationMirror),
      'methodName':
          js.quoteName(enableMinification ? internalName : methodName),
      'internalName': js.quoteName(internalName),
      'type': js.number(type),
      'arguments': jsAst.ArrayInitializer(
          parameterNames.map<jsAst.Expression>(js).toList()),
      'namedArguments': jsAst.ArrayInitializer(argNames),
      'typeArgumentCount': js.number(selector.typeArgumentCount)
    });

    jsAst.Expression function;
    if (isIntercepted) {
      function = js(
          r'function($receiver, #) { return # }', [parameterNames, expression]);
    } else {
      function = js(r'function(#) { return # }', [parameterNames, expression]);
    }
    return StubMethod(name, function);
  }

  /// Generates a getter for the given [field].
  Method generateGetter(Field field) {
    assert(field.needsGetter);

    jsAst.Expression code;
    if (field.isElided) {
      ConstantValue constantValue = field.constantValue;
      assert(
          constantValue != null, "No constant value for elided field: $field");
      if (constantValue == null) {
        // This should never occur because codegen member usage is now limited
        // by closed world member usage. In the case we've missed a spot we
        // cautiously generate a null constant.
        constantValue = NullConstantValue();
      }
      code = js("function() { return #; }",
          _emitter.constantReference(constantValue));
    } else {
      String template;
      if (field.needsInterceptedGetterOnReceiver) {
        template = "function(receiver) { return receiver[#]; }";
      } else if (field.needsInterceptedGetterOnThis) {
        template = "function(receiver) { return this[#]; }";
      } else {
        assert(!field.needsInterceptedGetter);
        template = "function() { return this[#]; }";
      }
      jsAst.Expression fieldName = js.quoteName(field.name);
      code = js(template, fieldName);
    }
    jsAst.Name getterName = _namer.deriveGetterName(field.accessorName);
    return StubMethod(getterName, code);
  }

  /// Generates a setter for the given [field].
  Method generateSetter(Field field) {
    assert(field.needsUncheckedSetter);

    String template;
    jsAst.Expression code;
    if (field.isElided) {
      code = js("function() { }");
    } else {
      if (field.needsInterceptedSetterOnReceiver) {
        template = "function(receiver, val) { return receiver[#] = val; }";
      } else if (field.needsInterceptedSetterOnThis) {
        template = "function(receiver, val) { return this[#] = val; }";
      } else {
        assert(!field.needsInterceptedSetter);
        template = "function(val) { return this[#] = val; }";
      }
      jsAst.Expression fieldName = js.quoteName(field.name);
      code = js(template, fieldName);
    }

    jsAst.Name setterName = _namer.deriveSetterName(field.accessorName);
    return StubMethod(setterName, code);
  }
}

/// Creates two JavaScript functions: `tearOffGetter` and `tearOff`.
///
/// `tearOffGetter` is internal and only used by `tearOff`.
///
/// `tearOff` takes the following arguments:
///   * `funcs`: a list of functions. These are the functions representing the
///     member that is torn off. There can be more than one, since a member
///     can have several stubs.
///     Each function must have the `$callName` property set.
///   * `applyTrampolineIndex` is the index of the stub to be used for
///     Function.apply
///   * `reflectionInfo`: contains reflective information, and the function
///     type. TODO(floitsch): point to where this is specified.
///   * `isStatic`.
///   * `name`.
///   * `isIntercepted.
List<jsAst.Statement> buildTearOffCode(
    CompilerOptions options, Emitter emitter, CommonElements commonElements) {
  FunctionEntity closureFromTearOff = commonElements.closureFromTearOff;
  jsAst.Expression closureFromTearOffAccessExpression;
  if (closureFromTearOff != null) {
    closureFromTearOffAccessExpression =
        emitter.staticFunctionAccess(closureFromTearOff);
  } else {
    // Default values for mocked-up test libraries.
    closureFromTearOffAccessExpression =
        js(r'''function() { throw "Helper 'closureFromTearOff' missing." }''');
  }

  jsAst.Statement instanceTearOffGetter;
  if (options.features.useContentSecurityPolicy.isEnabled) {
    instanceTearOffGetter = js.statement(
      '''
      function instanceTearOffGetter(isIntercepted, parameters) {
        var cache = null;
        return isIntercepted
            ? function(receiver) {
                if (cache === null) cache = #createTearOffClass(parameters);
                return new cache(receiver, this);
              }
            : function() {
                if (cache === null) cache = #createTearOffClass(parameters);
                return new cache(this, null);
              };
      }''',
      {'createTearOffClass': closureFromTearOffAccessExpression},
    );
  } else {
    // In the CSP version above, the allocation `new cache(...)` is polymorphic
    // since the same JavaScript anonymous function is used for all instance
    // tear-offs.
    //
    // The following code uses `new Function` to create a fresh instance method
    // tear-off getter for each method, allowing the allocation to be
    // monomorphic. This translates into a 2x performance improvement when a
    // method is torn-off many times.  The cost is that the getter, created via
    // `new Function`, is more expensive to create, and that cost is at program
    // startup.
    //
    // The a counter in the name ensures that the JavaScript engine does not
    // attempt to fold all of the almost-identical functions back to the same
    // instance of Function.
    //
    // Functions created by `new Function` are at the JavaScript global scope,
    // so cannot close-over any values from an 'intermediate' enclosing scope.
    // We use `new Function` to create a function that is immediately applied to
    // create a context with the closed-over values. The closed-over values
    // include parameters, (Dart) top-level definitions, and the local `cache`
    // variable all in one context (passing `null` to initialize `cache`).
    instanceTearOffGetter = js.statement(
      '''
function instanceTearOffGetter(isIntercepted, parameters) {
  var name = parameters.#tpFunctionsOrNames[0];
  if (isIntercepted)
    return new Function("parameters, createTearOffClass, cache",
        "return function tearOff_" + name + (functionCounter++) + "(receiver) {" +
          "if (cache === null) cache = createTearOffClass(parameters);" +
            "return new cache(receiver, this);" +
        "}")(parameters, #createTearOffClass, null);
  else
    return new Function("parameters, createTearOffClass, cache",
        "return function tearOff_" + name + (functionCounter++)+ "() {" +
          "if (cache === null) cache = createTearOffClass(parameters);" +
            "return new cache(this, null);" +
        "}")(parameters, #createTearOffClass, null);
}''',
      {
        'tpFunctionsOrNames':
            js.string(TearOffParametersPropertyNames.funsOrNames),
        'createTearOffClass': closureFromTearOffAccessExpression
      },
    );
  }

  jsAst.Statement staticTearOffGetter = js.statement(
    '''
function staticTearOffGetter(parameters) {
  var cache = null;
  return function() {
    if (cache === null) cache = #createTearOffClass(parameters).prototype;
    return cache;
  }
}''',
    {'createTearOffClass': closureFromTearOffAccessExpression},
  );

  return [instanceTearOffGetter, staticTearOffGetter];
}
