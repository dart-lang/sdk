// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A stress test for the analysis server.
 */
library analysis_server.test.stress.replay.replay;

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../utilities/git.dart';
import '../utilities/server.dart';
import 'operation.dart';

/**
 * Run the simulation based on the given command-line [arguments].
 */
Future main(List<String> arguments) async {
  Driver driver = new Driver();
  await driver.run(arguments);
}

/**
 * The driver class that runs the simulation.
 */
class Driver {
  /**
   * The name of the command-line flag that will print help text.
   */
  static String HELP_FLAG_NAME = 'help';

  /**
   * The name of the pubspec file.
   */
  static const String PUBSPEC_FILE_NAME = 'pubspec.yaml';

  /**
   * The name of the branch used to clean-up after making temporary changes.
   */
  static const String TEMP_BRANCH_NAME = 'temp';

  /**
   * The absolute path of the repository.
   */
  String repositoryPath;

  /**
   * The absolute paths to the analysis roots.
   */
  List<String> analysisRoots;

  /**
   * The git repository.
   */
  GitRepository repository;

  /**
   * The connection to the analysis server.
   */
  Server server = new Server();

  /**
   * A list of the glob patterns used to identify the files being analyzed by
   * the server.
   */
  List<Glob> fileGlobs;

  /**
   * An object gathering statistics about the simulation.
   */
  Statistics statistics;

  /**
   * Initialize a newly created driver.
   */
  Driver() {
    statistics = new Statistics(this);
  }

  /**
   * Run the test based on the given command-line arguments ([args]).
   */
  Future run(List<String> args) async {
    //
    // Process the command-line arguments.
    //
    ArgParser parser = _createArgParser();
    ArgResults results;
    try {
      results = parser.parse(args);
    } catch (exception) {
      _showUsage(parser);
      return null;
    }

    if (results[HELP_FLAG_NAME]) {
      _showUsage(parser);
      return null;
    }

    List<String> arguments = results.arguments;
    if (arguments.length < 2) {
      _showUsage(parser);
      return null;
    }
    repositoryPath = path.normalize(arguments[0]);
    repository = new GitRepository(repositoryPath);

    analysisRoots = arguments
        .sublist(1)
        .map((String analysisRoot) => path.normalize(analysisRoot))
        .toList();
    for (String analysisRoot in analysisRoots) {
      if (repositoryPath != analysisRoot &&
          !path.isWithin(repositoryPath, analysisRoot)) {
        _showUsage(parser,
            'Analysis roots must be contained within the repository: $analysisRoot');
        return null;
      }
    }
    //
    // Replay the commit history.
    //
    Stopwatch stopwatch = new Stopwatch();
    statistics.stopwatch = stopwatch;
    stopwatch.start();
    await server.start();
    server.sendServerSetSubscriptions([ServerService.STATUS]);
    server.sendAnalysisSetGeneralSubscriptions(
        [GeneralAnalysisService.ANALYZED_FILES]);
    // TODO(brianwilkerson) Get the list of glob patterns from the server after
    // an API for getting them has been implemented.
    fileGlobs = <Glob>[
      new Glob(path.context.separator, '**.dart'),
      new Glob(path.context.separator, '**.html'),
      new Glob(path.context.separator, '**.htm'),
      new Glob(path.context.separator, '**/.analysisOptions')
    ];
    try {
      _replayChanges();
    } finally {
      server.sendServerShutdown();
      repository.checkout('master');
    }
    stopwatch.stop();
    //
    // Print out statistics gathered while performing the simulation.
    //
    statistics.print();
    return null;
  }

  /**
   * Create and return a parser that can be used to parse the command-line
   * arguments.
   */
  ArgParser _createArgParser() {
    ArgParser parser = new ArgParser();
    parser.addFlag(HELP_FLAG_NAME,
        abbr: 'h',
        help: 'Print usage information',
        defaultsTo: false,
        negatable: false);
    return parser;
  }

  void _createSourceEdits(FileEdit fileEdit, BlobDiff blobDiff) {
    LineInfo info = fileEdit.lineInfo;
    for (DiffHunk hunk in blobDiff.hunks) {
      List<SourceEdit> sourceEdits = <SourceEdit>[];
      int srcStart = info.getOffsetOfLine(hunk.srcLine);
      int srcEnd = info.getOffsetOfLine(hunk.srcLine + hunk.removeLines.length);
      // TODO(brianwilkerson) Create multiple edits instead of a single edit.
      sourceEdits.add(new SourceEdit(
          srcStart, srcEnd - srcStart + 1, _join(hunk.addLines)));
      fileEdit.addSourceEdits(sourceEdits);
    }
  }

