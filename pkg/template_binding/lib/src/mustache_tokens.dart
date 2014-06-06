// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.src.mustache_tokens;

import 'package:observe/observe.dart';

// Dart note: this was added to decouple the parse function below from the rest
// of template_binding. This allows using this code in command-line tools as
// well.
typedef Function DelegateFunctionFactory(String pathString);

/**
 * Represents a set of parsed tokens from a {{ mustache binding expression }}.
 * This can be created by calling [parse].
 *
 * For performance reasons the data is stored in one linear array in [_tokens].
 * This class wraps that array and provides accessors in an attempt to make the
 * pattern easier to understand. See [length] and [getText] for example.
 */
class MustacheTokens {
  // Constants for indexing into the exploded structs in [_tokens] .
  static const _TOKEN_TEXT = 0;
  static const _TOKEN_ONETIME = 1;
  static const _TOKEN_PATH = 2;
  static const _TOKEN_PREPAREFN = 3;
  static const _TOKEN_SIZE = 4;

  // There is 1 extra entry for the end text.
  static const _TOKEN_ENDTEXT = 1;

  bool get hasOnePath => _tokens.length == _TOKEN_SIZE + _TOKEN_ENDTEXT;
  bool get isSimplePath => hasOnePath &&
      _tokens[_TOKEN_TEXT] == '' && _tokens[_TOKEN_SIZE + _TOKEN_TEXT] == '';

  /**
   * [TEXT, (ONE_TIME?, PATH, DELEGATE_FN, TEXT)+] if there is at least one
   * mustache.
   */
  final List _tokens;

  final bool onlyOneTime;

  // Dart note: I think this is cached in JavaScript to avoid an extra
  // allocation per template instance. Seems reasonable, so we do the same.
  Function _combinator;
  Function get combinator => _combinator;

  MustacheTokens._(this._tokens, this.onlyOneTime) {
    // Should be: [TEXT, (ONE_TIME?, PATH, DELEGATE_FN, TEXT)+].
    assert((_tokens.length - _TOKEN_ENDTEXT) % _TOKEN_SIZE == 0);

    _combinator = hasOnePath ? _singleCombinator : _listCombinator;
  }

  int get length => _tokens.length ~/ _TOKEN_SIZE;

  /**
   * Gets the [i]th text entry. Note that [length] can be passed to get the
   * final text entry.
   */
  String getText(int i) => _tokens[i * _TOKEN_SIZE + _TOKEN_TEXT];

  /** Gets the oneTime flag for the [i]th token. */
  bool getOneTime(int i) => _tokens[i * _TOKEN_SIZE + _TOKEN_ONETIME];

  /** Gets the path for the [i]th token. */
  PropertyPath getPath(int i) => _tokens[i * _TOKEN_SIZE + _TOKEN_PATH];

  /** Gets the prepareBinding function for the [i]th token. */
  Function getPrepareBinding(int i) =>
      _tokens[i * _TOKEN_SIZE + _TOKEN_PREPAREFN];


  /**
   * Parses {{ mustache }} bindings.
   *
   * Returns null if there are no matches. Otherwise returns the parsed tokens.
   */
  static MustacheTokens parse(String s, [DelegateFunctionFactory fnFactory]) {
    if (s == null || s.isEmpty) return null;

    var tokens = null;
    var length = s.length;
    var lastIndex = 0;
    var onlyOneTime = true;
    while (lastIndex < length) {
      var startIndex = s.indexOf('{{', lastIndex);
      var oneTimeStart = s.indexOf('[[', lastIndex);
      var oneTime = false;
      var terminator = '}}';

      if (oneTimeStart >= 0 &&
          (startIndex < 0 || oneTimeStart < startIndex)) {
        startIndex = oneTimeStart;
        oneTime = true;
        terminator = ']]';
      }

      var endIndex = -1;
      if (startIndex >= 0) {
        endIndex = s.indexOf(terminator, startIndex + 2);
      }

      if (endIndex < 0) {
        if (tokens == null) return null;

        tokens.add(s.substring(lastIndex)); // TEXT
        break;
      }

      if (tokens == null) tokens = [];
      tokens.add(s.substring(lastIndex, startIndex)); // TEXT
      var pathString = s.substring(startIndex + 2, endIndex).trim();
      tokens.add(oneTime); // ONETIME?
      onlyOneTime = onlyOneTime && oneTime;
      var delegateFn = fnFactory == null ? null : fnFactory(pathString);
      // Don't try to parse the expression if there's a prepareBinding function
      if (delegateFn == null) {
        tokens.add(new PropertyPath(pathString)); // PATH
      } else {
        tokens.add(null);
      }
      tokens.add(delegateFn); // DELEGATE_FN

      lastIndex = endIndex + 2;
    }

    if (lastIndex == length) tokens.add(''); // TEXT

    return new MustacheTokens._(tokens, onlyOneTime);
  }


  // Dart note: split "combinator" into the single/list variants, so the
  // argument can be typed.
  String _singleCombinator(Object value) {
    if (value == null) value = '';
    return '${getText(0)}$value${getText(length)}';
  }

  String _listCombinator(List<Object> values) {
    var newValue = new StringBuffer(getText(0));
    int len = this.length;
    for (var i = 0; i < len; i++) {
      var value = values[i];
      if (value != null) newValue.write(value);
      newValue.write(getText(i + 1));
    }
    return newValue.toString();
  }
}
