// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// New Compiler API. This API is under construction, use only internally or
/// in unittests.

library compiler_new;

import 'dart:async';

import 'compiler.dart' show Diagnostic;
import 'src/apiimpl.dart';
import 'src/options.dart' show CompilerOptions;

export 'compiler.dart' show Diagnostic, PackagesDiscoveryProvider;

// Unless explicitly allowed, passing `null` for any argument to the
// methods of library will result in an Error being thrown.

/// Input kinds used by [CompilerInput.readFromUri].
enum InputKind {
  /// Data is read as UTF8 either as a [String] or a zero-terminated
  /// `List<int>`.
  utf8,

  /// Data is read as bytes in a `List<int>`.
  binary,
}

/// Interface for data read through [CompilerInput.readFromUri].
abstract class Input<T> {
  /// The URI from which data was read.
  Uri get uri;

  /// The format of the read [data].
  InputKind get inputKind;

  /// The raw data read from [uri].
  T get data;
}

/// Interface for providing the compiler with input. That is, Dart source files,
/// package config files, etc.
abstract class CompilerInput {
  /// Returns a future that completes to the source corresponding to [uri].
  /// If an exception occurs, the future completes with this exception.
  ///
  /// If [inputKind] is `InputKind.utf8` the source can be represented either as
  /// a zero-terminated `List<int>` of UTF-8 bytes or as a [String]. If
  /// [inputKind] is `InputKind.binary` the source is a read a `List<int>`.
  ///
  /// The following text is non-normative:
  ///
  /// It is recommended to return a UTF-8 encoded list of bytes because the
  /// scanner is more efficient in this case. In either case, the data structure
  /// is expected to hold a zero element at the last position. If this is not
  /// the case, the entire data structure is copied before scanning.
  Future<Input> readFromUri(Uri uri, {InputKind inputKind: InputKind.utf8});
}

/// Output types used in `CompilerOutput.createOutputSink`.
enum OutputType {
  /// The main JavaScript output.
  js,

  /// A deferred JavaScript output part.
  jsPart,

  /// A source map for a JavaScript output.
  sourceMap,

  /// Serialization data output.
  serializationData,

  /// Additional information requested by the user, such dump info or a deferred
  /// map.
  info,

  /// Implementation specific output used for debugging the compiler.
  debug,
}

/// Sink interface used for generating output from the compiler.
abstract class OutputSink {
  /// Adds [text] to the sink.
  void add(String text);

  /// Closes the sink.
  void close();
}

/// Interface for producing output from the compiler. That is, JavaScript target
/// files, source map files, dump info files, etc.
abstract class CompilerOutput {
  /// Returns an [OutputSink] that will serve as compiler output for the given
  /// component.
  ///
  /// Components are identified by [name], [extension], and [type]. By
  /// convention, the empty string `""` will represent the main output of the
  /// provided [type]. [name] and [extension] are otherwise suggestive.
  // TODO(johnniwinther): Replace [name] and [extension] with something like
  // [id] and [uri].
  OutputSink createOutputSink(String name, String extension, OutputType type);
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
  void report(
      var code, Uri uri, int begin, int end, String text, Diagnostic kind);
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

  CompilerImpl compiler = new CompilerImpl(
      compilerInput, compilerOutput, compilerDiagnostics, compilerOptions);
  return compiler.run(compilerOptions.entryPoint).then((bool success) {
    return new CompilationResult(compiler, isSuccess: success);
  });
}
