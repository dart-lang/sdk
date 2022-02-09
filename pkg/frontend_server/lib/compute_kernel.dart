// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.8

/// A library to invoke the CFE to compute kernel summary files.
///
/// Used by `utils/bazel/kernel_worker.dart`.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:build_integration/file_system/multi_root.dart';
import 'package:compiler/src/kernel/dart2js_target.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/api_unstable/bazel_worker.dart' as fe;
import 'package:kernel/ast.dart' show Component, Library, Reference;
import 'package:kernel/target/targets.dart';
import 'package:vm/target/flutter.dart';
import 'package:vm/target/flutter_runner.dart';
import 'package:vm/target/vm.dart';

/// If the last arg starts with `@`, this reads the file it points to and treats
/// each line as an additional arg.
///
/// This is how individual work request args are differentiated from startup
/// args in bazel (individual work request args go in that file).
List<String> preprocessArgs(List<String> args) {
  args = new List.from(args);
  if (args.isEmpty) {
    return args;
  }
  String lastArg = args.last;
  if (lastArg.startsWith('@')) {
    File argsFile = new File(lastArg.substring(1));
    try {
      args.removeLast();
      args.addAll(argsFile.readAsLinesSync());
    } on FileSystemException catch (e) {
      throw new Exception('Failed to read file specified by $lastArg : $e');
    }
  }
  return args;
}

/// An [ArgParser] for generating kernel summaries.
final summaryArgsParser = new ArgParser()
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
        'ddc',
      ],
      help: 'Build kernel for the vm, flutter, flutter_runner, dart2js or ddc')
  ..addOption('dart-sdk-summary')
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
  ..addFlag('sound-null-safety', defaultsTo: false)
  ..addOption('verbosity',
      defaultsTo: fe.Verbosity.defaultValue,
      help: 'Sets the verbosity level used for filtering messages during '
          'compilation.',
      allowed: fe.Verbosity.allowedValues,
      allowedHelp: fe.Verbosity.allowedValuesHelp);

