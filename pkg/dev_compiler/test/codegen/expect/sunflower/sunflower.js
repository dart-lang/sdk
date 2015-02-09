var sunflower;
(function (sunflower) {
  'use strict';
  let ORANGE = "orange";
  let SEED_RADIUS = 2;
  let SCALE_FACTOR = 4;
  let TAU = math.PI * 2;
  let MAX_D = 300;
  let centerX = MAX_D / 2;
  let centerY = centerX;
  // Function querySelector: (String) → Element
  function querySelector(selector) { return dom.document.querySelector(selector); }

  sunflower.seeds = 0;
  dart.defineLazyProperties(sunflower, {
    get slider() { return dart.as(querySelector("#slider"), dom.InputElement) },
    get notes() { return querySelector("#notes") },
    get PHI() { return (math.sqrt(5) + 1) / 2 },
    get context() { return dart.as((dart.as(querySelector("#canvas"), dom.CanvasElement)).getContext("2d"), dom.CanvasRenderingContext2D) },
  });

  class Circle {
    constructor(x, y, radius) {
      this.x = x;
      this.y = y;
      this.radius = radius;
    }
  }

  class CirclePainter {
    constructor() {
      this.color = ORANGE;
      super();
    }
    draw() {
      sunflower.context.beginPath();
      sunflower.context.lineWidth = 2;
      sunflower.context.fillStyle = this.color;
      sunflower.context.strokeStyle = this.color;
      sunflower.context.arc(this.x, this.y, this.radius, 0, TAU, false);
      sunflower.context.fill();
      sunflower.context.closePath();
      sunflower.context.stroke();
    }
  }

  class SunflowerSeed extends dart.mixin(Circle, CirclePainter) {
    constructor(x, y, radius, color) {
      if (color === undefined) color = null;
      super(x, y, radius);
      if (color !== null) this.color = color;
    }
  }

  // Function main: () → void
  function main() {
    sunflower.slider.addEventListener("change", (e) => draw());
    draw();
  }

  // Function draw: () → void
  function draw() {
    sunflower.seeds = core.int.parse(sunflower.slider.value);
    sunflower.context.clearRect(0, 0, MAX_D, MAX_D);
    for (let i = 0; i < sunflower.seeds; i++) {
      let theta = i * TAU / sunflower.PHI;
      let r = math.sqrt(i) * SCALE_FACTOR;
      let x = centerX + r * math.cos(theta);
      let y = centerY - r * math.sin(theta);
      new SunflowerSeed(x, y, SEED_RADIUS).draw();
    }
    sunflower.notes.textContent = "" + (sunflower.seeds) + " seeds";
  }

  // Exports:
  sunflower.ORANGE = ORANGE;
  sunflower.SEED_RADIUS = SEED_RADIUS;
  sunflower.SCALE_FACTOR = SCALE_FACTOR;
  sunflower.TAU = TAU;
  sunflower.MAX_D = MAX_D;
  sunflower.centerX = centerX;
  sunflower.centerY = centerY;
  sunflower.querySelector = querySelector;
  sunflower.Circle = Circle;
  sunflower.CirclePainter = CirclePainter;
  sunflower.SunflowerSeed = SunflowerSeed;
  sunflower.main = main;
  sunflower.draw = draw;
})(sunflower || (sunflower = {}));
