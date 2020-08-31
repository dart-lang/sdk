// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:math';

// TODO: Remove this class, and use the URI class for all path manipulation.
class Path {
  static Path workingDirectory = Path(Directory.current.path);

  final String _path;
  final bool isWindowsShare;

  Path(String source)
      : _path = _clean(source),
        isWindowsShare = _isWindowsShare(source);

  Path.raw(String source)
      : _path = source,
        isWindowsShare = false;

  Path._internal(this._path, this.isWindowsShare);

  static String _clean(String source) {
    if (Platform.operatingSystem == 'windows') return _cleanWindows(source);
    // Remove trailing slash from directories:
    if (source.length > 1 && source.endsWith('/')) {
      return source.substring(0, source.length - 1);
    }
    return source;
  }

  static String _cleanWindows(String source) {
    // Change \ to /.
    var clean = source.replaceAll('\\', '/');
    // Add / before initial [Drive letter]:
    if (clean.length >= 2 && clean[1] == ':') {
      clean = '/$clean';
    }
    if (_isWindowsShare(source)) {
      return clean.substring(1, clean.length);
    }
    return clean;
  }

  static bool _isWindowsShare(String source) {
    return Platform.operatingSystem == 'windows' && source.startsWith('\\\\');
  }

  bool operator ==(other) => other is Path && _path == other._path;

  int get hashCode => _path.hashCode;
  bool get isEmpty => _path.isEmpty;
  bool get isAbsolute => _path.startsWith('/');
  bool get hasTrailingSeparator => _path.endsWith('/');

  /// Convert this path to an absolute path relative to the [workingDirectory]
  /// if it is not already absolute.
  Path get absolute {
    if (isAbsolute) return this;
    return Path.workingDirectory.join(this);
  }

  String toString() => _path;

  Path relativeTo(Path base) {
    // Returns a path "relative" such that
    // base.join(relative) == this.canonicalize.
    // Throws exception if an impossible case is reached.
    if (base.isAbsolute != isAbsolute ||
        base.isWindowsShare != isWindowsShare) {
      throw ArgumentError("Invalid case of Path.relativeTo(base):\n"
          "  Path and base must both be relative, or both absolute.\n"
          "  Arguments: $_path.relativeTo($base)");
    }

    var basePath = base.toString();
    // Handle drive letters specially on Windows.
    if (base.isAbsolute && Platform.operatingSystem == 'windows') {
      var baseHasDrive =
          basePath.length >= 4 && basePath[2] == ':' && basePath[3] == '/';
      var pathHasDrive =
          _path.length >= 4 && _path[2] == ':' && _path[3] == '/';
      if (baseHasDrive && pathHasDrive) {
        var baseDrive = basePath.codeUnitAt(1) | 32; // Convert to uppercase.
        if (baseDrive >= 'a'.codeUnitAt(0) &&
            baseDrive <= 'z'.codeUnitAt(0) &&
            baseDrive == (_path.codeUnitAt(1) | 32)) {
          if (basePath[1] != _path[1]) {
            // Replace the drive letter in basePath with that from _path.
            basePath = '/${_path[1]}:/${basePath.substring(4)}';
            base = Path(basePath);
          }
        } else {
          throw ArgumentError("Invalid case of Path.relativeTo(base):\n"
              "  Base path and target path are on different Windows drives.\n"
              "  Arguments: $_path.relativeTo($base)");
        }
      } else if (baseHasDrive != pathHasDrive) {
        throw ArgumentError("Invalid case of Path.relativeTo(base):\n"
            "  Base path must start with a drive letter if and "
            "only if target path does.\n"
            "  Arguments: $_path.relativeTo($base)");
      }
    }
    if (_path.startsWith(basePath)) {
      if (_path == basePath) return Path('.');
      // There must be a '/' at the end of the match, or immediately after.
      var matchEnd = basePath.length;
      if (_path[matchEnd - 1] == '/' || _path[matchEnd] == '/') {
        // Drop any extra '/' characters at matchEnd
        while (matchEnd < _path.length && _path[matchEnd] == '/') {
          matchEnd++;
        }
        return Path(_path.substring(matchEnd)).canonicalize();
      }
    }

    var baseSegments = base.canonicalize().segments();
    var pathSegments = canonicalize().segments();
    if (baseSegments.length == 1 && baseSegments[0] == '.') {
      baseSegments = [];
    }
    if (pathSegments.length == 1 && pathSegments[0] == '.') {
      pathSegments = [];
    }
    var common = 0;
    var length = min(pathSegments.length, baseSegments.length);
    while (common < length && pathSegments[common] == baseSegments[common]) {
      common++;
    }
    final segments = <String>[];

    if (common < baseSegments.length && baseSegments[common] == '..') {
      throw ArgumentError("Invalid case of Path.relativeTo(base):\n"
          "  Base path has more '..'s than path does.\n"
          "  Arguments: $_path.relativeTo($base)");
    }
    for (var i = common; i < baseSegments.length; i++) {
      segments.add('..');
    }
    for (var i = common; i < pathSegments.length; i++) {
      segments.add('${pathSegments[i]}');
    }
    if (segments.isEmpty) {
      segments.add('.');
    }
    if (hasTrailingSeparator) {
      segments.add('');
    }
    return Path(segments.join('/'));
  }

