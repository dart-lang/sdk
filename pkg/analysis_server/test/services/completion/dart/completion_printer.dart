// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:collection/collection.dart';

import 'completion_check.dart';

class CompletionResponsePrinter {
  final StringBuffer buffer;
  final Configuration configuration;
  final CompletionResponseForTesting response;

  String _indent = '';

  CompletionResponsePrinter({
    required this.buffer,
    required this.configuration,
    required this.response,
  });

  void writeResponse() {
    _writeLocation();
    _writeResponseReplacement();
    _writeSuggestions();
  }

  /// Compares suggestions according to the configuration sorting.
  int _compareSuggestions(CompletionSuggestion a, CompletionSuggestion b) {
    int completionThenKind() {
      var completionDiff = a.completion.compareTo(b.completion);
      if (completionDiff != 0) {
        return completionDiff;
      } else {
        return a.kind.name.compareTo(b.kind.name);
      }
    }

    switch (configuration.sorting) {
      case Sorting.asIs:
        return 0;
      case Sorting.completionThenKind:
        return completionThenKind();
      case Sorting.relevanceThenCompletionThenKind:
        var relevanceDiff = a.relevance - b.relevance;
        if (relevanceDiff != 0) {
          return -relevanceDiff;
        } else {
          return completionThenKind();
        }
    }
  }

  String _escapeMultiLine(String text) {
    return text.replaceAll('\n', r'\n');
  }

  String _getElementKindName(ElementKind kind) {
    if (kind == ElementKind.CLASS) {
      return 'class';
    } else if (kind == ElementKind.CONSTRUCTOR) {
      return 'constructor';
    } else if (kind == ElementKind.ENUM) {
      return 'enum';
    } else if (kind == ElementKind.EXTENSION) {
      return 'extension';
    } else if (kind == ElementKind.FIELD) {
      return 'field';
    } else if (kind == ElementKind.FUNCTION) {
      return 'function';
    } else if (kind == ElementKind.PARAMETER) {
      return 'parameter';
    } else if (kind == ElementKind.TOP_LEVEL_VARIABLE) {
      return 'topLevelVariable';
    } else if (kind == ElementKind.TYPE_ALIAS) {
      return 'typeAlias';
    }
    throw UnimplementedError('kind: $kind');
  }

  String _getSuggestionKindName(CompletionSuggestion suggestion) {
    var kind = suggestion.kind;
    if (kind == CompletionSuggestionKind.KEYWORD) {
      return 'keyword';
    } else if (kind == CompletionSuggestionKind.IDENTIFIER) {
      var elementKind = suggestion.element?.kind;
      if (elementKind == null) {
        return 'identifier';
      } else if (elementKind == ElementKind.CLASS) {
        return 'class';
      } else if (elementKind == ElementKind.CONSTRUCTOR) {
        return 'constructor';
      } else if (elementKind == ElementKind.ENUM) {
        return 'enum';
      } else if (elementKind == ElementKind.ENUM_CONSTANT) {
        return 'enumConstant';
      } else if (elementKind == ElementKind.EXTENSION) {
        return 'extension';
      } else if (elementKind == ElementKind.EXTENSION_TYPE) {
        return 'extensionType';
      } else if (elementKind == ElementKind.FIELD) {
        return 'field';
      } else if (elementKind == ElementKind.FUNCTION) {
        return 'function';
      } else if (elementKind == ElementKind.GETTER) {
        return 'getter';
      } else if (elementKind == ElementKind.LABEL) {
        return 'label';
      } else if (elementKind == ElementKind.LIBRARY) {
        return 'library';
      } else if (elementKind == ElementKind.LOCAL_VARIABLE) {
        return 'localVariable';
      } else if (elementKind == ElementKind.METHOD) {
        return 'method';
      } else if (elementKind == ElementKind.MIXIN) {
        return 'mixin';
      } else if (elementKind == ElementKind.PARAMETER) {
        return 'parameter';
      } else if (elementKind == ElementKind.PREFIX) {
        return 'prefix';
      } else if (elementKind == ElementKind.SETTER) {
        return 'setter';
      } else if (elementKind == ElementKind.TOP_LEVEL_VARIABLE) {
        return 'topLevelVariable';
      } else if (elementKind == ElementKind.TYPE_ALIAS) {
        return 'typeAlias';
      } else if (elementKind == ElementKind.TYPE_PARAMETER) {
        return 'typeParameter';
      }
      throw UnimplementedError('elementKind: $elementKind');
    } else if (kind == CompletionSuggestionKind.INVOCATION) {
      var elementKind = suggestion.element?.kind;
      if (elementKind == null) {
        return 'invocation';
      } else if (elementKind == ElementKind.CONSTRUCTOR) {
        return 'constructorInvocation';
      } else if (elementKind == ElementKind.EXTENSION) {
        return 'extensionInvocation';
      } else if (elementKind == ElementKind.FUNCTION) {
        return 'functionInvocation';
      } else if (elementKind == ElementKind.METHOD) {
        return 'methodInvocation';
      }
      throw UnimplementedError('elementKind: $elementKind');
    } else if (kind == CompletionSuggestionKind.IMPORT) {
      return 'import';
    } else if (kind == CompletionSuggestionKind.NAMED_ARGUMENT) {
      return 'namedArgument';
    } else if (kind == CompletionSuggestionKind.OVERRIDE) {
      return 'override';
    }
    throw UnimplementedError('kind: $kind');
  }

