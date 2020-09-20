// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/task/api/model.dart';
import 'package:path/path.dart' as pathos;

export 'package:analyzer/source/line_info.dart' show LineInfo;
export 'package:analyzer/source/source_range.dart';

/// A function that is used to visit [ContentCache] entries.
typedef ContentCacheVisitor = void Function(
    String fullPath, int stamp, String contents);

/// Base class providing implementations for the methods in [Source] that don't
/// require filesystem access.
abstract class BasicSource extends Source {
  @override
  final Uri uri;

  BasicSource(this.uri);

  @override
  String get encoding => uri.toString();

  @override
  String get fullName => '$uri';

  @override
  int get hashCode => uri.hashCode;

  @override
  bool get isInSystemLibrary => uri.scheme == 'dart';

  @override
  String get shortName => pathos.basename(fullName);

  @override
  bool operator ==(Object object) => object is Source && object.uri == uri;
}

/// A cache used to override the default content of a [Source].
///
/// TODO(scheglov) Remove it.
class ContentCache {
  /// A table mapping the full path of sources to the contents of those sources.
  /// This is used to override the default contents of a source.
  final Map<String, String> _contentMap = {};

  /// A table mapping the full path of sources to the modification stamps of
  /// those sources. This is used when the default contents of a source has been
  /// overridden.
  final Map<String, int> _stampMap = {};

  int _nextStamp = 0;

  /// Visit all entries of this cache.
  void accept(ContentCacheVisitor visitor) {
    _contentMap.forEach((String fullPath, String contents) {
      int stamp = _stampMap[fullPath];
      visitor(fullPath, stamp, contents);
    });
  }

  /// Return the contents of the given [source], or `null` if this cache does not
  /// override the contents of the source.
  ///
  /// <b>Note:</b> This method is not intended to be used except by
  /// [AnalysisContext.getContents].
  String getContents(Source source) => _contentMap[source.fullName];

  /// Return `true` if the given [source] exists, `false` if it does not exist,
  /// or `null` if this cache does not override existence of the source.
  ///
  /// <b>Note:</b> This method is not intended to be used except by
  /// [AnalysisContext.exists].
  bool getExists(Source source) {
    return _contentMap.containsKey(source.fullName) ? true : null;
  }

  /// Return the modification stamp of the given [source], or `null` if this
  /// cache does not override the contents of the source.
  ///
  /// <b>Note:</b> This method is not intended to be used except by
  /// [AnalysisContext.getModificationStamp].
  int getModificationStamp(Source source) => _stampMap[source.fullName];

  /// Set the contents of the given [source] to the given [contents]. This has
  /// the effect of overriding the default contents of the source. If the
  /// contents are `null` the override is removed so that the default contents
  /// will be returned.
  String setContents(Source source, String contents) {
    String fullName = source.fullName;
    if (contents == null) {
      _stampMap.remove(fullName);
      return _contentMap.remove(fullName);
    } else {
      int newStamp = _nextStamp++;
      int oldStamp = _stampMap[fullName];
      _stampMap[fullName] = newStamp;
      // Occasionally, if this method is called in rapid succession, the
      // timestamps are equal. Guard against this by artificially incrementing
      // the new timestamp.
      if (newStamp == oldStamp) {
        _stampMap[fullName] = newStamp + 1;
      }
      String oldContent = _contentMap[fullName];
      _contentMap[fullName] = contents;
      return oldContent;
    }
  }
}

/// Instances of the class `DartUriResolver` resolve `dart` URI's.
class DartUriResolver extends UriResolver {
  /// The name of the `dart` scheme.
  static String DART_SCHEME = "dart";

  /// The prefix of a URI using the dart-ext scheme to reference a native code
  /// library.
  static const String _DART_EXT_SCHEME = "dart-ext:";

  /// The Dart SDK against which URI's are to be resolved.
  final DartSdk _sdk;

  /// Initialize a newly created resolver to resolve Dart URI's against the
  /// given platform within the given Dart SDK.
  DartUriResolver(this._sdk);

