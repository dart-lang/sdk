class A<X extends A<X>> {}

A get g => throw 0;

main() {}
