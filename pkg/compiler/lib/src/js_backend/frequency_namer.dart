// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend.namer;

class FrequencyBasedNamer extends Namer
    with _MinifiedFieldNamer, _MinifiedOneShotInterceptorNamer
    implements jsAst.TokenFinalizer {
  _FieldNamingRegistry fieldRegistry;
  List<TokenName> tokens = new List<TokenName>();

  Map<NamingScope, TokenScope> _tokenScopes =
      new Maplet<NamingScope, TokenScope>();

  // Some basic settings for smaller names
  String get isolateName => 'I';
  String get isolatePropertiesName => 'p';
  bool get shouldMinify => true;

  final String getterPrefix = 'g';
  final String setterPrefix = 's';
  final String callPrefix = ''; // this will create function names $<n>
  String get requiredParameterField => r'$R';
  String get defaultValuesField => r'$D';
  String get operatorSignature => r'$S';

  jsAst.Name get staticsPropertyName =>
      _staticsPropertyName ??= getFreshName(instanceScope, 'static');

  FrequencyBasedNamer(
      ClosedWorld closedWorld, CodegenWorldBuilder codegenWorldBuilder)
      : super(closedWorld, codegenWorldBuilder) {
    fieldRegistry = new _FieldNamingRegistry(this);
  }

  TokenScope newScopeFor(NamingScope scope) {
    if (scope == instanceScope) {
      Set<String> illegalNames = new Set<String>.from(jsReserved);
      for (String illegal in MinifyNamer._reservedNativeProperties) {
        illegalNames.add(illegal);
        if (MinifyNamer._hasBannedPrefix(illegal)) {
          illegalNames.add(illegal.substring(1));
        }
      }
      return new TokenScope(illegalNames);
    } else {
      return new TokenScope(jsReserved);
    }
  }

  @override
  jsAst.Name getFreshName(NamingScope scope, String proposedName,
      {bool sanitizeForNatives: false, bool sanitizeForAnnotations: false}) {
    // Grab the scope for this token
    TokenScope tokenScope =
        _tokenScopes.putIfAbsent(scope, () => newScopeFor(scope));

    // Get the name the normal namer would use as a key.
    String proposed = _generateFreshStringForName(proposedName, scope,
        sanitizeForNatives: sanitizeForNatives,
        sanitizeForAnnotations: sanitizeForAnnotations);

    TokenName name = new TokenName(tokenScope, proposed);
    tokens.add(name);
    return name;
  }

  @override
  jsAst.Name instanceFieldPropertyName(FieldEntity element) {
    jsAst.Name proposed = _minifiedInstanceFieldPropertyName(element);
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

class TokenScope {
  List<int> _nextName = [$a];
  final Set<String> illegalNames;

  TokenScope([this.illegalNames = const ImmutableEmptySet()]);

  /// Increments the letter at [pos] in the current name. Also takes care of
  /// overflows to the left. Returns the carry bit, i.e., it returns `true`
  /// if all positions to the left have wrapped around.
  ///
  /// If [_nextName] is initially 'a', this will generate the sequence
  ///
  /// [a-zA-Z]
  /// [a-zA-Z][_0-9a-zA-Z]
  /// [a-zA-Z][_0-9a-zA-Z][_0-9a-zA-Z]
  /// ...
  bool _incrementPosition(int pos) {
    bool overflow = false;
    if (pos < 0) return true;
    int value = _nextName[pos];
    if (value == $_) {
      value = $0;
    } else if (value == $9) {
      value = $a;
    } else if (value == $z) {
      value = $A;
    } else if (value == $Z) {
      overflow = _incrementPosition(pos - 1);
      value = (pos > 0) ? $_ : $a;
    } else {
      value++;
    }
    _nextName[pos] = value;
    return overflow;
  }

  _incrementName() {
    if (_incrementPosition(_nextName.length - 1)) {
      _nextName.add($_);
    }
  }

  String getNextName() {
    String proposal;
    do {
      proposal = new String.fromCharCodes(_nextName);
      _incrementName();
    } while (MinifyNamer._hasBannedPrefix(proposal) ||
        illegalNames.contains(proposal));

    return proposal;
  }
}
