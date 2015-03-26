// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library memory_file_system;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

import 'file_system.dart';

/**
 * An in-memory implementation of [ResourceProvider].
 * Use `/` as a path separator.
 */
class MemoryResourceProvider implements ResourceProvider {
  final Map<String, _MemoryResource> _pathToResource =
      new HashMap<String, _MemoryResource>();
  final Map<String, String> _pathToContent = new HashMap<String, String>();
  final Map<String, int> _pathToTimestamp = new HashMap<String, int>();
  final Map<String, List<StreamController<WatchEvent>>> _pathToWatchers =
      new HashMap<String, List<StreamController<WatchEvent>>>();
  int nextStamp = 0;

  @override
  Context get pathContext => posix;

  /**
   * Delete the file with the given path.
   */
  void deleteFile(String path) {
    _checkFileAtPath(path);
    _pathToResource.remove(path);
    _pathToContent.remove(path);
    _pathToTimestamp.remove(path);
    _notifyWatchers(path, ChangeType.REMOVE);
  }

  /**
   * Delete the folder with the given path
   * and recurively delete nested files and folders.
   */
  void deleteFolder(String path) {
    _checkFolderAtPath(path);
    _MemoryFolder folder = _pathToResource[path];
    for (Resource child in folder.getChildren()) {
      if (child is File) {
        deleteFile(child.path);
      } else if (child is Folder) {
        deleteFolder(child.path);
      } else {
        throw 'failed to delete resource: $child';
      }
    }
    _pathToResource.remove(path);
    _pathToContent.remove(path);
    _pathToTimestamp.remove(path);
    _notifyWatchers(path, ChangeType.REMOVE);
  }

  @override
  Resource getResource(String path) {
    path = posix.normalize(path);
    Resource resource = _pathToResource[path];
    if (resource == null) {
      resource = new _MemoryFile(this, path);
    }
    return resource;
  }

  @override
  Folder getStateLocation(String pluginId) {
    return newFolder('/user/home/$pluginId');
  }

  void modifyFile(String path, String content) {
    _checkFileAtPath(path);
    _pathToContent[path] = content;
    _pathToTimestamp[path] = nextStamp++;
    _notifyWatchers(path, ChangeType.MODIFY);
  }

  /**
   * Create a resource representing a dummy link (that is, a File object which
   * appears in its parent directory, but whose `exists` property is false)
   */
  File newDummyLink(String path) {
    path = posix.normalize(path);
    newFolder(posix.dirname(path));
    _MemoryDummyLink link = new _MemoryDummyLink(this, path);
    _pathToResource[path] = link;
    _pathToTimestamp[path] = nextStamp++;
    _notifyWatchers(path, ChangeType.ADD);
    return link;
  }

  File newFile(String path, String content, [int stamp]) {
    path = posix.normalize(path);
    newFolder(posix.dirname(path));
    _MemoryFile file = new _MemoryFile(this, path);
    _pathToResource[path] = file;
    _pathToContent[path] = content;
    _pathToTimestamp[path] = stamp != null ? stamp : nextStamp++;
    _notifyWatchers(path, ChangeType.ADD);
    return file;
  }

  Folder newFolder(String path) {
    path = posix.normalize(path);
    if (!path.startsWith('/')) {
      throw new ArgumentError("Path must start with '/'");
    }
    _MemoryResource resource = _pathToResource[path];
    if (resource == null) {
      String parentPath = posix.dirname(path);
      if (parentPath != path) {
        newFolder(parentPath);
      }
      _MemoryFolder folder = new _MemoryFolder(this, path);
      _pathToResource[path] = folder;
      _pathToTimestamp[path] = nextStamp++;
      return folder;
    } else if (resource is _MemoryFolder) {
      return resource;
    } else {
      String message =
          'Folder expected at ' "'$path'" 'but ${resource.runtimeType} found';
      throw new ArgumentError(message);
    }
  }