class ComputeKernelResult {
  final bool succeeded;
  final fe.InitializedCompilerState previousState;

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
    {bool isWorker: false,
    StringBuffer outputBuffer,
    Map<Uri, List<int>> inputDigests,
    fe.InitializedCompilerState previousState}) async {
  inputDigests ??= <Uri, List<int>>{};
  dynamic out = outputBuffer ?? stderr;
  bool succeeded = true;

  var parsedArgs = summaryArgsParser.parse(args);

  if (parsedArgs['help']) {
    out.writeln(summaryArgsParser.usage);
    if (!isWorker) exit(0);
    return new ComputeKernelResult(false, previousState);
  }

  // Bazel creates an overlay file system where some files may be located in the
  // source tree, some in a gendir, and some in a bindir. The multi-root file
  // system hides this from the front end.
  var multiRoots = parsedArgs['multi-root'].map(Uri.base.resolve).toList();
  if (multiRoots.isEmpty) multiRoots.add(Uri.base);
  var fileSystem = new MultiRootFileSystem(parsedArgs['multi-root-scheme'],
      multiRoots, fe.StandardFileSystem.instance);
  var sources = (parsedArgs['source'] as List<String>).map(toUri).toList();
  var excludeNonSources = parsedArgs['exclude-non-sources'] as bool;

  var nnbdMode = parsedArgs['sound-null-safety'] as bool
      ? fe.NnbdMode.Strong
      : fe.NnbdMode.Weak;
  var summaryOnly = parsedArgs['summary-only'] as bool;
  var summary = parsedArgs['summary'] as bool;
  if (summaryOnly && !summary) {
    throw new ArgumentError('--summary-only conflicts with --no-summary');
  }
  var trackWidgetCreation = parsedArgs['track-widget-creation'] as bool;

  // TODO(sigmund,jakemac): make target mandatory. We allow null to be backwards
  // compatible while we migrate existing clients of this tool.
  var targetName =
      (parsedArgs['target'] as String) ?? (summaryOnly ? 'ddc' : 'vm');
  var targetFlags = new TargetFlags(
      trackWidgetCreation: trackWidgetCreation,
      enableNullSafety: nnbdMode == fe.NnbdMode.Strong);
  Target target;
  switch (targetName) {
    case 'vm':
      target = new VmTarget(targetFlags);
      if (summaryOnly) {
        out.writeln('error: --summary-only not supported for the vm target');
      }
      break;
    case 'flutter':
      target = new FlutterTarget(targetFlags);
      if (summaryOnly) {
        throw new ArgumentError(
            'error: --summary-only not supported for the flutter target');
      }
      break;
    case 'flutter_runner':
      target = new FlutterRunnerTarget(targetFlags);
      if (summaryOnly) {
        throw new ArgumentError('error: --summary-only not supported for the '
            'flutter_runner target');
      }
      break;
    case 'dart2js':
      target = new Dart2jsTarget('dart2js', targetFlags);
      if (summaryOnly) {
        out.writeln(
            'error: --summary-only not supported for the dart2js target');
      }
      break;
    case 'dart2js_summary':
      target = new Dart2jsSummaryTarget(
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
          new DevCompilerSummaryTarget(sources, excludeNonSources, targetFlags);
      if (!summaryOnly) {
        out.writeln('error: --no-summary-only not supported for the '
            'ddc target');
      }
      break;
    default:
      out.writeln('error: unsupported target: $targetName');
  }

  List<Uri> linkedInputs =
      (parsedArgs['input-linked'] as List<String>).map(toUri).toList();

  List<Uri> summaryInputs =
      (parsedArgs['input-summary'] as List<String>).map(toUri).toList();

  fe.InitializedCompilerState state;
  bool usingIncrementalCompiler = false;
  bool recordUsedInputs = parsedArgs["used-inputs"] != null;
  var environmentDefines = _parseEnvironmentDefines(parsedArgs['define']);
  var verbose = parsedArgs['verbose'] as bool;
  var verbosity = fe.Verbosity.parseArgument(parsedArgs['verbosity']);

  if (parsedArgs['use-incremental-compiler']) {
    usingIncrementalCompiler = true;

    // If digests weren't given and if not in worker mode, create fake data and
    // ensure we don't have a previous state (as that wouldn't be safe with
    // fake input digests).
    if (!isWorker && inputDigests.isEmpty) {
      previousState = null;
      inputDigests[toUri(parsedArgs['dart-sdk-summary'])] = const [0];
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
          "multiRootScheme=${fileSystem.markerScheme}",
          "multiRootRoots=${fileSystem.roots}",
        },
        toUri(parsedArgs['dart-sdk-summary']),
        toUri(parsedArgs['packages-file']),
        toUri(parsedArgs['libraries-file']),
        [...summaryInputs, ...linkedInputs],
        inputDigests,
        target,
        fileSystem,
        (parsedArgs['enable-experiment'] as List<String>),
        summaryOnly,
        environmentDefines,
        trackNeededDillLibraries: recordUsedInputs,
        verbose: verbose,
        nnbdMode: nnbdMode);
  } else {
    state = fe.initializeCompiler(
        // TODO(sigmund): pass an old state once we can make use of it.
        null,
        toUri(parsedArgs['dart-sdk-summary']),
        toUri(parsedArgs['libraries-file']),
        toUri(parsedArgs['packages-file']),
        [...summaryInputs, ...linkedInputs],
        target,
        fileSystem,
        parsedArgs['enable-experiment'] as List<String>,
        environmentDefines,
        verbose: verbose,
        nnbdMode: nnbdMode);
  }

  void onDiagnostic(fe.DiagnosticMessage message) {
    if (fe.Verbosity.shouldPrint(verbosity, message)) {
      fe.printDiagnosticMessage(message, out.writeln);
    }
    if (message.severity == fe.Severity.error) {
      succeeded = false;
    }
  }

  List<int> kernel;
  bool wroteUsedDills = false;
  if (usingIncrementalCompiler) {
    state.options.onDiagnostic = onDiagnostic;
    IncrementalCompilerResult incrementalCompilerResult =
        await state.incrementalCompiler.computeDelta(
            entryPoints: sources,
            fullComponent: true,
            trackNeededDillLibraries: recordUsedInputs);
    Component incrementalComponent = incrementalCompilerResult.component;

    if (recordUsedInputs) {
      Set<Uri> usedOutlines = {};
      for (Library lib in incrementalCompilerResult.neededDillLibraries) {
        if (lib.importUri.isScheme("dart")) continue;
        Uri uri = state.libraryToInputDill[lib.importUri];
        if (uri == null) {
          throw new StateError("Library ${lib.importUri} was recorded as used, "
              "but was not in the list of known libraries.");
        }
        usedOutlines.add(uri);
      }
      var outputUsedFile = new File(parsedArgs["used-inputs"]);
      outputUsedFile.createSync(recursive: true);
      outputUsedFile.writeAsStringSync(usedOutlines.join("\n"));
      wroteUsedDills = true;
    }

    kernel = await state.incrementalCompiler.context.runInContext((_) {
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

      return Future.value(fe.serializeComponent(incrementalComponent,
          filter: excludeNonSources
              ? (library) => sources.contains(library.importUri)
              : null,
          includeOffsets: true));
    });
  } else if (summaryOnly) {
    kernel = await fe.compileSummary(state, sources, onDiagnostic,
        includeOffsets: false);
  } else {
    Component component = await fe
        .compileComponent(state, sources, onDiagnostic, buildSummary: summary);
    kernel = fe.serializeComponent(component,
        filter: excludeNonSources
            ? (library) => sources.contains(library.importUri)
            : null,
        includeOffsets: true);
  }
  state.options.onDiagnostic = null; // See http://dartbug.com/36983.

  if (!wroteUsedDills && recordUsedInputs) {
    // The path taken didn't record inputs used: Say we used everything.
    var outputUsedFile = new File(parsedArgs["used-inputs"]);
    outputUsedFile.createSync(recursive: true);
    Set<Uri> allFiles = {...summaryInputs, ...linkedInputs};
    outputUsedFile.writeAsStringSync(allFiles.join("\n"));
    wroteUsedDills = true;
  }

  if (kernel != null) {
    var outputFile = new File(parsedArgs['output']);
    outputFile.createSync(recursive: true);
    outputFile.writeAsBytesSync(kernel);
  } else {
    assert(!succeeded);
  }

  return new ComputeKernelResult(succeeded, state);
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
    library.additionalExports.sort((Reference r1, Reference r2) {
      return "${r1.canonicalName}".compareTo("${r2.canonicalName}");
    });
    library.problemsAsJson?.sort();
  }
}

class DevCompilerSummaryTarget extends DevCompilerTarget with SummaryMixin {
  final List<Uri> sources;
  final bool excludeNonSources;

  DevCompilerSummaryTarget(
      this.sources, this.excludeNonSources, TargetFlags targetFlags)
      : super(targetFlags);
}

Uri toUri(String uriString) {
  if (uriString == null) return null;
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