  /**
   * Return athe absolute paths of all of the pubspec files in all of the
   * analysis roots.
   */
  Iterable<String> _findPubspecsInAnalysisRoots() {
    List<String> pubspecFiles = <String>[];
    for (String directoryPath in analysisRoots) {
      Directory directory = new Directory(directoryPath);
      List<FileSystemEntity> children =
          directory.listSync(recursive: true, followLinks: false);
      for (FileSystemEntity child in children) {
        String filePath = child.path;
        if (path.basename(filePath) == PUBSPEC_FILE_NAME) {
          pubspecFiles.add(filePath);
        }
      }
    }
    return pubspecFiles;
  }

  String _join(List<String> lines) {
    StringBuffer buffer = new StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      buffer.writeln(lines[i]);
    }
    return buffer.toString();
  }

  /**
   * Replay the changes in each commit.
   */
  void _replayChanges() {
    //
    // Get the revision history of the repo.
    //
    LinearCommitHistory history = repository.getCommitHistory();
    statistics.commitCount = history.commitIds.length;
    LinearCommitHistoryIterator iterator = history.iterator();
    //
    // Iterate over the history, applying changes.
    //
    bool firstCheckout = true;
//    Map<String, List<AnalysisError>> expectedErrors = null;
    Iterable<String> changedPubspecs;
    while (iterator.moveNext()) {
      //
      // Checkout the commit on which the changes are based.
      //
      repository.checkout(iterator.srcCommit);
//      if (expectedErrors != null) {
//        await server.analysisFinished;
//        server.expectErrorState(expectedErrors);
//      }
      if (firstCheckout) {
        changedPubspecs = _findPubspecsInAnalysisRoots();
        server.sendAnalysisSetAnalysisRoots(analysisRoots, []);
        firstCheckout = false;
      } else {
        server.removeAllOverlays();
      }
//      await server.analysisFinished;
//      expectedErrors = server.errorMap;
      for (String filePath in changedPubspecs) {
        _runPub(filePath);
      }
      //
      // Apply the changes.
      //
      CommitDelta commitDelta = iterator.next();
      commitDelta.filterDiffs(analysisRoots, fileGlobs);
      if (commitDelta.hasDiffs) {
        statistics.commitsWithChangeInRootCount++;
        _replayDiff(commitDelta);
      }
      changedPubspecs = commitDelta.filesMatching(PUBSPEC_FILE_NAME);
    }
    server.removeAllOverlays();
  }

  void _replayDiff(CommitDelta commitDelta) {
    List<FileEdit> editList = <FileEdit>[];
    for (DiffRecord record in commitDelta.diffRecords) {
      FileEdit edit = new FileEdit(record);
      _createSourceEdits(edit, record.getBlobDiff());
      editList.add(edit);
    }
    // TODO(brianwilkerson) Randomize.
    // Randomly select operations from different files to simulate a user
    // editing multiple files simultaneously.
    for (FileEdit edit in editList) {
      List<String> currentFile = <String>[edit.filePath];
      server.sendAnalysisSetPriorityFiles(currentFile);
      server.sendAnalysisSetSubscriptions({
        AnalysisService.FOLDING: currentFile,
        AnalysisService.HIGHLIGHTS: currentFile,
        AnalysisService.IMPLEMENTED: currentFile,
        AnalysisService.NAVIGATION: currentFile,
        AnalysisService.OCCURRENCES: currentFile,
        AnalysisService.OUTLINE: currentFile,
        AnalysisService.OVERRIDES: currentFile
      });
      for (ServerOperation operation in edit.getOperations()) {
        operation.perform(server);
      }
    }
  }

  /**
   * Run `pub` on the pubspec with the given [filePath].
   */
  void _runPub(String filePath) {
    String directoryPath = path.dirname(filePath);
    if (new Directory(directoryPath).existsSync()) {
      Process.runSync(
          '/Users/brianwilkerson/Dev/dart/dart-sdk/bin/pub', ['get'],
          workingDirectory: directoryPath);
    }
  }

  /**
   * Display usage information, preceeded by the [errorMessage] if one is given.
   */
  void _showUsage(ArgParser parser, [String errorMessage = null]) {
    if (errorMessage != null) {
      stderr.writeln(errorMessage);
      stderr.writeln();
    }
    stderr.writeln('''
Usage: replay [options...] repositoryPath analysisRoot...

Uses the commit history of the git repository at the given repository path to
simulate the development of a code base while using the analysis server to
analyze the code base.

The repository path must be the absolute path of a directory containing a git
repository.

There must be at least one analysis root, and all of the analysis roots must be
the absolute path of a directory contained within the repository directory. The
analysis roots represent the portion of the repository that will be analyzed by
the analysis server.

OPTIONS:''');
    stderr.writeln(parser.usage);
  }
}

