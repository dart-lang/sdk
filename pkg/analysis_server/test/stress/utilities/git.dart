// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for interacting with a git repository.
 */
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/util/glob.dart';
import 'package:path/path.dart' as path;

import 'logger.dart';

/**
 * A representation of the differences between two blobs.
 */
class BlobDiff {
  /**
   * The regular expression used to identify the beginning of a hunk.
   */
  static final RegExp hunkHeaderRegExp =
      new RegExp(r'@@ -([0-9]+)(?:,[0-9]+)? \+([0-9]+)(?:,[0-9]+)? @@');

  /**
   * A list of the hunks in the diff.
   */
  List<DiffHunk> hunks = <DiffHunk>[];

  /**
   * Initialize a newly created blob diff by parsing the result of the git diff
   * command (the [input]).
   *
   * This is only intended to be invoked from [GitRepository.getBlobDiff].
   */
  BlobDiff._(List<String> input) {
    _parseInput(input);
  }

  /**
   * Parse the result of the git diff command (the [input]).
   */
  void _parseInput(List<String> input) {
    for (String line in input) {
      _parseLine(line);
    }
  }

  /**
   * Parse a single [line] from the result of the git diff command.
   */
  void _parseLine(String line) {
    DiffHunk currentHunk = hunks.isEmpty ? null : hunks.last;
    if (line.startsWith('@@')) {
      Match match = hunkHeaderRegExp.matchAsPrefix(line);
      int srcLine = int.parse(match.group(1));
      int dstLine = int.parse(match.group(2));
      hunks.add(new DiffHunk(srcLine, dstLine));
    } else if (currentHunk != null && line.startsWith('+')) {
      currentHunk.addLines.add(line.substring(1));
    } else if (currentHunk != null && line.startsWith('-')) {
      currentHunk.removeLines.add(line.substring(1));
    }
  }
}

/**
 * A representation of the differences between two commits.
 */
class CommitDelta {
  /**
   * The length (in characters) of a SHA.
   */
  static final int SHA_LENGTH = 40;

  /**
   * The code-point for a colon (':').
   */
  static final int COLON = ':'.codeUnitAt(0);

  /**
   * The code-point for a nul character.
   */
  static final int NUL = 0;

  /**
   * The code-point for a tab.
   */
  static final int TAB = '\t'.codeUnitAt(0);

  /**
   * The repository from which the commits were taken.
   */
  final GitRepository repository;

  /**
   * The records of the files that were changed.
   */
  final List<DiffRecord> diffRecords = <DiffRecord>[];

  /**
   * Initialize a newly created representation of the differences between two
   * commits. The differences are computed by parsing the result of a git diff
   * command (the [diffResults]).
   *
   * This is only intended to be invoked from [GitRepository.getBlobDiff].
   */
  CommitDelta._(this.repository, String diffResults) {
    _parseInput(diffResults);
  }

  /**
   * Return `true` if there are differences.
   */
  bool get hasDiffs => diffRecords.isNotEmpty;

  /**
   * Return the absolute paths of all of the files in this commit whose name
   * matches the given [fileName].
   */
  Iterable<String> filesMatching(String fileName) {
    return diffRecords
        .where((DiffRecord record) => record.isFor(fileName))
        .map((DiffRecord record) => record.srcPath);
  }

  /**
   * Remove any diffs for files that are either (a) outside the given
   * [inclusionPaths], or (b) are files that do not match one of the given
   * [globPatterns].
   */
  void filterDiffs(List<String> inclusionPaths, List<Glob> globPatterns) {
    diffRecords.retainWhere((DiffRecord record) {
      String filePath = record.srcPath ?? record.dstPath;
      for (String inclusionPath in inclusionPaths) {
        if (path.isWithin(inclusionPath, filePath)) {
          for (Glob glob in globPatterns) {
            if (glob.matches(filePath)) {
              return true;
            }
          }
        }
      }
      return false;
    });
  }

  /**
   * Return the index of the first nul character in the given [string] that is
   * at or after the given [start] index.
   */
  int _findEnd(String string, int start) {
    int length = string.length;
    int end = start;
    while (end < length && string.codeUnitAt(end) != NUL) {
      end++;
    }
    return end;
  }

  /**
   * Return the result of converting the given [relativePath] to an absolute
   * path. The path is assumed to be relative to the root of the repository.
   */
  String _makeAbsolute(String relativePath) {
    return path.join(repository.path, relativePath);
  }

  /**
   * Parse all of the diff records in the given [input].
   */
  void _parseInput(String input) {
    int length = input.length;
    int start = 0;
    while (start < length) {
      start = _parseRecord(input, start);
    }
  }

