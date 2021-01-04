// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cmdline;

import 'dart:async' show Future;
import 'dart:convert' show utf8, LineSplitter;
import 'dart:io' show exit, File, FileMode, Platform, stdin, stderr;
import 'dart:isolate' show Isolate;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import '../compiler_new.dart' as api;
import 'commandline_options.dart';
import 'options.dart' show CompilerOptions;
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
String BUILD_ID = null;

/// The data passed to the [HandleOption] callback is either a single
/// string argument, or the arguments iterator for multiple arguments
/// handlers.
typedef void HandleOption(Null data);

class OptionHandler {
  final String pattern;
  final HandleOption _handle;
  final bool multipleArguments;

  void handle(argument) {
    (_handle as dynamic)(argument);
  }

  OptionHandler(this.pattern, this._handle, {this.multipleArguments: false});
}

/// Extract the parameter of an option.
///
/// For example, in ['--out=fisk.js'] and ['-ohest.js'], the parameters
/// are ['fisk.js'] and ['hest.js'], respectively.
String extractParameter(String argument, {bool isOptionalArgument: false}) {
  // m[0] is the entire match (which will be equal to argument). m[1]
  // is something like "-o" or "--out=", and m[2] is the parameter.
  Match m = new RegExp('^(-[a-zA-Z]|--.+=)(.*)').firstMatch(argument);
  if (m == null) {
    if (isOptionalArgument) return null;
    helpAndFail('Unknown option "$argument".');
  }
  return m[2];
}

String extractPath(String argument, {bool isDirectory: true}) {
  String path = fe.nativeToUriPath(extractParameter(argument));
  return !path.endsWith("/") && isDirectory ? "$path/" : path;
}

