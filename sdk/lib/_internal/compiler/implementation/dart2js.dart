// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js;

import 'dart:async';
import 'dart:collection' show Queue, LinkedHashMap;
import 'dart:io';
import 'dart:uri';
import 'dart:utf';

import '../compiler.dart' as api;
import 'source_file.dart';
import 'source_file_provider.dart';
import 'filenames.dart';
import 'util/uri_extras.dart';
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

typedef void HandleOption(String option);

class OptionHandler {
  String pattern;
  HandleOption handle;

  OptionHandler(this.pattern, this.handle);
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
  OUTER: for (String argument in argv) {
    Match match = pattern.firstMatch(argument);
    assert(match.groupCount == handlers.length);
    for (int i = 0; i < handlers.length; i++) {
      if (match[i + 1] != null) {
        handlers[i].handle(argument);
        continue OUTER;
      }
    }
    throw 'Internal error: "$argument" did not match';
  }
}

void compile(List<String> argv) {
  bool isWindows = (Platform.operatingSystem == 'windows');
  Uri cwd = getCurrentDirectory();
  Uri libraryRoot = cwd;
  Uri out = cwd.resolve('out.js');
  Uri sourceMapOut = cwd.resolve('out.js.map');
  Uri packageRoot = null;
  List<String> options = new List<String>();
  bool explicitOut = false;
  bool wantHelp = false;
  String outputLanguage = 'JavaScript';
  bool stripArgumentSet = false;
  bool analyzeOnly = false;
  SourceFileProvider inputProvider = new SourceFileProvider();
  FormattingDiagnosticHandler diagnosticHandler =
      new FormattingDiagnosticHandler(inputProvider);

  passThrough(String argument) => options.add(argument);

  if (BUILD_ID != null) {
    passThrough("--build-id=$BUILD_ID");
  }

  setLibraryRoot(String argument) {
    libraryRoot = cwd.resolve(extractPath(argument));
  }

  setPackageRoot(String argument) {
    packageRoot = cwd.resolve(extractPath(argument));
  }

  setOutput(String argument) {
    explicitOut = true;
    out = cwd.resolve(nativeToUriPath(extractParameter(argument)));
    sourceMapOut = Uri.parse('$out.map');
  }

  setOutputType(String argument) {
    if (argument == '--output-type=dart') {
      outputLanguage = OUTPUT_LANGUAGE_DART;
      if (!explicitOut) {
        out = cwd.resolve('out.dart');
        sourceMapOut = cwd.resolve('out.dart.map');
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
    return passThrough('--categories=${categories.join(",")}');
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

  List<String> arguments = <String>[];
  List<OptionHandler> handlers = <OptionHandler>[
    new OptionHandler('-[chv?]+', handleShortOptions),
    new OptionHandler('--throw-on-error',
                      (_) => diagnosticHandler.throwOnError = true),
    new OptionHandler('--suppress-warnings',
                      (_) => diagnosticHandler.showWarnings = false),
    new OptionHandler('--output-type=dart|--output-type=js', setOutputType),
    new OptionHandler('--verbose', setVerbose),
    new OptionHandler('--library-root=.+', setLibraryRoot),
    new OptionHandler('--out=.+|-o.+', setOutput),
    new OptionHandler('--allow-mock-compilation', passThrough),
    new OptionHandler('--minify', passThrough),
    new OptionHandler('--force-strip=.*', setStrip),
    // TODO(ahe): Remove the --no-colors option.
    new OptionHandler('--disable-diagnostic-colors',
                      (_) => diagnosticHandler.enableColors = false),
    new OptionHandler('--enable-diagnostic-colors',
                      (_) => diagnosticHandler.enableColors = true),
    new OptionHandler('--enable[_-]checked[_-]mode|--checked',
                      (_) => passThrough('--enable-checked-mode')),
    new OptionHandler('--enable-concrete-type-inference',
                      (_) => passThrough('--enable-concrete-type-inference')),
    new OptionHandler(r'--help|/\?|/h', (_) => wantHelp = true),
    new OptionHandler('--package-root=.+|-p.+', setPackageRoot),
    new OptionHandler('--disallow-unsafe-eval', passThrough),
    new OptionHandler('--analyze-all', passThrough),
    new OptionHandler('--analyze-only', setAnalyzeOnly),
    new OptionHandler('--analyze-signatures-only', passThrough),
    new OptionHandler('--disable-native-live-type-analysis', passThrough),
    new OptionHandler('--reject-deprecated-language-features', passThrough),
    new OptionHandler('--report-sdk-use-of-deprecated-language-features',
                      passThrough),
    new OptionHandler('--categories=.*', setCategories),

    // The following two options must come last.
    new OptionHandler('-.*', (String argument) {
      helpAndFail('Error: Unknown option "$argument".');
    }),
    new OptionHandler('.*', (String argument) {
      arguments.add(nativeToUriPath(argument));
    })
  ];

  parseCommandLine(handlers, argv);
  if (wantHelp) helpAndExit(diagnosticHandler.verbose);

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

  void handler(Uri uri, int begin, int end, String message,
               api.Diagnostic kind) {
    diagnosticHandler.diagnosticHandler(uri, begin, end, message, kind);
  }

  Uri uri = cwd.resolve(arguments[0]);
  if (packageRoot == null) {
    packageRoot = uri.resolve('./packages/');
  }

  diagnosticHandler.info('package root is $packageRoot');

  int charactersWritten = 0;

  compilationDone(String code) {
    if (analyzeOnly) return;
    if (code == null) {
      fail('Error: Compilation failed.');
    }
    writeString(Uri.parse('$out.deps'),
                getDepsOutput(inputProvider.sourceFiles));
    diagnosticHandler.info(
         'compiled ${inputProvider.dartCharactersRead} characters Dart '
         '-> $charactersWritten characters $outputLanguage '
         'in ${relativize(cwd, out, isWindows)}');
    if (!explicitOut) {
      String input = uriPathToNative(arguments[0]);
      String output = relativize(cwd, out, isWindows);
      print('Dart file $input compiled to $outputLanguage: $output');
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
    IOSink output =
        new File(uriPathToNative(uri.path)).openWrite();

    CountingSink sink;

    onDone() {
      if (sourceMapFileName != null) {
        String sourceMapTag = '//@ sourceMappingURL=$sourceMapFileName\n';
        sink.count += sourceMapTag.length;
        output.write(sourceMapTag);
      }
      output.close();
      if (isPrimaryOutput) {
        charactersWritten += sink.count;
      }
    }

    var controller = new StreamController<String>();
    controller.stream.listen(output.write, onDone: onDone);
    sink = new CountingSink(controller);
    return sink;
  }

  api.compile(uri, libraryRoot, packageRoot,
              inputProvider.readStringFromUri, handler,
              options, outputProvider)
      .then(compilationDone);
}

// TODO(ahe): Get rid of this class if http://dartbug.com/8118 is fixed.
class CountingSink implements EventSink<String> {
  final EventSink<String> sink;
  int count = 0;

  CountingSink(this.sink);

  void add(String value) {
    sink.add(value);
    count += value.length;
  }

  void addError(Object error) { sink.addError(error); }

  void close() { sink.close(); }
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
  print(message);
  exit(1);
}

void compilerMain(Options options) {
  var root = uriPathToNative("/$LIBRARY_ROOT");
  List<String> argv = ['--library-root=${options.script}$root'];
  argv.addAll(options.arguments);
  compile(argv);
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
  -o<file> Generate the output into <file>.
  -c       Insert runtime type checks and enable assertions (checked mode).
  -h       Display this message (add -v for information about all options).''');
}

void verboseHelp() {
  print('''
Usage: dart2js [options] dartfile

Compiles Dart to JavaScript.

Supported options:
  -o<file>, --out=<file>
    Generate the output into <file>.

  -c, --enable-checked-mode, --checked
    Insert runtime type checks and enable assertions (checked mode).

  -h, /h, /?, --help
    Display this message (add -v for information about all options).

  -v, --verbose
    Display verbose information.

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

  --disallow-unsafe-eval
    Disable dynamic generation of code in the generated output. This is
    necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).

  --suppress-warnings
    Do not display any warnings.

  --enable-diagnostic-colors
    Add colors to diagnostic messages.

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

  --reject-deprecated-language-features
    Reject deprecated language features.  Without this option, the
    compiler will accept language features that are no longer valid
    according to The Dart Programming Language Specification, version
    0.12, M1.

  --report-sdk-use-of-deprecated-language-features
    Report use of deprecated features in Dart platform libraries.
    Without this option, the compiler will silently accept use of
    deprecated language features from these libraries.  The option
    --reject-deprecated-language-features controls if these usages are
    reported as errors or warnings.

  --categories=<categories>
    A comma separated list of allowed library categories.  The default
    is "Client".  Possible categories can be seen by providing an
    unsupported category, for example, --categories=help.  To enable
    all categories, use --categories=all.

'''.trim());
}

void helpAndExit(bool verbose) {
  if (verbose) {
    verboseHelp();
  } else {
    help();
  }
  exit(0);
}

void helpAndFail(String message) {
  help();
  print('');
  fail(message);
}

void mainWithErrorHandler(Options options) {
  try {
    compilerMain(options);
  } catch (exception, trace) {
    try {
      print('Internal error: $exception');
    } catch (ignored) {
      print('Internal error: error while printing exception');
    }
    try {
      print(trace);
    } finally {
      exit(253); // 253 is recognized as a crash by our test scripts.
    }
  }
}

void main() {
  mainWithErrorHandler(new Options());
}
