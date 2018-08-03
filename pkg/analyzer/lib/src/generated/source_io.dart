// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.source_io;

import 'dart:collection';

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as path;

export 'package:analyzer/src/generated/source.dart';

/**
 * Instances of the class [ExplicitSourceResolver] map URIs to files on disk
 * using a fixed mapping provided at construction time.
 */
@deprecated
class ExplicitSourceResolver extends UriResolver {
  final Map<Uri, JavaFile> uriToFileMap;
  final Map<String, Uri> pathToUriMap;

  /**
   * Construct an [ExplicitSourceResolver] based on the given [uriToFileMap].
   */
  ExplicitSourceResolver(Map<Uri, JavaFile> uriToFileMap)
      : uriToFileMap = uriToFileMap,
        pathToUriMap = _computePathToUriMap(uriToFileMap);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    JavaFile file = uriToFileMap[uri];
    actualUri ??= uri;
    if (file == null) {
      return new NonExistingSource(
          uri.toString(), actualUri, UriKind.fromScheme(actualUri.scheme));
    } else {
      return new FileBasedSource(file, actualUri);
    }
  }

  @override
  Uri restoreAbsolute(Source source) {
    return pathToUriMap[source.fullName];
  }

  /**
   * Build the inverse mapping of [uriToSourceMap].
   */
  static Map<String, Uri> _computePathToUriMap(
      Map<Uri, JavaFile> uriToSourceMap) {
    Map<String, Uri> pathToUriMap = <String, Uri>{};
    uriToSourceMap.forEach((Uri uri, JavaFile file) {
      pathToUriMap[file.getAbsolutePath()] = uri;
    });
    return pathToUriMap;
  }
}

/**
 * Instances of the class `FileBasedSource` implement a source that represents a file.
 */
class FileBasedSource extends Source {
  /**
   * A function that changes the way that files are read off of disk.
   */
  static Function fileReadMode = (String s) => s;

  /**
   * Map from encoded URI/filepath pair to a unique integer identifier.  This
   * identifier is used for equality tests and hash codes.
   *
   * The URI and filepath are joined into a pair by separating them with an '@'
   * character.
   */
  static final Map<String, int> _idTable = new HashMap<String, int>();

  /**
   * The URI from which this source was originally derived.
   */
  @override
  final Uri uri;

  /**
   * The unique ID associated with this [FileBasedSource].
   */
  final int id;

  /**
   * The file represented by this source.
   */
  final JavaFile file;

  /**
   * The cached absolute path of this source.
   */
  String _absolutePath;

  /**
   * The cached encoding for this source.
   */
  String _encoding;

  /**
   * Initialize a newly created source object to represent the given [file]. If
   * a [uri] is given, then it will be used as the URI from which the source was
   * derived, otherwise a `file:` URI will be created based on the [file].
   */
  FileBasedSource(JavaFile file, [Uri uri])
      : this.uri = uri ?? file.toURI(),
        this.file = file,
        id = _idTable.putIfAbsent(
            '${uri ?? file.toURI()}@${file.getPath()}', () => _idTable.length);

  @override
  TimestampedData<String> get contents {
    return PerformanceStatistics.io.makeCurrentWhile(() {
      return contentsFromFile;
    });
  }

  /**
   * Get the contents and timestamp of the underlying file.
   *
   * Clients should consider using the method [AnalysisContext.getContents]
   * because contexts can have local overrides of the content of a source that the source is not
   * aware of.
   *
   * @return the contents of the source paired with the modification stamp of the source
   * @throws Exception if the contents of this source could not be accessed
   * See [contents].
   */
  TimestampedData<String> get contentsFromFile {
    return new TimestampedData<String>(
        file.lastModified(), fileReadMode(file.readAsStringSync()));
  }

  @override
  String get encoding {
    if (_encoding == null) {
      _encoding = uri.toString();
    }
    return _encoding;
  }

  @override
  String get fullName {
    if (_absolutePath == null) {
      _absolutePath = file.getAbsolutePath();
    }
    return _absolutePath;
  }

  @override
  int get hashCode => uri.hashCode;

  @override
  bool get isInSystemLibrary => uri.scheme == DartUriResolver.DART_SCHEME;

  @override
  int get modificationStamp => file.lastModified();

  @override
  String get shortName => file.getName();

  @override
  UriKind get uriKind {
    String scheme = uri.scheme;
    return UriKind.fromScheme(scheme);
  }

  @override
  bool operator ==(Object object) {
    if (object is FileBasedSource) {
      return id == object.id;
    } else if (object is Source) {
      return uri == object.uri;
    }
    return false;
  }

  @override
  bool exists() => file.isFile();

  @override
  String toString() {
    if (file == null) {
      return "<unknown source>";
    }
    return file.getAbsolutePath();
  }
}

