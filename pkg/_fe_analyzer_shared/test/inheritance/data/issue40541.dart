/*library: nnbd=true*/
/*class: A:A<T>,Object*/
class A<T> {
  /*member: A.test:void Function()!*/
  void test() {
    print(T);
  }
}

/*class: B:A<Object?>,B,Object*/
/*member: B.test:void Function()!*/
class B extends A<Object?> {}

/*class: C:A<dynamic>,C,Object*/
/*member: C.test:void Function()!*/
class C extends A<dynamic> {}

/*class: D1:A<Object?>,B,C,D1,Object*/
/*member: D1.test:void Function()!*/
class D1 extends B implements C {}

/*class: D2:A<Object?>,B,C,D2,Object*/
/*member: D2.test:void Function()!*/
class D2 extends C implements B {}

void main() {
  D1().test();
  D2().test();
}
