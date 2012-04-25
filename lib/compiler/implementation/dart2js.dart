// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dart2js');

#import('dart:io');
#import('dart:uri');
#import('dart:utf');

#import('../compiler.dart', prefix: 'api');
#import('colors.dart');
#import('source_file.dart');
#import('filenames.dart');
#import('util/uri_extras.dart');

void compile(List<String> argv) {
  Uri cwd = getCurrentDirectory();
  bool throwOnError = false;
  bool showWarnings = true;
  bool verbose = false;
  Uri libraryRoot = cwd;
  Uri out = cwd.resolve('out.js');
  List<String> options = new List<String>();

  List<String> arguments = <String>[];
  for (String argument in argv) {
    if ('--throw-on-error' == argument) {
      throwOnError = true;
    } else if ('--suppress-warnings' == argument) {
      showWarnings = false;
    } else if ('--verbose' == argument) {
      verbose = true;
    } else if (argument.startsWith('--library-root=')) {
      String path =
          nativeToUriPath(argument.substring(argument.indexOf('=') + 1));
      if (!path.endsWith("/")) path = "$path/";
      libraryRoot = cwd.resolve(path);
    } else if (argument.startsWith('--out=')) {
      String path =
          nativeToUriPath(argument.substring(argument.indexOf('=') + 1));
      out = cwd.resolve(path);
    } else if (argument == '--allow-mock-compilation') {
      options.add(argument);
    } else if (argument.startsWith('-')) {
      fail('Unknown option $argument.');
    } else {
      arguments.add(nativeToUriPath(argument));
    }
  }
  if (arguments.isEmpty()) {
    fail('No files to compile.');
  }
  if (arguments.length > 1) {
    var extra = arguments.getRange(1, arguments.length - 1);
    fail('Extra arguments: $extra.');
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
    if (verbose) print('${green("info:")} $message');
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
    fail('Compilation failed.');
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
    fail('Unhandled scheme ${uri.scheme}.');
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
