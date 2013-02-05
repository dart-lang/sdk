// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.source;

import 'java_core.dart';

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