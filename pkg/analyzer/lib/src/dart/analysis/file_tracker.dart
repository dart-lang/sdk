// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:front_end/src/base/performance_logger.dart';

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
  final PerformanceLog _logger;

  /**
   * The current file system state.
   */
  final FileSystemState _fsState;

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
   * The set of files that are currently scheduled for analysis, which were
   * reported as changed through [changeFile].
   */
  var _pendingChangedFiles = new LinkedHashSet<String>();

  /**
   * The set of files that are currently scheduled for analysis, which directly
   * import a changed file.
   */
  var _pendingImportFiles = new LinkedHashSet<String>();

  /**
   * The set of files that are currently scheduled for analysis, which have an
   * error or a warning, which might be fixed by a changed file.
   */
  var _pendingErrorFiles = new LinkedHashSet<String>();

  /**
   * The set of files that are currently scheduled for analysis, and don't
   * have any special relation with changed files.
   */
  var _pendingFiles = new LinkedHashSet<String>();

  FileTracker(this._logger, this._fsState, this._changeHook);

  /**
   * Returns the path to exactly one that needs analysis.  Throws a [StateError]
   * if no files need analysis.
   */
  String get anyPendingFile {
    if (_pendingChangedFiles.isNotEmpty) {
      return _pendingChangedFiles.first;
    }
    if (_pendingImportFiles.isNotEmpty) {
      return _pendingImportFiles.first;
    }
    if (_pendingErrorFiles.isNotEmpty) {
      return _pendingErrorFiles.first;
    }
    return _pendingFiles.first;
  }

  /**
   * Returns a boolean indicating whether there are any files that have changed,
   * but for which the impact of the changes hasn't been measured.
   */
  bool get hasChangedFiles => _changedFiles.isNotEmpty;

  /**
   * Return `true` if there are changed files that need analysis.
   */
  bool get hasPendingChangedFiles => _pendingChangedFiles.isNotEmpty;

  /**
   * Return `true` if there are files that have an error or warning, and that
   * need analysis.
   */
  bool get hasPendingErrorFiles => _pendingErrorFiles.isNotEmpty;

  /**
   * Returns a boolean indicating whether there are any files that need
   * analysis.
   */
  bool get hasPendingFiles {
    return hasPendingChangedFiles ||
        hasPendingImportFiles ||
        hasPendingErrorFiles ||
        _pendingFiles.isNotEmpty;
  }

  /**
   * Return `true` if there are files that directly import a changed file that
   * need analysis.
   */
  bool get hasPendingImportFiles => _pendingImportFiles.isNotEmpty;

  /**
   * Returns a count of how many files need analysis.
   */
  int get numberOfPendingFiles {
    return _pendingChangedFiles.length +
        _pendingImportFiles.length +
        _pendingErrorFiles.length +
        _pendingFiles.length;
  }

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
      _pendingChangedFiles.add(path);
    }
    _changeHook();
  }

  /**
   * Removes the given [path] from the set of "pending files".
   *
   * Should be called after the client has analyzed a file.
   */
  void fileWasAnalyzed(String path) {
    _pendingChangedFiles.remove(path);
    _pendingImportFiles.remove(path);
    _pendingErrorFiles.remove(path);
    _pendingFiles.remove(path);
  }

  /**
   * Returns a boolean indicating whether the given [path] points to a file that
   * requires analysis.
   */
  bool isFilePending(String path) {
    return _pendingChangedFiles.contains(path) ||
        _pendingImportFiles.contains(path) ||
        _pendingErrorFiles.contains(path) ||
        _pendingFiles.contains(path);
  }

  /**
   * Removes the given [path] from the set of "added files".
   */
  void removeFile(String path) {
    addedFiles.remove(path);
    _pendingChangedFiles.remove(path);
    _pendingImportFiles.remove(path);
    _pendingErrorFiles.remove(path);
    _pendingFiles.remove(path);
    // TODO(paulberry): removing the path from [fsState] and re-analyzing all
    // files seems extreme.
    _fsState.removeFile(path);
    _pendingFiles.addAll(addedFiles);
    _changeHook();
  }

  /**
   * Verify the API signature for the file with the given [path], and decide
   * which linked libraries should be invalidated, and files reanalyzed.
   */
  FileState verifyApiSignature(String path) {
    return _logger.run('Verify API signature of $path', () {
      bool anyApiChanged = false;
      List<FileState> files = _fsState.getFilesForPath(path);
      for (FileState file in files) {
        bool apiChanged = file.refresh();
        if (apiChanged) {
          anyApiChanged = true;
        }
      }
      if (anyApiChanged) {
        _logger.writeln('API signatures mismatch found for $path');
        // TODO(scheglov) schedule analysis of only affected files
        var pendingChangedFiles = new LinkedHashSet<String>();
        var pendingImportFiles = new LinkedHashSet<String>();
        var pendingErrorFiles = new LinkedHashSet<String>();
        var pendingFiles = new LinkedHashSet<String>();

        // Add the changed file.
        if (addedFiles.contains(path)) {
          pendingChangedFiles.add(path);
        }

        // Add files that directly import the changed file.
        for (String addedPath in addedFiles) {
          FileState addedFile = _fsState.getFileForPath(addedPath);
          for (FileState changedFile in files) {
            if (addedFile.importedFiles.contains(changedFile)) {
              pendingImportFiles.add(addedPath);
            }
          }
        }

        // Add files with errors or warnings that might be fixed.
        for (String addedPath in addedFiles) {
          FileState addedFile = _fsState.getFileForPath(addedPath);
          if (addedFile.hasErrorOrWarning) {
            pendingErrorFiles.add(addedPath);
          }
        }

        // Add all previous pending files.
        pendingChangedFiles.addAll(_pendingChangedFiles);
        pendingImportFiles.addAll(_pendingImportFiles);
        pendingErrorFiles.addAll(_pendingErrorFiles);
        pendingFiles.addAll(_pendingFiles);

        // Add all the rest.
        pendingFiles.addAll(addedFiles);

        // Replace pending files.
        _pendingChangedFiles = pendingChangedFiles;
        _pendingImportFiles = pendingImportFiles;
        _pendingErrorFiles = pendingErrorFiles;
        _pendingFiles = pendingFiles;
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
      if (_fsState.knownFilePaths.contains(path)) {
        verifyApiSignature(path);
      }
      return true;
    }
    return false;
  }
}
