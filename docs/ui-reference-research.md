# UI reference research

This file tracks external screenshots collected for the Godot remake UI pass.
The image files are kept locally under `reference/ui-research/screenshots/` and
ignored by git; keep this document as the durable source list.

## Primary original UI references

| Local file | Source | Size | What it shows |
| --- | --- | ---: | --- |
| `ref-1-20220107081940276.jpg` | `https://pic.downxia.com/upload/2022/0107/20220107081940276.jpg` | 600x528 | Main window at day 0, default market/inventory/status/subway layout |
| `ref-2-20220107081954412.jpg` | `https://pic.downxia.com/upload/2022/0107/20220107081954412.jpg` | 600x528 | Borrow-money dialog over main screen |
| `ref-3-20220107082023283.jpg` | `https://pic.downxia.com/upload/2022/0107/20220107082023283.jpg` | 600x528 | Beijing introduction modal |
| `ref-4-20220107082303861.jpg` | `https://pic.downxia.com/upload/2022/0107/20220107082303861.jpg` | 600x528 | Diary/event modal with book image |
| `ref-5-20220107082322232.jpg` | `https://pic.downxia.com/upload/2022/0107/20220107082322232.jpg` | 600x528 | Diary/error modal with different state values |
| `ref-10-2013911111429108200.jpg` | `https://pic.ncsep.com/up/2013-9/2013911111429108200.jpg` | 640x563 | Main screen plus diary modal, wider capture |
| `ref-11-2013911111430663750.jpg` | `https://pic.ncsep.com/up/2013-9/2013911111430663750.jpg` | 640x563 | Inventory table showing three columns: goods, buy price, quantity |
| `ref-12-2013911111431320420.jpg` | `https://pic.ncsep.com/up/2013-9/2013911111431320420.jpg` | 640x563 | High-score modal and table layout |
| `ref-13-2013911111430653750.jpg` | `https://pic.ncsep.com/up/2013-9/2013911111430653750.jpg` | 544x185 | Beijing news modal |
| `ref-8-cePt1yc9NapF2.jpg` | `https://b.zol-img.com.cn/soft/6/13/cePt1yc9NapF2.jpg` | 634x558 | Rent-agency modal over later game state |

## Secondary / non-target references

| Local file | Source | Size | Notes |
| --- | --- | ---: | --- |
| `ref-6-cebhhTbnM9FM.jpg` | `https://b.zol-img.com.cn/soft/6/15/cebhhTbnM9FM.jpg` | 330x220 | Cover/menu art, useful for title/launcher only |
| `ref-7-cehFDSwje0Tt.jpg` | `https://b.zol-img.com.cn/soft/6/14/cehFDSwje0Tt.jpg` | 320x480 | Mobile/derived version, not the target desktop UI |
| `ref-9-B-Gi-fxxswfv2429814.jpg` | `http://n.sinaimg.cn/games/crawl/20161116/B-Gi-fxxswfv2429814.jpg` | 500x439 | Article image, useful for historical context only |

## UI implications

- Target a 600x528 or 640x563 capture scale first, then decide whether to preserve the original client area or modernize the window frame.
- Main inventory table should become three columns once inventory has items: `商品`, `买进价格`, `数量`.
- Main market rows use small item icons; our current table has no icons yet.
- Status digits should stay black-backed seven-segment displays, with `现金/存款/欠债` wide and `健康/名声` compact.
- Bottom buttons have bitmap icons plus text. Our current buttons only use text.
- Modal system needs several Win32-style templates: borrow money, Beijing introduction, diary/event with book image, rent agency, news, and high-score table.
