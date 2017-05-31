// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.chain;

import 'dart:async' show Future, Stream;

import 'dart:convert' show JSON, JsonEncoder;

import 'dart:io' show Directory, File, FileSystemEntity, exitCode;

import 'suite.dart' show Suite;

import '../testing.dart' show TestDescription;

import 'test_dart/status_file_parser.dart'
    show ReadTestExpectations, TestExpectations;

import 'zone_helper.dart' show runGuarded;

import 'error_handling.dart' show withErrorHandling;

import 'log.dart'
    show
        logMessage,
        logStepComplete,
        logStepStart,
        logSuiteComplete,
        logTestComplete,
        logUnexpectedResult,
        splitLines;

import 'multitest.dart' show MultitestTransformer, isError;

import 'expectation.dart' show Expectation, ExpectationSet;

typedef Future<ChainContext> CreateContext(
    Chain suite, Map<String, String> environment);

/// A test suite for tool chains, for example, a compiler.
class Chain extends Suite {
  final Uri source;

  final Uri uri;

  final List<RegExp> pattern;

  final List<RegExp> exclude;

  final bool processMultitests;

  Chain(String name, String kind, this.source, this.uri, Uri statusFile,
      this.pattern, this.exclude, this.processMultitests)
      : super(name, kind, statusFile);

  factory Chain.fromJsonMap(Uri base, Map json, String name, String kind) {
    Uri source = base.resolve(json["source"]);
    Uri uri = base.resolve(json["path"]);
    Uri statusFile = base.resolve(json["status"]);
    List<RegExp> pattern =
        new List<RegExp>.from(json["pattern"].map((String p) => new RegExp(p)));
    List<RegExp> exclude =
        new List<RegExp>.from(json["exclude"].map((String p) => new RegExp(p)));
    bool processMultitests = json["process-multitests"] ?? false;
    return new Chain(name, kind, source, uri, statusFile, pattern, exclude,
        processMultitests);
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
    sink.writeln(".createContext, environment, selectors, r'''");
    const String jsonExtraIndent = "    ";
    sink.write(jsonExtraIndent);
    sink.writeAll(splitLines(new JsonEncoder.withIndent("  ").convert(this)),
        jsonExtraIndent);
    sink.writeln("''');");
  }

  Map toJson() {
    return {
      "name": name,
      "kind": kind,
      "source": "$source",
      "path": "$uri",
      "status": "$statusFile",
      "process-multitests": processMultitests,
      "pattern": []..addAll(pattern.map((RegExp r) => r.pattern)),
      "exclude": []..addAll(exclude.map((RegExp r) => r.pattern)),
    };
  }
}

abstract class ChainContext {
  const ChainContext();

  List<Step> get steps;

  ExpectationSet get expectationSet => ExpectationSet.Default;

  Future<Null> run(Chain suite, Set<String> selectors) async {
    List<String> partialSelectors = selectors
        .where((s) => s.endsWith('...'))
        .map((s) => s.substring(0, s.length - 3))
        .toList();
    TestExpectations expectations = await ReadTestExpectations(
        <String>[suite.statusFile.toFilePath()], {}, expectationSet);
    Stream<TestDescription> stream = list(suite);
    if (suite.processMultitests) {
      stream = stream.transform(new MultitestTransformer());
    }
    List<TestDescription> descriptions = await stream.toList();
    descriptions.sort();
    Map<TestDescription, Result> unexpectedResults =
        <TestDescription, Result>{};
    Map<TestDescription, Set<Expectation>> unexpectedOutcomes =
        <TestDescription, Set<Expectation>>{};
    int completed = 0;
    List<Future> futures = <Future>[];
    for (TestDescription description in descriptions) {
      String selector = "${suite.name}/${description.shortName}";
      if (selectors.isNotEmpty &&
          !selectors.contains(selector) &&
          !selectors.contains(suite.name) &&
          !partialSelectors.any((s) => selector.startsWith(s))) {
        continue;
      }
      final Set<Expectation> expectedOutcomes =
          expectations.expectations(description.shortName);
      final StringBuffer sb = new StringBuffer();
      final Step lastStep = steps.isNotEmpty ? steps.last : null;
      final Iterator<Step> iterator = steps.iterator;

      Result result;
      // Records the outcome of the last step that was run.
      Step lastStepRun;

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
          logStepStart(completed, unexpectedResults.length, descriptions.length,
              suite, description, step);
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
          future = new Future.value(null);
        }
        future = future.then((Result currentResult) {
          if (currentResult != null) {
            logStepComplete(completed, unexpectedResults.length,
                descriptions.length, suite, description, lastStepRun);
            result = currentResult;
            if (currentResult.outcome == Expectation.Pass) {
              // The input to the next step is the output of this step.
              return doStep(result.output);
            }
          }
          if (description.multitestExpectations != null) {
            if (isError(description.multitestExpectations)) {
              result = toNegativeTestResult(
                  result, description.multitestExpectations);
            }
          } else if (lastStep == lastStepRun &&
              description.shortName.endsWith("negative_test")) {
            if (result.outcome == Expectation.Pass) {
              result.addLog("Negative test didn't report an error.\n");
            } else if (result.outcome == Expectation.Fail) {
              result.addLog("Negative test reported an error as expeceted.\n");
            }
            result = toNegativeTestResult(result);
          }
          if (!expectedOutcomes.contains(result.outcome) &&
              !expectedOutcomes.contains(result.outcome.canonical)) {
            result.addLog("$sb");
            unexpectedResults[description] = result;
            unexpectedOutcomes[description] = expectedOutcomes;
            logUnexpectedResult(suite, description, result, expectedOutcomes);
            exitCode = 1;
          } else {
            logMessage(sb);
          }
          logTestComplete(++completed, unexpectedResults.length,
              descriptions.length, suite, description);
        });
        if (isAsync) {
          futures.add(future);
          return null;
        } else {
          return future;
        }
      }

