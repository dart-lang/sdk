// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Additions to Fasta for generating .dill (Kernel IR) files with dart2js patch
/// files and native hooks.
library compiler.src.kernel.fasta_support;

// TODO(sigmund): get rid of this file. Fasta should be agnostic of the
// target platform, at which point this should not be necessary. In particular,
// we need to:
//  - add a fasta flag to configure the platform library location.
//  - add a fasta flag to specify which sdk libraries should be built-in
//    (that would replace `loadExtraRequiredLibraries`).
//  - add flags to fasta to turn on various transformations.
//  - get rid of `native` in dart2js patches or unify the syntax with the VM.

import 'dart:async' show Future;
import 'dart:io' show exitCode;

import 'package:front_end/file_system.dart';
import 'package:front_end/physical_file_system.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:kernel/ast.dart' show Source, Library;
import 'package:kernel/target/targets.dart' show TargetFlags, NoneTarget;

import 'package:front_end/src/fasta/builder/builder.dart' show LibraryBuilder;
import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;
import 'package:front_end/src/fasta/fasta.dart' show CompileTask;
import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;
import 'package:front_end/src/fasta/loader.dart' show Loader;
import 'package:front_end/src/fasta/parser/parser.dart' show optional;
import 'package:front_end/src/fasta/source/source_loader.dart'
    show SourceLoader;
import 'package:front_end/src/scanner/token.dart' show Token;
import 'package:front_end/src/fasta/ticker.dart' show Ticker;
import 'package:front_end/src/fasta/translate_uri.dart' show TranslateUri;

import 'package:compiler/src/native/native.dart' show maybeEnableNative;

/// Generates a platform.dill file containing the compiled Kernel IR of the
/// dart2js SDK.
Future compilePlatform(Uri patchedSdk, Uri fullOutput,
    {Uri outlineOutput, Uri packages}) async {
  Uri deps = Uri.base.resolveUri(new Uri.file("${fullOutput.toFilePath()}.d"));
  TranslateUri uriTranslator = await TranslateUri
      .parse(PhysicalFileSystem.instance, patchedSdk, packages: packages);
  var ticker = new Ticker(isVerbose: false);
  var dillTarget = new DillTargetForDart2js(ticker, uriTranslator);
  var kernelTarget =
      new KernelTargetForDart2js(dillTarget, uriTranslator, false);

  kernelTarget.read(Uri.parse("dart:core"));
  await dillTarget.buildOutlines();
  var outline = await kernelTarget.buildOutlines();
  await writeProgramToFile(outline, outlineOutput);
  ticker.logMs("Wrote outline to ${outlineOutput.toFilePath()}");

  if (exitCode != 0) return null;
  var program = await kernelTarget.buildProgram();
  await writeProgramToFile(program, fullOutput);
  ticker.logMs("Wrote program to ${fullOutput.toFilePath()}");
  await kernelTarget.writeDepsFile(fullOutput, deps);
}

/// Extends the internal fasta [CompileTask] to use a dart2js-aware [DillTarget]
/// and [KernelTarget].
class Dart2jsCompileTask extends CompileTask {
  Dart2jsCompileTask(CompilerContext c, Ticker ticker) : super(c, ticker);

  @override
  DillTarget createDillTarget(TranslateUri uriTranslator) {
    return new DillTargetForDart2js(ticker, uriTranslator);
  }

  @override
  KernelTarget createKernelTarget(
      DillTarget dillTarget, TranslateUri uriTranslator, bool strongMode) {
    return new KernelTargetForDart2js(
        dillTarget, uriTranslator, strongMode, c.uriToSource);
  }
}

/// Specializes [KernelTarget] to build kernel for dart2js: no transformations
/// are run, JS-specific libraries are included in the SDK, and native clauses
/// have no string parameter.
class KernelTargetForDart2js extends KernelTarget {
  KernelTargetForDart2js(
      DillTarget target, TranslateUri uriTranslator, bool strongMode,
      [Map<String, Source> uriToSource])
      : super(PhysicalFileSystem.instance, target, uriTranslator, uriToSource);
  @override
  SourceLoader<Library> createLoader() =>
      new SourceLoaderForDart2js<Library>(fileSystem, this);

  @override
  bool enableNative(LibraryBuilder library) => maybeEnableNative(library.uri);

  @override
  Token skipNativeClause(Token token) => _skipNative(token);

  @override
  String extractNativeMethodName(Token token) => "";

  @override
  void loadExtraRequiredLibraries(Loader loader) => _loadExtras(loader);

  @override
  void runBuildTransformations() {}
}

/// Specializes [SourceLoader] to build kernel for dart2js: dart2js extends
/// bool, int, num, double, and String in a different platform library than
/// `dart:core`.
class SourceLoaderForDart2js<L> extends SourceLoader<L> {
  LibraryBuilder interceptorsLibrary;

  @override
  LibraryBuilder read(Uri uri, int charOffset,
      {Uri fileUri, LibraryBuilder accessor, bool isPatch: false}) {
    var library = super.read(uri, charOffset,
        fileUri: fileUri, accessor: accessor, isPatch: isPatch);
    if (uri.scheme == 'dart' && uri.path == '_interceptors') {
      interceptorsLibrary = library;
    }
    return library;
  }

  @override
  bool canImplementRestrictedTypes(LibraryBuilder library) =>
      library == coreLibrary || library == interceptorsLibrary;

  SourceLoaderForDart2js(FileSystem fs, KernelTarget target)
      : super(fs, target);
}

/// Specializes [DillTarget] to build kernel for dart2js: JS-specific libraries
/// are included in the SDK, and native clauses have no string parameter.
class DillTargetForDart2js extends DillTarget {
  DillTargetForDart2js(Ticker ticker, TranslateUri uriTranslator)
      : super(ticker, uriTranslator, new NoneTarget(new TargetFlags()));

  @override
  Token skipNativeClause(Token token) => _skipNative(token);

  @override
  String extractNativeMethodName(Token token) => "";

  @override
  void loadExtraRequiredLibraries(Loader loader) => _loadExtras(loader);
}

/// We use native clauses of this form in our dart2js patch files:
///
///     methodDeclaration() native;
///
/// The default front_end parser doesn't support this, so it will trigger an
/// error recovery condition. This function is used while parsing to detect this
/// form and continue parsing.
///
/// Note that `native` isn't part of the Dart Language Specification, and the VM
/// uses it a slightly different form. We hope to remove this syntax in our
/// dart2js patch files and replace it with the external modifier.
Token _skipNative(Token token) {
  if (!optional("native", token)) return null;
  if (!optional(";", token.next)) return null;
  return token;
}

void _loadExtras(Loader loader) {
  for (String uri in _extraDart2jsLibraries) {
    loader.read(Uri.parse(uri), -1);
  }
}

const _extraDart2jsLibraries = const <String>[
  'dart:_chrome',
  'dart:_foreign_helper',
  'dart:_interceptors',
  'dart:_internal',
  'dart:_isolate_helper',
  'dart:_js_embedded_names',
  'dart:_js_helper',
  'dart:_js_mirrors',
  'dart:_js_names',
  'dart:_native_typed_data',
  'dart:async',
  'dart:collection',
  'dart:html',
  'dart:html_common',
  'dart:indexed_db',
  'dart:js',
  'dart:js_util',
  'dart:mirrors',
  'dart:svg',
  'dart:web_audio',
  'dart:web_gl',
  'dart:web_sql',
];
