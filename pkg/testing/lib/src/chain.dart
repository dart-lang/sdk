// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testing.chain;

import 'dart:convert' show json, JsonEncoder;

import 'dart:io' show Directory, File, FileSystemEntity, exitCode;

import 'suite.dart' show Suite;

import '../testing.dart' show FileBasedTestDescription, TestDescription;

import 'status_file_parser.dart' show readTestExpectations, TestExpectations;

import 'zone_helper.dart' show runGuarded;

import 'error_handling.dart' show withErrorHandling;

import 'log.dart' show Logger, StdoutLogger, splitLines;

import 'expectation.dart' show Expectation, ExpectationGroup, ExpectationSet;

typedef CreateContext = Future<ChainContext> Function(
    Chain suite, Map<String, String> environment);

/// A test suite for tool chains, for example, a compiler.
class Chain extends Suite {
  final Uri source;

  final Uri root;

  final List<Uri> subRoots;

  final List<String> includeEndsWith;

  final List<RegExp> pattern;

  final List<RegExp> exclude;

  Chain(String name, String kind, this.source, this.root, this.subRoots,
      Uri statusFile, this.includeEndsWith, this.pattern, this.exclude)
      : super(name, kind, statusFile);

  factory Chain.fromJsonMap(Uri base, Map json, String name, String kind) {
    Uri source = base.resolve(json["source"]);
    String root = json["root"];
    if (!root.endsWith("/")) {
      root += "/";
    }
    Uri rootUri = base.resolve(root);
    List<Uri> subRoots = [];
    List? subRootsList = json["subRoots"];
    if (subRootsList != null) {
      for (String subRoot in subRootsList) {
        if (!subRoot.endsWith("/")) {
          subRoot += "/";
        }
        subRoots.add(rootUri.resolve(subRoot));
      }
    } else {
      subRoots.add(rootUri);
    }
    Uri statusFile = base.resolve(json["status"]);
    List<String> includeEndsWith =
        List<String>.from(json['includeEndsWith'] ?? const []);
    List<RegExp> pattern = [
      for (final p in json['pattern'] ?? const []) RegExp(p)
    ];
    List<RegExp> exclude = [
      for (final e in json['exclude'] ?? const []) RegExp(e)
    ];
    return Chain(name, kind, source, rootUri, subRoots, statusFile,
        includeEndsWith, pattern, exclude);
  }

  void writeImportOn(StringSink sink) {
    sink.write("import '");
    sink.write(source);
    sink.write("' as ");
    sink.write(name);
    sink.writeln(";");
  }

  void writeClosureOn(StringSink sink) {
    sink.write("await runChain(");
    sink.write(name);
    sink.writeln(".createContext, {...environment}, selectors, r'''");
    const String jsonExtraIndent = "    ";
    sink.write(jsonExtraIndent);
    sink.writeAll(splitLines(JsonEncoder.withIndent("  ").convert(this)),
        jsonExtraIndent);
    sink.writeln("''');");
  }

  Map toJson() {
    return {
      "name": name,
      "kind": kind,
      "source": "$source",
      "root": "$root",
      "status": "$statusFile",
      "pattern": [for (final r in pattern) r.pattern],
      "includeEndsWith": includeEndsWith,
      "exclude": [for (final r in exclude) r.pattern],
    };
  }
}

abstract class ChainContext {
  const ChainContext();

  List<Step> get steps;

  ExpectationSet get expectationSet => ExpectationSet.defaultExpectations;