/**
 * Instances of the class `FileUriResolver` resolve `file` URI's.
 *
 * This class is now deprecated, 'new FileUriResolver()' is equivalent to
 * 'new ResourceUriResolver(PhysicalResourceProvider.INSTANCE)'.
 */
@deprecated
class FileUriResolver extends UriResolver {
  /**
   * The name of the `file` scheme.
   */
  static String FILE_SCHEME = "file";

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!isFileUri(uri)) {
      return null;
    }
    return new FileBasedSource(new JavaFile.fromUri(uri), actualUri ?? uri);
  }

  @override
  Uri restoreAbsolute(Source source) {
    return new Uri.file(source.fullName);
  }

  /**
   * Return `true` if the given URI is a `file` URI.
   *
   * @param uri the URI being tested
   * @return `true` if the given URI is a `file` URI
   */
  static bool isFileUri(Uri uri) => uri.scheme == FILE_SCHEME;
}

/**
 * Instances of interface `LocalSourcePredicate` are used to determine if the given
 * [Source] is "local" in some sense, so can be updated.
 */
abstract class LocalSourcePredicate {
  /**
   * Instance of [LocalSourcePredicate] that always returns `false`.
   */
  static final LocalSourcePredicate FALSE = new LocalSourcePredicate_FALSE();

  /**
   * Instance of [LocalSourcePredicate] that always returns `true`.
   */
  static final LocalSourcePredicate TRUE = new LocalSourcePredicate_TRUE();

  /**
   * Instance of [LocalSourcePredicate] that returns `true` for all [Source]s
   * except of SDK.
   */
  static final LocalSourcePredicate NOT_SDK =
      new LocalSourcePredicate_NOT_SDK();

  /**
   * Determines if the given [Source] is local.
   *
   * @param source the [Source] to analyze
   * @return `true` if the given [Source] is local
   */
  bool isLocal(Source source);
}

class LocalSourcePredicate_FALSE implements LocalSourcePredicate {
  @override
  bool isLocal(Source source) => false;
}

class LocalSourcePredicate_NOT_SDK implements LocalSourcePredicate {
  @override
  bool isLocal(Source source) => source.uriKind != UriKind.DART_URI;
}

class LocalSourcePredicate_TRUE implements LocalSourcePredicate {
  @override
  bool isLocal(Source source) => true;
}

/**
 * Instances of the class `PackageUriResolver` resolve `package` URI's in the context of
 * an application.
 *
 * For the purposes of sharing analysis, the path to each package under the "packages" directory
 * should be canonicalized, but to preserve relative links within a package, the remainder of the
 * path from the package directory to the leaf should not.
 */
@deprecated
class PackageUriResolver extends UriResolver {
  /**
   * The name of the `package` scheme.
   */
  static String PACKAGE_SCHEME = "package";

  /**
   * Log exceptions thrown with the message "Required key not available" only once.
   */
  static bool _CanLogRequiredKeyIoException = true;

  /**
   * The package directories that `package` URI's are assumed to be relative to.
   */
  final List<JavaFile> _packagesDirectories;

  /**
   * Initialize a newly created resolver to resolve `package` URI's relative to the given
   * package directories.
   *
   * @param packagesDirectories the package directories that `package` URI's are assumed to be
   *          relative to
   */
  PackageUriResolver(this._packagesDirectories) {
    if (_packagesDirectories.length < 1) {
      throw new ArgumentError(
          "At least one package directory must be provided");
    }
  }

  /**
   * If the list of package directories contains one element, return it.
   * Otherwise raise an exception.  Intended for testing.
   */
  String get packagesDirectory_forTesting {
    int length = _packagesDirectories.length;
    if (length != 1) {
      throw new Exception('Expected 1 package directory, found $length');
    }
    return _packagesDirectories[0].getPath();
  }

