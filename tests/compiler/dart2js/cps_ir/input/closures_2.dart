main(x) {
  a() {
    return x;
  }
  x = x + '1';
  print(a());
  return a;
}

