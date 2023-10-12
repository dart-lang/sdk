// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports, constant_identifier_names

// front_end/src imports below that require lint `ignore_for_file` are a
// temporary state of things until frontend team builds better api that would
// replace api used below. This api was made private in an effort to discourage
// further use.

library frontend_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, IOSink, stdout;
import 'dart:typed_data' show BytesBuilder;

import 'package:args/args.dart';
import 'package:dev_compiler/dev_compiler.dart'
    show
        DevCompilerTarget,
        ExpressionCompiler,
        parseModuleFormat,
        ProgramCompiler;
import 'package:front_end/src/api_unstable/ddc.dart' as ddc
    show IncrementalCompiler;
import 'package:front_end/src/api_unstable/vm.dart';
import 'package:front_end/widget_cache.dart';
import 'package:kernel/ast.dart' show Library, Procedure, LibraryDependency;
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart'
    show Component, loadComponentSourceFromBytes;
import 'package:kernel/target/targets.dart' show targets, TargetFlags;
import 'package:package_config/package_config.dart';
import 'package:usage/uuid/uuid.dart';
import 'package:vm/incremental_compiler.dart' show IncrementalCompiler;
import 'package:vm/kernel_front_end.dart';
import 'package:vm/target_os.dart'; // For possible --target-os values.

import 'src/javascript_bundle.dart';

ArgParser argParser = ArgParser(allowTrailingOptions: true)
  ..addFlag('train',
      help: 'Run through sample command line to produce snapshot',
      negatable: false)
  ..addFlag('incremental',
      help: 'Run compiler in incremental mode', defaultsTo: false)
  ..addOption('sdk-root',
      help: 'Path to sdk root',
      defaultsTo: '../../out/android_debug/flutter_patched_sdk')
  ..addOption('platform', help: 'Platform kernel filename')
  ..addFlag('aot',
      help: 'Run compiler in AOT mode (enables whole-program transformations)',
      defaultsTo: false)
  ..addOption('target-os',
      help: 'Compile to a specific target operating system.',
      allowed: TargetOS.names)
  ..addFlag('support-mirrors',
      help: 'Whether dart:mirrors is supported. By default dart:mirrors is '
          'supported when --aot and --minimal-kernel are not used.',
      defaultsTo: null)
  ..addFlag('compact-async', help: 'Obsolete, ignored.', hide: true)
  ..addFlag('tfa',
      help:
          'Enable global type flow analysis and related transformations in AOT mode.',
      defaultsTo: false)
  ..addFlag('rta',
      help: 'Use rapid type analysis for faster compilation in AOT mode.',
      defaultsTo: true)
  ..addFlag('tree-shake-write-only-fields',
      help: 'Enable tree shaking of fields which are only written in AOT mode.',
      defaultsTo: true)
  ..addFlag('protobuf-tree-shaker-v2',
      help: 'Enable protobuf tree shaker v2 in AOT mode.', defaultsTo: false)
  ..addFlag('minimal-kernel',
      help: 'Produce minimal tree-shaken kernel file.', defaultsTo: false)
  ..addFlag('link-platform',
      help:
          'When in batch mode, link platform kernel file into result kernel file.'
          ' Intended use is to satisfy different loading strategies implemented'
          ' by gen_snapshot(which needs platform embedded) vs'
          ' Flutter engine(which does not)',
      defaultsTo: true)
  ..addOption('import-dill',
      help: 'Import libraries from existing dill file', defaultsTo: null)
  ..addOption('from-dill',
      help: 'Read existing dill file instead of compiling from sources',
      defaultsTo: null)
  ..addOption('output-dill',
      help: 'Output path for the generated dill', defaultsTo: null)
  ..addOption('output-incremental-dill',
      help: 'Output path for the generated incremental dill', defaultsTo: null)
  ..addOption('depfile',
      help: 'Path to output Ninja depfile. Only used in batch mode.')
  ..addOption('packages',
      help: '.dart_tool/package_config.json file to use for compilation',
      defaultsTo: null)
  ..addMultiOption('source',
      help: 'List additional source files to include into compilation.',
      defaultsTo: const <String>[])
  ..addOption('native-assets',
      help: 'Provide the native-assets mapping for @Native external functions.')
  ..addOption('target',
      help: 'Target model that determines what core libraries are available',
      allowed: <String>[
        'vm',
        'flutter',
        'flutter_runner',
        'dart_runner',
        'dartdevc'
      ],
      defaultsTo: 'vm')
  ..addMultiOption('filesystem-root',
      help: 'File path that is used as a root in virtual filesystem used in'
          ' compiled kernel files. When used --output-dill should be provided'
          ' as well.',
      hide: true)
  ..addOption('filesystem-scheme',
      help:
          'Scheme that is used in virtual filesystem set up via --filesystem-root'
          ' option',
      defaultsTo: 'org-dartlang-root',
      hide: true)
  ..addOption('binary-protocol-address',
      hide: true,
      help: 'The server will establish TCP connection to this address, and'
          ' will exchange binary requests and responses with the client.')
  ..addFlag('enable-http-uris',
      defaultsTo: false, hide: true, help: 'Enables support for http uris.')
  ..addFlag('verbose', help: 'Enables verbose output from the compiler.')
  ..addOption('initialize-from-dill',
      help: 'Normally the output dill is used to specify which dill to '
          'initialize from, but it can be overwritten here.',
      defaultsTo: null,
      hide: true)
  ..addFlag('assume-initialize-from-dill-up-to-date',
      help: 'Normally the dill used for initializing is checked against the '
          "files it was compiled against. If we somehow know that it's "
          'up-to-date we can skip it safely. Under normal circumstances this '
          "isn't safe though.",
      defaultsTo: false,
      hide: true)
  ..addMultiOption('define',
      abbr: 'D',
      help: 'The values for the environment constants (e.g. -Dkey=value).',
      splitCommas: false)
  ..addFlag('embed-source-text',
      help: 'Includes sources into generated dill file. Having sources'
          ' allows to effectively use observatory to debug produced'
          ' application, produces better stack traces on exceptions.',
      defaultsTo: true)
  ..addFlag('unsafe-package-serialization',
      help: '*Deprecated* '
          'Potentially unsafe: Does not allow for invalidating packages, '
          'additionally the output dill file might include more libraries than '
          'needed. The use case is test-runs, where invalidation is not really '
          'used, and where dill filesize does not matter, and the gain is '
          'improved speed.',
      defaultsTo: false,
      hide: true)
  ..addFlag('incremental-serialization',
      help: 'Re-use previously serialized data when serializing. '
          'The output dill file might include more libraries than strictly '
          'needed, but the serialization phase will generally be much faster.',
      defaultsTo: true,
      negatable: true,
      hide: true)
  ..addFlag('track-widget-creation',
      help: 'Run a kernel transformer to track creation locations for widgets.',
      defaultsTo: false)
  ..addMultiOption(
    'delete-tostring-package-uri',
    help: 'Replaces implementations of `toString` with `super.toString()` for '
        'specified package',
    valueHelp: 'dart:ui',
    defaultsTo: const <String>[],
  )
  ..addMultiOption(
    'keep-class-names-implementing',
    help: 'Prevents obfuscation of the class names of any class implementing '
        'the given class.',
    defaultsTo: const <String>[],
  )
  ..addFlag('enable-asserts',
      help: 'Whether asserts will be enabled.', defaultsTo: false)
  ..addFlag('sound-null-safety',
      help: 'Respect the nullability of types at runtime.', defaultsTo: true)
  ..addMultiOption('enable-experiment',
      help: 'Comma separated list of experimental features, eg set-literals.',
      hide: true)
  ..addFlag('split-output-by-packages',
      help:
          'Split resulting kernel file into multiple files (one per package).',
      defaultsTo: false)
  ..addOption('component-name', help: 'Name of the Fuchsia component')
  ..addOption('data-dir',
      help: 'Name of the subdirectory of //data for output files')
  ..addOption('far-manifest', help: 'Path to output Fuchsia package manifest')
  ..addOption('libraries-spec',
      help: 'A path or uri to the libraries specification JSON file')
  ..addFlag('debugger-module-names',
      help: 'Use debugger-friendly modules names', defaultsTo: false)
  ..addFlag('experimental-emit-debug-metadata',
      help: 'Emit module and library metadata for the debugger',
      defaultsTo: false)
  ..addFlag('emit-debug-symbols',
      help: 'Emit debug symbols for the debugger', defaultsTo: false)
  ..addOption('dartdevc-module-format',
      help: 'The module format to use on for the dartdevc compiler',
      defaultsTo: 'amd')
  ..addFlag('dartdevc-canary',
      help: 'Enable canary features in dartdevc compiler', defaultsTo: false)
  ..addFlag('flutter-widget-cache',
      help: 'Enable the widget cache to track changes to Widget subtypes',
      defaultsTo: false)
  ..addFlag('print-incremental-dependencies',
      help: 'Print list of sources added and removed from compilation',
      defaultsTo: true)
  ..addOption('resident-info-file-name',
      help:
          'Allowing for incremental compilation of changes when using the Dart CLI.'
          ' Stores server information in this file for accessing later',
      hide: true)
  ..addOption('verbosity',
      help: 'Sets the verbosity level of the compilation',
      defaultsTo: Verbosity.defaultValue,
      allowed: Verbosity.allowedValues,
      allowedHelp: Verbosity.allowedValuesHelp);

