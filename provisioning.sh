#!/bin/bash

#
cd /workspace/
# Cause the script to exit on failure.
set -eo pipefail

# Activate the main virtual environment
. /venv/main/bin/activate

git clone --recursive https://github.com/bmaltais/kohya_ss.git
cd kohya_ss
git checkout dev && git pull

# Install your packages
pip install xformers==0.0.30 && pip install -r requirements.txt && pip install bitsandbytes gradio tensorflow onnxruntime-gpu accelerate==0.30.0 "numpy<2"

# Download some useful files
wget -P "${WORKSPACE}/kohya_ss/models" https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/raw/main/sd_xl_base_1.0_0.9vae.safetensors

# Set up any additional services
cat > /etc/supervisor/conf.d/kohya_ss.conf<< EOF
command=. /venv/main/bin/activate && cd /workspace/kohya_ss && python3 /workspace/kohya_ss/kohya_gui.py --listen=0.0.0.0 --headless --noverify
autostart=true
autorestart=true
stderr_logfile=/var/log/kohya_ss.err.log
stdout_logfile=/var/log/kohya_ss.out.log
EOF

# Reconfigure the instance portal
rm -f /etc/portal.yaml
export PORTAL_CONFIG="localhost:1111:11111:/:Instance Portal|localhost:7860:7860:/:Kohya_SS"

# Reload Supervisor
supervisorctl reload
