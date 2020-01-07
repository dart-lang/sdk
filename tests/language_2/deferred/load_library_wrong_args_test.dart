import "load_library_wrong_args_lib.dart" deferred as lib;

void main() {
  // Loadlibrary should be called without arguments.
  lib.loadLibrary(10);
//^
// [cfe] 'loadLibrary' takes no arguments.
  //             ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
//    ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LOAD_LIBRARY_TAKES_NO_ARGUMENTS
}