  /**
   * Answer the canonical file for the specified package.
   *
   * @param packagesDirectory the "packages" directory (not `null`)
   * @param pkgName the package name (not `null`, not empty)
   * @param relPath the path relative to the package directory (not `null`, no leading slash,
   *          but may be empty string)
   * @return the file (not `null`)
   */
  JavaFile getCanonicalFile(
      JavaFile packagesDirectory, String pkgName, String relPath) {
    JavaFile pkgDir = new JavaFile.relative(packagesDirectory, pkgName);
    try {
      pkgDir = pkgDir.getCanonicalFile();
    } catch (exception, stackTrace) {
      if (!exception.toString().contains("Required key not available")) {
        AnalysisEngine.instance.logger.logError("Canonical failed: $pkgDir",
            new CaughtException(exception, stackTrace));
      } else if (_CanLogRequiredKeyIoException) {
        _CanLogRequiredKeyIoException = false;
        AnalysisEngine.instance.logger.logError("Canonical failed: $pkgDir",
            new CaughtException(exception, stackTrace));
      }
    }
    return new JavaFile.relative(
        pkgDir,
        relPath.replaceAll(
            '/', new String.fromCharCode(JavaFile.separatorChar)));
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!isPackageUri(uri)) {
      return null;
    }
    String path = uri.path;
    if (path == null) {
      path = uri.path;
      if (path == null) {
        return null;
      }
    }
    String pkgName;
    String relPath;
    int index = path.indexOf('/');
    if (index == -1) {
      // No slash
      pkgName = path;
      relPath = "";
    } else if (index == 0) {
      // Leading slash is invalid
      return null;
    } else {
      // <pkgName>/<relPath>
      pkgName = path.substring(0, index);
      relPath = path.substring(index + 1);
    }
    for (JavaFile packagesDirectory in _packagesDirectories) {
      JavaFile resolvedFile = new JavaFile.relative(packagesDirectory, path);
      if (resolvedFile.exists()) {
        JavaFile canonicalFile =
            getCanonicalFile(packagesDirectory, pkgName, relPath);
        if (actualUri != null) {
          return new FileBasedSource(canonicalFile, actualUri);
        }
        if (_isSelfReference(packagesDirectory, canonicalFile)) {
          uri = canonicalFile.toURI();
        }
        return new FileBasedSource(canonicalFile, uri);
      }
    }
    return new FileBasedSource(
        getCanonicalFile(_packagesDirectories[0], pkgName, relPath),
        actualUri ?? uri);
  }

  @override
  Uri restoreAbsolute(Source source) {
    String sourceUri = _toFileUri(source.fullName);
    for (JavaFile packagesDirectory in _packagesDirectories) {
      List<JavaFile> pkgFolders = packagesDirectory.listFiles();
      if (pkgFolders != null) {
        for (JavaFile pkgFolder in pkgFolders) {
          try {
            String pkgCanonicalUri = _toFileUri(pkgFolder.getCanonicalPath());
            if (sourceUri.startsWith(pkgCanonicalUri)) {
              String relPath = sourceUri.substring(pkgCanonicalUri.length);
              return Uri
                  .parse("$PACKAGE_SCHEME:${pkgFolder.getName()}$relPath");
            }
          } catch (e) {}
        }
      }
    }
    return null;
  }

  /**
   * @return `true` if "file" was found in "packagesDir", and it is part of the "lib" folder
   *         of the application that contains in this "packagesDir".
   */
  bool _isSelfReference(JavaFile packagesDir, JavaFile file) {
    JavaFile rootDir = packagesDir.getParentFile();
    if (rootDir == null) {
      return false;
    }
    String rootPath = rootDir.getAbsolutePath();
    String filePath = file.getAbsolutePath();
    return filePath.startsWith("$rootPath/lib");
  }

  /**
   * Convert the given file path to a "file:" URI.  On Windows, this transforms
   * backslashes to forward slashes.
   */
  String _toFileUri(String filePath) => path.context.toUri(filePath).toString();

  /**
   * Return `true` if the given URI is a `package` URI.
   *
   * @param uri the URI being tested
   * @return `true` if the given URI is a `package` URI
   */
  static bool isPackageUri(Uri uri) => PACKAGE_SCHEME == uri.scheme;
}

/**
 * Instances of the class `RelativeFileUriResolver` resolve `file` URI's.
 *
 * This class is now deprecated, file URI resolution should be done with
 * ResourceUriResolver, i.e.
 * 'new ResourceUriResolver(PhysicalResourceProvider.INSTANCE)'.
 */
@deprecated
class RelativeFileUriResolver extends UriResolver {
  /**
   * The name of the `file` scheme.
   */
  static String FILE_SCHEME = "file";

  /**
   * The directories for the relatvie URI's
   */
  final List<JavaFile> _relativeDirectories;

  /**
   * The root directory for all the source trees
   */
  final JavaFile _rootDirectory;

  /**
   * Initialize a newly created resolver to resolve `file` URI's relative to the given root
   * directory.
   */
  RelativeFileUriResolver(this._rootDirectory, this._relativeDirectories)
      : super();

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    String rootPath = _rootDirectory.toURI().path;
    String uriPath = uri.path;
    if (uriPath != null && uriPath.startsWith(rootPath)) {
      String filePath = uri.path.substring(rootPath.length);
      for (JavaFile dir in _relativeDirectories) {
        JavaFile file = new JavaFile.relative(dir, filePath);
        if (file.exists()) {
          return new FileBasedSource(file, actualUri ?? uri);
        }
      }
    }
    return null;
  }

  /**
   * Return `true` if the given URI is a `file` URI.
   *
   * @param uri the URI being tested
   * @return `true` if the given URI is a `file` URI
   */
  static bool isFileUri(Uri uri) => uri.scheme == FILE_SCHEME;
}
