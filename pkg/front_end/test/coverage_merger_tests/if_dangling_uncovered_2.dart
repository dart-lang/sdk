void main() {
  print("hello");
  Forest forest = new Forest();
  if (1 + 1 == 3) push(forest.createBlock(noLocation, noLocation, []));
  push(forest.createBlock(42, 42, [42]));
}

const int noLocation = -1;

void push(dynamic whatever) {}

class Forest {
  dynamic createBlock(int a, int b, List c) {
    return "$a$b$c";
  }
}
