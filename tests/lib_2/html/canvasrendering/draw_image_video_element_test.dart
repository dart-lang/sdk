// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library canvas_rendering_context_2d_test;

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'canvas_rendering_util.dart';
import 'package:async_helper/async_helper.dart';

// These videos and base64 strings are the same video, representing 2
// frames of 8x8 red pixels.
// The videos were created with:
//   convert -size 8x8 xc:red blank1.jpg
//   convert -size 8x8 xc:red blank2.jpg
//   avconv -f image2  -i "blank%d.jpg" -c:v libx264 small.mp4
//   avconv -i small.mp4 small.webm
//   python -m base64 -e small.mp4
//   python -m base64 -e small.webm
var mp4VideoUrl = '/root_dart/tests/lib_2/html/small.mp4';
var webmVideoUrl = '/root_dart/tests/lib_2/html/small.webm';
var mp4VideoDataUrl =
    'data:video/mp4;base64,AAAAIGZ0eXBpc29tAAACAGlzb21pc28yYXZjMW1wNDEAAA'
    'AIZnJlZQAAAsdtZGF0AAACmwYF//+X3EXpvebZSLeWLNgg2SPu73gyNjQgLSBjb3JlID'
    'EyMCByMjE1MSBhM2Y0NDA3IC0gSC4yNjQvTVBFRy00IEFWQyBjb2RlYyAtIENvcHlsZW'
    'Z0IDIwMDMtMjAxMSAtIGh0dHA6Ly93d3cudmlkZW9sYW4ub3JnL3gyNjQuaHRtbCAtIG'
    '9wdGlvbnM6IGNhYmFjPTEgcmVmPTMgZGVibG9jaz0xOjA6MCBhbmFseXNlPTB4MToweD'
    'ExMSBtZT1oZXggc3VibWU9NyBwc3k9MSBwc3lfcmQ9MS4wMDowLjAwIG1peGVkX3JlZj'
    '0wIG1lX3JhbmdlPTE2IGNocm9tYV9tZT0xIHRyZWxsaXM9MSA4eDhkY3Q9MCBjcW09MC'
    'BkZWFkem9uZT0yMSwxMSBmYXN0X3Bza2lwPTEgY2hyb21hX3FwX29mZnNldD0tMiB0aH'
    'JlYWRzPTE4IHNsaWNlZF90aHJlYWRzPTAgbnI9MCBkZWNpbWF0ZT0xIGludGVybGFjZW'
    'Q9MCBibHVyYXlfY29tcGF0PTAgY29uc3RyYWluZWRfaW50cmE9MCBiZnJhbWVzPTMgYl'
    '9weXJhbWlkPTAgYl9hZGFwdD0xIGJfYmlhcz0wIGRpcmVjdD0xIHdlaWdodGI9MCBvcG'
    'VuX2dvcD0xIHdlaWdodHA9MiBrZXlpbnQ9MjUwIGtleWludF9taW49MjUgc2NlbmVjdX'
    'Q9NDAgaW50cmFfcmVmcmVzaD0wIHJjX2xvb2thaGVhZD00MCByYz1jcmYgbWJ0cmVlPT'
    'EgY3JmPTUxLjAgcWNvbXA9MC42MCBxcG1pbj0wIHFwbWF4PTY5IHFwc3RlcD00IGlwX3'
    'JhdGlvPTEuMjUgYXE9MToxLjAwAIAAAAARZYiEB//3aoK5/tP9+8yeuIEAAAAHQZoi2P'
    '/wgAAAAzxtb292AAAAbG12aGQAAAAAAAAAAAAAAAAAAAPoAAAAUAABAAABAAAAAAAAAA'
    'AAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAACAAAAGGlvZHMAAAAAEICAgAcAT/////7/AAACUHRyYWsAAA'
    'BcdGtoZAAAAA8AAAAAAAAAAAAAAAEAAAAAAAAAUAAAAAAAAAAAAAAAAAAAAAAAAQAAAA'
    'AAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAEAAAAAACAAAAAgAAAAAACRlZHRzAAAAHG'
    'Vsc3QAAAAAAAAAAQAAAFAAAAABAAEAAAAAAchtZGlhAAAAIG1kaGQAAAAAAAAAAAAAAA'
    'AAAAAZAAAAAlXEAAAAAAAtaGRscgAAAAAAAAAAdmlkZQAAAAAAAAAAAAAAAFZpZGVvSG'
    'FuZGxlcgAAAAFzbWluZgAAABR2bWhkAAAAAQAAAAAAAAAAAAAAJGRpbmYAAAAcZHJlZg'
    'AAAAAAAAABAAAADHVybCAAAAABAAABM3N0YmwAAACXc3RzZAAAAAAAAAABAAAAh2F2Yz'
    'EAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAACAAIAEgAAABIAAAAAAAAAAEAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAY//8AAAAxYXZjQwFNQAr/4QAYZ01ACuiPyy'
    '4C2QAAAwABAAADADIPEiUSAQAGaOvAZSyAAAAAGHN0dHMAAAAAAAAAAQAAAAIAAAABAA'
    'AAFHN0c3MAAAAAAAAAAQAAAAEAAAAYY3R0cwAAAAAAAAABAAAAAgAAAAEAAAAcc3RzYw'
    'AAAAAAAAABAAAAAQAAAAEAAAABAAAAHHN0c3oAAAAAAAAAAAAAAAIAAAK0AAAACwAAAB'
    'hzdGNvAAAAAAAAAAIAAAAwAAAC5AAAAGB1ZHRhAAAAWG1ldGEAAAAAAAAAIWhkbHIAAA'
    'AAAAAAAG1kaXJhcHBsAAAAAAAAAAAAAAAAK2lsc3QAAAAjqXRvbwAAABtkYXRhAAAAAQ'
    'AAAABMYXZmNTMuMjEuMQ==';
