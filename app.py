from flask import Flask, request, jsonify
import joblib
import os
from utils import preprocess_input, classify_threat
from train_model import train_and_save_model

app = Flask(__name__)

# File paths for the model and scaler
scaler_path = 'models/scaler.pkl'
model_path = 'models/threat_detection.pkl'

# Ensure the model and scaler are trained and available
if not os.path.exists(scaler_path) or not os.path.exists(model_path):
    print("Model or scaler not found. Training and saving new model...")
    train_and_save_model()
else:
    print("Model and scaler loaded.")

# Load the pre-trained model and scaler
scaler = joblib.load(scaler_path)
model = joblib.load(model_path)

@app.route('/')
def index():
    return "Threat Detection API is running."

# Endpoint to receive heart rate data
@app.route('/heart_rate', methods=['POST'])
def heart_rate():
    data = request.json
    heart_rate = data.get('heart_rate')
    
    # Preprocess and classify the data
    threat_level = classify_threat(heart_rate=heart_rate, voice_data=None, scaler=scaler, model=model)
    
    return jsonify({"threat_level": threat_level})

# Endpoint to receive voice data
@app.route('/voice_data', methods=['POST'])
def voice_data():
    data = request.json
    voice_data = data.get('voice_data')
    
    # Preprocess and classify the data
    threat_level = classify_threat(heart_rate=None, voice_data=voice_data, scaler=scaler, model=model)
    
    return jsonify({"threat_level": threat_level})

# Endpoint to receive both heart rate and voice data
@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.json
    heart_rate = data.get('heart_rate')
    voice_data = data.get('voice_data')
    
    # Preprocess and classify the data
    threat_level = classify_threat(heart_rate=heart_rate, voice_data=voice_data, scaler=scaler, model=model)
    
    return jsonify({"threat_level": threat_level})

if __name__ == '__main__':
    app.run(debug=True)
