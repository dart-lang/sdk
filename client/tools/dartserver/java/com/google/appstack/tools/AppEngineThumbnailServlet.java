// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.appstack.tools;

import com.google.appengine.api.images.CompositeTransform;
import com.google.appengine.api.images.Image;
import com.google.appengine.api.images.ImagesService;
import com.google.appengine.api.images.ImagesServiceFactory;
import com.google.appengine.api.images.OutputSettings;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;

/**
 * This servlet takes images URLs and replies with a resized thumbnail of the
 * image. This servlet uses AppEngine libraries and is only used when
 * dartserver is run through the AppEngine dev server or hosted.
 */
public class AppEngineThumbnailServlet extends ThumbnailServlet {
  @Override
  protected byte[] makeThumbnail(URL originalUrl, int width, int height) {
    // Read the original image.
    Image original = ImagesServiceFactory.makeImage(readData(originalUrl));

    double aspect = (double) original.getWidth() / original.getHeight();
    double desiredAspect = (double) width / height;

    CompositeTransform transform = ImagesServiceFactory.makeCompositeTransform();

    // Adjust the image to fit the thumbnail's aspect ratio.
    if (aspect > desiredAspect) {
      // Too wide, so crop on the sides.

      // Width of original image cropped to fit thumbnail.
      double croppedWidth = (double) original.getHeight() * width / height;

      // Amount to crop on each side, in normal coords.
      double normalCrop = (original.getWidth() - croppedWidth) /
          original.getWidth() / 2.0f;

      transform.concatenate(ImagesServiceFactory.makeCrop(
        normalCrop, 0.0f, 1.0f - normalCrop, 1.0f));
    } else if (aspect < desiredAspect) {
      // Too tall, so crop out the bottom.

      // Height of original image cropped to fit thumbnail.
      double croppedHeight = (double) original.getWidth() * height / width;
      double normalHeight = croppedHeight / original.getHeight();

      transform.concatenate(ImagesServiceFactory.makeCrop(
          0.0f, 0.0f, 1.0f, normalHeight));
    }

    // Now scale the correctly-cropped image.
    transform.concatenate(ImagesServiceFactory.makeResize(width, height));

    // Resize it.
    ImagesService images = ImagesServiceFactory.getImagesService();

    OutputSettings settings = new OutputSettings(
        ImagesService.OutputEncoding.JPEG);
    settings.setQuality(75);
    Image thumbnail = images.applyTransform(transform, original, settings);

    return thumbnail.getImageData();
  }

  private byte[] readData(URL url) {
    final int bufferSize = 16384;

    ByteArrayOutputStream buffer = new ByteArrayOutputStream();

    int bytesRead;
    byte[] data = new byte[bufferSize];

    try {
      InputStream stream = url.openStream();
      while ((bytesRead = stream.read(data, 0, data.length)) != -1) {
        buffer.write(data, 0, bytesRead);
      }

      buffer.flush();
      return buffer.toByteArray();
    } catch (IOException e) {
      // TODO(rnystrom): Handle error!
      throw new RuntimeException();
    }
  }
}
