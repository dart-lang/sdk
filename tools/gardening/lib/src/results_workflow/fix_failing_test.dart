// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:status_file/canonical_status_file.dart';
import 'package:status_file/expectation.dart';
import 'package:status_file/status_file_normalizer.dart';
import 'package:status_file/src/expression.dart';

import 'present_failures.dart';
import '../results/result_json_models.dart';
import '../results/failing_test.dart';
import '../results/status_expectations.dart';
import '../results/status_files.dart';
import '../util.dart';
import '../workflow.dart';

final RegExp toggleSectionRegExp = new RegExp(r"^t(\d+)$");

/// This is the main workflow step, where the user is asked what to do with the
/// failure and input comments etc. For every test, [onShow] is called with the
/// remaining tests including the one to work on.
class FixFailingTest extends WorkflowStep<List<FailingTest>> {
  final TestResult _testResult;
  FixWorkingItem _currentWorkingItem;
  List<FailingTest> _remainingTests;

  // These fields are mutated to persist user input.
  String _lastComment = null;
  FixWorkingItem _lastWorkingItem;
  List<StatusSectionWithFile> _customSections = [];
  bool _fixIfPossible = false;

  FixFailingTest(this._testResult);

  @override
  Future<WorkflowAction> onShow(List<FailingTest> payload) async {
    if (payload.isEmpty) {
      print("Finished updating status files from failing tests.");
      print("Trying to find if any new errors have arised from the fixes.");
      return new NavigateStepWorkflowAction(
          new PresentFailures(), [_testResult]);
    }
    // We have to compute status files on every show, because we modify the
    // status files on every fix.
    var statusExpectations = new StatusExpectations(_testResult);
    await statusExpectations.loadStatusFiles();

    _remainingTests = payload.sublist(1);
    var failingTest = payload.first;

    if (!failingTest.stillFailing(statusExpectations)) {
      return new NavigateStepWorkflowAction(this, _remainingTests);
    }

    _currentWorkingItem = new FixWorkingItem(failingTest.result.name,
        failingTest, statusExpectations, _lastComment, this._customSections);
    _currentWorkingItem.init();

    if (_lastWorkingItem != null && _fixIfPossible) {
      // Outcome may be larger from the previous one, but current newOutcome
      // will always be a singleton list. So we check by matching first
      // element.
      var outcomeIsSame = _currentWorkingItem.newOutcome.first ==
          _lastWorkingItem.newOutcome.first;
      var lastConfigurations =
          _lastWorkingItem.failingTest.failingConfigurations;
      var currentConfigurations =
          _currentWorkingItem.failingTest.failingConfigurations;
      var sameConfigurations = lastConfigurations.length ==
              currentConfigurations.length &&
          lastConfigurations.every(
              (configuration) => currentConfigurations.contains(configuration));
      if (outcomeIsSame && sameConfigurations) {
        _lastWorkingItem.currentSections.forEach((section) {
          addExpressionToCustomSections(
              section.section.condition, section.statusFile.path);
        });
        print("Auto-fixing ${_currentWorkingItem.name}");
        await fixFailingTest();
        return new NavigateStepWorkflowAction(this, _remainingTests);
      }
    }

    print("");
    print("${_remainingTests.length + 1} tests remaining.");
    askAboutTest();

    return new WaitForInputWorkflowAction();
  }

  @override
  Future<WorkflowAction> input(String input) async {
    bool error = false;
    if (input.isEmpty) {
      _fixIfPossible = false;
      await fixFailingTest();
      return new NavigateStepWorkflowAction(this, _remainingTests);
    } else if (input == "a") {
      // Add expression.
      var expression = getNewExpressionFromCommandLine();
      if (expression != null) {
        var statusFile = getStatusFile(_currentWorkingItem);
        addExpressionToCustomSections(expression, statusFile.path);
      }
    } else if (input == "c") {
      // Change comment.
      _currentWorkingItem.comment = getNewComment();
      _lastComment = _currentWorkingItem.comment;
    } else if (input == "f") {
      // Fix failing tests and try to fix the coming ones.
      _fixIfPossible = true;
      await fixFailingTest();
      return new NavigateStepWorkflowAction(this, _remainingTests);
    } else if (input == "o") {
      // Case change new outcome.
      _currentWorkingItem.newOutcome = getNewOutcome();
    } else if (input == "r") {
      // Case reset.
      _currentWorkingItem.init();
    } else if (input == "s") {
      // Case reset.
      return new NavigateStepWorkflowAction(this, _remainingTests);
    } else {
      error = true;
    }
    var toggleMatch = toggleSectionRegExp.firstMatch(input);
    if (toggleMatch != null) {
      var index = int.parse(toggleMatch.group(1));
      error = !_currentWorkingItem.toggleSection(index);
    }
    if (error) {
      print("Input was not correct. Please try again.");
    } else {
      askAboutTest();
    }
    return new WaitForInputWorkflowAction();
  }

