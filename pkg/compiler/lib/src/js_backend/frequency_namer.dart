// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend.namer;

class FrequencyBasedNamer extends Namer
    with _MinifiedFieldNamer, _MinifiedOneShotInterceptorNamer
    implements jsAst.TokenFinalizer {
  @override
  late final _FieldNamingRegistry fieldRegistry = _FieldNamingRegistry(this);
  List<TokenName> tokens = [];

  final Map<NamingScope, TokenScope> _tokenScopes = {};

  @override
  String get genericInstantiationPrefix => r'$I';

  FrequencyBasedNamer(super.closedWorld, super.fixedNames);

  TokenScope newScopeFor(NamingScope scope) {
    if (scope == instanceScope) {
      Set<String> illegalNames = Set<String>.from(jsReserved);
      for (String illegal in MinifyNamer._reservedNativeProperties) {
        illegalNames.add(illegal);
        if (hasBannedMinifiedPrefix(illegal)) {
          illegalNames.add(illegal.substring(1));
        }
      }
      return TokenScope(illegalNames: illegalNames);
    } else {
      return TokenScope(illegalNames: jsReserved);
    }
  }

  @override
  jsAst.Name getFreshName(NamingScope scope, String proposedName,
      {bool sanitizeForNatives = false, bool sanitizeForAnnotations = false}) {
    // Grab the scope for this token
    TokenScope tokenScope =
        _tokenScopes.putIfAbsent(scope, () => newScopeFor(scope));

    // Get the name the normal namer would use as a key.
    String proposed = _generateFreshStringForName(proposedName, scope,
        sanitizeForNatives: sanitizeForNatives,
        sanitizeForAnnotations: sanitizeForAnnotations);

    TokenName name = TokenName(tokenScope, proposed);
    tokens.add(name);
    return name;
  }

  @override
  jsAst.Name instanceFieldPropertyName(FieldEntity element) {
    jsAst.Name? proposed = _minifiedInstanceFieldPropertyName(element);
    if (proposed != null) {
      return proposed;
    }
    return super.instanceFieldPropertyName(element);
  }

  @override
  void finalizeTokens() {
    int compareReferenceCount(TokenName a, TokenName b) {
      int result = b._rc - a._rc;
      if (result == 0) result = a.key.compareTo(b.key);
      return result;
    }

    List<TokenName> usedNames =
        tokens.where((TokenName a) => a._rc > 0).toList();
    usedNames.sort(compareReferenceCount);
    usedNames.forEach((TokenName token) => token.finalize());
  }
}
