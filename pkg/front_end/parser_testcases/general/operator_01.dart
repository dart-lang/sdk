class Foo {
  bool operator <(int x) {
    return true;
  }

  int operator <<(int x) {
    return 42;
  }

  bool operator >(int x) {
    return true;
  }

  int operator >>(int x) {
    return 42;
  }

  int operator >>>(int x) {
    return 42;
  }
}
