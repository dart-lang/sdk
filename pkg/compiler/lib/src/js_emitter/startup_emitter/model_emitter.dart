// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.startup_emitter.model_emitter;

import 'dart:convert' show JsonEncoder;

import 'package:js_runtime/synced/embedded_names.dart'
    show
        DEFERRED_INITIALIZED,
        DEFERRED_LIBRARY_PARTS,
        DEFERRED_PART_URIS,
        DEFERRED_PART_HASHES,
        INITIALIZATION_EVENT_LOG,
        INITIALIZE_LOADED_HUNK,
        INTERCEPTORS_BY_TAG,
        IS_HUNK_INITIALIZED,
        IS_HUNK_LOADED,
        LEAF_TAGS,
        MANGLED_GLOBAL_NAMES,
        MANGLED_NAMES,
        METADATA,
        NATIVE_SUPERCLASS_TAG_NAME,
        RECORD_TYPE_TEST_COMBINATORS_PROPERTY,
        RUNTIME_METRICS,
        STARTUP_METRICS,
        TearOffParametersPropertyNames,
        TYPE_TO_INTERCEPTOR_MAP;

import 'package:js_shared/synced/embedded_names.dart'
    show
        ARRAY_RTI_PROPERTY,
        JsGetName,
        RTI_UNIVERSE,
        RtiUniverseFieldNames,
        TYPES;

import 'package:js_ast/src/precedence.dart' as js_precedence;

import '../../../compiler_api.dart' as api;
import '../../common.dart';
import '../../common/elements.dart' show CommonElements, JElementEnvironment;
import '../../common/tasks.dart';
import '../../constants/values.dart';
import '../../deferred_load/output_unit.dart' show OutputUnit;
import '../../dump_info.dart';
import '../../elements/entities.dart';
import '../../elements/types.dart';
import '../../hash/sha1.dart' show Hasher;
import '../../io/code_output.dart';
import '../../io/location_provider.dart' show LocationCollector;
import '../../io/source_information.dart';
import '../../io/source_map_builder.dart' show SourceMapBuilder;
import '../../js/js.dart' as js;
import '../../js/js_source_mapping.dart';
import '../../js/size_estimator.dart';
import '../../js_backend/js_backend.dart'
    show Namer, ConstantEmitter, StringBackedName;
import '../../js_backend/js_interop_analysis.dart' as jsInteropAnalysis;
import '../../js_backend/runtime_types.dart';
import '../../js_backend/runtime_types_codegen.dart';
import '../../js_backend/runtime_types_new.dart' show RecipeEncoder;
import '../../js_backend/runtime_types_new.dart'
    show RecipeEncoderImpl, Ruleset, RulesetEncoder;
import '../../js_backend/runtime_types_resolution.dart' show RuntimeTypesNeed;
import '../../js_backend/deferred_holder_expression.dart'
    show
        DeferredHolderExpressionFinalizer,
        DeferredHolderExpressionFinalizerImpl,
        DeferredHolderParameter,
        DeferredHolderResource,
        DeferredHolderResourceKind,
        mainResourceName;
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
import '../../js_model/js_world.dart';
import '../../options.dart';
import '../../universe/class_hierarchy.dart' show ClassHierarchy;
import '../../universe/codegen_world_builder.dart' show CodegenWorld;
import '../js_emitter.dart';
import '../constant_ordering.dart' show ConstantOrdering;
import '../headers.dart';
import '../model.dart';
import '../resource_info_emitter.dart' show ResourceInfoCollector;
import 'fragment_merger.dart';

part 'fragment_emitter.dart';

class EmittedCodeFragment {
  final CodeFragment codeFragment;
  final js.Expression code;

  EmittedCodeFragment(this.codeFragment, this.code);
}

class ModelEmitter {
  final CompilerOptions _options;
  final DiagnosticReporter _reporter;
  final api.CompilerOutput _outputProvider;
  final DumpInfoTask _dumpInfoTask;
  final ResourceInfoCollector _resourceInfoCollector = ResourceInfoCollector();
  final Namer _namer;
  final CompilerTask _task;
  final Emitter _emitter;
  late final ConstantEmitter constantEmitter;
  final NativeEmitter _nativeEmitter;
  final bool _shouldGenerateSourceMap;
  final JClosedWorld _closedWorld;
  final ConstantOrdering _constantOrdering;
  final SourceInformationStrategy _sourceInformationStrategy;
  final FragmentMerger fragmentMerger;

  // The full code that is written to each hunk part-file.
  final Map<OutputUnit, CodeOutput> emittedOutputBuffers = {};

