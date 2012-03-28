// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('compiler');

#import('../../lib/uri/uri.dart');
#import('implementation/apiimpl.dart');

// Unless explicitly allowed, passing null for any argument to the
// methods of library will result in a NullPointerException being
// thrown.

/**
 * Returns the source corresponding to [uri]. If no such source exists
 * or if an error occur while fetching it, this method must throw an
 * exception.
 */
typedef Future<String> ReadUriFromString(Uri uri);

/**
 * Invoked by the compiler to report diagnostics. If [uri] is null, so
 * is [begin] and [end]. No other arguments may be null. If [uri] is
 * not null, neither are [begin] and [end]. [uri] indicates the
 * compilation unit from where the diagnostic originates. [begin] and
 * [end] are zero-based character offsets from the beginning of the
 * compilaton unit. [message] is the diagnostic message, and [fatal]
 * indicates whether or not this diagnostic will prevent the compiler
 * from returning null.
 */
typedef void DiagnosticHandler(Uri uri, int begin, int end,
                               String message, bool fatal);

/**
 * Returns [script] compiled to JavaScript. If the compilation fails,
 * null is returned and [handler] will have been invoked at least once
 * with [:fatal == true:].
 */
Future<String> compile(Uri script,
                       Uri libraryRoot,
                       ReadUriFromString provider,
                       DiagnosticHandler handler,
                       [List<String> options = const []]) {
  Compiler compiler = new Compiler(provider, handler, libraryRoot, options);
  compiler.run(script);
  String code = compiler.assembledCode;
  Completer<String> completer = new Completer<String>();
  completer.complete(code);
  return completer.future;
}
