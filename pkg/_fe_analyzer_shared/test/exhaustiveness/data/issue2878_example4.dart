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
      <A>[] /*space=<A>[]*/ => [],
      <A>[var x, ...var xs] /*space=<A>[Object?, ...List<A>]*/ => [
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
      <A>[] || <A>[_] /*space=<A>[]|<A>[Object?]*/ => [list],
      <A>[var x, ...var xs] /*space=<A>[Object?, ...List<A>]*/ => [
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
      (<A>[], <A>[]) /*space=(<A>[], <A>[])*/ => true,
      (<A>[_, ...], <A>[]) /*space=(<A>[Object?, ...List<A>], <A>[])*/ => false,
      (<A>[], <A>[_, ...]) /*space=(<A>[], <A>[Object?, ...List<A>])*/ => false,
      (
        <A>[var l, ...var ls],
        <A>[var r, ...var rs]
      ) /*space=(<A>[Object?, ...List<A>], <A>[Object?, ...List<A>])*/ =>
        l == r && equals(ls, rs),
    };
