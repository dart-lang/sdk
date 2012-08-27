// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('compiler');

#import('dart:uri');
#import('implementation/apiimpl.dart');

// Unless explicitly allowed, passing [:null:] for any argument to the
// methods of library will result in a NullPointerException being
// thrown.

/**
 * Returns a future that completes to the source corresponding to
 * [uri]. If an exception occurs, the future completes with this
 * exception.
 */
typedef Future<String> ReadStringFromUri(Uri uri);

/**
 * Invoked by the compiler to report diagnostics. If [uri] is
 * [:null:], so are [begin] and [end]. No other arguments may be
 * [:null:]. If [uri] is not [:null:], neither are [begin] and
 * [end]. [uri] indicates the compilation unit from where the
 * diagnostic originates. [begin] and [end] are zero-based character
 * offsets from the beginning of the compilaton unit. [message] is the
 * diagnostic message, and [kind] indicates indicates what kind of
 * diagnostic it is.
 */
typedef void DiagnosticHandler(Uri uri, int begin, int end,
                               String message, Diagnostic kind);

/**
 * Returns a future that completes to [script] compiled to JavaScript. If
 * the compilation fails, the future's value will be [:null:] and
 * [handler] will have been invoked at least once with [:kind ==
 * Diagnostic.ERROR:] or [:kind == Diagnostic.CRASH:].
 */
Future<String> compile(Uri script,
                       Uri libraryRoot,
                       Uri packageRoot,
                       ReadStringFromUri provider,
                       DiagnosticHandler handler,
                       [List<String> options = const []]) {
  // TODO(ahe): Consider completing the future with an exception if
  // code is null.
  Compiler compiler = new Compiler(provider, handler, libraryRoot, packageRoot,
                                   options);
  compiler.run(script);
  String code = compiler.assembledCode;
  return new Future.immediate(code);
}

/**
 * Kind of diagnostics that the compiler can report.
 */
class Diagnostic {
  /**
   * An error as identified by the "Dart Programming Language
   * Specification" [http://www.dartlang.org/docs/spec/].
   *
   * Note: the compiler may still produce an executable result after
   * reporting a compilation error. The specification says:
   *
   * "A compile-time error must be reported by a Dart compiler before
   * the erroneous code is executed." and "If a compile-time error
   * occurs within the code of a running isolate A, A is immediately
   * suspended."
   *
   * This means that the compiler can generate code that when executed
   * terminates execution.
   */
  static const Diagnostic ERROR = const Diagnostic(1, 'error');

  /**
   * A warning as identified by the "Dart Programming Language
   * Specification" [http://www.dartlang.org/docs/spec/].
   */
  static const Diagnostic WARNING = const Diagnostic(2, 'warning');

  /**
   * Any other warning that is not covered by [WARNING].
   */
  static const Diagnostic LINT = const Diagnostic(4, 'lint');

  /**
   * Informational messages.
   */
  static const Diagnostic INFO = const Diagnostic(8, 'info');

  /**
   * Informational messages that shouldn't be printed unless
   * explicitly requested by the user of a compiler.
   */
  static const Diagnostic VERBOSE_INFO = const Diagnostic(16, 'verbose info');

  /**
   * An internal error in the compiler.
   */
  static const Diagnostic CRASH = const Diagnostic(32, 'crash');

  /**
   * An [int] representation of this kind. The ordinals are designed
   * to be used as bitsets.
   */
  final int ordinal;

  /**
   * The name of this kind.
   */
  final String name;

  /**
   * This constructor is not private to support user-defined
   * diagnostic kinds.
   */
  const Diagnostic(this.ordinal, this.name);

  String toString() => name;
}