  @override
  Future<bool> onLeave() {
    return new Future.value(false);
  }

  /// Prints up to date data about [currentWorkItem] and gives information about
  /// the commands that can be used.
  void askAboutTest() {
    _currentWorkingItem.printInfo();
    print("");
    print("To modify the above data, the following commands are available:");
    print("<Enter> : Write new outcome to selected sections in status files.");
    print("a       : Add/Create section.");
    print("c       : Modify the comment.");
    print("f       : Write new outcome to selected sections in status files "
        "and try to fix remaining tests 'the same way'.");
    print("o       : Modify outcomes.");
    print("r       : Reset to initial state.");
    print("s       : Skip this failure.");
    print("ti      : Toggle selection of section, where i is the index.");
  }

  /// Fixes the failing test based on the data in [_currentWorkingItem].
  Future fixFailingTest() async {
    // Delete all existing entries that are wrong.
    var statusFiles = new Set<StatusFile>();
    for (var statusEntry in _currentWorkingItem.statusEntries) {
      statusEntry.section.entries.remove(statusEntry.entry);
      statusFiles.add(statusEntry.statusFile);
    }
    // Add new expectations to status sections.
    var path = getQualifiedNameForTest(_currentWorkingItem.name);
    var expectations = _currentWorkingItem.newOutcome
        .map((outcome) => Expectation.find(outcome))
        .toList();
    var comment = _currentWorkingItem.comment == null
        ? null
        : new Comment(_currentWorkingItem.comment);
    var statusEntry = new StatusEntry(path, 0, expectations, comment);
    for (var currentSection in _currentWorkingItem.currentSections) {
      if (!currentSection.statusFile.sections
          .contains(currentSection.section)) {
        currentSection.statusFile.sections.add(currentSection.section);
      }
      currentSection.section.entries.add(statusEntry);
      statusFiles.add(currentSection.statusFile);
    }
    // Save the modified status files.
    for (var statusFile in statusFiles) {
      var normalized = normalizeStatusFile(statusFile);
      await new File(statusFile.path).writeAsString(normalized.toString());
    }
    _lastWorkingItem = _currentWorkingItem;
  }

  /// Tries to find a section with the [expression] in [statusFilePath]. If it
  /// cannot find a section, it will create a new section. It selects the new
  /// section on the [currentWorkItem].
  void addExpressionToCustomSections(
      Expression expression, String statusFilePath) {
    expression = expression.normalize();
    var statusFile = _currentWorkingItem
        .statusFiles()
        .firstWhere((statusFile) => statusFile.path == statusFilePath);
    var sectionToAdd = statusFile.sections.firstWhere(
        (section) =>
            section.condition != null &&
            section.condition.normalize().compareTo(expression) == 0,
        orElse: () => null);
    sectionToAdd ??= new StatusSection(expression, 0, []);
    var section = new StatusSectionWithFile(statusFile, sectionToAdd);
    _customSections.add(section);
    _currentWorkingItem.currentSections.add(section);
  }
}

/// Gets a new [Expression] from the commandline. The expression is parsed to
/// make sure it is syntactically correct. If no input is added it returns
/// [null].
Expression getNewExpressionFromCommandLine() {
  print("Write a new status header expression - <Enter> to cancel:");
  String input = stdin.readLineSync();
  if (input.isEmpty) {
    return null;
  }
  try {
    return Expression.parse(input);
  } catch (e) {
    print(e);
    return getNewExpressionFromCommandLine();
  }
}

/// Gets a status file by finding the suite from [workingItem] and asks the
/// user to pick the correct file.
StatusFile getStatusFile(FixWorkingItem workingItem) {
  var statusFiles = workingItem.statusFiles();
  if (statusFiles.length == 1) {
    return statusFiles.first;
  }
  print("Which status file should the section be added to/exists in?");
  int i = 0;
  for (var statusFile in statusFiles) {
    print("  ${i++}: ${statusFile.path}");
  }
  var input = stdin.readLineSync();
  var index = int.parse(input, onError: (_) => null);
  if (index >= 0 && index < statusFiles.length) {
    return statusFiles[index];
  }
  print("Input was not between 0-$i. Please try again");
  return getStatusFile(workingItem);
}

/// Gets a new outcome from the user. The input is a list of strings, but every
/// element has been parsed to check if it is an expectation.
List<String> getNewOutcome() {
  print("Write new outcomes, separate by ',':");
  String input = stdin.readLineSync();
  try {
    var newOutcomes =
        input.split(",").map((outcome) => outcome.trim()).toList();
    newOutcomes.forEach((name) => Expectation.find(name));
    return newOutcomes;
  } catch (e) {
    print(e);
    return getNewOutcome();
  }
}

