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
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/diagnostic/diagnostic.dart' as engine;
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/generated/source.dart' as engine;
import 'package:analyzer_plugin/protocol/protocol_common.dart';

export 'package:analysis_server/plugin/protocol/protocol_dart.dart';
export 'package:analysis_server/protocol/protocol.dart';
export 'package:analysis_server/protocol/protocol_generated.dart';
export 'package:analyzer_plugin/protocol/protocol_common.dart';

/// Returns a list of AnalysisErrors corresponding to the given list of Engine
/// errors.
List<AnalysisError> doAnalysisError_listFromEngine(
    engine.ResolvedUnitResult result) {
  return mapEngineErrors(result, result.errors, newAnalysisError_fromEngine);
}

/// Adds [edit] to the file containing the given [element].
void doSourceChange_addElementEdit(
    SourceChange change, engine.Element element, SourceEdit edit) {
  var source = element.source;
  doSourceChange_addSourceEdit(change, source, edit);
}

/// Adds [edit] for the given [source] to the [change].
void doSourceChange_addSourceEdit(
    SourceChange change, engine.Source source, SourceEdit edit,
    {bool isNewFile = false}) {
  var file = source.fullName;
  change.addEdit(file, isNewFile ? -1 : 0, edit);
}

String getReturnTypeString(engine.Element element) {
  if (element is engine.ExecutableElement) {
    if (element.kind == engine.ElementKind.SETTER) {
      return null;
    } else {
      return element.returnType?.getDisplayString(withNullability: false);
    }
  } else if (element is engine.VariableElement) {
    var type = element.type;
    return type != null
        ? type.getDisplayString(withNullability: false)
        : 'dynamic';
  } else if (element is engine.TypeAliasElement) {
    var aliasedElement = element.aliasedElement;
    if (aliasedElement is engine.GenericFunctionTypeElement) {
      var returnType = aliasedElement.returnType;
      return returnType.getDisplayString(withNullability: false);
    } else {
      return null;
    }
  } else {
    return null;
  }
}

/// Translates engine errors through the ErrorProcessor.
List<T> mapEngineErrors<T>(
    engine.ResolvedUnitResult result,
    List<engine.AnalysisError> errors,
    T Function(engine.ResolvedUnitResult result, engine.AnalysisError error,
            [engine.ErrorSeverity errorSeverity])
        constructor) {
  var analysisOptions = result.session.analysisContext.analysisOptions;
  var serverErrors = <T>[];
  for (var error in errors) {
    var processor = ErrorProcessor.getProcessor(analysisOptions, error);
    if (processor != null) {
      var severity = processor.severity;
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

/// Construct based on error information from the analyzer engine.
///
/// If an [errorSeverity] is specified, it will override the one in [error].
AnalysisError newAnalysisError_fromEngine(
    engine.ResolvedUnitResult result, engine.AnalysisError error,
    [engine.ErrorSeverity errorSeverity]) {
  var errorCode = error.errorCode;
  // prepare location
  Location location;
  {
    var file = error.source.fullName;
    var offset = error.offset;
    var length = error.length;
    var startLine = -1;
    var startColumn = -1;
    var lineInfo = result.lineInfo;
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
  var message = error.message;
  var code = errorCode.name.toLowerCase();
  List<DiagnosticMessage> contextMessages;
  if (error.contextMessages.isNotEmpty) {
    contextMessages = error.contextMessages
        .map((message) => newDiagnosticMessage(result, message))
        .toList();
  }
  var correction = error.correction;
  var fix = hasFix(error.errorCode);
  var url = errorCode.url;
  return AnalysisError(severity, type, location, message, code,
      contextMessages: contextMessages,
      correction: correction,
      hasFix: fix,
      url: url);
}

/// Create a DiagnosticMessage based on an [engine.DiagnosticMessage].
DiagnosticMessage newDiagnosticMessage(
    engine.ResolvedUnitResult result, engine.DiagnosticMessage message) {
  var file = message.filePath;
  var offset = message.offset;
  var length = message.length;

  var lineLocation = result.lineInfo.getLocation(offset);
  var startLine = lineLocation.lineNumber;
  var startColumn = lineLocation.columnNumber;

  return DiagnosticMessage(
      message.message, Location(file, offset, length, startLine, startColumn));
}

/// Create a Location based on an [engine.Element].
Location newLocation_fromElement(engine.Element element) {
  if (element == null || element.source == null) {
    return null;
  }
  var offset = element.nameOffset;
  var length = element.nameLength;
  if (element is engine.CompilationUnitElement ||
      (element is engine.LibraryElement && offset < 0)) {
    offset = 0;
    length = 0;
  }
  var unitElement = _getUnitElement(element);
  var range = engine.SourceRange(offset, length);
  return _locationForArgs(unitElement, range);
}

/// Create a Location based on an [engine.SearchMatch].
Location newLocation_fromMatch(engine.SearchMatch match) {
  var unitElement = _getUnitElement(match.element);
  return _locationForArgs(unitElement, match.sourceRange);
}

/// Create a Location based on an [engine.AstNode].
Location newLocation_fromNode(engine.AstNode node) {
  var unit = node.thisOrAncestorOfType<engine.CompilationUnit>();
  var unitElement = unit.declaredElement;
  var range = engine.SourceRange(node.offset, node.length);
  return _locationForArgs(unitElement, range);
}

/// Create a Location based on an [engine.CompilationUnit].
Location newLocation_fromUnit(
    engine.CompilationUnit unit, engine.SourceRange range) {
  return _locationForArgs(unit.declaredElement, range);
}

/// Construct based on an element from the analyzer engine.
OverriddenMember newOverriddenMember_fromEngine(engine.Element member) {
  var element = convertElement(member);
  var className = member.enclosingElement.displayName;
  return OverriddenMember(element, className);
}

/// Construct based on a value from the search engine.
SearchResult newSearchResult_fromMatch(engine.SearchMatch match) {
  var kind = newSearchResultKind_fromEngine(match.kind);
  var location = newLocation_fromMatch(match);
  var path = _computePath(match.element);
  return SearchResult(location, kind, !match.isResolved, path);
}

/// Construct based on a value from the search engine.
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

/// Construct based on a SourceRange.
SourceEdit newSourceEdit_range(engine.SourceRange range, String replacement,
    {String id}) {
  return SourceEdit(range.offset, range.length, replacement, id: id);
}

List<Element> _computePath(engine.Element element) {
  var path = <Element>[];
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

/// Creates a new [Location].
Location _locationForArgs(
    engine.CompilationUnitElement unitElement, engine.SourceRange range) {
  var startLine = 0;
  var startColumn = 0;
  try {
    var lineInfo = unitElement.lineInfo;
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
