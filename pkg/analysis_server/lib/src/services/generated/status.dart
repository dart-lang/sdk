// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.status;

import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'stubs.dart';

/**
 * Outcome of a condition checking operation.
 */
class RefactoringStatus {
  /**
   * @return the new [RefactoringStatus] with [RefactoringStatusSeverity#ERROR].
   */
  static RefactoringStatus createErrorStatus(String msg) {
    RefactoringStatus status = new RefactoringStatus();
    status.addError(msg);
    return status;
  }

  /**
   * @return the new [RefactoringStatus] with [RefactoringStatusSeverity#FATAL].
   */
  static RefactoringStatus createFatalErrorStatus(String msg, [RefactoringStatusContext context]) {
    RefactoringStatus status = new RefactoringStatus();
    status.addFatalError(msg, context);
    return status;
  }

  /**
   * @return the new [RefactoringStatus] with [RefactoringStatusSeverity#WARNING].
   */
  static RefactoringStatus createWarningStatus(String msg) {
    RefactoringStatus status = new RefactoringStatus();
    status.addWarning(msg);
    return status;
  }

  /**
   * @return the [Enum] value with maximal ordinal.
   */
  static Enum _max(Enum a, Enum b) {
    if (b.ordinal > a.ordinal) {
      return b;
    }
    return a;
  }

  RefactoringStatusSeverity _severity = RefactoringStatusSeverity.OK;

  final List<RefactoringStatusEntry> entries = [];

  /**
   * Adds a <code>ERROR</code> entry filled with the given message and status to this status.
   */
  void addError(String msg, [RefactoringStatusContext context]) {
    _addEntry(new RefactoringStatusEntry(RefactoringStatusSeverity.ERROR, msg, context));
  }

  /**
   * Adds a <code>FATAL</code> entry filled with the given message and status to this status.
   */
  void addFatalError(String msg, [RefactoringStatusContext context]) {
    _addEntry(new RefactoringStatusEntry(RefactoringStatusSeverity.FATAL, msg, context));
  }

  /**
   * Adds a <code>WARNING</code> entry filled with the given message and status to this status.
   */
  void addWarning(String msg, [RefactoringStatusContext context]) {
    _addEntry(new RefactoringStatusEntry(RefactoringStatusSeverity.WARNING, msg, context));
  }

  /**
   * @return the copy of this [RefactoringStatus] with [RefactoringStatusSeverity#ERROR]
   *         replaced with [RefactoringStatusSeverity#FATAL].
   */
  RefactoringStatus escalateErrorToFatal() {
    RefactoringStatus result = new RefactoringStatus();
    for (RefactoringStatusEntry entry in entries) {
      RefactoringStatusSeverity severity = entry.severity;
      if (severity == RefactoringStatusSeverity.ERROR) {
        severity = RefactoringStatusSeverity.FATAL;
      }
      result._addEntry(new RefactoringStatusEntry(severity, entry.message, entry.context));
    }
    return result;
  }

  /**
   * @return the RefactoringStatusEntry with the highest severity, or <code>null</code> if no
   *         entries are present.
   */
  RefactoringStatusEntry get entryWithHighestSeverity {
    if (entries.isEmpty) {
      return null;
    }
    RefactoringStatusEntry result = entries[0];
    for (RefactoringStatusEntry entry in entries) {
      if (result.severity.ordinal < entry.severity.ordinal) {
        result = entry;
      }
    }
    return result;
  }

  /**
   * @return the message from the [RefactoringStatusEntry] with highest severity; may be
   *         <code>null</code> if not entries are present.
   */
  String get message {
    RefactoringStatusEntry entry = entryWithHighestSeverity;
    if (entry == null) {
      return null;
    }
    return entry.message;
  }

  /**
   * @return the current severity of the [RefactoringStatus].
   */
  RefactoringStatusSeverity get severity => _severity;

  /**
   * @return <code>true</code> if the current severity is <code>
   *  FATAL</code> or <code>ERROR</code>.
   */
  bool get hasError => _severity == RefactoringStatusSeverity.FATAL || _severity == RefactoringStatusSeverity.ERROR;

  /**
   * @return <code>true</code> if the current severity is <code>FATAL</code>.
   */
  bool get hasFatalError => _severity == RefactoringStatusSeverity.FATAL;

  /**
   * @return <code>true</code> if the current severity is <code>
   *  FATAL</code>, <code>ERROR</code>, <code>WARNING</code> or <code>INFO</code>.
   */
  bool get hasInfo => _severity == RefactoringStatusSeverity.FATAL || _severity == RefactoringStatusSeverity.ERROR || _severity == RefactoringStatusSeverity.WARNING || _severity == RefactoringStatusSeverity.INFO;

  /**
   * @return <code>true</code> if the current severity is <code>
   *  FATAL</code>, <code>ERROR</code> or <code>WARNING</code>.
   */
  bool get hasWarning => _severity == RefactoringStatusSeverity.FATAL || _severity == RefactoringStatusSeverity.ERROR || _severity == RefactoringStatusSeverity.WARNING;

  /**
   * @return <code>true</code> if the severity is <code>OK</code>.
   */
  bool get isOK => _severity == RefactoringStatusSeverity.OK;

  /**
   * Merges the receiver and the parameter statuses. The resulting list of entries in the receiver
   * will contain entries from both. The resulting severity in the receiver will be the more severe
   * of its current severity and the parameter's severity. Merging with <code>null</code> is allowed
   * - it has no effect.
   */
  void merge(RefactoringStatus other) {
    if (other == null) {
      return;
    }
    entries.addAll(other.entries);
    _severity = _max(_severity, other.severity);
  }

