// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cmdline;

import 'dart:async'
    show Future, EventSink;
import 'dart:convert' show UTF8, LineSplitter;
import 'dart:io'
    show exit, File, FileMode, Platform, RandomAccessFile, FileSystemException,
         stdin, stderr;

import '../compiler.dart' as api;
import 'commandline_options.dart';
import 'io/source_file.dart';
import 'source_file_provider.dart';
import 'filenames.dart';
import 'util/uri_extras.dart';
import 'util/util.dart' show stackTraceFilePrefix;
import 'util/command_line.dart';
import 'package:sdk_library_metadata/libraries.dart';
import 'package:package_config/discovery.dart' show findPackages;

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
typedef void HandleOption(data);

class OptionHandler {
  final String pattern;
  final HandleOption handle;
  final bool multipleArguments;

  OptionHandler(this.pattern, this.handle, {this.multipleArguments: false});
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
  OUTER: while (arguments.moveNext()) {
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

Future<api.CompilationResult> compile(List<String> argv) {
  stackTraceFilePrefix = '$currentDirectory';
  Uri libraryRoot = currentDirectory;
  Uri out = currentDirectory.resolve('out.js');
  Uri sourceMapOut = currentDirectory.resolve('out.js.map');
  Uri packageConfig = null;
  Uri packageRoot = null;
  List<String> options = new List<String>();
  bool explicitOut = false;
  bool wantHelp = false;
  bool wantVersion = false;
  String outputLanguage = 'JavaScript';
  bool stripArgumentSet = false;
  bool analyzeOnly = false;
  bool analyzeAll = false;
  bool dumpInfo = false;
  bool allowNativeExtensions = false;
  bool trustTypeAnnotations = false;
  bool checkedMode = false;
  // List of provided options that imply that output is expected.
  List<String> optionsImplyCompilation = <String>[];
  bool hasDisallowUnsafeEval = false;
  // TODO(johnniwinther): Measure time for reading files.
  SourceFileProvider inputProvider = new CompilerSourceFileProvider();
  diagnosticHandler = new FormattingDiagnosticHandler(inputProvider);
  Map<String, dynamic> environment = new Map<String, dynamic>();

  passThrough(String argument) => options.add(argument);

  if (BUILD_ID != null) {
    passThrough("--build-id=$BUILD_ID");
  }

  setLibraryRoot(String argument) {
    libraryRoot = currentDirectory.resolve(extractPath(argument));
  }

  setPackageRoot(String argument) {
    packageRoot = currentDirectory.resolve(extractPath(argument));
  }

  setPackageConfig(String argument) {
    packageConfig =
        currentDirectory.resolve(extractPath(argument, isDirectory: false));
  }

  setOutput(Iterator<String> arguments) {
    optionsImplyCompilation.add(arguments.current);
    String path;
    if (arguments.current == '-o') {
      if (!arguments.moveNext()) {
        helpAndFail('Error: Missing file after -o option.');
      }
      path = arguments.current;
    } else {
      path = extractParameter(arguments.current);
    }
    explicitOut = true;
    out = currentDirectory.resolve(nativeToUriPath(path));
    sourceMapOut = Uri.parse('$out.map');
  }

  setOutputType(String argument) {
    optionsImplyCompilation.add(argument);
    if (argument == '--output-type=dart' ||
        argument == '--output-type=dart-multi') {
      outputLanguage = OUTPUT_LANGUAGE_DART;
      if (!explicitOut) {
        out = currentDirectory.resolve('out.dart');
        sourceMapOut = currentDirectory.resolve('out.dart.map');
      }
      diagnosticHandler(null, null, null,
          "--output-type=dart is deprecated. It will remain available "
          "in Dart 1.11, but will be removed in Dart 1.12.",
          api.Diagnostic.WARNING);
    }
    passThrough(argument);
  }

  String getDepsOutput(Map<Uri, SourceFile> sourceFiles) {
    var filenames = sourceFiles.keys.map((uri) => '$uri').toList();
    filenames.sort();
    return filenames.join("\n");
  }

  setStrip(String argument) {
    optionsImplyCompilation.add(argument);
    stripArgumentSet = true;
    passThrough(argument);
  }

  setAnalyzeOnly(String argument) {
    analyzeOnly = true;
    passThrough(argument);
  }

  setAnalyzeAll(String argument) {
    analyzeAll = true;
    passThrough(argument);
  }

  setAllowNativeExtensions(String argument) {
    allowNativeExtensions = true;
    passThrough(argument);
  }

  setVerbose(_) {
    diagnosticHandler.verbose = true;
    passThrough('--verbose');
  }

  implyCompilation(String argument) {
    optionsImplyCompilation.add(argument);
    passThrough(argument);
  }

  setDumpInfo(String argument) {
    implyCompilation(argument);
    dumpInfo = true;
  }

  setTrustTypeAnnotations(String argument) {
    trustTypeAnnotations = true;
    implyCompilation(argument);
  }

  setTrustPrimitives(String argument) {
    implyCompilation(argument);
  }

  setCheckedMode(String argument) {
    checkedMode = true;
    passThrough(argument);
  }

  addInEnvironment(String argument) {
    int eqIndex = argument.indexOf('=');
    String name = argument.substring(2, eqIndex);
    String value = argument.substring(eqIndex + 1);
    environment[name] = value;
  }

  setCategories(String argument) {
    List<String> categories = extractParameter(argument).split(',');
    Set<String> allowedCategories =
        LIBRARIES.values.map((x) => x.category).toSet();
    allowedCategories.remove('Shared');
    allowedCategories.remove('Internal');
    List<String> allowedCategoriesList =
        new List<String>.from(allowedCategories);
    allowedCategoriesList.sort();
    if (categories.contains('all')) {
      categories = allowedCategoriesList;
    } else {
      String allowedCategoriesString = allowedCategoriesList.join(', ');
      for (String category in categories) {
        if (!allowedCategories.contains(category)) {
          fail('Unsupported library category "$category", '
               'supported categories are: $allowedCategoriesString');
        }
      }
    }
    passThrough('--categories=${categories.join(",")}');
  }

  void handleThrowOnError(String argument) {
    diagnosticHandler.throwOnError = true;
    String parameter = extractParameter(argument, isOptionalArgument: true);
    if (parameter != null) {
      diagnosticHandler.throwOnErrorCount = int.parse(parameter);
    }
  }

  handleShortOptions(String argument) {
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
          implyCompilation(Flags.minify);
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
    new OptionHandler(Flags.suppressWarnings, (_) {
      diagnosticHandler.showWarnings = false;
      passThrough(Flags.suppressWarnings);
    }),
    new OptionHandler(Flags.fatalWarnings, passThrough),
    new OptionHandler(Flags.suppressHints,
                      (_) => diagnosticHandler.showHints = false),
    new OptionHandler(
        '--output-type=dart|--output-type=dart-multi|--output-type=js',
        setOutputType),
    new OptionHandler(Flags.useCpsIr, passThrough),
    new OptionHandler(Flags.noFrequencyBasedMinification, passThrough),
    new OptionHandler(Flags.verbose, setVerbose),
    new OptionHandler(Flags.version, (_) => wantVersion = true),
    new OptionHandler('--library-root=.+', setLibraryRoot),
    new OptionHandler('--out=.+|-o.*', setOutput, multipleArguments: true),
    new OptionHandler(Flags.allowMockCompilation, passThrough),
    new OptionHandler(Flags.fastStartup, passThrough),
    new OptionHandler('${Flags.minify}|-m', implyCompilation),
    new OptionHandler(Flags.preserveUris, passThrough),
    new OptionHandler('--force-strip=.*', setStrip),
    new OptionHandler(Flags.disableDiagnosticColors,
                      (_) => diagnosticHandler.enableColors = false),
    new OptionHandler(Flags.enableDiagnosticColors,
                      (_) => diagnosticHandler.enableColors = true),
    new OptionHandler('--enable[_-]checked[_-]mode|--checked',
                      (_) => setCheckedMode(Flags.enableCheckedMode)),
    new OptionHandler(Flags.enableConcreteTypeInference,
                      (_) => implyCompilation(
                          Flags.enableConcreteTypeInference)),
    new OptionHandler(Flags.trustTypeAnnotations,
                      (_) => setTrustTypeAnnotations(
                          Flags.trustTypeAnnotations)),
    new OptionHandler(Flags.trustPrimitives,
                      (_) => setTrustPrimitives(
                          Flags.trustPrimitives)),
    new OptionHandler(r'--help|/\?|/h', (_) => wantHelp = true),
    new OptionHandler('--packages=.+', setPackageConfig),
    new OptionHandler('--package-root=.+|-p.+', setPackageRoot),
    new OptionHandler(Flags.analyzeAll, setAnalyzeAll),
    new OptionHandler(Flags.analyzeOnly, setAnalyzeOnly),
    new OptionHandler(Flags.noSourceMaps, passThrough),
    new OptionHandler(Flags.analyzeSignaturesOnly, setAnalyzeOnly),
    new OptionHandler(Flags.disableNativeLiveTypeAnalysis, passThrough),
    new OptionHandler('--categories=.*', setCategories),
    new OptionHandler(Flags.disableTypeInference, implyCompilation),
    new OptionHandler(Flags.terse, passThrough),
    new OptionHandler('--deferred-map=.+', implyCompilation),
    new OptionHandler(Flags.dumpInfo, setDumpInfo),
    new OptionHandler('--disallow-unsafe-eval',
                      (_) => hasDisallowUnsafeEval = true),
    new OptionHandler(Flags.showPackageWarnings, passThrough),
    new OptionHandler(Flags.useContentSecurityPolicy, passThrough),
    new OptionHandler(Flags.enableExperimentalMirrors, passThrough),
    new OptionHandler('--enable-async', (_) {
      diagnosticHandler.info(
          "Option '--enable-async' is no longer needed. "
          "Async-await is supported by default.",
          api.Diagnostic.HINT);
    }),
    new OptionHandler('--enable-null-aware-operators',  (_) {
      diagnosticHandler.info(
          "Option '--enable-null-aware-operators' is no longer needed. "
          "Null aware operators are supported by default.",
          api.Diagnostic.HINT);
    }),
    new OptionHandler('--enable-enum', (_) {
      diagnosticHandler.info(
          "Option '--enable-enum' is no longer needed. "
          "Enums are supported by default.",
          api.Diagnostic.HINT);
    }),
    new OptionHandler(Flags.allowNativeExtensions, setAllowNativeExtensions),
    new OptionHandler(Flags.generateCodeWithCompileTimeErrors, passThrough),
    new OptionHandler(Flags.testMode, passThrough),

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
  if (wantHelp || wantVersion) {
    helpAndExit(wantHelp, wantVersion, diagnosticHandler.verbose);
  }

  if (hasDisallowUnsafeEval) {
    String precompiledName =
        relativize(currentDirectory,
                   RandomAccessFileOutputProvider.computePrecompiledUri(out),
                   Platform.isWindows);
    helpAndFail("Option '--disallow-unsafe-eval' has been removed."
                " Instead, the compiler generates a file named"
                " '$precompiledName'.");
  }

  if (outputLanguage != OUTPUT_LANGUAGE_DART && stripArgumentSet) {
    helpAndFail("Option '--force-strip' may only be used with "
                "'--output-type=dart'.");
  }
  if (arguments.isEmpty) {
    helpAndFail('No Dart file specified.');
  }
  if (arguments.length > 1) {
    var extra = arguments.sublist(1);
    helpAndFail('Extra arguments: ${extra.join(" ")}');
  }

  if (checkedMode && trustTypeAnnotations) {
    helpAndFail("Option '${Flags.trustTypeAnnotations}' may not be used in "
                "checked mode.");
  }

  if (packageRoot != null && packageConfig != null) {
    helpAndFail("Cannot specify both '--package-root' and '--packages.");
  }

  if ((analyzeOnly || analyzeAll) && !optionsImplyCompilation.isEmpty) {
    if (!analyzeOnly) {
      diagnosticHandler.info(
          "Option '${Flags.analyzeAll}' implies '${Flags.analyzeOnly}'.",
          api.Diagnostic.INFO);
    }
    diagnosticHandler.info(
        "Options $optionsImplyCompilation indicate that output is expected, "
        "but compilation is turned off by the option '${Flags.analyzeOnly}'.",
        api.Diagnostic.INFO);
  }
  if (analyzeAll) analyzeOnly = true;
  if (!analyzeOnly) {
    if (allowNativeExtensions) {
      helpAndFail("Option '${Flags.allowNativeExtensions}' is only supported "
                  "in combination with the '${Flags.analyzeOnly}' option.");
    }
  }
  if (dumpInfo && outputLanguage == OUTPUT_LANGUAGE_DART) {
    helpAndFail("Option '${Flags.dumpInfo}' is not supported in "
                "combination with the '--output-type=dart' option.");
  }

  options.add('--out=$out');
  options.add('--source-map=$sourceMapOut');

  RandomAccessFileOutputProvider outputProvider =
      new RandomAccessFileOutputProvider(
          out, sourceMapOut, onInfo: diagnosticHandler.info, onFailure: fail);

  api.CompilationResult compilationDone(api.CompilationResult result) {
    if (analyzeOnly) return result;
    if (!result.isSuccess) {
      fail('Compilation failed.');
    }
    writeString(Uri.parse('$out.deps'),
                getDepsOutput(inputProvider.sourceFiles));
    diagnosticHandler.info(
         'Compiled ${inputProvider.dartCharactersRead} characters Dart '
         '-> ${outputProvider.totalCharactersWritten} characters '
         '$outputLanguage in '
         '${relativize(currentDirectory, out, Platform.isWindows)}');
    if (diagnosticHandler.verbose) {
      String input = uriPathToNative(arguments[0]);
      print('Dart file ($input) compiled to $outputLanguage.');
      print('Wrote the following files:');
      for (String filename in outputProvider.allOutputFiles) {
        print("  $filename");
      }
    } else if (!explicitOut) {
      String input = uriPathToNative(arguments[0]);
      String output = relativize(currentDirectory, out, Platform.isWindows);
      print('Dart file ($input) compiled to $outputLanguage: $output');
    }
    return result;
  }

  Uri uri = currentDirectory.resolve(arguments[0]);
  return compileFunc(uri, libraryRoot, packageRoot, inputProvider,
                     diagnosticHandler, options, outputProvider, environment,
                     packageConfig, findPackages)
            .then(compilationDone);
}

class AbortLeg {
  final message;
  AbortLeg(this.message);
  toString() => 'Aborted due to --throw-on-error: $message';
}

void writeString(Uri uri, String text) {
  if (uri.scheme != 'file') {
    fail('Unhandled scheme ${uri.scheme}.');
  }
  var file = new File(uri.toFilePath()).openSync(mode: FileMode.WRITE);
  file.writeStringSync(text);
  file.closeSync();
}

void fail(String message) {
  if (diagnosticHandler != null) {
    diagnosticHandler.report(
        null, null, -1, -1, message, api.Diagnostic.ERROR);
  } else {
    print('Error: $message');
  }
  exitFunc(1);
}

Future<api.CompilationResult> compilerMain(List<String> arguments) {
  var root = uriPathToNative("/$LIBRARY_ROOT");
  arguments = <String>['--library-root=${Platform.script.toFilePath()}$root']
      ..addAll(arguments);
  return compile(arguments);
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

  -c, --enable-checked-mode, --checked
    Insert runtime type checks and enable assertions (checked mode).

  -m, --minify
    Generate minified output.

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

  --preserve-uris
    Preserve the source URIs in the reflection data. Without this flag the
    `uri` getter for `LibraryMirror`s is mangled in minified mode.

  --csp
    Disables dynamic generation of code in the generated output. This is
    necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).

  --no-source-maps
    Do not generate a source map file.

The following options are only used for compiler development and may
be removed in a future version:

  --output-type=dart
    Output Dart code instead of JavaScript.

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
    This feature is currently not supported in combination with the
    '--output-type=dart' option.

  --generate-code-with-compile-time-errors
    Generates output even if the program contains compile-time errors. Use the
    exit code to determine if compilation failed.

  --use-cps-ir
    Experimental.  Use the new CPS based backend for code generation.

  --no-frequency-based-minification
    Experimental.  Disabled the new frequency based minifying namer and use the
    old namer instead.
'''.trim());
}

void helpAndExit(bool wantHelp, bool wantVersion, bool verbose) {
  if (wantVersion) {
    var version = (BUILD_ID == null)
        ? '<non-SDK build>'
        : BUILD_ID;
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

var exitFunc = exit;
var compileFunc = api.compile;

Future<api.CompilationResult> internalMain(List<String> arguments) {
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
    return compilerMain(arguments).catchError(onError);
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

  var stream = stdin.transform(UTF8.decoder).transform(new LineSplitter());
  var subscription;
  subscription = stream.listen((line) {
    new Future.sync(() {
      subscription.pause();
      exitCode = 0;
      if (line == null) exit(0);
      List<String> args = <String>[];
      args.addAll(batchArguments);
      args.addAll(splitLine(line, windows: Platform.isWindows));
      return internalMain(args);
    }).catchError((exception, trace) {
      if (!identical(exception, _EXIT_SIGNAL)) {
        exitCode = 253;
      }
    }).whenComplete(() {
      // The testing framework waits for a status line on stdout and
      // stderr before moving to the next test.
      if (exitCode == 0){
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