  Path join(Path further) {
    if (further.isAbsolute) {
      throw ArgumentError("Path.join called with absolute Path as argument.");
    }
    if (isEmpty) {
      return further.canonicalize();
    }
    if (hasTrailingSeparator) {
      var joined = Path._internal('$_path$further', isWindowsShare);
      return joined.canonicalize();
    }
    var joined = Path._internal('$_path/$further', isWindowsShare);
    return joined.canonicalize();
  }

  // Note: The URI RFC names for canonicalize, join, and relativeTo
  // are normalize, resolve, and relativize.  But resolve and relativize
  // drop the last segment of the base path (the filename), on URIs.
  Path canonicalize() {
    if (isCanonical) return this;
    return makeCanonical();
  }

  bool get isCanonical {
    // Contains no consecutive path separators.
    // Contains no segments that are '.'.
    // Absolute paths have no segments that are '..'.
    // All '..' segments of a relative path are at the beginning.
    if (isEmpty) return false; // The canonical form of '' is '.'.
    if (_path == '.') return true;
    var segs = _path.split('/'); // Don't mask the getter 'segments'.
    if (segs[0] == '') {
      // Absolute path
      segs[0] = null; // Faster than removeRange().
    } else {
      // A canonical relative path may start with .. segments.
      for (var pos = 0; pos < segs.length && segs[pos] == '..'; ++pos) {
        segs[pos] = null;
      }
    }
    if (segs.last == '') segs.removeLast(); // Path ends with /.
    // No remaining segments can be ., .., or empty.
    return !segs.any((s) => s == '' || s == '.' || s == '..');
  }

  Path makeCanonical() {
    var isAbs = isAbsolute;
    var segs = segments();
    String drive;
    if (isAbs && segs.isNotEmpty && segs[0].length == 2 && segs[0][1] == ':') {
      drive = segs[0];
      segs.removeRange(0, 1);
    }
    var newSegs = <String>[];
    for (var segment in segs) {
      switch (segment) {
        case '..':
          // Absolute paths drop leading .. markers, including after a drive.
          if (newSegs.isEmpty) {
            if (isAbs) {
              // Do nothing: drop the segment.
            } else {
              newSegs.add('..');
            }
          } else if (newSegs.last == '..') {
            newSegs.add('..');
          } else {
            newSegs.removeLast();
          }
          break;
        case '.':
        case '':
          // Do nothing - drop the segment.
          break;
        default:
          newSegs.add(segment);
          break;
      }
    }

    var segmentsToJoin = <String>[];
    if (isAbs) {
      segmentsToJoin.add('');
      if (drive != null) {
        segmentsToJoin.add(drive);
      }
    }

    if (newSegs.isEmpty) {
      if (isAbs) {
        segmentsToJoin.add('');
      } else {
        segmentsToJoin.add('.');
      }
    } else {
      segmentsToJoin.addAll(newSegs);
      if (hasTrailingSeparator) {
        segmentsToJoin.add('');
      }
    }
    return Path._internal(segmentsToJoin.join('/'), isWindowsShare);
  }

  String toNativePath() {
    if (isEmpty) return '.';
    if (Platform.operatingSystem == 'windows') {
      var nativePath = _path;
      // Drop '/' before a drive letter.
      if (nativePath.length >= 3 &&
          nativePath.startsWith('/') &&
          nativePath[2] == ':') {
        nativePath = nativePath.substring(1);
      }
      nativePath = nativePath.replaceAll('/', '\\');
      if (isWindowsShare) {
        return '\\$nativePath';
      }
      return nativePath;
    }
    return _path;
  }

  List<String> segments() {
    var result = _path.split('/');
    if (isAbsolute) result.removeRange(0, 1);
    if (hasTrailingSeparator) result.removeLast();
    return result;
  }

  Path append(String finalSegment) {
    if (isEmpty) {
      return Path._internal(finalSegment, isWindowsShare);
    } else if (hasTrailingSeparator) {
      return Path._internal('$_path$finalSegment', isWindowsShare);
    } else {
      return Path._internal('$_path/$finalSegment', isWindowsShare);
    }
  }

  String get filenameWithoutExtension {
    var name = filename;
    if (name == '.' || name == '..') return name;
    var pos = name.lastIndexOf('.');
    return (pos < 0) ? name : name.substring(0, pos);
  }

  String get extension {
    var name = filename;
    var pos = name.lastIndexOf('.');
    return (pos < 0) ? '' : name.substring(pos + 1);
  }

  Path get directoryPath {
    var pos = _path.lastIndexOf('/');
    if (pos < 0) return Path('');
    while (pos > 0 && _path[pos - 1] == '/') {
      --pos;
    }
    var dirPath = (pos > 0) ? _path.substring(0, pos) : '/';
    return Path._internal(dirPath, isWindowsShare);
  }

  String get filename {
    var pos = _path.lastIndexOf('/');
    return _path.substring(pos + 1);
  }
}
