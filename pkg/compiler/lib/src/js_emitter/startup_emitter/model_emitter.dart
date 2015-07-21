// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.startup_emitter.model_emitter;

import '../../constants/values.dart' show ConstantValue, FunctionConstantValue;
import '../../dart2jslib.dart' show Compiler;
import '../../elements/elements.dart' show ClassElement, FunctionElement;
import '../../js/js.dart' as js;
import '../../js_backend/js_backend.dart' show
    JavaScriptBackend,
    Namer,
    ConstantEmitter;

import '../js_emitter.dart' show AstContainer, NativeEmitter;

import 'package:js_runtime/shared/embedded_names.dart' show
    CREATE_NEW_ISOLATE,
    DEFERRED_INITIALIZED,
    DEFERRED_LIBRARY_URIS,
    DEFERRED_LIBRARY_HASHES,
    GET_TYPE_FROM_NAME,
    INITIALIZE_LOADED_HUNK,
    INTERCEPTORS_BY_TAG,
    IS_HUNK_INITIALIZED,
    IS_HUNK_LOADED,
    LEAF_TAGS,
    MANGLED_GLOBAL_NAMES,
    METADATA,
    NATIVE_SUPERCLASS_TAG_NAME,
    TYPE_TO_INTERCEPTOR_MAP,
    TYPES;

import '../js_emitter.dart' show NativeGenerator, buildTearOffCode;
import '../model.dart';

part 'fragment_emitter.dart';

class ModelEmitter {
  final Compiler compiler;
  final Namer namer;
  ConstantEmitter constantEmitter;
  final NativeEmitter nativeEmitter;

  JavaScriptBackend get backend => compiler.backend;

  /// For deferred loading we communicate the initializers via this global var.
  static const String deferredInitializersGlobal =
      r"$__dart_deferred_initializers__";

  static const String deferredExtension = "part.js";

  static const String typeNameProperty = r"builtin$cls";

  ModelEmitter(Compiler compiler, Namer namer, this.nativeEmitter)
      : this.compiler = compiler,
        this.namer = namer {
    this.constantEmitter = new ConstantEmitter(
        compiler, namer, this.generateConstantReference,
        constantListGenerator);
  }

  js.Expression constantListGenerator(js.Expression array) {
    // TODO(floitsch): remove hard-coded name.
    return js.js('makeConstList(#)', [array]);
  }

  js.Expression generateEmbeddedGlobalAccess(String global) {
    return js.js(generateEmbeddedGlobalAccessString(global));
  }

  String generateEmbeddedGlobalAccessString(String global) {
    // TODO(floitsch): don't use 'init' as global embedder storage.
    return 'init.$global';
  }

  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    if (constant.isFunction) return true;    // Already emitted.
    if (constant.isPrimitive) return true;   // Inlined.
    if (constant.isDummy) return true;       // Inlined.
    return false;
  }

  // TODO(floitsch): copied from OldEmitter. Adjust or share.
  int compareConstants(ConstantValue a, ConstantValue b) {
    // Inlined constants don't affect the order and sometimes don't even have
    // names.
    int cmp1 = isConstantInlinedOrAlreadyEmitted(a) ? 0 : 1;
    int cmp2 = isConstantInlinedOrAlreadyEmitted(b) ? 0 : 1;
    if (cmp1 + cmp2 < 2) return cmp1 - cmp2;

    // Emit constant interceptors first. Constant interceptors for primitives
    // might be used by code that builds other constants.  See Issue 18173.
    if (a.isInterceptor != b.isInterceptor) {
      return a.isInterceptor ? -1 : 1;
    }

    // Sorting by the long name clusters constants with the same constructor
    // which compresses a tiny bit better.
    int r = namer.constantLongName(a).compareTo(namer.constantLongName(b));
    if (r != 0) return r;
    // Resolve collisions in the long name by using the constant name (i.e. JS
    // name) which is unique.
    return namer.constantName(a).compareTo(namer.constantName(b));
  }

  js.Expression generateStaticClosureAccess(FunctionElement element) {
    return js.js('#.#()',
        [namer.globalObjectFor(element), namer.staticClosureName(element)]);
  }

  js.Expression generateConstantReference(ConstantValue value) {
    if (value.isFunction) {
      FunctionConstantValue functionConstant = value;
      return generateStaticClosureAccess(functionConstant.element);
    }

    // We are only interested in the "isInlined" part, but it does not hurt to
    // test for the other predicates.
    if (isConstantInlinedOrAlreadyEmitted(value)) {
      return constantEmitter.generate(value);
    }
    return js.js('#.#', [namer.globalObjectForConstant(value),
    namer.constantName(value)]);
  }

  int emitProgram(Program program) {
    List<Fragment> fragments = program.fragments;
    MainFragment mainFragment = fragments.first;

    int totalSize = 0;

    FragmentEmitter fragmentEmitter =
        new FragmentEmitter(compiler, namer, backend, constantEmitter, this);

    // We have to emit the deferred fragments first, since we need their
    // deferred hash (which depends on the output) when emitting the main
    // fragment.
    List<js.Expression> fragmentsCode = fragments.skip(1).map(
            (DeferredFragment deferredFragment) {
          js.Expression types =
          program.metadataTypesForOutputUnit(deferredFragment.outputUnit);
          return fragmentEmitter.emitDeferredFragment(
              deferredFragment, types, program.holders);
        }).toList();

    js.Statement mainAst = fragmentEmitter.emitMainFragment(program);

    js.TokenCounter counter = new js.TokenCounter();
    fragmentsCode.forEach(counter.countTokens);
    counter.countTokens(mainAst);

    program.finalizers.forEach((js.TokenFinalizer f) => f.finalizeTokens());

    for (int i = 0; i < fragmentsCode.length; ++i) {
      String code = js.prettyPrint(fragmentsCode[i], compiler).getText();
      totalSize += code.length;
      compiler.outputProvider(fragments[i+1].outputFileName, deferredExtension)
        ..add(code)
        ..close();
    }

    String mainCode = js.prettyPrint(mainAst, compiler).getText();
    compiler.outputProvider(mainFragment.outputFileName, 'js')
      ..add(buildGeneratedBy(compiler))
      ..add(mainCode)
      ..close();
    totalSize += mainCode.length;

    return totalSize;
  }

  String buildGeneratedBy(compiler) {
    var suffix = '';
    if (compiler.hasBuildId) suffix = ' version: ${compiler.buildId}';
    return '// Generated by dart2js (fast startup), '
        'the Dart to JavaScript compiler$suffix.\n';
  }
}
