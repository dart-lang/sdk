// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): html5lib might be a better home for this.
// But at the moment we only need it here.

library html5_utils;

/**
 * HTML attributes that expect a URL value.
 * <http://dev.w3.org/html5/spec/section-index.html#attributes-1>
 *
 * Every one of these attributes is a URL in every context where it is used in
 * the DOM. The comments show every DOM element where an attribute can be used.
 */
const urlAttributes = const [
  'action',     // in form
  'background', // in body
  'cite',       // in blockquote, del, ins, q
  'data',       // in object
  'formaction', // in button, input
  'href',       // in a, area, link, base, command
  'icon',       // in command
  'manifest',   // in html
  'poster',     // in video
  'src',        // in audio, embed, iframe, img, input, script, source, track,
                //    video
];
