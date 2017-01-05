// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A stress test for the analysis server.
 */
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart' as error;
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../utilities/git.dart';
import '../utilities/logger.dart';
import '../utilities/server.dart';
import 'operation.dart';

/**
 * Run the simulation based on the given command-line [arguments].
 */
Future<Null> main(List<String> arguments) async {
  Driver driver = new Driver();
  await driver.run(arguments);
}

/**
 * The driver class that runs the simulation.
 */
class Driver {
  /**
   * The value of the [OVERLAY_STYLE_OPTION_NAME] indicating that modifications
   * to a file should be represented by an add overlay, followed by zero or more
   * change overlays, followed by a remove overlay.
   */
  static String CHANGE_OVERLAY_STYLE = 'change';

  /**
   * The name of the command-line flag that will print help text.
   */
  static String HELP_FLAG_NAME = 'help';

  /**
   * The value of the [OVERLAY_STYLE_OPTION_NAME] indicating that modifications
   * to a file should be represented by an add overlay, followed by zero or more
   * additional add overlays, followed by a remove overlay.
   */
  static String MULTIPLE_ADD_OVERLAY_STYLE = 'multipleAdd';

  /**
   * The name of the command-line option used to specify the style of
   * interaction to use when making `analysis.updateContent` requests.
   */
  static String OVERLAY_STYLE_OPTION_NAME = 'overlay-style';

  /**
   * The name of the pubspec file.
   */
  static const String PUBSPEC_FILE_NAME = 'pubspec.yaml';

  /**
   * The name of the branch used to clean-up after making temporary changes.
   */
  static const String TEMP_BRANCH_NAME = 'temp';

  /**
   * The name of the command-line flag that will cause verbose output to be
   * produced.
   */
  static String VERBOSE_FLAG_NAME = 'verbose';

  /**
   * The style of interaction to use for analysis.updateContent requests.
   */
  OverlayStyle overlayStyle;

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
  Server server;

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
   * A flag indicating whether verbose output should be provided.
   */
  bool verbose = false;

  /**
   * The logger to which verbose logging data will be written.
   */
  Logger logger;

  /**
   * Initialize a newly created driver.
   */
  Driver() {
    statistics = new Statistics(this);
  }

  /**
   * Allow the output from the server to be read and processed.
   */
  Future<Null> readServerOutput() async {
    await new Future.delayed(new Duration(milliseconds: 2));
  }

  /**
   * Run the simulation based on the given command-line arguments ([args]).
   */
  Future<Null> run(List<String> args) async {
    //
    // Process the command-line arguments.
    //
    if (!_processCommandLine(args)) {
      return null;
    }
    if (verbose) {
      stdout.writeln();
      stdout.writeln('-' * 80);
      stdout.writeln();
    }
    //
    // Simulate interactions with the server.
    //
    await _runSimulation();
    //
    // Print out statistics gathered while performing the simulation.
    //
    if (verbose) {
      stdout.writeln();
      stdout.writeln('-' * 80);
    }
    stdout.writeln();
    statistics.print();
    if (verbose) {
      stdout.writeln();
      server.printStatistics();
    }
    exit(0);
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
    parser.addOption(OVERLAY_STYLE_OPTION_NAME,
        help:
            'The style of interaction to use for analysis.updateContent requests',
        allowed: [CHANGE_OVERLAY_STYLE, MULTIPLE_ADD_OVERLAY_STYLE],
        allowedHelp: {
          CHANGE_OVERLAY_STYLE: '<add> <change>* <remove>',
          MULTIPLE_ADD_OVERLAY_STYLE: '<add>+ <remove>'
        },
        defaultsTo: 'change');
    parser.addFlag(VERBOSE_FLAG_NAME,
        abbr: 'v',
        help: 'Produce verbose output for debugging',
        defaultsTo: false,
        negatable: false);
    return parser;
  }

