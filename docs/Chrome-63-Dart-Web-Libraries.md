> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

The Dart Web Libraries have not been updated since Chrome 50.  With this release these libraries have been rev’d to the Chrome 63 APIs (WebIDLs).  Below are the known differences between the Chrome 50 and Chrome 63 Dart Web libraries.  These are the changes that have affected Dart user’s code:

* Touch and TouchEvent change
    - _initTouchEvent removed see [Chrome Change](https://www.chromestatus.com/features/4923255479599104)
    - Example of [Migrating initTouchEvent to Map](https://developers.google.com/web/updates/2016/09/chrome-54-deprecations#use_of_inittouchevent_is_removed)
* TouchEvent constructor takes a map argument, strong mode catches these failures in our tests.
* Web_audio
    - AudioBufferSourceNode extends AudioScheduledSourceNode there are two start methods
    - AudioScheduledSourceNode.start can't be overloaded and will become operation void start2([num when]);
    - AudioBufferSourceNode.start([num when, num grainOffset, num grainDuration]) is void start([num when, num grainOffset, num grainDuration])
* Attributes of type double changed num see section "**Attributes Type Change double to num**" at the end of this document.
* onWheel event exposed
* Created for union of two kinds of canvas HTMLCanvasElement and OffscreenCanvas interface WebGLCanvas
* all other RenderingContext
    - readonly attribute WebGLCanvas canvas;
* interface WebGLRenderingContext
    - readonly attribute HTMLCanvasElement canvas;
* KeygenElement was removed in Chrome 57
* IDBFactory.webkitGetDatabaseNames() constructor removed in Chrome
* Depreciated FileError and DomError have been removed use DomException
    - error.code replaced with error.name  (e.g., see fileapi_directory_test.dart)
    - Additional because FileError is gone there is no easy way to determine which errors are File only errors.  However, these are:
    - NOT_FOUND_ERR
    - SECURITY_ERR
    - ABORT_ERR
    - NO_MODIFICATION_ALLOWED_ERR
    - INVALID_STATE_ERR
    - SYNTAX_ERR
    - INVALID_MODIFICATION_ERR
    - QUOTA_EXCEEDED_ERR
    - TYPE_MISMATCH_ERR
* registerElement and register maps to old style (Chrome 50)
* registerElement2 2nd parameter is a map {'prototype': xxx, 'extends': xxxx} not 2 separate arguments.
* List<Rectangle> getClientRects() is now DomRectList getClientRects()
* Rectangle getBoundingClientRect() is now DomRect getBoundingClientRect()
* postMessage(/*any*/ message, String targetOrigin, [List<MessagePort> transfer]) changed to void postMessage(/*any*/ message, String targetOrigin, [List<Object> transfer]) transfer can now be ArrayBuffer, MessagePort and ImageBitmap
* RTCPeerConnection.setLocalDescription and setRemoteDescription
    - takes a Map setLocalDescription(Map description) description is a map e.g.,  {'type': localSessionDescription, 'sdp': fakeLensSdp}
* nounce removed from HtmlScriptElement added to HtmlElement
    - https://codereview.chromium.org/2801243002
    - https://github.com/whatwg/html/issues/2369
* Event.deepPath() was removed Chrome 54
    - https://developer.mozilla.org/en-US/docs/Web/API/Event/deepPath
* Event.scoped replaced by Event.composed
    - https://developer.mozilla.org/en-US/docs/Web/API/Event/composed

***
Summary of API changes from Chrome 51 thru Chrome 63:
<br><br>
[https://developers.google.com/web/updates/tags/chrome51](https://developers.google.com/web/updates/tags/chrome51)
<br>
[https://developers.google.com/web/updates/tags/chrome52](https://developers.google.com/web/updates/tags/chrome52)
<br>
[https://developers.google.com/web/updates/tags/chrome53](https://developers.google.com/web/updates/tags/chrome53)
<br>
[https://developers.google.com/web/updates/tags/chrome54](https://developers.google.com/web/updates/tags/chrome54)
<br>
[https://developers.google.com/web/updates/tags/chrome55](https://developers.google.com/web/updates/tags/chrome55)
<br>
[https://developers.google.com/web/updates/tags/chrome56](https://developers.google.com/web/updates/tags/chrome56)
<br>
[https://developers.google.com/web/updates/tags/chrome57](https://developers.google.com/web/updates/tags/chrome57)
<br>
[https://developers.google.com/web/updates/tags/chrome58](https://developers.google.com/web/updates/tags/chrome58)
<br>
[https://developers.google.com/web/updates/tags/chrome59](https://developers.google.com/web/updates/tags/chrome59)
<br>
[https://developers.google.com/web/updates/tags/chrome60](https://developers.google.com/web/updates/tags/chrome60)
<br>
[https://developers.google.com/web/updates/tags/chrome61](https://developers.google.com/web/updates/tags/chrome61)
<br>
[https://developers.google.com/web/updates/tags/chrome62](https://developers.google.com/web/updates/tags/chrome62)
<br>
[https://developers.google.com/web/updates/tags/chrome63](https://developers.google.com/web/updates/tags/chrome63)
<br>

***
### Attributes Type Change double to num
* Accelerometer
    - x, y, z
* AmbientLightSensor
    - illuminance
* AnimationEffectTimingReadOnly
    - delay, endDelay, iterationStart, iterations
* AnimationEvent
    - elapsedTime
* AnimationPlaybackEvent
    - currentTime, timelineTime
* AnimationTimeline
    - currentTime
* BatteryManager
    - chargingTime, dischargingTime, level
* BlobEvent
    - timecode
* BudgetState
    - budgetAt
* Coordinates
    - accuracy, altitude, altitudeAccuracy, heading, latitude, longitude, speed
* CSSImageValue
    - intrinsicHeight,intrinsicRatio, intrinsicWidth
* DeviceAcceleration
    - x, y, z
* DeviceOrientationEvent
    - alpha, beta, gamma
* DeviceRotationRate
    - alpha, beta, gamma
* Event
    - timeStamp
* GamepadButton
    - value
* Gyroscope
    - x, y, z
* IntersectionObserverEntry
    - intersectionRatio, time
* Magnetometer
    - x, y, z
* HTMLMediaElement
    - duration
* MediaKeySession
    - expiration
* MediaSettingsRange
    - max. min, step
* MouseEvent
    - clientX, clientY, pageX, pageY, screenX, screenY
* Navigator
    - deviceMemory
* NetworkInformation
    - downlink, downlinkMax
* PaintSize
    - height, width
* PaintWorkletGlobalScope
    - devicePixelRatio
* Performance
    - timeOrigin
* PerformanceEntry
    - duration, startTime
* PerformanceNavigationTiming
    - domComplete, domContentLoadedEventEnd, domContentLoadedEventStart, domInteractive, loadEventEnd, loadEventStart, redirectCount, unloadEventEnd, unloadEventStart
* PerformanceResourceTiming
    - connectEnd, connectStart, domainLookupEnd, domainLookupStart, encodedBodySize, fetchStart, redirectStart, requestStart, responseEnd, responseStart, secureConnectionStart, workerStart
* PointerEvent
    - height, pressure, tangentialPressure, width
* HTMLProgressElement
    - position
* RTCRtpContributingSource
    - timestamp
* ScrollState
    - deltaGranularity, deltaX, deltaY, velocityX, velocityY
* Sensor
    - timestamp
* SpeechRecognitionAlternative
    - confidence
* SpeechSynthesisEvent
    - elapsedTime
* TextMetrics
    - actualBoundingBoxAscent, actualBoundingBoxDescent, actualBoundingBoxLeft, actualBoundingBoxRight, alphabeticBaseline, emHeightAscent, emHeightDescent, fontBoundingBoxAscent, fontBoundingBoxDescent, hangingBaseline, ideographicBaseline, width
* Touch
    - clientX, clientY, force, pageX, pageY, radiusX, radiusY, rotationAngle, screenX, screenY
* TransitionEvent
    - elapsedTime
* VRFrameOfReference
    - emulatedHeight
* VRStageBoundsPoint
    - x, z
* VRStageParameters
    - sizeX, sizeZ
* VideoPlaybackQuality
    - creationTime
* VisualViewport
    - height, offsetLeft, offsetTop, pageLeft, pageTop, sca, width
* WheelEvent
    - deltaX, deltaY, deltaZ
* Window
    - devicePixelRatio, pageXOffset, pageYOffset
* WorkerPerformance
    - timeOrigin
* XPathResult
    - numberValue
