var x = 1;
foo() => ++x > 10;
main() {
  print(foo() ? "hello world" : "bad bad");
}