  @override
  String toString() {
    JavaStringBuilder sb = new JavaStringBuilder();
    sb.append("<").append(_severity.name);
    if (!isOK) {
      sb.append("\n");
      for (RefactoringStatusEntry entry in entries) {
        sb.append("\t").append(entry).append("\n");
      }
    }
    sb.append(">");
    return sb.toString();
  }

  /**
   * Adds given [RefactoringStatusEntry] and updates [severity].
   */
  void _addEntry(RefactoringStatusEntry entry) {
    entries.add(entry);
    _severity = _max(_severity, entry.severity);
  }
}

/**
 * [RefactoringStatusContext] can be used to annotate a [RefactoringStatusEntry] with
 * additional information typically presented in the user interface.
 */
class RefactoringStatusContext {
  /**
   * @return the [RefactoringStatusContext] that corresponds to the given [SearchMatch].
   */
  static RefactoringStatusContext create(SearchMatch match) {
    Element enclosingElement = match.element;
    return new RefactoringStatusContext(enclosingElement.context, enclosingElement.source, match.sourceRange);
  }

  AnalysisContext _context;

  Source _source;

  SourceRange _range;

  RefactoringStatusContext(AnalysisContext context, Source source, SourceRange range) {
    this._context = context;
    this._source = source;
    this._range = range;
  }

  /**
   * Creates a new [RefactoringStatusContext] which corresponds to the given [AstNode].
   */
  RefactoringStatusContext.forNode(AstNode node) {
    CompilationUnit unit = node.getAncestor((node) => node is CompilationUnit);
    CompilationUnitElement unitElement = unit.element;
    this._context = unitElement.context;
    this._source = unitElement.source;
    this._range = SourceRangeFactory.rangeNode(node);
  }

  /**
   * Creates a new [RefactoringStatusContext] which corresponds to given location in the
   * [Source] of the given [CompilationUnit].
   */
  RefactoringStatusContext.forUnit(CompilationUnit unit, SourceRange range) {
    CompilationUnitElement unitElement = unit.element;
    this._context = unitElement.context;
    this._source = unitElement.source;
    this._range = range;
  }

  /**
   * @return the [RefactoringStatusContext] which corresponds to the declaration of the given
   *         [Element].
   */
  RefactoringStatusContext.forElement(Element element) {
    this._context = element.context;
    this._source = element.source;
    this._range = SourceRangeFactory.rangeElementName(element);
  }

  /**
   * @return the [AnalysisContext] in which this status occurs.
   */
  AnalysisContext get context => _context;

  /**
   * @return the [SourceRange] with specific location where this status occurs.
   */
  SourceRange get range => _range;

  /**
   * @return the [Source] in which this status occurs.
   */
  Source get source => _source;

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[source=");
    builder.append(_source);
    builder.append(", range=");
    builder.append(_range);
    builder.append("]");
    return builder.toString();
  }
}

/**
 * An immutable object representing an entry in the list in [RefactoringStatus]. A refactoring
 * status entry consists of a severity, a message and a context object.
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
   * The [RefactoringStatusContext] which can be used to show more detailed information
   * regarding this status entry in the UI. May be `null` indicating that no context is
   * available.
   */
  RefactoringStatusContext _context;

  RefactoringStatusEntry(this.severity, this.message, [RefactoringStatusContext ctx]) {
    this._context = ctx;
  }

  /**
   * @return the [RefactoringStatusContext] which can be used to show more detailed
   *         information regarding this status entry in the UI. The method may return `null`
   *         indicating that no context is available.
   */
  RefactoringStatusContext get context => _context;

  /**
   * Returns whether the entry represents an error or not.
   *
   * @return <code>true</code> if (severity ==<code>RefactoringStatusSeverity.ERROR</code>).
   */
  bool get isError => severity == RefactoringStatusSeverity.ERROR;

  /**
   * Returns whether the entry represents a fatal error or not.
   *
   * @return <code>true</code> if (severity ==<code>RefactoringStatusSeverity.FATAL</code>)
   */
  bool get isFatalError => severity == RefactoringStatusSeverity.FATAL;

  /**
   * Returns whether the entry represents an information or not.
   *
   * @return <code>true</code> if (severity ==<code>RefactoringStatusSeverity.INFO</code>).
   */
  bool get isInfo => severity == RefactoringStatusSeverity.INFO;

  /**
   * Returns whether the entry represents a warning or not.
   *
   * @return <code>true</code> if (severity ==<code>RefactoringStatusSeverity.WARNING</code>).
   */
  bool get isWarning => severity == RefactoringStatusSeverity.WARNING;

  @override
  String toString() {
    if (_context != null) {
      return "${severity}: ${message}; Context: ${_context}";
    } else {
      return "${severity}: ${message}";
    }
  }
}

/**
 * Severity of [RefactoringStatus].
 */
class RefactoringStatusSeverity extends Enum<RefactoringStatusSeverity> {
  static const RefactoringStatusSeverity OK = const RefactoringStatusSeverity('OK', 0);

  static const RefactoringStatusSeverity INFO = const RefactoringStatusSeverity('INFO', 1);

  static const RefactoringStatusSeverity WARNING = const RefactoringStatusSeverity('WARNING', 2);

  static const RefactoringStatusSeverity ERROR = const RefactoringStatusSeverity('ERROR', 3);

  static const RefactoringStatusSeverity FATAL = const RefactoringStatusSeverity('FATAL', 4);

  static const List<RefactoringStatusSeverity> values = const [OK, INFO, WARNING, ERROR, FATAL];

  const RefactoringStatusSeverity(String name, int ordinal) : super(name, ordinal);
}