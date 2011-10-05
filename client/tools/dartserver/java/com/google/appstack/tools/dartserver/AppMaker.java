// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.appstack.tools.dartserver;

import com.google.dart.compiler.DartCompilationError;

import java.io.File;
import java.io.IOException;
import java.util.logging.Logger;


/**
 * Creates the javascript that we need to send to the browser to
 * run a dart app.
 */
public class AppMaker {

  private static final Logger logger = Logger.getLogger(AppMaker.class.getName());

  /** The application's .app file. */
  private final File appFile;

  /**
   * Parses the uri and figure out the app name.
   *
   * @sourceDir - directory (relative to google3) containing dart source
   * @param uri - uri requested by browser
   * @return null if the uri isn't a dart app
   */
  public static AppMaker create(String sourceDir, String uri) {
    String appName;
    String path = sourceDir + uri;

    path = path.replaceFirst("\\.js$", ".app");
    
    if (!path.endsWith(".app")) {
      return null;
    }
    // Check if the .app file exists.
    File appFile = new File(path);
    if (!appFile.exists()) {
      logger.warning(String.format("cannot find app file '%s'", appFile.getAbsolutePath()));
      return null;
    }

    logger.info(String.format("found app file '%s'", appFile.getAbsolutePath()));
    return new AppMaker(appFile);
  }

  /**
   * private constructor (use {@code create} factory method above}
   */
  private AppMaker(File appFile) {
    this.appFile = appFile;
  }

  /**
   * Creates the JavaScript for this app by running the dart compiler.
   */
  public String getJavascript() {
    DartApp.Result result = DartApp.build(appFile);
    if (result.didBuild()) {
      return result.getApp().getJavaScript();
    } else {
      return ErrorFormatter.reportErrorsAsJs(result);
    }
  } 
}
