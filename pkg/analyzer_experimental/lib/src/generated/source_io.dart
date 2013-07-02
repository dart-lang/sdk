// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine.source.io;
import 'source.dart';
import 'dart:io';
import 'java_core.dart';
import 'java_io.dart';
import 'sdk.dart' show DartSdk;
import 'engine.dart' show AnalysisContext, AnalysisEngine;
export 'source.dart';
/**
 * Instances of the class `FileBasedSource` implement a source that represents a file.
 *
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
   * The cached encoding for this source.
   */
  String _encoding;

  /**
   * The kind of URI from which this source was originally derived.
   */
  UriKind _uriKind;

  /**
   * Initialize a newly created source object. The source object is assumed to not be in a system
   * library.
   *
   * @param contentCache the content cache used to access the contents of this source
   * @param file the file represented by this source
   */
  FileBasedSource.con1(ContentCache contentCache, JavaFile file) : this.con2(contentCache, file, UriKind.FILE_URI);

  /**
   * Initialize a newly created source object.
   *
   * @param contentCache the content cache used to access the contents of this source
   * @param file the file represented by this source
   * @param flags `true` if this source is in one of the system libraries
   */
  FileBasedSource.con2(ContentCache contentCache, JavaFile file, UriKind uriKind) {
    this._contentCache = contentCache;
    this._file = file;
    this._uriKind = uriKind;
    this._encoding = "${uriKind.encoding}${file.toURI().toString()}";
  }
  bool operator ==(Object object) => object != null && this.runtimeType == object.runtimeType && _file == ((object as FileBasedSource))._file;
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
  String get encoding => _encoding;
  String get fullName => _file.getAbsolutePath();
  int get modificationStamp {
    int stamp = _contentCache.getModificationStamp(this);
    if (stamp != null) {
      return stamp;
    }
    return _file.lastModified();
  }
  String get shortName => _file.getName();
  UriKind get uriKind => _uriKind;
  int get hashCode => _file.hashCode;
  bool get isInSystemLibrary => identical(_uriKind, UriKind.DART_URI);
  Source resolveRelative(Uri containedUri) {
    try {
      Uri resolvedUri = file.toURI().resolveUri(containedUri);
      return new FileBasedSource.con2(_contentCache, new JavaFile.fromUri(resolvedUri), _uriKind);
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
   * be used by [UriResolver].
   *
   * @return the file represented by this source
   */
  JavaFile get file => _file;
}
/**
 * Instances of the class `PackageUriResolver` resolve `package` URI's in the context of
 * an application.
 *
 * For the purposes of sharing analysis, the path to each package under the "packages" directory
 * should be canonicalized, but to preserve relative links within a package, the remainder of the
 * path from the package directory to the leaf should not.
 *
 * @coverage dart.engine.source
 */
class PackageUriResolver extends UriResolver {

  /**
   * The package directories that `package` URI's are assumed to be relative to.
   */
  List<JavaFile> _packagesDirectories;

  /**
   * The name of the `package` scheme.
   */
  static String PACKAGE_SCHEME = "package";

  /**
   * Log exceptions thrown with the message "Required key not available" only once.
   */
  static bool _CanLogRequiredKeyIoException = true;

  /**
   * Return `true` if the given URI is a `package` URI.
   *
   * @param uri the URI being tested
   * @return `true` if the given URI is a `package` URI
   */
  static bool isPackageUri(Uri uri) => PACKAGE_SCHEME == uri.scheme;

  /**
   * Initialize a newly created resolver to resolve `package` URI's relative to the given
   * package directories.
   *
   * @param packagesDirectories the package directories that `package` URI's are assumed to be
   *          relative to
   */
  PackageUriResolver(List<JavaFile> packagesDirectories) {
    if (packagesDirectories.length < 1) {
      throw new IllegalArgumentException("At least one package directory must be provided");
    }
    this._packagesDirectories = packagesDirectories;
  }
  Source fromEncoding(ContentCache contentCache, UriKind kind, Uri uri) {
    if (identical(kind, UriKind.PACKAGE_URI)) {
      return new FileBasedSource.con2(contentCache, new JavaFile.fromUri(uri), kind);
    }
    return null;
  }
  Source resolveAbsolute(ContentCache contentCache, Uri uri) {
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
      pkgName = path;
      relPath = "";
    } else if (index == 0) {
      return null;
    } else {
      pkgName = path.substring(0, index);
      relPath = path.substring(index + 1);
    }
    for (JavaFile packagesDirectory in _packagesDirectories) {
      JavaFile resolvedFile = new JavaFile.relative(packagesDirectory, path);
      if (resolvedFile.exists()) {
        return new FileBasedSource.con2(contentCache, getCanonicalFile(packagesDirectory, pkgName, relPath), UriKind.PACKAGE_URI);
      }
    }
    return new FileBasedSource.con2(contentCache, getCanonicalFile(_packagesDirectories[0], pkgName, relPath), UriKind.PACKAGE_URI);
  }
  Uri restoreAbsolute(Source source) {
    if (source is FileBasedSource) {
      String sourcePath = ((source as FileBasedSource)).file.getPath();
      for (JavaFile packagesDirectory in _packagesDirectories) {
        List<JavaFile> pkgFolders = packagesDirectory.listFiles();
        if (pkgFolders != null) {
          for (JavaFile pkgFolder in pkgFolders) {
            try {
              String pkgCanonicalPath = pkgFolder.getCanonicalPath();
              if (sourcePath.startsWith(pkgCanonicalPath)) {
                String relPath = sourcePath.substring(pkgCanonicalPath.length);
                return parseUriWithException("${PACKAGE_SCHEME}:${pkgFolder.getName()}${relPath}");
              }
            } catch (e) {
            }
          }
        }
      }
    }
    return null;
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
  JavaFile getCanonicalFile(JavaFile packagesDirectory, String pkgName, String relPath) {
    JavaFile pkgDir = new JavaFile.relative(packagesDirectory, pkgName);
    try {
      pkgDir = pkgDir.getCanonicalFile();
    } on IOException catch (e) {
      if (!e.toString().contains("Required key not available")) {
        AnalysisEngine.instance.logger.logError2("Canonical failed: ${pkgDir}", e);
      } else if (_CanLogRequiredKeyIoException) {
        _CanLogRequiredKeyIoException = false;
        AnalysisEngine.instance.logger.logError2("Canonical failed: ${pkgDir}", e);
      }
    }
    return new JavaFile.relative(pkgDir, relPath.replaceAll('/', new String.fromCharCode(JavaFile.separatorChar)));
  }
}
/**
 * Instances of the class [DirectoryBasedSourceContainer] represent a source container that
 * contains all sources within a given directory.
 *
 * @coverage dart.engine.source
 */
class DirectoryBasedSourceContainer implements SourceContainer {

  /**
   * Append the system file separator to the given path unless the path already ends with a
   * separator.
   *
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
   * The container's path (not `null`).
   */
  String _path;

  /**
   * Construct a container representing the specified directory and containing any sources whose
   * [Source#getFullName] starts with the directory's path. This is a convenience method,
   * fully equivalent to [DirectoryBasedSourceContainer#DirectoryBasedSourceContainer]
   * .
   *
   * @param directory the directory (not `null`)
   */
  DirectoryBasedSourceContainer.con1(JavaFile directory) : this.con2(directory.getPath());

  /**
   * Construct a container representing the specified path and containing any sources whose
   * [Source#getFullName] starts with the specified path.
   *
   * @param path the path (not `null` and not empty)
   */
  DirectoryBasedSourceContainer.con2(String path) {
    this._path = appendFileSeparator(path);
  }
  bool contains(Source source) => source.fullName.startsWith(_path);
  bool operator ==(Object obj) => (obj is DirectoryBasedSourceContainer) && ((obj as DirectoryBasedSourceContainer)).path == path;

  /**
   * Answer the receiver's path, used to determine if a source is contained in the receiver.
   *
   * @return the path (not `null`, not empty)
   */
  String get path => _path;
  int get hashCode => _path.hashCode;
  String toString() => "SourceContainer[${_path}]";
}
/**
 * Instances of the class `FileUriResolver` resolve `file` URI's.
 *
 * @coverage dart.engine.source
 */
class FileUriResolver extends UriResolver {

  /**
   * The name of the `file` scheme.
   */
  static String FILE_SCHEME = "file";

  /**
   * Return `true` if the given URI is a `file` URI.
   *
   * @param uri the URI being tested
   * @return `true` if the given URI is a `file` URI
   */
  static bool isFileUri(Uri uri) => uri.scheme == FILE_SCHEME;
  Source fromEncoding(ContentCache contentCache, UriKind kind, Uri uri) {
    if (identical(kind, UriKind.FILE_URI)) {
      return new FileBasedSource.con2(contentCache, new JavaFile.fromUri(uri), kind);
    }
    return null;
  }
  Source resolveAbsolute(ContentCache contentCache, Uri uri) {
    if (!isFileUri(uri)) {
      return null;
    }
    return new FileBasedSource.con1(contentCache, new JavaFile.fromUri(uri));
  }
}