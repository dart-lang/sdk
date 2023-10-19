// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cmdline;

import 'dart:async' show Future, StreamSubscription;
import 'dart:convert' show utf8, LineSplitter;
import 'dart:io' show exit, File, FileMode, Platform, stdin, stderr;
import 'dart:isolate' show Isolate;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import '../compiler_api.dart' as api;
import 'commandline_options.dart';
import 'common/ram_usage.dart';
import 'io/mapped_file.dart';
import 'options.dart' show CompilerOptions, Dart2JSStage, FeatureOptions;
import 'compiler.dart' as defaultCompiler show Compiler;
import 'source_file_provider.dart';
import 'util/command_line.dart';
import 'util/util.dart' show stackTraceFilePrefix;

const String _defaultSpecificationUri = '../../../../sdk/lib/libraries.json';
const String OUTPUT_LANGUAGE_DART = 'Dart';

/// A string to identify the revision or build.
///
/// This ID is displayed if the compiler crashes and in verbose mode, and is
/// an aid in reproducing bug reports.
///
/// The actual string is rewritten by a wrapper script when included in the sdk.
String? BUILD_ID;

/// The data passed to the [HandleOption] callback is either a single
/// string argument, or the arguments iterator for multiple arguments
/// handlers.
typedef HandleOption = void Function(String data);
typedef HandleMultiOption = void Function(Iterator<String> data);

abstract class OptionHandler<T> {
  String get pattern;
  void handle(T argument);
}

class _OneOption implements OptionHandler<String> {
  @override
  final String pattern;
  final HandleOption _handle;

  @override
  void handle(String argument) {
    _handle(argument);
  }

  _OneOption(this.pattern, this._handle);
}

class _ManyOptions implements OptionHandler<Iterator<String>> {
  @override
  final String pattern;
  final HandleMultiOption _handle;

  @override
  void handle(Iterator<String> argument) {
    _handle(argument);
  }

  _ManyOptions(this.pattern, this._handle);
}

/// Extract the parameter of an option.
///
/// For example, in ['--out=fisk.js'] and ['-ohest.js'], the parameters
/// are ['fisk.js'] and ['hest.js'], respectively.
String? extractOptionalParameter(String argument) {
  // m[0] is the entire match (which will be equal to argument). m[1]
  // is something like "-o" or "--out=", and m[2] is the parameter.
  final m = RegExp('^(-[a-zA-Z]|--.+=)(.*)').firstMatch(argument);
  return m?[2];
}

/// Extract the parameter of an option.
///
/// For example, in ['--out=fisk.js'] and ['-ohest.js'], the parameters
/// are ['fisk.js'] and ['hest.js'], respectively.
String extractParameter(String argument) {
  // m[0] is the entire match (which will be equal to argument). m[1]
  // is something like "-o" or "--out=", and m[2] is the parameter.
  final m = RegExp('^(-[a-zA-Z]|--.+=)(.*)').firstMatch(argument);
  if (m == null) {
    _helpAndFail('Unknown option "$argument".');
  }
  return m[2]!;
}

String extractPath(String argument, {bool isDirectory = true}) {
  String path = fe.nativeToUriPath(extractParameter(argument));
  return !path.endsWith("/") && isDirectory ? "$path/" : path;
}

void parseCommandLine(List<OptionHandler> handlers, List<String> argv) {
  // TODO(ahe): Use ../../args/args.dart for parsing options instead.
  var patterns = <String>[];
  for (OptionHandler handler in handlers) {
    patterns.add(handler.pattern);
  }
  var pattern = RegExp('^(${patterns.join(")\$|^(")})\$');

  Iterator<String> arguments = argv.iterator;
  OUTER:
  while (arguments.moveNext()) {
    String argument = arguments.current;
    final match = pattern.firstMatch(argument)!;
    assert(match.groupCount == handlers.length);
    for (int i = 0; i < handlers.length; i++) {
      if (match[i + 1] != null) {
        OptionHandler handler = handlers[i];
        if (handler is _ManyOptions) {
          handler.handle(arguments);
        } else {
          handler.handle(argument);
        }
        continue OUTER;
      }
    }
    throw 'Internal error: "$argument" did not match';
  }
}

FormattingDiagnosticHandler? diagnosticHandler;