var webmVideoDataUrl =
    'data:video/webm;base64,GkXfowEAAAAAAAAfQoaBAUL3gQFC8oEEQvOBCEKChHdlY'
    'm1Ch4ECQoWBAhhTgGcBAAAAAAAB/hFNm3RALE27i1OrhBVJqWZTrIHfTbuMU6uEFlSua'
    '1OsggEsTbuMU6uEHFO7a1OsggHk7AEAAAAAAACkAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVSalmAQAAAAAAA'
    'EEq17GDD0JATYCLTGF2ZjUzLjIxLjFXQYtMYXZmNTMuMjEuMXOkkJatuHwTJ7cvFLSzB'
    'Smxbp5EiYhAVAAAAAAAABZUrmsBAAAAAAAAR64BAAAAAAAAPteBAXPFgQGcgQAitZyDd'
    'W5khoVWX1ZQOIOBASPjg4QCYloA4AEAAAAAAAASsIEIuoEIVLCBCFS6gQhUsoEDH0O2d'
    'QEAAAAAAABZ54EAo72BAACA8AIAnQEqCAAIAABHCIWFiIWEiAICAnWqA/gD+gINTRgA/'
    'v0hRf/kb+PnRv/I4//8WE8DijI//FRAo5WBACgAsQEAARAQABgAGFgv9AAIAAAcU7trA'
    'QAAAAAAAA67jLOBALeH94EB8YIBfw==';

