// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * This class computes [AnalysisResult]s for Dart files.
 */
class AnalysisDriver {
  /**
   * The byte storage to get and put serialized data.
   *
   * It can be shared between other [AnalysisDriver]s.
   */
  final ByteStore _byteStore;

  /**
   * The [SourceFactory] is used to resolve URIs to paths and restore URIs
   * from file paths.
   */
  final SourceFactory _sourceFactory;

  /**
   * This [ContentCache] is consulted for a file content before reading
   * the content from the file.
   */
  final ContentCache _contentCache;

  AnalysisDriver(this._byteStore, this._sourceFactory, this._contentCache);

  /**
   * Set the list of files that the driver should try to analyze sooner.
   *
   * Every path in the list must be absolute and normalized.
   *
   * The driver will produce the results through the [results] stream. The
   * exact order in which results are produced is not defined, neither
   * between priority files, not between them and not priority files.
   */
  void set priorityFiles(List<String> priorityPaths) {
    // TODO(scheglov) implement
  }

  /**
   * Return the [Stream] that produces [AnalysisResult]s for added files.
   *
   * Analysis starts when the client starts listening to the stream, and stops
   * when the client cancels the subscription.
   *
   * Analysis is eventual, the driver will try to produce results that are at
   * some point more consistent with the state of the files, but does not
   * guarantee that this will ever happen.
   *
   * More than one result might be produced for the same file, even if the
   * client does not change the state of the files.
   *
   * Results might be produced even for files that have never been added
   * using [addFile], for example when [getResult] was called for a file.
   */
  Stream<AnalysisResult> get results async* {
    // TODO(scheglov) implement
  }

  /**
   * Add the file with the given [path] to the set of files to analyze.
   *
   * The [path] must be absolute and normalized.
   *
   * The results of analysis are eventually produced by the [results] stream.
   */
  void addFile(String path) {
    // TODO(scheglov) implement
  }

  /**
   * The file with the given [path] might have changed - updated, added or
   * removed. Or not, we don't know. Or it might have, but then changed back.
   *
   * The [path] must be absolute and normalized.
   *
   * The driver might use this information to decide that new analysis results
   * should be produced, but does not guarantee this, nor for the given file,
   * nor for any other file.
   *
   * Invocation of this method will not prevent a [Future] returned from
   * [getResult] from completing with a result, and does not guarantee that the
   * result will reflect the state of the file at the moment before, at or
   * after the invocation of [changeFile].
   */
  void changeFile(String path) {
    // TODO(scheglov) implement
  }

  /**
   * Return the [Future] that completes with a [AnalysisResult] for the file
   * with the given [path].
   *
   * The [path] must be absolute and normalized.
   *
   * The result is not guaranteed to be produced for the state of the file
   * which is closest to the moment of the invocation. But if the client
   * continues invoking this method, eventually one of the invocations will
   * return a [Future] that completes with the result that is closer to the
   * state of the files.
   */
  Future<AnalysisResult> getResult(String path) {
    // TODO(scheglov) implement
    throw new UnimplementedError();
  }

  /**
   * Remove the file with the given [path] from the list of files to analyze.
   *
   * The [path] must be absolute and normalized.
   *
   * The results of analysis of the file might still be produced by the
   * [results] stream. The driver will try to stop producing these results,
   * but does not guarantee this.
   */
  void removeFile(String path) {
    // TODO(scheglov) implement
  }
}

/**
 * The result of analyzing of a single file.
 *
 * These results are self-consistent, i.e. [content], [contentHash], the
 * resolved [unit] correspond to each other. All referenced elements, even
 * external ones, are also self-consistent. But none of the results is
 * guaranteed to be consistent with the state of the files.
 *
 * Every result is independent, and is not guaranteed to be consistent with
 * any previously returned result, even inside of the same library.
 */
class AnalysisResult {
  /**
   * The path of the analysed file, absolute and normalized.
   */
  final String path;

  /**
   * The URI of the file that corresponded to the [path] in the used
   * [SourceFactory] at some point. Is it not guaranteed to be still consistent
   * to the [path], and provided as FYI.
   */
  final Uri uri;

  /**
   * The content of the file that was scanned, parsed and resolved.
   */
  final String content;

  /**
   * The MD5 hash of the [content].
   */
  final String contentHash;

  /**
   * The fully resolved compilation unit for the [content].
   */
  final CompilationUnit unit;

  /**
   * The full list of computed analysis errors, both syntactic and semantic.
   */
  final List<AnalysisError> errors;

  AnalysisResult(this.path, this.uri, this.content, this.contentHash, this.unit,
      this.errors);
}