Future<api.CompilationResult> compile(List<String> argv,
    {fe.InitializedCompilerState? kernelInitializedCompilerState}) {
  Stopwatch wallclock = Stopwatch()..start();
  stackTraceFilePrefix = '${Uri.base}';
  Uri? entryUri;
  Uri? inputDillUri;
  Uri librariesSpecificationUri = Uri.base.resolve('lib/libraries.json');
  Uri? out;
  Uri? sourceMapOut;
  List<String>? bazelPaths;
  List<Uri>? multiRoots;
  String? multiRootScheme = 'org-dartlang-app';
  Uri? packageConfig;
  List<String> options = <String>[];
  bool wantHelp = false;
  bool wantVersion = false;
  bool trustTypeAnnotations = false;
  bool checkedMode = false;
  bool strongMode = true;
  List<String> hints = <String>[];
  bool? verbose;
  bool? throwOnError;
  int? throwOnErrorCount;
  bool? showWarnings;
  bool? showHints;
  bool? enableColors;
  List<Uri>? sources;
  int? optimizationLevel;
  Uri? platformBinaries;
  Map<String, String> environment = Map<String, String>();
  FeatureOptions features = FeatureOptions();
  String? invoker;

  void passThrough(String argument) => options.add(argument);
  void ignoreOption(String argument) {}

  if (BUILD_ID != null) {
    passThrough("--build-id=$BUILD_ID");
  }

  Uri extractResolvedFileUri(String argument) {
    return Uri.base.resolve(extractPath(argument, isDirectory: false));
  }

  void setEntryUri(String argument) {
    entryUri = extractResolvedFileUri(argument);
    options.add('${Flags.entryUri}=$entryUri');
  }

  void setInputDillUri(String argument) {
    inputDillUri = extractResolvedFileUri(argument);
    options.add('${Flags.inputDill}=$inputDillUri');
  }

  void setLibrarySpecificationUri(String argument) {
    librariesSpecificationUri = extractResolvedFileUri(argument);
  }

  void setPackageConfig(String argument) {
    packageConfig = extractResolvedFileUri(argument);
  }

  void Function(String) setDataUri(String flag) {
    return (String argument) {
      final uri = fe.nativeToUri(extractPath(argument, isDirectory: false));
      options.add('$flag=$uri');
    };
  }

  void setOutput(Iterator<String> arguments) {
    String option = arguments.current;
    String path;
    if (option == '-o' || option == '--out' || option == '--output') {
      if (!arguments.moveNext()) {
        _helpAndFail("Missing file after '$option' option.");
      }
      path = arguments.current;
    } else {
      path = extractParameter(option);
    }
    out = Uri.base.resolve(fe.nativeToUriPath(path));
    options.add('--out=$out');
  }

  void setOptimizationLevel(String argument) {
    final value = int.tryParse(extractParameter(argument));
    if (value == null || value < 0 || value > 4) {
      _helpAndFail("Unsupported optimization level '$argument', "
          "supported levels are: 0, 1, 2, 3, 4");
    }
    if (optimizationLevel != null) {
      print("Optimization level '$argument' ignored "
          "due to preceding '-O$optimizationLevel'");
      return;
    }
    optimizationLevel = value;
  }

  void setOutputType(String argument) {
    if (argument == '--output-type=dart' ||
        argument == '--output-type=dart-multi') {
      _helpAndFail(
          "--output-type=dart is no longer supported. It was deprecated "
          "since Dart 1.11 and removed in Dart 1.19.");
    }
  }

  setStrip(String argument) {
    _helpAndFail("Option '--force-strip' is not in use now that"
        "--output-type=dart is no longer supported.");
  }

  void setBazelPaths(String argument) {
    String paths = extractParameter(argument);
    bazelPaths = <String>[]..addAll(paths.split(','));
  }

  void setMultiRoots(String argument) {
    String paths = extractParameter(argument);
    (multiRoots ??= <Uri>[]).addAll(paths.split(',').map(fe.nativeToUri));
  }

  void setMultiRootScheme(String argument) {
    multiRootScheme = extractParameter(argument);
  }

  String getDepsOutput(Iterable<Uri> sourceFiles) {
    var filenames = sourceFiles.map((uri) => '$uri').toList();
    filenames.sort();
    return filenames.join("\n");
  }

  void setAllowNativeExtensions(String argument) {
    _helpAndFail("Option '${Flags.allowNativeExtensions}' is not supported.");
  }

  void setVerbose(_) {
    verbose = true;
    passThrough('--verbose');
  }

  void setTrustTypeAnnotations(String argument) {
    trustTypeAnnotations = true;
  }

  void setCheckedMode(String argument) {
    checkedMode = true;
    passThrough(argument);
  }

  void addInEnvironment(Iterator<String> arguments) {
    final isDefine = arguments.current.startsWith('--define');
    String argument;
    if (arguments.current == '--define') {
      arguments.moveNext();
      argument = arguments.current;
    } else {
      argument = arguments.current.substring(isDefine ? '--define='.length : 2);
    }
    // Allow for ' ' or '=' after --define
    int eqIndex = argument.indexOf('=');
    if (eqIndex <= 0) {
      _helpAndFail('Invalid value for --define: $argument');
    }
    String name = argument.substring(0, eqIndex);
    String value = argument.substring(eqIndex + 1);
    environment[name] = value;
  }

  void setCategories(String argument) {
    List<String> categories = extractParameter(argument).split(',');
    bool isServerMode = categories.length == 1 && categories.single == "Server";
    if (isServerMode) {
      hints.add("The --categories flag is deprecated and will be deleted in a "
          "future release, please use '${Flags.serverMode}' instead of "
          "'--categories=Server'.");
      passThrough(Flags.serverMode);
    } else {
      hints.add(
          "The --categories flag is deprecated, see the usage for details.");
    }
  }

  void setPlatformBinaries(String argument) {
    platformBinaries =
        Uri.base.resolve(extractPath(argument, isDirectory: true));
  }

  List<Uri> setUriList(String flag, String argument) {
    String list = extractParameter(argument);
    List<Uri> uris = list.split(',').map(fe.nativeToUri).toList();
    String uriList = uris.map((uri) => '$uri').join(',');
    options.add('${flag}=${uriList}');
    return uris;
  }

  void setModularAnalysisInputs(String argument) {
    setUriList(Flags.readModularAnalysis, argument);
  }

  void setDillDependencies(String argument) {
    setUriList(Flags.dillDependencies, argument);
  }

  void setSources(String argument) {
    sources = setUriList(Flags.sources, argument);
  }

  void setDumpInfo(String argument) {
    passThrough(Flags.dumpInfo);
    if (argument == Flags.dumpInfo || argument == "${Flags.dumpInfo}=json") {
      return;
    }
    if (argument == "${Flags.dumpInfo}=binary") {
      passThrough(argument);
      return;
    }
    _helpAndFail("Unsupported dump-info format '$argument', "
        "supported formats are: json or binary");
  }

  String? nullSafetyMode;
  void setNullSafetyMode(String argument) {
    if (nullSafetyMode != null && nullSafetyMode != argument) {
      _helpAndFail("Cannot specify both $nullSafetyMode and $argument.");
    }
    nullSafetyMode = argument;
    passThrough(argument);
  }

  void setInvoker(String argument) {
    invoker = extractParameter(argument);
  }

  void handleThrowOnError(String argument) {
    throwOnError = true;
    final parameter = extractOptionalParameter(argument);
    if (parameter != null) {
      var count = int.parse(parameter);
      throwOnErrorCount = count;
    }
  }

  void handleShortOptions(String argument) {
    var shortOptions = argument.substring(1).split("");
    for (var shortOption in shortOptions) {
      switch (shortOption) {
        case 'v':
          setVerbose(null);
          break;
        case 'h':
        case '?':
          wantHelp = true;
          break;
        case 'c':
          setCheckedMode(Flags.enableCheckedMode);
          break;
        case 'm':
          passThrough(Flags.minify);
          break;
        default:
          throw 'Internal error: "$shortOption" did not match';
      }
    }
  }

  List<String> arguments = <String>[];
  List<OptionHandler> handlers = <OptionHandler>[
    _OneOption('${Flags.entryUri}=.+', setEntryUri),
    _OneOption('${Flags.inputDill}=.+', setInputDillUri),
    _OneOption('-[chvm?]+', handleShortOptions),
    _OneOption('--throw-on-error(?:=[0-9]+)?', handleThrowOnError),
    _OneOption(Flags.suppressWarnings, (String argument) {
      showWarnings = false;
      passThrough(argument);
    }),
    _OneOption(Flags.fatalWarnings, passThrough),
    _OneOption(Flags.suppressHints, (String argument) {
      showHints = false;
      passThrough(argument);
    }),
    // TODO(sigmund): remove entirely after Dart 1.20
    _OneOption('--output-type=dart|--output-type=dart-multi|--output-type=js',
        setOutputType),
    _OneOption('--use-kernel', ignoreOption),
    _OneOption(Flags.platformBinaries, setPlatformBinaries),
    _OneOption(Flags.noFrequencyBasedMinification, passThrough),
    _OneOption(Flags.verbose, setVerbose),
    _OneOption(Flags.progress, passThrough),
    _OneOption(Flags.reportMetrics, passThrough),
    _OneOption(Flags.reportAllMetrics, passThrough),
    _OneOption(Flags.version, (_) => wantVersion = true),
    _OneOption('--library-root=.+', ignoreOption),
    _OneOption('--libraries-spec=.+', setLibrarySpecificationUri),
    _OneOption('${Flags.dillDependencies}=.+', setDillDependencies),
    _OneOption('${Flags.sources}=.+', setSources),
    _OneOption('${Flags.readModularAnalysis}=.+', setModularAnalysisInputs),
    _OneOption('${Flags.writeModularAnalysis}=.+',
        setDataUri(Flags.writeModularAnalysis)),
    _OneOption('${Flags.readData}=.+', setDataUri(Flags.readData)),
    _OneOption('${Flags.writeData}=.+', setDataUri(Flags.writeData)),
    _OneOption(
        '${Flags.readClosedWorld}=.+', setDataUri(Flags.readClosedWorld)),
    _OneOption(
        '${Flags.writeClosedWorld}=.+', setDataUri(Flags.writeClosedWorld)),
    _OneOption('${Flags.readCodegen}=.+', setDataUri(Flags.readCodegen)),
    _OneOption('${Flags.writeCodegen}=.+', setDataUri(Flags.writeCodegen)),
    _OneOption('${Flags.codegenShard}=.+', passThrough),
    _OneOption('${Flags.codegenShards}=.+', passThrough),
    _OneOption(Flags.cfeOnly, passThrough),
    _OneOption(Flags.memoryMappedFiles, passThrough),
    _OneOption(Flags.noClosedWorldInData, ignoreOption),
    _OneOption('${Flags.stage}=.+', passThrough),
    _OneOption(Flags.debugGlobalInference, passThrough),
    _ManyOptions('--output(?:=.+)?|--out(?:=.+)?|-o.*', setOutput),
    _OneOption('-O.*', setOptimizationLevel),
    _OneOption(Flags.allowMockCompilation, ignoreOption),
    _OneOption(Flags.fastStartup, ignoreOption),
    _OneOption(Flags.genericMethodSyntax, ignoreOption),
    _OneOption(Flags.initializingFormalAccess, ignoreOption),
    _OneOption(Flags.minify, passThrough),
    _OneOption(Flags.noMinify, passThrough),
    _OneOption(Flags.omitLateNames, passThrough),
    _OneOption(Flags.noOmitLateNames, passThrough),
    _OneOption(Flags.preserveUris, ignoreOption),
    _OneOption(Flags.printLegacyStars, passThrough),
    _OneOption('--force-strip=.*', setStrip),
    _OneOption(Flags.disableDiagnosticColors, (_) {
      enableColors = false;
    }),
    _OneOption(Flags.enableDiagnosticColors, (_) {
      enableColors = true;
    }),
    _OneOption('--enable[_-]checked[_-]mode|--checked',
        (_) => setCheckedMode(Flags.enableCheckedMode)),
    _OneOption(Flags.enableAsserts, passThrough),
    _OneOption(Flags.enableNullAssertions, passThrough),
    _OneOption(Flags.nativeNullAssertions, passThrough),
    _OneOption(Flags.noNativeNullAssertions, passThrough),
    _OneOption(Flags.trustTypeAnnotations, setTrustTypeAnnotations),
    _OneOption(Flags.trustPrimitives, passThrough),
    _OneOption(Flags.trustJSInteropTypeAnnotations, ignoreOption),
    _OneOption(r'--help|/\?|/h', (_) => wantHelp = true),
    _OneOption('--packages=.+', setPackageConfig),
    _OneOption(Flags.noSourceMaps, passThrough),
    _OneOption(Option.resolutionInput, ignoreOption),
    _OneOption(Option.bazelPaths, setBazelPaths),
    _OneOption(Option.multiRoots, setMultiRoots),
    _OneOption(Option.multiRootScheme, setMultiRootScheme),
    _OneOption(Flags.resolveOnly, ignoreOption),
    _OneOption(Flags.disableNativeLiveTypeAnalysis, passThrough),
    _OneOption('--categories=.*', setCategories),
    _OneOption(Flags.serverMode, passThrough),
    _OneOption(Flags.disableInlining, passThrough),
    _OneOption(Flags.disableProgramSplit, passThrough),
    _OneOption(Flags.stopAfterProgramSplit, passThrough),
    _OneOption(Flags.disableTypeInference, passThrough),
    _OneOption(Flags.useTrivialAbstractValueDomain, passThrough),
    _OneOption(Flags.experimentalWrapped, passThrough),
    _OneOption(Flags.experimentalPowersets, passThrough),
    _OneOption(Flags.disableRtiOptimization, passThrough),
    _OneOption(Flags.terse, passThrough),
    _OneOption('--deferred-map=.+', passThrough),
    _OneOption('${Flags.deferredLoadIdMapUri}=.+',
        setDataUri(Flags.deferredLoadIdMapUri)),
    _OneOption('${Flags.writeProgramSplit}=.+', passThrough),
    _OneOption('${Flags.readProgramSplit}=.+', passThrough),
    _OneOption('${Flags.dumpInfo}|${Flags.dumpInfo}=.+', setDumpInfo),
    _OneOption(
        '${Flags.readDumpInfoData}=.+', setDataUri(Flags.readDumpInfoData)),
    _OneOption(
        '${Flags.writeDumpInfoData}=.+', setDataUri(Flags.writeDumpInfoData)),
    _OneOption('--disallow-unsafe-eval', ignoreOption),
    _OneOption(Option.showPackageWarnings, passThrough),
    _OneOption(Option.enableLanguageExperiments, passThrough),
    _OneOption('--enable-experimental-mirrors', ignoreOption),
    _OneOption(Flags.enableAssertMessage, passThrough),
    _OneOption('--strong', ignoreOption),
    _OneOption(Flags.previewDart2, ignoreOption),
    _OneOption(Flags.omitImplicitChecks, passThrough),
    _OneOption(Flags.omitAsCasts, passThrough),
    _OneOption(Flags.laxRuntimeTypeToString, passThrough),
    _OneOption(Flags.benchmarkingProduction, passThrough),
    _OneOption(Flags.benchmarkingExperiment, passThrough),
    _OneOption(Flags.soundNullSafety, setNullSafetyMode),
    _OneOption(Flags.noSoundNullSafety, setNullSafetyMode),
    _OneOption(Flags.dumpUnusedLibraries, passThrough),
    _OneOption(Flags.writeResources, passThrough),

    // TODO(floitsch): remove conditional directives flag.
    // We don't provide the info-message yet, since we haven't publicly
    // launched the feature yet.
    _OneOption(Flags.conditionalDirectives, ignoreOption),
    _OneOption('--enable-async', ignoreOption),
    _OneOption('--enable-null-aware-operators', ignoreOption),
    _OneOption('--enable-enum', ignoreOption),
    _OneOption(Flags.allowNativeExtensions, setAllowNativeExtensions),
    _OneOption(Flags.generateCodeWithCompileTimeErrors, ignoreOption),
    _OneOption(Flags.useMultiSourceInfo, passThrough),
    _OneOption(Flags.useNewSourceInfo, passThrough),
    _OneOption(Flags.useOldRti, passThrough),
    _OneOption(Flags.useSimpleLoadIds, passThrough),
    _OneOption(Flags.testMode, passThrough),
    _OneOption('${Flags.dumpSsa}=.+', passThrough),
    _OneOption('${Flags.cfeInvocationModes}=.+', passThrough),
    _OneOption('${Flags.invoker}=.+', setInvoker),
    _OneOption('${Flags.verbosity}=.+', passThrough),
    _OneOption(Flags.disableDiagnosticByteCache, passThrough),

    // Experimental features.
    // We don't provide documentation for these yet.
    // TODO(29574): provide documentation when this feature is supported.
    // TODO(29574): provide a warning/hint/error, when profile-based data is
    // used without `--fast-startup`.
    _OneOption(Flags.experimentalTrackAllocations, passThrough),

    _OneOption(Flags.experimentLocalNames, ignoreOption),
    _OneOption(Flags.experimentStartupFunctions, passThrough),
    _OneOption(Flags.experimentToBoolean, passThrough),
    _OneOption(Flags.experimentUnreachableMethodsThrow, passThrough),
    _OneOption(Flags.experimentCallInstrumentation, passThrough),
    _OneOption(Flags.experimentNullSafetyChecks, passThrough),
    _OneOption(Flags.experimentNewRti, ignoreOption),
    _OneOption('${Flags.mergeFragmentsThreshold}=.+', passThrough),

    // Wire up feature flags.
    _OneOption(Flags.canary, passThrough),
    _OneOption(Flags.noShipping, passThrough),
    // Shipped features.
    for (var feature in features.shipped)
      _OneOption('--${feature.flag}', passThrough),
    for (var feature in features.shipped)
      _OneOption('--no-${feature.flag}', passThrough),
    // Shipping features.
    for (var feature in features.shipping)
      _OneOption('--${feature.flag}', passThrough),
    for (var feature in features.shipping)
      _OneOption('--no-${feature.flag}', passThrough),
    // Canary features.
    for (var feature in features.canary)
      _OneOption('--${feature.flag}', passThrough),
    for (var feature in features.canary)
      _OneOption('--no-${feature.flag}', passThrough),

    // The following three options must come last.
    _ManyOptions('-D.+=.*|--define=.+=.*|--define', addInEnvironment),
    _OneOption('-.*', (String argument) {
      _helpAndFail("Unknown option '$argument'.");
    }),
    _OneOption('.*', (String argument) {
      arguments.add(fe.nativeToUriPath(argument));
    })
  ];

  parseCommandLine(handlers, argv);

  if (nullSafetyMode == Flags.noSoundNullSafety && platformBinaries == null) {
    // Compiling without sound null safety is no longer allowed except in the
    // cases where an unsound platform .dill file is manually provided.
    // The unsound .dills are no longer packaged in the SDK release so any
    // compile initiated through `dart compile js --no-sound-null-safety`
    // will not find a .dill in the default location and should be prevented
    // from executing.
    _fail('the flag --no-sound-null-safety is not supported in Dart 3.\n'
        'See: https://dart.dev/null-safety.');
  }
  final diagnostic = diagnosticHandler = FormattingDiagnosticHandler();
  if (verbose != null) {
    diagnostic.verbose = verbose!;
  }
  if (throwOnError != null) {
    diagnostic.throwOnError = throwOnError!;
  }
  if (throwOnErrorCount != null) {
    diagnostic.throwOnErrorCount = throwOnErrorCount!;
  }
  if (showWarnings != null) {
    diagnostic.showWarnings = showWarnings!;
  }
  if (showHints != null) {
    diagnostic.showHints = showHints!;
  }
  if (enableColors != null) {
    diagnostic.enableColors = enableColors!;
  }

  if (checkedMode && strongMode) {
    checkedMode = false;
    hints.add("Option '${Flags.enableCheckedMode}' is not needed in Dart 2.0. "
        "To enable assertions use '${Flags.enableAsserts}' instead.");
  }

  if (trustTypeAnnotations && strongMode) {
    hints.add("Option '${Flags.trustTypeAnnotations}' is not available "
        "in Dart 2.0. Try using '${Flags.omitImplicitChecks}' instead.");
  }

  for (String hint in hints) {
    diagnostic.info(hint, api.Diagnostic.HINT);
  }

  if (wantHelp || wantVersion) {
    helpAndExit(wantHelp, wantVersion, diagnostic.verbose);
  }

  if (invoker == null) {
    final message = "The 'dart2js' entrypoint script is deprecated, "
        "please use 'dart compile js' instead.";
    // Aside from asking for `-h`, dart2js fails when it is invoked from its
    // snapshot directly and not using the supported workflows.  However, we
    // allow invoking dart2js from Dart sources to support the dart2js team
    // local workflows and testing.
    if (!Platform.script.path.endsWith(".dart")) {
      _fail(message);
    } else {
      warning(message);
    }
  } else if (verbose != null) {
    print("Compiler invoked from: '$invoker'");
  }

  if (arguments.isEmpty &&
      entryUri == null &&
      inputDillUri == null &&
      sources == null) {
    _helpAndFail('No Dart file specified.');
  }

  if (arguments.length > 1) {
    var extra = arguments.sublist(1);
    _helpAndFail('Extra arguments: ${extra.join(" ")}');
  }

  if (trustTypeAnnotations && checkedMode) {
    _helpAndFail("Option '${Flags.trustTypeAnnotations}' may not be used in "
        "checked mode.");
  }

  if (arguments.isNotEmpty) {
    String sourceOrDill = arguments[0];
    Uri file = Uri.base.resolve(fe.nativeToUriPath(sourceOrDill));
    if (sourceOrDill.endsWith('.dart')) {
      options.add('${Flags.entryUri}=$file');
      entryUri = file;
    } else {
      assert(sourceOrDill.endsWith('.dill'));
      options.add('${Flags.inputDill}=$file');
      inputDillUri = file;
    }
  }

  // Make [scriptName] a relative path.
  String scriptName = sources == null
      ? fe.relativizeUri(
          Uri.base, inputDillUri ?? entryUri!, Platform.isWindows)
      : sources!
          .map((uri) => fe.relativizeUri(Uri.base, uri, Platform.isWindows))
          .join(',');

  CompilerOptions compilerOptions = CompilerOptions.parse(options,
      featureOptions: features,
      librariesSpecificationUri: librariesSpecificationUri,
      platformBinaries: platformBinaries,
      useDefaultOutputUri: true,
      onError: (String message) => _fail(message),
      onWarning: (String message) => print(message))
    ..packageConfig = packageConfig
    ..environment = environment
    ..kernelInitializedCompilerState = kernelInitializedCompilerState
    ..optimizationLevel = optimizationLevel;

  final errorMessage = compilerOptions.validateStage();
  if (errorMessage != null) {
    _fail(errorMessage);
  }

  out = compilerOptions.setResolvedOutputUri();

  if (compilerOptions.stage.emitsJs) {
    sourceMapOut = Uri.parse('$out.map');
    compilerOptions.sourceMapUri ??= sourceMapOut;
  }

  // TODO(johnniwinther): Measure time for reading files.
  SourceFileByteReader byteReader = compilerOptions.memoryMappedFiles
      ? const MemoryMapSourceFileByteReader()
      : const MemoryCopySourceFileByteReader();

  SourceFileProvider inputProvider;
  if (bazelPaths != null) {
    if (multiRoots != null) {
      _helpAndFail(
          'The options --bazel-root and --multi-root cannot be supplied '
          'together, please choose one or the other.');
    }
    inputProvider = BazelInputProvider(bazelPaths!, byteReader,
        disableByteCache: compilerOptions.disableDiagnosticByteCache);
  } else if (multiRoots != null) {
    inputProvider = MultiRootInputProvider(
        multiRootScheme!, multiRoots!, byteReader,
        disableByteCache: compilerOptions.disableDiagnosticByteCache);
  } else {
    inputProvider = CompilerSourceFileProvider(
        byteReader: byteReader,
        disableByteCache: compilerOptions.disableDiagnosticByteCache);
  }

  diagnostic.registerFileProvider(inputProvider);

  RandomAccessFileOutputProvider outputProvider =
      RandomAccessFileOutputProvider(out, sourceMapOut,
          onInfo: diagnostic.info, onFailure: _fail);

  Future<api.CompilationResult> compilationDone(
      api.CompilationResult result) async {
    if (!result.isSuccess) {
      _fail('Compilation failed.');
    }
    if (out != null) {
      writeString(
          Uri.parse('$out.deps'), getDepsOutput(inputProvider.getSourceUris()));
    }

    String input = scriptName;
    int inputSize;
    String processName;
    String inputName;

    int outputSize;
    int? primaryOutputSize;
    String outputName;

    String? summary;
    switch (compilerOptions.stage) {
      case Dart2JSStage.all:
      case Dart2JSStage.cfe:
      case Dart2JSStage.allFromDill:
      case Dart2JSStage.cfeFromDill:
      case Dart2JSStage.modularAnalysis:
      case Dart2JSStage.modularAnalysisFromDill:
      case Dart2JSStage.closedWorld:
        final sourceCharCount =
            _formatCharacterCount(inputProvider.sourceBytesFromDill);
        inputName = 'input bytes ($sourceCharCount characters source)';
        inputSize = inputProvider.bytesRead;
        summary = 'Dart file $input ';
        break;
      case Dart2JSStage.deferredLoadIds:
        final sourceCharCount =
            _formatCharacterCount(inputProvider.sourceBytesFromDill);
        inputName = 'input bytes ($sourceCharCount characters source)';
        inputSize = inputProvider.bytesRead;
        summary = 'Dart file $input ';
        break;
      case Dart2JSStage.globalInference:
        inputName = 'bytes data';
        inputSize = inputProvider.bytesRead;
        String dataInput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataInputUriForStage(Dart2JSStage.closedWorld),
            Platform.isWindows);
        summary = 'Data files $input and $dataInput ';
        break;
      case Dart2JSStage.codegenSharded:
      case Dart2JSStage.codegenAndJsEmitter:
        inputName = 'bytes data';
        inputSize = inputProvider.bytesRead;
        String worldInput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataInputUriForStage(Dart2JSStage.closedWorld),
            Platform.isWindows);
        String dataInput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataInputUriForStage(Dart2JSStage.globalInference),
            Platform.isWindows);
        summary = 'Data files $input, $worldInput, and $dataInput ';
        break;
      case Dart2JSStage.jsEmitter:
        inputName = 'bytes data';
        inputSize = inputProvider.bytesRead;
        String worldInput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataInputUriForStage(Dart2JSStage.closedWorld),
            Platform.isWindows);
        String dataInput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataInputUriForStage(Dart2JSStage.globalInference),
            Platform.isWindows);
        String codeInput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataInputUriForStage(Dart2JSStage.codegenSharded),
            Platform.isWindows);
        summary = 'Data files $input, $worldInput, $dataInput and '
            '${codeInput}[0-${compilerOptions.codegenShards! - 1}] ';
        break;
    }

    switch (compilerOptions.stage) {
      case Dart2JSStage.all:
      case Dart2JSStage.allFromDill:
      case Dart2JSStage.jsEmitter:
      case Dart2JSStage.codegenAndJsEmitter:
        processName = 'Compiled';
        outputName = 'characters JavaScript';
        outputSize = outputProvider.totalCharactersWrittenJavaScript;
        primaryOutputSize = outputProvider.totalCharactersWrittenPrimary;
        String output = fe.relativizeUri(
            Uri.base, out ?? Uri.parse('out.js'), Platform.isWindows);
        summary += 'compiled to JavaScript: ${output}';
        break;
      case Dart2JSStage.cfe:
      case Dart2JSStage.cfeFromDill:
        processName = 'Compiled';
        outputName = 'kernel bytes';
        outputSize = outputProvider.totalDataWritten;
        String output = fe.relativizeUri(Uri.base, out!, Platform.isWindows);
        summary += 'compiled to dill: ${output}.';
        break;
      case Dart2JSStage.modularAnalysis:
      case Dart2JSStage.modularAnalysisFromDill:
        processName = 'Serialized';
        outputName = 'bytes data';
        outputSize = outputProvider.totalDataWritten;
        String output = fe.relativizeUri(Uri.base, out!, Platform.isWindows);
        String dataOutput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataOutputUriForStage(compilerOptions.stage),
            Platform.isWindows);
        summary += 'serialized to dill and data: ${output} and ${dataOutput}.';
        break;
      case Dart2JSStage.closedWorld:
        processName = 'Serialized';
        outputName = 'bytes data';
        outputSize = outputProvider.totalDataWritten;
        String output = fe.relativizeUri(Uri.base, out!, Platform.isWindows);
        String dataOutput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataOutputUriForStage(compilerOptions.stage),
            Platform.isWindows);
        summary += 'serialized to dill and data: ${output} and ${dataOutput}.';
        break;
      case Dart2JSStage.deferredLoadIds:
        processName = 'Serialized';
        outputName = 'character map';
        outputSize = outputProvider.totalCharactersWritten;
        String dataOutput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataOutputUriForStage(compilerOptions.stage),
            Platform.isWindows);
        summary += 'mapped to: ${dataOutput}.';
        break;
      case Dart2JSStage.globalInference:
        processName = 'Serialized';
        outputName = 'bytes data';
        outputSize = outputProvider.totalDataWritten;
        String dataOutput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataOutputUriForStage(compilerOptions.stage),
            Platform.isWindows);
        summary += 'serialized to data: ${dataOutput}.';
        break;
      case Dart2JSStage.codegenSharded:
        processName = 'Serialized';
        outputName = 'bytes data';
        outputSize = outputProvider.totalDataWritten;
        String codeOutput = fe.relativizeUri(
            Uri.base,
            compilerOptions.dataOutputUriForStage(compilerOptions.stage),
            Platform.isWindows);
        summary += 'serialized to codegen data: '
            '${codeOutput}${compilerOptions.codegenShard}.';
        break;
    }

    print('$processName '
        '${_formatCharacterCount(inputSize)} $inputName to '
        '${_formatCharacterCount(outputSize)} $outputName in '
        '${_formatDurationAsSeconds(wallclock.elapsed)} seconds using '
        '${await currentHeapCapacityInMb()} of memory');
    if (primaryOutputSize != null && out != null) {
      diagnostic.info('${_formatCharacterCount(primaryOutputSize)} $outputName '
          'in ${fe.relativizeUri(Uri.base, out!, Platform.isWindows)}');
    }
    if (compilerOptions.stage.emitsJs) {
      if (diagnostic.verbose) {
        print(summary);
        if (diagnostic.verbose) {
          var files = outputProvider.allOutputFiles;
          int jsCount = files.where((f) => f.endsWith('.js')).length;
          print('Emitted file $jsCount JavaScript files.');
        }
      }
    } else {
      print(summary);
    }

    return result;
  }

  return compileFunc(compilerOptions, inputProvider, diagnostic, outputProvider)
      .then(compilationDone);
}

