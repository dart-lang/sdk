class late {
  int get g => 1;
}

class required {
  int get g => 2;
}

class C {
  late l = late();
  required r = required();
}
