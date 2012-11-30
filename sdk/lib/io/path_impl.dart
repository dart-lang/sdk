// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Path implements Path {
  final String _path;
  final bool isWindowsShare;

  _Path(String source) : _path = source, isWindowsShare = false;

  _Path.fromNative(String source)
      : _path = _clean(source), isWindowsShare = _isWindowsShare(source);

  _Path._internal(String this._path, bool this.isWindowsShare);

  static String _clean(String source) {
    if (Platform.operatingSystem == 'windows') return _cleanWindows(source);
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
    // Throws exception if an unimplemented or impossible case is reached.
    // Returns a path "relative" such that
    //    base.join(relative) == this.canonicalize.
    // Throws an exception if no such path exists, or the case is not
    // implemented yet.
    var basePath = base.toString();
    if (base.isAbsolute && _path.startsWith(basePath) &&
        base.isWindowsShare == isWindowsShare) {
      if (_path == basePath) return new Path('.');
      if (base.hasTrailingSeparator) {
        return new Path(_path.substring(basePath.length));
      }
      if (_path[basePath.length] == '/') {
        return new Path(_path.substring(basePath.length + 1));
      }
    } else if (base.isAbsolute && isAbsolute &&
               base.isWindowsShare == isWindowsShare) {
      List<String> baseSegments = base.canonicalize().segments();
      List<String> pathSegments = canonicalize().segments();
      int common = 0;
      int length = min(pathSegments.length, baseSegments.length);
      while (common < length && pathSegments[common] == baseSegments[common]) {
        common++;
      }
      final sb = new StringBuffer();

      for (int i = common + 1; i < baseSegments.length; i++) {
        sb.add('../');
      }
      if (base.hasTrailingSeparator) {
        sb.add('../');
      }
      for (int i = common; i < pathSegments.length - 1; i++) {
        sb.add('${pathSegments[i]}/');
      }
      sb.add('${pathSegments.last}');
      if (hasTrailingSeparator) {
        sb.add('/');
      }
      return new Path(sb.toString());
    }
    throw new UnimplementedError(
      "Unimplemented case of Path.relativeTo(base):\n"
      "  Only absolute paths are handled at present.\n"
      "  Arguments: $_path.relativeTo($base)");
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
      var joined = new _Path._internal('$_path${further}', isWindowsShare);
      return joined.canonicalize();
    }
    var joined = new _Path._internal('$_path/${further}', isWindowsShare);
    return joined.canonicalize();
  }

  // Note: The URI RFC names for these operations are normalize, resolve, and
  // relativize.
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
    return !segs.some((s) => s == '' || s == '.' || s == '..');
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
    return new _Path._internal(Strings.join(segmentsToJoin, '/'),
                               isWindowsShare);
  }

  String toNativePath() {
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
      return new _Path._internal(finalSegment, isWindowsShare);
    } else if (hasTrailingSeparator) {
      return new _Path._internal('$_path$finalSegment', isWindowsShare);
    } else {
      return new _Path._internal('$_path/$finalSegment', isWindowsShare);
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
    return new _Path._internal(dirPath, isWindowsShare);
  }

  String get filename {
    int pos = _path.lastIndexOf('/');
    return _path.substring(pos + 1);
  }
}
