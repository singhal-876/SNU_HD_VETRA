import os
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
import joblib

# File paths for the model and scaler
scaler_path = 'models/scaler.pkl'
model_path = 'models/threat_detection.pkl'

# Path to the CSV file
csv_file_path = 'data/data.csv'

def train_and_save_model():
    # Check if the CSV file exists, if not create it with sample data
    if not os.path.exists(csv_file_path):
        print(f"{csv_file_path} not found. Creating a sample data.csv file...")
        os.makedirs('data', exist_ok=True)
        with open(csv_file_path, 'w') as f:
            f.write("heart_rate,voice_data,threat_level\n")
            f.write("80,0.5,0\n")
            f.write("120,0.9,2\n")
            f.write("90,0.3,0\n")
            f.write("130,0.8,1\n")
            f.write("100,0.6,1\n")
            f.write("140,0.9,2\n")

    # Load data from the CSV file
    data = pd.read_csv(csv_file_path)

    # Assume data.csv has 'heart_rate', 'voice_data', and 'threat_level' columns
    X = data[['heart_rate', 'voice_data']]
    y = data['threat_level']

    # Split data into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Normalize the data
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    # Train the model (RandomForest is used here, but you can use any classifier)
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train_scaled, y_train)

    # Ensure the models/ directory exists before saving the files
    if not os.path.exists('models'):
        os.makedirs('models')

    # Save the scaler and model to files
    joblib.dump(scaler, scaler_path)
    joblib.dump(model, model_path)

    # Optional: Evaluate the model
    accuracy = model.score(X_test_scaled, y_test)
    print(f'Model trained and saved with accuracy: {accuracy:.2f}')

# Check if the model and scaler exist; if not, train and save them
if __name__ == '__main__':
    if not os.path.exists(scaler_path) or not os.path.exists(model_path):
        print("Model or scaler not found. Training and saving new model...")
        train_and_save_model()
    else:
        print("Model and scaler already exist. Skipping training.")
