from ultralytics import YOLO

model = YOLO('yolo11s.pt')

results = model.train(
  data='../../rgb.yaml',
  batch=128
)
