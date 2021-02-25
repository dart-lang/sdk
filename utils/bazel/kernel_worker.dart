// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.8

/// A tool that invokes the CFE to compute kernel summary files.
///
/// This script can be used as a command-line command or a persistent server.
/// The server is implemented using the bazel worker protocol, so it can be used
/// within bazel as is. Other tools (like pub-build and package-build) also
/// use this persistent worker via the same protocol.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:build_integration/file_system/multi_root.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/src/api_unstable/bazel_worker.dart' as fe;
import 'package:kernel/ast.dart' show Component, Library, Reference;
import 'package:kernel/target/targets.dart';
import 'package:vm/target/vm.dart';
import 'package:vm/target/flutter.dart';
import 'package:vm/target/flutter_runner.dart';
import 'package:compiler/src/kernel/dart2js_target.dart';

/// [sendPort] may be passed in when started in an isolate. If provided, it is
/// used for bazel worker communication instead of stdin/stdout.
main(List<String> args, SendPort sendPort) async {
  args = preprocessArgs(args);

  if (args.contains('--persistent_worker')) {
    if (args.length != 1) {
      throw new StateError(
          "unexpected args, expected only --persistent-worker but got: $args");
    }
    await new KernelWorker(sendPort: sendPort).run();
  } else {
    var result = await computeKernel(args);
    if (!result.succeeded) {
      exitCode = 15;
    }
  }
}

/// A bazel worker loop that can compute full or summary kernel files.
class KernelWorker extends AsyncWorkerLoop {
  fe.InitializedCompilerState previousState;

  /// If [sendPort] is provided it is used for bazel worker communication
  /// instead of stdin/stdout.
  KernelWorker({SendPort sendPort})
      : super(
            connection: sendPort == null
                ? null
                : SendPortAsyncWorkerConnection(sendPort));

  Future<WorkResponse> performRequest(WorkRequest request) async {
    var outputBuffer = new StringBuffer();
    var response = new WorkResponse()..exitCode = 0;
    try {
      fe.InitializedCompilerState previousStateToPass;
      if (request.arguments.contains("--reuse-compiler-result")) {
        previousStateToPass = previousState;
      } else {
        previousState = null;
      }
      var result = await computeKernel(request.arguments,
          isWorker: true,
          outputBuffer: outputBuffer,
          inputs: request.inputs,
          previousState: previousStateToPass);
      previousState = result.previousState;
      if (!result.succeeded) {
        response.exitCode = 15;
      }
    } catch (e, s) {
      outputBuffer.writeln(e);
      outputBuffer.writeln(s);
      response.exitCode = 15;
    }
    response.output = outputBuffer.toString();
    return response;
  }
}

