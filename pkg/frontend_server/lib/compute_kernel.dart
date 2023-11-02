// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

/// A library to invoke the CFE to compute kernel summary files.
///
/// Used by `utils/bazel/kernel_worker.dart`.
library;

import 'dart:async';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/macros/executor/isolated_executor.dart'
    as isolated_executor;
import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart'
    as multi_executor;
import 'package:_fe_analyzer_shared/src/macros/executor/process_executor.dart'
    as process_executor;
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart'
    show SerializationMode;
import 'package:args/args.dart';
import 'package:build_integration/file_system/multi_root.dart';
import 'package:compiler/src/kernel/dart2js_target.dart';
import 'package:dart2wasm/target.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/api_unstable/bazel_worker.dart' as fe;
import 'package:front_end/src/fasta/kernel/macro/macro.dart';
import 'package:kernel/ast.dart'
    show Component, Library, NonNullableByDefaultCompiledMode;
import 'package:kernel/target/targets.dart';
import 'package:vm/kernel_front_end.dart';
import 'package:vm/native_assets/synthesizer.dart';
import 'package:vm/target/flutter.dart';
import 'package:vm/target/flutter_runner.dart';
import 'package:vm/target/vm.dart';

/// If the last arg starts with `@`, this reads the file it points to and treats
/// each line as an additional arg.
///
/// This is how individual work request args are differentiated from startup
/// args in bazel (individual work request args go in that file).
List<String> preprocessArgs(List<String> args) {
  args = List.from(args);
  if (args.isEmpty) {
    return args;
  }
  String lastArg = args.last;
  if (lastArg.startsWith('@')) {
    File argsFile = File(lastArg.substring(1));
    try {
      args.removeLast();
      args.addAll(argsFile.readAsLinesSync());
    } on FileSystemException catch (e) {
      throw Exception('Failed to read file specified by $lastArg : $e');
    }
  }
  return args;
}

/// An [ArgParser] for generating kernel summaries.
final summaryArgsParser = ArgParser()
  ..addFlag('help', negatable: false, abbr: 'h')
  ..addFlag('exclude-non-sources',
      negatable: false,
      help: 'Whether source files loaded implicitly should be included as '
          'part of the summary.')
  ..addFlag('summary-only',
      defaultsTo: true,
      negatable: true,
      help: 'Whether to only build summary files.')
  ..addFlag('summary',
      defaultsTo: true,
      negatable: true,
      help: 'Whether or not to build summary files.')
  ..addOption('target',
      allowed: const [
        'vm',
        'flutter',
        'flutter_runner',
        'dart2js',
        'dart2js_summary',
        'dart2wasm',
        'ddc',
      ],
      help: 'Build kernel for the vm, flutter, flutter_runner, dart2js, '
          'dart2wasm or ddc.')
  ..addOption('dart-sdk-summary')
  ..addMultiOption('redirect')
  ..addMultiOption('input-summary')
  ..addMultiOption('input-linked')
  ..addMultiOption('multi-root')
  ..addOption('multi-root-scheme', defaultsTo: 'org-dartlang-multi-root')
  ..addOption('libraries-file')
  ..addOption('packages-file')
  ..addMultiOption('source')
  ..addOption('output')
  ..addFlag('reuse-compiler-result', defaultsTo: false)
  ..addFlag('use-incremental-compiler', defaultsTo: false)
  ..addOption('used-inputs')
  ..addFlag('track-widget-creation', defaultsTo: false)
  ..addMultiOption('enable-experiment',
      help: 'Enable a language experiment when invoking the CFE.')
  ..addMultiOption('define', abbr: 'D')
  ..addFlag('verbose', defaultsTo: false)
  ..addFlag('sound-null-safety', defaultsTo: true)
  ..addFlag('null-environment', defaultsTo: false, negatable: false)
  ..addOption('verbosity',
      defaultsTo: fe.Verbosity.defaultValue,
      help: 'Sets the verbosity level used for filtering messages during '
          'compilation.',
      allowed: fe.Verbosity.allowedValues,
      allowedHelp: fe.Verbosity.allowedValuesHelp)
  ..addMultiOption('precompiled-macro',
      help: 'Configuration for precompiled macro binaries or kernel files.\n'
          'Must be used in combination with --precompiled-macro-format.\n'
          'The expected format of this option is as follows: '
          '<absolute-path-to-binary>;<macro-library-uri>\nFor example: '
          '--precompiled-macro="/path/to/compiled/macro;'
          'package:some_macro/some_macro.dart". Multiple library uris may be '
          'passed as well (separated by semicolons).')
  ..addOption('precompiled-macro-format',
      help: 'The format for precompiled macros.',
      allowed: ['aot', 'kernel'],
      defaultsTo: 'aot')
  ..addOption('macro-serialization-mode',
      help: 'The serialization mode for communicating with macros.',
      allowed: ['bytedata', 'json'],
      defaultsTo: 'bytedata')
  ..addOption('native-assets', help: 'Path to native assets yaml file.');

