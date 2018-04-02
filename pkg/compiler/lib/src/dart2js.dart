// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cmdline;

import 'dart:async' show Future;
import 'dart:convert' show UTF8, LineSplitter;
import 'dart:io' show exit, File, FileMode, Platform, stdin, stderr;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:package_config/discovery.dart' show findPackages;

import '../compiler_new.dart' as api;
import 'commandline_options.dart';
import 'common/names.dart' show Uris;
import 'filenames.dart';
import 'io/source_file.dart';
import 'null_compiler_output.dart';
import 'options.dart' show CompilerOptions;
import 'source_file_provider.dart';
import 'util/command_line.dart';
import 'util/uri_extras.dart';
import 'util/util.dart' show stackTraceFilePrefix;

const String LIBRARY_ROOT = '../../../../../sdk';
const String OUTPUT_LANGUAGE_DART = 'Dart';

/**
 * A string to identify the revision or build.
 *
 * This ID is displayed if the compiler crashes and in verbose mode, and is
 * an aid in reproducing bug reports.
 *
 * The actual string is rewritten by a wrapper script when included in the sdk.
 */
String BUILD_ID = null;

/**
 * The data passed to the [HandleOption] callback is either a single
 * string argument, or the arguments iterator for multiple arguments
 * handlers.
 */
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

/**
 * Extract the parameter of an option.
 *
 * For example, in ['--out=fisk.js'] and ['-ohest.js'], the parameters
 * are ['fisk.js'] and ['hest.js'], respectively.
 */
String extractParameter(String argument, {bool isOptionalArgument: false}) {
  // m[0] is the entire match (which will be equal to argument). m[1]
  // is something like "-o" or "--out=", and m[2] is the parameter.
  Match m = new RegExp('^(-[a-z]|--.+=)(.*)').firstMatch(argument);
  if (m == null) {
    if (isOptionalArgument) return null;
    helpAndFail('Unknown option "$argument".');
  }
  return m[2];
}

