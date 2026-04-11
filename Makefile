IMAGE ?= your-registry/myapp
NAMESPACE ?= myapp

dev:
	skaffold dev --cleanup=false

down:
	kubectl scale deployment --all --replicas=0 -n $(NAMESPACE)

reset:
	kubectl delete namespace $(NAMESPACE)

up:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/secret.yaml
	kubectl apply -f k8s/db/deployment.yaml
	kubectl apply -f k8s/web/deployment.yaml

build:
	docker build -t $(IMAGE):$(shell git rev-parse --short HEAD) ./app
	docker push $(IMAGE):$(shell git rev-parse --short HEAD)
	sed -i 's|$(IMAGE):.*|$(IMAGE):$(shell git rev-parse --short HEAD)|g' k8s/web/deployment.yaml
	sed -i 's|$(IMAGE):.*|$(IMAGE):$(shell git rev-parse --short HEAD)|g' k8s/web/migrate-job.yaml
