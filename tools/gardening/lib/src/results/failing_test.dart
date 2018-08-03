// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:status_file/canonical_status_file.dart';

import 'result_json_models.dart';
import '../results/configurations.dart';
import '../results/status_expectations.dart';
import '../results/status_files.dart';
import '../util.dart';

typedef SectionsSuggestion ComputeSectionsFunc(
    List<Configuration> failingConfigurations,
    List<Configuration> passingConfigurations,
    StatusExpectations expectations,
    String testName);

/// [FailingTest] captures the essential information of a failing test, to
/// suggest sections to be updated.
class FailingTest {
  /// [result] holds data from the actual running of the test, such as name and
  /// outcome.
  final Result result;

  /// [TestResult] is the combined result for all tests in all configurations,
  /// gathered from the result.logs.
  final TestResult testResult;
  final List<Configuration> failingConfigurations;
  final List<Configuration> passingConfigurations;

  FailingTest(this.result, this.testResult, this.failingConfigurations,
      this.passingConfigurations);

  // There are multiple strategies for finding candidate sections, which will
  // then be presented to the user.
  List<SectionsSuggestion> computeSections(StatusExpectations expectations) {
    var computeSectionStrategies = <ComputeSectionsFunc>[
      _findExistingFailingEntriesStrategy,
      _failingSectionsIntersectionStrategy,
      _statusSectionDifferenceStrategy
    ];

    // We remember all the sections already found by previous strategies. The
    // most precise strategies should be called first, so a section is printed
    // with the most accurate description of why it is a good candidate..
    var seenSections = new Set<StatusSectionWithFile>();

    var computedList = <SectionsSuggestion>[];
    computeSectionStrategies.forEach((strategy) {
      var suggestion = strategy(failingConfigurations, passingConfigurations,
          expectations, result.name);
      suggestion.sections = suggestion.sections
          .where((section) => !seenSections.contains(section))
          .toList();
      if (suggestion != null && suggestion.sections.isNotEmpty) {
        computedList.add(suggestion);
        seenSections.addAll(suggestion.sections);
      }
    });
    return computedList;
  }

  /// Checks, from [expectations], if the failing test is still failing.
  bool stillFailing(StatusExpectations expectations) {
    var testExpectations = expectations.getTestResultsWithExpectation();
    return testExpectations
        .where((expectation) =>
            !expectation.isSuccess() && expectation.result == result)
        .isNotEmpty;
  }

  /// Gets the status files for the suite this test belongs to.
  List<StatusFile> statusFiles(StatusExpectations expectations) {
    var testSuite = getSuiteNameForTest(result.name);
    return expectations.statusFilesMaps[testSuite].statusFiles;
  }

  /// Gets all failing status entries. Test can still fail without having any
  /// entries.
  List<StatusSectionEntry> failingStatusEntries(
      StatusExpectations expectations) {
    var entries = _sectionEntriesForTestInConfigurations(
        expectations, failingConfigurations, result.name,
        success: false);
    return new Set.of(entries).toList();
  }

  /// Gets the failing configurations not covered by expressions in [sections].
  List<Configuration> failingConfigurationsNotCovered(
      StatusExpectations expectations, List<StatusSectionWithFile> sections) {
    return _configurationsNotCovered(
        expectations, sections, this.failingConfigurations);
  }

  /// Gets the passing configurations not covered by expressions in [sections].
  List<Configuration> passingConfigurationsNotCovered(
      StatusExpectations expectations, List<StatusSectionWithFile> sections) {
    return _configurationsNotCovered(
        expectations, sections, this.passingConfigurations);
  }

  List<Configuration> _configurationsNotCovered(
      StatusExpectations expectations,
      List<StatusSectionWithFile> sections,
      List<Configuration> configurations) {
    List<Configuration> notCovered = [];
    for (var configuration in configurations) {
      var environment = expectations.configurationEnvironments[configuration];
      if (!sections
          .any((section) => section.section.condition.evaluate(environment))) {
        notCovered.add(configuration);
      }
    }
    return notCovered;
  }
}

/// Finds status section entries (entries with a path and expectation), where
/// the path matches the test name, in [statusExpectations] for the
/// [configurations]. [success] can be used to further filter on the entries, by
/// specifying if the status section entry should be successful, failing or both
/// (null), when compared with the result from the test, in one of the
/// configurations.
List<StatusSectionEntry> _sectionEntriesForTestInConfigurations(
    StatusExpectations statusExpectations,
    List<Configuration> configurations,
    String testName,
    {bool success: null}) {
  var expectations = statusExpectations.getTestResultsWithExpectation();
  return expectations
      .where((expectation) =>
          configurations.contains(expectation.configuration) &&
          expectation.result.name == testName &&
          (success == null || expectation.isSuccess() == success))
      .expand((testResult) => testResult.entries)
      .toList();
}

/*********************************
 * Strategies to find sections
 *********************************/

