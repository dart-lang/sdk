// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.source.io;

import 'source.dart';
import 'java_core.dart';
import 'java_io.dart';
import 'engine.dart' show AnalysisContext, AnalysisEngine;
export 'source.dart';

/**
 * Instances of interface `LocalSourcePredicate` are used to determine if the given
 * [Source] is "local" in some sense, so can be updated.
 *
 * @coverage dart.engine.source
 */
abstract class LocalSourcePredicate {
  /**
   * Instance of [LocalSourcePredicate] that always returns `false`.
   */
  static final LocalSourcePredicate FALSE = new LocalSourcePredicate_15();

  /**
   * Instance of [LocalSourcePredicate] that always returns `true`.
   */
  static final LocalSourcePredicate TRUE = new LocalSourcePredicate_16();

  /**
   * Instance of [LocalSourcePredicate] that returns `true` for all [Source]s
   * except of SDK.
   */
  static final LocalSourcePredicate NOT_SDK = new LocalSourcePredicate_17();

  /**
   * Determines if the given [Source] is local.
   *
   * @param source the [Source] to analyze
   * @return `true` if the given [Source] is local
   */
  bool isLocal(Source source);
}

class LocalSourcePredicate_15 implements LocalSourcePredicate {
  bool isLocal(Source source) => false;
}

class LocalSourcePredicate_16 implements LocalSourcePredicate {
  bool isLocal(Source source) => true;
}

class LocalSourcePredicate_17 implements LocalSourcePredicate {
  bool isLocal(Source source) => source.uriKind != UriKind.DART_URI;
}

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
  JavaFile file;

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
    this.file = file;
    this._uriKind = uriKind;
  }

  bool operator ==(Object object) => object != null && this.runtimeType == object.runtimeType && file == (object as FileBasedSource).file;

  bool exists() => _contentCache.getContents(this) != null || (file.exists() && !file.isDirectory());

  void getContents(Source_ContentReceiver receiver) {
    String contents = _contentCache.getContents(this);
    if (contents != null) {
      receiver.accept2(contents, _contentCache.getModificationStamp(this));
      return;
    }
    getContentsFromFile(receiver);
  }

  String get encoding {
    if (_encoding == null) {
      _encoding = "${_uriKind.encoding}${file.toURI().toString()}";
    }
    return _encoding;
  }

  String get fullName => file.getAbsolutePath();

  int get modificationStamp {
    int stamp = _contentCache.getModificationStamp(this);
    if (stamp != null) {
      return stamp;
    }
    return file.lastModified();
  }

  String get shortName => file.getName();

  UriKind get uriKind => _uriKind;

  int get hashCode => file.hashCode;

  bool get isInSystemLibrary => identical(_uriKind, UriKind.DART_URI);

  Source resolveRelative(Uri containedUri) {
    try {
      Uri resolvedUri = file.toURI().resolveUri(containedUri);
      return new FileBasedSource.con2(_contentCache, new JavaFile.fromUri(resolvedUri), _uriKind);
    } on JavaException catch (exception) {
    }
    return null;
  }

  String toString() {
    if (file == null) {
      return "<unknown source>";
    }
    return file.getAbsolutePath();
  }

  /**
   * Get the contents of underlying file and pass it to the given receiver. Exactly one of the
   * methods defined on the receiver will be invoked unless an exception is thrown. The method that
   * will be invoked depends on which of the possible representations of the contents is the most
   * efficient. Whichever method is invoked, it will be invoked before this method returns.
   *
   * @param receiver the content receiver to which the content of this source will be passed
   * @throws Exception if the contents of this source could not be accessed
   * @see #getContents(com.google.dart.engine.source.Source.ContentReceiver)
   */
  void getContentsFromFile(Source_ContentReceiver receiver) {
    {
    }
    receiver.accept2(file.readAsStringSync(), file.lastModified());
  }
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
    if (identical(kind, UriKind.PACKAGE_SELF_URI) || identical(kind, UriKind.PACKAGE_URI)) {
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
        JavaFile canonicalFile = getCanonicalFile(packagesDirectory, pkgName, relPath);
        UriKind uriKind = isSelfReference(packagesDirectory, canonicalFile) ? UriKind.PACKAGE_SELF_URI : UriKind.PACKAGE_URI;
        return new FileBasedSource.con2(contentCache, canonicalFile, uriKind);
      }
    }
    return new FileBasedSource.con2(contentCache, getCanonicalFile(_packagesDirectories[0], pkgName, relPath), UriKind.PACKAGE_URI);
  }

  Uri restoreAbsolute(Source source) {
    if (source is FileBasedSource) {
      String sourcePath = (source as FileBasedSource).file.getPath();
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
            } on JavaException catch (e) {
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
    } on JavaIOException catch (e) {
      if (!e.toString().contains("Required key not available")) {
        AnalysisEngine.instance.logger.logError2("Canonical failed: ${pkgDir}", e);
      } else if (_CanLogRequiredKeyIoException) {
        _CanLogRequiredKeyIoException = false;
        AnalysisEngine.instance.logger.logError2("Canonical failed: ${pkgDir}", e);
      }
    }
    return new JavaFile.relative(pkgDir, relPath.replaceAll('/', new String.fromCharCode(JavaFile.separatorChar)));
  }

  /**
   * @return `true` if "file" was found in "packagesDir", and it is part of the "lib" folder
   *         of the application that contains in this "packagesDir".
   */
  bool isSelfReference(JavaFile packagesDir, JavaFile file) {
    JavaFile rootDir = packagesDir.getParentFile();
    if (rootDir == null) {
      return false;
    }
    String rootPath = rootDir.getAbsolutePath();
    String filePath = file.getAbsolutePath();
    return filePath.startsWith("${rootPath}/lib");
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
  String path;

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
    this.path = appendFileSeparator(path);
  }

  bool contains(Source source) => source.fullName.startsWith(path);

  bool operator ==(Object obj) => (obj is DirectoryBasedSourceContainer) && (obj as DirectoryBasedSourceContainer).path == path;

  int get hashCode => path.hashCode;

  String toString() => "SourceContainer[${path}]";
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