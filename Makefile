IMAGE ?= your-registry/myapp
NAMESPACE ?= myapp

init:
	@test -n "$(NAME)" || (echo "Usage: make init NAME=mon-projet"; exit 1)
	@kubectl get ingressclass nginx >/dev/null 2>&1 || \
		echo "ATTENTION : aucun ingress controller nginx detecte dans le cluster. L'application ne sera pas accessible par hostname sans lui."
	grep -rl 'myapp' . --exclude-dir='.git' | xargs sed -i 's/myapp/$(NAME)/g'
	@echo ""
	@echo "Projet initialise : $(NAME)"
	@echo ""
	@echo "Ajoute cette ligne dans /etc/hosts :"
	@echo "  127.0.0.1 $(NAME).local"
	@echo ""
	@echo "Pour changer l'URL, edite : k8s/ingress.yaml"

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