String usage = '''
Usage: server [options] [input.dart]

If filename or uri pointing to the entrypoint is provided on the command line,
then the server compiles it, generates dill file and exits.
If no entrypoint is provided on the command line, server waits for
instructions from stdin.

Instructions:
- compile <input.dart>
- recompile [<input.dart>] <boundary-key>
<invalidated file uri>
<invalidated file uri>
...
<boundary-key>
- accept
- quit

Output:
- result <boundary-key>
<compiler output>
<boundary-key> [<output.dill>]

Options:
${argParser.usage}
''';

enum _State {
  READY_FOR_INSTRUCTION,
  RECOMPILE_LIST,
  // compileExpression
  COMPILE_EXPRESSION_EXPRESSION,
  COMPILE_EXPRESSION_DEFS,
  COMPILE_EXPRESSION_DEFTYPES,
  COMPILE_EXPRESSION_TYPEDEFS,
  COMPILE_EXPRESSION_TYPEBOUNDS,
  COMPILE_EXPRESSION_TYPEDEFAULTS,
  COMPILE_EXPRESSION_LIBRARY_URI,
  COMPILE_EXPRESSION_KLASS,
  COMPILE_EXPRESSION_METHOD,
  COMPILE_EXPRESSION_IS_STATIC,
  // compileExpressionToJs
  COMPILE_EXPRESSION_TO_JS_LIBRARYURI,
  COMPILE_EXPRESSION_TO_JS_LINE,
  COMPILE_EXPRESSION_TO_JS_COLUMN,
  COMPILE_EXPRESSION_TO_JS_JSMODULUES,
  COMPILE_EXPRESSION_TO_JS_JSFRAMEVALUES,
  COMPILE_EXPRESSION_TO_JS_MODULENAME,
  COMPILE_EXPRESSION_TO_JS_EXPRESSION,
}

/// Actions that every compiler should implement.
abstract class CompilerInterface {
  /// Compile given Dart program identified by `entryPoint` with given list of
  /// `options`. When `generator` parameter is omitted, new instance of
  /// `IncrementalKernelGenerator` is created by this method. Main use for this
  /// parameter is for mocking in tests.
  /// Returns [true] if compilation was successful and produced no errors.
  Future<bool> compile(
    String entryPoint,
    ArgResults options, {
    IncrementalCompiler? generator,
  });

  /// Sets the native assets mapping to be embedded in the kernel.
  Future<bool> setNativeAssets(String nativeAssets);

  /// Assuming some Dart program was previously compiled, recompile it again
  /// taking into account some changed(invalidated) sources.
  Future<void> recompileDelta({String? entryPoint});

  /// Accept results of previous compilation so that next recompilation cycle
  /// won't recompile sources that were previously reported as changed.
  void acceptLastDelta();

  /// Rejects results of previous compilation and sets compiler back to last
  /// accepted state.
  Future<void> rejectLastDelta();

  /// This let's compiler know that source file identified by `uri` was changed.
  void invalidate(Uri uri);

  /// Resets incremental compiler accept/reject status so that next time
  /// recompile is requested, complete kernel file is produced.
  void resetIncrementalCompiler();

  /// Compiles [expression] with free variables listed in [definitions],
  /// free type variables listed in [typedDefinitions]. "Free" means their
  /// values are through evaluation API call, rather than coming from running
  /// application.
  /// If [klass] is not [null], expression is compiled in context of [klass]
  /// class.
  /// If [klass] is [null],expression is compiled at top-level of
  /// [libraryUrl] library. If [klass] is not [null], [isStatic] determines
  /// whether expression can refer to [this] or not.
  Future<void> compileExpression(
      String expression,
      List<String> definitions,
      List<String> definitionTypes,
      List<String> typeDefinitions,
      List<String> typeBounds,
      List<String> typeDefaults,
      String libraryUri,
      String? klass,
      String? method,
      int offset,
      String? scriptUri,
      bool isStatic);

  /// Compiles [expression] in [libraryUri] at [line]:[column] to JavaScript
  /// in [moduleName].
  ///
  /// Values listed in [jsFrameValues] are substituted for their names in the
  /// [expression].
  ///
  /// Ensures that all [jsModules] are loaded and accessible inside the
  /// expression.
  ///
  /// Example values of parameters:
  /// [moduleName] is of the form '/packages/hello_world_main.dart'
  /// [jsFrameValues] is a map from js variable name to its primitive value
  /// or another variable name, for example
  /// { 'x': '1', 'y': 'y', 'o': 'null' }
  /// [jsModules] is a map from variable name to the module name, where
  /// variable name is the name originally used in JavaScript to contain the
  /// module object, for example:
  /// { 'dart':'dart_sdk', 'main': '/packages/hello_world_main.dart' }
  Future<void> compileExpressionToJs(
      String libraryUri,
      int line,
      int column,
      Map<String, String> jsModules,
      Map<String, String> jsFrameValues,
      String moduleName,
      String expression);