/// Returns the non-negative integer formatted with a thousands separator.
String _formatCharacterCount(int value, [String separator = ',']) {
  String text = '$value';
  // 'Insert' separators right-to-left. Inefficient, but used just a few times.
  for (int position = text.length - 3; position > 0; position -= 3) {
    text = text.substring(0, position) + separator + text.substring(position);
  }
  return text;
}

/// Formats [duration] in seconds in fixed-point format, preferring to keep the
/// result at to below [width] characters.
String _formatDurationAsSeconds(Duration duration, [int width = 4]) {
  num seconds = duration.inMilliseconds / 1000.0;
  late String text;
  for (int digits = 3; digits >= 0; digits--) {
    text = seconds.toStringAsFixed(digits);
    if (text.length <= width) return text;
  }
  return text;
}

class AbortLeg {
  final message;
  AbortLeg(this.message);
  @override
  toString() => 'Aborted due to --throw-on-error: $message';
}

void writeString(Uri uri, String text) {
  if (!enableWriteString) return;
  if (!uri.isScheme('file')) {
    _fail('Unhandled scheme ${uri.scheme}.');
  }
  var file = (File(uri.toFilePath())..createSync(recursive: true))
      .openSync(mode: FileMode.write);
  file.writeStringSync(text);
  file.closeSync();
}

