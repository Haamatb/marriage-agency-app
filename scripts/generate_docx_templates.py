#!/usr/bin/env python3
"""
generate_docx_templates.py
Creates sample .docx template files for:
  - Marriage Contract  (marriage_contract_template.docx)
  - Marriage Statement (marriage_statement_template.docx)
  - Agency Document   (agency_template.docx)

These are minimal valid .docx files with {{PLACEHOLDER}} tokens
that DocxTemplateEngine will replace.
"""

import zipfile
import os

ASSETS_DIR = os.path.join(os.path.dirname(__file__), "assets", "templates")
os.makedirs(ASSETS_DIR, exist_ok=True)

# ── Shared docx parts ─────────────────────────────────────────────────────────

CONTENT_TYPES = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml"
    ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/_rels/document.xml.rels"
    ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
</Types>"""

RELS = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    Target="word/document.xml"/>
</Relationships>"""

DOC_RELS = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>"""


def make_document_xml(paragraphs: list[str]) -> str:
    """Build a minimal word/document.xml with the given paragraph strings."""
    para_xml = ""
    for p in paragraphs:
        para_xml += f"""
  <w:p>
    <w:pPr>
      <w:bidi/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:r>
      <w:rPr><w:rtl/></w:rPr>
      <w:t xml:space="preserve">{p}</w:t>
    </w:r>
  </w:p>"""

    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document
  xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:w10="urn:schemas-microsoft-com:office:word"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
  xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml"
  xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
  xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
  xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
  xmlns:wtt="http://schemas.microsoft.com/office/word/2016/wordml/cid"
  mc:Ignorable="w14 w15 wp14">
  <w:body>{para_xml}
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>
    </w:sectPr>
  </w:body>
</w:document>"""


def create_docx(filename: str, paragraphs: list[str]):
    path = os.path.join(ASSETS_DIR, filename)
    doc_xml = make_document_xml(paragraphs)

    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", CONTENT_TYPES)
        zf.writestr("_rels/.rels", RELS)
        zf.writestr("word/_rels/document.xml.rels", DOC_RELS)
        zf.writestr("word/document.xml", doc_xml)

    print(f"✅  Created: {path}")


# ── Marriage Contract Template ─────────────────────────────────────────────────
create_docx("marriage_contract_template.docx", [
    "بسم الله الرحمن الرحيم",
    "",
    "عقد الزواج رقم: {{RECORD_NUMBER}}",
    "التاريخ الهجري: {{HIJRI_DATE}}   —   الموافق: {{GREGORIAN_DATE}}",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "بيانات الزوج",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "الاسم: {{HUSBAND_NAME}}",
    "نوع الهوية: {{HUSBAND_ID_TYPE}}   رقمها: {{HUSBAND_ID_NUMBER}}",
    "جهة الإصدار: {{HUSBAND_ID_ISSUE_PLACE}}   التاريخ: {{HUSBAND_ID_ISSUE_DATE}}",
    "محل الميلاد: {{HUSBAND_BIRTH_PLACE}}   محل الإقامة: {{HUSBAND_RESIDENCE}}",
    "الجنسية: {{HUSBAND_NATIONALITY}}   المهنة: {{HUSBAND_PROFESSION}}",
    "المستوى التعليمي: {{HUSBAND_EDUCATION}}",
    "الحالة الاجتماعية السابقة: {{HUSBAND_PREV_MARITAL}}",
    "اسم الأم: {{HUSBAND_MOTHER_NAME}}",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "بيانات الزوجة",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "الاسم: {{WIFE_NAME}}",
    "نوع الهوية: {{WIFE_ID_TYPE}}   رقمها: {{WIFE_ID_NUMBER}}",
    "جهة الإصدار: {{WIFE_ID_ISSUE_PLACE}}   التاريخ: {{WIFE_ID_ISSUE_DATE}}",
    "محل الميلاد: {{WIFE_BIRTH_PLACE}}   محل الإقامة: {{WIFE_RESIDENCE}}",
    "الجنسية: {{WIFE_NATIONALITY}}   المهنة: {{WIFE_PROFESSION}}",
    "المستوى التعليمي: {{WIFE_EDUCATION}}",
    "الحالة الاجتماعية السابقة: {{WIFE_PREV_MARITAL}}",
    "اسم الأم: {{WIFE_MOTHER_NAME}}",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "بيانات الولي",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "الاسم: {{GUARDIAN_NAME}}   صلة القرابة: {{GUARDIAN_RELATIONSHIP}}",
    "نوع الهوية: {{GUARDIAN_ID_TYPE}}   رقمها: {{GUARDIAN_ID_NUMBER}}",
    "جهة الإصدار: {{GUARDIAN_ID_ISSUE_PLACE}}   التاريخ: {{GUARDIAN_ID_ISSUE_DATE}}",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "المهر",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "مقدار المهر: {{MAHR_AMOUNT}}",
    "التفاصيل: {{MAHR_DETAILS}}",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "الشهود",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "الشاهد الأول: {{WITNESS1_NAME}}   رقم الهوية: {{WITNESS1_ID}}",
    "الشاهد الثاني: {{WITNESS2_NAME}}   رقم الهوية: {{WITNESS2_ID}}",
    "",
    "توقيع الزوج: __________________   توقيع الزوجة: __________________",
    "توقيع الولي: __________________   توقيع الشهود: __________________",
    "",
    "ختم المأذون الشرعي",
])

