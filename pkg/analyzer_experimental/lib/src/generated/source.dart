// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.source;

import 'dart:uri';
import 'java_core.dart';

/**
 * Instances of the class {@code SourceFactory} resolve possibly relative URI's against an existing{@link Source source}.
 * @coverage dart.engine.source
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
    _jtd_constructor_300_impl(contentCache2, resolvers2);
  }
  _jtd_constructor_300_impl(ContentCache contentCache2, List<UriResolver> resolvers2) {
    this._contentCache = contentCache2;
    this._resolvers = resolvers2;
  }
  /**
   * Initialize a newly created source factory.
   * @param resolvers the resolvers used to resolve absolute URI's
   */
  SourceFactory.con2(List<UriResolver> resolvers) {
    _jtd_constructor_301_impl(resolvers);
  }
  _jtd_constructor_301_impl(List<UriResolver> resolvers) {
    _jtd_constructor_300_impl(new ContentCache(), resolvers);
  }
  /**
   * Return a source object representing the given absolute URI, or {@code null} if the URI is not a
   * valid URI or if it is not an absolute URI.
   * @param absoluteUri the absolute URI to be resolved
   * @return a source object representing the absolute URI
   */
  Source forUri(String absoluteUri) {
    try {
      Uri uri = new Uri(absoluteUri);
      if (uri.isAbsolute) {
        return resolveUri2(null, uri);
      }
    } on URISyntaxException catch (exception) {
    }
    return null;
  }
  /**
   * Return a source object that is equal to the source object used to obtain the given encoding, or{@code null} if the argument is not a valid encoding.
   * @param encoding the encoding of a source object
   * @return a source object that is described by the given encoding
   * @see Source#getEncoding()
   */
  Source fromEncoding(String encoding) => forUri(encoding);
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
   * Return the modification stamp of the given source, or {@code null} if this factory does not
   * override the contents of the source.
   * <p>
   * <b>Note:</b> This method is not intended to be used except by{@link FileBasedSource#getModificationStamp()}.
   * @param source the source whose modification stamp is to be returned
   * @return the modification stamp of the given source
   */
  int getModificationStamp(Source source) => _contentCache.getModificationStamp(source);
  /**
   * Return a source object representing the URI that results from resolving the given (possibly
   * relative) contained URI against the URI associated with an existing source object, or{@code null} if either the contained URI is invalid or if it cannot be resolved against the
   * source object's URI.
   * @param containingSource the source containing the given URI
   * @param containedUri the (possibly relative) URI to be resolved against the containing source
   * @return the source representing the contained URI
   */
  Source resolveUri2(Source containingSource, Uri containedUri) {
    if (containedUri.isAbsolute) {
      for (UriResolver resolver in _resolvers) {
        Source result = resolver.resolveAbsolute(this, containedUri);
        if (result != null) {
          return result;
        }
      }
      return null;
    } else {
      return containingSource.resolveRelative(containedUri);
    }
  }
}
/**
 * The abstract class {@code UriResolver} defines the behavior of objects that are used to resolve
 * URI's for a source factory. Subclasses of this class are expected to resolve a single scheme of
 * absolute URI.
 * @coverage dart.engine.source
 */
abstract class UriResolver {
  /**
   * Initialize a newly created resolver.
   */
  UriResolver() : super() {
  }
  /**
   * Resolve the given absolute URI. Return a {@link Source source} representing the file to which
   * it was resolved, or {@code null} if it could not be resolved.
   * @param uri the URI to be resolved
   * @return a {@link Source source} representing the URI to which given URI was resolved
   */
  Source resolveAbsolute(SourceFactory factory, Uri uri);
}
/**
 * The interface {@code Source} defines the behavior of objects representing source code that can be
 * compiled.
 * @coverage dart.engine.source
 */
abstract class Source {
  /**
   * An empty array of sources.
   */
  static List<Source> EMPTY_ARRAY = new List<Source>(0);
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
   * Return {@code true} if this source exists.
   * @return {@code true} if this source exists
   */
  bool exists();
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
   * Return an encoded representation of this source that can be used to create a source that is
   * equal to this source.
   * @return an encoded representation of this source
   * @see SourceFactory#fromEncoding(String)
   */
  String get encoding;
  /**
   * Return the full (long) version of the name that can be displayed to the user to denote this
   * source. For example, for a source representing a file this would typically be the absolute path
   * of the file.
   * @return a name that can be displayed to the user to denote this source
   */
  String get fullName;
  /**
   * Return the modification stamp for this source. A modification stamp is a non-negative integer
   * with the property that if the contents of the source have not been modified since the last time
   * the modification stamp was accessed then the same value will be returned, but if the contents
   * of the source have been modified one or more times (even if the net change is zero) the stamps
   * will be different.
   * @return the modification stamp for this source
   */
  int get modificationStamp;
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
  /**
   * Resolve the relative URI against the URI associated with this source object. Return a{@link Source source} representing the URI to which it was resolved, or {@code null} if it
   * could not be resolved.
   * <p>
   * Note: This method is not intended for public use, it is only visible out of necessity. It is
   * only intended to be invoked by a {@link SourceFactory source factory}. Source factories will
   * only invoke this method if the URI is relative, so implementations of this method are not
   * required to, and generally do not, verify the argument. The result of invoking this method with
   * an absolute URI is intentionally left unspecified.
   * @param relativeUri the relative URI to be resolved against the containing source
   * @return a {@link Source source} representing the URI to which given URI was resolved
   */
  Source resolveRelative(Uri relativeUri);
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
 * The enumeration {@code SourceKind} defines the different kinds of sources that are known to the
 * analysis engine.
 * @coverage dart.engine.source
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
  int get ordinal => __ordinal;
  SourceKind(this.__name, this.__ordinal) {
  }
  String toString() => __name;
}
/**
 * A source range defines an {@link Element}'s source coordinates relative to its {@link Source}.
 * @coverage dart.engine.utilities
 */
