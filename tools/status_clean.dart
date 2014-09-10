// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library status_clean;

import "dart:async";
import "dart:convert" show JSON, UTF8;
import "dart:io";
import "testing/dart/multitest.dart";
import "testing/dart/status_file_parser.dart";
import "testing/dart/test_suite.dart"
    show multiHtmlTestGroupRegExp, multiTestRegExp, multiHtmlTestRegExp,
         TestUtils;
import "testing/dart/utils.dart" show Path;

// [STATUS_TUPLES] is a list of (suite-name, directory, status-file)-tuples.
final STATUS_TUPLES = [
    ["corelib", "tests/corelib", "tests/corelib/corelib.status"],
    ["html", "tests/html", "tests/html/html.status"],
    ["isolate", "tests/isolate", "tests/isolate/isolate.status"],
    ["language", "tests/language", "tests/language/language.status"],
    ["language", "tests/language", "tests/language/language_analyzer2.status"],
    ["language","tests/language", "tests/language/language_analyzer.status"],
    ["language","tests/language", "tests/language/language_dart2js.status"],
    ["lib", "tests/lib", "tests/lib/lib.status"],
    ["standalone", "tests/standalone", "tests/standalone/standalone.status"],
    ["pkg", "pkg", "pkg/pkg.status"],
    ["pkgbuild", ".", "pkg/pkgbuild.status"],
    ["utils", "tests/utils", "tests/utils/utils.status"],
    ["samples", "samples", "samples/samples.status"],
    ["analyze_library", "sdk", "tests/lib/analyzer/analyze_library.status"],
    ["dart2js_extra", "tests/compiler/dart2js_extra",
     "tests/compiler/dart2js_extra/dart2js_extra.status"],
    ["dart2js_native", "tests/compiler/dart2js_native",
     "tests/compiler/dart2js_native/dart2js_native.status"],
    ["dart2js", "tests/compiler/dart2js",
     "tests/compiler/dart2js/dart2js.status"],
    ["pub", "sdk/lib/_internal/pub_generated",
     "sdk/lib/_internal/pub/pub.status"],
    ["benchmark_smoke", "tests/benchmark_smoke",
     "tests/benchmark_smoke/benchmark_smoke.status"],
    ["co19", "tests/co19/src", "tests/co19/co19-analyzer2.status"],
    ["co19", "tests/co19/src", "tests/co19/co19-analyzer.status"],
    ["co19", "tests/co19/src", "tests/co19/co19-dart2dart.status"],
    ["co19", "tests/co19/src", "tests/co19/co19-dart2js.status"],
    ["co19", "tests/co19/src", "tests/co19/co19-co19.status"],
    ["co19", "tests/co19/src", "tests/co19/co19-dartium.status"],
    ["co19", "tests/co19/src", "tests/co19/co19-runtime.status"],
];

void main(List<String> args) {
  TestUtils.setDartDirUri(Platform.script.resolve('..'));
  usage() {
    print("Usage: ${Platform.executable} <deflake|remove-nonexistent-tests>");
    exit(1);
  }

  if (args.length == 0) usage();

  if (args[0] == 'deflake') {
    run(new StatusFileDeflaker());
  } else if (args[0] == 'remove-nonexistent-tests') {
    run(new StatusFileNonExistentTestRemover());
  } else {
    usage();
  }
}

run(StatusFileProcessor processor) {
  Future.forEach(STATUS_TUPLES, (List tuple) {
    String suiteName = tuple[0];
    String directory = tuple[1];
    String filePath = tuple[2];
    print("Processing $filePath");
    return processor.run(suiteName, directory, filePath);
  });
}

abstract class StatusFileProcessor {
  Future run(String suiteName, String directory, String filePath);

  Future<List<Section>> _readSections(String filePath) {
    File file = new File(filePath);

    if (file.existsSync()) {
      var completer = new Completer();
      List<Section> sections = new List<Section>();

      ReadConfigurationInto(new Path(file.path), sections, () {
        completer.complete(sections);
      });
      return completer.future;
    }
    return new Future.value([]);
  }
}

class StatusFileNonExistentTestRemover extends StatusFileProcessor {
  final MultiTestDetector multiTestDetector = new MultiTestDetector();
  final TestFileLister testFileLister = new TestFileLister();

  Future run(String suiteName, String directory, String filePath) {
    return _readSections(filePath).then((List<Section> sections) {
      Set<int> invalidLines = _analyzeStatusFile(directory, filePath, sections);
      if (invalidLines.length > 0) {
        return _writeFixedStatusFile(filePath, invalidLines);
      }
      return new Future.value();
    });
  }

