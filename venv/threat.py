import tensorflow as tf
from tensorflow.keras import layers, Model, Input
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split

# ============================
# 1. Load & Preprocess Data
# ============================

# -- Heart Rate Data --
heart_rate_path = "Processed_HeartRateData.csv"
heart_rate_data = pd.read_csv(heart_rate_path)
# Ensure all values are numeric and drop any NaNs
heart_rate_data = heart_rate_data.apply(pd.to_numeric, errors='coerce').dropna()

# Expected columns: "Heart Rate", "Feature_1", "Feature_2", "State"
X_heart = heart_rate_data.drop(columns=["State"]).values.astype(np.float32)
y_heart = heart_rate_data["State"].values.astype(np.float32)

# -- Audio Data --
audio_path = "Processed_AudioData.csv"
audio_data = pd.read_csv(audio_path)
# Ensure all values are numeric and drop any NaNs
audio_data = audio_data.apply(pd.to_numeric, errors='coerce').dropna()

# Expected columns: "MFCC_1", "MFCC_2", ..., "Label"
X_audio = audio_data.drop(columns=["Label"]).values.astype(np.float32)
y_audio = audio_data["Label"].values.astype(np.float32)

# Align datasets by keeping only the number of samples present in both
min_samples = min(len(X_heart), len(X_audio))
if min_samples == 0:
    raise ValueError("No valid samples found in one or both datasets. Check your CSV files.")

X_heart = X_heart[:min_samples]
X_audio = X_audio[:min_samples]
# We'll use the heart rate label (assumed to be aligned with the audio label)
y = y_heart[:min_samples]

# Split into training and testing sets (80/20 split)
X_train_heart, X_test_heart, X_train_audio, X_test_audio, y_train, y_test = train_test_split(
    X_heart, X_audio, y, test_size=0.2, random_state=42
)

# For the audio branch, add a channel dimension: shape becomes (num_samples, num_features, 1)
X_train_audio = np.expand_dims(X_train_audio, axis=-1)
X_test_audio = np.expand_dims(X_test_audio, axis=-1)

# ============================
# 2. Build the Multi-Input Model
# ============================

# Heart Rate Branch (Dense layers)
heart_input = Input(shape=(X_train_heart.shape[1],), name="heart_input")
x1 = layers.Dense(64, activation='relu')(heart_input)
x1 = layers.Dense(32, activation='relu')(x1)

# Audio Branch (Conv1D + LSTM)
audio_input = Input(shape=(X_train_audio.shape[1], 1), name="audio_input")
x2 = layers.Conv1D(64, kernel_size=3, activation='relu')(audio_input)
x2 = layers.MaxPooling1D(pool_size=2)(x2)
x2 = layers.LSTM(64)(x2)

# Merge the branches
merged = layers.concatenate([x1, x2])
x = layers.Dense(64, activation='relu')(merged)
x = layers.Dense(32, activation='relu')(x)
output = layers.Dense(1, activation='sigmoid')(x)  # Binary classification output

# Define and compile the model
threat_model = Model(inputs=[heart_input, audio_input], outputs=output)
threat_model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
threat_model.summary()

# ============================
# 3. Train & Evaluate the Model
# ============================
threat_model.fit([X_train_heart, X_train_audio], y_train, epochs=10, batch_size=32)
test_loss, test_acc = threat_model.evaluate([X_test_heart, X_test_audio], y_test)
print("Test Accuracy: {:.4f}".format(test_acc))

# ============================
# 4. Save and Convert the Model to TFLite
# ============================

# Save the trained Keras model
threat_model.save("threat_model.h5")
print("Keras model saved as threat_model.h5")

# Convert the model to TensorFlow Lite format
converter = tf.lite.TFLiteConverter.from_keras_model(threat_model)

# Enable Select TF ops to allow conversion of unsupported TF ops (like some tensor list ops)
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS, 
    tf.lite.OpsSet.SELECT_TF_OPS
]

# Disable experimental lowering of tensor list ops (to avoid legalization errors)
converter._experimental_lower_tensor_list_ops = False

# Enable resource variables conversion if needed
converter.experimental_enable_resource_variables = True

# (Optional) Enable optimization for a smaller/faster model
converter.optimizations = [tf.lite.Optimize.DEFAULT]

tflite_model = converter.convert()

# Save the TFLite model to disk
tflite_model_path = "threat_model.tflite"
with open(tflite_model_path, "wb") as f:
    f.write(tflite_model)
print("TFLite model saved as", tflite_model_path)
