void f(bool b1, bool b2) {
  print('b1=$b1, b2=$b2');
}

void g(int x, int y, Object o, Object p) async {
  f(x < y, (await o, ) > (p as int));
}

void main() {
  g(0, 1, 2, 3);
}

extension on Map {
  bool operator>(dynamic whatever) {
    return true;
  }
}
