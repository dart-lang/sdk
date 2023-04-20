void main() {
  List<int> list = [1, 2, 3];
  print(subs(list));
  print(perms(list));
  print(equals(list, list));
}

List<List<A>> subs<A>(List<A> list) => switch (list) {
      <A>[] => [],
      <A>[var x, ...var xs] => [
        for (var ys in subs(xs)) ...[
          [x] + ys,
          ys
        ],
        [x]
      ],
    };

List<List<A>> perms<A>(List<A> list) => switch (list) {
      <A>[] || <A>[_] => [list],
      <A>[var x, ...var xs] => [
        for (var i = 0; i < list.length; i++)
          for (var perm in perms(xs)) [...perm.take(i), x, ...perm.skip(i)]
      ],
    };

bool equals<A>(List<A> a, List<A> b) => switch ((a, b)) {
      (<A>[], <A>[]) => true,
      (<A>[_, ...], <A>[]) => false,
      (<A>[], <A>[_, ...]) => false,
      (<A>[var l, ...var ls], <A>[var r, ...var rs]) =>
        l == r && equals(ls, rs),
    };