Never _fail(String message) {
  if (diagnosticHandler != null) {
    diagnosticHandler!
        .report(null, null, -1, -1, message, api.Diagnostic.ERROR);
  } else {
    print('Error: $message');
  }
  exitFunc(1);
}

Future<api.CompilationResult> compilerMain(List<String> arguments,
    {fe.InitializedCompilerState? kernelInitializedCompilerState}) async {
  if (!arguments.any((a) => a.startsWith('--libraries-spec='))) {
    Uri script = Platform.script;
    if (script.isScheme("package")) {
      script = (await Isolate.resolvePackageUri(script))!;
    }
    Uri librariesJson = script.resolve(_defaultSpecificationUri);
    arguments = <String>['--libraries-spec=${librariesJson.toFilePath()}']
      ..addAll(arguments);
  }
  return compile(arguments,
      kernelInitializedCompilerState: kernelInitializedCompilerState);
}

void help() {
  // This message should be no longer than 20 lines. The default
  // terminal size normally 80x24. Two lines are used for the prompts
  // before and after running the compiler. Another two lines may be
  // used to print an error message.
  print('''
Compile Dart to JavaScript.

Usage: dart compile js [arguments] <dart entry point>
  -h, --help      Print this usage information.
  -h -v           Show detailed information about all options.
  -o, --output    Write the output to <file name>.
  -O<0,1,2,3,4>   Set the compiler optimization level (defaults to -O1).
     -O0          No optimizations (only meant for debugging the compiler).
     -O1          Default (includes whole program analyses and inlining).
     -O2          Safe production-oriented optimizations (like minification).
     -O3          Potentially unsafe optimizations (see -h -v for details).
     -O4          More agressive unsafe optimizations (see -h -v for details).
  ''');
}

