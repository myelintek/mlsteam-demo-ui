import os
import json
import requests

import numpy as np
from flask import Flask, request, jsonify
from keras.preprocessing import image
from keras.applications import resnet50
from werkzeug.utils import secure_filename

INFRENCE_API = "http://localhost:8500/v1/models/resnet50:predict"
CACH_FOLDER = "/dev/shm/mlsteam-demo-ui"
app = Flask(__name__, static_url_path='', static_folder='dist')

def image_classification(image_files, top=5):
    if not isinstance(image_files, list):
        image_files=[image_files]
    # Load and convert image array the image to a numpy array
    images = [image.load_img(img, target_size=(224, 224)) for img in image_files]
    image_arr = [np.expand_dims(image.img_to_array(img), axis=0) for img in images]
    image_batch = np.concatenate(image_arr, axis=0)

    # Scale the input image to the range used in the trained network
    x = resnet50.preprocess_input(image_batch)

    data = json.dumps({"instances": x.tolist()})
    headers = {"content-type": "application/json"}
    json_response = requests.post(INFRENCE_API, data=data, headers=headers)
    
    # Decode predictions for top 9 most likely resnet50 classes
    predictions = json.loads(json_response.text)['predictions']
    predictions_arr = np.array(predictions)
    predicted_classes = resnet50.decode_predictions(predictions_arr, top=top)
    results = []
    for image_result in predicted_classes:
        result = []
        for imagenet_id, name, likelihood in image_result:
            result.append({'id': imagenet_id, 'class': name, 'confidence': likelihood})
        results.append(result)
    return results

@app.route('/')
def load_app():
    return app.send_static_file('index.html')

@app.route('/inference', methods=['POST'])
def inference():
    images = request.files.getlist("images")
    image_files = []
    for img in images:
        path = os.path.join(CACH_FOLDER,secure_filename(img.filename))
        img.save(path)
        image_files.append(path)
    results = image_classification(image_files)
    return jsonify(results)

if __name__ == "__main__":
    if not os.path.exists(CACH_FOLDER):
        os.makedirs(CACH_FOLDER)
    app.run(host="0.0.0.0", port=5000)