      // The input of the first step is [description].
      await doStep(description);
    }
    await Future.wait(futures);
    logSuiteComplete();
    if (unexpectedResults.isNotEmpty) {
      unexpectedResults.forEach((TestDescription description, Result result) {
        logUnexpectedResult(
            suite, description, result, unexpectedOutcomes[description]);
      });
      print("${unexpectedResults.length} failed:");
      unexpectedResults.forEach((TestDescription description, Result result) {
        print("${suite.name}/${description.shortName}: ${result.outcome}");
      });
    }
  }

  Stream<TestDescription> list(Chain suite) async* {
    Directory testRoot = new Directory.fromUri(suite.uri);
    if (await testRoot.exists()) {
      Stream<FileSystemEntity> files =
          testRoot.list(recursive: true, followLinks: false);
      await for (FileSystemEntity entity in files) {
        if (entity is! File) continue;
        String path = entity.uri.path;
        if (suite.exclude.any((RegExp r) => path.contains(r))) continue;
        if (suite.pattern.any((RegExp r) => path.contains(r))) {
          yield new TestDescription(suite.uri, entity);
        }
      }
    } else {
      throw "${suite.uri} isn't a directory";
    }
  }

  Result toNegativeTestResult(Result result, [Set<String> expectations]) {
    Expectation outcome = result.outcome;
    if (outcome == Expectation.Pass) {
      if (expectations == null) {
        outcome = Expectation.Fail;
      } else if (expectations.contains("compile-time error")) {
        outcome = expectationSet["MissingCompileTimeError"];
      } else if (expectations.contains("runtime error") ||
          expectations.contains("dynamic type error")) {
        outcome = expectationSet["MissingRuntimeError"];
      } else {
        outcome = Expectation.Fail;
      }
    } else if (outcome == Expectation.Fail) {
      outcome = Expectation.Pass;
    }
    return result.copyWithOutcome(outcome);
  }
}

abstract class Step<I, O, C extends ChainContext> {
  const Step();

  String get name;

  bool get isAsync => false;

  bool get isCompiler => false;

  bool get isRuntime => false;

  Future<Result<O>> run(I input, C context);

  Result<O> unhandledError(error, StackTrace trace) {
    return new Result<O>.crash(error, trace);
  }

  Result<O> pass(O output) => new Result<O>.pass(output);

  Result<O> crash(error, StackTrace trace) => new Result<O>.crash(error, trace);

  Result<O> fail(O output, [error, StackTrace trace]) {
    return new Result<O>.fail(output, error, trace);
  }
}

class Result<O> {
  final O output;

  final Expectation outcome;

  final error;

  final StackTrace trace;

  final List<String> logs = <String>[];

  Result(this.output, this.outcome, this.error, this.trace);

  Result.pass(O output) : this(output, Expectation.Pass, null, null);

  Result.crash(error, StackTrace trace)
      : this(null, Expectation.Crash, error, trace);

  Result.fail(O output, [error, StackTrace trace])
      : this(output, Expectation.Fail, error, trace);

  String get log => logs.join();

  void addLog(String log) {
    logs.add(log);
  }

  Result<O> copyWithOutcome(Expectation outcome) {
    return new Result<O>(output, outcome, error, trace)..logs.addAll(logs);
  }
}

/// This is called from generated code.
Future<Null> runChain(CreateContext f, Map<String, String> environment,
    Set<String> selectors, String json) {
  return withErrorHandling(() async {
    Chain suite = new Suite.fromJsonMap(Uri.base, JSON.decode(json));
    print("Running ${suite.name}");
    ChainContext context = await f(suite, environment);
    return context.run(suite, selectors);
  });
}
