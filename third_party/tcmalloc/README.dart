Dart uses tcmalloc in the standalone VM on Linux.

To roll tcmalloc forward:
. Clone the gperftools git repo at the revision you want in a directory off
  to the side.

. Run a configure command similar to the one in the configure_command file in
  this directory. It is up to you to determine if different flags are required
  for the newer gperftools.

. From that repo, copy src/config.h and src/gperftools/tcmalloc.h, and any other
  generated header files to the include/ directory in this directory.

. Also copy the COPYING file and any other relevant licensing information.

. Make sure that include/config.h defines HAVE_UCONTEXT_H on Linux,

. Update tcmalloc_sources.gypi, and tcmalloc.gyp if necessary. This may require
  inspecting gperftools/Makefile.am to see any additional source files and
  preprocessor defines (-D flags).

. Update the DEPS file with the new git hash.

. Build and run tests for Debug, Release, and Product builds for ia32, x64,
  and arm for Linux and any other OSs that are supported.
