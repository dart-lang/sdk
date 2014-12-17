var sunflower;
(function (sunflower) {
  var ORANGE = function() { return "orange"; }();
  var SEED_RADIUS = function() { return 2; }();
  var SCALE_FACTOR = function() { return 4; }();
  var TAU = function() { return PI * 2; }();
  var MAX_D = function() { return 300; }();
  var centerX = function() { return MAX_D / 2; }();
  var centerY = function() { return centerX; }();
  // Function querySelector: (String) → Element
  function querySelector(selector) { return document.querySelector(selector); }
  sunflower.querySelector = querySelector;

  var slider = function() { return /* Unimplemented: DownCast: Element to InputElement */ sunflower.querySelector("#slider"); }();
  var notes = function() { return sunflower.querySelector("#notes"); }();
  var PHI = function() { return (dart.math.sqrt(5) + 1) / 2; }();
  var seeds = function() { return 0; }();
  var context = function() { return /* Unimplemented: DownCast: RenderingContext to CanvasRenderingContext2D */ (/* Unimplemented: as CanvasElement. */sunflower.querySelector("#canvas")).getContext("2d"); }();
  // Function main: () → void
  function main() {
    slider.addEventListener("change", /* Unimplemented: bind any free variables. */function(e) { return sunflower.draw(); });
    sunflower.draw();
  }
  sunflower.main = main;

  // Function draw: () → void
  function draw() {
    seeds = int.parse(slider.value);
    context.clearRect(0, 0, MAX_D, MAX_D);
    for (var i = 0; i < seeds; i++) {
      var theta = i * TAU / PHI;
      var r = dart.math.sqrt(i) * SCALE_FACTOR;
      sunflower.drawSeed(centerX + r * dart.math.cos(theta), centerY - r * dart.math.sin(theta));
    }
    notes.textContent = "null";
  }
  sunflower.draw = draw;

  // Function drawSeed: (num, num) → void
  function drawSeed(x, y) {
    (context.beginPath(),
      context.lineWidth = 2,
      context.fillStyle = ORANGE,
      context.strokeStyle = ORANGE,
      context.arc(x, y, SEED_RADIUS, 0, TAU, false),
      context.fill(),
      context.closePath(),
      context.stroke());
  }
  sunflower.drawSeed = drawSeed;

})(sunflower || (sunflower = {}));
