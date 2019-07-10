// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.interceptor_stub_generator;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;

import '../common_elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart' show InterfaceType;
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/namer.dart' show Namer;
import '../js_backend/custom_elements_analysis.dart'
    show CustomElementsCodegenAnalysis;
import '../js_backend/native_data.dart';
import '../js_backend/interceptor_data.dart';
import '../native/enqueue.dart';
import '../universe/codegen_world_builder.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show JClosedWorld;

import 'code_emitter_task.dart' show Emitter;

class InterceptorStubGenerator {
  final CommonElements _commonElements;
  final Emitter _emitter;
  final NativeCodegenEnqueuer _nativeCodegenEnqueuer;
  final Namer _namer;
  final CustomElementsCodegenAnalysis _customElementsCodegenAnalysis;
  final CodegenWorld _codegenWorld;
  final JClosedWorld _closedWorld;

  InterceptorStubGenerator(
      this._commonElements,
      this._emitter,
      this._nativeCodegenEnqueuer,
      this._namer,
      this._customElementsCodegenAnalysis,
      this._codegenWorld,
      this._closedWorld);

  NativeData get _nativeData => _closedWorld.nativeData;

  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  jsAst.Expression generateGetInterceptorMethod(
      SpecializedGetInterceptor interceptor) {
    Set<ClassEntity> classes = interceptor.classes;

    jsAst.Expression interceptorFor(ClassEntity cls) {
      return _emitter.interceptorPrototypeAccess(cls);
    }

    /// Build a JavaScript AST node for doing a type check on
    /// [cls]. [cls] must be a non-native interceptor class.
    jsAst.Statement buildInterceptorCheck(ClassEntity cls) {
      jsAst.Expression condition;
      assert(_interceptorData.isInterceptedClass(cls));
      if (cls == _commonElements.jsBoolClass) {
        condition = js('(typeof receiver) == "boolean"');
      } else if (cls == _commonElements.jsIntClass ||
          cls == _commonElements.jsDoubleClass ||
          cls == _commonElements.jsNumberClass) {
        throw 'internal error';
      } else if (cls == _commonElements.jsArrayClass ||
          cls == _commonElements.jsMutableArrayClass ||
          cls == _commonElements.jsFixedArrayClass ||
          cls == _commonElements.jsExtendableArrayClass) {
        condition = js('receiver.constructor == Array');
      } else if (cls == _commonElements.jsStringClass) {
        condition = js('(typeof receiver) == "string"');
      } else if (cls == _commonElements.jsNullClass) {
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
    bool anyNativeClasses = _nativeCodegenEnqueuer.hasInstantiatedNativeClasses;

    for (ClassEntity cls in classes) {
      if (cls == _commonElements.jsArrayClass ||
          cls == _commonElements.jsMutableArrayClass ||
          cls == _commonElements.jsFixedArrayClass ||
          cls == _commonElements.jsExtendableArrayClass)
        hasArray = true;
      else if (cls == _commonElements.jsBoolClass)
        hasBool = true;
      else if (cls == _commonElements.jsDoubleClass)
        hasDouble = true;
      else if (cls == _commonElements.jsIntClass)
        hasInt = true;
      else if (cls == _commonElements.jsNullClass)
        hasNull = true;
      else if (cls == _commonElements.jsNumberClass)
        hasNumber = true;
      else if (cls == _commonElements.jsStringClass)
        hasString = true;
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
          if (_nativeData.isNativeOrExtendsNative(cls)) hasNative = true;
        }
      }
    }
    if (hasDouble) {
      hasNumber = true;
    }
    if (hasInt) hasNumber = true;

    if (classes.containsAll(_interceptorData.interceptedClasses)) {
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
      jsAst.Expression interceptorForNumber = interceptorFor(hasDouble
          ? _commonElements.jsDoubleClass
          : _commonElements.jsNumberClass);

      if (hasInt) {
        whenNumber = js.statement('''{
            if (Math.floor(receiver) == receiver) return #;
            return #;
        }''',
            [interceptorFor(_commonElements.jsIntClass), interceptorForNumber]);
      } else {
        whenNumber = js.statement('return #', interceptorForNumber);
      }
      statements
          .add(js.statement('if (typeof receiver == "number") #;', whenNumber));
    }

    if (hasString) {
      statements.add(buildInterceptorCheck(_commonElements.jsStringClass));
    }
    if (hasNull) {
      statements.add(buildInterceptorCheck(_commonElements.jsNullClass));
    } else {
      // Returning "undefined" or "null" here will provoke a JavaScript
      // TypeError which is later identified as a null-error by
      // [unwrapException] in js_helper.dart.
      statements.add(js.statement('if (receiver == null) return receiver'));
    }
    if (hasBool) {
      statements.add(buildInterceptorCheck(_commonElements.jsBoolClass));
    }
    // TODO(ahe): It might be faster to check for Array before
    // function and bool.
    if (hasArray) {
      statements.add(buildInterceptorCheck(_commonElements.jsArrayClass));
    }

    if (hasNative) {
      statements.add(js.statement(r'''{
          if (typeof receiver != "object") {
              if (typeof receiver == "function" ) return #;
              return receiver;
          }
          if (receiver instanceof #) return receiver;
          return #(receiver);
      }''', [
        interceptorFor(_commonElements.jsJavaScriptFunctionClass),
        _emitter.constructorAccess(_commonElements.objectClass),
        _emitter
            .staticFunctionAccess(_commonElements.getNativeInterceptorMethod)
      ]));
    } else {
      ClassEntity jsUnknown = _commonElements.jsUnknownJavaScriptObjectClass;
      if (_codegenWorld.directlyInstantiatedClasses.contains(jsUnknown)) {
        statements.add(js.statement('if (!(receiver instanceof #)) return #;', [
          _emitter.constructorAccess(_commonElements.objectClass),
          interceptorFor(jsUnknown)
        ]));
      }

      statements.add(js.statement('return receiver'));
    }

    return js('''function(receiver) { #; }''', new jsAst.Block(statements));
  }

