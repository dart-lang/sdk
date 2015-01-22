var sunflower;
(function (sunflower) {
  'use strict';
  let ORANGE = "orange";
  let SEED_RADIUS = 2;
  let SCALE_FACTOR = 4;
  let TAU = PI * 2;
  let MAX_D = 300;
  let centerX = MAX_D / 2;
  let centerY = centerX;
  // Function querySelector: (String) → Element
  function querySelector(selector) { return document.querySelector(selector); }

  let slider = /* Unimplemented lazy eval *//* Unimplemented: DownCast: Element to InputElement */ querySelector("#slider");
  let notes = /* Unimplemented lazy eval */querySelector("#notes");
  let PHI = /* Unimplemented lazy eval */(dart.math.sqrt(5) + 1) / 2;
  let seeds = 0;
  let context = /* Unimplemented lazy eval *//* Unimplemented: DownCast: RenderingContext to CanvasRenderingContext2D */ (/* Unimplemented: as CanvasElement. */querySelector("#canvas")).getContext("2d");
  class Circle {
    constructor(x, y, radius, color) {
      this.x = x;
      this.y = y;
      this.radius = radius;
      this.color = color;
    }
    draw() {
      (context.beginPath(),
        context.lineWidth = 2,
        context.fillStyle = this.color,
        context.strokeStyle = this.color,
        context.arc(this.x, this.y, this.radius, 0, TAU, false),
        context.fill(),
        context.closePath(),
        context.stroke());
    }
  }

  class SunflowerSeed extends Circle {
    constructor(x, y) {
      super(x, y, SEED_RADIUS, ORANGE);
    }
  }

  // Function main: () → void
  function main() {
    slider.addEventListener("change", (e) => draw());
    draw();
  }


  // Function draw: () → void
  function draw() {
    seeds = int.parse(slider.value);
    context.clearRect(0, 0, MAX_D, MAX_D);
    for (let i = 0; i < seeds; i++) {
      let theta = i * TAU / PHI;
      let r = dart.math.sqrt(i) * SCALE_FACTOR;
      let x = centerX + r * dart.math.cos(theta);
      let y = centerY - r * dart.math.sin(theta);
      new SunflowerSeed(x, y).draw();
    }
    notes.textContent = "" + (seeds) + " seeds";
  }


  // Exports:
  sunflower.querySelector = querySelector;
  sunflower.Circle = Circle;
  sunflower.SunflowerSeed = SunflowerSeed;
  sunflower.main = main;
  sunflower.draw = draw;
})(sunflower || (sunflower = {}));
