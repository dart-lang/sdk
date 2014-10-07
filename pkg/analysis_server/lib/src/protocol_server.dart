// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library protocol.server;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/search/search_engine.dart' as
    engine;
import 'package:analyzer/src/generated/ast.dart' as engine;
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/source.dart' as engine;

export 'package:analysis_server/src/protocol.dart';


/**
 * Returns a list of AnalysisErrors correponding to the given list of Engine
 * errors.
 */
List<AnalysisError> doAnalysisError_listFromEngine(engine.LineInfo lineInfo,
    List<engine.AnalysisError> errors) {
  return errors.map((engine.AnalysisError error) {
    return newAnalysisError_fromEngine(lineInfo, error);
  }).toList();
}


/**
 * Adds [edit] to the [FileEdit] for the given [element].
 */
void doSourceChange_addElementEdit(SourceChange change, engine.Element element,
    SourceEdit edit) {
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


/**
 * Construct based on error information from the analyzer engine.
 */
AnalysisError newAnalysisError_fromEngine(engine.LineInfo lineInfo,
    engine.AnalysisError error) {
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
  // done
  var severity = new AnalysisErrorSeverity(errorCode.errorSeverity.name);
  var type = new AnalysisErrorType(errorCode.type.name);
  String message = error.message;
  String correction = error.correction;
  return new AnalysisError(
      severity,
      type,
      location,
      message,
      correction: correction);
}


/**
 * Construct from an analyzer engine element kind.
 */
CompletionSuggestionKind
    newCompletionSuggestionKind_fromElementKind(engine.ElementKind kind) {
  //    ElementKind.ANGULAR_FORMATTER,
  //    ElementKind.ANGULAR_COMPONENT,
  //    ElementKind.ANGULAR_CONTROLLER,
  //    ElementKind.ANGULAR_DIRECTIVE,
  //    ElementKind.ANGULAR_PROPERTY,
  //    ElementKind.ANGULAR_SCOPE_PROPERTY,
  //    ElementKind.ANGULAR_SELECTOR,
  //    ElementKind.ANGULAR_VIEW,
  if (kind == engine.ElementKind.CLASS) return CompletionSuggestionKind.CLASS;
  //    ElementKind.COMPILATION_UNIT,
  if (kind ==
      engine.ElementKind.CONSTRUCTOR) return CompletionSuggestionKind.CONSTRUCTOR;
  //    ElementKind.DYNAMIC,
  //    ElementKind.EMBEDDED_HTML_SCRIPT,
  //    ElementKind.ERROR,
  //    ElementKind.EXPORT,
  //    ElementKind.EXTERNAL_HTML_SCRIPT,
  if (kind == engine.ElementKind.FIELD) return CompletionSuggestionKind.FIELD;
  if (kind ==
      engine.ElementKind.FUNCTION) return CompletionSuggestionKind.FUNCTION;
  if (kind ==
      engine.ElementKind.FUNCTION_TYPE_ALIAS) return
          CompletionSuggestionKind.FUNCTION_TYPE_ALIAS;
  if (kind == engine.ElementKind.GETTER) return CompletionSuggestionKind.GETTER;
  //    ElementKind.HTML,
  if (kind == engine.ElementKind.IMPORT) return CompletionSuggestionKind.IMPORT;
  //    ElementKind.LABEL,
  //    ElementKind.LIBRARY,
  if (kind ==
      engine.ElementKind.LOCAL_VARIABLE) return
          CompletionSuggestionKind.LOCAL_VARIABLE;
  if (kind == engine.ElementKind.METHOD) return CompletionSuggestionKind.METHOD;
  //    ElementKind.NAME,
  if (kind ==
      engine.ElementKind.PARAMETER) return CompletionSuggestionKind.PARAMETER;
  //    ElementKind.POLYMER_ATTRIBUTE,
  //    ElementKind.POLYMER_TAG_DART,
  //    ElementKind.POLYMER_TAG_HTML,
  //    ElementKind.PREFIX,
  if (kind == engine.ElementKind.SETTER) return CompletionSuggestionKind.SETTER;
  if (kind ==
      engine.ElementKind.TOP_LEVEL_VARIABLE) return
          CompletionSuggestionKind.TOP_LEVEL_VARIABLE;
  //    ElementKind.TYPE_PARAMETER,
  //    ElementKind.UNIVERSE
  throw new ArgumentError('Unknown CompletionSuggestionKind for: $kind');
}



/**
 * Construct based on a value from the analyzer engine.
 */
ElementKind newElementKind_fromEngine(engine.ElementKind kind) {
  if (kind == engine.ElementKind.CLASS) {
    return ElementKind.CLASS;
  }
  if (kind == engine.ElementKind.COMPILATION_UNIT) {
    return ElementKind.COMPILATION_UNIT;
  }
  if (kind == engine.ElementKind.CONSTRUCTOR) {
    return ElementKind.CONSTRUCTOR;
  }
  if (kind == engine.ElementKind.FIELD) {
    return ElementKind.FIELD;
  }
  if (kind == engine.ElementKind.FUNCTION) {
    return ElementKind.FUNCTION;
  }
  if (kind == engine.ElementKind.FUNCTION_TYPE_ALIAS) {
    return ElementKind.FUNCTION_TYPE_ALIAS;
  }
  if (kind == engine.ElementKind.GETTER) {
    return ElementKind.GETTER;
  }
  if (kind == engine.ElementKind.LABEL) {
    return ElementKind.LABEL;
  }
  if (kind == engine.ElementKind.LIBRARY) {
    return ElementKind.LIBRARY;
  }
  if (kind == engine.ElementKind.LOCAL_VARIABLE) {
    return ElementKind.LOCAL_VARIABLE;
  }
  if (kind == engine.ElementKind.METHOD) {
    return ElementKind.METHOD;
  }
  if (kind == engine.ElementKind.PARAMETER) {
    return ElementKind.PARAMETER;
  }
  if (kind == engine.ElementKind.PREFIX) {
    return ElementKind.PREFIX;
  }
  if (kind == engine.ElementKind.SETTER) {
    return ElementKind.SETTER;
  }
  if (kind == engine.ElementKind.TOP_LEVEL_VARIABLE) {
    return ElementKind.TOP_LEVEL_VARIABLE;
  }
  if (kind == engine.ElementKind.TYPE_PARAMETER) {
    return ElementKind.TYPE_PARAMETER;
  }
  return ElementKind.UNKNOWN;
}


/**
 * Construct based on a value from the analyzer engine.
 */
Element newElement_fromEngine(engine.Element element) {
  return elementFromEngine(element);
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
  String name = element.displayName;
  int offset = element.nameOffset;
  int length = name != null ? name.length : 0;
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
      enclosingElement.context,
      enclosingElement.source,
      match.sourceRange);
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
Location newLocation_fromUnit(engine.CompilationUnit unit,
    engine.SourceRange range) {
  engine.CompilationUnitElement unitElement = unit.element;
  engine.AnalysisContext context = unitElement.context;
  engine.Source source = unitElement.source;
  return _locationForArgs(context, source, range);
}


/**
 * Construct based on an element from the analyzer engine.
 */
OverriddenMember newOverriddenMember_fromEngine(engine.Element member) {
  Element element = elementFromEngine(member);
  String className = member.enclosingElement.displayName;
  return new OverriddenMember(element, className);
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
 * Construct based on a value from the search engine.
 */
SearchResult newSearchResult_fromMatch(engine.SearchMatch match) {
  SearchResultKind kind = newSearchResultKind_fromEngine(match.kind);
  Location location = newLocation_fromMatch(match);
  List<Element> path = _computePath(match.element);
  return new SearchResult(location, kind, !match.isResolved, path);
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
    path.add(newElement_fromEngine(element));
    element = element.enclosingElement;
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
      source.fullName,
      range.offset,
      range.length,
      startLine,
      startColumn);
}
