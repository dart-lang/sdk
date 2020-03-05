(function() {

  // A constructor function with the same name as a HTML element.
  function HTMLDivElement(a) {
    this.a = a;
  }

  HTMLDivElement.prototype.bar = function() {
    return this.a;
  }

  HTMLDivElement.prototype.toString = function() {
    return "HTMLDivElement(" + this.a + ")";
  }

  self.makeDiv = function(text) {
    return new HTMLDivElement(text);
  };

})();
