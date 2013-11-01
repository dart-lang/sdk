// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cmdline;

import 'dart:async';
import 'dart:io'
    show exit, File, FileMode, Platform, RandomAccessFile;
import 'dart:math' as math;

import '../compiler.dart' as api;
import 'source_file.dart';
import 'source_file_provider.dart';
import 'filenames.dart';
import 'util/uri_extras.dart';
import 'util/util.dart';
import '../../libraries.dart';

const String LIBRARY_ROOT = '../../../../..';
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
String extractParameter(String argument) {
  // m[0] is the entire match (which will be equal to argument). m[1]
  // is something like "-o" or "--out=", and m[2] is the parameter.
  Match m = new RegExp('^(-[a-z]|--.+=)(.*)').firstMatch(argument);
  if (m == null) helpAndFail('Error: Unknown option "$argument".');
  return m[2];
}

String extractPath(String argument) {
  String path = nativeToUriPath(extractParameter(argument));
  return path.endsWith("/") ? path : "$path/";
}

void parseCommandLine(List<OptionHandler> handlers, List<String> argv) {
  // TODO(ahe): Use ../../args/args.dart for parsing options instead.
  var patterns = <String>[];
  for (OptionHandler handler in handlers) {
    patterns.add(handler.pattern);
  }
  var pattern = new RegExp('^(${patterns.join(")\$|(")})\$');

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

Future compile(List<String> argv) {
  bool isWindows = (Platform.operatingSystem == 'windows');
  stackTraceFilePrefix = '$currentDirectory';
  Uri libraryRoot = currentDirectory;
  Uri out = currentDirectory.resolve('out.js');
  Uri sourceMapOut = currentDirectory.resolve('out.js.map');
  Uri packageRoot = null;
  List<String> options = new List<String>();
  bool explicitOut = false;
  bool wantHelp = false;
  bool wantVersion = false;
  String outputLanguage = 'JavaScript';
  bool stripArgumentSet = false;
  bool analyzeOnly = false;
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

  setOutput(Iterator<String> arguments) {
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
    if (argument == '--output-type=dart') {
      outputLanguage = OUTPUT_LANGUAGE_DART;
      if (!explicitOut) {
        out = currentDirectory.resolve('out.dart');
        sourceMapOut = currentDirectory.resolve('out.dart.map');
      }
    }
    passThrough(argument);
  }

  String getDepsOutput(Map<String, SourceFile> sourceFiles) {
    var filenames = new List.from(sourceFiles.keys);
    filenames.sort();
    return filenames.join("\n");
  }

  setStrip(String argument) {
    stripArgumentSet = true;
    passThrough(argument);
  }

  setAnalyzeOnly(String argument) {
    analyzeOnly = true;
    passThrough(argument);
  }

  setVerbose(_) {
    diagnosticHandler.verbose = true;
    passThrough('--verbose');
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
          fail('Error: unsupported library category "$category", '
               'supported categories are: $allowedCategoriesString');
        }
      }
    }
    passThrough('--categories=${categories.join(",")}');
  }

  checkGlobalName(String argument) {
    String globalName = extractParameter(argument);
    if (!new RegExp(r'^\$[a-z]*$').hasMatch(globalName)) {
      fail('Error: "$globalName" must match "\\\$[a-z]*"');
    }
    passThrough(argument);
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
          passThrough('--enable-checked-mode');
          break;
        default:
          throw 'Internal error: "$shortOption" did not match';
      }
    }
  }

  Uri computePrecompiledUri() {
    String extension = 'precompiled.js';
    String outPath = out.path;
    if (outPath.endsWith('.js')) {
      outPath = outPath.substring(0, outPath.length - 3);
      return out.resolve('$outPath.$extension');
    } else {
      return out.resolve(extension);
    }
  }

  List<String> arguments = <String>[];
  List<OptionHandler> handlers = <OptionHandler>[
    new OptionHandler('-[chv?]+', handleShortOptions),
    new OptionHandler('--throw-on-error',
                      (_) => diagnosticHandler.throwOnError = true),
    new OptionHandler('--suppress-warnings',
                      (_) => diagnosticHandler.showWarnings = false),
    new OptionHandler('--suppress-hints',
                      (_) => diagnosticHandler.showHints = false),
    new OptionHandler('--output-type=dart|--output-type=js', setOutputType),
    new OptionHandler('--verbose', setVerbose),
    new OptionHandler('--version', (_) => wantVersion = true),
    new OptionHandler('--library-root=.+', setLibraryRoot),
    new OptionHandler('--out=.+|-o.*', setOutput, multipleArguments: true),
    new OptionHandler('--allow-mock-compilation', passThrough),
    new OptionHandler('--minify', passThrough),
    new OptionHandler('--force-strip=.*', setStrip),
    new OptionHandler('--disable-diagnostic-colors',
                      (_) => diagnosticHandler.enableColors = false),
    new OptionHandler('--enable-diagnostic-colors',
                      (_) => diagnosticHandler.enableColors = true),
    new OptionHandler('--enable[_-]checked[_-]mode|--checked',
                      (_) => passThrough('--enable-checked-mode')),
    new OptionHandler('--enable-concrete-type-inference',
                      (_) => passThrough('--enable-concrete-type-inference')),
    new OptionHandler('--trust-type-annotations',
                      (_) => passThrough('--trust-type-annotations')),
    new OptionHandler(r'--help|/\?|/h', (_) => wantHelp = true),
    new OptionHandler('--package-root=.+|-p.+', setPackageRoot),
    new OptionHandler('--analyze-all', passThrough),
    new OptionHandler('--analyze-only', setAnalyzeOnly),
    new OptionHandler('--analyze-signatures-only', passThrough),
    new OptionHandler('--disable-native-live-type-analysis', passThrough),
    new OptionHandler('--categories=.*', setCategories),
    new OptionHandler('--global-js-name=.*', checkGlobalName),
    new OptionHandler('--disable-type-inference', passThrough),
    new OptionHandler('--terse', passThrough),
    new OptionHandler('--disallow-unsafe-eval',
                      (_) => hasDisallowUnsafeEval = true),
    new OptionHandler('-D.+=.*', addInEnvironment),

    // The following two options must come last.
    new OptionHandler('-.*', (String argument) {
      helpAndFail('Error: Unknown option "$argument".');
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
        relativize(currentDirectory, computePrecompiledUri(), isWindows);
    helpAndFail("Error: option '--disallow-unsafe-eval' has been removed."
                " Instead, the compiler generates a file named"
                " '$precompiledName'.");
  }

  if (outputLanguage != OUTPUT_LANGUAGE_DART && stripArgumentSet) {
    helpAndFail('Error: --force-strip may only be used with '
        '--output-type=dart');
  }
  if (arguments.isEmpty) {
    helpAndFail('Error: No Dart file specified.');
  }
  if (arguments.length > 1) {
    var extra = arguments.sublist(1);
    helpAndFail('Error: Extra arguments: ${extra.join(" ")}');
  }

  Uri uri = currentDirectory.resolve(arguments[0]);
  if (packageRoot == null) {
    packageRoot = uri.resolve('./packages/');
  }

  diagnosticHandler.info('package root is $packageRoot');

  int totalCharactersWritten = 0;

  options.add('--source-map=$sourceMapOut');

  compilationDone(String code) {
    if (analyzeOnly) return;
    if (code == null) {
      fail('Error: Compilation failed.');
    }
    writeString(Uri.parse('$out.deps'),
                getDepsOutput(inputProvider.sourceFiles));
    diagnosticHandler.info(
         'compiled ${inputProvider.dartCharactersRead} characters Dart '
         '-> $totalCharactersWritten characters $outputLanguage '
         'in ${relativize(currentDirectory, out, isWindows)}');
    if (!explicitOut) {
      String input = uriPathToNative(arguments[0]);
      String output = relativize(currentDirectory, out, isWindows);
      print('Dart file ($input) compiled to $outputLanguage: $output');
    }
  }

  EventSink<String> outputProvider(String name, String extension) {
    Uri uri;
    String sourceMapFileName;
    bool isPrimaryOutput = false;
    if (name == '') {
      if (extension == 'js' || extension == 'dart') {
        isPrimaryOutput = true;
        uri = out;
        sourceMapFileName =
            sourceMapOut.path.substring(sourceMapOut.path.lastIndexOf('/') + 1);
      } else if (extension == 'precompiled.js') {
        uri = computePrecompiledUri();
        diagnosticHandler.info(
            "File ($uri) is compatible with header"
            " \"Content-Security-Policy: script-src 'self'\"");
      } else if (extension == 'js.map' || extension == 'dart.map') {
        uri = sourceMapOut;
      } else {
        fail('Error: Unknown extension: $extension');
      }
    } else {
      uri = out.resolve('$name.$extension');
    }

    if (uri.scheme != 'file') {
      fail('Error: Unhandled scheme ${uri.scheme} in $uri.');
    }

    RandomAccessFile output =
        new File(uriPathToNative(uri.path)).openSync(mode: FileMode.WRITE);
    int charactersWritten = 0;

    writeStringSync(String data) {
      // Write the data in chunks of 8kb, otherwise we risk running OOM
      int chunkSize = 8*1024;

      int offset = 0;
      while (offset < data.length) {
        output.writeStringSync(
            data.substring(offset, math.min(offset + chunkSize, data.length)));
        offset += chunkSize;
      }
      charactersWritten += data.length;
    }

    onDone() {
      if (sourceMapFileName != null) {
        // Using # is the new proposed standard. @ caused problems in Internet
        // Explorer due to "Conditional Compilation Statements" in JScript,
        // see:
        // http://msdn.microsoft.com/en-us/library/7kx09ct1(v=vs.80).aspx
        // About source maps, see:
        // https://docs.google.com/a/google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit
        // TODO(http://dartbug.com/11914): Remove @ line.
        String sourceMapTag = '''

//# sourceMappingURL=$sourceMapFileName
//@ sourceMappingURL=$sourceMapFileName
''';
        writeStringSync(sourceMapTag);
      }
      output.closeSync();
      if (isPrimaryOutput) {
        totalCharactersWritten += charactersWritten;
      }
    }

    return new EventSinkWrapper(writeStringSync, onDone);
  }

  return api.compile(uri, libraryRoot, packageRoot,
              inputProvider, diagnosticHandler,
              options, outputProvider, environment)
            .then(compilationDone);
}

class EventSinkWrapper extends EventSink<String> {
  var onAdd, onClose;

  EventSinkWrapper(this.onAdd, this.onClose);

  void add(String data) => onAdd(data);

  void addError(error, [StackTrace stackTrace]) => throw error;

  void close() => onClose();
}

class AbortLeg {
  final message;
  AbortLeg(this.message);
  toString() => 'Aborted due to --throw-on-error: $message';
}

void writeString(Uri uri, String text) {
  if (uri.scheme != 'file') {
    fail('Error: Unhandled scheme ${uri.scheme}.');
  }
  var file = new File(uriPathToNative(uri.path)).openSync(mode: FileMode.WRITE);
  file.writeStringSync(text);
  file.closeSync();
}

void fail(String message) {
  if (diagnosticHandler != null) {
    diagnosticHandler.diagnosticHandler(
        null, -1, -1, message, api.Diagnostic.ERROR);
  } else {
    print(message);
  }
  exit(1);
}

Future compilerMain(List<String> arguments) {
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

  -h, /h, /?, --help
    Display this message (add -v for information about all options).

  -v, --verbose
    Display verbose information.

  -D<name>=<value>
    Define an environment variable.

  --version
    Display version information.

  -p<path>, --package-root=<path>
    Where to find packages, that is, "package:..." imports.

  --analyze-all
    Analyze all code.  Without this option, the compiler only analyzes
    code that is reachable from [main].  This option is useful for
    finding errors in libraries, but using it can result in bigger and
    slower output.

  --analyze-only
    Analyze but do not generate code.

  --analyze-signatures-only
    Skip analysis of method bodies and field initializers. This option implies
    --analyze-only.

  --minify
    Generate minified output.

  --suppress-warnings
    Do not display any warnings.

  --suppress-hints
    Do not display any hints.

  --enable-diagnostic-colors
    Add colors to diagnostic messages.

  --terse
    Emit diagnostics without suggestions for how to get rid of the diagnosed
    problems.

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

  --enable-concrete-type-inference
    Enable experimental concrete type inference.

  --disable-native-live-type-analysis
    Disable the optimization that removes unused native types from dart:html
    and related libraries.

  --categories=<categories>
    A comma separated list of allowed library categories.  The default
    is "Client".  Possible categories can be seen by providing an
    unsupported category, for example, --categories=help.  To enable
    all categories, use --categories=all.

  --global-js-name=<name>
    By default, dart2js generates JavaScript output that uses a global
    variable named "$".  The name of this global can be overridden
    with this option.  The name must match the regular expression "\$[a-z]*".

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
  exit(0);
}

void helpAndFail(String message) {
  help();
  print('');
  fail(message);
}

void main(List<String> arguments) {
  runZoned(() => compilerMain(arguments), onError: (exception, trace) {
    try {
      print('Internal error: $exception');
    } catch (ignored) {
      print('Internal error: error while printing exception');
    }

    try {
      if (trace != null) {
        print(trace);
      }
    } finally {
      exit(253); // 253 is recognized as a crash by our test scripts.
    }
  });
}
