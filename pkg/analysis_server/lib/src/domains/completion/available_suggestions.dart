// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/services/available_declarations.dart';

/// Compute which suggestion sets should be included into completion for
/// the given completion [request].  Depending on the file path, it might
/// include different sets, e.g. inside the `lib/` directory of a `Pub` package
/// only regular dependencies can be referenced, but `test/` can reference
/// both regular and "dev" dependencies.
void computeIncludedSetList(
  DeclarationsTracker tracker,
  DartCompletionRequest request,
  List<protocol.IncludedSuggestionSet> includedSetList,
  Set<String> includedElementNames,
) {
  var context = tracker.getContext(request.analysisContext);
  if (context == null) return;

  var librariesObject = context.getLibraries(request.path);

  var importedUriSet = request.libraryElement.importedLibraries
      .map((importedLibrary) => importedLibrary.source.uri)
      .toSet();

  void includeLibrary(
    Library library,
    int importedRelevance,
    int deprecatedRelevance,
    int otherwiseRelevance,
  ) {
    int relevance;
    if (importedUriSet.contains(library.uri)) {
      relevance = importedRelevance;
    } else if (library.isDeprecated) {
      relevance = deprecatedRelevance;
    } else {
      relevance = otherwiseRelevance;
    }

    includedSetList.add(
      protocol.IncludedSuggestionSet(
        library.id,
        relevance,
        displayUri: _getRelativeFileUri(request, library.uri),
      ),
    );

    for (var declaration in library.declarations) {
      includedElementNames.add(declaration.name);
    }
  }

  for (var library in librariesObject.context) {
    includeLibrary(library, 8, 2, 5);
  }

  for (var library in librariesObject.dependencies) {
    includeLibrary(library, 7, 1, 4);
  }

  for (var library in librariesObject.sdk) {
    includeLibrary(library, 6, 0, 3);
  }
}

protocol.CompletionAvailableSuggestionsParams
    createCompletionAvailableSuggestions(
  List<Library> changed,
  List<int> removed,
) =>
        protocol.CompletionAvailableSuggestionsParams(
          changedLibraries: changed.map((library) {
            return _protocolAvailableSuggestionSet(library);
          }).toList(),
          removedLibraries: removed,
        );

/// Convert the [LibraryChange] into the corresponding protocol notification.
protocol.Notification createCompletionAvailableSuggestionsNotification(
  List<Library> changed,
  List<int> removed,
) =>
    createCompletionAvailableSuggestions(changed, removed).toNotification();

/// Compute existing imports and elements that they provide.
protocol.Notification createExistingImportsNotification(
  ResolvedUnitResult resolvedUnit,
) {
  var uniqueStrings = _UniqueImportedStrings();
  var uniqueElements = _UniqueImportedElements();
  var existingImports = <protocol.ExistingImport>[];

  var importElementList = resolvedUnit.libraryElement.libraryImports;
  for (var import in importElementList) {
    var importedLibrary = import.importedLibrary;
    if (importedLibrary == null) continue;

    var importedUriStr = '${importedLibrary.librarySource.uri}';

    var existingImportElements = <int>[];
    for (var element in import.namespace.definedNames.values) {
      if (element.librarySource != null) {
        var index = uniqueElements.indexOf(uniqueStrings, element);
        existingImportElements.add(index);
      }
    }

    existingImports.add(protocol.ExistingImport(
      uniqueStrings.indexOf(importedUriStr),
      existingImportElements,
    ));
  }

  return protocol.CompletionExistingImportsParams(
    resolvedUnit.libraryElement.source.fullName,
    protocol.ExistingImports(
      protocol.ImportedElementSet(
        uniqueStrings.values,
        uniqueElements.uriList,
        uniqueElements.nameList,
      ),
      existingImports,
    ),
  ).toNotification();
}

