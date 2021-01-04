// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.startup_emitter.model_emitter;

import 'dart:convert' show JsonEncoder;
import 'dart:math' show Random;

import 'package:js_runtime/shared/embedded_names.dart'
    show
        ARRAY_RTI_PROPERTY,
        DEFERRED_INITIALIZED,
        DEFERRED_LIBRARY_PARTS,
        DEFERRED_PART_URIS,
        DEFERRED_PART_HASHES,
        GET_TYPE_FROM_NAME,
        INITIALIZE_LOADED_HUNK,
        INTERCEPTORS_BY_TAG,
        IS_HUNK_INITIALIZED,
        IS_HUNK_LOADED,
        JsGetName,
        LEAF_TAGS,
        MANGLED_GLOBAL_NAMES,
        MANGLED_NAMES,
        METADATA,
        NATIVE_SUPERCLASS_TAG_NAME,
        RTI_UNIVERSE,
        RtiUniverseFieldNames,
        TYPE_TO_INTERCEPTOR_MAP,
        TYPES;

import 'package:js_ast/src/precedence.dart' as js_precedence;

import '../../../compiler_new.dart';
import '../../common.dart';
import '../../common/tasks.dart';
import '../../constants/values.dart'
    show ConstantValue, FunctionConstantValue, NullConstantValue;
import '../../common_elements.dart' show CommonElements, JElementEnvironment;
import '../../deferred_load.dart' show OutputUnit;
import '../../dump_info.dart';
import '../../elements/entities.dart';
import '../../elements/types.dart';
import '../../hash/sha1.dart' show Hasher;
import '../../io/code_output.dart';
import '../../io/location_provider.dart' show LocationCollector;
import '../../io/source_information.dart';
import '../../io/source_map_builder.dart' show SourceMapBuilder;
import '../../js/js.dart' as js;
import '../../js_backend/js_backend.dart'
    show Namer, ConstantEmitter, StringBackedName;
import '../../js_backend/js_interop_analysis.dart' as jsInteropAnalysis;
import '../../js_backend/runtime_types.dart';
import '../../js_backend/runtime_types_codegen.dart';
import '../../js_backend/runtime_types_new.dart'
    show RecipeEncoder, RecipeEncoderImpl, Ruleset, RulesetEncoder;
import '../../js_backend/runtime_types_resolution.dart' show RuntimeTypesNeed;
import '../../js_backend/type_reference.dart'
    show
        TypeReferenceFinalizer,
        TypeReferenceFinalizerImpl,
        TypeReferenceResource;
import '../../js_backend/string_reference.dart'
    show
        StringReferenceFinalizer,
        StringReferenceFinalizerImpl,
        StringReferenceResource;
import '../../options.dart';
import '../../universe/class_hierarchy.dart' show ClassHierarchy;
import '../../universe/codegen_world_builder.dart' show CodegenWorld;
import '../../world.dart';
import '../code_emitter_task.dart';
import '../constant_ordering.dart' show ConstantOrdering;
import '../headers.dart';
import '../js_emitter.dart' show buildTearOffCode, NativeGenerator;
import '../model.dart';
import '../native_emitter.dart';
import 'fragment_merger.dart';

part 'fragment_emitter.dart';

class ModelEmitter {
  final CompilerOptions _options;
  final DiagnosticReporter _reporter;
  final CompilerOutput _outputProvider;
  final DumpInfoTask _dumpInfoTask;
  final Namer _namer;
  final CompilerTask _task;
  final Emitter _emitter;
  ConstantEmitter _constantEmitter;
  final NativeEmitter _nativeEmitter;
  final bool _shouldGenerateSourceMap;
  final JClosedWorld _closedWorld;
  final ConstantOrdering _constantOrdering;
  final SourceInformationStrategy _sourceInformationStrategy;

  // The full code that is written to each hunk part-file.
  final Map<OutputUnit, CodeOutput> emittedOutputBuffers = {};

  final Set<OutputUnit> omittedOutputUnits = {};

  List<PreFragment> preDeferredFragmentsForTesting;

