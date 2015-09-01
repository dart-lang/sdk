// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.startup_emitter.model_emitter;

import 'dart:convert' show JsonEncoder;

import '../../common.dart';

import '../../constants/values.dart' show ConstantValue, FunctionConstantValue;
import '../../compiler.dart' show Compiler;
import '../../diagnostics/messages.dart' show
    MessageKind;

import '../../elements/elements.dart' show ClassElement, FunctionElement;
import '../../hash/sha1.dart' show Hasher;

import '../../io/code_output.dart';

import '../../io/line_column_provider.dart' show
    LineColumnCollector,
    LineColumnProvider;

import '../../io/source_map_builder.dart' show
    SourceMapBuilder;

import '../../js/js.dart' as js;
import '../../js_backend/js_backend.dart' show
    JavaScriptBackend,
    Namer,
    ConstantEmitter;

import '../../diagnostics/spannable.dart' show
    NO_LOCATION_SPANNABLE;

import '../../util/uri_extras.dart' show
    relativize;

import '../headers.dart';
import '../js_emitter.dart' show AstContainer, NativeEmitter;

import 'package:js_runtime/shared/embedded_names.dart' show
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

import '../js_emitter.dart' show NativeGenerator, buildTearOffCode;
import '../model.dart';

part 'deferred_fragment_hash.dart';
part 'fragment_emitter.dart';

class ModelEmitter {
  final Compiler compiler;
  final Namer namer;
  ConstantEmitter constantEmitter;
  final NativeEmitter nativeEmitter;
  final bool shouldGenerateSourceMap;

  // The full code that is written to each hunk part-file.
  final Map<Fragment, CodeOutput> outputBuffers = <Fragment, CodeOutput>{};


  JavaScriptBackend get backend => compiler.backend;

  /// For deferred loading we communicate the initializers via this global var.
  static const String deferredInitializersGlobal =
      r"$__dart_deferred_initializers__";

  static const String partExtension = "part";
  static const String deferredExtension = "part.js";

  static const String typeNameProperty = r"builtin$cls";

  ModelEmitter(Compiler compiler, Namer namer, this.nativeEmitter,
               this.shouldGenerateSourceMap)
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
    MainFragment mainFragment = program.fragments.first;
    List<DeferredFragment> deferredFragments =
        new List<DeferredFragment>.from(program.deferredFragments);

    FragmentEmitter fragmentEmitter =
        new FragmentEmitter(compiler, namer, backend, constantEmitter, this);

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
    deferredHashTokens.forEach((DeferredFragment key,
                                _DeferredFragmentHash token) {
      token.setHash(hunkHashes[key]);
    });

    writeMainFragment(mainFragment, mainCode);

    if (backend.requiresPreamble &&
        !backend.htmlLibraryIsLoaded) {
      compiler.reportHint(NO_LOCATION_SPANNABLE, MessageKind.PREAMBLE);
    }

    if (compiler.deferredMapUri != null) {
      writeDeferredMap();
    }

    // Return the total program size.
    return outputBuffers.values.fold(0, (a, b) => a + b.length);
  }

  /// Generates a simple header that provides the compiler's build id.
  js.Comment buildGeneratedBy() {
    String flavor = compiler.useContentSecurityPolicy
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

  // Writes the given [fragment]'s [code] into a file.
  //
  // Updates the shared [outputBuffers] field with the output.
  void writeMainFragment(MainFragment fragment, js.Statement code) {
    LineColumnCollector lineColumnCollector;
    List<CodeOutputListener> codeOutputListeners;
    if (shouldGenerateSourceMap) {
      lineColumnCollector = new LineColumnCollector();
      codeOutputListeners = <CodeOutputListener>[lineColumnCollector];
    }

    CodeOutput mainOutput = new StreamCodeOutput(
            compiler.outputProvider('', 'js'),
            codeOutputListeners);
    outputBuffers[fragment] = mainOutput;

    js.Program program = new js.Program([
        buildGeneratedBy(),
        new js.Comment(HOOKS_API_USAGE),
        code]);

    mainOutput.addBuffer(js.prettyPrint(program, compiler,
        monitor: compiler.dumpInfoTask));

    if (shouldGenerateSourceMap) {
      mainOutput.add(
          generateSourceMapTag(compiler.sourceMapUri, compiler.outputUri));
    }

    mainOutput.close();

    if (shouldGenerateSourceMap) {
      outputSourceMap(mainOutput, lineColumnCollector, '',
          compiler.sourceMapUri, compiler.outputUri);
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

    LineColumnCollector lineColumnCollector;
    if (shouldGenerateSourceMap) {
      lineColumnCollector = new LineColumnCollector();
      outputListeners.add(lineColumnCollector);
    }

    String hunkPrefix = fragment.outputFileName;

    CodeOutput output = new StreamCodeOutput(
        compiler.outputProvider(hunkPrefix, deferredExtension),
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
        js.js.statement('$deferredInitializersGlobal.current = #', code)]);

    output.addBuffer(js.prettyPrint(program, compiler,
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
      Uri sourceMapUri = compiler.sourceMapUri;
      Uri outputUri = compiler.outputUri;
      String partName = "$hunkPrefix.$partExtension";
      String hunkFileName = "$hunkPrefix.$deferredExtension";

      if (sourceMapUri != null) {
        String mapFileName = hunkFileName + ".map";
        List<String> mapSegments = sourceMapUri.pathSegments.toList();
        mapSegments[mapSegments.length - 1] = mapFileName;
        mapUri = compiler.sourceMapUri.replace(pathSegments: mapSegments);
      }

      if (outputUri != null) {
        List<String> partSegments = outputUri.pathSegments.toList();
        partSegments[partSegments.length - 1] = hunkFileName;
        partUri = compiler.outputUri.replace(pathSegments: partSegments);
      }

      output.add(generateSourceMapTag(mapUri, partUri));
      output.close();
      outputSourceMap(output, lineColumnCollector, partName, mapUri, partUri);
    } else {
      output.close();
    }

    return hash;
  }

  String generateSourceMapTag(Uri sourceMapUri, Uri fileUri) {
    if (sourceMapUri != null && fileUri != null) {
      String sourceMapFileName = relativize(fileUri, sourceMapUri, false);
      return '''

//# sourceMappingURL=$sourceMapFileName
''';
    }
    return '';
  }


  void outputSourceMap(CodeOutput output,
                       LineColumnProvider lineColumnProvider,
                       String name,
                       [Uri sourceMapUri,
                       Uri fileUri]) {
    if (!shouldGenerateSourceMap) return;
    // Create a source file for the compilation output. This allows using
    // [:getLine:] to transform offsets to line numbers in [SourceMapBuilder].
    SourceMapBuilder sourceMapBuilder =
    new SourceMapBuilder(sourceMapUri, fileUri, lineColumnProvider);
    output.forEachSourceLocation(sourceMapBuilder.addMapping);
    String sourceMap = sourceMapBuilder.build();
    compiler.outputProvider(name, 'js.map')
      ..add(sourceMap)
      ..close();
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
    compiler.outputProvider(compiler.deferredMapUri.path, 'deferred_map')
      ..add(const JsonEncoder.withIndent("  ").convert(mapping))
      ..close();
  }
}
