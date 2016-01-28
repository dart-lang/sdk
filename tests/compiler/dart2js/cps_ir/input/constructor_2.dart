class Base {
  var x;
  Base(this.x);
}
class Sub extends Base {
  var y;
  Sub(x, this.y) : super(x) {
    print(x);
  }
}
main() {
  print(new Sub(1, 2).x);
}