  /// For deferred loading we communicate the initializers via this global var.
  static const String deferredInitializersGlobal =
      r"$__dart_deferred_initializers__";

  static const String partExtension = "part";
  static const String deferredExtension = "part.js";

  static const String typeNameProperty = r"builtin$cls";

  ModelEmitter(
      this._options,
      this._reporter,
      this._outputProvider,
      this._dumpInfoTask,
      this._namer,
      this._closedWorld,
      this._task,
      this._emitter,
      this._nativeEmitter,
      this._sourceInformationStrategy,
      RecipeEncoder rtiRecipeEncoder,
      this._shouldGenerateSourceMap)
      : _constantOrdering = new ConstantOrdering(_closedWorld.sorter) {
    this._constantEmitter = new ConstantEmitter(
        _options,
        _closedWorld.commonElements,
        _closedWorld.elementEnvironment,
        _closedWorld.rtiNeed,
        rtiRecipeEncoder,
        _closedWorld.fieldAnalysis,
        _emitter,
        this.generateConstantReference,
        constantListGenerator);
  }

  js.Expression constantListGenerator(js.Expression array) {
    // TODO(floitsch): remove hard-coded name.
    return js.js('makeConstList(#)', [array]);
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
    int r = _namer.constantLongName(a).compareTo(_namer.constantLongName(b));
    if (r != 0) return r;

    // Resolve collisions in the long name by using a structural order.
    return _constantOrdering.compare(a, b);
  }

  js.Expression generateConstantReference(ConstantValue value) {
    if (value.isFunction) {
      FunctionConstantValue functionConstant = value;
      return _emitter.staticClosureAccess(functionConstant.element);
    }

    // We are only interested in the "isInlined" part, but it does not hurt to
    // test for the other predicates.
    if (isConstantInlinedOrAlreadyEmitted(value)) {
      return _constantEmitter.generate(value);
    }
    return js.js('#.#',
        [_namer.globalObjectForConstant(value), _namer.constantName(value)]);
  }

  bool get shouldMergeFragments => _options.mergeFragmentsThreshold != null;

