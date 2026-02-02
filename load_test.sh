#!/bin/bash

set -e

# 1. Load test backend HTTP endpoint (internal service)
echo "Load testing backend /api/health (service)..."
for i in {1..100}; do
  kubectl run curl-job-$i --rm -i --restart=Never --image=curlimages/curl -- \
    curl -s http://backend:8080/api/health &
done
wait

# 2. Scale frontend deployment up and down
echo "Scaling frontend deployment up and down..."
kubectl scale deployment/frontend-deployment --replicas=10
sleep 10
kubectl scale deployment/frontend-deployment --replicas=1

# 3. Stress CPU and memory on a node
echo "Stressing CPU and memory on a node..."
kubectl run cpu-stress --rm -i --restart=Never --image=alpine -- \
  sh -c "apk add --no-cache stress-ng && stress-ng --cpu 2 --timeout 20"
kubectl run mem-stress --rm -i --restart=Never --image=alpine -- \
  sh -c "apk add --no-cache stress-ng && stress-ng --vm 1 --vm-bytes 256M --timeout 20"

# 4. Create a CrashLoopBackOff pod
echo "Creating CrashLoopBackOff pod..."
kubectl run failpod --image=busybox --restart=Never -- /bin/sh -c "exit 1" || true
sleep 5
kubectl delete pod failpod --ignore-not-found

# 5. Load test backend via Ingress/ALB using wrk
ALB_HOST=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' -n default)
echo "Load testing backend via Ingress/ALB with wrk..."
if command -v wrk &> /dev/null; then
  wrk -t2 -c10 -d10s -H "Host: backend.contapics.local" http://$ALB_HOST/api/health
else
  echo "Please install 'wrk' for this test (https://github.com/wg/wrk)."
fi

# 6. Add multiple users to the database (Postgres)
echo "Adding users to the database..."
PG_POD=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec -i $PG_POD -- psql -U user contapics <<EOF
INSERT INTO users (username, password, role) VALUES
  ('testuser1', '\$2a\$10\$7QJ6QwQwQwQwQwQwQwQwQeQwQwQwQwQwQwQwQwQwQwQwQwQwQw', 'CLIENT'),
  ('testuser2', '\$2a\$10\$7QJ6QwQwQwQwQwQwQwQwQeQwQwQwQwQwQwQwQwQwQwQwQwQwQw', 'ADMIN'),
  ('testuser3', '\$2a\$10\$7QJ6QwQwQwQwQwQwQwQwQeQwQwQwQwQwQwQwQwQwQwQwQwQwQw', 'CLIENT'),
  ('testuser4', '\$2a\$10\$7QJ6QwQwQwQwQwQwQwQwQeQwQwQwQwQwQwQwQwQwQwQwQwQwQw', 'ADMIN')
ON CONFLICT DO NOTHING;
EOF

echo "All tests done! Check your Grafana dashboards for real-time metrics."