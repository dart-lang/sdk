// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.source;

import 'dart:collection';
import "dart:math" as math;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source_io.dart'
    show FileBasedSource, PackageUriResolver;
import 'package:analyzer/task/model.dart';
import 'package:package_config/packages.dart';
import 'package:path/path.dart' as pathos;

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
  HashMap<String, String> _contentMap = new HashMap<String, String>();

  /**
   * A table mapping the full path of sources to the modification stamps of
   * those sources. This is used when the default contents of a source has been
   * overridden.
   */
  HashMap<String, int> _stampMap = new HashMap<String, int>();

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
      int newStamp = JavaSystem.currentTimeMillis();
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
 * Information about line and column information within a source file.
 */
class LineInfo {
  /**
   * A list containing the offsets of the first character of each line in the
   * source code.
   */
  final List<int> lineStarts;

  /**
   * The zero-based [lineStarts] index resulting from the last call to
   * [getLocation].
   */
  int _previousLine = 0;

  /**
   * Initialize a newly created set of line information to represent the data
   * encoded in the given list of [lineStarts].
   */
  factory LineInfo(List<int> lineStarts) => new LineInfoWithCount(lineStarts);

  /**
   * Initialize a newly created set of line information corresponding to the
   * given file [content].
   */
  factory LineInfo.fromContent(String content) =>
      new LineInfoWithCount(StringUtilities.computeLineStarts(content));

  /**
   * Initialize a newly created set of line information to represent the data
   * encoded in the given list of [lineStarts].
   */
  LineInfo._(this.lineStarts) {
    if (lineStarts == null) {
      throw new IllegalArgumentException("lineStarts must be non-null");
    } else if (lineStarts.length < 1) {
      throw new IllegalArgumentException("lineStarts must be non-empty");
    }
  }

  /**
   * The number of lines.
   */
  int get lineCount => lineStarts.length;

  /**
   * Return the location information for the character at the given [offset].
   */
  LineInfo_Location getLocation(int offset) {
    var min = 0;
    var max = lineStarts.length - 1;

    // Subsequent calls to [getLocation] are often for offsets near each other.
    // To take advantage of that, we cache the index of the line start we found
    // when this was last called. If the current offset is on that line or
    // later, we'll skip those early indices completely when searching.
    if (offset >= lineStarts[_previousLine]) {
      min = _previousLine;

      // Before kicking off a full binary search, do a quick check here to see
      // if the new offset is on that exact line.
      if (min == lineStarts.length - 1 || offset < lineStarts[min + 1]) {
        return new LineInfo_Location(min + 1, offset - lineStarts[min] + 1);
      }
    }

    // Binary search to fine the line containing this offset.
    while (min < max) {
      var midpoint = (max - min + 1) ~/ 2 + min;

      if (lineStarts[midpoint] > offset) {
        max = midpoint - 1;
      } else {
        min = midpoint;
      }
    }

    _previousLine = min;

    return new LineInfo_Location(min + 1, offset - lineStarts[min] + 1);
  }

  /**
   * Return the offset of the first character on the line with the given
   * [lineNumber].
   */
  int getOffsetOfLine(int lineNumber) {
    if (lineNumber < 0 || lineNumber >= lineCount) {
      throw new ArgumentError(
          'Invalid line number: $lineNumber; must be between 0 and ${lineCount - 1}');
    }
    return lineStarts[lineNumber];
  }
}

/**
 * Instances of the class `Location` represent the location of a character as a line and
 * column pair.
 */
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
   * Initialize a newly created location to represent the location of the character at the given
   * line and column position.
   *
   * @param lineNumber the one-based index of the line containing the character
   * @param columnNumber the one-based index of the column containing the character
   */
  LineInfo_Location(this.lineNumber, this.columnNumber);

  @override
  String toString() => '$lineNumber:$columnNumber';
}

/**
 * Information about line and column information within a source file,
 * including a count of the total number of lines.
 *
 * TODO(paulberry): in the next major version roll of analyzer, merge this
 * class into [LineInfo].
 */
class LineInfoWithCount extends LineInfo {
  /**
   * Initialize a newly created set of line information to represent the data
   * encoded in the given list of [lineStarts].
   */
  LineInfoWithCount(List<int> lineStarts) : super._(lineStarts);
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
    throw new UnsupportedOperationException('$fullName does not exist.');
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
}