  int emitProgram(Program program, CodegenWorld codegenWorld) {
    MainFragment mainFragment = program.fragments.first;
    List<DeferredFragment> deferredFragments =
        new List<DeferredFragment>.from(program.deferredFragments);

    FragmentEmitter fragmentEmitter = new FragmentEmitter(
        _options,
        _dumpInfoTask,
        _namer,
        _emitter,
        _constantEmitter,
        this,
        _nativeEmitter,
        _closedWorld,
        codegenWorld);

    var deferredLoadingState = new DeferredLoadingState();
    js.Statement mainCode =
        fragmentEmitter.emitMainFragment(program, deferredLoadingState);

    // In order to get size estimates, we partially emit deferred fragments.
    List<PreFragment> preDeferredFragments = [];
    Map<DeferredFragment, PreFragment> preFragmentMap = {};
    _task.measureSubtask('emit prefragments', () {
      for (var fragment in deferredFragments) {
        var preFragment =
            fragmentEmitter.emitPreFragment(fragment, shouldMergeFragments);
        preFragmentMap[fragment] = preFragment;
        preDeferredFragments.add(preFragment);
      }
    });

    // Attach dependencies to each PreFragment.
    FragmentMerger.attachDependencies(program.loadMap, preFragmentMap);

    if (shouldMergeFragments) {
      preDeferredFragments = _task.measureSubtask('merge fragments', () {
        FragmentMerger fragmentMerger = FragmentMerger(_options);
        return fragmentMerger.mergeFragments(preDeferredFragments);
      });
    }

    // If necessary, we retain the merged PreFragments for testing.
    if (retainDataForTesting) {
      preDeferredFragmentsForTesting = preDeferredFragments;
    }

    Map<DeferredFragment, FinalizedFragment> fragmentMap = {};
    Map<FinalizedFragment, js.Expression> deferredFragmentsCode = {};
    for (var preDeferredFragment in preDeferredFragments) {
      var finalizedFragment =
          preDeferredFragment.finalize(program, fragmentMap);
      js.Expression fragmentCode = fragmentEmitter.emitDeferredFragment(
          finalizedFragment, program.holders);
      if (fragmentCode != null) {
        deferredFragmentsCode[finalizedFragment] = fragmentCode;
      } else {
        omittedOutputUnits.add(finalizedFragment.outputUnit);
      }
    }

    js.TokenCounter counter = new js.TokenCounter();
    deferredFragmentsCode.values.forEach(counter.countTokens);
    counter.countTokens(mainCode);

    program.finalizers.forEach((js.TokenFinalizer f) => f.finalizeTokens());

    // TODO(sra): This is where we know if the types (and potentially other
    // deferred ASTs inside the parts) have any contents. We should wait until
    // this point to decide if a part is empty.

    Map<FinalizedFragment, String> hunkHashes =
        _task.measureSubtask('write fragments', () {
      return writeDeferredFragments(deferredFragmentsCode);
    });

    // Now that we have written the deferred hunks, we can create the deferred
    // loading data.
    Map<String, List<FinalizedFragment>> loadMap =
        FragmentMerger.processLoadMap(program.loadMap, fragmentMap);
    fragmentEmitter.finalizeDeferredLoadingData(
        loadMap, hunkHashes, deferredLoadingState);

    _task.measureSubtask('write fragments', () {
      writeMainFragment(mainFragment, mainCode,
          isSplit: program.deferredFragments.isNotEmpty ||
              program.hasSoftDeferredClasses ||
              _options.experimentalTrackAllocations);
    });

    if (_closedWorld.backendUsage.requiresPreamble &&
        !_closedWorld.backendUsage.isHtmlLoaded) {
      _reporter.reportHintMessage(NO_LOCATION_SPANNABLE, MessageKind.PREAMBLE);
    }

    if (_options.deferredMapUri != null) {
      writeDeferredMap();
    }

    // Return the total program size.
    return emittedOutputBuffers.values.fold(0, (a, b) => a + b.length);
  }

  /// Generates a simple header that provides the compiler's build id.
  js.Comment buildGeneratedBy() {
    StringBuffer flavor = new StringBuffer();
    flavor.write('fast startup emitter');
    // TODO(johnniwinther): Remove this flavor.
    flavor.write(', strong');
    if (_options.trustPrimitives) flavor.write(', trust primitives');
    if (_options.omitImplicitChecks) flavor.write(', omit checks');
    if (_options.laxRuntimeTypeToString) {
      flavor.write(', lax runtime type');
    }
    if (_options.useContentSecurityPolicy) flavor.write(', CSP');
    return new js.Comment(generatedBy(_options, flavor: '$flavor'));
  }

