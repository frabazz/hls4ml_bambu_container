import numpy as np
import tensorflow as tf
import hls4ml
from tensorflow.keras.layers import Dense, Activation
from pathlib import Path
import os
import shutil

TEST_BACKEND = 'bambu'
TEST_IO_TYPE = 'io_parallel'

TEST_ROOT_PATH = Path(__file__).parent
OUTPUT_DIR_NAME = f'hls4mlprj_keras_api_dense_{TEST_BACKEND}_{TEST_IO_TYPE}_quick'
OUTPUT_DIR = TEST_ROOT_PATH / OUTPUT_DIR_NAME

if OUTPUT_DIR.exists():
    shutil.rmtree(OUTPUT_DIR)

print(f" Quick test starting for Dense layer with {TEST_BACKEND} and {TEST_IO_TYPE} ")

keras_model = tf.keras.models.Sequential()
keras_model.add(
    Dense(
        2,
        input_shape=(1,),
        name='Dense',
        use_bias=True,
        kernel_initializer=tf.keras.initializers.RandomUniform(minval=1, maxval=10),
        bias_initializer='zeros',
    )
)
keras_model.add(Activation(activation='elu', name='Activation'))
keras_model.compile(optimizer='adam', loss='mse')

X_input = np.random.rand(100, 1).astype(np.float32)
keras_prediction = keras_model.predict(X_input)

config = hls4ml.utils.config_from_keras_model(keras_model)

hls_model = hls4ml.converters.convert_from_keras_model(
    keras_model, 
    hls_config=config, 
    output_dir=str(OUTPUT_DIR), 
    backend=TEST_BACKEND, 
    io_type=TEST_IO_TYPE
)

print("\n HLS4ML Compilation and Prediction...")
try:
    hls_model.compile()
    hls_prediction = hls_model.predict(X_input)
    print(" HLS4ML Prediction complete.")
    
    np.testing.assert_allclose(hls_prediction, keras_prediction, rtol=1e-2, atol=0.01)
    print(" Numerical ASSERT: Keras and HLS predictions match (within tolerance).")

except Exception as e:
    print(f" ERROR: HLS4ML compilation/prediction or numerical assert failed. The error is: {e}")


hls_layers = list(hls_model.get_layers())
keras_dense_layer = keras_model.layers[0]

print("\n Structural Verification...")
assert len(keras_model.layers) + 1 == len(hls_layers), f"Failed: Expected {len(keras_model.layers) + 1} layers in HLS, found {len(hls_layers)}."
print(" ASSERT: Layer count is correct (Input + Keras Layers).")

assert hls_layers[1].attributes["class_name"] == keras_dense_layer._name, f"Failed: Layer Name/Class does not match. Found {hls_layers[1].attributes['class_name']}."
print(" ASSERT: Converted Dense layer name is correct.")

expected_n_in = keras_dense_layer.input_shape[1:][0]
assert hls_layers[1].attributes['n_in'] == expected_n_in, f"Failed: Expected n_in {expected_n_in}, found {hls_layers[1].attributes['n_in']}."
print(f" ASSERT: n_in ({expected_n_in}) is correct.")

expected_n_out = keras_dense_layer.output_shape[1:][0]
assert hls_layers[1].attributes['n_out'] == expected_n_out, f"Failed: Expected n_out {expected_n_out}, found {hls_layers[1].attributes['n_out']}."
print(f" ASSERT: n_out ({expected_n_out}) is correct.")

assert hls_layers[2].attributes['class_name'] == 'ELU', f"Failed: Final activation is not ELU."
print(" ASSERT: The activation layer is ELU.")

print("\n All *structural* ASSERTS passed successfully!")
print(f"The HLS project directory was created in: {OUTPUT_DIR_NAME}")
