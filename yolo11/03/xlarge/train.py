from ultralytics import YOLO

model = YOLO('yolo11x.pt')

results = model.train(
  data='../../rgb.yaml',
  batch=2
)
