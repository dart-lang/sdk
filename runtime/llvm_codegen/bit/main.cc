// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include <cctype>
#include <map>
#include <regex>

#include "bit.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/LineIterator.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/Process.h"
#include "llvm/Support/Program.h"
#include "llvm/Support/Regex.h"
#include "llvm/Support/VirtualFileSystem.h"
#include "llvm/Support/WithColor.h"

using namespace llvm;

namespace {

StringRef tool_name;

LLVM_ATTRIBUTE_NORETURN void Fail(Twine message) {
  WithColor::error(errs(), tool_name) << message << ".\n";
  errs().flush();
  exit(1);
}

LLVM_ATTRIBUTE_NORETURN void Fail(Error e) {
  assert(E);
  std::string buf;
  raw_string_ostream os(buf);
  logAllUnhandledErrors(std::move(e), os);
  os.flush();
  WithColor::error(errs(), tool_name) << buf;
  exit(1);
}

LLVM_ATTRIBUTE_NORETURN void ReportError(StringRef file, std::error_code ec) {
  assert(ec);
  Fail(createFileError(file, ec));
}

std::string ReadFile(FILE* file) {
  std::string output;
  constexpr size_t buf_size = 256;
  char buf[buf_size];
  size_t size;
  while ((size = fread(buf, buf_size, sizeof(buf[0]), file)))
    output.append(buf, buf + buf_size);
  return output;
}

bool IsPosixFullyPortablePath(StringRef path) {
  const char* extra = "._-/";
  for (auto c : path)
    if (!isalnum(c) && !strchr(extra, c)) return false;
  return true;
}

}  // namespace

int main(int argc, char** argv) {
  InitLLVM X(argc, argv);

  // Make sure we have both arguments.
  tool_name = argv[0];
  if (argc != 3) Fail("expected exactly 2 arguments");

  // Makes sure that stdin/stdout are setup correctly.
  if (sys::Process::FixupStandardFileDescriptors())
    Fail("std in/out fixup failed");

  // Set our config.
  Config config;
  config.filename = argv[1];
  config.out_dir = argv[2];

  // Make sure we have valid filepaths.
  if (!IsPosixFullyPortablePath(config.filename))
    Fail("'" + config.filename + "' is not a posix fully portable filename");
  if (!IsPosixFullyPortablePath(config.out_dir))
    Fail("'" + config.out_dir + "' is not a posix fully portable filename");

  // Compute substitutions.
  auto subs = GetSubstitutions(config);

  // The lines we execute are allowed to assume that %p will exist.
  sys::fs::create_directory(subs["p"]);

  // Open the file for reading.
  auto buf_or = vfs::getRealFileSystem()->getBufferForFile(config.filename);
  if (!buf_or) ReportError(config.filename, buf_or.getError());
  auto buf = std::move(*buf_or);

  // Now iterate over the lines in the file.
  line_iterator it{*buf};
  int count = 0;
  for (StringRef line = *it; !it.is_at_end(); line = *++it) {
    auto cmd = GetCommand(line);
    if (!cmd) continue;
    ++count;
    auto subbed = PerformSubstitutions(subs, *cmd);
    FILE* file = popen(subbed.c_str(), "r");
    std::string output = ReadFile(file);
    if (pclose(file) != 0) {
      errs() << output << "\n";
      Fail("Failure on line " + Twine(it.line_number()) + "\n\t" + subbed + "");
    }
  }
  if (count == 0) {
    Fail("No commands to run");
  }
  outs() << "Commands run: " << count << "\n";
  return 0;
}
