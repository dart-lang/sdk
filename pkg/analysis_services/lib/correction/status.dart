// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.status;

import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/correction/source_range.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * An outcome of a condition checking operation.
 */
class RefactoringStatus {
  /**
   * The current severity of this [RefactoringStatus] - the maximum of the
   * severities of its [entries].
   */
  RefactoringStatusSeverity _severity = RefactoringStatusSeverity.OK;

  /**
   * A list of [RefactoringStatusEntry]s.
   */
  final List<RefactoringStatusEntry> entries = [];

  /**
   * Creates a new OK [RefactoringStatus].
   */
  RefactoringStatus();

  /**
   * Creates a new [RefactoringStatus] with the ERROR severity.
   */
  factory RefactoringStatus.error(String msg,
      [RefactoringStatusContext context]) {
    RefactoringStatus status = new RefactoringStatus();
    status.addError(msg, context);
    return status;
  }

  /**
   * Creates a new [RefactoringStatus] with the FATAL severity.
   */
  factory RefactoringStatus.fatal(String msg,
      [RefactoringStatusContext context]) {
    RefactoringStatus status = new RefactoringStatus();
    status.addFatalError(msg, context);
    return status;
  }

  /**
   * Creates a new [RefactoringStatus] with the WARNING severity.
   */
  factory RefactoringStatus.warning(String msg,
      [RefactoringStatusContext context]) {
    RefactoringStatus status = new RefactoringStatus();
    status.addWarning(msg, context);
    return status;
  }

  /**
   * Returns the first [RefactoringStatusEntry] with the highest severity.
   *
   * If there is more than one entry with the highest severity then there is no
   * guarantee as to which will be returned.
   *
   * Returns `null` if no entries.
   */
  RefactoringStatusEntry get entryWithHighestSeverity {
    for (RefactoringStatusEntry entry in entries) {
      if (entry.severity == _severity) {
        return entry;
      }
    }
    return null;
  }

  /**
   * Returns `true` if the severity is FATAL or ERROR.
   */
  bool get hasError =>
      _severity == RefactoringStatusSeverity.FATAL ||
          _severity == RefactoringStatusSeverity.ERROR;

  /**
   * Returns `true` if the severity is FATAL.
   */
  bool get hasFatalError => _severity == RefactoringStatusSeverity.FATAL;

  /**
   * Returns `true` if the severity is WARNING.
   */
  bool get hasWarning => _severity == RefactoringStatusSeverity.WARNING;

  /**
   * Return `true` if the severity is `OK`.
   */
  bool get isOK => _severity == RefactoringStatusSeverity.OK;

  /**
   * Returns the message of the [RefactoringStatusEntry] with highest severity;
   * may be `null` if no entries.
   */
  String get message {
    RefactoringStatusEntry entry = entryWithHighestSeverity;
    if (entry == null) {
      return null;
    }
    return entry.message;
  }

  /**
   * Returns the current severity of this [RefactoringStatus].
   */
  RefactoringStatusSeverity get severity => _severity;

  /**
   * Adds an ERROR entry with the given message and status.
   */
  void addError(String msg, [RefactoringStatusContext context]) {
    _addEntry(
        new RefactoringStatusEntry(RefactoringStatusSeverity.ERROR, msg, context));
  }

  /**
   * Adds a FATAL entry with the given message and status.
   */
  void addFatalError(String msg, [RefactoringStatusContext context]) {
    _addEntry(
        new RefactoringStatusEntry(RefactoringStatusSeverity.FATAL, msg, context));
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
    entries.addAll(other.entries);
    _severity = RefactoringStatusSeverity._max(_severity, other.severity);
  }

  /**
   * Adds a WARNING entry with the given message and status.
   */
  void addWarning(String msg, [RefactoringStatusContext context]) {
    _addEntry(
        new RefactoringStatusEntry(RefactoringStatusSeverity.WARNING, msg, context));
  }

  /**
   * Returns a copy of this [RefactoringStatus] with ERROR replaced with FATAL.
   */
  RefactoringStatus escalateErrorToFatal() {
    RefactoringStatus result = new RefactoringStatus();
    for (RefactoringStatusEntry entry in entries) {
      if (entry.severity == RefactoringStatusSeverity.ERROR) {
        entry = new RefactoringStatusEntry(
            RefactoringStatusSeverity.FATAL,
            entry.message,
            entry.context);
      }
      result._addEntry(entry);
    }
    return result;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("<");
    sb.write(_severity.name);
    if (!isOK) {
      sb.write("\n");
      for (RefactoringStatusEntry entry in entries) {
        sb.write("\t");
        sb.write(entry);
        sb.write("\n");
      }
    }
    sb.write(">");
    return sb.toString();
  }

  /**
   * Adds the given [RefactoringStatusEntry] and updates [severity].
   */
  void _addEntry(RefactoringStatusEntry entry) {
    entries.add(entry);
    _severity = RefactoringStatusSeverity._max(_severity, entry.severity);
  }
}


/**
 * [RefactoringStatusContext] can be used to annotate [RefactoringStatusEntry]s
 * with additional information typically presented in the user interface.
 */