/// TODO(dantup): We need to expose this because the Declarations code currently
/// returns declarations with DeclarationKinds but the DartCompletionManager
/// gives us a list of "included ElementKinds". Maybe it would be better to expose
/// includedDeclarationKinds and then just map that list to ElementKinds once in
/// domain_completion for the original protocol?
protocol.ElementKind protocolElementKind(DeclarationKind kind) {
  return switch (kind) {
    DeclarationKind.CLASS => protocol.ElementKind.CLASS,
    DeclarationKind.CLASS_TYPE_ALIAS => protocol.ElementKind.CLASS_TYPE_ALIAS,
    DeclarationKind.CONSTRUCTOR => protocol.ElementKind.CONSTRUCTOR,
    DeclarationKind.ENUM => protocol.ElementKind.ENUM,
    DeclarationKind.ENUM_CONSTANT => protocol.ElementKind.ENUM_CONSTANT,
    DeclarationKind.EXTENSION => protocol.ElementKind.EXTENSION,
    DeclarationKind.FIELD => protocol.ElementKind.FIELD,
    DeclarationKind.FUNCTION => protocol.ElementKind.FUNCTION,
    DeclarationKind.FUNCTION_TYPE_ALIAS => protocol.ElementKind.TYPE_ALIAS,
    DeclarationKind.GETTER => protocol.ElementKind.GETTER,
    DeclarationKind.METHOD => protocol.ElementKind.METHOD,
    DeclarationKind.MIXIN => protocol.ElementKind.MIXIN,
    DeclarationKind.SETTER => protocol.ElementKind.SETTER,
    DeclarationKind.TYPE_ALIAS => protocol.ElementKind.TYPE_ALIAS,
    DeclarationKind.VARIABLE => protocol.ElementKind.TOP_LEVEL_VARIABLE
  };
}

/// Computes the best URI to import [what] into the [unit] library.
String? _getRelativeFileUri(DartCompletionRequest request, Uri what) {
  if (what.isScheme('file')) {
    var pathContext = request.analysisSession.resourceProvider.pathContext;

    var libraryPath = request.libraryElement.source.fullName;
    var libraryFolder = pathContext.dirname(libraryPath);

    var whatPath = pathContext.fromUri(what);
    var relativePath = pathContext.relative(whatPath, from: libraryFolder);
    return pathContext.split(relativePath).join('/');
  }
  return null;
}

protocol.AvailableSuggestion? _protocolAvailableSuggestion(
    Declaration declaration) {
  var label = declaration.name;
  var parent = declaration.parent;
  if (parent != null) {
    if (declaration.kind == DeclarationKind.CONSTRUCTOR) {
      label = parent.name;
      if (declaration.name.isNotEmpty) {
        label += '.${declaration.name}';
      }
    } else if (declaration.kind == DeclarationKind.ENUM_CONSTANT) {
      label = '${parent.name}.${declaration.name}';
    } else {
      return null;
    }
  }

  String declaringLibraryUri;
  if (parent == null) {
    declaringLibraryUri = '${declaration.locationLibraryUri}';
  } else {
    declaringLibraryUri = '${parent.locationLibraryUri}';
  }

  var relevanceTags = declaration.relevanceTags.toList()..add(declaration.name);

  return protocol.AvailableSuggestion(
    label,
    declaringLibraryUri,
    _protocolElement(declaration),
    defaultArgumentListString: declaration.defaultArgumentListString,
    defaultArgumentListTextRanges: declaration.defaultArgumentListTextRanges,
    parameterNames: declaration.parameterNames,
    parameterTypes: declaration.parameterTypes,
    requiredParameterCount: declaration.requiredParameterCount,
    relevanceTags: relevanceTags,
  );
}

protocol.AvailableSuggestionSet _protocolAvailableSuggestionSet(
    Library library) {
  var items = <protocol.AvailableSuggestion>[];

  void addItem(Declaration declaration) {
    var suggestion = _protocolAvailableSuggestion(declaration);
    if (suggestion != null) {
      items.add(suggestion);
    }
    declaration.children.forEach(addItem);
  }

  for (var declaration in library.declarations) {
    addItem(declaration);
  }

  return protocol.AvailableSuggestionSet(library.id, library.uriStr, items);
}

