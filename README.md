# HLS4ML Development Environment (Bambu Backend)

This repository provides a self-contained Docker image for working with hls4ml and the Bambu HLS compiler backend.

Firstly clone the repo. Once inside:
```
$ docker build -t bambu_img .
```

Then run the container:

```
$ docker run -it bambu_img --name bambu_container
```

Once inside the container

```
$ cd /home/bambu_user
$ ./script.sh
```

Follow the guided setup and install conda, then:

```
$ pip install hls4ml
```


