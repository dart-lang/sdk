// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler;

import 'dart:async';
import 'implementation/apiimpl.dart';

// Unless explicitly allowed, passing [:null:] for any argument to the
// methods of library will result in an Error being thrown.

/**
 * Returns a future that completes to the source corresponding to [uri].
 * If an exception occurs, the future completes with this exception.
 *
 * The source can be represented either as a [:List<int>:] of UTF-8 bytes or as
 * a [String].
 *
 * The following text is non-normative:
 *
 * It is recommended to return a UTF-8 encoded list of bytes because the scanner
 * is more efficient in this case. In either case, the data structure is
 * expected to hold a zero element at the last position. If this is not the
 * case, the entire data structure is copied before scanning.
 */
typedef Future/*<String | List<int>>*/ CompilerInputProvider(Uri uri);

/// Deprecated, please use [CompilerInputProvider] instead.
typedef Future<String> ReadStringFromUri(Uri uri);

/**
 * Returns an [EventSink] that will serve as compiler output for the given
 * component.
 *
 * Components are identified by [name] and [extension]. By convention,
 * the empty string [:"":] will represent the main script
 * (corresponding to the script parameter of [compile]) even if the
 * main script is a library. For libraries that are compiled
 * separately, the library name is used.
 *
 * At least the following extensions can be expected:
 *
 * * "js" for JavaScript output.
 * * "js.map" for source maps.
 * * "dart" for Dart output.
 * * "dart.map" for source maps.
 *
 * As more features are added to the compiler, new names and
 * extensions may be introduced.
 */
typedef EventSink<String> CompilerOutputProvider(String name,
                                                 String extension);

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
 * Returns a future that completes to a non-null String when [script]
 * has been successfully compiled.
 *
 * The compiler output is obtained by providing an [outputProvider].
 *
 * If the compilation fails, the future's value will be [:null:] and
 * [handler] will have been invoked at least once with [:kind ==
 * Diagnostic.ERROR:] or [:kind == Diagnostic.CRASH:].
 *
 * Deprecated: if no [outputProvider] is given, the future completes
 * to the compiled script. This behavior will be removed in the future
 * as the compiler may create multiple files to support lazy loading
 * of libraries.
 */
Future<String> compile(Uri script,
                       Uri libraryRoot,
                       Uri packageRoot,
                       CompilerInputProvider inputProvider,
                       DiagnosticHandler handler,
                       [List<String> options = const [],
                        CompilerOutputProvider outputProvider,
                        Map<String, dynamic> environment = const {}]) {
  if (!libraryRoot.path.endsWith("/")) {
    throw new ArgumentError("libraryRoot must end with a /");
  }
  if (packageRoot != null && !packageRoot.path.endsWith("/")) {
    throw new ArgumentError("packageRoot must end with a /");
  }
  // TODO(ahe): Consider completing the future with an exception if
  // code is null.
  Compiler compiler = new Compiler(inputProvider,
                                   outputProvider,
                                   handler,
                                   libraryRoot,
                                   packageRoot,
                                   options,
                                   environment);
  // TODO(ahe): Use the value of the future (which signals success or failure).
  return compiler.run(script).then((_) {
    String code = compiler.assembledCode;
    if (code != null && outputProvider != null) {
      code = ''; // Non-null signals success.
    }
    return code;
  });
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
  static const Diagnostic HINT = const Diagnostic(4, 'hint');

  /**
   * Additional information about the preceding non-info diagnostic from the
   * compiler.
   *
   * For example, consider a duplicated definition. The compiler first emits a
   * message about the duplicated definition, then emits an info message about
   * the location of the existing definition.
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