  /**
   * Add source edits to the given [fileEdit] based on the given [blobDiff].
   */
  void _createSourceEdits(FileEdit fileEdit, BlobDiff blobDiff) {
    LineInfo info = fileEdit.lineInfo;
    for (DiffHunk hunk in blobDiff.hunks) {
      int srcStart = info.getOffsetOfLine(hunk.srcLine);
      int srcEnd = info.getOffsetOfLine(
          math.min(hunk.srcLine + hunk.removeLines.length, info.lineCount - 1));
      String addedText = _join(hunk.addLines);
      //
      // Create the source edits.
      //
      List<int> breakOffsets = _getBreakOffsets(addedText);
      int breakCount = breakOffsets.length;
      List<SourceEdit> sourceEdits = <SourceEdit>[];
      if (breakCount == 0) {
        sourceEdits
            .add(new SourceEdit(srcStart, srcEnd - srcStart + 1, addedText));
      } else {
        int previousOffset = breakOffsets[0];
        String string = addedText.substring(0, previousOffset);
        sourceEdits
            .add(new SourceEdit(srcStart, srcEnd - srcStart + 1, string));
        String reconstruction = string;
        for (int i = 1; i < breakCount; i++) {
          int offset = breakOffsets[i];
          string = addedText.substring(previousOffset, offset);
          reconstruction += string;
          sourceEdits.add(new SourceEdit(srcStart + previousOffset, 0, string));
          previousOffset = offset;
        }
        string = addedText.substring(previousOffset);
        reconstruction += string;
        sourceEdits.add(new SourceEdit(srcStart + previousOffset, 0, string));
        if (reconstruction != addedText) {
          throw new AssertionError();
        }
      }
      fileEdit.addSourceEdits(sourceEdits);
    }
  }

  /**
   * Return the absolute paths of all of the pubspec files in all of the
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

  /**
   * Return a list of offsets into the given [text] that represent good places
   * to break the text when building edits.
   */
  List<int> _getBreakOffsets(String text) {
    List<int> breakOffsets = <int>[];
    Scanner scanner = new Scanner(null, new CharSequenceReader(text),
        error.AnalysisErrorListener.NULL_LISTENER);
    Token token = scanner.tokenize();
    // TODO(brianwilkerson) Randomize. Sometimes add zero (0) as a break point.
    while (token.type != TokenType.EOF) {
      // TODO(brianwilkerson) Break inside comments?
//      Token comment = token.precedingComments;
      int offset = token.offset;
      int length = token.length;
      breakOffsets.add(offset);
      if (token.type == TokenType.IDENTIFIER && length > 3) {
        breakOffsets.add(offset + (length ~/ 2));
      }
      token = token.next;
    }
    return breakOffsets;
  }