  /**
   * Parse a single record from the given [input], assuming that the record
   * starts at the given [startIndex].
   *
   * Each record is formatted as a sequence of fields. The fields are, from the
   * left to the right:
   *
   * 1. a colon.
   * 2. mode for "src"; 000000 if creation or unmerged.
   * 3. a space.
   * 4. mode for "dst"; 000000 if deletion or unmerged.
   * 5. a space.
   * 6. sha1 for "src"; 0{40} if creation or unmerged.
   * 7. a space.
   * 8. sha1 for "dst"; 0{40} if creation, unmerged or "look at work tree".
   * 9. a space.
   * 10. status, followed by optional "score" number.
   * 11. a tab or a NUL when -z option is used.
   * 12. path for "src"
   * 13. a tab or a NUL when -z option is used; only exists for C or R.
   * 14. path for "dst"; only exists for C or R.
   * 15. an LF or a NUL when -z option is used, to terminate the record.
   */
  int _parseRecord(String input, int startIndex) {
    // Skip the first five fields.
    startIndex += 15;
    // Parse field 6
    String srcSha = input.substring(startIndex, startIndex + SHA_LENGTH);
    startIndex += SHA_LENGTH + 1;
    // Parse field 8
    String dstSha = input.substring(startIndex, startIndex + SHA_LENGTH);
    startIndex += SHA_LENGTH + 1;
    // Parse field 10
    int endIndex = _findEnd(input, startIndex);
    String status = input.substring(startIndex, endIndex);
    startIndex = endIndex + 1;
    // Parse field 12
    endIndex = _findEnd(input, startIndex);
    String srcPath = _makeAbsolute(input.substring(startIndex, endIndex));
    startIndex = endIndex + 1;
    // Parse field 14
    String dstPath = null;
    if (status.startsWith('C') || status.startsWith('R')) {
      endIndex = _findEnd(input, startIndex);
      dstPath = _makeAbsolute(input.substring(startIndex, endIndex));
    }
    // Create the record.
    diffRecords.add(
        new DiffRecord(repository, srcSha, dstSha, status, srcPath, dstPath));
    return endIndex + 1;
  }
}

/**
 * Representation of a single diff hunk.
 */
class DiffHunk {
  /**
   * The index of the first line that was changed in the src as returned by the
   * diff command. The diff command numbers lines starting at 1, but it
   * subtracts 1 from the line number if there are no lines on the source side
   * of the hunk.
   */
  int diffSrcLine;

  /**
   * The index of the first line that was changed in the dst as returned by the
   * diff command. The diff command numbers lines starting at 1, but it
   * subtracts 1 from the line number if there are no lines on the destination
   * side of the hunk.
   */
  int diffDstLine;

  /**
   * A list of the individual lines that were removed from the src.
   */
  List<String> removeLines = <String>[];

  /**
   * A list of the individual lines that were added to the dst.
   */
  List<String> addLines = <String>[];

  /**
   * Initialize a newly created hunk. The lines will be added after the object
   * has been created.
   */
  DiffHunk(this.diffSrcLine, this.diffDstLine);

  /**
   * Return the index of the first line that was changed in the dst. Unlike the
   * [diffDstLine] field, this getter adjusts the line number to be consistent
   * whether or not there were any changed lines.
   */
  int get dstLine {
    return addLines.isEmpty ? diffDstLine : diffDstLine - 1;
  }

  /**
   * Return the index of the first line that was changed in the src. Unlike the
   * [diffDstLine] field, this getter adjusts the line number to be consistent
   * whether or not there were any changed lines.
   */
  int get srcLine {
    return removeLines.isEmpty ? diffSrcLine : diffSrcLine - 1;
  }
}

/**
 * A representation of a single line (record) from a raw diff.
 */
class DiffRecord {
  /**
   * The repository containing the file(s) that were modified.
   */
  final GitRepository repository;

  /**
   * The SHA1 of the blob in the src.
   */
  final String srcBlob;

  /**
   * The SHA1 of the blob in the dst.
   */
  final String dstBlob;

  /**
   * The status of the change. Valid values are:
   * * A: addition of a file
   * * C: copy of a file into a new one
   * * D: deletion of a file
   * * M: modification of the contents or mode of a file
   * * R: renaming of a file
   * * T: change in the type of the file
   * * U: file is unmerged (you must complete the merge before it can be committed)
   * * X: "unknown" change type (most probably a bug, please report it)
   *
   * Status letters C and R are always followed by a score (denoting the
   * percentage of similarity between the source and target of the move or
   * copy), and are the only ones to be so.
   */
  final String status;

  /**
   * The path of the src.
   */
  final String srcPath;

  /**
   * The path of the dst if this was either a copy or a rename operation.
   */
  final String dstPath;

  /**
   * Initialize a newly created diff record.
   */
  DiffRecord(this.repository, this.srcBlob, this.dstBlob, this.status,
      this.srcPath, this.dstPath);

  /**
   * Return `true` if this record represents a file that was added.
   */
  bool get isAddition => status == 'A';

  /**
   * Return `true` if this record represents a file that was copied.
   */
  bool get isCopy => status.startsWith('C');

  /**
   * Return `true` if this record represents a file that was deleted.
   */
  bool get isDeletion => status == 'D';

  /**
   * Return `true` if this record represents a file that was modified.
   */
  bool get isModification => status == 'M';

  /**
   * Return `true` if this record represents a file that was renamed.
   */
  bool get isRename => status.startsWith('R');