  /// Return the [DartSdk] against which URIs are to be resolved.
  ///
  /// @return the [DartSdk] against which URIs are to be resolved.
  DartSdk get dartSdk => _sdk;

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!isDartUri(uri)) {
      return null;
    }
    return _sdk.mapDartUri(uri.toString());
  }

  @override
  Uri restoreAbsolute(Source source) {
    Source dartSource = _sdk.fromFileUri(source.uri);
    return dartSource?.uri;
  }

  /// Return `true` if the given URI is a `dart-ext:` URI.
  ///
  /// @param uriContent the textual representation of the URI being tested
  /// @return `true` if the given URI is a `dart-ext:` URI
  static bool isDartExtUri(String uriContent) =>
      uriContent != null && uriContent.startsWith(_DART_EXT_SCHEME);

  /// Return `true` if the given URI is a `dart:` URI.
  ///
  /// @param uri the URI being tested
  /// @return `true` if the given URI is a `dart:` URI
  static bool isDartUri(Uri uri) => DART_SCHEME == uri.scheme;
}

/// Instances of the class `Location` represent the location of a character as a
/// line and column pair.
@deprecated
class LineInfo_Location {
  /// The one-based index of the line containing the character.
  final int lineNumber;

  /// The one-based index of the column containing the character.
  final int columnNumber;

  /// Initialize a newly created location to represent the location of the
  /// character at the given [lineNumber] and [columnNumber].
  LineInfo_Location(this.lineNumber, this.columnNumber);

  @override
  String toString() => '$lineNumber:$columnNumber';
}

/// An implementation of an non-existing [Source].
class NonExistingSource extends Source {
  static final unknown = NonExistingSource(
      '/unknown.dart', pathos.toUri('/unknown.dart'), UriKind.FILE_URI);

  @override
  final String fullName;

  @override
  final Uri uri;

  @override
  final UriKind uriKind;

  NonExistingSource(this.fullName, this.uri, this.uriKind);

  @override
  TimestampedData<String> get contents {
    throw UnsupportedError('$fullName does not exist.');
  }

  @override
  String get encoding => uri.toString();

  @override
  int get hashCode => fullName.hashCode;

  @override
  bool get isInSystemLibrary => false;

  @override
  int get modificationStamp => -1;

  @override
  String get shortName => pathos.basename(fullName);

  @override
  bool operator ==(Object other) {
    if (other is NonExistingSource) {
      return other.uriKind == uriKind && other.fullName == fullName;
    }
    return false;
  }

  @override
  bool exists() => false;

  @override
  String toString() => 'NonExistingSource($uri, $fullName)';
}

/// The interface `Source` defines the behavior of objects representing source
/// code that can be analyzed by the analysis engine.
///
/// Implementations of this interface need to be aware of some assumptions made
/// by the analysis engine concerning sources:
///
/// * Sources are not required to be unique. That is, there can be multiple
/// instances representing the same source.
/// * Sources are long lived. That is, the engine is allowed to hold on to a
/// source for an extended period of time and that source must continue to
/// report accurate and up-to-date information.
///
/// Because of these assumptions, most implementations will not maintain any
/// state but will delegate to an authoritative system of record in order to
/// implement this API. For example, a source that represents files on disk
/// would typically query the file system to determine the state of the file.
///
/// If the instances that implement this API are the system of record, then they
/// will typically be unique. In that case, sources that are created that
/// represent non-existent files must also be retained so that if those files
/// are created at a later date the long-lived sources representing those files
/// will know that they now exist.
abstract class Source implements AnalysisTarget {
  /// Get the contents and timestamp of this source.
  ///
  /// Clients should consider using the method [AnalysisContext.getContents]
  /// because contexts can have local overrides of the content of a source that
  /// the source is not aware of.
  ///
  /// @return the contents and timestamp of the source
  /// @throws Exception if the contents of this source could not be accessed
  TimestampedData<String> get contents;

  /// Return an encoded representation of this source that can be used to create
  /// a source that is equal to this source.
  ///
  /// @return an encoded representation of this source
  /// See [SourceFactory.fromEncoding].
  @deprecated
  String get encoding;

  /// Return the full (long) version of the name that can be displayed to the
  /// user to denote this source. For example, for a source representing a file
  /// this would typically be the absolute path of the file.
  ///
  /// @return a name that can be displayed to the user to denote this source
  String get fullName;

