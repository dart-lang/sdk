// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.class_stub_generator;

import '../common/names.dart' show Identifiers, Selectors;
import '../common_elements.dart' show CommonElements;
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

    Map<jsAst.Name, jsAst.Expression> generatedStubs =
        <jsAst.Name, jsAst.Expression>{};

    // Two selectors may match but differ only in type.  To avoid generating
    // identical stubs for each we track untyped selectors which already have
    // stubs.
    Set<Selector> generatedSelectors = new Set<Selector>();
    for (Selector selector in selectors.keys) {
      if (generatedSelectors.contains(selector)) continue;
      if (!selector.appliesUnnamed(member)) continue;
      if (selectors[selector]
          .canHit(member, selector.memberName, _closedWorld)) {
        generatedSelectors.add(selector);

        jsAst.Name invocationName = _namer.invocationName(selector);
        Selector callSelector = new Selector.callClosureFrom(selector);
        jsAst.Name closureCallName = _namer.invocationName(callSelector);

        List<jsAst.Parameter> parameters = <jsAst.Parameter>[];
        List<jsAst.Expression> arguments = <jsAst.Expression>[];
        if (isInterceptedMethod) {
          parameters.add(new jsAst.Parameter(receiverArgumentName));
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
    Map<jsAst.Name, Selector> jsNames = <jsAst.Name, Selector>{};

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
        new List.generate(selector.argumentCount, (i) => '\$$i') +
            new List.generate(selector.typeArgumentCount, (i) => '\$T${i + 1}');

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
      'arguments': new jsAst.ArrayInitializer(
          parameterNames.map<jsAst.Expression>(js).toList()),
      'namedArguments': new jsAst.ArrayInitializer(argNames),
      'typeArgumentCount': js.number(selector.typeArgumentCount)
    });

    jsAst.Expression function;
    if (isIntercepted) {
      function = js(
          r'function($receiver, #) { return # }', [parameterNames, expression]);
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
List<jsAst.Statement> buildTearOffCode(CompilerOptions options, Emitter emitter,
    Namer namer, CommonElements commonElements) {
  FunctionEntity closureFromTearOff = commonElements.closureFromTearOff;
  jsAst.Expression tearOffAccessExpression;
  jsAst.Expression tearOffGlobalObjectString;
  jsAst.Expression tearOffGlobalObject;
  if (closureFromTearOff != null) {
    tearOffAccessExpression = emitter.staticFunctionAccess(closureFromTearOff);
    tearOffGlobalObject =
        js.stringPart(namer.globalObjectForMember(closureFromTearOff));
    tearOffGlobalObjectString =
        js.string(namer.globalObjectForMember(closureFromTearOff));
  } else {
    // Default values for mocked-up test libraries.
    tearOffAccessExpression =
        js(r'''function() { throw "Helper 'closureFromTearOff' missing." }''');
    tearOffGlobalObjectString = js.string('MissingHelperFunction');
    tearOffGlobalObject = js(
        r'''(function() { throw "Helper 'closureFromTearOff' missing." })()''');
  }

  jsAst.Statement tearOffGetter;
  if (!options.useContentSecurityPolicy) {
    jsAst.Expression tearOffAccessText = new jsAst.UnparsedNode(
        tearOffAccessExpression, options.enableMinification, false);
    tearOffGetter = js.statement('''
function tearOffGetter(funcs, applyTrampolineIndex, reflectionInfo, name, isIntercepted) {
  return isIntercepted
      ? new Function("funcs", "applyTrampolineIndex", "reflectionInfo", "name",
                     #tearOffGlobalObjectString, "c",
          "return function tearOff_" + name + (functionCounter++) + "(receiver) {" +
            "if (c === null) c = " + #tearOffAccessText + "(" +
                "this, funcs, applyTrampolineIndex, reflectionInfo, false, true, name);" +
                "return new c(this, funcs[0], receiver, name);" +
           "}")(funcs, applyTrampolineIndex, reflectionInfo, name, #tearOffGlobalObject, null)
      : new Function("funcs", "applyTrampolineIndex", "reflectionInfo", "name",
                     #tearOffGlobalObjectString, "c",
          "return function tearOff_" + name + (functionCounter++)+ "() {" +
            "if (c === null) c = " + #tearOffAccessText + "(" +
                "this, funcs, applyTrampolineIndex, reflectionInfo, false, false, name);" +
                "return new c(this, funcs[0], null, name);" +
             "}")(funcs, applyTrampolineIndex, reflectionInfo, name, #tearOffGlobalObject, null);
}''', {
      'tearOffAccessText': tearOffAccessText,
      'tearOffGlobalObject': tearOffGlobalObject,
      'tearOffGlobalObjectString': tearOffGlobalObjectString
    });
  } else {
    tearOffGetter = js.statement('''
      function tearOffGetter(funcs, applyTrampolineIndex, reflectionInfo, name, isIntercepted) {
        var cache = null;
        return isIntercepted
            ? function(receiver) {
                if (cache === null) cache = #(
                    this, funcs, applyTrampolineIndex, reflectionInfo, false, true, name);
                return new cache(this, funcs[0], receiver, name);
              }
            : function() {
                if (cache === null) cache = #(
                    this, funcs, applyTrampolineIndex, reflectionInfo, false, false, name);
                return new cache(this, funcs[0], null, name);
              };
      }''', [tearOffAccessExpression, tearOffAccessExpression]);
  }

  jsAst.Statement tearOff = js.statement('''
      function tearOff(funcs, applyTrampolineIndex,
          reflectionInfo, isStatic, name, isIntercepted) {
      var cache = null;
      return isStatic
          ? function() {
              if (cache === null) cache = #tearOff(
                  this, funcs, applyTrampolineIndex,
                  reflectionInfo, true, false, name).prototype;
              return cache;
            }
          : tearOffGetter(funcs, applyTrampolineIndex,
              reflectionInfo, name, isIntercepted);
    }''', {'tearOff': tearOffAccessExpression});

  return <jsAst.Statement>[tearOffGetter, tearOff];
}
