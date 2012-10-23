// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js;

import 'dart:io';
import 'dart:uri';
import 'dart:utf';

import '../compiler.dart' as api;
import 'colors.dart' as colors;
import 'source_file.dart';
import 'filenames.dart';
import 'util/uri_extras.dart';

const String LIBRARY_ROOT = '../../../..';
const String OUTPUT_LANGUAGE_DART = 'Dart';

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
  Match m = const RegExp('^(-[a-z]|--.+=)(.*)').firstMatch(argument);
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
  var pattern = new RegExp('^(${Strings.join(patterns, ")\$|(")})\$');
  OUTER: for (String argument in argv) {
    Match match = pattern.firstMatch(argument);
    assert(match.groupCount() == handlers.length);
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
  bool throwOnError = false;
  bool showWarnings = true;
  bool verbose = false;
  Uri libraryRoot = cwd;
  Uri out = cwd.resolve('out.js');
  Uri sourceMapOut = cwd.resolve('out.js.map');
  Uri packageRoot = null;
  List<String> options = new List<String>();
  bool explicitOut = false;
  bool wantHelp = false;
  bool enableColors = false;
  String outputLanguage = 'JavaScript';
  bool stripArgumentSet = false;

  passThrough(String argument) => options.add(argument);

  setLibraryRoot(String argument) {
    libraryRoot = cwd.resolve(extractPath(argument));
  }

  setPackageRoot(String argument) {
    packageRoot = cwd.resolve(extractPath(argument));
  }

  setOutput(String argument) {
    explicitOut = true;
    out = cwd.resolve(nativeToUriPath(extractParameter(argument)));
    sourceMapOut = new Uri.fromString('$out.map');
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

  setStrip(String argument) {
    stripArgumentSet = true;
    passThrough(argument);
  }

  handleShortOptions(String argument) {
    var shortOptions = argument.substring(1).splitChars();
    for (var shortOption in shortOptions) {
      switch (shortOption) {
        case 'v':
          verbose = true;
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
    new OptionHandler('--throw-on-error', (_) => throwOnError = true),
    new OptionHandler('--suppress-warnings', (_) => showWarnings = false),
    new OptionHandler('--output-type=dart|--output-type=js', setOutputType),
    new OptionHandler('--verbose', (_) => verbose = true),
    new OptionHandler('--library-root=.+', setLibraryRoot),
    new OptionHandler('--out=.+|-o.+', setOutput),
    new OptionHandler('--allow-mock-compilation', passThrough),
    new OptionHandler('--minify', passThrough),
    new OptionHandler('--force-strip=.*', setStrip),
    // TODO(ahe): Remove the --no-colors option.
    new OptionHandler('--disable-diagnostic-colors',
                      (_) => enableColors = false),
    new OptionHandler('--enable-diagnostic-colors', (_) => enableColors = true),
    new OptionHandler('--enable[_-]checked[_-]mode|--checked',
                      (_) => passThrough('--enable-checked-mode')),
    new OptionHandler('--enable-concrete-type-inference',
                      (_) => passThrough('--enable-concrete-type-inference')),
    new OptionHandler(r'--help|/\?|/h', (_) => wantHelp = true),
    new OptionHandler('--package-root=.+|-p.+', setPackageRoot),
    new OptionHandler('--disallow-unsafe-eval', passThrough),
    // The following two options must come last.
    new OptionHandler('-.*', (String argument) {
      helpAndFail('Error: Unknown option "$argument".');
    }),
    new OptionHandler('.*', (String argument) {
      arguments.add(nativeToUriPath(argument));
    })
  ];

  parseCommandLine(handlers, argv);
  if (wantHelp) helpAndExit(verbose);

  if (outputLanguage != OUTPUT_LANGUAGE_DART && stripArgumentSet) {
    helpAndFail('Error: --force-strip may only be used with '
        '--output-type=dart');
  }
  if (arguments.isEmpty()) {
    helpAndFail('Error: No Dart file specified.');
  }
  if (arguments.length > 1) {
    var extra = arguments.getRange(1, arguments.length - 1);
    helpAndFail('Error: Extra arguments: ${Strings.join(extra, " ")}');
  }

  Map<String, SourceFile> sourceFiles = <String, SourceFile>{};
  int dartBytesRead = 0;

  Future<String> provider(Uri uri) {
    if (uri.scheme != 'file') {
      throw new ArgumentError(uri);
    }
    String source;
    try {
      source = readAll(uriPathToNative(uri.path));
    } on FileIOException catch (ex) {
      throw 'Error: Cannot read "${relativize(cwd, uri, isWindows)}" '
            '(${ex.osError}).';
    }
    dartBytesRead += source.length;
    sourceFiles[uri.toString()] =
      new SourceFile(relativize(cwd, uri, isWindows), source);
    return new Future.immediate(source);
  }

  void info(var message, [api.Diagnostic kind = api.Diagnostic.VERBOSE_INFO]) {
    if (!verbose && identical(kind, api.Diagnostic.VERBOSE_INFO)) return;
    if (enableColors) {
      print('${colors.green("info:")} $message');
    } else {
      print('info: $message');
    }
  }

  bool isAborting = false;

  final int FATAL = api.Diagnostic.CRASH.ordinal | api.Diagnostic.ERROR.ordinal;
  final int INFO =
      api.Diagnostic.INFO.ordinal | api.Diagnostic.VERBOSE_INFO.ordinal;

  void handler(Uri uri, int begin, int end, String message,
               api.Diagnostic kind) {
    if (identical(kind.name, 'source map')) {
      // TODO(podivilov): We should find a better way to return source maps from
      // emitter. Using diagnostic handler for that purpose is a temporary hack.
      writeString(sourceMapOut, message);
      return;
    }

    if (isAborting) return;
    isAborting = identical(kind, api.Diagnostic.CRASH);
    bool fatal = (kind.ordinal & FATAL) != 0;
    bool isInfo = (kind.ordinal & INFO) != 0;
    if (isInfo && uri == null && !identical(kind, api.Diagnostic.INFO)) {
      info(message, kind);
      return;
    }
    var color;
    if (!enableColors) {
      color = (x) => x;
    } else if (identical(kind, api.Diagnostic.ERROR)) {
      color = colors.red;
    } else if (identical(kind, api.Diagnostic.WARNING)) {
      color = colors.magenta;
    } else if (identical(kind, api.Diagnostic.LINT)) {
      color = colors.magenta;
    } else if (identical(kind, api.Diagnostic.CRASH)) {
      color = colors.red;
    } else if (identical(kind, api.Diagnostic.INFO)) {
      color = colors.green;
    } else {
      throw 'Unknown kind: $kind (${kind.ordinal})';
    }
    if (uri == null) {
      assert(fatal);
      print(color(message));
    } else if (fatal || showWarnings) {
      SourceFile file = sourceFiles[uri.toString()];
      if (file == null) {
        throw '$uri: file is null';
      }
      print(file.getLocationMessage(color(message), begin, end, true, color));
    }
    if (fatal && throwOnError) {
      isAborting = true;
      throw new AbortLeg(message);
    }
  }

  Uri uri = cwd.resolve(arguments[0]);
  if (packageRoot == null) {
    packageRoot = uri.resolve('./packages/');
  }

  info('package root is $packageRoot');

  // TODO(ahe): We expect the future to be complete and call value
  // directly. In effect, we don't support truly asynchronous API.
  String code = api.compile(uri, libraryRoot, packageRoot, provider, handler,
                            options).value;
  if (code == null) {
    fail('Error: Compilation failed.');
  }
  String sourceMapFileName =
      sourceMapOut.path.substring(sourceMapOut.path.lastIndexOf('/') + 1);
  code = '$code\n//@ sourceMappingURL=${sourceMapFileName}';
  writeString(out, code);
  int bytesWritten = code.length;
  info('compiled $dartBytesRead bytes Dart -> $bytesWritten bytes '
       '$outputLanguage in ${relativize(cwd, out, isWindows)}');
  if (!explicitOut) {
    String input = uriPathToNative(arguments[0]);
    String output = relativize(cwd, out, isWindows);
    print('Dart file $input compiled to $outputLanguage: $output');
  }
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
  var file = new File(uriPathToNative(uri.path)).openSync(FileMode.WRITE);
  file.writeStringSync(text);
  file.closeSync();
}

String readAll(String filename) {
  var file = (new File(filename)).openSync(FileMode.READ);
  var length = file.lengthSync();
  var buffer = new List<int>(length);
  var bytes = file.readListSync(buffer, 0, length);
  file.closeSync();
  return new String.fromCharCodes(new Utf8Decoder(buffer).decodeRest());
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

  --minify
    Generate minified output.

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

  --disallow-unsafe-eval
    Disables dynamic generation of code in the generated output. This is
    necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).
    This flag is not continuously tested. Please report breakages and we
    will fix them as soon as possible.''');
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

void main() {
  try {
    compilerMain(new Options());
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
