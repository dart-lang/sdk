dart_library.library('sunflower/sunflower', null, /* Imports */[
  "dart/_runtime",
  'sunflower/dom',
  'dart/core',
  'dart/math',
  'sunflower/painter',
  'sunflower/circle'
], /* Lazy imports */[
], function(exports, dart, dom, core, math, painter, circle) {
  'use strict';
  let dartx = dart.dartx;
  let SEED_RADIUS = 2;
  let SCALE_FACTOR = 4;
  let MAX_D = 300;
  let centerX = dart.notNull(MAX_D) / 2;
  let centerY = centerX;
  function querySelector(selector) {
    return dom.document.querySelector(selector);
  }
  dart.fn(querySelector, dom.Element, [core.String]);
  exports.seeds = 0;
  dart.defineLazyProperties(exports, {
    get canvas() {
      return dart.as(querySelector("#canvas"), dom.CanvasElement);
    },
    get context() {
      return dart.as(exports.canvas.getContext('2d'), dom.CanvasRenderingContext2D);
    },
    get slider() {
      return dart.as(querySelector("#slider"), dom.InputElement);
    },
    get notes() {
      return querySelector("#notes");
    },
    get PHI() {
      return (dart.notNull(math.sqrt(5)) + 1) / 2;
    }
  });
  function main() {
    exports.slider.addEventListener('change', dart.fn(e => draw(), dart.void, [dart.dynamic]));
    draw();
  }
  dart.fn(main, dart.void, []);
  function draw() {
    exports.seeds = core.int.parse(exports.slider.value);
    exports.context.clearRect(0, 0, MAX_D, MAX_D);
    for (let i = 0; dart.notNull(i) < dart.notNull(exports.seeds); i = dart.notNull(i) + 1) {
      let theta = dart.notNull(i) * dart.notNull(painter.TAU) / dart.notNull(exports.PHI);
      let r = dart.notNull(math.sqrt(i)) * dart.notNull(SCALE_FACTOR);
      let x = dart.notNull(centerX) + dart.notNull(r) * dart.notNull(math.cos(theta));
      let y = dart.notNull(centerY) - dart.notNull(r) * dart.notNull(math.sin(theta));
      new SunflowerSeed(x, y, SEED_RADIUS).draw(exports.context);
    }
    exports.notes.textContent = `${exports.seeds} seeds`;
  }
  dart.fn(draw, dart.void, []);
  class SunflowerSeed extends dart.mixin(circle.Circle, painter.CirclePainter) {
    SunflowerSeed(x, y, radius, color) {
      if (color === void 0)
        color = null;
      super.Circle(x, y, radius);
      if (color != null)
        this.color = color;
    }
  }
  dart.setSignature(SunflowerSeed, {
    constructors: () => ({SunflowerSeed: [SunflowerSeed, [core.num, core.num, core.num], [core.String]]})
  });
  // Exports:
  exports.SEED_RADIUS = SEED_RADIUS;
  exports.SCALE_FACTOR = SCALE_FACTOR;
  exports.MAX_D = MAX_D;
  exports.centerX = centerX;
  exports.centerY = centerY;
  exports.querySelector = querySelector;
  exports.main = main;
  exports.draw = draw;
  exports.SunflowerSeed = SunflowerSeed;
});
