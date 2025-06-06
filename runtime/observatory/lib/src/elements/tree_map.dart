// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as Math;

import 'package:web/web.dart';

import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/utils.dart';

abstract class TreeMap<T> {
  int getArea(T node);
  String getBackground(T node);
  String getLabel(T node);
  String getTooltip(T node) => getLabel(node);
  T? getParent(T node);
  Iterable<T> getChildren(T node);
  void onSelect(T node);
  void onDetails(T node);

  void showIn(T node, HTMLDivElement content) {
    final w = content.offsetWidth.toDouble();
    final h = content.offsetHeight.toDouble();
    final topTile = _createTreemapTile(node, w, h, 0, content);
    topTile.style.width = "${w}px";
    topTile.style.height = "${h}px";
    topTile.style.border = "none";
    content.setChildren([topTile]);
  }

  HTMLElement _createTreemapTile(
      T node, double width, double height, int depth, HTMLDivElement content) {
    final div = new HTMLDivElement();
    div.className = "treemapTile";
    div.style.background = getBackground(node);
    div.onDoubleClick.listen((event) {
      event.stopPropagation();
      if (depth == 0) {
        var p = getParent(node);
        onSelect(p ?? node); // Zoom out.
      } else {
        onSelect(node); // Zoom in.
      }
    });
    div.onContextMenu.listen((event) {
      event.stopPropagation();
      onDetails(node);
    });

    double left = 0.0;
    double top = 0.0;

    const kPadding = 5;
    const kBorder = 1;
    left += kPadding - kBorder;
    top += kPadding - kBorder;
    width -= 2 * kPadding;
    height -= 2 * kPadding;

    div.title = getTooltip(node);

    if (width < 10 || height < 10) {
      // Too small: don't render label or children.
      return div;
    }

    div.append(new HTMLSpanElement()..textContent = getLabel(node));
    const kLabelHeight = 9.0;
    top += kLabelHeight;
    height -= kLabelHeight;

    if (depth > 2) {
      // Too deep: don't render children.
      return div;
    }
    if (width < 4 || height < 4) {
      // Too small: don't render children.
      return div;
    }

    final children = <T>[];
    for (T c in getChildren(node)) {
      // Size 0 children seem to confuse the layout algorithm (accumulating
      // rounding errors?).
      if (getArea(c) > 0) {
        children.add(c);
      }
    }
    children.sort((a, b) => getArea(b) - getArea(a));

    final double scale = width * height / getArea(node);

    // Bruls M., Huizing K., van Wijk J.J. (2000) Squarified Treemaps. In: de
    // Leeuw W.C., van Liere R. (eds) Data Visualization 2000. Eurographics.
    // Springer, Vienna.
    for (int rowStart = 0; // Index of first child in the next row.
        rowStart < children.length;) {
      // Prefer wider rectangles, the better to fit text labels.
      const double GOLDEN_RATIO = 1.61803398875;
      final bool verticalSplit = (width / height) > GOLDEN_RATIO;

      double space;
      if (verticalSplit) {
        space = height;
      } else {
        space = width;
      }

      double rowMin = getArea(children[rowStart]) * scale;
      double rowMax = rowMin;
      double rowSum = 0.0;
      double lastRatio = 0.0;

      int rowEnd; // One after index of last child in the next row.
      for (rowEnd = rowStart; rowEnd < children.length; rowEnd++) {
        double size = getArea(children[rowEnd]) * scale;
        if (size < rowMin) rowMin = size;
        if (size > rowMax) rowMax = size;
        rowSum += size;

        double ratio = Math.max((space * space * rowMax) / (rowSum * rowSum),
            (rowSum * rowSum) / (space * space * rowMin));
        if ((lastRatio != 0) && (ratio > lastRatio)) {
          // Adding the next child makes the aspect ratios worse: remove it and
          // add the row.
          rowSum -= size;
          break;
        }
        lastRatio = ratio;
      }

      double rowLeft = left;
      double rowTop = top;
      double rowSpace = rowSum / space;

      for (int i = rowStart; i < rowEnd; i++) {
        T child = children[i];
        double size = getArea(child) * scale;

        double childWidth;
        double childHeight;
        if (verticalSplit) {
          childWidth = rowSpace;
          childHeight = size / childWidth;
        } else {
          childHeight = rowSpace;
          childWidth = size / childHeight;
        }

        HTMLElement childDiv = _createTreemapTile(
            child, childWidth, childHeight, depth + 1, content);
        childDiv.style.left = "${rowLeft}px";
        childDiv.style.top = "${rowTop}px";
        // Oversize the final div by kBorder to make the borders overlap.
        childDiv.style.width = "${childWidth + kBorder}px";
        childDiv.style.height = "${childHeight + kBorder}px";
        div.append(childDiv);

        if (verticalSplit)
          rowTop += childHeight;
        else
          rowLeft += childWidth;
      }

      if (verticalSplit) {
        left += rowSpace;
        width -= rowSpace;
      } else {
        top += rowSpace;
        height -= rowSpace;
      }

      rowStart = rowEnd;
    }

    return div;
  }
}

abstract class NormalTreeMap<T> extends TreeMap<T> {
  int getSize(T node);
  String getName(T node);
  String getType(T node);

  int getArea(T node) => getSize(node);
  String getLabel(T node) {
    String name = getName(node);
    String size = Utils.formatSize(getSize(node));
    return "$name [$size]";
  }

  String getBackground(T node) {
    int hue = getType(node).hashCode % 360;
    return "hsl($hue,60%,60%)";
  }
}

abstract class DiffTreeMap<T> extends TreeMap<T> {
  int getSizeA(T node);
  int getSizeB(T node);

  // We need to sum gains and losses separately because they both contribute
  // area to the tree map tiles, i.e., losses don't have negative area in the
  // visualization. For this reason, common is not necessarily
  // max(sizeA,sizeB)-min(sizeA,sizeB), gain is not necessarily
  // abs(sizeB-sizeA), etc.
  int getGain(T node);
  int getLoss(T node);
  int getCommon(T node);

  String getName(T node);
  String getType(T node);

  int getArea(T node) => getCommon(node) + getGain(node) + getLoss(node);
  String getLabel(T node) {
    var name = getName(node);
    var sizeA = Utils.formatSize(getSizeA(node));
    var sizeB = Utils.formatSize(getSizeB(node));
    return "$name [$sizeA → $sizeB]";
  }

  String getBackground(T node) {
    int l = getLoss(node);
    int c = getCommon(node);
    int g = getGain(node);
    int a = l + c + g;
    if (a == 0) {
      return "white";
    }
    // Stripes of green, white and red whose areas are poritional to loss, common and gain.
    String stop1 = (l / a * 100).toString();
    String stop2 = ((l + c) / a * 100).toString();
    return "linear-gradient(to right, #66FF99 $stop1%, white $stop1% $stop2%, #FF6680 $stop2%)";
  }
}
