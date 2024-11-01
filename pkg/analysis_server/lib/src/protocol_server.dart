// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol_dart.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_color.dart';
import 'package:analysis_server/src/services/search/search_engine.dart'
    as engine;
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/analysis/results.dart' as engine;
import 'package:analyzer/dart/ast/ast.dart' as engine;
import 'package:analyzer/dart/ast/token.dart' as engine;
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/dart/element/element2.dart' as engine;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart' as engine;
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/source.dart' as engine;
import 'package:analyzer/source/source_range.dart' as engine;
import 'package:analyzer_plugin/protocol/protocol_common.dart';

export 'package:analysis_server/plugin/protocol/protocol_dart.dart';
export 'package:analysis_server/protocol/protocol.dart';
export 'package:analysis_server/protocol/protocol_generated.dart';
export 'package:analyzer_plugin/protocol/protocol_common.dart';

/// Returns a list of AnalysisErrors corresponding to the given list of Engine
/// errors.
List<AnalysisError> doAnalysisError_listFromEngine(
    engine.AnalysisResultWithErrors result) {
  return mapEngineErrors(result, result.errors, newAnalysisError_fromEngine);
}

/// Adds [edit] to the file containing the given [element].
void doSourceChange_addElementEdit(
    SourceChange change, engine.Element element, SourceEdit edit) {
  var source = element.source!;
  doSourceChange_addSourceEdit(change, source, edit);
}

/// Adds [edit] for the given [source] to the [change].
void doSourceChange_addSourceEdit(
    SourceChange change, engine.Source source, SourceEdit edit,
    {bool isNewFile = false}) {
  var file = source.fullName;
  change.addEdit(file, isNewFile ? -1 : 0, edit);
}

String? getAliasedTypeString(engine.Element element) {
  if (element is engine.TypeAliasElement) {
    var aliasedType = element.aliasedType;
    return aliasedType.getDisplayString();
  }
  return null;
}

String? getAliasedTypeString2(engine.Element2 element) {
  if (element is engine.TypeAliasElement2) {
    var aliasedType = element.aliasedType;
    return aliasedType.getDisplayString();
  }
  return null;
}

/// Returns a color hex code (in the form '#FFFFFF')  if [element] represents
/// a color.
String? getColorHexString(engine.Element? element) {
  if (element is engine.VariableElement) {
    var dartValue = element.computeConstantValue();
    if (dartValue != null) {
      var color = ColorComputer.getColorForObject(dartValue);
      if (color != null) {
        return '#'
                '${color.red.toRadixString(16).padLeft(2, '0')}'
                '${color.green.toRadixString(16).padLeft(2, '0')}'
                '${color.blue.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();
      }
    }
  }
  return null;
}

/// Returns a color hex code (in the form '#FFFFFF')  if [element] represents
/// a color.
String? getColorHexString2(engine.Element2? element) {
  if (element is engine.VariableElement2) {
    var dartValue = element.computeConstantValue();
    if (dartValue != null) {
      var color = ColorComputer.getColorForObject(dartValue);
      if (color != null) {
        return '#'
                '${color.red.toRadixString(16).padLeft(2, '0')}'
                '${color.green.toRadixString(16).padLeft(2, '0')}'
                '${color.blue.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();
      }
    }
  }
  return null;
}

String? getReturnTypeString(engine.Element element) {
  if (element is engine.ExecutableElement) {
    if (element.kind == engine.ElementKind.SETTER) {
      return null;
    } else {
      return element.returnType.getDisplayString();
    }
  } else if (element is engine.VariableElement) {
    var type = element.type;
    return type.getDisplayString();
  } else if (element is engine.TypeAliasElement) {
    var aliasedType = element.aliasedType;
    if (aliasedType is FunctionType) {
      var returnType = aliasedType.returnType;
      return returnType.getDisplayString();
    }
  }
  return null;
}

