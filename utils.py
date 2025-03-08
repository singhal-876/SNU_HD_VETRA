import numpy as np

def preprocess_input(heart_rate, voice_data, scaler):
    # Prepare a feature vector from the inputs (heart rate, voice data)
    inputs = []
    
    if heart_rate is not None:
        inputs.append(float(heart_rate))
    else:
        inputs.append(0.0)
    
    if voice_data is not None:
        inputs.append(float(voice_data))
    else:
        inputs.append(0.0)

    # Scale the inputs
    inputs = np.array([inputs])
    inputs_scaled = scaler.transform(inputs)
    
    return inputs_scaled

def classify_threat(heart_rate, voice_data, scaler, model):
    # Preprocess input data
    inputs_scaled = preprocess_input(heart_rate, voice_data, scaler)
    
    # Predict threat level using the model
    prediction = model.predict(inputs_scaled)
    
    # Map prediction to threat levels
    threat_levels = {0: "low", 1: "medium", 2: "high"}
    
    return threat_levels.get(prediction[0], "unknown")
