# GraphQL ของแอป

โฟลเดอร์นี้เป็น "ต้นทาง" ของโค้ดที่ Apollo generate ไปไว้ที่
`Vertex/Core/Network/GraphQL/Generated/` — แก้ที่นี่แล้วต้อง generate ใหม่

```
schema.graphqls            คัดลอกมาจาก vertex-bff/graphql/schema.graphql
operations/                query กับ mutation ของแต่ละหน้าจอ
apollo-codegen-config.json ตั้งค่า codegen
```

## generate ใหม่

```sh
apollo-ios-cli generate --path graphql/apollo-codegen-config.json
```

ดาวน์โหลด `apollo-ios-cli` ได้จาก release ของ apollo-ios เวอร์ชันที่ตรงกับ
package ที่ใช้อยู่ (ตอนนี้ 2.4.0) ไม่ต้องเพิ่มอะไรใน Xcode project

## ตรวจ operation ก่อน generate

```sh
python3 -m pip install --user graphql-core
python3 - <<'PY'
from graphql import build_schema, parse, validate
import glob
s = build_schema(open('graphql/schema.graphqls').read())
doc = "\n".join(open(f).read() for f in sorted(glob.glob('graphql/operations/*.graphql')))
errs = validate(s, parse(doc))
print("ok" if not errs else errs)
PY
```

## สิ่งที่ห้ามลืม

**ไฟล์ที่แก้ด้วยมือแล้ว generate ทับไม่ได้** มีสองไฟล์ที่ Apollo ตั้งใจให้แก้เองและ
จะไม่ถูกเขียนทับ — `Schema/CustomScalars/DateTime.swift` (ตัวช่วยแปลงวัน)
กับ `Schema/SchemaConfiguration.swift` (cache key) ถ้าลบทั้งโฟลเดอร์ Generated
ทิ้งแล้ว generate ใหม่ ของสองอันนี้จะหายไปด้วย

**เวลาที่ส่งเป็น variable ต้องมี offset ของเครื่อง ห้ามเป็น `Z`** BFF แบ่งถังรายวัน
ตาม timezone ที่ติดมากับค่า `from` — ดูรายละเอียดใน `DateTime.swift`
