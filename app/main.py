import os
import json
import requests

import numpy as np
import PIL.Image as Image
import tensorflow.compat.v2 as tf
import tensorflow_hub as hub
from keras.applications import resnet50
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename


TFHUB_CLASSIFY_MODEL = "https://tfhub.dev/google/imagenet/resnet_v2_50/classification/5"
CACH_FOLDER = "/dev/shm/mlsteam-demo-ui"
IMAGE_SHAPE = (224, 224)
app = Flask(__name__, static_url_path='', static_folder='static')


class ImageClassificationService(object):
    def __init__(self):
        self.classifier = tf.keras.Sequential([
            hub.KerasLayer(TFHUB_CLASSIFY_MODEL, input_shape=IMAGE_SHAPE+(3,))
        ])

    def inference(self, images):
        logits = self.classifier.predict(images)    
        return tf.nn.softmax(logits).numpy()

    
infer_serv = ImageClassificationService()


def image_classification(image_files, top=5):
    if not isinstance(image_files, list):
        image_files=[image_files]

    # Load and convert image array the image to a numpy array
    images = [Image.open(img).resize(IMAGE_SHAPE) for img in image_files]
    image_arr = [np.expand_dims(np.array(img)/255.0, axis=0) for img in images]
    x = np.concatenate(image_arr, axis=0)
    softmax = infer_serv.inference(x)

    predicted_classes = resnet50.decode_predictions(softmax[:, 1:], top=top)
    results = []
    for image_result in predicted_classes:
        result = []
        for imagenet_id, name, likelihood in image_result:
            result.append({'id': imagenet_id, 'class': name, 'confidence': float(likelihood)})
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
        path = os.path.join(CACH_FOLDER, secure_filename(img.filename))
        img.save(path)
        image_files.append(path)
    results = image_classification(image_files)
    return jsonify(results)


if __name__ == "__main__":
    if not os.path.exists(CACH_FOLDER):
        os.makedirs(CACH_FOLDER)
    app.run(host="0.0.0.0", port=80)