/**
 * A representation of the edits to be applied to a single file.
 */
class FileEdit {
  /**
   * The absolute path of the file to be edited.
   */
  String filePath;

  /**
   * The content of the file before any edits have been applied.
   */
  String content;

  /**
   * The line info for the file before any edits have been applied.
   */
  LineInfo lineInfo;

  /**
   * The lists of source edits, one list for each hunk being edited.
   */
  List<List<SourceEdit>> editLists = <List<SourceEdit>>[];

  /**
   * Initialize a collection of edits to be associated with the file at the
   * given [filePath].
   */
  FileEdit(DiffRecord record) {
    filePath = record.srcPath;
    if (record.isAddition) {
      content = '';
      lineInfo = new LineInfo(<int>[0]);
    } else if (record.isCopy || record.isRename || record.isTypeChange) {
      throw new ArgumentError('Unhandled change of type ${record.status}');
    } else {
      content = new File(filePath).readAsStringSync();
      lineInfo = new LineInfo(StringUtilities.computeLineStarts(content));
    }
  }

  /**
   * Add a list of source edits that, taken together, transform a single hunk in
   * the file.
   */
  void addSourceEdits(List<SourceEdit> sourceEdits) {
    editLists.add(sourceEdits);
  }

  /**
   * Return a list of operations to be sent to the server.
   */
  List<ServerOperation> getOperations() {
    // TODO(brianwilkerson) Randomize.
    // Make the order of edits random. Doing so will require updating the
    // offsets of edits after the selected edit point.
    List<ServerOperation> operations = <ServerOperation>[];
    operations.add(
        new AnalysisUpdateContent(filePath, new AddContentOverlay(content)));
    for (List<SourceEdit> editList in editLists.reversed) {
      for (SourceEdit edit in editList.reversed) {
        operations.add(new AnalysisUpdateContent(
            filePath, new ChangeContentOverlay([edit])));
      }
    }
    operations
        .add(new AnalysisUpdateContent(filePath, new RemoveContentOverlay()));
    return operations;
  }
}

/**
 * A set of statistics related to the execution of the simulation.
 */
class Statistics {
  /**
   * The driver driving the simulation.
   */
  final Driver driver;

  /**
   * The stopwatch being used to time the simulation.
   */
  Stopwatch stopwatch;

  /**
   * The total number of commits in the repository.
   */
  int commitCount;

  /**
   * The number of commits in the repository that touched one of the files in
   * one of the analysis roots.
   */
  int commitsWithChangeInRootCount = 0;

  /**
   * Initialize a newly created set of statistics.
   */
  Statistics(this.driver);

  void print() {
    stdout.write('Replay commits in ');
    stdout.writeln(driver.repositoryPath);
    stdout.write('  replay took ');
    stdout.writeln(_printTime(stopwatch.elapsedMilliseconds));
    stdout.write('  analysis roots = ');
    stdout.writeln(driver.analysisRoots);
    stdout.write('  number of commits = ');
    stdout.writeln(commitCount);
    stdout.write('  number of commits with a change in an analysis root = ');
    stdout.writeln(commitsWithChangeInRootCount);
  }

  String _printTime(int milliseconds) {
    int seconds = milliseconds ~/ 1000;
    milliseconds -= seconds * 1000;
    int minutes = seconds ~/ 60;
    seconds -= minutes * 60;
    int hours = minutes ~/ 60;
    minutes -= hours * 60;

    if (hours > 0) {
      return '$hours:$minutes:$seconds.$milliseconds';
    } else if (minutes > 0) {
      return '$minutes:$seconds.$milliseconds m';
    } else if (seconds > 0) {
      return '$seconds.$milliseconds s';
    }
    return '$milliseconds ms';
  }
}
