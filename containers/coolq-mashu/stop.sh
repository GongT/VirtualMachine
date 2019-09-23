#!/bin/bash

docker logs -f coolq-mashu &

docker stop -t 90 coolq-mashu

