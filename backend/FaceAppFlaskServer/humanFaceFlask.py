from keras.models import load_model
from  flask import Flask, jsonify, request
import base64
import io
from keras.preprocessing.image import img_to_array
import numpy as np

import  time
from keras.preprocessing.image import save_img
import tensorflow as tf 
from PIL import Image
from flask_restful import Resource, Api, reqparse


# 1. open terminal
# 2. activate your environment
# 3. cd provide your Flask Server Folder Path
# use set in windows and export in non window
# 4 set FLASK_APP=humanFaceFlask.py
# 5. set FLASK_ENV=development
# 6. flask run --host=Your IP Address


app = Flask(__name__)
api = Api(app)



model = load_model("test.h5")
print(" * Model Loaded ")




def make_image(image, target):
    if image.mode != "RGB":
        image = image.convert("RGB")
    
    image = image.resize(target)
    image = img_to_array(image)

    image = (image - 127.5) / 127.5
    image = np.expand_dims(image, axis=0)
    return image





class PredictFace(Resource):
    def post(self):
        json_data = request.get_json()
        img_data = json_data["Image"]

        image = base64.b64decode(str(img_data))

        img = Image.open(io.BytesIO(image))

        preparedImage = make_image(img, target=(256,256))

        pred = model.predict(preparedImage)

        outputFile = "output.png"
        savePath = "./output/"

        output = tf.reshape(pred, [256,256,3])
        output = (output + 1) / 2
        save_img(savePath+outputFile, img_to_array(output))

        imageNew = Image.open(savePath+outputFile)
        imageNew = imageNew.resize((50,50))
        imageNew.save(savePath+"new_"+outputFile)

        with  open(savePath+"new_"+outputFile, "rb") as image_file:
            encoded_string = base64.b64encode(image_file.read())

        outputData = {
            "Image" : str(encoded_string),
        }
        return outputData



api.add_resource(PredictFace, "/predict")

if __name__ == "__main__":
    app.run(debug=True)