protocol.Element _protocolElement(Declaration declaration) {
  return protocol.Element(
    protocolElementKind(declaration.kind),
    declaration.name,
    _protocolElementFlags(declaration),
    location: protocol.Location(
      declaration.locationPath,
      declaration.locationOffset,
      0, // length
      declaration.locationStartLine,
      declaration.locationStartColumn,
      endLine: declaration.locationStartLine,
      endColumn: declaration.locationStartColumn,
    ),
    parameters: declaration.parameters,
    returnType: declaration.returnType,
    typeParameters: declaration.typeParameters,
  );
}

int _protocolElementFlags(Declaration declaration) {
  return protocol.Element.makeFlags(
    isAbstract: declaration.isAbstract,
    isConst: declaration.isConst,
    isDeprecated: declaration.isDeprecated,
    isFinal: declaration.isFinal,
    isStatic: declaration.isStatic,
  );
}

class CompletionLibrariesWorker implements SchedulerWorker {
  final DeclarationsTracker tracker;

  CompletionLibrariesWorker(this.tracker);

  @override
  AnalysisDriverPriority get workPriority {
    if (tracker.hasWork) {
      return AnalysisDriverPriority.priority;
    } else {
      return AnalysisDriverPriority.nothing;
    }
  }

  @override
  Future<void> performWork() async {
    tracker.doWork();
  }
}

class DeclarationsTrackerData {
  final DeclarationsTracker _tracker;

  /// The set of libraries reported by [_tracker] so far.
  ///
  /// We create [_tracker] at the server start, but the completion domain
  /// should send available declarations only when the corresponding
  /// subscription is done. OTOH, we don't want the changes stream grow
  /// infinitely as the same libraries are changed multiple times. So, we drain
  /// the changes stream in this map, and send it at subscription.
  final Map<int, Library> _idToLibrary = {};

  /// When the completion domain subscribes for changes, we start redirecting
  /// changes to this listener.
  void Function(LibraryChange)? _listener;

  DeclarationsTrackerData(this._tracker) {
    _tracker.changes.listen((change) {
      var listener = _listener;
      if (listener != null) {
        listener(change);
      } else {
        for (var library in change.changed) {
          _idToLibrary[library.id] = library;
        }
        for (var id in change.removed) {
          _idToLibrary.remove(id);
        }
      }
    });
  }

  /// Start listening for available libraries, and return the libraries that
  /// were accumulated so far.
  List<Library> startListening(void Function(LibraryChange) listener) {
    if (_listener != null) {
      throw StateError('Already listening.');
    }
    _listener = listener;

    var accumulatedLibraries = _idToLibrary.values.toList();
    _idToLibrary.clear();
    return accumulatedLibraries;
  }

  void stopListening() {
    if (_listener == null) {
      throw StateError('Not listening.');
    }
    _listener = null;
  }
}

class _ImportedElement {
  final int uri;
  final int name;

  @override
  final int hashCode;

  _ImportedElement(this.uri, this.name) : hashCode = Object.hash(uri, name);

  @override
  bool operator ==(other) {
    return other is _ImportedElement && other.uri == uri && other.name == name;
  }
}

class _UniqueImportedElements {
  final map = <_ImportedElement, int>{};

  List<int> get nameList => map.keys.map((e) => e.name).toList();

  List<int> get uriList => map.keys.map((e) => e.uri).toList();

  int indexOf(_UniqueImportedStrings strings, Element element) {
    var uriStr = '${element.librarySource!.uri}';
    var wrapper = _ImportedElement(
      strings.indexOf(uriStr),
      strings.indexOf(element.name!),
    );
    var index = map[wrapper];
    if (index == null) {
      index = map.length;
      map[wrapper] = index;
    }
    return index;
  }
}

class _UniqueImportedStrings {
  final map = <String, int>{};

  List<String> get values => map.keys.toList();

  int indexOf(String str) {
    var index = map[str];
    if (index == null) {
      index = map.length;
      map[str] = index;
    }
    return index;
  }
}