  /// Return a hash code for this source.
  ///
  /// @return a hash code for this source
  /// See [Object.hashCode].
  @override
  int get hashCode;

  /// Return `true` if this source is in one of the system libraries.
  ///
  /// @return `true` if this is in a system library
  bool get isInSystemLibrary;

  @override
  Source get librarySource => null;

  /// Return the modification stamp for this source, or a negative value if the
  /// source does not exist. A modification stamp is a non-negative integer with
  /// the property that if the contents of the source have not been modified
  /// since the last time the modification stamp was accessed then the same
  /// value will be returned, but if the contents of the source have been
  /// modified one or more times (even if the net change is zero) the stamps
  /// will be different.
  ///
  /// Clients should consider using the method
  /// [AnalysisContext.getModificationStamp] because contexts can have local
  /// overrides of the content of a source that the source is not aware of.
  int get modificationStamp;

  /// Return a short version of the name that can be displayed to the user to
  /// denote this source. For example, for a source representing a file this
  /// would typically be the name of the file.
  ///
  /// @return a name that can be displayed to the user to denote this source
  String get shortName;

  @override
  Source get source => this;

  /// Return the URI from which this source was originally derived.
  ///
  /// @return the URI from which this source was originally derived
  Uri get uri;

  /// Return the kind of URI from which this source was originally derived. If
  /// this source was created from an absolute URI, then the returned kind will
  /// reflect the scheme of the absolute URI. If it was created from a relative
  /// URI, then the returned kind will be the same as the kind of the source
  /// against which the relative URI was resolved.
  ///
  /// @return the kind of URI from which this source was originally derived
  UriKind get uriKind;

  /// Return `true` if the given object is a source that represents the same
  /// source code as this source.
  ///
  /// @param object the object to be compared with this object
  /// @return `true` if the given object is a source that represents the same
  ///         source code as this source
  /// See [Object.==].
  @override
  bool operator ==(Object object);

  /// Return `true` if this source exists.
  ///
  /// Clients should consider using the method [AnalysisContext.exists] because
  /// contexts can have local overrides of the content of a source that the
  /// source is not aware of and a source with local content is considered to
  /// exist even if there is no file on disk.
  ///
  /// @return `true` if this source exists
  bool exists();
}

/// Instances of the class `SourceFactory` resolve possibly relative URI's
/// against an existing [Source].
abstract class SourceFactory {
  /// Initialize a newly created source factory with the given absolute URI
  /// [resolvers].
  factory SourceFactory(List<UriResolver> resolvers) = SourceFactoryImpl;

  /// Return the [DartSdk] associated with this [SourceFactory], or `null` if
  /// there is no such SDK.
  ///
  /// @return the [DartSdk] associated with this [SourceFactory], or `null` if
  ///         there is no such SDK
  DartSdk get dartSdk;

  /// A table mapping package names to paths of directories containing
  /// the package (or [null] if there is no registered package URI resolver).
  Map<String, List<Folder>> get packageMap;

  /// Clear any cached URI resolution information in the [SourceFactory] itself,
  /// and also ask each [UriResolver]s to clear its caches.
  void clearCache();

  /// Return a source object representing the given absolute URI, or `null` if
  /// the URI is not a valid URI or if it is not an absolute URI.
  ///
  /// @param absoluteUri the absolute URI to be resolved
  /// @return a source object representing the absolute URI
  Source forUri(String absoluteUri);

  /// Return a source object representing the given absolute URI, or `null` if
  /// the URI is not an absolute URI.
  ///
  /// @param absoluteUri the absolute URI to be resolved
  /// @return a source object representing the absolute URI
  Source forUri2(Uri absoluteUri);

  /// Return a source representing the URI that results from resolving the given
  /// (possibly relative) [containedUri] against the URI associated with the
  /// [containingSource], whether or not the resulting source exists, or `null`
  /// if either the [containedUri] is invalid or if it cannot be resolved
  /// against the [containingSource]'s URI.
  Source resolveUri(Source containingSource, String containedUri);

  /// Return an absolute URI that represents the given source, or `null` if a
  /// valid URI cannot be computed.
  ///
  /// @param source the source to get URI for
  /// @return the absolute URI representing the given source
  Uri restoreUri(Source source);
}

