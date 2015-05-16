library dromaeo;
import 'dart:async';
import 'dart:html';
import "dart:convert";
import 'dart:math' as Math;
part 'Common.dart';
part 'RunnerSuite.dart';

void main() {
  final int num = 400;
  var random = new Math.Random();

  String str = 'null';
  // Very ugly way to build up the string, but let's mimic JS version as much as
  // possible.
  for (int i = 0; i < 1024; i++) {
    str += new String.fromCharCode(((25 * random.nextDouble()) + 97).toInt());
  }

  List<Node> elems = <Node>[];

  // Try to force real results.
  var ret;

  final htmlstr = document.body.innerHtml;

  new Suite(window, 'dom-modify')
    .test('createElement', () {
      for (int i = 0; i < num; i++) {
        ret = new Element.tag('div');
        ret = new Element.tag('span');
        ret = new Element.tag('table');
        ret = new Element.tag('tr');
        ret = new Element.tag('select');
      }
    })
    .test('createTextNode', () {
      for (int i = 0; i < num; i++) {
        ret = new Text(str);
        ret = new Text('${str}2');
        ret = new Text('${str}3');
        ret = new Text('${str}4');
        ret = new Text('${str}5');
      }
    })
    .test('innerHtml', () {
      document.body.innerHtml = htmlstr;
    })
    .prep(() {
      elems = new List<Node>();
      final telems = document.body.nodes;
      for (int i = 0; i < telems.length; i++) {
        elems.add(telems[i]);
      }
    })
    .test('cloneNode', () {
      for (int i = 0; i < elems.length; i++) {
        ret = elems[i].clone(false);
        ret = elems[i].clone(true);
        ret = elems[i].clone(true);
        }
    })
    .test('appendChild', () {
      for (int i = 0; i < elems.length; i++)
        document.body.append(elems[i]);
    })
    .test('insertBefore', () {
      for (int i = 0; i < elems.length; i++)
        document.body.insertBefore(elems[i], document.body.firstChild);
    })
    .end();
}
