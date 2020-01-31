// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol_dart.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/search/search_engine.dart'
    as engine;
import 'package:analyzer/dart/analysis/results.dart' as engine;
import 'package:analyzer/dart/ast/ast.dart' as engine;
import 'package:analyzer/dart/ast/visitor.dart' as engine;
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/dart/element/type.dart' as engine;
import 'package:analyzer/diagnostic/diagnostic.dart' as engine;
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/utilities.dart' as engine;
import 'package:analyzer/src/error/codes.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/source.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart' as engine;
import 'package:analyzer_plugin/protocol/protocol_common.dart';

export 'package:analysis_server/plugin/protocol/protocol_dart.dart';
export 'package:analysis_server/protocol/protocol.dart';
export 'package:analysis_server/protocol/protocol_generated.dart';
export 'package:analyzer_plugin/protocol/protocol_common.dart';

/**
 * Returns a list of AnalysisErrors corresponding to the given list of Engine
 * errors.
 */
List<AnalysisError> doAnalysisError_listFromEngine(
    engine.ResolvedUnitResult result) {
  return mapEngineErrors(result, result.errors, newAnalysisError_fromEngine);
}

/**
 * Adds [edit] to the file containing the given [element].
 */
void doSourceChange_addElementEdit(
    SourceChange change, engine.Element element, SourceEdit edit) {
  engine.Source source = element.source;
  doSourceChange_addSourceEdit(change, source, edit);
}

/**
 * Adds [edit] for the given [source] to the [change].
 */
void doSourceChange_addSourceEdit(
    SourceChange change, engine.Source source, SourceEdit edit,
    {bool isNewFile = false}) {
  String file = source.fullName;
  change.addEdit(file, isNewFile ? -1 : 0, edit);
}

String getReturnTypeString(engine.Element element) {
  if (element is engine.ExecutableElement) {
    if (element.kind == engine.ElementKind.SETTER) {
      return null;
    } else {
      return element.returnType?.toString();
    }
  } else if (element is engine.VariableElement) {
    engine.DartType type = element.type;
    return type != null
        ? type.getDisplayString(withNullability: false)
        : 'dynamic';
  } else if (element is engine.FunctionTypeAliasElement) {
    return element.function.returnType.toString();
  } else {
    return null;
  }
}

/**
 * Translates engine errors through the ErrorProcessor.
 */
List<T> mapEngineErrors<T>(
    engine.ResolvedUnitResult result,
    List<engine.AnalysisError> errors,
    T Function(engine.ResolvedUnitResult result, engine.AnalysisError error,
            [engine.ErrorSeverity errorSeverity])
        constructor) {
  engine.AnalysisOptions analysisOptions =
      result.session.analysisContext.analysisOptions;
  List<T> serverErrors = <T>[];
  for (engine.AnalysisError error in errors) {
    ErrorProcessor processor =
        ErrorProcessor.getProcessor(analysisOptions, error);
    if (processor != null) {
      engine.ErrorSeverity severity = processor.severity;
      // Errors with null severity are filtered out.
      if (severity != null) {
        // Specified severities override.
        serverErrors.add(constructor(result, error, severity));
      }
    } else {
      serverErrors.add(constructor(result, error));
    }
  }
  return serverErrors;
}

/**
 * Construct based on error information from the analyzer engine.
 *
 * If an [errorSeverity] is specified, it will override the one in [error].
 */
AnalysisError newAnalysisError_fromEngine(
    engine.ResolvedUnitResult result, engine.AnalysisError error,
    [engine.ErrorSeverity errorSeverity]) {
  engine.ErrorCode errorCode = error.errorCode;
  // prepare location
  Location location;
  {
    String file = error.source.fullName;
    int offset = error.offset;
    int length = error.length;
    int startLine = -1;
    int startColumn = -1;
    engine.LineInfo lineInfo = result.lineInfo;
    if (lineInfo != null) {
      CharacterLocation lineLocation = lineInfo.getLocation(offset);
      if (lineLocation != null) {
        startLine = lineLocation.lineNumber;
        startColumn = lineLocation.columnNumber;
      }
    }
    location = Location(file, offset, length, startLine, startColumn);
  }

  // Default to the error's severity if none is specified.
  errorSeverity ??= errorCode.errorSeverity;

  // done
  var severity = AnalysisErrorSeverity(errorSeverity.name);
  var type = AnalysisErrorType(errorCode.type.name);
  String message = error.message;
  String code = errorCode.name.toLowerCase();
  List<DiagnosticMessage> contextMessages;
  if (error.contextMessages.isNotEmpty) {
    contextMessages = error.contextMessages
        .map((message) => newDiagnosticMessage(result, message))
        .toList();
  }
  String correction = error.correction;
  bool fix = hasFix(error.errorCode);
  String url = errorCode.url;
  return AnalysisError(severity, type, location, message, code,
      contextMessages: contextMessages,
      correction: correction,
      hasFix: fix,
      url: url);
}

/**
 * Create a DiagnosticMessage based on an [engine.DiagnosticMessage].
 */
