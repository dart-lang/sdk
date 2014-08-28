// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.status;

import 'package:analysis_server/src/protocol.dart';


/**
 * An outcome of a condition checking operation.
 */
class RefactoringStatus {
  /**
   * The current severity of this [RefactoringStatus] - the maximum of the
   * severities of its [entries].
   */
  RefactoringProblemSeverity _severity = null;

  /**
   * A list of [RefactoringProblem]s.
   */
  final List<RefactoringProblem> problems = [];

  /**
   * Creates a new OK [RefactoringStatus].
   */
  RefactoringStatus();

  /**
   * Creates a new [RefactoringStatus] with the ERROR severity.
   */
  factory RefactoringStatus.error(String msg, [Location location]) {
    RefactoringStatus status = new RefactoringStatus();
    status.addError(msg, location);
    return status;
  }

  /**
   * Creates a new [RefactoringStatus] with the FATAL severity.
   */
  factory RefactoringStatus.fatal(String msg, [Location location]) {
    RefactoringStatus status = new RefactoringStatus();
    status.addFatalError(msg, location);
    return status;
  }

  /**
   * Creates a new [RefactoringStatus] with the WARNING severity.
   */
  factory RefactoringStatus.warning(String msg, [Location location]) {
    RefactoringStatus status = new RefactoringStatus();
    status.addWarning(msg, location);
    return status;
  }

  /**
   * Returns `true` if the severity is FATAL or ERROR.
   */
  bool get hasError {
    return _severity == RefactoringProblemSeverity.FATAL ||
        _severity == RefactoringProblemSeverity.ERROR;
  }

  /**
   * Returns `true` if the severity is FATAL.
   */
  bool get hasFatalError => _severity == RefactoringProblemSeverity.FATAL;

  /**
   * Returns `true` if the severity is WARNING.
   */
  bool get hasWarning => _severity == RefactoringProblemSeverity.WARNING;

  /**
   * Return `true` if the severity is `OK`.
   */
  bool get isOK => _severity == null;

  /**
   * Returns the message of the [RefactoringProblem] with highest severity;
   * may be `null` if no problems.
   */
  String get message {
    RefactoringProblem problem = this.problem;
    if (problem == null) {
      return null;
    }
    return problem.message;
  }

  /**
   * Returns the first [RefactoringProblem] with the highest severity.
   *
   * Returns `null` if no entries.
   */
  RefactoringProblem get problem {
    for (RefactoringProblem problem in problems) {
      if (problem.severity == _severity) {
        return problem;
      }
    }
    return null;
  }

  /**
   * Returns the current severity of this [RefactoringStatus].
   */
  RefactoringProblemSeverity get severity => _severity;

  /**
   * Adds an ERROR problem with the given message and location.
   */
  void addError(String msg, [Location location]) {
    _addProblem(
        new RefactoringProblem(
            RefactoringProblemSeverity.ERROR,
            msg,
            location: location));
  }

  /**
   * Adds a FATAL problem with the given message and location.
   */
  void addFatalError(String msg, [Location location]) {
    _addProblem(
        new RefactoringProblem(
            RefactoringProblemSeverity.FATAL,
            msg,
            location: location));
  }

  /**
   * Merges [other] into this [RefactoringStatus].
   *
   * The [other]'s entries are added to this.
   *
   * The resulting severity is the more severe of this and [other] severities.
   *
   * Merging with `null` is allowed - it has no effect.
   */
  void addStatus(RefactoringStatus other) {
    if (other == null) {
      return;
    }
    problems.addAll(other.problems);
    _severity = RefactoringProblemSeverity.max(_severity, other.severity);
  }

  /**
   * Adds a WARNING problem with the given message and location.
   */
  void addWarning(String msg, [Location location]) {
    _addProblem(
        new RefactoringProblem(
            RefactoringProblemSeverity.WARNING,
            msg,
            location: location));
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("<");
    if (_severity == null) {
      sb.write('OK');
    } else {
      sb.write(_severity.name);
    }
    if (!isOK) {
      sb.write("\n");
      for (RefactoringProblem problem in problems) {
        sb.write("\t");
        sb.write(problem);
        sb.write("\n");
      }
    }
    sb.write(">");
    return sb.toString();
  }

  /**
   * Adds the given [RefactoringProblem] and updates [severity].
   */
  void _addProblem(RefactoringProblem problem) {
    problems.add(problem);
    // update maximum severity
    RefactoringProblemSeverity severity = problem.severity;
    _severity = RefactoringProblemSeverity.max(_severity, severity);
  }
}