void verboseHelp() {
  print(r'''
Compile Dart to JavaScript.

Usage: dart compile js [arguments] <dart entry point>
  -h, /h, /?, --help
    Print this usage information (add -v for information about all options).

  -o <file name>, --output=<file name>
    Write the output to <file name>.

  -m, --minify
    Generate minified output.

  --enable-asserts
    Enable assertions.

  -v, --verbose
    Display verbose information.

  -D<name>=<value>, --define=<name>=<value>
    Define an environment declaration.

  --version
    Display version information.

  --packages=<path>
    Path to the package resolution configuration file, which supplies a mapping
    of package names to paths.

  --suppress-warnings
    Do not display any warnings.

  --fatal-warnings
    Treat warnings as compilation errors.

  --suppress-hints
    Do not display any hints.

  --enable-diagnostic-colors
    Add colors to diagnostic messages.

  --terse
    Emit diagnostics without suggestions for how to get rid of the diagnosed
    problems.

  --show-package-warnings
    Show warnings and hints generated from packages.

  --csp
    Disable dynamic generation of code in the generated output. This is
    necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).

  --no-source-maps
    Do not generate a source map file.

  --omit-late-names
    Do not include names of late variables in error messages. This allows
    the compiler to generate smaller code by removing late variable names from
    the generated JavaScript.

  --native-null-assertions
    Add assertions to web library APIs to ensure that non-nullable APIs do not
    return null. This is by default set to true in sound null-safety, unless
    -O3 or higher is passed.

  -O<0,1,2,3,4>
    Controls optimizations that can help reduce code-size and improve
    performance of the generated code for deployment.

    -O0
       Disables all optimizations. Equivalent to calling the compiler with these
       extra flags:
        --disable-inlining
        --disable-type-inference
        --disable-rti-optimizations


       Some optimizations cannot be disabled at this time, as we add the option
       to disable them, they will be added here as well.

    -O1
       Enables default optimizations. Equivalent to calling the compiler with no
       extra flags.

    -O2
       Enables optimizations that respect the language semantics and are safe
       for all programs. It however changes the string representation of types,
       which will no longer be consistent with the Dart VM or DDC.

       Equivalent to calling the compiler with these extra flags:
        --minify
        --lax-runtime-type-to-string
        --omit-late-names

    -O3
       Enables optimizations that respect the language semantics only on
       programs that do not ever throw any subtype of `Error`.  These
       optimizations improve the generated code, but they may cause programs to
       behave unexpectedly if this assumption is not met.  To use this
       option, we recommend that you properly test your application first
       without it, and ensure that no subtype of `Error` (such as `TypeError`)
       is ever thrown.

       Equivalent to calling the compiler with these extra flags:
         -O2
         --omit-implicit-checks

    -O4
       Enables more aggressive optimizations than -O3, but with the same
       assumptions. These optimizations are on a separate group because they
       are more susceptible to variations in input data. To use this option we
       recommend to pay special attention to test edge cases in user input.

       Equivalent to calling the compiler with these extra flags:
         -O3
         --trust-primitives

    While some of the individual optimizations and flags may change with time,
    we intend to keep the -O* flags stable. New safe optimizations may be added
    on any level, and optimizations that only work on some programs may move up
    from one level to the next (for instance, once alternative safe
    optimizations are implemented, `omit-implicit-checks` may be removed or may
    move to the O4 level).

The following individual options are included in some of the -O optimization
levels above. They help reduce the size of the generated code, but they may
cause programs to behave unexpectedly if assumptions are not met. Only turn on
these flags if you have enough test coverage to ensure they are safe to use:

  --omit-implicit-checks
    Omit implicit runtime checks, such as parameter checks and implicit
    downcasts. These checks are included by default in Dart 2.0. By
    using this flag the checks are removed, however the compiler will assume
    that all such checks were valid and may use this information for
    optimizations. Use this option only if you have enough testing to ensure
    that your program works with the checks.

  --trust-primitives
    Assume that operations on numbers, strings, and lists have valid inputs.
    This option allows the compiler to drop runtime checks for those operations.
    Note: a well-typed program is not guaranteed to have valid inputs. For
    example, an int index argument may be null or out of range.

  --lax-runtime-type-to-string
    Omits reified class type arguments when these are only needed for `toString`
    on `runtimeType`. This is useful if `runtimeType.toString()` is only used
    for debugging. Note that semantics of other uses of `.runtimeType`, for
    instance `a.runtimeType == b.runtimeType`, is not affected by this flag.

The following options are only used for compiler development and may
be removed in a future version:

  --throw-on-error
    Throw an exception if a compile-time error is detected.

  --libraries-spec=<file>
    A .json file containing the SDK libraries specification.

  --allow-mock-compilation
    Do not generate a call to main if either of the following
    libraries are used: dart:dom, dart:html dart:io.

  --disable-native-live-type-analysis
    Disable the optimization that removes unused native types from dart:html
    and related libraries.

  --server-mode
    Compile with server support. The compiler will use a library specification
    that disables dart:html but supports dart:js in conditional imports.

  --categories=<categories>
    (deprecated)
    Use '--server-mode' instead of '--categories=Server'. All other category
    values have no effect on the compiler behavior.

  --deferred-map=<file>
    Generates a json file with a mapping from each deferred import to a list of
    the part.js files that will be loaded.

  --dump-info[=<format>]
    Generates information about the generated code. 'format' can be either
    'json' or 'binary'.
    You can inspect the generated data using tools from 'package:dart2js_info'.

  --generate-code-with-compile-time-errors
    Generates output even if the program contains compile-time errors. Use the
    exit code to determine if compilation failed.

  --no-frequency-based-minification
    Experimental.  Disabled the new frequency based minifying namer and use the
    old namer instead.
'''
      .trim());
}

