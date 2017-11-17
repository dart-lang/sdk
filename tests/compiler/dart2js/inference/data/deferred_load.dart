import 'package:expect/expect.dart' deferred as expect;

/*element: main:[null]*/
main() {
  callLoadLibrary();
}

/*element: callLoadLibrary:[null|subclass=Object]*/
callLoadLibrary() => expect.loadLibrary();