/// Strategy that returns all status headers that have a failing status entry
/// for this test. For tests going from some failure to passing, this would be
/// the preferred option.
/// We are not guaranteed that any sections will cover all failing sections.
SectionsSuggestion _findExistingFailingEntriesStrategy(
    List<Configuration> failingConfigurations,
    List<Configuration> passingConfigurations,
    StatusExpectations expectations,
    String testName) {
  String description = "These sections already already have entries for this "
      "test, that apply to at least one failing configuration";
  var allEntries = new Set<StatusSectionEntry>.from(
      _sectionEntriesForTestInConfigurations(
          expectations, failingConfigurations, testName,
          success: false));
  var sections = allEntries
      .map(
          (entry) => new StatusSectionWithFile(entry.statusFile, entry.section))
      .toList();
  return new SectionsSuggestion(description, sections);
}

/// The [_failingSectionsIntersectionStrategy] will hopefully be the bread and
/// butter strategy for most. It takes the intersection of all failing
/// configurations enabled sections and subtracts the set of all sections
/// enabled for the passing configurations.
/// If a result is found, it is guaranteed to cover all the failing
/// configurations and none of the passing configurations.
SectionsSuggestion _failingSectionsIntersectionStrategy(
    List<Configuration> failingConfigurations,
    List<Configuration> passingConfigurations,
    StatusExpectations expectations,
    String testName) {
  String description = "Every section listed here covers all failing"
      "configurations and none of the passing configurations.";
  var testSuite = getSuiteNameForTest(testName);
  var configurationSections = <StatusSectionWithFile, List<Configuration>>{};
  for (var configuration in failingConfigurations) {
    var sections =
        _sectionsFromConfiguration(expectations, configuration, testSuite);
    for (var section in _filterSections(sections, testSuite, configuration)) {
      configurationSections.putIfAbsent(section, () => [])..add(configuration);
    }
  }
  var sections = new Set<StatusSectionWithFile>.from(configurationSections.keys
      .where((key) =>
          failingConfigurations.length == configurationSections[key].length));
  if (sections.isEmpty) {
    return new SectionsSuggestion(description, []);
  }
  for (var configuration in passingConfigurations) {
    var sectionsToRemove =
        _sectionsFromConfiguration(expectations, configuration, testSuite);
    sections.removeAll(sectionsToRemove);
  }
  var sortedSections = sections.toList()
    ..sort((a, b) => a.section.condition.compareTo(b.section.condition));
  return new SectionsSuggestion(description, sortedSections);
}

/// The [_statusSectionDifferenceStrategy] takes the union of all enabled
/// failing sections and subtracts all the enabled passing sections. We are
/// guaranteed to not select a section that is enabled in a passing
/// configuration, however, it is not guaranteed that a combination of the
/// sections will cover all failing configurations.
SectionsSuggestion _statusSectionDifferenceStrategy(
    List<Configuration> failingConfigurations,
    List<Configuration> passingConfigurations,
    StatusExpectations expectations,
    String testName) {
  String description = "All sections cover one or more failing "
      "configuration but none of the passing configurations.";
  var configurationSections = <Configuration, Set<StatusSectionWithFile>>{};
  var testSuite = getSuiteNameForTest(testName);
  for (var configuration in failingConfigurations) {
    var sections = _filterSections(
        _sectionsFromConfiguration(expectations, configuration, testSuite),
        testSuite,
        configuration);
    configurationSections[configuration] = new Set.from(sections);
  }
  for (var configuration in passingConfigurations) {
    var sectionsToRemove =
        _sectionsFromConfiguration(expectations, configuration, testSuite);
    for (var failingSections in configurationSections.values) {
      failingSections.removeAll(sectionsToRemove);
    }
  }
  var sortedSections = configurationSections.values
      .reduce((a, b) => a..addAll(b))
      .toList()
        ..sort((a, b) => a.section.condition.compareTo(b.section.condition));
  return new SectionsSuggestion(description, sortedSections);
}

List<StatusSectionWithFile> _sectionsFromConfiguration(
    StatusExpectations expectations,
    Configuration configuration,
    String testSuite) {
  var environment = expectations.configurationEnvironments[configuration];
  return expectations.statusFilesMaps[testSuite]
      .sectionsForConfiguration(environment);
}

/// Filters section by not taking the default section, and also exclude status
/// files of other compilers.
List<StatusSectionWithFile> _filterSections(
    List<StatusSectionWithFile> statusSections,
    String suite,
    Configuration configuration) {
  String specificStatusFile =
      configuration.compiler == Compiler.none ? "" : configuration.compiler;
  if (configuration.compiler == Compiler.dartdevk.name) {
    specificStatusFile = Compiler.dartdevc.name;
  }
  if (configuration.compiler == Compiler.dartk ||
      configuration.compiler == Compiler.dartkp) {
    specificStatusFile = "kernel";
  }
  if (specificStatusFile.isEmpty) {
    return statusSections
        .where((statusSection) => statusSection.section.condition != null);
  } else {
    return statusSections
        .where((statusSection) =>
            statusSection.section.condition != null &&
            (statusSection.statusFile.path.endsWith("$suite.status") ||
                statusSection.statusFile.path
                    .endsWith("${suite}-$specificStatusFile.status") ||
                statusSection.statusFile.path
                    .endsWith("${suite}_$specificStatusFile.status")))
        .toList();
  }
}

/// A [SectionsSuggestion] object holds all the sections suggested by a
/// strategy, and a description of that strategy.
class SectionsSuggestion {
  final String strategy;
  List<StatusSectionWithFile> sections;
  SectionsSuggestion(this.strategy, this.sections);
}
