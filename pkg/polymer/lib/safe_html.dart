// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): move this library to a shared package? or make part of
// dart:html?
library polymer.safe_html;

/** Declares a string that is a well-formed HTML fragment. */
class SafeHtml {

  /** Underlying html string. */
  final String _html;

  // TODO(sigmund): provide a constructor that does html validation
  SafeHtml.unsafe(this._html);

  String toString() => _html;

  operator ==(other) => other is SafeHtml && _html == other._html;
  int get hashCode => _html.hashCode;
}

/**
 * Declares a string that is safe to use in a Uri attribute, such as `<a href=`,
 * to avoid cross-site scripting (XSS) attacks.
 */
class SafeUri {
  final String _uri;

  // TODO(sigmund): provide a constructor that takes or creates a Uri and
  // validates that it is safe (not a javascript: scheme, for example)
  SafeUri.unsafe(this._uri);

  String toString() => _uri;

  operator ==(other) => other is SafeUri && _uri == other._uri;
  int get hashCode => _uri.hashCode;
}
