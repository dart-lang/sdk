To build Dart for Mac and Linux, we pull Fuchsia's buildtools, which is also
used by Flutter. Fuchsia's buildtools includes gn, ninja, and the clang
toolchain. Fuchsia buildtools vends clang-format as part of the clang toolchain.
Since Fuchsia's buildtools doesn't vend a clang toolchain for Windows, we can't
get a Windows clang-format binary from it. Therefore, from Chromium's buildtools
here:

https://chromium.googlesource.com/chromium/buildtools

we copy the hash file for its Windows clang-format binary, and pull it down
from google storage in the update.py script in this directory.

To update to a newer Windows clang-format binary, simply overwrite the hash in
clang-format.exe.sha1 with a newer one, and then do a 'gclient sync'.