  void _withIndent(void Function() f) {
    var indent = _indent;
    _indent = '$_indent  ';
    f();
    _indent = indent;
  }

  void _writeCompletion(CompletionSuggestion suggestion) {
    var completion = suggestion.completion;
    if (RegExp(r'^\s').hasMatch(completion) ||
        RegExp(r'\s$').hasMatch(completion)) {
      _writelnWithIndent('|$completion|');
    } else {
      _writelnWithIndent(completion);
    }
  }

  void _writeDeclaringType(CompletionSuggestion suggestion) {
    if (configuration.withDeclaringType) {
      _writelnWithIndent('declaringType: ${suggestion.declaringType}');
    }
  }

  void _writeDefaultArgumentList(CompletionSuggestion suggestion) {
    if (configuration.withDefaultArgumentList) {
      _writelnWithIndent(
        'defaultArgumentList: ${suggestion.defaultArgumentListString}',
      );
      _writelnWithIndent(
        'defaultArgumentListRanges: ${suggestion.defaultArgumentListTextRanges}',
      );
    }
  }

  void _writeDeprecated(CompletionSuggestion suggestion) {
    if (suggestion.isDeprecated) {
      _writelnWithIndent('deprecated: true');
    }
  }

  void _writeDisplayText(CompletionSuggestion suggestion) {
    if (configuration.withDisplayText) {
      _writelnWithIndent('displayText: ${suggestion.displayText}');
    }
  }

  void _writeDocumentation(CompletionSuggestion suggestion) {
    if (configuration.withDocumentation) {
      var docComplete = suggestion.docComplete;
      if (docComplete != null) {
        var text = _escapeMultiLine(docComplete);
        _writelnWithIndent('docComplete: $text');
      }

      var docSummary = suggestion.docSummary;
      if (docSummary != null) {
        var text = _escapeMultiLine(docSummary);
        _writelnWithIndent('docSummary: $text');
      }
    }
  }

  void _writeElement(CompletionSuggestion suggestion) {
    if (configuration.withElement) {
      var element = suggestion.element;
      if (element != null) {
        _writelnWithIndent('element');
        _withIndent(() {
          var kindStr = _getElementKindName(element.kind);
          _writelnWithIndent('name: ${element.name}');
          _writelnWithIndent('kind: $kindStr');
        });
      }
    }
  }

  void _writeElementOffset(CompletionSuggestion suggestion) {
    if (configuration.withElementOffset) {
      var element = suggestion.element;
      if (element != null) {
        _writelnWithIndent('offset: ${element.location?.offset}');
      }
    }
  }

  void _writeIsNotImported(CompletionSuggestion suggestion) {
    if (configuration.withIsNotImported) {
      _writelnWithIndent('isNotImported: ${suggestion.isNotImported}');
    }
  }

  void _writeLibraryUri(CompletionSuggestion suggestion) {
    if (configuration.withLibraryUri) {
      _writelnWithIndent('libraryUri: ${suggestion.libraryUri}');
    }
  }

  void _writelnWithIndent(String line) {
    buffer.write(_indent);
    buffer.writeln(line);
  }

  void _writeLocation() {
    if (configuration.withLocationName) {
      if (response.requestLocationName case var location?) {
        _writelnWithIndent('location: $location');
      }
      // TODO(scheglov): will be removed
      if (response.opTypeLocationName case var location?) {
        _writelnWithIndent('locationOpType: $location');
      }
    }
  }