  /// Communicates an error [msg] to the client.
  void reportError(String msg);
}

abstract class ProgramTransformer {
  void transform(Component component);
}

/// Class that for test mocking purposes encapsulates creation of [BinaryPrinter].
class BinaryPrinterFactory {
  /// Creates new [BinaryPrinter] to write to [targetSink].
  BinaryPrinter newBinaryPrinter(Sink<List<int>> targetSink) {
    return BinaryPrinter(targetSink);
  }
}

class FrontendCompiler implements CompilerInterface {
  FrontendCompiler(
    StringSink? outputStream, {
    BinaryPrinterFactory? printerFactory,
    this.transformer,
    this.unsafePackageSerialization,
    this.incrementalSerialization = true,
    this.useDebuggerModuleNames = false,
    this.emitDebugMetadata = false,
    this.emitDebugSymbols = false,
    this.canaryFeatures = false,
  })  : _outputStream = outputStream ?? stdout,
        printerFactory = printerFactory ?? BinaryPrinterFactory();

  /// Fields with initializers
  final List<String> errors = <String>[];
  Set<Uri> previouslyReportedDependencies = <Uri>{};

  /// Initialized in the constructor
  bool emitDebugMetadata;
  bool emitDebugSymbols;
  bool incrementalSerialization;
  final StringSink _outputStream;
  BinaryPrinterFactory printerFactory;
  bool useDebuggerModuleNames;
  bool canaryFeatures;

  /// Initialized in [compile].
  late List<Uri> _additionalSources;
  late bool _assumeInitializeFromDillUpToDate;
  late CompilerOptions _compilerOptions;
  late FileSystem _fileSystem;
  late IncrementalCompiler _generator;
  late String _initializeFromDill;
  late String _kernelBinaryFilename;
  late String _kernelBinaryFilenameIncremental;
  late String _kernelBinaryFilenameFull;
  late Uri _mainSource;
  late ArgResults _options;
  late bool _printIncrementalDependencies;
  late ProcessedOptions _processedOptions;

  /// Initialized in [compile] from options, or (re)set in [setNativeAssets].
  Uri? _nativeAssets;

  /// Cached compilation of [_nativeAssets].
  ///
  /// Managed by [_compileNativeAssets] and [setNativeAssets].
  Library? _nativeAssetsLibrary;

  /// Initialized in [writeJavaScriptBundle].
  IncrementalJavaScriptBundler? _bundler;

  /// Nullable fields
  final ProgramTransformer? transformer;
  bool? unsafePackageSerialization;
  WidgetCache? _widgetCache;

  _onDiagnostic(DiagnosticMessage message) {
    switch (message.severity) {
      case Severity.error:
      case Severity.internalProblem:
        errors.addAll(message.plainTextFormatted);
        break;
      case Severity.warning:
      case Severity.info:
        break;
      case Severity.context:
      case Severity.ignored:
        throw 'Unexpected severity: ${message.severity}';
    }
    if (Verbosity.shouldPrint(_compilerOptions.verbosity, message)) {
      printDiagnosticMessage(message, _outputStream.writeln);
    }
  }

  void _installDartdevcTarget() {
    targets['dartdevc'] = (TargetFlags flags) => DevCompilerTarget(flags);
  }

