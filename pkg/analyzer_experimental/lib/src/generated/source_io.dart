// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.source.io;

import 'source.dart';
import 'dart:io';
import 'dart:uri';
import 'java_core.dart';
import 'java_io.dart';
import 'package:analyzer_experimental/src/generated/sdk.dart' show DartSdk;
export 'source.dart';

/**
 * Instances of the class {@code FileBasedSource} implement a source that represents a file.
 * @coverage dart.engine.source
 */
class FileBasedSource implements Source {
  /**
   * The source factory that created this source and that should be used to resolve URI's against
   * this source.
   */
  SourceFactory _factory;
  /**
   * The file represented by this source.
   */
  JavaFile _file;
  /**
   * A flag indicating whether this source is in one of the system libraries.
   */
  bool _inSystemLibrary = false;
  /**
   * Initialize a newly created source object. The source object is assumed to not be in a system
   * library.
   * @param factory the source factory that created this source
   * @param file the file represented by this source
   */
  FileBasedSource.con1(SourceFactory factory, JavaFile file) {
    _jtd_constructor_296_impl(factory, file);
  }
  _jtd_constructor_296_impl(SourceFactory factory, JavaFile file) {
    _jtd_constructor_297_impl(factory, file, false);
  }
  /**
   * Initialize a newly created source object.
   * @param factory the source factory that created this source
   * @param file the file represented by this source
   * @param inSystemLibrary {@code true} if this source is in one of the system libraries
   */
  FileBasedSource.con2(SourceFactory factory2, JavaFile file3, bool inSystemLibrary2) {
    _jtd_constructor_297_impl(factory2, file3, inSystemLibrary2);
  }
  _jtd_constructor_297_impl(SourceFactory factory2, JavaFile file3, bool inSystemLibrary2) {
    this._factory = factory2;
    this._file = file3;
    this._inSystemLibrary = inSystemLibrary2;
  }
  bool operator ==(Object object) => object != null && identical(this.runtimeType, object.runtimeType) && _file == ((object as FileBasedSource))._file;
  bool exists() => _file.exists();
  void getContents(Source_ContentReceiver receiver) {
    {
      String contents = _factory.getContents(this);
      if (contents != null) {
        receiver.accept2(contents);
        return;
      }
    }
    receiver.accept2(_file.readAsStringSync());
  }
  String get encoding => _file.toURI().toString();
  String get fullName => _file.getAbsolutePath();
  int get modificationStamp {
    int stamp = _factory.getModificationStamp(this);
    if (stamp != null) {
      return stamp;
    }
    return _file.lastModified();
  }
  String get shortName => _file.getName();
  int get hashCode => _file.hashCode;
  bool isInSystemLibrary() => _inSystemLibrary;
  Source resolve(String uri) => _factory.resolveUri(this, uri);
  Source resolveRelative(Uri containedUri) {
    try {
      Uri resolvedUri = file.toURI().resolveUri(containedUri);
      return new FileBasedSource.con1(_factory, new JavaFile.fromUri(resolvedUri));
    } on JavaException catch (exception) {
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
 * Instances of the class {@code DartUriResolver} resolve {@code dart} URI's.
 * @coverage dart.engine.source
 */
class DartUriResolver extends UriResolver {
  /**
   * The Dart SDK against which URI's are to be resolved.
   */
  DartSdk _sdk;
  /**
   * The name of the {@code dart} scheme.
   */
  static String _DART_SCHEME = "dart";
  /**
   * Return {@code true} if the given URI is a {@code dart:} URI.
   * @param uri the URI being tested
   * @return {@code true} if the given URI is a {@code dart:} URI
   */
  static bool isDartUri(Uri uri) => uri.scheme == _DART_SCHEME;
  /**
   * Initialize a newly created resolver to resolve Dart URI's against the given platform within the
   * given Dart SDK.
   * @param sdk the Dart SDK against which URI's are to be resolved
   */
  DartUriResolver(DartSdk sdk) {
    this._sdk = sdk;
  }
  Source resolveAbsolute(SourceFactory factory, Uri uri) {
    if (!isDartUri(uri)) {
      return null;
    }
    JavaFile resolvedFile = _sdk.mapDartUri(uri.toString());
    return new FileBasedSource.con2(factory, resolvedFile, true);
  }
}
/**
 * Instances of the class {@code PackageUriResolver} resolve {@code package} URI's in the context of
 * an application.
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
  Source resolveAbsolute(SourceFactory factory, Uri uri) {
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
    for (JavaFile packagesDirectory in _packagesDirectories) {
      JavaFile resolvedFile = new JavaFile.relative(packagesDirectory, path4);
      if (resolvedFile.exists()) {
        return new FileBasedSource.con1(factory, resolvedFile);
      }
    }
    return new FileBasedSource.con1(factory, new JavaFile.relative(_packagesDirectories[0], path4));
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
    _jtd_constructor_294_impl(directory);
  }
  _jtd_constructor_294_impl(JavaFile directory) {
    _jtd_constructor_295_impl(directory.getPath());
  }
  /**
   * Construct a container representing the specified path and containing any sources whose{@link Source#getFullName()} starts with the specified path.
   * @param path the path (not {@code null} and not empty)
   */
  DirectoryBasedSourceContainer.con2(String path3) {
    _jtd_constructor_295_impl(path3);
  }
  _jtd_constructor_295_impl(String path3) {
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
  Source resolveAbsolute(SourceFactory factory, Uri uri) {
    if (!isFileUri(uri)) {
      return null;
    }
    return new FileBasedSource.con1(factory, new JavaFile.fromUri(uri));
  }
}