class RefactoringStatusContext {
  /**
   * The [AnalysisContext] in which this status occurs.
   */
  final AnalysisContext context;

  /**
   * The [Source] in which this status occurs.
   */
  final Source source;

  /**
   * The [SourceRange] with specific location where this status occurs.
   */
  final SourceRange range;

  /**
   * Creates a new [RefactoringStatusContext].
   */
  RefactoringStatusContext(this.context, this.source, this.range);

  /**
   * Creates a new [RefactoringStatusContext] for the given [Element].
   */
  factory RefactoringStatusContext.forElement(Element element) {
    AnalysisContext context = element.context;
    Source source = element.source;
    SourceRange range = rangeElementName(element);
    return new RefactoringStatusContext(context, source, range);
  }

  /**
   * Creates a new [RefactoringStatusContext] for the given [SearchMatch].
   */
  factory RefactoringStatusContext.forMatch(SearchMatch match) {
    Element enclosingElement = match.element;
    return new RefactoringStatusContext(
        enclosingElement.context,
        enclosingElement.source,
        match.sourceRange);
  }

  /**
   * Creates a new [RefactoringStatusContext] for the given [AstNode].
   */
  factory RefactoringStatusContext.forNode(AstNode node) {
    CompilationUnit unit = node.getAncestor((node) => node is CompilationUnit);
    CompilationUnitElement unitElement = unit.element;
    AnalysisContext context = unitElement.context;
    Source source = unitElement.source;
    SourceRange range = rangeNode(node);
    return new RefactoringStatusContext(context, source, range);
  }

  /**
   * Creates a new [RefactoringStatusContext] for the given [CompilationUnit].
   */
  factory RefactoringStatusContext.forUnit(CompilationUnit unit,
      SourceRange range) {
    CompilationUnitElement unitElement = unit.element;
    AnalysisContext context = unitElement.context;
    Source source = unitElement.source;
    return new RefactoringStatusContext(context, source, range);
  }

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[source=");
    builder.append(source);
    builder.append(", range=");
    builder.append(range);
    builder.append("]");
    return builder.toString();
  }
}


/**
 * An immutable object representing an entry in a [RefactoringStatus].
 *
 * A [RefactoringStatusEntry] consists of a severity, a message and a context.
 */
class RefactoringStatusEntry {
  /**
   * The severity level.
   */
  final RefactoringStatusSeverity severity;

  /**
   * The message of the status entry.
   */
  final String message;

  /**
   * The [RefactoringStatusContext] which can be used to show more detailed
   * information regarding this status entry in the UI.
   *
   * May be `null` indicating that no context is available.
   */
  final RefactoringStatusContext context;

  RefactoringStatusEntry(this.severity, this.message, [this.context]);

  /**
   * Returns whether the entry represents an error or not.
   */
  bool get isError => severity == RefactoringStatusSeverity.ERROR;

  /**
   * Returns whether the entry represents a fatal error or not.
   */
  bool get isFatalError => severity == RefactoringStatusSeverity.FATAL;

  /**
   * Returns whether the entry represents a warning or not.
   */
  bool get isWarning => severity == RefactoringStatusSeverity.WARNING;

  @override
  String toString() {
    if (context != null) {
      return "${severity}: ${message}; Context: ${context}";
    } else {
      return "${severity}: ${message}";
    }
  }
}


/**
 * Severity of [RefactoringStatus].
 */
class RefactoringStatusSeverity {
  /**
   * The severity indicating the nominal case.
   */
  static const OK = const RefactoringStatusSeverity('OK', 0);

  /**
   * The severity indicating a warning.
   *
   * Use this severity if the refactoring can be performed, but you assume that
   * the user could not be aware of problems or confusions resulting from the
   * execution.
   */
  static const WARNING = const RefactoringStatusSeverity('WARNING', 2);

  /**
   * The severity indicating an error.
   *
   * Use this severity if the refactoring can be performed, but the refactoring
   * will not be behavior preserving and/or the partial execution will lead to
   * an inconsistent state (e.g. compile errors).
   */
  static const ERROR = const RefactoringStatusSeverity('ERROR', 3);

  /**
   * The severity indicating a fatal error.
   *
   * Use this severity if the refactoring cannot be performed, and execution
   * would lead to major problems. Note that this completely blocks the user
   * from performing this refactoring.
   *
   * It is often preferable to use an [ERROR] status and allow a partial
   * execution (e.g. if just one reference to a refactored element cannot be
   * updated).
   */
  static const FATAL = const RefactoringStatusSeverity('FATAL', 4);

  final String name;
  final int ordinal;

  const RefactoringStatusSeverity(this.name, this.ordinal);

  @override
  String toString() => name;

  /**
   * Returns the most severe [RefactoringStatusSeverity].
   */
  static RefactoringStatusSeverity _max(RefactoringStatusSeverity a,
      RefactoringStatusSeverity b) {
    if (b.ordinal > a.ordinal) {
      return b;
    }
    return a;
  }
}