  @override
  Future<bool> compile(
    String entryPoint,
    ArgResults options, {
    IncrementalCompiler? generator,
  }) async {
    _options = options;
    _fileSystem = createFrontEndFileSystem(
        options['filesystem-scheme'], options['filesystem-root'],
        allowHttp: options['enable-http-uris']);
    _mainSource = resolveInputUri(entryPoint);
    _additionalSources =
        (options['source'] as List<String>).map(resolveInputUri).toList();
    final nativeAssets = options['native-assets'] as String?;
    _nativeAssets = nativeAssets != null ? resolveInputUri(nativeAssets) : null;
    _kernelBinaryFilenameFull = _options['output-dill'] ?? '$entryPoint.dill';
    _kernelBinaryFilenameIncremental = _options['output-incremental-dill'] ??
        (_options['output-dill'] != null
            ? '${_options['output-dill']}.incremental.dill'
            : '$entryPoint.incremental.dill');
    _kernelBinaryFilename = _kernelBinaryFilenameFull;
    _initializeFromDill =
        _options['initialize-from-dill'] ?? _kernelBinaryFilenameFull;
    _assumeInitializeFromDillUpToDate =
        _options['assume-initialize-from-dill-up-to-date'] ?? false;
    _printIncrementalDependencies = _options['print-incremental-dependencies'];
    final String boundaryKey = Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');
    final Uri sdkRoot = _ensureFolderPath(options['sdk-root']);
    final String platformKernelDill =
        options['platform'] ?? 'platform_strong.dill';
    final String? packagesOption = _options['packages'];
    final bool nullSafety = _options['sound-null-safety'];
    final CompilerOptions compilerOptions = CompilerOptions()
      ..sdkRoot = sdkRoot
      ..fileSystem = _fileSystem
      ..packagesFileUri =
          packagesOption != null ? resolveInputUri(packagesOption) : null
      ..sdkSummary = sdkRoot.resolve(platformKernelDill)
      ..verbose = options['verbose']
      ..embedSourceText = options['embed-source-text']
      ..explicitExperimentalFlags = parseExperimentalFlags(
          parseExperimentalArguments(options['enable-experiment']),
          onError: (msg) => errors.add(msg))
      ..nnbdMode = (nullSafety == false) ? NnbdMode.Weak : NnbdMode.Strong
      ..onDiagnostic = _onDiagnostic
      ..verbosity = Verbosity.parseArgument(options['verbosity'],
          onError: (msg) => errors.add(msg));
    _compilerOptions = compilerOptions;

    if (options.wasParsed('libraries-spec')) {
      compilerOptions.librariesSpecificationUri =
          resolveInputUri(options['libraries-spec']);
    }

    if (options.wasParsed('filesystem-root')) {
      if (_options['output-dill'] == null) {
        print('When --filesystem-root is specified it is required to specify'
            ' --output-dill option that points to physical file system location'
            ' of a target dill file.');
        return false;
      }
    }

    final Map<String, String> environmentDefines = {};
    if (!parseCommandLineDefines(
        options['define'], environmentDefines, usage)) {
      return false;
    }

    if (options['aot']) {
      if (!options['link-platform']) {
        print('Error: --no-link-platform option cannot be used with --aot');
        return false;
      }
      if (options['split-output-by-packages']) {
        print(
            'Error: --split-output-by-packages option cannot be used with --aot');
        return false;
      }
      if (options['incremental']) {
        print('Error: --incremental option cannot be used with --aot');
        return false;
      }
      if (options['import-dill'] != null) {
        print('Error: --import-dill option cannot be used with --aot');
        return false;
      }
    }

    if (options['target-os'] != null) {
      if (!options['aot']) {
        print('Error: --target-os option must be used with --aot');
        return false;
      }
    }

    if (options['support-mirrors'] == true) {
      if (options['aot']) {
        print('Error: --support-mirrors option cannot be used with --aot');
        return false;
      }
      if (options['minimal-kernel']) {
        print('Error: --support-mirrors option cannot be used with '
            '--minimal-kernel');
        return false;
      }
    }

    if (options['incremental']) {
      if (options['from-dill'] != null) {
        print('Error: --from-dill option cannot be used with --incremental');
        return false;
      }
    }

    // Initialize additional supported kernel targets.
    _installDartdevcTarget();
    compilerOptions.target = createFrontEndTarget(
      options['target'],
      trackWidgetCreation: options['track-widget-creation'],
      nullSafety: compilerOptions.nnbdMode == NnbdMode.Strong,
      supportMirrors: options['support-mirrors'] ??
          !(options['aot'] || options['minimal-kernel']),
    );
    if (compilerOptions.target == null) {
      print('Failed to create front-end target ${options['target']}.');
      return false;
    }

    final String? importDill = options['import-dill'];
    if (importDill != null) {
      compilerOptions.additionalDills = <Uri>[
        Uri.base.resolveUri(Uri.file(importDill))
      ];
    }

    _processedOptions = ProcessedOptions(options: compilerOptions);

    KernelCompilationResults? results;
    IncrementalSerializer? incrementalSerializer;
    if (options['incremental']) {
      _compilerOptions.environmentDefines =
          _compilerOptions.target!.updateEnvironmentDefines(environmentDefines);

      _compilerOptions.omitPlatform = false;
      _generator = generator ?? _createGenerator(Uri.file(_initializeFromDill));
      await invalidateIfInitializingFromDill();
      IncrementalCompilerResult compilerResult =
          await _runWithPrintRedirection(() => _generator.compile());
      Component component = compilerResult.component;

      await _compileNativeAssets();

      results = KernelCompilationResults.named(
        component: component,
        nativeAssetsLibrary: _nativeAssetsLibrary,
        classHierarchy: compilerResult.classHierarchy,
        coreTypes: compilerResult.coreTypes,
        compiledSources: component.uriToSource.keys,
      );

      incrementalSerializer = _generator.incrementalSerializer;
      if (options['flutter-widget-cache']) {
        _widgetCache = WidgetCache(component);
      }
    } else {
      if (options['link-platform']) {
        // TODO(aam): Remove linkedDependencies once platform is directly embedded
        // into VM snapshot and http://dartbug.com/30111 is fixed.
        compilerOptions.additionalDills = <Uri>[
          sdkRoot.resolve(platformKernelDill)
        ];
      }
      results = await _runWithPrintRedirection(() => compileToKernel(
          _mainSource, compilerOptions,
          additionalSources: _additionalSources,
          nativeAssets: _nativeAssets,
          includePlatform: options['link-platform'],
          deleteToStringPackageUris: options['delete-tostring-package-uri'],
          keepClassNamesImplementing: options['keep-class-names-implementing'],
          aot: options['aot'],
          targetOS: options['target-os'],
          useGlobalTypeFlowAnalysis: options['tfa'],
          useRapidTypeAnalysis: options['rta'],
          environmentDefines: environmentDefines,
          enableAsserts: options['enable-asserts'],
          useProtobufTreeShakerV2: options['protobuf-tree-shaker-v2'],
          minimalKernel: options['minimal-kernel'],
          treeShakeWriteOnlyFields: options['tree-shake-write-only-fields'],
          fromDillFile: options['from-dill']));
    }
    if (results!.component != null) {
      transformer?.transform(results.component!);

      if (_compilerOptions.target!.name == 'dartdevc') {
        await writeJavaScriptBundle(results, _kernelBinaryFilename,
            options['filesystem-scheme'], options['dartdevc-module-format'],
            fullComponent: true);
      }
      await writeDillFile(
        results,
        _kernelBinaryFilename,
        filterExternal: importDill != null || options['minimal-kernel'],
        incrementalSerializer: incrementalSerializer,
        aot: options['aot'],
      );

      _outputStream.writeln(boundaryKey);
      final compiledSources = results.compiledSources!;
      await _outputDependenciesDelta(compiledSources);
      _outputStream
          .writeln('$boundaryKey $_kernelBinaryFilename ${errors.length}');
      final String? depfile = options['depfile'];
      if (depfile != null) {
        await writeDepfile(compilerOptions.fileSystem, compiledSources,
            _kernelBinaryFilename, depfile);
      }

      _kernelBinaryFilename = _kernelBinaryFilenameIncremental;
    } else {
      _outputStream.writeln(boundaryKey);
    }
    results = null; // Fix leak: Probably variation of http://dartbug.com/36983.
    return errors.isEmpty;
  }

  @override
  Future<bool> setNativeAssets(String nativeAssets) async {
    _nativeAssetsLibrary = null; // Purge compiled cache.
    _nativeAssets = resolveInputUri(nativeAssets);
    return true;
  }

  /// Compiles [_nativeAssets] into [_nativeAssetsLibrary].
  ///
  /// [compile] and [recompileDelta] invoke this, and bundles the cached
  /// [_nativeAssetsLibrary] in the dill file.
  Future<void> _compileNativeAssets() async {
    final nativeAssets = _nativeAssets;
    if (nativeAssets == null || _nativeAssetsLibrary != null) {
      return;
    }

    final results = await _runWithPrintRedirection(() => compileToKernel(
          null,
          _compilerOptions,
          nativeAssets: _nativeAssets,
          environmentDefines: {},
        ));
    _nativeAssetsLibrary = results.nativeAssetsLibrary;
  }

  Future<void> _outputDependenciesDelta(Iterable<Uri> compiledSources) async {
    if (!_printIncrementalDependencies) {
      return;
    }
    Set<Uri> uris = {};
    for (Uri uri in compiledSources) {
      // Skip empty or corelib dependencies.
      if (uri.isScheme('org-dartlang-sdk')) continue;
      uris.add(uri);
    }
    for (Uri uri in uris) {
      if (previouslyReportedDependencies.contains(uri)) {
        continue;
      }
      try {
        _outputStream.writeln('+${await asFileUri(_fileSystem, uri)}');
      } on FileSystemException {
        // Ignore errors from invalid import uris.
      }
    }
    for (Uri uri in previouslyReportedDependencies) {
      if (uris.contains(uri)) {
        continue;
      }
      try {
        _outputStream.writeln('-${await asFileUri(_fileSystem, uri)}');
      } on FileSystemException {
        // Ignore errors from invalid import uris.
      }
    }
    previouslyReportedDependencies = uris;
  }