/// If the last arg starts with `@`, this reads the file it points to and treats
/// each line as an additional arg.
///
/// This is how individual work request args are differentiated from startup
/// args in bazel (inidividual work request args go in that file).
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
  ..addOption('target',
      allowed: const [
        'vm',
        'flutter',
        'flutter_runner',
        'dart2js',
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
  ..addFlag('sound-null-safety', defaultsTo: false);

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
    Iterable<Input> inputs,
    fe.InitializedCompilerState previousState}) async {
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
  var sources = (parsedArgs['source'] as List<String>).map(_toUri).toList();
  var excludeNonSources = parsedArgs['exclude-non-sources'] as bool;

  var nnbdMode = parsedArgs['sound-null-safety'] as bool
      ? fe.NnbdMode.Strong
      : fe.NnbdMode.Weak;
  var summaryOnly = parsedArgs['summary-only'] as bool;
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
      (parsedArgs['input-linked'] as List<String>).map(_toUri).toList();

  List<Uri> summaryInputs =
      (parsedArgs['input-summary'] as List<String>).map(_toUri).toList();

  fe.InitializedCompilerState state;
  bool usingIncrementalCompiler = false;
  bool recordUsedInputs = parsedArgs["used-inputs"] != null;
  var environmentDefines = _parseEnvironmentDefines(parsedArgs['define']);
  var verbose = parsedArgs['verbose'] as bool;

  if (parsedArgs['use-incremental-compiler']) {
    usingIncrementalCompiler = true;

    /// Build a map of uris to digests.
    final inputDigests = <Uri, List<int>>{};
    if (inputs != null) {
      for (var input in inputs) {
        inputDigests[_toUri(input.path)] = input.digest;
      }
    }

    // If digests weren't given and if not in worker mode, create fake data and
    // ensure we don't have a previous state (as that wouldn't be safe with
    // fake input digests).
    if (!isWorker && inputDigests.isEmpty) {
      previousState = null;
      inputDigests[_toUri(parsedArgs['dart-sdk-summary'])] = const [0];
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
        _toUri(parsedArgs['dart-sdk-summary']),
        _toUri(parsedArgs['packages-file']),
        _toUri(parsedArgs['libraries-file']),
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
    state = await fe.initializeCompiler(
        // TODO(sigmund): pass an old state once we can make use of it.
        null,
        _toUri(parsedArgs['dart-sdk-summary']),
        _toUri(parsedArgs['libraries-file']),
        _toUri(parsedArgs['packages-file']),
        [...summaryInputs, ...linkedInputs],
        target,
        fileSystem,
        parsedArgs['enable-experiment'] as List<String>,
        environmentDefines,
        verbose: verbose,
        nnbdMode: nnbdMode);
  }

  void onDiagnostic(fe.DiagnosticMessage message) {
    fe.printDiagnosticMessage(message, out.writeln);
    if (message.severity == fe.Severity.error) {
      succeeded = false;
    }
  }

  List<int> kernel;
  bool wroteUsedDills = false;
  if (usingIncrementalCompiler) {
    state.options.onDiagnostic = onDiagnostic;
    Component incrementalComponent = await state.incrementalCompiler
        .computeDelta(entryPoints: sources, fullComponent: true);

    if (recordUsedInputs) {
      Set<Uri> usedOutlines = {};
      for (Library lib in state.incrementalCompiler.neededDillLibraries) {
        if (lib.importUri.scheme == "dart") continue;
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
    Component component =
        await fe.compileComponent(state, sources, onDiagnostic);
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

/// Extends the DevCompilerTarget to transform outlines to meet the requirements
/// of summaries in bazel and package-build.
///
/// Build systems like package-build may provide the same input file twice to
/// the summary worker, but only intends to have it in one output summary.  The
/// convention is that if it is listed as a source, it is intended to be part of
/// the output, if the source file was loaded as a dependency, then it was
/// already included in a different summary.  The transformation below ensures
/// that the output summary doesn't include those implicit inputs.
///
/// Note: this transformation is destructive and is only intended to be used
/// when generating summaries.
class DevCompilerSummaryTarget extends DevCompilerTarget {
  final List<Uri> sources;
  final bool excludeNonSources;

  DevCompilerSummaryTarget(
      this.sources, this.excludeNonSources, TargetFlags targetFlags)
      : super(targetFlags);

  @override
  void performOutlineTransformations(Component component) {
    super.performOutlineTransformations(component);
    if (!excludeNonSources) return;

    List<Library> libraries = new List.from(component.libraries);
    component.libraries.clear();
    Set<Uri> include = sources.toSet();
    for (var lib in libraries) {
      if (include.contains(lib.importUri)) {
        component.libraries.add(lib);
      } else {
        // Excluding the library also means that their canonical names will not
        // be computed as part of serialization, so we need to do that
        // preemtively here to avoid errors when serializing references to
        // elements of these libraries.
        component.root.getChildFromUri(lib.importUri).bindTo(lib.reference);
        lib.computeCanonicalNames();
      }
    }
  }
}

Uri _toUri(String uriString) {
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
