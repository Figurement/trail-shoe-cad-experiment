"""Make a nondistorted reference/CAD board from FreeCAD-scripted images."""
import os
import sys

os.environ["QT_QPA_PLATFORM"] = "offscreen"
from PySide6.QtCore import QRect, Qt
from PySide6.QtGui import QColor, QFont, QGuiApplication, QImage, QPainter

app = QGuiApplication([])
root = os.path.dirname(os.path.abspath(__file__))
cad = os.path.join(root, "cad")
prefix = "editable_" if "--editable" in sys.argv else ""


def load(path):
    image = QImage(path)
    if image.isNull():
        raise ValueError("Cannot load image: " + path)
    return image


hero = load(os.path.join(root, "Gemini_Generated_Image_t8v95jt8v95jt8v9.jpg")).scaledToWidth(2000)
triptych = load(os.path.join(root, "Gemini_Generated_Image_8vkt9v8vkt9v8vkt.jpg")).scaledToWidth(2000)
pairs = [
    ("Lateral", hero.copy(345, 195, 1340, 700), "01_lateral_hero"),
    ("Medial", triptych.copy(595, 390, 845, 430), "12_medial_reference_angle"),
    ("Front", triptych.copy(130, 180, 485, 740), "11_front_reference_angle"),
    ("Heel", triptych.copy(1505, 265, 430, 640), "06_heel")
]
board = QImage(1600, 1580, QImage.Format.Format_RGB32)
board.fill(QColor("white"))
painter = QPainter(board)
painter.setFont(QFont("Arial", 20))
painter.setPen(QColor("#253343"))
painter.drawText(25, 35, "Reference concepts")
painter.drawText(825, 35, "Editable CAD" if prefix else "Reference reconstruction CAD")
for row, (label, reference, filename) in enumerate(pairs):
    model = load(os.path.join(cad, prefix + filename + ".png"))
    occupied = [(x, y) for y in range(0, model.height(), 3)
                for x in range(0, model.width(), 3)
                if min(model.pixelColor(x, y).getRgb()[:3]) < 235]
    if not occupied:
        raise ValueError("Blank CAD image: " + filename)
    xmin, xmax = min(p[0] for p in occupied), max(p[0] for p in occupied)
    ymin, ymax = min(p[1] for p in occupied), max(p[1] for p in occupied)
    model = model.copy(QRect(xmin-6, ymin-6, xmax-xmin+12, ymax-ymin+12).intersected(model.rect()))
    top = 65 + row * 375
    painter.drawText(25, top+20, label)
    for column, image in enumerate([reference, model]):
        fitted = image.scaled(750, 330, Qt.AspectRatioMode.KeepAspectRatio,
                              Qt.TransformationMode.SmoothTransformation)
        painter.drawImage(25 + column*800 + (750-fitted.width())//2,
                          top+35+(330-fitted.height())//2, fitted)
painter.end()
destination = os.path.join(cad, prefix + "reference_comparison.png")
if not board.save(destination):
    raise OSError("Could not save comparison: " + destination)
print(destination)