  /// Write a JavaScript bundle containing the provided component.
  Future<void> writeJavaScriptBundle(KernelCompilationResults results,
      String filename, String fileSystemScheme, String moduleFormat,
      {required bool fullComponent}) async {
    var packageConfig = await loadPackageConfigUri(
        _compilerOptions.packagesFileUri ??
            File('.dart_tool/package_config.json').absolute.uri);
    var soundNullSafety = _compilerOptions.nnbdMode == NnbdMode.Strong;
    final Component component = results.component!;

    final bundler = _bundler ??= IncrementalJavaScriptBundler(
      _compilerOptions.fileSystem,
      results.loadedLibraries,
      fileSystemScheme,
      useDebuggerModuleNames: useDebuggerModuleNames,
      emitDebugMetadata: emitDebugMetadata,
      moduleFormat: moduleFormat,
      soundNullSafety: soundNullSafety,
      canaryFeatures: canaryFeatures,
    );
    if (fullComponent) {
      await bundler.initialize(component, _mainSource, packageConfig);
    } else {
      await bundler.invalidate(
          component,
          _generator.lastKnownGoodResult!.component,
          _mainSource,
          packageConfig);
    }

    // Create JavaScript bundler.
    final File sourceFile = File('$filename.sources');
    final File manifestFile = File('$filename.json');
    final File sourceMapsFile = File('$filename.map');
    final File metadataFile = File('$filename.metadata');
    final File symbolsFile = File('$filename.symbols');
    if (!sourceFile.parent.existsSync()) {
      sourceFile.parent.createSync(recursive: true);
    }

    final sourceFileSink = sourceFile.openWrite();
    final manifestFileSink = manifestFile.openWrite();
    final sourceMapsFileSink = sourceMapsFile.openWrite();
    final metadataFileSink =
        emitDebugMetadata ? metadataFile.openWrite() : null;
    final symbolsFileSink = emitDebugSymbols ? symbolsFile.openWrite() : null;
    final kernel2JsCompilers = await bundler.compile(
        results.classHierarchy!,
        results.coreTypes!,
        packageConfig,
        sourceFileSink,
        manifestFileSink,
        sourceMapsFileSink,
        metadataFileSink,
        symbolsFileSink);
    cachedProgramCompilers.addAll(kernel2JsCompilers);
    await Future.wait([
      sourceFileSink.close(),
      manifestFileSink.close(),
      sourceMapsFileSink.close(),
      if (metadataFileSink != null) metadataFileSink.close(),
      if (symbolsFileSink != null) symbolsFileSink.close(),
    ]);
  }

  writeDillFile(
    KernelCompilationResults results,
    String filename, {
    bool filterExternal = false,
    IncrementalSerializer? incrementalSerializer,
    bool aot = false,
  }) async {
    final Component component = results.component!;
    final Library? nativeAssetsLibrary = results.nativeAssetsLibrary;

    if (aot && nativeAssetsLibrary != null) {
      // If Dart component in AOT, write the vm:native-assets library _inside_
      // the Dart component.
      // TODO(https://dartbug.com/50152): Support AOT dill concatenation.
      component.libraries.add(nativeAssetsLibrary);
      nativeAssetsLibrary.parent = component;
    }

    final IOSink sink = File(filename).openWrite();

    final Set<Library> loadedLibraries = results.loadedLibraries;
    final BinaryPrinter printer = filterExternal
        ? BinaryPrinter(sink,
            libraryFilter: (lib) => !loadedLibraries.contains(lib),
            includeSources: false)
        : printerFactory.newBinaryPrinter(sink);

    sortComponent(component);

    if (incrementalSerializer != null) {
      incrementalSerializer.writePackagesToSinkAndTrimComponent(
          component, sink);
    } else if (unsafePackageSerialization == true) {
      writePackagesToSinkAndTrimComponent(component, sink);
    }

    printer.writeComponentFile(component);

    if (nativeAssetsLibrary != null && !aot) {
      final BinaryPrinter printer = BinaryPrinter(sink);
      printer.writeComponentFile(Component(
        libraries: [nativeAssetsLibrary],
        mode: nativeAssetsLibrary.nonNullableByDefaultCompiledMode,
      ));
    }
    await sink.close();

    if (_options['split-output-by-packages']) {
      await writeOutputSplitByPackages(
          _mainSource, _compilerOptions, results, filename);
    }

    final String? manifestFilename = _options['far-manifest'];
    if (manifestFilename != null) {
      final String output = _options['output-dill'];
      final String? dataDir = _options.options.contains('component-name')
          ? _options['component-name']
          : _options['data-dir'];
      await createFarManifest(output, dataDir, manifestFilename);
    }
  }

  Future<void> invalidateIfInitializingFromDill() async {
    if (_assumeInitializeFromDillUpToDate) return;
    if (_kernelBinaryFilename != _kernelBinaryFilenameFull) return;
    // If the generator is initialized, it's not going to initialize from dill
    // again anyway, so there's no reason to spend time invalidating what should
    // be invalidated by the normal approach anyway.
    if (_generator.initialized) return;

    final File f = File(_initializeFromDill);
    if (!f.existsSync()) return;

    Component component;
    try {
      component = loadComponentSourceFromBytes(f.readAsBytesSync());
    } catch (e) {
      // If we cannot load the dill file we shouldn't initialize from it.
      _generator = _createGenerator(null);
      return;
    }

    nextUri:
    for (Uri uri in component.uriToSource.keys) {
      if ('$uri' == '') continue nextUri;

      final List<int> oldBytes = component.uriToSource[uri]!.source;
      FileSystemEntity entity;
      try {
        entity = _compilerOptions.fileSystem.entityForUri(uri);
      } catch (_) {
        // Ignore errors that might be caused by non-file uris.
        continue nextUri;
      }

      bool exists;
      try {
        exists = await entity.exists();
      } catch (e) {
        exists = false;
      }

      if (!exists) {
        _generator.invalidate(uri);
        continue nextUri;
      }
      final List<int> newBytes = await entity.readAsBytes();
      if (oldBytes.length != newBytes.length) {
        _generator.invalidate(uri);
        continue nextUri;
      }
      for (int i = 0; i < oldBytes.length; ++i) {
        if (oldBytes[i] != newBytes[i]) {
          _generator.invalidate(uri);
          continue nextUri;
        }
      }
    }
  }

  @override
  Future<void> recompileDelta({String? entryPoint}) async {
    final String boundaryKey = Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');
    await invalidateIfInitializingFromDill();
    if (entryPoint != null) {
      _mainSource = resolveInputUri(entryPoint);
    }
    errors.clear();

    IncrementalCompilerResult deltaProgramResult = await _generator
        .compile(entryPoints: [_mainSource, ..._additionalSources]);
    Component deltaProgram = deltaProgramResult.component;
    transformer?.transform(deltaProgram);

    await _compileNativeAssets();

    KernelCompilationResults results = KernelCompilationResults.named(
      component: deltaProgram,
      classHierarchy: deltaProgramResult.classHierarchy,
      coreTypes: deltaProgramResult.coreTypes,
      compiledSources: deltaProgram.uriToSource.keys,
      nativeAssetsLibrary: _nativeAssetsLibrary,
    );

    if (_compilerOptions.target!.name == 'dartdevc') {
      await writeJavaScriptBundle(results, _kernelBinaryFilename,
          _options['filesystem-scheme'], _options['dartdevc-module-format'],
          fullComponent: false);
    } else {
      await writeDillFile(results, _kernelBinaryFilename,
          incrementalSerializer: _generator.incrementalSerializer);
    }
    _updateWidgetCache(deltaProgram);

    _outputStream.writeln(boundaryKey);
    await _outputDependenciesDelta(results.compiledSources!);
    _outputStream
        .writeln('$boundaryKey $_kernelBinaryFilename ${errors.length}');
    _kernelBinaryFilename = _kernelBinaryFilenameIncremental;
  }

