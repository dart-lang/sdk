// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';

abstract class CodeOptimizer {
  /// Returns names exported from the library [uriStr].
  Set<String> getImportedNames(String uriStr);

  List<Edit> optimize(
    String code, {
    required Set<String> libraryDeclarationNames,
    required ScannerConfiguration scannerConfiguration,
    bool throwIfHasErrors = false,
  }) {
    List<Edit> edits = [];

    ScannerResult result = scanString(
      code,
      configuration: scannerConfiguration,
      includeComments: true,
      languageVersionChanged: (scanner, languageVersion) {
        throw new UnimplementedError();
      },
    );

    if (result.hasErrors) {
      if (throwIfHasErrors) {
        throw new StateError('Has scan errors');
      }
      return [];
    }

    _Listener listener = new _Listener(
      getImportedNames: getImportedNames,
    );

    try {
      new Parser(
        listener,
        allowPatterns: true,
      ).parseUnit(result.tokens);
    } on _StateError {
      // Recover by doing nothing.
      return [];
    }

    if (listener.hasErrors) {
      if (throwIfHasErrors) {
        throw new StateError('Has parse errors');
      }
      return [];
    }

    List<_Import> imports = listener.importScope.imports;
    for (_Import import in imports) {
      for (_PrefixedName prefixedName in import.prefixedNames) {
        String name = prefixedName.name.lexeme;

        // If there is more than one import that exports the name.
        if (!listener.importScope.hasUniqueImport(name)) {
          import.namesWithPrefix.add(name);
          continue;
        }

        // Might be shadowed by a library declaration.
        if (libraryDeclarationNames.contains(name)) {
          import.namesWithPrefix.add(name);
          continue;
        }

        // Might be shadowed by a local declaration.
        if (listener.declaredNames.contains(name)) {
          import.namesWithPrefix.add(name);
          continue;
        }

        // Might shadow super declaration.
        if (listener.unqualifiedNames.contains(name)) {
          import.namesWithPrefix.add(name);
          continue;
        }

        import.namesWithoutPrefix.add(name);

        int prefixOffset = prefixedName.prefix.offset;
        edits.add(
          new RemoveImportPrefixReferenceEdit(
            offset: prefixOffset,
            length: prefixedName.name.offset - prefixOffset,
          ),
        );
      }
    }

    for (_Import import in imports) {
      if (import.namesWithPrefix.isEmpty) {
        int uriEnd = import.uriToken.end;
        edits.add(
          new RemoveImportPrefixDeclarationEdit(
            offset: uriEnd,
            length: import.semicolon.offset - uriEnd,
          ),
        );
      } else if (import.namesWithoutPrefix.isNotEmpty) {
        // If some names require the prefix, and some not, add a new import
        // without a prefix, but hide those which require prefix.
        List<String> namesToHide = import.namesWithPrefix.toList();
        namesToHide.sort();
        edits.add(
          new ImportWithoutPrefixEdit(
            offset: import.semicolon.end,
            uriStr: import.uriStr,
            namesToHide: namesToHide,
          ),
        );
      }
    }

    edits.sort((a, b) => a.offset - b.offset);
    return edits;
  }
}

sealed class Edit {
  final int offset;
  final int length;
  final String replacement;

  Edit({
    required this.offset,
    required this.length,
    required this.replacement,
  });

  static String applyList(List<Edit> edits, String value) {
    final StringBuffer buffer = new StringBuffer();
    int offset = 0;
    for (Edit edit in edits) {
      buffer.write(value.substring(offset, edit.offset));
      buffer.write(edit.replacement);
      offset = edit.offset + edit.length;
    }
    if (offset < value.length) buffer.write(value.substring(offset));
    return buffer.toString();
  }
}

final class ImportWithoutPrefixEdit extends Edit {
  final String uriStr;
  final List<String> namesToHide;

  ImportWithoutPrefixEdit({
    required super.offset,
    required this.uriStr,
    required this.namesToHide,
  }) : super(
          length: 0,
          replacement: '\nimport \'$uriStr\' hide ${namesToHide.join(', ')};',
        );
}

final class RemoveDartCoreImportEdit extends RemoveEdit {
  RemoveDartCoreImportEdit({
    required super.offset,
    required super.length,
  });
}

sealed class RemoveEdit extends Edit {
  RemoveEdit({
    required super.offset,
    required super.length,
  }) : super(replacement: '');
}

final class RemoveImportPrefixDeclarationEdit extends RemoveEdit {
  RemoveImportPrefixDeclarationEdit({
    required super.offset,
    required super.length,
  });
}

final class RemoveImportPrefixReferenceEdit extends RemoveEdit {
  RemoveImportPrefixReferenceEdit({
    required super.offset,
    required super.length,
  });
}

class _Import {
  final Token importKeyword;
  final Token uriToken;
  final String uriStr;
  final _ImportPrefix prefix;
  final Set<String> names;
  final Token semicolon;

  final List<_PrefixedName> prefixedNames = [];

  /// Names that are used with [prefix], but can be used without it.
  final Set<String> namesWithoutPrefix = {};

  /// Names that are used with [prefix], and the prefix cannot be removed.
  final Set<String> namesWithPrefix = {};

  _Import({
    required this.importKeyword,
    required this.uriToken,
    required this.uriStr,
    required this.prefix,
    required this.names,
    required this.semicolon,
  });
}

