// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include <map>
#include <regex>

#include "llvm/ADT/StringRef.h"
#include "llvm/Support/LineIterator.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/Regex.h"
#include "llvm/Support/WithColor.h"

namespace {

using namespace llvm;

struct Config {
  StringRef filename;
  StringRef out_dir;
};

StringMap<std::string> GetSubstitutions(const Config& config) {
  // Compute all of our strings needed for substitutions.
  StringRef test_dir = sys::path::parent_path(config.filename);
  StringRef basename = sys::path::filename(config.filename);
  SmallString<128> tmp_file;
  sys::path::append(tmp_file, sys::path::Style::native, config.out_dir,
                    basename + ".tmp");
  SmallString<128> codegen;
  sys::path::append(codegen, sys::path::Style::native, BIT_BINARY_DIR,
                    "codegen");
  SmallString<128> bit;
  sys::path::append(bit, sys::path::Style::native, BIT_BINARY_DIR, "bit");

  SmallString<128> clang;
  sys::path::append(clang, sys::path::Style::native, BIT_CLANG_DIR, "clang");

  // Set up our substitutions.
  StringMap<std::string> subs;
  subs["s"] = config.filename.str();
  subs["p"] = test_dir.str();
  subs["P"] = test_dir.str();
  subs["t"] = tmp_file.str().str();
  subs["{codegen}"] = codegen.str().str();
  subs["{bit}"] = bit.str().str();
  subs["{clang}"] = clang.str().str();
  return subs;
}

std::string PerformSubstitutions(const StringMap<std::string>& subs,
                                 StringRef string) {
  std::string out = string.str();
  for (const auto& sub : subs) {
    std::string key = (Twine("%") + sub.getKeyData()).str();
    size_t pos = 0;
    while ((pos = out.find(key, pos)) != std::string::npos) {
      if (pos != 0 && out[pos - 1] == '%') {
        pos += key.size();
        continue;
      }
      out.replace(pos, key.size(), sub.getValue());
      pos += sub.second.size();
    }
  }
  return out;
}

Optional<std::string> GetCommand(StringRef line) {
  static Regex run_line("^;[ ]*RUN:[ ]*(.*)$");
  SmallVector<StringRef, 2> cmd;
  if (!run_line.match(line, &cmd)) return Optional<std::string>{};
  assert(cmd.size() == 2);
  return cmd[1].str();
}

}  // namespace