  Future<void> run(Chain suite, Set<String> selectors,
      {int shards = 1,
      int shard = 0,
      Logger logger = const StdoutLogger()}) async {
    assert(shards >= 1, "Invalid shards count: $shards");
    assert(0 <= shard && shard < shards,
        "Invalid shard index: $shard, not in range [0,$shards[.");
    List<String> tripleDotSelectors = selectors
        .where((s) => s.endsWith('...'))
        .map((s) => s.substring(0, s.length - 3))
        .toList();
    List<RegExp> asteriskSelectors = selectors
        .where((s) => s.contains('*'))
        .map((s) => _createRegExpForAsterisk(s))
        .toList();
    TestExpectations expectations = readTestExpectations(
        <String>[suite.statusFile!.toFilePath()], expectationSet);
    List<TestDescription> descriptions = await list(suite);
    descriptions.sort();

    /// Hack: If not running with asserts running the (invalid) configuration
    /// shards=1 shard>0 should behave as when running with the (invalid)
    /// configuration shards>1 shard>=shards, i.e. it should run nothing.
    if (shards > 1 || shard >= shards) {
      List<TestDescription> shardDescriptions = [];
      for (int index = 0; index < descriptions.length; index++) {
        if (index % shards == shard) {
          shardDescriptions.add(descriptions[index]);
        }
      }
      descriptions = shardDescriptions;
    }
    Map<TestDescription, Result> unexpectedResults =
        <TestDescription, Result>{};
    Map<TestDescription, Set<Expectation>> unexpectedOutcomes =
        <TestDescription, Set<Expectation>>{};
    int completed = 0;
    logger.logSuiteStarted(suite);
    List<Future> futures = <Future>[];
    for (TestDescription description in descriptions) {
      String selector = "${suite.name}/${description.shortName}";
      if (selectors.isNotEmpty &&
          !selectors.contains(selector) &&
          !selectors.contains(suite.name) &&
          !tripleDotSelectors.any((s) => selector.startsWith(s)) &&
          !asteriskSelectors.any((s) => s.hasMatch(selector))) {
        continue;
      }
      final Set<Expectation> expectedOutcomes = processExpectedOutcomes(
          expectations.expectations(description.shortName), description);
      bool shouldSkip = false;
      for (Expectation expectation in expectedOutcomes) {
        if (expectation.group == ExpectationGroup.skip) {
          shouldSkip = true;
          break;
        }
      }
      if (shouldSkip) continue;
      final StringBuffer sb = StringBuffer();
      final Iterator<Step> iterator = steps.iterator;

      Result? result;
      // Records the outcome of the last step that was run.
      Step? lastStepRun;

      /// Performs one step of [iterator].
      ///
      /// If `step.isAsync` is true, the corresponding step is said to be
      /// asynchronous.
      ///
      /// If a step is asynchronous the future returned from this function will
      /// complete after the first asynchronous step is scheduled.  This
      /// allows us to start processing the next test while an external process
      /// completes as steps can be interleaved. To ensure all steps are
      /// completed, wait for [futures].
      ///
      /// Otherwise, the future returned will complete when all steps are
      /// completed. This ensures that tests are run in sequence without
      /// interleaving steps.
      Future doStep(dynamic input) async {
        Future future;
        bool isAsync = false;
        if (iterator.moveNext()) {
          Step step = iterator.current;
          lastStepRun = step;
          isAsync = step.isAsync;
          logger.logStepStart(completed, unexpectedResults.length,
              descriptions.length, suite, description, step);
          // TODO(ahe): It's important to share the zone error reporting zone
          // between all the tasks. Otherwise, if a future completes with an
          // error in one zone, and gets stored, it becomes an uncaught error
          // in other zones (this happened in createPlatform).
          future = runGuarded(() async {
            try {
              return await step.run(input, this);
            } catch (error, trace) {
              return step.unhandledError(error, trace);
            }
          }, printLineOnStdout: sb.writeln);
        } else {
          future = Future.value(null);
        }
        future = future.then((currentResult) async {
          if (currentResult != null) {
            logger.logStepComplete(completed, unexpectedResults.length,
                descriptions.length, suite, description, lastStepRun!);
            result = currentResult;
            if ((currentResult as Result).outcome == Expectation.pass) {
              // The input to the next step is the output of this step.
              return doStep(result!.output);
            }
          }
          await cleanUp(description, result!);
          if (!expectedOutcomes.contains(result!.outcome) &&
              !expectedOutcomes.contains(result!.outcome.canonical)) {
            result!.addLog("$sb");
            unexpectedResults[description] = result!;
            unexpectedOutcomes[description] = expectedOutcomes;
            logger.logUnexpectedResult(
                suite, description, result!, expectedOutcomes);
            exitCode = 1;
          } else {
            logger.logExpectedResult(
                suite, description, result!, expectedOutcomes);
            logger.logMessage(sb);
          }
          logger.logTestComplete(++completed, unexpectedResults.length,
              descriptions.length, suite, description);
        });
        if (isAsync) {
          futures.add(future);
          return null;
        } else {
          return future;
        }
      }

      logger.logTestStart(completed, unexpectedResults.length,
          descriptions.length, suite, description);
      // The input of the first step is [description].
      await doStep(description);
    }
    await Future.wait(futures);
    logger.logSuiteComplete(suite);
    if (unexpectedResults.isNotEmpty) {
      unexpectedResults.forEach((TestDescription description, Result result) {
        logger.logUnexpectedResult(
            suite, description, result, unexpectedOutcomes[description]!);
      });
      print("${unexpectedResults.length} failed:");
      unexpectedResults.forEach((TestDescription description, Result result) {
        print("${suite.name}/${description.shortName}: ${result.outcome}");
      });
    }
    await postRun();
  }

