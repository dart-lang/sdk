// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.startup_emitter.model_emitter;

import 'dart:convert' show JsonEncoder;
import 'dart:math' show Random;

import 'package:js_runtime/shared/embedded_names.dart'
    show
        CLASS_FIELDS_EXTRACTOR,
        CLASS_ID_EXTRACTOR,
        CREATE_NEW_ISOLATE,
        DEFERRED_INITIALIZED,
        DEFERRED_LIBRARY_URIS,
        DEFERRED_LIBRARY_HASHES,
        GET_TYPE_FROM_NAME,
        INITIALIZE_EMPTY_INSTANCE,
        INITIALIZE_LOADED_HUNK,
        INSTANCE_FROM_CLASS_ID,
        INTERCEPTORS_BY_TAG,
        IS_HUNK_INITIALIZED,
        IS_HUNK_LOADED,
        LEAF_TAGS,
        MANGLED_GLOBAL_NAMES,
        MANGLED_NAMES,
        METADATA,
        NATIVE_SUPERCLASS_TAG_NAME,
        STATIC_FUNCTION_NAME_TO_CLOSURE,
        TYPE_TO_INTERCEPTOR_MAP,
        TYPES;

import '../../../compiler_new.dart';
import '../../common.dart';
import '../../compiler.dart' show Compiler;
import '../../constants/values.dart' show ConstantValue, FunctionConstantValue;
import '../../common_elements.dart' show CommonElements;
import '../../elements/elements.dart' show ClassElement, MethodElement;
import '../../hash/sha1.dart' show Hasher;
import '../../io/code_output.dart';
import '../../io/location_provider.dart' show LocationCollector;
import '../../io/source_map_builder.dart' show SourceMapBuilder;
import '../../js/js.dart' as js;
import '../../js_backend/js_backend.dart'
    show JavaScriptBackend, Namer, ConstantEmitter, StringBackedName;
import '../../js_backend/interceptor_data.dart';
import '../../world.dart';
import '../code_emitter_task.dart';
import '../constant_ordering.dart' show deepCompareConstants;
import '../headers.dart';
import '../js_emitter.dart' show NativeEmitter;
import '../js_emitter.dart' show buildTearOffCode, NativeGenerator;
import '../model.dart';

part 'deferred_fragment_hash.dart';
part 'fragment_emitter.dart';

class ModelEmitter {
  final Compiler compiler;
  final Namer namer;
  ConstantEmitter constantEmitter;
  final NativeEmitter nativeEmitter;
  final bool shouldGenerateSourceMap;
  final ClosedWorld _closedWorld;

  // The full code that is written to each hunk part-file.
  final Map<Fragment, CodeOutput> outputBuffers = <Fragment, CodeOutput>{};

  JavaScriptBackend get backend => compiler.backend;

  /// For deferred loading we communicate the initializers via this global var.
  static const String deferredInitializersGlobal =
      r"$__dart_deferred_initializers__";

  static const String partExtension = "part";
  static const String deferredExtension = "part.js";

  static const String typeNameProperty = r"builtin$cls";

  ModelEmitter(this.compiler, this.namer, this.nativeEmitter, this._closedWorld,
      CodeEmitterTask task, this.shouldGenerateSourceMap) {
    this.constantEmitter = new ConstantEmitter(
        compiler.options,
        _closedWorld.commonElements,
        compiler.codegenWorldBuilder,
        compiler.backend.rtiNeed,
        compiler.backend.rtiEncoder,
        namer,
        task,
        this.generateConstantReference,
        constantListGenerator);
  }

  DiagnosticReporter get reporter => compiler.reporter;

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
    if (constant.isFunction) return true; // Already emitted.
    if (constant.isPrimitive) return true; // Inlined.
    if (constant.isDummy) return true; // Inlined.
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

