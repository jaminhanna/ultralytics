from ultralytics import YOLO

model = YOLO('yolo11l.pt')

results = model.train(
  data='../../rgb.yaml',
  batch=32
)
