main() {
  var xs = ['x', 'y', 'z'], ys = ['A', 'B', 'C'];
  var xit = xs.iterator, yit = ys.iterator;
  while (xit.moveNext() && yit.moveNext()) {
    print(xit.current);
    print(yit.current);
  }
}
