// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.status;

import 'package:analysis_server/src/protocol2.dart' hide Element;
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Creates a new [Location].
 */
Location createLocation(AnalysisContext context, Source source,
    SourceRange range) {
  int startLine = 0;
  int startColumn = 0;
  {
    LineInfo lineInfo = context.getLineInfo(source);
    if (lineInfo != null) {
      LineInfo_Location offsetLocation = lineInfo.getLocation(range.offset);
      startLine = offsetLocation.lineNumber;
      startColumn = offsetLocation.columnNumber;
    }
  }
  return new Location(
      source.fullName,
      range.offset,
      range.length,
      startLine,
      startColumn);
}


/**
 * Creates a new [Location] for the given [Element].
 */
Location createLocation_forElement(Element element) {
  AnalysisContext context = element.context;
  Source source = element.source;
  SourceRange range = rangeElementName(element);
  return createLocation(context, source, range);
}


/**
 * Creates a new [Location] for the given [SearchMatch].
 */
Location createLocation_forMatch(SearchMatch match) {
  Element enclosingElement = match.element;
  return createLocation(
      enclosingElement.context,
      enclosingElement.source,
      match.sourceRange);
}


/**
 * Creates a new [Location] for the given [AstNode].
 */
Location createLocation_forNode(AstNode node) {
  CompilationUnit unit = node.getAncestor((node) => node is CompilationUnit);
  CompilationUnitElement unitElement = unit.element;
  AnalysisContext context = unitElement.context;
  Source source = unitElement.source;
  SourceRange range = rangeNode(node);
  return createLocation(context, source, range);
}


/**
 * Creates a new [Location] for the given [CompilationUnit].
 */
Location createLocation_forUnit(CompilationUnit unit, SourceRange range) {
  CompilationUnitElement unitElement = unit.element;
  AnalysisContext context = unitElement.context;
  Source source = unitElement.source;
  return createLocation(context, source, range);
}


RefactoringProblemSeverity _maxSeverity(RefactoringProblemSeverity a,
    RefactoringProblemSeverity b) {
  if (b == null) {
    return a;
  }
  if (a == null) {
    return b;
  } else if (a == RefactoringProblemSeverity.INFO) {
    return b;
  } else if (a == RefactoringProblemSeverity.WARNING) {
    if (b == RefactoringProblemSeverity.ERROR ||
        b == RefactoringProblemSeverity.FATAL) {
      return b;
    }
  } else if (a == RefactoringProblemSeverity.ERROR) {
    if (b == RefactoringProblemSeverity.FATAL) {
      return b;
    }
  }
  return a;
}

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
    _severity = _maxSeverity(_severity, other.severity);
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
    _severity = _maxSeverity(_severity, severity);
  }
}
