// compile options: --destructure-named-params
import 'dart-ext:foo';
import 'package:js/src/varargs.dart';

f(int a, b, [c = 1]) {
  f(a, b, c);
}
external f_ext(int a, b, [c = 1]);
f_nat(int a, b, [c = 1]) native "f_nat";
f_sync(int a, b, [c = 1]) sync* {}
f_async(int a, b, [c = 1]) async* {}

g(int a, b, {c : 1}) {
  f(a, b, c);
}
external g_ext(int a, b, {c : 1});
g_nat(int a, b, {c : 1}) native "g_nat";
g_sync(int a, b, {c : 1}) sync* {}
g_async(int a, b, {c : 1}) async* {}

r(int a, @rest others) {
  r(a, spread(others));
}
external r_ext(int a, @rest others);
r_nat(int a, @rest others) native "r_nat";
r_sync(int a, @rest others) sync* {}
r_async(int a, @rest others) async* {}

invalid_names1(int let, function, arguments) {
  f(let, function, arguments);
}
invalid_names2([int let, function = 1, arguments]) {
  f(let, function, arguments);
}
invalid_names3({int let, function, arguments : 2}) {
  f(let, function, arguments);
}

names_clashing_with_object_props({int constructor, valueOf, hasOwnProperty : 2}) {
  f(constructor, valueOf, hasOwnProperty);
}
