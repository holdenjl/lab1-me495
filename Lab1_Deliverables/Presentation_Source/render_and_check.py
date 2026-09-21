"""Render exported PDFs for visual inspection and create the poster thumbnail."""
from pathlib import Path
import sys, json
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'.task_review_tools'))
import pymupdf
out=root/'Lab1_Deliverables'
review=out/'Presentation_Source'/'Review'
review.mkdir(exist_ok=True)
audit={}
for name in ['Gulo_3000_Poster','Gulo_3000_Handout']:
    path=out/(name+'.pdf')
    if not path.exists():continue
    doc=pymupdf.open(path)
    audit[name]={'pages':len(doc),'page_sizes':[list(p.rect) for p in doc]}
    for i,page in enumerate(doc):
        scale=1.2 if 'Poster' in name else 1.6
        page.get_pixmap(matrix=pymupdf.Matrix(scale,scale)).save(review/(name+f'_{i+1}.png'))
        (review/(name+f'_{i+1}.txt')).write_text(page.get_text(),encoding='utf-8')
    if 'Poster' in name:
        doc[0].get_pixmap(matrix=pymupdf.Matrix(.6,.6)).save(out/'Presentation_Source/poster_thumbnail.png')
(review/'document_audit.json').write_text(json.dumps(audit,indent=2))
print(json.dumps(audit,indent=2))
