// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// New Compiler API. This API is under construction, use only internally or
/// in unittests.

library compiler_new;

import 'dart:async';
import 'src/apiimpl.dart';
import 'compiler.dart' show Diagnostic, PackagesDiscoveryProvider;
export 'compiler.dart' show Diagnostic, PackagesDiscoveryProvider;

// Unless explicitly allowed, passing `null` for any argument to the
// methods of library will result in an Error being thrown.

/// Interface for providing the compiler with input. That is, Dart source files,
/// package config files, etc.
abstract class CompilerInput {
  /// Returns a future that completes to the source corresponding to [uri].
  /// If an exception occurs, the future completes with this exception.
  ///
  /// The source can be represented either as a [:List<int>:] of UTF-8 bytes or
  /// as a [String].
  ///
  /// The following text is non-normative:
  ///
  /// It is recommended to return a UTF-8 encoded list of bytes because the
  /// scanner is more efficient in this case. In either case, the data structure
  /// is expected to hold a zero element at the last position. If this is not
  /// the case, the entire data structure is copied before scanning.
  Future/*<String | List<int>>*/ readFromUri(Uri uri);
}

/// Interface for producing output from the compiler. That is, JavaScript target
/// files, source map files, dump info files, etc.
abstract class CompilerOutput {
  /// Returns an [EventSink] that will serve as compiler output for the given
  ///  component.
  ///
  ///  Components are identified by [name] and [extension]. By convention,
  /// the empty string [:"":] will represent the main script
  /// (corresponding to the script parameter of [compile]) even if the
  /// main script is a library. For libraries that are compiled
  /// separately, the library name is used.
  ///
  /// At least the following extensions can be expected:
  ///
  /// * "js" for JavaScript output.
  /// * "js.map" for source maps.
  /// * "dart" for Dart output.
  /// * "dart.map" for source maps.
  ///
  /// As more features are added to the compiler, new names and
  /// extensions may be introduced.
  EventSink<String> createEventSink(String name, String extension);
}

/// Interface for receiving diagnostic message from the compiler. That is,
/// errors, warnings, hints, etc.
abstract class CompilerDiagnostics {
  /// Invoked by the compiler to report diagnostics. If [uri] is `null`, so are
  /// [begin] and [end]. No other arguments may be `null`. If [uri] is not
  /// `null`, neither are [begin] and [end]. [uri] indicates the compilation
  /// unit from where the diagnostic originates. [begin] and [end] are
  /// zero-based character offsets from the beginning of the compilation unit.
  /// [message] is the diagnostic message, and [kind] indicates indicates what
  /// kind of diagnostic it is.
  ///
  /// Experimental: [code] gives access to an id for the messages. Currently it
  /// is the [Message] used to create the diagnostic, if available, from which
  /// the [MessageKind] is accessible.
  void report(var code,
              Uri uri, int begin, int end, String text, Diagnostic kind);
}

/// Information resulting from the compilation.
class CompilationResult {
  /// `true` if the compilation succeeded, that is, compilation didn't fail due
  /// to compile-time errors and/or internal errors.
  final bool isSuccess;

  /// The compiler object used for the compilation.
  ///
  /// Note: The type of [compiler] is implementation dependent and may vary.
  /// Use only for debugging and testing.
  final compiler;

  CompilationResult(this.compiler, {this.isSuccess: true});
}

/// Object for passing options to the compiler.
class CompilerOptions {
  final Uri entryPoint;
  final Uri libraryRoot;
  final Uri packageRoot;
  final Uri packageConfig;
  final PackagesDiscoveryProvider packagesDiscoveryProvider;
  final List<String> options;
  final Map<String, dynamic> environment;

  /// Creates an option object for the compiler.
  // TODO(johnniwinther): Expand comment when [options] are explicit as named
  // arguments.
  factory CompilerOptions(
      {Uri entryPoint,
       Uri libraryRoot,
       Uri packageRoot,
       Uri packageConfig,
       PackagesDiscoveryProvider packagesDiscoveryProvider,
       List<String> options: const <String>[],
       Map<String, dynamic> environment: const <String, dynamic>{}}) {
    if (entryPoint == null) {
      throw new ArgumentError("entryPoint must be non-null");
    }
    if (!libraryRoot.path.endsWith("/")) {
      throw new ArgumentError("libraryRoot must end with a /");
    }
    if (packageRoot != null && !packageRoot.path.endsWith("/")) {
      throw new ArgumentError("packageRoot must end with a /");
    }
    return new CompilerOptions._(
        entryPoint,
        libraryRoot,
        packageRoot,
        packageConfig,
        packagesDiscoveryProvider,
        options,
        environment);
  }

  CompilerOptions._(
      this.entryPoint,
      this.libraryRoot,
      this.packageRoot,
      this.packageConfig,
      this.packagesDiscoveryProvider,
      this.options,
      this.environment);
}

/// Returns a future that completes to a [CompilationResult] when the Dart
/// sources in [options] have been compiled.
///
/// The generated compiler output is obtained by providing a [compilerOutput].
///
/// If the compilation fails, the future's `CompilationResult.isSuccess` is
/// `false` and [CompilerDiagnostics.report] on [compilerDiagnostics]
/// is invoked at least once with `kind == Diagnostic.ERROR` or
/// `kind == Diagnostic.CRASH`.
Future<CompilationResult> compile(
    CompilerOptions compilerOptions,
    CompilerInput compilerInput,
    CompilerDiagnostics compilerDiagnostics,
    CompilerOutput compilerOutput) {

  if (compilerOptions == null) {
    throw new ArgumentError("compilerOptions must be non-null");
  }
  if (compilerInput == null) {
    throw new ArgumentError("compilerInput must be non-null");
  }
  if (compilerDiagnostics == null) {
    throw new ArgumentError("compilerDiagnostics must be non-null");
  }
  if (compilerOutput == null) {
    throw new ArgumentError("compilerOutput must be non-null");
  }

  Compiler compiler = new Compiler(
      compilerInput,
      compilerOutput,
      compilerDiagnostics,
      compilerOptions.libraryRoot,
      compilerOptions.packageRoot,
      compilerOptions.options,
      compilerOptions.environment,
      compilerOptions.packageConfig,
      compilerOptions.packagesDiscoveryProvider);
  return compiler.run(compilerOptions.entryPoint).then((bool success) {
    return new CompilationResult(compiler, isSuccess: success);
  });
}
