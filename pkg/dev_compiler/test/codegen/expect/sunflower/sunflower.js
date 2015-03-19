var sunflower;
(function(exports) {
  'use strict';
  let ORANGE = "orange";
  let SEED_RADIUS = 2;
  let SCALE_FACTOR = 4;
  let TAU = dart.notNull(math.PI) * 2;
  let MAX_D = 300;
  let centerX = dart.notNull(MAX_D) / 2;
  let centerY = centerX;
  // Function querySelector: (String) → Element
  function querySelector(selector) {
    return dom.document.querySelector(selector);
  }
  exports.seeds = 0;
  dart.defineLazyProperties(exports, {
    get slider() {
      return dart.as(querySelector("#slider"), dom.InputElement);
    },
    get notes() {
      return querySelector("#notes");
    },
    get PHI() {
      return (dart.notNull(math.sqrt(5)) + 1) / 2;
    },
    get context() {
      return dart.as(dart.as(querySelector("#canvas"), dom.CanvasElement).getContext('2d'), dom.CanvasRenderingContext2D);
    }
  });
  // Function main: () → void
  function main() {
    exports.slider.addEventListener('change', dart.closureWrap((e) => draw(), "(Event) → void"));
    draw();
  }
  // Function draw: () → void
  function draw() {
    exports.seeds = core.int.parse(exports.slider.value);
    exports.context.clearRect(0, 0, MAX_D, MAX_D);
    for (let i = 0; dart.notNull(i) < dart.notNull(exports.seeds); i = dart.notNull(i) + 1) {
      let theta = dart.notNull(i) * dart.notNull(TAU) / dart.notNull(exports.PHI);
      let r = dart.notNull(math.sqrt(i)) * dart.notNull(SCALE_FACTOR);
      let x = dart.notNull(centerX) + dart.notNull(r) * dart.notNull(math.cos(theta));
      let y = dart.notNull(centerY) - dart.notNull(r) * dart.notNull(math.sin(theta));
      new SunflowerSeed(x, y, SEED_RADIUS).draw();
    }
    exports.notes.textContent = `${exports.seeds} seeds`;
  }
  class Circle extends core.Object {
    Circle(x, y, radius) {
      this.x = x;
      this.y = y;
      this.radius = radius;
    }
  }
  class CirclePainter extends core.Object {
    CirclePainter() {
      this.color = ORANGE;
    }
    draw() {
      exports.context.beginPath();
      exports.context.lineWidth = 2;
      exports.context.fillStyle = this.color;
      exports.context.strokeStyle = this.color;
      exports.context.arc(this.x, this.y, this.radius, 0, TAU, false);
      exports.context.fill();
      exports.context.closePath();
      exports.context.stroke();
    }
  }
  class SunflowerSeed extends dart.mixin(Circle, CirclePainter) {
    SunflowerSeed(x, y, radius, color) {
      if (color === void 0)
        color = null;
      super.Circle(x, y, radius);
      if (color !== null)
        this.color = color;
    }
  }
  // Exports:
  exports.ORANGE = ORANGE;
  exports.SEED_RADIUS = SEED_RADIUS;
  exports.SCALE_FACTOR = SCALE_FACTOR;
  exports.TAU = TAU;
  exports.MAX_D = MAX_D;
  exports.centerX = centerX;
  exports.centerY = centerY;
  exports.querySelector = querySelector;
  exports.main = main;
  exports.draw = draw;
  exports.SunflowerSeed = SunflowerSeed;
  exports.Circle = Circle;
  exports.CirclePainter = CirclePainter;
})(sunflower || (sunflower = {}));
