// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.appstack.tools;

import java.net.URL;
import java.net.URLDecoder;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

// TODO(rnystrom): Get rid of one of the subclasses of this and just have a
// single way to make thumbnails once we've got our server stuff figured out.
/**
 * This servlet takes images URLs and replies with a resized thumbnail of the
 * image. Relies on the subclass to provide the actual image resizing.
 */
public abstract class ThumbnailServlet extends HttpServlet {
  // TODO(rnystrom): Allow passing this in as a URL parameter.
  private static final int THUMBNAIL_SIZE = 156;

  private static Logger logger =
      Logger.getLogger(ThumbnailServlet.class.getName());

  @Override
  public void service(HttpServletRequest request, HttpServletResponse response) {
    String imageParam = request.getParameter("i");
    if (imageParam == null) {
      // TODO(rnystrom): Handle errors better.
      throw new RuntimeException("Must have an 'i' parameter.");
    }

    try {
      URL originalUrl = new URL(URLDecoder.decode(imageParam, "UTF-8"));

      byte[] data = makeThumbnail(originalUrl, THUMBNAIL_SIZE, THUMBNAIL_SIZE);

      // Serve up the thumbnail.
      response.setContentType("image/jpeg");
      response.getOutputStream().write(data);
    } catch (Exception e) {
      // TODO(rnystrom): Handle errors better.
      logger.log(Level.SEVERE, "Got error serving thumbnail.", e);
    }
  }

  /**
   * Override this to read the original image at that URL, scale it to a
   * thumbnail and return the raw data for a thumbnail PNG.
   *
   * @param originalUrl  URL of the source image to create a thumbnail for.
   * @return             Raw data for a PNG-formatted thumbnail image.
   */
  protected abstract byte[] makeThumbnail(URL originalUrl, int width, int height);
}
