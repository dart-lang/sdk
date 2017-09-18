// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.class_stub_generator;

import '../common/names.dart' show Identifiers;
import '../common_elements.dart' show CommonElements;
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/namer.dart' show Namer;
import '../js_backend/interceptor_data.dart' show InterceptorData;
import '../options.dart';
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart'
    show CodegenWorldBuilder, SelectorConstraints;
import '../world.dart' show ClosedWorld;

import 'code_emitter_task.dart';
import 'model.dart';

class ClassStubGenerator {
  final Namer _namer;
  final CodegenWorldBuilder _worldBuilder;
  final ClosedWorld _closedWorld;
  final bool enableMinification;
  final Emitter _emitter;
  final CommonElements _commonElements;

  ClassStubGenerator(this._emitter, this._commonElements, this._namer,
      this._worldBuilder, this._closedWorld,
      {this.enableMinification});

  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  jsAst.Expression generateClassConstructor(
      ClassEntity classElement, List<jsAst.Name> fields, bool hasRtiField) {
    // TODO(sra): Implement placeholders in VariableDeclaration position:
    //
    //     String constructorName = namer.getNameOfClass(classElement);
    //     return js.statement('function #(#) { #; }',
    //        [ constructorName, fields,
    //            fields.map(
    //                (name) => js('this.# = #', [name, name]))]));
    var typeParameters = const <jsAst.Parameter>[];
    dynamic typeInits = const <jsAst.Expression>[];
    if (hasRtiField) {
      dynamic rtiName = _namer.rtiFieldJsName;
      typeParameters = rtiName;
      typeInits = js('this.# = #', [rtiName, rtiName]);
    }
    List<jsAst.Parameter> parameters = new List<jsAst.Parameter>.generate(
        fields.length, (i) => new jsAst.Parameter('t$i'));
    List<jsAst.Expression> fieldInitializers =
        new List<jsAst.Expression>.generate(fields.length, (i) {
      return js('this.# = #', [fields[i], parameters[i]]);
    });
    return js('function(#, #) { #; #; this.#();}', [
      parameters,
      typeParameters,
      fieldInitializers,
      typeInits,
      _namer.deferredAction
    ]);
  }

  jsAst.Expression generateGetter(MemberEntity member, jsAst.Name fieldName) {
    ClassEntity cls = member.enclosingClass;
    String receiver =
        _interceptorData.isInterceptedClass(cls) ? 'receiver' : 'this';
    List<String> args =
        _interceptorData.isInterceptedMethod(member) ? ['receiver'] : [];
    return js('function(#) { return #.# }', [args, receiver, fieldName]);
  }

  jsAst.Expression generateSetter(MemberEntity member, jsAst.Name fieldName) {
    ClassEntity cls = member.enclosingClass;
    String receiver =
        _interceptorData.isInterceptedClass(cls) ? 'receiver' : 'this';
    List<String> args =
        _interceptorData.isInterceptedMethod(member) ? ['receiver'] : [];
    // TODO(floitsch): remove 'return'?
    return js(
        'function(#, v) { return #.# = v; }', [args, receiver, fieldName]);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [member] must be a declaration element.
   */
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
        jsAst.Name fieldName = _namer.instanceFieldPropertyName(member);
        return js('#.#', [receiver, fieldName]);
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
      if (selectors[selector].applies(member, selector, _closedWorld)) {
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
          parameters.add(new jsAst.Parameter(name));
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
    if (_worldBuilder.directlyInstantiatedClasses.isEmpty) {
      return jsNames;
    }

    void addNoSuchMethodHandlers(
        String ignore, Map<Selector, SelectorConstraints> selectors) {
      for (Selector selector in selectors.keys) {
        SelectorConstraints maskSet = selectors[selector];
        if (maskSet.needsNoSuchMethodHandling(selector, _closedWorld)) {
          jsAst.Name jsName = _namer.invocationMirrorInternalName(selector);
          jsNames[jsName] = selector;
        }
      }
    }

    _worldBuilder.forEachInvokedName(addNoSuchMethodHandlers);
    _worldBuilder.forEachInvokedGetter(addNoSuchMethodHandlers);
    _worldBuilder.forEachInvokedSetter(addNoSuchMethodHandlers);
    return jsNames;
  }

  StubMethod generateStubForNoSuchMethod(jsAst.Name name, Selector selector) {
    // Values match JSInvocationMirror in js-helper library.
    int type = selector.invocationMirrorKind;
    List<String> parameterNames =
        new List.generate(selector.argumentCount, (i) => '\$$i');

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
                                            #namedArguments))''', {
      'receiver': isIntercepted ? r'$receiver' : 'this',
      'noSuchMethodName': _namer.noSuchMethodName,
      'createInvocationMirror':
          _emitter.staticFunctionAccess(_commonElements.createInvocationMirror),
      'methodName':
          js.quoteName(enableMinification ? internalName : methodName),
      'internalName': js.quoteName(internalName),
      'type': js.number(type),
      'arguments': new jsAst.ArrayInitializer(parameterNames.map(js).toList()),
      'namedArguments': new jsAst.ArrayInitializer(argNames)
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
///    member that is torn off. There can be more than one, since a member
///    can have several stubs.
///    Each function must have the `$callName` property set.
///   * `reflectionInfo`: contains reflective information, and the function
///    type. TODO(floitsch): point to where this is specified.
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
    jsAst.Expression tearOffAccessText =
        new jsAst.UnparsedNode(tearOffAccessExpression, options, false);
    tearOffGetter = js.statement('''
function tearOffGetter(funcs, reflectionInfo, name, isIntercepted) {
  return isIntercepted
      ? new Function("funcs", "reflectionInfo", "name",
                     #tearOffGlobalObjectString, "c",
          "return function tearOff_" + name + (functionCounter++) + "(x) {" +
            "if (c === null) c = " + #tearOffAccessText + "(" +
                "this, funcs, reflectionInfo, false, [x], name);" +
                "return new c(this, funcs[0], x, name);" +
                "}")(funcs, reflectionInfo, name, #tearOffGlobalObject, null)
      : new Function("funcs", "reflectionInfo", "name",
                     #tearOffGlobalObjectString, "c",
          "return function tearOff_" + name + (functionCounter++)+ "() {" +
            "if (c === null) c = " + #tearOffAccessText + "(" +
                "this, funcs, reflectionInfo, false, [], name);" +
                "return new c(this, funcs[0], null, name);" +
                "}")(funcs, reflectionInfo, name, #tearOffGlobalObject, null);
}''', {
      'tearOffAccessText': tearOffAccessText,
      'tearOffGlobalObject': tearOffGlobalObject,
      'tearOffGlobalObjectString': tearOffGlobalObjectString
    });
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
    }''', {'tearOff': tearOffAccessExpression});

  return <jsAst.Statement>[tearOffGetter, tearOff];
}