void helpAndExit(bool wantHelp, bool wantVersion, bool verbose) {
  if (wantVersion) {
    var version = (BUILD_ID == null) ? '<non-SDK build>' : BUILD_ID;
    print('Dart-to-JavaScript compiler (dart2js) version: $version');
  }
  if (wantHelp) {
    if (verbose) {
      verboseHelp();
    } else {
      help();
    }
  }
  exitFunc(0);
}

Never _helpAndFail(String message) {
  help();
  print('');
  _fail(message);
}

void warning(String message) {
  if (diagnosticHandler != null) {
    diagnosticHandler!
        .report(null, null, -1, -1, message, api.Diagnostic.WARNING);
  } else {
    print('Warning: $message');
  }
}

Future<void> main(List<String> arguments) async {
  // Expand `@path/to/file`
  // When running from bazel, argument of the form `@path/to/file` might be
  // provided. It needs to be replaced by reading all the contents of the
  // file and expanding them into the resulting argument list.
  //
  // TODO: Remove when internal tooling targets bazelMain instead of this.
  if (arguments.length > 0 && arguments.last.startsWith('@')) {
    var extra = _readLines(arguments.last.substring(1));
    arguments = arguments.take(arguments.length - 1).followedBy(extra).toList();
  }

  // Since the sdk/bin/dart2js script adds its own arguments in front of
  // user-supplied arguments we search for '--batch' at the end of the list.
  if (arguments.length > 0 && arguments.last == "--batch") {
    batchMain(arguments.sublist(0, arguments.length - 1));
    return;
  }
  await internalMain(arguments);
}

