from ultralytics import YOLO

model = YOLO('yolo11m.pt')

results = model.train(
  data='../../rgb.yaml',
  batch=64
)
