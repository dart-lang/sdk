var math;
(function(exports) {
  'use strict';
  class _JenkinsSmiHash extends core.Object {
    static combine(hash, value) {
      hash = 536870911 & dart.notNull(hash) + dart.notNull(value);
      hash = 536870911 & dart.notNull(hash) + ((524287 & dart.notNull(hash)) << 10);
      return dart.notNull(hash) ^ dart.notNull(hash) >> 6;
    }
    static finish(hash) {
      hash = 536870911 & dart.notNull(hash) + ((67108863 & dart.notNull(hash)) << 3);
      hash = dart.notNull(hash) ^ dart.notNull(hash) >> 11;
      return 536870911 & dart.notNull(hash) + ((16383 & dart.notNull(hash)) << 15);
    }
    static hash2(a, b) {
      return _JenkinsSmiHash.finish(_JenkinsSmiHash.combine(_JenkinsSmiHash.combine(0, dart.as(a, core.int)), dart.as(b, core.int)));
    }
    static hash4(a, b, c, d) {
      return _JenkinsSmiHash.finish(_JenkinsSmiHash.combine(_JenkinsSmiHash.combine(_JenkinsSmiHash.combine(_JenkinsSmiHash.combine(0, dart.as(a, core.int)), dart.as(b, core.int)), dart.as(c, core.int)), dart.as(d, core.int)));
    }
  }
  let Point$ = dart.generic(function(T) {
    class Point extends core.Object {
      Point(x, y) {
        this.x = x;
        this.y = y;
      }
      toString() {
        return `Point(${this.x}, ${this.y})`;
      }
      ['=='](other) {
        if (!dart.is(other, Point))
          return false;
        return dart.notNull(dart.equals(this.x, dart.dload(other, 'x'))) && dart.notNull(dart.equals(this.y, dart.dload(other, 'y')));
      }
      get hashCode() {
        return _JenkinsSmiHash.hash2(this.x.hashCode, this.y.hashCode);
      }
      ['+'](other) {
        return new Point(dart.as(this.x['+'](other.x), T), dart.as(this.y['+'](other.y), T));
      }
      ['-'](other) {
        return new Point(dart.as(this.x['-'](other.x), T), dart.as(this.y['-'](other.y), T));
      }
      ['*'](factor) {
        return new Point(dart.as(this.x['*'](factor), T), dart.as(this.y['*'](factor), T));
      }
      get magnitude() {
        return sqrt(dart.notNull(this.x['*'](this.x)) + dart.notNull(this.y['*'](this.y)));
      }
      distanceTo(other) {
        let dx = this.x['-'](other.x);
        let dy = this.y['-'](other.y);
        return sqrt(dart.notNull(dx) * dart.notNull(dx) + dart.notNull(dy) * dart.notNull(dy));
      }
      squaredDistanceTo(other) {
        let dx = this.x['-'](other.x);
        let dy = this.y['-'](other.y);
        return dart.as(dart.notNull(dx) * dart.notNull(dx) + dart.notNull(dy) * dart.notNull(dy), T);
      }
    }
    return Point;
  });
  let Point = Point$(dart.dynamic);
  class Random extends core.Object {
    Random(seed) {
      if (seed === void 0)
        seed = null;
      return seed === null ? new _JSRandom() : new _Random(seed);
    }
  }
  let _RectangleBase$ = dart.generic(function(T) {
    class _RectangleBase extends core.Object {
      _RectangleBase() {
      }
      get right() {
        return dart.as(this.left['+'](this.width), T);
      }
      get bottom() {
        return dart.as(this.top['+'](this.height), T);
      }
      toString() {
        return `Rectangle (${this.left}, ${this.top}) ${this.width} x ${this.height}`;
      }
      ['=='](other) {
        if (!dart.is(other, Rectangle))
          return false;
        return dart.notNull(dart.equals(this.left, dart.dload(other, 'left'))) && dart.notNull(dart.equals(this.top, dart.dload(other, 'top'))) && dart.notNull(dart.equals(this.right, dart.dload(other, 'right'))) && dart.notNull(dart.equals(this.bottom, dart.dload(other, 'bottom')));
      }
      get hashCode() {
        return _JenkinsSmiHash.hash4(this.left.hashCode, this.top.hashCode, this.right.hashCode, this.bottom.hashCode);
      }
      intersection(other) {
        let x0 = max(this.left, other.left);
        let x1 = min(this.left['+'](this.width), other.left['+'](other.width));
        if (dart.notNull(x0) <= dart.notNull(x1)) {
          let y0 = max(this.top, other.top);
          let y1 = min(this.top['+'](this.height), other.top['+'](other.height));
          if (dart.notNull(y0) <= dart.notNull(y1)) {
            return new Rectangle(dart.as(x0, T), dart.as(y0, T), dart.as(dart.notNull(x1) - dart.notNull(x0), T), dart.as(dart.notNull(y1) - dart.notNull(y0), T));
          }
        }
        return null;
      }
      intersects(other) {
        return dart.notNull(this.left['<='](dart.notNull(other.left) + dart.notNull(other.width))) && dart.notNull(other.left) <= dart.notNull(this.left['+'](this.width)) && dart.notNull(this.top['<='](dart.notNull(other.top) + dart.notNull(other.height))) && dart.notNull(other.top) <= dart.notNull(this.top['+'](this.height));
      }
      boundingBox(other) {
        let right = max(this.left['+'](this.width), other.left['+'](other.width));
        let bottom = max(this.top['+'](this.height), other.top['+'](other.height));
        let left = min(this.left, other.left);
        let top = min(this.top, other.top);
        return new Rectangle(dart.as(left, T), dart.as(top, T), dart.as(dart.notNull(right) - dart.notNull(left), T), dart.as(dart.notNull(bottom) - dart.notNull(top), T));
      }
      containsRectangle(another) {
        return dart.notNull(this.left['<='](another.left)) && dart.notNull(this.left['+'](this.width)) >= dart.notNull(another.left) + dart.notNull(another.width) && dart.notNull(this.top['<='](another.top)) && dart.notNull(this.top['+'](this.height)) >= dart.notNull(another.top) + dart.notNull(another.height);
      }
      containsPoint(another) {
        return core.num['>='](another.x, this.left) && dart.notNull(another.x) <= dart.notNull(this.left['+'](this.width)) && core.num['>='](another.y, this.top) && dart.notNull(another.y) <= dart.notNull(this.top['+'](this.height));
      }
      get topLeft() {
        return new Point(this.left, this.top);
      }
      get topRight() {
        return new Point(dart.as(this.left['+'](this.width), T), this.top);
      }
      get bottomRight() {
        return new Point(dart.as(this.left['+'](this.width), T), dart.as(this.top['+'](this.height), T));
      }
      get bottomLeft() {
        return new Point(this.left, dart.as(this.top['+'](this.height), T));
      }
    }
    return _RectangleBase;
  });
  let _RectangleBase = _RectangleBase$(dart.dynamic);
  let Rectangle$ = dart.generic(function(T) {
    class Rectangle extends _RectangleBase$(T) {
      Rectangle(left, top, width, height) {
        this.left = left;
        this.top = top;
        this.width = dart.as(width['<'](0) ? dart.notNull(width['unary-']()) * 0 : width, T);
        this.height = dart.as(height['<'](0) ? dart.notNull(height['unary-']()) * 0 : height, T);
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
    dart.defineNamedConstructor(Rectangle, 'fromPoints');
    return Rectangle;
  });
  let Rectangle = Rectangle$(dart.dynamic);
  let _width = Symbol('_width');
  let _height = Symbol('_height');
  let MutableRectangle$ = dart.generic(function(T) {
    class MutableRectangle extends _RectangleBase$(T) {
      MutableRectangle(left, top, width, height) {
        this.left = left;
        this.top = top;
        this[_width] = dart.as(width['<'](0) ? _clampToZero(width) : width, T);
        this[_height] = dart.as(height['<'](0) ? _clampToZero(height) : height, T);
        super._RectangleBase();
      }
      MutableRectangle$fromPoints(a, b) {
        let left = dart.as(min(a.x, b.x), T);
        let width = dart.as(core.num['-'](max(a.x, b.x), left), T);
        let top = dart.as(min(a.y, b.y), T);
        let height = dart.as(core.num['-'](max(a.y, b.y), top), T);
        return new MutableRectangle(left, top, width, height);
      }
      get width() {
        return this[_width];
      }
      set width(width) {
        if (width['<'](0))
          width = dart.as(_clampToZero(width), T);
        this[_width] = width;
      }
      get height() {
        return this[_height];
      }
      set height(height) {
        if (height['<'](0))
          height = dart.as(_clampToZero(height), T);
        this[_height] = height;
      }
    }
    dart.defineNamedConstructor(MutableRectangle, 'fromPoints');
    return MutableRectangle;
  });
  let MutableRectangle = MutableRectangle$(dart.dynamic);
  // Function _clampToZero: (num) → num
  function _clampToZero(value) {
    dart.assert(dart.notNull(value) < 0);
    return -dart.notNull(value) * 0;
  }
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
    if (!dart.is(a, core.num))
      throw new core.ArgumentError(a);
    if (!dart.is(b, core.num))
      throw new core.ArgumentError(b);
    if (dart.notNull(a) > dart.notNull(b))
      return b;
    if (dart.notNull(a) < dart.notNull(b))
      return a;
    if (typeof b == 'number') {
      if (typeof a == 'number') {
        if (a === 0.0) {
          return (dart.notNull(a) + dart.notNull(b)) * dart.notNull(a) * dart.notNull(b);
        }
      }
      if (a === 0 && dart.notNull(b.isNegative) || dart.notNull(b.isNaN))
        return b;
      return a;
    }
    return a;
  }
  // Function max: (num, num) → num
  function max(a, b) {
    if (!dart.is(a, core.num))
      throw new core.ArgumentError(a);
    if (!dart.is(b, core.num))
      throw new core.ArgumentError(b);
    if (dart.notNull(a) > dart.notNull(b))
      return a;
    if (dart.notNull(a) < dart.notNull(b))
      return b;
    if (typeof b == 'number') {
      if (typeof a == 'number') {
        if (a === 0.0) {
          return dart.notNull(a) + dart.notNull(b);
        }
      }
      if (b.isNaN)
        return b;
      return a;
    }
    if (b === 0 && dart.notNull(a.isNegative))
      return b;
    return a;
  }
  // Function atan2: (num, num) → double
  function atan2(a, b) {
    return Math.atan2(_js_helper.checkNum(a), _js_helper.checkNum(b));
  }
  // Function pow: (num, num) → num
  function pow(x, exponent) {
    _js_helper.checkNum(x);
    _js_helper.checkNum(exponent);
    return Math.pow(x, exponent);
  }
  // Function sin: (num) → double
  function sin(x) {
    return Math.sin(_js_helper.checkNum(x));
  }
  // Function cos: (num) → double
  function cos(x) {
    return Math.cos(_js_helper.checkNum(x));
  }
  // Function tan: (num) → double
  function tan(x) {
    return Math.tan(_js_helper.checkNum(x));
  }
  // Function acos: (num) → double
  function acos(x) {
    return Math.acos(_js_helper.checkNum(x));
  }
  // Function asin: (num) → double
  function asin(x) {
    return Math.asin(_js_helper.checkNum(x));
  }
  // Function atan: (num) → double
  function atan(x) {
    return Math.atan(_js_helper.checkNum(x));
  }
  // Function sqrt: (num) → double
  function sqrt(x) {
    return Math.sqrt(_js_helper.checkNum(x));
  }
  // Function exp: (num) → double
  function exp(x) {
    return Math.exp(_js_helper.checkNum(x));
  }
  // Function log: (num) → double
  function log(x) {
    return Math.log(_js_helper.checkNum(x));
  }
  let _POW2_32 = 4294967296;
  class _JSRandom extends core.Object {
    _JSRandom() {
    }
    nextInt(max) {
      if (dart.notNull(max) <= 0 || dart.notNull(max) > dart.notNull(_POW2_32)) {
        throw new core.RangeError(`max must be in range 0 < max ≤ 2^32, was ${max}`);
      }
      return Math.random() * max >>> 0;
    }
    nextDouble() {
      return Math.random();
    }
    nextBool() {
      return Math.random() < 0.5;
    }
  }
  let _lo = Symbol('_lo');
  let _hi = Symbol('_hi');
  let _MASK32 = Symbol('_MASK32');
  let _nextState = Symbol('_nextState');
  let _POW2_27_D = Symbol('_POW2_27_D');
  let _POW2_53_D = Symbol('_POW2_53_D');
  class _Random extends core.Object {
    _Random(seed) {
      this[_lo] = 0;
      this[_hi] = 0;
      let empty_seed = 0;
      if (dart.notNull(seed) < 0) {
        empty_seed = -1;
      }
      do {
        let low = dart.notNull(seed) & dart.notNull(_Random[_MASK32]);
        seed = ((dart.notNull(seed) - dart.notNull(low)) / dart.notNull(_POW2_32)).truncate();
        let high = dart.notNull(seed) & dart.notNull(_Random[_MASK32]);
        seed = ((dart.notNull(seed) - dart.notNull(high)) / dart.notNull(_POW2_32)).truncate();
        let tmplow = dart.notNull(low) << 21;
        let tmphigh = dart.notNull(high) << 21 | dart.notNull(low) >> 11;
        tmplow = (~dart.notNull(low) & dart.notNull(_Random[_MASK32])) + dart.notNull(tmplow);
        low = dart.notNull(tmplow) & dart.notNull(_Random[_MASK32]);
        high = ~dart.notNull(high) + dart.notNull(tmphigh) + ((dart.notNull(tmplow) - dart.notNull(low)) / 4294967296).truncate() & dart.notNull(_Random[_MASK32]);
        tmphigh = dart.notNull(high) >> 24;
        tmplow = dart.notNull(low) >> 24 | dart.notNull(high) << 8;
        low = tmplow;
        high = tmphigh;
        tmplow = dart.notNull(low) * 265;
        low = dart.notNull(tmplow) & dart.notNull(_Random[_MASK32]);
        high = dart.notNull(high) * 265 + ((dart.notNull(tmplow) - dart.notNull(low)) / 4294967296).truncate() & dart.notNull(_Random[_MASK32]);
        tmphigh = dart.notNull(high) >> 14;
        tmplow = dart.notNull(low) >> 14 | dart.notNull(high) << 18;
        low = tmplow;
        high = tmphigh;
        tmplow = dart.notNull(low) * 21;
        low = dart.notNull(tmplow) & dart.notNull(_Random[_MASK32]);
        high = dart.notNull(high) * 21 + ((dart.notNull(tmplow) - dart.notNull(low)) / 4294967296).truncate() & dart.notNull(_Random[_MASK32]);
        tmphigh = dart.notNull(high) >> 28;
        tmplow = dart.notNull(low) >> 28 | dart.notNull(high) << 4;
        low = tmplow;
        high = tmphigh;
        tmplow = dart.notNull(low) << 31;
        tmphigh = dart.notNull(high) << 31 | dart.notNull(low) >> 1;
        tmplow = low;
        low = dart.notNull(tmplow) & dart.notNull(_Random[_MASK32]);
        high = dart.notNull(high) + dart.notNull(tmphigh) + ((dart.notNull(tmplow) - dart.notNull(low)) / 4294967296).truncate() & dart.notNull(_Random[_MASK32]);
        tmplow = dart.notNull(this[_lo]) * 1037;
        this[_lo] = dart.notNull(tmplow) & dart.notNull(_Random[_MASK32]);
        this[_hi] = dart.notNull(this[_hi]) * 1037 + ((dart.notNull(tmplow) - dart.notNull(this[_lo])) / 4294967296).truncate() & dart.notNull(_Random[_MASK32]);
        this[_lo] = low;
        this[_hi] = high;
      } while (seed !== empty_seed);
      if (this[_hi] === 0 && this[_lo] === 0) {
        this[_lo] = 23063;
      }
      this[_nextState]();
      this[_nextState]();
      this[_nextState]();
      this[_nextState]();
    }
    [_nextState]() {
      let tmpHi = 4294901760 * dart.notNull(this[_lo]);
      let tmpHiLo = dart.notNull(tmpHi) & dart.notNull(_Random[_MASK32]);
      let tmpHiHi = dart.notNull(tmpHi) - dart.notNull(tmpHiLo);
      let tmpLo = 55905 * dart.notNull(this[_lo]);
      let tmpLoLo = dart.notNull(tmpLo) & dart.notNull(_Random[_MASK32]);
      let tmpLoHi = dart.notNull(tmpLo) - dart.notNull(tmpLoLo);
      let newLo = dart.notNull(tmpLoLo) + dart.notNull(tmpHiLo) + dart.notNull(this[_hi]);
      this[_lo] = dart.notNull(newLo) & dart.notNull(_Random[_MASK32]);
      let newLoHi = dart.notNull(newLo) - dart.notNull(this[_lo]);
      this[_hi] = ((dart.notNull(tmpLoHi) + dart.notNull(tmpHiHi) + dart.notNull(newLoHi)) / dart.notNull(_POW2_32)).truncate() & dart.notNull(_Random[_MASK32]);
      dart.assert(dart.notNull(this[_lo]) < dart.notNull(_POW2_32));
      dart.assert(dart.notNull(this[_hi]) < dart.notNull(_POW2_32));
    }
    nextInt(max) {
      if (dart.notNull(max) <= 0 || dart.notNull(max) > dart.notNull(_POW2_32)) {
        throw new core.RangeError(`max must be in range 0 < max ≤ 2^32, was ${max}`);
      }
      if ((dart.notNull(max) & dart.notNull(max) - 1) === 0) {
        this[_nextState]();
        return dart.notNull(this[_lo]) & dart.notNull(max) - 1;
      }
      let rnd32 = null;
      let result = null;
      do {
        this[_nextState]();
        rnd32 = this[_lo];
        result = rnd32.remainder(max);
      } while (dart.notNull(rnd32) - dart.notNull(result) + dart.notNull(max) >= dart.notNull(_POW2_32));
      return result;
    }
    nextDouble() {
      this[_nextState]();
      let bits26 = dart.notNull(this[_lo]) & (1 << 26) - 1;
      this[_nextState]();
      let bits27 = dart.notNull(this[_lo]) & (1 << 27) - 1;
      return (dart.notNull(bits26) * dart.notNull(_Random[_POW2_27_D]) + dart.notNull(bits27)) / dart.notNull(_Random[_POW2_53_D]);
    }
    nextBool() {
      this[_nextState]();
      return (dart.notNull(this[_lo]) & 1) === 0;
    }
  }
  _Random._POW2_53_D = 1.0 * 9007199254740992;
  _Random._POW2_27_D = 1.0 * (1 << 27);
  _Random._MASK32 = 4294967295;
  // Exports:
  exports.Point = Point;
  exports.Point$ = Point$;
  exports.Random = Random;
  exports.Rectangle = Rectangle;
  exports.Rectangle$ = Rectangle$;
  exports.MutableRectangle = MutableRectangle;
  exports.MutableRectangle$ = MutableRectangle$;
  exports.E = E;
  exports.LN10 = LN10;
  exports.LN2 = LN2;
  exports.LOG2E = LOG2E;
  exports.LOG10E = LOG10E;
  exports.PI = PI;
  exports.SQRT1_2 = SQRT1_2;
  exports.SQRT2 = SQRT2;
  exports.min = min;
  exports.max = max;
  exports.atan2 = atan2;
  exports.pow = pow;
  exports.sin = sin;
  exports.cos = cos;
  exports.tan = tan;
  exports.acos = acos;
  exports.asin = asin;
  exports.atan = atan;
  exports.sqrt = sqrt;
  exports.exp = exp;
  exports.log = log;
})(math || (math = {}));