Future testWithThreeParams() async {
  setupFunc();

  video.onError.listen((_) {
    throw ('URL failed to load.');
  });
  if (video.canPlayType('video/webm; codecs="vp8.0, vorbis"', '') != '') {
    video.src = webmVideoUrl;
  } else if (video.canPlayType(
          'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null) !=
      '') {
    video.src = mp4VideoUrl;
  } else {
    window.console.log('Video is not supported on this system.');
  }

  // Without user interaction, playing the video requires autoplay to be enabled
  // and autoplay can only be enabled if muted. We loop the video so there is
  // always an active frame that can be drawn.
  video.loop = true;
  video.muted = true;
  video.autoplay = true;
  await video.play();
  context.drawImage(video, 50, 50);

  expectPixelFilled(50, 50);
  expectPixelFilled(54, 54);
  expectPixelFilled(57, 57);
  expectPixelUnfilled(58, 58);
  expectPixelUnfilled(0, 0);
  expectPixelUnfilled(70, 70);
  tearDownFunc();
}

Future testWithFiveParams() async {
  setupFunc();

  video.onError.listen((_) {
    throw ('URL failed to load.');
  });

  if (video.canPlayType('video/webm; codecs="vp8.0, vorbis"', '') != '') {
    video.src = webmVideoUrl;
  } else if (video.canPlayType(
          'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null) !=
      '') {
    video.src = mp4VideoUrl;
  } else {
    // TODO(amouravski): Better fallback?
    window.console.log('Video is not supported on this system.');
  }

  video.loop = true;
  video.muted = true;
  video.autoplay = true;
  await video.play();
  context.drawImageToRect(video, new Rectangle(50, 50, 20, 20));

  expectPixelFilled(50, 50);
  expectPixelFilled(55, 55);
  expectPixelFilled(59, 59);
  expectPixelFilled(60, 60);
  expectPixelFilled(69, 69);
  expectPixelUnfilled(70, 70);
  expectPixelUnfilled(0, 0);
  expectPixelUnfilled(80, 80);
  tearDownFunc();
}

Future testWithNineParams() async {
  setupFunc();

  video.onError.listen((_) {
    throw ('URL failed to load.');
  });

  if (video.canPlayType('video/webm; codecs="vp8.0, vorbis"', '') != '') {
    video.src = webmVideoUrl;
  } else if (video.canPlayType(
          'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null) !=
      '') {
    video.src = mp4VideoUrl;
  } else {
    // TODO(amouravski): Better fallback?
    window.console.log('Video is not supported on this system.');
  }

  video.loop = true;
  video.muted = true;
  video.autoplay = true;
  await video.play();
  context.drawImageToRect(video, new Rectangle(50, 50, 20, 20),
      sourceRect: new Rectangle(2, 2, 6, 6));

  expectPixelFilled(50, 50);
  expectPixelFilled(55, 55);
  expectPixelFilled(59, 59);
  expectPixelFilled(60, 60);
  expectPixelFilled(69, 69);
  expectPixelUnfilled(70, 70);
  expectPixelUnfilled(0, 0);
  expectPixelUnfilled(80, 80);
  tearDownFunc();
}

Future testDataUrlWithNineParams() async {
  setupFunc();

  video = new VideoElement();
  canvas = new CanvasElement();

  video.onError.listen((_) {
    throw ('URL failed to load.');
  });

  if (video.canPlayType('video/webm; codecs="vp8.0, vorbis"', '') != '') {
    video.src = webmVideoDataUrl;
  } else if (video.canPlayType(
          'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null) !=
      '') {
    video.src = mp4VideoDataUrl;
  } else {
    // TODO(amouravski): Better fallback?
    window.console.log('Video is not supported on this system.');
  }

  video.loop = true;
  video.muted = true;
  video.autoplay = true;
  await video.play();
  context.drawImageToRect(video, new Rectangle(50, 50, 20, 20),
      sourceRect: new Rectangle(2, 2, 6, 6));

  expectPixelFilled(50, 50);
  expectPixelFilled(55, 55);
  expectPixelFilled(59, 59);
  expectPixelFilled(60, 60);
  expectPixelFilled(69, 69);
  expectPixelUnfilled(70, 70);
  expectPixelUnfilled(0, 0);
  expectPixelUnfilled(80, 80);
  tearDownFunc();
}

main() {
  asyncTest(() async {
    await testWithThreeParams();
    await testWithFiveParams();
    await testWithNineParams();
    await testDataUrlWithNineParams();
  });
}
