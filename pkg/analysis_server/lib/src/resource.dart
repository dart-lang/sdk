// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library resource;

import 'dart:io' as io;

import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart';


/**
 * [File]s are leaf [Resource]s which contain data.
 */
abstract class File extends Resource {
  /**
   * Create a new [Source] instance that serves this file.
   */
  Source createSource(UriKind uriKind);
}


/**
 * [Folder]s are [Resource]s which may contain files and/or other folders.
 */
abstract class Folder extends Resource {
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
   * Return the full (long) version of the name that can be displayed to the
   * user to denote this resource.
   */
  String get fullName;

  /**
   * Return a short version of the name that can be displayed to the user to
   * denote this resource.
   */
  String get shortName;
}


/**
 * Instances of the class [ResourceProvider] convert [String] paths into
 * [Resource]s.
 */
abstract class ResourceProvider {
  /**
   * Return the [Resource] that corresponds to the given [path].
   */
  Resource getResource(String path);
}


/**
 * An in-memory implementation of [Resource].
 */
abstract class _MemoryResource implements Resource {
  final MemoryResourceProvider _provider;
  final String _path;

  _MemoryResource(this._provider, this._path);

  @override
  bool operator ==(other) {
    return identical(this, other);
  }

  @override
  bool get exists => _provider._pathToResource.containsKey(_path);

  @override
  String get fullName => _path;

  @override
  get hashCode => _path.hashCode;

  @override
  String get shortName => basename(_path);

  @override
  String toString() => fullName;
}


/**
 * An in-memory implementation of [File].
 */
class _MemoryFile extends _MemoryResource implements File {
  _MemoryFile(MemoryResourceProvider provider, String path) :
      super(provider, path);

  @override
  Source createSource(UriKind uriKind) {
    return new _MemoryFileSource(this, uriKind);
  }

  String get _content {
    String content = _provider._pathToContent[_path];
    if (content == null) {
      throw new MemoryResourceException(_path, "File '$_path' does not exist");
    }
    return content;
  }

  int get _timestamp => _provider._pathToTimestamp[_path];
}


/**
 * Exception thrown when a memory [Resource] file operation fails.
 */
class MemoryResourceException {
  final path;
  final message;

  MemoryResourceException(this.path, this.message);

  @override
  String toString() {
    return "MemoryResourceException(path=$path; message=$message)";
  }
}


/**
 * An in-memory implementation of [Source].
 */
class _MemoryFileSource implements Source {
  final _MemoryFile _file;

  final UriKind uriKind;

  _MemoryFileSource(this._file, this.uriKind);

  @override
  TimestampedData<String> get contents {
    return new TimestampedData<String>(modificationStamp, _file._content);
  }

  @override
  String get encoding {
    return '${new String.fromCharCode(uriKind.encoding)}${_file.fullName}';
  }

  @override
  bool exists() => _file.exists;

  @override
  String get fullName => _file.fullName;

  @override
  bool get isInSystemLibrary => false;

  @override
  int get modificationStamp => _file._timestamp;

  @override
  Source resolveRelative(Uri relativeUri) {
    String relativePath = fromUri(relativeUri);
    String folderPath = dirname(_file._path);
    String path = join(folderPath, relativePath);
    path = normalize(path);
    _MemoryFile file = new _MemoryFile(_file._provider, path);
    return new _MemoryFileSource(file, uriKind);
  }

  @override
  String get shortName => _file.shortName;
}


/**
 * An in-memory implementation of [Folder].
 */
class _MemoryFolder extends _MemoryResource implements Folder {
  _MemoryFolder(MemoryResourceProvider provider, String path) :
      super(provider, path);
  @override
  Resource getChild(String relPath) {
    relPath = normalize(relPath);
    String childPath = join(_path, relPath);
    childPath = normalize(childPath);
    _MemoryResource resource = _provider._pathToResource[childPath];
    if (resource == null) {
      resource = new _MemoryFile(_provider, childPath);
    }
    return resource;
  }

  @override
  List<Resource> getChildren() {
    List<Resource> children = <Resource>[];
    _provider._pathToResource.forEach((path, resource) {
      if (dirname(path) == _path) {
        children.add(resource);
      }
    });
    return children;
  }
}


