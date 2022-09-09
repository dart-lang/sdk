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
    _writeResponseReplacement();
    _writeSuggestions();
  }

  String _getSuggestionKindName(CompletionSuggestion suggestion) {
    final kind = suggestion.kind;
    if (kind == CompletionSuggestionKind.KEYWORD) {
      return 'keyword';
    } else if (kind == CompletionSuggestionKind.IDENTIFIER) {
      final elementKind = suggestion.element?.kind;
      if (elementKind == null) {
        return 'identifier';
      } else if (elementKind == ElementKind.CLASS) {
        return 'class';
      } else if (elementKind == ElementKind.ENUM) {
        return 'enum';
      } else if (elementKind == ElementKind.ENUM_CONSTANT) {
        return 'enumConstant';
      } else if (elementKind == ElementKind.FIELD) {
        return 'field';
      } else if (elementKind == ElementKind.GETTER) {
        return 'getter';
      } else if (elementKind == ElementKind.LIBRARY) {
        return 'library';
      } else if (elementKind == ElementKind.PARAMETER) {
        return 'parameter';
      } else if (elementKind == ElementKind.TOP_LEVEL_VARIABLE) {
        return 'topLevelVariable';
      }
      throw UnimplementedError('elementKind: $elementKind');
    } else if (kind == CompletionSuggestionKind.INVOCATION) {
      final elementKind = suggestion.element?.kind;
      if (elementKind == null) {
        return 'invocation';
      } else if (elementKind == ElementKind.CONSTRUCTOR) {
        return 'constructorInvocation';
      } else if (elementKind == ElementKind.FUNCTION) {
        return 'functionInvocation';
      }
      throw UnimplementedError('elementKind: $elementKind');
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
    final completion = suggestion.completion;
    if (RegExp(r'^\s').hasMatch(completion) ||
        RegExp(r'\s$').hasMatch(completion)) {
      _writelnWithIndent('|$completion|');
    } else {
      _writelnWithIndent(completion);
    }
  }

  void _writeDisplayText(CompletionSuggestion suggestion) {
    if (configuration.withDisplayText) {
      _writelnWithIndent('displayText: ${suggestion.displayText}');
    }
  }

  void _writelnWithIndent(String line) {
    buffer.write(_indent);
    buffer.writeln(line);
  }

  void _writeRelevance(CompletionSuggestion suggestion) {
    if (configuration.withRelevance) {
      _writelnWithIndent('relevance: ${suggestion.relevance}');
    }
  }

  void _writeResponseReplacement() {
    if (configuration.withReplacement) {
      final offset = response.replacementOffset;
      final length = response.replacementLength;
      final left = response.requestOffset - offset;
      final right = (offset + length) - response.requestOffset;
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
      final returnType = suggestion.returnType;
      if (returnType != null) {
        _writelnWithIndent('returnType: $returnType');
      }
    }
  }

  void _writeSelection(CompletionSuggestion suggestion) {
    if (configuration.withSelection) {
      final offset = suggestion.selectionOffset;
      final length = suggestion.selectionLength;
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
      _writeDisplayText(suggestion);
      _writeRelevance(suggestion);
      _writeReturnType(suggestion);
      _writeSelection(suggestion);
    });
  }

  void _writeSuggestionKind(CompletionSuggestion suggestion) {
    if (configuration.withKind) {
      final kind = _getSuggestionKindName(suggestion);
      _writelnWithIndent('kind: $kind');
    }
  }

  void _writeSuggestions() {
    final filtered = response.suggestions.where(configuration.filter);
    final sorted = filtered.sorted((a, b) {
      switch (configuration.sorting) {
        case Sorting.asIs:
          return 0;
        case Sorting.completion:
          return a.completion.compareTo(b.completion);
        case Sorting.relevanceThenCompletion:
          final relevanceDiff = a.relevance - b.relevance;
          if (relevanceDiff != 0) {
            return -relevanceDiff;
          } else {
            return a.completion.compareTo(b.completion);
          }
      }
    });

    _writelnWithIndent('suggestions');

    _withIndent(() {
      for (final suggestion in sorted) {
        if (configuration.filter(suggestion)) {
          _writeSuggestion(suggestion);
        }
      }
    });
  }
}

class Configuration {
  Sorting sorting;
  bool withDisplayText;
  bool withKind;
  bool withRelevance;
  bool withReplacement;
  bool withReturnType;
  bool withSelection;
  bool Function(CompletionSuggestion suggestion) filter;

  Configuration({
    this.sorting = Sorting.relevanceThenCompletion,
    this.withDisplayText = false,
    this.withKind = true,
    this.withReplacement = true,
    this.withRelevance = false,
    this.withReturnType = false,
    this.withSelection = true,
    required this.filter,
  });
}

enum Sorting {
  asIs,
  completion,
  relevanceThenCompletion,
}
