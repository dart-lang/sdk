void main() {
  List<int> list = [1, 2, 3];
  print(subs(list));
}

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
