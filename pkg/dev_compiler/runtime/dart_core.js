var dart_core;
(function (dart_core) {
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
