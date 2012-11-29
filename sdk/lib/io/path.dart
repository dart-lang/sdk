// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_io;

/**
 * A Path, which is a String interpreted as a sequence of path segments,
 * which are strings, separated by forward slashes.
 * Paths are immutable wrappers of a String, that offer member functions for
 * useful path manipulations and queries.  Joining of paths and normalization
 * interpret '.' and '..' in the usual way.
 */
abstract class Path {
  /**
   * Creates a Path from the String [source].  [source] is used as-is, so if
   * the string does not consist of segments separated by forward slashes, the
   * behavior may not be as expected.  Paths are immutable.
   */
  factory Path(String source) => new _Path(source);

  /**
   * Creates a Path from a String that uses the native filesystem's conventions.
   *
   * On Windows, this converts '\' to '/' and has special handling for drive
   * letters and shares.
   *
   * If the path contains a drive letter a '/' is added before the drive letter.
   *
   *     new Path.fromNative(r'c:\a\b').toString() == '/c:/a/b'
   *
   * A path starting with '/c:/' (or any other character instead of 'c') is
   * treated specially.  Backwards links ('..') cannot cancel the drive letter.
   *
   * If the path is a share path this is recorded in the Path object and
   * maintained in operations on the Path object.
   *
   *     var share = new Path.fromNative(r'\\share\a\b\c');
   *     share.isWindowsShare == true
   *     share.toString() == '/share/a/b/c'
   *     share.toNativePath() == r'\\share\a\b\c'
   *     share.append('final').isWindowsShare == true
   */
  factory Path.fromNative(String source) => new _Path.fromNative(source);

  /**
   * Is this path the empty string?
   */
  bool get isEmpty;

  /**
   * Is this path an absolute path, beginning with a path separator?
   */
  bool get isAbsolute;

  /**
   * Is this path a Windows share path?
   */
  bool get isWindowsShare;

  /**
   * Does this path end with a path separator?
   */
  bool get hasTrailingSeparator;

  /**
   * Does this path contain no consecutive path separators, no segments that
   * are '.' unless the path is exactly '.', and segments that are '..' only
   * as the leading segments on a relative path?
   */
  bool get isCanonical;

  /**
   * Make a path canonical by dropping segments that are '.', cancelling
   * segments that are '..' with preceding segments, if possible,
   * and combining consecutive path separators.  Leading '..' segments
   * are kept on relative paths, and dropped from absolute paths.
   */
  Path canonicalize();

  /**
   * Joins the relative path [further] to this path.  Canonicalizes the
   * resulting joined path using [canonicalize],
   * interpreting '.' and '..' as directory traversal commands, and removing
   * consecutive path separators.
   *
   * If [further] is an absolute path, an IllegalArgument exception is thrown.
   *
   * Examples:
   *   `new Path('/a/b/c').join(new Path('d/e'))` returns the Path object
   *   containing `'a/b/c/d/e'`.
   *
   *   `new Path('a/b/../c/').join(new Path('d/./e//')` returns the Path
   *   containing `'a/c/d/e/'`.
   *
   *   `new Path('a/b/c').join(new Path('d/../../e')` returns the Path
   *   containing `'a/b/e'`.
   *
   * Note that the join operation does not drop the last segment of the
   * base path, the way URL joining does.  That would be accomplished with
   * basepath.directoryPath.join(further).
   *
   * If you want to avoid joins that traverse
   * parent directories in the base, you can check whether
   * `further.canonicalize()` starts with '../' or equals '..'.
   */
  Path join(Path further);


  /**
   * Returns a path [:relative:] such that
   *    [:base.join(relative) == this.canonicalize():].
   * Throws an exception if such a path is impossible.
   * For example, if [base] is '../../a/b' and [this] is '.'.
   * The computation is independent of the file system and current directory.
   */
  Path relativeTo(Path base);

  /**
   * Converts a path to a string using the native filesystem's conventions.
   *
   * On Windows, converts path separators to backwards slashes, and removes
   * the leading path separator if the path starts with a drive specification.
   * For most valid Windows paths, this should be the inverse of the
   * constructor Path.fromNative.
   */
  String toNativePath();

  /**
   * Returns the path as a string.  If this path is constructed using
   * new Path() or new Path.fromNative() on a non-Windows system, the
   * returned value is the original string argument to the constructor.
   */
  String toString();

  /**
   * Gets the segments of a Path.  Paths beginning or ending with the
   * path separator do not have leading or terminating empty segments.
   * Other than that, the segments are just the result of splitting the
   * path on the path separator.
   *
   *     new Path('/a/b/c/d').segments() == ['a', 'b', 'c', d'];
   *     new Path(' foo bar //../') == [' foo bar ', '', '..'];
   */
  List<String> segments();

  /**
   * Appends [finalSegment] to a path as a new segment.  Adds a path separator
   * between the path and [finalSegment] if the path does not already end in
   * a path separator.  The path is not canonicalized, and [finalSegment] may
   * contain path separators.
   */
  Path append(String finalSegment);

  /**
   * Drops the final path separator and whatever follows it from this Path,
   * and returns the resulting Path object.  If the only path separator in
   * this Path is the first character, returns '/' instead of the empty string.
   * If there is no path separator in the Path, returns the empty string.
   *
   *     new Path('../images/dot.gif').directoryPath == '../images'
   *     new Path('/usr/geoffrey/www/').directoryPath == '/usr/geoffrey/www'
   *     new Path('lost_file_old').directoryPath == ''
   *     new Path('/src').directoryPath == '/'
   *     Note: new Path('/D:/src').directoryPath == '/D:'
   */
  Path get directoryPath;

  /**
   * The part of the path after the last path separator, or the entire path if
   * it contains no path separator.
   *
   *     new Path('images/DSC_0027.jpg).filename == 'DSC_0027.jpg'
   *     new Path('users/fred/').filename == ''
   */
  String get filename;

  /**
   * The part of [filename] before the last '.', or the entire filename if it
   * contains no '.'.  If [filename] is '.' or '..' it is unchanged.
   *
   *     new Path('/c:/My Documents/Heidi.txt').filenameWithoutExtension
   *     would return 'Heidi'.
   *     new Path('not what I would call a path').filenameWithoutExtension
   *     would return 'not what I would call a path'.
   */
  String get filenameWithoutExtension;

  /**
   * The part of [filename] after the last '.', or '' if [filename]
   * contains no '.'.  If [filename] is '.' or '..', returns ''.
   *
   *     new Path('tiger.svg').extension == 'svg'
   *     new Path('/src/dart/dart_secrets').extension == ''
   */
  String get extension;
}
