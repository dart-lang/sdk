// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/emulator/emulator_embedder.h"

#include <string.h>
#include <sys/time.h>
#include <time.h>
#include "embedders/openglui/common/canvas_context.h"
#include "embedders/openglui/common/context.h"
#include "embedders/openglui/common/dart_host.h"
#include "embedders/openglui/common/events.h"
#include "embedders/openglui/common/input_handler.h"
#include "embedders/openglui/common/log.h"
#include "embedders/openglui/common/sound_handler.h"
#include "embedders/openglui/common/vm_glue.h"
#include "embedders/openglui/emulator/emulator_graphics_handler.h"
#include "embedders/openglui/emulator/emulator_resource.h"

InputHandler* input_handler_ptr;
LifeCycleHandler* lifecycle_handler_ptr;

struct timeval tvStart;
void tick(int data);

Resource* MakePlatformResource(const char *path) {
  return new EmulatorResource(path);
}

void display() {
  // Get number of msecs since last call.
  struct timeval tvEnd;
  gettimeofday(&tvEnd, NULL);
  uint64_t now = (tvEnd.tv_usec + 1000000 * tvEnd.tv_sec);

  if (lifecycle_handler_ptr->OnStep() != 0) {
    exit(-1);
  }
  // Schedule next call, trying to aim for 60fps.
  uint64_t elapsed = now - (tvStart.tv_usec + 1000000 * tvStart.tv_sec);
  int delay = 1000 / 60 - (elapsed / 1000);
  if (delay < 0) delay = 0;
  tvStart = tvEnd;
  glutTimerFunc(delay, tick, 0);
}

void tick(int data) {
  display();
}

void reshape(int width, int height) {
  glViewport(0, 0, width, height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, width, 0, height, -1, 1);
  glMatrixMode(GL_MODELVIEW);
  glutPostRedisplay();
}

void keyboard(unsigned char key, int x, int y) {
  input_handler_ptr->OnKeyEvent(kKeyDown, time(0), key, false, false, false, 0);
  input_handler_ptr->OnKeyEvent(kKeyUp, time(0), key, false, false, false, 0);
  if (key == 'Q') {
    lifecycle_handler_ptr->Pause();
    lifecycle_handler_ptr->Deactivate();
    lifecycle_handler_ptr->FreeAllResources();
    exit(0);
  } else if (key == 'S') {
    LOGI("Simulating suspend");
    lifecycle_handler_ptr->Pause();
    lifecycle_handler_ptr->Deactivate();
  } else if (key == 'R') {
    LOGI("Simulating resume");
    lifecycle_handler_ptr->Activate();
    lifecycle_handler_ptr->Resume();
  } else if (key == '+') {
    LOGI("Simulating focus gain");
    lifecycle_handler_ptr->Resume();
  } else if (key == '-') {
    LOGI("Simulating focus loss");
    lifecycle_handler_ptr->Pause();
  }
}

void mouse(int button, int state, int x, int y) {
  if (state == GLUT_UP) {
    input_handler_ptr->OnMotionEvent(kMotionUp, time(0), x, y);
  } else if (state == GLUT_DOWN) {
    input_handler_ptr->OnMotionEvent(kMotionDown, time(0), x, y);
  }
}

void motion(int x, int y) {
  input_handler_ptr->OnMotionEvent(kMotionMove, time(0), x, y);
}

DART_EXPORT void emulator_main(int argc, char** argv, const char* script) {
  EmulatorGraphicsHandler graphics_handler(argc, argv);
  if (argc > 0) {
    int i = argc - 1;
    size_t len = strlen(argv[i]);
    if (len > 5 && strcmp(".dart", argv[i] + len - 5) == 0) {
      script = argv[i];
    }
  }
  VMGlue vm_glue(&graphics_handler, ".", "gl.dart", script, 1);
  InputHandler input_handler(&vm_glue);
  input_handler_ptr = &input_handler;
  SoundHandler sound_handler;
  Timer timer;
  Context app_context;
  app_context.graphics_handler = &graphics_handler;
  app_context.input_handler = &input_handler;
  app_context.sound_handler = &sound_handler;
  app_context.timer = &timer;
  app_context.vm_glue = &vm_glue;
  DartHost host(&app_context);
  lifecycle_handler_ptr = &host;
  glutReshapeFunc(reshape);
  glutDisplayFunc(display);
  glutKeyboardFunc(keyboard);
  glutMouseFunc(mouse);
  glutMotionFunc(motion);
  lifecycle_handler_ptr->OnStart();
  lifecycle_handler_ptr->Activate();
  lifecycle_handler_ptr->Resume();
  gettimeofday(&tvStart, NULL);
  glutTimerFunc(1, tick, 0);
  glutMainLoop();
}

