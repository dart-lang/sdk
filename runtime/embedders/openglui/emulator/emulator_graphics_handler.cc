// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/emulator/emulator_graphics_handler.h"

#include <stdlib.h>
#include <string.h>

EmulatorGraphicsHandler::EmulatorGraphicsHandler(int argc,
                                                 char** argv)
  : GLGraphicsHandler() {
  glutInit(&argc, argv);
  width_ = 480;
  height_ = 800;
  for (int i = 1; i < argc; i++) {
    if (argv[i][0] == '-') {
      int next_arg = i + 1;
      if (next_arg < argc && strcmp(argv[i], "-w") == 0) {
        width_ = static_cast<size_t>(atoi(argv[i = next_arg]));
      } else if (next_arg < argc && strcmp(argv[i], "-h") == 0) {
        height_ = static_cast<size_t>(atoi(argv[i = next_arg]));
      }
    }
  }
}

int32_t EmulatorGraphicsHandler::Start() {
  glutInitWindowSize(width_, height_);
  glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
  glutCreateWindow("Dart");
  return 0;
}

void EmulatorGraphicsHandler::Stop() {
  exit(0);
}

