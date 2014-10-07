// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library file_system;

import 'dart:async';

import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';


/**
 * [File]s are leaf [Resource]s which contain data.
 */
abstract class File extends Resource {
  /**
   * Create a new [Source] instance that serves this file.
   */
  Source createSource([Uri uri]);
}


/**
 * [Folder]s are [Resource]s which may contain files and/or other folders.
 */
abstract class Folder extends Resource {
  /**
   * Watch for changes to the files inside this folder (and in any nested
   * folders, including folders reachable via links).
   */
  Stream<WatchEvent> get changes;

  /**
   * If the path [path] is a relative path, convert it to an absolute path
   * by interpreting it relative to this folder.  If it is already an aboslute
   * path, then don't change it.
   *
   * However, regardless of whether [path] is relative or absolute, normalize
   * it by removing path components of the form '.' or '..'.
   */
  String canonicalizePath(String path);

  /**
   * Return `true` if absolute [path] references a resource in this folder.
   */
  bool contains(String path);

  /**
   * Return an existing child [Resource] with the given [relPath].
   * Return a not existing [File] if no such child exist.
   */
  Resource getChild(String relPath);

  /**
   * Return a list of existing direct children [Resource]s (folders and files)
   * in this folder, in no particular order.
   */
  List<Resource> getChildren();
}


/**
 * The abstract class [Resource] is an abstraction of file or folder.
 */
abstract class Resource {
  /**
   * Return `true` if this resource exists.
   */
  bool get exists;

  /**
   * Return the [Folder] that contains this resource, or `null` if this resource
   * is a root folder.
   */
  Folder get parent;

  /**
   * Return the full path to this resource.
   */
  String get path;

  /**
   * Return a short version of the name that can be displayed to the user to
   * denote this resource.
   */
  String get shortName;

  /**
   * Return `true` if absolute [path] references this resource or a resource in
   * this folder.
   */
  bool isOrContains(String path);
}


/**
 * Instances of the class [ResourceProvider] convert [String] paths into
 * [Resource]s.
 */
abstract class ResourceProvider {
  /**
   * Get the path context used by this resource provider.
   */
  Context get pathContext;

  /**
   * Return the [Resource] that corresponds to the given [path].
   */
  Resource getResource(String path);

  /**
   * Return the folder in which the plugin with the given [pluginId] can store
   * state that will persist across sessions. The folder returned for a given id
   * will not be returned for a different id, ensuring that plugins do not need
   * to be concerned with file name collisions with other plugins, assuming that
   * the plugin ids are unique. The plugin ids must be valid folder names.
   */
  Folder getStateLocation(String pluginId);
}


/**
 * A [UriResolver] for [Resource]s.
 */
class ResourceUriResolver extends UriResolver {
  /**
   * The name of the `file` scheme.
   */
  static String _FILE_SCHEME = "file";

  final ResourceProvider _provider;

  ResourceUriResolver(this._provider);

  @override
  Source resolveAbsolute(Uri uri) {
    if (!_isFileUri(uri)) {
      return null;
    }
    Resource resource = _provider.getResource(_provider.pathContext.fromUri(uri)
        );
    if (resource is File) {
      return resource.createSource(uri);
    }
    return null;
  }

  /**
   * Return `true` if the given URI is a `file` URI.
   *
   * @param uri the URI being tested
   * @return `true` if the given URI is a `file` URI
   */
  static bool _isFileUri(Uri uri) => uri.scheme == _FILE_SCHEME;
}