  bool _testExists(String filePath,
                   List<String> testFiles,
                   String directory,
                   TestRule rule) {
    // TODO: Unify this regular expression matching with status_file_parser.dart
    List<RegExp> getRuleRegex(String name) {
      return name.split("/")
          .map((name) => new RegExp(name.replaceAll('*', '.*')))
          .toList();
    }
    bool matchRegexp(List<RegExp> patterns, String str) {
      var parts = str.split("/");
      if (patterns.length > parts.length) {
        return false;
      }
      // NOTE: patterns.length <= parts.length
      for (var i = 0; i < patterns.length; i++) {
        if (!patterns[i].hasMatch(parts[i])) {
          return false;
        }
      }
      return true;
    }

    var rulePattern = getRuleRegex(rule.name);
    return testFiles.any((String file) {
      // TODO: Use test_suite.dart's [buildTestCaseDisplayName] instead.
      var filePath = new Path(file).relativeTo(new Path(directory));
      String baseTestName = _concat("${filePath.directoryPath}",
                                    "${filePath.filenameWithoutExtension}");

      List<String> testNames = [];
      for (var name in multiTestDetector.getMultitestNames(file)) {
        testNames.add(_concat(baseTestName, name));
      }

      // If it is not a multitest the testname is [baseTestName]
      if (testNames.isEmpty) {
        testNames.add(baseTestName);
      }

      return testNames.any(
          (String testName) => matchRegexp(rulePattern, testName));
    });
  }

  Set<int> _analyzeStatusFile(String directory,
                              String filePath,
                              List<Section> sections) {
    var invalidLines = new Set<int>();
    var dartFiles = testFileLister.listTestFiles(directory);
    for (var section in sections) {
      for (var rule in section.testRules) {
        if (!_testExists(filePath, dartFiles, directory, rule)) {
          print("Invalid rule: ${rule.name} in file "
                "$filePath:${rule.lineNumber}");
          invalidLines.add(rule.lineNumber);
        }
      }
    }
    return invalidLines;
  }

  _writeFixedStatusFile(String statusFilePath, Set<int> invalidLines) {
    var lines = new File(statusFilePath).readAsLinesSync();
    var outputLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      // The status file parser numbers lines starting with 1, not 0.
      if (!invalidLines.contains(i + 1)) {
        outputLines.add(lines[i]);
      }
    }
    var outputFile = new File("$statusFilePath.fixed");
    outputFile.writeAsStringSync(outputLines.join("\n"));
 }

  String _concat(String base, String part) {
    if (base == "") return part;
    if (part == "") return base;
    return "$base/$part";
  }
}

class StatusFileDeflaker extends StatusFileProcessor {
  TestOutcomeFetcher _testOutcomeFetcher = new TestOutcomeFetcher();

  Future run(String suiteName, String directory, String filePath) {
    return _readSections(filePath).then((List<Section> sections) {
      return _generatedDeflakedLines(suiteName, sections)
          .then((Map<int, String> fixedLines) {
            if (fixedLines.length > 0) {
              return _writeFixedStatusFile(filePath, fixedLines);
            }
      });
    });
  }

  Future _generatedDeflakedLines(String suiteName,
                                 List<Section> sections) {
    var fixedLines = new Map<int, String>();
    return Future.forEach(sections, (Section section) {
      return Future.forEach(section.testRules, (rule) {
        return _maybeFixStatusfileLine(suiteName, section, rule, fixedLines);
      });
    }).then((_) => fixedLines);
  }

  Future _maybeFixStatusfileLine(String suiteName,
                                 Section section,
                                 TestRule rule,
                                 Map<int, String> fixedLines) {
    print("Processing ${section.statusFile.location}: ${rule.lineNumber}");
    // None of our status file lines have expressions, so we pass {} here.
    var notedOutcomes = rule.expression
        .evaluate({})
        .map((name) => Expectation.byName(name))
        .where((Expectation expectation) => !expectation.isMetaExpectation)
        .toSet();

    if (notedOutcomes.isEmpty) return new Future.value();

    // TODO: [rule.name] is actually a pattern not just a testname. We should
    // find all possible testnames this rule matches against and unify the
    // outcomes of these tests.
    return _testOutcomeFetcher.outcomesOf(suiteName, section, rule.name)
      .then((Set<Expectation> actualOutcomes) {

      var outcomesThatNeverHappened = new Set<Expectation>();
      for (Expectation notedOutcome in notedOutcomes) {
        bool found = false;
        for (Expectation actualOutcome in actualOutcomes) {
          if (actualOutcome.canBeOutcomeOf(notedOutcome)) {
            found = true;
            break;
          }
        }
        if (!found) {
          outcomesThatNeverHappened.add(notedOutcome);
        }
      }

      if (outcomesThatNeverHappened.length > 0 && actualOutcomes.length > 0) {
        // Print the change to stdout.
        print("${rule.name} "
              "(${section.statusFile.location}:${rule.lineNumber}):");
        print("   Actual outcomes:         ${actualOutcomes.toList()}");
        print("   Outcomes in status file: ${notedOutcomes.toList()}");
        print("   Outcomes in status file that never happened : "
              "${outcomesThatNeverHappened.toList()}\n");

        // Build the fixed status file line.
        fixedLines[rule.lineNumber] =
            '${rule.name}: ${actualOutcomes.join(', ')} '
            '# before: ${notedOutcomes.join(', ')} / '
            'never happened:  ${outcomesThatNeverHappened.join(', ')}';
      }
    });
  }