class _ImportPrefix {
  final Token name;

  _ImportPrefix({
    required this.name,
  });
}

class _ImportScope {
  final List<_Import> imports = [];

  _ImportScope();

  void addPrefixedName(_PrefixedName prefixed) {
    for (_Import import in imports) {
      if (import.prefix.name.lexeme == prefixed.prefix.lexeme) {
        import.prefixedNames.add(prefixed);
      }
    }
  }

  bool hasUniqueImport(String name) {
    int importCount = 0;
    for (_Import import in imports) {
      if (import.names.contains(name)) {
        importCount++;
      }
    }
    return importCount == 1;
  }
}

class _Listener extends Listener {
  Set<String> Function(String uriStr) getImportedNames;

  bool hasErrors = false;

  _ImportScope importScope = new _ImportScope();

  /// The names of local declarations.
  final Set<String> declaredNames = {};

  /// The names that are referenced without a preceding `<something>.`.
  /// These can be references to super declarations.
  final Set<String> unqualifiedNames = {};

  final List<Object?> stack = [];

  _Listener({
    required this.getImportedNames,
  });

  @override
  void beginExtensionDeclaration(
      Token? augmentToken, Token extensionKeyword, Token? name) {
    if (name != null) {
      declaredNames.add(name.lexeme);
    }
  }

  @override
  void beginExtensionTypeDeclaration(
      Token? augmentToken, Token extensionKeyword, Token name) {
    declaredNames.add(name.lexeme);
  }

  @override
  void endBinaryExpression(Token token) {
    Token? prefixToken = token.previous;
    if (prefixToken == null || prefixToken.type != TokenType.IDENTIFIER) {
      return;
    }

    Token? nameToken = token.next;
    if (nameToken == null || nameToken.type != TokenType.IDENTIFIER) {
      return;
    }

    importScope.addPrefixedName(
      new _PrefixedName(
        prefix: prefixToken,
        name: nameToken,
      ),
    );
  }

  @override
  void endImport(Token importKeyword, Token? augmentToken, Token? semicolon) {
    _ImportPrefix prefix = popOrThrow();

    Token? uriToken = importKeyword.next;
    if (uriToken == null) {
      throw new _StateError();
    }

    String uriStr = uriToken.lexeme;
    if (uriStr.startsWith('\'') && uriStr.endsWith('\'')) {
      uriStr = uriStr.substring(1, uriStr.length - 1);
    } else {
      throw new _StateError();
    }

    importScope.imports.add(
      new _Import(
        importKeyword: importKeyword,
        uriToken: uriToken,
        uriStr: uriStr,
        prefix: prefix,
        semicolon: semicolon!,
        names: getImportedNames(uriStr),
      ),
    );
  }

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    if (beginToken.type != TokenType.AT) {
      throw new _StateError();
    }

    Token? prefixToken = beginToken.next;
    if (prefixToken == null || prefixToken.type != TokenType.IDENTIFIER) {
      throw new _StateError();
    }

    Token? periodToken = prefixToken.next;
    if (periodToken == null || periodToken.type != TokenType.PERIOD) {
      return;
    }

    Token? nameToken = periodToken.next;
    if (nameToken == null || nameToken.type != TokenType.IDENTIFIER) {
      throw new _StateError();
    }

    importScope.addPrefixedName(
      new _PrefixedName(
        prefix: prefixToken,
        name: nameToken,
      ),
    );
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    if (context.inDeclaration) {
      declaredNames.add(token.lexeme);
    }

    if (context == IdentifierContext.importPrefixDeclaration) {
      push(
        new _ImportPrefix(
          name: token,
        ),
      );
    }
  }

  @override
  void handleRecoverableError(
    Message message,
    Token startToken,
    Token endToken,
  ) {
    hasErrors = true;
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    if (beginToken.type != TokenType.IDENTIFIER) {
      return;
    }

    // If not qualified with another identifier, or expression, then it could
    // be an invocation of a method from a superclass. So, we cannot remove
    // the prefix from the import that provides this name, imported names
    // shadow super names.
    Token? period = beginToken.previous;
    if (period == null || period.type != TokenType.PERIOD) {
      unqualifiedNames.add(beginToken.lexeme);
    }
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    Token prefixToken = beginToken;
    if (prefixToken.type != TokenType.IDENTIFIER) {
      throw new _StateError();
    }

    Token? periodToken = prefixToken.next;
    if (periodToken == null || periodToken.type != TokenType.PERIOD) {
      return;
    }

    Token? nameToken = periodToken.next;
    if (nameToken == null || nameToken.type != TokenType.IDENTIFIER) {
      throw new _StateError();
    }

    importScope.addPrefixedName(
      new _PrefixedName(
        prefix: prefixToken,
        name: nameToken,
      ),
    );
  }

  T popOrThrow<T>() {
    if (stack.lastOrNull case T last) {
      stack.removeLast();
      return last;
    }
    throw new _StateError();
  }

  void push(Object? value) {
    stack.add(value);
  }
}

class _PrefixedName {
  final Token prefix;
  final Token name;

  _PrefixedName({
    required this.prefix,
    required this.name,
  });

  @override
  String toString() {
    return '$prefix.$name';
  }
}

/// The exception that is thrown if an unexpected syntax found.
class _StateError {}
