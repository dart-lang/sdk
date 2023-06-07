void main() {
  var (int x, (int, )? y) = switch (foo) {
    _ => (42, null),
  };
}
