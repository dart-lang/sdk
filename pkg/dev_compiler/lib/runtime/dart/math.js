dart_library.library('dart/math', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
  'dart/_js_helper'
], function(exports, dart, core, _js_helper) {
  'use strict';
  let dartx = dart.dartx;
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
  dart.setSignature(_JenkinsSmiHash, {
    statics: () => ({
      combine: [core.int, [core.int, core.int]],
      finish: [core.int, [core.int]],
      hash2: [core.int, [dart.dynamic, dart.dynamic]],
      hash4: [core.int, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['combine', 'finish', 'hash2', 'hash4']
  });
  const Point$ = dart.generic(function(T) {
    class Point extends core.Object {
      Point(x, y) {
        this.x = x;
        this.y = y;
      }
      toString() {
        return `Point(${this.x}, ${this.y})`;
      }
      ['=='](other) {
        if (!dart.is(other, Point$())) return false;
        return dart.equals(this.x, dart.dload(other, 'x')) && dart.equals(this.y, dart.dload(other, 'y'));
      }
      get hashCode() {
        return _JenkinsSmiHash.hash2(dart.hashCode(this.x), dart.hashCode(this.y));
      }
      ['+'](other) {
        dart.as(other, Point$(T));
        return new (Point$(T))(dart.notNull(this.x) + dart.notNull(other.x), dart.notNull(this.y) + dart.notNull(other.y));
      }
      ['-'](other) {
        dart.as(other, Point$(T));
        return new (Point$(T))(dart.notNull(this.x) - dart.notNull(other.x), dart.notNull(this.y) - dart.notNull(other.y));
      }
      ['*'](factor) {
        return new (Point$(T))(dart.notNull(this.x) * dart.notNull(factor), dart.notNull(this.y) * dart.notNull(factor));
      }
      get magnitude() {
        return sqrt(dart.notNull(this.x) * dart.notNull(this.x) + dart.notNull(this.y) * dart.notNull(this.y));
      }
      distanceTo(other) {
        dart.as(other, Point$(T));
        let dx = dart.notNull(this.x) - dart.notNull(other.x);
        let dy = dart.notNull(this.y) - dart.notNull(other.y);
        return sqrt(dx * dx + dy * dy);
      }
      squaredDistanceTo(other) {
        dart.as(other, Point$(T));
        let dx = dart.notNull(this.x) - dart.notNull(other.x);
        let dy = dart.notNull(this.y) - dart.notNull(other.y);
        return dx * dx + dy * dy;
      }
    }
    dart.setSignature(Point, {
      constructors: () => ({Point: [Point$(T), [T, T]]}),
      methods: () => ({
        '+': [Point$(T), [Point$(T)]],
        '-': [Point$(T), [Point$(T)]],
        '*': [Point$(T), [core.num]],
        distanceTo: [core.double, [Point$(T)]],
        squaredDistanceTo: [T, [Point$(T)]]
      })
    });
    return Point;
  });
  let Point = Point$();
  class Random extends core.Object {
    static new(seed) {
      if (seed === void 0) seed = null;
      return seed == null ? dart.const(new _JSRandom()) : new _Random(seed);
    }
  }
  dart.setSignature(Random, {
    constructors: () => ({new: [Random, [], [core.int]]})
  });
  const _RectangleBase$ = dart.generic(function(T) {
    class _RectangleBase extends core.Object {
      _RectangleBase() {
      }
      get right() {
        return dart.notNull(this.left) + dart.notNull(this.width);
      }
      get bottom() {
        return dart.notNull(this.top) + dart.notNull(this.height);
      }
      toString() {
        return `Rectangle (${this.left}, ${this.top}) ${this.width} x ${this.height}`;
      }
      ['=='](other) {
        if (!dart.is(other, Rectangle)) return false;
        return dart.equals(this.left, dart.dload(other, 'left')) && dart.equals(this.top, dart.dload(other, 'top')) && dart.equals(this.right, dart.dload(other, 'right')) && dart.equals(this.bottom, dart.dload(other, 'bottom'));
      }
      get hashCode() {
        return _JenkinsSmiHash.hash4(dart.hashCode(this.left), dart.hashCode(this.top), dart.hashCode(this.right), dart.hashCode(this.bottom));
      }
      intersection(other) {
        dart.as(other, Rectangle$(T));
        let x0 = max(this.left, other.left);
        let x1 = min(dart.notNull(this.left) + dart.notNull(this.width), dart.notNull(other.left) + dart.notNull(other.width));
        if (dart.notNull(x0) <= dart.notNull(x1)) {
          let y0 = max(this.top, other.top);
          let y1 = min(dart.notNull(this.top) + dart.notNull(this.height), dart.notNull(other.top) + dart.notNull(other.height));
          if (dart.notNull(y0) <= dart.notNull(y1)) {
            return new (Rectangle$(T))(x0, y0, dart.notNull(x1) - dart.notNull(x0), dart.notNull(y1) - dart.notNull(y0));
          }
        }
        return null;
      }
      intersects(other) {
        return dart.notNull(this.left) <= dart.notNull(other.left) + dart.notNull(other.width) && dart.notNull(other.left) <= dart.notNull(this.left) + dart.notNull(this.width) && dart.notNull(this.top) <= dart.notNull(other.top) + dart.notNull(other.height) && dart.notNull(other.top) <= dart.notNull(this.top) + dart.notNull(this.height);
      }
      boundingBox(other) {
        dart.as(other, Rectangle$(T));
        let right = max(dart.notNull(this.left) + dart.notNull(this.width), dart.notNull(other.left) + dart.notNull(other.width));
        let bottom = max(dart.notNull(this.top) + dart.notNull(this.height), dart.notNull(other.top) + dart.notNull(other.height));
        let left = min(this.left, other.left);
        let top = min(this.top, other.top);
        return new (Rectangle$(T))(left, top, dart.notNull(right) - dart.notNull(left), dart.notNull(bottom) - dart.notNull(top));
      }
      containsRectangle(another) {
        return dart.notNull(this.left) <= dart.notNull(another.left) && dart.notNull(this.left) + dart.notNull(this.width) >= dart.notNull(another.left) + dart.notNull(another.width) && dart.notNull(this.top) <= dart.notNull(another.top) && dart.notNull(this.top) + dart.notNull(this.height) >= dart.notNull(another.top) + dart.notNull(another.height);
      }
      containsPoint(another) {
        return dart.notNull(another.x) >= dart.notNull(this.left) && dart.notNull(another.x) <= dart.notNull(this.left) + dart.notNull(this.width) && dart.notNull(another.y) >= dart.notNull(this.top) && dart.notNull(another.y) <= dart.notNull(this.top) + dart.notNull(this.height);
      }
      get topLeft() {
        return new (Point$(T))(this.left, this.top);
      }
      get topRight() {
        return new (Point$(T))(dart.notNull(this.left) + dart.notNull(this.width), this.top);
      }
      get bottomRight() {
        return new (Point$(T))(dart.notNull(this.left) + dart.notNull(this.width), dart.notNull(this.top) + dart.notNull(this.height));
      }
      get bottomLeft() {
        return new (Point$(T))(this.left, dart.notNull(this.top) + dart.notNull(this.height));
      }
    }
    dart.setSignature(_RectangleBase, {
      constructors: () => ({_RectangleBase: [_RectangleBase$(T), []]}),
      methods: () => ({
        intersection: [Rectangle$(T), [Rectangle$(T)]],
        intersects: [core.bool, [Rectangle$(core.num)]],
        boundingBox: [Rectangle$(T), [Rectangle$(T)]],
        containsRectangle: [core.bool, [Rectangle$(core.num)]],
        containsPoint: [core.bool, [Point$(core.num)]]
      })
    });
    return _RectangleBase;
  });
  let _RectangleBase = _RectangleBase$();
  const Rectangle$ = dart.generic(function(T) {
    class Rectangle extends _RectangleBase$(T) {
      Rectangle(left, top, width, height) {
        this.left = left;
        this.top = top;
        this.width = dart.notNull(width) < 0 ? -dart.notNull(width) * 0 : width;
        this.height = dart.notNull(height) < 0 ? -dart.notNull(height) * 0 : height;
        super._RectangleBase();
      }
      static fromPoints(a, b) {
        let left = min(a.x, b.x);
        let width = dart.notNull(max(a.x, b.x)) - dart.notNull(left);
        let top = min(a.y, b.y);
        let height = dart.notNull(max(a.y, b.y)) - dart.notNull(top);
        return new (Rectangle$(T))(left, top, width, height);
      }
    }
    dart.setSignature(Rectangle, {
      constructors: () => ({
        Rectangle: [Rectangle$(T), [T, T, T, T]],
        fromPoints: [Rectangle$(T), [Point$(T), Point$(T)]]
      })
    });
    return Rectangle;
  });
  let Rectangle = Rectangle$();
  const _width = Symbol('_width');
  const _height = Symbol('_height');
  const MutableRectangle$ = dart.generic(function(T) {
    class MutableRectangle extends _RectangleBase$(T) {
      MutableRectangle(left, top, width, height) {
        this.left = left;
        this.top = top;
        this[_width] = dart.notNull(width) < 0 ? _clampToZero(width) : width;
        this[_height] = dart.notNull(height) < 0 ? _clampToZero(height) : height;
        super._RectangleBase();
      }
      static fromPoints(a, b) {
        let left = min(a.x, b.x);
        let width = dart.notNull(max(a.x, b.x)) - dart.notNull(left);
        let top = min(a.y, b.y);
        let height = dart.notNull(max(a.y, b.y)) - dart.notNull(top);
        return new (MutableRectangle$(T))(left, top, width, height);
      }
      get width() {
        return this[_width];
      }
      set width(width) {
        dart.as(width, T);
        if (dart.notNull(width) < 0) width = _clampToZero(width);
        this[_width] = width;
      }
      get height() {
        return this[_height];
      }
      set height(height) {
        dart.as(height, T);
        if (dart.notNull(height) < 0) height = _clampToZero(height);
        this[_height] = height;
      }
    }
    MutableRectangle[dart.implements] = () => [Rectangle$(T)];
    dart.setSignature(MutableRectangle, {
      constructors: () => ({
        MutableRectangle: [MutableRectangle$(T), [T, T, T, T]],
        fromPoints: [MutableRectangle$(T), [Point$(T), Point$(T)]]
      })
    });
    return MutableRectangle;
  });
  let MutableRectangle = MutableRectangle$();
  function _clampToZero(value) {
    dart.assert(dart.notNull(value) < 0);
    return -dart.notNull(value) * 0;
  }
  dart.fn(_clampToZero, core.num, [core.num]);
  const E = 2.718281828459045;
  const LN10 = 2.302585092994046;
  const LN2 = 0.6931471805599453;
  const LOG2E = 1.4426950408889634;
  const LOG10E = 0.4342944819032518;
  const PI = 3.141592653589793;
  const SQRT1_2 = 0.7071067811865476;
  const SQRT2 = 1.4142135623730951;
  function min(a, b) {
    if (!(typeof a == 'number')) dart.throw(new core.ArgumentError(a));
    if (!(typeof b == 'number')) dart.throw(new core.ArgumentError(b));
    if (dart.notNull(a) > dart.notNull(b)) return b;
    if (dart.notNull(a) < dart.notNull(b)) return a;
    if (typeof b == 'number') {
      if (typeof a == 'number') {
        if (a == 0.0) {
          return (dart.notNull(a) + dart.notNull(b)) * dart.notNull(a) * dart.notNull(b);
        }
      }
      if (a == 0 && dart.notNull(b[dartx.isNegative]) || dart.notNull(b[dartx.isNaN])) return b;
      return a;
    }
    return a;
  }
  dart.fn(min, () => dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
  function max(a, b) {
    if (!(typeof a == 'number')) dart.throw(new core.ArgumentError(a));
    if (!(typeof b == 'number')) dart.throw(new core.ArgumentError(b));
    if (dart.notNull(a) > dart.notNull(b)) return a;
    if (dart.notNull(a) < dart.notNull(b)) return b;
    if (typeof b == 'number') {
      if (typeof a == 'number') {
        if (a == 0.0) {
          return dart.notNull(a) + dart.notNull(b);
        }
      }
      if (dart.notNull(b[dartx.isNaN])) return b;
      return a;
    }
    if (b == 0 && dart.notNull(a[dartx.isNegative])) return b;
    return a;
  }
  dart.fn(max, () => dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
  function atan2(a, b) {
    return Math.atan2(_js_helper.checkNum(a), _js_helper.checkNum(b));
  }
  dart.fn(atan2, core.double, [core.num, core.num]);
  function pow(x, exponent) {
    _js_helper.checkNum(x);
    _js_helper.checkNum(exponent);
    return Math.pow(x, exponent);
  }
  dart.fn(pow, core.num, [core.num, core.num]);
  function sin(x) {
    return Math.sin(_js_helper.checkNum(x));
  }
  dart.fn(sin, core.double, [core.num]);
  function cos(x) {
    return Math.cos(_js_helper.checkNum(x));
  }
  dart.fn(cos, core.double, [core.num]);
  function tan(x) {
    return Math.tan(_js_helper.checkNum(x));
  }
  dart.fn(tan, core.double, [core.num]);
  function acos(x) {
    return Math.acos(_js_helper.checkNum(x));
  }
  dart.fn(acos, core.double, [core.num]);
  function asin(x) {
    return Math.asin(_js_helper.checkNum(x));
  }
  dart.fn(asin, core.double, [core.num]);
  function atan(x) {
    return Math.atan(_js_helper.checkNum(x));
  }
  dart.fn(atan, core.double, [core.num]);
  function sqrt(x) {
    return Math.sqrt(_js_helper.checkNum(x));
  }
  dart.fn(sqrt, core.double, [core.num]);
  function exp(x) {
    return Math.exp(_js_helper.checkNum(x));
  }
  dart.fn(exp, core.double, [core.num]);
  function log(x) {
    return Math.log(_js_helper.checkNum(x));
  }
  dart.fn(log, core.double, [core.num]);
  const _POW2_32 = 4294967296;
  class _JSRandom extends core.Object {
    _JSRandom() {
    }
    nextInt(max) {
      if (dart.notNull(max) <= 0 || dart.notNull(max) > dart.notNull(_POW2_32)) {
        dart.throw(new core.RangeError(`max must be in range 0 < max ≤ 2^32, was ${max}`));
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
  _JSRandom[dart.implements] = () => [Random];
  dart.setSignature(_JSRandom, {
    constructors: () => ({_JSRandom: [_JSRandom, []]}),
    methods: () => ({
      nextInt: [core.int, [core.int]],
      nextDouble: [core.double, []],
      nextBool: [core.bool, []]
    })
  });
  const _lo = Symbol('_lo');
  const _hi = Symbol('_hi');
  const _nextState = Symbol('_nextState');
  class _Random extends core.Object {
    _Random(seed) {
      this[_lo] = 0;
      this[_hi] = 0;
      let empty_seed = 0;
      if (dart.notNull(seed) < 0) {
        empty_seed = -1;
      }
      do {
        let low = dart.notNull(seed) & dart.notNull(_Random._MASK32);
        seed = ((dart.notNull(seed) - low) / dart.notNull(_POW2_32))[dartx.truncate]();
        let high = dart.notNull(seed) & dart.notNull(_Random._MASK32);
        seed = ((dart.notNull(seed) - high) / dart.notNull(_POW2_32))[dartx.truncate]();
        let tmplow = low << 21;
        let tmphigh = high << 21 | low >> 11;
        tmplow = (~low & dart.notNull(_Random._MASK32)) + tmplow;
        low = tmplow & dart.notNull(_Random._MASK32);
        high = ~high + tmphigh + ((tmplow - low) / 4294967296)[dartx.truncate]() & dart.notNull(_Random._MASK32);
        tmphigh = high >> 24;
        tmplow = low >> 24 | high << 8;
        low = low ^ tmplow;
        high = high ^ tmphigh;
        tmplow = low * 265;
        low = tmplow & dart.notNull(_Random._MASK32);
        high = high * 265 + ((tmplow - low) / 4294967296)[dartx.truncate]() & dart.notNull(_Random._MASK32);
        tmphigh = high >> 14;
        tmplow = low >> 14 | high << 18;
        low = low ^ tmplow;
        high = high ^ tmphigh;
        tmplow = low * 21;
        low = tmplow & dart.notNull(_Random._MASK32);
        high = high * 21 + ((tmplow - low) / 4294967296)[dartx.truncate]() & dart.notNull(_Random._MASK32);
        tmphigh = high >> 28;
        tmplow = low >> 28 | high << 4;
        low = low ^ tmplow;
        high = high ^ tmphigh;
        tmplow = low << 31;
        tmphigh = high << 31 | low >> 1;
        tmplow = tmplow + low;
        low = tmplow & dart.notNull(_Random._MASK32);
        high = high + tmphigh + ((tmplow - low) / 4294967296)[dartx.truncate]() & dart.notNull(_Random._MASK32);
        tmplow = dart.notNull(this[_lo]) * 1037;
        this[_lo] = tmplow & dart.notNull(_Random._MASK32);
        this[_hi] = dart.notNull(this[_hi]) * 1037 + ((tmplow - dart.notNull(this[_lo])) / 4294967296)[dartx.truncate]() & dart.notNull(_Random._MASK32);
        this[_lo] = dart.notNull(this[_lo]) ^ low;
        this[_hi] = dart.notNull(this[_hi]) ^ high;
      } while (seed != empty_seed);
      if (this[_hi] == 0 && this[_lo] == 0) {
        this[_lo] = 23063;
      }
      this[_nextState]();
      this[_nextState]();
      this[_nextState]();
      this[_nextState]();
    }
    [_nextState]() {
      let tmpHi = 4294901760 * dart.notNull(this[_lo]);
      let tmpHiLo = tmpHi & dart.notNull(_Random._MASK32);
      let tmpHiHi = tmpHi - tmpHiLo;
      let tmpLo = 55905 * dart.notNull(this[_lo]);
      let tmpLoLo = tmpLo & dart.notNull(_Random._MASK32);
      let tmpLoHi = tmpLo - tmpLoLo;
      let newLo = tmpLoLo + tmpHiLo + dart.notNull(this[_hi]);
      this[_lo] = newLo & dart.notNull(_Random._MASK32);
      let newLoHi = newLo - dart.notNull(this[_lo]);
      this[_hi] = ((tmpLoHi + tmpHiHi + newLoHi) / dart.notNull(_POW2_32))[dartx.truncate]() & dart.notNull(_Random._MASK32);
      dart.assert(dart.notNull(this[_lo]) < dart.notNull(_POW2_32));
      dart.assert(dart.notNull(this[_hi]) < dart.notNull(_POW2_32));
    }
    nextInt(max) {
      if (dart.notNull(max) <= 0 || dart.notNull(max) > dart.notNull(_POW2_32)) {
        dart.throw(new core.RangeError(`max must be in range 0 < max ≤ 2^32, was ${max}`));
      }
      if ((dart.notNull(max) & dart.notNull(max) - 1) == 0) {
        this[_nextState]();
        return dart.notNull(this[_lo]) & dart.notNull(max) - 1;
      }
      let rnd32 = null;
      let result = null;
      do {
        this[_nextState]();
        rnd32 = this[_lo];
        result = dart.asInt(rnd32[dartx.remainder](max));
      } while (dart.notNull(rnd32) - dart.notNull(result) + dart.notNull(max) >= dart.notNull(_POW2_32));
      return result;
    }
    nextDouble() {
      this[_nextState]();
      let bits26 = dart.notNull(this[_lo]) & (1 << 26) - 1;
      this[_nextState]();
      let bits27 = dart.notNull(this[_lo]) & (1 << 27) - 1;
      return (bits26 * dart.notNull(_Random._POW2_27_D) + bits27) / dart.notNull(_Random._POW2_53_D);
    }
    nextBool() {
      this[_nextState]();
      return (dart.notNull(this[_lo]) & 1) == 0;
    }
  }
  _Random[dart.implements] = () => [Random];
  dart.setSignature(_Random, {
    constructors: () => ({_Random: [_Random, [core.int]]}),
    methods: () => ({
      [_nextState]: [dart.void, []],
      nextInt: [core.int, [core.int]],
      nextDouble: [core.double, []],
      nextBool: [core.bool, []]
    })
  });
  _Random._POW2_53_D = 1.0 * 9007199254740992;
  _Random._POW2_27_D = 1.0 * (1 << 27);
  _Random._MASK32 = 4294967295;
  // Exports:
  exports.Point$ = Point$;
  exports.Point = Point;
  exports.Random = Random;
  exports.Rectangle$ = Rectangle$;
  exports.Rectangle = Rectangle;
  exports.MutableRectangle$ = MutableRectangle$;
  exports.MutableRectangle = MutableRectangle;
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
});
