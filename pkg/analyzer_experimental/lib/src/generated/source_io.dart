// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.source.io;

import 'source.dart';
import 'dart:io';
import 'dart:uri';
import 'java_core.dart';
import 'java_io.dart';
import 'sdk.dart' show DartSdk;
import 'engine.dart' show AnalysisContext, AnalysisEngine;
export 'source.dart';

/**
 * Instances of the class {@code FileBasedSource} implement a source that represents a file.
 * @coverage dart.engine.source
 */
class FileBasedSource implements Source {
  /**
   * The content cache used to access the contents of this source if they have been overridden from
   * what is on disk or cached.
   */
  ContentCache _contentCache;
  /**
   * The file represented by this source.
   */
  JavaFile _file;
  /**
   * The cached URI of the {@link #file}.
   */
  String _fileUriString;
  /**
   * A flag indicating whether this source is in one of the system libraries.
   */
  bool _inSystemLibrary = false;
  /**
   * Initialize a newly created source object. The source object is assumed to not be in a system
   * library.
   * @param contentCache the content cache used to access the contents of this source
   * @param file the file represented by this source
   */
  FileBasedSource.con1(ContentCache contentCache, JavaFile file) {
    _jtd_constructor_328_impl(contentCache, file);
  }
  _jtd_constructor_328_impl(ContentCache contentCache, JavaFile file) {
    _jtd_constructor_329_impl(contentCache, file, false);
  }
  /**
   * Initialize a newly created source object.
   * @param contentCache the content cache used to access the contents of this source
   * @param file the file represented by this source
   * @param inSystemLibrary {@code true} if this source is in one of the system libraries
   */
  FileBasedSource.con2(ContentCache contentCache2, JavaFile file3, bool inSystemLibrary2) {
    _jtd_constructor_329_impl(contentCache2, file3, inSystemLibrary2);
  }
  _jtd_constructor_329_impl(ContentCache contentCache2, JavaFile file3, bool inSystemLibrary2) {
    this._contentCache = contentCache2;
    this._file = file3;
    this._inSystemLibrary = inSystemLibrary2;
    this._fileUriString = file3.toURI().toString();
  }
  bool operator ==(Object object) => object != null && identical(this.runtimeType, object.runtimeType) && _file == ((object as FileBasedSource))._file;
  bool exists() => _contentCache.getContents(this) != null || (_file.exists() && !_file.isDirectory());
  void getContents(Source_ContentReceiver receiver) {
    {
      String contents = _contentCache.getContents(this);
      if (contents != null) {
        receiver.accept2(contents, _contentCache.getModificationStamp(this));
        return;
      }
    }
    receiver.accept2(_file.readAsStringSync(), _file.lastModified());
  }
  String get encoding => _fileUriString;
  String get fullName => _file.getAbsolutePath();
  int get modificationStamp {
    int stamp = _contentCache.getModificationStamp(this);
    if (stamp != null) {
      return stamp;
    }
    return _file.lastModified();
  }
  String get shortName => _file.getName();
  int get hashCode => _file.hashCode;
  bool isInSystemLibrary() => _inSystemLibrary;
  Source resolveRelative(Uri containedUri) {
    try {
      Uri resolvedUri = file.toURI().resolveUri(containedUri);
      return new FileBasedSource.con2(_contentCache, new JavaFile.fromUri(resolvedUri), isInSystemLibrary());
    } catch (exception) {
    }
    return null;
  }
  String toString() {
    if (_file == null) {
      return "<unknown source>";
    }
    return _file.getAbsolutePath();
  }
  /**
   * Return the file represented by this source. This is an internal method that is only intended to
   * be used by {@link UriResolver}.
   * @return the file represented by this source
   */
  JavaFile get file => _file;
}
/**
 * Instances of the class {@code PackageUriResolver} resolve {@code package} URI's in the context of
 * an application.
 * <p>
 * For the purposes of sharing analysis, the path to each package under the "packages" directory
 * should be canonicalized, but to preserve relative links within a package, the remainder of the
 * path from the package directory to the leaf should not.
 * @coverage dart.engine.source
 */