/// The enumeration `SourceKind` defines the different kinds of sources that are
/// known to the analysis engine.
class SourceKind implements Comparable<SourceKind> {
  /// A source containing HTML. The HTML might or might not contain Dart
  /// scripts.
  static const SourceKind HTML = SourceKind('HTML', 0);

  /// A Dart compilation unit that is not a part of another library. Libraries
  /// might or might not contain any directives, including a library directive.
  static const SourceKind LIBRARY = SourceKind('LIBRARY', 1);

  /// A Dart compilation unit that is part of another library. Parts contain a
  /// part-of directive.
  static const SourceKind PART = SourceKind('PART', 2);

  /// An unknown kind of source. Used both when it is not possible to identify
  /// the kind of a source and also when the kind of a source is not known
  /// without performing a computation and the client does not want to spend the
  /// time to identify the kind.
  static const SourceKind UNKNOWN = SourceKind('UNKNOWN', 3);

  static const List<SourceKind> values = [HTML, LIBRARY, PART, UNKNOWN];

  /// The name of this source kind.
  final String name;

  /// The ordinal value of the source kind.
  final int ordinal;

  const SourceKind(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(SourceKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/// The enumeration `UriKind` defines the different kinds of URI's that are
/// known to the analysis engine. These are used to keep track of the kind of
/// URI associated with a given source.
class UriKind implements Comparable<UriKind> {
  /// A 'dart:' URI.
  static const UriKind DART_URI = UriKind('DART_URI', 0, 0x64);

  /// A 'file:' URI.
  static const UriKind FILE_URI = UriKind('FILE_URI', 1, 0x66);

  /// A 'package:' URI.
  static const UriKind PACKAGE_URI = UriKind('PACKAGE_URI', 2, 0x70);

  static const List<UriKind> values = [DART_URI, FILE_URI, PACKAGE_URI];

  /// The name of this URI kind.
  final String name;

  /// The ordinal value of the URI kind.
  final int ordinal;

  /// The single character encoding used to identify this kind of URI.
  final int encoding;

  /// Initialize a newly created URI kind to have the given encoding.
  const UriKind(this.name, this.ordinal, this.encoding);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(UriKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;

  /// Return the URI kind represented by the given [encoding], or `null` if
  /// there is no kind with the given encoding.
  static UriKind fromEncoding(int encoding) {
    while (true) {
      if (encoding == 0x64) {
        return DART_URI;
      } else if (encoding == 0x66) {
        return FILE_URI;
      } else if (encoding == 0x70) {
        return PACKAGE_URI;
      }
      break;
    }
    return null;
  }

  /// Return the URI kind corresponding to the given scheme string.
  static UriKind fromScheme(String scheme) {
    if (scheme == 'package') {
      return UriKind.PACKAGE_URI;
    } else if (scheme == 'dart') {
      return UriKind.DART_URI;
    } else if (scheme == 'file') {
      return UriKind.FILE_URI;
    }
    return UriKind.FILE_URI;
  }
}

/// The abstract class `UriResolver` defines the behavior of objects that are
/// used to resolve URI's for a source factory. Subclasses of this class are
/// expected to resolve a single scheme of absolute URI.
///
/// NOTICE: in a future breaking change release of the analyzer, a method
/// `void clearCache()` will be added.  Clients that implement, but do not
/// extend, this class, can prepare for the breaking change by adding an
/// implementation of this method that clears any cached URI resolution
/// information.
abstract class UriResolver {
  /// Clear any cached URI resolution information.
  void clearCache() {}

  /// Resolve the given absolute URI. Return a [Source] representing the file to
  /// which it was resolved, whether or not the resulting source exists, or
  /// `null` if it could not be resolved because the URI is invalid.
  ///
  /// @param uri the URI to be resolved
  /// @param actualUri the actual uri for this source -- if `null`, the value of
  /// [uri] will be used
  /// @return a [Source] representing the file to which given URI was resolved
  Source resolveAbsolute(Uri uri, [Uri actualUri]);

  /// Return an absolute URI that represents the given [source], or `null` if a
  /// valid URI cannot be computed.
  ///
  /// The computation should be based solely on [source.fullName].
  Uri restoreAbsolute(Source source) => null;
}
