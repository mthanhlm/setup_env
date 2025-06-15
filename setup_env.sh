#!/bin/bash

# Thoát script khi có lỗi
set -e

# Setup miniconda
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh
source ~/miniconda3/bin/activate
conda init --all


# Tạo môi trường Conda với Python 3.8
conda create -n ai python=3.8 -y

# Kích hoạt môi trường (phải dùng conda.sh)
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate ai

# Cài torch 2.0.1 + CUDA 11.8
pip install torch==2.0.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Cài CUDA toolkit 11.8
conda install -c "nvidia/label/cuda-11.8.0" cuda-toolkit -y

# Cài phụ thuộc
pip install -U openmim
mim install mmengine
pip install -U setuptools wheel ninja
sudo apt update
sudo apt install -y build-essential

# Clone và cài MMCV
git clone https://github.com/open-mmlab/mmcv.git
cd mmcv
git checkout v2.1.0

export CUDA_HOME=$CONDA_PREFIX
export CXXFLAGS="-std=c++17"
export FORCE_CUDA=1
export TORCH_CUDA_ARCH_LIST="8.0"

pip install -v -e .

cd ..

# Cài MMDetection và MMSegmentation
pip install git+https://github.com/open-mmlab/mmdetection.git
pip install git+https://github.com/open-mmlab/mmsegmentation.git

# Cấu hình biến môi trường
echo 'export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# Kích hoạt môi trường (phải dùng conda.sh)
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate ai

# Cài MMDetection3D
git clone https://github.com/open-mmlab/mmdetection3d.git
cd mmdetection3d
pip install -v -e .

cd ..

# Cài spconv và cumm
pip install cumm-cu118
pip install spconv-cu118
python -c "import spconv; print('✅ spconv version:', spconv.__version__)"

# Cài MinkowskiEngine
conda install openblas-devel -c anaconda
export CPLUS_INCLUDE_PATH=${CONDA_PREFIX}/include
pip install "setuptools<60"
export MAX_JOBS=1

pip install --no-build-isolation -U git+https://github.com/NVIDIA/MinkowskiEngine -v --no-deps \
  --config-settings="--install-option=--blas_include_dirs=${CONDA_PREFIX}/include" \
  --config-settings="--install-option=--blas=openblas" \
  --config-settings="--install-option=--force_cuda"

# Kiểm tra toàn bộ
python -c "$(cat <<EOF
import torch, mmcv, mmdet, mmengine
try: import mmdet3d
except ImportError: mmdet3d = None
try: import mmseg
except ImportError: mmseg = None
try: import spconv
except ImportError: spconv = None
try: import MinkowskiEngine as ME
except ImportError: ME = None
print('🔍 Torch:', torch.__version__, '| CUDA:', torch.version.cuda)
print('🔍 MMCV:', mmcv.__version__)
print('🔍 MMEngine:', mmengine.__version__)
print('🔍 MMDetection:', mmdet.__version__)
print('🔍 MMDetection3D:', getattr(mmdet3d, '__version__', 'Not installed'))
print('🔍 MMSegmentation:', getattr(mmseg, '__version__', 'Not installed'))
print('🔍 spconv:', getattr(spconv, '__version__', 'Not installed'))
print('🔍 MinkowskiEngine:', getattr(ME, '__version__', 'Not installed'))
EOF
)"