  /**
   * Join the given [lines] into a single string.
   */
  String _join(List<String> lines) {
    StringBuffer buffer = new StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      buffer.writeln(lines[i]);
    }
    return buffer.toString();
  }

  /**
   * Process the command-line [arguments]. Return `true` if the simulation
   * should be run.
   */
  bool _processCommandLine(List<String> args) {
    ArgParser parser = _createArgParser();
    ArgResults results;
    try {
      results = parser.parse(args);
    } catch (exception) {
      _showUsage(parser);
      return false;
    }

    if (results[HELP_FLAG_NAME]) {
      _showUsage(parser);
      return false;
    }

    String overlayStyleValue = results[OVERLAY_STYLE_OPTION_NAME];
    if (overlayStyleValue == CHANGE_OVERLAY_STYLE) {
      overlayStyle = OverlayStyle.change;
    } else if (overlayStyleValue == MULTIPLE_ADD_OVERLAY_STYLE) {
      overlayStyle = OverlayStyle.multipleAdd;
    }

    if (results[VERBOSE_FLAG_NAME]) {
      verbose = true;
      logger = new Logger(stdout);
    }

    List<String> arguments = results.rest;
    if (arguments.length < 2) {
      _showUsage(parser);
      return false;
    }
    repositoryPath = path.normalize(arguments[0]);
    repository = new GitRepository(repositoryPath, logger: logger);

    analysisRoots = arguments
        .sublist(1)
        .map((String analysisRoot) => path.normalize(analysisRoot))
        .toList();
    for (String analysisRoot in analysisRoots) {
      if (repositoryPath != analysisRoot &&
          !path.isWithin(repositoryPath, analysisRoot)) {
        _showUsage(parser,
            'Analysis roots must be contained within the repository: $analysisRoot');
        return false;
      }
    }
    return true;
  }

  /**
   * Replay the changes in each commit.
   */
  Future<Null> _replayChanges() async {
    //
    // Get the revision history of the repo.
    //
    LinearCommitHistory history = repository.getCommitHistory();
    statistics.commitCount = history.commitIds.length;
    LinearCommitHistoryIterator iterator = history.iterator();
    try {
      //
      // Iterate over the history, applying changes.
      //
      bool firstCheckout = true;
      ErrorMap expectedErrors = null;
      Iterable<String> changedPubspecs;
      while (iterator.moveNext()) {
        //
        // Checkout the commit on which the changes are based.
        //
        String commit = iterator.srcCommit;
        repository.checkout(commit);
        if (expectedErrors != null) {
//          ErrorMap actualErrors =
          await server.computeErrorMap(server.analyzedDartFiles);
//          String difference = expectedErrors.expectErrorMap(actualErrors);
//          if (difference != null) {
//            stdout.write('Mismatched errors after commit ');
//            stdout.writeln(commit);
//            stdout.writeln();
//            stdout.writeln(difference);
//            return;
//          }
        }
        if (firstCheckout) {
          changedPubspecs = _findPubspecsInAnalysisRoots();
          server.sendAnalysisSetAnalysisRoots(analysisRoots, []);
          firstCheckout = false;
        } else {
          server.removeAllOverlays();
        }
        await readServerOutput();
        expectedErrors = await server.computeErrorMap(server.analyzedDartFiles);
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
          await _replayDiff(commitDelta);
        }
        changedPubspecs = commitDelta.filesMatching(PUBSPEC_FILE_NAME);
      }
    } finally {
      // Ensure that the repository is left at the most recent commit.
      if (history.commitIds.length > 0) {
        repository.checkout(history.commitIds[0]);
      }
    }
    server.removeAllOverlays();
    await readServerOutput();
    stdout.writeln();
  }

  /**
   * Replay the changes between two commits, as represented by the given
   * [commitDelta].
   */
  Future<Null> _replayDiff(CommitDelta commitDelta) async {
    List<FileEdit> editList = <FileEdit>[];
    for (DiffRecord record in commitDelta.diffRecords) {
      FileEdit edit = new FileEdit(overlayStyle, record);
      _createSourceEdits(edit, record.getBlobDiff());
      editList.add(edit);
    }
    //
    // TODO(brianwilkerson) Randomize.
    // Randomly select operations from different files to simulate a user
    // editing multiple files simultaneously.
    //
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
        statistics.editCount++;
        operation.perform(server);
        await readServerOutput();
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
   * Run the simulation by starting up a server and sending it requests.
   */
  Future<Null> _runSimulation() async {
    server = new Server(logger: logger);
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
      await _replayChanges();
    } finally {
      // TODO(brianwilkerson) This needs to be moved into a Zone in order to
      // ensure that it is always run.
      server.sendServerShutdown();
      repository.checkout('master');
    }
    stopwatch.stop();
  }

  /**
   * Display usage information, preceded by the [errorMessage] if one is given.
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
analysis roots represent the portions of the repository that will be analyzed by
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
   * The style of interaction to use for analysis.updateContent requests.
   */
  OverlayStyle overlayStyle;

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
   * The current content of the file. This field is only used if the overlay
   * style is [OverlayStyle.multipleAdd].
   */
  String currentContent;

  /**
   * Initialize a collection of edits to be associated with the file at the
   * given [filePath].
   */
  FileEdit(this.overlayStyle, DiffRecord record) {
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
    currentContent = content;
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
    List<ServerOperation> operations = <ServerOperation>[];
    void addUpdateContent(var overlay) {
      operations.add(new Analysis_UpdateContent(filePath, overlay));
    }

    // TODO(brianwilkerson) Randomize.
    // Make the order of edits random. Doing so will require updating the
    // offsets of edits after the selected edit point.
    addUpdateContent(new AddContentOverlay(content));
    for (List<SourceEdit> editList in editLists.reversed) {
      for (SourceEdit edit in editList.reversed) {
        var overlay = null;
        if (overlayStyle == OverlayStyle.change) {
          overlay = new ChangeContentOverlay([edit]);
        } else if (overlayStyle == OverlayStyle.multipleAdd) {
          currentContent = edit.apply(currentContent);
          overlay = new AddContentOverlay(currentContent);
        } else {
          throw new StateError(
              'Failed to handle overlay style = $overlayStyle');
        }
        if (overlay != null) {
          addUpdateContent(overlay);
        }
      }
    }
    addUpdateContent(new RemoveContentOverlay());
    return operations;
  }
}

/**
 * The possible styles of interaction to use for analysis.updateContent requests.
 */
enum OverlayStyle { change, multipleAdd }

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
   * The total number of edits that were applied.
   */
  int editCount = 0;

  /**
   * Initialize a newly created set of statistics.
   */
  Statistics(this.driver);

  /**
   * Print the statistics to [stdout].
   */
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
    stdout.write('  number of edits = ');
    stdout.writeln(editCount);
  }

  /**
   * Return a textual representation of the given duration, represented in
   * [milliseconds].
   */
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
      return '$minutes:$seconds.$milliseconds';
    }
    return '$seconds.$milliseconds';
  }
}