Future<String?> bazelMain(List<String> arguments) async {
  if (arguments.length > 0 && arguments.last.startsWith('@')) {
    var extra = _readLines(arguments.last.substring(1));
    arguments = arguments.take(arguments.length - 1).followedBy(extra).toList();
  }
  final compiler = (await internalMain(arguments)).compiler;
  if (compiler is defaultCompiler.Compiler) {
    final buffer = StringBuffer();
    compiler.collectMetrics(buffer);
    return buffer.toString();
  }
  return null;
}

/// Return all non-empty lines in a file found at [path].
Iterable<String> _readLines(String path) {
  return File(path).readAsLinesSync().where((line) => line.isNotEmpty);
}

typedef ExitFunc = Never Function(int exitCode);
typedef CompileFunc = Future<api.CompilationResult> Function(
    CompilerOptions compilerOptions,
    api.CompilerInput compilerInput,
    api.CompilerDiagnostics compilerDiagnostics,
    api.CompilerOutput compilerOutput);

ExitFunc exitFunc = exit;
CompileFunc compileFunc = api.compile;

/// If `true` a '.deps' file will be generated after compilation.
///
/// Set this to `false` in end-to-end tests to avoid generating '.deps' files.
bool enableWriteString = true;

Future<api.CompilationResult> internalMain(List<String> arguments,
    {fe.InitializedCompilerState? kernelInitializedCompilerState}) {
  Future<api.CompilationResult> onError(exception, trace) {
    // If we are already trying to exit, just continue exiting.
    if (exception == _EXIT_SIGNAL) throw exception;

    try {
      print('The compiler crashed: $exception');
    } catch (ignored) {
      print('The compiler crashed: error while printing exception');
    }

    try {
      if (trace != null) {
        print(trace);
      }
    } finally {
      exitFunc(253); // 253 is recognized as a crash by our test scripts.
    }
  }

  try {
    return compilerMain(arguments,
            kernelInitializedCompilerState: kernelInitializedCompilerState)
        .catchError(onError);
  } catch (exception, trace) {
    return onError(exception, trace);
  }
}