/**
 * The interface `Source` defines the behavior of objects representing source code that can be
 * analyzed by the analysis engine.
 *
 * Implementations of this interface need to be aware of some assumptions made by the analysis
 * engine concerning sources:
 * * Sources are not required to be unique. That is, there can be multiple instances representing
 * the same source.
 * * Sources are long lived. That is, the engine is allowed to hold on to a source for an extended
 * period of time and that source must continue to report accurate and up-to-date information.
 * Because of these assumptions, most implementations will not maintain any state but will delegate
 * to an authoritative system of record in order to implement this API. For example, a source that
 * represents files on disk would typically query the file system to determine the state of the
 * file.
 *
 * If the instances that implement this API are the system of record, then they will typically be
 * unique. In that case, sources that are created that represent non-existent files must also be
 * retained so that if those files are created at a later date the long-lived sources representing
 * those files will know that they now exist.
 */
abstract class Source implements AnalysisTarget {
  /**
   * An empty list of sources.
   */
  static const List<Source> EMPTY_LIST = const <Source>[];

  /**
   * Get the contents and timestamp of this source.
   *
   * Clients should consider using the method [AnalysisContext.getContents]
   * because contexts can have local overrides of the content of a source that the source is not
   * aware of.
   *
   * @return the contents and timestamp of the source
   * @throws Exception if the contents of this source could not be accessed
   */
  TimestampedData<String> get contents;

  /**
   * Return an encoded representation of this source that can be used to create a source that is
   * equal to this source.
   *
   * @return an encoded representation of this source
   * See [SourceFactory.fromEncoding].
   */
  String get encoding;

  /**
   * Return the full (long) version of the name that can be displayed to the user to denote this
   * source. For example, for a source representing a file this would typically be the absolute path
   * of the file.
   *
   * @return a name that can be displayed to the user to denote this source
   */
  String get fullName;

  /**
   * Return a hash code for this source.
   *
   * @return a hash code for this source
   * See [Object.hashCode].
   */
  @override
  int get hashCode;

  /**
   * Return `true` if this source is in one of the system libraries.
   *
   * @return `true` if this is in a system library
   */
  bool get isInSystemLibrary;

  @override
  Source get librarySource => null;

  /**
   * Return the modification stamp for this source, or a negative value if the
   * source does not exist. A modification stamp is a non-negative integer with
   * the property that if the contents of the source have not been modified
   * since the last time the modification stamp was accessed then the same value
   * will be returned, but if the contents of the source have been modified one
   * or more times (even if the net change is zero) the stamps will be different.
   *
   * Clients should consider using the method
   * [AnalysisContext.getModificationStamp] because contexts can have local
   * overrides of the content of a source that the source is not aware of.
   */
  int get modificationStamp;

  /**
   * Return a short version of the name that can be displayed to the user to denote this source. For
   * example, for a source representing a file this would typically be the name of the file.
   *
   * @return a name that can be displayed to the user to denote this source
   */
  String get shortName;

  @override
  Source get source => this;

  /**
   * Return the URI from which this source was originally derived.
   *
   * @return the URI from which this source was originally derived
   */
  Uri get uri;

  /**
   * Return the kind of URI from which this source was originally derived. If this source was
   * created from an absolute URI, then the returned kind will reflect the scheme of the absolute
   * URI. If it was created from a relative URI, then the returned kind will be the same as the kind
   * of the source against which the relative URI was resolved.
   *
   * @return the kind of URI from which this source was originally derived
   */
  UriKind get uriKind;

  /**
   * Return `true` if the given object is a source that represents the same source code as
   * this source.
   *
   * @param object the object to be compared with this object
   * @return `true` if the given object is a source that represents the same source code as
   *         this source
   * See [Object.==].
   */
  @override
  bool operator ==(Object object);

  /**
   * Return `true` if this source exists.
   *
   * Clients should consider using the method [AnalysisContext.exists] because
   * contexts can have local overrides of the content of a source that the source is not aware of
   * and a source with local content is considered to exist even if there is no file on disk.
   *
   * @return `true` if this source exists
   */
  bool exists();
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
class SourceKind extends Enum<SourceKind> {
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

  const SourceKind(String name, int ordinal) : super(name, ordinal);
}

/**
 * A source range defines an [Element]'s source coordinates relative to its [Source].
 */
class SourceRange {
  /**
   * An empty [SourceRange] with offset `0` and length `0`.
   */
  static SourceRange EMPTY = new SourceRange(0, 0);

  /**
   * The 0-based index of the first character of the source code for this element, relative to the
   * source buffer in which this element is contained.
   */
  final int offset;

  /**
   * The number of characters of the source code for this element, relative to the source buffer in
   * which this element is contained.
   */
  final int length;