    // Resolve collisions in the long name by using a structural order.
    return deepCompareConstants(a, b);
  }

  js.Expression generateStaticClosureAccess(MethodElement element) {
    return js.js('#.#()', [
      namer.globalObjectForMember(element),
      namer.staticClosureName(element)
    ]);
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
    return js.js('#.#',
        [namer.globalObjectForConstant(value), namer.constantName(value)]);
  }

  int emitProgram(Program program) {
    MainFragment mainFragment = program.fragments.first;
    List<DeferredFragment> deferredFragments =
        new List<DeferredFragment>.from(program.deferredFragments);

    FragmentEmitter fragmentEmitter = new FragmentEmitter(
        compiler, namer, backend, constantEmitter, this, _closedWorld);

    Map<DeferredFragment, _DeferredFragmentHash> deferredHashTokens =
        new Map<DeferredFragment, _DeferredFragmentHash>();
    for (DeferredFragment fragment in deferredFragments) {
      deferredHashTokens[fragment] = new _DeferredFragmentHash(fragment);
    }

    js.Statement mainCode =
        fragmentEmitter.emitMainFragment(program, deferredHashTokens);

    Map<DeferredFragment, js.Expression> deferredFragmentsCode =
        <DeferredFragment, js.Expression>{};

    for (DeferredFragment fragment in deferredFragments) {
      js.Expression types =
          program.metadataTypesForOutputUnit(fragment.outputUnit);
      deferredFragmentsCode[fragment] = fragmentEmitter.emitDeferredFragment(
          fragment, types, program.holders);
    }

    js.TokenCounter counter = new js.TokenCounter();
    deferredFragmentsCode.values.forEach(counter.countTokens);
    counter.countTokens(mainCode);

    program.finalizers.forEach((js.TokenFinalizer f) => f.finalizeTokens());

    Map<DeferredFragment, String> hunkHashes =
        writeDeferredFragments(deferredFragmentsCode);

    // Now that we have written the deferred hunks, we can update the hash
    // tokens in the main-fragment.
    deferredHashTokens
        .forEach((DeferredFragment key, _DeferredFragmentHash token) {
      token.setHash(hunkHashes[key]);
    });

    writeMainFragment(mainFragment, mainCode,
        isSplit: program.deferredFragments.isNotEmpty ||
            program.hasSoftDeferredClasses ||
            compiler.options.experimentalTrackAllocations);

    if (_closedWorld.backendUsage.requiresPreamble &&
        !backend.htmlLibraryIsLoaded) {
      reporter.reportHintMessage(NO_LOCATION_SPANNABLE, MessageKind.PREAMBLE);
    }

    if (compiler.options.deferredMapUri != null) {
      writeDeferredMap();
    }

    // Return the total program size.
    return outputBuffers.values.fold(0, (a, b) => a + b.length);
  }

  /// Generates a simple header that provides the compiler's build id.
  js.Comment buildGeneratedBy() {
    String flavor = compiler.options.useContentSecurityPolicy
        ? 'fast startup, CSP'
        : 'fast startup';
    return new js.Comment(generatedBy(compiler, flavor: flavor));
  }

  /// Writes all deferred fragment's code into files.
  ///
  /// Returns a map from fragment to its hashcode (as used for the deferred
  /// library code).
  ///
  /// Updates the shared [outputBuffers] field with the output.
  Map<DeferredFragment, String> writeDeferredFragments(
      Map<DeferredFragment, js.Expression> fragmentsCode) {
    Map<DeferredFragment, String> hunkHashes = <DeferredFragment, String>{};

    fragmentsCode.forEach((DeferredFragment fragment, js.Expression code) {
      hunkHashes[fragment] = writeDeferredFragment(fragment, code);
    });

    return hunkHashes;
  }

  js.Statement buildDeferredInitializerGlobal() {
    return js.js.statement(
        'self.#deferredInitializers = '
        'self.#deferredInitializers || Object.create(null);',
        {'deferredInitializers': deferredInitializersGlobal});
  }

  // Writes the given [fragment]'s [code] into a file.
  //
  // Updates the shared [outputBuffers] field with the output.
  void writeMainFragment(MainFragment fragment, js.Statement code,
      {bool isSplit}) {
    LocationCollector locationCollector;
    List<CodeOutputListener> codeOutputListeners;
    if (shouldGenerateSourceMap) {
      locationCollector = new LocationCollector();
      codeOutputListeners = <CodeOutputListener>[locationCollector];
    }

    CodeOutput mainOutput = new StreamCodeOutput(
        compiler.outputProvider('', 'js', OutputType.js), codeOutputListeners);
    outputBuffers[fragment] = mainOutput;

    js.Program program = new js.Program([
      buildGeneratedBy(),
      new js.Comment(HOOKS_API_USAGE),
      isSplit ? buildDeferredInitializerGlobal() : new js.Block.empty(),
      code
    ]);

    mainOutput.addBuffer(js.createCodeBuffer(
        program, compiler.options, backend.sourceInformationStrategy,
        monitor: compiler.dumpInfoTask));

    if (shouldGenerateSourceMap) {
      mainOutput.add(SourceMapBuilder.generateSourceMapTag(
          compiler.options.sourceMapUri, compiler.options.outputUri));
    }

    mainOutput.close();

    if (shouldGenerateSourceMap) {
      SourceMapBuilder.outputSourceMap(
          mainOutput,
          locationCollector,
          '',
          compiler.options.sourceMapUri,
          compiler.options.outputUri,
          compiler.outputProvider);
    }
  }

  // Writes the given [fragment]'s [code] into a file.
  //
  // Returns the deferred fragment's hash.
  //
  // Updates the shared [outputBuffers] field with the output.
  String writeDeferredFragment(DeferredFragment fragment, js.Expression code) {
    List<CodeOutputListener> outputListeners = <CodeOutputListener>[];
    Hasher hasher = new Hasher();
    outputListeners.add(hasher);

    LocationCollector locationCollector;
    if (shouldGenerateSourceMap) {
      locationCollector = new LocationCollector();
      outputListeners.add(locationCollector);
    }

    String hunkPrefix = fragment.outputFileName;

    CodeOutput output = new StreamCodeOutput(
        compiler.outputProvider(
            hunkPrefix, deferredExtension, OutputType.jsPart),
        outputListeners);

    outputBuffers[fragment] = output;

    // The [code] contains the function that must be invoked when the deferred
    // hunk is loaded.
    // That function must be in a map from its hashcode to the function. Since
    // we don't know the hash before we actually emit the code we store the
    // function in a temporary field first:
    //
    //   deferredInitializer.current = <pretty-printed code>;
    //   deferredInitializer[<hash>] = deferredInitializer.current;

    js.Program program = new js.Program([
      buildGeneratedBy(),
      buildDeferredInitializerGlobal(),
      js.js.statement('$deferredInitializersGlobal.current = #', code)
    ]);

    output.addBuffer(js.createCodeBuffer(
        program, compiler.options, backend.sourceInformationStrategy,
        monitor: compiler.dumpInfoTask));

    // Make a unique hash of the code (before the sourcemaps are added)
    // This will be used to retrieve the initializing function from the global
    // variable.
    String hash = hasher.getHash();

    // Now we copy the deferredInitializer.current into its correct hash.
    output.add('\n${deferredInitializersGlobal}["$hash"] = '
        '${deferredInitializersGlobal}.current');

    if (shouldGenerateSourceMap) {
      Uri mapUri, partUri;
      Uri sourceMapUri = compiler.options.sourceMapUri;
      Uri outputUri = compiler.options.outputUri;
      String partName = "$hunkPrefix.$partExtension";
      String hunkFileName = "$hunkPrefix.$deferredExtension";

      if (sourceMapUri != null) {
        String mapFileName = hunkFileName + ".map";
        List<String> mapSegments = sourceMapUri.pathSegments.toList();
        mapSegments[mapSegments.length - 1] = mapFileName;
        mapUri =
            compiler.options.sourceMapUri.replace(pathSegments: mapSegments);
      }

      if (outputUri != null) {
        List<String> partSegments = outputUri.pathSegments.toList();
        partSegments[partSegments.length - 1] = hunkFileName;
        partUri =
            compiler.options.outputUri.replace(pathSegments: partSegments);
      }

      output.add(SourceMapBuilder.generateSourceMapTag(mapUri, partUri));
      output.close();
      SourceMapBuilder.outputSourceMap(output, locationCollector, partName,
          mapUri, partUri, compiler.outputProvider);
    } else {
      output.close();
    }

    return hash;
  }

  /// Writes a mapping from library-name to hunk files.
  ///
  /// The output is written into a separate file that can be used by outside
  /// tools.
  void writeDeferredMap() {
    Map<String, dynamic> mapping = new Map<String, dynamic>();
    // Json does not support comments, so we embed the explanation in the
    // data.
    mapping["_comment"] = "This mapping shows which compiled `.js` files are "
        "needed for a given deferred library import.";
    mapping.addAll(compiler.deferredLoadTask.computeDeferredMap());
    compiler.outputProvider(
        compiler.options.deferredMapUri.path, '', OutputType.info)
      ..add(const JsonEncoder.withIndent("  ").convert(mapping))
      ..close();
  }
}
