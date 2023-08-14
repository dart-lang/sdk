// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler;

import 'dart:async';

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import 'src/compiler.dart';
import 'src/options.dart';

/// Kind of diagnostics that the compiler can report.
class Diagnostic {
  /// An error as identified by the "Dart Programming Language
  /// Specification" [https://dart.dev/guides/language/spec].
  ///
  /// Note: the compiler may still produce an executable result after
  /// reporting a compilation error. The specification says:
  ///
  /// "A compile-time error must be reported by a Dart compiler before
  /// the erroneous code is executed." and "If a compile-time error
  /// occurs within the code of a running isolate A, A is immediately
  /// suspended."
  ///
  /// This means that the compiler can generate code that when executed
  /// terminates execution.
  static const Diagnostic ERROR = const Diagnostic(1, 'error');

  /// A warning as identified by the "Dart Programming Language
  /// Specification" [https://dart.dev/guides/language/spec].
  static const Diagnostic WARNING = const Diagnostic(2, 'warning');

  /// Any other warning that is not covered by [WARNING].
  static const Diagnostic HINT = const Diagnostic(4, 'hint');

  /// Informational message about the compiler.
  static const Diagnostic INFO = const Diagnostic(8, 'info');

  /// Informational messages that shouldn't be printed unless
  /// explicitly requested by the user of a compiler.
  static const Diagnostic VERBOSE_INFO = const Diagnostic(16, 'verbose info');

  /// An internal error in the compiler.
  static const Diagnostic CRASH = const Diagnostic(32, 'crash');

  /// Additional information about the preceding non-info diagnostic from the
  /// compiler.
  ///
  /// For example, consider a duplicated definition. The compiler first emits a
  /// message about the duplicated definition, then emits an info message about
  /// the location of the existing definition.
  static const Diagnostic CONTEXT = const Diagnostic(64, 'context');

  /// An [int] representation of this kind. The ordinals are designed
  /// to be used as bitsets.
  final int ordinal;

  /// The name of this kind.
  final String name;

  /// This constructor is not private to support user-defined
  /// diagnostic kinds.
  const Diagnostic(this.ordinal, this.name);

  @override
  String toString() => name;
}

// Unless explicitly allowed, passing `null` for any argument to the
// methods of library will result in an Error being thrown.

/// Input kinds used by [CompilerInput.readFromUri].
enum InputKind {
  /// Data is read as UTF8 either as a [String] or a zero-terminated
  /// `List<int>`.
  UTF8,

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

  /// Release any resources held by the input. After releasing, a call to `get
  /// data` will fail, and previously returned data may be invalid.
  void release();
}

/// Interface for providing the compiler with input. That is, Dart source files,
/// package config files, etc.
abstract class CompilerInput {
  /// Returns a future that completes to the source corresponding to [uri].
  /// If an exception occurs, the future completes with this exception.
  ///
  /// If [inputKind] is `InputKind.UTF8` the source is represented as a
  /// zero-terminated list of encoded bytes. If the input kind is
  /// `InputKind.binary` the resulting list is the raw bytes from the input
  /// source.
  Future<Input<List<int>>> readFromUri(Uri uri,
      {InputKind inputKind = InputKind.UTF8});

  /// Register that [uri] should be an `InputKind.UTF8` input with the
  /// given [source] as its zero-terminated list of contents.
  ///
  /// If [uri] was read prior to this call, this registration has no effect,
  /// otherwise it is expected that a future [readFromUri] will return the
  /// contents provided here.
  ///
  /// The main purpose of this API is to assist in error reporting when
  /// compiling from kernel binary files. Binary files embed the contents
  /// of source files that may not be available on disk. By using these
  /// registered contents, dart2js will be able to provide accurate line/column
  /// information on an error.
  void registerUtf8ContentsForDiagnostics(Uri uri, List<int> source);
}

/// Output types used in `CompilerOutput.createOutputSink`.
enum OutputType {
  /// The main JavaScript output.
  js,

  /// A deferred JavaScript output part.
  jsPart,

  /// A source map for a JavaScript output.
  sourceMap,

  /// Dump info output.
  dumpInfo,

  /// Deferred map output.
  deferredMap,

  /// Unused libraries output.
  dumpUnusedLibraries,

  /// Resource identifiers output.
  resourceIdentifiers,

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

/// Sink interface used for generating binary data from the compiler.
abstract class BinaryOutputSink {
  /// Writes indices [start] to [end] of [buffer] to the sink.
  void write(List<int> buffer, [int start = 0, int? end]);

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

  /// Returns an [BinaryOutputSink] that will serve as compiler output for the
  /// given URI.
  BinaryOutputSink createBinarySink(Uri uri);
}

/// Interface for receiving diagnostic message from the compiler. That is,
/// errors, warnings, hints, etc.
abstract class CompilerDiagnostics {
  /// Invoked by the compiler to report diagnostics. If [uri] is `null`, so are
  /// [begin] and [end]. No other arguments may be `null`. If [uri] is not
  /// `null`, neither are [begin] and [end]. [uri] indicates the compilation
  /// unit from where the diagnostic originates. [begin] and [end] are
  /// zero-based character offsets from the beginning of the compilation unit.
  /// [message] is the diagnostic message, and [kind] indicates what
  /// kind of diagnostic it is.
  ///
  /// Experimental: [code] gives access to an id for the messages. Currently it
  /// is the [Message] used to create the diagnostic, if available, from which
  /// the [MessageKind] is accessible.
  void report(
      var code, Uri? uri, int? begin, int? end, String text, Diagnostic kind);
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

  /// Shared state between compilations.
  ///
  /// This is used to speed up batch mode.
  final fe.InitializedCompilerState? kernelInitializedCompilerState;

  CompilationResult(this.compiler,
      {this.isSuccess = true, this.kernelInitializedCompilerState});
}

// Unless explicitly allowed, passing [:null:] for any argument to the
// methods of library will result in an Error being thrown.

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
  var compiler = Compiler(
      compilerInput, compilerOutput, compilerDiagnostics, compilerOptions);
  return compiler.run().then((bool success) {
    return CompilationResult(compiler,
        isSuccess: success,
        kernelInitializedCompilerState: compiler.initializedCompilerState);
  });
}
