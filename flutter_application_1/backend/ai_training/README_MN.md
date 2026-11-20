# SANAA AI — сургалтын эхлэх багц

Энэ багц нь **одоо байгаа Flutter/FastAPI төслийг өөрчлөхгүй**. Бүх файлыг `D:\Downloads\test\flutter_application_1\backend\ai_training\` дотор хуулж байрлуулна. `.venv_gpu`-г устгахгүй; SAM 2 загварын checkpoint-ийг дахин татахгүй.

## AI системийн 3 хэсэг

1. Тавилга таних: `YOLO11n-seg`-ийг өөрийн тэмдэглэсэн өгөгдлөөр **fine-tune** хийнэ; байгаа `SAM 2.1 tiny`-аар засварлагдах маск гаргана.
2. Тавилга арилгах: `SAM 2 mask → LaMa inpainting` (эхний шатанд бэлэн жин; өөрөө сургаж байна гэж бүү нэрлэ). OpenCV inpaint нь зөвхөн суурь туршилт.
3. Тохирох тавилга сонгох: эхэнд хэмжээс/төсөв/төрөл шалгах дүрэм; дараа нь өөрийн зөв/буруу сонголтын тэмдэглэгээгээр `train_recommender.py` сургана.

## Эхний өгөгдөл

- 4 ангилал: `0 sofa`, `1 table`, `2 chair`, `3 bed`. Цаашдаа wardrobe/lamp-г өөрчлөлттэй шинэ сургалтаар нэмнэ.
- Эхлэх зорилт: **60–100** зөв тэмдэглэсэн зураг; эхний харьцуулалт хийхэд **200–300+** ялгаатай өрөөний зураг руу өсгөнө. Энэ нь баталгаатай accuracy биш, практик эхлэх зорилт.
- Боломжтой бол өөрөө/зөвшөөрөлтэй айлуудад авсан гэрэл зураг. Цонх/өнгө/гэрэлтүүлэг, камерын өнцөг, тавилгын зай янз бүр байг.
- Нэг өрөөний олон зураг нэг *group* гэдгийг нэрээр нь тогтооно: `room001__view01.jpg`, `room001__view02.jpg`, өөр өрөө бол `room002__view01.jpg`.
- Хэрэглэгчийн хувийн зураг, байршил, бичиг баримтыг зөвшөөрөлгүй цуглуулахгүй; хувийн зурагтай dataset-ийг public GitHub-д оруулахгүй.

## Тэмдэглэгээ (annotation)

1. Зургаа `datasets/furniture_seg/raw/images/` дотор хийнэ.
2. CVAT эсвэл Roboflow дээр **Instance Segmentation** сонгоод буйдан/ширээ/сандал/ор тус бүрийн харагдаж буй гадна хүрээг polygon-аар тэмдэглэнэ.
3. `Ultralytics YOLO Segmentation` хэлбэрээр экспортлоно.
4. Харгалзах `.txt` label-ээ `datasets/furniture_seg/raw/labels/` дотор хуулна. Жишээ: `room001__view01.jpg` ↔ `room001__view01.txt`.
5. Class ID-гийн дараалал **заавал** 0 sofa, 1 table, 2 chair, 3 bed байна. Экспортод өөр дараалалтай бол ID remap хий. Хүснэгтийн label-аас class ID-г сохроор таахгүй.
6. Label-ийн мөр бүр: `<class> <x1> <y1> <x2> <y2> ...`; бүх x/y нь 0..1 хооронд. Зөвхөн дөрвөлжин bbox биш, объектын хүрээний polygon шаардлагатай.
7. Зөвшөөрөлгүй интернэт зураг, лиценз нь тодорхойгүй data-г ашиглахгүй. ADE20K-ийн зургууд боловсрол/судалгааны noncommercial зориулалттай. Roboflow Universe dataset бүр өөр лицензтэй.

## Windows PowerShell команд

VS Code Terminal (backend root дээр):

```powershell
cd D:\Downloads\test\flutter_application_1\backend
.\.venv_gpu\Scripts\Activate.ps1
cd .\ai_training
python scripts\check_env.py
```

`CUDA available: True` байх ёстой. `ultralytics` байхгүй бол **GPU venv-ийн орчноо нөөцлөөд**:

```powershell
python -m pip freeze > packages_before_ai_training.txt
python -m pip install ultralytics
python -m pip check
```

Хэрэв `pip` нь torch/cu124 хувилбар солихыг санал болговол шууд үргэлжлүүлэхгүй, backend-ийн нийцлийг шалга. C: диск дүүрсэн бол шинэ GPU env эсвэл PyTorch-г давхар суулгах шаардлагагүй.

### Өгөгдөл бэлэн болсны дараа

```powershell
python scripts\prepare_dataset.py
python scripts\train_yolo.py
```

`best.pt` нь `runs/segmentation/sanaa_furniture*/weights/best.pt` дотор үүснэ. Windows, GTX1650 4GB-д эхлээд `imgsz=416, batch=1, workers=0` тохируулсан. CUDA out of memory гарвал `imgsz=320` болгон бууруулж, бусад GPU програмыг хаа.

Сургасны дараа шинэ, сургалтад ороогүй өрөөний зургаар турш:

```powershell
python scripts\predict_yolo.py "D:\path\to\test_room.jpg"
```

Туршилтын үр дүн: `runs/predictions/room`.

## Тавилга санал болгох сургалт

- `templates/furniture_catalog.csv` — бодит бүтээгдэхүүний нэр, үнэ, хэмжээ, өнгө, материал, компанийн ID, тавилгын PNG зураг.
- `templates/recommendation_labels.csv` — өрөө бүрийн сонголт бүрийн `suitable=1` (тохирно) эсвэл `0` (тохирохгүй) тэмдэглэгээ. Зөвхөн таамгаар эерэг тэмдэглэгээ бүү дүүргэ; хүн хянасан байх ёстой.
- Өрөөний бодит өргөн/уртыг нэг фотоноос найдвартай хэмжих боломжгүй; эхний хувилбарт хэрэглэгчээс см-ээр авна.
- 100-аас олон labelled room×furniture хос, 10-аас олон independent room байхад туршилтын CPU model-г сургаж болно:

```powershell
python -m pip install pandas scikit-learn joblib
python scripts\train_recommender.py
```

Энэ model нь `runs/recommendations/furniture_ranker.joblib` үүсгэнэ. Хэдхэн тэмдэглэгээнээс гарсан оноог бодит accuracy мэт тайлагнаж болохгүй.

## Туршилт, дипломын тайлан

- Segmentation: class бүрийн mask mAP50, mAP50–95, precision, recall; training/validation/test-г өрөөгөөр нь салга.
- Inpainting: before/after жишээ, үнэлгээний rubric, нэг өнцгөөс авсан цэвэр reference зураг байвал SSIM зэрэг хэмжүүр.
- Recommendation: Precision@3, хэрэглэгчийн сонголт/тохирохгүй гэж үнэлсэн жишээнүүд; дүрэмд суурилсан baseline-тай харьцуул.
- Үр дүнг `train/val/test` leak-гүй, screenshot ба туршилтын нөхцөлтэй тайлбарла.

## Анхаарах нь

Одоохондоо `backend/main.py` болон Flutter файлуудыг автоматаар өөрчлөхгүй. Эхлээд dataset → сургалт → `best.pt` → тусдаа inference endpoint → Flutter холболт гэсэн дараалал баримтална.
