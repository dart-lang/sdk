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
    if (!dart.is(a, core.num)) throw new core.ArgumentError(a);
    if (!dart.is(b, core.num)) throw new core.ArgumentError(b);
    if (dart.notNull(a) > dart.notNull(b)) return b;
    if (dart.notNull(a) < dart.notNull(b)) return a;
    if (typeof b == "number") {
      if (typeof a == "number") {
        if (a === 0.0) {
          return dart.notNull(dart.notNull((dart.notNull(a) + dart.notNull(b))) * dart.notNull(a)) * dart.notNull(b);
        }
      }
      if (dart.notNull(dart.notNull(a === 0) && dart.notNull(b.isNegative)) || dart.notNull(b.isNaN)) return b;
      return a;
    }
    return a;
  }

  // Function max: (num, num) → num
  function max(a, b) {
    if (!dart.is(a, core.num)) throw new core.ArgumentError(a);
    if (!dart.is(b, core.num)) throw new core.ArgumentError(b);
    if (dart.notNull(a) > dart.notNull(b)) return a;
    if (dart.notNull(a) < dart.notNull(b)) return b;
    if (typeof b == "number") {
      if (typeof a == "number") {
        if (a === 0.0) {
          return dart.notNull(a) + dart.notNull(b);
        }
      }
      if (b.isNaN) return b;
      return a;
    }
    if (dart.notNull(b === 0) && dart.notNull(a.isNegative)) return b;
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
  class _JenkinsSmiHash extends dart.Object {
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
    static hash2(a, b) { return finish(combine(combine(0, dart.as(a, core.int)), dart.as(b, core.int))); }
    static hash4(a, b, c, d) { return finish(combine(combine(combine(combine(0, dart.as(a, core.int)), dart.as(b, core.int)), dart.as(c, core.int)), dart.as(d, core.int))); }
  }

  let Point$ = dart.generic(function(T) {
    class Point extends dart.Object {
      Point(x, y) {
        this.x = x;
        this.y = y;
      }
      toString() { return `Point(${this.x}, ${this.y})`; }
      ['=='](other) {
        if (!dart.is(other, Point)) return false;
        return dart.notNull(dart.equals(this.x, dart.dload(other, "x"))) && dart.notNull(dart.equals(this.y, dart.dload(other, "y")));
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
      get magnitude() { return sqrt(dart.notNull(this.x['*'](this.x)) + dart.notNull(this.y['*'](this.y))); }
      distanceTo(other) {
        let dx = this.x['-'](other.x);
        let dy = this.y['-'](other.y);
        return sqrt(dart.notNull(dart.notNull(dx) * dart.notNull(dx)) + dart.notNull(dart.notNull(dy) * dart.notNull(dy)));
      }
      squaredDistanceTo(other) {
        let dx = this.x['-'](other.x);
        let dy = this.y['-'](other.y);
        return dart.as(dart.notNull(dart.notNull(dx) * dart.notNull(dx)) + dart.notNull(dart.notNull(dy) * dart.notNull(dy)), T);
      }
    }
    return Point;
  });
  let Point = Point$(dynamic);

  class Random extends dart.Object {
    /* Unimplemented external factory Random([int seed]); */
  }

  let _RectangleBase$ = dart.generic(function(T) {
    class _RectangleBase extends dart.Object {
      _RectangleBase() {
      }
      get right() { return dart.as(this.left['+'](this.width), T); }
      get bottom() { return dart.as(this.top['+'](this.height), T); }
      toString() {
        return `Rectangle (${this.left}, ${this.top}) ${this.width} x ${this.height}`;
      }
      ['=='](other) {
        if (!dart.is(other, Rectangle)) return false;
        return dart.notNull(dart.notNull(dart.notNull(dart.equals(this.left, dart.dload(other, "left"))) && dart.notNull(dart.equals(this.top, dart.dload(other, "top")))) && dart.notNull(dart.equals(this.right, dart.dload(other, "right")))) && dart.notNull(dart.equals(this.bottom, dart.dload(other, "bottom")));
      }
      get hashCode() { return _JenkinsSmiHash.hash4(this.left.hashCode, this.top.hashCode, this.right.hashCode, this.bottom.hashCode); }
      intersection(other) {
        let x0 = max(this.left, other.left);
        let x1 = min(this.left['+'](this.width), other.left['+'](other.width));
        if (dart.notNull(x0) <= dart.notNull(x1)) {
          let y0 = max(this.top, other.top);
          let y1 = min(this.top['+'](this.height), other.top['+'](other.height));
          if (dart.notNull(y0) <= dart.notNull(y1)) {
            return new Rectangle(x0, y0, dart.notNull(x1) - dart.notNull(x0), dart.notNull(y1) - dart.notNull(y0));
          }
        }
        return null;
      }
      intersects(other) {
        return (dart.notNull(dart.notNull(dart.notNull(this.left['<='](dart.notNull(other.left) + dart.notNull(other.width))) && dart.notNull(dart.notNull(other.left) <= dart.notNull(this.left['+'](this.width)))) && dart.notNull(this.top['<='](dart.notNull(other.top) + dart.notNull(other.height)))) && dart.notNull(dart.notNull(other.top) <= dart.notNull(this.top['+'](this.height))));
      }
      boundingBox(other) {
        let right = max(this.left['+'](this.width), other.left['+'](other.width));
        let bottom = max(this.top['+'](this.height), other.top['+'](other.height));
        let left = min(this.left, other.left);
        let top = min(this.top, other.top);
        return new Rectangle(left, top, dart.notNull(right) - dart.notNull(left), dart.notNull(bottom) - dart.notNull(top));
      }
      containsRectangle(another) {
        return dart.notNull(dart.notNull(dart.notNull(this.left['<='](another.left)) && dart.notNull(dart.notNull(this.left['+'](this.width)) >= dart.notNull(dart.notNull(another.left) + dart.notNull(another.width)))) && dart.notNull(this.top['<='](another.top))) && dart.notNull(dart.notNull(this.top['+'](this.height)) >= dart.notNull(dart.notNull(another.top) + dart.notNull(another.height)));
      }
      containsPoint(another) {
        return dart.notNull(dart.notNull(dart.notNull(core.num['>='](another.x, this.left)) && dart.notNull(dart.notNull(another.x) <= dart.notNull(this.left['+'](this.width)))) && dart.notNull(core.num['>='](another.y, this.top))) && dart.notNull(dart.notNull(another.y) <= dart.notNull(this.top['+'](this.height)));
      }
      get topLeft() { return new Point(this.left, this.top); }
      get topRight() { return new Point(this.left['+'](this.width), this.top); }
      get bottomRight() { return new Point(this.left['+'](this.width), this.top['+'](this.height)); }
      get bottomLeft() { return new Point(this.left, this.top['+'](this.height)); }
    }
    return _RectangleBase;
  });
  let _RectangleBase = _RectangleBase$(dynamic);

  let Rectangle$ = dart.generic(function(T) {
    class Rectangle extends _RectangleBase$(T) {
      Rectangle(left, top, width, height) {
        this.left = left;
        this.top = top;
        this.width = (width['<'](0)) ? dart.notNull(/* Unimplemented postfix operator: -width */) * 0 : width;
        this.height = (height['<'](0)) ? dart.notNull(/* Unimplemented postfix operator: -height */) * 0 : height;
        super._RectangleBase();
      }
      Rectangle$fromPoints(a, b) {
        let left = dart.as(min(a.x, b.x), T);
        let width = dart.as(core.num['-'](max(a.x, b.x), left), T);
        let top = dart.as(min(a.y, b.y), T);
        let height = dart.as(core.num['-'](max(a.y, b.y), top), T);
        return new Rectangle(left, top, width, height);
      }
    }
    dart.defineNamedConstructor(Rectangle, "fromPoints");
    return Rectangle;
  });
  let Rectangle = Rectangle$(dynamic);

  let MutableRectangle$ = dart.generic(function(T) {
    class MutableRectangle extends _RectangleBase$(T) {
      MutableRectangle(left, top, width, height) {
        this.left = left;
        this.top = top;
        this._width = (width['<'](0)) ? _clampToZero(width) : width;
        this._height = (height['<'](0)) ? _clampToZero(height) : height;
        super._RectangleBase();
      }
      MutableRectangle$fromPoints(a, b) {
        let left = dart.as(min(a.x, b.x), T);
        let width = dart.as(core.num['-'](max(a.x, b.x), left), T);
        let top = dart.as(min(a.y, b.y), T);
        let height = dart.as(core.num['-'](max(a.y, b.y), top), T);
        return new MutableRectangle(left, top, width, height);
      }
      get width() { return this._width; }
      set width(width) {
        if (width['<'](0)) width = dart.as(_clampToZero(width), T);
        this._width = width;
      }
      get height() { return this._height; }
      set height(height) {
        if (height['<'](0)) height = dart.as(_clampToZero(height), T);
        this._height = height;
      }
    }
    dart.defineNamedConstructor(MutableRectangle, "fromPoints");
    return MutableRectangle;
  });
  let MutableRectangle = MutableRectangle$(dynamic);

  // Function _clampToZero: (num) → num
  function _clampToZero(value) {
    dart.assert(dart.notNull(value) < 0);
    return dart.notNull(-dart.notNull(value)) * 0;
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
  math.Point$ = Point$;
  math.Random = Random;
  math.Rectangle = Rectangle;
  math.Rectangle$ = Rectangle$;
  math.MutableRectangle = MutableRectangle;
  math.MutableRectangle$ = MutableRectangle$;
})(math || (math = {}));
