// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import 'package:js_runtime/synced/embedded_names.dart'
    show TearOffParametersPropertyNames;

import '../common/elements.dart' show CommonElements;
import '../common/names.dart' show Identifiers, Selectors;
import '../elements/entities.dart';
import '../js/js.dart' as js_ast;
import '../js/js.dart' show js;
import '../js_backend/field_analysis.dart';
import '../js_backend/namer.dart' show Namer;
import '../js_backend/interceptor_data.dart' show InterceptorData;
import '../js_model/elements.dart' show JField;
import '../js_model/js_world.dart' show JClosedWorld;
import '../options.dart';
import '../universe/codegen_world_builder.dart';
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart' show SelectorConstraints;

import 'js_emitter.dart';
import 'model.dart';

class ClassStubGenerator {
  final Namer _namer;
  final CodegenWorld _codegenWorld;
  final JClosedWorld _closedWorld;
  final bool enableMinification;
  final Emitter _emitter;
  final CommonElements _commonElements;

  ClassStubGenerator(
    this._emitter,
    this._commonElements,
    this._namer,
    this._codegenWorld,
    this._closedWorld, {
    required this.enableMinification,
  });

  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  /// Documentation wanted -- johnniwinther
  ///
  /// Invariant: [member] must be a declaration element.
  Map<js_ast.Name, js_ast.Expression> generateCallStubsForGetter(
    MemberEntity member,
    Map<Selector, SelectorConstraints> selectors,
  ) {
    // If the method is intercepted, the stub gets the
    // receiver explicitly and we need to pass it to the getter call.
    bool isInterceptedMethod = _interceptorData.isInterceptedMethod(member);
    bool isInterceptedClass = _interceptorData.isInterceptedClass(
      member.enclosingClass!,
    );

    const String receiverArgumentName = r'$receiver';

    js_ast.Expression buildGetter() {
      js_ast.Expression receiver = js(
        isInterceptedClass ? receiverArgumentName : 'this',
      );
      if (member.isGetter) {
        js_ast.Name getterName = _namer.getterForElement(member);
        if (isInterceptedMethod) {
          return js('this.#(#)', [getterName, receiver]);
        }
        return js('#.#()', [receiver, getterName]);
      } else {
        FieldAnalysisData fieldData = _closedWorld.fieldAnalysis.getFieldData(
          member as JField,
        );
        if (fieldData.isEffectivelyConstant) {
          return _emitter.constantReference(fieldData.constantValue!);
        } else {
          js_ast.Name fieldName = _namer.instanceFieldPropertyName(member);
          return js('#.#', [receiver, fieldName]);
        }
      }
    }

    Map<js_ast.Name, js_ast.Expression> generatedStubs = {};

    // Two selectors may match but differ only in type.  To avoid generating
    // identical stubs for each we track untyped selectors which already have
    // stubs.
    Set<Selector> generatedSelectors = {};
    for (Selector selector in selectors.keys) {
      if (generatedSelectors.contains(selector)) continue;
      if (!selector.appliesUnnamed(member)) continue;
      if (selectors[selector]!.canHit(
        member,
        selector.memberName,
        _closedWorld,
      )) {
        generatedSelectors.add(selector);

        js_ast.Name invocationName = _namer.invocationName(selector);
        Selector callSelector = Selector.callClosureFrom(selector);
        js_ast.Name closureCallName = _namer.invocationName(callSelector);

        List<js_ast.Parameter> parameters = [];
        List<js_ast.Expression> arguments = [];
        if (isInterceptedMethod) {
          parameters.add(js_ast.Parameter(receiverArgumentName));
        }

        for (int i = 0; i < selector.argumentCount; i++) {
          String name = 'arg$i';
          parameters.add(js_ast.Parameter(name));
          arguments.add(js('#', name));
        }

        for (int i = 0; i < selector.typeArgumentCount; i++) {
          String name = '\$T${i + 1}';
          parameters.add(js_ast.Parameter(name));
          arguments.add(js('#', name));
        }

        final function =
            js('function(#) { return #.#(#); }', [
                  parameters,
                  buildGetter(),
                  closureCallName,
                  arguments,
                ])
                as js_ast.Fun;

        generatedStubs[invocationName] = function;
      }
    }

    return generatedStubs;
  }

