// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('frog_leg');

#import('../../uri/uri.dart');
#import('source_file.dart');
#import('../../../frog/lang.dart', prefix: 'frog');
#import('../compiler.dart', prefix: 'compiler');
#import('io/io.dart', prefix: 'io');

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

bool compile(frog.World world) {
  final throwOnError = frog.options.throwOnErrors;
  final showWarnings = frog.options.showWarnings;
  final allowMockCompilation = frog.options.allowMockCompilation;
  Uri cwd = new Uri(scheme: 'file', path: io.getCurrentDirectory());
  Uri uri = cwd.resolve(frog.options.dartScript);
  String frogLibDir = frog.options.libDir;
  if (!frogLibDir.endsWith("/")) frogLibDir = "$frogLibDir/";
  Uri frogLib = new Uri(scheme: 'file', path: frogLibDir);
  Uri libraryRoot = frogLib.resolve('../../lib/compiler/implementation/lib/');
  Map<String, SourceFile> sourceFiles = <SourceFile>{};

  Future<String> provider(Uri uri) {
    if (uri.scheme != 'file') {
      throw new IllegalArgumentException(uri);
    }
    String source = world.files.readAll(uri.path);
    world.dartBytesRead += source.length;
    sourceFiles[uri.toString()] =
      new SourceFile(relativize(cwd, uri), source);
    Completer<String> completer = new Completer<String>();
    completer.complete(source);
    return completer.future;
  }

  void handler(Uri uri, int begin, int end, String message, bool fatal) {
    if (uri === null && !fatal) {
      world.info('[leg] $message');
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

  List<String> options = new List<String>();
  if (allowMockCompilation) options.add('--allow-mock-compilation');

  // TODO(ahe): We expect the future to be complete and call value
  // directly. In effect, we don't support truly asynchronous API.
  String code =
    compiler.compile(uri, libraryRoot, provider, handler, options).value;
  if (code === null) return false;
  world.legCode = code;
  world.jsBytesWritten = code.length;
  return true;
}

class AbortLeg {
  final message;
  AbortLeg(this.message);
  toString() => 'Aborted due to --throw-on-error: $message';
}
