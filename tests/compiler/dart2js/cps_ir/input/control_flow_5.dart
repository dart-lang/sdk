foo(a) { print(a); return a; }

main() {
 foo(false);
 if (foo(true)) {
   print(1);
   print(1);
 } else {
   print(2);
   print(2);
 }
 print(3);
}