void parseCommandLine(List<OptionHandler> handlers, List<String> argv) {
  // TODO(ahe): Use ../../args/args.dart for parsing options instead.
  var patterns = <String>[];
  for (OptionHandler handler in handlers) {
    patterns.add(handler.pattern);
  }
  var pattern = new RegExp('^(${patterns.join(")\$|^(")})\$');

  Iterator<String> arguments = argv.iterator;
  OUTER:
  while (arguments.moveNext()) {
    String argument = arguments.current;
    Match match = pattern.firstMatch(argument);
    assert(match.groupCount == handlers.length);
    for (int i = 0; i < handlers.length; i++) {
      if (match[i + 1] != null) {
        OptionHandler handler = handlers[i];
        if (handler.multipleArguments) {
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

FormattingDiagnosticHandler diagnosticHandler;

Future<api.CompilationResult> compile(List<String> argv,
    {fe.InitializedCompilerState kernelInitializedCompilerState}) {
  Stopwatch wallclock = new Stopwatch()..start();
  stackTraceFilePrefix = '${Uri.base}';
  Uri librariesSpecificationUri = Uri.base.resolve('lib/libraries.json');
  bool outputSpecified = false;
  Uri out;
  Uri sourceMapOut;
  Uri readDataUri;
  Uri writeDataUri;
  Uri readClosedWorldUri;
  Uri writeClosedWorldUri;
  Uri readCodegenUri;
  Uri writeCodegenUri;
  int codegenShard;
  int codegenShards;
  List<String> bazelPaths;
  List<Uri> multiRoots;
  String multiRootScheme = 'org-dartlang-app';
  Uri packageConfig = null;
  List<String> options = <String>[];
  bool wantHelp = false;
  bool wantVersion = false;
  bool trustTypeAnnotations = false;
  bool checkedMode = false;
  bool strongMode = true;
  List<String> hints = <String>[];
  bool verbose;
  bool throwOnError;
  int throwOnErrorCount;
  bool showWarnings;
  bool showHints;
  bool enableColors;
  int optimizationLevel = null;
  Uri platformBinaries;
  Map<String, String> environment = new Map<String, String>();
  ReadStrategy readStrategy = ReadStrategy.fromDart;
  WriteStrategy writeStrategy = WriteStrategy.toJs;

  void passThrough(String argument) => options.add(argument);
  void ignoreOption(String argument) {}

  if (BUILD_ID != null) {
    passThrough("--build-id=$BUILD_ID");
  }

  void setLibrarySpecificationUri(String argument) {
    librariesSpecificationUri =
        Uri.base.resolve(extractPath(argument, isDirectory: false));
  }

  void setPackageConfig(String argument) {
    packageConfig = Uri.base.resolve(extractPath(argument, isDirectory: false));
  }

  void setOutput(Iterator<String> arguments) {
    outputSpecified = true;
    String path;
    if (arguments.current == '-o') {
      if (!arguments.moveNext()) {
        helpAndFail('Error: Missing file after -o option.');
      }
      path = arguments.current;
    } else {
      path = extractParameter(arguments.current);
    }
    out = Uri.base.resolve(fe.nativeToUriPath(path));
  }

  void setOptimizationLevel(String argument) {
    int value = int.tryParse(extractParameter(argument));
    if (value == null || value < 0 || value > 4) {
      helpAndFail("Error: Unsupported optimization level '$argument', "
          "supported levels are: 0, 1, 2, 3, 4");
      return;
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
      helpAndFail(
          "--output-type=dart is no longer supported. It was deprecated "
          "since Dart 1.11 and removed in Dart 1.19.");
    }
  }

  setStrip(String argument) {
    helpAndFail("Option '--force-strip' is not in use now that"
        "--output-type=dart is no longer supported.");
  }

  void setBazelPaths(String argument) {
    String paths = extractParameter(argument);
    bazelPaths = <String>[]..addAll(paths.split(','));
  }

  void setMultiRoots(String argument) {
    String paths = extractParameter(argument);
    multiRoots ??= <Uri>[];
    multiRoots.addAll(paths.split(',').map(fe.nativeToUri));
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
    helpAndFail("Option '${Flags.allowNativeExtensions}' is not supported.");
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

  void addInEnvironment(String argument) {
    int eqIndex = argument.indexOf('=');
    String name = argument.substring(2, eqIndex);
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

  void setReadData(String argument) {
    if (argument != Flags.readData) {
      readDataUri = fe.nativeToUri(extractPath(argument, isDirectory: false));
    }
    if (readStrategy != ReadStrategy.fromCodegen) {
      readStrategy = ReadStrategy.fromData;
    }
  }

  void setReadClosedWorld(String argument) {
    if (argument != Flags.readClosedWorld) {
      readClosedWorldUri =
          fe.nativeToUri(extractPath(argument, isDirectory: false));
    }
    readStrategy = ReadStrategy.fromClosedWorld;
  }

  void setDillDependencies(String argument) {
    String dependencies = extractParameter(argument);
    String uriDependencies = dependencies.splitMapJoin(',',
        onMatch: (_) => ',', onNonMatch: (p) => '${fe.nativeToUri(p)}');
    options.add('${Flags.dillDependencies}=${uriDependencies}');
  }

  void setCfeOnly(String argument) {
    if (writeStrategy == WriteStrategy.toClosedWorld) {
      fail("Cannot use ${Flags.cfeOnly} "
          "and write serialized closed world simultaneously.");
    }
    if (writeStrategy == WriteStrategy.toData) {
      fail("Cannot use ${Flags.cfeOnly} "
          "and write serialized data simultaneously.");
    }
    if (writeStrategy == WriteStrategy.toCodegen) {
      fail("Cannot use ${Flags.cfeOnly} "
          "and write serialized codegen simultaneously.");
    }
    writeStrategy = WriteStrategy.toKernel;
  }

  void setReadCodegen(String argument) {
    if (argument != Flags.readCodegen) {
      readCodegenUri =
          fe.nativeToUri(extractPath(argument, isDirectory: false));
    }
    readStrategy = ReadStrategy.fromCodegen;
  }

  void setWriteData(String argument) {
    if (writeStrategy == WriteStrategy.toKernel) {
      fail("Cannot use ${Flags.cfeOnly} "
          "and write serialized data simultaneously.");
    }
    if (writeStrategy == WriteStrategy.toClosedWorld) {
      fail("Cannot write closed world and data simultaneously.");
    }
    if (writeStrategy == WriteStrategy.toCodegen) {
      fail("Cannot write serialized data and codegen simultaneously.");
    }
    if (argument != Flags.writeData) {
      writeDataUri = fe.nativeToUri(extractPath(argument, isDirectory: false));
    }
    writeStrategy = WriteStrategy.toData;
  }

  void setWriteClosedWorld(String argument) {
    if (writeStrategy == WriteStrategy.toKernel) {
      fail("Cannot use ${Flags.cfeOnly} "
          "and write serialized data simultaneously.");
    }
    if (writeStrategy == WriteStrategy.toData) {
      fail("Cannot write both closed world and data");
    }
    if (writeStrategy == WriteStrategy.toCodegen) {
      fail("Cannot write serialized data and codegen simultaneously.");
    }
    if (argument != Flags.writeClosedWorld) {
      writeClosedWorldUri =
          fe.nativeToUri(extractPath(argument, isDirectory: false));
    }
    writeStrategy = WriteStrategy.toClosedWorld;
  }

  void setWriteCodegen(String argument) {
    if (writeStrategy == WriteStrategy.toKernel) {
      fail("Cannot use ${Flags.cfeOnly} "
          "and write serialized codegen simultaneously.");
    }
    if (writeStrategy == WriteStrategy.toClosedWorld) {
      fail("Cannot write closed world and codegen simultaneously.");
    }
    if (writeStrategy == WriteStrategy.toData) {
      fail("Cannot write serialized data and codegen data simultaneously.");
    }
    if (argument != Flags.writeCodegen) {
      writeCodegenUri =
          fe.nativeToUri(extractPath(argument, isDirectory: false));
    }
    writeStrategy = WriteStrategy.toCodegen;
  }

  void setCodegenShard(String argument) {
    codegenShard = int.parse(extractParameter(argument));
  }

  void setCodegenShards(String argument) {
    codegenShards = int.parse(extractParameter(argument));
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
    helpAndFail("Error: Unsupported dump-info format '$argument', "
        "supported formats are: json or binary");
  }

  String nullSafetyMode = null;
  void setNullSafetyMode(String argument) {
    if (nullSafetyMode != null && nullSafetyMode != argument) {
      helpAndFail("Error: cannot specify both $nullSafetyMode and $argument.");
    }
    nullSafetyMode = argument;
    passThrough(argument);
  }

  void handleThrowOnError(String argument) {
    throwOnError = true;
    String parameter = extractParameter(argument, isOptionalArgument: true);
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
    new OptionHandler('-[chvm?]+', handleShortOptions),
    new OptionHandler('--throw-on-error(?:=[0-9]+)?', handleThrowOnError),
    new OptionHandler(Flags.suppressWarnings, (String argument) {
      showWarnings = false;
      passThrough(argument);
    }),
    new OptionHandler(Flags.fatalWarnings, passThrough),
    new OptionHandler(Flags.suppressHints, (String argument) {
      showHints = false;
      passThrough(argument);
    }),
    // TODO(sigmund): remove entirely after Dart 1.20
    new OptionHandler(
        '--output-type=dart|--output-type=dart-multi|--output-type=js',
        setOutputType),
    new OptionHandler('--use-kernel', ignoreOption),
    new OptionHandler(Flags.platformBinaries, setPlatformBinaries),
    new OptionHandler(Flags.noFrequencyBasedMinification, passThrough),
    new OptionHandler(Flags.verbose, setVerbose),
    new OptionHandler(Flags.progress, passThrough),
    new OptionHandler(Flags.reportMetrics, passThrough),
    new OptionHandler(Flags.reportAllMetrics, passThrough),
    new OptionHandler(Flags.version, (_) => wantVersion = true),
    new OptionHandler('--library-root=.+', ignoreOption),
    new OptionHandler('--libraries-spec=.+', setLibrarySpecificationUri),
    new OptionHandler('${Flags.dillDependencies}=.+', setDillDependencies),
    new OptionHandler('${Flags.readData}|${Flags.readData}=.+', setReadData),
    new OptionHandler('${Flags.writeData}|${Flags.writeData}=.+', setWriteData),
    new OptionHandler('${Flags.readClosedWorld}|${Flags.readClosedWorld}=.+',
        setReadClosedWorld),
    new OptionHandler('${Flags.writeClosedWorld}|${Flags.writeClosedWorld}=.+',
        setWriteClosedWorld),
    new OptionHandler(
        '${Flags.readCodegen}|${Flags.readCodegen}=.+', setReadCodegen),
    new OptionHandler(
        '${Flags.writeCodegen}|${Flags.writeCodegen}=.+', setWriteCodegen),
    new OptionHandler('${Flags.codegenShard}=.+', setCodegenShard),
    new OptionHandler('${Flags.codegenShards}=.+', setCodegenShards),
    new OptionHandler(Flags.cfeOnly, setCfeOnly),
    new OptionHandler(Flags.debugGlobalInference, passThrough),
    new OptionHandler('--out=.+|-o.*', setOutput, multipleArguments: true),
    new OptionHandler('-O.*', setOptimizationLevel),
    new OptionHandler(Flags.allowMockCompilation, ignoreOption),
    new OptionHandler(Flags.fastStartup, ignoreOption),
    new OptionHandler(Flags.genericMethodSyntax, ignoreOption),
    new OptionHandler(Flags.initializingFormalAccess, ignoreOption),
    new OptionHandler(Flags.minify, passThrough),
    new OptionHandler(Flags.noMinify, passThrough),
    new OptionHandler(Flags.preserveUris, ignoreOption),
    new OptionHandler(Flags.printLegacyStars, passThrough),
    new OptionHandler('--force-strip=.*', setStrip),
    new OptionHandler(Flags.disableDiagnosticColors, (_) {
      enableColors = false;
    }),
    new OptionHandler(Flags.enableDiagnosticColors, (_) {
      enableColors = true;
    }),
    new OptionHandler('--enable[_-]checked[_-]mode|--checked',
        (_) => setCheckedMode(Flags.enableCheckedMode)),
    new OptionHandler(Flags.enableAsserts, passThrough),
    new OptionHandler(Flags.enableNullAssertions, passThrough),
    new OptionHandler(Flags.nativeNullAssertions, passThrough),
    new OptionHandler(Flags.noNativeNullAssertions, passThrough),
    new OptionHandler(Flags.trustTypeAnnotations, setTrustTypeAnnotations),
    new OptionHandler(Flags.trustPrimitives, passThrough),
    new OptionHandler(Flags.trustJSInteropTypeAnnotations, ignoreOption),
    new OptionHandler(r'--help|/\?|/h', (_) => wantHelp = true),
    new OptionHandler('--packages=.+', setPackageConfig),
    new OptionHandler(Flags.noSourceMaps, passThrough),
    new OptionHandler(Option.resolutionInput, ignoreOption),
    new OptionHandler(Option.bazelPaths, setBazelPaths),
    new OptionHandler(Option.multiRoots, setMultiRoots),
    new OptionHandler(Option.multiRootScheme, setMultiRootScheme),
    new OptionHandler(Flags.resolveOnly, ignoreOption),
    new OptionHandler(Flags.disableNativeLiveTypeAnalysis, passThrough),
    new OptionHandler('--categories=.*', setCategories),
    new OptionHandler(Flags.serverMode, passThrough),
    new OptionHandler(Flags.disableInlining, passThrough),
    new OptionHandler(Flags.disableProgramSplit, passThrough),
    new OptionHandler(Flags.disableTypeInference, passThrough),
    new OptionHandler(Flags.useTrivialAbstractValueDomain, passThrough),
    new OptionHandler(Flags.experimentalWrapped, passThrough),
    new OptionHandler(Flags.experimentalPowersets, passThrough),
    new OptionHandler(Flags.disableRtiOptimization, passThrough),
    new OptionHandler(Flags.terse, passThrough),
    new OptionHandler('--deferred-map=.+', passThrough),
    new OptionHandler('${Flags.dumpInfo}|${Flags.dumpInfo}=.+', setDumpInfo),
    new OptionHandler('--disallow-unsafe-eval', ignoreOption),
    new OptionHandler(Option.showPackageWarnings, passThrough),
    new OptionHandler(Option.enableLanguageExperiments, passThrough),
    new OptionHandler(Flags.useContentSecurityPolicy, passThrough),
    new OptionHandler('--enable-experimental-mirrors', ignoreOption),
    new OptionHandler(Flags.enableAssertMessage, passThrough),
    new OptionHandler('--strong', ignoreOption),
    new OptionHandler(Flags.previewDart2, ignoreOption),
    new OptionHandler(Flags.omitImplicitChecks, passThrough),
    new OptionHandler(Flags.omitAsCasts, passThrough),
    new OptionHandler(Flags.laxRuntimeTypeToString, passThrough),
    new OptionHandler(Flags.legacyJavaScript, passThrough),
    new OptionHandler(Flags.noLegacyJavaScript, passThrough),
    new OptionHandler(Flags.benchmarkingProduction, passThrough),
    new OptionHandler(Flags.benchmarkingExperiment, passThrough),
    new OptionHandler(Flags.soundNullSafety, setNullSafetyMode),
    new OptionHandler(Flags.noSoundNullSafety, setNullSafetyMode),

    // TODO(floitsch): remove conditional directives flag.
    // We don't provide the info-message yet, since we haven't publicly
    // launched the feature yet.
    new OptionHandler(Flags.conditionalDirectives, ignoreOption),
    new OptionHandler('--enable-async', ignoreOption),
    new OptionHandler('--enable-null-aware-operators', ignoreOption),
    new OptionHandler('--enable-enum', ignoreOption),
    new OptionHandler(Flags.allowNativeExtensions, setAllowNativeExtensions),
    new OptionHandler(Flags.generateCodeWithCompileTimeErrors, ignoreOption),
    new OptionHandler(Flags.useMultiSourceInfo, passThrough),
    new OptionHandler(Flags.useNewSourceInfo, passThrough),
    new OptionHandler(Flags.useOldRti, passThrough),
    new OptionHandler(Flags.testMode, passThrough),
    new OptionHandler('${Flags.dumpSsa}=.+', passThrough),

    // Experimental features.
    // We don't provide documentation for these yet.
    // TODO(29574): provide documentation when this feature is supported.
    // TODO(29574): provide a warning/hint/error, when profile-based data is
    // used without `--fast-startup`.
    new OptionHandler(Flags.experimentalTrackAllocations, passThrough),
    new OptionHandler("${Flags.experimentalAllocationsPath}=.+", passThrough),

    new OptionHandler(Flags.experimentLocalNames, ignoreOption),
    new OptionHandler(Flags.experimentStartupFunctions, passThrough),
    new OptionHandler(Flags.experimentToBoolean, passThrough),
    new OptionHandler(Flags.experimentUnreachableMethodsThrow, passThrough),
    new OptionHandler(Flags.experimentCallInstrumentation, passThrough),
    new OptionHandler(Flags.experimentNewRti, ignoreOption),
    new OptionHandler('${Flags.mergeFragmentsThreshold}=.+', passThrough),

    // The following three options must come last.
    new OptionHandler('-D.+=.*', addInEnvironment),
    new OptionHandler('-.*', (String argument) {
      helpAndFail("Unknown option '$argument'.");
    }),
    new OptionHandler('.*', (String argument) {
      arguments.add(fe.nativeToUriPath(argument));
    })
  ];

  parseCommandLine(handlers, argv);

  // TODO(johnniwinther): Measure time for reading files.
  SourceFileProvider inputProvider;
  if (bazelPaths != null) {
    if (multiRoots != null) {
      helpAndFail(
          'The options --bazel-root and --multi-root cannot be supplied '
          'together, please choose one or the other.');
    }
    inputProvider = new BazelInputProvider(bazelPaths);
  } else if (multiRoots != null) {
    inputProvider = new MultiRootInputProvider(multiRootScheme, multiRoots);
  } else {
    inputProvider = new CompilerSourceFileProvider();
  }

  diagnosticHandler = new FormattingDiagnosticHandler(inputProvider);
  if (verbose != null) {
    diagnosticHandler.verbose = verbose;
  }
  if (throwOnError != null) {
    diagnosticHandler.throwOnError = throwOnError;
  }
  if (throwOnErrorCount != null) {
    diagnosticHandler.throwOnErrorCount = throwOnErrorCount;
  }
  if (showWarnings != null) {
    diagnosticHandler.showWarnings = showWarnings;
  }
  if (showHints != null) {
    diagnosticHandler.showHints = showHints;
  }
  if (enableColors != null) {
    diagnosticHandler.enableColors = enableColors;
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
    diagnosticHandler.info(hint, api.Diagnostic.HINT);
  }

  if (wantHelp || wantVersion) {
    helpAndExit(wantHelp, wantVersion, diagnosticHandler.verbose);
  }

  if (arguments.isEmpty) {
    helpAndFail('No Dart file specified.');
  }
  if (arguments.length > 1) {
    var extra = arguments.sublist(1);
    helpAndFail('Extra arguments: ${extra.join(" ")}');
  }

  if (trustTypeAnnotations && checkedMode) {
    helpAndFail("Option '${Flags.trustTypeAnnotations}' may not be used in "
        "checked mode.");
  }

  String scriptName = arguments[0];

  switch (writeStrategy) {
    case WriteStrategy.toJs:
      out ??= Uri.base.resolve('out.js');
      break;
    case WriteStrategy.toKernel:
      out ??= Uri.base.resolve('out.dill');
      options.add(Flags.cfeOnly);
      if (readStrategy == ReadStrategy.fromClosedWorld) {
        fail("Cannot use ${Flags.cfeOnly} "
            "and read serialized closed world simultaneously.");
      } else if (readStrategy == ReadStrategy.fromData) {
        fail("Cannot use ${Flags.cfeOnly} "
            "and read serialized data simultaneously.");
      } else if (readStrategy == ReadStrategy.fromCodegen) {
        fail("Cannot use ${Flags.cfeOnly} "
            "and read serialized codegen simultaneously.");
      }
      break;
    case WriteStrategy.toClosedWorld:
      out ??= Uri.base.resolve('out.dill');
      writeClosedWorldUri ??= Uri.base.resolve('$out.world');
      options.add('${Flags.writeClosedWorld}=${writeClosedWorldUri}');
      if (readStrategy == ReadStrategy.fromClosedWorld) {
        fail("Cannot read and write serialized data simultaneously.");
      } else if (readStrategy == ReadStrategy.fromData) {
        fail("Cannot read from both closed world and data");
      } else if (readStrategy == ReadStrategy.fromCodegen) {
        fail("Cannot read serialized codegen and "
            "write serialized data simultaneously.");
      }
      break;
    case WriteStrategy.toData:
      out ??= Uri.base.resolve('out.dill');
      writeDataUri ??= Uri.base.resolve('$out.data');
      options.add('${Flags.writeData}=${writeDataUri}');
      if (readStrategy == ReadStrategy.fromData) {
        fail("Cannot read and write serialized data simultaneously.");
      } else if (readStrategy == ReadStrategy.fromCodegen) {
        fail("Cannot read serialized codegen and "
            "write serialized data simultaneously.");
      }
      break;
    case WriteStrategy.toCodegen:
      // TODO(johnniwinther): Avoid the need for an [out] value in this case or
      // use [out] to pass [writeCodegenUri].
      out ??= Uri.base.resolve('out');
      writeCodegenUri ??= Uri.base.resolve('$out.code');
      options.add('${Flags.writeCodegen}=${writeCodegenUri}');
      if (readStrategy == ReadStrategy.fromCodegen) {
        fail("Cannot read and write serialized codegen simultaneously.");
      }
      if (readStrategy != ReadStrategy.fromData) {
        fail("Can only write serialized codegen from serialized data.");
      }
      if (codegenShards == null) {
        fail("Cannot write serialized codegen without setting "
            "${Flags.codegenShards}.");
      } else if (codegenShards <= 0) {
        fail("${Flags.codegenShards} must be a positive integer.");
      }
      if (codegenShard == null) {
        fail("Cannot write serialized codegen without setting "
            "${Flags.codegenShard}.");
      } else if (codegenShard < 0 || codegenShard >= codegenShards) {
        fail("${Flags.codegenShard} must be between 0 and "
            "${Flags.codegenShards}.");
      }
      options.add('${Flags.codegenShard}=$codegenShard');
      options.add('${Flags.codegenShards}=$codegenShards');
      break;
  }
  switch (readStrategy) {
    case ReadStrategy.fromDart:
      break;
    case ReadStrategy.fromClosedWorld:
      readClosedWorldUri ??= Uri.base.resolve('$scriptName.world');
      options.add('${Flags.readClosedWorld}=${readClosedWorldUri}');
      break;
    case ReadStrategy.fromData:
      readDataUri ??= Uri.base.resolve('$scriptName.data');
      options.add('${Flags.readData}=${readDataUri}');
      break;
    case ReadStrategy.fromDataAndClosedWorld:
      readClosedWorldUri ??= Uri.base.resolve('$scriptName.world');
      options.add('${Flags.readClosedWorld}=${readClosedWorldUri}');
      readDataUri ??= Uri.base.resolve('$scriptName.data');
      options.add('${Flags.readData}=${readDataUri}');
      break;
    case ReadStrategy.fromCodegen:
      readDataUri ??= Uri.base.resolve('$scriptName.data');
      options.add('${Flags.readData}=${readDataUri}');
      readCodegenUri ??= Uri.base.resolve('$scriptName.code');
      options.add('${Flags.readCodegen}=${readCodegenUri}');
      if (codegenShards == null) {
        fail("Cannot write serialized codegen without setting "
            "${Flags.codegenShards}.");
      } else if (codegenShards <= 0) {
        fail("${Flags.codegenShards} must be a positive integer.");
      }
      options.add('${Flags.codegenShards}=$codegenShards');
      break;
    case ReadStrategy.fromCodegenAndClosedWorld:
      readClosedWorldUri ??= Uri.base.resolve('$scriptName.world');
      options.add('${Flags.readClosedWorld}=${readClosedWorldUri}');
      readDataUri ??= Uri.base.resolve('$scriptName.data');
      options.add('${Flags.readData}=${readDataUri}');
      readCodegenUri ??= Uri.base.resolve('$scriptName.code');
      options.add('${Flags.readCodegen}=${readCodegenUri}');
      if (codegenShards == null) {
        fail("Cannot write serialized codegen without setting "
            "${Flags.codegenShards}.");
      } else if (codegenShards <= 0) {
        fail("${Flags.codegenShards} must be a positive integer.");
      }
      options.add('${Flags.codegenShards}=$codegenShards');
      break;
  }
  options.add('--out=$out');
  if (writeStrategy == WriteStrategy.toJs) {
    sourceMapOut = Uri.parse('$out.map');
    options.add('--source-map=${sourceMapOut}');
  }

  RandomAccessFileOutputProvider outputProvider =
      new RandomAccessFileOutputProvider(out, sourceMapOut,
          onInfo: diagnosticHandler.info, onFailure: fail);

  api.CompilationResult compilationDone(api.CompilationResult result) {
    if (!result.isSuccess) {
      fail('Compilation failed.');
    }
    writeString(
        Uri.parse('$out.deps'), getDepsOutput(inputProvider.getSourceUris()));

    String input = fe.uriPathToNative(scriptName);
    int inputSize;
    String processName;
    String inputName;

    int outputSize;
    int primaryOutputSize;
    String outputName;

    String summary;
    switch (readStrategy) {
      case ReadStrategy.fromDart:
        inputName = 'characters Dart';
        inputSize = inputProvider.dartCharactersRead;
        summary = 'Dart file $input ';
        break;
      case ReadStrategy.fromClosedWorld:
        inputName = 'bytes data';
        inputSize = inputProvider.dartCharactersRead;
        String dataInput =
            fe.relativizeUri(Uri.base, readClosedWorldUri, Platform.isWindows);
        summary = 'Data files $input and $dataInput ';
        break;
      case ReadStrategy.fromData:
        inputName = 'bytes data';
        inputSize = inputProvider.dartCharactersRead;
        String dataInput =
            fe.relativizeUri(Uri.base, readDataUri, Platform.isWindows);
        summary = 'Data files $input and $dataInput ';
        break;
      case ReadStrategy.fromDataAndClosedWorld:
        inputName = 'bytes data';
        inputSize = inputProvider.dartCharactersRead;
        String worldInput =
            fe.relativizeUri(Uri.base, readClosedWorldUri, Platform.isWindows);
        String dataInput =
            fe.relativizeUri(Uri.base, readDataUri, Platform.isWindows);
        summary = 'Data files $input, $worldInput, and $dataInput ';
        break;
      case ReadStrategy.fromCodegen:
        inputName = 'bytes data';
        inputSize = inputProvider.dartCharactersRead;
        String dataInput =
            fe.relativizeUri(Uri.base, readDataUri, Platform.isWindows);
        String codeInput =
            fe.relativizeUri(Uri.base, readCodegenUri, Platform.isWindows);
        summary = 'Data files $input, $dataInput and '
            '${codeInput}[0-${codegenShards - 1}] ';
        break;
      case ReadStrategy.fromCodegenAndClosedWorld:
        inputName = 'bytes data';
        inputSize = inputProvider.dartCharactersRead;
        String worldInput =
            fe.relativizeUri(Uri.base, readClosedWorldUri, Platform.isWindows);
        String dataInput =
            fe.relativizeUri(Uri.base, readDataUri, Platform.isWindows);
        String codeInput =
            fe.relativizeUri(Uri.base, readCodegenUri, Platform.isWindows);
        summary = 'Data files $input, $worldInput, $dataInput and '
            '${codeInput}[0-${codegenShards - 1}] ';
        break;
    }

    switch (writeStrategy) {
      case WriteStrategy.toJs:
        processName = 'Compiled';
        outputName = 'characters JavaScript';
        outputSize = outputProvider.totalCharactersWrittenJavaScript;
        primaryOutputSize = outputProvider.totalCharactersWrittenPrimary;
        String output = fe.relativizeUri(Uri.base, out, Platform.isWindows);
        summary += 'compiled to JavaScript: ${output}';
        break;
      case WriteStrategy.toKernel:
        processName = 'Compiled';
        outputName = 'kernel bytes';
        outputSize = outputProvider.totalDataWritten;
        String output = fe.relativizeUri(Uri.base, out, Platform.isWindows);
        summary += 'compiled to dill: ${output}.';
        break;
      case WriteStrategy.toClosedWorld:
        processName = 'Serialized';
        outputName = 'bytes data';
        outputSize = outputProvider.totalDataWritten;
        String output = fe.relativizeUri(Uri.base, out, Platform.isWindows);
        String dataOutput =
            fe.relativizeUri(Uri.base, writeClosedWorldUri, Platform.isWindows);
        summary += 'serialized to dill and data: ${output} and ${dataOutput}.';
        break;
      case WriteStrategy.toData:
        processName = 'Serialized';
        outputName = 'bytes data';
        outputSize = outputProvider.totalDataWritten;
        String output = fe.relativizeUri(Uri.base, out, Platform.isWindows);
        String dataOutput =
            fe.relativizeUri(Uri.base, writeDataUri, Platform.isWindows);
        summary += 'serialized to dill and data: ${output} and ${dataOutput}.';
        break;
      case WriteStrategy.toCodegen:
        processName = 'Serialized';
        outputName = 'bytes data';
        outputSize = outputProvider.totalDataWritten;
        String codeOutput =
            fe.relativizeUri(Uri.base, writeCodegenUri, Platform.isWindows);
        summary += 'serialized to codegen data: '
            '${codeOutput}${codegenShard}.';
        break;
    }

    print('$processName '
        '${_formatCharacterCount(inputSize)} $inputName to '
        '${_formatCharacterCount(outputSize)} $outputName in '
        '${_formatDurationAsSeconds(wallclock.elapsed)} seconds');
    if (primaryOutputSize != null) {
      diagnosticHandler
          .info('${_formatCharacterCount(primaryOutputSize)} $outputName '
              'in ${fe.relativizeUri(Uri.base, out, Platform.isWindows)}');
    }
    if (writeStrategy == WriteStrategy.toJs) {
      if (outputSpecified || diagnosticHandler.verbose) {
        print(summary);
        if (diagnosticHandler.verbose) {
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

  Uri script = Uri.base.resolve(scriptName);

  diagnosticHandler.autoReadFileUri = true;
  CompilerOptions compilerOptions = CompilerOptions.parse(options,
      librariesSpecificationUri: librariesSpecificationUri,
      platformBinaries: platformBinaries,
      onError: (String message) => fail(message),
      onWarning: (String message) => print(message))
    ..entryPoint = script
    ..packageConfig = packageConfig
    ..environment = environment
    ..kernelInitializedCompilerState = kernelInitializedCompilerState
    ..optimizationLevel = optimizationLevel;
  return compileFunc(
          compilerOptions, inputProvider, diagnosticHandler, outputProvider)
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
  String text;
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
  if (uri.scheme != 'file') {
    fail('Unhandled scheme ${uri.scheme}.');
  }
  var file = new File(uri.toFilePath()).openSync(mode: FileMode.write);
  file.writeStringSync(text);
  file.closeSync();
}

void fail(String message) {
  if (diagnosticHandler != null) {
    diagnosticHandler.report(null, null, -1, -1, message, api.Diagnostic.ERROR);
  } else {
    print('Error: $message');
  }
  exitFunc(1);
}

Future<api.CompilationResult> compilerMain(List<String> arguments,
    {fe.InitializedCompilerState kernelInitializedCompilerState}) async {
  if (!arguments.any((a) => a.startsWith('--libraries-spec='))) {
    Uri script = Platform.script;
    if (script.isScheme("package")) {
      script = await Isolate.resolvePackageUri(script);
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
Usage: dart2js [options] dartfile

Compiles Dart to JavaScript.

Common options:
  -o <file> Generate the output into <file>.
  -m        Generate minified output.
  -h        Display this message (add -v for information about all options).''');
}

void verboseHelp() {
  print(r'''
Usage: dart2js [options] dartfile

Compiles Dart to JavaScript.

Supported options:
  -h, /h, /?, --help
    Display this message (add -v for information about all options).

  -o <file>, --out=<file>
    Generate the output into <file>.

  -m, --minify
    Generate minified output.

  --enable-asserts
    Enable assertions.

  -v, --verbose
    Display verbose information.

  -D<name>=<value>
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

  -O<0,1,2,3,4>
    Controls optimizations that can help reduce code-size and improve
    performance of the generated code for deployment.

    -O0
       Disables all optimizations. Equivalent to calling dart2js with these
       extra flags:
        --disable-inlining
        --disable-type-inference
        --disable-rti-optimizations


       Some optimizations cannot be dissabled at this time, as we add the option
       to disable them, they will be added here as well.

    -O1
       Enables default optimizations. Equivalent to calling dart2js with no
       extra flags.

    -O2
       Enables optimizations that respect the language semantics and are safe
       for all programs. It however changes the string representation of types,
       which will no longer be consistent with the Dart VM or DDC.

       Equivalent to calling dart2js with these extra flags:
        --minify
        --lax-runtime-type-to-string

    -O3
       Enables optimizations that respect the language semantics only on
       programs that don't ever throw any subtype of `Error`.  These
       optimizations improve the generated code, but they may cause programs to
       behave unexpectedly if this assumption is not met.  To use this
       option, we recommend that you properly test your application first
       without it, and ensure that no subtype of `Error` (such as `TypeError`)
       is ever thrown.

       Equivalent to calling dart2js with these extra flags:
         -O2
         --omit-implicit-checks

    -O4
       Enables more aggressive optimizations than -O3, but with the same
       assumptions. These optimizations are on a separate group because they
       are more susceptible to variations in input data. To use this option we
       recommend to pay special attention to test edge cases in user input.

       Equivalent to calling dart2js with these extra flags:
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
    A .json file containing the libraries specification for dart2js.

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

void helpAndFail(String message) {
  help();
  print('');
  fail(message);
}

void main(List<String> arguments) {
  // Expand `@path/to/file`
  // When running from bazel, argument of the form `@path/to/file` might be
  // provided. It needs to be replaced by reading all the contents of the
  // file and expanding them into the resulting argument list.
  //
  // TODO: Move this logic to a single place and share it among all tools.
  if (arguments.last.startsWith('@')) {
    var extra = _readLines(arguments.last.substring(1));
    arguments = arguments.take(arguments.length - 1).followedBy(extra).toList();
  }

  // Since the sdk/bin/dart2js script adds its own arguments in front of
  // user-supplied arguments we search for '--batch' at the end of the list.
  if (arguments.length > 0 && arguments.last == "--batch") {
    batchMain(arguments.sublist(0, arguments.length - 1));
    return;
  }
  internalMain(arguments);
}

/// Return all non-empty lines in a file found at [path].
Iterable<String> _readLines(String path) {
  return File(path).readAsLinesSync().where((line) => line.isNotEmpty);
}

typedef void ExitFunc(int exitCode);
typedef Future<api.CompilationResult> CompileFunc(
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
    {fe.InitializedCompilerState kernelInitializedCompilerState}) {
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
    return new Future.error(exception, trace);
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

const _EXIT_SIGNAL = const _ExitSignal();

void batchMain(List<String> batchArguments) {
  int exitCode;
  exitFunc = (errorCode) {
    // Since we only throw another part of the compiler might intercept our
    // exception and try to exit with a different code.
    if (exitCode == 0) {
      exitCode = errorCode;
    }
    throw _EXIT_SIGNAL;
  };

  var stream = stdin.transform(utf8.decoder).transform(new LineSplitter());
  var subscription;
  fe.InitializedCompilerState kernelInitializedCompilerState;
  subscription = stream.listen((line) {
    new Future.sync(() {
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
    }).catchError((exception, trace) {
      if (!identical(exception, _EXIT_SIGNAL)) {
        exitCode = 253;
      }
    }).then((api.CompilationResult result) {
      if (result != null) {
        kernelInitializedCompilerState = result.kernelInitializedCompilerState;
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

enum ReadStrategy {
  fromDart,
  fromClosedWorld,
  fromData,
  fromDataAndClosedWorld,
  fromCodegen,
  fromCodegenAndClosedWorld
}
enum WriteStrategy { toKernel, toClosedWorld, toData, toCodegen, toJs }
