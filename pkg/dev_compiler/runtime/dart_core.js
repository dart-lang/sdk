var dart_core;
(function (dart_core) {
  var Object = (function () {
    var constructor = function Object() {};

    constructor.prototype.toString = function toString() {
      return 'Instance of ' + this.constructor.name;
    };

    constructor.prototype.noSuchMethod = function noSuchMethod(invocation) {
      // TODO: add arguments when Invocation is defined
      throw new NoSuchMethodError();
    };

    // TODO: implement ==

    // TODO: implement hashCode

    // TODO: implement runtimeType

    return constructor;
  })();
  dart_core.Object = Object;

  function print(obj) {
    console.log(obj.toString());
  }
  dart_core.print = print;

  var NoSuchMethodError = (function () {
    // TODO(vsm): Implement.
    function NoSuchMethodError(f, args) {
    }
    return NoSuchMethodError;
  })();
  dart_core.NoSuchMethodError = NoSuchMethodError;
})(dart_core || (dart_core = {}));
