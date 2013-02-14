// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.source;

import 'dart:io';
import 'dart:uri';
import 'java_core.dart';
import 'package:analyzer-experimental/src/generated/sdk.dart' show DartSdk;

/**
 * Instances of the class {@code FileUriResolver} resolve {@code file} URI's.
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
    return new FileBasedSource.con1(factory, newFileFromUri(uri));
  }
}
/**
 * Instances of the class {@code DartUriResolver} resolve {@code dart} URI's.
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
    File resolvedFile = _sdk.mapDartUri(uri.toString());
    return new FileBasedSource.con2(factory, resolvedFile, true);
  }
}
/**
 * Instances of the class {@code FileBasedSource} implement a source that represents a file.
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
  File _file;
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
  FileBasedSource.con1(SourceFactory factory, File file) {
    _jtd_constructor_243_impl(factory, file);
  }
  _jtd_constructor_243_impl(SourceFactory factory, File file) {
    _jtd_constructor_244_impl(factory, file, false);
  }
  /**
   * Initialize a newly created source object.
   * @param factory the source factory that created this source
   * @param file the file represented by this source
   * @param inSystemLibrary {@code true} if this source is in one of the system libraries
   */
  FileBasedSource.con2(SourceFactory factory2, File file3, bool inSystemLibrary2) {
    _jtd_constructor_244_impl(factory2, file3, inSystemLibrary2);
  }
  _jtd_constructor_244_impl(SourceFactory factory2, File file3, bool inSystemLibrary2) {
    this._factory = factory2;
    this._file = file3;
    this._inSystemLibrary = inSystemLibrary2;
  }
  bool operator ==(Object object) => object != null && identical(this.runtimeType, object.runtimeType) && _file == ((object as FileBasedSource))._file;
  void getContents(Source_ContentReceiver receiver) {
    receiver.accept2(_file.readAsStringSync());
  }
  String get fullName => _file.fullPathSync();
  String get shortName => _file.name;
  int get hashCode => _file.hashCode;
  bool isInSystemLibrary() => _inSystemLibrary;
  Source resolve(String uri) => _factory.resolveUri(this, uri);
  String toString() {
    if (_file == null) {
      return "<unknown source>";
    }
    return _file.fullPathSync();
  }
  /**
   * Return the file represented by this source. This is an internal method that is only intended to
   * be used by {@link UriResolver}.
   * @return the file represented by this source
   */
  File get file => _file;
}
/**
 * Instances of the class {@link DirectoryBasedSourceContainer} represent a source container that
 * contains all sources within a given directory.
 */
