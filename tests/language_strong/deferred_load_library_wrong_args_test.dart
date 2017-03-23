import "deferred_load_library_wrong_args_lib.dart" deferred as lib;

void main() {
  // Loadlibrary should be called without arguments.
  lib.loadLibrary(
      10 //# 01: runtime error
      );
}
