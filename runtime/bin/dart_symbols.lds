{
  # Expose Dart_* API as well as malloc APIs (if we happen to statically link
  # tcmalloc)
  global:
    # Public API of Dart VM.
    Dart_*;

    # Public API of (possibly) linked malloc implementation
    malloc;
    calloc;
    realloc;
    aligned_alloc;
    posix_memalign;
    reallocarray;
    free;

    # Symbols intercepted by the sanitizers (incomplete, there are many more).
    getrlimit;

  # Hide everything else
  local:
    *;
};
