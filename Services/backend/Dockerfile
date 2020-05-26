FROM python:slim
COPY app /opt/shape/backend/app
WORKDIR  /opt/shape/backend/app
RUN  pip install -r requirements.txt
EXPOSE 80
CMD /bin/bash -c " python3 main.py"