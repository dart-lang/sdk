void main() {
  List<int> list = [1, 2, 3];
  print(subs(list));
}

List<List<A>> subs<A>(
        List<A>
            list) => /*
         checkingOrder={List<A>,<A>[],<A>[(), ...]},
         subtypes={<A>[],<A>[(), ...]},
         type=List<A>
        */
    switch (list) {
      [] /*space=<[]>*/ => [],
      [var x, ...var xs] /*space=<[Object?, ...List<A>]>*/ => [
        for (var ys in subs(xs)) ...[
          [x] + ys,
          ys
        ],
        [x]
      ],
    };