  /**
   * Return `true` if this record represents an entity whose type was changed
   * (for example, from a file to a directory).
   */
  bool get isTypeChange => status == 'T';

  /**
   * Return a representation of the individual blobs within this diff.
   */
  BlobDiff getBlobDiff() => repository.getBlobDiff(srcBlob, dstBlob);

  /**
   * Return `true` if this diff applies to a file with the given name.
   */
  bool isFor(String fileName) =>
      (srcPath != null && fileName == path.basename(srcPath)) ||
      (dstPath != null && fileName == path.basename(dstPath));

  @override
  String toString() => srcPath ?? dstPath;
}

/**
 * A representation of a git repository.
 */
class GitRepository {
  /**
   * The absolute path of the directory containing the repository.
   */
  final String path;

  /**
   * The logger to which git commands should be written, or `null` if the
   * commands should not be written.
   */
  final Logger logger;

  /**
   * Initialize a newly created repository to represent the git repository at
   * the given [path].
   *
   * If a [commandSink] is provided, any calls to git will be written to it.
   */
  GitRepository(this.path, {this.logger = null});

  /**
   * Checkout the given [commit] from the repository. This is done by running
   * the command `git checkout <sha>`.
   */
  void checkout(String commit) {
    _run(['checkout', commit]);
  }

  /**
   * Return details about the differences between the two blobs identified by
   * the SHA1 of the [srcBlob] and the SHA1 of the [dstBlob]. This is done by
   * running the command `git diff <blob> <blob>`.
   */
  BlobDiff getBlobDiff(String srcBlob, String dstBlob) {
    ProcessResult result = _run(['diff', '-U0', srcBlob, dstBlob]);
    List<String> diffResults = LineSplitter.split(result.stdout).toList();
    return new BlobDiff._(diffResults);
  }

  /**
   * Return details about the differences between the two commits identified by
   * the [srcCommit] and [dstCommit]. This is done by running the command
   * `git diff --raw --no-abbrev --no-renames -z <sha> <sha>`.
   */
  CommitDelta getCommitDiff(String srcCommit, String dstCommit) {
    // Consider --find-renames instead of --no-renames if rename information is
    // desired.
    ProcessResult result = _run([
      'diff',
      '--raw',
      '--no-abbrev',
      '--no-renames',
      '-z',
      srcCommit,
      dstCommit
    ]);
    return new CommitDelta._(this, result.stdout);
  }

  /**
   * Return a representation of the history of this repository. This is done by
   * running the command `git rev-list --first-parent HEAD`.
   */
  LinearCommitHistory getCommitHistory() {
    ProcessResult result = _run(['rev-list', '--first-parent', 'HEAD']);
    List<String> commitIds = LineSplitter.split(result.stdout).toList();
    return new LinearCommitHistory(this, commitIds);
  }

  /**
   * Synchronously run the given [executable] with the given [arguments]. Return
   * the result of running the process.
   */
  ProcessResult _run(List<String> arguments) {
    logger?.log('git', 'git', arguments: arguments);
    return Process.runSync('git', arguments,
        stderrEncoding: UTF8, stdoutEncoding: UTF8, workingDirectory: path);
  }
}

/**
 * A representation of the history of a Git repository. This only represents a
 * single linear path in the history graph.
 */
class LinearCommitHistory {
  /**
   * The repository whose history is being represented.
   */
  final GitRepository repository;

  /**
   * The id's (SHA's) of the commits in the repository, with the most recent
   * commit being first and the oldest commit being last.
   */
  final List<String> commitIds;

  /**
   * Initialize a commit history for the given [repository] to have the given
   * [commitIds].
   */
  LinearCommitHistory(this.repository, this.commitIds);

  /**
   * Return an iterator that can be used to iterate over this commit history.
   */
  LinearCommitHistoryIterator iterator() {
    return new LinearCommitHistoryIterator(this);
  }
}

/**
 * An iterator over the history of a Git repository.
 */
class LinearCommitHistoryIterator {
  /**
   * The commit history being iterated over.
   */
  final LinearCommitHistory history;

  /**
   * The index of the current commit in the list of [commitIds].
   */
  int currentCommit;

  /**
   * Initialize a newly created iterator to iterate over the commits with the
   * given [commitIds];
   */
  LinearCommitHistoryIterator(this.history) {
    currentCommit = history.commitIds.length;
  }

  /**
   * Return the SHA1 of the commit after the current commit (the 'dst' of the
   * [next] diff).
   */
  String get dstCommit => history.commitIds[currentCommit - 1];

  /**
   * Return the SHA1 of the current commit (the 'src' of the [next] diff).
   */
  String get srcCommit => history.commitIds[currentCommit];

  /**
   * Advance to the next commit in the history. Return `true` if it is safe to
   * ask for the [next] diff.
   */
  bool moveNext() {
    if (currentCommit <= 1) {
      return false;
    }
    currentCommit--;
    return true;
  }

  /**
   * Return the difference between the current commit and the commit that
   * followed it.
   */
  CommitDelta next() => history.repository.getCommitDiff(srcCommit, dstCommit);
}
