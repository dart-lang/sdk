// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dart2js');

#import('dart:io');
#import('dart:uri');
#import('dart:utf');

#import('../compiler.dart', prefix: 'api');
#import('colors.dart', prefix: 'colors');
#import('source_file.dart');
#import('filenames.dart');
#import('util/uri_extras.dart');

final String LIBRARY_ROOT = '../../../..';

typedef void HandleOption(String option);

class OptionHandler {
  String pattern;
  HandleOption handle;

  OptionHandler(this.pattern, this.handle);
}

String extractParameter(String argument) {
  return argument.substring(argument.indexOf('=') + 1);
}

void parseCommandLine(List<OptionHandler> handlers, List<String> argv) {
  var patterns = <String>[];
  for (OptionHandler handler in handlers) {
    patterns.add(handler.pattern);
  }
  var pattern = new RegExp('^(${Strings.join(patterns, ")|(")})\$');
  assert(pattern.groupCount() == handlers.length);
  OUTER: for (String argument in argv) {
    Match match = pattern.firstMatch(argument);
    for (int i = 0; i < handlers.length; i++) {
      if (match[i + 1] !== null) {
        handlers[i].handle(argument);
        continue OUTER;
      }
    }
    throw 'Internal error: "$argument" did not match';
  }
}

void compile(List<String> argv) {
  Uri cwd = getCurrentDirectory();
  bool throwOnError = false;
  bool showWarnings = true;
  bool verbose = false;
  Uri libraryRoot = cwd;
  Uri out = cwd.resolve('out.js');
  List<String> options = new List<String>();

  passThrough(String argument) => options.add(argument);

  List<String> arguments = <String>[];
  List<OptionHandler> handlers = <OptionHandler>[
    new OptionHandler('--throw-on-error', (_) => throwOnError = true),
    new OptionHandler('--suppress-warnings', (_) => showWarnings = false),
    new OptionHandler('--verbose', (_) => verbose = true),
    new OptionHandler('--library-root=.*', (String argument) {
      String path = nativeToUriPath(extractParameter(argument));
      if (!path.endsWith("/")) path = "$path/";
      libraryRoot = cwd.resolve(path);
    }),
    new OptionHandler('--out=.*', (String argument) {
      out = cwd.resolve(nativeToUriPath(extractParameter(argument)));
    }),
    new OptionHandler('--allow-mock-compilation', passThrough),
    new OptionHandler('--no-colors', (_) => colors.enabled = false),
    new OptionHandler('--enable-checked-mode|--checked|-c',
                      (_) => passThrough('--enable_checked_mode')),
    new OptionHandler('--help', (_) => helpAndExit()),
    // The following two options must come last.
    new OptionHandler('-.*', (String argument) {
      fail('Error: unknown option "$argument".');
    }),
    new OptionHandler('.*', (String argument) {
      arguments.add(nativeToUriPath(argument));
    })
  ];

  parseCommandLine(handlers, argv);

  if (arguments.isEmpty()) {
    helpAndFail('Error: no file to compile.');
  }
  if (arguments.length > 1) {
    var extra = arguments.getRange(1, arguments.length - 1);
    helpAndFail('Error: extra arguments: ${Strings.join(extra, " ")}');
  }

  Map<String, SourceFile> sourceFiles = <SourceFile>{};
  int dartBytesRead = 0;

  Future<String> provider(Uri uri) {
    if (uri.scheme != 'file') {
      throw new IllegalArgumentException(uri);
    }
    String source = readAll(uriPathToNative(uri.path));
    dartBytesRead += source.length;
    sourceFiles[uri.toString()] =
      new SourceFile(relativize(cwd, uri), source);
    Completer<String> completer = new Completer<String>();
    completer.complete(source);
    return completer.future;
  }

  void info(var message) {
    if (verbose) print('${colors.green("info:")} $message');
  }

  void handler(Uri uri, int begin, int end, String message, bool fatal) {
    if (uri === null && !fatal) {
      info(message);
      return;
    }
    if (uri === null) {
      assert(fatal);
      print(message);
    } else if (fatal || showWarnings) {
      SourceFile file = sourceFiles[uri.toString()];
      print(file.getLocationMessage(message, begin, end, true));
    }
    if (fatal && throwOnError) throw new AbortLeg(message);
  }

  Uri uri = cwd.resolve(arguments[0]);
  info('compiling $uri');

  // TODO(ahe): We expect the future to be complete and call value
  // directly. In effect, we don't support truly asynchronous API.
  String code = api.compile(uri, libraryRoot, provider, handler, options).value;
  if (code === null) {
    fail('Error: compilation failed.');
  }
  writeString(out, code);
  int jsBytesWritten = code.length;
  info('compiled $dartBytesRead bytes Dart -> $jsBytesWritten bytes JS '
       + 'in ${relativize(cwd, out)}');
}

class AbortLeg {
  final message;
  AbortLeg(this.message);
  toString() => 'Aborted due to --throw-on-error: $message';
}

void writeString(Uri uri, String text) {
  if (uri.scheme != 'file') {
    fail('Error: unhandled scheme ${uri.scheme}.');
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
  // This message should be no longer than 22 lines. The default
  // terminal size normally 80x24. Two lines are used for the prompts
  // before and after running the compiler.
  print('''
dart2js [OPTIONS...] DART-FILE

A Dart to JavaScript compiler.

By default, the compiled JavaScript code is saved to a file named
out.js in the current directory.

Common options:

  --help      Display this message.

  --out=FILE  Save the output to FILE (default is out.js).

  --checked   Turn on checked mode in generated JavaScript code.
''');
}

void helpAndExit() {
  help();
  exit(0);
}

void helpAndFail(String message) {
  help();
  fail(message);
}

void main() {
  try {
    compilerMain(new Options());
  } catch (var exception, var trace) {
    try {
      print('Internal error: $exception');
    } catch (var ignored) {
      print('Internal error: error while printing exception');
    }
    try {
      print(trace);
    } finally {
      exit(253); // 253 is recognized as a crash by our test scripts.
    }
  }
}
