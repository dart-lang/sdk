// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';

abstract class CodeOptimizer {
  /// Returns names exported from the library [uriStr].
  Set<String> getImportedNames(String uriStr);

  List<Edit> optimize(String code) {
    List<Edit> edits = [];

    ScannerResult result = scanString(
      code,
      configuration: new ScannerConfiguration(
        forAugmentationLibrary: true,
      ),
      includeComments: true,
      languageVersionChanged: (scanner, languageVersion) {
        throw new UnimplementedError();
      },
    );

    _MyListener listener = new _MyListener(
      getImportedNames: getImportedNames,
    );

    Parser fastaParser = new Parser(
      listener,
      allowPatterns: true,
    );
    fastaParser.parseUnit(result.tokens);

    void walkScopes(_Scope scope) {
      for (_PrefixedName prefixedName in scope.prefixedNames) {
        String name = prefixedName.name.token.lexeme;
        _NameStatus resolution = scope.resolve(name);
        if (resolution is _NameStatusImported) {
          if (resolution.imports.length == 1) {
            int prefixOffset = prefixedName.prefix.token.offset;
            edits.add(
              new Edit(
                offset: prefixOffset,
                length: prefixedName.name.token.offset - prefixOffset,
                replacement: '',
              ),
            );
          }
        }
      }
      for (_Scope child in scope.children) {
        walkScopes(child);
      }
    }

    walkScopes(listener.importScope);

    edits.sort((a, b) => b.offset - a.offset);
    return edits;
  }
}

class Edit {
  final int offset;
  final int length;
  final String replacement;

  Edit({
    required this.offset,
    required this.length,
    required this.replacement,
  });

  static String applyList(List<Edit> edits, String value) {
    for (Edit edit in edits) {
      String before = value.substring(0, edit.offset);
      String after = value.substring(edit.offset + edit.length);
      value = before + edit.replacement + after;
    }
    return value;
  }
}

class _Identifier {
  final Token token;

  _Identifier(this.token);

  @override
  String toString() {
    return token.lexeme;
  }
}

class _Import {
  final String uriStr;
  final String prefix;
  final Set<String> names;

  _Import({
    required this.uriStr,
    required this.prefix,
    required this.names,
  });
}

class _ImportPrefix {
  final _Identifier name;

  _ImportPrefix({
    required this.name,
  });
}

class _ImportScope extends _Scope {
  final List<_Import> imports = [];

  _ImportScope();

  @override
  _NameStatus resolve(String name) {
    return new _NameStatusImported(
      imports: imports.where((import) {
        return import.names.contains(name);
      }).toList(),
    );
  }
}

class _InterpolationString {
  final List<Object?> components;

  _InterpolationString({
    required this.components,
  });

  @override
  String toString() {
    return components.join('');
  }
}

class _MyListener extends Listener {
  Set<String> Function(String uriStr) getImportedNames;

  _ImportScope importScope = new _ImportScope();
  late _Scope scope = new _NestedScope(parent: importScope);

  final List<Object?> stack = [];

  _MyListener({
    required this.getImportedNames,
  });

  @override
  void beginLiteralString(Token token) {
    push(
      new _StringLiteral(
        token: token,
      ),
    );
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    _popList(count);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    _Identifier name = pop() as _Identifier;
    _ensureNestedScope().names.add(name.token.lexeme);
  }

  @override
  void endImport(Token importKeyword, Token? augmentToken, Token? semicolon) {
    _ImportPrefix prefix = pop() as _ImportPrefix;
    _StringLiteral uri = pop() as _StringLiteral;

    String uriStr = uri.token.lexeme;
    if (uriStr.startsWith('\'') && uriStr.endsWith('\'')) {
      uriStr = uriStr.substring(1, uriStr.length - 1);
    } else {
      throw new UnimplementedError();
    }

    importScope.imports.add(
      new _Import(
        uriStr: uriStr,
        prefix: prefix.name.token.lexeme,
        names: getImportedNames(uriStr),
      ),
    );
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    if (interpolationCount == 0) {
      return;
    }

    push(
      new _InterpolationString(
        components: _popList(1 + interpolationCount + 1),
      ),
    );
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    push(
      new _Identifier(token),
    );
  }

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    if (asKeyword == null) {
      throw new StateError('All macro imports must be prefixed');
    }

    _Identifier name = pop() as _Identifier;

    push(
      new _ImportPrefix(
        name: name,
      ),
    );
  }

  @override
  void handleQualified(Token period) {
    _Identifier name = pop() as _Identifier;
    _Identifier prefix = pop() as _Identifier;
    push(
      new _PrefixedName(
        prefix: prefix,
        name: name,
      ),
    );
  }

  @override
  void handleStringPart(Token token) {
    push(
      new _StringLiteral(
        token: token,
      ),
    );
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    Object? prefixedName = pop();
    if (prefixedName is _PrefixedName) {
      scope.prefixedNames.add(prefixedName);
    }
  }

  Object? pop() {
    return stack.removeLast();
  }

  void push(Object? value) {
    stack.add(value);
  }

  _NestedScope _ensureNestedScope() {
    if (scope case _NestedScope existing) {
      return existing;
    }
    return scope = new _NestedScope(parent: scope);
  }

  List<Object?> _popList(int count) {
    List<Object?> result = <Object?>[];
    for (int i = 0; i < count; i++) {
      Object? element = pop();
      result.add(element);
    }
    return result.reversed.toList();
  }
}

sealed class _NameStatus {
  const _NameStatus();
}

class _NameStatusImported extends _NameStatus {
  /// The imports that would provide this name if used without a prefix.
  final List<_Import> imports;

  _NameStatusImported({
    required this.imports,
  });
}

/// The name is shadowed by a local declaration.
///
/// A top-level declaration anywhere in the library.
///
/// A local declaration in the same scope - local variable, method name,
/// type parameters name, formal parameter name, etc.
class _NameStatusShadowed extends _NameStatus {
  const _NameStatusShadowed();
}

class _NestedScope extends _Scope {
  final _Scope parent;
  final Set<String> names = {};

  _NestedScope({
    required this.parent,
  }) {
    parent.children.add(this);
  }

  @override
  _NameStatus resolve(String name) {
    if (names.contains(name)) {
      return const _NameStatusShadowed();
    }
    return parent.resolve(name);
  }
}

class _PrefixedName {
  final _Identifier prefix;
  final _Identifier name;

  _PrefixedName({
    required this.prefix,
    required this.name,
  });

  @override
  String toString() {
    return '$prefix.$name';
  }
}

sealed class _Scope {
  final List<_PrefixedName> prefixedNames = [];
  final List<_Scope> children = [];

  _NameStatus resolve(String name);
}

class _StringLiteral {
  final Token token;

  _StringLiteral({
    required this.token,
  });

  @override
  String toString() {
    return token.lexeme;
  }
}
