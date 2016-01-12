var x = 1;
get foo => ++x > 10;
main() { print(foo || foo); }