  Map<js_ast.Name, Selector> computeSelectorsForNsmHandlers() {
    Map<js_ast.Name, Selector> jsNames = {};

    // Do not generate no such method handlers if there is no class.
    if (_codegenWorld.directlyInstantiatedClasses.isEmpty) {
      return jsNames;
    }

    void addNoSuchMethodHandlers(
      String ignore,
      Map<Selector, SelectorConstraints> selectors,
    ) {
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

        SelectorConstraints maskSet = selectors[selector]!;
        if (maskSet.needsNoSuchMethodHandling(selector, _closedWorld)) {
          js_ast.Name jsName = _namer.invocationMirrorInternalName(selector);
          jsNames[jsName] = selector;
        }
      }
    }

    _codegenWorld.forEachInvokedName(addNoSuchMethodHandlers);
    _codegenWorld.forEachInvokedGetter(addNoSuchMethodHandlers);
    _codegenWorld.forEachInvokedSetter(addNoSuchMethodHandlers);
    return jsNames;
  }

  StubMethod generateStubForNoSuchMethod(js_ast.Name name, Selector selector) {
    int type = selector.invocationMirrorKind.value;
    List<String> parameterNames =
        List.generate(selector.argumentCount, (i) => '\$$i') +
        List.generate(selector.typeArgumentCount, (i) => '\$T${i + 1}');

    List<js_ast.Expression> argNames = selector.callStructure
        .getOrderedNamedArguments()
        .map((String name) => js.string(name))
        .toList();

    js_ast.Name methodName = _namer.asName(selector.invocationMirrorMemberName);
    js_ast.Name internalName = _namer.invocationMirrorInternalName(selector);

    assert(_interceptorData.isInterceptedName(Identifiers.noSuchMethod_));
    bool isIntercepted = _interceptorData.isInterceptedName(selector.name);
    js_ast.Expression expression = js(
      '''this.#noSuchMethodName(#receiver,
                    #createInvocationMirror(#methodName,
                                            #internalName,
                                            #type,
                                            #arguments,
                                            #namedArguments,
                                            #typeArgumentCount))''',
      {
        'receiver': isIntercepted ? r'$receiver' : 'this',
        'noSuchMethodName': _namer.noSuchMethodName,
        'createInvocationMirror': _emitter.staticFunctionAccess(
          _commonElements.createInvocationMirror,
        ),
        'methodName': js.quoteName(methodName),
        'internalName': js.quoteName(internalName),
        'type': js.number(type),
        'arguments': js_ast.ArrayInitializer(
          parameterNames.map<js_ast.Expression>(js.call).toList(),
        ),
        'namedArguments': js_ast.ArrayInitializer(argNames),
        'typeArgumentCount': js.number(selector.typeArgumentCount),
      },
    );

    js_ast.Expression function;
    if (isIntercepted) {
      function = js(r'function($receiver, #) { return # }', [
        parameterNames,
        expression,
      ]);
    } else {
      function = js(r'function(#) { return # }', [parameterNames, expression]);
    }
    return StubMethod(name, function);
  }

  /// Generates a getter for the given [field].
  Method generateGetter(Field field) {
    assert(field.needsGetter);

    js_ast.Expression code;
    if (field.isElided) {
      code = js(
        "function() { return #; }",
        _emitter.constantReference(field.constantValue!),
      );
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
      js_ast.Expression fieldName = js.quoteName(field.name);
      code = js(template, fieldName);
    }
    js_ast.Name getterName = _namer.deriveGetterName(field.accessorName);
    return StubMethod(getterName, code, element: field.element);
  }

  /// Generates a setter for the given [field].
  Method generateSetter(Field field) {
    assert(field.needsUncheckedSetter);

    String template;
    js_ast.Expression code;
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
      js_ast.Expression fieldName = js.quoteName(field.name);
      code = js(template, fieldName);
    }

    js_ast.Name setterName = _namer.deriveSetterName(field.accessorName);
    return StubMethod(setterName, code, element: field.element);
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
List<js_ast.Statement> buildTearOffCode(
  CompilerOptions options,
  Emitter emitter,
  CommonElements commonElements,
) {
  FunctionEntity closureFromTearOff = commonElements.closureFromTearOff;

  js_ast.Expression closureFromTearOffAccessExpression = emitter
      .staticFunctionAccess(closureFromTearOff);

  js_ast.Statement instanceTearOffGetter;
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
        'tpFunctionsOrNames': js.string(
          TearOffParametersPropertyNames.funsOrNames,
        ),
        'createTearOffClass': closureFromTearOffAccessExpression,
      },
    );
  }

  js_ast.Statement staticTearOffGetter = js.statement(
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
