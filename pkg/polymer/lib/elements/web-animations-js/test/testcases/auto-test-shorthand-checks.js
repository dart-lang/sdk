timing_test(function() {
  at(0, function() {
    assert_styles("#background.test",{'backgroundImage':'none','backgroundPosition':'0% 0%','backgroundSize':'auto','backgroundRepeat':'repeat','backgroundAttachment':'scroll','backgroundOrigin':'padding-box','backgroundClip':'border-box','backgroundColor':'rgb(176, 196, 222)'});
  }, "#background");
  at(0, function() {
    assert_styles("#border.test",{'borderTopColor':'rgb(0, 0, 0)','borderTopStyle':'none','borderTopWidth':'0px','borderRightColor':'rgb(0, 0, 0)','borderRightStyle':'none','borderRightWidth':'0px','borderBottomColor':'rgb(0, 0, 0)','borderBottomStyle':'none','borderBottomWidth':'0px','borderLeftColor':'rgb(0, 0, 0)','borderLeftStyle':'none','borderLeftWidth':'0px'});
  }, "#border");
  at(0, function() {
    assert_styles("#borderBottom.test",{'borderBottomWidth':'0px','borderBottomStyle':'none','borderBottomColor':'rgb(0, 0, 0)'});
  }, "#borderBottom");
  at(0, function() {
    assert_styles("#borderColor.test",{'borderTopColor':'rgb(0, 0, 0)','borderRightColor':'rgb(0, 0, 0)','borderBottomColor':'rgb(0, 0, 0)','borderLeftColor':'rgb(0, 0, 0)'});
  }, "#borderColor");
  at(0, function() {
    assert_styles("#borderLeft.test",{'borderLeftWidth':'0px','borderLeftStyle':'none','borderLeftColor':'rgb(0, 0, 0)'});
  }, "#borderLeft");
  at(0, function() {
    assert_styles("#borderRadius.test",{'borderTopLeftRadius':'0px','borderTopRightRadius':'0px','borderBottomRightRadius':'0px','borderBottomLeftRadius':'0px'});
  }, "#borderRadius");
  at(0, function() {
    assert_styles("#borderRight.test",{'borderRightWidth':'0px','borderRightStyle':'none','borderRightColor':'rgb(0, 0, 0)'});
  }, "#borderRight");
  at(0, function() {
    assert_styles("#borderTop.test",{'borderTopWidth':'0px','borderTopStyle':'none','borderTopColor':'rgb(0, 0, 0)'});
  }, "#borderTop");
  at(0, function() {
    assert_styles("#borderWidth.test",{'borderTopWidth':'3px','borderRightWidth':'3px','borderBottomWidth':'3px','borderLeftWidth':'3px'});
  }, "#borderWidth");
  at(0, function() {
    assert_styles("#font.test",{'fontFamily':'\'DejaVu Sans\', \'Bitstream Vera Sans\', Arial, Sans','fontSize':'16px','fontStyle':'normal','fontVariant':'normal','fontWeight':'normal','lineHeight':'19.2000px'});
  }, "#font");
  at(0, function() {
    assert_styles("#margin.test",{'marginTop':'0px','marginRight':'10px','marginBottom':'0px','marginLeft':'0px'});
  }, "#margin");
  at(0, function() {
    assert_styles("#outline.test",{'outlineColor':'rgb(0, 0, 0)','outlineStyle':'none','outlineWidth':'0px'});
  }, "#outline");
  at(0, function() {
    assert_styles("#padding.test",{'paddingTop':'0px','paddingRight':'0px','paddingBottom':'0px','paddingLeft':'0px'});
  }, "#padding");
  at(0.5, function() {
    assert_styles("#background.test",{'backgroundImage':'none','backgroundPosition':'12.5% 6.25%','backgroundSize':'auto','backgroundRepeat':'repeat','backgroundAttachment':'scroll','backgroundOrigin':'padding-box','backgroundClip':'border-box','backgroundColor':'rgb(132, 179, 167)'});
  }, "#background");
  at(0.5, function() {
    assert_styles("#border.test",{'borderTopColor':'rgb(0, 32, 0)','borderTopStyle':'none','borderTopWidth':'0px','borderRightColor':'rgb(0, 32, 0)','borderRightStyle':'none','borderRightWidth':'0px','borderBottomColor':'rgb(0, 32, 0)','borderBottomStyle':'none','borderBottomWidth':'0px','borderLeftColor':'rgb(0, 32, 0)','borderLeftStyle':'none','borderLeftWidth':'0px'});
  }, "#border");
  at(0.5, function() {
    assert_styles("#borderBottom.test",{'borderBottomWidth':'0px','borderBottomStyle':'none','borderBottomColor':'rgb(0, 32, 0)'});
  }, "#borderBottom");
  at(0.5, function() {
    assert_styles("#borderColor.test",{'borderTopColor':'rgb(0, 64, 0)','borderRightColor':'rgb(36, 60, 36)','borderBottomColor':'rgb(0, 25, 0)','borderLeftColor':'rgb(0, 32, 0)'});
  }, "#borderColor");
  at(0.5, function() {
    assert_styles("#borderLeft.test",{'borderLeftWidth':'0px','borderLeftStyle':'none','borderLeftColor':'rgb(0, 32, 0)'});
  }, "#borderLeft");
  at(0.5, function() {
    assert_styles("#borderRadius.test",{'borderTopLeftRadius':'2.5px','borderTopRightRadius':'5px','borderBottomRightRadius':'calc(0px + 2.5%)','borderBottomLeftRadius':'calc(0px + 12.5%)'});
  }, "#borderRadius");
  at(0.5, function() {
    assert_styles("#borderRight.test",{'borderRightWidth':'0px','borderRightStyle':'none','borderRightColor':'rgb(0, 32, 0)'});
  }, "#borderRight");
  at(0.5, function() {
    assert_styles("#borderTop.test",{'borderTopWidth':'0px','borderTopStyle':'none','borderTopColor':'rgb(0, 32, 0)'});
  }, "#borderTop");
  at(0.5, function() {
    assert_styles("#borderWidth.test",{'borderTopWidth':'2px','borderRightWidth':'3px','borderBottomWidth':'3px','borderLeftWidth':'4px'});
  }, "#borderWidth");
  at(0.5, function() {
    assert_styles("#font.test",{'fontFamily':'\'DejaVu Sans\', \'Bitstream Vera Sans\', Arial, Sans','fontSize':'19.2000px','fontStyle':'normal','fontVariant':'normal','fontWeight':'500','lineHeight':'26.1333px'});
  }, "#font");
  at(0.5, function() {
    assert_styles("#margin.test",{'marginTop':'1.25px','marginRight':'10px','marginBottom':'3.75px','marginLeft':'5px'});
  }, "#margin");
  at(0.5, function() {
    assert_styles("#outline.test",{'outlineColor':'rgb(0, 32, 0)','outlineStyle':'none','outlineWidth':'0px'});
  }, "#outline");
  at(0.5, function() {
    assert_styles("#padding.test",{'paddingTop':'1.25px','paddingRight':'2.5px','paddingBottom':'3.75px','paddingLeft':'5px'});
  }, "#padding");
  at(1, function() {
    assert_styles("#background.test",{'backgroundPosition':'25% 12.5%','backgroundSize':'auto','backgroundRepeat':'repeat-y','backgroundAttachment':'scroll','backgroundOrigin':'padding-box','backgroundClip':'border-box','backgroundColor':'rgb(88, 162, 111)'});
  }, "#background");
  at(1, function() {
    assert_styles("#border.test",{'borderTopColor':'rgb(0, 64, 0)','borderTopStyle':'solid','borderTopWidth':'2px','borderRightColor':'rgb(0, 64, 0)','borderRightStyle':'solid','borderRightWidth':'2px','borderBottomColor':'rgb(0, 64, 0)','borderBottomStyle':'solid','borderBottomWidth':'2px','borderLeftColor':'rgb(0, 64, 0)','borderLeftStyle':'solid','borderLeftWidth':'2px'});
  }, "#border");
  at(1, function() {
    assert_styles("#borderBottom.test",{'borderBottomWidth':'2px','borderBottomStyle':'solid','borderBottomColor':'rgb(0, 64, 0)'});
  }, "#borderBottom");
  at(1, function() {
    assert_styles("#borderColor.test",{'borderTopColor':'rgb(0, 128, 0)','borderRightColor':'rgb(72, 119, 72)','borderBottomColor':'rgb(0, 50, 0)','borderLeftColor':'rgb(0, 64, 0)'});
  }, "#borderColor");
  at(1, function() {
    assert_styles("#borderLeft.test",{'borderLeftWidth':'2px','borderLeftStyle':'solid','borderLeftColor':'rgb(0, 64, 0)'});
  }, "#borderLeft");
  at(1, function() {
    assert_styles("#borderRadius.test",{'borderTopLeftRadius':'5px','borderTopRightRadius':'10px','borderBottomRightRadius':'calc(0px + 5%)','borderBottomLeftRadius':'calc(0px + 25%)'});
  }, "#borderRadius");
  at(1, function() {
    assert_styles("#borderRight.test",{'borderRightWidth':'2px','borderRightStyle':'solid','borderRightColor':'rgb(0, 64, 0)'});
  }, "#borderRight");
  at(1, function() {
    assert_styles("#borderTop.test",{'borderTopWidth':'2px','borderTopStyle':'solid','borderTopColor':'rgb(0, 64, 0)'});
  }, "#borderTop");
  at(1, function() {
    assert_styles("#borderWidth.test",{'borderTopWidth':'2px','borderRightWidth':'3px','borderBottomWidth':'4px','borderLeftWidth':'6px'});
  }, "#borderWidth");
  at(1, function() {
    assert_styles("#font.test",{'fontFamily':'serif','fontSize':'21px','fontStyle':'italic','fontVariant':'normal','fontWeight':'600','lineHeight':'34.1333px'});
  }, "#font");
  at(1, function() {
    assert_styles("#margin.test",{'marginTop':'2.5px','marginRight':'10px','marginBottom':'7.5px','marginLeft':'10px'});
  }, "#margin");
  at(1, function() {
    assert_styles("#outline.test",{'outlineColor':'rgb(0, 64, 0)','outlineStyle':'solid','outlineWidth':'2px'});
  }, "#outline");
  at(1, function() {
    assert_styles("#padding.test",{'paddingTop':'2.5px','paddingRight':'5px','paddingBottom':'7.5px','paddingLeft':'10px'});
  }, "#padding");
  at(1.5, function() {
    assert_styles("#background.test",{'backgroundPosition':'37.5% 18.75%','backgroundSize':'auto','backgroundRepeat':'repeat-y','backgroundAttachment':'scroll','backgroundOrigin':'padding-box','backgroundClip':'border-box','backgroundColor':'rgb(44, 145, 56)'});
  }, "#background");
  at(1.5, function() {
    assert_styles("#border.test",{'borderTopColor':'rgb(0, 96, 0)','borderTopStyle':'solid','borderTopWidth':'3px','borderRightColor':'rgb(0, 96, 0)','borderRightStyle':'solid','borderRightWidth':'3px','borderBottomColor':'rgb(0, 96, 0)','borderBottomStyle':'solid','borderBottomWidth':'3px','borderLeftColor':'rgb(0, 96, 0)','borderLeftStyle':'solid','borderLeftWidth':'3px'});
  }, "#border");
  at(1.5, function() {
    assert_styles("#borderBottom.test",{'borderBottomWidth':'3px','borderBottomStyle':'solid','borderBottomColor':'rgb(0, 96, 0)'});
  }, "#borderBottom");
  at(1.5, function() {
    assert_styles("#borderColor.test",{'borderTopColor':'rgb(0, 191, 0)','borderRightColor':'rgb(108, 179, 108)','borderBottomColor':'rgb(0, 75, 0)','borderLeftColor':'rgb(0, 96, 0)'});
  }, "#borderColor");
  at(1.5, function() {
    assert_styles("#borderLeft.test",{'borderLeftWidth':'3px','borderLeftStyle':'solid','borderLeftColor':'rgb(0, 96, 0)'});
  }, "#borderLeft");
  at(1.5, function() {
    assert_styles("#borderRadius.test",{'borderTopLeftRadius':'7.5px','borderTopRightRadius':'15px','borderBottomRightRadius':'calc(0px + 7.5%)','borderBottomLeftRadius':'calc(0px + 37.5%)'});
  }, "#borderRadius");
  at(1.5, function() {
    assert_styles("#borderRight.test",{'borderRightWidth':'3px','borderRightStyle':'solid','borderRightColor':'rgb(0, 96, 0)'});
  }, "#borderRight");
  at(1.5, function() {
    assert_styles("#borderTop.test",{'borderTopWidth':'3px','borderTopStyle':'solid','borderTopColor':'rgb(0, 96, 0)'});
  }, "#borderTop");
  at(1.5, function() {
    assert_styles("#borderWidth.test",{'borderTopWidth':'1px','borderRightWidth':'3px','borderBottomWidth':'4px','borderLeftWidth':'8px'});
  }, "#borderWidth");
  at(1.5, function() {
    assert_styles("#font.test",{'fontFamily':'serif','fontSize':'24px','fontStyle':'italic','fontVariant':'normal','fontWeight':'600','lineHeight':'43.2000px'});
  }, "#font");
  at(1.5, function() {
    assert_styles("#margin.test",{'marginTop':'3.75px','marginRight':'10px','marginBottom':'11.25px','marginLeft':'15px'});
  }, "#margin");
  at(1.5, function() {
    assert_styles("#outline.test",{'outlineColor':'rgb(0, 96, 0)','outlineStyle':'solid','outlineWidth':'3px'});
  }, "#outline");
  at(1.5, function() {
    assert_styles("#padding.test",{'paddingTop':'3.75px','paddingRight':'7.5px','paddingBottom':'11.25px','paddingLeft':'15px'});
  }, "#padding");
  at(2, function() {
    assert_styles("#background.test",{'backgroundPosition':'50% 25%','backgroundSize':'auto','backgroundRepeat':'repeat-y','backgroundAttachment':'scroll','backgroundOrigin':'padding-box','backgroundClip':'border-box','backgroundColor':'rgb(0, 128, 0)'});
  }, "#background");
  at(2, function() {
    assert_styles("#border.test",{'borderTopColor':'rgb(0, 128, 0)','borderTopStyle':'solid','borderTopWidth':'4px','borderRightColor':'rgb(0, 128, 0)','borderRightStyle':'solid','borderRightWidth':'4px','borderBottomColor':'rgb(0, 128, 0)','borderBottomStyle':'solid','borderBottomWidth':'4px','borderLeftColor':'rgb(0, 128, 0)','borderLeftStyle':'solid','borderLeftWidth':'4px'});
  }, "#border");
  at(2, function() {
    assert_styles("#borderBottom.test",{'borderBottomWidth':'4px','borderBottomStyle':'solid','borderBottomColor':'rgb(0, 128, 0)'});
  }, "#borderBottom");
  at(2, function() {
    assert_styles("#borderColor.test",{'borderTopColor':'rgb(0, 255, 0)','borderRightColor':'rgb(144, 238, 144)','borderBottomColor':'rgb(0, 100, 0)','borderLeftColor':'rgb(0, 128, 0)'});
  }, "#borderColor");
  at(2, function() {
    assert_styles("#borderLeft.test",{'borderLeftWidth':'4px','borderLeftStyle':'solid','borderLeftColor':'rgb(0, 128, 0)'});
  }, "#borderLeft");
  at(2, function() {
    assert_styles("#borderRadius.test",{'borderTopLeftRadius':'10px','borderTopRightRadius':'20px','borderBottomRightRadius':'10%','borderBottomLeftRadius':'50%'});
  }, "#borderRadius");
  at(2, function() {
    assert_styles("#borderRight.test",{'borderRightWidth':'4px','borderRightStyle':'solid','borderRightColor':'rgb(0, 128, 0)'});
  }, "#borderRight");
  at(2, function() {
    assert_styles("#borderTop.test",{'borderTopWidth':'4px','borderTopStyle':'solid','borderTopColor':'rgb(0, 128, 0)'});
  }, "#borderTop");
  at(2, function() {
    assert_styles("#borderWidth.test",{'borderTopWidth':'1px','borderRightWidth':'3px','borderBottomWidth':'5px','borderLeftWidth':'10px'});
  }, "#borderWidth");
  at(2, function() {
    assert_styles("#font.test",{'fontFamily':'serif','fontSize':'27px','fontStyle':'italic','fontVariant':'normal','fontWeight':'bold','lineHeight':'53.3333px'});
  }, "#font");
  at(2, function() {
    assert_styles("#margin.test",{'marginTop':'5px','marginRight':'10px','marginBottom':'15px','marginLeft':'20px'});
  }, "#margin");
  at(2, function() {
    assert_styles("#outline.test",{'outlineColor':'rgb(0, 128, 0)','outlineStyle':'solid','outlineWidth':'5px'});
  }, "#outline");
  at(2, function() {
    assert_styles("#padding.test",{'paddingTop':'5px','paddingRight':'10px','paddingBottom':'15px','paddingLeft':'20px'});
  }, "#padding");
}, "Auto generated tests");