class _ExitSignal {
  const _ExitSignal();
}

const _EXIT_SIGNAL = _ExitSignal();

void batchMain(List<String> batchArguments) {
  int? exitCode;
  exitFunc = (errorCode) {
    // Since we only throw another part of the compiler might intercept our
    // exception and try to exit with a different code.
    if (exitCode == 0) {
      exitCode = errorCode;
    }
    throw _EXIT_SIGNAL;
  };

  var stream = stdin.transform(utf8.decoder).transform(LineSplitter());
  late StreamSubscription subscription;
  fe.InitializedCompilerState? kernelInitializedCompilerState;
  subscription = stream.listen((String? line) {
    Future.sync(() {
      subscription.pause();
      exitCode = 0;
      if (line == null) exit(0);
      List<String> testArgs = splitLine(line, windows: Platform.isWindows);

      // Ignore experiment flags given to the batch runner.
      //
      // Batch arguments are provided when the batch compiler is created, and
      // contain flags that are generally enabled for all tests. Tests
      // may have more specific flags that could conflict with the batch flags.
      // For example, the batch runner might be setup to run the non-nullable
      // experiment, but the test may enable more experiments.
      //
      // At this time we are only aware of these kind of conflicts with
      // experiment flags, so we handle those directly. Currently the test
      // runner passes experiment flags on both the batch runner and the test
      // itself, so it is safe to ignore the flag that was given to the batch
      // runner.
      List<String> args = [
        for (var arg in batchArguments)
          if (!arg.startsWith('--enable-experiment')) arg,
        ...testArgs,
      ];
      return internalMain(args,
          kernelInitializedCompilerState: kernelInitializedCompilerState);
    }).then((api.CompilationResult? result) {
      if (result != null) {
        kernelInitializedCompilerState = result.kernelInitializedCompilerState;
      }
    }).catchError((exception, trace) {
      if (!identical(exception, _EXIT_SIGNAL)) {
        exitCode = 253;
      }
    }).whenComplete(() {
      // The testing framework waits for a status line on stdout and
      // stderr before moving to the next test.
      if (exitCode == 0) {
        print(">>> TEST OK");
      } else if (exitCode == 253) {
        print(">>> TEST CRASH");
      } else {
        print(">>> TEST FAIL");
      }
      stderr.writeln(">>> EOF STDERR");
      subscription.resume();
    });
  });
}

// TODO(joshualitt): Clean up the combinatorial explosion of read strategies.
// Right now only fromClosedWorld, fromDataAndClosedWorld, and
// fromCodegenAndClosedWorldAndData are valid.
enum ReadStrategy {
  fromDart,
  fromClosedWorld,
  fromData,
  fromDataAndClosedWorld,
  fromCodegen,
  fromCodegenAndClosedWorld,
  fromCodegenAndData,
  fromCodegenAndClosedWorldAndData,
}

enum WriteStrategy {
  toKernel,
  toKernelWithModularAnalysis,
  toModularAnalysis,
  toClosedWorld,
  toData,
  toCodegen,
  toJs
}
