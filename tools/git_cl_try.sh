
function git-cl-try-vm-jit-app {
  echo "git-cl-try-vm-jit-app"
  git cl try -B dart/try                                     \
     -b app-kernel-linux-debug-x64-try                       \
     -b app-kernel-linux-product-x64-try                     \
     -b app-kernel-linux-release-x64-try
}
function git-cl-try-vm-jit-reload {
  echo "git-cl-try-vm-jit-reload"
  git cl try -B dart/try                                     \
   -b vm-kernel-reload-linux-debug-x64-try                   \
   -b vm-kernel-reload-linux-release-x64-try                 \
   -b vm-kernel-reload-rollback-linux-debug-x64-try          \
   -b vm-kernel-reload-rollback-linux-release-x64-try
}
function git-cl-try-vm-jit-rest {
  echo "git-cl-try-vm-jit-rest"
  git cl try -B dart/try                                     \
   -b vm-kernel-checked-linux-release-x64-try                \
   -b vm-kernel-linux-debug-ia32-try                         \
   -b vm-kernel-linux-debug-x64-try                          \
   -b vm-kernel-linux-product-x64-try                        \
   -b vm-kernel-linux-release-ia32-try                       \
   -b vm-kernel-linux-release-simarm-try                     \
   -b vm-kernel-linux-release-simarm64-try                   \
   -b vm-kernel-linux-release-x64-try                        \
   -b vm-kernel-mac-debug-x64-try                            \
   -b vm-kernel-mac-product-x64-try                          \
   -b vm-kernel-mac-release-x64-try                          \
   -b vm-kernel-nnbd-linux-debug-x64-try                     \
   -b vm-kernel-nnbd-linux-release-x64-try                   \
   -b vm-kernel-optcounter-threshold-linux-release-ia32-try  \
   -b vm-kernel-optcounter-threshold-linux-release-x64-try   \
   -b vm-kernel-win-debug-ia32-try                           \
   -b vm-kernel-win-debug-x64-try                            \
   -b vm-kernel-win-product-x64-try                          \
   -b vm-kernel-win-release-ia32-try                         \
   -b vm-kernel-win-release-x64-try
}
function git-cl-try-vm-ffi {
  echo "git-cl-try-vm-ffi"
  git cl try -B dart/try                                     \
     -b vm-ffi-android-debug-arm-try                         \
     -b vm-ffi-android-debug-arm64-try                       \
     -b vm-ffi-android-product-arm-try                       \
     -b vm-ffi-android-product-arm64-try                     \
     -b vm-ffi-android-release-arm-try                       \
     -b vm-ffi-android-release-arm64-try
}
function git-cl-try-vm-precomp {
  echo "git-cl-try-vm-precomp"
  git cl try -B dart/try                                     \
     -b vm-kernel-precomp-android-release-arm64-try          \
     -b vm-kernel-precomp-android-release-arm_x64-try        \
     -b vm-kernel-precomp-linux-debug-simarm_x64-try         \
     -b vm-kernel-precomp-linux-debug-x64-try                \
     -b vm-kernel-precomp-linux-product-x64-try              \
     -b vm-kernel-precomp-linux-release-simarm-try           \
     -b vm-kernel-precomp-linux-release-simarm64-try         \
     -b vm-kernel-precomp-linux-release-simarm_x64-try       \
     -b vm-kernel-precomp-linux-release-x64-try              \
     -b vm-kernel-precomp-mac-release-simarm64-try           \
     -b vm-kernel-precomp-obfuscate-linux-release-x64-try    \
     -b vm-kernel-precomp-win-release-x64-try                \
     -b vm-precomp-ffi-qemu-linux-release-arm-try
}
function git-cl-try-vm-san {
  echo "git-cl-try-vm-jit-san"
  git cl try -B dart/try                                     \
   -b vm-kernel-asan-linux-release-x64-try                   \
   -b vm-kernel-msan-linux-release-x64-try                   \
   -b vm-kernel-tsan-linux-release-x64-try                   \
   -b vm-kernel-precomp-asan-linux-release-x64-try           \
   -b vm-kernel-precomp-msan-linux-release-x64-try           \
   -b vm-kernel-precomp-tsan-linux-release-x64-try           \
}
function git-cl-try-vm-all {
  echo "git-cl-try-vm-all"
  git-cl-try-vm-jit-app
  git-cl-try-vm-jit-reload
  git-cl-try-vm-jit-rest
  git-cl-try-vm-ffi
  git-cl-try-vm-precomp
  git-cl-try-vm-san
}