  /// Writes all deferred fragment's code into files.
  ///
  /// Returns a map from fragment to its hashcode (as used for the deferred
  /// library code).
  ///
  /// Updates the shared [outputBuffers] field with the output.
  Map<FinalizedFragment, String> writeDeferredFragments(
      Map<FinalizedFragment, js.Expression> fragmentsCode) {
    Map<FinalizedFragment, String> hunkHashes = {};

    fragmentsCode.forEach((FinalizedFragment fragment, js.Expression code) {
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
    if (_shouldGenerateSourceMap) {
      _task.measureSubtask('source-maps', () {
        locationCollector = LocationCollector();
        codeOutputListeners = <CodeOutputListener>[locationCollector];
      });
    }

    CodeOutput mainOutput = StreamCodeOutput(
        _outputProvider.createOutputSink('', 'js', OutputType.js),
        codeOutputListeners);
    emittedOutputBuffers[fragment.outputUnit] = mainOutput;

    js.Program program = js.Program([
      buildGeneratedBy(),
      js.Comment(HOOKS_API_USAGE),
      if (isSplit) buildDeferredInitializerGlobal(),
      code
    ]);

    CodeBuffer buffer = js.createCodeBuffer(
        program, _options, _sourceInformationStrategy,
        monitor: _dumpInfoTask);
    _task.measureSubtask('emit buffers', () {
      mainOutput.addBuffer(buffer);
    });

    if (_shouldGenerateSourceMap) {
      _task.measureSubtask('source-maps', () {
        mainOutput.add(SourceMapBuilder.generateSourceMapTag(
            _options.sourceMapUri, _options.outputUri));
      });
    }

    mainOutput.close();

    if (_shouldGenerateSourceMap) {
      _task.measureSubtask('source-maps', () {
        SourceMapBuilder.outputSourceMap(
            mainOutput,
            locationCollector,
            _namer.createMinifiedGlobalNameMap(),
            _namer.createMinifiedInstanceNameMap(),
            '',
            _options.sourceMapUri,
            _options.outputUri,
            _outputProvider);
      });
    }
  }

  // Writes the given [fragment]'s [code] into a file.
  //
  // Returns the deferred fragment's hash.
  //
  // Updates the shared [outputBuffers] field with the output.
  String writeDeferredFragment(FinalizedFragment fragment, js.Expression code) {
    List<CodeOutputListener> outputListeners = [];
    Hasher hasher = new Hasher();
    outputListeners.add(hasher);

    LocationCollector locationCollector;
    if (_shouldGenerateSourceMap) {
      _task.measureSubtask('source-maps', () {
        locationCollector = new LocationCollector();
        outputListeners.add(locationCollector);
      });
    }

    String hunkPrefix = fragment.outputFileName;

    CodeOutput output = new StreamCodeOutput(
        _outputProvider.createOutputSink(
            hunkPrefix, deferredExtension, OutputType.jsPart),
        outputListeners);

    emittedOutputBuffers[fragment.outputUnit] = output;

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

    CodeBuffer buffer = js.createCodeBuffer(
        program, _options, _sourceInformationStrategy,
        monitor: _dumpInfoTask);
    _task.measureSubtask('emit buffers', () {
      output.addBuffer(buffer);
    });

    // Make a unique hash of the code (before the sourcemaps are added)
    // This will be used to retrieve the initializing function from the global
    // variable.
    String hash = hasher.getHash();

    // Now we copy the deferredInitializer.current into its correct hash.
    output.add('\n${deferredInitializersGlobal}["$hash"] = '
        '${deferredInitializersGlobal}.current');

    if (_shouldGenerateSourceMap) {
      _task.measureSubtask('source-maps', () {
        Uri mapUri, partUri;
        Uri sourceMapUri = _options.sourceMapUri;
        Uri outputUri = _options.outputUri;
        String partName = "$hunkPrefix.$partExtension";
        String hunkFileName = "$hunkPrefix.$deferredExtension";

        if (sourceMapUri != null) {
          String mapFileName = hunkFileName + ".map";
          List<String> mapSegments = sourceMapUri.pathSegments.toList();
          mapSegments[mapSegments.length - 1] = mapFileName;
          mapUri = _options.sourceMapUri.replace(pathSegments: mapSegments);
        }

        if (outputUri != null) {
          List<String> partSegments = outputUri.pathSegments.toList();
          partSegments[partSegments.length - 1] = hunkFileName;
          partUri = _options.outputUri.replace(pathSegments: partSegments);
        }

        output.add(SourceMapBuilder.generateSourceMapTag(mapUri, partUri));
        output.close();
        SourceMapBuilder.outputSourceMap(output, locationCollector, {}, {},
            partName, mapUri, partUri, _outputProvider);
      });
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
    Map<String, dynamic> mapping = {};
    // Json does not support comments, so we embed the explanation in the
    // data.
    mapping["_comment"] = "This mapping shows which compiled `.js` files are "
        "needed for a given deferred library import.";
    mapping.addAll(_closedWorld.outputUnitData.computeDeferredMap(
        _options, _closedWorld.elementEnvironment,
        omittedUnits: omittedOutputUnits));
    _outputProvider.createOutputSink(
        _options.deferredMapUri.path, '', OutputType.deferredMap)
      ..add(const JsonEncoder.withIndent("  ").convert(mapping))
      ..close();
  }
}