  final Set<OutputUnit> omittedOutputUnits = {};

  List<PreFragment>? preDeferredFragmentsForTesting;

  /// A mapping from the name of a defer import to all the fragments it
  /// depends on in a list of lists to be loaded in the order they appear.
  ///
  /// For example {"lib1": [[lib1_lib2_lib3], [lib1_lib2, lib1_lib3],
  /// [lib1]]} would mean that in order to load "lib1" first the hunk
  /// lib1_lib2_lib2 should be loaded, then the hunks lib1_lib2 and lib1_lib3
  /// can be loaded in parallel. And finally lib1 can be loaded.
  final Map<String, List<FinalizedFragment>> finalizedFragmentsToLoad = {};

  /// Similar to the above map, but more granular as each [FinalizedFragment]
  /// may have multiple CodeFragments.
  final Map<String, List<CodeFragment>> codeFragmentsToLoad = {};

  /// For deferred loading we communicate the initializers via this global var.
  static const String deferredInitializersGlobal =
      r"$__dart_deferred_initializers__";

  static const String startupMetricsGlobal = r'$__dart_startupMetrics';

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
      : _constantOrdering = ConstantOrdering(_closedWorld.sorter),
        fragmentMerger = FragmentMerger(_options,
            _closedWorld.elementEnvironment, _closedWorld.outputUnitData) {
    constantEmitter = ConstantEmitter(
        _options,
        _namer,
        _closedWorld.commonElements,
        _closedWorld.elementEnvironment,
        _closedWorld.rtiNeed,
        rtiRecipeEncoder,
        _closedWorld.fieldAnalysis,
        _closedWorld.recordData,
        _emitter,
        this.generateConstantReference,
        constantListGenerator);
  }

  js.Expression constantListGenerator(js.Expression array) {
    // TODO(floitsch): remove hard-coded name.
    return js.js('makeConstList(#)', [array]);
  }

  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    if (constant is FunctionConstantValue) return true; // Already emitted.
    if (constant is PrimitiveConstantValue) return true; // Inlined.
    if (constant.isDummy) return true; // Inlined.
    if (constant is LateSentinelConstantValue) return true; // Inlined.
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
    bool aIsInterceptor = a is InterceptorConstantValue;
    bool bIsInterceptor = b is InterceptorConstantValue;
    if (aIsInterceptor != bIsInterceptor) {
      return aIsInterceptor ? -1 : 1;
    }

    // Sorting by the long name clusters constants with the same constructor
    // which compresses a tiny bit better.
    int r = _namer.constantLongName(a).compareTo(_namer.constantLongName(b));
    if (r != 0) return r;