  jsAst.Call _generateIsJsIndexableCall(
      jsAst.Expression use1, jsAst.Expression use2) {
    String dispatchPropertyName = embeddedNames.DISPATCH_PROPERTY_NAME;
    jsAst.Expression dispatchProperty =
        _emitter.generateEmbeddedGlobalAccess(dispatchPropertyName);

    // We pass the dispatch property record to the isJsIndexable
    // helper rather than reading it inside the helper to increase the
    // chance of making the dispatch record access monomorphic.
    jsAst.PropertyAccess record =
        new jsAst.PropertyAccess(use2, dispatchProperty);

    List<jsAst.Expression> arguments = <jsAst.Expression>[use1, record];
    FunctionEntity helper = _commonElements.isJsIndexable;
    jsAst.Expression helperExpression = _emitter.staticFunctionAccess(helper);
    return new jsAst.Call(helperExpression, arguments);
  }

  // Returns a statement that takes care of performance critical
  // common case for a one-shot interceptor, or null if there is no
  // fast path.
  jsAst.Statement _fastPathForOneShotInterceptor(
      Selector selector, Set<ClassEntity> classes) {
    if (selector.isOperator) {
      String name = selector.name;
      if (name == '==') {
        return js.statement('''{
          if (receiver == null) return a0 == null;
          if (typeof receiver != "object")
            return a0 != null && receiver === a0;
        }''');
      }
      if (!classes.contains(_commonElements.jsIntClass) &&
          !classes.contains(_commonElements.jsNumberClass) &&
          !classes.contains(_commonElements.jsDoubleClass)) {
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
        return js
            .statement('if (typeof receiver == "number") return -receiver');
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
      //    if (typeof a0 === "number") {
      //      if (receiver.constructor == Array ||
      //          typeof receiver == "string") {
      //        if (a0 >>> 0 === a0 && a0 < receiver.length) {
      //          return receiver[a0];
      //        }
      //      }
      //    }
      //
      // For an index set operation, this code generates:
      //
      //    if (typeof a0 === "number") {
      //      if (receiver.constructor == Array && !receiver.immutable$list) {
      //        if (a0 >>> 0 === a0 && a0 < receiver.length) {
      //          return receiver[a0] = a1;
      //        }
      //      }
      //    }
      bool containsArray = classes.contains(_commonElements.jsArrayClass);
      bool containsString = classes.contains(_commonElements.jsStringClass);
      bool containsJsIndexable = _closedWorld
              .isImplemented(_commonElements.jsIndexingBehaviorInterface) &&
          classes.any((cls) {
            return _closedWorld.classHierarchy
                .isSubtypeOf(cls, _commonElements.jsIndexingBehaviorInterface);
          });
      // The index set operator requires a check on its set value in
      // checked mode, so we don't optimize the interceptor if the
      // _compiler has type assertions enabled.
      if (selector.isIndexSet &&
          // TODO(johnniwinther): Support annotations on the possible targets
          // and used their parameter check policy here.
          (_closedWorld.annotationsData
                  .getParameterCheckPolicy(null)
                  .isEmitted ||
              !containsArray)) {
        return null;
      }
      if (!containsArray && !containsString) {
        return null;
      }
      jsAst.Expression arrayCheck = js('receiver.constructor == Array');

      // Lazy generation of the indexable check. If indexable behavior isn't
      // used, the isJsIndexable function isn't part of the closed world.
      jsAst.Expression genericIndexableCheck() =>
          _generateIsJsIndexableCall(js('receiver'), js('receiver'));

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
          typeCheck = orExp(typeCheck, genericIndexableCheck());
        }

        return js.statement('''
          if (typeof a0 === "number")
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
          typeCheck = orExp(typeCheck, genericIndexableCheck());
        }

        return js.statement(r'''
          if (typeof a0 === "number")
            if (# && !receiver.immutable$list &&
                (a0 >>> 0) === a0 && a0 < receiver.length)
              return receiver[a0] = a1;
          ''', typeCheck);
      }
    } else if (selector.isCall) {
      if (selector.name == 'abs' && selector.argumentCount == 0) {
        return js.statement(r'''
          if (typeof receiver === "number") return Math.abs(receiver);
        ''');
      }
    } else if (selector.isGetter) {
      if (selector.name == 'sign') {
        return js.statement(r'''
          if (typeof receiver === "number")
             return receiver > 0 ? 1 : receiver < 0 ? -1 : receiver;
        ''');
      }
    }
    return null;
  }

  jsAst.Expression generateOneShotInterceptor(OneShotInterceptor interceptor) {
    Selector selector = interceptor.selector;
    Set<ClassEntity> classes = interceptor.classes;
    jsAst.Name getInterceptorName = _namer.nameForGetInterceptor(classes);

    List<String> parameterNames = <String>[];
    parameterNames.add('receiver');

    if (selector.isSetter) {
      parameterNames.add('value');
    } else {
      for (int i = 0; i < selector.argumentCount; i++) {
        parameterNames.add('a$i');
      }
      for (int i = 1; i <= selector.typeArgumentCount; i++) {
        parameterNames.add('\$T$i');
      }
    }

    jsAst.Name invocationName = _namer.invocationName(selector);
    String globalObject =
        _namer.globalObjectForLibrary(_commonElements.interceptorsLibrary);

    jsAst.Statement optimizedPath =
        _fastPathForOneShotInterceptor(selector, classes);
    if (optimizedPath == null) optimizedPath = js.statement(';');

    return js('function(#) { #; return #.#(receiver).#(#) }', [
      parameterNames,
      optimizedPath,
      globalObject,
      getInterceptorName,
      invocationName,
      parameterNames
    ]);
  }

  jsAst.ArrayInitializer generateTypeToInterceptorMap() {
    // TODO(sra): Perhaps inject a constant instead?
    CustomElementsCodegenAnalysis analysis = _customElementsCodegenAnalysis;
    if (!analysis.needsTable) return null;

    List<jsAst.Expression> elements = <jsAst.Expression>[];
    Iterable<ConstantValue> constants =
        _codegenWorld.getConstantsForEmission(_emitter.compareConstants);
    for (ConstantValue constant in constants) {
      if (constant is TypeConstantValue &&
          constant.representedType is InterfaceType) {
        InterfaceType type = constant.representedType;
        ClassEntity classElement = type.element;
        if (!analysis.needsClass(classElement)) continue;

        elements.add(_emitter.constantReference(constant));
        elements.add(_emitter.interceptorClassAccess(classElement));

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
        var properties = <jsAst.Property>[];
        for (ConstructorEntity member in analysis.constructors(classElement)) {
          properties.add(new jsAst.Property(
              js.string(member.name), _emitter.staticFunctionAccess(member)));
        }

        var map = new jsAst.ObjectInitializer(properties);
        elements.add(map);
      }
    }

    return new jsAst.ArrayInitializer(elements);
  }
}