  @override
  Future<void> compileExpression(
      String expression,
      List<String> definitions,
      List<String> definitionTypes,
      List<String> typeDefinitions,
      List<String> typeBounds,
      List<String> typeDefaults,
      String libraryUri,
      String? klass,
      String? method,
      int offset,
      String? scriptUri,
      bool isStatic) async {
    final String boundaryKey = Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');
    Procedure? procedure = await _generator.compileExpression(
        expression,
        definitions,
        definitionTypes,
        typeDefinitions,
        typeBounds,
        typeDefaults,
        libraryUri,
        klass,
        method,
        offset,
        scriptUri,
        isStatic);
    if (procedure != null) {
      Component component = createExpressionEvaluationComponent(procedure);
      final IOSink sink = File(_kernelBinaryFilename).openWrite();
      sink.add(serializeComponent(component));
      await sink.close();
      _outputStream
          .writeln('$boundaryKey $_kernelBinaryFilename ${errors.length}');
      _kernelBinaryFilename = _kernelBinaryFilenameIncremental;
    } else {
      _outputStream.writeln(boundaryKey);
    }
  }

  /// Program compilers per module.
  ///
  /// Produced during initial compilation of the module to JavaScript,
  /// cached to be used for expression compilation in [compileExpressionToJs].
  final Map<String, ProgramCompiler> cachedProgramCompilers = {};

  @override
  Future<void> compileExpressionToJs(
      String libraryUri,
      int line,
      int column,
      Map<String, String> jsModules,
      Map<String, String> jsFrameValues,
      String moduleName,
      String expression) async {
    _generator.accept();
    errors.clear();

    if (_bundler == null) {
      reportError('JavaScript bundler is null');
      return;
    }
    if (!cachedProgramCompilers.containsKey(moduleName)) {
      reportError('Cannot find kernel2js compiler for $moduleName.');
      return;
    }

    final String boundaryKey = Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');

    _processedOptions.ticker
        .logMs('Compiling expression to JavaScript in $moduleName');

    final kernel2jsCompiler = cachedProgramCompilers[moduleName]!;
    IncrementalCompilerResult compilerResult = _generator.lastKnownGoodResult!;
    Component component = compilerResult.component;
    component.computeCanonicalNames();

    _processedOptions.ticker.logMs('Computed component');

    final expressionCompiler = ExpressionCompiler(
      _compilerOptions,
      parseModuleFormat(_options['dartdevc-module-format'] as String),
      errors,
      _generator.generator as ddc.IncrementalCompiler,
      kernel2jsCompiler,
      component,
    );

    final procedure = await expressionCompiler.compileExpressionToJs(
        libraryUri, line, column, jsFrameValues, expression);

    final result = errors.isNotEmpty ? errors[0] : procedure!;

    // TODO(annagrin): kernelBinaryFilename is too specific
    // rename to _outputFileName?
    await File(_kernelBinaryFilename).writeAsString(result);

    _processedOptions.ticker.logMs('Compiled expression to JavaScript');

    _outputStream
        .writeln('$boundaryKey $_kernelBinaryFilename ${errors.length}');

    // TODO(annagrin): do we need to add asserts/error reporting if
    // initial compilation didn't happen and _kernelBinaryFilename
    // is different from below?
    if (procedure != null) {
      _kernelBinaryFilename = _kernelBinaryFilenameIncremental;
    }
  }

  @override
  void reportError(String msg) {
    final String boundaryKey = Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');
    _outputStream.writeln(msg);
    _outputStream.writeln(boundaryKey);
  }

  /// Map of already serialized dill data. All uris in a serialized component
  /// maps to the same blob of data. Used by
  /// [writePackagesToSinkAndTrimComponent].
  Map<Uri, List<int>> cachedPackageLibraries = <Uri, List<int>>{};

  /// Map of dependencies for already serialized dill data.
  /// E.g. if blob1 dependents on blob2, but only using a single file from blob1
  /// that does not dependent on blob2, blob2 would not be included leaving the
  /// dill file in a weird state that could cause the VM to crash if asked to
  /// forcefully compile everything. Used by
  /// [writePackagesToSinkAndTrimComponent].
  Map<Uri, List<Uri>> cachedPackageDependencies = <Uri, List<Uri>>{};

  writePackagesToSinkAndTrimComponent(
      Component deltaProgram, Sink<List<int>> ioSink) {
    List<Library> packageLibraries = <Library>[];
    List<Library> libraries = <Library>[];
    deltaProgram.computeCanonicalNames();

    for (var lib in deltaProgram.libraries) {
      Uri uri = lib.importUri;
      if (uri.isScheme("package")) {
        packageLibraries.add(lib);
      } else {
        libraries.add(lib);
      }
    }
    deltaProgram.libraries
      ..clear()
      ..addAll(libraries);

    Map<String, List<Library>> newPackages = <String, List<Library>>{};
    Set<List<int>> alreadyAdded = <List<int>>{};

    addDataAndDependentData(List<int> data, Uri uri) {
      if (alreadyAdded.add(data)) {
        ioSink.add(data);
        // Now also add all dependencies.
        for (Uri dep in cachedPackageDependencies[uri]!) {
          addDataAndDependentData(cachedPackageLibraries[dep]!, dep);
        }
      }
    }

    for (Library lib in packageLibraries) {
      List<int>? data = cachedPackageLibraries[lib.fileUri];
      if (data != null) {
        addDataAndDependentData(data, lib.fileUri);
      } else {
        String package = lib.importUri.pathSegments.first;
        (newPackages[package] ??= <Library>[]).add(lib);
      }
    }

    for (String package in newPackages.keys) {
      List<Library> libraries = newPackages[package]!;
      Component singleLibrary = Component(
          libraries: libraries,
          uriToSource: deltaProgram.uriToSource,
          nameRoot: deltaProgram.root);
      singleLibrary.setMainMethodAndMode(null, false, deltaProgram.mode);
      ByteSink byteSink = ByteSink();
      final BinaryPrinter printer = printerFactory.newBinaryPrinter(byteSink);
      printer.writeComponentFile(singleLibrary);

      // Record things this package blob dependent on.
      Set<Uri> libraryUris = <Uri>{};
      for (Library lib in libraries) {
        libraryUris.add(lib.fileUri);
      }
      Set<Uri> deps = <Uri>{};
      for (Library lib in libraries) {
        for (LibraryDependency dep in lib.dependencies) {
          Library dependencyLibrary = dep.importedLibraryReference.asLibrary;
          if (!dependencyLibrary.importUri.isScheme("package")) continue;
          Uri dependencyLibraryUri =
              dep.importedLibraryReference.asLibrary.fileUri;
          if (libraryUris.contains(dependencyLibraryUri)) continue;
          deps.add(dependencyLibraryUri);
        }
      }

      List<int> data = byteSink.builder.takeBytes();
      for (Library lib in libraries) {
        cachedPackageLibraries[lib.fileUri] = data;
        cachedPackageDependencies[lib.fileUri] = List<Uri>.from(deps);
      }
      ioSink.add(data);
    }
  }