  File updateFile(String path, String content, [int stamp]) {
    path = posix.normalize(path);
    newFolder(posix.dirname(path));
    _MemoryFile file = new _MemoryFile(this, path);
    _pathToResource[path] = file;
    _pathToContent[path] = content;
    _pathToTimestamp[path] = stamp != null ? stamp : nextStamp++;
    _notifyWatchers(path, ChangeType.MODIFY);
    return file;
  }

  void _checkFileAtPath(String path) {
    _MemoryResource resource = _pathToResource[path];
    if (resource is! _MemoryFile) {
      throw new ArgumentError(
          'File expected at "$path" but ${resource.runtimeType} found');
    }
  }

  void _checkFolderAtPath(String path) {
    _MemoryResource resource = _pathToResource[path];
    if (resource is! _MemoryFolder) {
      throw new ArgumentError(
          'Folder expected at "$path" but ${resource.runtimeType} found');
    }
  }

  void _notifyWatchers(String path, ChangeType changeType) {
    _pathToWatchers.forEach((String watcherPath,
        List<StreamController<WatchEvent>> streamControllers) {
      if (posix.isWithin(watcherPath, path)) {
        for (StreamController<WatchEvent> streamController
            in streamControllers) {
          streamController.add(new WatchEvent(changeType, path));
        }
      }
    });
  }
}

/**
 * An in-memory implementation of [File] which acts like a symbolic link to a
 * non-existent file.
 */
class _MemoryDummyLink extends _MemoryResource implements File {
  _MemoryDummyLink(MemoryResourceProvider provider, String path)
      : super(provider, path);

  @override
  bool get exists => false;

  int get modificationStamp {
    int stamp = _provider._pathToTimestamp[path];
    if (stamp == null) {
      throw new FileSystemException(path, "File does not exist");
    }
    return stamp;
  }

  String get _content {
    throw new FileSystemException(path, 'File could not be read');
  }

  @override
  Source createSource([Uri uri]) {
    throw new FileSystemException(path, 'File could not be read');
  }

  @override
  bool isOrContains(String path) {
    return path == this.path;
  }

  @override
  String readAsStringSync() {
    throw new FileSystemException(path, 'File could not be read');
  }
}

/**
 * An in-memory implementation of [File].
 */
class _MemoryFile extends _MemoryResource implements File {
  _MemoryFile(MemoryResourceProvider provider, String path)
      : super(provider, path);

  @override
  bool get exists => _provider._pathToResource[path] is _MemoryFile;

  int get modificationStamp {
    int stamp = _provider._pathToTimestamp[path];
    if (stamp == null) {
      throw new FileSystemException(path, 'File "$path" does not exist.');
    }
    return stamp;
  }

  String get _content {
    String content = _provider._pathToContent[path];
    if (content == null) {
      throw new FileSystemException(path, 'File "$path" does not exist.');
    }
    return content;
  }

  @override
  Source createSource([Uri uri]) {
    if (uri == null) {
      uri = posix.toUri(path);
    }
    return new _MemoryFileSource(this, uri);
  }

  @override
  bool isOrContains(String path) {
    return path == this.path;
  }

  @override
  String readAsStringSync() {
    String content = _provider._pathToContent[path];
    if (content == null) {
      throw new FileSystemException(path, 'File "$path" does not exist.');
    }
    return content;
  }
}

/**
 * An in-memory implementation of [Source].
 */
class _MemoryFileSource extends Source {
  /**
   * Map from encoded URI/filepath pair to a unique integer identifier.  This
   * identifier is used for equality tests and hash codes.
   *
   * The URI and filepath are joined into a pair by separating them with an '@'
   * character.
   */
  static final Map<String, int> _idTable = new HashMap<String, int>();

  final _MemoryFile file;

  final Uri uri;

  /**
   * The unique ID associated with this [_MemoryFileSource].
   */
  final int id;

  _MemoryFileSource(_MemoryFile file, Uri uri)
      : uri = uri,
        file = file,
        id = _idTable.putIfAbsent('$uri@${file.path}', () => _idTable.length);

  @override
  TimestampedData<String> get contents {
    return new TimestampedData<String>(modificationStamp, file._content);
  }

