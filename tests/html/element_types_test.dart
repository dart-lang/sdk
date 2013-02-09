// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library element_types;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported_content', () {
    test('supported', () {
      expect(ContentElement.supported, true);
    });
  });

  group('supported_datalist', () {
    test('supported', () {
      expect(DataListElement.supported, true);
    });
  });

  group('supported_details', () {
    test('supported', () {
      expect(DetailsElement.supported, true);
    });
  });

  group('supported_embed', () {
    test('supported', () {
      expect(EmbedElement.supported, true);
    });
  });

  group('supported_keygen', () {
    test('supported', () {
      expect(KeygenElement.supported, true);
    });
  });

  group('supported_meter', () {
    test('supported', () {
      expect(MeterElement.supported, true);
    });
  });

  group('supported_object', () {
    test('supported', () {
      expect(ObjectElement.supported, true);
    });
  });

  group('supported_output', () {
    test('supported', () {
      expect(OutputElement.supported, true);
    });
  });

  group('supported_progress', () {
    test('supported', () {
      expect(ProgressElement.supported, true);
    });
  });

  group('supported_shadow', () {
    test('supported', () {
      expect(ShadowElement.supported, true);
    });
  });

  group('supported_track', () {
    test('supported', () {
      expect(TrackElement.supported, true);
    });
  });

  group('constructors', () {
    test('a', () {
      expect((new AnchorElement()) is AnchorElement, true);
    });
    test('area', () {
      expect((new AreaElement()) is AreaElement, true);
    });
    test('audio', () {
      expect((new AudioElement()) is AudioElement, true);
    });
    test('body', () {
      expect((new BodyElement()) is BodyElement, true);
    });
    test('br', () {
      expect((new BRElement()) is BRElement, true);
    });
    test('base', () {
      expect((new BaseElement()) is BaseElement, true);
    });
    test('button', () {
      expect((new ButtonElement()) is ButtonElement, true);
    });
    test('canvas', () {
      expect((new CanvasElement()) is CanvasElement, true);
    });
    test('caption', () {
      expect((new TableCaptionElement()) is TableCaptionElement, true);
    });
    test('content', () {
      expect((new ContentElement()) is ContentElement,
          ContentElement.supported);
    });
    test('details', () {
      expect((new DetailsElement()) is DetailsElement,
          DetailsElement.supported);
    });
    test('dl', () {
      expect((new DListElement()) is DListElement, true);
    });
    test('datalist', () {
      expect((new DataListElement()) is DataListElement,
          DataListElement.supported);
    });
    test('div', () {
      expect((new DivElement()) is DivElement, true);
    });
    test('embed', () {
      expect((new EmbedElement()) is EmbedElement, EmbedElement.supported);
    });
    test('fieldset', () {
      expect((new FieldSetElement()) is FieldSetElement, true);
    });
    test('form', () {
      expect((new FormElement()) is FormElement, true);
    });
    test('head', () {
      expect((new HeadElement()) is HeadElement, true);
    });
    test('hr', () {
      expect((new HRElement()) is HRElement, true);
    });
    test('html', () {
      expect((new HtmlElement()) is HtmlElement, true);
    });
    test('h1', () {
      expect((new HeadingElement.h1()) is HeadingElement, true);
      expect(new Element.tag('h1') is HeadingElement, true);
    });
    test('h2', () {
      expect((new HeadingElement.h2()) is HeadingElement, true);
      expect(new Element.tag('h2') is HeadingElement, true);
    });
    test('h3', () {
      expect((new HeadingElement.h3()) is HeadingElement, true);
      expect(new Element.tag('h3') is HeadingElement, true);
    });
    test('h4', () {
      expect((new HeadingElement.h4()) is HeadingElement, true);
      expect(new Element.tag('h4') is HeadingElement, true);
    });
    test('h5', () {
      expect((new HeadingElement.h5()) is HeadingElement, true);
      expect(new Element.tag('h5') is HeadingElement, true);
    });
    test('h6', () {
      expect((new HeadingElement.h6()) is HeadingElement, true);
      expect(new Element.tag('h6') is HeadingElement, true);
    });
    test('iframe', () {
      expect((new IFrameElement()) is IFrameElement, true);
    });
    test('img', () {
      expect((new ImageElement()) is ImageElement, true);
    });
    test('input', () {
      expect((new InputElement()) is InputElement, true);
    });
    test('keygen', () {
      expect((new KeygenElement()) is KeygenElement, KeygenElement.supported);
    });
    test('li', () {
      expect((new LIElement()) is LIElement, true);
    });
    test('label', () {
      expect((new LabelElement()) is LabelElement, true);
    });
    test('legend', () {
      expect((new LegendElement()) is LegendElement, true);
    });
    test('link', () {
      expect((new LinkElement()) is LinkElement, true);
    });
    test('map', () {
      expect((new MapElement()) is MapElement, true);
    });
    test('menu', () {
      expect((new MenuElement()) is MenuElement, true);
    });
    test('meta', () {
      expect((new Element.tag('meta')) is MetaElement, true);
    });
    test('meter', () {
      expect((new Element.tag('meter')) is MeterElement, MeterElement.supported);
    });
    test('del', () {
      expect((new Element.tag('del')) is ModElement, true);
    });
    test('ins', () {
      expect((new Element.tag('ins')) is ModElement, true);
    });
    test('object', () {
      expect((new ObjectElement()) is ObjectElement, ObjectElement.supported);
    });
    test('ol', () {
      expect((new OListElement()) is OListElement, true);
    });
    test('optgroup', () {
      expect((new OptGroupElement()) is OptGroupElement, true);
    });
    test('option', () {
      expect((new OptionElement()) is OptionElement, true);
    });
    test('output', () {
      expect((new OutputElement()) is OutputElement, OutputElement.supported);
    });
    test('p', () {
      expect((new ParagraphElement()) is ParagraphElement, true);
    });
    test('param', () {
      expect((new ParamElement()) is ParamElement, true);
    });
    test('pre', () {
      expect((new PreElement()) is PreElement, true);
    });
    test('progress', () {
      expect((new ProgressElement()) is ProgressElement,
          ProgressElement.supported);
    });
    test('q', () {
      expect((new Element.tag('q')) is QuoteElement, true);
    });
    test('script', () {
      expect((new ScriptElement()) is ScriptElement, true);
    });
    test('select', () {
      expect((new SelectElement()) is SelectElement, true);
    });
    test('shadow', () {
      expect((new Element.tag('shadow')) is ShadowElement,
          ShadowElement.supported);
    });
    test('source', () {
      expect((new SourceElement()) is SourceElement, true);
    });
    test('span', () {
      expect((new SpanElement()) is SpanElement, true);
    });
    test('style', () {
      expect((new StyleElement()) is StyleElement, true);
    });
    test('table', () {
      expect((new TableElement()) is TableElement, true);
    });
    test('textarea', () {
      expect((new TextAreaElement()) is TextAreaElement, true);
    });
    test('title', () {
      expect((new TitleElement()) is TitleElement, true);
    });
    test('td', () {
      expect((new TableCellElement()) is TableCellElement, true);
    });
    test('col', () {
      expect((new TableColElement()) is TableColElement, true);
      expect((new Element.tag('colgroup')) is TableColElement, true);
    });
    test('tr', () {
      expect((new TableRowElement()) is TableRowElement, true);
    });
    test('table section', () {
      expect((new Element.tag('tbody')) is TableSectionElement, true);
      expect((new Element.tag('tfoot')) is TableSectionElement, true);
      expect((new Element.tag('thead')) is TableSectionElement, true);
    });
    test('track', () {
      expect((new Element.tag('track')) is TrackElement,
          TrackElement.supported);
    });
    test('ul', () {
      expect((new UListElement()) is UListElement, true);
      var ul = new UListElement();
      var li = new LIElement();
      ul.append(li);
    });
    test('video', () {
      expect((new VideoElement()) is VideoElement, true);
    });
    test('unknown', () {
      expect((new Element.tag('someunknown')) is UnknownElement, true);
    });;
  });
}