String? getReturnTypeString2(engine.Element2 element) {
  if (element is engine.ExecutableElement2) {
    if (element.kind == engine.ElementKind.SETTER) {
      return null;
    } else {
      return element.returnType.getDisplayString();
    }
  } else if (element is engine.VariableElement2) {
    var type = element.type;
    return type.getDisplayString();
  } else if (element is engine.TypeAliasElement2) {
    var aliasedType = element.aliasedType;
    if (aliasedType is FunctionType) {
      var returnType = aliasedType.returnType;
      return returnType.getDisplayString();
    }
  }
  return null;
}

/// Translates engine errors through the ErrorProcessor.
List<T> mapEngineErrors<T>(
    engine.AnalysisResultWithErrors result,
    List<engine.AnalysisError> errors,
    T Function(
            engine.AnalysisResultWithErrors result, engine.AnalysisError error,
            [engine.ErrorSeverity errorSeverity])
        constructor) {
  var analysisOptions =
      result.session.analysisContext.getAnalysisOptionsForFile(result.file);
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
    engine.AnalysisResultWithErrors result, engine.AnalysisError error,
    [engine.ErrorSeverity? errorSeverity]) {
  var errorCode = error.errorCode;
  // prepare location
  Location location;
  {
    var file = error.source.fullName;
    var offset = error.offset;
    var length = error.length;
    var lineInfo = result.lineInfo;

    var startLocation = lineInfo.getLocation(offset);
    var startLine = startLocation.lineNumber;
    var startColumn = startLocation.columnNumber;

    var endLocation = lineInfo.getLocation(offset + length);
    var endLine = endLocation.lineNumber;
    var endColumn = endLocation.columnNumber;

    location = Location(file, offset, length, startLine, startColumn,
        endLine: endLine, endColumn: endColumn);
  }

  // Default to the error's severity if none is specified.
  errorSeverity ??= errorCode.errorSeverity;

  // done
  var severity = AnalysisErrorSeverity(errorSeverity.name);
  var type = AnalysisErrorType(errorCode.type.name);
  var message = error.message;
  var code = errorCode.name.toLowerCase();
  List<DiagnosticMessage>? contextMessages;
  if (error.contextMessages.isNotEmpty) {
    contextMessages = error.contextMessages
        .map((message) => newDiagnosticMessage(result, message))
        .toList();
  }
  var correction = error.correction;
  var url = errorCode.url;
  return AnalysisError(severity, type, location, message, code,
      contextMessages: contextMessages,
      correction: correction,
      // This parameter is only necessary for deprecated IDE support.
      // Whether the error actually has a fix or not is not important to report
      // here.
      // TODO(srawlins): Remove it.
      hasFix: false,
      url: url);
}

/// Create a DiagnosticMessage based on an [engine.DiagnosticMessage].
DiagnosticMessage newDiagnosticMessage(
    engine.AnalysisResultWithErrors result, engine.DiagnosticMessage message) {
  var file = message.filePath;
  var offset = message.offset;
  var length = message.length;

  var startLocation = result.lineInfo.getLocation(offset);
  var startLine = startLocation.lineNumber;
  var startColumn = startLocation.columnNumber;

  var endLocation = result.lineInfo.getLocation(offset + length);
  var endLine = endLocation.lineNumber;
  var endColumn = endLocation.columnNumber;

  return DiagnosticMessage(
      message.messageText(includeUrl: true),
      Location(file, offset, length, startLine, startColumn,
          endLine: endLine, endColumn: endColumn));
}

