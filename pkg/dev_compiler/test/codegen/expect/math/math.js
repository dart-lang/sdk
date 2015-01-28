var dart.math;
(function (dart.math) {
  'use strict';
  let E = 2.718281828459045;
  let LN10 = 2.302585092994046;
  let LN2 = 0.6931471805599453;
  let LOG2E = 1.4426950408889634;
  let LOG10E = 0.4342944819032518;
  let PI = 3.141592653589793;
  let SQRT1_2 = 0.7071067811865476;
  let SQRT2 = 1.4142135623730951;
  // Function min: (num, num) → num
  function min(a, b) {
    if (/* Unimplemented IsExpression: a is! num */) throw new dart_core.ArgumentError(a);
    if (/* Unimplemented IsExpression: b is! num */) throw new dart_core.ArgumentError(b);
    if (a > b) return b;
    if (a < b) return a;
    if (/* Unimplemented IsExpression: b is double */) {
      if (/* Unimplemented IsExpression: a is double */) {
        if (a === 0.0) {
          return (a + b) * a * b;
        }
      }
      if (a === 0 && b.isNegative || b.isNaN) return b;
      return a;
    }
    return a;
  }

  // Function max: (num, num) → num
  function max(a, b) {
    if (/* Unimplemented IsExpression: a is! num */) throw new dart_core.ArgumentError(a);
    if (/* Unimplemented IsExpression: b is! num */) throw new dart_core.ArgumentError(b);
    if (a > b) return a;
    if (a < b) return b;
    if (/* Unimplemented IsExpression: b is double */) {
      if (/* Unimplemented IsExpression: a is double */) {
        if (a === 0.0) {
          return a + b;
        }
      }
      if (b.isNaN) return b;
      return a;
    }
    if (b === 0 && a.isNegative) return b;
    return a;
  }

  // Function atan2: (num, num) → double
  function atan2(a, b) {}

  // Function pow: (num, num) → num
  function pow(x, exponent) {}

  // Function sin: (num) → double
  function sin(x) {}

  // Function cos: (num) → double
  function cos(x) {}

  // Function tan: (num) → double
  function tan(x) {}

  // Function acos: (num) → double
  function acos(x) {}

  // Function asin: (num) → double
  function asin(x) {}

  // Function atan: (num) → double
  function atan(x) {}

  // Function sqrt: (num) → double
  function sqrt(x) {}

  // Function exp: (num) → double
  function exp(x) {}

  // Function log: (num) → double
  function log(x) {}

  class _JenkinsSmiHash {
    static combine(hash, value) {
      hash = 536870911 & (hash + value);
      hash = 536870911 & (hash + ((524287 & hash) << 10));
      return hash ^ (hash >> 6);
    }
    static finish(hash) {
      hash = 536870911 & (hash + ((67108863 & hash) << 3));
      hash = hash ^ (hash >> 11);
      return 536870911 & (hash + ((16383 & hash) << 15));
    }
    static hash2(a, b) { return finish(combine(combine(0, /* Unimplemented: DownCast: dynamic to int */ a), /* Unimplemented: DownCast: dynamic to int */ b)); }
    static hash4(a, b, c, d) { return finish(combine(combine(combine(combine(0, /* Unimplemented: DownCast: dynamic to int */ a), /* Unimplemented: DownCast: dynamic to int */ b), /* Unimplemented: DownCast: dynamic to int */ c), /* Unimplemented: DownCast: dynamic to int */ d)); }
  }

  class Point {
    constructor(x, y) {
      this.x = x;
      this.y = y;
    }
    toString() { return "Point(" + (this.x) + ", " + (this.y) + ")"; }
    ==(other) {
      if (/* Unimplemented IsExpression: other is! Point */) return false;
      return dart.equals(this.x, dart.dload(other, "x")) && dart.equals(this.y, dart.dload(other, "y"));
    }
    get hashCode() { return _JenkinsSmiHash.hash2(this.x.hashCode, this.y.hashCode); }
    +(other) {
      return new Point(/* Unimplemented binary operator: x + other.x */, /* Unimplemented binary operator: y + other.y */);
    }
    -(other) {
      return new Point(/* Unimplemented binary operator: x - other.x */, /* Unimplemented binary operator: y - other.y */);
    }
    *(factor) {
      return new Point(/* Unimplemented binary operator: x * factor */, /* Unimplemented binary operator: y * factor */);
    }
    get magnitude() { return sqrt(/* Unimplemented binary operator: x * x */ + /* Unimplemented binary operator: y * y */); }
    distanceTo(other) {
      let dx = /* Unimplemented binary operator: x - other.x */;
      let dy = /* Unimplemented binary operator: y - other.y */;
      return sqrt(dx * dx + dy * dy);
    }
    squaredDistanceTo(other) {
      let dx = /* Unimplemented binary operator: x - other.x */;
      let dy = /* Unimplemented binary operator: y - other.y */;
      return /* Unimplemented: DownCast: num to T */ dx * dx + dy * dy;
    }
  }

  class Random {
    constructor(seed) {
      if (seed === undefined) seed = null;
    }
  }

  class _RectangleBase {
    constructor() {
    }
    get right() { return /* Unimplemented: DownCast: num to T */ /* Unimplemented binary operator: left + width */; }
    get bottom() { return /* Unimplemented: DownCast: num to T */ /* Unimplemented binary operator: top + height */; }
    toString() {
      return "Rectangle (" + (this.left) + ", " + (this.top) + ") " + (this.width) + " x " + (this.height) + "";
    }
    ==(other) {
      if (/* Unimplemented IsExpression: other is! Rectangle */) return false;
      return dart.equals(this.left, dart.dload(other, "left")) && dart.equals(this.top, dart.dload(other, "top")) && dart.equals(this.right, dart.dload(other, "right")) && dart.equals(this.bottom, dart.dload(other, "bottom"));
    }
    get hashCode() { return _JenkinsSmiHash.hash4(this.left.hashCode, this.top.hashCode, this.right.hashCode, this.bottom.hashCode); }
    intersection(other) {
      let x0 = max(this.left, other.left);
      let x1 = min(/* Unimplemented binary operator: left + width */, /* Unimplemented binary operator: other.left + other.width */);
      if (x0 <= x1) {
        let y0 = max(this.top, other.top);
        let y1 = min(/* Unimplemented binary operator: top + height */, /* Unimplemented binary operator: other.top + other.height */);
        if (y0 <= y1) {
          return new Rectangle(x0, y0, x1 - x0, y1 - y0);
        }
      }
      return null;
    }
    intersects(other) {
      return (/* Unimplemented binary operator: left <= other.left + other.width */ && other.left <= /* Unimplemented binary operator: left + width */ && /* Unimplemented binary operator: top <= other.top + other.height */ && other.top <= /* Unimplemented binary operator: top + height */);
    }
    boundingBox(other) {
      let right = max(/* Unimplemented binary operator: this.left + this.width */, /* Unimplemented binary operator: other.left + other.width */);
      let bottom = max(/* Unimplemented binary operator: this.top + this.height */, /* Unimplemented binary operator: other.top + other.height */);
      let left = min(this.left, other.left);
      let top = min(this.top, other.top);
      return new Rectangle(left, top, right - left, bottom - top);
    }
    containsRectangle(another) {
      return /* Unimplemented binary operator: left <= another.left */ && /* Unimplemented binary operator: left + width */ >= another.left + another.width && /* Unimplemented binary operator: top <= another.top */ && /* Unimplemented binary operator: top + height */ >= another.top + another.height;
    }
    containsPoint(another) {
      return /* Unimplemented binary operator: another.x >= left */ && another.x <= /* Unimplemented binary operator: left + width */ && /* Unimplemented binary operator: another.y >= top */ && another.y <= /* Unimplemented binary operator: top + height */;
    }
    get topLeft() { return new Point(this.left, this.top); }
    get topRight() { return new Point(/* Unimplemented binary operator: this.left + this.width */, this.top); }
    get bottomRight() { return new Point(/* Unimplemented binary operator: this.left + this.width */, /* Unimplemented binary operator: this.top + this.height */); }
    get bottomLeft() { return new Point(this.left, /* Unimplemented binary operator: this.top + this.height */); }
  }

  class Rectangle extends _RectangleBase {
    constructor(left, top, width, height) {
      this.left = left;
      this.top = top;
      this.width = (/* Unimplemented binary operator: width < 0 */) ? /* Unimplemented postfix operator: -width */ * 0 : width;
      this.height = (/* Unimplemented binary operator: height < 0 */) ? /* Unimplemented postfix operator: -height */ * 0 : height;
      super();
    }
    __init_fromPoints(a, b) {
      let left = /* Unimplemented: DownCast: num to T */ min(a.x, b.x);
      let width = /* Unimplemented: DownCast: num to T */ /* Unimplemented binary operator: max(a.x, b.x) - left */;
      let top = /* Unimplemented: DownCast: num to T */ min(a.y, b.y);
      let height = /* Unimplemented: DownCast: num to T */ /* Unimplemented binary operator: max(a.y, b.y) - top */;
      return new Rectangle(left, top, width, height);
    }
  }
  Rectangle.fromPoints = function(a, b) { this.__init_fromPoints(a, b) };
  Rectangle.fromPoints.prototype = Rectangle.prototype;

  class MutableRectangle extends _RectangleBase {
    constructor(left, top, width, height) {
      this.left = left;
      this.top = top;
      this._width = (/* Unimplemented binary operator: width < 0 */) ? _clampToZero(width) : width;
      this._height = (/* Unimplemented binary operator: height < 0 */) ? _clampToZero(height) : height;
      super();
    }
    __init_fromPoints(a, b) {
      let left = /* Unimplemented: DownCast: num to T */ min(a.x, b.x);
      let width = /* Unimplemented: DownCast: num to T */ /* Unimplemented binary operator: max(a.x, b.x) - left */;
      let top = /* Unimplemented: DownCast: num to T */ min(a.y, b.y);
      let height = /* Unimplemented: DownCast: num to T */ /* Unimplemented binary operator: max(a.y, b.y) - top */;
      return new MutableRectangle(left, top, width, height);
    }
    get width() { return this._width; }
    set width(width) {
      if (/* Unimplemented binary operator: width < 0 */) width = /* Unimplemented: DownCast: num to T */ _clampToZero(width);
      this._width = width;
    }
    get height() { return this._height; }
    set height(height) {
      if (/* Unimplemented binary operator: height < 0 */) height = /* Unimplemented: DownCast: num to T */ _clampToZero(height);
      this._height = height;
    }
  }
  MutableRectangle.fromPoints = function(a, b) { this.__init_fromPoints(a, b) };
  MutableRectangle.fromPoints.prototype = MutableRectangle.prototype;

  // Function _clampToZero: (num) → num
  function _clampToZero(value) {
    /* Unimplemented AssertStatement: assert (value < 0); */return -value * 0;
  }

  // Exports:
  dart.math.E = E;
  dart.math.LN10 = LN10;
  dart.math.LN2 = LN2;
  dart.math.LOG2E = LOG2E;
  dart.math.LOG10E = LOG10E;
  dart.math.PI = PI;
  dart.math.SQRT1_2 = SQRT1_2;
  dart.math.SQRT2 = SQRT2;
  dart.math.min = min;
  dart.math.max = max;
  dart.math.atan2 = atan2;
  dart.math.pow = pow;
  dart.math.sin = sin;
  dart.math.cos = cos;
  dart.math.tan = tan;
  dart.math.acos = acos;
  dart.math.asin = asin;
  dart.math.atan = atan;
  dart.math.sqrt = sqrt;
  dart.math.exp = exp;
  dart.math.log = log;
  dart.math.Point = Point;
  dart.math.Random = Random;
  dart.math.Rectangle = Rectangle;
  dart.math.MutableRectangle = MutableRectangle;
})(dart.math || (dart.math = {}));
