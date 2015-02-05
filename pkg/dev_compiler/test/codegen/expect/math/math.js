var math;
(function (math) {
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
    if (/* Unimplemented IsExpression: a is! num */) throw new core.ArgumentError(a);
    if (/* Unimplemented IsExpression: b is! num */) throw new core.ArgumentError(b);
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
    if (/* Unimplemented IsExpression: a is! num */) throw new core.ArgumentError(a);
    if (/* Unimplemented IsExpression: b is! num */) throw new core.ArgumentError(b);
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

  /* Unimplemented external double atan2(num a, num b) ; */
  /* Unimplemented external num pow(num x, num exponent) ; */
  /* Unimplemented external double sin(num x) ; */
  /* Unimplemented external double cos(num x) ; */
  /* Unimplemented external double tan(num x) ; */
  /* Unimplemented external double acos(num x) ; */
  /* Unimplemented external double asin(num x) ; */
  /* Unimplemented external double atan(num x) ; */
  /* Unimplemented external double sqrt(num x) ; */
  /* Unimplemented external double exp(num x) ; */
  /* Unimplemented external double log(num x) ; */
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

  class Point/* Unimplemented <T extends num> */ {
    constructor(x, y) {
      this.x = x;
      this.y = y;
    }
    toString() { return "Point(" + (this.x) + ", " + (this.y) + ")"; }
    ['=='](other) {
      if (/* Unimplemented IsExpression: other is! Point */) return false;
      return dart.equals(this.x, dart.dload(other, "x")) && dart.equals(this.y, dart.dload(other, "y"));
    }
    get hashCode() { return _JenkinsSmiHash.hash2(this.x.hashCode, this.y.hashCode); }
    ['+'](other) {
      return new Point(this.x['+'](other.x), this.y['+'](other.y));
    }
    ['-'](other) {
      return new Point(this.x['-'](other.x), this.y['-'](other.y));
    }
    ['*'](factor) {
      return new Point(this.x['*'](factor), this.y['*'](factor));
    }
    get magnitude() { return sqrt(this.x['*'](this.x) + this.y['*'](this.y)); }
    distanceTo(other) {
      let dx = this.x['-'](other.x);
      let dy = this.y['-'](other.y);
      return sqrt(dx * dx + dy * dy);
    }
    squaredDistanceTo(other) {
      let dx = this.x['-'](other.x);
      let dy = this.y['-'](other.y);
      return /* Unimplemented: DownCast: num to T */ dx * dx + dy * dy;
    }
  }

  class Random {
    /* Unimplemented external factory Random([int seed]); */
  }

  class _RectangleBase/* Unimplemented <T extends num> */ {
    constructor() {
    }
    get right() { return /* Unimplemented: DownCast: num to T */ this.left['+'](this.width); }
    get bottom() { return /* Unimplemented: DownCast: num to T */ this.top['+'](this.height); }
    toString() {
      return "Rectangle (" + (this.left) + ", " + (this.top) + ") " + (this.width) + " x " + (this.height) + "";
    }
    ['=='](other) {
      if (/* Unimplemented IsExpression: other is! Rectangle */) return false;
      return dart.equals(this.left, dart.dload(other, "left")) && dart.equals(this.top, dart.dload(other, "top")) && dart.equals(this.right, dart.dload(other, "right")) && dart.equals(this.bottom, dart.dload(other, "bottom"));
    }
    get hashCode() { return _JenkinsSmiHash.hash4(this.left.hashCode, this.top.hashCode, this.right.hashCode, this.bottom.hashCode); }
    intersection(other) {
      let x0 = max(this.left, other.left);
      let x1 = min(this.left['+'](this.width), other.left['+'](other.width));
      if (x0 <= x1) {
        let y0 = max(this.top, other.top);
        let y1 = min(this.top['+'](this.height), other.top['+'](other.height));
        if (y0 <= y1) {
          return new Rectangle(x0, y0, x1 - x0, y1 - y0);
        }
      }
      return null;
    }
    intersects(other) {
      return (this.left['<='](other.left + other.width) && other.left <= this.left['+'](this.width) && this.top['<='](other.top + other.height) && other.top <= this.top['+'](this.height));
    }
    boundingBox(other) {
      let right = max(this.left['+'](this.width), other.left['+'](other.width));
      let bottom = max(this.top['+'](this.height), other.top['+'](other.height));
      let left = min(this.left, other.left);
      let top = min(this.top, other.top);
      return new Rectangle(left, top, right - left, bottom - top);
    }
    containsRectangle(another) {
      return this.left['<='](another.left) && this.left['+'](this.width) >= another.left + another.width && this.top['<='](another.top) && this.top['+'](this.height) >= another.top + another.height;
    }
    containsPoint(another) {
      return core.num['>='](another.x, this.left) && another.x <= this.left['+'](this.width) && core.num['>='](another.y, this.top) && another.y <= this.top['+'](this.height);
    }
    get topLeft() { return new Point(this.left, this.top); }
    get topRight() { return new Point(this.left['+'](this.width), this.top); }
    get bottomRight() { return new Point(this.left['+'](this.width), this.top['+'](this.height)); }
    get bottomLeft() { return new Point(this.left, this.top['+'](this.height)); }
  }

  class Rectangle/* Unimplemented <T extends num> */ extends _RectangleBase/* Unimplemented <T> */ {
    constructor(left, top, width, height) {
      this.left = left;
      this.top = top;
      this.width = (width['<'](0)) ? /* Unimplemented postfix operator: -width */ * 0 : width;
      this.height = (height['<'](0)) ? /* Unimplemented postfix operator: -height */ * 0 : height;
      super();
    }
    /*constructor*/ fromPoints(a, b) {
      let left = /* Unimplemented: DownCast: num to T */ min(a.x, b.x);
      let width = /* Unimplemented: DownCast: num to T */ core.num['-'](max(a.x, b.x), left);
      let top = /* Unimplemented: DownCast: num to T */ min(a.y, b.y);
      let height = /* Unimplemented: DownCast: num to T */ core.num['-'](max(a.y, b.y), top);
      return new Rectangle(left, top, width, height);
    }
  }
  dart.defineNamedConstructor(Rectangle, "fromPoints");

  class MutableRectangle/* Unimplemented <T extends num> */ extends _RectangleBase/* Unimplemented <T> */ {
    constructor(left, top, width, height) {
      this.left = left;
      this.top = top;
      this._width = (width['<'](0)) ? _clampToZero(width) : width;
      this._height = (height['<'](0)) ? _clampToZero(height) : height;
      super();
    }
    /*constructor*/ fromPoints(a, b) {
      let left = /* Unimplemented: DownCast: num to T */ min(a.x, b.x);
      let width = /* Unimplemented: DownCast: num to T */ core.num['-'](max(a.x, b.x), left);
      let top = /* Unimplemented: DownCast: num to T */ min(a.y, b.y);
      let height = /* Unimplemented: DownCast: num to T */ core.num['-'](max(a.y, b.y), top);
      return new MutableRectangle(left, top, width, height);
    }
    get width() { return this._width; }
    set width(width) {
      if (width['<'](0)) width = /* Unimplemented: DownCast: num to T */ _clampToZero(width);
      this._width = width;
    }
    get height() { return this._height; }
    set height(height) {
      if (height['<'](0)) height = /* Unimplemented: DownCast: num to T */ _clampToZero(height);
      this._height = height;
    }
  }
  dart.defineNamedConstructor(MutableRectangle, "fromPoints");

  // Function _clampToZero: (num) → num
  function _clampToZero(value) {
    dart.assert(value < 0);
    return -value * 0;
  }

  // Exports:
  math.E = E;
  math.LN10 = LN10;
  math.LN2 = LN2;
  math.LOG2E = LOG2E;
  math.LOG10E = LOG10E;
  math.PI = PI;
  math.SQRT1_2 = SQRT1_2;
  math.SQRT2 = SQRT2;
  math.min = min;
  math.max = max;
  math.Point = Point;
  math.Random = Random;
  math.Rectangle = Rectangle;
  math.MutableRectangle = MutableRectangle;
})(math || (math = {}));