# ── Marriage Statement Template ────────────────────────────────────────────────
create_docx("marriage_statement_template.docx", [
    "بسم الله الرحمن الرحيم",
    "",
    "إفادة زواج",
    "",
    "يُفيد مكتب توثيق الزواجات والوكالات الشرعية",
    "بأن السيد / {{HUSBAND_NAME}}",
    "حامل الهوية رقم: {{HUSBAND_ID_NUMBER}}",
    "",
    "قد عقد قرانه على السيدة / {{WIFE_NAME}}",
    "حاملة الهوية رقم: {{WIFE_ID_NUMBER}}",
    "",
    "ولي الأمر: {{GUARDIAN_NAME}}",
    "مقدار المهر: {{MAHR_AMOUNT}}",
    "",
    "بتاريخ {{HIJRI_DATE}} الموافق {{GREGORIAN_DATE}}",
    "بموجب العقد رقم: {{RECORD_NUMBER}}",
    "",
    "أُعطيت هذه الإفادة بناءً على الطلب",
    "",
    "المأذون الشرعي",
    "التوقيع: _____________________",
    "الختم",
])

# ── Agency Template ────────────────────────────────────────────────────────────
create_docx("agency_template.docx", [
    "بسم الله الرحمن الرحيم",
    "",
    "وكالة شرعية رقم: {{AGENCY_NUMBER}}",
    "النوع: {{AGENCY_TYPE}}",
    "الموضوع: {{AGENCY_TITLE}}",
    "",
    "يوم {{DAY_NAME}} الموافق {{HIJRI_DATE}} / {{GREGORIAN_DATE}}",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "بيانات الموكِّل",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "الاسم: {{PRINCIPAL_NAME}}",
    "نوع الهوية: {{PRINCIPAL_ID_TYPE}}   رقمها: {{PRINCIPAL_ID_NUMBER}}",
    "جهة وتاريخ الإصدار: {{PRINCIPAL_ID_ISSUE}}",
    "رقم الجوال: {{PRINCIPAL_PHONE}}",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "بيانات الموكَّل إليه",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "الاسم: {{AGENT_NAME}}",
    "نوع الهوية: {{AGENT_ID_TYPE}}   رقمها: {{AGENT_ID_NUMBER}}",
    "جهة وتاريخ الإصدار: {{AGENT_ID_ISSUE}}",
    "رقم الجوال: {{AGENT_PHONE}}",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "محتوى الوكالة",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "[يُكتب محتوى الوكالة هنا مباشرةً في برنامج Word]",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "الشهود",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "الشاهد الأول: {{WITNESS1_NAME}}   رقم الهوية: {{WITNESS1_ID}}",
    "الشاهد الثاني: {{WITNESS2_NAME}}   رقم الهوية: {{WITNESS2_ID}}",
    "",
    "توقيع الموكِّل: __________________",
    "توقيع الموكَّل إليه: __________________",
    "توقيع الشهود: __________________",
    "",
    "ختم المأذون الشرعي",
])

print("\n🎉  All templates created successfully in:", ASSETS_DIR)
