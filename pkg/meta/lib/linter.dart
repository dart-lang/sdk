// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tools that developers can use to improve the linter behaviour.
library meta_linter;

/// Operations on futures which can help with enabling or avoiding lints.
extension FutureLintExtensions<T> on Future<T>? {
  /// Indicates to tools that the future is intentionally not `await`-ed.
  ///
  /// In an `async` context, it is normally expected that all [Future]s are
  /// awaited, and that is the basis of the lint `unawaited_futures`. However,
  /// there are times where one or more futures are intentionally not awaited.
  /// This getter may be used to ignore a particular future. It silences the
  /// `unawaited_futures` lint.
  ///
  /// ```
  /// Future<void> saveUserPreferences() async {
  ///   await _writePreferences();
  ///
  ///   // While 'log' returns a Future, the consumer of 'saveUserPreferences'
  ///   // is unlikely to want to wait for that future to complete; they only
  ///   // care about the preferences being written).
  ///   log('Preferences saved!').unawaited;
  /// }
  /// ```
  void get unawaited {}
}
