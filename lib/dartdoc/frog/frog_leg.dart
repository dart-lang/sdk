// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('frog_leg');

#import('dart:io');
#import('dart:uri');

#import('lang.dart', prefix: 'frog');
#import('../../compiler/compiler.dart', prefix: 'compiler');
#import('../../compiler/implementation/filenames.dart');
#import('../../compiler/implementation/util/uri_extras.dart');

bool compile(frog.World world) {
  final throwOnError = frog.options.throwOnErrors;
  final showWarnings = frog.options.showWarnings;
  final allowMockCompilation = frog.options.allowMockCompilation;
  Uri cwd = getCurrentDirectory();
  Uri uri = cwd.resolve(nativeToUriPath(frog.options.dartScript));
  String frogLibDir = nativeToUriPath(frog.options.libDir);
  if (!frogLibDir.endsWith("/")) frogLibDir = "$frogLibDir/";
  Uri frogLib = new Uri(scheme: 'file', path: frogLibDir);
  Uri libraryRoot = frogLib.resolve('../../');
  Map<String, frog.SourceFile> sourceFiles = <frog.SourceFile>{};

  Future<String> provider(Uri uri) {
    if (uri.scheme != 'file') {
      throw new IllegalArgumentException(uri);
    }
    String source = world.files.readAll(uriPathToNative(uri.path));
    world.dartBytesRead += source.length;
    sourceFiles[uri.toString()] =
      new frog.SourceFile(relativize(cwd, uri), source);
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
      frog.SourceFile file = sourceFiles[uri.toString()];
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
