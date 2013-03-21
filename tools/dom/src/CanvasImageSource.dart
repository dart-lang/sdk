// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/**
 * An object that can be drawn to a [CanvasRenderingContext2D] object with
 * [CanvasRenderingContext2D.drawImage],
 * [CanvasRenderingContext2D.drawImageRect],
 * [CanvasRenderingContext2D.drawImageScaled], or
 * [CanvasRenderingContext2D.drawImageScaledFromSource].
 *
 * If the CanvasImageSource is an [ImageElement] then the element's image is
 * used. If the [ImageElement] is an animated image, then the poster frame is
 * used. If there is no poster frame, then the first frame of animation is used.
 *
 * If the CanvasImageSource is a [VideoElement] then the frame at the current
 * playback position is used as the image.
 *
 * If the CanvasImageSource is a [CanvasElement] then the element's bitmap is
 * used.
 *
 * ** Note: ** Currently, all versions of Internet Explorer do not support
 * drawing a VideoElement to a canvas. Also, you may experience problems drawing
 * a video to a canvas in Firefox if the source of the video is a data URL.
 *
 * See also:
 *
 *  * [CanvasImageSource](http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#image-sources-for-2d-rendering-contexts)
 * from the WHATWG.
 *  * [drawImage](http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#dom-context-2d-drawimage)
 * from the WHATWG.
 */
abstract class CanvasImageSource {}
