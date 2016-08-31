import 'package:js/src/varargs.dart' as js;
import 'package:js/src/varargs.dart' show rest, spread;

varargsTest(x, @js.rest others) {
  var args = [1, others];
  x.call(js.spread(args));
}

varargsTest2(x, @rest others) {
  var args = [1, others];
  x.call(spread(args));
}
