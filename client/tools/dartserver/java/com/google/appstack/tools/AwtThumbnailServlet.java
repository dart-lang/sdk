// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.appstack.tools;

import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URL;
import java.util.Iterator;
import java.util.Locale;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.plugins.jpeg.JPEGImageWriteParam;
import javax.imageio.stream.ImageOutputStream;

/**
 * This servlet takes images URLs and replies with a resized thumbnail of the
 * image. Unlike the "real" thumbnail servlet, this one doesn't use any
 * AppEngine libs, so can be run locally on top of Jetty.
 */
public class AwtThumbnailServlet extends ThumbnailServlet {
  private static Logger logger =
      Logger.getLogger(AwtThumbnailServlet.class.getName());

  @Override
  protected byte[] makeThumbnail(URL originalUrl, int width, int height) {
    // Read the original image.
    BufferedImage image;
    try {
      image = ImageIO.read(originalUrl);

      // Resize it.
      // TODO(rnystrom): This doesn't use the exact same cropping and resize
      // logic as the "real" AppEngine thumbnail server. Consider the GSE one a
      // cheap approximation.
      BufferedImage resized = new BufferedImage(width, height,
        BufferedImage.TYPE_INT_RGB);

      Graphics2D g = resized.createGraphics();

      g.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
        RenderingHints.VALUE_INTERPOLATION_BILINEAR);
      g.setRenderingHint(RenderingHints.KEY_RENDERING,
        RenderingHints.VALUE_RENDER_QUALITY);
      g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
        RenderingHints.VALUE_ANTIALIAS_ON);

      g.drawImage(image, 0, 0, width, height, null);
      g.dispose();

      return makeJpeg(resized);
    } catch (IOException e) {
      // TODO(rnystrom): Handle error better.
      logger.log(Level.SEVERE, "Got error generating thumbnail.", e);
      throw new RuntimeException(e);
    }
  }

  /**
   * Create a compressed JPEG from the given image and return its data.
   */
  private byte[] makeJpeg(BufferedImage image) {
    try {
      Iterator<ImageWriter> iterator = ImageIO.getImageWritersByFormatName("jpg");
      ImageWriter writer = iterator.next();

      ByteArrayOutputStream output = new ByteArrayOutputStream();
      ImageOutputStream imageOutput = ImageIO.createImageOutputStream(output);
      writer.setOutput(imageOutput);

      ImageWriteParam param = new JPEGImageWriteParam(Locale.getDefault());

      param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
      param.setCompressionQuality(0.75F);

      writer.write(null, new IIOImage(image, null, null), param);

      imageOutput.flush();
      writer.dispose();
      imageOutput.close();

      return output.toByteArray();
    } catch (IOException e) {
      // TODO(rnystrom): Handle error better.
      logger.log(Level.SEVERE, "Got error creating JPEG.", e);
      throw new RuntimeException(e);
    }
  }



}
