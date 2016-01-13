// TODO(sigmund): change this to check method "function(Sub#+)" once we provide
// a way to disable inlining of Sub#+, which is compiled to something like:
// function(x) {
//   var v0, v1, v2;
//   v0 = 1;
//   v1 = J.getInterceptor$ns(x).$add(x, v0);
//   v2 = this;
//   return V.Base.prototype.$add.call(null, v2, v1);
// }

class Base {
  m(x) {
    print(x+1000);
  }
  operator+(x) => m(x+10);
}
class Sub extends Base {
  m(x) => super.m(x+100);
  operator+(x) => super + (x+1);
}
main() {
  new Sub() + 10000;
}