/// Create a Location based on an [engine.Element].
Location? newLocation_fromElement(engine.Element? element) {
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

/// Create a Location based on an [engine.Element2].
Location? newLocation_fromElement2(engine.Element2? element) {
  if (element == null) {
    return null;
  }
  if (element is engine.FragmentedElement) {
    var fragment = (element as engine.FragmentedElement).firstFragment;
    var offset = fragment.nameOffset2 ?? 0;
    var length = fragment.name2?.length ?? 0;
    var range = engine.SourceRange(offset, length);
    return _locationForArgs2(fragment, range);
  } else {
    assert(false, 'Could not convert ${element.runtimeType} to Location.');
    return null;
  }
}

/// Create a Location based on an [engine.SearchMatch].
Location newLocation_fromMatch(engine.SearchMatch match) {
  var unitElement = _getUnitElement(match.element);
  return _locationForArgs(unitElement, match.sourceRange);
}

/// Create a Location based on an [engine.AstNode].
Location newLocation_fromNode(engine.AstNode node) {
  var unit = node.thisOrAncestorOfType<engine.CompilationUnit>()!;
  var unitElement = unit.declaredElement!;
  var range = engine.SourceRange(node.offset, node.length);
  return _locationForArgs(unitElement, range);
}

/// Create a Location based on an [engine.AstNode].
Location newLocation_fromToken({
  required engine.CompilationUnitElement unitElement,
  required engine.Token token,
}) {
  var range = engine.SourceRange(token.offset, token.length);
  return _locationForArgs(unitElement, range);
}

/// Create a Location based on an [engine.CompilationUnit].
Location newLocation_fromUnit(
    engine.CompilationUnit unit, engine.SourceRange range) {
  return _locationForArgs(unit.declaredElement!, range);
}

/// Construct based on an element from the analyzer engine.
OverriddenMember newOverriddenMember_fromEngine(engine.Element2 member) {
  var element = convertElement2(member);
  var className = member.enclosingElement2!.displayName;
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
  if (kind == engine.MatchKind.INVOCATION ||
      kind == engine.MatchKind.INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS) {
    return SearchResultKind.INVOCATION;
  }
  if (kind.isReference) {
    return SearchResultKind.REFERENCE;
  }
  return SearchResultKind.UNKNOWN;
}

/// Construct based on a SourceRange.
SourceEdit newSourceEdit_range(engine.SourceRange range, String replacement,
    {String? id}) {
  return SourceEdit(range.offset, range.length, replacement, id: id);
}

List<Element> _computePath(engine.Element element) {
  var path = <Element>[];

  if (element is engine.PrefixElement) {
    element = element.enclosingElement3;
  }

  for (var e in element.withAncestors) {
    path.add(convertElement(e));
  }
  return path;
}

engine.CompilationUnitElement _getUnitElement(engine.Element element) {
  if (element is engine.CompilationUnitElement) {
    return element;
  }

  if (element.enclosingElement3 case engine.LibraryElement enclosing) {
    return enclosing.definingCompilationUnit;
  }

  if (element is engine.LibraryElement) {
    return element.definingCompilationUnit;
  }

  for (var e in element.withAncestors) {
    if (e is engine.CompilationUnitElement) {
      return e;
    }
  }

  throw StateError('No unit: $element');
}

/// Creates a new [Location].
Location _locationForArgs(
    engine.CompilationUnitElement unitElement, engine.SourceRange range) {
  var lineInfo = unitElement.lineInfo;

  var startLocation = lineInfo.getLocation(range.offset);
  var endLocation = lineInfo.getLocation(range.end);

  var startLine = startLocation.lineNumber;
  var startColumn = startLocation.columnNumber;
  var endLine = endLocation.lineNumber;
  var endColumn = endLocation.columnNumber;

  return Location(unitElement.source.fullName, range.offset, range.length,
      startLine, startColumn,
      endLine: endLine, endColumn: endColumn);
}

/// Creates a new [Location].
Location _locationForArgs2(engine.Fragment fragment, engine.SourceRange range) {
  var lineInfo = fragment.libraryFragment.lineInfo;

  var startLocation = lineInfo.getLocation(range.offset);
  var endLocation = lineInfo.getLocation(range.end);

  var startLine = startLocation.lineNumber;
  var startColumn = startLocation.columnNumber;
  var endLine = endLocation.lineNumber;
  var endColumn = endLocation.columnNumber;

  return Location(fragment.libraryFragment.source.fullName, range.offset,
      range.length, startLine, startColumn,
      endLine: endLine, endColumn: endColumn);
}
