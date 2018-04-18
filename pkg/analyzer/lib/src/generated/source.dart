// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source_io.dart' show FileBasedSource;
import 'package:front_end/src/base/source.dart';
import 'package:front_end/src/base/uri_kind.dart';
import 'package:package_config/packages.dart';
import 'package:path/path.dart' as pathos;

export 'package:analyzer/source/line_info.dart' show LineInfo;
export 'package:analyzer/source/source_range.dart';
export 'package:front_end/src/base/source.dart' show Source;
export 'package:front_end/src/base/uri_kind.dart' show UriKind;

/**
 * A function that is used to visit [ContentCache] entries.
 */
typedef void ContentCacheVisitor(String fullPath, int stamp, String contents);

/**
 * A cache used to override the default content of a [Source].
 */
class ContentCache {
  /**
   * A table mapping the full path of sources to the contents of those sources.
   * This is used to override the default contents of a source.
   */
  Map<String, String> _contentMap = new HashMap<String, String>();

  /**
   * A table mapping the full path of sources to the modification stamps of
   * those sources. This is used when the default contents of a source has been
   * overridden.
   */
  Map<String, int> _stampMap = new HashMap<String, int>();

  int _nextStamp = 0;

  /**
   * Visit all entries of this cache.
   */
  void accept(ContentCacheVisitor visitor) {
    _contentMap.forEach((String fullPath, String contents) {
      int stamp = _stampMap[fullPath];
      visitor(fullPath, stamp, contents);
    });
  }

  /**
   * Return the contents of the given [source], or `null` if this cache does not
   * override the contents of the source.
   *
   * <b>Note:</b> This method is not intended to be used except by
   * [AnalysisContext.getContents].
   */
  String getContents(Source source) => _contentMap[source.fullName];

  /**
   * Return `true` if the given [source] exists, `false` if it does not exist,
   * or `null` if this cache does not override existence of the source.
   *
   * <b>Note:</b> This method is not intended to be used except by
   * [AnalysisContext.exists].
   */
  bool getExists(Source source) {
    return _contentMap.containsKey(source.fullName) ? true : null;
  }

  /**
   * Return the modification stamp of the given [source], or `null` if this
   * cache does not override the contents of the source.
   *
   * <b>Note:</b> This method is not intended to be used except by
   * [AnalysisContext.getModificationStamp].
   */
  int getModificationStamp(Source source) => _stampMap[source.fullName];

  /**
   * Set the contents of the given [source] to the given [contents]. This has
   * the effect of overriding the default contents of the source. If the
   * contents are `null` the override is removed so that the default contents
   * will be returned.
   */
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

@deprecated
class CustomUriResolver extends UriResolver {
  final Map<String, String> _urlMappings;

  CustomUriResolver(this._urlMappings);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    String mapping = _urlMappings[uri.toString()];
    if (mapping == null) return null;

    Uri fileUri = new Uri.file(mapping);
    if (!fileUri.isAbsolute) return null;

    JavaFile javaFile = new JavaFile.fromUri(fileUri);
    return new FileBasedSource(javaFile, actualUri ?? uri);
  }
}

/**
 * Instances of the class `DartUriResolver` resolve `dart` URI's.
 */
class DartUriResolver extends UriResolver {
  /**
   * The name of the `dart` scheme.
   */
  static String DART_SCHEME = "dart";

  /**
   * The prefix of a URI using the dart-ext scheme to reference a native code library.
   */
  static String _DART_EXT_SCHEME = "dart-ext:";

  /**
   * The Dart SDK against which URI's are to be resolved.
   */
  final DartSdk _sdk;

  /**
   * Initialize a newly created resolver to resolve Dart URI's against the given platform within the
   * given Dart SDK.
   *
   * @param sdk the Dart SDK against which URI's are to be resolved
   */
  DartUriResolver(this._sdk);

  /**
   * Return the [DartSdk] against which URIs are to be resolved.
   *
   * @return the [DartSdk] against which URIs are to be resolved.
   */
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

  /**
   * Return `true` if the given URI is a `dart-ext:` URI.
   *
   * @param uriContent the textual representation of the URI being tested
   * @return `true` if the given URI is a `dart-ext:` URI
   */
  static bool isDartExtUri(String uriContent) =>
      uriContent != null && uriContent.startsWith(_DART_EXT_SCHEME);

  /**
   * Return `true` if the given URI is a `dart:` URI.
   *
   * @param uri the URI being tested
   * @return `true` if the given URI is a `dart:` URI
   */
  static bool isDartUri(Uri uri) => DART_SCHEME == uri.scheme;
}

/**
 * Instances of the class `Location` represent the location of a character as a line and
 * column pair.
 */
@deprecated
class LineInfo_Location {
  /**
   * The one-based index of the line containing the character.
   */
  final int lineNumber;

  /**
   * The one-based index of the column containing the character.
   */
  final int columnNumber;

  /**
   * Initialize a newly created location to represent the location of the
   * character at the given [lineNumber] and [columnNumber].
   */
  LineInfo_Location(this.lineNumber, this.columnNumber);

  @override
  String toString() => '$lineNumber:$columnNumber';
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
 * An implementation of an non-existing [Source].
 */
class NonExistingSource extends Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  @override
  final UriKind uriKind;

  NonExistingSource(this.fullName, this.uri, this.uriKind);

