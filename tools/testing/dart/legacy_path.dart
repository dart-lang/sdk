// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of utils;

class Path {
  final String _path;
  final bool isWindowsShare;

  Path(String source)
      : _path = _clean(source), isWindowsShare = _isWindowsShare(source);

  Path.raw(String source) : _path = source, isWindowsShare = false;

  Path._internal(String this._path, bool this.isWindowsShare);

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
    // Add / before intial [Drive letter]:
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

  int get hashCode => _path.hashCode;
  bool get isEmpty => _path.isEmpty;
  bool get isAbsolute => _path.startsWith('/');
  bool get hasTrailingSeparator => _path.endsWith('/');

  String toString() => _path;

  Path relativeTo(Path base) {
    // Returns a path "relative" such that
    // base.join(relative) == this.canonicalize.
    // Throws exception if an impossible case is reached.
    if (base.isAbsolute != isAbsolute ||
        base.isWindowsShare != isWindowsShare) {
      throw new ArgumentError(
          "Invalid case of Path.relativeTo(base):\n"
          "  Path and base must both be relative, or both absolute.\n"
          "  Arguments: $_path.relativeTo($base)");
    }

    var basePath = base.toString();
    // Handle drive letters specially on Windows.
    if (base.isAbsolute && Platform.operatingSystem == 'windows') {
      bool baseHasDrive =
          basePath.length >= 4 && basePath[2] == ':' && basePath[3] == '/';
      bool pathHasDrive =
          _path.length >= 4 && _path[2] == ':' && _path[3] == '/';
      if (baseHasDrive && pathHasDrive) {
        int baseDrive = basePath.codeUnitAt(1) | 32;  // Convert to uppercase.
        if (baseDrive >= 'a'.codeUnitAt(0) &&
            baseDrive <= 'z'.codeUnitAt(0) &&
            baseDrive == (_path.codeUnitAt(1) | 32)) {
          if(basePath[1] != _path[1]) {
            // Replace the drive letter in basePath with that from _path.
            basePath = '/${_path[1]}:/${basePath.substring(4)}';
            base = new Path(basePath);
          }
        } else {
          throw new ArgumentError(
              "Invalid case of Path.relativeTo(base):\n"
              "  Base path and target path are on different Windows drives.\n"
              "  Arguments: $_path.relativeTo($base)");
        }
      } else if (baseHasDrive != pathHasDrive) {
        throw new ArgumentError(
            "Invalid case of Path.relativeTo(base):\n"
            "  Base path must start with a drive letter if and "
            "only if target path does.\n"
            "  Arguments: $_path.relativeTo($base)");
      }

    }
    if (_path.startsWith(basePath)) {
      if (_path == basePath) return new Path('.');
      // There must be a '/' at the end of the match, or immediately after.
      int matchEnd = basePath.length;
      if (_path[matchEnd - 1] == '/' || _path[matchEnd] == '/') {
        // Drop any extra '/' characters at matchEnd
        while (matchEnd < _path.length && _path[matchEnd] == '/') {
          matchEnd++;
        }
        return new Path(_path.substring(matchEnd)).canonicalize();
      }
    }

    List<String> baseSegments = base.canonicalize().segments();
    List<String> pathSegments = canonicalize().segments();
    if (baseSegments.length == 1 && baseSegments[0] == '.') {
      baseSegments = [];
    }
    if (pathSegments.length == 1 && pathSegments[0] == '.') {
      pathSegments = [];
    }
    int common = 0;
    int length = min(pathSegments.length, baseSegments.length);
    while (common < length && pathSegments[common] == baseSegments[common]) {
      common++;
    }
    final segments = new List<String>();

    if (common < baseSegments.length && baseSegments[common] == '..') {
      throw new ArgumentError(
          "Invalid case of Path.relativeTo(base):\n"
          "  Base path has more '..'s than path does.\n"
          "  Arguments: $_path.relativeTo($base)");
    }
    for (int i = common; i < baseSegments.length; i++) {
      segments.add('..');
    }
    for (int i = common; i < pathSegments.length; i++) {
      segments.add('${pathSegments[i]}');
    }
    if (segments.isEmpty) {
      segments.add('.');
    }
    if (hasTrailingSeparator) {
        segments.add('');
    }
    return new Path(segments.join('/'));
  }


  Path join(Path further) {
    if (further.isAbsolute) {
      throw new ArgumentError(
          "Path.join called with absolute Path as argument.");
    }
    if (isEmpty) {
      return further.canonicalize();
    }
    if (hasTrailingSeparator) {
      var joined = new Path._internal('$_path${further}', isWindowsShare);
      return joined.canonicalize();
    }
    var joined = new Path._internal('$_path/${further}', isWindowsShare);
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
    if (isEmpty) return false;  // The canonical form of '' is '.'.
    if (_path == '.') return true;
    List segs = _path.split('/');  // Don't mask the getter 'segments'.
    if (segs[0] == '') {  // Absolute path
      segs[0] = null;  // Faster than removeRange().
    } else {  // A canonical relative path may start with .. segments.
      for (int pos = 0;
           pos < segs.length && segs[pos] == '..';
           ++pos) {
        segs[pos] = null;
      }
    }
    if (segs.last == '') segs.removeLast();  // Path ends with /.
    // No remaining segments can be ., .., or empty.
    return !segs.any((s) => s == '' || s == '.' || s == '..');
  }

  Path makeCanonical() {
    bool isAbs = isAbsolute;
    List segs = segments();
    String drive;
    if (isAbs &&
        !segs.isEmpty &&
        segs[0].length == 2 &&
        segs[0][1] == ':') {
      drive = segs[0];
      segs.removeRange(0, 1);
    }
    List newSegs = [];
    for (String segment in segs) {
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

    List segmentsToJoin = [];
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
    return new Path._internal(segmentsToJoin.join('/'), isWindowsShare);
  }

  String toNativePath() {
    if (isEmpty) return '.';
    if (Platform.operatingSystem == 'windows') {
      String nativePath = _path;
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
    List result = _path.split('/');
    if (isAbsolute) result.removeRange(0, 1);
    if (hasTrailingSeparator) result.removeLast();
    return result;
  }

  Path append(String finalSegment) {
    if (isEmpty) {
      return new Path._internal(finalSegment, isWindowsShare);
    } else if (hasTrailingSeparator) {
      return new Path._internal('$_path$finalSegment', isWindowsShare);
    } else {
      return new Path._internal('$_path/$finalSegment', isWindowsShare);
    }
  }

  String get filenameWithoutExtension {
    var name = filename;
    if (name == '.' || name == '..') return name;
    int pos = name.lastIndexOf('.');
    return (pos < 0) ? name : name.substring(0, pos);
  }

  String get extension {
    var name = filename;
    int pos = name.lastIndexOf('.');
    return (pos < 0) ? '' : name.substring(pos + 1);
  }

  Path get directoryPath {
    int pos = _path.lastIndexOf('/');
    if (pos < 0) return new Path('');
    while (pos > 0 && _path[pos - 1] == '/') --pos;
    var dirPath = (pos > 0) ? _path.substring(0, pos) : '/';
    return new Path._internal(dirPath, isWindowsShare);
  }

  String get filename {
    int pos = _path.lastIndexOf('/');
    return _path.substring(pos + 1);
  }
}
