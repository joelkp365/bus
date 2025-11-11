===========================================
EXPERIMENT – 3
FLASK APP CONTAINERIZATION & DOCKER HUB DEPLOYMENT
===========================================

OBJECTIVE:
To create a Flask web app, containerize it using Docker, and deploy the image to Docker Hub.

FILES TO CREATE:
---------------------------------
1. app.py
---------------------------------
from flask import Flask, render_template_string
app = Flask(__name__)

@app.route('/')
def home():
    return render_template_string("<h1>Welcome to Flask Docker App!</h1><p>Containerized by Joel</p>")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

---------------------------------
2. requirements.txt
---------------------------------
Flask==2.2.5

---------------------------------
3. Dockerfile
---------------------------------
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]

COMMANDS:
---------------------------------
pip install -r requirements.txt
docker build -t flask-docker-app .
docker run -p 5000:5000 flask-docker-app
docker login
docker tag flask-docker-app <username>/flask-docker-app:latest
docker push <username>/flask-docker-app:latest
docker pull <username>/flask-docker-app:latest
docker run -p 5050:5000 <username>/flask-docker-app:latest


===========================================
EXPERIMENT – 4
CI PIPELINE FOR PYTHON APP (GITHUB + DOCKER HUB)
===========================================

OBJECTIVE:
To create a Python application, test it using pytest, build a Docker image, and automatically push it to Docker Hub using GitHub Actions CI/CD.

FILES TO CREATE:
---------------------------------
1. app.py
---------------------------------
def add(a, b):
    return a + b

if __name__ == "__main__":
    print("Hello from Python CI Lab!")
    print("2 + 3 =", add(2, 3))

---------------------------------
2. tests/test_app.py
---------------------------------
from app import add

def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0

---------------------------------
3. requirements.txt
---------------------------------
pytest==8.3.2

---------------------------------
4. Dockerfile
---------------------------------
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "app.py"]

---------------------------------
5. .gitignore
---------------------------------
__pycache__/
.venv/
.pytest_cache/
*.pyc
.DS_Store

---------------------------------
6. .github/workflows/ci-dockerhub.yml
---------------------------------
name: ci-dockerhub
on:
  push:
    branches: [ "main" ]
    tags: [ "*" ]
  pull_request:
    branches: [ "main" ]
jobs:
  build-test-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install deps
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      - name: Run tests
        run: PYTHONPATH=. pytest -q
      - name: Docker meta
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ secrets.DOCKERHUB_USERNAME }}/python-ci-lab
          tags: |
            type=raw,value=latest,enable={{is_default_branch}}
            type=sha,prefix=sha-,format=short
            type=ref,event=tag
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3
      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          platforms: linux/amd64

COMMANDS:
---------------------------------
python app.py
pytest -q
docker build -t yourname/python-ci-lab:local .
docker run --rm yourname/python-ci-lab:local
git init
git add .
git commit -m "ci pipeline"
git push -u origin main
git tag v1.0.0
git push origin v1.0.0

GITHUB SECRETS:
---------------------------------
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN


===========================================
EXPERIMENT – 5
JENKINS DEPLOYMENT USING DOCKER
===========================================

OBJECTIVE:
To deploy Jenkins using Docker Compose and create a pipeline that generates and publishes a static website.

FILES TO CREATE:
---------------------------------
1. docker-compose.yml
---------------------------------
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  jenkins_home:
    driver: local

COMMANDS:
---------------------------------
mkdir ~/jenkins-static-site && cd ~/jenkins-static-site
docker compose up -d
docker ps
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
# Open browser → http://localhost:8080

INSTALL HTML PUBLISHER PLUGIN:
---------------------------------
Manage Jenkins → Plugins → Available → "HTML Publisher"

PIPELINE SCRIPT:
---------------------------------
pipeline {
    agent any
    stages {
        stage('Generate site') {
            steps {
                script {
                    sh 'rm -rf site || true'
                    sh 'mkdir -p site/assets'
                    writeFile file: 'site/index.html', text: """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Karunya University — Simple Site</title>
<link rel="stylesheet" href="assets/style.css"/>
</head>
<body>
<header class="site-header">
<div class="container">
<h1>Karunya University</h1>
<p class="tagline">Values — Knowledge — Service</p>
</div>
</header>
<main class="container">
<section class="card">
<h2>About Karunya University</h2>
<p>Karunya Institute of Technology and Sciences is a leading
centre for higher education in India.</p>
</section>
</main>
<footer class="site-footer container">
<p>&copy; ${new Date().format('yyyy')} Karunya University — Generated by Jenkins</p>
</footer>
</body>
</html>
"""
                    writeFile file: 'site/assets/style.css', text: """
body { font-family: Arial, sans-serif; margin:0; }
.container { max-width:800px; margin:0 auto; padding:20px; }
.site-header { background:#0b3d91; color:#fff; padding:20px; }
.tagline { font-size:14px; opacity:0.8; }
.card { background:#fff; border:1px solid #ddd; padding:15px; margin:15px 0; border-radius:6px; }
.site-footer { text-align:center; font-size:12px; color:#555; margin-top:20px; }
"""
                }
            }
        }
        stage('Publish site') {
            steps {
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'site',
                    reportFiles: 'index.html',
                    reportName: 'Karunya University - Simple Site'
                ])
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'site/**', fingerprint: true
        }
    }
}

HOW TO RUN:
---------------------------------
1. Create pipeline job → paste script  
2. Click "Build Now"  
3. Click "Karunya University - Simple Site" to view website  
4. Download artifacts if needed  


===========================================
END OF FILE
===========================================
