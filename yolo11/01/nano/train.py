from ultralytics import YOLO

model = YOLO('yolo11n.pt')

results = model.train(
  data='../../rgb.yaml',
  batch=128
)
