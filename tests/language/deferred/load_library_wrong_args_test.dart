import "load_library_wrong_args_lib.dart" deferred as lib;

void main() {
  // Loadlibrary should be called without arguments.
  lib.loadLibrary(10);
//^
// [cfe] 'loadLibrary' takes no arguments.
//               ^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
}
