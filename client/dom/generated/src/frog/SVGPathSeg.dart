
class SVGPathSeg native "SVGPathSeg" {

  static final int PATHSEG_ARC_ABS = 10;

  static final int PATHSEG_ARC_REL = 11;

  static final int PATHSEG_CLOSEPATH = 1;

  static final int PATHSEG_CURVETO_CUBIC_ABS = 6;

  static final int PATHSEG_CURVETO_CUBIC_REL = 7;

  static final int PATHSEG_CURVETO_CUBIC_SMOOTH_ABS = 16;

  static final int PATHSEG_CURVETO_CUBIC_SMOOTH_REL = 17;

  static final int PATHSEG_CURVETO_QUADRATIC_ABS = 8;

  static final int PATHSEG_CURVETO_QUADRATIC_REL = 9;

  static final int PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS = 18;

  static final int PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL = 19;

  static final int PATHSEG_LINETO_ABS = 4;

  static final int PATHSEG_LINETO_HORIZONTAL_ABS = 12;

  static final int PATHSEG_LINETO_HORIZONTAL_REL = 13;

  static final int PATHSEG_LINETO_REL = 5;

  static final int PATHSEG_LINETO_VERTICAL_ABS = 14;

  static final int PATHSEG_LINETO_VERTICAL_REL = 15;

  static final int PATHSEG_MOVETO_ABS = 2;

  static final int PATHSEG_MOVETO_REL = 3;

  static final int PATHSEG_UNKNOWN = 0;

  int pathSegType;

  String pathSegTypeAsLetter;

  var dartObjectLocalStorage;

  String get typeName() native;
}