  void _writeParameterNames(CompletionSuggestion suggestion) {
    if (configuration.withParameterNames) {
      var parameterNames = suggestion.parameterNames?.join(',') ?? '';
      if (parameterNames.isNotEmpty) {
        parameterNames = ' $parameterNames';
      }
      _writelnWithIndent('parameterNames:$parameterNames');
      var parameterTypes = suggestion.parameterTypes?.join(',') ?? '';
      if (parameterTypes.isNotEmpty) {
        parameterTypes = ' $parameterTypes';
      }
      _writelnWithIndent('parameterTypes:$parameterTypes');
    }
  }

  void _writeRelevance(CompletionSuggestion suggestion) {
    if (configuration.withRelevance) {
      _writelnWithIndent('relevance: ${suggestion.relevance}');
    }
  }

  void _writeResponseReplacement() {
    if (configuration.withReplacement) {
      var offset = response.replacementOffset;
      var length = response.replacementLength;
      var left = response.requestOffset - offset;
      var right = (offset + length) - response.requestOffset;
      if (left > 0 || right > 0) {
        _writelnWithIndent('replacement');
        if (left > 0) {
          _withIndent(() {
            _writelnWithIndent('left: $left');
          });
        }
        if (right > 0) {
          _withIndent(() {
            _writelnWithIndent('right: $right');
          });
        }
      }
    }
  }

  void _writeReturnType(CompletionSuggestion suggestion) {
    if (configuration.withReturnType) {
      var returnType = suggestion.returnType;
      if (returnType != null) {
        _writelnWithIndent('returnType: $returnType');
      }
    }
  }

  void _writeSelection(CompletionSuggestion suggestion) {
    if (configuration.withSelection) {
      var offset = suggestion.selectionOffset;
      var length = suggestion.selectionLength;
      if (length != 0) {
        _writelnWithIndent('selection: $offset $length');
      } else if (offset != suggestion.completion.length) {
        _writelnWithIndent('selection: $offset');
      }
    }
  }

  void _writeSuggestion(CompletionSuggestion suggestion) {
    _writeCompletion(suggestion);
    _withIndent(() {
      _writeSuggestionKind(suggestion);
      _writeElementOffset(suggestion);
      _writeDeclaringType(suggestion);
      _writeDeprecated(suggestion);
      _writeDefaultArgumentList(suggestion);
      _writeDisplayText(suggestion);
      _writeDocumentation(suggestion);
      _writeElement(suggestion);
      _writeIsNotImported(suggestion);
      _writeLibraryUri(suggestion);
      _writeParameterNames(suggestion);
      _writeRelevance(suggestion);
      _writeReturnType(suggestion);
      _writeSelection(suggestion);
    });
  }

  void _writeSuggestionKind(CompletionSuggestion suggestion) {
    if (configuration.withKind) {
      var kind = _getSuggestionKindName(suggestion);
      _writelnWithIndent('kind: $kind');
    }
  }

  void _writeSuggestions() {
    var filtered = response.suggestions.where(configuration.filter);
    var sorted = filtered.sorted(_compareSuggestions);

    _writelnWithIndent('suggestions');

    _withIndent(() {
      for (var suggestion in sorted) {
        if (configuration.filter(suggestion)) {
          _writeSuggestion(suggestion);
        }
      }
    });
  }
}

class Configuration {
  Sorting sorting;
  bool withDeclaringType;
  bool withDefaultArgumentList;
  bool withDisplayText;
  bool withDocumentation;
  bool withElement;
  bool withElementOffset;
  bool withIsNotImported;
  bool withKind;
  bool withLibraryUri;
  bool withLocationName;
  bool withParameterNames;
  bool withRelevance;
  bool withReplacement;
  bool withReturnType;
  bool withSelection;
  bool Function(CompletionSuggestion suggestion) filter;

  Configuration({
    this.sorting = Sorting.relevanceThenCompletionThenKind,
    this.withDeclaringType = false,
    this.withDefaultArgumentList = false,
    this.withDisplayText = false,
    this.withDocumentation = false,
    this.withElement = false,
    this.withElementOffset = false,
    this.withIsNotImported = false,
    this.withKind = true,
    this.withLibraryUri = false,
    this.withLocationName = false,
    this.withParameterNames = false,
    this.withReplacement = true,
    this.withRelevance = false,
    this.withReturnType = false,
    this.withSelection = true,
    required this.filter,
  });
}

enum Sorting { asIs, completionThenKind, relevanceThenCompletionThenKind }
