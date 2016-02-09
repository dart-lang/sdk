f(int a, b, [c = 1]) {
  f(a, b, c);
}
g(int a, b, {c : 1}) {
  f(a, b, c);
}

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
