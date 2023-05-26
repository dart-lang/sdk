main() {
  var ((a1,),) = ((-1,),);
  var (n: (x: a2)) = (n: (x: 42));
  var (n: (x: a3, b3), (y: c3, d3)) = (n: (x: 42, -1), (y: 1, 0));

  final ((a4,),) = ((-1,),);
  final (n: (x: a5)) = (n: (x: 42));
  final (n: (x: a6, b6), (y: c6, d6)) = (n: (x: 42, -1), (y: 1, 0));

  var ((int a7,),) = ((-1,),);
  var (n: (x: int a8)) = (n: (x: 42));
  var (n: (x: int a9, int b9), (y: int c9, int d9))
      = (n: (x: 42, -1), (y: 1, 0));

  var (n: (int, {int x}) a10, (int z, {int y}) b10)
      = (n: (x: 42, -1), (y: 1, 0));

  var ((a1,)?,) = (null,);
  var (n: (x: a2)?) = (n: null);
  var (n: (x: a3, b3)?, (y: c3, d3)?) = (n: null, null);

  final ((a4,)?,) = (null,);
  final (n: (x: a5)?) = (n: null);
  final (n: (x: a6, b6)?, (y: c6, d6)?) = (n: null, null);

  var ((int a7,)?,) = (null,);
  var (n: (x: int a8)?) = (n: null);
  var (n: (x: int a9, int b9)?, (y: int c9, int d9)?)
      = (n: null, null);

  var (n: (int, {int x})? a10, (int z, {int y})? b10)
      = (n: null, null);
}
