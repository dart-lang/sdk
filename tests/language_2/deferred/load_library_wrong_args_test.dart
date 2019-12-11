import "load_library_wrong_args_lib.dart" deferred as lib;

void main() {
  // Loadlibrary should be called without arguments.
  lib.loadLibrary(10);
//^
// [analyzer] unspecified
// [cfe] 'loadLibrary' takes no arguments.
  //             ^
  // [analyzer] unspecified
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
}
