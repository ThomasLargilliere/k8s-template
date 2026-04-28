BACKEND_IMAGE ?= your-registry/myapp-django
FRONTEND_IMAGE ?= your-registry/myapp-vue
NAMESPACE ?= myapp

init:
	@[ "$(origin NAME)" = "command line" ] || (echo "Usage: make init NAME=mon-projet"; exit 1)
	@kubectl get ingressclass nginx >/dev/null 2>&1 || \
		echo "ATTENTION : aucun ingress controller nginx detecte dans le cluster. L'application ne sera pas accessible par hostname sans lui."
	grep -rl 'myapp' . --exclude-dir='.git' | xargs sed -i 's/myapp/$(NAME)/g'
	@echo ""
	@echo "Projet initialise : $(NAME)"
	@echo ""
	@echo "Ajoute cette ligne dans /etc/hosts :"
	@echo "  127.0.0.1 $(NAME).local"
	@echo ""
	@echo "Pour changer l'URL, edite : k8s/base/ingress.yaml"

dev:
	@test -f k8s/overlays/dev/secret.yaml || (echo "Missing k8s/overlays/dev/secret.yaml."; exit 1)
	skaffold dev --cleanup=false

down:
	kubectl scale deployment --all --replicas=0 -n $(NAMESPACE)

reset:
	kubectl delete namespace $(NAMESPACE)

up:
	@test -f k8s/overlays/prod/sealed-secret.yaml || (echo "Missing k8s/overlays/prod/sealed-secret.yaml. Run 'make seal' first."; exit 1)
	kubectl apply -k k8s/overlays/prod

seal:
	@test -f k8s/overlays/prod/secret.yaml || (echo "Missing k8s/overlays/prod/secret.yaml (ne pas commiter ce fichier)."; exit 1)
	kubeseal --format yaml --namespace $(NAMESPACE) \
		< k8s/overlays/prod/secret.yaml \
		> k8s/overlays/prod/sealed-secret.yaml

migrate:
	kubectl exec -it -n $(NAMESPACE) deploy/django -- python manage.py migrate

build:
	docker build -t $(BACKEND_IMAGE):$(shell git rev-parse --short HEAD) ./django
	docker build -t $(FRONTEND_IMAGE):$(shell git rev-parse --short HEAD) ./vue
	docker push $(BACKEND_IMAGE):$(shell git rev-parse --short HEAD)
	docker push $(FRONTEND_IMAGE):$(shell git rev-parse --short HEAD)
	sed -i 's|$(BACKEND_IMAGE):.*|$(BACKEND_IMAGE):$(shell git rev-parse --short HEAD)|g' k8s/base/django/deployment.yaml
	sed -i 's|$(BACKEND_IMAGE):.*|$(BACKEND_IMAGE):$(shell git rev-parse --short HEAD)|g' k8s/base/django/migrate-job.yaml
	sed -i 's|$(FRONTEND_IMAGE):.*|$(FRONTEND_IMAGE):$(shell git rev-parse --short HEAD)|g' k8s/base/vue/deployment.yaml

shell:
	kubectl exec -it -n $(NAMESPACE) \
		$(shell kubectl get pod -n $(NAMESPACE) -l app=django -o jsonpath='{.items[0].metadata.name}') \
		-- /bin/bash
