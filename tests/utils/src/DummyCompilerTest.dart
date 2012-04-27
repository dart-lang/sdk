// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Smoke test of the dart2js compiler API.

#import('../../../lib/compiler/compiler.dart');
#import('dart:uri');

Future<String> provider(Uri uri) {
  Completer<String> completer = new Completer<String>();
  String source;
  if (uri.scheme == "main") {
    source = "main() {}";
  } else if (uri.scheme == "lib") {
    if (uri.path.endsWith("/core.dart")) {
      source = """#library('core');
                  class Object{}
                  class bool {}
                  class num {}
                  class int {}
                  class double{}
                  class String{}
                  class Function{}
                  class List {}
                  class Closure {}
                  class Dynamic {}
                  class Null {}
                  eqNull(a) {}
                  eqNullB(a) {}""";
    } else {
      source = "#library('lib');";
    }
  } else {
   throw "unexpected URI $uri";
  }
  completer.complete(source);
  return completer.future;
}

void handler(Uri uri, int begin, int end, String message, bool fatal) {
  print(message);
}

main() {
  String code = compile(new Uri(scheme: 'main'), new Uri(scheme: 'lib'),
                        provider, handler).value;
  if (code === null) {
    throw 'Compilation failed';
  }
}
