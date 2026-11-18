// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The name reported to analytics for an LSP client that isn't recognized.
const String otherLspClientName = 'other';

/// The known LSP client names, as substrings of the (lowercased) name that
/// clients send in the `clientInfo` of the `initialize` request, mapped to the
/// name reported to analytics.
///
/// The entries are checked in order, so more specific substrings must come
/// before less specific ones (for example, `nvim` before `vim`).
const List<(String, String)> _knownLspClients = [
  ('visual studio code', 'vscode'),
  ('vscode', 'vscode'),
  ('neovim', 'neovim'),
  ('nvim', 'neovim'),
  ('vim', 'vim'),
  ('zed', 'zed'),
  ('helix', 'helix'),
  ('emacs', 'emacs'),
  ('eglot', 'emacs'),
  ('sublime', 'sublime'),
  ('kate', 'kate'),
];

/// A version at the start of a string: up to four numeric components, with an
/// optional leading `v`, followed by the end of the string or a pre-release or
/// build suffix (`-`, `+`, or a space). The first group is the numeric version.
final RegExp _versionPattern = RegExp(
  r'^v?(\d{1,9}(?:\.\d{1,9}){0,3})(?:$|[-+ ])',
);

/// Returns the name to report to analytics for an LSP client that sent [name]
/// in the `clientInfo` of the `initialize` request.
///
/// Only names from a fixed list are reported, so that no free text is sent.
String lspClientNameForAnalytics(String name) {
  var lowerName = name.toLowerCase();
  for (var (substring, analyticsName) in _knownLspClients) {
    if (lowerName.contains(substring)) {
      return analyticsName;
    }
  }
  return otherLspClientName;
}

/// Returns the version to report to analytics for an LSP client that sent
/// [version] in the `clientInfo` of the `initialize` request, or an empty
/// string if it shouldn't be reported.
///
/// The version is only reported for recognized clients ([analyticsName] isn't
/// [otherLspClientName]), and only its leading numeric part is kept, so that no
/// free text is sent. Any pre-release or build suffix is dropped (for example,
/// `3.15.0-edge.102a906e` is reported as `3.15.0`).
String lspClientVersionForAnalytics(String analyticsName, String? version) {
  if (analyticsName == otherLspClientName || version == null) {
    return '';
  }
  return _versionPattern.firstMatch(version)?.group(1) ?? '';
}