class PackageUriResolver extends UriResolver {
  /**
   * The package directories that {@code package} URI's are assumed to be relative to.
   */
  List<JavaFile> _packagesDirectories;
  /**
   * The name of the {@code package} scheme.
   */
  static String _PACKAGE_SCHEME = "package";
  /**
   * Return {@code true} if the given URI is a {@code package} URI.
   * @param uri the URI being tested
   * @return {@code true} if the given URI is a {@code package} URI
   */
  static bool isPackageUri(Uri uri) => uri.scheme == _PACKAGE_SCHEME;
  /**
   * Initialize a newly created resolver to resolve {@code package} URI's relative to the given
   * package directories.
   * @param packagesDirectories the package directories that {@code package} URI's are assumed to be
   * relative to
   */
  PackageUriResolver(List<JavaFile> packagesDirectories) {
    if (packagesDirectories.length < 1) {
      throw new IllegalArgumentException("At least one package directory must be provided");
    }
    this._packagesDirectories = packagesDirectories;
  }
  Source resolveAbsolute(ContentCache contentCache, Uri uri) {
    if (!isPackageUri(uri)) {
      return null;
    }
    String path4 = uri.path;
    if (path4 == null) {
      path4 = uri.path;
      if (path4 == null) {
        return null;
      }
    }
    String pkgName;
    String relPath;
    int index = path4.indexOf('/');
    if (index == -1) {
      pkgName = path4;
      relPath = "";
    } else if (index == 0) {
      return null;
    } else {
      pkgName = path4.substring(0, index);
      relPath = path4.substring(index + 1);
    }
    for (JavaFile packagesDirectory in _packagesDirectories) {
      JavaFile resolvedFile = new JavaFile.relative(packagesDirectory, path4);
      if (resolvedFile.exists()) {
        return new FileBasedSource.con1(contentCache, getCanonicalFile(packagesDirectory, pkgName, relPath));
      }
    }
    return new FileBasedSource.con1(contentCache, getCanonicalFile(_packagesDirectories[0], pkgName, relPath));
  }
  /**
   * Answer the canonical file for the specified package.
   * @param packagesDirectory the "packages" directory (not {@code null})
   * @param pkgName the package name (not {@code null}, not empty)
   * @param relPath the path relative to the package directory (not {@code null}, no leading slash,
   * but may be empty string)
   * @return the file (not {@code null})
   */
  JavaFile getCanonicalFile(JavaFile packagesDirectory, String pkgName, String relPath) {
    JavaFile pkgDir = new JavaFile.relative(packagesDirectory, pkgName);
    try {
      pkgDir = pkgDir.getCanonicalFile();
    } on IOException catch (e) {
      AnalysisEngine.instance.logger.logError2("Canonical failed: ${pkgDir}", e);
    }
    return new JavaFile.relative(pkgDir, relPath.replaceAll(0x2F, JavaFile.separatorChar));
  }
}
/**
 * Instances of the class {@link DirectoryBasedSourceContainer} represent a source container that
 * contains all sources within a given directory.
 * @coverage dart.engine.source
 */
class DirectoryBasedSourceContainer implements SourceContainer {
  /**
   * Append the system file separator to the given path unless the path already ends with a
   * separator.
   * @param path the path to which the file separator is to be added
   * @return a path that ends with the system file separator
   */
  static String appendFileSeparator(String path) {
    if (path == null || path.length <= 0 || path.codeUnitAt(path.length - 1) == JavaFile.separatorChar) {
      return path;
    }
    return "${path}${JavaFile.separator}";
  }
  /**
   * The container's path (not {@code null}).
   */
  String _path;
  /**
   * Construct a container representing the specified directory and containing any sources whose{@link Source#getFullName()} starts with the directory's path. This is a convenience method,
   * fully equivalent to {@link DirectoryBasedSourceContainer#DirectoryBasedSourceContainer(String)}.
   * @param directory the directory (not {@code null})
   */
  DirectoryBasedSourceContainer.con1(JavaFile directory) {
    _jtd_constructor_326_impl(directory);
  }
  _jtd_constructor_326_impl(JavaFile directory) {
    _jtd_constructor_327_impl(directory.getPath());
  }
  /**
   * Construct a container representing the specified path and containing any sources whose{@link Source#getFullName()} starts with the specified path.
   * @param path the path (not {@code null} and not empty)
   */
  DirectoryBasedSourceContainer.con2(String path3) {
    _jtd_constructor_327_impl(path3);
  }
  _jtd_constructor_327_impl(String path3) {
    this._path = appendFileSeparator(path3);
  }
  bool contains(Source source) => source.fullName.startsWith(_path);
  bool operator ==(Object obj) => (obj is DirectoryBasedSourceContainer) && ((obj as DirectoryBasedSourceContainer)).path == path;
  /**
   * Answer the receiver's path, used to determine if a source is contained in the receiver.
   * @return the path (not {@code null}, not empty)
   */
  String get path => _path;
  int get hashCode => _path.hashCode;
}
/**
 * Instances of the class {@code FileUriResolver} resolve {@code file} URI's.
 * @coverage dart.engine.source
 */
class FileUriResolver extends UriResolver {
  /**
   * The name of the {@code file} scheme.
   */
  static String _FILE_SCHEME = "file";
  /**
   * Return {@code true} if the given URI is a {@code file} URI.
   * @param uri the URI being tested
   * @return {@code true} if the given URI is a {@code file} URI
   */
  static bool isFileUri(Uri uri) => uri.scheme == _FILE_SCHEME;
  /**
   * Initialize a newly created resolver to resolve {@code file} URI's relative to the given root
   * directory.
   */
  FileUriResolver() : super() {
  }
  Source resolveAbsolute(ContentCache contentCache, Uri uri) {
    if (!isFileUri(uri)) {
      return null;
    }
    return new FileBasedSource.con1(contentCache, new JavaFile.fromUri(uri));
  }
}