  /**
   * Initialize a newly created source range using the given offset and the given length.
   *
   * @param offset the given offset
   * @param length the given length
   */
  SourceRange(this.offset, this.length);

  /**
   * @return the 0-based index of the after-last character of the source code for this element,
   *         relative to the source buffer in which this element is contained.
   */
  int get end => offset + length;

  @override
  int get hashCode => 31 * offset + length;

  @override
  bool operator ==(Object other) {
    return other is SourceRange &&
        other.offset == offset &&
        other.length == length;
  }

  /**
   * @return `true` if <code>x</code> is in [offset, offset + length) interval.
   */
  bool contains(int x) => offset <= x && x < offset + length;

  /**
   * @return `true` if <code>x</code> is in (offset, offset + length) interval.
   */
  bool containsExclusive(int x) => offset < x && x < offset + length;

  /**
   * @return `true` if <code>otherRange</code> covers this [SourceRange].
   */
  bool coveredBy(SourceRange otherRange) => otherRange.covers(this);

  /**
   * @return `true` if this [SourceRange] covers <code>otherRange</code>.
   */
  bool covers(SourceRange otherRange) =>
      offset <= otherRange.offset && otherRange.end <= end;

  /**
   * @return `true` if this [SourceRange] ends in <code>otherRange</code>.
   */
  bool endsIn(SourceRange otherRange) {
    int thisEnd = end;
    return otherRange.contains(thisEnd);
  }

  /**
   * @return the expanded instance of [SourceRange], which has the same center.
   */
  SourceRange getExpanded(int delta) =>
      new SourceRange(offset - delta, delta + length + delta);

  /**
   * @return the instance of [SourceRange] with end moved on "delta".
   */
  SourceRange getMoveEnd(int delta) => new SourceRange(offset, length + delta);

  /**
   * @return the expanded translated of [SourceRange], with moved start and the same length.
   */
  SourceRange getTranslated(int delta) =>
      new SourceRange(offset + delta, length);

  /**
   * @return the minimal [SourceRange] that cover this and the given [SourceRange]s.
   */
  SourceRange getUnion(SourceRange other) {
    int newOffset = math.min(offset, other.offset);
    int newEnd = math.max(offset + length, other.offset + other.length);
    return new SourceRange(newOffset, newEnd - newOffset);
  }

  /**
   * @return `true` if this [SourceRange] intersects with given.
   */
  bool intersects(SourceRange other) {
    if (other == null) {
      return false;
    }
    if (end <= other.offset) {
      return false;
    }
    if (offset >= other.end) {
      return false;
    }
    return true;
  }

  /**
   * Return `true` if this [SourceRange] starts in the [otherRange].
   */
  bool startsIn(SourceRange otherRange) => otherRange.contains(offset);

  @override
  String toString() => '[offset=$offset, length=$length]';
}

/**
 * The enumeration `UriKind` defines the different kinds of URI's that are known to the
 * analysis engine. These are used to keep track of the kind of URI associated with a given source.
 */
class UriKind extends Enum<UriKind> {
  /**
   * A 'dart:' URI.
   */
  static const UriKind DART_URI = const UriKind('DART_URI', 0, 0x64);

  /**
   * A 'file:' URI.
   */
  static const UriKind FILE_URI = const UriKind('FILE_URI', 1, 0x66);

  /**
   * A 'package:' URI.
   */
  static const UriKind PACKAGE_URI = const UriKind('PACKAGE_URI', 2, 0x70);

  static const List<UriKind> values = const [DART_URI, FILE_URI, PACKAGE_URI];

  /**
   * The single character encoding used to identify this kind of URI.
   */
  final int encoding;

  /**
   * Initialize a newly created URI kind to have the given encoding.
   *
   * @param encoding the single character encoding used to identify this kind of URI.
   */
  const UriKind(String name, int ordinal, this.encoding) : super(name, ordinal);

  /**
   * Return the URI kind represented by the given encoding, or `null` if there is no kind with
   * the given encoding.
   *
   * @param encoding the single character encoding used to identify the URI kind to be returned
   * @return the URI kind represented by the given encoding
   */
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

  /**
   * Return the URI kind corresponding to the given scheme string.
   */
  static UriKind fromScheme(String scheme) {
    if (scheme == PackageUriResolver.PACKAGE_SCHEME) {
      return UriKind.PACKAGE_URI;
    } else if (scheme == DartUriResolver.DART_SCHEME) {
      return UriKind.DART_URI;
    } else if (scheme == ResourceUriResolver.FILE_SCHEME) {
      return UriKind.FILE_URI;
    }
    return UriKind.FILE_URI;
  }
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