  Future<List<TestDescription>> list(Chain suite) async {
    List<TestDescription> result = [];
    for (Uri subRoot in suite.subRoots) {
      Directory testRoot = Directory.fromUri(subRoot);
      if (testRoot.existsSync()) {
        for (FileSystemEntity entity
            in testRoot.listSync(recursive: true, followLinks: false)) {
          if (entity is! File) continue;
          // Use `.uri.path` instead of just `.path` to ensure forward slashes.
          String path = entity.uri.path;

          if (suite.exclude.any((RegExp r) => path.contains(r))) continue;

          bool include = false;
          if (suite.includeEndsWith.any((String end) => path.endsWith(end))) {
            include = true;
          }
          if (!include && suite.pattern.any((RegExp r) => path.contains(r))) {
            include = true;
          }
          if (include) {
            result.add(FileBasedTestDescription(suite.root, entity));
          }
        }
      } else {
        throw "$subRoot isn't a directory";
      }
    }
    return result;
  }

  Set<Expectation> processExpectedOutcomes(
      Set<Expectation> outcomes, TestDescription description) {
    return outcomes;
  }

  Future<void> cleanUp(TestDescription description, Result result) async {}

  Future<void> postRun() async {}
}

abstract class Step<I, O, C extends ChainContext> {
  const Step();

  String get name;

  /// Sets this (*and effectively subsequent*) test step(s) as async.
  ///
  /// TL;DR: Either set to false, or only set to true when this and all
  /// subsequent steps can run intertwined with another test.
  ///
  /// Details:
  ///
  /// A single test (TestDescription) can have several steps (Step).
  /// When running a test the first step is executed, and when that step is done
  /// the next step is executed by the now-ending step.
  ///
  /// When isAsync is false each step returns a future which is awaited,
  /// effectively meaning that only a single test is run at a time.
  ///
  /// When isAsync is true that step doesn't return a future (but adds it's
  /// future to a list which is awaited before sending an 'entire suite done'
  /// message), meaning that the next test can start before the step is
  /// finished. As the next step in the test only starts after the current
  /// step finishes, that also means that the next test can start - and run
  /// intertwined with - a subsequent step even if such a subsequent step has
  /// isAsync set to false.
  bool get isAsync => false;

  Future<Result<O>> run(I input, C context);

  Result<O> unhandledError(error, StackTrace trace) {
    return Result<O>.crash(error, trace);
  }

  Result<O> pass(O output) => Result<O>.pass(output);

  Result<O> crash(error, StackTrace trace) => Result<O>.crash(error, trace);

  Result<O> fail(O output, [error, StackTrace? trace]) {
    return Result<O>.fail(output, error, trace);
  }
}

class Result<O> {
  final O? output;

  final Expectation outcome;

  final Object? error;

  final StackTrace? trace;

  final List<String> logs = <String>[];

  /// If set, running the test with '-D$autoFixCommand' will automatically
  /// update the test to match new expectations.
  final String? autoFixCommand;

  /// If set, the test can be fixed by running
  ///
  ///     dart pkg/front_end/tool/update_expectations.dart
  ///
  final bool canBeFixWithUpdateExpectations;

  Result(
    this.output,
    this.outcome,
    this.error, {
    this.trace,
    this.autoFixCommand,
    this.canBeFixWithUpdateExpectations = false,
  });

  Result.pass(O output) : this(output, Expectation.pass, null);

  Result.crash(error, StackTrace trace)
      : this(null, Expectation.crash, error, trace: trace);

  Result.fail(O output, [error, StackTrace? trace])
      : this(output, Expectation.fail, error, trace: trace);

  bool get isPass => outcome == Expectation.pass;

  String get log => logs.join();

  void addLog(String log) {
    logs.add(log);
  }

  Result<O2> copyWithOutput<O2>(O2 output) {
    return Result<O2>(output, outcome, error,
        trace: trace,
        autoFixCommand: autoFixCommand,
        canBeFixWithUpdateExpectations: canBeFixWithUpdateExpectations)
      ..logs.addAll(logs);
  }
}

/// This is called from generated code.
Future<void> runChain(CreateContext f, Map<String, String> environment,
    Set<String> selectors, String jsonText) {
  return withErrorHandling(() async {
    Chain suite = Suite.fromJsonMap(Uri.base, json.decode(jsonText)) as Chain;
    print("Running ${suite.name}");
    ChainContext context = await f(suite, environment);
    return context.run(suite, selectors);
  });
}

RegExp _createRegExpForAsterisk(String s) {
  StringBuffer sb = StringBuffer("^");
  String between = "";
  for (String split in s.split("*")) {
    sb.write(between);
    between = ".*";
    sb.write(RegExp.escape(split));
  }
  sb.write("\$");
  return RegExp(sb.toString());
}
