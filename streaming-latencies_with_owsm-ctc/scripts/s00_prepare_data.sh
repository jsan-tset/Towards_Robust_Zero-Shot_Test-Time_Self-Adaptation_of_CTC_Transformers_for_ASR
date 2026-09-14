#!/bin/bash

set -e

export LC_ALL=C.UTF-8

# Prepare wavs, references and sample lists
cp -r ../20_false_streaming/wavs .
cp -r ../20_false_streaming/lhcp-lists .
ln -s ../20_false_streaming/ref