class SourceRange {
  /**
   * The 0-based index of the first character of the source code for this element, relative to the
   * source buffer in which this element is contained.
   */
  int _offset = 0;
  /**
   * The number of characters of the source code for this element, relative to the source buffer in
   * which this element is contained.
   */
  int _length = 0;
  /**
   * Initialize a newly created source range using the given offset and the given length.
   * @param offset the given offset
   * @param length the given length
   */
  SourceRange(int offset, int length) {
    this._offset = offset;
    this._length = length;
  }
  /**
   * @return <code>true</code> if <code>x</code> is in [offset, offset + length) interval.
   */
  bool contains(int x) => _offset <= x && x < _offset + _length;
  /**
   * @return <code>true</code> if <code>x</code> is in (offset, offset + length) interval.
   */
  bool containsExclusive(int x) => _offset < x && x < _offset + _length;
  /**
   * @return <code>true</code> if <code>otherRange</code> covers this {@link SourceRange}.
   */
  bool coveredBy(SourceRange otherRange) => otherRange.covers(this);
  /**
   * @return <code>true</code> if this {@link SourceRange} covers <code>otherRange</code>.
   */
  bool covers(SourceRange otherRange) => offset <= otherRange.offset && otherRange.end <= end;
  /**
   * @return <code>true</code> if this {@link SourceRange} ends in <code>otherRange</code>.
   */
  bool endsIn(SourceRange otherRange) {
    int thisEnd = end;
    return otherRange.contains(thisEnd);
  }
  bool operator ==(Object obj) {
    if (obj is! SourceRange) {
      return false;
    }
    SourceRange sourceRange = obj as SourceRange;
    return sourceRange.offset == _offset && sourceRange.length == _length;
  }
  /**
   * @return the 0-based index of the after-last character of the source code for this element,
   * relative to the source buffer in which this element is contained.
   */
  int get end => _offset + _length;
  /**
   * @return the expanded instance of {@link SourceRange}, which has the same center.
   */
  SourceRange getExpanded(int delta) => new SourceRange(_offset - delta, delta + _length + delta);
  /**
   * Returns the number of characters of the source code for this element, relative to the source
   * buffer in which this element is contained.
   * @return the number of characters of the source code for this element, relative to the source
   * buffer in which this element is contained
   */
  int get length => _length;
  /**
   * @return the instance of {@link SourceRange} with end moved on "delta".
   */
  SourceRange getMoveEnd(int delta) => new SourceRange(_offset, _length + delta);
  /**
   * Returns the 0-based index of the first character of the source code for this element, relative
   * to the source buffer in which this element is contained.
   * @return the 0-based index of the first character of the source code for this element, relative
   * to the source buffer in which this element is contained
   */
  int get offset => _offset;
  int get hashCode => 31 * _offset + _length;
  /**
   * @return <code>true</code> if this {@link SourceRange} intersects with given.
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
   * @return <code>true</code> if this {@link SourceRange} starts in <code>otherRange</code>.
   */
  bool startsIn(SourceRange otherRange) => otherRange.contains(_offset);
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[offset=");
    builder.append(_offset);
    builder.append(", length=");
    builder.append(_length);
    builder.append("]");
    return builder.toString();
  }
}
/**
 * The interface {@code SourceContainer} is used by clients to define a collection of sources
 * <p>
 * Source containers are not used within analysis engine, but can be used by clients to group
 * sources for the purposes of accessing composite dependency information. For example, the Eclipse
 * client uses source containers to represent Eclipse projects, which allows it to easily compute
 * project-level dependencies.
 * @coverage dart.engine.source
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
 * @coverage dart.engine.utilities
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
 * Instances of class {@code ContentCache} hold content used to override the default content of a{@link Source}.
 * @coverage dart.engine.source
 */
class ContentCache {
  /**
   * A table mapping sources to the contents of those sources. This is used to override the default
   * contents of a source.
   */
  Map<Source, String> _contentMap = new Map<Source, String>();
  /**
   * A table mapping sources to the modification stamps of those sources. This is used when the
   * default contents of a source has been overridden.
   */
  Map<Source, int> _stampMap = new Map<Source, int>();
  /**
   * Initialize a newly created cache to be empty.
   */
  ContentCache() : super() {
  }
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
   * Return the modification stamp of the given source, or {@code null} if this cache does not
   * override the contents of the source.
   * <p>
   * <b>Note:</b> This method is not intended to be used except by{@link SourceFactory#getModificationStamp(com.google.dart.engine.source.Source)}.
   * @param source the source whose modification stamp is to be returned
   * @return the modification stamp of the given source
   */
  int getModificationStamp(Source source) => _stampMap[source];
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
      _stampMap.remove(source);
    } else {
      _contentMap[source] = contents;
      _stampMap[source] = JavaSystem.currentTimeMillis();
    }
  }
}