// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library protocol.server;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/plugin/protocol/protocol_dart.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/search/search_engine.dart'
    as engine;
import 'package:analyzer/dart/ast/ast.dart' as engine;
import 'package:analyzer/dart/ast/visitor.dart' as engine;
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/dart/element/type.dart' as engine;
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/dart/ast/utilities.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/source.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart' as engine;

export 'package:analysis_server/plugin/protocol/protocol.dart';
export 'package:analysis_server/plugin/protocol/protocol_dart.dart';

/**
 * Returns a list of AnalysisErrors corresponding to the given list of Engine
 * errors.
 */
List<AnalysisError> doAnalysisError_listFromEngine(
    engine.AnalysisContext context,
    engine.LineInfo lineInfo,
    List<engine.AnalysisError> errors) {
  List<AnalysisError> serverErrors = <AnalysisError>[];
  for (engine.AnalysisError error in errors) {
    ErrorProcessor processor = ErrorProcessor.getProcessor(context, error);
    if (processor != null) {
      engine.ErrorSeverity severity = processor.severity;
      // Errors with null severity are filtered out.
      if (severity != null) {
        // Specified severities override.
        serverErrors
            .add(newAnalysisError_fromEngine(lineInfo, error, severity));
      }
    } else {
      serverErrors.add(newAnalysisError_fromEngine(lineInfo, error));
    }
  }
  return serverErrors;
}

/**
 * Adds [edit] to the [FileEdit] for the given [element].
 */
void doSourceChange_addElementEdit(
    SourceChange change, engine.Element element, SourceEdit edit) {
  engine.AnalysisContext context = element.context;
  engine.Source source = element.source;
  doSourceChange_addSourceEdit(change, context, source, edit);
}

/**
 * Adds [edit] to the [FileEdit] for the given [source].
 */
void doSourceChange_addSourceEdit(SourceChange change,
    engine.AnalysisContext context, engine.Source source, SourceEdit edit) {
  String file = source.fullName;
  int fileStamp = context.getModificationStamp(source);
  change.addEdit(file, fileStamp, edit);
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
    return type != null ? type.displayName : 'dynamic';
  } else if (element is engine.FunctionTypeAliasElement) {
    return element.returnType.toString();
  } else {
    return null;
  }
}

/**
 * Construct based on error information from the analyzer engine.
 *
 * If an [errorSeverity] is specified, it will override the one in [error].
 */
AnalysisError newAnalysisError_fromEngine(
    engine.LineInfo lineInfo, engine.AnalysisError error,
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
    if (lineInfo != null) {
      engine.LineInfo_Location lineLocation = lineInfo.getLocation(offset);
      if (lineLocation != null) {
        startLine = lineLocation.lineNumber;
        startColumn = lineLocation.columnNumber;
      }
    }
    location = new Location(file, offset, length, startLine, startColumn);
  }

  // Default to the error's severity if none is specified.
  errorSeverity ??= errorCode.errorSeverity;

  // done
  var severity = new AnalysisErrorSeverity(errorSeverity.name);
  var type = new AnalysisErrorType(errorCode.type.name);
  String message = error.message;
  String code = errorCode.name.toLowerCase();
  String correction = error.correction;
  bool fix = hasFix(error.errorCode);
  return new AnalysisError(severity, type, location, message, code,
      correction: correction, hasFix: fix);
}

/**
 * Create a Location based on an [engine.Element].
 */
Location newLocation_fromElement(engine.Element element) {
  engine.AnalysisContext context = element.context;
  engine.Source source = element.source;
  if (context == null || source == null) {
    return null;
  }
  int offset = element.nameOffset;
  int length = element.nameLength;
  if (element is engine.CompilationUnitElement) {
    offset = 0;
    length = 0;
  }
  engine.SourceRange range = new engine.SourceRange(offset, length);
  return _locationForArgs(context, source, range);
}

/**
 * Create a Location based on an [engine.SearchMatch].
 */
Location newLocation_fromMatch(engine.SearchMatch match) {
  engine.Element enclosingElement = match.element;
  return _locationForArgs(
      enclosingElement.context, enclosingElement.source, match.sourceRange);
}

/**
 * Create a Location based on an [engine.AstNode].
 */
Location newLocation_fromNode(engine.AstNode node) {
  engine.CompilationUnit unit =
      node.getAncestor((node) => node is engine.CompilationUnit);
  engine.CompilationUnitElement unitElement = unit.element;
  engine.AnalysisContext context = unitElement.context;
  engine.Source source = unitElement.source;
  engine.SourceRange range = new engine.SourceRange(node.offset, node.length);
  return _locationForArgs(context, source, range);
}

/**
 * Create a Location based on an [engine.CompilationUnit].
 */
Location newLocation_fromUnit(
    engine.CompilationUnit unit, engine.SourceRange range) {
  engine.CompilationUnitElement unitElement = unit.element;
  engine.AnalysisContext context = unitElement.context;
  engine.Source source = unitElement.source;
  return _locationForArgs(context, source, range);
}

/**
 * Construct based on an element from the analyzer engine.
 */
OverriddenMember newOverriddenMember_fromEngine(engine.Element member) {
  Element element = convertElement(member);
  String className = member.enclosingElement.displayName;
  return new OverriddenMember(element, className);
}

/**
 * Construct based on a value from the search engine.
 */
SearchResult newSearchResult_fromMatch(engine.SearchMatch match) {
  SearchResultKind kind = newSearchResultKind_fromEngine(match.kind);
  Location location = newLocation_fromMatch(match);
  List<Element> path = _computePath(match.element);
  return new SearchResult(location, kind, !match.isResolved, path);
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
  return new SourceEdit(range.offset, range.length, replacement, id: id);
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

/**
 * Creates a new [Location].
 */
Location _locationForArgs(engine.AnalysisContext context, engine.Source source,
    engine.SourceRange range) {
  int startLine = 0;
  int startColumn = 0;
  {
    engine.LineInfo lineInfo = context.getLineInfo(source);
    if (lineInfo != null) {
      engine.LineInfo_Location offsetLocation =
          lineInfo.getLocation(range.offset);
      startLine = offsetLocation.lineNumber;
      startColumn = offsetLocation.columnNumber;
    }
  }
  return new Location(
      source.fullName, range.offset, range.length, startLine, startColumn);
}