  @override
  void acceptLastDelta() {
    _generator.accept();
    _widgetCache?.reset();
  }

  @override
  Future<void> rejectLastDelta() async {
    final String boundaryKey = Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');
    await _generator.reject();
    _outputStream.writeln(boundaryKey);
  }

  @override
  void invalidate(Uri uri) {
    _generator.invalidate(uri);
    _widgetCache?.invalidate(uri);
  }

  @override
  void resetIncrementalCompiler() {
    _generator.resetDeltaState();
    _widgetCache?.reset();
    _kernelBinaryFilename = _kernelBinaryFilenameFull;
  }

  IncrementalCompiler _createGenerator(Uri? initializeFromDillUri) {
    return IncrementalCompiler(
        _compilerOptions, [_mainSource, ..._additionalSources],
        initializeFromDillUri: initializeFromDillUri,
        incrementalSerialization: incrementalSerialization);
  }

  /// If the flutter widget cache is enabled, check if a single class was modified.
  ///
  /// The resulting class name is written as a String to
  /// `_kernelBinaryFilename`.widget_cache, or else the file is deleted
  /// if it exists.
  ///
  /// Should not run if a full component is requested.
  void _updateWidgetCache(Component partialComponent) {
    if (_widgetCache == null || _generator.fullComponent) {
      return;
    }
    final String? singleModifiedClassName =
        _widgetCache!.checkSingleWidgetTypeModified(
      _generator.lastKnownGoodResult?.component,
      partialComponent,
      _generator.lastKnownGoodResult?.classHierarchy,
    );
    final File outputFile = File('$_kernelBinaryFilename.widget_cache');
    if (singleModifiedClassName != null) {
      outputFile.writeAsStringSync(singleModifiedClassName);
    } else if (outputFile.existsSync()) {
      outputFile.deleteSync();
    }
  }

  Uri _ensureFolderPath(String path) {
    String uriPath = Uri.file(path).toString();
    if (!uriPath.endsWith('/')) {
      uriPath = '$uriPath/';
    }
    return Uri.base.resolve(uriPath);
  }

  /// Runs the given function [f] in a Zone that redirects all prints into
  /// [_outputStream].
  Future<T> _runWithPrintRedirection<T>(Future<T> Function() f) {
    return runZoned(() => Future<T>(f),
        zoneSpecification: ZoneSpecification(
            print: (Zone self, ZoneDelegate parent, Zone zone, String line) =>
                _outputStream.writeln(line)));
  }
}

/// A [Sink] that directly writes data into a byte builder.
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = BytesBuilder();

  @override
  void add(List<int> data) {
    builder.add(data);
  }

  @override
  void close() {}
}

class _CompileExpressionRequest {
  late String expression;
  // Note that FE will reject a compileExpression command by returning a null
  // procedure when defs or typeDefs include an illegal identifier.
  List<String> defs = <String>[];
  List<String> defTypes = <String>[];
  List<String> typeDefs = <String>[];
  List<String> typeBounds = <String>[];
  List<String> typeDefaults = <String>[];
  late String library;
  String? klass;
  String? method;
  int offset = -1;
  String? scriptUri;
  late bool isStatic;
}

class _CompileExpressionToJsRequest {
  late String libraryUri;
  late int line;
  late int column;
  Map<String, String> jsModules = <String, String>{};
  Map<String, String> jsFrameValues = <String, String>{};
  late String moduleName;
  late String expression;
}

