// Expectation for test: 
// main() {
//   var xs = ['x', 'y', 'z'], ys = ['A', 'B', 'C'];
//   var xit = xs.iterator, yit = ys.iterator;
//   while (xit.moveNext() && yit.moveNext()) {
//     print(xit.current);
//     print(yit.current);
//   }
// }

function() {
  var xs = ["x", "y", "z"], ys = ["A", "B", "C"], i = 0, i1 = 0, current, current1;
  for (; i < 3; ++i, ++i1) {
    current = xs[i];
    if (!(i1 < 3))
      break;
    current1 = ys[i1];
    P.print(current);
    P.print(current1);
  }
}
