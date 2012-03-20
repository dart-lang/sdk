// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dart2js');

#import('dart:io');
#import('dart:utf');

#import('../../lib/uri/uri.dart');
#import('../../frog/leg/api.dart', prefix: 'api');
#import('../../frog/leg/io/io.dart', prefix: 'io');
#import('../../frog/leg/colors.dart');
#import('source_file.dart');

String relativize(Uri base, Uri uri) {
  if (base.scheme == 'file' &&
      base.scheme == uri.scheme &&
      base.userInfo == uri.userInfo &&
      base.domain == uri.domain &&
      base.port == uri.port &&
      uri.query == "" && uri.fragment == "") {
    if (uri.path.startsWith(base.path)) {
      return uri.path.substring(base.path.length);
    }
    List<String> uriParts = uri.path.split('/');
    List<String> baseParts = base.path.split('/');
    int common = 0;
    int length = Math.min(uriParts.length, baseParts.length);
    while (common < length && uriParts[common] == baseParts[common]) {
      common++;
    }
    StringBuffer sb = new StringBuffer();
    for (int i = common + 1; i < baseParts.length; i++) {
      sb.add('../');
    }
    for (int i = common; i < uriParts.length - 1; i++) {
      sb.add('${uriParts[i]}/');
    }
    sb.add('${uriParts.last()}');
    return sb.toString();
  }
  return uri.toString();
}

void compile(List<String> argv) {
  Uri cwd = new Uri(scheme: 'file', path: io.getCurrentDirectory());
  bool throwOnError = false;
  bool showWarnings = true;
  bool verbose = false;
  Uri libraryRoot = cwd;
  Uri out = cwd.resolve('out.js');

  List<String> arguments = <String>[];
  for (String argument in argv) {
    if ('--throw-on-error' == argument) {
      throwOnError = true;
    } else if ('--suppress-warnings' == argument) {
      showWarnings = false;
    } else if ('--verbose' == argument) {
      verbose = true;
    } else if (argument.startsWith('--library-root=')) {
      String path = argument.substring(argument.indexOf('=') + 1);
      if (!path.endsWith("/")) path = "$path/";
      libraryRoot = cwd.resolve(path);
    } else if (argument.startsWith('--out=')) {
      String path = argument.substring(argument.indexOf('=') + 1);
      out = cwd.resolve(path);
    } else if (argument.startsWith('-')) {
      throw new AbortLeg('unknown option $argument');
    } else {
      arguments.add(argument);
    }
  }
  if (arguments.isEmpty()) {
    throw new AbortLeg('no files to compile');
  }
  if (arguments.length > 1) {
    var extra = arguments.getRange(1, arguments.length - 1);
    throw new AbortLeg('extra arguments: $extra');
  }

  Map<String, SourceFile> sourceFiles = <SourceFile>{};
  int dartBytesRead = 0;

  Future<String> provider(Uri uri) {
    if (uri.scheme != 'file') {
      throw new IllegalArgumentException(uri);
    }
    String source = readAll(uri.path);
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
  String code = api.compile(uri, libraryRoot, provider, handler).value;
  if (code === null) throw new AbortLeg('compilation failed');
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
    throw new AbortLeg('unhandled scheme ${uri.scheme}');
  }
  var file = new File(uri.path).openSync(FileMode.WRITE);
  file.writeStringSync(text);
  file.closeSync();
}

String readAll(String filename) {
  var file = (new File(filename)).openSync();
  var length = file.lengthSync();
  var buffer = new List<int>(length);
  var bytes = file.readListSync(buffer, 0, length);
  file.closeSync();
  return new String.fromCharCodes(new Utf8Decoder(buffer).decodeRest());
}
