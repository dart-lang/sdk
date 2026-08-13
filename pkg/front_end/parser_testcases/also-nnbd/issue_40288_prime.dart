class Xlate {
  int get g => 1;
}

class Xrequired {
  int get g => 2;
}

class C {
  Xlate l = Xlate();
  Xrequired r = Xrequired();
}
