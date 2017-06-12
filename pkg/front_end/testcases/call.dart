class Callable {
  call(x) {
    return "string";
  }
}

class CallableGetter {
  get call => new Callable();
}

main() {
  var closure = (x) => x;
  var int1 = closure(1);
  var int2 = closure.call(1);
  var int3 = closure.call.call(1);
  var int4 = closure.call.call.call(1);

  var callable = new Callable();
  var string1 = callable(1);
  var string2 = callable.call(1);
  var string3 = callable.call.call(1);
  var string4 = callable.call.call.call(1);

  var callableGetter = new CallableGetter();
  var string5 = callableGetter(1);
  var string6 = callableGetter.call(1);
  var string7 = callableGetter.call.call(1);
  var string8 = callableGetter.call.call.call(1);

  var nothing1 = closure();
  var nothing2 = closure.call();
  var nothing3 = closure.call.call();
  var nothing4 = closure.call.call.call();

  var nothing5 = callable();
  var nothing6 = callable.call();
  var nothing7 = callable.call.call();
  var nothing8 = callable.call.call.call();

  var nothing9 = callableGetter();
  var nothing10 = callableGetter.call();
  var nothing11 = callableGetter.call.call();
  var nothing12 = callableGetter.call.call.call();
}
