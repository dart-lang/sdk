// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/disassembler.h"

#include "vm/assert.h"

namespace dart {

void Disassembler::Disassemble(uword start,
                               uword end,
                               DisassemblyFormatter* formatter) {
  // First print the actual addresses so that we know where in memory this is
  // being disassembled from.
  formatter->Print("start: %p  end: %p\n", start, end);

  // Write code block to tmp file.
  char tmp[] = "/tmp/codeblock.XXXXXX";
  int fd = mkstemp(tmp);
  if (fd < 0) {
    int errsv = errno;
    formatter->Print("Could not open tmp file %s, errno=%s\n",
                     tmp,
                     strerror(errsv));
    return;  // failed
  }
  ssize_t size = write(fd, reinterpret_cast<const void*>(start), end - start);
  if (size <= 0) {
    if (size < 0) {
      int errsv = errno;
      formatter->Print("Could not write to tmp file %s, errno=%s\n",
                       tmp,
                       strerror(errsv));
    }
    close(fd);
    remove(tmp);
    return;
  }
  close(fd);

  // Disassemble tmp file to stdout.
  char cmd[256];
#if defined(__APPLE__)
  snprintf(cmd, sizeof(cmd),
           "( cat %1$s | "
           "  hexdump -v -e '\".byte \" 1/1 \"0x%%02x\" \"\n\"' | "
           "  as - -arch x86_64 -o %1$s.o ; otool -tV %1$s.o"
           ") </dev/null 2>&1", tmp);
#else
  snprintf(cmd, sizeof(cmd), "( /usr/bin/objdump -b binary -m i386:x86-64 -D %s"
          " ) </dev/null 2>&1", tmp);
#endif
  FILE* output = popen(cmd, "r");
  if (output == NULL) {
    int errsv = errno;
    formatter->Print("Could not run \"%s\", errno=%s\n", cmd, strerror(errsv));
    remove(tmp);
    return;  // failed
  }
  const int kMaxOutputLine = 1024;
  char line[kMaxOutputLine];
#if defined(__APPLE__)
  const char* header = "(__TEXT,__text) section\n";
#else
  const char* header = "<.data>:\n";
#endif
  char* header_pos = NULL;
  while (header_pos == NULL && fgets(line, sizeof(line), output) != NULL) {
    header_pos = strstr(line, header);
    if (header_pos != NULL) {
      formatter->Print("%s", header_pos + strlen(header));
    }
  }
  while (fgets(line, sizeof(line), output) != NULL) {
    formatter->Print("%s", line);
  }
  pclose(output);

  // Delete tmp files.
  remove(tmp);
#if defined(__APPLE__)
  char tmp_o[32];
  snprintf(tmp_o, sizeof(tmp_o), "%s.o", tmp);
  remove(tmp_o);
#endif
}


int Disassembler::DecodeInstruction(char* hexa_buffer, intptr_t hexa_size,
                                    char* human_buffer, intptr_t human_size,
                                    uword pc) {
  UNIMPLEMENTED();
  return 0;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