class DirectoryBasedSourceContainer implements SourceContainer {
  /**
   * Append the system file separator to the given path unless the path already ends with a
   * separator.
   * @param path the path to which the file separator is to be added
   * @return a path that ends with the system file separator
   */
  static String appendFileSeparator(String path) {
    if (path == null || path.length <= 0 || path.codeUnitAt(path.length - 1) == System.pathSeparatorChar) {
      return path;
    }
    return "${path}${System.pathSeparator}";
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
  DirectoryBasedSourceContainer.con1(File directory) {
    _jtd_constructor_241_impl(directory);
  }
  _jtd_constructor_241_impl(File directory) {
    _jtd_constructor_242_impl(directory.fullPathSync());
  }
  /**
   * Construct a container representing the specified path and containing any sources whose{@link Source#getFullName()} starts with the specified path.
   * @param path the path (not {@code null} and not empty)
   */
  DirectoryBasedSourceContainer.con2(String path3) {
    _jtd_constructor_242_impl(path3);
  }
  _jtd_constructor_242_impl(String path3) {
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
 * Instances of the class {@code PackageUriResolver} resolve {@code package} URI's in the context of
 * an application.
 */
class PackageUriResolver extends UriResolver {
  /**
   * The package directories that {@code package} URI's are assumed to be relative to.
   */
  List<File> _packagesDirectories;
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
  PackageUriResolver(List<File> packagesDirectories) {
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
    for (File packagesDirectory in _packagesDirectories) {
      File resolvedFile = newRelativeFile(packagesDirectory, path4);
      if (resolvedFile.existsSync()) {
        return new FileBasedSource.con1(factory, resolvedFile);
      }
    }
    return new FileBasedSource.con1(factory, newRelativeFile(_packagesDirectories[0], path4));
  }
}
/**
 * The abstract class {@code UriResolver} defines the behavior of objects that are used to resolve
 * URI's for a source factory. Subclasses of this class are expected to resolve a single scheme of
 * absolute URI.
 */
abstract class UriResolver {
  /**
   * Initialize a newly created resolver.
   */
  UriResolver() : super() {
  }
  /**
   * Working on behalf of the given source factory, resolve the (possibly relative) contained URI
   * against the URI associated with the containing source object. Return a {@link Source source}representing the file to which it was resolved, or {@code null} if it could not be resolved.
   * @param factory the source factory requesting the resolution of the URI
   * @param containingSource the source containing the given URI
   * @param containedUri the (possibly relative) URI to be resolved against the containing source
   * @return a {@link Source source} representing the URI to which given URI was resolved
   */
  Source resolve(SourceFactory factory, Source containingSource, Uri containedUri) {
    if (containedUri.isAbsolute()) {
      return resolveAbsolute(factory, containedUri);
    } else {
      return resolveRelative(factory, containingSource, containedUri);
    }
  }
  /**
   * Resolve the given absolute URI. Return a {@link Source source} representing the file to which
   * it was resolved, or {@code null} if it could not be resolved.
   * @param uri the URI to be resolved
   * @return a {@link Source source} representing the URI to which given URI was resolved
   */
  Source resolveAbsolute(SourceFactory factory, Uri uri);
  /**
   * Resolve the relative (contained) URI against the URI associated with the containing source
   * object. Return a {@link Source source} representing the file to which it was resolved, or{@code null} if it could not be resolved.
   * @param containingSource the source containing the given URI
   * @param containedUri the (possibly relative) URI to be resolved against the containing source
   * @return a {@link Source source} representing the URI to which given URI was resolved
   */
  Source resolveRelative(SourceFactory factory, Source containingSource, Uri containedUri) {
    if (containingSource is FileBasedSource) {
      try {
        Uri resolvedUri = newUriFromFile(((containingSource as FileBasedSource)).file).resolveUri(containedUri);
        return new FileBasedSource.con1(factory, newFileFromUri(resolvedUri));
      } on JavaException catch (exception) {
      }
    }
    return null;
  }
}
/**
 * Instances of the class {@code SourceFactory} resolve possibly relative URI's against an existing{@link Source source}.
 */
class SourceFactory {
  /**
   * The resolvers used to resolve absolute URI's.
   */
  List<UriResolver> _resolvers;
  /**
   * A cache of content used to override the default content of a source.
   */
  ContentCache _contentCache;
  /**
   * Initialize a newly created source factory.
   * @param contentCache the cache holding content used to override the default content of a source.
   * @param resolvers the resolvers used to resolve absolute URI's
   */
  SourceFactory.con1(ContentCache contentCache2, List<UriResolver> resolvers2) {
    _jtd_constructor_247_impl(contentCache2, resolvers2);
  }
  _jtd_constructor_247_impl(ContentCache contentCache2, List<UriResolver> resolvers2) {
    this._contentCache = contentCache2;
    this._resolvers = resolvers2;
  }
  /**
   * Initialize a newly created source factory.
   * @param resolvers the resolvers used to resolve absolute URI's
   */
  SourceFactory.con2(List<UriResolver> resolvers) {
    _jtd_constructor_248_impl(resolvers);
  }
  _jtd_constructor_248_impl(List<UriResolver> resolvers) {
    _jtd_constructor_247_impl(new ContentCache(), [resolvers]);
  }
  /**
   * Return a source container representing the given directory
   * @param directory the directory (not {@code null})
   * @return the source container representing the directory (not {@code null})
   */
  SourceContainer forDirectory(File directory) => new DirectoryBasedSourceContainer.con1(directory);
  /**
   * Return a source object representing the given file.
   * @param file the file to be represented by the returned source object
   * @return a source object representing the given file
   */
  Source forFile(File file) => new FileBasedSource.con1(this, file);
  /**
   * Return a source object representing the given absolute URI, or {@code null} if the URI is not a
   * valid URI or if it is not an absolute URI.
   * @param absoluteUri the absolute URI to be resolved
   * @return a source object representing the absolute URI
   */
  Source forUri(String absoluteUri) {
    try {
      Uri uri = new Uri.fromComponents(path: absoluteUri);
      if (uri.isAbsolute()) {
        return resolveUri2(null, uri);
      }
    } on URISyntaxException catch (exception) {
    }
    return null;
  }
  /**
   * Return a source object representing the URI that results from resolving the given (possibly
   * relative) contained URI against the URI associated with an existing source object, or{@code null} if either the contained URI is invalid or if it cannot be resolved against the
   * source object's URI.
   * @param containingSource the source containing the given URI
   * @param containedUri the (possibly relative) URI to be resolved against the containing source
   * @return the source representing the contained URI
   */
  Source resolveUri(Source containingSource, String containedUri) {
    try {
      return resolveUri2(containingSource, new Uri.fromComponents(path: containedUri));
    } on URISyntaxException catch (exception) {
      return null;
    }
  }
  /**
   * Set the contents of the given source to the given contents. This has the effect of overriding
   * the default contents of the source. If the contents are {@code null} the override is removed so
   * that the default contents will be returned.
   * @param source the source whose contents are being overridden
   * @param contents the new contents of the source
   */
  void setContents(Source source, String contents) {
    _contentCache.setContents(source, contents);
  }
  /**
   * Return the contents of the given source, or {@code null} if this factory does not override the
   * contents of the source.
   * <p>
   * <b>Note:</b> This method is not intended to be used except by{@link FileBasedSource#getContents(com.google.dart.engine.source.Source.ContentReceiver)}.
   * @param source the source whose content is to be returned
   * @return the contents of the given source
   */
  String getContents(Source source) => _contentCache.getContents(source);
  /**
   * Return a source object representing the URI that results from resolving the given (possibly
   * relative) contained URI against the URI associated with an existing source object, or{@code null} if either the contained URI is invalid or if it cannot be resolved against the
   * source object's URI.
   * @param containingSource the source containing the given URI
   * @param containedUri the (possibly relative) URI to be resolved against the containing source
   * @return the source representing the contained URI
   */
  Source resolveUri2(Source containingSource, Uri containedUri) {
    for (UriResolver resolver in _resolvers) {
      Source result = resolver.resolve(this, containingSource, containedUri);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
/**
 * The interface {@code Source} defines the behavior of objects representing source code that can be
 * compiled.
 */
abstract class Source {
  /**
   * Return {@code true} if the given object is a source that represents the same source code as
   * this source.
   * @param object the object to be compared with this object
   * @return {@code true} if the given object is a source that represents the same source code as
   * this source
   * @see Object#equals(Object)
   */
  bool operator ==(Object object);
  /**
   * Get the contents of this source and pass it to the given receiver. Exactly one of the methods
   * defined on the receiver will be invoked unless an exception is thrown. The method that will be
   * invoked depends on which of the possible representations of the contents is the most efficient.
   * Whichever method is invoked, it will be invoked before this method returns.
   * @param receiver the content receiver to which the content of this source will be passed
   * @throws Exception if the contents of this source could not be accessed
   */
  void getContents(Source_ContentReceiver receiver);
  /**
   * Return the full (long) version of the name that can be displayed to the user to denote this
   * source. For example, for a source representing a file this would typically be the absolute path
   * of the file.
   * @return a name that can be displayed to the user to denote this source
   */
  String get fullName;
  /**
   * Return a short version of the name that can be displayed to the user to denote this source. For
   * example, for a source representing a file this would typically be the name of the file.
   * @return a name that can be displayed to the user to denote this source
   */
  String get shortName;
  /**
   * Return a hash code for this source.
   * @return a hash code for this source
   * @see Object#hashCode()
   */
  int get hashCode;
  /**
   * Return {@code true} if this source is in one of the system libraries.
   * @return {@code true} if this is in a system library
   */
  bool isInSystemLibrary();
  /**
   * Resolve the given URI relative to the location of this source.
   * @param uri the URI to be resolved against this source
   * @return a source representing the resolved URI
   */
  Source resolve(String uri);
}
/**
 * The interface {@code ContentReceiver} defines the behavior of objects that can receive the
 * content of a source.
 */
abstract class Source_ContentReceiver {
  /**
   * Accept the contents of a source represented as a character buffer.
   * @param contents the contents of the source
   */
  accept(CharBuffer contents);
  /**
   * Accept the contents of a source represented as a string.
   * @param contents the contents of the source
   */
  void accept2(String contents);
}
/**
 * Instances of class {@code ContentCache} hold content used to override the default content of a{@link Source}.
 */
class ContentCache {
  /**
   * A table mapping sources to the contents of those sources. This is used to override the default
   * contents of a source.
   */
  Map<Source, String> _contentMap = new Map<Source, String>();
  /**
   * Return the contents of the given source, or {@code null} if this cache does not override the
   * contents of the source.
   * <p>
   * <b>Note:</b> This method is not intended to be used except by{@link SourceFactory#getContents(com.google.dart.engine.source.Source.ContentReceiver)}.
   * @param source the source whose content is to be returned
   * @return the contents of the given source
   */
  String getContents(Source source) => _contentMap[source];
  /**
   * Set the contents of the given source to the given contents. This has the effect of overriding
   * the default contents of the source. If the contents are {@code null} the override is removed so
   * that the default contents will be returned.
   * @param source the source whose contents are being overridden
   * @param contents the new contents of the source
   */
  void setContents(Source source, String contents) {
    if (contents == null) {
      _contentMap.remove(source);
    } else {
      _contentMap[source] = contents;
    }
  }
}
/**
 * The interface {@code SourceContainer} is used by clients to define a collection of sources
 * <p>
 * Source containers are not used within analysis engine, but can be used by clients to group
 * sources for the purposes of accessing composite dependency information. For example, the Eclipse
 * client uses source containers to represent Eclipse projects, which allows it to easily compute
 * project-level dependencies.
 */
abstract class SourceContainer {
  /**
   * Determine if the specified source is part of the receiver's collection of sources.
   * @param source the source in question
   * @return {@code true} if the receiver contains the source, else {@code false}
   */
  bool contains(Source source);
}
/**
 * Instances of the class {@code LineInfo} encapsulate information about line and column information
 * within a source file.
 */
class LineInfo {
  /**
   * An array containing the offsets of the first character of each line in the source code.
   */
  List<int> _lineStarts;
  /**
   * Initialize a newly created set of line information to represent the data encoded in the given
   * array.
   * @param lineStarts the offsets of the first character of each line in the source code
   */
  LineInfo(List<int> lineStarts) {
    if (lineStarts == null) {
      throw new IllegalArgumentException("lineStarts must be non-null");
    } else if (lineStarts.length < 1) {
      throw new IllegalArgumentException("lineStarts must be non-empty");
    }
    this._lineStarts = lineStarts;
  }
  /**
   * Return the location information for the character at the given offset.
   * @param offset the offset of the character for which location information is to be returned
   * @return the location information for the character at the given offset
   */
  LineInfo_Location getLocation(int offset) {
    int lineCount = _lineStarts.length;
    for (int i = 1; i < lineCount; i++) {
      if (offset < _lineStarts[i]) {
        return new LineInfo_Location(i, offset - _lineStarts[i - 1] + 1);
      }
    }
    return new LineInfo_Location(lineCount, offset - _lineStarts[lineCount - 1] + 1);
  }
}
/**
 * Instances of the class {@code Location} represent the location of a character as a line and
 * column pair.
 */
class LineInfo_Location {
  /**
   * The one-based index of the line containing the character.
   */
  int _lineNumber = 0;
  /**
   * The one-based index of the column containing the character.
   */
  int _columnNumber = 0;
  /**
   * Initialize a newly created location to represent the location of the character at the given
   * line and column position.
   * @param lineNumber the one-based index of the line containing the character
   * @param columnNumber the one-based index of the column containing the character
   */
  LineInfo_Location(int lineNumber, int columnNumber) {
    this._lineNumber = lineNumber;
    this._columnNumber = columnNumber;
  }
  /**
   * Return the one-based index of the column containing the character.
   * @return the one-based index of the column containing the character
   */
  int get columnNumber => _columnNumber;
  /**
   * Return the one-based index of the line containing the character.
   * @return the one-based index of the line containing the character
   */
  int get lineNumber => _lineNumber;
}
/**
 * The enumeration {@code SourceKind} defines the different kinds of sources that are known to the
 * analysis engine.
 */
class SourceKind {
  /**
   * A source containing HTML. The HTML might or might not contain Dart scripts.
   */
  static final SourceKind HTML = new SourceKind('HTML', 0);
  /**
   * A Dart compilation unit that is not a part of another library. Libraries might or might not
   * contain any directives, including a library directive.
   */
  static final SourceKind LIBRARY = new SourceKind('LIBRARY', 1);
  /**
   * A Dart compilation unit that is part of another library. Parts contain a part-of directive.
   */
  static final SourceKind PART = new SourceKind('PART', 2);
  /**
   * An unknown kind of source. Used both when it is not possible to identify the kind of a source
   * and also when the kind of a source is not known without performing a computation and the client
   * does not want to spend the time to identify the kind.
   */
  static final SourceKind UNKNOWN = new SourceKind('UNKNOWN', 3);
  static final List<SourceKind> values = [HTML, LIBRARY, PART, UNKNOWN];
  final String __name;
  final int __ordinal;
  SourceKind(this.__name, this.__ordinal) {
  }
  String toString() => __name;
}