void main() {
  List<int> list = [1, 2, 3];
  print(subs(list));
  print(perms(list));
  print(equals(list, list));
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

List<List<A>> perms<A>(
        List<A>
            list) => /*
         checkingOrder={List<A>,<A>[],<A>[(), ...]},
         subtypes={<A>[],<A>[(), ...]},
         type=List<A>
        */
    switch (list) {
      [] || [_] /*space=<[]|[Object?]>*/ => [list],
      [var x, ...var xs] /*space=<[Object?, ...List<A>]>*/ => [
        for (var i = 0; i < list.length; i++)
          for (var perm in perms(xs)) [...perm.take(i), x, ...perm.skip(i)]
      ],
    };

bool equals<A>(
        List<A> a,
        List<A>
            b) => /*
 fields={$1:List<A>,$2:List<A>},
 type=(List<A>, List<A>)
*/
    switch ((a, b)) {
      ([], []) /*space=([], [])*/ => true,
      ([_, ...], []) /*space=([Object?, ...List<A>], [])*/ => false,
      ([], [_, ...]) /*space=([], [Object?, ...List<A>])*/ => false,
      (
        [var l, ...var ls],
        [var r, ...var rs]
      ) /*space=([Object?, ...List<A>], [Object?, ...List<A>])*/ =>
        l == r && equals(ls, rs),
    };