DiagnosticMessage newDiagnosticMessage(
    engine.ResolvedUnitResult result, engine.DiagnosticMessage message) {
  String file = message.filePath;
  int offset = message.offset;
  int length = message.length;
  int startLine = -1;
  int startColumn = -1;
  engine.LineInfo lineInfo = result.session.getFile(file).lineInfo;
  if (lineInfo != null) {
    CharacterLocation lineLocation = lineInfo.getLocation(offset);
    if (lineLocation != null) {
      startLine = lineLocation.lineNumber;
      startColumn = lineLocation.columnNumber;
    }
  }
  return DiagnosticMessage(
      message.message, Location(file, offset, length, startLine, startColumn));
}

/**
 * Create a Location based on an [engine.Element].
 */
Location newLocation_fromElement(engine.Element element) {
  if (element == null || element.source == null) {
    return null;
  }
  int offset = element.nameOffset;
  int length = element.nameLength;
  if (element is engine.CompilationUnitElement ||
      (element is engine.LibraryElement && offset < 0)) {
    offset = 0;
    length = 0;
  }
  engine.CompilationUnitElement unitElement = _getUnitElement(element);
  engine.SourceRange range = engine.SourceRange(offset, length);
  return _locationForArgs(unitElement, range);
}

/**
 * Create a Location based on an [engine.SearchMatch].
 */
Location newLocation_fromMatch(engine.SearchMatch match) {
  engine.CompilationUnitElement unitElement = _getUnitElement(match.element);
  return _locationForArgs(unitElement, match.sourceRange);
}

/**
 * Create a Location based on an [engine.AstNode].
 */
Location newLocation_fromNode(engine.AstNode node) {
  engine.CompilationUnit unit =
      node.thisOrAncestorOfType<engine.CompilationUnit>();
  engine.CompilationUnitElement unitElement = unit.declaredElement;
  engine.SourceRange range = engine.SourceRange(node.offset, node.length);
  return _locationForArgs(unitElement, range);
}

/**
 * Create a Location based on an [engine.CompilationUnit].
 */
Location newLocation_fromUnit(
    engine.CompilationUnit unit, engine.SourceRange range) {
  return _locationForArgs(unit.declaredElement, range);
}

/**
 * Construct based on an element from the analyzer engine.
 */
OverriddenMember newOverriddenMember_fromEngine(engine.Element member) {
  Element element = convertElement(member);
  String className = member.enclosingElement.displayName;
  return OverriddenMember(element, className);
}

/**
 * Construct based on a value from the search engine.
 */
SearchResult newSearchResult_fromMatch(engine.SearchMatch match) {
  SearchResultKind kind = newSearchResultKind_fromEngine(match.kind);
  Location location = newLocation_fromMatch(match);
  List<Element> path = _computePath(match.element);
  return SearchResult(location, kind, !match.isResolved, path);
}

/**
 * Construct based on a value from the search engine.
 */
SearchResultKind newSearchResultKind_fromEngine(engine.MatchKind kind) {
  if (kind == engine.MatchKind.DECLARATION) {
    return SearchResultKind.DECLARATION;
  }
  if (kind == engine.MatchKind.READ) {
    return SearchResultKind.READ;
  }
  if (kind == engine.MatchKind.READ_WRITE) {
    return SearchResultKind.READ_WRITE;
  }
  if (kind == engine.MatchKind.WRITE) {
    return SearchResultKind.WRITE;
  }
  if (kind == engine.MatchKind.INVOCATION) {
    return SearchResultKind.INVOCATION;
  }
  if (kind == engine.MatchKind.REFERENCE) {
    return SearchResultKind.REFERENCE;
  }
  return SearchResultKind.UNKNOWN;
}

/**
 * Construct based on a SourceRange.
 */
SourceEdit newSourceEdit_range(engine.SourceRange range, String replacement,
    {String id}) {
  return SourceEdit(range.offset, range.length, replacement, id: id);
}

List<Element> _computePath(engine.Element element) {
  List<Element> path = <Element>[];
  while (element != null) {
    path.add(convertElement(element));
    // go up
    if (element is engine.PrefixElement) {
      // imports are library children, but they are physically in the unit
      engine.LibraryElement library = element.enclosingElement;
      element = library.definingCompilationUnit;
    } else {
      element = element.enclosingElement;
    }
  }
  return path;
}

engine.CompilationUnitElement _getUnitElement(engine.Element element) {
  if (element is engine.CompilationUnitElement) {
    return element;
  }
  if (element?.enclosingElement is engine.LibraryElement) {
    element = element.enclosingElement;
  }
  if (element is engine.LibraryElement) {
    return element.definingCompilationUnit;
  }
  for (; element != null; element = element.enclosingElement) {
    if (element is engine.CompilationUnitElement) {
      return element;
    }
  }
  return null;
}

/**
 * Creates a new [Location].
 */
Location _locationForArgs(
    engine.CompilationUnitElement unitElement, engine.SourceRange range) {
  int startLine = 0;
  int startColumn = 0;
  try {
    engine.LineInfo lineInfo = unitElement.lineInfo;
    if (lineInfo != null) {
      CharacterLocation offsetLocation = lineInfo.getLocation(range.offset);
      startLine = offsetLocation.lineNumber;
      startColumn = offsetLocation.columnNumber;
    }
  } on AnalysisException {
    // TODO(brianwilkerson) It doesn't look like the code in the try block
    //  should be able to throw an exception. Try removing the try statement.
  }
  return Location(unitElement.source.fullName, range.offset, range.length,
      startLine, startColumn);
}
