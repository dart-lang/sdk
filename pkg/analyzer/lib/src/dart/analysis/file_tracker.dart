// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Callback used by [FileTracker] to report to its client that files have been
 * added, changed, or removed, and therefore more analysis may be necessary.
 */
typedef void FileTrackerChangeHook();

/**
 * Maintains the file system state needed by the analysis driver, as well as
 * information about files that have changed and the impact of those changes.
 *
 * Three related sets of files are tracked: "added files" is the set of files
 * for which the client would like analysis.  "changed files" is the set of
 * files which is known to have changed, but for which we have not yet measured
 * the impact of the change.  "pending files" is the subset of "added files"
 * which might have been impacted by a change, and thus need analysis.
 *
 * Provides methods for updating the file system state in response to changes.
 */
class FileTracker {
  /**
   * Callback invoked whenever a change occurs that may require the client to
   * perform analysis.
   */
  final FileTrackerChangeHook _changeHook;

  /**
   * The logger to write performed operations and performance to.
   */
  final PerformanceLog logger;

  /**
   * The current file system state.
   */
  final FileSystemState fsState;

  /**
   * The set of added files.
   */
  final addedFiles = new LinkedHashSet<String>();

  /**
   * The set of files were reported as changed through [changeFile] and not
   * checked for actual changes yet.
   */
  final _changedFiles = new LinkedHashSet<String>();

  /**
   * The set of files that are currently scheduled for analysis.
   */
  final _pendingFiles = new LinkedHashSet<String>();

  FileTracker(
      this.logger,
      ByteStore byteStore,
      FileContentOverlay contentOverlay,
      ResourceProvider resourceProvider,
      SourceFactory sourceFactory,
      AnalysisOptions analysisOptions,
      Uint32List salt,
      this._changeHook)
      : fsState = new FileSystemState(logger, byteStore, contentOverlay,
            resourceProvider, sourceFactory, analysisOptions, salt);

  /**
   * Returns the path to exactly one that needs analysis.  Throws a [StateError]
   * if no files need analysis.
   */
  String get anyPendingFile => _pendingFiles.first;

  /**
   * Returns a boolean indicating whether there are any files that have changed,
   * but for which the impact of the changes hasn't been measured.
   */
  bool get hasChangedFiles => _changedFiles.isNotEmpty;

  /**
   * Returns a boolean indicating whether there are any files that need
   * analysis.
   */
  bool get hasPendingFiles => _pendingFiles.isNotEmpty;

  /**
   * Returns a count of how many files need analysis.
   */
  int get numberOfPendingFiles => _pendingFiles.length;

  /**
   * Adds the given [path] to the set of "added files".
   */
  void addFile(String path) {
    addedFiles.add(path);
    _pendingFiles.add(path);
    _changeHook();
  }

  /**
   * Adds the given [paths] to the set of "added files".
   */
  void addFiles(Iterable<String> paths) {
    addedFiles.addAll(paths);
    _pendingFiles.addAll(paths);
    _changeHook();
  }

  /**
   * Adds the given [path] to the set of "changed files".
   */
  void changeFile(String path) {
    _changedFiles.add(path);
    if (addedFiles.contains(path)) {
      _pendingFiles.add(path);
    }
    _changeHook();
  }

  /**
   * Removes the given [path] from the set of "pending files".
   *
   * Should be called after the client has analyzed a file.
   */
  void fileWasAnalyzed(String path) {
    _pendingFiles.remove(path);
  }

  /**
   * Returns a boolean indicating whether the given [path] points to a file that
   * requires analysis.
   */
  bool isFilePending(String path) => _pendingFiles.contains(path);

  /**
   * Removes the given [path] from the set of "added files".
   */
  void removeFile(String path) {
    addedFiles.remove(path);
    _pendingFiles.remove(path);
    // TODO(paulberry): removing the path from [fsState] and re-analyzing all
    // files seems extreme.
    fsState.removeFile(path);
    _pendingFiles.addAll(addedFiles);
    _changeHook();
  }

  /**
   * Verify the API signature for the file with the given [path], and decide
   * which linked libraries should be invalidated, and files reanalyzed.
   */
  FileState verifyApiSignature(String path) {
    return logger.run('Verify API signature of $path', () {
      bool anyApiChanged = false;
      List<FileState> files = fsState.getFilesForPath(path);
      for (FileState file in files) {
        bool apiChanged = file.refresh();
        if (apiChanged) {
          anyApiChanged = true;
        }
      }
      if (anyApiChanged) {
        logger.writeln('API signatures mismatch found for $path');
        // TODO(scheglov) schedule analysis of only affected files
        _pendingFiles.addAll(addedFiles);
      }
      return files[0];
    });
  }

  /**
   * If at least one file is in the "changed files" set, determines the impact
   * of the change, updates the set of pending files, and returns `true`.
   *
   * If no files are in the "changed files" set, returns `false`.
   */
  bool verifyChangedFilesIfNeeded() {
    // Verify all changed files one at a time.
    if (_changedFiles.isNotEmpty) {
      String path = _changedFiles.first;
      _changedFiles.remove(path);
      // If the file has not been accessed yet, we either will eventually read
      // it later while analyzing one of the added files, or don't need it.
      if (fsState.knownFilePaths.contains(path)) {
        verifyApiSignature(path);
      }
      return true;
    }
    return false;
  }
}