String extractPath(String argument, {bool isDirectory: true}) {
  String path = nativeToUriPath(extractParameter(argument));
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
  stackTraceFilePrefix = '$currentDirectory';
  Uri libraryRoot = currentDirectory;
  bool outputSpecified = false;
  Uri out = currentDirectory.resolve('out.js');
  Uri sourceMapOut = currentDirectory.resolve('out.js.map');
  List<String> bazelPaths;
  Uri packageConfig = null;
  Uri packageRoot = null;
  List<String> options = new List<String>();
  bool wantHelp = false;
  bool wantVersion = false;
  bool analyzeOnly = false;
  bool trustTypeAnnotations = false;
  bool checkedMode = false;
  bool strongMode = false;
  List<String> hints = <String>[];
  bool verbose;
  bool throwOnError;
  int throwOnErrorCount;
  bool showWarnings;
  bool showHints;
  bool enableColors;
  bool useKernel = true;
  Uri platformBinaries = computePlatformBinariesLocation();
  Map<String, dynamic> environment = new Map<String, dynamic>();

  void passThrough(String argument) => options.add(argument);
  void ignoreOption(String argument) {}

  if (BUILD_ID != null) {
    passThrough("--build-id=$BUILD_ID");
  }

  void setLibraryRoot(String argument) {
    libraryRoot = currentDirectory.resolve(extractPath(argument));
  }

  void setPackageRoot(String argument) {
    packageRoot = currentDirectory.resolve(extractPath(argument));
  }

  void setPackageConfig(String argument) {
    packageConfig =
        currentDirectory.resolve(extractPath(argument, isDirectory: false));
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
    out = currentDirectory.resolve(nativeToUriPath(path));
    sourceMapOut = Uri.parse('$out.map');
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

  String getDepsOutput(Iterable<Uri> sourceFiles) {
    var filenames = sourceFiles.map((uri) => '$uri').toList();
    filenames.sort();
    return filenames.join("\n");
  }

  void setAnalyzeOnly(String argument) {
    analyzeOnly = true;
    passThrough(argument);
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
    passThrough(argument);
  }

  void setCheckedMode(String argument) {
    checkedMode = true;
    passThrough(argument);
  }

  void setStrongMode(_) {
    strongMode = true;
    passThrough(Flags.strongMode);
  }

  void addInEnvironment(String argument) {
    int eqIndex = argument.indexOf('=');
    String name = argument.substring(2, eqIndex);
    String value = argument.substring(eqIndex + 1);
    environment[name] = value;
  }

  void setCategories(String argument) {
    List<String> categories = extractParameter(argument).split(',');
    if (categories.contains('all')) {
      categories = ["Client", "Server"];
    } else {
      for (String category in categories) {
        if (!["Client", "Server"].contains(category)) {
          fail('Unsupported library category "$category", '
              'supported categories are: Client, Server, all');
        }
      }
    }
    passThrough('--categories=${categories.join(",")}');
  }

  void setUseOldFrontend(String argument) {
    useKernel = false;
    passThrough(argument);
  }

  void setPlatformBinaries(String argument) {
    platformBinaries =
        currentDirectory.resolve(extractPath(argument, isDirectory: true));
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
    new OptionHandler(Flags.useKernel, ignoreOption),
    new OptionHandler(Flags.useOldFrontend, setUseOldFrontend),
    new OptionHandler(Flags.platformBinaries, setPlatformBinaries),
    new OptionHandler(Flags.noFrequencyBasedMinification, passThrough),
    new OptionHandler(Flags.verbose, setVerbose),
    new OptionHandler(Flags.version, (_) => wantVersion = true),
    new OptionHandler('--library-root=.+', setLibraryRoot),
    new OptionHandler('--out=.+|-o.*', setOutput, multipleArguments: true),
    new OptionHandler(Flags.allowMockCompilation, ignoreOption),
    new OptionHandler(Flags.fastStartup, passThrough),
    new OptionHandler(Flags.genericMethodSyntax, ignoreOption),
    new OptionHandler(Flags.syncAsync, passThrough),
    new OptionHandler(Flags.initializingFormalAccess, ignoreOption),
    new OptionHandler(Flags.minify, passThrough),
    new OptionHandler(Flags.preserveUris, ignoreOption),
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
    new OptionHandler(Flags.trustTypeAnnotations, setTrustTypeAnnotations),
    new OptionHandler(Flags.trustPrimitives, passThrough),
    new OptionHandler(Flags.trustJSInteropTypeAnnotations, passThrough),
    new OptionHandler(r'--help|/\?|/h', (_) => wantHelp = true),
    new OptionHandler('--packages=.+', setPackageConfig),
    new OptionHandler('--package-root=.+|-p.+', setPackageRoot),
    new OptionHandler(Flags.analyzeAll, passThrough),
    new OptionHandler(Flags.analyzeOnly, setAnalyzeOnly),
    new OptionHandler(Flags.noSourceMaps, passThrough),
    new OptionHandler(Option.resolutionInput, ignoreOption),
    new OptionHandler(Option.bazelPaths, setBazelPaths),
    new OptionHandler(Flags.resolveOnly, ignoreOption),
    new OptionHandler(Flags.analyzeSignaturesOnly, setAnalyzeOnly),
    new OptionHandler(Flags.disableNativeLiveTypeAnalysis, passThrough),
    new OptionHandler('--categories=.*', setCategories),
    new OptionHandler(Flags.disableInlining, passThrough),
    new OptionHandler(Flags.disableProgramSplit, passThrough),
    new OptionHandler(Flags.disableTypeInference, passThrough),
    new OptionHandler(Flags.disableRtiOptimization, passThrough),
    new OptionHandler(Flags.terse, passThrough),
    new OptionHandler('--deferred-map=.+', passThrough),
    new OptionHandler(Flags.dumpInfo, passThrough),
    new OptionHandler('--disallow-unsafe-eval', ignoreOption),
    new OptionHandler(Option.showPackageWarnings, passThrough),
    new OptionHandler(Flags.useContentSecurityPolicy, passThrough),
    new OptionHandler(Flags.enableExperimentalMirrors, passThrough),
    new OptionHandler(Flags.enableAssertMessage, passThrough),
    new OptionHandler(Flags.strongMode, setStrongMode),
    new OptionHandler(Flags.previewDart2, setStrongMode),
    new OptionHandler(Flags.omitImplicitChecks, passThrough),

    // TODO(floitsch): remove conditional directives flag.
    // We don't provide the info-message yet, since we haven't publicly
    // launched the feature yet.
    new OptionHandler(Flags.conditionalDirectives, ignoreOption),
    new OptionHandler('--enable-async', ignoreOption),
    new OptionHandler('--enable-null-aware-operators', ignoreOption),
    new OptionHandler('--enable-enum', ignoreOption),
    new OptionHandler(Flags.allowNativeExtensions, setAllowNativeExtensions),
    new OptionHandler(Flags.generateCodeWithCompileTimeErrors, passThrough),
    new OptionHandler(Flags.useMultiSourceInfo, passThrough),
    new OptionHandler(Flags.useNewSourceInfo, passThrough),
    new OptionHandler(Flags.testMode, passThrough),

    // Experimental features.
    // We don't provide documentation for these yet.
    // TODO(29574): provide documentation when this feature is supported.
    // TODO(29574): provide a warning/hint/error, when profile-based data is
    // used without `--fast-startup`.
    new OptionHandler(Flags.experimentalTrackAllocations, passThrough),
    new OptionHandler("${Flags.experimentalAllocationsPath}=.+", passThrough),

    // The following three options must come last.
    new OptionHandler('-D.+=.*', addInEnvironment),
    new OptionHandler('-.*', (String argument) {
      helpAndFail("Unknown option '$argument'.");
    }),
    new OptionHandler('.*', (String argument) {
      arguments.add(nativeToUriPath(argument));
    })
  ];

  parseCommandLine(handlers, argv);

  // TODO(johnniwinther): Measure time for reading files.
  SourceFileProvider inputProvider;
  if (bazelPaths != null) {
    inputProvider = new BazelInputProvider(bazelPaths);
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

  if (trustTypeAnnotations) {
    if (checkedMode) {
      helpAndFail("Option '${Flags.trustTypeAnnotations}' may not be used in "
          "checked mode.");
    } else if (strongMode) {
      hints.add("Option '--trust-type-annotations' is not available "
          "in strong mode. Try usign '--omit-implicit-checks' instead.");
    }
  }

  if (packageRoot != null && packageConfig != null) {
    helpAndFail("Cannot specify both '--package-root' and '--packages.");
  }

  options.add('--out=$out');
  options.add('--source-map=$sourceMapOut');

  RandomAccessFileOutputProvider outputProvider =
      new RandomAccessFileOutputProvider(out, sourceMapOut,
          onInfo: diagnosticHandler.info, onFailure: fail);

  api.CompilationResult compilationDone(api.CompilationResult result) {
    if (analyzeOnly) return result;
    if (!result.isSuccess) {
      fail('Compilation failed.');
    }
    writeString(
        Uri.parse('$out.deps'), getDepsOutput(inputProvider.getSourceUris()));
    int dartCharactersRead = inputProvider.dartCharactersRead;
    int jsCharactersWritten = outputProvider.totalCharactersWrittenJavaScript;
    int jsCharactersPrimary = outputProvider.totalCharactersWrittenPrimary;

    print('Compiled '
        '${_formatCharacterCount(dartCharactersRead)} characters Dart'
        ' to '
        '${_formatCharacterCount(jsCharactersWritten)} characters JavaScript'
        ' in '
        '${_formatDurationAsSeconds(wallclock.elapsed)} seconds');

    diagnosticHandler.info(
        '${_formatCharacterCount(jsCharactersPrimary)} characters JavaScript'
        ' in '
        '${relativize(currentDirectory, out, Platform.isWindows)}');
    if (diagnosticHandler.verbose) {
      String input = uriPathToNative(arguments[0]);
      print('Dart file ($input) compiled to JavaScript.');
      print('Wrote the following files:');
      for (String filename in outputProvider.allOutputFiles) {
        print("  $filename");
      }
    } else if (outputSpecified) {
      String input = uriPathToNative(arguments[0]);
      String output = relativize(currentDirectory, out, Platform.isWindows);
      print('Dart file ($input) compiled to JavaScript: $output');
    }
    return result;
  }

  Uri script = currentDirectory.resolve(arguments[0]);
  if (useKernel) {
    diagnosticHandler.autoReadFileUri = true;
    // TODO(sigmund): reenable hints (Issue #32111)
    diagnosticHandler.showHints = showHints = false;
  }
  CompilerOptions compilerOptions = CompilerOptions.parse(options,
      libraryRoot: libraryRoot, platformBinaries: platformBinaries)
    ..entryPoint = script
    ..packageRoot = packageRoot
    ..packageConfig = packageConfig
    ..environment = environment
    ..packagesDiscoveryProvider = findPackages
    ..kernelInitializedCompilerState = kernelInitializedCompilerState;
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
  toString() => 'Aborted due to --throw-on-error: $message';
}

void writeString(Uri uri, String text) {
  if (!enableWriteString) return;
  if (uri.scheme != 'file') {
    fail('Unhandled scheme ${uri.scheme}.');
  }
  var file = new File(uri.toFilePath()).openSync(mode: FileMode.WRITE);
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
    {fe.InitializedCompilerState kernelInitializedCompilerState}) {
  var root = uriPathToNative("/$LIBRARY_ROOT");
  arguments = <String>['--library-root=${Platform.script.toFilePath()}$root']
    ..addAll(arguments);
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
  -c        Insert runtime type checks and enable assertions (checked mode).
  -m        Generate minified output.
  -h        Display this message (add -v for information about all options).''');
}

void verboseHelp() {
  print(r'''
Usage: dart2js [options] dartfile

Compiles Dart to JavaScript.

Supported options:
  -o <file>, --out=<file>
    Generate the output into <file>.

  -m, --minify
    Generate minified output.

  --enable-asserts
    Enable assertions.

  -h, /h, /?, --help
    Display this message (add -v for information about all options).

  -v, --verbose
    Display verbose information.

  -D<name>=<value>
    Define an environment variable.

  --version
    Display version information.

  -p<path>, --package-root=<path>
    Where to find packages, that is, "package:..." imports.  This option cannot
    be used with --packages.

  --packages=<path>
    Path to the package resolution configuration file, which supplies a mapping
    of package names to paths.  This option cannot be used with --package-root.

  --analyze-all
    Analyze all code.  Without this option, the compiler only analyzes
    code that is reachable from [main].  This option implies --analyze-only.

  --analyze-only
    Analyze but do not generate code.

  --analyze-signatures-only
    Skip analysis of method bodies and field initializers. This option implies
    --analyze-only.

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

  --fast-startup
    Produce JavaScript that can be parsed more quickly by VMs. This option
    usually results in larger JavaScript files with faster startup.
    Note: the dart:mirrors library is not supported with this option.

  --preview-dart-2
    Preview of all Dart 2.0 semantics, this includes generic methods and strong
    mode type checks.

    This flag is mainly for early dogfooding and will be removed when all
    features are shipped.

The following advanced options can help reduce the size of the generated code,
but they may cause programs to behave unexpectedly if assumptions are not met.
Only turn on these flags if you have enough test coverage to ensure they are
safe to use:

  --omit-implicit-checks
    Omit implicit runtime checks, such as parameter checks and implicit
    downcasts. These checks are included by default in strong mode. By
    using this flag the checks are removed, however the compiler will assume
    that all such checks were valid and may use this information for
    optimizations. Use this option only if you have enough testing to ensure
    that your program works with the checks.

  --trust-primitives
    Assume that operations on numbers, strings, and lists have valid inputs.
    This option allows the compiler to drop runtime checks for those operations.
    Note: a well-typed program is not guaranteed to have valid inputs. For
    example, an int index argument may be null or out of range.

The following options are only used for compiler development and may
be removed in a future version:

  --throw-on-error
    Throw an exception if a compile-time error is detected.

  --library-root=<directory>
    Where to find the Dart platform libraries.

  --allow-mock-compilation
    Do not generate a call to main if either of the following
    libraries are used: dart:dom, dart:html dart:io.

  --disable-native-live-type-analysis
    Disable the optimization that removes unused native types from dart:html
    and related libraries.

  --categories=<categories>
    A comma separated list of allowed library categories.  The default
    is "Client".  Possible categories can be seen by providing an
    unsupported category, for example, --categories=help.  To enable
    all categories, use --categories=all.

  --deferred-map=<file>
    Generates a json file with a mapping from each deferred import to a list of
    the part.js files that will be loaded.

  --dump-info
    Generates an out.info.json file with information about the generated code.
    You can inspect the generated file with the viewer at:
        https://dart-lang.github.io/dump-info-visualizer/

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
  // Since the sdk/bin/dart2js script adds its own arguments in front of
  // user-supplied arguments we search for '--batch' at the end of the list.
  if (arguments.length > 0 && arguments.last == "--batch") {
    batchMain(arguments.sublist(0, arguments.length - 1));
    return;
  }
  internalMain(arguments);
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
  Future onError(exception, trace) {
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

  if (USE_SERIALIZED_DART_CORE) {
    _useSerializedDataForDartCore(compileFunc);
  }

  var stream = stdin.transform(UTF8.decoder).transform(new LineSplitter());
  var subscription;
  fe.InitializedCompilerState kernelInitializedCompilerState;
  subscription = stream.listen((line) {
    new Future.sync(() {
      subscription.pause();
      exitCode = 0;
      if (line == null) exit(0);
      List<String> args = <String>[];
      args.addAll(batchArguments);
      args.addAll(splitLine(line, windows: Platform.isWindows));
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

// TODO(johnniwinther): Add corresponding options to the test script and change
// these to use 'bool.fromEnvironment'.
final bool USE_SERIALIZED_DART_CORE =
    Platform.environment['USE_SERIALIZED_DART_CORE'] == 'true';

final bool SERIALIZED_COMPILATION =
    Platform.environment['SERIALIZED_COMPILATION'] == 'true';

/// Mock URI used only in testing when [USE_SERIALIZED_DART_CORE] or
/// [SERIALIZED_COMPILATION] is enabled.
final Uri _SERIALIZED_DART_CORE_URI = Uri.parse('file:core.data');
final Uri _SERIALIZED_TEST_URI = Uri.parse('file:test.data');

void _useSerializedDataForDartCore(CompileFunc oldCompileFunc) {
  /// Run the [oldCompileFunc] with [serializedData] added as resolution input.
  Future<api.CompilationResult> compileWithSerializedData(
      CompilerOptions compilerOptions,
      api.CompilerInput compilerInput,
      api.CompilerDiagnostics compilerDiagnostics,
      api.CompilerOutput compilerOutput,
      List<_SerializedData> serializedData,
      {bool compileOnly: false}) {
    api.CompilerInput input = compilerInput;
    CompilerOptions options = compilerOptions;
    if (serializedData != null && serializedData.isNotEmpty) {
      Map<Uri, String> dataMap = <Uri, String>{};
      for (_SerializedData data in serializedData) {
        dataMap[data.uri] = data.data;
      }
      input = new _CompilerInput(input, dataMap);
      List<Uri> resolutionInputs = dataMap.keys.toList();
      if (compilerOptions.resolutionInputs != null) {
        for (Uri uri in compilerOptions.resolutionInputs) {
          if (!dataMap.containsKey(uri)) {
            resolutionInputs.add(uri);
          }
        }
      }
      options
        ..resolutionInputs = resolutionInputs
        ..compileOnly = compileOnly;
    }
    return oldCompileFunc(options, input, compilerDiagnostics, compilerOutput);
  }

  /// Serialize [entryPoint] using [serializedData] if provided.
  Future<api.CompilationResult> serialize(
      Uri entryPoint,
      Uri serializedUri,
      CompilerOptions compilerOptions,
      api.CompilerInput compilerInput,
      api.CompilerDiagnostics compilerDiagnostics,
      api.CompilerOutput compilerOutput,
      [List<_SerializedData> serializedData]) {
    compilerOptions
      ..entryPoint = entryPoint
      ..resolutionOutput = serializedUri
      ..analyzeAll = true
      ..analyzeOnly = true
      ..resolveOnly = true;
    return compileWithSerializedData(compilerOptions, compilerInput,
        compilerDiagnostics, compilerOutput, serializedData);
  }

  // Local cache for the serialized data for dart:core.
  _SerializedData serializedDartCore;

  /// Serialize the entry point using serialized data from dart:core and run
  /// [oldCompileFunc] using serialized data for whole program.
  Future<api.CompilationResult> compileFromSerializedData(
      CompilerOptions compilerOptions,
      api.CompilerInput compilerInput,
      api.CompilerDiagnostics compilerDiagnostics,
      api.CompilerOutput compilerOutput) async {
    _CompilerOutput output = new _CompilerOutput(_SERIALIZED_TEST_URI);
    api.CompilationResult result = await serialize(
        compilerOptions.entryPoint,
        output.uri,
        compilerOptions,
        compilerInput,
        compilerDiagnostics,
        output,
        [serializedDartCore]);
    if (!result.isSuccess) {
      return result;
    }
    return compileWithSerializedData(
        compilerOptions,
        compilerInput,
        compilerDiagnostics,
        compilerOutput,
        [serializedDartCore, output.serializedData],
        compileOnly: true);
  }

  /// Compiles the entry point using the serialized data from dart:core.
  Future<api.CompilationResult> compileWithSerializedDartCoreData(
      CompilerOptions compilerOptions,
      api.CompilerInput compilerInput,
      api.CompilerDiagnostics compilerDiagnostics,
      api.CompilerOutput compilerOutput) async {
    return compileWithSerializedData(compilerOptions, compilerInput,
        compilerDiagnostics, compilerOutput, [serializedDartCore]);
  }

  /// Serialize dart:core data into [serializedDartCore] and setup the
  /// [compileFunc] to run the compiler using this data.
  Future<api.CompilationResult> generateSerializedDataForDartCore(
      CompilerOptions compilerOptions,
      api.CompilerInput compilerInput,
      api.CompilerDiagnostics compilerDiagnostics,
      api.CompilerOutput compilerOutput) async {
    _CompilerOutput output = new _CompilerOutput(_SERIALIZED_DART_CORE_URI);
    await serialize(Uris.dart_core, output.uri, compilerOptions, compilerInput,
        compilerDiagnostics, output);
    serializedDartCore = output.serializedData;
    if (SERIALIZED_COMPILATION) {
      compileFunc = compileFromSerializedData;
    } else {
      compileFunc = compileWithSerializedDartCoreData;
    }
    return compileFunc(
        compilerOptions, compilerInput, compilerDiagnostics, compilerOutput);
  }

  compileFunc = generateSerializedDataForDartCore;
}

class _CompilerInput implements api.CompilerInput {
  final api.CompilerInput _input;
  final Map<Uri, String> _data;

  _CompilerInput(this._input, this._data);

  @override
  Future<api.Input> readFromUri(Uri uri,
      {api.InputKind inputKind: api.InputKind.utf8}) {
    String data = _data[uri];
    if (data != null) {
      return new Future.value(new StringSourceFile.fromUri(uri, data));
    }
    return _input.readFromUri(uri, inputKind: inputKind);
  }
}

class _SerializedData {
  final Uri uri;
  final String data;

  _SerializedData(this.uri, this.data);
}

class _CompilerOutput extends NullCompilerOutput {
  final Uri uri;
  _BufferedOutputSink sink;

  _CompilerOutput(this.uri);

  @override
  api.OutputSink createOutputSink(
      String name, String extension, api.OutputType type) {
    if (name == '' && extension == 'data') {
      return sink = new _BufferedOutputSink();
    }
    return super.createOutputSink(name, extension, type);
  }

  _SerializedData get serializedData {
    return new _SerializedData(uri, sink.sb.toString());
  }
}

class _BufferedOutputSink implements api.OutputSink {
  StringBuffer sb = new StringBuffer();

  @override
  void add(String event) {
    sb.write(event);
  }

  @override
  void close() {
    // Do nothing.
  }
}