/**
 * An in-memory implementation of [ResourceProvider].
 * Use `/` as a path separator.
 */
class MemoryResourceProvider implements ResourceProvider {
  final Map<String, _MemoryResource> _pathToResource = <String, _MemoryResource>{};
  final Map<String, String> _pathToContent = <String, String>{};
  final Map<String, int> _pathToTimestamp = <String, int>{};
  int nextStamp = 0;

  @override
  Resource getResource(String path) {
    path = normalize(path);
    Resource resource = _pathToResource[path];
    if (resource == null) {
      resource = new _MemoryFile(this, path);
    }
    return resource;
  }

  Folder newFolder(String path) {
    path = normalize(path);
    if (path.isEmpty) {
      throw new ArgumentError('Empty paths are not supported');
    }
    if (!path.startsWith('/')) {
      throw new ArgumentError("Path must start with '/'");
    }
    _MemoryFolder folder = null;
    String partialPath = "";
    for (String pathPart in path.split('/')) {
      if (pathPart.isEmpty) {
        continue;
      }
      partialPath += '/' + pathPart;
      _MemoryResource resource = _pathToResource[partialPath];
      if (resource == null) {
        folder = new _MemoryFolder(this, partialPath);
        _pathToResource[partialPath] = folder;
        _pathToTimestamp[partialPath] = nextStamp++;
      } else if (resource is _MemoryFolder) {
        folder = resource;
      } else {
        String message = 'Folder expected at '
                         "'$partialPath'"
                         'but ${resource.runtimeType} found';
        throw new ArgumentError(message);
      }
    }
    return folder;
  }

  File newFile(String path, String content) {
    path = normalize(path);
    newFolder(dirname(path));
    _MemoryFile file = new _MemoryFile(this, path);
    _pathToResource[path] = file;
    _pathToContent[path] = content;
    _pathToTimestamp[path] = nextStamp++;
    return file;
  }
}


/**
 * A `dart:io` based implementation of [File].
 */
class _PhysicalFile extends _PhysicalResource implements File {
  _PhysicalFile(io.File file) : super(file);

  @override
  Source createSource(UriKind uriKind) {
    io.File file = _entry as io.File;
    JavaFile javaFile = new JavaFile(file.absolute.path);
    return new FileBasedSource.con2(javaFile, uriKind);
  }
}


/**
 * A `dart:io` based implementation of [Folder].
 */
class _PhysicalFolder extends _PhysicalResource implements Folder {
  _PhysicalFolder(io.Directory directory) : super(directory);

  @override
  Resource getChild(String relPath) {
    String childPath = join(_entry.absolute.path, relPath);
    return PhysicalResourceProvider.INSTANCE.getResource(childPath);
  }

  @override
  List<Resource> getChildren() {
    List<Resource> children = <Resource>[];
    io.Directory directory = _entry as io.Directory;
    List<io.FileSystemEntity> entries = directory.listSync(recursive: false);
    int numEntries = entries.length;
    for (int i = 0; i < numEntries; i++) {
      io.FileSystemEntity entity = entries[i];
      if (entity is io.Directory) {
        children.add(new _PhysicalFolder(entity));
      } else if (entity is io.File) {
        children.add(new _PhysicalFile(entity));
      }
    }
    return children;
  }
}


/**
 * A `dart:io` based implementation of [Resource].
 */
abstract class _PhysicalResource implements Resource {
  final io.FileSystemEntity _entry;

  _PhysicalResource(this._entry);

  @override
  bool get exists => _entry.existsSync();

  @override
  String get fullName => _entry.absolute.path;

  @override
  get hashCode => _entry.hashCode;

  @override
  String get shortName => basename(fullName);

  @override
  String toString() => fullName;
}


/**
 * A `dart:io` based implementation of [ResourceProvider].
 */
class PhysicalResourceProvider implements ResourceProvider {
  static final PhysicalResourceProvider INSTANCE = new PhysicalResourceProvider._();

  PhysicalResourceProvider._();

  @override
  Resource getResource(String path) {
    if (io.FileSystemEntity.isDirectorySync(path)) {
      io.Directory directory = new io.Directory(path);
      return new _PhysicalFolder(directory);
    } else {
      io.File file = new io.File(path);
      return new _PhysicalFile(file);
    }
  }
}
