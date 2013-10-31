// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.barback_settings;

/// A generic settings object for providing configuration details to
/// [Transformer]s.
///
/// Barback does not specify *how* this is provided to transformers. It is up
/// to a host application to handle this. (For example, pub passes this to the
/// transformer's constructor.)
class BarbackSettings {
  /// An open-ended map of configuration properties specific to this
  /// transformer.
  ///
  /// The contents of the map should be serializable across isolates, but
  /// otherwise can contain whatever you want.
  final Map configuration;

  /// The mode that user is running Barback in.
  ///
  /// This will be the same for all transformers in a running instance of
  /// Barback.
  final BarbackMode mode;

  BarbackSettings(this.configuration, this.mode);
}

/// Enum-like class for specifying a mode that transformers may be run in.
///
/// Note that this is not a *closed* set of enum values. Host applications may
/// define their own values for this, so a transformer relying on it should
/// ensure that it behaves sanely with unknown values.
class BarbackMode {
  /// The normal mode used during development.
  static const DEBUG = const BarbackMode._("debug");

  /// The normal mode used to build an application for deploying to production.
  static const RELEASE = const BarbackMode._("release");

  /// The name of the mode.
  ///
  /// By convention, this is a lowercase string.
  final String name;

  /// Create a mode named [name].
  factory BarbackMode(String name) {
    // Use canonical instances of known names.
    switch (name) {
      case "debug": return BarbackMode.DEBUG;
      case "release": return BarbackMode.RELEASE;
      default:
        return new BarbackMode._(name);
    }
  }

  const BarbackMode._(this.name);

  String toString() => name;
}