/// Listens for the compilation commands on [input] stream.
/// This supports "interactive" recompilation mode of execution.
StreamSubscription<String> listenAndCompile(CompilerInterface compiler,
    Stream<List<int>> input, ArgResults options, Completer<int> completer,
    {IncrementalCompiler? generator}) {
  _State state = _State.READY_FOR_INSTRUCTION;
  late _CompileExpressionRequest compileExpressionRequest;
  late _CompileExpressionToJsRequest compileExpressionToJsRequest;
  late String boundaryKey;
  String? recompileEntryPoint;
  return input
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String string) async {
    switch (state) {
      case _State.READY_FOR_INSTRUCTION:
        const String COMPILE_INSTRUCTION_SPACE = 'compile ';
        const String RECOMPILE_INSTRUCTION_SPACE = 'recompile ';
        const String NATIVE_ASSETS_INSTRUCTION_SPACE = 'native-assets ';
        const String COMPILE_EXPRESSION_INSTRUCTION_SPACE =
            'compile-expression ';
        const String COMPILE_EXPRESSION_TO_JS_INSTRUCTION_SPACE =
            'compile-expression-to-js ';
        if (string.startsWith(COMPILE_INSTRUCTION_SPACE)) {
          final String entryPoint =
              string.substring(COMPILE_INSTRUCTION_SPACE.length);
          await compiler.compile(entryPoint, options, generator: generator);
        } else if (string.startsWith(RECOMPILE_INSTRUCTION_SPACE)) {
          // 'recompile [<entryPoint>] <boundarykey>'
          //   where <boundarykey> can't have spaces
          final String remainder =
              string.substring(RECOMPILE_INSTRUCTION_SPACE.length);
          final int spaceDelim = remainder.lastIndexOf(' ');
          if (spaceDelim > -1) {
            recompileEntryPoint = remainder.substring(0, spaceDelim);
            boundaryKey = remainder.substring(spaceDelim + 1);
          } else {
            boundaryKey = remainder;
          }
          state = _State.RECOMPILE_LIST;
        } else if (string.startsWith(NATIVE_ASSETS_INSTRUCTION_SPACE)) {
          final String nativeAssets =
              string.substring(NATIVE_ASSETS_INSTRUCTION_SPACE.length);
          await compiler.setNativeAssets(nativeAssets);
        } else if (string
            .startsWith(COMPILE_EXPRESSION_TO_JS_INSTRUCTION_SPACE)) {
          // 'compile-expression-to-js <boundarykey>
          // libraryUri
          // line
          // column
          // jsModules (one k-v pair per line)
          // ...
          // <boundarykey>
          // jsFrameValues (one k-v pair per line)
          // ...
          // <boundarykey>
          // moduleName
          // expression
          compileExpressionToJsRequest = _CompileExpressionToJsRequest();
          boundaryKey = string
              .substring(COMPILE_EXPRESSION_TO_JS_INSTRUCTION_SPACE.length);
          state = _State.COMPILE_EXPRESSION_TO_JS_LIBRARYURI;
        } else if (string.startsWith(COMPILE_EXPRESSION_INSTRUCTION_SPACE)) {
          // 'compile-expression <boundarykey>
          // expression
          // definitions (one per line)
          // ...
          // <boundarykey>
          // definitionTypes (one per line)
          // ...
          // <boundarykey>
          // type-definitions (one per line)
          // ...
          // <boundarykey>
          // type-bounds (one per line)
          // ...
          // <boundarykey>
          // type-defaults (one per line)
          // ...
          // <boundarykey>
          // <libraryUri: String>
          // <klass: String>
          // <method: String>
          // <isStatic: true|false>
          compileExpressionRequest = _CompileExpressionRequest();
          boundaryKey =
              string.substring(COMPILE_EXPRESSION_INSTRUCTION_SPACE.length);
          state = _State.COMPILE_EXPRESSION_EXPRESSION;
        } else if (string == 'accept') {
          compiler.acceptLastDelta();
        } else if (string == 'reject') {
          await compiler.rejectLastDelta();
        } else if (string == 'reset') {
          compiler.resetIncrementalCompiler();
        } else if (string == 'quit') {
          if (!completer.isCompleted) {
            completer.complete(0);
          }
        }
        break;
      case _State.RECOMPILE_LIST:
        if (string == boundaryKey) {
          await compiler.recompileDelta(entryPoint: recompileEntryPoint);
          state = _State.READY_FOR_INSTRUCTION;
        } else {
          compiler.invalidate(Uri.base.resolve(string));
        }
        break;
      case _State.COMPILE_EXPRESSION_EXPRESSION:
        compileExpressionRequest.expression = string;
        state = _State.COMPILE_EXPRESSION_DEFS;
        break;
      case _State.COMPILE_EXPRESSION_DEFS:
        if (string == boundaryKey) {
          state = _State.COMPILE_EXPRESSION_DEFTYPES;
        } else {
          compileExpressionRequest.defs.add(string);
        }
        break;
      case _State.COMPILE_EXPRESSION_DEFTYPES:
        if (string == boundaryKey) {
          state = _State.COMPILE_EXPRESSION_TYPEDEFS;
        } else {
          compileExpressionRequest.defTypes.add(string);
        }
        break;
      case _State.COMPILE_EXPRESSION_TYPEDEFS:
        if (string == boundaryKey) {
          state = _State.COMPILE_EXPRESSION_TYPEBOUNDS;
        } else {
          compileExpressionRequest.typeDefs.add(string);
        }
        break;
      case _State.COMPILE_EXPRESSION_TYPEBOUNDS:
        if (string == boundaryKey) {
          state = _State.COMPILE_EXPRESSION_TYPEDEFAULTS;
        } else {
          compileExpressionRequest.typeBounds.add(string);
        }
        break;
      case _State.COMPILE_EXPRESSION_TYPEDEFAULTS:
        if (string == boundaryKey) {
          state = _State.COMPILE_EXPRESSION_LIBRARY_URI;
        } else {
          compileExpressionRequest.typeDefaults.add(string);
        }
        break;
      case _State.COMPILE_EXPRESSION_LIBRARY_URI:
        compileExpressionRequest.library = string;
        state = _State.COMPILE_EXPRESSION_KLASS;
        break;
      case _State.COMPILE_EXPRESSION_KLASS:
        compileExpressionRequest.klass = string.isEmpty ? null : string;
        state = _State.COMPILE_EXPRESSION_METHOD;
        break;
      case _State.COMPILE_EXPRESSION_METHOD:
        compileExpressionRequest.method = string.isEmpty ? null : string;
        state = _State.COMPILE_EXPRESSION_IS_STATIC;
        break;
      case _State.COMPILE_EXPRESSION_IS_STATIC:
        if (string == 'true' || string == 'false') {
          compileExpressionRequest.isStatic = string == 'true';
          await compiler.compileExpression(
              compileExpressionRequest.expression,
              compileExpressionRequest.defs,
              compileExpressionRequest.defTypes,
              compileExpressionRequest.typeDefs,
              compileExpressionRequest.typeBounds,
              compileExpressionRequest.typeDefaults,
              compileExpressionRequest.library,
              compileExpressionRequest.klass,
              compileExpressionRequest.method,
              compileExpressionRequest.offset,
              compileExpressionRequest.scriptUri,
              compileExpressionRequest.isStatic);
        } else {
          compiler
              .reportError('Got $string. Expected either "true" or "false"');
        }
        state = _State.READY_FOR_INSTRUCTION;
        break;
      case _State.COMPILE_EXPRESSION_TO_JS_LIBRARYURI:
        compileExpressionToJsRequest.libraryUri = string;
        state = _State.COMPILE_EXPRESSION_TO_JS_LINE;
        break;
      case _State.COMPILE_EXPRESSION_TO_JS_LINE:
        compileExpressionToJsRequest.line = int.parse(string);
        state = _State.COMPILE_EXPRESSION_TO_JS_COLUMN;
        break;
      case _State.COMPILE_EXPRESSION_TO_JS_COLUMN:
        compileExpressionToJsRequest.column = int.parse(string);
        state = _State.COMPILE_EXPRESSION_TO_JS_JSMODULUES;
        break;
      case _State.COMPILE_EXPRESSION_TO_JS_JSMODULUES:
        if (string == boundaryKey) {
          state = _State.COMPILE_EXPRESSION_TO_JS_JSFRAMEVALUES;
        } else {
          var list = string.split(':');
          var key = list[0];
          var value = list[1];
          compileExpressionToJsRequest.jsModules[key] = value;
        }
        break;
      case _State.COMPILE_EXPRESSION_TO_JS_JSFRAMEVALUES:
        if (string == boundaryKey) {
          state = _State.COMPILE_EXPRESSION_TO_JS_MODULENAME;
        } else {
          var list = string.split(':');
          var key = list[0];
          var value = list[1];
          compileExpressionToJsRequest.jsFrameValues[key] = value;
        }
        break;
      case _State.COMPILE_EXPRESSION_TO_JS_MODULENAME:
        compileExpressionToJsRequest.moduleName = string;
        state = _State.COMPILE_EXPRESSION_TO_JS_EXPRESSION;
        break;
      case _State.COMPILE_EXPRESSION_TO_JS_EXPRESSION:
        compileExpressionToJsRequest.expression = string;
        await compiler.compileExpressionToJs(
            compileExpressionToJsRequest.libraryUri,
            compileExpressionToJsRequest.line,
            compileExpressionToJsRequest.column,
            compileExpressionToJsRequest.jsModules,
            compileExpressionToJsRequest.jsFrameValues,
            compileExpressionToJsRequest.moduleName,
            compileExpressionToJsRequest.expression);
        state = _State.READY_FOR_INSTRUCTION;
        break;
    }
  });
}
