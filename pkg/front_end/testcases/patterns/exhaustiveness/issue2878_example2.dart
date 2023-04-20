void main() {
  List<int> list = [1, 2, 3];
  print(f(list));
  print(subs(list));
  print(perms(list));
  print(equals(list, list));
}

List<A> f<A>(List<A> list) => switch (list) {
      [] => [],
      [...] => [],
    };

List<List<A>> subs<A>(List<A> list) => switch (list) {
      [] => [],
      [var x, ...var xs] => [
        for (var ys in subs(xs)) ...[
          [x] + ys,
          ys
        ],
        [x]
      ],
    };

List<List<A>> perms<A>(List<A> list) => switch (list) {
      [] || [_] => [list],
      [var x, ...var xs] => [
        for (var i = 0; i < list.length; i++)
          for (var perm in perms(xs)) [...perm.take(i), x, ...perm.skip(i)]
      ],
    };

bool equals<A>(List<A> a, List<A> b) => switch ((a, b)) {
      ([], []) => true,
      ([_, ...], []) => false,
      ([], [_, ...]) => false,
      ([var l, ...var ls], [var r, ...var rs]) => l == r && equals(ls, rs),
    };
