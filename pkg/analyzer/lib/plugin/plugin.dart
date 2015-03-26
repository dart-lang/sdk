// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.plugin.plugin;

/**
 * A function used to register the given [extension] to the extension point with
 * the given unique [identifier].
 *
 * An [ExtensionError] will be thrown if the [extension] is not appropriate
 * for the extension point, such as an [extension] that does not implement the
 * required interface.
 */
typedef void RegisterExtension(String identifier, Object extension);

/**
 * A function used to register an extension point with the given simple
 * [identifier]. If given, the [validator] will be used to validate extensions
 * to the extension point.
 *
 * An [ExtensionError] will be thrown if the extension point cannot be
 * registered, such as when a plugin attempts to define two extension points
 * with the same simple identifier.
 */
typedef ExtensionPoint RegisterExtensionPoint(String identifier,
    [ValidateExtension validateExtension]);

/**
 * A function used by a plugin to validate an [extension] to a extension point.
 *
 * An [ExtensionError] should be thrown if the [extension] is not valid for the
 * extension point, such as an [extension] that does not implement the required
 * interface.
 */
typedef void ValidateExtension(Object extension);

/**
 * An exception indicating that an error occurred while attempting to register
 * either an extension or an extension point.
 *
 * Clients are not expected to subtype this class.
 */
class ExtensionError implements Exception {
  /**
   * The message describing the error that occurred.
   */
  final String message;

  /**
   * Initialize a newly created error to have the given message.
   */
  ExtensionError(this.message);
}

/**
 * A representation of an extension point.
 *
 * Clients are not expected to subtype this class.
 */
abstract class ExtensionPoint {
  /**
   * Return an immutable list containing all of the extensions that were
   * registered for this extension point.
   */
  List<Object> get extensions;

  /**
   * Return the plugin that defined this extension point.
   */
  Plugin get plugin;

  /**
   * Return the identifier used to uniquely identify this extension point within
   * the defining plugin.
   */
  String get simpleIdentifier;

  /**
   * Return the identifier used to uniquely identify this extension point. The
   * unique identifier is the identifier for the plugin, followed by a period
   * (`.`), followed by the [simpleIdentifier] for the extension point.
   */
  String get uniqueIdentifier;
}

/**
 * A contribution to the analysis server that can extend the behavior of the
 * server while also allowing other plugins to extend it's behavior.
 *
 * Clients are expected to subtype this class when implementing plugins.
 */
abstract class Plugin {
  /**
   * Return the identifier used to uniquely identify this plugin.
   */
  String get uniqueIdentifier;

  /**
   * Use the [register] function to register all of the extension points
   * contributed by this plugin.
   *
   * Clients should not invoke the [register] function after this method has
   * returned.
   */
  void registerExtensionPoints(RegisterExtensionPoint register);

  /**
   * Use the [register] function to register all of the extensions contributed
   * by this plugin.
   *
   * Clients should not invoke the [register] function after this method has
   * returned.
   */
  void registerExtensions(RegisterExtension register);

  /**
   * Return a unique identifier created from the unique identifier from the
   * [plugin] and the [simpleIdentifier].
   */
  static String buildUniqueIdentifier(Plugin plugin, String simpleIdentifier) =>
      join(plugin.uniqueIdentifier, simpleIdentifier);

  /**
   * Return an identifier created by joining the [pluginIdentifier] and the
   * [simpleIdentifier].
   */
  static String join(String pluginIdentifier, String simpleIdentifier) =>
      '$pluginIdentifier.$simpleIdentifier';
}
