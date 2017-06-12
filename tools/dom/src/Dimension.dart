part of html;

/**
 * Class representing a
 * [length measurement](https://developer.mozilla.org/en-US/docs/Web/CSS/length)
 * in CSS.
 */
@Experimental()
class Dimension {
  num _value;
  String _unit;

  /** Set this CSS Dimension to a percentage `value`. */
  Dimension.percent(this._value) : _unit = '%';

  /** Set this CSS Dimension to a pixel `value`. */
  Dimension.px(this._value) : _unit = 'px';

  /** Set this CSS Dimension to a pica `value`. */
  Dimension.pc(this._value) : _unit = 'pc';

  /** Set this CSS Dimension to a point `value`. */
  Dimension.pt(this._value) : _unit = 'pt';

  /** Set this CSS Dimension to an inch `value`. */
  Dimension.inch(this._value) : _unit = 'in';

  /** Set this CSS Dimension to a centimeter `value`. */
  Dimension.cm(this._value) : _unit = 'cm';

  /** Set this CSS Dimension to a millimeter `value`. */
  Dimension.mm(this._value) : _unit = 'mm';

  /**
   * Set this CSS Dimension to the specified number of ems.
   *
   * 1em is equal to the current font size. (So 2ems is equal to double the font
   * size). This is useful for producing website layouts that scale nicely with
   * the user's desired font size.
   */
  Dimension.em(this._value) : _unit = 'em';

  /**
   * Set this CSS Dimension to the specified number of x-heights.
   *
   * One ex is equal to the x-height of a font's baseline to its mean line,
   * generally the height of the letter "x" in the font, which is usually about
   * half the font-size.
   */
  Dimension.ex(this._value) : _unit = 'ex';

  /**
   * Construct a Dimension object from the valid, simple CSS string `cssValue`
   * that represents a distance measurement.
   *
   * This constructor is intended as a convenience method for working with
   * simplistic CSS length measurements. Non-numeric values such as `auto` or
   * `inherit` or invalid CSS will cause this constructor to throw a
   * FormatError.
   */
  Dimension.css(String cssValue) {
    if (cssValue == '') cssValue = '0px';
    if (cssValue.endsWith('%')) {
      _unit = '%';
    } else {
      _unit = cssValue.substring(cssValue.length - 2);
    }
    if (cssValue.contains('.')) {
      _value =
          double.parse(cssValue.substring(0, cssValue.length - _unit.length));
    } else {
      _value = int.parse(cssValue.substring(0, cssValue.length - _unit.length));
    }
  }

  /** Print out the CSS String representation of this value. */
  String toString() {
    return '${_value}${_unit}';
  }

  /** Return a unitless, numerical value of this CSS value. */
  num get value => this._value;
}
