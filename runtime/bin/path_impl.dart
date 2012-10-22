// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Path implements Path {
  final String _path;

  _Path(String source) : _path = source;
  _Path.fromNative(String source) : _path = _clean(source);

  int get hashCode => _path.hashCode;

  static String _clean(String source) {
    switch (Platform.operatingSystem) {
      case 'windows':
        return _cleanWindows(source);
      default:
        return source;
    }
  }

  static String _cleanWindows(source) {
    // Change \ to /.
    var clean = source.replaceAll('\\', '/');
    // Add / before intial [Drive letter]:
    if (clean.length >= 2 && clean[1] == ':') {
      clean = '/$clean';
    }
    return clean;
  }

  bool get isEmpty => _path.isEmpty();
  bool get isAbsolute => _path.startsWith('/');
  bool get hasTrailingSeparator => _path.endsWith('/');

  String toString() => _path;

  Path relativeTo(Path base) {
    // Throws exception if an unimplemented or impossible case is reached.
    // Returns a path "relative" such that
    //    base.join(relative) == this.canonicalize.
    // Throws an exception if no such path exists, or the case is not
    // implemented yet.
    if (base.isAbsolute && _path.startsWith(base._path)) {
      if (_path == base._path) return new Path('.');
      if (base.hasTrailingSeparator) {
        return new Path(_path.substring(base._path.length));
      }
      if (_path[base._path.length] == '/') {
        return new Path(_path.substring(base._path.length + 1));
      }
    } else if (base.isAbsolute && isAbsolute) {
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
      sb.add('${pathSegments.last()}');
      if (hasTrailingSeparator) {
        sb.add('/');
      }
      return new Path(sb.toString());
    }
    throw new NotImplementedException(
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
      return new Path('$_path${further._path}').canonicalize();
    }
    return new Path('$_path/${further._path}').canonicalize();
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
    if (segs.last() == '') segs.removeLast();  // Path ends with /.
    // No remaining segments can be ., .., or empty.
    return !segs.some((s) => s == '' || s == '.' || s == '..');
  }

  Path makeCanonical() {
    bool isAbs = isAbsolute;
    List segs = segments();
    String drive;
    if (isAbs &&
        !segs.isEmpty() &&
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
          if (newSegs.isEmpty()) {
            if (isAbs) {
              // Do nothing: drop the segment.
            } else {
              newSegs.add('..');
            }
          } else if (newSegs.last() == '..') {
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

    if (newSegs.isEmpty()) {
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
    return new Path(Strings.join(segmentsToJoin, '/'));
  }

  String toNativePath() {
    if (Platform.operatingSystem == 'windows') {
      String nativePath = _path;
      // Drop '/' before a drive letter.
      if (nativePath.length > 3 &&
          nativePath.startsWith('/') &&
          nativePath[2] == ':') {
        nativePath = nativePath.substring(1);
      }
      nativePath = nativePath.replaceAll('/', '\\');
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
      return new Path(finalSegment);
    } else if (hasTrailingSeparator) {
      return new Path('$_path$finalSegment');
    } else {
      return new Path('$_path/$finalSegment');
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
    return new Path((pos > 0) ? _path.substring(0, pos) : '/');
  }

  String get filename {
    int pos = _path.lastIndexOf('/');
    return _path.substring(pos + 1);
  }
}