    // Resolve collisions in the long name by using a structural order.
    return _constantOrdering.compare(a, b);
  }

  js.Expression generateConstantReference(ConstantValue value) {
    if (value is FunctionConstantValue) {
      return _emitter.staticClosureAccess(value.element);
    }

    // We are only interested in the "isInlined" part, but it does not hurt to
    // test for the other predicates.
    if (isConstantInlinedOrAlreadyEmitted(value)) {
      return constantEmitter.generate(value)!;
    }
    return js.js('#.#',
        [_namer.globalObjectForConstant(value), _namer.constantName(value)]);
  }

  bool get shouldMergeFragments => _options.mergeFragmentsThreshold != null;

  int emitProgram(Program program, CodegenWorld codegenWorld) {
    final mainFragment = program.fragments.first as MainFragment;
    List<DeferredFragment> deferredFragments =
        List<DeferredFragment>.from(program.deferredFragments);

    FragmentEmitter fragmentEmitter = FragmentEmitter(
        _options,
        _dumpInfoTask,
        _namer,
        _emitter,
        constantEmitter,
        this,
        _nativeEmitter,
        _closedWorld,
        codegenWorld);

    // In order to get size estimates, we partially emit deferred fragments.
    List<OutputUnit> outputUnits = [];
    List<PreFragment> preDeferredFragments = [];
    _task.measureSubtask('emit prefragments', () {
      for (var fragment in deferredFragments) {
        var preFragment =
            fragmentEmitter.emitPreFragment(fragment, shouldMergeFragments);
        outputUnits.add(fragment.outputUnit);
        preDeferredFragments.add(preFragment);
      }
    });

    // Sort output units so they are in a canonical order and generate a map of
    // loadId to list of OutputUnits to load.
    outputUnits.sort();
    var outputUnitsToLoad =
        fragmentMerger.computeOutputUnitsToLoad(outputUnits);

    // If we are going to merge, then we attach dependencies to each PreFragment
    // and merge.
    if (shouldMergeFragments) {
      preDeferredFragments = _task.measureSubtask('merge fragments', () {
        fragmentMerger.attachDependencies(outputUnits, preDeferredFragments);
        return fragmentMerger.mergeFragments(preDeferredFragments);
      });
    }

    // If necessary, we retain the merged PreFragments for testing.
    if (retainDataForTesting) {
      preDeferredFragmentsForTesting = preDeferredFragments;
    }

    // Finalize and emit fragments.
    Map<OutputUnit, CodeFragment> outputUnitMap = {};
    Map<CodeFragment, FinalizedFragment> codeFragmentMap = {};
    Map<FinalizedFragment, List<EmittedCodeFragment>> deferredFragmentsCode =
        {};
    for (var preDeferredFragment in preDeferredFragments) {
      var finalizedFragment =
          preDeferredFragment.finalize(program, outputUnitMap, codeFragmentMap);
      for (var codeFragment in finalizedFragment.codeFragments) {
        final fragmentCode = fragmentEmitter.emitCodeFragment(codeFragment);
        if (fragmentCode != null) {
          (deferredFragmentsCode[finalizedFragment] ??= [])
              .add(EmittedCodeFragment(codeFragment, fragmentCode));
        } else {
          omittedOutputUnits.addAll(codeFragment.outputUnits);
        }
      }
    }

    // With all deferred fragments finalized, we can now compute a map of
    // loadId to the files(FinalizedFragments) which need to be loaded.
    fragmentMerger.computeFragmentsToLoad(
        outputUnitsToLoad,
        outputUnitMap,
        codeFragmentMap,
        omittedOutputUnits,
        codeFragmentsToLoad,
        finalizedFragmentsToLoad);

    // Emit main Fragment.
    var deferredLoadingState = DeferredLoadingState();
    js.Statement mainCode = fragmentEmitter.emitMainFragment(
        program, finalizedFragmentsToLoad, deferredLoadingState);

    // Count tokens and run finalizers.
    js.TokenCounter counter = js.TokenCounter();
    for (var emittedFragments in deferredFragmentsCode.values) {
      for (var emittedFragment in emittedFragments) {
        counter.countTokens(emittedFragment.code);
      }
    }
    counter.countTokens(mainCode);

    program.finalizers.forEach((js.TokenFinalizer f) => f.finalizeTokens());

    // TODO(sra): This is where we know if the types (and potentially other
    // deferred ASTs inside the parts) have any contents. We should wait until
    // this point to decide if a part is empty.

    Map<CodeFragment, String> codeFragmentHashes =
        _task.measureSubtask('write fragments', () {
      return writeFinalizedFragments(deferredFragmentsCode);
    });

    // Now that we have written the deferred hunks, we can create the deferred
    // loading data.
    fragmentEmitter.finalizeDeferredLoadingData(codeFragmentsToLoad,
        codeFragmentMap, codeFragmentHashes, deferredLoadingState);

    _task.measureSubtask('write fragments', () {
      writeMainFragment(mainFragment, mainCode,
          isSplit: program.isSplit || _options.experimentalTrackAllocations);
    });

    if (_closedWorld.backendUsage.requiresPreamble &&
        !_closedWorld.backendUsage.isHtmlLoaded) {
      _reporter.reportHintMessage(NO_LOCATION_SPANNABLE, MessageKind.PREAMBLE);
    }

    if (_options.deferredMapUri != null) {
      writeDeferredMap();
    }

    if (_options.writeResources) {
      writeResourceIdentifiers();
    }

    // Return the total program size.
    return emittedOutputBuffers.values.fold(0, (a, b) => a + b.length);
  }

  /// Generates a simple header that provides the compiler's build id.
  js.Comment buildGeneratedBy() {
    final flavor = StringBuffer();
    flavor.write(_options.nullSafetyMode);
    if (_options.trustPrimitives) flavor.write(', trust primitives');
    if (_options.omitImplicitChecks) flavor.write(', omit checks');
    if (_options.laxRuntimeTypeToString) {
      flavor.write(', lax runtime type');
    }
    var featureString = _options.features.flavorString();
    if (featureString.isNotEmpty) flavor.write(', $featureString');
    return js.Comment(generatedBy(_options, flavor: '$flavor'));
  }

  js.Statement buildDeferredInitializerGlobal(js.LiteralString partFileName,
      {js.Expression? code}) {
    return js.js.statement(
        '((s,d) => {s[d] = s[d] || {#eventLog: []}; '
        's[d].#eventLog.push({part:#part,event:"beginLoadPart"});})'
        '(self,#deferredInitializers)',
        {
          'deferredInitializers': js.string(deferredInitializersGlobal),
          'eventLog': js.string(INITIALIZATION_EVENT_LOG),
          'part': partFileName,
        });
  }

  js.Statement buildStartupMetrics() {
    // We want the code that initializes the startup metrics to execute as early
    // as possible, so it is placed ahead of the main program IIFE instead of,
    // e.g. as a parameter of the IIFE. It is OK to use a top-level variable,
    // since the IIFE immediately reads the variable.
    return js.js.statement('''
var ${startupMetricsGlobal} =
(function(){
  // The timestamp metrics use `performance.now()`. We feature-detect and
  // fall back on `Date.now()` for JavaScript run in a non-browser environment.
  var _performance =
      (typeof performance == "object" &&
       performance != null &&
       typeof performance.now == "function")
          ? performance
          : Date;
  var metrics = {
    a: [],
    now: function() { return _performance.now() },
    add: function(name) { this.a.push(name, this.now()); }
  };
  metrics.add('firstMs');
  return metrics;
})();''');
  }

  // Writes the given [fragment]'s [code] into a file.
  //
  // Updates the shared [outputBuffers] field with the output.
  void writeMainFragment(MainFragment fragment, js.Statement code,
      {required bool isSplit}) {
    LocationCollector? locationCollector;
    List<CodeOutputListener>? codeOutputListeners;
    if (_shouldGenerateSourceMap) {
      _task.measureSubtask('source-maps', () {
        final collector = locationCollector = LocationCollector();
        codeOutputListeners = [collector];
      });
    }

    CodeOutput mainOutput = StreamCodeOutput(
        _outputProvider.createOutputSink('', 'js', api.OutputType.js),
        codeOutputListeners);
    emittedOutputBuffers[fragment.outputUnit] = mainOutput;

    js.Program program = js.Program([
      buildGeneratedBy(),
      js.Comment(HOOKS_API_USAGE),
      if (isSplit) buildDeferredInitializerGlobal(js.string('main')),
      if (_closedWorld.backendUsage.requiresStartupMetrics)
        buildStartupMetrics(),
      code
    ]);

    CodeBuffer buffer = js.createCodeBuffer(program, _options,
        _sourceInformationStrategy as JavaScriptSourceInformationStrategy,
        monitor: _dumpInfoTask,
        annotationMonitor: _resourceInfoCollector
            .monitorFor(_options.outputUri?.pathSegments.last ?? 'out'));
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
            locationCollector!,
            _namer.createMinifiedGlobalNameMap(),
            _namer.createMinifiedInstanceNameMap(),
            '',
            _options.sourceMapUri,
            _options.outputUri,
            _outputProvider);
      });
    }
  }

  /// Writes all [FinalizedFragments] to files, returning a map of
  /// [CodeFragment] to their initialization hashes.
  Map<CodeFragment, String> writeFinalizedFragments(
      Map<FinalizedFragment, List<EmittedCodeFragment>> fragmentsCode) {
    Map<CodeFragment, String> fragmentHashes = {};
    fragmentsCode.forEach((fragment, code) {
      writeFinalizedFragment(fragment, code, fragmentHashes);
    });
    return fragmentHashes;
  }

  /// Writes a single [FinalizedFragment] and all of its [CodeFragments] to
  /// file, updating the [fragmentHashes] map as necessary.
  void writeFinalizedFragment(
      FinalizedFragment fragment,
      List<EmittedCodeFragment> fragmentCode,
      Map<CodeFragment, String> fragmentHashes) {
    List<CodeOutputListener> outputListeners = [];
    LocationCollector? locationCollector;
    if (_shouldGenerateSourceMap) {
      _task.measureSubtask('source-maps', () {
        final collector = locationCollector = LocationCollector();
        outputListeners.add(collector);
      });
    }

    String outputFileName = fragment.outputFileName;
    CodeOutput output = StreamCodeOutput(
        _outputProvider.createOutputSink(
            outputFileName, deferredExtension, api.OutputType.jsPart),
        outputListeners);

    writeCodeFragments(fragmentCode, fragmentHashes, output, outputFileName);

    if (_shouldGenerateSourceMap) {
      _task.measureSubtask('source-maps', () {
        Uri? mapUri, partUri;
        final sourceMapUri = _options.sourceMapUri;
        final outputUri = _options.outputUri;
        String partName = "$outputFileName.$partExtension";
        String hunkFileName = "$outputFileName.$deferredExtension";

        if (sourceMapUri != null) {
          String mapFileName = hunkFileName + ".map";
          List<String> mapSegments = sourceMapUri.pathSegments.toList();
          mapSegments[mapSegments.length - 1] = mapFileName;
          mapUri = _options.sourceMapUri!.replace(pathSegments: mapSegments);
        }

        if (outputUri != null) {
          List<String> partSegments = outputUri.pathSegments.toList();
          partSegments[partSegments.length - 1] = hunkFileName;
          partUri = _options.outputUri!.replace(pathSegments: partSegments);
        }

        output.add(SourceMapBuilder.generateSourceMapTag(mapUri, partUri));
        output.close();
        SourceMapBuilder.outputSourceMap(output, locationCollector!, {}, {},
            partName, mapUri, partUri, _outputProvider);
      });
    } else {
      output.close();
    }
  }

  /// Writes a list of [CodeFragments] to [CodeOutput].
  void writeCodeFragments(
      List<EmittedCodeFragment> fragmentCode,
      Map<CodeFragment, String> fragmentHashes,
      CodeOutput output,
      String outputFileName) {
    bool isFirst = true;
    for (var emittedCodeFragment in fragmentCode) {
      var codeFragment = emittedCodeFragment.codeFragment;
      var code = emittedCodeFragment.code;
      for (var outputUnit in codeFragment.outputUnits) {
        emittedOutputBuffers[outputUnit] = output;
      }
      fragmentHashes[codeFragment] =
          writeCodeFragment(output, code, isFirst, outputFileName);
      isFirst = false;
    }
  }

  // Writes the given [fragment]'s [code] into a file.
  //
  // Returns the deferred fragment's hash.
  //
  // Updates the shared [outputBuffers] field with the output.
  String writeCodeFragment(CodeOutput output, js.Expression code, bool isFirst,
      String outputFileName) {
    // The [code] contains the function that must be invoked when the deferred
    // hunk is loaded.
    // That function must be in a map from its hashcode to the function. Since
    // we don't know the hash before we actually emit the code we store the
    // function in a temporary field first:
    //
    //   deferredInitializer.current = <pretty-printed code>;
    //   deferredInitializer[<hash>] = deferredInitializer.current;

    final outputFileJsString = js.string(outputFileName);
    js.Program program = js.Program([
      if (isFirst) buildGeneratedBy(),
      if (isFirst) buildDeferredInitializerGlobal(outputFileJsString),
      js.js.statement('#deferredInitializers.current = #code',
          {'deferredInitializers': deferredInitializersGlobal, 'code': code})
    ]);

    Hasher hasher = Hasher();
    CodeBuffer buffer = js.createCodeBuffer(program, _options,
        _sourceInformationStrategy as JavaScriptSourceInformationStrategy,
        monitor: _dumpInfoTask,
        listeners: [hasher],
        annotationMonitor: _resourceInfoCollector.monitorFor(outputFileName));
    _task.measureSubtask('emit buffers', () {
      output.addBuffer(buffer);
      // Add semi-colon to separate from IIFE epilogue.
      output.add(';');
    });

    // Make a unique hash of the code (before the sourcemaps are added)
    // This will be used to retrieve the initializing function from the global
    // variable.
    String hash = hasher.getHash();

    // Now we copy the deferredInitializer.current into its correct hash.
    final epilogue = js.js.statement(
        '((d,h)=>{d[h]=d.current; '
        'd.#eventLog.push({hash:h,event:"endPartLoad",part:#part})})'
        '(#deferredInitializers,#hash)',
        {
          'deferredInitializers': deferredInitializersGlobal,
          'hash': js.string(hash),
          'eventLog': js.string(INITIALIZATION_EVENT_LOG),
          'part': outputFileJsString,
        });
    output.add('\n');
    output.add(js
        .createCodeBuffer(epilogue, _options,
            _sourceInformationStrategy as JavaScriptSourceInformationStrategy)
        .getText());
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
    mapping.addAll(fragmentMerger.computeDeferredMap(finalizedFragmentsToLoad));
    _outputProvider.createOutputSink(
        _options.deferredMapUri!.path, '', api.OutputType.deferredMap)
      ..add(const JsonEncoder.withIndent("  ").convert(mapping))
      ..close();
  }

  /// Writes out all the referenced resource identifiers as a JSON file.
  void writeResourceIdentifiers() {
    _outputProvider.createOutputSink(
        '', 'resources.json', api.OutputType.resourceIdentifiers)
      ..add(JsonEncoder.withIndent('  ')
          .convert(_resourceInfoCollector.finish(_options.environment)))
      ..close();
  }
}