  @override
  String get encoding {
    return uri.toString();
  }

  @override
  String get fullName => file.path;

  @override
  int get hashCode => id;

  @override
  bool get isInSystemLibrary => uriKind == UriKind.DART_URI;

  @override
  int get modificationStamp {
    try {
      return file.modificationStamp;
    } on FileSystemException {
      return -1;
    }
  }

  @override
  String get shortName => file.shortName;

  @override
  UriKind get uriKind {
    String scheme = uri.scheme;
    if (scheme == PackageUriResolver.PACKAGE_SCHEME) {
      return UriKind.PACKAGE_URI;
    } else if (scheme == DartUriResolver.DART_SCHEME) {
      return UriKind.DART_URI;
    } else if (scheme == FileUriResolver.FILE_SCHEME) {
      return UriKind.FILE_URI;
    }
    return UriKind.FILE_URI;
  }

  @override
  bool operator ==(other) {
    return other is _MemoryFileSource && other.id == id;
  }

  @override
  bool exists() => file.exists;

  @override
  Uri resolveRelativeUri(Uri relativeUri) {
    return uri.resolveUri(relativeUri);
  }

  @override
  String toString() => file.toString();
}

/**
 * An in-memory implementation of [Folder].
 */
class _MemoryFolder extends _MemoryResource implements Folder {
  _MemoryFolder(MemoryResourceProvider provider, String path)
      : super(provider, path);

  @override
  Stream<WatchEvent> get changes {
    StreamController<WatchEvent> streamController =
        new StreamController<WatchEvent>();
    if (!_provider._pathToWatchers.containsKey(path)) {
      _provider._pathToWatchers[path] = <StreamController<WatchEvent>>[];
    }
    _provider._pathToWatchers[path].add(streamController);
    streamController.done.then((_) {
      _provider._pathToWatchers[path].remove(streamController);
      if (_provider._pathToWatchers[path].isEmpty) {
        _provider._pathToWatchers.remove(path);
      }
    });
    return streamController.stream;
  }

  @override
  bool get exists => _provider._pathToResource[path] is _MemoryFolder;

  @override
  String canonicalizePath(String relPath) {
    relPath = posix.normalize(relPath);
    String childPath = posix.join(path, relPath);
    childPath = posix.normalize(childPath);
    return childPath;
  }

  @override
  bool contains(String path) {
    return posix.isWithin(this.path, path);
  }

  @override
  Resource getChild(String relPath) {
    String childPath = canonicalizePath(relPath);
    _MemoryResource resource = _provider._pathToResource[childPath];
    if (resource == null) {
      resource = new _MemoryFile(_provider, childPath);
    }
    return resource;
  }

  @override
  _MemoryFolder getChildAssumingFolder(String relPath) {
    String childPath = canonicalizePath(relPath);
    _MemoryResource resource = _provider._pathToResource[childPath];
    if (resource is _MemoryFolder) {
      return resource;
    }
    return new _MemoryFolder(_provider, childPath);
  }

  @override
  List<Resource> getChildren() {
    if (!exists) {
      throw new FileSystemException(path, 'Folder does not exist.');
    }
    List<Resource> children = <Resource>[];
    _provider._pathToResource.forEach((resourcePath, resource) {
      if (posix.dirname(resourcePath) == path) {
        children.add(resource);
      }
    });
    return children;
  }

  @override
  bool isOrContains(String path) {
    if (path == this.path) {
      return true;
    }
    return contains(path);
  }
}

/**
 * An in-memory implementation of [Resource].
 */
abstract class _MemoryResource implements Resource {
  final MemoryResourceProvider _provider;
  final String path;

  _MemoryResource(this._provider, this.path);

  @override
  get hashCode => path.hashCode;

  @override
  Folder get parent {
    String parentPath = posix.dirname(path);
    if (parentPath == path) {
      return null;
    }
    return _provider.getResource(parentPath);
  }

  @override
  String get shortName => posix.basename(path);

  @override
  bool operator ==(other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return path == other.path;
  }

  @override
  String toString() => path;
}