class ComputeKernelResult {
  final bool succeeded;
  final fe.InitializedCompilerState? previousState;

  ComputeKernelResult(this.succeeded, this.previousState);
}

/// Computes a kernel file based on [args].
///
/// If [isWorker] is true then exit codes will not be set on failure.
///
/// If [outputBuffer] is provided then messages will be written to that buffer
/// instead of printed to the console.
///
/// Returns whether or not the summary was successfully output.
Future<ComputeKernelResult> computeKernel(List<String> args,
    {bool isWorker = false,
    StringBuffer? outputBuffer,
    Map<Uri, List<int>>? inputDigests,
    fe.InitializedCompilerState? previousState}) async {
  inputDigests ??= <Uri, List<int>>{};
  dynamic out = outputBuffer ?? stderr;
  bool succeeded = true;

  var parsedArgs = summaryArgsParser.parse(args);

  if (parsedArgs['help']) {
    out.writeln(summaryArgsParser.usage);
    if (!isWorker) exit(0);
    return ComputeKernelResult(false, previousState);
  }

  // Bazel creates an overlay file system where some files may be located in the
  // source tree, some in a gendir, and some in a bindir. The multi-root file
  // system hides this from the front end.
  var multiRoots = parsedArgs['multi-root'].map(Uri.base.resolve).toList();
  if (multiRoots.isEmpty) multiRoots.add(Uri.base);
  MultiRootFileSystem mrfs = MultiRootFileSystem(
      parsedArgs['multi-root-scheme'],
      multiRoots,
      fe.StandardFileSystem.instance);
  FileSystem fileSystem = mrfs;
  var sources = (parsedArgs['source'] as List<String>).map(toUri).toList();
  var excludeNonSources = parsedArgs['exclude-non-sources'] as bool;

  var nnbdMode = parsedArgs['sound-null-safety'] as bool
      ? fe.NnbdMode.Strong
      : fe.NnbdMode.Weak;
  var summaryOnly = parsedArgs['summary-only'] as bool;
  var summary = parsedArgs['summary'] as bool;
  if (summaryOnly && !summary) {
    throw ArgumentError('--summary-only conflicts with --no-summary');
  }
  var trackWidgetCreation = parsedArgs['track-widget-creation'] as bool;

  // TODO(sigmund,jakemac): make target mandatory. We allow null to be backwards
  // compatible while we migrate existing clients of this tool.
  var targetName =
      (parsedArgs['target'] as String?) ?? (summaryOnly ? 'ddc' : 'vm');
  var targetFlags = TargetFlags(
      trackWidgetCreation: trackWidgetCreation,
      soundNullSafety: nnbdMode == fe.NnbdMode.Strong);
  Target target;
  switch (targetName) {
    case 'vm':
      target = VmTarget(targetFlags);
      if (summaryOnly) {
        out.writeln('error: --summary-only not supported for the vm target');
      }
      break;
    case 'flutter':
      target = FlutterTarget(targetFlags);
      if (summaryOnly) {
        throw ArgumentError(
            'error: --summary-only not supported for the flutter target');
      }
      break;
    case 'flutter_runner':
      target = FlutterRunnerTarget(targetFlags);
      if (summaryOnly) {
        throw ArgumentError('error: --summary-only not supported for the '
            'flutter_runner target');
      }
      break;
    case 'dart2js':
      target = Dart2jsTarget('dart2js', targetFlags);
      if (summaryOnly) {
        out.writeln(
            'error: --summary-only not supported for the dart2js target');
      }
      break;
    case 'dart2js_summary':
      target = Dart2jsSummaryTarget(
          'dart2js', sources, excludeNonSources, targetFlags);
      if (!summaryOnly) {
        out.writeln(
            'error: --no-summary-only not supported for the dart2js summary target');
      }
      break;
    case 'ddc':
      // TODO(jakemac):If `generateKernel` changes to return a summary
      // component, process the component instead.
      target =
          DevCompilerSummaryTarget(sources, excludeNonSources, targetFlags);
      if (!summaryOnly) {
        out.writeln('error: --no-summary-only not supported for the '
            'ddc target');
      }
      break;
    case 'dart2wasm':
      target = WasmTarget();
      break;
    default:
      out.writeln('error: unsupported target: $targetName');
      return ComputeKernelResult(false, previousState);
  }

  List<Uri> linkedInputs =
      (parsedArgs['input-linked'] as List<String>).map(toUri).toList();

  List<Uri> summaryInputs =
      (parsedArgs['input-summary'] as List<String>).map(toUri).toList();

  fe.InitializedCompilerState state;
  bool usingIncrementalCompiler = parsedArgs['use-incremental-compiler'];
  bool recordUsedInputs = parsedArgs["used-inputs"] != null;
  bool usingNullEnvironment = parsedArgs['null-environment'];
  Map<String, String>? nullableEnvironmentDefines;
  var environmentDefines = _parseEnvironmentDefines(parsedArgs['define']);
  if (usingNullEnvironment) {
    if (environmentDefines.isNotEmpty) {
      throw ArgumentError('`--null-environment` not supported with defines.');
    } else if (!target.constantsBackend.supportsUnevaluatedConstants) {
      throw ArgumentError(
          '`--null-environment` not supported on `$targetName`.');
    } else if (usingIncrementalCompiler) {
      throw ArgumentError(
          '`--null-environment` not supported with incremental compilation.');
    }
  } else {
    nullableEnvironmentDefines = environmentDefines;
  }
  var verbose = parsedArgs['verbose'] as bool;
  var verbosity = fe.Verbosity.parseArgument(parsedArgs['verbosity']);
  Uri? sdkSummaryUri = toUriNullable(parsedArgs['dart-sdk-summary']);

  Map<Uri, Uri> redirectsToFrom = {};
  for (String redirect in parsedArgs['redirect']) {
    List<String> split = redirect.split("|");
    if (split.length != 2) throw "Invalid redirect input: '$redirect'";
    redirectsToFrom[toUri(split[1])] = toUri(split[0]);
  }

  if (redirectsToFrom.isNotEmpty) {
    // If redirecting from a->b and we were asked to compile b, we want
    // the output to look like we compiled a.
    List<Uri> newSources = [];
    for (Uri source in sources) {
      newSources.add(redirectsToFrom[source] ?? source);
    }
    // Dart2jsSummaryTarget and DevCompilerSummaryTarget has a pointer to
    // sources, so to keep it up to date we'll clear and add instead of
    // overwriting.
    sources.clear();
    sources.addAll(newSources);

    // Make the filesystem map from a to b, so that if asked to read a,
    // actually return data from b. If asked to read b throw.
    fe.InitializedCompilerState helper = fe.initializeCompiler(
        null,
        sdkSummaryUri,
        toUriNullable(parsedArgs['libraries-file']),
        toUriNullable(parsedArgs['packages-file']),
        [...summaryInputs, ...linkedInputs],
        target,
        fileSystem,
        parsedArgs['enable-experiment'] as List<String>,
        nullableEnvironmentDefines,
        verbose: verbose,
        nnbdMode: nnbdMode);
    var uriTranslator = await helper.processedOpts.getUriTranslator();
    _FakeFileSystem ffs = fileSystem = _FakeFileSystem(fileSystem);
    for (MapEntry<Uri, Uri> entry in redirectsToFrom.entries) {
      ffs.addRedirect(
          uriTranslator.translate(entry.value, false) ?? entry.value,
          uriTranslator.translate(entry.key, false) ?? entry.key);
    }
  }

  if (usingIncrementalCompiler) {
    // If digests weren't given and if not in worker mode, create fake data and
    // ensure we don't have a previous state (as that wouldn't be safe with
    // fake input digests).
    if (!isWorker && inputDigests.isEmpty) {
      previousState = null;
      if (sdkSummaryUri != null) {
        inputDigests[sdkSummaryUri] = const [0];
      }
      for (Uri uri in summaryInputs) {
        inputDigests[uri] = const [0];
      }
      for (Uri uri in linkedInputs) {
        inputDigests[uri] = const [0];
      }
    }

    state = await fe.initializeIncrementalCompiler(
        previousState,
        {
          "target=$targetName",
          "trackWidgetCreation=$trackWidgetCreation",
          "multiRootScheme=${mrfs.markerScheme}",
          "multiRootRoots=${mrfs.roots}",
        },
        sdkSummaryUri,
        toUriNullable(parsedArgs['packages-file']),
        toUriNullable(parsedArgs['libraries-file']),
        [...summaryInputs, ...linkedInputs],
        inputDigests,
        target,
        fileSystem,
        (parsedArgs['enable-experiment'] as List<String>),
        summaryOnly,
        nullableEnvironmentDefines!,
        trackNeededDillLibraries: recordUsedInputs,
        verbose: verbose,
        nnbdMode: nnbdMode);
  } else {
    state = fe.initializeCompiler(
        // TODO(sigmund): pass an old state once we can make use of it.
        null,
        sdkSummaryUri,
        toUriNullable(parsedArgs['libraries-file']),
        toUriNullable(parsedArgs['packages-file']),
        [...summaryInputs, ...linkedInputs],
        target,
        fileSystem,
        parsedArgs['enable-experiment'] as List<String>,
        nullableEnvironmentDefines,
        verbose: verbose,
        nnbdMode: nnbdMode);
  }

  // Either set up or reset the state for macros based on experiment status.
  // TODO(jakemac,johnniwinther): Make this a part of `initializeCompiler`,
  // if/when we want to make it more widely supported.
  var registeredMacroExecutors = <multi_executor.ExecutorFactoryToken>[];
  if (state.processedOpts.globalFeatures.macros.isEnabled) {
    enableMacros = true;
    forceEnableMacros = true;

    SerializationMode serializationMode;
    switch (parsedArgs['macro-serialization-mode']) {
      case 'json':
        serializationMode = SerializationMode.json;
        break;
      case 'bytedata':
        serializationMode = SerializationMode.byteData;
        break;
      default:
        throw ArgumentError('Unrecognized macro serialization mode '
            '${parsedArgs['macro-serialization-mode']}');
    }

    // TODO: Handle invalidation of precompiled macros.
    // TODO: Handle multiple macro libraries compiled to a single precompiled
    // kernel file.
    var macroExecutor = state.processedOpts.macroExecutor;
    var format = parsedArgs['precompiled-macro-format'];
    for (var parts in (parsedArgs['precompiled-macro'] as List<String>)
        .map((arg) => arg.split(';'))) {
      var libraries = parts
          .skip(1)
          .map(Uri.parse)
          .where((library) => !macroExecutor.libraryIsRegistered(library))
          .toSet();
      if (libraries.isEmpty) {
        continue;
      }
      var programUri = toUri(parts[0]);
      switch (format) {
        case 'kernel':
          registeredMacroExecutors.add(macroExecutor.registerExecutorFactory(
              () => isolated_executor.start(serializationMode, programUri),
              libraries));
          break;
        case 'aot':
          registeredMacroExecutors.add(macroExecutor.registerExecutorFactory(
              () => process_executor.start(
                  serializationMode,
                  process_executor.CommunicationChannel.socket,
                  programUri.toFilePath()),
              libraries));
          break;
        default:
          throw ArgumentError('Unrecognized precompiled macro format $format');
      }
    }
  } else {
    enableMacros = false;
    forceEnableMacros = false;
    await state.options.macroExecutor?.close();
    state.options.macroExecutor = null;
  }

  void onDiagnostic(fe.DiagnosticMessage message) {
    if (fe.Verbosity.shouldPrint(verbosity, message)) {
      fe.printDiagnosticMessage(message, out.writeln);
    }
    if (message.severity == fe.Severity.error) {
      succeeded = false;
    }
  }

  List<int>? kernel;
  bool wroteUsedDills = false;
  var nativeAssets = parsedArgs['native-assets'];
  Library? nativeAssetsLibrary;
  if (nativeAssets != null) {
    var nativeAssetsUri = Uri.base.resolve(nativeAssets);

    nativeAssetsLibrary =
        await NativeAssetsSynthesizer.synthesizeLibraryFromYamlFile(
      nativeAssetsUri,
      ErrorDetector(),
      nonNullableByDefaultCompiledMode:
          state.options.nnbdMode == fe.NnbdMode.Strong
              ? NonNullableByDefaultCompiledMode.Strong
              : NonNullableByDefaultCompiledMode.Weak,
    );
  }

  if (usingIncrementalCompiler) {
    state.options.onDiagnostic = onDiagnostic;
    IncrementalCompilerResult incrementalCompilerResult =
        await state.incrementalCompiler!.computeDelta(
            entryPoints: sources,
            fullComponent: true,
            trackNeededDillLibraries: recordUsedInputs);
    Component incrementalComponent = incrementalCompilerResult.component;

    if (recordUsedInputs) {
      Set<Uri> usedOutlines = {};
      for (Library lib in incrementalCompilerResult.neededDillLibraries!) {
        if (lib.importUri.isScheme("dart")) continue;
        Uri? uri = state.libraryToInputDill![lib.importUri];
        if (uri == null) {
          throw StateError("Library ${lib.importUri} was recorded as used, "
              "but was not in the list of known libraries.");
        }
        usedOutlines.add(uri);
      }
      var outputUsedFile = File(parsedArgs["used-inputs"]);
      outputUsedFile.createSync(recursive: true);
      outputUsedFile.writeAsStringSync(usedOutlines.join("\n"));
      wroteUsedDills = true;
    }

    kernel = await state.incrementalCompiler!.context.runInContext((_) {
      if (summaryOnly) {
        incrementalComponent.uriToSource.clear();
        incrementalComponent.problemsAsJson = null;
        incrementalComponent.setMainMethodAndMode(
            null, true, incrementalComponent.mode);
        target.performOutlineTransformations(incrementalComponent);
        makeStable(incrementalComponent);
        return Future.value(fe.serializeComponent(incrementalComponent,
            includeSources: false, includeOffsets: false));
      }

      makeStable(incrementalComponent);
      setNativeAssetsLibrary(incrementalComponent, nativeAssetsLibrary);

      return Future.value(fe.serializeComponent(incrementalComponent,
          filter: excludeNonSources
              ? (library) =>
                  sources.contains(library.importUri) ||
                  library == nativeAssetsLibrary
              : null,
          includeOffsets: true));
    });
  } else if (summaryOnly) {
    kernel = await fe.compileSummary(state, sources, onDiagnostic,
        includeOffsets: false);
  } else {
    Component? component = await fe
        .compileComponent(state, sources, onDiagnostic, buildSummary: summary);
    if (component != null) {
      setNativeAssetsLibrary(component, nativeAssetsLibrary);
      kernel = fe.serializeComponent(component,
          filter: excludeNonSources
              ? (library) =>
                  sources.contains(library.importUri) ||
                  library == nativeAssetsLibrary
              : null,
          includeOffsets: true);
    }
  }
  state.options.onDiagnostic = null; // See http://dartbug.com/36983.

  // Unregister any macros executors so the processes can be shut down.
  // TODO(jakemac,johnniwinther): A better cleanup mechanism? Should these be
  // longer lived?
  if (state.options.macroExecutor != null &&
      registeredMacroExecutors.isNotEmpty) {
    await Future.wait(registeredMacroExecutors.map((token) =>
        state.options.macroExecutor!.unregisterExecutorFactory(token)));
  }

  if (!wroteUsedDills && recordUsedInputs) {
    // The path taken didn't record inputs used: Say we used everything.
    var outputUsedFile = File(parsedArgs["used-inputs"]);
    outputUsedFile.createSync(recursive: true);
    Set<Uri> allFiles = {...summaryInputs, ...linkedInputs};
    outputUsedFile.writeAsStringSync(allFiles.join("\n"));
    wroteUsedDills = true;
  }

  if (kernel != null) {
    var outputFile = File(parsedArgs['output']);
    outputFile.createSync(recursive: true);
    outputFile.writeAsBytesSync(kernel);
  } else {
    assert(!succeeded);
  }

  return ComputeKernelResult(succeeded, state);
}

