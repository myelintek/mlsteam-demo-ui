import json
import request

import numpy as np
from flask import Flask
from keras.preprocessing import image
from keras.applications import resnet50

INFRENCE_API = "http://localhost:8500/v1/models/resnet50:predict"

app = Flask(__name__, static_url_path='', static_folder='dist')

def image_classification(image_file, top=5):
    img = image.load_img(image_file, target_size=(224, 224))
    # Convert the image to a numpy array
    x = image.img_to_array(img)
    # Add a forth dimension since Keras expects a list of images
    x = np.expand_dims(x, axis=0)
    # Scale the input image to the range used in the trained network
    x = resnet50.preprocess_input(x)
    
    data = json.dumps({"instances": x.tolist()})
    headers = {"content-type": "application/json"}
    json_response = requests.post(INFRENCE_API, data=data, headers=headers)

    predictions = json.loads(json_response.text)['predictions']
    # Decode predictions for top 9 most likely resnet50 classes
    predictions_arr = np.array(predictions)
    predicted_classes = resnet50.decode_predictions(predictions_arr, top=top)
    result = []
    for imagenet_id, name, likelihood in predicted_classes[0]:
        result.append({'id': imagenet_id, 'class': name, 'confidence': likelihood})
    return result

@app.route('/')
def load_app():
    return app.send_static_file('index.html')

@app.route('/inference')
def inference():
    flask.request.
    image_classification()
    return 'aa'

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)