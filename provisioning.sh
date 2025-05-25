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
pip install -r requirements.txt && pip install bitsandbytes gradio tensorflow onnxruntime-gpu accelerate==0.30.0 numpy==1.26.4 && pip install -I torch torchvision xformers==0.0.30 --index-url https://download.pytorch.org/whl/cu128 && pip uninstall numpy && pip install numpy==1.26.4

# Download some useful files
wget -P "${WORKSPACE}/kohya_ss/models" -o sd_xl_base_1.0_0.9vae.safetensors "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0_0.9vae.safetensors?download=true"

# create kohya_ss start script
cat > /workspace/kohya_ss.sh<< EOF
#!/bin/bash
source /venv/main/bin/activate
cd /workspace/kohya_ss
python3 kohya_gui.py --listen=0.0.0.0 --headless --noverify
EOF
chmod +x /workspace/kohya_ss.sh

# Set up any additional services
cat > /etc/supervisor/conf.d/kohya_ss.conf<< EOF
[program:kohya_ss]
command=/workspace/kohya_ss.sh
autostart=true
autorestart=true
stderr_logfile=/var/log/kohya_ss.err.log
stdout_logfile=/var/log/kohya_ss.out.log
EOF

# Reconfigure the instance portal
#rm -f /etc/portal.yaml
#export PORTAL_CONFIG="localhost:1111:11111:/:Instance Portal|localhost:7860:7860:/:Kohya_SS"

# Reload Supervisor
supervisorctl reload
