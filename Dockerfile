# Distroless: no shell, no package manager. ":nonroot" runs as UID 65532.
FROM gcr.io/distroless/python3-debian12:nonroot
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY --chown=65532:65532 --chmod=444 app/app.py .
USER 65532:65532
EXPOSE 8080
# ENTRYPOINT of the base image is already python3
CMD ["app.py"]
