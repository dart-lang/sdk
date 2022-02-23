// From https://dart-review.googlesource.com/c/sdk/+/113126

class C {
  C() : assert = 0;
}

class C {
  C() : null = 0;
}

class C {
  C() : super = 0;
}

class C {
  C() : this = 0;
}
