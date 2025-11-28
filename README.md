# HLS4ML Development Environment (Bambu Backend)

This repository provides a self-contained Docker image for working with hls4ml and the Bambu HLS compiler backend.

The container is based on Ubuntu 22.04 and includes Miniconda3, Python 3.10, TensorFlow, Keras (CPU version), and the hls4ml repository (nghielme/hls4ml@bambu-backend). It also installs the bambu executable.

## Prerequisites

Docker or Podman: Ensure you have either Docker or Podman installed on your system.

## Setup 
### Building the Docker Image

The image is built using the provided Dockerfile. This process downloads and configures all necessary system libraries, Conda, Python environments, and installs the required packages as a non-root user (bambu_user).

Save the Dockerfile content to a file named Dockerfile in an empty directory.

Build the image using the following command (replace hls4ml-bambu with your desired image name):

```
podman build -t hls4ml-bambu .
# OR
docker build -t hls4ml-bambu .
```

### Running the Container

Run the built image in interactive mode. This command will execute the ENTRYPOINT defined in the Dockerfile, which activates the bambu_env Conda environment and drops you into a bash shell.

```
podman run -it --name bambu-dev hls4ml-bambu 
# OR
docker run -it --name bambu-dev hls4ml-bambu 
```

Once inside the container, your prompt should start with (bambu_env).

## Testing the Environment

To verify that the HLS tools and environment are set up correctly, perform the following two checks.

### Check Bambu Executable

Verify that the bambu executable is correctly installed and accessible on the PATH.

```
bambu --version
```

Expected Output: Bambu version information.


If this command executes successfully, the system dependencies and the path to the AppImage executable are correctly configured.

### Testing HLS4ML Project Generation and Build

Firstly copy the [[hls_config.py]] file into the container 
Then enter the python shell:
```
python3
```

Inside the Python shell:

```
>>> from hls_config import *
>>> hls_model.compile()
>>> hls_model.build()
```

Note on Build Crash (Expected Behavior):

It is normal and expected that the hls_model.build() command might fail or crash.