  @override
  TimestampedData<String> get contents {
    throw new UnsupportedError('$fullName does not exist.');
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

/**
 * The interface `ContentReceiver` defines the behavior of objects that can receive the
 * content of a source.
 */
abstract class Source_ContentReceiver {
  /**
   * Accept the contents of a source.
   *
   * @param contents the contents of the source
   * @param modificationTime the time at which the contents were last set
   */
  void accept(String contents, int modificationTime);
}

/**
 * The interface `SourceContainer` is used by clients to define a collection of sources
 *
 * Source containers are not used within analysis engine, but can be used by clients to group
 * sources for the purposes of accessing composite dependency information. For example, the Eclipse
 * client uses source containers to represent Eclipse projects, which allows it to easily compute
 * project-level dependencies.
 */
abstract class SourceContainer {
  /**
   * Determine if the specified source is part of the receiver's collection of sources.
   *
   * @param source the source in question
   * @return `true` if the receiver contains the source, else `false`
   */
  bool contains(Source source);
}

/**
 * Instances of the class `SourceFactory` resolve possibly relative URI's against an existing
 * [Source].
 */
abstract class SourceFactory {
  /**
   * The analysis context that this source factory is associated with.
   */
  AnalysisContext context;

  /**
   * Initialize a newly created source factory with the given absolute URI
   * [resolvers] and optional [packages] resolution helper.
   */
  factory SourceFactory(List<UriResolver> resolvers,
      [Packages packages,
      ResourceProvider resourceProvider]) = SourceFactoryImpl;

  /**
   * Return the [DartSdk] associated with this [SourceFactory], or `null` if
   * there is no such SDK.
   *
   * @return the [DartSdk] associated with this [SourceFactory], or `null` if
   *         there is no such SDK
   */
  DartSdk get dartSdk;

  /**
   * Sets the [LocalSourcePredicate].
   *
   * @param localSourcePredicate the predicate to determine is [Source] is local
   */
  void set localSourcePredicate(LocalSourcePredicate localSourcePredicate);

  /// A table mapping package names to paths of directories containing
  /// the package (or [null] if there is no registered package URI resolver).
  Map<String, List<Folder>> get packageMap;

  /**
   * Return a source factory that will resolve URI's in the same way that this
   * source factory does.
   */
  SourceFactory clone();

  /**
   * Return a source object representing the given absolute URI, or `null` if
   * the URI is not a valid URI or if it is not an absolute URI.
   *
   * @param absoluteUri the absolute URI to be resolved
   * @return a source object representing the absolute URI
   */
  Source forUri(String absoluteUri);

  /**
   * Return a source object representing the given absolute URI, or `null` if
   * the URI is not an absolute URI.
   *
   * @param absoluteUri the absolute URI to be resolved
   * @return a source object representing the absolute URI
   */
  Source forUri2(Uri absoluteUri);

  /**
   * Return a source object that is equal to the source object used to obtain
   * the given encoding.
   *
   * @param encoding the encoding of a source object
   * @return a source object that is described by the given encoding
   * @throws IllegalArgumentException if the argument is not a valid encoding
   * See [Source.encoding].
   */
  Source fromEncoding(String encoding);

  /**
   * Determines if the given [Source] is local.
   *
   * @param source the [Source] to analyze
   * @return `true` if the given [Source] is local
   */
  bool isLocalSource(Source source);

  /**
   * Return a source representing the URI that results from resolving the given
   * (possibly relative) [containedUri] against the URI associated with the
   * [containingSource], whether or not the resulting source exists, or `null`
   * if either the [containedUri] is invalid or if it cannot be resolved against
   * the [containingSource]'s URI.
   */
  Source resolveUri(Source containingSource, String containedUri);

  /**
   * Return an absolute URI that represents the given source, or `null` if a
   * valid URI cannot be computed.
   *
   * @param source the source to get URI for
   * @return the absolute URI representing the given source
   */
  Uri restoreUri(Source source);
}

/**
 * The enumeration `SourceKind` defines the different kinds of sources that are
 * known to the analysis engine.
 */
class SourceKind implements Comparable<SourceKind> {
  /**
   * A source containing HTML. The HTML might or might not contain Dart scripts.
   */
  static const SourceKind HTML = const SourceKind('HTML', 0);

  /**
   * A Dart compilation unit that is not a part of another library. Libraries
   * might or might not contain any directives, including a library directive.
   */
  static const SourceKind LIBRARY = const SourceKind('LIBRARY', 1);

  /**
   * A Dart compilation unit that is part of another library. Parts contain a
   * part-of directive.
   */
  static const SourceKind PART = const SourceKind('PART', 2);

  /**
   * An unknown kind of source. Used both when it is not possible to identify
   * the kind of a source and also when the kind of a source is not known
   * without performing a computation and the client does not want to spend the
   * time to identify the kind.
   */
  static const SourceKind UNKNOWN = const SourceKind('UNKNOWN', 3);

  static const List<SourceKind> values = const [HTML, LIBRARY, PART, UNKNOWN];

  /**
   * The name of this source kind.
   */
  final String name;

  /**
   * The ordinal value of the source kind.
   */
  final int ordinal;

  const SourceKind(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(SourceKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/**
 * The abstract class `UriResolver` defines the behavior of objects that are used to resolve
 * URI's for a source factory. Subclasses of this class are expected to resolve a single scheme of
 * absolute URI.
 */
abstract class UriResolver {
  /**
   * Resolve the given absolute URI. Return a [Source] representing the file to which
   * it was resolved, whether or not the resulting source exists, or `null` if it could not be
   * resolved because the URI is invalid.
   *
   * @param uri the URI to be resolved
   * @param actualUri the actual uri for this source -- if `null`, the value of [uri] will be used
   * @return a [Source] representing the file to which given URI was resolved
   */
  Source resolveAbsolute(Uri uri, [Uri actualUri]);

  /**
   * Return an absolute URI that represents the given [source], or `null` if a
   * valid URI cannot be computed.
   *
   * The computation should be based solely on [source.fullName].
   */
  Uri restoreAbsolute(Source source) => null;
}
