// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/**
 * An object that can be drawn to a 2D canvas rendering context.
 *
 * The image drawn to the canvas depends on the type of this object:
 *
 * * If this object is an [ImageElement], then this element's image is
 * drawn to the canvas. If this element is an animated image, then this
 * element's poster frame is drawn. If this element has no poster frame, then
 * the first frame of animation is drawn.
 *
 * * If this object is a [VideoElement], then the frame at this element's current
 * playback position is drawn to the canvas.
 *
 * * If this object is a [CanvasElement], then this element's bitmap is drawn to
 * the canvas.
 *
 * **Note:** Currently all versions of Internet Explorer do not support
 * drawing a video element to a canvas. You may also encounter problems drawing
 * a video to a canvas in Firefox if the source of the video is a data URL.
 *
 * ## See also
 *
 * * [CanvasRenderingContext2D.drawImage]
 * * [CanvasRenderingContext2D.drawImageToRect]
 * * [CanvasRenderingContext2D.drawImageScaled]
 * * [CanvasRenderingContext2D.drawImageScaledFromSource]
 *
 * ## Other resources
 *
 * * [Image sources for 2D rendering
 *   contexts](https://html.spec.whatwg.org/multipage/scripting.html#image-sources-for-2d-rendering-contexts)
 *   from WHATWG.
 * * [Drawing images](https://html.spec.whatwg.org/multipage/scripting.html#dom-context-2d-drawimage)
 *   from WHATWG.
 */
abstract class CanvasImageSource {}