  _writeFixedStatusFile(String filePath, Map<int, String> fixedLines) {
    var lines = new File(filePath).readAsLinesSync();
    var outputLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      if (fixedLines.containsKey(i + 1)) {
        outputLines.add(fixedLines[i + 1]);
      } else {
        outputLines.add(lines[i]);
      }
    }
    var output = outputLines.join("\n");
    var outputFile = new File("$filePath.deflaked");
    outputFile.writeAsStringSync(output);
 }
}

class MultiTestDetector {
  final multiTestsCache = new Map<String,List<String>>();
  final multiHtmlTestsCache = new Map<String,List<String>>();


  List<String> getMultitestNames(String file) {
    List<String> names = [];
    names.addAll(getStandardMultitestNames(file));
    names.addAll(getHtmlMultitestNames(file));
    return names;
  }

  List<String> getStandardMultitestNames(String file) {
    return multiTestsCache.putIfAbsent(file, () {
      try {
        var tests = new Map<String, String>();
        var outcomes = new Map<String, Set<String>>();
        if (multiTestRegExp.hasMatch(new File(file).readAsStringSync())) {
          ExtractTestsFromMultitest(new Path(file), tests, outcomes);
        }
        return tests.keys.toList();
      } catch (error) {
        print("WARNING: Couldn't determine multitests in file ${file}: $error");
        return [];
      }
    });
  }

  List<String> getHtmlMultitestNames(String file) {
    return multiHtmlTestsCache.putIfAbsent(file, () {
      try {
        List<String> subtestNames = [];
        var content = new File(file).readAsStringSync();

        if (multiHtmlTestRegExp.hasMatch(content)) {
          var matchesIter = multiHtmlTestGroupRegExp.allMatches(content).iterator;
          while(matchesIter.moveNext()) {
            String fullMatch = matchesIter.current.group(0);
            subtestNames.add(fullMatch.substring(fullMatch.indexOf("'") + 1));
          }
        }
        return subtestNames;
      } catch (error) {
        print("WARNING: Couldn't determine multitests in file ${file}: $error");
      }
      return [];
    });
  }
}

class TestFileLister {
  final Map<String, List<String>> _filesCache = {};

  List<String> listTestFiles(String directory) {
    return _filesCache.putIfAbsent(directory, () {
      var dir = new Directory(directory);
      // Cannot test for _test.dart because co19 tests don't have that ending.
      var dartFiles = dir.listSync(recursive: true)
          .where((fe) => fe is File)
          .where((file) => file.path.endsWith(".dart") ||
                           file.path.endsWith("_test.html"))
          .map((file) => file.path)
          .toList();
      return dartFiles;
    });
  }
}


/*
 * [TestOutcomeFetcher] will fetch test results from a server using a REST-like
 * interface.
 */
class TestOutcomeFetcher {
  static String SERVER = '108.170.219.8';
  static int PORT = 4540;

  HttpClient _client = new HttpClient();

  Future<Set<Expectation>> outcomesOf(
      String suiteName, Section section, String testName) {
    var pathComponents = ['json', 'test-outcomes', 'outcomes',
                          Uri.encodeComponent("$suiteName/$testName")];
    var path = pathComponents.join('/') + '/';
    var url = new Uri(scheme: 'http', host: SERVER, port: PORT, path: path);

    return _client.getUrl(url)
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
        return response.transform(UTF8.decoder).transform(JSON.decoder).first
            .then((List testResults) {
              var setOfActualOutcomes = new Set<Expectation>();

              try {
                for (var result in testResults) {
                  var config = result['configuration'];
                  var testResult = result['test_result'];
                  var outcome = testResult['outcome'];

                  // These variables are derived variables and will be set in
                  // tools/testing/dart/test_options.dart.
                  // [Mostly due to the fact that we don't have an unary !
                  //  operator in status file expressions.]
                  config['unchecked'] = !config['checked'];
                  config['unminified'] = !config['minified'];
                  config['nocsp'] = !config['csp'];
                  config['browser'] =
                      TestUtils.isBrowserRuntime(config['runtime']);
                  config['analyzer'] =
                      TestUtils.isCommandLineAnalyzer(config['compiler']);
                  config['jscl'] =
                      TestUtils.isJsCommandLineRuntime(config['runtime']);

                  if (section.condition == null ||
                      section.condition.evaluate(config)) {
                    setOfActualOutcomes.add(Expectation.byName(outcome));
                  }
                }
                return setOfActualOutcomes;
              } catch (error) {
                print("Warning: Error occured while processing testoutcomes"
                      ": $error");
                return [];
              }
            }).catchError((error) {
              print("Warning: Error occured while fetching testoutcomes: $error");
              return [];
            });
    });
  }
}
