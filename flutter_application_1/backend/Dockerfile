FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-runtime
WORKDIR /srv/sanaa
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
COPY requirements.txt requirements-ai.txt models.lock.json ./
RUN pip install --no-cache-dir wheel -r requirements-ai.txt
RUN SAM2_BUILD_CUDA=0 pip install --no-build-isolation 'git+https://github.com/facebookresearch/sam2.git@2b90b9f5ceec907a1c18123530e92e794ad901a4'
COPY app ./app
COPY main.py ./
COPY scripts ./scripts
ENV SANAA_DATA_DIR=/data SANAA_DEVICE=cuda SANAA_SAM_DEVICE=cpu
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