final _nativeAssetsLibraryUri = Uri.parse('vm:ffi:native-assets');

void setNativeAssetsLibrary(
    Component component, Library? nativeAssetsLibrary) async {
  if (nativeAssetsLibrary == null) {
    return;
  }
  assert(nativeAssetsLibrary.importUri == _nativeAssetsLibraryUri);
  component.libraries
      .removeWhere((l) => l.importUri == _nativeAssetsLibraryUri);
  component.libraries.add(nativeAssetsLibrary..parent = component);
}

/// Make sure the output is stable by sorting libraries and additional exports.
void makeStable(Component c) {
  // Make sure the output is stable.
  c.libraries.sort((l1, l2) {
    return "${l1.fileUri}".compareTo("${l2.fileUri}");
  });
  c.problemsAsJson?.sort();
  c.computeCanonicalNames();
  for (Library library in c.libraries) {
    library.additionalExports.sort();
    library.problemsAsJson?.sort();
  }
}

class _FakeFileSystem extends FileSystem {
  final Map<Uri, Uri> redirectsFromTo = {};
  final Set<Uri> redirectsTo = {};
  final FileSystem fs;
  _FakeFileSystem(this.fs);

  void addRedirect(Uri from, Uri to) {
    redirectsTo.add(to);
    redirectsFromTo[from] = to;
  }

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (redirectsTo.contains(uri)) throw "$uri is a redirection target.";
    uri = redirectsFromTo[uri] ?? uri;
    return fs.entityForUri(uri);
  }
}

class DevCompilerSummaryTarget extends DevCompilerTarget with SummaryMixin {
  @override
  final List<Uri> sources;
  @override
  final bool excludeNonSources;

  DevCompilerSummaryTarget(
      this.sources, this.excludeNonSources, TargetFlags targetFlags)
      : super(targetFlags);
}

Uri? toUriNullable(String? uriString) {
  if (uriString == null) return null;
  return toUri(uriString);
}

Uri toUri(String uriString) {
  // Windows-style paths use '\', so convert them to '/' in case they've been
  // concatenated with Unix-style paths.
  return Uri.base.resolve(uriString.replaceAll("\\", "/"));
}

Map<String, String> _parseEnvironmentDefines(List<String> args) {
  var environment = <String, String>{};

  for (var arg in args) {
    var eq = arg.indexOf('=');
    if (eq <= 0) {
      var kind = eq == 0 ? 'name' : 'value';
      throw FormatException('no $kind given to -D option `$arg`');
    }
    var name = arg.substring(0, eq);
    var value = arg.substring(eq + 1);
    environment[name] = value;
  }

  return environment;
}
