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
  var context = function() { return (/* Unimplemented: as CanvasElement. */sunflower.querySelector("#canvas")).context2D; }();
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
      var theta = /* Unimplemented binary operator: i * TAU / PHI */;
      var r = dart.math.sqrt(i) * SCALE_FACTOR;
      sunflower.drawSeed(/* Unimplemented binary operator: centerX + r * cos(theta) */, /* Unimplemented binary operator: centerY - r * sin(theta) */);
    }
    notes.textContent = "null";
  }
  sunflower.draw = draw;

  // Function drawSeed: (num, num) → void
  function drawSeed(x, y) {
    var context$0 = context;
    context$0.beginPath();
    context$0.lineWidth = 2;
    context$0.fillStyle = ORANGE;
    context$0.strokeStyle = ORANGE;
    context$0.arc(x, y, SEED_RADIUS, 0, TAU, false);
    context$0.fill();
    context$0.closePath();
    context$0.stroke();
  }
  sunflower.drawSeed = drawSeed;

})(sunflower || (sunflower = {}));
