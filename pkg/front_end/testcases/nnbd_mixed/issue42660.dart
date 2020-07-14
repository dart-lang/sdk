// @dart=2.8
import 'issue42660_lib.dart';

void main() {
  f().m();
  (f)().m();
  p.m();
  var c = new Class();
  c.f().m();
  (c.f)().m();
  c.p.m();
  c..p.m()..f().m();
  new Class()..p.m()..f().m();
}
