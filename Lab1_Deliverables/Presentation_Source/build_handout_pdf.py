"""Deterministic three-page PDF layout from the editable handout's content.
Uses the same text, tables and plot assets as the DOCX; no engineering calculations.
"""
from pathlib import Path
import sys, io, html, json
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'.task_review_tools'))
from docx import Document
from docx.text.paragraph import Paragraph as WordParagraph
from docx.table import Table as WordTable
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.platypus import Paragraph, Table, TableStyle, Image, Spacer
from PIL import Image as PILImage

out=root/'Lab1_Deliverables'
doc=Document(out/'Gulo_3000_Handout.docx')
pdfmetrics.registerFont(TTFont('Arial',r'C:\Windows\Fonts\arial.ttf'))
pdfmetrics.registerFont(TTFont('Arial-Bold',r'C:\Windows\Fonts\arialbd.ttf'))
pdfmetrics.registerFontFamily('Arial',normal='Arial',bold='Arial-Bold',italic='Arial',boldItalic='Arial-Bold')
navy=colors.HexColor('#062D48');gray=colors.HexColor('#526577');pale=colors.HexColor('#EDF3F6')

groups=[[]]
for el in doc.element.body:
    if el.tag.endswith('}p'):
        p=WordParagraph(el,doc)
        if 'w:type="page"' in p._p.xml:groups.append([])
        else:groups[-1].append(p)
    elif el.tag.endswith('}tbl'):groups[-1].append(WordTable(el,doc))
assert len(groups)==3

def convert_paragraph(p,width,font=9,image_scale=1,cell=False,header=False):
    embeds=p._p.xpath('.//a:blip/@r:embed')
    result=[]
    for rid in embeds:
        blob=doc.part.related_parts[rid].blob
        im=PILImage.open(io.BytesIO(blob));iw,ih=im.size
        ext=p._p.xpath('.//wp:extent')
        orig=float(ext[0].get('cx'))/12700 if ext else width
        # Slightly smaller figures leave room for the technical explanation.
        maxw=width if cell else min(width,390)
        target=min(orig,maxw)*image_scale
        result.append(Image(io.BytesIO(blob),width=target,height=target*ih/iw))
    if not p.text:return result or [Spacer(1,2)]
    name=p.style.name
    size=font;leading=font*1.15;before=0;after=3
    fontname='Arial';fg=navy
    if name=='Title':size=17;leading=20;fontname='Arial-Bold';after=5
    elif name.startswith('Heading'):size=12;leading=14;fontname='Arial-Bold';before=5;after=4
    elif cell:size=font-.7;leading=size*1.14;after=0
    elif p.runs and p.runs[0].font.size and p.runs[0].font.size.pt<=8:
        size=font-1;leading=size*1.16;fg=gray
    if header:fontname='Arial-Bold';fg=colors.white
    style=ParagraphStyle('p',fontName=fontname,fontSize=size,leading=leading,textColor=fg,
        spaceBefore=before,spaceAfter=after)
    # Preserve intentional bold runs, equations and line breaks.
    runs=[]
    for r in p.runs:
        s=html.escape(r.text).replace('\n','<br/>')
        if r.bold:s='<b>'+s+'</b>'
        runs.append(s)
    content=''.join(runs) or html.escape(p.text).replace('\n','<br/>')
    if before:result.append(Spacer(1,before))
    result.append(Paragraph(content,style))
    if after:result.append(Spacer(1,after))
    return result

def make_flows(group,font,image_scale):
    width=537.12;flows=[]
    for item in group:
        if isinstance(item,WordParagraph):flows.extend(convert_paragraph(item,width,font,image_scale))
        else:
            widths=[float(c.width)/12700 for c in item.columns]
            norm=width/sum(widths);widths=[v*norm for v in widths]
            is_thumb=bool(item._tbl.xpath('.//a:blip'))
            rows=[]
            for i,row in enumerate(item.rows):
                cols=[]
                for j,cell in enumerate(row.cells):
                    inner=[]
                    for p in cell.paragraphs:inner.extend(convert_paragraph(p,widths[j]-10,font,image_scale,True,not is_thumb and i==0))
                    cols.append(inner)
                rows.append(cols)
            tb=Table(rows,colWidths=widths,hAlign='LEFT')
            commands=[('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),5),
                ('RIGHTPADDING',(0,0),(-1,-1),5),('TOPPADDING',(0,0),(-1,-1),3),('BOTTOMPADDING',(0,0),(-1,-1),3)]
            if not is_thumb:
                commands += [('BACKGROUND',(0,0),(-1,0),navy)]
                for i in range(1,len(rows),2):commands.append(('BACKGROUND',(0,i),(-1,i),pale))
            tb.setStyle(TableStyle(commands));flows.extend([tb,Spacer(1,5)])
    return flows

target=out/'Gulo_3000_Handout.pdf'
c=canvas.Canvas(str(target),pagesize=(612,792))
c.setTitle('Gulo 3000 — Three-page technical handout')
c.setAuthor('Powertrain Dynamics Group')
audit=[]
for page,group in enumerate(groups,1):
    chosen=None
    for font,scale in [(12,1),(12,.95),(12,.90)]:
        flows=make_flows(group,font,scale)
        heights=[f.wrap(537.12,720)[1] for f in flows]
        if sum(heights)<=712:
            chosen=(flows,heights,font,scale);break
    if chosen is None:raise RuntimeError(f'Handout page {page} exceeds readable three-page layout: {sum(heights):.1f} pt')
    flows,heights,font,scale=chosen
    c.setFillColor(gray);c.setFont('Arial',7)
    c.drawString(37.44,774,'POWERTRAIN DYNAMICS GROUP  |  ME 495  |  SEPTEMBER 2026')
    c.setStrokeColor(colors.HexColor('#F3C84B'));c.setLineWidth(1);c.line(37.44,765,574.56,765)
    y=752
    for f,h in zip(flows,heights):
        # Center standalone plot images while keeping prose/table alignment.
        x=37.44+(537.12-f.drawWidth)/2 if isinstance(f,Image) else 37.44
        f.drawOn(c,x,y-h);y-=h
    c.setFillColor(gray);c.setFont('Arial',7);c.drawRightString(574.56,21,f'Gulo 3000 • Technical handout  |  {page} / 3')
    c.showPage();audit.append({'page':page,'font':font,'image_scale':scale,'content_height_pt':sum(heights),'bottom_y':y})
c.save()
(out/'Presentation_Source/handout_layout_audit.json').write_text(json.dumps(audit,indent=2))
print(json.dumps(audit,indent=2))