/// Gets a comment from the user. It automatically adds # if it is not entered
/// and checks if the input is a number, by which it assumes it is an issue.
String getNewComment() {
  print("Write a new comment or github issue. Empty for no comment:");
  String newComment = stdin.readLineSync();
  if (newComment.isEmpty) {
    return null;
  }
  if (int.parse(newComment, onError: (input) => null) != null) {
    return "# Issue $newComment";
  }
  if (!newComment.startsWith("#")) {
    newComment = "# $newComment";
  }
  return newComment;
}

/// [FixWorkingItem] holds the current data about what sections to update,
/// what configurations are covered, the comment, the outcomes etc.
class FixWorkingItem {
  final String name;
  final FailingTest failingTest;
  final StatusExpectations statusExpectations;
  final List<StatusSectionWithFile> customSections;

  List<StatusSectionWithFile> currentSections;
  List<SectionsSuggestion> suggestedSections;
  List<String> newOutcome;
  List<StatusSectionEntry> statusEntries;
  String comment;

  FixWorkingItem(this.name, this.failingTest, this.statusExpectations,
      this.comment, this.customSections) {}

  /// init resets all custom data to the standard values from the failing test,
  /// except the comment and custom added sections.
  void init() {
    newOutcome = [failingTest.result.result];
    statusEntries = failingTest.failingStatusEntries(statusExpectations);
    suggestedSections = failingTest.computeSections(statusExpectations);
    currentSections = [];
  }

  /// Gets the status files for the failing test.
  List<StatusFile> statusFiles() {
    return failingTest.statusFiles(statusExpectations);
  }

  /// Toggles the selection of a section by [index].
  bool toggleSection(int index) {
    var sections =
        suggestedSections.expand((suggested) => suggested.sections).toList();
    sections.addAll(customSections);
    if (index < 0 || index >= sections.length) {
      return false;
    }
    var section = sections[index];
    if (currentSections.contains(section)) {
      currentSections.remove(section);
    } else {
      currentSections.add(section);
    }
    return true;
  }

  /// Prints all information about the current working item.
  void printInfo() {
    print("");
    print("--- ${name} ---");
    print("New (o)utcome: ${newOutcome}");
    print("Failing configurations (covered configurations marked by *):");
    var failingNotCovered = failingTest.failingConfigurationsNotCovered(
        statusExpectations, currentSections);
    failingTest.failingConfigurations.forEach((configuration) {
      String selected = !failingNotCovered.contains(configuration) ? "* " : "";
      print("  $selected${configuration.toArgs(includeSelectors: false)}");
    });
    if (failingTest.passingConfigurations.isEmpty) {
      print("Passing configurations: None");
    } else {
      var passingNotCovered = failingTest.failingConfigurationsNotCovered(
          statusExpectations, currentSections);
      print("Passing configurations (covered configurations marked by x - this "
          "is generally not what you want):");
      failingTest.passingConfigurations.forEach((configuration) {
        String selected = passingNotCovered.contains(configuration) ? "x " : "";
        print("  $selected${configuration.toArgs(includeSelectors: false)}");
      });
    }
    var defaultExpectations =
        expectationsFromTest(failingTest.result.testExpectations);
    defaultExpectations.add(Expectation.pass);
    // Is the outcome the default expectation, i.e. should all entries should be
    // removed.
    bool isDefaultExpectation = newOutcome.length == 1 &&
        defaultExpectations.contains(Expectation.find(newOutcome.first));
    if (isDefaultExpectation) {
      print("The new outcome is the default expectation of the test file.");
    } else {
      _printSections();
    }
    if (statusEntries.isNotEmpty) {
      print("Status entries to be deleted:");
      _printStatusEntries(statusEntries);
    }
    print("Status entry (c)omment:");
    if (comment != null) {
      print("  ${comment}");
    }
  }

  void _printSections() {
    print("Sections to add the new outcome to. The selected sections are "
        "marked by *:");
    int groupCounter = "A".codeUnitAt(0);
    int sectionCounter = 0;
    suggestedSections.forEach((suggestedSection) {
      print("  ${new String.fromCharCode(groupCounter++)} "
          "(${suggestedSection.strategy}):");
      suggestedSection.sections
          .forEach((section) => _printSection(section, sectionCounter++));
    });
    print("  ${new String.fromCharCode(groupCounter)}: Added sections");
    customSections
        .forEach((section) => _printSection(section, sectionCounter++));
  }

  void _printSection(StatusSectionWithFile section, int index) {
    String selected = currentSections.contains(section) ? "* " : "";
    print("    $selected${index}: ${section.statusFile.path}: "
        "[ ${section.section.condition.toString()} ]");
  }

  void _printStatusEntries(List<StatusSectionEntry> entries) {
    for (StatusSectionEntry entry in entries) {
      print("  ${entry.statusFile.path}");
      print("    [ ${entry.section.condition} ]");
      print("      line ${entry.entry.lineNumber}: ${entry.entry.path} : "
          "${entry.entry.expectations} ${entry.entry.comment ?? ""}");
    }
  }
}
